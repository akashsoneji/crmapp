import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/api_const.dart';
import 'package:pipze/controllers/account_controller.dart';
import 'package:pipze/controllers/trading_controller.dart';
import 'package:pipze/models/websocket_trading_response.dart';
import 'package:pipze/services/secure_storage_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TradingWebSocketService extends GetxService with WidgetsBindingObserver {
  // Connection state
  final RxBool isConnected = false.obs;
  final RxBool isReconnecting = false.obs;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  bool _isDisposed = false;
  late WebSocketChannel channel;

  // Controllers
  late TradingController _tradingController;
  late AccountController _accountController;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    // Initialize controllers
    _tradingController = Get.find<TradingController>();
    _accountController = Get.find<AccountController>();

    // Initialize WebSocket connection
    _initializeWebSocket();
  }

  @override
  void onClose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _disconnectWebSocket();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        if (!isConnected.value && !_isDisposed) {
          dev.log('Trading WS: App resumed, reconnecting...');
          _initializeWebSocket();
        }
        break;
      case AppLifecycleState.paused:
        dev.log('Trading WS: App paused, maintaining connection');
        break;
      case AppLifecycleState.detached:
        dev.log('Trading WS: App detached, closing connection');
        _disconnectWebSocket();
        break;
      case AppLifecycleState.inactive:
        dev.log('Trading WS: App inactive');
        break;
      case AppLifecycleState.hidden:
        dev.log('Trading WS: App hidden');
        break;
    }
  }

  // Initialize WebSocket connection
  void _initializeWebSocket() {
    if (isConnected.value) return;

    try {
      channel = WebSocketChannel.connect(Uri.parse(ApiConstants.socketUrl));
      isConnected.value = true;
      _reconnectAttempts = 0;
      isReconnecting.value = false;

      dev.log('Trading WS: Connected successfully');

      channel.stream.listen(
        (message) => _handleSocketMessage(message),
        onError: (error) {
          dev.log('Trading WS error: $error');
          isConnected.value = false;
          _scheduleReconnect();
        },
        onDone: () {
          dev.log('Trading WS: Connection closed');
          isConnected.value = false;
          _scheduleReconnect();
        },
      );

      // Request trading data after connection
      Future.delayed(const Duration(milliseconds: 100), () {
        if (isConnected.value && !_isDisposed) {
          _requestTradingData();
        }
      });
    } catch (e) {
      dev.log('Trading WS: Initialization failed: $e');
      isConnected.value = false;
      _scheduleReconnect();
    }
  }

  // Request trading data from WebSocket
  void _requestTradingData() async {
    if (_isDisposed) return;

    final authId = await SecureStorageService.getWebsocketToken();
    if (authId == null || authId.isEmpty) {
      dev.log('Trading WS: No auth token, retrying in 2 seconds...');
      Timer(const Duration(seconds: 2), () {
        if (isConnected.value && !_isDisposed) {
          _requestTradingData();
        }
      });
      return;
    }

    final activeAccount = _accountController.activeMT5Account;
    final accountNumber = activeAccount?.metaAccountNumber ?? "0";

    dev.log('Trading WS: Requesting data for account: $accountNumber');

    // Request open positions
    _sendEvent({
      "type": "openPositions",
      "authID": authId,
      "mt5AccountNumber": int.tryParse(accountNumber) ?? 0,
      "isapp": "1",
    });

    // Request pending orders
    _sendEvent({
      "type": "pendingOrders",
      "authID": authId,
      "mt5AccountNumber": int.tryParse(accountNumber) ?? 0,
      "isapp": "1",
    });
  }

  // Send event to WebSocket
  void _sendEvent(Map<String, dynamic> event) {
    if (!isConnected.value || _isDisposed) return;

    try {
      final message = jsonEncode(event);
      channel.sink.add(message);
      dev.log('Trading WS: Sent event: $event');
    } catch (e) {
      dev.log('Trading WS: Error sending event: $e');
    }
  }

  // Handle incoming WebSocket messages
  void _handleSocketMessage(dynamic message) {
    if (_isDisposed) return;

    try {
      final Map<String, dynamic> data = jsonDecode(message);
      // dev.log('Trading WS: Received data: $data');

      // Check if this is trading data
      if (data.containsKey('openPositions') ||
          data.containsKey('pendingOrders')) {
        final tradingResponse = WebSocketTradingResponse.fromJson(data);
        _tradingController.updateWebSocketData(tradingResponse);
        // dev.log('Trading WS: Updated trading data successfully');
      }
    } catch (e) {
      dev.log('Trading WS: Error parsing message: $e');
    }
  }

  // Schedule reconnection
  void _scheduleReconnect() {
    if (_isDisposed || _reconnectAttempts >= _maxReconnectAttempts) {
      dev.log('Trading WS: Max reconnection attempts reached or disposed');
      return;
    }

    if (isReconnecting.value) return;

    isReconnecting.value = true;
    _reconnectAttempts++;

    dev.log(
      'Trading WS: Scheduling reconnect attempt $_reconnectAttempts in ${_reconnectDelay.inSeconds}s',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (!_isDisposed) {
        dev.log('Trading WS: Attempting reconnection...');
        _initializeWebSocket();
      }
    });
  }

  // Disconnect WebSocket
  void _disconnectWebSocket() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    if (isConnected.value) {
      try {
        channel.sink.close();
        dev.log('Trading WS: Disconnected');
      } catch (e) {
        dev.log('Trading WS: Error during disconnect: $e');
      }
    }

    isConnected.value = false;
    isReconnecting.value = false;
  }

  // Manual reconnection
  void reconnect() {
    if (_isDisposed) return;

    dev.log('Trading WS: Manual reconnection requested');
    _disconnectWebSocket();
    _reconnectAttempts = 0;
    _initializeWebSocket();
  }

  // Manual disconnect
  void disconnect() {
    dev.log('Trading WS: Manual disconnect requested');
    _disconnectWebSocket();
  }

  // Refresh trading data
  void refreshTradingData() {
    if (isConnected.value && !_isDisposed) {
      dev.log('Trading WS: Manual refresh requested');
      _requestTradingData();
    } else {
      dev.log('Trading WS: Cannot refresh - not connected or disposed');
    }
  }

  // Force refresh trading data (clears cache and requests fresh data)
  void forceRefreshTradingData() {
    dev.log('Trading WS: Force refresh requested');

    // Clear all trading data first
    _tradingController.clearAllTradingData();

    // Request fresh data
    if (isConnected.value && !_isDisposed) {
      _requestTradingData();
    } else {
      dev.log('Trading WS: Cannot force refresh - not connected or disposed');
    }
  }

  // Clear all trading data and disconnect (called on logout)
  void clearAllDataAndDisconnect() {
    dev.log('Trading WS: Clearing all data and disconnecting...');

    // Disconnect WebSocket
    _disconnectWebSocket();

    // Clear trading controller data if it exists
    try {
      if (Get.isRegistered<TradingController>()) {
        final tradingController = Get.find<TradingController>();
        tradingController.clearAllTradingData();
        dev.log('Trading WS: Cleared trading controller data');
      }
    } catch (e) {
      dev.log('Trading WS: Error clearing trading controller: $e');
    }

    // Reset reconnection attempts
    _reconnectAttempts = 0;

    dev.log('Trading WS: Data cleared and disconnected successfully');
  }

  // Reset and reconnect with new account (called on login)
  void resetAndReconnect() {
    dev.log('Trading WS: Resetting and reconnecting...');

    // Clear all data first
    clearAllDataAndDisconnect();

    // Reset disposed flag
    _isDisposed = false;

    // Reconnect after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isDisposed) {
        _initializeWebSocket();
      }
    });

    dev.log('Trading WS: Reset and reconnect initiated');
  }
}
