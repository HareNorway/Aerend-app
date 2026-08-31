# Porting Claude Design (CSS/JSX) to Flutter

The Ærend prototypes are authored as CSS + React on a fixed phone frame. Flutter is
not a browser, and roughly a dozen specific mismatches between the two have caused
every parity bug on this project so far — several of them more than once.

This is the rulebook. Each rule states the reasoning, because the reasoning is what
transfers to the next screen and the next app; the rule alone doesn't.

---

## Never a bug — scan this before filing a discrepancy

These are the false positives this project has actually filed, most of them
more than once. Each has a full rule below; this list exists because nobody
opens a twenty-rule reference mid-comparison.

- **Authored `font-weight: 900` renders 800.** Plus Jakarta Sans has no 900
  face. Never a discrepancy, in either direction. *(rule 14)*
- **`getComputedStyle().borderWidth` is device-snapped.** An authored `1.5px`
  can read back `1.25px`. Read hairlines from CSS source. *(rule 19)*
- **A card's own computed background may be a base layer**, with a positioned
  child doing the visible painting. Walk the stacking context. *(rule 17)*
- **`--ae-shadow-card` is a default, not a rule.** Some cards are deliberately
  single-layer; "upgrading" one to three layers is a regression. *(rule 18)*
- **A value styled inline in JSX has no stylesheet rule to grep.** Absence from
  the CSS is not absence from the design. *(rule 19)*
- **A large CSS file can truncate silently at 256 KiB.** A rule missing from
  one read is not proof it does not exist — check the `truncated` flag.
  *(rule 10)*

Two habits that prevent most of the rest: **identify the widget first, then
read its values** — never match on a distinctive colour or shadow string and
infer the element — and **ask before assuming a difference is deliberate**.

---

## 1. The design is a fixed 375 × 812 frame

`.ae-screen` in `ui_kits/kit-shared.css`:

```css
.ae-screen { width: 375px; height: 812px; font-size: 15px; line-height: 1.4; }
```

**Every CSS px in the whole design system is authored against a 375pt-wide viewport.**
A `height: 56` button is 56pt on a 375pt frame — it is not "56pt on every device".

Port with **one width-anchored scale factor**:

```dart
double get ds => (MediaQuery.sizeOf(this).width / 375.0).clamp(0.85, 1.20);
double dp(double designPx) => designPx * ds;
```

Anchor to **width only**. The frame's aspect (375×812 → 2.165) matches a modern
iPhone's (430×932 → 2.167) almost exactly, so scaling by width scales the vertical
rhythm correctly too. The exception is the iPhone SE (375×667): `ds == 1.0`, the
content is design-exact, and it simply scrolls — which is what the prototype does when
you shorten its frame.

**Why not fractions of the screen?** An older approach here used
`0.025 × deviceAverageSize` (a mean of width and height). That is wrong at *every*
size including the design's own, and drifts unpredictably with aspect ratio. A
width-anchored factor is exactly `1.0` at 375, which makes the reference frame
pixel-perfect and every regression measurable against it.

Above ~450pt (where `ds` clamps) stop scaling and centre a `dp(375)` column, so a
tablet gets a phone-width layout rather than a 2.7×-blown-up phone.

## 2. Scale each value exactly once

The costliest bug on this project. A bulk transform wrapped `fontSize: 24` into
`fontSize: context.dp(24)`, and a second transform appended `.dp(context)` to the same
`style:` expression. Every text value was then multiplied twice — `ds²`, which is
**+4.8% at 393pt and +14.7% at 430pt**.

It was hard to spot because only *text* overshot: geometry had gone through `dp()`
once and measured correct. Cards looked subtly cramped and the page read "a little
big", with no single obviously-wrong number.

**Guard it in CI.** `test/layout/scale_once_guard_test.dart` fails if any `style:`
expression contains both `context.dp(` and `.dp(context)`. Review does not catch this;
a test does.

## 3. `em` is relative, Flutter's `letterSpacing` is absolute

CSS `letter-spacing: -0.02em` on 24px text means **−0.48px**. Flutter's
`letterSpacing: -0.02` means **−0.02 logical px** — visually nothing.

Ported literally, every heading and numeral tracks loose, and it gets worse the larger
the type. This is a large part of what reads as "cheap" or "not premium".

