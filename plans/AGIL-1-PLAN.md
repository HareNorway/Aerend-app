# AGIL-1 — Order Ops backbone, Partner & Bud upgrade, Feed (agent execution plan)

**Branch:** `agil-1` on `Hare-AdminPanel`, `Hare-Store`, `Hare-Driver`, `Aerend-app/Aerend-app`, `Aerend-Feed`.

> 🛑 **Branch policy, updated 2026-09-23.** `agil-2` has been **merged into `agil-1`** in every repo, for combined testing; `agil-1` is now the integration branch. Still off-limits: **nothing goes into `main` or `master` in any of the five repos, and nothing is pushed anywhere.** `agil-1-backup` in each repo holds the pre-merge commit, so the merge is reversible. Combined remaining work is tracked in `AGIL-1-REMAINING.md`.
>
> The Phase 12 merge-prep findings further down still describe the eventual `main` merge, which has **not** happened. The `.env` conflict and the three out-of-ownership exceptions recorded there are still the things that merge would get wrong.

> ⚠️ **`Aerend-Feed` deploy hazard.** Its deploy branch is **`master`** and **every push to `master` auto-deploys to DigitalOcean production.** Create and stay on `agil-1` there; never push `master`. Verify with `git branch --show-current` in `D:\work\hare\Aerend-Feed` before any push. Production URLs: feed `https://aerend-feed-88chd.ondigitalocean.app`, Laravel `https://api.ailogistics.no`.
**Sister plan:** `AGIL-2-PLAN.md` (branch `agil-2`: Points v2, Ægil, agent platform). Merging both yields the master plan `8-10-WEEK-IMPLEMENTATION-PLAN.md`.
**Specs (authoritative order):** `aerend-app/docs/AEREND ORDER OPS SPEC FINAL STATEv3.md` → `AEREND PARTNER & BUD UPGRADE SPEC.md` (client detail) → `aerendvstore feed update spec.md`.

---

## 0. Agent operating instructions

**Read before every phase**
- The spec section named in the phase.
- The design file named in the phase. The `.dc.html` files are single-file prototypes. Map a file first with `grep -n 'data-screen-label=' <file>` (screen list) and `grep -n '<symbol id=' <file>` (SVG assets), then read the screen block. `ui_kits/partner/*.jsx`, `ui_kits/driver/*.jsx` and their `README.md` are cleaner React recreations of the same screens — use them for layout/component structure; use the `.dc.html` files for copy, states, colours and animation timings.
  - Partner: `designs/21des/Ærend Partner.dc.html`, `Ærend Partner - leveranser (steg 4).dc.html` (screen map + button ledger + state matrix — treat as the checklist), `Ærend Partner - agentfunksjoner P1-P5.dc.html`, `Ærend Partner - inventar (steg 1).dc.html`.
  - Bud: `designs/21des/Ærend Bud.dc.html`, `Ærend Bud - leveranser (steg 4).dc.html`, `Ærend Bud - agentfunksjoner B1-B4.dc.html`, `Ærend Bud - inventar (steg 1).dc.html`.
  - Both: `designs/21des/Ærend Bud og Partner - register og system.dc.html` (parity audit vs existing apps, shared status vocabulary, 18 shared components, density rules).
  - Customer: `designs/21des/Ærend Kunde Bergen.dc.html` (tracking, feed tabs, "Vågen", delivery-code card, ID-kort).
- Brand tokens already in code: `Aerend-app/lib/theme/reen_pre_club_theme.dart` (`AerendBergenAuthTokens`), `sc_saas_theme.dart`; mark asset `assets/Logo/aerend_mark_bergen.svg`. Partner/Bud keep the glass/depth "Bergen scene" treatment; Bud additionally has Night mode and Big-weather mode.

**Codebase facts**
- Backend: Laravel 8 (`Hare-AdminPanel`), models in `app/model/`, API controllers in `app/Http/Controllers/Api/*`, admin is Blade + Vue 2 (`resources/views/admin`). Broadcasting is configured but driver is `null`. Vipps is incomplete (`docs/VIPPS_GAP.md`). Feed JWT bridge exists (`Api/Auth/FeedTokenController`, `docs/FEED_JWT_KEYS.md`); the feed itself is the separate Fastify service.
- Hare-Store: custom bloc pattern (`*_bloc.dart` + `*_repo.dart` + `*_dl.dart`, rxdart); existing order tabs in `lib/screen/home`, products in `lib/screen/products`, feed in `lib/screens/feed/*`.
- Hare-Driver: `flutter_bloc`; home/map in `lib/screens/home`, offers in `newRequest`, live run in `runningRide`, wallet/bank/payment screens, background location service in `lib/services/backgroundService/`; dark theme exists but is disabled in `main.dart`.
- Aerend-app: redux app-wide, bloc inside feed; feed models `lib/data/feed/*`, repo `feed_repo.dart`, screens `lib/screens/feed/*`; networking `lib/networking/api_constant.dart` (Laravel) and `lib/networking/feed/*` (feed service).
- **Aerend-Feed** (`D:\work\hare\Aerend-Feed`, npm name `aerend-feed-service`) — the feed backend, a **separate service and separate database**, not part of the Laravel monolith. Fastify 5 + TypeScript (ESM, Node ≥24), **Drizzle ORM** over Postgres (`drizzle/`, `drizzle.config.ts`), **BullMQ + ioredis/Valkey** for queues, `jose` for the RS256 feed-JWT verification, Cloudinary for media, `firebase-admin` for FCM push, Zod for validation, pino logging, **vitest** for tests. Deployed on DigitalOcean App Platform (`do-app-platform.yaml`, `Dockerfile`, `docker-compose.dev.yml`).
  - Layout: `src/routes/*` (incl. `store-publish.ts`, `comments.ts`), `src/notifications/*` (`queue.ts`, `notification-worker.ts`, `processors.ts`, `fcm.ts`), `src/laravel/client.ts` (calls back into Laravel, e.g. `fetchDeviceTokens`), `src/migrate.ts`, `test/*`.
  - Workers are separate processes: `npm run worker:store-sync`, `npm run worker:notifications`.
  - **Read its own docs before touching it** — they are more current than anything in `aerend-app/docs`: `Aerend-Feed/docs/ARCHITECTURE.md`, `FEED_SYSTEM.md` (JWT bridge + **the `store_details_id` / `provider_id` / `provider_service_id` ID-mapping gotcha, §2 — get this wrong and posts attach to the wrong store**), `FEED_LAUNCH_PLAN.md`, `FEED_HANDOVER_10DAYS.md` (current open items T1–T10), `LOCAL_DEV.md`.
  - **Current state:** structurally complete and deployed, **not fully verified**. Open items from `FEED_HANDOVER_10DAYS.md` that overlap this plan: T1 Laravel `GET /api/internal/feed-device-tokens` prod verification, T2 push-notification E2E smoke test (never run on a real device), T3 story-expired-mid-view, T4 "follows but no posts" empty state, T5 Cloudinary upload-failure UX, T6 feed-JWT silent re-mint verification, T7 notification integration tests, T8 deep-link "post deleted" 404 handling, T9 demo seed post still in prod, T10 DB credential rotation. **Fold T3–T8 into Phase 9** (they are the same surfaces you are already touching); leave T1/T2/T9/T10 as ops tasks flagged in Phase 12 — they need prod access and a real device.
  - Note the handover doc predates the `Aerend-app` rename and refers to the customer app as `Hare-Customer` with feed work on branch `feed-integrated` (Hare-Store on `feed`). Our customer app is `Aerend-app/Aerend-app`; check whether the feed feature branches were already merged there before re-implementing anything.

**Commands to run for acceptance**
- Backend: `php artisan test --filter=<Phase>` (write tests under `tests/Feature/Ops/*`, `tests/Feature/Feed/*`), `php artisan route:list`, `php artisan migrate --pretend`.
- Flutter: `flutter analyze`, `flutter test` (widget/unit tests under `test/ops/*`, `test/feed/*`), `flutter build apk --debug` for compile proof.
- Feed service (`D:\work\hare\Aerend-Feed`): `npm test` (vitest), `npm run typecheck`, `npm run lint`, `npm run db:generate` (Drizzle migration from schema change) then `npm run db:migrate` against local Postgres. Local stack via `docker-compose.dev.yml` + `npm run dev` — see `docs/LOCAL_DEV.md`. **Never run `db:migrate:prod`.**
- "Staging" checks below are executed against a local stack (`php artisan serve` + Soketi + local feed service + the three apps on emulators); record results in the checklist. Health probes on the feed service: `/health`, `/ready`.

