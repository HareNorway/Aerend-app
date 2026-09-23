# Ærend — combined remaining work (agil-1 + agil-2)

Companion to `AGIL-1-PLAN.md` and `AGIL-2-PLAN.md`. The plans record what was
built; this records what is not, across both branches, now that they sit on one
tree. Last updated **2026-09-23**.

> 🛑 **Branch policy.** `agil-2` is merged into `agil-1` in all five repos for
> combined testing. `agil-1` is the integration branch. **Nothing goes into
> `main` or `master` in any repo, and nothing is pushed.** `agil-1-backup` holds
> the pre-merge commit in each repo, so the merge is reversible with
> `git reset --hard agil-1-backup`.

## Where things stand

| Repo | Merged | Combined tests |
|---|---|---|
| Hare-AdminPanel | 12 commits, no conflicts | **989 passing**, 11 skipped, 6 pre-existing failures |
| Hare-Store | 2 commits, no conflicts | **235 passing** (222 ops + 13 points) |
| Aerend-app | 19 commits, 10 conflicts resolved | **302 passing** (187 ops/feed + 115 points/Ægil) |
| Hare-Driver | nothing to merge — agil-2 owns nothing here | 129 passing |
| Aerend-Feed | nothing to merge — agil-2 never touched it, as contracted | 60 passing / 120 skipped (no Docker) |

The backend suite passes identically in **both** configurations: the default
pre-cutover bindings, and with the merge-day adapters live
(`POINTS_ORDER_SOURCE=order_events POINTS_SIGNAL_SOURCE=webhook`).

The six remaining backend failures are pre-existing main-branch unit tests —
`DonationFeeService`, `GamificationConfigService`, `MediaUrlResolver`,
`SeasonRolloverService`, `StoreMediaResolver` (×2). Neither branch touches those
files and all six already fail on `agil-1-backup`. They are somebody's to fix,
but they are not merge damage and not in either plan.

---

## 0. Before you manually test

Run in this order. Steps 1-3 are required; skip 4 and the app looks broken when
it is only switched off.

**1. Migrate the dev database.** It has agil-1's tables but **not agil-2's** -
24 pending migrations. The test DB is already done.

```
cd D:/work/hare/Hare-AdminPanel
php artisan migrate            # 24 pending, all additive
```

**2. Seed. Yes, five of them, and four are agil-2's.** All idempotent.

```
php artisan ops:seed-policies                              # agil-1 rate card (already 16 rows)
php artisan db:seed --class=PointsPolicySeeder             # 16 points.* keys
php artisan db:seed --class=AgentRegisterSeeder            # 15 agents, all DISABLED
php artisan db:seed --class=MissionTemplateSeeder          # 4 templates
php artisan db:seed --class=PrizeCatalogueSeeder           # 5 active + 10 inactive
```

There is no `DatabaseSeeder.php`, so `db:seed` with no `--class` will not work -
each one is named explicitly. `PointsPolicySeeder` seeded **nothing at all**
before the fix in this merge; if you ran it earlier and saw no rows, that is why.

**3. Seed the flags, then turn some on.** Everything ships off by design, which
means a fresh manual pass shows you the pre-agil-1 app and nothing else.

```
php artisan ops:flags seed     # 30 surface flags, all off
php artisan ops:flags list     # what is on
php artisan ops:flags stage backbone       --reason="manual test"
php artisan ops:flags stage partner_floor  --reason="manual test"
php artisan ops:flags stage courier        --reason="manual test"
php artisan ops:flags stage money          --reason="manual test"
php artisan ops:flags stage storefront     --reason="manual test"
```

**4. agil-2's flags are separate, and env-only.** `ops:flags` does **not** touch
them - see the `feature_flags` / `ops_feature_flags` mismatch in §1. Set these in
`.env` and they take effect immediately:

```
FLAG_POINTS=true
FLAG_PREMIEHYLLA=true
FLAG_MISSIONS=true
FLAG_LEAGUE=true
FLAG_AEGIL_LEVEL_MAX=3        # a number, not a boolean: how far Aegil may go
```

**5. Decide which adapter configuration you are testing.** The default is
pre-cutover; combined testing is the point of the merge, so you probably want the
merge-day pair:

```
POINTS_ORDER_SOURCE=order_events    # points from real ops_order_events rows
POINTS_SIGNAL_SOURCE=webhook        # Aegil signals from the real feed inbox
```

Leave them unset to test the legacy/fixture path instead. The suite passes both
ways; these two vars are the whole cutover.

