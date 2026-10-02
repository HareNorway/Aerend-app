# Ærend — Ægil Personal Shopping Agent: Technical Specification

Version 2.0 · September 2026 · Status: for implementation review
Supersedes v1.1. Companion to the Order Operations Platform spec v2.0 (*Ops spec*); uses its definitions of states, events, policy keys, the agent layer and the Feed service boundary. Appendix C maps the 34 chat tweaks from the design brief to the contracts in this document.

---

## 0. Scope

Ægil as a personal shopping agent in the customer app:
- a user-owned preference memory (stated, interpreted from free text, learned and confirmed);
- a proactive matching engine over offers, arrivals, rhythms and reward thresholds, with a daily model re-ranking step;
- an **against-interest engine** that tells the user when not to buy, when to wait and where it is cheaper;
- a suggestion tray, level-gated cart filling, push notifications with caps, wait reminders and availability subscriptions;
- weekly grocery shopping with model composition, substitutions and standing orders with recurring payment;
- feedback on suggestions and a **trust ledger** the user can read;
- the chat-side content services the Ægil chat needs (shopping list, comparisons, tracking snapshot, guides);
- a full action log, notification-centre items, panel views, metrics and rollout.

Covers the Laravel monolith, the Feed service as a signal source, the agent layer (`agent.aegil_customer`), the customer app and the admin panel. Out of scope: the rewards ledger internals (rewards spec), store-side features, the courier and store apps.

---

## 1. Principles (binding)

1. **Memory is the user's, shown in full.** Every preference and learned pattern that influences any suggestion or action is readable and deletable by the user.
2. **Automation level is explicit and server-enforced** at execution time. Five levels; default 2.
3. **Propose into a tray; touch the cart only by level.** Below level 3 nothing enters the cart without a tap. Level 3 merges with receipt and undo. Payment without a tap exists only at level 4 under a recurring agreement, a review window and caps.
4. **Every suggestion has a machine-readable reason** with a real signal behind it. The engine attaches reasons; the model never writes them.
5. **Learned patterns drive automation only after user confirmation.**
6. **Ægil tells the truth against Ærend's short-term interest** whenever the against-interest engine finds it worth saying (§6). This is a product feature with a log, not a tone.
7. **Notifications are capped by user choice, respect quiet hours, and map to one item each.**
8. **Everything Ægil does while the app is closed is logged and surfaced at next open.**
9. **The system runs fully with the model off.** The LLM is used at four bounded points — interpreting free text, daily re-ranking, weekly composition, and chat — inside constraints enforced by code, with deterministic fallbacks on timeout.
10. **The model chooses among candidates it was given; it never invents.** All model output is validated against eligibility, allergens, exclusions, caps and level before storage or action.
11. **Feedback closes the loop.** "Ikke for meg" changes memory and weights visibly; the user sees Ægil learn.

---

## 2. Automation levels and settings

| Level | Key | Proactive actions allowed | Payment |
|---|---|---|---|
| 0 | `ask_only` | none; no persistent memory unless the user adds it | tap |
| 1 | `suggest` | in-app highlights; tray entries when the app is open | tap |
| 2 | `notify_suggest` (default) | level 1 + tray entries while closed + pushes within caps + wait reminders | tap |
| 3 | `fill_cart` | level 2 + cart merge while closed, receipted | tap |
| 4 | `standing_grocery` | level 3 + standing weekly grocery order | recurring agreement, review window, caps |

`agent_settings`: `level`, `allowed_store_mode ∈ {all_nearby, favourites, list}`, `allowed_store_ids[]`, `allowed_categories[]`, `cap_per_order`, `cap_per_week`, `quiet_hours {start,end}` (default 21:00–08:00 local), `learning_enabled` (default true), `paused_until?`, `push_mode ∈ {never, daily, good_only}` (good_only = max 3 per rolling 7 days), `against_interest_enabled` (default true; the user may turn the *lines* off, never the logging), `read_aloud` (default false).

Level 4 requires an active recurring agreement (§11) or is rejected with `LEVEL_REQUIRES_RECURRING`. Level changes and pauses are audited.

---

## 3. Preference model

### 3.1 Stated preferences
```
preferences (id, customer_id, kind, value JSON, source stated|onboarding|chat|settings|feedback,
             created_at, deleted_at)
kind ∈ { category, cuisine, food, favourite_store, household_size, allergen, diet, dinner_day, dinner_time,
         exclusion_product, exclusion_store, notify_topic, note }
```
- Allergens and diet are **hard constraints** enforced in the engine at every level; never inferred, accepted only through explicit chips or an explicit statement the user confirms.
- Exclusions come from "Aldri dette", "Ikke for meg → Aldri dette" and settings.

### 3.2 Free-text interpretation
Text from onboarding ("Noe annet") or chat ("ikke koriander", "lett mat på hverdager") is interpreted once at write time by `agent.aegil_customer` into structured rows with `source = chat` and `value.raw` kept; the user sees the structured line and can remove it. On failure or timeout (5 s) the text is stored as `kind = note` and does not influence matching.

