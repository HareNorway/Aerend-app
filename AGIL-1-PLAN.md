# AGIL-1 — Order Ops backbone, Partner & Bud upgrade, Feed (agent execution plan)

**Branch:** `agil-1` on `Hare-AdminPanel`, `Hare-Store`, `Hare-Driver`, `Aerend-app/Aerend-app`, `Aerend-Feed`.

> ⚠️ `Aerend-Feed` **deploy hazard.** Its deploy branch is `master` and **every push to** `master` **auto-deploys to DigitalOcean production.** Create and stay on `agil-1` there; never push `master`. Verify with `git branch --show-current` in `D:\work\hare\Aerend-Feed` before any push. Production URLs: feed `https://aerend-feed-88chd.ondigitalocean.app`, Laravel `https://api.ailogistics.no`. **Sister plan:** `AGIL-2-PLAN.md` (branch `agil-2`: Points v2, Ægil, agent platform). Merging both yields the master plan `8-10-WEEK-IMPLEMENTATION-PLAN.md`. **Specs (authoritative order):** `aerend-app/docs/AEREND ORDER OPS SPEC FINAL STATEv3.md` → `AEREND PARTNER & BUD UPGRADE SPEC.md` (client detail) → `aerendvstore feed update spec.md`.

---



## 0. Agent operating instructions

**Read before every phase**

- The spec section named in the phase.
- The design file named in the phase. The `.dc.html` files are single-file prototypes. Map a file first with `grep -n 'data-screen-label=' <file>` (screen list) and `grep -n '<symbol id=' <file>` (SVG assets), then read the screen block. `ui_kits/partner/*.jsx`, `ui_kits/driver/*.jsx` and their `README.md` are cleaner React recreations of the same screens — use them for layout/component structure; use the `.dc.html` files for copy, states, colours and animation timings.
  - Partner: `designs/20des/Ærend Partner.dc.html`, `Ærend Partner - leveranser (steg 4).dc.html` (screen map + button ledger + state matrix — treat as the checklist), `Ærend Partner - agentfunksjoner P1-P5.dc.html`, `Ærend Partner - inventar (steg 1).dc.html`.
  - Bud: `designs/20des/Ærend Bud.dc.html`, `Ærend Bud - leveranser (steg 4).dc.html`, `Ærend Bud - agentfunksjoner B1-B4.dc.html`, `Ærend Bud - inventar (steg 1).dc.html`.
  - Both: `designs/20des/Ærend Bud og Partner - register og system.dc.html` (parity audit vs existing apps, shared status vocabulary, 18 shared components, density rules).
  - Customer: `designs/20des/Ærend Kunde Bergen.dc.html` (tracking, feed tabs, "Vågen", delivery-code card, ID-kort).
- Brand tokens already in code: `Aerend-app/lib/theme/reen_pre_club_theme.dart` (`AerendBergenAuthTokens`), `sc_saas_theme.dart`; mark asset `assets/Logo/aerend_mark_bergen.svg`. Partner/Bud keep the glass/depth "Bergen scene" treatment; Bud additionally has Night mode and Big-weather mode.

**Codebase facts**

- Backend: Laravel 8 (`Hare-AdminPanel`), models in `app/model/`, API controllers in `app/Http/Controllers/Api/*`, admin is Blade + Vue 2 (`resources/views/admin`). Broadcasting is configured but driver is `null`. Vipps is incomplete (`docs/VIPPS_GAP.md`). Feed JWT bridge exists (`Api/Auth/FeedTokenController`, `docs/FEED_JWT_KEYS.md`); the feed itself is the separate Fastify service.
- Hare-Store: custom bloc pattern (`*_bloc.dart` + `*_repo.dart` + `*_dl.dart`, rxdart); existing order tabs in `lib/screen/home`, products in `lib/screen/products`, feed in `lib/screens/feed/*`.
- Hare-Driver: `flutter_bloc`; home/map in `lib/screens/home`, offers in `newRequest`, live run in `runningRide`, wallet/bank/payment screens, background location service in `lib/services/backgroundService/`; dark theme exists but is disabled in `main.dart`.
- Aerend-app: redux app-wide, bloc inside feed; feed models `lib/data/feed/*`, repo `feed_repo.dart`, screens `lib/screens/feed/*`; networking `lib/networking/api_constant.dart` (Laravel) and `lib/networking/feed/*` (feed service).
- **Aerend-Feed** (`D:\work\hare\Aerend-Feed`, npm name `aerend-feed-service`) — the feed backend, a **separate service and separate database**, not part of the Laravel monolith. Fastify 5 + TypeScript (ESM, Node ≥24), **Drizzle ORM** over Postgres (`drizzle/`, `drizzle.config.ts`), **BullMQ + ioredis/Valkey** for queues, `jose` for the RS256 feed-JWT verification, Cloudinary for media, `firebase-admin` for FCM push, Zod for validation, pino logging, **vitest** for tests. Deployed on DigitalOcean App Platform (`do-app-platform.yaml`, `Dockerfile`, `docker-compose.dev.yml`).
  - Layout: `src/routes/*` (incl. `store-publish.ts`, `comments.ts`), `src/notifications/*` (`queue.ts`, `notification-worker.ts`, `processors.ts`, `fcm.ts`), `src/laravel/client.ts` (calls back into Laravel, e.g. `fetchDeviceTokens`), `src/migrate.ts`, `test/*`.
  - Workers are separate processes: `npm run worker:store-sync`, `npm run worker:notifications`.
  - **Read its own docs before touching it** — they are more current than anything in `aerend-app/docs`: `Aerend-Feed/docs/ARCHITECTURE.md`, `FEED_SYSTEM.md` (JWT bridge + **the** `store_details_id` **/** `provider_id` **/** `provider_service_id` **ID-mapping gotcha, §2 — get this wrong and posts attach to the wrong store**), `FEED_LAUNCH_PLAN.md`, `FEED_HANDOVER_10DAYS.md` (current open items T1–T10), `LOCAL_DEV.md`.
  - **Current state:** structurally complete and deployed, **not fully verified**. Open items from `FEED_HANDOVER_10DAYS.md` that overlap this plan: T1 Laravel `GET /api/internal/feed-device-tokens` prod verification, T2 push-notification E2E smoke test (never run on a real device), T3 story-expired-mid-view, T4 "follows but no posts" empty state, T5 Cloudinary upload-failure UX, T6 feed-JWT silent re-mint verification, T7 notification integration tests, T8 deep-link "post deleted" 404 handling, T9 demo seed post still in prod, T10 DB credential rotation. **Fold T3–T8 into Phase 9** (they are the same surfaces you are already touching); leave T1/T2/T9/T10 as ops tasks flagged in Phase 12 — they need prod access and a real device.
  - Note the handover doc predates the `Aerend-app` rename and refers to the customer app as `Hare-Customer` with feed work on branch `feed-integrated` (Hare-Store on `feed`). Our customer app is `Aerend-app/Aerend-app`; check whether the feed feature branches were already merged there before re-implementing anything.

