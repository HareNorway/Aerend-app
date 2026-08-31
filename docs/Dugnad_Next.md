# Dugnad v1 Build Plan

**Product source of truth:** `aerend dugnad v1 final spec.md` — organizations, campaigns, donations, referrals, privacy, admin ops, public website.

**Gamification & STØ source of truth:** `aerend-sto-system-spec.md` (v1.0, consolidated). Supersedes all prior gamification specs and **overrides** the STØ/rating/metal/carryover sections of `aerend points engine spec.md` where they conflict. Points ledger mechanics and referral/donation band formulas remain in the points engine spec until migrated.

**Design source of truth (Customer app):** `designs/des8/rend-design-system/project/dugnad/` (canonical Dugnad prototype export). Older `des2/rend-design-system/project/dugnad/` is legacy — prefer des8 for new UI work.

**Design source of truth (Admin panel):** `designs/des8/rend-design-system/project/Admin-Dugnad.html` — interactive prototype loading `admin/*.jsx` (org-first shell, gamification module, seasons, points, finance). Match layout, navigation, and screen structure from this export; zero design drift.

**Delivery strategy (locked):** **AdminPanel first, Customer app second.** All gamification, season, team, points, and config surfaces must be buildable and testable in `Hare-AdminPanel` (with working config APIs) before Flutter STØ screens are implemented. Ops needs to configure and verify seasons, STØ thresholds, carryover, badges, and feature flags in admin before app work depends on them.

This document turns the final product/admin specifications into a stepwise engineering plan for `Hare-Customer`, `Hare-AdminPanel`, and the public campaign website. It should be updated as implementation progresses.

## Progress Legend

- `[x]` Done and verified.
- `[~]` Partially done or in progress.
- `[ ]` Not started.
- `[!]` Blocked by product, ops, payment, or configuration decision.

## Current Progress Snapshot


| Area                                   | Status | Notes                                                                                                                                                                                                                                                           |
| -------------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Vipps login and one-time payment merge | `[x]`  | Production Vipps login and one-time campaign checkout integrated; uses env keys configured for production. |
| Guest browsing                         | `[!]`  | Still called out as remaining config/work from Day 1.                                                                                                                                                                                                           |
| Organization/team model                | `[~]`  | Team model/admin/campaign attachment exists, but final spec requires richer org/team contact, bank, status, and finance fields.                                                                                                                                 |
| Team-owned campaigns                   | `[~]`  | AdminPanel already has sales window start/end, distribution date/location, products, status flow, exports, fundraising goal, team attachment, and public order APIs. Remaining work is Dugnad-specific settlement/payout ledgers and final app parity. |
| Customer localization                  | `[x]`  | New Dugnad Customer placeholder/action strings are localized through Customer `AppLocalizations`.                                                                                                                                                               |
| Donations / Fast støtte                | `[x]`  | Phase 5 shipped (2026-06-17): Vipps recurring setup/confirm/manage, pause/resume, amount change (PATCH → DB on 204), fee preview, points on charge. Dev E2E signed off; Vipps **test app** flaky — production MSN/webhook checklist in `VIPPS_PRODUCTION_SETUP.md`. |
| Points, STØ rating, tiers (Phase 6)    | `[~]`  | **Shipped but superseded by STØ spec v1.0:** current engine uses **lifetime** points for STØ + metal tiers; new spec requires **season** points → rating, form as tempo-only, badge point bonuses, membership points per 100 kr. See **Phase 15**. |
| Leaderboard, supporter card, referrals | `[~]`  | Phase 8 shipped (4 tabs, prize zone, season admin, privacy). **Rebase needed:** rank on STØ rating (not lagpoeng alone); deprecate **Verdi**/markedsverdi tab per STØ §9. Referrals Phase 7 complete. |
| STØ gamification (admin)               | `[~]`  | **Chunks H+A+B+C+D+E+F shipped:** `/admin/dugnad/gamification` + org **Sesong & oppdrag** (club weekly-challenge pool, season goals, metallnavn); progress API + `dugnad:rotate-weekly-challenges` (Mon 00:05). **Open:** Chunk G, rollover job (Chunk I), org **Sesonger** tab (standings + prizes). |
| STØ gamification (Customer app)        | `[~]`  | **`DugnadMissionsScreen`** (Ukens kamper + Sesongmål + form/streak) wired from config + progress APIs. **Still open:** dedicated Form screen, Career, Transfers, supporter card rebuild, leaderboard STØ tab, global config cache at startup. |
| Admin Dugnad shell (des8 parity)       | `[~]`  | Gamification sidebar + module `[x]`. **Org workspace** live (`/sports-club/{id}/workspace`: Oversikt, Lag, Kampanjer, Sesong & oppdrag, Økonomi, Kontakt). Missing: full des8 nav parity, org **Sesonger** tab (standings/prizes), push. |
| Privacy (Phase 9)                      | `[x]`  | `DugnadPrivacyService`, visibility screen (des8 `visibility.jsx` parity), server-side masking. |
| Admin finance and manual payouts       | `[ ]`  | Required for v1, first-class scope.                                                                                                                                                                                                                             |
| Public campaign website                | `[~]`  | `Reen-web-portal` has campaign/club pages, no-login checkout, Stripe/Vipps paths, confirmation polling, referral landing/capture at `/k/{club}?v={ref}`, and optional fundraising-goal progress bars on club campaign cards. Remaining work is final design parity/funnel and post-purchase app funnel. |


## Campaign Fundraising Goal Status

Cross-repo verification as of 2026-06-16.


| Layer                        | Status | What shipped                                                                                                                                                                                                                                                    |
| ---------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Hare-AdminPanel` data + API | `[x]`  | Nullable `fundraising_goal_nok` on `campaigns` (migration `2026_06_11_120000_add_fundraising_goal_nok_to_campaigns`). Model cast + `fundraisingGoalPercent()` (0–100, or `null` when no goal). Admin create/edit form field (optional). Campaign index **Goal** column and dashboard stat card with progress bar when set. |
| `Hare-AdminPanel` APIs       | `[x]`  | `PublicCampaignController` (`/public/campaign/live`, `/public/campaign/{slug}`) and `SportsClubApiController` (`/customer/sports-club/{id}`) return `fundraising_goal_nok`, `total_revenue_nok`, and `goal_percent`. Progress numerator is gross paid campaign revenue (`total_revenue_nok`), refreshed via `CampaignService::refreshCounters()`. |
| `Reen-web-portal`            | `[x]`  | `ClubCampaignSummary` / `Campaign` types and parsers in `lib/api.ts`. Club campaign cards (`components/club/campaign-card.tsx`) show progress bar + raised amount + % of goal only when `fundraising_goal_nok > 0`. Campaign detail page (`campaign-landing.tsx`) uses the same gate. Campaigns without a goal omit the bar. |
| `Hare-Customer` app          | `[ ]`  | Customer campaign cards do not yet show fundraising goal progress; API fields exist on public endpoints but Customer list/detail UI is not wired.                                                                                                                |


### Product rules

- Goal is **optional per campaign** — leave blank in AdminPanel when no target applies.
- Progress = `total_revenue_nok / fundraising_goal_nok`, capped at 100%.
- Public copy shows raised amount and percent of goal; goal amount in NOK is not shown on cards today (only on admin dashboard/list).

### Remaining fundraising-goal gaps

- Customer app campaign cards and detail screens (Phase 4 parity).
- `CustomerCampaignController` active-campaign list does not yet expose `fundraising_goal_nok` / `goal_percent` (public + sports-club APIs do).
- Anchor-card goal bar on Dugnad home (if product wants it separate from club landing cards).

## Referral System Status (Phase 7)

Cross-repo verification as of 2026-06-14.


| Layer                        | Status | What shipped                                                                                                                                                                                                                                                    |
| ---------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Hare-AdminPanel` API + data | `[x]`  | `dugnad_referrals` table, user `dugnad_referral_token`/`dugnad_referral_code`, `ReferralService`, `DugnadReferralController` (`validate`/`capture`/`summary`), payment-webhook conversion, refund reversal, guest-order referral metadata, unit/smoke tests.    |
| `Hare-Customer` app          | `[x]`  | `ReferralShareScreen`, deep-link loader (`aerend://referral`), signup/login capture banner + manual code field, OTP/post-checkout capture, localized copy with `organization_short_name` / `DugnadClubBranding.compactName()`, and `IncomingReferralBanner` on home/profile via `incoming_referral` summary API. |
| `Reen-web-portal`            | `[x]`  | `/[locale]/k/[club]?v=` landing page, referral cookie storage, checkout passes pending referral to public order API.                                                                                                                                            |


### Remaining referral gaps

- Admin referral oversight and fraud-flag UI (Phase 10).
- Config-driven points engine formulas and `config_version` on ledger rows (Phase 6); referral escalation + milestone bonuses now match `aerend points engine spec.md` §7 via env-backed `PointsConfig`.
- Conversion trigger is campaign purchase and first succeeded donation charge (Phase 5 wired in `ReferralService::convertOnDonationCharge`); referral leaderboard Assistkonge remains open.
- Leaderboard Assistkonge tab wired to referral conversions (Phase 8, 2026-06-17).
- Staging E2E verification of link → signup → paid conversion → refund reversal (Phase 14).

## v1 Product Rules

### In Scope

- Customer Dugnad app with auth, guest browsing, dynamic club identity, campaigns, monthly donations, points, STØ rating, metal tiers, leaderboard, referrals, supporter card, gamification, and privacy controls.
- Public campaign website with desktop and mobile web campaign sales, web checkout, Vipps/card payment, and app-design parity.
- Admin panel for Ærend ops: organizations, teams, members, points, campaigns, buyers, CSV export, finance, adjustable distribution, and manual payouts.

### Out Of Scope

- Driver/courier flows and in-app Ærend delivery.
- Social-commerce feed.
- Sponsor shopping and sponsor purchase points.
- Member-discount verification and membership-number onboarding.
- Donation add-on on one-off orders.
- Any payment/auth behavior not explicitly confirmed for the launch environment. Vipps login, one-time payment, and recurring payment remain planned surfaces, but production keys/config must be verified before enabling them publicly.

### Non-Negotiable Domain Rules

- Hierarchy is organization -> team -> user.
- Campaign money belongs to the campaign team.
- Donation money targets a team (Customer v1 UI is team-only; API also supports organization beneficiary for later/admin use).
- Each user has exactly one `points_team_id`; all points aggregate to that team regardless of where the money goes.
- A user can have up to three active monthly donation subscriptions, each targeting a different team (or org via API).
- Public contribution/name display must honor privacy server-side.
- Points formulas live in `aerend points engine spec.md` for ledger/referral/donation mechanics; **STØ rating, metal tiers, form, badges, carryover, and leaderboard ranking** follow `aerend-sto-system-spec.md` where they conflict.
- Public "Samlet inn" means the amount raised/collected for the club over its lifetime (for now). It must be net paid out, not gross sales. UI copy may still say "i år" in places until relabeled; the calculation period is lifetime.

