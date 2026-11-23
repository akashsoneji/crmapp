import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/screens/home/trade_screen.dart';
import 'package:crm_app/services/chart_webview_prewarmer.dart';
import 'package:crm_app/flavor_config.dart';
import 'package:crm_app/services/symbol_selection_service.dart';
import 'package:crm_app/utils/rtl_wrapper.dart';
import 'package:crm_app/widgets/exit_confirmation_wrapper.dart';
import 'package:crm_app/widgets/chart/app_tenax_chart.dart';
import '../../widgets/trading_bottom_navigation_new.dart';
import 'instruments_screen_new.dart';
import 'trading_main_screen.dart' show KeepAliveWrapper;
import 'chart_screen.dart';
import 'more/more_screen.dart';
import 'dashboard_screen.dart';
import '../../controllers/instruments_controller.dart';
import '../../controllers/trading_controller.dart';

import '../../controllers/more/more_controller.dart';
import '../../services/one_click_trading_service.dart';
import '../../services/app_status/app_status_service.dart';

/// Tenaxnew home shell (TSK-0165 redesign). Other flavors use
/// [TradingMainScreen]; [TradingHomeScreen] picks between them.
class TradingMainScreenNew extends StatefulWidget {
  const TradingMainScreenNew({super.key});

  @override
  State<TradingMainScreenNew> createState() => _TradingMainScreenNewState();
}

class _TradingMainScreenNewState extends State<TradingMainScreenNew> {
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
      print(
        '🚀 TradingMainScreen: Chart tab index set to 1 and PageView navigated',
      );
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

    // LEGACY_CHART_START — pre-warms the remote chart page; the bundled
    // Tenax chart has nothing remote to warm.
    // ✅ PERFORMANCE OPTIMIZATION: Pre-warm the chart WebView in background
    if (!AppTenaxChart.isSupported) {
      ChartWebViewPrewarmer.instance.prewarm(symbol: 'XAUUSD');
    }
    // LEGACY_CHART_END

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

    // ✅ FIX: Reusable callback so each child screen's AccountHeaderWidget
    // can request a tab switch (e.g. menu icon → last tab index 4).
    final void Function(int) navigateToTab = _onTabChanged;

    _screens = [
      // Pass the callback to InstrumentsScreen
      KeepAliveWrapper(
        child: InstrumentsScreenNew(
          onNavigateToChart: _switchToChartTab,
          onNavigateToTab: navigateToTab,
        ),
      ),
      KeepAliveWrapper(
        child: ChartScreen(
          onNavigateToTrade: _switchToTradeTab,
          onNavigateToTab: navigateToTab,
        ),
      ),
      KeepAliveWrapper(
        child: TradeScreen(
          onNavigateToChart: _switchToChartTab,
          onNavigateToTab: navigateToTab,
        ),
      ),
      KeepAliveWrapper(child: DashboardScreen(onNavigateToTab: navigateToTab)),
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

  // LEGACY_CHART_START — pre-warm for the remote /mobile-chart page only.
  /// Android-only: Load chart URL in a hidden WebView to:
  /// 1. Pre-warm the WebView renderer process (biggest win — saves 3-5s)
  /// 2. Cache chart HTML/JS/CSS so visible WebView loads from cache
  Future<void> _preloadChartWebViewAndroid() async {
    if (!Platform.isAndroid) return;
    if (!mounted) return;
    // The bundled Tenax chart ships in the APK; there is no remote page to cache.
    if (AppTenaxChart.isSupported) return;

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

      print(
        '📱 Android Chart Preload: Starting headless WebView for $chartUrl',
      );

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
  // LEGACY_CHART_END

  // Ensure one-click trading is enabled (safety net)
  Future<void> _ensureOneClickTradingEnabled() async {
    try {
      final isEnabled = await OneClickTradingService.instance
          .isOneClickTradingEnabled();
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
    return ExitConfirmationWrapper(
      forceExitDialog: true,
      child: RTLWrapper(child: _buildScaffold()),
    );
  }

  /// Same docked tab bar on Android and iOS, so both match the design.
  Widget _buildScaffold() {
    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      body: _buildPageView(),
      bottomNavigationBar: TradingBottomNavigationNew(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
      ),
    );
  }

  Widget _buildPageView() {
    // The home tab paints its purple header under the status bar itself.
    return SafeArea(
      top: _currentIndex != 0,
      child: PageView(
        controller: _pageController,
        onPageChanged: _onTabChanged,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),
    );
  }
}