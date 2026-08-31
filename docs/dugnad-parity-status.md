# Dugnad design-parity — status receipt

What was audited against the Custom Dugnad prototype, how, and what guards now hold
the line. A receipt, not a narrative. Rules live in `claude-design-to-flutter.md`;
open decisions in `dugnad-open-questions.md`.

## The five clusters

| cluster | screens | what changed |
|---|---|---|
| **Auth / onboarding** | login, otp, mode-select, create-profile, club select/onboard, home | fill-vs-scroll + fixed-px → width-anchored `context.dp`; locale (en→no); nav overlap |
| **Home / gamify** | leaderboard, points, missions, player-card, season cards, STØ, sheens | Family A metal ramp consumed not synthesised; sheen curves gated; per-tone metal insets/drops restored |
| **Matkasse / Kampanje** | campaign, product, cart bar, supplier, countdown, mode | expired states, price tags, `.mk-chero` flush hero; 23-radii method scaling |
| **Donation** | setup, confirm, manage, why-fee, incomplete, failed, fee-calc, sheets | shadows both ways (collapsed *and* expanded); neutral greys de-themed; undeclared borders removed |
| **Privacy / Referral / Support** | visibility, referral-share, support-share, promo, incoming | the 13-site tracking cluster; grey-for-purple; under-elevated highlight shadows |

Plus: two celebration screens gated (`tier_level_up`, `welcome`), the shared feed-item
entrance gated, `career` migrated onto the shared `DugnadLbHero`, dead code deleted.

## Defect classes that recurred, with counts

| class | count | guard that now prevents it |
|---|---|---|
| decimal-shifted em factors | 13 / 5 files | **`tracking_magnitude_guard`** (em > 0.1) + **`tracking_manifest`** (absence) |
| ungated controllers | 22 | **`reduced_motion` harness** + **`initstate_gate_guard`** — now 42/42 gated |
| collapsed `--ae-shadow-card` | 3 | **none** — audit only |
| Family A synthesised not consumed | 2 | **none** — audit only |
| dropped insets | 3 | **none** — audit only |
| token approximated by another's alpha | 3 | **none** — audit only |
| app theming the design's fixed neutrals | 6+ | **none** — audit only |
| undeclared borders | 5 | **none** — audit only |

**The most useful line in this document:** every *value/visual* class — shadows,
insets, token approximation, grey-for-purple, undeclared borders — has **no guard**.
They were caught by manual audit and nothing prevents their return. Only the two
*structural* classes (tracking, lifecycle) and *scaling* are guarded. A future pass
wanting durable coverage should key a guard on each: e.g. "no `BoxShadow` list shorter
than its `--ae-shadow-card` source", "no `theme.primaryHover` where the design cites
`--ae-gray-*`".

## Other guards in place

`scale_once`, `banner_scale`, `subpage_shell_scale`, `shared_constant`,
`hero_mount`, `inset_surface`, `metal_surface`, `sheen_curve` — **225 tests, all green.**

## Coverage measured as ratios, not booleans

- **Reduced-motion:** 42 / 42 `AnimationController` declarations in `lib/screens/dugnad`
  are gated. (The one gap the ratio found — `DugnadFeedEnter` — is now closed.)
- **Scaling:** **95%** (3058 `context.dp` / 3222 design-value literals, 67 files).
  The seven gaps the circular()-radii census could not see — bare width/height/padding
  with no bare radius — are now **closed**: `dugnad_swipe_button`, `dugnad_prize_banner`,
  `dugnad_profile_section`, `dugnad_points_screen`, `dugnad_sheet`, `mk_campaign_card`
  scaled; `tilbud_placeholder` was dead code, deleted. Every file still below 80% is
  legitimate: `points_metal_theme` (context-free theme helper), `club_crest` /
  `dugnad_badge_emblem` (size-relative — scale via their `size` param), and
  `dugnad_player_card` at 73% (the ratio itself miscounting a `height: 0.95` line-height
  ratio and tiny `const` micro-paddings; its scalable geometry is scaled).
  A radii-keyed census could not see these — the ratio could.

## Scope — what was and was not audited

Audited + scaled: **`lib/screens/dugnad/`** (93 files) + 4 auth screens in `common/`.

**Zero coverage** — separate commercial design system (`ui_kits/customer`), never the
Custom Dugnad prototype: `deliveryService` (80), `feed` (47), `campaign` (21),
`rideService` (20), `courier` / `snurre` (6). ~174 files. The rulebook and guards
transfer directly if that surface is ever taken to parity.

## Left deliberately (need a device or a decision, not a blind rebuild)

- `transfer_window` and `season_recap` heroes — **not** hand-rolled `DugnadLbHero`s:
  `season_recap`'s is a minimal solid-primary nav bar (no title; the `.rc-hero` card is
  the hero), `transfer`'s is a centered-title custom hero with an embedded `.dg-deadline`
  card the shared hero has no slot for. Mapping facts, not drift.
- `dn-rcpt` `ListTile → Row` and `.dn-actions` layout — maintainability refactors; the
  visible treatments already match, so a blind rebuild only risks spacing drift.
- On-device pass at 375 / 393 / 430 — the one thing source-level checks cannot settle:
  whether residual height deltas are font metrics or real.
