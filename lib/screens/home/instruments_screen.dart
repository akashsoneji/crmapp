// lib/presentation/screens/instruments_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';

import 'package:pipze/controllers/instruments_controller.dart';

import 'package:pipze/models/socket_response.dart';
import 'package:pipze/services/language_service.dart';
import 'package:pipze/utils/trl_helper.dart';
import 'package:pipze/utils/precision_helper.dart';
import '../../widgets/global_drawer.dart';
import '../../widgets/account_header_widget.dart';
import '../auth/register/account_created_screen.dart';
import 'chart_screen.dart';
import 'dart:developer' as dev;

class InstrumentsScreen extends StatefulWidget {
  final Function(String)? onNavigateToChart;

  const InstrumentsScreen({super.key, this.onNavigateToChart});

  @override
  State<InstrumentsScreen> createState() => _InstrumentsScreenState();
}

class _InstrumentsScreenState extends State<InstrumentsScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _filters = [
    'All',
    'Favorites',
    'Currency',
    'Metals',
    'Indices Spot',
  ];
  final List<String> _sortOptions = [
    'Popularity',
    'Daily Changes',
    'Daily gain',
    'Daily loss',
  ];
  final InstrumentsController _controller = Get.put(InstrumentsController());

  final LanguageService languageService = Get.put(LanguageService());
  bool _isSearching = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _controller.searchInstruments(_searchController.text);
    });

    // Listen to real-time price updates from instruments controller
    _listenToPriceUpdates();

    // Note: WebSocket will be started by TradingMainScreen when tab is switched to
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      drawer: const GlobalDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchAndFilters(),
            Expanded(
              child: Obx(() {
                // Show loading indicator while WebSocket is connecting and no data yet
                if (_controller.instruments.isEmpty &&
                    !_controller.isConnected.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Loading instruments...',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textGrey,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (_controller.instruments.isEmpty) {
                  return _buildNoData();
                }
                return _buildInstrumentsList(_controller.instruments);
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
                  hintText: "instruments_search".tr,
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
      return AccountHeaderWidget(
        onSearchTap: () {
          setState(() {
            _isSearching = true;
          });
        },
      );
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
        return Row(
          children:
              _filters.map((filter) {
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
                        color: isSelected ? AppColors.primary : Colors.white,
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
                          fontSize: 14.sp,
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
            color: AppColors.primary.withAlpha(25),
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
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: instruments.length,
      itemBuilder: (context, index) {
        final instrument = instruments[index];
        return _buildInstrumentItem(instrument);
      },
    );
  }

  Widget _buildInstrumentItem(ListElement instrument) {
    return GestureDetector(
      onTap: () {
        _navigateToChartWithSymbol(instrument.symbol);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: AppColors.border.withOpacity(0.3),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 24.h,
                    child: Stack(
                      children: [
                        Image.network(
                          instrument.logo,
                          width: 24.w,
                          height: 24.h,
                          fit: BoxFit.cover,
                          cacheWidth:
                              48, // Cache at 2x resolution for crisp display
                          cacheHeight: 48,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 24.w,
                              height: 24.h,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 12.w,
                                  height: 12.h,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.grey[600]!,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 24.w,
                              height: 24.h,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4.r),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4.r),
                                child: Image.asset(
                                  'assets/image/noflag.jpeg',
                                  width: 24.w,
                                  height: 24.h,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('🚀 Asset image also failed: $error');
                                    // If asset also fails, show a simple icon
                                    return Container(
                                      width: 24.w,
                                      height: 24.h,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(
                                          4.r,
                                        ),
                                      ),
                                      child: Image.asset(
                                        'assets/image/no_flag_icon.png',
                                        width: 24.w,
                                        height: 24.h,
                                        fit: BoxFit.cover,
                                      ),
                                      // Icon(
                                      // Icons.image_not_supported,
                                      // size: 12.w,
                                      // color: Colors.grey[600],
                                      // ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          // _getMarketStatus(instrument.symbol),
                          DateFormat('HH:mm:ss').format(DateTime.now()),
                          style: AppTextStyles.subheading.copyWith(
                            fontSize: 10.sp,
                            color: AppColors.textGrey,
                          ),
                        ),
                        Text(
                          instrument.symbol.replaceAll(".c", ""),
                          style: AppTextStyles.input.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                          ),
                        ),
                        Row(
                          children: [
                            // Text(
                            //   instrument.bid!.toString().replaceFirst(
                            //         r'S',
                            //         '+',
                            //       ) +
                            //       '%' +
                            //       '\t',
                            //   style: AppTextStyles.subheading.copyWith(
                            //     fontSize: 10.sp,
                            //     color: AppColors.green,
                            //   ),
                            // ),
                            Text(
                              _formatSpreadDiff(instrument.spreadDiff),
                              style: AppTextStyles.subheading.copyWith(
                                fontSize: 10.sp,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      children: _buildPriceTextSpans(
                        instrument.bid,
                        AppColors.red,
                        instrument.digits,
                      ),
                    ),
                  ),

                  SizedBox(height: 2.h),
                  Text(
                    'L: st',
                    style: AppTextStyles.subheading.copyWith(
                      fontSize: 10.sp,
                      color: AppColors.textGrey,
                      height: 22 / 10,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      children: _buildPriceTextSpans(
                        instrument.ask,
                        AppColors.green,
                        instrument.digits,
                      ),
                    ),
                  ),

                  SizedBox(height: 2.h),
                  Text(
                    'H: st',
                    style: AppTextStyles.subheading.copyWith(
                      fontSize: 10.sp,
                      color: AppColors.textGrey,
                      height: 22 / 10,
                    ),
                  ),
                ],
              ),
            ),
            // Favorite button
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: () {
                _controller.toggleFavorite(instrument.symbol);
              },
              child: Container(
                padding: EdgeInsets.all(4.w),
                child: Obx(() {
                  final isFavorite = _controller.isFavorite(instrument.symbol);
                  return Container(
                    width: 22.w,
                    height: 22.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isFavorite ? AppColors.primary : AppColors.textGrey,
                        width: 2,
                      ),
                      color:
                          isFavorite ? AppColors.primary : Colors.transparent,
                    ),
                    child:
                        isFavorite
                            ? Icon(Icons.check, size: 15.w, color: Colors.white)
                            : null,
                  );
                }),
              ),

              //   child: Obx(() {
              //     final isFavorite = _controller.isFavorite(instrument.symbol);
              //     return Container(
              //       padding: EdgeInsets.all(4.w),
              //       child: Icon(
              //         isFavorite ? Icons.favorite : Icons.favorite_border,
              //         size: 20.w,
              //         color: isFavorite ? AppColors.primary : AppColors.textGrey,
              //       ),
              //     );
              //   }),
              // ),
            ),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _buildPriceTextSpans(dynamic price, Color color, int digits) {
    // Keep only 4 digits after decimal
    String priceStr = PrecisionHelper.formatPrice(price, decimals: digits);

    // Split into integer + decimal parts
    int dotIndex = priceStr.indexOf(".");
    String firstPart = priceStr; // default full number
    String secondPart = "";

    if (dotIndex != -1) {
      firstPart = priceStr.substring(0, dotIndex + 1); // number + "."
      secondPart = priceStr.substring(dotIndex + 1); // 4 decimals
    }

    // Decide color (example rule)
    // Color color = price % 2 == 0 ? Colors.green : Colors.red;

    return [
      TextSpan(
        text: firstPart,
        style: TextStyle(
          fontSize: 14,
          color: color,
          fontWeight: FontWeight.normal,
        ),
      ),
      if (secondPart.isNotEmpty)
        TextSpan(
          text: secondPart,
          style: TextStyle(
            fontSize: 20,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
    ];
  }

  // List<TextSpan> _buildPriceTextSpans(dynamic price) {
  //   // Convert to string with fixed decimals (e.g. 5 decimal places)
  //   String priceStr = price.toStringAsFixed(5);

  //   // Split into two parts: first 3 decimals, and the rest
  //   int dotIndex = priceStr.indexOf(".");
  //   String before = priceStr; // default

  //   String firstPart = priceStr;
  //   String secondPart = "";

  //   if (dotIndex != -1 && dotIndex + 2 < priceStr.length) {
  //     firstPart = priceStr.substring(0, dotIndex + 2); // up to 3 decimals
  //     secondPart = priceStr.substring(dotIndex + 1); // rest
  //   }

  //   // Decide color (example: green if increased, red if decreased)
  //   Color color = price % 2 == 0 ? Colors.green : Colors.red; // default
  //   // You can pass last price vs new price to decide increase/decrease
  //   print("object first part$firstPart");
  //   print("object second part$secondPart");
  //   print("object color$color");
  //   return [
  //     TextSpan(
  //       text: firstPart,
  //       style: TextStyle(
  //         fontSize: 16,
  //         color: color,
  //         fontWeight: FontWeight.normal,
  //       ),
  //     ),
  //     if (secondPart.isNotEmpty)
  //       TextSpan(
  //         text: secondPart,
  //         style: TextStyle(
  //           fontSize: 20,
  //           color: color,
  //           fontWeight: FontWeight.bold,
  //         ),
  //       ),
  //   ];
  // }

  void _navigateToChartWithSymbol(String symbol) {
    dev.log('InstrumentsScreen: Navigating to chart with symbol: $symbol');

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
      case 'Popularity':
        return SvgPicture.asset(
          "assets/svg/Like_Icon.svg",
          height: 22.h,
          width: 24.w,
        );
      case 'Daily Changes':
        return SvgPicture.asset(
          "assets/svg/fire.svg",
          height: 22.h,
          width: 24.w,
        );
      case 'Daily gain':
        return SvgPicture.asset(
          "assets/svg/dayily_gain.svg",
          height: 22.h,
          width: 24.w,
        );
      case 'Daily loss':
        return SvgPicture.asset(
          "assets/svg/dailly_loss.svg",
          height: 22.h,
          width: 24.w,
        );
      default:
        return Icon(Icons.sort, size: 20.h, color: AppColors.textGrey);
    }
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
