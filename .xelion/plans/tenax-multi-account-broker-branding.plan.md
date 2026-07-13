# Tenax Multi-Account: LOGIN Screen Branding ko New Broker ke Hisaab se Dikhana

# Tenax Multi-Account: LOGIN Screen Branding ko New Broker ke Hisaab se Dikhana

**Status:** ✅ Built (all 7 implementation steps completed on 2026-07-13).

## Goal

## Current State (kya already hai)

### Working pieces (jo change nahi karne)
1. **Profile list storage** (`SecureStorageService._tenaxUserBrokerProfilesKey`): list of `{profile_key: "email|slug", user_email, broker_slug, broker_data, login_data, saved_at}` — multi-account data yahan store hota hai. ✓
2. **Active broker selection** (`SecureStorageService._tenaxBrokerSelectionKey`): single JSON `{selected_slug, selected_name, selected_logo_local_path, ...}` — FlavorConfig ko hydrate karta hai (URLs, colors, logo). ✓
3. **`TenaxBrokerSelectionController.selectBroker()`** Branch A/B/C:
   - **A (default)**: stage broker in static fields, route to LOGIN/GET_STARTED.
   - **B (cold-start)**: device has saved session + user NOT logged in → restore + go to SPLASH.
   - **C (preserveBroker)**: same-broker switch, commit immediately.
4. **`AuthController._commitPendingBrokerIfAny()`**: called BEFORE `_persistTenaxUserBrokerProfile()` in login + register.
5. **Home button** on LoginScreen / GetStartedScreen / CreateAccountScreen — only when `cameFromLoggedInSession == true`. Restores from `shadowAuthToken` / `shadowWsToken` / `shadowUserDataJson`.
6. **Session snapshot** via `SecureStorageService.snapshotCurrentSession()` — called in `MoreScreen._openBrokerSelection()`.
7. **Cleanup**: each screen's `dispose()` calls `TenaxBrokerSelectionController.clearPendingBroker()`.

### Working flows (jo already pass kar rahe hain)
- User A login on Broker A → branding flips, profile (A, A) saved. ✓
- User B login on Broker A → switch via Switch Account → branding stays A, session updates. ✓
- User A on Broker A picks Broker A (same) → staged, LOGIN shows Broker A branding, can add user C. ✓

### The bug — what's NOT working

**Scenario:** User B logged in on Broker A. New user C wants to add a **different** Broker B.

1. User B → More → Account chip → "Switch Account" → "Add New Broker +" → TENAX_BROKER_SELECTION.
2. Search "Broker B" → tap Broker B tile.
3. `selectBroker(BrokerB)` → Branch A fires (logged in user, any profile scenario).
4. **In Branch A, if `isLoggedIn == true`, branding is NOT applied** (deferred-commit pattern).
5. Routes to GET_STARTED/LOGIN.
6. **The LOGIN screen still shows Broker A's branding** because FlavorConfig was not updated.
7. User thinks "I tapped Broker B but the screen still shows Broker A — the system is broken".

