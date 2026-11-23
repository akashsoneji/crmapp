// Tenaxnew home tab (TSK-0165 redesign). Other flavors use instruments_screen.dart.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';

import 'package:crm_app/controllers/account_controller.dart';
import 'package:crm_app/controllers/dashboard_controller.dart';
import 'package:crm_app/controllers/instruments_controller.dart';
import 'package:crm_app/controllers/ib_controller.dart';

import 'package:crm_app/models/socket_response.dart';
import 'package:crm_app/routes/app_pages.dart';
import 'package:crm_app/screens/home/more/promotional/promotional_screen.dart';
import 'package:crm_app/screens/ibm/view_models/ibm_controller.dart';
import 'package:crm_app/services/enabled_modules_service.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/utils/svg_color_helper.dart';
import '../../widgets/banner_carousel.dart';
import '../../widgets/common_loading_widget.dart';
import '../../widgets/home/feature_panel.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/instrument_trade_card.dart';
import '../../widgets/home/invite_banner_card.dart';
import '../../widgets/home/quick_actions_grid.dart';
import '../../widgets/home/ticker_cards_row.dart';
import 'chart_screen.dart';
import '../../widgets/home/sheets/instrument_search_sheet_new.dart';
import 'package:crm_app/services/symbol_selection_service.dart';
import 'package:crm_app/services/market_watch_v2_service.dart';

class InstrumentsScreenNew extends StatefulWidget {
  final Function(String)? onNavigateToChart;
  final Function(int)? onNavigateToTab; // Bottom navigation index (0..4)

  const InstrumentsScreenNew({
    super.key,
    this.onNavigateToChart,
    this.onNavigateToTab,
  });

  @override
  State<InstrumentsScreenNew> createState() => _InstrumentsScreenNewState();
}

