import 'package:pipze/constants/api_const.dart';
import 'package:pipze/models/mt5_account.dart';

/// Centralized WebSocket endpoint management
/// Provides consistent endpoint selection based on account type (MT5 vs Self-hosted)
class WebSocketEndpointHelper {
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
  static String getOpenPositionsEndpoint(MT5Account? account) {
    return _isMT5Account(account) ? mt5OpenPositions : selfHostedOpenPositions;
  }

  /// Get pending orders endpoint based on account type
  /// Returns MT5 endpoint if account is MT5, otherwise self-hosted
  static String getPendingOrdersEndpoint(MT5Account? account) {
    return _isMT5Account(account) ? mt5PendingOrders : selfHostedPendingOrders;
  }

  /// Get symbol endpoint based on account type
  /// Returns MT5 endpoint if account is MT5, otherwise self-hosted
  static String getSymbolEndpoint(MT5Account? account) {
    return _isMT5Account(account) ? mt5Symbol : selfHostedSymbol;
  }

  /// Get market watch endpoint based on account type
  /// Returns MT5 endpoint if account is MT5, otherwise self-hosted
  static String getMarketWatchEndpoint(MT5Account? account) {
    return _isMT5Account(account) ? mt5MarketWatch : selfHostedMarketWatch;
  }

  /// Get account endpoint based on account type
  /// Returns MT5 endpoint if account is MT5, otherwise self-hosted
  static String getAccountEndpoint(MT5Account? account) {
    return _isMT5Account(account) ? mt5Account : selfHostedAccount;
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
    return '${ApiConstants.socketUrl}$endpoint';
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
}
