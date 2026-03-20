import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../constants/color.dart';
import '../../controllers/dashboard_controller.dart';

class OpenAccountScreen extends StatefulWidget {
  const OpenAccountScreen({Key? key}) : super(key: key);

  @override
  State<OpenAccountScreen> createState() => _OpenAccountScreenState();
}

class _OpenAccountScreenState extends State<OpenAccountScreen> {
  String? selectedAccountType; // null means no selection
  final DashboardController controller = Get.find<DashboardController>();

  void _selectAccountType(String accountType) {
    setState(() {
      selectedAccountType = accountType;
    });
  }

  void _handleNext() {
    if (selectedAccountType == null) return;

    // Navigate to Create Trading Account screen
    Get.toNamed('/create-trading-account', arguments: selectedAccountType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(closeOverlays: true),
          icon: SvgPicture.asset('assets/svg/trade/arro_back.svg'),
        ),
        title: Text(
          'Open Account',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Subtitle
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Text(
              'Open a trading account to get superior trading conditions any strategy',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ),

          // Account Type Selection Row
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                // Real Account Button
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectAccountType('real'),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color:
                            selectedAccountType == 'real'
                                ? AppColors.primary.withOpacity(0.1)
                                : AppColors.whiteColor,
                        border: Border.all(
                          color:
                              selectedAccountType == 'real'
                                  ? AppColors.primary
                                  : Colors.grey[300]!,
                          width: selectedAccountType == 'real' ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Purple Brain Icon
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(),
                            child: SvgPicture.asset(
                              "assets/svg/deshboard/wallet-money.svg",
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Real Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color:
                                  selectedAccountType == 'real'
                                      ? AppColors.primary
                                      : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 16),

                // Demo Account Button
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectAccountType('demo'),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color:
                            selectedAccountType == 'demo'
                                ? AppColors.primary.withOpacity(0.1)
                                : AppColors.whiteColor,
                        border: Border.all(
                          color:
                              selectedAccountType == 'demo'
                                  ? AppColors.primary
                                  : Colors.grey[300]!,
                          width: selectedAccountType == 'demo' ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Purple Brain Icon
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(),
                            child: SvgPicture.asset(
                              "assets/svg/deshboard/wallet-money.svg",
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Demo Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color:
                                  selectedAccountType == 'demo'
                                      ? AppColors.primary
                                      : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Spacer(),

          // Next Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: GestureDetector(
              onTap: selectedAccountType != null ? _handleNext : null,
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color:
                      selectedAccountType != null
                          ? AppColors.primary
                          : Colors.grey[400],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    selectedAccountType != null
                        ? 'Next'
                        : 'Select Account Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.whiteColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
