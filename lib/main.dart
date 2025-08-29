import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/services/price_alert_service.dart';
import 'package:pipze/services/loading_service.dart';
import 'package:pipze/services/notification_service.dart';
import 'constants/color.dart';
import 'flavor_config.dart';
import 'services/language_service.dart';
import 'controllers/auth_controller.dart';
import 'controllers/account_controller.dart';
import 'controllers/instruments_controller.dart';
import 'controllers/trading_controller.dart';
import 'services/auth_service.dart';
import 'services/account_service.dart';
import 'routes/app_pages.dart';
import 'screens/auth/splash/splash_screen.dart';

void main() async {
  // 🎨 SELECT YOUR BRAND HERE - Change this line to switch brands!
  // FlavorConfig.pipze;  // 🟣 Purple theme
  // FlavorConfig.octa;   // 🟠 Orange theme
  FlavorConfig.fleza; // 🟢 Green theme

  //text direction
  WidgetsFlutterBinding.ensureInitialized();

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

  // Register controllers
  Get.put<AuthController>(AuthController(), permanent: true);
  Get.put<AccountController>(AccountController(), permanent: true);
  Get.put<InstrumentsController>(InstrumentsController(), permanent: true);
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
            child: GetMaterialApp(
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
                    padding: EdgeInsets.symmetric(vertical: 16.h),
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
          );
        });
      },
    );
  }
}
