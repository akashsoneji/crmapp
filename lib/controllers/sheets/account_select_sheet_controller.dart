import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:crm_app/controllers/account_controller.dart';
import 'package:crm_app/models/mt5_account.dart';

/// State for the tenaxnew "Select Account" sheet. Reads the same
/// `AccountController` lists and switches with the same
/// `setActiveMT5Account` call as `AccountHeaderWidget.showAccountSelectionSheet`.
class AccountSelectSheetController extends GetxController {
  final AccountController accounts;

  AccountSelectSheetController({AccountController? accounts})
      : accounts = accounts ?? Get.find<AccountController>();

  List<MT5Account> get items => accounts.mt5Accounts;

  bool get isSwitching => accounts.isLoading;

  bool isActive(MT5Account account) =>
      accounts.activeMT5Account?.metaAccountNumber ==
      account.metaAccountNumber;

  static bool isDemo(MT5Account account) =>
      account.accountType.toLowerCase() == 'demo';

  /// Starts the switch exactly like the old sheet: fire and forget, errors
  /// logged. Returns false when nothing should happen (busy or already
  /// active) so the caller can simply close the sheet.
  bool select(MT5Account account) {
    if (isSwitching || isActive(account)) return false;
    unawaited(
      accounts
          .setActiveMT5Account(account.metaAccountNumber)
          .catchError((Object e) {
        if (kDebugMode) debugPrint('Account switch failed: $e');
      }),
    );
    return true;
  }
}
