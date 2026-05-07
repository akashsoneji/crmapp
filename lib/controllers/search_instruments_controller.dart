import 'package:get/get.dart';
import 'package:crm_app/services/api_service.dart';
import 'package:crm_app/constants/api_const.dart';
import 'package:crm_app/controllers/account_controller.dart';
import 'package:crm_app/models/search_instruments_model.dart';
import 'package:crm_app/models/socket_response.dart';

class SearchInstrumentsController extends GetxController {
  final AccountController _accountController = Get.find<AccountController>();

  var isLoading = false.obs;
  var allSymbols = <SearchSymbol>[].obs;
  var filteredSymbols = <SearchSymbol>[].obs;
  var availableCategories = <String>[].obs;
  var searchQuery = ''.obs;
  var currentCategory = 'All'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchInstruments();
  }

  Future<void> fetchInstruments() async {
    final activeAccount = _accountController.activeMT5Account;
    if (activeAccount == null) return;

    try {
      isLoading.value = true;
      final response = await ApiService.get(
        endpoint: ApiConstants.getInstrumentsByAccount(activeAccount.metaAccountNumber),
      );

      if (response.success && response.data != null) {
        final searchResponse = SearchInstrumentsResponse.fromJson(response.data);
        if (searchResponse.data != null) {
          allSymbols.assignAll(searchResponse.data!.symbols);
          _updateAvailableCategories();
          _applyFilter();
        }
      }
    } catch (e) {
      print('Error fetching search instruments: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void searchInstruments(String query) {
    searchQuery.value = query;
    _applyFilter();
  }

  void filterByCategory(String category) {
    currentCategory.value = category;
    _applyFilter();
  }

  void _updateAvailableCategories() {
    final categories = allSymbols.map((s) => s.categoryName).toSet().toList();
    categories.sort();
    availableCategories.assignAll(['All', ...categories]);
  }

  void _applyFilter() {
    var results = allSymbols.toList();

    // Apply category filter
    if (currentCategory.value != 'All') {
      results = results.where((s) => s.categoryName == currentCategory.value).toList();
    }

    // Apply search query filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      results = results.where((symbol) {
        return symbol.displaySymbol.toLowerCase().contains(query) ||
               symbol.categoryName.toLowerCase().contains(query);
      }).toList();
    }

    filteredSymbols.assignAll(results);
  }

  // Convert SearchSymbol to ListElement for UI compatibility if needed
  ListElement mapToListElement(SearchSymbol symbol) {
    return ListElement(
      symbol: symbol.displaySymbol,
      digits: symbol.digits,
      bid: 0.0, // Static data from API doesn't have bid/ask
      ask: 0.0,
      last: 0,
      volume: 0,
      volumeReal: 0,
      logo: '', // Default empty logo
      spreadDiff: symbol.spreadConfig.spreadDiff,
      category: symbol.categoryName,
    );
  }
}
