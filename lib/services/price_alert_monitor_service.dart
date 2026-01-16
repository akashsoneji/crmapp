import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crm_app/controllers/chart_socket_controller.dart';
import 'package:crm_app/controllers/app_notification_controller.dart';
import 'package:crm_app/controllers/account_controller.dart';
import 'package:crm_app/services/notification_service.dart';
import 'package:crm_app/services/fcm_service.dart';
import 'package:crm_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PriceAlertMonitorService extends GetxController {
  static final PriceAlertMonitorService _instance =
      PriceAlertMonitorService._internal();
  factory PriceAlertMonitorService() => _instance;
  PriceAlertMonitorService._internal();

  final NotificationService _notificationService = NotificationService();
  Timer? _monitoringTimer;
  final List<Map<String, dynamic>> _activeAlerts = [];
  bool _isMonitoring = false;

  // Chart socket controller for real-time price data
  ChartSocketController? _chartSocketController;

  @override
  void onInit() {
    super.onInit();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _notificationService.initialize();
    await _loadActiveAlerts();

    // Try to find ChartSocketController
    try {
      _chartSocketController = Get.find<ChartSocketController>();
      debugPrint('✅ Found existing ChartSocketController');
    } catch (e) {
      debugPrint('❌ ChartSocketController not found: $e');
      // Try to create one
      try {
        _chartSocketController = Get.put(ChartSocketController());
        debugPrint('✅ Created new ChartSocketController');
      } catch (e2) {
        debugPrint('❌ Failed to create ChartSocketController: $e2');
      }
    }

    _startMonitoring();
  }

  Future<void> _loadActiveAlerts() async {
    try {
      // First, try to sync from backend
      await syncAlertsWithBackend();

      // Then load from local storage as backup
      final prefs = await SharedPreferences.getInstance();
      final List<String> alerts = prefs.getStringList('price_alerts') ?? [];

      // Only add local alerts that don't exist in backend (for offline support)
      for (String alertStr in alerts) {
        try {
          final Map<String, dynamic> alert = json.decode(alertStr);
          if (alert['isActive'] == true) {
            // Check if this alert already exists in _activeAlerts
            final exists = _activeAlerts.any((a) => 
              a['id'] == alert['id'] || 
              (a['backend_id'] != null && a['backend_id'] == alert['backend_id'])
            );
            if (!exists) {
              _activeAlerts.add(alert);
            }
          }
        } catch (e) {
          debugPrint('Error parsing alert: $e');
        }
      }

      debugPrint('Loaded ${_activeAlerts.length} active price alerts');
    } catch (e) {
      debugPrint('Error loading active alerts: $e');
    }
  }

  /// Sync alerts from backend API
  Future<void> syncAlertsWithBackend() async {
    try {
      // Get current MT5 account ID (backend expects database ID)
      int? mt5AccountId;
      try {
        if (Get.isRegistered<AccountController>()) {
          final accountController = Get.find<AccountController>();
          final activeAccount = accountController.activeMT5Account;
          if (activeAccount != null) {
            mt5AccountId = activeAccount.id;
          }
        }
      } catch (e) {
        debugPrint('⚠️ MT5 account ID not available for sync: $e');
        return; // Can't sync without account ID
      }

      if (mt5AccountId == null || mt5AccountId == 0) {
        debugPrint('⚠️ Skipping backend sync - no MT5 account ID');
        return;
      }

      debugPrint('📡 Syncing alerts from backend for account ID: $mt5AccountId');
      final response = await ApiService.get(
        endpoint: '/api/user/price-alerts?mt5_account_id=$mt5AccountId',
      );

      if (response.success && response.data != null) {
        // Backend returns: { 'alerts': [...] }
        final List<dynamic> alertsData = response.data['alerts'] as List? ?? [];

        debugPrint('✅ Fetched ${alertsData.length} alerts from backend');

        // Get FCM token for updating existing alerts
        String? fcmToken;
        try {
          if (Get.isRegistered<FCMService>()) {
            fcmToken = await Get.find<FCMService>().getToken();
          }
        } catch (e) {
          debugPrint('⚠️ FCM token not available: $e');
        }

        // Clear and rebuild active alerts from backend
        _activeAlerts.clear();
        final prefs = await SharedPreferences.getInstance();
        final List<String> alertsToSave = [];

        for (var alertData in alertsData) {
          try {
            final Map<String, dynamic> alert = Map<String, dynamic>.from(alertData);
            
            // Convert backend format to local format
            final localAlert = {
              'id': alert['id'] as int,
              'backend_id': alert['id'] as int, // Store backend ID
              'symbol': alert['symbol'] as String? ?? '',
              'targetPrice': (alert['target_price'] as num?)?.toDouble() ?? 0.0,
              'condition': alert['condition'] as String? ?? 'above',
              'currentPrice': 0.0, // Will be updated when monitoring
              'message': alert['message'] as String?,
              'createdAt': alert['created_at'] as String? ?? DateTime.now().toIso8601String(),
              'isActive': (alert['is_active'] as bool?) ?? true,
              'fcm_token': alert['fcm_token'] as String? ?? fcmToken,
            };

            _activeAlerts.add(localAlert);
            alertsToSave.add(json.encode(localAlert));

            // Update FCM token if it's missing and we have one
            if ((alert['fcm_token'] == null || (alert['fcm_token'] as String).isEmpty) && 
                fcmToken != null && fcmToken.isNotEmpty) {
              try {
                await ApiService.put(
                  endpoint: '/api/user/price-alerts/${alert['id']}',
                  data: {
                    'fcm_token': fcmToken,
                    'device_type': Get.isRegistered<FCMService>()
                        ? Get.find<FCMService>().deviceType
                        : 'android',
                  },
                );
                debugPrint('✅ Updated FCM token for alert ${alert['id']}');
              } catch (e) {
                debugPrint('⚠️ Failed to update FCM token: $e');
              }
            }
          } catch (e) {
            debugPrint('⚠️ Error processing alert from backend: $e');
          }
        }

        // Save synced alerts to local storage
        await prefs.setStringList('price_alerts', alertsToSave);
        debugPrint('✅ Synced ${_activeAlerts.length} alerts from backend');
      } else {
        debugPrint('⚠️ Backend sync failed: ${response.message}');
      }
    } catch (e) {
      debugPrint('⚠️ Error syncing alerts from backend: $e');
      // Continue with local storage if backend fails
    }
  }

  void _startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _monitoringTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkPriceAlerts();
    });

    debugPrint('🔄 ===== PRICE ALERT MONITORING STARTED =====');
    debugPrint('⏰ Checking prices every 2 seconds');
    debugPrint('📊 Active alerts: ${_activeAlerts.length}');
    debugPrint(
      '🎯 Current symbol: ${_chartSocketController?.currentSymbol.value ?? 'Unknown'}',
    );
  }

  void _stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _isMonitoring = false;
    debugPrint('Price alert monitoring stopped');
  }

  void _checkPriceAlerts() {
    if (_activeAlerts.isEmpty) {
      debugPrint('No active alerts to check');
      return;
    }

    // Get chart socket controller if not already set
    if (_chartSocketController == null) {
      try {
        _chartSocketController = Get.find<ChartSocketController>();
      } catch (e) {
        debugPrint('ChartSocketController not found: $e');
        return;
      }
    }

    // Check if ChartSocketController is connected
    if (!_chartSocketController!.isConnected.value) {
      debugPrint(
        '⚠️ ChartSocketController not connected, attempting to reconnect...',
      );
      // Try to reconnect for the first active alert's symbol
      if (_activeAlerts.isNotEmpty) {
        final firstAlert = _activeAlerts.first;
        final symbol = firstAlert['symbol'] as String;
        ensureChartSocketConnected(symbol);
      }
      return; // Skip this check cycle, will try again next time
    }

    // Get current market price (average of bid and ask)
    final currentPrice = _chartSocketController!.getMarketPrice();
    if (currentPrice == null) {
      debugPrint('No current market price data available');
      return;
    }

    final currentSymbol = _chartSocketController!.currentSymbol.value;
    final bidPrice = _chartSocketController!.getBidPrice();
    final askPrice = _chartSocketController!.getAskPrice();
    debugPrint(
      '🔍 Checking alerts for $currentSymbol: Bid=$bidPrice, Ask=$askPrice, Market=$currentPrice (${_activeAlerts.length} active alerts)',
    );

    // Check each active alert
    for (int i = _activeAlerts.length - 1; i >= 0; i--) {
      final alert = _activeAlerts[i];
      final symbol = alert['symbol'] as String;
      final targetPrice = alert['targetPrice'] as double;
      final condition = alert['condition'] as String;

      // Check if this alert is for the current symbol
      final currentSymbol = _chartSocketController!.currentSymbol.value;
      if (symbol != currentSymbol) {
        debugPrint('⏭️ Skipping alert for $symbol (current: $currentSymbol)');
        continue;
      }

      debugPrint(
        '🎯 Checking alert: $symbol $condition $targetPrice vs current $currentPrice',
      );

      // Calculate difference for better debugging
      final difference =
          condition == 'above'
              ? currentPrice - targetPrice
              : targetPrice - currentPrice;
      final isClose = difference.abs() < 0.0001; // Within 0.0001

      debugPrint(
        '📊 Price difference: ${difference.toString()} (${isClose ? 'CLOSE!' : 'not close'})',
      );

      bool shouldTrigger = false;

      if (condition == 'above' && currentPrice >= targetPrice) {
        shouldTrigger = true;
        debugPrint('✅ ABOVE condition met: $currentPrice >= $targetPrice');
      } else if (condition == 'below' && currentPrice <= targetPrice) {
        shouldTrigger = true;
        debugPrint('✅ BELOW condition met: $currentPrice <= $targetPrice');
      } else {
        debugPrint(
          '❌ Condition not met: $currentPrice $condition $targetPrice',
        );
        if (isClose) {
          debugPrint(
            '⚠️  VERY CLOSE! Only ${difference.abs().toString()} away from trigger',
          );
        }
      }

      if (shouldTrigger) {
        debugPrint(
          'Price alert triggered: $symbol $condition $targetPrice (current: $currentPrice)',
        );
        _triggerPriceAlert(alert, currentPrice);

        // Remove the triggered alert
        _activeAlerts.removeAt(i);
        _removeAlertFromStorage(alert['id'] as int);
      }
    }
  }

  Future<void> _triggerPriceAlert(
    Map<String, dynamic> alert,
    double currentPrice,
  ) async {
    final symbol = alert['symbol'] as String;
    final targetPrice = alert['targetPrice'] as double;
    final condition = alert['condition'] as String;
    final message = alert['message'] as String?;
    final alertId = alert['id'] as int;

    debugPrint('🚨 ===== TRIGGERING PRICE ALERT =====');
    debugPrint('📊 Alert Details:');
    debugPrint('   - Symbol: $symbol');
    debugPrint('   - Target Price: ${targetPrice.toString()}');
    debugPrint('   - Current Price: ${currentPrice.toString()}');
    debugPrint('   - Condition: $condition');
    debugPrint('   - Alert ID: $alertId');

    // Try multiple times to ensure notification is sent
    bool notificationSent = false;
    int attempts = 0;
    const maxAttempts = 3;

    while (!notificationSent && attempts < maxAttempts) {
      attempts++;
      debugPrint('🔄 Attempt $attempts/$maxAttempts to send notification...');

      try {
        // Check notification permissions first
        if (!_notificationService.hasPermission) {
          debugPrint('❌ No notification permission, requesting...');
          final granted = await _notificationService.requestPermissions();
          if (!granted) {
            debugPrint('❌ Permission denied, cannot send notification');
            break;
          }
        }

        // Show notification
        await _notificationService.schedulePriceAlert(
          symbol: symbol,
          targetPrice: targetPrice,
          condition: condition,
          currentPrice: currentPrice,
          message: message,
        );

        notificationSent = true;
        debugPrint('✅ Notification sent successfully on attempt $attempts');

        // Show in-app notification
        if (Get.isRegistered<AppNotificationController>()) {
          Get.find<AppNotificationController>().showSuccess(
            message: '$symbol price is ${condition == 'above' ? 'above' : 'below'} \$${targetPrice.toString()}',
            title: 'Price Alert Triggered!',
          );
        }

        debugPrint('✅ In-app notification shown');
        debugPrint('🚨 ===== ALERT TRIGGERED SUCCESSFULLY =====');
      } catch (e) {
        debugPrint('❌ Attempt $attempts failed: $e');
        if (attempts < maxAttempts) {
          debugPrint('⏳ Waiting 1 second before retry...');
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    if (!notificationSent) {
      debugPrint('❌ Failed to send notification after $maxAttempts attempts');
      // Show error notification
      if (Get.isRegistered<AppNotificationController>()) {
        Get.find<AppNotificationController>().showError(
          message: '$symbol reached \$${targetPrice.toString()} but notification failed',
          title: 'Alert Triggered (No Notification)',
        );
      }
    }
  }

  Future<void> _removeAlertFromStorage(int alertId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> alerts = prefs.getStringList('price_alerts') ?? [];

      for (int i = 0; i < alerts.length; i++) {
        try {
          final Map<String, dynamic> alert = json.decode(alerts[i]);
          if (alert['id'] == alertId) {
            alert['isActive'] = false;
            alerts[i] = json.encode(alert);
            break;
          }
        } catch (e) {
          debugPrint('Error parsing alert: $e');
        }
      }

      await prefs.setStringList('price_alerts', alerts);
    } catch (e) {
      debugPrint('Error removing alert from storage: $e');
    }
  }

  // Add new alert to monitoring
  Future<void> addPriceAlert({
    required String symbol,
    required double targetPrice,
    required String condition,
    required double currentPrice,
    String? message,
  }) async {
    try {
      // Ensure ChartSocketController is connected for this symbol
      await ensureChartSocketConnected(symbol);

      // Get current market data for detailed logging
      final bidPrice = _chartSocketController?.getBidPrice();
      final askPrice = _chartSocketController?.getAskPrice();
      final marketPrice = _chartSocketController?.getMarketPrice();

      // Debug price data availability
      debugPrint('🔍 Price data check:');
      debugPrint(
        '   - ChartSocketController connected: ${_chartSocketController?.isConnected.value ?? false}',
      );
      debugPrint(
        '   - Current symbol: ${_chartSocketController?.currentSymbol.value ?? 'Unknown'}',
      );
      debugPrint(
        '   - Bid price available: ${bidPrice != null} (${bidPrice?.toString() ?? 'null'})',
      );
      debugPrint(
        '   - Ask price available: ${askPrice != null} (${askPrice?.toString() ?? 'null'})',
      );
      debugPrint(
        '   - Market price available: ${marketPrice != null} (${marketPrice?.toString() ?? 'null'})',
      );
      debugPrint('   - Current price from dialog: ${currentPrice.toString()}');

      // Use currentPrice as fallback if market data is not available
      final finalBidPrice = bidPrice ?? currentPrice;
      final finalAskPrice = askPrice ?? currentPrice;
      final finalMarketPrice = marketPrice ?? currentPrice;

      debugPrint('🚨 ===== SETTING NEW PRICE ALERT =====');
      debugPrint('📊 Symbol: $symbol');
      debugPrint('💰 Current Prices:');
      debugPrint('   - Bid Price (SELL): ${finalBidPrice.toString()}');
      debugPrint('   - Ask Price (BUY): ${finalAskPrice.toString()}');
      debugPrint('   - Market Price (Alert): ${finalMarketPrice.toString()}');
      debugPrint('🎯 Alert Settings:');
      debugPrint('   - Target Price: ${targetPrice.toString()}');
      debugPrint('   - Condition: $condition');
      debugPrint('   - Message: ${message ?? 'No message'}');

      // Calculate difference and show status
      final difference =
          condition == 'above'
              ? targetPrice - finalMarketPrice
              : finalMarketPrice - targetPrice;
      final isAlreadyTriggered =
          condition == 'above'
              ? finalMarketPrice >= targetPrice
              : finalMarketPrice <= targetPrice;

      debugPrint('📈 Price Analysis:');
      debugPrint('   - Difference: ${difference.toString()}');
      debugPrint(
        '   - Status: ${isAlreadyTriggered ? 'ALREADY TRIGGERED!' : 'Waiting for trigger'}',
      );

      if (isAlreadyTriggered) {
        debugPrint('⚠️  WARNING: Alert condition is already met!');
        debugPrint(
          '   Current market price (${finalMarketPrice.toString()}) ${condition == 'above' ? '≥' : '≤'} target price (${targetPrice.toString()})',
        );
        debugPrint('🚨 TRIGGERING ALERT IMMEDIATELY!');

        // Create alert object for immediate triggering
        final immediateAlert = {
          'id': DateTime.now().millisecondsSinceEpoch % 100000,
          'symbol': symbol,
          'targetPrice': targetPrice,
          'condition': condition,
          'currentPrice': finalMarketPrice,
          'message': message,
          'createdAt': DateTime.now().toIso8601String(),
          'isActive': true,
        };

        // Trigger immediately
        _triggerPriceAlert(immediateAlert, finalMarketPrice);
        debugPrint('✅ Immediate alert triggered!');
        return; // Don't save this alert since it's already triggered
      } else {
        debugPrint(
          '✅ Alert will trigger when market price ${condition == 'above' ? '≥' : '≤'} ${targetPrice.toString()}',
        );
      }

      // Get FCM token
      String? fcmToken;
      try {
        if (Get.isRegistered<FCMService>()) {
          fcmToken = await Get.find<FCMService>().getToken();
        }
      } catch (e) {
        debugPrint('⚠️ FCM token not available: $e');
      }

      // Get current MT5 account ID (backend expects database ID)
      int? mt5AccountId;
      try {
        if (Get.isRegistered<AccountController>()) {
          final accountController = Get.find<AccountController>();
          final activeAccount = accountController.activeMT5Account;
          if (activeAccount != null) {
            mt5AccountId = activeAccount.id;
          }
        }
      } catch (e) {
        debugPrint('⚠️ MT5 account ID not available: $e');
      }

      // Create alert on backend via API
      int? backendAlertId;
      try {
        if (fcmToken != null && fcmToken.isNotEmpty && mt5AccountId != null && mt5AccountId > 0) {
          debugPrint('📡 Sending alert to backend API...');
          final response = await ApiService.post(
            endpoint: '/api/user/price-alerts',
            data: {
              'mt5_account_id': mt5AccountId,
              'symbol': symbol,
              'target_price': targetPrice,
              'condition': condition,
              'fcm_token': fcmToken,
              'device_type': Get.isRegistered<FCMService>()
                  ? Get.find<FCMService>().deviceType
                  : 'android',
              if (message != null && message.isNotEmpty) 'message': message,
            },
          );

          if (response.success && response.data != null) {
            backendAlertId = response.data['id'] as int?;
            debugPrint('✅ Alert created on backend with ID: $backendAlertId');
          } else {
            debugPrint('⚠️ Backend API call failed: ${response.message}');
          }
        } else {
          debugPrint('⚠️ Skipping backend API call (missing FCM token or MT5 account ID)');
          if (fcmToken == null || fcmToken.isEmpty) {
            debugPrint('   - FCM token is missing');
          }
          if (mt5AccountId == null || mt5AccountId == 0) {
            debugPrint('   - MT5 account ID is missing or invalid');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error creating alert on backend: $e');
        // Continue with local storage even if backend fails
      }

      // Generate unique ID (use backend ID if available, otherwise local ID)
      final int alertId = backendAlertId ?? (DateTime.now().millisecondsSinceEpoch % 100000);

      final Map<String, dynamic> alert = {
        'id': alertId,
        'backend_id': backendAlertId, // Store backend ID separately
        'symbol': symbol,
        'targetPrice': targetPrice,
        'condition': condition,
        'currentPrice': currentPrice,
        'message': message,
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': true,
        'fcm_token': fcmToken, // Store FCM token for reference
      };

      // Add to active alerts
      _activeAlerts.add(alert);

      // Save to storage
      final prefs = await SharedPreferences.getInstance();
      final List<String> alerts = prefs.getStringList('price_alerts') ?? [];
      alerts.add(json.encode(alert));
      await prefs.setStringList('price_alerts', alerts);

      debugPrint('✅ Alert saved successfully!');
      debugPrint('📱 Total active alerts: ${_activeAlerts.length}');
      debugPrint('🔄 Monitoring will check every 2 seconds');
      debugPrint('🚨 ===== ALERT SETUP COMPLETE =====');
    } catch (e) {
      debugPrint('❌ Error adding price alert: $e');
    }
  }

  // Get active alerts count
  int get activeAlertsCount => _activeAlerts.length;

  // Get active alerts for current symbol
  List<Map<String, dynamic>> getActiveAlertsForSymbol(String symbol) {
    return _activeAlerts.where((alert) => alert['symbol'] == symbol).toList();
  }

  // Cancel specific alert
  Future<void> cancelAlert(int alertId) async {
    try {
      // Find the alert to get backend ID
      final alert = _activeAlerts.firstWhere(
        (a) => a['id'] == alertId,
        orElse: () => {},
      );

      // Delete from backend if backend_id exists
      final backendId = alert['backend_id'] as int?;
      if (backendId != null) {
        try {
          debugPrint('📡 Deleting alert from backend (ID: $backendId)...');
          final response = await ApiService.delete(
            endpoint: '/api/user/price-alerts/$backendId',
          );
          if (response.success) {
            debugPrint('✅ Alert deleted from backend');
          } else {
            debugPrint('⚠️ Backend deletion failed: ${response.message}');
          }
        } catch (e) {
          debugPrint('⚠️ Error deleting alert from backend: $e');
          // Continue with local deletion even if backend fails
        }
      }

      _activeAlerts.removeWhere((alert) => alert['id'] == alertId);
      await _removeAlertFromStorage(alertId);
      debugPrint('Cancelled alert: $alertId');
    } catch (e) {
      debugPrint('Error cancelling alert: $e');
    }
  }

  // Cancel all alerts for a symbol
  Future<void> cancelAllAlertsForSymbol(String symbol) async {
    try {
      final alertsToRemove =
          _activeAlerts.where((alert) => alert['symbol'] == symbol).toList();

      for (final alert in alertsToRemove) {
        await cancelAlert(alert['id'] as int);
      }

      debugPrint('Cancelled all alerts for symbol: $symbol');
    } catch (e) {
      debugPrint('Error cancelling alerts for symbol: $e');
    }
  }

  // Test method to manually trigger an alert
  Future<void> testTriggerAlert(String symbol, double currentPrice) async {
    try {
      debugPrint('🧪 Testing alert trigger for $symbol at $currentPrice');

      // Create a test alert
      final testAlert = {
        'id': 999999,
        'symbol': symbol,
        'targetPrice': currentPrice,
        'condition': 'above',
        'currentPrice': currentPrice,
        'message': 'Test alert triggered',
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': true,
      };

      await _triggerPriceAlert(testAlert, currentPrice);
      debugPrint('✅ Test alert triggered successfully');
    } catch (e) {
      debugPrint('❌ Error triggering test alert: $e');
    }
  }

  // Add a test alert for specific price scenario
  Future<void> addTestAlert(
    String symbol,
    double targetPrice,
    String condition,
  ) async {
    try {
      final currentPrice = _chartSocketController?.getMarketPrice() ?? 1.14252;
      debugPrint(
        '🧪 Adding test alert: $symbol $condition $targetPrice (current: $currentPrice)',
      );

      await addPriceAlert(
        symbol: symbol,
        targetPrice: targetPrice,
        condition: condition,
        currentPrice: currentPrice,
        message: 'Test alert for debugging',
      );

      debugPrint('✅ Test alert added successfully');
    } catch (e) {
      debugPrint('❌ Error adding test alert: $e');
    }
  }

  // Test notification system directly
  Future<void> testNotificationSystem() async {
    try {
      debugPrint('🧪 ===== TESTING NOTIFICATION SYSTEM =====');

      // Test notification service directly
      await _notificationService.showTestNotification();

      debugPrint('✅ Test notification sent successfully');
      debugPrint('🧪 ===== NOTIFICATION TEST COMPLETE =====');
    } catch (e) {
      debugPrint('❌ Error testing notification system: $e');
    }
  }

  // Force ChartSocketController to connect and set symbol
  Future<void> ensureChartSocketConnected(String symbol) async {
    try {
      debugPrint('🔌 ===== ENSURING CHART SOCKET CONNECTION =====');
      debugPrint('📊 Target Symbol: $symbol');

      if (_chartSocketController == null) {
        debugPrint('❌ ChartSocketController is null, trying to find/create...');
        try {
          _chartSocketController = Get.find<ChartSocketController>();
          debugPrint('✅ Found existing ChartSocketController');
        } catch (e) {
          debugPrint('❌ ChartSocketController not found: $e');
          try {
            _chartSocketController = Get.put(ChartSocketController());
            debugPrint('✅ Created new ChartSocketController');
          } catch (e2) {
            debugPrint('❌ Failed to create ChartSocketController: $e2');
            return;
          }
        }
      }

      debugPrint('🔍 Current Status:');
      debugPrint(
        '   - Connected: ${_chartSocketController!.isConnected.value}',
      );
      debugPrint(
        '   - Current Symbol: ${_chartSocketController!.currentSymbol.value}',
      );

      if (!_chartSocketController!.isConnected.value) {
        debugPrint('🔄 Not connected, attempting to connect...');
        try {
          await _chartSocketController!.changeSymbol(symbol);
          debugPrint('✅ Connection attempt completed');
        } catch (e) {
          debugPrint('❌ Connection failed: $e');
        }
      }

      if (_chartSocketController!.currentSymbol.value != symbol) {
        debugPrint('🔄 Symbol mismatch, changing symbol...');
        try {
          await _chartSocketController!.changeSymbol(symbol);
          debugPrint('✅ Symbol changed successfully');
        } catch (e) {
          debugPrint('❌ Symbol change failed: $e');
        }
      }

      debugPrint('🔍 Final Status:');
      debugPrint(
        '   - Connected: ${_chartSocketController!.isConnected.value}',
      );
      debugPrint(
        '   - Current Symbol: ${_chartSocketController!.currentSymbol.value}',
      );
      debugPrint('🔌 ===== CONNECTION CHECK COMPLETE =====');
    } catch (e) {
      debugPrint('❌ Error ensuring ChartSocket connection: $e');
    }
  }

  // Get current monitoring status
  Map<String, dynamic> getMonitoringStatus() {
    return {
      'isMonitoring': _isMonitoring,
      'activeAlertsCount': _activeAlerts.length,
      'currentSymbol': _chartSocketController?.currentSymbol.value ?? 'Unknown',
      'currentPrice': _chartSocketController?.getMarketPrice() ?? 0.0,
      'alerts':
          _activeAlerts
              .map(
                (alert) => {
                  'symbol': alert['symbol'],
                  'targetPrice': alert['targetPrice'],
                  'condition': alert['condition'],
                },
              )
              .toList(),
    };
  }

  @override
  void onClose() {
    _stopMonitoring();
    super.onClose();
  }
}
