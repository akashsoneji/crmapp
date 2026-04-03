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
  final bool autoSelectFirstAccount;
  CopyTradingSubscribeController({
    required this.masterCode,
    required this.planId,
    this.autoSelectFirstAccount = true,
  });

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxList<EligibleCopyAccount> eligibleAccounts = <EligibleCopyAccount>[].obs;
  final Rxn<EligibleCopyAccount> selectedAccount = Rxn<EligibleCopyAccount>();

  // subscribe params
  /// UI selection / web key (sent as `sizing_method`):
  /// fixed | proportional_equity | proportional_balance | multiplier_only | mirror_ratio | percentage_risk
  /// reverse | dynamic_lot | fixed_ratio
  final RxString sizingMethod = 'fixed'.obs;

  /// API field `copying_method` must be either `fixed` or `proportional`
  /// (backend uses this for legacy compatibility)
  final RxString copyingMethod = 'fixed'.obs;

  /// Only used when copying_method == fixed
  final RxDouble fixedLotSize = 0.10.obs;

  /// Legacy proportional multiplier (also used by proportional_* when desired)
  final RxDouble lotMultiplier = 1.0.obs;

  /// multiplier_only
  final RxDouble multiplierOnly = 2.0.obs;

  /// mirror_ratio
  final RxDouble mirrorRatio = 0.5.obs;

  /// percentage_risk
  final RxDouble percentageRisk = 2.0.obs; // %
  final RxDouble percentageRiskSlPips = 50.0.obs; // used for auto lot calc on web

  /// reverse
  final RxBool isReverse = true.obs;

  /// dynamic_lot
  final RxDouble dynamicDrawdownThreshold = 20.0.obs; // %
  final RxDouble dynamicReductionRatio = 0.5.obs; // 0-1

  /// fixed_ratio
  final RxDouble fixedRatioProfitStep = 1000.0.obs; // $ profit milestone
  final RxDouble fixedRatioLotStep = 0.01.obs; // lot add per milestone

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
      if (autoSelectFirstAccount && selectedAccount.value == null && list.isNotEmpty) {
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
        'sizing_method': sizingMethod.value,
        'copying_method': copyingMethod.value,
      };

      // Always include lot_multiplier (backend examples include it even for fixed)
      payload['lot_multiplier'] = lotMultiplier.value;

      switch (sizingMethod.value) {
        case 'fixed':
          payload['fixed_lot_size'] = fixedLotSize.value;
          break;
        case 'mirror_ratio':
          payload['mirror_ratio'] = mirrorRatio.value;
          break;
        case 'percentage_risk':
          payload['risk_percent'] = percentageRisk.value;
          break;
        case 'reverse':
          payload['is_reverse'] = isReverse.value;
          break;
        case 'dynamic_lot':
          payload['dynamic_lot_rules'] = <String, dynamic>{
            'drawdown_threshold_pct': dynamicDrawdownThreshold.value > 0 ? dynamicDrawdownThreshold.value : null,
            'multiplier': dynamicReductionRatio.value > 0 ? dynamicReductionRatio.value : null,
          };
          break;
        case 'fixed_ratio':
          payload['fixed_ratio_rules'] = <String, dynamic>{
            'profit_step': fixedRatioProfitStep.value > 0 ? fixedRatioProfitStep.value : null,
            'lot_step': fixedRatioLotStep.value > 0 ? fixedRatioLotStep.value : null,
          };
          break;
        // proportional_equity / proportional_balance / multiplier_only etc:
        default:
          // no extra required fields (except ones already included like mirror_ratio/risk_percent)
          break;
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

