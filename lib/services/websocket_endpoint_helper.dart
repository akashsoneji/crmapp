import 'package:flutter/foundation.dart';
import 'package:pipze/constants/api_const.dart';
import 'package:pipze/models/mt5_account.dart';
import 'package:pipze/services/api_service.dart';
import 'package:pipze/services/secure_storage_service.dart';

/// Centralized WebSocket endpoint management
/// Provides consistent endpoint selection based on account type (MT5 vs Self-hosted)
class WebSocketEndpointHelper {
  // ==================== CACHE FOR PRIMARY ACCOUNT ====================
  static MT5Account? _cachedPrimaryAccount;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidity = Duration(minutes: 5);

  // ✅ FIX: Store primary account set during app initialization
  static MT5Account? _initializedPrimaryAccount;

  /// Set primary account during app initialization
  static void setPrimaryAccount(MT5Account? account) {
    _initializedPrimaryAccount = account;
    _cachedPrimaryAccount = account;
    _cacheTimestamp = account != null ? DateTime.now() : null;
    if (kDebugMode) {
      print(
        'WebSocketEndpointHelper: Primary account set: ${account?.metaAccountNumber ?? "null"} (${account?.tradingServer ?? "N/A"})',
      );
    }
  }

  /// Get stored primary account (set during initialization)
  static MT5Account? getStoredPrimaryAccount() {
    return _initializedPrimaryAccount ?? _cachedPrimaryAccount;
  }

  // ==================== SELF-HOSTED ENDPOINTS (DEFAULT) ====================
  static const String selfHostedOpenPositions = '/ws/op';
  static const String selfHostedPendingOrders = '/ws/po';
  static const String selfHostedSymbol = '/ws/symbol';
  static const String selfHostedMarketWatch = '/ws/marketwatch';
  static const String selfHostedAccount = '/ws/accounts';

  // ==================== MT5 ENDPOINTS ====================
  static const String mt5OpenPositions = '/ws/mt5/op';
  static const String mt5PendingOrders = '/ws/mt5/po';
  static const String mt5Symbol = '/ws/mt5/symbol';
  static const String mt5MarketWatch = '/ws/mt5/marketwatch';
  static const String mt5Account = '/ws/mt5/account';

  // ==================== ENDPOINT GETTERS ====================

  /// Get open positions endpoint based on account type
  /// Returns MT5 endpoint if account is MT5, otherwise self-hosted
  /// Uses stored primary account as fallback if provided account is null
  static String getOpenPositionsEndpoint(MT5Account? account) {
    final accountToUse = account ?? getStoredPrimaryAccount();
    return _isMT5Account(accountToUse)
        ? mt5OpenPositions
        : selfHostedOpenPositions;
  }

  /// Get pending orders endpoint based on account type
  /// Returns MT5 endpoint if account is MT5, otherwise self-hosted
  /// Uses stored primary account as fallback if provided account is null
  static String getPendingOrdersEndpoint(MT5Account? account) {
    final accountToUse = account ?? getStoredPrimaryAccount();
    return _isMT5Account(accountToUse)
        ? mt5PendingOrders
        : selfHostedPendingOrders;
  }

  /// Get symbol endpoint based on account type
  /// Returns MT5 endpoint if account is MT5, otherwise self-hosted
  /// Uses stored primary account as fallback if provided account is null
  static String getSymbolEndpoint(MT5Account? account) {
    final accountToUse = account ?? getStoredPrimaryAccount();
    return _isMT5Account(accountToUse) ? mt5Symbol : selfHostedSymbol;
  }

  /// Get market watch endpoint based on account type
  /// Returns MT5 endpoint if account is MT5, otherwise self-hosted
  /// Uses stored primary account as fallback if provided account is null
  static String getMarketWatchEndpoint(MT5Account? account) {
    final accountToUse = account ?? getStoredPrimaryAccount();
    return _isMT5Account(accountToUse) ? mt5MarketWatch : selfHostedMarketWatch;
  }

  /// Get account endpoint based on account type
  /// Returns MT5 endpoint if account is MT5, otherwise self-hosted
  /// Uses stored primary account as fallback if provided account is null
  static String getAccountEndpoint(MT5Account? account) {
    final accountToUse = account ?? getStoredPrimaryAccount();
    return _isMT5Account(accountToUse) ? mt5Account : selfHostedAccount;
  }

  // ==================== HELPER METHODS ====================

  /// Check if account is MT5 type
  /// Returns true if account exists and tradingServer is "MT5" (case-insensitive)
  /// Returns false if account is null or not MT5
  static bool _isMT5Account(MT5Account? account) {
    if (account == null) return false;
    return account.tradingServer.toUpperCase() == "MT5";
  }

