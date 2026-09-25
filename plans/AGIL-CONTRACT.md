# AGIL contract — agil-1 (v2) and agil-3

**This file is binding on both plans.** `AGIL-1-PLAN-v2.md` and `AGIL-3-PLAN.md`
each say "read the contract first". If a plan and this file disagree, this file
wins and the plan is wrong. Written 2026-09-25.

The last merge (`agil-2` into `agil-1`, 2026-09-23) produced **seven defects, five
of them silent**, and every one was the same thing: two components agreed on a
*name* in prose and disagreed in code — `order_events` vs `ops_order_events`,
`feature_flags` vs `ops_feature_flags`, `policies` vs `ops_policies`, a JSON
`actor` vs two columns, an env var documented and never read. The event payloads,
which *were* contracted with fixtures, came through untouched. So this contract
does for names what `EVENT_CONTRACT.md` did for payloads: every table, column,
env var, flag, policy key, route, event, Dart file and copy key that either
branch will create is **written here first, with an owner, before any code**, and
a test on each branch asserts the registry against reality.

---

## 0. The rules

1. **Names come from here.** A branch creates only names listed in §3 under its
   own owner column. If you need a name that is not here, add it to your
   branch's registry file (§4.2) and to this document in the same commit, then
   build. Never invent a name in code and document it later.
2. **A prefix says who builds it, not what it is about.** `ops_` and `ops.` are
   agil-1's; `pd_`, `geo_`, `agtp_` and `agt.` / `geo.` / `pd.` are agil-3's;
   `pts_`, `agent_` and the `points` / `aegil` flags are agil-2's inheritance
   and now agil-3's to extend. If agil-3 needs a column on an order it is
   `pd_…`, not `ops_…`, even though the order is agil-1's table. That is how
   both branches add columns to the same table without ever touching the same
   name.
3. **Read a table name from a constant, never a literal.** Every model owns
   `public const TABLE`; every consumer references `Model::TABLE`. Defects #1,
   #2 and #7 were string literals in the consumer.
4. **Guard every cross-branch column with `Schema::hasColumn` until merge day.**
   agil-1 reads `pd_delivery_actor` before agil-3's migration exists on its
   branch; the read degrades to the default, never throws. This is the pattern
   `FeedTokenTest` and `OpsTestHelpers::providerRow()` already use.
5. **One env var, one reader, and the reader is in `config/`.** Nothing calls
   `env()` outside a config file. Defect #3 was an env var read nowhere.
6. **No positional column hints.** `->after('x')` is banned in both branches:
   production has columns no migration creates (`ean_number`, `users.credit`,
   `providers.first_name` …), so a position pin that works on dev fails on any
   database built from migrations. Column order is cosmetic.
7. **Test against the live schema.** `scripts/rebuild_test_db.sh` before
   `php artisan test`, always. A migration-built test DB is a schema that exists
   nowhere real.
8. **Shared files get one append per need**, in a commit titled
   `chore(shared): <what>`, and never a deletion. The full list of shared files
   is §2.4; anything not on it is owned by exactly one branch.
9. **No ARB edits on agil-3, and none on agil-1 until Phase 8.** Eight of the ten
   merge conflicts were `lib/l10n/*`. Both branches put screen copy in a Dart
   copy file they own (`*_copy.dart`, the pattern the onboarding and Hjem work
   already use), keyed with the branch prefix. agil-1's final phase moves all of
   it into ARB in one pass, after agil-3 has merged.
10. **Nothing goes into `main` or `master` in any repo, and nothing is pushed
    without being asked.** `agil-1` is the integration branch; `agil-3` merges
    into it on merge day (§6). `agil-1-backup` stays as the pre-merge fallback.

---

## 1. Branches and sync points

| Branch | Base | Owner plan | Role |
|---|---|---|---|
| `agil-1` | continues from `53c788f`+ | `AGIL-1-PLAN-v2.md` | Integration branch. The customer's ærend end to end — search, store, cart, checkout, tracking — the customer tracking API, the shared UI kit, l10n consolidation, hygiene. |
| `agil-3` | `git checkout -b agil-3 agil-1` at the commit that carries this file | `AGIL-3-PLAN.md` | The three new specs' backends and admin modules; the Points, Ægil and Meg customer screens. |

**Sync C** — agil-1 v2 Phase 0 ends with `git tag sync-C`. **Tagged 2026-09-25:**
Hare-AdminPanel `c07f51ee47a3c0661cd4c529ebdcc21de64270b0`, Aerend-app
`525b01444b767e592317f87b38ac3c3767749d1b` (both on `agil-1`; `agil-3` was
branched from these commits the same day). It contains, and nothing else:

- `ops_feature_flags.value` (json, nullable) and `App\Points\FeatureFlags`
  repointed to `ops_feature_flags` — ending the two-mechanism split.
- `App\Ops\SurfaceFlags::register(array)` — a static registry other providers
  add flags to, so agil-3 never edits `SurfaceFlags.php`.
- `App\Ops\Dispatch\CandidateSource` interface, `OpsCandidateSource` default,
  bound in `AppServiceProvider`, consumed by `DispatchService`.
- Aerend-app: `lib/screens/bergen/kit/*` (§2.2), the seam files (§2.2), the
  shell wired to them, `lib/theme/bergen_tokens.dart` (the renamed
  `reen_pre_club_theme.dart`).
- `tests/Feature/Contract/ContractNamesTest.php` and the two registry files.
- `docs/EVENT_CONTRACT.md` extended per its versioning rule with the three new
  events in §5.3 and their fixtures.

agil-3 runs `git cherry-pick sync-C` as its first action and must not start
Phase 1 until it applies cleanly and `ContractNamesTest` passes on both
branches.

**Merge day** — agil-3 → agil-1, §6. There is no Sync D: after merge day agil-1's
Phase 8 consolidates copy into ARB on the merged tree.

---

## 2. Ownership

### 2.1 Backend — `Hare-AdminPanel`

