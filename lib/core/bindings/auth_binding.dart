import 'package:crm_app/controllers/auth_controller.dart';
import 'package:get/get.dart';
 
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // AuthController is already registered in main, just ensure it's available
    Get.lazyPut<AuthController>(() => Get.find<AuthController>());
  }
}