```dart
// wrong
fontSize: context.dp(24), letterSpacing: -0.02,
// right
fontSize: context.dp(24), letterSpacing: context.dp(24) * -0.02,
```

Watch the **positive** tracking on uppercase labels — `.dg-label` is
`font-size: 11px; letter-spacing: 0.08em` → `+0.88px`. Collapsing that to `0.08px`
visibly squashes every uppercase section header.

### The risk is hand-rolled `TextStyle`s, not the whole tree

Seven sites in this repo got this wrong, and **every one was an ad-hoc
`TextStyle(...)`**. Anything routed through the `AeDugnadText.*` helpers is
correct by construction, because the conversion happens one layer down:

```dart
letterSpacing: letterSpacingEm != null ? size * letterSpacingEm : null,
```

So `AeDugnadText.sectionLabel()` is right without the call site doing anything,
while a hand-written `TextStyle(fontSize: 11, letterSpacing: 0.08)` beside it is
10× under. Two spellings that look equally deliberate.

This narrows the triage: when auditing tracking, **skip every style that goes
through a helper and read only the hand-rolled ones.** It also suggests the
fix direction — a value that must be converted should be converted in one
place, not at each call site.

## 4. CSS shadows are lists, and the first layer is often a hairline ring

`--ae-shadow-card` is three layers:

```css
0 0 0 1px       rgba(45,27,91,0.05)   /* ring: no blur, 1px spread */
0 2px 5px       rgba(45,27,91,0.06)
0 10px 22px -8px rgba(45,27,91,0.12)
```

```dart
const [
  BoxShadow(color: Color(0x0D2D1B5B), spreadRadius: 1),               // ring
  BoxShadow(color: Color(0x0F2D1B5B), blurRadius: 5, offset: Offset(0, 2)),
  BoxShadow(color: Color(0x1F2D1B5B), blurRadius: 22, offset: Offset(0, 10),
            spreadRadius: -8),
]
```

**Never collapse a multi-layer shadow into one `BoxShadow`.** The ring is what makes a
card read crisp instead of floaty; the wide soft layer alone reads cheap.

## 5. `inset` shadows have no `BoxShadow` equivalent — fake them, never drop them

Several tokens are inset-led (`--ae-shiny-shadow`, the metal `M_SHADOW` family). There
is no inset mode on `BoxShadow`, and silently dropping those layers is how surfaces end
up looking flat.

Approximate the inset highlight with an edge gradient **inside** the clipped container,
with the outer drop shadow on the parent:

```dart
DecoratedBox(
  decoration: BoxDecoration(
    gradient: metalGradient,
    borderRadius: BorderRadius.circular(r),
    boxShadow: [ /* outer layers only */ ],
  ),
  child: DecoratedBox(                     // the inset highlight
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(r),
      gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.white.withValues(alpha: 0.75), Colors.white.withValues(alpha: 0)],
        stops: const [0.0, 0.02],          // a 1px inset on a ~50px card
      ),
    ),
    child: content,
  ),
)
```

Derive the stop from real geometry: a `1px` inset on a card of height `H` is `1 / H`.
Build it once as a shared surface widget and route every card through it — hand-rolling
the stack per card is how they drift apart.

## 6. CSS shadow spread is the 4th length, and is often negative

`0 10px 22px -8px` → `offset: Offset(0, 10), blurRadius: 22, spreadRadius: -8`.

Omitting a negative spread makes the shadow far too wide and heavy. It is easy to miss
because three-length shadows are more common.

## 7. `line-height` inherits

`.ae-screen` sets `line-height: 1.4`. A rule that declares no `line-height` **inherits
1.4** — it does not get a browser default, and it certainly does not get Flutter's.

`.auth-head h1 { font-size: 26px }` with no line-height is `26 × 1.4 = 36.4px` of block
height. Assuming otherwise shifted every auth subtitle by ~7px.

`height` in a Flutter `TextStyle` is a ratio and must **not** be scaled by `ds` — only
`fontSize` and `letterSpacing` scale.

## 8. Clamp OS text scaling, and screenshot at default

The prototype has **no OS text scaling**. A device above default text size will always
render larger, and any screenshot comparison is invalid.

```dart
MediaQuery.withClampedTextScaling(minScaleFactor: 1.0, maxScaleFactor: 1.15, child: child)
```