class _InstrumentsScreenNewState extends State<InstrumentsScreenNew>
    with AutomaticKeepAliveClientMixin {
  final InstrumentsController _controller = Get.put(InstrumentsController());
  final List<String> _sortOptions = ['Default', 'Symbol A-Z', 'Symbol Z-A'];
  final LanguageService languageService = Get.find<LanguageService>();
  final SymbolSelectionService _symbolSelectionService =
      Get.find<SymbolSelectionService>();
  late final IBController _ibController = Get.isRegistered<IBController>()
      ? Get.find<IBController>()
      : Get.put(IBController());

  late final Future<Widget> _swipeDeleteIconFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller.markInitialScreenOpening();
    _swipeDeleteIconFuture = SvgColorHelper.loadSvgWithColor(
      assetPath: 'assets/svg/delete.svg',
      targetColor: AppColors.onColoredBackground,
      colorToReplace: '#000000',
    );
    _listenToPriceUpdates();
    // Explicit `marketwatchv2` WS: this tab opens the session (auth + subscribe when favorites exist).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureMarketWatchV2ForTab();
      _ibController.getBanners(showLoading: false);
    });

    // NOTE: Unified legacy market-watch WS lifecycle is still managed by AccountController.
  }

  /// Opens `ws/marketwatchv2` from this tab.
  ///
  /// First tab entry must hydrate the favorite instrument rows before subscribing
  /// prices. If we only subscribe ticks here, the list stays empty until the first
  /// tick and the UI can briefly show the empty/no-data container. Hydrating via
  /// the controller keeps the loader visible and then shows data directly.
  Future<void> _ensureMarketWatchV2ForTab() async {
    final ic = _controller;
    final deadline = DateTime.now().add(const Duration(milliseconds: 400));
    while (ic.isLoadingFavorites.value && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }

    try {
      await ic.startMarketWatchV2Only();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // NOTE: WebSocket initialization is handled centrally by AccountController.setActiveMT5Account()
    // DO NOT call ensureWebSocketInitialized() here - it causes redundant refreshes on every build

    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      // Top inset is painted by HomeHeader so the purple runs under the status bar.
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildWebSocketStarter(),
            HomeHeader(
              onSearchTap: _openSearchSheet,
              onNotificationTap: () => Get.toNamed(AppPages.NOTIFICATIONS),
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  _controller.notifyUserScrollActivity();
                  return false;
                },
                child: CustomScrollView(
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildTopSections()),
                    SliverToBoxAdapter(child: _buildWatchlistHeader()),
                    Obx(() {
                      final controller = _controller;
                      final isFetching =
                          controller.isLoadingFavorites.value ||
                          controller.isHydratingInstrumentCatalog.value ||
                          !controller.hasAttemptedInitialLoad.value;
                      // Every re-hydrate (tab entry, chart open, account switch,
                      // reconnect) flips the loading flags. Once rows exist they
                      // stay on screen and only their prices tick; the loader is
                      // for a first load with nothing to show yet.
                      final showInitialLoader =
                          isFetching && controller.instruments.isEmpty;
                      if (showInitialLoader) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.h),
                            child: Center(
                              child: CommonLoadingWidget(
                                message: 'Loading instruments...',
                                size: 50.0,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        );
                      }
                      if (controller.instruments.isEmpty) {
                        return SliverToBoxAdapter(child: _buildNoData());
                      }
                      return _buildInstrumentsSliver(controller.instruments);
                    }),
                    SliverToBoxAdapter(
                      child: SizedBox(height: 6.h),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `marketwatchv2` WebSocket — outgoing JSON requests + incoming decoded frames.
  Widget _buildMarketWatchV2DecodedPanel() {
    if (!Get.isRegistered<MarketWatchV2Service>()) {
      return const SizedBox.shrink();
    }
    final svc = Get.find<MarketWatchV2Service>();
    return Obx(() {
      final text = svc.decodedLog.value;
      return SizedBox(
        height: 160.h,
        child: Material(
          color: AppColors.border.withValues(alpha: 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(8.w, 6.h, 8.w, 2.h),
                child: Text(
                  'marketwatchv2 (request / response)',
                  style: AppTextStyles.subheading.copyWith(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGrey,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 6.h),
                  child: SelectableText(
                    text.isEmpty
                        ? '(no traffic yet — waiting for auth token or network)'
                        : text,
                    style: AppTextStyles.subheading.copyWith(
                      fontSize: 9.sp,
                      height: 1.25,
                      color: AppColors.textGrey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// The old AccountHeaderWidget started the dashboard WebSocket once the
  /// primary account was known and re-ran it whenever the connection state or
  /// account info changed (a reconnect watchdog). Live prices depend on it,
  /// so this observes exactly the same values.
  Widget _buildWebSocketStarter() {
    final accountController = Get.find<AccountController>();
    final DashboardController? dashboardController =
        Get.isRegistered<DashboardController>()
        ? Get.find<DashboardController>()
        : null;

    return Obx(() {
      final primaryAccount =
          accountController.activeMT5Account ??
          dashboardController?.primaryMT5Account;
      final accountInfoMap = dashboardController?.accountInfoMap;
      if (primaryAccount != null && accountInfoMap != null) {
        // Read the entry so GetX tracks account-info updates.
        accountInfoMap[primaryAccount.metaAccountNumber];
      }
      // Tracked so a dropped connection triggers ensureWebSocketInitialized again.
      dashboardController?.isWebSocketConnected;
      dashboardController?.isLoadingMT5Accounts.value;
      if (primaryAccount != null && dashboardController != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          dashboardController.ensureWebSocketInitialized();
        });
      }
      return const SizedBox.shrink();
    });
  }

  void _openSearchSheet() {
    InstrumentSearchSheetNew.show(
      context,
      onNavigateToChart: widget.onNavigateToChart,
    );
  }

  /// Everything above the watchlist: invite card, promo banners, tickers,
  /// quick actions and the feature panel.
  Widget _buildTopSections() {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(12.w, 12.h, 12.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() {
            if (_ibController.banners.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(top: 10.h),
              child: BannerCarousel(banners: _ibController.banners),
            );
          }),
          SizedBox(height: 12.h),
          Obx(() {
            final symbols = _controller.instruments
                .take(TickerCardsRow.maxCards)
                .map((e) => e.symbol)
                .toList();
            return TickerCardsRow(
              symbols: symbols,
              controller: _controller,
              onSymbolTap: _navigateToChartWithSymbol,
            );
          }),
          _buildShortcutSections(),
        ],
      ),
    );
  }

  /// Quick actions + feature panel. Rebuilds when the broker's module flags
  /// load or change, so tiles appear/disappear without a restart.
  Widget _buildShortcutSections() {
    Widget sections() => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 12.h),
        QuickActionsGrid(
          onShortcutTap: _onShortcutTap,
          isVisible: _isShortcutVisible,
        ),
        SizedBox(height: 12.h),
        FeaturePanel(
          onShortcutTap: _onShortcutTap,
          isVisible: _isShortcutVisible,
        ),
      ],
    );

    if (!Get.isRegistered<EnabledModulesService>()) return sections();
    final modulesService = Get.find<EnabledModulesService>();
    return Obx(() {
      modulesService.modules.value;
      return sections();
    });
  }

  Widget _buildWatchlistHeader() {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(16.w, 16.h, 16.w, 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              languageService.tr("watchlist_title"),
              style: AppTextStyles.heading.copyWith(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          _buildSortDropdown(),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Obx(() {
        // Use dynamic filters from controller (based on WebSocket categories)
        // Remove 'All' tab - only show Favorites and category filters
        final filters = [
          'Favorites',
          ..._controller.availableFilters.where(
            (f) => f != 'All' && f != 'Favorites',
          ),
        ];

        return Row(
          children: filters.map((filter) {
            final isSelected = filter == _controller.currentFilter.value;
            // Show favorites count for Favorites filter
            final displayText = filter == 'Favorites'
                ? 'Favorites (${_controller.favoritesCount})'
                : filter;
            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: GestureDetector(
                onTap: () {
                  _controller.filterInstruments(filter);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.selectedChipBackground
                        : AppColors.tradeBackgroundCenterColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.primary,
                    ),
                  ),
                  child: Text(
                    displayText,
                    style: AppTextStyles.input.copyWith(
                      fontSize: 13.sp,
                      height: 22 / 15,
                      color: isSelected
                          ? AppColors.selectedChipForeground
                          : AppColors.primary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  Widget _buildSortDropdown() {
    return GestureDetector(
      onTap: () {
        _showSortBottomSheet();
      },
      child: Obx(() {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'By ${_controller.currentSort.value}',
                style: AppTextStyles.input.copyWith(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  height: 22 / 15,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.keyboard_arrow_down,
                size: 16.h,
                color: AppColors.primary,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInstrumentsSliver(List<ListElement> instruments) {
    return SliverReorderableList(
      onReorderStart: (index) {
        HapticFeedback.heavyImpact();
      },
      onReorder: (oldIndex, newIndex) {
        _controller.reorderInstruments(oldIndex, newIndex);
      },
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final double animValue = Curves.easeInOut.transform(
              animation.value,
            );
            final double scale = 1.0 + (0.05 * animValue);
            final double elevation = 8.0 * animValue;

            return Transform.scale(
              scale: scale,
              child: Material(
                elevation: elevation,
                color: Colors.transparent,
                shadowColor: AppColors.border.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14.r),
                child: child,
              ),
            );
          },
          child: child,
        );
      },
      itemCount: instruments.length,
      itemBuilder: (context, index) {
        return _buildInstrumentItem(instruments[index], index);
      },
    );
  }

  Widget _buildInstrumentItem(ListElement instrument, int index) {
    Widget item = ReorderableDelayedDragStartListener(
      index: index,
      child: InstrumentTradeCard(
        symbol: instrument.symbol,
        controller: _controller,
        onTap: () => _navigateToChartWithSymbol(instrument.symbol),
      ),
    );

    // Only allow swipe to remove if we are in Favorites mode
    if (_controller.currentFilter.value == 'Favorites') {
      item = Dismissible(
        key: ValueKey('fav_${instrument.symbol}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: AlignmentDirectional.centerEnd,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: _buildSwipeDeleteIcon(),
        ),
        onDismissed: (direction) {
          // Remove from local list immediately to satisfy Dismissible requirements
          _controller.instruments.removeAt(index);
          // Then handle the persistent removal
          _controller.removeFromFavorites(instrument.symbol);
        },
        child: item,
      );
    }

    // Spacing sits outside the Dismissible so the red background is revealed
    // right from the card's edge, with no gap.
    return Padding(
      key: ValueKey('item_${instrument.symbol}'),
      padding: EdgeInsetsDirectional.fromSTEB(12.w, 0, 12.w, 10.h),
      child: item,
    );
  }

  void _navigateToChartWithSymbol(String symbol) {
    _symbolSelectionService.setSymbol(symbol);

    // Set the selected symbol for the chart screen
    ChartScreen.setSelectedSymbol(symbol);

    // Navigate to chart screen
    if (widget.onNavigateToChart != null) {
      widget.onNavigateToChart!(symbol);
    }
  }

  /// Swipe-delete affordance — uses [assets/svg/delete.svg] tinted white.
  Widget _buildSwipeDeleteIcon() {
    return FutureBuilder<Widget>(
      future: _swipeDeleteIconFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return SizedBox(width: 28.w, height: 28.h, child: snapshot.data);
        }
        return SizedBox(width: 28.w, height: 28.h);
      },
    );
  }

  // Listen to price updates from instruments controller
  void _listenToPriceUpdates() {
    // Real-time updates: InstrumentsController + unified market-watch WS.
  }

  // NOTE: _listenToAccountChanges() was removed
  // WebSocket account-switching is handled centrally by AccountController
  // Screen should only display data reactively via Obx(), not manage WebSocket lifecycle

  Widget _buildNoData() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // SvgPicture.asset('assets/svg/no_imge_icon.svg'),
            FutureBuilder<Widget>(
              future: SvgColorHelper.loadSvgWithColor(
                assetPath: 'assets/svg/no_imge_icon.svg',
                targetColor: AppColors.primary,
                colorToReplace: '#5F259E', // Replace this color in the SVG
                height: 100.h,
                width: 100.w,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasData) return snapshot.data!;
                return SizedBox(height: 100.h, width: 100.w);
              },
            ),
            SizedBox(height: 24.h),
            Obx(() {
              final isFavoritesFilter =
                  _controller.currentFilter.value == 'Favorites';
              return Text(
                isFavoritesFilter
                    ? languageService.tr("no_favorites_added")
                    : languageService.tr("common_no_data"),
                style: AppTextStyles.heading.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              );
            }),
            Obx(() {
              final isFavoritesFilter =
                  _controller.currentFilter.value == 'Favorites';
              return Text(
                isFavoritesFilter
                    ? languageService.tr("tap_circle_icon_to_add_instruments")
                    : languageService.tr("common_no_data_description"),
                style: AppTextStyles.subheading.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              );
            }),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.sheetHandle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Sort by',
                style: AppTextStyles.heading.copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 16.h),
              Obx(() {
                return Column(
                  children: [
                    ..._sortOptions.map((option) {
                      return Column(
                        children: [
                          ListTile(
                            title: Row(
                              children: [
                                Container(
                                  width: 24.w,
                                  height: 24.h,
                                  margin: EdgeInsets.all(8.sp),
                                  padding: EdgeInsets.all(2.sp),
                                  child: _getSortIcon(option),
                                ),
                                Text(option, style: AppTextStyles.input),
                              ],
                            ),
                            trailing: option == _controller.currentSort.value
                                ? Icon(Icons.check, color: AppColors.primary)
                                : null,
                            onTap: () {
                              _controller.sortInstruments(option);
                              Navigator.pop(context);
                            },
                          ),
                          Divider(color: AppColors.border, height: 1.h),
                        ],
                      );
                    }).toList(),
                  ],
                );
              }),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 0.1),
            ],
          ),
        );
      },
    );
  }

  Widget _getSortIcon(String option) {
    switch (option) {
      case 'Default':
        return Icon(Icons.view_list, size: 20.h, color: AppColors.textGrey);
      case 'Symbol A-Z':
        return Icon(Icons.sort_by_alpha, size: 20.h, color: AppColors.textGrey);
      case 'Symbol Z-A':
        return Icon(Icons.sort_by_alpha, size: 20.h, color: AppColors.textGrey);
      default:
        return Icon(Icons.sort, size: 20.h, color: AppColors.textGrey);
    }
  }

  /// Where a shortcut leads, or null when this broker has no such feature
  /// (module switched off, or the app has no screen for it). Null hides the
  /// tile. Flags mirror the More screen's gating.
  VoidCallback? _shortcutAction(HomeShortcut shortcut) {
    final modules = EnabledModulesService.flags;
    return switch (shortcut) {
      HomeShortcut.deposit => () => Get.toNamed(AppPages.DEPOSIT),
      HomeShortcut.demoContest => () => Get.toNamed(AppPages.DEMO_CONTEST),
      HomeShortcut.pamm =>
        modules.pmam ? () => Get.toNamed(AppPages.PMAM_MAIN) : null,
      HomeShortcut.ibDashboard => modules.ib ? _openIbDashboard : null,
      HomeShortcut.withdraw => () => Get.toNamed(AppPages.WITHDRAWAL),
      HomeShortcut.bonus => () => Get.toNamed(AppPages.BONUS),
      HomeShortcut.transfer => () => Get.toNamed(AppPages.INTERNAL_TRANSFER),
      HomeShortcut.history => () => Get.toNamed(AppPages.TRANSACTION_HISTORY),
      HomeShortcut.copyTrading =>
        modules.copytrading
            ? () => Get.toNamed(AppPages.COPY_TRADING_MAIN)
            : null,
      HomeShortcut.supportTickets => () => Get.toNamed(AppPages.TICKET_LIST),
      HomeShortcut.wallet => () => Get.toNamed(AppPages.WALLET),
      HomeShortcut.promotional => () => Get.to(
        () => const PromotionalScreen(),
        transition: Transition.rightToLeft,
      ),
      HomeShortcut.finance => () => Get.toNamed(AppPages.FINANCE),
      HomeShortcut.savings || HomeShortcut.liveStream => null,
    };
  }

  bool _isShortcutVisible(HomeShortcut shortcut) =>
      _shortcutAction(shortcut) != null;

  void _onShortcutTap(HomeShortcut shortcut) =>
      _shortcutAction(shortcut)?.call();

  Future<void> _openIbDashboard() async {
    final ibmController = Get.isRegistered<IbmController>()
        ? Get.find<IbmController>()
        : Get.put(IbmController());
    await ibmController.checkSystemAndNavigate();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
