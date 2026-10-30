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

  // ── DEFERRED COMMIT ────────────────────────────────────────────────
  // When a broker tile is tapped while a user is already logged in (or from
  // the MoreScreen "Add another account" path), we do NOT immediately save
  // branding / clear auth. Instead, we stage the selection in these static
  // fields and route to LOGIN / GET_STARTED. Branding only gets applied once
  // login OR registration successfully completes (see AuthController).
  // Branding snapshot: before we apply the new broker's branding, we capture
  // the current FlavorConfig reference here so the Home button on the
  // LOGIN/GET_STARTED/CREATE_ACCOUNT screens can roll it back if the user
  // changes their mind and hits Home.
  static Map<String, dynamic>? pendingBrokerPayload;
  static TenaxBrokerModel? pendingBrokerModel;
  static FlavorConfig? pendingBrandingSnapshot;
  /// True when the caller wants the broker selection to be applied even
  /// without logging in (e.g. demo mode or a fresh-install tenant re-tap).
  static bool _forceCommitPendingBroker = false;

  static bool get hasPendingBroker =>
      pendingBrokerPayload != null && pendingBrokerModel != null;

  static void clearPendingBroker() {
    pendingBrokerPayload = null;
    pendingBrokerModel = null;
    // NOTE: do NOT clear pendingBrandingSnapshot here. The LOGIN/GET_STARTED
    // /CREATE_ACCOUNT screens hold their own per-screen snapshot of the
    // previous branding (captured in initState). Clearing this would erase
    // the snapshot the *previous* session captured. Each screen manages
    // its own snapshot lifecycle.
    _forceCommitPendingBroker = false;
  }

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

  Future<void> selectBroker(
    TenaxBrokerModel broker, {
    bool preserveBroker = false,
    // Callers that are not the broker selection route (e.g. invite deep
    // links) pass their own args instead of the current route's.
    Map<String, dynamic>? routeArguments,
  }) async {
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

      // ── BRANCH RESOLUTION ──────────────────────────────────────────
      // (A) Default path: route to login / register. The new broker is
      //     STAGED in memory (pendingBrokerPayload / pendingBrokerModel);
      //     branding only commits on successful login or registration.
      //     - Logged-out users: branding IS committed eagerly so the
      //       login screens look correct.
      //     - Logged-in users: branding is NOT committed so the active
      //       session's visuals stay stable until the new account logs in.
      // (C) preserveBroker == true: caller wants to keep the current
      //     broker's branding (e.g. "log in with another account" on
      //     this same broker). Commit branding immediately and clear auth.
      //
      // Branch B has been intentionally removed. There is no auto-login
      // path from broker selection any more — see the long-form comment
      // at the start of the file.
      final isLoggedIn = await SecureStorageService.isUserLoggedIn();

      // Branch C: preserveBroker path - same broker as current session,
      // user wants to log in with another account on this broker.
      if (preserveBroker) {
        await SecureStorageService.saveTenaxBrokerSelection(payload);
        FlavorConfig.applyTenaxBrokerRuntimeConfig(
          config: decryptedConfig,
          brokerName: broker.displayName,
          brokerLogoUrl: localLogoPath ?? logoFromPayload,
          brokerData: payload,
        );
        await SecureStorageService.clearAuthData();
        await SecureStorageService.saveLoginStatus(false);
        Get.find<LanguageService>().brandingUpdateIndex.value++;
        Get.offAllNamed(
          FlavorConfig.isTenaxBrokerDemoEnabled
              ? AppPages.LOGIN
              : AppPages.GET_STARTED,
        );
        return;
      }

      // Branch A: stage the broker AND apply branding immediately so the
      // LOGIN/REGISTER screens reflect what the user just picked. The
      // OLD branding is snapshotted into [pendingBrandingSnapshot] so the
      // Home button can roll it back if the user changes their mind.
      //
      // For Brand-new / logged-out users we additionally persist the
      // broker selection to secure storage (no active session to corrupt).
      // For logged-in users we DO NOT save to storage yet and DO NOT clear
      // the active session — that's the deferred-commit boundary.
      // [AuthController._commitPendingBrokerIfAny] will persist on
      // successful login/register.
      pendingBrokerPayload = payload;
      pendingBrokerModel = broker;
      pendingBrandingSnapshot = FlavorConfig.snapshotBranding();
      _forceCommitPendingBroker = FlavorConfig.isTenaxBrokerDemoEnabled;

      FlavorConfig.applyTenaxBrokerRuntimeConfig(
        config: decryptedConfig,
        brokerName: broker.displayName,
        brokerLogoUrl: localLogoPath ?? logoFromPayload,
        brokerData: payload,
      );
      try {
        if (Get.isRegistered<LanguageService>()) {
          Get.find<LanguageService>().brandingUpdateIndex.value++;
        }
      } catch (_) {}

      if (!isLoggedIn) {
        await SecureStorageService.saveTenaxBrokerSelection(payload);
      }

      // Forward any snapshot/route args from the calling screen (e.g.
      // MoreScreen → TENAX_BROKER_SELECTION → LOGIN/GET_STARTED chain)
      // so the destination screens can restore the previous session.
      final incomingArgs = routeArguments ?? Get.arguments;
      final Map<String, dynamic> forwarded = <String, dynamic>{
        'pendingBroker': true,
        'forceAuth': true,
        'cameFromLoggedInSession': isLoggedIn,
        'preserveBroker': false,
      };
      if (incomingArgs is Map) {
        for (final entry in incomingArgs.entries) {
          final key = entry.key.toString();
          if (key == 'allowBack' || key == 'nextRoute') continue;
          forwarded[key] = entry.value;
        }
      }

      Get.offAllNamed(
        FlavorConfig.isTenaxBrokerDemoEnabled
            ? AppPages.LOGIN
            : AppPages.GET_STARTED,
        arguments: forwarded,
      );
    } finally {
      isSaving.value = false;
    }
  }

  /// Whether the staged broker should be committed eagerly (e.g. demo mode).
  /// Called by AuthController after successful login/register.
  static bool get forceCommitPendingBroker => _forceCommitPendingBroker;
}
