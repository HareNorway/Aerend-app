# AGIL-3 — agents, geo, self-delivery, and the Points / Ægil / Meg screens (agent execution plan)

**Branch:** `agil-3`, created from `agil-1` at the commit that carries
`plans/AGIL-CONTRACT.md`: `cd <repo> && git checkout -b agil-3 agil-1` in
**Hare-AdminPanel** and **aerend-app/Aerend-app** (the only two repos this plan
touches). Never created in Aerend-Feed, Hare-Store or Hare-Driver.
**Contract:** `plans/AGIL-CONTRACT.md` — **read it first; it is binding and it
wins over this file.** Its §3.3 is your name registry; its §7 defines a tick.
**Sister plan:** `plans/AGIL-1-PLAN-v2.md` (branch `agil-1`). Merge day is
contract §6 and is executed by agil-1; your Phase 8 makes you ready for it.
**Specs (authoritative, in this order):**
1. `aerend-app/docs/aerend-ai-agents-spec.docx` — Agents A / B / C, the proposal model, the status contract (§7), build order (§11), open questions (§12).
2. `aerend-app/docs/aerend-partner-self-delivery-spec.docx` — delivery modes, lifecycle, Partner endpoints, customer requirements (§5 — agil-1 builds those; you provide the fields), money, 422 states.
3. `aerend-app/docs/aerend-geo-coverage-spec.docx` — the geo model, store placement, coverage, courier eligibility, Agent E, Områder, country packs.
4. `aerend-app/docs/AEREND POINTS SPEC v2 .md` and `AEREND AEGIL AGENT SPEC FINAL VERSION.md` — for the customer screens in Phase 7 (agil-2 built the backends; you build the Bergen screens on them).
**Design (Phase 7 only):** `designs/21des/Ærend Kunde Bergen.dc.html`, the screens
listed in contract §2.2 under `poeng`, `aegil`, `meg`.

> 🛑 **Branch policy.** Nothing goes into `main` or `master` in any repo, and
> nothing is pushed unless a human says so. **No Flutter UI outside Aerend-app.**
> Partner and Bud app screens are a later plan; you land the endpoints they will
> call and stop there.

---

## 0. Agent operating instructions

**The one rule from the agents spec governs everything you build:** *propose,
never execute.* No agent publishes a product, assigns an order, changes an order
status, or moves money. Agents write `agtp_proposals`; humans decide; existing
services execute. If a task seems to need an agent to *do* something, it is
mis-read — find the proposal.

