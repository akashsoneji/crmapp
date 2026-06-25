import 'dart:convert';

import 'package:crm_app/utils/trl_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/auth_controller.dart';
import 'package:crm_app/routes/app_pages.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/services/secure_storage_service.dart';
import 'package:crm_app/services/biometric_service.dart';
import 'package:crm_app/services/app_lock_service.dart';
import 'package:crm_app/utils/agreement_launcher.dart';

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
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
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
            activeColor: AppColors.whiteColor,
            checkColor: AppColors.primary,
            side: BorderSide(color: AppColors.border),
            value: _isAgreementChecked,
            onChanged: (value) {
              setState(() {
                _isAgreementChecked = value ?? false;
                _validateForm();
              });
            },
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
          onTap: AgreementLauncher.openTerms,
        ),
        SizedBox(height: 5.h),
        _buildDocumentItem(
          languageService.tr("legal_documents_privacy_policy"),
          onTap: AgreementLauncher.openPrivacy,
        ),
      ],
    );
  }

  Widget _buildDocumentItem(String title, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
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
      child: RTLHelper.rtlButton(
        height: 46.h,
        text: languageService.tr("common_submit"),
        onPressed: _isFormValid ? _submitDocuments : null,
        backgroundColor: AppColors.primary,
        foregroundColor: _isFormValid ? AppColors.whiteColor : AppColors.textGrey,
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
      } else {
        // Registration failed - error is already shown by controller
        // but we can also show it here if needed
        final errorMessage =
            authController.errorMessage.isNotEmpty
                ? authController.errorMessage
                : 'Registration failed. Please check your information and try again.';
        _showError(errorMessage);
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

  Future<void> _resendOTP(BuildContext modalContext) async {
    try {
      // Create a copy of registration data without OTP and with register_event_type = "register"
      final resendData = Map<String, dynamic>.from(widget.registrationData);
      resendData.remove('otp'); // Remove OTP field if it exists
      resendData['register_event_type'] =
          'register'; // Set to register to resend OTP

      // Show loading
      _showLoadingDialog('Resending OTP...');

      // Call register API to resend OTP
      final registrationSuccess = await authController.register(
        data: resendData,
      );

      _hideLoadingDialog();

      if (registrationSuccess) {
        // Clear OTP fields in modal
        _clearOtpFields?.call();

        // Show success message
        CustomToastService.showSuccess(
          title: 'Success',
          message: 'OTP resent successfully. Please check your email.',
        );
      } else {
        // Show error if resend failed
        final errorMessage =
            authController.errorMessage.isNotEmpty
                ? authController.errorMessage
                : 'Failed to resend OTP. Please try again.';
        _showError(errorMessage);
      }
    } catch (e) {
      _hideLoadingDialog();
      _showError('Failed to resend OTP: $e');
    }
  }

  // ... existing code ...

  void Function()? _clearOtpFields;

  void _showOtpVerificationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // Prevent accidental dismissal
      enableDrag: false, // Prevent dragging down
      builder:
          (context) => OtpModal(
            email: widget.registrationData['email'],
            isEmailVerification: true,
            otpLength: 6,
            onModalReady: (clearFields) {
              // Store the clearFields function for later use
              _clearOtpFields = clearFields;
            },
            onOtpSubmitted: (otp) async {
              // Handle OTP verification
              await _verifyOtpAndCompleteRegistration(otp, context);
            },
            onResendOtp: () async {
              // Handle resending OTP - don't close modal, just resend
              await _resendOTP(context);
            },
          ),
    );
  }

  // ... existing code ...
  Future<void> _verifyOtpAndCompleteRegistration(
    String otp,
    BuildContext modalContext,
  ) async {
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
        Navigator.of(modalContext).pop();

        await _maybeEnableBiometricAfterRegistration();

        // Navigate to next screen
        Get.toNamed(AppPages.ACCOUNT_CREATED);

        // Show success message
        // CustomToastService.showSuccess(
        //   title: 'Success',
        //   message: 'Account created successfully!',
        // );
      } else {
        // OTP verification failed - keep modal open and show error
        // The error message is already shown by auth_controller
        // Clear OTP fields so user can try again
        _clearOtpFields?.call();

        final errorMessage =
            authController.errorMessage.isNotEmpty
                ? authController.errorMessage
                : 'OTP verification failed. Please try again.';
        _showError(errorMessage);
      }
    } catch (e) {
      _hideLoadingDialog();
      _showError('OTP verification failed: $e');
      // Modal stays open on error
    }
  }

  Future<void> _maybeEnableBiometricAfterRegistration() async {
    final enabled = widget.registrationData['enable_biometric'] == true;
    if (!enabled) {
      await SecureStorageService.setBiometricEnabled(false);
      return;
    }

    final bio = BiometricService.instance;
    final supported = await bio.isDeviceSupported();
    final enrolled = await bio.isEnrolled();
    if (!supported || !enrolled) {
      await SecureStorageService.setBiometricEnabled(false);
      await _showBiometricNotEnrolledDialog();
      return;
    }

    final ok = await bio.authenticate(
      reason: languageService.tr('biometric_auth_reason_enable'),
    );
    if (!ok) {
      await SecureStorageService.setBiometricEnabled(false);
      return;
    }

    try {
      if (Get.isRegistered<AppLockService>()) {
        Get.find<AppLockService>().markJustAuthenticated();
      }
    } catch (_) {}

    final userIdentifier = (widget.registrationData['email'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    await SecureStorageService.setBiometricEnabled(
      true,
      userIdentifier: userIdentifier.isEmpty ? null : userIdentifier,
    );
  }

  Future<void> _showBiometricNotEnrolledDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text(
            languageService.tr('biometric_not_enabled_title'),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            languageService.tr('biometric_not_enabled_message'),
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                languageService.tr('common_close'),
                style: TextStyle(color: AppColors.primary),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await BiometricService.instance.openDeviceSecuritySettings();
              },
              child: Text(
                languageService.tr('biometric_open_settings'),
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
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
    CommonLoadingWidget(isFullScreen: true);
  }

  void _hideLoadingDialog() {
    if (Get.isDialogOpen == true) {
      Get.back(closeOverlays: true);
    }
  }

  void _showError(String message) {
    CustomToastService.showError(title: 'Error', message: message);
  }
}
