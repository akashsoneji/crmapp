import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/services/language_service.dart';
import '../../../controllers/auth_controller.dart';
import '../../../widgets/common_loading_widget.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;

  const VerifyCodeScreen({super.key, required this.email});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isFormValid = false;
  String _otpCode = '';
  final LanguageService languageService = Get.find<LanguageService>();
  final AuthController authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _addListeners();
    _validateForm();
  }

  void _addListeners() {
    for (int i = 0; i < 6; i++) {
      _controllers[i].addListener(_validateForm);
    }
  }

  void _validateForm() {
    setState(() {
      _otpCode = _controllers.map((controller) => controller.text).join();
      _isFormValid = _otpCode.length == 6;
    });
  }

  void _onCodeChanged(String value, int index) {
    if (value.length == 1) {
      // User typed a character, move to next box
      if (index < 5) {
        // Small delay to ensure smooth transition
        Future.delayed(Duration(milliseconds: 50), () {
          if (_focusNodes[index + 1].canRequestFocus) {
            _focusNodes[index + 1].requestFocus();
          }
        });
      } else {
        // Last field filled, hide keyboard
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty) {
      // User deleted/backspaced - only go back if we're not at the first box
      if (index > 0) {
        // Small delay to ensure smooth transition
        Future.delayed(Duration(milliseconds: 50), () {
          if (_focusNodes[index - 1].canRequestFocus) {
            _focusNodes[index - 1].requestFocus();
          }
        });
      }
    }
  }

  void _verifyCode() {
    if (_isFormValid) {
      authController.verifyPasswordResetOTP(email: widget.email, otp: _otpCode);
    }
  }

  void _resendCode() {
    authController.requestPasswordResetOTP(email: widget.email);
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 24.h),
                  _buildHeader(),
                  SizedBox(height: 40.h),
                  _buildTitle(),
                  _buildDescription(),
                  SizedBox(height: 40.h),
                  _buildCodeInput(),
                  SizedBox(height: 35.h),
                  _buildVerifyButton(),
                  SizedBox(height: 24.h),
                  _buildResendCode(),
                ],
              ),
            ),
            Obx(() {
              if (authController.isLoading) {
                return Center(child: CommonLoadingWidget(isFullScreen: true));
              } else {
                return const SizedBox.shrink();
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 40.h,
      width: 40.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        iconSize: 17.h,
        padding: EdgeInsets.only(left: 5.w),
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      "${languageService.tr("verify_code_description")}\t${widget.email}",
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textGrey,
        height: 22 / 14,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      languageService.tr("verify_code_title"),
      style: AppTextStyles.heading.copyWith(
        fontSize: 31.sp,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildCodeInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 50.w,
          height: 46.h,
          child: TextField(
            cursorColor: AppColors.primary,
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            onChanged: (value) => _onCodeChanged(value, index),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              height: 1.2,
            ),
            decoration: InputDecoration(
              counterText: "",
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                vertical: 13.h,
                horizontal: 14.w,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      child: Obx(
        () => ElevatedButton(
          onPressed:
              authController.isLoading || !_isFormValid ? null : _verifyCode,
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
            languageService.tr("verify_code_button"),
            style: AppTextStyles.button.copyWith(
              color: _isFormValid ? Colors.white : AppColors.textGrey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResendCode() {
    return Center(
      child: Column(
        children: [
          Text(
            languageService.tr("verify_code_didnt_receive"),
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 14.sp,
              height: 22 / 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 7.h),
          GestureDetector(
            onTap: _resendCode,
            child: Text(
              languageService.tr("verify_code_resend"),
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14.sp,
                height: 22 / 14,
                fontWeight: FontWeight.w400,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
