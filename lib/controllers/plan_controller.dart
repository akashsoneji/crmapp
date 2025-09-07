import 'package:get/get.dart';
import 'package:pipze/services/api_service.dart';
import 'package:pipze/services/secure_storage_service.dart';
import 'package:pipze/widgets/custom_toast.dart';
import '../constants/api_const.dart';

class PlanModel {
  final String? groupName;
  final String? ibGroupType;
  final String? mt5GroupName;
  final String? execution;
  final String? commission;
  final String? companyWillGet;
  final String? companyWillPasson;
  final String? leverage;
  final String? minimumDeposit;
  final String? planTitle;
  final String? minimumTradeSize;
  final String? spread;
  final String? stopOutLevel;
  final String? swapFreeDays;
  final String? tradingInstruments;
  final String? tradingPlatform;

  PlanModel({
    this.groupName,
    this.ibGroupType,
    this.mt5GroupName,
    this.execution,
    this.commission,
    this.companyWillGet,
    this.companyWillPasson,
    this.leverage,
    this.minimumDeposit,
    this.planTitle,
    this.minimumTradeSize,
    this.spread,
    this.stopOutLevel,
    this.swapFreeDays,
    this.tradingInstruments,
    this.tradingPlatform,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      groupName: json['group_name'],
      ibGroupType: json['ib_group_type'],
      mt5GroupName: json['mt5_group_name'],
      execution: json['execution'],
      commission: json['commission'],
      companyWillGet: json['company_will_get'],
      companyWillPasson: json['company_will_passon'],
      leverage: json['leverage'],
      minimumDeposit: json['minimum_deposit'],
      planTitle: json['plan_title'],
      minimumTradeSize: json['minimum_trade_size'],
      spread: json['spread'],
      stopOutLevel: json['stop_out_level'],
      swapFreeDays: json['swap_free_days'],
      tradingInstruments: json['trading_instruments'],
      tradingPlatform: json['trading_platform'],
    );
  }
}


class PlanController extends GetxController {
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var plan = Rxn<PlanModel>();       // for single object
  var plans = <PlanModel>[].obs;     // for list, if API returns array

  Future<void> fetchPlan({required int groupId}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final token = await SecureStorageService.getAuthToken();
      final response = await ApiService.post(
          endpoint: ApiConstants.realPlanDetails,
          data: {"group_id":groupId}
      );


      if (response.success) {
        final data = response.data;
        if (data is List) {
          plans.value = data.map((e) => PlanModel.fromJson(e)).toList();
        } else if (data is Map) {
          plan.value = PlanModel.fromJson(Map<String, dynamic>.from(data));
        }
      } else {
        errorMessage.value = response.message ?? "Failed to fetch plan";
      }
    } catch (e) {
      errorMessage.value = "Error: $e";
    } finally {
      isLoading.value = false;
    }
  }
}