import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:crm_app/controllers/instruments_controller.dart';
import 'package:crm_app/controllers/search_instruments_controller.dart';
import 'package:crm_app/models/search_instruments_model.dart';
import 'package:crm_app/models/socket_response.dart';
import 'package:crm_app/screens/home/chart_screen.dart';
import 'package:crm_app/services/symbol_selection_service.dart';

/// State for the tenaxnew instrument sheet.
///
/// Uses the same data sources as `SearchInstrumentsScreen`:
/// - favourites mode (chart symbol picker): live `InstrumentsController`
///   instruments, filtered locally;
/// - full mode (Markets search): `SearchInstrumentsController` API list with
///   its categories and server-side search.
class InstrumentSearchSheetController extends GetxController {
  final bool favoritesOnly;

  /// Symbol currently shown on the chart; highlighted in the list.
  final String? activeSymbol;

  final TextEditingController searchField = TextEditingController();
  final RxString query = ''.obs;

  late final InstrumentsController instruments;
  SearchInstrumentsController? _search;

  InstrumentSearchSheetController({
    required this.favoritesOnly,
    this.activeSymbol,
  });

  SearchInstrumentsController get search => _search!;

  @override
  void onInit() {
    super.onInit();
    instruments = Get.find<InstrumentsController>();
    if (!favoritesOnly) {
      // Same refetch rule as SearchInstrumentsScreen: a reused controller does
      // not run onInit again, so refresh it for the current MT5 account.
      final alreadyRegistered = Get.isRegistered<SearchInstrumentsController>();
      _search = Get.put(SearchInstrumentsController());
      _search!.filterByCategory('All');
      if (alreadyRegistered) {
        _search!.fetchInstruments();
      }
    }
    searchField.addListener(_onQueryChanged);
  }

  @override
  void onClose() {
    searchField.removeListener(_onQueryChanged);
    searchField.dispose();
    super.onClose();
  }

  void _onQueryChanged() {
    if (query.value == searchField.text) return;
    query.value = searchField.text;
    if (!favoritesOnly) search.searchInstruments(searchField.text);
  }

  void clearQuery() => searchField.clear();

  /// Favourites filtered by [query], de-duplicated by symbol without suffix.
  List<ListElement> get favoriteResults => filterBySymbol<ListElement>(
        instruments.instruments,
        query.value,
        (item) => item.symbol,
      );

  bool isActive(String symbol) {
    final active = activeSymbol;
    if (active == null || active.isEmpty) return false;
    return stripSuffix(symbol).toUpperCase() ==
        stripSuffix(active).toUpperCase();
  }

  bool isFavorite(String symbol) => instruments.isFavorite(symbol);

  /// Same add/remove flow as the old list row.
  Future<void> toggleFavorite(SearchSymbol symbol) async {
    await instruments.toggleFavorite(
      symbol.displaySymbol,
      searchSymbol: symbol,
      hydrateAfterChange: false,
    );
    await instruments.syncMarketWatchV2AfterFavoriteChange(
      symbol.displaySymbol,
      isFavoriteNow: instruments.isFavorite(symbol.displaySymbol),
    );
  }

  /// Same side effects as `_navigateToChartWithSymbol`; the sheet closes
  /// itself afterwards.
  void selectSymbol(String symbol, void Function(String)? onNavigateToChart) {
    FocusManager.instance.primaryFocus?.unfocus();
    Get.find<SymbolSelectionService>().setSymbol(symbol);
    ChartScreen.setSelectedSymbol(symbol);
    onNavigateToChart?.call(symbol);
  }

  static String stripSuffix(String symbol) {
    if (!symbol.contains('.')) return symbol;
    return symbol.substring(0, symbol.lastIndexOf('.'));
  }

  /// Same matching as the old favourites list: case-insensitive "contains"
  /// on the symbol without its broker suffix, first occurrence wins.
  static List<T> filterBySymbol<T>(
    Iterable<T> source,
    String rawQuery,
    String Function(T) symbolOf,
  ) {
    final query = rawQuery.toLowerCase();
    final seen = <String>{};
    final result = <T>[];
    for (final item in source) {
      final stripped = stripSuffix(symbolOf(item));
      if (query.isNotEmpty && !stripped.toLowerCase().contains(query)) {
        continue;
      }
      if (seen.add(stripped.toUpperCase())) result.add(item);
    }
    return result;
  }
}
