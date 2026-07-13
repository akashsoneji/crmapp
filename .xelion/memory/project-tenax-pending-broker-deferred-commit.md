---
name: project-tenax-pending-broker-deferred-commit
description: "Tenax multi-broker: deferred-commit + home button on login/register flows + shadow session snapshot"
type: project
createdAt: 1783489338526
updatedAt: 1783932498195
---

Tenax multi-broker broker selection uses a DEFERRED-COMMIT pattern: tapping a broker on the selection screen NO LONGER commits branding (color/logo) immediately. Instead, the broker is staged in-memory as static fields on `TenaxBrokerSelectionController` (`pendingBrokerPayload`, `pendingBrokerModel`) and the user is routed to LOGIN/GET_STARTED/CREATE_ACCOUNT with `{pendingBroker: true, forceAuth: true, cameFromLoggedInSession: bool, preserveBroker: false}` args (plus any forwarded `shadow*` snapshot args).

**Why:** A user tapping a broker from a logged-in session or from the broker search might back out of login/register without completing the action. Previously, `selectBroker` saved branding + applied FlavorConfig eagerly, which corrupted the active session's branding on accidental taps. The staged pattern makes branding atomic to "successful login OR successful registration".

**How to apply:**
- Static fields die with the process — if the app dies between broker tap and login, user must re-tap. This is intentional (we don't want stale branding to leak across cold starts).
- `AuthController._commitPendingBrokerIfAny()` is the ONLY commit point. Called from `_completeLogin` and `registerWithOTPVerification` BEFORE `_persistTenaxUserBrokerProfile()` so the new (email, broker) profile picks up the right broker.
- After commit, `TenaxBrokerSelectionController.clearPendingBroker()` is called in finally on both auth paths.
- Home button on `LoginScreen` / `GetStartedScreen` / `CreateAccountScreen` — only shown when `cameFromLoggedInSession == true`. It restores snapshotted token/user_data from `_shadowAuthToken`/`_shadowWsToken`/`_shadowUserDataJson` instance fields (sourced from `Get.arguments`) and bounces to TRADING.
- `LoginScreen.dispose()` (and `GetStartedScreen.dispose()` / `CreateAccountScreen.dispose()`) all clear the pending broker so system-back/cancel doesn't leak stale state.
- `MoreScreen._showAddAccountBottomSheet()` "Choose Broker" button snapshots the session via `SecureStorageService.snapshotCurrentSession()` BEFORE pushing and passes the shadow args + `cameFromLoggedInSession:true, pendingBroker:true, forceAuth:true, preserveBroker:false` in route args.
- Branch (B) of selectBroker (different user already on this broker) still routes to SPLASH with snackbar — NOT into the staged flow.
- Branch (C) preserveBroker=true (Switch Account → "Log in with another account" on same broker) commits branding immediately because the user is staying on the same broker they were already on. Only the FIRST-time broker selection path stages.
- The broker selection controller forwards all incoming `Get.arguments` (except `allowBack`/`nextRoute`) to LOGIN/GET_STARTED so the shadow session propagates end-to-end.

**Affected files:**
- `lib/controllers/tenax_broker_selection_controller.dart` (added pendingBrokerPayload/Model, restructured branches A/B/C)
- `lib/controllers/auth_controller.dart` (added `_commitPendingBrokerIfAny`, called from login + register flows)
- `lib/services/secure_storage_service.dart` (added `getUserDataRawJson()` and `snapshotCurrentSession()` for session snapshotting)
- `lib/screens/auth/getstart/login_screen.dart` (AppBar Home button + _restoreSessionAndExit + session snapshotting via shadow args + dispose() clears pending)
- `lib/screens/auth/getstart/get_started_screen.dart` (converted to StatefulWidget, Home button + _restoreSessionAndExit + _forwardedArgs() prop-drills shadow args to login/register routes + dispose() clears pending)
- `lib/screens/auth/register/create_account_screen.dart` (Home button in header alongside back button + _restoreSessionAndExit + shadow args in initState + dispose() clears pending)
- `lib/screens/home/more/more_screen.dart` (`_showAddAccountBottomSheet` "Choose Broker" button now snapshots session via `SecureStorageService.snapshotCurrentSession()` and passes `cameFromLoggedInSession:true, pendingBroker:true, forceAuth:true, preserveBroker:false` + shadow* args)