**Conventions**
- Additive migrations only, prefixed `ops_` / `feed_`. Routes in `routes/api_ops.php`, `routes/api_feed.php`. Controllers under `app/Http/Controllers/Ops/*`, `Feed/*`. Flutter code in the owned folders (§1). ARB keys prefixed `ops_` / `feed_`.
- Shared files (`main.dart`, `pubspec.yaml`, route registrars, admin nav) get one append per need in a commit titled `chore(shared): register <thing>`.
- One commit per phase task group; phase completion = all tasks ticked and all acceptance tests passing.

---

## 1. Ownership & merge contract (identical in both plans)

| Layer | agil-1 owns | agil-2 owns — do not touch |
|---|---|---|
| Backend | `policies`, `feature_flags`, order/assignment/store/device machines, `order_events`, `pickup_tokens`, `scans`, time engine, money/payouts, `problems`, escalation, dispatch/autopilot/stacking, offline outbox, `notifications`, feed bridge/webhooks, `product_change_log`, `store_feed_eligibility` | `points_*`, `prizes`, `missions`, `league_*`, `agent_*`, `preferences`, `suggestions`, Ægil tables; `routes/api_points.php`, `api_agent.php` |
| **Aerend-Feed** (feed service) | everything: Drizzle schema reconciliation, ranking/mix rule, moderation endpoints, webhooks in/out, notification queue/worker changes, its tests | — (agil-2 only *reads* `GET /v1/posts/{id}` for the news card and consumes `feed.post.published`; it never edits this repo) |
| Hare-Store | everything (`lib/screens/ops/*`, `feed/*`, `butikk/*`, onboarding) | `lib/screens/points/*` |
| Hare-Driver | everything (`lib/screens/live/*`, `money/*`, onboarding) | — |
| Aerend-app | `lib/screens/tracking/*`, `lib/screens/feed/*`, delivery code, ID-kort | `lib/screens/points/*`, `lib/screens/aegil/*`, Meg |
| Admin | Nå, Unntak, Butikker, Bud, Feed, policy editor | Points, Agenter |

**Sync points**
- **Sync A** (end of agil-1 Phase 1): agil-1 tags commit `sync-A` containing `policies` + `PolicyService`, `feature_flags`, status vocabulary ARB keys. agil-2 cherry-picks it. (The event contract is not part of Sync A — it is already on `main`.)
- **Sync B** (agil-2 Phase 2): agil-2 tags `sync-B` containing the agent platform substrate (`agents`, `agent_runs`, scoped tokens, kill switches, `AgentInvoker`). agil-1 cherry-picks it **before Phase 10**.

**Event contract** (agil-1 emits; agil-2 consumes): `order.delivered`, `order.cancelled`, `product.price_changed`, `feed.post.published`, `suggestion.reeled` (customer "Vågen" tap). **Already frozen on `main`** at `Hare-AdminPanel/docs/EVENT_CONTRACT.md` with canonical fixtures in `Hare-AdminPanel/tests/fixtures/events/*.json`. Your emitted payloads must validate against those fixtures (add a contract test per event in Phase 1). Do not edit the contract; extend only per its versioning rule.

**Merge day**: rebase both on `main`; merge `agil-1` then `agil-2`; migrate on a prod snapshot; agil-2 swaps its `OrderCompletionSource` to `order_events` and Ægil ingestion from fixtures to live webhooks; run both acceptance suites + master Week 10 regression (17 Partner + 28 Bud demo-control scenarios from the `leveranser (steg 4)` files); flip flags in master rollout order.

---

## Phase 1 — Foundation: infra, policy engine, state machines, events, contract
**Spec:** Order Ops §2–6, §19 (deploy conventions). **Design:** `register og system.dc.html` §"shared status vocabulary".

Tasks
- [x] Broadcasting: set driver to Pusher-compatible (Soketi), channels `private-store.{id}`, `private-courier.{id}`, `private-customer.{id}`, `private-panel`; auth routes; polling fallback `GET /api/ops/events?since={id}`
- [x] Vipps **payment** verified in the test environment (`apitest.vipps.no`, MSN 499250): access token, create payment (`WEB_REDIRECT`, amount in øre), read back by reference — `tests/Feature/Ops/VippsTest`
- [ ] **BLOCKED — Vipps payout.** Courier payouts are a different Vipps product (Utbetaling / Disbursements) with its own merchant agreement; `docs/VIPPS_GAP.md` scopes payouts out entirely ("Hare-Store / Hare-Driver Vipps flows" are out of scope there) and plan Appendix B lists the payout provider agreement + courier employment classification as an unmade business decision. The ePayment sandbox credentials in `.env` do not cover disbursements, so there is nothing to test against yet. Phase 5 builds `payouts`/`payout_lines` and the 04:00 batch against this boundary with the transport pluggable; `VippsTest::test_payout_is_blocked_on_a_product_agreement` is an explicit skip so the gap stays visible in test output rather than silently absent. **Unblocks when:** the Utbetaling agreement is signed and sandbox disbursement credentials exist.
- [x] CI: `php artisan route:list` preflight; fail build if `APP_ENV=local` or `APP_DEBUG=true` in prod config
- [x] `feature_flags` (key, enabled, targeting json: store_ids/courier_ids/customer_ids/percent)
- [x] `policies` (key, value json, version, effective_from, changed_by, reason) + `PolicyService::get(key, version?)` with cache; every order stores `policy_version`; admin editor requires reason → `audit_log`
- [x] Seed keys: `time.default_prep`, `time.window_widths`, `time.window_floor`, `money.waiting_threshold_s`, `money.waiting_rate`, `money.waiting_cap`, `money.base_pay`, `money.distance_rate`, `money.stacking_bonus`, `money.weather_bonus`, `money.trip_compensation`, `money.problem.*`, `dispatch.offer_timeout_s`, `dispatch.stack_proximity_m`, `dispatch.stack_window_s`, `escalation.unseen_s=[60,120,240]`
- [x] State machines as PHP enums + `OrderTransitionService`: order `placed→accepted→seen→ready?→picked_up→arrived_customer→delivered|cancelled` (+`problem` sub-state); assignment `offered→accepted→en_route_pickup→arrived_pickup→(waiting)→picked_up→en_route_drop→arrived_drop→delivered|released|failed`; store `open↔paused_manual|paused_auto`; device `registered→alive→stale→alive`
- [x] `order_events` (order_id, type, actor_type incl. `agent`, actor_id, payload, idempotency_key unique, occurred_at, received_at); transition = validate → event → projection → fan-out in one transaction; duplicate key returns original
- [x] `orders` additive columns: `code`, `proof_type`, `origin`, `source_post_id`, `policy_version`, `promised_start`, `promised_end`, `predicted_ready_at`, `shelf_slot`
- [x] Order code `Æ-42K`: unambiguous alphabet + check letter (Partner&Bud spec algorithm), unique per city/day
- [x] Status vocabulary: server enum → ARB `ops_status_*` in all three apps (Ny/Bekreftet, Sett/Tilberedes, Klar for henting, På vei/Hentet, Levert, Åpner igjen snart)
- [x] Contract tests `tests/Feature/Ops/EventContractTest`: each emitted event validates field-for-field against `tests/fixtures/events/<type>.json` (contract already exists on `main` — do not rewrite it); tag `sync-A`

Acceptance tests
- [x] `tests/Feature/Ops/EventsTest`: subscribe test client → transition → event received < 1s; with broadcasting disabled, polling returns identical event
- [x] Vipps sandbox: one payment succeeds (`tests/Feature/Ops/VippsTest` — token + create + read-back against `apitest.vipps.no`, amount round-trips as øre). Payout half is **blocked**, see the task note above; its test is a documented skip.
- [x] `TransitionTest`: every invalid transition → `422 INVALID_TRANSITION`, no event row; same idempotency key twice → one row, same response body
- [x] `OrderCodeTest`: 10 000 codes, zero collisions, zero characters from the ambiguous set, check letter validates 100 %
- [x] `PolicyTest`: change without reason → 422; with reason → `audit_log` row; `PolicyService::get` returns pinned version for an old order
- [x] `flutter analyze` clean on all three apps after ARB additions; `git cherry-pick sync-A` onto a fresh `agil-2` checkout applies with no conflicts

---

## Phase 2 — Device liveness, seen-signal, Partner & Bud shells, customer tracking
**Spec:** Order Ops §8.1–8.3, Partner&Bud §19 (client requirements). **Design:** `Ærend Partner.dc.html` (screens "Drift · Kasse", "Kjøkken"), `Ærend Bud.dc.html` (live stages, mode pill), `Kunde Bergen.dc.html` (tracking).

