import 'package:get/get.dart';
import 'package:pipze/models/login_response_model.dart';
import 'package:pipze/models/user_model.dart';
import 'package:pipze/models/settings_profile_model.dart';
import 'package:pipze/services/auth_service.dart';
import 'package:pipze/services/secure_storage_service.dart';
import 'package:pipze/widgets/custom_toast.dart';
import '../constants/api_const.dart';
import '../routes/app_pages.dart';
import 'dart:convert';
import 'dashboard_controller.dart';
import 'account_controller.dart';
import 'package:pipze/services/api_service.dart';
import 'trading_controller.dart';
import 'package:pipze/services/trading_websocket_service.dart';
import 'wallet_controller.dart';
import 'instruments_controller.dart';
import 'chart_socket_controller.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  // Observable states
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;
  final _isAuthenticated = false.obs;
  final _loginResponse = Rxn<LoginResponseModel>();
  final _userData = Rxn<UserModel>();
  final _otpSentEmail = ''.obs;
  final _otpSentMessage = ''.obs;
  final _verifiedEmail = ''.obs;
  final _verifiedOtp = ''.obs;
  final _registerData = Rxn<Map<String, dynamic>>();
  final _profileData = Rxn<SettingsProfileData>();

  // Getters
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  bool get isAuthenticated => _isAuthenticated.value;
  LoginResponseModel? get loginResponse => _loginResponse.value;
  UserModel? get userData => _userData.value;
  String get otpSentEmail => _otpSentEmail.value;
  String get otpSentMessage => _otpSentMessage.value;
  String get verifiedEmail => _verifiedEmail.value;
  String get verifiedOtp => _verifiedOtp.value;
  Map<String, dynamic>? get registerData => _registerData.value;
  SettingsProfileData? get profileData => _profileData.value;

  // User data getters
  String? get userEmail => _userData.value?.email;
  String? get userFullName => _userData.value?.fullName;
  String? get userFirstName => _userData.value?.firstName;
  String? get userLastName => _userData.value?.lastName;
  String? get userMobile => _userData.value?.mobile;
  bool get isEmailVerified => _userData.value?.isEmailVerified ?? false;
  bool get isMobileVerified => _userData.value?.isMobileVerified ?? false;
  bool get isUserActive => _userData.value?.isActive ?? false;

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
    getUserData();
  }

  // Get user data from secure storage
  Future<UserModel?> getUserData() async {
    try {
      final userData = await SecureStorageService.getUserData();
      _userData.value = userData;
      return userData;
    } catch (e) {
      print('AuthController: Error getting user data: $e');
      _setError('Failed to get user data: $e');
      return null;
    }
  }

  // Get user email specifically
  Future<String?> getUserEmail() async {
    final user = await getUserData();
    print("userEmail getUserEmail : ${user?.email}");
    return user?.email;
  }

  Future<String> getUserName() async {
    final user = await getUserData();
    print("userEmail getUserEmail : ${user?.firstName} ${user?.lastName}");
    return '${user?.firstName} ${user?.lastName}';
  }

  // Refresh user data (useful for profile updates)
  Future<void> refreshUserData() async {
    await getUserData();
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
        await SecureStorageService.saveWebsocketToken(
          response.data!.data.websocketToken,
        );
        await SecureStorageService.saveLoginStatus(true);

        Get.offAllNamed(AppPages.TRADING);

        _loginResponse.value = response.data;
        _userData.value = response.data!.data.user;
        _isAuthenticated.value = true;

        // Initialize dashboard controller and fetch MT5 accounts
        try {
          final dashboardController = Get.put(DashboardController());
          await dashboardController.forceCheckMT5Accounts();

          // Wait for account data to be ready before proceeding
          // This ensures account number and type are available when screen loads
          if (!dashboardController.hasMT5Accounts.value ||
              dashboardController.mt5Accounts.isEmpty) {
            // Wait a bit more and retry if accounts weren't loaded
            // await Future.delayed(const Duration(milliseconds: 500));
            await dashboardController.forceCheckMT5Accounts();
          }

          // Force refresh account controller to update active account
          try {
            if (Get.isRegistered<AccountController>()) {
              final accountController = Get.find<AccountController>();
              await accountController.forceRefreshAccountData();
              print('AuthController: Account data refreshed after login');
            }
          } catch (e) {
            print('AuthController: Error refreshing account controller: $e');
          }
        } catch (e) {
          print('AuthController: Error initializing dashboard: $e');
        }

        // Reset trading controller for new user
        try {
          if (Get.isRegistered<TradingController>()) {
            final tradingController = Get.find<TradingController>();
            tradingController.resetToInitialState();
          }
        } catch (e) {
          print('AuthController: Error resetting trading controller: $e');
        }

        // Reset and reconnect WebSocket for new user
        try {
          if (Get.isRegistered<TradingWebSocketService>()) {
            final tradingWebSocketService = Get.find<TradingWebSocketService>();
            tradingWebSocketService.resetAndReconnect();
          }
        } catch (e) {
          print('AuthController: Error resetting WebSocket service: $e');
        }

        // Navigate to trading screen

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
        // _registerData.value = response.data;

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

  // ==================== REGISTRATION METHODS ====================
  Future<bool> registerWithOTPVerification({
    required Map<String, dynamic> data,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _authService.registerWithOTPVerification(
        data: data,
      );

      if (response.success && response.data != null) {
        print("NEW USER DATA");
        print(response.data);

        // Check if the response has the expected structure
        if (response.data!.data.token.isNotEmpty) {
          final loginData = {
            'token': response.data!.data.token,
            'websocket_token': response.data!.data.websocketToken,
            'user': response.data!.data.user.toJson(),
            'is_logged_in': true,
          };

          await SecureStorageService.saveUserData(jsonEncode(loginData));
          await SecureStorageService.saveAuthToken(response.data!.data.token);
          await SecureStorageService.saveWebsocketToken(
            response.data!.data.websocketToken,
          );
          await SecureStorageService.saveLoginStatus(true);

          // Set user data in controller
          _userData.value = response.data!.data.user;
          _isAuthenticated.value = true;

          CustomToastService.showSuccess(
            message: 'Registration completed successfully',
            title: 'Success',
          );
        } else {
          CustomToastService.showError(
            message: 'Invalid response structure from server',
            title: 'Error',
          );
          return false;
        }
      } else {
        CustomToastService.showError(
          message: response.message ?? 'Registration failed',
          title: 'Error',
        );
        return false;
      }

      return true; // Return success for OTP flow
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

  // Future<bool> verifyOTP({required Map<String, dynamic> data}) async {
  //   try {
  //     _setLoading(true);
  //     _clearError();
  //
  //     final response = await _authService.register(data: data);
  //
  //     if (response.success && response.data != null) {
  //       _registerData.value = response.data;
  //
  //       CustomToastService.showSuccess(
  //         message: 'OTP verified successfully',
  //         title: 'Success',
  //       );
  //
  //       return true; // Return success for OTP flow
  //     } else {
  //       _setError(response.message ?? 'Registration failed');
  //       return false;
  //     }
  //   } catch (e) {
  //     _setError('Verify OTP error: $e');
  //     return false;
  //   } finally {
  //     _setLoading(false);
  //   }
  // }

  // Future<bool> verifyOTP({required String email, required String otp}) async {
  //   try {
  //     _setLoading(true);
  //     _clearError();
  //
  //     final response = await _authService.verifyOTP(email: email, otp: otp);
  //
  //     if (response.success && response.data != null) {
  //       _verifiedEmail.value = email;
  //       _verifiedOtp.value = otp;
  //
  //       CustomToastService.showSuccess(
  //         message: 'OTP verified successfully',
  //         title: 'Success',
  //       );
  //
  //       return true;
  //     } else {
  //       _setError(response.message ?? 'OTP verification failed');
  //       return false;
  //     }
  //   } catch (e) {
  //     _setError('Verify OTP error: $e');
  //     return false;
  //   } finally {
  //     _setLoading(false);
  //   }
  // }

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
      _setLoading(true);
      _clearError();

      final token = await SecureStorageService.getAuthToken();

      final response = await ApiService.post(
        endpoint: ApiConstants.logout,
        token: token,
      );

      if (response.success && response.data != null) {
        // Clear secure storage
        await SecureStorageService.clearAuthData();

        // Clear trading data and disconnect WebSocket
        try {
          if (Get.isRegistered<TradingWebSocketService>()) {
            final tradingWebSocketService = Get.find<TradingWebSocketService>();
            tradingWebSocketService.clearAllDataAndDisconnect();
          }
        } catch (e) {
          print('AuthController: Error clearing trading WebSocket service: $e');
        }

        // Clear Instruments Controller WebSocket
        try {
          if (Get.isRegistered<InstrumentsController>()) {
            final instrumentsController = Get.find<InstrumentsController>();
            instrumentsController.disconnectWebSocket();
            print('AuthController: Instruments socket disconnected on logout');
          }
        } catch (e) {
          print('AuthController: Error disconnecting Instruments socket: $e');
        }

        // Clear Chart Socket Controller WebSocket
        try {
          if (Get.isRegistered<ChartSocketController>()) {
            final chartSocketController = Get.find<ChartSocketController>();
            chartSocketController.resetController();
            print('AuthController: Chart socket disconnected on logout');
          }
        } catch (e) {
          print('AuthController: Error disconnecting Chart socket: $e');
        }

        // Clear trading controller data
        try {
          if (Get.isRegistered<TradingController>()) {
            final tradingController = Get.find<TradingController>();
            tradingController.clearAllTradingData();
          }
        } catch (e) {
          print('AuthController: Error clearing trading controller: $e');
        }

        // Clear wallet controller data
        try {
          if (Get.isRegistered<WalletController>()) {
            final walletController = Get.find<WalletController>();
            walletController.clearAllWalletData();
          }
        } catch (e) {
          print('AuthController: Error clearing wallet controller: $e');
        }

        // Reset state
        _loginResponse.value = null;
        _userData.value = null;
        _isAuthenticated.value = false;
        _registerData.value = null;
        _clearError();

        // Navigate to get started screen
        Get.offAllNamed(AppPages.GET_STARTED);
      } else {
        final errorMsg = 'Logout failed';
        _setError(errorMsg);
      }
    } catch (e) {
      _setError('Logout error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logoutWithOutApi() async {
    try {
      // Clear secure storage
      await SecureStorageService.clearAuthData();

      // Clear trading data and disconnect WebSocket
      try {
        if (Get.isRegistered<TradingWebSocketService>()) {
          final tradingWebSocketService = Get.find<TradingWebSocketService>();
          tradingWebSocketService.clearAllDataAndDisconnect();
        }
      } catch (e) {
        print('AuthController: Error clearing trading WebSocket service: $e');
      }

      // Clear Instruments Controller WebSocket
      try {
        if (Get.isRegistered<InstrumentsController>()) {
          final instrumentsController = Get.find<InstrumentsController>();
          instrumentsController.disconnectWebSocket();
          print('AuthController: Instruments socket disconnected on logout');
        }
      } catch (e) {
        print('AuthController: Error disconnecting Instruments socket: $e');
      }

      // Clear Chart Socket Controller WebSocket
      try {
        if (Get.isRegistered<ChartSocketController>()) {
          final chartSocketController = Get.find<ChartSocketController>();
          chartSocketController.resetController();
          print('AuthController: Chart socket disconnected on logout');
        }
      } catch (e) {
        print('AuthController: Error disconnecting Chart socket: $e');
      }

      // Clear trading controller data
      try {
        if (Get.isRegistered<TradingController>()) {
          final tradingController = Get.find<TradingController>();
          tradingController.clearAllTradingData();
        }
      } catch (e) {
        print('AuthController: Error clearing trading controller: $e');
      }

      // Clear wallet controller data
      try {
        if (Get.isRegistered<WalletController>()) {
          final walletController = Get.find<WalletController>();
          walletController.clearAllWalletData();
        }
      } catch (e) {
        print('AuthController: Error clearing wallet controller: $e');
      }

      // Reset state
      _loginResponse.value = null;
      _userData.value = null;
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
          _userData.value = userData;
        }
      }
    } catch (e) {
      print('AuthController checkAuthStatus error: $e');
      _isAuthenticated.value = false;
    }
  }

  void resetAuthState() {
    _loginResponse.value = null;
    _userData.value = null;
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

  // Get Profile Method
  Future<SettingsProfileData?> getProfile() async {
    try {
      _isLoading.value = true;
      _clearError();

      final token = await SecureStorageService.getAuthToken();

      final response = await ApiService.get(
        endpoint: ApiConstants.profile,
        token: token,
      );

      if (response.success && response.data != null) {
        final profileData = SettingsProfileData.fromJson(response.data);
        _profileData.value = profileData;
        return profileData;
      } else {
        CustomToastService.showError(
          message: response.message ?? 'Failed to load profile',
        );
        return null;
      }
    } catch (e, t) {
      print('AuthController: Error getting profile: $e');
      print('AuthController: Error getting profile: $t');
      CustomToastService.showError(message: 'Failed to load profile: $e');
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  // Profile Update Method
  Future<void> updateProfile({
    required String title,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String dob,
    required String gender,
    required int state,
    required int city,
    required String address,
    required String nationality,
    required String cityName,
    // required String otp,
    required int countryId,
    String postcode = '',
    String address2 = '',
  }) async {
    try {
      _isLoading.value = true;
      _clearError();

      final token = await SecureStorageService.getAuthToken();

      // final response = await ApiService.post(
      //   token: token,
      //   endpoint: ApiConstants.profile,
      //   data: {
      //     'is_app': '1',
      //     'user_id': _userData.value?.id ?? '',
      //     'auth_key': token,
      //     'user_title': title,
      //     'user_first_name': firstName,
      //     'user_last_name': lastName,
      //     'user_email_address': email,
      //     'user_phone': phone,
      //     'user_dob': dob,
      //     'user_gender': gender,
      //     'user_state': state,
      //     'user_city': city,
      //     'user_postcode': postcode,
      //     'user_address_1': address,
      //     'user_address_2': "",
      //     // 'otp': otp,
      //     'country_id': countryId,
      //   },
      // );
      final response = await ApiService.post(
        token: token,
        endpoint: ApiConstants.profile,
        data: {
          "page1": {"email": email, "title": title, "gender": gender},
          "page2": {
            "date_of_birth": dob,
            "alt_mobile": phone,
            "alt_email": email,
          },
          "page3": {
            "country": countryId,
            "state": state,
            "city": city,
            "nationality": nationality, // you’ll need to pass this
          },
          "page4": {
            "address_line1": address,
            "address_line2": cityName,
            "postcode": postcode,
            "language": "English",
          },
          "page5": {
            "us_citizen": "yes",
            "politically_exposed": "no",
            "industry": "finance",
            "tax_identification_number": "123456789",
          },
          // Keep common params outside if required by API
          "is_app": "1",
          "user_id": _userData.value?.id ?? '',
          "auth_key": token,
        },
      );

      if (response.success) {
        // Show success toast
        CustomToastService.showSuccess(
          message: response.message ?? 'Profile updated successfully!',
        );

        // Navigate to next page
        Get.toNamed(AppPages.KYC_DOCS);
      } else {
        // Show error toast
        CustomToastService.showError(
          message: response.message ?? 'Failed to update profile',
        );
      }
    } catch (e) {
      print('AuthController: Error updating profile: $e');
      CustomToastService.showError(message: 'Failed to update profile: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // ==================== FORGOT PASSWORD METHODS ====================
  Future<void> forgotPassword({required Map<String, dynamic> data}) async {
    try {
      _setLoading(true); // show activity indicator
      _clearError();

      final response = await ApiService.post(
        endpoint: ApiConstants.forgotPassword,
        data: data,
      );

      print('FORGOT PASSWORD DATA');
      print(response.data);
      final responseData = response.data;
      final status = responseData['status'];
      final message = responseData['message'] ?? 'Something went wrong';
      if (status == true) {
        CustomToastService.showSuccess(message: message, title: 'Success');

        // Go back to previous screen
        Get.toNamed(AppPages.LOGIN);
      } else {
        print("ELSE FORGOT PASSOWRD STATUS ${status}");
        CustomToastService.showError(message: message);
      }
    } catch (e, t) {
      print("CATCH FORGOT PASSOWRD STATUS ${e}");
      print("CATCH TT FORGOT PASSOWRD STATUS ${t}");
      _setError('Forgot password error: $e');
    } finally {
      _setLoading(false); // hide activity indicator
    }
  }
}
