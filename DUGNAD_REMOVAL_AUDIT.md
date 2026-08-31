# Ærend App — Dugnad Removal Audit (Chunk 0)

Inventory only. **No code was changed, no files deleted, no analyzer or build
was run.** Every claim below is anchored to a real path and line number in
`Aerend-app/`.

**Purpose:** map everything that must be removed, renamed, or un-gated to turn
this clone of `Hare-Customer` into the commercial / delivery-only Ærend app.

---

## 0. Headline findings

| # | Finding | Consequence |
|---|---------|-------------|
| 1 | `lib/screens/dugnad/` is **145 files / ~73,900 lines** — roughly 39% of all non-l10n Dart in `lib/` (190,640 lines). | The bulk is genuinely dugnad-only and deletable. |
| 2 | **42 of those 145 files are imported by non-dugnad code.** Six of them are imported 11–40 times each. | The directory **cannot be deleted wholesale.** A dugnad-named shared UI kit has to be extracted first. See §A.0. |
| 3 | The commercial 6-tab home (`HomeV1`, Søk, Feed, AI, Kurv, Profil) is **fully intact and unmodified** in `home_main_v1.dart:318-336`. `DGHome` was added as a parallel branch; it did not replace or absorb `HomeV1`. | Un-gating the shell is a small, low-risk edit. |
| 4 | The whole post-login route is funnelled through one helper, `dugnadAuthDestination()` in `lib/utils/utils.dart:824`, called from 5 sites. | Routing removal is a single-function change plus 5 call sites. |
| 5 | `context.dugnadTheme` already falls back to `DugnadClubThemePalette.defaults` (the Ærend purple palette) whenever dugnad mode is off — `dugnad_club_theme.dart:306-325`. | ~40 commercial files that read `context.dugnadTheme` are **already rendering correct commercial colours today.** This is a rename problem, not a behaviour problem. |
| 6 | `lib/screens/campaign/**` (30 files / ~11,500 lines) is the **matkasse campaign** feature. It is entered from the *commercial* home (`home_v1.dart:2795-2827`) as well as from dugnad. | Campaign is **not** cleanly dugnad-only. See §D. |
| 7 | Two unrelated club systems coexist: the new `DugnadState` (user-driven, `prefDugnadModeEnabled`) and a **legacy server-driven Reen Sports mode** (`prefReenSportsMode` / `prefActiveSportsClubId`, `home_bloc.dart:270-279`). | Removing one does not remove the other. See §B.3. |
| 8 | ARB has **2,012 unique keys**, of which **911 are `dugnad*`-prefixed**. Only **11** of those 911 are referenced outside `lib/screens/dugnad/`, and **137 are referenced nowhere at all.** | Localization cleanup is mechanical and safe. |

---

## A. Dugnad-only files

### A.0 / B.0 — CRITICAL CARVE-OUT: the dugnad-named shared UI kit

> ## ✅ Chunk 1 — kit rename: DONE
>
> The carve-out below has been executed. **15 files** moved to `lib/ui/kit/` via
> `git mv` (history preserved), **423 import directives** and **1,556 identifier
> occurrences** rewritten across **195 files**. Pure rename — verified by
> mechanically reversing the rename on every changed file and byte-comparing
> against its `HEAD` blob: **195/195 identical**. No logic, parameter, default,
> colour or conditional was changed; nothing was deleted; no ARB key was touched.
>
> **File moves**
>
> | Old path | New path |
> |---|---|
> | `lib/screens/dugnad/dugnad_club_theme.dart` | `lib/ui/kit/ae_theme.dart` |
> | `lib/screens/dugnad/dugnad_sheet.dart` | `lib/ui/kit/ae_sheet.dart` |
> | `lib/screens/dugnad/club_crest.dart` | `lib/ui/kit/ae_club_crest.dart` |
> | `lib/screens/dugnad/widgets/dugnad_rise_in.dart` | `lib/ui/kit/ae_rise_in.dart` |
> | `lib/screens/dugnad/widgets/dugnad_subpage_shell.dart` | `lib/ui/kit/ae_subpage_shell.dart` |
> | `lib/screens/dugnad/widgets/dugnad_confirm_sheet.dart` | `lib/ui/kit/ae_confirm_sheet.dart` |
> | `lib/screens/dugnad/widgets/dugnad_address_drawer.dart` | `lib/ui/kit/ae_address_drawer.dart` |
> | `lib/screens/dugnad/widgets/dugnad_checkout_payment_selector.dart` | `lib/ui/kit/ae_checkout_payment_selector.dart` |
> | `lib/screens/dugnad/widgets/dugnad_swipe_button.dart` | `lib/ui/kit/ae_swipe_button.dart` |
> | `lib/screens/dugnad/widgets/mk_qty_stepper.dart` | `lib/ui/kit/ae_qty_stepper.dart` |
> | `lib/screens/dugnad/widgets/dugnad_confetti.dart` | `lib/ui/kit/ae_confetti.dart` |
> | `lib/screens/dugnad/widgets/dugnad_hourglass.dart` | `lib/ui/kit/ae_hourglass.dart` |
> | `lib/screens/dugnad/widgets/dugnad_support_share.dart` | `lib/ui/kit/ae_support_share.dart` |
> | `lib/commonView/dugnad_club_loader.dart` | `lib/ui/kit/ae_loader.dart` |
> | `lib/screens/common/manageAddress/dugnad_inline_address.dart` | `lib/ui/kit/ae_inline_address.dart` |
>
> **Key symbol renames** (full list in the Chunk 1 report; 100 identifiers total)
>
> | Old | New |
> |---|---|
> | `showDugnadSheet` | `showAeSheet` |
> | `DugnadRiseIn` | `AeRiseIn` |
> | `DugnadFixedTypography` | `AeFixedTypography` |
> | `DugnadLbBackButton` | `AeBackButton` |
> | `DugnadClubThemePalette` | `AeThemePalette` |
> | `DugnadClubThemeScope` | `AeThemeScope` |
> | `context.dugnadTheme` | `context.aeTheme` |
> | `DugnadClubLoaderScreen` | `AeLoaderScreen` |
> | `DGConfirmSheet` | `AeConfirmSheet` |
> | `ClubCrest` | `AeClubCrest` |
> | `MkQtyStepper` | `AeQtyStepper` |
> | `kDugnadShinyPurple` | `kAeSheetShinyPurple` ⚠️ **collision substitution** — `kAeShinyPurple` was already taken by `deliveryService/checkout/co_styles.dart:128` |
>
> **Two deviations from the Chunk 1 brief:**
>
> 1. `lib/commonView/skeleton_loaders/dugnad_subpage_skeletons.dart` was **NOT
>    moved.** The brief listed it, but it has **zero** commercial importers — all
>    15 of its importers are dugnad-only screens, and none of its classes are
>    referenced outside `lib/screens/dugnad/`. It is a **section-A dugnad-only
>    file that A.0 mis-classified**. Moving it would have hidden dugnad-only code
>    inside the commercial kit and defeated the purpose of the rename. **A.0 is
>    corrected below: this file belongs in section A, and Chunk 5 should delete
>    it.**
> 2. The kit files legitimately retain back-references into dugnad-only code
>    (`DugnadState` in `ae_theme.dart` / `ae_sheet.dart`, `DugnadRepo` +
>    `DugnadClubBranding` in `ae_support_share.dart`, `DugnadRoundedFeedSheet` +
>    `DugnadReenLogo` in `ae_subpage_shell.dart`, `AeDugnadText`/`AeDugnadSpace`
>    from `theme/ae_typography.dart`, and ~20 `languages.dugnad*` ARB keys). The
>    brief required these to keep working; **they are the real remaining coupling
>    and are Chunk 2/3/7 work, not Chunk 1 work.**

These files live under `lib/screens/dugnad/` but are the general design system
of the app, imported by commercial login, consent, cart, checkout, wallet,
notifications, address management and order tracking. They are dugnad **in name
only**. Deleting them breaks the commercial app.

| Imports from non-dugnad code | File | What it actually is |
|---|---|---|
| 40 | `lib/screens/dugnad/dugnad_club_theme.dart` | The colour palette plus the `context.dugnadTheme` extension. Falls back to Ærend defaults off-mode (`:306-325`). |
| 33 | `lib/screens/dugnad/widgets/dugnad_rise_in.dart` | Generic staggered rise+fade entrance animation. |
| 27 | `lib/screens/dugnad/widgets/dugnad_subpage_shell.dart` | `DugnadFixedTypography` (locks text to the 375px design frame) plus `DugnadLbBackButton`. Used by every commercial sub-page. |
| 24 | `lib/screens/dugnad/dugnad_sheet.dart` | `showDugnadSheet()` — the only bottom-sheet primitive in the app, plus haptics and `kDugnadSheetRadius`. |
| 11 | `lib/screens/dugnad/widgets/dugnad_confirm_sheet.dart` | Generic confirm / destructive dialog vocabulary. |
| 3 | `lib/screens/dugnad/widgets/dugnad_address_drawer.dart` | Address picker drawer — used by commercial `account_detail.dart:572`. |
| 2 | `lib/screens/dugnad/widgets/dugnad_checkout_payment_selector.dart` | Payment-method row and change sheet. |
| 1 | `lib/screens/dugnad/widgets/dugnad_swipe_button.dart` | Swipe-to-confirm slider — used by commercial `checkout.dart:577,770`. |
| 1 | `lib/screens/dugnad/widgets/mk_qty_stepper.dart` | Generic quantity stepper. |
| 1 | `lib/screens/dugnad/widgets/dugnad_confetti.dart` | Generic confetti. |
| 1 | `lib/screens/dugnad/widgets/dugnad_hourglass.dart` | Generic animated hourglass (used by campaign countdown). |
| 1 | `lib/screens/dugnad/widgets/dugnad_support_share.dart` | Success-screen card layout constants. |
| — | `lib/screens/dugnad/club_crest.dart` | Avatar-with-initials fallback widget plus `resolveClubMediaUrl`. Used 4× from campaign. |

Also outside the dugnad folder but dugnad-named and **shared**:

| File | What it is |
|---|---|
| `lib/commonView/dugnad_club_loader.dart` | The global loading screen. Used by `full_screen_progress.dart:12` and `global_loading_overlay.dart:28` — i.e. **every** loading overlay in the app. |
| ~~`lib/commonView/skeleton_loaders/dugnad_subpage_skeletons.dart`~~ | ❌ **MIS-CLASSIFIED — belongs in section A, not here.** Zero commercial importers; all 15 importers are dugnad-only screens and none of its classes are used outside `lib/screens/dugnad/`. Not moved in Chunk 1. Delete in Chunk 5. |
| `lib/screens/common/manageAddress/dugnad_inline_address.dart` | The inline address form used by commercial `manage_address.dart:190,218`. |
| `lib/theme/ae_typography.dart:33,168` | `AeDugnadSpace` / `AeDugnadText` — general spacing and type scale. |

**Recommended action for all of the above: rename, do not delete.**
`Dugnad*` → `Ae*` (e.g. `DugnadRiseIn` → `AeRiseIn`, `showDugnadSheet` →
`showAeSheet`, `context.dugnadTheme` → `context.aePalette`), and move out of
`lib/screens/dugnad/` into `lib/commonView/` or `lib/theme/`.