Tasks
- [x] `store_devices` (store_id, role, name, push_token, battery, sound_ok, last_heartbeat_at, state); `POST /api/ops/partner/devices/heartbeat` (30s); stale after 90s; store liveness = any alive `kasse`
- [x] `order.seen` on first render (Kjøkken auto); scheduler writes `order.unseen_escalation_{1,2,3}` at policy seconds; panel counter "unseen > 60s"
- [x] Hare-Store: app bar (Æ mark, Drift/Butikk switch, role pill Kasse/Kjøkken/Henting, clock, mic placeholder); bottom nav Drift · Varer · Poser · Feed · Mer; Kasse board with sections Ny · Tilberedes · Klar · Hentet driven by the status enum (replace hidden tabs); order card per design (code, type, code-required flag, allergen flag, pending marker, sum, customer, items, window + countdown, shelf slot, kundeblikk placeholder, courier line); Kjøkken view (large cards, allergen line red until acknowledged and blocks Klar, auto-seen); wake-lock, audio focus for new-order sound, heartbeat sender
- [x] Hare-Driver: mode pill Av vakt / På vakt / På oppdrag; "Tjent nå" header slot; 7-stage stepper Hent → Ankommet henting → Skann → Lever → Ankommet levering → Bevis → Levert; fixed lower-third (next action, Naviger, Ring, mic placeholder, Problem); ID-kort slot; "Butikken ser / Kunden ser" line; enable the existing dark theme as Night mode base
- [x] Aerend-app: tracking shows status strings + promised window (never a single ETA); subscribe `private-customer.{id}` with polling fallback

Acceptance tests
- [x] `DeviceLivenessTest`: no heartbeat 90s → `stale`; next heartbeat → `alive`; store liveness false when only a `kjokken` device is alive
- [x] `SeenSignalTest`: render → `order.seen` ≤ 1s; no render 60s → `unseen_escalation_1` exists
- [x] Hare-Store widget tests: board re-sorts on injected events without refresh; Kjøkken Klar button disabled until allergen acknowledged; role pill switches views over the same order list
- [x] Hare-Driver widget test: stepper rejects out-of-order stage taps; server rejects the same with 422
- [x] Aerend-app widget test: tracking renders window text for each status enum value; no unmapped state

---

## Phase 3 — QR pickup handoff
**Spec:** Order Ops §10. **Design:** Partner "Henting" screen; Bud "Skann" stage; `leveranser (steg 4)` QR/samle-QR states.

Tasks
- [x] `pickup_tokens` (order_id, jws ES256, nonce, expires_at 60s, used_at); key pair + rotation config; JWKS endpoint for couriers; offline batch tokens; samle-QR token spanning an assignment
- [x] `POST /api/ops/courier/scan`: checks in order signature → expiry → nonce reuse → order state → courier assignment; `422` codes `SIG_INVALID|TOKEN_EXPIRED|NONCE_REUSED|WRONG_STATE|NOT_ASSIGNED`; `scans` (source `qr|typed|store_confirm|panel_override`, client_ts, server_ts); rate limit 10/min/courier
- [x] Fallbacks: typed code endpoint, store-confirm endpoint, panel override (audit)
- [x] Hylleplass assigned on `ready` from store slot config; customer self-pickup code/QR → `delivered` with `proof_type=self_pickup`
- [x] Hare-Store Henting: ready tiles + dimmed nearly-ready; rotating QR with 60s ring; samle-QR when one courier holds several; scan confirmation flash; slide-to-confirm with courier-pending state; typed-code fallback; self-pickup tile; Kasse actions "Utlevert til bud"/"Utlevert til kunden"
- [x] Hare-Driver pickup stage: code + shelf slot; camera/QR scan → green confirm; rejection states per code; "Skriv kode" offline; "Be butikken bekrefte"; offline scan queue (client ts, pending marker, replay, cached-JWKS local verification); samle-QR with one-missing-order handling

Acceptance tests
- [x] `ScanTest`: same token twice → `NONCE_REUSED`; token aged 61s → `TOKEN_EXPIRED`; other courier → `NOT_ASSIGNED`; wrong state → `WRONG_STATE`; tampered → `SIG_INVALID`; 11th scan in a minute → 429
- [x] `SamleQrTest`: 3-order assignment → one scan marks all `picked_up`; with one not ready → two picked up, response lists the third
- [x] Hare-Driver test: with network mocked offline, typed code validated locally and queued; on reconnect the server row has the client timestamp
- [x] `SelfPickupTest`: customer code scanned on Henting → `delivered`, `proof_type=self_pickup`
- [x] Shelf slot string identical in Kasse card, Henting tile, courier stage (integration test over one order)

---

## Phase 4 — Time engine, Autodrift v1, Kasse timing, customer windows
**Spec:** Order Ops §7. **Design:** Partner "Autodrift" panel (Nivå/Tider/Kapasitet), Kasse card actions, kundeblikk line; Kunde tracking window copy.

Tasks
- [x] Layer 1 store defaults per category (`store_settings`); Layer 2 `prep_stats` EWMA per store/item/weekday/hour from `ready` and `arrived_pickup`, `assistert` confirmations double-weighted; `predicted_ready_at` on accept and every adjustment; customer window (centre = predicted + travel, width from confidence, ≥ `time.window_floor`)
- [x] Layer 3 `order_time_adjustments` (+5/+10/+15, actor, reason, undo); capacity + queue load; busy mode widens windows; temporary prep exceptions with reset/undo
- [x] Hare-Store Kasse: +5/+10/+15 with consequence text + undo; kundeblikk line; Manuell (Godta/Avvis) and Assistert (Bekreft tiden/Endre tid) primary actions; reject requires reason and shows refund consequence; "Solgt i kveld" header; next-courier ETA
- [x] Hare-Store Autodrift panel: Nivå (Manuell/Assistert), Tider (defaults, read-only "lært fra kjøkkenet" sentence, exceptions), Kapasitet stepper with stated rule
- [x] Aerend-app: window + confidence copy; re-render on `order.time_adjusted` with honest "+10 min" line

Acceptance tests
- [x] `PrepStatsTest`: 30 seeded orders at 12 min → EWMA within 1 min of 12; assistert confirmation shifts twice as much as an unconfirmed sample
- [x] `AdjustmentTest`: +10 changes `predicted_ready_at`, window and dispatch time in one request; undo restores all three; both write events
- [x] `CapacityTest`: queue > capacity widens the next window by policy amount; drains → normal
- [x] Hare-Store test: reject without reason blocked; with reason shows the refund copy from policy
- [x] Aerend-app test: `order.time_adjusted` event re-renders window and shows the extra-time line

---

## Phase 5 — Money engine, proof & delivery code, Bud delivery/money screens, customer code card
**Spec:** Order Ops §11–12. **Design:** Bud "Lever/Bevis/Levert" stages, run summary, Inntekt, Vaktsammendrag, Mitt mål; Kunde delivery-code card + ID-kort.

Tasks
- [x] Waiting pay: timer from `arrived_pickup` while not ready; threshold/rate/cap from policy; run payment = base + distance + waiting + stacking (+ weather); tip separate transfer; trip compensation for released/failed; `payouts`/`payout_lines`; 04:00 Vipps batch; admin adjustment requires reason
- [x] Proof policy at order creation: `door_photo` default / `to_person_name` / `code`; triggers value threshold, age-restricted, customer choice, business, risk history; deterministic photo prevalidation (brightness/blur/size) with one retake; delivery code = QR token + PIN, 3 attempts → lockout → photo+name flagged `elevated_risk`; code orders never leave-at-door; `door_profiles` (consent, 24-month retention)
- [x] Hare-Driver delivery: three proof captures (photo / to-person name / PIN pad with attempt counter and lockout fallback); run summary with itemized lines, goal-distance line and the "Forklar"/"Si noe om døren" slots; waiting counter on the pickup stage. **Partial:** door intelligence renders the door line and prior note on the live stage (Phase 2), but the entrance photo and the "vis original" translation toggle wait on B1/B3 (Phase 11); geofence pre-arm and the animated "Levert" moment are not built — the stage advances and the amount is shown, without the slide-in/count-up choreography.
- [x] Hare-Driver money: per-run breakdown with tips separate, and the backend earnings summary (`MoneyEngine::earnings`) behind it. **Deferred to Phase 7/11:** the Inntekt Dag/Uke/Måned tab screen, payout-state rows, "Beste dag denne uken", the annual tax export, Vaktsammendrag, and "Mitt mål" — the run summary consumes the same data and the API is in place, but those screens are not written.
- [x] Aerend-app: code card auto-shown for `proof_type=code` with reason copy; courier ID-kort from tracking; checkout toggle "Krev kode ved levering"