Clamp at the app root — do not disable it outright (that silently breaks accessibility)
and do not override it per screen. Harden layouts against the 1.15 ceiling with
`Flexible` + `TextOverflow.ellipsis` on any label inside a fixed-height control.

**Set the device to default text size before taking parity screenshots.**

## 9. Flex containers

`flex: 1` + `overflow-y: auto` → fill the viewport but stay scrollable:

```dart
LayoutBuilder(
  builder: (context, c) => SingleChildScrollView(
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: c.maxHeight),   // minHeight, never height
      child: Column(...),
    ),
  ),
)
```

A fixed `height:` overflows on short devices. `minHeight` fills when there is room and
scrolls when there isn't.

`margin-top: auto` on one child → **`MainAxisAlignment.spaceBetween` over exactly two
groups.** A literal `Spacer()` **throws** here: `ConstrainedBox` passes
`maxHeight: infinity` down from the scroll view, and a flex child under unbounded
main-axis constraints asserts. `spaceBetween` still distributes correctly because
`RenderFlex` measures free space against its *constrained* size.

Adjacent margins **do not collapse** in a flex column, so `margin-bottom: 16` followed
by `margin-top: 18` is a 34px gap, not 18.

## 10. Read CSS in ranges, and check truncation

`dugnad/dugnad.css` is over 256 KiB and the design fetch **truncates silently** at that
cap. The response carries a `truncated: true` flag.

Missing that flag once produced a confident, wrong conclusion that a dozen `.auth-*`
and `.otp-*` rules "do not exist anywhere in the project" — they were simply past the
cut. **A rule being absent from one read is not evidence it does not exist.**

Read in ranges and check `truncated` on every read.

## 11. Verify by ratio, not by pixel

The single assertion that has caught every real bug here:

```dart
expect(elementHeight / screenWidth, closeTo(designPx / 375, 0.0005));
```

Check it at 375×667, 375×812, 393×852 and 430×932. If an element holds the same
fraction of the screen at every size, it is proportionally correct. Absolute-pixel
assertions only re-check your own arithmetic.

Pair it with an exactness guard at 375: `ds == 1.0` there, so every value must equal
its literal design px. That keeps the reference frame pixel-perfect.

## 12. The same component can appear twice with different treatments

`.dg-points-card.metal-*` (150deg, two stops, pale) and `M_BG` in `club-select.jsx`
(135deg, three stops with a **48%** midpoint, saturated) are both "the metal points
card" — but they belong to different screens. One shared helper serving both will be
wrong on one of them.

Before porting a component, confirm **which selector the screen you are building
actually mounts**. Trace it in the JSX, not by name similarity.

Related: a two-stop `LinearGradient` with no explicit `stops` looks plastic where the
design specifies a midpoint. `135deg` in CSS maps to
`begin: Alignment.topLeft, end: Alignment.bottomRight`.

## 13. `tabular-nums` needs an explicit font feature

`font-variant-numeric: tabular-nums` (on `.dg-points-card .v`, `.lb-level .pts`
and several `gamify.css` stat values) has no automatic Flutter equivalent:

```dart
TextStyle(fontFeatures: [FontFeature.tabularFigures()])
```

Without it digits keep their proportional widths, so any number that changes —
a count-up, a live points total, a countdown — visibly jitters as glyphs swap.
Apply it to every numeral the design marks, not just the big one.

## 14. A CSS `font-weight` above the loaded range clamps

`colors_and_type.css` loads Plus Jakarta Sans at `wght@400;500;600;700;800`.
Rules that ask for `font-weight: 900` therefore render at **800** in the
browser — the heaviest face actually loaded.

So an authored 900 against an app's `FontWeight.w800` is **not** a defect;
both render 800. Check what the design's `@import` actually loads before
treating a weight mismatch as a bug, and port the *rendered* weight rather than
the authored one. Bundling a heavier family to "fix" it would make the app
diverge from the design.

### Standing verdict for this design — stop re-deriving it

**Authored `900` renders as `800` everywhere in this design. It is never a
discrepancy. Do not file it, do not "fix" it in either direction.**

This has now surfaced three times — the leaderboard numerals, the metal
tokens, and `DugnadFeedEntryBanner`'s variant titles — and been re-derived from
scratch each time, which is why it is recorded as a verdict and not just a
mechanism.

