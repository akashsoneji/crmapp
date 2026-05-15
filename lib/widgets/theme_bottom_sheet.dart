import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/services/theme_service.dart';
import 'package:crm_app/services/language_service.dart';

/// Shows the theme selection bottom sheet.
/// Call this from any screen context.
void showThemeBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.95, end: 1),
      builder: (context, value, child) => Transform.scale(scale: value, child: child),
      child: const _ThemeBottomSheet(),
    ),
  );
}

class _ThemeBottomSheet extends StatelessWidget {
  const _ThemeBottomSheet();

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();
    final themeService = Get.find<ThemeService>();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
      padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 18.h),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  languageService.tr('settings_theme_title'),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE1E1E1),
                  ),
                  child: Icon(Icons.close, size: 18.sp, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            languageService.tr('settings_theme_description'),
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w400,
            ),
          ),
          Divider(height: 20.h, color: AppColors.border),
          Obx(() => Column(
            children: [
              _ThemeOption(
                icon: Icons.brightness_auto_rounded,
                label: languageService.tr('settings_theme_system'),
                isSelected: themeService.currentMode.value == ThemeServiceMode.system,
                onTap: () {
                  themeService.selectTheme(ThemeServiceMode.system);
                  Navigator.pop(context);
                },
              ),
              _ThemeOption(
                icon: Icons.light_mode_rounded,
                label: languageService.tr('settings_theme_light'),
                isSelected: themeService.currentMode.value == ThemeServiceMode.light,
                onTap: () {
                  themeService.selectTheme(ThemeServiceMode.light);
                  Navigator.pop(context);
                },
              ),
              _ThemeOption(
                icon: Icons.dark_mode_rounded,
                label: languageService.tr('settings_theme_dark'),
                isSelected: themeService.currentMode.value == ThemeServiceMode.dark,
                onTap: () {
                  themeService.selectTheme(ThemeServiceMode.dark);
                  Navigator.pop(context);
                },
              ),
            ],
          )),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 20.sp,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textGrey,
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                size: 22.sp,
                color: AppColors.primary,
              )
            else
              Icon(
                Icons.circle_outlined,
                size: 22.sp,
                color: AppColors.textGrey.withValues(alpha: 0.4),
              ),
          ],
        ),
      ),
    );
  }
}