// lib/presentation/screens/instruments_screen.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';

import 'package:crm_app/controllers/instruments_controller.dart';
import 'package:crm_app/controllers/dashboard_controller.dart';
import 'package:crm_app/controllers/trading_controller.dart'; // ✅ ADD: For floating P&L

import 'package:crm_app/models/socket_response.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/utils/trl_helper.dart';
import 'package:crm_app/utils/precision_helper.dart';
import '../../widgets/account_header_widget.dart';
import '../../widgets/common_loading_widget.dart';
import '../auth/register/account_created_screen.dart';
import 'chart_screen.dart';
import 'dart:developer' as dev;
import '../../services/symbol_selection_service.dart';

class InstrumentsScreen extends StatefulWidget {
  final Function(String)? onNavigateToChart;

  const InstrumentsScreen({super.key, this.onNavigateToChart});

  @override
  State<InstrumentsScreen> createState() => _InstrumentsScreenState();
}

class _InstrumentsScreenState extends State<InstrumentsScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  // Filters are now dynamic - use _controller.availableFilters instead
  final List<String> _sortOptions = ['Default', 'Symbol A-Z', 'Symbol Z-A'];
  final InstrumentsController _controller = Get.put(InstrumentsController());
  final SymbolSelectionService _symbolSelectionService = Get.put(
    SymbolSelectionService(),
    permanent: true,
  );

  final LanguageService languageService = Get.put(LanguageService());
  bool _isSearching = false;
  Timer? _searchDebounceTimer;
  static const int _minSearchLength = 2; // Minimum characters before searching

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);

    // Ensure the last selected symbol is loaded from secure storage
    Future.microtask(() async {
      await _symbolSelectionService.ensureDefault();
    });

    // Listen to real-time price updates from instruments controller
    _listenToPriceUpdates();

    // Note: WebSocket will be started by TradingMainScreen when tab is switched to
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // ✅ FIX: Ensure DashboardController WebSocket is initialized in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (Get.isRegistered<DashboardController>()) {
          final dashboardController = Get.find<DashboardController>();
          dashboardController.ensureWebSocketInitialized();
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            'Instruments Screen: Error ensuring WebSocket initialization: $e',
          );
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      // drawer: const GlobalDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchAndFilters(),
            Expanded(
              child: Obx(() {
                final controller = _controller;
                // Show loading indicator while WebSocket is connecting and no data yet
                if (controller.allInstruments.isEmpty &&
                    !controller.isConnected.value) {
                  return Center(
                    child: CommonLoadingWidget(
                      message: 'Loading instruments...',
                      size: 50.0,
                      color: AppColors.primary,
                    ),
                  );
                }
                // Build list content (reactive - updates automatically when instruments list changes)
                if (controller.instruments.isEmpty) {
                  return _buildNoData();
                }
                return _buildInstrumentsList(controller.instruments);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    if (_isSearching) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
                _controller.searchInstruments('');
              },
              child: Icon(
                Icons.arrow_back,
                size: 24.h,
                color: AppColors.textGrey,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                textDirection: RTLHelper.textDirection,
                textAlign: RTLHelper.isRTL ? TextAlign.right : TextAlign.left,
                decoration: InputDecoration(
                  hintText: languageService.tr("instruments_search"),
                  hintStyle: AppTextStyles.input.copyWith(
                    color: AppColors.textGrey,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // ✅ Get floating P&L from trading controller
      final tradingController = Get.find<TradingController>();

      return Obx(() {
        final double? floatingProfit = tradingController.accountInfo?.profit;

        return AccountHeaderWidget(
          onSearchTap: () {
            setState(() {
              _isSearching = true;
            });
          },
          floatingProfit: floatingProfit, // ✅ ADD: Show floating P&L
        );
      });
    }
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                languageService.tr("instruments_title"),
                style: AppTextStyles.heading.copyWith(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 12.w),
              _buildSortDropdown(),
            ],
          ),
          SizedBox(height: 16.h),
          Row(children: [Expanded(child: _buildFilterButtons())]),
          SizedBox(height: 16.h),
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
          children:
              filters.map((filter) {
                final isSelected = filter == _controller.currentFilter.value;
                // Show favorites count for Favorites filter
                final displayText =
                    filter == 'Favorites'
                        ? 'Favorites (${_controller.favoritesCount})'
                        : filter;
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: GestureDetector(
                    onTap: () {
                      if (_isSearching) {
                        setState(() {
                          _isSearching = false;
                          _searchController.clear();
                        });
                      }
                      _controller.filterInstruments(filter);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppColors.primary
                                : AppColors.tradeBackgroundCenterColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : AppColors.primary,
                        ),
                      ),
                      child: Text(
                        displayText,
                        style: AppTextStyles.input.copyWith(
                          fontSize: 13.sp,
                          height: 22 / 15,
                          color:
                              isSelected
                                  ? AppColors.whiteColor
                                  : AppColors.primary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
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
                  color: AppColors.primary,
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

  Widget _buildInstrumentsList(List<ListElement> instruments) {
    // ✅ PERFORMANCE OPTIMIZATION: Calculate time ONCE for all items
    // Instead of calling DateTime.now() 50+ times (once per item)
    final currentTime = DateFormat('HH:mm:ss').format(DateTime.now());

    return ListView.builder(
      // Performance optimizations
      cacheExtent: 500, // Balanced cache size
      physics: const BouncingScrollPhysics(), // Smoother scrolling feel
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      // ✅ PERFORMANCE FIX: Use itemExtent instead of prototypeItem
      // More efficient - avoids building prototype widget
      itemExtent: 70.h, // Fixed height for each list item
      padding: EdgeInsets.only(
        bottom: 77.h + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: instruments.length,
      itemBuilder: (context, index) {
        final instrument = instruments[index];
        return _buildInstrumentItem(instrument, currentTime);
      },
    );
  }

  Widget _buildInstrumentItem(ListElement instrument, String currentTime) {
    // ✅ PERFORMANCE: Wrap entire item in RepaintBoundary
    // This isolates repaints - when one item updates, others don't repaint
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          _navigateToChartWithSymbol(instrument.symbol);
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(
            // color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: AppColors.border.withOpacity(0.3),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start, // ✅ Restore top alignment (like v5)
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 45.w,
                      constraints: BoxConstraints(minHeight: 42.h),
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.only(top: 2.h),
                      child: _buildFlagIcon(instrument.symbol),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _removeSymbolSuffix(instrument.symbol),
                            style: AppTextStyles.input.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          // ✅ PERFORMANCE FIX: Use pre-calculated time (passed as parameter)
                          Text(
                            currentTime,
                            style: AppTextStyles.subheading.copyWith(
                              fontSize: 10.sp,
                              color: AppColors.textGrey,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Row(
                            spacing: 2.w,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                'assets/svg/spread.svg',
                                width: 10.w,
                                height: 10.h,
                                // color: AppColors.textGrey,
                              ),
                              Flexible(
                                child: Text(
                                  _formatSpreadDiff(instrument.spreadDiff),
                                  style: AppTextStyles.subheading.copyWith(
                                    fontSize: 10.sp,
                                    color: AppColors.textGrey,
                                    height: 1.1,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ✅ PERFORMANCE: Extract Bid column into separate widget (reactive)
              Expanded(
                flex: 2,
                child: _BidPriceColumn(
                  symbol: instrument.symbol,
                  controller: _controller,
                  dayLow: instrument.dayLow,
                  digits: instrument.digits,
                ),
              ),
              SizedBox(width: 8.w), // ✅ Reduced gap for small devices
              // ✅ PERFORMANCE: Extract Ask column into separate widget (reactive)
              Expanded(
                flex: 2,
                child: _AskPriceColumn(
                  symbol: instrument.symbol,
                  controller: _controller,
                  dayHigh: instrument.dayHigh,
                  digits: instrument.digits,
                ),
              ),
              // Favorite button - Centered vertically relative to the row
              SizedBox(width: 6.w),
              Container(
                constraints: BoxConstraints(minHeight: 42.h),
                alignment: Alignment.topCenter,
                padding: EdgeInsets.only(top: 2.h),
                child: _FavoriteButton(
                  symbol: instrument.symbol,
                  controller: _controller,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToChartWithSymbol(String symbol) {
    dev.log('InstrumentsScreen: Navigating to chart with symbol: $symbol');

    _symbolSelectionService.setSymbol(symbol);

    // Set the selected symbol for the chart screen
    ChartScreen.setSelectedSymbol(symbol);
    dev.log('InstrumentsScreen: Set selected symbol to: $symbol');

    // Navigate to chart screen
    if (widget.onNavigateToChart != null) {
      dev.log(
        'InstrumentsScreen: Calling onNavigateToChart callback with symbol: $symbol',
      );
      widget.onNavigateToChart!(symbol);
    } else {
      dev.log('InstrumentsScreen: onNavigateToChart callback is null');
    }
  }

  // Listen to price updates from instruments controller
  void _listenToPriceUpdates() {
    // The instruments controller already handles real-time updates
    // and updates the instruments list automatically
    dev.log('InstrumentsScreen: Listening to price updates from controller');
  }

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
                  color: AppColors.grey,
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
                            trailing:
                                option == _controller.currentSort.value
                                    ? Icon(
                                      Icons.check,
                                      color: AppColors.primary,
                                    )
                                    : null,
                            onTap: () {
                              _controller.sortInstruments(option);
                              Navigator.pop(context);
                            },
                          ),
                          Divider(color: AppColors.grey, height: 1.h),
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

  // Helper method to remove symbol suffixes (.c, .r, etc.)
  // Handles both cases: symbols WITH suffix (EURUSD.c) and WITHOUT suffix (EURUSD)
  // Returns cleaned symbol for display purposes only
  String _removeSymbolSuffix(String symbol) {
    // If symbol has suffix (contains '.'), remove it
    // If symbol has no suffix, return as-is
    if (symbol.contains('.')) {
      return symbol.substring(0, symbol.lastIndexOf('.'));
    }
    return symbol; // No suffix, return original
  }

  String _formatSpreadDiff(double spreadDiff) {
    // Convert to string and remove leading zeros and decimal point
    String formatted = spreadDiff.toString();

    // Remove leading zeros and decimal point
    // For example: 0.00003 -> 3, 0.03 -> 3, 0.0012 -> 12
    if (formatted.contains('.')) {
      // Split by decimal point
      List<String> parts = formatted.split('.');
      String integerPart = parts[0];
      String decimalPart = parts[1];

      // If integer part is 0, remove it and leading zeros from decimal part
      if (integerPart == '0') {
        // Remove leading zeros from decimal part
        String trimmedDecimal = decimalPart.replaceFirst(RegExp(r'^0+'), '');
        return trimmedDecimal.isEmpty ? '0' : trimmedDecimal;
      } else {
        // If integer part is not 0, return it
        return integerPart;
      }
    }

    return formatted;
  }

  /// Get the flag SVG path based on the instrument symbol
  /// Extracts currency code from symbol (e.g., EURUSD -> EUR)
  /// Returns path like 'assets/svg/flags/eur.svg'
  String _getFlagPath(String symbol) {
    // Remove suffix if present (e.g., EURUSD.c -> EURUSD)
    String cleanSymbol =
        symbol.contains('.')
            ? symbol.substring(0, symbol.lastIndexOf('.'))
            : symbol;

    // Extract first currency code (typically first 3 characters)
    // For pairs like EURUSD, GBPUSD, etc.
    return 'assets/svg/flags/${cleanSymbol.toLowerCase()}.svg';
  }

  /// Build flag icon widget - Direct rendering for max performance
  Widget _buildFlagIcon(String symbol) {
    final flagPath = _getFlagPath(symbol);

    // Direct rendering without async checks
    // This eliminates the "freezing" caused by file I/O on the UI thread
    return Container(
      width: 40.w,
      height: 40.h,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: SvgPicture.asset(
          flagPath,
          width: 32.w,
          height: 32.h,
          fit: BoxFit.cover,
          // If asset is missing, it will just log a warning but won't crash/freeze
          placeholderBuilder: (context) => _buildFallbackFlag(),
        ),
      ),
    );
  }

  // Helper for fallback flag (used by placeholderBuilder)
  Widget _buildFallbackFlag() {
    return Container(
      width: 40.w,
      height: 40.h,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(Icons.flag, color: AppColors.primary, size: 20.w),
    );
  }

  void _onSearchTextChanged() {
    final query = _searchController.text;

    // Cancel previous timer if exists
    _searchDebounceTimer?.cancel();

    // If query is less than minimum length, clear search
    if (query.length < _minSearchLength) {
      _controller.searchInstruments('');
      return;
    }

    // Debounce: wait 300ms after user stops typing before searching
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _controller.searchInstruments(query);
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }
}

// ✅ PERFORMANCE: Separate widget for Bid price column
// Isolates repaints to only this column when bid price updates
class _BidPriceColumn extends StatelessWidget {
  final String symbol;
  final InstrumentsController controller;
  final double? dayLow;
  final int digits;

  const _BidPriceColumn({
    required this.symbol,
    required this.controller,
    required this.dayLow,
    required this.digits,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✅ PERFORMANCE FIX: Use Obx to observe only the bid price for this symbol
        // This ensures only the price text updates, not the entire widget
        Obx(() {
          final instrument = controller.allInstruments.firstWhereOrNull(
            (i) => i.symbol == symbol,
          );
          final bid = instrument?.bid ?? 0.0;
          return RichText(
            text: TextSpan(
              children: _buildPriceTextSpans(bid, AppColors.red, digits),
            ),
          );
        }),
        if (dayLow != null) ...[
          SizedBox(height: 1.h),
          RichText(
            textAlign: TextAlign.right,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'L: ',
                  style: AppTextStyles.subheading.copyWith(
                    fontSize: 9.sp,
                    color: AppColors.textGrey,
                    height: 1.0,
                  ),
                ),
                TextSpan(
                  text: PrecisionHelper.formatPrice(dayLow!, decimals: digits),
                  style: AppTextStyles.subheading.copyWith(
                    fontSize: 9.sp,
                    color: AppColors.textGrey,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<InlineSpan> _buildPriceTextSpans(
    dynamic price,
    Color color,
    int digits,
  ) {
    String priceStr = PrecisionHelper.formatPrice(price, decimals: digits);

    if (priceStr.length < 3) {
      return [
        TextSpan(
          text: priceStr,
          style: TextStyle(fontSize: 14.sp, color: color),
        ),
      ];
    }

    String lastDigit = priceStr.substring(priceStr.length - 1);
    String bigPart = "";
    String prefix = "";

    if (priceStr.length >= 3) {
      bigPart = priceStr.substring(priceStr.length - 3, priceStr.length - 1);
      prefix = priceStr.substring(0, priceStr.length - 3);
    } else {
      prefix = priceStr.substring(0, priceStr.length - 1);
    }

    return [
      TextSpan(
        text: prefix,
        style: TextStyle(
          fontSize: 14.sp,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      TextSpan(
        text: bigPart,
        style: TextStyle(
          fontSize: 20.sp,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      WidgetSpan(
        alignment: PlaceholderAlignment.top,
        child: Transform.translate(
          offset: const Offset(0, -4),
          child: Text(
            lastDigit,
            style: TextStyle(
              fontSize: 10.sp,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    ];
  }
}

// ✅ PERFORMANCE: Separate widget for Ask price column
// Isolates repaints to only this column when ask price updates
class _AskPriceColumn extends StatelessWidget {
  final String symbol;
  final InstrumentsController controller;
  final double? dayHigh;
  final int digits;

  const _AskPriceColumn({
    required this.symbol,
    required this.controller,
    required this.dayHigh,
    required this.digits,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✅ PERFORMANCE FIX: Use Obx to observe only the ask price for this symbol
        // This ensures only the price text updates, not the entire widget
        Obx(() {
          final instrument = controller.allInstruments.firstWhereOrNull(
            (i) => i.symbol == symbol,
          );
          final ask = instrument?.ask ?? 0.0;
          return RichText(
            text: TextSpan(
              children: _buildPriceTextSpans(ask, AppColors.green, digits),
            ),
          );
        }),
        if (dayHigh != null) ...[
          SizedBox(height: 1.h),
          RichText(
            textAlign: TextAlign.left,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'H: ',
                  style: AppTextStyles.subheading.copyWith(
                    fontSize: 9.sp,
                    color: AppColors.textGrey,
                    height: 1.0,
                  ),
                ),
                TextSpan(
                  text: PrecisionHelper.formatPrice(dayHigh!, decimals: digits),
                  style: AppTextStyles.subheading.copyWith(
                    fontSize: 9.sp,
                    color: AppColors.textGrey,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<InlineSpan> _buildPriceTextSpans(
    dynamic price,
    Color color,
    int digits,
  ) {
    String priceStr = PrecisionHelper.formatPrice(price, decimals: digits);

    if (priceStr.length < 3) {
      return [
        TextSpan(
          text: priceStr,
          style: TextStyle(fontSize: 14.sp, color: color),
        ),
      ];
    }

    String lastDigit = priceStr.substring(priceStr.length - 1);
    String bigPart = "";
    String prefix = "";

    if (priceStr.length >= 3) {
      bigPart = priceStr.substring(priceStr.length - 3, priceStr.length - 1);
      prefix = priceStr.substring(0, priceStr.length - 3);
    } else {
      prefix = priceStr.substring(0, priceStr.length - 1);
    }

    return [
      TextSpan(
        text: prefix,
        style: TextStyle(
          fontSize: 14.sp,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      TextSpan(
        text: bigPart,
        style: TextStyle(
          fontSize: 20.sp,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      WidgetSpan(
        alignment: PlaceholderAlignment.top,
        child: Transform.translate(
          offset: const Offset(0, -4),
          child: Text(
            lastDigit,
            style: TextStyle(
              fontSize: 10.sp,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    ];
  }
}

class _FavoriteButton extends StatelessWidget {
  final String symbol;
  final InstrumentsController controller;

  const _FavoriteButton({required this.symbol, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        controller.toggleFavorite(symbol);
      },
      child: Obx(() {
        final isFavorite = controller.isFavorite(symbol);
        return Container(
          width: 18.w,
          height: 18.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isFavorite ? AppColors.primary : AppColors.textGrey,
              width: 2,
            ),
            color: isFavorite ? AppColors.primary : Colors.transparent,
          ),
          child:
              isFavorite
                  ? Icon(Icons.check, size: 12.w, color: Colors.white)
                  : null,
        );
      }),
    );
  }
}
