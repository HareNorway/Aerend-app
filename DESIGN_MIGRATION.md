# Ærend Customer App — Design Migration

Porting the Claude Design system (`rend-design-system/`) into the Flutter customer
app (`Hare-Customer/`), "same to same". This was a visual restyle plus dugnad
donation messaging wiring. No business logic, payment processing, cart mutation, or
navigation structure was changed.

Source of truth: `rend-design-system/project/colors_and_type.css` (tokens) and
`ui_kits/customer/*.jsx` (screens).

---

## 1. Where the Design System Lives

| Layer | File(s) | What |
|-------|---------|------|
| **Color tokens** | `lib/theme/sc_saas_theme.dart` (`ScSaasThemeTokens`) | All color constants, shadow constants, font family getters |
| **Legacy colors** | `lib/constant/colors.dart` | Repointed to design values (e.g. `colorPrimary` → `#7F5FC4`) |
| **Spacing / radii** | `lib/theme/responsive/responsive_tokens.dart` (`UiSpacing`, `UiRadius`) | 4-px spacing scale, design radii |
| **Dimensions** | `lib/constant/dimensions.dart` | Responsive factor-based sizing (base values aligned to 375×812 frame) |
| **Type helpers** | `lib/utils/utils.dart` | `aeDisplay` through `aeMono` — see table below |
| **Surface decorations** | `lib/commonView/surface_decorations.dart` (`AeSurface`) | `card()`, `buttonGlow()`, `deep()`, `shiny()`, `shinyPurple()` |
| **Currency formatter** | `lib/utils/utils.dart` → `formatNok()` | Norwegian price display: `"149 NOK"` or `"149,90 NOK"` |
| **Theme** | `lib/theme/sc_saas_theme.dart` (`ScSaasTheme.light()`) | ThemeData with Plus Jakarta Sans, brand colors, input/snackbar/dialog themes |

---

## 2. Design Tokens

### Colors (`ScSaasThemeTokens`)

| Token | Hex | CSS var | Usage |
|-------|-----|---------|-------|
| `primary` | `#7F5FC4` | `--ae-purple-600` | Primary action, buttons |
| `primaryHover` | `#6B4FA8` | `--ae-purple-700` | Hover, pressed, links |
| `primarySoft` | `#9B7FD4` | `--ae-purple-500` | Secondary surfaces |
| `primaryDisabled` | `#B8A2E2` | `--ae-purple-400` | Disabled state |
| `primaryTint` | `#E8DEF5` | `--ae-purple-100` | Surface tint, chips |
| `background` | `#F4F0FB` | `--ae-lavender` | App canvas |
| `text` | `#2D1B5B` | `--ae-midnight` | Headings, dark buttons |
| `ink` | `#0F1620` | `--ae-ink` | Body text on light |
| `muted` | `#6B4FA8` | `--ae-purple-700` | Muted/secondary text |
| `accent` | `#6CC985` | `--ae-acid` | Rare accent |
| `success` | `#22A769` | `--ae-success` | Open, paid, positive |
| `danger` | `#DC4040` | `--ae-error` | Reject, destructive |
| `warning` | `#C98A1A` | `--ae-warning` | Pending, attention |
| `gray50` | `#F8F9FA` | `--ae-gray-50` | Very light bg |
| `gray100` | `#EFF1F4` | `--ae-gray-100` | Dividers, borders |
| `gray300` | `#CFD1D7` | `--ae-gray-300` | Disabled borders |
| `gray500` | `#8F8F8F` | `--ae-gray-500` | Secondary text |
| `gray700` | `#555660` | `--ae-gray-700` | Field labels on dark |
| `card` | `#FFFFFF` | — | Card surfaces |
| `border` | `#EFF1F4` | `--ae-gray-100` | Border color |
| `midnightButton` | `#2D1B5B` | `--ae-midnight` | Dark button fill |

### Shadows (`ScSaasThemeTokens`)

| Constant | CSS var | Usage |
|----------|---------|-------|
| `shadowCard` | `--ae-shadow-card` | Resting card elevation (brand-tinted, never black) |
| `shadowButton` | `--ae-shadow-button` | Purple glow on primary buttons |
| `shadowDeep` | `--ae-shadow-deep` | Floating sheets, modals |

### Type Scale (`ae*` helpers in `lib/utils/utils.dart`)

