# Port wallet history redesign + finance-activity API to crmapp

## Goal
Bring the whitelabel Wallet screen work into the separate `crmapp` repo (`/Users/akash/Desktop/Soneji Infotech/xelthio/app/crmapp`, branch `staging`): wallet history from `GET user/finance-activity`, the new compact design, the anchored filter popup, the coloured status tabs, wallet auto-select in Internal Transfer, and the build-phase and stale-response fixes.

## Approach
- **Port the changes, don't copy files.** crmapp has a different layout: no `FinanceRepository`, a static `ApiService.get`, and different paths. Each change is re-applied in crmapp's own style. The reference implementation is whitelabel `lib/screens/finance/presentation/pages/wallet_screen.dart` and `lib/screens/wallet/view_models/wallet_controller.dart` as they are now.
- **API:** call `finance-activity` directly through `ApiService.get`, with the same query params whitelabel's `FinanceRepository.getTransactions` sends: `page`, `perPage=10`, `transactionType=''`, `includeTraderTransfers=1`, `dateFrom`, `dateTo`, `type=''`, `status=''`, `_t`. All values are Strings, because `Uri` rejects ints. That was the earlier crash.
- **Leave other screens alone.** crmapp's Transaction History screen keeps using `user/transactions`. Only the wallet history moves to the new API.
- **Missing colours:** crmapp's `AppColors` has no `onPrimary` or `textFieldBg`. Use `Colors.white` on primary, which matches what the current crmapp screen already does, and `AppColors.surface` for the tab and field background. `color.dart` is not touched.
- **Missing i18n keys:** add the missing keys to all 5 crmapp languages (`ar`, `en`, `es`, `hi`, `tr`). Existing keys are reused wherever they are present.
- **Order:** controller first (screen depends on it), then screen, transfer screen, translations, then analyze.

## Steps
- [x] 1. **API constant.** In `crmapp/lib/constants/api_const.dart`, add `static const String getFinanceActivity = '${ajax}finance-activity';` next to `getWalletDetailsNew` (line 87). Keep `getTransactions`, because other screens use it.
- [x] 2. **Controller state.** In `crmapp/lib/controllers/wallet_controller.dart`, replace the history state block at lines 263-276:
  - Remove `historyTransactions`, `filterType`, `filterStatus` and `totalItems`. Their only users are this controller and the wallet screen; the matches in other files are unrelated symbols with the same name.
  - Add `_historyPerPage = 10`, `_historyRequestId`, `completedTransactions`, `pendingTransactions`, `rejectedTransactions`, `selectedHistoryTab`, and the `visibleHistoryTransactions` getter.
  - Keep `filterDateFrom`, `filterDateTo`, `currentPage`, `lastPage`, `hasMore`, `isLoadingMore` and `isHistoryLoading`.
- [x] 3. **Controller fetch.** Rewrite `fetchWalletHistory` (line 632 onward) to match whitelabel:
  - Call `ApiService.get(endpoint: ApiConstants.getFinanceActivity, ...)` with the String params above.
  - Use the request-id staleness guard.
  - Read `pagination.current_page` and `last_page`.
  - Split rows into the three tabs client-side.
  - Port these helpers: `_toInt`, `_clearHistoryLists`, `_fillVisibleTab`, `selectHistoryTab`, `loadMoreTransactions`, `applyFilters`, `clearFilters`.
  - Remove the `print('DEBUG: …')` lines in the rewritten method.
- [x] 4. **Build-phase guard.** Add `_waitForBuildToFinish()` plus `import 'package:flutter/scheduler.dart';`. Await it at the top of `fetchWalletData()` (line 572) and `fetchWalletHistory()`.
- [x] 5. **Models.** Append `enum WalletHistoryTab` and `class WalletHistoryEntry` (with `fromFinanceActivity`, `isCredit` and `tab`) at the end of the controller file. Leave the existing `Data` class alone; it is still referenced by the old JSON model in the same file.
- [x] 6. **Wallet screen, build.** In `crmapp/lib/screens/home/more/finance/wallet_screen.dart`, port whitelabel's `build()`:
  - Compact header sliver.
  - Pinned `SliverPersistentHeader` with extent `54.h`, or `54.h + 38.h` when a date chip is shown.
  - Loading and empty states that also cover "tab empty while later pages load".
  - Date-grouped `SliverList` and a footer that works on every tab.
  - Keep crmapp's existing app bar, refresh and processing-overlay pieces as they are today.