## STØ System Realignment (spec v1.0)

**Authoritative doc:** `aerend-sto-system-spec.md` (consolidated, supersedes prior gamification specs).

**Canonical design:** `designs/des8/rend-design-system/project/dugnad/` — especially `player-card.jsx`, `leaderboard.jsx`, `gamify-form.jsx`, `gamify-cards.jsx`, `offers.jsx`, `donate-abonnement.jsx`, `visibility.jsx`.

**Admin canonical design:** `designs/des8/rend-design-system/project/Admin-Dugnad.html` — especially `admin/screens-gamification.jsx`, `admin/screens-gamification2.jsx`, `admin/screens-org.jsx` (Sesonger tab), `admin/screens-points.jsx`, `admin/screens-global.jsx`, `admin/app.jsx` (sidebar nav).

### Delivery gate: Admin before app

| Gate | AdminPanel must ship first | Then Customer app can | Status |
| ---- | -------------------------- | --------------------- | ------ |
| G1 | Feature flags + config API extension (Chunk H) | Read flags at startup; hide modules when off | `[x]` admin |
| G2 | STØ rating thresholds + tier ranges (Chunk A) + carryover (Chunk B) | Supporter card rating, metal tier, carryover copy | `[x]` admin |
| G3 | Membership points config (Chunk C) + balance-insight | Fast støtte membership framing (`donate-abonnement.jsx`) | `[x]` admin (tab + i18n + charge hook) |
| G4 | Badges admin (Chunk D) + tier aliases (Chunk F) | Badge display, career permanent badges | `[x]` admin + API; app badge/career UI still open |
| G5 | Streaks + season goals + weekly challenges (Chunk E) | Ukens kamper + Sesongmål screens | `[x]` admin + runtime; `[~]` app (`DugnadMissionsScreen`) |
| G6 | Org **Sesonger** tab: seasons CRUD, standings, prizes (des8 `OrgSeasons`) | Season honours, prize banners, rollover ceremony | `[~]` global seasons CRUD only |
| G7 | Leaderboard config rebase (Chunk G) | STØ-rangering tab; remove Verdi | `[ ]` |
| G8 | Rollover job (Chunk I) | Season-end card archive, Ny sesong flow | `[x]` archive + carryover + admin action; transfer ceremony UI partial |

**Rule:** No new Flutter STØ/gamification screen work until the corresponding admin screen saves config and the config API returns it in a staging smoke test.

### Admin panel — screen map (des8 → Hare-AdminPanel)

**Global sidebar** (`admin/app.jsx` `NAV` — target Dugnad mode nav):

| Prototype route | Label | Laravel target | Status |
| --------------- | ----- | -------------- | ------ |
| `orgs` | Organisasjoner | Org-first workspace (`screens-org.jsx`) | `[~]` `/sports-club/{id}/workspace` + `/dugnad/organisasjoner` list; des8 `OrgWorkspace` parity polish + Sesonger tab still open |
| `g-campaigns` | Alle kampanjer | Cross-org campaign list | `[~]` `/admin/campaigns` exists; verify des8 columns/filters |
| `g-invoices` | Fakturaer | `screens-invoices.jsx` | `[~]` `/dugnad/fakturaer` routes exist |
| `g-suppliers` | Leverandører | `screens-suppliers.jsx` | `[~]` `/dugnad/leverandorer` list/create/edit/detail live; supplier detail now shows linked catalog products |
| `g-finance` | Økonomi & utbetalinger | `screens-global.jsx` `GlobalFinance` | `[~]` `/dugnad/okonomi` partial |
| `g-donations` | Donasjoner | Donation subscriptions/charges/settlements | `[x]` `/dugnad/donations/*` |
| `g-points` | Poeng | `screens-points.jsx` — clubs → teams → STØ card | `[~]` `/dugnad/poeng` list; needs team drill-down + rules editor |
| `g-gamification` | **Gamification** | `screens-gamification.jsx` + `screens-gamification2.jsx` | `[x]` `/admin/dugnad/gamification` — seven tabs (incl. Medlemspoeng), des8 layout, NO/EN i18n |
| `g-push` | Push-varsler | `screens-push.jsx` | `[ ]` not built |
| `g-settings` | Innstillinger | `GlobalSettings` in `app.jsx` | `[~]` placeholder `/dugnad/innstillinger` |

**Org workspace tabs** (`OrgWorkspace` in `screens-org.jsx`):

| Tab | Content | Status |
| --- | ------- | ------ |
| Oversikt | KPIs, active campaigns, mini leaderboard | `[~]` KPIs + active campaigns + teams summary in org workspace |
| Lag | Team table → `TeamWorkspace` | `[~]` teams tab + `/sports-club/{id}/team/{team_id}/workspace` |
| Kampanjer | Org-scoped campaigns | `[~]` campaigns tab in org workspace |
| **Sesong & oppdrag** | Club weekly-challenge pool, club season goals, metallnavn; active-season summary | `[x]` editor + inherited global missions read-only banner |
| **Sesonger** | Season list, standings table, **SeasonPrizes** (3 team + 3 individual prizes) | `[~]` global seasons blade only (`/admin/dugnad/seasons`); no org tab, no prizes UI |
| Økonomi | Org finance slice | `[~]` tab shell in workspace; full finance slice open |
| Kontakt & konto | Org contact, bank account | `[x]` contact tab in workspace |

**Gamification module tabs** (`GlobalGamification` — **Phase 15 Part A priority**):

| Tab | Prototype | STØ spec chunk | Status |
| --- | --------- | -------------- | ------ |
| Innstillinger | `GamiSettings` | H | `[x]` Feature flags + config API preview |
| STØ-rating | `GamiRating` | A + D | `[x]` Season-points → rating thresholds, metal tier ranges, cap strategy, badge CRUD |
| Form & Sesongmål | `GamiForm` | E | `[x]` Form rules, decay config, streak thresholds, global weekly pool + rotation slots, season goals + simulator |
| Spesialkort | `GamiCards` | — | `[x]` Card variants, toggles, manual grant log |
| Overgangsvindu | `GamiTransfer` | I (partial) | `[~]` Transfer window + season picker + age-group promotion mappings; activity log reads DB only (no migration seed). `user_team_affiliations` + rollover job still open. |
| Sesong-carryover | `GamiCarryover` | B | `[x]` Rating-% carryover tiers + simulator; API `carryover` key |
| Medlemspoeng | `GamiMembership` (spec) | C | `[x]` Per-100-kr formula, rounding, balance-insight, clawback guard; charge hook; API `membership_points`; NO/EN i18n |

> **Prototype vs spec:** `GamiRating` and `player-card.jsx` comments still show the pre-consolidation model (badge STØ cap, form affects rating). **Implement behaviour per `aerend-sto-system-spec.md`**; keep des8 **layout and admin UX**, not the deprecated formulas.

### What changed vs shipped Phase 6 / 8

| Topic | Shipped today | STØ spec v1.0 |
| ----- | ------------- | ------------- |
| STØ rating source | Lifetime points + breadth + streak (`PointsEngine::stoRating`) | **Season points** → rating 40–99 via configurable thresholds (linear interpolation) |
| Metal tiers | Lifetime points thresholds (0 / 300 / 600 / 1000) | From **rating** ranges (Bronse 40–59 … Platina 90–99); shared config with carryover |
| Form | Not built | Cosmetic tempo only (↑→↓); **does not** affect rating; no form decay |
| Badges | Client preview only (`dugnad_badges.dart`) | One-off **point bonus** on unlock; permanent vs seasonal types; admin CRUD |
| Membership points | Donation band × continuity formula only | Configurable **pts per 100 kr** on successful charge; **no clawback** on cancel/pause/failed charge |
| Leaderboard | 4 tabs incl. **Verdi** (markedsverdi) | Rank on **STØ rating** + season points tiebreak; **no** kroner/markedsverdi framing |
| Season end | Season admin exists; no rollover job | Transactional job: archive → carryover → reset → re-earn |
| Career / transfers | Not built | `Karrieren din`, `user_team_affiliations`, transfer window ceremony |
| Missions | Not built | **Ukens kamper** + **Sesongmål** (challenges over existing actions) |

### Compliance (non-negotiable — STØ §2)

- Points and rating are **never clawed back** on membership cancel, pause, or failed charge.
- Membership points are a **moderate baseline** — activity and purchases must realistically exceed passive billing.
- Leaderboard must not read as "who pays the club the most."
- Admin must **block** any config that would withdraw points/rating on cancel/pause/failed charge.
- Cash-equivalent season prizes tied to purchase-influenced rankings need **legal review** (Lotteritilsynet / Forbrukertilsynet) before launch.

### Deferred (document only — do not build in v1)

- Rating head-start carryover (carrying the rating value itself across seasons).
- Multi-team affiliation (one primary + additional teams).
- Cup quiz (team-vs-team).

### Design screen inventory (des8 — not yet in Flutter)

| Prototype file | Screen(s) | Phase |
| -------------- | --------- | ----- |
| `player-card.jsx` | STØ supporter card, rating breakdown sheet, carryover explainer, season recap share | 15 |
| `gamify-form.jsx` | **Formen din** (`FormScreen`); **Ukens kamper** + **Sesongmål** (`MissionsScreen`) | 15 — `[~]` `DugnadMissionsScreen` partial |
| `gamify-cards.jsx` | **Overgangsvinduet** (`TransferScreen`); **Karrieren din** (`CareerScreen`); special cards | 15 |
| `leaderboard.jsx` | STØ-rangering tab, team average STØ, deprecate markedsverdi | 15 (Chunk G) |
| `offers.jsx` | Profile rows: Sesong-recap, Overgangsvinduet, Karrieren din | 15 |
| `donate-abonnement.jsx` | Membership framing for Fast støtte (points per 100 kr copy) | 15 (Chunk C) + Phase 5 parity |
| `visibility.jsx` | Privacy / visibility | Phase 9 `[x]` |
| `donate.jsx`, `matkasse.jsx`, `customer-screens.jsx`, `auth.jsx`, `club-select.jsx` | Core flows — reference for parity audits | Phases 2–5 |

### Admin build chunks (STØ spec §13 — **build in Hare-AdminPanel first**)

