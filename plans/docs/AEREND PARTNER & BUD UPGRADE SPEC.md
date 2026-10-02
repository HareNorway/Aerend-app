# Ærend — Partner ↔ Bud Interplay: Technical Specification

Version 1.0 · September 2026 · Status: for implementation review

This document specifies the infrastructure, state model, events, APIs and user flows that connect **Ærend Partner** (merchant app), **Ærend Bud** (courier app), the **customer app** and the **admin panel**. It is the source of truth for the "zero-touch" order flow: a store can run a full day without touching the app, the courier sees only the next stop, and the customer's tracking is always true.

Stack assumptions: Laravel 8 API (MySQL, Cloudinary, Cloudflare in front of `api.ailogistics.no`), Flutter for the three apps, Stripe and Vipps for payments, BankID via Idura (OIDC) for courier identity. All new work lands on dedicated feature branches; nothing touches `main`.

---

## 1. Principles

1. **Server-authoritative state.** Clients render state and emit events. No client derives or advances order state locally. Every transition is validated and applied on the server; clients reflect the result.
2. **Exception-only human input.** The normal order requires zero store taps and three courier taps (arrived, scan, delivered). Humans act only on the exceptions in §12.
3. **The courier is the sensor.** Courier arrival, waiting and the pickup scan are the hard timestamps that drive tracking and learning. The store's manual signals are optional accelerators.
4. **Honest tracking.** The customer sees a window, never a point; "Tilberedes" is shown only after the kitchen has demonstrably seen the order.
5. **Idempotent, ordered events.** Every client action carries an idempotency key and a client timestamp; the server orders by receipt but records both.
6. **Offline tolerated, never silent.** Actions taken offline queue locally, display as pending, and reconcile without loss.
7. **No paper.** Screens are tickets; the QR scan is the handoff.
8. **Same words everywhere.** State names, order codes and status strings are identical across the three apps and the panel.

---

## 2. Actors and surfaces

| Surface | Runtime | Role in the flow |
|---|---|---|
| Customer app | Flutter | Places orders, sees tracking, pays via Vipps/Stripe |
| Ærend Partner | Flutter, phone/tablet, App Store | Device roles Kasse / Kjøkken / Henting; heartbeats; optional Klar; exceptions |
| Ærend Bud | Flutter | Offers, live stages, scan, proof of delivery, problems, earnings |
| Admin panel | Laravel 8 web | Exceptions inbox, audit, overrides, store/courier settings |
| API + workers | Laravel 8 | Order state machine, time engine, dispatch, token service, escalation scheduler, settlement |
| Realtime | Pusher-protocol WebSocket (self-hosted Soketi recommended) + FCM/APNs push + polling fallback | State fan-out to all surfaces |
| Agents (OpenClaw) | separate hosts | Product onboarding drafts; communication (calls/SMS/WhatsApp) in the escalation ladder; settlement proposals for approval |

---

## 3. Identifiers and the order code

- `order.id` — UUID, internal.
- `order.short_code` — human code shown in all apps: `Æ-` + two digits + one check letter, e.g. `Æ-42K`. Unique per store per calendar day. Digits are a per-store daily sequence (01–99, then wraps to two-letter prefix if a store exceeds 99); the check letter is derived from `(store_id, day, seq)` mod 23 over an unambiguous alphabet (no I, L, O, Q, S, Z). Displayed in ARB as `{code}` with the Æ prefix hard-coded (brand string, not translated).
- `assignment.id` — one per courier per order (or per stacked run, see §9).
- `device.id` — per installed Partner instance, with role.

---

## 4. Order state machine

### 4.1 States

| State | Description | Customer status string (ARB key) |
|---|---|---|
| `placed` | Paid and created | `status.placed` — "Bekreftet" |
| `accepted` | Auto- or manually accepted | `status.accepted` — "Bekreftet · sendt til kjøkkenet" |
| `seen` | A human-facing store device has rendered the order (§7) | `status.preparing` — "Tilberedes" |
| `ready` | Optional; store signalled ready | `status.preparing` |
| `picked_up` | Courier scan validated | `status.on_the_way` — "På vei" |
| `arrived_customer` | Courier at drop geofence + tap | `status.at_door` — "Budet er ved døren" |
| `delivered` | Proof accepted | `status.delivered` — "Levert" |
| `cancelled` | Any terminal cancel; carries a reason | `status.cancelled` |
| `problem` | Sub-state flag, not a primary state; see §12 | problem-specific |

`ready` is optional: `seen → picked_up` is a legal transition. `seen` is also implied by `ready` and by `picked_up` (a scan on an unseen order sets `seen` with `source = scan` and logs an anomaly).

### 4.2 Transitions

