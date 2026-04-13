import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:crm_app/controllers/chart_socket_controller.dart';
import 'package:crm_app/services/price_alert_service.dart';
import 'package:crm_app/services/loading_service.dart';
import 'package:crm_app/services/notification_service.dart';
import 'package:crm_app/services/secure_storage_service.dart';
import 'constants/color.dart';

import 'flavor_config.dart';
import 'services/language_service.dart';
import 'services/theme_service.dart';
import 'core/config/app_config_service.dart';
import 'core/network/api_client.dart';
import 'core/network/network_startup_phase.dart';
import 'services/api_service_client.dart';
import 'features/copy_trading/data/datasources/copy_trading_remote_data_source.dart';
import 'features/copy_trading/data/repositories/copy_trading_repository_impl.dart';
import 'features/copy_trading/domain/repositories/copy_trading_repository.dart';
import 'features/finance/data/repositories/finance_repository_impl.dart';
import 'features/finance/domain/repositories/finance_repository.dart';
import 'features/ib/data/datasources/ib_remote_data_source.dart';
import 'features/ib/data/repositories/ib_repository_impl.dart';
import 'features/ib/domain/repositories/ib_repository.dart';
import 'features/kyc/data/repositories/kyc_repository_impl.dart';
import 'features/kyc/domain/repositories/kyc_repository.dart';
import 'features/wallet/data/repositories/wallet_repository_impl.dart';
import 'features/wallet/domain/repositories/wallet_repository.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/domain/repositories/profile_repository.dart';
import 'features/trading/data/repositories/trading_repository_impl.dart';
import 'features/trading/domain/repositories/trading_repository.dart';
import 'features/bonus/data/repositories/bonus_repository_impl.dart';
import 'features/bonus/domain/repositories/bonus_repository.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_user.dart';
import 'features/auth/domain/usecases/forgot_password.dart';
import 'features/auth/domain/usecases/register_user.dart';
import 'features/auth/domain/usecases/register_with_otp_verification.dart';
import 'features/auth/domain/usecases/request_password_reset_otp.dart';
import 'features/auth/domain/usecases/reset_password.dart';
import 'features/auth/domain/usecases/reset_password_with_otp.dart';
import 'features/auth/domain/usecases/send_otp.dart';
import 'features/auth/domain/usecases/verify_password_reset_otp.dart';
import 'controllers/auth_controller.dart';
import 'controllers/account_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'controllers/instruments_controller.dart';
import 'controllers/trading_controller.dart';
import 'services/auth_service.dart';
import 'services/account_service.dart';
import 'services/websocket_endpoint_helper.dart';
import 'routes/app_pages.dart';
import 'widgets/exit_confirmation_wrapper.dart';
import 'widgets/app_notification_stack.dart';
import 'controllers/app_notification_controller.dart';
import 'utils/app_logger.dart';
// App status check imports are enabled
import 'services/app_status/app_status_service.dart';
import 'services/app_status/app_status_controller.dart';
import 'services/app_status/app_status_overlay.dart';

// Connectivity overlay imports
import 'services/connectivity/connectivity_service.dart';
import 'services/connectivity/connectivity_controller.dart';
import 'services/connectivity/connectivity_overlay.dart';

// Firebase Background Message Handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  // 🎨 AUTO-DETECT FLAVOR FROM BUILD CONFIGURATION
  // The flavor is automatically detected from the build command
  // Example: flutter build apk --flavor afx -t lib/main.dart

  // Reset any previous flavor configuration
  FlavorConfig.reset();

  WidgetsFlutterBinding.ensureInitialized();
  // Auto-detect and initialize the correct flavor
  await _initializeFlavor();

  // Initialize Firebase and get FCM Token
  try {
    await Firebase.initializeApp();

    // Set the background messaging handler early on, as a native callback
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // IMPORTANT: Do not block app startup on token fetching.
    // Native splash will stay visible until the first Flutter frame renders.
    // Token retrieval can be slow/flaky, so we fetch it in the background.
    FirebaseMessaging.instance.getToken().then((token) async {
      try {
        print("====================================");
        print("FCM TOKEN: $token");
        print("====================================");

        if (token != null) {
          await SecureStorageService.saveFcmToken(token);
        }
      } catch (e) {
        print("FCM token handling error: $e");
      }
    }).catchError((e) {
      print("FCM token fetch error: $e");
    });
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  // Initialize logging system
  _initializeLogging();

  // Add global error handling for debugging crashes
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error(
      'Flutter Error: ${details.exception}',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // Add global error handling for async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('Platform Error: $error', error: error, stackTrace: stack);
    return true;
  };

  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize GetX services
  await initServices();

  runApp(const MyGetXApp());
}

