import 'package:crm_app/controllers/ticket_controller.dart';
import 'package:get/get.dart';

class TicketBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TicketController>(() => TicketController());
  }
}