| Chunk | Scope | Admin UI (des8) | Status |
| ----- | ----- | --------------- | ------ |
| **H** | `gamification_features` + app-config API | Gamification → Innstillinger | `[x]` |
| **A** | `sto_rating_thresholds` + `sto_tier_thresholds` | Gamification → STØ-rating (thresholds + tier ranges) | `[x]` |
| **B** | `season_carryover_tiers` + `carryover_settings` | Gamification → Sesong-carryover | `[x]` |
| **D** | Badge extend + `sto_badge_rating_config` + `user_seasonal_badges` | Gamification → STØ-rating (badges section) | `[x]` CRUD, permanent/seasonal, unlock hook |
| **F** | `club_tier_aliases` | Org → Sesong & oppdrag (per-club metal display names) | `[x]` |
| **E** | `form_rules`, `season_goals`, `weekly_challenges`, `streak_thresholds`, `form_decay_config` | Gamification → Form & Sesongmål | `[x]` global pool + rotation + runtime; club pool in org Sesong & oppdrag (rotation stays global) |
| **C** | `membership_points_config` | Gamification → Medlemspoeng | `[x]` |
| **G** | Leaderboard STØ ranking config | Poeng / Gamification cross-check | `[ ]` |
| **I** | `season_card_archive` + rollover job + `user_team_affiliations` | Org Sesonger → end season action; Overgangsvindu (partial) | `[x]` rollover service + `dugnad:rollover-season` + admin button; affiliations + badge evaluator |

**Suggested AdminPanel build order:** H → A+B → D+F → E+C → org Sesonger tab (prizes + standings) → G → I → config API smoke tests → **then** Customer app (Phase 15 Part B).

**Progress (2026-07-07):** H, A, B, C, D, E, F done. Spesialkort + Overgangsvindu (partial I) done. Org workspace **Sesong & oppdrag** ships club missions + metallnavn. Customer **`DugnadMissionsScreen`** reads config + progress APIs. **Next:** org **Sesonger** tab (standings + prizes), Chunk G, rollover job (I), season-points engine hooks, remaining Flutter STØ screens.
## Phase 0 - Scope Lock And Technical Baseline

Goal: stop drift from older sponsor/courier plans and make the final spec executable.

### Tasks

- `[x]` Replace older sponsor/discount/courier plan with this final-spec plan.
- `[~]` Keep only unresolved decisions in the open-decision table at the bottom of this document.
- `[x]` Confirm v1 admin scope: Ærend-internal first, no club admin login required for launch.
- `[ ]` Confirm pilot organization(s), especially Sædalen IL and Fana Fotball sample data.
- `[x]` Confirm no new fulfilment scope is needed for now; keep the current campaign completion flow and final-spec CSV export path.
- `[ ]` Confirm production payment readiness: Vipps one-time, Vipps recurring, card provider, webhook URLs, and callback URLs.
- `[x]` Confirm SMTP and OTP providers should be reused.
- `[x]` Confirm app account creation requires phone verification.
- `[x]` Confirm public website has no login; buyers enter contact/order information directly at checkout.
- `[x]` Confirm season cadence (finalized): AdminPanel owns the season lifecycle — set start/end dates, start/end/manage the active season, view season history, and configure prize (and related season settings) without code changes. No fixed calendar cadence is baked into app code.
- `[x]` Confirm prize is in scope and admin-configurable per active season (see season cadence decision above).
- `[x]` Confirm `Samlet inn` period: lifetime for now.

### Acceptance Criteria

- Team agrees this document is the active implementation checklist.
- No implementation ticket references sponsor shopping, courier delivery, or membership-number flows as v1 requirements.
- Open decisions are tracked with owner, deadline, and current default.

## Season Cadence (Finalized)

**Decision:** Season timing and prizes are **admin-driven**, not hard-coded in Customer app or backend cron.


| Requirement                                      | Owner         | Notes                                                                                                           |
| ------------------------------------------------ | ------------- | --------------------------------------------------------------------------------------------------------------- |
| Set season **start** and **end** dates           | AdminPanel    | Per organization (or global policy — implement as one admin model; no fixed annual/quarterly calendar in code). |
| **Start**, **end**, and **manage** active season | AdminPanel    | Ops controls when a season is live; points/leaderboard season scope follows the active window.                  |
| **Season history**                               | AdminPanel    | List/archive past seasons with dates, status, and prize configuration snapshot.                                 |
| **Configure prize**                              | AdminPanel    | Prize value, description, and any launch-required prize metadata for the active/upcoming season.                |
| Season points scope                              | Backend + app | `season_points` and leaderboard Tabell rank teams within the active season window; lifetime points unchanged.   |
| Season-end card / honours                        | Customer app  | Derived from ledger + season record; share-only, no redemption (see Phase 13).                                  |


**Out of scope for cadence decision:** automatic season rollover jobs (optional later); club-admin self-service (Ærend-internal admin only for v1).

## Phase 1 - Data Model Foundation

Goal: create the durable backend foundation for organizations, teams, users, campaigns, money, and points.

### Backend Tasks

- `[~]` Normalize organizations as the dynamic club source.
  - Required fields: `name`, `short_name`, `location`, `logo_url`, `org_number`, `contact_name`, `contact_phone`, `contact_email`, encrypted `bank_account`, `status`.
  - `short_name` must be explicit, not derived from `name`.
- `[~]` Expand teams under organizations.
  - Required fields: `organization_id`, `name`, `logo_url`, `contact_name`, `contact_phone`, `contact_email`, encrypted `bank_account`, `status`, sort/display fields.
  - Team dashboard stats must be derivable: members, active subscribers, active campaigns, season points, net raised, pending payout.
- `[~]` Extend users for Dugnad.
  - Required fields: auth provider, verified phone, `points_team_id`, referral attribution, display-name preference, nickname, visibility flag.
  - Referral credentials (`dugnad_referral_token`, `dugnad_referral_code`) and pending/converted rows in `dugnad_referrals` are live; privacy/display-name fields remain open.
- `[x]` Add subscription tables (Phase 5 slice).
  - `dugnad_subscriptions`, `dugnad_subscription_charges`, `dugnad_settlements` migrations + Eloquent models live in AdminPanel.
  - Vipps agreement id/status, streak months, `next_charge_at`, pending amount/target fields, and per-charge fee split columns implemented.
- `[~]` Add `points_ledger`.
  - Table and referral/campaign/donation-charge ledger writes exist; config version, reversal link column, and full engine-spec coverage remain Phase 6 work.
- `[x]` Add `referrals` (`dugnad_referrals`).
  - Stores referrer, referred user, organization, referral code/token, capture source, status, converted/reversed timestamps, sequence number, and converted source linkage.
  - Admin fraud-flag UI and explicit fraud status column remain future work (Phase 10).
- `[ ]` Add effective-dated `distribution_config`.
  - Supports global, organization, and campaign splits plus donation fee rules.
- `[ ]` Add settlement and payout ledgers.
  - Donation `dugnad_settlements` rows (`pending_paid`) exist per succeeded charge; full campaign/subscription payout ledger and manual payout workflow remain Phase 11.
- `[ ]` Add season tables and admin season model.
  - Season records: `start_date`, `end_date`, `status` (draft/active/ended), organization scope, configurable **prize** fields, and metadata needed for history display.
  - `team_seasons` / season snapshot data for leaderboard honours and season-end card.
  - Admin can create/edit season windows, end the active season, list **season history**, and configure prize without deploys.

### Admin Tasks

- `[~]` Update organization and team CRUD to include all final-spec fields.
- `[ ]` Add encrypted bank-account handling and role-restricted display.
- `[ ]` Add audit logging for org/team/contact/bank/status changes.

### Acceptance Criteria

- A new organization and multiple teams can be created from AdminPanel.
- Customer app can render club name, short name, location, and logo without hardcoding.
- Bank account values are encrypted/restricted and never exposed to Customer APIs.
- Points, settlement, and payout ledgers exist before feature code relies on aggregate counters.

## Phase 2 - Auth, Guest Browsing, Phone Verification, And Club/Team Choice

Goal: make the app App Store-safe and ready for supporter actions.

### Customer App Tasks

- `[ ]` Add guest entry that allows browsing campaigns and leaderboard without login.
- `[~]` Keep Vipps login as a primary option, behind a developer/config toggle until production keys are ready.
- `[ ]` Ensure Google and Apple are primary auth options.
- `[ ]` Keep email as a fallback, not the primary Dugnad path.
- `[ ]` Implement register = login for all supported auth providers.
- `[ ]` Add compulsory phone verification during app account creation.
  - Vipps users can skip if provider returns verified phone.
  - Google/Apple/email users verify a phone by OTP.
- `[ ]` Add club picker during onboarding.
- `[ ]` Add points-team selection with exactly one selected team.
- `[ ]` Remove membership-number prompts from v1 onboarding.
- `[ ]` Gate only account actions: buy, donate, refer, earn points, manage profile, choose/change points team.

### Backend/API Tasks

- `[ ]` Provide guest-safe bootstrap endpoint for public club/campaign/leaderboard data.
- `[ ]` Add or adapt social login/register endpoints.
- `[ ]` Add OTP send/verify endpoints or reuse existing platform endpoints.
- `[ ]` Add endpoints for organization list/detail, team list, and points-team selection.
- `[ ]` Enforce points-team presence before earning points.

### Acceptance Criteria

- Guest can view campaign list/detail and leaderboard.
- Guest is prompted to login only when starting buy/donate/refer/profile actions.
- New Google/Apple/email user must verify phone before account creation is complete.
- User has exactly one active points team.
- No v1 screen asks for a membership number.

## Phase 3 - Dynamic Club Identity

Goal: ensure every visual and text surface is driven by the selected organization.

**Status (2026-06-14):** Shipped. API returns `short_name` on club list/detail and leaderboard. Customer app persists `clubShortName` in `DugnadState`, exposes `DugnadClubBranding` helpers, and re-renders on club switch via `revision` listeners. `ClubCrest` uses `BoxFit.contain`. Admin sports-club form includes **Short name (Dugnad)** (`club_short_name`). Existing `AppLocalizations` strings (`dugnadYouSupport`, `dugnadReferFriendsToClub`, `dugnadDonationTeamInClub`, referral share copy, etc.) were already parameterized — Phase 3 only wires `fullName()` / `compactName()` into those call sites; no new ARB keys.

### Tasks

- `[x]` Replace hardcoded club references with organization fields.
- `[x]` Use `name` for full labels such as "DU STOTTER {name}".
- `[x]` Use `short_name` for compact/tier/referral copy such as "{prefix}-helt" and "Verv venner til {prefix}".
- `[x]` Render `logo_url` with contain/fallback on anchor cards, supporter card, campaign/team headers, and leaderboard.
- `[x]` Ensure club switch re-renders name, logo, location, tier names, referral copy, and leaderboard title.
- `[x]` Add sample/test clubs with long names to verify layouts (set full store name + explicit `club_short_name` in AdminPanel; e.g. pilot Fana / Sædalen).