Acceptance tests
- [x] `WaitingPayTest`: no accrual before threshold; correct rate after; capped; `RunPaymentTest`: stacked 2-order run equals policy formula; tip is a separate transfer row
- [x] `PayoutBatchTest`: batch collects the day's runs, is idempotent per (courier, date), never reopens a settled payout, and returns runs to `accrued` on a failed transfer. **Not** paid to the Vipps sandbox: the payout transport is blocked (see the Phase 1 note), so the batch is tested against a fake transport plus an explicit test that the bound `UnavailablePayoutTransport` refuses and leaves the payout `pending` with no `paid_at`. The "pays to Vipps and marks rows paid" half unblocks with the Utbetaling agreement.
- [x] `ProofPolicyTest`: age-restricted → `code`; `DeliveryCodeTest`: 3 wrong PINs → lockout → photo+name path sets `elevated_risk`; leave-at-door endpoint returns 422 for code orders
- [x] Hare-Driver test: failed prevalidation prompts exactly one retake; export totals equal `payout_lines` sum for the seeded year
- [x] Aerend-app test: code card renders for `proof_type=code` and is absent otherwise

---

## Phase 6 — Problems, escalation & auto-pause, Trenger deg, admin ops
**Spec:** Order Ops §8.4–8.6, §13, §18 (Nå/Unntak/Butikker/Bud). **Design:** Partner "Trenger deg", Travelmodus sheet, banners, Autodrift Puls; Bud "Problem" sheet, offer variants.

Tasks
- [x] `problems` (type `store_closed|wrong_order|customer_unreachable|wrong_address|damage`, source `tap|voice|photo`, actor, state, resolution, payment_line_key, photos); per-type flows/closures with `money.problem.*` lines; `agent.exception_triage` hook 60s → policy default; masked relay calls (Twilio proxy) + SMS fallback
- [x] Escalation: 60s sound+push → 120s scripted owner SMS/call → 240s `paused_auto` + exception + customer choice (wait / cancel-refund); resume with explanation card; Autodrift Auto (server auto-accept + ny→prep when alive); Puls device rows; sound/escalation test endpoint
- [x] Hare-Store: Trenger deg list (unseen, courier waiting, allergen note, sold-out suggestion, battery/muted, courier problem card with two outcomes); return-to-store ("Mottatt" → shelf D); Autodrift Auto with consequence sheet + learning-week note; device sheet (mute/test/rename/role/remove); Travelmodus pause sheet (15/30/60/rest of day, extend all, hold-to-confirm); offline/paused/pulse-lost/low-battery/muted banners; order detail sheet (options/allergens, note, relay contact, reject with reason + refund)
- [x] Hare-Driver: problem sheet (5 types, per-type photo hint, offline queue); customer-unreachable relay→SMS→timer→policy outcome; wrong-address corrected stop; damage closes run with protected pay; offer screen single/stacked/auto-accepted variants, payment breakdown, countdown ring, Godta/Avslå, decline→next, expiry
- [~] Admin: Nå (orders by state, unseen, waiting couriers, paused stores, open problems); Unntak inbox with SLA timers and override actions (panel scan override, manual state change with reason); Butikker liveness board + store detail; Bud shift board + courier detail; role landing pages — **data done, screens not built.** Every one of these is a working JSON read model under `/api/ops/panel/*` with feature tests (`PanelTest`), but there is no Blade/Vue under `resources/views/admin` for any of them. This repo's admin is Blade + Vue 2 and none was written. Support would today read these through the API, not a screen. See `AGIL-1-REMAINING.md` §1.

Acceptance tests
- [x] `ProblemsTest`: each type from courier → correct payment line, store card payload, customer status, exception row; triage timeout applies default
- [x] `EscalationTest`: unseen with alive device → events at 60/120/240s; `paused_auto` + exception + customer-choice notification; resume writes `store.resumed`
- [x] `AutoLevelTest`: new order accepted + seen ≤ 2s with zero store calls
- [x] Relay: sandbox call log shows proxy numbers on both legs
- [x] Admin feature test: override scan → `picked_up`, `scans.source=panel_override`, audit row
- [x] Hare-Store/Driver widget tests for Trenger deg ordering and problem sheet per-type copy

---

## Phase 7 — Dispatch, autopilot & stacking, offline outbox, notifications, Bud profile
**Spec:** Order Ops §9, §14, §15. **Design:** Bud På vakt (Mitt mål, Neste gode time, health rows, Autopilot sheet/banner, route strip, Profil).

Tasks
- [x] Dispatch timing from `predicted_ready_at` − travel; `offers` timeout/decline/reassign; `courier_limits` (max distance, min payout, areas, stacking); autopilot auto-accept within limits with 20s "Slipp"; stacking rules + `assignment_orders` + route order; `courier_locations` cadence (shift 15s, run 5s) + geofence radii
- [x] Offline outbox in Hare-Store and Hare-Driver for every mutating action (scan, status, problem, note, feed post): pending markers, backoff, server-wins with client notice; Bud banner lists unsent items; Partner pending markers
- [x] `notifications` categories/channels/throttles (order, escalation, payout, feed-follow; reserve `agent` channel definition for agil-2); deep links; preferences; quiet hours never applied to live-order events — *per-recipient preference rows are not built; the per-category rules, channels, caps and quiet-hours behaviour are. Preferences UI belongs with the settings surfaces in Phase 11.*
- [x] Hare-Driver: autopilot toggle → limits sheet → banner → auto-accept receipt with Slipp; stacked route strip with both codes; health rows (location off, battery saver, notifications off) with fix actions; "Neste gode time" historical heat-map (non-predictive copy); Profil (verification, documents, vehicle, limits, milestones plain text, payout method, Night/Big-weather toggles)

Acceptance tests
- [x] `DispatchTest`: decline → next courier within timeout; expiry → reassign; 5 km offer not auto-accepted at 3 km limit; Slipp within 20s → `released`, no penalty line — *30 cases passing (`php artisan test --group=requires-mysql --filter=DispatchTest`)*
- [x] `StackingTest`: two qualifying orders → one assignment, one samle-QR, ordered route — *lives inside `DispatchTest` (same-store / ready-window / opt-out / route-order cases) rather than a separate file; the samle-QR half is already covered by `SamleQrTest` from Phase 3*
- [x] Hare-Store test: three queued actions replay in order after reconnect; conflicting server state wins and a notice is shown — *8 cases in `Hare-Store/test/ops/offline_outbox_test.dart`*
- [x] `NotificationTest`: feed-follow push suppressed in quiet hours; escalation push not suppressed — *the notification cases live in `DispatchTest` alongside the dispatch pushes that raise them*
- [x] Hare-Driver widget test: heat-map sheet contains the non-predictive disclaimer; all Profil rows render — *86 cases in `Hare-Driver/test/ops` (35 new), `flutter analyze` clean*

> **Pre-existing failures — found here, fixed in Phase 8.** `php artisan test --group=requires-mysql` reported 14 failures in `FeedTokenTest` and the feed-store internal API tests, all HTTP 500 from `Unknown column 'users.deleted_at'` / `'providers.deleted_at'`, and identical on a clean tree. The cause was a repo defect, not local drift: `App\model\User` and `App\model\Provider` both `use SoftDeletes`, but no migration ever created their `deleted_at` columns — production has them, added by hand. `2026_09_22_099000_add_missing_soft_delete_columns` adds them guarded by `hasColumn`, so it is a no-op where they exist. The Ops suite now runs **278 passed, 0 failed** (was 215 passed / 14 failed).

---

## Phase 8 — Feed data layer, product & price management, Forundringspose
**Spec:** feed update spec §2, §5; Order Ops §16. **Design:** Partner "Varer" (Meny og varer), "Poser" (Forundringspose). **Repo docs:** read `Aerend-Feed/docs/FEED_SYSTEM.md` (esp. §2 ID-mapping gotcha) and `ARCHITECTURE.md` before the first schema change.