| From → To | Trigger | Guard | Side effects |
|---|---|---|---|
| placed → accepted | `store.auto_accept` job, or Partner `POST /orders/{id}/accept` | store not paused; if auto: store liveness true (§7.1) | start time engine (§6); schedule dispatch (§9); schedule seen-escalation (§7.3) |
| accepted → seen | `POST /orders/{id}/seen` from a Kasse/Kjøkken device, or any Partner tap, or Ægil voice | device role ∈ {kasse, kjokken}; device alive | cancel escalation; customer status → preparing |
| seen → ready | Partner tap, voice "klar", or `POST /orders/{id}/ready` | — | re-time courier (target arrival = now + handoff buffer) |
| seen/ready → picked_up | `POST /pickups/scan` validated (§10) | assignment active; token valid; geofence ok | assignment → `en_route_drop`; customer → on_the_way; time engine learns (§6.5); waiting pay closes |
| picked_up → arrived_customer | Bud `POST /assignments/{id}/arrived_drop` | geofence ok or override reason | customer → at_door |
| arrived_customer → delivered | Bud `POST /assignments/{id}/proof` | proof matches `order.proof_type` | settlement lines; customer → delivered; rating scheduled +20 min |
| any → cancelled | customer (before seen), store reject, escalation policy, admin | reason required | refund per policy; courier compensation per policy (§11) |

Illegal transitions return HTTP 422 with business code `ORDER_STATE_CONFLICT` and the current state in the body. Flutter clients must use `postAllowClientError` for all transition calls so the body is read.

### 4.3 Assignment (courier) sub-machine

`offered → accepted → en_route_pickup → arrived_pickup → (waiting) → picked_up → en_route_drop → arrived_drop → delivered | released | failed`

- `offered` expires after `offer.expires_at` (default 40 s) → `expired`, next candidate.
- `released` = courier declined after acceptance within the grace window (§9.4) or a problem closed the run.
- `waiting` is a flag on `arrived_pickup` set by the server when `now > order.predicted_ready_at + waiting_threshold` (default 3 min), not by the courier.

### 4.4 Store availability machine

`open → paused_manual (15/30/60 min or until resumed) → open`
`open → paused_auto (liveness lost, or escalation step 3) → open (manual resume from any device)`
Customer app shows `store.paused` as "Åpner igjen snart"; new orders are blocked server-side regardless of client cache.

---

## 5. Event model

All state changes are persisted in `order_events` and fanned out.

```
order_events
  id, order_id, assignment_id?, type, actor_type (system|store_device|courier|customer|admin|agent),
  actor_id, device_id?, payload JSON, client_ts?, server_ts, idempotency_key (unique), lat?, lng?, accuracy?
```

- **Idempotency:** every client mutation sends `Idempotency-Key` (UUID v4 generated at action time and persisted in the client queue). Replays return the original response.
- **Ordering:** server applies in receipt order; `client_ts` is stored for analytics and for offline reconciliation (e.g., an offline scan at 18:04 that syncs at 18:09 is recorded as a pickup at 18:04 with `synced_at = 18:09`).
- **Fan-out channels:** `private-store.{store_id}`, `private-courier.{courier_id}`, `private-order.{order_id}` (customer). Events carry the full current order snapshot, not deltas, so any client can rebuild state from the last event.
- **Polling fallback:** `GET /stores/{id}/live` and `GET /couriers/me/live` return snapshots with an `etag`; clients poll every 10 s when the socket is down.

Event types: `order.placed`, `order.accepted`, `order.seen`, `order.ready`, `order.time_adjusted`, `order.picked_up`, `order.arrived_customer`, `order.delivered`, `order.cancelled`, `order.problem_opened`, `order.problem_closed`, `assignment.offered`, `assignment.accepted`, `assignment.declined`, `assignment.expired`, `assignment.arrived_pickup`, `assignment.waiting_started`, `assignment.released`, `store.paused`, `store.resumed`, `store.liveness_lost`, `store.liveness_restored`, `device.heartbeat` (not persisted per beat; last-seen only).

---

## 6. Time engine

The engine predicts when an order will be ready and turns that into (a) a dispatch target for the courier and (b) a delivery window for the customer.

### 6.1 Inputs
- Layer 1 — **store defaults**: `prep_default_normal_min`, `prep_default_busy_min` per store category, set at onboarding.
- Layer 2 — **learned**: per `(store_id, item_id | category, weekday, hour_bucket)` an exponentially weighted moving average of observed prep durations with a sample count.
- Layer 3 — **active adjustments**: per-order `+5/+10/+15`; store-level busy extension; capacity extension (§6.4).

