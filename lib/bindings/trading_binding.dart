import 'package:get/get.dart';
import '../controllers/account_controller.dart';
import '../controllers/instruments_controller.dart';
import '../controllers/trading_controller.dart';
import '../services/trading_websocket_service.dart';
import '../services/account_websocket_service.dart';

class TradingBinding extends Bindings {
  @override
  void dependencies() {
    // Controllers are already registered in main, just ensure they're available
    Get.lazyPut<AccountController>(() => Get.find<AccountController>());
    Get.lazyPut<InstrumentsController>(() => Get.find<InstrumentsController>());
    Get.lazyPut<TradingController>(() => TradingController());

    // Initialize WebSocket services early so that AccountHeaderWidget has access to data immediately
    if (!Get.isRegistered<TradingWebSocketService>()) {
      Get.put(TradingWebSocketService(), permanent: true);
    }
    if (!Get.isRegistered<AccountWebSocketService>()) {
      Get.put(AccountWebSocketService(), permanent: true);
    }
  }
}