# Account Selection Flow - Implementation Summary

## Problem Statement
Previously, when navigating from Dashboard → Payment Gateway Selection → Deposit Screen, the system would automatically select the first account (default/primary) in the deposit screen, ignoring which account was selected in the dashboard.

## Solution Implemented
Modified the navigation flow to pass the selected account number through all screens, ensuring the account chosen in the dashboard is pre-selected in the deposit screen.

## Changes Made

### 1. **PaymentMethodsScreen** (`lib/screens/home/more/finance/payment_methods_screen.dart`)
- **Line 96-103**: Updated navigation to `DepositRealScreen` to include `preselectedAccountNumber` parameter
- Now passes `widget.accountNumber` (received from dashboard) to the next screen

```dart
Get.to(
  () => DepositRealScreen(
    object: method,
    preselectedAccountNumber: widget.accountNumber,  // NEW
  ),
);
```

### 2. **DepositRealScreen** (`lib/screens/home/more/finance/deposit_real_screen.dart`)
- **Line 16-24**: Added optional `preselectedAccountNumber` parameter to the widget
- **Line 58-63**: Updated `initState()` to pass the preselected account number to the controller

```dart
class DepositRealScreen extends StatefulWidget {
  final Map<String, dynamic> object;
  final String? preselectedAccountNumber;  // NEW

  const DepositRealScreen({
    super.key,
    required this.object,
    this.preselectedAccountNumber,  // NEW
  });
```

### 3. **DepositController** (`lib/controllers/finance/deposit_controller.dart`)
- **Line 92-157**: Modified `fetchAccountsForPaymentMethod()` to accept optional `preselectedAccountNumber` parameter
- **Line 143-154**: Added logic to find and select the matching account based on the preselected account number
- If preselected account is found, it's selected; otherwise, falls back to first account

```dart
Future<void> fetchAccountsForPaymentMethod(
  String slug, {
  String? preselectedAccountNumber,  // NEW PARAMETER
}) async {
  // ... fetch accounts logic ...
  
  // NEW SELECTION LOGIC
  if (mt5Accounts.isNotEmpty) {
    if (preselectedAccountNumber != null && preselectedAccountNumber.isNotEmpty) {
      // Try to find the preselected account
      final matchingAccount = mt5Accounts.firstWhere(
        (account) => account['meta_account_number'].toString() == preselectedAccountNumber,
        orElse: () => mt5Accounts.first,
      );
      selectedTransferAccount.value = matchingAccount;
    } else {
      // Auto-select first account
      selectedTransferAccount.value = mt5Accounts.first;
    }
  }
}
```

## Flow Diagram

```
Dashboard
  ↓ (User selects account: "5013314")
  ↓ onDepositRealAccount("5013314")
  ↓
PaymentMethodsScreen (accountNumber: "5013314")
  ↓ (User selects payment gateway)
  ↓ Navigate with preselectedAccountNumber: "5013314"
  ↓
DepositRealScreen (preselectedAccountNumber: "5013314")
  ↓ initState()
  ↓ fetchAccountsForPaymentMethod(slug, preselectedAccountNumber: "5013314")
  ↓
DepositController
  ↓ Fetches available accounts from API
  ↓ Searches for account matching "5013314"
  ↓ Selects matching account (or first if not found)
  ↓
Deposit Screen displays with correct account pre-selected ✓
```

## Testing
To test the implementation:
1. Open the app and navigate to Dashboard
2. Select a specific account (e.g., "5013314")
3. Tap "Deposit" on that account
4. Select a payment gateway
5. **Verify**: The deposit screen should show "5013314" pre-selected in the "Deposit to" field
6. If you select a different account in dashboard, that account should be pre-selected instead

## Backward Compatibility
- The changes are backward compatible
- If `preselectedAccountNumber` is not provided (null or empty), the system falls back to selecting the first account
- Existing code that doesn't pass the account number will continue to work as before