### Acceptance Criteria

- App can switch between two organizations without code changes.
- No visible copy incorrectly says Fana when Sædalen is selected, or vice versa.
- Long organization names and logos render without overflow.
- Tier/referral text uses `short_name`, not string-splitting from `name`.

## Phase 4 - Campaigns / Matkasser

Goal: make team-owned campaign sales work in app and backend.

### Backend/API Tasks

- `[~]` Attach every campaign to a team.
- `[x]` AdminPanel validates the selected campaign team belongs to the selected sports club, so campaign team implies organization through that relation.
- `[x]` Campaign lifecycle/status fields exist as draft, active, closed, fulfilled.
- `[x]` Sales window start/end fields exist in AdminPanel as `sales_window_start` and `sales_window_end`.
- `[x]` Keep the current campaign completion/distribution flow; do not add a new fulfilment subsystem for v1.
- `[~]` Campaign product records, product admin, price, stock/sold-out controls, image galleries, and store sync exist; verify supplier-cost/final settlement inputs before finance work.
- `[~]` Campaign dashboard computes gross, Jens Eide cost, club share, and Reen margin; remaining work is durable settlement/payout-ledger generation and final configurable split policy.
- `[~]` Admin campaign index supports club/team filters and public APIs include team payloads; verify Customer API filters cover final Dugnad app needs.
- `[x]` Optional per-campaign fundraising goal in NOK (`fundraising_goal_nok`); admin form, index Goal column, dashboard progress, and public/club API `goal_percent` for web progress bars.
- `[~]` Include team name/logo in list, detail, checkout, and order responses.
- `[x]` Public campaign order API blocks orders outside the sales window and auto-closes stale active campaigns.
- `[ ]` On settled purchase, write order records, settlement source data, and points ledger event.
- `[ ]` Reverse points and settlement impact on refund.
- `[~]` Keep Vipps one-time checkout behind config until production keys are ready.
- `[x]` Card payment path exists through Stripe for public campaign checkout.

### Customer App Tasks

- `[~]` Show campaign cards with club/team identity.
- `[ ]` Show optional fundraising goal progress on campaign cards when `fundraising_goal_nok` is set (web portal shipped; Customer app not wired).
- `[ ]` Add honest countdown/hourglass tied to real deadline.
- `[ ]` Intensify countdown in the final 24 hours.
- `[ ]` Show "Stengt" state for expired campaigns.
- `[~]` Show team name/logo through detail, checkout, and success screens.
- `[ ]` Show supplier/product/price information cleanly.
- `[ ]` Keep checkout/completion copy aligned with the current campaign flow and avoid Ærend courier assumptions.
- `[ ]` On successful purchase, show full confetti, haptics, and shareable support card.

### Acceptance Criteria

- Team-owned campaign can be browsed as guest.
- Logged-in user can buy a campaign product through enabled payment method.
- Expired campaign cannot be purchased.
- Order and settlement are attributed to the correct campaign team.
- Campaign purchase creates a points ledger entry according to the points-engine config.
- Refund reverses points and financial contribution.
- UI never suggests Ærend courier delivery in v1.

## Phase 5 - Donations / Fast Støtte

Goal: build monthly giving to teams or organization with transparent fees and continuity points.

**Status (2026-06-17):** **Complete** for v1 scope. AdminPanel: `VippsRecurringService`, `DonationSubscriptionService` (create, sync, update, cancel, pause, resume, abandon, charge job), customer APIs, donation webhook, points + referral conversion hooks, admin blades. Customer app: setup (`DonationSetupScreen`), confirm/incomplete/failed deep-link paths, manage (`DonationManageScreen` — prototype layout, Change/Pause/Exit), `aerend://donation/vipps`, fee + points preview, `/donation/enabled` gating. **Ops:** production MSN/webhooks documented in `Hare-AdminPanel/docs/VIPPS_PRODUCTION_SETUP.md`. **Verification:** dev agreement + cancel + amount PATCH tested; full charge-capture E2E deferred — Vipps test app unstable at time of sign-off. Card/Stripe subscriptions remain out of scope.

### Fast støtte implementation notes (dev)


| Item                   | Status | Notes                                                                                                                               |
| ---------------------- | ------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| Feature gate           | `[x]`  | `DUGNAD_DONATIONS_ENABLED` + `DugnadFeatureFlags.donationsEnabled`; `/donation/enabled` polled on setup screen.                     |
| Recipient picker       | `[x]`  | Customer v1 is **team-only** (no whole-club option in app); backend still supports `organization` beneficiary for future/admin use. |
| Vipps agreement create | `[x]`  | Works on dev MSN when Recurring API active; `merchantAgreementUrl` must be HTTPS (`DUGNAD_DONATION_AGREEMENT_URL`).                 |
| Manage support UI      | `[x]`  | `DonationManageScreen` — purple hero + lavender feed (`DugnadLbScrollBody`), summary card, tier badges, Change/Pause/Exit, dashed add-team card. |
| Amount change          | `[x]`  | `PATCH /subscriptions/{id}` → Vipps `updateAgreementAmount`; DB `amount_ore` updated only after **204** (sync) or **202** + poll.      |
| Pending setup hygiene  | `[x]`  | Pending subs excluded from manage list + 3-team cap; `abandon` + stale pending cleanup (>1 h).                                      |
| Error visibility       | `[x]`  | Full Vipps body logged in `storage/logs/laravel-*.log`; `debug_detail` returned to app when `APP_DEBUG=true`.                       |
| PHPUnit                | `[x]`  | `DonationFeeServiceTest`, `PointsEngineTest::test_donation_points_formula_matches_spec_defaults`.                                   |


**Vipps portal checklist (ops):** MSN **1091843** on production (`https://api.vipps.no`) — see `Hare-AdminPanel/docs/VIPPS_PRODUCTION_SETUP.md`. Register webhooks via `php artisan vipps:register-webhooks` → `POST /api/webhook/campaign/vipps` (ePayment) and `POST /api/webhook/donation/vipps` (Recurring). Login redirect: `https://api.ailogistics.no/vipps/login/callback` on MSN **1101321** (Login product). Allowlist `aerend://donation/vipps`, `aerend://payment`, and `https://aerend.com/.../confirmation` return URLs.

#### Fast støtte points formula (monthly charge)

**Authoritative source:** `aerend points engine spec.md` §3.2 + §6. Implemented in `PointsEngine::donationPointsForAmountKr` (backend) and `DonationFeeCalculator` (Customer setup preview).

**Award trigger:** points ledger row on each **succeeded** subscription charge (`PointsService::awardDonationChargePoints`), credited to the user's `points_team_id`.

**Formula:**

```
monthly_points = round( base_band(amount_kr) × continuity_multiplier(streak_months) )
```

**Amount bands (base points per month)** — env overrides in parentheses:

| Monthly amount (kr) | Base points | Env key |
| ------------------- | ----------- | ------- |
| 10–99 | 10 | `DUGNAD_DONATION_POINTS_BAND_0` |
| 100–199 | 20 | `DUGNAD_DONATION_POINTS_BAND_100` |
| 200+ | 35 | `DUGNAD_DONATION_POINTS_BAND_200` |

**Continuity multiplier** (unbroken months on the subscription, `current_streak_months` at charge time):

| Streak months | Multiplier | Env key |
| ------------- | ---------- | ------- |
| 0–2 | 1.0 | — |
| 3–5 | 1.25 | `DUGNAD_DONATION_CONTINUITY_MULT_3` |
| 6–11 | 1.5 | `DUGNAD_DONATION_CONTINUITY_MULT_6` |
| 12+ | 2.0 | `DUGNAD_DONATION_CONTINUITY_MULT_12` |

**Worked examples** (spec defaults, `PointsEngineTest`):

| Amount | Streak | Calculation | Points |
| ------ | ------ | ----------- | ------ |
| 50 kr | 1 mo | 10 × 1.0 | **10** |
| 100 kr | 1 mo | 20 × 1.0 | **20** |
| 150 kr | 7 mo | 20 × 1.5 | **30** |
| 250 kr | 12 mo | 35 × 2.0 | **70** |

**Streak / grace (§6.1):** failed charge sets `streak_at_risk_since`; if not recovered within **14 days** (`DUGNAD_DONATION_GRACE_PERIOD_DAYS`), streak resets to 0. Cancel/pause breaks streak per `DonationSubscriptionService`. Setup-screen preview uses month-1 multiplier (1.0) — actual awards use live streak at capture.

**UI note:** kr-band badges on donation cards are **amount-tier styling** for manage/setup only. **Phase 15:** align copy with `donate-abonnement.jsx` (membership points per 100 kr, no clawback messaging). Metal tiers on supporter card follow **rating** per STØ spec, not donation amount bands.

#### STØ membership points (Phase 15 Chunk C — shipped 2026-07-06)

**Source:** `aerend-sto-system-spec.md` §8. Points = `(charged_amount_kr / 100) × points_per_100_kr` on each **successful** charge only. Admin: Gamification → **Medlemspoeng** tab (NO/EN via `dugnad-i18n.js`). API: `membership_points` in `GET /api/customer/dugnad/config`. Award hooks `PointsService::donationChargePointsForAmountKr` on Vipps recurring charge success. **No clawback** on cancel/pause/failed charge. Enable module flag **Medlemspoeng** under Innstillinger + config row enabled.

### Backend/API Tasks

- `[x]` Implement Vipps recurring agreements from scratch.
- `[ ]` Add card subscription support if confirmed for v1 (deferred — Vipps recurring only for v1).
- `[x]` Enforce maximum three active subscriptions per user.
- `[x]` Enforce unique donation target per active subscription.
- `[x]` Support team and organization targets.
  - API supports both; Customer app ships team-only recipient selection for v1.
- `[x]` Store transaction fee, platform/drift fee, VAT treatment, net amount, and payout target per charge.
- `[x]` Failed charge is skipped and never retro-charged.
- `[x]` Cancel stops future charges; paid amounts remain non-refundable unless ops manually refunds.
- `[x]` Amount/target changes apply from next charge.
- `[x]` Each successful charge creates subscription charge, settlement, payout-pending entry, and points ledger event.
- `[x]` Continuity multiplier resets on cancel according to points-engine spec.

### Customer App Tasks

- `[x]` Add Fast støtte landing/setup screen.
- `[x]` Allow donation to selected team or whole organization.
  - Team picker shipped; whole-club option removed from Customer UI per product direction.
- `[x]` Add amount chips and custom amount.
- `[x]` Show fee breakdown at setup, confirmation, and manage screens.
- `[x]` Show current active subscriptions and next charge dates.
- `[x]` Add cancel/change amount/change target flows.
  - Manage screen: Change → `DonationSetupScreen(editing)`, Pause/Resume, Exit (cancel sheet). Amount: Vipps PATCH then DB. Beneficiary: pending fields apply from next charge.
