---
name: project-tenax-pending-broker-deferred-commit
description: "Tenax broker selection uses deferred-commit (pendingBroker) pattern - branding only flips on successful auth"
type: project
createdAt: 1783489338526
updatedAt: 1783489806835
---

Tenax multi-broker broker selection uses a DEFERRED-COMMIT pattern: tapping a broker on the selection screen NO LONGER commits branding (color/logo) immediately. Instead, the broker is staged in-memory as static fields on `TenaxBrokerSelectionController` (`pendingBrokerPayload`, `pendingBrokerModel`) and the user is routed to LOGIN/GET_STARTED/CREATE_ACCOUNT with `{pendingBroker: true, forceAuth: true, cameFromLoggedInSession: bool, preserveBroker: true}` args.

**Why:** A user tapping a broker from a logged-in session or from the broker search might back out of login/register without completing the action. Previously, `selectBroker` saved branding + applied FlavorConfig eagerly, which corrupted the active session's branding on accidental taps. The staged pattern makes branding atomic to "successful login OR successful registration".

**How to apply:**
- Static fields die with the process — if the app dies between broker tap and login, user must re-tap. This is intentional (we don't want stale branding to leak across cold starts).
- AuthController `_commitPendingBrokerIfAny()` is the ONLY commit point. Called from `_completeLogin` and `registerWithOTPVerification` BEFORE `_persistTenaxUserBrokerProfile()` so the new (email, broker) profile picks up the right broker.
- After commit, `clearPendingBroker()` is called in finally.
- Home button (`_restoreSessionAndExit`) on LoginScreen / GetStartedScreen / CreateAccountScreen — only shown when `cameFromLoggedInSession == true`. It restores snapshotted token/user_data from `_stashSessionForHomeRestore()` (or from inline `shadowAuthToken`/`shadowWsToken`/`shadowUserDataJson` args) and bounces to TRADING.
- `LoginScreen.dispose()` clears the pending broker so system-back/cancel doesn't leak stale state.
- Callers that clear storage BEFORE snapshotting (e.g. `_addAnotherAccountOnCurrentBroker` in MoreScreen) embed the snapshot directly in route arguments as `shadowAuthToken`/`shadowWsToken`/`shadowUserDataJson`. The destination screens prefer these over storage reads.
- Branch (B) of selectBroker (different user already on this broker) still routes to SPLASH with a snackbar — NOT into the staged flow.
- Branch (C) is split: `preserveBroker: true` (Switch Account → "Log in with another account" path) still commits branding because the user is staying on the same broker they were already on. Only the FIRST-time broker selection path stages.

**Affected files:**
- `lib/controllers/tenax_broker_selection_controller.dart` (added pendingBrokerPayload/Model, restructured branch C)
- `lib/controllers/auth_controller.dart` (added `_commitPendingBrokerIfAny`, called from login + register flows)
- `lib/services/secure_storage_service.dart` (added `getUserDataRawJson()` for session snapshotting)
- `lib/screens/auth/getstart/login_screen.dart` (AppBar Home button + _restoreSessionAndExit + session snapshotting + dispose() clears pending + reads shadow args)
- `lib/screens/auth/getstart/get_started_screen.dart` (Home button + shadow arg support + prop drilling pendingBroker to login/register routes)
- `lib/screens/auth/register/create_account_screen.dart` (Home button in header alongside back button + shadow arg support)
- `lib/screens/home/more/more_screen.dart` (`_addAnotherAccountOnCurrentBroker` now snapshots session before clearing auth and passes `cameFromLoggedInSession:true` + `shadowAuthToken`/`shadowWsToken`/`shadowUserDataJson` in args)