### 3.3 Learned patterns
```
learned_patterns (id, customer_id, type, params JSON, support_n, confidence, first_seen, last_seen,
                  state proposed|confirmed|rejected|paused, decided_at)
type ∈ { recurring_item, dinner_rhythm, usual_time, usual_store, usual_cuisine }
```
Derived nightly from delivered orders when `learning_enabled`. Thresholds: `recurring_item` when an identity appears in ≥ 3 of the last 6 grocery orders; `dinner_rhythm` when ≥ 3 of the last 5 occurrences of a weekday had a restaurant order within a 90-minute window; `usual_time` from the median order time with IQR < 2 h. Only `confirmed` patterns feed level 3–4 actions, rhythm pushes and wait recommendations; `proposed` patterns may rank suggestions at levels 1–2 with lower weight. Rejected patterns are not re-proposed for 90 days; turning learning off sets existing patterns `paused`.

### 3.4 Product identity
All matching and comparison is by `product_identity_id`, resolved from EAN via the licensed product database for groceries and from `store_product_id` for restaurant items. `product_identities (id, ean?, canonical_name, category_id)`; `store_products.product_identity_id` set at import and on upsert. `reference_prices (product_identity_id, store_id?, price, observed_at)` maintained from price history for offer deltas and comparisons.

---

## 4. Onboarding
Chip cards in the agent sheet; the client posts answers in one batch: `POST /me/preferences/batch { items, source:"onboarding" }` and `PATCH /me/agent_settings { level, push_mode, quiet_hours }`. Skips set `onboarding_state.skipped_at`; the invitation card is re-shown at most every 7 days (`GET /me/agent_state.invite_eligible`). Guests are offered onboarding after their first delivered order. The onboarding summary sentence is rendered by the model from the batch (5 s deadline; template fallback).

---

## 5. Signals, matching and re-ranking

### 5.1 Signal sources
| Signal | Source | Ingest |
|---|---|---|
| `offer` | Feed posts `type = tilbud` (webhook `feed.post.published`); `product.price_changed` with `delta < 0`; `forundringspose.available` | event |
| `arrival` | Feed posts `ny_i_hyllene`, `dagens_rett`; `product.upserted` at favourite stores | event |
| `rhythm` | confirmed `dinner_rhythm` / `recurring_item` | scheduler, 06:00 and `dinner_time − 2 h` |
| `threshold` | rewards engine `reward.threshold_near` | event |
| `availability` | `product.upserted` / `product.in_stock` for identities with an active subscription (§9.2) | event |
Normalised into `signals (id, type, product_identity_id?, store_id?, payload, valid_from, valid_to, created_at)`.

### 5.2 Match evaluation (deterministic)
Per signal and per candidate customer (index-driven on preference, pattern or subscription match):
1. **Eligibility:** level ≥ 1; not paused; store and category allowed; identity not excluded; allergens and diet satisfied; store deliverable to the default address.
2. **Score:** weighted sum from `policy.agent.match_weights` (versioned): stated match, confirmed pattern, proposed pattern (levels 1–2 only), recency of last purchase, offer delta vs. reference, feedback history on the identity and store (§12).
3. **Threshold:** score ≥ `policy.agent.match_threshold` → `suggestions` row in state `candidate`, reason `{code, params}` attached by the engine.
4. **Dedup:** one per `(customer_id, product_identity_id, store_id)`; better offers replace.
5. **Pool:** up to `policy.agent.candidate_pool` (default 20) per customer per day, by score.

Reason codes: `offer_liked_product`, `offer_liked_store`, `offer_cheaper_elsewhere`, `arrival_fav_store`, `arrival_liked_category`, `rhythm_dinner_day`, `rhythm_recurring_item`, `threshold_free_delivery`, `threshold_varde`, `availability_back`.

### 5.3 Daily re-ranking (the judgment step)
`rerank_daily` runs once per active customer per day (`dinner_time − 3 h` if a confirmed rhythm exists, else 10:00 local):
- **Input:** the candidate pool (identity, store, price, delta, reason code and params, score, last suggested and bought dates), the memory view, the last 14 days of suggestions with outcomes and feedback, weekday and season. Untrusted text in labelled fields (Ops spec §17.5).
- **Output:** an ordered subset of candidate ids ≤ `tray_size` (default 5) and an optional `hint` ≤ 12 words.
- **Validation in code:** ids must exist in the pool; eligibility, allergens, exclusions, caps and level re-checked; violations dropped and logged as `rerank_violation`.
- **Promotion:** validated ids become `open`; the rest stay `candidate` until expiry.
- **Fallback:** deadline 5 s or model off → engine top-N. `rerank_source ∈ {model, fallback}` stored.
- **Cost:** one call per active customer per day, batched; local model first, cloud fallback only when the local runtime is degraded.
Pushes are sent only for promoted suggestions.

