import 'package:crm_app/controllers/more/more_controller.dart';
import 'package:get/get.dart';
 
class MoreBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MoreController>(() => MoreController());
  }
}