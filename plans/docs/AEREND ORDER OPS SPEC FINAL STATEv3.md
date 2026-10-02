# Ærend — Order Operations Platform: Technical Specification

Version 3.1 · September 2026 · Status: for implementation review
Change in 3.1: Ærend's own feed posts are produced and published by `agent.editorial` under rules (L2), not drafted for the panel; the panel monitors and retracts.
Supersedes v2.0 and is complete on its own. This version integrates the complete agent catalogue across the customer app, Ærend Partner, Ærend Bud and the admin panel. The Ægil Personal Shopping Agent spec v2.0 remains the companion for the customer app's memory, matching, re-ranking, composition, against-interest engine and grocery flows; its agents are listed here in the register and detailed there.

---

## 0. Scope

How orders flow between the **customer app**, **Ærend Partner** (merchant), **Ærend Bud** (courier), the **admin panel**, the **Laravel API** and its workers, the **Feed service** and the **agent layer**: state, events, timing, the paperless QR handoff, delivery code, money, problems, offline behaviour, notifications, feed integration, agents (all of them), the panel, security, data, APIs, client requirements, metrics, edge cases and rollout.

Stack: Laravel 8 API on DigitalOcean (Frankfurt), managed MySQL, Cloudinary, Cloudflare in front of `api.ailogistics.no`; Flutter for the three apps; Stripe and Vipps; BankID via Idura (OIDC); **Feed service as a separate TypeScript microservice (Fastify, repo `aerend-feed-service`)** with its own datastore; agent runtime (OpenClaw) with local models on the Ærend workstation and cloud fallback. All work on feature branches; nothing touches `main`.

---

## 1. Principles

1. **Server-authoritative state.** Clients render and emit; no client advances order state.
2. **Exception-only human input.** A normal order needs zero store taps and three courier taps.
3. **The courier is the sensor.** Arrival, waiting and the scan are the hard timestamps.
4. **Honest tracking.** Windows, never points; "Tilberedes" only after the kitchen has seen the order.
5. **Idempotent, ordered events.**
6. **Offline tolerated, never silent.**
7. **No paper.** Screens are tickets; the QR scan is the handoff.
8. **Same words everywhere.**
9. **Agents propose, the state machine executes.** No agent in the critical path; same APIs as humans with `actor_type = agent`, scoped allowlists; money computed by the policy engine, never by a model.
10. **One panel, one truth.** Every automatic action is visible with its reason within seconds.
11. **Service boundaries are explicit.** Monolith owns stores, products, orders, assignments, money; the Feed service owns posts, follows, unread, ranking.
12. **Every agent is optional.** The system runs fully with every agent off; kill switch per agent is a release requirement.
13. **The model chooses among candidates it was given; it never invents.** Model output is validated in code before it is stored, shown or acted on.

---

## 2. System overview

| Component | Runtime | Owns | Talks to |
|---|---|---|---|
| Customer app | Flutter | UI | API, realtime, Feed service, agent layer via API |
| Ærend Partner | Flutter, phone/tablet | Device roles Kasse / Kjøkken / Henting; heartbeats; back office | API, realtime, Feed service |
| Ærend Bud | Flutter | Offers, live stages, scan, proof, problems, earnings | API, realtime, telephony relay |
| Laravel API + workers | Laravel 8, MySQL | Orders, assignments, stores, products, devices, time engine, dispatch, tokens, escalation, settlement, policy engine, audit | everything |
| Feed service | TypeScript / Fastify | Posts, drafts, follows, unread, ranking, mix rule, attribution, health | API, clients, panel, agents |
| Realtime | Pusher-protocol WebSocket (Soketi) + FCM/APNs + polling | Snapshot fan-out | all clients |
| Admin panel | Laravel 8 web | Operations, exceptions, proposals, overrides, settings, flags, audit | API, Feed admin API, agent runtime |
| Agent layer | OpenClaw; local models first, cloud fallback for latency-critical agents | The register in §17.3 | API (scoped tokens), Feed service (drafts), telephony, media |
| Telephony / relay | external | Masked numbers, calls, SMS, WhatsApp | Bud, agent.comms |
| Payments | Stripe, Vipps (incl. recurring) | Charges, transfers, payouts | API |

### 2.1 Monolith ↔ Feed service
- Identity: `store_id`, `product_id`, `order_id`, `customer_id` minted by the monolith.
- Auth: service JWTs with `aud` and short TTL; clients call the Feed service with monolith tokens verified via JWKS.
- Webhooks to the Feed service (at-least-once, idempotent by `event_id`): `store.updated`, `store.status_changed`, `product.upserted`, `product.sold_out`, `product.price_changed`, `order.delivered {source_post_id?}`, `customer.deleted`.
- From the Feed service: `GET /feed/unread`, `GET /feed/posts/{id}`, `GET /feed/health`, post metrics; events `feed.post.published | flagged`, `feed.service.degraded`.
- Degradation: customer app hides unread and shows an empty state; Partner queues posts; panel shows red. No order path depends on the Feed service.

---

## 3. Identifiers and the order code
- `order.id` UUID; `order.short_code` `Æ-` + two digits + one check letter (e.g. `Æ-42K`), unique per store per day, unambiguous alphabet (no I, L, O, Q, S, Z); the `Æ-` prefix is a brand constant.
- `assignment.id` per courier run; `device.id` per Partner instance with role; `post.id` minted by the Feed service.

---

## 4. State machines

### 4.1 Order

| State | Description | Customer status (ARB key → bokmål) |
|---|---|---|
| `placed` | Paid and created | `status.placed` → "Bekreftet" |
| `accepted` | Auto- or manually accepted | `status.accepted` → "Bekreftet · sendt til kjøkkenet" |
| `seen` | A human-facing store device rendered the order (§7.2) | `status.preparing` → "Tilberedes" |
| `ready` | Optional; store signalled ready | `status.preparing` |
| `picked_up` | Courier scan validated | `status.on_the_way` → "På vei" |
| `arrived_customer` | Courier at drop geofence + tap | `status.at_door` → "Budet er ved døren" |
| `delivered` | Proof accepted | `status.delivered` → "Levert" |
| `cancelled` | Terminal, with reason | `status.cancelled` |

`ready` is optional: `seen → picked_up` is legal. `seen` is implied by `ready` and by `picked_up` (a scan on an unseen order sets `seen` with `source = scan` and logs an anomaly). `problem` is a flag on any non-terminal state (§13).

| From → To | Trigger | Guard | Side effects |
|---|---|---|---|
| placed → accepted | `store.auto_accept` job, or Partner `POST /orders/{id}/accept` | store not paused; if auto: liveness true (§7.1) | start time engine; schedule dispatch; start seen-escalation |
| accepted → seen | `POST /orders/{id}/seen` from a Kasse/Kjøkken device, any Partner tap, Ægil voice, or `agent_phone_confirm` | device alive and role ∈ {kasse, kjokken}, or agent run id present | cancel escalation; customer → preparing |
| seen → ready | tap, voice "klar", `POST /orders/{id}/ready` | — | re-time courier |
| seen/ready → picked_up | `POST /pickups/scan` or `/pickups/code` or store confirm (§10) | assignment active; token/code valid; geofence ok | assignment → `en_route_drop`; customer → on_the_way; time engine learns; waiting closes |
| picked_up → arrived_customer | Bud `POST /assignments/{id}/arrived_drop` | geofence ok or override reason | customer → at_door |
| arrived_customer → delivered | Bud `POST /assignments/{id}/proof` | proof matches `order.proof_type`; prevalidate verdict ≠ `retake` or courier overrode once | settlement lines; customer → delivered; rating +20 min; `order.delivered` webhook to Feed service if `source_post_id` |
| any → cancelled | customer (before seen), store reject, escalation policy, admin, agent proposal approved | reason required | refund per policy; courier compensation per policy |

Illegal transitions return `422 ORDER_STATE_CONFLICT` with the current state. Flutter clients call every transition with `postAllowClientError` so the body is read.

### 4.2 Assignment (courier run)
`offered → accepted → en_route_pickup → arrived_pickup → (waiting) → picked_up → en_route_drop → arrived_drop → delivered | released | failed`
- `offered` expires at `offer.expires_at` (default 40 s) → `expired`.
- `waiting` is set by the server when `now > order.predicted_ready_at + waiting_threshold` while `arrived_pickup`.
- `released` on courier release within grace, or when a problem closes the run.

### 4.3 Store availability
`open → paused_manual (15/30/60 min or until resumed) → open`
`open → paused_auto (liveness lost, escalation step 3, or all devices offline > 60 s) → open (manual resume)`
Customer app shows `paused` as "Åpner igjen snart"; new orders are blocked server-side.

### 4.4 Device
`registered → alive (heartbeat ≤ 60 s) → stale → alive`; roles `kasse | kjokken | henting`.

---

## 5. Event model and realtime

```
order_events
  id, order_id, assignment_id?, type, actor_type (system|store_device|courier|customer|admin|agent),
  actor_id, device_id?, agent_run_id?, payload JSON, client_ts?, server_ts,
  idempotency_key (unique), lat?, lng?, accuracy?
```
- **Idempotency:** `Idempotency-Key` on every mutation; replays return the original response.
- **Ordering:** applied in receipt order; `client_ts` stored for analytics and offline reconciliation (an offline scan at 18:04 synced at 18:09 is a pickup at 18:04 with `synced_at = 18:09`).
- **Fan-out:** channels `private-store.{id}`, `private-courier.{id}`, `private-order.{id}`, `private-panel.ops` (all events, throttled), `private-panel.store.{id}`. Events carry the full current snapshot, not deltas.
- **Polling fallback:** `GET /stores/{id}/live`, `GET /couriers/me/live`, `GET /panel/live` with `etag`, every 10 s when the socket is down.
- **Cross-service events:** outbound webhooks to the Feed service and inbound `feed.post.published` for the panel; all with `event_id` and retries.

Event types: `order.placed | accepted | seen | ready | time_adjusted | picked_up | arrived_customer | delivered | cancelled | problem_opened | problem_closed`, `assignment.offered | accepted | declined | expired | arrived_pickup | waiting_started | released`, `store.paused | resumed | liveness_lost | liveness_restored`, `agent.run_started | run_finished | proposal_created | proposal_decided | scope_denied | cap_hit`, `feed.post.published | post.flagged | service.degraded`.

---

## 6. Time engine

### 6.1 Layers
1. **Store defaults** per category: `prep_default_normal_min`, `prep_default_busy_min` (onboarding).
2. **Learned:** EWMA per `(store_id, item_id | category_id, weekday, hour_bucket)` with variance and sample count.
3. **Active adjustments:** per-order `+5/+10/+15`, store busy extension, capacity extension.

