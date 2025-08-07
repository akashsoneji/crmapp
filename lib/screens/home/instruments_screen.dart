// lib/presentation/screens/instruments_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/controllers/account_controller.dart';
import 'package:pipze/controllers/instruments_controller.dart';
import 'package:pipze/models/instrument.dart';
import 'package:pipze/utils/trl_helper.dart';
import '../../widgets/global_drawer.dart';
import 'chart_screen.dart';

class InstrumentsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToChart;

  const InstrumentsScreen({super.key, this.onNavigateToChart});

  @override
  State<InstrumentsScreen> createState() => _InstrumentsScreenState();
}

class _InstrumentsScreenState extends State<InstrumentsScreen> {
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
  final AccountController _accountController = Get.put(AccountController());
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _controller.searchInstruments(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          if (_isSearching) ...[
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
          ] else ...[
            InkWell(
              onTap: () {
                Scaffold.of(context).openDrawer();
              },
              child: SvgPicture.asset(
                "assets/svg/menu.svg",
                height: 24.h,
                width: 24.w,
              ),
            ),
            SizedBox(width: 6.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _accountController.activeAccount != null
                              ? '\$${_accountController.activeAccount!.balance.toStringAsFixed(2)}'
                              : '\$0.00',
                          style: AppTextStyles.heading.copyWith(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _accountController.resetToDefaultAccounts();
                            _showAccountSelectionBottomSheet(context);
                          },
                          child: Row(
                            children: [
                              Container(
                                alignment: Alignment.center,
                                width: 45.w,
                                height: 22.h,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _accountController.activeAccount?.type ??
                                      "REAL",
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: 4.w),
                              SizedBox(
                                height: 22.h,
                                width: 75.w,
                                child: Text(
                                  _accountController.activeAccount?.id ??
                                      '035172384',
                                  textAlign: TextAlign.start,
                                  style: AppTextStyles.subheading.copyWith(
                                    fontSize: 12.sp,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 16.h,
                                color: AppColors.textGrey,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isSearching = true;
                });
              },
              child: SvgPicture.asset(
                "assets/svg/search-normal.svg",
                height: 24.h,
                width: 24.w,
              ),
            ),
          ],
        ],
      ),
    );
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
                "instruments_title".tr,
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
                        filter,
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
            color: AppColors.primary.withAlpha(45),
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

