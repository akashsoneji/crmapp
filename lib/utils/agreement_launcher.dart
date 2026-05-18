import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crm_app/controllers/app_notification_controller.dart';
import 'package:crm_app/routes/app_pages.dart';
import 'package:crm_app/screens/common/webview_screen.dart';
import 'package:crm_app/services/crm_settings_service.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/services/secure_storage_service.dart';

/// Opens Terms, Privacy, or IB agreements from CRM settings API with fallbacks.
class AgreementLauncher {
  AgreementLauncher._();

  static const String termsKey = 'terms_conditions';
  static const String privacyKey = 'privacy_policy';
  static const String ibTermsKey = 'ib_terms';

  static Future<void> openTerms() => _open(
        agreementKey: termsKey,
        brokerUrlKey: 'terms_of_use_url',
        fallbackTitleKey: 'register_terms_condition',
      );

  static Future<void> openPrivacy() => _open(
        agreementKey: privacyKey,
        brokerUrlKey: 'privacy_policy_url',
        fallbackTitleKey: 'privacy_policy_title',
      );

  static Future<void> openIbTerms() => _open(
        agreementKey: ibTermsKey,
        brokerUrlKey: 'ib_terms_url',
        fallbackTitleKey: 'terms_conditions',
      );

  static Future<void> _open({
    required String agreementKey,
    required String brokerUrlKey,
    required String fallbackTitleKey,
  }) async {
    final languageService = Get.find<LanguageService>();
    final title = languageService.tr(fallbackTitleKey);

    if (Get.isRegistered<CrmSettingsService>()) {
      final crmService = Get.find<CrmSettingsService>();
      if (crmService.current == null) {
        await crmService.fetchCrmSettings();
      }
      final agreement = crmService.agreementFor(agreementKey);
      if (agreement != null && (agreement.canOpen || agreement.hasUrl)) {
        await _openUrl(
          agreement.url,
          agreement.label.isNotEmpty ? agreement.label : title,
        );
        return;
      }
    }

    final brokerData = await SecureStorageService.getTenaxBrokerSelection();
    final brokerUrl =
        brokerData?['broker_runtime_config']?[brokerUrlKey]?.toString();
    if (brokerUrl != null && brokerUrl.isNotEmpty) {
      await _openUrl(brokerUrl, title);
      return;
    }

    await _handleUnavailableFallback(
      agreementKey: agreementKey,
      title: title,
      languageService: languageService,
    );
  }

  /// Fallback when no URL is available — driven by [agreementKey], not a static flag.
  static Future<void> _handleUnavailableFallback({
    required String agreementKey,
    required String title,
    required LanguageService languageService,
  }) async {
    if (agreementKey == privacyKey) {
      Get.toNamed(AppPages.PRIVACY_POLICY);
      return;
    }

    if (agreementKey == termsKey || agreementKey == ibTermsKey) {
      _showInAppNotice(
        title: title,
        message: languageService.tr('agreement_document_unavailable'),
      );
      return;
    }

    _showInAppNotice(
      title: title,
      message: languageService.tr('agreement_document_unavailable'),
    );
  }

  static void _showInAppNotice({
    required String title,
    required String message,
  }) {
    if (Get.isRegistered<AppNotificationController>()) {
      Get.find<AppNotificationController>().showInfo(
        title: title,
        message: message,
      );
      return;
    }
  }

  static Future<void> _openUrl(String url, String title) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return;

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      await Get.to(
        () => WebViewScreen(url: trimmed, title: title),
        transition: Transition.rightToLeft,
      );
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri,);
    }
  }
}