`font-weight: 900` appears dozens of times across `gamify.css` alone:
`.lb-tablehead .ttl`, `.lb-trow .pts b`, `.scl-stat b`, `.td-stat .v`,
`.sq-more .n`, `.dg-cd-panel .big`, and more. Every one of them renders 800.
An app using either `FontWeight.w800` or `w900` against them is already
correct, because Flutter clamps against the same family.

## 15. A metal or gradient surface is rarely one gradient

`.lb-level.metal-*` carries ten tone-keyed tokens, not two. Beyond the ramp and
the shadow there are **two stacked `radial-gradient` overlays with off-canvas
centres** (`at 88% -25%` and `at 2% 130%`) that throw a specular highlight in
from the top-right and a warm bounce from the bottom-left.

Those overlays are what make a surface read as lit metal. Port the linear ramp
alone and it looks like coloured plastic no matter how exact the hex values
are — and no measurement or geometry test will ever flag it.

In Flutter: stack them as `RadialGradient`s inside the clip, with `Alignment`
values outside the `-1..1` box to keep the centres off-canvas. Also check for a
per-tone override of a shared element (platina alone replaces `.lb-level-shine`
with a four-stop holographic band).

## 16. Reduced motion must stop the controller, not hide its output

Every animation block in this design sits inside
`@media (prefers-reduced-motion: reduce)`. Honouring that in Flutter has three
traps, all of which shipped here, and none of which is visible unless you
actually exercise the path:

**Gating in `build` is not gating.** Starting a controller in `initState` and
then returning the un-animated child from `build` leaves the controller
running — burning battery and holding a frame permanently scheduled — while
looking correct. `disableAnimationsOf` appearing in a file proves nothing;
what matters is whether the controller is prevented from *starting*.

**The gate goes in `didChangeDependencies`, never `initState`.** Inherited
widget lookups are illegal in `initState`. `didChangeDependencies` is also the
right place because it re-fires when the user toggles the setting at runtime —
guard with a `_started` flag so it does not double-start.

**`mounted` is not a substitute for cancelling the timer.** It stays `true`
between deactivate and dispose, so a fire-and-forget `Future.delayed` can fire
against a deactivated element, re-register the controller, and assert on the
`TickerMode` lookup. Model `animation-delay` as a `Timer` stored on the state
and cancelled in `dispose()`.

**And re-check the gate inside the timer's callback, not just `mounted`.** A
delay can outlive a settings change as easily as a disposal: the user turns
reduced motion on during the 1.2s wait, the widget is still mounted, and the
callback happily starts a controller the gate had already refused. The
callback needs both checks.

```dart
_delayTimer = Timer(delay, () {
  if (!mounted) return;
  if (MediaQuery.disableAnimationsOf(context)) return;   // <- the second one
  _controller.repeat();
});
```

A fourth, milder one: avoid `late final AnimationController`. Under reduced
motion the field may never be read, leaving `TickerProviderStateMixin` with an
unstable ticker set. Construct eagerly in `initState`.

Under reduced motion, land at the **end** state (`controller.value = 1.0`) or
the rest state for loops — reduced motion removes the animation, not the
information.

### Reduced motion is not one behaviour — the design uses four

The right treatment is **per animation**; look up the CSS rule rather than
pattern-matching from one already done.

| Treatment | CSS | Meaning |
| --- | --- | --- |
| **A — reset to initial** | `animation: none` | sits at its *declared static* state |
| **B — land at end** | `animation: none; opacity: 1; transform: none` | forced to the finished state |
| **C — remove entirely** | `display: none` | element does not exist |
| **D — never animated** | wrapped in `@media (prefers-reduced-motion: no-preference)` | animation is only *added* when motion is allowed |

**The line to remember: `animation: none` means reset to the declared initial
state, which for a sheen means invisible — it does not mean land at the end.**
A sheen's parked transform sits off-screen; landing it at its end state leaves
a permanent white band across the card, the exact opposite of intended.

Entrance staggers are treatment **D**, so a rise-in should simply sit at its
natural position and opacity — `controller.value = 1.0`. Loop sheens are
treatment **A**, so stop *and reset to 0*. A celebration may use three at once:
`.cel-metalup` resets its ring (A), lands its `+N` delta badge (B), and removes
its particle coins entirely (C) — so the user still learns they levelled up,
with no motion at all.

