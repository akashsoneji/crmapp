import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_app/constants/api_const.dart';
import 'package:crm_app/controllers/tenax_broker_selection_controller.dart';
import 'package:crm_app/flavor_config.dart';
import 'package:crm_app/models/tenax_broker_model.dart';
import 'package:crm_app/services/api_service.dart';
import 'package:crm_app/services/secure_storage_service.dart';
import 'package:crm_app/services/tenax_broker_service.dart';

/// Broker and referral code carried by a Tenax invite link.
class DeepLinkIntent {
  const DeepLinkIntent({
    required this.brokerSlug,
    this.referralCode,
    this.source = sourceLink,
    this.clickId,
  });

  /// `referral_source` values sent with registration and attribution.
  static const String sourceLink = 'link';
  static const String sourcePlayReferrer = 'play_referrer';
  static const String sourceServerMatch = 'server_match';

  final String brokerSlug;
  final String? referralCode;
  final String source;
  final String? clickId;

  Map<String, String> toJson() => {
    'broker_slug': brokerSlug,
    'ref': ?referralCode,
    'source': source,
    'click_id': ?clickId,
  };

  /// Builds an intent from `broker` / `broker_slug`, `ref` and `click_id`
  /// keys, as used by the Play install referrer and the deferred-link match
  /// API. A stored `source` wins over [source].
  static DeepLinkIntent? fromParams(
    Map<String, dynamic> params, {
    String source = sourceLink,
  }) {
    final slug = _clean(params['broker_slug'] ?? params['broker']);
    if (slug == null) return null;
    final clickId = _clean(params['click_id']);
    return DeepLinkIntent(
      brokerSlug: slug,
      referralCode: _clean(params['ref']),
      source: _clean(params['source']) ?? source,
      clickId: clickId != null && clickId.length <= 64 ? clickId : null,
    );
  }

  static String? _clean(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

/// Handles `https://app.tenaxcode.com/invite/<broker_slug>?ref=<code>` and
/// `tenax://invite/<broker_slug>?ref=<code>` for the multi-broker Tenax build.
class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  static const String _webHost = 'app.tenaxcode.com';
  static const String _customScheme = 'tenax';
  static const String _invitePath = 'invite';
  static const String _deferredMatchUrl =
      'https://broker.tenaxcode.com/api/mobile/deferred-link/match';
  static const Duration _timeout = Duration(seconds: 10);

  static const String _pendingReferralKey = 'deep_link_pending_referral';
  static const String _installReferralCheckedKey =
      'deep_link_install_referral_checked';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  /// `uriLinkStream` also replays the link that launched the app; that one is
  /// already handled at startup, so its first emission is skipped.
  String? _launchLinkToSkip;

  static DeepLinkIntent? parse(Uri uri) {
    final List<String> segments;
    if (uri.scheme == 'https' && uri.host == _webHost) {
      segments = uri.pathSegments;
    } else if (uri.scheme == _customScheme) {
      segments = [uri.host, ...uri.pathSegments];
    } else {
      return null;
    }

    if (segments.length < 2 || segments.first != _invitePath) return null;
    return DeepLinkIntent.fromParams({
      'broker_slug': segments[1],
      'ref': uri.queryParameters['ref'],
      'click_id': uri.queryParameters['click_id'],
    });
  }

  /// Returns the invite that launched the app or, on the first launch after
  /// install, the deferred invite. Either one is saved as the pending referral.
  Future<DeepLinkIntent?> resolveStartupIntent({
    required bool isLoggedIn,
  }) async {
    if (!FlavorConfig.isMultiBrokerEnabled) return null;

    DeepLinkIntent? intent;
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('DeepLinkService: launch link received: $initialUri');
        _launchLinkToSkip = initialUri.toString();
        intent = parse(initialUri);
      }
    } catch (e) {
      debugPrint('DeepLinkService: initial link error: $e');
    }

    final installIntent = await _resolveInstallReferralOnce(
      isLoggedIn: isLoggedIn,
    );
    intent ??= installIntent;

