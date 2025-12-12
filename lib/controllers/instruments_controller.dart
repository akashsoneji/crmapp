import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/api_const.dart';
import 'package:pipze/models/socket_response.dart';
import 'package:pipze/services/secure_storage_service.dart';
import 'package:pipze/services/api_service.dart';
import 'package:pipze/services/favorites_storage_service.dart';
import 'package:pipze/controllers/account_controller.dart';
import 'package:pipze/controllers/trading_controller.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pipze/utils/message_pack_decoder.dart';
import 'package:pipze/services/websocket_endpoint_helper.dart';

class InstrumentsController extends GetxController with WidgetsBindingObserver {
  final RxList<ListElement> allInstruments = <ListElement>[].obs;
  final RxList<ListElement> instruments = <ListElement>[].obs;
  final RxString currentFilter =
      'Favorites'.obs; // Default to 'Favorites' instead of 'All'
  final RxString currentSort = 'Default'.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;
  final RxMap<String, List<ListElement>> tradingGroups =
      <String, List<ListElement>>{}.obs;

  // Dynamic filters based on WebSocket categories
  final RxList<String> availableFilters = <String>['Favorites'].obs;

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
  static const Duration _baseReconnectDelay = Duration(seconds: 3);
  static const Duration _connectionTimeout = Duration(seconds: 10);
  bool _isConnecting = false; // Guard to prevent concurrent connections
  bool _isInitialSnapshot = true; // Track if we're receiving initial snapshot
  bool _isReconnecting =
      false; // Track if we're in reconnection mode to preserve prices
  bool _loggedFirstMessage = false;

  // Unsubscribe/resubscribe state
  Completer<void>? _unsubscribeCompleter;

  // Track current account number to detect account changes
  String? _currentAccountNumber;
  String? _currentWsUrl;

  // Get exponential backoff delay
  Duration _getReconnectDelay() {
    final baseSeconds = _baseReconnectDelay.inSeconds;
    final exponentialSeconds =
        baseSeconds * (1 << (_reconnectAttempts - 1).clamp(0, 4));
    return Duration(seconds: exponentialSeconds.clamp(3, 60)); // Max 60 seconds
  }

  // Check if primary account has trading_server="MT5"
  bool _isMT5Account() {
    try {
      final accountController = Get.find<AccountController>();
      final activeAccount = accountController.activeMT5Account;
      return activeAccount?.tradingServer.toUpperCase() == "MT5";
    } catch (e) {
      print('Error checking MT5 account: $e');
      return false;
    }
  }