`test/layout/reduced_motion_harness.dart` asserts all four at once. Point new
animated widgets at it. Verify the harness itself fails against a known
offender before trusting it.

## 17. A card's computed background may not be the one you see

`.dg-missions-entry` and `.dg-transfer-banner` both compute to
`rgb(240,240,240)` — a flat grey that appears nowhere in the design. That is a
base layer. The visible background is painted by an absolutely-positioned
child:

```css
.dg-missions-entry .me-bg { position:absolute; inset:0; z-index:0;
  background: linear-gradient(135deg, var(--ae-purple-600), var(--ae-purple-500)); }
.dg-missions-entry > *    { z-index: 1; }
```

**Resolve a visual background by walking the stacking context, not by reading
the element.** Reading the computed style of the card itself would have ported
two of home's cards as flat grey.

Related: those gradients are built from `--ae-purple-600`, which the **club
theme overrides per club**. The same card is navy for one club and purple for
another, and both are correct. Route it through the theme token; never
hardcode either colour, and do not "fix" a colour that differs from a
screenshot taken with a different club selected.

### The converse: a raw hex is a deliberate opt-out of theming

`SeasonCarryoverCard` declares both in the same block:

```jsx
border: "1px solid var(--ae-purple-100, #e7defb)",
background: "linear-gradient(150deg, #fbf9ff, #f3eefe)",
```

The author tokenised what they wanted themed and wrote literals for what they
did not. A club override therefore moves that border and leaves the gradient
alone — and deriving those two stops from `primaryTint`/`primarySoft` makes
the card diverge from the design on every non-default club.

**Match a raw hex literally; consume a `var(--token)` through the theme.** The
distinction lives only in the source: both render the same pixel on the
default club, so no screenshot or computed style can tell them apart.

## 18. Not every card is `--ae-shadow-card`

The three-layer card shadow is a default, not a rule. Measured on home:

- **season carryover** — a *single* `0 2px 6px rgba(45,27,91,0.05)` plus a
  1.25px border. Deliberately soft; "fixing" it to three layers is wrong.
- **`.lb-entry`** — three layers, **two of them inset**, including a
  *negative-offset* bottom inset (`0 -10px 18px … inset`), and a ramp midpoint
  at **55%**, not the metal family's 48%.
- seven of home's nine feed children carry at least one inset layer.

Hairline widths are not uniform either: **1.25px** on the carryover and
heart-ref cards, **1.5px** on the profile points card and inputs. Check each
against its own rule rather than assuming a house value.

### Check each override individually — a partial one looks intentional

`.scl-hero` overrides three things. `_ScorerTierBadge` carried its `large`
flag and grew correctly; `_ScorerStoBadge`, the badge sitting directly beside
it, had no flag at all and rendered the row's size in the hero.

That survived because **one of the two badges did grow**. Nothing read as
unfinished — the hero looked like a deliberate composition. A partially
implemented state override is more durable than a missing one, because it
removes the visual cue that anything is absent.

So check each override against its own selector, one at a time. "The hero
looks right" is not evidence; it is what a half-applied override produces.

### A base rule is not the whole story — find the state overrides first

`.lb-ladder .step` declares `background: #fff` and a single
`0 1px 3px rgba(45,27,91,.05)`. Against that base rule the app's grey locked
step and its lone shadow layer both look like defects.

They are not. Thirty-seven lines further down:

```css
.lb-ladder .step.locked { background: var(--ae-gray-50,#f7f6f9); }
.lb-ladder .step.metal-gull.done, .lb-ladder .step.metal-gull.on { background: linear-gradient(135deg,#ffe9a8 0%,#f6cf6b 48%,#e7b542 100%); }
```

The base rule styles a state the widget may never render. **Before filing a
delta on a state, grep for that state's own selector** — `.locked`, `.on`,
`.done`, `.frozen`, `.empty`. The same read found the real defect on that
widget: the metal ramp had been reduced from three stops to two, with the 48%
midpoint colour absent from the file entirely.

## 19. Measure layout from the DOM, but read hairlines from the source