**Commands to run for acceptance**

- Backend: `php artisan test --filter=<Phase>` (write tests under `tests/Feature/Ops/*`, `tests/Feature/Feed/*`), `php artisan route:list`, `php artisan migrate --pretend`.
- Flutter: `flutter analyze`, `flutter test` (widget/unit tests under `test/ops/*`, `test/feed/*`), `flutter build apk --debug` for compile proof.
- Feed service (`D:\work\hare\Aerend-Feed`): `npm test` (vitest), `npm run typecheck`, `npm run lint`, `npm run db:generate` (Drizzle migration from schema change) then `npm run db:migrate` against local Postgres. Local stack via `docker-compose.dev.yml` + `npm run dev` — see `docs/LOCAL_DEV.md`. **Never run** `db:migrate:prod`**.**
- "Staging" checks below are executed against a local stack (`php artisan serve` + Soketi + local feed service + the three apps on emulators); record results in the checklist. Health probes on the feed service: `/health`, `/ready`.

**Conventions**

- Additive migrations only, prefixed `ops_` / `feed_`. Routes in `routes/api_ops.php`, `routes/api_feed.php`. Controllers under `app/Http/Controllers/Ops/*`, `Feed/*`. Flutter code in the owned folders (§1). ARB keys prefixed `ops_` / `feed_`.
- Shared files (`main.dart`, `pubspec.yaml`, route registrars, admin nav) get one append per need in a commit titled `chore(shared): register <thing>`.
- One commit per phase task group; phase completion = all tasks ticked and all acceptance tests passing.

---



## 1. Ownership & merge contract (identical in both plans)


| Layer                          | agil-1 owns                                                                                                                                                                                                                                                                                           | agil-2 owns — do not touch                                                                                                                   |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Backend                        | `policies`, `feature_flags`, order/assignment/store/device machines, `order_events`, `pickup_tokens`, `scans`, time engine, money/payouts, `problems`, escalation, dispatch/autopilot/stacking, offline outbox, `notifications`, feed bridge/webhooks, `product_change_log`, `store_feed_eligibility` | `points_*`, `prizes`, `missions`, `league_*`, `agent_*`, `preferences`, `suggestions`, Ægil tables; `routes/api_points.php`, `api_agent.php` |
| **Aerend-Feed** (feed service) | everything: Drizzle schema reconciliation, ranking/mix rule, moderation endpoints, webhooks in/out, notification queue/worker changes, its tests                                                                                                                                                      | — (agil-2 only *reads* `GET /v1/posts/{id}` for the news card and consumes `feed.post.published`; it never edits this repo)                  |
| Hare-Store                     | everything (`lib/screens/ops/*`, `feed/*`, `butikk/*`, onboarding)                                                                                                                                                                                                                                    | `lib/screens/points/*`                                                                                                                       |
| Hare-Driver                    | everything (`lib/screens/live/*`, `money/*`, onboarding)                                                                                                                                                                                                                                              | —                                                                                                                                            |
| Aerend-app                     | `lib/screens/tracking/*`, `lib/screens/feed/*`, delivery code, ID-kort                                                                                                                                                                                                                                | `lib/screens/points/*`, `lib/screens/aegil/*`, Meg                                                                                           |
| Admin                          | Nå, Unntak, Butikker, Bud, Feed, policy editor                                                                                                                                                                                                                                                        | Points, Agenter                                                                                                                              |


**Sync points**

- **Sync A** (end of agil-1 Phase 1): agil-1 tags commit `sync-A` containing `policies` + `PolicyService`, `feature_flags`, status vocabulary ARB keys. agil-2 cherry-picks it. (The event contract is not part of Sync A — it is already on `main`.)
- **Sync B** (agil-2 Phase 2): agil-2 tags `sync-B` containing the agent platform substrate (`agents`, `agent_runs`, scoped tokens, kill switches, `AgentInvoker`). agil-1 cherry-picks it **before Phase 10**.

**Event contract** (agil-1 emits; agil-2 consumes): `order.delivered`, `order.cancelled`, `product.price_changed`, `feed.post.published`, `suggestion.reeled` (customer "Vågen" tap). **Already frozen on** `main` at `Hare-AdminPanel/docs/EVENT_CONTRACT.md` with canonical fixtures in `Hare-AdminPanel/tests/fixtures/events/*.json`. Your emitted payloads must validate against those fixtures (add a contract test per event in Phase 1). Do not edit the contract; extend only per its versioning rule.

**Merge day**: rebase both on `main`; merge `agil-1` then `agil-2`; migrate on a prod snapshot; agil-2 swaps its `OrderCompletionSource` to `order_events` and Ægil ingestion from fixtures to live webhooks; run both acceptance suites + master Week 10 regression (17 Partner + 28 Bud demo-control scenarios from the `leveranser (steg 4)` files); flip flags in master rollout order.

---



## Phase 1 — Foundation: infra, policy engine, state machines, events, contract