Future<void> initServices() async {
  // Load bundled app config (branding + feature flags) early.
  final appConfigService = Get.put<AppConfigService>(
    AppConfigService(),
    permanent: true,
  );
  await appConfigService.ensureInitialized();

  // Register services
  final languageService = Get.put<LanguageService>(
    LanguageService(),
    permanent: true,
  );
  await languageService.ensureInitialized();

  // Register ThemeService
  final themeService = Get.put<ThemeService>(
    ThemeService(),
    permanent: true,
  );
  await themeService.ensureInitialized();

  // Shared API client abstraction (wrapping existing ApiService).
  Get.put<ApiClient>(ApiServiceClient(), permanent: true);

  // CopyTrading (incremental clean architecture)
  Get.put<CopyTradingRemoteDataSource>(
    CopyTradingRemoteDataSource(Get.find<ApiClient>()),
    permanent: true,
  );
  Get.put<CopyTradingRepository>(
    CopyTradingRepositoryImpl(Get.find<CopyTradingRemoteDataSource>()),
    permanent: true,
  );

  // Finance (incremental clean architecture)
  Get.put<FinanceRepository>(
    FinanceRepositoryImpl(Get.find<ApiClient>()),
    permanent: true,
  );

  // IB (incremental clean architecture)
  Get.put<IbRemoteDataSource>(
    IbRemoteDataSource(Get.find<ApiClient>()),
    permanent: true,
  );
  Get.put<IbRepository>(
    IbRepositoryImpl(Get.find<IbRemoteDataSource>()),
    permanent: true,
  );

  // KYC (incremental clean architecture)
  Get.put<KycRepository>(
    KycRepositoryImpl(Get.find<ApiClient>()),
    permanent: true,
  );

  // Wallet (incremental clean architecture)
  Get.put<WalletRepository>(
    WalletRepositoryImpl(Get.find<ApiClient>()),
    permanent: true,
  );

  // Profile / More (incremental clean architecture)
  Get.put<ProfileRepository>(
    ProfileRepositoryImpl(Get.find<ApiClient>()),
    permanent: true,
  );

  Get.put<TradingRepository>(
    TradingRepositoryImpl(Get.find<ApiClient>()),
    permanent: true,
  );
  Get.put<BonusRepository>(
    BonusRepositoryImpl(Get.find<ApiClient>()),
    permanent: true,
  );

  Get.put<AuthService>(
    AuthServiceImpl(Get.find<ApiClient>()),
    permanent: true,
  );
  Get.put<AuthRepository>(
    AuthRepositoryImpl(Get.find<AuthService>(), Get.find<ApiClient>()),
    permanent: true,
  );
  Get.put<LoginUser>(
    LoginUser(Get.find<AuthRepository>()),
    permanent: true,
  );
  Get.put<ForgotPassword>(
    ForgotPassword(Get.find<AuthRepository>()),
    permanent: true,
  );
  Get.put<RegisterUser>(
    RegisterUser(Get.find<AuthRepository>()),
    permanent: true,
  );
  Get.put<RegisterWithOtpVerification>(
    RegisterWithOtpVerification(Get.find<AuthRepository>()),
    permanent: true,
  );
  Get.put<SendOtp>(
    SendOtp(Get.find<AuthRepository>()),
    permanent: true,
  );
  Get.put<ResetPassword>(
    ResetPassword(Get.find<AuthRepository>()),
    permanent: true,
  );
  Get.put<RequestPasswordResetOtp>(
    RequestPasswordResetOtp(Get.find<AuthRepository>()),
    permanent: true,
  );
  Get.put<VerifyPasswordResetOtp>(
    VerifyPasswordResetOtp(Get.find<AuthRepository>()),
    permanent: true,
  );
  Get.put<ResetPasswordWithOtp>(
    ResetPasswordWithOtp(Get.find<AuthRepository>()),
    permanent: true,
  );
  Get.put<AccountService>(AccountServiceImpl(), permanent: true);
  Get.put<LoadingService>(LoadingService(), permanent: true);

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  Get.put<NotificationService>(notificationService, permanent: true);

  // Register controllers in proper order
  Get.put<AuthController>(AuthController(), permanent: true);

  // Initialize DashboardController first as AccountController depends on it
  Get.put<DashboardController>(DashboardController(), permanent: true);
  Get.put<AccountController>(AccountController(), permanent: true);
  Get.put<InstrumentsController>(InstrumentsController(), permanent: true);
  Get.put<ChartSocketController>(ChartSocketController(), permanent: true);
  Get.put<TradingController>(TradingController(), permanent: true);
  await PriceAlertService().initialize();

  // Initialize app notification controller for global notifications
  Get.put<AppNotificationController>(
    AppNotificationController(),
    permanent: true,
  );

  // Initialize app status service and controller for version check and maintenance mode
  // REQUIRED: Version check and maintenance check are enabled for testing
  Get.put<AppStatusService>(AppStatusService(), permanent: true);
  Get.put<AppStatusController>(AppStatusController(), permanent: true);

  // Start periodic app status checking
  // REQUIRED: Starting periodic check for testing
  final appStatusService = Get.find<AppStatusService>();
  appStatusService.startPeriodicCheck();

  // Initialize connectivity service and controller for no-internet overlay
  await Get.putAsync<ConnectivityService>(
    () async => await ConnectivityService().init(),
    permanent: true,
  );
  Get.put<ConnectivityController>(ConnectivityController(), permanent: true);
}