### 6.2 Predicted ready time
```
base        = max over items in order of learned(item) if n ≥ 5 else learned(category) if n ≥ 5 else default(store)
queue_load  = number of orders in {accepted, seen, ready} at the store
capacity_ext= max(0, queue_load − store.capacity) × store.capacity_ext_min_per_order (default 2)
predicted_ready_at = accepted_at + base + capacity_ext + active_adjustments
confidence  = f(min sample n across items, variance)   // "high" | "medium" | "low"
```
Recalculated on: accept, seen, each item state change, `+N`, busy mode, capacity change, courier arrival (§6.5), and every 60 s while `accepted|seen`.

### 6.3 Customer window
```
courier_eta_drop = travel_estimate(store → customer, vehicle, time) + handoff_buffer (default 2 min)
window_start = predicted_ready_at + courier_eta_drop − w
window_end   = predicted_ready_at + courier_eta_drop + w
w = 4 min (high confidence) | 7 min (medium) | 10 min (low)
```
Displayed as `Kommer 18:12–18:22` in the customer app and as `kundeblikk` on the Partner card. The window is re-issued on every recalculation; the client shows the latest and never an earlier, narrower one that has been superseded.

### 6.4 Capacity and busy mode
- `store.capacity` = simultaneous orders the kitchen can hold. Above it, `capacity_ext` applies and Partner surfaces the busy control suggestion.
- Busy mode: `pause_new_orders(15|30|60 min)` or `extend_all(+N min)`; both are store-level adjustments with `expires_at`.

### 6.5 Learning from the courier
Observed prep duration for an order:
```
observed_ready_at = min(ready_at if set, scan_at − handoff_buffer)
observed_prep     = observed_ready_at − accepted_at
```
If the courier arrived before `observed_ready_at`, the arrival timestamp confirms the order was not ready and `waiting_started_at` is stored. Update the EWMA (α = 0.2) for each item bucket and the category bucket. Outliers beyond 3σ are stored but excluded from the average.

### 6.6 Assistert level
In `autodrift_level = assistert`, the store confirms or edits the predicted time on each order for the first 7 days (or first 50 orders). Confirmed values are added to the learned layer with double weight.

---

## 7. Auto-accept, liveness, seen-signal and escalation

### 7.1 Heartbeat and liveness
- Each Partner device sends `POST /devices/{id}/heartbeat` every 20 s while foregrounded, with `role`, `battery`, `volume_muted`, `online`. Server keeps `last_seen_at` only.
- `store.liveness = any device with role ∈ {kasse, kjokken} and last_seen_at ≥ now − 60 s`.
- Liveness lost → `store.liveness_lost` event → store `paused_auto` for new orders; existing orders continue. Liveness restored does **not** auto-resume; the store resumes with one tap after reading the explanation card.
- `autodrift_level ∈ {manuell, assistert, auto}`. Auto-accept requires liveness. In `manuell`, the accept job is skipped and a `NEW_ORDER_PENDING` push is sent.

### 7.2 Seen-signal
`POST /orders/{id}/seen` is sent by a Partner device when the order card is rendered at full size in the foreground on a Kasse or Kjøkken device for ≥ 1 s, or on any explicit tap, or on an Ægil voice reference to the code. The server accepts the first and ignores duplicates. Henting-role devices do not set `seen`.

### 7.3 Escalation ladder (scheduler)
Started at `accepted`; cancelled at `seen`.

| Step | Time after accept | Server action | Client behaviour |
|---|---|---|---|
| 1 | 0–60 s | push `ORDER_UNSEEN` to all store devices every 20 s | sound escalates; card pulses once per repeat |
| 2 | 120 s | push to devices with role `kasse` and to the owner's registered phone; enqueue `agent.call_store` (communication agent: call, then SMS/WhatsApp) | — |
| 3 | 240 s | `store.paused_auto`; order flagged `unseen_timeout`; exception created in panel inbox; customer offered `wait_new_window` or `cancel_full_refund` via push + in-app card | Partner shows the explanation card on next foreground |

If the courier has already been dispatched, the assignment is held at step 3 pending the customer's choice; a cancel releases the courier with `trip_compensation` (§11).

---

## 8. Device roles and registration

```
store_devices
  id, store_id, role (kasse|kjokken|henting), name, platform, push_token,
  last_seen_at, battery, muted, app_version, created_at
```
- Role is set once in Partner settings; multiple devices per store; all roles subscribe to `private-store.{id}`.
- Kjøkken and Henting request a wake lock and run full-screen; the app shows a persistent banner if `muted`, `battery < 15%` or offline.
- Henting devices pre-fetch pickup token batches (§10.2).

---

## 9. Dispatch and offers

### 9.1 Timing
Dispatch aims for courier arrival at `predicted_ready_at − arrival_lead` (default 2 min).
```
dispatch_at = predicted_ready_at − arrival_lead − travel_estimate(candidate → store)
```
Candidates are scored at `dispatch_at − 60 s` and the best is offered; if the store signals `ready` early, dispatch runs immediately.

