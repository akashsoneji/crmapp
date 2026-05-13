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
  var currentCategory = 'Forex'.obs; // Default to Forex/Currency

  @override
  void onInit() {
    super.onInit();
    fetchInstruments();
  }

  Future<void> fetchInstruments() async {
    try {
      isLoading.value = true;

      // Determine account number: use active account number or "0" as fallback
      String accountNumber = "0";
      final activeAccount = _accountController.activeMT5Account;
      if (activeAccount != null) {
        final accountFromController = activeAccount.metaAccountNumber;
        if (accountFromController != null &&
            accountFromController.isNotEmpty &&
            accountFromController != "0") {
          accountNumber = accountFromController;
        }
      }

      final response = await ApiService.get(
        endpoint: ApiConstants.getInstrumentsByAccount(accountNumber),
      );

      if (response.success && response.data != null) {

        final searchResponse = SearchInstrumentsResponse.fromJson(
          response.data,
        );

        if (searchResponse.data != null) {
          allSymbols.assignAll(searchResponse.data!.symbols);
          _updateAvailableCategories();

          // Ensure default category exists, otherwise fallback to 'Currency', then 'All'
          if (!availableCategories.contains(currentCategory.value)) {
            if (availableCategories.contains('Currency')) {
              currentCategory.value = 'Currency';
            } else {
              currentCategory.value = 'All';
            }
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

  void _updateAvailableCategories() {
    final categories = allSymbols.map((s) => s.categoryName).toSet().toList();

    // Define priority categories in desired order
    // Handling common variations like 'Forex' vs 'Currency' and 'Metal' vs 'Metals'
    final List<String> priorityOrder = [
      'All',
      'Forex',
      'Currency',
      'Metal',
      'Metals',
      'Crypto',
    ];

    List<String> sortedCategories = [];

    // 1. Always start with 'All'
    sortedCategories.add('All');

    // 2. Add other priority items if they exist in the API data
    for (var priority in priorityOrder) {
      if (priority == 'All') continue;

      // Find the actual category name that matches (case-insensitive)
      final existingCategory = categories.firstWhereOrNull(
        (c) => c.toLowerCase() == priority.toLowerCase(),
      );

      if (existingCategory != null) {
        sortedCategories.add(existingCategory);
        categories.remove(existingCategory);
      }
    }

    // 3. Sort the remaining categories alphabetically
    categories.sort();

    // 4. Combine everything
    sortedCategories.addAll(categories);

    availableCategories.assignAll(sortedCategories);
  }

  void _applyFilter() {
    var results = allSymbols.toList();

    // Apply category filter
    if (currentCategory.value != 'All') {
      results =
          results
              .where((s) => s.categoryName == currentCategory.value)
              .toList();
    }

    // Apply search query filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      results =
          results.where((symbol) {
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