---

### A.1 — Dugnad state, data, services (delete)

| File | Lines | What it does |
|---|---|---|
| `lib/screens/dugnad/dugnad_state.dart` | 521 | Singleton for dugnad mode, selected club, points team, membership number, referral/mission point pops, `onboardingComplete`. |
| `lib/screens/dugnad/dugnad_repo.dart` | 1328 | API client for all `sports-club/*`, `points/*`, `dugnad/*` endpoints. |
| `lib/screens/dugnad/dugnad_models.dart` | 1494 | POJOs for clubs, points, notifications, donations. |
| `lib/screens/dugnad/gamification_models.dart` | 1109 | Missions / career / progress models. |
| `lib/screens/dugnad/transfer_window_models.dart` | 167 | Transfer-window models. |
| `lib/screens/dugnad/celebration_models.dart` | 336 | Celebration queue models (T1–T16). |
| `lib/screens/dugnad/dugnad_feature_flags.dart` | 8 | `donationsEnabled` toggle. |
| `lib/screens/dugnad/dugnad_referral_state.dart` | 104 | Local pending-referral attribution before backend capture. |
| `lib/services/dugnad_data_cache.dart` | 767 | In-memory TTL cache for dugnad API payloads. |
| `lib/services/dugnad_cache_persistence.dart` | 168 | Disk snapshot of the above. |

### A.2 — Mode / club onboarding (delete)

| File | Lines | What it does |
|---|---|---|
| `lib/screens/dugnad/mode_select_screen.dart` | 375 | "Velg modus" gate. **Currently unreachable** (see §C) but still live-imported by `snurre_launcher_policy.dart:6`. |
| `lib/screens/dugnad/mode_sheet.dart` | 179 | "Bytt modus" sheet — Dugnad active, Kommersiell locked with a "Kommer snart" toast (`:99`). |
| `lib/screens/dugnad/mode_chip.dart` | 76 | Heart + "Dugnad" + chevron chip. |
| `lib/screens/dugnad/club_onboarding_screen.dart` | 730 | "Velg din klubb" onboarding. |
| `lib/screens/dugnad/club_sheet.dart` | 819 | Searchable club picker sheet. |
| `lib/screens/dugnad/membership_sheet.dart` | 195 | Membership-number editor. |
| `lib/screens/dugnad/dugnad_welcome_screen.dart` | 698 | Post-onboarding welcome celebration. |
| `lib/screens/dugnad/team_club_switch_screen.dart` | 759 | Club / team switch screen. |
| `lib/screens/dugnad/widgets/dugnad_choose_club_widgets.dart` | 171 | Browse-without-club hero widgets. |
| `lib/screens/dugnad/dugnad_club_branding.dart` | 29 | Dynamic club identity helpers. |

### A.3 — Home, feed, profile (delete)

| File | Lines | What it does |
|---|---|---|
| `lib/screens/dugnad/dg_home.dart` | 1643 | Dugnad home (tab 0 when dugnad mode is on). |
| `lib/screens/dugnad/dugnad_profile_section.dart` | 880 | Dugnad body of the Profil tab. |
| `lib/screens/dugnad/dugnad_profile_widgets.dart` | 645 | Profile head row, rows, tiles. |
| `lib/screens/dugnad/dugnad_privacy_screen.dart` | 1189 | Profile visibility controls. |
| `lib/screens/dugnad/widgets/dugnad_home_anchor_card.dart` | 907 | Home points anchor card. |
| `lib/screens/dugnad/widgets/dugnad_feed_entry_banner.dart` | 771 | Home feed entry banner. |
| `lib/screens/dugnad/widgets/dugnad_rounded_feed_sheet.dart` | 65 | Rounded feed sheet over the club hero. |
| `lib/screens/dugnad/widgets/dugnad_earn_sheet.dart` | 479 | How-to-earn sheet. |
| `lib/screens/dugnad/widgets/dugnad_locked_module.dart` | 234 | Guest lock / blur overlay. |
| `lib/screens/dugnad/widgets/dugnad_bell_button.dart` | 152 | Profile bell with unread dot. |
| `lib/commonView/skeleton_loaders/dugnad_feed_skeleton.dart` | 458 | Skeleton for the dugnad home feed. |

### A.4 — Points, tiers, metals, STØ (delete)

| File | Lines | What it does |
|---|---|---|
| `lib/screens/dugnad/dugnad_points_screen.dart` | 528 | "Dine poeng" — tier ladder, team, badges, earn paths. |
| `lib/screens/dugnad/dugnad_points_widgets.dart` | 2661 | All points UI components. |
| `lib/screens/dugnad/points_history_screen.dart` | 204 | Points history list. |
| `lib/screens/dugnad/points_ledger_display.dart` | 94 | Ledger row formatting. |
| `lib/screens/dugnad/points_metal_theme.dart` | 763 | Bronze / silver / gold / platinum tier theming. |
| `lib/screens/dugnad/points_progression_section.dart` | 223 | Progression banner and metal tier cards. |
| `lib/screens/dugnad/points_team_picker_screen.dart` | 533 | Points-team picker screen. |
| `lib/screens/dugnad/points_team_sheet.dart` | 313 | Points-team picker sheet. |
| `lib/screens/dugnad/metal_hero_tokens.dart` | 215 | Metal surface tokens. |
| `lib/screens/dugnad/tier_level_up_screen.dart` | 647 | Tier level-up celebration. |
| `lib/screens/dugnad/dugnad_sto_utils.dart` | 395 | STØ rating maths and labels. |
| `lib/screens/dugnad/dugnad_sto_source_breakdown.dart` | 95 | STØ source breakdown. |
| `lib/screens/dugnad/widgets/dugnad_sto_explainer_sheet.dart` | 929 | STØ explainer sheet. |
| `lib/screens/dugnad/widgets/dugnad_t16_sto_rise.dart` | 888 | T16 STØ-rose animation. |
| `lib/screens/dugnad/widgets/dugnad_t1_pulse_overlay.dart` | 577 | T1 points pulse. |
| `lib/screens/dugnad/dugnad_t1_controller.dart` | 94 | T1 inline count-up controller. |
| `lib/screens/dugnad/widgets/dugnad_points_pop.dart` | 925 | Global points-award pop. |
| `lib/screens/dugnad/widgets/dugnad_points_earn.dart` | 195 | Points-earn card. |
| `lib/screens/dugnad/widgets/ae_metal_hero_surface.dart` | 130 | Metal hero surface painter. |
| `lib/screens/dugnad/widgets/ae_metal_progress_bar.dart` | 313 | Four-timeline metal progress bar. |
| `lib/screens/dugnad/widgets/ae_sheen.dart` | 241 | Metal sheen keyframes. |
| `lib/screens/dugnad/widgets/dugnad_metal_animations.dart` | 946 | Metallic reflection animations. |
| `lib/screens/dugnad/widgets/dugnad_shiny_press.dart` | 212 | Shiny press / release for club pills. |

### A.5 — Teams, leaderboard, season, career (delete)

| File | Lines | What it does |
|---|---|---|
| `lib/screens/dugnad/leaderboard_screen.dart` | 2419 | Lagkonkurranse — 4-tab team leaderboard. |
| `lib/screens/dugnad/team_screen.dart` | 2649 | Lag-detalj — troppen, standing, team leaderboard. |
| `lib/screens/dugnad/team_detail_screen.dart` | 958 | Your Team detail and climb tips. |
| `lib/screens/dugnad/career_screen.dart` | 1223 | Career screen. |
| `lib/screens/dugnad/season_recap_screen.dart` | 929 | Season recap. |
| `lib/screens/dugnad/transfer_window_screen.dart` | 1324 | Transfer window. |
| `lib/screens/dugnad/supporter_card_screen.dart` | 517 | FIFA-style supporter card. |
| `lib/screens/dugnad/dugnad_formen_screen.dart` | 864 | "Formen din" season form graph. |
| `lib/screens/dugnad/dugnad_form_utils.dart` | 187 | Form tempo maths. |
| `lib/screens/dugnad/dugnad_missions_screen.dart` | 961 | Missions list. |
| `lib/screens/dugnad/dugnad_badges.dart` | 599 | Badge logic. |
| `lib/screens/dugnad/dugnad_badge_emblem.dart` | 284 | Badge icon resolver. |
| `lib/screens/dugnad/dugnad_badge_sheet.dart` | 427 | Badge detail sheet. |
| `lib/screens/dugnad/widgets/dugnad_player_card.dart` | 576 | STØ supporter card widget. |
| `lib/screens/dugnad/widgets/dugnad_team_sign_card.dart` | 306 | Team-selection SIGNERT hero. |
| `lib/screens/dugnad/widgets/dugnad_throne_player_hero.dart` | 223 | Season-title player hero. |
| `lib/screens/dugnad/widgets/dugnad_club_contract_card.dart` | 576 | Player contract card. |
| `lib/screens/dugnad/widgets/dugnad_bead_badge.dart` | 359 | Season-final gold cup. |
| `lib/screens/dugnad/widgets/dugnad_prize_banner.dart` | 257 | Season prize banner. |
| `lib/screens/dugnad/widgets/dugnad_season_finale_card.dart` | 404 | Season carryover card. |
| `lib/screens/dugnad/widgets/dugnad_form_explainer_sheet.dart` | 509 | Form tempo explainer. |
| `lib/screens/dugnad/widgets/troppen_sheet.dart` | 456 | Full Troppen list. |
| `lib/screens/dugnad/widgets/supporter_preview_sheet.dart` | 206 | Supporter card preview sheet. |
| `lib/screens/dugnad/widgets/lucide_trophy_icon.dart` | 138 | Trophy icon. |
| `lib/screens/dugnad/widgets/lucide_box_icon.dart` | 82 | Box icon. |

### A.6 — Celebrations (delete)

| File | Lines | What it does |
|---|---|---|
| `lib/screens/dugnad/dugnad_celebration_orchestrator.dart` | 391 | Global celebration queue — fetches pending server rows, shows one at a time, exposes `holdCriticalFlow()` and `blockedListenable`. |
| `lib/screens/dugnad/celebration_copy.dart` | 185 | Celebration copy. |
| `lib/screens/dugnad/celebration_debug_flags.dart` | 13 | Dev toggles. |
| `lib/screens/dugnad/widgets/celebration_ceremonial_presenter.dart` | 605 | Ceremonial presenters per type. |
| `lib/screens/dugnad/widgets/celebration_debug_panel.dart` | 284 | Dev trigger panel. |
| `lib/screens/dugnad/widgets/dugnad_celebration_overlay.dart` | 1326 | Celebration overlay. |
| `lib/screens/dugnad/widgets/dugnad_celebration_route.dart` | 75 | Full-screen ceremonial route. |
| `lib/screens/dugnad/widgets/dugnad_ceremonial_screen.dart` | 419 | Reusable ceremonial shell. |
| `lib/screens/dugnad/dugnad_flip_route.dart` | 98 | 3D flip page transition. |

### A.7 — Guided tour (delete)