| Helper | Size | Weight | Line-height | Letter-spacing | Default color |
|--------|------|--------|-------------|----------------|---------------|
| `aeDisplay()` | 30 | w800 | 1.05 | -0.60px | Midnight |
| `aeH1()` | 26 | w800 | 1.15 | -0.52px | Midnight |
| `aeH2()` | 22 | w800 | 1.2 | -0.33px | Midnight |
| `aeH3()` | 17 | w800 | 1.2 | -0.17px | Midnight |
| `aeTitle()` | 15 | w700 | 1.25 | -0.075px | Midnight |
| `aeBody()` | 15 | w500 | 1.45 | 0 | Ink |
| `aeLabel()` | 14 | w600 | 1.3 | -0.07px | Midnight |
| `aeCaption()` | 12 | w500 | 1.4 | 0 | Gray 500 |
| `aeOverline()` | 10.5 | w800 | 1.2 | +0.84px | Gray 500 |
| `aeMono()` | 14 | w500 | — | -0.14px | Midnight |

All accept an optional `color` parameter. Font family: Plus Jakarta Sans (mono: JetBrains Mono).

### Spacing (`UiSpacing` in `responsive_tokens.dart`)

| Token | Value |
|-------|-------|
| `xxs` | 2 |
| `xs` | 4 |
| `sm` | 8 |
| `md` | 12 |
| `lg` | 16 |
| `screen` | 20 |
| `xl` | 24 |
| `xxl` | 32 |
| `xxxl` | 40 |
| `xxxxl` | 56 |

### Radii (`UiRadius`)

| Token | Value | CSS var |
|-------|-------|---------|
| `sm` | 8 | `--ae-r-sm` |
| `md` | 14 | `--ae-r-md` |
| `lg` | 18 | `--ae-r-lg` |
| `xl` | 24 | `--ae-r-xl` |
| `pill` | 999 | `--ae-r-pill` |

---

## 3. Reusable Components

| Component | File | Purpose |
|-----------|------|---------|
| `CustomFillButton` | `lib/commonView/custom_fill_button.dart` | Primary button with purple-glow shadow, disabled state |
| `CustomBorderButton` | `lib/commonView/custom_border_button.dart` | Outlined / ghost / dark button variants (`AeBorderButtonVariant`) |
| `TextFormFieldCustom` | `lib/commonView/custom_text_field.dart` | Input with 8px radius, 4px purple focus ring, error state |
| `AeSegmentedControl` | `lib/commonView/segmented_control.dart` | Pill-container toggle (e.g. Delivery / Pickup) |
| `AeOverlineText` | `lib/commonView/overline_text.dart` | 10.5px uppercase with wide tracking |
| `aeBadge()` | `lib/commonView/common_view.dart` | Status pill with semantic variants (info/success/warning/error/primary/dark) |
| `AeSurface` | `lib/commonView/surface_decorations.dart` | BoxDecoration helpers: `.card()`, `.buttonGlow()`, `.deep()`, `.shiny()`, `.shinyPurple()` |
| Floating pill nav | `lib/commonView/circle_nav_bar.dart` | Frosted-glass bottom nav with expanding active tab |
| Category wheel | `lib/screens/deliveryService/home/widgets/category_wheel.dart` | Radial shiny-chip arrangement for store categories |
| Service wheel | `lib/screens/common/home/home_v1.dart` (`_ServiceWheel`) | Radial shiny-chip arrangement for service categories (Food/Fashion/etc.) |
| Purple hero | `lib/screens/deliveryService/home/widgets/purple_hero.dart` | Purple gradient header with location + search pill |
| Promo carousel | `lib/screens/deliveryService/home/widgets/promo_carousel.dart` | Auto-rotating card carousel with dot indicators |

---

## 4. Navigation

### 6-Tab Floating Pill Nav (`lib/screens/common/homeMainV1/home_main_v1.dart`)

| Index | Label | Screen | File |
|-------|-------|--------|------|
| 0 | Hjem | `HomeV1` | `lib/screens/common/home/home_v1.dart` |
| 1 | Sok | `SearchStore` | `lib/screens/deliveryService/searchStore/search_store.dart` |
| 2 | Feed | `FeedShellScreen` | `lib/screens/feed/feed_shell_screen.dart` |
| 3 | AI | `SnurreChatScreen` | `lib/screens/snurre/snurre_chat_screen.dart` |
| 4 | Kurv | `OrderCart` | `lib/screens/common/orderCart/order_cart.dart` |
| 5 | Profil | `Account` | `lib/screens/common/account/account.dart` |

