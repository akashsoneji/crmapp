import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pipze/models/websocket_trading_response.dart';
import 'package:pipze/models/trade_history_model.dart';
import 'package:pipze/models/order_types.dart';
import 'package:pipze/services/api_service.dart';
import 'package:pipze/constants/api_const.dart';
import 'package:pipze/widgets/custom_toast.dart';
import 'package:pipze/utils/precision_helper.dart';
import 'package:pipze/utils/app_logger.dart';
import 'account_controller.dart';
import 'package:pipze/services/trading_websocket_service.dart';
import 'package:pipze/services/audio_service.dart';

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
  final String duration;
  final int digits;

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
    this.duration = '',
    this.digits = 5,
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
  // Tab-specific direction filters (for Pending tab 1 and Closed tab 2)
  final _pendingDirection = 'All'.obs;
  final _closedDirection = 'All'.obs;
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;
  final _successMessage = ''.obs;

  // Order type and trading states
  final _selectedOrderType = OrderType.buyMarket.obs;
  final _currentSymbol = ''.obs;
  final _currentBidPrice = 0.0.obs;
  final _currentAskPrice = 0.0.obs;
  final _pipGapValue = 0.0001.obs; // Default pip gap value
  final _pipSLTPValue = 0.0001.obs; // Default pip SL/TP value

  // Real-time data from WebSocket
  final _websocketData = Rxn<WebSocketTradingResponse>();
  final _accountInfo = Rxn<AccountInfo>();

  // Trade positions data
  final _marketPositions = <TradePosition>[].obs;
  final _pendingPositions = <TradePosition>[].obs;
  final _closedPositions = <TradePosition>[].obs;
  final _historyEntries = <HistoryEntry>[].obs;

  // Flag to prevent flickering during account switch
  bool _isAccountSwitching = false;

  // Track orders being cancelled to prevent duplicate API calls
  final _cancellingOrderIds = <int>{};

  /// Check if an order is currently being cancelled
  bool isOrderBeingCancelled(int orderId) {
    return _cancellingOrderIds.contains(orderId);
  }

  /// Check if an order exists in pending positions
  bool hasPendingOrder(int orderId) {
    return _pendingPositions.any((p) => p.orderId == orderId.toString());
  }

  // Public methods to manage account switching state
  void setAccountSwitching(bool value) {
    _isAccountSwitching = value;
  }

  bool get isAccountSwitching => _isAccountSwitching;

  // Trade history data with pagination
  final _tradeHistory = <TradeHistoryItem>[].obs;
  final _paginationInfo = Rxn<PaginationInfo>();
  final _tradeHistoryTotals = Rxn<TradeHistoryTotals>();
  final _isLoadingHistory = false.obs;
  final _hasDateFilter = false.obs; // Track if date filter is active
  // Store all current filter parameters for pagination (includes timestamps, symbol, action, etc.)
  Map<String, String>? _currentFilterParams;

  // Getters
  int get selectedTab => _selectedTab.value;
  Set<String> get selectedInstruments => _selectedInstruments;
  String get selectedDirection => _selectedDirection.value;
  String get pendingDirection => _pendingDirection.value;
  String get closedDirection => _closedDirection.value;
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
  TradeHistoryTotals? get tradeHistoryTotals => _tradeHistoryTotals.value;
  bool get isLoadingHistory => _isLoadingHistory.value;

  /// Get unique symbols from trade history
  Set<String> get availableHistorySymbols {
    final symbols = <String>{};
    for (final item in _tradeHistory) {
      // Get base symbol (remove .c suffix if present)
      final baseSymbol = item.tradeSymbol.replaceAll(RegExp(r'\..+$'), '');
      symbols.add(baseSymbol);
    }
    return symbols;
  }

  // Order type getters
  OrderType get selectedOrderType => _selectedOrderType.value;
  Rx<OrderType> get selectedOrderTypeObs => _selectedOrderType;
  String get currentSymbol => _currentSymbol.value;
  double get currentBidPrice => _currentBidPrice.value;
  double get currentAskPrice => _currentAskPrice.value;
  double get pipGapValue => _pipGapValue.value;
  double get pipSLTPValue => _pipSLTPValue.value;

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

  // ✅ FIX: WebSocket data handling - instant real-time updates with no delays
  // Process all updates immediately to match website behavior (millisecond updates)
  void updateWebSocketData(WebSocketTradingResponse data) {
    _websocketData.value = data;

    // Update account info immediately for smoothness
    if (data.openPositions != null &&
        data.openPositions!.accountinfo.isNotEmpty) {
      // Only update if values actually changed to prevent unnecessary rebuilds
      final newAccountInfo = data.openPositions!.accountinfo.first;
      if (_accountInfo.value == null ||
          _accountInfo.value!.balance != newAccountInfo.balance ||
          _accountInfo.value!.equity != newAccountInfo.equity ||
          _accountInfo.value!.margin != newAccountInfo.margin) {
        _accountInfo.value = newAccountInfo;
      }
    }

    // ✅ FIX: Update market positions immediately - no delays for real-time trading
    if (data.openPositions != null) {
      _updateMarketPositions(data.openPositions!.positions);
    }

    // Update pending orders from WebSocket data
    if (data.pendingOrders != null) {
      _updatePendingOrders(data.pendingOrders!.pendingOrders);
    }
  }

  // Update account info from Account WebSocket service
  void updateAccountInfoFromWebSocket(AccountInfo accountInfo) {
    // Validate account number matches current active account
    try {
      final accountController = Get.find<AccountController>();
      final activeAccount = accountController.activeMT5Account;

      if (activeAccount != null) {
        final activeAccountNumber = activeAccount.metaAccountNumber;
        final accountInfoLogin = accountInfo.login.toString();

        // ✅ FIX: Normalize account numbers for comparison (remove leading zeros, handle string/int)
        final normalizedActive = activeAccountNumber.trim();
        final normalizedReceived = accountInfoLogin.trim();

        // Also try comparing as integers if string comparison fails
        final activeAsInt = int.tryParse(normalizedActive);
        final receivedAsInt = int.tryParse(normalizedReceived);

        final accountMatches =
            normalizedActive == normalizedReceived ||
            (activeAsInt != null &&
                receivedAsInt != null &&
                activeAsInt == receivedAsInt);

        // Only update if account number matches current active account
        if (!accountMatches) {
          return; // Don't update with data from wrong account
        }
      }
    } catch (e) {
      // If AccountController not found, proceed with update (shouldn't happen)
    }

    // Only update if values actually changed to prevent unnecessary rebuilds
    final currentInfo = _accountInfo.value;
    final shouldUpdate =
        currentInfo == null ||
        currentInfo.balance != accountInfo.balance ||
        currentInfo.equity != accountInfo.equity ||
        currentInfo.margin != accountInfo.margin ||
        currentInfo.profit != accountInfo.profit ||
        currentInfo.marginFree != accountInfo.marginFree ||
        currentInfo.marginLevel != accountInfo.marginLevel;

    if (shouldUpdate) {
      _accountInfo.value = accountInfo;
    }
  }

  void _updateMarketPositions(List<TradingPosition> positions) {
    // ✅ FIX: Map to trade positions immediately for instant real-time updates
    // No delays, no batching - process immediately to match website behavior (millisecond updates)
    final newPositions =
        positions.map((position) => position.toTradePosition()).toList();

    // ✅ FIX: During account switch, always update (even if empty) to clear old data immediately
    // This ensures UI shows empty state first, then new data when it arrives
    if (_isAccountSwitching) {
      _marketPositions.value = newPositions;
      // Reset flag after first update (even if empty) to allow subsequent updates
      _isAccountSwitching = false;
      return;
    }

    // ✅ FIX: Always update immediately - no comparison delays for real-time trading
    // Price updates happen in milliseconds and need instant UI refresh
    // Skip any expensive comparisons that might delay updates
    _marketPositions.value = newPositions;
  }

  void _updatePendingOrders(List<PendingOrder> orders) {
    // Map to trade positions - always update even if empty to clear screen
    // Similar to how market positions work - they always update, even if empty
    // ✅ FIX: Filter out orders that are being cancelled to prevent re-adding removed orders
    final newPendingOrders =
        orders
            .where((order) => !_cancellingOrderIds.contains(order.order))
            .map((order) => order.toTradePosition())
            .toList();


    // Always update value and refresh - this ensures UI clears when websocket sends empty array
    // Matching the behavior of _updateMarketPositions which always updates
    _pendingPositions.value = newPendingOrders;
    _pendingPositions.refresh();
  }

  // Public method for WebSocket service to update pending orders separately
  void updatePendingOrders(List<PendingOrder> orders) {
    _updatePendingOrders(orders);
    // Commented out to reduce noise - fires frequently
    // if (kDebugMode) {
    //   print('Trading Controller: Updated ${orders.length} pending orders');
    // }
  }

  // Add or update a single pending order (for incremental updates from /ws/po)
  void addOrUpdatePendingOrder(PendingOrder order) {
    final orderId = order.order.toString();
    final orderIdInt = order.order;

    // ✅ FIX: Don't re-add orders that are being cancelled
    // This prevents WebSocket from re-adding orders that were just removed
    if (_cancellingOrderIds.contains(orderIdInt)) {
      return;
    }

    final existingIndex = _pendingPositions.indexWhere(
      (p) => p.orderId == orderId,
    );

    final newTradePosition = order.toTradePosition();

    if (existingIndex != -1) {
      // Update existing - replace the entire object to ensure all fields update
      _pendingPositions[existingIndex] = newTradePosition;
      // Force refresh to ensure UI updates
      _pendingPositions.refresh();
    } else {
      // Add new
      _pendingPositions.add(newTradePosition);
      _pendingPositions.refresh();
    }
  }

  // Remove a pending order by orderId (for /ws/po remove messages)
  void removePendingOrder(int orderId) {
    final orderIdString = orderId.toString();
    _pendingPositions.removeWhere((p) => p.orderId == orderIdString);

    // Force refresh to ensure UI updates immediately
    _pendingPositions.refresh();

    // Also remove from cancelling set if present (cleanup)
    _cancellingOrderIds.remove(orderId);
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
    final previousTab = _selectedTab.value;
    _selectedTab.value = tabIndex;

    // Always refresh trade history API when switching to Close tab (index 2)
    if (tabIndex == 2) {
      // If filters are active, preserve them; otherwise load without filters
      if (_currentFilterParams != null && _currentFilterParams!.isNotEmpty) {
        loadTradeHistory(
          page: 1,
          refresh: true,
          additionalParams: Map<String, String>.from(_currentFilterParams!),
        );
      } else {
        loadTradeHistory(page: 1, refresh: true);
      }
    }

    // When switching to Market tab (index 0), ensure WebSocket is ready
    if (tabIndex == 0) {
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          if (Get.isRegistered<TradingWebSocketService>()) {
            final wsService = Get.find<TradingWebSocketService>();
            // Ensure connection to open positions endpoint is ready
            wsService.ensureOpenPositionsConnection();
          }
        } catch (e) {
          // Error ensuring open positions connection
        }
      });
    }

    // When switching to Pending tab (index 1), ensure pending orders WebSocket is ready
    if (tabIndex == 1) {
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          if (Get.isRegistered<TradingWebSocketService>()) {
            final wsService = Get.find<TradingWebSocketService>();
            // Ensure connection to pending orders endpoint is ready
            wsService.ensurePendingOrdersConnection();
          }
        } catch (e) {
          // Error ensuring pending orders connection
        }
      });
    }

    // When switching to Pending tab (index 1), ensure WebSocket is ready
    if (tabIndex == 1) {
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          if (Get.isRegistered<TradingWebSocketService>()) {
            final wsService = Get.find<TradingWebSocketService>();
            // Ensure connection to pending orders endpoint is ready
            wsService.ensurePendingOrdersConnection();
          }
        } catch (e) {
          // Error ensuring pending orders connection
        }
      });
    }

    // Refresh WebSocket subscription when switching between Market and Pending tabs
    // Market tab (0) uses subscribe_all_groups, Pending tab (1) uses subscribe_pending_orders
    // Add debounce to prevent rapid tab switches from causing issues
    if (previousTab != tabIndex &&
        (tabIndex == 0 ||
            tabIndex == 1 ||
            previousTab == 0 ||
            previousTab == 1)) {
      // Debounce: wait a bit before refreshing to avoid race conditions
      Future.delayed(const Duration(milliseconds: 300), () {
        try {
          if (Get.isRegistered<TradingWebSocketService>()) {
            final wsService = Get.find<TradingWebSocketService>();
            // Only refresh if still on the same tab (user didn't switch again)
            if (_selectedTab.value == tabIndex) {
              wsService.refreshDataForCurrentTab();
            }
          }
        } catch (e) {
          // Error refreshing WebSocket on tab change
        }
      });
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

  // Tab-specific direction filtering
  void setPendingDirection(String direction) {
    _pendingDirection.value = direction;
  }

  void setClosedDirection(String direction) {
    _closedDirection.value = direction;
  }

  // Get current direction filter based on active tab
  String getCurrentDirectionFilter() {
    switch (_selectedTab.value) {
      case 1: // Pending tab
        return _pendingDirection.value;
      case 2: // Closed tab
        return _closedDirection.value;
      default: // Market tab (0) uses general direction
        return _selectedDirection.value;
    }
  }

  // Get count of filtered positions for current tab
  int getFilteredCount() {
    return getFilteredPositions().length;
  }

  // Get total count before filtering for current tab
  int getTotalCountBeforeFilter() {
    switch (_selectedTab.value) {
      case 0:
        return _marketPositions.length;
      case 1:
        return _pendingPositions.length;
      case 2:
        return _closedPositions.length;
      default:
        return 0;
    }
  }

  // Check if date filter is active
  bool get hasDateFilter => _hasDateFilter.value;

  // Set date filter state
  void setDateFilterActive(bool active) {
    _hasDateFilter.value = active;
    if (!active) {
      // Clear filter parameters when filter is deactivated
      _currentFilterParams = null;
    }
  }

  /// Clear date filter state
  void clearDateFilter() {
    _hasDateFilter.value = false;
    _currentFilterParams = null;
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

    // Apply instrument filter (match base symbols too)
    if (_selectedInstruments.isNotEmpty) {
      positions =
          positions.where((p) {
            // Check if exact symbol matches
            if (_selectedInstruments.contains(p.symbol)) {
              return true;
            }
            // Check if base symbol (without .c suffix) matches
            final baseSymbol = p.symbol.replaceFirst('.c', '');
            return _selectedInstruments.contains(baseSymbol) ||
                _selectedInstruments.any(
                  (selected) => selected.replaceFirst('.c', '') == baseSymbol,
                );
          }).toList();
    }

    // Apply direction filter (case-insensitive comparison) - tab-specific
    String directionFilter = 'All';
    switch (_selectedTab.value) {
      case 1: // Pending tab
        directionFilter = _pendingDirection.value;
        break;
      case 2: // Closed tab
        directionFilter = _closedDirection.value;
        break;
      default: // Market tab (0)
        directionFilter = _selectedDirection.value;
        break;
    }

    if (directionFilter != 'All') {
      positions =
          positions.where((p) {
            final positionAction = p.action.trim().toLowerCase();
            final selectedDirection = directionFilter.trim().toLowerCase();
            return positionAction == selectedDirection;
          }).toList();
    }

    // Sort Market and Pending tabs positions by timestamp (newest first)
    if (_selectedTab.value == 0 || _selectedTab.value == 1) {
      // Create a copy before sorting to avoid modifying the observable list
      // This prevents issues during Flutter's draw frame cycle
      positions = List<TradePosition>.from(positions);
      positions.sort((a, b) {
        // Parse openTime to timestamp for comparison
        int getTimestamp(TradePosition pos) {
          if (pos.openTime.isEmpty) return 0;
          try {
            // Try parsing as ISO8601 string (standard format from WebSocket)
            final dateTime = DateTime.tryParse(pos.openTime);
            if (dateTime != null) {
              return dateTime.millisecondsSinceEpoch ~/
                  1000; // Convert to seconds
            }
            // If not ISO8601, try parsing as Unix timestamp string/number
            final timestamp = int.tryParse(pos.openTime);
            if (timestamp != null) {
              // If timestamp is in milliseconds (13+ digits), convert to seconds
              if (timestamp > 1000000000000) {
                return timestamp ~/ 1000;
              }
              return timestamp;
            }
          } catch (e) {
            // If parsing fails, return 0 (will be sorted last)
          }
          return 0;
        }

        final timestampA = getTimestamp(a);
        final timestampB = getTimestamp(b);
        // Sort descending (newest first) - higher timestamp comes first
        return timestampB.compareTo(timestampA);
      });
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
        // Remove from market positions immediately (UI update)
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

      // Get all positions for this account
      final positionsToClose =
          _marketPositions.where((p) => p.accountId == accountToUse).toList();

      if (positionsToClose.isEmpty) {
        _setError('No positions found to close');
        return;
      }

      // Try bulk close first
      final response = await ApiService.post(
        endpoint: ApiConstants.closePositions,
        data: {'mt5_account': accountToUse},
      );

      if (response.success) {
        // Clear all market positions after successful API call
        _marketPositions.value = [];

        // Force UI refresh
        _marketPositions.refresh();

        _setSuccess('All positions closed successfully');
      } else {
        // If bulk close fails, try closing individually

        int successCount = 0;
        int failCount = 0;
        List<String> errors = [];

        // Close each position individually
        for (var position in positionsToClose) {
          try {
            final positionId = int.tryParse(position.orderId);
            if (positionId == null) {
              failCount++;
              continue;
            }

            // Call API directly to avoid loading state conflicts
            final closeResponse = await ApiService.post(
              endpoint: ApiConstants.closePositionByPositionId,
              data: {'mt5_account': accountToUse, 'position_id': positionId},
            );

            if (closeResponse.success) {
              // Remove from market positions
              _marketPositions.removeWhere(
                (p) => p.orderId == position.orderId,
              );
              successCount++;
            } else {
              failCount++;
              errors.add('Position ${position.orderId}');
            }
          } catch (e) {
            failCount++;
            errors.add('Position ${position.orderId}: $e');
          }
        }

        // Update UI
        _marketPositions.refresh();

        if (successCount > 0) {
          if (failCount == 0) {
            _setSuccess('All $successCount positions closed successfully');
          } else {
            _setError(
              'Closed $successCount positions, but $failCount failed. ${errors.join(", ")}',
            );
          }
        } else {
          _setError('Failed to close all positions. ${errors.join(", ")}');
        }
      }
    } catch (e) {
      _setError('Failed to close all positions: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Close position by position ID (more direct method)
  Future<bool> closePositionById({
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
        // No toast message - just return success
        return true;
      } else {
        _setError(response.message ?? 'Failed to close position');
        return false;
      }
    } catch (e) {
      _setError('Failed to close position: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update Take Profit and Stop Loss for a position
  Future<bool> updateTPSL({
    required String mt5Account,
    required int positionId,
    double? stopLoss,
    double? takeProfit,
    int? digits,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Validate inputs
      if (mt5Account.isEmpty) {
        _setError('MT5 account is required');
        return false;
      }
      if (positionId <= 0) {
        _setError('Invalid position ID');
        return false;
      }
      if (stopLoss == null && takeProfit == null) {
        _setError('At least one of Stop Loss or Take Profit must be provided');
        return false;
      }

      // Prepare payload
      final payload = {'mt5_account': mt5Account, 'position_id': positionId};

      // Add optional TP/SL values
      if (stopLoss != null && stopLoss > 0) {
        payload['stop_loss'] =
            digits != null
                ? PrecisionHelper.round(stopLoss, decimals: digits)
                : stopLoss;
      }
      if (takeProfit != null && takeProfit > 0) {
        payload['take_profit'] =
            digits != null
                ? PrecisionHelper.round(takeProfit, decimals: digits)
                : takeProfit;
      }

      // Call the API to update TP/SL
      final response = await ApiService.post(
        endpoint: ApiConstants.updateTPSL,
        data: payload,
      );

      if (response.success) {
        // No toast message - just return success
        return true;
      } else {
        _setError(
          response.message ?? 'Failed to update Take Profit and Stop Loss',
        );
        return false;
      }
    } catch (e) {
      _setError('Failed to update Take Profit and Stop Loss: $e');
      return false;
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
    // Check if order is already being cancelled to prevent duplicate calls
    if (_cancellingOrderIds.contains(orderId)) {
      return;
    }

    // Check if order still exists in pending list
    final orderExists = _pendingPositions.any(
      (p) => p.orderId == orderId.toString(),
    );

    if (!orderExists) {
      // Order already removed (likely by socket), treat as success
      return;
    }

    try {
      // Add to tracking set to prevent duplicate calls
      _cancellingOrderIds.add(orderId);
      _setLoading(true);
      _clearError();

      // DON'T remove from list immediately - let WebSocket update handle it
      // This prevents Dismissible widget from freezing
      // The UI will hide the item using _dismissedPositions in trade_screen.dart

      // Call the API in background with correct payload format
      final response = await ApiService.post(
        endpoint: ApiConstants.closePendingOrder,
        data: {
          'mt5_account': mt5Account,
          'orderIds': [orderId], // Array of order IDs as per API spec
        },
      );

      // Handle response
      if (response.success) {
        // Success - show message
        _setSuccess('Order cancelled successfully');

        // Remove from list immediately after successful API call
        // WebSocket will confirm the removal
        _pendingPositions.removeWhere((p) => p.orderId == orderId.toString());
        _pendingPositions.refresh(); // Force UI update
      } else {
        // Check if error is "not found" - means order was already closed
        final errorMessage = response.message?.toLowerCase() ?? '';
        if (errorMessage.contains('not found') ||
            errorMessage.contains('already closed') ||
            errorMessage.contains('does not exist')) {
          // Order already closed, remove from list
          _pendingPositions.removeWhere((p) => p.orderId == orderId.toString());
          _pendingPositions.refresh(); // Force UI update
        } else {
          // Real error - show it
          _setError(response.message ?? 'Failed to cancel order');
        }
      }
    } catch (e) {
      // Check if error is "not found" related
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('not found') ||
          errorString.contains('already closed') ||
          errorString.contains('does not exist')) {
        // Order already closed, remove from list
        _pendingPositions.removeWhere((p) => p.orderId == orderId.toString());
        _pendingPositions.refresh(); // Force UI update
      } else {
        // Real error - show it
        _setError('Failed to cancel order: $e');
      }
    } finally {
      // Remove from tracking set after a short delay to prevent re-adding
      // This gives WebSocket time to process the removal
      Future.delayed(const Duration(seconds: 2), () {
        _cancellingOrderIds.remove(orderId);
      });
      _setLoading(false);
    }
  }

  /// Close multiple pending orders at once
  Future<void> closeMultiplePendingOrders({
    required String mt5Account,
    required List<int> orderIds,
  }) async {
    List<int> existingOrders = []; // Declare outside try block for catch access

    try {
      _setLoading(true);
      _clearError();

      if (orderIds.isEmpty) {
        _setError('No orders to close');
        return;
      }

      // Filter out orders that are already being cancelled
      final ordersToCancel =
          orderIds.where((id) => !_cancellingOrderIds.contains(id)).toList();

      if (ordersToCancel.isEmpty) {
        return;
      }

      // Filter out orders that don't exist in pending list (already closed)
      existingOrders =
          ordersToCancel.where((id) {
            return _pendingPositions.any((p) => p.orderId == id.toString());
          }).toList();

      if (existingOrders.isEmpty) {
        return;
      }

      // Add all orders to tracking set
      for (final id in existingOrders) {
        _cancellingOrderIds.add(id);
      }

      // DON'T remove from UI immediately - let API response handle it
      // This prevents issues with Dismissible widget when closing last order

      final response = await ApiService.post(
        endpoint: ApiConstants.closePendingOrder,
        data: {'mt5_account': mt5Account, 'orderIds': existingOrders},
      );

      if (response.success) {
        _setSuccess('${existingOrders.length} orders cancelled successfully');

        // Remove from list immediately after successful API call
        final orderIdSet = existingOrders.map((id) => id.toString()).toSet();
        _pendingPositions.removeWhere((p) => orderIdSet.contains(p.orderId));
        _pendingPositions.refresh(); // Force UI update
      } else {
        // Check if error is "not found" - means some orders were already closed
        final errorMessage = response.message?.toLowerCase() ?? '';
        if (errorMessage.contains('not found') ||
            errorMessage.contains('already closed') ||
            errorMessage.contains('does not exist')) {
          // Some orders already closed, remove them
          final orderIdSet = existingOrders.map((id) => id.toString()).toSet();
          _pendingPositions.removeWhere((p) => orderIdSet.contains(p.orderId));
          _pendingPositions.refresh(); // Force UI update
        } else {
          // Real error - show it
          _setError(response.message ?? 'Failed to cancel orders');
        }
      }
    } catch (e) {
      // Check if error is "not found" related
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('not found') ||
          errorString.contains('already closed') ||
          errorString.contains('does not exist')) {
        // Orders already closed, remove them if existingOrders is not empty
        if (existingOrders.isNotEmpty) {
          final orderIdSet = existingOrders.map((id) => id.toString()).toSet();
          _pendingPositions.removeWhere((p) => orderIdSet.contains(p.orderId));
          _pendingPositions.refresh(); // Force UI update
        }
      } else {
        // Real error - show it
        _setError('Failed to cancel orders: $e');
      }
    } finally {
      // Remove all orders from tracking set after a short delay
      // This gives WebSocket time to process the removals
      Future.delayed(const Duration(seconds: 2), () {
        for (final id in orderIds) {
          _cancellingOrderIds.remove(id);
        }
      });
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
        // Error getting active account
      }

      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        "trading_account": mt5Account,
        "perPage": "10",
        // "sort_by": "trade_position_id",
        "sort_by": "trade_close_time",
        "sort_direction": 'desc',
        "is_app": "1",
      };

      // Add additional parameters if provided
      if (additionalParams != null) {
        queryParams.addAll(additionalParams);
      }

      final response = await ApiService.get(
        endpoint: ApiConstants.tradeHistory,
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final tradeHistoryResponse = TradeHistoryResponse.fromJson(
          response.data!,
        );

        if (refresh || page == 1) {
          // Clear old data and replace with new data for refresh or first page
          _tradeHistory.clear();
          _tradeHistory.value = tradeHistoryResponse.data;
        } else {
          // Append data for pagination
          _tradeHistory.addAll(tradeHistoryResponse.data);
        }

        _paginationInfo.value = tradeHistoryResponse.pagination;

        // Store totals data
        _tradeHistoryTotals.value = tradeHistoryResponse.totals;

        // Update closed positions for compatibility with existing UI
        _updateClosedPositionsFromHistory();
      } else {
        _setError(response.message ?? 'Failed to load trade history');
      }
    } catch (e) {
      _setError('Failed to load trade history: $e');
    } finally {
      _isLoadingHistory.value = false;
    }
  }

  /// Load next page of trade history
  Future<void> loadNextPage() async {
    final pagination = _paginationInfo.value;
    if (pagination != null && pagination.hasNextPage) {
      final nextPage = pagination.currentPage + 1;
      print('📄 Loading next page: $nextPage (current: ${pagination.currentPage}, last: ${pagination.lastPage})');
      
      // Preserve all filter parameters if any filters are active
      if (_currentFilterParams != null && _currentFilterParams!.isNotEmpty) {
        print('🔍 Loading with filters: $_currentFilterParams');
        await loadTradeHistory(
          page: nextPage,
          refresh: false, // Important: don't clear existing data
          additionalParams: Map<String, String>.from(_currentFilterParams!),
        );
      } else {
        // No filter active, load without filter parameters
        await loadTradeHistory(
          page: nextPage,
          refresh: false, // Important: don't clear existing data
        );
      }
    } else {
      print('⚠️ Cannot load next page - hasNextPage: ${pagination?.hasNextPage}, pagination: $pagination');
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

    // Store filter parameters for pagination
    if (additionalParams.isNotEmpty) {
      _currentFilterParams = Map<String, String>.from(additionalParams);
      _hasDateFilter.value = dateFrom != null || dateTo != null;
    } else {
      _currentFilterParams = null;
      _hasDateFilter.value = false;
    }

    await loadTradeHistory(
      page: page,
      refresh: refresh,
      additionalParams: additionalParams,
    );
  }

  /// Load trade history with timestamp filters
  Future<void> loadTradeHistoryWithTimestamps({
    int page = 1,
    bool refresh = true,
    required int fromTimestamp,
    required int toTimestamp,
  }) async {
    _hasDateFilter.value = true;

    // Convert timestamps to date strings in YYYY-MM-DD format (UTC)
    final fromDate = DateTime.fromMillisecondsSinceEpoch(
      fromTimestamp * 1000,
      isUtc: true,
    );
    final toDate = DateTime.fromMillisecondsSinceEpoch(
      toTimestamp * 1000,
      isUtc: true,
    );

    // Format dates as YYYY-MM-DD
    final fromDateStr = '${fromDate.year.toString().padLeft(4, '0')}-'
        '${fromDate.month.toString().padLeft(2, '0')}-'
        '${fromDate.day.toString().padLeft(2, '0')}';
    final toDateStr = '${toDate.year.toString().padLeft(4, '0')}-'
        '${toDate.month.toString().padLeft(2, '0')}-'
        '${toDate.day.toString().padLeft(2, '0')}';

    final additionalParams = <String, String>{
      'from_date': fromDateStr,
      'to_date': toDateStr,
    };

    // Store all filter parameters for pagination
    _currentFilterParams = Map<String, String>.from(additionalParams);

    await loadTradeHistory(
      page: page,
      refresh: refresh,
      additionalParams: additionalParams,
    );
  }

  /// Refresh trade history (load first page)
  Future<void> refreshTradeHistory() async {
    // If filters are active, preserve them
    if (_currentFilterParams != null && _currentFilterParams!.isNotEmpty) {
      await loadTradeHistory(
        page: 1,
        refresh: true,
        additionalParams: Map<String, String>.from(_currentFilterParams!),
      );
    } else {
      await loadTradeHistory(page: 1, refresh: true);
    }
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
            duration: positionData['duration'] ?? '',
            digits: positionData['digits'] ?? 5,
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

    // ✅ FIX: Clear all position data immediately and force UI update
    // Use .value = [] to trigger immediate UI update, not just .clear()
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
    _pendingDirection.value = 'All';
    _closedDirection.value = 'All';
    _selectedTab.value = 0;

    // Clear messages
    _errorMessage.value = '';
    _successMessage.value = '';
    _isLoading.value = false;
    _isLoadingHistory.value = false;

    // ✅ FIX: Force immediate UI refresh to show cleared state
    _marketPositions.refresh();
    _pendingPositions.refresh();
    _closedPositions.refresh();
    _historyEntries.refresh();
    _tradeHistory.refresh();

    // Trigger full UI rebuild
    update();

  }

  /// Reset to initial state (called on login)
  void resetToInitialState() {
    clearAllTradingData();
    _initializeSampleData();
  }

  // ==================== ENHANCED TRADING METHODS ====================

  /// Set the current trading symbol and update pip values
  void setCurrentSymbol(String symbol) {
    _currentSymbol.value = symbol;
    _updatePipValues(symbol);
  }

  /// Update pip values based on symbol type
  void _updatePipValues(String symbol) {
    if (symbol.contains('JPY')) {
      _pipGapValue.value = 0.01;
      _pipSLTPValue.value = 0.01;
    } else if (symbol.contains('XAU') || symbol.contains('GOLD')) {
      _pipGapValue.value = 0.01;
      _pipSLTPValue.value = 0.01;
    } else if (symbol.contains('XAG') || symbol.contains('SILVER')) {
      _pipGapValue.value = 0.001;
      _pipSLTPValue.value = 0.001;
    } else {
      // Default for major currency pairs
      _pipGapValue.value = 0.0001;
      _pipSLTPValue.value = 0.0001;
    }
  }

  /// Update current market prices
  void updateMarketPrices(double bidPrice, double askPrice) {
    _currentBidPrice.value = bidPrice;
    _currentAskPrice.value = askPrice;

    // Log price updates (only for important symbols to avoid spam)
    if (_currentSymbol.value.isNotEmpty &&
        (_currentSymbol.value.contains('EUR') ||
            _currentSymbol.value.contains('XAU') ||
            _currentSymbol.value.contains('GBP'))) {
      LoggingUtils.logPriceUpdate(
        symbol: _currentSymbol.value,
        bidPrice: bidPrice,
        askPrice: askPrice,
      );
    }
  }

  /// Set the selected order type
  void setOrderType(OrderType orderType) {
    _selectedOrderType.value = orderType;
  }

  /// Get pip value for a given price
  double getPipValue(String price) {
    if (price.isEmpty) return 0.0;
    return double.tryParse(price) ?? 0.0;
  }

  /// Get decimal digits for price formatting
  int getDecimalDigits(String price) {
    if (price.isEmpty) return 5;
    final parts = price.split('.');
    return parts.length > 1 ? parts[1].length : 5;
  }

  /// Calculate pip gap for price validation
  /// FIXED: pipGapValue is already set correctly based on symbol type
  /// - JPY/XAU: 0.01, XAG: 0.001, Major pairs: 0.0001
  double calculatePipGap(String price) {
    return pipGapValue; // Return directly, no need to multiply by full price
  }

  /// Calculate pip gap for SL/TP validation
  /// FIXED: pipSLTPValue is already set correctly based on symbol type
  double calculateSLTPPipGap(String price) {
    return pipSLTPValue; // Return directly, no need to multiply by full price
  }

  /// Validate price for order type
  String? validateOrderPrice(String price, OrderType orderType) {
    if (price.isEmpty) {
      if (orderType.requiresPrice) {
        return "Please add price!!";
      }
      return null;
    }

    final priceValue = double.tryParse(price);
    if (priceValue == null || priceValue <= 0) {
      return "Please enter a valid price";
    }

    final currentPrice =
        orderType.isBuyOrder ? currentAskPrice : currentBidPrice;
    final pipGap = calculatePipGap(price);

    switch (orderType) {
      case OrderType.buyLimit:
        final difference = currentPrice - priceValue;
        if (difference < pipGap) {
          return "Price too close to current market price (need ${pipGap.toStringAsFixed(2)} gap, have ${difference.toStringAsFixed(2)})";
        }
        break;
      case OrderType.sellLimit:
        final difference = priceValue - currentPrice;
        if (difference < pipGap) {
          return "Price too close to current market price (need ${pipGap.toStringAsFixed(2)} gap, have ${difference.toStringAsFixed(2)})";
        }
        break;
      case OrderType.buyStop:
        final difference = priceValue - currentPrice;
        if (difference < pipGap) {
          return "Price too close to current market price (need ${pipGap.toStringAsFixed(2)} gap, have ${difference.toStringAsFixed(2)})";
        }
        break;
      case OrderType.sellStop:
        final difference = currentPrice - priceValue;
        if (difference < pipGap) {
          return "Price too close to current market price (need ${pipGap.toStringAsFixed(2)} gap, have ${difference.toStringAsFixed(2)})";
        }
        break;
      default:
        break;
    }

    return null;
  }

  /// Validate SL/TP values
  String? validateSLTP(
    String slValue,
    String tpValue,
    OrderType orderType,
    String entryPrice,
  ) {
    if (slValue.isEmpty && tpValue.isEmpty) return null;

    final entryPriceValue = double.tryParse(entryPrice) ?? 0.0;
    final slPriceValue = slValue.isNotEmpty ? double.tryParse(slValue) : null;
    final tpPriceValue = tpValue.isNotEmpty ? double.tryParse(tpValue) : null;
    final sltpGap = calculateSLTPPipGap(entryPrice);

    // Validate Take Profit
    if (tpPriceValue != null) {
      if (orderType.isBuyOrder) {
        // For buy orders, TP should be above entry price
        if (tpPriceValue <= entryPriceValue + sltpGap) {
          return "Take Profit should be above entry price";
        }
      } else {
        // For sell orders, TP should be below entry price
        if (tpPriceValue >= entryPriceValue - sltpGap) {
          return "Take Profit should be below entry price";
        }
      }
    }

    // Validate Stop Loss
    if (slPriceValue != null) {
      if (orderType.isBuyOrder) {
        // For buy orders, SL should be below entry price
        if (slPriceValue >= entryPriceValue - sltpGap) {
          return "Stop Loss should be below entry price";
        }
      } else {
        // For sell orders, SL should be above entry price
        if (slPriceValue <= entryPriceValue + sltpGap) {
          return "Stop Loss should be above entry price";
        }
      }
    }

    return null;
  }

  /// Place a trade order with enhanced validation
  Future<bool> placeTradeOrder({
    required String symbol,
    required String volume,
    required OrderType orderType,
    String? price,
    String? takeProfit,
    String? stopLoss,
    String? mt5Account,
  }) async {
    try {
      // Log order placement attempt
      LoggingUtils.logOrderPlacement(
        symbol: symbol,
        orderType: orderType.value.toString(),
        volume: volume,
        price: price,
        takeProfit: takeProfit,
        stopLoss: stopLoss,
      );

      _setLoading(true);
      _clearError();

      // Validate inputs
      if (symbol.isEmpty) {
        _setError('Symbol is required');
        return false;
      }

      if (volume.isEmpty ||
          double.tryParse(volume) == null ||
          double.parse(volume) <= 0) {
        _setError('Please add lot size!!');
        return false;
      }

      // Validate price for limit/stop orders
      final priceValidation = validateOrderPrice(price ?? '', orderType);
      if (priceValidation != null) {
        // Uncomment the next line to bypass validation for testing
        // _setError(priceValidation);
        // return false;
      }

      // Validate SL/TP
      final entryPrice =
          price ??
          (orderType.isBuyOrder
              ? currentAskPrice.toString()
              : currentBidPrice.toString());

      final sltpValidation = validateSLTP(
        stopLoss ?? '',
        takeProfit ?? '',
        orderType,
        entryPrice,
      );
      if (sltpValidation != null) {
        _setError(sltpValidation);
        return false;
      }

      // Prepare payload
      final payload = {
        'symbol': symbol,
        'volume': volume,
        'type': orderType.value,
        'mt5_account': mt5Account ?? '',
      };

      // Add optional parameters
      if (price != null && price.isNotEmpty) {
        payload['price'] = price;
      }
      if (takeProfit != null && takeProfit.isNotEmpty) {
        payload['take_profit'] = takeProfit;
      }
      if (stopLoss != null && stopLoss.isNotEmpty) {
        payload['stop_loss'] = stopLoss;
      }

      // Log the API call details
      AppLogger.api('''
API Call Details:
- Endpoint: ${ApiConstants.placeOrder}
- Full URL: ${ApiConstants.baseUrl}${ApiConstants.placeOrder}
- Payload: $payload
- Headers: Content-Type: application/json, Accept: application/json
      ''');

      // Call the API
      final response = await ApiService.post(
        endpoint: ApiConstants.placeOrder,
        data: payload,
      );

      // Log the API response
      AppLogger.api('''
API Response:
- Success: ${response.success}
- Message: ${response.message}
- Data: ${response.data}

      ''');

      // response.success is true only when:
      // 1. HTTP status code is 200
      // 2. API response has status: true
      if (response.success) {
        AppLogger.order('order is order${response.data}');
        AppLogger.order(
          'Order placed successfully - $symbol ${orderType.displayName}',
        );

        // Play success sound for both buy and sell orders when response is successful
        // Audio plays when HTTP status is 200 AND API status is true
        try {
          // Play audio - don't await to avoid blocking UI
          AudioService.playSuccessSound().catchError((audioError, stackTrace) {
            // Don't fail the order if audio fails
          });
        } catch (audioError) {
          // Don't fail the order if audio fails
        }

        _setSuccess('Order placed successfully');
        return true;
      } else {
        AppLogger.error('Failed to place order: ${response.message}');
        _setError(response.message ?? 'Failed to place order');
        return false;
      }
    } catch (e) {
      AppLogger.error('Exception placing order: $e', error: e);
      _setError('Failed to place order: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Adjust price by pip value
  String adjustPriceByPip(
    String currentPrice,
    bool isIncrease,
    OrderType orderType,
  ) {
    if (currentPrice.isEmpty) {
      final defaultPrice =
          orderType.isBuyOrder ? currentAskPrice : currentBidPrice;
      return PrecisionHelper.formatPrice(
        defaultPrice,
        decimals: getDecimalDigits(currentPrice),
      );
    }

    final priceValue = double.tryParse(currentPrice) ?? 0.0;
    final pipValue = calculatePipGap(currentPrice);
    final adjustment = isIncrease ? pipValue : -pipValue;

    // Apply order type specific logic
    double newValue = priceValue + adjustment;

    if (orderType == OrderType.buyLimit || orderType == OrderType.sellStop) {
      // For buy limit and sell stop, ensure price is not too close to market
      final marketPrice =
          orderType.isBuyOrder ? currentAskPrice : currentBidPrice;
      final minGap = calculatePipGap(currentPrice);
      if (orderType == OrderType.buyLimit) {
        newValue = newValue.clamp(0.0, marketPrice - minGap);
      } else {
        newValue = newValue.clamp(marketPrice + minGap, double.infinity);
      }
    } else if (orderType == OrderType.sellLimit ||
        orderType == OrderType.buyStop) {
      // For sell limit and buy stop, ensure price is not too close to market
      final marketPrice =
          orderType.isBuyOrder ? currentAskPrice : currentBidPrice;
      final minGap = calculatePipGap(currentPrice);
      if (orderType == OrderType.sellLimit) {
        newValue = newValue.clamp(marketPrice + minGap, double.infinity);
      } else {
        newValue = newValue.clamp(0.0, marketPrice - minGap);
      }
    }

    return PrecisionHelper.formatPrice(
      newValue,
      decimals: getDecimalDigits(currentPrice),
    );
  }

  /// Adjust SL/TP by pip value
  String adjustSLTPByPip(
    String currentValue,
    bool isIncrease,
    OrderType orderType,
    String entryPrice,
  ) {
    if (currentValue.isEmpty) {
      final entryPriceValue = double.tryParse(entryPrice) ?? 0.0;
      final pipValue = calculateSLTPPipGap(entryPrice);
      final defaultValue =
          isIncrease ? entryPriceValue + pipValue : entryPriceValue - pipValue;
      return PrecisionHelper.formatPrice(
        defaultValue,
        decimals: getDecimalDigits(entryPrice),
      );
    }

    final currentValueNum = double.tryParse(currentValue) ?? 0.0;
    final pipValue = calculateSLTPPipGap(entryPrice);
    final adjustment = isIncrease ? pipValue : -pipValue;
    final newValue = currentValueNum + adjustment;

    return PrecisionHelper.formatPrice(
      newValue,
      decimals: getDecimalDigits(entryPrice),
    );
  }

  /// Check if order type is enabled for current market conditions
  bool isOrderTypeEnabled(OrderType orderType) {
    switch (orderType) {
      case OrderType.buyMarket:
      case OrderType.sellMarket:
        return true; // Market orders are always enabled
      case OrderType.buyLimit:
      case OrderType.buyStop:
        return true; // Buy orders are enabled
      case OrderType.sellLimit:
      case OrderType.sellStop:
        return true; // Sell orders are enabled
    }
  }

  /// Get available order types for current symbol
  List<OrderType> getAvailableOrderTypes() {
    return OrderType.values.where((type) => isOrderTypeEnabled(type)).toList();
  }
}