| File | Lines | What it does |
|---|---|---|
| `lib/screens/dugnad/tour/dugnad_tour_controller.dart` | 815 | Tour step machine. |
| `lib/screens/dugnad/tour/dugnad_tour_overlay.dart` | 156 | Root-navigator overlay host. |
| `lib/screens/dugnad/tour/dugnad_tour_card.dart` | 481 | Tour step card. |
| `lib/screens/dugnad/tour/dugnad_tour_prompt.dart` | 439 | Tour invite prompt. |
| `lib/screens/dugnad/tour/dugnad_tour_keys.dart` | 107 | Spotlight target keys. |

### A.8 — Notifications (dugnad-specific, delete)

| File | Lines | What it does |
|---|---|---|
| `lib/screens/dugnad/dugnad_notifications_screen.dart` | 1090 | In-app dugnad notification feed. Separate from the commercial `lib/screens/common/notifications/`. |
| `lib/screens/dugnad/dugnad_notification_prefs_screen.dart` | 378 | Per-category notification prefs. |
| `lib/screens/dugnad/dugnad_notification_nav.dart` | 62 | Deep-link routing for notification taps. |
| `lib/screens/dugnad/dugnad_notification_unread.dart` | 25 | Shared unread counter. |

### A.9 — Referrals (delete)

| File | Lines | What it does |
|---|---|---|
| `lib/screens/dugnad/referral_share_screen.dart` | 714 | Club-level referral share screen. |
| `lib/screens/dugnad/referral_deep_link_loader.dart` | 64 | Validates `aerend://referral` deep links. |
| `lib/screens/dugnad/referral_capture_helper.dart` | 29 | `capturePendingDugnadReferralIfNeeded()` — called post-OTP. |
| `lib/screens/dugnad/dugnad_share.dart` | 31 | System share sheet wrapper. |
| `lib/screens/dugnad/widgets/referral_capture_banner.dart` | 30 | Login referral banner. |
| `lib/screens/dugnad/widgets/referral_manual_code_field.dart` | 366 | Login manual referral code field. |
| `lib/screens/dugnad/widgets/referral_invite_card.dart` | 125 | Club invite card. |
| `lib/screens/dugnad/widgets/incoming_referral_banner.dart` | 204 | "Vervet av X" confirmation banner. |
| `lib/screens/dugnad/widgets/dugnad_referral_promo_sheet.dart` | 614 | Floating referral promo. |

### A.10 — Donations / Fast støtte (delete)

| File | Lines | What it does |
|---|---|---|
| `lib/screens/dugnad/donation_setup_screen.dart` | 1426 | Fast støtte setup. |
| `lib/screens/dugnad/donation_manage_screen.dart` | 921 | Manage active subscriptions. |
| `lib/screens/dugnad/donation_confirm_screen.dart` | 614 | Post-Vipps confirmation. |
| `lib/screens/dugnad/donation_incomplete_screen.dart` | 149 | No active agreement. |
| `lib/screens/dugnad/donation_setup_failed_screen.dart` | 97 | Vipps rejected the agreement. |
| `lib/screens/dugnad/donation_deep_link_loader.dart` | 45 | `aerend://donation/vipps` return sync. |
| `lib/screens/dugnad/donation_flow.dart` | 23 | Entry router. |
| `lib/screens/dugnad/donation_fee_calculator.dart` | 106 | Client-side fee split preview. |
| `lib/screens/dugnad/widgets/donation_why_fee_sheet.dart` | 195 | Fee explainer sheet. |
| `lib/screens/dugnad/widgets/team_support_sheet.dart` | 215 | Fast støtte vs Kjøp kampanje choice sheet. |
| `lib/screens/common/vipps/donation_vipps_return.dart` | — | Vipps return handler; imports 5 donation files. |

### A.11 — Club shop (delete)

`lib/screens/dugnad/shop/` — 9 files, ~4,600 lines:
`club_shop_screen.dart` (608, locked gate), `club_shop_home.dart` (1018),
`club_shop_product_screen.dart` (779), `club_shop_cart_screen.dart` (737),
`club_shop_receipt_screen.dart` (556), `club_shop_models.dart` (368),
`club_shop_orders_screen.dart` (226), `club_shop_vipps_return.dart` (189),
`club_shop_cart.dart` (136). Plus `widgets/dugnad_club_shop_entry.dart` (179).

### A.12 — Kampanje / matkasse dugnad wrappers (delete; see §D)

| File | Lines | What it does |
|---|---|---|
| `lib/screens/dugnad/kampanje_screen.dart` | 599 | Club-scoped campaign tab (dugnad tab 1). Opens `CampaignDetailScreen` by slug. |
| `lib/screens/dugnad/matkasse_campaign_screen.dart` | 1064 | Dugnad campaign detail. |
| `lib/screens/dugnad/matkasse_product_screen.dart` | 721 | Dugnad product detail, pushes `CampaignCheckoutScreen`. |
| `lib/screens/dugnad/dugnad_supplier_sheet.dart` | 158 | Supplier detail sheet. |
| `lib/screens/dugnad/widgets/dugnad_campaign_carousel.dart` | 725 | Home campaign carousel. |
| `lib/screens/dugnad/widgets/campaign_countdown.dart` | 627 | Campaign countdown chip. |
| `lib/screens/dugnad/widgets/mk_campaign_card.dart` | 786 | Matkasse campaign card. |
| `lib/screens/dugnad/widgets/mk_cart_bar.dart` | 413 | Sticky matkasse cart bar. |
| `lib/screens/dugnad/widgets/mk_price_tag.dart` | 297 | Animated price tag. |

### A.13 — Assets

**No dugnad-only image or SVG assets found.** Searching `assets/` for
`*dugnad*`, `*club*`, `*metal*`, `*trophy*`, `*medal*` returns nothing
dugnad-specific. Dugnad screens use generic `assets/svgs/menu/*` icons
(`box.svg`, `shirt.svg`), which are also referenced by the commercial nav
(`home_main_v1.dart:400-431`), and `assets/Logo/reen/*`, which is the app brand.
`pubspec.yaml` needs no asset-list change.

---

## B. Shared files touched by dugnad

> **Chunk 2 status.** B.1, B.2, B.4, B.5 and B.6 are un-gated (see the per-section
> notes below). B.3 (legacy Reen Sports) is Chunk 3. B.7 / campaign coupling is
> Chunk 4. B.8 is mostly Chunk 1 rename work plus `brand_scrub.dart` (Chunk 3).


**Classification legend**

1. **DUGNAD-ONLY BLOCK** — delete outright.
2. **COMMERCIAL PATH SUPPRESSED** — commercial code currently hidden, gated,
   commented out, or replaced by a dugnad branch. The commercial behaviour once
   the gate is removed is stated.
3. **AMBIGUOUS** — cannot tell without a decision.

Total dugnad references outside `lib/screens/dugnad/` and `lib/l10n/`:
**1,169 lines across 118 files**, of which **223 are import statements**. The
large majority are shared-UI-kit usage (§A.0), not feature coupling.

---

### B.1 — Routing and app bootstrap

> **✅ Chunk 2 — un-gate commercial paths: DONE.** Every mode conditional in this section now takes its commercial branch; the dugnad branch is deleted. Dugnad *files* are untouched and still present (Chunk 5 deletes them).


| File | Line(s) | Class | Detail |
|---|---|---|---|
| `lib/utils/utils.dart` | 824-831 | **(2)** | `dugnadAuthDestination()` — forces `setDugnadMode(true)` then returns `HomeMainV1` or `ClubOnboardingScreen`. **Commercial:** delete the function; all call sites return `HomeMainV1(isShowDialog: ...)` directly. |
| `lib/utils/utils.dart` | 32-37, 39 | **(1)** | Imports of `dugnad_celebration_orchestrator.dart`, `dugnad_state.dart`, `club_onboarding_screen.dart`; commented-out `mode_select_screen.dart` import at `:36`. |
| `lib/utils/utils.dart` | 297 | **(1)** | `bool _toastOnReenPreClub() => !DugnadState.instance.hasClub;` — suppresses toasts pre-club. |
| `lib/utils/utils.dart` | 766-767 | **(1)** | Inside `logout()`: `dugnadResetTransientUi(); await DugnadState.instance.reset();`. |
| `lib/utils/utils.dart` | 865 | **(2)** | `manageLoginResponse()` awaits `dugnadAuthDestination()`. **Commercial:** `openScreenWithClearPrevious(context, const HomeMainV1(isShowDialog: true))`. |
| `lib/main.dart` | 13-18, 35-36 | **(1)** | Imports of orchestrator, state, tour controller, points pop, referral and donation deep-link loaders, club-shop Vipps return, data cache. |
| `lib/main.dart` | 99 | **(1)** | `await DugnadDataCache.instance.hydrateFromPrefs();` in bootstrap. |
| `lib/main.dart` | 208-223 | **(1)** | Wires `onReferrerPointsAwarded` / `onMissionPointsAwarded` to `DugnadPointsPop.award`. |
| `lib/main.dart` | 225-227 | **(1)** | `DugnadTourController.onBecameInactive` triggers an orchestrator pump. |
| `lib/main.dart` | 254-258 | **(1)** | On app resume: `syncPointsTeamFromServer()` plus `DugnadCelebrationOrchestrator.instance.sync()`. |
| `lib/main.dart` | 486-492 | **(3)** | Snurre launcher `AnimatedBuilder` listens to `DugnadState.instance.revision` alongside `snurreLauncherVisible` and `snurreChatRouteOnTop`. **Ambiguous:** drop the listenable, but confirm the launcher still rebuilds on the remaining two. |
| `lib/utils/guest_auth_helper.dart` | 5, 69-71 | **(2)** | Commented `mode_select_screen` import; `dugnadAuthDestination(isShowDialog: false)`. **Commercial:** navigate straight to `HomeMainV1`. |
| `lib/utils/shared_pref_utill.dart` | 58-120 | **(1)** | 18 dugnad pref keys: `prefDugnadModeEnabled`, `prefShowDugnadWelcomeAfterOnboarding`, `prefDugnadWelcomeBonusPoints`, `prefDugnadReferralJoinPoints`, `prefDugnadTourCompleted/RewardPaid/PopShown/Finished`, `prefPendingDugnadReferral`, `prefDugnadLastSeenTierKey`, `prefDugnadSeasonFinaleDismissed`, `prefDugnadReferralPromoDismissed`, `prefDugnadIncomingReferralDismissedId`, `prefDugnadReferralPopCursor(+Ready)`, `prefDugnadMissionPopCursor`, `prefDugnadDataCacheSnapshot`, `prefMembershipNumber` (`:67`). |
| `lib/utils/shared_pref_utill.dart` | 196-197 | **(1)** | `prefClearWithRemainSomeData()` special-cases the pop-cursor prefixes. |

### B.2 — Home shell and tabs

> **✅ Chunk 2 — un-gate commercial paths: DONE.** Every mode conditional in this section now takes its commercial branch; the dugnad branch is deleted. Dugnad *files* are untouched and still present (Chunk 5 deletes them).


