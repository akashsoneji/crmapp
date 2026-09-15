import 'package:crm_app/constants/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

/// Theme-aware back arrow using [assets/svg/trade/arro_back.svg].
/// Color follows [AppColors.textPrimary] (black in light, white in dark).
class AppSvgBackIcon extends StatelessWidget {
  const AppSvgBackIcon({super.key, this.width, this.height, this.color});

  final double? width;
  final double? height;
  final Color? color;

  static const String assetPath = 'assets/svg/trade/arro_back.svg';

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppColors.textPrimary;
    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      matchTextDirection: true,
      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
    );
  }
}

/// Material back chevron — same theme color as [AppSvgBackIcon].
class AppMaterialBackIcon extends StatelessWidget {
  const AppMaterialBackIcon({
    super.key,
    this.ios = true,
    this.size,
    this.color,
  });

  final bool ios;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppColors.textPrimary;
    if (ios) {
      return Icon(Icons.arrow_back_ios, size: size, color: iconColor);
    }
    return Icon(Icons.arrow_back, size: size, color: iconColor);
  }
}

/// App bar leading: SVG back + [IconButton].
class AppSvgBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double? iconWidth;
  final double? iconHeight;

  const AppSvgBackButton({
    super.key,
    required this.onPressed,
    this.iconWidth,
    this.iconHeight,
  });

  /// Prefer [Navigator.pop] when possible, otherwise [Get.back].
  static void popRoute(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: AppSvgBackIcon(width: iconWidth, height: iconHeight),
    );
  }
}