### 6.2 Predicted ready time
```
base         = max over items of learned(item) if n≥5 else learned(category) if n≥5 else default(store)
queue_load   = orders in {accepted, seen, ready} at the store
capacity_ext = max(0, queue_load − store.capacity) × store.capacity_ext_min_per_order (default 2)
predicted_ready_at = accepted_at + base + capacity_ext + active_adjustments
confidence   = high | medium | low from min(n) and variance
```
Recalculated on accept, seen, item changes, `+N`, busy mode, capacity change, courier arrival, and every 60 s while `accepted|seen`.

### 6.3 Customer window
```
courier_eta_drop = travel_estimate(store→customer, vehicle, time) + handoff_buffer (2 min)
window = [predicted_ready_at + courier_eta_drop − w, predicted_ready_at + courier_eta_drop + w]
w = 4 (high) | 7 (medium) | 10 (low) minutes
```
Shown as `Kommer 18:12–18:22` to the customer and as `kundeblikk` on Partner cards and Bud stages. Re-issued on every recalculation; a superseded narrower window is never shown again.

### 6.4 Capacity and busy mode
`store.capacity` = simultaneous orders the kitchen holds; above it `capacity_ext` applies and Partner surfaces the busy control. Busy mode = `pause_new_orders(15|30|60)` or `extend_all(+N)` with `expires_at`.

### 6.5 Learning from the courier
```
observed_ready_at = min(ready_at if set, scan_at − handoff_buffer)
observed_prep     = observed_ready_at − accepted_at
```
EWMA α = 0.2 per item and category bucket; outliers > 3σ stored but excluded. In `assistert` level, store-confirmed times count double for the first 7 days or 50 orders.

---

## 7. Auto-accept, liveness, seen-signal, escalation

### 7.1 Heartbeat and liveness
- `POST /devices/{id}/heartbeat` every 20 s while foregrounded: `role, battery, muted, online`. Server stores `last_seen_at` only.
- `liveness = any device with role ∈ {kasse, kjokken} and last_seen_at ≥ now − 60 s`.
- Liveness lost → `store.liveness_lost` → `paused_auto` for new orders; existing orders continue. Restored liveness does not auto-resume; the store resumes with one tap after the explanation card.
- `autodrift_level ∈ {manuell, assistert, auto}`; auto-accept requires liveness. In `manuell` the accept job is skipped and `NEW_ORDER_PENDING` is pushed.

### 7.2 Seen-signal
`POST /orders/{id}/seen` when the order card is rendered full-size in the foreground on a Kasse or Kjøkken device for ≥ 1 s, on any explicit tap, on an Ægil voice reference to the code, or from `agent.comms` with `source = agent_phone_confirm` and a required `agent_run_id`. First accepted, duplicates ignored. Henting devices never set `seen`.

### 7.3 Escalation ladder (scheduler; starts at accept, cancelled at seen)

| Step | After accept | Server action | Clients |
|---|---|---|---|
| 1 | 0–60 s | push `ORDER_UNSEEN` to all store devices every 20 s | sound escalates; card pulses per repeat |
| 2 | 120 s | push to `kasse` devices and the owner's phone; enqueue `agent.comms` call → SMS/WhatsApp (deadline 90 s) | — |
| 3 | 240 s | `paused_auto`; order flagged `unseen_timeout`; exception in the panel inbox; customer offered `wait_new_window` or `cancel_full_refund` | Partner shows the explanation card on next foreground |

If a courier is dispatched, the assignment is held at step 3 pending the customer's choice; cancel releases the courier with `trip_compensation`. If `agent.comms` misses its deadline, step 3 proceeds unchanged.

---

## 8. Device roles

```
store_devices (id, store_id, role, name, platform, push_token, last_seen_at, battery, muted, app_version, created_at)
```
Role set once in Partner settings; several devices per store; all subscribe to `private-store.{id}`. Kjøkken and Henting hold a wake lock and run full-screen; a persistent banner shows on `muted`, `battery < 15 %` or offline. Henting devices pre-fetch pickup token batches (§10.2).

---

## 9. Dispatch and offers

### 9.1 Timing
```
dispatch_at = predicted_ready_at − arrival_lead (2 min) − travel_estimate(candidate → store)
```
Candidates scored at `dispatch_at − 60 s`; if the store signals `ready` early, dispatch runs immediately.

### 9.2 Offer payload
```
offer { id, assignment_id, order_short_codes[], store {name, strok, lat, lng}, drop_area (strøk only),
        distance_to_pickup_m, run_distance_m, pickup_at, delivery_window,
        payment {base, distance, expected_waiting: 0, stacked_bonus, total}, stacked, expires_at }
```
Full drop address released on acceptance.

### 9.3 Autopilot
Server-side courier limits: `vehicle, max_pickup_distance_m, min_payment, areas[], accept_stacked`. With `autopilot = true` the server accepts qualifying offers and emits `assignment.accepted {auto: true}`; the courier may release within `autopilot_grace` (20 s) without penalty. The grace window starts at delivery of the push, not at server acceptance.

### 9.4 Decline, expiry, reassignment
Decline or expiry → next candidate; Partner shows "Finner bud" until accepted. No acceptance rate is exposed to couriers; `decline_count` exists for ops analytics only. Release after grace triggers reassignment and `trip_compensation` if travel had started.

### 9.5 Stacking
Allowed when: same store or stores within 400 m, drop-offs within 1.5 km, second order's `predicted_ready_at` within 6 min of the first. One assignment with `orders[]`; the Henting display issues a samle-QR (§10.3); payment shows the stack total before acceptance.

### 9.6 Courier location
Every 10 s while `på vakt`, 5 s while `på oppdrag`, batched when offline, to `POST /couriers/me/location`. Server computes ETAs; the customer channel receives throttled positions (≤ 1 per 5 s) only while `en_route_drop`. The panel map receives all positions at 5 s.

---

## 10. Pickup handoff

### 10.1 Token design
JWS (ES256): `{ v:1, o:[order_id…], s:store_id, iat, exp, n:nonce, kid }`, `exp = iat + 60 s`; the Henting display renders a new token every 60 s. Public keys via `GET /keys` (JWKS), cached daily and on `kid` miss. Replays rejected by nonce.

### 10.2 Offline batch
`POST /stores/{id}/pickup_tokens/batch` returns tokens per active order for the next 180 min in 60-s slices; the device picks by wall clock; refreshed whenever online and an order changes.

### 10.3 Samle-QR
When ≥ 2 orders share an assignment, one token with `o:[…]`. A scan picks up all listed orders in `seen|ready`; others are excluded and reported so the courier is told which bag is missing.

### 10.4 Scan validation — `POST /pickups/scan`
Request `{ token, assignment_id, lat, lng, accuracy, client_ts, idempotency_key }`. Checks in order: signature and `kid`; `exp ≥ client_ts − 120 s` and nonce unused; assignment belongs to the courier and is active; every order in the token is on the assignment and in `seen|ready` (or `accepted` → sets `seen` with anomaly); distance ≤ 150 m or accuracy > 100 m with a warning; apply `picked_up`, close waiting, emit events.
Responses: `200 { picked_up:[…], excluded:[{order_id, reason}] }`; `422 SCAN_TOKEN_EXPIRED | SCAN_NOT_ASSIGNED | SCAN_STATE_CONFLICT | SCAN_OUT_OF_RANGE | SCAN_REPLAY`.

### 10.5 Fallbacks, in order
1. **Typed code** `POST /pickups/code { short_code, assignment_id, … }` — same checks; works offline for the courier's assigned orders (codes delivered with the offer); queues.
2. **Store confirmation** Partner `POST /orders/{id}/handoff_confirm`; Bud receives `HANDOFF_PENDING_CONFIRM` and confirms → `picked_up {source: store_confirm}`.
3. **Panel override** with reason; audit-logged.

### 10.6 Offline scan on Bud
Local JWS verification with cached JWKS, `exp` tolerance ±120 s, outbox with `client_ts` and position, stage shown pending, submit when online; server rejections surfaced with reason and the problem flow.

### 10.7 Hylleplass
If `store.hylleplass_enabled`, the lowest free slot `A–F` is assigned at `ready` and released at `picked_up`; shown on the Henting tile and the Bud Skann screen.

### 10.8 Customer self-pickup
`fulfilment = pickup` orders carry the same short code and a customer QR (`aud: customer`). Partner scans with Kasse (`POST /pickups/customer_scan`) or taps "Utlevert" after reading the code → `delivered {proof_type: customer_pickup}`.

---

## 11. Delivery and proof

### 11.1 Proof types
`order.proof_type ∈ {door_photo (default), to_person_name, code}`, decided by the policy engine at order creation (§11.4) and stated on the Bud stage before arrival. Proof media uploads to Cloudinary via signed upload; `media_id` is referenced on the order.

### 11.2 Prevalidate
Bud calls `POST /assignments/{id}/proof/prevalidate {media_id}` before submitting a photo; `agent.photo_qa` returns `pass | retake | unavailable` within 5 s. `retake` shows one line ("For mørkt — ta et til"); at most one retake per delivery; `unavailable` never blocks.

### 11.3 Door profiles and the unreachable forløp
- `GET /door_profiles?address_hash=` before arrival; optional `POST /door_profiles` after delivery (note, entrance photo), only where the customer consented.
- **Customer unreachable:** one tap starts the forløp (relay call → SMS → `unreachable_wait` 8 min → policy outcome). For `door_photo` orders the outcome is `leave_at_door_photo`; for `code` orders it is always `return_to_store` (§11.4.6). Outcome and payment are displayed before the courier waits.

### 11.4 Delivery code (QR with PIN fallback)
Door photo proves that a bag stood at a door; a code proves that the right person received it. The code is a risk-based proof type, never the default: the delivery moment should stay quick and warm for the majority of orders. Bud reuses the pickup scan pattern so couriers learn one flow.

**11.4.1 Triggers (policy engine, at order creation; the courier never decides at the door)**
- Order value above `policy.delivery_code.value_threshold` (typically Mote, Interiør, Gaver).
- Age-restricted items: BankID age verification at checkout + code at the door + courier visual check; the alcohol rules are a separate policy area.
- Customer choice: "Krev kode ved levering" in Meg, or per order at checkout.
- Risk history: prior disputes on the address or account (`policy.delivery_code.dispute_threshold`).
- Business or reception deliveries where a named recipient signs.
The checkout states plainly that code orders cannot be left at the door.

**11.4.2 Token and PIN**
- **QR:** JWS (ES256) `{ v:1, o:[order_id], a:"delivery", iat, exp, n:nonce, kid }`, `exp = iat + 60 s`, rendered by the customer app from a pre-fetched batch (`GET /orders/{id}/delivery_tokens`, valid 180 min) so it works without network at the door.
- **PIN:** four digits, generated server-side at `picked_up`, stored hashed with a per-order salt, shown in the customer app and sent by SMS at `picked_up`. Static per order; never reused; expires at `delivered | cancelled`.

