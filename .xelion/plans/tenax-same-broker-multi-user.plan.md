# Tenax Same-Broker Multi-User — Implementation Plan

## Goal
Fix the Tenax flavor's multi-broker account management so that the **same broker can be added/used by multiple different users** (User A and User B both logged in via the Tenax broker, side by side). Today the code collapses everyone using the same broker into a single profile because the broker-saved lookup matches by `broker_slug` only — it ignores the user email. After this fix, `(email, broker_slug)` becomes the canonical identity, switching between A and B is supported, and the active session is never silently hijacked.

## Approach

The Tenax architecture already has all the right primitives (`profile_key = '<email>|<broker_slug>'` is already the canonical identity used by `_normalizeTenaxProfile` and `upsertTenaxUserBrokerProfile`). The fix is to **enforce `profile_key` as the lookup key everywhere** and add one new user-facing affordance ("Log in as another user in this broker") so the broken path is replaced with an explicit flow.

**Key decisions / trade-offs:**
1. **Identity = `profile_key`** (lowercased email + broker_slug). All match logic switches to this. Storage layer is already keyed this way; only the read paths need fixing.
2. **No silent auto-login on broker re-selection.** When a broker is tapped on the selection screen:
   - If the active session's profile matches `(currentEmail, brokerSlug)` → keep the active session, just re-apply the broker runtime config and go home.
   - If a **different** profile exists for this broker (i.e. User A) and current session is B → keep B logged in, but show a small banner/CTA "Switch to A".
   - If no profile exists for the active user → fresh login as today.
3. **Add explicit "Log in with another account"** entry in the existing Switch Account bottom sheet so users have a first-class way to add a second user to the same broker.
4. **Navigation guard**: if an already-logged-in user accidentally lands on a login/auth screen (deep link, hot-reload, race), they get bounced back home automatically.
5. **Logout auto-fallback** keeps the current behavior of switching to the next valid saved profile. No change needed there — it already keys by `profile_key`.
6. **No backend changes required.** Everything is client-side state — the auth API already returns the right user/token when User B logs in with B's credentials; we just need to save it under a separate profile.

## Steps

- [x] **Step 1 — Add identity-aware match helpers in `SecureStorageService`**
  In `lib/services/secure_storage_service.dart`, add:
  - `findTenaxProfileByIdentity({email, brokerSlug})` — returns the unique profile matching `<lowercased_email>|<broker_slug>` (or null).
  - `findTenaxProfilesByBrokerSlug(brokerSlug)` — returns ALL saved profiles for a given broker slug (across all users/emails). Uses `profile_key` suffix match plus legacy slug-field fallback.
  - `findTenaxProfileForActiveSession()` — returns the active profile based on the current session's email + selected broker slug (or null).
  - `getActiveSession()` — returns `({bool loggedIn, String? email})` for the route guard.
  - `_assertIdentityConsistency()` — logs a warning if any profile is missing `profile_key` or has duplicate `(email, slug)` pairs.

- [x] **Step 2 — Fix `TenaxBrokerSelectionController.selectBroker` to use identity-aware lookup**
  In `lib/controllers/tenax_broker_selection_controller.dart`, replace the slug-only `existingProfile` lookup with a 3-branch identity check:
  1. Active session exists AND `(activeEmail, brokerSlug)` matches a saved profile → keep current session, re-apply runtime config, route to `SPLASH`.
  2. Active session exists BUT a different email has a profile for this broker → keep current session, raise one-time snackbar, route to `SPLASH` (no silent switch).
  3. No active session → fresh login path (`LOGIN` or `GET_STARTED`).

- [x] **Step 3 — Harden `_persistTenaxUserBrokerProfile` with a debug log**
  In `lib/controllers/auth_controller.dart`, add `print('AuthController: Persisting Tenax profile → email=..., brokerSlug=..., key=...')` right before the upsert call so cross-user separation is visible in logs.

- [x] **Step 4 — Update Switch Account sheet to group by broker + add "Log in with another account"**
  In `lib/screens/home/more/more_screen.dart`:
  - Group profiles by `broker_slug`; same broker with multiple users appears as one group with multiple user rows (avatar + name + email).
  - Existing profile tap → unchanged (`_selectTenaxProfile` restores correctly).
  - New per-group tile "+ Add another account for this broker" — clears ONLY the active auth session (keeps broker selection + other profiles), routes to `LOGIN`/`GET_STARTED` with `{preserveBroker: true, forceAuth: true}`.
  - Existing "Add New +" routes through broker selection with `arguments: {allowBack: true, preserveBroker: true}`.
  - Wire `selectBroker` to honor `preserveBroker` flag so re-tapping same broker doesn't re-open picker.

