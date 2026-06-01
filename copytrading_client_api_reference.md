# Client-Side Copy Trading API Reference (Structured by Submenus)

This document provides a detailed reference for all client-side API endpoints used in the Copy Trading module, organized by their respective frontend submenus and views.

---

## ─── PART A: MASTER (TRADER) AREA ───

### Submenu: Master Dashboard
*   **When is it used:** Loaded when a Master Trader opens their main dashboard to view aggregate growth metrics, account validation status, and active open positions.
*   **APIs Used:**

#### 1. Check Master Trader Status
*   **Function:** `copytradingService.master.getStatus()`
*   **Method & Path:** `GET /api/user/copytrading/master/status`
*   **Request Parameters:** None
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Master status retrieved successfully",
      "data": {
        "is_master": true,
        "application_status": "approved",
        "master_code": "MST-928347",
        "created_at": "2026-05-01T12:00:00.000000Z"
      }
    }
    ```

#### 2. Get Dashboard Stats
*   **Function:** `copytradingService.master.getDashboardStats()`
*   **Method & Path:** `GET /api/user/copytrading/master/dashboard-stats`
*   **Request Parameters:** None
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Dashboard statistics retrieved",
      "data": {
        "total_copiers": 12,
        "active_copiers": 8,
        "total_aum": 24500.50,
        "total_commission_earned": 1250.75,
        "monthly_pnl_percentage": 14.5
      }
    }
    ```

#### 3. Get Plan Open Positions
*   **Function:** `copytradingService.master.getPlanOpenPositions(id)`
*   **Method & Path:** `GET /api/user/copytrading/master/plans/{id}/open-positions`
*   **Request Parameters:** None (passed via URL slug `{id}`)
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Open positions retrieved",
      "data": [
        {
          "position_id": 1694550,
          "symbol": "XAUUSD.c",
          "type": "buy",
          "volume": 0.10,
          "open_price": 2345.50,
          "current_price": 2348.20,
          "profit": 270.00,
          "open_time": "2026-06-01T15:30:00.000000Z"
        }
      ]
    }
    ```

#### 4. Apply to become a Master (First-time users)
*   **Function:** `copytradingService.master.apply(data)`
*   **Method & Path:** `POST /api/user/copytrading/master/apply`
*   **Request Body (JSON):**
    ```json
    {
      "mt5_account_id": 128
    }
    ```
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Application submitted successfully",
      "data": {
        "id": 15,
        "user_id": 24,
        "mt5_account_id": 128,
        "status": "pending",
        "created_at": "2026-06-01T16:00:00.000000Z"
      }
    }
    ```

---

### Submenu: My Plans
*   **When is it used:** Loaded when a Master Trader navigates to their plan manager to view active strategy settings, create new plans, or modify parameters.
*   **APIs Used:**

#### 1. List Master Plans
*   **Function:** `copytradingService.master.getPlans()`
*   **Method & Path:** `GET /api/user/copytrading/master/plans`
*   **Request Parameters:** None
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Plans retrieved successfully",
      "data": [
        {
          "id": 4,
          "name": "Aggressive Gold Growth",
          "description": "High-risk plan focusing on XAUUSD",
          "min_investment": 500.00,
          "profit_share": 30.00,
          "status": "active",
          "copiers_count": 5
        }
      ]
    }
    ```

#### 2. Create Plan
*   **Function:** `copytradingService.master.createPlan(data)`
*   **Method & Path:** `POST /api/user/copytrading/master/plans`
*   **Request Body (JSON):**
    ```json
    {
      "name": "Aggressive Gold Growth",
      "description": "High-risk plan focusing on XAUUSD",
      "min_investment": 500.00,
      "profit_share": 30.00,
      "status": "active"
    }
    ```
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Plan created successfully",
      "data": {
        "id": 5,
        "name": "Aggressive Gold Growth",
        "min_investment": 500.00,
        "profit_share": 30.00,
        "status": "active"
      }
    }
    ```

