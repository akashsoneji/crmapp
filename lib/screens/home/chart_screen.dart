import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:pipze/models/instrument.dart';
import 'package:pipze/widgets/fixed_size_webview.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../constants/color.dart';
import '../../constants/text_styles.dart';
import '../../services/language_service.dart';
import '../../controllers/account_controller.dart';
import '../../controllers/instruments_controller.dart';
import '../../widgets/price_alert_dialog.dart';
import '../../services/price_alert_service.dart';
import 'instruments_screen.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  // Static method to set symbol from instruments screen
  static void setSelectedSymbol(String symbol) {
    _selectedSymbolNotifier.value = symbol;
  }

  // Static ValueNotifier to handle symbol changes
  static final ValueNotifier<String> _selectedSymbolNotifier = ValueNotifier(
    'EURUSD',
  );

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  double volume = 0.02;
  String selectedTimeframe = '15s';
  String selectedChartType = 'Candlestick';
  String selectedSymbol = 'EURUSD'; // Default to first instrument

  bool useTradingView = true;
  final ValueNotifier<String> selectedPriceType = ValueNotifier('Asset Price');

  late TextEditingController _volumeController;
  late TextEditingController _takeProfitController;
  late TextEditingController _stopLossController;
  late TextEditingController distanceController;
  VoidCallback? _distanceListener;

  // Get controllers
  final AccountController accountController = Get.find<AccountController>();
  final InstrumentsController instrumentsController =
      Get.find<InstrumentsController>();

  // Mock chart data for now
  List<Map<String, dynamic>> _chartData = [];
  Map<String, dynamic>? realTimePrice;
  bool isLoading = true;
  String? errorMessage;

  late TrackballBehavior _trackballBehavior;
  Timer? _timer;
  int _maxCandles = 50;
  List<int> _candleOptions = [20, 30, 50, 100];

  // Trading Order Bottom Sheet State with ValueNotifier
  final ValueNotifier<int> _selectedOrderTab = ValueNotifier(
    0,
  ); // 0: Market Order, 1: Pending Order
  final ValueNotifier<int> _selectedPendingOrderType = ValueNotifier(
    1,
  ); // 0: Sell Limit, 1: Buy Limit
  final ValueNotifier<double> _orderVolume = ValueNotifier(0.06);
  final ValueNotifier<double> _openPrice = ValueNotifier(1.15505);
  final ValueNotifier<double> _distance = ValueNotifier(40.0);
  final ValueNotifier<bool> _takeProfitEnabled = ValueNotifier(false);
  final ValueNotifier<bool> _stopLossEnabled = ValueNotifier(false);
  final ValueNotifier<bool> _advanceSettingsEnabled = ValueNotifier(false);
  final ValueNotifier<bool> _trailingStopEnabled = ValueNotifier(false);
  final ValueNotifier<bool> _orderExpirationEnabled = ValueNotifier(false);
  final ValueNotifier<DateTime> _orderExpirationDate = ValueNotifier(
    DateTime.now(),
  );
  final ValueNotifier<DateTime> _orderExpirationTime = ValueNotifier(
    DateTime.now(),
  );
  final ValueNotifier<bool> _breakEvenEnabled = ValueNotifier(false);
  final ValueNotifier<double> _takeProfitPrice = ValueNotifier(1.15550);
  final ValueNotifier<double> _stopLossPrice = ValueNotifier(1.15448);
  final _accountController = Get.find<AccountController>();

  @override
  void initState() {
    super.initState();

    // Listen to symbol changes from instruments screen
    ChartScreen._selectedSymbolNotifier.addListener(
      _onSymbolChangedFromInstruments,
    );

    _volumeController = TextEditingController(text: volume.toStringAsFixed(2));
    _takeProfitController = TextEditingController(
      text: _takeProfitPrice.value.toStringAsFixed(2),
    );
    _stopLossController = TextEditingController(
      text: _stopLossPrice.value.toStringAsFixed(2),
    );
    distanceController = TextEditingController(
      text: _distance.value.toStringAsFixed(2),
    );

    // Add listener to sync distance controller with value notifier
    _distanceListener = () {
      if (distanceController.text != _distance.value.toStringAsFixed(2)) {
        distanceController.text = _distance.value.toStringAsFixed(2);
      }
    };
    _distance.addListener(_distanceListener!);

    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
    );

    _loadMockData();
    _loadRealTimePrice();
    _initializePriceAlertService();
  }

  void _onSymbolChangedFromInstruments() {
    final newSymbol = ChartScreen._selectedSymbolNotifier.value;
    print('ChartScreen: Symbol changed from $selectedSymbol to $newSymbol');
    if (newSymbol != selectedSymbol) {
      setState(() {
        selectedSymbol = newSymbol;
      });
      _loadRealTimePrice();
      print('ChartScreen: Updated selectedSymbol to $selectedSymbol');
    }
  }

  Future<void> _initializePriceAlertService() async {
    try {
      await PriceAlertService().initialize();
    } catch (e) {
      print('Failed to initialize price alert service: $e');
    }
  }

  void _loadMockData() {
    // Generate mock chart data
    _chartData = List.generate(50, (index) {
      final date = DateTime.now().subtract(Duration(days: 50 - index));
      final basePrice = 1.1550;
      final randomChange = (index % 10 - 5) * 0.001;
      final open = basePrice + randomChange;
      final close = open + (index % 3 - 1) * 0.0005;
      final high = open > close ? open + 0.002 : close + 0.002;
      final low = open > close ? close - 0.001 : open - 0.001;

      return {
        'date': date,
        'open': open,
        'high': high,
        'low': low,
        'close': close,
        'volume': 1000 + (index * 100),
      };
    });

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadRealTimePrice() async {
    try {
      // Mock real-time price data
      final mockPrice = {
        'bid': 1.1550 + (DateTime.now().millisecond % 100) * 0.0001,
        'ask': 1.1552 + (DateTime.now().millisecond % 100) * 0.0001,
        'change': 0.0002,
        'changePercent': 0.017,
      };

      setState(() {
        realTimePrice = mockPrice;
      });

      // Check price alerts when new price is received
      if (mockPrice['bid'] != null) {
        final currentPrice = mockPrice['bid'] as double;
        if (currentPrice > 0) {
          await PriceAlertService().checkPriceAlerts(
            currentPrice,
            selectedSymbol,
          );
        }
      }
    } catch (e) {
      // Handle error silently for real-time price
      print('Error loading real-time price: $e');
    }
  }

  void _showPriceAlertDialog() {
    final currentPrice = realTimePrice?['bid'] ?? 1.14252;
    final price =
        currentPrice is double
            ? currentPrice
            : double.tryParse(currentPrice.toString()) ?? 1.14252;

    print("object of_showPriceAlertDialog Price ${price}");
    print("object of_showPriceAlertDialog currentPrice ${currentPrice}");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // Prevent closing when clicking behind
      enableDrag: false, // Prevent dragging to close
      builder:
          (context) =>
              PriceAlertDialog(symbol: selectedSymbol, currentPrice: price),
    );
  }

  void _onTimeframeChanged(String newTimeframe) {
    setState(() {
      selectedTimeframe = newTimeframe;
    });
  }

  void _onChartTypeChanged(String newChartType) {
    setState(() {
      selectedChartType = newChartType;
    });
  }

  void _onSymbolChanged(String newSymbol) {
    print('ChartScreen: _onSymbolChanged called with $newSymbol');
    setState(() {
      selectedSymbol = newSymbol;
    });
    _loadRealTimePrice();
    print('ChartScreen: Updated selectedSymbol to $selectedSymbol');
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isLargeScreen = screenWidth > 600;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header - Fixed height
            _buildHeader(context),

            // Chart Area - Responsive height
            Expanded(
              flex:
                  isSmallScreen
                      ? 3
                      : isLargeScreen
                      ? 4
                      : 3,
              child: _buildChartArea(),
            ),

            // Interactive Icons - Fixed height
            _buildVolumeInputScreen(context, true),

            // Trading Controls - Fixed height
            _buildTradingControls(),
            _buildInteractiveIcons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isLargeScreen = screenWidth > 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12.w : 16.w,
        vertical: isSmallScreen ? 6.h : 8.h,
      ),
      child: Row(
        children: [
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
          SizedBox(width: 8.w),
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
                          fontSize: 22.sp,
                          color: AppColors.green,
                          fontWeight: FontWeight.w600,
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
            onTap: () => _showSymbolSelector(),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8.w : 12.w,
                vertical: isSmallScreen ? 6.h : 8.h,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardBackGround,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Text(
                    selectedSymbol,
                    style: AppTextStyles.label.copyWith(
                      fontSize: isSmallScreen ? 12.sp : 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: isSmallScreen ? 14.h : 16.h,
                    color: AppColors.textGrey,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetDetails() {
    if (_chartData.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(
          children: [
            Text(
              'Loading...',
              style: AppTextStyles.label.copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      );
    }

    final latestCandle = _chartData.last;
    final firstCandle = _chartData.first;
    final change = latestCandle['close'] - firstCandle['open'];
    final changePercent = (change / firstCandle['open']) * 100;
    final isPositive = change >= 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Text(
            'Change: ${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
            style: AppTextStyles.label.copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: isPositive ? AppColors.success : AppColors.error,
            ),
          ),
          SizedBox(width: 16.w),
          Text(
            'Low: ${firstCandle['low']?.toStringAsFixed(5) ?? '0.00000'}',
            style: AppTextStyles.label.copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textGrey,
            ),
          ),
          SizedBox(width: 16.w),
          Text(
            'High: ${firstCandle['high']?.toStringAsFixed(5) ?? '0.00000'}',
            style: AppTextStyles.label.copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textGrey,
            ),
          ),
          const Spacer(),
          Container(
            width: 20.w,
            height: 20.h,
            decoration: BoxDecoration(
              color: AppColors.textGrey.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline,
              size: 14.h,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartArea() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.4, // Responsive height
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,

      // margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: FixedSizeWebView(
        key: ValueKey(selectedSymbol), // Force rebuild when symbol changes
        url:
            'https://my.pipze.com/user/chart/$selectedSymbol', // Responsive height
      ),
    );
  }

  void _showSymbolSelector() {
    // Use the same instruments data from instruments screen
    final instruments = [
      // Currency pairs - matching the instruments screen exactly
      Instrument(
        name: 'EURUSD',
        flag: '🇪🇺🇺🇸',
        status: 'Market closed',
        bidPrice: '1.24948',
        askPrice: '1.24959',
        lowPrice: '0.65514',
        highPrice: '0.65582',
        category: 'Currency',
      ),
      Instrument(
        name: 'AUDCHF',
        flag: '🇦🇺🇨🇭',
        status: 'Market closed',
        bidPrice: '1.24948',
        askPrice: '1.24959',
        lowPrice: '0.65514',
        highPrice: '0.65582',
        category: 'Currency',
      ),
      Instrument(
        name: 'AUDJPY',
        flag: '🇦🇺🇯🇵',
        status: '10:47:54',
        heigh: 'S 0.06',
        bidPrice: '1.24948',
        askPrice: '1.24959',
        lowPrice: '0.65514',
        highPrice: '0.65582',
        category: 'Currency',
      ),
      Instrument(
        name: 'GBPUSD',
        flag: '🇬🇧🇺🇸',
        status: 'Market closed',
        bidPrice: '1.24948',
        askPrice: '1.24959',
        lowPrice: '0.65514',
        highPrice: '0.65582',
        category: 'Currency',
      ),
      Instrument(
        name: 'USDJPY',
        flag: '🇺🇸🇯🇵',
        status: 'Market closed',
        bidPrice: '1.24948',
        askPrice: '1.24959',
        lowPrice: '0.65514',
        highPrice: '0.65582',
        category: 'Currency',
      ),
      Instrument(
        name: 'USDCHF',
        flag: '🇺🇸🇨🇭',
        status: 'Market closed',
        bidPrice: '1.24948',
        askPrice: '1.24959',
        lowPrice: '0.65514',
        highPrice: '0.65582',
        category: 'Currency',
      ),
      Instrument(
        name: 'USDCAD',
        flag: '🇺🇸🇨🇦',
        status: 'Market closed',
        bidPrice: '1.24948',
        askPrice: '1.24959',
        lowPrice: '0.65514',
        highPrice: '0.65582',
        category: 'Currency',
      ),
      Instrument(
        name: 'NZDUSD',
        flag: '🇳🇿🇺🇸',
        status: 'Market closed',
        bidPrice: '1.24948',
        askPrice: '1.24959',
        lowPrice: '0.65514',
        highPrice: '0.65582',
        category: 'Currency',
      ),
      Instrument(
        name: 'EURGBP',
        flag: '🇪🇺🇬🇧',
        status: 'Market closed',
        bidPrice: '1.24948',
        askPrice: '1.24959',
        lowPrice: '0.65514',
        highPrice: '0.65582',
        category: 'Currency',
      ),
      Instrument(
        name: 'EURJPY',
        flag: '🇪🇺🇯🇵',
        status: 'Market closed',
        bidPrice: '1.24948',
        askPrice: '1.24959',
        lowPrice: '0.65514',
        highPrice: '0.65582',
        category: 'Currency',
      ),
      Instrument(
        name: 'EURCHF',
        flag: '🇪🇺🇨🇭',
        status: 'Market closed',
        bidPrice: '1.24948',
        askPrice: '1.24959',
        lowPrice: '0.65514',
        highPrice: '0.65582',
        category: 'Currency',
      ),
      Instrument(
        name: 'GBPJPY',
        flag: '🇬🇧🇯🇵',
        status: 'Market closed',
        bidPrice: '1.24948',
        askPrice: '1.24959',
        lowPrice: '0.65514',
        highPrice: '0.65582',
        category: 'Currency',
      ),
      // Metals
      Instrument(
        name: 'XAUUSD',
        flag: '🥇',
        status: '01:00:00 H 20.0',
        bidPrice: '3426.588',
        askPrice: '3426.772',
        lowPrice: '3426.0',
        highPrice: '3427.0',
        category: 'Metals',
      ),
      Instrument(
        name: 'XAGUSD',
        flag: '🥈',
        status: '01:00:00 H 33.0',
        bidPrice: '39.419',
        askPrice: '39.442',
        lowPrice: '39.40',
        highPrice: '39.45',
        category: 'Metals',
      ),
      // Indices
      Instrument(
        name: 'AU200',
        flag: '🇦🇺',
        status: '01:00:00 H 26.0',
        bidPrice: '8734.25',
        askPrice: '8736.87',
        lowPrice: '8730.0',
        highPrice: '8740.0',
        category: 'Indices Spot',
      ),
      Instrument(
        name: 'DE40',
        flag: '🇩🇪',
        status: '01:00:00 H 35.0',
        bidPrice: '24157.431',
        askPrice: '24157.776',
        lowPrice: '24150.0',
        highPrice: '24160.0',
        category: 'Indices Spot',
      ),
      Instrument(
        name: 'ES35',
        flag: '🇪🇸',
        status: '01:00:00 H 65.0',
        bidPrice: '14136.54',
        askPrice: '14143.07',
        lowPrice: '14130.0',
        highPrice: '14150.0',
        category: 'Indices Spot',
      ),
      Instrument(
        name: 'EU50',
        flag: '🇪🇺',
        status: '01:00:00 H 25.0',
        bidPrice: '5335.73',
        askPrice: '5338.28',
        lowPrice: '5330.0',
        highPrice: '5340.0',
        category: 'Indices Spot',
      ),
      Instrument(
        name: 'FR40',
        flag: '🇫🇷',
        status: '01:00:00 H 22.0',
        bidPrice: '7818.84',
        askPrice: '7821.09',
        lowPrice: '7815.0',
        highPrice: '7825.0',
        category: 'Indices Spot',
      ),
      Instrument(
        name: 'HK50',
        flag: '🇭🇰',
        status: '01:00:00 H 55.0',
        bidPrice: '25503.35',
        askPrice: '25508.76',
        lowPrice: '25500.0',
        highPrice: '25510.0',
        category: 'Indices Spot',
      ),
      // Crypto
      Instrument(
        name: 'BTCUSD',
        flag: '₿',
        status: 'Market closed',
        bidPrice: '124796.510',
        askPrice: '124796.520',
        lowPrice: '124790.0',
        highPrice: '124800.0',
        category: 'Crypto',
      ),
      Instrument(
        name: 'ETHUSD',
        flag: 'Ξ',
        status: 'Market closed',
        bidPrice: '3426.588',
        askPrice: '3426.772',
        lowPrice: '3426.0',
        highPrice: '3427.0',
        category: 'Crypto',
      ),
    ];

    final TextEditingController searchController = TextEditingController();
    final List<String> filters = [
      'All',
      'Favorites',
      'Currency',
      'Metals',
      'Indices Spot',
    ];
    String currentFilter = 'All';
    List<Instrument> filteredInstruments = List.from(instruments);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Get keyboard height and screen dimensions
            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
            final screenHeight = MediaQuery.of(context).size.height;
            final availableHeight = screenHeight - keyboardHeight;

            // Calculate modal height - use more space when keyboard is visible
            double modalHeight;
            if (keyboardHeight > 0) {
              // When keyboard is visible, use most of available space
              modalHeight = availableHeight * 0.9;
            } else {
              // When keyboard is hidden, use 90% of screen
              modalHeight = screenHeight * 0.9;
            }

            // Ensure minimum and maximum bounds
            modalHeight = modalHeight.clamp(
              screenHeight * 0.9, // Minimum 70% of screen
              screenHeight * 0.95, // Maximum 95% of screen
            );

            // Filter instruments based on current filter and search
            void updateFilteredInstruments() {
              List<Instrument> filtered = instruments;

              // Apply category filter
              if (currentFilter == 'Favorites') {
                filtered =
                    instruments
                        .where((instrument) => instrument.isFavorite)
                        .toList();
              } else if (currentFilter != 'All') {
                filtered =
                    instruments
                        .where(
                          (instrument) => instrument.category == currentFilter,
                        )
                        .toList();
              }

              // Apply search filter
              if (searchController.text.isNotEmpty) {
                filtered =
                    filtered
                        .where(
                          (instrument) => instrument.name
                              .toLowerCase()
                              .contains(searchController.text.toLowerCase()),
                        )
                        .toList();
              }

              setState(() {
                filteredInstruments = filtered;
              });
            }

            return Container(
              height: modalHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: EdgeInsets.only(top: 12.h),
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Title
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    child: Container(width: 30.w, height: 5.h),
                  ),

                  // Search bar
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      onChanged: (value) {
                        updateFilteredInstruments();
                      },
                      decoration: InputDecoration(
                        hintText: 'Search instruments',
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.textGrey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Filter buttons - same as instruments screen
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            filters.map((filter) {
                              final isSelected = filter == currentFilter;
                              return Padding(
                                padding: EdgeInsets.only(right: 8.w),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      currentFilter = filter;
                                    });
                                    updateFilteredInstruments();
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
                                              : Colors.white,
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
                                            isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Instruments list with same layout as instruments screen
                  Expanded(
                    child:
                        filteredInstruments.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 48.h,
                                    color: AppColors.textGrey,
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    'No symbols found',
                                    style: AppTextStyles.subheading.copyWith(
                                      color: AppColors.textGrey,
                                      fontSize: 16.sp,
                                    ),
                                  ),
                                  if (searchController.text.isNotEmpty)
                                    Text(
                                      'Try a different search term',
                                      style: AppTextStyles.subheading.copyWith(
                                        color: AppColors.textGrey,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              itemCount: filteredInstruments.length,
                              itemBuilder: (context, index) {
                                final instrument = filteredInstruments[index];
                                final isSelected =
                                    instrument.name == selectedSymbol;

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    _onSymbolChanged(instrument.name);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 5.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border(
                                        bottom: BorderSide(
                                          color: AppColors.border.withOpacity(
                                            0.3,
                                          ),
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Flag and Name - same layout as instruments screen
                                        Expanded(
                                          flex: 3,
                                          child: Row(
                                            children: [
                                              // Flags container
                                              Container(
                                                width: 40.w,
                                                height: 24.h,
                                                child: Stack(
                                                  children: [
                                                    // First flag (left)
                                                    Positioned(
                                                      left: 0,
                                                      child: Text(
                                                        _getFirstFlag(
                                                          instrument.flag,
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 16.sp,
                                                        ),
                                                      ),
                                                    ),
                                                    // Second flag (right, slightly overlapping)
                                                    Positioned(
                                                      right: 0,
                                                      child: Text(
                                                        _getSecondFlag(
                                                          instrument.flag,
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 16.sp,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(width: 12.w),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      _getMarketStatus(
                                                        instrument.status,
                                                      ),
                                                      style: AppTextStyles
                                                          .subheading
                                                          .copyWith(
                                                            fontSize: 10.sp,
                                                            color:
                                                                AppColors
                                                                    .textGrey,
                                                          ),
                                                    ),
                                                    Text(
                                                      instrument.name,
                                                      style: AppTextStyles.input
                                                          .copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 14.sp,
                                                          ),
                                                    ),
                                                    if (instrument.heigh !=
                                                        null)
                                                      Row(
                                                        children: [
                                                          Text(
                                                            instrument.heigh!
                                                                    .replaceFirst(
                                                                      r'S',
                                                                      '+',
                                                                    ) +
                                                                '%' +
                                                                '\t',
                                                            style: AppTextStyles
                                                                .subheading
                                                                .copyWith(
                                                                  fontSize:
                                                                      10.sp,
                                                                  color:
                                                                      AppColors
                                                                          .green,
                                                                ),
                                                          ),
                                                          Text(
                                                            instrument.heigh!,
                                                            style: AppTextStyles
                                                                .subheading
                                                                .copyWith(
                                                                  fontSize:
                                                                      10.sp,
                                                                  color:
                                                                      AppColors
                                                                          .textGrey,
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
                                        // Sell Price (Red) - same as instruments screen
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                instrument.bidPrice,
                                                style: AppTextStyles.input
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 17.sp,
                                                      color: AppColors.red,
                                                      height: 22 / 17,
                                                    ),
                                              ),
                                              SizedBox(height: 2.h),
                                              Text(
                                                'L: ${instrument.lowPrice}',
                                                style: AppTextStyles.subheading
                                                    .copyWith(
                                                      fontSize: 10.sp,
                                                      color: AppColors.textGrey,
                                                      height: 22 / 10,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Buy Price (Green) - same as instruments screen
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                instrument.askPrice,
                                                style: AppTextStyles.input
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 17.sp,
                                                      color: AppColors.success,
                                                      height: 22 / 17,
                                                    ),
                                              ),
                                              SizedBox(height: 2.h),
                                              Text(
                                                'H: ${instrument.highPrice}',
                                                style: AppTextStyles.subheading
                                                    .copyWith(
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
                              },
                            ),
                  ),

                  // Bottom padding - only add extra padding when keyboard is not visible
                  if (keyboardHeight == 0)
                    SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 16.h,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInteractiveIcons() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              _showTradingOrderBottomSheet();
            },
            child: Container(
              height: 45.h,
              width: 288.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7.r),
                color: AppColors.cardBackGround,
              ),
              child: Text(
                "Pending order • SL • TP",
                style: AppTextStyles.labelOnTradeButton,
              ),
            ),
          ),
          Spacer(),

          GestureDetector(
            onTap: () {
              _showPriceAlertDialog();
            },
            child: Container(
              height: 45.h,
              width: 45.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7.r),
                color: AppColors.primary,
              ),
              child: SvgPicture.asset(
                "assets/svg/chart_screen_icon/bell_icon.svg",
                color: AppColors.whiteColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradingControls() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isLargeScreen = screenWidth > 600;

    final bidValue = realTimePrice?['bid'];
    final askValue = realTimePrice?['ask'];

    final bidPrice =
        bidValue is double
            ? bidValue.toStringAsFixed(5)
            : bidValue is String
            ? bidValue
            : '0.00000';
    final askPrice =
        askValue is double
            ? askValue.toStringAsFixed(5)
            : askValue is String
            ? askValue
            : '0.00000';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Container(
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // SELL Button - Fixed width for small screens, flexible for larger
                Container(
                  height: 48.h,
                  width: 170.5.w,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'SELL',
                        style: AppTextStyles.button.copyWith(
                          fontSize: isSmallScreen ? 12.sp : 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        askPrice + '050',
                        style: AppTextStyles.button.copyWith(
                          fontSize: isSmallScreen ? 12.sp : 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8.w : 16.w),

                // BUY Button - Fixed width for small screens, flexible for larger
                Container(
                  height: 48.h,
                  width: 170.5.w,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'BUY',
                        style: AppTextStyles.button.copyWith(
                          fontSize: isSmallScreen ? 12.sp : 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        bidPrice,
                        style: AppTextStyles.button.copyWith(
                          fontSize: isSmallScreen ? 12.sp : 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.tradeBackgroundCenterColor,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  height: 26.h,
                  width: 52.w,
                  child: Text(
                    '0.222',
                    style: AppTextStyles.labelOnTradeDifference,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeInputScreen(BuildContext context, bool isborder) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isborder ? 10.w : 0,
        vertical: isborder ? 10.h : 2.h,
      ),
      child: Container(
        height: 48.h,
        padding: EdgeInsets.symmetric(horizontal: 11.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isborder ? AppColors.border : Colors.transparent,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Minus button
            Container(
              height: 24.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // color: AppColors.icongrey,
                border: Border.all(color: AppColors.icongrey),
              ),
              width: 24.w,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    if (volume > 0.01) {
                      volume -= 0.01;
                      _volumeController.text = volume.toStringAsFixed(2);
                    }
                  });
                },
                icon: Icon(Icons.remove, size: 18.h, color: AppColors.icongrey),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ),

            // Volume display
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Quantity (lots)',
                    style: AppTextStyles.labelOnTradeQuantity,
                  ),
                  // SizedBox(height: 1.h),
                  TextField(
                    controller: _volumeController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelOnTradeQuantityDigit,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      final newVolume = double.tryParse(value);
                      if (newVolume != null && newVolume > 0) {
                        setState(() {
                          volume = newVolume;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            // Plus button
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // color: AppColors.icongrey,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              width: 24.w,
              height: 24.h,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    volume += 0.01;
                    _volumeController.text = volume.toStringAsFixed(2);
                  });
                },
                icon: Icon(Icons.add, size: 18.h, color: AppColors.primary),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTradingOrderBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SafeArea(
            child: DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.25,
              maxChildSize: 0.75,

              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.r),
                      topRight: Radius.circular(20.r),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Container(
                          width: 30.w,
                          height: 5.h,
                          decoration: BoxDecoration(
                            color: AppColors.grey,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 18.h),
                        child: Text(
                          "Pending order ",
                          style: AppTextStyles.labelOnTradeBottomTitle,
                        ),
                      ),
                      SizedBox(height: 7.5.h),
                      Container(
                        height: 1.h,
                        width: double.infinity,
                        color: AppColors.grey,
                      ),

                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: EdgeInsets.all(16.w),
                          child: _buildPendingOrderContent(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
    );
  }

  Widget _buildMarketOrderContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Volume Input
        _buildVolumeInput(),
        SizedBox(height: 14.h),

        // Monetary Equivalent
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Monetary equivalent',
              style: AppTextStyles.label.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.textGrey,
              ),
            ),
            ValueListenableBuilder<double>(
              valueListenable: _openPrice,
              builder: (context, price, child) {
                return Text(
                  '${price.toStringAsFixed(2)}',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                  ),
                );
              },
            ),
          ],
        ),
        SizedBox(height: 14.h),

        // Margin Details
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.grey,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Required margin',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textGrey,
                      ),
                    ),
                    Text(
                      '\$6.93',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Free margin',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textGrey,
                      ),
                    ),
                    Text(
                      '\$4953.85',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // Take Profit
        _buildSwitchTile(
          'Take Profit',
          _takeProfitEnabled,
          onChanged: (value) {
            _takeProfitEnabled.value = value;
            if (value) _stopLossEnabled.value = false;
          },
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _takeProfitEnabled,
          builder: (context, enabled, child) {
            if (!enabled) return SizedBox.shrink();
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 236.w,
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 17.0),
                            child: Container(
                              width: 22.w,
                              height: 22.h,
                              alignment: Alignment.center,

                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    if (_takeProfitPrice.value > 0.01) {
                                      _takeProfitPrice.value -= 0.01;
                                      _takeProfitController
                                          .text = _takeProfitPrice.value
                                          .toStringAsFixed(2);
                                    }
                                  });
                                },
                                icon: Icon(
                                  Icons.remove,
                                  size: 16.h,
                                  color: AppColors.icongrey,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _volumeController,
                                        keyboardType:
                                            TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.label.copyWith(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          errorBorder: InputBorder.none,
                                          focusedErrorBorder: InputBorder.none,
                                          disabledBorder: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                          isDense: true,
                                        ),
                                        onChanged: (value) {
                                          final newVolume = double.tryParse(
                                            value,
                                          );
                                          if (newVolume != null &&
                                              newVolume > 0) {
                                            setState(() {
                                              volume = newVolume;
                                            });
                                          }
                                        },
                                      ),
                                    ), // Text(
                                    // volume.toStringAsFixed(2),
                                    // style: AppTextStyles.label.copyWith(
                                    // fontSize: 16.sp,
                                    // fontWeight: FontWeight.w700,
                                    // ),
                                    // ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Padding(
                            padding: const EdgeInsets.only(right: 14.0),
                            child: Container(
                              width: 22.w,
                              height: 22.h,
                              alignment: Alignment.center,

                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    volume += 0.01;
                                    _volumeController.text = volume
                                        .toStringAsFixed(2);
                                  });
                                },
                                icon: Icon(
                                  Icons.add,
                                  size: 16.h,
                                  color: AppColors.primary,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 96.w,
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.center,
                      child: _buildPriceTypeDropdown(),
                    ),
                  ],
                ),

                // _buildPriceInput('1.15550', _takeProfitPrice),
                // SizedBox(height: 4.h),
                // Text(
                //   '68 points | Profit +4.08 USD | +0.08% of balance',
                //   style: AppTextStyles.label.copyWith(
                //     fontSize: 12.sp,
                //     color: AppColors.textGrey,
                //   ),
                // ),
                SizedBox(height: 8.h),
              ],
            );
          },
        ),

        // Stop Loss
        _buildSwitchTile(
          'Stop Loss',
          _stopLossEnabled,
          onChanged: (value) {
            _stopLossEnabled.value = value;
            if (value) _trailingStopEnabled.value = false;
            if (value) _breakEvenEnabled.value = false;
          },
        ),

        // ValueListenableBuilder<bool>(
        //   valueListenable: _stopLossEnabled,
        //   builder: (context, enabled, child) {
        //     if (!enabled) return SizedBox.shrink();
        //     return Column(
        //       children: [
        //         _buildPriceInput('1.15448', _stopLossPrice),
        //         SizedBox(height: 4.h),
        //         Text(
        //           '-37 points | Profit -2.22 USD | -0.04% of balance',
        //           style: AppTextStyles.label.copyWith(
        //             fontSize: 12.sp,
        //             color: AppColors.textGrey,
        //           ),
        //         ),
        //         SizedBox(height: 8.h),
        //       ],
        //     );
        //   },
        // ),
        ValueListenableBuilder<bool>(
          valueListenable: _stopLossEnabled,
          builder: (context, enabled, child) {
            if (!enabled) return SizedBox.shrink();
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 236.w,
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 17.0),
                            child: Container(
                              width: 22.w,
                              height: 22.h,
                              alignment: Alignment.center,

                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    if (_takeProfitPrice.value > 0.01) {
                                      _takeProfitPrice.value -= 0.01;
                                      _takeProfitController
                                          .text = _takeProfitPrice.value
                                          .toStringAsFixed(2);
                                    }
                                  });
                                },
                                icon: Icon(
                                  Icons.remove,
                                  size: 16.h,
                                  color: AppColors.icongrey,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _volumeController,
                                        keyboardType:
                                            TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.label.copyWith(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          errorBorder: InputBorder.none,
                                          focusedErrorBorder: InputBorder.none,
                                          disabledBorder: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                          isDense: true,
                                        ),
                                        onChanged: (value) {
                                          final newVolume = double.tryParse(
                                            value,
                                          );
                                          if (newVolume != null &&
                                              newVolume > 0) {
                                            setState(() {
                                              volume = newVolume;
                                            });
                                          }
                                        },
                                      ),
                                    ), // Text(
                                    // volume.toStringAsFixed(2),
                                    // style: AppTextStyles.label.copyWith(
                                    // fontSize: 16.sp,
                                    // fontWeight: FontWeight.w700,
                                    // ),
                                    // ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Padding(
                            padding: const EdgeInsets.only(right: 14.0),
                            child: Container(
                              width: 22.w,
                              height: 22.h,
                              alignment: Alignment.center,

                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    volume += 0.01;
                                    _volumeController.text = volume
                                        .toStringAsFixed(2);
                                  });
                                },
                                icon: Icon(
                                  Icons.add,
                                  size: 16.h,
                                  color: AppColors.primary,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 96.w,
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.center,
                      child: _buildPriceTypeDropdown(),
                    ),
                  ],
                ),

                // _buildPriceInput('1.15550', _takeProfitPrice),
                // SizedBox(height: 4.h),
                // Text(
                //   '68 points | Profit +4.08 USD | +0.08% of balance',
                //   style: AppTextStyles.label.copyWith(
                //     fontSize: 12.sp,
                //     color: AppColors.textGrey,
                //   ),
                // ),
                SizedBox(height: 8.h),
              ],
            );
          },
        ),

        // // Advanced Settings
        _buildAdvancedSettings(),

        SizedBox(height: 24.h),

        // Confirm Button
        Container(
          width: double.infinity,
          height: 50.h,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Confirm Buy order',
                style: AppTextStyles.button.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '1.15482',
                style: AppTextStyles.button.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingOrderContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Limit Order Buttons
        Container(
          padding: EdgeInsets.all(10.spMax),
          decoration: BoxDecoration(
            color: AppColors.cardBackGround,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: ValueListenableBuilder<int>(
            valueListenable: _selectedPendingOrderType,
            builder: (context, selectedType, child) {
              return Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectedPendingOrderType.value = 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 42,
                        ),
                        height: 55.h,
                        width: 150.w,
                        decoration: BoxDecoration(
                          color:
                              selectedType == 0
                                  ? AppColors.backgroundLight
                                  : AppColors.cardBackGround,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Sell Limit',
                              style: AppTextStyles.label.copyWith(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w400,
                                color:
                                    selectedType == 0
                                        ? AppColors.textPrimary
                                        : AppColors.textGrey,
                              ),
                            ),
                            Text(
                              '1.15498',
                              style: AppTextStyles.label.copyWith(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                                color:
                                    selectedType == 0
                                        ? AppColors.red
                                        : AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectedPendingOrderType.value = 1,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 42,
                        ),
                        height: 55.h,
                        width: 150.w,
                        decoration: BoxDecoration(
                          color:
                              selectedType == 1
                                  ? AppColors.backgroundLight
                                  : AppColors.cardBackGround,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Buy Limit',
                              style: AppTextStyles.label.copyWith(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w400,
                                color:
                                    selectedType == 1
                                        ? AppColors.textPrimary
                                        : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '1.15514',
                              style: AppTextStyles.label.copyWith(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                                color:
                                    selectedType == 1
                                        ? AppColors.green
                                        : AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        SizedBox(height: 14.h),
        _buildQuentyPendingOrder(),

        // Volume Input
        // _buildVolumeInput(),
        SizedBox(height: 8.h),

        // Monetary Equivalent
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Monetary equivalent',
              style: AppTextStyles.label.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.textGrey,
              ),
            ),
            ValueListenableBuilder<double>(
              valueListenable: _openPrice,
              builder: (context, price, child) {
                return Text(
                  '${price.toStringAsFixed(2)}',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                  ),
                );
              },
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // Open Price Input
        _buildOpenPriceInput(),

        SizedBox(height: 16.h),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Distance',
              style: AppTextStyles.label.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.textGrey,
              ),
            ),
            ValueListenableBuilder<double>(
              valueListenable: _openPrice,
              builder: (context, price, child) {
                return Text(
                  '${price.toStringAsFixed(2)} points',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                  ),
                );
              },
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // Take Profit
        _buildSwitchTile(
          'Take Profit',
          _takeProfitEnabled,
          onChanged: (value) {
            _takeProfitEnabled.value = value;
            if (value) _stopLossEnabled.value = false;
          },
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _takeProfitEnabled,
          builder: (context, enabled, child) {
            if (!enabled) return SizedBox.shrink();
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 236.w,
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 17.0),
                            child: Container(
                              width: 22.w,
                              height: 22.h,
                              alignment: Alignment.center,

                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    if (_takeProfitPrice.value > 0.01) {
                                      _takeProfitPrice.value -= 0.01;
                                      _takeProfitController
                                          .text = _takeProfitPrice.value
                                          .toStringAsFixed(2);
                                    }
                                  });
                                },
                                icon: Icon(
                                  Icons.remove,
                                  size: 16.h,
                                  color: AppColors.icongrey,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _volumeController,
                                        keyboardType:
                                            TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.label.copyWith(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          errorBorder: InputBorder.none,
                                          focusedErrorBorder: InputBorder.none,
                                          disabledBorder: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                          isDense: true,
                                        ),
                                        onChanged: (value) {
                                          final newVolume = double.tryParse(
                                            value,
                                          );
                                          if (newVolume != null &&
                                              newVolume > 0) {
                                            setState(() {
                                              volume = newVolume;
                                            });
                                          }
                                        },
                                      ),
                                    ), // Text(
                                    // volume.toStringAsFixed(2),
                                    // style: AppTextStyles.label.copyWith(
                                    // fontSize: 16.sp,
                                    // fontWeight: FontWeight.w700,
                                    // ),
                                    // ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Padding(
                            padding: const EdgeInsets.only(right: 14.0),
                            child: Container(
                              width: 22.w,
                              height: 22.h,
                              alignment: Alignment.center,

                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    volume += 0.01;
                                    _volumeController.text = volume
                                        .toStringAsFixed(2);
                                  });
                                },
                                icon: Icon(
                                  Icons.add,
                                  size: 16.h,
                                  color: AppColors.primary,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 96.w,
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.center,
                      child: _buildPriceTypeDropdown(),
                    ),
                  ],
                ),

                // _buildPriceInput('1.15550', _takeProfitPrice),
                // SizedBox(height: 4.h),
                // Text(
                //   '68 points | Profit +4.08 USD | +0.08% of balance',
                //   style: AppTextStyles.label.copyWith(
                //     fontSize: 12.sp,
                //     color: AppColors.textGrey,
                //   ),
                // ),
                SizedBox(height: 8.h),
              ],
            );
          },
        ),

        // Stop Loss
        _buildSwitchTile(
          'Stop Loss',
          _stopLossEnabled,
          onChanged: (value) {
            _stopLossEnabled.value = value;
            if (value) _trailingStopEnabled.value = false;
            if (value) _breakEvenEnabled.value = false;
          },
        ),

        // ValueListenableBuilder<bool>(
        //   valueListenable: _stopLossEnabled,
        //   builder: (context, enabled, child) {
        //     if (!enabled) return SizedBox.shrink();
        //     return Column(
        //       children: [
        //         _buildPriceInput('1.15448', _stopLossPrice),
        //         SizedBox(height: 4.h),
        //         Text(
        //           '-37 points | Profit -2.22 USD | -0.04% of balance',
        //           style: AppTextStyles.label.copyWith(
        //             fontSize: 12.sp,
        //             color: AppColors.textGrey,
        //           ),
        //         ),
        //         SizedBox(height: 8.h),
        //       ],
        //     );
        //   },
        // ),
        ValueListenableBuilder<bool>(
          valueListenable: _stopLossEnabled,
          builder: (context, enabled, child) {
            if (!enabled) return SizedBox.shrink();
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 236.w,
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 17.0),
                            child: Container(
                              width: 22.w,
                              height: 22.h,
                              alignment: Alignment.center,

                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    if (_takeProfitPrice.value > 0.01) {
                                      _takeProfitPrice.value -= 0.01;
                                      _takeProfitController
                                          .text = _takeProfitPrice.value
                                          .toStringAsFixed(2);
                                    }
                                  });
                                },
                                icon: Icon(
                                  Icons.remove,
                                  size: 16.h,
                                  color: AppColors.icongrey,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _volumeController,
                                        keyboardType:
                                            TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.label.copyWith(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          errorBorder: InputBorder.none,
                                          focusedErrorBorder: InputBorder.none,
                                          disabledBorder: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                          isDense: true,
                                        ),
                                        onChanged: (value) {
                                          final newVolume = double.tryParse(
                                            value,
                                          );
                                          if (newVolume != null &&
                                              newVolume > 0) {
                                            setState(() {
                                              volume = newVolume;
                                            });
                                          }
                                        },
                                      ),
                                    ), // Text(
                                    // volume.toStringAsFixed(2),
                                    // style: AppTextStyles.label.copyWith(
                                    // fontSize: 16.sp,
                                    // fontWeight: FontWeight.w700,
                                    // ),
                                    // ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Padding(
                            padding: const EdgeInsets.only(right: 14.0),
                            child: Container(
                              width: 22.w,
                              height: 22.h,
                              alignment: Alignment.center,

                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    volume += 0.01;
                                    _volumeController.text = volume
                                        .toStringAsFixed(2);
                                  });
                                },
                                icon: Icon(
                                  Icons.add,
                                  size: 16.h,
                                  color: AppColors.primary,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 96.w,
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.center,
                      child: _buildPriceTypeDropdown(),
                    ),
                  ],
                ),

                // _buildPriceInput('1.15550', _takeProfitPrice),
                // SizedBox(height: 4.h),
                // Text(
                //   '68 points | Profit +4.08 USD | +0.08% of balance',
                //   style: AppTextStyles.label.copyWith(
                //     fontSize: 12.sp,
                //     color: AppColors.textGrey,
                //   ),
                // ),
                SizedBox(height: 8.h),
              ],
            );
          },
        ),

        // Stop Loss

        // Advanced Settings
        _buildAdvancedSettings(),

        SizedBox(height: 24.h),

        // Place Order Button
        Container(
          width: double.infinity,
          height: 50.h,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Place Buy Limit order',
                style: AppTextStyles.button.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '1.15505',
                style: AppTextStyles.button.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 236.w,
          height: 50.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 17.0),
                child: Container(
                  width: 22.w,
                  height: 22.h,
                  alignment: Alignment.center,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        if (volume > 0.01) {
                          volume -= 0.01;
                          _volumeController.text = volume.toStringAsFixed(2);
                        }
                      });
                    },
                    icon: Icon(
                      Icons.remove,
                      size: 16.h,
                      color: AppColors.icongrey,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Volume',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textGrey,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _volumeController,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.label.copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                            onChanged: (value) {
                              final newVolume = double.tryParse(value);
                              if (newVolume != null && newVolume > 0) {
                                setState(() {
                                  volume = newVolume;
                                });
                              }
                            },
                          ),
                        ), // Text(
                        // volume.toStringAsFixed(2),
                        // style: AppTextStyles.label.copyWith(
                        // fontSize: 16.sp,
                        // fontWeight: FontWeight.w700,
                        // ),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Padding(
                padding: const EdgeInsets.only(right: 14.0),
                child: Container(
                  width: 22.w,
                  height: 22.h,
                  alignment: Alignment.center,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        volume += 0.01;
                        _volumeController.text = volume.toStringAsFixed(2);
                      });
                    },
                    icon: Icon(Icons.add, size: 16.h, color: AppColors.primary),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 96.w,
          height: 48.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: Text(
            "lots",
            style: AppTextStyles.label.copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuentyPendingOrder() {
    return Container(
      height: 117.h,
      width: 343.w,
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildVolumeInputScreen(context, false),
          Container(width: double.maxFinite, height: 2, color: AppColors.grey),
          SizedBox(height: 6.h),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 11.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "Required Margin",
                      style: AppTextStyles.labelOnChartPendingOrder,
                    ),
                    SizedBox(width: 4.w),
                    Icon(Icons.info_outline_rounded, size: 16.h),
                  ],
                ),
                Text(
                  "\$0.066%",
                  style: AppTextStyles.labelOnChartPendingOrderBold,
                ),
              ],
            ),
          ),
          SizedBox(height: 6.h),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 11.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Free margin",
                  style: AppTextStyles.labelOnChartPendingOrder,
                ),
                Text("\$356.68", style: AppTextStyles.labelOnChartPendingOrder),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenPriceInput() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 2.h),
      child: Container(
        height: 48.h,
        padding: EdgeInsets.symmetric(horizontal: 11.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Minus button
            Container(
              height: 24.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // color: AppColors.icongrey,
                border: Border.all(color: AppColors.icongrey),
              ),
              width: 24.w,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    if (volume > 0.01) {
                      volume -= 0.01;
                      _volumeController.text = volume.toStringAsFixed(2);
                    }
                  });
                },
                icon: Icon(Icons.remove, size: 18.h, color: AppColors.icongrey),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ),

            // Volume display
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Quantity (lots)',
                    style: AppTextStyles.labelOnTradeQuantity,
                  ),
                  // SizedBox(height: 1.h),
                  TextField(
                    controller: _volumeController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelOnTradeQuantityDigit,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      final newVolume = double.tryParse(value);
                      if (newVolume != null && newVolume > 0) {
                        setState(() {
                          volume = newVolume;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            // Plus button
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // color: AppColors.icongrey,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              width: 24.w,
              height: 24.h,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    volume += 0.01;
                    _volumeController.text = volume.toStringAsFixed(2);
                  });
                },
                icon: Icon(Icons.add, size: 18.h, color: AppColors.primary),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceInput(String label, ValueNotifier<double> priceNotifier) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ValueListenableBuilder<double>(
        valueListenable: priceNotifier,
        builder: (context, price, child) {
          return Row(
            children: [
              Container(
                width: 32.w,
                height: 32.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: IconButton(
                  onPressed: () {
                    if (price > 0.01) priceNotifier.value = price - 0.01;
                  },
                  icon: Icon(Icons.remove, size: 16.h, color: Colors.grey[600]),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    price.toStringAsFixed(5),
                    style: AppTextStyles.label.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              Container(
                width: 32.w,
                height: 32.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary),
                ),
                child: IconButton(
                  onPressed: () {
                    priceNotifier.value = price + 0.01;
                  },
                  icon: Icon(Icons.add, size: 16.h, color: AppColors.primary),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ),
              SizedBox(width: 12.w),
              _buildPriceTypeDropdown(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    ValueNotifier<bool> valueNotifier, {
    required Function(bool) onChanged,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: valueNotifier,
      builder: (context, value, child) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                textAlign: TextAlign.start,
                style: AppTextStyles.label.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textGrey,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  height: 20.h,
                  width: 25.w,
                  child: Transform.scale(
                    scale: 0.8, // Adjust this scale to control total size
                    child: Switch(
                      value: value,
                      onChanged: onChanged,
                      activeColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withOpacity(0.3),
                      inactiveThumbColor: AppColors.whiteColor,
                      inactiveTrackColor: AppColors.icongrey.withAlpha(55),
                      trackOutlineColor: WidgetStateProperty.all(
                        Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdvancedSettings() {
    return ValueListenableBuilder<bool>(
      valueListenable: _advanceSettingsEnabled,
      builder: (context, expanded, child) {
        return Column(
          children: [
            GestureDetector(
              onTap: () => _advanceSettingsEnabled.value = !expanded,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Advanced settings',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.primary,
                      size: 20.h,
                    ),
                  ],
                ),
              ),
            ),
            if (expanded) ...[
              SizedBox(height: 8.h),
              _buildSwitchTile(
                'Trailing stop',
                _trailingStopEnabled,
                onChanged: (value) {
                  _trailingStopEnabled.value = value;
                  if (value) _stopLossEnabled.value = false;
                  if (value) _breakEvenEnabled.value = false;
                },
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _trailingStopEnabled,
                builder: (context, enabled, child) {
                  if (!enabled) return SizedBox.shrink();
                  return Column(
                    children: [
                      SizedBox(height: 8.h),
                      _buildDistanceInput(),
                      SizedBox(height: 8.h),
                    ],
                  );
                },
              ),

              _buildSwitchTile(
                'Break even',
                _breakEvenEnabled,
                onChanged: (value) {
                  _breakEvenEnabled.value = value;
                  if (value) _trailingStopEnabled.value = false;
                  if (value) _stopLossEnabled.value = false;
                },
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _breakEvenEnabled,
                builder: (context, enabled, child) {
                  if (!enabled) return SizedBox.shrink();
                  return Column(
                    children: [
                      SizedBox(height: 8.h),
                      _buildDistanceInput(),
                      SizedBox(height: 8.h),
                    ],
                  );
                },
              ),
              ValueListenableBuilder<int>(
                valueListenable: _selectedOrderTab,
                builder: (context, selectedTab, child) {
                  return selectedTab == 1
                      ? Column(
                        children: [
                          _buildSwitchTile(
                            'Order expiration',
                            _orderExpirationEnabled,
                            onChanged: (value) {
                              _orderExpirationEnabled.value = value;
                            },
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: _orderExpirationEnabled,
                            builder: (context, enabled, child) {
                              if (!enabled) return SizedBox.shrink();
                              return Column(
                                children: [
                                  SizedBox(height: 8.h),
                                  _buildOrderExpirationInput(),
                                  SizedBox(height: 8.h),
                                ],
                              );
                            },
                          ),
                        ],
                      )
                      : SizedBox.shrink();
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildOrderExpirationInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // First container - Display selected date/time with calendar icon
            InkWell(
              onTap: _selectOrderExpirationDate,
              child: Container(
                width: 150.w,
                height: 50.h,
                padding: EdgeInsets.only(left: 12.w, top: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Date',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textGrey,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ValueListenableBuilder<DateTime>(
                        valueListenable: _orderExpirationDate,
                        builder: (context, dateTime, child) {
                          return Text(
                            DateFormat('MMM dd, yyyy').format(dateTime),
                            style: AppTextStyles.label.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Third container - Time picker button
            Container(
              width: 150.w,
              height: 50.h,
              padding: EdgeInsets.only(left: 12.w, top: 6.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.border),
              ),
              child: InkWell(
                onTap: _selectOrderExpirationTime,
                borderRadius: BorderRadius.circular(8.r),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textGrey,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    ValueListenableBuilder<DateTime>(
                      valueListenable: _orderExpirationTime,
                      builder: (context, dateTime, child) {
                        return Text(
                          DateFormat('hh:MM').format(dateTime),
                          style: AppTextStyles.label.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectOrderExpirationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _orderExpirationDate.value,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // Keep the current time, only update the date
      final currentDateTime = _orderExpirationDate.value;
      final newDateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        currentDateTime.hour,
        currentDateTime.minute,
      );
      _orderExpirationDate.value = newDateTime;
    }
  }

  Future<void> _selectOrderExpirationTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_orderExpirationTime.value),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // Keep the current date, only update the time
      final currentDateTime = _orderExpirationTime.value;
      final newDateTime = DateTime(
        currentDateTime.year,
        currentDateTime.month,
        currentDateTime.day,
        picked.hour,
        picked.minute,
      );
      _orderExpirationTime.value = newDateTime;
    }
  }

  Widget _buildDistanceInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distance, points',
          style: AppTextStyles.label.copyWith(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textGrey,
          ),
        ),
        SizedBox(height: 8.h),
        ValueListenableBuilder<double>(
          valueListenable: _distance,
          builder: (context, distance, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 340.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 17.0),
                        child: Container(
                          width: 22.w,
                          height: 22.h,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: IconButton(
                            onPressed: () {
                              if (distance > 10) {
                                _distance.value = distance - 10;
                                distanceController.text = _distance.value
                                    .toStringAsFixed(2);
                              }
                            },
                            icon: Icon(
                              Icons.remove,
                              size: 16.h,
                              color: AppColors.icongrey,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: distanceController,
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.label.copyWith(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      focusedErrorBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      isDense: true,
                                    ),
                                    onChanged: (value) {
                                      if (value.isNotEmpty) {
                                        try {
                                          double newDistance = double.parse(
                                            value,
                                          );
                                          if (newDistance > 0) {
                                            _distance.value = newDistance;
                                          }
                                        } catch (e) {
                                          // Handle invalid input
                                        }
                                      }
                                    },
                                  ),
                                ), // Text(
                                // volume.toStringAsFixed(2),
                                // style: AppTextStyles.label.copyWith(
                                // fontSize: 16.sp,
                                // fontWeight: FontWeight.w700,
                                // ),
                                // ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Padding(
                        padding: const EdgeInsets.only(right: 14.0),
                        child: Container(
                          width: 22.w,
                          height: 22.h,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: IconButton(
                            onPressed: () {
                              _distance.value = distance + 10;
                              distanceController.text = _distance.value
                                  .toStringAsFixed(2);
                            },
                            icon: Icon(
                              Icons.add,
                              size: 16.h,
                              color: AppColors.primary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );

            //  Row(
            //   children: [
            //     Container(
            //       width: 32.w,
            //       height: 32.h,
            //       decoration: BoxDecoration(
            //         shape: BoxShape.circle,
            //         border: Border.all(color: Colors.grey[400]!),
            //       ),
            //       child: IconButton(
            //         onPressed: () {
            //           if (distance > 10) _distance.value = distance - 10;
            //         },
            //         icon: Icon(
            //           Icons.remove,
            //           size: 16.h,
            //           color: Colors.grey[600],
            //         ),
            //         padding: EdgeInsets.zero,
            //         constraints: BoxConstraints(),
            //       ),
            //     ),
            //     Expanded(
            //       child: Center(
            //         child: Text(
            //           distance.toInt().toString(),
            //           style: AppTextStyles.label.copyWith(
            //             fontSize: 18.sp,
            //             fontWeight: FontWeight.w700,
            //             color: AppColors.textPrimary,
            //           ),
            //         ),
            //       ),
            //     ),
            //     Container(
            //       width: 32.w,
            //       height: 32.h,
            //       decoration: BoxDecoration(
            //         shape: BoxShape.circle,
            //         border: Border.all(color: AppColors.primary),
            //       ),
            //       child: IconButton(
            //         onPressed: () {
            //           _distance.value = distance + 10;
            //         },
            //         icon: Icon(
            //           Icons.add,
            //           size: 16.h,
            //           color: AppColors.primary,
            //         ),
            //         padding: EdgeInsets.zero,
            //         constraints: BoxConstraints(),
            //       ),
            //     ),
            //   ],
            // );
          },
        ),
      ],
    );
  }

  Widget _buildPriceTypeDropdown() {
    return ValueListenableBuilder<String>(
      valueListenable: selectedPriceType,
      builder: (context, value, child) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              icon: Icon(
                Icons.keyboard_arrow_down,
                size: 16.h,
                color: AppColors.textGrey,
              ),
              style: AppTextStyles.label.copyWith(
                fontSize: 12.sp,
                color: AppColors.textGrey,
              ),
              items: [
                DropdownMenuItem<String>(
                  value: 'Asset Price',
                  child: Text('Asset Price'),
                ),
                DropdownMenuItem<String>(
                  value: 'Profit in \$',
                  child: Text('Profit in \$'),
                ),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  selectedPriceType.value = newValue;
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _showAccountSelectionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Obx(() {
            final accounts = accountController.accounts;
            // Calculate dynamic height based on number of accounts
            double dynamicHeight;
            if (accounts.isNotEmpty) {
              if (accounts.length <= 2) {
                // If 2 accounts or fewer, take 1/4 of screen height
                dynamicHeight = MediaQuery.of(context).size.height * 0.35;
              } else if (accounts.length <= 3) {
                // If 2 accounts or fewer, take 1/4 of screen height
                dynamicHeight = MediaQuery.of(context).size.height * 0.45;
              } else if (accounts.length <= 4) {
                // If 2 accounts or fewer, take 1/4 of screen height
                dynamicHeight = MediaQuery.of(context).size.height * 0.55;
              } else {
                // If more than 3 accounts, take 1/7 of screen height
                dynamicHeight = MediaQuery.of(context).size.height * 0.65;
              }
            } else {
              // Default height if state is not loaded
              dynamicHeight = MediaQuery.of(context).size.height * 0.3;
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
                  // Handle bar
                  Container(
                    margin: EdgeInsets.only(top: 12.h),
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Title
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

                  // Scrollable Account list
                  if (accounts.isNotEmpty) ...[
                    Expanded(
                      child: ListView.builder(
                        // padding: EdgeInsets.symmetric(horizontal: 16.w),
                        padding: EdgeInsets.zero,
                        itemCount: accounts.length,
                        itemBuilder: (context, index) {
                          final account = accounts[index];
                          final isActive =
                              accountController.activeAccount?.id == account.id;
                          return Container(
                            // margin: EdgeInsets.symmetric(vertical: 4.h),
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
                                groupValue: accountController.activeAccount?.id,
                                onChanged: (value) {
                                  if (value != null) {
                                    accountController.setActiveAccount(value);
                                    Navigator.pop(context);
                                  }
                                },
                                activeColor: AppColors.primary,
                              ),
                              onTap: () {
                                accountController.setActiveAccount(account.id);
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
                  ] else ...[
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(20.w),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ],

                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            );
          }),
    );
  }

  // Helper methods from instruments screen
  String _getMarketStatus(String status) {
    // Extract time and percentage from status like "01:00:00 H 16.0"
    if (status.contains('H') || status.contains('S')) {
      final parts = status.split(' ');
      if (parts.length >= 3) {
        final time = parts[0];
        final type = parts[1];
        final value = parts[2];

        if (type == 'S') {
          // Show active status with percentage
          return '$time +$value% S:${value.split('.')[0]}.${value.split('.')[1]}';
        } else {
          // Show market closed
          return 'Market closed';
        }
      }
    }
    return 'Market closed';
  }

  String _getFirstFlag(String flag) {
    // Extract first flag from combined flag string
    if (flag.length >= 4) {
      return flag.substring(0, 2);
    }
    return flag;
  }

  String _getSecondFlag(String flag) {
    // Extract second flag from combined flag string
    if (flag.length >= 4) {
      return flag.substring(2, 4);
    }
    return '';
  }
}
