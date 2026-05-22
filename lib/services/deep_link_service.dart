import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:crm_app/routes/app_pages.dart';
import 'package:crm_app/widgets/custom_toast.dart';
import 'package:crm_app/controllers/dashboard_controller.dart';

class DeepLinkService extends GetxService {
  static const _channel = MethodChannel('com.crmapp/deeplink');

  @override
  void onInit() {
    super.onInit();
    _channel.setMethodCallHandler(_handleMethodCall);
    _checkInitialLink();
  }

  Future<void> _checkInitialLink() async {
    try {
      final initialUrl = await _channel.invokeMethod<String>('getInitialUrl');
      if (initialUrl != null) {
        _handleDeepLink(initialUrl);
      }
    } catch (_) {}
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onDeepLink') {
      final url = call.arguments as String?;
      if (url != null) {
        _handleDeepLink(url);
      }
    }
  }

  void _handleDeepLink(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'crmapp') return;

    final path = uri.host;

    if (path == 'cregis') {
      final subPath = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';

      if (subPath == 'success') {
        try {
          final dashboardController = Get.find<DashboardController>();
          dashboardController.markMT5AccountsAsStale();
        } catch (_) {}

        CustomToastService.showSuccess(
          message: 'Returning from payment. Checking status...',
        );

        Get.offAllNamed(
          AppPages.TRANSACTION_HISTORY,
          arguments: {'from': 'finance'},
        );
      } else if (subPath == 'cancel') {
        CustomToastService.showWarning(
          message: 'Payment was cancelled.',
          title: 'Cancelled',
        );
        Get.offAllNamed(Routes.TRADING);
      }
    }
  }
}