#### 3. Get Plan Details (For Editing)
*   **Function:** `copytradingService.master.getPlanDetail(id)`
*   **Method & Path:** `GET /api/user/copytrading/master/plans/{id}`
*   **Request Parameters:** None (passed via URL slug `{id}`)
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Plan details retrieved",
      "data": {
        "id": 5,
        "name": "Aggressive Gold Growth",
        "description": "Strategy description",
        "min_investment": 500.00,
        "profit_share": 30.00,
        "status": "active"
      }
    }
    ```

#### 4. Update Plan Settings
*   **Function:** `copytradingService.master.updatePlan(id, data)`
*   **Method & Path:** `PUT /api/user/copytrading/master/plans/{id}`
*   **Request Body (JSON):**
    ```json
    {
      "name": "Modified Gold Growth Plan",
      "description": "Updated strategy details"
    }
    ```
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Plan updated successfully",
      "data": {
        "id": 5,
        "name": "Modified Gold Growth Plan"
      }
    }
    ```

#### 5. Pause Copying on Plan
*   **Function:** `copytradingService.master.pausePlan(id)`
*   **Method & Path:** `POST /api/user/copytrading/master/plans/{id}/pause`
*   **Request Parameters:** None (passed via URL slug `{id}`)
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Plan paused successfully"
    }
    ```

#### 6. Resume Copying on Plan
*   **Function:** `copytradingService.master.resumePlan(id)`
*   **Method & Path:** `POST /api/user/copytrading/master/plans/{id}/resume`
*   **Request Parameters:** None (passed via URL slug `{id}`)
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Plan resumed successfully"
    }
    ```

#### 7. Inactivate Plan
*   **Function:** `copytradingService.master.inactivatePlan(id)`
*   **Method & Path:** `POST /api/user/copytrading/master/plans/{id}/inactivate`
*   **Request Parameters:** None (passed via URL slug `{id}`)
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Plan inactivated successfully"
    }
    ```

---

### Submenu: My Copiers
*   **When is it used:** Loaded when a Master Trader wishes to view the list of investors copying their plans, including details on current capital and subscription dates.
*   **APIs Used:**

#### 1. Get All Copiers (Global List)
*   **Function:** `copytradingService.master.getAllCopiers(params)`
*   **Method & Path:** `GET /api/user/copytrading/master/copiers`
*   **Query Parameters (`params`):** `{ page, per_page, plan_id, status, search }`
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Copiers list retrieved",
      "data": {
        "data": [
          {
            "id": 18,
            "plan_id": 4,
            "plan_name": "Gold Growth",
            "user_name": "John Doe",
            "account_number": "400450",
            "investment_amount": 2500.00,
            "status": "active"
          }
        ],
        "total": 1,
        "current_page": 1
      }
    }
    ```

#### 2. Get Copiers for Specific Plan
*   **Function:** `copytradingService.master.getPlanCopiers(id, params)`
*   **Method & Path:** `GET /api/user/copytrading/master/plans/{id}/copiers`
*   **Query Parameters (`params`):** `{ page, per_page }`
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Plan copiers retrieved",
      "data": {
        "data": [
          {
            "id": 18,
            "user_name": "John Doe",
            "account_number": "400450",
            "investment_amount": 2500.00,
            "status": "active"
          }
        ],
        "total": 1
      }
    }
    ```

---

### Submenu: Commission History
*   **When is it used:** Loaded when a Master Trader views performance fee receipts and payouts.
*   **APIs Used:**

#### 1. Get Commissions
*   **Function:** `copytradingService.master.getCommissions(params)`
*   **Method & Path:** `GET /api/user/copytrading/master/commissions`
*   **Query Parameters (`params`):** `{ from_date, to_date }`
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Commissions list retrieved",
      "data": [
        {
          "id": 92,
          "copier_name": "John Doe",
          "copier_account": "400450",
          "amount": 75.00,
          "profit_share_percentage": 30.00,
          "calculation_date": "2026-05-31T23:59:59.000000Z"
        }
      ]
    }
    ```

