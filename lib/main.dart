import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/controllers/chart_socket_controller.dart';
import 'package:pipze/services/price_alert_service.dart';
import 'package:pipze/services/loading_service.dart';
import 'package:pipze/services/notification_service.dart';
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
import 'routes/app_pages.dart';
import 'screens/auth/splash/splash_screen.dart';
import 'widgets/exit_confirmation_wrapper.dart';
import 'utils/app_logger.dart';

void main() async {
  // 🎨 SELECT YOUR BRAND HERE - Change this line to switch brands!
  FlavorConfig.tenax; // 🟣 Purple theme
  // FlavorConfig.octa;   // 🟠 Orange theme
  // FlavorConfig.fleza; // 🟢 Green theme
  // FlavorConfig.onsa; // 🟣 Purple theme
  //text direction
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
  Get.put<LanguageService>(LanguageService(), permanent: true);
  Get.put<AuthService>(AuthServiceImpl(), permanent: true);
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
                  return MediaQuery(
                    data: mediaQuery.copyWith(textScaleFactor: 1.0),
                    child: child!,
                  );
                },
                title: FlavorConfig.instance.appTitle,
                debugShowCheckedModeBanner: false,
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
                initialRoute: AppPages.SPLASH,
                getPages: AppPages.routes,
                home: const SplashScreen(),
              ),
            ),
          );
        });
      },
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
  AppLogger.trading('Pipze Trading App initialized');
  AppLogger.chart('Chart system ready');
  AppLogger.websocket('WebSocket system ready');
}