| Area | agil-1 (v2) | agil-3 |
|---|---|---|
| Migrations | filenames `2026_10_*_ops2_*` | filenames `2026_10_*_a3_*` |
| Tables (new) | `ops_*` only | `agtp_*`, `geo_*`, `pd_*`; may add columns prefixed `pd_` / `geo_` to `store_details`, `user_store_product_booking`, `providers` |
| Models | `app/Models/Ops/*` | `app/Models/AgentOps/*`, `app/Models/Geo/*`, `app/Models/PartnerDelivery/*`; inherits `app/model/Pts*`, `app/model/Agent*` |
| Services | `app/Services/Ops/*`, `app/Ops/*` | `app/Services/AgentOps/*`, `app/Services/Geo/*`, `app/Services/PartnerDelivery/*`; inherits `app/Agent/*`, `app/Points/*` |
| Controllers | `app/Http/Controllers/Ops/*`, `Admin/OpsAdminController` | `app/Http/Controllers/AgentOps/*`, `Geo/*`, `PartnerDelivery/*`, `Admin/{AgentOps,Geo,PartnerDelivery}AdminController`; inherits `Admin/PointsAdminV2Controller`, `Admin/AgentAdminController` |
| Routes | `routes/api_ops.php`, `routes/channels.php` | new files `routes/api_agentops.php`, `routes/api_geo.php`, `routes/api_partner_delivery.php`; inherits `api_points.php`, `api_agent.php`. Each registered by one `require` in `routes/api.php` (shared, append) |
| Admin views | `resources/views/admin/pages/super_admin/ops/*` | `.../agentops/*`, `.../geo/*`, `.../partner_delivery/*`; inherits `.../points/*`, `.../agents/*` |
| Admin nav | `admin_module` rows via own migration | same, own migration per module |
| Flags | `App\Ops\SurfaceFlags` (the file) | registers `agt.*`, `geo.*`, `pd.*` through `SurfaceFlags::register()` from `AgentOpsServiceProvider` |
| Policy keys | `App\Ops\PolicyKeys` (`time.* money.* dispatch.* escalation.*`) | `AgentOps\AgentOpsPolicyKeys` (`agt.*`), `Geo\GeoPolicyKeys` (`geo.*`), `PartnerDelivery\PdPolicyKeys` (`pd.*`), each with its own seeder |
| Console | `ops:*` | `agentops:*`, `geo:*`, `pd:*` |
| Dispatch seam | `App\Ops\Dispatch\CandidateSource` + `OpsCandidateSource`, bound in `AppServiceProvider`; `DispatchService` consumes it (**Sync C**) | binds `Geo\GeoCandidateSource` in its own provider when `geo.engine.cutover` is on. Never edits `DispatchService`. |
| Notifications | `App\Services\Ops\NotificationService` and its table | calls its public `send()`; never writes `ops_notifications` |
| Order transitions | `OrderTransitionService` — the single write path | calls it with `actor_type = 'store'` for self-delivery transitions; never writes `ops_state` |
| Delivery proof | `DeliveryProofService` (PIN verify) | calls it for the store-entered PIN; never re-implements |
| Tests | `tests/Feature/Ops/*`, `tests/Feature/Contract/ContractNamesTest.php` (the file) | `tests/Feature/AgentOps/*`, `Geo/*`, `PartnerDelivery/*`; extends `Points/*`, `Agent/*` |
| Registry | `tests/fixtures/contract/names.agil1.json` | `tests/fixtures/contract/names.agil3.json` |
| Docs | `docs/OPS_*.md`, `docs/EVENT_CONTRACT.md` (only via its versioning rule, only in Sync C) | `docs/AGENTOPS_*.md`, `docs/GEO_*.md`, `docs/PARTNER_DELIVERY_*.md` |

**Existing tables are not renamed by anyone.** The baseline in §3.1 is frozen.

### 2.2 Customer app — `aerend-app/Aerend-app`

The prototype's 70 `data-screen-label`s are mostly components and states. Its
real screens are the values of its `st.skjerm` router plus a set of sheets, and
ownership is by those. All new screens live under `lib/screens/bergen/<group>/`;
the Hjem package stays at `lib/screens/common/home/bergen/`.

| Folder | Owner | Prototype screens | Labels that belong to them |
|---|---|---|---|
| `lib/screens/bergen/kit/*` | agil-1, **built in Sync C** | shared UI kit: `BergenTokens`, `BergenArk` (the generic `Ark {{ kArkTittel }}` sheet: title, subtitle, copy block, rows, two CTAs), `BergenSheet`, `BergenChip`, `BergenCta3d`, `BergenToast`, `BergenUndoPill`, `BergenOfflineBanner`, `BergenCard`, `BergenStepper` | Ark, toast, Angre, offline banner |
| `lib/screens/common/home/bergen/*` | agil-1 | `hjem` (done) plus its entry points | Sjø · hero/dag/kveld/regn, Fjordfiske-knapp, Vindu · kategoriene, Kategorirad, Forundringspose (card), Utforsk-kort ×2, the shop and product carousels, the bell |
| `lib/screens/bergen/sok/*` | agil-1 | `sok` | Søk · treff / Spør Ægil / Nylige søk / Populært nå / Ukens oppdrag, the wish banner, `sokVanlig` / `sokIngen` / `sokTom` |
| `lib/screens/bergen/butikk/*` | agil-1 | `kategori` (+ Gaver and Mote variants), `butikk` (restaurant page), `{{ butSideLabel }}` (fashion / gift page), `automat` (Poseautomaten), the Klede sheet, the food product sheet, the Info sheet, the category sheet | Dreieskiven, Seilas · Burger King, Kjøkkenluka, Gaver-kategori, Mote-utstilling, Forundringspose (sheet) |
| `lib/screens/bergen/kasse/*` | agil-1 | `kurv`, the Adresse / Ny adresse / Levering / Betaling sheets, the post-purchase sequence `kjopSteg2–4`, `bestillinger` **detail** | Seilas · kassen, Levert · vervebillett, Bestillingsdetaljer |
| `lib/screens/bergen/sporing/*` | agil-1 | `sporing` (all stages, delivery and pickup), `levert`, the Hjelp sheet and all its states, the completion layer | Sporing · stadier / stadieskifte / Bekreftet / Tilberedes / Levert / Avslutt, Ægil-veileder, Bud-identitet, Leveringskode, Valg som venter, Ring / Melding til `{{ kontaktRolle }}`, Finner ikke døra, Noe mangler, Kundeservice, Bekreftet (help), Poeng for denne ordren (the line on Levert) |
| `lib/screens/bergen/utforsk/*` and existing `lib/screens/feed/*` | agil-1 | `utforsk` (Feed / Fjordfiske / Forundringspose tabs), `feed` (Nytt fra butikkene) | Feed-media, the pinned Drift notice, the bags tab. The Fjordfiske tab body is agil-3's screen reached by route |
| `lib/screens/bergen/hjelp/*` | agil-1 | `Laster`, the `Demo` panel (5-tap; compiled out of release builds) | Laster, Demo |
| `lib/screens/tracking/*`, `lib/networking/ops/*`, `lib/networking/feed/*`, `lib/data/feed/*`, `lib/data/ops/*` | agil-1 | existing; `tracking/` is retired into `sporing/` in Phase 6 | |
| `lib/screens/bergen/poeng/*` | agil-3 | `premier`, `velger`, `liga`, `opprykk`, `fiske`, the Napp-kort dialog | Premiehylla, Ægil velger, Premien Ægil valgte, Fløyen-ligaen, Nivåopprykk, Fjordfiske, Bryggen · fiske, Sjø · fiske, Ægil (poses), Ægil snakker, Fangst, Premiefangst, Fiske-kontroller, Agn, Napp-kort, Poeng (the Meg card) |
| `lib/screens/bergen/aegil/*` | agil-3 | `agent` (the chat screen and every `agentGaa` state), Det Ægil vet om deg, the brett drawer, Mens du var borte | Ægil-hilsen, Forslagskort, Klassisk søk *block*, Det jeg vet, Ægil-relevanskort, Mens du var borte, the Ark variants for Ægil |
| `lib/screens/bergen/meg/*` | agil-3 | `meg`, `favoritter`, `konto`, `bestillinger` **list**, the Varsler panel | Meg-rader, Gullbilletten, notification rows |
| `lib/screens/points/*`, `lib/screens/aegil/*`, `lib/data/points/*`, `lib/data/aegil/*`, `lib/screens/snurre/*` | agil-3 | inherited from agil-2 | |
| `lib/l10n/*` | agil-1, **Phase 8 only** | | |

