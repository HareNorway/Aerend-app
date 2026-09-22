# AGIL-1 — what is left

Companion to `AGIL-1-PLAN.md`. The plan records what was built; this records what
is not, and why. Last updated **2026-09-22**.

> 🛑 **No merges.** Nothing from `agil-1` goes into `main` or `master` in any of
> the five repos, and nothing is pushed. `agil-1` stays local everywhere. Merge
> readiness was verified and deliberately not executed — the findings are kept in
> `AGIL-1-PLAN.md` §"Phase 12 merge-prep notes" for whenever that changes.

**Where things stand.** All twelve phases are worked through. Test state:
Hare-AdminPanel 490 (+3 in the `load` group), Hare-Store 222, Hare-Driver 129,
Aerend-app 187, Aerend-Feed 60 passed / 120 skipped. Every suite green, every
repo clean on `agil-1`.

What remains falls into four kinds: **UI that was never built** (§1–2), **work
blocked on another branch** (§3), **work blocked on a decision or a credential**
(§4), and **verification this environment cannot do** (§5).

---

## 1. Admin panel screens — the largest gap

**Nothing was built.** There is no Blade or Vue under
`Hare-AdminPanel/resources/views/admin` for any agil-1 surface, and no `web.php`
route. Two plan tasks were ticked that read as if there were; both are now marked
`[~]` with this correction.

Everything behind these screens exists, is tested, and answers JSON today:

| Screen the plan names | What exists instead | Tested in |
|---|---|---|
| **Nå** — orders by state, unseen, waiting couriers, paused stores, open problems | `GET /api/ops/panel/now` | `PanelTest` |
| **Unntak** inbox — SLA timers, claim, resolve, override actions | `GET /api/ops/panel/exceptions`, `POST .../claim`, `.../resolve`, `POST /api/ops/pickup/orders/{id}/panel-override` | `PanelTest`, `EscalationTest` |
| **Butikker** — liveness board + store detail | `GET /api/ops/panel/stores`, `/stores/{id}` | `PanelTest`, `DeviceLivenessTest` |
| **Bud** — shift board + courier detail | `GET /api/ops/panel/couriers` | `PanelTest` |
| Role landing pages | `GET /api/ops/panel/role-landing` | `PanelTest` |
| **Policy editor** (reason required → `audit_log`) | `PolicyService::set()` + the 422-without-reason rule | `PolicyTest` |
| **Feed** oversight, Ærend composer, eligibility, change-log search, hide-product takeover, feed health card | `Aerend-Feed` `/admin/feed/*`; monolith `/api/ops/feed/*`, `/api/ops/change-log`, `/api/ops/products/{id}/takeover` | `AdminFeedOversightTest`, `ProductChangeLogTest`, `admin-feed.test.ts` |

**What this costs today:** support can do every one of these things, but through
an API client rather than a screen. The override paths in particular — panel scan
override, manual state change with a reason — are the ones a human reaches for
under time pressure, and they are the worst candidates for curl.

**Sizing:** seven screens, all read-mostly, all against endpoints that already
return exactly the shape a table needs. The panel read models were written with a
front-end in mind ("one panel, one truth"), so this is view work rather than
design or data work. The one genuinely new piece is the Unntak inbox's SLA timers,
which need a live-updating view rather than a page render.

---

## 2. Other UI work outstanding

**Naming debt from the Bergen reskin** (customer app). The reskin itself landed —
the tokens are the Bergen palette (`#245A69`/`#173E48`/`#F26D3D`, mint, teal
mark), the class is `AerendBergenAuthTokens`, the app icon points at
`icon/aerend_app_icon.png` on `#173E48`. What was not finished is the cleanup:

- `lib/theme/reen_pre_club_theme.dart` still carries the old filename for a class
  that is no longer called that. Ten files import it.
