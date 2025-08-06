// import 'package:get/get.dart';

// // This controller handles instruments/trading data
// // Since I don't see the original InstrumentsBloc implementation,
// // I'm creating a basic structure that can be expanded
// class InstrumentsController extends GetxController {
//   // Observable states
//   final _isLoading = false.obs;
//   final _errorMessage = ''.obs;
//   final _instruments = <Map<String, dynamic>>[].obs;
//   final _selectedInstrument = Rxn<Map<String, dynamic>>();
//   final _searchQuery = ''.obs;

//   // Getters
//   bool get isLoading => _isLoading.value;
//   String get errorMessage => _errorMessage.value;
//   List<Map<String, dynamic>> get instruments => _instruments;
//   Map<String, dynamic>? get selectedInstrument => _selectedInstrument.value;
//   String get searchQuery => _searchQuery.value;

//   // Filtered instruments based on search
//   List<Map<String, dynamic>> get filteredInstruments {
//     if (_searchQuery.value.isEmpty) {
//       return _instruments;
//     }
//     return _instruments.where((instrument) {
//       final name = instrument['name']?.toString().toLowerCase() ?? '';
//       final symbol = instrument['symbol']?.toString().toLowerCase() ?? '';
//       final query = _searchQuery.value.toLowerCase();
//       return name.contains(query) || symbol.contains(query);
//     }).toList();
//   }

//   @override
//   void onInit() {
//     super.onInit();
//     loadInstruments();
//   }

//   Future<void> loadInstruments() async {
//     try {
//       _setLoading(true);
//       _clearError();

//       // TODO: Replace with actual API call
//       // For now, using mock data
//       await Future.delayed(const Duration(seconds: 1));

//       _instruments.value = [
//         {
//           'id': '1',
//           'name': 'EUR/USD',
//           'symbol': 'EURUSD',
//           'price': 1.0825,
//           'change': 0.0012,
//           'changePercent': 0.11,
//         },
//         {
//           'id': '2',
//           'name': 'GBP/USD',
//           'symbol': 'GBPUSD',
//           'price': 1.2634,
//           'change': -0.0045,
//           'changePercent': -0.35,
//         },
//         {
//           'id': '3',
//           'name': 'USD/JPY',
//           'symbol': 'USDJPY',
//           'price': 149.85,
//           'change': 0.25,
//           'changePercent': 0.17,
//         },
//         // Add more mock instruments as needed
//       ];
//     } catch (e) {
//       _setError('Failed to load instruments: $e');
//     } finally {
//       _setLoading(false);
//     }
//   }

//   void selectInstrument(Map<String, dynamic> instrument) {
//     _selectedInstrument.value = instrument;
//   }

//   void updateSearchQuery(String query) {
//     _searchQuery.value = query;
//   }

//   void clearSearch() {
//     _searchQuery.value = '';
//   }

//   Future<void> refreshInstruments() async {
//     await loadInstruments();
//   }

//   void _setLoading(bool loading) {
//     _isLoading.value = loading;
//   }

//   void _setError(String error) {
//     _errorMessage.value = error;
//     if (error.isNotEmpty) {
//       Get.snackbar(
//         'Error',
//         error,
//         snackPosition: SnackPosition.TOP,
//       );
//     }
//   }

//   void _clearError() {
//     _errorMessage.value = '';
//   }
// }

// lib/presentation/controllers/instruments_controller.dart
import 'package:get/get.dart';
import 'package:pipze/models/instrument.dart';

