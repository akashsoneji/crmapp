import 'package:get/get.dart';
import 'package:crm_app/constants/api_const.dart';
import 'package:crm_app/models/trade_win/trade_win_leaderboard_entry_model.dart';
import 'package:crm_app/models/trade_win/trade_win_past_win_model.dart';
import 'package:crm_app/models/trade_win/trade_win_product_model.dart';
import 'package:crm_app/models/trade_win/trade_win_stats_model.dart';
import 'package:crm_app/services/api_service.dart';

class TradeWinController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool moduleEnabled = true.obs;
  final RxString errorMessage = ''.obs;
  final RxString selectedCategory = 'all'.obs;
  final RxInt mainTabIndex = 0.obs;

  final RxList<TradeWinProductModel> products = <TradeWinProductModel>[].obs;
  final Rxn<TradeWinStatsModel> stats = Rxn<TradeWinStatsModel>();
  final RxList<TradeWinPastWinModel> pastWins = <TradeWinPastWinModel>[].obs;
  final RxList<TradeWinLeaderboardEntryModel> leaderboard =
      <TradeWinLeaderboardEntryModel>[].obs;

  List<String> get categories {
    final set = <String>{'all'};
    for (final p in products) {
      if (p.category.isNotEmpty) set.add(p.category.toLowerCase());
    }
    return set.toList();
  }

  List<TradeWinProductModel> get filteredProducts {
    final cat = selectedCategory.value.toLowerCase();
    if (cat == 'all') return products.toList();
    return products.where((p) => p.category.toLowerCase() == cat).toList();
  }

  TradeWinProductModel? productById(int id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  Future<void> fetchProducts({bool showLoader = true}) async {
    if (showLoader) isLoading.value = true;
    errorMessage.value = '';

    try {
      final response = await ApiService.get(
        endpoint: ApiConstants.tradeWinProducts,
      );

      if (!response.success || response.data == null) {
        errorMessage.value = response.message ?? 'Failed to load products';
        return;
      }

      final root = _asMap(response.data);
      if (root == null) {
        errorMessage.value = 'Invalid response';
        return;
      }

      moduleEnabled.value = root['module_enabled'] != false;

      final data = _asMap(root['data']) ?? root;
      final productsRaw = data['products'];
      if (productsRaw is List) {
        products.assignAll(
          productsRaw
              .whereType<Map>()
              .map(
                (e) =>
                    TradeWinProductModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList(),
        );
      } else {
        products.clear();
      }

      final statsRaw = data['stats'];
      stats.value =
          statsRaw is Map
              ? TradeWinStatsModel.fromJson(Map<String, dynamic>.from(statsRaw))
              : null;

      final pastRaw = data['past_wins'];
      if (pastRaw is List) {
        pastWins.assignAll(
          pastRaw
              .whereType<Map>()
              .map(
                (e) =>
                    TradeWinPastWinModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList(),
        );
      } else {
        pastWins.clear();
      }

      final leaderboardRaw = data['leaderboard'];
      if (leaderboardRaw is List) {
        leaderboard.assignAll(
          leaderboardRaw
              .whereType<Map>()
              .map(
                (e) => TradeWinLeaderboardEntryModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList(),
        );
      } else {
        leaderboard.clear();
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      if (showLoader) isLoading.value = false;
    }
  }

  void selectCategory(String category) {
    selectedCategory.value = category.toLowerCase();
  }

  Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }
}
