# Hare-Customer — Dugnad Performance Upgrade Plan

**Status:** Phase 0 (partial) + Phase 1 + Phase 2 implemented; Phase 3–4 pending  
**Scope:** **Dugnad mode only** — commercial home (`HomeV1`), feed, search, AI (Snurre), delivery checkout, and ride flows are **out of scope** for this update.  
**Goal:** Make the dugnad experience feel fast without breaking existing behaviour.  
**Constraint:** Points, badges, and missions still need reasonably fresh data — but we should not block entire screens waiting for every endpoint.

---

## 1. Problem summary (dugnad)

With backend upgraded (4 GB+ RAM), remaining dugnad slowness is largely **client-side request orchestration** and **loading UX**:


| Symptom                      | Root cause                                                                                                            |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| Profile tab feels “stuck”    | 7–9 API calls; profile body hidden until **all** finish sequentially                                                  |
| Hjem tab slow on open        | Up to 9 parallel calls on `DGHome`; full-body spinner while waiting                                                   |
| Same data fetched many times | Club detail, leaderboard, referral summary, points team hit from Hjem + Kampanje + Toppliste + Profil                 |
| “Stuck” loading feel         | Full-screen primary-bg `CircularProgressIndicator` on most dugnad screens                                             |
| Cold start delay             | Fixed **3 s** splash timer before reaching dugnad shell (affects all modes, but dugnad users feel it on every launch) |
| Backend CPU still high       | Duplicate + eager requests from dugnad tabs mounted before user visits them                                           |


**What already works well in dugnad (reuse these patterns):**

- `DGHome` — `Future.wait` for parallel fetch + hero visible while content loads
- `DugnadProfileSection` header — shows cached name/avatar from prefs immediately (body does not)
- `leaderboard_screen.dart` — in-tab secondary loader for scorers while table stays visible
- Skeleton infrastructure in `lib/commonView/skeleton_loaders/` (reuse for dugnad screens)

**Out of scope (do not change in this effort):**

- `HomeV1`, `HomeBloc`, `SearchStore`, `FeedShellScreen`, `FeedHome`, `SnurreChatScreen`, `OrderCart` (commercial tabs)
- Delivery / ride / wallet flows unless directly invoked from a dugnad screen (e.g. matkasse campaign checkout keeps current behaviour)

---

## 2. Design principles

1. **Stale-while-revalidate (SWR)** — Show last-known data instantly; refresh in background.
2. **Parallel by default** — Never chain independent `await`s; use `Future.wait` (see `dg_home.dart`).
3. **Progressive render** — Shell + cached sections first; per-section loaders for slow bits.
4. **Fetch on visibility** — Don’t load dugnad tab data until the user opens that tab (or prefetch lightly).
5. **Single source of truth** — One in-memory cache per resource; screens subscribe, don’t each call the API.
6. **Tiered freshness** — Not everything needs realtime (see §4).
7. **Skeletons over spinners** — Keep layout stable; reserve full-screen spinners for payment/auth only.
8. **No silent behaviour change** — Pull-to-refresh, post-action invalidation, and logout clear cache as today.

---

## 3. Proposed architecture: `DugnadDataCache`

Add a thin cache layer **above** `DugnadRepo`, below dugnad screens. Not a full state-management rewrite.

**Location (suggested):** `lib/services/dugnad_data_cache.dart`

```
┌─────────────────────────────────────────────────────────┐
│  Dugnad screens (DGHome, Profile, Kampanje, Toppliste,  │
│  Points, Missions, Career, Referral, …)                 │
└─────────────────────────┬───────────────────────────────┘
                          │ listen / read cached
┌─────────────────────────▼───────────────────────────────┐
│  DugnadDataCache (ChangeNotifier or singleton streams)   │
│  - TTL per key                                           │
│  - in-flight deduplication (same request → one Future)     │
│  - stale-while-revalidate                                │
└─────────────────────────┬───────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────┐
│  DugnadRepo + DugnadState (prefs for identity/branding)  │
└─────────────────────────────────────────────────────────┘
```

### Cache keys (dugnad endpoints only)


