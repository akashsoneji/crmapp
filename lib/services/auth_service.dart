import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/api_const.dart';
import 'package:crm_app/models/login_response_model.dart';
import 'package:crm_app/services/api_service.dart';
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

  // Password reset OTP flow methods
  Future<ApiResponse<Map<String, dynamic>>> requestPasswordResetOTP({
    required String email,
  });

  Future<ApiResponse<Map<String, dynamic>>> verifyPasswordResetOTP({
    required String email,
    required String otp,
  });

  Future<ApiResponse<Map<String, dynamic>>> resetPasswordWithOTP({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  });

  Future<ApiResponse<Map<String, dynamic>>> changePassword({
    required String mt5Account,
    required String newPassword,
  });

  Future<ApiResponse<Map<String, dynamic>>> changeLeverage({
    required String mt5Account,
    required int leverage,
  });

  Future<ApiResponse<Map<String, dynamic>>> changeUserPassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
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
      // Check network connectivity before attempting login
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return ApiResponse.error(
          'No internet connection. Please check your network and try again.',
        );
      }

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
        final errorMessage =
            response.message ?? 'Login failed - invalid response';
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

  // ==================== PASSWORD RESET OTP FLOW ====================
  @override
  Future<ApiResponse<Map<String, dynamic>>> requestPasswordResetOTP({
    required String email,
  }) async {
    try {
      final data = {'email': email};

      final response = await ApiService.post(
        endpoint: ApiConstants.requestPasswordResetOTP,
        data: data,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      } else {
        return ApiResponse.error(
          response.message ?? response.data?['message'] ?? 'Failed to send OTP',
        );
      }
    } catch (e) {
      print("AuthService requestPasswordResetOTP error: ${e.toString()}");
      return ApiResponse.error('Network error: $e');
    }
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> verifyPasswordResetOTP({
    required String email,
    required String otp,
  }) async {
    try {
      final data = {'email': email, 'otp': otp};

      final response = await ApiService.post(
        endpoint: ApiConstants.verifyPasswordResetOTP,
        data: data,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      } else {
        return ApiResponse.error(
          response.message ??
              response.data?['message'] ??
              'OTP verification failed',
        );
      }
    } catch (e) {
      print("AuthService verifyPasswordResetOTP error: ${e.toString()}");
      return ApiResponse.error('Network error: $e');
    }
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> resetPasswordWithOTP({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final data = {
        'email': email,
        'otp': otp,
        'password': password,
        'password_confirmation': passwordConfirmation,
      };

      final response = await ApiService.post(
        endpoint: ApiConstants.resetPasswordWithOTP,
        data: data,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      } else {
        return ApiResponse.error(
          response.message ??
              response.data?['message'] ??
              'Password reset failed',
        );
      }
    } catch (e) {
      print("AuthService resetPasswordWithOTP error: ${e.toString()}");
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
      final data = {
        'meta_account_number': mt5Account,
        'newPassword': newPassword,
      };

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

  // ==================== CHANGE LEVERAGE ====================
  @override
  Future<ApiResponse<Map<String, dynamic>>> changeLeverage({
    required String mt5Account,
    required int leverage,
  }) async {
    try {
      final data = {'mt5_account': mt5Account, 'leverage': leverage};

      final response = await ApiService.post(
        endpoint: ApiConstants.changeLeverage,
        data: data,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      } else {
        return ApiResponse.error(
          response.data?['message'] ?? 'Change leverage failed',
        );
      }
    } catch (e) {
      print("AuthService changeLeverage error: ${e.toString()}");
      return ApiResponse.error('Network error: $e');
    }
  }

  // ==================== CHANGE USER PASSWORD ====================
  @override
  Future<ApiResponse<Map<String, dynamic>>> changeUserPassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final data = {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      };

      final response = await ApiService.post(
        endpoint: ApiConstants.changeUserPassword,
        data: data,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      } else {
        // Handle validation errors
        final errorData = response.data;
        String errorMessage = response.message ?? 'Change password failed';

        if (errorData is Map<String, dynamic> &&
            errorData.containsKey('errors')) {
          final errors = errorData['errors'] as Map<String, dynamic>?;
          if (errors != null && errors.isNotEmpty) {
            // Get first error message
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              errorMessage = firstError.first.toString();
            } else if (firstError is String) {
              errorMessage = firstError;
            }
          }
        }

        return ApiResponse.error(errorMessage, data: errorData);
      }
    } catch (e) {
      print("AuthService changeUserPassword error: ${e.toString()}");
      return ApiResponse.error('Network error: $e');
    }
  }

  // ==================== REGISTER ====================
  @override
  Future<ApiResponse<Map<String, dynamic>>> register({
    required Map<String, dynamic> data,
  }) async {
    try {
      // Check network connectivity before attempting registration
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return ApiResponse.error(
          'No internet connection. Please check your network and try again.',
        );
      }

      final response = await ApiService.post(
        endpoint: ApiConstants.register,
        data: data,
      );

      // If response failed or data is invalid, return error message from API
      if (!response.success && response.message != null) {
        return ApiResponse.error(response.message ?? 'Registration failed');
      }

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data);
      } else {
        // If data is null or not a map, return error message from API
        final errorMessage =
            response.message ?? 'Registration failed - invalid response';
        return ApiResponse.error(errorMessage);
      }
    } catch (e, t) {
      print("AuthService register network error: ${e.toString()}");
      print("AuthService register network stacktrace: ${t.toString()}");
      return ApiResponse.error('Network error during registration: $e');
    }
  }

  // ==================== REGISTER With OTP Verification ====================
  @override
  Future<ApiResponse<LoginResponseModel>> registerWithOTPVerification({
    required Map<String, dynamic> data,
  }) async {
    try {
      // Check network connectivity before attempting registration
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return ApiResponse.error(
          'No internet connection. Please check your network and try again.',
        );
      }

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

          // Check if the API response indicates failure
          if (!loginResponse.status) {
            return ApiResponse.error(loginResponse.message);
          }

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
        final errorMessage =
            response.message ?? 'Registration failed - invalid response';
        return ApiResponse.error(errorMessage);
      }
    } catch (e, t) {
      print(
        "AuthService registerWithOTPVerification network error: ${e.toString()}",
      );
      dev.log(
        "AuthService registerWithOTPVerification network stacktrace: ${t.toString()}",
      );
      return ApiResponse.error('Network error during registration: $e');
    }
  }
}