---

## 6. Against-interest engine

The engine that makes Ægil trustworthy: it evaluates, at defined moments, whether the honest thing to say costs Ærend or the store a sale, and says it when the saving or the harm is real.

### 6.1 Checks
| Check | When | Condition | Line code |
|---|---|---|---|
| `cheaper_elsewhere` | a store product enters the cart or a proposal is built | same identity at an allowed, deliverable store with `effective_total` (price + delivery share) lower by ≥ `policy.ai.min_saving_kr` (default 20) or ≥ `policy.ai.min_saving_pct` (default 15 %) | `AI_CHEAPER_ELSEWHERE` |
| `wait_for_offer` | proposal or cart | a known upcoming offer on the identity within `policy.ai.wait_horizon_days` (default 4) from store-scheduled campaigns or a cyclic price pattern with confidence ≥ 0.7 | `AI_WAIT_FOR_OFFER` |
| `already_have` | grocery proposal or cart | the identity was delivered within `policy.ai.already_have_days` (default 2, per category) and is a confirmed recurring item | `AI_ALREADY_HAVE` |
| `store_unreliable` | store proposal | the store's window hit rate over the last 7 days < `policy.ai.reliability_floor` (default 80 %) with ≥ 10 orders | `AI_STORE_UNRELIABLE` |
| `threshold_trap` | cart | adding suggested items to reach a free-delivery threshold would cost more than the delivery fee saved | `AI_THRESHOLD_TRAP` |
| `not_needed` | chat proposals | the user asked for one thing and a bundle would add items outside the request | `AI_NOT_NEEDED` |

### 6.2 Behaviour
- The line is emitted as a structured `against_interest_events` row and rendered by the client as the first element of the turn (tweak T21), with the alternative as an action ("Bytt til Nordnes Fisk", "Minn meg torsdag", "Hopp over").
- `wait_for_offer` creates a `reminders` row when the user taps "Minn meg" (§9.1).
- Thresholds are policy keys so the business can tune how often Ægil speaks against a sale; **every evaluation is logged whether or not it fired**, so the effect on conversion and retention can be measured.
- The user can turn the lines off (`against_interest_enabled = false`); logging continues for the ledger.

```
against_interest_events (id, customer_id, check, fired bool, subject_type cart|proposal|chat, subject_id,
                         saving_kr?, alternative JSON, shown_at?, acted_at?, action?, created_at)
```

---

## 7. Suggestions, tray and cart merge
```
suggestions (id, customer_id, product_identity_id, store_product_id, store_id, signal_id, reason JSON, score,
             price, reference_price?, state candidate|open|dismissed|never|added|merged|expired,
             level_at_creation, rerank_source model|fallback|none, rerank_rank?, hint?, agent_run_id?,
             created_at, expires_at, decided_at)
```
- Tray: `GET /me/suggestions?state=open` → at most `tray_size`, by rank; expiry = signal `valid_to` or 72 h.
- Actions: `POST /me/suggestions/{id}/add | dismiss | never`; `never` creates an `exclusion_product`.
- Level-3 merge (`merge_level3` on `suggestion.open` while the app is closed): adds the store product to the server cart with `cart_lines.added_by = agent`, respecting `cap_per_order` (sum of agent lines) and `cap_per_week`; never changes user lines; if another store is in the cart and multi-store checkout is unsupported, routes to the tray with `merge_blocked_reason`. `POST /me/cart/lines/{id}/undo` removes the line.
- Every open suggestion is also written as a notification item (§16).

---

## 8. Push notifications
Sent by the push service on `suggestion.open`, `reminder.due`, `weekly.ready`, `cart.merged_by_agent` when `level ≥ 2`, `push_mode ≠ never`, outside quiet hours (deferred otherwise), within cap (`daily` = 1/day; `good_only` = 3 per rolling 7 days and score ≥ `policy.agent.push_threshold_good`). One push per item; deep links `aerend://item/{notification_id}`. Rhythm pushes at `dinner_time − 2 h`. `push_category = agent` is reserved and audited; Ærend marketing never uses it. `agent_push_log (customer_id, notification_id, category, sent_at, deferred_from?)`.

---

## 9. Reminders and availability subscriptions

### 9.1 Reminders (wait recommendations)
```
reminders (id, customer_id, product_identity_id?, store_id?, due_at, reason AI_WAIT_FOR_OFFER|user, state pending|sent|cancelled|acted)
```
Created by "Minn meg" on a wait line or by the user in chat ("minn meg om reker torsdag"). At `due_at` the engine verifies the offer is live; if it is, a suggestion with reason `offer_liked_product` is opened and pushed (counts against cap); if not, a notification item "Tilbudet kom ikke. Vil du kjøpe likevel?" is written without a push.