**6. Services, if you want the live paths rather than the screens alone.**

- `.env` currently has `BROADCAST_DRIVER=log` and `QUEUE_CONNECTION=sync`. Live
  tracking and the courier/partner realtime channels need Soketi:
  `docker compose -f docker-compose.soketi.yml up -d`, then set
  `BROADCAST_DRIVER=pusher`, `PUSHER_APP_ID=aerend`, `PUSHER_APP_KEY=aerend-key`
  and the secret from that compose file. On `log` the apps fall back to polling
  `GET /api/ops/events?since=`, which works but is not what you are testing.
- Escalation, auto-pause and the feed outbox are driven by the scheduler, not by
  requests. Without `php artisan schedule:work` running, an unseen order never
  escalates and no feed event is delivered.
- The feed service needs Docker (Postgres + Valkey). **It is not running on this
  machine**, which is also why 120 of its tests skip.

**7. Nothing to reinstall.** The merge changed no `composer.json` and no
`pubspec.yaml`, so no `composer install` and no `flutter pub get` are needed.

### What you can click immediately

| Surface | Where |
|---|---|
| Points admin | `/admin/poeng-v2` |
| Agents admin (register, kill switches, caps) | `/admin/agenter` |
| agil-1 ops surfaces | API only - no screens, see §2 |
| Partner, Bud, customer apps | the three Flutter apps, against `php artisan serve` |

### If something looks wrong

Check in this order, because these are the likely causes and the cheapest to
rule out: flag off (§0.3, §0.4) → seed missing (§0.2) → migration not run (§0.1)
→ scheduler not running (§0.6) → actually a bug. All 15 agents are seeded
**disabled**, so Ægil doing nothing is the designed state, not a failure.

---

## 1. What the merge itself found

Five defects that no amount of testing on either branch alone could have caught.
All are fixed and covered by tests; they are listed because they say something
about where the next one will be.

**Three of them were silent by design.** Both merge-day adapters degrade to
empty when their table is missing, which is correct behaviour for a branch
waiting on the other — and exactly why nothing complained when the table names
turned out to be wrong.

1. **`OrderEventsSource` read `order_events`; the table is `ops_order_events`.**
   Both plans' ownership tables name it unprefixed, and agil-1 applied its `ops_`
   convention to everything it created. Each side was locally right and the
   contract was ambiguous. Consequence had this shipped: flipping
   `POINTS_ORDER_SOURCE` on cutover would have awarded **nobody any points for
   any delivery**, with nothing in any log to say why.
2. **`WebhookSignalSource` read `feed_webhook_events`, a table neither branch
   creates.** agil-1's inbound landing table is `ops_feed_inbox`, and its shape
   differs too — no surrogate `id`, and `received_at` rather than `occurred_at`.
   Ægil would never have reacted to a feed post.
3. **The `SignalSource` binding ignored `POINTS_SIGNAL_SOURCE` entirely** and
   always returned fixtures. The env var is documented in `AGIL2_ROLLOUT.md` §7
   and was read nowhere.
4. **The order event's actor is two columns, not one.** agil-1 stores
   `actor_type`/`actor_id`; agil-2 decoded a single JSON `actor` field, so every
   event resolved to `system`/`null` — losing who did the thing on every record.
5. **A migration pinned a column to a position that only exists in production.**
   agil-2's `agent_product_identity` migration used `->after('ean_number')`; that
   column exists on the live and dev databases and **no migration in the repo
   creates it**. Worked on a developer's machine, failed on any database built
   from migrations.

**The pattern worth taking forward:** every one of these is a place where two
components agreed on a *name* in prose and disagreed in code. The frozen event
contract stopped that happening to the payloads — `MergeIntegrationTest` drives
the real path from `tests/fixtures/events/order.delivered.json` and passes — but
nothing played the same role for table names, column shapes or env var names. If
there is one thing to add to the contract before the next integration, it is
those.

### Also surfaced, and fixed

- **agil-1's ops fixtures inserted `providers.name`.** Production has
  `first_name`/`last_name` and **no `name` column at all**. Those tests passed
  against a schema that exists nowhere real. Now detected with
  `Schema::hasColumn`, the guard `FeedTokenTest` already used.
- **`MetricsTest::the_unseen_rate_pages_support` was date-dependent** — it
  windowed on a hard-coded 22 September while the fixture stamped `created_at`
  from the wall clock. It passed on the day it was written and failed the next.
  Nothing to do with the merge.