**Spec:** Order Ops §2–6, §19 (deploy conventions). **Design:** `register og system.dc.html` §"shared status vocabulary".

Tasks

- [ ] Broadcasting: set driver to Pusher-compatible (Soketi), channels `private-store.{id}`, `private-courier.{id}`, `private-customer.{id}`, `private-panel`; auth routes; polling fallback `GET /api/ops/events?since={id}`
- [ ] Vipps: implement items in `docs/VIPPS_GAP.md` for payment + payout in the Vipps test environment
- [ ] CI: `php artisan route:list` preflight; fail build if `APP_ENV=local` or `APP_DEBUG=true` in prod config
- [ ] `feature_flags` (key, enabled, targeting json: store_ids/courier_ids/customer_ids/percent)
- [ ] `policies` (key, value json, version, effective_from, changed_by, reason) + `PolicyService::get(key, version?)` with cache; every order stores `policy_version`; admin editor requires reason → `audit_log`
- [ ] Seed keys: `time.default_prep`, `time.window_widths`, `time.window_floor`, `money.waiting_threshold_s`, `money.waiting_rate`, `money.waiting_cap`, `money.base_pay`, `money.distance_rate`, `money.stacking_bonus`, `money.weather_bonus`, `money.trip_compensation`, `money.problem.*`, `dispatch.offer_timeout_s`, `dispatch.stack_proximity_m`, `dispatch.stack_window_s`, `escalation.unseen_s=[60,120,240]`
- [ ] State machines as PHP enums + `OrderTransitionService`: order `placed→accepted→seen→ready?→picked_up→arrived_customer→delivered|cancelled` (+`problem` sub-state); assignment `offered→accepted→en_route_pickup→arrived_pickup→(waiting)→picked_up→en_route_drop→arrived_drop→delivered|released|failed`; store `open↔paused_manual|paused_auto`; device `registered→alive→stale→alive`
- [ ] `order_events` (order_id, type, actor_type incl. `agent`, actor_id, payload, idempotency_key unique, occurred_at, received_at); transition = validate → event → projection → fan-out in one transaction; duplicate key returns original
- [ ] `orders` additive columns: `code`, `proof_type`, `origin`, `source_post_id`, `policy_version`, `promised_start`, `promised_end`, `predicted_ready_at`, `shelf_slot`
- [ ] Order code `Æ-42K`: unambiguous alphabet + check letter (Partner&Bud spec algorithm), unique per city/day
- [ ] Status vocabulary: server enum → ARB `ops_status_*` in all three apps (Ny/Bekreftet, Sett/Tilberedes, Klar for henting, På vei/Hentet, Levert, Åpner igjen snart)
- [ ] Contract tests `tests/Feature/Ops/EventContractTest`: each emitted event validates field-for-field against `tests/fixtures/events/<type>.json` (contract already exists on `main` — do not rewrite it); tag `sync-A`

Acceptance tests

- [ ] `tests/Feature/Ops/EventsTest`: subscribe test client → transition → event received < 1s; with broadcasting disabled, polling returns identical event
- [ ] Vipps sandbox: one payment and one payout succeed (`tests/Feature/Ops/VippsTest`, uses sandbox keys)
- [ ] `TransitionTest`: every invalid transition → `422 INVALID_TRANSITION`, no event row; same idempotency key twice → one row, same response body
- [ ] `OrderCodeTest`: 10 000 codes, zero collisions, zero characters from the ambiguous set, check letter validates 100 %
- [ ] `PolicyTest`: change without reason → 422; with reason → `audit_log` row; `PolicyService::get` returns pinned version for an old order
- [ ] `flutter analyze` clean on all three apps after ARB additions; `git cherry-pick sync-A` onto a fresh `agil-2` checkout applies with no conflicts

---



## Phase 2 — Device liveness, seen-signal, Partner & Bud shells, customer tracking

**Spec:** Order Ops §8.1–8.3, Partner&Bud §19 (client requirements). **Design:** `Ærend Partner.dc.html` (screens "Drift · Kasse", "Kjøkken"), `Ærend Bud.dc.html` (live stages, mode pill), `Kunde Bergen.dc.html` (tracking).

Tasks

- [ ] `store_devices` (store_id, role, name, push_token, battery, sound_ok, last_heartbeat_at, state); `POST /api/ops/partner/devices/heartbeat` (30s); stale after 90s; store liveness = any alive `kasse`
- [ ] `order.seen` on first render (Kjøkken auto); scheduler writes `order.unseen_escalation_{1,2,3}` at policy seconds; panel counter "unseen > 60s"
- [ ] Hare-Store: app bar (Æ mark, Drift/Butikk switch, role pill Kasse/Kjøkken/Henting, clock, mic placeholder); bottom nav Drift · Varer · Poser · Feed · Mer; Kasse board with sections Ny · Tilberedes · Klar · Hentet driven by the status enum (replace hidden tabs); order card per design (code, type, code-required flag, allergen flag, pending marker, sum, customer, items, window + countdown, shelf slot, kundeblikk placeholder, courier line); Kjøkken view (large cards, allergen line red until acknowledged and blocks Klar, auto-seen); wake-lock, audio focus for new-order sound, heartbeat sender
- [ ] Hare-Driver: mode pill Av vakt / På vakt / På oppdrag; "Tjent nå" header slot; 7-stage stepper Hent → Ankommet henting → Skann → Lever → Ankommet levering → Bevis → Levert; fixed lower-third (next action, Naviger, Ring, mic placeholder, Problem); ID-kort slot; "Butikken ser / Kunden ser" line; enable the existing dark theme as Night mode base
- [ ] Aerend-app: tracking shows status strings + promised window (never a single ETA); subscribe `private-customer.{id}` with polling fallback

Acceptance tests

