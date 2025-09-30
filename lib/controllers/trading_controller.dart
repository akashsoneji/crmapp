import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pipze/models/websocket_trading_response.dart';
import 'package:pipze/models/trade_history_model.dart';
import 'package:pipze/services/api_service.dart';
import 'package:pipze/constants/api_const.dart';
import 'package:pipze/widgets/custom_toast.dart';
import 'account_controller.dart';

// Trade Position Model
class TradePosition {
  final String symbol;
  final String flag;
  final String action; // "Buy" or "Sell"
  final double volume;
  final double profitLoss;
  final String entryPrice;
  final String currentPrice;
  final String accountId;
  final String orderId;
  final bool isFavorite;
  final String openTime;
  final String closeTime;
  final String reason;
  final String orderNo;
  final double commission;
  final double swap;
  final String takeProfit;
  final String stopLoss;
  final String mt5Account;
  final String time;

  TradePosition({
    required this.symbol,
    required this.flag,
    required this.action,
    required this.volume,
    required this.profitLoss,
    required this.entryPrice,
    required this.currentPrice,
    required this.accountId,
    required this.orderId,
    this.isFavorite = false,
    this.openTime = '',
    this.closeTime = '',
    this.reason = '',
    this.orderNo = '',
    this.commission = 0.0,
    this.swap = 0.0,
    this.takeProfit = '',
    this.stopLoss = '',
    this.mt5Account = '',
    this.time = '',
  });

  // Getters for compatibility
  String get openPrice => entryPrice;
  Color get actionColor =>
      action.toLowerCase() == 'buy' ? Colors.green : Colors.red;
}

// History Entry Model
class HistoryEntry {
  final String type; // "Order Closed" or "Order Opened"
  final String operation; // "Manual operation"
  final double profitLoss;
  final String dateTime;
  final String device;
  final String direction;
  final String openPrice;
  final String volume;
  final bool isExpanded;

  HistoryEntry({
    required this.type,
    required this.operation,
    required this.profitLoss,
    required this.dateTime,
    this.device = '',
    this.direction = '',
    this.openPrice = '',
    this.volume = '',
    this.isExpanded = false,
  });
}

class TradingController extends GetxController {
  // Observable states
  final _selectedTab = 0.obs;
  final _selectedInstruments = <String>{}.obs;
  final _selectedDirection = 'All'.obs;
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;
  final _successMessage = ''.obs;

  // Real-time data from WebSocket
  final _websocketData = Rxn<WebSocketTradingResponse>();
  final _accountInfo = Rxn<AccountInfo>();

  // Trade positions data
  final _marketPositions = <TradePosition>[].obs;
  final _pendingPositions = <TradePosition>[].obs;
  final _closedPositions = <TradePosition>[].obs;
  final _historyEntries = <HistoryEntry>[].obs;

  // Trade history data with pagination
  final _tradeHistory = <TradeHistoryItem>[].obs;
  final _paginationInfo = Rxn<PaginationInfo>();
  final _isLoadingHistory = false.obs;

  // Getters
  int get selectedTab => _selectedTab.value;
  Set<String> get selectedInstruments => _selectedInstruments;
  String get selectedDirection => _selectedDirection.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  String get successMessage => _successMessage.value;
  List<TradePosition> get marketPositions => _marketPositions;
  List<TradePosition> get pendingPositions => _pendingPositions;
  List<TradePosition> get closedPositions => _closedPositions;
  List<HistoryEntry> get historyEntries => _historyEntries;
  WebSocketTradingResponse? get websocketData => _websocketData.value;
  AccountInfo? get accountInfo => _accountInfo.value;

  // Trade history getters
  List<TradeHistoryItem> get tradeHistory => _tradeHistory;
  PaginationInfo? get paginationInfo => _paginationInfo.value;
  bool get isLoadingHistory => _isLoadingHistory.value;

  // Calculate floating profit from market positions
  double get floatingProfit {
    return _marketPositions.fold(
      0.0,
      (sum, position) => sum + position.profitLoss,
    );
  }

