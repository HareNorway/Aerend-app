# Ærend — 10-Week Implementation Plan (week-by-week, with progress + acceptance checklists)

**Source specs (priority order):**
1. `AEREND ORDER OPS SPEC FINAL STATEv3.md` — **final, authoritative** backbone (state machines, QR handoff, time engine, money, problems, agent catalogue, admin panel).
2. `AEREND POINTS SPEC v2 .md` — **final v2**, rip-and-replace of the old rewards system.
3. `AEREND PARTNER & BUD UPGRADE SPEC.md` — client-side detail for the Partner and Bud apps (superseded by Order Ops where they conflict).
4. `aerendvstore feed update spec.md` — feed enhancement (products, publishing, oversight).
5. `AEREND AEGIL AGENT SPEC FINAL VERSION.md` — AI shopping agent (built last; consumes everything above).

**Designs:** `designs/20des/Ærend Partner*.dc.html`, `Ærend Bud*.dc.html`, `Ærend Bud og Partner - register og system.dc.html`, `ui_kits/partner`, `ui_kits/driver`.
**Codebases:** `Hare-AdminPanel` (Laravel 8 backend + Blade/Vue2 admin), `Hare-Store` (Partner Flutter), `Hare-Driver` (Bud Flutter), `Aerend-app/Aerend-app` (Customer Flutter), `aerend-feed-service` (Fastify, separate repo).

---

## How to use this document

- Ten weeks, each split into 5–6 **phases**. Each phase is a checklist (`[ ]`) — tick as you go.
- Every week ends with an **Acceptance test checklist**: the week is not done until every box is ticked in staging.
- Order Ops and Points work is front-loaded (weeks 1–6). Feed lands in weeks 7–8. Ægil lands in weeks 9–10 on top of a stable backbone, exactly as its own spec sequences it.
- **Reuse rule:** the backend, feed service, Snurre agent subsystem, Dugnad points engine, and all three Flutter apps already exist and are production-grade. Nothing below is "build from scratch" unless explicitly marked *(net-new)*.
- Appendix A maps every feature in the five specs to a week (or to the Week-11+ backlog). Appendix B lists the business/legal decisions that gate specific weeks.

---

## Week 1 — Backbone: infrastructure, policy engine, state machines, points ledger

### Phase 1.1 — Infrastructure prerequisites
- [ ] Activate realtime broadcasting (Soketi/Pusher driver — currently `null`); provision channels `private-store.{id}`, `private-courier.{id}`, `private-panel`, `private-customer.{id}`
- [ ] Polling fallback endpoint (`GET /events?since=`) for clients when websockets are down
- [ ] Close `VIPPS_GAP.md`: production Vipps payment + payout capability, provider agreement confirmed (Appendix B)
- [ ] CI preflight: `php artisan route:list`, block `APP_ENV=local` / `APP_DEBUG=true` in prod builds, `main` branch protection
- [ ] Feature-flag table (`feature_flags`) with per-store / per-courier / per-customer targeting

### Phase 1.2 — Policy engine *(net-new)*
- [ ] `policies` table: key, value (json), version, effective_from, changed_by, reason
- [ ] Policy read service with in-memory cache + version pinning per order (orders record the policy version they were priced under)
- [ ] Seed keys: `time.default_prep`, `time.window_widths`, `money.waiting_threshold_s`, `money.waiting_rate`, `money.waiting_cap`, `money.base_pay`, `money.distance_rate`, `money.stacking_bonus`, `money.trip_compensation`, `dispatch.offer_timeout_s`, `dispatch.stack_proximity_m`, `escalation.unseen_s=[60,120,240]`, `points.*` (see 1.5)
- [ ] Admin: policy edit requires a reason; every change writes `audit_log`

### Phase 1.3 — Order & assignment state machines
- [ ] Order machine: `placed → accepted → seen → ready(optional) → picked_up → arrived_customer → delivered | cancelled`, plus `problem` sub-state; guards and side-effects per Order Ops table
- [ ] Assignment machine: `offered → accepted → en_route_pickup → arrived_pickup → (waiting) → picked_up → en_route_drop → arrived_drop → delivered | released | failed`
- [ ] Store availability machine: `open ↔ paused_manual | paused_auto`
- [ ] Device machine: `registered → alive → stale → alive`; roles `kasse | kjokken | henting`
- [ ] Order code generator `Æ-42K`: unambiguous alphabet + check-letter algorithm (Partner&Bud spec reference implementation), uniqueness per day per city

### Phase 1.4 — Event model
- [ ] `order_events` (append-only): order_id, type, actor_type (`customer|store|courier|system|agent|admin`), actor_id, payload, idempotency_key (unique), occurred_at, received_at
- [ ] Transition service: validates transition, writes event, updates projection, fans out to channels — one transaction
- [ ] Duplicate idempotency_key → `200` with original event (not an error)
- [ ] Out-of-order events accepted and re-sorted by `occurred_at` for offline clients
- [ ] Extension columns on `orders`: `code`, `proof_type`, `origin`, `source_post_id`, `policy_version`, `promised_window_start/end`, `predicted_ready_at`, `shelf_slot`

### Phase 1.5 — Points ledger (generalize the Dugnad engine)
- [ ] `points_ledger` (append-only): user_id, kind (`earn|spend|expire|revoke|adjust`), rule_key, amount, ref_type, ref_id, policy_version, available_at, expires_at, created_at
- [ ] `points_balances` projection: available, pending, earned_12m, lifetime — rebuildable from ledger
- [ ] Rebuild command (`points:rebuild {user?}`) and nightly integrity check (projection == ledger sum)
- [ ] Policy keys seeded: `points.kjop_per_10kr=1`, `points.dagens_napp=5`, `points.verving=200/200`, `points.forste_gang=50`, `points.league_cap_per_order=200`, `points.expiry_months=12`, `points.expiry_warning_days=30`, `points.tier_thresholds=[0,1000,3000,8000]`
- [ ] Map existing `PointsLedger` / Dugnad tables → new schema (read-side compatibility view so nothing breaks before Week 3 migration)

### Phase 1.6 — Shared status vocabulary
- [ ] One server `status` enum mapped to Customer/Partner/Bud display strings (Ny/Bekreftet, Sett/Tilberedes, Klar for henting, På vei/Hentet, Levert, Åpner igjen snart) in ARB files for all three apps
- [ ] Contract doc published: event names, channel names, payload shapes (frozen for the clients in weeks 2–7)

### Week 1 acceptance tests
- [ ] Websocket event delivered to a subscribed store/courier/panel client within 1s; polling fallback returns the same event when websockets are disabled
- [ ] Vipps: test payment and test payout complete end-to-end in the Vipps test environment
- [ ] Every invalid transition (e.g. `placed → picked_up`) returns `422 INVALID_TRANSITION` and writes no event
- [ ] Replaying the same idempotency_key twice yields one event row
- [ ] 10 000 generated order codes: zero collisions, zero ambiguous characters, check-letter validates 100 %
- [ ] Policy change without a reason is rejected; change with reason appears in `audit_log`
- [ ] `points:rebuild` on a seeded ledger reproduces the projection exactly; integrity check passes
- [ ] All three apps compile against the new status enum with no unmapped states