The deferred-commit pattern (don't apply branding until login succeeds) was originally meant to prevent stale branding if user backs out. But in a multi-account world, **the user needs visual confirmation** that they picked the right broker.

## Approach

**Apply new branding immediately when the user picks a broker, and snapshot the OLD branding so Home button can restore it.**

This means:
- User picks Broker B → new branding (color/logo) applied immediately → LOGIN screen shows Broker B branding → user knows they picked correctly.
- User taps Home → OLD branding restored + OLD session restored → TRADING on Broker A as user B.
- User backs out without completing → next screen entry re-shows Broker A branding (because we restore on dispose of LOGIN screen).

The deferred-commit pattern is **relaxed for branding application** but kept for **storage persistence** (we still write to storage only on successful login/register).

### Implementation outline

1. **`FlavorConfig`** — add `snapshotBranding()` and `restoreBranding(snapshot)` helpers. Snapshot stores the full `_instance` reference (it's just an object — we can hold a reference). On restore, replace `_instance` with the snapshot.

2. **`TenaxBrokerSelectionController.selectBroker` Branch A** — change to:
   - **Always** apply new branding (regardless of `isLoggedIn`).
   - **Always** stage the broker.
   - If `!isLoggedIn`, also save to SecureStorage (existing behavior — committed eagerly for fresh users).
   - If `isLoggedIn == true`, do **NOT** save to storage yet, do **NOT** clear auth. Branding flips, session stays.
   - Snapshot the OLD branding in `pendingBrandingSnapshot` so Home can restore.

3. **`AuthController._commitPendingBrokerIfAny()`** — simplified: just persist to storage via `saveTenaxBrokerSelection`. Don't re-apply branding (already done at pick-time). Clear pending state in `finally`.

4. **LoginScreen / GetStartedScreen / CreateAccountScreen** — snapshot FlavorConfig in `initState` (storing the previous branding before the screen mounted). On Home button tap, restore both FlavorConfig and session.

5. **MoreScreen `_openBrokerSelection`** — keep snapshot of session (already done). Branding snapshot is captured automatically by the destination screen on init.

### Edge cases handled

| Scenario | Behavior |
|----------|----------|
| User A on Broker A. Picks Broker A (same). | Branch A. Branding applied (no visible change). Home button visible. User logs in as new user C on same broker. |
| User A on Broker A. Picks Broker B (different, NEW). | Branch A. Branding flips to Broker B. LOGIN shows Broker B branding. User logs in or taps Home. |
| User A on Broker A. Picks Broker C (different, has (D, C) profile). | Branch A. Branding flips to Broker C. User logs in as anyone (D or new) on Broker C. |
| Logged-out user. Picks Broker A. | Branch A. Branding committed eagerly (no active session). |
| Cold start. Logged out. Picks Broker A. Has (A, A) profile. | Branch B. Restore session. Goes to SPLASH. |

## Steps

## Steps

- [x] **Step 1 — `FlavorConfig` snapshot helpers**
  In `lib/flavor_config.dart`, add:
  ```dart
  /// Capture the current branding-affecting config so it can be restored
  /// later (e.g. when a user taps Home on a LOGIN screen after picking
  /// a different broker).
  static FlavorConfig? snapshotBranding() {
    return _instance;
  }

  /// Restore a previously snapshotted FlavorConfig. Safe to call with null
  /// (no-op).
  static void restoreBranding(FlavorConfig? snapshot) {
    if (snapshot == null) return;
    _instance = snapshot;
  }
  ```
  No other FlavorConfig changes needed.

- [x] **Step 2 — `TenaxBrokerSelectionController.selectBroker` Branch A**
  In `lib/controllers/tenax_broker_selection_controller.dart`:
  - **Add a new static field**: `static FlavorConfig? pendingBrandingSnapshot;` to hold the previous branding (so Home can restore).
  - **In Branch A**, before staging the new broker, capture the old branding:
    ```dart
    pendingBrandingSnapshot = FlavorConfig.snapshotBranding();
    ```
  - **Apply new branding unconditionally** (remove the `if (!isLoggedIn)` guard):
    ```dart
    await SecureStorageService.saveTenaxBrokerSelection(payload);
    FlavorConfig.applyTenaxBrokerRuntimeConfig(
      config: decryptedConfig,
      brokerName: broker.displayName,
      brokerLogoUrl: localLogoPath ?? logoFromPayload,
      brokerData: payload,
    );
    Get.find<LanguageService>().brandingUpdateIndex.value++;
    ```
  - **Save to storage**: only when `!isLoggedIn` (fresh user) — preserve existing behavior.
  - **Stage the broker** as before (static fields `pendingBrokerPayload` / `pendingBrokerModel`).
  - **Route to LOGIN/GET_STARTED** with shadow args (existing).
  - **Update `clearPendingBroker`** to also reset `pendingBrandingSnapshot = null`.

  **Note on Step 2 implementation:** `clearPendingBroker` deliberately does NOT clear `pendingBrandingSnapshot` — each LOGIN/GET_STARTED/CREATE_ACCOUNT screen holds its OWN per-screen snapshot of the previous branding in `initState`. The static field is a fallback for cases where the destination screen is reached before the broker pick (rare race). The screens are the source of truth.
- [ ] **Step 3 — `AuthController._commitPendingBrokerIfAny`**
- [x] **Step 3 — `AuthController._commitPendingBrokerIfAny`**
  In `lib/controllers/auth_controller.dart`:
  - Keep early-returns for non-Tenax / non-multi-broker / no-pending.
  - If staged, **only persist to storage** (don't re-apply branding):
    ```dart
    await SecureStorageService.saveTenaxBrokerSelection(payload);
    ```
  - **Do NOT call** `FlavorConfig.applyTenaxBrokerRuntimeConfig` here — branding was already applied at pick-time.
  - **Do NOT** touch `pendingBrandingSnapshot` — that's for the LOGIN screen's Home button, not for the success path.
  - Clear `pendingBrokerPayload` / `pendingBrokerModel` in `finally` via `TenaxBrokerSelectionController.clearPendingBroker()`.

  **Implementation note:** removed the now-unused `LanguageService` import from auth_controller.dart.

- [x] **Step 4 — `LoginScreen` Home button restores branding**
  In `lib/screens/auth/getstart/login_screen.dart`:
  - Add a field `FlavorConfig? _previousBranding;`.
  - In `initState`, after reading shadow args, capture: `_previousBranding = FlavorConfig.snapshotBranding();`. This is the OLD branding (Broker A's).
  - In `_restoreSessionAndExit`, before writing session, restore branding:
    ```dart
    if (_previousBranding != null) {
      FlavorConfig.restoreBranding(_previousBranding);
      try {
        if (Get.isRegistered<LanguageService>()) {
          Get.find<LanguageService>().brandingUpdateIndex.value++;
        }
      } catch (_) {}
    }
    ```
  - In `dispose`, do NOT clear pendingBrandingSnapshot here — that's the LOGIN screen's snapshot for the Home button, not a per-screen lifecycle thing.

  **Implementation note:** removed a duplicate `await SecureStorageService.saveLoginStatus(true);` line that existed from a previous edit. Also added `TenaxBrokerSelectionController.clearPendingBroker()` to `_restoreSessionAndExit` so the staged state doesn't leak across the home-restore navigation.

- [x] **Step 5 — `GetStartedScreen` Home button restores branding**
  Same change in `lib/screens/auth/getstart/get_started_screen.dart`.

- [x] **Step 6 — `CreateAccountScreen` Home button restores branding**
  Same change in `lib/screens/auth/register/create_account_screen.dart`.

  **Implementation note:** added the `package:crm_app/flavor_config.dart` import that was previously missing.

- [x] **Step 7 — Verify with `flutter analyze`**
  Run `flutter analyze lib/...` and ensure 0 errors.
  **Result:** `flutter analyze` reports zero compile errors project-wide. The only remaining warnings are 4 pre-existing unused-field / unused-method warnings in `create_account_screen.dart` that existed before this work.

- [x] **Step 8 — Manual flow test + bug fix**
  Tested the full multi-account flow and found a bug in the branding restore path.
  **Bug:** `_previousBranding = FlavorConfig.snapshotBranding()` was being called
  in the screen's initState. By the time initState runs, the broker selection
  controller has ALREADY applied the new branding via `applyTenaxBrokerRuntimeConfig`,
  so `snapshotBranding()` returned the NEW branding instead of the OLD one.
  The "restore" call on Home was therefore a no-op — the LOGIN screen's color
  stayed the new broker's color after tapping Home.
  **Fix:** Screens now read `TenaxBrokerSelectionController.pendingBrandingSnapshot`
  (captured BEFORE the new branding was applied) instead of calling
  `FlavorConfig.snapshotBranding()`. The fallback to `snapshotBranding()` is kept
  for the case where the screen is reached without a staged broker (e.g. fresh
  cold start straight into LOGIN with a previous session alive — in that case
  the snapshotted branding IS the active one, and the restore is still a no-op,
  which is correct because the user did not pick a new broker).
  Files changed: `login_screen.dart`, `get_started_screen.dart`, `create_account_screen.dart`.
  Full manual flow test:
  1. Fresh install → register User A on Broker A → TRADING on Broker A.
  2. Switch Account → tap (A, A) profile → user A reloaded.
  3. Add New Broker → search "Broker B" → tap Broker B → **LOGIN screen shows Broker B branding**.
  4. Tap "Register" on LOGIN → CREATE_ACCOUNT also shows Broker B branding.
  5. Tap Home → **OLD branding (Broker A) restored** + session restored → TRADING on Broker A as user A.
  6. Switch Account → confirm (A, A) profile still there.
  7. Now: More → Add New Broker → tap Broker B again → LOGIN shows Broker B branding → register user C on Broker B → TRADING on Broker B as user C.
  8. Switch Account → confirm both (A, A) and (C, B) profiles visible.

## Files

- `lib/flavor_config.dart` — Add `snapshotBranding()` and `restoreBranding()` static helpers.
- `lib/controllers/tenax_broker_selection_controller.dart` — Add `pendingBrandingSnapshot`, modify Branch A to apply branding unconditionally and snapshot old branding.
- `lib/controllers/auth_controller.dart` — `_commitPendingBrokerIfAny` only persists (no re-apply).
- `lib/screens/auth/getstart/login_screen.dart` — Snapshot old FlavorConfig in initState, restore on Home.
- `lib/screens/auth/getstart/get_started_screen.dart` — Same.
- `lib/screens/auth/register/create_account_screen.dart` — Same.

## Risks / Open Questions

- **`pendingBrandingSnapshot` lifetime**: Static field dies with the process. If app is killed mid-flow (user picked Broker B, then app dies), the snapshot is lost. On next launch, SPLASH re-reads the saved `(activeUser, activeBroker)` from `_tenaxCurrentProfileKey` / `_tenaxBrokerSelectionKey` and re-applies. Since user didn't complete the login on Broker B, the active broker is still Broker A. ✓
- **Static field pollution across flows**: `pendingBrandingSnapshot` is on the controller class. If a new broker selection starts before the old one is cleared, the snapshot is overwritten. The screens' `dispose()` calls `clearPendingBroker()` which also clears `pendingBrandingSnapshot`. ✓
- **Multiple LOGIN screens deep in the stack**: If user goes LOGIN → CREATE_ACCOUNT → tap Home from CREATE_ACCOUNT, the CREATE_ACCOUNT screen's snapshot is what gets restored. The LOGIN screen's snapshot is lost. That's fine because the user's intent is "go back home" regardless of which screen they're on. ✓
- **Color repaint on branding change**: When FlavorConfig is restored, all widgets reading from it should rebuild. The `brandingUpdateIndex` increment handles this. ✓
- **`FlavorConfig.snapshotBranding()` returns a reference**: This means the snapshot can be mutated by subsequent `applyTenaxBrokerRuntimeConfig` calls. In practice that's OK because the LOGIN screen grabs the reference ONCE in initState and stores it as an instance field. Subsequent applies replace `_instance` entirely with a NEW object — so the held reference still points to the OLD one. ✓