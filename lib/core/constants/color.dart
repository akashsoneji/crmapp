import 'package:flutter/material.dart';
import '../config/flavor_config.dart';

class AppColors {
  // Brand Colors - Now using flavor configuration
  static Color get primary => FlavorConfig.instance.primaryColor;
  static Color get secondary => FlavorConfig.instance.secondaryColor;
  static Color get accent => FlavorConfig.instance.accentColor;

  // Legacy static colors (keeping for backward compatibility)
  static const Color secondaryStatic = Color(0xFFF6F6F6);
  static const Color accentStatic = Color(0xFFFFC93C);
  static const Color blue = Color(0xFF3478F6);

  // Text Colors
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Colors.grey;
  static const Color textGrey = Color.fromRGBO(117, 121, 132, 1);
  static const Color textGreyLight = Color(0xff919EAB);
  static const Color whiteColor = Color(0xFFF6F6F6);
  static const Color tradeTextCenterColor = Color(0xFF4F535D);
  // static const Color tradeBackgroundCenterColor = Color(0xFFD6D6D6);
  static const Color tradeBackgroundCenterColor = Color(0xFFf7f7f7);

  // Backgrounds
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF121212);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  // Quote Digit Color
  static const Color red = Color(0xFFD72E1F);
  static const Color green = Color(0xFF3C8836);
  static const Color grey = Color(0xFFEDF1F3);
  static const Color icongrey = Color(0xFF757984);
  static const Color icongreylight = Color(0xff919eab7a);
  // static const Color cardBackGround = Color(0xffFBF5FF);
  // static const Color cardBackGround =  primary.withOpacity(0.1);
  static Color cardBackGround = primary.withOpacity(0.1);
  static Color cardBackGroundSecondary = primary.withOpacity(0.3);
  // Others
  static const Color border = Color(0xFFBBBBBB);
  static const Color hint = Colors.grey;
}

