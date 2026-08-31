# Campaign Tracker — Handoff (Customer app / Hare-Customer)

> **Feature:** Reen Dugnad — Campaign Purchases: Overview, Countdown & Tracker.
> **Spec:** the "Reen Dugnad — Campaign Purchases" developer specification (§1–§9).
> **Design source of truth:** `docs/aerend-design-system/dugnad/campaign-purchases.jsx`
> (CpTracker, CpDial, CpCountdown, CampaignPurchasesScreen, CpActiveCard, CpArchiveSheet,
> CpChangeSheet) + `dugnad/gamify.css` (`.cp-*` classes). Interactive: `Custom Dugnad.html`.
>
> **Branch:** `feature/campaign-tracker` — **never merge to `main`/`master` without review.**
> **Commits:** `904200d` (Chunk 4 — data layer) → `b694db8` (Chunk 5 — tracker).
>
> **Status:** Chunks 4–5 complete, unit/widget-verified (`flutter test` green). **Nothing has
> been rendered/eyeballed in a running build** — the tracker's *behavior* is trustworthy, its
> *look and placement* are not yet confirmed. Chunks 6 (overview) and 7 (change sheet) are not
> started.

---

## 1. Golden rules for this feature (carried from the spec + recon)

- **Never re-derive state on the client.** Read `CampaignMyOrder.state` (server-authoritative).
- **Never hardcode Ærend purple.** All colours from `context.dugnadTheme`
  (`theme.primary` == active club accent); `ScSaasThemeTokens.danger` for the "soon" urgency.
- **Never compute or re-award points.** Display only, via the existing ledger.
- **Countdown/progress math is on absolute instants** (`.difference()`, `DateTime.now()`) — no
  timezone assumptions. The **tracker shows no wall-clock time.** Wall-clock rendering starts in
  Chunk 6 and is timezone-blocked (see §5).
- **Additive only** on shared code; match existing idioms, no duplication.
- **Do not run `flutter analyze`** (Cursor linter noise) and **do not run full APK/IPA builds per
  chunk.** `flutter test` and `flutter gen-l10n` are fine.

---

## 2. What's built (with files)

### Chunk 4 — data layer: model + repo + ARB + networking (`904200d`)

- **`lib/screens/campaign/models/campaign_order_pojo.dart`**
  - `enum CampaignPurchaseState { awaiting, locked, archived, unknown }` (+ string parser;
    `unknown` for anything unexpected / old payloads).
  - `class MethodChangeLogEntry { String from, to; DateTime? changedAt; double feeNok; bool feePaid }`.
  - New `CampaignMyOrder` fields (all nullable/defaulted; old JSON still parses):
    `state`, `methodChangeFeeNok` (0), `methodChangeLockHours?`, `methodChangeLockAt?`,
    `windowStart?`, `methodsOffered` (default `['pickup','delivery']`), `earnedPoints?`
    (**null until backend exposes `earned_points` — see §4A of the backend doc**),
    `methodChangeLog` (default `const []`).
  - Getters: `canChangeMethod` (= `state == awaiting`), `isArchived`.
  - Current method still sourced from the existing `deliveryMethod`/`taken_away_type` mapping — **not duplicated.**
- **`lib/screens/campaign/campaign_repo.dart`**
  - `Future<ChangeMethodResult> changeMethod({required String orderNo, required String targetMethod, String paymentMethod = 'stripe'})`.
  - Pure parser `parseChangeMethodResponse(statusCode, data, {targetMethod, fallbackErrorMessage})`.
  - **`ChangeMethodResult`** — enum-tagged (`changed / paymentRequired / locked / noChange /
    notOffered / error`) with factory constructors carrying: `newMethod`; `provider` +
    `payment` (`CampaignPaymentInfo`) + `changeId`; `lockAt`; `offeredMethods`; `message`.
    **This is the contract Chunk 7 pattern-matches on.**