- **The test database has to be built from the live schema, not from
  migrations.** `scripts/rebuild_test_db.sh` (agil-2's, documented in
  `AGIL2_ROLLOUT.md` §6) copies the live structure and migrates on top. Run it
  before `php artisan test` or roughly a third of the suite fails on drift that
  has nothing to do with the code under test. This is the single most important
  thing for a new person to know about this repo.

---

## 1b. The screens are built but not connected — found 2026-09-23

**Corrected after a second look.** The first version of this section said the
screens only needed a navigation entry each. That was wrong, and the real
situation is worse: **they are presentational widgets with no container layer.**

### What is reachable today

| Path | Reachable? | How |
|---|---|---|
| Store publishes a feed post | **Yes** | `home_screen.dart:116` → `StoreFeedProfileScreen` → `FeedCreateOptionsSheet` → `FeedComposerScreen` |
| Customer browses the feed | **Yes** | `home_v1.dart:91` and `home_main_v1.dart:231` → `FeedShellScreen` |
| Customer opens a post from a push | **Yes** | `push_notification_service.dart:305` routes `feedNewPost` → `PostDetailScreen(postId:)` |
| Partner ops surface (`OpsShellScreen`, 5 tabs, 23 screens) | **No** | nothing constructs it |
| Courier run screen (`LiveStageScreen`) | **No** | nothing constructs it |
| agil-2 Points surfaces (`TilbyPremieScreen`, `MegPointsCard`, `PremiehyllaShelf`, `WelcomeMoment`, `SuggestionTray`) | **No** | nothing constructs them |
| `VaagenCard`, `DeliveryCodeCard`, `FeedPublisherTabs`, `OpsTrackingStatus` | **No** | nothing constructs them |

So the feed — the pre-agil-1 work — is wired end to end. Everything agil-1 and
agil-2 added on top of it is not.

### Why it is not a routing fix

`OpsShellScreen` takes `required List<OpsOrder> orders` plus `onPrimaryAction`,
`onReject`, `onAddTime`, `onMarkReady`, `onSeen`, and its banner state
(`offline`, `paused`, `pulseLost`, `soldTonightOre`, `nextCourierEtaMinutes`).
`LiveStageScreen` takes `required assignmentState`, `orderCode`, `address` and a
dozen more. Every one of them is a pure function of props — which is why they
test so cleanly, and why they cannot simply be pushed onto a navigator.

What is missing is the layer between them and the API:

1. **A fetch that does not exist yet.** `lib/networking/ops/ops_api.dart` has
   `heartbeat`, `devices`, `markSeen`, `transition` and `eventsSince` — there is
   no "give me this store's current orders". `GET /api/ops/panel/now` is the
   closest thing and it is admin-scoped, not store-scoped. Either the Partner app
   builds its state from `eventsSince` or the backend needs a store snapshot
   endpoint.
2. **A container per shell** mapping that state into the widget's props and each
   callback back onto `transition()`.
3. **Then** the navigation entry. Both apps have a `DrawerEnum`-driven drawer, so
   this last part really is a few lines.

I attempted the navigation entry first and it failed to compile precisely
because of this — `const OpsShellScreen()` has no valid zero-argument form. That
failure is the useful evidence here, so it is recorded rather than tidied away.

### Why the tests did not catch it

A widget test pumps the widget with hand-built props, so a screen with no data
source passes exactly as well as one with a working feed behind it. 666 green
Flutter tests say every screen renders correctly from good data; not one says
where that data comes from, or that a human can open the screen.

### What this means for manual testing

- **Feed and push (T2) can be tested today.** That path is complete on both
  sides.
- **The Partner ops surface, the courier run screen and every Points surface
  cannot be tested at all**, by anyone, until the container layer exists. There
  is no configuration, flag or seed that unlocks them.

---

## 2. Admin panel screens — agil-1's half is the largest gap

**agil-1's screens were not built. agil-2's were.** Corrected 2026-09-23 after
checking the merged tree rather than trusting the earlier note: agil-2 shipped
Blade screens into the existing admin, with controllers and web routes.
agil-1 delivered only the data behind its own screens.

agil-1 side — every one of these is a working, tested JSON endpoint:

| Screen | Endpoint | Tested in |
|---|---|---|
| **Nå** — orders by state, unseen, waiting couriers, paused stores, problems | `GET /api/ops/panel/now` | `PanelTest` |
| **Unntak** inbox — SLA timers, claim, resolve, overrides | `GET /api/ops/panel/exceptions`, `.../claim`, `.../resolve`, `POST /api/ops/pickup/orders/{id}/panel-override` | `PanelTest`, `EscalationTest` |
| **Butikker** — liveness board + store detail | `GET /api/ops/panel/stores`, `/stores/{id}` | `PanelTest`, `DeviceLivenessTest` |
| **Bud** — shift board + courier detail | `GET /api/ops/panel/couriers` | `PanelTest` |
| Role landing pages | `GET /api/ops/panel/role-landing` | `PanelTest` |
| **Policy editor** (reason required → `audit_log`) | `PolicyService::set()` | `PolicyTest` |
| **Feed** oversight, composer, eligibility, change-log, takeover | `Aerend-Feed /admin/feed/*`; `/api/ops/feed/*`, `/api/ops/change-log` | `AdminFeedOversightTest`, `ProductChangeLogTest`, `admin-feed.test.ts` |

**agil-2 side — built and clickable.** `/admin/poeng-v2` (dashboard, ledger,
adjust, rebuild, prizes, claims, donations, rules, tier review, missions, league
month-end, fraud flags, partner proposals) and `/admin/agenter` (register,
per-agent kill switch, caps). Views live at
`resources/views/admin/pages/super_admin/{points,agents}/index.blade.php` with
`PointsAdminV2Controller` and `AgentAdminController` behind them. So the gap in
this section is agil-1's half only.

**What agil-1's missing half costs today:** support can do all of it, but
through an API client rather than a screen. The override paths — panel scan
override, manual state change with a reason — are the ones a human reaches for
under time pressure and the worst possible candidates for curl.

**Sizing:** seven screens, all read-mostly, against endpoints already shaped
for a table — and agil-2's two are a working precedent to copy, in the same
admin, with the same layout and auth. The one genuinely new piece is the Unntak
inbox's SLA timers, which want a live-updating view rather than a page render.
---

## 3. Other UI work outstanding

**Bergen reskin naming debt** (customer app). The reskin landed — Bergen palette,
`AerendBergenAuthTokens`, correct app icon on `#173E48`. Not finished:

- `lib/theme/reen_pre_club_theme.dart` still carries the old filename for a class
  no longer called that; ten files import it.
- `assets/Logo/reen-mark-coral.png` and `assets/Logo/reen/mark-coral-navy.png`
  still carry Reen names and render on five live surfaces — `homeMainV1`,
  `feed_branded_header`, `home_v1`, `contact_us_screen`, `snurre_chat_screen`.
  Both were touched in the reskin commit, so the **pixels are probably already
  right and only the names are wrong** — but that wants one visual confirmation,
  because the alternative is a coral Reen mark on the feed header.

**Two surfaces a widget test cannot reach**, both built, both needing one manual
pass:

- **Composer image picker** (Hare-Store) — the 10 MB gate and the inline error
  with a working Retry are built and analyze-clean, but the picker crosses a
  platform channel. Check: oversized photo blocked before upload; airplane mode
  gives an inline error and Retry works; a normal photo publishes unchanged.
- **Story viewer with a broken `media_url`** (Aerend-app) — the view is tested
  directly because `CachedNetworkImage` needs `path_provider`, so driving the
  full screen sits on the placeholder and passes for the wrong reason.

**Analyze noise in the customer app:** 632 infos and 2 errors. Both errors are in
a stray `test_app/` scaffold that exists identically on both branches — a
`flutter create` leftover, not merge damage. Worth deleting.

**Pre-existing, nobody's plan:** `lib/screens/common/account/account_detail.dart`
has ~8 hardcoded Norwegian strings marked `// TODO(l10n)`.

---

## 4. Blocked on a decision or a credential

