# Ærend Dugnad — Build Handoff

Step-by-step build plan for the full dugnad customer experience. Each step is
independently reviewable. Design source: `rend-design-system/project/dugnad/*.jsx`.

---

## 1. Overview

Two modes share one app shell (`HomeMainV1`):

| Mode | Nav tabs | Status at launch |
|------|----------|-----------------|
| **Dugnad** | 5 tabs: Hjem · Tilbud · Kampanje · Kurv · Profil | **Active** (only selectable mode) |
| **Commercial** | 6 tabs: Hjem · Søk · Feed · AI · Kurv · Profil | **Locked** ("Kommer snart") |

**Dugnad user flow:**
Login → Velg modus (mode gate) → Velg din klubb (club onboarding) → Medlem
(optional membership #) → DGHome. Mode + club switchable anytime via ModeChip /
MinKlubbRow. Returning users skip onboarding if mode + club already set.

---

## 2. Already Built — Reuse, Do NOT Rebuild

### Backend (Hare-AdminPanel)

| What | File | Endpoint / Method |
|------|------|-------------------|
| Club listing | `app/Http/Controllers/Api/SportsClubApiController.php` → `listClubs()` | `GET /api/customer/sports-club/list` |
| Club detail | Same file → `showClub(int $id)` | `GET /api/customer/sports-club/{id}` |
| Sponsor stores | Same file → `clubSponsorStores(int $id)` | `GET /api/customer/sports-club/{id}/sponsor-stores` |
| Fundraising YTD | Same file → `postFinancialSummary()` | `POST /api/customer/sports-club/financial-summary` (call with `start_date=YYYY-01-01`, `end_date=YYYY-12-31`, `sports_club_store_id=X`; read `summary[0].club_share`) |
| Club donation on campaigns | `app/Http/Controllers/Api/CustomerCampaignController.php` | `club_share_amount`, `club_name`, `club_logo` on place-order response |
| Campaign payout % | `app/Http/Controllers/Api/Public/PublicCampaignController.php` | `club_payout_type`, `club_payout_value` on campaign detail |
| Routes | `routes/api.php` lines 210-215 | All six sports-club routes registered |

### Flutter (Hare-Customer)

| What | File | Provides |
|------|------|----------|
| Dugnad pref keys | `lib/utils/shared_pref_utill.dart` lines 56-61 | `prefDugnadModeEnabled`, `prefSelectedClubId`, `prefSelectedClubName`, `prefSelectedClubLogo`, `prefSelectedClubArea`, `prefMembershipNumber` |
| Dugnad state helper | `lib/screens/dugnad/dugnad_state.dart` | `DugnadState.instance` — read/write mode, club, membership; `onboardingComplete`, `reset()` |
| API client | `lib/screens/dugnad/dugnad_repo.dart` | `DugnadRepo` — `listClubs()`, `getClubDetail(int)`, `getSponsorStores(int)`, `getFundraisingYtd(int)` |
| Pojos | `lib/screens/dugnad/dugnad_models.dart` | `ClubListItem`, `ClubDetail`, `ClubCampaignSummary`, `SponsorStore` + postcode stripping |
| Club crest widget | `lib/screens/dugnad/club_crest.dart` | `ClubCrest` — logo or initials circle, parameterized size |
| Club picker sheet | `lib/screens/dugnad/club_sheet.dart` | `showClubSheet()` — searchable list, returns `ClubListItem?` |
| API endpoints | `lib/networking/api_constant.dart` lines 273-275 | `endPointSportsClubList`, `endPointSportsClubDetail`, `endPointSportsClubFinancialSummary` |
| Campaign flow | `lib/screens/campaign/` (6 screens + bloc + repo + models) | Full matkasse list → detail → checkout → confirmation with donation messaging |
| Service wheel | `lib/screens/common/home/home_v1.dart` → `_ServiceWheel` (line 3181) | Radial shiny-chip layout — adapt for team wheel |
| Design tokens | `lib/theme/sc_saas_theme.dart`, `lib/utils/utils.dart` (ae* helpers), `lib/commonView/surface_decorations.dart` | All visual tokens + `formatNok()` |

---

## 3. Decisions

### Locked (proceed with these)

| Decision | Resolution |
|----------|-----------|
| **Nav tabs** | Conditional: 5-tab dugnad vs 6-tab commercial, switched in `home_main_v1.dart` |
| **Membership storage** | SharedPreferences for v1 (local-only, no backend validation) |
| **Donation reality** | Campaign orders only for v1 (already wired via Chunk 12/13). Regular-order club split is v2. |

### Resolved for v1

| # | Decision | Resolution |
|---|----------|-----------|
| 1 | **Tilbud tab** | **(b) "Kommer snart" placeholder** — offers backend deferred post-launch. |
| 2 | **Regular-order club split** | **(b) Campaign-only donation for v1** — regular-order split = v2. |
| 3 | **Vipps login** | **(b) Google/Apple only** — no Vipps SSO for v1. |
| 4 | **Membership prefs-only v1** | **Confirmed** — local prefs only, no backend `club_members` table. |

---

## 4. Step D3 — Mode Gate + Club Onboarding

**Status: Done**

**Goal:** Post-login routing inserts mode selection and club onboarding before home.

**Files to CREATE:**
- `lib/screens/dugnad/mode_select_screen.dart` — two mode cards (Dugnad active / Kommersiell locked), info banner. Design: `dugnad/auth.jsx` → `ModeSelect`.
- `lib/screens/dugnad/club_onboarding_screen.dart` — 2-step flow. Step 1: choose club (uses `showClubSheet`). Step 2: membership number (optional). Design: `dugnad/club-select.jsx` → `ClubOnboarding`.

**Files to CHANGE:**
- `lib/screens/common/splash/splash_bloc.dart` — at lines 53, 106, 129, 151 where `HomeMainV1` is opened: add conditional `if (!DugnadState.instance.onboardingComplete) → ModeSelectScreen`, else `HomeMainV1`.
- `lib/screens/common/otpVerify/otp_verify_bloc.dart` — at line 119-120: same conditional.
- `lib/utils/utils.dart` — in `logout()` (line 648): call `DugnadState.instance.reset()` before clearing prefs.

**Do NOT touch:** Login auth logic, OTP verification, Firebase, the existing `prefReenSportsMode`/`prefActiveSportsClubId` keys, HomeMainV1 content.

**Acceptance:**
- Fresh login → ModeSelect → tap Dugnad → ClubOnboarding step 1 → pick club → step 2 → "Fortsett som støttespiller" → lands on HomeMainV1.
- Kill app, reopen → skips onboarding, lands on HomeMainV1 directly.
- Logout → `DugnadState` reset → next login shows ModeSelect again.

---

## 5. Step D4 — DGHome Screen + Conditional Nav

**Status: Done**

**Goal:** Build the dugnad home screen and wire it as Hjem (index 0) when dugnad mode is active.

**Files to CREATE:**
- `lib/screens/dugnad/dg_home.dart` — the dugnad Hjem screen. Sections (top to bottom per `dugnad/customer-screens.jsx` → `DGHome` + `dugnad/club-select.jsx` → `DGClubHome`):
  - Purple hero: gradient, Sveip button, location, ModeChip (taps → mode sheet, built in D6), MinKlubbRow (taps → `showClubSheet`).
  - Team wheel: adapt `_ServiceWheel` pattern from `home_v1.dart` (line 3181) — feed it clubs from `DugnadRepo().listClubs()`, tap navigates to club's sponsor stores (or sets selected club).
  - Club anchor: ClubCrest(56) + name + "Du støtter [club]" pill + area.
  - Green fundraising banner: "Klubben har samlet inn [amount] kr i år" — call `DugnadRepo().getFundraisingYtd(clubId)`, display with `formatNok()`.
  - Medlemstilbud CTA: if `DugnadState.instance.hasMembership` → "Se dine medlemstilbud"; else "Medlemsrabatter er låst" + "Lås opp" button.
  - Matkasse section: "Matkasse fra klubben" — reuse `CampaignListScreen` or inline campaign cards from `lib/screens/campaign/`.
  - Sponsor banner: "Handle hos sponsorene" + payout % from club detail.
  - Sponsor store cards: from `DugnadRepo().getSponsorStores(clubId)`, tap → `StoreDetail`.

**Files to CHANGE:**
- `lib/screens/common/homeMainV1/home_main_v1.dart`:
  - `PageView.children[0]`: conditional — `DugnadState.instance.isDugnadMode ? DGHome() : HomeV1(...)`.
  - `levels` list: conditional — dugnad: `['Hjem', 'Tilbud', 'Kampanje', 'Kurv', 'Profil']`, commercial: existing 6.
  - `activeIcons` / `inactiveIcons`: conditional sets (5 vs 6).
  - Tab 1-4 for dugnad: Tilbud (placeholder or real), Kampanje (`CampaignListScreen`), Kurv (`OrderCart`), Profil (`Account`).

**Do NOT touch:** `HomeV1`, `ds_home.dart`, `SearchStore`, `FeedShellScreen`, `SnurreChatScreen`, any commercial flow.

**Acceptance:**
- Dugnad mode → DGHome renders with club data, fundraising banner shows real YTD, sponsor stores load, matkasse section shows campaigns.
- Commercial mode → existing 6-tab HomeV1 renders (unchanged).
- Tap sponsor store → `StoreDetail` opens.
- Tap matkasse → campaign detail opens.

---

## 6. Step D5 — Kampanje Tab + Profil + Cart Donation

**Status: Done**

**Goal:** Wire the Kampanje tab, add dugnad sections to Profil, add cart donation banner.

**v1 note:** Cart donation banner (`order_cart.dart`) dropped — campaign-order donation
is already shown in the campaign checkout flow (Chunks 12-13). Regular-order donation
is deferred to v2 (Backend Build B). `order_cart.dart` left untouched.

**Files to CHANGE:**
- `lib/screens/common/account/account.dart` — add "Min klubb" section (ClubCrest + name + "Bytt" button → `showClubSheet`) and "Medlemskap" row (key icon + membership # or "Legg til" → membership editor). Conditional: only when `DugnadState.instance.isDugnadMode`. Insert above the existing settings card.
- `lib/screens/common/orderCart/order_cart.dart` — add a green donation banner above the cart items when `DugnadState.instance.isDugnadMode && order has campaign_id`. Use the existing donation data from campaign orders. For v1, regular orders show no donation banner.

**Files to CREATE (if Tilbud = placeholder):**
- `lib/screens/dugnad/tilbud_placeholder.dart` — "Tilbud" tab placeholder with "Kommer snart" message, matching the design's offer-list layout outline.

**Do NOT touch:** Campaign data fetching, order placement, payment, cart mutation, the existing commercial Profil layout.

**Acceptance:**
- Kampanje tab → `CampaignListScreen` (existing, reused).
- Profil → "Min klubb" card shows selected club with "Bytt" → opens `showClubSheet`.
- Cart → campaign-order items show green "Av denne bestillingen går X kr til [club]" banner when data is available.

---

## 7. Step D6 — Mode Switch + Club Switch + Rebuild

**Status: Done**

**Icon note:** Design system uses inline Lucide-style SVG path data (no external SVG files).
Exported `tag.svg`, `box.svg`, `heart.svg` from the icon definitions in
`rend-design-system/project/ui_kits/icons.jsx` into `assets/svgs/menu/`. These replace
the Material icon stand-ins (`local_offer_rounded`, `volunteer_activism_rounded`) on the
Tilbud and Kampanje tabs.

**DGHome self-refresh:** `DGHomeState` listens to `DugnadState.instance.revision`;
on change it re-runs `_loadData()` (mounted-guarded) so club switch / membership
change refreshes fundraising, sponsors, campaigns, and medlemstilbud CTA live.

**Goal:** Mode and club are switchable anytime; the nav and index-0 content rebuild.

**Files to CREATE:**
- `lib/screens/dugnad/mode_sheet.dart` — bottom sheet: "Bytt modus", Dugnad row (active, checkmark), Kommersiell row (locked, "Kommer snart", toast on tap). Design: `dugnad/auth.jsx` → `ModeSheet`.
- `lib/screens/dugnad/mode_chip.dart` — compact button in the hero: heart icon + "Dugnad" + chevron down. Taps → opens `mode_sheet`. Design: `dugnad/auth.jsx` → `ModeChip`.

**Files to CHANGE:**
- `lib/screens/common/homeMainV1/home_main_v1.dart` — add a rebuild mechanism: when `DugnadState` changes mode or club, call `setState()` on `HomeMainV1State` to rebuild the `PageView` children + nav. Options: (a) `ValueNotifier` on `DugnadState` + listener in `HomeMainV1State`, or (b) pass a callback down from DGHome. Recommend (a).
- `lib/screens/dugnad/dg_home.dart` — wire ModeChip in the hero (opens `mode_sheet`). Wire MinKlubbRow (opens `showClubSheet`, on result → `DugnadState.instance.selectClub(club)` + trigger rebuild).

**Do NOT touch:** HomeV1, any commercial screen, login/auth, payment.

**Acceptance:**
- Tap ModeChip → ModeSheet opens. Tap Kommersiell → toast "Kommer snart". Close sheet.
- Tap MinKlubbRow → ClubSheet opens. Pick different club → DGHome refreshes with new club's data.
- Tap "Bytt" in Profil → ClubSheet opens. Same behavior.

---

## 8. Step D7 — Tilbud + Dugnad Swipe (Gated on Decision 1)

**Only build if Decision 1 = (a) build offers backend.**

**Goal:** Real offers tab with member-discount gating + Tinder-style swipe variant.

**Backend prerequisite:** Backend Build A (see section 9).

**Files to CREATE:**
- `lib/screens/dugnad/tilbud_screen.dart` — offer cards per `dugnad/offers.jsx` → `TilbudScreen`. Locked offers (member-only, no membership) show lock icon + "Lås opp". Active offers (with membership) show "Aktiv for deg".
- `lib/screens/dugnad/sveip_screen.dart` — Tinder-style card swiping per `dugnad/offers.jsx` → `SveipDeals`. Reuse `appinio_swiper` package (already a dependency). Cards show product image, discount, price, "Andel til klubben". Swipe right = add to cart, left = skip.

**Files to CHANGE:**
- `lib/screens/common/homeMainV1/home_main_v1.dart` — replace Tilbud placeholder with real `TilbudScreen` at tab index 1 (dugnad mode).

**Do NOT touch:** Existing `SwipeReen`/`swipeHare` screens (commercial swipe stays separate).

**Acceptance:**
- Tilbud tab shows offers filtered to the selected club's sponsors.
- Member-only offers show "Kun medlem" lock when no membership; "Aktiv for deg" badge when membership set.
- Tap locked offer → membership editor opens.
- Sveip: swipe right adds to cart, left skips. Counter shows progress. "Det var alle!" at end.

---

## 9. Backend Build A — Offers Model

**Status: Deferred (post-launch / v2)**

**Scope:** Medium. Only if Decision 1 = (a).

**Migration:** Create `sponsor_offers` table:
- `id`, `sports_club_store_id` (FK → store_details), `store_id` (FK → store_details, the sponsor store), `title`, `subtitle`, `discount_label`, `image`, `valid_from`, `valid_to`, `requires_membership` (bool), `status` (draft/active/expired), timestamps.

**Model:** `SponsorOffer` with relationships to club and store.

**Admin:** CRUD in `SportsClubAdminController` (web routes only).

**API:** `GET /api/customer/sports-club/{id}/offers` — returns active offers for the club's sponsor stores, filtered by `valid_from <= now <= valid_to` and `status = active`.

**Do NOT touch:** Payout logic, order placement, existing tables.

---

## 10. Backend Build B — Regular-Order Club Split (v2)

**Status: Deferred (post-launch / v2)**

**Scope:** Medium. Only if Decision 2 = (a).

**Migration:** Add nullable `club_id` column to `user_store_product_booking` table.

**Order placement:** Modify the regular order API to accept optional `club_id`. If present and the store is a sponsor of that club, compute club share via existing `SportsClubService::resolveClubPayoutForLine()`.

**Response:** Add `club_share_amount`, `club_name` to regular order response (same pattern as campaign orders from Chunk 12).

**Flutter:** Pass `DugnadState.instance.clubId` during regular order placement. Show donation banner on all orders (not just campaign).

**Do NOT touch:** Campaign order flow (already has donation). Payout calculation logic (reuse existing).

---

## 11. Reuse Map

| Piece | Location | Reuse in |
|-------|----------|----------|
| `showClubSheet()` | `lib/screens/dugnad/club_sheet.dart` | Onboarding step 1, MinKlubbRow, Profil "Bytt" |
| `ClubCrest` | `lib/screens/dugnad/club_crest.dart` | DGHome anchor, team wheel chips, ClubSheet rows, Profil, checkout donation |
| `DugnadState.instance` | `lib/screens/dugnad/dugnad_state.dart` | All dugnad screens, nav conditionals, logout |
| `DugnadRepo` | `lib/screens/dugnad/dugnad_repo.dart` | DGHome data loading, ClubSheet list |
| `getFundraisingYtd()` | `lib/screens/dugnad/dugnad_repo.dart` | DGHome green banner |
| `_ServiceWheel` pattern | `lib/screens/common/home/home_v1.dart` line 3181 | DGHome team wheel (adapt with club data) |
| `PurpleHero` pattern | `lib/screens/deliveryService/home/widgets/purple_hero.dart` | DGHome hero (adapt with ModeChip + MinKlubbRow) |
| Campaign flow | `lib/screens/campaign/` (6 screens) | Kampanje tab, matkasse section in DGHome |
| `AeSurface` | `lib/commonView/surface_decorations.dart` | All dugnad cards and banners |
| `ae*` helpers | `lib/utils/utils.dart` | All dugnad text |
| `formatNok()` | `lib/utils/utils.dart` | Fundraising amounts, prices |
| `ScSaasThemeTokens` | `lib/theme/sc_saas_theme.dart` | All dugnad colors + shadows |

---

## 12. Acceptance Checklist

| Step | Check |
|------|-------|
| D3 | ~~Fresh login → ModeSelect → Dugnad → ClubOnboarding → pick club → membership (skip or enter) → HomeMainV1. Returning user skips. Logout resets.~~ **Done** |
| D4 | ~~Dugnad mode: DGHome at tab 0 with 5-tab nav. Club data, fundraising, sponsors, matkasse load. Commercial mode: existing 6-tab HomeV1 unchanged.~~ **Done** |
| D5 | ~~Kampanje tab shows campaigns. Profil shows Min klubb + Medlemskap. Cart shows donation banner on campaign orders.~~ **Done** (cart banner dropped for v1 — campaign donation already in campaign flow; regular-order = v2) |
| D6 | ~~ModeChip → ModeSheet. MinKlubbRow → ClubSheet → pick → DGHome refreshes. Profil "Bytt" → ClubSheet.~~ **Done** |
| D7 | Tilbud shows offers with member gating. Sveip works. (Only if Decision 1 = build.) |

---

## 13. Conventions

- **Text styles:** Use `ae*()` helpers from `lib/utils/utils.dart`. Do NOT call `GoogleFonts` directly.
- **Card/shadow decoration:** Use `AeSurface.card()`, `.shiny()`, etc. from `lib/commonView/surface_decorations.dart`.
- **Colors:** Use `ScSaasThemeTokens.*` from `lib/theme/sc_saas_theme.dart`.
- **Prices:** Use `formatNok(double)` from `lib/utils/utils.dart`. Output: `"149 NOK"` or `"149,90 NOK"`.
- **UI language:** All user-facing text uses `lib/l10n/` ARB keys via the global `languages` — do NOT hardcode string literals. Keys are `dugnad`-prefixed (camelCase). Interpolated strings use ICU MessageFormat placeholders with `@`-metadata in `intl_en.arb`.
- **Backend changes:** Additive only — no existing fields renamed/removed, no payout logic changes.
- **Build process:** Do NOT rely on `flutter analyze` (noisy in Cursor). Build debug APK in batches: `flutter build apk --debug`.
- **Reuse before adding:** Check the reuse map (section 11) before creating anything new.

---

## 14. Decisions — Resolved for v1

All four open decisions have been resolved. See section 3 for details.

| # | Question | Resolution |
|---|----------|-----------|
| 1 | Tilbud tab | **(b) Placeholder** — "Kommer snart". D7 + Backend A deferred post-launch. |
| 2 | Regular-order club split | **(b) Campaign-only** for v1. Backend B deferred. |
| 3 | Vipps login | **(b) Google/Apple only**. No Vipps SSO. |
| 4 | Membership storage | **Confirmed** prefs-only for v1. |

---

## 15. Localization (L1)

All dugnad user-facing strings use ARB keys via the global `languages` accessor
(`AppLocalizations`). ~55 new `dugnad`-prefixed keys added to `lib/l10n/intl_en.arb`
(English, template) and `lib/l10n/intl_no.arb` (Norwegian). 11 keys use ICU
MessageFormat placeholders for interpolated values (club name, amounts, counts).
1 existing key reused (`continueTxt`). Zero hardcoded Norwegian literals remain in
the 10 scope files. Disabled locales (sv/da/es) fall back to the English template
for new keys.

**P1 — campaign_strings.dart migrated:** 49 new `campaign`-prefixed keys added
(EN + NO). 5 existing keys reused (`fullName`, `email`, `deliveryAddress`, `payNow`,
`tryAgain`). `CampaignStrings` members changed from `static const String` to
`static String get` proxies returning `languages.*` — member names unchanged so all
call sites compile without modification. The hardcoded English
`"Payment initialization failed"` in `campaign_checkout_screen.dart` now routes
through `CampaignStrings.paymentInitFailed` with a proper NO translation. Zero
hardcoded literals remain in `campaign_strings.dart`.

**P2 — restyle screens localized:** 24 new keys added (EN + NO) across 7 namespaces
(`cart*`, `home*`, `account*`, `hero*`, `splash*`, `snurre*`, `campaignLastChance`).
4 existing keys reused (`skip`, `submit`, `logout`, `campaignMatkasser`). 2 keys use
ICU placeholders (`cartTitle` with `{count}`, `cartSubstitutionDetail` with
`{requested}`/`{matched}`). Brand terms ("ærend" wordmark, "Ærend Credits") kept
identical in both locales. All listed literals replaced in order_cart, home_v1,
account, purple_hero, splash, snurre_chat_screen, and campaign_list_screen.

**P3 — remaining screens + final sweep:** ~100 new keys added (EN + NO) covering
checkout, track_order, store_detail, store_info, search_store, account sub-screens
(edit_email, edit_username, edit_phonenumber, edit_profile_picture, redeem_code,
referral_code, application_setting, appearance, account_detail), create_profile,
add_location, edit_address, customize_map_picker, explore_city, login, sign_up,
invite_friends, swipe_card/swipe_hare_bloc, snurre_chat_screen (15 more strings),
chat_provider, order_history_detail, add_card, and feed components. ~15 existing
keys reused. Final sweep found and localized 43 additional stragglers. Social media
brand names (X, Instagram, etc.), currency codes (NOK), version numbers, and URLs
left as non-translatable data. **The full app's user-facing text is now ARB-driven
(~256 new keys added across L1+P1+P2+P3, total ~1053 keys in EN template).**

**AI agent (Snurre) in dugnad mode:** Disabled. The dugnad 5-tab nav excludes the AI
tab (no code change needed — already absent). The only shared-screen AI surface was
the Snurre substitution review badge in `order_cart.dart`, which is now mode-gated
(`!DugnadState.instance.isDugnadMode`). No dugnad-only file references Snurre/AI.
SnurreChatScreen, the commercial AI tab, SwipeReen, and all Snurre logic are untouched
and fully functional in commercial mode.

---

## 16. Guided Tour (App Walkthrough)

A spotlight walkthrough of DGHome and the STØ supporter card, offered to new
dugnad users and repeatable from the profile.

### Architecture

Three pieces, all under `lib/screens/dugnad/tour/`:

- **Target registry** (`dugnad_tour_keys.dart`) — a `DugnadTourTarget` enum and a
  static map of `GlobalKey`s. Feature widgets attach a key via
  `DugnadTourKeys.register(target)` (idempotent across rebuilds).
  `isResolvable(target)` is true only when a key is attached to a laid-out,
  non-zero-size render box, i.e. the feature is genuinely on screen. The three
  player-card targets are owned by the newest live `SupporterCardScreen`
  (claim/release), so a double-push never collides two live keys.
- **Controller** (`dugnad_tour_controller.dart`) — a `ChangeNotifier` +
  `WidgetsBindingObserver` that resolves the step list, walks it, drives the
  clubHome ↔ playerCard navigation on the root navigator, and measures the target
  in the overlay's coordinate space. The measured rect is a `ValueNotifier<Rect?>`
  so a scroll notification repaints only the spotlight and repositions the card,
  not the whole overlay. It subscribes to the target's `ScrollPosition` for the
  step's lifetime (scroll-following) and re-measures on viewport metrics changes.
- **Overlay host** (`dugnad_tour_overlay.dart`) — a single `OverlayEntry` in the
  root navigator's Overlay, so it survives the clubHome → playerCard push and the
  pop back. It paints a persistent base dim with a fading rounded hole/ring, shows
  the explanation card (`dugnad_tour_card.dart`), absorbs input (the dim is not
  tappable; only the card controls advance/exit), and handles Android back
  (dismiss on clubHome, tour-back on playerCard). The prompt card
  (`dugnad_tour_prompt.dart`) is a separate root-overlay invite.

### Resolved-step model — why the count can be under 13

The tour is defined as 13 steps (welcome, team, connect, earn, addr, camps,
donate, refer, comp, sto, form, badges, done). At start, `resolveSteps` filters to
the steps whose target is actually present, and `totalSteps` (the progress-bar
count and the "n / N" counter) is that filtered length. A step is dropped when its
target cannot exist for this user:

- **`camps`** — the campaign carousel is absent when the club has no live
  campaign; dropped via live `isResolvable` on the club-home screen.
- **`badges`** — the badges row is absent when the user has earned no badges;
  dropped via a data signal at launch (the badges target lives on a screen that
  isn't open yet, so it can't be measured up front).

Steps whose target is temporarily unresolvable at runtime are auto-skipped without
renumbering; if the whole player-card screen never loads, its remaining steps are
dropped together and the tour continues on club-home.

### Award endpoint and idempotency

Completing the tour (not dismissing it) awards **50 points**, separate from the
30-point onboarding welcome bonus.

- `POST /api/customer/sports-club/tour/complete` →
  `Api\DugnadPointsController@completeTour`. Points value is a single controller
  constant (`TOUR_COMPLETION_POINTS = 50`).
- `PointsService::awardTourCompletionPoints(user, points, organizationId)` is
  idempotent: a stable `source_id = crc32("tour_complete:{userId}:{orgId}")` plus
  a check-before-insert against `(user, ACTION_TOUR_COMPLETE, SOURCE_TOUR)`, backed
  by the ledger's `(source_type, source_id, action)` unique index. A concurrent
  double-call returns the existing ledger row instead of erroring, so there is
  exactly one `tour_complete` row per user + club. The award requires a points
  team; if none is set yet, nothing is awarded and the client retries later
  (idempotent, safe).
- The response carries `tour_points` (reward value), `awarded` (whether a ledger
  row is secured), and `first_award` (whether this call created it) so the client
  can tell first-award from repeat.

### Persistence

Two SharedPreferences flags:

- `dugnadTourCompleted` — set on both finish and dismiss. Suppresses the prompt and
  switches the final step to its "again" copy.
- `dugnadTourRewardPaid` — set only when the award is confirmed secured. Hides the
  prompt's reward strip and gates the background retry (if completed but not paid,
  the award is re-attempted once on the next eligibility check).

### Entry points

- **First run:** the prompt is shown once per session on DGHome when dugnad mode +
  a club are active, the tour isn't completed, the feed has loaded, and nothing is
  on top of DGHome.
- **Repeat:** a profile row ("App walkthrough") starts the tour directly (no
  prompt); on a repeat run the reward strip stays hidden and the final step shows
  its "already paid" copy.