| File | Line(s) | Class | Detail |
|---|---|---|---|
| `lib/screens/common/homeMainV1/home_main_v1.dart` | 14-19 | **(1)** | Imports `dg_home.dart`, `dugnad_club_theme.dart`, `dugnad_state.dart`, `kampanje_screen.dart`, `leaderboard_screen.dart`, `shop/club_shop_screen.dart`. |
| same | 62-63 | **(1)** | `_visitedDugnadTabs` lazy-mount set. |
| same | 69-73 | **(1)** | `dugnadHome/Kampanje/Shop/Leaderboard/ProfileTabIndex` constants. |
| same | 75 | **(1)** | `bool get _isDugnad => DugnadState.instance.isDugnadMode;` — the master switch for this file. |
| same | 95-106 | **(1)** | `_remapDugnadIndex()`. |
| same | 110-112 | **(2)** | `initState`: `_isDugnad ? _remapDugnadIndex(...) : _remapLegacyIndex(...)`. **Commercial:** `_remapLegacyIndex(widget.homeIndex)` unconditionally. |
| same | 117, 126, 129-137 | **(1)** | `DugnadState.revision` listener plus `markHomeShellReady/NotReady`. |
| same | 144-146 | **(1)** | Lazy dugnad tab mount inside `switchToTab`. |
| same | 161-170 | **(1)** | `backOrHome()` — back affordance for dugnad root tabs. |
| same | 294-297 | **(1)** | `dugnadPalette` and `browseNoClub` locals. |
| same | 302-317 | **(1)** | Dugnad `PageView` children list. |
| same | 318-336 | **(2)** | **Commercial 6-tab list — INTACT.** `HomeV1`, `SearchStore`, `FeedShellScreen`, `SnurreChatScreen`, `OrderCart`, `Account`. **Commercial:** this becomes the only `children:` value. |
| same | 342-366 | **(3)** | `body:` — dugnad wraps `pageView` in a `Stack` with the persistent `CampaignTracker` pill; commercial gets a bare `pageView`. **Ambiguous:** does the commercial app keep the campaign tracker? See §D. |
| same | 379-431 | **(2)** | `CircleNavBar` — `compactItems`, `compactWidthFactor`, `activePillGradient`, `pillBorderColor`, `activePillShadowColor`, `levels`, `activeIcons`, `inactiveIcons` are all ternaries on `_isDugnad`. **Commercial:** the commercial branch of each — `compactItems: false`, `compactWidthFactor: 0.90`, `levels: const ['Hjem','Søk','Feed','AI','Kurv','Profil']`, and the commercial icon lists. Note that `activePillGradient` / `pillBorderColor` / `activePillShadowColor` resolve to `null` in commercial mode today because `dugnadPalette` is null. |
| same | 458-465 | **(2)** | `WillPopScope` child — dugnad wraps in `DugnadClubThemeScope`. **Commercial:** `child: themedScaffold` unwrapped. |
| `lib/commonView/circle_nav_bar.dart` | 53, 178, 287 | **(3)** | Comments only (`compactWidthFactor` doc, "compact dugnad bar", "dugnad track"). Behaviour is driven entirely by parameters. **Ambiguous:** keep the compact-mode code path (dead but harmless) or strip it. |

### B.3 — Legacy Reen Sports mode (separate from DugnadState)

> **Chunk 3 - switched OFF: DONE.** `home_bloc.dart` no longer writes
> `prefReenSportsMode` / `prefActiveSportsClubId` / `Name` / `Image` from the
> home response, and `ds_home.dart` renders the full store list
> unconditionally - the single-club filter and the
> "Matkasse is not available today." branch are both gone. The four pref keys
> are still declared in `shared_pref_utill.dart` (Chunk 5 removes them).
> `checkout1.dart` is untouched - it is dead code, decided in U6.

This is a **different, older** club system driven by the server via
`home_bloc.dart`, not by `DugnadState`. It survives dugnad removal untouched
unless deliberately removed.

| File | Line(s) | Class | Detail |
|---|---|---|---|
| `lib/screens/common/home/home_bloc.dart` | 270-279 | **(3)** | Writes `prefReenSportsMode`, `prefActiveSportsClubId/Name/Image` from the home API response. |
| `lib/screens/deliveryService/home/ds_home.dart` | 37-38, 345-357 | **(3)** | `hasActiveClub = _isReenSportsMode && _activeClubId > 0` — **filters the food store list down to a single club store**, otherwise shows "Matkasse is not available today." This actively restricts the commercial store list. |
| `lib/screens/deliveryService/home/ds_home.dart` | 159 | **(2)** | Hardcoded title `'Velkommen til Reen Dugnad'`. **Commercial:** the commercial welcome string. |
| `lib/screens/deliveryService/checkout/checkout1.dart` | 153, 621-630 | **(3)** | `isReenSportsFood` gate showing a club pickup/delivery instruction block. **Note:** `CheckOut1` (`:28`) is **dead code** — nothing outside the file references it; the live checkout is `CheckOut` in `checkout.dart`. |
| `lib/utils/shared_pref_utill.dart` | 53-54 | **(3)** | `prefReenSportsMode`, `prefActiveSportsClubId`. |

### B.4 — Auth and onboarding

> **✅ Chunk 2 — un-gate commercial paths: DONE.** Every mode conditional in this section now takes its commercial branch; the dugnad branch is deleted. Dugnad *files* are untouched and still present (Chunk 5 deletes them).


| File | Line(s) | Class | Detail |
|---|---|---|---|
| `lib/screens/common/splash/splash_bloc.dart` | 12, 14 | **(1)** | Imports `dugnad_data_cache.dart`, `dugnad_state.dart`. |
| same | 15-16 | **(2)** | Commented-out `mode_select_screen.dart` import. Delete. |
| same | 97-104 | **(1)** | `_openDugnadHome()` — prefetch plus `dugnadAuthDestination`. |
| same | 121, 224 | **(2)** | `isLoggedIn() && DugnadState.instance.onboardingComplete`. See §C.1. |
| same | 99, 201 | **(1)** | "ModeSelectScreen skipped" comments. |
| `lib/screens/common/otpVerify/otp_verify_bloc.dart` | 6-8 | **(1)/(2)** | Commented mode-select import; live `referral_capture_helper.dart` import. |
| same | 172 | **(1)** | `prefSetBool(prefShowDugnadWelcomeAfterOnboarding, true)`. |
| same | 248 | **(1)** | `await capturePendingDugnadReferralIfNeeded();`. |
| same | 288-292 | **(2)** | `_navigateAfterVerify()` calls `dugnadAuthDestination`. See §C.2. |
| `lib/screens/common/createProfile/create_profile_bloc.dart` | 118 | **(1)** | `prefSetBool(prefShowDugnadWelcomeAfterOnboarding, true)`. |
| `lib/screens/common/createProfile/create_profile.dart` | 9, 44 | **(A.0)** | `DugnadRiseIn` only — rename. |
| `lib/screens/common/login/login.dart` | 13-16 | **(1)/(A.0)** | `dugnad_referral_state.dart`, `referral_capture_banner.dart`, `referral_manual_code_field.dart` are **(1)**; `dugnad_rise_in.dart` is shared kit. |
| same | 77-79 | **(1)** | `_refMode` derived from `DugnadReferralState.instance.pending`. |
| same | 238-241 | **(1)** | Renders `ReferralCaptureBanner` / `ReferralManualCodeField` under the login tabs. **Removing this leaves a gap in the login layout** — the `_regDemoMarginBottom` / `_methodsMarginTop` spacing at `:235,243` needs re-tuning. |
| same | 247-254, 501 | **(A.0)** | `DugnadRiseIn`, `useDugnadTheme: false`. |
| `lib/screens/common/consent/consent_gate_screen.dart` | 12, 229, 272, 302-308, 428, 478, 497 | **(A.0)** | `DugnadRiseIn` plus `useDugnadTheme: false` only. Rename, no behaviour change. |
| `lib/screens/common/auth/auth_style.dart` | 803-805 | **(2)** | `final theme = useDugnadTheme && DugnadState.instance.isDugnadMode ? ... : DugnadClubThemePalette.reenPreClub;` **Commercial:** always `reenPreClub` (renamed) — which is already what every commercial caller gets, since all pass `useDugnadTheme: false`. |
| `lib/screens/snurre/snurre_launcher_policy.dart` | 4-6 | **(1)** | Live imports of `club_onboarding_screen.dart`, `dugnad_state.dart`, `mode_select_screen.dart`. |
| same | 40-46 | **(1)** | Route-name mapping for `ModeSelectScreen` and `ClubOnboardingScreen`. |
| same | 66-69 | **(2)** | `if (DugnadState.instance.isDugnadMode) return false; if (!DugnadState.instance.onboardingComplete) return false;` — **this is why the Snurre AI launcher never appears today.** **Commercial:** delete both lines; the launcher then shows on all commercial routes not otherwise excluded. |

### B.5 — Account / Profil

> **✅ Chunk 2 — un-gate commercial paths: DONE.** Every mode conditional in this section now takes its commercial branch; the dugnad branch is deleted. Dugnad *files* are untouched and still present (Chunk 5 deletes them).


| File | Line(s) | Class | Detail |
|---|---|---|---|
| `lib/screens/common/account/account.dart` | 18, 20 | **(1)** | `dugnad_profile_section.dart`, `dugnad_bell_button.dart`. |
| same | 43-50 | **(1)** | `syncPointsTeamFromServer()` and `syncClubThemeFromApi()` on init. |
| same | 51-61 | **(1)** | `DugnadState.revision` listener. |
| same | 67-68, 74-90 | **(2)** | `appBar: isDugnad ? null : AppBar(...)`. **Commercial:** the `AppBar` always renders (title `languages.accountMyAccount`, `aeH2()`, centred, `toolbarHeight: 60`). |
| same | 91-97 | **(2)** | `body: (isLoggedIn() \|\| (isDugnad && isGuestUser())) ? (isDugnad ? SafeArea(_buildDugnadAccount()) : _buildAccount()) : _noAccount()`. **Commercial:** `isLoggedIn() ? _buildAccount() : _noAccount()`. The guest-account branch disappears with dugnad — confirm that is intended. |
| same | 101-152 | **(1)** | `_buildDugnadAccount()` — the whole dugnad profile body. |
| same | 153-305 | **(2)** | `_buildAccount()` — **commercial profile body, intact.** |
| `lib/screens/common/account/account_bloc.dart` | 42-44 | **(2)** | `if (!DugnadState.instance.isDugnadMode) { getWalletBalance(); }` **Commercial:** `getWalletBalance()` called unconditionally — the wallet balance reappears on the commercial profile. |
| same | 10, 226 | **(A.0)** | `showDugnadSheet` for the logout sheet. |
| `lib/screens/common/account/account_detail.dart` | 46-47, 75-81 | **(1)** | `DugnadState.revision` listener plus `syncClubThemeFromApi()`. |
| same | 107-114, 131-240, 372, 453, 557, 572 | **(A.0)** | `context.dugnadTheme`, `DugnadClubThemeScope`, `DugnadRiseIn`, `showDugnadSheet`, `showDugnadAddressDrawer`, `DugnadClubThemePalette` parameters. Rename only. |
| `lib/screens/common/account/account_widgets.dart` | 344, 379, 401 | **(A.0)** | `DugnadClubThemePalette` parameters. Rename only. |
| `lib/screens/common/account/*` (appearance, application_setting, credit, edit_*, redeem_code, referral_code, referral_term, settings_design_kit, terms_statement) | various | **(A.0)** | Shared-kit only (`DugnadRiseIn`, `DugnadFixedTypography`, `context.dugnadTheme`, `showDugnadSheet`). No feature coupling found. |

