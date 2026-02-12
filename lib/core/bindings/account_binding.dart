import 'package:crm_app/controllers/account_controller.dart';
import 'package:get/get.dart';
 
class AccountBinding extends Bindings {
  @override
  void dependencies() {
    // AccountController is already registered in main, just ensure it's available
    Get.lazyPut<AccountController>(() => Get.find<AccountController>());
  }
}