- [x] **Step 5 — Login screen honor `preserveBroker` arg**
  In `lib/screens/auth/getstart/login_screen.dart`:
  - Read `Get.arguments`; if `preserveBroker == true`, keep broker selection + runtime config; clear only `auth_token`, `user_data`, `is_logged_in`.
  - Show banner "Logging in to <BrokerName> — different account".
  - Add `initState` auth-session guard that bounces to `TRADING` (unless `forceAuth == true`).

- [x] **Step 6 — Splash screen add `profile_key` debug print**
  In `lib/screens/auth/splash/splash_screen.dart`, after auth check: `print('SplashScreen: Active Tenax profile_key = $currentKey')`.

- [x] **Step 7 — Add translation keys**
  In `assets/translations/en.json` (+ ar/hi/es/tr mirrors):
  - `tenax_switch_account_broker_group` → "Broker"
  - `tenax_switch_account_other_user` → "Other account on this broker"
  - `tenax_switch_account_add_another` → "Log in with another account"
  - `tenax_switch_account_add_new_broker` → "Use a different broker"
  - `tenax_login_preserving_broker_banner` → "Logging in to {{brokerName}} — different account"

- [x] **Step 8 — Identity-consistency assertion on app start**
  In `lib/services/secure_storage_service.dart`, expose `assertIdentityConsistency()` (called from `main.dart` after `ensureInitialized`) which logs a warning if any profile is missing `profile_key` or has duplicate `(email, slug)` pairs.

- [x] **Step 9 — Manual end-to-end verification (test matrix documented for QA pass)**
  Test matrix (on `tenax` flavor build):
  1. Fresh install → pick Tenax broker → login as `a@x.com` → save profile `a|x.com|tenax`.
  2. Open More → Switch Account → only one profile shown.
  3. Tap "+ Log in with another account" → login screen with banner → login as `b@x.com` → land on home → open Switch Account → now TWO profiles under same Tenax broker group, each with correct email.
  4. Tap `a@x.com` profile → B's session replaced with A's tokens → home shows A's name.
  5. Tap `b@x.com` profile → A's session replaced with B's tokens → home shows B's name.
  6. Logout from B → existing auto-fallback should switch to A (no broker re-selection needed).
  7. Re-select Tenax broker from picker while logged in as A → snackbar "Another account is registered on Tenax — open Switch Account" → still logged in as A (NOT silently switched to B).
  8. Logout from A → since A was the last profile, fall through to `TENAX_BROKER_SELECTION`.
  9. Auth-route guard: while logged in, manually `Get.toNamed(LOGIN)` → should bounce to `TRADING`.
  10. Auth-route guard: explicit "Log in with another account" with `forceAuth=true` → must NOT bounce.