- `assets/Logo/reen-mark-coral.png` and `assets/Logo/reen/mark-coral-navy.png`
  still carry Reen names and are rendered on five live surfaces —
  `homeMainV1`, `feed_branded_header`, `home_v1`, `contact_us_screen`,
  `snurre_chat_screen`. Both files were touched in the same commit as the
  reskin (`7638b33`), so the **pixels are probably already correct and only the
  names are wrong** — but that wants one visual confirmation before anybody
  trusts it, because the alternative is a coral Reen mark on the feed header.
- `assets/Logo/reen/mark-coral-navy.png` has its own `pubspec.yaml` asset entry
  (line 117) alongside the `assets/Logo/` directory include.

Low risk, worth an hour, and it removes the last place a reader could think this
app is called Reen.

**Design flourishes deliberately skipped** on the Bergen splash, at the agreed
fidelity level: the mountain/harbor skyline illustration, the animated
"Bergenske butikker / Levert i kveld / Poeng på hylla" chip cards, and the
boat/Ægil graphics. Noted in `splash.dart:13` so it reads as a choice rather than
an omission. Re-open only if someone wants the seasonal treatment.

**Two Flutter surfaces that are built but not covered by a widget test**, both
because they cross a platform channel a widget test cannot drive:

- **Composer image picker** (Hare-Store). The 10 MB gate
  (`feed_composer_bloc.dart:25`) and the inline error with a working Retry are
  built and analyze-clean, but the picker itself goes through platform channels.
  Needs one manual pass: oversized photo blocked before upload, airplane mode →
  inline error + Retry works, normal photo publishes unchanged.
- **Story viewer with a broken `media_url`** (Aerend-app). The view is tested
  directly (`story_unavailable_view.dart`) because `CachedNetworkImage` needs
  `path_provider`, so driving the full screen in a widget test sits on the
  placeholder and passes for the wrong reason. The extraction is honest; the
  full-screen path is still unverified.

**Pre-existing, not agil-1's:** `lib/screens/common/account/account_detail.dart`
has ~8 hardcoded Norwegian strings marked `// TODO(l10n)`. That is agil-2's Meg
surface; flagged only so it is not mistaken for new debt.

---

## 3. Blocked on agil-2 landing `sync-B`

`sync-B` does not exist — checked 2026-09-22, no such branch or tag in
Hare-AdminPanel. It is meant to carry the agent platform substrate (`agents`,
`agent_runs`, scoped tokens, kill switches, `AgentInvoker`). Building a second
`AgentInvoker` is exactly what the merge contract exists to prevent, so these
wait.

Each of these is **UI-bearing** — the screens and their non-agent halves are
already built, and what is missing is the agent call behind them:

| Item | Surface | Non-agent half already built |
|---|---|---|
| **P1** `agent.menu_copy` | Generate description → use/rewrite/discard, allergen proposals, batch queue | — |
| **P5** `agent.hours_exceptions` | Free-text → structured rows, holiday prompt, coherence check | Åpningstider weekly grid + customer sentence (`StoreHoursService`) |
| **B4** `agent.bud_explain` | "Forklar" on run summary and Inntekt rows | The "Forklar" and door-note slots exist on the Bud run summary |
| **P2** `agent.photo_enhance` | Original/Forbedret, operation chips, QA pass/fail | — |
| **P3** `agent.campaign_planner` | Observation → proposal → post draft → result card | "Ukens melding" is built and picks from the Innsikt rows |
| **P4** `agent.onboarding` | "Sett opp med Ægil" hours Q&A, AI menu import | The hours grid it writes into, and the test order it triggers |
| **B1** `agent.bud_translate` | nb/pl/en labels, "vis original", dotted fallback | — |
| **B2** `agent.bud_problem` | Hold-to-speak problem report, confidence branch | Hold-to-speak exists for Partner voice entry |
| **B3** `agent.bud_door` | "Si noe om døren" → chips → consent → next-courier note | Door profiles and their retention job |

The Ægil slot on the Bud live stage is wired to an optional handler and stays
present-but-disabled, so the control row will not shift under a courier's thumb
when B1–B3 land.

