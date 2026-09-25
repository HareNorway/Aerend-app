# AGIL-1 v2 — the customer's ærend, end to end (agent execution plan)

**Branch:** `agil-1` (continues; the integration branch). Base: the commit that
carries `plans/AGIL-CONTRACT.md`.
**Contract:** `plans/AGIL-CONTRACT.md` — **read it first; it is binding and it
wins over this file.** Its §7 defines what a tick means.
**Sister plan:** `plans/AGIL-3-PLAN.md` (branch `agil-3`, the three new specs'
backends and the Points / Ægil / Meg screens). Merge day is contract §6.
**Predecessors (read for state, not for tasks):** `plans/AGIL-1-PLAN.md`,
`plans/AGIL-2-PLAN.md`, `plans/AGIL-1-REMAINING.md` (the record of what was
and was not done as of 2026-09-25).
**Design (the fasit for every screen here):** `designs/21des/Ærend Kunde Bergen.dc.html`.
**Specs:** `aerend-app/docs/AEREND ORDER OPS SPEC FINAL STATEv3.md` (order and
tracking behaviour), `aerend-app/docs/aerend-partner-self-delivery-spec.docx` §5
(the customer-app requirements — functional, not optional), `aerend-app/docs/aerend-geo-coverage-spec.docx` §4
(customer coverage), `aerend-app/docs/aerendvstore feed update spec.md`.

> 🛑 **Branch policy.** Nothing goes into `main` or `master` in any repo, and
> nothing is pushed unless a human says so. UI work is **Aerend-app only** —
> Hare-Store and Hare-Driver are out of scope for both plans by decision.

---

## 0. Agent operating instructions

**How to read the design file.** It is one 10,691-line HTML prototype. Do not
read it whole. Map it, then read blocks:

```
grep -n 'data-screen-label=' "designs/21des/Ærend Kunde Bergen.dc.html"   # 71 markers
grep -n "skjerm === '" "designs/21des/Ærend Kunde Bergen.dc.html"          # the real screens
grep -n '<symbol id=' "designs/21des/Ærend Kunde Bergen.dc.html"           # SVG assets
```

The labels are mostly *components and states*; the real screens are the values
of `st.skjerm` (`hjem sok agent butikk kategori utforsk automat kurv sporing
levert meg opprykk premier velger liga fiske feed favoritter konto
bestillinger`) plus the sheets under `visSheet` / `arkAapent` / `sheetHjelp`.
The line ranges in each phase below are from the 2026-09-25 inventory; verify
them with grep before relying on them — the file may have moved.

Three blocks are **dead** and must not be implemented: the `aldri` search overlay
(≈L4229–4388), `erSporingV1` (≈L5779–5880, flag never defined), and the
`visRelGammel` / `gammelUtstilling` variants.

**Copy, not ARB.** Every string a screen shows goes in that group's
`<group>_copy.dart` as `A1Copy.<group>.<key>` (NO and EN), keys prefixed
`a1_<group>_`. `lib/l10n/*` is untouched until Phase 8 (contract rule 9).

**Tokens.** After Phase 0, colours and type come from `lib/theme/bergen_tokens.dart`
(`BergenTokens`) and `lib/screens/bergen/kit/`. The design declares no CSS
variables; its palette is inline hex. The inventory's counts: ink `#23201D`,
fjord teal `#1E4F5C` (+ gradient partner `#2A6272`), mint `#5CE0B8`, orange
`#F26D3D` (ramp `#F9A273 #F58A55 #E95C2C #DD5A25 #C4491A`), lantern `#F2C14E`,
secondary text `#57534B`, muted `#6E6862 #8C847C`, paper `#F5F3EF #E9E2D2
#FBFAF6`, body `#E2DFD8`, deep teal `#173E48 #0F1F2B`, sea day `#9FC3CC` /
evening `#3D6B7A` / rain `#6F8790`. Font: Plus Jakarta Sans 200–800 (variable
weight animates); Inter 400–700 twice. Reduced motion is honoured
(`prefers-reduced-motion` kill-switch in the design → `MediaQuery.disableAnimations`).

**Data.** Laravel through `lib/networking/*` (`BaseUrl.domain + endPointBaseUrlApi`),
ops endpoints under `api/ops/...` the way `ops_feed_api.dart` already does. The
feed service through `lib/networking/feed/*` (unchanged). Redux app-wide
(`lib/redux/*`, shared file — append only), bloc inside feed. New screen state is
local bloc/`ChangeNotifier` per screen; only cart and address touch redux.

**Commands for acceptance.**
- Backend: `cd D:/work/hare/Hare-AdminPanel && bash scripts/rebuild_test_db.sh && php artisan test --filter=<X>`; `php artisan route:list --path=api/ops/customer`; `php artisan test --filter=ContractNamesTest`.
- Flutter: `cd D:/work/hare/aerend-app/Aerend-app && flutter analyze lib/ && flutter test && flutter test test/contract`.
- Reachability, every screen phase: `grep -rn "<ScreenClass>(" lib/ --include=*.dart | grep -v "<its own file>"` must show the route map or a parent; and `flutter test test/contract/contract_names_test.dart` asserts every route in `bergen_routes_agil1.dart` builds.
- Design comparison, every screen: open the design block beside the running app; list the differences in the phase's "Design ledger" table. A screen with an empty ledger row is not compared.

**Conventions.** One commit per task group, message starting with the phase.
Shared files: contract §2.4. Blocked tasks: contract §7. Do not summarise to the
user between phases; stop only when the plan is done or fully blocked.

---

## 1. Ownership (summary — the contract is the source)

agil-1 owns in Aerend-app: `lib/screens/bergen/{kit,sok,butikk,kasse,sporing,utforsk,hjelp}/`,
`lib/screens/common/home/bergen/`, `lib/screens/feed/`, `lib/networking/ops/`,
`lib/networking/feed/`, `lib/data/{feed,ops}/`, `lib/theme/bergen_tokens.dart`,
the shell `home_main_v1.dart` (after Sync C), `lib/l10n/` (Phase 8 only). In
Hare-AdminPanel: `ops_*`, `app/Services/Ops`, `Ops/*` controllers, `api_ops.php`,
`tests/Feature/Ops`, `tests/Feature/Contract/ContractNamesTest.php`. All of
Aerend-Feed.