- `[ ]` Add donation success confetti, haptics, and share card.

### Admin Tasks

- `[x]` Add donation fee configuration (env-driven + admin blades).
- `[~]` Make real platform fee, transaction fee, and VAT-related settings editable in AdminPanel (env + minimal admin views; full editable config table deferred).
- `[x]` Add subscription and charge overview.
- `[ ]` Add failed/cancelled charge filters.
- `[x]` Add donation settlement/payout view.

### Ops / verification

- `[x]` Activate Vipps Recurring API on production MSN — documented in `VIPPS_PRODUCTION_SETUP.md`; dev MSN tested when Vipps test app stable.
- `[x]` Register webhooks on production MSN 1091843 — `php artisan vipps:register-webhooks` + secrets in `.env` (see `VIPPS_PRODUCTION_SETUP.md`).
- `[x]` Dev E2E: create subscription → Vipps approve → deep link sync → manage screen → cancel / amount PATCH.
  - First **charge capture → webhook → points ledger** row not re-verified (Vipps test app buggy Jun 2026); logic wired in `DonationSubscriptionService::processDueCharges` + `DonationWebhookController`.

### Acceptance Criteria

- User can create, view, update, and cancel monthly support.
- User cannot exceed three active donation subscriptions.
- User cannot create two active subscriptions to the same target.
- Fee split is visible before payment confirmation.
- Successful charge contributes money to its donation target and points to the user's `points_team_id`.
- Failed charge does not create debt.

## Phase 6 - Points Engine, STØ Rating, Tiers, And Ledger

Goal: make all gamification auditable, reversible, and config-driven.

**Status (2026-06-16):** Ledger, summary APIs, reversals, and Customer progression UI shipped. **STØ model realignment required** — see **Phase 15** and `aerend-sto-system-spec.md`. Current `PointsEngine::stoRating` and lifetime-based metal tiers are **deprecated** for STØ display/ranking; keep ledger mechanics until migration.

### Backend Tasks

- `[x]` Implement config-driven points awards from the engine spec (env-backed `PointsConfig` + `PointsEngine`; version stamped on ledger rows).
- `[x]` Support three v1 pillars only: campaign purchase, monthly donation, referral conversion.
- `[x]` Maintain lifetime points and season points.
- `[~]` Derive STØ rating — **shipped (legacy):** lifetime + breadth + streak. **Target (STØ spec):** season points → rating via `sto_rating_thresholds` (Phase 15 Chunk A).

#### STØ rating (supporter card number) — LEGACY (pre–STØ spec v1.0)

> **Superseded by** `aerend-sto-system-spec.md` §5. Do not extend this formula; migrate to season-points-based rating in Phase 15.

**Was:** `aerend points engine spec.md` §9 + `PointsEngine::stoRating`.

**Range:** `40–99` (clamp after rounding).

**Legacy formula** (`PointsEngine::stoRating`):

```
sto_rating = clamp( round(base_curve(lifetime_points)) + breadth_bonus + streak_bonus , 40, 99 )
```

**Legacy base curve (§9.1)** — linear interpolation between breakpoints, cap at top:

| lifetime_points | base rating |
| --------------- | ----------- |
| 0 | 40 |
| 250 | 68 |
| 500 | 76 |
| 800 | 82 |
| 1 200 | 86 |
| 2 000 | 90 |
| 3 500 | 94 |
| 6 000+ | 97 |

**Legacy bonuses (§9.2):**

| Bonus | Rule |
| ----- | ---- |
| **Breadth** | +1 if active in **2** pillars; +4 if active in **all 3** (campaign purchase, monthly donation, referral). “Active” = ≥1 non-reversed award in that pillar. |
| **Streak** | +1 at **6** unbroken donation months; +2 at **12** months. |

**Target (STØ spec §5.1 seed):** season points 0→40, 500→60, 1500→75, 3000→90, 5000+→99; metal from rating ranges 40–59 / 60–74 / 75–89 / 90–99.

**Card label under the number:** `STØ` / `SUP` by default; `KAP` / `CAP` when the user has a points team selected (UI only).

**Card background gradient:** follows current metal tier — same `PointsMetalTheme.pointsCardDecoration` as the Dine poeng hero card.

- `[~]` Implement four metal tiers — **shipped (legacy):** lifetime 0/300/600/1000. **Target:** rating-derived tiers + `club_tier_aliases` (Phase 15 Chunks A, F).
- `[x]` Render tier names from organization prefix (`{prefix}-supporter/helt/legende/ikon`).
- `[x]` Add point reversal mechanics for refund/cancel/reversed referral conversion.
- `[x]` Store points config version on every ledger row.
- `[x]` Add points summary endpoint (`POST /api/customer/points/summary`).
- `[x]` Add points ledger endpoint (`POST /api/customer/points/ledger`).

### Customer App Tasks

- `[x]` Add progression banner from current points to next tier (`PointsProgressionSection` on Dugnad home).
- `[x]` Add four metal level cards.
- `[x]` Add points history/recent activity (`PointsHistoryScreen`).
  - Human-readable titles + subtitles for referral conversion (sequence), milestone bonuses, and reversals via ledger `meta` + `points_ledger_display.dart` (2026-06-17).
- `[x]` Color banner/cards by current metal.
- `[~]` Remove donation kr-band metal tiers from setup; show markedsverdi via points preview — **deprecate markedsverdi framing** per STØ §9 when Phase 15 lands.

### Acceptance Criteria

- Every point shown in app/admin can be traced to a `points_ledger` row.
- Lifetime points never reset.
- Season points reset by season without losing lifetime tier.
- Tier meaning is consistent across card, progression, and level cards.
- Donation magnitude is shown through points, not public kroner tiers. *(Markedsverdi as public ranking metric is deprecated — STØ §9.)*

### Remaining Phase 6 gaps

- **Phase 15 Part A:** Admin gamification + STØ config — **Chunks H, A, B, C, D, E, F + seven-tab shell shipped (2026-07-07).** Remaining: G, rollover (I), `stoRatingFromSeasonPoints()` engine hook, org **Sesonger** tab.
- **Phase 15 Part B:** Customer realignment after admin gates.
- Admin editable points/tier/referral config UI (still env-driven; Phase 10 + Phase 15 chunks).
- Donation charge refund → points reversal when ops refund path is used.
- Campaign purchase points default env value is 50 (`DUGNAD_CAMPAIGN_PURCHASE_POINTS`); donation bands + continuity multipliers aligned to spec 2026-06-17.

## Phase 7 - Referrals / Verving

Goal: add growth loops with anti-fraud and first-paid-action conversion.

### Backend/API Tasks

- `[x]` Generate referral links: `{landing}/k/{club}?v={ref}` via `ReferralService` (`DUGNAD_REFERRAL_LINK_BASE` or `LANDING_PAGE_BASE_URL`).
- `[x]` Add manual referral code validation (`GET/POST /api/customer/referral/validate`).
- `[x]` Capture referral attribution at signup as pending (`POST /api/customer/referral/capture` after phone verification).
- `[x]` Lock one referrer per referred user (unique `referred_user_id` on `dugnad_referrals`).
- `[x]` Convert referral on referred user's first settled paid action.
  - Campaign purchase conversion is wired through payment webhooks/reconciler and login/OTP reconciliation paths; first succeeded donation charge via `ReferralService::convertOnDonationCharge`.
- `[x]` Award escalating points and milestone bonuses from the engine spec.
  - §7 formula (`base + increment × (min(n,cap)−1)`) in `PointsEngine`; milestone ledger rows (`referral_milestone`) at counts 3/5/10 via `PointsService::syncReferralMilestoneBonuses`; env defaults match spec (50/15/10 and 100/250/600).
- `[x]` Prevent self-referral.
- `[x]` Dedupe by verified phone.
- `[x]` Cap escalation per referrer (`DUGNAD_REFERRAL_CAP_PER_REFERRER`).
- `[x]` Reverse conversion on refund of the converting action (`reverseOnRefund` on campaign refund paths).

### Customer App Tasks

- `[x]` Add referral screen with share link, reward explanation, and progress (`ReferralShareScreen` from Dugnad home).
- `[x]` Manual referral code entry on signup/login (`ReferralManualCodeField`); organic vs link tabs on auth screens.
- `[x]` Show "Vervet av X" after capture.
  - `ReferralCaptureBanner` during signup/login; `IncomingReferralBanner` on Dugnad home and profile from summary API `incoming_referral`.
- `[x]` Add referral states in signup: link captured, manual code valid, invalid code, self-code error, organic signup.
- `[x]` Add shareable referral message using organization `short_name`.
  - `ReferralShareScreen` prefers `organization_short_name` from summary API, else `DugnadClubBranding.compactName()`.

### Admin Tasks

- `[ ]` Referral oversight list, conversion drilldown, and fraud flags (Phase 10).

### Website Tasks

- `[x]` Public referral landing at `Reen-web-portal` `/[locale]/k/[club]?v=` with app deep-link and store fallbacks.
- `[x]` Persist pending referral in cookie and attach to guest checkout order payload.
- `[x]` Guest web orders store `pending_referral_`* fields for post-signup conversion.

### Acceptance Criteria

- `[x]` Referral can be captured from link or manual code.
- `[x]` Referral does not award points until first settled paid action (campaign purchase path).
- `[x]` One referred user cannot credit multiple referrers.
- `[x]` Self-referral and duplicate-phone abuse are blocked.
- `[x]` Refund of converting action reverses referral points (reversal ledger row + `reversed` status).
- `[ ]` Staging E2E sign-off for full link → signup → purchase → points → refund loop.

## Phase 8 - Leaderboard, Team Detail, And Supporter Card

Goal: ship the football-style competitive experience.

**Status (2026-06-17):** Core slice shipped. **STØ leaderboard rebase pending** (Phase 15 Chunk G). **Verdi tab deprecated** per `aerend-sto-system-spec.md` §9. Prize zone = top 3 (configurable via `dugnad_seasons.prize_zone_size`, default 3). Admin **Dugnad seasons** under Providers sidemenu (`/admin/dugnad/seasons`).

### Backend/API Tasks

- `[x]` Organization leaderboard with four tabs (single club payload + scorers endpoint):
  - Tabell: `GET /sports-club/{id}/leaderboard` — team season lagpoeng.
  - Toppscorer: `GET .../leaderboard/scorers?tab=toppscorer` — campaign purchase count (`points_ledger` goals).
  - Assistkonge: `?tab=assistkonge` — referral conversion count.
  - Verdi: `?tab=verdi` — donation markedsverdi (**deprecated** — remove/hide when Phase 15 Chunk G ships).