/// Build light theme
ThemeData _buildLightTheme() {
  return ThemeData(
    primaryColor: FlavorConfig.instance.primaryColor,
    colorScheme: ColorScheme.light(
      primary: FlavorConfig.instance.primaryColor,
      secondary: FlavorConfig.instance.secondaryColor,
      surface: AppColors.whiteColor,
      onPrimary: AppColors.whiteColor,
      onSecondary: Colors.black,
      onSurface: Colors.black,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.whiteColor,
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: FlavorConfig.instance.primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 14.h,
      ),
      alignLabelWithHint: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: FlavorConfig.instance.primaryColor,
        foregroundColor: AppColors.whiteColor,
        minimumSize: Size(double.infinity, 40.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.symmetric(vertical: 8.h),
      color: AppColors.whiteColor,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
      minLeadingWidth: 0,
      leadingAndTrailingTextStyle: TextStyle(
        fontSize: 14.sp,
        color: AppColors.textGreyLightTheme,
      ),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: AppColors.whiteColor,
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.whiteColor,
      selectedItemColor: FlavorConfig.instance.primaryColor,
      unselectedItemColor: AppColors.textGreyLightTheme,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.whiteColor,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    iconTheme: const IconThemeData(color: Colors.black),
    textTheme: const TextTheme(bodyLarge: TextStyle(color: Colors.black)),
  );
}

/// Build dark theme
ThemeData _buildDarkTheme() {
  return ThemeData(
    primaryColor: FlavorConfig.instance.primaryColor,
    colorScheme: ColorScheme.dark(
      primary: FlavorConfig.instance.primaryColor,
      secondary: FlavorConfig.instance.secondaryColor,
      surface: AppColors.surfaceDarkTheme,
      onPrimary: AppColors.whiteColor,
      onSecondary: AppColors.whiteColor,
      onSurface: AppColors.whiteColor,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.backgroundDarkTheme,
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: FlavorConfig.instance.primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 14.h,
      ),
      alignLabelWithHint: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: FlavorConfig.instance.primaryColor,
        foregroundColor: AppColors.whiteColor,
        minimumSize: Size(double.infinity, 40.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.symmetric(vertical: 8.h),
      color: AppColors.cardDarkTheme,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
      minLeadingWidth: 0,
      leadingAndTrailingTextStyle: TextStyle(
        fontSize: 14.sp,
        color: AppColors.textGreyDark,
      ),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: AppColors.surfaceDarkTheme,
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceDarkTheme,
      selectedItemColor: FlavorConfig.instance.primaryColor,
      unselectedItemColor: AppColors.textGreyDark,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    appBarTheme:   AppBarTheme(
      backgroundColor: AppColors.surfaceDarkTheme,
      foregroundColor: AppColors.whiteColor,
      elevation: 0,
    ),
    iconTheme:   IconThemeData(color: AppColors.whiteColor),
    textTheme:   TextTheme(bodyLarge: TextStyle(color: AppColors.whiteColor)),
  );
}

class MyGetXApp extends StatelessWidget {
  const MyGetXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Obx(() {
          final languageService = Get.find<LanguageService>();
          final themeService = Get.find<ThemeService>();
          final isRTL = languageService.isRTL();
          // Access brandingUpdateIndex to trigger reactive rebuild when broker/branding changes
          // Strictly gated: only listen if multi-broker is enabled for Tenax flavor
          if (FlavorConfig.isMultiBrokerEnabled) {
            final _ = languageService.brandingUpdateIndex.value;
          }

          return Directionality(
            textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
            child: ExitConfirmationWrapper(
              forceExitDialog: true, // Always show exit dialog on back button
              child: GetMaterialApp(
                builder: (context, child) {
                  final mediaQuery = MediaQuery.of(context);
                  return Stack(
                    children: [
                      MediaQuery(
                        data: mediaQuery.copyWith(textScaleFactor: 1.0),
                        child: child!,
                      ),
                      // Global notification overlay
                      const AppNotificationStack(),
                      // Global app status overlay (maintenance screen & force update)
                      const AppStatusOverlay(),
                      // Global connectivity overlay (no internet screen)
                      const ConnectivityOverlay(),
                    ],
                  );
                },
                title: FlavorConfig.instance.appTitle,
                debugShowCheckedModeBanner: false,
                // showPerformanceOverlay: true, // Removed in favor of custom overlay
                locale: languageService.getCurrentLocale(),
                themeMode: themeService.themeMode,
                theme: _buildLightTheme(),
                darkTheme: _buildDarkTheme(),
                // initialRoute: AppPages.GET_STARTED,
                getPages: AppPages.routes,
                home: const AuthCheckScreen(),
              ),
            ),
          );
        });
      },
    );
  }
}