### 9.2 Availability subscriptions ("Si fra når det finnes")
```
availability_subscriptions (id, customer_id, product_identity_id|category_id, store_id?, state active|fulfilled|cancelled, created_at)
```
Created from `Ikke funnet` cards and chat. Fulfilled by `availability` signals through the normal matching path (reason `availability_back`); one notification per subscription; auto-cancel after 60 days.

---

## 10. Grocery: Handleliste, Middag, Ukens kurv

### 10.1 Handleliste
`shopping_list_items (id, customer_id, product_identity_id, preferred_store_id?, qty, source confirmed_pattern|manual|chat|recipe, active, updated_at)`. Confirmed `recurring_item` patterns create items; the chat's list card (T10) reads and writes the same table through the same endpoints, so the list is one list everywhere.

### 10.2 Middag denne uken
`dinner_plans (id, customer_id, week, day, choice_type restaurant|recipe|skip, store_product_id?, recipe_id?)`. Candidates from favourite stores and liked cuisines, recipe cards from the recipe source (open decision). Picking a recipe adds its missing ingredients to the list with `source = recipe`, subtracting confirmed recurring items assumed at home (T12).

### 10.3 Ukens kurv (build)
`weekly_orders (id, customer_id, week, state draft|ready|reviewed|placed|paid|cancelled, build_at, review_until, total, savings, lines JSON, compose_source model|fallback, agent_run_id?)`. The `weekly_build` job at `build_at` (default Monday 10:00):
1. Start from active list items and the dinner plan.
2. **Composition by the model (once per week):** input = list, confirmed dinner days, dish and recipe candidates, household, last four plans; output = selection among candidates plus quantities; validated in code (allergens, exclusions, caps, availability); invalid items replaced by engine defaults; deadline 30 s; fallback = highest-scored dish per day and pattern quantities. `compose_source` stored.
3. Store choice per identity: live offer (lowest effective price), then preferred store, then fewest stores overall; `savings = Σ(reference − price)` over offer lines. The against-interest checks `cheaper_elsewhere` and `already_have` run here and may drop or swap lines with a receipt.
4. Caps: drop lowest-score non-list items first; otherwise ask in review.
5. Substitutions for sold-out items with `substitution {reason, original}`; require `accept` at level 3; default accept at level 4 unless the line is `no_substitute`.
6. State `ready`; push "Ukeshandelen er klar. Du kan endre til kl. 18."

### 10.4 Level 3 checkout
Review and pay with one tap; the weekly order becomes one order per store through the standard path with `origin = weekly` and `source_post_id` where applicable.

### 10.5 Level 4 standing orders
`standing_orders (id, customer_id, weekday, slot, build_at, review_until, cap_per_week, recurring_agreement_id, state active|paused|ended, paused_until?, created_at, ended_at)`. Requires an active `recurring_agreements` row (Vipps). At `review_until` with state `ready|reviewed` the order is placed and charged; failure → not placed, standing order `paused`, push "Betalingen gikk ikke gjennom", panel exception `agent.weekly_payment_failed`. `pause | resume | end` are single calls; agreement revocation is separate. Receipts allow `not_next_time` per line. Consumer-law wording (withdrawal, cancellation, price changes between build and placement) is surfaced in the set-up sheet; the business owns the text.

---

## 11. Payments
Levels 0–3: existing checkout with a human tap. Level 4: Vipps recurring agreement with the agreement maximum set to `cap_per_week` plus delivery and updated when the cap changes. Refunds and problems follow the Ops spec.

---

## 12. Feedback and the trust ledger

### 12.1 Feedback on suggestions (T26)
```
suggestion_feedback (id, customer_id, suggestion_id, verdict good|not_for_me, reason too_expensive|wrong_store|dislike_item|never_this|other, created_at)
```
- `good` raises the weight of the reason code and identity for the customer; `not_for_me` lowers it; `wrong_store` adds a soft store demotion; `never_this` creates an `exclusion_product`; `dislike_item` adds a `food` preference with negative polarity. Each writes a receipt with undo.
- Weight adjustments are per customer, bounded (±30 % of base), and decay over 90 days.

### 12.2 Trust ledger (T23)
Computed monthly and on demand from real rows:
```
trust_ledger (customer_id, month, saved_kr, finds_applied, against_interest_shown, wait_recommended, cheaper_elsewhere_taken, computed_at)
```
- `saved_kr` = applied Funn deltas + accepted `cheaper_elsewhere` savings + offer savings in weekly orders (from `savings`).
- Shown in Meg ("Ægil sparte deg 214 kr denne måneden · sa fra om billigere 12 ganger · foreslo å vente 3 ganger") and in chat on request. Numbers reconcile with the rewards ledger where they overlap; nothing is estimated.

---