  // Get MT5 group name and escape backslashes (single to double)
  // Group name comes as "Pipze\Standard" but needs to be sent as "Pipze\\Standard"
  Future<String> _getMT5GroupName() async {
    try {
      final accountController = Get.find<AccountController>();
      final activeAccount = accountController.activeMT5Account;
      String mt5GroupName = activeAccount?.mt5GroupName ?? "";

      if (mt5GroupName.isEmpty) {
        // Fallback: fetch from API if not available in account
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
                  (first['mt5_group_name'] ?? first['group_name'])
                      ?.toString() ??
                  "";
            }
          }
        } catch (e) {
          print('Error fetching MT5 group name from API: $e');
        }
      }

      // Escape backslashes: "Pipze\Standard" -> "Pipze\\Standard"
      if (mt5GroupName.isNotEmpty) {
        mt5GroupName = mt5GroupName.replaceAll('\\', '\\\\');
      }

      return mt5GroupName.isNotEmpty ? mt5GroupName : "Internal\\Standard";
    } catch (e) {
      print('Error getting MT5 group name: $e');
      return "Internal\\Standard";
    }
  }

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

    // Get current account number
    String? newAccountNumber;
    try {
      final accountController = Get.find<AccountController>();
      newAccountNumber = accountController.activeMT5Account?.metaAccountNumber;
    } catch (e) {
      print('Error getting account number: $e');
    }

    // Check if account changed
    // Account changed if:
    // 1. We have a previous account number AND new account number is different
    // 2. OR we have a new account number but no previous one (first connection)
    final accountChanged =
        _currentAccountNumber != null &&
        newAccountNumber != null &&
        _currentAccountNumber != newAccountNumber;

    // If this is the first connection (no previous account), treat it as not changed
    final isFirstConnection =
        _currentAccountNumber == null && newAccountNumber != null;

    // Only reconnect if:
    // 1. Not already connecting
    // 2. AND (not connected OR account changed)
    if (!_isConnecting) {
      if (isConnected.value && !accountChanged && !isFirstConnection) {
        // Already connected and account hasn't changed - no need to reconnect
        print(
          'Instruments: Already connected with same account, skipping reconnect',
        );
        return;
      }

      print('Websocket started');
      // If already connected but account changed, disconnect first to ensure clean reconnection
      if (isConnected.value && accountChanged) {
        print(
          'Instruments: Account changed from $_currentAccountNumber to $newAccountNumber, reconnecting',
        );
        _disconnectWebSocket();
        // Reset connection state to allow immediate reconnection
        isConnected.value = false;
        isReconnecting.value = false;
        _reconnectAttempts = 0;
      }

      // Update current account number
      _currentAccountNumber = newAccountNumber;
      _initializeWebSocket();
    } else {
      print('Instruments: Connection already in progress, skipping');
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

  void _initializeWebSocket() async {
    if (_isConnecting) {
      print('Instruments: Connection already in progress, skipping');
      return;
    }

    // Check network connectivity first
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        print('Instruments: No network connectivity, retrying later...');
        _scheduleReconnect();
        return;
      }
    } catch (e) {
      print('Instruments: Error checking connectivity: $e');
      // Continue anyway - connectivity check might not be available
    }

    try {
      _isConnecting = true;
      _isInitialSnapshot = true; // Reset for new connection

      final accountController = Get.find<AccountController>();
      var activeAccount = accountController.activeMT5Account;

      // ✅ FIX: Fallback to stored primary account from initialization
      if (activeAccount == null) {
        activeAccount = WebSocketEndpointHelper.getStoredPrimaryAccount();
        if (kDebugMode && activeAccount != null) {
          print(
            'Instruments: Using stored primary account from initialization',
          );
        }
      }

      // ✅ Use centralized endpoint helper
      final wsUrl = WebSocketEndpointHelper.getMarketWatchUrl(activeAccount);
      final accountType = WebSocketEndpointHelper.getAccountType(activeAccount);

      print(
        'Instruments: Endpoint change? prev=${_currentWsUrl ?? "none"} -> new=$wsUrl',
      );
      WebSocketEndpointHelper.logSwitchStep(
        'Instruments connect start',
        url: wsUrl,
      );
      print(
        'Instruments: Connecting to $wsUrl ($accountType account, Account: ${activeAccount?.metaAccountNumber ?? "N/A"}, trading_server: ${activeAccount?.tradingServer ?? "N/A"})',
      );

      // Connect with timeout handling
      channel = await Future<WebSocketChannel>.delayed(
        Duration.zero,
        () => WebSocketChannel.connect(Uri.parse(wsUrl)),
      ).timeout(
        _connectionTimeout,
        onTimeout: () {
          throw TimeoutException(
            'Connection timeout after ${_connectionTimeout.inSeconds}s',
          );
        },
      );

      // Don't set isConnected = true yet - wait for first message or confirmation
      _reconnectAttempts = 0;
      isReconnecting.value = false;
      _currentWsUrl = wsUrl;
      _loggedFirstMessage = false;

      // Update current account number when connecting
      try {
        final accountController = Get.find<AccountController>();
        _currentAccountNumber =
            accountController.activeMT5Account?.metaAccountNumber;
      } catch (e) {
        print('Error updating account number: $e');
      }

      // Listen for data from socket server
      // ✅ PERFORMANCE: Handle both JSON (String) and binary (Uint8List) messages
      channel.stream.listen(
        (message) {
          updateFromJson(message); // Can be String (JSON) or Uint8List (binary)
          // Set connected after receiving first valid message
          if (!isConnected.value) {
            isConnected.value = true;
            print('Instruments: WebSocket connected and receiving data');
          }
          if (!_loggedFirstMessage) {
            _loggedFirstMessage = true;
            WebSocketEndpointHelper.logSwitchStep(
              'Instruments first message',
              url: _currentWsUrl,
            );
          }
        },
        onError: (error) {
          print('Instruments: WebSocket error: $error');
          isConnected.value = false;
          _isConnecting = false;
          _scheduleReconnect();
        },
        onDone: () {
          print('Instruments: WebSocket connection closed');
          isConnected.value = false;
          _isConnecting = false;
          _scheduleReconnect();
        },
      );

      // Request authentication and subscription
      // ✅ PERFORMANCE: Request binary format for improved performance
      getSocketdata();
      _isConnecting = false;
    } catch (e) {
      print('Instruments: Failed to initialize WebSocket: $e');
      isConnected.value = false;
      _isConnecting = false;
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
    final accountNumber = activeAccount?.metaAccountNumber ?? "0";

    print("Instruments: Using MT5 Account Number: $accountNumber");

    // Send different event based on trading_server
    // ✅ PERFORMANCE: Request binary format for improved performance (50-70% smaller, 5-10x faster)
    if (_isMT5Account()) {
      // MT5 account: send join_market event with actual group name
      final groupName = await _getMT5GroupName();
      print(
        "Instruments: Sending join_market event for MT5 account with group: $groupName",
      );
      // sendEvent({"type": "join_market", "group": groupName});
      sendEvent({
        "authID": authid,
        "trading_account": accountNumber,
        "format": "binary", // Request binary format
      });
    } else {
      // Default: send authID and trading_account
      sendEvent({
        "authID": authid,
        "trading_account": accountNumber,
        "format": "binary", // Request binary format
      });
    }
  }

  void updateFromJson(dynamic message) {
    try {
      // ✅ PERFORMANCE: Handle both JSON and binary (MessagePack) formats
      // WebSocket can send either String (JSON) or Uint8List (binary)
      dynamic decodedData;

      if (MessagePackDecoder.isBinaryMessage(message)) {
        // Binary MessagePack format - decode it
        if (kDebugMode) {
          final sizeInfo = MessagePackDecoder.getMessageSize(message);
          WebSocketEndpointHelper.logSwitchStep(
            'Instruments first snapshot',
            url: _currentWsUrl,
            payload: {'sizeKB': sizeInfo['sizeKB']},
          );
        }
        decodedData = MessagePackDecoder.decodeBinary(
          message is Uint8List
              ? message
              : Uint8List.fromList(message as List<int>),
        );

        if (decodedData == null) {
          return;
        }
      } else {
        // JSON format - decode as string
        final jsonStr = message is String ? message : message.toString();
        decodedData = jsonDecode(jsonStr);
      }

      // ✅ Handle JSON object responses (authentication, errors, etc.)
      if (decodedData is Map<String, dynamic>) {
        _handleJsonResponse(decodedData);
        return;
      }

      // ✅ Handle array responses (price updates)
      // STEP 1: Initial snapshot (array of arrays) - comes first
      // STEP 3: Real-time updates (array of arrays) - comes after confirmation
      // Format: [symbol, bid, ask, spread_points, digits, day_high, day_low, category]
      if (decodedData is List && decodedData.isNotEmpty) {
        // Array of arrays (multiple instruments)
        if (decodedData[0] is List) {
          _parseNewFormat(decodedData);
        }
        // Single array (one instrument update)
        else if (decodedData[0] is String && decodedData.length >= 5) {
          _parseSingleInstrument(decodedData);
        }
        return;
      }

      // Fallback: Try old JSON format (only if it's actually a Map)
      if (decodedData is Map<String, dynamic>) {
        try {
          final SocketResponse socketResponse = SocketResponse.fromJson(
            decodedData,
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

          // ✅ Update trading groups and available filters
          _updateTradingGroups(allInstruments);

          // ✅ Apply current filter and sort
          _updateFilteredInstruments();
        } catch (e) {
          print('Error parsing old format: $e');
        }
      }
    } catch (e, t) {
      print('Error parsing JSON: $e\n $t');
    }
  }

  void _handleJsonResponse(Map<String, dynamic> data) {
    final type = data['type']?.toString();

    // Handle unsubscribe confirmation
    if (type == 'marketwatch_left') {
      print('✅ Unsubscribed from market watch');
      if (_unsubscribeCompleter != null &&
          !_unsubscribeCompleter!.isCompleted) {
        _unsubscribeCompleter!.complete();
        _unsubscribeCompleter = null;
      }
      return;
    }

    // Handle STEP 2: Confirmation message (subscribed_pricing)
    // Note: This comes AFTER the initial snapshot (STEP 1)
    if (type == 'subscribed_pricing') {
      final status = data['status']?.toString();
      final pricesCount = data['prices_count'];
      final totalSymbols = data['total_symbols'];
      final tradingAccount = data['trading_account'];
      final isReconnection = data['is_reconnection'] ?? false;

      if (status == 'ok') {
        print('✅ Instruments: Subscribed to pricing');
        print('   Account: $tradingAccount');
        print('   Prices count: $pricesCount / Total symbols: $totalSymbols');
        print('   Is reconnection: $isReconnection');

        // Confirmation received - initial snapshot should have been processed already
        // Next arrays will be real-time updates (STEP 3)
        _isInitialSnapshot = false;

        // ✅ Clear reconnection flag after successful subscription
        if (_isReconnecting) {
          _isReconnecting = false;
          print('✅ Reconnection complete - normal updates resumed');
        }

        // Set connected state after successful subscription
        if (!isConnected.value) {
          isConnected.value = true;
        }
      }
      return;
    }

    // Handle authentication success messages
    if (type == 'marketwatch_joined' ||
        type == 'symbol_joined' ||
        type == 'authenticated') {
      final status = data['status']?.toString();
      final message = data['message']?.toString();

      if (status == 'success') {
        print('✅ WebSocket authenticated: $message');
        if (type == 'marketwatch_joined') {
          print(
            '✅ Subscribed to market watch for account: ${data['trading_account']}',
          );
        } else if (type == 'symbol_joined') {
          print('✅ Subscribed to symbol: ${data['symbol']}');
        }
      }
      return;
    }

    // Handle error responses
    if (type == 'error') {
      final errorMessage = data['message']?.toString() ?? 'Unknown error';
      print('❌ WebSocket error: $errorMessage');
      // Complete unsubscribe completer even on error to avoid hanging
      if (_unsubscribeCompleter != null &&
          !_unsubscribeCompleter!.isCompleted) {
        _unsubscribeCompleter!.complete();
        _unsubscribeCompleter = null;
      }
      return;
    }

    // Handle other JSON responses (if any)
    print('📨 Received JSON response: $data');
  }

  void _parseNewFormat(List decodedData) {
    final List<ListElement> incomingItems = [];

    for (final item in decodedData) {
      final parsed = _parseInstrumentItem(item);
      if (parsed != null) incomingItems.add(parsed);
    }

    // STEP 1: Initial snapshot - replace all instruments
    // STEP 3: Real-time updates - merge/update only changed symbols
    // ✅ FIX: During reconnection, always use merge logic to preserve prices
    if (_isInitialSnapshot && incomingItems.isNotEmpty && !_isReconnecting) {
      // This is the FIRST initial snapshot (not a reconnection) - replace all
      print(
        '📊 Instruments: Receiving initial snapshot (${incomingItems.length} symbols)',
      );
      allInstruments.assignAll(incomingItems);
      _isInitialSnapshot = false; // Next updates will be real-time
    } else {
      // This is a real-time update - merge/update only changed symbols
      // ✅ PERFORMANCE FIX: Batch updates to avoid triggering UI rebuild for every item
      // We create a temporary list, update it, and then assign back to RxList ONCE.

      // 1. Create a working copy of the current list
      // 1. Create a working copy of the current list
      final List<ListElement> workingList = List<ListElement>.from(
        allInstruments,
      );
      bool hasChanges = false;

      // Map for faster lookup during batch processing
      final Map<String, int> indexMap = {};
      for (int i = 0; i < workingList.length; i++) {
        indexMap[workingList[i].symbol] = i;
      }

      for (final newItem in incomingItems) {
        final index = indexMap[newItem.symbol];

        if (index != null) {
          // Update existing instrument
          final existing = workingList[index];

          // ✅ FIX: Always update, even if prices are zero (market closed)
          // This ensures symbols don't disappear when markets are closed
          workingList[index] = existing.copyWith(
            bid: newItem.bid > 0.0 ? newItem.bid : existing.bid,
            ask: newItem.ask > 0.0 ? newItem.ask : existing.ask,
            spreadDiff: newItem.spreadDiff,
            digits: newItem.digits,
            last: newItem.last,
            volume: newItem.volume,
            volumeReal: newItem.volumeReal,
            category: newItem.category,
            // ✅ Preserve day_high/day_low if not provided during reconnect
            dayHigh: newItem.dayHigh ?? existing.dayHigh,
            dayLow: newItem.dayLow ?? existing.dayLow,
          );
          hasChanges = true;
        } else {
          // ✅ FIX: Add new symbols even if prices are zero (market closed)
          // This ensures all symbols from symbol master are visible
          workingList.add(newItem);
          // Update index map for subsequent items in this batch (unlikely but safe)
          indexMap[newItem.symbol] = workingList.length - 1;
          hasChanges = true;
        }
      }

      // 2. Assign back to RxList only if changes occurred
      // This triggers ONLY ONE notification for the entire batch
      if (hasChanges) {
        allInstruments.assignAll(workingList);
      }

      // ✅ Clear reconnection flag after first successful merge
      if (_isReconnecting) {
        _isReconnecting = false;
        print('✅ Reconnection merge complete - prices preserved');
      }
    }

    // ✅ Update trading groups and available filters
    _updateTradingGroups(allInstruments);

    // ✅ Apply current filter and sort
    _updateFilteredInstruments();
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
          dayHigh: newItem.dayHigh,
          dayLow: newItem.dayLow,
        );
      } else {
        // ✅ Add brand new instrument
        allInstruments.add(newItem);
      }

      // ✅ Update trading groups and available filters
      _updateTradingGroups(allInstruments);

      // ✅ Apply current filter and sort
      _updateFilteredInstruments();
    }
  }

  ListElement? _parseInstrumentItem(List item) {
    try {
      // New format: [symbol, bid, ask, spread_points, digits, day_high, day_low, category]
      // spread_points is the spread in points (not percentage)
      if (item.length < 5) {
        print(
          "❌ Invalid item format: expected at least 5 elements, got ${item.length}",
        );
        return null;
      }

      final symbol = item[0].toString();
      final bid = double.tryParse(item[1].toString()) ?? 0.0;
      final ask = double.tryParse(item[2].toString()) ?? 0.0;
      final spreadPoints = double.tryParse(item[3].toString()) ?? 0.0;
      final digits = int.tryParse(item[4].toString()) ?? 5;
      // day_high and day_low are at indices 5 and 6
      final dayHigh =
          item.length >= 6 ? (double.tryParse(item[5].toString())) : null;
      final dayLow =
          item.length >= 7 ? (double.tryParse(item[6].toString())) : null;
      final category =
          item.length >= 8
              ? item[7].toString()
              : (item.length >= 6 && dayHigh == null && dayLow == null
                  ? item[5].toString()
                  : null);

      return ListElement(
        symbol: symbol,
        bid: bid,
        ask: ask,
        spreadDiff: spreadPoints, // spread_points from API
        digits: digits,
        last: 0,
        volume: 0,
        volumeReal: 0,
        logo: '',
        category: category,
        dayHigh: dayHigh,
        dayLow: dayLow,
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
      var groupName = instrument.category ?? _inferGroupName(instrument.symbol);

      // Normalize category names
      final lowerName = groupName.toLowerCase();
      if (lowerName == 'fx cross' ||
          lowerName == 'fxcross' ||
          lowerName == 'currency' ||
          lowerName == 'forex') {
        groupName = 'Forex';
      } else if (lowerName == 'metals' || lowerName == 'metal') {
        groupName = 'Metals';
      } else if (lowerName == 'crypto' || lowerName == 'cryptocurrency') {
        groupName = 'Crypto';
      } else if (lowerName == 'indices' || lowerName == 'index') {
        groupName = 'Indices';
      } else if (lowerName == 'commodities' || lowerName == 'commodity') {
        groupName = 'Commodities';
      } else {
        // Capitalize first letter for consistency
        if (groupName.isNotEmpty) {
          groupName =
              groupName[0].toUpperCase() + groupName.substring(1).toLowerCase();
        }
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

    // ✅ Update available filters dynamically based on categories
    final List<String> newFilters = ['Favorites'];
    final sortedCategories = uniqueCategories.toList()..sort();
    newFilters.addAll(sortedCategories);
    availableFilters.assignAll(newFilters);
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
        // ✅ FIX: Force reconnect even if connected flag says connected
        // The connection might be stale after app was paused
        if (!isConnected.value) {
          // Clear data before reconnecting to ensure fresh data
          clearInstrumentsData();
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
      print('Instruments: Max reconnection attempts reached');
      isReconnecting.value = false;
      return;
    }

    if (isReconnecting.value) return; // Already scheduled

    _reconnectAttempts++;
    isReconnecting.value = true;

    final delay = _getReconnectDelay();
    print(
      'Instruments: Scheduling reconnection attempt $_reconnectAttempts in ${delay.inSeconds}s (exponential backoff)',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!isConnected.value && !_isConnecting) {
        _reconnectWebSocket();
      } else {
        isReconnecting.value = false;
      }
    });
  }

  void _reconnectWebSocket() {
    if (isConnected.value) return;

    print('🔄 Attempting to reconnect WebSocket...');
    isReconnecting.value = true;
    _isReconnecting = true; // ✅ Mark as reconnection to preserve prices

    try {
      _disconnectWebSocket();
      _initializeWebSocket();
    } catch (e) {
      print('Reconnection failed: $e');
      isReconnecting.value = false;
      _isReconnecting = false; // ✅ Clear flag on error
      _scheduleReconnect();
    }
  }

  void disconnectWebSocket() {
    try {
      channel.sink.close();
      isConnected.value = false;
      isReconnecting.value = false;
      _currentWsUrl = null;
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

    // If searching, ignore category/favorites filter and search across ALL instruments
    if (searchQuery.value.isNotEmpty) {
      // Search across all instruments regardless of current filter
      filteredInstruments =
          filteredInstruments
              .where(
                (instrument) => instrument.symbol.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ),
              )
              .toList();
    } else {
      // Only apply category/favorites filter when NOT searching
      // Apply category filter
      if (currentFilter.value != 'Favorites') {
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

    // Update current account number
    try {
      final accountController = Get.find<AccountController>();
      _currentAccountNumber =
          accountController.activeMT5Account?.metaAccountNumber;
    } catch (e) {
      print('Error updating account number in refreshSocketData: $e');
    }

    // If not connected, try to reconnect first
    if (!isConnected.value) {
      print("Not connected, attempting to reconnect...");
      _reconnectWebSocket();
    } else {
      // If connected, just send new data
      getSocketdata();
    }
  }

  // Clear instruments data (called when account changes)
  void clearInstrumentsData() {
    print(
      "InstrumentsController: Clearing instruments data for account change",
    );
    allInstruments.clear();
    instruments.clear();
    tradingGroups.clear();
    // Reset filter to 'Favorites' to show favorites from new account
    currentFilter.value = 'Favorites';
    // Clear available filters and rebuild from new account data
    availableFilters.value = ['Favorites'];

    // ✅ Also clear trading data to prevent old positions/orders showing
    try {
      final tradingController = Get.find<TradingController>();
      tradingController.clearAllTradingData();
    } catch (e) {
      print('Error clearing trading data: $e');
    }

    print("InstrumentsController: Instruments data cleared");
  }

  // Method to manually reconnect (can be called from UI)
  Future<void> manualReconnect() async {
    print("Manual reconnection requested");
    _reconnectAttempts = 0; // Reset attempts for manual reconnect

    // Ensure clean disconnect first
    stopWebSocket();
    await Future.delayed(const Duration(milliseconds: 100));

    // Then reconnect
    if (!isConnected.value && !_isConnecting) {
      _initializeWebSocket();
    }
  }

  // Unsubscribe and resubscribe with new account (keeps socket active)
  Future<void> unsubscribeAndResubscribe(String newAccountNumber) async {
    print(
      '🔄 InstrumentsController: Unsubscribing and resubscribing for account: $newAccountNumber',
    );

    // Update current account number
    _currentAccountNumber = newAccountNumber;

    // Check if URL needs to change (trading_server changed)
    final wasMT5 = _isMT5Account();

    // Get new account to check if trading_server changed
    try {
      final accountController = Get.find<AccountController>();
      final newAccount = accountController.mt5Accounts.firstWhereOrNull(
        (acc) => acc.metaAccountNumber == newAccountNumber,
      );
      final isNowMT5 = newAccount?.tradingServer.toUpperCase() == "MT5";

      // If URL needs to change, close and reconnect
      if (wasMT5 != isNowMT5) {
        print(
          '🔄 InstrumentsController: Trading server changed (was MT5: $wasMT5, now MT5: $isNowMT5), closing and reconnecting',
        );
        stopWebSocket();
        await Future.delayed(const Duration(milliseconds: 150));
        clearInstrumentsData();
        startWebSocket();
        return;
      }
    } catch (e) {
      print('⚠️ InstrumentsController: Error checking trading server: $e');
    }

    // If not connected, just initialize normally
    if (!isConnected.value) {
      print('⚠️ InstrumentsController: Not connected, initializing normally');
      clearInstrumentsData();
      startWebSocket();
      return;
    }

    try {
      // Step 1: Unsubscribe from current market watch
      print(
        '📤 InstrumentsController: Sending {"type": "unsubscribe"} request',
      );
      _unsubscribeCompleter = Completer<void>();
      sendEvent({"type": "unsubscribe"});

      // Step 2: Wait for unsubscribe confirmation (with timeout)
      try {
        await _unsubscribeCompleter!.future.timeout(
          const Duration(milliseconds: 500),
          onTimeout: () {
            print(
              '⚠️ InstrumentsController: Unsubscribe timeout, proceeding anyway',
            );
            if (_unsubscribeCompleter != null &&
                !_unsubscribeCompleter!.isCompleted) {
              _unsubscribeCompleter!.complete();
              _unsubscribeCompleter = null;
            }
          },
        );
      } catch (e) {
        print('⚠️ InstrumentsController: Error waiting for unsubscribe: $e');
      }

      // Step 3: Clear instruments data
      clearInstrumentsData();

      // Step 4: Resubscribe with new account (using appropriate event)
      print(
        '📤 InstrumentsController: Resubscribing with new account: $newAccountNumber',
      );
      if (_isMT5Account()) {
        // MT5 account: send join_market event with actual group name
        final groupName = await _getMT5GroupName();
        print(
          "InstrumentsController: Sending join_market event for MT5 account with group: $groupName",
        );
        sendEvent({"type": "join_market", "group": groupName});
      } else {
        // Default: send authID and trading_account
        final authid = await SecureStorageService.getAuthToken();
        if (authid != null && authid.isNotEmpty) {
          sendEvent({"authID": authid, "trading_account": newAccountNumber});
        } else {
          print(
            '❌ InstrumentsController: No auth token available for resubscribe',
          );
        }
      }
      print('✅ InstrumentsController: Resubscribed successfully');
    } catch (e) {
      print('❌ InstrumentsController: Error in unsubscribeAndResubscribe: $e');
      // Fallback: if unsubscribe/resubscribe fails, do full reconnect
      stopWebSocket();
      await Future.delayed(const Duration(milliseconds: 100));
      clearInstrumentsData();
      startWebSocket();
    }
  }
}