- [x] 7. **Wallet screen, widgets.** Replace these crmapp methods: `_buildPremiumBalanceCard` (228), `_buildQuickActions` (384), `_buildActionButton` (415), `_buildFilterBar` (464), `_showFilterBottomSheet` (632) and `_buildFilterDropdownWidget` (909). Port these whitelabel methods in their place:
  - `_buildWalletHeader`, `_buildHeaderAction`
  - `_buildHistoryControls`, `_tabVisual`, `_buildStatusSegmentedControl`, `_buildSquareIconButton`
  - `_showFilterPopup`, `_pickDate`, `_buildDateField`
  - `_groupByDay`, `_buildTransactionGroup`, `_buildTransactionTile`
  - `_formatSignedAmount`, `_formatDate`, `_statusColors`, `_typeVisual`, `_buildStatusBadge`
  - `_showTransactionDetails`, `_buildDetailRow`, `_buildFilterChip`
  - the `_PinnedControlsDelegate` class

  Then delete `_buildTransactionCard(dynamic)` (946), and drop the now-unused `flutter_svg` and `url_launcher` imports.
- [x] 8. **Colour substitutions.** In the ported screen code, use `Colors.white` for `AppColors.onPrimary` and `AppColors.surface` for `AppColors.textFieldBg`.
- [x] 9. **Internal Transfer.** In `crmapp/lib/screens/home/more/finance/internal_transfer_screen.dart`:
  - Add a `preselectWallet` flag (default `false`) to the constructor at line 38.
  - Add `_preselectWalletAsSource()`, which selects the wallet as From and the first MT5 as To.
  - In `_fetchData` (line 96), branch on the flag. The `addPostFrameCallback` there already exists.
  - The wallet screen's transfer action passes `preselectWallet: true`. Other callers (`dashboard_screen.dart`, `ibm_main_shell.dart`, `app_pages.dart`) stay unchanged.
- [x] 10. **Translations.** Add only the keys that are missing in `crmapp/assets/translations/{ar,en,es,hi,tr}.json`: `wallet_history_current_balance`, `wallet_history_completed_hint`, `wallet_screen_date_range`, `ibm_transaction_details`, `order_history_screen_reason`, plus any other key the ported code uses that a grep shows is absent. Copy values from whitelabel for `ar`, `en` and `es`. Write fresh `hi` and `tr` translations. Insert each key next to an existing `wallet_*` key, and verify that only additions show in `git diff`.
- [x] 11. **Verify.**
  - Run `flutter analyze` inside crmapp on the 4 edited Dart files, with zero errors.
  - Grep crmapp `lib/` for `historyTransactions|filterType.value|filterStatus` in wallet code; expect zero matches.
  - Check that `_t`, `page` and `perPage` are sent as Strings.
  - Report the remaining manual device checks: the filter popup, tabs, Internal Transfer pre-select, and the URL containing `dateFrom`/`dateTo`.

## Files
- `crmapp/lib/constants/api_const.dart`: add the `getFinanceActivity` endpoint.
- `crmapp/lib/controllers/wallet_controller.dart`: new history state, finance-activity fetch, build-phase guard, `WalletHistoryEntry`/`WalletHistoryTab`.
- `crmapp/lib/screens/home/more/finance/wallet_screen.dart`: compact design, tabs, filter popup, grouped list.
- `crmapp/lib/screens/home/more/finance/internal_transfer_screen.dart`: `preselectWallet` flag and wallet auto-select.
- `crmapp/assets/translations/{ar,en,es,hi,tr}.json`: missing keys only.

## Risks / Open questions
- **Backend support is unverified.** I have not confirmed that crmapp's backend (`FlavorConfig.apiBaseUrl` per flavour) serves `user/finance-activity` with the same response shape (`data[]` and `pagination`). If a flavour's backend lacks it, that flavour's wallet history will show empty. Check one flavour's log after the change.
- **Date-filter param names are assumed.** The backend accepting `dateFrom`/`dateTo` was not confirmed in whitelabel either.
- **Copy-trading wallet is out of scope.** crmapp has a second, separate `lib/screens/copy_trading/settings/wallet_screen.dart` that is not touched. Say so if it should get the design too.
- **Hindi and Turkish strings are machine-written.** They are new and should get a native-speaker review.
- **Edits are outside this workspace.** crmapp is a separate git repo. Nothing will be committed; the changes are left as uncommitted edits on `staging` for you to review.
