## PMAM API – Manager & Investor Flows

This document describes the main **PMAM (Percent Allocation Money Management)** APIs exposed by `crmwebadmin` for:

- **Managers**: create plans, see investors, stats, withdrawals.
- **Investors**: browse plans, join/leave, deposits, P&L.
- **Trade Engine**: internal callbacks for trade-open / trade-close / partial-close.

Base API URL (frontend): all user-facing routes are under:

- `https://<crm-domain>/api/user/...` (Laravel `auth:sanctum`)

Internal trade engine callbacks:

- `https://<crm-domain>/api/internal/...` (protected by `verify.trade.engine`)

---

### Common Response Envelope

Most PMAM endpoints use a common JSON shape via `apiResponse()`:

```json
{
  "message": "Human readable message",
  "success": true,
  "data": { ... },           // or [] for lists
  "status_code": 200         // HTTP status is also set accordingly
}
```

Below examples omit `status_code` field when not critical.

---

## 1. Manager APIs

All manager APIs are prefixed with:

- `GET/POST /api/user/pmam/manager/...`

### 1.1 Get Manager Status

**Route**

- `GET /api/user/pmam/manager/status`

**Description**

Return current user's PMAM manager application status.

**Response**

```json
{
  "message": "Manager status retrieved",
  "success": true,
  "data": {
    "status": "approved",          // pending | approved | rejected | inactive
    "manager_code": "MG1234"
  }
}
```

If no application:

```json
{
  "message": "No manager application found",
  "success": true,
  "data": null
}
```

---

### 1.2 Apply as Manager

**Route**

- `POST /api/user/pmam/manager/apply`

**Request Body**

```json
{
  "terms_accepted": true
}
```

Validation:

- `terms_accepted` must be `true` (`accepted` rule).
- User must **not** be an IB (`user_role_type !== 'ib'`).
- User must not have an existing `pending` or `approved` manager record.

**Success Response**

```json
{
  "message": "Manager application submitted successfully.",
  "success": true,
  "data": {
    "status": "pending"
  }
}
```

**Error Responses (examples)**

- User is IB:

```json
{
  "message": "IB partners cannot become PMAM managers. Roles are mutually exclusive.",
  "success": false,
  "data": [],
  "status_code": 422
}
```

- Existing application:

```json
{
  "message": "You already have an active manager application.",
  "success": false,
  "data": [],
  "status_code": 422
}
```

---

### 1.3 Create PMAM Plan

**Route**

- `POST /api/user/pmam/manager/plans`

**Request Body**

```json
{
  "trading_account_id": 123,           // MT5Account.id owned by manager
  "plan_name": "Gold Swing Strategy",
  "commission_percentage": 20,         // 0–100
  "minimum_investment": 1000,
  "strategy_description": "Swing trading XAUUSD on H1/H4.",
  "risk_information": "High risk. Max DD 30%."
}
```

**Behaviour**

- Requires an **approved** `PmamManager` for current user.
- Validates that `trading_account_id` belongs to manager.
- Uses manager account balance as initial `manager_own_fund`.
- Sets plan status:
  - `approved` if `manager.auto_approve_plans === true`
  - otherwise `pending_admin`.
- If auto-approved, triggers `TradeEngineClient::notifyPmamCacheRefresh()` so trade engine sees plan immediately.

**Success Response**

```json
{
  "message": "Plan created and automatically approved.",
  "success": true,
  "data": {
    "id": 10,
    "status": "approved"
  }
}
```

or (when admin approval required):

```json
{
  "message": "Plan submitted for admin approval.",
  "success": true,
  "data": {
    "id": 11,
    "status": "pending_admin"
  }
}
```

---

### 1.4 Get Manager Plans

**Route**

- `GET /api/user/pmam/manager/plans`

**Response (data = array of plans)**

```json
{
  "message": "Plans retrieved",
  "success": true,
  "data": [
    {
      "id": 10,
      "plan_name": "Gold Swing Strategy",
      "trading_account_id": 123,
      "trading_account_number": "70001234",
      "commission_percentage": 20,
      "minimum_investment": 1000,
      "strategy_description": "Swing trading XAUUSD on H1/H4.",
      "status": "approved",
      "active_investors": 5,
      "total_locked": 25000.0,            // sum(invested_amount)
      "total_investor_equity": 27000.0,   // invested + total_pnl
      "pool_balance": 30000.0,            // manager MT5 balance
      "manager_own_fund": 3000.0,         // pool_balance - total_investor_equity (or stored override)
      "created_at": "2026-03-10T09:15:32.000000Z"
    }
  ]
}
```

