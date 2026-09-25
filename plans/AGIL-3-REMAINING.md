# AGIL-3 — remaining tasks and manual things

Written at the end of the agil-3 run (Phases 0–8 complete on branch `agil-3`
in `Hare-AdminPanel` and `Aerend-app`). Nothing here blocks the merge; every
item is either a decision, a credential, a human action, or work the plan
explicitly deferred. Read with `plans/AGIL-3-PLAN.md` (the checklist, the
design ledger and the blocked section) and `plans/AGIL-1-REMAINING.md` §8.

## 1. Manual things (a person has to do these)

- **Push.** Nothing was pushed. `git push origin agil-3` in both repos when
  you are ready. Never push `master`/`main`; never touch Aerend-Feed.
- **Merge is agil-1's.** Report line for the agil-1 plan: see the bottom of
  `plans/AGIL-3-PLAN.md` Phase 8 ("agil-3 merge-ready at …"). Both
  `git merge-tree --write-tree agil-1 agil-3` runs produced a clean tree.
- **Credentials (all optional, all off by default), set in the server `.env`
  only — `.env` is tracked in Hare-AdminPanel, so never commit them:**
  `AGENTOPS_API_TOKEN_*` (one per agent), `AGENTOPS_WHATSAPP_PROVIDER` +
  Meta Cloud token / phone id, `AGENTOPS_SLACK_WEBHOOK`,
  `AGENTOPS_KASSAL_API_KEY`, `AGENTOPS_MODEL_DRIVER=ollama` + host.
  `.env.example` lists every key with a comment.
- **Seed once after migrating:** `php artisan agentops:seed-policies`,
  `php artisan pd:seed-policies`, `php artisan geo:seed-policies`,
  `php artisan db:seed --class=AgentOpsRegisterSeeder`,
  `php artisan geo:import-legacy-areas` (then `geo:recompute-footprints`).
- **Flags.** Every agil-3 surface flag defaults off (`AgentOpsFlags`, 12
  flags). Turn on in this order: `agentops.center` (admin), then
  `pd.enabled` for one test store, `geo.coverage.customer` (read-only), and
  only after a clean shadow report `geo.engine.cutover`.
- **Legal sign-off** on the courier outreach consent text
  (`docs/AGENTOPS_COURIER_COMMS.md`) before `agentops.courier_comms.auto`.
- **Device pass** of the Phase 7 screens on a phone: Fjordfiske timing,
  the Napp sheet from the Hjem bobber, reduced motion from Konto, the
  Ægil chat with a real `agent/chat` (the fake model driver answers with
  fixtures). Widget tests cover rendering and wiring, not feel.
- **Native Norwegian review** of the three copy files
  (`poeng_copy.dart`, `meg_copy.dart`, `aegil_copy.dart`) and the ~75 EN
  dictionary entries appended to `public/assets/js/dugnad-i18n.js`.

## 2. Asks of agil-1 (recorded in AGIL-3-PLAN.md, not done here by contract)

- `ContractNamesTest` `agent` kind should grep every seeder, not only
  `AgentRegisterSeeder.php` — until then the four agil-3 agents stay
  `built:false` in `names.agil3.json` (4 skips).
- `PayoutLine::KIND_DELIVERY_INCOME` (1 skip); `SettlementService` to
  include the kind in partner statements.
- `OpsCandidateSource::eligible()` → `PdEligibility` hand-off.
- `GET /api/ops/customer/orders` — `BestillingerScreen` reads it for
  "PÅ VEI NÅ" (`liveCount` is 0 until then).
- `CustomerTrackingReadModel::finding_courier` reads `courier_outreach`
  proposals.
- App-wide `MediaQuery.disableAnimations` from the Konto "Roligere
  bevegelse" preference (agil-3 honours it on its own screens via
  `A3Services.reducedMotion`; the pref key is `a3_konto_rolig`).
- Hjem wiring of the filled seams: call `refreshAegilFindCount()` and
  `refreshMensDuVarBorte()` on cold start / resume so `aegilFindCount()` and
  `mensDuVarBorteCard()` have data; pass an `earn` hook to `showNappKort`
  if the Hjem wants the "+5" toast.
- `/bergen/utforsk?tab=feed` and `/bergen/kundeservice` targets for the
  Meg rows "Nytt fra butikkene" / "Hjelp og kontakt" (they open Konto now).
- Zone / bydel name for the Meg header (a copy constant "Bergenhus" now).

## 3. Asks of agil-2 (Points / Ægil API gaps found while building Phase 7)

- `LeagueStanding` has no display name → the league table shows
  "Klatrer · bydel". The design shows first names.
- No per-entry forget on `agent/me/memory` (forget-all only) → "Fjern" per
  memory row is not offered; "Stemmer" is local.
- No mute-by-kind endpoint for notifications → Varsler's "Ikke slike
  varsler" is Fjern + undo.
- `agent/suggestions` has no bait facet → no "Agn" chip rail in Fjordfiske.

## 4. Deferred by the plan (explicitly out of scope for agil-3)

- Partner app (Hare-Store) and Courier app (Hare-Driver) UI for
  self-delivery, placement, "Områdene dine", consent capture, the "Fra
  Ærend AI" badge — endpoints exist and are tested.
- Partner "AI-assistert import" UI; v2 butikkmodus (identity, T&C).
- Real providers: WhatsApp (Meta Cloud adapter exists, unverified against
  the live API), Kassal (HTTP client exists, fixture-tested), Kartverket
  geocoder (client exists), Brreg (client exists), Ollama model driver.
- Payout rails for Agent C (stops at `exported` CSV).
- Ægil screen extras not built: voice input, the Tweaks sheet, "Alle
  butikker" picker, the 5-step onboarding chips inside the chat, the basket
  bar → `/bergen/kurv` hand-off, the camera flow for `intent=photo`
  (`agent/photo-order` accepts a text list), avatar pose images (the header
  shows the state label), the Tillitsregnskap Ark variant.
- Fjordfiske art: Bryggen / Sjø SVGs and the Ægil poses (a gradient water
  card with boat + bobber is used); Ægil velger reuses the two dashboard
  poses.
- Interactive cell painting on the Områder map; second country pack; H3.

## 5. Known baseline noise (not agil-3's)

- `flutter analyze lib/` → 641 pre-existing infos/warnings, 0 errors; the
  agil-3 folders are clean.
- Hare-AdminPanel full PHPUnit baseline: 5 Unit failures + 1 error
  (`MediaUrlResolverTest`) predate this branch.
- `ContractNamesTest`: 41 skips = 36 agil-1 "reserved, not yet built"
  rows + the 5 agil-3 rows listed in §2.