- [ ] `DeviceLivenessTest`: no heartbeat 90s → `stale`; next heartbeat → `alive`; store liveness false when only a `kjokken` device is alive
- [ ] `SeenSignalTest`: render → `order.seen` ≤ 1s; no render 60s → `unseen_escalation_1` exists
- [ ] Hare-Store widget tests: board re-sorts on injected events without refresh; Kjøkken Klar button disabled until allergen acknowledged; role pill switches views over the same order list
- [ ] Hare-Driver widget test: stepper rejects out-of-order stage taps; server rejects the same with 422
- [ ] Aerend-app widget test: tracking renders window text for each status enum value; no unmapped state

---



## Phase 3 — QR pickup handoff

**Spec:** Order Ops §10. **Design:** Partner "Henting" screen; Bud "Skann" stage; `leveranser (steg 4)` QR/samle-QR states.

Tasks

- [ ] `pickup_tokens` (order_id, jws ES256, nonce, expires_at 60s, used_at); key pair + rotation config; JWKS endpoint for couriers; offline batch tokens; samle-QR token spanning an assignment
- [ ] `POST /api/ops/courier/scan`: checks in order signature → expiry → nonce reuse → order state → courier assignment; `422` codes `SIG_INVALID|TOKEN_EXPIRED|NONCE_REUSED|WRONG_STATE|NOT_ASSIGNED`; `scans` (source `qr|typed|store_confirm|panel_override`, client_ts, server_ts); rate limit 10/min/courier
- [ ] Fallbacks: typed code endpoint, store-confirm endpoint, panel override (audit)
- [ ] Hylleplass assigned on `ready` from store slot config; customer self-pickup code/QR → `delivered` with `proof_type=self_pickup`
- [ ] Hare-Store Henting: ready tiles + dimmed nearly-ready; rotating QR with 60s ring; samle-QR when one courier holds several; scan confirmation flash; slide-to-confirm with courier-pending state; typed-code fallback; self-pickup tile; Kasse actions "Utlevert til bud"/"Utlevert til kunden"
- [ ] Hare-Driver pickup stage: code + shelf slot; camera/QR scan → green confirm; rejection states per code; "Skriv kode" offline; "Be butikken bekrefte"; offline scan queue (client ts, pending marker, replay, cached-JWKS local verification); samle-QR with one-missing-order handling

Acceptance tests

- [ ] `ScanTest`: same token twice → `NONCE_REUSED`; token aged 61s → `TOKEN_EXPIRED`; other courier → `NOT_ASSIGNED`; wrong state → `WRONG_STATE`; tampered → `SIG_INVALID`; 11th scan in a minute → 429
- [ ] `SamleQrTest`: 3-order assignment → one scan marks all `picked_up`; with one not ready → two picked up, response lists the third
- [ ] Hare-Driver test: with network mocked offline, typed code validated locally and queued; on reconnect the server row has the client timestamp
- [ ] `SelfPickupTest`: customer code scanned on Henting → `delivered`, `proof_type=self_pickup`
- [ ] Shelf slot string identical in Kasse card, Henting tile, courier stage (integration test over one order)

---



## Phase 4 — Time engine, Autodrift v1, Kasse timing, customer windows

**Spec:** Order Ops §7. **Design:** Partner "Autodrift" panel (Nivå/Tider/Kapasitet), Kasse card actions, kundeblikk line; Kunde tracking window copy.

Tasks

- [ ] Layer 1 store defaults per category (`store_settings`); Layer 2 `prep_stats` EWMA per store/item/weekday/hour from `ready` and `arrived_pickup`, `assistert` confirmations double-weighted; `predicted_ready_at` on accept and every adjustment; customer window (centre = predicted + travel, width from confidence, ≥ `time.window_floor`)
- [ ] Layer 3 `order_time_adjustments` (+5/+10/+15, actor, reason, undo); capacity + queue load; busy mode widens windows; temporary prep exceptions with reset/undo
- [ ] Hare-Store Kasse: +5/+10/+15 with consequence text + undo; kundeblikk line; Manuell (Godta/Avvis) and Assistert (Bekreft tiden/Endre tid) primary actions; reject requires reason and shows refund consequence; "Solgt i kveld" header; next-courier ETA
- [ ] Hare-Store Autodrift panel: Nivå (Manuell/Assistert), Tider (defaults, read-only "lært fra kjøkkenet" sentence, exceptions), Kapasitet stepper with stated rule
- [ ] Aerend-app: window + confidence copy; re-render on `order.time_adjusted` with honest "+10 min" line

Acceptance tests

- [ ] `PrepStatsTest`: 30 seeded orders at 12 min → EWMA within 1 min of 12; assistert confirmation shifts twice as much as an unconfirmed sample
- [ ] `AdjustmentTest`: +10 changes `predicted_ready_at`, window and dispatch time in one request; undo restores all three; both write events
- [ ] `CapacityTest`: queue > capacity widens the next window by policy amount; drains → normal
- [ ] Hare-Store test: reject without reason blocked; with reason shows the refund copy from policy
- [ ] Aerend-app test: `order.time_adjusted` event re-renders window and shows the extra-time line

---



## Phase 5 — Money engine, proof & delivery code, Bud delivery/money screens, customer code card

**Spec:** Order Ops §11–12. **Design:** Bud "Lever/Bevis/Levert" stages, run summary, Inntekt, Vaktsammendrag, Mitt mål; Kunde delivery-code card + ID-kort.

Tasks

- [ ] Waiting pay: timer from `arrived_pickup` while not ready; threshold/rate/cap from policy; run payment = base + distance + waiting + stacking (+ weather); tip separate transfer; trip compensation for released/failed; `payouts`/`payout_lines`; 04:00 Vipps batch; admin adjustment requires reason
- [ ] Proof policy at order creation: `door_photo` default / `to_person_name` / `code`; triggers value threshold, age-restricted, customer choice, business, risk history; deterministic photo prevalidation (brightness/blur/size) with one retake; delivery code = QR token + PIN, 3 attempts → lockout → photo+name flagged `elevated_risk`; code orders never leave-at-door; `door_profiles` (consent, 24-month retention)
- [ ] Hare-Driver delivery: door intelligence (door line, prior entrance photo, prior note with "vis original"); geofence pre-arm; three proof captures; PIN pad with attempts; "Levert" moment (amount slide-in, Tjent nå count-up, tip ping); run summary itemized lines, goal-distance line, "Forklar"/"Si noe om døren" placeholders; waiting-fee moment at pickup
- [ ] Hare-Driver money: Inntekt Dag/Uke/Måned, per-run breakdown, tips separate, payout states, "Beste dag denne uken", tax-report export; Vaktsammendrag (both design variants); "Mitt mål" target with distance-to-goal
- [ ] Aerend-app: code card auto-shown for `proof_type=code` with reason copy; courier ID-kort from tracking; checkout toggle "Krev kode ved levering"

