import 'package:get/get.dart';
import 'package:pipze/controllers/finance/deposit_controller.dart';

import '../services/api_service.dart';

class DepositBinding extends Bindings {
  @override
  void dependencies() {

    Get.lazyPut<ApiService>(() => ApiService());


    Get.lazyPut<DepositController>(() => DepositController());
  }
}