#### 2. Export Commission Report (CSV download)
*   **Function:** `copytradingService.master.exportCommissions(params)`
*   **Method & Path:** `GET /api/user/copytrading/master/commissions/export`
*   **Query Parameters (`params`):** `{ from_date, to_date }`
*   **JSON Response:** Returns a raw binary CSV file stream.

---
---

## ─── PART B: INVESTOR (COPIER) AREA ───

### Submenu: Find Masters / Leaderboard
*   **When is it used:** Loaded when an investor browses strategy providers, compares performance metrics, or selects a master to start copying.
*   **APIs Used:**

#### 1. List Available Masters (Leaderboard)
*   **Function:** `copytradingService.public.getMasters(params)`
*   **Method & Path:** `GET /api/copytrading/masters`
*   **Query Parameters (`params`):** `{ page, per_page, search, sort_by }`
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Masters list retrieved",
      "data": {
        "data": [
          {
            "master_code": "MST-928347",
            "name": "Alex Mercer",
            "roi_30d": 18.5,
            "min_investment": 500.00,
            "active_copiers": 24,
            "profit_share": 25.00
          }
        ]
      }
    }
    ```

#### 2. Get Master Profile details
*   **Function:** `copytradingService.copier.getMasterProfile(code)`
*   **Method & Path:** `GET /api/user/copytrading/copier/masters/{code}`
*   **Request Parameters:** None (passed via URL slug `{code}`)
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Profile retrieved",
      "data": {
        "master_code": "MST-928347",
        "bio": "Experienced gold trader",
        "equity": 15400.00,
        "max_drawdown": 12.4,
        "win_rate": 78.5,
        "plans": [
          {
            "id": 4,
            "name": "Gold Growth",
            "min_investment": 500.00,
            "profit_share": 30.00
          }
        ]
      }
    }
    ```

#### 3. Master Closed Trade History
*   **Function:** `copytradingService.copier.getMasterTradeHistory(code, params)`
*   **Method & Path:** `GET /api/user/copytrading/copier/masters/{code}/trade-history`
*   **Query Parameters (`params`):** `{ page, per_page, timeframe, plan_id }`
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Master trade history retrieved",
      "data": {
        "data": [
          {
            "symbol": "XAUUSD.c",
            "type": "buy",
            "volume": 0.10,
            "profit": 45.00,
            "close_time": "2026-06-01T14:20:00Z"
          }
        ],
        "total": 120
      }
    }
    ```

---

### Submenu: My Subscriptions (Portfolio)
*   **When is it used:** Loaded when an investor manages active copying settings, adds capital, pauses copy execution, or stops copying strategies.
*   **APIs Used:**

#### 1. List Subscriptions
*   **Function:** `copytradingService.copier.getSubscriptions(params)`
*   **Method & Path:** `GET /api/user/copytrading/copier/subscriptions`
*   **Query Parameters (`params`):** `{ page, per_page }`
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Subscriptions retrieved",
      "data": [
        {
          "id": 78,
          "master_name": "Alex Mercer",
          "plan_name": "Gold Growth",
          "my_account_number": "400424",
          "investment_amount": 1000.00,
          "status": "active"
        }
      ]
    }
    ```

