import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/services/language_service.dart';
import 'package:pipze/utils/rtl_wrapper.dart';
import 'package:pipze/widgets/exit_confirmation_wrapper.dart';
import '../../widgets/trading_bottom_navigation.dart';
import '../../widgets/global_drawer.dart';
import 'instruments_screen.dart';
import 'chart_screen.dart';
import 'more/more_screen.dart';
import 'trade_screen.dart';
import 'dashboard_screen.dart';
import '../../controllers/instruments_controller.dart';
import '../../controllers/chart_socket_controller.dart';
import '../../controllers/trading_controller.dart';
import '../../controllers/dashboard_controller.dart';

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
  void _switchToTradeTab() {
    setState(() {
      _currentIndex = 2; // Trade screen is at index 2
    });
    // Reset to Market tab when switching to trade screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<TradingController>()) {
        Get.find<TradingController>().setSelectedTab(0);
      }
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

    // Start WebSocket for initial tab (Instruments)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startWebSocketForTab(_currentIndex);
    });
  }

  // Handle tab changes and manage WebSocket connections
  void _onTabChanged(int index) {
    final int previousIndex = _currentIndex;

    setState(() {
      _currentIndex = index;
    });

    // Reset to Market tab when switching to Trade screen (index 2)
    if (index == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<TradingController>()) {
          Get.find<TradingController>().setSelectedTab(0);
        }
      });
    }

    // Unsubscribe and resubscribe WebSocket when dashboard tab (index 3) is tapped
    if (index == 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (Get.isRegistered<DashboardController>()) {
            Get.find<DashboardController>().unsubscribeAndResubscribe();
          }
        } catch (e) {
          print('Error resubscribing dashboard WebSocket: $e');
        }
      });
    }

    // Stop WebSocket for previous tab
    _stopWebSocketForTab(previousIndex);

    // Start WebSocket for new tab
    _startWebSocketForTab(index);
  }

  void _startWebSocketForTab(int index) {
    print('🔌 TradingMainScreen: Starting WebSocket for tab $index');
    switch (index) {
      case 0: // Instruments
        if (Get.isRegistered<InstrumentsController>()) {
          Get.find<InstrumentsController>().startWebSocket();
        }
        break;
      case 1: // Chart
        if (Get.isRegistered<ChartSocketController>()) {
          final controller = Get.find<ChartSocketController>();
          if (controller.currentSymbol.value.isNotEmpty) {
            controller.startWebSocket();
          }
        }
        break;
      // Other tabs don't use WebSocket
    }
  }

  void _stopWebSocketForTab(int index) {
    print('🔌 TradingMainScreen: Stopping WebSocket for tab $index');
    switch (index) {
      case 0: // Instruments
        if (Get.isRegistered<InstrumentsController>()) {
          Get.find<InstrumentsController>().stopWebSocket();
        }
        break;
      case 1: // Chart
        if (Get.isRegistered<ChartSocketController>()) {
          Get.find<ChartSocketController>().stopWebSocket();
        }
        break;
      // Other tabs don't use WebSocket
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExitConfirmationWrapper(
      forceExitDialog: true,
      child: RTLWrapper(
        child: Scaffold(
          backgroundColor: AppColors.backgroundLight,
          drawer: const GlobalDrawer(),
          body: SafeArea(
            child: IndexedStack(index: _currentIndex, children: _screens),
          ),
          bottomNavigationBar: TradingBottomNavigation(
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