| Key                                    | Source endpoint                       | Default TTL | Invalidate on                            |
| -------------------------------------- | ------------------------------------- | ----------- | ---------------------------------------- |
| `pointsSummary`                        | `POST points/summary`                 | 60 s        | purchase, referral capture, pull-refresh |
| `referralSummary`                      | `POST referral/summary`               | 60 s        | referral share/capture, pull-refresh     |
| `leaderboard:{clubId}`                 | `GET sports-club/{id}/leaderboard`    | 120 s       | pull-refresh, points-changing actions    |
| `gamificationConfig:{clubId}`          | `GET dugnad/config`                   | 1 h         | admin config change (rare)               |
| `gamificationCareer:{clubId}:{teamId}` | `POST dugnad/gamification/career`     | 60 s        | mission complete, badge earn             |
| `clubDetail:{clubId}`                  | `GET sports-club/{id}`                | 15 min      | club switch, `DugnadState.revision`      |
| `sponsorStores:{clubId}`               | `GET sports-club/{id}/sponsor-stores` | 15 min      | club switch                              |
| `clubList`                             | `GET sports-club/list`                | 15 min      | club switch                              |
| `pointsTeam`                           | `POST sports-club/points-team`        | 60 s        | team change, welcome bonus               |
| `campaigns:{clubId}`                   | club campaigns (kampanje)             | 120 s       | pull-refresh, after order                |


**Persistence:** Phase 1 = memory only. Phase 2 = optional JSON in `SharedPreferences` for points summary + club detail (instant cold profile/home).

**Existing prefs to leverage:** `DugnadState` already stores club id, branding, `pointsTotal`, team id — use these for **instant first paint** before network returns.

---

## 4. Data freshness tiers (dugnad)


| Tier                           | Data                                                                       | Strategy                                                                           |
| ------------------------------ | -------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| **A — Static / slow-changing** | Badge catalog (`dugnad/config`), club branding, sponsor list, club list    | Long TTL; refresh on club change only                                              |
| **B — Semi-realtime**          | Points summary, career badges, leaderboard rank, referral counts           | SWR: show cache, background refresh; invalidate after user actions                 |
| **C — Realtime**               | Matkasse/campaign checkout payment, donation Vipps flows                   | No cache or very short TTL; keep current behaviour                                 |
| **D — Derived / over-fetched** | Full points ledger page 1 **only** to detect subscription badge on profile | Replace with career API flag or dedicated lightweight endpoint (backend follow-up) |


---

## 5. Screen-by-screen plan (dugnad only)

### 5.1 Dugnad shell — 4 tabs (`home_main_v1.dart`)

**Dugnad tabs:** Hjem (`DGHome`) · Kampanje · Toppliste · Profil (`Account`)

**Current:** `PageView` builds all four tab roots at once → every tab’s `initState` fires APIs before the user visits them.

**Target (pick one):**


| Option                        | Approach                                                         | Trade-off                              |
| ----------------------------- | ---------------------------------------------------------------- | -------------------------------------- |
| **A — Lazy tabs**             | Build tab child only after first visit (`Set<int> _visitedTabs`) | Best request reduction; small refactor |
| **B — Defer loads**           | Tabs mount but `_load()` runs on first focus callback from shell | Keeps scroll state; medium refactor    |
| **C — Prefetch (this works)** | Only Hjem loads on shell open; others on first tap               | Simplest; good enough for phase 1      |


**Recommendation:** Option C for phase 1, Option A for phase 2.

**Constraint:** Changes apply only when `DugnadState.instance.isDugnadMode` — commercial `PageView` children unchanged.

**Files:** `lib/screens/common/homeMainV1/home_main_v1.dart`

---

### 5.2 Hjem — `dg_home.dart`

**Current (mixed):**

- Good: `Future.wait` for up to 9 endpoints
- Bad: `SliverFillRemaining` + centered spinner blocks feed body; reloads entire batch on every `DugnadState.revision`

**Target:**

1. Keep hero + club header visible always
2. Replace body spinner with **dugnad feed skeleton** (`DugnadFeedSkeleton` using `BaseSkeleton`)
3. On `revision` change: invalidate only affected cache keys (e.g. team change → points + career, not sponsor stores)
4. Read/write via `DugnadDataCache` so other tabs don’t re-fetch the same payloads

**Files:** `lib/screens/dugnad/dg_home.dart`

---

### 5.3 Profil — `account.dart` + `dugnad_profile_section.dart`

**Current (bad):**

- `Account.initState` (dugnad path): `syncPointsTeam`, `syncClubTheme`, plus `AccountBloc` profile/wallet calls
- `DugnadProfileSection._load`: **sequential** 7 awaits; entire body gated by `_loading`
- Duplicate: `referral/summary` (profile + `IncomingReferralBanner`), `sports-club/{id}` (Account + profile section)
- Ledger fetched only for `hasSub` boolean

**Target:**