  Widget _buildInstrumentsList(List<Instrument> instruments) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: instruments.length,
      itemBuilder: (context, index) {
        final instrument = instruments[index];
        return _buildInstrumentItem(instrument);
      },
    );
  }

  Widget _buildInstrumentItem(Instrument instrument) {
    return GestureDetector(
      onTap: () {
        _navigateToChartWithSymbol(instrument.name);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
                        Positioned(
                          left: 0,
                          child: Text(
                            _getFirstFlag(instrument.flag),
                            style: TextStyle(fontSize: 16.sp),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: Text(
                            _getSecondFlag(instrument.flag),
                            style: TextStyle(fontSize: 16.sp),
                          ),
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
                          _getMarketStatus(instrument.status),
                          style: AppTextStyles.subheading.copyWith(
                            fontSize: 10.sp,
                            color: AppColors.textGrey,
                          ),
                        ),
                        Text(
                          instrument.name,
                          style: AppTextStyles.input.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                          ),
                        ),
                        if (instrument.heigh != null)
                          Row(
                            children: [
                              Text(
                                instrument.heigh!.replaceFirst(r'S', '+') +
                                    '%' +
                                    '\t',
                                style: AppTextStyles.subheading.copyWith(
                                  fontSize: 10.sp,
                                  color: AppColors.green,
                                ),
                              ),
                              Text(
                                instrument.heigh!,
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
                  Text(
                    instrument.bidPrice,
                    style: AppTextStyles.input.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 17.sp,
                      color: AppColors.red,
                      height: 22 / 17,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'L: ${instrument.lowPrice}',
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
                  Text(
                    instrument.askPrice,
                    style: AppTextStyles.input.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 17.sp,
                      color: AppColors.success,
                      height: 22 / 17,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'H: ${instrument.highPrice}',
                    style: AppTextStyles.subheading.copyWith(
                      fontSize: 10.sp,
                      color: AppColors.textGrey,
                      height: 22 / 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToChartWithSymbol(String symbol) {
    print('InstrumentsScreen: Navigating to chart with symbol: $symbol');
    ChartScreen.setSelectedSymbol(symbol);
    print('InstrumentsScreen: Set selected symbol to: $symbol');
    if (widget.onNavigateToChart != null) {
      print('InstrumentsScreen: Calling onNavigateToChart callback');
      widget.onNavigateToChart!();
    } else {
      print('InstrumentsScreen: onNavigateToChart callback is null');
    }
  }

  String _getMarketStatus(String status) {
    if (status.contains('H') || status.contains('S')) {
      final parts = status.split(' ');
      if (parts.length >= 3) {
        final time = parts[0];
        final type = parts[1];
        final value = parts[2];
        if (type == 'S') {
          return '$time +$value% S:${value.split('.')[0]}.${value.split('.')[1]}';
        } else {
          return 'Market closed';
        }
      }
    }
    return 'Market closed';
  }

  String _getFirstFlag(String flag) {
    if (flag.length >= 4) {
      return flag.substring(0, 2);
    }
    return flag;
  }

  String _getSecondFlag(String flag) {
    if (flag.length >= 4) {
      return flag.substring(2, 4);
    }
    return '';
  }

  Widget _buildNoData() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/svg/no_imge_icon.svg'),
            SizedBox(height: 24.h),
            Text(
              "common_no_data".tr,
              style: AppTextStyles.heading.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              "common_no_data_description".tr,
              style: AppTextStyles.subheading.copyWith(
                color: AppColors.textPrimary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
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

  void _showAccountSelectionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Obx(() {
          double dynamicHeight;
          if (_accountController.accounts.length <= 2) {
            dynamicHeight = MediaQuery.of(context).size.height * 0.35;
          } else if (_accountController.accounts.length <= 3) {
            dynamicHeight = MediaQuery.of(context).size.height * 0.45;
          } else if (_accountController.accounts.length <= 4) {
            dynamicHeight = MediaQuery.of(context).size.height * 0.55;
          } else {
            dynamicHeight = MediaQuery.of(context).size.height * 0.65;
          }

          return Container(
            height: dynamicHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 12.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Account',
                        style: AppTextStyles.heading.copyWith(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: AppColors.textGrey),
                      ),
                    ],
                  ),
                ),
                _accountController.isLoading
                    ? Expanded(
                      child: Container(
                        padding: EdgeInsets.all(20.w),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                    : Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _accountController.accounts.length,
                        itemBuilder: (context, index) {
                          final account = _accountController.accounts[index];
                          final isActive =
                              _accountController.activeAccount?.id ==
                              account.id;
                          return Container(
                            child: ListTile(
                              leading: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color:
                                      account.type == 'REAL'
                                          ? AppColors.primary
                                          : AppColors.success,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet,
                                  color: Colors.white,
                                  size: 20.h,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    account.type,
                                    style: AppTextStyles.label.copyWith(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (isActive) ...[
                                    SizedBox(width: 8.w),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6.w,
                                        vertical: 2.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                      ),
                                      child: Text(
                                        'ACTIVE',
                                        style: AppTextStyles.label.copyWith(
                                          fontSize: 8.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ID: ${account.id}',
                                    style: AppTextStyles.label.copyWith(
                                      fontSize: 12.sp,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                  Text(
                                    '\$${account.balance.toStringAsFixed(2)}',
                                    style: AppTextStyles.label.copyWith(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Radio<String>(
                                value: account.id,
                                groupValue:
                                    _accountController.activeAccount?.id,
                                onChanged: (value) {
                                  if (value != null) {
                                    _accountController.setActiveAccount(value);
                                    Navigator.pop(context);
                                  }
                                },
                                activeColor: AppColors.primary,
                              ),
                              onTap: () {
                                _accountController.setActiveAccount(account.id);
                                Navigator.pop(context);
                              },
                              tileColor:
                                  isActive
                                      ? AppColors.primary.withOpacity(0.1)
                                      : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