---

### 1.5 Inactivate Plan

**Route**

- `POST /api/user/pmam/manager/plans/{planId}/inactivate`

**Description**

Set plan to `inactive`. Only allowed if:

- Plan is `approved`, and
- Either no active investors **or** active investors' AUM `< 0.01`.

**Success Response**

```json
{
  "message": "Plan inactivated successfully.",
  "success": true,
  "data": {
    "status": "inactive"
  }
}
```

**Error Example (still active investors with AUM)**

```json
{
  "message": "Cannot inactivate: plan has 3 active investor(s) with $12000.00 AUM.",
  "success": false,
  "data": {
    "active_investors": 3,
    "total_aum": 12000.0
  },
  "status_code": 422
}
```

---

### 1.6 Manager Dashboard Stats

**Route**

- `GET /api/user/pmam/manager/dashboard-stats`

**Response**

```json
{
  "message": "Dashboard stats retrieved",
  "success": true,
  "data": {
    "total_plans": 2,
    "active_investors": 8,
    "pending_requests": 3,
    "total_locked_aum": 42000.0,
    "total_lots_traded": 135.4321,
    "total_pnl": 3500.25,
    "total_commission": 700.5,
    "commission_this_month": 120.0,
    "recent_commissions": [
      {
        "investor_name": "John Doe",
        "plan_id": 10,
        "gross_profit_share": 150.0,
        "commission_charged": 30.0,
        "net_profit_credited": 120.0,
        "settled_at": "2026-03-10T18:15:00.000000Z"
      }
    ]
  }
}
```

---

### 1.7 Investor Requests (Manager View)

#### 1.7.1 List Pending Requests

**Route**

- `GET /api/user/pmam/manager/plans/{planId}/investor-requests`

**Response**

`data` is an array of `PmamInvestor` records (status = `pending`) with user + account relations:

```json
{
  "message": "Investor requests retrieved",
  "success": true,
  "data": [
    {
      "id": 101,
      "investor_user_id": 55,
      "pmam_plan_id": 10,
      "invested_amount": 5000.0,
      "status": "pending",
      "created_at": "2026-03-10T10:00:00.000000Z",
      "user": {
        "id": 55,
        "first_name": "Alice",
        "last_name": "Trader",
        "email": "alice@example.com"
      },
      "investor_account": {
        "id": 2001,
        "meta_account_number": "70005678",
        "balance": 8000.0,
        "pmam_locked_amount": 0.0
      }
    }
  ]
}
```

> Exact nested fields depend on Eloquent serialization, but this is the typical structure.

#### 1.7.2 Approve Investor Request

**Route**

- `POST /api/user/pmam/manager/investor-requests/{id}/approve`

**Description (side‑effects)**

For the selected `PmamInvestor` (status `pending`):

1. Validates that the current user is the plan manager.
2. Caps `invested_amount` to **available balance**:
   - `availableBalance = investorAccount.balance - investorAccount.pmam_locked_amount`.
3. **Step 1 – Lock**: increments `pmam_locked_amount` on investor MT5 account by `amount`.
4. **Step 2 – Deposit to pool**: calls trade engine `depositAccount` to increase manager's pool account balance.
5. Updates manager pool `balance` + `equity` and marks balance updated via `SyncController`.
6. Marks investor:
   - `status = 'active'`
   - `active_since = now()`
7. Creates `PmamInvestorFundEntry` of type `subscribe`.
8. Notifies trade engine to reload account & refresh PMAM cache.

**Success Response**

```json
{
  "message": "Investor request approved. Account locked and funds deposited into pool.",
  "success": true,
  "data": []
}
```

**Error Example (no available balance)**

```json
{
  "message": "Investor account has no available balance to lock.",
  "success": false,
  "data": [],
  "status_code": 422
}
```

#### 1.7.3 Reject Investor Request

**Route**

- `POST /api/user/pmam/manager/investor-requests/{id}/reject`

**Response**

```json
{
  "message": "Investor request rejected.",
  "success": true,
  "data": []
}
```

---

### 1.8 Plan Detail (Manager View)

**Route**

- `GET /api/user/pmam/manager/plans/{planId}/detail`

**Response (simplified)**

