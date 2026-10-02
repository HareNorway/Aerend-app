# Ærend — Points System: Technical Specification

Version 2.0 · September 2026 · Status: for implementation review
Supersedes v1.0 and is complete on its own. Adds the four-tier **Nivå** system. Replaces the rewards layer in the customer-app rewards brief (Ærend-kroner, varder, Syv fjell, store stamp cards, Bydelsligaen). Companion to the Order Operations Platform spec v3.1 and the Ægil agent spec v2.0; uses their definitions of events, policy keys, the agent layer and the panel.

---

## 0. Scope and principles

One points system for the customer app, with tiers, fully visible and controllable in the admin panel.

1. **One currency:** Ærend-poeng, earned by shopping and activity, redeemed **only for prizes**. Never converted to cash, credit or a discount amount. No second currency.
2. **Five ways to earn, and no others** (§1). Every rate is a policy key, editable in the panel with version history.
3. **Four tiers, named after Bergen's mountains:** Fløyen · Løvstakken · Rundemanen · Ulriken. A tier decides **which prizes are on your shelf**, and nothing else: no earning multipliers, no fees, no other benefits. Simplicity is the feature.
4. **Tier is based on points *earned*, never on balance.** Spending points can never lower a tier. This is stated in the app, because otherwise people hoard and the shelf dies.
5. **Three surfaces:** earning feeds the monthly **Fløyen-ligaen** and the tier; spending happens on the **Premiehylla**; the balance is the one number the user tracks.
6. **Ægil communicates the system** and chooses the weekly mission, the welcome gift and the surprise prize within rules. Ægil never invents points, prices, prizes or tiers.
7. **The panel sees everything:** every point issued, spent, expired or revoked with its reason; liability at expected cost; every prize, claim and fulfilment; every tier change; every mission and league month; every fraud flag.
8. **Honesty:** no countdowns, no "du går glipp av", no demotion without warning, no prize shown as claimable that is not, no rate or threshold that is not stated on "Slik får du poeng".

---

## 1. Earning rules (rates set now)

| Rule | Key | Rate | Trigger | Notes |
|---|---|---|---|---|
| Kjøp | `points.purchase_per_10kr` | 1 point per 10 kr | `order.delivered` | Base = order subtotal excluding delivery fee, tips and prize-voucher value; rounded down per order. `pending` from `placed`, `available` at `delivered`; cancellation or full refund voids; partial refund recomputes. |
| Dagens napp | `points.daily_catch` | 5 | the user reels in a float in Vågen (`suggestion.reeled`), or taps Ægil's daily line when no float exists | Once per calendar day (Europe/Oslo). No streak, no penalty for skipping. |
| Verving | `points.referral_each` | 200 to referrer and 200 to the friend | the friend's first order `delivered` with subtotal ≥ `points.referral_min_order` (150 kr) | Existing referral integrity rules; `points.referral_monthly_cap` = 10 rewards. |
| Første gang | `points.first_time` | 50 | first `delivered` order in a category never ordered from, and separately with a store never ordered from | `points.first_time_monthly_cap` = 5 per month. |
| Ægils oppdrag | `points.mission_min` / `points.mission_max` | 20–100 | mission completion (§6) | One active mission; weekly. |

**League counting cap:** `league.order_points_cap` = 200 points per order count toward the league; the balance and the tier receive the full amount.
**Expiry:** each batch expires 12 months after becoming available (`points.expiry_months` = 12), FIFO on spend; one reminder 30 days before the first expiring batch above 50 points. Expiry does not affect the tier (§3.2).

---

## 2. Ledger

```
points_ledger (id, customer_id, delta, kind earn|spend|expire|revoke|adjust, source purchase|daily_catch|referral|first_time|mission|league_prize|tier_gift|panel,
               reference_type, reference_id, state pending|available|void, available_at, expires_at, batch_id,
               policy_version, agent_run_id?, created_at)
points_balances (customer_id, available, pending, lifetime_earned, earned_12m, expired, lifetime_spent, updated_at)  -- projection, rebuildable
```
Append-only; balances are rebuilt from the ledger on demand ("Rebuild balance" in the panel). Spend consumes oldest available batches first. `revoke` from refund and fraud jobs with a reason; `adjust` only from the panel with a reason and an approver. Every row carries the policy version that produced it.

