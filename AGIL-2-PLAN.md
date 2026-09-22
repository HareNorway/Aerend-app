# AGIL-2 — Points v2, Ægil, Agent platform (agent execution plan)

**Branch:** `agil-2` on `Hare-AdminPanel`, `Hare-Store`, `Hare-Driver`, `Aerend-app/Aerend-app`.
**Sister plan:** `AGIL-1-PLAN.md` (branch `agil-1`: Order Ops backbone, Partner & Bud upgrade, Feed). Merging both yields the master plan `8-10-WEEK-IMPLEMENTATION-PLAN.md`.
**Specs (authoritative order):** `aerend-app/docs/AEREND POINTS SPEC v2 .md` → `AEREND AEGIL AGENT SPEC FINAL VERSION.md` → Order Ops §17 (agent layer rules).

---

## 0. Agent operating instructions

**Read before every phase**
- The spec section named in the phase.
- The design file named in the phase. `.dc.html` files are single-file prototypes: map with `grep -n 'data-screen-label=' <file>` and `grep -n '<symbol id=' <file>`, then read the screen block.
  - Customer: `designs/20des/Ærend Kunde Bergen.dc.html` (Meg, Nivå, Premiehylla, liga, oppdrag, Ægil chat, onboarding chips, "Vågen"), `Ægil-chatten - tweaks.dc.html` (chat card types T07–T34), `Ærend Kunde - agentfunksjoner C1-C4.dc.html` (reference only — C1–C4 are backlog), `Ærend Kunde - inventar (steg 1).dc.html`, `Ærend Kunde - leveranser (steg 4).dc.html`.
  - Partner (only for "Tilby en premie"): `designs/20des/Ærend Partner.dc.html`.
  - Shared system rules: `Ærend Bud og Partner - register og system.dc.html` (18 shared components, density, "no streaks/leaderboards as gamification" ethics rule — the league is tier-blind and opt-in by design).
- Brand tokens in code: `Aerend-app/lib/theme/reen_pre_club_theme.dart` (`AerendBergenAuthTokens`), `sc_saas_theme.dart`; mark `assets/Logo/aerend_mark_bergen.svg`.

**Codebase facts**
- Backend: Laravel 8 (`Hare-AdminPanel`). Existing loyalty engine is "Dugnad" (`app/model/PointsLedger`, `DugnadReferral`, tiers/badges/gamification, `Admin/DugnadGamificationController`, `Api/Dugnad*Controller`) — generalize it, do not build a parallel one. Existing LLM agent subsystem is "Snurre" (`Api/SnurreController`, `SnurreConversation/Message`, `docs/SNURRE_STATUS.md`, `docs/AGENT_PLATFORM_AUDIT*.md`) — extend it as the Ægil/agent substrate. Admin is Blade + Vue 2.
- Aerend-app: redux app-wide, bloc in feature modules; no points/Ægil UI exists (net-new under `lib/screens/points/*`, `lib/screens/aegil/*`); networking in `lib/networking/api_constant.dart`. Existing "Snurre" chat screen `lib/screens/snurre/snurre_chat_screen.dart` can be reused as the Ægil chat shell.
- Hare-Store: custom bloc pattern; only `lib/screens/points/*` ("Tilby en premie") is yours.
- Order completion today = `ProductBooking` status update in the Laravel app. Until merge, hook points onto that through an adapter (see §1).

**Commands to run for acceptance**
- Backend: `php artisan test --filter=<Phase>` (tests under `tests/Feature/Points/*`, `tests/Feature/Agent/*`), `php artisan points:rebuild`, `php artisan migrate --pretend`.
- Flutter: `flutter analyze`, `flutter test` (`test/points/*`, `test/aegil/*`), `flutter build apk --debug`.
- Fixture events for cross-branch signals live in `tests/fixtures/events/*.json` and match `docs/EVENT_CONTRACT.md` (owned by agil-1, read-only).