Acceptance tests

- [ ] `WaitingPayTest`: no accrual before threshold; correct rate after; capped; `RunPaymentTest`: stacked 2-order run equals policy formula; tip is a separate transfer row
- [ ] `PayoutBatchTest`: batch pays yesterday's runs to Vipps sandbox and marks rows paid
- [ ] `ProofPolicyTest`: age-restricted → `code`; `DeliveryCodeTest`: 3 wrong PINs → lockout → photo+name path sets `elevated_risk`; leave-at-door endpoint returns 422 for code orders
- [ ] Hare-Driver test: failed prevalidation prompts exactly one retake; export totals equal `payout_lines` sum for the seeded year
- [ ] Aerend-app test: code card renders for `proof_type=code` and is absent otherwise

---



## Phase 6 — Problems, escalation & auto-pause, Trenger deg, admin ops

**Spec:** Order Ops §8.4–8.6, §13, §18 (Nå/Unntak/Butikker/Bud). **Design:** Partner "Trenger deg", Travelmodus sheet, banners, Autodrift Puls; Bud "Problem" sheet, offer variants.

Tasks

- [ ] `problems` (type `store_closed|wrong_order|customer_unreachable|wrong_address|damage`, source `tap|voice|photo`, actor, state, resolution, payment_line_key, photos); per-type flows/closures with `money.problem.*` lines; `agent.exception_triage` hook 60s → policy default; masked relay calls (Twilio proxy) + SMS fallback
- [ ] Escalation: 60s sound+push → 120s scripted owner SMS/call → 240s `paused_auto` + exception + customer choice (wait / cancel-refund); resume with explanation card; Autodrift Auto (server auto-accept + ny→prep when alive); Puls device rows; sound/escalation test endpoint
- [ ] Hare-Store: Trenger deg list (unseen, courier waiting, allergen note, sold-out suggestion, battery/muted, courier problem card with two outcomes); return-to-store ("Mottatt" → shelf D); Autodrift Auto with consequence sheet + learning-week note; device sheet (mute/test/rename/role/remove); Travelmodus pause sheet (15/30/60/rest of day, extend all, hold-to-confirm); offline/paused/pulse-lost/low-battery/muted banners; order detail sheet (options/allergens, note, relay contact, reject with reason + refund)
- [ ] Hare-Driver: problem sheet (5 types, per-type photo hint, offline queue); customer-unreachable relay→SMS→timer→policy outcome; wrong-address corrected stop; damage closes run with protected pay; offer screen single/stacked/auto-accepted variants, payment breakdown, countdown ring, Godta/Avslå, decline→next, expiry
- [ ] Admin: Nå (orders by state, unseen, waiting couriers, paused stores, open problems); Unntak inbox with SLA timers and override actions (panel scan override, manual state change with reason); Butikker liveness board + store detail; Bud shift board + courier detail; role landing pages

Acceptance tests

- [ ] `ProblemsTest`: each type from courier → correct payment line, store card payload, customer status, exception row; triage timeout applies default
- [ ] `EscalationTest`: unseen with alive device → events at 60/120/240s; `paused_auto` + exception + customer-choice notification; resume writes `store.resumed`
- [ ] `AutoLevelTest`: new order accepted + seen ≤ 2s with zero store calls
- [ ] Relay: sandbox call log shows proxy numbers on both legs
- [ ] Admin feature test: override scan → `picked_up`, `scans.source=panel_override`, audit row
- [ ] Hare-Store/Driver widget tests for Trenger deg ordering and problem sheet per-type copy

---



## Phase 7 — Dispatch, autopilot & stacking, offline outbox, notifications, Bud profile

**Spec:** Order Ops §9, §14, §15. **Design:** Bud På vakt (Mitt mål, Neste gode time, health rows, Autopilot sheet/banner, route strip, Profil).

Tasks

- [ ] Dispatch timing from `predicted_ready_at` − travel; `offers` timeout/decline/reassign; `courier_limits` (max distance, min payout, areas, stacking); autopilot auto-accept within limits with 20s "Slipp"; stacking rules + `assignment_orders` + route order; `courier_locations` cadence (shift 15s, run 5s) + geofence radii
- [ ] Offline outbox in Hare-Store and Hare-Driver for every mutating action (scan, status, problem, note, feed post): pending markers, backoff, server-wins with client notice; Bud banner lists unsent items; Partner pending markers
- [ ] `notifications` categories/channels/throttles (order, escalation, payout, feed-follow; reserve `agent` channel definition for agil-2); deep links; preferences; quiet hours never applied to live-order events
- [ ] Hare-Driver: autopilot toggle → limits sheet → banner → auto-accept receipt with Slipp; stacked route strip with both codes; health rows (location off, battery saver, notifications off) with fix actions; "Neste gode time" historical heat-map (non-predictive copy); Profil (verification, documents, vehicle, limits, milestones plain text, payout method, Night/Big-weather toggles)

Acceptance tests

- [ ] `DispatchTest`: decline → next courier within timeout; expiry → reassign; 5 km offer not auto-accepted at 3 km limit; Slipp within 20s → `released`, no penalty line
- [ ] `StackingTest`: two qualifying orders → one assignment, one samle-QR, ordered route
- [ ] Hare-Store test: three queued actions replay in order after reconnect; conflicting server state wins and a notice is shown
- [ ] `NotificationTest`: feed-follow push suppressed in quiet hours; escalation push not suppressed
- [ ] Hare-Driver widget test: heat-map sheet contains the non-predictive disclaimer; all Profil rows render

