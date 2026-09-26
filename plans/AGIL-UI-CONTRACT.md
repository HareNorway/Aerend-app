# AGIL UI contract — `agil-1` (Utforsk · Butikk · Kasse · Sporing) and the Meg / Poeng / Betaling branch

**Binding on both branches from 2026-09-26.** Extends `AGIL-CONTRACT.md` (still
in force: §0 rules, §2.4 shared files, §4 enforcement, §6 merge day). Where this
file and that one disagree, this file wins for the two branches it names.

The second branch is called **`agil-ui-meg`** below until its real name is
confirmed; replace the name in one commit, nothing else changes.

---

## 0. Why this exists

After the agil-3 merge, one tree is being brought up to the prototype screen by
screen, on two branches at once:

| Branch | Screens (the prototype's `st.skjerm` values) |
|---|---|
| `agil-1` | `utforsk` (Feed, Fjordfiske landing, Forundringspose), `feed` (Nytt fra butikkene), `sok`, `kategori`, `butikk`, `automat`, `kurv`, `sporing`, `levert`, the Hjelp sheet |
| `agil-ui-meg` | `meg`, `favoritter`, `konto`, `bestillinger` (list), `premier`, `velger`, `liga`, `opprykk`, `fiske`, `agent`, and the **payment** surfaces: the Betaling sheet in the checkout, saved cards, Vipps return, `kjopSteg2–4` |

The prototype is one 1.85 MB file; both branches read it, neither edits it.

---

## 1. Ownership — files

Everything in `AGIL-CONTRACT.md` §2.2 still holds. The rows that moved or were
added:

| Path | Owner | Note |
|---|---|---|
| `lib/screens/bergen/utforsk/**` | `agil-1` | `utforsk_screen.dart`, `feed_tab.dart`, `feed_post_card.dart`, `feed_icons.dart`, `feed_nyheter_screen.dart`, `utforsk_copy.dart` |
| `lib/screens/feed/**`, `lib/networking/feed/**`, `lib/data/feed/**` | `agil-1` | the feed service client. `agil-ui-meg` may **call** `FeedRepo`; it never edits it. |
| `lib/screens/bergen/butikk/**`, `kasse/**`, `sporing/**`, `sok/**`, `hjelp/**` | `agil-1` | |
| `lib/screens/bergen/kasse/betaling_*.dart` | `agil-ui-meg` | **new files only**. The Betaling sheet body and the card / Vipps flows. `kurv_screen.dart` (agil-1) opens them through the seam in §3. |
| `lib/screens/bergen/meg/**`, `poeng/**`, `aegil/**` | `agil-ui-meg` | inherited from agil-3 |
| `lib/screens/points/**`, `lib/screens/aegil/**`, `lib/data/points/**`, `lib/data/aegil/**` | `agil-ui-meg` | inherited from agil-3 |
| `lib/screens/bergen/kit/**`, `lib/theme/bergen_tokens.dart` | `agil-1` | The kit. `agil-ui-meg` asks for a kit change by adding a `TODO(kit): …` in its own file and a line in §5; agil-1 lands the change. Never a local copy of a kit widget. |
| `lib/screens/common/home/bergen/**` | `agil-1` | Hjem and the bottom nav |
| `lib/l10n/intl_no.arb`, `lib/l10n/intl_en.arb` | **shared, append-only** | see §2 |
| `assets/**` | shared, **add-only** | new files only; never rename or replace an existing asset; register a new *folder* in `pubspec.yaml` with a `chore(shared):` commit |
| `pubspec.yaml` | shared, append-only | `chore(shared): add <package>` — one package per commit, and `pubspec.lock` stays uncommitted on both branches |
| `lib/main.dart`, `home_main_v1.dart`, `lib/redux/*`, `api_constant.dart` | shared, append-only | `AGIL-CONTRACT.md` §2.4 |
| `plans/AGIL-UI-CONTRACT.md` (this file) | shared, append-only | |

## 2. Copy — the ARB is the only place text lives

Both branches write user-visible text **only** in `lib/l10n/intl_no.arb` and
`lib/l10n/intl_en.arb`, and read it through a copy facade in the screen's own
folder (`UtforskCopy`, `A3MegCopy`, …). No string literal in a widget.

| Prefix | Owner |
|---|---|
| `ops_utforsk_*`, `ops_feed_*`, `ops_sok_*`, `ops_butikk_*`, `ops_kasse_*`, `ops_sporing_*`, `ops_hjelp_*` | `agil-1` |
| `meg_*`, `pts_*`, `aegil_*`, `ops_betaling_*` | `agil-ui-meg` (`ops_betaling_*` is reserved for it despite the prefix) |

Rules that make the ARB merge clean:

1. **Append at the end of the file, never insert.** Both files end with the
   newest keys; git merges appends without conflict.
2. **Never edit or delete another prefix's key.** A wrong translation in the
   other branch's key is a note in §5, not an edit.
3. Every key exists in **both** files in the same commit. `flutter gen-l10n`
   fails on a missing translation, so a half-added key breaks the other
   branch's build after merge.
4. Placeholders are typed in `intl_en.arb` (`"@key": {"placeholders": …}`);
   `intl_no.arb` carries no metadata (the template is EN).
5. Plurals use ICU (`{n, plural, =0{…} =1{…} other{…}}`), never string
   concatenation.
6. Regenerate with `flutter gen-l10n` and commit `lib/l10n/app_localizations*.dart`
   together with the ARB change.

## 3. Seams — how the two branches reach each other

The route table is the seam, as before: `bergen_routes_agil1.dart` (agil-1) and
`bergen_routes_agil3.dart` (now `agil-ui-meg`'s). Push by name through
`BergenRoutes.push`; an unregistered name is a «Kommer snart» toast, never a
crash.

Names each branch may rely on the other registering:

| Route | Registered by | Used by |
|---|---|---|
| `/bergen/utforsk` (`?tab=feed\|fiske\|pose`) | agil-1 | Meg's "Nytt fra butikkene" row → `?tab=feed` |
| `/bergen/butikk/{id}`, `/bergen/kurv`, `/bergen/sporing/{id}`, `/bergen/kundeservice` | agil-1 | Meg's order rows, Ægil's suggestion cards |
| `/bergen/automat` | agil-1 | |
| `/bergen/fjordfiske`, `/bergen/poeng`, `/bergen/premier`, `/bergen/aegil`, `/bergen/meg` | `agil-ui-meg` | Utforsk's Fjordfiske landing, Hjem's Points card, Søk's «Spør Ægil» |
| `/bergen/betaling` | `agil-ui-meg` | **new**: the payment-method picker as a full screen. Kurv pushes it with `{'order_id': …}` and reads the chosen method from the route's result (`Map<String,String>` with `method` and `label`). Until it lands, Kurv's own Betaling sheet stays. |

Seam files (stubs by agil-1, bodies by `agil-ui-meg`) from `AGIL-CONTRACT.md`
§2.2 remain: `meg_host.dart`, `poeng_entry.dart`, `napp_entry.dart`,
`aegil_entry.dart`, `brett_entry.dart`, `borte_entry.dart`. One new one:

| File | Exports | Purpose |
|---|---|---|
| `lib/screens/bergen/kasse/betaling_entry.dart` | `Future<BetalingChoice?> showBetalingSheet(BuildContext, {required int orderId})`, `class BetalingChoice {final String method; final String label;}` | Kurv calls it; the stub (agil-1) returns the current sheet's answer; `agil-ui-meg` replaces the body. Neither branch renames the function. |

## 4. Rules for a merge-proof change

1. **A branch only edits files it owns** (§1) plus append-only shared files.
   Before committing, `git diff --stat` must show nothing outside those.
2. **The bottom nav, the shell, and the four tab hosts** (`home_main_v1.dart`)
   are agil-1's. `agil-ui-meg` reaches its screens through `MegScreen`
   (`meg_host.dart`) and named routes.
3. **Tests live next to the screen**: `test/bergen/<screen>_test.dart` for
   agil-1, `test/meg/`, `test/points/`, `test/aegil/`, `test/a3/` for
   `agil-ui-meg`. Shared fakes in `test/a3/a3_fakes.dart` and
   `test/layout/reduced_motion_harness.dart` are append-only.
4. **Test kill-switches** stay: `OpsCustomerApi.networkEnabled = false`,
   `FeedPostCard.loadImages = false`, `A3Services` fakes. A test never
   reaches the network.
5. **Widget keys** are prefixed: `a1_…` (agil-1), `a3_…` (`agil-ui-meg`).
6. **No `dart format` on the other branch's files** — that produced the only
   conflict in the last merge.
7. **Backend**: `AGIL-CONTRACT.md` §2.1 unchanged — `ops_` is agil-1's; payment
   and points tables are `agil-ui-meg`'s under their existing prefixes
   (`pts_`, `agtp_`, `pd_`). New Laravel routes go into the name registry
   (`tests/fixtures/contract/names.<branch>.json`) before the code.
8. **Feed service** (`Aerend-Feed`): agil-1 only. `agil-ui-meg` never edits it.

## 5. Open asks between the branches

Append a line; the owner ticks it when done.

- [ ] `agil-ui-meg` → agil-1: none yet.
- [ ] agil-1 → `agil-ui-meg`: Meg's rows "Nytt fra butikkene" and "Hjelp og
      kontakt" still open Konto; the targets `/bergen/utforsk?tab=feed` and
      `/bergen/kundeservice` exist (two-line change in the Meg screen).
- [ ] agil-1 → `agil-ui-meg`: the bottom nav's cart pill shows «1 vare»; the
      prototype shows «1 · 899 kr». agil-1 will change the pill (nav is
      agil-1's); `agil-ui-meg`'s checkout must keep `BergenCart.syncBadge`
      calls as they are.
- [x] **Fjordfiske is agil-1's (decided 2026-09-26).** `lib/screens/bergen/fiske/**`
      is owned by `agil-1` (screen, copy facade `FiskeCopy`, keys `ops_fiske_*`,
      tests in `test/bergen/fiske_test.dart`). The screen moved out of
      `poeng/fjordfiske_screen.dart`; the route name `/bergen/fjordfiske` and its
      registration in `bergen_routes_agil3.dart` stay where they are (only the
      import path changed). agil-1 also removed the moved screen's widget test
      block from `test/points/a3_points_screens_test.dart` (it tested the old
      screen by its old keys). `poeng_copy.dart`'s `a3_poeng_fiske_*` and the
      `pts_fiske_*` ARB keys are untouched. The game reads the daily cap from
      agil-1's `ops.customer.fiske` (AGIL-CONTRACT §3.2) and calls agil-3's
      `showNappKort` seam for the day's first catch.
- [ ] agil-1 → `agil-ui-meg`: `PointsAppApi.pick()`'s prize map carries no
      per-prize tint / art; the Premiefangst card tints by `tier_band` and picks
      art by `type` until the shelf payload names them.

## 6. Merge day

`AGIL-CONTRACT.md` §6 applies: `agil-ui-meg` merges **into** `agil-1`, ARB
files merge as appends, `flutter gen-l10n`, `flutter analyze` (0 errors),
`flutter test` green, `php artisan ops:contract-check --strict`. Nothing is
pushed to `main` by either branch.