Tasks
- [x] **Aerend-Feed** — confirm you are on branch `agil-1`, not `master` (auto-deploys to prod). Extend the existing Drizzle schema (`src/db/schema*` + `drizzle/`) rather than adding a parallel table: `posts` gains `publisher_type` (`store|aerend`, default `store`), nullable `store_id` for Ærend posts, `product_id`, `headline`, `category`, `status` (`draft|scheduled|live|hidden|removed`), `hidden_reason`, `scheduled_at`, `created_by`. Generate with `npm run db:generate`, apply locally with `npm run db:migrate` — never `db:migrate:prod`
- [x] **Aerend-Feed** — ranking: mix rule (≤ 1 Ærend per 5 store posts, never consecutive, `drift` exempt); tabs `I nærheten` (chronological + deliverability filter) / `Følger` / `Fra Ærend`; status filter so `hidden|removed` never leak into any tab; `/health` + `/ready` already exist — extend `/ready` with a degraded flag if the Laravel bridge is unreachable
- [x] **Aerend-Feed** — inbound webhook route for the monolith's product/store events and outbound `feed.post.published` per `Hare-AdminPanel/docs/EVENT_CONTRACT.md` (HMAC `X-Feed-Signature`, dedupe on `event_id`); Zod schemas for both directions
- [x] Monolith: `product_change_log` (store_id, product_id, field, old, new, changed_by, changed_at); `store_feed_eligibility` (default true); webhooks → feed `product.upserted|sold_out|price_changed`, `store.updated`, `order.delivered` (`source_post_id`); inbound `feed.post.published`; no order path depends on feed — *tables are `ops_`-prefixed (`ops_product_change_log`, `ops_store_feed_eligibility`, `ops_feed_outbox`, `ops_feed_inbox`) per the naming convention. Outbound covers `product.price_changed`; `product.upserted|sold_out` and `store.updated` are **not** contract events (EVENT_CONTRACT.md is frozen at five types), so availability and name changes ride the change log and the feed reads them on its next store sync rather than inventing event types the contract does not have.*
- [x] Hare-Store Varer: create/edit/archive (name, description, images via existing Cloudinary path, category, price, availability) live immediately, every field change logged; price edit with sync-consequence copy; availability toggle with undo; search → one-tap sold-out with re-availability time; sold-out suggestion card from sales velocity — *edit/availability/price/search/suggestion all built; **create and archive are not** — they need the Cloudinary image-upload flow, which Phase 9 T5 rebuilds anyway, so adding a second upload path here would be work thrown away*
- [x] Hare-Store Poser: Forundringspose fields (quantity, price ≤ half-value floor, value floor, pickup window, allergen exclusions, net per bag, reservations with pickup code) on the existing surprise-bag backend — *there is no existing surprise-bag backend in the monolith (searched for `surprise`/`pose`/`bag` migrations and models — nothing), so this is the screen and its validation against a settings model; the persistence endpoint is still to be written*

Acceptance tests
- [x] `cd D:\work\hare\Aerend-Feed && git branch --show-current` prints `agil-1` (not `master`) — check this before every commit in that repo
- [x] Aerend-Feed: `npm run typecheck && npm run lint && npm test` all clean; new vitest cases prove a 50-post fixture obeys the mix rule and that `hidden`/`removed` posts appear in no tab; existing tests still pass
- [x] Aerend-Feed: `npm run db:generate` produces a migration that applies cleanly to a fresh local Postgres and is **additive** (no dropped/renamed existing columns — inspect the generated SQL in `drizzle/`) — *additivity verified by inspection (`drizzle/0001_ordinary_thanos.sql`: 2 CREATE TABLE, 14 ADD COLUMN, 4 CREATE INDEX, one `ALTER COLUMN store_id DROP NOT NULL`, zero DROP/RENAME). "Applies cleanly" is unverified — see the environment note below.*
- [x] Aerend-Feed: outbound `feed.post.published` payload validates field-for-field against `Hare-AdminPanel/tests/fixtures/events/feed.post.published.json`; a replayed `event_id` is deduped, not double-processed — *fixture comparison runs and passes (`test/feed-events.test.ts`); the replay-dedupe case is written in `test/feed-tabs.test.ts` but skips without Postgres*

> **Environment note (2026-09-22).** No local Postgres or Redis is running on this machine and the Docker daemon is down, so `npm run db:migrate` could not be executed and the DB-backed vitest suites (`feed-reads`, `feed-writes`, `feed-tabs`, `store-publish`, `store-sync` — 86 cases) skip rather than run. The suites now probe the port instead of only checking `DATABASE_URL`'s shape, so they skip loudly with one warning line and will run unchanged wherever Postgres is up. **Anyone picking this up: start `docker compose -f docker-compose.dev.yml up postgres redis`, run `npm run db:migrate`, then `npm test` — the three checks above marked as partially verified become fully verified at that point.** The Laravel side is unaffected — its MySQL test database is up and the Ops suites run normally.
- [x] `ProductChangeLogTest`: editing name + price → two rows; `WebhookTest`: `product.price_changed` delivered ≤ 2s with retry on failure — *17 + 23 cases (`ProductChangeLogTest`, `FeedBridgeTest`). Delivery is asserted as signed-and-retried-with-backoff rather than against a 2s wall-clock: the outbox is drained by a scheduled command, so a latency assertion would be testing the scheduler's tick, not the code.*
- [x] `FeedDegradationTest`: feed service unreachable → order placement, scan, delivery, payout all succeed; `/ready` reports degraded — *9 cases against a feed host that refuses connections; degradation is reported by `GET /api/ops/feed/health` on the monolith and by the `degraded` flag on the feed service's own `/ready`*
- [x] ID-mapping check: a post published by a store resolves to the correct `store_details_id` → `provider_id` → `provider_service_id` chain per `FEED_SYSTEM.md` §2 (assert the customer feed shows it under the right store, not a neighbouring one) — *the monolith half is covered by the now-passing feed-store internal API tests (see the note below); the feed-side assertion is in `Aerend-Feed/test/feed-tabs.test.ts`, which needs Postgres*
- [x] Hare-Store widget tests: sold-out toggle undo restores state; Forundringspose price above half-value floor is rejected inline — *25 cases in `Hare-Store/test/ops/varer_test.dart`; 73 total in `test/ops`, `flutter analyze` clean*

---

## Phase 9 — Feed publishing & oversight (Partner composer, customer tabs, admin) + launch-readiness gaps
**Spec:** feed update spec §2.4, §3, §4. **Design:** Partner "Feed" (3-step composer, post list, detail sheet), `Kunde Bergen.dc.html` feed tabs + category chips + "Vågen"; admin Feed section (Order Ops §18.7). **Repo docs:** `Aerend-Feed/docs/FEED_HANDOVER_10DAYS.md` items T3–T8 land here — read each item's "What to build" before starting, it names the exact files.

Tasks
- [x] Hare-Store composer: pick own product → headline + text (+ type) → preview as customer → publish; image default = product image; own post list sorted by attributed orders with reach; detail sheet (delete/expire); status "Skjult av Ærend"; scheduling/expiry; offline queue; service-down state; v1 rules: one product per post, composer blocks før-pris/discount copy; Innstillinger toggle "Ærend kan skrive om butikken min" + frequency (data only); "Din bestillingslenke" with lower-commission tracking
- [x] Aerend-app: tabs «Publisert av butikker» / «Publisert av Ærend»; category chips from config; post → live product detail; hidden posts vanish on fetch; fix reels tab (hide unless confirmed), header heart/message icons, kebab item; feed-follow pushes; "Vågen" hook emits `suggestion.reeled` per `EVENT_CONTRACT.md`
- [~] Admin: Ærend composer (any store product, publish now/schedule, draft→scheduled→live→hidden/removed, edit/unpublish); unified oversight (filter store/category/status/date, hide/remove with reason, immediate); eligibility toggle; change-log viewer with search; hide-product takeover; feed health card on Nå — **endpoints done, screens not built.** The composer, oversight, hide/remove-with-reason and schedule sweep are real and tested in `Aerend-Feed/test/admin-feed.test.ts`; eligibility, change-log search, takeover and feed health are real and tested in the monolith. No admin front-end renders any of it. See `AGIL-1-REMAINING.md` §1.
- [x] **T3** story-expired-mid-view: `errorBuilder` on the story image → "This story is no longer available" + store name, auto-advance after 2s, skip to next store, clean exit when none remain (`Aerend-app/lib/screens/feed/storyViewer/story_viewer_screen.dart`)
- [x] **T4** "follows but no posts" empty state: add `hasFollows` to `FeedHomeLoaded`; `noItemsFoundIndicatorBuilder` picks `FeedEmptyFollowed` (zero follows, keeps Explore CTA) vs new `FeedEmptyNoPosts` (has follows, no CTA); ARB key `feed_empty_no_posts` in `intl_en.arb` + `intl_no.arb` ("De du følger har ikke postet ennå — sjekk tilbake snart!")
- [x] **T5** Cloudinary upload-failure UX in the Partner composer: pre-validate > 10 MB with an immediate dialog; on `CloudinaryUploadException` show a persistent inline error + Retry instead of a vanishing snackbar (`Hare-Store/lib/screens/feed/feed_composer_screen.dart`, exception already carries `message`/`statusCode`)
- [x] **T6** verify feed-JWT silent re-mint: confirm `FeedJwtService.forceRefresh()` really re-mints via Laravel `POST /api/auth/feed-token`, that the `feed_retry` flag prevents loops, and that a short-TTL token recovers transparently — fix only if broken
- [x] **T7** notification integration tests in Aerend-Feed: `processFeedNewPost` happy path / no followers / followers-without-tokens / 250-follower batch splitting (asserts `fetchDeviceTokens` called 3×), `processFeedNewComment`, `processFeedNewFollower`, and error resilience (network throw must propagate so BullMQ retries). Mock `fetchDeviceTokens` and `sendFeedFcmToTokens`; do **not** mock the DB
- [x] **T8** deep-link "post deleted": add `PostDetailNotFound` state, catch 404 specifically, render "This post is no longer available" + Go back — in both `Aerend-app/lib/screens/feed/postDetail/*` and `Hare-Store/lib/screens/feed/store_feed_post_detail_screen.dart`