---



## Phase 8 — Feed data layer, product & price management, Forundringspose

**Spec:** feed update spec §2, §5; Order Ops §16. **Design:** Partner "Varer" (Meny og varer), "Poser" (Forundringspose). **Repo docs:** read `Aerend-Feed/docs/FEED_SYSTEM.md` (esp. §2 ID-mapping gotcha) and `ARCHITECTURE.md` before the first schema change.

Tasks

- [ ] **Aerend-Feed** — confirm you are on branch `agil-1`, not `master` (auto-deploys to prod). Extend the existing Drizzle schema (`src/db/schema`* + `drizzle/`) rather than adding a parallel table: `posts` gains `publisher_type` (`store|aerend`, default `store`), nullable `store_id` for Ærend posts, `product_id`, `headline`, `category`, `status` (`draft|scheduled|live|hidden|removed`), `hidden_reason`, `scheduled_at`, `created_by`. Generate with `npm run db:generate`, apply locally with `npm run db:migrate` — never `db:migrate:prod`
- [ ] **Aerend-Feed** — ranking: mix rule (≤ 1 Ærend per 5 store posts, never consecutive, `drift` exempt); tabs `I nærheten` (chronological + deliverability filter) / `Følger` / `Fra Ærend`; status filter so `hidden|removed` never leak into any tab; `/health` + `/ready` already exist — extend `/ready` with a degraded flag if the Laravel bridge is unreachable
- [ ] **Aerend-Feed** — inbound webhook route for the monolith's product/store events and outbound `feed.post.published` per `Hare-AdminPanel/docs/EVENT_CONTRACT.md` (HMAC `X-Feed-Signature`, dedupe on `event_id`); Zod schemas for both directions
- [ ] Monolith: `product_change_log` (store_id, product_id, field, old, new, changed_by, changed_at); `store_feed_eligibility` (default true); webhooks → feed `product.upserted|sold_out|price_changed`, `store.updated`, `order.delivered` (`source_post_id`); inbound `feed.post.published`; no order path depends on feed
- [ ] Hare-Store Varer: create/edit/archive (name, description, images via existing Cloudinary path, category, price, availability) live immediately, every field change logged; price edit with sync-consequence copy; availability toggle with undo; search → one-tap sold-out with re-availability time; sold-out suggestion card from sales velocity
- [ ] Hare-Store Poser: Forundringspose fields (quantity, price ≤ half-value floor, value floor, pickup window, allergen exclusions, net per bag, reservations with pickup code) on the existing surprise-bag backend

Acceptance tests

- [ ] `cd D:\work\hare\Aerend-Feed && git branch --show-current` prints `agil-1` (not `master`) — check this before every commit in that repo
- [ ] Aerend-Feed: `npm run typecheck && npm run lint && npm test` all clean; new vitest cases prove a 50-post fixture obeys the mix rule and that `hidden`/`removed` posts appear in no tab; existing tests still pass
- [ ] Aerend-Feed: `npm run db:generate` produces a migration that applies cleanly to a fresh local Postgres and is **additive** (no dropped/renamed existing columns — inspect the generated SQL in `drizzle/`)
- [ ] Aerend-Feed: outbound `feed.post.published` payload validates field-for-field against `Hare-AdminPanel/tests/fixtures/events/feed.post.published.json`; a replayed `event_id` is deduped, not double-processed
- [ ] `ProductChangeLogTest`: editing name + price → two rows; `WebhookTest`: `product.price_changed` delivered ≤ 2s with retry on failure
- [ ] `FeedDegradationTest`: feed service unreachable → order placement, scan, delivery, payout all succeed; `/ready` reports degraded
- [ ] ID-mapping check: a post published by a store resolves to the correct `store_details_id` → `provider_id` → `provider_service_id` chain per `FEED_SYSTEM.md` §2 (assert the customer feed shows it under the right store, not a neighbouring one)
- [ ] Hare-Store widget tests: sold-out toggle undo restores state; Forundringspose price above half-value floor is rejected inline

---



## Phase 9 — Feed publishing & oversight (Partner composer, customer tabs, admin) + launch-readiness gaps

**Spec:** feed update spec §2.4, §3, §4. **Design:** Partner "Feed" (3-step composer, post list, detail sheet), `Kunde Bergen.dc.html` feed tabs + category chips + "Vågen"; admin Feed section (Order Ops §18.7). **Repo docs:** `Aerend-Feed/docs/FEED_HANDOVER_10DAYS.md` items T3–T8 land here — read each item's "What to build" before starting, it names the exact files.

Tasks