  @override
  void onInit() {
    super.onInit();
    _initializeSampleData();
  }

  // WebSocket data handling
  void updateWebSocketData(WebSocketTradingResponse data) {
    _websocketData.value = data;

    // Update account info
    if (data.openPositions?.accountinfo.isNotEmpty == true) {
      _accountInfo.value = data.openPositions!.accountinfo.first;
    }

    // Update market positions from WebSocket data
    if (data.openPositions != null) {
      _updateMarketPositions(data.openPositions!.positions);
    }

    // Update pending orders from WebSocket data
    if (data.pendingOrders != null) {
      _updatePendingOrders(data.pendingOrders!.pendingOrders);
    }
  }

  void _updateMarketPositions(List<TradingPosition> positions) {
    _marketPositions.value =
        positions.map((position) => position.toTradePosition()).toList();
  }

  void _updatePendingOrders(List<PendingOrder> orders) {
    _pendingPositions.value =
        orders.map((order) => order.toTradePosition()).toList();
  }

  void _initializeSampleData() {
    // Market positions
    _marketPositions.value = [];

    // Closed positions
    _closedPositions.value = [];

    // History entries
    _historyEntries.value = [
      HistoryEntry(
        type: 'Order Closed',
        operation: 'Manual operation',
        profitLoss: 89.54,
        dateTime: '25 jan 2025 • 12:49',
        device: 'Android',
        direction: 'Sell',
        openPrice: '3,408.65',
        volume: '0.03 lots',
        isExpanded: true,
      ),
      HistoryEntry(
        type: 'Order Closed',
        operation: 'Manual operation',
        profitLoss: -8.56,
        dateTime: '25 jan 2025 • 12:49',
        device: 'Android',
        direction: 'Sell',
        openPrice: '3,408.65',
        volume: '0.03 lots',
        isExpanded: false,
      ),
    ];
  }

  // Tab management
  void setSelectedTab(int tabIndex) {
    _selectedTab.value = tabIndex;

    // Load trade history when closed positions tab is selected
    if (tabIndex == 2 && _tradeHistory.isEmpty) {
      loadTradeHistory(page: 1, refresh: true);
    }
  }

  // Instrument filtering
  void addInstrument(String instrument) {
    _selectedInstruments.add(instrument);
  }

  void removeInstrument(String instrument) {
    _selectedInstruments.remove(instrument);
  }

  void clearInstruments() {
    _selectedInstruments.clear();
  }

  // Direction filtering
  void setSelectedDirection(String direction) {
    _selectedDirection.value = direction;
  }

  // Get all available instruments
  Set<String> get availableInstruments {
    Set<String> instruments = {};
    instruments.addAll(_marketPositions.map((p) => p.symbol));
    instruments.addAll(_pendingPositions.map((p) => p.symbol));
    instruments.addAll(_closedPositions.map((p) => p.symbol));
    return instruments;
  }

  // Get filtered positions based on current tab and filters
  List<TradePosition> getFilteredPositions() {
    List<TradePosition> positions = [];

    switch (_selectedTab.value) {
      case 0: // Market
        positions = _marketPositions;
        break;
      case 1: // Pending
        positions = _pendingPositions;
        break;
      case 2: // Close
        positions = _closedPositions;
        break;
    }

    // Apply instrument filter
    if (_selectedInstruments.isNotEmpty) {
      positions =
          positions
              .where((p) => _selectedInstruments.contains(p.symbol))
              .toList();
    }

    // Apply direction filter
    if (_selectedDirection.value != 'All') {
      positions =
          positions.where((p) => p.action == _selectedDirection.value).toList();
    }

    return positions;
  }

