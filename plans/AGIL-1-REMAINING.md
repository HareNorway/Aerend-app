# Ærend — combined remaining work (agil-1 + agil-2)

Companion to `AGIL-1-PLAN.md` and `AGIL-2-PLAN.md`. Those record what was built.
This records what is not, what is built but unreachable, and what nobody has
checked. Rewritten **2026-09-23** after the branches were merged, and
updated **2026-09-25**: the customer pre-auth flow and the Bergen Hjem screen
have both landed (see §3 and §4).

> **Superseded for planning purposes on 2026-09-25.** Everything still open here
> has been folded into two executable plans in this folder: `AGIL-1-PLAN-v2.md`
> (branch `agil-1`) and `AGIL-3-PLAN.md` (branch `agil-3`), governed by
> `AGIL-CONTRACT.md`. This file stays as the record of state on that date.

> 🛑 **Branch policy.** `agil-2` is merged into `agil-1` in all five repos, for
> combined testing. `agil-1` is the integration branch. **Nothing goes into
> `main` or `master` in any repo, and nothing is pushed.** `agil-1-backup` holds
> the pre-merge commit in each repo, so the merge is reversible with
> `git reset --hard agil-1-backup`.

---

## Contents

1. [Status at a glance](#1-status-at-a-glance)
2. [Before you manually test](#2-before-you-manually-test)
3. [What you can and cannot reach today](#3-what-you-can-and-cannot-reach-today)
4. [Design fidelity — one flow done, the rest not assessed](#4-design-fidelity--one-flow-done-the-rest-not-assessed)
5. [What the merge found](#5-what-the-merge-found)
6. [Admin screens](#6-admin-screens)
7. [Other outstanding UI work](#7-other-outstanding-ui-work)
8. [Blocked on a decision or a credential](#8-blocked-on-a-decision-or-a-credential)
9. [Blocked on the eventual main merge](#9-blocked-on-the-eventual-main-merge)
10. [What this environment could not verify](#10-what-this-environment-could-not-verify)
11. [Suggested order](#11-suggested-order)

---

## 1. Status at a glance

| Repo | Merged | Combined tests |
|---|---|---|
| Hare-AdminPanel | 12 commits, no conflicts | **989 passing**, 11 skipped, 6 pre-existing failures |
| Hare-Store | 2 commits, no conflicts | **235 passing** |
| Aerend-app | 19 commits, 10 conflicts resolved; `agil-1-dashboard` merged clean 2026-09-25 | **321 passing**, `lib/` analyzes with 0 errors |
| Hare-Driver | nothing to merge — agil-2 owns nothing here | 129 passing |
| Aerend-Feed | nothing to merge — agil-2 never touched it, as contracted | 60 passing / 120 skipped (no Docker) |

The backend suite passes identically in both configurations: default pre-cutover
bindings, and with the merge-day adapters live
(`POINTS_ORDER_SOURCE=order_events POINTS_SIGNAL_SOURCE=webhook`).

The six backend failures are pre-existing main-branch unit tests —
`DonationFeeService`, `GamificationConfigService`, `MediaUrlResolver`,
`SeasonRolloverService`, `StoreMediaResolver` (×2). Neither branch touches those
files; all six already fail on `agil-1-backup`. Not merge damage, and not in
either plan.

**The headline.** Both branches built their screens and tested them as widgets.
The test counts are high and honest. But most of that work is **not connected to
the running apps** (§3), and **nobody has compared any of it to the designs**
(§4). Those two things, not the test results, are what stands between here and a
manual test pass.

**The one exception, and the shape to copy.** The customer app’s pre-auth flow
(splash, onboarding, login, OTP, consent) landed on 2026-09-24 in `590cfc4`. It
is the first work in this project that is **both reachable and built to the
design** — the splash samples the design’s own CSS keyframes, and the onboarding
follows the design’s step order. That is the bar the rest of §3 and §4 is
measured against from here.

---

## 2. Before you manually test

Run in order. Steps 1–3 are required. Skip step 4 and the app looks broken when
it is only switched off.

**1. Migrate the dev database.** It has agil-1's tables but **not agil-2's** —
24 pending migrations. The test DB is already done.

```
cd D:/work/hare/Hare-AdminPanel
php artisan migrate
```

**2. Seed — five of them, four are agil-2's.** All idempotent. There is no
`DatabaseSeeder.php`, so a bare `db:seed` does nothing; each needs `--class`.

```
php artisan ops:seed-policies                      # agil-1 rate card
php artisan db:seed --class=PointsPolicySeeder     # 16 points.* keys
php artisan db:seed --class=AgentRegisterSeeder    # 15 agents, all DISABLED
php artisan db:seed --class=MissionTemplateSeeder  # 4 templates
php artisan db:seed --class=PrizeCatalogueSeeder   # 5 active + 10 inactive
```

`PointsPolicySeeder` wrote **nothing at all** before the fix in this merge (§5);
if you ran it earlier and saw no rows, that is why.

**3. Seed the flags, then turn some on.** Every agil-1 surface flag ships off by
design, so a fresh pass otherwise shows you the pre-agil-1 app.

```
php artisan ops:flags seed          # 30 surface flags, all off
php artisan ops:flags list
php artisan ops:flags stage backbone      --reason="manual test"
php artisan ops:flags stage partner_floor --reason="manual test"
php artisan ops:flags stage courier       --reason="manual test"
php artisan ops:flags stage money         --reason="manual test"
php artisan ops:flags stage storefront    --reason="manual test"
```

**4. agil-2's flags are a separate, env-only mechanism.** `ops:flags` does not
touch them — see the `feature_flags` mismatch in §5. In `.env`:

```
FLAG_POINTS=true
FLAG_PREMIEHYLLA=true
FLAG_MISSIONS=true
FLAG_LEAGUE=true
FLAG_AEGIL_LEVEL_MAX=3     # a number, not a boolean
```

**5. Choose an adapter configuration.** Unset is the legacy/fixture path; these
two vars are the entire merge-day cutover:

```
POINTS_ORDER_SOURCE=order_events
POINTS_SIGNAL_SOURCE=webhook
```

**6. Services, for the live paths rather than the screens alone.**

- `.env` has `BROADCAST_DRIVER=log` and `QUEUE_CONNECTION=sync`. Realtime
  channels need Soketi: `docker compose -f docker-compose.soketi.yml up -d`,
  then `BROADCAST_DRIVER=pusher`, `PUSHER_APP_ID=aerend`,
  `PUSHER_APP_KEY=aerend-key`. On `log` the apps fall back to polling
  `GET /api/ops/events?since=`, which works but is not what you are testing.
- Escalation, auto-pause and feed delivery are **scheduler-driven**. Without
  `php artisan schedule:work`, an unseen order never escalates and no feed event
  is delivered.
- The feed service needs Docker (Postgres + Valkey), which is not running here.

**7. Nothing to reinstall.** The merge changed no `composer.json` and no
`pubspec.yaml`.

**If something looks wrong,** check in this order — flag off (§2.3, §2.4) → seed
missing (§2.2) → migration not run (§2.1) → screen not mounted (§3) → scheduler
not running (§2.6) → actually a bug. All 15 agents seed **disabled**, so Ægil
doing nothing is the designed state.

---

## 3. What you can and cannot reach today

The most operationally important section. Verified by searching for any file
that constructs each entry point other than its own definition.

### Customer app (Aerend-app) — navigation works

`main.dart` → `Splash` → `HomeMainV1`, now a **four-tab** bottom nav:
**Hjem, Utforsk, Kurv, Meg** (`BergenBottomNav`). Søk and the Ægil chat moved out
of the nav into the home screen's search flow and are still reachable from there
(`home_main_v1.dart:116` and `:120`). `lib/` analyzes with zero errors.

| Path | Reachable |
|---|---|
| **Splash → onboarding (Landing → Vilkår → Konto → Telefon → Kode → Ferdig) → login → OTP → consent** | **Yes — complete, 2026-09-24** |
| **Hjem — the Bergen home screen (`BergenHome`)** | **Yes — complete, 2026-09-25** |
| All four bottom-nav tabs | **Yes** |
| Feed tab → stories row, post cards | **Yes** |
| "Follows but no posts" empty state (`FeedEmptyNoPosts`) | **Yes** — the one new widget with a real parent |
| Feed search (embedded) | **Yes** |
| Push → post detail deep-link (`feedNewPost` → `PostDetailScreen`) | **Yes** |
| Story viewer, post-detail "no longer available" | **Yes** |
| Live order screen (`deliveries_order_detail`) | **Yes** — pre-existing |
| `FeedPublisherTabs` — the *Nærheten / Følger / Fra Ærend* tabs | **No** — `FeedHome` never constructs it |
| `VaagenCard` | **No** |
| `DeliveryCodeCard`, `OpsTrackingStatus` | **No** — `lib/screens/tracking/` holds only these two files and nothing imports either |
| `MegPointsCard`, `PremiehyllaShelf`, `WelcomeMoment`, `SuggestionTray` (agil-2) | **No** — Profil → `Account` does not include them |

**These are light widgets, not a missing layer.** `FeedPublisherTabs(active,
onSelected)`, `VaagenCard(available, onReel, pending)`, `OpsTrackingStatus(state,
promisedStart, promisedEnd, adjustedByMinutes)`, `DeliveryCodeCard(pin,
reasonCopy, qrPayload)`. `FeedHomeState` already carries the tab state and
`hasFollows`; `ops_feed_api.dart` already has the Vågen call; the order-detail
screen already has the order. Mounting them is placement plus a few prop
wirings.

### Partner app (Hare-Store) — feed yes, ops no

| Path | Reachable |
|---|---|
| Store publishes a feed post — `home_screen.dart:116` → `StoreFeedProfileScreen` → `FeedCreateOptionsSheet` → `FeedComposerScreen` | **Yes** |
| `OpsShellScreen` — the five-tab host for all 23 ops screens | **No** |
| `TilbyPremieScreen` (agil-2) | **No** |

This repo also has **two screen trees**: `lib/screen/` (singular, 125 files) is
the shipping app; `lib/screens/` (plural, 44 files) is where both branches built.
Imports work across them, so this is confusing rather than blocking.

### Courier app (Hare-Driver) — no

`LiveStageScreen` is referenced in exactly one file, its own. Its screens are in
the right tree, just unlinked.

### Why Partner and Bud are harder than the customer app

`OpsShellScreen` takes `required List<OpsOrder> orders` plus `onPrimaryAction`,
`onReject`, `onAddTime`, `onMarkReady`, `onSeen` and its banner state.
`LiveStageScreen` takes `required assignmentState`, `orderCode`, `address` and a
dozen more. They are pure functions of their props — which is why they test so
cleanly and why they cannot simply be pushed onto a navigator. Missing:

1. **A fetch that does not exist.** `lib/networking/ops/ops_api.dart` has
   `heartbeat`, `devices`, `markSeen`, `transition`, `eventsSince` — nothing that
   returns a store's current orders. `GET /api/ops/panel/now` is admin-scoped.
   Either the app builds state from `eventsSince`, or the backend gains a store
   snapshot endpoint. **That is a backend decision, not Flutter work.**
2. **A container per shell**, mapping state into props and callbacks onto
   `transition()`.
3. **Then** the navigation entry — both apps have a `DrawerEnum` drawer, so that
   last part is a few lines.

I attempted the navigation entry alone and it failed to compile, because
`const OpsShellScreen()` has no valid zero-argument form. That failure is the
evidence for this section.

### Why the tests did not catch any of this

A widget test pumps the widget with hand-built props. A screen with no data
source and no route passes exactly as well as one wired end to end. 666 green
Flutter tests say every screen renders correctly from good data; not one says
where that data comes from, or that a human can open the screen.

---

## 4. Design fidelity — one flow done, the rest not assessed

### Done: the customer pre-auth flow and the Hjem screen

**One flow has been built to the design and is reachable** — splash, onboarding,
login, OTP and consent, delivered 2026-09-24 in `590cfc4`:

- The splash is a 1:1 port of `data-screen-label="Splash · klistremerke"` from
  `Ærend Kunde Bergen.dc.html` — 3D sticker slap, rings, dust, sheen, letter
  flips, horizon line — with **every value sampled from the design’s own CSS
  keyframes** on one 2.6s clock, positioned in the design’s 390×844 frame. The
  iOS launch screen is solid `#2F6270` so the native-to-Flutter handover does not
  flash.
- Onboarding runs in the design’s order: Landing → Vilkår → Konto → Telefon →
  Kode → Ferdig, on a shared kit (sea surface, step ladder, Ægil + bubble, CTA,
  fields, tabs), NO/EN copy in `OnbCopy`. Terms acceptance persists per device;
  a referral code from the landing or an `/invite?code=` link is sent as
  `refer_code` on register.
- It is **wired**: `onboarding_kit.dart` is used by `consent_gate_screen.dart`,
  `login.dart` and `otp_verify.dart`, and splash routes into them. Unlike §3’s
  orphans, a tester reaches this by opening the app.

**The Hjem screen followed on 2026-09-25** (`agil-1-dashboard`, merged clean).
Built 1:1 from the Bergen design: the sea hero and its day/evening/rain/fishing
variants, the category row, the explore cards and the four-tab bottom nav, with
ten scene SVGs under `assets/svgs/dashboard/`. Around 10,000 lines across a
`lib/screens/common/home/bergen/` package, wired as tab 0 of the shell — so it
is reachable as well as faithful, which is the combination §3 says almost
nothing else in this project has.

Those two flows no longer need a design review. **Everything below still does.**

### Not assessed: everything else

**No other screen in any of the three apps has been compared to any design.** No
test in any repo asserts visual fidelity, and nothing in either plan’s notes
records a review of them. So if the impression is that the remaining screens do
not match the designs, nothing here contradicts that.

What is true:

- The widgets were written *from* the designs — they cite them in their
  docstrings (`feed_publisher_tabs.dart`: "§3.1, `Kunde Bergen` design";
  `delivery_code_card.dart`: "Kunde design delivery-code card + ID-kort";
  `vaagen_card.dart`: "One pull a day, and that limit is the design").
- The sources are in `designs/21des/` (47 `.dc.html` files — the folder was
  `20des` until 2026-09-24, so any older citation of that path is stale), for the
  customer app
  principally `Ærend Kunde Bergen.dc.html`,
  `Ærend Kunde - inventar (steg 1).dc.html` and
  `Ærend Kunde - leveranser (steg 4).dc.html`.
- Some divergence is **deliberate and recorded**: the Bergen splash skips the
  mountain/harbour illustration, the animated chip cards and the boat graphics,
  noted at `splash.dart:13`.

What is not true: that any of it was checked. Widget tests assert structure and
behaviour — that a label exists, that a tap fires a callback, that an empty state
appears. None assert spacing, type scale, colour, elevation or motion, which is
most of what "consistent with the designs" means.

**So this is open work of unknown size**, and it cannot be sized without someone
opening the design files beside the running app. It interacts with §3: a widget
that is not mounted cannot be design-reviewed at all, so mounting comes first,
then review, then rework. Treat any estimate for §3 as excluding whatever rework
§4 produces.

---

## 5. What the merge found

Seven defects that no amount of testing on either branch alone could have caught.
All are fixed and covered by tests. They are listed because the pattern says
where the next one will be.

**Five of the seven were silent.** Both merge-day adapters degrade to empty when
their table is missing — correct behaviour for a branch waiting on the other, and
exactly why nothing complained when the names turned out wrong.

| # | Defect | Consequence had it shipped |
|---|---|---|
| 1 | `OrderEventsSource` read `order_events`; the table is `ops_order_events` | A cutover would have awarded **nobody any points for any delivery**, with nothing in any log to say why |
| 2 | `WebhookSignalSource` read `feed_webhook_events`, which neither branch creates; the real table is `ops_feed_inbox`, with a different shape | Ægil would never have reacted to a feed post |
| 3 | The `SignalSource` binding ignored `POINTS_SIGNAL_SOURCE` and always returned fixtures | The documented merge-day switch did nothing |
| 4 | `ops_order_events` stores the actor as `actor_type`/`actor_id`; agil-2 decoded one JSON `actor` field | Every event resolved to `system`/`null` — attribution lost on every record |
| 5 | A migration pinned a column with `->after('ean_number')` — a column production has and no migration creates | Worked on a developer machine, failed on any DB built from migrations |
| 6 | agil-2's `FeatureFlags` reads `feature_flags`; agil-1 created `ops_feature_flags` | Points/Ægil flags unreadable from the DB — still two separate rollout mechanisms today (§2.4) |
| 7 | `PointsPolicy`, `ConfigPolicyLookup` and `PointsPolicySeeder` read `policies`; agil-1 created `ops_policies` | The seeder wrote **nothing**; the points rate card came only from config, and admin policy changes had no effect on Points |

**The pattern.** Every one is two components agreeing on a *name* in prose and
disagreeing in code. The frozen event contract prevented exactly this for the
payloads — `MergeIntegrationTest` drives the real path from
`tests/fixtures/events/order.delivered.json` and passes, including both plans'
acceptance criterion *"real `order.delivered` via `order_events` earns Kjøp
points"*. Nothing played that role for table names, column shapes or env var
names. **If one thing goes into the contract before the next integration, it is
those.**

Number 6 is the one still open as a design question: agil-2 reads a `value`
column that can hold a number (`aegil_level_max`); agil-1's table has
`enabled`/`targeting` with no equivalent. Unifying the two rollout controls needs
a schema decision.

### Also surfaced, and fixed

- **agil-1's ops fixtures inserted `providers.name`.** Production has
  `first_name`/`last_name` and **no `name` column at all** — those tests passed
  against a schema that exists nowhere real. Now detected with
  `Schema::hasColumn`, the guard `FeedTokenTest` already used.
- **`MetricsTest::the_unseen_rate_pages_support` was date-dependent** — windowed
  on a hard-coded 22 September while the fixture stamped `created_at` from the
  wall clock. Passed the day it was written, failed the next.
- **The test database must be built from the live schema, not migrations.**
  `scripts/rebuild_test_db.sh` copies the live structure and migrates on top. Run
  it before `php artisan test`, or roughly a third of the suite fails on drift
  unrelated to the code under test. **The most important thing a new person needs
  to know about this repo.** Drifted columns include `users.credit`,
  `providers.first_name`, `users.deleted_at`, `service_category.is_sub_cat_flow`,
  `user_store_product_booking.tip` and `store_product_details.ean_number`.

---

## 6. Admin screens

**Both halves are built and in the sidebar, as of 2026-09-24.**

- **agil-1** — seven screens under `/admin/drift` (Nå, Unntak, Butikker + store
  detail, Bud, Feed, Policy, Finn ordre), in the commercial panel, using the
  `adm-*` design system. Navigation is `admin_module` rows
  (`2026_09_24_090000_ops_register_drift_admin_menu`), so they are grantable to
  restricted admins. `PanelReadModel` is shared with the JSON API the apps poll,
  so the screens and the apps cannot disagree. 22 tests render every screen
  through the real layout (`OpsAdminScreenTest`). Guides:
  `Hare-AdminPanel/docs/OPS_ADMIN_GUIDE.md`, `docs/T1_T2_SMOKE_TEST.md`.
- **agil-2** — `/admin/poeng-v2` and `/admin/agenter`, moved to the commercial
  layout, restyled onto `adm-*` (zero Bootstrap classes left), registered as
  "Poeng & Ægil" in the sidebar, English added.

Both need `php artisan migrate` on the dev DB before the sidebar entries appear.

Still open from this section: the `feature_flags` / `ops_feature_flags` split
(§5 #6) means `ops:flags` does not control the Points surfaces — two rollout
mechanisms until a schema decision is made. It is the first task of
`AGIL-1-PLAN-v2.md` Phase 0.

---

## 7. Other outstanding UI work

**Bergen reskin naming debt** (customer app). The reskin landed — Bergen palette,
`AerendBergenAuthTokens`, correct app icon on `#173E48`. Not finished:

- `lib/theme/reen_pre_club_theme.dart` still carries the old filename for a class
  no longer called that (`AerendBergenAuthTokens`). **24 files import it now**, up
  from ten — agil-2’s Points and Ægil widgets import it too, and the new pre-auth
  work keeps using it. The rename gets cheaper the sooner it happens.
- `assets/Logo/reen-mark-coral.png` and `assets/Logo/reen/mark-coral-navy.png`
  still carry Reen names and render on five live surfaces — `homeMainV1`,
  `feed_branded_header`, `home_v1`, `contact_us_screen`, `snurre_chat_screen`.
  Both were touched in the reskin commit, so the **pixels are probably already
  right and only the names are wrong** — one visual check settles it, because the
  alternative is a coral Reen mark on the feed header.

**Two surfaces a widget test cannot reach**, both built, both needing one manual
pass:

- **Composer image picker** (Hare-Store) — the 10 MB gate and the inline error
  with Retry are built and analyze-clean, but the picker crosses a platform
  channel. Check: oversized photo blocked before upload; airplane mode gives an
  inline error and Retry works; a normal photo publishes unchanged.
- **Story viewer with a broken `media_url`** (Aerend-app) — the view is tested
  directly because `CachedNetworkImage` needs `path_provider`, so driving the
  full screen sits on the placeholder and passes for the wrong reason.

**Analyze noise:** the customer app's `lib/` has 0 errors and 641 infos
(deprecations). The only 2 errors in that repo are in a stray `test_app/`
scaffold present identically on both branches — a `flutter create` leftover worth
deleting. Hare-Store has 11 pre-existing errors from inconsistent import casing
(`homeScreen` vs `homescreen`), also on both branches.

**Fixed on the way in (2026-09-24), worth knowing before you test.** The
social-login busy overlay could stay up forever and **block every tap in the
app** — a tester would have been stuck on the login screen with no way forward.
It is now tied to the login call and always released. Also fixed:
`primaryFocus!.unfocus()` threw when nothing had focus (20 call sites), login’s
connectivity check compared a `List` to an enum, and cancelling Sign in with
Apple threw.

**Pre-existing, nobody's plan:** `account_detail.dart` has ~8 hardcoded
Norwegian strings marked `// TODO(l10n)`.

---

## 8. Blocked on a decision or a credential

**Points migration cutover** (agil-2's last open task). Needs the Appendix B
conversion factor **and** production access. Job, dry run and reconciliation
report are built and tested; a live run refuses to start until
`POINTS_MIGRATION_FACTOR_CONFIRMED=true`. 24-hour monitoring follows it.

**Vipps payout (courier disbursements).** A different Vipps product (Utbetaling)
with its own merchant agreement. `payouts`/`payout_lines` and the 04:00 batch are
built against a pluggable transport, deliberately bound to
`UnavailablePayoutTransport` — a batch that silently no-ops is worse than one
that refuses. **Unblocks when** the agreement is signed and sandbox credentials
exist.

**Six policy values are placeholders, not decisions** (Appendix B): three
waiting-pay figures, trip compensation, and the two store commercial rates (14 %
commission, 1.55 % payment fee). Marked in `docs/OPS_POLICY_KEYS.md`. Each is one
`PolicyService::set()` call with a reason; every historical order keeps the
`policy_version` it was quoted under.

**Four ops tasks need prod access, a real device, or DO rights** — all
**PENDING — HUMAN**, none attempted:

- **T1** verify `GET /api/internal/feed-device-tokens` is live in prod. A 404
  means Laravel never deployed the route and needs a `workflow_dispatch` run.
  **T2 depends on this.**
- **T2** push-notification E2E on two real phones: store publishes → customer
  push within 30s → deep-link; customer comments → store push. **The most
  important unverified path in the product, and testable today** — the whole
  chain is wired (§3): store publish reachable, customer feed reachable, FCM
  configured in both apps, `feedNewPost` → `PostDetailScreen` implemented. Needs
  T1 first, two devices with Play Services, a test store and customer with the
  customer **following** the store, and release builds against production. Note
  that `notification-processors.test.ts` covers the *processor* logic with mocks —
  fan-out, token de-duplication, batching, retries. That is a different claim
  from the real chain on real hardware, which the handover says has never been
  run.
- **T9** delete the demo seed post in prod (id `1`, likely `store_details_id`
  45). **Confirm what that row actually is first** — real partner posts may sit
  alongside it.
- **T10** rotate `aerend-feed-pg` + `aerend-feed-redis` credentials and redeploy.
  ~30s downtime; run **after** T2.

**Two out-of-band items, not engineering:**

- **Partner content seeding** — 10–15 stores × 3–5 posts before launch. BD work.
  An empty feed on day one reads as a broken app rather than a new one, and the
  mix rule (5 store posts per Ærend post) has nothing to mix without it.
- **Native Norwegian review of the 23 machine-translated feed ARB keys.**

---

## 9. Blocked on the eventual main merge

Not blocked on agil-2 any more — that merge has happened.

- **Post-merge integration against live producers.** The adapters are proven
  against real rows in the integration suite, but "a real feed webhook from the
  deployed feed service creates a suggestion" needs both services running.
- **The `main` merge itself.** Verified, not executed: a dry-run merge
  auto-merges everything and conflicts in `.env` alone. **Resolve that hunk in
  `main`'s favour** — `agil-1` points `VIPPS_LOGIN_REDIRECT_URI` at `127.0.0.1`
  from local testing, `main` at production. (`main`'s value also has a typo:
  `https//ailogistics.no`, missing the colon.)
- **Three out-of-ownership exceptions:** the tracked `.env`; three pre-existing
  `Snurre` commits (`9ddee0f`, `4253c07`, `2b85dc0`) belonging to neither plan;
  and the shared-file appends (`main.dart`, `l10n.yaml`, generated `lib/l10n/*`,
  `routes/api.php`, `Kernel.php`, `config/broadcasting.php`,
  `AppServiceProvider.php`).
- **Flag rollout.** 30 agil-1 surface flags plus agil-2's five, all defaulting
  off. Order and rollback: `docs/OPS_ROLLBACK.md` §5 and `docs/AGIL2_ROLLOUT.md`.

---

## 10. What this environment could not verify

- **Docker Desktop is not running**, so 120 of Aerend-Feed's 180 tests skip —
  every Postgres- and Valkey-backed suite, including feed-tab ranking and
  moderation. They pass with the local stack up; they were not run here.
- **No staging environment**, so "store publishes → appears in the customer feed
  ≤ 5s" and the two-service integration pass remain unmeasured.
- **No real devices** — T2, plus the two platform-channel surfaces in §7.
- **No design review beyond the pre-auth flow** — §4.
- **The load test measures the monolith, not the wire.** p50 9 ms / p95 25 ms /
  max 35 ms against a 1 s budget, with the broadcast driver faked. Read it as
  "the monolith can produce 500 orders' worth of fan-out inside the budget", not
  "a phone sees it in a second".

---

## 11. Suggested order

Retained for the record; the live ordering is now the phase order of the two
plans named at the top of this file.

1. ~~Mount the customer app's widgets~~ → `AGIL-1-PLAN-v2.md` Phase 2.
2. ~~Design-review the rest of the customer app~~ → `AGIL-1-PLAN-v2.md`
   Phases 3–6, which build the remaining Bergen screens to the design rather
   than reviewing the old ones.
3. **T1 then T2** — unchanged, human-only, `docs/T1_T2_SMOKE_TEST.md`.
4. ~~Decide the Partner data source~~ → deferred; Partner and Bud app UI is out
   of scope for both new plans by decision (Aerend-app is the only Flutter UI
   target now). The backend endpoint they need is specified in `AGIL-3-PLAN.md`
   Phase 4 so a later Partner plan is pure UI.
5. ~~agil-1's seven admin screens~~ → done 2026-09-24 (§6).
6. ~~Add names to the cross-branch contract~~ → `AGIL-CONTRACT.md` §3 is that
   registry.
7. The two manual UI passes and the Reen naming cleanup → `AGIL-1-PLAN-v2.md`
   Phase 7.
8. Everything blocked on an agreement or a decision → listed per plan under
   "Blocked".
