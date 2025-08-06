import 'package:get/get.dart';
import 'package:pipze/models/login_response_model.dart';
import 'package:pipze/services/secure_storage_service.dart';
import '../services/auth_service.dart';
import '../routes/app_pages.dart';
import 'dart:convert';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  // Observable states
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;
  final _isAuthenticated = false.obs;
  final _loginResponse = Rxn<LoginResponseModel>();
  final _otpSentEmail = ''.obs;
  final _otpSentMessage = ''.obs;
  final _verifiedEmail = ''.obs;
  final _verifiedOtp = ''.obs;
  final _registerData = Rxn<Map<String, dynamic>>();

  // Getters
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  bool get isAuthenticated => _isAuthenticated.value;
  LoginResponseModel? get loginResponse => _loginResponse.value;
  String get otpSentEmail => _otpSentEmail.value;
  String get otpSentMessage => _otpSentMessage.value;
  String get verifiedEmail => _verifiedEmail.value;
  String get verifiedOtp => _verifiedOtp.value;
  Map<String, dynamic>? get registerData => _registerData.value;

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }

  Future<void> login({required String email, required String password}) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _authService.login(
        email: email,
        password: password,
      );

      print("AuthController login response: ${response.data}");
      print("AuthController login token: ${response.data?.data.token}");
      print(
        "AuthController login websocket token: ${response.data?.data.websocketToken}",
      );
      print("AuthController login user: ${response.data?.data.user.toJson()}");

      if (response.success && response.data != null) {
        // Save login data to secure storage
        final loginData = {
          'token': response.data!.data.token,
          'websocket_token': response.data!.data.websocketToken,
          'user': response.data!.data.user.toJson(),
          'is_logged_in': true,
        };

        await SecureStorageService.saveUserData(jsonEncode(loginData));
        await SecureStorageService.saveAuthToken(response.data!.data.token);
        await SecureStorageService.saveLoginStatus(true);

        _loginResponse.value = response.data;
        _isAuthenticated.value = true;

        // Navigate to trading screen
        Get.offAllNamed(AppPages.TRADING);
      } else {
        _setError(response.message ?? 'Login failed');
      }
    } catch (e) {
      _setError('Login error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendOTP({required String email}) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _authService.sendOTP(email: email);

      if (response.success && response.data != null) {
        _otpSentEmail.value = email;
        _otpSentMessage.value =
            response.data!['message'] ?? 'OTP sent successfully';

        Get.snackbar(
          'Success',
          _otpSentMessage.value,
          snackPosition: SnackPosition.TOP,
        );
        Get.toNamed(AppPages.VERIFY_CODE, arguments: email);
      } else {
        _setError(response.message ?? 'Failed to send OTP');
      }
    } catch (e) {
      _setError('Send OTP error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> verifyOTP({required String email, required String otp}) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _authService.verifyOTP(email: email, otp: otp);

      if (response.success && response.data != null) {
        _verifiedEmail.value = email;
        _verifiedOtp.value = otp;

        Get.snackbar(
          'Success',
          'OTP verified successfully',
          snackPosition: SnackPosition.TOP,
        );
      } else {
        _setError(response.message ?? 'OTP verification failed');
      }
    } catch (e) {
      _setError('Verify OTP error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _authService.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );

      if (response.success && response.data != null) {
        Get.snackbar(
          'Success',
          'Password reset successfully',
          snackPosition: SnackPosition.TOP,
        );

        // Navigate to login screen
        Get.offAllNamed(AppPages.LOGIN);
      } else {
        _setError(response.message ?? 'Password reset failed');
      }
    } catch (e) {
      _setError('Reset password error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resendOTP({
    required String email,
    String message = 'OTP resent successfully',
  }) async {
    await sendOTP(email: email);
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String mobile,
    required String otp,
    required String registerEventType,
    required bool acceptTerms,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _authService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        mobile: mobile,
        otp: otp,
        registerEventType: registerEventType,
        acceptTerms: acceptTerms,
      );

      if (response.success && response.data != null) {
        _registerData.value = response.data;

        Get.snackbar(
          'Success',
          'Registration successful',
          snackPosition: SnackPosition.TOP,
        );

        // Navigate to account created screen
        Get.offAllNamed(AppPages.ACCOUNT_CREATED);
      } else {
        _setError(response.message ?? 'Registration failed');
      }
    } catch (e) {
      _setError('Registration error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      // Clear secure storage
      await SecureStorageService.clearAuthData();

      // Reset state
      _loginResponse.value = null;
      _isAuthenticated.value = false;
      _registerData.value = null;
      _clearError();

      // Navigate to get started screen
      Get.offAllNamed(AppPages.GET_STARTED);
    } catch (e) {
      _setError('Logout error: $e');
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      final isLoggedIn = await SecureStorageService.isUserLoggedIn();
      _isAuthenticated.value = isLoggedIn;

      if (isLoggedIn) {
        // Try to get stored user data
        final userData = await SecureStorageService.getUserData();
        if (userData != null) {
          // You might want to create a LoginResponseModel from stored data
          // _loginResponse.value = LoginResponseModel.fromJson(userData.toJson());
        }
      }
    } catch (e) {
      print('AuthController checkAuthStatus error: $e');
      _isAuthenticated.value = false;
    }
  }

  void resetAuthState() {
    _loginResponse.value = null;
    _isAuthenticated.value = false;
    _otpSentEmail.value = '';
    _otpSentMessage.value = '';
    _verifiedEmail.value = '';
    _verifiedOtp.value = '';
    _registerData.value = null;
    _clearError();
  }

  void _setLoading(bool loading) {
    _isLoading.value = loading;
  }

  void _setError(String error) {
    _errorMessage.value = error;
    if (error.isNotEmpty) {
      Get.snackbar('Error', error, snackPosition: SnackPosition.TOP);
    }
  }

  void _clearError() {
    _errorMessage.value = '';
  }
}
