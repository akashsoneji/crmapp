import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';

class OtpModal extends StatefulWidget {
  final String email;
  final String? phoneNumber;
  final VoidCallback? onVerify;
  final Function(String)? onOtpSubmitted;
  final VoidCallback? onResendOtp;
  final bool isEmailVerification;
  final int otpLength;

  const OtpModal({
    Key? key,
    this.email = '',
    this.phoneNumber,
    this.onVerify,
    this.onOtpSubmitted,
    this.onResendOtp,
    this.isEmailVerification = true,
    this.otpLength = 6, // ✅ Default is 6 - this is correct
  }) : super(key: key);

  @override
  State<OtpModal> createState() => _OtpModalState();
}

class _OtpModalState extends State<OtpModal> {
  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _otpFocusNodes;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // ✅ Creates controllers based on otpLength (6 by default)
    _otpControllers = List.generate(
      widget.otpLength,
          (index) => TextEditingController(),
    );
    _otpFocusNodes = List.generate(widget.otpLength, (index) => FocusNode());

    // Add focus listeners to handle keyboard appearance
    for (int i = 0; i < widget.otpLength; i++) {
      _otpFocusNodes[i].addListener(() {
        if (_otpFocusNodes[i].hasFocus) {
          _scrollToVisible(i);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToVisible(int index) {
    // Add a small delay to ensure the keyboard is fully visible
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        final double itemHeight = 60.h;
        final double scrollOffset =
            (index * itemHeight) - (MediaQuery.of(context).size.height * 0.3);
        if (scrollOffset > 0) {
          _scrollController.animateTo(
            scrollOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 24.h),

              // Title
              Text(
                widget.isEmailVerification
                    ? 'Verify Email'
                    : 'Verify Mobile Number',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),

              // Instructions - ✅ FIXED: Changed from "5-digit" to use dynamic otpLength
              Text(
                widget.isEmailVerification
                    ? 'Enter the ${widget.otpLength}-digit code we\'ve sent to your email'
                    : 'Enter the ${widget.otpLength}-digit code we\'ve sent to your number',
                style: TextStyle(fontSize: 14.sp, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.h),
              Text(
                widget.isEmailVerification
                    ? widget.email
                    : (widget.phoneNumber ?? ''),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),

              // OTP Input Fields - ✅ Generates fields based on otpLength (will be 6)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(widget.otpLength, (index) {
                  return Container(
                    width: 50.w,
                    height: 50.h,
                    child: TextField(
                      controller: _otpControllers[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      focusNode: _otpFocusNodes[index],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.icongrey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.icongrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        _handleOtpInput(index, value);
                      },
                      onTap: () {
                        // When user taps on a box, select all text for easy replacement
                        if (_otpControllers[index].text.isNotEmpty) {
                          _otpControllers[index].selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: _otpControllers[index].text.length,
                          );
                        }
                      },
                    ),
                  );
                }),
              ),
              SizedBox(height: 32.h),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: widget.onVerify ?? _handleVerify,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Verify',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.whiteColor,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Resend OTP Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Didn\'t receive the code? ',
                    style: TextStyle(fontSize: 14.sp, color: Colors.black54),
                  ),
                  TextButton(
                    onPressed: _handleResendOtp,
                    child: Text(
                      'Resend',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  void _handleOtpInput(int index, String value) {
    if (value.length == 1) {
      // User typed a character, move to next box
      if (index < widget.otpLength - 1) {
        // Small delay to ensure smooth transition
        Future.delayed(Duration(milliseconds: 50), () {
          if (_otpFocusNodes[index + 1].canRequestFocus) {
            _otpFocusNodes[index + 1].requestFocus();
          }
        });
      } else {
        // Last field filled, hide keyboard
        _otpFocusNodes[index].unfocus();
      }
    } else if (value.isEmpty) {
      // User deleted/backspaced - only go back if we're not at the first box
      if (index > 0) {
        // Small delay to ensure smooth transition
        Future.delayed(Duration(milliseconds: 50), () {
          if (_otpFocusNodes[index - 1].canRequestFocus) {
            _otpFocusNodes[index - 1].requestFocus();
          }
        });
      }
    }
  }

  void _handleVerify() {
    final otp = _otpControllers.map((controller) => controller.text).join();
    if (otp.length == widget.otpLength) {
      if (widget.onOtpSubmitted != null) {
        widget.onOtpSubmitted!(otp);
      } else {
        // Default behavior
        Get.back(); // Close modal
        Get.snackbar(
          'Success',
          'OTP verified successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } else {
      Get.snackbar(
        'Error',
        'Please enter a valid ${widget.otpLength}-digit OTP',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _handleResendOtp() {
    if (widget.onResendOtp != null) {
      // Use the callback provided by parent
      widget.onResendOtp!();
    } else {
      // Default behavior
      Get.snackbar(
        'Success',
        'OTP resent successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }

    // Clear the OTP input fields
    for (var controller in _otpControllers) {
      controller.clear();
    }

    // Focus on the first input field
    if (_otpFocusNodes.isNotEmpty) {
      _otpFocusNodes[0].requestFocus();
    }
  }
}