**ÆREND**  
**Gamification & STØ System**

Complete Technical Specification

*App (Dugnad Custom) \+ Admin Panel (Hare-AdminPanel)*

Ai Logistics AS · Org.nr. 936 971 857

Version 1.0 — Consolidated source of truth

*Supersedes all prior gamification specs*

# **Contents**

# **1\. Overview & Purpose**

This document is the single, consolidated specification for Ærend's gamification and STØ supporter-card system. It replaces and supersedes all earlier gamification specs and master prompts. Where an earlier document conflicts with this one, this document wins.

Ærend is a Norwegian membership and supporter product operated by Ai Logistics AS. Users buy an Ærend membership and follow the local sports team they support. The product is built around the STØ supporter card — a season-based rating that grows as the user earns points.

## **1.1 Scope**

This spec covers two surfaces that must stay in lockstep:

* **Customer app** — the Flutter app (Dugnad Custom prototype is the design source of truth): how the mechanics are presented to end users.

* **Admin panel** — Hare-AdminPanel (Laravel 8): how each mechanic is configured, edited, and controlled by Ærend staff and, where relevant, per club/team.

Every configurable value described in the app section has a corresponding admin control described in the admin section. Nothing in the app should be hardcoded where this spec says it is configurable.

## **1.2 Product surfaces (context)**

| Repo | Stack | Role |
| :---- | :---- | :---- |
| Hare-Customer | Flutter | Customer app (STØ, membership, points) |
| Hare-AdminPanel | Laravel 8 | Admin/back-office \+ config API |
| rend-design-system | Design export | Canonical design reference |

# **2\. Compliance Foundation (read first)**

These constraints are not preferences. They shape the entire mechanic and override any feature goal. Every engineer working on this system must understand them, because a single misconfigured feature can break them.

## **2.1 Non-negotiable rules**

1. Points may be earned from activity, product purchases (campaigns/matkasser), and membership billing — but earned points are PERMANENT. No mechanism may ever remove, claw back, or reduce a user's points or rating because a membership is cancelled, paused, or a charge fails.

2. Cancelling or pausing a membership stops FUTURE earning only. It never reduces existing points, rating, badges, or standing. This preserves the written 'no lock-in, cancel anytime' commitment made to Vipps.

3. Membership points are a moderate baseline stream — activity and purchases must realistically be able to exceed pure membership earning, so rating is not simply 'who paid most'.

4. Badges are never lost — not on cancellation, pause, or season rollover (permanent badges) — see §7.

5. No mechanic may let users direct or allocate money to specific clubs. Ærend's support of clubs is Ærend's own sponsorship decision, separate from any individual user's payment.

| HARD ENFORCEMENT (admin) The admin panel must block any configuration that would withdraw points/rating on cancellation, pause, or failed charge. This is not an optional toggle — attempting to configure a clawback must be rejected with an explanatory warning. |
| :---- |

## **2.2 Why the leaderboard is the litmus test**

Because points drive rating, and rating drives leaderboard standing and prizes, the leaderboard is where any compliance mistake becomes most visible. A public ranking must never read as 'who pays the club the most'. Rankings are on STØ rating (activity-derived), never on payment or 'fast støtte'. See §9.

| LEGAL FLAG — not a Vipps question Cash-equivalent season prizes (e.g. gift cards) tied to a ranking that purchases can influence may fall under Norwegian lottery/marketing regulation. This is the domain of Lotteritilsynet / Forbrukertilsynet, NOT Vipps. A Vipps approval does not cover it. Legal review recommended before awarding cash-equivalent prizes tied to a purchase-influenced ranking. |
| :---- |

# **3\. Core STØ Model**

One clean loop drives the whole system:

6. Users farm POINTS through activity, product purchases, and membership billing.

7. Season points determine STØ RATING (40–99) via configurable thresholds.

8. Rating determines METAL TIER: Bronse / Sølv / Gull / Platina.

9. At SEASON END the card is archived to the user's career; season points reset down to a carryover head-start determined by the metal tier reached.

10. Next season, rating is re-earned from scratch (plus the carryover head-start).

