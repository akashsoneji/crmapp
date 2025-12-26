import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/screens/auth/getstart/login_screen.dart';
import 'package:pipze/services/language_service.dart';
import 'package:pipze/utils/trl_helper.dart';
import '../../../controllers/auth_controller.dart';
import '../../../widgets/common_loading_widget.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: '');
  bool _isFormValid = false;
  final AuthController authController = Get.find<AuthController>();
  final LanguageService languageService = Get.find<LanguageService>();

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _validateForm();
  }

  void _validateForm() {
    setState(() {
      _isFormValid =
          _emailController.text.isNotEmpty &&
          _emailController.text.contains('@');
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 24.h),
                        _buildHeader(),
                        SizedBox(height: 40.h),
                        _buildTitle(),
                        SizedBox(height: 40.h),
                        _buildEmailField(),
                        SizedBox(height: 35.h),
                        _buildSendOTPButton(),
                        const Spacer(),
                        _buildLoginLink(),
                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                ),
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

  Widget _buildTitle() {
    return Text(
      languageService.tr("forgot_password_title"),
      style: AppTextStyles.heading.copyWith(
        fontSize: 28.sp,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RTLHelper.rtlTextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return languageService.tr('forgot_password_enter_your_email');
            }
            if (!value.contains('@')) {
              return languageService.tr(
                "forgot_password_Please_enter_a_valid_email",
              );
            }
            return null;
          },
          labelText: languageService.tr("forgot_password_email"),
        ),
      ],
    );
  }

  Widget _buildSendOTPButton() {
    return SizedBox(
      width: double.infinity,
      child: Obx(
        () => ElevatedButton(
          onPressed:
              authController.isLoading
                  ? null
                  : _isFormValid
                  ? () {
                    if (_formKey.currentState!.validate()) {
                      authController.requestPasswordResetOTP(
                        email: _emailController.text.trim(),
                      );
                    }
                  }
                  : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.border,
            padding: EdgeInsets.symmetric(vertical: 12.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            languageService.tr("forgot_password_send_otp"),
            style: AppTextStyles.button.copyWith(
              color: _isFormValid ? Colors.white : AppColors.textGrey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: RichText(
        text: TextSpan(
          text: languageService.tr("forgot_password_remember_password"),
          style: TextStyle(color: AppColors.textGrey, fontSize: 14.sp),
          children: [
            TextSpan(
              text: languageService.tr("forgot_password_login"),
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              recognizer:
                  TapGestureRecognizer()
                    ..onTap = () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                        (route) => false,
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }
}
