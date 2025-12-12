import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pipze/screens/home/more/finance/payment_methods_screen.dart';
import '../constants/color.dart';
import '../screens/home/more/finance/deposit_screen.dart';

class CongratulationsDialog extends StatelessWidget {
  final String accountNumber;
  final String serverName;
  final String? accountType;
  final String? leverage;

  const CongratulationsDialog({
    Key? key,
    required this.accountNumber,
    required this.serverName,
    this.accountType,
    this.leverage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.r),
          color: Colors.white,
        ),
        child: Column(
          children: [
            // Main Content - Centered
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 0),
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
                                fontSize: 16.sp,
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

                    SizedBox(height: 16),

                    // Account Information
                    Padding(
                      padding: EdgeInsets.only(left: 10.w),
                      child: Row(
                        children: [
                          // Account Number
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Account Number',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        accountNumber,
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: 4),
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

                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Server Name',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Row(
                                  children: [
                                    Text(
                                      serverName,
                                      style: TextStyle(
                                        fontSize: 16.sp,
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
                    ),

                    // Additional Account Details
                    SizedBox(height: 10.h),

                    // Make Deposit Button
                    SizedBox(
                      width: double.infinity,
                      height: 44.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        onPressed: () {
                          // Close dialog first
                          Get.back();
                          // Pop back to Dashboard (first route) to clear any intermediate screens
                          // This ensures the dialog is removed from navigation stack
                          Get.until((route) => route.isFirst);
                          // Navigate to PaymentMethodsScreen after a short delay
                          // This ensures Dashboard is the base route
                          Future.delayed(Duration(milliseconds: 300), () {
                            print(
                              'accountNumber wehn we make deposit plese : $accountNumber',
                            );
                            // Check if account is demo, navigate to DepositScreen
                            // Otherwise navigate to PaymentMethodsScreen
                            if (accountType?.toLowerCase() == 'demo') {
                              Get.to(
                                () =>
                                    DepositScreen(accountNumber: accountNumber),
                              );
                            } else {
                              Get.to(
                                () => PaymentMethodsScreen(
                                  accountNumber: accountNumber,
                                ),
                              );
                            }
                          });
                        },
                        child: Text('Make Deposit'),
                      ),
                    ),

                    SizedBox(height: 14.h),

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

                    SizedBox(height: 16),

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
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
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