### 9.2 Offer payload
```
offer { id, assignment_id, order_short_code, store {name, strok, lat, lng},
        drop_area (strøk only), distance_to_pickup_m, run_distance_m,
        pickup_at, delivery_window, payment {base, distance, expected_waiting: 0, stacked_bonus, total},
        stacked: bool, expires_at }
```
The full drop address is released on acceptance.

### 9.3 Autopilot
Courier limits stored server-side: `vehicle, max_pickup_distance_m, min_payment, areas[], accept_stacked`. When `autopilot = true`, the server accepts offers meeting the limits on the courier's behalf and emits `assignment.accepted {auto: true}`. The courier may **release** within `autopilot_grace` (20 s) without penalty; after that the store's timing depends on the assignment.

### 9.4 Decline, expiry and reassignment
- Decline or expiry → next candidate; the store's card ETA shows "Finner bud" until accepted. No acceptance rate is stored per courier for display; a `decline_count` exists for ops analytics only and is never exposed to the courier UI.
- Release after grace triggers reassignment and, if the run had started, `trip_compensation`.

### 9.5 Stacking
Two orders may be stacked when: same store or stores within 400 m, drop-offs within 1.5 km, and the second order's `predicted_ready_at` is within 6 min of the first's. A stacked run is one assignment with `orders[]`. The Henting display issues a **samle-QR** (§10.3). Payment shows the stack total before acceptance.

### 9.6 Courier location
Bud streams location every 10 s while `på vakt` and every 5 s while `på oppdrag` to `POST /couriers/me/location` (batched when offline). Server computes ETAs and forwards throttled positions (≤ 1 per 5 s) to the customer's channel only while `en_route_drop`.

---

## 10. Pickup handoff

### 10.1 Token design
Pickup QR payload is a compact signed token (JWS, ES256):
```
{ v:1, o:[order_id...], s:store_id, iat, exp, n:nonce, kid }
```
- `exp = iat + 60 s`; the Henting display renders a new token every 60 s from its batch.
- Signing key per environment with `kid`; public keys distributed to Bud via `GET /keys` (cached, refreshed daily and on `kid` miss).
- Screenshots are useless after 60 s; replays are rejected by nonce.

### 10.2 Offline batch
Henting devices request `POST /stores/{id}/pickup_tokens/batch` returning tokens for each active order for the next `N` minutes (default 180) in 60-s slices; the device selects by wall clock. Batches are refreshed whenever the device is online and an order changes.

### 10.3 Samle-QR
When ≥ 2 orders at the store share an assignment, the display shows one token with `o:[...]`. A scan on a samle-QR picks up all listed orders that are in `seen|ready`; any order not in a pickup-able state is excluded and reported in the scan response so the courier is told which bag is missing.

### 10.4 Scan validation (`POST /pickups/scan`)
Request: `{ token, assignment_id, lat, lng, accuracy, client_ts, idempotency_key }`.
Server checks, in order:
1. signature valid, `kid` known, `exp ≥ client_ts − 120 s` (allowing offline delay) and nonce unused;
2. `assignment_id` belongs to the authenticated courier and is active;
3. every `order_id` in the token belongs to the assignment and is in `seen|ready` (or `accepted`, which sets `seen` with anomaly);
4. distance(courier position, store position) ≤ 150 m or accuracy > 100 m with a logged warning;
5. apply `picked_up` to each order; close waiting; emit events.
Responses: `200 { picked_up:[...], excluded:[{order_id, reason}] }`; `422 SCAN_TOKEN_EXPIRED | SCAN_NOT_ASSIGNED | SCAN_STATE_CONFLICT | SCAN_OUT_OF_RANGE | SCAN_REPLAY`.

### 10.5 Fallbacks
1. **Typed code:** `POST /pickups/code { short_code, assignment_id, ... }`. Valid only for orders on the courier's assignment; same state and geofence checks. Works offline for the courier's assigned orders because the codes were delivered with the offer; the request queues.
2. **Store confirmation:** Partner `POST /orders/{id}/handoff_confirm` from any device; Bud receives `HANDOFF_PENDING_CONFIRM` and taps confirm → `picked_up` with `source = store_confirm`.
3. **Admin:** panel override with reason; audit-logged.

### 10.6 Offline scan on Bud
Bud verifies the JWS locally with the cached public key, checks `exp` against device time with a ±120 s tolerance, stores the scan in the outbox with `client_ts` and position, shows the stage as pending, and submits when online. If the server later rejects (e.g., reassignment happened), Bud surfaces the rejection with the reason and the problem flow.