### B.6 — Cart, checkout, orders

> **✅ Chunk 2 — un-gate commercial paths: DONE.** Every mode conditional in this section now takes its commercial branch; the dugnad branch is deleted. Dugnad *files* are untouched and still present (Chunk 5 deletes them).


| File | Line(s) | Class | Detail |
|---|---|---|---|
| `lib/screens/common/orderCart/order_cart.dart` | 43-48 | **(1)** | `if (DugnadState.instance.isDugnadMode) { syncClubThemeFromApi()... }`. |
| same | 145-148 | **(2)** | `theme = isDugnad ? context.dugnadTheme : null; pageBg = theme?.background ?? ScSaasThemeTokens.background`. **Commercial:** `ScSaasThemeTokens.background`. |
| same | 427-428, 460-461, 490, 498 | **(2)** | Empty-cart copy branches on `isDugnad` (`languages.cartDugnadEmptyDesc`). **Commercial:** the commercial empty-cart strings. |
| same | 517-519 | **(2)** | `homeState.switchToTab(isDugnad ? 1 : 0)`. **Commercial:** `switchToTab(0)` (Hjem). |
| same | 576-578 | **(2)** | `if (!DugnadState.instance.isDugnadMode && order['snurre_flag_review'] ...)` — the Snurre substitution-review badge. **Commercial:** un-gated; the badge shows whenever the flag is set. |
| `lib/screens/deliveryService/checkout/checkout.dart` | 20-23, 110, 130-394, 577-579, 625-655, 770-772, 896-914, 1549-1561 | **(A.0)** | The **live commercial checkout** is built entirely from the dugnad UI kit: `DugnadFixedTypography`, `DugnadRiseIn` (×9), `DugnadLbBackButton`, `DugnadSwipeButton` (×2, `variant: purple`), `showDugnadSheet`, `DugnadSheetHandle`, `kDugnadSheetRadius`. **No mode gate anywhere in this file.** Rename only — deleting the kit breaks checkout entirely. |
| `lib/screens/deliveryService/checkout/co_styles.dart` | 435-437 | **(2)** | `CoFoot` background: `isDugnadMode ? context.dugnadTheme.background : ScSaasThemeTokens.background`. **Commercial:** `ScSaasThemeTokens.background`. |
| `lib/screens/deliveryService/checkout/checkout_bloc.dart` | — | **(A.0)** | Kit usage only. |
| `lib/screens/deliveryService/trackOrder/track_order.dart` | 19, 1494 | **(A.0)** | `showDugnadSheet<bool>` only. |
| `lib/screens/common/orderHistory/order_history.dart`, `order_detail/order_detail.dart` | various | **(A.0)** | Kit plus `context.dugnadTheme` only. |
| `lib/screens/common/address_order_chrome.dart` | 7-8, 100-593 | **(A.0)** | Entirely built on `context.dugnadTheme`, `DugnadFixedTypography`, `DugnadLbBackButton`. Shared chrome for address and order screens. Rename only. |
| `lib/screens/common/manageAddress/manage_address.dart` | 10-15, 105-394 | **(A.0)** | Kit plus `DugnadInlineAddressForm`, `DugnadAddAddressCard`, `showDugnadSheet`, `languages.dugnadAddressSavedInfo`. Rename only; the shared `dugnadAddress*` ARB keys (§E) move with it. |
| `lib/screens/common/manageAddress/add_new_address.dart`, `edit_address.dart`, `item_address_list.dart` | various | **(A.0)** | Kit only. |

### B.7 — Vipps

| File | Line(s) | Class | Detail |
|---|---|---|---|
| `lib/screens/common/vipps/vipps_return_screens.dart` | 12-17 | **(1)/(3)** | Imports campaign screens **and** `referral_capture_helper.dart`, `dugnad_state.dart`. |
| same | 119-121 | **(1)** | `capturePendingDugnadReferralIfNeeded(); await DugnadState.instance.syncPointsTeamFromServer();` after a successful campaign payment. |
| same | 170 | **(3)** | `CampaignTrackerController.instance.refresh()` — survives only if campaign survives. |
| same | 279 | **(A.0)** | `DugnadFixedTypography`. |
| `lib/screens/common/vipps/donation_vipps_return.dart` | 5-9, 36, 150 | **(1)** | The entire file is the donation Vipps return handler. Delete with §A.10. |
| `lib/screens/dugnad/shop/club_shop_vipps_return.dart` | — | **(1)** | Imported by `main.dart:35`. Delete with §A.11. |

### B.8 — Misc shared surfaces

> **Chunk 3 - brand scrub inverted: DONE.** `brand_scrub.dart` now normalizes
> every superseded brand **to Ærend** instead of to "Reen Dugnad"; the
> `the Ærend app -> Reen Dugnad` mapping and the whole `Ærend -> Reen Dugnad`
> regex family are deleted. The three named hardcoded strings
> (`common_view.dart:436`, `contact_us_screen.dart:136`, `ds_home.dart:159`)
> now read Ærend. **~30 further hardcoded "Reen Dugnad" literals remain across
> 13 commercial files** - listed in the Chunk 3 report, not yet authorised for
> change. `_toastOnReenPreClub`'s leftover `const reenPre = true` is gone and
> its ternaries are constant-folded to the true branch; no colour value
> changed (U3 still open).
>
> **Chunk 3b - brand rename completed: DONE.** All **36 remaining hardcoded
> literals across 13 commercial files** now read Ærend, including the
> **payment-sheet brand** (`checkout_bloc.dart:606,629` and the second, newly
> found `utils/stripe_payment_helper.dart:29,68`). Six commercial ARB keys were
> updated across the locales that carry them (13 value edits) and
> `flutter gen-l10n` was re-run, so ARB and `app_localizations*.dart` agree
> (**G13 satisfied**). The Apple Pay merchant ID
> `merchant.com.reen.customer` (`main.dart:74` + both `.entitlements`) is
> **unchanged** - it is an identifier, not a display string.
>
> **OPEN PRODUCT DECISION - `appName`.** Still `'Reen Dugnad'` in all five
> locales (`intl_{en,no,da,es,sv}.arb:2`). This is the label under the app
> icon. Deliberately **not** changed; the product owner must confirm, and it
> should be changed together with the native `CFBundleDisplayName` /
> `android:label` and the store listings.

| File | Line(s) | Class | Detail |
|---|---|---|---|
| `lib/commonView/image_selection.dart` | 25, 122, 151, 158-161 | **(2)** | Wraps the picker in `DugnadClubThemeScope(palette: isDugnadMode ? themePalette : ...)`. **Commercial:** drop the scope; `context.dugnadTheme` already returns `defaults` off-mode. |
| `lib/commonView/full_screen_progress.dart` | 3, 12 | **(A.0)** | `DugnadClubLoaderScreen`. |
| `lib/utils/global_loading_overlay.dart` | 3, 28 | **(A.0)** | `DugnadClubLoaderScreen`. |
| `lib/commonView/logout_curtain.dart` | 11 | — | Doc comment only. |
| `lib/commonView/common_view.dart` | 436 | **(2)** | Hardcoded `'Explore Reen Dugnad offer that suits you right now!'`. **Commercial:** commercial copy. |
| `lib/utils/brand_scrub.dart` | 22-59 | **(2)** | Maps every legacy brand string (`Hare App`, `Food Delivery`, `the Ærend app`, copyright lines) to `'Reen Dugnad'` / `'REEN DUGNAD'`. **Commercial:** the commercial brand name. **This is display-layer rewriting applied to backend content — it will silently mislabel the commercial app if left as-is.** |
| `lib/screens/deliveryService/searchStore/search_store.dart` | 115-118 | **(2)** | Uses `languages.dugnadSelectAddress` as the address placeholder. **Commercial:** a commercial `selectAddress` key. |
| `lib/screens/common/notifications/notifications.dart` | 9, 51 | **(A.0)** | `DugnadFixedTypography`. |
| `lib/screens/common/wallet/wallet.dart`, `walletTransfer/wallet_transfer.dart` | various | **(A.0)** | Kit only. |
| `lib/screens/common/helpAndSupport/*` | various | **(A.0)/(2)** | Kit, plus `contact_us_screen.dart:136` hardcodes `'Reen Dugnad'`. |
| `lib/screens/common/chatHistory/*`, `chatting/*`, `inviteFriend/*`, `location/*`, `emergency_contact.dart`, `selectLanguageAndCurrency/*`, `selectPaymentMethod/*`, `manageCard/*`, `addCard/*`, `swipeAerend/*` | various | **(A.0)** | Kit only. |
| `lib/dialogs/**` (14 files) | various | **(A.0)** | All `showDugnadSheet` / `DugnadRiseIn` / `context.dugnadTheme`. Rename only. |
| `lib/theme/ae_typography.dart` | 33, 165-169 | **(A.0)** | `AeDugnadSpace`, `AeDugnadText`. Rename to `AeSpace` / `AeText`. |
| `lib/theme/reen_pre_club_theme.dart` | 4-6, 59 | **(3)** | `ReenPreClubTokens` — the coral/navy pre-club palette. Used by `home_main_v1.dart:383,386,389` and `auth_style.dart:805`. **Ambiguous:** is the coral/navy REEN identity the commercial brand, or dugnad-only? |
| `lib/theme/sc_saas_theme.dart` | 37 | — | Comment only. |
| `lib/constant/colors.dart` | 15 | — | Comment only. |
| `lib/screens/rideService/rideDetail/ride_detail_bloc.dart` | — | **(A.0)** | Kit only. |
| `lib/screens/snurre/snurre_chat_screen.dart` | — | **(A.0)** | Kit only. |

---

## C. Routing + navigation

> **✅ Chunk 2 — routing un-gated: DONE.**
> - `splash_bloc.dart` is now a strict two-branch cold start; **`onboardingComplete` is gone** (audit G5 fixed).
> - `dugnadAuthDestination()` deleted from `utils.dart`; `HomeMainV1` inlined at all five call sites.
> - `logout()` no longer touches `DugnadState`; the logout curtain is kept (U7).
> - `home_main_v1.dart` renders the commercial 6-tab shell unconditionally. `HomeV1` untouched and still constructed with both parameters.
> - **G7 still open:** `activePillGradient` / `pillBorderColor` / `activePillShadowColor` are now explicitly `null` on `CircleNavBar`. This is exactly what the commercial branch always evaluated to, but it has never been visually verified because commercial mode was unreachable before this chunk.


### C.1 — `lib/screens/common/splash/splash_bloc.dart`

**Current (`:119-131`):**