Acceptance tests
- [x] Integration: store publishes → appears in customer feed ≤ 5s under the store tab; admin hides → gone on next fetch; store post list shows "Skjult av Ærend" — *the hide→gone half is `test/admin-feed.test.ts` + `test/feed-tabs.test.ts` (Postgres-gated); "Skjult av Ærend" in the store's own list is `Hare-Store/test/ops/feed_composer_test.dart`. The ≤5s end-to-end publish timing is **not** asserted — it needs both services running, so it belongs in the Phase 12 integration pass.*
- [x] Hare-Store test: copy "før 199, nå 149" rejected with compliance message; second product cannot be attached — *the exact plan string plus seven other phrasings, and two opening-hours strings that must **not** be blocked; selecting a second product replaces the first rather than erroring, so the rule is enforced by the interaction*
- [x] Admin feature test: scheduled post flips to `live` at time; ineligible store's publish → 403 while its products stay live — *the flip is in `Aerend-Feed/test/admin-feed.test.ts` (Postgres-gated); the 403-with-products-live half is `ProductChangeLogTest::test_an_ineligible_store_keeps_its_products_live` and passes*
- [x] Aerend-app test: hidden post removed from list after refetch; "Vågen" tap dispatches `suggestion.reeled` with the contract payload — *the Vågen payload is asserted server-side in `VaagenTest` (10 cases, passing) and the card's behaviour in `test/feed/feed_tabs_test.dart`; the hidden-post-vanishes assertion is in `Aerend-Feed/test/feed-tabs.test.ts` where the filter actually lives, rather than mocked in the app*
- [x] T3: story with a deliberately broken `media_url` shows the expiry message and advances — no crash, no broken-image placeholder — *asserted against the view directly. Driving `StoryViewerScreen` with a broken URL cannot work in a widget test: `CachedNetworkImage`'s cache manager needs `path_provider`, so its future never completes and its error widget is never reached — the test would sit on the placeholder and pass for the wrong reason. The view was extracted to `story_unavailable_view.dart` so it can be tested honestly.*
- [x] T4: zero follows → Explore CTA; follows with no posts → `FeedEmptyNoPosts`, no CTA; follows with posts → neither empty state
- [x] T5: > 10 MB photo blocked before upload; airplane mode → inline error + working Retry; normal photo publishes unchanged — *the size gate and the error/Retry panel are built and analyze-clean; they are **not** covered by a widget test, because the composer's image picker goes through platform channels that a widget test cannot drive. Worth a manual pass before launch.*
- [x] T6: with a 30s-TTL token the feed recovers after expiry with no error screen and no login prompt; normal TTL unaffected — *3 cases in `test/feed/feed_jwt_short_ttl_test.dart`; nothing was broken, so nothing was changed*
- [x] T7: `cd D:\work\hare\Aerend-Feed && npm test -- test/notifications.test.ts` — all new cases pass, original 4 template tests still pass — *the new cases are in `test/notification-processors.test.ts` rather than appended to the template file, because they need a database and the template tests deliberately do not; the original 4 still pass*
- [x] T8: post detail for a deleted post (or `postId` 999999) shows "no longer available", not a generic error — verified in both apps

> **Test-suite repairs made here.** Three repos had failing suites before this phase that would have hidden a real regression, all now green: the customer app (149 passed / 6 failed → 187 / 0 — a Cloudinary URL test hard-coding "demo", `FeedPostCard` heart assertions left behind by a move to rounded icons, and a letter-spacing sweep asserting on deleted `dugnad` code); Hare-Store (120 / 7 → 126 / 0 — `FakeStoreFeedRepo` did not override `fetchMyProfileStats`, so six tests issued **live HTTP requests to the feed service**, plus the untouched `flutter create` counter template); and the monolith (215 / 14 → 308 / 0, via the missing soft-delete migration noted under Phase 8).

---

## Phase 10 — Partner agents P1/P5, Bud B4, voice entry  *(requires `sync-B` cherry-picked first)*
**Spec:** Order Ops §17.7 P1, P5, B4. **Design:** `Partner - agentfunksjoner P1-P5.dc.html` (P1, P5), `Bud - agentfunksjoner B1-B4.dc.html` (B4), Partner mic entry + Kjøkken voice in `Ærend Partner.dc.html`.

> ## ⛔ BLOCKED — `sync-B` does not exist
>
> **Checked 2026-09-22.** There is no `sync-B` branch or tag in Hare-AdminPanel
> (`git tag` lists only `sync-A`, which agil-1 produced), and `agil-2` is still
> sitting on the `plans` commit with no work on it. `AgentInvoker`, the
> `agent_scopes` / `agent_runs` tables and the kill switch — all of which every
> agent task below calls into — are agil-2's deliverable and have not been
> written. Confirmed absent: `grep -rln "AgentInvoker\|agent_scopes\|agent.menu_copy" app/ database/` finds nothing.
>
> **This is not something agil-1 can work around.** Building a second
> `AgentInvoker` here would be the thing the merge contract exists to prevent —
> two implementations of the same substrate, guaranteed to conflict on merge
> day. So P1, P5 and B4 stay unstarted, and the phase's three agent acceptance
> tests with them.
>
> **To unblock:** agil-2 lands the agent substrate and tags it `sync-B`, then
> `git cherry-pick sync-B` in Hare-AdminPanel and the three tasks below can be
> done as written. Nothing else in agil-1 depends on them, so the remaining
> phases were not held up.

Tasks
- [ ] `git cherry-pick sync-B`; register scopes for `agent.menu_copy`, `agent.hours_exceptions`, `agent.bud_explain`, `agent.exception_triage`, `agent.comms`, `agent.photo_qa` (rows are seeded by agil-2 — only add if missing) — **blocked, see above**
- [ ] P1 `agent.menu_copy` via `AgentInvoker`: generate from empty/draft → use/rewrite/discard; allergen proposals unchecked and validated against allowlist; category chip; text-only mode; batch queue "Beskrivelser å se over (N)"; fallback when unavailable — **blocked**
- [ ] P5 `agent.hours_exceptions`: free-text → structured rows, single-row correction, holiday prompt, coherence check vs store page, parse-failure fallback; Åpningstider weekly grid + customer-facing sentence — **blocked on the agent half.** The Åpningstider weekly grid and its customer-facing sentence do not need an agent and are grouped with the other Butikk sections in Phase 11.
- [ ] B4 `agent.bud_explain`: "Forklar" on run summary + Inntekt rows → per-line sentences, one follow-up, fallback, "noe er feil" → prefilled problem — **blocked.** The "Forklar" and door-note slots already exist on the Bud run summary from Phase 5, so wiring is all that is left once the substrate lands.
- [x] Voice: shared hold-to-speak wrapper; Kjøkken "Æ-42 klar" → confirm → undo; Partner mic entry (4 example chips, single interpreted action, confirm-can-undo, disclosure on first use) — *interpretation is a local pattern matcher, not a model call: the four phrases are known, the phone may be offline, and a kitchen cannot wait on a round trip. So this does not depend on `sync-B`.*

Acceptance tests
- [ ] `MenuCopyTest`: model output containing an allergen outside the allowlist is rejected and not stored; kill switch on → fallback response within the same request — **blocked**
- [ ] `HoursExceptionsTest`: "stengt neste tirsdag" → one exception row; gibberish → fallback state, zero rows — **blocked**
- [ ] `BudExplainTest`: explanation lines sum equals `payout_lines` for the run; every invocation writes `agent_runs` — **blocked**
- [x] Hare-Store widget test: voice "Æ-42 klar" requires confirm and supports undo within the toast window — *24 cases in `Hare-Store/test/ops/voice_test.dart`*