### 10.7 Hylleplass
When an order enters `ready`, if `store.hylleplass_enabled`, the server assigns the lowest free slot in `A–F` (configurable) and releases it at `picked_up`. Shown on the Henting tile and on Bud's Skann screen.

### 10.8 Customer self-pickup
Orders with `fulfilment = pickup` carry the same short code and a customer QR (same token format, `aud: customer`). Partner scans with a Kasse device (`POST /pickups/customer_scan`) or taps "Utlevert" after reading the code; both set `delivered` with `proof_type = customer_pickup`.

---

## 11. Waiting pay and courier payment

### 11.1 Waiting
- `waiting_started_at = arrived_pickup_at` if `arrived_pickup_at > predicted_ready_at`; otherwise `predicted_ready_at`.
- Waiting pay accrues from `waiting_started_at + waiting_threshold` (default 3 min) until `picked_up`, at `waiting_rate_per_min`, capped at `waiting_cap_min` (default 20). Accrual is shown live on Bud and as "Bud venter · N min" on Partner.

### 11.2 Run payment
```
payment = base + distance_component(run_distance_m) + waiting_pay + stacked_bonus + tip (separate line)
```
Computed server-side at `delivered`; components are stored per assignment and exposed as-is to Bud. Tips flow through Stripe/Vipps as separate transfers and appear on the run within seconds of capture.

### 11.3 Compensation
- `trip_compensation` for runs cancelled after the courier started travelling: `base × 0.5 + distance travelled`, or a fixed amount, per business rule.
- Problem outcomes (§12) each define courier compensation.

### 11.4 Payout
Daily payout batch at 04:00 for balances above a minimum; Vipps or bank per courier settings. Pending amounts are labelled `pending` in the API and UI. A yearly CSV/PDF export endpoint exists for tax purposes.

---

## 12. Problems

`POST /assignments/{id}/problems { type, note?, photo_ids?, lat, lng }` opens a problem; the server drives the flow and closes it.

| Type | Courier flow | Store effect | Customer effect | Closure |
|---|---|---|---|---|
| `store_closed` / `store_not_started` | shows escalation status; waits or is released | triggers §7.3 ladder from step 2 | wait with new window or cancel/refund | by customer choice or timeout |
| `wrong_order` / `missing_item` | photo + item list; `take_anyway` or `wait_for_correct` | Trenger deg card with courier note | partial refund per policy | store or policy |
| `customer_unreachable` | relay call → SMS → wait `unreachable_wait` (default 8 min) → policy: `leave_at_door_photo` or `return_to_store` | none unless return | notifications; final status | policy |
| `wrong_address` | relay confirmation; corrected stop | none | address prompt | customer confirmation |
| `damage_incident` | photo + note; run closed | card | refund per policy | admin |

All problem outcomes write `courier_compensation` and `customer_refund` lines and emit events so all three surfaces show the same status.

---

## 13. Offline and synchronisation

### 13.1 Client outbox (both apps)
- Every mutation is written to a local outbox (`id, endpoint, payload, idempotency_key, client_ts, lat, lng, attempts, last_error`) before the request is attempted.
- The UI marks the corresponding element `pending` until the server responds 2xx or a terminal 4xx.
- Retry with exponential backoff (2 s → 60 s) while offline; on reconnect, drain in FIFO order.
- Terminal 422 business errors are surfaced to the user with the server message; the item is removed from the outbox.

### 13.2 Conflict rules
- Server state wins. If a queued action is no longer legal (e.g., an order was cancelled while the courier was offline), the server returns `ORDER_STATE_CONFLICT` and the client shows the current state with the reason.
- Timestamps: `client_ts` is stored for analytics and for computing waiting and prep durations when the action was taken offline; `server_ts` governs ordering.

### 13.3 Partner offline
- Snapshot cached; banner with `last_synced_at`.
- All devices offline > 60 s → `paused_auto` (server-side, via liveness).
- Henting keeps serving tokens from its batch.

---

## 14. Notifications

| Category | Recipient | Channel | Throttle |
|---|---|---|---|
| `NEW_ORDER` / `ORDER_UNSEEN` | store devices | push + in-app sound | ladder-defined |
| `COURIER_WAITING` | store devices | in-app | once per order |
| `OFFER` | courier | push + in-app | per offer |
| `TIME_ADJUSTED`, `STORE_PAUSED` | courier | in-app | per event |
| `STATUS_*` | customer | push + in-app | per transition, max 1 per 2 min except delivered |
| `PROBLEM_*` | store, customer, ops | per §12 | — |
| Feed follow pushes (customer app) | customer | push | 1 per store per day, 2 per day total, off by default |

Sound assets for store escalation are bundled; the app requests audio focus and overrides the ringer where the platform allows, and warns when it cannot.

