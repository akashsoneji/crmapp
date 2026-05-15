import 'dart:async';
import 'dart:convert';

import 'package:crm_app/constants/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crm_app/flavor_config.dart';
import 'package:crm_app/models/tenax_broker_model.dart';
import 'package:crm_app/routes/app_pages.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/services/secure_storage_service.dart';
import 'package:crm_app/services/tenax_broker_service.dart';

class TenaxBrokerSelectionController extends GetxController {
  static const String _demoSearchQuery = 'Demo';
  final TenaxBrokerService _brokerService = TenaxBrokerService();
  final TextEditingController searchController = TextEditingController();

  final RxList<TenaxBrokerModel> brokers = <TenaxBrokerModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString loadingInfoSlug = ''.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;

  Timer? _searchDebounce;

  bool get isDemoMode => FlavorConfig.isTenaxBrokerDemoEnabled;

  @override
  void onInit() {
    super.onInit();
    if (FlavorConfig.isTenaxBrokerDemoEnabled) {
      searchQuery.value = _demoSearchQuery;
      searchController.text = _demoSearchQuery;
      fetchBrokers();
    }
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.onClose();
  }

  void onSearchChanged(String value) {
    if (FlavorConfig.isTenaxBrokerDemoEnabled) {
      return;
    }
    searchQuery.value = value;
    _searchDebounce?.cancel();
    if (value.trim().length <= 2) {
      // Clear results immediately when search query is 2 characters or less
      brokers.clear();
      errorMessage.value = '';
      isLoading.value = false;
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 350), fetchBrokers);
  }

  Future<void> fetchBrokers() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final effectiveSearch =
          FlavorConfig.isTenaxBrokerDemoEnabled
              ? _demoSearchQuery
              : searchQuery.value;
      final data = await _brokerService.fetchBrokers(search: effectiveSearch);
      brokers.assignAll(data);
    } catch (e) {
      errorMessage.value = e.toString();
      brokers.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchBrokerInfo(TenaxBrokerModel broker) async {
    if (loadingInfoSlug.value.isNotEmpty) return;
    loadingInfoSlug.value = broker.slug;
    try {
      final decryptedConfig = await _brokerService.fetchBrokerConfigBySlug(
        broker.slug,
      );
      Get.toNamed(
        AppPages.TENAX_BROKER_INFO,
        arguments: {'broker': broker, 'config': decryptedConfig},
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Unable to load broker information. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withValues(alpha: 0.85),
        colorText: AppColors.whiteColor,
      );
    } finally {
      loadingInfoSlug.value = '';
    }
  }

  Future<void> selectBroker(TenaxBrokerModel broker) async {
    if (!FlavorConfig.isMultiBrokerEnabled) return;
    if (isSaving.value) {
      return;
    }

    isSaving.value = true;
    try {
      final decryptedConfig = await _brokerService.fetchBrokerConfigBySlug(
        broker.slug,
      );

      // Prefer app_icon_url from decrypted config (used as the app logo everywhere)
      final logoFromPayload =
          (decryptedConfig['app_icon_url'] ??
                  decryptedConfig['app_logo_url'] ??
                  decryptedConfig['logo_url'] ??
                  decryptedConfig['logoUrl'] ??
                  decryptedConfig['logo'] ??
                  broker.logoUrl)
              .toString();

      final localLogoPath = await _brokerService.downloadLogoToLocal(
        logoUrl: logoFromPayload,
        slug: broker.slug,
      );

      final payload = <String, dynamic>{
        'selected_slug': broker.slug,
        'selected_id': broker.id,
        'selected_name': broker.displayName,
        'selected_sub_title': broker.subTitle,
        'selected_logo_url': logoFromPayload,
        'selected_logo_local_path': localLogoPath,
        'broker_list_item': broker.raw,
        'broker_runtime_config': decryptedConfig,
      };

      // ── PROFILE & SESSION MANAGEMENT ──────────────────────────────────
      // Check if we have an existing profile for this broker to restore session
      final profiles = await SecureStorageService.getTenaxUserBrokerProfiles();
      final existingProfile = profiles.firstWhereOrNull((p) {
        final topLevelSlug =
            (p['broker_slug'] ?? p['selected_slug'] ?? p['slug'] ?? '')
                .toString();
        if (topLevelSlug == broker.slug) return true;

        final brokerData =
            p['broker_data'] is Map<String, dynamic>
                ? p['broker_data'] as Map<String, dynamic>
                : null;
        final nestedSlug =
            (brokerData?['selected_slug'] ??
                    brokerData?['slug'] ??
                    brokerData?['broker_list_item']?['slug'] ??
                    '')
                .toString();
        return nestedSlug == broker.slug;
      });
      if (existingProfile != null) {
        // Restore session for this broker
        final loginData = existingProfile['login_data'];
        if (loginData is Map<String, dynamic>) {
          final token = (loginData['token'] ?? '').toString();
          final wsToken = (loginData['websocket_token'] ?? '').toString();
          final userData = loginData['user'];
          if (token.isNotEmpty) {
            await SecureStorageService.saveAuthToken(token);
            await SecureStorageService.saveWebsocketToken(wsToken);
            if (userData is Map<String, dynamic>) {
              await SecureStorageService.saveUserData(
                jsonEncode({
                  'token': token,
                  'websocket_token': wsToken,
                  'user': userData,
                  'is_logged_in': true,
                }),
              );
            }
            await SecureStorageService.saveLoginStatus(true);
          }
        }
        await SecureStorageService.setTenaxCurrentProfileKey(
          (existingProfile['profile_key'] ?? '').toString(),
        );
      } else {
        // New broker: Clear current session to force fresh login for this broker
        await SecureStorageService.clearAuthData();
        await SecureStorageService.saveLoginStatus(false);
      }

      await SecureStorageService.saveTenaxBrokerSelection(payload);
      FlavorConfig.applyTenaxBrokerRuntimeConfig(
        config: decryptedConfig,
        brokerName: broker.displayName,
        brokerLogoUrl: localLogoPath ?? logoFromPayload,
        brokerData: payload,
      );

      // Trigger UI refresh
      Get.find<LanguageService>().brandingUpdateIndex.value++;

      if (existingProfile != null) {
        Get.offAllNamed(AppPages.SPLASH);
      } else {
        Get.offAllNamed(
          FlavorConfig.isTenaxBrokerDemoEnabled
              ? AppPages.LOGIN
              : AppPages.GET_STARTED,
        );
      }
    } finally {
      isSaving.value = false;
    }
  }
}
