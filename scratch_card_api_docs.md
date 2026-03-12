# Scratch Card Feature - API & Backend Logic Documentation

## Overview
This document outlines the API structure and backend logic required to implement the Scratch Card feature.
- **Maximum Reward Limit:** $20 per 30 days.
- **Frequency:** 2 scratch cards per day (1 card every 12 hours).
- **Expiry:** If a card is not scratched within its 12-hour window, it expires, and a new card is generated for the next window.

---

## 1. API: Get Scratch Cards (Listing & History)
This API is called when the user opens the "Scratch Card" screen. It returns active, expired, and already scratched cards to build the UI.

- **Method:** `GET`
- **Endpoint:** `/api/v1/user/scratch-cards`

### Response JSON
```json
{
  "status": true,
  "message": "Scratch cards fetched successfully",
  "data": {
    "summary": {
      "earned_in_30_days": 15.50,
      "max_limit_30_days": 20.00,
      "next_card_available_at": "2026-03-07T06:00:00Z"
    },
    "cards": [
      {
        "id": 101,
        "status": "active",
        "reward_amount": null,
        "created_at": "2026-03-06T18:00:00Z",
        "expires_at": "2026-03-07T06:00:00Z",
        "scratched_at": null
      },
      {
        "id": 100,
        "status": "expired",
        "reward_amount": 0.00,
        "created_at": "2026-03-06T06:00:00Z",
        "expires_at": "2026-03-06T18:00:00Z",
        "scratched_at": null
      },
      {
        "id": 99,
        "status": "scratched",
        "reward_amount": 2.50,
        "created_at": "2026-03-05T18:00:00Z",
        "expires_at": "2026-03-06T06:00:00Z",
        "scratched_at": "2026-03-05T19:30:00Z"
      }
    ]
  }
}
```
*Note: `status` can be `active` (clickable), `expired` (missed), or `scratched` (already played).*

---

## 2. API: Reveal / Scratch the Card
This API is called when the user rubs/scratches the active card on the screen. The backend calculates the win amount based on the remaining limits.

- **Method:** `POST`
- **Endpoint:** `/api/v1/user/scratch-cards/reveal`

### Request Body
```json
{
  "card_id": 101 
}
```

### Response JSON
```json
{
  "status": true,
  "message": "Congratulations! You won $1.50",
  "data": {
    "card_id": 101,
    "status": "scratched",
    "reward_amount": 1.50,
    "scratched_at": "2026-03-06T18:25:00Z",
    "summary_update": {
      "earned_in_30_days": 17.00,
      "remaining_limit": 3.00
    }
  }
}
```

---

## Backend Developer Logic Guidelines

### 1. Lazy Loading & Interval Management
- **No strict cron jobs required.** The status of cards can be evaluated lazily when the `GET /scratch-cards` API is requested.
- If the previous card's `expires_at` is older than the current time, its status should be updated to `"expired"` in the database.
- A new `"active"` card should be generated for the current 12-hour window and returned in the response.

### 2. Thirty-Day Maximum Limit ($20)
When the `POST /reveal` API is hit, the backend must perform the following checks:
- **Rule A (Time Check):** Verify that the card is currently `"active"` and the current time is strictly less than `expires_at`. If not, return an error (e.g., "Card has expired").
- **Rule B (Limit Check):** Calculate the sum of `reward_amount` for the last 30 days. 
  - If the user has already earned $20, the API must return `reward_amount: 0.00` ("Better luck next time").
  - If the user has earned $19.50, the maximum possible reward for this scratch must be capped at $0.50 so the limit is never exceeded.

### 3. Centralized Status Management
- There should **only be 1 active card** per user at any given time.
- All older cards must be marked as either `scratched` or `expired`.
- This ensures consistency both on the Flutter app (UI presentation) and in the backend calculations.