---

## 15. Security and privacy

- **Courier identity:** BankID via Idura OIDC at onboarding; `courier.identity_verified_at`. Scans and proofs are attributed to the verified courier.
- **Store staff:** roles `drift`, `drift_menu`, `full`; device sessions are tied to a store, not to a person, but actions record `device_id` and the logged-in staff account when present.
- **Calls:** customer ↔ courier calls go through a relay/masked number provider; real numbers are never delivered to clients.
- **Door profiles:** `door_profiles (address_hash, door_line, entrance_photo_id, last_note, consent_at)`; created only with the customer's consent captured in the customer app; deletable by the customer; retention 24 months.
- **Tokens:** ES256 keys in the secrets store; rotation supported via `kid`; nonces kept for 10 min.
- **Geofences:** 150 m pickup, 100 m drop, with accuracy-aware overrides logged.
- **Audit:** every scan, override, problem and payout is in `audit_log` with actor, device and position.
- **Rate limits:** scan and code endpoints limited per courier (10/min) to prevent brute-forcing codes.

---

## 16. Admin panel

- **Exceptions inbox:** unseen timeouts, liveness losses, problems, failed scans, held assignments, payout failures; each with the timeline and one-click actions (resume store, reassign, refund, compensate).
- **Overrides:** state transitions with mandatory reason; token invalidation; manual handoff confirmation.
- **Settings:** per-store defaults, capacity, hylleplass, autodrift level, escalation timings; per-courier limits and verification status; global thresholds (waiting, geofence, offer expiry).
- **Views:** live map of assignments; store liveness board; time-engine accuracy dashboard (predicted vs observed).

---

## 17. Data model (new and changed tables)

```
orders               + short_code, autodrift_level_at_accept, predicted_ready_at, confidence,
                       window_start, window_end, seen_at, seen_source, ready_at, picked_up_at,
                       arrived_customer_at, delivered_at, proof_type, proof_media_id, hylleplass,
                       fulfilment (delivery|pickup), unseen_timeout (bool)
order_events         (see §5)
order_time_adjustments (order_id, delta_min, source, created_at, expires_at?)
store_settings       + autodrift_level, capacity, capacity_ext_min_per_order, hylleplass_enabled,
                       prep_default_normal_min, prep_default_busy_min, waiting_threshold_min
store_status         (store_id, state open|paused_manual|paused_auto, reason, until, changed_at)
store_devices        (see §8)
prep_stats           (store_id, item_id?, category_id?, weekday, hour_bucket, ewma_min, variance, n, updated_at)
assignments          (id, courier_id, state, orders[] via assignment_orders, offered_at, accepted_at, auto_accepted,
                       arrived_pickup_at, waiting_started_at, picked_up_at, arrived_drop_at, delivered_at,
                       payment_base, payment_distance, payment_waiting, payment_stack, tip, compensation, released_reason)
assignment_orders    (assignment_id, order_id, sequence)
offers               (id, assignment_id, courier_id, payload JSON, expires_at, response, responded_at)
courier_limits       (courier_id, vehicle, max_pickup_distance_m, min_payment, areas JSON, accept_stacked, autopilot)
courier_locations    (courier_id, lat, lng, accuracy, ts)  // ring buffer / TTL
pickup_tokens        (jti nonce, order_ids JSON, store_id, iat, exp, kid, used_at?)   // nonce ledger only
scans                (id, assignment_id, order_ids JSON, source (qr|code|store_confirm|admin), lat, lng, accuracy, client_ts, server_ts, result)
problems             (id, assignment_id, order_id, type, note, photos JSON, state, outcome, courier_compensation, customer_refund, opened_at, closed_at)
door_profiles        (see §15)
payouts / payout_lines (courier_id, period, amount, state pending|paid|failed, lines JSON)
audit_log            (actor_type, actor_id, device_id, action, target, reason, lat, lng, ts)
```

---

## 18. API surface (contract level)

Authentication: bearer tokens per app; Partner devices carry `X-Device-Id`. All mutations accept `Idempotency-Key`. Errors: 4xx with `{ code, message, state? }`; Flutter must call these with `postAllowClientError` to read 422 business codes.

**Partner**
- `POST /devices` (register with role) · `PATCH /devices/{id}` · `POST /devices/{id}/heartbeat`
- `GET /stores/{id}/live` (snapshot: orders, status, liveness, devices)
- `POST /orders/{id}/accept` · `POST /orders/{id}/seen` · `POST /orders/{id}/ready` · `POST /orders/{id}/time_adjust {delta_min}` · `POST /orders/{id}/reject {reason}` · `POST /orders/{id}/handoff_confirm`
- `POST /stores/{id}/pause {minutes}` · `POST /stores/{id}/extend_all {delta_min}` · `POST /stores/{id}/resume`
- `POST /stores/{id}/pickup_tokens/batch` · `POST /pickups/customer_scan`
- `PATCH /stores/{id}/settings` (autodrift level, capacity, defaults, hylleplass) · `GET /stores/{id}/prep_stats/summary`
- `POST /items/{id}/sold_out {until}` · menu, hours, photos, feed, settlement endpoints (existing, unchanged)

