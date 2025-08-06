import 'package:get/get.dart';

// This controller handles instruments/trading data
// Since I don't see the original InstrumentsBloc implementation,
// I'm creating a basic structure that can be expanded
class InstrumentsController extends GetxController {
  // Observable states
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;
  final _instruments = <Map<String, dynamic>>[].obs;
  final _selectedInstrument = Rxn<Map<String, dynamic>>();
  final _searchQuery = ''.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  List<Map<String, dynamic>> get instruments => _instruments;
  Map<String, dynamic>? get selectedInstrument => _selectedInstrument.value;
  String get searchQuery => _searchQuery.value;

  // Filtered instruments based on search
  List<Map<String, dynamic>> get filteredInstruments {
    if (_searchQuery.value.isEmpty) {
      return _instruments;
    }
    return _instruments.where((instrument) {
      final name = instrument['name']?.toString().toLowerCase() ?? '';
      final symbol = instrument['symbol']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.value.toLowerCase();
      return name.contains(query) || symbol.contains(query);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadInstruments();
  }

  Future<void> loadInstruments() async {
    try {
      _setLoading(true);
      _clearError();

      // TODO: Replace with actual API call
      // For now, using mock data
      await Future.delayed(const Duration(seconds: 1));
      
      _instruments.value = [
        {
          'id': '1',
          'name': 'EUR/USD',
          'symbol': 'EURUSD',
          'price': 1.0825,
          'change': 0.0012,
          'changePercent': 0.11,
        },
        {
          'id': '2',
          'name': 'GBP/USD',
          'symbol': 'GBPUSD',
          'price': 1.2634,
          'change': -0.0045,
          'changePercent': -0.35,
        },
        {
          'id': '3',
          'name': 'USD/JPY',
          'symbol': 'USDJPY',
          'price': 149.85,
          'change': 0.25,
          'changePercent': 0.17,
        },
        // Add more mock instruments as needed
      ];
    } catch (e) {
      _setError('Failed to load instruments: $e');
    } finally {
      _setLoading(false);
    }
  }

  void selectInstrument(Map<String, dynamic> instrument) {
    _selectedInstrument.value = instrument;
  }

  void updateSearchQuery(String query) {
    _searchQuery.value = query;
  }

  void clearSearch() {
    _searchQuery.value = '';
  }

  Future<void> refreshInstruments() async {
    await loadInstruments();
  }

  void _setLoading(bool loading) {
    _isLoading.value = loading;
  }

  void _setError(String error) {
    _errorMessage.value = error;
    if (error.isNotEmpty) {
      Get.snackbar(
        'Error',
        error,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  void _clearError() {
    _errorMessage.value = '';
  }
}