**11.4.3 Customer app**
When the assignment reaches `arrived_drop`, the tracking screen automatically shows a code card: QR large, the PIN beneath it at 40 pt, and the line "Vis denne til budet". The PIN can be read aloud without handing over the phone. The card is also reachable from the order at any time after `picked_up`.

**11.4.4 Bud**
The stage reads "Lever Æ-42K · kode kreves" from dispatch, so the courier is not surprised at the door. On arrival: **Skann** (same button as pickup). Validation (`POST /deliveries/scan {token, assignment_id, lat, lng, accuracy, client_ts, idempotency_key}`): signature and `kid`; `a = delivery`; `exp ≥ client_ts − 120 s`, nonce unused; the order is on the courier's assignment and in `arrived_customer`; distance ≤ 100 m of the drop or accuracy > 100 m with a warning; then `delivered {proof_type: code, proof_source: qr}`.
Fallback: **Tast PIN** (`POST /deliveries/code {pin, assignment_id, …}`), three attempts, then `DELIVERY_CODE_LOCKED` for that order; Bud then offers the risk fallback: photo + recipient first name, `delivered {proof_type: code, proof_source: fallback_photo_name}`, and the order is flagged `elevated_risk` in the panel with an exception of type `delivery.code_fallback`.
Offline: local JWS verification as for pickups; PIN entry queues and is validated on sync (the hash is not shipped to Bud); the stage shows pending.

**11.4.5 Responses**
`200 { delivered: true, proof_source }`; `422 DELIVERY_TOKEN_EXPIRED | DELIVERY_NOT_ASSIGNED | DELIVERY_STATE_CONFLICT | DELIVERY_OUT_OF_RANGE | DELIVERY_REPLAY | DELIVERY_PIN_WRONG {attempts_left} | DELIVERY_CODE_LOCKED`.

**11.4.6 Rules**
- A `code` order can never end in `leave_at_door_photo`. The unreachable forløp ends in `return_to_store`; the customer is charged per `policy.redelivery` and was told this at checkout.
- Rate limit: 3 PIN attempts per order, 10 scan/code calls per minute per courier.
- Every scan, PIN attempt and fallback is in `scans` (with `kind = delivery`) and `audit_log`.
- The customer's phone number never reaches Bud; SMS is sent by the platform.

### 11.5 Courier identity for the customer
Trust runs both ways at the door. The tracking screen shows the courier's first name, photo and a "BankID-verifisert" badge once the assignment is `en_route_drop`. Bud has an **ID-kort** screen (photo, first name, verification badge, order short code, live time) reachable in one tap from any live stage, so a courier can show it at the door when asked. No surname, no phone number, no vehicle registration.

---

## 12. Waiting pay, courier payment, payouts

- `waiting_started_at = max(arrived_pickup_at, predicted_ready_at)`; waiting pay accrues after `waiting_threshold` (3 min) at `waiting_rate_per_min`, capped at `waiting_cap_min` (20); shown live on Bud and as "Bud venter · N min" on Partner.
- `payment = base + distance_component + waiting_pay + stacked_bonus`; tips are a separate line and separate transfer, visible within seconds.
- `trip_compensation` for runs cancelled after travel started; problem outcomes define compensation (§13).
- Daily payout batch at 04:00 above a minimum, via Vipps or bank; `pending` labelled as such; yearly export endpoint.
- All amounts come from the **policy engine** (`policies` table keyed by `policy_key`, versioned); agents and humans reference keys, never type amounts, except admins with a reason.

---

## 13. Problems

`POST /assignments/{id}/problems { type, note?, photo_ids?, lat, lng }`. The server drives and closes the flow; `agent.exception_triage` proposes within 60 s; ops approves, or the policy default applies after `triage_timeout` (5 min).

| Type | Courier flow | Store | Customer | Closure |
|---|---|---|---|---|
| `store_closed` / `store_not_started` | escalation status; wait or release | ladder from step 2 | wait with new window or cancel/refund | customer choice or timeout |
| `wrong_order` / `missing_item` | photo + list; `take_anyway` or `wait_for_correct` | Trenger deg card with courier words | partial refund per policy | store or policy |
| `customer_unreachable` | §11 forløp | none unless return | notifications; final status | policy |
| `wrong_address` | relay confirmation; corrected stop | none | address prompt | customer |
| `damage_incident` | photo + note; run closed | card | refund per policy | admin/agent proposal |

Outcomes write `courier_compensation` and `customer_refund` lines by policy key and emit events to all surfaces.

---

**Addition in v3.0:** problems may also be opened by voice and photo through `agent.bud_problem` (§17.7 B2); `problems.source ∈ {tap, voice, photo}`.

---

## 14. Offline and synchronisation

- **Outbox (both apps):** `id, endpoint, payload, idempotency_key, client_ts, lat, lng, attempts, last_error`; UI `pending` until 2xx or terminal 4xx; backoff 2 s → 60 s; FIFO drain on reconnect; terminal 422 surfaced with the server message.
- **Conflicts:** server wins; `ORDER_STATE_CONFLICT` shows current state and reason. `client_ts` for durations, `server_ts` for order.
- **Partner offline:** snapshot cached with `last_synced_at`; all devices offline > 60 s → `paused_auto`; Henting serves tokens from its batch; feed posts queue locally.

---

## 15. Notifications

| Category | Recipient | Channel | Throttle |
|---|---|---|---|
| `NEW_ORDER` / `ORDER_UNSEEN` | store devices | push + in-app sound | ladder-defined |
| `COURIER_WAITING` | store devices | in-app | once per order |
| `OFFER` | courier | push + in-app | per offer |
| `TIME_ADJUSTED`, `STORE_PAUSED` | courier | in-app | per event |
| `STATUS_*` | customer | push + in-app | per transition, ≤ 1 per 2 min except delivered |
| `PROBLEM_*` | store, customer, ops | per §13 | — |
| Feed follow pushes | customer | push | 1 per store per day, 2 per day total, off by default |
| `PANEL_ALERT` | ops on-call | push/SMS/e-mail | per §18.9 |

Store escalation sounds are bundled; the app requests audio focus and overrides the ringer where allowed, and warns when it cannot.

---

## 16. Feed service integration

### 16.1 Ownership
The Feed service owns `posts`, `follows`, `unread_state`, `post_metrics`, ranking and the mix rule. The monolith owns stores, products, orders and settlement. Attribution links the two: a deep link from a post carries `post_id`; the customer app sends `source_post_id` on order creation; `order.delivered` is webhooked to the Feed service, which records reach → orders per post.

### 16.2 Senders and the mix rule (enforced in the Feed service ranking)
- Store posts: created by Partner (`POST /feed/posts` with store token), types `dagens_rett | ny_i_hyllene | bak_disken | apent_na | tilbud`, media 4:3 or 9:16 video, linked `product_id` optional.
- Ærend posts: created from the panel (`POST /feed/admin/posts`), types `redaksjonelt | kampanje | drift`; `drift` may be pinned with `pinned_until`.
- Mix rule in `I nærheten`: at most 1 Ærend post per 5 store posts, never two consecutive; `drift` exempt. Unread counts store posts only.
- Promo cards (Forundringspose, Fjordfiske) are Ærend-sent stream cards under the same mix rule, at most 1 per 6–8 posts, never adjacent; sourced from monolith endpoints (`GET /forundringsposer/nearby`) at render time so counts are real.

### 16.3 Ranking
`I nærheten`: chronological within 72 h, filtered to stores deliverable to the customer's address (the Feed service calls `GET /stores/deliverable?lat,lng` with a short cache), followed stores lifted slightly. No engagement ranking. `Følger`: chronological. `Fra Ærend`: Ærend posts only.

### 16.4 Unread and pushes
`GET /feed/unread` returns the count of unseen store posts in the customer's `I nærheten` window; reset per post when it has been on screen ≥ 1 s (`POST /feed/posts/{id}/seen`, batched). Follow pushes are sent by the Feed service through the monolith's push gateway with the throttles in §15.

### 16.5 Moderation and reporting
`POST /feed/posts/{id}/report` from the customer app; the Feed service flags and emits `feed.post.flagged` to the panel; ops hide or restore via the admin API. No public comments at launch.

### 16.6 Agent drafts
`agent.onboarding` and `agent.aegil_partner` write drafts to `POST /feed/drafts` (Feed service); a store publishes with one tap in Partner. Auto-drafts are created by the Feed service on `product.upserted` webhooks.

### 16.7 Health and degradation
`GET /feed/health` (datastore, queue depth, webhook lag, push gateway). The panel polls it every 30 s. On failure the customer app hides the unread count and shows the empty state; Partner queues posts; the monolith's order path is unaffected.

---

**Addition in v3.0:** `agent.campaign_planner` writes offer post drafts to the Feed service (`POST /feed/drafts`) and `agent.menu_copy` writes menu drafts in the monolith; both are published by the store's tap.

### 16.8 Ærend's own posts are automated (v3.1)
Posts from Ærend as sender (`sender_type = aerend`) are planned, written and published by `agent.editorial` under the rules in §17.7 X1, on behalf of the stores and to increase their sales, without manual work in the panel. The Feed service keeps enforcing the mix rule (1 Ærend per 5 store posts, never two in a row; `drift` exempt), so automation cannot crowd out store posts. The panel's Feed view becomes a monitoring surface: every agent post is visible before it goes live during a hold window, can be retracted in one tap, and each post type has its own kill switch. Store posts remain the store's; Ærend posts remain visibly Ærend's.

---

## 17. Agent layer

### 17.1 Placement rule
Agents optimise around the state machine; they never replace it. Deterministic, idempotent, auditable or sub-2-second work stays in code. Statistics are not agents. **Never agent-driven:** acceptance in the normal flow, assignment selection, scan and code validation, payout execution, refund amounts, pricing and commission, fraud decisions, any sub-2-second path.

### 17.2 Autonomy levels
| Level | Meaning | Requirement |
|---|---|---|
| L0 · Draft | Text or data a human reviews before it leaves the system | draft stored; approver recorded |
| L1 · Act-in-script | Fixed, versioned playbook; wording only | playbook in code |
| L2 · Act-under-cap | Allowlisted actions within hard limits | caps enforced by the API |
| L3 | Not used | — |

### 17.3 Register (all agents)

