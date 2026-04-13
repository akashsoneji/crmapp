# Feature inventory (pre-migration)

This file is a **working map** of the current codebase into a **feature-first Clean Architecture** target shape (`lib/features/*` + `lib/core/*`).

It is intended to help with the “move all files feature-wise” migration without breaking flows.

## Source of truth for navigation

- **Routes**: `lib/routes/app_pages.dart`, `lib/routes/app_routes.dart`
- **More menu**: `lib/screens/home/more/more_screen.dart`

## Proposed feature folders (target)

### `auth`
- **Screens**: `lib/screens/auth/**`
  - splash/get-started/login/register/password flows
  - broker selection screens: `lib/screens/auth/broker/**` (Tenax)
- **Controller**: `lib/controllers/auth_controller.dart`
- **Service**: `lib/services/auth_service.dart`

### `tenax_broker` (or `broker_selection`)
- **Screens**: `lib/screens/auth/broker/tenax_broker_selection_screen.dart`, `tenax_broker_info_screen.dart`
- **Controller**: `lib/controllers/tenax_broker_selection_controller.dart`
- **Service**: `lib/services/tenax_broker_service.dart`
- **Storage**: `lib/services/secure_storage_service.dart` (Tenax keys)
- **Branding runtime apply**: `lib/flavor_config.dart` (`applyTenaxBrokerRuntimeConfig`)

### `trading`
- **Screens**: `lib/screens/home/trading_main_screen.dart`, `order_confirmation_screen.dart`, `chart_screen.dart` (and related trading UI)
- **Controllers**: `lib/controllers/trading_controller.dart`, `chart_controller.dart`, `chart_socket_controller.dart`, `instruments_controller.dart`, `chart_notification_controller.dart`
- **Services**:
  - websocket: `lib/services/trading_websocket_service.dart`, `account_websocket_service.dart`, `unified_websocket_service.dart`, `websocket_endpoint_helper.dart`
  - market helpers/caches: `lib/services/symbol_selection_service.dart`, `symbol_details_cache_service.dart`

### `account` (and/or `profile`)
- **Controllers**: `lib/controllers/account_controller.dart`, `change_password_controller.dart`, `create_trading_account_controller.dart`, `wallet_controller.dart`
- **Service**: `lib/services/account_service.dart`
- **Screens**: `lib/screens/home/change_password_screen.dart`, `lib/screens/home/open_account_screen.dart`, `lib/screens/home/choose_account_screen.dart`, `lib/screens/home/create_crm_app_account_screen.dart`
- **Profile UI**: `lib/screens/home/more/edit_profile_screen.dart` + controller `lib/controllers/more/edit_profile_controller.dart`

### `finance`
- **Screens**: `lib/screens/home/more/finance/**`
- **Controllers**: `lib/controllers/finance/**`
- **Services**: finance-related calls currently mixed in screens/controllers; will become `data/datasources/*`

### `kyc`
- **Screens**: `lib/screens/home/kyc/**` and `lib/screens/home/more/kyc_verification_screen.dart`
- **Controllers**: `lib/controllers/kyc_controller.dart`, `lib/controllers/kyc/**`

### `pmam` (required feature flag candidate)
- **Routes**: PMAM routes in `lib/routes/app_routes.dart` and pages in `lib/routes/app_pages.dart`
- **Menu entry**: PMAM item in `lib/screens/home/more/more_screen.dart`
- **Screens**: `lib/screens/home/more/pmam/**`
- **Controllers**: `lib/controllers/pmam/pmam_controller.dart`, `lib/controllers/pmam/pmam_manager_plan_detail_controller.dart`
- **Service**: `lib/services/pmam_service.dart`

### `copy_trading`
There are two areas today:
- **Main Copy Trading**: `lib/screens/copy_trading/**` + controllers `lib/controllers/copy_trading/**`
- **More → Copytrading hub**: `lib/screens/home/more/copytrading/**` + controller(s) in `lib/controllers/copy_trading/**`

### `ib` (IB dashboard / partnership)
- **Screens**: `lib/screens/home/more/ib_dashboard/**`, `lib/screens/home/more/partnership_program_screen.dart`
- **Controller**: `lib/controllers/ib_controller.dart`

### `bonus`
- **Screens**: `lib/screens/home/more/bonus/**`

### `demo_contest`
- **Screens**: `lib/screens/home/more/demo_contest/**`

### `support`
- **Screens**: `lib/screens/home/more/support/**`, `lib/screens/home/more/chat_with_us_screen.dart`
- **Controller**: `lib/controllers/chat_with_us_controller.dart`

### `settings`
- **Screens**: `lib/screens/home/more/setting/setting_screen.dart`, `lib/screens/settings/**`
- **Service**: `lib/services/theme_service.dart`, `lib/services/language_service.dart`

### `notifications`
- **Controllers**: `lib/controllers/app_notification_controller.dart`
- **Services**: `lib/services/notification_service.dart`, `lib/services/price_alert_service.dart`, `price_alert_monitor_service.dart`

### `one_click_trading`
- **Service**: `lib/services/one_click_trading_service.dart`, `one_click_trading_queue_service.dart`
- **UI entry**: `lib/screens/home/more/more_screen.dart` (toggle item)
- **Disclaimer screen**: `lib/screens/home/more/one_click_trading_disclaimer_screen.dart`

## Candidates for `lib/core/*` (shared)
- **Network**: `lib/services/api_service.dart` (legacy), `lib/services/api_service_client.dart` (adapter), `lib/core/network/*` (new), `lib/services/http_client_service.dart`
- **Storage**: `lib/services/secure_storage_service.dart`
- **App status overlays**: `lib/services/app_status/**`
- **Connectivity**: `lib/services/connectivity/**`
- **Loading/toast**: `lib/services/loading_service.dart`, `lib/services/toast_service.dart`, plus shared widgets

