import 'package:crm_app/flavor_config.dart';
import 'package:crm_app/widgets/brand_logo.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/screens/auth/getstart/login_screen.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/middleware/auth_screen_guard.dart';
import 'package:crm_app/utils/trl_helper.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAndRedirectIfLoggedIn(screenName: 'ForgotPasswordScreen');
    });
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        maintainBottomViewPadding: true,
        child: Stack(
          children: [
            Column(
              children: [
                        Padding(
                          padding:  EdgeInsets.only(top:24.h,left: 24.0),
                          child: Align(alignment: Alignment.topLeft,child: _buildHeader()),
                        ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // SizedBox(height: 16.h),
                                  Center(
                                    child: BrandLogo(
                                      source: FlavorConfig.effectiveLogo,
                                      color: FlavorConfig.isONSA() &&
                                              !FlavorConfig.hasRemoteLogo
                                          ? AppColors.primary
                                          : null,
                                      height: 100.h,
                                      width: 120.w,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(top: 70.h),
                                    child: Text(
                                      languageService.tr("forgot_password_title"),
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
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
     
                                  
                                  SizedBox(height: 35.h),
                                  Obx(() {
                                    final isLoading = authController.isLoading;
                                    return ElevatedButton(
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
                                        minimumSize:
                                            Size(double.infinity, 40.h),
                                        backgroundColor: AppColors.primary,
                                        disabledBackgroundColor: AppColors.surface,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Text(
                                        languageService.tr("forgot_password_send_otp"),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: _isFormValid ? AppColors.whiteColor : AppColors.textGrey,
                                        ),
                                      ),
                                    );
                                  }),
                                  SizedBox(height: 150.h),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Center(
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
                  ),
                ),
              ],
            ),
            Obx(
              () => authController.isLoading
                  ? Center(
                      child: CommonLoadingWidget(isFullScreen: true),
                    )
                  : const SizedBox.shrink(),
            ),
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
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
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
              color: _isFormValid ? AppColors.whiteColor : AppColors.textGrey,
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
