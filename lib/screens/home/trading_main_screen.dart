import 'dart:async';
import 'dart:io' show Platform;

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart' as adaptive;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/flavor_config.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/services/symbol_selection_service.dart';
import 'package:crm_app/utils/rtl_wrapper.dart';
import 'package:crm_app/widgets/exit_confirmation_wrapper.dart';
import '../../widgets/trading_bottom_navigation.dart';
import 'instruments_screen.dart';
import 'chart_screen.dart';
import 'more/more_screen.dart';
import 'trade_screen.dart';
import 'dashboard_screen.dart';
import '../../controllers/instruments_controller.dart';
import '../../controllers/trading_controller.dart';

import '../../controllers/more/more_controller.dart';
import '../../services/one_click_trading_service.dart';
import '../../services/app_status/app_status_service.dart';

class TradingMainScreen extends StatefulWidget {
  const TradingMainScreen({super.key});

  @override
  State<TradingMainScreen> createState() => _TradingMainScreenState();
}

class _TradingMainScreenState extends State<TradingMainScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;
  late PageController _pageController;

  // 🚀 Android-only: HeadlessInAppWebView to pre-warm the WebView renderer
  // and cache chart HTML/JS/CSS before user opens Chart tab.
  // iOS WKWebView doesn't need this — it starts fast natively.
  HeadlessInAppWebView? _headlessChartWebView;
  bool _headlessDisposed = false;

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
      if (_pageController.hasClients && _pageController.page?.round() != 1) {
        _pageController.jumpToPage(1);
      }
      print('🚀 TradingMainScreen: Chart tab index set to 1 and PageView navigated');
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
    if (_pageController.hasClients && _pageController.page?.round() != 2) {
      _pageController.jumpToPage(2);
    }
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

    // ✅ FIX: Check for initial tab index from navigation arguments
    // This allows navigating directly to a specific tab (e.g., dashboard at index 3)
    final arguments = Get.arguments;
    if (arguments != null && arguments is int) {
      // If argument is a valid tab index (0-4), set it
      if (arguments >= 0 && arguments <= 4) {
        _currentIndex = arguments;
        print('TradingMainScreen: Initial tab set to index $arguments');
      }
    }

    _pageController = PageController(initialPage: _currentIndex);

    _screens = [
      // Pass the callback to InstrumentsScreen
      KeepAliveWrapper(child: InstrumentsScreen(onNavigateToChart: _switchToChartTab)),
      KeepAliveWrapper(
        child: ChartScreen(
          onNavigateToTrade: _switchToTradeTab,
          onNavigateToTab: (index) {
            _onTabChanged(index);
          },
        ),
      ),
      KeepAliveWrapper(child: TradeScreen(onNavigateToChart: _switchToChartTab)),
      KeepAliveWrapper(
        child: DashboardScreen(
          onNavigateToTab: (index) {
            _onTabChanged(index);
          },
        ),
      ),
      const KeepAliveWrapper(child: MoreScreen()),
    ];

    // ✅ WebSocket connections now auto-start and stay active across all screens
    // No need to manually start/stop on tab changes

    // ✅ Safety net: Ensure one-click trading is enabled by default
    _ensureOneClickTradingEnabled();

    // 🚀 ANDROID CHART PRELOAD: Pre-warm Android WebView renderer + cache chart assets.
    // Android WebView has a cold-start renderer penalty (3-5s) that iOS doesn't.
    // HeadlessInAppWebView loads the chart URL silently in background so the
    // visible WebView on Chart tab starts with a warm renderer + cached assets.
    if (Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _preloadChartWebViewAndroid();
      });
    }

    // Ensure app update check runs after the main UI is mounted.
    // This covers the "already logged-in" flow where AuthCheckScreen may navigate
    // away quickly and a dialog can be dismissed by route changes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (!FlavorConfig.isMultiBrokerEnabled &&
            Get.isRegistered<AppStatusService>()) {
          unawaited(Get.find<AppStatusService>().checkAppStatus());
        }
      } catch (_) {}
    });

    // ✅ If initial tab is dashboard (index 3), refresh accounts
    // if (_currentIndex == 3) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     try {
    //       if (Get.isRegistered<DashboardController>()) {
    //         final dashboardController = Get.find<DashboardController>();
    //         dashboardController.refreshMT5Accounts(force: true);
    //         dashboardController.unsubscribeAndResubscribe();
    //       }
    //     } catch (e) {
    //       print('Error refreshing dashboard on initial load: $e');
    //     }
    //   });
    // }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _disposeHeadlessWebView();
    super.dispose();
  }

  void _disposeHeadlessWebView() {
    if (!_headlessDisposed && _headlessChartWebView != null) {
      _headlessDisposed = true;
      try {
        _headlessChartWebView!.dispose();
      } catch (_) {}
      _headlessChartWebView = null;
    }
  }

  /// Android-only: Load chart URL in a hidden WebView to:
  /// 1. Pre-warm the WebView renderer process (biggest win — saves 3-5s)
  /// 2. Cache chart HTML/JS/CSS so visible WebView loads from cache
  Future<void> _preloadChartWebViewAndroid() async {
    if (!Platform.isAndroid) return;
    if (!mounted) return;

    try {
      // Get default/saved symbol
      String symbol = 'XAUUSD';
      try {
        if (Get.isRegistered<SymbolSelectionService>()) {
          final svc = Get.find<SymbolSelectionService>();
          await svc.ensureDefault();
          if (svc.currentSymbol.isNotEmpty) symbol = svc.currentSymbol;
        }
      } catch (_) {}

      // Strip suffix for display (e.g. XAUUSD.c → XAUUSD)
      final displaySymbol = symbol.contains('.')
          ? symbol.substring(0, symbol.lastIndexOf('.'))
          : symbol;

      final chartUrl =
          '${FlavorConfig.instance.chartBaseUrl}/mobile-chart'
          '?symbol=$displaySymbol&theme=${AppColors.chartTheme}';

      print('📱 Android Chart Preload: Starting headless WebView for $chartUrl');

      _headlessChartWebView = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(chartUrl)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          cacheEnabled: true,
          cacheMode: CacheMode.LOAD_DEFAULT,
          // Use off-screen size so renderer fully initialises
          transparentBackground: true,
        ),
        onLoadStop: (controller, url) async {
          print('📱 Android Chart Preload: Chart assets cached ✅ ($url)');
          // Keep alive a moment so cache is flushed, then dispose
          await Future.delayed(const Duration(seconds: 2));
          _disposeHeadlessWebView();
        },
        onReceivedError: (controller, request, error) {
          print('📱 Android Chart Preload: Error (non-critical): $error');
          _disposeHeadlessWebView();
        },
      );

      await _headlessChartWebView!.run();
      print('📱 Android Chart Preload: Headless WebView running...');
    } catch (e) {
      print('📱 Android Chart Preload: Failed (non-critical): $e');
      _disposeHeadlessWebView();
    }
  }

  // Ensure one-click trading is enabled (safety net)
  Future<void> _ensureOneClickTradingEnabled() async {
    try {
      final isEnabled =
          await OneClickTradingService.instance.isOneClickTradingEnabled();
      if (!isEnabled) {
        await OneClickTradingService.instance.setOneClickTradingEnabled(true);
        print('TradingMainScreen: One-click trading enabled by default');
      }
    } catch (e) {
      print(
        'TradingMainScreen: Error ensuring one-click trading is enabled: $e',
      );
    }
  }

  // Handle tab changes and manage WebSocket connections
  void _onTabChanged(int index) {
    if (_currentIndex == index) return;

    final int previousIndex = _currentIndex;

    setState(() {
      _currentIndex = index;
    });

    if (_pageController.hasClients && _pageController.page?.round() != index) {
      _pageController.jumpToPage(index);
    }

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
          // IMPORTANT:
          // Do NOT force-refresh accounts or resubscribe sockets on simple tab switches.
          // This was causing unnecessary API calls / WS churn and visible refresh when
          // returning back to Instruments. Refresh should happen only on:
          // - explicit user actions (pull-to-refresh)
          // - explicit account switch
          // - app resume / reconnect handling inside controllers

          // Also re-check app update on dashboard open, so returning users
          // still get the popup when a new version is available.
          if (!FlavorConfig.isMultiBrokerEnabled &&
              Get.isRegistered<AppStatusService>()) {
            unawaited(Get.find<AppStatusService>().checkAppStatus());
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
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return ExitConfirmationWrapper(
      forceExitDialog: true,
      child: RTLWrapper(
        child: isIOS ? _buildIOSAdaptiveScaffold() : _buildAndroidScaffold(),
      ),
    );
  }

  Widget _buildAndroidScaffold() {
    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      // drawer: const GlobalDrawer(),
      body: _buildPageView(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      floatingActionButton: TradingBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          _onTabChanged(index);
        },
      ),
    );
  }

  Widget _buildIOSAdaptiveScaffold() {
    return adaptive.AdaptiveScaffold(
      body: _buildPageView(),
      resizeToAvoidBottomInset: false,
      enableBlur: true,
      minimizeBehavior: adaptive.TabBarMinimizeBehavior.never,
      bottomNavigationBar: adaptive.AdaptiveBottomNavigationBar(
        selectedIndex: _currentIndex,
        onTap: _onTabChanged,
        useNativeBottomBar: true,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textGreyLight,
        items: [
          adaptive.AdaptiveNavigationDestination(
            icon: _currentIndex == 0
                ? 'arrow.up.forward.app.fill'
                : 'arrow.up.forward.app',
            selectedIcon: 'arrow.up.forward.app.fill',
            label: TranslationUtils.tr('quote_title'),
          ),
          adaptive.AdaptiveNavigationDestination(
            icon: _currentIndex == 1 ? 'chart.bar.fill' : 'chart.bar',
            selectedIcon: 'chart.bar.fill',
            label: TranslationUtils.tr('chart_title'),
          ),
          adaptive.AdaptiveNavigationDestination(
            icon: _currentIndex == 2
                ? 'arrow.up.arrow.down.square.fill'
                : 'arrow.up.arrow.down.square',
            selectedIcon: 'arrow.up.arrow.down.square.fill',
            label: TranslationUtils.tr('trade_title'),
          ),
          adaptive.AdaptiveNavigationDestination(
            icon: _currentIndex == 3 ? 'wallet.bifold.fill' : 'wallet.bifold',
            selectedIcon: 'wallet.bifold.fill',
            label: TranslationUtils.tr('dashboard_title'),
          ),
          adaptive.AdaptiveNavigationDestination(
            icon: _currentIndex == 4 ? 'gearshape.fill' : 'gearshape',
            selectedIcon: 'gearshape.fill',
            label: TranslationUtils.tr('more_title'),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return SafeArea(
      child: PageView(
        controller: _pageController,
        onPageChanged: _onTabChanged,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
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

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}