class InstrumentsController extends GetxController {
  final RxList<Instrument> allInstruments = <Instrument>[].obs;
  final RxList<Instrument> instruments = <Instrument>[].obs;
  final RxString currentFilter = 'Currency'.obs;
  final RxString currentSort = 'Popularity'.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize instruments
    allInstruments.addAll([
      Instrument(
        name: 'EURUSD',
        flag: '🇪🇺🇺🇸',
        status: 'Market closed',
        bidPrice: '1.24948',
        askPrice: '1.24959',
        lowPrice: '0.65514',
        highPrice: '0.65582',
        category: 'Currency',
      ),
      Instrument(
        name: 'AUDCHF',
        flag: '🇦🇺🇨🇭',
        status: 'Market closed',
        bidPrice: '1.24948',
        askPrice: '1.24959',
        lowPrice: '0.65514',
        highPrice: '0.65582',
        category: 'Currency',
      ),
      Instrument(
        name: 'AUDJPY',
        flag: '🇦🇺🇯🇵',
        status: '10:47:54',
        heigh: 'S 0.06',
        bidPrice: '1.24948',
        askPrice: '1.24959',
        lowPrice: '0.65514',
        highPrice: '0.65582',
        category: 'Currency',
      ),
      Instrument(
        name: 'AUDCHF',
        flag: '🇦🇺🇨🇭',
        status: 'Market closed',
        bidPrice: '1.24948',
        askPrice: '1.24959',
        lowPrice: '0.65514',
        highPrice: '0.65582',
        category: 'Currency',
      ),
      Instrument(
        name: 'EURUSD',
        flag: '🇪🇺🇺🇸',
        status: 'Market closed',
        bidPrice: '1.24948',
        askPrice: '1.24959',
        lowPrice: '0.65514',
        highPrice: '0.65582',
        category: 'Currency',
      ),
      Instrument(
        name: 'AUDCHF',
        flag: '🇦🇺🇨🇭',
        status: 'Market closed',
        bidPrice: '1.24948',
        askPrice: '1.24959',
        lowPrice: '0.65514',
        highPrice: '0.65582',
        category: 'Currency',
      ),
      Instrument(
        name: 'AUDJPY',
        flag: '🇦🇺🇯🇵',
        status: 'Market closed',
        bidPrice: '1.24948',
        askPrice: '1.24959',
        lowPrice: '0.65514',
        highPrice: '0.65582',
        category: 'Currency',
      ),
      Instrument(
        name: 'AUDCHF',
        flag: '🇦🇺🇨🇭',
        status: 'Market closed',
        bidPrice: '1.24948',
        askPrice: '1.24959',
        lowPrice: '0.65514',
        highPrice: '0.65582',
        category: 'Currency',
      ),
      Instrument(
        name: 'XAUUSD',
        flag: '🥇',
        status: '01:00:00 H 20.0',
        bidPrice: '3426.588',
        askPrice: '3426.772',
        lowPrice: '3426.0',
        highPrice: '3427.0',
        category: 'Metals',
      ),
      Instrument(
        name: 'XAGUSD',
        flag: '🥈',
        status: '01:00:00 H 33.0',
        bidPrice: '39.419',
        askPrice: '39.442',
        lowPrice: '39.40',
        highPrice: '39.45',
        category: 'Metals',
      ),
      Instrument(
        name: 'AU200',
        flag: '🇦🇺',
        status: '01:00:00 H 26.0',
        bidPrice: '8734.25',
        askPrice: '8736.87',
        lowPrice: '8730.0',
        highPrice: '8740.0',
        category: 'Indices Spot',
      ),
      Instrument(
        name: 'DE40',
        flag: '🇩🇪',
        status: '01:00:00 H 35.0',
        bidPrice: '24157.431',
        askPrice: '24157.776',
        lowPrice: '24150.0',
        highPrice: '24160.0',
        category: 'Indices Spot',
      ),
      Instrument(
        name: 'ES35',
        flag: '🇪🇸',
        status: '01:00:00 H 65.0',
        bidPrice: '14136.54',
        askPrice: '14143.07',
        lowPrice: '14130.0',
        highPrice: '14150.0',
        category: 'Indices Spot',
      ),
      Instrument(
        name: 'EU50',
        flag: '🇪🇺',
        status: '01:00:00 H 25.0',
        bidPrice: '5335.73',
        askPrice: '5338.28',
        lowPrice: '5330.0',
        highPrice: '5340.0',
        category: 'Indices Spot',
      ),
      Instrument(
        name: 'FR40',
        flag: '🇫🇷',
        status: '01:00:00 H 22.0',
        bidPrice: '7818.84',
        askPrice: '7821.09',
        lowPrice: '7815.0',
        highPrice: '7825.0',
        category: 'Indices Spot',
      ),
      Instrument(
        name: 'HK50',
        flag: '🇭🇰',
        status: '01:00:00 H 55.0',
        bidPrice: '25503.35',
        askPrice: '25508.76',
        lowPrice: '25500.0',
        highPrice: '25510.0',
        category: 'Indices Spot',
      ),
    ]);
    loadInstruments();
  }

  void loadInstruments() {
    final currencyInstruments =
        allInstruments
            .where((instrument) => instrument.category == 'Currency')
            .toList();
    instruments.assignAll(currencyInstruments);
    currentFilter.value = 'Currency';
    searchQuery.value = '';
    isSearching.value = false;
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
    List<Instrument> sortedInstruments = List.from(instruments);

    switch (sortBy) {
      case 'Popularity':
        break;
      case 'Daily Changes':
        sortedInstruments.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Daily gain':
        sortedInstruments.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'Daily loss':
        sortedInstruments.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    instruments.assignAll(sortedInstruments);
  }

  void toggleFavorite(String instrumentName) {
    final updatedInstruments =
        allInstruments.map((instrument) {
          if (instrument.name == instrumentName) {
            return Instrument(
              name: instrument.name,
              flag: instrument.flag,
              status: instrument.status,
              bidPrice: instrument.bidPrice,
              askPrice: instrument.askPrice,
              lowPrice: instrument.lowPrice,
              highPrice: instrument.highPrice,
              isFavorite: !instrument.isFavorite,
              category: instrument.category,
            );
          }
          return instrument;
        }).toList();

    allInstruments.assignAll(updatedInstruments);
    _updateFilteredInstruments();
  }

  void _updateFilteredInstruments() {
    List<Instrument> filteredInstruments = allInstruments;

    if (currentFilter.value != 'All' && currentFilter.value != 'Favorites') {
      filteredInstruments =
          filteredInstruments
              .where((instrument) => instrument.category == currentFilter.value)
              .toList();
    } else if (currentFilter.value == 'Favorites') {
      filteredInstruments =
          filteredInstruments
              .where((instrument) => instrument.isFavorite)
              .toList();
    }

    if (searchQuery.value.isNotEmpty) {
      filteredInstruments =
          filteredInstruments
              .where(
                (instrument) => instrument.name.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ),
              )
              .toList();
    }

    instruments.assignAll(filteredInstruments);
  }
}
