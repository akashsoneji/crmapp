import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../constants/color.dart';

class CongratulationsDialog extends StatelessWidget {
  final String accountNumber;
  final String serverName;

  const CongratulationsDialog({
    Key? key,
    required this.accountNumber,
    required this.serverName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        margin: EdgeInsets.all(20),
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Column(
          children: [
            // Main Content - Centered
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Congratulations Header
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Congratulations!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.2,
                            ),
                            Align(
                              alignment: Alignment.topLeft,
                              child: GestureDetector(
                                onTap: () {
                                  // Close dialog and navigate to Dashboard
                                  Get.back();
                                  Get.until((route) => route.isFirst);
                                },
                                child: Container(
                                  width: 23,
                                  height: 23,
                                  decoration: BoxDecoration(
                                    color: Color(0xffA1A1A1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: AppColors.whiteColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'You have successfully Created trading account',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.icongrey,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ],
                    ),

                    SizedBox(height: 40),

                    // Account Information
                    Row(
                      children: [
                        // Account Number
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Account Number',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Text(
                                    accountNumber,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(
                                        ClipboardData(text: accountNumber),
                                      );
                                      Get.snackbar(
                                        'Copied!',
                                        'Account number copied to clipboard',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: AppColors.primary,
                                        colorText: Colors.white,
                                      );
                                    },
                                    child: Icon(
                                      Icons.copy,
                                      color: Colors.grey[600],
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Server Name',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Text(
                                    'Meta-Right',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Make Deposit Button
                    GestureDetector(
                      onTap: () {
                        // Navigate to Wallet screen
                        Get.back(); // Close dialog
                        Get.toNamed('/wallet');
                      },
                      child: Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Make Deposit',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 32),

                    // Information Text
                    Text(
                      'Please remember your password. And also note that your real Account ID & Password has been sent to your email ID, you can always change your password in Account setting reset',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.icongrey,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 24),

                    // See Account List Link
                    GestureDetector(
                      onTap: () {
                        // Navigate to Dashboard (account list)
                        Get.back(); // Close dialog
                        Get.until((route) => route.isFirst);
                      },
                      child: Text(
                        'See account list',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
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
}