```dart
// Desired cold-start flow: Splash → Consent → Login → (auth) → club select.
// Only skip Login when the user already finished club onboarding.
if (isLoggedIn() && DugnadState.instance.onboardingComplete) {
  prefSetBool(prefIsGuestMode, false);
  callRunningServiceApi();
} else if (isLoggedIn()) {
  prefSetBool(prefIsGuestMode, false);
  _openScreen(const Login());
} else {
  prefSetBool(prefIsGuestMode, false);
  _openScreen(const ConsentGateScreen(), handoff: true);
}
```

**Commercial-only version.** `onboardingComplete` is `isDugnadMode && hasClub`
(`dugnad_state.dart:481`), so with dugnad gone the middle branch — logged in but
no club, therefore back to Login — must disappear, otherwise **every returning
user is bounced to the login screen on every cold start.**

```dart
if (isLoggedIn()) {
  prefSetBool(prefIsGuestMode, false);
  callRunningServiceApi();
} else {
  prefSetBool(prefIsGuestMode, false);
  _openScreen(const ConsentGateScreen(), handoff: true);
}
```

**Current (`:97-104`):**

```dart
void _openDugnadHome({required bool isShowDialog}) {
  DugnadDataCache.instance.prefetchForDugnadEntry();
  // ModeSelectScreen skipped — dugnad is the only mode for now.
  dugnadAuthDestination(isShowDialog: isShowDialog).then((dest) {
    if (!state.mounted) return;
    _openScreen(dest);
  });
}
```

**Commercial:** `_openScreen(HomeMainV1(isShowDialog: isShowDialog));` — rename
the method to `_openHome`, drop the cache prefetch and the comment.

**Current (`:196-205`):** `manageRunningServiceResponse()` status `0` calls
`dugnadAuthDestination`. **Commercial:** `_openScreen(const HomeMainV1(isShowDialog: true))`.
Note this method is currently **dead** — `callRunningServiceApi()` (`:179-194`)
has its entire body commented out and only calls `_openDugnadHome`. Restoring
the running-service check is a separate decision (U8).

**Current (`:223-234`):** `openHomeOrLoginActivity()` — the same three-way branch
as `splashAction()`. **Commercial:** the same two-way form as above.

### C.2 — `lib/screens/common/otpVerify/otp_verify_bloc.dart`

**Current (`:278-292`):**

```dart
void _navigateAfterVerify() {
  if (!state.mounted) return;
  final bool returnToCaller = prefGetBool(prefAuthReturnOnSuccess) ||
      prefGetBool(prefGuestCheckoutResume) ||
      prefGetBool(prefGuestCampaignCheckoutResume);
  prefSetBool(prefAuthReturnOnSuccess, false);
  if (returnToCaller && Navigator.canPop(context)) {
    Navigator.pop(context, true);
    return;
  }
  // ModeSelectScreen skipped — dugnad is the only mode for now.
  dugnadAuthDestination(isShowDialog: true).then((dest) {
    if (!state.mounted) return;
    openScreenWithClearPrevious(context, dest);
  });
}
```

**Commercial-only version:** keep the `returnToCaller` early-return exactly as
is (it is the guest-checkout resume path), and replace the tail with
`openScreenWithClearPrevious(context, const HomeMainV1(isShowDialog: true));`.
Also delete `:172` (`prefShowDugnadWelcomeAfterOnboarding`) and `:248`
(`capturePendingDugnadReferralIfNeeded()`). `prefGuestCampaignCheckoutResume` at
`:283` survives only if campaign survives (§D).

### C.3 — `lib/screens/common/homeMainV1/home_main_v1.dart`

**Current (`:110-112`):**

```dart
final int initialTab = _isDugnad
    ? _remapDugnadIndex(widget.homeIndex)
    : _remapLegacyIndex(widget.homeIndex);
```

**Commercial:** `final int initialTab = _remapLegacyIndex(widget.homeIndex);`

**Current (`:302-336`):** a ternary between the 5-item dugnad list and the 6-item
commercial list. **Commercial:** the commercial list only —

```dart
children: [
  HomeV1(isShowDialog: widget.isShowDialog, orderId: widget.orderId), // 0 Hjem
  SearchStore(latLng: prefGetLatLng()),                               // 1 Søk
  const FeedShellScreen(),                                            // 2 Feed
  const SnurreChatScreen(),                                           // 3 AI
  Padding(padding: const EdgeInsets.only(bottom: _kShellNavLayoutReserve),
      child: OrderCart(fromStore: widget.fromStore)),                 // 4 Kurv
  const Account(),                                                    // 5 Profil
],
```

**Current (`:391-431`):** `levels` / `activeIcons` / `inactiveIcons` ternaries.
**Commercial:** `levels: const ['Hjem','Søk','Feed','AI','Kurv','Profil']` and
the corresponding 6-icon lists.

**Current (`:458-465`):** `_isDugnad ? DugnadClubThemeScope(...) : themedScaffold`.
**Commercial:** `child: themedScaffold`.

**Confirmation: `HomeV1` is fully intact and reachable.** `DGHome` was added as a
sibling branch at `:304`; it never replaced or absorbed `HomeV1`. `HomeV1` is
still constructed with both its parameters at `:320-322` and lives untouched at
`lib/screens/common/home/home_v1.dart` (2,800+ lines). The commercial tabs
`SearchStore`, `FeedShellScreen`, `SnurreChatScreen`, `OrderCart` and `Account`
are all present and constructed. Nothing needs rebuilding — only un-gating.

### C.4 — `lib/utils/utils.dart` — `logout()` (`:753-774`)

**Current:**

```dart
logout(BuildContext context) async {
  showLogoutCurtain();
  try {
    clearFCMToken().then((value) { FirebaseAuth.instance.signOut(); });
    StoreProvider.of<AppState>(context).dispatch(ClearCartItem());
    StoreProvider.of<AppState>(context).dispatch(ClearSelectedCoupons());
    // Before the route stack is cleared: `pushAndRemoveUntil` drops routes only,
    // so any dugnad Overlay entry still up would float into the next session.
    dugnadResetTransientUi();
    await DugnadState.instance.reset();
    prefClearWithRemainSomeData();
    openScreenWithClearPreviousHandoff(context, const Splash());
  } finally {
    hideLogoutCurtainAfterSwap();
  }
}
```

**Commercial-only version:** delete `dugnadResetTransientUi()` and
`await DugnadState.instance.reset()` (`:766-767`) plus the two-line comment.
**Keep** `showLogoutCurtain()` / `hideLogoutCurtainAfterSwap()` — the doc comment
at `:754-756` justifies the curtain as a club-repaint guard, but it also covers
the ordinary route swap, so removing it is a separate cosmetic decision, not part
of dugnad removal (U7).

**Also `:824-831`** — delete `dugnadAuthDestination()` entirely and inline
`HomeMainV1(isShowDialog: ...)` at all 5 call sites:
`splash_bloc.dart:100,202,225`, `otp_verify_bloc.dart:289`,
`guest_auth_helper.dart:70`, `utils.dart:865`.

---

## D. Campaign / Matkasse

**Contents of `lib/screens/campaign/**` — 30 files, ~11,489 lines:**

- **Screens:** `campaign_list_screen.dart`, `campaign_detail_screen.dart`,
  `campaign_product_detail_screen.dart`, `campaign_checkout_screen.dart`,
  `campaign_order_success_screen.dart`, `campaign_my_orders_screen.dart`,
  `campaign_order_detail_screen.dart`, `campaign_purchases_screen.dart`
- **Blocs:** `bloc/campaign_checkout_bloc.dart`, `bloc/campaign_detail_bloc.dart`,
  `bloc/campaign_list_bloc.dart`, `bloc/campaign_my_orders_bloc.dart`
- **Models:** `models/campaign_detail_pojo.dart`, `models/campaign_list_pojo.dart`,
  `models/campaign_order_pojo.dart`
- **Support:** `campaign_repo.dart`, `campaign_strings.dart`,
  `campaign_media.dart`, `campaign_delivery_utils.dart`,
  `campaign_product_utils.dart`, `campaign_supplier_content.dart`,
  `campaign_order_pdf.dart`, `campaign_tracker_controller.dart`
- **Widgets:** `campaign_tracker.dart`, `campaign_tracker_countdown.dart`,
  `campaign_swipe_pay_bar.dart`, `cp_active_card.dart`, `cp_archive_sheet.dart`,
  `cp_change_sheet.dart`, `cp_receipt_paper.dart`

### D.1 — What campaign depends on (campaign to dugnad)

45 dugnad imports across 13 campaign files, split by kind.

**Shared-kit (rename-only):** `dugnad_club_theme.dart` (8 files),
`dugnad_rise_in.dart` (4), `dugnad_sheet.dart` (2),
`dugnad_confirm_sheet.dart` (2), `dugnad_address_drawer.dart` (2),
`dugnad_checkout_payment_selector.dart` (2), `dugnad_hourglass.dart`,
`mk_qty_stepper.dart`, `dugnad_confetti.dart`, `dugnad_support_share.dart`,
`club_crest.dart` (4).

**Real dugnad-feature coupling:**

| Campaign file | Line(s) | Dugnad dependency |
|---|---|---|
| `campaign_checkout_screen.dart` | 72-75 | `_useClubTheme => DugnadState.instance.isDugnadMode`; `_clubTheme()`. |
| same | 106, 207 | `DugnadCelebrationOrchestrator.instance.holdCriticalFlow()` / `releaseCriticalFlow()`. |
| same | 119 | `if (!DugnadState.instance.isDugnadMode) return;` — early-out in a points sync path. |
| same | 248-249 | `capturePendingDugnadReferralIfNeeded()` plus `syncPointsTeamFromServer()`. |
| same | 562-565 | Shows the points-team nudge when `isDugnadMode && !hasPointsTeam`. |
| same | 830, 897, 940 | `DugnadState.instance.clubId` / `clubLogo` feeding `ClubCrest`. The club id is sent with the order. |
| same | 21, 23, 26 | `dugnad_repo.dart`, `points_team_sheet.dart`, `dugnad_points_earn.dart`. |
| `campaign_order_success_screen.dart` | 149, 196-197 | `DugnadState.instance`; `isDugnad ? context.dugnadTheme : null`. |
| same | 179, 208-210 | `DugnadPointsPop.dismissNow()`, `DugnadPointsPopTrigger`, `DugnadPointsPopReasons.campaign`. |
| same | 473 | `ClubCrest`. |
| `campaign_tracker_controller.dart` | 20, 89-90, 141 | Listens to `DugnadState.revision`; refresh guarded by `isDugnadMode && hasClub`. **The tracker never fetches in commercial mode today.** |
| `widgets/campaign_tracker.dart` | 55-71, 104 | Hides itself while `DugnadCelebrationOrchestrator.instance.isBlocked`. |
| `widgets/cp_change_sheet.dart` | 105, 111 | Orchestrator hold / release. |
| `widgets/cp_receipt_paper.dart` | 214-217, 236, 298 | `campaignClubCrestUrl()` reads `DugnadState.instance.clubLogo`; `ClubCrest.resolveClubMediaUrl`. |

### D.2 — What references campaign (campaign from the rest of the app)

**From the commercial flow:**

