import 'package:get/get.dart';
import 'package:crm_app/models/login_response_model.dart';
import 'package:crm_app/models/user_model.dart';
import 'package:crm_app/models/settings_profile_model.dart';
import 'package:crm_app/flavor_config.dart';
import 'package:get/get.dart' as g;
import 'package:crm_app/services/auth_service.dart';
import 'package:crm_app/services/secure_storage_service.dart';
import 'package:crm_app/services/account_cache_service.dart';
import 'package:crm_app/widgets/custom_toast.dart';
import 'package:crm_app/controllers/app_notification_controller.dart';
import '../constants/api_const.dart';
import '../routes/app_pages.dart';
import 'dart:convert';
import 'dashboard_controller.dart';
import 'account_controller.dart';
import 'package:crm_app/services/api_service.dart';
import 'trading_controller.dart';
import 'package:crm_app/services/trading_websocket_service.dart';
import 'package:crm_app/services/websocket_endpoint_helper.dart';
import 'wallet_controller.dart';
import 'instruments_controller.dart';
import 'chart_socket_controller.dart';
import 'package:crm_app/services/one_click_trading_service.dart';
import 'package:crm_app/services/account_websocket_service.dart';
import 'dart:io' show Platform;
import 'package:crm_app/services/biometric_service.dart';
import 'package:crm_app/services/app_lock_service.dart';

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
    // checkAuthStatus(); // Redundant - called in AuthCheckScreen and initServices
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
  Future<void> login({
    required String email,
    required String password,
    bool enableBiometricAfterLogin = false,
  }) async {
    try {
      // ⏱️ Performance measurement: Start timing
      final stopwatch = Stopwatch()..start();
      print('⏱️ [PERFORMANCE] Login process started at ${DateTime.now()}');

      _setLoading(true);
      _clearError();

      final loginStartTime = stopwatch.elapsedMilliseconds;
      String? fcmToken = await SecureStorageService.getFcmToken();
      String deviceType = Platform.isIOS ? 'ios' : 'android';

      final response = await _authService.login(
        email: email,
        password: password,
        fcmToken: fcmToken,
        deviceType: deviceType,
      );
      print(
        '⏱️ [PERFORMANCE] Login API completed: ${stopwatch.elapsedMilliseconds - loginStartTime}ms',
      );

      if (response.success && response.data != null) {
        // Save login data to secure storage
        final loginData = {
          'token': response.data!.data.token,
          'websocket_token': response.data!.data.websocketToken,
          'user': response.data!.data.user.toJson(),
          'is_logged_in': true,
        };

        // Pre-initialize controllers in parallel with saving tokens
        // This reduces sequential overhead
        final controllerInitStart = stopwatch.elapsedMilliseconds;
        final dashboardController = Get.put(DashboardController());
        print(
          '⏱️ [PERFORMANCE] DashboardController initialized: ${stopwatch.elapsedMilliseconds - controllerInitStart}ms',
        );

        // Save tokens and update state in parallel
        final tokenSaveStart = stopwatch.elapsedMilliseconds;
        await Future.wait([
          SecureStorageService.saveUserData(jsonEncode(loginData)),
          SecureStorageService.saveAuthToken(response.data!.data.token),
          SecureStorageService.saveWebsocketToken(
            response.data!.data.websocketToken,
          ),
          SecureStorageService.saveLoginStatus(true),
        ]);
        print(
          '⏱️ [PERFORMANCE] Tokens saved: ${stopwatch.elapsedMilliseconds - tokenSaveStart}ms',
        );

        _loginResponse.value = response.data;
        _userData.value = response.data!.data.user;
        _isAuthenticated.value = true;
        await _persistTenaxUserBrokerProfile();

        if (enableBiometricAfterLogin) {
          try {
            // Only enable if device supports + enrolled and user confirms.
            final supported = await BiometricService.instance.isDeviceSupported();
            final enrolled = await BiometricService.instance.isEnrolled();
            if (supported && enrolled) {
              final ok = await BiometricService.instance.authenticate(
                reason: 'Confirm biometric to enable login.',
              );
              if (ok) {
                try {
                  if (Get.isRegistered<AppLockService>()) {
                    Get.find<AppLockService>().markJustAuthenticated();
                  }
                } catch (_) {}
                await SecureStorageService.setBiometricEnabled(
                  true,
                  userIdentifier: email.trim().toLowerCase(),
                );
              }
            }
          } catch (e) {
            // Keep login flow safe even if biometrics fail.
            print('AuthController: Failed to enable biometrics after login: $e');
          }
        }

        // Enable one-click trading by default after login
        OneClickTradingService.instance.setOneClickTradingEnabled(true);

        // ✅ FIX: Wait for account check before connecting sockets
        // Initialize dashboard controller and fetch MT5 accounts
        int accountDataStart = 0;
        try {
          // Get account controller if it exists
          AccountController? accountController;
          try {
            if (Get.isRegistered<AccountController>()) {
              accountController = Get.find<AccountController>();
            }
          } catch (e) {
            print('AuthController: AccountController not registered yet: $e');
          }

          // ✅ FIX: Wait for account check to complete
          accountDataStart = stopwatch.elapsedMilliseconds;
          final futures = <Future>[dashboardController.forceCheckMT5Accounts()];

          if (accountController != null) {
            futures.add(accountController.forceRefreshAccountData());
          }

          await Future.wait(futures, eagerError: false);
          print(
            '⏱️ [PERFORMANCE] Account data loaded: ${stopwatch.elapsedMilliseconds - accountDataStart}ms',
          );

          // ✅ FIX: Check if account exists and set primary account
          final primaryAccount = dashboardController.primaryMT5Account;
          if (primaryAccount != null) {
            // Account exists - set it in WebSocketEndpointHelper
            WebSocketEndpointHelper.setPrimaryAccount(primaryAccount);
            print(
              'AuthController: Primary account set: ${primaryAccount.metaAccountNumber} (${primaryAccount.tradingServer})',
            );
          } else {
            // No account - set to null (will use self-hosted endpoints)
            WebSocketEndpointHelper.setPrimaryAccount(null);
            print(
              'AuthController: No account found, using self-hosted endpoints',
            );
          }

          print('AuthController: All account data loaded after login');
        } catch (e) {
          print('AuthController: Error initializing dashboard: $e');
          // Set to null on error to use self-hosted endpoints
          WebSocketEndpointHelper.setPrimaryAccount(null);
        }

        // ✅ FIX: Re-initialize ALL controllers and WebSocket services BEFORE navigation
        // This ensures everything is ready when the UI loads
        print(
          'AuthController: Re-initializing all controllers and services...',
        );

        // 1. Re-initialize DashboardController
        try {
          if (Get.isRegistered<DashboardController>()) {
            Get.delete<DashboardController>(force: true);
          }
          Get.put<DashboardController>(DashboardController(), permanent: true);
          print('AuthController: DashboardController re-initialized');
        } catch (e) {
          print(
            'AuthController: Error re-initializing DashboardController: $e',
          );
        }

        // 2. Re-initialize AccountController
        try {
          if (Get.isRegistered<AccountController>()) {
            Get.delete<AccountController>(force: true);
          }
          Get.put<AccountController>(AccountController(), permanent: true);
          print('AuthController: AccountController re-initialized');
        } catch (e) {
          print('AuthController: Error re-initializing AccountController: $e');
        }

        // 3. Re-initialize InstrumentsController (has WebSocket)
        try {
          if (Get.isRegistered<InstrumentsController>()) {
            Get.delete<InstrumentsController>(force: true);
          }
          Get.put<InstrumentsController>(
            InstrumentsController(),
            permanent: true,
          );
          print('AuthController: InstrumentsController re-initialized');
        } catch (e) {
          print(
            'AuthController: Error re-initializing InstrumentsController: $e',
          );
        }

        // 4. Re-initialize ChartSocketController (has WebSocket)
        try {
          if (Get.isRegistered<ChartSocketController>()) {
            Get.delete<ChartSocketController>(force: true);
          }
          Get.put<ChartSocketController>(
            ChartSocketController(),
            permanent: true,
          );
          print('AuthController: ChartSocketController re-initialized');
        } catch (e) {
          print(
            'AuthController: Error re-initializing ChartSocketController: $e',
          );
        }

        // 5. Re-initialize TradingController
        try {
          if (Get.isRegistered<TradingController>()) {
            Get.delete<TradingController>(force: true);
          }
          Get.put<TradingController>(TradingController(), permanent: true);
          print('AuthController: TradingController re-initialized');
        } catch (e) {
          print('AuthController: Error re-initializing TradingController: $e');
        }

        // 6. Re-initialize TradingWebSocketService
        try {
          if (Get.isRegistered<TradingWebSocketService>()) {
            Get.delete<TradingWebSocketService>(force: true);
          }
          Get.put<TradingWebSocketService>(
            TradingWebSocketService(),
            permanent: true,
          );
          print('AuthController: TradingWebSocketService re-initialized');
        } catch (e) {
          print(
            'AuthController: Error re-initializing TradingWebSocketService: $e',
          );
        }

        // 7. Re-initialize AccountWebSocketService
        try {
          if (Get.isRegistered<AccountWebSocketService>()) {
            Get.delete<AccountWebSocketService>(force: true);
          }
          Get.put<AccountWebSocketService>(
            AccountWebSocketService(),
            permanent: true,
          );
          print('AuthController: AccountWebSocketService re-initialized');
        } catch (e) {
          print(
            'AuthController: Error re-initializing AccountWebSocketService: $e',
          );
        }

        print(
          'AuthController: All controllers and services re-initialized with new user token',
        );

        // Navigate to trading screen AFTER controllers are ready
        Get.offAllNamed(AppPages.TRADING);

        // Navigate to trading screen
        // final navigationStart = stopwatch.elapsedMilliseconds;
        //
        // stopwatch.stop();

        // ⏱️ Performance measurement: Final timing report
        // print('═══════════════════════════════════════════════════════');
        // print('⏱️ [PERFORMANCE] LOGIN TO DASHBOARD TIMING REPORT');
        // print('═══════════════════════════════════════════════════════');
        // final totalTime = stopwatch.elapsedMilliseconds;
        // print(
        //   '⏱️ Total time: ${totalTime}ms (${(totalTime / 1000).toStringAsFixed(2)}s)',
        // );
        // print('⏱️ Breakdown:');
        // print(
        //   '   • Login API: ${stopwatch.elapsedMilliseconds - loginStartTime}ms',
        // );
        // if (totalTime > controllerInitStart) {
        //   print('   • Controller Init: ${controllerInitStart}ms');
        // }
        // if (totalTime > tokenSaveStart) {
        //   print('   • Token Save: ${tokenSaveStart - controllerInitStart}ms');
        // }
        // if (accountDataStart > 0 && totalTime > accountDataStart) {
        //   print('   • Account Data: ${accountDataStart - tokenSaveStart}ms');
        // }
        // print('   • Navigation: ${totalTime - navigationStart}ms');
        // print('═══════════════════════════════════════════════════════');
        // print(
        //   '${stopwatch.elapsedMilliseconds < 2000
        //       ? "✅ EXCELLENT"
        //       : stopwatch.elapsedMilliseconds < 3000
        //       ? "✅ GOOD"
        //       : "⚠️ NEEDS IMPROVEMENT"} (<2s excellent, <3s good, >3s needs work)',
        // );
        // print('═══════════════════════════════════════════════════════');
      } else {
        print('❌ AuthController.login() - Login failed:');
        print('   response.success: ${response.success}');
        print('   response.message: ${response.message}');
        print('   response.data: ${response.data}');

        // Ensure we always have an error message to display
        final errorMessage =
            response.message?.isNotEmpty == true
                ? response.message!
                : 'Login failed. Please check your credentials and try again.';

        print('   Setting error message: $errorMessage');
        _setError(errorMessage);
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
        // Display validation errors if available
        final errorMessage = response.message ?? 'Registration failed';
        _setError(errorMessage);

        // Show error toast with validation details
        CustomToastService.showError(
          message: errorMessage,
          title: 'Validation Error',
        );

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

          // Trigger background API call for FCM token
          _registerFcmTokenInBackground(response.data!.data.token);

          // Set user data in controller
          _userData.value = response.data!.data.user;
          _isAuthenticated.value = true;
          await _persistTenaxUserBrokerProfile();

          // Enable one-click trading by default after registration
          OneClickTradingService.instance.setOneClickTradingEnabled(true);

          // ✅ FIX: Re-initialize ALL controllers and WebSocket services for new user
          // This ensures everything is ready with the new user's token
          print(
            'AuthController: Re-initializing all controllers after registration...',
          );

          try {
            // Fetch primary account and set in WebSocketEndpointHelper
            final dashboardController = Get.find<DashboardController>();
            await dashboardController.forceCheckMT5Accounts();
            final primaryAccount = dashboardController.primaryMT5Account;

            if (primaryAccount != null) {
              WebSocketEndpointHelper.setPrimaryAccount(primaryAccount);
              print(
                'AuthController: Primary account set for new user: ${primaryAccount.metaAccountNumber}',
              );
            } else {
              WebSocketEndpointHelper.setPrimaryAccount(null);
              print(
                'AuthController: No account found, using self-hosted endpoints',
              );
            }
          } catch (e) {
            print('AuthController: Error fetching account data: $e');
            WebSocketEndpointHelper.setPrimaryAccount(null);
          }

          // Re-initialize all controllers (same as login flow)
          // 1. DashboardController
          try {
            if (Get.isRegistered<DashboardController>()) {
              Get.delete<DashboardController>(force: true);
            }
            Get.put<DashboardController>(
              DashboardController(),
              permanent: true,
            );
            print('AuthController: DashboardController re-initialized');
          } catch (e) {
            print(
              'AuthController: Error re-initializing DashboardController: $e',
            );
          }

          // 2. AccountController
          try {
            if (Get.isRegistered<AccountController>()) {
              Get.delete<AccountController>(force: true);
            }
            Get.put<AccountController>(AccountController(), permanent: true);
            print('AuthController: AccountController re-initialized');
          } catch (e) {
            print(
              'AuthController: Error re-initializing AccountController: $e',
            );
          }

          // 3. InstrumentsController
          try {
            if (Get.isRegistered<InstrumentsController>()) {
              Get.delete<InstrumentsController>(force: true);
            }
            Get.put<InstrumentsController>(
              InstrumentsController(),
              permanent: true,
            );
            print('AuthController: InstrumentsController re-initialized');
          } catch (e) {
            print(
              'AuthController: Error re-initializing InstrumentsController: $e',
            );
          }

          // 4. ChartSocketController
          try {
            if (Get.isRegistered<ChartSocketController>()) {
              Get.delete<ChartSocketController>(force: true);
            }
            Get.put<ChartSocketController>(
              ChartSocketController(),
              permanent: true,
            );
            print('AuthController: ChartSocketController re-initialized');
          } catch (e) {
            print(
              'AuthController: Error re-initializing ChartSocketController: $e',
            );
          }

          // 5. TradingController
          try {
            if (Get.isRegistered<TradingController>()) {
              Get.delete<TradingController>(force: true);
            }
            Get.put<TradingController>(TradingController(), permanent: true);
            print('AuthController: TradingController re-initialized');
          } catch (e) {
            print(
              'AuthController: Error re-initializing TradingController: $e',
            );
          }

          // 6. TradingWebSocketService
          try {
            if (Get.isRegistered<TradingWebSocketService>()) {
              Get.delete<TradingWebSocketService>(force: true);
            }
            Get.put<TradingWebSocketService>(
              TradingWebSocketService(),
              permanent: true,
            );
            print('AuthController: TradingWebSocketService re-initialized');
          } catch (e) {
            print(
              'AuthController: Error re-initializing TradingWebSocketService: $e',
            );
          }

          // 7. AccountWebSocketService
          try {
            if (Get.isRegistered<AccountWebSocketService>()) {
              Get.delete<AccountWebSocketService>(force: true);
            }
            Get.put<AccountWebSocketService>(
              AccountWebSocketService(),
              permanent: true,
            );
            print('AuthController: AccountWebSocketService re-initialized');
          } catch (e) {
            print(
              'AuthController: Error re-initializing AccountWebSocketService: $e',
            );
          }

          print(
            'AuthController: All controllers re-initialized for new registered user',
          );

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
        // Display validation errors if available
        final errorMessage = response.message ?? 'Registration failed';
        _setError(errorMessage);

        CustomToastService.showError(
          message: errorMessage,
          title: 'Validation Error',
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

  Future<void> _persistTenaxUserBrokerProfile() async {
    if (!FlavorConfig.isMultiBrokerEnabled) return;
    try {
      if (!FlavorConfig.isTenax()) return;

      final user = _userData.value;
      final brokerSelection =
          await SecureStorageService.getTenaxBrokerSelection();
      if (user == null || brokerSelection == null) return;

      final email = user.email.trim().toLowerCase();
      if (email.isEmpty) return;

      final authToken = await SecureStorageService.getAuthToken();
      final wsToken = await SecureStorageService.getWebsocketToken();

      final brokerName =
          (brokerSelection['selected_name'] ??
                  brokerSelection['name'] ??
                  FlavorConfig.instance.appName)
              .toString();
      final brokerSlug =
          (brokerSelection['selected_slug'] ??
                  brokerSelection['slug'] ??
                  brokerSelection['broker_list_item']?['slug'] ??
                  '')
              .toString();
      final profileKey = '$email|$brokerSlug';

      final profile = <String, dynamic>{
        'profile_key': profileKey,
        'user_email': user.email,
        'user_name': user.fullName,
        'broker_name': brokerName,
        'broker_slug': brokerSlug,
        'broker_logo_local_path':
            brokerSelection['selected_logo_local_path'] ?? '',
        'broker_logo_url': brokerSelection['selected_logo_url'] ?? '',
        'broker_data': brokerSelection,
        // Save login credentials so they can be restored on account switch
        'login_data': {
          'token': authToken ?? '',
          'websocket_token': wsToken ?? '',
          'user': user.toJson(),
          'is_logged_in': true,
        },
        'saved_at': DateTime.now().toIso8601String(),
      };

      await SecureStorageService.upsertTenaxUserBrokerProfile(profile);
    } catch (e) {
      print('AuthController: Failed to persist Tenax user-broker profile: $e');
    }
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

  /// Centralized method to clear all user data, disconnect sockets, and reset controllers
  /// This ensures consistent cleanup across logout, account deletion, and offline logout
  Future<void> _clearAllUserData() async {
    print('AuthController: Starting centralized cleanup of all user data');

    // 1. Clear secure storage and cache
    await SecureStorageService.clearAuthData();
    // Safety: biometric login should not remain enabled after logout.
    await SecureStorageService.clearBiometricState();
    try {
      if (Get.isRegistered<AppLockService>()) {
        await Get.find<AppLockService>().clearLock();
      }
    } catch (_) {}
    await AccountCacheService.clearCache();
    print('AuthController: Cleared secure storage and account cache');

    // 2. Clear WebSocketEndpointHelper cache
    WebSocketEndpointHelper.setPrimaryAccount(null);
    print('AuthController: Cleared WebSocket endpoint helper cache');

    // 3. Disconnect and DELETE all WebSocket services and controllers

    // Clear TradingWebSocketService
    try {
      if (Get.isRegistered<TradingWebSocketService>()) {
        final tradingWebSocketService = Get.find<TradingWebSocketService>();
        tradingWebSocketService.clearAllDataAndDisconnect();
        Get.delete<TradingWebSocketService>(force: true);
        print('AuthController: Trading WebSocket disconnected and deleted');
      }
    } catch (e) {
      print('AuthController: Error clearing trading WebSocket service: $e');
    }

    // Clear InstrumentsController (has WebSocket)
    try {
      if (Get.isRegistered<InstrumentsController>()) {
        final instrumentsController = Get.find<InstrumentsController>();
        instrumentsController.disconnectWebSocket();
        Get.delete<InstrumentsController>(force: true);
        print(
          'AuthController: Instruments controller disconnected and deleted',
        );
      }
    } catch (e) {
      print('AuthController: Error clearing Instruments controller: $e');
    }

    // Clear ChartSocketController (has WebSocket)
    try {
      if (Get.isRegistered<ChartSocketController>()) {
        final chartSocketController = Get.find<ChartSocketController>();
        chartSocketController.resetController();
        Get.delete<ChartSocketController>(force: true);
        print(
          'AuthController: Chart socket controller disconnected and deleted',
        );
      }
    } catch (e) {
      print('AuthController: Error clearing Chart socket controller: $e');
    }

    // Clear AccountWebSocketService
    try {
      if (Get.isRegistered<AccountWebSocketService>()) {
        Get.delete<AccountWebSocketService>(force: true);
        print('AuthController: Account WebSocket disconnected and deleted');
      }
    } catch (e) {
      print('AuthController: Error disconnecting Account WebSocket: $e');
    }

    // 4. Clear all controller data and DELETE them

    // Clear DashboardController
    try {
      if (Get.isRegistered<DashboardController>()) {
        final dashboardController = Get.find<DashboardController>();
        dashboardController.clearAllData();
        Get.delete<DashboardController>(force: true);
        print('AuthController: DashboardController cleared and deleted');
      }
    } catch (e) {
      print('AuthController: Error clearing DashboardController: $e');
    }

    // Clear AccountController
    try {
      if (Get.isRegistered<AccountController>()) {
        Get.delete<AccountController>(force: true);
        print('AuthController: AccountController deleted');
      }
    } catch (e) {
      print('AuthController: Error clearing AccountController: $e');
    }

    // Clear TradingController
    try {
      if (Get.isRegistered<TradingController>()) {
        final tradingController = Get.find<TradingController>();
        tradingController.clearAllTradingData();
        tradingController.clearInstruments();
        tradingController.pendingPositions.clear();
        tradingController.marketPositions.clear();
        tradingController.closedPositions.clear();
        Get.delete<TradingController>(force: true);
        print('AuthController: TradingController cleared and deleted');
      }
    } catch (e) {
      print('AuthController: Error clearing TradingController: $e');
    }

    // Clear WalletController
    try {
      if (Get.isRegistered<WalletController>()) {
        final walletController = Get.find<WalletController>();
        walletController.clearAllWalletData();
        Get.delete<WalletController>(force: true);
        print('AuthController: WalletController cleared and deleted');
      }
    } catch (e) {
      print('AuthController: Error clearing WalletController: $e');
    }

    // 5. Reset AuthController state
    _loginResponse.value = null;
    _userData.value = null;
    _isAuthenticated.value = false;
    _registerData.value = null;
    _clearError();

    print('AuthController: All user data cleared successfully');
  }

  bool _hasValidTenaxLoginProfile(Map<String, dynamic> profile) {
    final loginData = profile['login_data'];
    if (loginData is! Map) return false;
    final token = (loginData['token'] ?? '').toString().trim();
    return token.isNotEmpty;
  }

  Future<bool> _isTenaxBrokerFlowEnabled() async {
    // Quick compile-time gate: if multi-broker is disabled in TenaxConfig,
    // skip the SecureStorage check entirely.
    if (!FlavorConfig.isMultiBrokerEnabled) return false;
    return await SecureStorageService.getTenaxBrokerSelectionFlag();
  }

  Future<Map<String, dynamic>?>
  _trySwitchTenaxFallbackProfileAfterLogout() async {
    if (!await _isTenaxBrokerFlowEnabled()) {
      return null;
    }

    final profiles = await SecureStorageService.getTenaxUserBrokerProfiles();
    if (profiles.isEmpty) return null;

    final currentKey = await SecureStorageService.getTenaxCurrentProfileKey();
    final currentIndex = profiles.indexWhere(
      (p) => (p['profile_key'] ?? '').toString() == (currentKey ?? ''),
    );
    if (currentIndex < 0) return null;

    // Remove the currently logged-out profile from saved profiles.
    profiles.removeAt(currentIndex);
    await SecureStorageService.saveTenaxUserBrokerProfiles(profiles);

    final fallback =
        profiles.where(_hasValidTenaxLoginProfile).cast<Map<String, dynamic>>();
    if (fallback.isEmpty) {
      await SecureStorageService.setTenaxCurrentProfileKey('');
      return null;
    }

    final nextProfile = fallback.first;
    final nextProfileKey = (nextProfile['profile_key'] ?? '').toString();
    if (nextProfileKey.isNotEmpty) {
      await SecureStorageService.setTenaxCurrentProfileKey(nextProfileKey);
    }
    return nextProfile;
  }

  Future<void> _restoreTenaxProfileSession(Map<String, dynamic> profile) async {
    if (!FlavorConfig.isMultiBrokerEnabled) return;
    final brokerData =
        profile['broker_data'] is Map<String, dynamic>
            ? profile['broker_data'] as Map<String, dynamic>
            : null;
    final loginData = profile['login_data'];
    if (brokerData == null || loginData is! Map) return;

    final token = (loginData['token'] ?? '').toString().trim();
    if (token.isEmpty) return;

    final wsToken = (loginData['websocket_token'] ?? '').toString();
    final userData = loginData['user'];
    final runtimeConfig =
        brokerData['broker_runtime_config'] is Map<String, dynamic>
            ? brokerData['broker_runtime_config'] as Map<String, dynamic>
            : brokerData;
    final selectedName = (brokerData['selected_name'] ?? '').toString().trim();
    final selectedLogo =
        (brokerData['selected_logo_local_path'] ??
                brokerData['selected_logo_url'] ??
                '')
            .toString()
            .trim();

    await SecureStorageService.saveTenaxBrokerSelection(brokerData);
    FlavorConfig.applyTenaxBrokerRuntimeConfig(
      config: runtimeConfig,
      brokerName: selectedName.isNotEmpty ? selectedName : null,
      brokerLogoUrl: selectedLogo.isNotEmpty ? selectedLogo : null,
      brokerData: brokerData,
    );

    if (userData is Map<String, dynamic>) {
      await SecureStorageService.saveUserData(
        jsonEncode({
          'token': token,
          'websocket_token': wsToken,
          'user': userData,
          'is_logged_in': true,
        }),
      );
      try {
        _userData.value = UserModel.fromJson(userData);
      } catch (_) {
        await getUserData();
      }
    }
    await SecureStorageService.saveAuthToken(token);
    await SecureStorageService.saveWebsocketToken(wsToken);
    await SecureStorageService.saveLoginStatus(true);
    _isAuthenticated.value = true;
    await AccountCacheService.clearCache();
  }

  Future<void> logout() async {
    try {
      _setLoading(true);
      _clearError();
      final token = await SecureStorageService.getAuthToken();

      final response = await ApiService.post(
        endpoint: ApiConstants.logout,
        token: token,
      );

      // Determine where to navigate after logout
      final isTenaxBrokerFlow =
          FlavorConfig.isMultiBrokerEnabled &&
          await SecureStorageService.getTenaxBrokerSelectionFlag();

      final fallbackProfile = await _trySwitchTenaxFallbackProfileAfterLogout();
      if (fallbackProfile != null) {
        await _restoreTenaxProfileSession(fallbackProfile);
        if (Get.isDialogOpen == true) {
          Get.back(closeOverlays: true);
        }
        Get.forceAppUpdate();
        return;
      }

      if (response.success && response.data != null) {
        await _clearAllUserData();
        Get.offAllNamed(
          isTenaxBrokerFlow
              ? AppPages.TENAX_BROKER_SELECTION
              : AppPages.GET_STARTED,
          arguments:
              isTenaxBrokerFlow
                  ? {'allowBack': false, 'nextRoute': AppPages.LOGIN}
                  : null,
        );
      } else {
        print('AuthController: Logout failed - ${response.message}');
        await _clearAllUserData();
        Get.offAllNamed(
          isTenaxBrokerFlow
              ? AppPages.TENAX_BROKER_SELECTION
              : AppPages.GET_STARTED,
          arguments:
              isTenaxBrokerFlow
                  ? {'allowBack': false, 'nextRoute': AppPages.LOGIN}
                  : null,
        );
      }
    } catch (e) {
      print('AuthController: Logout error: $e');
      try {
        final fallbackProfile =
            await _trySwitchTenaxFallbackProfileAfterLogout();
        if (fallbackProfile != null) {
          await _restoreTenaxProfileSession(fallbackProfile);
          if (Get.isDialogOpen == true) {
            Get.back(closeOverlays: true);
          }
          Get.forceAppUpdate();
          return;
        }

        final isTenaxBrokerFlow =
            FlavorConfig.isMultiBrokerEnabled &&
            await SecureStorageService.getTenaxBrokerSelectionFlag();
        await _clearAllUserData();
        Get.offAllNamed(
          isTenaxBrokerFlow
              ? AppPages.TENAX_BROKER_SELECTION
              : AppPages.GET_STARTED,
          arguments:
              isTenaxBrokerFlow
                  ? {'allowBack': false, 'nextRoute': AppPages.LOGIN}
                  : null,
        );
      } catch (cleanupError) {
        print('AuthController: Cleanup error: $cleanupError');
        Get.offAllNamed(AppPages.GET_STARTED);
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAccount(Map<String, dynamic> data) async {
    try {
      _setLoading(true);
      _clearError();

      final token = await SecureStorageService.getAuthToken();

      // ["password":pasword,"reason": "No longer need the service","accept_terms": true,"confirm_deletion": true]
      final response = await ApiService.post(
        endpoint: ApiConstants.deleteAccount,
        token: token,
        data: data,
      );

      if (response.success && response.data != null) {
        // Use centralized cleanup method
        await _clearAllUserData();

        // Navigate to get started screen
        Get.offAllNamed(AppPages.GET_STARTED);
      } else {
        // Don't show error UI - just log it
        print('AuthController: Delete account failed - ${response.message}');
        // Show error toast before navigation
        CustomToastService.showError(
          title: 'Error',
          message: response.message ?? 'Something went wrong',
        );
      }
    } catch (e) {
      // Don't show error UI after navigation - just log it
      print('AuthController: Delete account error: $e');
      CustomToastService.showError(
        title: 'Error',
        message: 'Failed to delete account',
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logoutWithOutApi() async {
    try {
      final fallbackProfile = await _trySwitchTenaxFallbackProfileAfterLogout();
      if (fallbackProfile != null) {
        await _restoreTenaxProfileSession(fallbackProfile);
        if (Get.isDialogOpen == true) {
          Get.back(closeOverlays: true);
        }
        Get.forceAppUpdate();
        return;
      }

      await _clearAllUserData();
      final isTenaxBrokerFlow =
          FlavorConfig.isMultiBrokerEnabled &&
          await SecureStorageService.getTenaxBrokerSelectionFlag();
      Get.offAllNamed(
        isTenaxBrokerFlow
            ? AppPages.TENAX_BROKER_SELECTION
            : AppPages.GET_STARTED,
        arguments:
            isTenaxBrokerFlow
                ? {'allowBack': false, 'nextRoute': AppPages.LOGIN}
                : null,
      );
    } catch (e) {
      print('AuthController: Logout without API error: $e');
      Get.offAllNamed(AppPages.GET_STARTED);
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

        // Validate token by making a lightweight API call
        // This ensures the token is still valid (not expired or invalidated)
        final token = await SecureStorageService.getAuthToken();
        if (token != null && token.isNotEmpty) {
          try {
            // Make a lightweight API call to validate token
            final response = await ApiService.get(
              endpoint: ApiConstants.profile,
              token: token,
            );

            if (!response.success) {
              // Check if it's a network error or actual auth failure
              final message = response.message?.toLowerCase() ?? '';
              final isNetworkError =
                  message.contains('network') ||
                  message.contains('connection') ||
                  message.contains('timeout');

              if (isNetworkError) {
                // ✅ FIX: Don't logout on network errors!
                // Assume valid session if we can't reach server
                print(
                  'AuthController: Network error during token check, assuming offline mode',
                );
                _isAuthenticated.value = true;
              } else {
                // Token is invalid (401 or other API error), clear auth state
                print(
                  'AuthController: Token validation failed ($message), user is not authenticated',
                );
                _isAuthenticated.value = false;
                // REMOVED: await logoutWithOutApi(); // Don't navigate from status check!
              }
            } else {
              // Token is valid
              _isAuthenticated.value = true;
            }
          } catch (e) {
            // If validation fails with exception, check if it's network related
            print('AuthController: Error validating token: $e');
            final errorStr = e.toString().toLowerCase();
            final isNetworkError =
                errorStr.contains('socket') ||
                errorStr.contains('network') ||
                errorStr.contains('timeout') ||
                errorStr.contains('handshake');

            if (isNetworkError) {
              print('AuthController: Network exception, assuming offline mode');
              _isAuthenticated.value = true;
            } else {
              _isAuthenticated.value = false;
            }
          }
        } else {
          _isAuthenticated.value = false;
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
    print('🔴 AuthController._setError() called with: "$error"');
    _errorMessage.value = error;
    if (error.isNotEmpty) {
      print('🔴 Attempting to show error toast: "$error"');
      try {
        CustomToastService.showError(
          message: error,
          position: SnackPosition.TOP,
        );
        print('🔴 CustomToastService.showError() called successfully');
      } catch (e, stackTrace) {
        print('❌ Error showing toast: $e');
        print('❌ Stack trace: $stackTrace');
        // Fallback: Use AppNotificationController if CustomToastService fails
        try {
          if (Get.isRegistered<AppNotificationController>()) {
            Get.find<AppNotificationController>().showError(
              message: error,
              title: 'Error',
            );
            print('🔴 Fallback: AppNotificationController called successfully');
          }
        } catch (fallbackError) {
          print('❌ Fallback notification also failed: $fallbackError');
          // Last resort: just print it
          print('🔴 ERROR MESSAGE (Toast failed): $error');
        }
      }
    } else {
      print('⚠️ _setError called with empty error message');
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

  // ==================== PASSWORD RESET OTP FLOW METHODS ====================
  Future<void> requestPasswordResetOTP({required String email}) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _authService.requestPasswordResetOTP(email: email);

      if (response.success && response.data != null) {
        final message = response.data?['message'] ?? 'OTP sent to your email.';
        CustomToastService.showSuccess(message: message, title: 'Success');

        // Navigate to verify code screen with email
        Get.toNamed(AppPages.VERIFY_CODE, arguments: email);
      } else {
        final errorMessage = response.message ?? 'Failed to send OTP';
        CustomToastService.showError(message: errorMessage);
        _setError(errorMessage);
      }
    } catch (e) {
      _setError('Request OTP error: $e');
      CustomToastService.showError(message: 'Failed to send OTP: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> verifyPasswordResetOTP({
    required String email,
    required String otp,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _authService.verifyPasswordResetOTP(
        email: email,
        otp: otp,
      );

      if (response.success && response.data != null) {
        final message = response.data?['message'] ?? 'OTP verified.';
        CustomToastService.showSuccess(message: message, title: 'Success');

        // Navigate to create new password screen with email and otp
        Get.toNamed(
          AppPages.CREATE_NEW_PASSWORD,
          arguments: {'email': email, 'otp': otp},
        );
      } else {
        final errorMessage = response.message ?? 'OTP verification failed';
        CustomToastService.showError(message: errorMessage);
        _setError(errorMessage);
      }
    } catch (e) {
      _setError('Verify OTP error: $e');
      CustomToastService.showError(message: 'OTP verification failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPasswordWithOTP({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _authService.resetPasswordWithOTP(
        email: email,
        otp: otp,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      if (response.success && response.data != null) {
        final message =
            response.data?['message'] ?? 'Password reset successfully';
        CustomToastService.showSuccess(message: message, title: 'Success');

        // Navigate to login screen
        Get.offAllNamed(AppPages.LOGIN);
      } else {
        final errorMessage = response.message ?? 'Password reset failed';
        CustomToastService.showError(message: errorMessage);
        _setError(errorMessage);
      }
    } catch (e) {
      _setError('Reset password error: $e');
      CustomToastService.showError(message: 'Password reset failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _registerFcmTokenInBackground(String authToken) async {
    try {
      String? fcmToken = await SecureStorageService.getFcmToken();
      if (fcmToken == null) return;

      String deviceType = Platform.isIOS ? 'ios' : 'android';

      await ApiService.post(
        endpoint: ApiConstants.registerFcmToken,
        token: authToken,
        data: {'fcm_token': fcmToken, 'device_type': deviceType},
      );
      print('✅ AuthController: Registered FCM token in background');
    } catch (e) {
      print('⚠️ AuthController: Failed to register FCM token: $e');
    }
  }
}