**Conventions**
- Additive migrations only, prefixed `pts_` / `agent_`. Routes `routes/api_points.php`, `routes/api_agent.php`. Controllers `app/Http/Controllers/Points/*`, `Agent/*`. Flutter code only in owned folders (§1). ARB keys prefixed `pts_` / `aegil_`.
- Shared files get one append per need in a commit `chore(shared): register <thing>`.
- Every agent call goes through `AgentInvoker` (deadline → deterministic fallback → code re-validation → `agent_runs` row). Money only by policy key. AI disclosure on first use in every surface.

---

## 1. Ownership & merge contract (identical in both plans)

| Layer | agil-2 owns | agil-1 owns — do not touch |
|---|---|---|
| Backend | `points_ledger`, `points_balances`, `prizes`, `prize_claims`, `point_goals`, `mission_templates`, `missions`, `league_*`, `agents`, `agent_runs`, `agent_settings`, `preferences`, `learned_patterns`, `product_identities`, `reference_prices`, `suggestions`, `suggestion_feedback`, `against_interest_events`, `reminders`, `availability_subscriptions`, `agent_actions`, `trust_ledger`, `shopping_list_items`; Snurre extension | `policies`/`feature_flags` (cherry-picked in), order machines, `order_events`, tokens, time, money, problems, dispatch, feed, `notifications` table |
| Aerend-app | `lib/screens/points/*`, `lib/screens/aegil/*`, `lib/data/points/*`, `lib/data/aegil/*`, Meg section | tracking, feed, delivery code |
| Hare-Store | `lib/screens/points/*` ("Tilby en premie") | everything else |
| Hare-Driver | nothing (substrate is backend-only) | everything |
| Admin | Points (Dashboard, Ledger, Regler, Nivå, Premiehylla, Oppdrag, Liga, Svindel), Agenter | Nå, Unntak, Butikker, Bud, Feed, policy editor UI |

**Sync points**
- **Sync A** (agil-1 Phase 1 → you, at your Phase 1): cherry-pick `sync-A` (`policies`, `PolicyService`, `feature_flags`, status ARB keys, `docs/EVENT_CONTRACT.md`). Never create your own policy table; seed `points.*`/`agent.*` keys via a seeder.
- **Sync B** (your Phase 2 → agil-1): tag `sync-B` with the agent platform substrate. agil-1 cherry-picks it before their Phase 10.

**Cross-branch events** (agil-1 emits): `order.delivered`, `order.cancelled`, `product.price_changed`, `feed.post.published`, `suggestion.reeled`. Consume through adapters: `OrderCompletionSource` (`LegacyBookingSource` now, `OrderEventsSource` at merge) and `SignalSource` (`FixtureSignalSource` now, `WebhookSignalSource` at merge).

**Merge day**: rebase on `main`; merge `agil-1` first, then `agil-2`; migrate on prod snapshot; swap both adapters to live implementations; run both acceptance suites + master Week 10 regression; flip flags in master rollout order.

---

## Phase 1 — Branch setup, ledger, earning rules
**Spec:** Points §Core rules, §Ledger, §Earning rules, §Jobs. **Design:** `Kunde Bergen.dc.html` "Meg" balance strip (data shape only).

