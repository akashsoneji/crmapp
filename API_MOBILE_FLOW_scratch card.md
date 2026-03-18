# ScratchCard Mobile API Flow (v1)

This document describes the **mobile/client flow** to use Scratch Cards, including the **self-hosted scratch trading account requirement** and the **lossable credit** behavior.

## Base URL

- **Base**: `http://crm.forx.com`

## Auth

All ScratchCard user endpoints require:

- **Header**: `Authorization: Bearer <TOKEN>`
- Token is obtained from `POST /api/user/login`

---

## 1) Login (Get Bearer Token)

### Endpoint

- **POST** `/api/user/login`

### Headers

- `Content-Type: application/json`
- `Accept: application/json`

### Body (email login)

| Field | Type | Required | Notes |
|------|------|----------|------|
| `email` | string | yes* | Provide either `email` or `mobile` |
| `password` | string | yes | Plain password |
| `fcm_token` | string | no | Optional |
| `device_type` | string | no | `android` or `ios` |

\*Required if `mobile` not provided.

### Body (mobile login)

| Field | Type | Required | Notes |
|------|------|----------|------|
| `mobile` | string | yes* | Provide either `mobile` or `email` |
| `password` | string | yes | Plain password |

### Success Response (shape)

```json
{
  "status": true,
  "message": "Signed in successfully",
  "data": {
    "user": { },
    "token": "1|xxxxxxxxxxxxxxxx",
    "websocket_token": "...."
  }
}
```

---

## 2) Fetch Scratch Cards (Auto-creates current window card)

This endpoint:

- Uses **Dubai timezone**
- Creates/ensures a card exists for the current window (`08:00` / `20:00`)
- Expires old active cards when past `expires_at`

### Endpoint

- **GET** `/api/v1/user/scratch-cards`

### Headers

- `Authorization: Bearer <TOKEN>`
- `Accept: application/json`

### Success Response (shape)

```json
{
  "status": true,
  "message": "Scratch cards fetched successfully",
  "data": {
    "summary": {
      "earned_in_30_days": 0,
      "max_limit_30_days": 10,
      "next_card_available_at": "2026-03-17T16:00:00+00:00"
    },
    "cards": [
      {
        "id": 5,
        "status": "active",
        "reward_amount": null,
        "refresh_window": "2026-03-17-08",
        "expires_at": "2026-03-17T16:00:00+00:00"
      }
    ]
  }
}
```

### Fields returned (important)

| Field | Meaning |
|------|---------|
| `cards[].id` | Use as `card_id` for reveal |
| `cards[].refresh_window` | Window ID like `YYYY-MM-DD-08` or `YYYY-MM-DD-20` |
| `cards[].expires_at` | Next window time |

---

## 3) Reveal / Scratch a Card

### Endpoint

- **POST** `/api/v1/user/scratch-cards/reveal`

### Headers

- `Authorization: Bearer <TOKEN>`
- `Content-Type: application/json`
- `Accept: application/json`

### Body

| Field | Type | Required | Notes |
|------|------|----------|------|
| `card_id` | integer | yes | From `GET /api/v1/user/scratch-cards` |

---

## 3A) If Scratch Trading Account is Missing (Popup Flow)

If the user **does not have** the required scratch trading account (`selfHosted` + `is_scratchcard_account=1`), reveal is blocked and returns:

- HTTP **409**
- `data.code = "SCRATCH_ACCOUNT_REQUIRED"`

### Response (shape)

```json
{
  "status": false,
  "message": "Scratch trading account is required to reveal rewards.",
  "data": {
    "code": "SCRATCH_ACCOUNT_REQUIRED",
    "scratch_group_configured": true,
    "scratch_group_id": 5,
    "next_step": {
      "action": "create_scratch_account",
      "endpoint": "/api/user/mt5accounts/create",
      "required_fields": ["group_id", "main_password", "investor_password"]
    }
  }
}
```

### What mobile should do

1. Show popup/modal to collect:
   - `main_password`
   - `investor_password`
2. Call **Create Scratch Account** (next section)
3. Retry **Reveal** with the same `card_id`

---

## 4) Create Scratch Self-Hosted Trading Account (from popup)

This uses the existing account create API. For scratch card:

- Group must be the single group flagged as `is_scratchcard_group = 1`
- Account created is:
  - `trading_server = selfHosted`
  - `is_scratchcard_account = 1`
- If account already exists, API returns `"Scratch trading account already exists"`

### Endpoint

- **POST** `/api/user/mt5accounts/create`

### Headers

- `Authorization: Bearer <TOKEN>`
- `Content-Type: application/json`
- `Accept: application/json`

### Body

| Field | Type | Required | Notes |
|------|------|----------|------|
| `group_id` | integer | yes | Use `scratch_group_id` from step 3A |
| `main_password` | string | yes | From user popup |
| `investor_password` | string | yes | From user popup |

### Success Response (created)

```json
{
  "status": true,
  "message": "Live account created successfully",
  "data": {
    "group_name": "SCRATCH_WEBTRADER",
    "account_number": "2000001",
    "account_type": "live",
    "leverage": "100",
    "trading_platform": "WEB_TRADER"
  }
}
```

### Success Response (already exists)

```json
{
  "status": true,
  "message": "Scratch trading account already exists",
  "data": {
    "account_id": 2,
    "mt5_account": "2000001",
    "trading_server": "selfHosted"
  }
}
```

---

## 5) Retry Reveal (after account is created)

Call step 3 again (same `card_id`).

### Success Response (lose)

```json
{
  "status": true,
  "message": "Better luck next time!",
  "data": {
    "card_id": 5,
    "status": "scratched",
    "reward_amount": 0,
    "scratched_at": "2026-03-17T13:23:46+00:00",
    "credit_status": "none",
    "credit_error": ""
  }
}
```

### Success Response (win)

```json
{
  "status": true,
  "message": "Congratulations! You won $0.40",
  "data": {
    "card_id": 5,
    "status": "scratched",
    "reward_amount": 0.4,
    "scratched_at": "2026-03-17T13:50:46+00:00",
    "credit_status": "credited",
    "credit_error": ""
  }
}
```

### Credit fields meaning

| Field | Meaning |
|------|---------|
| `credit_status` | `none` if reward is 0, otherwise `pending/credited/failed` |
| `credit_error` | Reason when `credit_status = failed` |

---

## Common Errors

### Module disabled

If ScratchCard module is disabled in admin settings (`is_enabled=0`):

- `GET /api/v1/user/scratch-cards` → HTTP 403
- `POST /api/v1/user/scratch-cards/reveal` → HTTP 403

### Trade Engine credit failed

If the reward wins but Trade Engine is not reachable/configured, reveal may return:

- `credit_status = failed`
- `credit_error` contains the HTTP/cURL error

This means: scratch was recorded, but **credit was not applied to the trading account**.

