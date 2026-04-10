# CopyTrading API — Mobile Developer Reference

> **Base URL:** `{DOMAIN}/api`
> **Auth:** Bearer Token (`Authorization: Bearer {token}`) — required on all `/user/` endpoints.
> **Response shape:** All endpoints return `{ "status": true|false, "message": "...", "data": ... }`

---

## Table of Contents

1. [App Flow Overview](#app-flow-overview)
2. [Public Endpoints (No Auth)](#public-endpoints-no-auth)
3. [Master (Trader) Endpoints](#master-trader-endpoints)
4. [Copier (Investor) Endpoints](#copier-investor-endpoints)
5. [Full Payload Reference](#full-payload-reference)
6. [Error Codes & Validation Rules](#error-codes--validation-rules)

---

## App Flow Overview

```
USER
 │
 ├── [Leaderboard / Browse Masters]
 │     GET /api/copytrading/masters              ← Public, no auth needed
 │     GET /api/copytrading/masters/{code}       ← Public master profile
 │
 ├── [COPIER FLOW]
 │     1. GET  /api/user/copytrading/copier/eligible-accounts    → pick account
 │     2. GET  /api/user/copytrading/copier/masters/{code}       → confirm plan
 │     3. POST /api/user/copytrading/copier/subscribe            → subscribe
 │     4. GET  /api/user/copytrading/copier/subscriptions        → my subscriptions
 │     5. GET  /api/user/copytrading/copier/subscriptions/{id}/detail
 │     6. GET  /api/user/copytrading/copier/subscriptions/{id}/trades
 │     7. GET  /api/user/copytrading/copier/subscriptions/{id}/pnl-history
 │     8. POST /api/user/copytrading/copier/subscriptions/{id}/add-capital
 │     9. POST /api/user/copytrading/copier/subscriptions/{id}/pause
 │    10. POST /api/user/copytrading/copier/subscriptions/{id}/resume
 │    11. POST /api/user/copytrading/copier/subscriptions/{id}/stop
 │
 └── [MASTER FLOW]
       1. GET  /api/user/copytrading/master/status               → check if already applied
       2. POST /api/user/copytrading/master/apply                → become a master
       3. GET  /api/user/copytrading/master/dashboard-stats      → dashboard numbers
       4. GET  /api/user/copytrading/master/plans                → my plans list
       5. POST /api/user/copytrading/master/plans                → create plan
       6. GET  /api/user/copytrading/master/plans/{id}           → plan detail
       7. GET  /api/user/copytrading/master/plans/{id}/copiers   → who is copying me
       8. GET  /api/user/copytrading/master/plans/{id}/open-positions
       9. GET  /api/user/copytrading/master/plans/{id}/trades
      10. POST /api/user/copytrading/master/plans/{id}/inactivate
      11. GET  /api/user/copytrading/master/commissions
      12. GET  /api/user/copytrading/master/commissions/export   → CSV blob
```

---

## Public Endpoints (No Auth)

### 1. Get Leaderboard / All Masters

```
GET /api/copytrading/masters
```

**Query Params (all optional):**

| Param | Type | Description |
|---|---|---|
| `search` | string | Filter by nickname |
| `sort` | string | `aum`, `copiers`, `gain` |

**Response `data` (array of masters):**

```json
[
  {
    "master_code": "MCT-XXXX",
    "master_nickname": "The Scalper",
    "master_name": "The Scalper",
    "server_type": "mt5",
    "plan_count": 2,
    "total_copiers": 14,
    "total_aum": 45000.00,
    "strategy_description": "...",
    "risk_score": null,
    "total_gain": 12.5,
    "active_days": 45,
    "win_rate": 68.3,
    "is_enrolled": false,
    "approved_plans": [
      {
        "id": 3,
        "plan_id": 3,
        "plan_name": "Scalp Pro",
        "commission_type": "per_trade",
        "commission_label": "5% per trade",
        "commission_percentage": 5.0,
        "minimum_capital": 100.0,
        "active_copiers_count": 8,
        "total_aum": 24000.00,
        "is_full": false,
        "no_fee_days": 7,
        "subscription_period_days": 30
      }
    ]
  }
]
```

---

### 2. Get Public Master Profile

```
GET /api/copytrading/masters/{master_code}
```

**Response `data`:**

```json
{
  "master_code": "MCT-XXXX",
  "master_nickname": "The Scalper",
  "master_name": "The Scalper",
  "server_type": "mt5",
  "strategy_description": "...",
  "risk_information": "...",
  "risk_score": null,
  "total_plans": 2,
  "approved_plans": [ /* same shape as leaderboard */ ],
  "pending_plans": []
}
```

---

## Master (Trader) Endpoints

> All require `Authorization: Bearer {token}`

### 3. Get Master Application Status

```
GET /api/user/copytrading/master/status
```

**Response `data`:**

```json
{
  "status": "pending",      // null | "pending" | "approved" | "rejected"
  "master_code": "MCT-XXXX" // null if not approved yet
}
```

**Screen logic:**
- `null` → Show "Become a Master" button
- `"pending"` → Show "Application Under Review"
- `"approved"` → Show Master Dashboard
- `"rejected"` → Show "Contact Support"

---

### 4. Apply as Master Trader

```
POST /api/user/copytrading/master/apply
```

**Request Body:**

```json
{
  "mt5_account_id": 12,
  "nickname": "The Scalper",
  "terms_accepted": 1,
  "strategy": "Optional strategy description",
  "risk_info": "Optional risk description"
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `mt5_account_id` | integer | ✅ | Must belong to user |
| `nickname` | string | ✅ | Max 100 chars, public name |
| `terms_accepted` | integer | ✅ | Must be `1` (accepted) |
| `strategy` | string | ❌ | Max 2000 chars |
| `risk_info` | string | ❌ | Max 2000 chars |

**Response `data`:**

```json
{
  "status": "pending",
  "master_code": "MCT-XXXX"
}
```

---

### 5. Get Master Dashboard Stats

```
GET /api/user/copytrading/master/dashboard-stats
```

**Response `data`:**

```json
{
  "plans_count": 3,
  "active_copiers_count": 14,
  "total_aum": 45200.00,
  "commission_earned": 2310.50
}
```

---

### 6. Get My Plans (List)

```
GET /api/user/copytrading/master/plans
```

**Response `data` (array):**

```json
[
  {
    "id": 3,
    "plan_name": "Scalp Pro",
    "trading_account_number": "****1234",
    "trading_server": "mt5.broker.com",
    "lp_provider_name": "ICMarkets",
    "server_type": "mt5",
    "commission_type": "per_trade",
    "commission_label": "5% per trade",
    "commission_percentage": 5.0,
    "subscription_fee": 0.0,
    "minimum_capital": 100.0,
    "copy_ratio": 1.0,
    "max_copiers": 50,
    "active_copiers_count": 8,
    "total_capital": 24000.00,
    "is_full": false,
    "status": "approved",
    "created_at": "2025-01-15T10:00:00Z"
  }
]
```

**Plan `status` values:** `pending_admin` | `approved` | `inactive` | `rejected`

---

### 7. Create New Plan

```
POST /api/user/copytrading/master/plans
```

**Request Body:**

```json
{
  "trading_account_id": 12,
  "name": "Scalp Pro",
  "commission_type": "per_trade",
  "commission_value": 5,
  "min_capital": 100,
  "max_copiers": 50,
  "no_fee_days": 7,
  "copy_ratio": 1.0,
  "take_profit_pips": 20,
  "stop_loss_pips": 10,
  "strategy_description": "Optional",
  "risk_info": "Optional",
  "subscription_fee": 0,
  "subscription_period": "30"
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `trading_account_id` | integer | ✅ | Must match master's server type |
| `name` | string | ✅ | Max 100 chars, unique per master |
| `commission_type` | string | ✅ | `per_trade` or `subscription` |
| `commission_value` | number | ✅ | `per_trade` → % (0-100); `subscription` → flat fee |
| `min_capital` | number | ❌ | Minimum copier capital in USD |
| `max_copiers` | integer | ❌ | Max concurrent copiers |
| `no_fee_days` | integer | ❌ | Grace period days (0 = no grace) |
| `copy_ratio` | number | ❌ | Default `1.0` |
| `take_profit_pips` | number | ❌ | Master default TP in pips |
| `stop_loss_pips` | number | ❌ | Master default SL in pips |
| `subscription_fee` | number | ❌ | Only for `subscription` type |
| `subscription_period` | string | ❌ | Days: `"7"`, `"30"`, `"90"` or `"weekly"`, `"monthly"`, `"quarterly"` |

**Response `data`:** Same as plan object above (status = `pending_admin`)

---

### 8. Get Plan Detail

```
GET /api/user/copytrading/master/plans/{id}
```

**Response `data`:**

```json
{
  "id": 3,
  "plan_name": "Scalp Pro",
  "server_type": "mt5",
  "commission_type": "per_trade",
  "commission_percentage": 5.0,
  "subscription_fee": 0.0,
  "subscription_period_days": 30,
  "no_fee_days": 7,
  "minimum_capital": 100.0,
  "copy_ratio": 1.0,
  "max_copiers": 50,
  "is_full": false,
  "total_capital": 24000.00,
  "active_copiers": 8,
  "total_commission_earned": 2310.50,
  "open_positions": 3,
  "status": "approved",
  "take_profit_pips": 20.0,
  "stop_loss_pips": 10.0,
  "trade_history": [
    {
      "id": 101,
      "symbol": "EURUSD",
      "direction": "buy",
      "master_volume": 1.0,
      "copier_volume": 0.1,
      "open_price": 1.08150,
      "close_price": 1.08250,
      "open_time": "2025-03-01T09:00:00Z",
      "close_time": "2025-03-01T11:30:00Z",
      "status": "closed",
      "master_profit": 100.0,
      "copier_profit": 10.0,
      "copier_account": "****5678",
      "copier_name": "John D"
    }
  ],
  "commission_history": [
    {
      "id": 55,
      "settled_at": "2025-03-01T11:30:00Z",
      "symbol": "EURUSD",
      "copier_account": "****5678",
      "gross_profit_share": 10.0,
      "commission_charged": 0.50,
      "master_commission_credited": 0.50,
      "in_grace_period": false,
      "status": "settled"
    }
  ]
}
```

---

### 9. Get Plan Copiers

```
GET /api/user/copytrading/master/plans/{id}/copiers
```

**Query Params (optional):**

| Param | Type | Default |
|---|---|---|
| `page` | integer | 1 |
| `per_page` | integer | 15 |
| `status` | string | all |
| `search` | string | — |

---

### 10. Get Plan Open Positions

```
GET /api/user/copytrading/master/plans/{id}/open-positions
```

---

### 11. Get Plan Trade History

```
GET /api/user/copytrading/master/plans/{id}/trades
```

**Query Params:** `page`, `per_page`

---

### 12. Inactivate Plan

```
POST /api/user/copytrading/master/plans/{id}/inactivate
```

> Only works if plan is `approved` AND `active_copiers_count = 0`

**Response `data`:** `{ "status": "inactive" }`

---

### 13. Get Commission History

```
GET /api/user/copytrading/master/commissions
```

**Query Params (optional):**

| Param | Type | Example |
|---|---|---|
| `from_date` | string (Y-m-d) | `2025-01-01` |
| `to_date` | string (Y-m-d) | `2025-03-31` |

---

### 14. Export Commissions CSV

```
GET /api/user/copytrading/master/commissions/export
```

**Query Params:** Same as above  
**Response:** Binary CSV blob (save as file)

---

## Copier (Investor) Endpoints

### 15. Browse Available Masters (Authenticated)

```
GET /api/user/copytrading/copier/masters
```

Same shape as public leaderboard but `is_enrolled` reflects actual user state.

---

### 16. Get Master Profile (Authenticated)

```
GET /api/user/copytrading/copier/masters/{master_code}
```

---

### 17. Get Eligible Accounts

```
GET /api/user/copytrading/copier/eligible-accounts
```

**Query Params (optional):**

| Param | Type | Description |
|---|---|---|
| `plan_id` | integer | Filter accounts compatible with this plan |

**Response `data` (array):**

```json
[
  {
    "id": 12,
    "meta_account_number": "****1234",
    "account_type": "live",
    "balance": 5000.00,
    "equity": 5120.00,
    "trading_server": "mt5.broker.com",
    "lp_provider_name": "ICMarkets",
    "server_type": "mt5",
    "is_enrolled": false,
    "subscriptions": [
      {
        "id": 7,
        "plan_id": 3,
        "plan_name": "Scalp Pro",
        "master_code": "MCT-XXXX",
        "master_nickname": "The Scalper",
        "status": "active",
        "is_active": true
      }
    ]
  }
]
```

> **Note:** Only `live` accounts are returned. Demo accounts cannot subscribe.

---

### 18. Subscribe to a Plan

```
POST /api/user/copytrading/copier/subscribe
```

**Request Body:**

```json
{
  "master_code": "MCT-XXXX",
  "plan_id": 3,
  "mt5_account_id": 12,
  "investment_amount": 1000,
  "copying_method": "proportional",
  "fixed_lot_size": null,
  "lot_multiplier": 1,
  "overrides_sl_tp": false
}
```

**With TP/SL Override (Pip Mode):**

```json
{
  "master_code": "MCT-XXXX",
  "plan_id": 3,
  "mt5_account_id": 12,
  "investment_amount": 1000,
  "copying_method": "proportional",
  "overrides_sl_tp": true,
  "sl_tp_mode": "pip",
  "take_profit_pips": 20,
  "stop_loss_pips": 10
}
```

**With TP/SL Override (Dollar Mode):**

```json
{
  "master_code": "MCT-XXXX",
  "plan_id": 3,
  "mt5_account_id": 12,
  "investment_amount": 1000,
  "copying_method": "proportional",
  "overrides_sl_tp": true,
  "sl_tp_mode": "dollar",
  "take_profit_dollar": 50,
  "stop_loss_dollar": 25
}
```

**With Fixed Lot Size:**

```json
{
  "master_code": "MCT-XXXX",
  "plan_id": 3,
  "mt5_account_id": 12,
  "investment_amount": 1000,
  "copying_method": "fixed",
  "fixed_lot_size": 0.10
}
```

**Full Field Reference:**

| Field | Type | Required | Notes |
|---|---|---|---|
| `master_code` | string | ✅ | From master profile |
| `plan_id` | integer | ✅ | Must be `approved` plan |
| `mt5_account_id` | integer | ✅ | Must be `live` account, belongs to user |
| `investment_amount` | number | ✅ | Min $1, cannot exceed account equity, >= plan minimum_capital |
| `copying_method` | string | ✅ | `proportional` or `fixed` |
| `fixed_lot_size` | number | ✅ if fixed | Min 0.01 |
| `lot_multiplier` | number | ❌ | Default `1`, min 0.01, max 100 (proportional only) |
| `overrides_sl_tp` | boolean | ❌ | Default `false`. If `true`, must provide at least one TP or SL |
| `sl_tp_mode` | string | ❌ | `pip` (default) or `dollar`. Used only when `overrides_sl_tp: true` |
| `take_profit_pips` | number | ❌ | Pip mode only. Min 1, max 10000 |
| `stop_loss_pips` | number | ❌ | Pip mode only. Min 1, max 10000 |
| `take_profit_dollar` | number | ❌ | Dollar mode only. Min 0.01, max 100000 |
| `stop_loss_dollar` | number | ❌ | Dollar mode only. Min 0.01, max 100000 |
| `copy_open_trades` | boolean | ❌ | Default `false` |

**Response `data`:**

```json
{
  "id": 88,
  "status": "active",
  "plan_id": 3,
  "plan_name": "Scalp Pro",
  "master_code": "MCT-XXXX",
  "master_nickname": "The Scalper"
}
```

---

### 19. Get My Subscriptions

```
GET /api/user/copytrading/copier/subscriptions
```

**Response `data` (array):**

```json
[
  {
    "id": 88,
    "plan_id": 3,
    "plan_name": "Scalp Pro",
    "master_name": "The Scalper",
    "master_code": "MCT-XXXX",
    "server_type": "mt5",
    "account_number": "****1234",
    "capital_amount": 1000.00,
    "copy_ratio": 1.0,
    "copy_method": "proportional",
    "total_pnl": 125.50,
    "total_commission_paid": 6.28,
    "open_trades": 2,
    "status": "active",
    "active_since": "2025-03-01T09:00:00Z",
    "subscription_started_at": "2025-03-01T09:00:00Z"
  }
]
```

**`status` values:** `active` | `paused` | `stopped`

---

### 20. Get Subscription Detail

```
GET /api/user/copytrading/copier/subscriptions/{id}/detail
```

**Response `data`:**

```json
{
  "subscription": {
    "id": 88,
    "plan_id": 3,
    "plan_name": "Scalp Pro",
    "master_name": "The Scalper",
    "master_code": "MCT-XXXX",
    "commission_type": "per_trade",
    "commission_percentage": 5.0,
    "account_number": "****1234",
    "capital_amount": 1000.00,
    "copy_ratio": 1.0,
    "copy_method": "proportional",
    "fixed_lot_size": null,
    "no_fee_until": "2025-03-08T09:00:00Z",
    "in_grace_period": true,
    "total_pnl": 125.50,
    "total_commission_paid": 6.28,
    "open_trades_count": 2,
    "closed_trades_count": 18,
    "status": "active",
    "active_since": "2025-03-01T09:00:00Z",
    "paused_at": null,
    "take_profit_pips": 20.0,
    "stop_loss_pips": 10.0
  },
  "pnl_history": [
    {
      "id": 55,
      "symbol": "EURUSD",
      "gross_profit_share": 10.0,
      "commission_charged": 0.50,
      "net_credited": 9.50,
      "in_grace_period": false,
      "status": "settled",
      "settled_at": "2025-03-01T11:30:00Z"
    }
  ]
}
```

---

### 21. Get Copied Trades

```
GET /api/user/copytrading/copier/subscriptions/{id}/trades
```

**Query Params:** `page` (default 1), `per_page` (default 15, max 100)

**Response `data`:**

```json
{
  "data": [
    {
      "id": 101,
      "symbol": "EURUSD",
      "trade_type": "buy",
      "master_volume": 1.0,
      "copier_volume": 0.1,
      "open_price": 1.08150,
      "close_price": 1.08250,
      "open_time": "2025-03-01T09:00:00Z",
      "close_time": "2025-03-01T11:30:00Z",
      "master_profit": 100.0,
      "copier_profit": 10.0,
      "commission_charged": 0.50,
      "net_credited": 9.50,
      "status": "closed"
    }
  ],
  "total": 18,
  "current_page": 1,
  "per_page": 15,
  "total_pages": 2
}
```

---

### 22. Get P&L History

```
GET /api/user/copytrading/copier/subscriptions/{id}/pnl-history
```

**Query Params:** `page`, `per_page`

**Response `data`:**

```json
{
  "data": [
    {
      "id": 55,
      "symbol": "EURUSD",
      "trade_type": "buy",
      "gross_profit_share": 10.0,
      "commission_charged": 0.50,
      "net_credited": 9.50,
      "commission_percentage": 5.0,
      "in_grace_period": false,
      "status": "settled",
      "settled_at": "2025-03-01T11:30:00Z"
    }
  ],
  "total": 18,
  "current_page": 1,
  "per_page": 20,
  "total_pages": 1
}
```

---

### 23. Add Capital

```
POST /api/user/copytrading/copier/subscriptions/{id}/add-capital
```

**Request Body:**

```json
{ "amount": 500 }
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `amount` | number | ✅ | Min 1, cannot exceed account equity |

**Response `data`:**

```json
{ "new_capital": 1500.00 }
```

---

### 24. Pause Subscription

```
POST /api/user/copytrading/copier/subscriptions/{id}/pause
```

> Subscription must be `active`

**Response `data`:** `{ "status": "paused" }`

---

### 25. Resume Subscription

```
POST /api/user/copytrading/copier/subscriptions/{id}/resume
```

> Subscription must be `paused`

**Response `data`:** `{ "status": "active" }`

---

### 26. Stop Subscription

```
POST /api/user/copytrading/copier/subscriptions/{id}/stop
```

> Subscription must be `active` or `paused`. This is **permanent** — cannot re-activate, only re-subscribe.

**Response `data`:** `{}`

---

## Full Payload Reference

### Subscribe Payload (Complete)

```json
{
  "master_code": "MCT-XXXX",
  "plan_id": 3,
  "mt5_account_id": 12,
  "investment_amount": 1000.00,
  "copying_method": "proportional",
  "fixed_lot_size": null,
  "lot_multiplier": 2,
  "copy_open_trades": false,
  "overrides_sl_tp": true,
  "sl_tp_mode": "pip",
  "take_profit_pips": 20,
  "stop_loss_pips": 10,
  "take_profit_dollar": null,
  "stop_loss_dollar": null
}
```

### Apply as Master Payload (Complete)

```json
{
  "mt5_account_id": 12,
  "nickname": "The Scalper",
  "terms_accepted": 1,
  "strategy": "I scalp major pairs during London session.",
  "risk_info": "Moderate risk. Max 2% per trade."
}
```

### Create Plan Payload (Complete)

```json
{
  "trading_account_id": 12,
  "name": "Scalp Pro",
  "commission_type": "per_trade",
  "commission_value": 5,
  "subscription_fee": 0,
  "subscription_period": "30",
  "no_fee_days": 7,
  "min_capital": 100,
  "copy_ratio": 1.0,
  "max_copiers": 50,
  "take_profit_pips": 20,
  "stop_loss_pips": 10,
  "strategy_description": "Optional strategy text",
  "risk_info": "Optional risk text"
}
```

---

## Error Codes & Validation Rules

### HTTP Status Codes

| Code | Meaning |
|---|---|
| `200` | Success (`status: true`) |
| `200` | Failure with business error (`status: false`, `message` explains why) |
| `422` | Validation error — `errors` object contains field-level messages |
| `401` | Unauthenticated |
| `404` | Resource not found |

### Common Error Messages

| Scenario | Message |
|---|---|
| Terms not accepted | `"The terms accepted field is required."` |
| Account not found | `"Trading account not found or does not belong to you."` |
| Server type mismatch | `"This plan requires a mt5 account. Your account is self_hosted."` |
| Demo account | `"Demo accounts cannot subscribe to copy trading plans."` |
| Plan full | `"This plan has reached its maximum copiers limit."` |
| Already subscribed | `"You already have an active subscription to this plan with this account."` |
| Insufficient balance | `"Insufficient available balance."` |
| Below minimum capital | `"Minimum capital is {X}."` |
| No TP/SL set but override on | `"At least one of TP or SL is required when overriding master TP/SL."` |
| Own plan subscription | `"You cannot subscribe to your own plan using the master trading account."` |
| Plan not approved | `"Plan not found or not approved."` |

### TP/SL Dollar Mode Logic

When `sl_tp_mode = "dollar"`, the trade engine converts dollar target → pips at order open using live price:

```
pips = dollar_amount / (lot_size × pip_value)
```

- EURUSD: pip_value = $10 per lot
- USDJPY: pip_value = ~$6.5 per lot  
- XAUUSD: pip_value = $100 per lot

---

## Screen-by-Screen API Mapping

| Screen | APIs to Call |
|---|---|
| **Leaderboard** | `GET /api/copytrading/masters` |
| **Master Profile** | `GET /api/copytrading/masters/{code}` |
| **Subscribe Drawer — Step 1** | `GET /api/user/copytrading/copier/eligible-accounts?plan_id=X` |
| **Subscribe Drawer — Step 2** | (local form, no extra API) |
| **Subscribe Confirm** | `POST /api/user/copytrading/copier/subscribe` |
| **My Copies (Copier Dashboard)** | `GET /api/user/copytrading/copier/subscriptions` |
| **Copy Detail** | `GET .../subscriptions/{id}/detail` |
| **Trade History** | `GET .../subscriptions/{id}/trades?page=1&per_page=15` |
| **P&L History** | `GET .../subscriptions/{id}/pnl-history` |
| **Add Capital** | `POST .../subscriptions/{id}/add-capital` |
| **Pause/Resume/Stop** | `POST .../subscriptions/{id}/pause|resume|stop` |
| **Master Dashboard** | `GET .../master/status` + `GET .../master/dashboard-stats` + `GET .../master/plans` |
| **Plan Detail** | `GET .../master/plans/{id}` |
| **Plan Copiers** | `GET .../master/plans/{id}/copiers` |
| **Commission History** | `GET .../master/commissions` |
| **Become Master** | `POST .../master/apply` |
| **Create Plan** | `POST .../master/plans` |
