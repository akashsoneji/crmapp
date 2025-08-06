import 'package:get/get.dart';
import '../controllers/account_controller.dart';
import '../controllers/instruments_controller.dart';

class TradingBinding extends Bindings {
  @override
  void dependencies() {
    // Controllers are already registered in main, just ensure they're available
    Get.lazyPut<AccountController>(() => Get.find<AccountController>());
    Get.lazyPut<InstrumentsController>(() => Get.find<InstrumentsController>());
  }
}