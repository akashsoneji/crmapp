import 'dart:async';

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

    // ── Honor `preserveBroker` arg ─────────────────────────────────────────
    // If the caller passed `preserveBroker: true` (e.g. Switch Account →
    // "Choose Broker") AND the user already has a profile on this broker,
    // re-tapping the same broker should NOT clear auth and re-route to login.
    // The caller is responsible for having cleared the active session before
    // navigating here, so the only thing we need to do is treat the existing
    // profile as "keep broker context, route home after login".
    final args = Get.arguments as Map<String, dynamic>?;
    final preserveBroker = args?['preserveBroker'] == true;

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

      // ── PROFILE & SESSION MANAGEMENT (IDENTITY-AWARE) ────────────────────
      // Canonical identity = profile_key = '<lowercased_email>|<broker_slug>'.
      // We resolve the broker tap in one of three ways:
      //   (A) Active session matches this broker's profile_key → keep session,
      //       just re-apply runtime config and route home.
      //   (B) Active session is logged in but a DIFFERENT user has a profile
      //       for this broker → keep current session, raise a one-time snackbar
      //       telling the user to use Switch Account. Never silently switch.
      //   (C) No active session OR no profile for this user on this broker
      //       → fresh login path.
      final activeSession = await SecureStorageService.getActiveSession();
      final activeEmail = activeSession.email;
      final isLoggedIn = activeSession.loggedIn;

      Map<String, dynamic>? ownProfileForBroker;
      if (activeEmail != null) {
        ownProfileForBroker = await SecureStorageService
            .findTenaxProfileByIdentity(
              email: activeEmail,
              brokerSlug: broker.slug,
            );
      }

      final profilesForThisBroker = await SecureStorageService
          .findTenaxProfilesByBrokerSlug(broker.slug);
      final hasOtherUsersOnThisBroker = profilesForThisBroker.any((p) {
        final key = (p['profile_key'] ?? '').toString();
        if (key.isEmpty) return false;
        final myKey =
            activeEmail == null ? '' : '${activeEmail.trim().toLowerCase()}|${broker.slug}';
        return key != myKey;
      });

      // Always save the broker selection + re-apply runtime config first, so
      // the branding is correct regardless of which branch we end up in.
      await SecureStorageService.saveTenaxBrokerSelection(payload);
      FlavorConfig.applyTenaxBrokerRuntimeConfig(
        config: decryptedConfig,
        brokerName: broker.displayName,
        brokerLogoUrl: localLogoPath ?? logoFromPayload,
        brokerData: payload,
      );
      Get.find<LanguageService>().brandingUpdateIndex.value++;

      if (isLoggedIn && ownProfileForBroker != null) {
        // (A) Same user, same broker — session is already active, just route home.
        print(
          'TenaxBrokerSelection: Active session matches profile_key='
          '${ownProfileForBroker['profile_key']} — keeping current session.',
        );
        await SecureStorageService.setTenaxCurrentProfileKey(
          (ownProfileForBroker['profile_key'] ?? '').toString(),
        );
        Get.offAllNamed(AppPages.SPLASH);
      } else if (isLoggedIn && hasOtherUsersOnThisBroker) {
        // (B) Different user already saved for this broker — keep current session,
        // let user switch explicitly via the Switch Account sheet.
        print(
          'TenaxBrokerSelection: Active session is ${activeEmail ?? '?'}, but another '
          'user has a profile on broker=${broker.slug}. Keeping current session.',
        );
        if (ownProfileForBroker != null) {
          await SecureStorageService.setTenaxCurrentProfileKey(
            (ownProfileForBroker['profile_key'] ?? '').toString(),
          );
        }
        Get.snackbar(
          'Another account is registered on ${broker.displayName}',
          'Open "Switch Account" in More to use it.',
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.offAllNamed(AppPages.SPLASH);
      } else {
        // (C) Fresh login path — either no active session, or active session
        // but no profile for this broker yet (legitimately new).
        print(
          'TenaxBrokerSelection: No matching profile for active session on '
          'broker=${broker.slug} — forcing fresh login.',
        );
        // When preserveBroker is true, the caller (Switch Account →
        // "Log in with another account") has already cleared the active
        // session and we just need to route to login WITHOUT also clearing
        // the broker selection / saved profiles. The (C) branch only
        // clears auth data; broker selection + profiles are untouched.
        await SecureStorageService.clearAuthData();
        await SecureStorageService.saveLoginStatus(false);
        final nextRoute = preserveBroker
            ? AppPages.LOGIN
            : (FlavorConfig.isTenaxBrokerDemoEnabled
                  ? AppPages.LOGIN
                  : AppPages.GET_STARTED);
        Get.offAllNamed(
          nextRoute,
          arguments: preserveBroker
              ? {'preserveBroker': true, 'forceAuth': true}
              : null,
        );
      }
    } finally {
      isSaving.value = false;
    }
  }
}
