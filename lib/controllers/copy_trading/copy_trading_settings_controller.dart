import 'package:get/get.dart';

class CopyTradingSettingsController extends GetxController {
  // Demo wallet balance
  final RxString walletBalance = r'$0.00'.obs;

  // Selected tab in Wallet Screen (Actions, History, About)
  final RxInt selectedWalletTab = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize data from API if needed
  }

  void refreshData() {
    // Refresh logic
  }
}
