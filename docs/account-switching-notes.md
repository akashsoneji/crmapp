# Account Switching Notes

## Current (before changes)
- Entry points: `widgets/account_header_widget.dart` bottom sheet uses `AccountController.setActiveMT5Account`; `screens/home/dashboard_screen.dart` account card trade button calls the same. Both rely on `DashboardController.changePrimaryAccount` API.
- Endpoint selection: `WebSocketEndpointHelper` returns MT5 vs self-hosted endpoints and caches the primary account; cache is set via `setPrimaryAccount` in `AccountController.updateMT5Accounts`, cleared in `AccountController.setActiveMT5Account`.
- Websocket services:
  - Trading WS (`services/trading_websocket_service.dart`): chooses endpoint per tab using `WebSocketEndpointHelper.get*Endpoint`; tracks `_currentEndpoint` but does not log old/new on switch.
  - Account WS (`services/account_websocket_service.dart`): listens to `activeMT5AccountRx`; forces endpoint switch when type changes but lacks explicit old/new URL logging.
  - Instruments WS (`controllers/instruments_controller.dart`): uses `getMarketWatchUrl`; reconnects when account changes; no old/new URL logging.
  - Chart WS (`controllers/chart_socket_controller.dart`): recomputes endpoint on account change; logs only endpoint change flag.
- State clearing: `TradingController.clearAllTradingData` exists; `DashboardController.clearAllData` clears `accountInfoMap`; switching accounts does not clear all trading/dashboard caches consistently before reconnect.
- Gap observed: When switching MT5 vs self-hosted, endpoint helper cache may not be updated with the new primary account before websockets reconnect; old URLs can persist, and there is no consolidated logging of old→new URLs or cache wipes.

## Desired
- On account switch from header or dashboard: log old vs new URLs per websocket, disconnect old sockets, wipe cached JSON/state (trading data, accountInfo map), set new endpoint URLs, reconnect and resubscribe, and confirm MT5 vs self-hosted URL swap via debug output.

## After changes (current)
- Account switching now snapshots endpoints per socket (trading open/pending/market watch/symbol + account WS) and logs old→new URLs when switching accounts in `AccountController.setActiveMT5Account`.
- WebSocketEndpointHelper cache is cleared then set to the new primary account during switch to avoid stale endpoints; trading/dashboard cached data is cleared before reconnect.
- Trading WS, Account WS, and Instruments WS log endpoint transitions (prev→new) when connecting; Instruments WS resets tracked URL on disconnect.
- Switch flow disconnects old sockets, clears cached data, then reconnects and resubscribes using the new URLs while emitting debug lines for verification.