Tasks
- [ ] Create `agil-2` on all four repos; `git cherry-pick sync-A`; seed `points.*` keys: `kjop_per_10kr=1`, `dagens_napp=5`, `verving=200`, `verving_referee=200`, `verving_min_order`, `verving_monthly_cap`, `forste_gang=50`, `forste_gang_monthly_cap`, `league_cap_per_order=200`, `expiry_months=12`, `expiry_warning_days=30`, `tier_thresholds=[0,1000,3000,8000]`, `claim_expiry_days=60`, `claim_cancel_hours=24`
- [ ] `OrderCompletionSource` interface + `LegacyBookingSource` (listens to `ProductBooking` completion/cancel) + stub `OrderEventsSource`
- [ ] `points_ledger` append-only (user_id, kind `earn|spend|expire|revoke|adjust`, rule_key, amount, ref_type, ref_id, policy_version, available_at, expires_at, created_at); `points_balances` (available, pending, earned_12m, lifetime); `points:rebuild {user?}`; nightly integrity job; read-compat view over legacy `PointsLedger`
- [ ] Rules: Kjøp (pending earn 1 pt/10 kr on completion → available after return window; revoke on cancel/refund); Verving (code + link, 200/200 on referee's first ≥ threshold delivered order, monthly cap); Første gang (50 on first delivered order in a new category/store, monthly cap); Dagens napp (5/day on `suggestion.reeled` via `SignalSource`); Ægils oppdrag (`mission.completed` → template points)
- [ ] Jobs `points_release`, `points_expire` (12-month FIFO), 30-day warning event `points.expiring`
- [ ] API: `GET /api/points/me`, `GET /api/points/me/ledger`, `POST /api/points/me/referral`

Acceptance tests
- [ ] `LedgerTest`: 149 kr completion → 14 pending; release job → available; cancel → revoke row; balance projection matches ledger after `points:rebuild`
- [ ] `ReferralTest`: pair earns 200/200 once; below-threshold order earns nothing; cap+1 referral earns nothing
- [ ] `ForsteGangTest`: second order in same category same month earns nothing; new category earns 50
- [ ] `ExpiryTest`: 13-month-old earn → expire row; warning fired 30 days before
- [ ] Legacy Dugnad screens still render against the compat view; `php artisan migrate --pretend` shows only additive `pts_` migrations

---

## Phase 2 — Nivå tier engine, agent platform substrate (Sync B), Admin Agenter
**Spec:** Points §Nivå; Order Ops §17.1–17.6, Ægil §15. **Design:** `Kunde Bergen.dc.html` Nivå card (mountain names, progress), admin Agenter list (Order Ops §18.5).

Tasks
- [ ] Tiers Fløyen 0 / Løvstakken 1000 / Rundemanen 3000 / Ulriken 8000 on `earned_12m`; `tier_evaluate` on every earn → immediate promotion, `tier.promoted`; `tier_review` annual job (max one drop, `tier.review_warning` 60 days prior with mission recommendation, `protected_until`) scheduled for launch anniversary; code guard: spend/expire never touch `earned_12m`
- [ ] Substrate (extend Snurre): `agents` (name, autonomy `L0|L1|L2`, scopes json, caps json, enabled); scoped service tokens → `403 AGENT_SCOPE_DENIED`; `actor_type=agent`; `agent_runs` (agent, input_hash, output, validation_result, deadline_hit, fallback_used, cost); `AgentInvoker::run(agent, input, deadline, fallback, validator)`; per-agent/per-hour/per-case caps; kill switch check; untrusted-text sanitiser; money-by-policy-key guard; disclosure copy component (Flutter + Blade)
- [ ] Seed register rows for **all** agents named in both plans: `aegil_customer`, `menu_copy`, `photo_enhance`, `campaign_planner`, `onboarding`, `hours_exceptions`, `bud_translate`, `bud_problem`, `bud_door`, `bud_explain`, `exception_triage`, `comms`, `photo_qa`, `anomaly_explain`, `editorial` (disabled)
- [ ] Admin Agenter v1: register list, runs log with filters, kill switch, cap editing
- [ ] Tag `sync-B` (substrate + seed only; no points code in that commit)

Acceptance tests
- [ ] `TierTest`: crossing 1000 promotes on the same request; spending 900 keeps tier; expiry keeps tier; annual dry-run on seeded users never drops > 1 tier and lists warning recipients
- [ ] `AgentInvokerTest`: out-of-scope token → 403; deadline exceeded → fallback + `deadline_hit=true`; validator rejection → nothing stored, `validation_result=rejected`; kill switch → fallback with no model call; every run writes one `agent_runs` row
- [ ] `git cherry-pick sync-B` onto a fresh `agil-1` checkout applies cleanly and `php artisan test --filter=AgentInvoker` passes there

---

## Phase 3 — Migration, removal of old mechanics, Premiehylla backend
**Spec:** Points §Removal & migration, §Premiehylla, §Claims & fulfilment, §Goal-setting. **Design:** `Kunde Bergen.dc.html` Premiehylla shelf bands, locked previews, claim states.

Tasks
- [ ] Migration job: kroner → points at policy `points.migration_factor`; `adjust` rows with `ref_type=migration`; `earned_12m` seeded from trailing-12-month delivered orders; `--dry-run` produces reconciliation report (users, kroner in, points out, tier distribution)
- [ ] Remove from backend, admin and Aerend-app: Ærend-kroner/cashback, varder/Din sti, Syv fjell, store stamp cards, Bydelsligaen, "Ekte bergenser", "fjell tent", standalone trust-ledger card (savings line moves to monthly summary); drop the compat view once nothing reads it
- [ ] `prizes` (tier_band, type `voucher|physical|donation|identity|partner`, funding `aerend|partner`, point_price, inventory, per_user_cap, fulfilment_type, active); `prize_claims` `claimed→applied|shipped|delivered|used|expired|cancelled`; 60-day expiry; 24h cancel refund; voucher auto-apply at checkout; shipment queue; donation ledger; identity prize (boat) name + name-filter review queue
- [ ] Seed catalogue from the spec table (Fløyen: free delivery 100, sticker pack 150, Forundringspose 250, club donation 500 … Ulriken: boat 2000)
- [ ] `point_goals` (one active, prize or tier)
- [ ] API: `GET /api/points/prizes`, `POST /api/points/prizes/{id}/claim`, `DELETE /api/points/claims/{id}`, `GET /api/points/claims`, `PUT /api/points/goal`

Acceptance tests
- [ ] `MigrationTest`: dry-run reconciles kroner→points within rounding; nobody below Fløyen; report lists tier distribution; second run is idempotent
- [ ] `grep -ri "varder\|syv fjell\|bydelsligaen\|ekte bergenser\|fjell tent"` returns nothing in `Hare-AdminPanel/app`, `resources`, and `Aerend-app/lib`; `flutter analyze` clean
- [ ] `ClaimTest`: claim → spend row, inventory −1, voucher auto-applies on next checkout; cancel at 23h refunds, at 25h refused; unclaimed after 60 days → expired
- [ ] `IdentityPrizeTest`: filtered name → review queue, not rendered; approved → rendered

---

## Phase 4 — Customer points UI, missions v1, welcome gift, Admin Points v1
**Spec:** Points §Premiehylla UI, §Ægils oppdrag, §Welcome gift, §Admin (Dashboard, Ledger, Premiehylla). **Design:** `Kunde Bergen.dc.html` "Meg", Nivå, Premiehylla (blurred previews "Fra Rundemanen · 2400 poeng til", max 3, no padlock), mission card, welcome moment, monthly summary.

Tasks
- [ ] Aerend-app `lib/screens/points/*`: Meg (available/pending, Nivå card with progress, expiry notice); Premiehylla cumulative bands, locked previews per design, claim flow + history, voucher at checkout; goal picker + progress line; monthly summary (incl. migrated savings line)
- [ ] `mission_templates` × `business_goals` (`quiet_hours|new_store|category_growth|pickup_share`), weekly scoring, one active, one decline/week, template wording; `missions_weekly` job; `mission.completed` → points; mission card in app
- [ ] Welcome gift: on `tier.promoted` create zero-cost claim from configured pool (deterministic pick); welcome moment in app
- [ ] Admin Points v1: Dashboard (issuance, liability with editable breakage assumption, redemptions); Ledger (search user/order, `adjust` with reason, rebuild); Premiehylla CRUD, inventory, fulfilment queues (shipment/donation/name review), cost per prize

Acceptance tests
- [ ] Aerend-app widget tests: Fløyen user sees exactly 3 blurred previews with correct "poeng til" gaps; claim button disabled when balance < price; voucher chip appears in checkout after claim
- [ ] `MissionsTest`: job assigns one active mission per eligible user; completion earns template points once; second decline in a week → 422
- [ ] `WelcomeGiftTest`: promotion creates a zero-cost claim automatically; no duplicate on re-evaluation
- [ ] Admin feature test: adjust without reason → 422; with reason → ledger row + audit row; dashboard liability = Σ available × (1 − breakage)

---

## Phase 5 — League, Admin Points complete, partner prize proposals, fraud flags
**Spec:** Points §Fløyen-ligaen, §Admin (Regler, Nivå, Oppdrag, Liga, Svindel), §Partner: Tilby en premie. **Design:** `Kunde Bergen.dc.html` liga screen (top-10, own rank, "Din bydel"); `Ærend Partner.dc.html` prize proposal form.

Tasks
- [ ] League: monthly opt-in, tier-blind, per-order cap `points.league_cap_per_order`; standings top-10 + own rank + "Din bydel"; `league_month_end` (freeze, fraud exclusion, prize assignment, twice-a-year top-3 cap); league screen in app
- [ ] Admin: Regler og satser (every `points.*` key, version history, what-if simulator replaying last 30 days without writes); Nivå (thresholds, population over time, review queue, `protected_until`, welcome pool, dry-run button); Oppdrag (templates, completion rates, kill switch); Liga (standings, exclusions, month-end run)
- [ ] Hare-Store `lib/screens/points/tilby_premie_*`: proposal form (item/experience, quantity, window, price, band) → admin approve + price → partner-funded claims redeem as 0-kr order line with `prize_claim_id` (adapter on existing cart)
- [ ] Svindel og avvik v1: detectors for referral rings, self-referral, velocity anomalies, daily-catch abuse, mission farming, tier gaming → flags only (humans act)

Acceptance tests
- [ ] `LeagueTest`: month-end freezes standings, excludes a flagged account, assigns prizes, refuses a third top-3 prize in a year for the same user
- [ ] `WhatIfTest`: `kjop_per_10kr=2` doubles reported issuance; ledger row count unchanged
- [ ] `PartnerPrizeTest`: proposal → approval → claim → order contains a 0-kr line with `prize_claim_id`
- [ ] `FraudTest`: seeded self-referral raises exactly one flag and changes no balance

---

## Phase 6 — Ægil settings, memory, product identity, onboarding
**Spec:** Ægil §2–4, §20 (privacy). **Design:** `Kunde Bergen.dc.html` Ægil onboarding chip cards + summary, settings; `Ægil-chatten - tweaks.dc.html` disclosure line.

Tasks
- [ ] `agent_settings` (level 0–4, allowed_store_mode, allowed_store_ids, allowed_categories, cap_per_order, cap_per_week, quiet_hours, learning_enabled, paused_until, push_mode, against_interest_enabled, read_aloud); default 2; level 4 → `422 LEVEL_REQUIRES_RECURRING`; level changes audited
- [ ] `preferences` (kind incl. `allergen`/`diet` hard constraints — never inferred; exclusion_product/store; source `stated|onboarding|chat|settings|feedback`); `GET /api/agent/me/memory`, `DELETE /api/agent/me/memory` (`forget_all`)
- [ ] Free-text interpretation via `AgentInvoker(aegil_customer, deadline 5s, fallback → note row)`; validator rejects any inferred allergen/diet
- [ ] `product_identities` (EAN / store_product_id), `reference_prices`; additive `store_products.product_identity_id`
- [ ] Aerend-app `lib/screens/aegil/*`: onboarding chip-card batch flow (`POST /api/agent/me/preferences/batch`, `PATCH /api/agent/me/settings`), skip + 7-day re-invite, guest onboarding after first delivery, summary sentence (model/template), disclosure; settings screen (level explanations, pause, quiet hours, against-interest toggle, read-aloud)

Acceptance tests
- [ ] `PreferencesTest`: stated "nøtter" stored as hard constraint; free text "jeg spiser vel alt uten nøtter" never creates an allergen row (must stay a note unless stated explicitly via chip)
- [ ] `SettingsTest`: level 4 without recurring agreement → 422; `forget_all` leaves zero preference/suggestion/against-interest rows
- [ ] `InterpretTest`: simulated 6s model latency → note row, no structured rows, `deadline_hit=true`
- [ ] Aerend-app widget tests: chip batch posts the expected payload; re-invite hidden inside 7 days

---

## Phase 7 — Signals, matching, suggestion tray, feedback, points↔Ægil hooks
**Spec:** Ægil §5, §7, §12. **Design:** `Kunde Bergen.dc.html` suggestion tray + "Ikke for meg" sheet; "Vågen" daily catch moment.

Tasks
- [ ] `SignalSource` adapters: `FixtureSignalSource` (reads `tests/fixtures/events/*.json` matching `EVENT_CONTRACT.md`) + stub `WebhookSignalSource`; signals: `feed.post.published` (offer/arrival types), `product.price_changed`, scheduler rhythm, rewards threshold, availability
- [ ] Deterministic match: eligibility (hard constraints, allowed stores/categories, age-restricted exclusion) → weighted score `policy.agent.match_weights` → threshold → dedup → daily pool `policy.agent.pool_size=20`; 9 reason codes (`offer_liked_product`, `arrival_fav_store`, …)
- [ ] `suggestions` (`candidate|open|dismissed|never|added|merged|expired`, reason_code, rerank_source); shadow re-rank via `AgentInvoker(aegil_customer)` logging only; served tray = engine top-N (`policy.agent.tray_size=5`)
- [ ] API: `GET /api/agent/me/suggestions`, `POST .../{id}/add|dismiss|never`; no cart writes at level ≤ 2
- [ ] `suggestion_feedback` ("Ikke for meg" + reason codes) → bounded ±30 %, 90-day decay, reflected in `/me/memory`
- [ ] Points hooks: Dagens napp from `suggestion.reeled`; missions worded by `aegil_customer` (fallback template); Ægil-proposed `point_goals`; welcome-gift reason text
- [ ] Aerend-app: tray UI, "Ikke for meg" sheet, "Vågen" daily-catch moment reading `suggestion.reeled` result

Acceptance tests
- [ ] `MatchingTest`: fixture `tilbud` post for a liked product → `open` suggestion with `offer_liked_product`; nut-containing candidate excluded for a nut-allergic user; age-restricted excluded for all
- [ ] `TrayTest`: level 2 tray populated; cart untouched after `add` (tray-only); level 0 receives no proactive suggestions
- [ ] `FeedbackTest`: "Ikke for meg" lowers product weight, visible in `/me/memory`; weight never exceeds ±30 %
- [ ] `RerankShadowTest`: `rerank_source` logged on 100 % of daily runs; served order equals engine top-N

---

## Phase 8 — Against-interest engine, reminders, action log, trust ledger, agent pushes
**Spec:** Ægil §6, §8–9, §12.2, §13, §16. **Design:** `Ægil-chatten - tweaks.dc.html` against-interest card first in turn; `Kunde Bergen.dc.html` "Mens du var borte", trust-ledger card in Meg.

Tasks
- [ ] Checks `cheaper_elsewhere`, `already_have`, `wait_for_offer`, `not_needed`, `threshold_trap`, `store_unreliable` — rule-based, each with line code + alternative action; `against_interest_events` written on every evaluation; lines silenceable per user, logging never
- [ ] `reminders` (wait-for-offer), `availability_subscriptions` ("Si fra når det finnes", 60-day auto-cancel)
- [ ] `agent_actions` ("Mens du var borte", 30-day user view, 12-month audit); `trust_ledger` monthly (saved_kr, finds_applied, against_interest_shown, wait_recommended, cheaper_elsewhere_taken)
- [ ] Agent pushes on `push_category=agent` (append the channel definition to agil-1's `notifications` config in a `chore(shared)` commit): caps `daily=1`, `good_only=3/7d`, quiet hours, 1 item per push, deep links
- [ ] Aerend-app: against-interest line rendered first in chat/cart turn with alternative; reminders card; action log screen; trust-ledger card in Meg

Acceptance tests
- [ ] `AgainstInterestTest`: cheaper identical EAN at an allowed store → `cheaper_elsewhere` event + line first in response; user silences lines → line absent, event still written
- [ ] `RemindersTest`: wait-for-offer reminder fires when offer appears; subscription auto-cancels at day 60
- [ ] `PushCapTest`: second agent push in a day suppressed; push inside quiet hours deferred; deep link resolves
- [ ] `TrustLedgerTest`: monthly roll-up equals counts of underlying events

---

## Phase 9 — Chat content services, communication table, anomaly explain
**Spec:** Ægil §14, §17 (tool allowlist); Points §Ægil communication table; Order Ops §17.7 X2. **Design:** `Ægil-chatten - tweaks.dc.html` card types (T07 shopping list, T08 news card, comparison, tracking snapshot, reminders, against-interest, points explainer, monthly summary).

Tasks
- [ ] Chat services (reuse Snurre chat shell): shopping list (`shopping_list_items`), comparison `POST /api/agent/compare` (allowlisted fields only), tracking snapshot (read model), news card (`GET /feed/posts/{id}` read-only), reminders card, against-interest card, "Hvordan får jeg poeng?" explainer, monthly points summary card
- [ ] Tool allowlist: model may call read tools only; no eligibility/score/merge/charge/hard-constraint tools exposed; requests to act above the user's level answered with the level explanation
- [ ] Communication table: events + templates `points.earned`, `goal.near`, `goal.reached`, `tier.promoted`, `tier.review_warning`, `tier.demoted`, `points.expiring`, `mission.proposed`, `league.month_closed`, monthly summary — routed by surface (in-app card / push / chat)
- [ ] `agent.anomaly_explain` attached to Svindel og avvik flags (explain only, never act)

Acceptance tests
- [ ] `ChatToolsTest`: prompt "legg den i handlekurven" at level 2 → refusal with level copy, no cart write; `compare` response contains only allowlisted fields
- [ ] `CommunicationTest`: each event renders its template on the correct surface exactly once
- [ ] `AnomalyExplainTest`: explanation stored on the flag; zero state changes; `agent_runs` row present

---

## Phase 10 — Security & privacy, metrics, migration cutover, merge
**Spec:** Ægil §20–22, Points §Metrics/Rollout, Order Ops §17.6 guardrails.

Tasks
- [ ] PII-minimisation audit of every agent payload (no raw addresses/phones to the model); age-restricted hard exclusion verified; `audit_log` completeness for Points/Agenter admin actions; agent scope review report (override rate > 30 % flags scope review)
- [ ] Metrics jobs + dashboards: points issuance, liability, redemption, tier distribution, migration reconciliation; Ægil runs, fallback rate, override rate, against-interest "saved kr", tray add/dismiss; alerts
- [ ] Migration cutover: final dry-run sign-off; customer comms (in-app + email) same day; production run; post-run reconciliation; 24h monitoring
- [ ] Merge prep: rebase on `main`; `git diff --stat main..agil-2` touches only owned paths + `chore(shared)`; feature flags `points`, `premiehylla`, `missions`, `league`, `aegil_level_max`; rollback runbook; docs (API, policy keys, agent register)
- [ ] Merge day with agil-1: swap `OrderCompletionSource` → `OrderEventsSource`, `SignalSource` → `WebhookSignalSource`; rerun both suites + master Week 10 regression

Acceptance tests
- [ ] `PrivacyTest`: agent payload snapshot contains no phone/email/street strings; age-restricted item never appears in any tray
- [ ] Production migration reconciles within rounding; monitoring shows zero missing-balance reports in 24h
- [ ] Post-merge integration: real `order.delivered` via `order_events` earns Kjøp points; real store `tilbud` post creates a suggestion; real "Vågen" tap fires Dagens napp
- [ ] Every agent kill switch drilled with fallback observed; every flag toggled off/on cleanly; `git merge agil-2` onto `main` clean after agil-1