| Caller | Line | Reference |
|---|---|---|
| `lib/screens/common/home/home_v1.dart` | 26 | `import campaign_list_screen.dart` |
| same | 1721, 1747, 2795-2827 | `_activeCampaignsEntry()` card on the **commercial home**, labelled `languages.campaignMatkasser`, opens `CampaignListScreen`. |
| `lib/screens/common/account/account.dart` | 3 | `import campaign_my_orders_screen.dart` — reachable from the commercial profile. |
| `lib/screens/common/homeMainV1/home_main_v1.dart` | 10, 358-364 | `CampaignTracker` pill plus `CampaignPurchasesScreen` — **only in the dugnad `Stack` branch**, not in the commercial branch. |
| `lib/screens/common/vipps/vipps_return_screens.dart` | 12-15, 170 | Campaign Vipps return plus `CampaignTrackerController.refresh()`. |
| `lib/utils/guest_auth_helper.dart` | 256-274 | `saveGuestCampaignCheckoutResume` / `consumeGuestCampaignCheckoutResume`. |
| `lib/utils/shared_pref_utill.dart` | 80 | `prefGuestCampaignCheckoutResume`. |
| `lib/screens/common/otpVerify/otp_verify_bloc.dart` | 283 | Reads that pref in the auth-return decision. |

**From dugnad:** `kampanje_screen.dart:31,584`,
`matkasse_product_screen.dart:10-13,566`, `matkasse_campaign_screen.dart:13,15`,
`widgets/mk_cart_bar.dart:9,154`, `dugnad_supplier_sheet.dart:7`,
`season_recap_screen.dart:8`, `dugnad_profile_section.dart:3-4,321`,
`widgets/dugnad_checkout_payment_selector.dart:9`.

**Coupling with commercial cart / checkout / orders / tracking:**
`lib/screens/common/orderCart/order_cart.dart`,
`lib/screens/deliveryService/checkout/checkout.dart`,
`lib/screens/deliveryService/checkout/checkout_bloc.dart`,
`lib/screens/deliveryService/trackOrder/track_order.dart` and
`lib/screens/common/orderHistory/**` contain **zero** references to `campaign`.
Campaign is a fully parallel purchase flow with its own repo, blocs, checkout,
Vipps return and order history. The only crossing points are the shared
`prefGuestCampaignCheckoutResume` auth-return pref and
`vipps_return_screens.dart`, which dispatches to either flow.

*(Per the brief, no keep/drop judgement is made here — coupling only.)*

---

## E. Localization

`lib/l10n/` holds five ARB files (`intl_en.arb`, `intl_no.arb`, `intl_da.arb`,
`intl_es.arb`, `intl_sv.arb`) and the generated `app_localizations*.dart`.
`intl_en.arb` is the source of truth.

| Metric | Count |
|---|---|
| Unique keys in `intl_en.arb` | **2,012** |
| `dugnad*`-prefixed keys | **911** (45%) |
| …referenced **only** inside `lib/screens/dugnad/` | **763** |
| …referenced **outside** `lib/screens/dugnad/` | **11** |
| …referenced **nowhere in `lib/`** (already dead) | **137** |
| `campaign*`-prefixed keys | **167** (152 referenced outside the dugnad folder) |
| `celebration*`-prefixed keys | **37** |
| `dg*`-prefixed keys | **7** |
| `referral*` / `shop*` / `transfer*` | 5 / 2 / 1 |

**Key-name pattern.** Dugnad keys are camelCase with a `dugnad` prefix followed
by a subsystem segment: `dugnadPoints*`, `dugnadClub*`, `dugnadTeam*`,
`dugnadNotif*`, `dugnadDonation*`, `dugnadShop*`, `dugnadTour*`,
`dugnadReferral*`, `dugnadMode*`, `dugnadAddress*`, `dugnadProfile*`,
`dugnadMission*`, `dugnadSto*`. Campaign and matkasse keys use `campaign*`;
celebration keys use `celebration*`. There is **no** top-level `sto*`,
`kampanje*`, `matkasse*`, `mk*`, `points*`, `club*`, `membership*` or `metal*`
prefix — those subsystems all sit under `dugnad*` or `campaign*`.

**The 11 `dugnad*` keys used outside the dugnad folder** — these must be renamed,
or their call sites re-pointed, rather than deleted:

| Key | Used by |
|---|---|
| `dugnadAddressDeliverMultiple` | manageAddress |
| `dugnadAddressSavedToast` | manageAddress |
| `dugnadAddressSearchHint` | manageAddress |
| `dugnadAddressStandardBadge` | manageAddress |
| `dugnadAddressSuggestFoot` | manageAddress |
| `dugnadDonationSyncing` | `common/vipps/donation_vipps_return.dart:150` (dies with donations) |
| `dugnadPointsTeamCheckoutNudge` | `campaign/campaign_checkout_screen.dart` |
| `dugnadPointsTeamPurchasePoints` | `campaign/campaign_checkout_screen.dart` |
| `dugnadPointsTeamSelect` | `campaign/campaign_checkout_screen.dart` |
| `dugnadProfileTitle` | `common/account/account.dart:131` |
| `dugnadSupportShareMessage` | success-screen share |

Plus two more shared strings that follow the same rule:
`languages.dugnadSelectAddress` at
`lib/screens/deliveryService/searchStore/search_store.dart:115,118`, and
`languages.cartDugnadEmptyDesc` at
`lib/screens/common/orderCart/order_cart.dart:461`.

**Practical removal path:** delete the 763 dugnad-only plus 137 dead keys
(roughly 900 keys, 45% of the ARB) from all five ARB files, rename the ~13
shared keys to commercial names, then regenerate `app_localizations*.dart`. The
generated Dart files hold ~1,900 getters each and must be regenerated, not
hand-edited.

---

## F. Backend surface (inventory only — no backend changes)

All constants live in `lib/networking/api_constant.dart:310-382`. The client is
`lib/screens/dugnad/dugnad_repo.dart` (1,328 lines) unless noted.

### F.1 — Sports club / points

| Endpoint | Constant | Line |
|---|---|---|
| `sports-club/list` | `endPointSportsClubList` | 311 |
| `sports-club/` (detail) | `endPointSportsClubDetail` | 312 |
| `sports-club/financial-summary` | `endPointSportsClubFinancialSummary` | 313 |
| `sports-club/points-team` | `endPointSportsClubPointsTeam` | 314 |
| `sports-club/points-team/set` | `endPointSportsClubPointsTeamSet` | 315 |
| `sports-club/club/set` | `endPointSportsClubClubSet` | 316 |
| `sports-club/welcome-bonus/claim` | `endPointSportsClubWelcomeBonusClaim` | 317-318 |
| `sports-club/tour/complete` | `endPointSportsClubTourComplete` | 319-320 |
| `points/summary` | `endPointPointsSummary` | 321 |
| `points/ledger` | `endPointPointsLedger` | 322 |

### F.2 — Referrals / share

| Endpoint | Constant | Line |
|---|---|---|
| `referral/validate` | `endPointReferralValidate` | 325 |
| `referral/capture` | `endPointReferralCapture` | 326 |
| `referral/summary` | `endPointReferralSummary` | 327 |
| `share/summary` | `endPointShareSummary` | 328 |

### F.3 — Dugnad privacy, notifications, config, celebrations

| Endpoint | Constant | Line |
|---|---|---|
| `dugnad/privacy` | `endPointDugnadPrivacy` | 330 |
| `dugnad/privacy/update` | `endPointDugnadPrivacyUpdate` | 331 |
| `dugnad/notifications` | `endPointDugnadNotifications` | 334 |
| `dugnad/notifications/unread-count` | `endPointDugnadNotificationsUnreadCount` | 335-336 |
| `dugnad/notifications/mark-read` | `endPointDugnadNotificationsMarkRead` | 337-338 |
| `dugnad/notifications/mark-feed-seen` | `endPointDugnadNotificationsMarkFeedSeen` | 339-340 |
| `dugnad/notifications/prefs` | `endPointDugnadNotificationsPrefs` | 341-342 |
| `dugnad/notifications/prefs/update` | `endPointDugnadNotificationsPrefsUpdate` | 343-344 |
| `dugnad/config` | `endPointDugnadConfig` | 346 |
| `dugnad/celebrations/pending` | `endPointDugnadCelebrationsPending` | 347-348 |
| `dugnad/celebrations/dev/trigger` | `endPointDugnadCelebrationsDevTrigger` | 349-350 |
| `dugnad/celebrations/dev/clear` | `endPointDugnadCelebrationsDevClear` | 351-352 |
| `dugnad/celebrations` | `endPointDugnadCelebrationsConsume` | 353-354 |

### F.4 — Club shop

| Endpoint | Constant | Line |
|---|---|---|
| `dugnad/club-shop/unlock` | `endPointClubShopUnlock` | 356 |
| `dugnad/club-shop/access` | `endPointClubShopAccess` | 357 |
| `dugnad/club-shop/catalog` | `endPointClubShopCatalog` | 358 |
| `dugnad/club-shop/quote` | `endPointClubShopQuote` | 359 |
| `dugnad/club-shop/pay` | `endPointClubShopPay` | 360 |
| `dugnad/club-shop/confirm` | `endPointClubShopConfirm` | 361 |
| `dugnad/club-shop/orders` | `endPointClubShopOrders` | 362 |
| `dugnad/club-shop/order` | `endPointClubShopOrder` | 363 |

### F.5 — Gamification / transfer

| Endpoint | Constant | Line |
|---|---|---|
| `dugnad/gamification/progress` | `endPointDugnadGamificationProgress` | 364 |
| `dugnad/gamification/activity` | `endPointDugnadGamificationActivity` | 365 |
| `dugnad/gamification/career` | `endPointDugnadGamificationCareer` | 366 |
| `dugnad/transfer/window` | `endPointDugnadTransferWindow` | 367 |
| `dugnad/transfer/commit` | `endPointDugnadTransferCommit` | 368 |

### F.6 — Donations

| Endpoint | Constant | Line |
|---|---|---|
| `donation/enabled` | `endPointDonationEnabled` | 370 |
| `donation/fee-preview` | `endPointDonationFeePreview` | 371 |
| `donation/subscriptions` | `endPointDonationSubscriptions` | 372 |

### F.7 — Campaign / matkasse (see §D before treating as dugnad-only)

| Endpoint | Constant | Line | Client |
|---|---|---|---|
| `campaigns/active` | `endPointCampaignsActive` | 375 | `campaign_repo.dart` |
| `campaign/place-order` | `endPointCampaignPlaceOrder` | 376 | `campaign_repo.dart` |
| `campaign/confirm-payment` | `endPointCampaignConfirmPayment` | 377 | `campaign_repo.dart` |
| `campaign/orders` | `endPointCampaignMyOrders` | 378 | `campaign_repo.dart` |
| `campaign/change-method` | `endPointCampaignChangeMethod` | 379 | `campaign_repo.dart` |
| `api/public/campaign/` | `endPointCampaignPublicShow` | 380 | `campaign_repo.dart` |
| `api/public/campaign/order/` | `endPointCampaignPublicOrderStatus` | 381-382 | `campaign_repo.dart` |

### F.8 — Legacy Reen Sports (not in the dugnad block)