| Agent | Surface | Job | Level | Detailed in |
|---|---|---|---|---|
| `agent.exception_triage` | panel | timeline, classification, proposal with drafts | L0 | v2.0 §17.3 |
| `agent.comms` | ladder, stores, couriers | calls, SMS, WhatsApp; lookup answers | L1 | v2.0 §17.3 |
| `agent.onboarding` | Partner | menu extraction, EAN enrichment; **conversational store onboarding** | L0 | §17.7 P4 |
| `agent.photo_qa` | Partner, Bud | photo spec check; delivery proof check | L2 | v2.0 §17.3 |
| `agent.photo_enhance` | Partner | crop, relight, background, format | L2 | §17.7 P2 |
| `agent.menu_copy` | Partner | item descriptions from photo and name; allergen suggestions to confirm; categorisation | L0 | §17.7 P1 |
| `agent.campaign_planner` | Partner | offer proposals from the store's own data, with the feed post draft | L0 | §17.7 P3 |
| `agent.hours_exceptions` | Partner | free text → opening-hour exceptions | L0 | §17.7 P5 |
| `agent.settlement` | panel | payout batch proposals; anomalies | L0 | v2.0 |
| `agent.time_review` | panel, Partner | drift explanation and nudge | L0 | v2.0 |
| `agent.aegil_partner` | Partner | voice and chat operations | L2 | v2.0 |
| `agent.aegil_bud` | Bud | narration and stage commands | L2 | v2.0 |
| `agent.bud_translate` | Bud, Partner | multilingual live mode | L1 | §17.7 B1 |
| `agent.bud_problem` | Bud | voice and photo → problem type | L2 | §17.7 B2 |
| `agent.bud_door` | Bud | spoken door note → door profile | L0 | §17.7 B3 |
| `agent.bud_explain` | Bud | explain payment lines and payouts | L0 | §17.7 B4 |
| `agent.support_triage` | support | classify, resolve under cap, escalate | L2 | v2.0 |
| `agent.order_issue` | customer app | post-delivery issue self-service with photo | L2 | §17.7 C2 |
| `agent.gift` | customer app | gift shortlist and card text | L0 | §17.7 C1 |
| `agent.reorder_photo` | customer app | package photo → EAN → add | L1 | §17.7 C3 |
| `agent.door_interpret` | customer app | free text → door profile | L0 | §17.7 C4 |
| `agent.aegil_customer` | customer app | interpret, re-rank, compose, chat | L2 | Ægil spec v2.0 |
| `agent.feed_moderation` | Feed, panel | screen posts and reports | L0 | v2.0 |
| `agent.editorial` | Feed (Ærend sender), panel monitoring | plans, writes and publishes Ærend's feed posts on behalf of stores, under rules and caps | L2 | §17.7 X1 |
| `agent.anomaly_explain` | panel | explain rule-detected anomalies | L0 | §17.7 X2 |

### 17.4 Integration contract
Service tokens per agent bound to allowlists (`403 AGENT_SCOPE_DENIED`); `actor_type = agent`, `actor_id = agent.<name>@<version>`; no direct database writes; money by policy key only; human confirmation as an event; deadlines (L1/L2 5 s except comms 90 s and vision jobs 8 s; L0 60 s) with deterministic fallback; prompt, model and playbook versions pinned per run; every run an `agent_runs` row.

### 17.5 Guardrails
Untrusted text as labelled data with tool use disabled on mutation turns and `tainted` marking; hard caps server-side per agent per hour and per case; disclosure and consent (comms identifies itself; Ægil states it is an AI); PII minimisation with local models for addresses, door photos and proof photos; kill switch per agent tested before each phase; no agent-to-agent chaining without a human or deterministic step; vision agents never see images outside their job's subject (a proof photo, a menu photo, a package photo).

### 17.6 Hosting
Local models on the Ærend workstation for triage, vision, transcription, translation and drafting; cloud fallback for comms and any agent with a sub-10-second deadline on user-facing paths (translation, problem classification, reorder-by-photo); health, queue depth and deadline-hit rate per agent reported to the panel.

### 17.7 New agent specifications

Each entry: job · trigger and input · output and validation · UI surface · data · metrics · rollout flag. All follow §17.4–17.5.

#### Partner