`earned_12m` = Σ `earn` rows with `available_at` in the last 365 days, excluding `tier_gift` and `league_prize` (gifts must not lift a tier). This is the tier basis.

---

## 3. Nivå (tiers)

### 3.1 The four tiers

| Tier | Key | Threshold (`earned_12m`) | What its band adds to the shelf |
|---|---|---|---|
| **Fløyen** | `floyen` | 0 | Free delivery, sticker pack, Forundringspose, club donation |
| **Løvstakken** | `lovstakken` | 1 000 | Partner goods: a store's dish or product (pizza, prawns, pastries), Ægil velger |
| **Rundemanen** | `rundemanen` | 3 000 | Experiences: Fløibanen return, dinner for two, early access to new stores |
| **Ulriken** | `ulriken` | 8 000 | Things money cannot buy: chef's table on Bryggen, dinner on Ulriken, and **your own boat in Vågen** — a named boat rendered in the Hjem window |

Thresholds are policy keys (`tier.threshold.*`) with version history. A tier opens its own band **and every band below it**; nothing is ever removed from a lower band.

### 3.2 Tier engine
```
customer_tiers (customer_id, tier, since, source threshold|review|panel, earned_12m_at_change, next_review_at, protected_until?)
tier_events (id, customer_id, from_tier, to_tier, kind promotion|demotion|hold|panel, earned_12m, reason, created_at)
```
- **Promotion is immediate:** when `earned_12m` crosses a threshold, the tier rises at once and `tier.promoted` fires (§7.4).
- **Demotion only at the annual review.** `next_review_at` = the customer's tier anniversary. At review, if `earned_12m` is below the current threshold, the customer drops **at most one tier**; a drop of two or more is capped at one. `tier.hold` is written when the customer stays.
- **Warning, once:** 60 days before the review, if `earned_12m` is below the threshold, `tier.review_warning` fires with the gap in points, and the mission engine prefers a mission that closes it. One notification, no countdown, no repetition.
- **Spending never affects the tier.** Expiry does not either: `earned_12m` counts when points were earned, not whether they still exist.
- **Protection:** `protected_until` can be set from the panel (support goodwill, a data issue) and is audited.

### 3.3 Welcome gift on promotion
On `tier.promoted`, the customer receives one prize from the new band, chosen by Ægil from a configured welcome pool (`tier_welcome_pool (tier, prize_id, active)`), granted as a claim with points cost 0 and ledger row `tier_gift` (0 delta, recorded for audit). It is endowed progress: the new tier starts with something in hand. One gift per promotion, never on hold or demotion.

---

## 4. Premiehylla (the prize shelf)

### 4.1 Catalogue
```
prizes (id, tier_band floyen|lovstakken|rundemanen|ulriken, type free_delivery|forundringspose|sticker_pack|partner_item|partner_experience|aegil_velger|donation|identity,
        title, teaser, description, image_id, point_price, funding aerend|partner, partner_store_id?, partner_terms JSON,
        estimated_cost_kr, value_floor_kr?, inventory_total?, inventory_left?, monthly_cap?, window_start, window_end,
        state draft|live|paused|ended, fulfilment voucher|partner_code|shipment|donation|surprise|identity,
        shelf_position, created_by, approved_by?, created_at)
```
- Point prices set now (editable): **Fløyen band** — Gratis levering 100 · Ægil-klistremerkepakke 150 · Forundringspose 250 · Gi 100 kr til en lokal klubb 500. **Løvstakken** — Reker 500 g fra Torgboden 300 · Ægil velger 300 · Gratis pizza fra Casa Maria 400. **Rundemanen** — Fløibanen tur-retur 600 · Middag for to på Bryggen 1 500 · Tidlig tilgang til nye butikker 400. **Ulriken** — Kokkens bord på Bryggen 2 500 · Middag på Ulriken 3 000 · Din egen båt i Vågen 2 000.
- `estimated_cost_kr` is required on every prize and drives the liability estimate; `identity` prizes (the boat) have cost 0 and no fulfilment queue.
- The shelf shows 8–12 live prizes from the customer's open bands plus **locked previews** (§4.2). Gratis levering is always live.

