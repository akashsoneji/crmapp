import 'package:crm_app/controllers/auth_controller.dart';
import 'package:crm_app/models/login_response_model.dart';
import 'package:crm_app/services/auth_service.dart';
import 'package:crm_app/services/api_service.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:typed_data';

class TestAuthService extends AuthService {
  @override
  Future<ApiResponse<LoginResponseModel>> login({
    required String email,
    required String password,
    String? fcmToken,
    String? deviceType,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> sendOTP({required String email}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> verifyOTP({
    required String email,
    required String otp,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> requestPasswordResetOTP({
    required String email,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> verifyPasswordResetOTP({
    required String email,
    required String otp,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> resetPasswordWithOTP({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> changePassword({
    required String mt5Account,
    required String newPassword,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> changeLeverage({
    required String mt5Account,
    required int leverage,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> changeUserPassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> register({
    required Map<String, dynamic> data,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<LoginResponseModel>> registerWithOTPVerification({
    required Map<String, dynamic> data,
  }) {
    throw UnimplementedError();
  }
}

/// Mocks flutter_secure_storage platform channel so services using it won't crash
/// in widget tests.
void mockSecureStorageChannel() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestWidgetsFlutterBinding.ensureInitialized();

  channel.setMockMethodCallHandler((call) async {
    // Keep storage empty by default.
    switch (call.method) {
      case 'read':
        return null;
      case 'write':
      case 'delete':
      case 'deleteAll':
        return null;
      default:
        return null;
    }
  });
}

class _TestAssetBundle extends CachingAssetBundle {
  static const _svg =
      '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"></svg>';
  static final Uint8List _pngBytes = base64Decode(
    // 1x1 transparent PNG
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO1n7uUAAAAASUVORK5CYII=',
  );

  @override
  Future<ByteData> load(String key) async {
    if (key.toLowerCase().endsWith('.svg')) {
      final bytes = Uint8List.fromList(utf8.encode(_svg));
      return ByteData.view(bytes.buffer);
    }
    // For any raster asset, return a tiny valid PNG.
    return ByteData.view(_pngBytes.buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key.toLowerCase().endsWith('.json')) return '{}';
    if (key.toLowerCase().endsWith('.svg')) return _svg;
    return '';
  }
}

class TestAuthController extends AuthController {
  int loginCalls = 0;
  int requestPasswordResetOtpCalls = 0;
  int verifyPasswordResetOtpCalls = 0;
  int resetPasswordWithOtpCalls = 0;

  String? lastEmail;
  String? lastOtp;
  String? lastPassword;
  String? lastPasswordConfirmation;

  @override
  Future<void> login({
    required String email,
    required String password,
    bool enableBiometricAfterLogin = false,
  }) async {
    loginCalls++;
    lastEmail = email;
    lastPassword = password;
  }

  @override
  Future<void> requestPasswordResetOTP({required String email}) async {
    requestPasswordResetOtpCalls++;
    lastEmail = email;
  }

  @override
  Future<void> verifyPasswordResetOTP({
    required String email,
    required String otp,
  }) async {
    verifyPasswordResetOtpCalls++;
    lastEmail = email;
    lastOtp = otp;
  }

  @override
  Future<void> resetPasswordWithOTP({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    resetPasswordWithOtpCalls++;
    lastEmail = email;
    lastOtp = otp;
    lastPassword = password;
    lastPasswordConfirmation = passwordConfirmation;
  }
}

T setUpGetxForWidgetTests<T extends AuthController>({
  required AuthService authService,
  required T Function() authControllerFactory,
}) {
  Get.testMode = true;
  Get.reset();

  mockSecureStorageChannel();
  Get.put<LanguageService>(LanguageService(), permanent: true);
  Get.put<AuthService>(authService, permanent: true);

  final controller = authControllerFactory();
  Get.put<AuthController>(controller, permanent: true);
  return controller;
}

Widget wrapForTest(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    builder:
        (context, _) => GetMaterialApp(
          home: DefaultAssetBundle(
            bundle: _TestAssetBundle(),
            child: Scaffold(body: child),
          ),
        ),
  );
}

