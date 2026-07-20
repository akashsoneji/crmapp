# Card Withdrawal Method — Flutter Mobile Changes

Companion doc for the backend card-withdrawal work already merged in `crmwebadmin-devnew`. This lists the **exact** mobile-side changes needed so the app can list, add and pay out via a saved credit/debit card.

- Backend contract confirmed live in `core/app/Http/Controllers/User/FinanceController.php`:
  - Add-method (`store`) accepts `card_holder_name`, `card_brand` (`visa|mastercard`), `card_last4` (`digits:4`). **No proof image, no relationship gate.**
  - Every user-facing withdrawal endpoint now returns `card_holder_name` / `card_brand` / `card_last4` alongside the bank/upi/crypto fields.
  - Master method row: `method_name = 'card'`, seeded `inactive` — admin enables per broker. If the mobile app respects `activeMasterMethodTypes` (it does, via `/user/finance/withdrawal/methods`), the Card tab only appears where the broker has flipped it on.

PCI note: **only** `holder_name`, `brand`, `last4` are ever stored/transmitted. No PAN, no CVV, no expiry ever touches the app or the API.

---

## Files to change

| # | File | What |
|---|------|------|
| 1 | `lib/models/bank_withdralList_model.dart` | Add `cardHolderName` / `cardBrand` / `cardLast4` to `WithdrawalMethods` |
| 2 | `lib/controllers/kyc/kyc_bank_controller.dart` | New `card` category + validators + OTP/submit payload |
| 3 | `lib/screens/home/kyc/kyc_bank_screen.dart` | Card form (holder / brand dropdown / last-4), skip proof section |
| 4 | `lib/screens/home/kyc/bank_list_screen.dart` | Detail-row rendering + `_buildTitle` label for card |
| 5 | `lib/screens/home/more/finance/withdrawal_screen.dart` | Show saved cards in payout picker when method == `card` |
| 6 | `assets/translations/en.json` + `ar.json` | New `kyc_card_*` strings |

Skip: `lib/constants/api_const*.dart` — endpoint URLs unchanged.

---

## 1. Model — `lib/models/bank_withdralList_model.dart`

Extend `WithdrawalMethods` (currently at the bottom of the file). Add three optional fields alongside the crypto/upi ones:

```dart
class WithdrawalMethods {
  // ... existing fields ...
  String? cryptoNetwork;
  String? cardHolderName;   // NEW
  String? cardBrand;        // NEW — 'visa' | 'mastercard' (lowercased by backend)
  String? cardLast4;        // NEW — always 4 digits as string (preserves leading zeros)
  String? proofImg;
  // ...
}
```

Wire them in the constructor, `fromJson` (`json['card_holder_name']`, `json['card_brand']`, `json['card_last4']`) and `toJson` — mirroring how `cryptoAddress` is done. Snake_case on the JSON side, camelCase on the Dart side.

---

## 2. Controller — `lib/controllers/kyc/kyc_bank_controller.dart`

### 2a. Extend the category switch

`accountTypeCategory` (line ~126) currently maps `local|bank → bank`, `crypto → crypto`, `upi → upi`. Add `card`:

```dart
case 'card':
  return 'card';
```

### 2b. Add observables

Alongside `bankName`, `cryptoAddress`, `upiAddress`:

```dart
final cardBrand = ''.obs;   // 'visa' or 'mastercard'
final cardLast4 = ''.obs;   // exactly 4 digits
```

`accountHolderName` is reused (already exists) — no separate `cardHolderName` observable needed; matches how bank/upi reuse it.

### 2c. Validation (add a branch in the same `validate...()` method that handles bank/crypto/upi, ~line 525)

