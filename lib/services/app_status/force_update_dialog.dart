import 'dart:io';
import 'package:crm_app/flavor_config.dart';
import 'package:crm_app/widgets/brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/services/app_status/app_status_controller.dart';
import 'package:crm_app/services/app_status/in_app_update_service.dart';
import 'package:crm_app/services/language_service.dart';

enum UpdateDialogState { idle, downloading, installing, openingStore, error }

class ForceUpdateDialog extends StatefulWidget {
  final bool isForceUpdate;

  const ForceUpdateDialog({super.key, required this.isForceUpdate});

  @override
  State<ForceUpdateDialog> createState() => _ForceUpdateDialogState();
}

class _ForceUpdateDialogState extends State<ForceUpdateDialog> {
  UpdateDialogState _state = UpdateDialogState.idle;
  double? _downloadProgress;
  String? _downloadError;
  String? _downloadedSizeLabel;

  Future<void> _handleUpdateTap() async {
    final controller = Get.find<AppStatusController>();
    final languageService = Get.find<LanguageService>();
    final updateUrl = controller.statusData.value?.updateUrlAndroid;

    if (updateUrl == null || updateUrl.isEmpty) {
      setState(() {
        _state = UpdateDialogState.error;
        _downloadError = languageService.tr('app_status_update_no_url');
      });
      return;
    }

    final isPlayStoreUrl =
        updateUrl.contains('play.google.com') ||
        updateUrl.contains('market.android.com') ||
        updateUrl.toLowerCase().endsWith('.aab');

    if (isPlayStoreUrl) {
      setState(() => _state = UpdateDialogState.openingStore);
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      controller.openAppStore();
      setState(() => _state = UpdateDialogState.idle);
      return;
    }

    setState(() {
      _state = UpdateDialogState.downloading;
      _downloadProgress = 0.0;
      _downloadError = null;
      _downloadedSizeLabel = languageService.tr(
        'app_status_update_starting_download',
      );
    });

    final result = await InAppUpdateService.instance.downloadAndInstall(
      updateUrl,
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
            final percent = (progress * 100).toStringAsFixed(0);
            _downloadedSizeLabel = languageService.tr(
              'app_status_update_percent_complete',
              {'percent': percent},
            );
          });
        }
      },
    );

    if (!mounted) return;

    switch (result) {
      case DownloadResult.downloading:
        setState(() {
          _state = UpdateDialogState.installing;
          _downloadProgress = 1.0;
          _downloadedSizeLabel = languageService.tr(
            'app_status_update_ready_to_install',
          );
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _state = UpdateDialogState.idle);
        break;
      case DownloadResult.playStore:
        setState(() => _state = UpdateDialogState.openingStore);
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        controller.openAppStore();
        setState(() => _state = UpdateDialogState.idle);
        break;
      case DownloadResult.aabPlayStore:
        setState(() => _state = UpdateDialogState.openingStore);
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        controller.openAppStore();
        setState(() => _state = UpdateDialogState.idle);
        break;
      case DownloadResult.error:
        setState(() {
          _state = UpdateDialogState.error;
          _downloadError = languageService.tr(
            'app_status_update_download_failed',
          );
        });
        break;
    }
  }

  void _retry() {
    setState(() {
      _state = UpdateDialogState.idle;
      _downloadError = null;
      _downloadProgress = null;
    });
  }

  Color get _accentColor {
    switch (_state) {
      case UpdateDialogState.downloading:
        return AppColors.primary;
      case UpdateDialogState.installing:
        return AppColors.success;
      case UpdateDialogState.openingStore:
        return AppColors.primary;
      case UpdateDialogState.error:
        return AppColors.error;
      case UpdateDialogState.idle:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppStatusController>();
    final languageService = Get.find<LanguageService>();
    final releaseNotes = controller.statusData.value?.releaseNotes;
    final hasApkUrl =
        Platform.isAndroid &&
        controller.statusData.value?.updateUrlAndroid?.isNotEmpty == true;

    final bool isDark = AppColors.isDarkMode;
    final Color cardColor = AppColors.whiteColor;
    final Color titleColor = AppColors.textPrimary;
    final Color subtitleColor = AppColors.textSecondary;
    final Color cardBorder = AppColors.border;
    final Color cardSurface = AppColors.surface;
    final Color shadowColor = Colors.black.withValues(alpha: 0.5);

    return PopScope(
      canPop: !widget.isForceUpdate,
      child: Material(
        child: Container(
          color: isDark
              ? Colors.black.withValues(alpha: 0.7)
              : Colors.black.withValues(alpha: 0.45),
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Main card
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(28.r),
                      border: Border.all(color: cardBorder, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                        BoxShadow(
                          color: shadowColor.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: _accentColor.withValues(
                            alpha: isDark ? 0.1 : 0.15,
                          ),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(28.w, 32.w, 28.w, 28.w),
                          child: Column(
                            children: [
                              // Icon
                              _buildIcon(isDark),
                              SizedBox(height: 20.h),

                              // Title
                              Text(
                                _getTitle(),
                                style: AppTextStyles.heading.copyWith(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w800,
                                  color: titleColor,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              SizedBox(height: 8.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    size: 12.w,
                                    color: AppColors.textGrey,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    languageService.tr(
                                      'app_status_update_do_not_close',
                                    ),
                                    style: AppTextStyles.bodyText.copyWith(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w400,
                                      color: subtitleColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              // Text(
                              //   'New version $latestVersion available',
                              //   style: AppTextStyles.bodyText.copyWith(
                              //     fontSize: 14.sp,
                              //     fontWeight: FontWeight.w400,
                              //     color: subtitleColor,
                              //   ),
                              //   textAlign: TextAlign.center,
                              // ),

                              // Release notes
                              if (releaseNotes != null &&
                                  releaseNotes.isNotEmpty) ...[
                                SizedBox(height: 20.h),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(14.w),
                                  decoration: BoxDecoration(
                                    color: cardSurface,
                                    borderRadius: BorderRadius.circular(14.r),
                                    border: Border.all(
                                      color: cardBorder,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.new_releases_outlined,
                                            size: 14.w,
                                            color: _accentColor,
                                          ),
                                          SizedBox(width: 6.w),
                                          Text(
                                            languageService.tr(
                                              'app_status_update_whats_new',
                                            ),
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.w600,
                                              color: subtitleColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        releaseNotes,
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: titleColor.withValues(
                                            alpha: 0.8,
                                          ),
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              SizedBox(height: 28.h),

                              // Buttons
                              _buildActions(hasApkUrl, isDark),
                              if (!widget.isForceUpdate &&
                                  _state == UpdateDialogState.idle) ...[
                                SizedBox(height: 16.h),
                                GestureDetector(
                                  onTap: () {
                                    controller.skipUpdateFor24Hours();
                                    Get.back(closeOverlays: true);
                                    controller.resetForceUpdateDialogFlag();
                                  },
                                  child: Text(
                                    languageService.tr(
                                      'app_status_update_remind_later',
                                    ),
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: subtitleColor.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
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

  String _getTitle() {
    final controller = Get.find<AppStatusController>();
    final latestVersion =
        controller.statusData.value?.appVersion ??
        controller.latestVersion.value;
    switch (_state) {
      case UpdateDialogState.downloading:
        return 'Downloading Update';
      case UpdateDialogState.installing:
        return 'Ready to Install';
      case UpdateDialogState.openingStore:
        return 'Opening App Store';
      case UpdateDialogState.error:
        return 'Download Failed';
      case UpdateDialogState.idle:
        return '${latestVersion} Update Available';
    }
  }

  String _getSubtitle(String latestVersion) {
    switch (_state) {
      case UpdateDialogState.downloading:
        return _downloadedSizeLabel ?? 'Please wait...';
      case UpdateDialogState.installing:
        return 'Tap "Install" in the system prompt to continue';
      case UpdateDialogState.openingStore:
        return 'Taking you to the app store...';
      case UpdateDialogState.error:
        return _downloadError ?? 'Something went wrong.';
      case UpdateDialogState.idle:
        return 'Version $latestVersion is ready. Update now for the best experience.';
    }
  }

  Widget _buildIcon(bool isDark) {
    final bool isDownloading = _state == UpdateDialogState.downloading;

    return SizedBox(
      width: 120.w,
      height: 120.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress ring background
          SizedBox(
            width: 120.w,
            height: 120.w,
            child: CircularProgressIndicator(
              value: isDownloading ? (_downloadProgress ?? 0) : 0,
              strokeWidth: 4.w,
              backgroundColor: _accentColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                _accentColor.withValues(alpha: isDownloading ? 0.6 : 0.15),
              ),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Brand logo container
          Container(
            width: 90.w,
            height: 90.w,
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: isDark ? 0.15 : 0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withValues(alpha: isDark ? 0.15 : 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: BrandLogo(
                source: FlavorConfig.effectiveLogo,
                color: FlavorConfig.isONSA() && !FlavorConfig.hasRemoteLogo
                    ? AppColors.primary
                    : null,
                height: 70.w,
                width: 85.w,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateContent(bool isDark) {
    switch (_state) {
      case UpdateDialogState.downloading:
        return _buildDownloadingContent(isDark);
      case UpdateDialogState.installing:
        return _buildInstallingContent(isDark);
      case UpdateDialogState.openingStore:
        return _buildOpeningStoreContent(isDark);
      case UpdateDialogState.error:
      case UpdateDialogState.idle:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDownloadingContent(bool isDark) {
    final int percent = ((_downloadProgress ?? 0) * 100).toInt();

    return Column(
      children: [
        // Circular progress with percentage
        SizedBox(
          width: 60.w,
          height: 60.w,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60.w,
                height: 60.w,
                child: CircularProgressIndicator(
                  value: _downloadProgress ?? 0,
                  strokeWidth: 4.w,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: _accentColor,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 12.w,
              color: AppColors.textGrey,
            ),
            SizedBox(width: 4.w),
            Text(
              'Do not close the app',
              style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInstallingContent(bool isDark) {
    final Color bgColor = isDark
        ? AppColors.successBg
        : const Color(0xFFECFDF5);
    final Color borderColor = isDark
        ? AppColors.success.withValues(alpha: 0.3)
        : const Color(0xFFBBF7D0);
    final Color textColor = AppColors.successText;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.android_rounded, size: 20.w, color: _accentColor),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tap Install when prompted',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Allow "Unknown apps" if asked by your device',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: textColor.withValues(alpha: 0.85),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpeningStoreContent(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 20.w,
          height: 20.w,
          child: CircularProgressIndicator(
            strokeWidth: 2.5.w,
            valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
          ),
        ),
        SizedBox(width: 10.w),
        Text(
          'Redirecting to app store...',
          style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildActions(bool hasApkUrl, bool isDark) {
    switch (_state) {
      case UpdateDialogState.downloading:
        return _buildDownloadingActions(hasApkUrl, isDark);
      case UpdateDialogState.installing:
        return _buildInstallingActions(isDark);
      case UpdateDialogState.openingStore:
        return _buildOpeningStoreActions(isDark);
      case UpdateDialogState.error:
        return _buildErrorActions(isDark);
      case UpdateDialogState.idle:
        return _buildIdleActions(hasApkUrl, isDark);
    }
  }

  Widget _buildIdleActions(bool hasApkUrl, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleUpdateTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          padding: EdgeInsets.symmetric(vertical: 4.h),
          elevation: 2,
          shadowColor: _accentColor.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasApkUrl ? Icons.download_rounded : Icons.open_in_new_rounded,
              size: 20.w,
              color: AppColors.onColoredBackground,
            ),
            SizedBox(width: 10.w),
            Text(
              hasApkUrl ? 'Download & Install' : 'Update Now',
              style: TextStyle(
                color: AppColors.whiteColor,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadingActions(bool hasApkUrl, bool isDark) {
    final int percent = ((_downloadProgress ?? 0) * 100).toInt();
    final controller = Get.find<AppStatusController>();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18.w,
                height: 18.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5.w,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Downloading... $percent%',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (!widget.isForceUpdate) ...[
          SizedBox(height: 16.h),
          GestureDetector(
            onTap: () {
              controller.skipUpdateFor24Hours();
              Get.back(closeOverlays: true);
              controller.resetForceUpdateDialogFlag();
            },
            child: Text(
              'Remind me later',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInstallingActions(bool isDark) {
    final Color bgColor = isDark
        ? AppColors.successBg
        : const Color(0xFFECFDF5);
    final Color borderColor = isDark
        ? AppColors.success.withValues(alpha: 0.3)
        : const Color(0xFFBBF7D0);
    final Color textColor = AppColors.successText;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, size: 20.w, color: _accentColor),
              SizedBox(width: 10.w),
              Text(
                'Download complete!',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'System installer should have opened automatically',
          style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOpeningStoreActions(bool isDark) {
    final Color btnBg = isDark
        ? _accentColor.withValues(alpha: 0.15)
        : _accentColor.withValues(alpha: 0.08);
    final Color btnBorder = isDark
        ? _accentColor.withValues(alpha: 0.3)
        : _accentColor.withValues(alpha: 0.2);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: btnBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: btnBorder, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20.w,
            height: 20.w,
            child: CircularProgressIndicator(
              strokeWidth: 2.5.w,
              valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            'Opening app store...',
            style: TextStyle(
              color: _accentColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorActions(bool isDark) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _retry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  size: 20.w,
                  color: AppColors.onColoredBackground,
                ),
                SizedBox(width: 10.w),
                Text(
                  'Try Again',
                  style: TextStyle(
                    color: AppColors.onColoredBackground,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),
        GestureDetector(
          onTap: () {
            Get.back(closeOverlays: true);
            Get.find<AppStatusController>().resetForceUpdateDialogFlag();
          },
          child: Text(
            'Skip this version',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
