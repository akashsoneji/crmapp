import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:crm_app/constants/color.dart';

// ============================================================================
// PROFESSIONAL FONT SYSTEM
// ============================================================================
// Font Families:
// - Plus Jakarta Sans: UI text, headings, buttons, labels
// - Inter: Numbers, financial data, prices, tabular data
// ============================================================================

class AppTextStyles {
  // ==========================================================================
  // UI FONTS (Plus Jakarta Sans) - For headings, body, buttons
  // ==========================================================================

  // Screen Title - Main app bar titles
  static TextStyle get screenTitle => GoogleFonts.plusJakartaSans(
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  // Heading - Section headings
  static TextStyle get heading => GoogleFonts.plusJakartaSans(
    fontSize: 18.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.55,
    letterSpacing: -0.2,
  );

  // Heading Black - Emphasis headings
  static TextStyle get headingblack => GoogleFonts.plusJakartaSans(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.55,
    letterSpacing: -0.2,
  );

  // H1 Title - Large centered titles (24px bold as per reference)
  static TextStyle get centerbodyHeading => GoogleFonts.plusJakartaSans(
    fontSize: 24.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.5,
  );

  // H2 Main Title - Page/section titles (20px as per reference)
  static TextStyle get mainTitle => GoogleFonts.plusJakartaSans(
    fontSize: 20.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.3,
  );

  // Welcome Title - Login/Welcome screen main title
  static TextStyle get welcomeTitle => GoogleFonts.plusJakartaSans(
    fontSize: 24.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  // Subtitle - Secondary descriptive text (12px as per reference)
  static TextStyle get subheading => GoogleFonts.plusJakartaSans(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: 0,
    height: 1.4,
  );

  // Label - Form labels, field labels
  static TextStyle get label => GoogleFonts.plusJakartaSans(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
  );

  // Input - Text input content
  static TextStyle get input => GoogleFonts.plusJakartaSans(
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: 0,
  );

  // Link - Clickable links
  static TextStyle get link => GoogleFonts.plusJakartaSans(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    decoration: TextDecoration.underline,
    color: AppColors.primary,
    letterSpacing: 0,
  );

  // Black 14 600 - Semi-bold 14sp
  static TextStyle get black14600 => GoogleFonts.plusJakartaSans(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
  );

  // Button - Primary button text (on dark backgrounds)
  static TextStyle get button => GoogleFonts.plusJakartaSans(
    fontSize: 15.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.whiteColor,
    letterSpacing: 0.2,
  );

  // Label On Trade Button - Trade action buttons
  static TextStyle get labelOnTradeButton => GoogleFonts.plusJakartaSans(
    fontSize: 15.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.whiteColor,
    letterSpacing: 2.sp,
  );

  // Text Button - Text buttons on light backgrounds
  static TextStyle get textButton => GoogleFonts.plusJakartaSans(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
    letterSpacing: 0.1,
  );

  // Outlined Button - Outlined button text
  static TextStyle get outlinedButton => GoogleFonts.plusJakartaSans(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
    letterSpacing: 0.1,
  );

  // Card Title - Card/section titles
  static TextStyle get cardTitle => GoogleFonts.plusJakartaSans(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  // Card Subtitle - Card/section subtitles
  static TextStyle get cardSubtitle => GoogleFonts.plusJakartaSans(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
    letterSpacing: -0.1,
  );

  // Body Text - General body content
  static TextStyle get bodyText => GoogleFonts.plusJakartaSans(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
    letterSpacing: 0,
  );

  // Caption - Small descriptive text
  static TextStyle get caption => GoogleFonts.plusJakartaSans(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
    letterSpacing: 0,
  );

  // Hint Text - Input hints, placeholders
  static TextStyle get hint => GoogleFonts.plusJakartaSans(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.hint,
    letterSpacing: 0,
  );

  // Error Text - Error messages
  static TextStyle get error => GoogleFonts.plusJakartaSans(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.error,
    letterSpacing: 0,
  );

  // Success Text - Success messages
  static TextStyle get success => GoogleFonts.plusJakartaSans(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.success,
    letterSpacing: 0,
  );

  // Warning Text - Warning messages
  static TextStyle get warning => GoogleFonts.plusJakartaSans(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.warning,
    letterSpacing: 0,
  );

  // Label On Trade Quantity - Small quantity labels
  static TextStyle get labelOnTradeQuantity => GoogleFonts.plusJakartaSans(
    fontSize: 10.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.icongrey,
    letterSpacing: 0,
  );

  // Label On Trade Quantity Digit - Quantity values
  static TextStyle get labelOnTradeQuantityDigit => GoogleFonts.plusJakartaSans(
    fontSize: 16.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: 0,
  );

  // Label On Trade Difference - P&L difference
  static TextStyle get labelOnTradeDifference => GoogleFonts.plusJakartaSans(
    fontSize: 11.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.tradeTextCenterColor,
    letterSpacing: 0,
  );

  // Label On Trade Price Alert Grey - Price alert labels
  static TextStyle get labelOnTradePriceAlertGrey => GoogleFonts.plusJakartaSans(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.tradeTextCenterColor,
    letterSpacing: 0,
  );

  // Label On Trade Price Alert Black - Price alert values
  static TextStyle get labelOnTradePriceAlertBlack => GoogleFonts.plusJakartaSans(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: 0,
  );

  // Label On Trade Bottom Title - Bottom section titles
  static TextStyle get labelOnTradeBottomTitle => GoogleFonts.plusJakartaSans(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
  );

  // Label On Chart Pending Order - Pending order labels
  static TextStyle get labelOnChartPendingOrder => GoogleFonts.plusJakartaSans(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.tradeTextCenterColor,
    letterSpacing: 0,
  );

  // Label On Chart Pending Order Bold - Pending order emphasis
  static TextStyle get labelOnChartPendingOrderBold => GoogleFonts.plusJakartaSans(
    fontSize: 12.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
    letterSpacing: 0,
  );

  // Grey 10 400 - Small grey text
  static TextStyle get grey10400 => GoogleFonts.plusJakartaSans(
    fontSize: 10.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.icongrey,
    letterSpacing: 0,
  );

  // Grey 11 400 - Tiny grey text
  static TextStyle get grey11400 => GoogleFonts.plusJakartaSans(
    fontSize: 11.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.icongrey,
    letterSpacing: 0,
  );

  // Black 11 400 - Tiny black text
  static TextStyle get black11400 => GoogleFonts.plusJakartaSans(
    fontSize: 11.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: 0,
  );

  // Black 14 500 - Medium black text
  static TextStyle get black14500 => GoogleFonts.plusJakartaSans(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
  );

  // Black 16 400 Height 1.37 - Body with specific height
  static TextStyle get black16400h37 => GoogleFonts.plusJakartaSans(
    fontSize: 16.sp,
    height: 1.37,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: 0,
  );

  // Black 16 400 Height 1.5 - Body with comfortable height
  static TextStyle get black16400h1_5 => GoogleFonts.plusJakartaSans(
    fontSize: 16.sp,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: 0,
  );

  // Black 16 600 - Semi-bold 16sp
  static TextStyle get black16600 => GoogleFonts.plusJakartaSans(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  // Grey 14 400 Height 1.57 - Grey body with height
  static TextStyle get grey14400h57 => GoogleFonts.plusJakartaSans(
    fontSize: 14.sp,
    height: 1.57,
    fontWeight: FontWeight.w400,
    color: AppColors.icongrey,
    letterSpacing: 0,
  );

  // Black 15 400 Height 1.4 - Body text
  static TextStyle get black15400h9 => GoogleFonts.plusJakartaSans(
    fontSize: 15.sp,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: 0,
  );

  // Black 14 600 Height 1.71 - Button/label with height
  static TextStyle get black14600h1_71 => GoogleFonts.plusJakartaSans(
    fontSize: 15.sp,
    height: 1.71,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );

  // Black 24 600 Height 1.42 - Large display text
  static TextStyle get black24600h1_42 => GoogleFonts.plusJakartaSans(
    fontSize: 24.sp,
    height: 1.42,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  // ==========================================================================
  // NUMBER FONTS (Inter) - For financial data, prices, quantities
  // ==========================================================================

  // Number Display - Large numbers (equity, balance)
  static TextStyle get numberDisplay => GoogleFonts.inter(
    fontSize: 24.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // Number Medium - Medium numbers (prices, values)
  static TextStyle get numberMedium => GoogleFonts.inter(
    fontSize: 16.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // Number Regular - Regular numbers (table data)
  static TextStyle get numberRegular => GoogleFonts.inter(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: 0,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // Number Small - Small numbers (captions, labels)
  static TextStyle get numberSmall => GoogleFonts.inter(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: 0,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // Number Profit - Positive values (green)
  static TextStyle get numberProfit => GoogleFonts.inter(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.green,
    letterSpacing: 0,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // Number Loss - Negative values (red)
  static TextStyle get numberLoss => GoogleFonts.inter(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.red,
    letterSpacing: 0,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // Price Large - Large price display
  static TextStyle get priceLarge => GoogleFonts.inter(
    fontSize: 32.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -1,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // Price Medium - Medium price
  static TextStyle get priceMedium => GoogleFonts.inter(
    fontSize: 20.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // Price Small - Small price
  static TextStyle get priceSmall => GoogleFonts.inter(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // Account Number - MT5 account numbers
  static TextStyle get accountNumber => GoogleFonts.inter(
    fontSize: 15.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // ==========================================================================
  // SPECIALTY STYLES
  // ==========================================================================

  // Scratch Card Yellow - Special gold text
  static TextStyle get scratchCardYellow => GoogleFonts.roboto(
    fontSize: 10.sp,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.normal,
    color: AppColors.primary,
    textBaseline: TextBaseline.alphabetic,
    letterSpacing: 0,
    height: 1.0,
  );

  // Badge Text - Account type badges
  static TextStyle get badge => GoogleFonts.plusJakartaSans(
    fontSize: 10.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.whiteColor,
    letterSpacing: 0.3,
  );

  // Menu Item - Menu list items
  static TextStyle get menuItem => GoogleFonts.plusJakartaSans(
    fontSize: 16.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
  );

  // Bottom Nav Label - Bottom navigation labels
  static TextStyle get bottomNavLabel => GoogleFonts.plusJakartaSans(
    fontSize: 11.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0,
  );

  // Dialog Title - Dialog/popup titles (matches H2 style)
  static TextStyle get dialogTitle => GoogleFonts.plusJakartaSans(
    fontSize: 20.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  // Dialog Content - Dialog body text
  static TextStyle get dialogContent => GoogleFonts.plusJakartaSans(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
    letterSpacing: 0,
  );
}