- [x] **Step 10 — Navigation guard: bounce already-logged-in users out of auth screens**
  - **10a** — `getActiveSession()` helper added (done as part of Step 1).
  - **10b** — New file `lib/middleware/auth_route_guard.dart` defining `authOnlyRouteRedirect(String? route)` and the `_authOnlyRoutes` set (LOGIN, GET_STARTED, CREATE_ACCOUNT, FORGOT_PASSWORD, VERIFY_CODE, CREATE_NEW_PASSWORD, GOOGLE_LOGIN_OTP, LEGAL_DOCUMENTS, PRIVACY_POLICY, ACCOUNT_CREATED, TWO_FACTOR_AUTH). TENAX_BROKER_SELECTION is intentionally NOT included.
  - **10c** — Wire `routingCallback` into `GetMaterialApp` in `lib/main.dart`; use `Future.microtask(Get.offAllNamed(...))` to defer redirect.
  - **10d** — Add `_checkAndRedirectIfLoggedIn()` `initState` guard inside `LoginScreen`, `GetStartedScreen`, `CreateAccountScreen`, `ForgotPasswordScreen`, `VerifyCodeScreen`, `CreateNewPasswordScreen`, `GoogleLoginOtpScreen`, `AccountCreatedScreen`, `TwoFactorAuthScreen`. The guard checks `arguments['forceAuth'] == true` to bypass.
  - **10e** — `forceAuth` plumbing: the Switch Account "Log in with another account" path in Step 4 sets `arguments = {preserveBroker: true, forceAuth: true}` so the legitimate re-auth flow is never blocked.
  - **10f** — `SPLASH` is NOT in the guarded set (already correct — it's reachable while logged in for re-selecting brokers).

## Files

- `lib/services/secure_storage_service.dart` — Added `findTenaxProfileByIdentity`, `findTenaxProfilesByBrokerSlug`, `findTenaxProfileForActiveSession`, `getActiveSession`, `assertIdentityConsistency`.
- `lib/controllers/tenax_broker_selection_controller.dart` — Replaced slug-only `existingProfile` lookup with identity-aware 3-branch logic in `selectBroker`; honors `preserveBroker` arg.
- `lib/controllers/auth_controller.dart` — Added debug log in `_persistTenaxUserBrokerProfile`.
- `lib/screens/home/more/more_screen.dart` — Refactored `_showSwitchAccountBottomSheet` to group profiles by broker + added "Log in with another account" affordance per group.
- `lib/screens/auth/getstart/login_screen.dart` — Honors `arguments['preserveBroker']`; shows banner; added `initState` auth-session guard.
- `lib/screens/auth/splash/splash_screen.dart` — Added active `profile_key` debug print.
- `lib/middleware/auth_route_guard.dart` — **NEW** — `authOnlyRouteRedirect` callback + `_authOnlyRoutes` set.
- `lib/main.dart` — Wired `routingCallback` to `authOnlyRouteRedirect`; calls `assertIdentityConsistency()` after `WidgetsFlutterBinding.ensureInitialized()`.
- `lib/screens/auth/getstart/get_started_screen.dart` — Added `initState` auth-session guard.
- `lib/screens/auth/register/create_account_screen.dart` — Added `initState` auth-session guard.
- `lib/screens/auth/password/forgot_password_screen.dart` — Added `initState` auth-session guard.
- `lib/screens/auth/password/verify_code_screen.dart` — Added `initState` auth-session guard.
- `lib/screens/auth/password/create_new_password_screen.dart` — Added `initState` auth-session guard.
- `lib/screens/auth/google_login_otp_screen.dart` — Added `initState` auth-session guard.
- `lib/screens/auth/register/account_created_screen.dart` — Added `initState` auth-session guard.
- `lib/screens/home/more/two_factor_auth_screen.dart` — Added `initState` auth-session guard (login variant).
- `assets/translations/en.json`, `ar.json`, `hi.json`, `es.json`, `tr.json` — Added 5 new translation keys per locale.

## Risks / Open Questions

- **Legacy data:** Profiles saved before this change may have slug-only identity (no `profile_key`, or wrong key due to casing). `_sanitizeTenaxProfiles` already regenerates `profile_key` on read, but the first read after update may still produce merged entries if the old data has the same `(email, slug)` pair under two records. The assertion helper will catch this; users with corrupted state can clear app data and re-login.
- **Same email, two devices:** Out of scope — we only resolve multi-user on a single device. Cross-device sync would need backend session listing (not requested).
- **Token revocation across users:** If User A's token is revoked server-side, switching to A's profile will fail on next API call. Acceptable — the existing code already restores tokens blindly; adding a token-validation step on switch is a separate task.
- **`preserveBroker` flag propagation:** Confirm the Login/GetStarted/Register screens all read `Get.arguments` correctly. If any route strips arguments, the broker context will be lost on the way to login — a small assertion in the login screen should catch this.
- **Multiple accounts per same broker, same email:** Intentionally disallowed — `profile_key` is `(email, slug)`, so the same email can only have one profile per broker. If User B registers a new account with an existing email under the same broker, `_persistTenaxUserBrokerProfile` will overwrite B's own profile, which is the correct UX (B re-logging in updates B's saved session).
- **Auth-route guard vs `forceAuth`:** The redirect guard in Step 10 must NOT bounce a user who is in the middle of an explicit "Log in with another account" flow. The `Switch Account` → "Log in with another account" path (Step 4) clears the active session **before** routing to LOGIN, so `getActiveSession()` will already return `loggedIn: false`. Belt-and-suspenders: we also pass `arguments['forceAuth'] = true` so the per-screen `initState` guard never blocks the legitimate re-auth flow even if there is a race condition with the `routingCallback`.
- **Redirect timing:** `routingCallback` fires after the new route is already pushed. We use `Future.microtask(Get.offAllNamed(...))` so the redirect happens on the next event-loop tick — the user may see a one-frame flash of the auth screen before the bounce. Acceptable; the per-screen `initState` guard covers this case anyway.
- **TENAX_BROKER_SELECTION is intentionally NOT in the guarded set** — a logged-in user is allowed to re-pick a broker (Step 2 handles that flow). Guarding it would break the Switch Account + same-broker snackbar behavior.
