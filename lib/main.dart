import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

void main() async {
  // 🎨 AUTO-DETECT FLAVOR FROM BUILD CONFIGURATION
  // The flavor is automatically detected from the build command
  // Example: flutter build apk --flavor afx -t lib/main.dart

  // Reset any previous flavor configuration
  FlavorConfig.reset();

  // Auto-detect and initialize the correct flavor
  _initializeFlavor();

  WidgetsFlutterBinding.ensureInitialized();

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
  // Register services
  final languageService = Get.put<LanguageService>(
    LanguageService(),
    permanent: true,
  );
  await languageService.ensureInitialized();
  Get.put<AuthService>(AuthServiceImpl(), permanent: true);
  Get.put<AccountService>(AccountServiceImpl(), permanent: true);
  Get.put<LoadingService>(LoadingService(), permanent: true);

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  Get.put<NotificationService>(notificationService, permanent: true);

  // Register controllers in proper order
  Get.put<AuthController>(AuthController(), permanent: true);

  // ✅ FIX: Fetch accounts FIRST if user is authenticated
  try {
    final authController = Get.find<AuthController>();
    final isLoggedIn = await SecureStorageService.isUserLoggedIn();

    if (isLoggedIn) {
      // Validate auth status first
      await authController.checkAuthStatus();

      if (authController.isAuthenticated) {
        print('initServices: User authenticated, fetching accounts...');
        // Fetch primary account and store in helper
        final primaryAccount =
            await WebSocketEndpointHelper.fetchPrimaryAccount();
        if (primaryAccount != null) {
          WebSocketEndpointHelper.setPrimaryAccount(primaryAccount);
          print(
            'initServices: Primary account loaded: ${primaryAccount.metaAccountNumber} (${primaryAccount.tradingServer})',
          );
        } else {
          print('initServices: No accounts found or API failed');
        }
      }
    }
  } catch (e) {
    print('initServices: Error fetching accounts: $e');
    // Continue anyway - accounts will be fetched later
  }

  // Initialize DashboardController first as AccountController depends on it
  Get.put<DashboardController>(DashboardController(), permanent: true);
  Get.put<AccountController>(AccountController(), permanent: true);
  Get.put<InstrumentsController>(InstrumentsController(), permanent: true);
  Get.put<ChartSocketController>(ChartSocketController(), permanent: true);
  Get.put<TradingController>(TradingController(), permanent: true);
  await PriceAlertService().initialize();

  // Initialize app notification controller for global notifications
  Get.put<AppNotificationController>(AppNotificationController(), permanent: true);
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
          final isRTL = languageService.isRTL();

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
                    ],
                  );
                },
                title: FlavorConfig.instance.appTitle,
                debugShowCheckedModeBanner: false,
                // showPerformanceOverlay: true, // Removed in favor of custom overlay
                locale: languageService.getCurrentLocale(),
                theme: ThemeData(
                  primaryColor: FlavorConfig.instance.primaryColor,
                  inputDecorationTheme: InputDecorationTheme(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
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
                    floatingLabelAlignment:
                        isRTL
                            ? FloatingLabelAlignment.start
                            : FloatingLabelAlignment.start,
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlavorConfig.instance.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 40.h),
                      // Removed maximumSize to avoid conflicts with SizedBox wrappers
                      // padding: EdgeInsets.symmetric(vertical: 16.h),
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
                  ),
                  listTileTheme: ListTileThemeData(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                    minLeadingWidth: 0,
                    leadingAndTrailingTextStyle: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textGrey,
                    ),
                  ),
                  drawerTheme: DrawerThemeData(
                    backgroundColor: Colors.white,
                    elevation: 16,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(20.r),
                        bottomRight: Radius.circular(20.r),
                      ),
                    ),
                  ),
                  bottomNavigationBarTheme: BottomNavigationBarThemeData(
                    backgroundColor: Colors.white,
                    selectedItemColor: FlavorConfig.instance.primaryColor,
                    unselectedItemColor: AppColors.textGrey,
                    type: BottomNavigationBarType.fixed,
                    elevation: 8,
                  ),
                ),
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
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      // Check if user is logged in
      final isLoggedIn = await SecureStorageService.isUserLoggedIn();
      print('AuthCheckScreen: User login status: $isLoggedIn');

      if (isLoggedIn) {
        // User is logged in, validate token before navigating
        print('AuthCheckScreen: Validating authentication token...');
        final authController = Get.find<AuthController>();
        await authController.checkAuthStatus();

        // Wait a moment to ensure auth state is updated
        // await Future.delayed(const Duration(milliseconds: 100));

        // Only navigate to trading if token is valid
        if (authController.isAuthenticated) {
          print(
            'AuthCheckScreen: User is authenticated, navigating to Trading screen (Home)',
          );
          // Navigate to trading screen (main home screen with bottom navigation)
          // Using offAllNamed to clear navigation stack and prevent back navigation
          Get.offAllNamed(AppPages.TRADING);
        } else {
          // Token validation failed, navigate to get started
          print(
            'AuthCheckScreen: Token validation failed, navigating to Get Started',
          );
          // Clear any stale auth data
          await SecureStorageService.clearAuthData();
          Get.offAllNamed(AppPages.GET_STARTED);
        }
      } else {
        // User is not logged in, navigate to get started screen
        print(
          'AuthCheckScreen: User is not logged in, navigating to Get Started',
        );
        Get.offAllNamed(AppPages.GET_STARTED);
      }
    } catch (e) {
      print('AuthCheckScreen: Error checking auth status: $e');
      // On error, navigate to get started screen
      // Clear any potentially corrupted auth data
      try {
        await SecureStorageService.clearAuthData();
      } catch (clearError) {
        print('AuthCheckScreen: Error clearing storage: $clearError');
      }
      Get.offAllNamed(AppPages.GET_STARTED);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a minimal loading screen while checking auth
    return Scaffold(
      backgroundColor: FlavorConfig.instance.primaryColor,
      body: const Center(child: SizedBox.shrink()),
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
void _initializeFlavor() {
  // Try to detect flavor from build configuration
  // The flavor is passed via --dart-define=FLAVOR=afx or through build.gradle
  const flavorFromDefine = String.fromEnvironment('FLAVOR', defaultValue: '');

  if (flavorFromDefine.isNotEmpty) {
    // Flavor specified via --dart-define
    _initializeFlavorByName(flavorFromDefine);
    AppLogger.debug('Flavor initialized from dart-define: $flavorFromDefine');
  } else {
    // Fallback: Try to detect from package name or use default
    // For now, default to app if no flavor is specified
    FlavorConfig.pipze;
    AppLogger.debug('Flavor initialized: pipze (default)');
  }
}

/// Initialize flavor by name
void _initializeFlavorByName(String flavorName) {
  switch (flavorName.toLowerCase()) {
    case 'afx':
      FlavorConfig.afx;
      break;
    case 'pipze':
      FlavorConfig.pipze;
      break;
    case 'octa':
      FlavorConfig.octa;
      break;
    case 'tenax':
      FlavorConfig.tenax;
      break;
    case 'onsa':
      FlavorConfig.onsa;
      break;
    case 'profx':
      FlavorConfig.profx;
      break;
    case 'tradoxy':
      FlavorConfig.tradoxy;
      break;
    default:
      FlavorConfig.pipze; // Default fallback
      AppLogger.error('Unknown flavor: $flavorName, using pipze as default');
  }
}
// adb --version
// flutter doctor
