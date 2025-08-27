import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class OtpModal extends StatefulWidget {
  final String phoneNumber;
  final VoidCallback? onVerify;

  const OtpModal({
    Key? key,
    required this.phoneNumber,
    this.onVerify,
  }) : super(key: key);

  @override
  State<OtpModal> createState() => _OtpModalState();
}

class _OtpModalState extends State<OtpModal> {
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );

  final List<FocusNode> _otpFocusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
            'Verify Mobile Number',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),

          // Instructions
          Text(
            'Enter the code we\'ve sent to your number',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            widget.phoneNumber,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 24.h),

          // OTP Input Fields
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              return Container(
                width: 60.w,
                height: 60.h,
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
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
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
                      borderSide: BorderSide(color: const Color(0xFF5A2DD8), width: 2),
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
                backgroundColor: const Color(0xFF5A2DD8),
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
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  void _handleOtpInput(int index, String value) {
    if (value.length == 1) {
      // User typed a character, move to next box
      if (index < 3) {
        // Small delay to ensure smooth transition
        Future.delayed(Duration(milliseconds: 50), () {
          if (_otpFocusNodes[index + 1].canRequestFocus) {
            _otpFocusNodes[index + 1].requestFocus();
          }
        });
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
    if (otp.length == 4) {
      // TODO: Implement OTP verification logic
      Get.back(); // Close modal
      Get.snackbar(
        'Success',
        'OTP verified successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        'Please enter a valid 4-digit OTP',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