## 13. Action log ("Mens du var borte")
```
agent_actions (id, customer_id, type, subject_type, subject_id, summary JSON, undoable bool, undone_at?, seen_at?, created_at)
type ∈ { suggestion_opened, cart_merged, weekly_built, weekly_placed, push_sent, pattern_proposed, reminder_created, against_interest_shown }
```
`GET /me/agent_actions?unseen=true` feeds the Hjem card; `POST /me/agent_actions/seen`; `POST /me/agent_actions/{id}/undo` for `cart_merged` and `weekly_built`. Retention 30 days for the user view, 12 months in audit. Every action also exists as a notification item (§16).

---

## 14. Chat content services

The chat renders cards from these read models; none of them involve the model.

| Card (tweak) | Service | Endpoint |
|---|---|---|
| Handleliste (T10) | shopping list | `GET|POST|PATCH|DELETE /me/shopping_list/*`, `POST /me/shopping_list/to_cart` |
| Sammenlikning (T09) | comparison | `POST /compare { identities[] | intent, address }` → per-store totals incl. delivery, time, rating, best marked |
| Tilbudskort / Nyhetskort (T07/T08) | suggestions | `GET /me/suggestions`, `GET /feed/posts/{id}` |
| Ukesmeny / Oppskrift (T11/T12) | grocery | `GET|POST /me/dinner_plans/{week}`, `GET /recipes/{id}`, `POST /me/shopping_list/from_recipe` |
| Sporingskort (T14) | tracking snapshot | `GET /orders/{id}/tracking` (existing; lightweight `?fields=stage,window,courier_first_name`) |
| Kart-kort (T15) | places | `GET /stores/{id}/location` |
| Guide-kort (T13) | content | `GET /guides/{slug}` (static, versioned, bokmål) |
| Funn (T16) | rewards/AI | existing Funn endpoint; `POST /me/finds/{id}/apply` |
| Forundringspose (T17) | Forundringspose | existing endpoints |
| Belønningskort (T18) | rewards | `GET /me/rewards/next_threshold` |
| Kurvoversikt (T19) | cart | `GET /me/cart` |
| Ikke funnet (T20) | availability | `POST /me/availability_subscriptions` |
| Vent-anbefaling (T28) | against-interest | `against_interest_events` + `POST /me/reminders` |
| Startere / Hva kan Ægil (T33/T34) | starters | `GET /me/chat/starters` (from memory, time, rhythm) |

---

## 15. Agent-layer integration

| Point | Job | Input | May return | Cadence | Deadline / fallback |
|---|---|---|---|---|---|
| Interpret | preference write; chat | text, memory summary | structured preference rows (never allergens/diet) | on write | 5 s / store as `note` |
| Re-rank | `rerank_daily` (§5.3) | candidate pool, memory, 14-day outcomes and feedback, calendar | ordered subset ≤ `tray_size`, hint | daily | 5 s / engine top-N |
| Compose | `weekly_build` step 2 (§10.3) | list, dinner days, candidates, household, last four plans | selection + quantities | weekly | 30 s / engine defaults |
| Chat | agent sheet | conversation, memory, tool results | tool calls from the allowlist, language | per turn | 5 s per tool / template lines |

Chat tools (allowlist, all mapped to endpoints a tap would call): memory read/write, settings, tray actions, cart add/remove/swap (proposal → receipt → undo), shopping list, dinner plan, compare, tracking read, reminders, availability subscriptions, feedback, trust ledger read. **Never a model:** eligibility, scores, candidates, against-interest checks, pushes, merges, weekly build or placement, charging, hard constraints. Untrusted-text rules, caps, kill switch and audit per Ops spec §17.5; every invocation is an `agent_runs` row linked from what it influenced. Against-interest lines are rendered from `against_interest_events` codes with template sentences; the model may vary wording but not content.

---

## 16. Notification-centre items
Every proactive event writes a `notifications` row (type, sender `aegil|order|store|aerend`, title, detail, reason code, target deep link, read_at, muted-by-type support) consumed by the Varsler sheet and the bell. Types from this spec: `suggestion`, `rhythm`, `reward`, `reminder_due`, `reminder_missed`, `availability_back`, `weekly_ready`, `agent_action`, `pattern_proposed`. Mute by type writes `notify_topic` preferences. Pushes reference the item id.

---