```json
{
  "message": "Plan detail retrieved",
  "success": true,
  "data": {
    "plan": {
      "id": 10,
      "plan_name": "Gold Swing Strategy",
      "total_aum": 42000.0,
      "total_pnl": 3500.0,
      "total_commission": 700.0,
      "active_investors": 8,
      "commission_pct": 20
    },
    "withdrawable": 3000.0,
    "can_withdraw": true,
    "withdraw_message": null,
    "investors": [
      {
        "id": 101,
        "investor_user_id": 55,
        "investor_name": "Alice Trader",
        "investor_email": "alice@example.com",
        "status": "active",
        "active_since": "2026-03-10T11:00:00.000000Z",
        "inactive_since": null,
        "invested_amount": 5000.0
      }
    ],
    "unique_investors": [
      {
        "user_id": 55,
        "investor_name": "Alice Trader",
        "investor_email": "alice@example.com"
      }
    ]
  }
}
```

`withdrawable` = max(0, pool MT5 balance − total investor capital).

---

## 2. Investor APIs

All investor APIs are prefixed with:

- `GET/POST /api/user/pmam/investor/...`

### 2.1 List Available Plans

**Route**

- `GET /api/user/pmam/investor/plans`

**Description**

Return all **approved + visible** PMAM plans with basic info: manager, min investment, performance summary (implementation in controller below the excerpt).

**Typical Response Example**

```json
{
  "message": "Plans retrieved",
  "success": true,
  "data": [
    {
      "id": 10,
      "plan_name": "Gold Swing Strategy",
      "manager_name": "Fund Manager A",
      "commission_percentage": 20,
      "minimum_investment": 1000,
      "total_aum": 42000.0,
      "total_pnl": 3500.0,
      "active_investors": 8,
      "status": "approved"
    }
  ]
}
```

---

### 2.2 Get Eligible Accounts

**Route**

- `GET /api/user/pmam/investor/eligible-accounts`

**Description**

Return MT5 live accounts of investor that can be used for PMAM (e.g. correct group, not already fully locked).

**Typical Response**

```json
{
  "message": "Eligible accounts retrieved",
  "success": true,
  "data": [
    {
      "id": 2001,
      "meta_account_number": "70005678",
      "balance": 8000.0,
      "pmam_locked_amount": 1000.0,
      "currency": "USD"
    }
  ]
}
```

---

### 2.3 Request Join (Subscribe)

**Route**

- `POST /api/user/pmam/investor/request-join`

**Request Body (typical)**  
Exact field names depend on controller implementation further down, but in practice:

```json
{
  "plan_id": 10,
  "investor_account_id": 2001,
  "amount": 5000.0
}
```

**Response**

```json
{
  "message": "Join request submitted.",
  "success": true,
  "data": {
    "id": 101,
    "status": "pending"
  }
}
```

Manager then uses the manager APIs above to approve or reject.

---

### 2.4 Deposit (Add Funds)

**Route**

- `POST /api/user/pmam/investor/deposit`

**Request Body**

```json
{
  "pmam_investor_id": 101,
  "amount": 2000.0
}
```

**Behaviour (conceptual)**

- Creates a new `PmamInvestorFundEntry` of type `deposit`.
- Moves funds from investor MT5 account into manager pool (via trade engine).
- Updates `invested_amount` and `pmam_locked_amount`.

**Success Response**

```json
{
  "message": "Deposit added successfully.",
  "success": true,
  "data": {}
}
```

---

### 2.5 Unsubscribe

**Route**

- `POST /api/user/pmam/investor/unsubscribe/{id}`

Where `{id}` is the `PmamInvestor.id`.

**Behaviour (high level)**

- Triggers unsubscribe process (may involve partial closes via trade engine).
- Once all allocations are closed, `finalizeUnsubscribe`:
  - Returns principal + net P&L to investor MT5 account.
  - Decrements `pmam_locked_amount`.
  - Marks investor `inactive`.

**Response**

```json
{
  "message": "Unsubscribe request accepted.",
  "success": true,
  "data": {}
}
```

---

### 2.6 P&L History / Fund Entries / Open Allocations

**Routes**

- `GET /api/user/pmam/investor/pnl-history`
- `GET /api/user/pmam/investor/my-fund-entries`
- `GET /api/user/pmam/investor/my-open-allocations`

**Examples (simplified)**

P&L history:

```json
{
  "message": "P&L history retrieved",
  "success": true,
  "data": [
    {
      "trade_id": 123456,
      "gross_profit_share": 150.0,
      "commission_charged": 30.0,
      "net_profit_credited": 120.0,
      "settled_at": "2026-03-10T18:15:00.000000Z"
    }
  ]
}
```

Fund entries:

```json
{
  "message": "My fund entries retrieved",
  "success": true,
  "data": [
    {
      "id": 1,
      "amount": 5000.0,
      "type": "subscribe",
      "type_label": "Subscribe",
      "entry_time": "2026-03-10T11:00:00.000000Z",
      "status": "active"
    }
  ]
}
```