- **`lib/networking/api_base_helper.dart`** — added `postAllowClientError` (per-request
  `validateStatus: s < 500`, same Dio/interceptors/headers) + `ApiClientResult{statusCode, data}`.
  **Why:** the existing `post` throws on 4xx and discards the body, so the backend's 422 business
  codes (`change_locked` etc.) are otherwise unreadable. `changeMethod` uses this.
- **`lib/networking/api_constant.dart`** — `endPointCampaignChangeMethod = 'campaign/change-method'`
  (base URL already includes `/api/customer/`). Body fields are inline snake_case
  (`order_no`, `target_method`, `payment_method`) matching `confirmPayment`.
- **ARB** — 48 feature-prefixed camelCase keys across `lib/l10n/intl_{en,no,da,es,sv}.arb`.
  **EN + NO bokmål are real; da/es/sv are EN-copy placeholders (need translation).** Surfaced via
  `lib/screens/campaign/campaign_strings.dart` (`CampaignStrings`). `campaignSwipeToPay` already
  existed and is reused.
- **Test** `test/campaign_tracker_chunk4_test.dart` (10 tests, model + response parsing).

### Chunk 5 — persistent tracker pill + countdown/dial (`b694db8`)

- **`lib/screens/campaign/widgets/campaign_tracker_countdown.dart`** — `TrackerCountdown`
  (sizes `full`/`row`/`sm`; `Timer.periodic` 1s, cancelled in `dispose`; respects
  `MediaQuery.disableAnimationsOf`; `soon` = `<26h` → `ScSaasThemeTokens.danger` +
  `DugnadCountdownPulse`; clamps at 0, no negatives; `textColor` param for white-on-gradient).
  `TrackerDial` (~92px `CustomPainter` ring by progress, `theme.primary`/danger). Pure helpers:
  `trackerRemaining`, `trackerIsSoon`, `trackerProgress`, `trackerUnits`.
- **`lib/screens/campaign/widgets/campaign_tracker.dart`** — `CampaignTracker` pill: method icon
  (truck/store) + lock badge when `locked`; name + `+N mer` (`campaignTrackerMore` ICU) when
  `activeCount > 1`; `sm` countdown to soonest `windowStart`; decorative rail; in/out animation
  (instant under reduced motion); chevron/pill tap → `onOpenOverview`; X → `controller.dismiss`.
- **`lib/screens/campaign/campaign_tracker_controller.dart`** — app-scoped `ChangeNotifier`
  singleton. `visibleActive` = server-state `awaiting|locked`, sorted by `windowStart` (nulls
  last), minus an **in-memory `Set<String> _dismissed`** (no `SharedPreferences`; reappears on
  reload; persists for the whole session, cleared only on club switch/logout). `refresh()` guards on
  `isDugnadMode && hasClub && isLoggedIn`, fetches `CampaignRepo.getMyOrders`, filters to
  awaiting/locked. Refetches on `DugnadState.revision` (club switch/logout) and
  `AppLifecycleState.resumed`. Countdown ticks locally — orders are **not** refetched per tick.
- **`lib/screens/dugnad/dugnad_celebration_orchestrator.dart`** — additive suppression read:
  `bool get isBlocked => _blocked;`, `ValueListenable<bool> get blockedListenable`,
  `void refreshBlockedState()`. `holdCriticalFlow`/`releaseCriticalFlow` now call
  `refreshBlockedState()`. **Reuses the existing `_blocked` three-way check** (critical hold /
  `DugnadTourController.active` / `isGlobalLoadingOverlayVisible`) — no new suppression flag.
- **`lib/screens/common/homeMainV1/home_main_v1.dart`** — shell mount. `Scaffold.body` is
  `_isDugnad ? Stack[ pageView, Positioned(left/right 14, bottom 92, CampaignTracker(...)) ]
  : pageView`. Bounded Positioned → non-blocking, cross-tab. Overview tap pushes `CampaignPurchasesScreen`; dismissals are NOT cleared on open.
- **Test** `test/campaign_tracker_chunk5_test.dart` (11 tests: render/soonest/`+N`/none/locked/
  suppression/dismissal-in-memory/soon-threshold/progress/reduced-motion).

---