**Existing substrate you build on, never beside** (contract rule 4.3, "no second
copy"): `agents` / `agent_runs` / `agent_settings` and `App\Agent\AgentInvoker`
(agil-2's — every model call goes through it: deadline → rule-based fallback →
revalidation → one `agent_runs` row); `App\Agent\Support\PiiScrubber` (runs
inside the invoker; nothing reaches a model unscrubbed); `OrderTransitionService`
(the only writer of `ops_state`); `DeliveryProofService` (PIN); `SettlementService`
and the `ops_payouts` / `ops_payout_lines` batch (money); `NotificationService`
(`ops_notifications`); `PolicyService` (`ops_policies`, reason required);
`SurfaceFlags::register()` (flags); `FeedBridge` (never — you do not touch the
feed). Spec names that map onto these are listed in contract §3.3 ("reuse").

**Model calls.** The spec says local Ollama under OpenClaw on a Mac Studio.
That machine is not this one. `config/agentops.php` gets `driver` ∈
`fake | ollama` (env `AGENTOPS_MODEL_DRIVER`, default `fake`). Every agent is
built and tested against `fake`, whose output is deterministic fixtures in
`tests/fixtures/agentops/`. The `ollama` driver is one adapter class with a
base URL; wire it, do not depend on it. **Nothing in the acceptance lists needs a
live model.**

**External providers** (WhatsApp, Kartverket, Brønnøysund, Kassal) are adapters
behind interfaces with a `none` / `fake` default from config. Real credentials
are open questions in the specs, not tasks here.

**Copy, not ARB.** Strings in `<group>_copy.dart` as `A3Copy.<group>.<key>`,
keys `a3_*`, plus the spec §7 keys verbatim. `lib/l10n/*` is never touched on
this branch (contract rule 9). Admin screens are Norwegian with EN entries
appended to `public/assets/js/dugnad-i18n.js` `DICT` (shared file, append only;
`AdminI18nDictionaryTest` must stay green — a key with a different translation
elsewhere fails it).

**Admin screens** use the commercial layout and the `adm-*` vocabulary exactly
as `resources/views/admin/pages/super_admin/{ops,agents,points}/*` do (they are
the precedent; `OpsAdminScreenTest` and `RendersAdminScreens` are the test
pattern). Navigation is an `admin_module` migration per module.

**Commands for acceptance.**
- Backend: `cd D:/work/hare/Hare-AdminPanel && bash scripts/rebuild_test_db.sh && php artisan test --filter=<X>`; `php artisan test --filter=ContractNamesTest` (green, your entries asserted); `php artisan route:list --path=api/<prefix>`; `php artisan migrate:status`.
- Flutter (Phase 7): `cd D:/work/hare/aerend-app/Aerend-app && flutter analyze lib/ && flutter test && flutter test test/contract`.
- Ownership check before every commit: `git diff --name-only agil-1...agil-3` contains nothing outside contract §2's agil-3 columns except §2.4 appends.

**Conventions.** Migrations `2026_10_*_a3_*`, additive, no `->after()`. Every
model has `public const TABLE`. Every env var is read in `config/agentops.php`,
`config/geo.php` or `config/partner_delivery.php` and nowhere else. 422s carry
the contract's code strings. Europe/Oslo for displayed time. One commit per task
group, phase in the message. Blocked → contract §7. Do not summarise between
phases.

---

## 1. Ownership (summary — the contract is the source)

You own in Hare-AdminPanel: `agtp_*`, `geo_*`, `pd_*` (tables and columns),
`app/{Models,Services,Http/Controllers}/{AgentOps,Geo,PartnerDelivery}/*`,
`Admin/{AgentOps,Geo,PartnerDelivery}AdminController`, `routes/api_agentops.php`,
`api_geo.php`, `api_partner_delivery.php`, views `super_admin/{agentops,geo,partner_delivery}/*`,
`tests/Feature/{AgentOps,Geo,PartnerDelivery}/*`, `tests/fixtures/contract/names.agil3.json`,
`docs/{AGENTOPS,GEO,PARTNER_DELIVERY}_*.md`; and, inherited from agil-2:
`app/{Agent,Points}/*`, `app/model/{Pts*,Agent*}`, `api_points.php`, `api_agent.php`,
`super_admin/{points,agents}/*`, `tests/Feature/{Points,Agent}/*`. In Aerend-app:
`lib/screens/bergen/{poeng,aegil,meg}/*`, `lib/screens/{points,aegil,snurre}/*`,
`lib/data/{points,aegil}/*`, and the seam files' *bodies*.

You do **not** touch: anything `ops_*`, `app/Services/Ops`, `DispatchService`,
`api_ops.php`, `SurfaceFlags.php`, `ContractNamesTest.php`, `EVENT_CONTRACT.md`,
`lib/l10n`, the shell `home_main_v1.dart`, Aerend-Feed, Hare-Store, Hare-Driver.
Needs there go under "Asks of agil-1".

---

## Phase 0 — Branch, inherit, register

- [x] `git checkout -b agil-3 agil-1` in both repos at the contract commit. Confirm `git log agil-1..agil-3` is empty. *(Branched 2026-09-25 from the sync-C commits themselves: `c07f51e` / `525b014`.)*
- [x] `git cherry-pick sync-C` in both repos (agil-1 v2 Phase 0 tags it). *(No-op — the branch point already carries sync-C; all five checks verified.)*
- [x] `tests/fixtures/contract/names.agil3.json` is now yours. Added (contract + file, same commit): policies `agt.product_onboarding.bulk_threshold`, `agt.product_onboarding.first_approval`, `geo.auto_apply_templates`, `pd.driver_pin_enabled`; 422s `AGTP_TERMINAL`, `AGTP_NO_AUTHORIZATION`, `AGTP_DENYLISTED_DOMAIN`, `AGTP_SCOPE`.
- [x] `app/Providers/AgentOpsServiceProvider.php` registered in `config/app.php`: `SurfaceFlags::register(AgentOpsFlags::all())` (12 flags, storefront, off), `ModelDriver` binding (`fake` | `ollama`), the seam rebind via `app->extend(CandidateSource)` only when `geo.engine.cutover` is on and the class exists, and the three route files.
- [x] `config/agentops.php`, `config/geo.php`, `config/partner_delivery.php`; `.env.example` appended.
- [x] `docs/AGENTOPS_ARCHITECTURE.md`.

**Acceptance**
- [x] `ContractNamesTest` green (61 asserted, agil-3 reserved entries skipped); `ops:flags list` shows the 12 `agt.* geo.* pd.*` keys (not seeded → off); commit `Phase 0: branch and inherit sync-C`.

---

## Phase 1 — Proposal substrate, the Agent API, Agentsenter

Spec §2–§3 and §11 step 1. Everything else stands on this.

- [x] `2026_10_02_000000_a3_create_agtp_proposals`: `agtp_proposals (id, agent_key, proposal_type, subject_type, subject_id, payload_json, evidence_json, rationale, status, proposed_at, expires_at, decided_by_type, decided_by_id, decided_at, decision_reason, executed_at, execution_ref, error, idempotency_key unique, created_at, updated_at)`. Model `App\Models\AgentOps\Proposal` with `TABLE`, `STATUS_*` and `TYPE_*` constants matching the contract enums exactly. `App\Models\AgentOps\ProposalStatus` / `ProposalType` constant classes for `ContractNamesTest`'s `enum` kind.
- [x] `App\Services\AgentOps\ProposalService`: `propose(agentKey, type, subjectType, subjectId, payload, evidence, rationale, ttlHours = policy)` — idempotent on `idempotency_key` (returns the existing row, never a duplicate); `approve / reject / expire / markExecuted / markFailed` with the state machine `proposed → approved|rejected|expired`, `approved → executed|failed`, terminal states refuse with 422 `AGTP_TERMINAL`; every decision writes `ops_audit_log` through `AuditLogger` and emits `agent.proposal_decided` v1 (fixture from Sync C, `EventContractTest` extended). Expired proposals are visible but not approvable.
- [x] `agentops:expire-proposals` (scheduled every 5 min via a `Kernel.php` append) and `agentops:seed-policies` (`AgentOpsPolicyKeys` seeded through `PolicyService::seedDefaults`-style helper with a reason).
- [x] The scoped **Agent API** `routes/api_agentops.php` under `/api/agentops`: bearer token per agent checked against `agents.token_hash` (agil-2's column; hashing helper reused from `AgentInvoker::assertScope`'s neighbourhood — find it, do not write a second), middleware `agentops.token` binds the agent and refuses when `agents.enabled` is false (**the kill switch is the existing column**). Routes: `POST proposals` (creates via `ProposalService`, scope-checked per agent), `GET proposals/{id}`, `POST proposals/{id}/decide` (admin session only, not agent token), `POST runs` (writes an `agent_runs` row for a run that happened off-box — the spec's `agent_run_log`), `GET config/{agent}` (thresholds from `agent_settings` + policies). Every call logged with `agent_key`.
- [x] Register the four agents (`AgentOpsRegisterSeeder`; **note:** `ContractNamesTest` greps agil-2's `AgentRegisterSeeder.php` for `agent` entries, so those four registry rows stay `built:false` until agil-1 widens the grep — listed under Asks of agil-1; `AgentApiTest` asserts the rows instead): `AgentOpsRegisterSeeder` (new file; do not edit agil-2's seeder) inserts `product_onboarding`, `courier_comms`, `payment_sorting`, `geo` into `agents` **disabled**, with `surface`, `autonomy = L1`, scopes, caps. `ContractNamesTest` `agent` kind asserts them after seeding.
- [x] Slack notifier `App\Services\AgentOps\SlackNotifier` behind `AGENTOPS_SLACK_WEBHOOK` (`none` → logs). Open question #6 (channel conventions) → one channel, documented.
- [x] **Agentsenter** admin shell: `/admin/agentsenter` → `Admin\AgentOpsAdminController@index` with tabs `Forslag` (proposal queue: type / subject / rationale / evidence disclosure / expires / Godkjenn · Avvis with reason), `Kjøringer` (agent_runs filtered to the four agents), `Innstillinger` (thresholds per agent from policies; kill switch links to the existing `/admin/agenter` toggle — do not duplicate it). Views under `super_admin/agentops/`, `adm-*` only, `RendersAdminScreens` test. Nav migration `..._a3_register_agentsenter_menu` (parent `Agentsenter`, module_name `agentsenter`).
- [x] Tests `tests/Feature/AgentOps/ProposalTest.php`, `AgentApiTest.php`, `AgentsenterScreenTest.php`: idempotency (same key twice → one row), full state machine incl. refusals, TTL expiry, kill switch refuses the API, scope refusal, audit rows, the event fixture, screens render with rows.

**Acceptance**
- [x] `php artisan test --filter="AgentOps"` green; `ContractNamesTest` asserts the Phase 1 entries; `route:list --path=api/agentops` shows the five routes; commit `Phase 1: proposal substrate and Agentsenter`.

---

## Phase 2 — Agent C: payment sorting

Spec §6 and §11 step 2. Review-only until payout rails exist (open question #3),
which is exactly what the spec asks for.

- [x] `2026_10_03_000000_a3_create_agtp_settlements`: `agtp_settlement_batches (id, proposal_id, period_start, period_end, party_type ∈ partner|courier, status ∈ proposed|approved|rejected|exported|executed, created_by_agent, …)` and `agtp_settlement_lines (id, batch_id, party_id, order_id, kind ∈ gross|deduction|delivery_income|tip|adjustment, amount_ore, description, anomaly_flag, anomaly_reason, evidence_json, status)`. Models with `TABLE`.
- [x] `App\Services\AgentOps\PaymentSortingAgent`: cadence from `agt.payment_sorting.cadence`; reads completed orders (`ops_order_events` type `order.delivered` via `OrderEventsSource` — agil-2's adapter, already pointed at the right table), `ops_run_payments` / `ops_payout_lines` (courier side, by constant), `SettlementService` (partner side); builds one `settlement_batch` proposal per period per party type with lines and order ids as evidence; anomaly flags = deviation > 2σ from that party's trailing 8 periods (informational only). **Framing rule:** every partner/courier-facing `description` states what *they* receive; Ærend's cut is never a percentage on a line. All amounts integer øre.
- [x] `agentops:settle {period}` command (manual trigger) + scheduled per cadence.
- [x] Approve in Agentsenter → `Settlements` tab: batch or line-by-line; a rejected line returns to the next batch with its reason; approve → `status = approved` and an **export** (CSV in the existing Fiken/Tripletex/PowerOffice shape from `SettlementService`); execution hand-off: when payout rails exist, `markExecuted` with `execution_ref` — until then, a documented `exported` state. The agent never calls the payout batch.
- [x] Read APIs for the other apps (**UI deferred**): `GET /api/agentops/settlements/partner/{storeId}` and `.../courier/{courierId}` returning that party's own lines with `settlement_status_proposed|_approved|_paid` — the keys from spec §7. Feature-tested; no screen.
- [x] Self-delivery hook (spec §6.2 of the self-delivery doc): for orders with `pd_delivery_actor = partner` the batch has a partner line of kind `delivery_income` for 100 % of the fee and **no courier line**; tips per open question #2 → default to the store as a separate line, flagged in the plan. (The column arrives in Phase 4; write this against the constant with a `hasColumn` guard so Phase 2 is green before Phase 4 — then Phase 4's test asserts the present branch.)
- [x] Tests `PaymentSortingTest.php`: a period with 3 partner and 2 courier orders yields the right lines to the øre; anomaly flag set and not blocking; reject-a-line carries forward; export shape matches the existing CSV test in `SettlementTest`; the agent cannot approve its own batch (API token → 403); self-delivery attribution.

**Acceptance**
- [x] Green; `ContractNamesTest` asserts; Agentsenter `Settlements` renders; commit `Phase 2: Agent C payment sorting`.

---

## Phase 3 — Agent A: product onboarding

Spec §4 and §11 step 3. Drafts are never live; approval routes through the
existing product path so the change log and `product.price_changed` fire as they
do for any edit.

- [x] `2026_10_04_000000_a3_create_agtp_product_drafts_and_authorizations`: `agtp_content_authorizations (id, store_id, domain, scope, expires_at, document_ref, granted_by, revoked_at)`; `agtp_product_drafts (id, proposal_id, store_id, source ∈ partner_feed|kassal|own_site, name, description, category_id, image_ref, price_ore_suggested, ean, variants_json, confidence, evidence_json, status ∈ draft|approved|rejected, decided_by_type, decided_by_id, decided_at, created_product_id)`. Models with `TABLE`.
- [x] Source adapters behind `App\Services\AgentOps\Sources\ProductSource` interface: `PartnerFeedSource` (CSV upload / free text / EAN list), `KassalSource` (interface + HTTP adapter behind `AGENTOPS_KASSAL_API_KEY`; `fake` fixtures for tests), `OwnSiteSource` (**refuses without a valid, unexpired `agtp_content_authorizations` row for the domain**; fetch + parse behind an interface, fake in tests). Priority order as spec §4.2. Never Wolt/Foodora or any third-party domain — assert a denylist.
- [x] `App\Services\AgentOps\ProductOnboardingAgent`: triggers = API call from the Partner endpoint (below), panel-initiated import, scheduled refresh (policy-gated, off by default); one `product_draft` proposal per product with evidence and a confidence score; images through `MediaStorageService` with provenance recorded in `evidence_json`; prices are **suggestions** — the draft carries `price_ore_suggested`, never writes a price.
- [x] Approval → `App\Services\AgentOps\DraftApprovalService`: the existing product path is inlined in `StoreController::saveProductDetails` (request-bound, not callable as a service), so the service builds the product through the same `StoreProductDetails` model with the same columns/defaults, then runs price + availability through `ProductChangeLogger::applyAndLog` so the change log and `product.price_changed` fire as for any edit (never a raw `store_product_details` write), which logs via `ProductChangeLogger` and goes live per the store-feed rules; sets `created_product_id`; `markExecuted`. Bulk approve for confidence ≥ policy `agt.product_onboarding.bulk_threshold` (add to registry: default 0.9).
- [x] Partner endpoints (**UI deferred**): `POST /api/agentops/imports` (start), `GET /api/agentops/imports/{id}/drafts`, `POST .../drafts/{id}/approve|reject`, bulk approve — store-scoped through the existing store auth; feature-tested only. The Partner screen «AI-assistert import» is a later plan.
- [x] Agentsenter → `Produktonboarding` tab: all partners' queues, approve on a partner's behalf, source authorizations (grant / revoke with document ref), provenance view, thresholds. Open question #5 (who approves for a brand-new partner) → policy `agt.product_onboarding.first_approval` ∈ `partner|aerend`, default `aerend`, in the registry.
- [x] Tests `ProductOnboardingTest.php`: a CSV of 3 rows → 3 drafts, none live; approve one → one product via the real service, one change-log row, `created_product_id` set; scrape without authorization → 422 `AGTP_NO_AUTHORIZATION`; expired authorization → same; denylisted domain → 422; price is never written by the agent; bulk approve respects the threshold; kill switch stops triggers.

**Acceptance**
- [x] Green; asserted; screens render; commit `Phase 3: Agent A product onboarding`.

---

## Phase 4 — Partner self-delivery (backend, admin, endpoints)

Self-delivery spec §2–§4, §8–§11. Customer-side (§5) is agil-1's Phase 6 and
reads the fields you create here through the contract's tracking payload.

- [x] `2026_10_05_000000_a3_add_pd_columns`: the five `pd_*` columns on `store_details` and the four on `user_store_product_booking` exactly as contract §3.3, nullable/defaulted as listed, **no `->after()`**; `pd_actor_changes (id, order_id, from_actor, to_actor, changed_by_type, changed_by_id, reason, changed_at)`. `App\Models\PartnerDelivery\DeliveryActor` constants `AERND_COURIER = 'aerend_courier'`, `PARTNER = 'partner'` (column names live in `PdColumns` so the enum class holds values only); `PdPolicyKeys` + `pd:seed-policies`.
- [x] `App\Services\PartnerDelivery\SettingsService`: read/write the five fields; `deliveryMode()` derived (`courier_only | self_only | per_order`), never stored; both switches off → 422 `PD_MIN_ONE_MODE`; `suggest_self_delivery` forced false when `can_self_deliver` is false; `pd.require_aerend_approval` policy gates `self_only`/`per_order` behind `pd_approved_by_aerend`.
- [x] `App\Services\PartnerDelivery\ActorService`: `chooseAtAccept(order, actor)` (per_order → explicit; else derived), `switchActor(order, to, by, reason)` with the rules — self → courier allowed until `picked_up`, then offers to the pool via `DispatchService::createAssignment` (its `CandidateSource::eligible()` now sees `aerend_courier` and allows); courier → self allowed until an `ops_assignments` row is `accepted`, after that 422 `PD_COURIER_ALREADY_ACCEPTED`; every switch → `pd_actor_changes` + `order.delivery_actor_changed` v1 (fixture from Sync C) + `ops_audit_log`. Radius rule: `self_only` store + address outside `pd_self_delivery_radius_km` → 422 `PD_OUTSIDE_RADIUS` at checkout; `per_order` → auto-fallback to courier with a store notification via `NotificationService::send()`.
- [x] `App\Services\PartnerDelivery\StoreDeliveryService`: `onTheWay(order, etaMinutes?)` → `OrderTransitionService::transition(order, picked_up, actor_type='store', ...)` + `pd_store_eta_minutes` (default policy) — refused if already `picked_up` (422 `PD_ON_THE_WAY_ALREADY`); `delivered(order, pin?)` → PIN through `DeliveryProofService` else `pd_delivered_without_code = true` + reason required → `transition(delivered, actor_type='store')`; `deliveryView(order)` read model = address + door info exactly as entered at checkout, contact availability, the two actions' current legality.
- [x] **Dispatch skip** (contract §5.6): `GeoCandidateSource` is Phase 5; here, `App\Services\PartnerDelivery\PdEligibility` used **through the seam only**: `AgentOpsServiceProvider` wraps the bound `CandidateSource` in `PdAwareCandidateSource` (eligible() = PdEligibility ∧ inner), so neither `DispatchService` nor `OpsCandidateSource` is edited. Test `PartnerDelivery/DispatchSkipTest`: a `partner` order → `createAssignment` and `offer` refuse `PD_PARTNER_DELIVERS`; switching to courier makes them succeed.
- [x] `pd:remind-on-the-way` (scheduled every minute): `ready` + `partner` + no `picked_up` after `pd.reminder_after_ready_minutes` → `NotificationService::send()` to the store; the customer's stage stays 1 (agil-1's copy says "Butikken gjør klar leveringen").
- [x] Routes `routes/api_partner_delivery.php` under `/api/partner-delivery` (**UI deferred; feature-tested**): `GET/POST settings`, `POST orders/{id}/actor`, `POST orders/{id}/on-the-way`, `POST orders/{id}/delivered`, `GET orders/{id}/delivery-view` — store-scoped auth; a driver PIN concept (spec §4.3) is one policy-gated header, documented, not a new auth system.
- [x] Settlement line: `SettlementService` gains nothing; Phase 2's agent writes `delivery_income` lines for `partner` orders; `ops_payout_lines.kind` gains the value via a `Model` constant append (`PayoutLine::KIND_DELIVERY_INCOME` — **ask agil-1** to add the constant to their model; until then write the string through your own `PdPayoutKinds::DELIVERY_INCOME` and the `no-literal` grep excludes kinds).
- [x] Admin `/admin/egenlevering` → `Admin\PartnerDeliveryAdminController`: per-partner view and override of the five fields + approval; oversight (late rate against `ops_promised_end` for `partner` orders, `pd_delivered_without_code` frequency, open problems); revoke; config (policies). Nav migration inserts the child `Egenlevering` under the parent found by `module_name = 'drift'`. `RendersAdminScreens` test.
- [x] Docs `docs/PARTNER_DELIVERY_GUIDE.md`: the lifecycle table from spec §3 with the **contract's** state names, the 422 table, what the customer sees (pointer to agil-1's tracking payload), what is deferred (Partner UI, v2 butikkmodus).
- [x] Tests `PartnerDelivery/{Settings,Actor,StoreDelivery,DispatchSkip,Reminder,AdminScreen}Test.php`: every 422; the switching matrix; on-the-way transitions through the transition service (assert an `ops_order_events` row with `actor_type = store`); delivered with PIN via `DeliveryProofService`, without PIN needs a reason; the reminder fires once; the event fixture validates; Phase 2's attribution now asserted with the column present.

**Acceptance**
- [x] Green; asserted; `route:list --path=api/partner-delivery` shows five; commit `Phase 4: partner self-delivery`.

---

## Phase 5 — Geo & coverage engine, store placement, Områder

Geo spec §2–§5, §7, §9–§12. **Chunk 0 first.**

- [x] **Chunk 0 — read-only audit** (`docs/GEO_AUDIT.md`): the current geofence tables `admin_area_list`, `restricted_area`, store `address_lat/long`, `service_lat/long`, `admin_area_list` usage in dispatch and the apps, `ops_courier_locations`; and the **cell scheme decision**: check for a maintained PHP H3 binding (composer / extension). If none, `geo.cell_scheme = geohash_7` (pure PHP, ~25 lines), documented with the precision comparison. Record which manual data becomes derived.
- [x] `2026_10_06_000000_a3_create_geo_tables`: all eleven `geo_*` tables per contract §3.3 with `cell varchar(16)` everywhere, `geo_country_packs.cell_scheme`; models with `TABLE`; enum constant classes for `ZoneStatus`, `PlacementState`, `EligibilitySource`. `GeoPolicyKeys` + `geo:seed-policies`; `geo_country_packs` seeded with `NO` (Kartverket, Brønnøysund, BankID via Idura, Vipps, Europe/Oslo, NOK, 15/25 %, `nb`).
- [x] `App\Services\Geo\CellIndex` (encode lat/lng → cell, neighbours, distance between cell centroids) per the chosen scheme; `ZoneService` (zones as cell sets; add/remove cells; adjacency computed; status draft/active/paused; `geo.zone_changed` v1 on every change, fixture from Sync C); `FootprintService` (store footprint = cells within `geo.max_travel_min` of the store cell by straight-line at a policy speed — no routing engine; self-delivery radius honoured from `pd_self_delivery_radius_km`; cached in `geo_store_footprint_cells`, recomputed on zone/store change; `geo:recompute-footprints`); `CoverageService` (address → cell → stores whose footprint contains it, fee and ETA from zone rules; answered from cache; `< 100 ms` asserted in a test with 200 stores); unmet demand: uncovered lookups and waitlist logged **at cell level only**.
- [x] `geo:import-legacy-areas`: converts today's polygons/areas into `geo_zones` + `geo_zone_cells` (draft), one region `Bergen`; `geo:shadow-compare`: for the last N orders, old coverage answer vs new, report to `docs/GEO_AUDIT.md`. Flag `geo.engine` = shadow mode (compute, log, do not answer).
- [x] **Store placement pipeline** `PlacementService`: org.nr → `BrregClient` (adapter, fake in tests) → registered address → partner confirms/corrects pickup address → `GeocoderClient` (Kartverket adapter, fake in tests; `GEO_GEOCODER_FALLBACK`) → lat/lng + cell + confidence → zone resolution: active zone → `placed` + footprint; region but no active zone → `waiting_zone` (+ Agent E signal, Phase 6); outside → `outside_region` (+ unmet demand); low confidence → Agent E placement proposal (Phase 6), never a silent guess. Manual override → `geo_override_log`, counted in health. Routes `POST /api/geo/stores/{id}/place`, `POST .../confirm-pin` (**Partner UI deferred**).
- [x] **Courier side**: `EligibilityService` — home (address or cell) → home zone; eligibility = home + adjacent (`source = home|adjacent`); `courier_presence` from `ops_courier_locations` (read by constant, `hasTable`-guarded — it is agil-1's) → cell while online, precise only `on_run`; `geo:prune-presence` per `geo.presence_retention_days`; auto-extension when online in a non-eligible adjacent zone with a gap and good standing (`geo.auto_extend_adjacent_only`), else Agent E proposal; "Områdene dine" read model + opt-out list. Routes `POST /api/geo/couriers/{id}/home`, `GET /api/geo/couriers/{id}/zones` (**Bud UI deferred**).
- [x] **`GeoCandidateSource implements App\Ops\Dispatch\CandidateSource`**: candidates = online couriers whose live cell is within T minutes of the store cell, eligible for the store's zone, not on hold, not mid-delivery (or stackable via agil-1's existing `canStack`), ranked by proximity then acceptance history; `eligible()` = `PdEligibility` (Phase 4). Bound only when `geo.engine.cutover` is on. Test: with the flag on, `DispatchService::offer` (agil-1's, unchanged) receives your candidates; with it off, agil-1's default.
- [x] Customer coverage route `GET /api/geo/coverage?lat=&lng=` and `POST /api/geo/waitlist` (behind `geo.customer.coverage`; agil-1's checkout calls them, contract §3.3).
- [x] **Områder** admin `/admin/omrader` → `Admin\GeoAdminController`: regions → zones list with status, hours, fee rules, courier target; a map (Leaflet from cdnjs, cells drawn as their bounding polygons) with overlays: stores by placement state, online couriers **aggregated per cell** (never individual tracks), unmet-demand heat, ETA p50/p90 per zone from `ops_order_events`; proposal queue (Phase 6 fills it); health per zone (supply vs demand, gaps, override count, stores waiting); manual cell painting **as GeoJSON upload → cell set** (v1; interactive painting is not in scope), logged as override; country packs. Nav migration parent `Områder`. `RendersAdminScreens`.
- [x] Docs `docs/GEO_GUIDE.md`: the model, the cell scheme and why, cut-over (flag order: `geo.engine` shadow → compare → `geo.engine.cutover`; old tables read-only after; store-courier links removed from UIs is **deferred with the app UIs**).
- [x] Tests `Geo/{CellIndex,Zone,Footprint,Coverage,Placement,Eligibility,CandidateSource,ShadowCompare,OmraderScreen}Test.php`.

**Acceptance**
- [x] Green; asserted; `geo:shadow-compare` runs on the test DB and writes the report; `geo.engine.cutover` off by default and `DispatchTest` (agil-1's) still green with the flag off; commit `Phase 5: geo engine and Områder`.

---

## Phase 6 — Agent E (geo proposals) and Agent B (courier comms)

Geo spec §6; agents spec §5 and §11 step 4; the legal gate in §9.

**Agent E — `geo`**
- [x] `App\Services\AgentOps\GeoAgent` working only through **tools** (`geocode`, `cellLookup`, `coverageStats`, `demandHeat`, `etaStats` — each a method returning data the proposal stores as evidence); the model (fake driver) never emits coordinates. Proposals: `geo_placement` (low-confidence pins → best pin + partner confirmation prompt), `geo_zone_change` (cell diff from `waiting_zone` stores, unmet-demand cells, waitlist density; also split/merge/hours from ETA p90 drift), `geo_eligibility` (gap alerts → specific couriers or a recruitment area; auto within guardrails else proposal), `geo_communication` (template slots for affected partners / couriers / waitlisted customers via `NotificationService`; new wording → proposal), `geo_launch_brief`. Every geometric claim is a tool result in `evidence_json`; every proposal is a cell diff or config diff, applied by `ZoneService` on approval, reversible. Open question #5 → nothing auto-applies in v1 except template communications (policy `geo.auto_apply_templates`, in the registry, default true).
- [x] Områder proposal queue shows the cell diff on the map + evidence + Approve / Edit / Reject; approval applies via `ZoneService` and notifies per the spec §8 table (all messages ARB/copy-keyed templates, filled by the agent).
- [x] Tests `AgentOps/GeoAgentTest.php`: a `waiting_zone` store yields one `geo_zone_change` proposal whose cells are exactly the tool output; approval extends the zone, emits `geo.zone_changed`, flips the store to `placed`, sends the three template notifications; low-confidence geocode → placement proposal, never a silent placement; nothing applies without approval.

**Agent B — `courier_comms`**
- [x] `2026_10_07_000000_a3_create_agtp_courier_tables`: `agtp_courier_consents (courier_id, channel, granted_at, revoked_at, wording_version)`, `agtp_courier_outreach (proposal_id, order_id, courier_id, channel, template_id, sent_at, delivered_at, response ∈ accepted|declined|none)`.
- [x] `App\Services\AgentOps\CourierCommsAgent`: trigger = order at `accepted`/`ready` with `pd_delivery_actor = aerend_courier` (**skip partner orders entirely**) and no accepted assignment after `agt.courier_comms.t1_minutes`; shortlist = `CandidateSource::candidates()` (the seam — geo when cut over, ops otherwise) filtered by consent, not on hold, not contacted in the last N minutes, outside quiet hours; ranking inputs and the list stored in evidence; K per wave, W waves, T2 interval from policies; one `courier_outreach` proposal per wave with `subject_type = order` (**agil-1 derives "Finner bud" from this — contract §5.1**); auto-approve **only** when flag `agt.courier_comms.auto_approve` is on *and* consent/quiet-hours/rate guardrails pass, else manual in Agentsenter.
- [x] `WhatsAppProvider` interface + `NoneProvider` (logs) + a `MetaCloudProvider` skeleton behind `AGENTOPS_WHATSAPP_PROVIDER`; templates are pre-approved slots only — the message body is never generated: store name, zone (never the customer address), pickup ETA, earnings placeholder from config, deep link `hare-driver://offer/{id}`. No PII, no order price — asserted by a test that greps the rendered message.
- [x] Shift reminders (scheduled batch proposal, opted-in couriers, approved once per schedule).
- [x] Courier-side fields (**Bud UI deferred**): `GET /api/agentops/offers/{id}/badge` → `agent_offer_from_ai` when an outreach row exists for the offer; `POST /api/agentops/couriers/{id}/whatsapp-consent` (grant/revoke, wording version) — consent capture in onboarding is the Bud app's later plan; the profile toggle alone is **not** consent (spec §9).
- [x] **Legal gate:** `agt.courier_comms.auto_approve` ships off and `docs/AGENTOPS_COURIER_COMMS.md` states that auto-outreach must not be enabled until consent wording and default have legal sign-off (open question #2). Manual mode works end to end without it.
- [x] Agentsenter → `Budkontakt` tab: outreach log per order, thresholds, quiet hours, manual/auto, consent overview, kill switch link.
- [x] Tests `AgentOps/CourierCommsTest.php`: partner orders never proposed; consent, quiet hours, rate limit, on-hold each exclude; K/W/T2 honoured; evidence contains the ranking; the message has no PII and no price; auto-approve off → proposal waits; on → approved within guardrails; the outreach row gives agil-1's `finding_courier` its input (assert the row shape the contract names).

**Acceptance**
- [x] Green; asserted; commit `Phase 6: Agent E and Agent B`.

---

## Phase 7 — Aerend-app: Meg, Points, Ægil screens

Fill the seam stubs and build every screen in contract §2.2's `poeng`, `aegil`,
`meg` rows, to the design, reachable, on agil-2's existing APIs (`api_points.php`
under `points/`, `api_agent.php` under `agent/` — see `api_constant.dart` L331–338
for the bases already in the app). Copy in `poeng_copy.dart`, `aegil_copy.dart`,
`meg_copy.dart`. Mount the four orphaned Points widgets (`MegPointsCard`,
`PremiehyllaShelf`, `WelcomeMoment`, `SuggestionTray`) and the Ægil widgets in
`lib/screens/aegil/widgets/` where the design places them — rebuild rather than
mount when the design differs. Use `lib/screens/bergen/kit/*` for sheets, chips,
CTAs, toasts; never re-implement them.

**Meg** (`meg` ≈L5942–6091; `favoritter` ≈L6699; `konto` ≈L6746; `bestillinger`; Varsler ≈L6809)
- [x] `meg/meg_screen.dart` fills `MegScreen` (tab 3): header ("{navn} fra {bydel} · {zone}", goal bubble, "Premie: gratis levering", **Gullbilletten** "Gi 200 · få 200 poeng – Del" with the referral code from `points/me/referral`), the **Poeng** card (≈L5978: DITT NIVÅ ladder, POENG Å BRUKE, pending, goal %, "Hent premien" when reached, Premiehylla / "Slik får du poeng" → `BergenArk` variant), **Meg-rader** (≈L6031: Nivå, Fløyen-ligaen (rank or "Bli med"), UKENS OPPDRAG (Godta / Ikke dette → `points/me/mission`), Gullbilletten, Favoritter (count), Nytt fra butikkene (badge → `/bergen/utforsk?tab=feed`, agil-1's), Hjelp og kontakt → `/bergen/kundeservice`, agil-1's).
- [x] `meg/favoritter_screen.dart` `/bergen/meg/favoritter`; `meg/konto_screen.dart` `/bergen/meg/konto` (Vipps-verifisert, Adresser, Betaling, Innstillinger "Varsler om krysningen" / "Roligere bevegelse" → `MediaQuery.disableAnimations` preference, "Dine data lagres i Norge") — reuse the existing account/address/card data layers, restyle to the design; `meg/bestillinger_screen.dart` `/bergen/meg/bestillinger` from `GET /api/ops/customer/orders` (agil-1's Phase 1 route; guarded 404 → empty state) with rows → `/bergen/sporing/{id}` (live) or `/bergen/bestilling/{id}` (done); `meg/varsler_panel.dart` `/bergen/meg/varsler` (filter chips, "PÅ VEI NÅ Æ-42K … Vis sporing", per-row reason + "Ikke slike varsler" / Fjern, empty "Ingenting nytt siden sist · Fin utsikt", undo) from the existing notification list + `agent_pushes`.
- [x] `meg/borte_entry.dart` filled: `mensDuVarBorteCard` (≈L7322) returns the card when `agent/me/away` (add to `api_agent.php` — your file) has ≥1 item: "Tre ting fra Ægil", the three lines with Angre where applicable, "Se de siste 30 dagene" → `/bergen/aegil/minne`.

**Points** (`premier` ≈L6178; `velger` ≈L6306; `liga` ≈L6368; `opprykk` ≈L6124; `fiske` ≈L6436–6640; Napp-kort ≈L2115)
- [x] `poeng/premiehylla_screen.dart` `/bergen/premiehylla`: goal with %, "Mine premier (n)", the month's shelf priced in points ("aldri i kroner"), MÅL / UTSOLGT badges, "N igjen", set-goal, locked section, "Premier gjelder i 60 dager" — from `points/prizes`, `points/me`. `poeng/premie_screen.dart` `/bergen/premie/{id}`.
- [x] `poeng/aegil_velger_screen.dart` (Ægil velger → Premien Ægil valgte): the animated scene (rear / find / shock / explore images — reuse `assets/images/aegil/*` from the onboarding commit; add missing poses under `assets/images/aegil/` with a `pubspec` append), reveal card ("Verdi minst 300 kr", reason), Hent premien / Bra / Ikke for meg / Hopp over — `points/prizes/pick` (agil-2 route; if absent, add to `api_points.php`).
- [x] `poeng/liga_screen.dart` `/bergen/liga`: rank, Hele Bergen / Din bydel tabs, climbers table, monthly prizes (the four from the design), "Se månedsslutten" → `BergenArk` `kArkErSeremoni`, "Navn i ligaen" → `kArkErLiga` join sheet — `points/league`.
- [x] `poeng/opprykk_screen.dart` `/bergen/opprykk` (Nivåopprykk celebration; entered from `TierPromoted` push / `points/me` tier delta; "HER ER NOE TIL DEG", "Hylla di har fått tre nye premier", Hopp over / Ferdig). Mount `WelcomeMoment` here for the first tier.
- [x] `poeng/fjordfiske_screen.dart` `/bergen/fjordfiske`: Bryggen · fiske SVG, Sjø · fiske (reuse `BergenTokens` sea modes), Ægil rear/shock/find/sorry, Ægil snakker ("Kast N av M · K lagret"), **Fiske-kontroller** (cast → "Snøret er ute … vent på napp" → "DRA INN!" → Slipp / Legg i kurven / Lagre; prize: Slipp / Hent), **Agn** chip rail, **Fangst** card (+5 poeng, item, shop, price, ETA), **Premiefangst** ("Fra hylla di"), frequency from `fiskePremieHverN / Maks / FraKast` as policies `points.fiske_*` (add to `config/points.php` keys + registry), end state ("Det var alt for nå. Du lagret N og la M i kurven." / "Kast ut igjen i morgen"); offers from `agent/suggestions?context=fiske`; catches award via `points/me/earn?rule=dagens_napp` (agil-2's DagensNappRule — 5/day cap enforced server-side).
- [x] `poeng/napp_entry.dart` filled: `showNappKort` renders **Napp-kort** (≈L2115: rises from the water; product, shop, "Bergensk" badge, price, reason; Legg til / Ikke nå / Aldri dette → `agent/suggestions/{id}/feedback`); `poeng_entry.dart` filled: `poengEntryCard` = the Hjem's compact points card, `kPoengRoute` → `/bergen/meg` scrolled to the Poeng card.

**Ægil** (`agent` ≈L3523–3800 and every `agentGaa` state; Det Ægil vet ≈L3586+; brett; Mens du var borte)
- [x] `aegil/aegil_screen.dart` `/bergen/aegil` — the chat screen: header (avatar pose front/find/popup/discount/store/sorry/wait, state label Lytter / Leter i Vågen / Fant tre valg / Fant noe / Fikser kurven / Byttet / Sammenlikner / Beklager…, level, **Det jeg vet** chip when memory exists), **Ægil-hilsen** (greeting; empty-memory variant "Vil du at jeg husker hva du liker?" Ja, la oss / Ikke nå), **Forslagskort** (the four evening cards from `agent/suggestions?context=evening`), **Klassisk søk** block (→ `/bergen/sok`, agil-1's), the states: `agForslag` (basket proposal: lines, "6 varer · inkl. levering", "Derfor:" line, "Bytt butikk" → shop picker sheet), `agKvittering` (receipt with Angre → `BergenUndoPill`), `agFunn`, `agSammen` (price comparison table incl. delivery), `agFiks` (swap), `agTillatelse` ("Jeg er en AI… Du betaler alltid selv", Foreslå / Handle i kurven levels), `agMinne`, onboarding `agOb1–5 + agObSum` (5 chip steps, "+N Ægil-poeng"), `agNivaaSkjerm` ("Så mye kan Ægil gjøre", the 5 `NIVAAER`), `agIkkeFunnet`, `agAldersblokk` ("18+ · ikke verifisert … BankID"), allergen disclaimer, the agent basket bar ("Kurv · N · X kr · tid – Betal med Vipps" → hands the cart to agil-1's `/bergen/kurv`), voice input, the Tweaks sheet (dev only, `kDebugMode`), "Alle butikker" picker. Intents from the query string: `intent=photo` (C3: "Bestill fra bilde" → `agent/photo-order`, add to `api_agent.php`), `intent=door` (C4: door-note interpretation → `agent/door-note`), `intent=gift`, `intent=store&id=`. All through the existing `agent/chat` route and agil-2's `ChatToolGate` / `CommunicationRouter`; against-interest lines from `AgainstInterestEngine` rendered with `against_interest_line.dart`.
- [x] `aegil/minne_screen.dart` `/bergen/aegil/minne` (Det Ægil vet om deg: DU LIKER / BUTIKKER / HUSSTAND / KOSTHOLD / MIDDAGSRYTME / ÆGIL HAR LAGT MERKE TIL with add/remove and "Stemmer", VARSLER, "Glem alt") on `agent/preferences` (`PreferenceService`) and `agent/trust-ledger` (Tillitsregnskap Ark variant).
- [x] `aegil/brett_entry.dart` filled: `aegilFindCount()` from a cached `agent/suggestions?context=home` count; `showAegilBrett` renders the drawer of `kBrettKort` (add / undo / "Ikke for meg"). `aegil_entry.dart` filled: `aegilGreeting` = the compact Hjem greeting bubble; `kAegilRoute` → `/bergen/aegil`.
- [x] `bergen_routes_agil3.dart` filled with every `/bergen/…` agil-3 route from contract §3.4.
- [x] Tests under `test/{points,aegil,meg}/`: every screen renders from fake API responses; every route builds (`test/contract/contract_names_test.dart` — agil-1's file, do not edit; your routes are picked up automatically); reachability greps per screen; Fjordfiske's 5/day cap respected client-side and server-side.
- [x] **Design ledger** — one row per screen, opened beside its `data-screen-label` block, differences listed.

**Design ledger** (compared beside `designs/21des/Ærend Kunde Bergen.dc.html`)

| Screen | Design block | Differences accepted / to fix |
|---|---|---|
| Meg | ≈L5942 | Header shows "{fornavn} fra Bergenhus" (bydel is a copy constant until agil-1 exposes the zone name); Nytt fra butikkene / Hjelp og kontakt rows route to Konto until agil-1's `/bergen/utforsk?tab=feed` and `/bergen/kundeservice` land; Gullbilletten "Del" copies the referral link (no share sheet). |
| Favoritter | ≈L6699 | The list is the existing `FavouriteStoreScreen` behind a door row (no favourites API for a compact list); the "Kast ut" empty state and footer line are per design. |
| Konto | ≈L6746 | Vipps-verifisert badge is static (no verification flag in prefs); "Roligere bevegelse" is honoured by every agil-3 screen through `A3Services.reducedMotion` — app-wide `MediaQuery.disableAnimations` is an Ask of agil-1; BankID age check is not wired. |
| Bestillinger | design `bestillinger` | "PÅ VEI NÅ" needs agil-1's `GET /api/ops/customer/orders`; until then `liveCount` is 0 and every row opens the existing `OrderHistory`. |
| Varsler | ≈L6809 | Filters classify the mass-notification list by title/message keywords (no `agent_pushes` join yet); per-row "Ikke slike varsler" is Fjern + undo (no mute endpoint in agil-2's API). |
| Mens du var borte | ≈L7322 | Cached `agent/me/away` (≤3) with Angre; "Se de siste 30 dagene" opens Varsler. |
| Premiehylla | ≈L6178 | As designed; claims render as chips (no voucher artwork). |
| Premie | `/bergen/premie/{id}` | Route argument is the `Prize` or an `int` id (Flutter route table has no path params). |
| Ægil velger | ≈L6306 | Poses reuse `assets/images/dashboard/{rear,front}.png` (no shock/explore exports); reveal after 900 ms (instant under reduced motion). |
| Fløyen-ligaen | ≈L6368 | Standings show "Klatrer · bydel" — `LeagueStanding` has no display name in agil-2's model (Ask of agil-2/agil-1); the four monthly prizes are copy constants. |
| Nivåopprykk | ≈L6124 | `WelcomeMoment` mounts for tier 1 when a gift claim exists; otherwise the gift card. |
| Fjordfiske | ≈L6436 | Water is a gradient card with the boat icon and a bobber (no Bryggen/Sjø SVG); no Agn rail (no bait facet on `agent/suggestions`); prize every 4th catch (`points.keys.fiske_premie_hver_n`), 5 catches/day server cap. |
| Napp-kort | ≈L2115 | Bottom sheet instead of rising from the water (agil-1 owns the water); Legg til / Ikke nå / Aldri dette wired. |
| Ægil | ≈L3523 | Header pose is the state label (no avatar images); voice input, Tweaks sheet, "Alle butikker" picker, onboarding chip steps and the basket bar → `/bergen/kurv` are not built (see `plans/AGIL-3-REMAINING.md`); `intent=photo|door` accepted by the API but the camera flow is not built. |
| Det Ægil vet | ≈L3586 | Per-entry "Fjern" is not available (agil-2's API has forget-all only) — "Stemmer" is local; "Legg til" stores through the onboarding chips; Tillitsregnskap inline (Ark variant deferred). |
| Brett | brett | agil-2's `SuggestionTray` in a `BergenSheet`; count cached for the Hjem card. |

**Notes**
- `lib/screens/bergen/meg/a3_scaffold.dart` and `a3_services.dart` are the shared page frame and the test seam (`A3Services.points/aegil/aegilRepo`, `a3Try`, `a3Pref`) for all agil-3 screens; they live under `meg/` so the diff stays inside the owned folders.
- Backend for this phase (Hare-AdminPanel): `AegilAppController` (`agent/chat`, `agent/me/away`, `agent/photo-order`, `agent/door-note`, `agent/me/trust-ledger`), `FiskeController` (`points/prizes/pick`, `points/me/earn?rule=dagens_napp`), `config/points.php` keys `fiske_premie_hver_n/fiske_maks/fiske_fra_kast`, tests `AegilAppTest`, `FiskeTest`.
**Acceptance**
- [x] `flutter analyze lib/` 0 errors; `flutter test` green; `git diff --name-only agil-1...agil-3 -- lib/` shows only `lib/screens/bergen/{poeng,aegil,meg}/`, `lib/screens/{points,aegil,snurre}/`, `lib/data/{points,aegil}/` and a `pubspec.yaml` append; commit `Phase 7: Meg, Poeng og Ægil-skjermene`.

---

## Phase 8 — Merge readiness and hand-off

- [ ] `AdminI18nDictionaryTest` green after appending EN entries for every agil-3 admin label (append inside `DICT`; no key that exists with a different value).
- [ ] Docs complete: `AGENTOPS_ARCHITECTURE.md`, `AGENTOPS_COURIER_COMMS.md` (legal gate), `GEO_AUDIT.md`, `GEO_GUIDE.md`, `PARTNER_DELIVERY_GUIDE.md`; each ends with a "Deferred to later plans" list (Partner UI, Bud UI, v2 butikkmodus, live model, real providers).
- [ ] Contract §6 steps 1 and 3 run **from this branch**: suites green, `ContractNamesTest` no skips for agil-3, `git diff --name-only agil-1...agil-3` audited against §2, `git merge-tree --write-tree agil-1 agil-3` shows only §2.4 append conflicts. Record the outputs here.
- [ ] Update `plans/AGIL-1-REMAINING.md` §8 with the status of every spec open question (#1–#6 agents, #1–#7 geo, #1–#6 self-delivery) as `BLOCKED — decision` lines, and the four HUMAN items unchanged.
- [ ] Report to the agil-1 plan: "agil-3 merge-ready at `<hash>`". agil-1 executes the merge.

**Acceptance**
- [ ] Commit `Phase 8: merge-ready`. Stop.

---

## Asks of agil-1 (do not do these here)

- Add `PayoutLine::KIND_DELIVERY_INCOME = 'delivery_income'` to `app/Models/Ops/PayoutLine.php` and let `SettlementService` include the kind in partner statements (Phase 4 writes the string through `PdPayoutKinds` until then).
- `OpsCandidateSource::eligible()` must call `PdEligibility` when the class exists (Sync C ships it reading `pd_delivery_actor` directly with a guard, which is acceptable; the class hand-off is cleaner).
- `GET /api/ops/customer/orders` (their Phase 1) is what `bestillinger` reads.
- `CustomerTrackingReadModel::finding_courier` reads `agtp_proposals` where `proposal_type = courier_outreach`, `subject_type = order`, `subject_id = <order id>`, `status ∈ approved|executed` — Phase 6 writes exactly that.

## Blocked / deferred (from the specs' open questions)

- **Agents #1 WhatsApp provider, #2 consent wording (legal)** → Agent B ships in manual mode with `NoneProvider`; auto-outreach stays off.
- **Agents #3 payout rails** → Agent C stops at `exported`.
- **Agents #4 dispatch timing** → T1 measured from `accepted` (policy-changeable).
- **Agents #5 first approval** → policy default `aerend`.
- **Geo #2 geocoder fallback, #3 fee banding (flat 29 kr kept), #6 Sweden payments, #7 retention (30 d default)** → policies, documented.
- **Self-delivery #1 approval (default required), #2 tips (default to store), #3 emergency override (not built — support only), #4 defaults (20 min / 10 min), #5–#6 v2 identity and T&C** → documented; v2 butikkmodus is a separate spec.
- **Partner and Bud app UI, Partner "AI-assistert import", store-courier link removal from app UIs** — out of scope by decision; endpoints ready.
- **Live model (Ollama on the Mac Studio)** — `fake` driver here; one adapter class.
