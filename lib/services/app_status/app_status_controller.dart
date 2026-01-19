import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crm_app/services/app_status/app_status_model.dart';
import 'package:crm_app/services/app_status/app_status_service.dart';
import 'package:crm_app/services/app_version_service.dart';
import 'package:crm_app/utils/app_logger.dart';
import 'package:crm_app/services/app_status/force_update_dialog.dart' as force_update;
import 'package:crm_app/services/app_status/maintenance_screen.dart';

/// Controller for managing app status (version check and maintenance mode)
class AppStatusController extends GetxController {
  final AppStatusService _service = Get.find<AppStatusService>();

  // Observable states
  final RxBool isUpdateRequired = false.obs;
  final RxBool isMaintenanceMode = false.obs;
  final RxString latestVersion = ''.obs;
  final RxBool isChecking = false.obs;

  bool _forceUpdateDialogShown = false;
  bool _maintenanceScreenShown = false;

  @override
  void onInit() {
    super.onInit();
    AppLogger.debug('AppStatusController: Initialized');
  }

  /// Handle status update from service
  Future<void> handleStatusUpdate(AppStatusModel status) async {
    try {
      isChecking.value = true;
      latestVersion.value = status.appVersion;

      // Check maintenance mode first (takes priority)
      if (status.isUnderMaintenance) {
        isMaintenanceMode.value = true;
        if (!_maintenanceScreenShown) {
          showMaintenanceScreen();
        }
        // Don't hide force update dialog during maintenance - it should persist
        isUpdateRequired.value = true; // Keep update required flag true
      } else {
        // Maintenance mode is off - hide maintenance screen
        if (isMaintenanceMode.value) {
          AppLogger.debug('AppStatusController: Maintenance mode turned off, hiding maintenance screen');
          isMaintenanceMode.value = false;
          hideMaintenanceScreen();
        }

        // Check if update is required
        final updateRequired = await _service.isUpdateRequired(status.appVersion);
        isUpdateRequired.value = updateRequired;

        if (updateRequired) {
          // Always show dialog if update is required (even if already shown, ensure it's visible)
          if (!_forceUpdateDialogShown) {
            showForceUpdateDialog();
          } else {
            // Dialog already shown - verify it's still open, if not, show it again
            if (!(Get.isDialogOpen ?? false)) {
              _forceUpdateDialogShown = false; // Reset flag to allow showing again
              showForceUpdateDialog();
            }
          }
        } else {
          // Only hide dialog if versions actually match (user updated the app)
          // This means the installed version now matches the API version
          // But only hide if we're sure - don't hide on first check if dialog wasn't shown
          if (_forceUpdateDialogShown && (Get.isDialogOpen ?? false)) {
            hideForceUpdateDialog();
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'AppStatusController: Error handling status update',
        error: e,
        stackTrace: stackTrace,
      );
      // On error, don't hide the dialog - keep it shown if it was already shown
    } finally {
      isChecking.value = false;
    }
  }

  /// Show force update dialog
  void showForceUpdateDialog() {
    // If already shown and dialog is still open, don't show again
    if (_forceUpdateDialogShown && (Get.isDialogOpen ?? false)) {
      return;
    }

    _forceUpdateDialogShown = true;
    
    Get.dialog(
      WillPopScope(
        onWillPop: () async {
          // Allow closing via close button, but mark as not shown so it can be re-shown on next check
          _forceUpdateDialogShown = false;
          return true; // Allow closing
        },
        child: const force_update.ForceUpdateDialog(),
      ),
      barrierDismissible: false, // Still prevent closing by tapping outside
    );
    AppLogger.debug('AppStatusController: Force update dialog shown');
  }

  /// Hide force update dialog
  void hideForceUpdateDialog() {
    if (!_forceUpdateDialogShown) return;

    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
    _forceUpdateDialogShown = false;
    AppLogger.debug('AppStatusController: Force update dialog hidden');
  }

  /// Show maintenance screen
  void showMaintenanceScreen() {
    if (_maintenanceScreenShown) return;

    _maintenanceScreenShown = true;
    AppLogger.debug('AppStatusController: Maintenance screen shown');
  }

  /// Hide maintenance screen
  void hideMaintenanceScreen() {
    if (!_maintenanceScreenShown) return;

    _maintenanceScreenShown = false;
    AppLogger.debug('AppStatusController: Maintenance screen hidden');
  }

  /// Check status manually (for retry button)
  Future<void> checkStatus() async {
    await _service.checkAppStatus();
  }

  /// Open app store/play store
  Future<void> openAppStore() async {
    try {
      final packageName = await AppVersionService.instance.getPackageName();
      String url;

      if (Platform.isAndroid) {
        // Android Play Store
        url = 'https://play.google.com/store/apps/details?id=$packageName';
      } else if (Platform.isIOS) {
        // iOS App Store
        url = 'https://apps.apple.com/app/id$packageName';
        // Note: You might need to replace 'id' with actual App Store ID
        // Format: https://apps.apple.com/app/id{APP_STORE_ID}
      } else {
        AppLogger.error('AppStatusController: Unsupported platform for app store');
        return;
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        AppLogger.debug('AppStatusController: Opened app store: $url');
      } else {
        AppLogger.error('AppStatusController: Could not launch app store URL: $url');
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'AppStatusController: Error opening app store',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void onClose() {
    hideForceUpdateDialog();
    super.onClose();
  }
}