Open allocations:

```json
{
  "message": "My open allocations retrieved",
  "success": true,
  "data": [
    {
      "id": 1001,
      "position_id": 987654,
      "trade_symbol": "XAUUSD",
      "trade_type": 0,
      "allocated_lot": 0.12,
      "allocation_percentage": 0.075,
      "open_price": 5195.63,
      "open_time": "2026-03-10T20:15:00.000000Z",
      "status": "open"
    }
  ]
}
```

---

## 3. Internal Trade Engine APIs

All internal callbacks are under:

- `POST /api/internal/pmam/...`

Protected by `verify.trade.engine` middleware (shared secret / header).

### 3.1 Trade Opened

**Route**

- `POST /api/internal/pmam/trade-opened`

**Body**

```json
{
  "position_id": 987654,
  "trade_id": 123456,
  "manager_account": "70001234",   // MT5 account number OR internal ID (fallback)
  "symbol": "XAUUSD",
  "volume": 120000,                // base units; if <100 → treated as lots × 10000
  "open_price": 5195.63,
  "open_time": "2026-03-10T18:15:00Z",
  "trade_type": 0,                 // 0=Buy, 1=Sell
  "pool_equity": 45000.0           // optional: manager pool equity snapshot
}
```

**Success Response**

```json
{
  "success": true,
  "message": "Allocations calculated for trade 123456"
}
```

If no active plan is found for `manager_account`:

```json
{
  "success": false,
  "message": "No active PMAM plan for this account"
}
```

**Side‑effects**

- Resolves `PmamPlan` by `manager_account` (meta_account_number or ID).
- Calls `PmamAllocationService::calculateAllocations(...)` to:
  - Lock plan,
  - Compute total AUM,
  - Create `PmamTradeAllocation` rows with snapshots.

---

### 3.2 Trade Closed

**Route**

- `POST /api/internal/pmam/trade-closed`

**Body**

```json
{
  "position_id": 987654,
  "trade_id": 123456,
  "manager_account": "70001234",
  "close_price": 5205.63,
  "close_time": "2026-03-10T20:15:00Z",
  "total_profit": 600.0,
  "swap": -10.0,            // optional
  "pool_balance": 45600.0   // optional: pool balance snapshot
}
```

**Success Response**

```json
{
  "success": true,
  "message": "Profit distribution queued for trade 123456"
}
```

**Side‑effects**

- Dispatches `DistributeProfitJob`:
  - Calls `PmamAllocationService::distributeProfit(...)`.
  - For each open allocation:
    - Computes `gross_profit_share`, `commission_charged`, `net_profit_credited`.
    - Creates `PmamProfitDistribution`.
    - Updates `PmamInvestor.total_pnl` and `MT5Account.pmam_locked_amount`.
    - Inserts mirror trade(s) into investor history.
  - After transaction, withdraws accumulated commission from manager pool via trade engine.

---

### 3.3 Partial Close Confirmed (Unsubscribe Flow)

**Route**

- `POST /api/internal/pmam/partial-close-confirmed`

**Body**

```json
{
  "position_id": 987654,
  "pmam_investor_id": 101,
  "lot_closed": 60000,              // base units or lots; service normalizes
  "executed_price": 5200.10,
  "profit": 120.0,
  "swap": -1.5,
  "close_time": "2026-03-10T19:45:00Z"
}
```

**Success Response**

```json
{
  "success": true,
  "message": "Partial close confirmed for investor 101"
}
```

**Side‑effects (summary)**

- Finds `PmamTradeAllocation` for `(pmam_investor_id, position_id)` with status `open` or `unsubscribed_close`.
- Caps profit if engine accidentally sends full position profit instead of partial share.
- Creates `PmamProfitDistribution` record.
- Updates:
  - `allocation.status = 'closed'`, sets `close_price` & `close_time`.
  - Investor `total_pnl` and `pmam_locked_amount`.
  - Inserts mirror trade via `insertMirrorTrade`.
- Credits commission to manager wallet and withdraws from pool.
- If all allocations for this investor are now closed:
  - Calls `finalizeUnsubscribe(...)` to:
    - Return principal + P&L to investor MT5 account.
    - Release `pmam_locked_amount`.
    - Mark investor `inactive`.

---

This document is intended as a **backend-facing** reference for integrating the PMAM module with:

- Frontend (TenaxCode client),
- Trade Engine (`crmtradeenginev3`),
- Bridge/MT5 infrastructure.

For any new integration (e.g. new engine), reuse these payloads and flows to stay compatible.

