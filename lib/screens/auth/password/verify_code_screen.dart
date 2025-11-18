import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/routes/app_pages.dart';
import 'package:pipze/services/language_service.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;

  const VerifyCodeScreen({super.key, required this.email});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());

  bool _isFormValid = false;
  String _otpCode = '';
  final LanguageService languageService = Get.find<LanguageService>();

  @override
  void initState() {
    super.initState();
    _addListeners();
    _validateForm();
  }

  void _addListeners() {
    for (int i = 0; i < 4; i++) {
      _controllers[i].addListener(_validateForm);
    }
  }

  void _validateForm() {
    setState(() {
      _otpCode = _controllers.map((controller) => controller.text).join();
      _isFormValid = _otpCode.length == 4;
    });
  }

  void _onCodeChanged(String value, int index) {
    if (value.length == 1 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _verifyCode() {
    if (_isFormValid) {
      Get.toNamed(
        AppPages.CREATE_NEW_PASSWORD,
        arguments: {'email': widget.email, 'otp': _otpCode},
      );
    }
  }

  void _resendCode() {
    // TODO: Implement resend OTP logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(languageService.tr('verify_code_otp_resent')),
        backgroundColor: AppColors.primary,
      ),
    );
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
        child: SingleChildScrollView(
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
      ),
    );
    ;
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
      children: List.generate(4, (index) {
        return SizedBox(
          width: 57.w,
          height: 46.h,
          child: TextField(
            cursorColor: AppColors.primary,
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            onChanged: (value) => _onCodeChanged(value, index),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              counterText: "",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: 13,
                horizontal: 14,
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
      child: ElevatedButton(
        onPressed: _isFormValid ? _verifyCode : null,
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