#### 2. Get Eligible Accounts (For new subscription modal)
*   **Function:** `copytradingService.copier.getEligibleAccounts(planId)`
*   **Method & Path:** `GET /api/user/copytrading/copier/eligible-accounts`
*   **Query Parameters:** `{ plan_id }`
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Eligible accounts retrieved",
      "data": [
        {
          "id": 23,
          "meta_account_number": "400424",
          "balance": 995.27,
          "leverage": 500
        }
      ]
    }
    ```

#### 3. Subscribe (Start Copying)
*   **Function:** `copytradingService.copier.subscribe(data)`
*   **Method & Path:** `POST /api/user/copytrading/copier/subscribe`
*   **Request Body (JSON):**
    ```json
    {
      "master_code": "MST-928347",
      "plan_id": 4,
      "mt5_account_id": 23,
      "investment_amount": 1000.00,
      "copying_method": "multiplier",
      "lot_multiplier": 1.5,
      "fixed_lot_size": null
    }
    ```
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Subscribed successfully",
      "data": {
        "subscription_id": 78,
        "status": "active"
      }
    }
    ```

#### 4. Get Subscription Details
*   **Function:** `copytradingService.copier.getSubscriptionDetail(id)`
*   **Method & Path:** `GET /api/user/copytrading/copier/subscriptions/{id}/detail`
*   **Request Parameters:** None (passed via URL slug `{id}`)
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Subscription details retrieved",
      "data": {
        "id": 78,
        "current_equity": 1045.20,
        "total_profit_loss": 45.20,
        "status": "active"
      }
    }
    ```

#### 5. Pause Copying
*   **Function:** `copytradingService.copier.pause(id)`
*   **Method & Path:** `POST /api/user/copytrading/copier/subscriptions/{id}/pause`
*   **Request Parameters:** None (passed via URL slug `{id}`)
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Subscription paused successfully"
    }
    ```

#### 6. Resume Copying
*   **Function:** `copytradingService.copier.resume(id)`
*   **Method & Path:** `POST /api/user/copytrading/copier/subscriptions/{id}/resume`
*   **Request Parameters:** None (passed via URL slug `{id}`)
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Subscription resumed successfully"
    }
    ```

#### 7. Stop Copying (Unsubscribe)
*   **Function:** `copytradingService.copier.stop(id)`
*   **Method & Path:** `POST /api/user/copytrading/copier/subscriptions/{id}/stop`
*   **Request Parameters:** None (passed via URL slug `{id}`)
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Unsubscribed successfully. All open trades have been closed."
    }
    ```

#### 8. Get Copied Trades
*   **Function:** `copytradingService.copier.getMyTrades(id, params)`
*   **Method & Path:** `GET /api/user/copytrading/copier/subscriptions/{id}/trades`
*   **Query Parameters (`params`):** `{ page, per_page }`
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Copied trades retrieved",
      "data": [
        {
          "ticket": 489201,
          "symbol": "XAUUSD.c",
          "type": "buy",
          "lots": 0.15,
          "profit": 67.50
        }
      ]
    }
    ```

#### 9. Add Capital
*   **Function:** `copytradingService.copier.addCapital(id, data)`
*   **Method & Path:** `POST /api/user/copytrading/copier/subscriptions/{id}/add-capital`
*   **Request Body (JSON):**
    ```json
    {
      "amount": 250.00
    }
    ```
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Capital added successfully",
      "data": {
        "new_investment_amount": 1250.00
      }
    }
    ```

#### 10. Update Copying Parameters
*   **Function:** `copytradingService.copier.updateSubscription(id, data)`
*   **Method & Path:** `PUT /api/user/copytrading/copier/subscriptions/{id}/update`
*   **Request Body (JSON):**
    ```json
    {
      "copying_method": "fixed",
      "fixed_lot_size": 0.05
    }
    ```
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "Subscription updated successfully"
    }
    ```

#### 11. Subscription P&L Growth History (Charts)
*   **Function:** `copytradingService.copier.getMyPnlHistory(id, params)`
*   **Method & Path:** `GET /api/user/copytrading/copier/subscriptions/{id}/pnl-history`
*   **Query Parameters (`params`):** `{ timeframe }`
*   **JSON Response:**
    ```json
    {
      "status": true,
      "message": "PnL history retrieved",
      "data": [
        { "date": "2026-05-28", "profit": 12.50 },
        { "date": "2026-05-29", "profit": 28.00 }
      ]
    }
    ```
