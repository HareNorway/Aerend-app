# Dugnad design-parity — open questions

Accumulated across the dugnad design-parity audit (auth → home → gamify → matkasse →
donation → privacy/referral/support → the radii groups). Sorted into what was done,
what needs an engineering decision, and what needs a product decision.

Each product question below is **one line stating the decision needed** — you do not
need the audit history to answer it.

---

## (a) Safe maintenance — DONE

- `dugnad_placeholder_screen.dart` — dead code, zero references. **Deleted.**
- `matkasse_product_screen` — unused `dugnad_models` import. **Removed.**

## (b) Structural — needs an engineering decision

- **`DugnadLbHero` migration.** `season_recap`, `transfer_window` and `career` each
  hand-roll their own `.lb-hero` top bar instead of the shared `DugnadLbHero`. Migrate
  all three onto the shared hero, or keep them hand-rolled?
- **`dn-rcpt` layout.** The donation receipt row is built as a `ListTile`; the design is
  a `Row`. Refactor to `Row`, or accept the `ListTile`?
- **`.dn-actions` layout.** The donation change/pause/exit actions render as three inline
  buttons; the design is full-width stacked rows. Refactor, or accept the inline form?

## (c) Product questions — for Didrik

**Absent elements** (in the design, not built in the app — build or drop?):

- `.td-squad-agg` — build the team-detail squad-aggregate row, or leave it out?
- `.mi-prog` sweep — add the animated sweep-highlight layer on the mission progress bar?
- `.dg-mission.season` — give season missions their distinct gradient treatment?
- `.dg-mission.strong` — give "strong" missions the inset purple ring?
- `transfer` `switch` / `signed` steps — build these two transfer-flow steps?
- `teamdetail` climb-tips — what content belongs in the team-detail climb-tips section?
- `teamswitch` / `visibility` screens — should these exist as standalone screens?
- `.dn-badge-unlock` — build the donation "Fast medlem" badge-unlock card on the success
  screen?

**Presentation / value decisions:**

- `.dn-mpts` — should the donation points be an inline row (design) rather than the
  current block?
- **Error-CTA colour** — should error-screen CTAs (`donation_incomplete`,
  `donation_setup_failed`) use the club colour (`theme.primary`) or the fixed
  purple-700 they hardcode?
- **Sheet radius: `points_team_sheet`** — the team picker is a raw white bottom sheet at
  radius 24; should it adopt the `.dg-msheet` lavender vocabulary at 26?
- **Sheet radius: `dugnad_address_drawer`** — the address drawer is a raw bottom sheet at
  radius 24; should it be the `.dg-msheet` 26?

**Unstyled / app-authored surfaces** (no design rule exists — are the app's own values
acceptable, or should design supply rules?):

- `.dg-ref-*` (`referral_share`) — the club-referral screen's classes are mounted in the
  prototype but defined nowhere in the CSS layer; its visual values are app-authored.
- `dugnad_referral_promo_sheet` — the floating home referral promo has no matching design
  class at all; entirely app-authored.

---

## Scope statement — what remains unaudited

The design-parity audit and the width-scaling (`context.dp`) pass covered **only
`lib/screens/dugnad/`** (93 files, 59 scaled) plus the early auth screens in
`lib/screens/common/` (4).

The rest of the customer app has had **no design-parity audit and no width-scaling**:

| area | dart files | scaled |
|---|---|---|
| `feed` | 47 | 0 |
| `deliveryService` | 80 | 0 |
| `campaign` | 21 | 0 |
| `rideService` | 20 | 0 |
| `courierService` | 3 | 0 |
| `snurre` | 3 | 0 |

These are the **commercial** customer surfaces, which follow a separate design system
(`ui_kits/customer/*.css`), not the Custom Dugnad prototype. They are out of scope for
this effort but are the honest answer to "is the customer app done?" — the dugnad
feature is; the commercial surfaces have not been touched.
