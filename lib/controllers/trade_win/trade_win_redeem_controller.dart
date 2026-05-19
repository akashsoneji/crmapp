import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_app/controllers/trade_win/trade_win_controller.dart';
import 'package:crm_app/models/trade_win/trade_win_product_model.dart';
import 'package:crm_app/models/trade_win/trade_win_shipping_details_model.dart';
import 'package:crm_app/routes/app_pages.dart';

class TradeWinRedeemController extends GetxController {
  TradeWinRedeemController({
    required this.product,
    required this.initialQuantity,
  });

  final TradeWinProductModel product;
  final int initialQuantity;

  final RxInt currentStep = 1.obs;
  final RxInt quantity = 1.obs;
  final RxBool rememberAddress = true.obs;
  final RxBool isSubmitting = false.obs;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final countryController = TextEditingController();

  static const _prefPrefix = 'trade_win_shipping_';

  double get totalCost => product.requiredPoints * quantity.value;

  double get balanceAfter {
    final ctrl = Get.find<TradeWinController>();
    final current = ctrl.stats.value?.totalPoints ?? 0;
    return (current - totalCost).clamp(0, double.infinity);
  }

  @override
  void onInit() {
    super.onInit();
    quantity.value = initialQuantity.clamp(1, product.stock > 0 ? product.stock : 1);
    _loadSavedAddress();
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    cityController.dispose();
    countryController.dispose();
    super.onClose();
  }

  Future<void> _loadSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    nameController.text = prefs.getString('${_prefPrefix}name') ?? '';
    phoneController.text = prefs.getString('${_prefPrefix}phone') ?? '';
    emailController.text = prefs.getString('${_prefPrefix}email') ?? '';
    addressController.text = prefs.getString('${_prefPrefix}address') ?? '';
    cityController.text = prefs.getString('${_prefPrefix}city') ?? '';
    countryController.text = prefs.getString('${_prefPrefix}country') ?? '';
  }

  Future<void> _saveAddressIfNeeded() async {
    if (!rememberAddress.value) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefPrefix}name', nameController.text.trim());
    await prefs.setString('${_prefPrefix}phone', phoneController.text.trim());
    await prefs.setString('${_prefPrefix}email', emailController.text.trim());
    await prefs.setString('${_prefPrefix}address', addressController.text.trim());
    await prefs.setString('${_prefPrefix}city', cityController.text.trim());
    await prefs.setString('${_prefPrefix}country', countryController.text.trim());
  }

  void incrementQuantity() {
    final maxQty = product.stock > 0 ? product.stock : 1;
    if (quantity.value < maxQty) quantity.value++;
  }

  void decrementQuantity() {
    if (quantity.value > 1) quantity.value--;
  }

  void goToStep(int step) {
    currentStep.value = step.clamp(1, 2);
  }

  bool validateShipping() {
    return nameController.text.trim().isNotEmpty &&
        phoneController.text.trim().isNotEmpty &&
        emailController.text.trim().isNotEmpty &&
        addressController.text.trim().isNotEmpty &&
        cityController.text.trim().isNotEmpty &&
        countryController.text.trim().isNotEmpty;
  }

  TradeWinShippingDetailsModel get shippingDetails =>
      TradeWinShippingDetailsModel(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        email: emailController.text.trim(),
        address: addressController.text.trim(),
        city: cityController.text.trim(),
        country: countryController.text.trim(),
      );

  /// TODO: Replace with POST api/v1/user/trade-win/redeem when available.
  Future<void> submitRedemption() async {
    if (!validateShipping()) return;

    isSubmitting.value = true;
    try {
      await _saveAddressIfNeeded();

      final reference = 'TRW-${DateTime.now().millisecondsSinceEpoch}';

      if (Get.isRegistered<TradeWinController>()) {
        Get.find<TradeWinController>().fetchProducts(showLoader: false);
      }

      Get.offNamed(
        AppPages.TRADE_WIN_REDEMPTION_SUCCESS,
        arguments: {
          'productName': product.name,
          'reference': reference,
        },
      );
    } finally {
      isSubmitting.value = false;
    }
  }
}
