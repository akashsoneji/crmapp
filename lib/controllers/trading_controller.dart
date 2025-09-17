import 'package:get/get.dart';
import 'package:pipze/models/websocket_trading_response.dart';
import 'package:pipze/services/api_service.dart';
import 'package:pipze/constants/api_const.dart';
import 'package:pipze/widgets/custom_toast.dart';

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
  });
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

  @override
  void onInit() {
    super.onInit();
    _initializeSampleData();
  }

  // WebSocket data handling
  void updateWebSocketData(WebSocketTradingResponse data) {
    _websocketData.value = data;

    // Update account info
    if (data.openPositions.accountinfo.isNotEmpty) {
      _accountInfo.value = data.openPositions.accountinfo.first;
    }

    // Update market positions from WebSocket data
    _updateMarketPositions(data.openPositions.positions);
  }

  void _updateMarketPositions(List<TradingPosition> positions) {
    _marketPositions.value =
        positions.map((position) => position.toTradePosition()).toList();
  }

  void _initializeSampleData() {
    // Market positions
    _marketPositions.value = [
      TradePosition(
        symbol: 'EURUSD',
        flag: '🇪🇺🇺🇸',
        action: 'Sell',
        volume: 0.02,
        profitLoss: -8.56,
        entryPrice: '3425.59',
        currentPrice: '3430.23',
        accountId: '035172384',
        orderId: '1',
        openTime: '01.08.2022, 8:20',
        closeTime: '04.08.2022, 5:10',
        reason: 'Take Profit',
        orderNo: '98547235',
        commission: 0.1,
        swap: 0.1,
        takeProfit: '1.8401',
        stopLoss: '-',
      ),
      TradePosition(
        symbol: 'XAUUSD',
        flag: '🇪🇸🇺🇸',
        action: 'Buy',
        volume: 0.02,
        profitLoss: 44.18,
        entryPrice: '1.17464',
        currentPrice: '17456',
        accountId: '035172384',
        orderId: '2',
        openTime: '01.08.2022, 8:20',
        closeTime: '04.08.2022, 5:10',
        reason: 'Take Profit',
        orderNo: '98547236',
        commission: 0.1,
        swap: 0.1,
        takeProfit: '1.8401',
        stopLoss: '-',
      ),
      TradePosition(
        symbol: 'GBPUSD',
        flag: '🇬🇧🇺🇸',
        action: 'Buy',
        volume: 0.01,
        profitLoss: 12.45,
        entryPrice: '1.2850',
        currentPrice: '1.2865',
        accountId: '035172384',
        orderId: '6',
        openTime: '02.08.2022, 9:15',
        closeTime: '05.08.2022, 6:30',
        reason: 'Take Profit',
        orderNo: '98547240',
        commission: 0.1,
        swap: 0.1,
        takeProfit: '1.2870',
        stopLoss: '-',
      ),
    ];

    // Closed positions
    _closedPositions.value = [
      TradePosition(
        symbol: 'EURUSD',
        flag: '🇪🇺🇺🇸',
        action: 'Sell',
        volume: 0.02,
        profitLoss: -8.56,
        entryPrice: '3425.59',
        currentPrice: '3430.23',
        accountId: '035172384',
        orderId: '4',
        openTime: '01.08.2022, 8:20',
        closeTime: '04.08.2022, 5:10',
        reason: 'Take Profit',
        orderNo: '98547238',
        commission: 0.1,
        swap: 0.1,
        takeProfit: '1.8401',
        stopLoss: '-',
      ),
      TradePosition(
        symbol: 'XAUUSD',
        flag: '🇪🇸🇺🇸',
        action: 'Buy',
        volume: 0.02,
        profitLoss: 44.18,
        entryPrice: '1.17464',
        currentPrice: '17456',
        accountId: '035172384',
        orderId: '6',
        openTime: '01.08.2022, 8:20',
        closeTime: '04.08.2022, 5:10',
        reason: 'Take Profit',
        orderNo: '98547240',
        commission: 0.1,
        swap: 0.1,
        takeProfit: '1.8401',
        stopLoss: '-',
      ),
    ];

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

      // Call the API to close all positions
      final response = await ApiService.post(
        endpoint: ApiConstants.closePositions,
        data: {'mt5_account': accountToUse},
      );

      if (response.success) {
        // Clear all market positions
        _marketPositions.clear();
        _setSuccess('All positions closed successfully');
      } else {
        _setError(response.message ?? 'Failed to close all positions');
      }
    } catch (e) {
      _setError('Failed to close all positions: $e');
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
      _marketPositions.removeWhere((p) => p.profitLoss > 0);

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
      _marketPositions.removeWhere((p) => p.profitLoss < 0);

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
      _marketPositions.removeWhere((p) => p.action == 'Buy');

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
      _marketPositions.removeWhere((p) => p.action == 'Sell');

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
    _marketPositions.removeWhere((p) => p.orderId == orderId);
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
      _marketPositions.removeWhere((p) => p.orderId == positionId.toString());

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
}