- [ ] Hare-Store composer: pick own product → headline + text (+ type) → preview as customer → publish; image default = product image; own post list sorted by attributed orders with reach; detail sheet (delete/expire); status "Skjult av Ærend"; scheduling/expiry; offline queue; service-down state; v1 rules: one product per post, composer blocks før-pris/discount copy; Innstillinger toggle "Ærend kan skrive om butikken min" + frequency (data only); "Din bestillingslenke" with lower-commission tracking
- [ ] Aerend-app: tabs «Publisert av butikker» / «Publisert av Ærend»; category chips from config; post → live product detail; hidden posts vanish on fetch; fix reels tab (hide unless confirmed), header heart/message icons, kebab item; feed-follow pushes; "Vågen" hook emits `suggestion.reeled` per `EVENT_CONTRACT.md`
- [ ] Admin: Ærend composer (any store product, publish now/schedule, draft→scheduled→live→hidden/removed, edit/unpublish); unified oversight (filter store/category/status/date, hide/remove with reason, immediate); eligibility toggle; change-log viewer with search; hide-product takeover; feed health card on Nå
- [ ] **T3** story-expired-mid-view: `errorBuilder` on the story image → "This story is no longer available" + store name, auto-advance after 2s, skip to next store, clean exit when none remain (`Aerend-app/lib/screens/feed/storyViewer/story_viewer_screen.dart`)
- [ ] **T4** "follows but no posts" empty state: add `hasFollows` to `FeedHomeLoaded`; `noItemsFoundIndicatorBuilder` picks `FeedEmptyFollowed` (zero follows, keeps Explore CTA) vs new `FeedEmptyNoPosts` (has follows, no CTA); ARB key `feed_empty_no_posts` in `intl_en.arb` + `intl_no.arb` ("De du følger har ikke postet ennå — sjekk tilbake snart!")
- [ ] **T5** Cloudinary upload-failure UX in the Partner composer: pre-validate > 10 MB with an immediate dialog; on `CloudinaryUploadException` show a persistent inline error + Retry instead of a vanishing snackbar (`Hare-Store/lib/screens/feed/feed_composer_screen.dart`, exception already carries `message`/`statusCode`)
- [ ] **T6** verify feed-JWT silent re-mint: confirm `FeedJwtService.forceRefresh()` really re-mints via Laravel `POST /api/auth/feed-token`, that the `feed_retry` flag prevents loops, and that a short-TTL token recovers transparently — fix only if broken
- [ ] **T7** notification integration tests in Aerend-Feed: `processFeedNewPost` happy path / no followers / followers-without-tokens / 250-follower batch splitting (asserts `fetchDeviceTokens` called 3×), `processFeedNewComment`, `processFeedNewFollower`, and error resilience (network throw must propagate so BullMQ retries). Mock `fetchDeviceTokens` and `sendFeedFcmToTokens`; do **not** mock the DB
- [ ] **T8** deep-link "post deleted": add `PostDetailNotFound` state, catch 404 specifically, render "This post is no longer available" + Go back — in both `Aerend-app/lib/screens/feed/postDetail/`* and `Hare-Store/lib/screens/feed/store_feed_post_detail_screen.dart`

Acceptance tests

- [ ] Integration: store publishes → appears in customer feed ≤ 5s under the store tab; admin hides → gone on next fetch; store post list shows "Skjult av Ærend"
- [ ] Hare-Store test: copy "før 199, nå 149" rejected with compliance message; second product cannot be attached
- [ ] Admin feature test: scheduled post flips to `live` at time; ineligible store's publish → 403 while its products stay live
- [ ] Aerend-app test: hidden post removed from list after refetch; "Vågen" tap dispatches `suggestion.reeled` with the contract payload
- [ ] T3: story with a deliberately broken `media_url` shows the expiry message and advances — no crash, no broken-image placeholder
- [ ] T4: zero follows → Explore CTA; follows with no posts → `FeedEmptyNoPosts`, no CTA; follows with posts → neither empty state
- [ ] T5: > 10 MB photo blocked before upload; airplane mode → inline error + working Retry; normal photo publishes unchanged
- [ ] T6: with a 30s-TTL token the feed recovers after expiry with no error screen and no login prompt; normal TTL unaffected
- [ ] T7: `cd D:\work\hare\Aerend-Feed && npm test -- test/notifications.test.ts` — all new cases pass, original 4 template tests still pass
- [ ] T8: post detail for a deleted post (or `postId` 999999) shows "no longer available", not a generic error — verified in both apps

---



## Phase 10 — Partner agents P1/P5, Bud B4, voice entry  *(requires* `sync-B` *cherry-picked first)*

**Spec:** Order Ops §17.7 P1, P5, B4. **Design:** `Partner - agentfunksjoner P1-P5.dc.html` (P1, P5), `Bud - agentfunksjoner B1-B4.dc.html` (B4), Partner mic entry + Kjøkken voice in `Ærend Partner.dc.html`.

Tasks

- [ ] `git cherry-pick sync-B`; register scopes for `agent.menu_copy`, `agent.hours_exceptions`, `agent.bud_explain`, `agent.exception_triage`, `agent.comms`, `agent.photo_qa` (rows are seeded by agil-2 — only add if missing)
- [ ] P1 `agent.menu_copy` via `AgentInvoker`: generate from empty/draft → use/rewrite/discard; allergen proposals unchecked and validated against allowlist; category chip; text-only mode; batch queue "Beskrivelser å se over (N)"; fallback when unavailable
- [ ] P5 `agent.hours_exceptions`: free-text → structured rows, single-row correction, holiday prompt, coherence check vs store page, parse-failure fallback; Åpningstider weekly grid + customer-facing sentence
- [ ] B4 `agent.bud_explain`: "Forklar" on run summary + Inntekt rows → per-line sentences, one follow-up, fallback, "noe er feil" → prefilled problem
- [ ] Voice: shared hold-to-speak wrapper; Kjøkken "Æ-42 klar" → confirm → undo; Partner mic entry (4 example chips, single interpreted action, confirm-can-undo, disclosure on first use)

Acceptance tests

- [ ] `MenuCopyTest`: model output containing an allergen outside the allowlist is rejected and not stored; kill switch on → fallback response within the same request
- [ ] `HoursExceptionsTest`: "stengt neste tirsdag" → one exception row; gibberish → fallback state, zero rows
- [ ] `BudExplainTest`: explanation lines sum equals `payout_lines` for the run; every invocation writes `agent_runs`
- [ ] Hare-Store widget test: voice "Æ-42 klar" requires confirm and supports undo within the toast window

---



## Phase 11 — Partner P2/P3/P4, Bud B1/B2/B3, Innsikt/Oppgjør, Butikk sections, onboarding flows

**Spec:** Order Ops §17.7 P2–P4, B1–B3; Partner&Bud §19. **Design:** `Partner - agentfunksjoner P1-P5.dc.html` (P2–P4), `Bud - agentfunksjoner B1-B4.dc.html` (B1–B3), Partner "Innsikt", "Oppgjør", "Bilder/Åpningstider/Enheter/Tilgang/Innstillinger", 7-step onboarding; Bud 6-step onboarding, Night mode, Big-weather.

Tasks

