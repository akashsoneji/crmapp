// lib/screens/home/chart_socket_controller.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/api_const.dart';
import 'package:pipze/controllers/account_controller.dart';
import 'package:pipze/models/websocket_price_data.dart';
import 'package:pipze/services/secure_storage_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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

    // Auto-(re)connect + subscribe when symbol changes
    ever<String>(currentSymbol, (sym) async {
      if (sym.isEmpty) return;
      if (isConnected.value) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (isConnected.value && !_isDisposed) getSocketData();
        });
      } else {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!_isDisposed) initializeWebSocket();
      }
    });
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

  // ---------- WebSocket ----------
  void initializeWebSocket() {
    if (currentSymbol.value.isEmpty) {
      dev.log('Chart: initializeWebSocket() called with empty symbol');
      return;
    }
    if (isConnected.value) return;

    try {
      channel = WebSocketChannel.connect(Uri.parse(ApiConstants.socketUrl));
      isConnected.value = true;
      _reconnectAttempts = 0;
      isReconnecting.value = false;

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
    if (currentSymbol.value.isEmpty) return;

    final authid = await SecureStorageService.getWebsocketToken();
    if (authid == null || authid.isEmpty) {
      Timer(const Duration(seconds: 2), () {
        if (isConnected.value && currentSymbol.value.isNotEmpty) {
          getSocketData();
        }
      });
      return;
    }

    final accountController = Get.find<AccountController>();
    final activeAccount = accountController.activeMT5Account;
    final accountNumber = activeAccount?.metaAccountNumber ?? "901246";

    sendEvent({
      "authID": authid,
      "symbol": currentSymbol.value,
      "isapp": 1,
      "mt5AccountNumber": int.tryParse(accountNumber) ?? 901246,
      "type": "singleSymbolPrice",
    });
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
      final data = jsonDecode(message);

      if (data is Map<String, dynamic> && data.containsKey('groups')) {
        _handleGroupsData(data);
        return;
      }

      if (data is Map<String, dynamic> && data.containsKey('singleSymbol')) {
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
            _priceStreamController.add(Map<String, dynamic>.from(transformed));
          }
        }
        return;
      }

      if (data is Map<String, dynamic>) {
        if (data['type'] == 'singleSymbolPrice' ||
            data['symbol'] == currentSymbol.value) {
          if (!_isDisposed)
            realTimePrice.value = Map<String, dynamic>.from(data);
          if (!_priceStreamController.isClosed) {
            _priceStreamController.add(Map<String, dynamic>.from(data));
          }
          return;
        }
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
        final item = it as Map<String, dynamic>;
        final symbol = item['Symbol']?.toString() ?? '';
        if (_matchesCurrentSymbol(symbol)) {
          final transformed = {
            'type': 'singleSymbolPrice',
            'symbol': symbol,
            'bid': item['Bid'],
            'ask': item['Ask'],
            'digits': item['Digits'],
            'last': item['Last'],
            'spreadDiff': item['SpreadDiff'],
            'volume': item['Volume'],
          };
          if (!_isDisposed) realTimePrice.value = transformed;
          if (!_priceStreamController.isClosed) {
            _priceStreamController.add(Map<String, dynamic>.from(transformed));
          }
          return;
        }
      }
    }
  }

  bool _matchesCurrentSymbol(String? responseSymbol) {
    final cur = currentSymbol.value;
    if (responseSymbol == null || cur.isEmpty) return false;
    final a = responseSymbol.replaceAll('.c', '');
    final b = cur.replaceAll('.c', '');
    return responseSymbol == cur || a == b || a.contains(b) || b.contains(a);
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