- `[ ]` **STØ-rangering** tab: rank users by STØ rating + season points tiebreak; subtitle "Hvem har høyest STØ denne sesongen"; no kroner values (design: `des8/leaderboard.jsx`).
- `[x]` Rank movement snapshots (`dugnad_team_rank_snapshots`, daily compare → `rank_move`).
- `[x]` Prize-zone metadata (`prize_zone_size`, `prize_zone_cutoff_points` on Tabell payload).
- `[x]` Highlight user's points team (`is_user_team`, `viewer_points_team_id`).
- `[x]` Team detail endpoint: `GET /sports-club/{clubId}/teams/{teamId}/detail` — rank, goal progress, points breakdown.
- `[x]` Season cadence admin: `dugnad_seasons` table + CRUD blades (prize NOK, dates, prize zone size, team goal points). Falls back to env when no active season.
- `[~]` Add supporter card endpoint (Customer composes from points summary + ledger today).
- `[x]` Enforce full privacy/display-name rules server-side (Phase 9).
- `[ ]` Team detail: active campaign, troppen rail, top contributor honours (deferred).

### Customer App Tasks

- `[x]` Build `{name}-tabellen` with football-style segmented tabs (`LeaderboardScreen`).
- `[x]` Top-three medals, prize-zone gold styling, rank-move arrows, gap-to-zone divider.
- `[x]` Choose-team CTA when no `points_team`; Mitt lag / Hele klubben filter on scorer tabs.
- `[x]` Toppscorer / Assistkonge / Verdi tabs with hero #1 card and YOU badge. *(Replace Verdi with STØ-rangering in Phase 15.)*
- `[x]` Team detail page (`TeamDetailScreen` — rank card, fast støtte CTA, season goal, breakdown, climb tips).
- `[x]` Bottom quick cards: Your team → `TeamDetailScreen`, Your points → `DugnadPointsScreen`.
- `[~]` FIFA-style supporter card (`SupporterCardScreen` exists; wire to dedicated API when added).
- `[ ]` Season honours display (Toppscorer, Assistkonge, Kaptein, Sesongens støttespiller).

### Acceptance Criteria

- `[x]` Leaderboard ranks teams by season points inside one organization.
- `[~]` Monetary values are supporting context, not the main ranking pressure. **STØ spec:** no markedsverdi/kroner framing on leaderboard at all.
- `[x]` Public people rows honour `display_name_pref`, `is_visible`, and minor defaults via `DugnadPrivacyService`.
- `[~]` Supporter card uses tier system from points summary. **Realign** to season-based STØ model + rating breakdown sheet (`des8/player-card.jsx`) in Phase 15.
- `[~]` Toppscorer and Assistkonge rank by count-based actions. Verdi by markedsverdi is **deprecated**.

## Phase 9 - Privacy, Profile, And Compliance

Goal: make public display safe and configurable.

### Backend/API Tasks

- `[x]` Add profile fields:
  - `display_name_pref`: full name, initials, nickname if kept, anonymous.
  - `nickname`.
  - `is_visible`.
- `[x]` Add privacy update endpoint (`POST /api/customer/dugnad/privacy`, `POST .../privacy/update`).
- `[x]` Apply display masking server-side on leaderboard scorers, points summary (supporter card), and referral surfaces via `DugnadPrivacyService`.
- `[x]` Let adults choose full name, initials, nickname, or anonymous display.
- `[x]` Default minors to anonymous (enforced when `points_team.age_group` indicates youth, e.g. U-lag).
- `[~]` Log/admin-display distinction: admins can see operational PII according to role, but public surfaces cannot. *(Existing admin PII masking via `User::String2Stars`; audit log deferred.)*

### Customer App Tasks

- `[x]` Add profile privacy controls (`DugnadPrivacyScreen` from Profile → Visibility; design: `des8/visibility.jsx`).
- `[x]` Preview how user appears publicly.
- `[x]` Add explanation that anonymous contributions still count.

### Acceptance Criteria

- `[x]` Changing privacy updates all public surfaces (leaderboard, supporter card, referrals).
- `[x]` Anonymous users still contribute to team totals.
- `[x]` Public APIs never leak full names for hidden/masked users.
- `[~]` Admin PII access is role-scoped and auditable. *(Role-scoped admin masking exists; audit trail not built.)*

## Phase 10 - Admin Panel Operations

Goal: give Ærend ops the tooling to run the ecosystem — **full des8 `Admin-Dugnad.html` parity in `Hare-AdminPanel` before Customer STØ work**.

**Design reference:** `designs/des8/rend-design-system/project/Admin-Dugnad.html` + `admin/*.jsx`.

**Priority:** This phase (with Phase 15 Part A) is the **active track**. Customer gamification screens are deferred until admin config + APIs pass staging gates (see STØ delivery gates).

### Phase 10A — Dugnad admin shell & navigation

- `[~]` Replace legacy Dugnad sidebar (`dugnad_sidebar.blade.php`: Sports Clubs / Campaigns / Seasons only) with des8 **Super-admin** nav: Organisasjoner, Alle kampanjer, Fakturaer, Leverandører, Økonomi, Donasjoner, Poeng, **Gamification**, Push, Innstillinger.
- `[~]` Org-first drill-down: `OrgsHome` → `OrgWorkspace` (tabs: Oversikt, Lag, Kampanjer, **Sesong & oppdrag**, Økonomi, Kontakt) — live at `/sports-club/{id}/workspace`; **Sesonger** tab (standings + prizes) still open per `screens-org.jsx`.
- `[ ]` Team workspace tabs per `screens-team.jsx` (overview, campaigns, members/points, settings).
- `[~]` Wire existing routes into new shell: `/dugnad/donations/*` `[x]`, `/dugnad/poeng` `[~]`, `/dugnad/okonomi` `[~]`, `/dugnad/fakturaer` `[~]`, `/dugnad/leverandorer` `[~]` *(CRUD + detail catalog section live; nav parity polish pending)*.
- `[ ]` Campaign drill-down: dashboard, products, orders, exports per `screens-global.jsx` / `screens-detail.jsx`.
- `[ ]` Min konto (`/dugnad/min-konto`) per des8 `MyAccount`.

### Phase 10B — Seasons (org-scoped)

- `[~]` Season CRUD exists at `/admin/dugnad/seasons` (Providers menu) — **migrate to org Sesonger tab** per `OrgSeasons` in `screens-org.jsx`.
- `[ ]` Per-org season list: label, period, prize NOK, premiesone (top N), status (draft/active/ended); one active season per org.
- `[ ]` Live **Tabellstilling** for active season: rank, team, players, orders, sesongpoeng; prize-zone row styling.
- `[ ]` **SeasonPrizes** editor: 3 lag-premier (league placement) + 3 individuelle kåringer; image, title, value, show/hide in app (`screens-org.jsx` `SeasonPrizes`).
- `[ ]` End-season action (triggers rollover job when Chunk I is ready).
- `[ ]` Deprecate global-only seasons blade once org tab ships (comment, keep route redirect).

### Phase 10C — Points & members oversight

- `[~]` Poeng hub (`/dugnad/poeng`): clubs list with KPIs — extend to des8 `GlobalPoints` → club → team → member STØ card drill-down (`screens-points.jsx`).
- `[ ]` Member table per org/team with columns: Kjøp, Abonnement, Vervinger, Livstid, Sesong, Tier, STØ.
- `[ ]` Member detail / ledger view (`openLedger` flow).
- `[~]` Points rules editor (`screens-points.jsx` `PointsRules`) — env-backed today; make editable with version stamp.
- `[ ]` Referral oversight list, conversion drilldown, and fraud flags.
- `[ ]` Subscription and charge oversight (link from donations module).
- `[ ]` Failed/cancelled charge filters on donation admin.

### Phase 10D — Finance, distribution, exports

- `[ ]` Økonomi & utbetalinger: utbetalingskø, settlements, gebyr & fordeling tabs per `GlobalFinance`.
- `[ ]` Admin-editable global default campaign surplus split + org/campaign overrides with effective dates.
- `[ ]` Campaign order CSV/XLSX export — verify columns against final spec.
- `[ ]` Audit logs for sensitive changes and exports.

### Phase 10E — Remaining ops (parallel after 10A–C)

- `[~]` Organization CRUD with dynamic identity fields (`club_short_name`, crest, contact).
- `[~]` Team CRUD with logo.
- `[ ]` Team contact and bank-account management.
- `[~]` Campaign create/edit with team selector + fundraising goal.
- `[x]` Campaign products management.
- `[~]` Supplier integration in product flows: campaign product supplier dropdown uses `dugnad_suppliers`; master catalog product form migrated from legacy brand dropdown to suppliers; supplier detail lists linked catalog products.
- `[ ]` Push-varsler module (`screens-push.jsx`) — optional for v1 launch but in des8 nav.

### Acceptance Criteria

- Ærend ops can configure a full season (dates, prize zone, prizes) **per organization** without code changes.
- Gamification module is reachable from sidebar and saves STØ chunks H, A, B, C, D, E, F to DB + config API. *(Chunks G, I rollover still open.)*
- Ops can drill org → team → member → points ledger and STØ summary.
- Buyer CSV export works per campaign and per product.
- **Staging gate:** Flutter team can fetch complete gamification config from API before any new STØ screen work starts.
- Club admin access, if enabled, cannot see Ærend margin or edit split policies.

### CSV Export Columns

`order_id, date, buyer_name, phone, email, product, quantity, unit_price, line_total, payment_method, fulfilment_type, fulfilment_status, refunded, points_awarded, team`

## Phase 11 - Finance, Distribution, Settlements, And Manual Payouts

Goal: make money traceable from payment to manual payout.

### Backend/Admin Tasks

- `[ ]` Add admin-editable global default campaign surplus split.
- `[ ]` Add admin-editable organization-level split override.
- `[ ]` Add admin-editable campaign-level split override.
- `[ ]` Add admin-editable transparent donation fee configuration, including platform fee rates.
- `[ ]` Version all distribution config with effective dates.
- `[ ]` Generate campaign settlements:
  - Gross sales.
  - Supplier/cost of goods if modeled.
  - Surplus.
  - Ærend share.
  - Team share.
  - Net to team.
  - Payout status.
- `[ ]` Generate subscription settlements:
  - Charges collected.
  - Transaction/platform fees.
  - Net to team/org.
  - Payout status.
- `[ ]` Build payout queue grouped by recipient account.
- `[ ]` Mark paid manually with paid date, amount, bank reference, and admin user.
- `[ ]` Make public "Samlet inn" equal sum of all paid net amounts to the club (lifetime, for now).
- `[ ]` Audit every payout and split change immutably.

### Acceptance Criteria