---

## Week 2 — Realtime, device liveness, seen-signal, client shells, points earning rules

### Phase 2.1 — Device registration, heartbeat & liveness
- [ ] `store_devices`: store_id, role, name, push_token, battery, sound_ok, last_heartbeat_at, state
- [ ] `POST /partner/devices/heartbeat` every 30s (battery, sound, app-foreground); liveness rule `stale` after 90s, `alive` on next heartbeat
- [ ] Store liveness = any `alive` device with role `kasse`; feeds `paused_auto` in Week 6

### Phase 2.2 — Seen-signal
- [ ] `order.seen` event on first render of the order card on any device (auto in Kjøkken)
- [ ] `unseen_timeout` scheduler (60/120/240s from `policies`) writes `order.unseen_escalation_{1,2,3}` events (ladder actions wired in Week 6)
- [ ] Panel counter "unseen > 60s" live

### Phase 2.3 — Partner app: device-role shell
- [ ] App bar: Æ mark, Drift/Butikk switch, role pill (Kasse/Kjøkken/Henting), clock, mic entry placeholder
- [ ] Bottom nav Drift · Varer · Poser · Feed · Mer
- [ ] Kasse board with 4 stage sections (Ny · Tilberedes · Klar · Hentet) driven by the Week 1 status enum, replacing the hidden tab pattern
- [ ] Order card: code, type, code-required flag, allergen flag, sum, customer, items, promised window + countdown, shelf slot placeholder, courier line placeholder
- [ ] Kjøkken view: large prep cards, allergen line red until acknowledged (blocks Klar), auto-seen on render
- [ ] Wake-lock, audio-focus for new-order sound, heartbeat sender

### Phase 2.4 — Bud app: 7-stage live shell
- [ ] Mode pill Av vakt / På vakt / På oppdrag; "Tjent nå" header slot
- [ ] Live stage stepper: Hent → Ankommet henting → Skann → Lever → Ankommet levering → Bevis → Levert, driven by the assignment machine
- [ ] Fixed lower-third controls: next action, Naviger, Ring, mic placeholder, Problem
- [ ] Fixed ID-kort slot on every live stage
- [ ] "Butikken ser / Kunden ser" dual-status line reading from order + assignment state
- [ ] Re-enable the built-but-disabled dark theme (`main.dart`) as Night mode foundation

### Phase 2.5 — Points earning rules
- [ ] **Kjøp**: on `order.delivered` write `earn` pending (1 pt / 10 kr, policy key) → `available_at = delivered + return window`; `revoke` on cancel/refund
- [ ] **Verving**: referral code + link, 200+200 on referee's first delivered order ≥ min threshold, monthly cap per referrer
- [ ] **Første gang**: 50 pts on first delivered order in a new category or store, monthly cap
- [ ] **Dagens napp**: 5 pts/day on `suggestion.reeled` (event stub until Ægil exists in Week 9; Feed "Vågen" tap fires it)
- [ ] **Ægils oppdrag**: `mission.completed` → 20–100 pts (missions engine arrives Week 6)
- [ ] `points_release` job (pending → available), `points_expire` job (12-month FIFO), 30-day expiry warning event

### Phase 2.6 — Customer app status consumption
- [ ] Order tracking screen renders the new status strings and the promised **window** (never a point-in-time ETA)
- [ ] Subscribes to `private-customer.{id}` for live status; polling fallback

### Week 2 acceptance tests
- [ ] Kill the Kasse app → store shows `stale` in panel within 90s; reopen → `alive` within 30s
- [ ] New order rendered on Kasse → `order.seen` event within 1s; not rendering for 60s → escalation_1 event exists
- [ ] Partner board shows an order moving Ny → Tilberedes → Klar via server events without a manual refresh
- [ ] Kjøkken "Klar" is disabled until the allergen line is acknowledged
- [ ] Bud stepper advances only through valid assignment transitions; invalid taps are rejected client-side and server-side
- [ ] Delivered 149 kr order → 14 pending points, becomes available after the return window; cancelling revokes them
- [ ] Referral: two accounts, referee's first ≥ threshold order → both get 200; third referral over monthly cap earns nothing
- [ ] Expiry job on a seeded 13-month-old earn row writes an `expire` row and the warning fired 30 days earlier

---

## Week 3 — QR pickup handoff, offline scanning, Nivå tiers, points migration

### Phase 3.1 — Pickup tokens (Order Ops §10)
- [ ] `pickup_tokens`: order_id, jws (ES256), nonce, expires_at (60s), used_at; key rotation schedule
- [ ] Offline batch tokens (pre-signed set per order for stores with weak connectivity)
- [ ] **Samle-QR**: one token covering all orders in a stacked assignment
- [ ] Rotating QR endpoint for the Henting device; `POST /courier/scan` with 5 ordered validations (signature, expiry, nonce reuse, order state, courier assignment) and named `422` codes (`TOKEN_EXPIRED`, `NONCE_REUSED`, `WRONG_STATE`, `NOT_ASSIGNED`, `SIG_INVALID`)
- [ ] `scans` table (source `qr|typed|store_confirm|panel_override`, client_ts, server_ts)
- [ ] Fallbacks: typed code, store confirmation, panel override — each writes its own scan source

### Phase 3.2 — Shelf slot & self-pickup
- [ ] Hylleplass assignment on `ready` (A1…D9 per store config), shown on Kasse/Henting cards and in the courier's pickup stage
- [ ] Customer self-pickup: customer QR/code shown in app, Henting tile scans it or accepts typed code; `delivered` with `proof_type=self_pickup`

### Phase 3.3 — Partner app: Henting screen
- [ ] Ready-order tiles (full) + nearly-ready (dimmed), code, item count, courier name/ETA or "selvhenting", shelf slot
- [ ] Rotating QR with 60s countdown ring; samle-QR when one courier has multiple orders
- [ ] Scan confirmation (green flash); slide-to-confirm fallback with courier-confirm pending state; typed-code fallback
- [ ] "Utlevert til bud" and "Utlevert til kunden" handoff actions on Kasse

### Phase 3.4 — Bud app: pickup stage
- [ ] Code + shelf slot display; not-ready → waiting counter (fee moment wired Week 5)
- [ ] Camera/QR scan → green confirm; scan-rejected states per `422` code; "Skriv kode" typed fallback (works offline)
- [ ] "Be butikken bekrefte" pending-confirm path
- [ ] Offline scan queue: client-timestamped, pending marker, auto-send on reconnect, offline JWS verification with cached public key
- [ ] Samle-QR flow with one-missing-order handling

### Phase 3.5 — Nivå tier engine (Points §Nivå)
- [ ] Tiers Fløyen 0 / Løvstakken 1000 / Rundemanen 3000 / Ulriken 8000 on `earned_12m` (policy key)
- [ ] `tier_evaluate` on every earn: immediate promotion, `tier.promoted` event
- [ ] `tier_review` annual job: at most one tier drop, `tier.review_warning` 60 days prior with mission recommendation, `protected_until` override honoured — built and unit-tested, scheduled but not fired until launch anniversary
- [ ] Rule enforced in code: spend and expiry never touch `earned_12m`

