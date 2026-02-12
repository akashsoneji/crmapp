import 'package:crm_app/controllers/instruments_controller.dart';
import 'package:crm_app/controllers/trading_controller.dart';
import 'package:get/get.dart';
import 'package:crm_app/controllers/account_controller.dart';
class TradingBinding extends Bindings {
  @override
  void dependencies() {
    // Controllers are already registered in main, just ensure they're available
    Get.lazyPut<AccountController>(() => Get.find<AccountController>());
    Get.lazyPut<InstrumentsController>(() => Get.find<InstrumentsController>());
    Get.lazyPut<TradingController>(() => TradingController());
  }
}