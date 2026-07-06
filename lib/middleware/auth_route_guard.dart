import 'package:get/get.dart';
import 'package:crm_app/routes/app_pages.dart';
import 'package:crm_app/services/secure_storage_service.dart';

/// Middleware used by `GetMaterialApp.routingCallback` (and as a backstop in
/// each auth screen's `initState`) to bounce already-logged-in users out of
/// auth-only routes.
///
/// Why: if the user is somehow routed to a login/auth screen while a session
/// is still active (deep link, race condition, hot reload, manual
/// `Get.toNamed` call from legacy code), they should be sent back to TRADING
/// instead of being asked to re-authenticate over their existing session.
///
/// Layered defenses:
///   - Layer 1: this `authOnlyRouteRedirect` is wired into the global
///     `routingCallback` in `main.dart` (Step 10c).
///   - Layer 2: each auth screen calls `_checkAndRedirectIfLoggedIn()` in
///     `initState` (Step 10d) so the redirect runs even if the routing
///     callback fires after the screen has mounted.
///
/// Important: the `_authOnlyRoutes` set does NOT include
/// `TENAX_BROKER_SELECTION`. A logged-in user is still allowed to re-pick a
/// broker; Step 2 of the plan handles that case explicitly.

const Set<String> _authOnlyRoutes = {
  AppPages.LOGIN,
  AppPages.GET_STARTED,
  AppPages.CREATE_ACCOUNT,
  AppPages.FORGOT_PASSWORD,
  AppPages.VERIFY_CODE,
  AppPages.CREATE_NEW_PASSWORD,
  AppPages.GOOGLE_LOGIN_OTP,
  AppPages.LEGAL_DOCUMENTS,
  AppPages.PRIVACY_POLICY,
  AppPages.ACCOUNT_CREATED,
  AppPages.TWO_FACTOR_AUTH,
};

/// If [route] is an auth-only route AND there is an active auth session,
/// return the redirect target route name (`AppPages.TRADING`). Otherwise
/// return `null` (no redirect).
///
/// The caller is responsible for actually performing the navigation:
///   - `routingCallback` callbacks should `Get.offAllNamed(redirect)`
///     on the next microtask.
///   - `initState` guards should also call `Get.offAllNamed(redirect)`.
///
/// `Get.arguments['forceAuth'] == true` bypasses the guard so the legitimate
/// "Log in with another account" flow (Switch Account → re-auth) is never
/// blocked even if the caller forgot to clear the active session first.
Future<String?> authOnlyRouteRedirect(String? route) async {
  if (route == null) return null;
  if (!_authOnlyRoutes.contains(route)) return null;
  // ✅ Step 10e: respect the explicit forceAuth override
  final args = Get.arguments as Map<String, dynamic>?;
  if (args?['forceAuth'] == true) return null;
  final session = await SecureStorageService.getActiveSession();
  if (!session.loggedIn) return null;
  print(
    'AuthRouteGuard: Logged-in user (${session.email}) tried to access '
    'auth route $route → redirecting to ${AppPages.TRADING}',
  );
  return AppPages.TRADING;
}

/// True if the supplied route name is an auth-only route. Useful for the
/// per-screen `initState` backstop so screens can short-circuit before doing
/// any routing work.
bool isAuthOnlyRoute(String? route) {
  if (route == null) return false;
  return _authOnlyRoutes.contains(route);
}
