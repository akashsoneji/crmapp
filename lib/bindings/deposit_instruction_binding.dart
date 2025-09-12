import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/bindings_interface.dart';
import 'package:pipze/controllers/finance/deposit_instrction_controller.dart';

class DepositInstructionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DepositInstructionController>(() => DepositInstructionController(),);
  }
}
