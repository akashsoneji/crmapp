# ScratchCard Mobile API Flow (Auto-create Passwords, No Popup)

This document describes the **mobile/client flow** for Scratch Cards, including what to do when the backend returns:
`HTTP 409` with `data.code = "SCRATCH_ACCOUNT_REQUIRED"`.

In this version, the mobile app **does not show the password popup**. Instead it:
1) **auto-generates** `main_password` and `investor_password` in the background,
2) calls the account creation endpoint,
3) **retries reveal** for the same `card_id`.

---

## Base URL

- **Base**: `http://crm.forx.com`

---

## 0) Authentication

All ScratchCard user endpoints require:

- **Header**: `Authorization: Bearer <TOKEN>`

Token is obtained from:

- `POST /api/user/login`

---

## 1) Login (Get Bearer Token)

### Endpoint

- `POST /api/user/login`

### Headers

- `Content-Type: application/json`
- `Accept: application/json`

### Body

Provide either:
- `email` OR `mobile`

And also:
- `password` (plain text)
- `fcm_token` (optional)
- `device_type` (optional; `android` or `ios`)

---

## 2) Fetch Scratch Cards

### Endpoint

- `GET /api/v1/user/scratch-cards`

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

### Fields you need

- `cards[].id` => use as `card_id` for reveal

---

## 3) Reveal / Scratch a Card

### Endpoint

- `POST /api/v1/user/scratch-cards/reveal`

### Headers

- `Authorization: Bearer <TOKEN>`
- `Content-Type: application/json`
- `Accept: application/json`

### Body

| Field | Type | Required |
|------|------|----------|
| `card_id` | integer | yes |

---

## 3A) If Scratch Trading Account is Missing (Auto-create path)

If the user **does not have** the required scratch trading account (selfHosted + `is_scratchcard_account=1`), reveal is blocked and returns:

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

### What the mobile app should do (no popup)

1. Read `scratch_group_id` from the 409 response.
2. **Generate** (locally) two random strings:
   - `main_password`
   - `investor_password`
3. Call **Create Scratch Account** (next section).
4. **Retry** reveal using the **same** `card_id`.

Notes for implementers:
- Backend requires these fields to be present as non-empty strings.
- You may keep the generated passwords only in memory or store them securely (recommended if you ever need them later).

---

## 4) Create Scratch Self-Hosted Trading Account (Auto-create)

### Endpoint

- `POST /api/user/mt5accounts/create`

### Headers

- `Authorization: Bearer <TOKEN>`
- `Content-Type: application/json`
- `Accept: application/json`

### Body

| Field | Type | Required |
|------|------|----------|
| `group_id` | integer | yes (use `scratch_group_id` from step 3A) |
| `main_password` | string | yes (auto-generated) |
| `investor_password` | string | yes (auto-generated) |

### Success Response (created) (shape)

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

### Success Response (already exists) (shape)

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

## 5) Retry Reveal

After account creation, call step 3 again using the **same** `card_id`.

### Success Response (lose) (example shape)

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

### Success Response (win) (example shape)

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

- `credit_status`:
  - `none` if `reward_amount = 0`
  - otherwise can be `pending/credited/failed`
- `credit_error`:
  - error reason when `credit_status = failed`

---

## Common Errors

### Module disabled

- `GET /api/v1/user/scratch-cards` → HTTP **403**
- `POST /api/v1/user/scratch-cards/reveal` → HTTP **403**

### Credit failed

If the reward is a win but Trade Engine is not reachable/configured:
- `credit_status = "failed"`
- `credit_error` contains the HTTP/cURL error

Meaning:
- scratch was recorded, but credit was not applied.


