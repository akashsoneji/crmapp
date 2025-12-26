import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/color.dart';
import '../constants/text_styles.dart';
import '../services/notification_service.dart';
import '../services/price_alert_monitor_service.dart';
import '../utils/precision_helper.dart';

class PriceAlertDialog extends StatefulWidget {
  final String symbol;
  final double currentPrice;
  final int digits; // Digits from socket data

  const PriceAlertDialog({
    super.key,
    required this.symbol,
    required this.currentPrice,
    this.digits = 5, // Default to 5 if not provided
  });

  @override
  State<PriceAlertDialog> createState() => _PriceAlertDialogState();
}

class _PriceAlertDialogState extends State<PriceAlertDialog> {
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _selectedCondition = 'above';
  bool _isLoading = false;
  double _price = 0.0;
  late int _decimalDigits;
  final NotificationService _notificationService = NotificationService();
  final PriceAlertMonitorService _monitorService = PriceAlertMonitorService();

  @override
  void initState() {
    super.initState();
    _decimalDigits = widget.digits; // Use digits from socket data
    _price = PrecisionHelper.round(
      widget.currentPrice,
      decimals: _decimalDigits,
    );
    _priceController.text = PrecisionHelper.formatPrice(
      _price,
      decimals: _decimalDigits,
    );
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
  }

  // Calculate pip increment based on digits from socket data
  // Always changes the LAST digit: 1 / (10^digits)
  // digits = 2 → 0.01 (1/10^2)
  // digits = 3 → 0.001 (1/10^3)
  // digits = 4 → 0.0001 (1/10^4)
  // digits = 5 → 0.00001 (1/10^5)
  double _getPipIncrement() {
    // Calculate 10^digits
    double multiplier = 1.0;
    for (int i = 0; i < _decimalDigits; i++) {
      multiplier *= 10.0;
    }
    return 1.0 / multiplier;
  }

  String _getPriceChangePercentage() {
    if (widget.currentPrice == 0 || _price == 0) {
      return "0.000%";
    }
    try {
      final change =
          ((_price - widget.currentPrice) / widget.currentPrice) * 100;
      return PrecisionHelper.formatPercentage(change, decimals: 3);
    } catch (e) {
      return "0.000%";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 20.w,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20.w,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 2.h, bottom: 10.h),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.grey,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    width: 30.w,
                    height: 4.h,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'New Price Alert',
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Container(
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
                        border: Border.all(color: AppColors.icongrey),
                      ),
                      width: 24.w,
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            final pipIncrement = _getPipIncrement();
                            // Parse current value from TextField controller
                            final currentValue =
                                double.tryParse(_priceController.text) ??
                                _price;
                            final newValue = currentValue - pipIncrement;
                            _price = PrecisionHelper.round(
                              newValue < 0 ? 0 : newValue,
                              decimals: _decimalDigits,
                            );
                            _priceController.text = PrecisionHelper.formatPrice(
                              _price,
                              decimals: _decimalDigits,
                            );
                          });
                        },
                        icon: Icon(
                          Icons.remove,
                          size: 18.h,
                          color: AppColors.icongrey,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ),

                    // Price display
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Price',
                            style: AppTextStyles.labelOnTradeQuantity,
                          ),
                          TextField(
                            controller: _priceController,
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
                              // Allow user to type freely - only update if we have a valid number
                              if (value.isEmpty ||
                                  value == '.' ||
                                  value == '-') {
                                return; // Don't update while user is typing invalid input
                              }
                              final parsed = double.tryParse(value);
                              if (parsed != null && parsed > 0) {
                                final newPrice = PrecisionHelper.round(
                                  parsed,
                                  decimals: _decimalDigits,
                                );
                                setState(() {
                                  _price = newPrice;
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
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      width: 24.w,
                      height: 24.h,
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            final pipIncrement = _getPipIncrement();
                            // Parse current value from TextField controller
                            final currentValue =
                                double.tryParse(_priceController.text) ??
                                _price;
                            final newValue = currentValue + pipIncrement;
                            _price = PrecisionHelper.round(
                              newValue,
                              decimals: _decimalDigits,
                            );
                            _priceController.text = PrecisionHelper.formatPrice(
                              _price,
                              decimals: _decimalDigits,
                            );
                          });
                        },
                        icon: Icon(
                          Icons.add,
                          size: 18.h,
                          color: AppColors.primary,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Price Change",
                    style: AppTextStyles.labelOnTradePriceAlertGrey,
                  ),
                  Text(
                    _getPriceChangePercentage(),
                    style: AppTextStyles.labelOnTradePriceAlertBlack,
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Current bid price",
                    style: AppTextStyles.labelOnTradePriceAlertGrey,
                  ),
                  Text(
                    PrecisionHelper.formatPrice(
                      widget.currentPrice,
                      decimals: _decimalDigits,
                    ),
                    style: AppTextStyles.labelOnTradePriceAlertBlack,
                  ),
                ],
              ),

              SizedBox(height: 25.h),

              // Action buttons
              SafeArea(
                child: Row(
                  children: [
                    // Set alert button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _setPriceAlert,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child:
                            _isLoading
                                ? SizedBox(
                                  height: 20.h,
                                  width: 20.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text('Set Alert'),
                      ),
                    ),
                  ],
                ),
              ),
              // SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConditionButton(String value, String label) {
    final isSelected = _selectedCondition == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCondition = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Future<void> _setPriceAlert() async {
    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a price')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final price = PrecisionHelper.parseDouble(
        _priceController.text,
        decimals: _decimalDigits,
      );
      if (price <= 0) {
        throw Exception('Invalid price');
      }

      // Check and request notification permissions
      if (!_notificationService.hasPermission) {
        final granted = await _notificationService.requestPermissions();
        if (!granted) {
          throw Exception(
            'Notification permission is required for price alerts',
          );
        }
      }

      // Add alert to monitoring service for real-time checking
      await _monitorService.addPriceAlert(
        symbol: widget.symbol,
        targetPrice: price,
        condition: _selectedCondition,
        currentPrice: widget.currentPrice,
        message:
            _messageController.text.isNotEmpty ? _messageController.text : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Price alert set successfully! You will be notified when ${widget.symbol} reaches \$${PrecisionHelper.formatPrice(price, decimals: _decimalDigits)}.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting price alert: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testNotification() async {
    try {
      await _notificationService.showTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Test notification sent! Check your notification panel.',
            ),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test notification failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