`reenSportsMode` and `activeSportsClub` arrive in the **home API response** and
are persisted at `lib/screens/common/home/home_bloc.dart:270-279`. There is no
dedicated endpoint constant; the fields ride on the existing commercial home
payload. Removing them is a backend response-shape decision, not a client-route
deletion.

**Total dugnad-specific endpoints: 48** (F.1–F.6), plus 7 campaign endpoints
(F.7) whose fate follows §D.

---

## G. Risk list

### G.1 — Will break the commercial app if naively deleted

| # | Risk | Evidence |
|---|---|---|
| **G1** | **Deleting `lib/screens/dugnad/` wholesale breaks the build immediately.** 42 files in it are imported by non-dugnad code; six are imported 11–40 times. | §A.0 table. |
| **G2** | **The commercial checkout is built entirely from dugnad-named widgets and has no mode gate.** Removing `dugnad_swipe_button.dart`, `dugnad_subpage_shell.dart`, `dugnad_sheet.dart` or `dugnad_rise_in.dart` leaves `CheckOut` unbuildable. | `deliveryService/checkout/checkout.dart:20-23,110,177,577,770,902,914,1549`. |
| **G3** | **Every loading overlay in the app routes through `DugnadClubLoaderScreen`.** | `full_screen_progress.dart:12`, `global_loading_overlay.dart:28`. |
| **G4** | **`showDugnadSheet()` is the only bottom-sheet primitive in the app** — 24 non-dugnad call sites including logout, order-cancel, tips, promo code, password change, wallet and track-order. | `dugnad_sheet.dart` import count. |
| **G5** | **Splash routing regression.** `onboardingComplete == isDugnadMode && hasClub`. If `DugnadState` is deleted but the three-way branch at `splash_bloc.dart:121` is left as `isLoggedIn() && false`, **every returning user is sent to Login on every cold start.** | `dugnad_state.dart:481`, `splash_bloc.dart:121,224`. |
| **G6** | **Login layout gap.** Removing `ReferralCaptureBanner` / `ReferralManualCodeField` at `login.dart:238-241` leaves the `_regDemoMarginBottom` to `_methodsMarginTop` spacing double-counted; the auth screen needs re-measuring against the design frame. | `login.dart:233-243`. |
| **G7** | **Nav-bar styling parameters go null.** `activePillGradient`, `pillBorderColor` and `activePillShadowColor` at `home_main_v1.dart:383-390` currently resolve to `dugnadPalette?.…`, i.e. `null` in commercial mode. Deleting the dugnad branch is safe **only if** `CircleNavBar` renders acceptably with all three null — never visually verified, because commercial mode is unreachable today. | `home_main_v1.dart:379-390`. |
| **G8** | **The Snurre AI launcher is currently suppressed by dugnad and will suddenly appear everywhere.** `snurre_launcher_policy.dart:68-69` returns `false` whenever dugnad mode is on. Removing those lines un-hides the floating AI launcher across the whole commercial app — an intended un-gating, but a large untested visual change. It also drops `DugnadState.revision` from the rebuild listenable at `main.dart:490`. | `snurre_launcher_policy.dart:66-69`, `main.dart:486-492`. |
| **G9** | **The wallet balance reappears on the profile.** `account_bloc.dart:42-44` currently skips `getWalletBalance()` in dugnad mode. Un-gating restores a network call and a UI row that has not run in this build. | `account_bloc.dart:42-44`. |
| **G10** | **Guest access to the profile disappears.** `account.dart:91` allows the body to render for `isDugnad && isGuestUser()`. With dugnad gone the condition collapses to `isLoggedIn()`, so guests get `_noAccount()`. May be intended, but it is a behaviour change, not a no-op. | `account.dart:91-97`. |
| ~~**G11**~~ ✅ **RESOLVED (Chunk 3)** — mapping inverted; every output value is now Ærend. *Original:* **`brand_scrub.dart` rewrites backend text to "Reen Dugnad" at display time.** Left as-is, the commercial app relabels supplier, legal and support content with the dugnad brand. This is invisible in code review because the strings come from the API. | `brand_scrub.dart:22-59`, plus hardcoded `'Reen Dugnad'` at `common_view.dart:436`, `contact_us_screen.dart:136`, `ds_home.dart:159`. |
| ~~**G12**~~ ✅ **RESOLVED (Chunk 3)** — writes stopped, filter removed, full store list always renders. *Original:* **Legacy Reen Sports filters the commercial store list.** `ds_home.dart:345-357` narrows the food store list to a single club and can render "Matkasse is not available today." It is driven by `prefReenSportsMode` from the **server**, entirely independent of `DugnadState` — deleting dugnad does not disable it. | `ds_home.dart:37-38,345-357`, `home_bloc.dart:270-279`. |
| **G13** | **ARB regeneration is required, not optional.** `app_localizations*.dart` are generated (1,902 getters in the EN file). Editing the ARB without regenerating, or vice versa, produces a silent mismatch. | `lib/l10n/`, `l10n.yaml`. |
| **G14** | **Campaign carries live dugnad state into order payloads.** `campaign_checkout_screen.dart:830` sends `DugnadState.instance.hasClub ? clubId : 0` with the order, and `:897,940` render the club crest. If campaign is kept, this needs a defined commercial value — not just deletion of the reference. | `campaign_checkout_screen.dart:830,897,940`. |
| **G15** | **The celebration orchestrator doubles as a generic do-not-interrupt lock for campaign checkout.** `holdCriticalFlow()` / `releaseCriticalFlow()` at `campaign_checkout_screen.dart:106,207` and `cp_change_sheet.dart:105,111`, and `campaign_tracker.dart:104` hides the pill while `isBlocked`. Deleting the orchestrator removes a coordination mechanism campaign relies on, not just an animation queue. | as cited. |
| **G16** | **`CampaignTrackerController` never fetches in commercial mode.** `campaign_tracker_controller.dart:89-90` returns early unless `isDugnadMode && hasClub`. If the tracker is kept for commercial, this guard must be replaced with a real commercial condition — simply deleting it makes the controller poll for every user. | `campaign_tracker_controller.dart:20,89-90,141`. |

### G.2 — Could not classify (needs a decision)

| # | Question |
|---|---|
| **U1** | **Does the commercial app keep the matkasse campaign feature?** It is reachable from the commercial home (`home_v1.dart:2795-2827`) and the commercial profile (`account.dart:3`), has its own repo, blocs, checkout and Vipps flow, and owns 167 ARB keys — but it also carries live dugnad club and points coupling (§D.1). Everything downstream (7 endpoints, `prefGuestCampaignCheckoutResume`, `vipps_return_screens.dart`, `CampaignTracker`) hinges on this answer. |
| **U2** | **Does the persistent `CampaignTracker` pill appear in commercial mode?** Today it exists only in the dugnad `Stack` branch (`home_main_v1.dart:342-366`). Depends on U1. |
| **U3** | **Is `ReenPreClubTokens` (coral/navy) the commercial brand or dugnad-only?** Used by `home_main_v1.dart:383-390` and `auth_style.dart:805`. If it is the commercial identity, `reen_pre_club_theme.dart` stays and only the "pre-club" naming changes; if not, login and consent need a new palette. |
| **U4** | **What replaces `DugnadClubThemePalette.defaults`?** ~40 commercial files read `context.dugnadTheme`. Off-mode it already returns `defaults` (Ærend purple), so the *values* are correct — but the class, the extension and the `DugnadClubThemeScope` inherited widget all need a commercial home and name. |
| **U5** | **Does the legacy Reen Sports mode (`prefReenSportsMode`) get removed too?** It is a separate, server-driven club system (§B.3, G12). Out of scope for "dugnad removal" as literally worded, but it produces club-shaped behaviour in the commercial app. |
| **U6** | **`CheckOut1` (`checkout1.dart`, 1,000+ lines) is dead code** — no reference outside the file. Delete as part of this cleanup, or leave alone? |
| **U7** | **Does `logout()` keep the logout curtain?** Its doc comment (`utils.dart:754-756`) justifies it purely as a club-repaint guard. Whether it still earns its place after dugnad is a cosmetic call. |
| **U8** | **`splash_bloc.dart:179-194` — `callRunningServiceApi()` has its entire body commented out** and `manageRunningServiceResponse()` (`:196-221`) is unreachable. Restore the running-service resume, or delete both? This predates dugnad; the dugnad rewrite left it stranded. |
| **U9** | **`main.dart:490` — does the Snurre launcher still rebuild correctly** once `DugnadState.instance.revision` is removed from the merged listenable, leaving only `snurreLauncherVisible` and `snurreChatRouteOnTop`? Not verifiable without running the app. |
| **U10** | **`circle_nav_bar.dart` compact-mode code path** (`:53,178,287`) becomes dead once `compactItems` is always `false`. Strip it, or keep it for future use? |

---

## Suggested chunk order

Offered as a map, not as part of the audit findings.

1. **Extract and rename the shared UI kit** (§A.0) — mechanical, no behaviour
   change, unblocks everything else.
2. **Un-gate routing** (§C) — `dugnadAuthDestination`, splash, OTP, logout.
3. **Un-gate the home shell** (§B.2) — collapse every `_isDugnad` ternary to its
   commercial branch.
4. **Resolve U1** (campaign), then delete or de-couple `lib/screens/campaign/**`.
5. **Delete dugnad feature code** (§A.1–A.13).
6. **Remove state, prefs and endpoints** (§B.1, §F).
7. ~~**Brand strings** (G11) and the legacy Reen Sports decision (U5).~~
   ✅ **Done in Chunk 3.** G11 and G12 are resolved; U5 is decided (Reen Sports off).
8. **Purge and regenerate the ARB** (§E) — the **Chunk 5 l10n pass**.

### Carried into the Chunk 5 l10n pass

These three were raised in earlier chunk reports and belong here, not in a
separate later chunk:

| Item | Where | Why it waits for the l10n pass |
|---|---|---|
| `languages.dugnadSelectAddress` | `deliveryService/searchStore/search_store.dart:115,118` | No commercial equivalent key exists; renaming it means touching the ARB, so it rides with the l10n regeneration. Chunk 2 deliberately left it rather than invent copy. |
| The inert `useDugnadTheme` parameter | `screens/common/auth/auth_style.dart:788,796` + 7 call sites | Its mode gate was removed in Chunk 2, so it no longer affects rendering. Only the *name* is dugnad-era — a pure rename, batched with the l10n/naming sweep. |
| Stale `ModeSelect` comment | `screens/snurre/snurre_launcher_policy.dart:87` | Comment only, no behaviour. `ModeSelectScreen` is deleted in Chunk 5; the comment goes with it. |

~~Plus the ~30 remaining hardcoded "Reen Dugnad" literals in commercial code
and the 29 brand-carrying ARB keys.~~ ✅ **Done in Chunk 3b** — 36 literals and
6 commercial ARB keys fixed; l10n regenerated. What is left for Chunk 5 is the
**22 dugnad-only ARB keys** (`dugnad*` / `dg*` / `campaign*`), which die with
their screens.

**Still open, not a Chunk 5 item — `appName`.** `'Reen Dugnad'` in all five
locales (`intl_*.arb:2`). Controls the label under the app icon. Needs a
product-owner decision and must be coordinated with the native
`CFBundleDisplayName` / `android:label` and the store listings.
