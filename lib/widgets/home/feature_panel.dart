import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/widgets/home/quick_actions_grid.dart';

class _Feature {
  final HomeShortcut shortcut;
  final String iconAsset;
  final String titleKey;
  final String fallbackTitle;
  final String subtitleKey;
  final String fallbackSubtitle;

  const _Feature(
    this.shortcut,
    this.iconAsset,
    this.titleKey,
    this.fallbackTitle,
    this.subtitleKey,
    this.fallbackSubtitle,
  );
}

/// Rounded 2-column panel: Promotional, Finance, Savings, Live Stream. Only
/// the features [isVisible] accepts are laid out; the panel disappears when
/// none are.
class FeaturePanel extends StatelessWidget {
  final ValueChanged<HomeShortcut> onShortcutTap;
  final bool Function(HomeShortcut shortcut) isVisible;

  const FeaturePanel({
    super.key,
    required this.onShortcutTap,
    required this.isVisible,
  });

  static const String _iconDir = 'assets/svg/new_svg';

  static const List<_Feature> _features = [
    _Feature(
      HomeShortcut.promotional,
      '$_iconDir/feature_rewards.svg',
      'general_promotional',
      'Promotional',
      'home_promotional_subtitle',
      'Offers and bonuses for you',
    ),
    _Feature(
      HomeShortcut.finance,
      '$_iconDir/feature_referral.svg',
      'general_finance',
      'Finance',
      'home_finance_subtitle',
      'Deposits, withdrawals and more',
    ),
    _Feature(
      HomeShortcut.savings,
      '$_iconDir/feature_savings.svg',
      'home_savings',
      'Savings',
      'home_savings_subtitle',
      '',
    ),
    _Feature(
      HomeShortcut.liveStream,
      '$_iconDir/feature_live_stream.svg',
      'home_live_stream',
      'Live Stream',
      'home_live_stream_subtitle',
      '',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = _features.where((f) => isVisible(f.shortcut)).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    final divider = AppColors.homeIconTint.withValues(alpha: 0.25);

    Widget tile(_Feature f) => Expanded(
      child: _FeatureTile(feature: f, onTap: () => onShortcutTap(f.shortcut)),
    );

    Widget row(_Feature start, _Feature? end) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tile(start),
          VerticalDivider(width: 1, thickness: 1, color: divider),
          if (end != null) tile(end) else const Expanded(child: SizedBox()),
        ],
      ),
    );

    final rows = <Widget>[];
    for (var i = 0; i < visible.length; i += 2) {
      if (i > 0) rows.add(Divider(height: 1, thickness: 1, color: divider));
      rows.add(row(visible[i], i + 1 < visible.length ? visible[i + 1] : null));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: ColoredBox(
        color: AppColors.homeFeaturePanelBackground,
        child: Column(mainAxisSize: MainAxisSize.min, children: rows),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final _Feature feature;
  final VoidCallback onTap;

  const _FeatureTile({required this.feature, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();
    final title = languageService.trf(feature.titleKey, feature.fallbackTitle);
    final subtitle = languageService.trf(
      feature.subtitleKey,
      feature.fallbackSubtitle,
    );

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(14.w, 12.h, 10.w, 12.h),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.heading.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: AppTextStyles.subheading.copyWith(
                        fontSize: 11.sp,
                        color: AppColors.textGrey,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6.w),
              SvgPicture.asset(
                feature.iconAsset,
                width: 30.r,
                height: 30.r,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