`Ark {{ kArkTittel }}` has ~45 titled variants used by both branches. The sheet
*component* is agil-1's (`kit/`); each variant's *body* belongs to whichever
screen opens it and lives in that owner's folder. No branch adds a variant to
the kit.

**Seam files, created by agil-1 in Sync C as stubs, filled by agil-3:**

| File | Exports | Purpose |
|---|---|---|
| `lib/screens/bergen/bergen_routes_agil3.dart` | `Map<String, WidgetBuilder> bergenRoutesAgil3()` | agil-3's named routes. The shell spreads it into `MaterialApp.routes` (Sync C). agil-1 has `bergen_routes_agil1.dart`. Neither edits the other's. |
| `lib/screens/bergen/meg/meg_host.dart` | `class MegScreen extends StatelessWidget` | Tab 3 of the shell. The stub renders the existing `Account()`; agil-3 replaces the body. |
| `lib/screens/bergen/poeng/poeng_entry.dart` | `const String kPoengRoute = '/bergen/poeng'`, `Widget poengEntryCard(BuildContext)` | The Hjem's Points card calls `Navigator.pushNamed(kPoengRoute)` and renders `poengEntryCard`. The stub renders a placeholder chip. |
| `lib/screens/bergen/poeng/napp_entry.dart` | `class NappOffer`, `Future<void> showNappKort(BuildContext, NappOffer)` | The Hjem's bobbers (agil-1) tap → the card that rises from the water (agil-3). Stub shows a `BergenToast`. |
| `lib/screens/bergen/aegil/aegil_entry.dart` | `const String kAegilRoute = '/bergen/aegil'`, `Widget aegilGreeting(BuildContext)` | The Hjem's Ægil greeting and the Søk · Spør Ægil card push `kAegilRoute`. |
| `lib/screens/bergen/aegil/brett_entry.dart` | `Future<void> showAegilBrett(BuildContext)`, `int aegilFindCount()` | Ægil-relevanskort on Hjem → the suggestion drawer. Stub returns 0; agil-1 hides the card at 0. |
| `lib/screens/bergen/meg/borte_entry.dart` | `Widget? mensDuVarBorteCard(BuildContext)` | The cold-start card on Hjem. Stub returns `null`. |

**Shared files in this repo** (§2.4 rules): `lib/main.dart`,
`lib/screens/common/homeMainV1/home_main_v1.dart`, `pubspec.yaml`, `lib/redux/*`,
`lib/networking/api_constant.dart`. Only agil-1 edits `home_main_v1.dart` after
Sync C; agil-3's screens are reached through the seam files, never by editing
the shell.

### 2.3 Other repos

| Repo | agil-1 (v2) | agil-3 |
|---|---|---|
| `Aerend-Feed` | everything | **nothing — never edit or push this repo** |
| `Hare-Store` (Partner app) | nothing | nothing — **UI out of scope for both plans by decision (2026-09-25)**. The self-delivery Partner screens and the "AI-assistert import" queue need their own later plan; agil-3 lands the endpoints they will call (§5.5) so that plan is pure UI. |
| `Hare-Driver` (Bud app) | nothing | nothing — same decision. "Fra Ærend AI" and the WhatsApp opt-out are backend fields agil-3 exposes. |

### 2.4 Shared files — the complete list

Append-only, one commit per need titled `chore(shared): …`, never a deletion, and
a `MergeReadinessTest`-style assertion on each branch that the file has zero
removed lines relative to the branch point.

