import 'package:get/get.dart';
import 'package:crm_app/controllers/tenax_broker_selection_controller.dart';

class TenaxBrokerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TenaxBrokerSelectionController>(
      () => TenaxBrokerSelectionController(),
    );
  }
}
