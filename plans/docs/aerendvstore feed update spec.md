**ÆREND**  
**Store App Update: Products, Prices, Surprise Bags & the Ærend Feed**

Developer Specification — Store app · Customer app · Admin panel

*Commercial side only (Ærend) — Hare-Store, Hare-Customer (commercial), Hare-AdminPanel, aerend-feed-service*

Ai Logistics AS · Org.nr. 936 971 857

# **Contents**

# **1\. Overview & Decisions**

The store app (Hare-Store) gains self-service management of products, prices, and surprise bags, plus the ability to publish product highlights to the Ærend feed. The customer app gains the feed itself, with content from two publisher types: stores and the Ærend team. The admin panel gains feed publishing/oversight and a product/price change log.

**This is the COMMERCIAL side (Ærend) only — no dugnad, STØ, points, or club mechanics anywhere in these features.**

## **1.1 Product-owner decisions (locked)**

| Decision | Choice |
| :---- | :---- |
| Store feed posts go live… | Immediately. The panel moderates AFTER the fact (hide/remove). |
| What stores publish | Product highlights/offers linked to their own products. |
| Product & price edits | Live immediately in the customer app; panel has oversight \+ full change log. |
| Ærend team publishing | The panel can also publish promotional product posts; the customer feed shows BOTH publisher types («Publisert av butikker» / «Publisert av Ærend» tabs). |

# **2\. Store App (Hare-Store)**

## **2.1 Product management (varer)**

* Create, edit, and archive products: name, description, image(s) (via existing media handling), category, price, availability (in stock / hidden).

* **Changes are live immediately** in the customer app — no approval step.

* **Every change is logged** (who, product, field, old → new, timestamp) to the change log the panel reads (§4.3).

## **2.2 Price editing**

* Edit price per product; same live-immediately \+ logged model. Price displayed to customers always renders from the product's CURRENT price.

## **2.3 Surprise bags (forundringsposer)**

* **Already specified in the Surprise Bags spec** (store self-service: quantity, price, category, pickup window, margin helper around the configurable fee). No changes here — this document only notes that bag management lives in the same store app alongside products and the feed.

## **2.4 Publish to the Ærend feed**

* Create a feed post: pick one of the store's own products, add a headline and short text; image defaults to the product image (custom image optional).

* **The post is linked to the product** — tapping it in the customer app opens the product (with live price).

* Live immediately on publish. The store sees its own posts (list), can unpublish/delete them, and sees if the panel has hidden one (status shown honestly: «Skjult av Ærend»).

| Offer posts & price-marketing rules (flag) If a post presents a DISCOUNT or 'before/after' price, Norwegian price-marketing rules apply (reference-price/førpris requirements, Forbrukertilsynet). Keep v1 simple: posts highlight a product at its current price. If discount framing is added later, it needs its own compliance pass — do not free-text 'før 199,-' claims. |
| :---- |

# **3\. Customer App — the Ærend Feed**

## **3.1 Structure (as prototyped)**

* **Two publisher tabs:** «Publisert av butikker» and «Publisert av Ærend».

* Category filter chips under the tabs (Alle, Restaurant, Mote, Mat & fisk, …) — the commercial categories, from config.

* Posts show: store name \+ avatar (or Ærend identity for panel posts), image, headline/text, linked product. Tap → product detail with live price. Default ordering: newest first within tab \+ filter.

* A stories-style row appears at the top of the prototype («Din historie», store names). Its scope is NOT settled — see open question \#1. Do not build stories until confirmed; the post feed is the v1 deliverable.

## **3.2 Behaviour**

* Hidden/removed posts disappear from the feed immediately (server-side status; client renders only live posts).

* Prices shown anywhere in the feed render from the product's current price — never a value frozen into the post (avoids stale-price claims when stores edit prices).

* Feed content is served by the existing aerend-feed-service; extend it rather than building a parallel path.

# **4\. Admin Panel**

## **4.1 Ærend team publishing**

* Compose promotional posts from the panel: pick any store's product to promote, headline, text, image; publish now or schedule. These appear under «Publisert av Ærend».

* Draft → scheduled → live → hidden/removed states; full list of Ærend posts with edit/unpublish.

## **4.2 Feed oversight (post-moderation)**

* All feed posts (both publisher types) in one view: filter by store, category, status, date.

* **Hide/remove any post** with a reason (logged). Takes effect immediately in the customer feed. The publishing store sees the honest status.

* Per-store feed eligibility toggle (default: eligible) — lets Ærend switch off publishing for a misbehaving store without touching their products.

## **4.3 Product & price oversight**

* Change log across stores: store, product, field, old → new, who, when. Filter \+ search.

* Panel can hide a product (compliance takeover) — same post-moderation philosophy as the feed.

## **4.4 Surprise bags**

* Oversight already covered by the Surprise Bags spec (fee config, eligibility, orders). Unchanged.

# **5\. Data Model (indicative — additive)**

| Entity / field | Purpose |
| :---- | :---- |
| product\_change\_log | store\_id, product\_id, field, old\_value, new\_value, changed\_by, changed\_at |
| feed\_post | publisher\_type (store | aerend), store\_id (nullable for aerend), product\_id, headline, body, image, category, status (draft/scheduled/live/hidden/removed), created\_by, created\_at, hidden\_reason |
| store\_feed\_eligibility | store\_id, enabled (default true) |

* Feed served via aerend-feed-service (TypeScript/Fastify) — extend the existing service. Panel and store app write through the existing API patterns; additive migrations only; reuse existing media/service methods.

# **6\. Open Questions**

| \# | Question |
| :---- | :---- |
| 1 | The stories row in the prototype («Din historie» \+ store avatars): who publishes stories, and is it v1 or later? Feed posts are the confirmed v1 scope. |
| 2 | Can stores EDIT a live post, or only unpublish and re-post? (Recommended v1: unpublish \+ re-post — simpler, cleaner audit.) |
| 3 | «Publisert av Ærend» ordering: purely chronological, or can the panel pin/curate? |
| 4 | Discount/offer framing in posts (førpris rules) — deferred until compliance pass (see §2.4 flag). |
| 5 | Should feed posts support multiple products per post, or exactly one? (Spec assumes one — the tap target stays unambiguous.) |

| The essence Stores manage products, prices, and surprise bags themselves, and publish product highlights that go live instantly; the Ærend team publishes its own promotions from the panel; customers see both in one feed with publisher tabs and category filters; and the panel holds the after-the-fact controls — hide any post, switch off a store's publishing, and audit every product and price change. |
| :---- |

