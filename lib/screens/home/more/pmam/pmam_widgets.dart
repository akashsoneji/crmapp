import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ─── PMAM Color System ─────────────────────────────────────────────────────

class PmamColors {
  PmamColors._();

  static const Color primaryPurple = Color(0xFF5B2C6F);
  static const Color primaryPurpleLight = Color(0xFFE8DAEF);
  static const Color primaryPurpleMid = Color(0xFF9B59B6);

  static const Color approvedGreen = Color(0xFFD5F5E3);
  static const Color approvedGreenText = Color(0xFF1E8449);
  static const Color rejectedRed = Color(0xFFFFE5E5);
  static const Color rejectedRedText = Color(0xFFCC0000);
  static const Color pendingAmber = Color(0xFFFFF3CD);
  static const Color pendingAmberText = Color(0xFF92400E);
  static const Color inactiveGrey = Color(0xFFEDF1F3);
  static const Color inactiveGreyText = Color(0xFF757575);

  static const Color scaffoldBg = Color(0xFFF5F5F5);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color borderLight = Color(0xFFE8E8E8);

  static Color statusBg(String status) {
    switch (status) {
      case 'approved':
        return approvedGreen;
      case 'rejected':
        return rejectedRed;
      case 'pending':
      case 'pending_admin':
        return pendingAmber;
      case 'inactive':
        return inactiveGrey;
      default:
        return inactiveGrey;
    }
  }

  static Color statusText(String status) {
    switch (status) {
      case 'approved':
        return approvedGreenText;
      case 'rejected':
        return rejectedRedText;
      case 'pending':
      case 'pending_admin':
        return pendingAmberText;
      case 'inactive':
        return inactiveGreyText;
      default:
        return inactiveGreyText;
    }
  }
}

/// ─── Reusable Card ───────────────────────────────────────────────────────────

class PmamCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;

  const PmamCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(
      padding: padding ?? EdgeInsets.all(16.w),
      child: child,
    );

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? PmamColors.cardWhite,
        borderRadius: BorderRadius.circular(14.r),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1)
            : Border.all(color: PmamColors.borderLight, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14.r),
                onTap: onTap,
                child: content,
              ),
            )
          : content,
    );
  }
}

/// ─── Status Badge ────────────────────────────────────────────────────────────

class PmamStatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const PmamStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  String get _label {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'pending':
      case 'pending_admin':
        return 'Pending';
      case 'inactive':
        return 'Inactive';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8.w : 10.w,
        vertical: compact ? 3.h : 4.h,
      ),
      decoration: BoxDecoration(
        color: PmamColors.statusBg(status),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: compact ? 10.sp : 11.sp,
          fontWeight: FontWeight.w600,
          color: PmamColors.statusText(status),
        ),
      ),
    );
  }
}

/// ─── Stat Card (for dashboard) ──────────────────────────────────────────────

class PmamStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? valueColor;
  final Color? iconBgColor;
  final Color? iconColor;
  final bool highlight;

  const PmamStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.valueColor,
    this.iconBgColor,
    this.iconColor,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? PmamColors.primaryPurple;
    final effectiveIconBg = iconBgColor ?? PmamColors.primaryPurpleLight;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: PmamColors.cardWhite,
        borderRadius: BorderRadius.circular(12.r),
        border: highlight
            ? Border.all(color: (valueColor ?? PmamColors.primaryPurple).withOpacity(0.4), width: 1.5)
            : Border.all(color: PmamColors.borderLight, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: effectiveIconBg,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: effectiveIconColor, size: 18.sp),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: valueColor ?? PmamColors.textPrimary,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: PmamColors.textSecondary,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// ─── Manager Avatar ───────────────────────────────────────────────────────────

class PmamAvatar extends StatelessWidget {
  final String name;
  final double size;
  final double fontSize;

  const PmamAvatar({
    super.key,
    required this.name,
    this.size = 52,
    this.fontSize = 18,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.w,
      height: size.w,
      decoration: const BoxDecoration(
        color: PmamColors.primaryPurpleLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            fontSize: fontSize.sp,
            fontWeight: FontWeight.w700,
            color: PmamColors.primaryPurple,
          ),
        ),
      ),
    );
  }
}

/// ─── Empty State ─────────────────────────────────────────────────────────────

class PmamEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PmamEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.w,
              height: 72.w,
              decoration: BoxDecoration(
                color: PmamColors.primaryPurpleLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32.sp,
                color: PmamColors.primaryPurple.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              message,
              style: TextStyle(
                fontSize: 14.sp,
                color: PmamColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 16.h),
              GestureDetector(
                onTap: onAction,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: PmamColors.primaryPurple,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    actionLabel!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ─── Section Header ──────────────────────────────────────────────────────────

class PmamSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  const PmamSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: PmamColors.textPrimary,
          ),
        ),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Row(
              children: [
                if (actionIcon != null) ...[
                  Icon(actionIcon, size: 14.sp, color: PmamColors.primaryPurple),
                  SizedBox(width: 4.w),
                ],
                Text(
                  actionLabel!,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: PmamColors.primaryPurple,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// ─── Filter Chip ─────────────────────────────────────────────────────────────

class PmamFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const PmamFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: selected ? PmamColors.primaryPurple : PmamColors.cardWhite,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected
                ? PmamColors.primaryPurple
                : PmamColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : PmamColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// ─── Primary Button ──────────────────────────────────────────────────────────

class PmamPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final double? width;

  const PmamPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 48.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: PmamColors.primaryPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// ─── Info Row ────────────────────────────────────────────────────────────────

class PmamInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final FontWeight? valueWeight;

  const PmamInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            color: PmamColors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: valueWeight ?? FontWeight.w600,
              color: valueColor ?? PmamColors.textPrimary,
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}