### Phase 3.6 — Points migration & removal of old mechanics
- [ ] Migration job: Ærend-kroner → points at the agreed factor (Appendix B); every converted balance written as `adjust` with `ref_type=migration`
- [ ] Seed `earned_12m` from trailing-12-month delivered orders so existing customers are not reset to Fløyen unfairly
- [ ] Remove from backend, admin, and customer app: varder/Din sti, Syv fjell, store stamp cards, Bydelsligaen, "Ekte bergenser", "fjell tent", standalone trust-ledger card (its savings line moves into the monthly points summary)
- [ ] Dry-run mode producing a reconciliation report (users, kroner in, points out, tier distribution) — production cutover scheduled Week 10 together with customer comms

### Week 3 acceptance tests
- [ ] Token scanned twice → second scan `NONCE_REUSED`; token scanned after 60s → `TOKEN_EXPIRED`; wrong courier → `NOT_ASSIGNED`
- [ ] Samle-QR with 3 orders marks all 3 `picked_up` in one scan; with one order not ready, the two ready ones are picked up and the third stays with an explicit warning
- [ ] Airplane mode on Bud: typed code accepted locally, queued, appears server-side with the client timestamp after reconnect
- [ ] Self-pickup order: customer code scanned on Henting → `delivered`, `proof_type=self_pickup`
- [ ] Shelf slot shown identically on Kasse, Henting and the courier pickup stage
- [ ] User crossing 1000 `earned_12m` is promoted to Løvstakken on the same request; spending 900 pts afterwards leaves the tier unchanged
- [ ] Annual review dry-run on seeded data drops nobody more than one tier and lists every user who would receive the 60-day warning
- [ ] Migration dry-run report reconciles to the kroner total within rounding; zero users end below Fløyen; zero references to removed mechanics remain in any app build (grep + UI smoke)

---

## Week 4 — Time engine, Autodrift v1, Kasse timing actions, Premiehylla + customer points UI

### Phase 4.1 — Time engine layer 1–2 (Order Ops §7)
- [ ] Layer 1: store default prep times per category (from `store_settings`)
- [ ] Layer 2: `prep_stats` EWMA per store / item / weekday / hour learned from `ready` and courier `arrived_pickup` timestamps; `assistert` confirmations double-weighted
- [ ] `predicted_ready_at` computed on `accepted`, recomputed on every adjustment
- [ ] Customer window formula: centre = predicted_ready + travel, width from confidence (policy `time.window_widths`); never narrower than the policy floor

### Phase 4.2 — Time engine layer 3 & capacity
- [ ] `order_time_adjustments`: +5/+10/+15 with actor, reason, undo
- [ ] Capacity: `store_settings.capacity`, queue-load computation, busy mode widens windows automatically
- [ ] Temporary exceptions (per-day prep override) with reset + undo

### Phase 4.3 — Partner app: Kasse timing & Autodrift v1
- [ ] Card actions +5/+10/+15 with consequence text + undo; "kundeblikk" line ("Kunden ser: 18:40–18:55")
- [ ] Level-specific primary actions: Manuell (Godta/Avvis), Assistert (Bekreft tiden/Endre tid) — Auto in Week 6
- [ ] Autodrift panel: Nivå (Manuell/Assistert), Tider (editable defaults, read-only "lært fra kjøkkenet" sentence, exceptions), Kapasitet stepper with stated rule
- [ ] "Solgt i kveld" header (sum, count, vs last week), next-courier ETA line
- [ ] Reject requires a reason and shows the customer consequence/refund text

### Phase 4.4 — Premiehylla backend (Points §Premiehylla)
- [ ] `prizes`: tier_band, type (`voucher|physical|donation|identity|partner`), funding (`aerend|partner`), point_price, inventory, per-user cap, fulfilment_type, active
- [ ] `prize_claims` machine: `claimed → applied | shipped | delivered | used | expired | cancelled`; 60-day claim expiry; 24h cancel-for-refund window
- [ ] Voucher auto-apply at next checkout; shipment queue; donation ledger; `identity` prize (boat) with name + name-filter review queue
- [ ] Initial catalogue seeded from the spec pricing table (Fløyen: free delivery 100, sticker pack 150, Forundringspose 250, club donation 500 … Ulriken: boat 2000)
- [ ] `point_goals`: one active goal (prize or tier), user-set (Ægil-proposed goals arrive Week 9)

### Phase 4.5 — Customer app: points UI *(net-new)*
- [ ] "Meg" section: balance (available / pending), Nivå card with progress to next tier, expiry notice
- [ ] Premiehylla: cumulative shelf bands; locked previews above current tier (blurred, teaser + price + gap, max 3, no padlock framing)
- [ ] Claim flow, claim history, cancel within 24h, voucher visible at checkout
- [ ] Goal setting (pick a prize or tier); goal progress line
- [ ] Monthly points summary screen (includes the migrated trust-ledger savings line)

### Phase 4.6 — Customer app: window rendering
- [ ] Tracking shows the window and confidence copy; re-renders on `order.time_adjusted`; +10 from the store is shown honestly ("Butikken trenger 10 min ekstra")

### Week 4 acceptance tests
- [ ] After 30 seeded orders for one item, `prep_stats` EWMA moves toward the observed prep time; window MAE on a replay set is reported by the metrics job
- [ ] +10 on Kasse updates `predicted_ready_at`, the customer window, and the courier's dispatch time within 1s; undo restores all three
- [ ] Busy mode (queue > capacity) widens new windows by the policy amount; falls back when queue drains
- [ ] Reject without a reason is blocked; with a reason the customer receives the refund notification
- [ ] Claiming a 100-pt voucher writes `spend`, decrements inventory, and the voucher applies automatically to the next checkout
- [ ] A Fløyen user sees exactly 3 blurred previews from higher bands with correct "poeng til" gaps
- [ ] Cancelling a claim inside 24h refunds points; outside 24h is refused
- [ ] Boat prize claim with a filtered name lands in the review queue and is not rendered until approved

---

## Week 5 — Money engine, proof & delivery code, Bud delivery stages, Points admin

### Phase 5.1 — Waiting pay & run payment (Order Ops §12)
- [ ] Waiting timer starts at `arrived_pickup` when order not `ready`; accrues after `money.waiting_threshold_s` at `money.waiting_rate` up to `money.waiting_cap`
- [ ] Run payment = base + distance + waiting + stacking bonus (+ weather bonus key) ; tip as a separate transfer
- [ ] Trip compensation for `released`/`failed` per policy; problem payment lines (Week 6) plug into the same formula
- [ ] `payouts` / `payout_lines`; daily payout batch at 04:00 via Vipps; "paid to Vipps" state
- [ ] Amounts only ever sourced from `policies`; admin manual adjustment requires reason + audit

### Phase 5.2 — Proof types & delivery code/PIN (Order Ops §11)
- [ ] Proof policy at order creation: `door_photo` (default) / `to_person_name` / `code`; triggers: value threshold, age-restricted, customer choice, business delivery, risk history
- [ ] `door_photo` prevalidate via `agent.photo_qa` stub (deterministic checks: brightness, blur, size) with one retake
- [ ] Delivery code: QR token + 4-digit PIN, 3 PIN attempts then lockout → photo+name fallback flagged `elevated_risk`; code orders can never end as leave-at-door
- [ ] `door_profiles` (consent flag, 24-month retention) storing door line, entrance photo, prior courier note