**Bud**
- `POST /couriers/me/shift {state, autopilot}` · `PATCH /couriers/me/limits` · `POST /couriers/me/location` (batch)
- `GET /couriers/me/live` · `POST /offers/{id}/accept` · `POST /offers/{id}/decline` · `POST /assignments/{id}/release`
- `POST /assignments/{id}/arrived_pickup` · `POST /pickups/scan` · `POST /pickups/code` · `POST /assignments/{id}/arrived_drop` · `POST /assignments/{id}/proof {type, media_id?, name?, code?}`
- `POST /assignments/{id}/problems` · `GET /assignments/{id}/problem` · `POST /assignments/{id}/problems/{pid}/choice`
- `GET /door_profiles?address_hash=` · `POST /door_profiles` (post-delivery note)
- `GET /couriers/me/earnings?period=` · `GET /couriers/me/payouts` · `GET /couriers/me/exports/{year}`
- `GET /keys` (JWKS for offline verification)

**Customer (additions)**
- `GET /orders/{id}/tracking` (state, window, courier first name, throttled position while on the way) · `POST /orders/{id}/unseen_choice {wait|cancel}` · `POST /orders/{id}/door_consent`

**Realtime channels:** `private-store.{id}`, `private-courier.{id}`, `private-order.{id}`.

---

## 19. Client requirements

**Partner (Flutter)**
- Device role in local settings; role-specific screens (Kasse, Kjøkken, Henting); wake lock in Kjøkken/Henting; foreground heartbeat; audio focus and escalation sounds; muted/battery/offline banner.
- Seen-signal emission on card render (≥ 1 s visible, foreground, role ∈ kasse|kjokken).
- Henting: token batch cache, QR rendering per 60-s slice, samle-QR grouping by assignment, hylleplass display.
- All strings via ARB (`lib/l10n/`); order code prefix `Æ-` is a brand constant.
- All transition calls via `postAllowClientError`.

**Bud (Flutter)**
- Background location with the platform's "while using / always" flow explained at onboarding; batching when offline.
- Camera scan with local JWS verification (ES256) using cached JWKS; outbox with pending UI; typed-code fallback.
- Geofence pre-arm (client-side hint only); every transition is a server call.
- Relay-call integration; proof capture to Cloudinary via signed upload; Night mode by sunset; Big-weather mode as a layout variant.
- Voice layer (Ægil) as an optional module; voice commands map to the same endpoints and never bypass validation.

**Admin (Laravel)**
- Exceptions inbox, overrides, settings, dashboards (§16); scheduler jobs: auto-accept, escalation ladder, dispatch, waiting accrual, payouts, token key rotation.

**Deploy safety (existing convention):** `php artisan route:list > /dev/null` pre-flight; production never runs `APP_ENV=local` or `APP_DEBUG=true`; no infrastructure specifics in tracked `.env` files.

---

## 20. Metrics and logging

- Time engine: predicted vs observed prep (MAE, per store, per confidence class); window hit rate (delivered within window).
- Store: liveness uptime; unseen-order rate; escalation step reached; average seen latency; auto-pause count.
- Courier: waiting minutes per run; scan success rate by source (qr/code/confirm); offline scan share; problem rate by type.
- Handoff: scan latency (arrival → scan); samle-QR usage; hylleplass usage.
- Money: waiting pay share; tips latency; payout failures.
- Structured logs for every scan validation failure with the failing check.

---

## 21. Edge cases

- Courier arrives before dispatch target because of fast travel: waiting starts at `predicted_ready_at`, not arrival; UI shows "Klar om N min".
- Store taps `ready` on an order whose courier is 10 min away: no penalty; the store sees the courier ETA; the time engine records the early ready.
- Scan of a token for an order already picked up (samle-QR with one done): excluded list in response; UI names the missing bag.
- Reassignment while the first courier is at the store: the first courier's scan fails `SCAN_NOT_ASSIGNED`; Bud shows the reassignment and releases with compensation.
- Device clock skew: server tolerates ±120 s on `exp`; larger skew is flagged to the store device with a banner.
- Two Henting devices at one store: both serve tokens; nonces are unique per token so double display is harmless.
- Order cancelled by escalation after the courier picked it up: impossible by guard (step 3 holds the assignment before pickup); if a race occurs, `ORDER_STATE_CONFLICT` and ops review.
- Customer changes address after acceptance: allowed only before `picked_up`, re-times the courier and re-issues the window.
- Autopilot accepted while the courier's app is backgrounded: offer push contains the run; the 20-s release window starts at delivery of the push, not at server acceptance.