1. **Phase A — Quick wins**
  - Rewrite `_load()` to `Future.wait` (mirror `dg_home.dart`)
  - Dedupe `syncClubThemeFromApi` (Account vs profile — single path via `DugnadState` or cache)
  - Pass `referral` from parent into `IncomingReferralBanner` instead of second fetch
  - Skip `getWalletBalance()` on dugnad profile (not displayed)
  - Drop ledger call; derive subscription badge from `career` or config
2. **Phase B — Progressive UI**
  - Remove global `_loading` gate
  - Always render: header (prefs), club card (`DugnadState`), account rows
  - Per-section: points card, badges, leaderboard row — mini-shimmer or stale data + refresh indicator
3. **Phase C — Cache**
  - Profile reads from `DugnadDataCache`; `refreshIfStale()` on tab focus

**Files:** `lib/screens/common/account/account.dart`, `lib/screens/dugnad/dugnad_profile_section.dart`, `lib/screens/dugnad/widgets/incoming_referral_banner.dart`, `lib/screens/common/account/account_bloc.dart` (dugnad branches only)

---

### 5.4 Kampanje — `kampanje_screen.dart`

**Current:** Own full load (`getClubDetail`, campaigns) — duplicates `DGHome`.

**Target:**

1. Read campaigns from `DugnadDataCache`; show cached list immediately
2. Background refresh on tab first focus
3. Skeleton instead of full-page spinner

**Files:** `lib/screens/dugnad/kampanje_screen.dart`, `lib/screens/dugnad/matkasse_campaign_screen.dart` (if linked)

---

### 5.5 Toppliste — `leaderboard_screen.dart`

**Current:** Own `getLeaderboard` on init — duplicates `DGHome` and profile.

**Target:**

1. Read leaderboard from cache; show cached table immediately
2. Keep existing pattern: secondary load for scorers sub-tab only
3. Skeleton for initial table if no cache

**Files:** `lib/screens/dugnad/leaderboard_screen.dart`

---

### 5.6 Dugnad sub-screens (drill-downs)

**Current:** ~15 dugnad screens use full-screen primary-bg `CircularProgressIndicator`.

**Priority migration (highest traffic first):**


| Screen                         | File                                                        |
| ------------------------------ | ----------------------------------------------------------- |
| Points                         | `dugnad_points_screen.dart`                                 |
| Missions (Matches of the week) | `dugnad_missions_screen.dart`                               |
| Referral share                 | `referral_share_screen.dart`                                |
| Career                         | `career_screen.dart`                                        |
| Team detail                    | `team_detail_screen.dart`                                   |
| Supporter card                 | `supporter_card_screen.dart`                                |
| Season recap                   | `season_recap_screen.dart`                                  |
| Transfer window                | `transfer_window_screen.dart`                               |
| Donation setup/manage          | `donation_setup_screen.dart`, `donation_manage_screen.dart` |
| Points history                 | `points_history_screen.dart`                                |
| Points team picker             | `points_team_picker_screen.dart`                            |
| Formen                         | `dugnad_formen_screen.dart`                                 |
| Privacy                        | `dugnad_privacy_screen.dart`                                |


**Target:**

1. **Hero-visible + content skeleton** (pattern from `dg_home.dart` hero-always-visible)
2. New skeletons: `DugnadProfileSkeleton`, `DugnadPointsSkeleton`, `DugnadLeaderboardSkeleton`, `DugnadMissionsSkeleton`
3. Reserve `withGlobalLoadingOverlay` for matkasse/campaign payment + Vipps only

**Reference:** `lib/commonView/skeleton_loaders/SKELETON_LOADER_GUIDE.md`

---

### 5.7 Splash → dugnad entry (`splash_bloc.dart`)

**Scope note:** Splash is shared, but only the **dugnad routing path** is in scope — remove artificial delay before `HomeMainV1` when `DugnadState.instance.onboardingComplete`.

**Current:** Fixed 3 s `Timer` before navigation.

**Target:**

1. Navigate as soon as `checkAppVersionApi` completes (FCM token can continue in background)
2. When route is dugnad home: optionally warm `DugnadDataCache` keys (`clubDetail`, `pointsSummary`) after auth known
3. Do **not** change commercial/guest routing logic beyond shared delay removal

**Files:** `lib/screens/common/splash/splash_bloc.dart` (delay removal only)

---

## 6. Loading UX overhaul (dugnad)

### Patterns to replace