**Legacy index remap:** External callers (15+ sites) pass `homeIndex: 0/1/2/3/4` using the old 5-tab positions. `_remapLegacyIndex()` in `home_main_v1.dart` translates old→new: 0→0, 1→4, 2→0, 3→1, 4→5.

---

## 5. Screens Restyled

| Screen | File(s) | Summary |
|--------|---------|---------|
| **Splash** | `lib/screens/common/splash/splash.dart` | Purple gradient, fade-in animation, brand mark + tagline |
| **Login** | `lib/screens/common/login/login.dart` | ae* inputs, purple glow CTA, Norwegian labels. SSO: Google + Apple (iOS) only. |
| **Home hub (Hjem)** | `lib/screens/common/home/home_v1.dart` | Purple gradient hero, shiny search pill, `_ServiceWheel` (replaces CircularMotion), restyled carousels + restaurant cards |
| **DSHome (per-service)** | `lib/screens/deliveryService/home/ds_home.dart` | `PurpleHero`, `PromoCarousel`, `CategoryWheel`, `AeSurface.card()` store cards |
| **Store Detail** | `lib/screens/deliveryService/storeDetail/store_detail.dart` | Parallax hero, logo overlay, pinned tabs, AeSurface product cards, purple cart bar, restyled modal |
| **Search (Sok)** | `lib/screens/deliveryService/searchStore/search_store.dart` | Flat AppBar, 8px search field, pill category chips, AeSurface cards |
| **Order Cart (Kurv)** | `lib/screens/common/orderCart/order_cart.dart` | AeSurface cards, purple quantity controls, purple glow checkout bar, `formatNok()` prices |
| **Checkout** | `lib/screens/deliveryService/checkout/checkout.dart` | Segmented Delivery/Pickup toggle, AeSurface address/ETA/summary cards, purple glow CTA |
| **Feed** | `lib/screens/feed/` (shell + 13 components) | Purple gradient header, AeSurface post cards, story bubbles, ae* type throughout |
| **Snurre (AI)** | `lib/screens/snurre/snurre_chat_screen.dart` | Restyled AppBar/composer/bubbles/suggestions/landing-grid (chrome only; card renderers untouched) |
| **Profile** | `lib/screens/common/account/account.dart` | AeSurface cards, grouped settings with Material icons, ae* helpers |
| **Order Tracking** | `lib/screens/deliveryService/trackOrder/track_order.dart` | Header/store-row/route-box/OTP/timeline labels restyled; Norwegian labels |
| **Chat** | `lib/screens/common/chatting/chatting.dart` + `item_chatting.dart` | Purple gradient header, styled bubbles (purple sent / gray50 received), purple send button |
| **Campaign/Matkasse** | `lib/screens/campaign/` (6 screens) | AeSurface cards, club-earns banner, urgency badges, donation line, Norwegian labels |

### New widget files created

| File | Used by |
|------|---------|
| `lib/screens/deliveryService/home/widgets/purple_hero.dart` | `ds_home.dart` |
| `lib/screens/deliveryService/home/widgets/promo_carousel.dart` | `ds_home.dart` |
| `lib/screens/deliveryService/home/widgets/category_wheel.dart` | `ds_home.dart` |
| `lib/commonView/segmented_control.dart` | Available (not yet wired into checkout toggle) |
| `lib/commonView/overline_text.dart` | Available |
| `lib/commonView/surface_decorations.dart` | Used app-wide |

---

## 6. Dugnad Donation Messaging

### Backend (Hare-AdminPanel)

**Endpoint 1:** `GET /api/public/campaign/{slug}` (live state)

Added to `fullPayload()` in `app/Http/Controllers/Api/Public/PublicCampaignController.php`:

| Field | Type | Source |
|-------|------|--------|
| `club_payout_type` | `string` ("percent" or "fixed") | `Campaign::effectiveClubPayoutType()` |
| `club_payout_value` | `float` (e.g. 10.00) | `Campaign::effectiveClubPayoutValue()` |

**Endpoint 2:** `POST /api/customer/campaign/place-order`

Added to order envelope in `app/Http/Controllers/Api/CustomerCampaignController.php`:

| Field | Type | Source |
|-------|------|--------|
| `club_share_amount` | `int` (ore) | `$order->club_payout_amount * 100` (from `SportsClubService::computePayoutSnapshotsByOrder()`) |
| `club_name` | `string?` | `$club->name` |
| `club_logo` | `string?` | `resolveClubLogo($club)` via `MediaUrlResolver` |