Measuring the rendered design DOM is the right way to get heights, padding and
radii — far better than estimating off a screenshot. But `getComputedStyle`
returns the **used** value, and browsers snap border widths to the device-pixel
grid. An authored `1.5px` border can read back as `1.25px` depending on the
display.

So: **anything under 2px, trust the CSS source, not the computed style.** The
same applies to any sub-pixel authored length. Heights, padding and radius
survive the round trip; hairlines do not.

Corollary: when a value comes from inline JSX rather than a stylesheet
(`DGPointsCard` styles its card inline in `club-select.jsx`, not via a class),
there is no CSS rule to read — find the literal in the component body. Grepping
the stylesheet and finding nothing does not mean the element is unstyled.

## 20. One widget, N design treatments — assume nothing is shared

When a single Flutter widget serves several design treatments, **assume every
visual property varies per treatment until proven shared. A uniform value
across variants is a smell, not a simplification.**

Three confirmed occurrences on this project:

1. **`points_metal_theme.dart`** served two metal families with one gradient
   function — the pale 150deg `.dg-points-card` ramp was being used where the
   saturated 135deg `M_BG` ramp belonged.
2. **`AeMetalHeroTokens`** held one inset alpha per tone where the design has
   two — home and hero differ per tone, non-proportionally (+0.05 on bronse,
   +0.15 on gull), so no single multiplier could express it.
3. **`DugnadFeedEntryBanner`** gives all five variants the same
   `blur 28, offset 14, spread -14` shadow at alpha `.32–.42`, where the design
   specifies five different shadows at `.6–.82` — two with no inset layer at
   all, one with two insets including a negative-offset bottom tint.

The tell in each case: a value that looks like a house default. Check it
against *each* treatment's own rule rather than assuming the author
generalised correctly.

### Audit per declaration, not per widget

A correct value beside a wrong one is the **normal case**, not the exception.
Three from one screen:

- `.lb-trow`'s colour tokens were byte-correct while its border width, both
  shadows and its radius were not.
- `.scl-hero`'s drop shadow was byte-exact while its radius, its gradient
  axis, **both** gradient stops and its entire inset layer were wrong.
- `.scl-row.me` had blur, spread and tint right and reused the base row's
  1px offset under a 24px blur.

The pattern is a port written by reading the CSS for the one property the
author came for and skimming the rest of the declaration. It produces widgets
that pass a spot-check on whichever value you happen to look at, which is
exactly why a general review keeps missing what a per-property sweep finds.

### A shared constant is verified once or not at all

`_kPurplePoints` held `#5a3d96` where `--ae-purple-700` is `#6b4fa8`, and it
backed **both** `.lb-trow .pts b` and `.scl-stat b`. Because both sites were
wrong *identically*, nothing looked inconsistent — the two families' numerals
matched each other perfectly and diverged only from the design.

That is the failure mode: **internal consistency is what hides a shared wrong
value.** Comparing call sites against each other can never find it; only a
comparison against the token or the source can.

`_kSuccessGreen` was the same shape without the error — the same literal
declared separately in three files, each free to drift. Alias the token
instead:

```dart
const _kSuccessGreen = ScSaasThemeTokens.success;   // not Color(0xFF22A769)
```

If a token exists, consume it. If one does not and the value is used more than
once, add the token — `--ae-gray-400` was missing and got inlined twice before
anyone noticed it was a token at all.

And read the hex character by character. `.scl-hero`'s stops were `#ffe8a3`
against `#ffe9a8`, and `#f7d774` against `#f3c95f` — **near-misses, not
typos**. Close enough to look right in isolation, wrong enough to shift the
colour. Nothing but a character-by-character comparison catches those.

The counter-example is worth noting too — `referralPurple` consumes the
`shinyGradient` **token** rather than rebuilding stops from `theme.primary`,
so it follows a club override wholesale instead of drifting. Where a design
value comes from a token, consume the token.

## 20b. N widgets, one design treatment — the inverse, and it hides better

Rule 20 is one widget flattening several design treatments. The mirror case is
several widgets rendering **one** design treatment, and it has appeared here
too: home's campaign carousel uses `DugnadCampMiniCard` while the Kampanjer
list uses `MkCampaignCard`, for cards the CSS treats as one family.

