import 'package:get/get.dart';
import 'package:pipze/constants/api_const.dart';
import 'package:pipze/models/login_response_model.dart';
import 'package:pipze/services/api_service.dart';
import 'dart:developer' as dev;

abstract class AuthService extends GetxService {
  Future<ApiResponse<LoginResponseModel>> login({
    required String email,
    required String password,
  });

  Future<ApiResponse<Map<String, dynamic>>> sendOTP({required String email});

  Future<ApiResponse<Map<String, dynamic>>> verifyOTP({
    required String email,
    required String otp,
  });

  Future<ApiResponse<Map<String, dynamic>>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });

  Future<ApiResponse<Map<String, dynamic>>> changePassword({
    required String mt5Account,
    required String newPassword,
  });

  Future<ApiResponse<Map<String, dynamic>>> register({
    required Map<String, dynamic> data,
  });

  Future<ApiResponse<LoginResponseModel>> registerWithOTPVerification({
    required Map<String, dynamic> data,
  });
}

class AuthServiceImpl extends AuthService {
  // ==================== LOGIN ====================
  @override
  Future<ApiResponse<LoginResponseModel>> login({
    required String email,
    required String password,
  }) async {
    try {
      final data = {'email': email, 'password': password};

      final response = await ApiService.post(
        endpoint: ApiConstants.login,
        data: data,
      );

      // If response failed or data is invalid, return error message from API
      if (!response.success && response.message != null) {
        return ApiResponse.error(response.message ?? 'Login failed');
      }

      // Check if response.data is a valid Map
      if (response.data != null && response.data is Map<String, dynamic>) {
        try {
          final loginResponse = LoginResponseModel.fromJson(response.data);

          if (loginResponse.status) {
            return ApiResponse.success(loginResponse);
          } else {
            return ApiResponse.error(loginResponse.message);
          }
        } catch (e, t) {
          print("AuthService login parsing error: ${e.toString()}");
          print("AuthService login parsing stacktrace: ${t.toString()}");
          return ApiResponse.error('Failed to parse login response: $e');
        }
      } else {
        // If data is null or not a map, return error message from API
        final errorMessage = response.message ?? 'Login failed - invalid response';
        return ApiResponse.error(errorMessage);
      }
    } catch (e, t) {
      print("AuthService login network error: ${e.toString()}");
      print("AuthService login network stacktrace: ${t.toString()}");
      return ApiResponse.error('Network error during login: $e');
    }
  }

  // ==================== SEND OTP ====================
  @override
  Future<ApiResponse<Map<String, dynamic>>> sendOTP({
    required String email,
  }) async {
    try {
      final data = {'email': email};

      final response = await ApiService.post(
        endpoint: ApiConstants.sendOTP,
        data: data,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      } else {
        return ApiResponse.error(
          response.data?['message'] ?? 'Failed to send OTP',
        );
      }
    } catch (e) {
      print("AuthService sendOTP error: ${e.toString()}");
      return ApiResponse.error('Network error: $e');
    }
  }

  // ==================== VERIFY OTP ====================
  @override
  Future<ApiResponse<Map<String, dynamic>>> verifyOTP({
    required String email,
    required String otp,
  }) async {
    try {
      final data = {
        'email': email,
        'otp': otp,
        'otp_verification_type': 'email',
        'register_event_type': 'verifyOtp',
      };

      final response = await ApiService.post(
        endpoint: ApiConstants.verifyOTP,
        data: data,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      } else {
        return ApiResponse.error(
          response.data?['message'] ?? 'OTP verification failed',
        );
      }
    } catch (e) {
      print("AuthService verifyOTP error: ${e.toString()}");
      return ApiResponse.error('Network error: $e');
    }
  }

  // ==================== RESET PASSWORD ====================
  @override
  Future<ApiResponse<Map<String, dynamic>>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final data = {'email': email, 'otp': otp, 'new_password': newPassword};

      final response = await ApiService.post(
        endpoint: ApiConstants.resetPassword,
        data: data,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      } else {
        return ApiResponse.error(
          response.data?['message'] ?? 'Password reset failed',
        );
      }
    } catch (e) {
      print("AuthService resetPassword error: ${e.toString()}");
      return ApiResponse.error('Network error: $e');
    }
  }

  // ==================== CHANGE PASSWORD ====================
  @override
  Future<ApiResponse<Map<String, dynamic>>> changePassword({
    required String mt5Account,
    required String newPassword,
  }) async {
    try {

      final data = {'meta_account_number': mt5Account, 'newPassword': newPassword};

      final response = await ApiService.post(
        endpoint: ApiConstants.changePassword,
        data: data,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      } else {
        return ApiResponse.error(
          response.data?['message'] ?? 'Change password failed',
        );
      }
    } catch (e) {
      print("AuthService changePassword error: ${e.toString()}");
      return ApiResponse.error('Network error: $e');
    }
  }

  // ==================== REGISTER ====================
  @override
  Future<ApiResponse<Map<String, dynamic>>> register({
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await ApiService.post(
        endpoint: ApiConstants.register,
        data: data,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      } else {
        return ApiResponse.error(
          response.data?['message'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      print("AuthService register error: ${e.toString()}");
      return ApiResponse.error('Network error: $e');
    }
  }

  // ==================== REGISTER With OTP Verification ====================
  @override
  Future<ApiResponse<LoginResponseModel>> registerWithOTPVerification({
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await ApiService.post(
        endpoint: ApiConstants.register,
        data: data,
      );

      // If response failed or data is invalid, return error message from API
      if (!response.success && response.message != null) {
        return ApiResponse.error(response.message ?? 'Registration failed');
      }

      // Check if response.data is a valid Map
      if (response.data != null && response.data is Map<String, dynamic>) {
        print(
          "AuthService registerWithOTPVerification raw response: ${response.data}",
        );
        try {
          final loginResponse = LoginResponseModel.fromJson(response.data);
          print("AuthService registerWithOTPVerification parsed successfully");
          return ApiResponse.success(loginResponse);
        } catch (e, t) {
          print(
            "AuthService registerWithOTPVerification parsing error: ${e.toString()}",
          );
          print(
            "AuthService registerWithOTPVerification response data: ${response.data}",
          );
          dev.log(
            "AuthService registerWithOTPVerification parsing stacktrace: ${t.toString()}",
          );
          return ApiResponse.error('Failed to parse registration response: $e');
        }
      } else {
        // If data is null or not a map, return error message from API
        print(
          "AuthService registerWithOTPVerification failed: ${response.message}",
        );
        final errorMessage = response.message ?? 'Registration failed - invalid response';
        return ApiResponse.error(errorMessage);
      }
    } catch (e, t) {
      print("AuthService registerWithOTPVerification error: ${e.toString()}");
      dev.log(
        "AuthService registerWithOTPVerification trace is : ${t.toString()}",
      );
      return ApiResponse.error('Network error: $e');
    }
  }
}
