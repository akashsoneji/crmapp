import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/api_const.dart';
import 'package:pipze/models/socket_response.dart';
import 'package:pipze/services/secure_storage_service.dart';
import 'package:pipze/services/api_service.dart';
import 'package:pipze/services/favorites_storage_service.dart';
import 'package:pipze/controllers/account_controller.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class InstrumentsController extends GetxController with WidgetsBindingObserver {
  final RxList<ListElement> allInstruments = <ListElement>[].obs;
  final RxList<ListElement> instruments = <ListElement>[].obs;
  final RxString currentFilter = 'All'.obs; // Changed default to 'All'
  final RxString currentSort = 'Default'.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;
  final RxMap<String, List<ListElement>> tradingGroups =
      <String, List<ListElement>>{}.obs;

  // Dynamic filters based on WebSocket categories
  final RxList<String> availableFilters = <String>['All', 'Favorites'].obs;

  // Favorites management
  final RxList<String> favoriteInstruments = <String>[].obs;
  final RxBool isLoadingFavorites = false.obs;

  // Put your WebSocket URL here
  late WebSocketChannel channel;

  // Connection management
  final RxBool isConnected = false.obs;
  final RxBool isReconnecting = false.obs;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  @override
  void onInit() {
    super.onInit();
    // Add lifecycle observer to handle app state changes
    WidgetsBinding.instance.addObserver(this);

    // Load favorites from storage
    _loadFavorites();

    // Force reinitialize with new defaults if needed (for existing users)
    _checkAndUpdateDefaults();

    // DON'T initialize WebSocket automatically - let screen decide when to start
    // _initializeWebSocket();
  }

  // Method to start WebSocket when screen becomes visible
  void startWebSocket() {
    print('🔌 InstrumentsController: Starting WebSocket');
    if (!isConnected.value) {
      print('Websocket started');
      _initializeWebSocket();
    }
  }

  // Method to stop WebSocket when screen is hidden
  void stopWebSocket() {
    print('🔌 InstrumentsController: Stopping WebSocket');
    _disconnectWebSocket();
  }

  // Check if we need to update defaults (for existing users)
  Future<void> _checkAndUpdateDefaults() async {
    try {
      final currentFavorites =
          await FavoritesStorageService.instance.getFavoriteInstruments();
      // If user has old defaults (USOIL, NAS100, BTCUSD), update to new ones
      if (currentFavorites.contains('USIOL.c') ||
          currentFavorites.contains('NAS100.c') ||
          currentFavorites.contains('BTCUSD.c')) {
        print('🔄 Detected old default favorites, updating to new ones');
        await forceReinitializeDefaults();
      }
    } catch (e) {
      print('Error checking and updating defaults: $e');
    }
  }

  void _initializeWebSocket() {
    try {
      channel = WebSocketChannel.connect(Uri.parse('${ApiConstants.socketUrl}/ws/marketwatch'));
      isConnected.value = true;
      _reconnectAttempts = 0;
      print("URL============'${ApiConstants.socketUrl}/ws/marketwatch'");
      // Listen for data from socket server
      channel.stream.listen(
        (message) {
          print("RESPONE++++++++++${message}");
          updateFromJson(message);
        },
        onError: (error) {
          print('WebSocket error: $error');
          isConnected.value = false;
          _scheduleReconnect();
        },
        onDone: () {
          print('WebSocket connection closed');
          isConnected.value = false;
          _scheduleReconnect();
        },
      );

      getSocketdata();
    } catch (e) {
      print('Failed to initialize WebSocket: $e');
      isConnected.value = false;
      _scheduleReconnect();
    }
  }

  void getSocketdata() async {
    final authid = await SecureStorageService.getAuthToken();
    print(
      "Instruments: WebSocket token: ${authid != null ? 'exists' : 'null'}",
    );

    if (authid == null || authid.isEmpty) {
      print(
        'Instruments: WebSocket token is null or empty, retrying in 500ms...',
      );
      // Retry after a shorter delay to allow token to be saved
      Timer(const Duration(milliseconds: 500), () {
        if (isConnected.value) {
          getSocketdata();
        }
      });
      return;
    }

    // Get the active MT5 account number from account controller
    final accountController = Get.find<AccountController>();
    final activeAccount = accountController.activeMT5Account;
    final accountNumber = activeAccount?.metaAccountNumber ?? "";

    String mt5GroupName = activeAccount?.mt5GroupName ?? "";
    if (mt5GroupName.isEmpty) {
      // Fallback: fetch first plan group when no account exists
      try {
        final resp = await ApiService.post(
          endpoint: ApiConstants.realPlanDetails,
          data: {"group_id": 0},
        );
        if (resp.success && resp.data is Map && resp.data['data'] is List) {
          final List list = resp.data['data'] as List;
          if (list.isNotEmpty) {
            final first = list.first as Map<String, dynamic>;
            mt5GroupName =
                (first['mt5_group_name'] ?? first['group_name'])?.toString() ??
                "";
          }
        }
      } catch (e) {
        // ignore and proceed
      }
    }

    print("Instruments: Using MT5 Account Number: $accountNumber");

    sendEvent({"authID": authid, "trading_account": accountNumber,});
  }

  void updateFromJson(String jsonStr) {
    try {
      final dynamic decodedData = jsonDecode(jsonStr);

      // ✅ Handle both: Array of arrays & Single array updates
      if (decodedData is List && decodedData.isNotEmpty) {
        if (decodedData[0] is List) {
          _parseNewFormat(decodedData);
        } else if (decodedData[0] is String) {
          _parseSingleInstrument(decodedData);
        }
        return;
      }

      // ✅ Old JSON Format
      final SocketResponse socketResponse = SocketResponse.fromJson(
        decodedData as Map<String, dynamic>,
      );

      final List<ListElement> allItems = [];
      final Map<String, List<ListElement>> map = {};
      final Set<String> uniqueCategories = {};

      for (final group in socketResponse.groups) {
        var groupName = group.groupName;

        if (groupName.toLowerCase() == 'fx cross' ||
            groupName.toLowerCase() == 'fxcross') {
          groupName = 'Forex';
        }
        if (groupName.toLowerCase() == 'currency') {
          groupName = 'Forex';
        }

        if (!map.containsKey(groupName)) {
          map[groupName] = [];
        }
        map[groupName]!.addAll(group.list);

        if (groupName.isNotEmpty) {
          uniqueCategories.add(groupName);
        }
      }

      tradingGroups.value = map;

      for (final group in socketResponse.groups) {
        allItems.addAll(group.list);
      }

      _updateInstrumentsList(allItems);
      instruments.assignAll(allInstruments);

    } catch (e, t) {
      print('Error parsing JSON: $e\n $t');
    }
  }

  void _parseNewFormat(List decodedData) {
    final List<ListElement> incomingItems = [];

    for (final item in decodedData) {
      final parsed = _parseInstrumentItem(item);
      if (parsed != null) incomingItems.add(parsed);
    }

    // ✅ Merge & update (no duplicates)
    for (final newItem in incomingItems) {
      final index = allInstruments.indexWhere((e) => e.symbol == newItem.symbol);
      if (index != -1) {
        // Update values
        final existing = allInstruments[index];
        allInstruments[index] = existing.copyWith(
          bid: newItem.bid,
          ask: newItem.ask,
          spreadDiff: newItem.spreadDiff,
          digits: newItem.digits,
          last: newItem.last,
          volume: newItem.volume,
          volumeReal: newItem.volumeReal,
          category: newItem.category,
        );
      } else {
        // Add new unique symbol
        allInstruments.add(newItem);
      }
    }

    // ✅ Show all instruments without filtering during streaming updates
    instruments.assignAll(allInstruments);
  }

  void _parseSingleInstrument(List item) {
    final newItem = _parseInstrumentItem(item);
    if (newItem != null) {
      // Check if this symbol already exists
      final existingIndex = allInstruments.indexWhere(
        (element) => element.symbol == newItem.symbol,
      );

      if (existingIndex != -1) {
        // ✅ Update existing instrument instead of removing/re-adding
        final existing = allInstruments[existingIndex];
        allInstruments[existingIndex] = existing.copyWith(
          bid: newItem.bid,
          ask: newItem.ask,
          spreadDiff: newItem.spreadDiff,
          digits: newItem.digits,
          last: newItem.last,
          volume: newItem.volume,
          volumeReal: newItem.volumeReal,
          category: newItem.category,
        );
      } else {
        // ✅ Add brand new instrument
        allInstruments.add(newItem);
      }

      // ✅ Show all instruments without filtering during streaming updates
      instruments.assignAll(allInstruments);
    }
  }

  ListElement? _parseInstrumentItem(List item) {
    try {
      final symbol = item[0].toString();
      final bid = double.tryParse(item[1].toString()) ?? 0.0;
      final ask = double.tryParse(item[2].toString()) ?? 0.0;
      final spreadDiff = int.tryParse(item[3].toString()) ?? 0;
      final digits = int.tryParse(item[4].toString()) ?? 0;
      final category = item.length >= 6 ? item[5].toString() : null;

      return ListElement(
        symbol: symbol,
        bid: bid,
        ask: ask,
        spreadDiff: spreadDiff.toDouble(),
        digits: digits,
        last: 0,
        volume: 0,
        volumeReal: 0,
        logo: '',
        category: category,
      );
    } catch (e) {
      print("❌ Failed parsing $item — $e");
      return null;
    }
  }

  void _updateTradingGroups(List<ListElement> allItems) {
    final Map<String, List<ListElement>> map = {};
    final Set<String> uniqueCategories = {};

    for (final instrument in allItems) {
      var groupName =
          instrument.category ?? _inferGroupName(instrument.symbol);

      if (groupName.toLowerCase() == 'fx cross' ||
          groupName.toLowerCase() == 'fxcross') {
        groupName = 'Forex';
      }
      if (groupName.toLowerCase() == 'currency') {
        groupName = 'Forex';
      }

      if (!map.containsKey(groupName)) {
        map[groupName] = [];
      }
      map[groupName]!.add(instrument);

      if (groupName.isNotEmpty) {
        uniqueCategories.add(groupName);
      }
    }

    tradingGroups.value = map;
  }

  // Helper method to infer group name from symbol
  String _inferGroupName(String symbol) {
    final upperSymbol = symbol.toUpperCase();

    // Currency pairs
    if (_isCurrencyPair(symbol)) {
      return 'Currency';
    }

    // Metals
    if (upperSymbol.contains('XAU') || upperSymbol.contains('XAG')) {
      return 'Metals';
    }

    // Crypto
    if (upperSymbol.contains('BTC') ||
        upperSymbol.contains('ETH') ||
        upperSymbol.contains('USDT') ||
        upperSymbol.contains('DOGE')) {
      return 'Crypto';
    }

    // Indices
    if (upperSymbol.contains('NAS') ||
        upperSymbol.contains('SPX') ||
        upperSymbol.contains('DOW') ||
        upperSymbol.contains('UK100')) {
      return 'Indices';
    }

    // Commodities
    if (upperSymbol.contains('OIL') || upperSymbol.contains('USIOL')) {
      return 'Commodities';
    }

    return 'Other';
  }

  bool _isCurrencyPair(String symbol) {
    final majorPairs = ['EUR', 'GBP', 'AUD', 'NZD', 'USD', 'CAD', 'CHF', 'JPY'];
    final symbolWithoutSuffix = symbol
        .replaceAll('.c', '')
        .replaceAll('.r', '');

    int matchCount = 0;
    for (final pair in majorPairs) {
      if (symbolWithoutSuffix.contains(pair)) {
        matchCount++;
      }
    }

    // If it contains 2 major currencies, it's likely a currency pair
    return matchCount >= 2 && symbolWithoutSuffix.length <= 6;
  }

  void _updateInstrumentsList(List<ListElement> newInstruments) {
    // Create a map of existing instruments by symbol for quick lookup
    final Map<String, ListElement> existingInstrumentsMap = {};
    for (final instrument in allInstruments) {
      existingInstrumentsMap[instrument.symbol] = instrument;
    }

    // Update or add instruments - preserve order from WebSocket (newInstruments order)
    final List<ListElement> updatedInstruments = [];
    for (final newInstrument in newInstruments) {
      final existingInstrument = existingInstrumentsMap[newInstrument.symbol];
      if (existingInstrument != null) {
        // Update existing instrument with new price data
        final updatedInstrument = existingInstrument.copyWith(
          bid: newInstrument.bid,
          ask: newInstrument.ask,
          last: newInstrument.last,
          volume: newInstrument.volume,
          volumeReal: newInstrument.volumeReal,
          spreadDiff: newInstrument.spreadDiff,
          category: newInstrument.category,
        );
        updatedInstruments.add(updatedInstrument);
      } else {
        // Add new instrument (preserves WebSocket order)
        updatedInstruments.add(newInstrument);
      }
    }

    // Update the observable list (order is preserved from newInstruments)
    allInstruments.assignAll(updatedInstruments.toSet().toList());
  }

  // Send event with parameters over WebSocket
  void sendEvent(Map<String, dynamic> event) {
    final encoded = jsonEncode(event);
    channel.sink.add(encoded);
  }

  @override
  void onClose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Cancel reconnect timer
    _reconnectTimer?.cancel();

    // Close WebSocket connection when controller disposed
    try {
      channel.sink.close();
    } catch (e) {
      print('Error closing WebSocket: $e');
    }

    super.onClose();
  }

  // Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        print('App resumed - checking WebSocket connection');
        if (!isConnected.value) {
          _reconnectWebSocket();
        }
        break;
      case AppLifecycleState.paused:
        print('App paused - WebSocket may disconnect');
        break;
      case AppLifecycleState.detached:
        print('App detached - closing WebSocket');
        _disconnectWebSocket();
        break;
      case AppLifecycleState.inactive:
        print('App inactive');
        break;
      case AppLifecycleState.hidden:
        print('App hidden');
        break;
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('Max reconnection attempts reached');
      return;
    }

    if (_reconnectTimer?.isActive == true) return;

    _reconnectAttempts++;
    isReconnecting.value = true;

    print(
      'Scheduling reconnection attempt $_reconnectAttempts in ${_reconnectDelay.inSeconds} seconds',
    );

    _reconnectTimer = Timer(_reconnectDelay, () {
      _reconnectWebSocket();
    });
  }

  void _reconnectWebSocket() {
    if (isConnected.value) return;

    print('Attempting to reconnect WebSocket...');
    isReconnecting.value = true;

    try {
      _disconnectWebSocket();
      _initializeWebSocket();
    } catch (e) {
      print('Reconnection failed: $e');
      isReconnecting.value = false;
      _scheduleReconnect();
    }
  }

  void disconnectWebSocket() {
    try {
      channel.sink.close();
      isConnected.value = false;
      isReconnecting.value = false;
      print('InstrumentsController: WebSocket disconnected');
    } catch (e) {
      print('Error disconnecting WebSocket: $e');
    }
  }

  void _disconnectWebSocket() {
    disconnectWebSocket();
  }

  void loadInstruments() {
    final currencyInstruments =
        allInstruments
            .where(
              (instrument) =>
                  getGroupNameForSymbol(instrument.symbol) == 'Forex',
            )
            .toList();
    instruments.assignAll(currencyInstruments);
    currentFilter.value = 'Forex';
    searchQuery.value = '';
    isSearching.value = false;
  }

  String getGroupNameForSymbol(String symbol) {
    // First, try to find the symbol in trading groups
    for (final entry in tradingGroups.entries) {
      if (entry.value.any((element) => element.symbol == symbol)) {
        return entry.key;
      }
    }

    // If not found in groups, try to find in allInstruments and use its category
    final instrument = allInstruments.firstWhereOrNull(
      (element) => element.symbol == symbol,
    );

    if (instrument != null && instrument.category != null) {
      var category = instrument.category!;
      // Merge "Fx Cross" into "Forex"
      if (category.toLowerCase() == 'fx cross' ||
          category.toLowerCase() == 'fxcross') {
        return 'Forex';
      }
      return category;
    }

    // Fallback to inferring from symbol
    return _inferGroupName(symbol);
  }

  void searchInstruments(String query) {
    searchQuery.value = query;
    isSearching.value = query.isNotEmpty;
    _updateFilteredInstruments();
  }

  void filterInstruments(String filter) {
    currentFilter.value = filter;
    _updateFilteredInstruments();
  }

  void sortInstruments(String sortBy) {
    currentSort.value = sortBy;
    // Reapply sorting using the same helper method
    _applyCurrentSort(instruments);
    // Trigger update by reassigning
    instruments.assignAll(instruments);
  }

  // Load favorites from storage
  Future<void> _loadFavorites() async {
    try {
      isLoadingFavorites.value = true;
      final favorites =
          await FavoritesStorageService.instance.getFavoriteInstruments();
      favoriteInstruments.assignAll(favorites);
      // print('📱 Loaded ${favorites.length} favorite instruments: $favorites');
    } catch (e) {
      print('Error loading favorites: $e');
    } finally {
      isLoadingFavorites.value = false;
    }
  }

  // Toggle favorite status for an instrument
  Future<void> toggleFavorite(String instrumentSymbol) async {
    try {
      // Normalize symbol format - always store with .c suffix for consistency
      final normalizedSymbol =
          instrumentSymbol.endsWith('.c')
              ? instrumentSymbol
              : instrumentSymbol + '.c';

      final success = await FavoritesStorageService.instance.toggleFavorite(
        normalizedSymbol,
      );
      if (success) {
        // Reload favorites to update the list
        await _loadFavorites();
        // Update filtered instruments to reflect changes
        _updateFilteredInstruments();
        // print('Toggled favorite for: $normalizedSymbol');
      }
    } catch (e) {
      print('Error toggling favorite for $instrumentSymbol: $e');
    }
  }

  // Check if an instrument is favorite
  bool isFavorite(String instrumentSymbol) {
    // Check both with and without .c suffix
    final isFav =
        favoriteInstruments.contains(instrumentSymbol) ||
        favoriteInstruments.contains(instrumentSymbol + '.c') ||
        favoriteInstruments.contains(instrumentSymbol.replaceAll('.c', ''));

    // print('🔍 isFavorite check for "$instrumentSymbol": $isFav');
    // print('🔍 Current favorites: $favoriteInstruments');

    return isFav;
  }

  // Add instrument to favorites
  Future<void> addToFavorites(String instrumentSymbol) async {
    try {
      final success = await FavoritesStorageService.instance.addToFavorites(
        instrumentSymbol,
      );
      if (success) {
        await _loadFavorites();
        _updateFilteredInstruments();
        print('Added $instrumentSymbol to favorites');
      }
    } catch (e) {
      print('Error adding $instrumentSymbol to favorites: $e');
    }
  }

  // Remove instrument from favorites
  Future<void> removeFromFavorites(String instrumentSymbol) async {
    try {
      final success = await FavoritesStorageService.instance
          .removeFromFavorites(instrumentSymbol);
      if (success) {
        await _loadFavorites();
        _updateFilteredInstruments();
        print('Removed $instrumentSymbol from favorites');
      }
    } catch (e) {
      print('Error removing $instrumentSymbol from favorites: $e');
    }
  }

  // Get favorites count
  int get favoritesCount => favoriteInstruments.length;

  // Reset to default favorites (useful for testing or user preference)
  Future<void> resetToDefaultFavorites() async {
    try {
      await FavoritesStorageService.instance.resetToDefaultFavorites();
      await _loadFavorites();
      _updateFilteredInstruments();
      print('Reset to default favorites');
    } catch (e) {
      print('Error resetting to default favorites: $e');
    }
  }

  // Force reinitialize with new defaults (useful when default list changes)
  Future<void> forceReinitializeDefaults() async {
    try {
      await FavoritesStorageService.instance.forceReinitializeDefaults();
      await _loadFavorites();
      _updateFilteredInstruments();
      print('Force reinitialized with new defaults');
    } catch (e) {
      print('Error force reinitializing defaults: $e');
    }
  }

  void _updateFilteredInstruments() {
    List<ListElement> filteredInstruments = List.from(allInstruments);

    // Apply category filter
    if (currentFilter.value != 'All' && currentFilter.value != 'Favorites') {
      filteredInstruments =
          filteredInstruments
              .where(
                (instrument) =>
                    getGroupNameForSymbol(instrument.symbol) ==
                    currentFilter.value,
              )
              .toList();
    }

    // Apply favorites filter
    if (currentFilter.value == 'Favorites') {
      filteredInstruments =
          filteredInstruments
              .where((instrument) => isFavorite(instrument.symbol))
              .toList();
    }

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      filteredInstruments =
          filteredInstruments
              .where(
                (instrument) => instrument.symbol.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ),
              )
              .toList();
    }

    // Apply current sort (preserve sort when filters/search change)
    _applyCurrentSort(filteredInstruments);

    instruments.assignAll(filteredInstruments);
  }

  // Helper method to apply current sort to instruments list
  void _applyCurrentSort(List<ListElement> instrumentsToSort) {
    switch (currentSort.value) {
      case 'Default':
        // Don't sort - keep original order from WebSocket
        break;
      case 'Symbol A-Z':
        instrumentsToSort.sort((a, b) => a.symbol.compareTo(b.symbol));
        break;
      case 'Symbol Z-A':
        instrumentsToSort.sort((a, b) => b.symbol.compareTo(a.symbol));
        break;
      default:
        // Default: keep original order from WebSocket
        break;
    }
  }

  // Method to refresh socket data when account changes
  void refreshSocketData() {
    print("Refreshing socket data for new account...");

    // If not connected, try to reconnect first
    if (!isConnected.value) {
      print("Not connected, attempting to reconnect...");
      _reconnectWebSocket();
    } else {
      // If connected, just send new data
      getSocketdata();
    }
  }

  // Method to manually reconnect (can be called from UI)
  void manualReconnect() {
    print("Manual reconnection requested");
    _reconnectAttempts = 0; // Reset attempts for manual reconnect
    _reconnectWebSocket();
  }
}