  // Position management
  Future<void> closePosition(String orderId, {double? volume}) async {
    try {
      _setLoading(true);
      _clearError();

      // Find the position to get account info
      final position = _marketPositions.firstWhere(
        (p) => p.orderId == orderId,
        orElse: () => throw Exception('Position not found'),
      );

      // Call the API to close position
      final response = await ApiService.post(
        endpoint: ApiConstants.closePositionByPositionId,
        data: {
          'mt5_account': position.accountId,
          'position_id': int.parse(position.orderId),
          if (volume != null) 'volume': volume, // For partial close
        },
      );

      if (response.success) {
        // Remove from market positions
        _marketPositions.removeWhere((p) => p.orderId == orderId);
        _setSuccess('Position closed successfully');
      } else {
        _setError(response.message ?? 'Failed to close position');
      }
    } catch (e) {
      _setError('Failed to close position: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> closeAllPositions({String? mt5Account}) async {
    try {
      _setLoading(true);
      _clearError();

      // Use provided account or get from first position
      String accountToUse = mt5Account ?? '';
      if (accountToUse.isEmpty && _marketPositions.isNotEmpty) {
        accountToUse = _marketPositions.first.accountId;
      }

      if (accountToUse.isEmpty) {
        _setError('No MT5 account found to close positions');
        return;
      }

      print('🚀 Closing all positions for account: $accountToUse');
      print('📊 Current market positions count: ${_marketPositions.length}');

      // Use the dedicated closePositions endpoint to close all positions at once
      final response = await ApiService.post(
        endpoint: ApiConstants.closePositions,
        data: {'mt5_account': accountToUse},
      );

      if (response.success) {
        // Clear all market positions after successful API call
        _marketPositions.value = [];
        print('✅ All positions closed successfully');
        print('✅ Market positions cleared - count: ${_marketPositions.length}');

        // Force UI refresh
        _marketPositions.refresh();

        _setSuccess('All positions closed successfully');
      } else {
        _setError(response.message ?? 'Failed to close all positions');
        print('❌ Failed to close all positions: ${response.message}');
      }
    } catch (e) {
      _setError('Failed to close all positions: $e');
      print('❌ Exception closing all positions: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Close position by position ID (more direct method)
  Future<void> closePositionById({
    required String mt5Account,
    required int positionId,
    double? volume, // For partial close
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Call the API to close position
      final response = await ApiService.post(
        endpoint: ApiConstants.closePositionByPositionId,
        data: {
          'mt5_account': mt5Account,
          'position_id': positionId,
          if (volume != null) 'volume': volume, // For partial close
        },
      );

      if (response.success) {
        // Remove from market positions if it exists
        _marketPositions.removeWhere((p) => p.orderId == positionId.toString());
        _setSuccess('Position closed successfully');
      } else {
        _setError(response.message ?? 'Failed to close position');
      }
    } catch (e) {
      _setError('Failed to close position: $e');
    } finally {
      _setLoading(false);
    }
  }

  // New methods for closing different types of positions
  Future<void> closeAllProfitablePositions({String? mt5Account}) async {
    try {
      _setLoading(true);
      _clearError();

      // Use provided account or get from first position
      String accountToUse = mt5Account ?? '';
      if (accountToUse.isEmpty && _marketPositions.isNotEmpty) {
        accountToUse = _marketPositions.first.accountId;
      }

      if (accountToUse.isEmpty) {
        _setError('No MT5 account found to close positions');
        return;
      }

      // Get all profitable positions
      final profitablePositions =
          _marketPositions.where((p) => p.profitLoss > 0).toList();

      // Close each profitable position
      for (final position in profitablePositions) {
        final response = await ApiService.post(
          endpoint: ApiConstants.closePositionByPositionId,
          data: {
            'mt5_account': accountToUse,
            'position_id': int.parse(position.orderId),
          },
        );

        if (!response.success) {
          _setError(
            'Failed to close some profitable positions: ${response.message}',
          );
          return;
        }
      }

      // Remove all profitable positions from local list
      _marketPositions.value =
          _marketPositions.where((p) => p.profitLoss <= 0).toList();
      _marketPositions.refresh();

      _setSuccess('All profitable positions closed successfully');
    } catch (e) {
      _setError('Failed to close profitable positions: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> closeAllLosingPositions({String? mt5Account}) async {
    try {
      _setLoading(true);
      _clearError();

      // Use provided account or get from first position
      String accountToUse = mt5Account ?? '';
      if (accountToUse.isEmpty && _marketPositions.isNotEmpty) {
        accountToUse = _marketPositions.first.accountId;
      }

      if (accountToUse.isEmpty) {
        _setError('No MT5 account found to close positions');
        return;
      }

      // Get all losing positions
      final losingPositions =
          _marketPositions.where((p) => p.profitLoss < 0).toList();

      // Close each losing position
      for (final position in losingPositions) {
        final response = await ApiService.post(
          endpoint: ApiConstants.closePositionByPositionId,
          data: {
            'mt5_account': accountToUse,
            'position_id': int.parse(position.orderId),
          },
        );

        if (!response.success) {
          _setError(
            'Failed to close some losing positions: ${response.message}',
          );
          return;
        }
      }

      // Remove all losing positions from local list
      _marketPositions.value =
          _marketPositions.where((p) => p.profitLoss >= 0).toList();
      _marketPositions.refresh();

      _setSuccess('All losing positions closed successfully');
    } catch (e) {
      _setError('Failed to close losing positions: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> closeAllLongPositions({String? mt5Account}) async {
    try {
      _setLoading(true);
      _clearError();

      // Use provided account or get from first position
      String accountToUse = mt5Account ?? '';
      if (accountToUse.isEmpty && _marketPositions.isNotEmpty) {
        accountToUse = _marketPositions.first.accountId;
      }

      if (accountToUse.isEmpty) {
        _setError('No MT5 account found to close positions');
        return;
      }

      // Get all long positions
      final longPositions =
          _marketPositions.where((p) => p.action == 'Buy').toList();

      // Close each long position
      for (final position in longPositions) {
        final response = await ApiService.post(
          endpoint: ApiConstants.closePositionByPositionId,
          data: {
            'mt5_account': accountToUse,
            'position_id': int.parse(position.orderId),
          },
        );

        if (!response.success) {
          _setError('Failed to close some long positions: ${response.message}');
          return;
        }
      }

      // Remove all long positions from local list
      _marketPositions.value =
          _marketPositions.where((p) => p.action != 'Buy').toList();
      _marketPositions.refresh();

      _setSuccess('All long positions closed successfully');
    } catch (e) {
      _setError('Failed to close long positions: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> closeAllShortPositions({String? mt5Account}) async {
    try {
      _setLoading(true);
      _clearError();

      // Use provided account or get from first position
      String accountToUse = mt5Account ?? '';
      if (accountToUse.isEmpty && _marketPositions.isNotEmpty) {
        accountToUse = _marketPositions.first.accountId;
      }

      if (accountToUse.isEmpty) {
        _setError('No MT5 account found to close positions');
        return;
      }

      // Get all short positions
      final shortPositions =
          _marketPositions.where((p) => p.action == 'Sell').toList();

      // Close each short position
      for (final position in shortPositions) {
        final response = await ApiService.post(
          endpoint: ApiConstants.closePositionByPositionId,
          data: {
            'mt5_account': accountToUse,
            'position_id': int.parse(position.orderId),
          },
        );

        if (!response.success) {
          _setError(
            'Failed to close some short positions: ${response.message}',
          );
          return;
        }
      }

      // Remove all short positions from local list
      _marketPositions.value =
          _marketPositions.where((p) => p.action != 'Sell').toList();
      _marketPositions.refresh();

      _setSuccess('All short positions closed successfully');
    } catch (e) {
      _setError('Failed to close short positions: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods to calculate totals for different position types
  double getTotalProfitLoss() {
    return _marketPositions.fold(0.0, (sum, p) => sum + p.profitLoss);
  }

  double getTotalProfitableProfitLoss() {
    return _marketPositions
        .where((p) => p.profitLoss > 0)
        .fold(0.0, (sum, p) => sum + p.profitLoss);
  }

  double getTotalLosingProfitLoss() {
    return _marketPositions
        .where((p) => p.profitLoss < 0)
        .fold(0.0, (sum, p) => sum + p.profitLoss);
  }

  double getTotalLongProfitLoss() {
    return _marketPositions
        .where((p) => p.action == 'Buy')
        .fold(0.0, (sum, p) => sum + p.profitLoss);
  }

  double getTotalShortProfitLoss() {
    return _marketPositions
        .where((p) => p.action == 'Sell')
        .fold(0.0, (sum, p) => sum + p.profitLoss);
  }

  int getProfitablePositionsCount() {
    return _marketPositions.where((p) => p.profitLoss > 0).length;
  }

  int getLosingPositionsCount() {
    return _marketPositions.where((p) => p.profitLoss < 0).length;
  }

  int getLongPositionsCount() {
    return _marketPositions.where((p) => p.action == 'Buy').length;
  }

  int getShortPositionsCount() {
    return _marketPositions.where((p) => p.action == 'Sell').length;
  }

  // History management
  void toggleHistoryExpansion(int index) {
    if (index < _historyEntries.length) {
      final entry = _historyEntries[index];
      final updatedEntry = HistoryEntry(
        type: entry.type,
        operation: entry.operation,
        profitLoss: entry.profitLoss,
        dateTime: entry.dateTime,
        device: entry.device,
        direction: entry.direction,
        openPrice: entry.openPrice,
        volume: entry.volume,
        isExpanded: !entry.isExpanded,
      );
      _historyEntries[index] = updatedEntry;
    }
  }

  // Utility methods
  void _setLoading(bool loading) {
    _isLoading.value = loading;
  }

  void _setError(String error) {
    _errorMessage.value = error;
    if (error.isNotEmpty) {
      // Get.snackbar('Error', error, snackPosition: SnackPosition.TOP);
      CustomToastService.showError(title: 'Error', message: error);
    }
  }

  void _setSuccess(String message) {
    _successMessage.value = message;
    if (message.isNotEmpty) {
      CustomToastService.showSuccess(title: 'Success', message: message);
      // Get.snackbar('Success', message, snackPosition: SnackPosition.TOP);
    }
  }

  void _clearError() {
    _errorMessage.value = '';
  }

  void clearMessages() {
    _errorMessage.value = '';
    _successMessage.value = '';
  }

  /// Remove position from list immediately (for Dismissible widget)
  void removePositionFromList(String orderId) {
    _marketPositions.value =
        _marketPositions.where((p) => p.orderId != orderId).toList();
    _marketPositions.refresh();
  }

  /// Close position with immediate UI update (for Dismissible widget)
  Future<void> closePositionWithImmediateUpdate({
    required String mt5Account,
    required int positionId,
    double? volume,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Remove from UI immediately
      _marketPositions.value =
          _marketPositions
              .where((p) => p.orderId != positionId.toString())
              .toList();
      _marketPositions.refresh();

      // Call the API in background
      final response = await ApiService.post(
        endpoint: ApiConstants.closePositionByPositionId,
        data: {
          'mt5_account': mt5Account,
          'position_id': positionId,
          if (volume != null) 'volume': volume,
        },
      );

      if (response.success) {
        _setSuccess('Position closed successfully');
      } else {
        _setError(response.message ?? 'Failed to close position');
        // Re-add the position if API call failed
        // Note: This would require storing the position data to re-add it
      }
    } catch (e) {
      _setError('Failed to close position: $e');
      // Re-add the position if API call failed
      // Note: This would require storing the position data to re-add it
    } finally {
      _setLoading(false);
    }
  }

  /// Cancel order with immediate UI update (for pending orders)
  Future<void> cancelOrderWithImmediateUpdate({
    required String mt5Account,
    required int orderId,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Remove from UI immediately
      _pendingPositions.removeWhere((p) => p.orderId == orderId.toString());

      // Call the API in background with correct payload format
      print('🚀 Cancelling pending order:');
      print('   Endpoint: ${ApiConstants.closePendingOrder}');
      print('   MT5 Account: $mt5Account');
      print('   Order ID: $orderId');

      final response = await ApiService.post(
        endpoint: ApiConstants.closePendingOrder,
        data: {
          'mt5_account': mt5Account,
          'orderIds': [orderId], // Array of order IDs as per API spec
        },
      );

      print('📡 API Response: ${response.success} - ${response.message}');

      if (response.success) {
        _setSuccess('Order cancelled successfully');
      } else {
        _setError(response.message ?? 'Failed to cancel order');
        // Re-add the order if API call failed
        // Note: This would require storing the order data to re-add it
      }
    } catch (e) {
      _setError('Failed to cancel order: $e');
      // Re-add the order if API call failed
      // Note: This would require storing the order data to re-add it
    } finally {
      _setLoading(false);
    }
  }

  /// Close multiple pending orders at once
  Future<void> closeMultiplePendingOrders({
    required String mt5Account,
    required List<int> orderIds,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      if (orderIds.isEmpty) {
        _setError('No orders to close');
        return;
      }

      // Remove from UI immediately
      for (int orderId in orderIds) {
        _pendingPositions.removeWhere((p) => p.orderId == orderId.toString());
      }

      // Call the API with multiple order IDs
      print('🚀 Cancelling multiple pending orders:');
      print('   Endpoint: ${ApiConstants.closePendingOrder}');
      print('   MT5 Account: $mt5Account');
      print('   Order IDs: $orderIds');

      final response = await ApiService.post(
        endpoint: ApiConstants.closePendingOrder,
        data: {'mt5_account': mt5Account, 'orderIds': orderIds},
      );

      print('📡 API Response: ${response.success} - ${response.message}');

      if (response.success) {
        _setSuccess('${orderIds.length} orders cancelled successfully');
      } else {
        _setError(response.message ?? 'Failed to cancel orders');
        // Re-add the orders if API call failed
        // Note: This would require storing the order data to re-add them
      }
    } catch (e) {
      _setError('Failed to cancel orders: $e');
      // Re-add the orders if API call failed
      // Note: This would require storing the order data to re-add them
    } finally {
      _setLoading(false);
    }
  }

  /// Load trade history with pagination
  Future<void> loadTradeHistory({
    int page = 1,
    bool refresh = false,
    Map<String, String>? additionalParams,
  }) async {
    try {
      _isLoadingHistory.value = true;
      _clearError();

      // Get active MT5 account
      String mt5Account = '';
      try {
        final accountController = Get.find<AccountController>();
        final activeAccount = accountController.activeMT5Account;
        mt5Account = activeAccount?.metaAccountNumber ?? '';
      } catch (e) {
        print('TradingController: Error getting active account: $e');
      }

      print(
        '🚀 Loading trade history - Page: $page, Refresh: $refresh, Account: $mt5Account',
      );

      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        "mt5_account": mt5Account,
        "perPage": "10",
        "sort_by": "trade_position_id",
        "sort_direction": 'desc',
        "is_app": "1",
      };

      // Add additional parameters if provided
      if (additionalParams != null) {
        queryParams.addAll(additionalParams);
      }

      print('📋 Query Parameters: $queryParams');

      final response = await ApiService.get(
        endpoint: ApiConstants.tradeHistory,
        queryParameters: queryParams,
      );

      print(
        '📡 Trade History API Response: ${response.success} - ${response.message}',
      );

      if (response.success && response.data != null) {
        final tradeHistoryResponse = TradeHistoryResponse.fromJson(
          response.data!,
        );

        if (refresh || page == 1) {
          // Replace all data for refresh or first page
          _tradeHistory.value = tradeHistoryResponse.data;
        } else {
          // Append data for pagination
          _tradeHistory.addAll(tradeHistoryResponse.data);
        }

        _paginationInfo.value = tradeHistoryResponse.pagination;

        // Update closed positions for compatibility with existing UI
        _updateClosedPositionsFromHistory();

        print(
          '✅ Trade history loaded successfully - ${_tradeHistory.length} items',
        );
      } else {
        _setError(response.message ?? 'Failed to load trade history');
      }
    } catch (e) {
      _setError('Failed to load trade history: $e');
      print('❌ Trade history error: $e');
    } finally {
      _isLoadingHistory.value = false;
    }
  }

  /// Load next page of trade history
  Future<void> loadNextPage() async {
    final pagination = _paginationInfo.value;
    if (pagination != null && pagination.hasNextPage) {
      await loadTradeHistory(page: pagination.currentPage + 1);
    }
  }

  /// Load trade history with specific filters
  Future<void> loadTradeHistoryWithFilters({
    int page = 1,
    bool refresh = false,
    String? symbol,
    String? action,
    String? dateFrom,
    String? dateTo,
    String? sortBy,
    String? sortDirection,
  }) async {
    final additionalParams = <String, String>{};

    if (symbol != null && symbol.isNotEmpty) {
      additionalParams['symbol'] = symbol;
    }
    if (action != null && action.isNotEmpty) {
      additionalParams['action'] = action;
    }
    if (dateFrom != null && dateFrom.isNotEmpty) {
      additionalParams['date_from'] = dateFrom;
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      additionalParams['date_to'] = dateTo;
    }
    if (sortBy != null && sortBy.isNotEmpty) {
      additionalParams['sort_by'] = sortBy;
    }
    if (sortDirection != null && sortDirection.isNotEmpty) {
      additionalParams['sort_direction'] = sortDirection;
    }

    await loadTradeHistory(
      page: page,
      refresh: refresh,
      additionalParams: additionalParams,
    );
  }

  /// Refresh trade history (load first page)
  Future<void> refreshTradeHistory() async {
    await loadTradeHistory(page: 1, refresh: true);
  }

  /// Update closed positions from trade history for UI compatibility
  void _updateClosedPositionsFromHistory() {
    _closedPositions.value =
        _tradeHistory.map((item) {
          final positionData = item.toTradePositionMap();
          return TradePosition(
            symbol: positionData['symbol'],
            flag: positionData['flag'],
            action: positionData['action'],
            volume: positionData['volume'],
            profitLoss: positionData['profitLoss'],
            entryPrice: positionData['entryPrice'],
            currentPrice: positionData['currentPrice'],
            accountId: positionData['accountId'],
            orderId: positionData['orderId'],
            isFavorite: positionData['isFavorite'],
            openTime: positionData['openTime'],
            closeTime: positionData['closeTime'],
            reason: positionData['reason'],
            orderNo: positionData['orderNo'],
            commission: positionData['commission'],
            swap: positionData['swap'],
            takeProfit: positionData['takeProfit'],
            stopLoss: positionData['stopLoss'],
            mt5Account: positionData['mt5Account'],
            time: positionData['time'],
          );
        }).toList();
  }

  /// Check if there are more pages to load
  bool get hasMoreHistoryPages {
    final pagination = _paginationInfo.value;
    return pagination?.hasNextPage ?? false;
  }

  /// Get current page number
  int get currentHistoryPage {
    final pagination = _paginationInfo.value;
    return pagination?.currentPage ?? 1;
  }

  /// Get total pages
  int get totalHistoryPages {
    final pagination = _paginationInfo.value;
    return pagination?.lastPage ?? 1;
  }

  /// Clear all trading data (called on logout)
  void clearAllTradingData() {
    print('TradingController: Clearing all trading data...');

    // Clear all position data
    _marketPositions.value = [];
    _pendingPositions.value = [];
    _closedPositions.value = [];
    _historyEntries.value = [];
    _tradeHistory.value = [];

    // Clear WebSocket data
    _websocketData.value = null;
    _accountInfo.value = null;
    _paginationInfo.value = null;

    // Clear filters and selections
    _selectedInstruments.clear();
    _selectedDirection.value = 'All';
    _selectedTab.value = 0;

    // Clear messages
    _errorMessage.value = '';
    _successMessage.value = '';
    _isLoading.value = false;
    _isLoadingHistory.value = false;

    // Force UI refresh
    _marketPositions.refresh();
    _pendingPositions.refresh();
    _closedPositions.refresh();
    _historyEntries.refresh();
    _tradeHistory.refresh();

    print('TradingController: All trading data cleared successfully');
  }

  /// Reset to initial state (called on login)
  void resetToInitialState() {
    print('TradingController: Resetting to initial state...');
    clearAllTradingData();
    _initializeSampleData();
    print('TradingController: Reset to initial state completed');
  }
}
