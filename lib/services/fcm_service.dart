import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:crm_app/services/api_service.dart';
import 'package:crm_app/services/notification_service.dart';
import 'package:crm_app/controllers/app_notification_controller.dart';
import 'package:crm_app/controllers/account_controller.dart';

/// Top-level function for handling background FCM messages
/// This must be a top-level function, not a class method
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📱 Background FCM message received: ${message.messageId}');
  debugPrint('📱 Title: ${message.notification?.title}');
  debugPrint('📱 Body: ${message.notification?.body}');
  debugPrint('📱 Data: ${message.data}');

  // Show local notification for background messages
  final notificationService = NotificationService();
  await notificationService.initialize();

  if (message.notification != null) {
    final notification = message.notification!;
    final data = message.data;

    // Check if this is a price alert notification
    if (data['type'] == 'price_alert') {
      await notificationService.schedulePriceAlert(
        symbol: data['symbol'] ?? 'Unknown',
        targetPrice: double.tryParse(data['target_price'] ?? '0') ?? 0.0,
        condition: data['condition'] ?? 'above',
        currentPrice: double.tryParse(data['current_price'] ?? '0') ?? 0.0,
        message: notification.body,
      );
    }
  }
}

/// Firebase Cloud Messaging Service
/// Handles FCM token management, message handling, and backend synchronization
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  FirebaseMessaging? _messaging;
  String? _currentToken;
  bool _isInitialized = false;

  /// Initialize Firebase and FCM
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('FCMService: Already initialized');
      return;
    }

    try {
      debugPrint('🔥 FCMService: Initializing Firebase...');
      
      // Initialize Firebase (should be called before this, but ensure it's done)
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
        debugPrint('✅ FCMService: Firebase initialized');
      } else {
        debugPrint('✅ FCMService: Firebase already initialized');
      }

      // Initialize Firebase Messaging
      _messaging = FirebaseMessaging.instance;

      // Request notification permissions
      await _requestPermissions();

      // Get FCM token (non-blocking, don't fail if token unavailable)
      try {
        _currentToken = await _messaging?.getToken();
        debugPrint('FCMService: FCM Token retrieved: ${_currentToken?.substring(0, 20) ?? 'null'}...');
      } catch (e) {
        debugPrint('FCMService: Warning - Could not get FCM token: $e');
        // Continue initialization even if token fails
      }

      // Setup message handlers
      _setupMessageHandlers();

      // Setup token refresh listener
      _setupTokenRefresh();

      // Register background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      _isInitialized = true;
      debugPrint('✅ FCMService: Initialization complete');
    } catch (e) {
      debugPrint('❌ FCMService: Initialization failed: $e');
      // Don't rethrow - allow app to continue even if FCM fails
      _isInitialized = false;
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      if (_messaging == null) {
        debugPrint('FCMService: Messaging not initialized, skipping permissions');
        return;
      }
      
      if (Platform.isIOS) {
        NotificationSettings settings = await _messaging!.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        debugPrint('FCMService: iOS permission status: ${settings.authorizationStatus}');
      } else if (Platform.isAndroid) {
        // Android 13+ requires runtime permission
        await _messaging!.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('FCMService: Android permission requested');
      }
    } catch (e) {
      debugPrint('FCMService: Error requesting permissions: $e');
      // Don't rethrow - continue even if permissions fail
    }
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    // Don't auto-initialize here to avoid infinite loops
    if (!_isInitialized || _messaging == null) {
      debugPrint('FCMService: Not initialized, returning null token');
      return null;
    }

    if (_currentToken != null) {
      return _currentToken;
    }

    try {
      _currentToken = await _messaging?.getToken();
      debugPrint('FCMService: FCM Token retrieved: ${_currentToken?.substring(0, 20)}...');
      return _currentToken;
    } catch (e) {
      debugPrint('FCMService: Error getting token: $e');
      return null;
    }
  }

  /// Setup message handlers for foreground, background, and terminated states
  void _setupMessageHandlers() {
    // Foreground messages (when app is open)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background/terminated messages (when user taps notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

    // Check if app was opened from a terminated state via notification
    _messaging?.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('FCMService: App opened from terminated state via notification');
        _handleMessageOpened(message);
      }
    });
  }

  /// Handle foreground messages (app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📱 FCMService: Foreground message received');
    debugPrint('   Message ID: ${message.messageId}');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Body: ${message.notification?.body}');
    debugPrint('   Data: ${message.data}');

    try {
      final notificationService = Get.find<NotificationService>();
      final data = message.data;

      // Check if this is a price alert notification
      if (data['type'] == 'price_alert') {
        final symbol = data['symbol'] ?? 'Unknown';
        final targetPrice = double.tryParse(data['target_price'] ?? '0') ?? 0.0;
        final condition = data['condition'] ?? 'above';
        final currentPrice = double.tryParse(data['current_price'] ?? '0') ?? 0.0;

        // Show local notification
        await notificationService.schedulePriceAlert(
          symbol: symbol,
          targetPrice: targetPrice,
          condition: condition,
          currentPrice: currentPrice,
          message: message.notification?.body,
        );

        // Show in-app notification
        if (Get.isRegistered<AppNotificationController>()) {
          Get.find<AppNotificationController>().showSuccess(
            message: '$symbol price is ${condition == 'above' ? 'above' : 'below'} \$${targetPrice.toStringAsFixed(5)}',
            title: 'Price Alert Triggered!',
          );
        }
      } else {
        // Handle other notification types
        if (message.notification != null) {
          await notificationService.schedulePriceAlert(
            symbol: 'Notification',
            targetPrice: 0.0,
            condition: 'above',
            currentPrice: 0.0,
            message: message.notification?.body,
          );
        }
      }
    } catch (e) {
      debugPrint('FCMService: Error handling foreground message: $e');
    }
  }

  /// Handle message opened (user tapped notification)
  void _handleMessageOpened(RemoteMessage message) {
    debugPrint('📱 FCMService: Message opened (user tapped notification)');
    debugPrint('   Message ID: ${message.messageId}');
    debugPrint('   Data: ${message.data}');

    // Navigate to appropriate screen based on notification data
    final data = message.data;
    if (data['type'] == 'price_alert') {
      // Navigate to chart screen with the symbol
      final symbol = data['symbol'];
      if (symbol != null) {
        // You can add navigation logic here
        debugPrint('FCMService: Should navigate to chart for symbol: $symbol');
      }
    }
  }

  /// Setup token refresh listener
  void _setupTokenRefresh() {
    _messaging?.onTokenRefresh.listen((String newToken) {
      debugPrint('FCMService: Token refreshed: ${newToken.substring(0, 20)}...');
      _currentToken = newToken;
      
      // Update token on backend
      updateFcmTokenOnBackend(newToken);
    });
  }

  /// Update FCM token on Laravel backend
  Future<bool> updateFcmTokenOnBackend(String? token, {String? mt5AccountId}) async {
    if (token == null || token.isEmpty) {
      debugPrint('FCMService: No token to update');
      return false;
    }

    try {
      final deviceType = Platform.isAndroid ? 'android' : 'ios';
      final data = {
        'fcm_token': token,
        'device_type': deviceType,
      };

      // Add mt5_account_id if provided (for account-specific token updates)
      if (mt5AccountId != null && mt5AccountId.isNotEmpty) {
        data['mt5_account_id'] = mt5AccountId;
      }

      debugPrint('FCMService: Updating FCM token on backend...');
      final response = await ApiService.post(
        endpoint: '/api/user/price-alerts/update-fcm-token',
        data: data,
      );

      if (response.success) {
        debugPrint('✅ FCMService: Token updated on backend successfully');
        return true;
      } else {
        debugPrint('❌ FCMService: Failed to update token: ${response.message}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ FCMService: Error updating token on backend: $e');
      return false;
    }
  }

  /// Get device type
  String get deviceType => Platform.isAndroid ? 'android' : 'ios';

  /// Check if FCM is initialized
  bool get isInitialized => _isInitialized;

  /// Get current token (synchronous getter)
  String? get currentToken => _currentToken;
}