### 4.2 Locked previews
Prizes in bands above the customer's tier are shown, not hidden: image blurred, title readable, `teaser` as one concrete line, the point price visible, and the requirement in plain words: "Fra Rundemanen · 2 400 poeng til". No padlock icon, no "låst opp" wording, no claim button. Tapping opens a sheet explaining the tier, its band, and how far away it is. At most three locked previews at a time, the nearest band first; the intention is curiosity with facts, not frustration.

### 4.3 Claims and fulfilment
```
prize_claims (id, customer_id, prize_id, points_spent, tier_at_claim, state claimed|applied|shipped|delivered|used|expired|cancelled,
              fulfilment_ref, claim_expires_at, created_at, decided_at)
```
Claiming spends points immediately and creates a claim; the tier is checked at claim time (`422 PRIZE_TIER_LOCKED` otherwise). `voucher` applies automatically at the next eligible checkout (`orders.prize_claim_id`, line "Premie: gratis levering"); `partner_code` shows a code; `shipment` enters the fulfilment queue; `donation` accrues to a club ledger paid monthly by finance; `surprise` per §5; `identity` (the boat) is applied to the customer's Hjem scene with a name the customer chooses, reviewed against a name filter. Claims expire after `prizes.claim_validity_days` (60), stated at claim time; cancellation within 24 h before fulfilment refunds the points.

### 4.4 The goal
```
point_goals (customer_id, target_type prize|tier, prize_id?, tier?, set_by user|aegil, set_at, reached_at?, cleared_at?)
```
One goal per customer: a prize (including a locked one, which then shows both the points and the tier gap) or the next tier. Ægil proposes one from memory; progress is `available / point_price` for a prize and `earned_12m / threshold` for a tier.

---

## 5. Ægil velger (the surprise prize)

Selection, not chance; legal review against lotteriloven is an open decision (§14) and the design must add no element of chance.
- Pool `surprise_pool (prize_id, tier_band, active)`; only prizes with `estimated_cost_kr ≥ value_floor_kr` (`aegil_velger.value_floor_kr` = 300). The pool is filtered to the customer's open bands, so a higher tier makes the surprise better — the tier's effect is on quality, never on odds.
- Deterministic scoring in code (fit to stated preferences and confirmed patterns, novelty against prizes already received, availability); the agent breaks ties among the top three and writes one reason, stored and shown after the reveal.
- The customer cannot choose or swap; the value floor is stated before claiming. The reveal is the gamified moment (design brief).

---

## 6. Ægils oppdrag (missions)
```
mission_templates (id, type try_store|try_category|order_before_time|order_on_weekday|use_pickup|forundringspose|repeat_store, params_schema, points, tier_hint?, active)
business_goals (id, type quiet_hours|new_store|category_growth|pickup_share, store_id?, category_id?, weekday?, hours?, weight, window)
missions (id, customer_id, template_id, params JSON, points, state proposed|active|declined|completed|expired, wording, agent_run_id?, week, created_at, completed_at)
```
Weekly job builds candidates from `business_goals × memory` (excluding allergen conflicts and excluded stores), scores them, and `agent.aegil_customer` picks and words one. When `tier.review_warning` is active, the engine prefers a mission whose points close the gap. One active mission; one decline per week; completion detected from events.

---

## 7. Fløyen-ligaen and tiers together

```
league_months (id, month, city, state open|closing|closed, prizes JSON, closed_at)
league_entries (league_month_id, customer_id, display_name, strok, opt_in_at, points_counted, rank?, prize_id?, excluded bool, excluded_reason?)
```
- Monthly, opt-in, ranked by `points_counted` (earned this month, with the per-order cap), ties by time reached. Top 10 plus own rank and distance; a "Din bydel" filter inside the same league.
- The league is **tier-blind**: everyone competes on the month's activity, so a new customer can win. Tier prizes and league prizes are separate; league prizes are assigned from the catalogue regardless of the winner's tier.
- Month-end: freeze, exclude fraud-flagged entries, assign top-3 prizes and `league.top10_points` = 100 to the top ten, create claims, notify. A customer may win a top-3 prize at most twice a year.