- Every settled order/charge has a settlement line.
- Pending payout queue matches settlement totals.
- Admin can mark payout paid after bank transfer.
- Public raised amount reconciles to paid net payouts, not gross revenue.
- Past settlements do not change when future split config changes.

## Phase 12 - Public Campaign Website

Goal: ship the public web sales funnel from the same campaign model.

### Website Tasks

- `[x]` `Reen-web-portal` has campaign and club landing routes/components for web/mobile web.
- `[x]` Website checkout is no-login; buyers place orders by entering contact/order information directly.
- `[~]` Website has dedicated campaign/club components; verify final visual parity against current Customer Dugnad screens.
- `[ ]` Use dynamic organization source, initially configured for Sædalen IL if confirmed.
- `[x]` Website renders active campaigns and details from public campaign APIs.
- `[x]` Club campaign cards and campaign detail show optional fundraising progress when admin sets `fundraising_goal_nok`.
- `[ ]` Include real app campaign-screen mockup, matching current app UI.
- `[~]` Web checkout creates guest orders and supports Stripe/Vipps provider responses; production payment config still needs verification.
- `[~]` Confirmation polling/status page exists; verify final confetti/celebration parity with app.
- `[ ]` Funnel users toward app after purchase.

### Backend/API Tasks

- `[x]` Public campaign endpoints exist: live list, campaign detail, guest order, and order status.
- `[x]` Guest web checkout order creation and confirmation polling exist using buyer-entered info.
- `[~]` Ensure website purchase still awards points only when user identity/referral rules allow it.
  - Guest orders carry pending referral metadata; conversion requires verified account match and first paid action rules.
- `[x]` Support referral link capture from website path/query (`/[locale]/k/[club]?v=` + checkout cookie forwarding).

### Acceptance Criteria

- Public user can browse and buy campaign products on web/mobile web.
- Website purchase does not require login or account creation.
- Web checkout payment creates the same order/settlement records as app checkout.
- Design matches app campaign screens.
- Website does not expose leaderboard, points, badges, or donations in v1.

## Phase 13 - Gamification, Celebrations, And Season End

Goal: make the supporter experience feel complete without changing core money rules.

**Design reference:** `des8/gamify-form.jsx`, `gamify-cards.jsx`, `player-card.jsx`, `gamify-plus.css`.

### Celebration & feedback tasks

- `[ ]` Add welcome confetti once after onboarding.
- `[ ]` Add full confetti and haptics for campaign purchase, donation setup, level-up, and milestones.
- `[ ]` Add lighter feedback for minor actions.
- `[ ]` Add shareable cards after major actions.
- `[ ]` Add season-end card lock as a keepsake that users can share to showcase their season (`player-card.jsx` season recap).
- `[ ]` Add season honour calculations.
- `[x]` Do not build season-end redemption; no prize draw/perk redemption flow is needed for v1.

### New STØ screens (**Phase 15 Part B** — partial; missions screen shipped)

> Full Part B sign-off still blocked on admin gates G6–G8. `DugnadMissionsScreen` shipped early against live config + progress APIs.

- `[~]` **Formen din** — form tempo + streak on `DugnadMissionsScreen`; dedicated `FormScreen` (`gamify-form.jsx`) still open.
- `[~]` **Ukens kamper** — weekly challenges + streak card on `DugnadMissionsScreen` (config + `GamificationProgressService`).
- `[~]` **Sesongmål** — season goals with progress bars on `DugnadMissionsScreen`.
- `[ ]` **Overgangsvinduet** — season-end transfer ceremony, "Signert for" share card, flexible promotion options (`TransferScreen` in `gamify-cards.jsx`).
- `[ ]` **Karrieren din** — lifetime points anchor, permanent badges, seasonal archive, FIFA-årganger season cards, affiliation timeline (`CareerScreen`).
- `[ ]` Profile entry rows for recap / transfer / career (`offers.jsx`).

### Acceptance Criteria

- Celebrations fire once per qualifying event.
- No celebration awards unledgered points or money.
- Season-end honours can be reproduced from ledger/season data.
- Season-end card can be shared, but cannot be redeemed for money, perks, or bonus donations.
- Form display never implies payment affects rating.
- Transfer changes affiliation only — rating, points, tier, and permanent badges follow the user.

## Phase 14 - QA, Migration, And Launch Readiness

Goal: validate the full supporter/admin/money loop.

### Test Scenarios

- `[ ]` Guest browses campaigns and leaderboard.
- `[ ]` New Google user signs up, verifies phone, selects club/team.
- `[ ]` New Apple user signs up, verifies phone, selects club/team.
- `[ ]` Returning user sees same points team and profile preferences.
- `[ ]` User buys campaign product with enabled payment method.
- `[ ]` Purchase creates order, settlement, points, and success UI.
- `[~]` User creates recurring donation (setup/manage UI + API shipped; Vipps agreement approval blocked on Recurring MSN portal setup).
- `[ ]` Donation charge creates settlement, payout-pending row, and points (code paths exist; needs charge E2E after Recurring live).
- `[~]` User refers friend by link (implemented; needs staging E2E verification).
- `[~]` Friend signs up and converts on first settled paid action (campaign + donation charge paths implemented; staging E2E pending).
- `[~]` Referrer points update (ledger write on conversion; verify against points summary UI).
- `[~]` Refund reverses campaign/referral points where applicable (service + webhook paths exist; needs refund E2E).
- `[x]` User changes privacy to anonymous and public rows mask immediately.
- `[ ]` Admin exports buyer CSV.
- `[ ]` Admin marks payout paid.
- `[ ]` Public raised amount updates from paid net amount.
- `[ ]` Web campaign checkout creates equivalent records.
- `[ ]` Admin creates season with prizes in org Sesonger tab; standings update from ledger.
- `[~]` Admin saves STØ rating thresholds in Gamification tab; config API returns same values (shipped 2026-07-06; staging smoke test pending).
- `[~]` Admin toggles gamification feature flag off; app config reflects disabled module (API shipped; Customer consumption pending).
- `[ ]` Admin runs end-season / rollover; season cards archived with frozen club/team names.
- `[ ]` Cancel/pause donation — points and rating unchanged; only future earning stops.
- `[ ]` Season rollover: archive → carryover → reset preserves lifetime points and permanent badges.
- `[ ]` Transfer team/club — rating/points follow user; season counters reset for new team.
- `[ ]` Leaderboard STØ-rangering tab shows rating only (no kroner/markedsverdi).

### Required Checks

- `[ ]` Flutter analyze/build for Customer.
- `[~]` Backend tests or API scripts for auth, campaigns, donations, referrals, points, leaderboard, settlements, payouts, and privacy.
  - Donation fee unit tests (`DonationFeeServiceTest`) and referral tests exist; donation subscription/charge lifecycle integration tests remain open.
- `[ ]` Payment webhook tests for success, failure, duplicate webhook, refund, cancellation.
- `[ ]` Role/permission tests for PII, bank accounts, exports, and finance margins.
- `[ ]` Localization pass for all visible Customer Dugnad strings.
- `[ ]` Copy audit:
  - No sponsor-shopping points.
  - No membership-number requirement.
  - No member-discount promise.
  - No courier delivery copy.
  - No fake scarcity/deadline.
  - No markedsverdi/kroner on leaderboard (STØ §9).
  - Membership points copy states earn-on-charge, no clawback (STØ §2).

### Launch Acceptance Criteria

- A complete loop works: guest browses -> user signs up -> chooses points team -> buys campaign -> donates -> refers friend -> earns points -> appears correctly on leaderboard -> admin pays out.
- Money, points, referrals, and public display are all traceable to ledgers/config.
- Pilot organization can be configured without code changes.
- Open decisions are either signed off or explicitly deferred with feature flags disabled.

## Phase 15 - STØ System Realignment (spec v1.0)

Goal: align backend config, APIs, and surfaces with `aerend-sto-system-spec.md` and des8 prototypes.

**Prerequisite:** `dugnad_seasons` table (exists from Phase 8).

**Split:** **Part A — Hare-AdminPanel (first, active track).** **Part B — Hare-Customer (after admin staging gates G1–G8).**

---

### Part A — Hare-AdminPanel (priority track)

Matches `Admin-Dugnad.html` Gamification module + org **Sesonger** tab + Poeng rules. Each chunk ships: migration + admin UI (des8 layout) + config API extension + admin smoke test.

#### A1 — Gamification module shell

- `[x]` Sidebar **Gamification** → seven tabs: Innstillinger, STØ-rating, Form & Sesongmål, Spesialkort, Overgangsvindu, Sesong-carryover, **Medlemspoeng**.
- `[x]` Admin blades matching `admin/admin.css` (`adm-card`, `PageHead`, `Tabs`, `Toggle`, config payload preview).
- `[ ]` Integrate with Phase 10A org-first shell when ready.

#### A2 — Build chunks (§13)

- `[x]` **Chunk H** — `gamification_features` + app-config API (`GamiSettings`).
- `[x]` **Chunk A** — `sto_rating_thresholds` + `sto_tier_thresholds`; curve preview (spec-aligned season-points → rating, not legacy 3-component model).
- `[x]` **Chunk B** — `season_carryover_tiers` + `carryover_settings`; simulator (`GamiCarryover`).
- `[x]` **Chunk D** — `sto_badges` + `sto_badge_rating_config`; `user_permanent_badges` + `user_seasonal_badges`; badge CRUD (permanent/seasonal); `StoBadgeService` unlock → points ledger.
- `[x]` **Chunk F** — `club_tier_aliases` in org Sesong & oppdrag; `ClubTierAliasService`; scoped `club_tier_aliases` in config API; `PointsEngine` + leaderboard display.
- `[x]` **Chunk E** — config (`GamiForm`) + runtime: progress tables, `GamificationProgressService`, weekly auto-rotation (`dugnad:rotate-weekly-challenges`), scoped API merge, org workspace Sesong & oppdrag tab, `DugnadMissionsScreen` in app.
- `[x]` **Chunk C** — `membership_points_config`; charge hook; balance-insight; clawback guard; Medlemspoeng tab NO/EN i18n.
- `[ ]` **Chunk G** — leaderboard STØ ranking config.
- `[x]` **Chunk I** — `SeasonRolloverService` (archive → carryover ledger → reset counters), `user_team_affiliations`, `StoBadgeEvaluatorService`, career API, admin **Kjør sesongavslutning** on season form, `dugnad:rollover-season {id}`.

#### A3 — Engine hooks (config plug-ins only)