- [ ] P2 `agent.photo_enhance`: before/after (Original/Forbedret), operation chips, QA pass/fail (original preselected on fail), fallback, propagate chosen photo
- [ ] P3 `agent.campaign_planner`: observation → proposal (expected effect, confidence, basis) → post draft → publish creates offer + post → live forecast → next-day result card; "ikke nå"/re-suggest; surfaced in Innsikt + "Ukens melding"
- [ ] P4 `agent.onboarding`: "Sett opp med Ægil" hours Q&A → summary with per-row correction → save → triggers test order; AI menu import (PDF/website/EAN)
- [ ] Innsikt (11 metric rows, 8-week charts, Ukens melding, campaign card); Oppgjør (paid yesterday, 7 rows gross−commission−fee, per-order, monthly, Fiken/Tripletex/PowerOffice exports, role-gated)
- [ ] Butikk: Bilder (requirements, missing list with impact line, photographer booking); Enheter; Tilgang (roles, "vis appen som", invite); Innstillinger (nb/nn/en, sound/push, support, re-run onboarding); Ægil chat entry in Butikk (draft action-cards execute only on tap)
- [ ] B1 `agent.bud_translate` nb/pl/en labels only ("vis original", dotted fallback, language setting); B2 `agent.bud_problem` hold-to-speak (live transcript, confidence branch, two-option disambiguation, photo hint, offline "venter på nett", visible on Partner side); B3 `agent.bud_door` ("Si noe om døren" → chips → consent → next-courier note)
- [ ] Partner onboarding 7 steps (BankID mock → e-sign → Vipps connect → menu import/shelf scan → photo pair → hours/P4 → capacity + device roles + sound test → Autodrift level → test order Kasse→Kjøkken→Henting), saved position
- [ ] Bud onboarding 6 steps (Identitet BankID → Dokumenter/kjøretøy → Utbetaling → Tillatelser with consequences → "Slik virker en tur" 7-stage demo → Autopilot + language), ends Av vakt
- [ ] Night mode full recolor at sunset; Big-weather mode (64pt targets, larger address, full-width next action) across all 7 stages

Acceptance tests

- [ ] `CampaignPlannerTest`: publish creates exactly one offer + one live post; result card counts orders with `source_post_id`
- [ ] Hare-Store tests: P2 QA fail leaves original selected; P4 row correction updates saved hours; drift-role user sees Oppgjør locked
- [ ] Hare-Driver tests: B1 Polish render leaves code/amounts/address byte-identical; B2 low-confidence shows two options and files the chosen type; B3 note shown to next courier only with consent; Big-weather widget test: every live-stage tap target ≥ 64pt
- [ ] Both onboarding flows complete end-to-end in emulator and land on Drift / Av vakt; resume from a saved step works

---



## Phase 12 — Security, metrics, regression, merge

**Spec:** Order Ops §19–§24. **Design:** `leveranser (steg 4)` §4 demo-control lists (17 Partner, 28 Bud).

Tasks

- [ ] BankID verification enforced (unverified courier cannot go På vakt; ID-kort shows date); staff roles server-side; ES256 rotation drill + JWKS refresh in both apps; API rate limits per role; door-profile retention job; `audit_log` completeness for every admin action
- [ ] Metrics jobs + dashboards: time (window hit-rate, MAE), handoff (scan success, fallback share), money (waiting share, payout latency), store (unseen rate, auto-pause count, level mix), courier (accept/decline/release, autopilot share), feed (posts/day, attributed orders, hide rate); alert routing table
- [ ] Regression suite: automate the 17 Partner + 28 Bud demo-control scenarios as integration tests; Order Ops edge cases (offer expiry mid-add, sold-out at pickup, address change mid-run, feed down, key rotation mid-shift); load 500 orders / 200 couriers streaming
- [ ] Merge prep: rebase on `main`; verify only owned paths changed (`git diff --stat main..agil-1`); `chore(shared)` commits isolated; feature flag per surface; rollback runbook; docs (API, events, policy keys) updated; execute merge-day checklist with agil-2
- [ ] **Aerend-Feed merge guard:** that repo's deploy branch is `master` and pushes auto-deploy. Do **not** merge `agil-1` → `master` yourself. Rebase `agil-1` on `master`, run the full suite (`npm run typecheck && npm run lint && npm test`), push `agil-1` **only**, and hand the merge to a human (per `FEED_HANDOVER_10DAYS.md` §6, merging to deploy branches needs sign-off)
- [ ] **Flag for a human, do not attempt** — these need prod access, a real device, or DO dashboard rights, so leave them as written notes in this file rather than acting: **T1** verify `GET /api/internal/feed-device-tokens` is live in prod (`curl` expects 401/403; a 404 means Laravel needs a `workflow_dispatch` deploy); **T2** push-notification E2E smoke test on two real devices (store publishes → customer push in ≤ 30s → deep-link; comment → store push), the single most important unverified path in the feed; **T9** delete the demo seed post still in prod (post id `1`, likely `store_details_id` 45 — confirm before deleting, real partner posts may exist); **T10** rotate `aerend-feed-pg` + `aerend-feed-redis` credentials and redeploy (do after T2, causes ~30s downtime)
- [ ] Also flag the two out-of-band items from `FEED_HANDOVER_10DAYS.md` §4: partner content seeding (10–15 stores × 3–5 posts before launch — BD work, not engineering) and native Norwegian review of the 23 machine-translated feed ARB keys

Acceptance tests

- [ ] `SecurityTest`: unverified courier → 403 on go-online; drift staff → 403 on Oppgjør; old-key token valid until expiry, new-key token valid immediately
- [ ] All 45 demo-control scenarios green; edge-case tests green; load test fan-out p95 < 1s
- [ ] `git merge agil-1` onto `main` clean; post-merge master Week 10 regression green; every feature flag toggled off/on without errors
- [ ] `cd D:\work\hare\Aerend-Feed && git log master..agil-1 --oneline` shows your work is on `agil-1` and `git log agil-1..master` shows you never pushed to `master`
- [ ] T1/T2/T9/T10 each have a written status note in this file (done-by-human, blocked, or pending) — none silently dropped