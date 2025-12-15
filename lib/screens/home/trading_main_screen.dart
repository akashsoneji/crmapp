import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/services/language_service.dart';
import 'package:pipze/utils/rtl_wrapper.dart';
import 'package:pipze/widgets/exit_confirmation_wrapper.dart';
import '../../widgets/trading_bottom_navigation.dart';
import 'instruments_screen.dart';
import 'chart_screen.dart';
import 'more/more_screen.dart';
import 'trade_screen.dart';
import 'dashboard_screen.dart';
import '../../controllers/instruments_controller.dart';
import '../../controllers/trading_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/more/more_controller.dart';

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

  // Callback to switch to chart tab and set symbol
  void _switchToChartTab(String symbol) {
    print('🚀 TradingMainScreen: Switching to chart tab with symbol: $symbol');
    try {
      setState(() {
        _currentIndex = 1; // Chart screen is at index 1
      });
      print('🚀 TradingMainScreen: Chart tab index set to 1');
      ChartScreen.setSelectedSymbol(symbol);
      print('🚀 TradingMainScreen: Symbol passed to ChartScreen');
    } catch (e) {
      print('🚨 TradingMainScreen: Error switching to chart tab: $e');
    }
  }

  // Callback to switch to trade tab
  // Optional initialTab parameter: null = default to Market (0), or specify tab index (0=Market, 1=Pending, 2=Close)
  void _switchToTradeTab([int? initialTab]) {
    setState(() {
      _currentIndex = 2; // Trade screen is at index 2
    });
    // Set the initial tab: use provided initialTab, or default to Market tab (0)
    // Use a slightly longer delay to ensure it runs after TradeScreen.initState()
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 50), () {
        if (Get.isRegistered<TradingController>()) {
          final tradingController = Get.find<TradingController>();
          final tabToSet =
              initialTab ?? 0; // Default to Market tab if not specified
          tradingController.setSelectedTab(tabToSet);
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _screens = [
      // Pass the callback to InstrumentsScreen
      InstrumentsScreen(onNavigateToChart: _switchToChartTab),
      ChartScreen(onNavigateToTrade: _switchToTradeTab),
      TradeScreen(onNavigateToChart: _switchToChartTab),
      DashboardScreen(
        onNavigateToTab: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      const MoreScreen(),
    ];

    // ✅ WebSocket connections now auto-start and stay active across all screens
    // No need to manually start/stop on tab changes
  }

  // Handle tab changes and manage WebSocket connections
  void _onTabChanged(int index) {
    final int previousIndex = _currentIndex;

    setState(() {
      _currentIndex = index;
    });

    // Reset to Market tab when switching to Trade screen (index 2) via bottom navigation
    // Only reset if user manually switched from a different screen (not already on Trade screen)
    if (index == 2 && previousIndex != 2) {
      // User manually switched to Trade screen from another screen via bottom nav
      // Reset to Market tab (default behavior)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<TradingController>()) {
          final tradingController = Get.find<TradingController>();
          tradingController.setSelectedTab(0); // Reset to Market tab (index 0)
        }
      });
    }
    // If previousIndex == 2, we're already on Trade screen, so don't override the tab

    // Resubscribe dashboard WebSocket and refresh accounts when Dashboard tab (index 3) is tapped
    if (index == 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (Get.isRegistered<DashboardController>()) {
            final dashboardController = Get.find<DashboardController>();
            // Always call get account API when dashboard tab is tapped
            dashboardController.refreshMT5Accounts(force: true);
            // Also resubscribe WebSocket
            dashboardController.unsubscribeAndResubscribe();
          }
        } catch (e) {
          print('Error refreshing dashboard on tab switch: $e');
        }
      });
    }

    // Refresh More screen data when More tab (index 4) is tapped
    if (index == 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (Get.isRegistered<MoreController>()) {
            Get.find<MoreController>().loadMoreScreenData();
          }
        } catch (e) {
          print('Error refreshing More screen data: $e');
        }
      });
    }

    // ✅ REMOVED: Don't stop/start WebSockets on screen change
    // All WebSocket connections (market watch, open positions, pending orders, account)
    // should remain active across all screens for instant data availability
  }

  // ✅ REMOVED: WebSocket management methods no longer needed
  // All WebSocket connections stay active across all screens

  @override
  Widget build(BuildContext context) {
    return ExitConfirmationWrapper(
      forceExitDialog: true,
      child: RTLWrapper(
        child: Scaffold(
          backgroundColor: AppColors.tradeBackgroundCenterColor,
          // drawer: const GlobalDrawer(),
          body: SafeArea(
            child: IndexedStack(index: _currentIndex, children: _screens),
          ),

          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
          floatingActionButton: TradingBottomNavigation(
            currentIndex: _currentIndex,
            onTap: (index) {
              _onTabChanged(index);
            },
          ),
        ),
      ),
    );
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