```dart
} else if (accountTypeCategory == "card") {
  if (accountHolderName.value.trim().isEmpty) {
    _showErr('Please enter cardholder name');
    return false;
  }
  // Same regex as crypto holder name (letters, spaces, - ' .)
  if (!_isValidCryptoHolderName(accountHolderName.value)) {
    _showErr('Cardholder name contains invalid characters');
    return false;
  }
  if (cardBrand.value.isEmpty) {
    _showErr('Please select card brand');
    return false;
  }
  if (!RegExp(r'^\d{4}$').hasMatch(cardLast4.value)) {
    _showErr('Enter the last 4 digits of the card');
    return false;
  }
}
```

**Do not** validate expiry, full PAN or CVV — backend rejects these fields and they must never leave the device.

### 2d. Skip proof-image requirement for card

Where the controller enforces `proofFile.value != null` (`_validateProofImage()` / equivalent), add a short-circuit near the top:

```dart
if (accountTypeCategory == 'card' || accountTypeCategory == 'local') {
  return true; // backend also skips proof for these two
}
```

Mirrors the backend guard at `FinanceController.php:236`.

### 2e. OTP / submit payload — `_buildOtpRequestParams()` (~line 635)

Add before the "common parameters" block:

```dart
if (accountTypeCategory == 'card') {
  return {
    'withdrawal_method': 'card',
    'currency': selectedCurrency.value,
    'card_holder_name': accountHolderName.value.trim(),
    'card_brand': cardBrand.value.toLowerCase(),
    'card_last4': cardLast4.value,
    // relationship intentionally omitted — backend does not require it for card
    'holder_name': accountHolderName.value.trim(),
  };
}
```

### 2f. `_getProofFieldName()` (~line 700)

Add a case so the multipart uploader doesn't crash if it's ever invoked:

```dart
case 'card':
  return 'card_proof_img'; // unused — proof is skipped for card
```

---

## 3. Add-method screen — `lib/screens/home/kyc/kyc_bank_screen.dart`

### 3a. TextEditingControllers

Alongside `_cryptoAddressController` / `_upiAddressController`:

```dart
final _cardLast4Controller = TextEditingController();
```

Dispose it in `dispose()`.

### 3b. Method-type dropdown

The dropdown at line ~410 is fed by `controller.withdrawalMethods` (from the master-methods API). No local hardcoded list — as soon as the admin flips card `active`, it appears. **No change needed here.**

### 3c. Clear-on-switch (~line 519)

Add:

```dart
cardBrand.value = '';
cardLast4.value = '';
_cardLast4Controller.clear();
```

Next to the existing `_cryptoAddressController.clear()`.

### 3d. Field builder — add a `case 'card':` in the switch at line ~537 / ~629

Render three inputs (mirror the crypto block):

1. **Cardholder name** — reuse the shared holder-name input already used by bank/upi (`onChanged: (v) => controller.accountHolderName.value = v`).
2. **Card brand** — `DropdownButtonFormField<String>` with options:
   ```dart
   items: [
     DropdownMenuItem(value: 'visa', child: Text('Visa')),
     DropdownMenuItem(value: 'mastercard', child: Text('Mastercard')),
   ],
   onChanged: (v) => controller.cardBrand.value = v ?? '',
   ```
3. **Last 4 digits**:
   ```dart
   TextField(
     controller: _cardLast4Controller,
     keyboardType: TextInputType.number,
     maxLength: 4,
     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
     onChanged: (v) => controller.cardLast4.value = v,
     decoration: InputDecoration(
       labelText: languageService.tr('kyc_card_last4'),
       hintText: '1234',
     ),
   ),
   ```

### 3e. Hide the proof-upload section

The proof block (~line 862) wraps in `final isCrypto = ...`. Extend it so card also hides it:

```dart
final skipProof = ['crypto', 'card'].contains(controller.accountTypeCategory);
if (skipProof) return const SizedBox.shrink();
```

Backend accepts submission without any proof for card — hiding is the only correct UX.

---

## 4. Saved-methods list — `lib/screens/home/kyc/bank_list_screen.dart`

### 4a. Detail rows (~line 322)