## **3.1 Key definitions**

| Concept | Definition |
| :---- | :---- |
| Season points | Reset each season (down to carryover). Drive rating. |
| Lifetime points | Accumulate forever. Career total / history. Never reset. |
| STØ rating | 40–99. Derived from season points. Re-earned each season. |
| Metal tier | Bronse/Sølv/Gull/Platina — derived from rating thresholds. |
| Form | Tempo indicator only (how fast you're earning now). Does NOT drive rating. |
| Carryover | Point head-start into next season, set by end-of-season metal tier. |
| Club alias | Cosmetic display name for a tier (e.g. Sølv \= 'Sædalen-helt'). |

| CHANGED FROM EARLIER SPECS Form no longer drives rating — it is now a cosmetic tempo indicator. Any earlier 'form decay lowers rating' logic is void. Badges no longer add a separate capped rating component — they now grant a point bonus on unlock, which feeds rating through the normal points channel (see §7). Rating is derived from season points — not a sum of Grunnform+Form+Merker components. |
| :---- |

# **4\. Points System**

Points are the single currency. Everything that rewards the user grants points, and season points feed rating.

## **4.1 Point sources**

| Source | Trigger | Notes |
| :---- | :---- | :---- |
| Activity | Referral, participation, card share, login | Core farming. Activity-based. |
| Product purchase | Campaign / matkasse purchase | Commercial driver. A purchase is an action, not a subscription. |
| Membership billing | Successful monthly charge | Moderate baseline stream. Configurable per 100 kr. See §8. |
| Badge unlock | Unlocking a badge | One-off point bonus. See §7. |
| Missions & goals | Weekly challenges / season goals | Framed challenges over existing actions. See §6. |

## **4.2 Two counters**

* **Season points** — reset at season rollover (down to carryover). These drive rating.

* **Lifetime points** — accumulate forever; power the career total and history; never reset.

*Both counters use the platform's existing lifetime/season separation. Do not modify the counter calculation logic; new point sources plug in as configuration on the existing scoring.*

# **5\. Rating & Metal Tiers**

## **5.1 Points → rating mapping (configurable)**

Season points map to a 40–99 rating via configurable threshold points. Rating interpolates linearly between configured points (steps optional — see admin). Seed values:

| Season points | STØ rating | Resulting tier |
| :---- | :---- | :---- |
| 0 | 40 | Bronse (start) |
| 500 | 60 | Sølv |
| 1500 | 75 | Gull |
| 3000 | 90 | Platina |
| 5000+ | 99 | Platina (max) |

## **5.2 Metal tier thresholds (configurable)**

| Tier | Rating range |
| :---- | :---- |
| Bronse | 40–59 |
| Sølv | 60–74 |
| Gull | 75–89 |
| Platina | 90–99 |

*These tier ranges are the SAME source as the carryover tiers (§10). Nivå thresholds and carryover tiers must share one configuration, so they can never drift out of sync.*

## **5.3 Club tier aliases (cosmetic)**

Each club may define display names for the four tiers. Aliases are names only — never a separate system with its own thresholds. Example (Sædalen): Bronse \= 'Sædalen-supporter', Sølv \= 'Sædalen-helt', Gull \= 'Sædalen-legende', Platina \= 'Sædalen-ikon'. Empty alias → fall back to metal name. Aliases are frozen into history when a season card is archived, so an old card always shows the name that was true that season.

# **6\. Form, Weekly Challenges & Season Goals**

## **6.1 Form (tempo indicator)**

Form is a cosmetic ↑ → ↓ indicator of how fast the user is earning points right now. It is motivational only and does NOT affect rating. Form does not decay rating. Display it on the card and on the challenge screen as 'Tempo', with copy like 'Formen bygges av aktiviteten din i appen'.

## **6.2 The 'Ukens kamper' screen — split in two**

The screen is split into two clearly labelled sections. Both are framed challenges over EXISTING point-earning actions — they are not a new parallel action set. A weekly challenge to 'refer a friend' is a bonus framing over the referral that already grants points; it must reference the same activity tracking, never duplicate it.

### **Ukeskamper (weekly)**

* Streak card at top: 'X uker på rad med aktivitet' — one point-earning action per week keeps the streak.

* 2–4 rotating weekly challenges, each with title, short description, progress (e.g. 3/5), point reward, and a form/tempo marker.

* Reset weekly (e.g. Monday) with a countdown ('4 dager igjen').

### **Sesongmål (season-long)**

* Larger goals spanning the whole season, e.g. 'Fullfør en aktiv uke ×10', 'Kjøp 4 kampanjer i sesongen'.

* Title, description, progress bar, point reward, optional badge link (e.g. 'Sesongkriger').

## **6.3 Club/team scoping (both types)**

Weekly challenges and season goals are managed per club, with optional per-team override:

* **Club-level** (team\_id \= NULL) — inherited by all teams in the club.

* **Team-level** (team\_id set) — additional goals for that team only.

*Teams ADD their own goals; they do not override/hide inherited club goals (no holes in club goals). The app merges club goals \+ team goals into one list for the user's team.*

# **7\. Badges**

Two clearly separated types. Both grant a one-off point bonus on unlock (feeding rating via the normal points channel). There is no separate 'badge rating component' anymore.

## **7.1 Permanent badges (lifetime)**

* Earned once, kept forever, shown in history. Never lost — not on season rollover, pause, or cancellation.

* Include all tenure/membership-based badges (e.g. 'Veteran – 12 mnd') plus lasting milestones ('Første overgang', 'Hat-trick', 'Trofast').

## **7.2 Seasonal badges (renew each season)**

* Reset at season rollover and must be re-earned — this drives a fresh badge hunt each season.

* **Seasonal badges are built ONLY on activity and locality** (referrals, form, missions, club engagement) — never on pure tenure/membership.

* At season end they are archived (not deleted) into that season's achievements — moved from 'active' to the season shelf.

* If a seasonal badge has a membership angle, membership may only make it EASIER (a positive bonus), never a requirement. Non-members must also be able to earn it.

| ENFORCEMENT RULE (admin) A badge flagged as tenure/membership-triggered CANNOT be set to type 'seasonal' (reset). The admin must block this with a warning, because resetting a tenure badge would tie rating loss to lapsed payment. Only activity/locality badges may be seasonal. |
| :---- |

# **8\. Membership Points (points per 100 kr)**

Members earn points on each successful monthly charge. This is a moderate baseline stream, deliberately balanced so activity and purchases can exceed it.

## **8.1 Model**

* **Formula:** points \= (charged amount / 100\) × points\_per\_100 (rounding configurable).

* Awarded ONLY on an actually completed charge. Failed/missed charge grants nothing — and removes nothing.

* Membership points feed the same point total as activity points (drive rating and carryover on equal footing).

* **Cancellation/pause never removes earned points or rating** — only future earning stops. No clawback path may exist.

## **8.2 Balance intent**

Membership is a baseline, not the dominant path. An active free user should be able to compete with a passive payer. The admin balance-insight tool (see §13) exists specifically to keep this ratio healthy; points\_per\_100 must be tuned against real activity values, not set blindly.

| Seed value Suggested starting point: 10 points per 100 kr. Calibrate after observing real data. |
| :---- |

# **9\. Leaderboard**

The leaderboard ranks on STØ rating (rating-derived from points), with season points as tiebreak. It must never display a monetary 'value', 'markedsverdi', or 'fast støtte' framing, and must never rank on payment.

## **9.1 Display**

* Section title: 'STØ-rangering' (or 'Topplista'). Subtitle: 'Hvem har høyest STØ denne sesongen'.

* Ranking value shown per user is their STØ rating (e.g. 'STØ 93'); ties broken on season points. No kroner values anywhere.

* Keep: name, club alias/tier, kamper count, medals for top places, 'Hele klubben / Mitt lag' filter.

* Season-prize banner may remain — subject to the legal flag in §2.2.

# **10\. Season Rollover & Carryover**

## **10.1 Rollover order (ONE transactional job)**

Rollover must run as a single transactional operation, in this exact order. Archive BEFORE reset — reversing this destroys the user's season card permanently.

11. ARCHIVE — freeze the user's end-of-season card (rating, tier, club/team, permanent badges earned this season, seasonal badges achieved) into history.

12. CARRYOVER — compute the point head-start from the end-of-season metal tier.

13. RESET — reset season points down to the carryover head-start; reset seasonal badges (already archived in step 1).

14. RE-EARN — new season begins; rating rebuilds from points. Lifetime points and permanent badges untouched.

## **10.2 Carryover per metal tier (configurable)**

| End-of-season tier | Carryover points |
| :---- | :---- |
| Bronse | 100 |
| Sølv | 250 |
| Gull | 500 |
| Platina | 1000 |

| Deferred (document, do not build) Rating head-start carryover (carrying the rating value itself across seasons) — intentionally omitted to protect breadth and keep re-earning meaningful. Multi-team affiliation (one primary \+ additional teams) — data model must tolerate it later; no UI/logic now. Cup quiz (team-vs-team) — good idea, deferred to phase 2; keep prizes non-cash if built. |
| :---- |

# **11\. Career, History & Transfers**

## **11.1 'Karrieren din' (profile history)**

Replaces the running list of all card variants held during a season with a curated career view containing:

* Lifetime points — top anchor card ('Din totale poengsum'). Never resets.

* Permanent badge collection — with unlock dates; locked badges shown as silhouettes with requirements.

* Seasonal badge archive — which seasonal badges were achieved each season.

* Season card archive (FIFA-årganger) — one archived card per season: year, club \+ team followed that season (with small crest), final rating and tier. Format: 'Sesong 25/26 · Sædalen IL – Gutter 14 · STØ 82 (Gull)'.

* Affiliation timeline — from the transfer module, lives in the same section.

*Frozen history: club/team name AND tier alias are frozen at archival (stored as strings), so old cards never change if a club later renames a team or a tier alias. Source is the user\_team\_affiliations history table, using the affiliation active at the season end date.*

## **11.2 Transfers (team/club changes)**

Affiliation is a HISTORY table (user\_team\_affiliations: user\_id, team\_id, from\_date, to\_date). Rating, points, tier, and badges follow the user unchanged on transfer; only affiliation changes. Season counters reset for the new team; lifetime is untouched.

### **Anytime vs. window**

* **Transfers are allowed ANY TIME** via a profile entry ('Bytt lag eller klubb'). Users are never forced to wait for a window.

* **The transfer window is a season-end EVENT, not a lock** — it adds ceremony (Deadline Day countdown, 'Signert for' share card, transfer badges, club-feed visibility). Transfers outside the window work identically, just without the ceremony.

### **Flexible promotion (season end)**

A 'Ny sesong'-screen offers, not a yes/no, but options: 'Rykk opp med laget' (suggested if age-group mapping exists), 'Bli på samme trinn', 'Bytt til et annet lag i klubben', 'Bytt klubb' (full ceremony), 'Ikke nå'. All show: rating/points/tier follow you; season counters reset for the new team.

# **12\. Admin Panel — Control Surface**

Every mechanic above is configured here. The admin panel is Hare-AdminPanel (Laravel 8). All work follows the repo conventions below.

## **12.1 Conventions (non-negotiable)**

* Match the existing design system exactly (rend-design-system is the source of truth). Zero design drift.

* All migrations additive (new tables/columns only — no drops, no destructive renames). Deprecate in comments, never hard-delete.

* Reuse existing service methods by name (e.g. MediaStorageService). Do not duplicate logic.

* **Do NOT modify PointsEngine / CampaignService / DonationFeeService core logic.** All new mechanics plug in as configuration on the existing config-driven scoring.

* Norwegian for user-facing strings; English for code and comments.

* Report per chunk: files changed, migrations added, routes added, one cross-check. Do not run full builds; make edits and report changes — Didrik runs builds/tests in batches.

* Never run flutter analyze on the Flutter side; do not run a full APK build per chunk.

## **12.2 Admin sections (Gamification \+ per-club)**

| Admin area | Controls | Spec ref |
| :---- | :---- | :---- |
| STØ-terskler | Points→rating mapping (interpolated); tier ranges (shared w/ carryover) | §5, §13.A |
| Carryover | Carryover points per metal tier | §10, §13.B |
| Medlemspoeng | Points per 100 kr, rounding, balance-insight | §8, §13.C |
| Merker | Badge CRUD, type (permanent/seasonal), trigger\_class, point bonus | §7, §13.D |
| Ukeskamper | Weekly challenge CRUD, rotation, streak config | §6, §13.E |
| Sesongmål | Season goal CRUD (per club/team, inheritance) | §6, §13.E |
| Nivå-titler | Per-club tier aliases | §5.3, §13.F |
| Topplista | Ranking metric (STØ), filters, season link | §9, §13.G |
| Feature flags | Master on/off per module | §13.H |

# **13\. Admin — Build Chunks**

Each chunk is independently scoped. Seasons table (from prior gamification work) must exist before rollover-dependent chunks (B carryover, and the rollover job). Build order suggestion at §15.

## **Chunk A — Rating thresholds**

* **Migration:** sto\_rating\_thresholds (points\_required, rating\_value, enabled). Seed 0→40, 500→60, 1500→75, 3000→90, 5000→99.

* Tier ranges live in sto\_tier\_thresholds (40–59/60–74/75–89/90–99), shared with carryover — one source for metal boundaries.

* UI: edit points→rating points; validate (increasing points, increasing rating, covers 40–99). Read-only curve preview. Linear interpolation between points (configurable/documented).

* **Cross-check:** thresholds served via config API without altering existing payload; app reads at startup.

## **Chunk B — Carryover**

* **Migration:** metal\_carryover\_config (tier\_key, carryover\_points, enabled). Seed 100/250/500/1000.

* UI: edit carryover points per tier; validation (non-negative; recommend increasing with tier, warn if not). Read-only simulator: pick end tier → carryover points.

## **Chunk C — Membership points**

* **Migration:** membership\_points\_config (points\_per\_100\_kr, rounding\_mode, enabled, updated\_by). Seed 10\.

* Award logic hooks the EXISTING successful-charge event. No award on failed/missed charge. Register as a point config-entry in existing scoring.

* **Enforce:** no clawback path may exist; block any config that withdraws points on cancel/pause/failed charge, with warning.

* Balance-insight (read-only): 'A member at 200 kr/mnd earns \~X pts/mnd; typical activity/purchase earns \~Y'. Simulator: amount → points.

## **Chunk D — Badges**

* **Migration:** extend badge table: badge\_type (permanent|seasonal), trigger\_class (activity|locality|tenure), point\_bonus, season\_id nullable. user\_seasonal\_badges (user\_id, season\_id, badge\_id, earned\_at).

* **Enforce:** if trigger\_class \= tenure, force badge\_type \= permanent and block 'seasonal'. Only activity/locality can be seasonal.

* Badge unlock grants point\_bonus via normal points channel (no separate rating component).

## **Chunk E — Weekly challenges & season goals**

* **Migrations:** weekly\_challenges and season\_goals (both: org\_id, team\_id nullable, title\_no, description\_no, type, goal\_count, reward\_points, badge\_id nullable, active\_from/to, enabled, sort\_order; weekly adds rotation manual|auto). streak\_config.

* Placement: per-club (org workspace) with team override in team workspace (inherited club items read-only \+ team items editable).

* **Rule:** challenge/goal types reference EXISTING activity keys — never new duplicate actions. Rewards register as config-entries in existing scoring.

## **Chunk F — Tier aliases**

* **Migration:** club\_tier\_aliases (club\_id, tier\_key, alias\_name\_no, enabled). Aliases reference tier\_key only — NO thresholds here.

* Per-club editor for the four aliases (optional; empty → metal name). Frozen into season\_card\_archive at rollover.

## **Chunk G — Leaderboard**

* Change ranking source from any monetary/value metric to STØ rating (primary) \+ season points (tiebreak). Deprecate any market\_value ranking source (do not hard-delete).

* **Cross-check:** ranks on STØ rating; no kroner value exposed via config API.

## **Chunk H — Feature flags**

* **Migration:** gamification\_features (feature\_key, enabled, config\_json, updated\_by). Flags: form\_enabled, streaks\_enabled, season\_goals\_enabled, membership\_points\_enabled, weekly\_challenges\_enabled, transfer\_window\_enabled.

* Exposed via existing app-config endpoint so Flutter reads at startup, without altering existing payload structure.

## **Chunk I — Season rollover job**

* **Migrations:** season\_card\_archive (user\_id, season\_id, final\_rating, final\_tier, club\_name\_frozen, team\_name\_frozen, tier\_alias\_frozen, snapshot\_json, archived\_at). Audit column for applied\_carryover.

* **One transactional job:** archive → carryover → reset (points \+ seasonal badges) → re-earn. ARCHIVE BEFORE RESET (critical). Bound to seasons table.

* Frozen values sourced from user\_team\_affiliations at season end date.

# **14\. Data Model Summary (new/extended tables)**

| Table | Purpose | Additive? |
| :---- | :---- | :---- |
| sto\_rating\_thresholds | Points → rating mapping | New |
| sto\_tier\_thresholds | Rating → metal tier (shared w/ carryover) | New/existing |
| metal\_carryover\_config | Carryover points per tier | New |
| membership\_points\_config | Points per 100 kr | New |
| (badge table) \+cols | badge\_type, trigger\_class, point\_bonus, season\_id | Extend |
| user\_seasonal\_badges | Seasonal badges earned per season | New |
| weekly\_challenges | Weekly challenges (club/team) | New |
| season\_goals | Season goals (club/team, inheritance) | New |
| streak\_config | Streak definition \+ bonuses | New |
| club\_tier\_aliases | Per-club tier display names | New |
| season\_card\_archive | Frozen end-of-season cards | New |
| user\_team\_affiliations | Affiliation history (from transfers) | New/existing |
| gamification\_features | Feature flags | New |

*All migrations additive. Deprecated tables (e.g. old missions/mission\_templates, market\_value ranking source) are commented as deprecated, not dropped.*

# **15\. Build Order & Config API**

## **15.1 Suggested order**

15. Seasons table (prerequisite for rollover, carryover, goals) — confirm it exists first.

16. Chunk H (feature flags) — so everything can be toggled off safely.

17. Chunk A (rating thresholds) \+ Chunk B (carryover) — core rating loop.

18. Chunk D (badges), Chunk F (aliases) — independent.

19. Chunk E (challenges/goals) \+ Chunk C (membership points) — point sources.

20. Chunk G (leaderboard) — depends on rating being live.

21. Chunk I (rollover job) — last; ties archive+carryover+reset together.

## **15.2 Config API**

All configurable values (rating thresholds, tier ranges, carryover, membership points, aliases, challenges, goals, streak config, flags) are exposed through the existing config endpoint pattern. The Flutter app reads them at startup. Never change the existing payload structure — add to it.

## **15.3 Handoff doc**

Update DUGNAD\_BUILD\_HANDOFF.md with: the consolidated model; form demoted to tempo indicator; badges grant point bonus (no separate rating component); membership points as configurable baseline with no clawback; leaderboard rebased to STØ; deprecations (old missions tables, market\_value source); and the deferred list (rating carryover, multi-team, cup quiz). No individual names in the doc.

# **16\. Open Items & Flags for Didrik**

| Requires action outside engineering 1\. Legal review of prizes. Cash-equivalent prizes tied to a ranking that purchases can influence may fall under lottery/marketing law (Lotteritilsynet/Forbrukertilsynet) — not covered by any Vipps approval. 2\. Balance calibration. Set points\_per\_100 against real activity values using the balance-insight tool, so membership stays a baseline and not the dominant path to rating. 3\. Consistency of recruitment. Any landing pages / club messaging must match the membership framing the app now uses (not 'give to your club'). 4\. Cross-surface truth. The app now states membership points are earned on billing and never clawed back — the backend award/clawback behaviour must match this exactly. |
| :---- |