New private method added: `resolveClubLogo(StoreDetails $club)`.
New import: `use App\model\StoreDetails;`.

### Flutter (Hare-Customer)

**Pojo fields added:**

| Model | File | Fields |
|-------|------|--------|
| `CampaignDetail` | `lib/screens/campaign/models/campaign_detail_pojo.dart` | `clubPayoutType` (String?), `clubPayoutValue` (double?) |
| `CampaignOrderInfo` | `lib/screens/campaign/models/campaign_order_pojo.dart` | `clubShareAmount` (int?), `clubName` (String?), `clubLogo` (String?), `clubShareNokFormatted` getter |

**Screens rendering the messaging:**

| Screen | What | Condition |
|--------|------|-----------|
| `campaign_detail_screen.dart` | "X% av kjopet gar til [club]" banner | `clubPayoutType == "percent"` and `clubPayoutValue > 0` |
| `campaign_order_success_screen.dart` | Green "Takk! Du bidro med X kr til [club]" banner | `clubShareAmount != null && > 0` |

---

## 7. Conventions for Future Work

1. **Text styles:** Use `ae*()` helpers from `utils.dart`. Do NOT call `GoogleFonts.plusJakartaSans(...)` or `GoogleFonts.nunito(...)` directly.
2. **Card/shadow decoration:** Use `AeSurface.card()`, `.buttonGlow()`, `.deep()`, `.shiny()`, `.shinyPurple()`. Never use `Colors.grey.withOpacity(...)` shadows.
3. **Colors:** Use `ScSaasThemeTokens.*` constants. The legacy `colorPrimary`, `colorGreen`, `colorRed` etc. in `colors.dart` are repointed but prefer the token class for new code.
4. **Price formatting:** Use `formatNok(double)` from `utils.dart`. Output: `"149 NOK"` or `"149,90 NOK"`. Do NOT use `toStringAsFixed(2)` or `"NOK ${x}"` prefix format.
5. **Border radii:** Use `UiRadius.sm/md/lg/xl/pill` constants.
6. **UI language:** Norwegian (bokmol). Ideally from `languages.*` localization, but hardcoded Norwegian is acceptable during migration.
7. **Build process:** Do NOT rely on `flutter analyze` (Cursor linter produces noise). Build debug APK in batches: `flutter build apk --debug`.

---

## 8. Known Deferred / Intentionally Unstyled

These are NOT bugs — they were intentionally left for future work:

| Item | Reason |
|------|--------|
| **Order-item editor modal** (`_openOrderItemEditor` in `checkout.dart`) | 300+ lines of cart mutation API calls tightly coupled to `StatefulBuilder`. Too risky to restyle without breaking payment flow. |
| **Active-order tracker bubble** (`home_v1.dart` ~lines 1060-1125) | `DashedCircularProgressBar` + `StreamBuilder<HomeTrackOrderPojo>` + timer polling. Color tokens already correct from Chunk 1. |
| **Track-order action buttons** (Chat/Call/Receipt/Cancel/Home) | Complex conditional layout with dynamic `deviceWidth * 0.29/0.45/0.92` sizing. Already use repointed `colorPrimary`/`colorGreen`. |
| **Reels tab** (`feed_reels_tab.dart`) | Placeholder "Coming Soon" with dark background (#0D0B16). No video playback infrastructure. |
| **Dark mode** | `ScSaasTheme.dark()` skeleton exists but is incomplete. Light mode only (`ThemeMode.light`). |
| **Campaign list card payout %** | List API (`POST /api/customer/campaigns/active`) doesn't return `club_payout_type`/`value`. Static "Klubben tjener pa hvert kjop" banner used instead. Backend addition needed. |
| **Fundraising progress bar** | No `fundraising_goal`/`fundraising_raised` fields in campaign API. |
| **Club onboarding / mode gate** | Design shows Dugnad vs Commercial mode selection. Not built — requires club listing API + mode state. |
| **`AeSegmentedControl`** | Built but not wired into checkout toggle (checkout uses restyled `TabBar` instead to avoid rewiring `TabBarView` state). |
| **Snurre card renderers** | 5 card-rendering methods (~1200 lines) use `GoogleFonts.plusJakartaSans` directly. Left as-is to avoid touching the fragile animation + card extraction engine. |