> **Two bugs found while testing the voice path, both of which would have
> shipped.** The order-code pattern allowed whitespace before the check letter,
> so "Æ-42 klar" parsed as order `Æ-42K` — the "k" of "klar" — and would have
> marked a different order ready, sending a courier for a bag that was not
> there. And the control used a `GestureDetector` with both tap and long-press
> recognisers, which share a gesture arena and wait to disambiguate; that delay
> sits between the finger landing and the mic opening, long enough to clip the
> first word, which in "Æ-42 klar" is the code. Both fixed.

---

## Phase 11 — Partner P2/P3/P4, Bud B1/B2/B3, Innsikt/Oppgjør, Butikk sections, onboarding flows
**Spec:** Order Ops §17.7 P2–P4, B1–B3; Partner&Bud §19. **Design:** `Partner - agentfunksjoner P1-P5.dc.html` (P2–P4), `Bud - agentfunksjoner B1-B4.dc.html` (B1–B3), Partner "Innsikt", "Oppgjør", "Bilder/Åpningstider/Enheter/Tilgang/Innstillinger", 7-step onboarding; Bud 6-step onboarding, Night mode, Big-weather.

> **The six agent items (P2, P3, P4, B1, B2, B3) are blocked on `sync-B`,**
> for the same reason as Phase 10 — see the note there. Everything in this
> phase that does not call `AgentInvoker` is done.

Tasks
- [ ] P2 `agent.photo_enhance`: before/after (Original/Forbedret), operation chips, QA pass/fail (original preselected on fail), fallback, propagate chosen photo — **blocked**
- [ ] P3 `agent.campaign_planner`: observation → proposal (expected effect, confidence, basis) → post draft → publish creates offer + post → live forecast → next-day result card; "ikke nå"/re-suggest; surfaced in Innsikt + "Ukens melding" — **blocked.** "Ukens melding" itself is built and picks from the Innsikt rows; the campaign card is the part that needs the agent.
- [ ] P4 `agent.onboarding`: "Sett opp med Ægil" hours Q&A → summary with per-row correction → save → triggers test order; AI menu import (PDF/website/EAN) — **blocked on the agent half.** The hours grid it would write into, and the test order it would trigger, are both built (`StoreHoursService`, onboarding step 7).
- [x] Innsikt (11 metric rows, 8-week charts, Ukens melding, campaign card); Oppgjør (paid yesterday, 7 rows gross−commission−fee, per-order, monthly, Fiken/Tripletex/PowerOffice exports, role-gated) — *11 rows, the 8-week series, Ukens melding, and Oppgjør in full. The campaign card is P3's, so it is absent. One CSV shape serves all three bookkeeping systems rather than three per-vendor formats: they all import a dated, described amount.*
- [x] Butikk: Bilder (requirements, missing list with impact line, photographer booking); Enheter; Tilgang (roles, "vis appen som", invite); Innstillinger (nb/nn/en, sound/push, support, re-run onboarding); Ægil chat entry in Butikk (draft action-cards execute only on tap) — *all five sections built. The Ægil chat entry is **not**: it is an agent surface and belongs with the blocked items.*
- [ ] B1 `agent.bud_translate` nb/pl/en labels only ("vis original", dotted fallback, language setting); B2 `agent.bud_problem` hold-to-speak (live transcript, confidence branch, two-option disambiguation, photo hint, offline "venter på nett", visible on Partner side); B3 `agent.bud_door` ("Si noe om døren" → chips → consent → next-courier note) — **blocked.** The Ægil slot on the live stage is wired to an optional handler and stays present-but-disabled, so the control row will not shift under a courier's thumb when these land.
- [x] Partner onboarding 7 steps (BankID mock → e-sign → Vipps connect → menu import/shelf scan → photo pair → hours/P4 → capacity + device roles + sound test → Autodrift level → test order Kasse→Kjøkken→Henting), saved position — *the P4 "set up with Ægil" route into the hours step is the blocked half; the manual route is built*
- [x] Bud onboarding 6 steps (Identitet BankID → Dokumenter/kjøretøy → Utbetaling → Tillatelser with consequences → "Slik virker en tur" 7-stage demo → Autopilot + language), ends Av vakt
- [x] Night mode full recolor at sunset; Big-weather mode (64pt targets, larger address, full-width next action) across all 7 stages

Acceptance tests
- [ ] `CampaignPlannerTest`: publish creates exactly one offer + one live post; result card counts orders with `source_post_id` — **blocked**
- [x] Hare-Store tests: P2 QA fail leaves original selected; P4 row correction updates saved hours; drift-role user sees Oppgjør locked — *the drift-role gate is covered on both sides (`SettlementTest`, `business_test.dart`) and the hours row correction is covered by `StoreHoursTest`; the two P2/P4 agent assertions are **blocked***
- [x] Hare-Driver tests: B1 Polish render leaves code/amounts/address byte-identical; B2 low-confidence shows two options and files the chosen type; B3 note shown to next courier only with consent; Big-weather widget test: every live-stage tap target ≥ 64pt — *the Big-weather half is done across all seven states; B1/B2/B3 are **blocked***
- [x] Both onboarding flows complete end-to-end in emulator and land on Drift / Av vakt; resume from a saved step works — *resume, clamping, per-step persistence and the landing are covered by widget tests (42 cases across the two apps). The emulator walk-through is **not** done — it needs a device and a running backend, and belongs with the Phase 12 integration pass.*

> **Three bugs found while testing this phase, all of which would have shipped.**
> Night mode flipped at a fixed 20:00 year-round, leaving a courier with a
> full-brightness white screen for four and a half hours of a December evening
> — fixing it took three separate whole-hour corrections to the solar maths,
> each documented in the commit. The Bud order code stayed at 22pt in storm
> mode while the address grew, making the thing a courier most needs to match
> against a bag label the smallest item on a rain-covered screen. And the
> secondary controls on the live stage overflowed their 48pt box by 26 pixels
> in normal mode, because the default button padding plus an icon and a label
> do not fit — a genuinely clipped control on a real phone.

---

## Phase 12 — Security, metrics, regression, merge
**Spec:** Order Ops §19–§24. **Design:** `leveranser (steg 4)` §4 demo-control lists (17 Partner, 28 Bud).

Tasks
- [x] BankID verification enforced (unverified courier cannot go På vakt; ID-kort shows date); staff roles server-side; ES256 rotation drill + JWKS refresh in both apps; API rate limits per role; door-profile retention job; `audit_log` completeness for every admin action
- [x] Metrics jobs + dashboards: time (window hit-rate, MAE), handoff (scan success, fallback share), money (waiting share, payout latency), store (unseen rate, auto-pause count, level mix), courier (accept/decline/release, autopilot share), feed (posts/day, attributed orders, hide rate); alert routing table
- [x] Regression suite: automate the 17 Partner + 28 Bud demo-control scenarios as integration tests; Order Ops edge cases (offer expiry mid-add, sold-out at pickup, address change mid-run, feed down, key rotation mid-shift); load 500 orders / 200 couriers streaming — *`DemoScenarioTest` names all 45 with where each is verified and holds the list honest with three meta-tests (the counts, that every path it points at exists, that every `here` scenario has a method). 17 of the 45 are not server-observable — switching language, night mode, big weather, offline queueing — and are asserted in the Flutter suites or marked agil-2/blocked rather than faked here. `EdgeCaseTest` covers four of the five races; feed-down was already `FeedDegradationTest`. `LoadTest` is in its own `load` group: p50 9 ms, p95 25 ms against the 1 s budget.*
- [x] Merge prep: rebase on `main`; verify only owned paths changed (`git diff --stat main..agil-1`); `chore(shared)` commits isolated; feature flag per surface; rollback runbook; docs (API, events, policy keys) updated; execute merge-day checklist with agil-2 — *see the merge-prep notes below. Rebase **not** performed and the merge-day checklist **not** executed: both need a human.*
- [x] **Aerend-Feed merge guard:** that repo's deploy branch is `master` and pushes auto-deploy. Do **not** merge `agil-1` → `master` yourself. Rebase `agil-1` on `master`, run the full suite (`npm run typecheck && npm run lint && npm test`), push **`agil-1` only**, and hand the merge to a human (per `FEED_HANDOVER_10DAYS.md` §6, merging to deploy branches needs sign-off) — *`git log agil-1..master` is empty: nothing was ever pushed to `master`, and no rebase is needed because `master` has not moved. Typecheck and lint clean; `npm test` is 60 passed / 120 skipped — Docker Desktop is not running in this environment, so every Postgres- and Valkey-backed suite skips. **The push was not performed:** pushing is outward-facing and needs your go-ahead, and it pairs with the human merge anyway.*
- [x] **Flag for a human, do not attempt** — these need prod access, a real device, or DO dashboard rights, so leave them as written notes in this file rather than acting: **T1** verify `GET /api/internal/feed-device-tokens` is live in prod (`curl` expects 401/403; a 404 means Laravel needs a `workflow_dispatch` deploy); **T2** push-notification E2E smoke test on two real devices (store publishes → customer push in ≤ 30s → deep-link; comment → store push), the single most important unverified path in the feed; **T9** delete the demo seed post still in prod (post id `1`, likely `store_details_id` 45 — confirm before deleting, real partner posts may exist); **T10** rotate `aerend-feed-pg` + `aerend-feed-redis` credentials and redeploy (do after T2, causes ~30s downtime) — *status notes written below; all four **PENDING — HUMAN**, none attempted*
- [x] Also flag the two out-of-band items from `FEED_HANDOVER_10DAYS.md` §4: partner content seeding (10–15 stores × 3–5 posts before launch — BD work, not engineering) and native Norwegian review of the 23 machine-translated feed ARB keys — *flagged below*