## 17. API surface (customer app)
- **Memory:** `GET /me/memory`, `POST /me/preferences`, `POST /me/preferences/batch`, `DELETE /me/preferences/{id}`, `GET /me/patterns`, `POST /me/patterns/{id}/confirm | reject`, `POST /me/memory/forget_all`.
- **Settings:** `GET|PATCH /me/agent_settings`, `POST /me/agent/pause`, `GET /me/agent_state`.
- **Tray:** `GET /me/suggestions`, `POST /me/suggestions/{id}/add | dismiss | never`, `POST /me/cart/lines/{id}/undo`.
- **Feedback and ledger:** `POST /me/suggestions/{id}/feedback`, `GET /me/trust_ledger?month=`.
- **Against-interest:** `GET /me/against_interest?subject=` (for the client to render lines on cart views), `POST /me/against_interest/{id}/acted`.
- **Reminders and availability:** `POST /me/reminders`, `DELETE /me/reminders/{id}`, `POST /me/availability_subscriptions`, `DELETE /me/availability_subscriptions/{id}`.
- **Grocery:** shopping list, dinner plans, weekly orders (`review`, `checkout`, `lines/{line}/not_next_time`), standing orders (`pause | resume | end`), recurring agreements (`create`, `revoke`).
- **Chat services:** `POST /compare`, `GET /guides/{slug}`, `GET /me/chat/starters`, `GET /orders/{id}/tracking?fields=`.
- **Log and notifications:** `GET /me/agent_actions`, `POST /me/agent_actions/seen`, `POST /me/agent_actions/{id}/undo`, `GET /me/notifications`, `POST /me/notifications/{id}/read | mute_type`.
All mutations accept `Idempotency-Key`; 422 codes: `LEVEL_REQUIRES_RECURRING`, `CAP_EXCEEDED`, `STORE_NOT_ALLOWED`, `ALLERGEN_CONFLICT`, `MERGE_BLOCKED`, `WEEKLY_STATE_CONFLICT`, `OFFER_EXPIRED`, `REMINDER_DUPLICATE`; clients use `postAllowClientError`.

**Panel:** `GET /panel/agent/customers/{id}` (read-only plus pause and level downgrade with reason), `GET /panel/agent/metrics` (incl. against-interest fire rates and conversion deltas), `GET|POST /panel/policies` for `policy.agent.*` and `policy.ai.*`, exceptions `agent.weekly_payment_failed`, `agent.merge_blocked_repeat`, `agent.push_cap_anomaly`, `agent.rerank_violation_spike`.

---

## 18. Events
`preference.changed`, `pattern.proposed|confirmed|rejected|paused`, `signal.ingested`, `suggestion.candidate|open|added|dismissed|never|merged|expired`, `against_interest.evaluated|fired|acted`, `feedback.recorded`, `reminder.created|due|sent|missed`, `availability.subscribed|fulfilled`, `cart.merged_by_agent`, `push.sent|deferred`, `weekly.built|reviewed|placed|paid|failed`, `standing.created|paused|resumed|ended`, `trust_ledger.computed`, `agent.action_undone`, `memory.forgotten`, `notification.created|read|muted`.

---

## 19. Jobs
| Job | Cadence | Work |
|---|---|---|
| `learn_patterns` | nightly 03:00 | derive/propose patterns |
| `evaluate_signals` | on event + hourly | candidates; expiry |
| `rerank_daily` | daily per active customer, batched | model promotion; fallback |
| `against_interest_eval` | on cart change, proposal build, weekly build | checks and logging |
| `rhythm_scheduler` | 06:00 + `dinner_time − 2 h` | rhythm suggestions |
| `reminders_due` | every 5 min | verify and open/notify |
| `merge_level3` | on `suggestion.open` while closed | cart merge |
| `weekly_build` / `weekly_place` | per settings | build; place and charge |
| `push_dispatch` | on demand | caps and quiet hours |
| `trust_ledger_monthly` | 1st of month 05:00 | compute ledger |
| `expire` | hourly | suggestions, drafts, subscriptions |
Every job checks the current level and pause state at execution.

---

## 20. Data model (consolidated, new tables)
`preferences`, `learned_patterns`, `product_identities`, `reference_prices`, `signals`, `suggestions`, `against_interest_events`, `suggestion_feedback`, `trust_ledger`, `reminders`, `availability_subscriptions`, `shopping_list_items`, `dinner_plans`, `weekly_orders`, `standing_orders`, `recurring_agreements`, `agent_settings`, `agent_actions`, `agent_push_log`, `notifications`, `guides`. `cart_lines.added_by`, `orders.origin`, `orders.source_post_id`, `store_products.product_identity_id` as added columns. All customer-scoped tables carry `customer_id` and are covered by `forget_all` except order-derived history.

---

## 21. Client requirements (customer app)
Onboarding chip cards; memory section with delete and confirm; settings with levels and controls, level-4 flow with the Vipps recurring step; tray on Hjem; "Lagt i kurven · Angre" on agent lines; against-interest lines rendered first in the turn from event codes on chat and cart views; feedback marks under proposal cards; trust ledger in Meg; reminders and availability subscriptions from cards and chat; grocery screens (list, dinner plan, build with substitutions, review, checkout, standing management); "Mens du var borte" on cold open; notification items and deep links `aerend://item/*`, `aerend://weekly/*`; reason and against-interest sentences from codes via ARB (`lib/l10n/`), model-varied wording optional; push permission with reason; quiet hours in settings; `postAllowClientError` on all mutations.

---