/// Screen that checks authentication and navigates to the appropriate screen
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
    // testDecryption();
  }

  // void testDecryption() {
  //   try {
  //     final result = EncryptionHelper.decryptPayload(
  //       'LmpLtM1LChdA2Y/rI/nsk6dzGcO9IivZg5Au9d5n9cyNPdMrQIshEKVaBhk4lSs/uNSYVqr8lkACIwIOGAEUMNvYYFoiEPvHoFZxHsKnNhg6+N9LIVhAUOOPRmWLWeMm9eQhmbXBvEIgLk3/t+V420eUevC3A7JGkuEjvTFjv4Mcp3f8BKAJVvguFpwaGDvRV++Pxys8bn5QUWtJd5e+V3Cj2aT1P8nPb3o4GuzrD6KvzYaGia2mr170GCAbFPceMgUQ1Y3k7NNjuWWx+UjgsvaGVUlnOJK+cQAmwyAUOfFcRCCwAdOb+IW64OWnVrfFCzjTSd5gxNY6qjbVokjIlLeUc1qH4ym1yCI5Qs0/rOq9L9Ypmyb17pkmgIFnl0R7dJSwPZCmUzixSOCguQHLhltaJd2gNCTWMo8n1Y9vpuj7fZ11SJz2k/S9ztvP2b5vi6Q3jCPieC7A3sdmAAnLMV5upcy4fHpTt7uaGdNgtwBugf7cq9rI0JUvae+ctv2m', // payload
  //       'vYXxNGG/cNbEh7zBCUPhTg==', // iv
  //     );
  //     print('✅ DECRYPTED: $result');
  //   } catch (e) {
  //     print('❌ FAILED: $e');
  //   }
  // }

  Future<void> _checkAuthAndNavigate() async {
    try {
      unawaited(Get.find<AppStatusService>().checkAppStatus());

      final isLoggedIn = await SecureStorageService.isUserLoggedIn();
      await _applySavedTenaxBrokerSelection();
      if (await _shouldOpenTenaxBrokerSelection(isLoggedIn: isLoggedIn)) {
        NetworkStartupPhase.end();
        Get.offAllNamed(
          AppPages.TENAX_BROKER_SELECTION,
          arguments: {'allowBack': false, 'nextRoute': AppPages.LOGIN},
        );
        return;
      }

      print('AuthCheckScreen: User login status: $isLoggedIn');

      if (isLoggedIn) {
        // User is logged in, validate token before navigating
        print('AuthCheckScreen: Validating authentication token...');
        final authController = Get.find<AuthController>();
        await authController.checkAuthStatus();

        // Only navigate to trading if token is valid
        if (authController.isAuthenticated) {
          print(
            'AuthCheckScreen: User is authenticated, fetching accounts before navigation...',
          );

          // ✅ PRE-FETCH: Fetch primary account and store in helper before navigating
          try {
            final primaryAccount =
                await WebSocketEndpointHelper.fetchPrimaryAccount();
            if (primaryAccount != null) {
              WebSocketEndpointHelper.setPrimaryAccount(primaryAccount);
              print(
                'AuthCheckScreen: Primary account loaded: ${primaryAccount.metaAccountNumber}',
              );
            }
          } catch (e) {
            print('AuthCheckScreen: Error fetching accounts: $e');
          }

          print('AuthCheckScreen: Navigating to Trading screen (Home)');
          // End startup phase so normal 401 handling (session expired) resumes
          NetworkStartupPhase.end();
          Get.offAllNamed(AppPages.TRADING);
        } else {
          // Token validation failed, navigate to get started
          // (no session-expired toast — user was not actively using the app)
          print(
            'AuthCheckScreen: Token validation failed, navigating to Get Started',
          );
          // Clear any stale auth data
          await SecureStorageService.clearAuthData();
          // End startup phase before navigating
          NetworkStartupPhase.end();
          if (await _shouldSkipWelcomeForTenax()) {
            Get.offAllNamed(AppPages.LOGIN);
          } else {
            Get.offAllNamed(AppPages.GET_STARTED);
          }
        }
      } else {
        // User is not logged in, navigate to get started screen
        print(
          'AuthCheckScreen: User is not logged in, navigating to Get Started',
        );
        NetworkStartupPhase.end();
        if (await _shouldSkipWelcomeForTenax()) {
          Get.offAllNamed(AppPages.LOGIN);
        } else {
          Get.offAllNamed(AppPages.GET_STARTED);
        }
      }
    } catch (e) {
      print('AuthCheckScreen: Error checking auth status: $e');
      // On error, navigate to get started screen
      try {
        await SecureStorageService.clearAuthData();
      } catch (clearError) {
        print('AuthCheckScreen: Error clearing storage: $clearError');
      }
      NetworkStartupPhase.end();
      Get.offAllNamed(AppPages.GET_STARTED);
    }
  }

  Future<void> _applySavedTenaxBrokerSelection() async {
    if (!FlavorConfig.isMultiBrokerEnabled) {
      return;
    }

    final selectedBroker = await SecureStorageService.getTenaxBrokerSelection();
    if (selectedBroker == null) {
      return;
    }

    final selectedName =
        (selectedBroker['selected_name'] ??
                selectedBroker['name'] ??
                selectedBroker['brandName'] ??
                '')
            .toString();
    final selectedLogo =
        (selectedBroker['selected_logo_local_path'] ??
                selectedBroker['selected_logo_url'] ??
                selectedBroker['logo_url'] ??
                '')
            .toString();
    final runtimeConfig =
        selectedBroker['broker_runtime_config'] is Map<String, dynamic>
            ? selectedBroker['broker_runtime_config'] as Map<String, dynamic>
            : selectedBroker;

    FlavorConfig.applyTenaxBrokerRuntimeConfig(
      config: runtimeConfig,
      brokerName: selectedName.isNotEmpty ? selectedName : null,
      brokerLogoUrl: selectedLogo.isNotEmpty ? selectedLogo : null,
      brokerData: selectedBroker,
    );
  }

  Future<bool> _shouldOpenTenaxBrokerSelection({
    required bool isLoggedIn,
  }) async {
    if (!FlavorConfig.isMultiBrokerEnabled) return false;
    final isEnabled = await SecureStorageService.getTenaxBrokerSelectionFlag();
    if (!isEnabled) return false;
    if (FlavorConfig.isTenaxBrokerDemoEnabled &&
        await SecureStorageService.hasTenaxBrokerSelection()) {
      return false;
    }
    return !isLoggedIn;
  }

  Future<bool> _shouldSkipWelcomeForTenax() async {
    if (!FlavorConfig.isMultiBrokerEnabled) return false;
    final isEnabled = await SecureStorageService.getTenaxBrokerSelectionFlag();
    if (!isEnabled) return false;
    if (FlavorConfig.isTenaxBrokerDemoEnabled) {
      return await SecureStorageService.hasTenaxBrokerSelection();
    }
    return SecureStorageService.hasTenaxBrokerSelection();
  }

  @override
  Widget build(BuildContext context) {
    // Show neutral loading UI while async auth check runs.
    // Prevents SR flavor's red background "flash" before GetStarted.
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // SvgPicture.asset(FlavorConfig.instance.splashLogoPath),
            const SizedBox(height: 24),
            // const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

/// Initialize logging system based on environment
void _initializeLogging() {
  // Check if running in debug mode
  bool isDebugMode = false;
  assert(isDebugMode = true);

  if (isDebugMode) {
    // Development mode - enable all logs
    AppLogger.enableAllLogs();
    AppLogger.debug('App started in DEBUG mode - All logs enabled');
  } else {
    // Production mode - only errors and warnings
    AppLogger.enableProductionLogging();
    AppLogger.error('App started in PRODUCTION mode - Error logs only');
  }

  // Disable InAppWebView debug logging
  try {
    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;
    AppLogger.debug('InAppWebView debug logging disabled');
  } catch (e) {
    AppLogger.error('Failed to disable InAppWebView debug logging: $e');
  }

  // Log app initialization
  AppLogger.chart('Chart system ready');
  AppLogger.websocket('WebSocket system ready');
}

/// Auto-detect and initialize the correct flavor based on build configuration
Future<void> _initializeFlavor() async {
  // Tenax-only: keep the env var read for compatibility with existing scripts,
  // but always initialize Tenax configuration.
  const flavorFromDefine = String.fromEnvironment('FLAVOR', defaultValue: '');
  if (flavorFromDefine.isNotEmpty && flavorFromDefine.toLowerCase() != 'tenax') {
    AppLogger.error(
      'Ignoring unsupported flavor "$flavorFromDefine" (Tenax-only build).',
    );
  }

  FlavorConfig.tenax;
  AppLogger.debug('Flavor initialized: tenax');
}

// adb --version
// flutter doctor