| Pattern                                  | Where                         | Replacement                        |
| ---------------------------------------- | ----------------------------- | ---------------------------------- |
| Full-screen primary bg + white spinner   | Most `lib/screens/dugnad/*`   | Hero + skeleton in content area    |
| All-or-nothing `_loading` bool           | `dugnad_profile_section.dart` | Per-section state                  |
| `SliverFillRemaining` + centered spinner | `dg_home.dart`                | Skeleton list in sliver            |
| Global black overlay on data fetch       | Dugnad screens                | Skeleton only; overlay for payment |


### Standard loading contract

```dart
enum SectionLoadState { idle, loading, success, error }

// Each section:
// - success → show data
// - loading + hasStaleData → show stale + top progress bar
// - loading + no data → skeleton
// - error + hasStaleData → show stale + retry chip
// - error + no data → inline error with retry
```

### Visual guidelines

- **Primary progress:** 2 px `LinearProgressIndicator` at top of scroll content
- **Section placeholders:** Shimmer matching final layout
- **Pull-to-refresh:** Invalidates relevant cache keys (keep on `DGHome`, profile, kampanje, toppliste)
- **First paint:** User sees structure within **100 ms** from `DugnadState` / cache

---

## 7. Request reduction checklist (dugnad)


| Issue                                                 | Fix                             | Est. impact                      |
| ----------------------------------------------------- | ------------------------------- | -------------------------------- |
| Profile sequential waterfall                          | `Future.wait`                   | Latency −50–70%                  |
| Duplicate `referral/summary`                          | Pass from parent to banner      | −1 per profile open              |
| Duplicate `sports-club/{id}`                          | Dedupe in cache / `DugnadState` | −1–2 per profile open            |
| Ledger for badge flag                                 | Use career/config               | −1 per profile open              |
| Eager 4-tab mounting                                  | Lazy tab load                   | −10–20 calls on cold start       |
| Hjem + Kampanje + Toppliste + Profil same leaderboard | Shared cache                    | −2–3 per tab switch              |
| Wallet on dugnad profile                              | Skip when `isDugnadMode`        | −1 per profile open              |
| Splash 3 s wait                                       | Remove artificial delay         | Perceived −3 s to dugnad shell   |
| `revision` → full reload                              | Targeted cache invalidation     | Fewer calls on team/theme change |


---

## 8. Backend coordination (optional, dugnad APIs)

Frontend changes deliver most UX win. Optional backend follow-ups in `Hare-AdminPanel`:


| Idea                                                   | Effort | Notes                                                                |
| ------------------------------------------------------ | ------ | -------------------------------------------------------------------- |
| **Combined dugnad dashboard**                          | Medium | Single endpoint: summary + referral + career + rank for profile/home |
| **HTTP Cache-Control** on `dugnad/config`, club detail | Low    | `max-age=300`                                                        |
| **Redis cache** for leaderboard                        | Medium | 60 s TTL; invalidate on points write                                 |
| **Subscription badge flag** on career response         | Low    | Avoids ledger fetch on profile                                       |


Only dugnad-related controllers (`DugnadGamification*`, `DugnadPoints*`, sports-club APIs).

---

## 9. Implementation phases

### Phase 0 — Measurement (1–2 days)

- [x] Debug logging wrapper on `DugnadRepo` (endpoint, duration, caller) behind `kDebugMode`
- [ ] Baseline **dugnad mode only**: cold start → Hjem visible, Profil tap → content visible, API count per flow
- [ ] Record under **§12 Benchmarks**

### Phase 1 — Quick wins (3–5 days)

**Risk: Low | Impact: High**

- [x] Profile `_load`: sequential → `Future.wait`
- [x] Remove duplicate referral fetch (pass to banner)
- [x] Skip wallet fetch on dugnad profile
- [x] Remove ledger fetch; use career for subscription badge
- [x] Remove splash 3 s artificial delay (dugnad entry path)
- [x] Dedupe `syncClubThemeFromApi` across Account + profile

### Phase 2 — `DugnadDataCache` + progressive UI (1–2 weeks)

**Risk: Medium | Impact: Very high**

- [x] Implement `DugnadDataCache` with TTL + in-flight dedupe
- [x] Migrate `dg_home.dart` to cache
- [x] Refactor `dugnad_profile_section.dart` to progressive sections
- [x] Migrate Kampanje + Toppliste to cache reads
- [x] Lazy dugnad tab loading (option C or A in `home_main_v1.dart`)

### Phase 3 — Dugnad loading UX (1–2 weeks, parallel with phase 2)

**Risk: Low | Impact: Medium (perceived)**