agil-1 does **not** touch: `lib/screens/bergen/{poeng,aegil,meg}/`,
`lib/screens/{points,aegil,snurre}/`, anything `agtp_ geo_ pd_`, `api_points.php`,
`api_agent.php`, Hare-Store, Hare-Driver. Needs there go under "Asks of agil-3".

---

## Phase 0 — Contract & substrate → `sync-C`

Everything agil-3 must inherit before it branches. Small, mechanical, tagged.

**Backend**
- [x] `2026_10_01_000000_ops2_add_value_to_feature_flags`: `ops_feature_flags.value` json nullable. `App\Points\FeatureFlags::raw()` reads `ops_feature_flags` (via `FeatureFlag::TABLE`), `value` when present else `enabled` cast to bool; `aegil_level_max` reads `value`. `ops:flags on/off` writes both. Delete the config fallback's "table missing" branch only after `MergeReadinessTest::every_rollout_flag_defaults_off` still passes with config cleared. **This closes remaining-defect #6.**
- [x] `SurfaceFlags::register(array $flags)` — static registry merged into `FLAGS`/`forStage()`/`isKnown()`; `ops:flags seed` seeds registered keys too. Test: a registered `zz.test` key seeds off, lists, flips, and `isKnown` is true.
- [x] `App\Ops\Dispatch\CandidateSource` (`candidates(int $storeId, Carbon $now): array`, `eligible(int $orderId): bool`) + `OpsCandidateSource` (today's logic lifted out of `DispatchService` unchanged) bound in `AppServiceProvider`; `DispatchService` calls it. `eligible()` reads `pd_delivery_actor` with `Schema::hasColumn` and returns true when absent. `DispatchTest` green unchanged, plus one test that a fake `CandidateSource` returning `false` makes `createAssignment` refuse with `PD_PARTNER_DELIVERS`.
- [x] `docs/EVENT_CONTRACT.md`: add `order.delivery_actor_changed`, `geo.zone_changed`, `agent.proposal_decided` (v1) per its versioning rule; fixtures in `tests/fixtures/events/`; `EventContractTest` cases that validate the fixtures' shape (no emitter yet — agil-3 emits).
- [x] `tests/fixtures/contract/names.agil1.json` with every §3.2 entry; `names.agil3.json` with every §3.3 + §3.4 agil-3 entry (**agil-1 writes both files once**, agil-3 owns the second afterwards). `tests/Feature/Contract/ContractNamesTest.php` per contract §4.1, including the `no-literal` and `no-after` greps. Green with agil-3 entries *skipped*.
- [x] `ops:contract-check` console wrapper.

**Aerend-app**
- [x] `git mv lib/theme/reen_pre_club_theme.dart lib/theme/bergen_tokens.dart`; class stays `AerendBergenAuthTokens`, add `BergenTokens` (the palette above, sea modes, type scale, radii, motion durations) in the same file; fix the 24 imports; `assets/Logo/reen-mark-coral.png` → `aerend_mark_coral.png`, `assets/Logo/reen/mark-coral-navy.png` → `assets/Logo/aerend_mark_navy.png`, pubspec entry updated, one visual check that the feed header mark is the Bergen Æ. Delete `test_app/`. **This closes the Reen naming debt.**
- [x] `lib/screens/bergen/kit/`: `bergen_tokens` re-export, `BergenArk` (the generic `Ark {{ kArkTittel }}` sheet, design ≈L7332–7559: title, subtitle, close, optional copy block with Kopier, list rows, secondary + primary CTA; body is a slot), `BergenSheet` (draggable bottom sheet with the handle-text states "Alle butikker og varer / Slipp — Ægil åpner / Lukk vinduet"), `BergenChip`, `BergenCta3d` (the orange 3D button), `BergenToast`, `BergenUndoPill` ("Angre"), `BergenOfflineBanner` ("Uten nett · viser siste kjente status"), `BergenCard`, `BergenStepper` (4 steps). Widget tests for each.
- [x] Seam files exactly as contract §2.2, all as **stubs**: `bergen_routes_agil3.dart` (empty map), `meg/meg_host.dart` (`MegScreen` → `Account()`), `poeng/poeng_entry.dart`, `poeng/napp_entry.dart`, `aegil/aegil_entry.dart`, `aegil/brett_entry.dart`, `meg/borte_entry.dart`. `bergen_routes_agil1.dart` (empty map).
- [x] `chore(shared): wire bergen route maps and MegScreen` — `main.dart` spreads both route maps into `MaterialApp.routes`; `home_main_v1.dart` tab 3 renders `MegScreen()`. One append each.
- [x] `test/contract/contract_names_test.dart`: every route in both maps builds without throwing; every seam file exports its declared symbols (reflection-free: import and reference).
- [x] Demo panel scaffold `lib/screens/bergen/hjelp/demo_panel.dart` behind `kDebugMode` (5-tap on the Hjem wordmark, design ≈L7565): lists scenario triggers as no-ops now; later phases register real triggers. Compiled out of release.

**Acceptance**
- [x] `php artisan test` → previous count + new tests, still the same 6 pre-existing unit failures and nothing else; `ContractNamesTest` green (agil-3 entries skipped); `ops:flags list` shows `value` column in play; `MergeReadinessTest` green.
- [x] `flutter analyze lib/` 0 errors; `flutter test` green (321 + kit + contract tests); `grep -rl reen_pre_club_theme lib/` empty.
- [x] `git tag sync-C` on the phase commit. Write the tag hash into contract §1.

---

## Phase 1 — Customer tracking API (backend)

The app currently reads **no** `ops_state` anywhere. Sporing needs one endpoint
that already knows about self-delivery and "Finner bud".

- [x] `2026_10_01_010000_ops2_create_customer_tracking_views`: `ops_customer_tracking_views (id, user_id, order_id, viewed_at)`; model `App\Models\Ops\CustomerTrackingView` with `TABLE`.
- [x] `App\Services\Ops\CustomerTrackingReadModel::tracking(int $userId, int $orderId): array` producing exactly contract §5.1: `stage` derived from `state` × `delivery_actor`; `delivery_actor` from `pd_delivery_actor` guarded; `courier` null for partner; `finding_courier` per the four-condition rule with `agtp_proposals` guarded by `Schema::hasTable`; ETA for partner from `pd_store_eta_minutes` + the `picked_up` event's `occurred_at`; `contact.*_target`; `live_position` from `ops_courier_locations` for courier orders only; `unseen_by_store`. Records a `ops_customer_tracking_views` row.
- [x] `App\Http\Controllers\Ops\CustomerController` + routes in `api_ops.php` under `customer/`: `tracking`, `tracking.events` (delegates to the existing events feed filtered to the order), `contact` (creates an `ops_relay_calls` row or a message row via the existing relay/notification services, target by contract rule), `problem` (`kind ∈ {door, missing, wait, cancel}` → `ProblemService::report` with `WRONG_ADDRESS` / a new problem *payload* not type; `cancel` → `OrderTransitionService` to `cancelled` with `actor_type = customer`, refused after `ready`), `orders` (the customer's orders with `ops_*` columns for Bestillinger and "Bestill igjen"), `away-summary` (orders delivered / changed since the last tracking view). All under the app's existing customer auth middleware (find it on `api_points.php`'s `me/*` routes and reuse it).
- [x] Tests `tests/Feature/Ops/CustomerTrackingTest.php`: stage table for both actors (8 states × 2), `finding_courier` true/false matrix with the `agtp_proposals` table present (create it in the test with `Schema::create` in a transaction) and absent, contact routing, a customer cannot read another customer's order (403), `unseen_by_store`, away summary. `no-literal` grep clean.
- [x] Registry entries asserted, not skipped. Added one name in the same commit (contract §0 rule 1): column `ops_delivery_codes.pin_ciphertext` (`encrypted` cast) — §5.1's `delivery_code.pin` cannot be recovered from `pin_hash`. `finding_courier` reads the proposals table name from agil-3's `Proposal::TABLE` when the class exists, so no `agtp_` literal lives under `app/`; the with-table matrix is `CustomerTrackingFindingCourierTest` (own file: MySQL DDL commits the test transaction, so it runs its own transaction and drops the table it created).

**Acceptance**
- [x] `php artisan test --filter=CustomerTrackingTest` green (28 tests across the two files); `route:list --path=api/ops/customer` shows the six routes. Full suite: the 6 pre-existing unit failures plus 6 pre-existing `DemoScenarioTest` / `EdgeCaseTest` failures (pickup-key PEMs and a scenario pointer on this machine) — verified identical on the clean tree before Phase 1 (`git stash -u && php artisan test --filter='DemoScenarioTest|EdgeCaseTest'` → the same 6).
- [x] Commit `Phase 1: customer tracking API`.

---

## Phase 2 — Utforsk, the feed tabs, and the Hjem entry points

Mount what exists, build the Utforsk screen, and make every card on the Hjem go
somewhere.

**Screens** (`utforsk` ≈L4389–4635; `feed` ≈L6643)
- [x] `lib/screens/bergen/utforsk/utforsk_screen.dart` at `/bergen/utforsk`, tab 1 of the shell: tabs **Feed** (unread badge) / **Fjordfiske** / **Forundringspose**; shop filter chips; pinned "Ærend · Drift" notice ("Mye regn i kveld — vi legger 5 min på alle tider", source: `GET /api/ops/store/availability` weather/pause note, else hidden); the Feed tab body is the existing `FeedHome` with `FeedPublisherTabs` **mounted** (state already in `FeedHomeState`) and `VaagenCard` **mounted** above the first post when `vaagenAvailable`; posts keep `FeedPostCard`; `Feed-media` (≈L4439) = the existing media slot plus optional autoplay video per `feedAutoplay`; the Fjordfiske tab body is `Navigator.pushNamed('/bergen/fjordfiske')` behind a landing card ("3 napp igjen i dag", "Kast ut") — the screen is agil-3's; the Forundringspose tab lists bags from `GET /api/ops/products?kind=pose` with pickup windows and a "Poseautomaten" link to `/bergen/automat` (Phase 4).
- [x] `lib/screens/bergen/utforsk/feed_nyheter_screen.dart` — `feed` "Nytt fra butikkene" (≈L6643): posts from `GET /v1/feed/tabs?tab=naerheten`, footer "Bare butikker i nærheten av deg · ingen reklame". `/bergen/utforsk?tab=feed` (agil-3's Meg row) resolves to this screen — it is the design's `feed` screen; the shell's Feed *segment* is the social feed. Also a chip in the Utforsk filter row. "Bestill · 89 kr": the feed service carries no product price on a tab item, so the CTA is "Se" (opens the post, which resolves the live product) — never a stale number (TODO(api): a `product` on the tab item).
- [x] Hjem entry points (`lib/screens/common/home/bergen/`): `Kategorirad` "Åpne" → `/bergen/kategori/{slug}`; `Vindu · kategoriene` houses → same; `Utforsk-kort` ×2 → `/bergen/utforsk`; `Forundringspose` card "Sikre en" → `/bergen/automat`; shop cards → `/bergen/butikk/{id}`; product cards → the product sheet; `Fjordfiske-knapp` → `/bergen/fjordfiske`; the bobbers → `showNappKort(context, NappOffer(...))` (seam); `Ægil-relevanskort` shows only when `aegilFindCount() > 0` and taps `showAegilBrett` (seam); the Ægil greeting → `kAegilRoute`; the Points card → `poengEntryCard` + `kPoengRoute`; `mensDuVarBorteCard(context)` rendered at the top of the sheet when non-null; the bell → `/bergen/meg/varsler` (agil-3). "UNDER KAIEN" find (≈L2141 region) reads `GET /api/agent/suggestions?context=under_kaien` (agil-2 route; guarded 404 → hidden).
- [x] Search field in the nav ("Søk i Bergen — butikker, varer, bydeler") → `/bergen/sok` with the typed text (`BergenRoutes.pushOr` → the legacy `SearchStore` until Phase 3 registers the route).
- [x] Copy: `utforsk_copy.dart` (`UtforskCopy`, keys `a1_utforsk_*`). Widget tests `test/bergen/utforsk_test.dart`; reachability: `UtforskScreen(` in `home_main_v1.dart` (tab 1) and `bergen_routes_agil1.dart`; `FeedNyheterScreen(` in the route map and `utforsk_screen.dart`. Added in this phase (kit, agil-1): `BergenRoutes` (`/bergen/...?query` and trailing-id resolution for both maps, `push` → toast for a route not on this tree, `pushOr` → the legacy screen), `BergenCart` (one add-to-cart + nav-pill badge for every product surface), `OpsCustomerApi` (`lib/networking/ops/ops_customer_api.dart`, the `ops.customer.*` calls plus the guarded points/agent/geo reads), `GET /api/ops/products?kind=pose` (backend, `CustomerPoserTest`). One append to `lib/main.dart`'s `onGenerateRoute` (`chore(shared)` in the Phase 2 commit).

**Design ledger** (fill during comparison)

| Screen | Design block | Differences accepted / to fix |
|---|---|---|
| Utforsk | ≈L4389 | Compared code-side against the block (no device screenshot in this session). Same: teal gradient, "Utforsk" 20/800 white, the 3-segment pill with the orange thumb (flex 1/1/1.25), Feed unread badge (orange, white ring), filter chips, Drift notice card layout, the Fjordfiske landing (168+, three floating cards, "3 napp igjen i dag", "Kast ut"), the bag list and the Poseautomaten link. **Differences accepted:** (1) the feed posts keep `FeedPostCard` (light cards on the teal, per plan) instead of the design's glass cards; (2) the Drift notice is hidden — `GET /api/ops/store/availability` is per store and carries no weather/pause note (TODO(api)); (3) filter chips narrow only the Ærend tab's items by `category`; the followed-stores feed has no category per post (feed service gap); (4) "3 napp igjen" on the landing is the design's number (agil-3's game state); (5) `left` / "N igjen" on bags is hidden — stock is not tracked; the promo card at the foot of the feed (`visPromo`) is not shown for the same reason. |
| Nytt fra butikkene | ≈L6643 | Same: paper background, back orb, "Bergenhus · i dag" chip, 22/800 title, time · shop · Bergensk dot, text, orange CTA + "Se butikk", footer. **Differences:** CTA reads "Se" not "Bestill · N kr" (no price on the tab item, see above); Bergensk dot shown for every store post (no per-store flag on the item); district is the address' district only when the caller passes it, else "Bergenhus". |
| Hjem entry points | ≈L1895–2600 | Kategorirad → `/bergen/kategori/{slug}` (slug from the name; `id` in arguments; legacy `DSHome` until Phase 4); Utforsk-kort ×2 → shell tab 1 (Utforsk); Forundringspose "Sikre en" and the hero bag → `/bergen/automat` (toast until Phase 4); shop cards → `/bergen/butikk/{id}` (legacy `StoreDetail` until Phase 4); product cards → `/bergen/butikk/{id}` with `product_id` (Phase 4 opens the sheet); Fjordfiske-knapp → `/bergen/fjordfiske` (toast until merge day); bobbers → `showNappKort(NappOffer)` seam (the Sync C stub toasts until agil-3's card merges — the hero's own card is kept as the fallback when no seam handler is given); Ægil-relevanskort only when `aegilFindCount() > 0` → `showAegilBrett`; greeting → `kAegilRoute` (legacy Snurre chat until merge); Points card `poengEntryCard` → `kPoengRoute`; `mensDuVarBorteCard` at the top of the sheet when non-null; bell → `/bergen/meg/varsler` (legacy Notifications until merge); UNDER KAIEN first card = a real find from `GET /api/agent/me/suggestions?context=under_kaien` when the tray has one (the route on this tree is `agent/me/suggestions`, not `agent/suggestions`), else the design's sample. **Not in the Hjem as built:** the `Vindu · kategoriene` houses (≈L2141) — the current Hjem hero has no house window; the category rad is the entry. Demo panel: 5-tap on the greeting line (the Hjem has no wordmark). |

**Acceptance**
- [x] `FeedPublisherTabs`, `VaagenCard` each used by `feed_home.dart`; every Hjem card has a route target or a seam call; `flutter test` green (360 + Utforsk); `/bergen/utforsk` in `bergen_routes_agil1.dart`.
- [x] Commit `Phase 2: Utforsk and Hjem entry points`.

---

## Phase 3 — Søk

`sok` ≈L4067–4228 (ignore the `aldri` overlay after it).

- [x] `lib/screens/bergen/sok/sok_screen.dart` at `/bergen/sok`: header "Hva leter du etter? Et ord — så søker jeg. Et ønske — så ordner jeg ærendet."; field with voice affordance; empty state = **Søk · Spør Ægil** card (≈L4183; "Start samtale" → `kAegilRoute`, "Skriv eller snakk" focuses the field) + **Nylige søk** (≈L4198, local storage, last 8) + **Populært nå** (≈L4206, `GET /api/ops/search/trending` — add to `api_ops.php` reading `ops_order_events` product names last 7 days, cached 10 min) + **Ukens oppdrag** banner (≈L4215, reads `GET /api/points/me/mission` — agil-2's route, guarded; "Se" → `/bergen/meg`).
- [x] Results **Søk · treff** (≈L4109): "Butikker {n}" (name, category, ETA, rating, fee) and "Produkter {n}" (name, shop, price, add) from the app's existing search endpoint (find it in `api_constant.dart`; wrap in `ops_customer_api.dart`); states `sokVanlig` ("SPØR ÆGIL – Sammenlikn «x» på pris og levering" → `kAegilRoute` with the query), `sokIngen` ("Ingen treff på «x» i Bergen ennå… La Ægil finne nærmeste"), `sokTom`.
- [x] Wish banner (`sokOnske`): when the query has ≥4 words or a number + "kr" → "Dette høres ut som et ærend – Spør Ægil" → `kAegilRoute` with the query.
- [x] Copy `sok_copy.dart` (`SokCopy`, `a1_sok_*`); tests `test/bergen/sok_test.dart`: each state renders, trending / mission fall back to hidden, the wish rule (the design's L7806 rule: ≥4 words, a `?`, or an errand word), recent searches capped at 8 in local storage. Backend: `GET /api/ops/search/trending` → `ops.search.trending` (registered in the contract §3.2 and `names.agil1.json`, `SearchTrendingTest`); the five `ops.customer.*` flags are now in `SurfaceFlags` (stage storefront, off) and asserted. Note: agil-2's mission route on this tree is `GET /api/points/mission` (not `me/mission`); the suggestions route is `agent/me/suggestions`. `OpsCustomerApi.networkEnabled` is a test-only kill-switch the route-build contract test flips (a screen that starts a request in `initState` would leave a Dio timer pending).

**Design ledger**

| Screen | Design block | Differences |
|---|---|---|
| Søk empty | ≈L4067 | Compared code-side. Same: the two-line header, white field with the orange search glyph and the orange mic orb, Kategorier row with "Alle N", the Spør Ægil card (kicker, line, two «examples», Start samtale / Skriv eller snakk), NYLIG, POPULÆRT NÅ, UKENS OPPDRAG · +N POENG with Se. **Differences accepted:** (1) the design's Fløyen cable-car scene behind the header (`vaerKlokke`, 290 px) is a flat gradient band — the scene is decorative and the assets are not in the app; (2) "Utforsker · 3 av 5 prøvd" is not shown (no per-customer category-tried count); (3) the mic focuses the field — no speech plugin in the app (design: "Skriv eller snakk"); (4) recent-search rows go to the field, not straight to a store (`tilButikk` in the design is a sample). |
| Søk · treff | ≈L4109 | Same: "N treff i Bergen", Butikker (n) rows with banner/name/meta, Produkter (n) rows with image/name/shop/price/Legg til, SPØR ÆGIL compare footer, `sokIngen` card with "La Ægil finne nærmeste". **Differences:** fee (`frakt`) is not on the store search response — omitted rather than invented; category on a store row is the legacy `store_products` line. Max 4 stores / 6 products as in the design. |
| wish banner | ≈L4090 | Same title, line, Spør Ægil CTA; pushes `kAegilRoute` with `q` (legacy Snurre chat with the draft until merge day). |

**Acceptance**
- [x] `/bergen/sok` reachable from the nav field (`openSearchTab` → `BergenRoutes.pushOr('/bergen/sok')`, now resolving) and from Hjem (the same orb); `flutter test` green (369); commit `Phase 3: Søk`.

---

## Phase 4 — Butikk & kategori

The biggest phase. Four screens and four sheets.

- [x] **Kategori** `lib/screens/bergen/butikk/kategori_screen.dart` at `/bergen/kategori/{slug}` (≈L4748–4856): "{n} åpne nå · Bergen", title, "Bestill fra bilde" (Mat only → C3 is agil-3's; button pushes `kAegilRoute` with `intent=photo`), Butikker / Produkter tabs, live strip "Akkurat nå i X: N bestillinger siste time" (`GET /api/ops/panel/...` is admin-scoped — add `GET /api/ops/customer/categories/{slug}/pulse` to Phase 1's controller), shop cards ("bestiller nå", VIDEO badge, ETA, fee), product grid, filter chips (Åpen nå / Gratis levering / Under 30 min / Topprangert), subcategory icons. Variants: **Gaver-kategori** (≈L4774: "Rekker fram i dag · Innen 18:15", "La Ægil finne en gave ›" → `kAegilRoute` gift intent, Anledninger, "GRATIS INNPAKNING" badge, "Populært til bursdag") and **Mote-utstilling** (≈L4825: the Dreieskiven turntable).
- [x] **Dreieskiven** `dreieskiven.dart` (≈L2762): pointer-driven turntable, front item shows price, heart "Lagre · si fra hvis prisen faller" → `POST /api/agent/availability-subscriptions` (agil-2 route, guarded), name / quote / who / add. Reused by Kategori Mote, the fashion store page, and Gaver.
- [x] **Restaurant store page** `butikk_screen.dart` at `/bergen/butikk/{id}` (`erButikk` ≈L3035–3520): hero (name, distance, "Åpent til", "Kjøkkenet er i gang 17:31" from `ops_store_hours` + availability), Casa Maria variant (EST., ETA, fee, "38 ærend i dag"), **Seilas · Burger King** progress (≈L3143: Kjøkkenet → Din dør, thresholds MIN 150 / Gratis frakt / Dessert / 10 % / 800 kr, "NESTE FORDEL", "Båten er i havn"), info buttons Allergener / Åpningstider / Mer / Del → the Info sheet, "Spør Ægil" → `kAegilRoute` store intent, **Kjøkkenluka** (≈L3246: swipe rail of 3 specials with before/after, "Spar X kr", "+Y kr" = 7 % Ærend-kroner from `points.*` policy via `GET /api/points/rules` guarded), category tabs, "Mest bestilt · Priser inkl. mva" menu with allergens, mini basket + floating basket bar (redux cart).
- [x] **Fashion / gift store page** `mote_butikk_screen.dart` (`{{ butSideLabel }}` ≈L2705–3033): label resolution "Mote-butikk" / "Gavebutikk · {navn}" / "Anledning · {x}"; hero ("12 kikker nå" from `GET /api/ops/customer/stores/{id}/presence`, add in Phase 1's controller, count of tracking views last 10 min — honest, not invented); "Ukens utstilling · Mote" Dreieskiven; PERSONALETS FAVORITT; "Til denne:" cross-sell; brand filter chips; shelf products with −% and points badge; "Usikker på størrelsen? Spør butikken" → `ops.customer.contact` with target store; gift variant (La Ægil finne en gave, Til hvem chips, INNPAKNING); mini basket + bar.
- [x] **Klede sheet** `klede_sheet.dart` (`visKlede` ≈L2630): colour, size with stock, quantity, "Prøv hjemme. Budet henter returen gratis innen 14 dager.", "Legg i kurv · X kr".
- [x] **Food product sheet** `produkt_sheet.dart` (`visProdukt` ≈L7211): "Mest bestilt i kveld", points, "Klar på 12 min", size (Liten −20 / Vanlig / Stor +29), add-ons, strength, allergens, quantity, "Legg til · X kr".
- [x] **Info sheet** (≈L6913 region: Allergener / Åpningstider / Mer) via `BergenArk`; **category sheet** (`arkAapent` ≈L7143).
- [x] **Poseautomaten** `automat_screen.dart` at `/bergen/automat` (`automat` ≈L4636): claw machine "Trekk i spaken · 99 kr", "Ingen nedtelling. Ingen nitter.", bag reveal, add to cart; bags from the same endpoint as Phase 2.
- [x] Copy `butikk_copy.dart` (`ButikkCopy`, `a1_butikk_*`); tests `test/bergen/butikk_test.dart` (Kategori incl. filters and the Gaver variant, both store pages, the three sheets, Dreieskiven, Poseautomaten); reachable from Hjem (kategori rad, shop and product cards, the bag card, Under kaien) and Søk (store rows, category chips) through `BergenRoutes`. Data: `lib/data/ops/butikk_models.dart` maps the legacy store-detail response; `lib/networking/ops/ops_butikk_api.dart` wraps the existing store, category, product-search and topping calls. Backend (Phase 1's controller): `ops.customer.categories.pulse` and `ops.customer.stores.presence`, registered in the contract §3.2 and the registry, tested in `CustomerTrackingTest`. `/bergen/butikk/{id}` loads the store and shows the restaurant page or, by category, the Mote / Gave page; `product_id` in the arguments opens the product sheet (the Hjem product cards).

**Design ledger**

| Screen | Design block | Differences |
|---|---|---|
| Kategori (+ Gaver, Mote) | ≈L4748 | Compared code-side. Same: hero band in the category's look, "{n} åpne nå · Bergen", title, "Bestill fra bilde" (Mat only → `kAegilRoute` `intent=photo`), Butikker / Produkter tabs with counts, the live strip (real: `ops.customer.categories.pulse`, hidden at 0), shop cards (banner, offer badge, name, ETA, rating), the product grid, four filter chips; Gaver: "Rekker fram i dag · Innen 18:15", "La Ægil finne en gave ›", Anledninger, GRATIS INNPAKNING badge, "Populært til bursdag i Bergenhus"; Mote: Ukens utstilling on the Dreieskiven. **Differences accepted:** (1) shop cards have no "bestiller nå" / VIDEO badge and no fee (the store list carries neither; the offer line is the badge); (2) the Gratis-levering chip keeps stores with an offer line (no fee field) — noted in code; (3) subcategory icons: the legacy category list has none; the category's own icon is the hero; (4) "Innen 18:15" is the design's cut-off (TODO(api): a category-wide same-day cut-off); (5) "Populært til bursdag" is a heading over the product tab, not a separate rail. |
| Restaurant store page | ≈L3035 | Same: banner hero with name, address · km · Åpent til, kitchen state pill (from `GET /api/ops/store/availability` when it answers, else the legacy status), ETA / fee / rating tags, "N kikker nå" (real presence, hidden at 0), SEILASEN DIN (Kjøkkenet → Din dør, the real minimum order and free-delivery threshold as the marks, NESTE FORDEL / "Båten er i havn"), Allergener / Åpningstider / Mer / Del chips → the Info sheet, Spør Ægil row → `kAegilRoute` store intent, Kjøkkenluka (the three best-discounted items, "Spar X kr", "+Y kr" only when `GET /api/points/rules` answers), category chips, "{kategori} · Priser inkl. mva" menu with "Mest bestilt" on the first item, mini basket + floating bar → `/bergen/kurv`. **Differences accepted:** (1) the voyage's Dessert / 10 % / 800 kr tiers are the design's; the app shows the store's real thresholds only; (2) the voyage's subtotal is the lines added on this page in this session (the cart total is not on the store-detail response); (3) "38 ærend i dag" is not shown (no endpoint); (4) allergens per item are not on the product response — the sheet says so instead of guessing; (5) EST. / "Kjøkkenet er i gang 17:31" timestamp: the pill shows the state without a time. |
| Fashion / gift store page | ≈L2705 | Same: label resolution (Mote-butikk / Gavebutikk · {navn} / Anledning · {x}), hero with logo, name, hours · ETA · fee, "N kikker nå" (real), Ukens utstilling on the Dreieskiven with PERSONALETS FAVORITT · {butikk}, "Til denne:" cross-sell with + Legg til / Lagt til, Spør butikken (→ `ops.customer.contact` on the customer's latest order at the store, else Ægil with the question), Merker chips (the store's categories), Hyllene grid with −% and points badges, INNPAKNING on gift tiles, the size hint line, gift variant with "La Ægil finne en gave" and Til hvem chips, mini basket + bar. **Differences accepted:** the staff quote («Den jeg tar på hver regndag») and the picker's name are not in any response — the who-line is the store's name; brands are the store's product categories. |
| Klede sheet | ≈L2630 | Same: image, brand kicker, name, price (+ struck was-price), colour chips, size chips with På lager / Utsolgt from `stock`, the try-at-home line, quantity, "Legg i kurv · X kr". Adds through the legacy cart call with size / colour ids. |
| Food product sheet | ≈L7211 | Same: image, "Mest bestilt i kveld" pill (first item), "+N poeng" (only when points rules answer), "Klar på N min" (the store's delivery time), name, description, price incl. mva, size chips with ±kr from `size_list`, option groups from `options_list` (single-choice groups behave as radio), allergens line, quantity, "Legg til · X kr". **Differences accepted:** the design's Styrke (Mild / Medium / Hot) is an option group when the store defines one — nothing is invented. |
| Poseautomaten | ≈L4636 | Same: title, line, "N igjen", the cabinet with the claw on a cable, real bags as the prizes, arrows steer the claw, "Styr klypen med pilene · posen lander her", "Trekk i spaken · 99 kr", the win card (POSEN ER DIN, store, Hentes · verdi minst, "Sikre posen · N kr" → cart → `/bergen/kurv`, Prøv igjen, the northern-lights line), the footer. **Differences accepted:** the design's four named bags are replaced by whatever `kind=pose` returns (empty → "Ingen poser i automaten i kveld"); "verdi minst" is 2× price + 52 (the design's 99 → 250 ratio) since value is not tracked. |

**Acceptance**
- [x] `/bergen/kategori`, `/bergen/butikk`, `/bergen/automat` in `bergen_routes_agil1.dart` (the sheets are opened from the pages, not routed); reachable from Hjem and Søk; every product surface adds through `BergenCart.add`, which updates the nav pill badge; `flutter test` green; commit `Phase 4: Butikk og kategori`.

---

## Phase 5 — Kurv & kasse

`kurv` ≈L4973–5250, sheets ≈L6913–7142, purchase sequence `kjopSteg2–4`.

- [ ] **Kurv** `kurv_screen.dart` at `/bergen/kurv`, tab 2 of the shell: **Seilas · kassen** header (≈L4976: "Bryggen → Kassen", "Ægil ror til bryggen"); Levering / Henting toggle; lines with quantity; empty state ("Kurven er tom — skal vi finne noe i Bergen?", "Bla gjennom Bergen", "Tilbud i kveld"); "Legg til noe mer – Glemte du drikke?" from the store's drinks category; Endre rows (address / time / payment "Betales ved bestilling"); "Beskjed til budet" + "Flere valg"; pickup note; tips 0/15/25/40 ("Alt går uavkortet til budet"); SAMMENDRAG incl. "Lagt i kurven av Ægil … 312 kr · Angre" (reads the cart's `added_by = aegil` lines — agil-3 writes them through the existing cart API; agil-1 just renders + `BergenUndoPill`); "DØREN · FOR BUDET" note with the "Tolk" chip (**C4, agil-3 — the chip pushes `kAegilRoute` with `intent=door`; no local logic**) and "Kode ved levering" toggle → `ops_delivery_codes` via the existing checkout; gift recipient "Overrask / Si fra"; "Å BETALE NÅ" total with "Gir N kr tilbake i Ærend-kroner"; footer "Ærendet krysser Vågen med {bud}" only once a courier is assigned; pay button = the existing Vipps flow (`endPointVippsInitiate`).
- [ ] Sheets via `BergenArk`: **Adresse** ("Hvor skal ærendet?" + door note), **Ny adresse** (uses the existing address drawer `ae_address_drawer.dart` inside), **Levering** ("Når vil du ha det?" Så fort som mulig / 18:30 / 19:30 — slots from `ops_store_hours`), **Betaling** (Vipps / Visa / Apple Pay / Google Pay from the existing card list).
- [ ] **Coverage at address change** (geo spec §4): call `GET /api/geo/coverage?lat=&lng=` when flag `geo.customer.coverage` is on; **404 or flag off → skip silently** (agil-3's endpoint may not exist on this branch yet). Not covered → "Vi leverer ikke hit ennå — si fra, så gir vi beskjed" with one-tap `POST /api/geo/waitlist`.
- [ ] **Self-delivery checkout rule** (spec §8.2): a 422 `PD_OUTSIDE_RADIUS` from checkout shows "Butikken leverer ikke hit" and offers pickup. The customer's fee line is unchanged whoever delivers (spec §5).
- [ ] **Purchase sequence** `kjop_sekvens.dart` (`kjopSteg2–4` ≈L5249): steps 2–3 are placeholders in the design — implement as the Vipps return → "Bekreftet" transition; step 4 **Levert · vervebillett** ("ÆREND-BILLETT {kode} – Gi 100 kr, få 100 kr", "Del billetten" / "Kopier", code from `GET /api/points/me/referral`, guarded) shown once per order after Levert.
- [ ] **Bestillingsdetaljer** `bestilling_sheet.dart` at `/bergen/bestilling/{id}` (≈L5641): Sammendrag / Detaljer tabs, Vipps timestamp, ORDRENUMMER + ÆREND-ID, store address, "Kvittering", "Meg · Bestillinger" (→ `/bergen/meg/bestillinger`, agil-3), "Kontakt kundeservice" (→ `/bergen/kundeservice`). Data: `ops.customer.orders`.
- [ ] Copy `kasse_copy.dart`; tests: empty / filled / pickup / gift; tip math; Ægil-added line renders and Angre removes; coverage call skipped on 404; 422 handling.

**Design ledger**

| Screen | Design block | Differences |
|---|---|---|
| Kurv | ≈L4973 | |
| four sheets | ≈L6913–7142 | |
| Levert · vervebillett | ≈L5249 | |
| Bestillingsdetaljer | ≈L5641 | |

**Acceptance**
- [ ] Order placed end to end on the local stack (`php artisan serve` + Vipps test env) lands in `ops_order_events` with `ops_origin = app` and `policy_version`; commit `Phase 5: Kurv og kasse`.

---

## Phase 6 — Sporing, Hjelp, Levert

The self-delivery spec's §5 items are **requirements** here, not suggestions.

- [ ] **Sporing** `sporing_screen.dart` at `/bergen/sporing/{id}` (≈L5287–5760, plus `spHentKlar` ≈L5500 and `spPaaVei` ≈L5457): data from `ops.customer.tracking` polled every 10 s, or the events channel when broadcasting is on (`private-customer.{id}`); top line "Live · {stadie}", ETA, "om N min"; **Sporing · stadier** stepper (`BergenStepper`, labels by `mode`); **stadieskifte** overlay ("Steg N av 4", "+X poeng" — points from `GET /api/points/me` delta, guarded) on every stage change; stage cards **Bekreftet** (receipt), **Tilberedes** (ticket, "På komfyren · 6 min igjen" from `ops_predicted_ready_at`), **På vei** (map with the route; live marker only when `live_position != null`; bike or car from `courier.vehicle`), **Klar for henting** (pickup variant: "Den står i disken. Si «{navn}»", "Vis veien" → map sheet `kArkErKart`), **Levert**; **Ægil-veileder** line ("Ægil · følger ærendet ditt" + `spNesteHint`); **Avslutt** ("Avslutt bestillingen" at stage 3 → `/bergen/levert/{id}`; before that "Fjordfiske mens du venter" → `/bergen/fjordfiske`); gift variant "{navn} venter på kaien".
- [ ] **Completion layer** (≈L7294–7326): **Bud-identitet** pill (courier initial + "BankID-verifisert" when `courier.verified`, or the store icon when `delivery_actor == partner`); **Leveringskode** (7×7 visual code from `qr_payload` + PIN; offline → PIN only, "Uten nett vises bare PIN."); **Valg som venter** ("Torgboden har ikke sett ordren" when `unseen_by_store`; Vent → no-op + toast, Avbestill → `ops.customer.problem kind=cancel` → full refund copy); `BergenOfflineBanner` on connectivity loss with the last payload.
- [ ] **Self-delivery variants** (spec §5, every line): label "Leveres av {butikknavn}" and no courier identity when `partner`; stages from the store-emitted statuses (server-derived — assert the app never maps states itself); ETA from the store estimate; **no live map** (route/destination only, no marker); contact routing "Ring butikken" / "Melding til butikken"; "Finner ikke døra" and "Noe mangler" route to the store; PIN shown as today; no courier notifications ("Butikken er på vei" variant — the notification copy keys `a1_sporing_notif_store_*`).
- [ ] **"Finner bud"** (agents spec §7): when `finding_courier`, the top line reads the `order_status_finding_courier` copy ("Finner bud") and the Ægil-veileder hint says a courier is being found; never for partner orders.
- [ ] **Hjelp sheet** `hjelp_sheet.dart` at `/bergen/sporing/{id}/hjelp` (`sheetHjelp` ≈L7000–7130): main (contact card "På vei · 4 min unna · sykler siden mars · 4,9" when courier, store card when partner; Ring / Send melding), **Ring {{ kontaktRolle }}** (in-app call UI: Demp / Avslutt / Høyttaler → `ops.customer.contact kind=call`, which today creates the relay record and, with no provider, shows the store/courier number masked per `ops_relay_calls`), **Melding til {{ kontaktRolle }}** (thread with typing indicator → `ops.customer.contact kind=message`), **Finner ikke døra** ("Dette er det {navn} ser nå", address, directions, Send / Ring / Skriv selv → `problem kind=door`), **Noe mangler** (tap the missing items → `problem kind=missing`; "Vipps-refusjon innen 2 min eller ny levering"), **Kundeservice** (≈L7114: hours, chat, 55 00 12 34, "Ordre #… er allerede lagt ved" → the existing live chat), **Bekreftet** (sent confirmation, "Ferdig"). `kontaktRolle` = "butikken" when partner else "bud".
- [ ] **Kundeservice** standalone at `/bergen/kundeservice` (same body, no order attached) — reached from Bestillingsdetaljer and Meg (agil-3 pushes it).
- [ ] **Levert** `levert_screen.dart` at `/bergen/levert/{id}` (≈L5881–5940): "18:11 Levert. Håper det smaker. to minutter før tiden" (from `promised_end` vs the delivered event), **Poeng for denne ordren** line (≈L5912: "+34 poeng", league gap, first-time bonus, "Du støttet en familiedrevet butikk…" — from `GET /api/points/me/ledger?order={id}`, guarded; hidden on 404), "Levert til deg · koden ble bekreftet av {bud|butikken}", "Takk til {bud}" (courier only), "Hvordan gikk det?" (existing rating), "Noe galt med bestillingen?" → Hjelp, "Ferdig".
- [ ] Retire `lib/screens/tracking/*`: `DeliveryCodeCard` and `OpsTrackingStatus` become the Leveringskode card and the stepper's status line inside `sporing/`; delete the old files and their tests once the new ones cover the same assertions.
- [ ] Wire the existing order-detail entry (`deliveries_order_detail.dart`) and push notifications (`push_notification_service.dart` order types) to `/bergen/sporing/{id}`; the Hjem's "PÅ VEI NÅ" notification row too.
- [ ] Demo panel triggers: new order → Bekreftet; next stage; unseen shop; code OK; PIN wrong ×3; offline/online (the design's `kDemoRader` list) — each drives the real endpoints on the local stack, not fake state.
- [ ] Copy `sporing_copy.dart`; tests: stage rendering for all 8 states × 2 actors × 2 modes; partner variant assertions (no courier widget, no marker, store contact targets); Finner bud; Hjelp states; Levert.

**Design ledger**

| Screen | Design block | Differences |
|---|---|---|
| Sporing stages | ≈L5287–5760 | |
| completion layer | ≈L7294 | |
| Hjelp sheet states | ≈L7000–7130 | |
| Levert | ≈L5881 | |

**Acceptance**
- [ ] On the local stack, drive an order through every state with the Partner endpoints (`api_ops.php` transitions) and watch the screen change; repeat with `pd_delivery_actor = partner` **after** agil-3 merges (until then, assert the guarded default path). `flutter test` green; commit `Phase 6: Sporing, Hjelp og Levert`.

---

## Phase 7 — Hygiene and the human-only list

- [ ] Delete `lib/screens/tracking/` if not already; triage `flutter analyze` infos on files this plan touched (deprecations only; do not chase the 641 pre-existing).
- [ ] Story viewer with a broken `media_url` — manual pass on a device; record in `AGIL-1-REMAINING.md` §7.
- [ ] `[ ] **HUMAN — T1** verify `GET /api/internal/feed-device-tokens` in prod; `**HUMAN — T2**` push E2E per `Hare-AdminPanel/docs/T1_T2_SMOKE_TEST.md`; `**HUMAN — T9**`, `**HUMAN — T10**`. Write status into `AGIL-1-REMAINING.md` §8. Do not attempt.
- [ ] Composer image-picker manual pass (Hare-Store) — **HUMAN**, out of UI scope, listed so it is not lost.
- [ ] Update `Hare-AdminPanel/docs/OPS_API.md` with the `customer/*` routes and `docs/OPS_ADMIN_GUIDE.md` "Sporing" note.

**Acceptance**
- [ ] Commit `Phase 7: hygiene`. Human items stay unticked with notes.

---

## Phase 8 — Merge day, l10n, design review, close

Runs **after** agil-3 reports merge-ready (its Phase 8).

- [ ] Execute contract §6 step by step; every step's command and result recorded here. Stop and report on any conflict outside §2.4.
- [ ] **l10n consolidation**: move every `A1Copy` and `A3Copy` key into `intl_no.arb` / `intl_en.arb` under `ops_<group>_*` / `pts_*` / `aegil_*` (and the spec §7 keys verbatim: `agent_badge_proposed order_status_finding_courier …`); `flutter gen-l10n`; replace the copy classes with `AppLocalizations` lookups; delete the copy files; `flutter test` green. One commit.
- [ ] **Design review ledger** — one row per screen in this plan and in agil-3's Phase 7, opened beside the design, differences listed and either fixed or accepted with a reason. The ledger is the acceptance artifact; a screen without a row is not done.
- [ ] Flags: `ops:flags list` shows every new key off; document the rollout order in `docs/OPS_ROLLBACK.md` §5 (customer stages after storefront).
- [ ] Update `plans/AGIL-1-REMAINING.md` to the post-merge state (or retire it with a pointer).

**Acceptance**
- [ ] Both suites green on the merged tree; `ContractNamesTest` no skips; `ops:contract-check` exit 0; commit `Phase 8: merge, l10n, review`.

---

## Asks of agil-3 (do not do these here)

- `GET /api/agent/suggestions?context=under_kaien` and `GET /api/agent/suggestions/{id}` must return the `NappOffer` shape (contract §5.4).
- `GET /api/points/me/ledger?order={id}` must return the per-order line the Levert screen shows, or a documented 404.
- `agtp_proposals` of type `courier_outreach` must set `subject_type = order`, `subject_id = <order id>` so `finding_courier` can be derived.
- The Meg "Nytt fra butikkene" row pushes `/bergen/utforsk?tab=feed`; "Hjelp og kontakt" pushes `/bergen/kundeservice`; Bestillinger rows push `/bergen/sporing/{id}` or `/bergen/bestilling/{id}`.

## Blocked / deferred

- **Vipps payout, policy placeholders, Points migration cutover** — unchanged from `AGIL-1-REMAINING.md` §8; not this plan's.
- **Partner and Bud app UI** — out of scope by decision; the self-delivery Partner screens are a later plan.
- **C3 "Bestill fra bilde" and C4 "Tolk" door notes** — agent functions; agil-3 owns the agent, agil-1 only pushes the intent.
- **Live map for partner-delivered orders** — v2 "butikkmodus" (spec §7.2), not this plan.
