import 'package:adaptive_platform_ui/adaptive_platform_ui.dart' as adaptive;
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/flavor_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum AdaptiveAppButtonVariant { primary, secondary, outline, text }

class AdaptiveAppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final Widget? leadingIcon;
  final AdaptiveAppButtonVariant variant;
  final bool fullWidth;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final TextStyle? textStyle;
  final Color? color;
  final Color? textColor;

  const AdaptiveAppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.leadingIcon,
    this.variant = AdaptiveAppButtonVariant.primary,
    this.fullWidth = true,
    this.height,
    this.padding,
    this.borderRadius,
    this.textStyle,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = enabled && !isLoading && onPressed != null;
    final effectiveHeight = height ?? 44.h;
    final effectiveColor = color ?? _backgroundColor(context);
    final effectiveTextColor = textColor ?? _foregroundColor(context);

    final child = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16.w,
            height: 16.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
            ),
          ),
          SizedBox(width: 8.w),
        ] else if (leadingIcon != null) ...[
          leadingIcon!,
          SizedBox(width: 8.w),
        ],
        Flexible(
          flex: fullWidth ? 0 : 1,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                textStyle ??
                TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: effectiveTextColor,
                ),
          ),
        ),
      ],
    );

    final button = adaptive.AdaptiveButton.child(
      onPressed: effectiveEnabled ? onPressed : null,
      enabled: effectiveEnabled,
      color: effectiveColor,
      style: _adaptiveStyle,
      size: adaptive.AdaptiveButtonSize.large,
      minSize: Size(fullWidth ? double.infinity : 0, effectiveHeight),
      padding:
          padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      borderRadius: borderRadius ?? BorderRadius.circular(12.r),
      child: child,
    );

    if (!fullWidth) return button;

    return SizedBox(width: double.infinity, height: effectiveHeight, child: button);
  }

  adaptive.AdaptiveButtonStyle get _adaptiveStyle {
    switch (variant) {
      case AdaptiveAppButtonVariant.primary:
        return adaptive.AdaptiveButtonStyle.filled;
      case AdaptiveAppButtonVariant.secondary:
        return adaptive.AdaptiveButtonStyle.tinted;
      case AdaptiveAppButtonVariant.outline:
        return adaptive.AdaptiveButtonStyle.bordered;
      case AdaptiveAppButtonVariant.text:
        return adaptive.AdaptiveButtonStyle.plain;
    }
  }

  Color _backgroundColor(BuildContext context) {
    switch (variant) {
      case AdaptiveAppButtonVariant.primary:
        return FlavorConfig.instance.primaryColor;
      case AdaptiveAppButtonVariant.secondary:
      case AdaptiveAppButtonVariant.outline:
      case AdaptiveAppButtonVariant.text:
        return FlavorConfig.instance.primaryColor;
    }
  }

  Color _foregroundColor(BuildContext context) {
    switch (variant) {
      case AdaptiveAppButtonVariant.primary:
        return AppColors.whiteColor;
      case AdaptiveAppButtonVariant.secondary:
      case AdaptiveAppButtonVariant.outline:
      case AdaptiveAppButtonVariant.text:
        return FlavorConfig.instance.primaryColor;
    }
  }
}
