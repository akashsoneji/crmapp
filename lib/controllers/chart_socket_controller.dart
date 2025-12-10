// lib/controllers/chart_socket_controller.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/api_const.dart';
import 'package:pipze/controllers/account_controller.dart';
import 'package:pipze/services/secure_storage_service.dart';
import 'package:pipze/services/websocket_endpoint_helper.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:pipze/utils/message_pack_decoder.dart';

class ChartSocketController extends GetxController with WidgetsBindingObserver {
  // Connection state
  final RxBool isConnected = false.obs;
  final RxBool isReconnecting = false.obs;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  bool _isDisposed = false;
  late WebSocketChannel channel;

  // Unsubscribe/resubscribe state
  Completer<void>? _unsubscribeCompleter;

  // Symbol & data
  final RxString currentSymbol = ''.obs;
  final RxMap<String, dynamic> realTimePrice = <String, dynamic>{}.obs;

  final StreamController<Map<String, dynamic>> _priceStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get priceStream => _priceStreamController.stream;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    // DON'T auto-connect - let screen decide when to start
    // Auto-(re)connect + subscribe when symbol changes
    ever<String>(currentSymbol, (sym) async {
      if (sym.isEmpty) return;
      // Only auto-subscribe if already connected
      if (isConnected.value && !_isDisposed) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (isConnected.value && !_isDisposed) getSocketData();
        });
      }
    });
  }

  // Method to start WebSocket when screen becomes visible
  void startWebSocket() {
    print('🔌 ChartSocketController: Starting WebSocket');
    if (currentSymbol.value.isNotEmpty && !isConnected.value) {
      initializeWebSocket();
    }
  }

  // Method to stop WebSocket when screen is hidden
  void stopWebSocket() {
    print('🔌 ChartSocketController: Stopping WebSocket');
    resetController();
  }

  @override
  void onClose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _reconnectTimer?.cancel();
    try {
      if (!_priceStreamController.isClosed) {
        _priceStreamController.close();
      }
    } catch (_) {}
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      handleAppRestart();
    }
  }

  // ---------- Public API ----------
  Future<void> initializeSocketForSymbol(String symbol) async {
    if (symbol.isEmpty) return;

    if (isConnected.value && currentSymbol.value == symbol) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (isConnected.value) getSocketData();
      });
      return;
    }

    if (isConnected.value) {
      _disconnectWebSocket();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    currentSymbol.value = symbol;
    realTimePrice.clear();
    await Future.delayed(const Duration(milliseconds: 500));

    if (!_isDisposed) initializeWebSocket();
  }

  Future<void> changeSymbol(String newSymbol) =>
      initializeSocketForSymbol(newSymbol);

  /// Called by chart screen after restart/resume (kept for compatibility).
  void handleAppRestart() {
    if (currentSymbol.value.isEmpty) return;

    if (!isConnected.value) {
      _reconnectWebSocket();
    } else {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (isConnected.value) getSocketData();
      });
    }
  }

  /// Convenience: ensure started for a symbol (used by screen bootstrap)
  Future<void> ensureStartedFor(String? symbol) async {
    if (symbol == null || symbol.isEmpty) return;
    await initializeSocketForSymbol(symbol);
    handleAppRestart();
  }

  // Get WebSocket URL based on account type (MT5 vs self-hosted)
  String _getWebSocketUrl() {
    try {
      final accountController = Get.find<AccountController>();
      final activeAccount = accountController.activeMT5Account;

      // ✅ Use centralized endpoint helper
      final wsUrl = WebSocketEndpointHelper.getSymbolUrl(activeAccount);
      final accountType = WebSocketEndpointHelper.getAccountType(activeAccount);

      if (kDebugMode) {
        dev.log(
          'Chart WS: Using $accountType endpoint: $wsUrl (Account: ${activeAccount?.metaAccountNumber ?? "N/A"}, trading_server: ${activeAccount?.tradingServer ?? "N/A"})',
        );
      }

      return wsUrl;
    } catch (e) {
      // Fallback to self-hosted endpoint if account controller not found
      if (kDebugMode) {
        dev.log(
          'Chart WS: Error getting account, using default self-hosted endpoint: $e',
        );
      }
      return WebSocketEndpointHelper.getFullUrl(
        WebSocketEndpointHelper.selfHostedSymbol,
      );
    }
  }

  // ---------- WebSocket ----------
  void initializeWebSocket() {
    if (currentSymbol.value.isEmpty) {
      dev.log('Chart: initializeWebSocket() called with empty symbol');
      return;
    }
    if (isConnected.value) return;

    try {
      // ✅ Use correct endpoint: /ws/symbol for single symbol subscription
      channel = WebSocketChannel.connect(Uri.parse(_getWebSocketUrl()));
      isConnected.value = true;
      _reconnectAttempts = 0;
      isReconnecting.value = false;
      dev.log('✅ Chart WebSocket connected to: ${_getWebSocketUrl()}');

      channel.stream.listen(
        (message) => _handleSocketMessage(message),
        onError: (error) {
          dev.log('Chart WS error: $error');
          isConnected.value = false;
          _scheduleReconnect();
        },
        onDone: () {
          dev.log('Chart WS closed');
          isConnected.value = false;
          _scheduleReconnect();
        },
      );

      Future.delayed(const Duration(milliseconds: 100), () {
        if (isConnected.value && !_isDisposed) getSocketData();
      });
    } catch (e) {
      dev.log('Chart WS init failed: $e');
      isConnected.value = false;
      _scheduleReconnect();
    }
  }

  void getSocketData() async {
    if (currentSymbol.value.isEmpty) {
      dev.log('Chart: getSocketData() called with empty symbol');
      return;
    }

    // ✅ Use authID (same as instruments controller)
    final authid = await SecureStorageService.getAuthToken();
    dev.log("Chart: WebSocket token: ${authid != null ? 'exists' : 'null'}");

    if (authid == null || authid.isEmpty) {
      dev.log('Chart: WebSocket token is null or empty, retrying in 500ms...');
      // Retry after a shorter delay to allow token to be saved
      Timer(const Duration(milliseconds: 500), () {
        if (isConnected.value && currentSymbol.value.isNotEmpty) {
          getSocketData();
        }
      });
      return;
    }

    // Get the active MT5 account number from account controller
    final accountController = Get.find<AccountController>();
    final activeAccount = accountController.activeMT5Account;
    final accountNumber = activeAccount?.metaAccountNumber ?? "0";

    dev.log("Chart: Using MT5 Account Number: $accountNumber");
    dev.log("Chart: Subscribing to symbol: ${currentSymbol.value}");

    // ✅ Send correct request format: { "authID": "token", "trading_account": "account", "symbol": "SYMBOL" }
    // ✅ PERFORMANCE: Request binary format for improved performance (50-70% smaller, 5-10x faster)
    sendEvent({
      "authID": authid,
      "trading_account": accountNumber,
      "symbol": currentSymbol.value,
      "format": "binary", // Request binary format
    });

    dev.log(
      '📤 ChartSocket: Sent subscription request for ${currentSymbol.value} (account: $accountNumber)',
    );
  }

  void sendEvent(Map<String, dynamic> event) {
    try {
      if (isConnected.value) {
        channel.sink.add(jsonEncode(event));
      } else {
        dev.log('Chart: cannot send, WS not connected');
      }
    } catch (e) {
      dev.log('Chart: send error: $e');
      isConnected.value = false;
    }
  }

  void _handleSocketMessage(dynamic message) {
    try {
      // ✅ PERFORMANCE: Handle both JSON and binary (MessagePack) formats
      dynamic data;

      if (MessagePackDecoder.isBinaryMessage(message)) {
        // Binary MessagePack format - decode it
        if (kDebugMode) {
          final sizeInfo = MessagePackDecoder.getMessageSize(message);
          dev.log(
            '📦 Chart: Received binary MessagePack message (${sizeInfo['sizeKB']} KB)',
          );
        }
        data = MessagePackDecoder.decodeBinary(
          message is Uint8List
              ? message
              : Uint8List.fromList(message as List<int>),
        );

        if (data == null) {
          dev.log('⚠️ Chart: Binary decode failed, skipping message');
          return;
        }
      } else {
        // JSON format - decode as string
        final jsonStr = message is String ? message : message.toString();
        data = jsonDecode(jsonStr);
      }

      // ✅ Handle JSON object responses (authentication, errors, etc.)
      if (data is Map<String, dynamic>) {
        final type = data['type']?.toString();

        // Handle unsubscribe confirmation
        if (type == 'symbol_left') {
          dev.log('✅ Unsubscribed from symbol');
          if (_unsubscribeCompleter != null &&
              !_unsubscribeCompleter!.isCompleted) {
            _unsubscribeCompleter!.complete();
            _unsubscribeCompleter = null;
          }
          return;
        }

        // Handle authentication success messages
        if (type == 'symbol_joined' || type == 'authenticated') {
          final status = data['status']?.toString();
          final messageText = data['message']?.toString();

          if (status == 'success') {
            dev.log('✅ Chart WebSocket authenticated: $messageText');
            if (type == 'symbol_joined') {
              dev.log('✅ Subscribed to symbol: ${data['symbol']}');
            }
          }
          return;
        }

        // Handle error responses
        if (type == 'error') {
          final errorMessage = data['message']?.toString() ?? 'Unknown error';
          dev.log('❌ Chart WebSocket error: $errorMessage');
          // Complete unsubscribe completer even on error to avoid hanging
          if (_unsubscribeCompleter != null &&
              !_unsubscribeCompleter!.isCompleted) {
            _unsubscribeCompleter!.complete();
            _unsubscribeCompleter = null;
          }
          return;
        }

        // Handle old format with groups
        if (data.containsKey('groups')) {
          _handleGroupsData(data);
          return;
        }

        // Handle old format with singleSymbol
        if (data.containsKey('singleSymbol')) {
          final single = Map<String, dynamic>.from(data['singleSymbol'] ?? {});
          final responseSymbol = single['Symbol']?.toString();

          if (_matchesCurrentSymbol(responseSymbol)) {
            final transformed = {
              'type': 'singleSymbolPrice',
              'symbol': responseSymbol,
              'bid': single['Bid'],
              'ask': single['Ask'],
              'digits': single['Digits'],
              'last': single['Last'],
              'spreadDiff': single['SpreadDiff'],
              'volume': single['Volume'],
            };

            if (!_isDisposed) realTimePrice.value = transformed;
            if (!_priceStreamController.isClosed) {
              _priceStreamController.add(
                Map<String, dynamic>.from(transformed),
              );
            }
          }
          return;
        }

        // Handle other JSON responses
        if (data['type'] == 'singleSymbolPrice' ||
            data['symbol'] == currentSymbol.value) {
          if (!_isDisposed)
            realTimePrice.value = Map<String, dynamic>.from(data);
          if (!_priceStreamController.isClosed) {
            _priceStreamController.add(Map<String, dynamic>.from(data));
          }
          return;
        }
        return;
      }

      // ✅ Handle array format: [symbol, bid, ask, spread_points, digits, category]
      // New format: ["XAUUSD", 2650.50, 2650.70, 2, 2, "metals"]
      if (data is List && data.length >= 5) {
        final symbol = data[0].toString();

        if (_matchesCurrentSymbol(symbol)) {
          final transformed = {
            'type': 'singleSymbolPrice',
            'symbol': symbol,
            'bid': double.tryParse(data[1].toString()) ?? 0.0,
            'ask': double.tryParse(data[2].toString()) ?? 0.0,
            'spreadDiff':
                double.tryParse(data[3].toString()) ?? 0.0, // spread_points
            'digits': int.tryParse(data[4].toString()) ?? 5,
            'category': data.length >= 6 ? data[5].toString() : null,
            'last': 0,
            'volume': 0,
          };

          if (!_isDisposed) realTimePrice.value = transformed;
          if (!_priceStreamController.isClosed) {
            _priceStreamController.add(Map<String, dynamic>.from(transformed));
          }
        }
        return;
      }
    } catch (e) {
      dev.log('Chart: parse error: $e; raw: $message');
    }
  }

  void _handleGroupsData(Map<String, dynamic> data) {
    final groups = data['groups'] as List<dynamic>? ?? [];
    for (final g in groups) {
      final group = g as Map<String, dynamic>;
      final list = group['list'] as List<dynamic>? ?? [];
      for (final it in list) {
        // Handle both array and object formats
        if (it is List && it.length >= 5) {
          // Array format: ["symbol", "bid", "ask", "spreadDiff", "digits", "category"]
          final symbol = it[0].toString();
          if (_matchesCurrentSymbol(symbol)) {
            final transformed = {
              'type': 'singleSymbolPrice',
              'symbol': symbol,
              'bid': double.tryParse(it[1].toString()) ?? 0.0,
              'ask': double.tryParse(it[2].toString()) ?? 0.0,
              'spreadDiff': int.tryParse(it[3].toString()) ?? 0,
              'digits': int.tryParse(it[4].toString()) ?? 0,
              'category': it.length >= 6 ? it[5].toString() : null,
              'last': 0,
              'volume': 0,
            };
            if (!_isDisposed) realTimePrice.value = transformed;
            if (!_priceStreamController.isClosed) {
              _priceStreamController.add(
                Map<String, dynamic>.from(transformed),
              );
            }
            return;
          }
        } else if (it is Map<String, dynamic>) {
          // Object format
          final symbol = it['Symbol']?.toString() ?? '';
          if (_matchesCurrentSymbol(symbol)) {
            final transformed = {
              'type': 'singleSymbolPrice',
              'symbol': symbol,
              'bid': it['Bid'],
              'ask': it['Ask'],
              'digits': it['Digits'],
              'last': it['Last'],
              'spreadDiff': it['SpreadDiff'],
              'volume': it['Volume'],
            };
            if (!_isDisposed) realTimePrice.value = transformed;
            if (!_priceStreamController.isClosed) {
              _priceStreamController.add(
                Map<String, dynamic>.from(transformed),
              );
            }
            return;
          }
        }
      }
    }
  }

  bool _matchesCurrentSymbol(String? responseSymbol) {
    final cur = currentSymbol.value;
    if (responseSymbol == null || cur.isEmpty) return false;

    // Exact match (with or without suffix)
    if (responseSymbol == cur) return true;

    // Remove any suffix (.c, .r, etc.) and compare base symbols
    final baseResponse = _removeSuffix(responseSymbol);
    final baseCurrent = _removeSuffix(cur);

    // Match if base symbols are same (handles EURUSD.c == EURUSD)
    return baseResponse == baseCurrent;
  }

  // Helper to remove any suffix (.c, .r, etc.) for comparison purposes
  // Handles both cases: symbols WITH suffix (EURUSD.c) and WITHOUT suffix (EURUSD)
  String _removeSuffix(String symbol) {
    if (symbol.contains('.')) {
      return symbol.substring(0, symbol.lastIndexOf('.'));
    }
    return symbol; // No suffix, return original
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      isReconnecting.value = false;
      return;
    }
    _reconnectAttempts++;
    isReconnecting.value = true;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, _reconnectWebSocket);
  }

  void _reconnectWebSocket() {
    if (isConnected.value) return;
    try {
      _disconnectWebSocket();
      Future.delayed(const Duration(milliseconds: 100), () {
        initializeWebSocket();
      });
    } catch (e) {
      dev.log('Chart: reconnect error: $e');
      isReconnecting.value = false;
    }
  }

  void _disconnectWebSocket() {
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    isConnected.value = false;
    isReconnecting.value = false;
    realTimePrice.clear();
    try {
      channel.sink.close();
    } catch (_) {}
  }

  // Unsubscribe and resubscribe with new account (keeps socket active)
  Future<void> unsubscribeAndResubscribe(
    String newAccountNumber,
    String symbol,
  ) async {
    print(
      '🔄 ChartSocketController: Unsubscribing and resubscribing for account: $newAccountNumber, symbol: $symbol',
    );

    // If not connected or symbol is empty, just initialize normally
    if (!isConnected.value || symbol.isEmpty) {
      print(
        '⚠️ ChartSocketController: Not connected or empty symbol, initializing normally',
      );
      currentSymbol.value = symbol;
      realTimePrice.clear();
      if (!isConnected.value) {
        initializeWebSocket();
      } else {
        getSocketData();
      }
      return;
    }

    try {
      // Step 1: Unsubscribe from current symbol
      print('📤 ChartSocketController: Sending leave_symbol request');
      _unsubscribeCompleter = Completer<void>();
      sendEvent({"type": "leave_symbol"});

      // Step 2: Wait for unsubscribe confirmation (with timeout)
      try {
        await _unsubscribeCompleter!.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            print(
              '⚠️ ChartSocketController: Unsubscribe timeout, proceeding anyway',
            );
            if (_unsubscribeCompleter != null &&
                !_unsubscribeCompleter!.isCompleted) {
              _unsubscribeCompleter!.complete();
              _unsubscribeCompleter = null;
            }
          },
        );
      } catch (e) {
        print('⚠️ ChartSocketController: Error waiting for unsubscribe: $e');
      }

      // Step 3: Clear price data
      realTimePrice.clear();
      currentSymbol.value = symbol;

      // Step 4: Resubscribe with new account
      print(
        '📤 ChartSocketController: Resubscribing with new account: $newAccountNumber, symbol: $symbol',
      );
      final authid = await SecureStorageService.getAuthToken();
      if (authid != null && authid.isNotEmpty) {
        sendEvent({
          "authID": authid,
          "trading_account": newAccountNumber,
          "symbol": symbol,
        });
        print('✅ ChartSocketController: Resubscribed successfully');
      } else {
        print(
          '❌ ChartSocketController: No auth token available for resubscribe',
        );
      }
    } catch (e) {
      print('❌ ChartSocketController: Error in unsubscribeAndResubscribe: $e');
      // Fallback: if unsubscribe/resubscribe fails, do full reconnect
      _disconnectWebSocket();
      await Future.delayed(const Duration(milliseconds: 100));
      currentSymbol.value = symbol;
      realTimePrice.clear();
      initializeWebSocket();
    }
  }

  void resetController() {
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    isReconnecting.value = false;
    if (isConnected.value) {
      try {
        channel.sink.close();
      } catch (_) {}
    }
    isConnected.value = false;
    realTimePrice.clear();
  }

  void forceReconnect() {
    resetController();
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!_isDisposed) initializeWebSocket();
    });
  }

  // ----- Convenience getters -----
  Map<String, dynamic>? getCurrentPrice() {
    return realTimePrice.isNotEmpty ? realTimePrice : null;
  }

  double? getBidPrice() {
    final p = getCurrentPrice();
    if (p != null && p.containsKey('bid')) {
      return double.tryParse(p['bid'].toString());
    }
    return null;
  }

  double? getAskPrice() {
    final p = getCurrentPrice();
    if (p != null && p.containsKey('ask')) {
      return double.tryParse(p['ask'].toString());
    }
    return null;
  }

  double? getDifference() {
    try {
      final p = getCurrentPrice();
      if (p == null) return null;
      final spreadField = p['spreadDiff'] ?? p['SpreadDiff'];
      if (spreadField != null) {
        final v = double.tryParse(spreadField.toString());
        if (v != null) return v.abs();
      }
      // final bid = getBidPrice();
      // final ask = getAskPrice();
      // if (bid != null && ask != null) return (ask - bid).abs();
    } catch (e) {
      dev.log('Chart: getDifference error: $e');
    }
    return null;
  }

  // Get market price (average of bid and ask) for price alerts
  double? getMarketPrice() {
    try {
      final bid = getBidPrice();
      final ask = getAskPrice();
      if (bid != null && ask != null) {
        return (bid + ask) / 2;
      }
      // Fallback to bid price if ask is not available
      return bid;
    } catch (e) {
      dev.log('Chart: getMarketPrice error: $e');
      return null;
    }
  }

  // WebsocketPriceData? getCurrentPriceDataModel() {
  //   try {
  //     final p = getCurrentPrice();
  //     if (p == null) return null;
  //     final candidate = <String, dynamic>{
  //       'Symbol': p['symbol'] ?? p['Symbol'],
  //       'Bid': p['bid'] ?? p['Bid'],
  //       'Ask': p['ask'] ?? p['Ask'],
  //       'Last': p['last'] ?? p['Last'],
  //       'Digits': p['digits'] ?? p['Digits'],
  //       'SpreadDiff': p['spreadDiff'] ?? p['SpreadDiff'],
  //       'Volume': p['volume'] ?? p['Volume'],
  //     };
  //     try {
  //       return WebsocketPriceData.fromJson(candidate);
  //     } catch (_) {
  //       return WebsocketPriceData.fromJson({'singleSymbol': candidate});
  //     }
  //   } catch (e) {
  //     dev.log('Chart: getCurrentPriceDataModel error: $e');
  //     return null;
  //   }
  // }
}
