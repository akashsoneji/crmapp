import 'package:get/get.dart';
import 'package:pipze/models/account_models.dart';

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

  // Sample trade positions data
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

  @override
  void onInit() {
    super.onInit();
    _initializeSampleData();
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
      positions = positions.where((p) => _selectedInstruments.contains(p.symbol)).toList();
    }

    // Apply direction filter
    if (_selectedDirection.value != 'All') {
      positions = positions.where((p) => p.action == _selectedDirection.value).toList();
    }

    return positions;
  }

  // Position management
  Future<void> closePosition(String orderId) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Remove from market positions
      _marketPositions.removeWhere((p) => p.orderId == orderId);
      
      _setSuccess('Position closed successfully');
    } catch (e) {
      _setError('Failed to close position: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> closeAllPositions() async {
    try {
      _setLoading(true);
      _clearError();
      
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Clear all market positions
      _marketPositions.clear();
      
      _setSuccess('All positions closed successfully');
    } catch (e) {
      _setError('Failed to close all positions: $e');
    } finally {
      _setLoading(false);
    }
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
      Get.snackbar('Error', error, snackPosition: SnackPosition.TOP);
    }
  }

  void _setSuccess(String message) {
    _successMessage.value = message;
    if (message.isNotEmpty) {
      Get.snackbar('Success', message, snackPosition: SnackPosition.TOP);
    }
  }

  void _clearError() {
    _errorMessage.value = '';
  }

  void clearMessages() {
    _errorMessage.value = '';
    _successMessage.value = '';
  }
}