Hare-AdminPanel: `routes/api.php`, `routes/web.php` (inside the admin group
only), `app/Console/Kernel.php`, `app/Providers/AppServiceProvider.php`,
`config/app.php` (provider registration), `.env.example` (never `.env` — it is
tracked, and it is where the last merge's only real conflict was),
`public/assets/js/dugnad-i18n.js` (append inside the `DICT` object only;
`AdminI18nDictionaryTest` fails a duplicate key with a different value).

Aerend-app: `lib/main.dart`, `lib/screens/common/homeMainV1/home_main_v1.dart`,
`pubspec.yaml`, `lib/redux/app_state.dart`, `lib/redux/actions.dart`,
`lib/redux/app_state_reducer.dart`, `lib/networking/api_constant.dart`.

---

## 3. The name registry

Everything below is reserved. "Owner" is who builds it. A name not in this
section does not exist yet; add it here before using it.

### 3.1 Frozen baseline — exists today, nobody renames

Tables: `ops_assignment_orders ops_assignments ops_audit_log ops_code_sequences
ops_courier_limits ops_courier_locations ops_courier_shifts ops_courier_verification
ops_delivery_codes ops_delivery_proofs ops_door_profiles ops_exceptions
ops_feature_flags ops_feed_inbox ops_feed_outbox ops_notifications ops_offers
ops_order_events ops_payout_lines ops_payouts ops_pickup_tokens ops_policies
ops_prep_stats ops_problems ops_product_change_log ops_relay_calls
ops_retention_runs ops_run_payments ops_scans ops_store_devices
ops_store_feed_eligibility ops_store_hour_exceptions ops_store_hours ops_store_staff
ops_time_adjustments ops_vaagen_reels` · `pts_audit_log pts_balances pts_donations
pts_event_receipts pts_fraud_flags pts_league_entries pts_league_months
pts_league_prizes pts_ledger pts_mission_templates pts_missions
pts_partner_prize_proposals pts_point_goals pts_policy_versions pts_prize_claims
pts_prizes pts_referrals` · `agents agent_runs agent_settings agent_preferences
agent_actions agent_against_interest_events agent_availability_subscriptions
agent_communications agent_product_identities agent_pushes agent_reference_prices
agent_reminders agent_shopping_list_items agent_suggestion_feedback
agent_suggestions agent_trust_ledger`.

Legacy tables the new work touches (never renamed; columns added only with the
owner's prefix): `user_store_product_booking` (orders), `store_details` (stores),
`providers` (couriers *and* store owners — `delivery_people_id` is a FK to it),
`users` (customers), `store_product_details` (products), `admin_module`,
`super_admin`, `admin_area_list` and `restricted_area` (the old geofence —
read-only after geo cut-over).

Existing `ops_` columns on orders: `ops_code ops_state ops_proof_type ops_origin
ops_source_post_id ops_policy_version ops_promised_start ops_promised_end
ops_predicted_ready_at ops_shelf_slot ops_seen_at`. On stores: `ops_capacity
ops_autodrift_level ops_availability_state ops_paused_until`. Store geometry
today: `store_details.address, address_lat, address_long, service_lat,
service_long`. Courier position today: `ops_courier_locations (courier_id, lat,
lng, accuracy_metres, on_run, recorded_at)`.

State machines (frozen; no new states): `OrderState` `placed accepted seen ready
picked_up arrived_customer delivered cancelled`; `AssignmentState` `offered
accepted en_route_pickup arrived_pickup waiting picked_up en_route_drop
arrived_drop delivered released failed`; `StoreAvailabilityState` `open
paused_manual paused_auto`. **"Finner bud" is not a state** — it is a derived
boolean on the tracking payload (§5.1).

Agents already registered (`agents.name`, seeded disabled): `aegil_customer
onboarding menu_copy photo_enhance photo_qa campaign_planner hours_exceptions
bud_translate bud_problem bud_door bud_explain exception_triage comms
anomaly_explain editorial`. Flags: 31 `ops.*` keys in `SurfaceFlags`, and
`points premiehylla missions league aegil_level_max`. Policy keys: 19 under
`time.* money.* dispatch.* escalation.*` and 16 under `points.*`. Payout line
kinds: `run tip adjustment`. Events (frozen, `docs/EVENT_CONTRACT.md`):
`order.delivered order.cancelled product.price_changed feed.post.published
suggestion.reeled`.

Aerend-app baseline: `BergenHome`, `BergenBottomNav` (four tabs Hjem / Utforsk /
Kurv / Meg, `home_main_v1.dart`), `FeedShellScreen`, `AerendBergenAuthTokens`
(in `reen_pre_club_theme.dart`, renamed in Sync C), `bergen_kit.dart` constants
(`kBergen*`), the `*_copy.dart` pattern (`OnbCopy`, `bergen_copy.dart`), API
bases `BaseUrl.domain + endPointBaseUrlApi + 'points/'` / `'agent/'`,
`ops_feed_api.dart` paths under `api/ops/feed/*`, redux in `lib/redux/*`, feed
bloc in `lib/screens/feed/*`.

### 3.2 Reserved — agil-1 (v2)

| Kind | Name | Notes |
|---|---|---|
| column | `ops_feature_flags.value` | json nullable; Sync C |
| column | `ops_delivery_codes.pin_ciphertext` | text nullable, Laravel `encrypted` cast; Phase 1. The customer's own copy of the PIN for §5.1 `delivery_code.pin` — `pin_hash` cannot give it back. Written by `DeliveryProofService::issueCode`, read only by `CustomerTrackingReadModel`. |
| table | `ops_customer_tracking_views` | who opened tracking when — feeds "Mens du var borte" and the away summary |
| route | `GET /api/ops/customer/orders/{orderId}/tracking` → `ops.customer.tracking` | §5.1 payload |
| route | `GET /api/ops/customer/orders/{orderId}/events?since=` → `ops.customer.tracking.events` | polling fallback |
| route | `POST /api/ops/customer/orders/{orderId}/contact` → `ops.customer.contact` | routes to courier or store by `pd_delivery_actor` |
| route | `POST /api/ops/customer/orders/{orderId}/problem` → `ops.customer.problem` | Finner ikke døra / Noe mangler / Valg som venter (wait or cancel) |
| route | `GET /api/ops/customer/orders` → `ops.customer.orders` | the customer's orders with `ops_*` fields, for Bestillinger and "Bestill igjen" |
| route | `GET /api/ops/customer/away-summary` → `ops.customer.away` | Mens du var borte data (orders half; Ægil half is agil-3) |
| route | `GET /api/ops/search/trending` → `ops.search.trending` | Søk · "Populært nå": product names ordered in the last 7 days, cached 10 min (Phase 3) |
| route | `GET /api/ops/customer/categories/{slug}/pulse` → `ops.customer.categories.pulse` | Kategori live strip: orders with an event in the last hour for the category's stores, and open stores (Phase 4) |
| route | `GET /api/ops/customer/stores/{storeId}/presence` → `ops.customer.stores.presence` | "N kikker nå": distinct customers with a tracking view on the store's orders in the last 10 min (Phase 4) |
| route | `POST /api/ops/customer/orders/{orderId}/code` → `ops.customer.code` | "Kode ved levering": the customer asks for a delivery code on their own order (`DeliveryProofService::assignProof` with `customer_requested_code`); 422 `CODE_TOO_LATE` after `ready` (Phase 5) |
| route | `POST /api/ops/proof/orders/{orderId}/pin` → `ops.proof.pin` | the courier types the customer's PIN (`DeliveryProofService::verifyPin`): 200 ok, 422 `WRONG_PIN` / `CODE_LOCKED`; used by the Bud app and the customer app's debug demo panel (Phase 6) |
| class | `App\Services\Ops\OrderIntakeService` + `LegacyOrderObserver` | a legacy booking enters the machine at creation: `order.placed` event, `ops_origin`, `ops_policy_version`, `ops_code`; the observer is one append in `AppServiceProvider` (Phase 5) |
| flag | `ops.customer.sok`, `ops.customer.butikk`, `ops.customer.kasse`, `ops.customer.sporing`, `ops.customer.utforsk` | one per screen group, off by default |
| console | `ops:contract-check` | runs the `ContractNamesTest` assertions as a command for merge day |
| interface | `App\Ops\Dispatch\CandidateSource` (`candidates(int $storeId, Carbon $now): array`) with `OpsCandidateSource` | Sync C |
| Dart | `lib/screens/bergen/kit/*`, `lib/screens/bergen/bergen_routes_agil1.dart`, `lib/screens/bergen/{sok,butikk,kasse,sporing,utforsk,hjelp}/*`, `lib/networking/ops/ops_customer_api.dart`, `lib/data/ops/tracking_models.dart`, `lib/theme/bergen_tokens.dart` | |
| copy | `lib/screens/bergen/<group>/<group>_copy.dart`, class `<Group>Copy`, keys `a1_<group>_*` | moved to ARB in Phase 8 as `ops_<group>_*` |
| env | none new | |

### 3.3 Reserved — agil-3

**Agent proposal substrate and Agents A / B / C** (`aerend-ai-agents-spec.docx`):

| Kind | Name | Spec name |
|---|---|---|
| table | `agtp_proposals` | `agent_proposal` — the shared record, spec §3 |
| table | `agtp_courier_consents` | `courier_contact_consent` |
| table | `agtp_courier_outreach` | `courier_outreach_log` |
| table | `agtp_settlement_batches`, `agtp_settlement_lines` | `settlement_batch` / `settlement_line` |
| table | `agtp_product_drafts` | "existing staging queue" — there is no staging table in this repo; this is it |
| table | `agtp_content_authorizations` | "partner content authorization record" (domain, scope, expiry, signed document ref) |
| table | reuse `agent_runs` | spec's `agent_run_log` — do not create a second run log |
| table | reuse `agents` + `agent_settings` | spec's `agent_config`: kill switch is `agents.enabled`; thresholds are `agent_settings` rows keyed `agt.<agent>.<threshold>` |
| agents.name | `product_onboarding`, `courier_comms`, `payment_sorting`, `geo` | spec keys `agent_product_onboarding` etc.; the `agent_` prefix is dropped because the column already is the agents table |
| enum | `agtp_proposals.status` ∈ `proposed approved rejected expired executed failed` | spec §3, frozen |
| enum | `agtp_proposals.proposal_type` ∈ `product_draft courier_outreach settlement_batch geo_placement geo_zone_change geo_eligibility geo_communication geo_launch_brief` | |
| column | `agtp_proposals.idempotency_key` unique | `agent_key + subject + trigger window` |
| flag | `agt.product_onboarding`, `agt.courier_comms`, `agt.courier_comms.auto_approve`, `agt.payment_sorting`, `agt.geo` | via `SurfaceFlags::register()`; all off |
| policy | `agt.courier_comms.t1_minutes` (3), `agt.courier_comms.t2_minutes` (2), `agt.courier_comms.k_per_wave` (3), `agt.courier_comms.w_waves` (2), `agt.courier_comms.quiet_hours` (`["22:00","07:00"]`), `agt.proposal_ttl_hours` (24), `agt.payment_sorting.cadence` (`weekly`), `agt.product_onboarding.bulk_threshold` (0.9), `agt.product_onboarding.first_approval` (`aerend`) | seeded by `agentops:seed-policies` |
| 422 codes | `AGTP_TERMINAL`, `AGTP_NO_AUTHORIZATION`, `AGTP_DENYLISTED_DOMAIN`, `AGTP_SCOPE`, `AGTP_DISABLED` (403) | in `App\Services\AgentOps\AgentOpsException` (added agil-3 Phase 0/3) |
| route (Phase 3) | `POST /api/agentops/imports` → `agentops.imports.store`, `GET imports/{importRef}/drafts` → `agentops.imports.drafts`, `POST imports/{importRef}/approve-bulk` → `agentops.imports.bulk`, `POST drafts/{id}/approve` → `agentops.drafts.approve`, `POST drafts/{id}/reject` → `agentops.drafts.reject` | the Partner app's AI-assisted import (UI deferred); `agtp_product_drafts.import_ref` groups one import |
| env | `AGENTOPS_API_TOKEN_PRODUCT_ONBOARDING`, `AGENTOPS_API_TOKEN_COURIER_COMMS`, `AGENTOPS_API_TOKEN_PAYMENT_SORTING`, `AGENTOPS_API_TOKEN_GEO`, `AGENTOPS_WHATSAPP_PROVIDER` (`none`), `AGENTOPS_SLACK_WEBHOOK`, `AGENTOPS_KASSAL_API_KEY` | read only in `config/agentops.php` |
| route file | `routes/api_agentops.php`, prefix `/api/agentops`, names `agentops.*` | `POST proposals`, `GET proposals/{id}`, `POST proposals/{id}/decide`, `POST runs`, `GET config/{agent}` — the scoped Agent API; **added agil-3 Phase 2:** `GET settlements/partner/{storeId}` → `agentops.settlements.partner`, `GET settlements/courier/{courierId}` → `agentops.settlements.courier` (party-facing read APIs, UI deferred) |
| admin | `/admin/agentsenter` → `Admin\AgentOpsAdminController`, views `super_admin/agentops/*`, nav parent `Agentsenter` (module_name `agentsenter`) | "Agent centre" |
| console | `agentops:run {agent}`, `agentops:expire-proposals`, `agentops:seed-policies`, `agentops:settle {period}` | |
| route (Phase 6) | `GET /api/agentops/offers/{id}/badge` → `agentops.offers.badge` (`agent_offer_from_ai`), `POST /api/agentops/couriers/{id}/whatsapp-consent` → `agentops.couriers.consent` | Bud app fields, UI deferred |
| copy keys (spec §7, verbatim) | `agent_badge_proposed`, `agent_offer_from_ai`, `order_status_finding_courier`, `courier_pref_whatsapp_alerts`, `settlement_status_proposed/_approved/_paid`, `import_status_draft/_approved/_rejected` | agil-3 uses them as keys in its `*_copy.dart`; agil-1 writes them into ARB in Phase 8 under exactly these names |
| payout line kind | `delivery_income` | §5.2 |
| event | `agent.proposal_decided` v1 | §5.3 |

**Geo & coverage** (`aerend-geo-coverage-spec.docx`):

| Kind | Name | Spec name |
|---|---|---|
| table | `geo_country_packs`, `geo_regions`, `geo_zones`, `geo_zone_cells`, `geo_store_locations`, `geo_store_footprint_cells`, `geo_courier_homes`, `geo_courier_zone_eligibility`, `geo_courier_presence`, `geo_unmet_demand`, `geo_override_log` | one-to-one with spec §11 |
| column | `*.cell` varchar(16) — **not** `h3`. The monolith is MySQL; the spec's "PostGIS + H3" assumes Postgres. The scheme is the policy `geo.cell_scheme` ∈ `h3_r9 geohash_7`, decided in agil-3 Phase 5 Chunk 0: `h3_r9` only if a maintained PHP binding is available, otherwise `geohash_7` (≈153 m × 153 m, the closest built-in equivalent to H3 r9's ~0.1 km²). Every `cell` column uses the same scheme; `geo_country_packs.cell_scheme` records it. | spec §2.1 "H3 hexagon, resolution 9" |
| enum | `geo_zones.status` ∈ `draft active paused`; `geo_store_locations.placement_state` ∈ `placed waiting_zone outside_region`; `geo_courier_zone_eligibility.source` ∈ `home adjacent auto_extended approved` | frozen |
| flag | `geo.engine` (shadow), `geo.engine.cutover`, `geo.customer.coverage`, `geo.courier.eligibility`, `geo.admin.omrader` | all off |
| policy | `geo.cell_scheme` (`geohash_7`), `geo.max_travel_min` (25), `geo.flat_fee_ore` (2900), `geo.auto_extend_adjacent_only` (true), `geo.presence_retention_days` (30), `geo.auto_apply_templates` (true) | seeded by `geo:seed-policies` |
| env | `GEO_GEOCODER` (`kartverket`), `GEO_GEOCODER_FALLBACK` (`none`), `GEO_KARTVERKET_BASE_URL`, `GEO_BRREG_BASE_URL` | read only in `config/geo.php` |
| route file | `routes/api_geo.php`, prefix `/api/geo`, names `geo.*` | `GET coverage?lat=&lng=` (customer), `POST waitlist`, `GET zones`, `POST stores/{id}/place`, `POST stores/{id}/confirm-pin`, `POST couriers/{id}/home`, `GET couriers/{id}/zones` |
| admin | `/admin/omrader` → `Admin\GeoAdminController`, views `super_admin/geo/*`, nav parent `Områder` (module_name `omrader`) | |
| console | `geo:import-legacy-areas`, `geo:recompute-footprints`, `geo:seed-policies`, `geo:shadow-compare`, `geo:prune-presence` | |
| service | `Geo\GeoCandidateSource implements App\Ops\Dispatch\CandidateSource` | the dispatch seam |
| event | `geo.zone_changed` v1 | §5.3 |

**Partner self-delivery** (`aerend-partner-self-delivery-spec.docx`):

| Kind | Name | Spec name |
|---|---|---|
| column on `store_details` | `pd_can_self_deliver` (bool, false), `pd_suggest_self_delivery` (bool, false), `pd_suggest_courier` (bool, true), `pd_self_delivery_radius_km` (decimal nullable), `pd_approved_by_aerend` (bool, false) | `partner.*` §2.1 |
| column on `user_store_product_booking` | `pd_delivery_actor` ∈ `aerend_courier partner` (default `aerend_courier`), `pd_store_eta_minutes` (int nullable), `pd_delivered_without_code` (bool, false), `pd_delivered_without_code_reason` (string nullable) | `order.*` §10 |
| table | `pd_actor_changes` | `delivery_actor_change_log` |
| derived | `delivery_mode` ∈ `courier_only self_only per_order` — **computed, never stored** | §2.1 |
| flag | `pd.self_delivery`, `pd.customer.tracking_variant` | off |
| policy | `pd.default_store_eta_minutes` (20), `pd.reminder_after_ready_minutes` (10), `pd.require_aerend_approval` (true), `pd.driver_pin_enabled` (false) | seeded by `pd:seed-policies` |
| route file | `routes/api_partner_delivery.php`, prefix `/api/partner-delivery`, names `pd.*` | `GET/POST settings`, `POST orders/{id}/actor`, `POST orders/{id}/on-the-way`, `POST orders/{id}/delivered`, `GET orders/{id}/delivery-view` |
| 422 codes | `PD_MIN_ONE_MODE` ("Minst én leveringsmåte må være på"), `PD_COURIER_ALREADY_ACCEPTED` ("Et bud har allerede tatt ordren"), `PD_OUTSIDE_RADIUS`, `PD_ON_THE_WAY_ALREADY`, `PD_PARTNER_DELIVERS` | |
| admin | `/admin/egenlevering` → `Admin\PartnerDeliveryAdminController`, views `super_admin/partner_delivery/*`, nav child `Egenlevering` under agil-1's `Ærend Drift` parent (found by `module_name = 'drift'`; agil-3's own migration inserts the child row) | |
| console | `pd:remind-on-the-way`, `pd:seed-policies` | |
| event | `order.delivery_actor_changed` v1 | §5.3 |