---

## 8. Ægil communication (events → lines)

| Event | Where | Line |
|---|---|---|
| `points.earned` (purchase) | Levert, Varsler | "+34 poeng. 12 fra 6. plass." (league distance only when opted in) |
| `points.earned` (daily catch) | window | "Dagens napp: +5" |
| `points.earned` (referral) | Varsler, push | "Kari kom til kai · +200 poeng" |
| `points.earned` (first time) | Levert | "+50 poeng · første gang hos Torgboden" |
| `goal.near` | window, Varsler | "Én bestilling til, så er pizzaen din." |
| `goal.reached` | Meg, Varsler | "Pizzaen er din. Hent premien." |
| `tier.promoted` | full-screen moment, Varsler, push | "Du er på Rundemanen. Her er noe til deg." with the welcome gift |
| `tier.review_warning` | Varsler, one push | "Du er 400 poeng fra å bli på Rundemanen ut året." with the mission |
| `tier.demoted` | Varsler | "Du er på Løvstakken nå. Premiene fra Rundemanen venter på deg." |
| `points.expiring` | Varsler, one push | "120 poeng utløper 3. desember." |
| `mission.proposed` | Meg, Varsler | the mission wording |
| `league.month_closed` | Varsler, push | rank and prize |
| monthly summary (1st) | Meg card, Varsler | points earned, tier and distance to the next, rank, best mission, the savings line |
| "Hvordan får jeg poeng?" | chat | the five earning lines and the four tiers with thresholds, nothing more |

Lines are templates rendered from events; the agent may vary wording within the copy rules; pushes respect caps and quiet hours.

---

## 9. Admin panel (full visibility)

1. **Dashboard:** issued, spent, expired, revoked by source and by tier; active balances; **liability** = outstanding points × expected redemption × average cost per point, with the breakage assumption editable and its history; distribution of customers per tier; points per order and per customer.
2. **Ledger:** search by customer, order, source, tier, date; row detail with reason, policy version and agent run; balance rebuild; `adjust` with reason and second approver above `panel.adjust_limit`.
3. **Regler og satser:** every `points.*`, `tier.*`, `league.*`, `aegil_velger.*` key with version history, effective-from and a simulation ("if Rundemanen becomes 3 500, X % of customers move").
4. **Nivå:** thresholds; customers per tier over time; promotions, holds and demotions with reasons; review queue for the next 30 days; `protected_until` overrides with audit; welcome-pool management per tier; the annual-review dry run.
5. **Premiehylla:** catalogue CRUD with band, state, window, inventory, caps, funding, partner, estimated cost; shelf ordering; live preview as each tier sees it (including locked previews); claims by prize and by tier; fulfilment queues (shipments with addresses and labels, partner codes, donations ledger, identity prizes awaiting name review); realised vs estimated cost per prize.
6. **Ægil velger:** pool per band, value-floor compliance, selection audit per claim, outcome distribution, kill switch.
7. **Oppdrag:** templates and points, business goals with weights, active missions, completion and decline rates by template, wording samples, kill switch.
8. **Liga:** live standings, opt-ins, fraud exclusions, month-end dry run and run, winners history, the twice-a-year rule.
9. **Svindel og avvik:** referral rings, self-referral, velocity anomalies, daily-catch abuse, mission farming, tier-threshold gaming; rules detect, `agent.anomaly_explain` explains; actions: revoke with reason, exclude from league, freeze tier, suspend earning.
10. **Alerts:** issuance above forecast, liability above threshold, prize inventory below 10 %, fulfilment older than 3 days, month-end or annual-review job failure, fraud spike, an unusual number of promotions in a day.

---

## 10. Partner: Tilby en premie
In Partner → Butikk, a store proposes a prize: item or experience, quantity, window, suggested point price, suggested band, terms note. The panel approves, sets the band and the price, and makes it live. The store sees redemptions, new customers from the prize and cost. Partner prizes are ordered through the normal order path with a 0-kr line and `prize_claim_id`; settlement and VAT follow the finance decision (§14).

---

