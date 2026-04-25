# Auth Test Cases (Login / Register / OTP / Forgot Password)

This document is aligned to the current Flutter implementation in this repo (GetX routes + `AuthController` + `OtpModal`).

## Implemented user flows (from code)

### Login (Email + Password)
- **Screen**: `lib/screens/auth/getstart/login_screen.dart`
- **Fields**: email (regex), password (min length 6)
- **Actions**
  - Login → `AuthController.login(email, password, enableBiometricAfterLogin)`
  - Forgot password → route `AppPages.FORGOT_PASSWORD`
  - Register → route `AppPages.CREATE_ACCOUNT`
- **Biometric**
  - Optional checkbox “enable biometric after login”
  - Auto biometric prompt on login screen startup if biometric enabled + token exists

### Register (Create Account → Legal Documents → OTP verification)
- **Screens**:
  - `lib/screens/auth/register/create_account_screen.dart`
  - `lib/screens/auth/register/legal_documents_screen.dart`
  - OTP UI: `lib/widgets/otp_modal.dart`
- **Flow**
  - Create Account → navigates to Legal Documents with `registrationData`
  - Legal Documents “Submit” triggers `AuthController.register(data)`
  - On registration success → opens OTP modal (email verification) → verify OTP → `AuthController.registerWithOTPVerification(...)` → `AppPages.ACCOUNT_CREATED`
- **Field rules (current UI validation)**
  - Required: first name, last name, phone (non-empty), email (regex), password (min length 6)
  - Legal documents checkbox must be checked to submit

### Forgot Password (Request OTP → Verify Code → Create New Password)
- **Screens**:
  - `lib/screens/auth/password/forgot_password_screen.dart`
  - `lib/screens/auth/password/verify_code_screen.dart` (6-digit OTP)
  - `lib/screens/auth/password/create_new_password_screen.dart` (password min length 8)
- **Flow**
  - Forgot password: Send OTP → `AuthController.requestPasswordResetOTP(email)`
  - Verify code: Verify → `AuthController.verifyPasswordResetOTP(email, otp)` → navigates to Create New Password with `{email, otp}`
  - Create new password: Submit → `AuthController.resetPasswordWithOTP(...)` → navigates to `AppPages.LOGIN`
- **Resend**
  - Verify Code “Resend” calls `requestPasswordResetOTP` again
  - No client-side cooldown timer is implemented in `VerifyCodeScreen` (server may still rate limit)

## Important observations (affects test expectations)

- **Login identifier is email** (no phone login in `LoginScreen`).
- **Password min length differs**:
  - Login/Register UI: **>= 6**
  - Reset password UI: **>= 8**
- **OTP length is inconsistent for registration**:
  - `CreateAccountScreen` opens `OtpModal(otpLength: 5)` in its own (older) flow
  - `LegalDocumentsScreen` opens `OtpModal` with **6** (current completion path)
  - Forgot-password OTP screen is **6**
- **Verify Code screen supports paste** (first field can accept 6 digits and distributes across boxes).
- **Biometric login path exists**:
  - If biometric enabled + token present: login screen may auto-prompt biometric and navigate to Trading on success.

---

## Test cases

### A) Login (Email + Password)

- **TC-L01 Valid login (email + password)**
  - Steps: Enter valid email + correct password → Tap Login
  - Expected: Loader shown; login success; user navigates to `AppPages.TRADING`; session/token saved

- **TC-L02 Invalid email format**
  - Steps: Enter `abc` in email → any password → Login
  - Expected: Validation error (email invalid); login not called

- **TC-L03 Empty email**
  - Steps: Keep email empty → Login
  - Expected: “email required” validation; login not called

- **TC-L04 Empty password**
  - Steps: Keep password empty → Login
  - Expected: “password required” validation; login not called

- **TC-L05 Password < 6**
  - Steps: Enter valid email + password length 1–5 → Login
  - Expected: Validation error for min length; login not called

- **TC-L06 Wrong credentials (server rejects)**
  - Steps: Enter valid email + wrong password → Login
  - Expected: Error toast shown (API message or fallback); stays on login

- **TC-L07 Trim input**
  - Steps: Enter ` user@example.com ` + ` pass123 ` → Login
  - Expected: Trimming occurs; behavior correct (success/failure matches trimmed values)

- **TC-L08 Login button disabled while loading**
  - Steps: Tap Login; immediately tap again
  - Expected: Button disabled; no duplicate requests

- **TC-L09 Forgot password navigation**
  - Steps: Tap “Forgot password”
  - Expected: Navigates to `AppPages.FORGOT_PASSWORD`

- **TC-L10 Register navigation**
  - Steps: Tap “Register”
  - Expected: Navigates to `AppPages.CREATE_ACCOUNT`

#### Biometric (Login Screen)

- **TC-LB01 Enable biometric after login (supported + enrolled + user approves)**
  - Preconditions: Device supports biometrics; biometrics enrolled
  - Steps: Check “enable biometric after login” → login successfully → approve biometric prompt
  - Expected: Biometric enabled saved; future app launches can use biometric entry

