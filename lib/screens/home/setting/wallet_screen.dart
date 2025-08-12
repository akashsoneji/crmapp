import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../controllers/wallet_controller.dart';

class WalletScreen extends StatelessWidget {
  // const WalletScreen({super.key});
  final WalletController controller = Get.put(WalletController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Wallet',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            // Wallet Info Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Wallet ID
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Wallet ID',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Obx(() => Text(
                        controller.walletId.value,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      )),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Balance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Balance',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Obx(() => Text(
                        '\$${controller.balance.value.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      )),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Transfer Form
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Transfer From
                    _buildFieldLabel('Transfer From'),
                    SizedBox(height: 8),
                    Obx(() => GestureDetector(
                      onTap: controller.toggleTransferFromDropdown,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              controller.transferFromAccount.value,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            Icon(
                              controller.showTransferFromDropdown.value
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ),
                    )),

                    // Dropdown options
                    Obx(() => controller.showTransferFromDropdown.value
                        ? Container(
                      margin: EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Column(
                        children: controller.accountOptions.map((account) {
                          return GestureDetector(
                            onTap: () => controller.selectTransferFromAccount(account),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Text(
                                account,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    )
                        : SizedBox.shrink()),

                    SizedBox(height: 20),

                    // Transfer To
                    _buildFieldLabel('Transfer to'),
                    SizedBox(height: 8),
                    TextField(
                      controller: controller.transferToController,
                      onChanged: controller.updateTransferToAccount,
                      decoration: InputDecoration(
                        hintText: 'MT5 Account Number',
                        hintStyle: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFF7B2CBF)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Amount
                    _buildFieldLabel('Amount'),
                    SizedBox(height: 8),
                    TextField(
                      controller: controller.amountController,
                      onChanged: controller.updateAmount,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: '\$500.00',
                        hintStyle: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFF7B2CBF)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),

                    Spacer(),

                    // Deposit Wallet Button
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 12),
                      child: Obx(() => OutlinedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.depositWallet,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Color(0xFF7B2CBF)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: controller.isLoading.value
                            ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF7B2CBF),
                          ),
                        )
                            : Text(
                          'Deposit Wallet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7B2CBF),
                          ),
                        ),
                      )),
                    ),

                    // Send OTP Button
                    Container(
                      width: double.infinity,
                      child: Obx(() => ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.sendOTP,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF7B2CBF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: controller.isLoading.value
                            ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          'Send OTP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      )),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
        fontWeight: FontWeight.w400,
      ),
    );
  }

}


class ExampleNavigationScreen extends StatelessWidget {
  const ExampleNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Get.to(() => WalletScreen()),
          child: Text('Open Wallet'),
        ),
      ),
    );
  }
}