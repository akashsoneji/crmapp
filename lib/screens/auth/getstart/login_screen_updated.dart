import 'package:crm_app/core/services/language_service.dart';
import 'package:crm_app/core/services/toast_service.dart';
import 'package:crm_app/core/widgets/rtl_components.dart';
import 'package:crm_app/core/widgets/social_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
 import '../../../constants/color.dart';
import '../../../constants/text_styles.dart';
 import '../../../controllers/auth_controller.dart';
import 'package:crm_app/core/routes/app_pages.dart';
 
/// Updated Login Screen using RTL Components
class LoginScreenUpdated extends StatefulWidget {
  const LoginScreenUpdated({super.key});

  @override
  State<LoginScreenUpdated> createState() => _LoginScreenUpdatedState();
}

class _LoginScreenUpdatedState extends State<LoginScreenUpdated> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthController authController = Get.find<AuthController>();
  final LanguageService languageService = Get.find<LanguageService>();

  bool obscureText = true;
  bool isEmailValid = false;
  bool isPasswordValid = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool _validateEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _validatePassword(String password) {
    return password.length >= 6;
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      authController.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
    }
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 60.h),

                // Header
                Text(
                  languageService.tr("login_welcome_back"),
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 40.h),

                // Email Field
                RTLComponents.textField(
                  controller: emailController,
                  labelText: languageService.tr("register_email"),
                  hintText: languageService.tr("register_email"),
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icon(Icons.email, color: AppColors.primary),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return languageService.tr("validation_email_required");
                    }
                    if (!_validateEmail(value)) {
                      return languageService.tr("validation_email_invalid");
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      isEmailValid = _validateEmail(value);
                    });
                  },
                ),
                SizedBox(height: 16.h),

                // Password Field
                RTLComponents.textField(
                  controller: passwordController,
                  labelText: languageService.tr("register_password"),
                  hintText: languageService.tr("register_password"),
                  obscureText: obscureText,
                  prefixIcon: Icon(Icons.lock, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textGrey,
                    ),
                    onPressed: () {
                      setState(() {
                        obscureText = !obscureText;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return languageService.tr("validation_password_required");
                    }
                    if (!_validatePassword(value)) {
                      return languageService.tr(
                        "validation_password_min_length",
                      );
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      isPasswordValid = _validatePassword(value);
                    });
                  },
                ),

                SizedBox(height: 5.h),

                // Forgot Password
                Align(
                  alignment:
                      languageService.isRTL()
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                  child: RTLComponents.textButton(
                    text: languageService.tr("login_forgot_password"),
                    onPressed: () {
                      Get.toNamed(AppPages.FORGOT_PASSWORD);
                    },
                    height: 40,
                    padding: EdgeInsets.zero,
                  ),
                ),

                SizedBox(height: 35.h),

                // Login Button
                Obx(() {
                  final isLoading = authController.isLoading;
                  return RTLComponents.elevatedButton(
                    text: languageService.tr("login_button"),
                    onPressed: isLoading ? null : _handleLogin,
                    width: double.infinity,
                    isLoading: isLoading,
                  );
                }),

                SizedBox(height: 32.h),

                // Divider
                RTLComponents.row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        languageService.tr("login_or_with"),
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),

                SizedBox(height: 24.h),

                // Social Buttons
                RTLComponents.column(
                  children: [
                    SocialButton(
                      label: languageService.tr('login_google'),
                      icon: 'assets/svg/GoogleLogo.svg',
                      onPressed: () {
                        ToastService.showInfo(
                          context,
                          languageService.tr('login_google_coming_soon'),
                          duration: const Duration(seconds: 2),
                        );
                      },
                    ),
                    SocialButton(
                      label: languageService.tr('login_apple'),
                      icon: 'assets/svg/apple_logo.svg',
                      onPressed: () {
                        ToastService.showInfo(
                          context,
                          languageService.tr('login_apple_coming_soon'),
                          duration: const Duration(seconds: 2),
                        );
                      },
                    ),
                  ],
                  spacing: 12,
                ),

                const Spacer(),

                // Register Link
                Center(
                  child: RTLComponents.textButton(
                    text:
                        "${languageService.tr("login_no_account_login")} ${languageService.tr("login_register")}",
                    onPressed: () {
                      Get.toNamed(AppPages.CREATE_ACCOUNT);
                    },
                    height: 40,
                    padding: EdgeInsets.zero,
                    textColor: AppColors.textGrey,
                  ),
                ),

                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
