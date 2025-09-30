import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/api_const.dart';
import 'package:pipze/models/socket_response.dart';
import 'package:pipze/services/secure_storage_service.dart';
import 'package:pipze/controllers/account_controller.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class InstrumentsController extends GetxController with WidgetsBindingObserver {
  final RxList<ListElement> allInstruments = <ListElement>[].obs;
  final RxList<ListElement> instruments = <ListElement>[].obs;
  final RxString currentFilter = 'Currency'.obs;
  final RxString currentSort = 'Popularity'.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;
  final RxMap<String, List<ListElement>> tradingGroups =
      <String, List<ListElement>>{}.obs;
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

    // Initialize WebSocket connection
    _initializeWebSocket();
  }

  void _initializeWebSocket() {
    try {
      channel = WebSocketChannel.connect(Uri.parse(ApiConstants.socketUrl));
      isConnected.value = true;
      _reconnectAttempts = 0;

      // Listen for data from socket server
      channel.stream.listen(
        (message) {
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
    final authid = await SecureStorageService.getWebsocketToken();
    print(
      "Instruments: WebSocket token: ${authid != null ? 'exists' : 'null'}",
    );

    if (authid == null || authid.isEmpty) {
      print(
        'Instruments: WebSocket token is null or empty, retrying in 2 seconds...',
      );
      // Retry after a short delay to allow token to be saved
      Timer(const Duration(seconds: 2), () {
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

    print("Instruments: Using MT5 Account Number: $accountNumber");

    sendEvent({
      "authID": authid,
      "price": "price", // symbol or any user input
      "isapp": 1,
      "mt5AccountNumber": int.tryParse(accountNumber) ?? 901246,
      "type": "marketWatch",
    });
  }

  void updateFromJson(String jsonStr) {
    try {
      final SocketResponse socketResponse = SocketResponse.fromJson(
        jsonDecode(jsonStr),
      );

      // Update trading groups
      final Map<String, List<ListElement>> map = {};
      for (final group in socketResponse.groups) {
        map[group.groupName] = group.list;
      }
      tradingGroups.value = map;

      // Update all instruments list - but update existing objects instead of replacing
      final List<ListElement> allItems = [];
      for (final group in socketResponse.groups) {
        allItems.addAll(group.list);
      }

      // Instead of assignAll, update existing instruments or add new ones
      _updateInstrumentsList(allItems);

      // Update filtered instruments
      _updateFilteredInstruments();
    } catch (e) {
      print('Error parsing JSON: $e');
    }
  }

  void _updateInstrumentsList(List<ListElement> newInstruments) {
    // Create a map of existing instruments by symbol for quick lookup
    final Map<String, ListElement> existingInstrumentsMap = {};
    for (final instrument in allInstruments) {
      existingInstrumentsMap[instrument.symbol] = instrument;
    }

    // Update or add instruments
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
        );
        updatedInstruments.add(updatedInstrument);
      } else {
        // Add new instrument
        updatedInstruments.add(newInstrument);
      }
    }

    // Update the observable list
    allInstruments.assignAll(updatedInstruments);
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

  void _disconnectWebSocket() {
    try {
      channel.sink.close();
      isConnected.value = false;
    } catch (e) {
      print('Error disconnecting WebSocket: $e');
    }
  }

  void loadInstruments() {
    final currencyInstruments =
        allInstruments
            .where(
              (instrument) =>
                  getGroupNameForSymbol(instrument.symbol) == 'Currency',
            )
            .toList();
    instruments.assignAll(currencyInstruments);
    currentFilter.value = 'Currency';
    searchQuery.value = '';
    isSearching.value = false;
  }

  String getGroupNameForSymbol(String symbol) {
    for (final entry in tradingGroups.entries) {
      if (entry.value.any((element) => element.symbol == symbol)) {
        return entry.key;
      }
    }
    return 'Unknown';
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
    List<ListElement> sortedInstruments = List.from(instruments);

    switch (sortBy) {
      case 'Popularity':
        break;
      case 'Daily Changes':
        sortedInstruments.sort((a, b) => a.symbol.compareTo(b.symbol));
        break;
      case 'Daily gain':
        sortedInstruments.sort((a, b) => b.symbol.compareTo(a.symbol));
        break;
      case 'Daily loss':
        sortedInstruments.sort((a, b) => a.symbol.compareTo(b.symbol));
        break;
    }

    instruments.assignAll(sortedInstruments);
  }

  void toggleFavorite(String instrumentSymbol) {
    // Note: ListElement doesn't have isFavorite property, you may need to extend it
    // or create a separate favorites list
    print('Toggle favorite for: $instrumentSymbol');
  }

  void _updateFilteredInstruments() {
    List<ListElement> filteredInstruments = allInstruments;

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
    // Note: Favorites functionality removed as ListElement doesn't have isFavorite property

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

    instruments.assignAll(filteredInstruments);
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
