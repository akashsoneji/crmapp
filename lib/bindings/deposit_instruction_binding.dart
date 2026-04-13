import 'package:get/get.dart';
import 'package:crm_app/controllers/finance/deposit_instrction_controller.dart';

class DepositInstructionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DepositInstructionController>(
      () => DepositInstructionController(),
    );
  }
}