- [x] Add dugnad skeleton components (`dugnad_feed_skeleton.dart`, `dugnad_subpage_skeletons.dart`)
- [x] Migrate top 6 dugnad screens off primary-bg spinners (points, missions, referral, career, team detail, supporter card)
- [x] Kampanje tab skeleton (header + list placeholders)
- [x] Apply skeleton pattern to remaining dugnad drill-downs (season recap, transfer window, donation, privacy, formen, points history)

### Phase 4 — Polish (optional)

- [x] Persist cache to prefs for cold dugnad start
- [x] Backend dugnad dashboard bundle endpoint (`GET sports-club/{id}/home-bundle`)
- [x] Prefetch cache on splash when dugnad route detected

---

## 10. Testing & regression guardrails

### Must not break (dugnad)

- Points totals after matkasse/campaign purchase
- Badge unlock after mission complete
- Referral attribution (`referral/capture`)
- Team selection + welcome bonus
- Pull-to-refresh on Hjem / Profil
- Logout → dugnad cache cleared
- Guest / logged-out dugnad paths
- Club switch → no stale data from previous club
- Mode switch commercial ↔ dugnad (cache must not leak across modes)

### Test matrix


| Flow                                   | Verify                                           |
| -------------------------------------- | ------------------------------------------------ |
| Cold start → dugnad Hjem               | Fast first paint; data matches after refresh     |
| Profil tab                             | Name/avatar instant; points update after earning |
| Switch club                            | No stale previous club                           |
| Kampanje → order → back                | Points refresh                                   |
| Toppliste tab                          | Rank matches Profil                              |
| Tab switch Hjem ↔ Kampanje ↔ Toppliste | No duplicate burst (check logs)                  |
| Slow / offline network                 | Stale data + retry; no blank screen              |
| Logout / other user                    | No cache leak                                    |


### Automated

- Unit tests: `DugnadDataCache` TTL, dedupe, invalidation, club-switch clear
- Widget test: dugnad profile header from prefs when network slow

---

## 11. Success metrics (dugnad)


| Metric                                | Baseline (fill in)     | Target                        |
| ------------------------------------- | ---------------------- | ----------------------------- |
| Cold start → dugnad Hjem interactive  | ~3 s+ splash + network | < 1.5 s perceived             |
| Profil tab → first content            | All APIs sequential    | < 300 ms first paint (cached) |
| Profil tab → full data                | Sum of 7 RTTs          | Max(RTT) via parallel + cache |
| API calls first 30 s (dugnad session) | ~20–35                 | < 12                          |
| Dugnad screens with full-page spinner | ~15                    | 0 (payment overlays only)     |


---

## 12. Benchmarks (fill after Phase 0)

```
Date:
Device:
Network:
Backend:
Mode: Dugnad only

Cold start → dugnad Hjem:
Profil tap → content visible:
Hjem API count (first open):
Profil API count (first open):
Total dugnad API calls (60 s session):
Tab switch Kampanje / Toppliste (duplicate calls?):
```

---

## 13. Key file index (dugnad)


| Area                 | Path                                                       |
| -------------------- | ---------------------------------------------------------- |
| Dugnad tab shell     | `lib/screens/common/homeMainV1/home_main_v1.dart`          |
| Hjem                 | `lib/screens/dugnad/dg_home.dart`                          |
| Profil shell         | `lib/screens/common/account/account.dart`                  |
| Profil body          | `lib/screens/dugnad/dugnad_profile_section.dart`           |
| Kampanje             | `lib/screens/dugnad/kampanje_screen.dart`                  |
| Toppliste            | `lib/screens/dugnad/leaderboard_screen.dart`               |
| Dugnad state (prefs) | `lib/screens/dugnad/dugnad_state.dart`                     |
| API repo             | `lib/screens/dugnad/dugnad_repo.dart`                      |
| Splash (delay only)  | `lib/screens/common/splash/splash_bloc.dart`               |
| Skeleton guide       | `lib/commonView/skeleton_loaders/SKELETON_LOADER_GUIDE.md` |


---

## 14. Recommended starting point

1. **Profile `Future.wait` + dedupe** — smallest diff, immediate latency win
2. **Remove splash 3 s timer** — faster dugnad entry
3. `**DugnadDataCache` + progressive profile** — stops duplicate tab fetches
4. **Lazy dugnad tabs in shell** — cuts cold-start API storm
5. **Skeleton migration** — fixes “stuck” feel without changing business logic

All phases preserve existing dugnad API contracts and user-visible outcomes; only **when** data loads and **how** loading is displayed changes. Commercial, feed, and AI codepaths are untouched.