- `[ ]` `PointsEngine::stoRatingFromSeasonPoints()` using Chunk A.
- `[ ]` Metal tier from rating ranges.
- `[x]` Membership points on successful charge; no reversal on cancel/pause (Chunk C — `MembershipPointsService` + `PointsService::donationChargePointsForAmountKr`).
- `[x]` Badge unlock → point bonus ledger row (`StoBadgeService` + `PointsService::awardBadgeUnlockPoints`).
- `[~]` Extend config API payload (additive only) — badges, `weekly_challenges`, `membership_points`, `carryover`, `club_tier_aliases`, form/goals, progress API shipped; Chunk G leaderboard config + season-points rating engine still open.

#### A4 — Admin staging gates (unlocks Part B)

- `[~]` G1–G5 pass (admin + runtime; Flutter missions partial). G6/G7/G8 open. Ops smoke-test script for remaining gates still TBD.
  - **Partial (2026-07-07):** G1–G5 admin/runtime done; `DugnadMissionsScreen` consumes config + progress; G6 (org Sesonger), G7 (leaderboard STØ config), G8 (rollover job) open.

---

### Part B — Hare-Customer (partial — missions screen live)

**Design:** `des8/dugnad/`. **Remaining STØ screens** blocked on Part A gates G6–G8.

#### B1 — Config consumption

- `[~]` Read gamification config + feature flags (`DugnadMissionsScreen` + repo on demand; global startup cache TBD).
- `[ ]` Use season-based STØ rating for display/ranking (replace lifetime-based display).

#### B2 — Screens

- `[ ]` Rebuild supporter card (`player-card.jsx`).
- `[~]` `DugnadMissionsScreen` (`dugnad_missions_screen.dart`) — Ukens kamper + Sesongmål + form/streak from APIs; entry from Dugnad points screen.
- `[ ]` `DugnadFormScreen`, `DugnadTransferScreen`, `DugnadCareerScreen` still open.
- `[ ]` Profile rows: Sesong-recap, Overgangsvinduet, Karrieren din (`offers.jsx`).
- `[ ]` Leaderboard STØ-rangering tab; hide Verdi (`leaderboard.jsx`).
- `[ ]` Fast støtte membership copy (`donate-abonnement.jsx`).
- `[ ]` Transfer + career APIs (affiliation history, frozen season cards).

#### B3 — Customer acceptance

- STØ rating and metal tier match admin thresholds.
- Form is display-only; no clawback on cancel/pause.
- Leaderboard shows STØ only — no markedsverdi/kroner.

### Compliance checklist (before launch)

- `[ ]` Legal review of cash-equivalent season prizes (STØ §2.2).
- `[ ]` Balance calibration via admin balance-insight tool.
- `[ ]` Landing/marketing copy matches membership framing.
- `[ ]` Backend award behaviour matches app copy: no clawback on cancel/pause/failed charge.

## Resolved Decisions


| Decision                       | Confirmed Direction                                                                                                                                                                                                                                        | Status |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| Club admin logins              | Ærend-internal admin first; no club admin login required for v1 launch.                                                                                                                                                                                    | `[x]`  |
| Campaign fulfilment            | No new fulfilment scope for now; current campaign completion flow is acceptable, with final-spec CSV exports.                                                                                                                                              | `[x]`  |
| Platform/transaction fee rates | Rates must be editable via AdminPanel.                                                                                                                                                                                                                     | `[x]`  |
| Campaign split                 | Split rules must be configurable via AdminPanel.                                                                                                                                                                                                           | `[x]`  |
| Points/rating formulas         | **STØ gamification:** `aerend-sto-system-spec.md` (season points → rating, form tempo-only, badge bonuses). **Membership points (Chunk C):** per-100-kr on charge via `MembershipPointsService`. **Ledger/referral:** legacy band formula when Medlemspoeng module off. Legacy `PointsEngine::stoRating` (lifetime) deprecated. | `[~]`  |
| Season cadence and prize       | **Finalized:** Admin sets season start/end dates, manages active season lifecycle, views season history, and configures prize (value + required metadata) in AdminPanel. No fixed calendar cadence in code; season points scope follows the active window. | `[x]`  |
| Adult privacy defaults         | Adults can choose full name, initials, or anonymous.                                                                                                                                                                                                       | `[x]`  |
| Minor privacy defaults         | Minors are anonymous by default.                                                                                                                                                                                                                           | `[x]`  |
| SMTP/OTP providers             | Reuse existing SMTP and OTP providers.                                                                                                                                                                                                                     | `[x]`  |
| App phone verification timing  | Phone verification is compulsory when creating an account in the app.                                                                                                                                                                                      | `[x]`  |
| Website login                  | `Reen-web-portal` campaign checkout has no login; buyers enter their info directly.                                                                                                                                                                        | `[x]`  |
| Matkasser website/admin base   | `Reen-web-portal` and `Hare-AdminPanel` already cover campaign pages, sales windows, distribution date/location, products, no-login checkout, payment initiation, and exports.                                                                             | `[x]`  |
| `Samlet inn` period            | Lifetime for now (all paid net amounts to the club).                                                                                                                                                                                                       | `[x]`  |
| Season-end redemption          | No redemption flow; users can share the locked season card only.                                                                                                                                                                                           | `[x]`  |
| Campaign fundraising goal      | Optional `fundraising_goal_nok` per campaign in AdminPanel; web club cards and campaign detail show progress when set; Customer app parity deferred.                                                                                                      | `[x]`  |
| STØ system model               | `aerend-sto-system-spec.md` v1.0 is authoritative for rating, tiers, form, badges, carryover, leaderboard, career, transfers. Supersedes lifetime-based STØ in points engine §9.                                                                          | `[x]`  |
| Leaderboard Verdi tab          | Deprecated — rank on STØ rating instead; no markedsverdi/kroner framing (STØ §9).                                                                                                                                                                        | `[x]`  |
| Design source (Dugnad UI)      | Customer: `des8/.../dugnad/`; Admin: `des8/.../Admin-Dugnad.html` + `admin/*.jsx`.                                                                                                         | `[x]`  |
| Admin-first delivery           | Hare-AdminPanel gamification, seasons, teams, and config APIs must ship and pass staging gates before Flutter STØ screens.                                                                  | `[x]`  |


## Remaining Open Decisions


| Decision                                 | Default For Planning                                                                                                                                                                                | Status |
| ---------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| Production payment readiness             | MSN **1091843** production keys on `api.ailogistics.no`; webhooks + login redirect documented in `Hare-AdminPanel/docs/VIPPS_PRODUCTION_SETUP.md`; portal registration in progress. | `[~]`  |
| Goal bar on anchor card                  | Club landing + campaign detail progress bars shipped on web when goal is set; Dugnad home anchor card still optional / not built.                                                                  | `[~]`  |
| Campaign fundraising goal (NOK)          | Optional per campaign in AdminPanel; drives progress on `Reen-web-portal` club cards and campaign detail. Customer app parity open.                                                                  | `[x]`  |
| Prize-zone presentation (leaderboard UI) | Top 3 default; editable via **Dugnad seasons** admin (`prize_zone_size`).                                                                                                                         | `[x]`  |
| STØ legal review (season prizes)         | Cash-equivalent prizes tied to purchase-influenced ranking need Lotteritilsynet/Forbrukertilsynet review before award (STØ §2.2).                                                                | `[!]`  |
| Membership points calibration            | Set `points_per_100_kr` using admin balance-insight after real activity data; membership must stay baseline not dominant path (STØ §8).                                                          | `[ ]`  |


## Implementation Order

**Active priority:** Steps 11–13 (AdminPanel). Customer STØ screens (step 14) start only after admin staging gates.

1. Scope lock and open-decision ownership.
2. Data model foundation: orgs, teams, users, ledgers, settlements.
3. Auth, guest browsing, OTP, club/team selection.
4. Dynamic club identity everywhere.
5. Team-owned campaigns and app checkout.
6. Points ledger foundation (ledger shipped; STØ rating realignment in admin first).
7. Donations / Fast støtte — code shipped; Vipps Recurring MSN + E2E remain.
8. Referrals — core loop shipped; staging E2E remain.
9. Leaderboard, team detail, supporter card — shipped; STØ-rangering rebase after admin Chunk G.
10. Privacy and profile compliance — shipped (Phase 9).
11. **Admin Dugnad shell** — des8 nav, org workspace (`/sports-club/{id}/workspace`), team drill-down (Phase 10A) `[~]`.
12. **Admin seasons** — org **Sesonger** tab, standings, prizes, end-season (Phase 10B) `[~]` global CRUD only.
13. **Admin gamification + STØ config** — Gamification module, chunks H→F done; G + I open; config API gates (Phase 15 Part A + Phase 10C) `[~]`.
14. **Customer STØ screens** — `DugnadMissionsScreen` `[~]`; remaining screens after G6–G8 (Phase 15 Part B + Phase 13 celebrations).
15. Admin finance, CSV exports, payouts (Phase 10D–E, Phase 11).
16. Public campaign website parity (Phase 12).
17. QA, migration, pilot launch hardening (Phase 14).

## Notes For Engineers

- Prefer additive Dugnad APIs where existing commercial APIs are shared.
- Do not break existing commercial mode.
- Keep feature flags around payment surfaces that lack production keys.
- **PHPUnit safety:** tests must use `db_hare_test` (`phpunit.xml`); `TestCase` hard-fails if `DB_DATABASE=db_hare`. Never run `RefreshDatabase` / `migrate:fresh` against the dev database.
- **Weekly challenges (club admin):** org **Sesong & oppdrag** edits the club challenge **pool** only; which three are active each ISO week is snapshotted in `weekly_challenge_weeks` from **global** rotation (manual slots or auto Mon 00:05). Mid-week pool edits update definitions immediately; new challenges enter rotation next week.
- Vipps Recurring failures: search `Vipps recurring` in `Hare-AdminPanel/storage/logs/laravel-*.log`; with `APP_DEBUG=true` the API may also return `debug_detail` to the Customer app.
- Treat ledger rows as source of truth; aggregate counters are cached/display data only.
- Enforce privacy on the server, not only in Flutter.
- Keep UI copy anchored to final spec and localized through Customer localization files.
- Any change to points or money config must be versioned and auditable.
- **STØ spec:** do not modify `PointsEngine` / `CampaignService` / `DonationFeeService` core logic — plug new mechanics in as configuration (spec §12.1).
- **STØ spec:** all migrations additive; deprecate in comments, never hard-delete ranking sources or tables.
- **Admin design:** match `Admin-Dugnad.html` / `admin/*.jsx` for all new Dugnad admin screens; open prototype locally via `npx serve` on `designs/des8/rend-design-system/project/`.
- **Customer design:** match `des8/dugnad/` for STØ gamification screens — but only after admin config exists.
- **Prototype vs spec:** admin `GamiRating` and customer `player-card.jsx` may show pre-consolidation formulas; implement behaviour per `aerend-sto-system-spec.md`.
- **Compliance:** no point/rating clawback on cancel/pause/failed charge; admin must block such config.

