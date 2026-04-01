import 'package:crm_app/constants/api_const.dart';
import 'package:crm_app/services/api_service.dart';
import 'package:get/get.dart';

class EligibleCopyAccount {
  final int id;
  final String metaAccountNumber;
  final String accountType;
  final num balance;
  final num equity;
  final bool isEnrolled;
  final List<Map<String, dynamic>> subscriptions;

  const EligibleCopyAccount({
    required this.id,
    required this.metaAccountNumber,
    required this.accountType,
    required this.balance,
    required this.equity,
    required this.isEnrolled,
    required this.subscriptions,
  });

  factory EligibleCopyAccount.fromJson(Map<String, dynamic> json) {
    final subsRaw = json['subscriptions'];
    final subs = subsRaw is List ? subsRaw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList() : <Map<String, dynamic>>[];
    return EligibleCopyAccount(
      id: (json['id'] ?? 0) is num ? (json['id'] as num).toInt() : 0,
      metaAccountNumber: (json['meta_account_number'] ?? '').toString(),
      accountType: (json['account_type'] ?? '').toString(),
      balance: (json['balance'] ?? 0) as num? ?? 0,
      equity: (json['equity'] ?? 0) as num? ?? 0,
      isEnrolled: json['is_enrolled'] == true,
      subscriptions: subs,
    );
  }
}

class CopyTradingSubscribeController extends GetxController {
  final String masterCode;
  final int planId;
  CopyTradingSubscribeController({required this.masterCode, required this.planId});

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxList<EligibleCopyAccount> eligibleAccounts = <EligibleCopyAccount>[].obs;
  final Rxn<EligibleCopyAccount> selectedAccount = Rxn<EligibleCopyAccount>();

  // subscribe params
  /// copying_method: "proportional" | "fixed"
  final RxString copyingMethod = 'proportional'.obs;

  /// Only used when copying_method == fixed
  final RxDouble fixedLotSize = 0.10.obs;

  /// TP/SL override settings
  final RxBool overridesSlTp = false.obs;
  /// sl_tp_mode: "pip" | "dollar" (only if overridesSlTp == true)
  final RxString slTpMode = 'pip'.obs;
  final RxDouble takeProfitPips = 0.0.obs;
  final RxDouble stopLossPips = 0.0.obs;
  final RxDouble takeProfitDollar = 0.0.obs;
  final RxDouble stopLossDollar = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadEligibleAccounts(showLoading: true);
  }

  Future<void> loadEligibleAccounts({bool showLoading = false}) async {
    if (showLoading) isLoading.value = true;
    errorMessage.value = '';
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final res = await ApiService.get(
        endpoint: ApiConstants.copyTradingCopierEligibleAccounts,
        queryParameters: {'plan_id': planId.toString(), '_t': timestamp.toString()},
      );
      if (!res.success || res.data == null) {
        eligibleAccounts.clear();
        errorMessage.value = res.message ?? 'Failed to load eligible accounts';
        return;
      }
      final data = res.data?['data'];
      if (data is! List) {
        eligibleAccounts.clear();
        errorMessage.value = 'Invalid response';
        return;
      }
      final list =
          data.whereType<Map>().map((e) => EligibleCopyAccount.fromJson(e.cast<String, dynamic>())).toList();
      eligibleAccounts.assignAll(list);
      if (selectedAccount.value == null && list.isNotEmpty) {
        selectedAccount.value = list.first;
      }
    } catch (e) {
      eligibleAccounts.clear();
      errorMessage.value = 'Load error: $e';
    } finally {
      if (showLoading) isLoading.value = false;
    }
  }

  Future<ApiResponse> subscribe({required num investmentAmount}) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final acc = selectedAccount.value;
      if (acc == null || acc.id <= 0) {
        errorMessage.value = 'Select an account';
        return ApiResponse.error(errorMessage.value);
      }

      final payload = <String, dynamic>{
        'master_code': masterCode,
        'plan_id': planId,
        'mt5_account_id': acc.id,
        'investment_amount': investmentAmount,
        'copying_method': copyingMethod.value,
      };

      if (copyingMethod.value == 'fixed') {
        payload['fixed_lot_size'] = fixedLotSize.value;
      }

      payload['overrides_sl_tp'] = overridesSlTp.value;
      if (overridesSlTp.value) {
        payload['sl_tp_mode'] = slTpMode.value;
        if (slTpMode.value == 'pip') {
          payload['take_profit_pips'] = takeProfitPips.value;
          payload['stop_loss_pips'] = stopLossPips.value;
        } else {
          payload['take_profit_dollar'] = takeProfitDollar.value;
          payload['stop_loss_dollar'] = stopLossDollar.value;
        }
      }

      final res = await ApiService.post(endpoint: ApiConstants.copyTradingCopierSubscribe, data: payload);
      if (!res.success) {
        errorMessage.value = res.message ?? 'Failed to subscribe';
      }
      return res;
    } catch (e) {
      errorMessage.value = 'Subscribe error: $e';
      return ApiResponse.error(errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }
}

