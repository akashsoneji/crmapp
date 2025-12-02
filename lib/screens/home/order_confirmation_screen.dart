import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import '../../routes/app_pages.dart';
import '../../constants/color.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final String symbol;
  final String orderType; // "buy" or "sell" or "1" for sell
  final double volume;
  final double? price;
  final Function()? onNavigateToTrade;

  const OrderConfirmationScreen({
    Key? key,
    required this.orderData,
    required this.symbol,
    required this.orderType,
    required this.volume,
    this.price,
    this.onNavigateToTrade,
  }) : super(key: key);

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  Timer? _autoNavigateTimer;
  Timer? _countdownTimer;
  int _remainingSeconds = 2;

  @override
  void initState() {
    super.initState();
    print('✅ OrderConfirmationScreen: Initialized');
    print('✅ OrderConfirmationScreen: Order data: ${widget.orderData}');

    // Start countdown timer
    _startCountdown();

    // Auto-navigate after 1 minute
    _autoNavigateTimer = Timer(const Duration(seconds: 2), () {
      print('⏰ OrderConfirmationScreen: 1 minute elapsed, auto-navigating...');
      _navigateToTrade();
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _navigateToTrade() {
    if (!mounted) return;

    print('🚀 OrderConfirmationScreen: Starting navigation to trade screen...');

    // Cancel timers to prevent multiple navigations
    _autoNavigateTimer?.cancel();
    _countdownTimer?.cancel();

    // Store callback before removing screen (in case widget is disposed)
    final callback = widget.onNavigateToTrade;

    // Execute callback FIRST to switch to trade tab in TradingMainScreen
    // This ensures we navigate directly to trade screen without showing chart
    if (callback != null) {
      print(
        '🚀 OrderConfirmationScreen: Executing callback to switch to trade tab...',
      );
      try {
        callback(); // This switches to trade tab in TradingMainScreen
        print(
          '✅ OrderConfirmationScreen: Callback executed, switched to trade tab',
        );
      } catch (e) {
        print('❌ OrderConfirmationScreen: Error executing callback: $e');
      }
    }

    // Then remove confirmation screen from navigation stack
    // Use Get.until() to go back to TradingMainScreen (which is now showing trade tab)
    Future.delayed(const Duration(milliseconds: 150), () {
      print(
        '🚀 OrderConfirmationScreen: Removing confirmation screen from stack...',
      );
      // Remove confirmation screen, go back to TradingMainScreen
      // This ensures we go directly to trade screen without showing chart
      Get.until((route) {
        // Go back until we reach TradingMainScreen (route name is '/trading')
        final routeName = route.settings.name;
        print('🔍 OrderConfirmationScreen: Checking route: $routeName');
        return routeName == Routes.TRADING;
      });
      print(
        '✅ OrderConfirmationScreen: Removed confirmation screen, now on trade screen',
      );
    });
  }

  @override
  void dispose() {
    _autoNavigateTimer?.cancel();
    _countdownTimer?.cancel();
    print('🗑️ OrderConfirmationScreen: Disposed');
    super.dispose();
  }

  String _getOrderTypeDisplay() {
    final type = widget.orderType.toLowerCase();
    if (type == 'buy' || type == '0' || type == '2' || type == '4') {
      return 'market buy';
    } else if (type == 'sell' || type == '1' || type == '3' || type == '5') {
      return 'market sell';
    }
    return 'market order';
  }

  String _getSymbolDisplay() {
    // Remove suffix if present (e.g., "EURUSD.c" -> "EURUSD")
    return widget.symbol.replaceAll(RegExp(r'\.\w+$'), '');
  }

  String _getSymbolDescription() {
    final symbol = _getSymbolDisplay();
    // Map common symbols to descriptions
    final descriptions = {
      'EURUSD': 'Euro vs US Dollar',
      'GBPUSD': 'British Pound vs US Dollar',
      'USDJPY': 'US Dollar vs Japanese Yen',
      'XAUUSD': 'Gold vs US Dollar',
      'ES35': 'ES35 Index',
    };
    return descriptions[symbol] ?? '$symbol Pair';
  }

  @override
  Widget build(BuildContext context) {
    // Get order ID from response - check multiple possible fields
    final orderTicket =
        widget.orderData['OrderTicket']?.toString() ??
        widget.orderData['orderTicket']?.toString() ??
        widget.orderData['Order_ID']?.toString() ??
        widget.orderData['order_id']?.toString() ??
        widget.orderData['id']?.toString() ??
        'N/A';

    print('🔍 OrderConfirmationScreen: Order ID extracted: $orderTicket');
    print('🔍 OrderConfirmationScreen: Full order data: ${widget.orderData}');

    final executionPrice =
        widget.price?.toStringAsFixed(2) ??
        widget.orderData['price']?.toString() ??
        widget.orderData['Price']?.toString() ??
        'N/A';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => _navigateToTrade(),
                    child: Icon(
                      Icons.arrow_back,
                      size: 24.h,
                      color: AppColors.textGrey,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Symbol and description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.symbol,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 18.sp,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                        Text(
                          _getSymbolDescription(),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Order confirmation content
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Lottie success animation
                      SizedBox(
                        width: 200.w,
                        height: 200.h,
                        child: Lottie.asset(
                          'assets/animation/success.json',
                          fit: BoxFit.contain,
                          repeat: false,
                        ),
                      ),
                      SizedBox(height: 32.h),
                      // Order details
                      Text(
                        '#$orderTicket ${_getOrderTypeDisplay()} ${widget.volume.toStringAsFixed(2)} ${widget.symbol} at',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // Price
                      Text(
                        executionPrice,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // Done status
                      Text(
                        'done',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 32.h),
                      // Auto-navigate countdown
                      Text(
                        'Redirecting to trade screen in $_remainingSeconds seconds...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
