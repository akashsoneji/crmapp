import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:crm_app/constants/color.dart';

/// One quick action shown inside [MoreProfileHero].
class MoreQuickAction {
  final String svgIcon;
  final String label;
  final VoidCallback onTap;

  const MoreQuickAction({
    required this.svgIcon,
    required this.label,
    required this.onTap,
  });
}

/// One tile of [MoreFeatureGrid]. [svgIcon] is a name under
/// `assets/svg/more/`; [materialIcon] is used instead when set.
class MoreFeatureItem {
  final String svgIcon;
  final IconData? materialIcon;
  final String label;
  final VoidCallback onTap;

  const MoreFeatureItem({
    required this.svgIcon,
    required this.label,
    required this.onTap,
    this.materialIcon,
  });
}

Widget _moreIcon({
  required String svgIcon,
  IconData? materialIcon,
  required Color color,
  required double size,
}) {
  if (materialIcon != null) {
    return Icon(materialIcon, size: size, color: color);
  }
  return SvgPicture.asset(
    'assets/svg/more/$svgIcon.svg',
    width: size,
    height: size,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
  );
}

/// Gradient identity card: avatar, name, email, broker, profile and
/// switch-account actions, with the wallet quick actions docked at the bottom.
class MoreProfileHero extends StatelessWidget {
  final String name;
  final String email;
  final String? brokerName;
  final String initials;
  final bool isFullyVerified;
  final int completion;
  final bool isProfileVerified;
  final VoidCallback onProfileTap;
  final VoidCallback? onSwitchAccount;
  final List<MoreQuickAction> quickActions;

  const MoreProfileHero({
    super.key,
    required this.name,
    required this.email,
    required this.initials,
    required this.isFullyVerified,
    required this.completion,
    required this.isProfileVerified,
    required this.onProfileTap,
    required this.quickActions,
    this.brokerName,
    this.onSwitchAccount,
  });

  @override
  Widget build(BuildContext context) {
    final onHero = AppColors.whiteColor;
    final hasBroker = (brokerName ?? '').isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.78),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 12.h, 8.w, 10.h),
            child: Row(
              children: [
                Container(
                  width: 44.r,
                  height: 44.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: onHero.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: onHero.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: onHero,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: onHero,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          _VerificationPill(
                            isFullyVerified: isFullyVerified,
                            completion: completion,
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: onHero.withValues(alpha: 0.82),
                          fontSize: 11.5.sp,
                        ),
                      ),
                      if (hasBroker) ...[
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(
                              Icons.business_rounded,
                              size: 12.sp,
                              color: onHero.withValues(alpha: 0.82),
                            ),
                            SizedBox(width: 4.w),
                            Flexible(
                              child: Text(
                                brokerName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: onHero.withValues(alpha: 0.82),
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                _HeroIconButton(
                  icon: isProfileVerified
                      ? Icons.remove_red_eye_outlined
                      : Icons.edit_outlined,
                  tooltip: isProfileVerified ? 'View profile' : 'Edit profile',
                  onTap: onProfileTap,
                ),
                if (onSwitchAccount != null)
                  _HeroIconButton(
                    icon: Icons.swap_horiz_rounded,
                    tooltip: 'Switch account',
                    onTap: onSwitchAccount!,
                  ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(8.w, 0, 8.w, 8.h),
            padding: EdgeInsets.symmetric(vertical: 6.h),
            decoration: BoxDecoration(
              color: onHero.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                for (final action in quickActions)
                  Expanded(child: _HeroQuickAction(action: action)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationPill extends StatelessWidget {
  final bool isFullyVerified;
  final int completion;

  const _VerificationPill({
    required this.isFullyVerified,
    required this.completion,
  });

  @override
  Widget build(BuildContext context) {
    final label = isFullyVerified ? 'Verified' : '$completion%';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: isFullyVerified
            ? AppColors.whiteColor
            : AppColors.whiteColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFullyVerified ? Icons.verified_rounded : Icons.shield_outlined,
            size: 11.sp,
            color: isFullyVerified ? AppColors.primary : AppColors.whiteColor,
          ),
          SizedBox(width: 3.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5.sp,
              fontWeight: FontWeight.w700,
              color: isFullyVerified ? AppColors.primary : AppColors.whiteColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeroIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
      icon: Container(
        width: 30.r,
        height: 30.r,
        decoration: BoxDecoration(
          color: AppColors.whiteColor.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16.sp, color: AppColors.whiteColor),
      ),
    );
  }
}

class _HeroQuickAction extends StatelessWidget {
  final MoreQuickAction action;

  const _HeroQuickAction({required this.action});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: action.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _moreIcon(
                  svgIcon: action.svgIcon,
                  color: AppColors.whiteColor,
                  size: 18.r,
                ),
                SizedBox(height: 4.h),
                Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.whiteColor,
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small uppercase label above a group.
class MoreSectionLabel extends StatelessWidget {
  final String title;

  const MoreSectionLabel({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 14.h, 4.w, 6.h),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
          color: AppColors.textGrey,
        ),
      ),
    );
  }
}

/// Three-column grid of compact feature tiles (Finance, IB, Copy trading…).
/// Rows size to their tallest tile so two-line labels and large text scales
/// never clip.
class MoreFeatureGrid extends StatelessWidget {
  final List<MoreFeatureItem> items;

  const MoreFeatureGrid({super.key, required this.items});

  static const int _columns = 3;

  @override
  Widget build(BuildContext context) {
    final rowCount = (items.length / _columns).ceil();
    return Column(
      children: [
        for (var row = 0; row < rowCount; row++) ...[
          if (row > 0) SizedBox(height: 8.h),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var col = 0; col < _columns; col++) ...[
                  if (col > 0) SizedBox(width: 8.w),
                  Expanded(
                    child: row * _columns + col < items.length
                        ? _FeatureTile(item: items[row * _columns + col])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final MoreFeatureItem item;

  const _FeatureTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: Material(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: AppColors.icongrey.withValues(alpha: 0.14),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32.r,
                    height: 32.r,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: _moreIcon(
                      svgIcon: item.svgIcon,
                      materialIcon: item.materialIcon,
                      color: AppColors.primary,
                      size: 17.r,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.sp,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// White rounded card that separates its rows with hairline dividers.
class MoreSettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const MoreSettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final divider = Divider(
      height: 1,
      indent: 48.w,
      endIndent: 12.w,
      color: AppColors.icongrey.withValues(alpha: 0.14),
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.icongrey.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) divider,
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Compact settings row: tinted square icon, label, chevron.
class MoreSettingsRow extends StatelessWidget {
  final String svgIcon;
  final IconData? materialIcon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const MoreSettingsRow({
    super.key,
    required this.svgIcon,
    required this.label,
    required this.onTap,
    this.materialIcon,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDestructive ? AppColors.error : AppColors.primary;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 46),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Row(
            children: [
              Container(
                width: 28.r,
                height: 28.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: _moreIcon(
                  svgIcon: svgIcon,
                  materialIcon: materialIcon,
                  color: accent,
                  size: 15.r,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: isDestructive ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18.sp,
                color: AppColors.icongrey.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width outlined logout button.
class MoreLogoutButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const MoreLogoutButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: _moreIcon(svgIcon: 'logout', color: AppColors.error, size: 16.r),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.error,
          ),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          backgroundColor: AppColors.error.withValues(alpha: 0.04),
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.35)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }
}
