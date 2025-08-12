import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:pipze/controllers/dashboard_controller.dart';

import '../../controllers/create_trading_account_controller.dart';

class CreateTradingAccountScreen extends StatelessWidget {
  final String accountType;
  late final CreateTradingAccountController controller;

  CreateTradingAccountScreen({Key? key, required this.accountType}) : super(key: key) {
    controller = Get.put(CreateTradingAccountController());
    controller.setAccountType(accountType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Create Open Account',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Select Account
                  _buildFieldLabel('Select Account'),
                  SizedBox(height: 8),
                  Obx(() => Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.selectedAccountType.value,
                        isExpanded: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey[600],
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        items: controller.accountOptions.map((String account) {
                          return DropdownMenuItem<String>(
                            value: account,
                            child: Text(account),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            controller.selectAccountType(newValue);
                          }
                        },
                      ),
                    ),
                  )),

                  SizedBox(height: 24),

                  // Deposit Amount
                  _buildFieldLabel('Deposit Amount'),
                  SizedBox(height: 8),
                  TextField(
                    controller: controller.depositAmountController,
                    onChanged: controller.updateDepositAmount,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: '500.00',
                      hintStyle: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: Colors.white,
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

                  SizedBox(height: 24),

                  // Pipze Trading Password
                  _buildFieldLabel('Pipze Trading Password'),
                  SizedBox(height: 8),
                  Obx(() => TextField(
                    controller: controller.tradingPasswordController,
                    onChanged: controller.updateTradingPassword,
                    obscureText: !controller.showTradingPassword.value,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'xxxxxxxxx',
                      hintStyle: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: Colors.white,
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
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.showTradingPassword.value
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey[600],
                        ),
                        onPressed: controller.toggleTradingPasswordVisibility,
                      ),
                    ),
                  )),

                  SizedBox(height: 24),

                  // Pipze Investor Password
                  _buildFieldLabel('Pipze Investor Password'),
                  SizedBox(height: 8),
                  Obx(() => TextField(
                    controller: controller.investorPasswordController,
                    onChanged: controller.updateInvestorPassword,
                    obscureText: !controller.showInvestorPassword.value,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'xxxxxxxxx',
                      hintStyle: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: Colors.white,
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
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.showInvestorPassword.value
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey[600],
                        ),
                        onPressed: controller.toggleInvestorPasswordVisibility,
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),

          // Create Account Button
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            child: Obx(() => ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : controller.createAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7B2CBF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
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
                  : Obx(() => Text(
                'Open ${controller.accountType.value} Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              )),
            )),
          ),
        ],
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

// Update the DashboardController to navigate to this screen
// Add these methods to your existing DashboardController:

// extension DashboardControllerExtension on DashboardController {
//   void openRealAccount() {
//     Get.back(); // Close bottom sheet
//     Get.to(() => CreateOpenAccountScreen(accountType: 'Real'));
//   }
//
//   void openDemoAccount() {
//     Get.back(); // Close bottom sheet
//     Get.to(() => CreateOpenAccountScreen(accountType: 'Demo'));
//   }
// }