### 3.4 Reserved — Aerend-app route names and copy keys

All route names start with `/bergen/`. agil-1: `/bergen/sok`, `/bergen/butikk/{id}`,
`/bergen/kategori/{slug}`, `/bergen/automat`, `/bergen/kurv`,
`/bergen/bestilling/{id}`, `/bergen/sporing/{id}`, `/bergen/sporing/{id}/hjelp`,
`/bergen/levert/{id}`, `/bergen/utforsk`, `/bergen/kundeservice`. agil-3:
`/bergen/poeng`, `/bergen/premiehylla`, `/bergen/premie/{id}`, `/bergen/liga`,
`/bergen/opprykk`, `/bergen/fjordfiske`, `/bergen/aegil`, `/bergen/aegil/minne`,
`/bergen/meg`, `/bergen/meg/favoritter`, `/bergen/meg/konto`,
`/bergen/meg/bestillinger`, `/bergen/meg/varsler`. Nobody registers a route
outside their list without adding it here.

Copy keys: `a1_*` on agil-1, `a3_*` on agil-3, in `*_copy.dart` files only. The
spec §7 status keys in §3.3 are the one exception and are used verbatim.

---

## 4. The enforcement

### 4.1 `ContractNamesTest` — one test, both branches

`tests/Feature/Contract/ContractNamesTest.php` (owned by agil-1, created in Sync
C, never edited by agil-3) loads every `tests/fixtures/contract/names.*.json` it
finds and asserts each entry against reality:

| Registry kind | Assertion |
|---|---|
| `table` | `Schema::hasTable(name)` **if** the entry's `branch` is the current branch or the tree contains the other branch (`git merge-base --is-ancestor`); otherwise skipped with a message naming the entry |
| `column` | `Schema::hasColumn(table, name)`, same rule |
| `route` | `Route::has(name)` |
| `flag` | `SurfaceFlags::isKnown(key)` (after Sync C this includes registered keys) |
| `policy` | the key is in the owning `*PolicyKeys::all()` |
| `console` | `Artisan::all()` contains it |
| `agent` | an `agents.name` row exists after the seeder |
| `enum` | the class constant list equals the registry list exactly |
| `env` | a config key reads it (grep `config/`) and `.env.example` names it |
| `event` | `docs/EVENT_CONTRACT.md` names it and `tests/fixtures/events/<type>.json` exists |
| `no-literal` | grep of `app/` finds no string literal equal to any registered table name outside its own model file — the defect-#1 guard |
| `no-after` | grep of `database/migrations/2026_1*` finds no `->after(` |
| `dart` | in Aerend-app: `test/contract/contract_names_test.dart` asserts every registered route name is a key of the branch's route map and every seam file exports its declared symbols |

Each branch keeps the test green for its own entries before every commit. On
merge day the whole registry is asserted at once with no skips.