| | Rule 20 | Rule 20b |
| --- | --- | --- |
| Shape | one widget, N treatments | N widgets, one treatment |
| Tell | a value that looks like a house default | two values that differ with nothing in the CSS to justify it |
| Assume | nothing is **shared** until proven | nothing is **unshared** until proven |

**20b hides better.** With one widget a wrong value is wrong everywhere, so it
shows up in any comparison. With two widgets each value can be independently
plausible and only the *pair* is wrong — neither card looks broken, they just
disagree. That is the `_kSuccessGreen` invisibility one level up: consistency
within each site is what conceals the divergence between them.

So check every value **three ways**: against the CSS, and the two widgets
against each other. A difference the CSS does not justify is a finding even
when both values look reasonable on their own.

## 22. A rendered height is box + wrapped copy — measure them apart

*(There is no rule 21. The weight-900 verdict it would have held was folded
into rule 14 instead, because a rule that gets re-derived is a rule that is
not being read at the right moment.)*

A height measured from the design DOM is the box **plus** however many lines
the copy happened to wrap to. Comparing it to an app height compares two
things at once, and the copy term is the larger one.

Worse, the copy term is not reproducible: **`flutter test` cannot load Plus
Jakarta Sans**, so text is laid out in a fallback face with different metrics
and wraps at different points. Any height delta measured in a widget test
therefore contains an artifact you cannot remove by being careful.

So measure twice:

1. **The box** — with copy too short to wrap, or, when the copy comes from
   l10n and cannot be shortened in place, by widening the column past every
   wrap point. What is left is padding plus the tallest child.
2. **The copy** — separately, and only as a question about *line count*, not
   about pixels.

A height that is identical at both widths has no copy term at all, and any
delta in it is structural.

**Widen the viewport, not just the box.** `SizedBox(width: 900)` inside a
375pt viewport is clamped straight back to 375 — `SizedBox` builds a tight
constraint and then `enforce()`s it against the incoming one, so the widening
silently does nothing. Both passes then measure the same width, every row
reports as having no copy term, and a pure wrapping difference gets filed as
a structural defect. Set `tester.view.physicalSize` for the wide pass.

This is the same class of fault as the stretched card below: the harness
quietly declined to do what it was told, and the assertions passed anyway.
**Before trusting any measurement, prove the harness actually changed what
you asked it to change** — a one-off probe that prints the granted width
costs a minute and is the only thing that catches it.

This turned "all five feed banners are 2.6–8.4pp too tall" into "no
base-value or scale defects exist". The proof was that the transfer banner's
box is *exactly* the missions card's 72.0 — both are `padding: 15px` twice
plus a 42px icon — so the design's 112.2 was a two-line subtitle all along.
Without the split it would have produced five phantom findings.

Two corollaries:

**A measured height is not a constant.** `_EntryStyle` carried a
`designHeight` per variant, used to turn a CSS inset's px extent into a
gradient stop — and it was wrong by 40pt on the transfer banner for exactly
this reason. A CSS `0 1px 1px inset` is 1px whatever the box turns out to be.
Derive it from the laid-out height (`LayoutBuilder`), never from a number
someone measured once.

**The animation counterpart: geometry gets copied, the curve gets
improvised.** `DugnadSheenOverlay` had `Matrix4.skewX(-0.28)` against a CSS
`skewX(-16deg)` — `tan(16°) = 0.2867`, so its author read the keyframe closely
enough to get the transform right — and then modelled the motion as a linear
tween across the whole period. The keyframe's real shape was a sweep over the
first 24% and a parked, invisible 76%.

**The timing function is the part that does not survive porting.** A CSS
keyframe's percentages are the animation; a `Tween` from first frame to last
frame throws them away and leaves a constant crawl that no duration value can
correct. Port the percentages as `Interval`s, and treat any dwell as
load-bearing rather than as dead time to be smoothed out.

**Check the harness before believing a height.** Under a `Scaffold`, a card
with no height constraint stretches to the full 812 frame. Every `1/H` stop
then computes against 812 and lands on its clamp floor, so the assertions
pass while testing nothing. Give the subject unbounded height
(`SingleChildScrollView`) so it must size to its content, and measure the
layer you actually care about — a bordered card paints its inset *inside* the
border, so the card and the inset differ by the border width.

## 23. A guard encodes an assumption about how the code is written

