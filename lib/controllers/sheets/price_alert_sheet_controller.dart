import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:crm_app/controllers/app_notification_controller.dart';
import 'package:crm_app/services/notification_service.dart';
import 'package:crm_app/services/price_alert_monitor_service.dart';
import 'package:crm_app/utils/precision_helper.dart';

typedef AddPriceAlertFn = Future<void> Function({
  required String symbol,
  required double targetPrice,
  required String condition,
  required double currentPrice,
  String? message,
});

/// State for the tenaxnew "New Price Alert" sheet.
///
/// The submit flow mirrors `_PriceAlertDialogState._setPriceAlert` in
/// `lib/widgets/price_alert_dialog.dart` step for step (same services, same
/// arguments, same toasts) so both designs create identical alerts.
class PriceAlertSheetController extends GetxController {
  static const String conditionAbove = 'above';
  static const String conditionBelow = 'below';

  final String symbol;
  final int digits;

  /// Bid when the sheet opened; passed to the monitor service as
  /// `currentPrice`, exactly like the old dialog.
  final double openingBid;

  final Stream<dynamic>? bidChanges;
  final double? Function()? readBid;
  final AddPriceAlertFn _addPriceAlert;
  final bool Function() _hasNotificationPermission;
  final Future<bool> Function() _requestNotificationPermission;
  final Future<void> Function() _initializeNotifications;

  final TextEditingController priceField = TextEditingController();
  final TextEditingController noteField = TextEditingController();
  final RxDouble price = 0.0.obs;
  final RxDouble liveBid = 0.0.obs;
  final RxString condition = conditionAbove.obs;
  final RxBool isNoteOpen = false.obs;
  final RxBool isLoading = false.obs;

  StreamSubscription<dynamic>? _bidSubscription;

  PriceAlertSheetController({
    required this.symbol,
    required this.openingBid,
    this.digits = 5,
    this.bidChanges,
    this.readBid,
    AddPriceAlertFn? addPriceAlert,
    bool Function()? hasNotificationPermission,
    Future<bool> Function()? requestNotificationPermission,
    Future<void> Function()? initializeNotifications,
  })  : _initializeNotifications =
            initializeNotifications ?? NotificationService().initialize,
        _addPriceAlert =
            addPriceAlert ?? PriceAlertMonitorService().addPriceAlert,
        _hasNotificationPermission = hasNotificationPermission ??
            (() => NotificationService().hasPermission),
        _requestNotificationPermission = requestNotificationPermission ??
            NotificationService().requestPermissions;

  /// One tick of the last decimal: 1 / 10^digits.
  double get tick {
    var multiplier = 1.0;
    for (var i = 0; i < digits; i++) {
      multiplier *= 10.0;
    }
    return 1.0 / multiplier;
  }

  String get priceText => format(price.value);

  /// Signed distance of the target from the live bid.
  double get distance =>
      PrecisionHelper.round(price.value - liveBid.value, decimals: digits);

  double get distancePercent =>
      liveBid.value == 0 ? 0 : (distance / liveBid.value) * 100;

  bool get isAbove => condition.value == conditionAbove;

  String format(double value) =>
      PrecisionHelper.formatPrice(value, decimals: digits);

  @override
  void onInit() {
    super.onInit();
    final rounded = PrecisionHelper.round(openingBid, decimals: digits);
    price.value = rounded;
    liveBid.value = rounded;
    priceField.text = format(rounded);
    _bidSubscription = bidChanges?.listen((_) => _refreshBid());
    // Same warm-up the old dialog runs on open; failures surface on submit.
    unawaited(_initializeNotifications().catchError((Object _) {}));
  }

  @override
  void onClose() {
    _bidSubscription?.cancel();
    priceField.dispose();
    noteField.dispose();
    super.onClose();
  }

  void _refreshBid() {
    final bid = readBid?.call();
    if (bid == null || bid <= 0) return;
    liveBid.value = PrecisionHelper.round(bid, decimals: digits);
  }

  void stepUp() => _setPrice(price.value + tick);

  void stepDown() => _setPrice(price.value - tick);

  /// Called while the user types; invalid text keeps the last good value.
  void onPriceTyped(String text) {
    final parsed = double.tryParse(text.trim());
    if (parsed == null) return;
    // Do not rewrite the field while the user is typing in it.
    _setPrice(parsed, syncField: false);
  }

  void useLiveBid() => _setPrice(liveBid.value);

  void _setPrice(double value, {bool syncField = true}) {
    price.value =
        PrecisionHelper.round(value < 0 ? 0 : value, decimals: digits);
    if (syncField) priceField.text = format(price.value);
  }

  void setCondition(String value) {
    if (value != conditionAbove && value != conditionBelow) return;
    condition.value = value;
  }

  void toggleNote() => isNoteOpen.toggle();

  /// Returns true when the alert was created (the sheet should close).
  Future<bool> submit() async {
    if (isLoading.value) return false;
    if (priceField.text.trim().isEmpty) {
      _notifyError('Please enter a price');
      return false;
    }

    isLoading.value = true;
    try {
      final target =
          PrecisionHelper.parseDouble(priceField.text, decimals: digits);
      if (target <= 0) {
        throw Exception('Invalid price');
      }

      if (!_hasNotificationPermission()) {
        final granted = await _requestNotificationPermission();
        if (!granted) {
          throw Exception(
            'Notification permission is required for price alerts',
          );
        }
      }

      final trimmedNote = noteField.text.trim();
      await _addPriceAlert(
        symbol: symbol,
        targetPrice: target,
        condition: condition.value,
        currentPrice: openingBid,
        message: trimmedNote.isNotEmpty ? trimmedNote : null,
      );

      _notifySuccess(
        'Price alert set successfully! You will be notified when $symbol reaches \$${format(target)}.',
      );
      return true;
    } catch (e) {
      _notifyError('Error setting price alert: $e');
      return false;
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  void _notifySuccess(String message) {
    if (!Get.isRegistered<AppNotificationController>()) return;
    Get.find<AppNotificationController>().showSuccess(message: message);
  }

  void _notifyError(String message) {
    if (!Get.isRegistered<AppNotificationController>()) return;
    Get.find<AppNotificationController>().showError(message: message);
  }
}
