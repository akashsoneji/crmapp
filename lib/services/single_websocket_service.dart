import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:crm_app/models/mt5_account.dart';
import 'package:crm_app/services/secure_storage_service.dart';
import 'package:crm_app/services/websocket_endpoint_helper.dart';
import 'package:crm_app/utils/message_pack_decoder.dart';
import 'package:crm_app/utils/app_logger.dart';
import 'package:crm_app/utils/encryption_helper.dart';

class SingleWebSocketService extends GetxService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  
  final RxBool isConnected = false.obs;
  final RxBool isAuthenticating = false.obs;
  final RxBool isAuthenticated = false.obs;
  
  MT5Account? _currentAccount;
  
  // Exponential backoff reconnect
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  static const int _maxReconnectDelayMs = 30000;
  int _backoffMs = 1000;
  
  // Broadcast streams for consumers
  final _pricesCtrl = StreamController<dynamic>.broadcast();
  final _positionsCtrl = StreamController<dynamic>.broadcast();
  final _ordersCtrl = StreamController<dynamic>.broadcast();
  final _accountsCtrl = StreamController<dynamic>.broadcast();
  
  Stream<dynamic> get pricesStream => _pricesCtrl.stream;
  Stream<dynamic> get positionsStream => _positionsCtrl.stream;
  Stream<dynamic> get ordersStream => _ordersCtrl.stream;
  Stream<dynamic> get accountsStream => _accountsCtrl.stream;
  
  // Track subscribed symbols to resubscribe after reconnect
  final Set<String> _subscribedSymbols = {};

  @override
  void onClose() {
    disconnect();
    _pricesCtrl.close();
    _positionsCtrl.close();
    _ordersCtrl.close();
    _accountsCtrl.close();
    super.onClose();
  }

  Future<void> connect({MT5Account? account}) async {
    if (account != null) {
      _currentAccount = account;
    }
    
    if (_currentAccount == null) {
      AppLogger.warning('SingleWS: Cannot connect, no active account set');
      return;
    }
    
    if (_channel != null) {
      // If we are already connected to a different account, switch
      return; 
    }
    
    final token = await SecureStorageService.getAuthToken();
    if (token == null || token.isEmpty) {
      AppLogger.warning('SingleWS: No auth token, skipping connection');
      return;
    }
    
    final wsUrl = WebSocketEndpointHelper.getFullUrl('/ws/stream');
    AppLogger.websocket('SingleWS: Connecting to $wsUrl for account ${_currentAccount!.metaAccountNumber}');
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      isConnected.value = true;
      _backoffMs = 1000; // Reset backoff on connection initiation
      
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: (err) {
          AppLogger.error('SingleWS: Connection error', error: err);
          _handleDisconnect();
        },
        onDone: () {
          AppLogger.websocket('SingleWS: Connection closed by server');
          _handleDisconnect();
        },
        cancelOnError: false,
      );
      
      _authenticate(token);
    } catch (e) {
      AppLogger.error('SingleWS: Failed to connect', error: e);
      _handleDisconnect();
    }
  }
  
  void _authenticate(String token) {
    if (_channel == null || _currentAccount == null) return;
    
    isAuthenticating.value = true;
    final authMsg = {
      "type": "authenticate",
      "authID": token,
      "trading_account": _currentAccount!.metaAccountNumber,
    };
    
    AppLogger.websocket('SingleWS: Sending authenticate payload');
    _send(authMsg);
  }
  
  void _send(Map<String, dynamic> msg) {
    if (_channel != null) {
      try {
        _channel!.sink.add(jsonEncode(msg));
      } catch (e) {
        AppLogger.error('SingleWS: Error sending message', error: e);
      }
    }
  }
  
  void _onMessage(dynamic message) {
    try {
      if (message is String) {
        final trimmed = message.trim();
        if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
          final decodedJson = jsonDecode(trimmed);
          _handleDecodedJson(decodedJson);
        } else {
          AppLogger.warning('SingleWS: Received non-JSON string message: $message');
        }
      } else {
        // Data message (BINARY msgpack)
        final Uint8List u8 = message is Uint8List
            ? message
            : Uint8List.fromList(message as List<int>);
            
        final decoded = MessagePackDecoder.decodeBinary(u8);
        if (decoded == null || decoded is! List || decoded.length < 2) {
          return;
        }
        
        final tag = decoded[0]?.toString();
        final payload = decoded[1];
        
        _routePayloadByTag(tag, payload);
      }
    } catch (e) {
      AppLogger.error('SingleWS: Error processing message', error: e);
    }
  }

  void _handleDecodedJson(dynamic decodedJson) {
    dynamic actualData = decodedJson;

    // Check if the message is encrypted
    if (decodedJson is Map<String, dynamic>) {
      final isEncrypted = decodedJson['encrypted'] == true;
      if (isEncrypted) {
        final payload = decodedJson['payload'] as String?;
        final iv = decodedJson['iv'] as String?;
        if (payload != null && iv != null) {
          try {
            final decryptedJson = EncryptionHelper.decryptPayload(payload, iv);
            actualData = jsonDecode(decryptedJson);
            // AppLogger.websocket('SingleWS Decryption: Decrypted successfully');
          } catch (e) {
            AppLogger.error('SingleWS Encryption: Decryption failed', error: e);
            return;
          }
        } else {
          AppLogger.warning('SingleWS Encryption: encrypted=true but payload or iv is missing');
        }
      }
    }

    // Now process actualData (which can be a Map or a List)
    if (actualData is Map<String, dynamic>) {
      final type = actualData['type']?.toString();
      // AppLogger.debug('[SingleWS Control Stream] Endpoint: Control ($type), Response: $actualData');

      if (type == 'authenticated') {
        isAuthenticating.value = false;
        isAuthenticated.value = true;
        AppLogger.websocket('SingleWS: Authentication successful');
        _subscribeToChannels();
      } else if (type == 'stream_subscribed') {
        AppLogger.websocket('SingleWS: Subscribed to channels successfully');
      } else if (type == 'error') {
        AppLogger.error('SingleWS: Error from server: ${actualData['message']}');
        if (actualData['message']?.toString().contains('failed') == true) {
          _channel?.sink.close(1008);
        }
      } else if (type == 'pending_orders_init') {
        if (!_ordersCtrl.isClosed) {
          // AppLogger.debug('[SingleWS Orders Stream] Endpoint: pending_orders_init, Response: $actualData');
          _ordersCtrl.add(actualData);
        }
      } else if (type == 'positions_init' || type == 'positions_delta') {
        if (!_positionsCtrl.isClosed) {
          // AppLogger.debug('[SingleWS Positions Stream] Endpoint: $type, Response: $actualData');
          _positionsCtrl.add(actualData);
        }
      } else if (type == 'pending_orders_delta') {
        if (!_ordersCtrl.isClosed) {
          // AppLogger.debug('[SingleWS Orders Stream] Endpoint: $type, Response: $actualData');
          _ordersCtrl.add(actualData);
        }
      } else if (type == 'account_switched' || type == 'unsubscribed') {
        if (!_accountsCtrl.isClosed) {
          // AppLogger.debug('[SingleWS Accounts Stream] Endpoint: $type, Response: $actualData');
          _accountsCtrl.add(actualData);
        }
      }
    } else if (actualData is List) {
      // JSON data envelope: e.g. [tag, payload]
      if (actualData.length >= 2) {
        final tag = actualData[0]?.toString();
        final payload = actualData[1];
        _routePayloadByTag(tag, payload);
      } else {
        AppLogger.warning('SingleWS: Received JSON List with length < 2: $actualData');
      }
    } else {
      AppLogger.warning('SingleWS: Received unknown JSON data type: ${actualData.runtimeType}');
    }
  }

  void _routePayloadByTag(String? tag, dynamic payload) {
    switch (tag) {
      case 'p':
        // AppLogger.debug('[SingleWS Prices Stream] Tag: p, Response: $payload');
        if (!_pricesCtrl.isClosed) _pricesCtrl.add(payload);
        break;
      case 'pos':
        // AppLogger.debug('[SingleWS Positions Stream] Tag: pos, Response: $payload');
        if (!_positionsCtrl.isClosed) _positionsCtrl.add(payload);
        break;
      case 'po':
        // AppLogger.debug('[SingleWS Orders Stream] Tag: po, Response: $payload');
        if (!_ordersCtrl.isClosed) _ordersCtrl.add(payload);
        break;
      case 'ac':
        // AppLogger.debug('[SingleWS Accounts Stream] Tag: ac, Response: $payload');
        if (!_accountsCtrl.isClosed) {
          // AccountWebSocketService/DashboardController legacy parsers expect
          // each account row to start with the "ac" marker. The single stream
          // demux gives us only the payload after tag='ac', so normalize it here.
          _accountsCtrl.add(_normalizeAccountPayload(payload));
        }
        break;
      default:
        AppLogger.warning('SingleWS: Unknown tag: $tag');
    }
  }
  
  void _subscribeToChannels() {
    final subMsg = {
      "type": "stream_subscribe",
      "channels": ["prices", "positions", "orders", "accounts"]
    };
    AppLogger.websocket('SingleWS: Subscribing to stream channels');
    _send(subMsg);
    
    if (_subscribedSymbols.isNotEmpty) {
      _send({
        "action": "subscribe",
        "symbols": _subscribedSymbols.toList(),
      });
    }
  }
  
  dynamic _normalizeAccountPayload(dynamic payload) {
    if (payload is List) {
      if (payload.isEmpty) return payload;

      // Already legacy-compatible: ["ac", account, ...]
      if (payload.first?.toString().toLowerCase() == 'ac') {
        return payload;
      }

      // Multiple rows: [[account, ...], [account, ...]] or [["ac", account, ...]]
      if (payload.first is List) {
        return payload.map((row) {
          if (row is List &&
              row.isNotEmpty &&
              row.first?.toString().toLowerCase() != 'ac') {
            return ['ac', ...row];
          }
          return row;
        }).toList();
      }

      // Single row without marker: [account, balance, credit/equity, ...]
      return ['ac', ...payload];
    }

    return payload;
  }
  
  void subscribeSymbols(List<String> symbols) {
    if (symbols.isEmpty) return;
    _subscribedSymbols.addAll(symbols);
    if (isAuthenticated.value) {
      _send({
        "action": "subscribe",
        "symbols": symbols,
      });
    }
  }
  
  void unsubscribeSymbols(List<String> symbols) {
    if (symbols.isEmpty) return;
    _subscribedSymbols.removeAll(symbols);
    if (isAuthenticated.value) {
      _send({
        "action": "unsubscribe",
        "symbols": symbols,
      });
    }
  }
  
  void loadMorePositions(int offset) {
    if (isAuthenticated.value) {
      _send({
        "type": "chunk_request",
        "data_type": "positions",
        "offset": offset,
        "limit": 100
      });
    }
  }

  void loadMoreOrders(int offset) {
    if (isAuthenticated.value) {
      _send({
        "type": "chunk_request",
        "data_type": "orders",
        "offset": offset,
        "limit": 100
      });
    }
  }

  void loadMoreAccounts(int offset) {
    if (isAuthenticated.value) {
      _send({
        "type": "chunk_request",
        "data_type": "accounts",
        "offset": offset,
        "limit": 100
      });
    }
  }
  
  Future<void> switchAccount(MT5Account newAccount) async {
    AppLogger.websocket('SingleWS: Switching account to ${newAccount.metaAccountNumber}');
    
    // Close current connection cleanly first
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _reconnectAttempts = 0;
    
    isConnected.value = false;
    isAuthenticating.value = false;
    isAuthenticated.value = false;
    
    // Update account
    _currentAccount = newAccount;
    
    // Wait for TCP close to settle
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Establish fresh connection with new account
    await connect(account: newAccount);
  }
  
  void disconnect() {
    AppLogger.websocket('SingleWS: Disconnecting manually');
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _currentAccount = null;
    _reconnectAttempts = 0;
    _subscribedSymbols.clear();
    isConnected.value = false;
    isAuthenticating.value = false;
    isAuthenticated.value = false;
  }
  
  void _handleDisconnect() {
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    isConnected.value = false;
    isAuthenticating.value = false;
    isAuthenticated.value = false;
    
    _scheduleReconnect();
  }
  
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: _backoffMs), () {
      AppLogger.websocket('SingleWS: Reconnecting... Attempt count: $_reconnectAttempts');
      _reconnectAttempts++;
      _backoffMs = (_backoffMs * 2).clamp(1000, _maxReconnectDelayMs);
      connect();
    });
  }
}