### Phase 5.3 — Bud app: delivery & proof
- [ ] Delivery stage: door intelligence (door line, prior entrance photo, prior note with "vis original")
- [ ] Geofence pre-arm: arrival button arms within radius, human still presses
- [ ] Proof capture for all three types; PIN pad with attempt counter and lockout messaging
- [ ] "Levert" moment: amount slides in, Tjent nå counts up, tip ping
- [ ] Run summary: itemized lines (base/distance/waiting/stacking/tip), goal-distance line, "Forklar" button placeholder (Week 8), "Si noe om døren" placeholder (Week 9)
- [ ] Waiting-fee moment at pickup ("ventegebyr +12 kr")

### Phase 5.4 — Bud app: money screens
- [ ] Inntekt: Dag/Uke/Måned tabs, per-run rows with component breakdown, tips separate, payout states, "Beste dag denne uken"
- [ ] Annual tax-report export (CSV/PDF from `payout_lines`)
- [ ] Vaktsammendrag (shift-end summary) with the two design variants; "Mitt mål" settable target with distance-to-goal

### Phase 5.5 — Customer app: delivery code & courier identity
- [ ] Code card auto-shown when `proof_type=code` (QR + PIN), with reason copy (age-restricted / value / your choice)
- [ ] Courier ID-kort (name, photo, verification date) visible from tracking
- [ ] Customer choice toggle "Krev kode ved levering" in checkout

### Phase 5.6 — Points admin panel (Points §Admin)
- [ ] Dashboard: issuance, liability (with editable breakage assumption), redemptions
- [ ] Ledger: search by user/order, manual `adjust` with reason, rebuild button
- [ ] Regler og satser: every `points.*` policy key with version history and a what-if simulator (replays last 30 days)
- [ ] Nivå: thresholds, tier population over time, review queue, `protected_until`, welcome-pool management, annual-review dry-run button
- [ ] Premiehylla: prize CRUD, inventory, fulfilment queues (shipment/donation/name review), cost tracking per prize

### Week 5 acceptance tests
- [ ] Courier arrives at a not-ready order: no waiting pay before threshold, correct accrual after, capped at the policy cap
- [ ] Run payment on a stacked 2-order run equals base + distance + waiting + stacking bonus per policy; tip lands as a separate transfer
- [ ] 04:00 batch pays yesterday's runs to Vipps test accounts; rows move to "paid to Vipps"
- [ ] Age-restricted item → order created with `proof_type=code`; customer sees the code card; 3 wrong PINs → lockout → photo+name path → `elevated_risk` set; leave-at-door option absent
- [ ] Door photo that fails prevalidation prompts exactly one retake, then is accepted with a QA flag
- [ ] Tax export for a seeded year totals to the sum of `payout_lines`
- [ ] Admin what-if simulator on `points.kjop_per_10kr=2` reports doubled issuance for the replay window without writing to the ledger
- [ ] Every admin adjust/threshold change appears in `audit_log` with a reason

---

## Week 6 — Problems, escalation ladder & auto-pause, exceptions inbox, missions/league/welcome gift

### Phase 6.1 — Problems (Order Ops §13)
- [ ] `problems`: type (`store_closed|wrong_order|customer_unreachable|wrong_address|damage`), source (`tap|voice|photo`), actor, state, resolution, payment_line_key, photos
- [ ] Per-type flows and closures: store closed (60 kr), wrong order take-anyway / wait (25 kr), customer unreachable relay→SMS→timer→policy outcome + return-to-store for code orders (45 kr), wrong address corrected stop (+8 kr), damage run closed with protected pay (118 kr) — all amounts as policy keys
- [ ] `agent.exception_triage` hook: proposes resolution within 60s; on timeout, policy default applies automatically
- [ ] Masked relay calls (courier ↔ customer, courier ↔ store) via Twilio proxy numbers; SMS fallback

### Phase 6.2 — Escalation ladder & auto-pause (Order Ops §8)
- [ ] Step 1 (60s unseen): sound escalation + push to all store devices
- [ ] Step 2 (120s): owner call/SMS via `agent.comms` (scripted, L1)
- [ ] Step 3 (240s): `paused_auto`, exception opened, customer offered choice (wait / cancel with refund)
- [ ] Resume flow with the post-autopause explanation card; Autodrift **Auto** level: server auto-accepts and auto-advances `ny → prep` when the store is alive
- [ ] Autodrift `Puls` device rows and per-device sound/escalation test endpoint

