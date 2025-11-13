import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/services/language_service.dart';
import 'package:pipze/services/toast_service.dart';
import 'package:pipze/utils/trl_helper.dart';
import 'package:pipze/widgets/common_loading_widget.dart';
import '../../../widgets/AppTextField.dart';
import '../../../widgets/social_button.dart';
import '../../../controllers/auth_controller.dart';
import '../../../routes/app_pages.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool obscureText = true;

  // Get the AuthController
  final AuthController authController = Get.find<AuthController>();

  // Get the LanguageService
  final LanguageService languageService = Get.find<LanguageService>();

  // Validation states
  bool isEmailValid = false;
  bool isPasswordValid = false;

  // Validation methods
  bool _validateEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  bool _validatePassword(String password) {
    return password.length >= 6;
  }

  void _handleLogin() {
    print("object is click on ${authController.isLoading}");
    if (_formKey.currentState!.validate()) {
      authController.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        maintainBottomViewPadding: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Stack(
                    children: [
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 60.h),
                            Text(
                              languageService.tr("welcome_title"),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 40.h),

                            RTLHelper.rtlTextField(
                              // child: AppTextField(
                              controller: emailController,
                              labelText: languageService.tr("register_email"),
                              hintText: languageService.tr("register_email"),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return languageService.tr(
                                    "validation_email_required",
                                  );
                                }
                                if (!_validateEmail(value)) {
                                  return languageService.tr(
                                    "validation_email_invalid",
                                  );
                                }
                                return null;
                              },
                              onChanged: (value) {
                                setState(() {
                                  isEmailValid = _validateEmail(value);
                                });
                              },
                              // ),
                            ),
                            SizedBox(height: 16.h),

                            RTLHelper.rtlTextField(
                              // child: AppTextField(
                              controller: passwordController,
                              // label: languageService.tr("login_password"),
                              hintText: languageService.tr("register_password"),
                              obscureText: obscureText,
                              labelText: languageService.tr(
                                "register_password",
                              ),
                              suffixIcon: IconButton(
                                icon: SvgPicture.asset(
                                  obscureText
                                      ? "assets/svg/eye-slash.svg"
                                      : "assets/svg/eye_icon.svg",
                                ),
                                // icon: Icon(
                                //   obscureText
                                //       ? Icons.visibility
                                //       : Icons.visibility_off,
                                //   color: AppColors.textGrey,
                                // ),
                                onPressed: () {
                                  setState(() {
                                    obscureText = !obscureText;
                                  });
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return languageService.tr(
                                    "validation_password_required",
                                  );
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
                              // ),
                            ),

                            SizedBox(height: 5.h),
                            Align(
                              alignment:
                                  languageService.isRTL()
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Get.toNamed(AppPages.FORGOT_PASSWORD);
                                },
                                child: Text(
                                  languageService.tr("login_forgot_password"),
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 35.h),
                            Obx(() {
                              final isLoading = authController.isLoading;
                              return ElevatedButton(
                                onPressed: isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  // padding: EdgeInsets.symmetric(vertical: 12.h),
                                  minimumSize: Size(double.infinity, 40.h),
                                  // Removed maximumSize to avoid constraint conflicts
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  languageService.tr("login_button"),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }),

                            // SizedBox(height: 32.h),
                            // Row(
                            //   children: [
                            //     const Expanded(
                            //       child: Divider(color: AppColors.border),
                            //     ),
                            //     Padding(
                            //       padding: const EdgeInsets.symmetric(
                            //         horizontal: 16,
                            //       ),
                            //       child: Text(
                            //         languageService.tr("login_or_with"),
                            //         style: const TextStyle(
                            //           color: AppColors.textGrey,
                            //           fontSize: 14,
                            //         ),
                            //       ),
                            //     ),
                            //     const Expanded(
                            //       child: Divider(color: AppColors.border),
                            //     ),
                            //   ],
                            // ),
                            // SizedBox(height: 24.h),
                            //
                            // // SocialButton(
                            // //   label: languageService.tr('login_google'),
                            // //   icon: 'assets/svg/GoogleLogo.svg',
                            // //   onPressed: () {
                            // //     ToastService.showInfo(
                            // //       context,
                            // //       languageService.tr(
                            // //         'login_google_coming_soon',
                            // //       ),
                            // //       duration: const Duration(seconds: 2),
                            // //     );
                            // //   },
                            // // ),
                            // // const SizedBox(height: 12),
                            // // SocialButton(
                            // //   label: languageService.tr('login_apple'),
                            // //   icon: 'assets/svg/apple_logo.svg',
                            // //   onPressed: () {
                            // //     ToastService.showInfo(
                            // //       context,
                            // //       languageService.tr('login_apple_coming_soon'),
                            // //       duration: const Duration(seconds: 2),
                            // //     );
                            // //   },
                            // // ),
                            const Spacer(),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Get.toNamed(AppPages.CREATE_ACCOUNT);
                                },
                                child: Text.rich(
                                  TextSpan(
                                    text:
                                        "${languageService.tr("login_no_account_login")} ",
                                    style: const TextStyle(
                                      color: AppColors.textGrey,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: languageService.tr(
                                          "login_register",
                                        ),
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20.h),
                          ],
                        ),
                      ),
                      Obx(
                        () =>
                            authController.isLoading
                                ? Center(
                                  child: CommonLoadingWidget(
                                    isFullScreen: true,
                                  ),
                                )
                                : SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
