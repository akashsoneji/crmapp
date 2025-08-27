import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/constants/color.dart';

class AppTextStyles {

  static final screenTitle = TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static final heading = TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.55,
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

  static final grey10400 = TextStyle(
    fontSize: 10.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.icongrey,
  );
  static final grey11400 = TextStyle(
    fontSize: 11.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.icongrey,
  );
  static final black11400 = TextStyle(
    fontSize: 11.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static final black14500 = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static final black16400h37 = TextStyle(
    fontSize: 16.sp,
    height: 1.37,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static final black16600 = TextStyle(
    fontSize: 16.sp,

    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static final grey14400h57 = TextStyle(
    fontSize: 14.sp,
    height: 1.57,
    fontWeight: FontWeight.w400,
    color: AppColors.icongrey,
  );

  static final black15400h9 = TextStyle(
    fontSize: 15.sp,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static final black14600h1_71 = TextStyle(
    fontSize: 15.sp,
    height: 1.71,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static final black24600h1_42 = TextStyle(
    fontSize: 24.sp,
    height: 1.42,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
}
