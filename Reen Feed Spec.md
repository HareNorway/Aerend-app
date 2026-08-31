**Link for the UI in Figma:**

[**https://www.figma.com/design/xwc4Ir6CGg954Yxaj1HpeY/HARE-Project?node-id=9380-46541\&p=f\&t=N7yg2UmqaOlpQdNL-0**](https://www.figma.com/design/xwc4Ir6CGg954Yxaj1HpeY/HARE-Project?node-id=9380-46541&p=f&t=N7yg2UmqaOlpQdNL-0) 

**REEN**

**Reen Feed**

In-App Social Commerce Feature

Developer Specification & Product Logic

Version 1.0  ·  2026  ·  Confidential

# **1\. Overview & Strategic Purpose**

Reen Feed is a native in-app social commerce layer built directly into the Reen platform. It gives partner stores (restaurants, shops, and other businesses) a free, built-in marketing channel to reach customers — without relying on Instagram, TikTok, or paid advertising on external platforms.

| 📣  The core insight: stores already pay for marketing elsewhere. Reen Feed gives them a free, high-intent alternative — their audience is already in the app ready to order. Every post is a direct path to purchase. |
| :---- |

## **1.1 What Reen Feed Is**

Reen Feed is best understood as a purpose-built combination of Instagram and TikTok, but embedded inside a delivery and commerce app. Stores publish content. Customers discover and engage with that content. Every interaction is designed to drive purchase — not just passive engagement.

## **1.2 Who Can Do What**

| Action | Store (Store App) | Customer (Customer App) |
| :---- | :---: | :---: |
| Publish posts (photo/video) | ✅ Yes | ❌ No |
| Publish Stories | ✅ Yes | ❌ No |
| Publish Reels | ✅ Yes | ❌ No |
| Go Live (livestream) | ✅ Yes | ❌ No |
| View feed & content | ❌ No | ✅ Yes |
| Follow stores | ❌ No | ✅ Yes |
| Like & comment on posts | ❌ No | ✅ Yes |
| Send DMs to stores | ❌ No | ✅ Yes |
| Receive & reply to DMs | ✅ Yes | ❌ No |
| Tap CTA → visit store | — | ✅ Yes |
| View store profile & grid | ✅ Own profile | ✅ Yes |

# **2\. Store Profile**

Every partner store has a public profile page on Reen Feed — similar to an Instagram business profile. This is distinct from their ordering store page, but linked to it.

## **2.1 Profile Page Elements**

| Feature | Description |
| :---- | :---- |
| **Profile photo** | Store logo or photo, circular, displayed prominently at top |
| **Store name** | Full store name with verified badge if applicable |
| **Bio / Description** | Short text description of the store (editable from store app) |
| **Stats row** | Three counters: Posts · Followers · Following (stores can follow other stores) |
| **Follow button** | Customers tap to follow/unfollow the store |
| **Message button** | Opens a direct message thread to the store |
| **Visit Store button** | Deep-links the customer directly to the store's ordering page in Reen |
| **Content grid** | Scrollable grid of all published posts (photos and reels thumbnails) |
| **Stories row** | Active story bubbles shown at top of profile when stories are live |
| **Recommended section** | Algorithm-suggested content shown below the grid: 'Suggested For You' |

| The store profile is the store's permanent brand presence inside Reen. It should feel as polished and complete as an Instagram business page. |
| :---- |

# **3\. Content Types — Store App (Publishing Side)**

Stores can publish four types of content, all from the store app. Each content type has its own creation flow.

| 3.1  Posts (Photo / Static Video) |
| :---- |

A standard post is one or more photos or a short video, with a caption and optional tags. This is the baseline content format.

### **Creation flow (as seen in designs):**

1. Store taps 'New Post' from their feed/profile

2. Selects media from camera roll or takes new photo/video

3. Writes a caption (bildetekst) with support for tags and hashtags

4. Optional: Add Music — choose from the in-app music library

5. Optional: Tag People / other stores

6. Optional: Add Location — searchable location picker

7. Sets audience (public / followers only)

8. Taps 'Del' (Share) to publish — or 'Lagre Utkast' (Save Draft)

### **Post features:**

* Caption with hashtag and mention support

* Music overlay selected from in-app library

* Location tag displayed on the post

* CTA button on each post: tapping opens the store in the Reen ordering app

* Save as draft — publish later

* AI-generated label option ('Merk som Laget med KI') visible in designs

| 3.2  Stories |
| :---- |

Stories are full-screen, ephemeral content that disappear after 24 hours. They are displayed as circular bubbles at the top of the feed and on the store's profile. The designs show a rich creation flow identical to Instagram Stories.

### **Creation flow:**

9. Store opens camera in Story mode

10. Captures photo or video (with timer and speed controls visible in designs)

11. Edits using the sticker/label toolbar

12. Sets audience: 'Din Historie' or 'Nære Venner' (close friends list)

13. Taps 'Del' to publish to followers

### **Interactive sticker types (visible in designs):**

* Sted (Location tag)

* Område (Area/region tag)

* Din Tur (Your Turn — call to action prompt)

* Spørsmål (Question box — followers can ask questions)

* GIF (animated sticker from library)

* Avatar (personalised avatar sticker)

* Musikk (Music sticker with visible waveform)

* Din Tur-Maler (Templates for 'your turn' challenges)

* Utklipp (Clip/cut-out sticker)

* Meningssamling (Poll / opinion collector)

* Quiz (Multiple choice quiz sticker)

* Expression (Emoji/reaction sticker)

* Lenke (Clickable link — for directing to store or product)

* Emneknagg (Hashtag sticker)

* Bidrag (Contribution / fundraiser sticker)

* Bilde (Photo sticker from camera roll)

* Text overlay with font and colour options

| Stories are the highest-frequency, most casual content format. Stores should be encouraged to post daily Stories as a low-effort way to stay top-of-mind with followers. |
| :---- |

| 3.3  Reels (Short-Form Video) |
| :---- |

Reels are short vertical videos, displayed in a TikTok-style full-screen scroll in the customer app. They are the highest-engagement format and should be prioritised in the feed algorithm.

### **Creation flow:**

14. Store opens camera in Reels mode (distinct from Story mode in the nav bar)

15. Records video in segments — can record multiple clips that are stitched together

16. Selects background music from the in-app library (with waveform preview)

17. Adjusts playback speed (visible in designs: speed controls)

18. Trims video clips in the video-cut editor

19. Sets a cover thumbnail ('Rediger Forside') — choose frame from video or upload separate image

20. Writes caption, tags location, sets audience

21. Option to also share to Story simultaneously

22. Taps 'Del' to publish

### **Reels features:**

* Multi-clip recording with stitching

* In-app music library with search and featured tracks

* Import own audio option

* Speed control (slow-motion / fast-forward)

* Cover/thumbnail editor

* Caption with hashtags and location

* Save as draft

* AI-generated label toggle

* CTA button visible on reel in customer feed — taps directly to store ordering page

| 3.4  Live Streaming |
| :---- |

Live streaming allows stores to broadcast in real time to their followers. As seen in the designs, live streams support product showcasing with an overlay card — this is the 'live shopping' feature. Viewers can comment in real time.

### **Live stream features:**

* Real-time video broadcast to all followers (and discoverable to non-followers)

* Live comment stream visible on screen

* Product card overlay: store can pin a specific product during the stream with name, price, and a 'See Product' CTA button that opens the product in the Reen ordering app

* Viewer count displayed

* Store can end the broadcast and optionally save the recording

| Live shopping is a powerful conversion tool. A store can demonstrate a dish being prepared, show a new product, and viewers can tap 'Buy' without leaving the stream. This is the killer feature of Reen Feed. |
| :---- |

# **4\. Customer App — Reen Feed Experience**

From the customer's perspective, Reen Feed is accessed via a dedicated 'Reen Feed' button on the home screen. The customer cannot publish content — they are a consumer and engager only.

## **4.1 Home Feed**

The main feed is a chronological or algorithm-ranked vertical scroll of posts from stores the customer follows, plus suggested content from stores they don't yet follow.

### **Feed structure (top to bottom):**

* Stories row at the top — circular avatars of stores with active stories. Tap to view full-screen

* Post cards in vertical scroll — photo or video posts with store avatar, name, caption, and action buttons

* Like, comment, share, and save buttons on each post

* CTA button on each post — taps through to the store's ordering page

* Reels are surfaced inline in the feed and also accessible via dedicated Reels tab

## **4.2 Reels Tab**

A dedicated full-screen vertical scroll of Reels content — identical UX to TikTok or Instagram Reels. Swipe up to advance to the next reel.

### **Reels player elements (visible in designs):**

* Full-screen vertical video

* Store name and follow button overlaid at bottom

* Caption text overlaid at bottom left

* Music name with rotating disc icon

* Like, comment, share, and save buttons on right side

* CTA button — direct link to the store

* Comment section slides up from bottom (tap comments icon)

## **4.3 Explore / Search**

The Explore section allows customers to discover new stores they don't yet follow.

* Grid layout of content from all stores (not just followed)

* Search bar — search by store name or category

* Search results show store cards with name, category, rating, and distance

* Tapping a search result opens the store's Reen Feed profile

## **4.4 Viewing Stories**

Stories are viewed full-screen, one store at a time. Tap right to advance, tap left to go back, swipe down to close.

* Progress bar at top shows time remaining for each story frame

* Store name and timestamp shown top left

* Like button and reply/message field at bottom

* Share button to forward the story to other users via WhatsApp, copy link, or in-app DM

* External links in stories open in in-app browser

## **4.5 Direct Messages (DM)**

Customers can send messages directly to any store. This is a key support and discovery channel.

### **From the customer side:**

* Tap the 'Message' button on any store's profile to open a DM thread

* Can also reply to a Story directly, which sends a DM

* Can share a post into a DM thread

* Chat supports text and image sharing

### **From the store side (Store App):**

* DM inbox shows all incoming conversations from customers

* Stories viewers are shown at top of inbox for quick access

* Store can reply with text or images

* Conversations are threaded per customer

| DM is the primary customer support tool within Reen Feed. Stores should respond promptly. A future version may include automated quick-reply templates. |
| :---- |

## **4.6 Following & Followers**

Customers build a personalised feed by following the stores they care about.

* Follow / Unfollow button on every store profile and in search results

* Follower and following counts displayed on store profile

* Stores can view their follower list (folgere) from the store app

* Stores can also follow other stores (visible in designs: 'folger' from a store's perspective)

# **5\. Notifications**

The notification system keeps customers engaged and drives return visits. The designs show a 'Forinstady Store' notification screen with categorised tabs.

## **5.1 Notification Types**

| Feature | Description |
| :---- | :---- |
| **New post from followed store** | Push notification when a store you follow publishes a new post or reel |
| **New story live** | Push notification when a followed store posts a new story |
| **Livestream started** | Push notification when a followed store goes live |
| **Comment reply** | Notification when someone replies to your comment on a post |
| **New follower (store)** | Store receives notification when a customer follows them |
| **New DM** | Notification for both customer and store when a new message arrives |
| **Story reply** | Store notified when a customer replies to their story |

## **5.2 Notification Centre**

The notification screen (as seen in designs) has tabs: Alle (All) · Personer Du Følger (People You Follow) · Kommentarer (Comments). Each notification shows avatar, description, timestamp, and a thumbnail of the relevant post.

# **6\. Architecture & Integration Notes**

| ⚠️  Critical: Reen Feed is a new module built on top of the existing Reen platform. It shares user accounts, store profiles, and the ordering system — but it is an entirely new content layer. Plan the data model accordingly. |
| :---- |

## **6.1 Data Separation**

* Store feed profile is linked to (but separate from) the store's ordering profile

* Posts, stories, and reels are stored independently from the ordering catalogue

* Follow relationships are a new data entity — not related to order history

* DMs are a new messaging layer — separate from any existing order communication

## **6.2 The CTA Link — Core Integration Point**

The most important integration between Reen Feed and the ordering system is the CTA (Call to Action) button. This button appears on every post, reel, and story and directs the customer straight to the store's ordering page within the Reen app.

* Each store profile has a permanent 'Visit Store' CTA

* Individual posts can have a product-specific CTA (linking to a specific item)

* Live streams support a pinned product CTA that updates in real time

* The link must deep-link within the app — not open a browser

## **6.3 Media Infrastructure**

* Video storage and streaming must support both short-form (Reels) and long-form (Live) video

* Stories require automatic deletion after 24 hours

* Music library must be licensed — use an existing licensed library API (e.g. Epidemic Sound or similar)

* Image and video compression on upload to manage bandwidth and storage costs

## **6.4 Feed Algorithm (v1 — Simple)**

For v1, keep the algorithm simple and predictable:

* Content from followed stores appears in chronological order

* Suggested / explore content is ranked by recency and engagement (likes \+ comments)

* Reels tab surfaces all published reels, most recent first

* Live streams are always surfaced at the top of the feed while active

| A personalisation algorithm (based on viewing time, tap-through rate, purchase history) can be introduced in a later version. Do not over-engineer the feed for v1. |
| :---- |

# **7\. Summary — What Needs to Be Built**

| Store App — New Features |
| :---- |

* Feed profile page: bio, photo, stats, content grid

* Post creation flow: photo/video, caption, music, location, audience, draft, publish

* Story creation flow: camera, sticker toolkit (all sticker types listed in section 3.2), audience selector, share

* Reels creation flow: multi-clip recording, music, speed, trim, cover, caption, publish

* Live streaming: broadcast, real-time comments, product card overlay with price and CTA

* DM inbox: view all customer conversations, reply with text and images

* Notifications: new followers, new DMs, story replies

| Customer App — New Features |
| :---- |

* 'Reen Feed' entry point on the home screen (prominent button/tab)

* Home feed: stories row \+ chronological post scroll from followed stores

* Post interaction: like, comment, share, CTA tap-through to store ordering page

* Reels tab: full-screen vertical video scroll with all reel controls

* Explore / Search: store discovery by name and category

* Story viewer: full-screen, progress bar, reply, share

* Store profile view: bio, stats, follow button, message button, visit store CTA, content grid

* DM: start conversation with any store, receive replies

* Follow/unfollow stores, view follower and following lists

* Notifications: new posts, stories, live alerts, comment replies, DM

| Backend & Infrastructure |
| :---- |

* Content data model: posts, stories (with 24h TTL), reels, live sessions

* Follow relationship model: customer → store

* DM messaging system: threaded conversations per customer-store pair

* Feed API: followed-store content endpoint \+ explore/discover endpoint

* Notification service: push notifications for all trigger types in section 5

* Media storage: image hosting, video storage and streaming, 24h auto-delete for stories

* Music library integration: licensed audio API

* Live streaming infrastructure: real-time video broadcast and comment stream

* CTA deep-link system: post/reel/story → store ordering page within app

| Questions or clarifications? Raise them before starting implementation. Reen Feed is a significant new product surface. Agree on the v1 scope before writing any code — start with Posts and Stories, then layer in Reels and Live in subsequent releases if needed. |
| :---- |