---

## 22. Rollout

1. **Phase 0 — ledger and flags.** Feature ledger for both apps; feature flags per store (`autodrift`, `hylleplass`, `henting_display`) and per courier (`autopilot`, `voice`).
2. **Phase 1 — state machine and events.** New states, `order_events`, realtime fan-out, short codes, `seen`, snapshots. Customer status mapping. No behaviour change for stores yet (level `manuell`).
3. **Phase 2 — QR handoff.** Token service, Henting role, scan and fallbacks, offline verification in Bud. Runs alongside the existing pickup confirmation until stable.
4. **Phase 3 — time engine and dispatch timing.** Defaults, learning, windows, waiting accrual; `assistert` level for pilot stores.
5. **Phase 4 — auto-accept and escalation.** Liveness, ladder, agent calls, exceptions inbox; `auto` level for stores that completed the learning week.
6. **Phase 5 — autopilot, stacking, door profiles, voice.**
Each phase ships behind flags with its own handoff document in the repo, following the existing handoff convention (no individual names, any developer can pick it up).

---

## 23. Open decisions (business)

- Waiting threshold, rate and cap; trip compensation formula; problem compensation and refund policies.
- Daily payout via Vipps: provider agreement and minimum balance.
- Courier employment vs self-employment, and the corresponding earnings/export surfaces.
- Relay-number provider.
- Whether `unseen_timeout` cancellations charge the store, and after how many occurrences liveness pauses become a contract issue.
- Age-restricted goods handling (proof type `Med kode` plus BankID age check) — out of scope here, flagged for the customer-app spec.

---

## Appendix A — Sequence: normal order, zero store taps

```
Customer app        API/workers                 Partner devices            Bud
   │ place+pay ──────▶ order placed
   │                   auto-accept (liveness ok) ──▶ NEW_ORDER push, card rendered
   │  "Bekreftet"      start time engine, ladder    ──▶ POST /seen (Kjøkken card)
   │  "Tilberedes"  ◀─ seen; ladder cancelled
   │  window 18:12–22  dispatch_at computed ─────────────────────────────▶ OFFER
   │                   assignment accepted ◀────────────────────────────── accept/autopilot
   │                   card: "Bud kommer 18:05"   (Partner)
   │                   arrived_pickup ◀──────────────────────────────────── geofence + tap
   │                   Henting shows tile + QR
   │                   scan validated ◀──────────────────────────────────── POST /pickups/scan
   │  "På vei"         tile → Hentet; Kjøkken card gone; learn prep
   │  live position    arrived_drop ◀─────────────────────────────────────── geofence + tap
   │  "Ved døren"
   │  "Levert"      ◀─ proof accepted ◀──────────────────────────────────── photo
   │                   payment lines; payout batch; rating +20 min
```

## Appendix B — Sequence: unseen order

```
accept ──▶ ladder step 1 (0–60 s: pushes, sound)
       ──▶ step 2 (120 s: owner push + agent call/SMS)
       ──▶ step 3 (240 s: store paused_auto; exception; customer choice)
             ├─ wait: new window; ladder continues to seen
             └─ cancel: refund; courier released with trip_compensation if dispatched
store foreground ──▶ explanation card ──▶ POST /stores/{id}/resume
```

## Appendix C — Sample payloads

Scan request
```json
{ "token": "eyJhbGciOiJFUzI1NiIsImtpZCI6IjIwMjYtMDkifQ...", "assignment_id": "a_7f3…",
  "lat": 60.3975, "lng": 5.3245, "accuracy": 12, "client_ts": "2026-09-05T16:04:12Z",
  "idempotency_key": "6f1c…" }
```
Scan response
```json
{ "picked_up": ["o_1a2…"], "excluded": [], "order_states": { "o_1a2…": "picked_up" },
  "customer_status": "on_the_way", "next_stage": "en_route_drop" }
```
Order snapshot (subset, fanned out on every event)
```json
{ "id": "o_1a2…", "short_code": "Æ-42K", "state": "seen", "predicted_ready_at": "…16:05:00Z",
  "confidence": "high", "window": ["…16:12:00Z", "…16:22:00Z"], "hylleplass": null,
  "assignment": { "id": "a_7f3…", "courier_first_name": "Kari", "eta_pickup": "…16:05:00Z", "state": "en_route_pickup" },
  "waiting": null, "customer_view": "Tilberedes · 18:12–18:22", "problem": null }
```
