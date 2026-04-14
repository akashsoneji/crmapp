# ScratchCard + Leaderboard APIs (Mobile)

This document describes the **user-facing ScratchCard APIs** and the **marketing Leaderboard API**.

---

## Base URL

Use your environment base URL, for example:

- `https://demo.tenaxcode.com`

All endpoints below are under that host.

---

## Authentication

All endpoints in this document require a **Bearer token** (Laravel Sanctum), unless noted otherwise.

### Required headers

- `Authorization: Bearer <TOKEN>`
- `Accept: application/json`
- For JSON POST: `Content-Type: application/json`

---

## 0) Login (to obtain token)

### POST `/api/user/login`

Use the same login payload your app already uses for the portal.

After login, store the returned token and use it as:

- `Authorization: Bearer <TOKEN>`

---

## 1) Get Scratch Cards + Summary (Promotion screen)

### GET `/api/v1/user/scratch-cards`

#### Response (200)

```json
{
  "status": true,
  "message": "Scratch cards fetched successfully",
  "data": {
    "summary": {
      "earned_in_30_days": 3.25,
      "max_limit_30_days": 20,
      "next_card_available_at": "2026-04-14T16:00:00+04:00",

      "scratch_pending_reward_total": 1.15,
      "required_lots": 0.02,
      "lots_accumulated": 0.01,
      "lots_remaining": 0.01,

      "has_scratch_account": true,
      "scratch_account_number": "2000027",

      "scratch_completed_once": false
    },
    "cards": [
      {
        "id": 123,
        "user_id": 53,
        "status": "active",
        "refresh_window": "2026-04-14-08",
        "expires_at": "2026-04-14 20:00:00",

        "reward_amount": 0,
        "scratched_at": null,

        "credited_mt5_account_id": null,
        "credit_status": null,
        "credit_error": null
      }
    ]
  }
}
```

#### `data.summary` fields

- **`earned_in_30_days`**: total winnings in the current 30-day period.
- **`max_limit_30_days`**: configured monthly cap.
- **`next_card_available_at`**: next scratch window time (Dubai time). Can be `null` if scratch is disabled after completion.
- **`scratch_pending_reward_total`**: pending scratch reward total (cycle tracking).
- **`required_lots`**: lots required to unlock conversion.
- **`lots_accumulated`**: current cycle lots accumulated.
- **`lots_remaining`**: remaining lots to reach requirement.
- **`has_scratch_account`**: whether user has a scratch self-hosted trading account.
- **`scratch_account_number`**: scratch account login number (if exists).
- **`scratch_completed_once`**: when `true`, UI hides new scratch cards (one-time completion behavior).

#### Common errors

- **403**: Scratch module disabled for the user/account.

---

## 2) Reveal (Scratch) a Card

### POST `/api/v1/user/scratch-cards/reveal`

#### Request body

```json
{
  "card_id": 123
}
```

#### Response (200) — win example

```json
{
  "status": true,
  "message": "Congratulations! You won $0.83",
  "data": {
    "card_id": 123,
    "status": "scratched",
    "reward_amount": 0.83,
    "scratched_at": "2026-04-14T07:25:10Z",

    "credit_status": "credited",
    "credit_error": null,

    "bonus_period": false,
    "summary_update": {
      "earned_in_30_days": 3.25,
      "remaining_limit": 16.75
    }
  }
}
```

#### Response (200) — lose example

```json
{
  "status": true,
  "message": "Better luck next time!",
  "data": {
    "card_id": 123,
    "status": "scratched",
    "reward_amount": 0,
    "scratched_at": "2026-04-14T07:25:10Z",
    "credit_status": "none",
    "credit_error": null
  }
}
```

#### Common errors

##### 409 — Scratch trading account required

If the user has no scratch self-hosted account yet:

```json
{
  "status": false,
  "message": "Scratch trading account is required to reveal rewards.",
  "data": {
    "code": "SCRATCH_ACCOUNT_REQUIRED",
    "scratch_group_configured": true,
    "scratch_group_id": 6,
    "next_step": {
      "action": "create_scratch_account",
      "endpoint": "/api/user/mt5accounts/create",
      "required_fields": ["group_id", "main_password", "investor_password"]
    }
  }
}
```

##### 422 — Card expired / already scratched / invalid

---

## 3) Create Scratch Trading Account (only if reveal returns 409)

### POST `/api/user/mt5accounts/create`

#### Request body

```json
{
  "group_id": 6,
  "main_password": "YourMainPassword",
  "investor_password": "YourInvestorPassword"
}
```

#### Response (200)

Returns the created MT5/self-hosted account payload (varies by environment). After success, retry reveal.

---

## 4) Marketing Scratch Leaderboard (Rotating Top 5)

This leaderboard is **NOT** based on real users. It returns **fake masked names** and amounts for marketing.

### GET `/api/v1/user/scratch-cards/leaderboard`

#### Rotation windows (Dubai timezone)

- **08:00–19:59 Asia/Dubai** → `YYYY-MM-DD-08`
- **20:00–07:59 Asia/Dubai** → `YYYY-MM-DD-20` (previous day when before 08:00)

#### Sorting guarantee

The API always returns 5 entries:

- Sorted by **`amount` descending**
- `position` is assigned after sorting:
  - `position=1` is highest amount
  - `position=5` is lowest amount

#### Amount guarantee

Each row amount is always strictly above admin ScratchCard `max_prize`:

- `amount >= max_prize + 2.00`

#### Response (200)

```json
{
  "status": true,
  "message": "Leaderboard fetched successfully",
  "data": {
    "window": {
      "window_key": "2026-04-14-08",
      "range_label": "Apr 13 - 19",
      "batch_index": 12
    },
    "leaderboard": [
      {
        "position": 1,
        "display_name": "Y***a",
        "avatar_letter": "Y",
        "amount": 16.45
      },
      {
        "position": 2,
        "display_name": "R***l",
        "avatar_letter": "R",
        "amount": 15.04
      }
    ]
  }
}
```

#### Common errors

##### 500 — Leaderboard not seeded

If batches are not seeded on server:

```json
{
  "status": false,
  "message": "Leaderboard is not seeded. Run: php artisan scratch:seed-leaderboard-batches --force",
  "data": {
    "window": { "window_key": "2026-04-14-08", "range_label": "Apr 13 - 19", "batch_index": 12 },
    "leaderboard": []
  }
}
```

---

## Postman quick test (minimal)

1) Login → get token (store as `TOKEN`)\n
2) Call scratch summary:\n
- `GET {{BASE_URL}}/api/v1/user/scratch-cards`\n
\n
3) Call leaderboard:\n
- `GET {{BASE_URL}}/api/v1/user/scratch-cards/leaderboard`\n
- Header: `Authorization: Bearer {{TOKEN}}`\n