## 3. Reuse targets (Chunks 6 & 7 MUST reuse — do not duplicate)

| Need | Reuse | Location |
|------|-------|----------|
| Club colours | `context.dugnadTheme` (`theme.primary` = accent) | `lib/screens/dugnad/dugnad_club_theme.dart` |
| Countdown / dial | `TrackerCountdown` (full/row), `TrackerDial` | `lib/screens/campaign/widgets/campaign_tracker_countdown.dart` |
| Fetch purchases | `CampaignRepo.getMyOrders()` | `lib/screens/campaign/campaign_repo.dart` |
| Change method | `CampaignRepo.changeMethod()` → `ChangeMethodResult` | same |
| Settle fee (re-call) | `CampaignRepo.confirmPayment(orderNo)` | same |
| Fee payment | `StripePaymentHelper.presentPaymentSheet` / Vipps `redirectUrl` + `launchUrl` | `lib/utils/stripe_payment_helper.dart` |
| Suppress during pay | `DugnadCelebrationOrchestrator.instance.holdCriticalFlow()/releaseCriticalFlow()` | `lib/screens/dugnad/dugnad_celebration_orchestrator.dart` |
| Points (display only) | `pointsLedgerDisplay(...)` | `lib/screens/dugnad/points_ledger_display.dart` |
| Copy | `CampaignStrings` getters (+ `languages`) | `lib/screens/campaign/campaign_strings.dart` |

---

## 4. What remains (customer)

### Chunk 6 — Overview screen (Kampanjekjøp): tabs + active card + archive

**Design:** `campaign-purchases.jsx` → `CampaignPurchasesScreen`, `CpActiveCard`, `CpArchiveSheet`.

- **Create** the screen + card + archive-sheet widgets under `lib/screens/campaign/` (e.g.
  `campaign_purchases_screen.dart`, `widgets/cp_active_card.dart`, `widgets/cp_archive_sheet.dart`).
- **Tabs:** `Aktive · {n}` / `Arkiv` (ARB keys `campaignTabActive` (ICU) / `campaignTabArchive`
  already exist). Active = `state ∈ {awaiting, locked}`; Archive = `state == archived`.
- **Active card** = receipt style (`.cp-card .paper`): crest + "Kvittering · kjøpt {date}",
  campaign/box/club·team, `TrackerDial` + row countdown, dotted-leader rows (Betalt,
  Leverings-/Hentedag, Tidsrom, Adresse/Hentested, Metode), a points chip, and an **Endre** button
  → opens the Chunk-7 change sheet (disabled → "Låst" when `state == locked`). ARB rows already
  exist (`campaignRow*`, `campaignPointsChip`, `campaignChangeButton`, `campaignLockedButton`).
- **Archive** = green points-earned summary (`campaignArchivePointsEarnedLabel` / `...PointsTotal`)
  + compact rows → `CpArchiveSheet` ("Levert/Hentet {day}" + "Se full kjøpshistorikk").
  **Show settled changes only, or clearly mark pending** (`method_change_log[].feePaid`).
- **Wire the tracker → overview:** replace the stub in `home_main_v1.dart` (`onOpenOverview`) with
  navigation to this screen. Do NOT clear dismissals on open - a pill the user closed stays
  closed for the rest of the session.
- **Points:** read `earnedPoints` (backend mini-chunk must land first — see backend doc §4A) or
  render via `pointsLedgerDisplay`. Never compute.

### Chunk 7 — Change sheet (CpChangeSheet): method change + fee payment

**Design:** `campaign-purchases.jsx` → `CpChangeSheet` (form → busy/payment → done).

