import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/controllers/auth_controller.dart';
import 'package:pipze/routes/app_pages.dart';
import 'package:pipze/services/language_service.dart';

import '../../../widgets/common_loading_widget.dart';
import '../../../widgets/custom_toast.dart';
import '../../../widgets/otp_modal.dart';

class LegalDocumentsScreen extends StatefulWidget {
  final Map<String, dynamic> registrationData;

  const LegalDocumentsScreen({super.key, required this.registrationData});

  @override
  State<LegalDocumentsScreen> createState() => _LegalDocumentsScreenState();
}

class _LegalDocumentsScreenState extends State<LegalDocumentsScreen> {
  bool _isAgreementChecked = false;
  bool _isFormValid = false;
  final LanguageService languageService = Get.find<LanguageService>();
  AuthController authController = Get.find<AuthController>();
  @override
  void initState() {
    super.initState();

    print("object json is ${jsonEncode(widget.registrationData)}");
    _validateForm();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _isAgreementChecked;
    });
  }

  void _submitDocuments() {
    if (_isFormValid) {
      // Make registration API call
      _createAccount();
      // print("object json is ${jsonEncode(widget.registrationData)}");
      // print(
      //   "object json is ${(jsonEncode(widget.registrationData).runtimeType)}",
      // );
      // authController.register(data: widget.registrationData);
      // Get.toNamed(AppPages.ACCOUNT_CREATED);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 24.h),
                  Text(
                    languageService.tr("legal_documents_title"),
                    style: AppTextStyles.heading,
                  ),
                  SizedBox(height: 24.h),
                  _buildAgreementCheckbox(),
                  SizedBox(height: 35.h),
                  _buildDocumentsList(),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
            Spacer(),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildSubmitButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Row(
        children: [
          Container(
            height: 40.h,
            width: 40.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              iconSize: 17.h,
              padding: EdgeInsets.only(left: 5.w),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _progressBar(active: true),
                SizedBox(width: 8.w),
                _progressBar(active: true),
                SizedBox(width: 8.w),
                _progressBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBar({bool active = false}) {
    return Container(
      width: 60.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.border,
      ),
    );
  }

  Widget _buildAgreementCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: 25.w,
          height: 25.h,
          child: Checkbox(
            value: _isAgreementChecked,
            onChanged: (value) {
              setState(() {
                _isAgreementChecked = value ?? false;
                _validateForm();
              });
            },
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 3.h, left: 5.h),
            child: Text(
              languageService.tr("legal_documents_subtitle"),
              style: TextStyle(
                fontSize: 16,
                height: 22 / 16,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        _buildDocumentItem(
          languageService.tr("legal_documents_customer_agreement"),
        ),
        SizedBox(height: 5.h),
        _buildDocumentItem(
          languageService.tr("legal_documents_privacy_policy"),
        ),
      ],
    );
  }

  Widget _buildDocumentItem(String title) {
    return InkWell(
      onTap: () {
        if (title == "Privacy Policy") {
          Navigator.pushNamed(context, '/privacy-policy');
        } else {
          Navigator.pushNamed(context, '/privacy-policy');
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 8.w),
        child: Row(
          children: [
            Container(
              width: 4.w,
              height: 4.w,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.link.copyWith(
                  decoration: TextDecoration.none,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isFormValid ? _submitDocuments : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.border,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          languageService.tr("common_submit"),
          style: AppTextStyles.button.copyWith(
            color: _isFormValid ? Colors.white : AppColors.textGrey,
          ),
        ),
      ),
    );
  }

  // ==================== ACCOUNT CREATION FLOW ====================
  Future<void> _createAccount() async {
    try {
      // Step 1: Register user
      final registrationSuccess = await authController.register(
        data: widget.registrationData,
      );

      if (registrationSuccess) {
        // Step 2: Send OTP for verification
        await _sendOTPForVerification();
      }
    } catch (e) {
      _hideLoadingDialog();
      _showError('Registration failed: $e');
    }
  }

  Future<void> _sendOTPForVerification() async {
    try {
      _showOtpVerificationBottomSheet();
    } catch (e) {
      _hideLoadingDialog();
      _showError('Failed to send OTP: $e');
    }
  }

  // ... existing code ...

  void _showOtpVerificationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true, // Prevent accidental dismissal
      enableDrag: false, // Prevent dragging down
      builder:
          (context) => OtpModal(
            email: widget.registrationData['email'],
            isEmailVerification: true,
            otpLength: 5,
            onOtpSubmitted: (otp) async {
              // Handle OTP verification
              await _verifyOtpAndCompleteRegistration(otp);
            },
            onResendOtp: () async {
              // Handle resending OTP
              Navigator.of(context).pop();
              await _createAccount();
            },
          ),
    );
  }

  // ... existing code ...
  Future<void> _verifyOtpAndCompleteRegistration(String otp) async {
    try {
      _showLoadingDialog('Verifying OTP...');
      widget.registrationData["register_event_type"] = "verifyOtp";
      widget.registrationData["otp"] = otp;

      // Step 1: Register user
      final otpVerified = await authController.registerWithOTPVerification(
        data: widget.registrationData,
      );

      _hideLoadingDialog();

      if (otpVerified) {
        // Close OTP modal
        Navigator.of(context).pop();

        // Navigate to next screen
        Get.toNamed(AppPages.ACCOUNT_CREATED);
      }
      // Show success message
      CustomToastService.showSuccess(
        title: 'Success',
        message: 'Account created successfully!',
      );
      // }
    } catch (e) {
      _hideLoadingDialog();
      _showError('OTP verification failed: $e');
    }
  }

  // ... existing code ...
  // Future<void> _verifyOtpAndCompleteRegistration(String otp) async {
  //   try {
  //     _showLoadingDialog('Verifying OTP...');
  //
  //     final otpVerified = await authController.verifyOTP(
  //       email: widget.registrationData['email'],
  //       otp: otp,
  //     );
  //
  //     _hideLoadingDialog();
  //
  //     if (otpVerified) {
  //       // Close OTP modal
  //       Navigator.of(context).pop();
  //     }
  //     // Show success message
  //     CustomToastService.showSuccess(
  //       title: 'Success',
  //       message: 'Account created successfully!',
  //     );
  //
  //     // Navigate to next screen
  //     Get.toNamed(AppPages.ACCOUNT_CREATED);
  //     // }
  //   } catch (e) {
  //     _hideLoadingDialog();
  //     _showError('OTP verification failed: $e');
  //   }
  // }

  // ==================== UI HELPER METHODS ====================
  void _showLoadingDialog(String message) {
    OverlayLoadingWidget();
  }

  void _hideLoadingDialog() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  void _showError(String message) {
    CustomToastService.showError(title: 'Error', message: message);
  }
}