    if (intent != null) await savePendingReferral(intent);
    return intent;
  }

  void listenForLiveLinks() {
    if (!FlavorConfig.isMultiBrokerEnabled || _linkSubscription != null) return;
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) async {
        final link = uri.toString();
        debugPrint('DeepLinkService: live link received: $link');
        if (link == _launchLinkToSkip) {
          _launchLinkToSkip = null;
          return;
        }
        final intent = parse(uri);
        if (intent == null) return;
        await savePendingReferral(intent);
        final isLoggedIn = await SecureStorageService.isUserLoggedIn();
        await openBrokerFromInvite(intent, isLoggedIn: isLoggedIn);
      },
      onError: (Object e) => debugPrint('DeepLinkService: link stream error: $e'),
    );
  }

  Future<void> savePendingReferral(DeepLinkIntent intent) async {
    await _storage.write(
      key: _pendingReferralKey,
      value: jsonEncode(intent.toJson()),
    );
    debugPrint(
      'DeepLinkService: referral saved broker=${intent.brokerSlug} '
      'ref=${intent.referralCode}',
    );
  }

  Future<DeepLinkIntent?> getPendingReferral() async {
    final raw = await _storage.read(key: _pendingReferralKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic>
          ? DeepLinkIntent.fromParams(decoded)
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getPendingReferralCode() async =>
      (await getPendingReferral())?.referralCode;

  Future<void> clearPendingReferral() =>
      _storage.delete(key: _pendingReferralKey);

  /// `referral_source` / `referral_click_id` for the register request. Empty
  /// when [enteredCode] is not the invite's code (the user typed their own).
  static Map<String, String> registrationFieldsFor(
    DeepLinkIntent? intent,
    String enteredCode,
  ) {
    final code = intent?.referralCode;
    if (intent == null || code == null || code != enteredCode.trim()) {
      return const {};
    }
    return {
      'referral_source': intent.source,
      'referral_click_id': ?intent.clickId,
    };
  }

  /// Tells the broker the account was just registered on which invite click
  /// it came from (`POST deeplink/attribution`). Runs after registration, when
  /// the API points at that broker. Failures are ignored.
  Future<void> reportAttribution() async {
    final intent = await getPendingReferral();
    final code = intent?.referralCode;
    final clickId = intent?.clickId;
    if (intent == null || code == null || clickId == null) return;
    try {
      await ApiService.post(
        endpoint: ApiConstants.deepLinkAttribution,
        data: {
          'brand': intent.brokerSlug,
          'click_id': clickId,
          'code': code,
          'source': intent.source,
        },
      );
    } catch (e) {
      debugPrint('DeepLinkService: attribution report failed: $e');
    }
  }

  /// Selects the invite's broker through the normal broker-selection flow.
  /// Returns true when it navigated away from the current screen.
  Future<bool> openBrokerFromInvite(
    DeepLinkIntent intent, {
    required bool isLoggedIn,
  }) async {
    if (!FlavorConfig.isMultiBrokerEnabled) return false;
    try {
      final current = await SecureStorageService.getTenaxBrokerSelection();
      final currentSlug = (current?['selected_slug'] ?? '').toString();
      // Same broker: the normal flow continues and the referral stays pending.
      if (currentSlug == intent.brokerSlug) return false;

      if (isLoggedIn && !await _confirmBrokerSwitch()) return false;

      final broker = await _findBroker(intent.brokerSlug);
      if (broker == null) return false;

      Map<String, dynamic> routeArguments = const {};
      if (isLoggedIn) {
        // Same arguments as MoreScreen._openBrokerSelection, so the Home button
        // on the login / register screens can restore the current session.
        final snapshot = await SecureStorageService.snapshotCurrentSession();
        routeArguments = {
          'cameFromLoggedInSession': true,
          'pendingBroker': true,
          'forceAuth': true,
          'preserveBroker': false,
          'shadowAuthToken': snapshot?.token,
          'shadowWsToken': snapshot?.wsToken,
          'shadowUserDataJson': snapshot?.userJson,
        };
      }

      final controller =
          Get.isRegistered<TenaxBrokerSelectionController>()
              ? Get.find<TenaxBrokerSelectionController>()
              : Get.put(TenaxBrokerSelectionController());
      await controller.selectBroker(broker, routeArguments: routeArguments);
      return true;
    } catch (e) {
      debugPrint('DeepLinkService: unable to open invite broker: $e');
      return false;
    }
  }

  Future<DeepLinkIntent?> _resolveInstallReferralOnce({
    required bool isLoggedIn,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_installReferralCheckedKey) ?? false) return null;
    // Marked before the lookup so a slow or failing lookup is never retried
    // on a later launch and applied to an unrelated session.
    await prefs.setBool(_installReferralCheckedKey, true);

    // SharedPreferences is wiped on uninstall but the iOS Keychain is not, so
    // drop any referral left over from a previous install.
    await clearPendingReferral();

    if (isLoggedIn) return null;
    try {
      if (Platform.isAndroid) return await _readPlayInstallReferrer();
      if (Platform.isIOS) return await _matchDeferredLink();
    } catch (e) {
      debugPrint('DeepLinkService: install referral lookup failed: $e');
    }
    return null;
  }

  /// The store link carries `referrer=broker%3D<slug>%26ref%3D<code>`.
  Future<DeepLinkIntent?> _readPlayInstallReferrer() async {
    final details = await PlayInstallReferrer.installReferrer;
    final referrer = details.installReferrer;
    debugPrint('DeepLinkService: play install referrer: $referrer');
    if (referrer == null || referrer.isEmpty) return null;
    return DeepLinkIntent.fromParams(
      Uri.splitQueryString(referrer),
      source: DeepLinkIntent.sourcePlayReferrer,
    );
  }

  /// The App Store passes nothing to the app, so the backend matches this
  /// device against the invite click it logged before the store redirect.
  Future<DeepLinkIntent?> _matchDeferredLink() async {
    final views = PlatformDispatcher.instance.views;
    final logicalSize =
        views.isEmpty
            ? Size.zero
            : views.first.physicalSize / views.first.devicePixelRatio;

    final response = await http
        .post(
          Uri.parse(_deferredMatchUrl),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'platform': 'ios',
            'os_version': Platform.operatingSystemVersion,
            'locale': PlatformDispatcher.instance.locale.toLanguageTag(),
            'timezone_offset_minutes': DateTime.now().timeZoneOffset.inMinutes,
            'screen_width': logicalSize.width.round(),
            'screen_height': logicalSize.height.round(),
          }),
        )
        .timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic> || body['status'] != true) return null;
    final data = body['data'];
    return data is Map<String, dynamic>
        ? DeepLinkIntent.fromParams(
            data,
            source: DeepLinkIntent.sourceServerMatch,
          )
        : null;
  }

  Future<TenaxBrokerModel?> _findBroker(String slug) async {
    final service = TenaxBrokerService();
    final brokers = await service.fetchBrokers(search: slug);
    for (final broker in brokers) {
      if (broker.slug == slug) return broker;
    }

    // The list search matches names, so fall back to the broker's own config.
    final config = await service.fetchBrokerConfigBySlug(slug);
    return TenaxBrokerModel.fromJson({
      ...config,
      'slug': slug,
      'name': config['brandName'] ?? config['name'] ?? slug,
    });
  }

  Future<bool> _confirmBrokerSwitch() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Switch broker?'),
        content: const Text(
          'This invite link is for a different broker. Switch now? You can '
          'return to your current account with the Home button.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Switch'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