- **Create** `lib/screens/campaign/widgets/cp_change_sheet.dart`.
- **Flow:** show target method + where/when + fee note. Call `CampaignRepo.changeMethod(...)`
  and pattern-match `ChangeMethodResult`:
  - `changed` → done card + success toast (`campaignChangeSuccessToast`).
  - `paymentRequired` → hand the carried `payment` (`client_secret`/`publishable_key` or
    `redirect_url`) to `StripePaymentHelper.presentPaymentSheet` / Vipps `launchUrl`. **On payment
    success, re-call `CampaignRepo.confirmPayment(orderNo)`** to trigger server settlement
    (`settlePendingMethodChange`) — this is the contract that actually flips the method.
  - `locked` → show `campaignLockMessage` with the `lockAt` datetime; disable.
  - `noChange` / `notOffered` / `error` → the matching ARB error copy
    (`campaignErrorNoChange` / `campaignErrorMethodNotOffered` / `campaignErrorGeneric`).
- **WRAP the whole payment path** in `holdCriticalFlow()` … `releaseCriticalFlow()` (this also
  auto-hides the tracker, since it reads the same signal). Use the pre-existing `campaignSwipeToPay`
  key for the swipe-to-pay label.
- **This is where the fee>0 settlement path gets its first real end-to-end test** — the backend
  `settlePendingMethodChange` has only been verified by inspection. Test a real fee payment →
  confirm the method actually flips and is idempotent on retry.

---

## 5. Blockers & open decisions

1. **Timezone (HARD — blocks Chunk 6).** The active card renders wall-clock times
   ("Tidsrom kl. 15:00–19:00") and the archive shows "Levert/Hentet {day}" — the first wall-clock
   rendering in the feature. `distribution_date` comes back `+00:00`. If deliveries are meant in
   **Europe/Oslo** but the column is UTC, a 17:00 Oslo pickup renders "15:00" and a purchase
   archives ~2h after local midnight. **Do not build Chunk 6 display until the zone is confirmed**
   (and note the server end-time question — single time vs an admin-set range; see backend doc §4C).
2. **Guest vs authenticated (reach — decide before investing in Chunk 6).** `getMyOrders` is
   auth-gated; in dev **every campaign order is a guest order.** If production buyers check out as
   guests, the overview reaches almost no one. Confirm before building the biggest screen.
3. **`earnedPoints` is null until the backend mini-chunk lands** (backend doc §4A). Chunk 6's
   archive points depend on it.

---

## 6. Known issues & polish

- **Suppression 1s poll (smell).** `blockedListenable` fires instantly for critical-flow
  transitions (checkout/onboarding), but tour-active and global-loading changes aren't observable,
  so the tracker **polls `refreshBlockedState()` every 1s** to catch them — up to a 1s window where
  it's briefly visible over a tour/loading it should hide under, plus a perpetual timer.
  **Cleanup:** have `DugnadTourController` and the global loading overlay call
  `refreshBlockedState()` on their transitions (like `holdCriticalFlow` already does), then drop
  the poll.
- **Package "hop" is static.** The prototype's package accelerates near/locked; Chunk 5 rendered it
  as a static position-by-progress (reduced-motion-safe by construction). A visible departure from
  the prototype's motion — restore the animated hop (reduced-motion-guarded) if design wants it.
- **da/es/sv ARB are placeholders** (EN copy). Need real translations; NO bokmål is done.
- **Typography.** Prototype CSS uses `font-weight: 800`; app convention prefers **Medium 500** via
  the `ae*()` helpers (`DUGNAD_BUILD_HANDOFF.md` §13). Map down — don't copy 800.
- **Visual verification pending.** Widget tests prove behavior, not pixels. Confirm in a real build:
  the pill matches `CpTracker` and sits correctly above `DGNav`; awaiting/locked/soon states look
  right.
- **Pre-existing in-file ARB duplicates** (`campaignDistributionDate`, `campaignOrderNumber`) were
  left untouched — unrelated to this feature, flagged so they aren't mistaken for new work.

---

## 7. Verify

- `flutter test test/campaign_tracker_chunk4_test.dart test/campaign_tracker_chunk5_test.dart`
  (21 tests green as handed off).
- `flutter gen-l10n` (no-op unless ARB changes).
- **Real build, eyes on:** tracker look + placement above the nav; suppression during
  checkout/onboarding/tour; dismissal; the soon (<26h) intensification.
- **Do not** run `flutter analyze` or per-chunk APK/IPA builds.
