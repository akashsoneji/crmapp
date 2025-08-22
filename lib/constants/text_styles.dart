import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/constants/color.dart';

class AppTextStyles {
  static final heading = TextStyle(
    fontSize: 31.sp,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  static final subheading = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    color: Colors.grey,
  );

  static final label = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: Colors.black,
  );

  static final input = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    color: Colors.black,
  );

  static final link = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.underline,
    color: Color(0xFF692EAF),
  );

  static final button = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  static final labelOnTradeButton = TextStyle(
    fontSize: 15.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.primary,
    letterSpacing: 2.sp,
  );

  static final labelOnTradeQuantity = TextStyle(
    fontSize: 10.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.icongrey,
  );

  static final labelOnTradeQuantityDigit = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static final labelOnTradeDifference = TextStyle(
    fontSize: 11.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.tradeTextCenterColor,
  );

  static final labelOnTradePriceAlertGrey = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.tradeTextCenterColor,
  );
  static final labelOnTradePriceAlertBlack = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static final labelOnTradeBottomTitle = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static final labelOnChartPendingOrder = TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.tradeTextCenterColor,
  );
  static final labelOnChartPendingOrderBold = TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );
}
