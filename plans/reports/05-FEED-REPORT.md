# Ærend feed — how posts are created, moderated, ranked and shown, across every app

> **Audience:** developers on the Ærend team (Flutter, Laravel, Node) · **As of:** 2026-10-02 · **Report 5 of 5** (the FEED report)
>
> **Repos and `agil-1` tips read:** `Aerend-Feed` `d1f7a2f` · `Hare-AdminPanel` `ec1dfe8` · `aerend-app/Aerend-app` `824c478` · `Hare-Store` `6ce38b3` · `Hare-Driver` `a71b33e` (not involved in the feed).
>
> **Sources read:** `Aerend-Feed/docs/` (ARCHITECTURE, FEED_SYSTEM, FEED_MASTER_PLAN, FEED_LAUNCH_PLAN, FEED_HANDOVER_10DAYS, LOCAL_DEV), `Aerend-Feed/README.md`, every file under `Aerend-Feed/src/`, `scripts/`, `drizzle/`, `do-app-platform.yaml`, `Dockerfile`, `docker-compose*.yml`, `.env.example`, `.env.local.example`. Specs `aerendvstore feed update spec.md`, `AEREND ORDER OPS SPEC FINAL STATEv3.md` §16 / §17.7 X1 / §18.7, `AEREND AEGIL AGENT SPEC FINAL VERSION.md` §5, `aerend-support-refunds-feed-spec.docx` §4–§6. Plans `AGIL-1-PLAN.md` Phases 8–9, `AGIL-1-PLAN-v2.md` Phase 2, `AGIL-1-REMAINING.md` §3/§5, `AGIL-CONTRACT.md`, `AGIL-UI-CONTRACT.md`, `8-10-WEEK-IMPLEMENTATION-PLAN.md` Phases 7.5 and 8.1–8.3. Admin docs `FEED_JWT_KEYS.md`, `EVENT_CONTRACT.md`, `OPS_API.md`, `OPS_ADMIN_GUIDE.md`, `OPS_ROLLBACK.md`. Designs `Ærend leveranse 6 - Feed.dc.html`, the Utforsk section of `Ærend Kunde Bergen.dc.html`, the Butikk/feed section of `Ærend Partner.dc.html`, and `designs/21des/admin/*.jsx`.

> [!WARNING]
> **`Aerend-Feed` branch `master` auto-deploys to production.** `do-app-platform.yaml` sets `deploy_on_push: true` on `master` for the `api`, `store-sync-worker` and `notification-worker` components, and runs `node dist/migrate.js` as a `PRE_DEPLOY` job. A merge or push to `master` ships code **and** runs migrations against the production Postgres, with no gate. Work on `agil-1`. Never run `npm run db:migrate:prod` by hand.

---

## Table of contents