### 4.2 Registry file shape

```json
{ "branch": "agil-3", "entries": [
  { "kind": "table",  "name": "agtp_proposals", "model": "App\\Models\\AgentOps\\Proposal", "spec": "aerend-ai-agents-spec §3" },
  { "kind": "column", "table": "user_store_product_booking", "name": "pd_delivery_actor", "guard": "hasColumn" },
  { "kind": "route",  "name": "pd.orders.actor", "method": "POST", "path": "/api/partner-delivery/orders/{id}/actor" },
  { "kind": "flag",   "name": "pd.self_delivery", "default": false },
  { "kind": "policy", "name": "pd.default_store_eta_minutes", "default": 20, "owner": "App\\Services\\PartnerDelivery\\PdPolicyKeys" },
  { "kind": "enum",   "class": "App\\Models\\PartnerDelivery\\DeliveryActor", "values": ["aerend_courier","partner"] },
  { "kind": "event",  "name": "order.delivery_actor_changed", "version": 1 },
  { "kind": "dart",   "route": "/bergen/poeng", "file": "lib/screens/bergen/bergen_routes_agil3.dart" }
] }
```

A registry entry is the *first* artifact of any task that creates a name, and
`ContractNamesTest` is green with it *skipped* (not yet built) before it is
green *asserted* (built).

### 4.3 What each branch must never do

- Edit a file in the other branch's ownership column. If a change is needed
  there, write it under "Asks of the other branch" in your plan and keep going.
- Read a cross-branch table or column by literal, or without a guard.
- Create a second copy of a thing that exists: no new run log, no new policy
  table, no new flag mechanism, no new notification queue, no new order state,
  no new sheet component.
- Touch `lib/l10n/*` (agil-3: ever; agil-1: before Phase 8).
- Edit `.env`. Only `.env.example`, append-only.

---

## 5. Cross-branch payload contracts

### 5.1 Customer tracking payload — served by agil-1, includes agil-3 fields

`GET /api/ops/customer/orders/{orderId}/tracking`, for the signed-in customer's
own order:

```json
{
  "order_id": "8f2c0001", "code": "Æ-42K",
  "mode": "delivery",
  "state": "picked_up", "stage": 2, "stage_label": "På vei",
  "promised_start": "2026-09-25T18:12:00+02:00", "promised_end": "2026-09-25T18:22:00+02:00",
  "adjusted_by_minutes": 0,
  "delivery_actor": "aerend_courier", "delivered_by_label": "Bud",
  "finding_courier": false,
  "courier": { "first_name": "Jonas", "avatar_url": null, "verified": true, "vehicle": "sykkel" },
  "store": { "id": 45, "name": "Sandviken Bakeri", "address": "Bryggen 7" },
  "contact": { "call_target": "courier", "message_target": "courier" },
  "delivery_code": { "pin": "4821", "reason_copy_key": "a1_sporing_kode_reason_default", "qr_payload": "…" },
  "live_position": null,
  "unseen_by_store": false,
  "policy_version": 12,
  "events_since": 4471
}
```

- `mode` ∈ `delivery pickup`; stage labels follow the prototype (Bekreftet ·
  Tilberedes · På vei · Levert, or Bekreftet · Tilberedes · Klar for henting ·
  Hentet).
- `stage` ∈ 0..3 is derived server-side from `state` **and** `delivery_actor`:
  for `partner`, 0 = placed / accepted / seen, 1 = ready, 2 = picked_up (the
  store marked "På vei"), 3 = delivered; `arrived_customer` is 2 for both actors.
  The app never derives the stage itself.
- `delivery_actor` is `pd_delivery_actor` read with `Schema::hasColumn`; absent
  column → `aerend_courier`.
- `delivered_by_label` is `Bud` for a courier and the store name for a partner.
  `courier` is `null` whenever `delivery_actor == partner` — spec §5 "Leveres av
  [butikknavn]", no courier name, no avatar.