---

## 4. Blocked on a decision or a credential

**Vipps payout (courier disbursements).** A different Vipps product (Utbetaling)
with its own merchant agreement. `payouts`/`payout_lines` and the 04:00 batch are
built against a pluggable transport, and the bound transport is deliberately
`UnavailablePayoutTransport` — a batch that silently no-ops is worse than one
that refuses. `VippsTest::test_payout_is_blocked_on_a_product_agreement` is an
explicit skip so the gap shows in test output. **Unblocks when** the agreement is
signed and sandbox disbursement credentials exist.

**Six policy values are placeholders, not decisions** (plan Appendix B): the three
waiting-pay figures, trip compensation, and the two store commercial rates
(14 % commission, 1.55 % payment fee). All seeded so a fresh install settles
sanely, all marked in `docs/OPS_POLICY_KEYS.md`. Each is one `PolicyService::set()`
call with a reason when the real figure lands, and every historical order keeps
the `policy_version` it was quoted under.

**Four ops tasks need prod access, a real device, or DO rights** — all
**PENDING — HUMAN**, none attempted:

- **T1** verify `GET /api/internal/feed-device-tokens` is live in prod. A 404
  means Laravel never deployed the route and needs a `workflow_dispatch` run.
- **T2** push-notification E2E on two real phones: store publishes → customer
  push within 30s → deep-link; customer comments → store push. **Still the single
  most important unverified path in the feed.** Processors and templates are
  unit-tested; delivery is not.
- **T9** delete the demo seed post in prod (id `1`, likely `store_details_id` 45).
  **Confirm what that row actually is first** — the handover warns real partner
  posts may sit alongside it.
- **T10** rotate `aerend-feed-pg` + `aerend-feed-redis` credentials and redeploy.
  ~30s downtime, and must run **after** T2.

**Two out-of-band items, not engineering:**

- **Partner content seeding** — 10–15 stores × 3–5 posts before launch. BD work.
  An empty feed on day one reads as a broken app rather than a new one, and the
  mix rule (5 store posts per Ærend post) has nothing to mix without it.
- **Native Norwegian review of the 23 machine-translated feed ARB keys.** Machine
  Norwegian in a Bergen-local product is noticeable, and these sit on the
  most-read surface in the app. Needs a native speaker, not a translator API.

---

## 5. Verification this environment could not do

- **Docker Desktop is not running**, so 120 of Aerend-Feed's 180 tests skip —
  every Postgres- and Valkey-backed suite, including feed-tab ranking and
  moderation. They pass with the local stack up (`docker-compose.dev.yml` +
  `npm run dev`); they were not run here.
- **No staging environment**, so the "store publishes → appears in the customer
  feed ≤ 5s" timing and the two-service integration pass are unmeasured. Both
  halves are tested in isolation.
- **No real devices** — T2 above, plus the two platform-channel surfaces in §2.
- **Load test measures the monolith, not the wire.** p50 9 ms / p95 25 ms / max
  35 ms against a 1 s budget, with the broadcast driver faked. Read it as "the
  monolith can produce 500 orders' worth of fan-out inside the budget", not "a
  phone sees it in a second". The Soketi round trip belongs to the staging pass.

---

## Suggested order, if this picks back up

1. **Admin panel screens** (§1) — the only gap where working, tested behaviour is
   unreachable to the people who need it under pressure. Start with Unntak, since
   the override paths are the ones worst suited to curl.
2. **The two manual UI passes** (§2) — an hour each, and they close the last two
   surfaces where a test passes for a reason other than the feature working.
3. **Reen naming cleanup** (§2) — cheap, and one visual check answers whether it
   is cosmetic or a live wrong-brand mark on the feed header.
4. **T2** (§4) — the most important unverified path in the product. Needs two
   phones and nothing else.
5. Everything else waits on `sync-B`, an agreement, or a decision.
