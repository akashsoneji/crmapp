import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/api_const.dart';
import 'package:crm_app/flavor_config.dart';
import 'package:crm_app/models/tenax_broker_model.dart';
import 'package:crm_app/services/api_service.dart';
import 'package:crm_app/services/secure_storage_service.dart';
import 'package:crm_app/services/tenax_broker_service.dart';

class TenaxBrokerSelectionController extends GetxController {
  final TenaxBrokerService _brokerService = TenaxBrokerService();
  final TextEditingController searchController = TextEditingController();

  final RxList<TenaxBrokerModel> brokers = <TenaxBrokerModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;

  Timer? _searchDebounce;

  @override
  void onInit() {
    super.onInit();
    fetchBrokers();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.onClose();
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), fetchBrokers);
  }

  Future<void> fetchBrokers() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final data = await _brokerService.fetchBrokers(search: searchQuery.value);
      brokers.assignAll(data);
    } catch (e) {
      errorMessage.value = e.toString();
      brokers.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectBroker(TenaxBrokerModel broker) async {
    if (isSaving.value) {
      return;
    }

    isSaving.value = true;
    try {
      final decryptedConfig = await _brokerService.fetchBrokerConfigBySlug(
        broker.slug,
      );

      final logoFromPayload =
          (decryptedConfig['logo_url'] ??
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

      await SecureStorageService.saveTenaxBrokerSelection(payload);
      FlavorConfig.applyTenaxBrokerRuntimeConfig(
        config: decryptedConfig,
        brokerName: broker.displayName,
        brokerLogoUrl: localLogoPath ?? logoFromPayload,
        brokerData: payload,
      );
      ApiConstants.baseUrl = FlavorConfig.instance.apiBaseUrl;
      ApiConstants.socketUrl = FlavorConfig.instance.websocketUrl;
      ApiService.syncBaseUrlWithFlavor();
      Get.forceAppUpdate();
    } finally {
      isSaving.value = false;
    }
  }
}