Add another `else if` after the crypto branch:

```dart
} else if (methodType == 'card') {
  if (_hasValue(method.cardBrand)) {
    detailRows.add(_buildDetailRow(
      'Card Brand',
      method.cardBrand!.toUpperCase(), // 'VISA' / 'MASTERCARD'
    ));
  }
  if (_hasValue(method.cardLast4)) {
    detailRows.add(_buildDetailRow(
      'Card Number',
      '•••• •••• •••• ${method.cardLast4}',
    ));
  }
}
```

`holderName` block below already handles the name for all methods — no duplication needed.

### 4b. Title formatter (`_buildTitle` at line ~429)

Add:

```dart
case 'card':
  final brand = (method.cardBrand ?? 'Card').toUpperCase();
  final last4 = method.cardLast4 ?? '••••';
  return '$brand •••• $last4';
```

---

## 5. Withdrawal-submit screen — `lib/screens/home/more/finance/withdrawal_screen.dart`

Currently the payout picker branches on `method == 'bank'` / `method == 'crypto'` (lines ~225–230, ~965–976). Add card:

### 5a. Method-type gate (~line 225)

```dart
} else if (method == 'card') {
  // No extra selector like "Crypto Type" — cards are picked directly.
}
```

### 5b. Selected-payment-method validation (~line 965)

```dart
if (controller.selectedPaymentMethod.value.toLowerCase() == 'card') {
  if (controller.selectedCardMethodId.value == null) {
    _validationMessage.value = 'Please select a card';
    return false;
  }
}
```

Add `final selectedCardMethodId = Rxn<int>();` to the withdrawal controller (mirror `selectedBankMethodId` / `selectedCryptoMethodId` — whichever field already exists there).

### 5c. Saved-card picker

Where the bank picker builds `bankName / accountNumber` labels (~line 1545), add an analogous card branch that lists `${method.cardBrand.toUpperCase()} •••• ${method.cardLast4} — ${method.cardHolderName}`.

If no cards saved, show the same empty-state used by bank/crypto with CTA → `bank_list_screen`.

---

## 6. Translations — `assets/translations/en.json` + `ar.json`

Add (English shown; add Arabic equivalents in `ar.json`):

```json
"kyc_card_holder_name": "Cardholder name",
"kyc_card_holder_name_hint": "Name as printed on the card",
"kyc_card_brand": "Card brand",
"kyc_card_last4": "Last 4 digits",
"kyc_card_last4_hint": "e.g. 1234",
"kyc_card_no_proof_helper": "No proof image needed — the last 4 digits identify the card.",
"withdrawal_saved_cards_empty": "No cards saved. Add a card to proceed."
```

---

## Verification checklist

- [ ] `flutter analyze` clean on the 5 touched files.
- [ ] Add-Card flow: submit with brand=Visa, last4=`0012` — row is created, list shows `VISA •••• 0012` (leading zeros preserved).
- [ ] Add-Card flow: submitting with last4=`12` or `abcd` is blocked client-side (matches backend `digits:4`).
- [ ] No proof-image field visible on the Card add screen; no crash on submit.
- [ ] Withdrawal-submit picker: Card option **absent** on a broker where admin has `card` master row `inactive` — appears the moment it's flipped `active`.
- [ ] Telegram / admin channel notification (backend side, already merged) shows brand + last4 + holder — confirmed by `FinanceController.php:2728` payload.
- [ ] Arabic build renders RTL card number correctly (unicode bullets `••••` render either way; last4 stays LTR).

---

## Out of scope (do NOT bundle in this task)

- Gateway payout driver mapping — a broker-specific driver that pushes the payout to Visa/Mastercard rails is a backend job. Mobile only surfaces the saved reference.
- Editing an existing card — no edit flow for bank/crypto/upi either; keeping parity. Delete + re-add is the flow.
- Card image / logo per brand — nice-to-have; not required for functional parity with bank/upi.