**P1 · `agent.menu_copy` (L0)**
- Job: write the item description (bokmål, 1–2 sentences, the store's voice), propose allergens for confirmation, and propose a category, from the item photo and name.
- Trigger: item created or edited without a description; "Skriv beskrivelsen" tap in the item editor; batch during onboarding.
- Output: `menu_copy_drafts (id, store_id, item_id, description, allergens_proposed[], category_proposed, model, version, state draft|applied|discarded)`. Validation: description ≤ 240 chars, no prices or claims ("beste i byen") by rule; **allergens are never applied automatically** — they render as unchecked chips the store confirms.
- UI: the draft appears in the editor with "Bruk" / "Skriv om" / "Forkast"; onboarding shows a batch review list.
- Metrics: apply rate, edit distance before apply, items with descriptions before/after, conversion delta for items that gained a description.
- Flag `agent.menu_copy`; rollout A5.

**P2 · `agent.photo_enhance` (L2, blocks nothing)**
- Job: produce an enhanced variant of a store or item photo: crop to the required ratios (4:3 store, 1:1 item), exposure and white balance correction, background clean-up where the subject is isolated, format and size. Never alters the food or product itself (no generative fill, no replacement).
- Trigger: photo uploaded in Partner or captured in onboarding; `agent.photo_qa` verdict `retake` may suggest enhancement first.
- Output: `photo_enhancements (id, media_id, enhanced_media_id, operations[], model, version, accepted bool)`; the original is kept. Validation: operations from an allowlist (`crop, exposure, wb, bg_clean, resize`); a perceptual-diff guard rejects results that change the subject region beyond a threshold.
- UI: side-by-side "Original / Forbedret" with "Bruk forbedret"; default selection is the enhanced variant only if QA passed it.
- Metrics: accept rate, QA pass rate after enhancement, conversion delta for enhanced items.
- Flag `agent.photo_enhance`; rollout A5.

**P3 · `agent.campaign_planner` (L0)**
- Job: from the store's own data (hourly revenue, sold-out patterns, item margins where provided, feed attribution, weather), propose at most one campaign per week: item, discount, window, expected orders and revenue with a confidence label, and the feed post draft.
- Trigger: weekly job Sunday 18:00 per store with ≥ 4 weeks of data; "Foreslå en kampanje" in Butikk.
- Output: `campaign_proposals (id, store_id, item_id, discount_pct, window, expected_orders, expected_revenue, confidence, rationale JSON, post_draft_id, state proposed|published|dismissed)`. Validation: discount within `policy.campaign.max_discount_pct`; window inside opening hours; item available; expected numbers come from the deterministic forecast, the model writes the rationale and the post.
- UI: a card in Butikk and in Ukens melding: "Tirsdager er stille. 15 % på fiskesuppe 16–18? Forventet 12 ekstra bestillinger." with "Publiser" (creates the offer and the feed post) / "Endre" / "Ikke nå". Publishing is a human tap.
- Metrics: publish rate, realised vs expected orders, attributed revenue.
- Flag `agent.campaign_planner`; rollout A6.

**P4 · `agent.onboarding` — conversational onboarding (L0, extends the existing agent)**
- Job: replace the settings forms with five questions in chat: what the store sells, typical prep times normal and busy, how many orders the kitchen can hold at once, opening hours and exceptions, which devices will be used and where. Answers become `store_settings`, `prep_default_*`, `capacity`, hours, and device roles.
- Trigger: onboarding step 4–5; "Sett opp med Ægil".
- Output: a settings draft the store confirms on one summary screen ("Da har jeg satt: 12 min normalt, 18 min travelt, 8 samtidige, åpent 10–22…"). Validation: ranges from policy; nothing applied before the confirmation tap.
- Metrics: onboarding completion time, corrections on the summary screen.
- Flag `agent.onboarding_chat`; rollout A6.

**P5 · `agent.hours_exceptions` (L0)**
- Job: "stengt julaften, kort dag nyttårsaften 10–15" → structured exceptions.
- Trigger: free text in Åpningstider; holiday prompts.
- Output: `hours_exceptions` rows shown as a list the store confirms; the customer-facing sentence rendered from the structure.
- Flag `agent.hours_exceptions`; rollout A6.

#### Bud

**B1 · `agent.bud_translate` (L1)**
- Job: translate the live-stage fields into the courier's language and the courier's replies back to bokmål: stage instructions, door lines, customer notes, store handoff notes, problem outcomes, and the offer card's texts. Also available in Partner for staff whose language is not Norwegian (kitchen cards, Trenger deg).
- Trigger: `courier.language ≠ nb` (set in onboarding, changeable in settings); per field on render; cached per string and language.
- Output: `translations (hash, lang, text, model, version)` cache; fields render translated with the original one tap away ("Vis original"). Validation: numbers, codes (`Æ-42K`), addresses and times are passed through untouched by rule; the translation layer never rewrites a status word into a different status.
- Deadline 3 s per field; fallback shows the original bokmål.
- Metrics: coverage, fallback rate, problem rate for non-nb couriers before/after.
- Flag `agent.bud_translate`; rollout A4. Languages at launch: English, Polish, Ukrainian, Arabic, Somali, Tigrinya, Spanish, plus nynorsk rendering as a variant (business to confirm).

**B2 · `agent.bud_problem` (L2, classification only)**
- Job: from a spoken line and/or a photo at a live stage ("butikken er stengt", photo of a wrong bag), classify to the problem taxonomy (§13), prefill the note and photo, and open the problem through the same endpoint a tap would use.
- Trigger: the problem button held for voice, or "Problem" said to Ægil.
- Output: `POST /assignments/{id}/problems` with `source = voice|photo`, `agent_run_id`; the courier sees the prefilled sheet and confirms with one tap; nothing is filed without the tap. Validation: type from the enum; confidence < 0.7 → the sheet opens with the two most likely types selectable.
- Metrics: confirm rate, reclassification rate by ops, time from problem to filing.
- Flag `agent.bud_problem`; rollout A4.

**B3 · `agent.bud_door` (L0)**
- Job: after delivery, a spoken note ("inngang bak, kode 1234, ring på Hansen") becomes a structured `door_profiles` update; an entrance photo is stored with the note.
- Output: the structured line shown to the courier for one-tap confirm; codes are stored only where the customer consented to door profiles; otherwise the note is kept for the courier's own next visit only.
- Flag `agent.bud_door`; rollout A4.

**B4 · `agent.bud_explain` (L0)**
- Job: answer "hvorfor betaler denne 118?" and "når kommer pengene?" from the assignment's payment lines and payout state, in plain bokmål or the courier's language.
- Output: language only; never a number that is not on the lines. Deadline 5 s; fallback shows the lines.
- Flag `agent.bud_explain`; rollout A4.

#### Customer app

**C1 · `agent.gift` (L0)**
- Job: from a natural-language brief ("gave til mamma, 60 år, liker hage, under 600 kr, til lørdag"), produce three shortlisted gifts from local stores in Gaver and adjacent categories that can deliver by the date, each with a Derfor-line, and a draft card message the user can edit.
- Trigger: the Gaver category's "La Ægil finne en gave" chip; chat.
- Input: the brief, the memory view, the deterministic candidate set (`GET /gifts/candidates {budget, deliver_by, interests[], recipient_hints}` — catalogue filter by category tags, price, availability and delivery date). Output: an ordered subset ≤ 3 with reasons and the card text; validation: ids from the candidate set only, budget respected, delivery date feasible, no age-restricted items.
- UI: a gift card set in the chat with "Velg", "Se flere", "Endre kortet"; checkout adds a gift flag, the card text and optional gift wrapping if the store offers it.
- Data: `gift_requests (id, customer_id, brief, parsed JSON, candidates JSON, shortlist JSON, chosen_store_product_id?, card_text, created_at)`.
- Metrics: shortlist → order rate, edit rate on the card, Gaver conversion before/after.
- Flag `agent.gift`; rollout A5.

**C2 · `agent.order_issue` (L2 under cap)**
- Job: after delivery, "Noe galt med bestillingen?" opens a two-step sheet: photo (optional) and one line. The agent classifies (missing item, wrong item, damaged, cold/late, not delivered, other), maps to a policy key, and resolves instantly within `policy.issue.max_auto_amount` (credit or refund), else escalates to `agent.support_triage` / ops with everything attached.
- Input: the order, its timeline (windows, scan, proof photo), the customer's photo and text, the customer's issue history. Output: `order_issues (id, order_id, customer_id, type, photo_id?, text, policy_key, resolution auto_credit|auto_refund|escalated|denied, amount, agent_run_id, state)`. Validation: amount from policy; per-customer monthly cap; duplicate-issue guard; `denied` only by a human, never by the agent (the agent may only auto-resolve or escalate).
- UI: instant confirmation "Vi har lagt 89 kr på saldoen din. Beklager." or "Vi ser på det. Svar innen 30 minutter." with the case in Varsler.
- Metrics: auto-resolution share, time-to-resolution, reversal rate by ops, repeat-issue rate.
- Flag `agent.order_issue`; rollout A5.

**C3 · `agent.reorder_photo` (L1)**
- Job: a photo of a package or product → EAN or product recognition → the matching product identity at an allowed store → "Legg til" card.
- Input: the photo; the product database (EAN and images); the customer's allowed stores. Output: at most three identity candidates with confidence; below 0.6 the card asks "Var det denne?" with alternatives; nothing is added without a tap.
- Data: `reorder_scans (id, customer_id, media_id, candidates JSON, chosen_identity_id?, created_at)`; photos deleted after 24 h.
- Flag `agent.reorder_photo`; rollout A6.

**C4 · `agent.door_interpret` (L0)**
- Job: the address's free-text field ("tredje etasje, ring på Hansen, bakgården") → structured door profile fields (floor, bell name, entrance, code) the customer confirms; consent captured on the same sheet.
- Output: `door_profiles` proposal; validation: codes only stored with consent; the customer sees exactly what couriers will see.
- Flag `agent.door_interpret`; rollout A5.

#### Panel

**X1 · `agent.editorial` (L2, publish under rules)**
- Job: run Ærend's feed presence automatically. Plan what Ærend should say each day for each bydel, write it, and publish it as Ærend, so that stores get exposure and orders without anyone working in the panel. The deterministic planner decides *what* and *whom*; the model decides *wording*; the Feed service decides *placement* (mix rule); the panel can stop or retract.
- Post types the agent may publish autonomously — all factual, all resolvable to data:
  | Type | Fact source | Cadence cap |
  |---|---|---|
  | `ny_pa_aerend` — a store went live ("Ny på Ærend: Sandviken Bakeri · Bergensk") | `store.status_changed` first open, store profile, photos | once per store |
  | `nytt_i_hyllene` — round-up of new products at stores that did not post themselves | `product.upserted` in the last 48 h | 1 per bydel per day |
  | `tilbud_i_naerheten` — round-up of live offers and campaigns | offers, `campaign_proposals.published`, Forundringspose availability | 1 per bydel per day |
  | `apent_sent` — who is open late tonight | opening hours, current status | 1 per bydel per day, after 19:00 |
  | `populaert_i_kveld` — what people in the bydel ordered most tonight | delivered orders, ≥ 20 orders in the window | 1 per bydel per day |
  | `butikk_i_fokus` — a store spotlight for stores with no own post in 14 days | menu, photos, hours, Bergensk badge, attribution history | 1 per store per 14 days, 1 per bydel per day |
  | `drift` — service notices (weather, delays) | ops signals and weather | as needed, pinned ≤ 3 h |
  Types with claims, opinions or discounts not registered in the system are not in the allowlist and cannot be published.
- **Planner (deterministic, daily 09:00 and hourly refresh):** for each bydel, selects candidate posts by type caps, data thresholds (`policy.editorial.min_data` per type), store opt-in (§ below), fairness rotation (every eligible store is featured before any is featured twice; new stores and stores with the fewest orders in the last 14 days first), store reliability (window hit rate ≥ `policy.editorial.reliability_floor`, else no spotlight), photo availability (no spotlight without a QA-passed photo), and the Feed service's mix-rule capacity for the day (`GET /feed/admin/capacity?bydel`).
- **Writer (model):** receives the plan item with its facts (store names, products, times, prices, photos) and the editorial guidelines; returns title, body ≤ 280 chars, the photo selection from the given ids and a deep link target. Validation in code: every named store, product, price and time must resolve to the facts payload; banned-phrase list and a superlative classifier (`policy.editorial.banned_phrases`); no store named without opt-in; no discount named that is not live; bokmål only; deadline 20 s, fallback = template text per type.
- **Hold and publish:** the post is created in the Feed service as `scheduled` with `hold_until = now + policy.editorial.hold_minutes` (default 15) and appears in the panel's Feed view with **Trekk tilbake**; at `hold_until` it publishes unless retracted; `drift` posts publish immediately. Published posts carry `sender_type = aerend`, `origin = agent`, and, if the business decides so, a discreet disclosure line ("Skrevet automatisk av Ærend").
- **Store controls (Partner → Feed):** `store_editorial_settings (store_id, opt_in bool default true, frequency normal|less|none, updated_at)` with the toggle "Ærend kan skrive om butikken min" and a preview of the latest Ærend post about the store; **Skjul** on any post retracts it for that store and lowers frequency; attributed orders from Ærend posts appear in the store's feed metrics as "Fra Ærend". Stores are told at onboarding that Ærend writes about partners automatically and how to turn it off.
- **Panel controls:** Feed → Fra Ærend shows scheduled (in hold), published and retracted posts with facts, model version and attribution; per-type kill switches; caps editable in `policy.editorial.*`; a weekly digest of posts, reach and attributed orders; exception `editorial.validation_spike` when > 20 % of drafts fail validation in a day.
- **Data:** `editorial_plans (id, bydel, date, items JSON, computed_at)`, `editorial_posts (id, feed_post_id, type, bydel, store_ids JSON, facts JSON, model, version, hold_until, state scheduled|published|retracted|failed, retracted_by?, reason?, created_at)`, `store_editorial_settings`.
- **API:** `GET /panel/editorial/queue`, `POST /panel/editorial/{id}/retract {reason}`, `POST /panel/editorial/{id}/publish_now`, `PATCH /panel/policies/editorial`, `GET|PATCH /stores/{id}/editorial_settings` (Partner), Feed service `POST /feed/admin/posts {scheduled, hold_until}` and `GET /feed/admin/capacity`.
- **Metrics:** posts per type per bydel, reach, attributed orders per post and per store, share of stores featured per 30 days (fairness), retract rate, validation failure rate, store opt-out rate, mix-rule capacity used.
- **Never:** a post naming a store without opt-in; a claim not in the facts payload; a discount not live; more than the caps; publishing while a type's kill switch is on; a post about a store below the reliability floor; two Ærend posts in a row (enforced by the Feed service).
- Flag `agent.editorial`; rollout A5 in shadow (posts created as `scheduled` with an infinite hold, reviewed daily for two weeks), then live with the 15-minute hold.

**X2 · `agent.anomaly_explain` (L0)**
- Job: when rules flag an anomaly (referral fraud patterns, repeated scan failures, refund clusters, address anomalies), assemble the timeline and write a plain explanation and a suggested action for ops. The rules decide; the agent explains.
- Output: a panel proposal attached to the exception; never an automatic suspension, refund reversal or reward removal.
- Flag `agent.anomaly_explain`; rollout A5.

### 17.8 Agent data model (additions)
`agent_runs`, `agent_proposals`, `proof_checks`, `agent_limits` (v2.0) plus: `menu_copy_drafts`, `photo_enhancements`, `campaign_proposals`, `hours_exceptions`, `translations`, `gift_requests`, `order_issues`, `reorder_scans`, `door_profile_proposals`. `problems.source ∈ {tap, voice, photo}`; `door_profiles.consent_at` required for codes.

### 17.9 Agent API additions
- Partner: `POST /items/{id}/menu_copy`, `POST /media/{id}/enhance`, `GET /stores/{id}/campaign_proposals`, `POST /campaign_proposals/{id}/publish | dismiss`, `POST /stores/{id}/onboarding_chat/turn`, `POST /stores/{id}/hours_exceptions/parse`.
- Bud: `GET /translate?hash&lang` (cached), `POST /assignments/{id}/problems/classify {audio_id?|photo_id?|text}`, `POST /door_profiles/parse {audio_id|text}`, `POST /assignments/{id}/explain {question}`.
- Customer: `POST /gifts/brief`, `GET /gifts/candidates`, `POST /orders/{id}/issue`, `POST /reorder/scan`, `POST /addresses/{id}/door/parse`.
- Panel: `GET /panel/agents/*` (register, runs, proposals, limits, kill), `POST /feed/admin/drafts`, exception types `agent.*`.

---

## 18. Admin panel

The panel is the single operational view. It reads the monolith, the Feed service and the agent runtime, and it is the only place where humans override, approve or configure. It must remain fully functional with every agent off and with the Feed service down.

### 18.1 Roles and default views

| Role | Default landing | Can |
|---|---|---|
| `ops` (driftsvakt) | **Nå** | act on exceptions, approve proposals, override states, pause/resume stores, reassign couriers, contact parties |
| `support` | **Support** | work tickets, apply refunds within caps, read everything |
| `finance` | **Økonomi** | settlements, payouts, refunds review, exports |
| `management` | **Oversikt** | read everything, set policies and flags, manage users |
| `admin` | any | all of the above plus system settings and keys |

Views are permission-filtered, not duplicated; the same order timeline is visible to all roles.

### 18.2 Nå (live operations)
- **Header strip:** open stores / paused (manual, auto) / liveness lost; couriers på vakt / på oppdrag / autopilot; active orders by state; exceptions open; agent proposals awaiting; service health dots (API, realtime, Feed service, telephony, payments, agents).
- **Live map:** couriers (5-s positions), stores with liveness colour, active assignments as lines from store to drop; click any marker for the timeline.
- **Ladders in progress:** every order currently in the seen-escalation with its step and countdown; one-click call, pause, cancel with policy.
- **Waiting now:** couriers waiting at stores past threshold, with minutes and the store's predicted time.
- **Late windows:** orders whose window end is < 5 min away and not yet `arrived_customer`.
Everything on Nå updates from `private-panel.ops`; nothing on Nå requires an agent.

### 18.3 Unntak (exceptions inbox)
One queue with type filters: `unseen_timeout`, `liveness_lost`, `problem.*`, `scan_failed`, `delivery.code_fallback`, `assignment_held`, `payout_failed`, `feed.post.flagged`, `agent.scope_denied`, `agent.cap_hit`, `service.degraded`. Each item shows the full timeline (order events, agent runs, messages sent), the agent proposal if any (with drafts), the policy default that will apply at `triage_timeout`, and one-click actions: approve proposal, choose another policy outcome, resume store, reassign, refund by policy key, message customer/store/courier (relay), close with reason. SLA timers per type; auto-escalation to on-call (§18.9).

### 18.4 Butikker
- **Liveness board:** every store with status, devices (role, battery, muted, last heartbeat), autodrift level, capacity, queue depth, today's unseen count, average seen latency.
- **Store detail:** orders today with kundeblikk history; time-engine accuracy (predicted vs observed, by hour); prep defaults and learned layer (readable sentences); hylleplass; settings; feed posts and their attributed orders (from the Feed service); onboarding status and menu drafts pending approval; staff accounts.
- **Actions:** pause/resume with reason, set autodrift level, edit defaults and capacity, invalidate pickup tokens, force resync of devices, publish a drift post to the store's followers.

### 18.5 Bud
- **Shift board:** couriers by state, autopilot on/off with limits, current assignment, waiting minutes, today's runs and earnings.
- **Courier detail:** verification status (BankID), documents, limits, run history with payment lines, problems raised, offline-scan share, device and app version.
- **Actions:** message via relay, release/reassign with reason and compensation policy, suspend with reason (audit), adjust limits on request.

### 18.6 Agenter
- **Register:** every agent with level, version, model, hosting (local/cloud), health, queue depth, deadline-hit rate, tainted runs, scope denials, cap hits, kill switch.
- **Proposals:** all `agent_proposals` by state; bulk approve for low-risk types; override rate per agent.
- **Runs:** searchable `agent_runs` with input digest, tool calls, outcome, latency, cost; link to the exception or order.
- **Limits:** edit `agent_limits` with audit; changes take effect immediately.
Rule: no agent may be widened in scope from the panel without a recorded reason and a second approver for L2 mutations.

### 18.7 Feed
- **Health:** the Feed service health payload; webhook lag; push gateway status.
- **Ærend posts:** compose and schedule `redaksjonelt | kampanje | drift`, preview as the customer card, pin drift posts, expiry for offers; the mix rule preview shows where the post will land in a sample stream.
- **Moderation:** flagged posts with `agent.feed_moderation` proposals; hide/restore; store notification.
- **Performance:** posts, reach, attributed orders per store and per post; follow counts; unread distribution.

### 18.8 Ordrer, Tid, Økonomi, Support, System, Revisjon
- **Ordrer:** search by short code, customer, store, courier, date; the timeline view is the canonical debugging surface (events, agent runs, messages, scans with validation results, windows issued).
- **Tid:** time-engine dashboard — MAE by store and confidence, window hit rate, drift alerts, `agent.time_review` proposals.
- **Økonomi:** settlements per store, commission and fees, payout batches (courier and store), failures, refunds and compensations by policy key, exports (Fiken, Tripletex, PowerOffice), Stripe/Vipps reconciliation.
- **Support:** tickets with `agent.support_triage` classification and proposals, caps, linked orders; canned actions by policy key.
- **System:** service health (API, workers/queues, Soketi, Feed service, telephony, Stripe/Vipps, agent runtime), feature flags per store/courier/global, policy engine (versioned `policies`), escalation timings, thresholds, JWKS and key rotation, webhook delivery log, deploy info.
- **Revisjon:** `audit_log` search — actor (human, device, agent), action, target, reason, position, before/after.

### 18.9 Alerts and on-call
| Condition | Severity | Route |
|---|---|---|
| Any exception past SLA (unseen 5 min, problem 10 min, payout failure 1 h) | high | push + SMS to on-call |
| Liveness lost at ≥ 3 stores in 10 min, or realtime down | critical | call on-call |
| Feed service degraded > 5 min | medium | push |
| Agent deadline-hit rate > 20 % over 15 min, or any `cap_hit` | medium | push |
| Payment provider errors > 2 % over 10 min | critical | call |
Alert routing is configured in System; every alert links to the exception or dashboard.

### 18.10 Panel non-functional requirements
- Nå renders within 2 s from snapshot; live updates ≤ 3 s behind events.
- Every automatic action is visible with its reason within 5 s (`private-panel.ops`).
- Read paths never call agents synchronously; agent data is read from tables.
- Full functionality with the Feed service down (feed views show the health error) and with agents off (proposal columns empty, policy defaults still apply).
- All panel mutations require a reason for state overrides, refunds outside policy default, agent limit changes and suspensions; all are audit-logged.


### Additions in v3.0
**Feed → Fra Ærend** becomes a monitoring queue (scheduled in hold, published, retracted) with one-tap retract, per-type kill switches and the weekly digest; composing Ærend posts by hand remains possible but is no longer the normal path. **Agenter** shows the full register from §17.3 with per-agent health, proposals, runs, limits and kill switches, and per-agent outcome metrics from §17.7; **Unntak** gains `order_issue.escalated`, `campaign.anomaly`, `translation.fallback_spike`; **Butikker** shows menu-copy coverage and photo enhancement acceptance; **Support** shows auto-resolved order issues with reversal.


---

## 19. Security and privacy

- **Courier identity:** BankID via Idura at onboarding; `identity_verified_at`; scans and proofs attributed to the verified courier.
- **Store staff:** roles `drift | drift_menu | full`; device sessions tied to a store; actions record `device_id` and staff account when present.
- **Panel users:** SSO with MFA; roles per §18.1; session and IP logging.
- **Calls:** relay/masked numbers; real numbers never delivered to clients or agents.
- **Door profiles:** created only with customer consent; deletable; retention 24 months.
- **Tokens and keys:** ES256 keys in the secrets store, `kid` rotation; nonces kept 10 min; service JWTs short-lived with `aud`.
- **Geofences:** 150 m pickup, 100 m drop, accuracy-aware overrides logged.
- **Agents:** scoped tokens, caps, tainted-run marking, PII minimisation, kill switches (§17.5).
- **Feed service:** verifies user tokens against the monolith JWKS; admin API restricted to panel service identity.
- **Audit:** every scan, override, problem, payout, agent action, panel mutation and feed moderation in `audit_log`.
- **Rate limits:** scan/code 10 per min per courier; feed post 20 per day per store; panel exports throttled.
- **Deploy safety (existing convention):** `php artisan route:list > /dev/null` pre-flight; never `APP_ENV=local` or `APP_DEBUG=true` in production; no infrastructure specifics in tracked `.env`.


### Additions in v3.0
vision agents receive only the media for their job and never the user's gallery; photos for `reorder_scan` are deleted after 24 h; translations are cached by content hash with no customer identifiers; door codes require consent and are encrypted at rest; `order_issue` amounts are policy-bound and audited; conversational onboarding stores only the confirmed settings, not the transcript beyond 30 days; courier language is a preference, not a protected attribute, and is never used for dispatch.


---

## 20. Data model

**Monolith (MySQL)**
```
orders                 + short_code, autodrift_level_at_accept, predicted_ready_at, confidence, window_start, window_end,
                         seen_at, seen_source, ready_at, picked_up_at, arrived_customer_at, delivered_at, proof_type,
                         proof_media_id, proof_source, hylleplass, fulfilment, unseen_timeout, source_post_id,
                         delivery_pin_hash?, delivery_pin_salt?, pin_attempts, elevated_risk
order_events           (see §5)
order_time_adjustments (order_id, delta_min, source, created_at, expires_at?)
store_settings         + autodrift_level, capacity, capacity_ext_min_per_order, hylleplass_enabled,
                         prep_default_normal_min, prep_default_busy_min, waiting_threshold_min
store_status           (store_id, state, reason, until, changed_at)
store_devices          (see §8)
prep_stats             (store_id, item_id?, category_id?, weekday, hour_bucket, ewma_min, variance, n, updated_at)
assignments            (id, courier_id, state, offered_at, accepted_at, auto_accepted, arrived_pickup_at, waiting_started_at,
                         picked_up_at, arrived_drop_at, delivered_at, payment_base, payment_distance, payment_waiting,
                         payment_stack, tip, compensation, released_reason)
assignment_orders      (assignment_id, order_id, sequence)
offers                 (id, assignment_id, courier_id, payload JSON, expires_at, response, responded_at)
courier_limits         (courier_id, vehicle, max_pickup_distance_m, min_payment, areas JSON, accept_stacked, autopilot)
courier_locations      (courier_id, lat, lng, accuracy, ts)  // TTL ring buffer
pickup_tokens          (jti, order_ids JSON, store_id, iat, exp, kid, used_at?)   // nonce ledger
scans                  (id, kind pickup|delivery, assignment_id, order_ids JSON, source, lat, lng, accuracy, client_ts, server_ts, result)
problems               (id, assignment_id, order_id, type, note, photos JSON, state, outcome, courier_compensation,
                         customer_refund, opened_at, closed_at)
door_profiles          (address_hash, door_line, entrance_photo_id, last_note, consent_at, updated_at)
policies               (policy_key, version, params JSON, active_from)
payouts / payout_lines (party_type, party_id, period, amount, state, lines JSON)
agent_runs             (id, agent, version, model, hosting, trigger_type, trigger_ref, input_digest, tainted, tool_calls JSON,
                         outcome, latency_ms, cost_tokens?, deadline_hit, created_at)
agent_proposals        (id, agent_run_id, subject_type, subject_id, proposal JSON, policy_key?, drafts JSON, state,
                         approver_id?, decided_at, applied_event_id?)
proof_checks           (id, assignment_id, media_id, checks JSON, verdict, reason_code, created_at)
agent_limits           (agent, window, max_calls, max_sms, max_mutations, max_case_amount, updated_at)
exceptions             (id, type, subject_type, subject_id, state, sla_due_at, assigned_to?, resolved_at, resolution JSON)
alerts                 (id, condition, severity, routed_to, fired_at, acked_at)
feature_flags          (key, scope_type, scope_id?, value, updated_by, updated_at)
webhook_deliveries     (id, target, event_id, status, attempts, last_error, delivered_at)
audit_log              (actor_type, actor_id, device_id?, agent_run_id?, action, target, reason, before JSON, after JSON, lat?, lng?, ts)
```

**Feed service (own datastore)**
```
posts                  (id, sender_type store|aerend, store_id?, type, media[], text, product_id?, pinned_until?, expires_at?,
                         state draft|scheduled|published|hidden, published_at)
drafts                 (id, store_id, source agent|auto|manual, payload, created_at)
follows                (customer_id, store_id, push_enabled, created_at)
post_seen              (customer_id, post_id, seen_at)
post_metrics           (post_id, impressions, taps, attributed_orders, updated_at)
reports                (id, post_id, customer_id, reason, created_at)
moderation_proposals   (id, post_id, agent_run_ref, proposal, state, decided_by, decided_at)
inbound_events         (event_id unique, type, payload, processed_at)
```


### Additions in v3.0
Monolith: the agent tables in §17.8, `editorial_plans`, `editorial_posts`, `store_editorial_settings`; `courier.language`; `store_staff.language`; `orders.gift {card_text, wrap}`; `orders.issue_id?`. Feed service: `drafts.source` gains `campaign_planner | editorial`.


---

## 21. API surface (contract level)

Auth: bearer tokens per app; Partner devices send `X-Device-Id`; agents use scoped service tokens; the Feed service verifies monolith tokens via JWKS. Every mutation accepts `Idempotency-Key`. Errors `{ code, message, state? }`; Flutter reads 422 bodies via `postAllowClientError`.

**Partner (monolith)** — `POST /devices`, `PATCH /devices/{id}`, `POST /devices/{id}/heartbeat`; `GET /stores/{id}/live`; `POST /orders/{id}/accept | seen | ready | time_adjust | reject | handoff_confirm`; `POST /stores/{id}/pause | extend_all | resume`; `POST /stores/{id}/pickup_tokens/batch`; `POST /pickups/customer_scan`; `PATCH /stores/{id}/settings`; `GET /stores/{id}/prep_stats/summary`; `POST /items/{id}/sold_out`; existing menu, hours, photos, settlement endpoints.
**Partner (Feed service)** — `POST /feed/posts`, `GET /feed/posts?store_id`, `GET /feed/drafts`, `POST /feed/drafts/{id}/publish`, `GET /feed/metrics?store_id`.

**Bud** — `POST /couriers/me/shift`, `PATCH /couriers/me/limits`, `POST /couriers/me/location`; `GET /couriers/me/live`; `POST /offers/{id}/accept | decline`; `POST /assignments/{id}/release | arrived_pickup | arrived_drop | proof | proof/prevalidate | problems`; `GET /assignments/{id}/problem`; `POST /assignments/{id}/problems/{pid}/choice`; `POST /pickups/scan | code`; `POST /deliveries/scan | code`; `GET /couriers/me/id_card`; `GET /door_profiles`, `POST /door_profiles`; `GET /couriers/me/earnings | payouts | exports/{year}`; `GET /keys`.

**Customer (additions)** — `GET /orders/{id}/tracking` (includes courier first name, photo and verification badge from `en_route_drop`); `GET /orders/{id}/delivery_tokens`; `POST /orders/{id}/unseen_choice`; `POST /orders/{id}/door_consent`; `PATCH /customers/me/settings {require_delivery_code}`; order creation accepts `source_post_id` and `require_delivery_code`. Feed: `GET /feed?tab`, `GET /feed/unread`, `POST /feed/posts/{id}/seen`, `POST /feed/follows`, `POST /feed/posts/{id}/report`.

**Panel** — `GET /panel/live`; `GET|POST /panel/exceptions/*`; `GET|POST /panel/proposals/*`; `POST /panel/orders/{id}/override {to_state, reason}`; `POST /panel/stores/{id}/pause | resume | settings | tokens/invalidate`; `POST /panel/assignments/{id}/reassign | release`; `POST /panel/refunds {order_id, policy_key, reason?}`; `GET|PATCH /panel/agents/*`, `POST /panel/agents/{agent}/kill`; `GET|PATCH /panel/flags`; `GET|POST /panel/policies`; `GET /panel/audit`; `GET /panel/health`. Feed admin: `POST /feed/admin/posts`, `POST /feed/admin/posts/{id}/hide | restore | pin`, `GET /feed/admin/flags`, `GET /feed/health`.

**Agents (internal)** — `POST /agents/{agent}/runs`, `GET /agents/{agent}/limits`; plus the per-agent allowlists in §17.3.

**Realtime channels** — `private-store.{id}`, `private-courier.{id}`, `private-order.{id}`, `private-panel.ops`, `private-panel.store.{id}`.

**Webhooks** — monolith → Feed service: `store.updated | store.status_changed | product.upserted | product.sold_out | order.delivered | customer.deleted`; Feed service → monolith/panel: `feed.post.published | feed.post.flagged | feed.service.degraded`.


### Additions in v3.0
Auth, idempotency and error rules unchanged; every agent-originated mutation goes through the same endpoints with an agent token.


---

## 22. Client requirements

**Partner (Flutter):** device role; role screens (Kasse, Kjøkken, Henting); wake lock; foreground heartbeat; audio focus and escalation sounds; muted/battery/offline banner; seen-signal on card render (≥ 1 s, foreground, role kasse|kjokken); Henting token batch cache, 60-s QR slices, samle-QR grouping, hylleplass; feed posting to the Feed service with local queue; ARB strings (`lib/l10n/`), `Æ-` as brand constant; `postAllowClientError` on transitions.

**Bud (Flutter):** background location with explained permissions; batching offline; camera scan with local ES256 verification via cached JWKS; outbox and pending UI; typed-code fallback; geofence pre-arm as a hint only; relay calls; proof upload via signed Cloudinary upload and `prevalidate`; delivery scan and PIN entry reusing the pickup scan module, with `kode kreves` shown from dispatch; ID-kort screen; Night mode by sunset; Big-weather layout variant; voice module mapping to the same endpoints.

**Customer app:** tracking view from `/tracking` with courier identity; the delivery code card shown automatically at `arrived_customer` for code orders, with pre-fetched tokens for offline display; `require_delivery_code` in settings and checkout with the return-to-store consequence stated; `unseen_choice` card; door consent; feed tabs from the Feed service; graceful degradation when the Feed service is down; `source_post_id` on orders from deep links.

**Panel (Laravel):** views per §18; subscriptions to `private-panel.*`; scheduler jobs: auto-accept, escalation, dispatch, waiting accrual, payouts, key rotation, webhook retries, alert evaluation; reads agent tables, never calls agents synchronously.

**Feed service (TypeScript/Fastify):** endpoints in §21; webhook consumer with `inbound_events` idempotency; ranking with the mix rule; unread computation; push via the monolith gateway; health endpoint; admin API restricted to the panel identity.


### Additions in v3.0
- **Partner:** menu-copy draft in the item editor; enhanced/original photo comparison; campaign card in Butikk and Ukens melding; conversational onboarding turns with a confirmation summary; hours-exception parsing; translated kitchen cards when staff language ≠ nb.
- **Bud:** language setting and translated fields with "Vis original"; hold-to-speak on the problem button with the prefilled sheet; spoken door note after delivery; "Forklar" on the run summary.
- **Customer:** "La Ægil finne en gave" in Gaver and chat; gift card set and card text at checkout; "Noe galt med bestillingen?" sheet after delivery; reorder-by-photo entry in Mat & fisk and the chat; door-text parsing in address editing with the consent line.
- **Panel:** register, metrics and controls for every agent.


---

## 23. Metrics

- **Time engine:** predicted vs observed prep (MAE by store and confidence); window hit rate.
- **Store:** liveness uptime; unseen-order rate; ladder step reached; seen latency; auto-pause count.
- **Courier:** waiting minutes per run; scan success by source; offline-scan share; problem rate by type; autopilot share.
- **Handoff:** arrival → scan latency; samle-QR and hylleplass usage; delivery-code share of orders, QR vs PIN vs fallback, PIN lock rate, dispute rate for code vs photo orders.
- **Money:** waiting pay share; tip latency; payout failures; refunds by policy key.
- **Feed:** posts per store per week; reach; attributed orders; unread distribution; service health.
- **Agents:** proposal acceptance and override rate; time-to-resolution vs baseline; deadline-hit rate; tainted runs; scope denials; cap hits; photo-QA retake and dispute rates; comms reach at step 2 and unseen orders resolved before step 3. Any agent overridden > 30 % is reviewed before widening scope.
- **Panel:** exception SLA attainment; time-to-first-action; alerts fired and acknowledged.
- Structured logs for every scan validation failure and every agent scope denial.


### Additions in v3.0
Per new agent as listed in §17.7, plus cross-cutting: share of store items with descriptions and enhanced photos; Gaver conversion; order-issue auto-resolution share and reversal rate; non-Norwegian-speaking courier problem rate before/after translation; campaign realised vs expected; conversational onboarding completion time. All agents: proposal acceptance, override rate, deadline-hit rate, tainted runs, scope denials, cap hits; any agent overridden > 30 % is reviewed before its scope is widened.


---

## 24. Edge cases

- Courier arrives before dispatch target: waiting starts at `predicted_ready_at`; UI shows "Klar om N min".
- Store taps `ready` with the courier 10 min away: no penalty; early ready recorded.
- Samle-QR with one order already picked up: excluded list names the missing bag.
- Reassignment while the first courier is at the store: `SCAN_NOT_ASSIGNED`; release with compensation.
- Device clock skew: ±120 s tolerated; larger skew flagged to the store device.
- Two Henting devices: both serve tokens; nonces unique per token.
- Cancel after pickup: prevented by guard (step 3 holds before pickup); races → `ORDER_STATE_CONFLICT` and ops review.
- Address change after acceptance: allowed before `picked_up`; re-times courier and window.
- Autopilot acceptance while Bud is backgrounded: grace starts at push delivery.
- Feed service down during a Partner post: queued locally; store sees "Publiseres når tjenesten er tilbake".
- Agent proposal approved after the policy default already applied: proposal marked `superseded`; no double action.
- `agent.comms` reaches the store but nobody confirms verbally: no `seen`; ladder continues.
- Panel override while an offline scan is queued: scan rejected on sync with reason; courier shown the current state.
- Code order, customer's phone dead: the PIN was also sent by SMS to the number on the order; if neither is available the fallback (photo + name, `elevated_risk`) applies and support reviews.
- Code order where the recipient is not the customer (family member): any holder of the code may receive; the code is the credential, not the person.
- Customer enables `require_delivery_code` after an order is placed: applies to the next order only.


### Additions in v3.0
- `menu_copy` for an item whose photo is missing: text-only draft, marked "uten bilde"; allergens still proposed for confirmation.
- `photo_enhance` result fails QA: original kept, no enhancement offered.
- `campaign_planner` proposes on an item that sells out early: the window is capped to the observed sell-out time.
- `bud_translate` fallback mid-run: the original renders; the stage never blocks.
- `bud_problem` low confidence: two types offered; the courier chooses.
- `gift` with no deliverable candidates by the date: honest card "Ingenting rekker fram til lørdag i Bergenhus. Vil du ha til mandag?".
- `order_issue` on an order with a code delivery and a valid PIN scan: auto-resolution limited to quality issues; "not delivered" escalates always.
- `reorder_photo` recognises an age-restricted product: no card; the category rule applies.
- `door_interpret` finds a code but no consent: the code is dropped and the user is told why.
- `editorial` draft references a store that pauses before publish: the draft is invalidated.


---

## 25. Rollout

Each phase ships behind flags with its own handoff document in the repo (existing convention: no individual names, any developer can pick it up). The system must be fully functional at every phase with all agents off.

1. **Phase 0 — ledger and flags.** Feature ledgers for Partner and Bud; flags per store/courier/global; panel System view with health and flags.
2. **Phase 1 — state machine, events, panel core.** New states, `order_events`, realtime, short codes, `seen`, snapshots, customer status mapping; panel Nå, Ordrer timeline, Revisjon. Stores stay at `manuell`.
3. **Phase 2 — QR handoff.** Token service, Henting role, scan and fallbacks, offline verification; panel scan diagnostics.
4. **Phase 3 — time engine and dispatch timing.** Defaults, learning, windows, waiting accrual; `assistert` for pilot stores; panel Tid.
5. **Phase 4 — auto-accept and escalation.** Liveness, ladder, exceptions inbox with SLAs and alerts; `auto` for stores past the learning week.
6. **Phase 5 — Feed integration.** Webhooks, attribution, unread, panel Feed view, Ærend posts, moderation.
7. **Phase 6 — autopilot, stacking, door profiles, voice.**

Agent track, each behind its own flag and shippable with the system fully functional when off:
- **A1** exception triage and settlement (L0).
- **A2** photo QA in shadow, then live.
- **A3** comms in the ladder after the ladder is stable.
- **A4** Bud agents: translate, problem by voice/photo, door note, explain.
- **A5** menu copy, photo enhancement, gift, order issue, door interpret, editorial (shadow two weeks, then live with hold), anomaly explain.
- **A6** campaign planner, conversational onboarding, hours exceptions, reorder by photo.
- **A7** Ægil in Partner and Bud voice mutations; support triage widening; feed moderation.
Customer-app shopping agent phases per the Ægil spec v2.0 §25.


---

## 26. Open decisions (business)

- Waiting threshold, rate and cap; trip compensation; problem compensation and refund policies (all as `policy_keys`).
- Daily payout via Vipps: provider agreement and minimum balance.
- Courier employment vs self-employment and the corresponding earnings/export surfaces.
- Relay-number provider; call recording consent wording and transcript retention.
- Whether `unseen_timeout` cancellations charge the store, and when repeated liveness loss becomes a contract issue.
- Agent hosting split (local vs cloud) and per-agent caps, including `max_case_amount` for support triage.
- `triage_timeout` value; exception SLAs; on-call rota.
- Ærend Direkte (store's own ordering link) — in scope for Partner's Butikk if enabled.
- Delivery code policy values: `value_threshold`, `dispute_threshold`, `policy.redelivery` charge for code orders returned to store; whether business deliveries default to code.
- Age-restricted goods: the alcohol and tobacco rules on top of the delivery code (BankID age check at checkout, courier visual check) — customer-app spec and legal review.

- languages at launch for `bud_translate` and whether nynorsk is offered
- `policy.issue.max_auto_amount` and monthly cap per customer
- `policy.campaign.max_discount_pct` and whether campaign proposals may include delivery-fee changes
- gift wrapping as a store capability
- retention of onboarding transcripts
- whether `photo_enhance` is on by default for new uploads
- the editorial guidelines document that `agent.editorial` must follow
- whether Ærend's automated posts carry a disclosure line ("Skrevet automatisk av Ærend") and its wording
- `policy.editorial.*` values: caps per type and bydel, hold window (proposed 15 min), reliability floor, minimum data per type, and whether stores are opted in by default.

---.

---

## Appendix A — Sequence: normal order, zero store taps
```
Customer app        API/workers                     Partner devices           Bud                    Panel
   │ place+pay ──────▶ placed
   │                  auto-accept (liveness) ─────▶ NEW_ORDER, card rendered                        Nå: order appears
   │ "Bekreftet"      time engine, ladder start   ──▶ POST /seen (Kjøkken)                          ladder shows, then clears
   │ "Tilberedes"  ◀─ seen; ladder cancelled
   │ window 18:12–22  dispatch_at ─────────────────────────────────────────▶ OFFER
   │                  accepted ◀───────────────────────────────────────────── accept/autopilot       map: assignment line
   │                  card "Bud kommer 18:05"
   │                  arrived_pickup ◀────────────────────────────────────── geofence + tap
   │                  Henting tile + QR
   │                  scan validated ◀──────────────────────────────────────── POST /pickups/scan   scan diagnostics
   │ "På vei"         tile → Hentet; Kjøkken card gone; learn prep
   │ live position    arrived_drop ◀─────────────────────────────────────────── geofence + tap
   │ "Ved døren"      prevalidate (photo QA) ◀────────────────────────────────── photo
   │ "Levert"      ◀─ proof accepted; payment lines; rating +20 min; webhook order.delivered → Feed service (attribution)
```

## Appendix B — Sequence: unseen order with agent and panel
```
accept ──▶ step 1 (0–60 s: pushes, sound)                          Panel Nå: ladder row
       ──▶ step 2 (120 s: owner push; agent.comms call/SMS, 90 s)   Panel: agent run visible
             ├─ verbal "ja, vi har den" ──▶ seen {agent_phone_confirm} ──▶ ladder cancelled
             └─ no confirmation ──▶ step 3 (240 s)
       ──▶ step 3: store paused_auto; exception (SLA 5 min); customer choice
             ├─ agent.exception_triage proposal (≤ 60 s) ──▶ ops approves, or policy default at triage_timeout
             ├─ wait: new window
             └─ cancel: refund; courier released with trip_compensation
store foreground ──▶ explanation card ──▶ POST /stores/{id}/resume     Panel: exception resolved
```

## Appendix B2 — Sequences added in v3.0
**Order issue, auto-resolved**
```
customer "Noe galt?" ──▶ photo + line ──▶ agent.order_issue classifies (5 s) ──▶ policy_key ──▶ amount from policy ≤ cap
   ──▶ credit to saldo ──▶ notification item ──▶ audit; over cap or "not delivered" ──▶ escalated ──▶ support/ops
```
**Courier problem by voice**
```
hold problem button ──▶ "butikken er stengt" ──▶ agent.bud_problem classify ──▶ prefilled sheet ──▶ courier confirms
   ──▶ POST /problems {source: voice} ──▶ normal §13 flow ──▶ Partner Trenger deg / ladder
```
**Automated Ærend post**
```
09:00 planner per bydel ──▶ candidates by type caps, opt-in, fairness rotation, reliability, photos, mix capacity
   ──▶ model writes (20 s) | template ──▶ validation (facts, banned phrases, opt-in, live discounts)
   ──▶ Feed service scheduled, hold 15 min ──▶ panel queue (Trekk tilbake) ──▶ published as Ærend ──▶ attribution
```
**Campaign proposal**
```
Sunday 18:00 ──▶ forecast (deterministic) ──▶ agent.campaign_planner writes rationale + post ──▶ Butikk card
   ──▶ "Publiser" ──▶ offer created (monolith) + post published (Feed service) ──▶ attribution
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
Order snapshot (subset)
```json
{ "id": "o_1a2…", "short_code": "Æ-42K", "state": "seen", "predicted_ready_at": "…16:05:00Z",
  "confidence": "high", "window": ["…16:12:00Z", "…16:22:00Z"], "hylleplass": null,
  "assignment": { "id": "a_7f3…", "courier_first_name": "Kari", "eta_pickup": "…16:05:00Z", "state": "en_route_pickup" },
  "waiting": null, "customer_view": "Tilberedes · 18:12–18:22", "problem": null, "source_post_id": "p_91…" }
```
Agent proposal
```json
{ "id": "ap_44…", "agent": "agent.exception_triage@1.3", "subject_type": "problem", "subject_id": "pr_8c…",
  "proposal": { "outcome": "partial_refund", "policy_key": "refund.missing_item.v2", "courier": "keep_run" },
  "drafts": { "customer": "Hei — en vare manglet…", "store": "…", "courier": "…" },
  "state": "open", "sla_due_at": "…16:20:00Z" }
```
Feed webhook (monolith → Feed service)
```json
{ "event_id": "ev_5d…", "type": "order.delivered", "order_id": "o_1a2…", "store_id": "s_12…",
  "source_post_id": "p_91…", "delivered_at": "…16:19:40Z" }
```

Problem classify request
```json
{ "audio_id": "au_3f…", "photo_id": null, "lat": 60.3971, "lng": 5.3240 }
```
Problem classify response
```json
{ "type": "store_closed", "confidence": 0.91, "alternatives": ["store_not_started"], "note_prefill": "Butikken er stengt, lyset er av", "agent_run_id": "ar_c2…" }
```
Order issue
```json
{ "id": "oi_9a…", "order_id": "o_1a2…", "type": "missing_item", "policy_key": "issue.missing_item.v1",
  "resolution": "auto_credit", "amount": 89, "state": "resolved", "agent_run_id": "ar_77…" }
```
Campaign proposal
```json
{ "id": "cp_5d…", "store_id": "s_torgboden", "item_id": "it_fiskesuppe", "discount_pct": 15, "window": ["Tue 16:00", "Tue 18:00"],
  "expected_orders": 12, "expected_revenue": 1790, "confidence": "medium", "post_draft_id": "fd_11…", "state": "proposed" }
```

## Appendix D — Glossary
**Kundeblikk** — the line on Partner cards and Bud stages showing what the customer sees now. **Puls** — store device heartbeat; liveness gates auto-accept. **Sett** — the seen-signal. **Samle-QR** — one token for several orders on one assignment. **Hylleplass** — shelf slot A–F assigned at ready. **Trenger deg** — the store's list of items needing a human. **Unntak** — panel exceptions inbox. **Autodrift** — automation level (manuell/assistert/auto). **Autopilot** — courier auto-accept within own limits. **Policy key** — versioned rule the policy engine resolves to an amount or outcome. **Leveringskode** — QR with PIN fallback required at the door for risk-triggered orders. **ID-kort** — the courier's in-app identity card with the BankID-verified badge. **Leveringskode** — QR with PIN fallback at the door. **ID-kort** — the courier's in-app identity card. **Kampanjeforslag** — a store's weekly campaign proposal from its own data. **Bestill fra bilde** — reorder by package photo.
