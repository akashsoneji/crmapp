import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/services/language_service.dart';
import 'package:pipze/utils/rtl_wrapper.dart';
import '../../widgets/trading_bottom_navigation.dart';
import '../../widgets/global_drawer.dart';
import 'instruments_screen.dart';
import 'chart_screen.dart';
import 'trade_screen.dart';
import 'dashboard_screen.dart';
import 'more_screen.dart';
import '../../controllers/instruments_controller.dart';

class TradingMainScreen extends StatefulWidget {
  const TradingMainScreen({super.key});

  @override
  State<TradingMainScreen> createState() => _TradingMainScreenState();
}

class _TradingMainScreenState extends State<TradingMainScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;

  // Get the instruments controller
  final InstrumentsController instrumentsController =
      Get.find<InstrumentsController>();

  // Callback to switch to chart tab
  void _switchToChartTab() {
    setState(() {
      _currentIndex = 1; // Chart screen is at index 1
    });
  }

  @override
  void initState() {
    super.initState();
    _screens = [
      // Pass the callback to InstrumentsScreen
      InstrumentsScreen(onNavigateToChart: _switchToChartTab),
      const ChartScreen(),
      const TradeScreen(),
      const DashboardScreen(),
      const MoreScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return RTLWrapper(
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        drawer: const GlobalDrawer(),
        body: SafeArea(
          child: IndexedStack(index: _currentIndex, children: _screens),
        ),
        bottomNavigationBar: TradingBottomNavigation(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }

  String _getCurrentScreenTitle() {
    final languageService = Get.find<LanguageService>();
    switch (_currentIndex) {
      case 0:
        return languageService.tr("instruments_title");
      case 1:
        return languageService.tr("chart_title");
      case 2:
        return languageService.tr("trade_title");
      case 3:
        return languageService.tr("dashboard_title");
      case 4:
        return languageService.tr("more_title");
      default:
        return languageService.tr("app_name");
    }
  }
}

// Placeholder screen for other trading sections
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return RTLWrapper(
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.construction, size: 64.h, color: AppColors.textGrey),
                SizedBox(height: 16.h),
                Text(
                  title,
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  TranslationUtils.tr('common_coming_soon'),
                  style: AppTextStyles.subheading.copyWith(
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
