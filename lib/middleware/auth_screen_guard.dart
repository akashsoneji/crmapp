import 'package:get/get.dart';
import 'package:crm_app/routes/app_pages.dart';
import 'package:crm_app/services/secure_storage_service.dart';

/// Shared helper used by every auth-only screen's `initState` to bounce an
/// already-logged-in user back to TRADING. Step 10d of the
/// tenax-same-broker-multi-user plan.
///
/// Bypassed if `Get.arguments['forceAuth'] == true` (used by the legitimate
/// "Log in with another account" flow from the Switch Account sheet).
///
/// This is the per-screen backstop for the global `routingCallback` guard
/// in `auth_route_guard.dart`. Both layers must be present so the redirect
/// works regardless of whether it fires before or after the screen mounts.
Future<void> checkAndRedirectIfLoggedIn({String? screenName}) async {
  final args = Get.arguments as Map<String, dynamic>?;
  if (args?['forceAuth'] == true) return;
  final session = await SecureStorageService.getActiveSession();
  if (!session.loggedIn) return;
  print(
    '${screenName ?? "AuthScreen"}: Logged-in user (${session.email}) '
    'reached this screen — bouncing to ${AppPages.TRADING}.',
  );
  Get.offAllNamed(AppPages.TRADING);
}