## 22. Privacy and compliance
Preferences, patterns, suggestions, feedback, reminders, actions and pushes are personal data with purpose limited to personalisation; `forget_all` deletes them all. Allergens and diet are stated, never inferred. Learned patterns require `learning_enabled`. Recurring payments use the provider's agreement flow with cap, cadence, review window, pause and end shown in set-up and receipts; withdrawal and cancellation terms linked. Against-interest logging is internal analytics on the customer's own interactions and is deleted with `forget_all`. The agent push channel is logged and separate from marketing consent. The app targets adults; age-restricted identities are hard-excluded from suggestions, merges and weekly orders. Ægil discloses that it is an AI on first use and when asked.

---

## 23. Metrics
- Matching: suggestions created → added/merged/dismissed/never; tray dwell; undo rate at level 3 (target < 10 %); reason-code undo rates (review > 25 %).
- Re-ranking and composition: model vs fallback share; add and undo rates by `rerank_source`; edit and substitution rates by `compose_source`; violations; latency.
- **Against-interest:** evaluations, fire rate per check, acted rate, short-term conversion delta vs. control, 30/90-day retention delta for customers who saw ≥ 1 line — the number that justifies the feature.
- Feedback: verdict distribution; weight change effects on next-30-day add rate.
- Trust ledger: distribution of `saved_kr`; correlation with retention.
- Reminders and availability: due → live share; acted rate; subscription fulfilment time.
- Grocery: build → placed; savings per order; level-4 payment failures.
- Pushes: send/deferred/open → order; cap events. Onboarding completion and skips; memory size; pattern confirm/reject.

---

## 24. Edge cases
- Offer expires between suggestion and add → `OFFER_EXPIRED` with current price shown.
- Sold out at merge → no merge; tray with substitution.
- Level lowered while a merge is queued → routed to the tray.
- New allergen → violating open suggestions expire immediately.
- Address change → deliverability re-evaluated; undeliverable suggestions expire.
- `cheaper_elsewhere` store cannot deliver today → check not fired; logged with cause.
- Wait reminder due but offer not live → item without push; no suggestion.
- Model selects a stale candidate → dropped as `rerank_violation` with cause `stale`, not counted against the model.
- Local model runtime down → fallbacks; panel shows degraded; no user-visible failure.
- Level-4 charge fails → not placed, paused, push, exception; no silent retry.
- Feedback on an expired suggestion → recorded; weights updated; no receipt on a card that is gone.
- Two devices → server state; `seen` per customer.
- Feed service down → offer and arrival signals pause; rhythm, threshold and availability continue; panel shows the degraded source.
- App uninstalled → pushes fail silently; standing orders continue until paused by the user or a charge failure; pre-charge reminder e-mail is an open decision.

---

## 25. Rollout
1. **P1 Memory:** preferences, interpretation, onboarding, memory section, settings (levels 0–1 effective).
2. **P2 Matching and tray:** signals, engine, candidate pool, tray, reason codes, fallback promotion; notification items.
3. **P2b Re-ranking:** local model in shadow mode two weeks, live when its add rate ≥ fallback's.
4. **P3 Against-interest and feedback:** checks, logging, lines in chat and cart, feedback marks, trust ledger, reminders, availability subscriptions.
5. **P4 Pushes and level 2 default;** existing users opt in via the invitation card.
6. **P5 Level 3:** cart merge with caps, receipts, undo, "Mens du var borte".
7. **P6 Grocery:** list, dinner plan, weekly build with engine defaults, substitutions, level-3 checkout; chat list sync.
8. **P6b Composition:** model composition in shadow, then live when edit rates ≤ fallback's.
9. **P7 Level 4:** recurring agreements, standing orders, placement, panel exceptions.
Each phase behind flags with its own handoff document; the model is optional throughout.

---

## 26. Open decisions (business)
- Policy values: match weights and thresholds, push thresholds, caps, tray size, suggestion TTL, candidate pool size.
- **Against-interest thresholds:** `min_saving_kr` (proposed 20), `min_saving_pct` (proposed 15 %), `wait_horizon_days` (4), `reliability_floor` (80 %), and whether `store_unreliable` lines are shown to users or only used to demote — the balance between trust and merchant relations.
- Whether level 3 requires a confirmation sheet beyond the toggle.
- Level-4 consumer-law wording, pre-charge reminder e-mail, and price changes between build and placement.
- Multi-store checkout for weekly orders.
- Whether restaurant rhythm suggestions may pre-fill the cart at level 3.
- Recipe source for dinner cards.
- Whether the model may see product names in the first release or only identities and categories; whether the re-ranking `hint` is shown at launch.
- Whether "Ukens lille oppdrag" (tweak T32) ships at all.

---

