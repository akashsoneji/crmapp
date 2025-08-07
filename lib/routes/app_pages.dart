import 'package:get/get.dart';
import '../screens/auth/splash/splash_screen.dart';
import '../screens/auth/getstart/get_started_screen.dart';
import '../screens/auth/getstart/login_screen.dart';
import '../screens/auth/register/create_account_screen.dart';
import '../screens/auth/register/legal_documents_screen.dart';
import '../screens/auth/register/privacy_policy_screen.dart';
import '../screens/auth/register/account_created_screen.dart';
import '../screens/auth/password/forgot_password_screen.dart';
import '../screens/auth/password/verify_code_screen.dart';
import '../screens/auth/password/create_new_password_screen.dart';
import '../screens/home/trading_main_screen.dart';
import '../screens/settings/language_selector_screen.dart';
import '../screens/settings/account_management_screen.dart';
import '../bindings/splash_binding.dart';
import '../bindings/auth_binding.dart';
import '../bindings/account_binding.dart';
import '../bindings/trading_binding.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const SPLASH = _Paths.SPLASH;
  static const GET_STARTED = _Paths.GET_STARTED;
  static const LOGIN = _Paths.LOGIN;
  static const CREATE_ACCOUNT = _Paths.CREATE_ACCOUNT;
  static const LEGAL_DOCUMENTS = _Paths.LEGAL_DOCUMENTS;
  static const PRIVACY_POLICY = _Paths.PRIVACY_POLICY;
  static const ACCOUNT_CREATED = _Paths.ACCOUNT_CREATED;
  static const FORGOT_PASSWORD = _Paths.FORGOT_PASSWORD;
  static const VERIFY_CODE = _Paths.VERIFY_CODE;
  static const CREATE_NEW_PASSWORD = _Paths.CREATE_NEW_PASSWORD;
  static const TRADING = _Paths.TRADING;
  static const TOAST_DEMO = _Paths.TOAST_DEMO;
  static const LANGUAGE_SELECTOR = _Paths.LANGUAGE_SELECTOR;
  static const ACCOUNT_MANAGEMENT = _Paths.ACCOUNT_MANAGEMENT;

  static final routes = [
    GetPage(
      name: _Paths.SPLASH,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage(name: _Paths.GET_STARTED, page: () => GetStartedScreen()),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.CREATE_ACCOUNT,
      page: () => const CreateAccountScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.LEGAL_DOCUMENTS,
      page: () => const LegalDocumentsScreen(registrationData: {}),
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.PRIVACY_POLICY,
      page: () => const PrivacyPolicyScreen(),
    ),
    GetPage(name: _Paths.ACCOUNT_CREATED, page: () => AccountCreatedScreen()),
    GetPage(
      name: _Paths.FORGOT_PASSWORD,
      page: () => const ForgotPasswordScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.VERIFY_CODE,
      page: () => VerifyCodeScreen(email: Get.arguments ?? ''),
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.CREATE_NEW_PASSWORD,
      page: () => const CreateNewPasswordScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.TRADING,
      page: () => const TradingMainScreen(),
      binding: TradingBinding(),
    ),
    GetPage(
      name: _Paths.LANGUAGE_SELECTOR,
      page: () => const LanguageSelectorScreen(),
    ),
    GetPage(
      name: _Paths.ACCOUNT_MANAGEMENT,
      page: () => const AccountManagementScreen(),
      binding: AccountBinding(),
    ),
  ];
}
