import 'package:crm_app/constants/api_const.dart';
import 'package:crm_app/services/api_service.dart';
import 'package:get/get.dart';

class CopyTradingMasterListItem {
  final String masterCode;
  final String nickname;
  final String name;
  final int planCount;
  final int totalCopiers;
  final num totalAum;
  final int? riskScore;
  final num totalGain;
  final int activeDays;
  final num winRate;
  final bool isEnrolled;

  const CopyTradingMasterListItem({
    required this.masterCode,
    required this.nickname,
    required this.name,
    required this.planCount,
    required this.totalCopiers,
    required this.totalAum,
    required this.riskScore,
    required this.totalGain,
    required this.activeDays,
    required this.winRate,
    required this.isEnrolled,
  });

  factory CopyTradingMasterListItem.fromJson(Map<String, dynamic> json) {
    return CopyTradingMasterListItem(
      masterCode: (json['master_code'] ?? '').toString(),
      nickname: (json['master_nickname'] ?? '').toString(),
      name: (json['master_name'] ?? '').toString(),
      planCount: (json['plan_count'] ?? 0) is num ? (json['plan_count'] as num).toInt() : 0,
      totalCopiers:
          (json['total_copiers'] ?? 0) is num ? (json['total_copiers'] as num).toInt() : 0,
      totalAum: (json['total_aum'] ?? 0) as num? ?? 0,
      riskScore: json['risk_score'] is num ? (json['risk_score'] as num).toInt() : null,
      totalGain: (json['total_gain'] ?? 0) as num? ?? 0,
      activeDays:
          (json['active_days'] ?? 0) is num ? (json['active_days'] as num).toInt() : 0,
      winRate: (json['win_rate'] ?? 0) as num? ?? 0,
      isEnrolled: json['is_enrolled'] == true,
    );
  }
}

class CopyTradingMastersController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<CopyTradingMasterListItem> masters = <CopyTradingMasterListItem>[].obs;

  final RxString search = ''.obs;
  final RxString sort = ''.obs; // aum | copiers | gain

  @override
  void onInit() {
    super.onInit();
    loadMasters(showLoading: true);
  }

  Future<void> loadMasters({bool showLoading = false}) async {
    if (showLoading) isLoading.value = true;
    errorMessage.value = '';
    try {
      final qp = <String, dynamic>{};
      if (search.value.trim().isNotEmpty) qp['search'] = search.value.trim();
      if (sort.value.trim().isNotEmpty) qp['sort'] = sort.value.trim();

      final res = await ApiService.get(endpoint: ApiConstants.copyTradingMasters, queryParameters: qp);
      if (!res.success || res.data == null) {
        masters.clear();
        errorMessage.value = res.message ?? 'Failed to load masters';
        return;
      }

      final data = res.data?['data'];
      if (data is! List) {
        masters.clear();
        errorMessage.value = 'Invalid response';
        return;
      }

      masters.assignAll(
        data.whereType<Map>().map((e) => CopyTradingMasterListItem.fromJson(e.cast<String, dynamic>())),
      );
    } catch (e) {
      masters.clear();
      errorMessage.value = 'Load error: $e';
    } finally {
      if (showLoading) isLoading.value = false;
    }
  }
}