## 11. Removal and migration
Removed from the customer app: Ærend-kroner and cashback lines, varder and Din sti, Syv fjell, store stamp cards, Bydelsligaen, "Ekte bergenser", "butikker støttet", "fjell tent", the separate trust-ledger card (its savings line moves into the monthly summary). Referral rewards become points. Any kroner balance at launch converts once at `migration.kr_to_points` (proposed 3 points per kr) with a ledger row and a Varsler item. At launch every customer starts on Fløyen; `earned_12m` is seeded from the last 12 months of delivered orders at the current purchase rate so long-standing customers are not placed at the bottom.

---

## 12. APIs, events, jobs

**Customer:** `GET /me/points` (balance, pending, expiring, tier, earned_12m, distance to next tier, goal, league opt-in) · `GET /me/points/ledger` · `GET /me/points/rules` (rates and thresholds) · `GET /me/tier` (tier, since, next review, gap) · `GET /prizes` (open bands with claimability plus locked previews) · `POST /prizes/{id}/claim` · `POST /prize_claims/{id}/cancel` · `GET /me/prize_claims` · `POST /me/points/goal {prize|tier}` · `DELETE /me/points/goal` · `GET /me/missions/current` · `POST /me/missions/{id}/accept|decline` · `POST /league/opt_in` · `DELETE /league/opt_in` · `GET /league/{month}` · `POST /me/daily_catch` (idempotent per day) · `POST /me/boat_name` (identity prize).
**Partner:** `POST /stores/{id}/prize_offers` · `GET /stores/{id}/prize_offers` · `GET /stores/{id}/prize_redemptions`.
**Panel:** `/panel/points/*`, `/panel/tiers/*`, `/panel/prizes/*`, `/panel/missions/*`, `/panel/league/*`, `/panel/surprise/*` for everything in §9.

**Events:** `points.earned|pending|voided|spent|expired|revoked|adjusted` · `tier.promoted|hold|demoted|review_warning|protected` · `goal.set|near|reached|cleared` · `prize.claimed|applied|shipped|used|expired|cancelled` · `surprise.selected|revealed` · `mission.proposed|accepted|declined|completed|expired` · `league.opted_in|month_closed|prize_assigned` · `daily_catch.earned`.

**Jobs:** `points_release` · `points_expire` (daily, FIFO) · `expiry_reminders` · `tier_evaluate` (on every earn; promotion immediate) · `tier_review` (daily, per anniversary, with a dry run) · `tier_review_warnings` (daily, 60-day horizon) · `missions_weekly` (Mon 06:00) · `league_month_end` (1st 03:00, dry run 02:00) · `monthly_summary` (1st 07:00) · `liability_snapshot` (daily) · `fulfilment_queue_sla` (hourly).

---

## 13. Metrics
Issuance and redemption by source and tier; redemption rate and breakage; realised cost per point; tier distribution and movement (promotions, holds, demotions); retention and order frequency by tier, and the delta around a promotion; goal set rate and time-to-goal; claim conversion by prize and by band; locked-preview taps → tier-goal set rate (does curiosity convert?); Ægil velger feedback and distribution; mission accept and completion by template; league opt-in and retention delta; daily-catch share of DAU; referral conversion with points; fraud revocations and tier freezes.

## 14. Open decisions (business and legal)
Legal review of Ægil velger and Forundringspose against lotteriloven; VAT and settlement for partner-funded prizes; partner compensation terms; league and tier terms text; sticker-pack fulfilment partner; donation recipients and payout cadence; the kroner-to-points migration factor; whether the twice-a-year winner rule covers top 3 or top 10; the boat-name filter and review process; whether tier thresholds differ by city when Ærend expands.

## 15. Rollout
**P1** ledger, earning rules, balances, panel dashboard and ledger (no user-facing spend).
**P2** Premiehylla with Ærend-funded prizes, goal, Ægil lines, the new Meg.
**P3** tiers: engine, `earned_12m` seeding, bands, locked previews, promotion moment and welcome gift, panel Nivå view. Annual review and warnings ship in the same phase but only take effect after the first anniversary.
**P4** partner prizes and Partner offers.
**P5** missions.
**P6** league.
**P7** Ægil velger after legal review; Ulriken identity prizes (the boat) last.
Each phase behind flags with its own handoff document; the system runs fully with the agent off.
