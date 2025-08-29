import 'package:get/get.dart';
import 'package:pipze/models/login_response_model.dart';
import 'package:pipze/models/user_model.dart';
import 'package:pipze/services/api_service.dart';
import 'package:pipze/services/auth_service.dart';
import 'package:pipze/services/secure_storage_service.dart';
import 'package:pipze/widgets/custom_toast.dart';
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

  // ==================== LOGIN METHODS ====================
  Future<void> login({required String email, required String password}) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _authService.login(
        email: email,
        password: password,
      );

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

  // ==================== REGISTRATION METHODS ====================
  Future<bool> register({required Map<String, dynamic> data}) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _authService.register(data: data);

      if (response.success && response.data != null) {
        _registerData.value = response.data;

        CustomToastService.showSuccess(
          message: 'Registration initiated successfully',
          title: 'Success',
        );

        return true; // Return success for OTP flow
      } else {
        _setError(response.message ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      _setError('Registration error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== OTP METHODS ====================
  Future<bool> sendOTP({required String email}) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _authService.sendOTP(email: email);

      if (response.success && response.data != null) {
        _otpSentEmail.value = email;
        _otpSentMessage.value =
            response.data!['message'] ?? 'OTP sent successfully';

        CustomToastService.showSuccess(
          message: _otpSentMessage.value,
          title: 'Success',
        );

        return true;
      } else {
        _setError(response.message ?? 'Failed to send OTP');
        return false;
      }
    } catch (e) {
      _setError('Send OTP error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyOTP({required String email, required String otp}) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _authService.verifyOTP(email: email, otp: otp);

      if (response.success && response.data != null) {
        _verifiedEmail.value = email;
        _verifiedOtp.value = otp;

        CustomToastService.showSuccess(
          message: 'OTP verified successfully',
          title: 'Success',
        );

        return true;
      } else {
        _setError(response.message ?? 'OTP verification failed');
        return false;
      }
    } catch (e) {
      _setError('Verify OTP error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resendOTP({required String email}) async {
    await sendOTP(email: email);
  }

  // ==================== PASSWORD RESET METHODS ====================
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
        CustomToastService.showSuccess(
          message: 'Password reset successfully',
          title: 'Success',
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

  // ==================== LOGOUT & UTILITY METHODS ====================
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

  // ==================== PRIVATE HELPER METHODS ====================
  void _setLoading(bool loading) {
    _isLoading.value = loading;
  }

  void _setError(String error) {
    _errorMessage.value = error;
    if (error.isNotEmpty) {
      CustomToastService.showError(message: error, position: SnackPosition.TOP);
    }
  }

  void _clearError() {
    _errorMessage.value = '';
  }
}