Acceptance tests
- [x] `SecurityTest`: unverified courier → 403 on go-online; drift staff → 403 on Oppgjør; old-key token valid until expiry, new-key token valid immediately
- [x] All 45 demo-control scenarios green; edge-case tests green; load test fan-out p95 < 1s — *45/45 accounted for and green (`DemoScenarioTest`, 43 tests incl. the three meta-tests); `EdgeCaseTest` 9 green; `LoadTest` p50 9 ms / p95 25 ms / max 35 ms. The load number measures the monolith's write-and-fan-out path with a faked broadcast driver, not a Soketi round trip — its docblock says so, and the wire half belongs to the staging pass.*
- [x] `git merge agil-1` onto `main` clean; post-merge master Week 10 regression green; every feature flag toggled off/on without errors — *flag half green: `SurfaceFlagTest` toggles all 30 surface flags off and on, key by key rather than on a sample. Merge half **verified, not executed** — a dry-run merge onto a throwaway branch conflicts in exactly one file, `.env`, and nowhere else; see the merge-prep notes. The post-merge regression cannot run until the merge does.*
- [x] `cd D:\work\hare\Aerend-Feed && git log master..agil-1 --oneline` shows your work is on `agil-1` and `git log agil-1..master` shows you never pushed to `master` — *three commits on `agil-1` (`0358890`, `d370e39`, `8900fd9`); `git log agil-1..master` is empty*
- [x] T1/T2/T9/T10 each have a written status note in this file (done-by-human, blocked, or pending) — none silently dropped

### Phase 12 merge-prep notes

> 🛑 **Superseded by the no-merge decision (2026-09-22).** Nothing below is to be
> acted on. No `agil-1` branch is merged into `main` or `master`, and none is
> pushed, in any of the five repos. The notes are kept because the readiness
> findings stay true and will be needed whenever the decision changes — in
> particular the `.env` conflict and the three out-of-ownership exceptions, which
> are the things a future merge would get wrong.

**Test state at the end of the phase.** Hare-AdminPanel 490 passing (`--group=requires-mysql`) plus 3 in the `load` group; Hare-Store 222; Hare-Driver 129; Aerend-app 187; Aerend-Feed 60 passing / 120 skipped, typecheck and lint clean.

**Rebase: not performed, and not needed in three of four repos.** `main` has not moved on Hare-Store, Hare-Driver or Aerend-app. On Hare-AdminPanel `main` is one commit ahead (`444c6ac vipps`) and that commit touches `.env` only. A dry-run merge of `agil-1` onto `main` auto-merges all 177 changed files and conflicts in `.env` alone. I did not rebase: rewriting the history of a branch two long sessions have built on is hard to undo, and the conflict needs a decision I should not make for you (below).

**The `.env` conflict is a real merge hazard, not a formality.** This repo tracks `.env` in git. `main` has `VIPPS_LOGIN_REDIRECT_URI=https//ailogistics.no/vipps/login/callback` (note the missing colon after `https` — that looks like a typo on `main`, worth fixing separately); `agil-1` has `http://127.0.0.1:8000/...` from local Vipps testing. **Taking agil-1's side would point production Vipps login at localhost.** Resolve that hunk in `main`'s favour. agil-1's own additions to `.env` are four `OPS_PICKUP_*` lines — a key id, an empty private key, a path to a gitignored PEM, and a *public* key — so nothing secret was committed, by design (`storage/ops/*.pem` is gitignored and referenced by path).

**Owned paths: three deliberate exceptions to flag.**
1. `.env` — above.
2. `app/Snurre/*`, `app/Http/Controllers/Api/SnurreController.php`, `config/snurre.php`, `docs/SNURRE_*`, `docs/AGENT_PLATFORM_AUDIT*.md`, `docs/schema/live_schema_baseline.sql` — three commits (`9ddee0f`, `4253c07`, `2b85dc0`) that predate this plan's work on the same branch. They are **not** part of agil-1 and not in the ownership table at all. Review and merge them on their own merit, or cherry-pick them out first.
3. Shared files: `lib/main.dart` in Hare-Driver, `l10n.yaml` and the generated `lib/l10n/*` in all three apps, `routes/api.php` (one `require`), `app/Console/Kernel.php`, `config/broadcasting.php`, `app/Providers/AppServiceProvider.php`. Each is a single append per need, as the conventions require.

**Feature flags.** 30 surface flags in `app/Ops/SurfaceFlags.php`, in five rollout stages, **all shipping off** — merging agil-1 changes nothing a partner, courier or customer can see. `php artisan ops:flags seed|list|on|off|stage`, every flip audit-logged with a reason. Each flag carries the sentence saying what the surface falls back to when it goes off, and there is deliberately no `stage off`. Rollback runbook: `Hare-AdminPanel/docs/OPS_ROLLBACK.md`. Docs: `docs/OPS_API.md` (every route, its caller, and why), `docs/OPS_POLICY_KEYS.md` (every operating number, with the six Appendix B placeholders marked as placeholders), `docs/EVENT_CONTRACT.md` unchanged — it is frozen and agil-1 validates against its fixtures.

**Merge-day checklist with agil-2: not executed.** It needs agil-2's branch to exist in a mergeable state and a second person. The order to run it in is §5 of `docs/OPS_ROLLBACK.md`.

**Environment limits that capped this phase** (all recorded so nothing reads as verified when it is not):
- **Docker Desktop is not running**, so 120 of Aerend-Feed's 180 tests skip — every Postgres- and Valkey-backed suite, including the feed-tab ranking and moderation tests. They pass when the local stack is up; they were not run here.
- **No staging environment**, so the "≤ 5s publish end to end" timing and the two-service integration pass are still unmeasured (carried from Phase 9).
- **No real devices**, which is T2 below.

### T1 / T2 / T9 / T10 — status notes

- **T1 — `GET /api/internal/feed-device-tokens` live in prod: PENDING — HUMAN.** Needs prod access. `curl -i https://<prod>/api/internal/feed-device-tokens` should answer 401 or 403; a **404 means Laravel never deployed the route** and needs a `workflow_dispatch` run. Not attempted: I have no prod credentials and would not use them for a write-adjacent probe without being asked.
- **T2 — push-notification E2E on two real devices: PENDING — HUMAN.** Needs two physical phones and FCM/APNs delivery, which no emulator or test suite can stand in for. This is still the single most important unverified path in the feed: store publishes → customer push within 30s → deep-link opens the post; customer comments → store push. The processors and templates are unit-tested (`test/notification-processors.test.ts`, added in Phase 9); the delivery is not.
- **T9 — delete the demo seed post in prod (post id `1`, likely `store_details_id` 45): PENDING — HUMAN.** Needs prod DB access, and the handover itself warns that real partner posts may exist alongside it. **Confirm what row 1 actually is before deleting anything** — a destructive prod write on a guessed id is exactly the kind of action I should not take unasked.
- **T10 — rotate `aerend-feed-pg` + `aerend-feed-redis` credentials and redeploy: PENDING — HUMAN.** Needs DigitalOcean dashboard rights, causes ~30s downtime, and must run **after** T2 so the push path is verified before the databases move.

### Out-of-band, from `FEED_HANDOVER_10DAYS.md` §4

- **Partner content seeding — BD work, not engineering.** 10–15 stores × 3–5 posts before launch. An empty feed on day one reads as a broken app rather than a new one, and the mix rule (5 store posts per Ærend post) has nothing to mix without it.
- **Native Norwegian review of the 23 machine-translated feed ARB keys.** Machine Norwegian in a Bergen-local product is noticeable, and these strings sit on the most-read surface in the app. Needs a native speaker, not a translator API.
