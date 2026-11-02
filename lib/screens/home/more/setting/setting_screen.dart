import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../constants/color.dart';
import '../../../../constants/text_styles.dart';
import '../../../../routes/app_pages.dart';
import '../../../../services/enabled_modules_service.dart';
import '../../../../services/language_service.dart';
import '../../../../services/theme_service.dart';
import '../../../../widgets/app_back_button.dart';
import '../../../../widgets/theme_bottom_sheet.dart';
import '../platforms_screen.dart';

/// App Settings, opened from the More screen: language, theme, password,
/// sessions, login activity and platforms.
class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        title: Text(
          languageService.tr('more_app_settings'),
          style: AppTextStyles.heading,
        ),
        leading: const AppBackButton(),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: _CardGroup(
            children: [
              _MenuItem(
                icon: const _LanguageGlyph(),
                label: languageService.tr('more_language'),
                onTap: () => Get.toNamed(AppPages.LANGUAGE_SELECTOR),
              ),
              _MenuItem(
                icon: const _ThemeModeIcon(),
                label: languageService.tr('settings_theme'),
                onTap: () => showThemeBottomSheet(context),
              ),
              _MenuItem(
                icon: const _SvgIcon('assets/svg/more/change_password.svg'),
                label: languageService.tr('change_password'),
                onTap: () => Get.toNamed(AppPages.CHANGE_PASSWORD),
              ),
              _MenuItem(
                icon: Icon(
                  Icons.devices_rounded,
                  size: 17.sp,
                  color: AppColors.primary,
                ),
                label: languageService.tr('active_sessions_title'),
                onTap: () => Get.toNamed(AppPages.ACTIVE_SESSIONS),
              ),
              _MenuItem(
                icon: Icon(
                  Icons.history_rounded,
                  size: 17.sp,
                  color: AppColors.primary,
                ),
                label: languageService.tr('login_activity_title'),
                onTap: () => Get.toNamed(AppPages.LOGIN_ACTIVITY),
              ),
              // `enabled-modules.platform` off → admin hid the Platforms page.
              if (EnabledModulesService.flags.platform)
                _MenuItem(
                  icon: Icon(
                    Icons.download_for_offline_outlined,
                    size: 17.sp,
                    color: AppColors.primary,
                  ),
                  label: languageService.tr('platforms_title'),
                  onTap: () => Get.to(() => const PlatformsScreen()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardGroup extends StatelessWidget {
  final List<Widget> children;
  const _CardGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Divider(
                  height: 1,
                  color: AppColors.icongrey.withValues(alpha: 0.14),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// "a अ" glyph for the Language row, drawn as text so it follows the theme
/// colour without a separate asset.
class _LanguageGlyph extends StatelessWidget {
  const _LanguageGlyph();

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
      height: 1,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('a', style: style.copyWith(fontSize: 13.sp)),
        SizedBox(width: 1.w),
        Text('अ', style: style.copyWith(fontSize: 12.sp)),
      ],
    );
  }
}

/// Sun in light mode, moon in dark mode.
class _ThemeModeIcon extends StatelessWidget {
  const _ThemeModeIcon();

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ThemeService>()) {
      return Icon(Icons.contrast_rounded, size: 17.sp, color: AppColors.primary);
    }
    final themeService = Get.find<ThemeService>();
    return Obx(
      () => Icon(
        themeService.isDarkModeObs.value
            ? Icons.dark_mode_rounded
            : Icons.light_mode_rounded,
        size: 17.sp,
        color: AppColors.primary,
      ),
    );
  }
}

class _SvgIcon extends StatelessWidget {
  final String path;
  const _SvgIcon(this.path);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      path,
      height: 16.h,
      width: 16.w,
      colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
          child: Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.14),
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: Center(child: icon),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyText.copyWith(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14.sp,
                color: AppColors.icongrey.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