- **TC-LB02 Enable biometric after login (not enrolled)**
  - Preconditions: Device supports biometrics but no enrollment
  - Steps: Check “enable biometric…” checkbox
  - Expected: Dialog shown; checkbox resets to false

- **TC-LB03 Auto biometric prompt on app open**
  - Preconditions: `biometric_enabled=true`, token exists
  - Steps: Open login screen
  - Expected: Biometric prompt appears; on success navigates to Trading; on cancel stays on login

---

### B) Register (Create Account → Legal Docs → OTP)

- **TC-R01 Create account form required fields**
  - Steps: Leave first/last/phone/email/password empty → try to proceed
  - Expected: Form cannot proceed / validation messages shown

- **TC-R02 Email regex validation**
  - Steps: Enter invalid email → proceed
  - Expected: Email validation error

- **TC-R03 Password min length 6**
  - Steps: Enter password length 1–5 → proceed
  - Expected: Validation error

- **TC-R04 Phone required (non-empty)**
  - Steps: Leave phone empty → proceed
  - Expected: Validation error (required)

- **TC-R05 Successful navigation to Legal Documents**
  - Steps: Fill required fields → Next
  - Expected: Navigates to `LegalDocumentsScreen` with registration payload

- **TC-R06 Legal agreement gating**
  - Steps: On legal documents screen, do not check agreement → Submit
  - Expected: Submit disabled / no API call

- **TC-R07 Registration API success triggers OTP modal**
  - Steps: Check agreement → Submit (server success)
  - Expected: OTP modal opens for email verification

- **TC-R08 OTP verify success completes registration**
  - Steps: Enter correct OTP → Verify
  - Expected: OTP accepted; navigates to `AppPages.ACCOUNT_CREATED`

- **TC-R09 OTP invalid / incomplete**
  - Steps: Enter fewer digits than required by modal → Verify
  - Expected: Client-side error (“Please enter a valid N-digit OTP”); no verify call

- **TC-R10 Resend OTP from modal**
  - Steps: Tap Resend
  - Expected: OTP fields cleared and focus returns to first field; resend handler called (if wired)

- **TC-R11 Duplicate email / already registered**
  - Steps: Register with already-used email
  - Expected: Error toast shown; remains in flow; no account-created navigation

---

### C) Forgot Password (Request OTP → Verify Code → New Password)

#### Forgot Password Screen

- **TC-F01 Email validation (current rule: contains '@')**
  - Steps: Enter `abc` → Send OTP
  - Expected: Validation error (invalid email)

- **TC-F02 Empty email**
  - Steps: Empty → Send OTP
  - Expected: “enter your email” validation error

- **TC-F03 Request OTP success navigates to Verify Code**
  - Steps: Enter valid email → Send OTP (server success)
  - Expected: Toast success; navigates to `AppPages.VERIFY_CODE` with email argument

- **TC-F04 Request OTP failure**
  - Steps: Enter valid email → Send OTP (server error)
  - Expected: Error toast; stays on same screen

#### Verify Code Screen (6 digits)

- **TC-VO01 Verify OTP success**
  - Steps: Enter 6-digit OTP → Verify
  - Expected: Toast success; navigates to `AppPages.CREATE_NEW_PASSWORD` with `{email, otp}`

- **TC-VO02 Verify button disabled until 6 digits**
  - Steps: Enter 1–5 digits
  - Expected: Verify disabled

- **TC-VO03 Paste full OTP**
  - Steps: Paste 6 digits into first box
  - Expected: Distributed into all boxes; verify enabled

- **TC-VO04 Resend code (no UI cooldown)**
  - Steps: Tap “Resend Code?” multiple times quickly
  - Expected: App sends multiple requests (client allows); server may rate limit; app handles “too many requests” gracefully if returned

#### Create New Password Screen

- **TC-NP01 New password required**
  - Steps: Leave new password empty → Submit
  - Expected: “Password is required”

- **TC-NP02 New password min length 8**
  - Steps: Enter 1–7 chars → Submit
  - Expected: “at least 8 characters”

- **TC-NP03 Confirm password mismatch**
  - Steps: New password != confirm → Submit
  - Expected: “Passwords do not match”

- **TC-NP04 Reset password success**
  - Steps: Enter valid new password + confirm → Submit (server success)
  - Expected: Toast success; navigates to `AppPages.LOGIN`; old password no longer works

- **TC-NP05 Reset password failure**
  - Steps: Submit (server error, invalid/expired OTP)
  - Expected: Error toast; stays on screen; user can retry

---

### D) Non-functional / reliability (recommended)

- **TC-NF01 Offline behavior (login)**
  - Steps: Disable internet → attempt login
  - Expected: Friendly error; no crash; loading stops

- **TC-NF02 App relaunch with biometric enabled + token present**
  - Steps: Close app → reopen to login screen
  - Expected: Auto biometric prompt; on success proceeds to Trading

- **TC-NF03 Error messages from server are surfaced**
  - Steps: Trigger known server errors (invalid otp, user not found, too many requests)
  - Expected: Toast shows server-provided message when available