- [0. How to read this report](#0-how-to-read-this-report)
- [1. TL;DR](#1-tldr)
- [2. System context](#2-system-context)
- [3. The feed service (Aerend-Feed): architecture and deployment](#3-the-feed-service-aerend-feed-architecture-and-deployment)
- [4. Identity: feed JWT minted by Laravel, verified by JWKS](#4-identity-feed-jwt-minted-by-laravel-verified-by-jwks)
- [5. Data model and the post lifecycle (innleggets livssyklus)](#5-data-model-and-the-post-lifecycle-innleggets-livssyklus)
- [6. Store publishing (Butikk-innlegg)](#6-store-publishing-butikk-innlegg)
- [7. Ærend composer, scheduling and expiry (Fra Ærend)](#7-ærend-composer-scheduling-and-expiry-fra-ærend)
- [8. Moderation and publishing eligibility (Moderering)](#8-moderation-and-publishing-eligibility-moderering)
- [9. Reading the feed: tabs, ranking and the mix rule (I nærheten / Følger / Fra Ærend)](#9-reading-the-feed-tabs-ranking-and-the-mix-rule-i-nærheten--følger--fra-ærend)
- [10. Social features: follows, likes, comments, stories, search, CTA (Følg, Historier)](#10-social-features-follows-likes-comments-stories-search-cta-følg-historier)
- [11. Media: Cloudinary direct upload](#11-media-cloudinary-direct-upload)
- [12. Push notifications (FCM)](#12-push-notifications-fcm)
- [13. Store sync from Laravel](#13-store-sync-from-laravel)
- [14. Event bridge and Ægil signals](#14-event-bridge-and-ægil-signals)
- [15. Entry point: customer app — Utforsk → Feed](#15-entry-point-customer-app--utforsk--feed)
- [16. Entry point: store app (Partner / Hare-Store)](#16-entry-point-store-app-partner--hare-store)
- [17. Entry point: admin panel](#17-entry-point-admin-panel)
- [18. Entry point: Ægil (agent signals)](#18-entry-point-ægil-agent-signals)
- [19. How the other apps/services interact with this one](#19-how-the-other-appsservices-interact-with-this-one)
- [20. GAP analysis](#20-gap-analysis)
- [21. Configuration, flags and environment](#21-configuration-flags-and-environment)
- [22. Developer quick-start / where to look first](#22-developer-quick-start--where-to-look-first)
- [23. Glossary](#23-glossary)
- [Appendix: source index](#appendix-source-index)

---

## 0. How to read this report

**Status legend** (used in feature sections and the GAP table):

| Mark | Meaning |
|---|---|
| ✅ Built | Code exists on `agil-1`, is reachable from a real entry point, and I opened it |
| 🟡 Partial | Some of the requirement exists, or it exists but nothing reaches it |
| ❌ Not built | No code found (the grep terms are named) |
| 🧪 Stub/mock only | Exists only as a fixture, test double, prototype or placeholder |
| ⛔ Blocked | Waiting on a business decision or something outside the code |

**"Spec says / code does / design shows"** are kept apart on purpose. A `[x]` in a plan is reported as a claim; the status always comes from the code.

**Link conventions.** The report lives in `aerend-app/Aerend-app/plans/reports/`. Links are relative:

| Target | Prefix |
|---|---|
| Customer app | `../../lib/...`, `../../test/...` |
| Feed service | `../../../../Aerend-Feed/...` |
| Admin panel / Laravel | `../../../../Hare-AdminPanel/...` |
| Store app | `../../../../Hare-Store/...` |
| Specs | `../../../docs/...` |
| Plans | `../...` |
| Designs | `../../../../designs/21des/...` |

**Naming.** The feed service is called "Express" in several of its own docs. The code is **Fastify 5** ([`src/app.ts`](../../../../Aerend-Feed/src/app.ts)). This report says "feed service". "Laravel", "the monolith" and "the admin panel" all mean `Hare-AdminPanel`.

**What I could not do.** I could not call production. I did not read `Aerend-Feed/.env` (local secrets). I did not run any test suite. Claims about production are taken from the code on `origin/master` and are marked as such.

---

## 1. TL;DR

- **What it is.** The feed is a separate Node/TypeScript service (`Aerend-Feed`: Fastify 5, Drizzle, Postgres 16, Redis/Valkey, BullMQ). Stores post product highlights and 24-hour stories. Ærend can post too. Customers follow stores, like, comment and tap through to order. Laravel stays the identity authority: it mints a short-lived RS256 **feed JWT** that the service verifies against Laravel's JWKS.
- **Production runs `master`, not `agil-1`.** `origin/master` has no `/v1/feed/tabs`, no admin/moderation routes, no event webhook and no migration `0001`. All the agil-1 work (tabs, mix rule, Ærend composer, moderation, eligibility, event bridge) exists only on `agil-1`. The customer app's Utforsk feed calls `/v1/feed/tabs`, so **against production it gets a 404** until `agil-1` is merged to `master`, and that merge auto-deploys and auto-migrates.
- **Works end-to-end on `agil-1` (code-verified):** feed JWT mint and verify, store sync from Laravel, store post and story publishing from the **legacy** Hare-Store composer, customer reads (tabs, legacy feed, explore, stories, store profile, post detail, comments, search, CTA), follow, like, comment with rate limit and profanity check, FCM fan-out for new post, story, comment and follower.
- **Ranking is simple and deterministic.** `I nærheten` is chronological with the mix rule (at most 1 Ærend post per 5 store posts, never two in a row, `drift` exempt), plus an optional `bydel` filter. **There is no deliverability filter and no 72-hour window**, both of which Order Ops §16.3 asks for. `Følger` is chronological. `Fra Ærend` shows only Ærend posts.
- **The Ærend composer and the moderation queue are API-only.** `POST/GET /internal/admin/posts`, `hide`, `remove`, `restore` and `schedule-sweep` exist and are tested in the feed service. **No admin screen calls any of them.** Laravel only calls `schedule-sweep`, once a minute from `ops:feed-outbox`.
- **The admin eligibility toggle does not reach the feed service.** Laravel writes `ops_store_feed_eligibility`. The feed service checks its own `feed_store_eligibility`, and no code writes to it. Switching a store off in the panel does not stop that store publishing through the store app.
- **Store posts carry almost no metadata.** `POST /v1/store/posts` accepts only `caption`, `location_name` and one media item. Every store post is therefore `post_type = generic` with no product, price, headline, category or `bydel`. The spec's "post linked to one of the store's products" is not built in the shipping composer.
- **Ægil receives almost nothing from the feed.** The bridge is built on both sides, but: (1) the feed posts to `/api/internal/feed/events` by default, while Laravel listens on **`/api/ops/feed/events`**; (2) the `OPS_FEED_*` and `FEED_WEBHOOK_SECRET` variables are in no committed env file; (3) store posts are `generic`, which `SignalInterpreter` ignores; (4) `POINTS_SIGNAL_SOURCE` defaults to `fixtures`; (5) `seed-bergen-feed.ts` writes rows directly and emits no events.
- **The customer app reaches only part of the feed.** The reachable Utforsk tab (`UtforskFeedTab`) loads one page of `tab=naerheten` (no paging, no `bydel`). The publisher tabs, the `Fra Ærend` tab, `VaagenCard`, the stories row and search live in the `lib/screens/feed/` stack, which hangs off `HomeV1`, and nothing constructs `HomeV1`.
- **The store app has two composers.** The legacy one (`FeedComposerScreen`) is reachable and posts caption plus image or video. The new Partner-design 3-step `FeedComposerFlow` (product link, type, compliance check, statuses) is pure UI, has no network call, and nothing opens it.
- **Spec drift.** The feed update spec says two publisher tabs («Publisert av butikker» / «Publisert av Ærend»), no stories in v1, and prices always read live. The code and later designs use three tabs, ship stories, and render a cached `price_ore`. The support/refunds/feed spec replaces "live immediately" with **pre-publication screening by Agent G** (`pending_review`/`held`/`rejected`). None of that exists in code.
- **Security.** `do-app-platform.yaml` (tracked in git) contains production secret values: the internal service token, the Cloudinary API secret and an FCM service-account private key. `docs/google-service.json` and `fcm-service-account-one-line.json` are tracked too. Rotate them and move them to DO encrypted env.
- **Biggest gaps:** deploy `agil-1` to `master` safely; fix the event-path mismatch and configure the bridge secrets; build the admin feed screens on the existing API; make eligibility one source of truth; give store posts product, type and price; wire the reachable Utforsk feed to all three tabs with paging; decide on Agent G screening.

---

## 2. System context

```mermaid
flowchart LR
  subgraph Apps
    CUST["Customer app - Kunde, aerend_customer"]
    STORE["Store app - Partner, Hare-Store"]
  end
  ADMIN["Admin panel - Laravel Blade"]
  LAR["Laravel monolith - Hare-AdminPanel, api.ailogistics.no"]
  FEED["Feed service - Aerend-Feed, Fastify"]
  PG[("Feed Postgres 16 - aerend-feed-pg")]
  RD[("Redis or Valkey 8 - aerend-feed-redis")]
  CLD["Cloudinary - media CDN"]
  FCM["Firebase Cloud Messaging - project hare-89094"]
  MYSQL[("Laravel MySQL")]
  WRK["Workers - store-sync and notifications"]

  CUST -- "POST /api/auth/feed-token" --> LAR
  STORE -- "POST /api/auth/feed-token with provider_service_id" --> LAR
  CUST -- "Bearer feed JWT, /v1/*" --> FEED
  STORE -- "Bearer feed JWT, /v1/store/*" --> FEED
  CUST -- "signed upload" --> CLD
  STORE -- "signed upload" --> CLD
  FEED -- "GET /.well-known/feed-jwks.json" --> LAR
  WRK -- "X-Service-Token, /api/internal/feed-stores and feed-device-tokens" --> LAR
  FEED -- "feed.post.published, HMAC" --> LAR
  LAR -- "ops:feed-outbox, /internal/events and /internal/admin/schedule-sweep" --> FEED
  ADMIN --> LAR
  LAR --> MYSQL
  FEED --> PG
  FEED --> RD
  WRK --> PG
  WRK --> RD
  WRK -- "sendEachForMulticast" --> FCM
  FCM --> CUST
  FCM --> STORE
```

What the arrows mean (each one is detailed in §19):

| Arrow | Direction | Auth |
|---|---|---|
| Feed-token mint | app → Laravel | the app's Laravel `access_token` in the body |
| Feed API | app → feed | `Authorization: Bearer <feed JWT>` (RS256) |
| JWKS fetch | feed → Laravel | public |
| Store sync, device tokens | feed workers → Laravel | `X-Service-Token` |
| `feed.post.published` | feed → Laravel | `X-Feed-Signature: sha256=<hmac>` |
| Contract events, schedule sweep | Laravel → feed | HMAC for events; `X-Service-Token` for admin routes |
| Push | feed worker → FCM → devices | the feed service's own FCM service account |

---

## 3. The feed service (Aerend-Feed): architecture and deployment

**What it is / why.** This service owns everything social: posts, media references, stories, follows, likes, comments, and the ranking and mix rule. Laravel keeps identity, stores, products, orders and money ([`docs/ARCHITECTURE.md`](../../../../Aerend-Feed/docs/ARCHITECTURE.md) §1, Order Ops spec §16.1). It was split out so feed load and feed outages never touch the order path.

**Spec & design.**
- Order Ops spec §2.1 and §16 ([link](../../../docs/AEREND%20ORDER%20OPS%20SPEC%20FINAL%20STATEv3.md)): the feed service owns `posts`, `follows`, `unread_state`, `post_metrics`, ranking and the mix rule; it talks to the monolith through JWKS-verified tokens and webhooks; "No order path depends on the Feed service".
- Feed update spec §3.2 and §5 ([link](../../../docs/aerendvstore%20feed%20update%20spec.md)): extend the existing feed service, using additive migrations only.

**How it works today.**
1. `src/server.ts` builds the Fastify app, listens on `PORT` (3000), then calls `registerSchedules()`, which registers the 5-minute `store-sync` repeatable job.
2. `src/app.ts` registers the raw-body parser (for HMAC), sensible, CORS and the auth plugin, then all routes (`src/routes/index.ts`), plus a global error handler with a stable envelope (`code`, `message`, `request_id`).
3. Authentication is per route: `requireAuth` (feed JWT), then `requireCustomer` or `requireStore`. Internal routes use `requireServiceToken` (`X-Service-Token`). `/internal/events` checks an HMAC signature.
4. Two worker processes run separately: `store-sync-worker` and `notification-worker`. `npm run dev` does not start them.

**Where in code.**

| Layer | File | Key symbols |
|---|---|---|
| Boot | [`src/server.ts`](../../../../Aerend-Feed/src/server.ts) | `buildApp`, `registerSchedules` |
| App | [`src/app.ts`](../../../../Aerend-Feed/src/app.ts) | error envelope, `x-request-id` header |
| Env | [`src/config/env.ts`](../../../../Aerend-Feed/src/config/env.ts) | `envSchema` (Zod), `loadFcmServiceAccount`, `fcmServiceAccount` |
| Routes | [`src/routes/index.ts`](../../../../Aerend-Feed/src/routes/index.ts) | `registerRoutes` (13 route modules) |
| Auth | [`src/auth/plugin.ts`](../../../../Aerend-Feed/src/auth/plugin.ts), [`verify.ts`](../../../../Aerend-Feed/src/auth/verify.ts), [`jwks.ts`](../../../../Aerend-Feed/src/auth/jwks.ts), [`types.ts`](../../../../Aerend-Feed/src/auth/types.ts) | `requireAuth`, `requireCustomer`, `requireStore`, `requireServiceToken`, `adminActorId`, `verifyFeedJwt`, `getJwks`, `feedJwtClaimsSchema` |
| DB | [`src/db/schema/*`](../../../../Aerend-Feed/src/db/schema/) | see §5 |
| Migrations | [`drizzle/0000_tough_thunderbird.sql`](../../../../Aerend-Feed/drizzle/0000_tough_thunderbird.sql), [`drizzle/0001_ordinary_thanos.sql`](../../../../Aerend-Feed/drizzle/0001_ordinary_thanos.sql), [`src/migrate.ts`](../../../../Aerend-Feed/src/migrate.ts) | |
| Queues | [`src/queues/index.ts`](../../../../Aerend-Feed/src/queues/index.ts), [`store-sync-worker.ts`](../../../../Aerend-Feed/src/queues/store-sync-worker.ts), [`src/notifications/*`](../../../../Aerend-Feed/src/notifications/) | `storeSyncQueue`, `notificationsQueue` |
| Health | [`src/routes/health.ts`](../../../../Aerend-Feed/src/routes/health.ts) | `/health`, `/ready` (`db`, `redis`, `laravel_bridge`, `degraded`) |

**API / events / data — full route inventory** (from `src/routes/*.ts` on `agil-1`):

| Method + path | Auth | Purpose | On `origin/master` (prod)? |
|---|---|---|---|
| `GET /health` | none | liveness, version | yes |
| `GET /ready` | none | Postgres + Redis + Laravel-bridge probe | yes (no bridge probe) |
| `GET /v1/me` | JWT | echo of the actor | yes |
| `GET /v1/me/follows/count` | customer | `following_count` | **no** |
| `POST /v1/me/profile` | customer | sync display name and avatar to `feed_users` | yes |
| `POST /v1/uploads/sign` | JWT | Cloudinary signed params | yes |
| `GET /v1/feed/tabs?tab=&bydel=&cursor=&limit=` | JWT | three tabs, mix rule | **no → 404** |
| `GET /v1/feed/explore` | JWT | engagement-ranked, unfollowed stores | yes |
| `GET /v1/feed` | JWT | legacy "followed stores" feed | yes |
| `GET /v1/stories` | JWT | followed stores' live stories, grouped | yes |
| `GET /v1/stores/:storeId/stories` | JWT | one store's stories | yes |
| `GET /v1/stores/:storeId` | JWT | store profile | yes |
| `GET /v1/stores/:storeId/posts` | JWT | store's posts | yes |
| `GET /v1/search/stores?q=` | JWT | store search | yes |
| `GET /v1/posts/:postId` | JWT | post detail (+ first 20 comments) | yes |
| `GET /v1/posts/:postId/comments` | JWT | comment page | yes |
| `GET /v1/cta/:postId` | JWT | deep link + web URL to the store | yes |
| `POST`/`DELETE /v1/stores/:storeId/follow` | customer | follow / unfollow | yes |
| `POST`/`DELETE /v1/posts/:postId/like` | customer | like / unlike | yes |
| `POST /v1/posts/:postId/comments` | customer | comment (rate limited, profanity) | yes |
| `DELETE /v1/comments/:commentId` | customer | delete own comment | yes |
| `GET /v1/store/profile` | store | own follower and post counts | yes |
| `POST`/`GET /v1/store/posts` | store | publish / list own posts | yes |
| `GET`/`PATCH`/`DELETE /v1/store/posts/:id` | store | own post detail / edit caption / soft delete | yes |
| `DELETE /v1/store/posts/:postId/comments/:commentId` | store | moderate a comment on own post | yes |
| `POST`/`GET /v1/store/stories`, `DELETE /v1/store/stories/:id` | store | stories | yes |
| `POST /internal/events` | HMAC `X-Feed-Signature` | inbound contract events | **no** |
| `POST`/`GET /internal/admin/posts` | `X-Service-Token` | Ærend composer / oversight list | **no** |
| `POST /internal/admin/posts/:postId/hide`, `/remove`, `/restore` | `X-Service-Token` | moderation | **no** |
| `POST /internal/admin/schedule-sweep` | `X-Service-Token` | promote scheduled, retire expired | **no** |

The "On `origin/master`" column comes from `git show origin/master:src/routes/index.ts` and `…/feed.ts`. `origin/master` registers no `events` or `admin-feed` modules, and its `feed.ts` has only `/v1/feed/explore` and `/v1/feed`. `origin/master` has only migration `0000`.

**Deployment** ([`do-app-platform.yaml`](../../../../Aerend-Feed/do-app-platform.yaml), [`Dockerfile`](../../../../Aerend-Feed/Dockerfile)):

| Component | Kind | Command | Branch |
|---|---|---|---|
| `api` | service, port 3000, health `/health` | Dockerfile `production` target → `node dist/server.js` | `master`, **`deploy_on_push: true`** |
| `store-sync-worker` | worker | `node dist/queues/store-sync-worker.js` | `master`, **auto-deploy** |
| `notification-worker` | worker | `node dist/notifications/notification-worker.js` | `master`, **auto-deploy** |
| `migrate` | **PRE_DEPLOY** job | `node dist/migrate.js` | `master` |
| `aerend-feed-pg` | managed PG | `${aerend-feed-pg.DATABASE_URL}` | |
| `aerend-feed-redis` | managed **Valkey** | `${aerend-feed-redis.DATABASE_URL}` | |

- Public URL: `https://aerend-feed-88chd.ondigitalocean.app/` ([`FEED_SYSTEM.md`](../../../../Aerend-Feed/docs/FEED_SYSTEM.md) §4). The target domain `apifeed.ailogistics.no` is still pending DNS.
- CI ([`.github/workflows/ci.yml`](../../../../Aerend-Feed/.github/workflows/ci.yml)) runs typecheck, lint and test on pull requests and on pushes to `main`. **It does not run on `master` pushes**, which are the deploy trigger.
- `FEED_WEBHOOK_SECRET` and `FEED_EVENTS_WEBHOOK_PATH` are **not in the DO spec**. Unless they were set by hand in the DO UI, a deployed `agil-1` has the event bridge switched off (see §14).

**Use-case examples.**
1. A developer merges `agil-1` into `master`. DO builds three images, runs `migrate` (applying `0001`: two new tables, 14 new `feed_posts` columns, `store_id` made nullable), then rolls out `api` and both workers. There is no manual step in between.
2. Laravel is down. `/v1/feed/tabs` still answers, because reads touch only Postgres. `/ready` reports `laravel_bridge: "unreachable"` and `degraded: true` (when the webhook secret is set). Store sync and push fail and retry.

**Status:** ✅ Built (service, routes, workers, deploy). Production runs the older `master`; the agil-1 surface is not deployed.

---

## 4. Identity: feed JWT minted by Laravel, verified by JWKS

**What it is / why.** Apps never send their long-lived Laravel `access_token` to the feed. They swap it for a short-lived RS256 JWT minted by Laravel, which the feed verifies offline with Laravel's public key.

**Spec & design.** [`FEED_MASTER_PLAN.md`](../../../../Aerend-Feed/docs/FEED_MASTER_PLAN.md) §3 "Bridge 1 — JWT issuance". [`Hare-AdminPanel/docs/FEED_JWT_KEYS.md`](../../../../Hare-AdminPanel/docs/FEED_JWT_KEYS.md). Order Ops spec §2.1 ("service JWTs with `aud` and short TTL").

**How it works today.**

```mermaid
sequenceDiagram
  participant App as "App - customer or store"
  participant L as "Laravel"
  participant F as "Feed service"
  App->>L: POST /api/auth/feed-token with access_token, actor_type, optional provider_service_id
  L->>L: FeedTokenController checks users or providers access_token
  L->>L: FeedJwtSigner mint RS256 with kid, iss, aud, exp, jti
  L-->>App: feed_jwt and expires_at
  App->>F: GET /v1/... Authorization Bearer feed_jwt
  F->>L: GET /.well-known/feed-jwks.json, cached by jose
  F->>F: jwtVerify RS256, iss, aud, then Zod feedJwtClaimsSchema
  F-->>App: 200, or 401 with jwt_expired or jwt_invalid_signature
  App->>L: on 401 re-mint once, then retry
```

**Claims** ([`src/auth/types.ts`](../../../../Aerend-Feed/src/auth/types.ts) `feedJwtClaimsSchema`, a discriminated union on `actor_type`):

| actor_type | `sub` | Other claims |
|---|---|---|
| `customer` | `c_<user_id>` | `user_id`, optional `user_name`, optional `avatar_url` |
| `store` | `s_<store_details_id>` | `provider_id`, `provider_service_id`, `store_details_id` |
| both | | `iat`, `exp`, `iss`, `aud`, `jti` |

There is no `role` or `store_id` claim. **The feed store key is `store_details_id`**, not `providers.id` (the "ID mapping gotcha" in `FEED_SYSTEM.md` §2).

**Where in code.**

| Layer | File | Key symbols |
|---|---|---|
| Laravel route | [`routes/api.php`](../../../../Hare-AdminPanel/routes/api.php) L35 | `POST auth/feed-token` (no auth middleware; the controller checks the token) |
| Laravel controller | [`app/Http/Controllers/Api/Auth/FeedTokenController.php`](../../../../Hare-AdminPanel/app/Http/Controllers/Api/Auth/FeedTokenController.php) | `__invoke`; 403 `store_not_owned`, 401 `no_store_context`, 401 `invalid_token` |
| Laravel signer | [`app/Services/FeedJwt/FeedJwtSigner.php`](../../../../Hare-AdminPanel/app/Services/FeedJwt/FeedJwtSigner.php) | `mint()` → `JWT::encode(..., 'RS256', $keyId)` |
| JWKS | [`app/Http/Controllers/WellKnownController.php`](../../../../Hare-AdminPanel/app/Http/Controllers/WellKnownController.php), [`app/Services/FeedJwt/JwksService.php`](../../../../Hare-AdminPanel/app/Services/FeedJwt/JwksService.php) | `GET /.well-known/feed-jwks.json` (`routes/web.php` L17), `Cache-Control: max-age=3600`, **one key only** |
| Laravel config | [`config/feed_jwt.php`](../../../../Hare-AdminPanel/config/feed_jwt.php) | `FEED_JWT_PRIVATE_KEY`, `FEED_JWT_PUBLIC_KEY`, `FEED_JWT_KEY_ID` (`feed-key-1`), `FEED_JWT_ISSUER` (`aerend-laravel`), `FEED_JWT_AUDIENCE` (`aerend-feed-service`), `FEED_JWT_TTL` (3600) |
| Feed verify | [`src/auth/verify.ts`](../../../../Aerend-Feed/src/auth/verify.ts), [`src/auth/jwks.ts`](../../../../Aerend-Feed/src/auth/jwks.ts) | `verifyFeedJwt`, `createRemoteJWKSet(LARAVEL_JWKS_URL)` |
| Customer app | [`lib/services/feed_jwt_service.dart`](../../lib/services/feed_jwt_service.dart), [`lib/networking/feed/feed_auth_interceptor.dart`](../../lib/networking/feed/feed_auth_interceptor.dart), [`lib/services/feed_jwt_storage.dart`](../../lib/services/feed_jwt_storage.dart) | `FeedJwtService.getValidToken` (re-mints within 300 s of expiry), `forceRefresh`, a single shared mint `Completer`; `FeedAuthInterceptor.onError` retries a 401 once (`feed_retry`) |
| Store app | [`Hare-Store/lib/services/store_feed_jwt_service.dart`](../../../../Hare-Store/lib/services/store_feed_jwt_service.dart) | `StoreFeedJwtService`: sends `provider_service_id` from `prefStoreServiceId`, re-mints when the active store changes |
| Tests | [`tests/Feature/FeedTokenTest.php`](../../../../Hare-AdminPanel/tests/Feature/FeedTokenTest.php) (9 cases), [`tests/Feature/FeedJwksTest.php`](../../../../Hare-AdminPanel/tests/Feature/FeedJwksTest.php), [`Aerend-Feed/test/auth.test.ts`](../../../../Aerend-Feed/test/auth.test.ts), [`test/feed/feed_jwt_service_test.dart`](../../test/feed/feed_jwt_service_test.dart), [`test/feed/feed_jwt_short_ttl_test.dart`](../../test/feed/feed_jwt_short_ttl_test.dart) | |

**Use-case examples.**
1. A Bronse customer opens Utforsk for the first time today. `FeedAuthInterceptor` asks `FeedJwtService` for a token. There is none cached, so it posts the stored `prefAccessToken` to Laravel, stores `feed_jwt` in secure storage, and the tabs call goes out with a Bearer header.
2. A partner with two shops switches from shop A to shop B. `StoreFeedJwtService` sees a new `provider_service_id` and re-mints. The JWT now carries B's `store_details_id`, so a post lands under B.
3. The token expires while the app is in the background. The next call returns 401 `jwt_expired`. The interceptor force-refreshes once and retries without interceptors. No login prompt appears.

**Status:** ✅ Built. Gaps: no key rotation (JWKS serves exactly one key, and there is no rotation command); `FeedJwtService.clear()` is never called on logout, so a cached feed JWT survives logout or an account switch until it expires. The audit doc warns that the same `X-Service-Token` secret is reused in both directions (`docs/AGENT_PLATFORM_AUDIT.md`).

---

## 5. Data model and the post lifecycle (innleggets livssyklus)

**What it is / why.** One table, `feed_posts`, holds both store and Ærend posts. They differ by `publisher_type`. A richer `status` was added alongside the original `is_published`/`is_deleted` flags so old readers keep working.

**Spec & design.** Feed update spec §5 data model (`feed_post` with `publisher_type`, nullable `store_id`, `product_id`, `headline`, `body`, `image`, `category`, `status draft/scheduled/live/hidden/removed`, `hidden_reason`; `store_feed_eligibility`). The support spec §6 adds `pending_review`/`held`/`rejected` and a `screening_result` table. Order Ops spec §16.2 uses different type names (`redaksjonelt | kampanje | drift`, `bak_disken`, `apent_na`).

**Tables** ([`src/db/schema/`](../../../../Aerend-Feed/src/db/schema/)):

| Table | File | Purpose | Written by |
|---|---|---|---|
| `feed_users` | `users.ts` | Mirror of Laravel customer ids (name, avatar, locale) | `ensureFeedUser` / `syncCustomerFeedUser` on every customer call |
| `feed_stores` | `stores.ts` | Denormalised store (id = `store_details.id`, slug, name, logo, cover, `is_active`, `deeplink_path`, `updated_at_source`) | `upsertStores` (sync) |
| `feed_profiles` | `stores.ts` | 1:1 store counters (`follower_count`, `post_count`, bio) | sync (insert), follow and post writes |
| `feed_posts` | `posts.ts` | Posts; see the columns below | store publish, Ærend composer, moderation, sweep, events, seeds |
| `feed_post_media` | `posts.ts` | Ordered Cloudinary references (`position` 0 only in practice) | store publish, seeds |
| `feed_stories` | `stories.ts` | 24 h stories (`expires_at`, `is_expired`) | store story publish |
| `feed_follows`, `feed_likes`, `feed_comments` | `social.ts` | social graph and engagement | customer writes |
| `feed_store_eligibility` | `eligibility.ts` | per-store publish switch (default on) | **nothing writes it** |
| `feed_processed_events` | `eligibility.ts` | inbound event dedupe (`event_id` PK) | `claimEvent` |
| `feed_drafts` | `drafts.ts` | composer drafts | **unused** |
| `feed_notifications_log`, `feed_outbox` | `notifications.ts` | in-app log, reliable outbox | **unused** |

**`feed_posts` columns added by migration `0001` (agil-1):** `publisher_type` (default `store`), `store_product_id`, `price_ore`, `price_updated_at`, `attributed_order_count`, `headline`, `post_type` (default `generic`), `category`, `status` (default `live`), `hidden_reason`, `scheduled_at`, `expires_at`, `created_by`, `bydel`; `store_id` becomes nullable. New indexes: `feed_posts_publisher_status_idx`, `feed_posts_scheduled_idx`. See [`drizzle/0001_ordinary_thanos.sql`](../../../../Aerend-Feed/drizzle/0001_ordinary_thanos.sql).

**Enumerations** ([`src/db/schema/posts.ts`](../../../../Aerend-Feed/src/db/schema/posts.ts)):
- `FEED_POST_STATUS`: `draft`, `scheduled`, `live`, `hidden`, `removed`
- `FEED_PUBLISHER_TYPE`: `store`, `aerend`
- `FEED_POST_TYPE`: `tilbud`, `ny_i_hyllene`, `dagens_rett`, `generic`, `ny_pa_aerend`, `nytt_i_hyllene`, `tilbud_i_naerheten`, `apent_sent`, `populaert_i_kveld`, `butikk_i_fokus`, `drift`

**The single readability rule** ([`src/feed/ranking/status.ts`](../../../../Aerend-Feed/src/feed/ranking/status.ts) `readablePostSql`):
`p.is_published AND NOT p.is_deleted AND p.status = 'live'`. Every customer query composes it. The tab reader also adds `deliverableSql` ([`tabs.ts`](../../../../Aerend-Feed/src/feed/queries/tabs.ts)): not expired, and for store posts the store is active and not disabled.

**Post lifecycle — what the code actually does:**

```mermaid
stateDiagram-v2
  [*] --> live: store POST /v1/store/posts
  [*] --> live: admin composer, no or past scheduled_at
  [*] --> scheduled: admin composer, future scheduled_at
  [*] --> draft: constant only, no writer
  scheduled --> live: schedule-sweep when scheduled_at is due
  live --> hidden: POST hide with reason
  hidden --> live: POST restore
  live --> removed: POST remove with reason
  hidden --> removed: POST remove with reason
  scheduled --> hidden: POST hide
  live --> expiredLive: sweep sets is_published false when expires_at is due
  live --> softDeleted: store DELETE sets is_deleted true
  removed --> [*]
  note right of expiredLive
    status stays live, only is_published flips.
    The tabs reader also hides it by expires_at at once.
  end note
  note right of softDeleted
    status stays live, is_deleted true.
    Readable filter excludes it everywhere.
  end note
```

Rules worth knowing ([`src/feed/admin/moderation.ts`](../../../../Aerend-Feed/src/feed/admin/moderation.ts)):
- `createAerendPost` decides the status **only** from `scheduled_at` (future → `scheduled`, else `live`). A caller cannot ask for "live with a future date".
- `hidePost` and `removePost` require a non-empty reason (422 `reason_required`) and store it in `hidden_reason`. `removePost` also sets `is_deleted = true`.
- `restorePost` works only from `hidden` (409 `post_not_restorable` otherwise). **`removed` is terminal.**
- `runScheduleSweep` promotes due `scheduled` posts and flips `is_published=false` on expired `live` posts, deliberately leaving `status = live` ("the store should not see «Skjult av Ærend» for a post that simply ended").
- `draft` is never written by any code path (grep for `FEED_POST_STATUS.draft` finds only the constant and the `UNREADABLE_STATUSES` list).

**Use-case examples.**
1. Ærend schedules a "Fiskesuppe-uke" post for Friday 11:00. It is stored as `scheduled` and is invisible in every tab. At 11:00, Laravel's minute scheduler calls `schedule-sweep`; the post goes `live`, `published_at` becomes 11:00, and `feed.post.published` is emitted.
2. A moderator hides a store post: "Bildet viser et annet produkt". It disappears from all three tabs on the next fetch. The store app's own post list (`GET /v1/store/posts`) filters on `is_published`, so **the post disappears from the store's list too**, without the "Skjult av Ærend" label the spec asks for.

**Status:** 🟡 Partial. Schema and transitions are built and tested ([`test/admin-feed.test.ts`](../../../../Aerend-Feed/test/admin-feed.test.ts), [`test/feed-tabs.test.ts`](../../../../Aerend-Feed/test/feed-tabs.test.ts); the Postgres suites skip without Docker). Not built: `draft` writer, edit-in-place for Ærend posts, an honest status in the store's own list, `pinned_until` (Order Ops §16.2), the screening statuses (support spec §6).

---

## 6. Store publishing (Butikk-innlegg)

**What it is / why.** A partner publishes a post (one image or video plus a caption) or a 24-hour story from the store app. Store posts go live immediately; moderation happens afterwards.

**Spec & design.**
- Feed update spec §1.1 ("Store feed posts go live… Immediately") and §2.4: pick one of your own products, add a headline and short text, image defaults to the product image, the post links to the product, live immediately, the store sees its own posts and an honest «Skjult av Ærend».
- **Superseded** by `aerend-support-refunds-feed-spec.docx` §4 / §4.5: every partner post is screened by **Agent G** before publication (clean → published within about 60 s; hold → human queue with a 2 h SLA; propose reject → a human confirms). Statuses «Til gjennomgang», «Publisert», «Avvist», plus «Endre og send på nytt».
- Order Ops §16.2: store post types `dagens_rett | ny_i_hyllene | bak_disken | apent_na | tilbud`; media 4:3 or 9:16 video; `product_id` optional.
- Design: [`Ærend leveranse 6 - Feed.dc.html`](../../../../designs/21des/%C3%86rend%20leveranse%206%20-%20Feed.dc.html) screen **6g** "Ærend Partner · postingsflyt på under 60 sekunder" (1: camera, Foto/Video 30 s; 2: one line, type, link a product; 3: preview as the customer card, Publiser nå / Utløper i kveld 22:00, local reach line). [`Ærend Partner.dc.html`](../../../../designs/21des/%C3%86rend%20Partner.dc.html) Butikk hub → `feed` / `komponer` / `kampanje`, with screening statuses (`sendTilScreening`, `feedStatus`, pending_review/held/rejected/published) and "FRA ÆREND · OM BUTIKKEN DIN" with the opt-in toggle.

**How it works today** (legacy composer, the reachable path):

```mermaid
sequenceDiagram
  participant P as "Partner user"
  participant SA as "Hare-Store FeedComposerScreen"
  participant L as "Laravel"
  participant F as "Feed service"
  participant C as "Cloudinary"
  participant Q as "BullMQ notifications"
  participant W as "notification-worker"
  participant M as "Laravel ops feed events"
  P->>SA: pick photo or video, write caption, Publiser
  SA->>L: POST api/auth/feed-token actor_type store, provider_service_id
  L-->>SA: feed_jwt with store_details_id
  SA->>F: POST /v1/uploads/sign purpose post
  F-->>SA: signature, public_id, folder, eager
  SA->>C: upload bytes directly
  C-->>SA: public_id, version, width, height, format
  SA->>F: POST /v1/store/posts caption, location_name, media
  F->>F: assertStorePublishable, store exists and feed_store_eligibility not disabled
  F->>F: createStorePost, status live, post_type generic
  F-->>SA: 201 post detail
  F-)Q: enqueueFeedNewPost
  F-)M: emitFeedPostPublished, fire and forget
  Q->>W: job feed_new_post
  W->>L: GET /api/internal/feed-device-tokens user_ids
  W->>W: FCM sendEachForMulticast to followers
```

Steps in prose:
1. `home_screen.dart:116` (tooltip "Store feed profile") opens `StoreFeedProfileScreen`. Its create button opens `FeedCreateOptionsSheet` (post or story), which opens `FeedComposerScreen`.
2. `StoreFeedPublishFlow` picks and compresses the file, calls `POST /v1/uploads/sign`, uploads to Cloudinary with `CloudinaryUploader`, then calls `StoreFeedRepo.createPost(caption, media)`.
3. The feed service validates the body with `createStorePostBodySchema`: `caption` ≤ 2200 characters, optional `location_name`, required `media`. **No product, headline, type, category, price, bydel, schedule or expiry is accepted.**
4. `assertStorePublishable` returns 404 if the store is not synced, or 403 `store_not_eligible` with the stored reason if `feed_store_eligibility.enabled = false`.
5. `createStorePost` inserts the post (`is_published = true`, `published_at = now`, all agil-1 columns at their defaults: `publisher_type = store`, `post_type = generic`, `status = live`), inserts media row 0 with `bytes = 0`, and increments `feed_profiles.post_count`.
6. It then enqueues `feed_new_post` (job id `new-post-<id>`) and calls `emitFeedPostPublished` (§14). Neither blocks the 201.
7. Stories use `POST /v1/store/stories`: `expires_at = now + 24 h` (`STORY_TTL_MS`) and a `feed_new_story` push to followers.
8. The store can `PATCH` caption/location (`updateStorePost`), soft-delete (`deleteStorePost`: `is_deleted = true`, `post_count - 1`), delete a comment on its own post (`deleteCommentForStore`), list its own posts and stories, and read its follower/post counts.

**Where in code.**

| Layer | File | Key symbols |
|---|---|---|
| Feed route | [`src/routes/store-publish.ts`](../../../../Aerend-Feed/src/routes/store-publish.ts) | `/v1/store/profile`, `/v1/store/posts[/:id]`, `/v1/store/posts/:postId/comments/:commentId`, `/v1/store/stories[/:id]` |
| Feed write | [`src/feed/store-publish/write.ts`](../../../../Aerend-Feed/src/feed/store-publish/write.ts) | `assertStorePublishable`, `createStorePost`, `updateStorePost`, `deleteStorePost`, `createStoreStory`, `deleteStoreStory`, `getPostForPublishedEvent`, `STORY_TTL_MS` |
| Feed schemas | [`src/feed/store-publish/schemas.ts`](../../../../Aerend-Feed/src/feed/store-publish/schemas.ts) | `createStorePostBodySchema`, `CAPTION_MAX_LENGTH = 2200` |
| Feed reads | [`src/feed/store-publish/queries.ts`](../../../../Aerend-Feed/src/feed/store-publish/queries.ts) | `queryStoreOwnPosts` (filters `p.is_published AND NOT p.is_deleted`), `queryStoreOwnActiveStories` |
| Store app (reachable) | [`Hare-Store/lib/screens/feed/`](../../../../Hare-Store/lib/screens/feed/) | `StoreFeedProfileScreen`, `FeedCreateOptionsSheet`, `FeedComposerScreen` + `FeedComposerBloc`, `FeedManagementScreen`, `StorePostDetailScreen`, `StoreFeedPostEditScreen`, `StoreStoryViewerScreen` |
| Store app networking | [`Hare-Store/lib/networking/feed/`](../../../../Hare-Store/lib/networking/feed/) | `StoreFeedRepo`, `StoreFeedApiHelper`, `StoreFeedAuthInterceptor`, `StoreFeedPublishFlow`, `CloudinaryUploader`, `FeedBaseUrl` |
| Store app (Partner design, **unwired**) | [`Hare-Store/lib/screens/ops/feed/feed_composer_flow.dart`](../../../../Hare-Store/lib/screens/ops/feed/feed_composer_flow.dart), [`store_post_list_screen.dart`](../../../../Hare-Store/lib/screens/ops/feed/store_post_list_screen.dart), [`lib/data/ops/ops_feed_post.dart`](../../../../Hare-Store/lib/data/ops/ops_feed_post.dart), [`lib/data/ops/feed_compliance.dart`](../../../../Hare-Store/lib/data/ops/feed_compliance.dart) | `FeedComposerFlow` (3 steps, `onPublish` callback only, no HTTP), `StorePostListScreen`, `OpsFeedPost`, `FeedDraft`, `FeedCompliance` |
| Tests | [`Aerend-Feed/test/store-publish.test.ts`](../../../../Aerend-Feed/test/store-publish.test.ts) (18 cases) | |

**API / events / data.** `POST /v1/store/posts` body: `{ caption?, location_name?, media: { cloudinary_public_id, cloudinary_version, format, width, height, resource_type, duration_ms? } }` → 201 post detail. Errors: `invalid_request_body` 400, `store_not_found` 404, `store_not_eligible` 403. Side effects: `feed_new_post` job, `feed.post.published` event.

**Use-case examples.**
1. *Torgboden* posts a photo of prawns with "Reker 500 g, ferske i dag". The post is live within a second for followers in `Følger` and for everyone in `I nærheten`. It has no price or product, so the customer card shows no "Legg til" and no price. Ægil ignores the resulting event (`post_type = generic`).
2. Ærend switches *Torgboden* off in the admin panel's "Publiseringstilgang". The next post from the store app **still succeeds**, because the panel wrote Laravel's `ops_store_feed_eligibility` and the feed reads its own empty `feed_store_eligibility` (see §8).
3. A partner taps "Feed" in the new ops shell bottom nav. They see the placeholder "Butikk — Varer, Feed og innstillinger (Phase 7–9)" (`ops_shell_screen.dart`). The 3-step composer is never shown.

**Status:** 🟡 Partial. The legacy publish path works end-to-end. Not built in the shipping path: product link, headline, type, price, bydel, scheduling/expiry, honest hidden status, Agent G screening, and the reach line. The `AGIL-1-PLAN.md` Phase 9 tick on "Hare-Store composer: pick own product → headline + text (+ type) → preview → publish …" is **not true end-to-end**: the widget exists, but it has no network call and no parent.

---

## 7. Ærend composer, scheduling and expiry (Fra Ærend)

**What it is / why.** Ærend publishes its own posts, under its own identity, into the `Fra Ærend` tab, and through the mix rule into `I nærheten`. These posts may have no store (an editorial or drift notice) or may promote a store's product.

**Spec & design.**
- Feed update spec §4.1: compose from the panel, pick any store's product, headline, text, image, publish now or schedule; states draft → scheduled → live → hidden/removed; full list with edit/unpublish.
- Order Ops §16.2: types `redaksjonelt | kampanje | drift`, with `drift` pinnable via `pinned_until`. §18.7: preview as the customer card, pin drift, expiry for offers, a mix-rule preview.
- Order Ops §16.8 and §17.7 **X1 `agent.editorial`** (v3.1): Ærend posts are **planned, written and published by an agent** (types `ny_pa_aerend`, `nytt_i_hyllene`, `tilbud_i_naerheten`, `apent_sent`, `populaert_i_kveld`, `butikk_i_fokus`, `drift`), created as `scheduled` with `hold_until = now + 15 min`, and retractable in the panel ("Trekk tilbake"). Store opt-out lives in `store_editorial_settings`.
- Support spec §4.3: Ærend posts go through the same Agent G screening; an author may publish over a hold with a logged reason.
- Design: leveranse 6 screen **6f** "Fra Ærend · drift (festet), redaksjonelt, kampanje"; admin prototype `CFeedEdit` "Nytt Ærend-innlegg" ([`admin/screens-commercial.jsx`](../../../../designs/21des/admin/screens-commercial.jsx) L1081) and `FeedMgmt` tab "Publisert av Ærend" (L1933).

**How it works today.**
1. A server-side caller (meant to be the admin panel) sends `POST /internal/admin/posts` with `X-Service-Token`, and optionally `X-Ops-Actor-Id` for the audit trail (it falls back to `"unknown"`).
2. `createPostSchema` accepts `headline` (1–200, required), `caption` (≤ 4000), `store_id`, `store_product_id`, `post_type` (required, free string ≤ 32), `category`, `bydel`, `price_ore`, `scheduled_at`, `expires_at`. **There is no media field**, so an Ærend post has no image. The tab reader then returns a `media` object with an empty `cloudinary_public_id`.
3. `createAerendPost` inserts with `publisher_type = aerend` and `status` derived from `scheduled_at`.
4. If the result is `live`, the route emits `feed.post.published` (actor `system`, id = `X-Ops-Actor-Id`). **It does not enqueue a push**, unlike store posts.
5. Scheduling and expiry are driven from **Laravel**. `ops:feed-outbox` runs every minute (`app/Console/Kernel.php` L37, `everyMinute()->withoutOverlapping(55)`), drains Laravel's outbox, then calls `FeedBridge::runScheduleSweep()` → `POST {OPS_FEED_BASE_URL}/internal/admin/schedule-sweep`. The feed's `runScheduleSweep` is idempotent; each promoted post gets a `feed.post.published` event.

```mermaid
sequenceDiagram
  participant Sch as "Laravel scheduler, every minute"
  participant FB as "FeedBridge"
  participant F as "Feed service"
  participant DB as "Feed Postgres"
  participant L as "Laravel api ops feed events"
  Sch->>FB: ops:feed-outbox
  FB->>F: POST /internal/events for each pending outbox row, HMAC
  FB->>F: POST /internal/admin/schedule-sweep, X-Service-Token
  F->>DB: scheduled and scheduled_at due becomes live
  F->>DB: live, published and expires_at due sets is_published false
  F-->>FB: published and expired counts
  F-)L: feed.post.published for each newly live post
```

**Where in code.**

| Layer | File | Key symbols |
|---|---|---|
| Route | [`src/routes/admin-feed.ts`](../../../../Aerend-Feed/src/routes/admin-feed.ts) | `createPostSchema`, `oversightQuerySchema`, `registerAdminFeedRoutes` |
| Logic | [`src/feed/admin/moderation.ts`](../../../../Aerend-Feed/src/feed/admin/moderation.ts) | `createAerendPost`, `runScheduleSweep`, `listPostsForOversight` |
| Auth | [`src/auth/plugin.ts`](../../../../Aerend-Feed/src/auth/plugin.ts) | `requireServiceToken` (constant-time compare against `LARAVEL_INTERNAL_TOKEN`), `adminActorId` (`x-ops-actor-id`) |
| Laravel caller | [`app/Services/Ops/FeedBridge.php`](../../../../Hare-AdminPanel/app/Services/Ops/FeedBridge.php) | `runScheduleSweep()`, `drainOutbox()`, `deliver()` |
| Laravel command | [`app/Console/Commands/Ops/OpsFeedOutbox.php`](../../../../Hare-AdminPanel/app/Console/Commands/Ops/OpsFeedOutbox.php) | `ops:feed-outbox {--limit=50}` |
| Tests | [`Aerend-Feed/test/admin-feed.test.ts`](../../../../Aerend-Feed/test/admin-feed.test.ts) (22 cases), Laravel `AdminFeedOversightTest` (schedule sweep) | |

**API.** `POST /internal/admin/posts` → `201 { post_id, status }` · 422 `invalid_request_body`. `POST /internal/admin/schedule-sweep` → `{ published, expired }`.

**Use-case examples.**
1. Ops wants a rain notice: `post_type = "drift"`, `headline = "Regn i kveld — litt lengre leveringstid"`, no store, `expires_at` +3 h. It is live at once, appears in `Fra Ærend`, and appears in `I nærheten` regardless of the mix rule (drift is exempt). It is retired by the sweep after 3 h. Today this can only be done with curl or a script, because no panel screen exists.
2. A campaign for *Trattoria Del Napoli* (`store_id = 5`, `post_type = "butikk_i_fokus"`, `price_ore = 21900`): it renders with the store's name and logo and goes through the mix rule. `feed.post.published` carries `publisher_type = aerend`, actor `system`. Ægil's interpreter ignores `butikk_i_fokus` (§14).

**Status:** 🟡 Partial. API, scheduling and expiry ✅. Panel UI ❌. Media on Ærend posts ❌. Pinning ❌. `agent.editorial` ❌ (grep `editorial` in `Aerend-Feed/src` finds nothing). Hold-window retract ❌. Push for Ærend posts ❌.

---

## 8. Moderation and publishing eligibility (Moderering)

**What it is / why.** After-the-fact control. Hide or remove any post with a reason, restore a hidden one, and switch a misbehaving store's publishing off without touching its products.

**Spec & design.**
- Feed update spec §4.2: one view of all posts (filter store, category, status, date), hide/remove with a logged reason, immediate effect, honest status shown to the store; per-store eligibility toggle, default on.
- Order Ops §16.5: `POST /feed/posts/{id}/report` from the customer app → `feed.post.flagged` → panel; "No public comments at launch". §18.7: flagged posts with `agent.feed_moderation` proposals.
- Support spec §4: pre-publication Agent G screening, a moderation queue with SLA timer, Approve / Edit-and-publish / Reject, and the `agent_config` knobs.
- Admin prototype: `ModerationModule` ([`admin/screens-support.jsx`](../../../../designs/21des/admin/screens-support.jsx) L312), `AgentGControl` (L420), `FeedMgmt` tabs including "Moderering" and "Funksjoner" (toggles stories, comments, explore, likeCounts, allowSharing, requireApproval).

**How it works today.**

| Capability | Where | Status |
|---|---|---|
| Oversight list, all statuses, filters `store_id`, `category`, `status`, `publisher_type`, `from`, `to`, `search`, `limit` ≤ 200, `offset` | `GET /internal/admin/posts` → `listPostsForOversight` | ✅ API, ❌ UI |
| Hide with reason | `POST /internal/admin/posts/:id/hide` → `hidePost` | ✅ API, ❌ UI |
| Remove with reason (terminal) | `POST …/remove` → `removePost` | ✅ API, ❌ UI |
| Restore hidden | `POST …/restore` → `restorePost` | ✅ API, ❌ UI |
| Hidden posts gone from every tab | `readablePostSql` | ✅ |
| Store sees «Skjult av Ærend» + reason | `queryStoreOwnPosts` filters out unpublished posts; no `status`/`hidden_reason` in the response | ❌ |
| Eligibility toggle in panel | Laravel `GET /admin/drift/feed`, `POST /admin/drift/feed/butikk/{storeId}` → `FeedBridge::setEligibility` → `ops_store_feed_eligibility` | ✅ in Laravel |
| Eligibility enforced on publish | feed `assertStorePublishable` reads `feed_store_eligibility` | 🟡 enforced, but **no writer**: the two tables are never synced |
| Eligibility hides existing posts | `deliverableSql` joins `feed_store_eligibility` (tabs only) | 🟡 same disconnect |
| Customer "report post" | `feed_post_kebab_sheet.dart` "report" is a coming-soon stub; no `/report` route | ❌ |
| Comment moderation by store | `DELETE /v1/store/posts/:postId/comments/:commentId` | ✅ API |
| Comment profanity filter | `containsProfanity` ([`src/moderation/check.ts`](../../../../Aerend-Feed/src/moderation/check.ts)) on create | ✅ |
| Agent G pre-screening | grep `pending_review`, `held`, `screening` in `Aerend-Feed/src`, `Hare-AdminPanel/app`: nothing feed-related | ❌ |
| Unauthenticated Laravel eligibility API | `POST /api/ops/feed/stores/{storeId}/eligibility` has **no auth middleware** (`routes/api_ops.php`) | ⚠️ security gap |

```mermaid
sequenceDiagram
  participant Mod as "Moderator, no screen today"
  participant L as "Laravel"
  participant F as "Feed service"
  participant C as "Customer app"
  participant S as "Store app"
  Mod->>F: POST /internal/admin/posts/42/hide reason, X-Service-Token, X-Ops-Actor-Id
  F->>F: status hidden, hidden_reason set, is_published false
  F-->>Mod: post_id 42, status hidden
  C->>F: GET /v1/feed/tabs
  F-->>C: post 42 no longer in any tab
  S->>F: GET /v1/store/posts
  F-->>S: post 42 missing, no status or reason
  Mod->>L: toggle eligibility off for store 28 in /admin/drift/feed
  L->>L: ops_store_feed_eligibility enabled false
  S->>F: POST /v1/store/posts
  F->>F: feed_store_eligibility has no row, so publish is allowed
  F-->>S: 201, the toggle had no effect
```

**Where in code.**

| Layer | File | Key symbols |
|---|---|---|
| Feed | [`src/feed/admin/moderation.ts`](../../../../Aerend-Feed/src/feed/admin/moderation.ts) | `hidePost`, `removePost`, `restorePost`, `listPostsForOversight`, `OversightRow` |
| Feed | [`src/db/schema/eligibility.ts`](../../../../Aerend-Feed/src/db/schema/eligibility.ts) | `feedStoreEligibility` |
| Laravel | [`app/Http/Controllers/Admin/OpsAdminController.php`](../../../../Hare-AdminPanel/app/Http/Controllers/Admin/OpsAdminController.php) | `feed()`, `setEligibility()`, `drainOutbox()`, `takeover()` |
| Laravel | [`resources/views/admin/pages/super_admin/ops/feed.blade.php`](../../../../Hare-AdminPanel/resources/views/admin/pages/super_admin/ops/feed.blade.php) | sections "Broen", "Publiseringstilgang", "Steng en butikk ute", change log, "Overta et produkt" |
| Laravel | [`app/Services/Ops/FeedBridge.php`](../../../../Hare-AdminPanel/app/Services/Ops/FeedBridge.php) | `isEligible`, `ineligibleReason`, `setEligibility` (reason required to disable, audit `feed.eligibility.disabled`) |
| Laravel | [`app/Ops/SurfaceFlags.php`](../../../../Hare-AdminPanel/app/Ops/SurfaceFlags.php) L182–196 | `ops.feed.bridge`, `ops.feed.composer`, `ops.feed.oversight` |
| Laravel | `app/Http/Controllers/Ops/ProductController.php` L97–98 | returns `feed_eligible`, `feed_ineligible_reason` (for the unwired Partner composer) |

**Use-case examples.**
1. A customer complains about a post with alcohol marketing. Today ops must call `POST /internal/admin/posts/:id/remove` by hand with the service token; there is no screen and no report button.
2. Ops toggles a store off with the reason "Gjentatte brudd på prisreglene". The admin page shows it as disabled, but that store's legacy composer keeps publishing (see the diagram above).

**Status:** 🟡 Partial. Moderation API ✅; eligibility split across two unsynced tables 🟡; UI, report flow, honest store status and Agent G ❌.

Note also a small Laravel bug: `OpsAdminController::drainOutbox()` computes `$sent = is_array($result) ? count($result) : (int) $result;`. `FeedBridge::drainOutbox()` returns a 3-key array, so the flash message always says "3 hendelse(r) sendt.".

---

## 9. Reading the feed: tabs, ranking and the mix rule (I nærheten / Følger / Fra Ærend)

**What it is / why.** The customer sees three tabs. `I nærheten` (nearby) is the default stream, `Følger` (following) shows stores you follow, and `Fra Ærend` (from Ærend) shows Ærend's own posts. Ranking is intentionally not engagement-based.

**Spec & design.**
- Feed update spec §3.1: **two** publisher tabs «Publisert av butikker» / «Publisert av Ærend», category chips from config, newest first. §3.2: hidden posts disappear; prices always live.
- Order Ops §16.3: `I nærheten` chronological **within 72 h**, **filtered to stores deliverable to the customer's address** (`GET /stores/deliverable?lat,lng`), followed stores lifted slightly, no engagement ranking. `Følger` chronological. `Fra Ærend` Ærend posts only. §16.2 mix rule; promo cards at most 1 per 6–8 posts. §16.4 `GET /feed/unread`.
- Design: leveranse 6 **6a** (tabs I nærheten / Følger / Fra Ærend, store card with Følg, price, "Legg til"), **6b** (mix rule + promo cards), **6c** (six CTA states), **6d** (empty states), **6e** (Følger), **6f** (Fra Ærend). `Ærend Kunde Bergen.dc.html` `feedFane = naer | folger | aerend` (JS around L12528), category rail Alle / Restaurant / Mat & fisk / Bakeri / Grønt / Mote.

**How it works today.**

```mermaid
sequenceDiagram
  participant U as "Customer"
  participant App as "Utforsk, UtforskFeedTab"
  participant J as "FeedJwtService"
  participant L as "Laravel"
  participant F as "Feed service"
  participant DB as "Feed Postgres"
  participant Ops as "Laravel ops APIs"
  U->>App: open Utforsk, segment Feed
  App->>J: getValidToken
  J->>L: POST /api/auth/feed-token if none or near expiry
  L-->>J: feed_jwt
  App->>F: GET /v1/feed/tabs?tab=naerheten&limit=30
  F->>F: requireAuth, syncCustomerFeedUser
  F->>DB: SELECT readable and deliverable posts, ORDER BY published_at DESC, LIMIT 61
  F->>F: applyMixRuleBy, slice to 30, cursor from oldest key shown
  F-->>App: tab, label, items, next_cursor
  App->>Ops: OpsButikkApi.store per store, OpsCustomerApi.orders, OpsCustomerApi.poser
  App->>App: client-side category filter, render FeedPostCard
  Note over App,F: against production the tabs call is a 404, shown as the error card with Retry
```

Server rules ([`src/feed/queries/tabs.ts`](../../../../Aerend-Feed/src/feed/queries/tabs.ts) `queryFeedTab`):

| Tab (wire slug) | Filter beyond readable + deliverable | Order | Mix rule |
|---|---|---|---|
| `naerheten` (default) | if `bydel` is given: `p.bydel IS NULL OR p.bydel = :bydel` | `published_at DESC, id DESC` | ✅ applied; over-fetch `2·limit+1` |
| `folger` | `store_id` followed by the caller | same | no |
| `fra_aerend` | `publisher_type = 'aerend'` | same | no |

- **Deliverable** (`deliverableSql`): `expires_at` is null or in the future, and for store posts `s.is_active AND COALESCE(e.enabled, true)`. This is *not* address deliverability.
- **Mix rule** ([`src/feed/ranking/mix-rule.ts`](../../../../Aerend-Feed/src/feed/ranking/mix-rule.ts) `applyMixRuleBy`, `MIX_RULE.storePostsPerAerendPost = 5`): store and `drift` posts keep their order. An Ærend post is inserted only after five non-exempt store posts since the last one. Ærend posts that do not fit are **dropped from the page**. A page with only Ærend posts shows exactly one. `validateMix` exists for tests and a planned panel health card.
- **Paging:** cursor `(published_at, id)`. Because the mix rule reorders, the watermark is the oldest key actually shown (`oldestKey`).
- **Legacy `/v1/feed`** ([`queries/feed.ts`](../../../../Aerend-Feed/src/feed/queries/feed.ts)): followed stores only, readable, `s.is_active`; does **not** check `expires_at` or eligibility (relies on the sweep flipping `is_published`).
- **Explore `/v1/feed/explore`** ([`queries/explore.ts`](../../../../Aerend-Feed/src/feed/queries/explore.ts)): unfollowed active stores, scored `like_count + 3·comment_count + (10 − hours since publish, floored at 0)`. This is engagement ranking, which Order Ops §16.3 rules out for `I nærheten`. Explore is a separate surface, and the reachable app does not call it.
- **Item shape** (`FeedTabItem`): `publisher {type, name, logo_url}` ("Ærend" when there is no store), nullable `store`, `post_type`, `category`, `headline`, `bydel`, `caption`, `store_product_id`, `price_ore`, `attributed_order_count`, `media` (incl. `duration_ms`, `thumbnail_public_id`), likes, comments, `is_liked`, `published_at`, `expires_at`.

**Where in code.**

| Layer | File | Key symbols |
|---|---|---|
| Route | [`src/routes/feed.ts`](../../../../Aerend-Feed/src/routes/feed.ts) | `/v1/feed/tabs` (400 `unknown_tab`), `/v1/feed/explore`, `/v1/feed` |
| Tabs | [`src/feed/ranking/status.ts`](../../../../Aerend-Feed/src/feed/ranking/status.ts) | `FEED_TAB`, `FEED_TAB_LABELS` ("I nærheten", "Følger", "Fra Ærend"), `isFeedTab`, `readablePostSql` |
| Query | [`src/feed/queries/tabs.ts`](../../../../Aerend-Feed/src/feed/queries/tabs.ts) | `queryFeedTab`, `deliverableSql`, `mapRow`, `oldestKey` |
| Ranking | [`src/feed/ranking/mix-rule.ts`](../../../../Aerend-Feed/src/feed/ranking/mix-rule.ts) | `applyMixRule`, `applyMixRuleBy`, `isMixExempt`, `validateMix` |
| Paging | [`src/lib/cursor.ts`](../../../../Aerend-Feed/src/lib/cursor.ts) | `parsePaginationParams` (limit 1–50, default 20), `encodeCursor` |
| Tests | [`test/feed-ranking.test.ts`](../../../../Aerend-Feed/test/feed-ranking.test.ts) (11), [`test/feed-tabs.test.ts`](../../../../Aerend-Feed/test/feed-tabs.test.ts) (50-post mix fixture, hidden/removed/draft never shown, Følger/Fra Ærend scopes) | |

**Use-case examples.**
1. A new customer with no follows opens Utforsk. `I nærheten` returns every live post in Norway (no address filter), newest first, with at most one Ærend post after the first five store posts.
2. The same customer opens `Følger` (only reachable through the unwired `FeedHome`, and there only as "stores" vs "aerend"). The client never requests `tab=folger`.
3. A post expires at 22:00. The tabs reader stops showing it at 22:00:00 (`expires_at > NOW()`), while legacy `/v1/feed` shows it until the next minute's sweep.

**Status:** 🟡 Partial. Tabs and mix rule ✅. Not built: deliverability filter, 72 h window, "followed lifted slightly", promo-card mixing (done client-side in the app instead), `GET /feed/unread` and `seen` (the app approximates unread with a local timestamp pref `a1_utforsk_feed_seen_at`), category filtering on the server (client-side only), pinning.

---

## 10. Social features: follows, likes, comments, stories, search, CTA (Følg, Historier)

**What it is / why.** The Instagram-style layer from Phase 1 of the feed (`FEED_MASTER_PLAN.md` §1): follow a store, like and comment, 24 h stories, store search, and a CTA that deep-links to the store.

**Spec & design.** `FEED_MASTER_PLAN.md` §1 Phase 1 scope. The later feed update spec §3.1 says **do not build stories until confirmed** (open question 1). Order Ops §16.5 says "No public comments at launch". The leveranse 6 design states the heart means *save to a collection*, not like, and has "ingen kommentarer ved lansering". In `Ærend Kunde Bergen.dc.html` the "stories" rail is a **category filter**, and the comment icon toasts "kommentarer kommer senere".

**How it works today.**
- **Follow:** `POST/DELETE /v1/stores/:storeId/follow` → `feed_follows`, `feed_profiles.follower_count`, and a `feed_new_follower` push to the store. `GET /v1/me/follows/count`.
- **Like:** `POST/DELETE /v1/posts/:postId/like` → `feed_likes`, `like_count`.
- **Comment:** `POST /v1/posts/:postId/comments` (body ≤ 2000, optional `display_name`, `avatar_url`). The post must be readable (404 otherwise). It is checked by `containsProfanity`, then rate limited by Redis at **3 per user per post per 60 s** ([`src/lib/rate-limit.ts`](../../../../Aerend-Feed/src/lib/rate-limit.ts)) → 429 `rate_limit_exceeded` with `reset_at`. It then enqueues `feed_new_comment` to the store. `DELETE /v1/comments/:id` works for the author only.
- **Stories:** `GET /v1/stories` (followed stores, `expires_at > NOW()`, grouped by store), `GET /v1/stores/:id/stories`. There is no expiry worker: `is_expired` is never set to true; filtering is by `expires_at`.
- **Search:** `GET /v1/search/stores?q=` (active stores).
- **CTA:** `GET /v1/cta/:postId` → `{ deeplink_path (store's or /store/<slug>), web_url = CUSTOMER_WEB_BASE_URL/store/<slug> }`. Store posts only (inner join on `feed_stores`).

| Layer | File | Key symbols |
|---|---|---|
| Routes | [`src/routes/follows.ts`](../../../../Aerend-Feed/src/routes/follows.ts), [`likes.ts`](../../../../Aerend-Feed/src/routes/likes.ts), [`comments.ts`](../../../../Aerend-Feed/src/routes/comments.ts), [`posts.ts`](../../../../Aerend-Feed/src/routes/posts.ts), [`stories.ts`](../../../../Aerend-Feed/src/routes/stories.ts), [`stores.ts`](../../../../Aerend-Feed/src/routes/stores.ts), [`me.ts`](../../../../Aerend-Feed/src/routes/me.ts) | |
| Writes | [`src/feed/follows/write.ts`](../../../../Aerend-Feed/src/feed/follows/write.ts), [`likes/write.ts`](../../../../Aerend-Feed/src/feed/likes/write.ts), [`comments/write.ts`](../../../../Aerend-Feed/src/feed/comments/write.ts) | `deleteCommentForStore` |
| Reads | [`src/feed/queries/posts.ts`](../../../../Aerend-Feed/src/feed/queries/posts.ts), [`stores.ts`](../../../../Aerend-Feed/src/feed/queries/stores.ts), [`stories.ts`](../../../../Aerend-Feed/src/feed/queries/stories.ts) | `queryPostById`, `queryPostCta`, `queryStoreProfile`, `querySearchStores`, `queryFollowedStories` |
| Customer app | [`lib/networking/feed/feed_repo.dart`](../../lib/networking/feed/feed_repo.dart) | `followStore`, `likePost`, `createComment`, `fetchFollowedStories`, `searchStores`, `resolveCta` |
| Tests | [`test/feed-reads.test.ts`](../../../../Aerend-Feed/test/feed-reads.test.ts) (28), [`test/feed-writes.test.ts`](../../../../Aerend-Feed/test/feed-writes.test.ts) (29) | |

**Use-case examples.**
1. A customer taps Følg on a card in Utforsk. The app updates optimistically and shows the toast; the server inserts the follow; the store gets "X started following your store" (English template).
2. A customer writes four comments in 30 s on the same post. The fourth gets 429 with `reset_at`.

**Status:** ✅ Built (server). Spec conflict ⛔: stories and comments contradict the later specs and designs; a product decision is needed on whether they stay. Push copy is English only ([`src/notifications/templates.ts`](../../../../Aerend-Feed/src/notifications/templates.ts)).

---

## 11. Media: Cloudinary direct upload

**What it is / why.** Media bytes never pass through the feed service. It signs upload parameters, and the client uploads straight to Cloudinary.

**How it works today** ([`src/uploads/sign.ts`](../../../../Aerend-Feed/src/uploads/sign.ts), [`src/cloudinary/client.ts`](../../../../Aerend-Feed/src/cloudinary/client.ts)):
1. `POST /v1/uploads/sign { resource_type, purpose }`. Customers may use only `purpose = profile` (403 `upload_purpose_forbidden` otherwise). Stores may use `post`, `story` or `profile`.
2. `public_id = <CLOUDINARY_UPLOAD_FOLDER>/<customers|stores>/<id>/<purpose>/<uuid>`. Per-purpose `eager` transforms: post is square 1080 plus a 400 thumbnail (10 MB); story is 1080×1920 (8 MB); profile is face-aware 400/160 (4 MB). `api_sign_request` uses `CLOUDINARY_API_SECRET`, which is never returned.
3. The client posts the returned metadata in `media` when creating the post or story.
4. Clients build URLs as `https://res.cloudinary.com/<cloud>/<type>/upload/f_auto,q_auto/v<ver>/<id>.<format>` (customer `FeedMedia.cloudinaryUrl`, cloud `dybew1yxr` in [`lib/networking/feed/feed_cloudinary_config.dart`](../../lib/networking/feed/feed_cloudinary_config.dart)).

**Status:** ✅ Built ([`test/uploads.test.ts`](../../../../Aerend-Feed/test/uploads.test.ts), 11 cases). Note: `feed_post_media.bytes` is always written as 0 by `createStorePost`.

---

## 12. Push notifications (FCM)

**What it is / why.** The feed service sends its own pushes, using its own Firebase service account in the same Firebase project as Laravel (`hare-89094`), so device tokens work for both ([`FEED_MASTER_PLAN.md`](../../../../Aerend-Feed/docs/FEED_MASTER_PLAN.md) Bridges 3–4).

**Spec & design.** Order Ops §15/§16.4: follow pushes sent "through the monolith's push gateway", **off by default**, at most 1 per store per day and 2 per day in total. Leveranse 6 design: "Push er av til du slår det på per butikk". `FEED_LAUNCH_PLAN.md` M1/M2.

**How it works today.**

| Trigger | Job (`src/notifications/types.ts`) | Recipients | Template |
|---|---|---|---|
| Store post | `feed_new_post` (job id `new-post-<postId>`) | all followers of the store | "{store} posted something new…" |
| Store story | `feed_new_story` | all followers | "{store} added a new story…" |
| Customer comment | `feed_new_comment` | the store (provider device) | "{name} commented on your post" |
| Follow | `feed_new_follower` | the store | "{name} started following your store" |
| Ærend post | none | — | — |

The worker ([`src/notifications/notification-worker.ts`](../../../../Aerend-Feed/src/notifications/notification-worker.ts), [`processors.ts`](../../../../Aerend-Feed/src/notifications/processors.ts)) reads followers from `feed_follows`, calls Laravel `GET /api/internal/feed-device-tokens?user_ids=…` (or `store_ids=…`) in batches, and sends with `sendEachForMulticast` in chunks of 500 ([`fcm.ts`](../../../../Aerend-Feed/src/notifications/fcm.ts)). Queue options: 3 attempts, exponential backoff starting at 2 s.

Laravel's side: [`app/Http/Controllers/Api/Internal/FeedDeviceTokenController.php`](../../../../Hare-AdminPanel/app/Http/Controllers/Api/Internal/FeedDeviceTokenController.php) (max 100 ids per parameter; `store_ids` resolve to provider tokens). There is no Laravel test for it. Laravel also defines `NotificationService::CATEGORY_FEED_FOLLOW` (quiet hours, cap 3/day, deep link `aerend://feed/post/{id}`), but nothing sends with it.

Clients: the customer app's [`lib/services/push_notification_service.dart`](../../lib/services/push_notification_service.dart) handles `feed_new_post` (→ `PostDetailScreen`) and `feed_new_story` (→ `StoreProfileScreen`). Hare-Store's `lib/service/push_notification_service.dart` handles `feed_new_comment` and `feed_new_follower`.

**Status:** 🟡 Partial. Fan-out ✅ (tests: [`test/notification-processors.test.ts`](../../../../Aerend-Feed/test/notification-processors.test.ts), [`test/notifications.test.ts`](../../../../Aerend-Feed/test/notifications.test.ts)). Not built: opt-in per store (pushes go to every follower), daily caps, quiet hours, Norwegian copy. Production smoke tests T1/T2 are still "PENDING — HUMAN" (`AGIL-1-PLAN.md` Phase 12). **Boot gotcha:** `src/config/env.ts` builds `fcmServiceAccount` at import time and **throws** when `FCM_SERVICE_ACCOUNT_JSON` is `{}` and no path is set (unless `NODE_ENV=test`). This contradicts `LOCAL_DEV.md`, which says `{}` is fine for local boot.

---

## 13. Store sync from Laravel

**What it is / why.** `feed_stores` is a read-optimised copy of Laravel's `store_details` (plus provider and service fields), so feed reads never call Laravel.

**How it works today.**

```mermaid
sequenceDiagram
  participant API as "Feed api process"
  participant R as "Redis BullMQ"
  participant W as "store-sync-worker"
  participant L as "Laravel internal API"
  participant DB as "Feed Postgres"
  API->>R: registerSchedules, repeatable sync-changed every 5 min
  R->>W: job sync-changed
  W->>DB: SELECT max updated_at_source from feed_stores
  loop until empty or 50 pages
    W->>L: GET /api/internal/feed-stores/changed-since?ts=cursor&limit=200, X-Service-Token
    L-->>W: stores and next_cursor
    W->>DB: upsertStores, feed_stores upsert and feed_profiles insert if missing
  end
  Note over API,L: on demand, getStoreFresh caches feedstore id in Redis, 300 s hit and 60 s miss
  Note over W,L: manual, scripts/sync-store-ids.ts ids or scripts/trigger-store-sync.ts
```

**Where in code.**

| Layer | File | Key symbols |
|---|---|---|
| Schedule | [`src/queues/index.ts`](../../../../Aerend-Feed/src/queues/index.ts) | `storeSyncQueue`, `registerSchedules` (every 5 min) |
| Worker | [`src/queues/store-sync-worker.ts`](../../../../Aerend-Feed/src/queues/store-sync-worker.ts) | `MAX_PAGES = 50`, concurrency 1 |
| Upsert | [`src/feed/stores/sync.ts`](../../../../Aerend-Feed/src/feed/stores/sync.ts) | `upsertStores` (the single mutation path) |
| Cache | [`src/feed/stores/cache.ts`](../../../../Aerend-Feed/src/feed/stores/cache.ts) | `getStoreFresh` |
| HTTP client | [`src/laravel/client.ts`](../../../../Aerend-Feed/src/laravel/client.ts), [`types.ts`](../../../../Aerend-Feed/src/laravel/types.ts) | `fetchStoresByIds`, `fetchStoresChangedSince`, `fetchDeviceTokens`, `laravelFeedStoreSchema` |
| Scripts | [`scripts/sync-store-ids.ts`](../../../../Aerend-Feed/scripts/sync-store-ids.ts), [`scripts/trigger-store-sync.ts`](../../../../Aerend-Feed/scripts/trigger-store-sync.ts) | `npx tsx scripts/sync-store-ids.ts 28,9,10` |
| Laravel | [`routes/api.php`](../../../../Hare-AdminPanel/routes/api.php) L37–45, [`app/Http/Controllers/Api/Internal/FeedStoreController.php`](../../../../Hare-AdminPanel/app/Http/Controllers/Api/Internal/FeedStoreController.php), `app/Services/FeedSync/StoreFeedDataResolver.php`, [`app/Http/Middleware/RequireServiceToken.php`](../../../../Hare-AdminPanel/app/Http/Middleware/RequireServiceToken.php) | `byIds` (≤ 100), `changedSince` (limit 1–500); token `FEED_INTERNAL_TOKEN` (`config/services.php`) |
| Tests | [`tests/Feature/FeedInternalStoreTest.php`](../../../../Hare-AdminPanel/tests/Feature/FeedInternalStoreTest.php) (12), [`Aerend-Feed/test/store-sync.test.ts`](../../../../Aerend-Feed/test/store-sync.test.ts), [`test/laravel-client.test.ts`](../../../../Aerend-Feed/test/laravel-client.test.ts) | |

**Store fields:** `id` (= `store_details.id`), `provider_service_id`, `slug`, `name`, `logo_url`, `cover_url`, `is_active` (service status and provider status), `service_category_id` (only 5–10 are returned), `is_sports_club`, `deeplink_path` (`/store/<slug>`), `updated_at_source`.

**Use-case example.** Locally, `seed-bergen-feed.ts` refuses to run until stores 28, 9, 10, 5, 17 and 6 are in `feed_stores`. Run `npx tsx scripts/sync-store-ids.ts 28,9,10,5,17,6` against the local Laravel first.

**Status:** ✅ Built. Order Ops §2.1 lists webhooks `store.updated`, `store.status_changed`, `product.upserted`, `product.sold_out`; these do not exist (polling only, by design; see the `AGIL-1-PLAN.md` Phase 8 note).

---

## 14. Event bridge and Ægil signals

**What it is / why.** Contract events (`Hare-AdminPanel/docs/EVENT_CONTRACT.md`, FROZEN v1) let the feed tell the monolith a post went live, so Ægil can turn offers and arrivals into suggestions. They also let the monolith tell the feed about price changes and delivered orders (attribution).

**Spec & design.** Ægil spec §5.1 ([link](../../../docs/AEREND%20AEGIL%20AGENT%20SPEC%20FINAL%20VERSION.md)): signal `offer` from feed posts `type = tilbud` (`feed.post.published`) and `product.price_changed` with `delta < 0`; `arrival` from `ny_i_hyllene`, `dagens_rett`. Order Ops §16.1: attribution via `source_post_id` on order creation → `order.delivered` → feed counts orders per post. `EVENT_CONTRACT.md` "Transport": feed → monolith `POST /api/internal/feed/events`, HMAC `X-Feed-Signature`.

**How it works today.**

```mermaid
sequenceDiagram
  participant F as "Feed service"
  participant L as "Laravel FeedBridgeController"
  participant IN as "ops_feed_inbox"
  participant SS as "WebhookSignalSource"
  participant AM as "agent:match-daily 05:30"
  participant SI as "SignalInterpreter"
  participant ME as "MatchingEngine"
  participant AS as "agent_suggestions"
  F->>F: post becomes live, store publish, admin live, or sweep
  F->>F: buildFeedPostPublishedEvent and Zod-validate
  F->>L: POST LARAVEL_INTERNAL_BASE plus FEED_EVENTS_WEBHOOK_PATH, X-Feed-Signature
  Note over F,L: default path is /api/internal/feed/events, Laravel listens on /api/ops/feed/events
  L->>L: 503 if OPS_FEED_WEBHOOK_SECRET empty, 401 on bad signature, 422 on bad envelope
  L->>IN: claimInbound, dedupe on event_id, whole envelope stored
  L-->>F: 200
  AM->>SS: events feed.post.published, only if POINTS_SIGNAL_SOURCE is webhook
  SS->>IN: SELECT by type
  AM->>SI: fromEnvelope
  SI->>SI: tilbud or tilbud_i_naerheten gives offer, ny_i_hyllene, dagens_rett, nytt_i_hyllene, ny_pa_aerend give arrival, anything else gives nothing
  AM->>ME: run for each customer with agent level 1 or more
  ME->>AS: store post_id, signal_type, signal_event_id
```

**Outbound, feed → Laravel.**

| Event | Emitted from | Payload source | Delivery |
|---|---|---|---|
| `feed.post.published` v1 | `POST /v1/store/posts`; `POST /internal/admin/posts` when live; `schedule-sweep` per promoted post | `getPostForPublishedEvent` (headline falls back to the caption's first 200 characters; `product_identity_id` is always null) | `sendContractEvent`: single attempt, 10 s timeout, **no retry, no outbox** (`feed_outbox` is unused). Dropped with a warning when `FEED_WEBHOOK_SECRET` is empty |

**Inbound, Laravel → feed** (`POST /internal/events`, [`src/feed/webhooks/inbound.ts`](../../../../Aerend-Feed/src/feed/webhooks/inbound.ts)):

| Event | Effect in the feed | Does Laravel send it? |
|---|---|---|
| `product.price_changed` | `price_ore` and `price_updated_at` refreshed on every live post with that `store_id` + `store_product_id` | ✅ `ProductChangeLogger` L122 → `FeedBridge::enqueuePriceChanged` → `ops_feed_outbox` → `ops:feed-outbox` |
| `order.delivered` | `attributed_order_count + 1` on `source_post_id` | ❌ `ContractEventPublisher::orderDelivered` writes only `ops_order_events`; nothing enqueues it to the feed outbox, nothing writes `orders.ops_source_post_id`, and the customer app never sends `source_post_id` |
| `suggestion.reeled` | ignored (no handler; accepted with `ignored: true`) | ✅ `VaagenService::reel` |
| others | ignored | — |

Dedupe: `claimEvent` inserts `feed_processed_events` (PK `event_id`) before the work, and `releaseEvent` deletes it if the handler throws. IDs may be bare (`"3"`) or prefixed (`"p_3"`), via `parseContractId`.

**Why Ægil sees almost nothing today.** Every one of these has to be fixed for a real feed post to become a suggestion:
1. **Path mismatch.** The feed defaults to `FEED_EVENTS_WEBHOOK_PATH=/api/internal/feed/events` (`src/config/env.ts`, `.env.example`) and `EVENT_CONTRACT.md` documents the same path. Laravel's route is `POST /api/ops/feed/events` (`routes/api_ops.php` L174–176, included under `/api`). A 404 is logged as `feed_event_send_failed` and dropped.
2. **Secrets unset.** `FEED_WEBHOOK_SECRET` (feed) and `OPS_FEED_WEBHOOK_SECRET`, `OPS_FEED_BASE_URL`, `OPS_FEED_SERVICE_TOKEN` (Laravel) are not in any committed env file or in the DO spec. Unset, both sides switch the bridge off.
3. **Store posts are untyped.** The store publish API cannot set `post_type`, so every store post is `generic`, which the interpreter drops.
4. **Signal source flag.** `PointsServiceProvider` binds `WebhookSignalSource` only when `env('POINTS_SIGNAL_SOURCE') === 'webhook'`. It reads `env()` directly, which returns null once `config:cache` has run in production, so it would silently fall back to fixtures.
5. **Seed data emits nothing.** [`scripts/seed-bergen-feed.ts`](../../../../Aerend-Feed/scripts/seed-bergen-feed.ts) inserts `feed_posts` rows with typed `post_type`, prices and products, but imports no emitter, so its typed posts never reach `ops_feed_inbox`.
6. **Daily batch.** `agent:match-daily` runs at 05:30 (`app/Console/Kernel.php` L97), so even a delivered event becomes a suggestion only the next morning (or with `php artisan agent:match-daily --user=<id>`).

**Where in code.**

| Layer | File | Key symbols |
|---|---|---|
| Feed emit | [`src/feed/webhooks/emit.ts`](../../../../Aerend-Feed/src/feed/webhooks/emit.ts), [`outbound.ts`](../../../../Aerend-Feed/src/feed/webhooks/outbound.ts) | `emitFeedPostPublished`, `buildFeedPostPublishedEvent`, `sendContractEvent` |
| Feed schemas | [`src/feed/webhooks/schemas.ts`](../../../../Aerend-Feed/src/feed/webhooks/schemas.ts) | `eventEnvelopeSchema`, `EVENT_TYPE`, `feedPostPublishedPayloadSchema`, `productPriceChangedPayloadSchema`, `orderDeliveredPayloadSchema` |
| Feed HMAC | [`src/feed/webhooks/signature.ts`](../../../../Aerend-Feed/src/feed/webhooks/signature.ts) | `SIGNATURE_HEADER = "x-feed-signature"`, `signWebhookBody`, `verifyWebhookSignature` |
| Feed inbound | [`src/routes/events.ts`](../../../../Aerend-Feed/src/routes/events.ts), [`src/feed/webhooks/inbound.ts`](../../../../Aerend-Feed/src/feed/webhooks/inbound.ts), [`dedupe.ts`](../../../../Aerend-Feed/src/feed/webhooks/dedupe.ts), [`contract-id.ts`](../../../../Aerend-Feed/src/feed/webhooks/contract-id.ts) | `handleInboundEvent`, `HANDLERS`, `claimEvent`, `releaseEvent` |
| Laravel inbound | [`app/Http/Controllers/Ops/FeedBridgeController.php`](../../../../Hare-AdminPanel/app/Http/Controllers/Ops/FeedBridgeController.php), [`app/Services/Ops/FeedBridge.php`](../../../../Hare-AdminPanel/app/Services/Ops/FeedBridge.php) | `receive`, `verifySignature`, `claimInbound`, `INBOX_TABLE = 'ops_feed_inbox'` |
| Laravel → Ægil | [`app/Points/Sources/WebhookSignalSource.php`](../../../../Hare-AdminPanel/app/Points/Sources/WebhookSignalSource.php), [`app/Providers/PointsServiceProvider.php`](../../../../Hare-AdminPanel/app/Providers/PointsServiceProvider.php) L42–50, [`app/Console/Commands/AgentMatchDaily.php`](../../../../Hare-AdminPanel/app/Console/Commands/AgentMatchDaily.php), [`app/Agent/Matching/SignalInterpreter.php`](../../../../Hare-AdminPanel/app/Agent/Matching/SignalInterpreter.php) | `events()`, `OFFER_POST_TYPES`, `ARRIVAL_POST_TYPES`, `fromFeedPost` |
| Fixtures | [`tests/fixtures/events/feed.post.published.json`](../../../../Hare-AdminPanel/tests/fixtures/events/feed.post.published.json), `product.price_changed.json`, `suggestion.reeled.json`; registry `tests/fixtures/contract/names.agil1.json` L19–20, L35, L37, L74, L86–88 | |
| Tests | [`tests/Feature/Ops/FeedSignalSeamTest.php`](../../../../Hare-AdminPanel/tests/Feature/Ops/FeedSignalSeamTest.php) (`test_a_claimed_feed_post_becomes_an_offer_candidate`: claim → read through `WebhookSignalSource` → 1 offer candidate for store 28, product 488), `FeedBridgeTest`, `MergeIntegrationTest`; [`Aerend-Feed/test/feed-events.test.ts`](../../../../Aerend-Feed/test/feed-events.test.ts) (fixture field-for-field), [`test/feed-tabs.test.ts`](../../../../Aerend-Feed/test/feed-tabs.test.ts) "inbound event webhook" | |

**Use-case examples.**
1. With everything configured correctly (path override, secrets, `POINTS_SIGNAL_SOURCE=webhook`, not config-cached), Ærend publishes a `tilbud_i_naerheten` post for store 28 / product 488. The feed emits; Laravel stores it in `ops_feed_inbox`; at 05:30 `agent:match-daily` creates offer candidates for every customer with Ægil level ≥ 1. This is what `FeedSignalSeamTest` proves from the inbox onward.
2. A store changes the price of product 488 from 59 kr to 49,50 kr. `ProductChangeLogger` enqueues `product.price_changed`. Within a minute `ops:feed-outbox` delivers it, and every live post about 488 now shows `price_ore = 4950`. (Ægil's price-drop path reads `product.price_changed` from `ops_feed_inbox` in webhook mode, but this event only ever goes *out* to the feed, so Ægil never sees it: a Laravel-internal gap, see [report 01](01-AGENTIC-WORKFLOW-REPORT.md).)

**Status:** 🟡 Partial. Both halves of the bridge are built and unit/feature tested. The live wire is broken by the path mismatch and the missing configuration, and store posts carry no type. Attribution (`order.delivered`) is ❌ end-to-end.

---

## 15. Entry point: customer app — Utforsk → Feed

**What it is / why.** Customers see the feed inside **Utforsk** (Explore), the second tab of the Bergen bottom nav (Hjem, Utforsk, Kurv, Meg). Utforsk has three segments: Feed, Fjordfiske, Forundringspose.

**Spec & design.** Feed update spec §3. Leveranse 6 screens 6a–6f. `Ærend Kunde Bergen.dc.html` Utforsk block (`erUtforsk` around L4576, `data-screen-label="Feed-media"` L4626; entry cards `Utforsk-kort` L2527/L2638). `AGIL-1-PLAN-v2.md` Phase 2 "Utforsk, the feed tabs, and the Hjem entry points".

**How it works today (reachable path).**
1. `HomeMainV1` builds `UtforskScreen` as shell tab 1 ([`lib/screens/common/homeMainV1/home_main_v1.dart`](../../lib/screens/common/homeMainV1/home_main_v1.dart) L146).
2. [`UtforskScreen`](../../lib/screens/bergen/utforsk/utforsk_screen.dart) renders the segments, reads `OpsCustomerApi.driftNotice()` and `poser()`, and computes an unread badge from posts newer than the pref `a1_utforsk_feed_seen_at`. The Feed segment body is `UtforskFeedTab`.
3. [`UtforskFeedTab`](../../lib/screens/bergen/utforsk/feed_tab.dart) `_load()` calls `FeedRepo.fetchFeedTab(tab: 'naerheten', limit: 30)` **once**: no `bydel`, `nextCursor` ignored, no pull-to-refresh. It enriches each store from Laravel (`OpsButikkApi.store`), adds the "Du bestilte …" hint from `OpsCustomerApi.orders(limit: 50)`, interleaves a Forundringspose promo from `OpsCustomerApi.poser()`, and filters by category orb on the client (`alle, restaurant, fisk, bakeri, gront, mote`).
4. [`FeedPostCard`](../../lib/screens/bergen/utforsk/feed_post_card.dart) renders image or muted looping video (`VideoPlayerController.networkUrl`), a type badge, "Publisert av Ærend" for Ærend posts, the **cached** `price_ore`, Følg, heart, comments, Del and a CTA (`BergenCart.add` or open post/store).
5. Like and follow are optimistic with rollback. Tapping a store post opens `/bergen/butikk/{id}`; an Ærend post or comments open `PostDetailScreen`.
6. Any error, **including the production 404 on `/v1/feed/tabs`**, shows `a1_feed_error_title`/`_text` with a Retry button. A 404 is not told apart from other errors.
7. [`FeedNyheterScreen`](../../lib/screens/bergen/utforsk/feed_nyheter_screen.dart) ("Nytt fra butikkene", route `/bergen/utforsk?tab=feed` from Meg) calls `fetchFeedTab(tab: 'naerheten', limit: 30, bydel: …)`. On error it shows the empty copy and offers no retry.

**The unreachable legacy stack** (`lib/screens/feed/`): `FeedShellScreen` → `FeedHome` (+ `FeedHomeBloc` paging `/v1/feed`, stories row, `FeedPublisherTabs` stores/aerend → `fetchFeedTab('fra_aerend')`, `VaagenCard` via `OpsFeedApi`), `FeedSearchScreen`, `StoreProfileScreen`, `StoryViewerScreen`, `PostDetailScreen`. `FeedShellScreen` is opened only by `HomeV1._openFeedScreen` ([`lib/screens/common/home/home_v1.dart`](../../lib/screens/common/home/home_v1.dart)), and **nothing constructs `HomeV1`** (grep finds only its own declaration and a `.txt` scratch file). `FeedHome`'s `showPublisherTabs` and `showVaagen` default to `false`. `PostDetailScreen` and `StoreProfileScreen` *are* reachable, from Utforsk and from push.

**Where in code.**

| Layer | File | Key symbols |
|---|---|---|
| Base URL | [`lib/networking/feed/feed_api_constant.dart`](../../lib/networking/feed/feed_api_constant.dart) | `FeedBaseUrl.prodDomain`, `domain` (override else prod), `apiBase = domain + 'v1/'`, `setOverride`/`restoreOverride` (pref `dev_feed_api_override`) |
| HTTP | [`feed_api_helper.dart`](../../lib/networking/feed/feed_api_helper.dart), [`feed_auth_interceptor.dart`](../../lib/networking/feed/feed_auth_interceptor.dart), [`feed_locale_interceptor.dart`](../../lib/networking/feed/feed_locale_interceptor.dart) | `FeedApiHelper.instance` (Dio), `FeedAuthInterceptor`, `Accept-Language` |
| Repo | [`lib/networking/feed/feed_repo.dart`](../../lib/networking/feed/feed_repo.dart) | `fetchFeedTab`, `fetchFeed`, `fetchExploreFeed` (unused), `fetchFollowedStories`, `followStore`, `likePost`, `createComment`, `resolveCta`, `signUpload` (unused) |
| Models | [`lib/data/feed/`](../../lib/data/feed/) | `FeedTabItem`/`FeedTabPage` (`isFromAerend`, `hasProduct`, `title`), `FeedPost` (no `publisher_type`), `FeedMedia.cloudinaryUrl`, `FeedStory`, `FeedComment`, `FeedCta` |
| Errors | [`lib/exceptions/feed/feed_api_exception.dart`](../../lib/exceptions/feed/feed_api_exception.dart) | `FeedApiException.fromDio` (maps server `error.code`) |
| Utforsk | [`lib/screens/bergen/utforsk/`](../../lib/screens/bergen/utforsk/) | `UtforskScreen`, `UtforskFeedTab`, `FeedPostCard`, `FeedDriftNotice`, `FeedNyheterScreen`, `utforsk_copy.dart` |
| Legacy stack | [`lib/screens/feed/`](../../lib/screens/feed/) | `FeedShellScreen`, `FeedHome`, `FeedHomeBloc`, `FeedPublisherTabs`, `FeedCategoryChips`, `VaagenCard`, `FeedTabCard`, `PostDetailScreen`, `StoreProfileScreen`, `StoryViewerScreen`, `FeedSearchScreen`, `feed_reels_tab.dart` (unwired) |
| Vågen | [`lib/networking/ops/ops_feed_api.dart`](../../lib/networking/ops/ops_feed_api.dart) | `GET api/ops/feed/vaagen`, `POST api/ops/feed/vaagen/reel` (Laravel; used only by `FeedHome`) |
| Push | [`lib/services/push_notification_service.dart`](../../lib/services/push_notification_service.dart) | `feed_new_post` → `PostDetailScreen`; `feed_new_story` → `StoreProfileScreen` |
| Dev override | [`lib/screens/dev/dev_env_screen.dart`](../../lib/screens/dev/dev_env_screen.dart) | presets Prod / Local iOS / Local Android / Local LAN / Custom; long-press the title in `account.dart`, non-release builds only |
| Tests | [`test/feed/`](../../test/feed/), [`test/bergen/feed_tab_test.dart`](../../test/bergen/feed_tab_test.dart), `test/bergen/utforsk_test.dart` | no test for the tabs 404, the 401 retry, `FeedBaseUrl` or push routing |

**Use-case examples.**
1. A customer on a release build points at production. `FeedBaseUrl.prodDomain` is the DO URL (committed value), and `/v1/feed/tabs` returns 404 because prod runs `master`. Utforsk shows "the feed is not answering" with Retry, forever.
2. A developer with the local stack (`adb reverse tcp:3000 tcp:3000`) and the uncommitted local edit `prodDomain = 'http://127.0.0.1:3000/'` sees the Bergen seed: 7 posts, one video, one Ærend card, and one closed store. Liking works. `Fra Ærend` cannot be reached.
3. A customer taps a `feed_new_post` push. The app opens `PostDetailScreen`. If the post was removed meanwhile, it shows "no longer available" (T8, `PostDetailNotFound`).

**Status:** 🟡 Partial. The reachable feed is one page of `I nærheten` with cards, like, follow, CTA and post detail. Publisher tabs, `Følger`, `Fra Ærend`, Vågen, stories, search and paging are built but unreachable. The `AGIL-1-PLAN-v2.md` Phase 2 `[x]` "FeedHome with FeedPublisherTabs mounted … VaagenCard mounted" is contradicted by the code, and `AGIL-1-REMAINING.md` §3 already says so.

---

## 16. Entry point: store app (Partner / Hare-Store)

**What it is / why.** Partners publish posts and stories, see their counts and comments, and moderate comments.

**Spec & design.** See §6. `AGIL-1-PLAN.md` Phase 9 first task (Partner composer) and `8-10-WEEK-IMPLEMENTATION-PLAN.md` Phase 8.1 (`[ ]`). `Ærend Partner.dc.html` Butikk hub (`bSkjerm` `feed`/`komponer`/`kampanje`): drafts (UTKAST), posts sorted by orders, screening statuses, a service-down banner and queue, "Ærend kan skrive om butikken min".

**How it works today.**
- Reachable: home app-bar avatar button "Store feed profile" ([`lib/screen/homeScreen/home_screen.dart`](../../../../Hare-Store/lib/screen/homeScreen/home_screen.dart) L116) → [`StoreFeedProfileScreen`](../../../../Hare-Store/lib/screens/feed/store_feed_profile_screen.dart) (stats from `GET /v1/store/profile`, posts/stories grids) → `FeedCreateOptionsSheet` → [`FeedComposerScreen`](../../../../Hare-Store/lib/screens/feed/feed_composer_screen.dart) (caption + media) / story composer. Plus `StorePostDetailScreen` (comments, delete comment), `StoreFeedPostEditScreen` (`PATCH` caption), `StoreStoryViewerScreen`.
- Feed URL: [`lib/networking/feed/feed_api_constant.dart`](../../../../Hare-Store/lib/networking/feed/feed_api_constant.dart) `FeedBaseUrl.prodDomain` = the DO URL (verified committed on `agil-1`; the `192.168.x` line is commented out). Laravel `EndPoint.baseUrl = https://api.ailogistics.no/api/`.
- Push: `feed_new_comment` → `StorePostDetailScreen`; `feed_new_follower` → `StoreFeedProfileScreen`.
- Built but unreachable: `FeedComposerFlow`, `StorePostListScreen`, `OpsFeedPost` statuses (`draft/scheduled/live/hidden/removed`, «Skjult av Ærend»), `FeedCompliance` (blocks før-pris/discount and superlatives). `OpsShellScreen`'s "Feed" tab shows a placeholder. No `pending_review`/`held`/`rejected` anywhere.
- A dev upload test screen exists: `lib/screens/feed_dev/feed_upload_test_screen.dart`.

**Status:** 🟡 Partial. Legacy publish ✅. Partner-design composer 🧪 (UI only). Product-linked posts, scheduling/expiry and honest status ❌.

---

## 17. Entry point: admin panel

**What it is / why.** Ops should compose Ærend posts, moderate, switch store eligibility, watch bridge health and audit product and price changes.

**Spec & design.** Feed update spec §4. Order Ops §18.7 (Health, Ærend posts, Moderation, Performance). Support spec §4.4 (moderation queue with SLA timer). Admin prototype `FeedMgmt`, `CFeedEdit`, `ModerationModule`, `AgentGControl` ([`designs/21des/admin/`](../../../../designs/21des/admin/)).

**How it works today** (Laravel Blade, `routes/web.php` L559–585, admin group prefix `drift`):

| Route | Name | Controller | What it does |
|---|---|---|---|
| `GET /admin/drift/feed` | `get:admin:ops_feed` | `OpsAdminController@feed` | bridge health (`PanelReadModel::feedHealth`, read from Laravel tables only), eligibility table, last 50 change-log rows |
| `POST /admin/drift/feed/butikk/{storeId}` | `post:admin:ops_feed_eligibility` | `@setEligibility` | writes `ops_store_feed_eligibility` (reason required to disable) |
| `POST /admin/drift/feed/send` | `post:admin:ops_feed_drain` | `@drainOutbox` | "Send utboksen nå" (flash count bug, §8) |
| `POST /admin/drift/feed/produkt/{productId}` | `post:admin:ops_feed_takeover` | `@takeover` | hide/show a product via `ProductChangeLogger::applyAndLog` |

The "Nå" board has a feed health card (`ops/now.blade.php` L92–110). States: `unconfigured`, `failing`, `behind`, `ok`.

**Not built** (grep for composer, moderation and hide screens in `resources/views`, `resources/js`): Ærend composer UI, oversight list, hide/remove/restore, post preview, mix-rule preview, performance per post, Agent G controls. `OPS_ADMIN_GUIDE.md` L282 states it outright: "No feed moderation of post content… lives in the feed service's own admin API". `AGIL-1-PLAN.md` Phase 9 marks this `[~]` "endpoints done, screens not built", which is accurate.

**JWT key management:** `docs/FEED_JWT_KEYS.md` (openssl generate, `.env` PEM formats, `config:clear`, never commit the private key, deploy via the `APP_ENV_FILE` GitHub secret). No rotation command and no multi-key JWKS.

**Status:** 🟡 Partial (eligibility, health, change log, takeover ✅; feed content moderation and composer ❌).

---

## 18. Entry point: Ægil (agent signals)

The full path is in §14. In short, for [report 01](01-AGENTIC-WORKFLOW-REPORT.md) (Ægil): the feed is Ægil's only source of `offer`/`arrival` signals from posts. The Laravel half (`ops_feed_inbox` → `WebhookSignalSource` → `SignalInterpreter` → `MatchingEngine` → `agent_suggestions.post_id`) is built and covered by `FeedSignalSeamTest`. The feed half (`emitFeedPostPublished`) is built. They do not meet in a default deployment (wrong path, no secrets, `generic` store posts, the `POINTS_SIGNAL_SOURCE` env read).

Client side: `Suggestion.postId` (`lib/data/aegil/suggestion_models.dart` L37) is parsed but never read; `NewsCard` ("FRA FEEDEN", `lib/screens/aegil/widgets/chat_cards.dart`) is never built; `VaagenMoment` is built only in tests. The spec's "Vågen" reel (`suggestion.reeled`) is emitted by Laravel's `VaagenService`, the customer UI for it (`VaagenCard`) is unreachable, and the feed service ignores the event.

Not built: `agent.editorial` (X1), `agent.feed_moderation`, Agent G screening, `agent.campaign_planner` drafts into `POST /feed/drafts` (`feed_drafts` exists but is unused).

---

## 19. How the other apps/services interact with this one

### 19.1 Integration matrix

| From → To | Endpoint / channel | Auth | Built | Notes |
|---|---|---|---|---|
| Customer app → Laravel | `POST /api/auth/feed-token` (`actor_type: customer`) | `access_token` in the body | ✅ | `FeedJwtService` |
| Store app → Laravel | `POST /api/auth/feed-token` (`actor_type: store`, `provider_service_id`) | `access_token` | ✅ | `StoreFeedJwtService` |
| Customer app → feed | `/v1/feed/tabs`, `/v1/posts/*`, `/v1/stores/*`, `/v1/stories`, follow/like/comment, `/v1/me/*` | feed JWT | ✅ (tabs: agil-1 only) | `FeedRepo` |
| Store app → feed | `/v1/store/*`, `/v1/uploads/sign` | feed JWT (store) | ✅ | `StoreFeedRepo` |
| Apps → Cloudinary | `api.cloudinary.com/v1_1/dybew1yxr/{type}/upload` | signed params | ✅ | |
| Feed → Laravel | `GET /.well-known/feed-jwks.json` | public | ✅ | |
| Feed workers → Laravel | `GET /api/internal/feed-stores[?ids]`, `/changed-since`, `/feed-device-tokens` | `X-Service-Token` = `FEED_INTERNAL_TOKEN` | ✅ | |
| Feed → Laravel | `POST {LARAVEL_INTERNAL_BASE}{FEED_EVENTS_WEBHOOK_PATH}` `feed.post.published` | HMAC `X-Feed-Signature` (+ `X-Service-Token`) | 🟡 | **default path wrong** (`/api/internal/feed/events` vs `/api/ops/feed/events`) |
| Feed → Laravel | `GET /api/internal/feed-health` (`/ready` probe) | `X-Service-Token` | 🟡 | route does not exist in Laravel; a 404 counts as "ok" by design |
| Laravel → feed | `POST {OPS_FEED_BASE_URL}{OPS_FEED_EVENTS_PATH=/internal/events}` | HMAC | ✅ (if configured) | price changes, `suggestion.reeled` |
| Laravel → feed | `POST {OPS_FEED_BASE_URL}/internal/admin/schedule-sweep` | `X-Service-Token` = `OPS_FEED_SERVICE_TOKEN` | ✅ (if configured) | every minute |
| Admin panel → feed | `/internal/admin/posts*` | `X-Service-Token`, `X-Ops-Actor-Id` | ❌ | no caller |
| Customer app → Laravel | `GET /api/ops/feed/vaagen`, `POST /api/ops/feed/vaagen/reel` | **none** | 🟡 | unreachable UI; unauthenticated routes |
| Feed worker → FCM → apps | `sendEachForMulticast` | FCM service account | ✅ | |
| Driver app | — | — | n/a | the feed is not used by Bud |

### 19.2 Shared-secret wiring (must match)

| Feed service env | Laravel env | Used for |
|---|---|---|
| `LARAVEL_INTERNAL_TOKEN` | `FEED_INTERNAL_TOKEN` (`config/services.php` `feed.internal_token`) | feed → Laravel internal endpoints |
| `LARAVEL_INTERNAL_TOKEN` | `OPS_FEED_SERVICE_TOKEN` (`config/ops.php` `feed.service_token`) | Laravel → feed `/internal/admin/*` |
| `FEED_WEBHOOK_SECRET` | `OPS_FEED_WEBHOOK_SECRET` (`config/ops.php` `feed.secret`) | HMAC in both directions |
| `LARAVEL_JWT_ISSUER` / `LARAVEL_JWT_AUDIENCE` | `FEED_JWT_ISSUER` / `FEED_JWT_AUDIENCE` | JWT `iss`/`aud` |
| `LARAVEL_JWKS_URL` | served by `WellKnownController@feedJwks` | public key |
| `FEED_EVENTS_WEBHOOK_PATH` | route `POST /api/ops/feed/events` | must be set to `/api/ops/feed/events` |
| `LARAVEL_INTERNAL_BASE` | — | base for internal calls and events |
| — | `OPS_FEED_BASE_URL` | feed base URL (e.g. `http://127.0.0.1:3000`) |

### 19.3 End-to-end: store post → customer → Ægil

```mermaid
sequenceDiagram
  participant S as "Store app"
  participant F as "Feed service"
  participant W as "notification-worker"
  participant C as "Customer app"
  participant L as "Laravel"
  participant A as "Ægil matching"
  S->>F: POST /v1/store/posts
  F-->>S: 201 live
  F-)W: feed_new_post job
  W->>L: device tokens for followers
  W-)C: FCM push feed_new_post
  C->>F: GET /v1/posts/id on tap
  F-)L: feed.post.published, post_type generic
  L->>L: ops_feed_inbox if path and secret are right
  A->>L: 05:30 read inbox
  A->>A: generic gives no candidate
```

---

## 20. GAP analysis

### 20.1 Feed service (Aerend-Feed)

| # | Feature / requirement | Spec / plan ref | Status | Evidence | What's missing / next step | Owner app(s) |
|---|---|---|---|---|---|---|
| F1 | agil-1 feed code deployed to prod | AGIL-1-PLAN Ph 8–9 | ❌ | `origin/master` lacks `/v1/feed/tabs`, admin, events, `0001` | Planned, reviewed merge to `master` (auto-deploy + PRE_DEPLOY migrate). Smoke test `/v1/feed/tabs`, `/ready` | Aerend-Feed |
| F2 | Tabs I nærheten / Følger / Fra Ærend | Order Ops §16.3 | ✅ | `src/feed/queries/tabs.ts` `queryFeedTab` | — | Aerend-Feed |
| F3 | Mix rule 1:5, no two in a row, drift exempt | Order Ops §16.2 | ✅ | `src/feed/ranking/mix-rule.ts` | Panel preview (`validateMix` unused outside tests) | Aerend-Feed, Admin |
| F4 | I nærheten = deliverable to address, 72 h, followed lifted | Order Ops §16.3 | ❌ | `deliverableSql` checks only expiry/active/eligible | Add lat/lng or zone param, call Laravel deliverable stores (cached), 72 h window | Aerend-Feed, Laravel |
| F5 | Promo cards in the mix (Forundringspose, Fjordfiske) | Order Ops §16.2 | 🟡 | done client-side in `UtforskFeedTab` | Decide server vs client; enforce 1 per 6–8, not adjacent | App |
| F6 | Unread count and seen | Order Ops §16.4 | ❌ | no `/feed/unread` route; app uses pref `a1_utforsk_feed_seen_at` | Add `unread_state`, `GET /v1/feed/unread`, `POST /v1/posts/:id/seen` | Aerend-Feed, App |
| F7 | Post lifecycle draft → scheduled → live → hidden/removed | Feed spec §4.1, §5 | 🟡 | `moderation.ts`; `draft` has no writer | Draft create/edit for Ærend posts; edit-in-place | Aerend-Feed |
| F8 | Pinned drift posts | Order Ops §16.2, §18.7 | ❌ | no `pinned_until` column | Add column + ordering | Aerend-Feed |
| F9 | Outbound events reliable (retry/outbox) | EVENT_CONTRACT "Guarantees" | ❌ | `sendContractEvent` single attempt; `feed_outbox` unused | Persist to `feed_outbox`, retry worker | Aerend-Feed |
| F10 | Attribution `order.delivered` → `attributed_order_count` | Order Ops §16.1 | 🟡 | handler in `inbound.ts`; Laravel never sends it | Laravel enqueue to feed outbox; app sends `source_post_id`; write `orders.ops_source_post_id` | Laravel, App |
| F11 | Prices live, never frozen | Feed spec §3.2 | 🟡 | `price_ore` cache refreshed by `product.price_changed` | Accept as render cache, or have the app read the live price | Aerend-Feed, App |
| F12 | Post report → `feed.post.flagged` | Order Ops §16.5 | ❌ | no route; kebab "report" is a stub | Add route, event, panel queue | Aerend-Feed, App, Admin |
| F13 | Agent G pre-publication screening | Support spec §4, §6 | ❌ | no `pending_review`/`held`/`screening` | Business sign-off, then statuses + `screening_result` + worker | Aerend-Feed, Store, Admin |
| F14 | Agent drafts `POST /feed/drafts` | Order Ops §16.6, X1 | ❌ | `feed_drafts` unused | Routes + Partner "one tap publish" | Aerend-Feed, Store |
| F15 | `agent.editorial` Ærend posts with hold window | Order Ops §16.8, §17.7 X1 | ❌ | grep `editorial` → none | Planner, writer, `hold_until`, retract | Laravel agents, Aerend-Feed |
| F16 | Feed health `GET /feed/health` (queue depth, webhook lag) | Order Ops §16.7 | 🟡 | `/ready` has db/redis/bridge only; probes a non-existent Laravel path | Add queue depth/lag; fix the probe path | Aerend-Feed |
| F17 | Story expiry worker | FEED_MASTER_PLAN §1 | 🟡 | filtering by `expires_at` works; `is_expired` never set | Optional cleanup job | Aerend-Feed |
| F18 | Secrets out of git | FEED_SYSTEM §4 "Never commit" | ❌ | `do-app-platform.yaml`, `docs/google-service.json`, `fcm-service-account-one-line.json` tracked | Rotate internal token, Cloudinary secret, FCM key; move to DO encrypted env; replace with `REPLACE_ME` | Aerend-Feed, Ops |
| F19 | CI on the deploy branch | — | ❌ | `ci.yml` triggers on PRs and `main`, not `master` | Add `master` (or protect `master` behind PRs) | Aerend-Feed |
| F20 | FCM optional for local boot | LOCAL_DEV §3 | ❌ | `env.ts` throws on `{}` | Make FCM lazy, or fix the doc | Aerend-Feed |

### 20.2 Admin panel

| # | Feature / requirement | Spec / plan ref | Status | Evidence | What's missing / next step | Owner |
|---|---|---|---|---|---|---|
| A1 | Ærend composer UI (product, headline, text, image, schedule, expiry) | Feed spec §4.1; Order Ops §18.7 | ❌ | no view calls `/internal/admin/posts` | Blade/Vue screen on the existing API; add media to `createPostSchema` | Admin, Aerend-Feed |
| A2 | Oversight + hide/remove/restore with reason | Feed spec §4.2 | ❌ (API ✅) | `OPS_ADMIN_GUIDE.md` L282 | Screen calling `/internal/admin/posts*` with `X-Ops-Actor-Id` | Admin |
| A3 | Eligibility toggle effective in the feed | Feed spec §4.2 | 🟡 | Laravel `ops_store_feed_eligibility` vs feed `feed_store_eligibility` (no writer) | Push eligibility to the feed (event or internal call), or have the feed ask Laravel | Admin, Aerend-Feed |
| A4 | Moderation queue with SLA (Agent G) | Support spec §4.4 | ❌ | — | After F13 | Admin |
| A5 | Feed performance (reach, attributed orders) | Order Ops §18.7 | ❌ | `MetricsService` keys point to the feed; no screen | Read `attributed_order_count` via the oversight API | Admin |
| A6 | Bridge configured in env | OPS_ADMIN_GUIDE "Feed" | ❌ | `OPS_FEED_*` in no committed env file | Add to `.env.example` and deploy secrets | Admin/Ops |
| A7 | Event route matches the contract | EVENT_CONTRACT "Transport" | ❌ | doc `/api/internal/feed/events` vs route `/api/ops/feed/events` | Align doc, route alias or feed env | Admin, Aerend-Feed |
| A8 | Auth on `/api/ops/feed/stores/{id}/eligibility` and `vaagen/reel` | — | ❌ | `routes/api_ops.php` group has no auth middleware | Add service-token/admin and customer auth | Admin |
| A9 | `drainOutbox` flash count | — | 🟡 | `OpsAdminController::drainOutbox` counts array keys | Use `$result['sent']` | Admin |
| A10 | Feed JWT key rotation | FEED_JWT_KEYS | ❌ | single-key JWKS | Two-key JWKS + rotation runbook | Admin |
| A11 | `POINTS_SIGNAL_SOURCE` survives `config:cache` | AGIL2_ROLLOUT §7 | 🟡 | `env()` read in `PointsServiceProvider` | Move to `config/points.php` | Admin |

### 20.3 Store app (Hare-Store)

| # | Feature / requirement | Spec / plan ref | Status | Evidence | What's missing / next step | Owner |
|---|---|---|---|---|---|---|
| S1 | Publish post/story | Feed spec §2.4 | ✅ | `FeedComposerScreen`, `StoreFeedPublishFlow` | — | Store |
| S2 | Post linked to own product, headline, type | Feed spec §2.4; Order Ops §16.2 | ❌ | API accepts caption + media only; `FeedComposerFlow` unwired | Extend `createStorePostBodySchema` (`store_product_id`, `headline`, `post_type`, `category`, `bydel`, `expires_at`); wire `FeedComposerFlow` into `OpsShellScreen` | Store, Aerend-Feed |
| S3 | Honest status «Skjult av Ærend» + reason | Feed spec §2.4 | ❌ | `queryStoreOwnPosts` filters `is_published`; no status in the response | Return all own posts with `status`, `hidden_reason` | Aerend-Feed, Store |
| S4 | Compliance (no før-pris / discount copy) | Feed spec §2.4 flag | 🧪 | `FeedCompliance` (client only, unwired) | Wire + server-side check | Store, Aerend-Feed |
| S5 | Screening statuses (Til gjennomgang, Avvist …) | Support spec §4.4 | ❌ | none | After F13 | Store |
| S6 | "Ærend kan skrive om butikken min" opt-in | Order Ops X1 | ❌ | design only | `store_editorial_settings` | Store, Laravel |
| S7 | Offline queue / service-down state | Order Ops §16.7 | 🧪 | `FeedComposerFlow` `offline` flag, no outbox | Wire | Store |

### 20.4 Customer app (Aerend-app)

| # | Feature / requirement | Spec / plan ref | Status | Evidence | What's missing / next step | Owner |
|---|---|---|---|---|---|---|
| C1 | Feed works against production | — | ❌ | prod 404 on `/v1/feed/tabs` | Deploy F1; consider a fallback to `/v1/feed` | Aerend-Feed, App |
| C2 | Three tabs in the reachable Utforsk | Order Ops §16.3; design 6a/6e/6f | ❌ | `UtforskFeedTab` hard-codes `naerheten` | Add the tab switcher to `UtforskFeedTab` (or mount `FeedPublisherTabs` with `folger`) | App |
| C3 | Paging / refresh | — | ❌ | `nextCursor` ignored | Infinite scroll with `cursor` | App |
| C4 | `bydel` passed to I nærheten | Design 6a | 🟡 | only `FeedNyheterScreen` passes it | Pass the customer's bydel | App |
| C5 | Vågen card | AGIL-1-PLAN Ph 9; EVENT_CONTRACT `suggestion.reeled` | 🟡 | `VaagenCard` in `FeedHome` only | Mount in Utforsk | App |
| C6 | Stories row and viewer | FEED_MASTER_PLAN; feed spec §3.1 says not v1 | ⛔ | built, unreachable | Product decision | App, Product |
| C7 | Report post | Order Ops §16.5 | ❌ | kebab stub | After F12 | App |
| C8 | Clear feed JWT on logout | — | ❌ | `FeedJwtService.clear()` has no caller | Call it from logout | App |
| C9 | Send `source_post_id` on order | Order Ops §16.1 | ❌ | grep `source_post_id` in `lib/` → none | Carry `post_id` from the CTA to checkout | App |
| C10 | Distinguish 404 / service-down in the UI | Order Ops §16.7 | 🟡 | generic error card | Specific copy for "feed unavailable" | App |
| C11 | Push opt-in per store, Norwegian copy | Order Ops §15; design 6d | ❌ | pushes to all followers, English | Opt-in flag + nb templates | Aerend-Feed, App |

### 20.5 Ægil

| # | Feature / requirement | Spec / plan ref | Status | Evidence | What's missing / next step | Owner |
|---|---|---|---|---|---|---|
| G1 | Feed posts become offer/arrival signals | Ægil spec §5.1 | 🟡 | `FeedSignalSeamTest` passes from the inbox onward | Fix A7 path, set secrets, set `POINTS_SIGNAL_SOURCE=webhook` via config | Admin, Aerend-Feed |
| G2 | Store posts typed so they qualify | Ægil spec §5.1 | ❌ | store posts are `generic` | S2 | Store, Aerend-Feed |
| G3 | Seeded/demo posts produce signals | — | ❌ | `seed-bergen-feed.ts` emits nothing | Add an "emit after seed" option, or a replay script that calls `emitFeedPostPublished` for `created_by='seed-bergen'` rows | Aerend-Feed |
| G4 | Feed news card in the app | Ægil spec T08 | ❌ | `NewsCard` never built | See [report 01](01-AGENTIC-WORKFLOW-REPORT.md) | App |

### 20.6 Top 10 gaps to close next (ranked by impact)

1. **Ship agil-1 to production safely (F1, C1).** Everything new is invisible in prod, and the app's feed 404s. Plan the `master` merge, check `0001` against a prod snapshot first, and set the env (below) in DO before merging, because the merge deploys and migrates at once.
2. **Fix the event bridge configuration (A6, A7, G1).** Set `FEED_EVENTS_WEBHOOK_PATH=/api/ops/feed/events` (or add a Laravel route alias), set matching `FEED_WEBHOOK_SECRET`/`OPS_FEED_WEBHOOK_SECRET`, `OPS_FEED_BASE_URL`, `OPS_FEED_SERVICE_TOKEN`, and move `POINTS_SIGNAL_SOURCE` into config. Then correct `EVENT_CONTRACT.md`.
3. **Rotate and remove committed secrets (F18).** The internal token, Cloudinary secret and FCM private key are in git.
4. **Give store posts product, type and price (S2, G2).** Without them store posts cannot drive Ægil, cannot show "Legg til" or a price, and do not meet feed spec §2.4. Wire the existing `FeedComposerFlow`.
5. **Admin moderation and composer screens (A1, A2).** The API is done and tested; only the panel UI is missing.
6. **One source of truth for eligibility (A3).** Today the panel toggle does nothing to publishing.
7. **Make the reachable Utforsk feed complete (C2, C3, C4, C5).** Three tabs, paging, `bydel`, Vågen.
8. **Honest status for stores (S3).** Hidden posts currently vanish from the store's own list with no reason.
9. **Decide on Agent G screening (F13, S5, A4) ⛔.** The support spec supersedes "live immediately". Until it is decided, the store composer and moderation design cannot settle.
10. **Attribution end-to-end (F10, C9).** `source_post_id` from the app → Laravel order → `order.delivered` to the feed, so `attributed_order_count` (the "posts sorted by orders" view) means something.

---

## 21. Configuration, flags and environment

### 21.1 Feed service env ([`src/config/env.ts`](../../../../Aerend-Feed/src/config/env.ts))

| Variable | Default | Required | Notes |
|---|---|---|---|
| `NODE_ENV` | — | yes | `development` / `test` / `production` |
| `PORT` | 3000 | | |
| `DATABASE_URL` | — | yes | local host dev: `postgres://postgres:postgres@localhost:5433/feed` |
| `REDIS_URL` | — | yes | `redis://localhost:6379` |
| `LARAVEL_JWKS_URL` | — | yes | local: `http://127.0.0.1:8000/.well-known/feed-jwks.json` |
| `LARAVEL_JWT_ISSUER` / `LARAVEL_JWT_AUDIENCE` | `aerend-laravel` / `aerend-feed-service` | | must match Laravel `FEED_JWT_*` |
| `LARAVEL_INTERNAL_BASE` | — | yes | local: `http://127.0.0.1:8000` |
| `LARAVEL_INTERNAL_TOKEN` | — | yes, ≥ 32 chars | = Laravel `FEED_INTERNAL_TOKEN` = Laravel `OPS_FEED_SERVICE_TOKEN` |
| `CLOUDINARY_CLOUD_NAME` / `_API_KEY` / `_API_SECRET` | — | yes | placeholders boot; real values needed to upload (and for `seed-bergen-feed.ts`) |
| `CLOUDINARY_UPLOAD_FOLDER` | `aerend/feed` | | |
| `FCM_SERVICE_ACCOUNT_JSON` / `FCM_SERVICE_ACCOUNT_PATH` | `{}` / unset | **yes in practice** | boot throws on `{}` unless `NODE_ENV=test` |
| `FEED_WEBHOOK_SECRET` | `""` | for the bridge | empty: inbound 503, outbound dropped |
| `FEED_EVENTS_WEBHOOK_PATH` | `/api/internal/feed/events` | | **set to `/api/ops/feed/events`** to match Laravel |
| `CORS_ALLOWED_ORIGINS` | `""` | | |
| `CUSTOMER_WEB_BASE_URL` | `https://reendugnad.no` | | CTA `web_url` |

### 21.2 Laravel env (feed-related)

| Variable | Config key | Purpose |
|---|---|---|
| `FEED_JWT_PRIVATE_KEY`, `FEED_JWT_PUBLIC_KEY`, `FEED_JWT_KEY_ID`, `FEED_JWT_ISSUER`, `FEED_JWT_AUDIENCE`, `FEED_JWT_TTL` | `config/feed_jwt.php` | mint / JWKS |
| `FEED_INTERNAL_TOKEN` | `services.feed.internal_token` | protects `/api/internal/feed-*` (503 if empty) |
| `OPS_FEED_BASE_URL`, `OPS_FEED_EVENTS_PATH` (`/internal/events`), `OPS_FEED_WEBHOOK_SECRET`, `OPS_FEED_SERVICE_TOKEN`, `OPS_FEED_TIMEOUT` (5) | `config/ops.php` `feed.*` | outbound events, schedule sweep, inbound HMAC |
| `POINTS_SIGNAL_SOURCE` (`fixtures` / `webhook`) | read with `env()` in `PointsServiceProvider` | Ægil reads `ops_feed_inbox` only when `webhook` |

**Surface flags** (`app/Ops/SurfaceFlags.php`): `ops.feed.bridge`, `ops.feed.composer`, `ops.feed.oversight`; `ops.customer.utforsk` covers the customer Utforsk tab. **Scheduler:** `php artisan schedule:work` is required locally for `ops:feed-outbox` (event delivery + schedule sweep) and `agent:match-daily`.

### 21.3 Apps

| App | Setting | Committed on agil-1 | Notes |
|---|---|---|---|
| Customer | `FeedBaseUrl.prodDomain` | `https://aerend-feed-88chd.ondigitalocean.app/` | default unless the Dev Env override (`dev_feed_api_override`) is set; no `--dart-define` for the feed |
| Customer | `BaseUrl.prodDomain` (Laravel, feed-token mint) | **`http://10.224.247.180:8000/`** (a LAN IP; `https://api.ailogistics.no/` is commented out) | release blocker; the feed JWT is minted against this host |
| Customer | Cloudinary cloud | `dybew1yxr` | |
| Store | `FeedBaseUrl.prodDomain` | DO URL | Laravel `EndPoint.baseUrl = https://api.ailogistics.no/api/` |

### 21.4 Local-dev gotchas (each verified)

1. **The customer app talks to the production feed by default.** `FeedBaseUrl.domain` returns `prodDomain` unless an override is set ([`feed_api_constant.dart`](../../lib/networking/feed/feed_api_constant.dart)). For a local feed: either use the Dev Env screen (long-press the title on Account, non-release) → Local Android `10.0.2.2:3000` / Custom `http://127.0.0.1:3000/` with `adb reverse tcp:3000 tcp:3000`, or edit `prodDomain` locally. The working copy currently carries an **uncommitted** edit (`prodDomain = 'http://127.0.0.1:3000/'` and Laravel `http://127.0.0.1:8000/`); do not commit it.
2. **Production feed has no `/v1/feed/tabs`.** Prod = `origin/master`, whose `src/routes/feed.ts` registers only `/v1/feed/explore` and `/v1/feed`. Utforsk shows its error card against prod until agil-1 is deployed.
3. **The local feed must trust the local Laravel.** `.env.example` points `LARAVEL_JWKS_URL` and `LARAVEL_INTERNAL_BASE` at `api.ailogistics.no`. With those, a token minted by your local Laravel (different key) fails as `jwt_invalid_signature`, and store sync and device tokens hit production. Use the values in [`.env.local.example`](../../../../Aerend-Feed/.env.local.example) (`http://127.0.0.1:8000/...`), and make `LARAVEL_INTERNAL_TOKEN` equal the local Laravel's `FEED_INTERNAL_TOKEN`. (I did not read your local `.env`.)
4. **Postgres is on host port 5433.** `docker-compose.dev.yml` maps `5433:5432`, and `LOCAL_DEV.md` says 5433. But `.env.example`, `.env.local.example` and `README.md` step 4 still say `localhost:5432`, which on many machines is a different Postgres (`role "postgres" does not exist`). Use `postgres://postgres:postgres@localhost:5433/feed`.
5. **Migration `0001` must be applied locally.** It adds the 14 `feed_posts` columns, `feed_store_eligibility` and `feed_processed_events`. Without it, every tabs query fails. Run `DATABASE_URL=postgres://postgres:postgres@localhost:5433/feed npm run db:migrate` (`tsx src/migrate.ts`). **Never `npm run db:migrate:prod`.** (README mentions `scripts/migrate.ts` for the test DB; that file does not exist. Use `src/migrate.ts` with `feed_test`.)
6. **`seed-bergen-feed.ts` emits no events.** It writes `feed_posts`, `feed_post_media`, `feed_users` (990001, 990002) and comments directly (`created_by = 'seed-bergen'`, idempotent), uploads demo media to Cloudinary (real credentials needed), and requires stores 28, 9, 10, 5, 17, 6 in `feed_stores` (`scripts/sync-store-ids.ts` first). It never calls `emitFeedPostPublished`, so **Ægil gets no signals from seeded posts**. To exercise Ægil locally, publish through `POST /v1/store/posts` or `POST /internal/admin/posts` with a typed `post_type`, with the bridge configured.
7. **FCM credentials are needed to boot.** Set `FCM_SERVICE_ACCOUNT_PATH=docs/google-service.json` locally; `{}` throws at import.
8. **Workers are separate processes.** `npm run dev` starts only the API. Run `npm run worker:store-sync` and `npm run worker:notifications` in other terminals, or use the compose dev stack.
9. **The schedule sweep and event delivery need Laravel's scheduler** (`php artisan schedule:work`) and the `OPS_FEED_*` variables. Without them, scheduled Ærend posts never go live.
10. **Without Docker, most feed tests skip** (Postgres/Valkey suites). `AGIL-1-REMAINING.md` reports 60 passing / 120 skipped.

---

## 22. Developer quick-start / where to look first

### 22.1 File map

| Question | Look here first |
|---|---|
| Which routes exist? | `Aerend-Feed/src/routes/*.ts` (table in §3) |
| Why is a post not showing? | `src/feed/ranking/status.ts` `readablePostSql`, `src/feed/queries/tabs.ts` `deliverableSql` |
| Mix rule | `src/feed/ranking/mix-rule.ts` |
| Store publish | `src/routes/store-publish.ts`, `src/feed/store-publish/write.ts` |
| Ærend composer / moderation | `src/routes/admin-feed.ts`, `src/feed/admin/moderation.ts` |
| Events | `src/feed/webhooks/*`, Laravel `app/Services/Ops/FeedBridge.php`, `app/Http/Controllers/Ops/FeedBridgeController.php` |
| JWT | Laravel `FeedTokenController`, `FeedJwtSigner`, `JwksService`; feed `src/auth/*`; app `lib/services/feed_jwt_service.dart` |
| Store sync | `src/queues/store-sync-worker.ts`, `src/feed/stores/sync.ts`, Laravel `FeedStoreController` |
| Push | `src/notifications/*`, Laravel `FeedDeviceTokenController` |
| Customer UI | `lib/screens/bergen/utforsk/feed_tab.dart`, `feed_post_card.dart`; legacy `lib/screens/feed/` |
| Store UI | `Hare-Store/lib/screens/feed/` (live), `lib/screens/ops/feed/` (unwired) |
| Admin UI | `resources/views/admin/pages/super_admin/ops/feed.blade.php`, `OpsAdminController` |
| Ægil seam | `app/Points/Sources/WebhookSignalSource.php`, `app/Agent/Matching/SignalInterpreter.php`, `app/Console/Commands/AgentMatchDaily.php` |

### 22.2 Run everything locally

```bash
# 1. Feed infrastructure
cd D:/work/hare/Aerend-Feed
git branch --show-current          # must print agil-1, never work on master
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d postgres redis
cp .env.local.example .env         # then fix DATABASE_URL to port 5433, set FCM_SERVICE_ACCOUNT_PATH,
                                   # LARAVEL_INTERNAL_TOKEN = Laravel FEED_INTERNAL_TOKEN,
                                   # FEED_WEBHOOK_SECRET = Laravel OPS_FEED_WEBHOOK_SECRET,
                                   # FEED_EVENTS_WEBHOOK_PATH=/api/ops/feed/events
npm install
DATABASE_URL=postgres://postgres:postgres@localhost:5433/feed npm run db:migrate

# 2. Laravel (other terminal): php artisan serve (port 8000) and php artisan schedule:work
#    with OPS_FEED_BASE_URL=http://127.0.0.1:3000, OPS_FEED_SERVICE_TOKEN, OPS_FEED_WEBHOOK_SECRET,
#    FEED_INTERNAL_TOKEN, FEED_JWT_* keys, POINTS_SIGNAL_SOURCE=webhook (and no config:cache)

# 3. Feed processes
npm run dev                         # API :3000
npm run worker:store-sync           # separate terminal
npm run worker:notifications        # separate terminal
npx tsx scripts/sync-store-ids.ts 28,9,10,5,17,6
npx tsx scripts/seed-bergen-feed.ts # demo content; emits NO events

# 4. Smoke
curl -s http://localhost:3000/health
curl -s http://localhost:3000/ready  # laravel_bridge should be "ok"

# 5. Customer app on an Android device
adb reverse tcp:3000 tcp:3000
adb reverse tcp:8000 tcp:8000
# Account screen: long-press the title, Dev Env, Feed API Custom http://127.0.0.1:3000/
```

To exercise the Ærend composer and the Ægil seam by hand (the service token is your local value):

```bash
curl -s -X POST http://localhost:3000/internal/admin/posts \
  -H "Content-Type: application/json" -H "X-Service-Token: $LARAVEL_INTERNAL_TOKEN" -H "X-Ops-Actor-Id: dev" \
  -d '{"headline":"Ferske reker i dag","post_type":"tilbud_i_naerheten","store_id":"28","store_product_id":"488","price_ore":17900,"bydel":"Møhlenpris"}'
# then in Laravel: php artisan agent:match-daily --user=<id> --dry-run
```

### 22.3 Tests

| Repo | Command | Notes |
|---|---|---|
| Aerend-Feed | `npm test` (uses `feed_test` DB) | DB suites skip without Docker; single file: `npx vitest run test/feed-tabs.test.ts` |
| Laravel | `php artisan test --filter=Feed` | `FeedTokenTest`, `FeedJwksTest`, `FeedInternalStoreTest`, `Ops/FeedBridgeTest`, `Ops/FeedSignalSeamTest`, `AdminFeedOversightTest`, `FeedDegradationTest` (many are `@group requires-mysql`) |
| Customer | `flutter test test/feed test/bergen/feed_tab_test.dart` | |
| Store | `flutter test test/` (feed + `test/ops/feed_composer_test.dart`) | |

---

## 23. Glossary

| Term | Meaning |
|---|---|
| **Ærend** | The commercial delivery brand and platform (and the publisher identity for Ærend's own posts) |
| **Ægil** | The customer AI agent that turns signals (incl. feed posts) into suggestions; see [report 01](01-AGENTIC-WORKFLOW-REPORT.md) |
| **Utforsk** | "Explore": the customer bottom-nav tab holding Feed, Fjordfiske and Forundringspose |
| **Hjem / Kurv / Meg** | Home / Basket / Me: the other customer bottom-nav tabs |
| **I nærheten** | "Nearby": the default feed tab (`naerheten`) |
| **Følger / Følg** | "Following" (tab `folger`) / "Follow" (button) |
| **Fra Ærend** | "From Ærend": the tab with Ærend-published posts (`fra_aerend`) |
| **Publisert av butikker / av Ærend** | "Published by stores / by Ærend": the two tabs in the feed update spec |
| **Butikk** | Store / shop |
| **Innlegg / Butikk-innlegg** | Post / store post (feed content item); *innleggets livssyklus* = the post lifecycle |
| **Partner** | The store app (Hare-Store) and its users |
| **Bud** | Courier (driver app); not involved in the feed |
| **bydel** | City district (e.g. Møhlenpris, Sentrum); a filter on posts |
| **Skjult av Ærend** | "Hidden by Ærend": the honest status a store should see on a moderated post |
| **Moderering** | Moderation |
| **Til gjennomgang / Avvist / Publisert** | "Under review / Rejected / Published": Agent G screening statuses (support spec) |
| **Endre og send på nytt** | "Edit and resubmit" |
| **Trekk tilbake** | "Retract": pulling an agent-written post during its hold window |
| **Drift** | Operations; a `drift` post is an operational notice (exempt from the mix rule) |
| **Redaksjonelt / Kampanje** | Editorial / campaign (Ærend post kinds in Order Ops §16.2) |
| **Tilbud** | Offer (post type `tilbud`) |
| **Ny i hyllene / Nytt i hyllene** | "New on the shelves" (store type / Ærend round-up type) |
| **Dagens rett** | "Dish of the day" |
| **Bak disken / Åpent nå / Åpent sent** | "Behind the counter" / "Open now" / "Open late" |
| **Populært i kveld** | "Popular tonight" |
| **Butikk i fokus** | "Store spotlight" |
| **Ny på Ærend** | "New on Ærend" (a store went live) |
| **Historie / Historier** | Story / stories (24 h) |
| **Forundringspose** | Surprise bag |
| **Fjordfiske** | The fishing mini-game/promo in Utforsk |
| **Vågen** | "The bay": a once-a-day "reel in" moment in the feed that emits `suggestion.reeled` |
| **Legg til / Bestill** | Add (to basket) / Order |
| **Premiehylla, Gullbilletten, Nivå** | Points-programme terms (prize shelf, golden ticket, level); not part of the feed |
| **Nå** | "Now": the admin live-operations board |
| **Utboks** | Outbox (`ops_feed_outbox`) |
| **Publiseringstilgang** | Publishing access (the eligibility section in the admin feed page) |
| **førpris** | Reference "before" price; Norwegian price-marketing rules apply |

---

## Appendix: source index

**Feed service docs and config**
- [`Aerend-Feed/docs/ARCHITECTURE.md`](../../../../Aerend-Feed/docs/ARCHITECTURE.md) §1–6 (bridges, Cloudinary, data model, request lifecycle)
- [`Aerend-Feed/docs/FEED_SYSTEM.md`](../../../../Aerend-Feed/docs/FEED_SYSTEM.md) §2 (JWT bridge, ID mapping gotcha), §4 (DO infra), §6 (local dev), §7 (build log), §8 (roadmap)
- [`Aerend-Feed/docs/FEED_MASTER_PLAN.md`](../../../../Aerend-Feed/docs/FEED_MASTER_PLAN.md) §1–7
- [`Aerend-Feed/docs/FEED_LAUNCH_PLAN.md`](../../../../Aerend-Feed/docs/FEED_LAUNCH_PLAN.md) §1–2 (M1–M5), §8
- [`Aerend-Feed/docs/FEED_HANDOVER_10DAYS.md`](../../../../Aerend-Feed/docs/FEED_HANDOVER_10DAYS.md) §1 "Branches" (master auto-deploys), T1–T10
- [`Aerend-Feed/docs/LOCAL_DEV.md`](../../../../Aerend-Feed/docs/LOCAL_DEV.md) §3–8
- [`Aerend-Feed/README.md`](../../../../Aerend-Feed/README.md), [`do-app-platform.yaml`](../../../../Aerend-Feed/do-app-platform.yaml), [`Dockerfile`](../../../../Aerend-Feed/Dockerfile), [`docker-compose.yml`](../../../../Aerend-Feed/docker-compose.yml), [`docker-compose.dev.yml`](../../../../Aerend-Feed/docker-compose.dev.yml), [`.env.example`](../../../../Aerend-Feed/.env.example), [`.env.local.example`](../../../../Aerend-Feed/.env.local.example), [`.github/workflows/ci.yml`](../../../../Aerend-Feed/.github/workflows/ci.yml)
- [`scripts/seed-feed.ts`](../../../../Aerend-Feed/scripts/seed-feed.ts), [`scripts/seed-bergen-feed.ts`](../../../../Aerend-Feed/scripts/seed-bergen-feed.ts), [`scripts/sync-store-ids.ts`](../../../../Aerend-Feed/scripts/sync-store-ids.ts), [`scripts/trigger-store-sync.ts`](../../../../Aerend-Feed/scripts/trigger-store-sync.ts)

**Specs**
- [`aerendvstore feed update spec.md`](../../../docs/aerendvstore%20feed%20update%20spec.md) §1.1, §2.4, §3.1–3.2, §4.1–4.3, §5, §6
- [`AEREND ORDER OPS SPEC FINAL STATEv3.md`](../../../docs/AEREND%20ORDER%20OPS%20SPEC%20FINAL%20STATEv3.md) §2.1, §15, §16.1–16.8, §17.7 X1, §18.7
- [`AEREND AEGIL AGENT SPEC FINAL VERSION.md`](../../../docs/AEREND%20AEGIL%20AGENT%20SPEC%20FINAL%20VERSION.md) §5.1, Appendix flow ("Feed service ──feed.post.published (tilbud)──▶ signals")
- [`aerend-support-refunds-feed-spec.docx`](../../../docs/aerend-support-refunds-feed-spec.docx) §1, §4.1–4.5 (Agent G), §5, §6, §7 step 4, §8 Q6–Q7
- `aerend-ai-agents-spec.docx`, `aerend-support-system-spec.docx` (feed mentions only in passing)

**Plans**
- [`AGIL-1-PLAN.md`](../AGIL-1-PLAN.md) Phase 8 "Feed data layer…", Phase 9 "Feed publishing & oversight…", Phase 12 (T1, T2, T9, T10 pending)
- [`AGIL-1-PLAN-v2.md`](../AGIL-1-PLAN-v2.md) Phase 2 "Utforsk, the feed tabs, and the Hjem entry points"
- [`AGIL-1-REMAINING.md`](../AGIL-1-REMAINING.md) §3 "What you can and cannot reach today", §5 defect #2 (`WebhookSignalSource` table name), §8
- [`AGIL-CONTRACT.md`](../AGIL-CONTRACT.md) (file ownership; Aerend-Feed "never edit" for other branches), [`AGIL-UI-CONTRACT.md`](../AGIL-UI-CONTRACT.md) §5
- [`8-10-WEEK-IMPLEMENTATION-PLAN.md`](../8-10-WEEK-IMPLEMENTATION-PLAN.md) Phase 7.5, 8.1, 8.2, 8.3

**Laravel docs and tests**
- [`docs/FEED_JWT_KEYS.md`](../../../../Hare-AdminPanel/docs/FEED_JWT_KEYS.md), [`docs/EVENT_CONTRACT.md`](../../../../Hare-AdminPanel/docs/EVENT_CONTRACT.md) "Transport", "`feed.post.published`", "`suggestion.reeled`", "Guarantees"
- [`docs/OPS_API.md`](../../../../Hare-AdminPanel/docs/OPS_API.md) "Feed bridge", [`docs/OPS_ADMIN_GUIDE.md`](../../../../Hare-AdminPanel/docs/OPS_ADMIN_GUIDE.md) "Feed", [`docs/OPS_ROLLBACK.md`](../../../../Hare-AdminPanel/docs/OPS_ROLLBACK.md) (mentions `ops:feed-outbox --drain`, an option that does not exist)
- `tests/fixtures/contract/names.agil1.json`, `tests/fixtures/events/feed.post.published.json`, `product.price_changed.json`, `suggestion.reeled.json`

**Designs**
- [`Ærend leveranse 6 - Feed.dc.html`](../../../../designs/21des/%C3%86rend%20leveranse%206%20-%20Feed.dc.html) screens 6a, 6b, 6c, 6d (inside 6c), 6e, 6f, 6g
- [`Ærend Kunde Bergen.dc.html`](../../../../designs/21des/%C3%86rend%20Kunde%20Bergen.dc.html) `Utforsk-kort` (L2527, L2638), `erUtforsk` (~L4576), `Feed-media` (L4626), `feedFane` / `POSTER` (~L12495–12528)
- [`Ærend Partner.dc.html`](../../../../designs/21des/%C3%86rend%20Partner.dc.html) Butikk hub `feed` / `komponer` / `kampanje`, `sendTilScreening` / `feedStatus` (~L1361–1375), status sheet (~L2060)
- [`designs/21des/admin/screens-commercial.jsx`](../../../../designs/21des/admin/screens-commercial.jsx) `CFeedEdit` (L1081), `FeedMgmt` (L1933); [`screens-support.jsx`](../../../../designs/21des/admin/screens-support.jsx) `ModerationModule` (L312), `AgentGControl` (L420); `support-data.jsx`; `app.jsx` nav `c-feed`, `c-moderation`