**Points migration cutover** (agil-2's last open task). Needs the Appendix B
conversion factor **and** production access. The job, dry run and reconciliation
report are built and tested; a live run refuses to start until
`POINTS_MIGRATION_FACTOR_CONFIRMED=true`. The 24-hour monitoring window follows
it.

**Vipps payout (courier disbursements).** A different Vipps product (Utbetaling)
with its own merchant agreement. `payouts`/`payout_lines` and the 04:00 batch are
built against a pluggable transport, deliberately bound to
`UnavailablePayoutTransport` — a batch that silently no-ops is worse than one
that refuses. **Unblocks when** the agreement is signed and sandbox credentials
exist.

**Six policy values are placeholders, not decisions** (Appendix B): the three
waiting-pay figures, trip compensation, and the two store commercial rates (14 %
commission, 1.55 % payment fee). All marked in `docs/OPS_POLICY_KEYS.md`. Each is
one `PolicyService::set()` call with a reason; every historical order keeps the
`policy_version` it was quoted under.

**Four ops tasks need prod access, a real device, or DO rights** — all
**PENDING — HUMAN**, none attempted:

- **T1** verify `GET /api/internal/feed-device-tokens` is live in prod. A 404
  means Laravel never deployed the route and needs a `workflow_dispatch` run.
- **T2** push-notification E2E on two real phones: store publishes → customer
  push within 30s → deep-link; customer comments → store push. **Still the most
  important unverified path in the product.** Processors and templates are
  unit-tested; delivery is not.
- **T9** delete the demo seed post in prod (id `1`, likely `store_details_id`
  45). **Confirm what that row actually is first** — real partner posts may sit
  alongside it.
- **T10** rotate `aerend-feed-pg` + `aerend-feed-redis` credentials and redeploy.
  ~30s downtime, and must run **after** T2.

**Two out-of-band items, not engineering:**

- **Partner content seeding** — 10–15 stores × 3–5 posts before launch. BD work.
  An empty feed on day one reads as a broken app rather than a new one, and the
  mix rule (5 store posts per Ærend post) has nothing to mix without it.
- **Native Norwegian review of the 23 machine-translated feed ARB keys.** Machine
  Norwegian in a Bergen-local product is noticeable, and these sit on the
  most-read surface in the app.

---

## 5. Still blocked on the eventual `main` merge

Not blocked on agil-2 any more — that merge has happened. These wait on the
branch policy changing:

- **Post-merge integration against live producers.** The adapters are now proven
  against real rows in the integration suite, but "a real feed webhook arriving
  from the deployed feed service creates a suggestion" needs both services
  running and a staging environment.
- **The `main` merge itself.** Verified, not executed: a dry-run merge
  auto-merges everything and conflicts in `.env` alone. **Resolve that hunk in
  `main`'s favour** — `agil-1` points `VIPPS_LOGIN_REDIRECT_URI` at `127.0.0.1`
  from local testing, `main` at production. (`main`'s value also has a typo:
  `https//ailogistics.no`, missing the colon.)
- **Three out-of-ownership exceptions** to settle before that merge: the tracked
  `.env`; three pre-existing `Snurre` commits (`9ddee0f`, `4253c07`, `2b85dc0`)
  that belong to neither plan and should be reviewed on their own merit; and the
  shared-file appends (`main.dart`, `l10n.yaml`, generated `lib/l10n/*`,
  `routes/api.php`, `Kernel.php`, `config/broadcasting.php`,
  `AppServiceProvider.php`).
- **Flag rollout.** 30 agil-1 surface flags plus agil-2's (`points`,
  `premiehylla`, `missions`, `league`, `aegil_level_max`), all defaulting off.
  Order and rollback: `docs/OPS_ROLLBACK.md` §5 and `docs/AGIL2_ROLLOUT.md`.

---

## 6. Verification this environment could not do

- **Docker Desktop is not running**, so 120 of Aerend-Feed's 180 tests skip —
  every Postgres- and Valkey-backed suite, including feed-tab ranking and
  moderation. They pass with the local stack up; they were not run here.
- **No staging environment**, so "store publishes → appears in the customer feed
  ≤ 5s" and the two-service integration pass remain unmeasured.
- **No real devices** — T2, plus the two platform-channel surfaces in §3.
- **The load test measures the monolith, not the wire.** p50 9 ms / p95 25 ms /
  max 35 ms against a 1 s budget, with the broadcast driver faked. Read it as
  "the monolith can produce 500 orders' worth of fan-out inside the budget", not
  "a phone sees it in a second".

---

## Suggested order

1. **Admin panel screens** (§2) — the only gap where working, tested behaviour is
   unreachable to the people who need it under pressure. Start with Unntak.
2. **Add table names, column shapes and env var names to the cross-branch
   contract** (§1). Five of five merge defects were name disagreements; the
   payloads, which *were* contracted, survived untouched.
3. **The two manual UI passes** (§3) — an hour each, and they close the last
   surfaces where a test passes for a reason other than the feature working.
4. **T2** (§4) — the most important unverified path in the product. Two phones.
5. **Reen naming cleanup** (§3) — cheap, and one visual check settles whether it
   is cosmetic or a live wrong-brand mark.
6. Everything else waits on an agreement, a decision, or the `main` merge.
