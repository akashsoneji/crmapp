import 'package:get/get.dart';
import 'package:crm_app/controllers/finance/deposit_controller.dart';

class DepositBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DepositController>(() => DepositController());
  }
}