  /// Public method to check if account is MT5 type (for external use)
  /// Returns true if account exists and tradingServer is "MT5" (case-insensitive)
  /// Returns false if account is null or not MT5
  static bool isMT5Account(MT5Account? account) {
    return _isMT5Account(account);
  }

  /// Get account type as string for logging
  static String getAccountType(MT5Account? account) {
    return _isMT5Account(account) ? "MT5" : "Self-hosted";
  }

  /// Get full WebSocket URL by combining base URL with endpoint
  static String getFullUrl(String endpoint) {
    final baseUrl = ApiConstants.socketUrl;
    // ✅ FIX: Ensure endpoint starts with / and baseUrl doesn't end with /
    final cleanBaseUrl =
        baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';

    // ✅ FIX: Remove any fragments (#) or query parameters that shouldn't be in WebSocket URL
    final cleanEndpointNoFragment = cleanEndpoint.split('#')[0].split('?')[0];

    final fullUrl = '$cleanBaseUrl$cleanEndpointNoFragment';

    // ✅ FIX: Ensure URL doesn't contain any fragments
    final finalUrl = fullUrl.split('#')[0];

    if (kDebugMode) {
      print(
        'WebSocketEndpointHelper: Constructed URL: $finalUrl (base: $baseUrl, endpoint: $endpoint)',
      );
    }

    return finalUrl;
  }

  /// Get full WebSocket URL for open positions
  static String getOpenPositionsUrl(MT5Account? account) {
    return getFullUrl(getOpenPositionsEndpoint(account));
  }

  /// Get full WebSocket URL for pending orders
  static String getPendingOrdersUrl(MT5Account? account) {
    return getFullUrl(getPendingOrdersEndpoint(account));
  }

  /// Get full WebSocket URL for symbol
  static String getSymbolUrl(MT5Account? account) {
    return getFullUrl(getSymbolEndpoint(account));
  }

  /// Get full WebSocket URL for market watch
  static String getMarketWatchUrl(MT5Account? account) {
    return getFullUrl(getMarketWatchEndpoint(account));
  }

  /// Get full WebSocket URL for account
  static String getAccountUrl(MT5Account? account) {
    return getFullUrl(getAccountEndpoint(account));
  }

  // ==================== ACCOUNT FETCHING METHODS ====================

  /// Fetch MT5 accounts from API and return primary account
  static Future<MT5Account?> fetchPrimaryAccount() async {
    try {
      // Check cache first
      if (_cachedPrimaryAccount != null &&
          _cacheTimestamp != null &&
          DateTime.now().difference(_cacheTimestamp!) < _cacheValidity) {
        if (kDebugMode) {
          print('WebSocketEndpointHelper: Using cached primary account');
        }
        return _cachedPrimaryAccount;
      }

      final token = await SecureStorageService.getAuthToken();
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          print('WebSocketEndpointHelper: No auth token available');
        }
        return null;
      }

      if (kDebugMode) {
        print(
          'WebSocketEndpointHelper: Fetching accounts from API: ${ApiConstants.getMT5Accounts}',
        );
      }

      final response = await ApiService.get(
        endpoint: ApiConstants.getMT5Accounts,
        token: token,
      );

      if (response.success && response.data['status'] == true) {
        final accountsData = response.data['data'] as List?;
        if (accountsData != null && accountsData.isNotEmpty) {
          final accounts =
              accountsData
                  .map((account) => MT5Account.fromJson(account))
                  .toList();

          // Find primary account
          MT5Account? primaryAccount;
          try {
            primaryAccount = accounts.firstWhere(
              (account) => account.isPrimaryAccount,
            );
          } catch (e) {
            // No primary account found, use first account
            primaryAccount = accounts.first;
          }

          _cachedPrimaryAccount = primaryAccount;
          _cacheTimestamp = DateTime.now();

          if (kDebugMode) {
            print(
              'WebSocketEndpointHelper: Fetched primary account: ${primaryAccount.metaAccountNumber} (${primaryAccount.tradingServer})',
            );
          }

          return primaryAccount;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('WebSocketEndpointHelper: Error fetching accounts: $e');
      }
    }
    return null;
  }

  /// Get primary account, fetching from API if not provided
  static Future<MT5Account?> getPrimaryAccount(
    MT5Account? providedAccount,
  ) async {
    if (providedAccount != null) return providedAccount;
    return await fetchPrimaryAccount();
  }

  /// Clear cached account (call when account switches)
  static void clearCache() {
    _cachedPrimaryAccount = null;
    _cacheTimestamp = null;
    _initializedPrimaryAccount = null;
    if (kDebugMode) {
      print('WebSocketEndpointHelper: Cache cleared');
    }
  }
}