- `finding_courier` is `true` when `state ∈ {accepted, seen, ready}`,
  `delivery_actor == aerend_courier`, no `ops_assignments` row at `accepted` or
  later exists for the order, and an `agtp_proposals` row of type
  `courier_outreach` for the order is `approved` or `executed` within the last
  `t1 + t2 × w` minutes. Read with table guards; never true for a partner order.
- ETA for `partner` comes from `pd_store_eta_minutes` added to the "På vei"
  event's `occurred_at`, rendered as the same time range.
- `contact.*_target` is `store` for partner orders and whenever
  `state ∈ {placed, accepted, seen, ready}`; `courier` otherwise. "Finner ikke
  døra" and "Noe mangler" post to `ops.customer.problem` and route the same way.
- `live_position` is `null` for partner orders in v1 — never a fake position.
- `unseen_by_store` drives "Valg som venter" (`ops_seen_at` null past the first
  escalation rung).

### 5.2 Settlement lines

`ops_payout_lines.kind` gains `delivery_income` (agil-3 writes it via
`agtp_settlement_lines` → execution through the existing payout mechanism).
Partner Oppgjør reads it through `SettlementService` by kind. The framing rule
travels with the row: `description` is `Leveringsinntekt · Du beholder {kr} kr`.

### 5.3 New events — `docs/EVENT_CONTRACT.md` extension (Sync C)

| Event | Emitter | Consumers | Payload keys (v1) |
|---|---|---|---|
| `order.delivery_actor_changed` | agil-3 `PartnerDelivery\ActorService` | agil-1 tracking; agil-3 dispatch skip and courier comms skip | `order_id, from, to, changed_by_type, changed_by_id, reason` |
| `geo.zone_changed` | agil-3 `Geo\ZoneService` | agil-1 customer coverage cache; notifications | `zone_id, region_id, change ∈ {created,extended,paused,resumed}, cells_added[], cells_removed[], proposal_id` |
| `agent.proposal_decided` | agil-3 `AgentOps\ProposalService` | admin activity feed; Slack | `proposal_id, agent_key, proposal_type, status, decided_by_type, decided_by_id` |

Fixtures at `tests/fixtures/events/<type>.json`; `EventContractTest` extended
the same way as the five existing events.

### 5.4 Seam types — Aerend-app

`NappOffer` (in `napp_entry.dart`; agil-3 owns the file, agil-1 constructs it):
`{ String id; String title; String storeName; int priceOre; String reason; String kind /* tilbud | ny | rytme */; }`.
The Hjem passes what the bobber knows; the card fetches the rest by `id` from
`GET /api/agent/suggestions/{id}` (agil-2's existing route).

`aegilFindCount()` returns the number the Hjem's Ægil-relevanskort shows; the
stub returns 0 and agil-1 hides the card at 0.

### 5.5 Partner-app endpoints agil-3 must land (UI deferred)

So the later Partner plan is pure UI, agil-3 ships and feature-tests: settings
read/write with the 422 rule; per-order actor choice with the switching rules;
`on-the-way` (writes `pd_store_eta_minutes`; the order transitions
`ready → picked_up` through `OrderTransitionService` with `actor_type = store`);
`delivered` requiring the PIN through `DeliveryProofService`, or
`without_code + reason`; the `delivery-view` read model. **No new order states,
no bypass of the transition service.**

### 5.6 Dispatch and courier comms must skip partner orders

`DispatchService::createAssignment` and `offer` (agil-1, via the `CandidateSource`
seam's `eligible()` check) and `agtp` courier outreach (agil-3) all read
`pd_delivery_actor` (guarded) and refuse `partner` orders with 422
`PD_PARTNER_DELIVERS`. Asserted in `DispatchTest` (agil-1 — the guard degrades
to allow when the column is absent) and `PartnerDelivery/DispatchSkipTest`
(agil-3 — the column is present).

---

## 6. Merge day — agil-3 into agil-1

Executed by the agil-1 agent at the start of its Phase 8, or by a human.

1. On `agil-3`: `scripts/rebuild_test_db.sh && php artisan test` green;
   `flutter test` green in Aerend-app; `ContractNamesTest` green with no skips
   for `agil-3` entries; `git diff --name-only agil-1...agil-3` contains no file
   outside §2's agil-3 columns except §2.4 appends.
2. On `agil-1`: same, for agil-1 entries.
3. `git merge-tree --write-tree agil-1 agil-3` — the only conflicts permitted are
   in §2.4 shared files, and each must be append-vs-append. Anything else is a
   contract breach: fix it on `agil-3` first; do not resolve it in the merge.
4. `git merge --no-ff agil-3` on `agil-1`; `php artisan migrate` on the test DB;
   `ContractNamesTest` with **no skips at all**; full suites in both repos.
5. `EventContractTest` for all eight events; `MergeIntegrationTest` still green;
   `DispatchTest` and `PartnerDelivery/DispatchSkipTest` both green — the
   guarded column now exists, so the guard is exercised in its "present" branch.
6. Flip nothing. Every new flag is off; `ops:flags list` shows it.
7. Then agil-1 Phase 8: copy → ARB, `flutter gen-l10n`, `AdminI18nDictionaryTest`.

**Nothing in this procedure pushes or merges to `main` or `master`.**

---

## 7. Checkbox semantics — identical in both plans

- `[ ]` not started. `[~]` built but an acceptance test is red or a name is
  registered-but-skipped. `[x]` acceptance tests green **and** the registry
  entry asserted, not skipped, on this branch. A `[x]` with a caveat is a `[~]`.
- A task that creates a name is not `[x]` until the name is in this file *and*
  in the registry file *and* asserted by `ContractNamesTest`.
- Blocked tasks are written `[ ] **BLOCKED — <why>. Unblocks when: <what>.**`
  and the agent moves to the next independent task.
- Every phase ends with: run its acceptance list, commit with the phase in the
  message, tick, continue. No summaries to the user between phases.
- A screen is `[x]` only when it is **reachable from the running app by a
  route in the branch's route map**, renders with real data from the named
  endpoint, and has been compared side by side with its `data-screen-label`
  block in the design file with the differences listed in the plan. A widget
  test alone never ticks a screen — 666 green widget tests on the previous
  branches proved nothing about reachability.
