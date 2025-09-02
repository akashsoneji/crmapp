import 'dart:convert';

import 'package:get/get.dart';
import 'package:pipze/models/socket_response.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class InstrumentsController extends GetxController {
  final RxList<ListElement> allInstruments = <ListElement>[].obs;
  final RxList<ListElement> instruments = <ListElement>[].obs;
  final RxString currentFilter = 'Currency'.obs;
  final RxString currentSort = 'Popularity'.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;
  final RxMap<String, List<ListElement>> tradingGroups =
      <String, List<ListElement>>{}.obs;
  final String socketUrl =
      'wss://my.pipze.com:8080'; // Put your WebSocket URL here
  late WebSocketChannel channel;

  @override
  void onInit() {
    super.onInit();
    // Initialize WebSocket connection
    channel = WebSocketChannel.connect(Uri.parse(socketUrl));

    // Listen for data from socket server
    channel.stream.listen(
      (message) {
        updateFromJson(message);
      },
      onError: (error) {
        print('WebSocket error: $error');
      },
      onDone: () {
        print('WebSocket connection closed');
      },
    );

    sendEvent({
      "authID":
          "eyJpdiI6ImQwZkxLYzlFU3ZSbXFZbDFHYStMYnc9PSIsInZhbHVlIjoiTWE2YjBVejBlY1FkRnJiaXl4STRhUG5oTWhzcEdJSzJTVmU4UTRLN1paREdQL0Q0OHZqcmhvZ3V2UkY5c3lqUERtMDFqVXhIZmQ0UzBNdWlhN3RVQVBkbmlFd3BXT3BlTFFnQXpuQmhNemE2ajhIbUhqOU03OTVLVlJNVU5PUjciLCJtYWMiOiIxMGJiMmM0YmIyMmY5Y2QyMDVhOWJkM2UxZDYyODc0OWI1OTk0YjFlODgzOWIyNzI5NzI5NDg5NDViOTdjMWU4IiwidGFnIjoiIn0=",
      "price": "price", // symbol or any user input
      "isapp": 1,
      "mt5AccountNumber": 901246,
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

      // Update all instruments list
      final List<ListElement> allItems = [];
      for (final group in socketResponse.groups) {
        allItems.addAll(group.list);
      }
      allInstruments.assignAll(allItems);

      // Update filtered instruments
      _updateFilteredInstruments();
    } catch (e) {
      print('Error parsing JSON: $e');
    }
  }

  // Send event with parameters over WebSocket
  void sendEvent(Map<String, dynamic> event) {
    final encoded = jsonEncode(event);
    channel.sink.add(encoded);
  }

  @override
  void onClose() {
    // Close WebSocket connection when controller disposed
    channel.sink.close();
    super.onClose();
  }

  void loadInstruments() {
    final currencyInstruments =
        allInstruments
            .where(
              (instrument) =>
                  _getGroupNameForSymbol(instrument.symbol) == 'Currency',
            )
            .toList();
    instruments.assignAll(currencyInstruments);
    currentFilter.value = 'Currency';
    searchQuery.value = '';
    isSearching.value = false;
  }

  String _getGroupNameForSymbol(String symbol) {
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
                    _getGroupNameForSymbol(instrument.symbol) ==
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
}
