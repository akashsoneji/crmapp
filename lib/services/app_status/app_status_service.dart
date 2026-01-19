import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/api_const.dart';
import 'package:crm_app/services/api_service.dart';
import 'package:crm_app/services/app_version_service.dart';
import 'package:crm_app/services/app_status/app_status_model.dart';
import 'package:crm_app/services/app_status/app_status_controller.dart';
import 'package:crm_app/utils/app_logger.dart';

/// Service to check app version and maintenance status
class AppStatusService extends GetxService {
  Timer? _periodicTimer;
  static const Duration _checkInterval = Duration(seconds: 10);

  // Mock data configuration
  static bool useMockData = true; // Set to false when API is ready
  static String mockFileName =
      'app_status_response.json'; // Modify this file to test different scenarios (change app_version or is_under_maintenance)

  /// Start periodic checking
  void startPeriodicCheck() {
    if (_periodicTimer != null && _periodicTimer!.isActive) {
      return; // Already running
    }

    // Wait a bit before first check to ensure app is fully initialized
    // This prevents showing popup immediately on app open
    Future.delayed(const Duration(seconds: 10), () {
      // Perform initial check after 10 seconds
      checkAppStatus();
    });

    // Then check every 10 seconds
    _periodicTimer = Timer.periodic(_checkInterval, (timer) {
      checkAppStatus();
    });

    AppLogger.debug(
      'AppStatusService: Started periodic checking (first check after 10 seconds, then every 10 seconds)',
    );
  }

  /// Stop periodic checking
  void stopPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    AppLogger.debug('AppStatusService: Stopped periodic checking');
  }

  /// Check app status (either from API or mock data)
  Future<AppStatusModel?> checkAppStatus() async {
    try {
      // Ensure AppVersionService is initialized before checking
      await AppVersionService.instance.initialize();

      AppStatusModel? status;

      if (useMockData) {
        // Load from mock JSON file
        status = await loadMockData(mockFileName);
        AppLogger.debug(
          'AppStatusService: Loaded mock data from $mockFileName',
        );
      } else {
        // Call real API
        final response = await ApiService.get(
          endpoint: ApiConstants.appVersionCheck,
        );

        if (response.success && response.data != null) {
          status = AppStatusModel.fromJson(
            response.data as Map<String, dynamic>,
          );
          AppLogger.debug('AppStatusService: Loaded status from API');
        } else {
          AppLogger.error(
            'AppStatusService: API call failed - ${response.message}',
          );
          // Don't return null on API failure - continue with previous state
          // This prevents hiding the dialog on temporary network errors
          return null;
        }
      }

      if (status != null) {
        // Compare versions and notify controller
        // Only process if we have valid status data
        if (Get.isRegistered<AppStatusController>()) {
          final controller = Get.find<AppStatusController>();
          await controller.handleStatusUpdate(status);
        }
      }

      return status;
    } catch (e, stackTrace) {
      AppLogger.error(
        'AppStatusService: Error checking app status',
        error: e,
        stackTrace: stackTrace,
      );
      // On error, don't return null - let the previous state persist
      // This ensures the dialog stays visible even if there's a temporary error
      return null;
    }
  }

  /// Load mock data from assets
  Future<AppStatusModel?> loadMockData(String fileName) async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/mock/$fileName',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      return AppStatusModel.fromJson(jsonData);
    } catch (e, stackTrace) {
      AppLogger.error(
        'AppStatusService: Error loading mock data from $fileName',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Compare installed version with API version
  /// Returns true if update is required (versions don't match)
  Future<bool> isUpdateRequired(String apiVersion) async {
    try {
      final installedVersion = await AppVersionService.instance.getVersion();
      return !_compareVersions(installedVersion, apiVersion);
    } catch (e) {
      AppLogger.error('AppStatusService: Error comparing versions', error: e);
      return false;
    }
  }

  /// Compare two version strings (semantic versioning)
  /// Returns true if versions are equal
  bool _compareVersions(String version1, String version2) {
    try {
      final v1Parts =
          version1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final v2Parts =
          version2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      // Pad with zeros if lengths differ
      while (v1Parts.length < v2Parts.length) v1Parts.add(0);
      while (v2Parts.length < v1Parts.length) v2Parts.add(0);

      for (int i = 0; i < v1Parts.length; i++) {
        if (v1Parts[i] != v2Parts[i]) {
          return false;
        }
      }
      return true;
    } catch (e) {
      AppLogger.error(
        'AppStatusService: Error in version comparison',
        error: e,
      );
      return false;
    }
  }

  @override
  void onClose() {
    stopPeriodicCheck();
    super.onClose();
  }
}
