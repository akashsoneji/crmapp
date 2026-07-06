---
name: project-tenax-multi-broker-collision-bug
description: "Tenax multi-broker matches by broker_slug only — different users on same broker collide"
type: project
createdAt: 1783334108789
updatedAt: 1783334108789
---

Tenax multi-broker profile lookup in `lib/controllers/tenax_broker_selection_controller.dart` (`selectBroker` method) matches saved profiles by `broker_slug` only, ignoring the user email. This causes User A and User B (different emails) using the same Tenax broker to collide: when B taps the same broker on the selection screen, the code finds A's profile by slug, restores A's tokens, and silently logs B into A's account.

**Why:** The storage layer (`SecureStorageService`) already keys every profile by `profile_key = '<lowercased_email>|<broker_slug>'` and `upsertTenaxUserBrokerProfile` de-dupes correctly. The bug is purely in the read path inside `selectBroker` — `firstWhereOrNull((p) => p['broker_slug'] == broker.slug)` — and the slug-only fallback in `more_screen.dart` `_selectTenaxProfile`. The login flow (`_persistTenaxUserBrokerProfile`) is correct and writes the right `profile_key`; only the broker re-selection path is broken.

**How to apply:** When touching Tenax multi-broker code, always match on `profile_key` (email + slug), never on `broker_slug` alone. The Switch Account sheet in `MoreScreen` should group profiles by broker and show the email/name per profile. Adding a new "Log in with another account" affordance per broker group is the user-facing fix. See `.xelion/plans/tenax-same-broker-multi-user.plan.md` for the full 9-step plan. Related: `[[project-add-flavor-script-2026-07-03]]` covers the broker setup itself; this memory covers the runtime user-broker identity layer.

**Affected files:**
- `lib/services/secure_storage_service.dart` (storage — correct, has helpers like `findTenaxProfileByIdentity` to add)
- `lib/controllers/tenax_broker_selection_controller.dart` (BUG: slug-only match in `selectBroker`)
- `lib/controllers/auth_controller.dart` (correct, just needs a debug log)
- `lib/screens/home/more/more_screen.dart` (Switch Account sheet — needs broker grouping)
- `lib/screens/auth/login/login_screen.dart` (needs `preserveBroker` arg support)