## Appendix A — Sequences
**Level 2 offer with re-ranking**
```
Feed service ──feed.post.published (tilbud)──▶ signals ──▶ evaluate_signals ──▶ suggestions (candidate)
rerank_daily ──▶ model selects ≤ 5 ──▶ validation ──▶ open (rerank_source: model | fallback)
against_interest_eval on proposal ──▶ e.g. AI_CHEAPER_ELSEWHERE logged (fired or not)
notifications row ──▶ push_dispatch (level ≥ 2, cap, quiet hours) ──▶ push ──▶ tray card ──▶ add | dismiss | never | feedback
```
**Wait recommendation**
```
cart change ──▶ against_interest_eval ──▶ AI_WAIT_FOR_OFFER fired ──▶ line first in turn ──▶ "Minn meg" ──▶ reminders (pending)
reminders_due @ due_at ──▶ offer live? ──▶ yes: suggestion open + push · no: item "Tilbudet kom ikke…" without push
```
**Level 4 weekly order**
```
weekly_build ──▶ list + dinner days + candidates ──▶ model composes (30 s) | engine defaults ──▶ validation ──▶ store choice
  ──▶ against-interest checks (cheaper_elsewhere, already_have) ──▶ caps ──▶ substitutions ──▶ ready ──▶ push
weekly_place @ review_until ──▶ orders per store ──▶ charge via agreement ──▶ paid → receipts | failed → paused + exception
```

## Appendix B — Sample payloads
Suggestion
```json
{ "id": "sg_2b…", "product_identity_id": "pi_reker_500", "store_id": "s_torgboden", "price": 119, "reference_price": 149,
  "score": 0.83, "state": "open", "reason": { "code": "offer_liked_store", "params": { "store": "Torgboden", "delta": 30, "last_bought_at": "2026-08-28" } },
  "rerank_source": "model", "rerank_rank": 1, "hint": "Passer til torsdagsmiddagen", "agent_run_id": "ar_9e…", "expires_at": "2026-09-07T22:00:00Z" }
```
Against-interest event
```json
{ "id": "ai_71…", "check": "cheaper_elsewhere", "fired": true, "subject_type": "cart", "subject_id": "c_44…", "saving_kr": 30,
  "alternative": { "store_id": "s_nordnes", "store_product_id": "sp_88…", "effective_total": 149 }, "created_at": "2026-09-06T15:12:04Z" }
```
Trust ledger
```json
{ "customer_id": "cu_1…", "month": "2026-09", "saved_kr": 214, "finds_applied": 6, "against_interest_shown": 12, "wait_recommended": 3, "cheaper_elsewhere_taken": 4 }
```

## Appendix C — Chat tweak mapping (design brief T01–T34)

| Tweak | Reads / writes | Contract | New work |
|---|---|---|---|
| T01 Intent chips | conversation state | chat agent (§15) | — |
| T02 Slot chips | conversation state | chat agent | — |
| T03 Neste steg-bar | conversation state, cart | `GET /me/cart` | — |
| T04 Derfor-linje | `suggestions.reason`, compare results | engine reason codes | — |
| T05 Kvittering med Angre | cart, memory, settings | existing receipt/undo endpoints | — |
| T06 Stemme | client | `read_aloud` setting | — |
| T07 Tilbudskort | suggestions, reference prices | §7, §3.4 | — |
| T08 Nyhetskort | suggestions, feed posts | §7, Feed service | — |
| T09 Sammenlikning | comparison | `POST /compare` | **new endpoint** |
| T10 Handleliste-kort | shopping list | §10.1, `to_cart` | **new: chat sync + `to_cart`** |
| T11 Ukesmeny-kort | dinner plans, weekly build | §10.2–10.3 | — |
| T12 Oppskriftskort | recipes, list | `from_recipe` | **new: recipe source + endpoint** |
| T13 Guide-kort | guides | `GET /guides/{slug}` | **new: content store** |
| T14 Sporingskort | tracking snapshot | `?fields=` | minor |
| T15 Kart-kort | store location | existing | — |
| T16 Funn-kort | finds | existing | — |
| T17 Forundringspose-kort | Forundringspose | existing | — |
| T18 Belønningskort | rewards | `next_threshold` | minor |
| T19 Kurvoversikt | cart | existing | — |
| T20 Ikke funnet | availability | §9.2 | **new** |
| T21 Mot egen interesse | against-interest | §6 | **new engine** |
| T22 Sist sa du | memory | §3 | — |
| T23 Tillitsregnskap | trust ledger | §12.2 | **new** |
| T24 Ærlig usikkerhet | stock/feed freshness | `Sjekk` = live stock read | minor |
| T25 Små ritualer | time, weather, rhythm | `GET /me/chat/starters` | — |
| T26 Tilbakemelding | feedback | §12.1 | **new** |
| T27 Grenser og åpenhet | client | — | — |
| T28 Vent-anbefaling | against-interest, reminders | §6, §9.1 | **new** |
| T29 Kort stiger opp | client motion | — | — |
| T30 Ægil på kaien | agent states | Ops spec §17 | — |
| T31 Varde-stripe | rewards | `next_threshold` | — |
| T32 Ukens lille oppdrag | Syv fjell | rewards spec | open decision |
| T33 Hva kan Ægil | starters | `GET /me/chat/starters` | minor |
| T34 Startere | starters | `GET /me/chat/starters` | minor |