### Phase 6.3 — Partner app: Trenger deg, problems, Autodrift complete
- [ ] "Trenger deg" priority list: unseen order, courier waiting, allergen note, sold-out suggestion, low battery/muted device, courier problem card (courier's words + customer-facing status, two outcomes)
- [ ] Return-to-store flow ("Mottatt" → shelf D) for failed code deliveries
- [ ] Autodrift Nivå adds Auto with consequence sheet and learning-week note; Puls rows open the device sheet (mute/test/rename/role/remove)
- [ ] Travelmodus/pause sheet (15/30/60/rest of day + extend all, hold-to-confirm); offline / paused / pulse-lost / low-battery / muted banners
- [ ] Order detail sheet: options/allergens, full note, contact courier via relay, reject with reason + stated refund

### Phase 6.4 — Bud app: problem flows
- [ ] Problem sheet (tap): 5 types, per-type photo hint, offline "sendes når du er på nett"
- [ ] Customer-unreachable relay flow with timer and policy outcome; wrong-address corrected stop; damage closes the run with protected pay shown
- [ ] Offer screen: single / stacked / auto-accepted variants (auto-accept wiring Week 7), full payment breakdown, calm countdown ring, Godta/Avslå equal weight, decline → next, expiry state

### Phase 6.5 — Admin: Nå + Unntak + Butikker + Bud
- [ ] Nå: live counts (orders by state, unseen, waiting couriers, paused stores, open problems)
- [ ] Unntak inbox with SLA timers per exception type (unseen, courier waiting, problem, failed delivery, payout hold, name review, moderation) and override actions (panel scan override, manual state change with reason)
- [ ] Butikker liveness board + store detail (devices, Autodrift level, prep stats, exceptions); Bud shift board + courier detail/verification
- [ ] Role-based landing pages (ops/support/finance/management/admin)

### Phase 6.6 — Points: missions v1, league v1, welcome gift
- [ ] `mission_templates` × `business_goals` (quiet_hours/new_store/category_growth/pickup_share) → weekly scored candidates; one active mission, one decline/week; template wording (Ægil personalisation arrives Week 9); `missions_weekly` job
- [ ] Fløyen-ligaen: monthly opt-in, tier-blind, per-order cap 200, top-10 + own rank + "Din bydel", `league_month_end` job (freeze, fraud exclusion, prize assignment, twice-a-year top-3 cap)
- [ ] Welcome gift on `tier.promoted`: zero-cost prize auto-selected from the configured pool (deterministic pick; Ægil reason text in Week 9)
- [ ] Customer app: mission card, league screen, welcome-gift moment; admin: Oppgjør/Liga/Oppdrag sections with kill switches

### Week 6 acceptance tests
- [ ] Each of the 5 problem types, from Bud, produces the correct payment line, store card, customer status, and exception row; timeout with no triage proposal applies the policy default
- [ ] Unseen order in a store with a live device: sound at 60s, owner SMS at 120s, `paused_auto` + exception + customer choice at 240s; resume shows the explanation card
- [ ] Autodrift Auto: new order is `accepted` and `seen` by the server within 2s with zero store taps
- [ ] Relay call connects courier and customer with both real numbers masked
- [ ] Panel override scan marks the order `picked_up` with `source=panel_override` and an audit row
- [ ] Missions job assigns exactly one active mission per eligible user; completing it earns the template's points once
- [ ] League month-end freezes standings, excludes a flagged account, assigns prizes, respects the twice-a-year cap
- [ ] Promotion to Løvstakken creates a zero-cost welcome-gift claim automatically

---

## Week 7 — Autopilot & stacking, offline outbox, notifications, feed data layer, product management

### Phase 7.1 — Dispatch, autopilot & stacking (Order Ops §9)
- [ ] Dispatch timing from `predicted_ready_at` minus travel; `offers` with timeout, decline → next courier, reassignment on expiry
- [ ] `courier_limits` (max distance, min payout, areas, stacking allowed); autopilot auto-accept within limits with 20s "Slipp" release window; persistent banner state
- [ ] Stacking rules (proximity + timing thresholds), `assignment_orders`, route strip ordering, samle-QR link
- [ ] `courier_locations` streaming cadence (on-shift 15s, on-run 5s), geofence radius per stage

### Phase 7.2 — Offline outbox & conflict rules (Order Ops §14)
- [ ] Partner and Bud: local outbox for every mutating action (scan, status change, problem, note, feed post); pending markers; retry with backoff; server-wins conflict resolution with client notification
- [ ] Offline banner lists the actual unsent items (queue sheet) on Bud; pending markers on Partner cards

### Phase 7.3 — Notifications table (Order Ops §15)
- [ ] `notifications` categories/channels/throttles: order, escalation, payout, points, feed-follow, agent (separate channel, quiet hours, caps `daily=1`, `good_only=3/7d`)
- [ ] Deep links per category; per-user preferences; quiet hours honoured for agent + feed, never for live-order events

### Phase 7.4 — Bud app: autopilot, stacking, health rows
- [ ] Autopilot toggle → limits sheet → banner; auto-accepted receipt with "Slipp" (20s)
- [ ] Stacked route strip with both codes; offer stacking variant live
- [ ] Health/readiness rows (location off, battery saver, notifications off) with fix actions; "Neste gode time" heat-map sheet (historical only, explicitly non-predictive)
- [ ] Profil: verification badge, documents, vehicle, delivery limits, milestones (plain text), payout method, Night mode, Big-weather mode toggles

### Phase 7.5 — Feed data layer (feed spec §5 + Order Ops §16)
- [ ] Reconcile `feed_post` with the feed service's existing `posts` table into **one** schema: publisher_type (`store|aerend`), store_id (nullable), product_id, headline, body, image, category, status (`draft|scheduled|live|hidden|removed`), created_by, hidden_reason, scheduled_at
- [ ] `product_change_log` (store_id, product_id, field, old, new, changed_by, changed_at); `store_feed_eligibility` (default true)
- [ ] Monolith → feed-service webhooks: `product.upserted`, `product.sold_out`, `product.price_changed`, `store.updated`, `order.delivered` (with `source_post_id`); feed → monolith `feed.post.published`
- [ ] Mix rule in ranking (max 1 Ærend post per 5 store posts, never consecutive; `drift` exempt); tabs `I nærheten` (chronological + deliverability filter), `Følger`, `Fra Ærend`
- [ ] Degradation: health endpoint; no order path depends on the feed service

### Phase 7.6 — Partner app: product & price management (feed spec §2)
- [ ] Varer: create/edit/archive products — name, description, images (existing Cloudinary path), category, price, availability; live immediately, every change logged
- [ ] Price editing with sync-consequence copy; availability toggle with undo; search → one-tap sold-out with re-availability time; sold-out suggestion card (sales velocity)
- [ ] Forundringspose screen fields (quantity, price ≤ half-value floor, pickup window, allergen exclusions, net per bag, reservations with pickup code) on the existing surprise-bag backend

### Week 7 acceptance tests
- [ ] Offer declined by courier A is offered to courier B within the policy timeout; expired offers reassign automatically
- [ ] Autopilot with max 3 km: a 5 km offer is not auto-accepted; a 2 km one is, and "Slipp" within 20s releases it with no penalty
- [ ] Two qualifying orders stack into one assignment with one samle-QR and one route strip
- [ ] Airplane mode on Partner: +10 and Klar queue with pending markers and apply in order after reconnect; a conflicting server state wins and the device is told
- [ ] Agent-channel push respects quiet hours and daily cap; a live-order push does not
- [ ] `product.price_changed` webhook reaches the feed service within 2s and the feed post shows the new price without republishing
- [ ] Feed service down: ordering, pickup, delivery and payouts all still complete; health endpoint reports degraded
- [ ] Product edit on Partner produces one `product_change_log` row per changed field

---

## Week 8 — Feed publishing & oversight, agent-platform substrate, first Partner/Bud agents

### Phase 8.1 — Partner app: publish to feed (feed spec §2.4)
- [ ] 3-step composer: pick own product → headline + short text (+ post type) → preview as customer → publish; image defaults to product image, custom optional
- [ ] Own post list sorted by attributed orders with reach; detail sheet (delete / expire); honest moderation status "Skjult av Ærend"; scheduling/expiry; offline queueing; service-down state
- [ ] v1 rule: exactly one product per post; **no discount / "før-pris" framing** (compliance gate, Appendix B) — composer blocks such copy
- [ ] Butikk → Innstillinger: "Ærend kan skrive om butikken min" toggle + frequency (drives Week 11+ `agent.editorial`), "Din bestillingslenke" (direct order link, lower-commission tracking)

### Phase 8.2 — Customer app: feed tabs & product linking (feed spec §3)
- [ ] Tabs «Publisert av butikker» / «Publisert av Ærend»; category chips from config
- [ ] Post → live product detail; hidden/removed posts disappear on next fetch; prices always read live
- [ ] Close inherited gaps: reels tab (hide unless reels are confirmed), header heart/message icons, kebab-sheet item
- [ ] Feed follow pushes through the Week 7 notification table

### Phase 8.3 — Admin: Ærend publishing, oversight, change log (feed spec §4)
- [ ] Ærend team composer: any store's product → headline/text/image → publish now or schedule; states draft/scheduled/live/hidden/removed; edit/unpublish list
- [ ] Unified post oversight: filter store/category/status/date; hide/remove with logged reason (immediate effect)
- [ ] Per-store `store_feed_eligibility` toggle; product & price change log with filter/search; panel hide-product (compliance takeover)
- [ ] Feed health card on Nå

### Phase 8.4 — Agent platform substrate (Order Ops §17, extends Snurre)
- [ ] `agents` register (name, autonomy level L0/L1/L2, scopes, caps, enabled), scoped service tokens (`403 AGENT_SCOPE_DENIED`), `actor_type=agent` on events, **no direct DB writes**
- [ ] `agent_runs` audit row per invocation (input hash, output, validation result, deadline hit, fallback used); per-agent / per-hour / per-case caps
- [ ] Kill switch per agent (tested); deadline → deterministic fallback pattern as a shared wrapper; untrusted-text handling; AI-disclosure copy on first use in every app
- [ ] Policy-keyed money only: agents may reference `money.*` keys, never amounts

### Phase 8.5 — Partner agents P1 & P5
- [ ] **P1 `agent.menu_copy`**: generate description from empty/draft (use / rewrite / discard), allergen proposals unchecked by default, category chip, text-only mode, batch review queue "Beskrivelser å se over (N)", fallback when unavailable
- [ ] **P5 `agent.hours_exceptions`**: free-text line → structured rows, single-row correction, holiday prompt, coherence check vs store page, parse-failure fallback; Åpningstider weekly grid + customer-facing sentence

### Phase 8.6 — Bud agent B4 & Kjøkken voice
- [ ] **B4 `agent.bud_explain`**: "Forklar" on run summary and Inntekt rows → per-line explanation sentences (bokmål; Polish once B1 lands), one follow-up question, fallback state, "noe er feil" escape into the problem flow
- [ ] Kjøkken voice mark-ready ("Æ-42 klar" → confirm → undo) on the shared voice wrapper; Partner mic entry (hold-to-speak, 4 example chips, single interpreted action, confirm-can-undo)

### Week 8 acceptance tests
- [ ] Store publishes a post → visible in the customer feed under «Publisert av butikker» within 5s; admin hides it → gone from the customer feed on next fetch and the store sees "Skjult av Ærend"
- [ ] Composer rejects "før 199, nå 149" style copy with the compliance message
- [ ] Ærend scheduled post goes live at its time under «Publisert av Ærend»; mix rule holds in a 50-post feed (no two consecutive Ærend posts, ≤ 1 per 5)
- [ ] Ineligible store cannot publish; its products remain live
- [ ] Every agent call writes an `agent_runs` row; an agent token requesting an out-of-scope endpoint gets `403 AGENT_SCOPE_DENIED`; flipping the kill switch makes P1 return the fallback within the same minute
- [ ] P1 output with an invented allergen not on the allowlist is rejected by code validation and never stored
- [ ] P5 parses "stengt neste tirsdag" into one structured exception row; nonsense input shows the fallback, not a guess
- [ ] B4 explanation lines sum to the run payment shown; "noe er feil" opens a prefilled problem report

---

## Week 9 — Ægil foundation (levels 0–2), matching & tray, against-interest, Bud B1/B2/B3, Partner P3/P4

### Phase 9.1 — Preference memory & settings (Ægil §2–3)
- [ ] `agent_settings` (level 0–4, allowed_store_mode/ids, allowed_categories, cap_per_order, cap_per_week, quiet_hours, learning_enabled, paused_until, push_mode, against_interest_enabled, read_aloud); default level 2; level 4 → `422 LEVEL_REQUIRES_RECURRING` until Week 11+
- [ ] `preferences` (kind incl. allergen/diet as hard constraints never inferred, exclusion_product/store, source stated/onboarding/chat/settings/feedback)
- [ ] Free-text → structured rows via `agent.aegil_customer` (5s deadline, fallback to unstructured `note`); `/me/memory` fully readable + `forget_all`
- [ ] `product_identities` + `reference_prices` (EAN for groceries, store_product_id for restaurants)

### Phase 9.2 — Onboarding (Ægil §4)
- [ ] Chip-card batch flow (`POST /me/preferences/batch`, `PATCH /me/agent_settings`), skip with 7-day re-invite, guests onboarded after first delivery, summary sentence (model with template fallback), AI disclosure

### Phase 9.3 — Signals, matching, suggestion tray (Ægil §5, §7)
- [ ] Signal ingestion: `feed.post.published` (offer/arrival types), `product.price_changed`, scheduler (rhythm), rewards engine (threshold), availability
- [ ] Deterministic match: eligibility → weighted score (`policy.agent.match_weights`) → threshold → dedup → daily pool (20); 9 reason codes
- [ ] `suggestions` machine (`candidate|open|dismissed|never|added|merged|expired`); tray `GET /me/suggestions`, add / dismiss / never; **no cart merge** (level ≤ 2)
- [ ] Re-ranking in **shadow mode** only (`rerank_source` logged, engine top-N served)
- [ ] `suggestion_feedback` ("Ikke for meg" + reason codes) → bounded ±30 %, 90-day decaying weights, visible in memory
- [ ] Dagens napp now fires from a real `suggestion.reeled`; missions personalised by `agent.aegil_customer` wording; welcome-gift reason text; Ægil-proposed `point_goals`

### Phase 9.4 — Against-interest engine (Ægil §6)
- [ ] Checks `cheaper_elsewhere`, `already_have`, `wait_for_offer`, `not_needed`, `threshold_trap`, `store_unreliable` — rule-based, each with line code + alternative action
- [ ] `against_interest_events` written every evaluation whether or not shown; user can silence lines, never logging
- [ ] `reminders` for wait-for-offer; `availability_subscriptions` ("Si fra når det finnes", 60-day auto-cancel)
- [ ] Customer app: tray, against-interest line first in chat/cart turn, "Mens du var borte" action log (`agent_actions`, 30-day user view), settings screen with level explanation, trust ledger card in Meg (saved_kr, finds_applied, against_interest_shown, wait_recommended, cheaper_elsewhere_taken)

### Phase 9.5 — Bud agents B1, B2, B3
- [ ] **B1 `agent.bud_translate`**: nb/pl/en labels for offer, stages, notes, problem sheet, earnings — numbers/codes/addresses/times untouched, "vis original", dotted-underline fallback, language in Innstillinger
- [ ] **B2 `agent.bud_problem`**: hold-to-speak with live transcript, high-confidence → prefilled form, low-confidence → 2-option disambiguation, photo hint, offline "venter på nett", visible on Partner side
- [ ] **B3 `agent.bud_door`**: "Si noe om døren" → transcript → editable chips → consent state → `door_profiles` note for the next courier

### Phase 9.6 — Partner agents P3, P4 & Innsikt/Oppgjør
- [ ] **P3 `agent.campaign_planner`**: observation → proposal with expected effect (confidence + basis) → feed-post draft → publish creates offer + post → live forecast → next-day result card; "ikke nå" / re-suggest
- [ ] **P4 `agent.onboarding`**: "Sett opp med Ægil" hours Q&A → summary with per-row correction → saved → triggers the test order; AI menu import (PDF/website/EAN) in onboarding
- [ ] Innsikt: 11 metric rows with 8-week charts, "Ukens melding", campaign card on top; Oppgjør: paid-yesterday figure, 7 daily rows (gross − commission − card fee), per-order breakdown, monthly comparison, Fiken/Tripletex/PowerOffice exports, role-gated
- [ ] Butikk: Bilder (requirements, missing-photo list, photographer booking), Enheter, Tilgang (staff roles, "vis appen som", invite), Innstillinger (language nb/nn/en, sound/push), P2 `agent.photo_enhance` before/after with QA pass/fail (original preselected on fail)

### Week 9 acceptance tests
- [ ] Stated allergen "nøtter" → any nut-containing candidate is excluded at eligibility, and no allergen is ever created by inference
- [ ] A store `tilbud` post for a liked product creates an `open` suggestion with `offer_liked_product`; "Ikke for meg" lowers that product's weight visibly in `/me/memory`
- [ ] Level 2 user: tray populates, cart is never modified; setting level 4 without a recurring agreement → `422 LEVEL_REQUIRES_RECURRING`
- [ ] Cheaper identical EAN at an allowed store → `cheaper_elsewhere` line rendered first with the alternative; event row exists even when the user has silenced lines
- [ ] `forget_all` leaves zero preference/suggestion/against-interest rows for the user
- [ ] Shadow re-rank logs `rerank_source` on 100 % of daily runs while the served tray equals engine top-N
- [ ] B1: Polish rendering of an offer changes only labels; the `Æ-42K` code, amounts and address are byte-identical
- [ ] B2 low-confidence utterance shows the two-option sheet; chosen option files the correct problem type; B3 note appears on the next courier's delivery stage only with consent given
- [ ] P3 publish creates exactly one offer and one live post; next-day result card reports attributed orders from `source_post_id`

---

## Week 10 — Security & privacy, hardening, chat services, metrics, migration cutover, rollout

### Phase 10.1 — Security & privacy (Order Ops §19)
- [ ] BankID courier verification in Bud onboarding (Identitet step) and Partner onboarding; verification date on ID-kort
- [ ] Store staff roles enforced server-side (owner vs drift; Oppgjør locked for drift)
- [ ] ES256 key rotation drill; JWKS refresh in both apps; scan rate limit 10/min/courier; API rate limits per role
- [ ] Door-profile consent + 24-month retention job; reorder-photo 24h retention (for Week 11+ C3); age-restricted hard-exclusion in Ægil eligibility
- [ ] PII minimisation audit of every agent payload; `audit_log` completeness check across admin actions

### Phase 10.2 — Ægil chat content services (Ægil §14) — priority subset
- [ ] Shopping list (`shopping_list_items`), comparison (`POST /compare`), tracking snapshot, news card (`GET /feed/posts/{id}`), reminders card, against-interest card, "Hvordan får jeg poeng?" explainer, monthly points summary card
- [ ] Chat tool allowlist enforced (no eligibility/score/merge/charge tools exposed to the model)
- [ ] Ægil communication table events wired: `points.earned`, `goal.near/reached`, `tier.promoted/review_warning`, `points.expiring`, `mission.proposed`, `league.month_closed`, monthly summary

### Phase 10.3 — Client polish: Night mode, Big-weather, offline, self-service
- [ ] Bud: Night mode full recolor at sunset; Big-weather mode (64pt targets, larger address, full-width next action) across all 7 stages; offline banner lists exact unsent items
- [ ] Partner: paused/pulse-lost/low-battery/muted banners verified; queued feed post replay; per-device sound test
- [ ] Customer: settings for Ægil level/pauses/quiet hours; points expiry reminder surfaces

### Phase 10.4 — Metrics & dashboards
- [ ] Time engine: window hit-rate, MAE; handoff: scan success, fallback share; money: waiting-pay share, payout latency
- [ ] Store: unseen rate, auto-pause count, Autodrift level mix; courier: acceptance/decline/release, autopilot share
- [ ] Points: issuance, liability, redemption, tier distribution, migration reconciliation; feed: posts/day, attributed orders, hide rate
- [ ] Agents: runs, fallback rate, override rate (> 30 % triggers scope review), kill-switch state; against-interest "saved kr"
- [ ] Alerts & on-call routing table from Order Ops §18

### Phase 10.5 — Regression from the design demo-control checklists
- [ ] Partner: all 17 simulated actions (new order, seen, courier arrives/waits, scan variants, delivered, customer unreachable, battery lost/restored, offline/online, feed down/up, escalation timers, next day, switch role, switch level)
- [ ] Bud: all 28 simulated actions (arrivals, stage advances, scans, waiting increments, problem triggers, device/network state, night/rain, language, autopilot, shift end, next day)
- [ ] Order Ops edge cases: offer expiry mid-add, sold-out at pickup, level lowered mid-flow, new allergen invalidates suggestions, address change mid-run, feed service down, token key rotation mid-shift
- [ ] Load test: 500 concurrent orders, 200 couriers streaming location, event fan-out p95 < 1s

### Phase 10.6 — Points cutover & rollout
- [ ] Final migration dry-run report signed off; customer comms (in-app + email) scheduled same day; production kroner→points run; post-run reconciliation
- [ ] Feature-flag audit: every new surface independently toggleable; staged rollout order = state machine → QR handoff → time engine → escalation/Autodrift → points → feed publishing → autopilot/stacking → agents (matches Order Ops core phases + agent track)
- [ ] Kill-switch drill for every registered agent; rollback runbook per flag
- [ ] Documentation: API contract, event catalogue, policy key reference, admin runbooks

### Week 10 acceptance tests
- [ ] Unverified courier cannot go På vakt; verified courier's ID-kort shows the BankID date
- [ ] Drift-role staff opening Oppgjør sees the locked state; owner sees figures
- [ ] Key rotation: tokens signed with the old key validate until expiry, new tokens validate immediately, both apps refresh JWKS without restart
- [ ] `POST /compare` returns only allowlisted fields; a chat prompt asking Ægil to "add it to my cart" at level 2 is refused with the level explanation
- [ ] Big-weather mode: every live-stage tap target ≥ 64pt (automated widget test)
- [ ] All 17 + 28 demo-control scenarios pass end-to-end in staging; load test meets p95 < 1s fan-out
- [ ] Production migration reconciliation within rounding; zero support tickets caused by missing balances in the first 24h monitored window
- [ ] Every agent kill switch flipped and restored during the drill with fallbacks observed; each feature flag toggled off and on with no errors in the flag audit log

---

## Appendix A — Feature traceability (every spec item → week or backlog)

**BL** = Week 11+ backlog (Appendix C).

### Order Ops v3.1 (priority 1)
| Feature | Week |
|---|---|
| Broadcasting, polling fallback, Vipps, CI preflight, feature flags | 1 |
| Policy engine (`policies`, versioning, reason + audit) | 1 |
| Order / assignment / store / device machines, order code | 1 |
| `order_events`, idempotency, fan-out | 1 |
| Device heartbeat/liveness, seen-signal, unseen timers | 2 |
| Pickup tokens, scan validation, samle-QR, fallbacks, offline verification | 3 |
| Hylleplass, self-pickup | 3 |
| Time engine layers 1–3, capacity/busy mode, windows | 4 |
| Waiting pay, run payment, trip compensation, payouts | 5 |
| Proof types, photo QA, delivery code/PIN incl. risk triggers, door profiles | 5 |
| Problems (5 types), exception triage hook, relay calls | 6 |
| Escalation ladder, auto-pause, Autodrift Auto | 6 |
| Dispatch/offers, autopilot, stacking, courier locations | 7 |
| Offline outbox, conflict resolution | 7 |
| Notification table, quiet hours, agent channel | 7 |
| Feed-service integration (webhooks, mix rule, ranking, degradation) | 7 |
| Agent platform (register, scopes, `agent_runs`, caps, kill switches, disclosure) | 8 |
| P1 menu_copy, P5 hours_exceptions, B4 bud_explain, Kjøkken voice | 8 |
| P2 photo_enhance, P3 campaign_planner, P4 onboarding, B1 translate, B2 bud_problem, B3 bud_door | 9 |
| Security/privacy, key rotation, rate limits, retention jobs | 10 |
| Admin: Nå, Unntak, Butikker, Bud, roles | 6 |
| Admin: Agenter, Feed, Points sections | 5, 8 |
| Metrics, alerts/on-call, edge cases, load test | 10 |
| `agent.editorial` (automated Ærend posts), `agent.anomaly_explain`, customer agents C1–C4, `agent.comms` beyond scripted SMS, remaining panel sections (Ordrer/Tid/Økonomi/Support/System/Revisjon full breadth) | BL |

### Points v2 (priority 2)
| Feature | Week |
|---|---|
| `points_ledger`, `points_balances`, rebuild, integrity, policy keys | 1 |
| Kjøp, Verving, Første gang, Dagens napp (stub), Missions hook, release/expire jobs | 2 |
| Nivå engine (promotion, annual review built), migration + old-mechanics removal | 3 |
| Premiehylla backend, claims/fulfilment, goals, customer points UI, monthly summary | 4 |
| Admin dashboard/ledger/rules/Nivå/Premiehylla | 5 |
| Missions v1, Fløyen-ligaen, welcome gift, admin Liga/Oppdrag | 6 |
| Ægil-personalised missions/goals/gift text, Dagens napp live | 9 |
| Communication table events, metrics, cutover | 10 |
| Ægil velger (surprise prize) — after lotteriloven review | BL |
| Partner "Tilby en premie" (partner-funded prizes, 0-kr order line with `prize_claim_id`) | BL |
| Svindel og avvik admin (referral rings, self-referral, velocity, mission farming) with `agent.anomaly_explain` | BL |
| Annual tier review firing, multi-city thresholds | BL (scheduled) |

### Partner & Bud Upgrade spec + designs (priority 3)
| Feature | Week |
|---|---|
| Device-role shell, Kasse board, Kjøkken, wake-lock/heartbeat/audio | 2 |
| Bud 7-stage shell, mode pill, ID-kort, dual status, Night mode base | 2 |
| Henting screen, Bud pickup stage, offline scan | 3 |
| Kasse timing actions, Autodrift v1, reject-with-reason | 4 |
| Bud delivery/proof, money screens, Vaktsammendrag, Mitt mål, tax export; Customer code card & ID-kort | 5 |
| Trenger deg, Autodrift complete, pause sheet, banners, detail sheet; Bud problems, offer variants | 6 |
| Bud autopilot/stacking/health/heat-map/Profil; Partner Varer, Forundringspose | 7 |
| Partner feed composer, Innstillinger, Din bestillingslenke, Åpningstider; Partner mic entry | 8 |
| Innsikt, Oppgjør + exports, Bilder, Enheter, Tilgang, Ægil chat entry in Butikk | 9 |
| Night mode full, Big-weather, offline polish, demo-control regression | 10 |
| Partner onboarding 7-step full flow (BankID → e-sign → Vipps → import/scan → photos → hours → capacity/devices → autodrift → test order), Bud onboarding 6-step full flow | 9–10 (BankID/hours/test-order pieces), remainder BL |
| Business-decision items: driver-to-driver wallet transfer, card top-up, currency picker (locked NOK) | BL (decide) |

### Feed update spec (priority 4)
| Feature | Week |
|---|---|
| `feed_post` reconciliation, change log, eligibility, webhooks, mix rule | 7 |
| Product & price management (Partner) | 7 |
| Publish-to-feed composer, post list, moderation status | 8 |
| Customer tabs, category chips, live price, inherited gap fixes | 8 |
| Admin Ærend publishing, oversight, eligibility, change-log viewer, hide product | 8 |
| Stories row (open Q1), post editing (v1 = unpublish + re-post), Ærend curation/pinning, discount/før-pris framing (after compliance review), multi-product posts | BL |

### Ægil spec (priority 5)
| Feature | Week |
|---|---|
| `agent_settings` levels 0–2, preferences, memory, forget_all, product identities | 9 |
| Onboarding chip flow | 9 |
| Signals, deterministic matching, reason codes, tray, feedback weights, shadow re-rank | 9 |
| Against-interest (6 checks), reminders, availability subscriptions, action log, trust ledger | 9 |
| Chat services (priority subset), tool allowlist, communication events | 10 |
| Level 3 cart merge + undo, Level 4 standing orders + Vipps recurring, learned patterns, live LLM re-rank, weekly grocery (Handleliste/Middag/Ukens kurv, `weekly_build`), remaining chat cards (guides, recipes, T32), C1 gift, C2 order_issue, C3 reorder_photo, C4 door_interpret | BL |

---

## Appendix B — Decisions that gate specific weeks

| Decision | Gates | Needed by |
|---|---|---|
| Vipps payout provider agreement; courier employment classification | Week 1 payouts | Week 1 |
| Waiting threshold/rate/cap, trip-compensation formula, problem payment amounts | Weeks 5–6 policy seeds | Week 4 |
| Relay number provider (Twilio proxy) | Week 6 | Week 5 |
| Kroner→points conversion factor; customer comms plan | Week 3 dry-run, Week 10 cutover | Week 2 |
| Tier thresholds confirmation (1000/3000/8000) | Week 3 | Week 2 |
| Feed: stories row v1?; post edit vs re-post; Ærend curation | Week 8 | Week 7 |
| Førpris/discount framing compliance review | Composer copy rules | Before Week 8 (else v1 blocks discount copy, as planned) |
| Ægil policy values (match weights, thresholds, tray size, TTL) | Week 9 | Week 8 |
| Lotteriloven review (Ægil velger, Forundringspose framing) | BL items | Before BL |
| Level-4 consumer-law wording, recurring agreement flow | BL | Before BL |
| Driver wallet transfer / card top-up / currency picker keep-or-remove | BL | Any time |

---

## Appendix C — Week 11+ backlog (continuation of each spec's own rollout phases)

1. **Order Ops:** `agent.editorial` (planner + writer + 15-min hold + retract, `store_editorial_settings`, fairness rotation), `agent.anomaly_explain`, customer agents C1–C4, full admin breadth (Ordrer/Tid/Økonomi/Support/System/Revisjon), full onboarding flows for Partner and Bud, remaining edge cases.
2. **Points:** Ægil velger (post legal review), partner-funded prizes, fraud tooling, annual review go-live, city-specific thresholds.
3. **Feed:** stories row, post editing, curation/pinning, compliant offer framing, multi-product posts.
4. **Ægil:** levels 3–4, learned patterns, live re-ranking, grocery/weekly basket, standing orders, remaining chat cards, trust-ledger maturation.
5. **Cross-cutting:** B1 beyond nb/pl/en, remaining metrics, deeper offline polish.
