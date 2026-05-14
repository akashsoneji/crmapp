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
    final rawNumber = activeAccount?.metaAccountNumber;
    final tradingAccount =
        (rawNumber != null && rawNumber.trim().isNotEmpty) ? rawNumber : '0';

    try {
      isLoading.value = true;
      final response = await ApiService.get(
        endpoint: ApiConstants.getInstrumentsByAccount(tradingAccount),
      );

      if (response.success && response.data != null) {
        final searchResponse = SearchInstrumentsResponse.fromJson(response.data);
        if (searchResponse.data != null) {
          allSymbols.assignAll(searchResponse.data!.symbols);
          _updateAvailableCategories(searchResponse.data!.categories);

          if (!availableCategories.contains(currentCategory.value)) {
            currentCategory.value = 'All';
          }

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

  void _updateAvailableCategories(
      [List<InstrumentsDataCategory> apiCategories = const []]) {
    final symbolCategoryNames = allSymbols.map((s) => s.categoryName).toSet();

    if (apiCategories.isNotEmpty) {
      final sorted = <String>['All'];
      for (final c in apiCategories) {
        if (c.name.isEmpty) continue;
        if (symbolCategoryNames.contains(c.name) &&
            !sorted.contains(c.name)) {
          sorted.add(c.name);
        }
      }
      final remaining = symbolCategoryNames
          .where((n) => !sorted.contains(n))
          .toList()
        ..sort();
      sorted.addAll(remaining);
      availableCategories.assignAll(sorted);
      return;
    }

    final categories = symbolCategoryNames.toList();

    final List<String> priorityOrder = [
      'All',
      'Forex',
      'Currency',
      'Metal',
      'Metals',
      'Crypto',
      'Indices',
      'Energies',
      'Commodities',
    ];

    final sortedCategories = <String>['All'];

    for (var priority in priorityOrder) {
      if (priority == 'All') continue;

      final existingCategory = categories.firstWhereOrNull(
        (c) => c.toLowerCase() == priority.toLowerCase(),
      );

      if (existingCategory != null) {
        sortedCategories.add(existingCategory);
        categories.remove(existingCategory);
      }
    }

    categories.sort();
    sortedCategories.addAll(categories);

    availableCategories.assignAll(sortedCategories);
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