The tracking manifest failed on its first run against two values that were
**correctly** implemented: `.scl-sto` and the banner title are table-driven
(`context.dp(style.titleSize) * style.titleTracking`), so their literals never
appear in one expression.

Table-driven conversion is the *better* shape. Rule 3 concluded that
per-call-site conversion is exactly what produced the seven 10×-under bugs;
converting once in a table is the fix. A manifest that only recognised
literals would have created pressure back toward the broken pattern.

**Treat a guard failing on well-written code as a defect in the guard, never
in the code.** A source-level guard is a regex over a style of writing, and
the style is supposed to improve.

### Audit of the guards in this repo

| Guard | Verdict |
| --- | --- |
| shared-constant | **Clean.** A constant that aliases a token (`= ScSaasThemeTokens.success`) does not match its `Color(0x…)` pattern, so the better shape passes silently — which is what should happen. |
| banner-scaling | **Biased.** Its skip-list is a hardcoded set of `_EntryStyle` field names. Adding a new, well-named table field makes it fire on a correct value. Its earlier `SizedBox(` pattern missing `Container(width:)` was the same bias in another form. |
| scale-once | **Blind, not biased.** No false positives, but it only inspects `style:` expressions, so a double-scale that happens inside a helper is invisible to it. |
| letter-spacing | **Blind, not biased.** Same shape: it cannot see a value assembled from variables, and could not see an absent one at all — which is why the manifest exists. |

Two distinct faults fall out of that table, and they want different fixes.
A **biased** guard punishes good code and must be fixed. A **blind** guard
just fails to catch things, and wants a second guard beside it asking the
opposite question — which is exactly what the manifest is to the
letter-spacing rules.

### Third form — a proxy answers only about the property it is keyed on

A guard is not the only measurement that encodes an assumption; every *census*
does too. The dugnad radii census was keyed on `circular()`, so it could only
report on files containing a bare radius — seven files with bare
`width`/`height`/`padding` and **no** bare radius stayed invisible to it across
the whole effort. And "is this file scaled?" was answered by a boolean — *does
the file contain any `context.dp`* — which read a single scaled line (the one
`sheetTopRadius` call) as a scaled file, twice.

The scaling **ratio** (`context.dp` against all design-value literals, per
file) found what both missed: the seven absent files *and* the one-line-scaled
false positives. The boolean and the radii census each got a different half
wrong; the ratio got both right.

So the rule generalises past guards to all measurement: **a proxy keyed on one
property answers only about that property. Compute a ratio, not a boolean, and
before trusting any count, ask what it structurally cannot see.**

---

## Known outstanding

**The dugnad tree is complete** — five clusters, ~40 screens, all verified then
scaled to a **95%** ratio (the remainder are context-free helpers, size-relative
widgets, and line-height ratios that must not scale). Guards hold at 225 tests.
The full receipt — clusters, defect classes, which classes have a guard and
which have none — is in [`dugnad-parity-status.md`](dugnad-parity-status.md);
open product decisions are in [`dugnad-open-questions.md`](dugnad-open-questions.md).

The order that got it there, kept as the rule: **per screen, verify values
against the design first, then scale. Never scale first.**

What remains is not code: an on-device pass at 375/393/430, ~15 product
questions for Didrik, and the untouched commercial tree (`ui_kits/customer` —
feed, delivery, campaign, ride; ~174 files) to which this rulebook and the
guards transfer directly.

## Checklist for a new screen

- [ ] Frame values read from CSS, not from a screenshot measurement
- [ ] Every value through `dp()` exactly once (guard test passes)
- [ ] `letterSpacing` derived from the scaled font size everywhere
- [ ] Multi-layer shadows kept whole, including the hairline ring and negative spreads
- [ ] Inset layers faked with an edge gradient, not dropped
- [ ] `line-height` inherited from `.ae-screen` where the rule declares none
- [ ] Fill/scroll via `ConstrainedBox(minHeight:)`, auto-margins via `spaceBetween`
- [ ] Ratio assertions at four device widths, exactness at 375
- [ ] Screenshots taken at default OS text size
- [ ] `tabular-nums` mapped to `FontFeature.tabularFigures()`
- [ ] Font weights checked against what the design's `@import` actually loads
- [ ] Radial overlays on gradient surfaces kept, with off-canvas centres
- [ ] Every animated widget passes `expectRespectsReducedMotion`
