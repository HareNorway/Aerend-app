import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/feed/feed_tab_item.dart';
import '../../../data/ops/butikk_models.dart';
import '../../../networking/feed/feed_attribution.dart';
import '../../../networking/feed/feed_repo.dart';
import '../../../networking/ops/ops_butikk_api.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../utils/utils.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart';
import '../../feed/postDetail/post_detail.dart';
import '../hjem/hjem_harness.dart';
import '../kit/bergen_css.dart' show rgba;
import '../kit/bergen_kit.dart';
import 'feed_icons.dart';
import 'feed_post_card.dart';
import 'utforsk_bits.dart';
import 'utforsk_copy.dart';

/// The Feed segment of Utforsk (`utfFeed`, L5466–5590 in `Ærend Kunde
/// Launch.dc.html`, design px): the category orbs, the active-filter chip,
/// the pinned «Ærend · Drift» notice, the post cards, the honest empty state,
/// and the Forundringspose promo at the bottom.
///
/// Data: `GET /v1/feed/tabs` through [FeedRepo] for the posts (`naerheten`,
/// or `folger` / `fra_aerend` when [fane] says so — the prototype's
/// `feedFane`, reached from «Nytt fra butikkene du følger»); the shop's open
/// state, delivery minutes and distance through [OpsButikkApi.store]; the «Du
/// bestilte …» hint from the customer's own orders (`ops.customer.orders`);
/// the promo bag from `GET /api/ops/products?kind=pose`. Every read degrades
/// to "not shown" — a card never waits for the monolith before it renders.
///
/// In the Utforsk screen the tab is a sliver ([sliver]) under the segment
/// control, which scrolls with it as in the prototype (`data-utfscroll`).
class UtforskFeedTab extends StatefulWidget {
  const UtforskFeedTab({
    super.key,
    required this.bottomReserve,
    this.drift,
    this.onPostsLoaded,
    this.repo,
    this.api,
    this.butikkApi,
    this.sliver = false,
    this.fane = 'naer',
    this.onFane,
    this.segSeq = 0,
    this.segSince,
    this.segDir = -1,
    this.onPose,
  });

  /// Room for the bottom nav.
  final double bottomReserve;

  /// The Drift note from `OpsCustomerApi.driftNotice`, when there is one.
  final Map<String, dynamic>? drift;

  /// The first page, once — the segment's unread badge counts it.
  final ValueChanged<List<FeedTabItem>>? onPostsLoaded;

  /// Injected in tests.
  final FeedRepo? repo;
  final OpsCustomerApi? api;
  final OpsButikkApi? butikkApi;

  /// Build a sliver (inside Utforsk's scroll view) instead of a list.
  final bool sliver;

  /// `feedFane`: `naer` | `folger` | `aerend`.
  final String fane;

  /// The empty «Følger» state's «Se hva som er i nærheten».
  final ValueChanged<String>? onFane;

  /// The segment switch (`utfSeg`, L15225): bumped when the segment changes,
  /// with when and from which side, so the children slide in.
  final int segSeq;
  final DateTime? segSince;
  final int segDir;

  /// The promo's tap (Poseautomaten).
  final VoidCallback? onPose;

  /// The orbs (design `STORIES`), in order.
  static const List<String> orbs = [
    'alle',
    'restaurant',
    'fisk',
    'bakeri',
    'gront',
    'mote',
  ];

  /// `feedFane` → the feed service's tab slug.
  static String tabFor(String fane) => switch (fane) {
    'folger' => 'folger',
    'aerend' => 'fra_aerend',
    _ => 'naerheten',
  };

  @override
  State<UtforskFeedTab> createState() => _UtforskFeedTabState();
}

class _UtforskFeedTabState extends State<UtforskFeedTab> {
  List<FeedTabItem>? _items;
  bool _error = false;
  String _filter = 'alle';
  String? _playing;

  final Map<int, BergenStoreInfo> _stores = {};
  final Map<int, int> _orderedDaysAgo = {};
  final Map<String, bool> _liked = {};
  final Map<String, int> _likes = {};
  final Map<int, bool> _following = {};
  List<Map<String, dynamic>> _bags = const [];
  BergenStoreInfo? _promoStore;

  /// `feedBytt`: the posts leaving, then the new set's entrance.
  bool _leaving = false;
  int _postSeq = 0;
  DateTime? _postSince;
  Timer? _byttT;

  FeedRepo get _repo => widget.repo ?? FeedRepo();
  OpsCustomerApi get _api => widget.api ?? OpsCustomerApi();
  OpsButikkApi get _butikk => widget.butikkApi ?? OpsButikkApi();

  bool get _naer => widget.fane == 'naer';

  @override
  void initState() {
    super.initState();
    if (kDebugMode && HjemHarness.feedKat != null) _filter = HjemHarness.feedKat!;
    _load();
    _loadPromo();
    _loadOrders();
  }

  @override
  void didUpdateWidget(UtforskFeedTab old) {
    super.didUpdateWidget(old);
    if (old.fane != widget.fane) _load();
  }

  @override
  void dispose() {
    _byttT?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _items = null;
      _error = false;
    });
    try {
      final at = feedAddressLatLng();
      final page = await _repo.fetchFeedTab(tab: UtforskFeedTab.tabFor(widget.fane), limit: 30, lat: at?.lat, lng: at?.lng);
      if (!mounted) return;
      setState(() {
        _items = page.items;
        if (kDebugMode && HjemHarness.feedSpill != null) _playing = HjemHarness.feedSpill;
      });
      widget.onPostsLoaded?.call(page.items);
      unawaited(_loadStores(page.items));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _error = true;
      });
    }
  }

  /// One store read per shop on the page, in parallel; a failed read leaves
  /// that card without open state and distance rather than blocking it.
  Future<void> _loadStores(List<FeedTabItem> items) async {
    final ids = <int>{
      for (final i in items)
        if (i.store != null) int.tryParse(i.store!.id) ?? 0,
    }..remove(0);
    await Future.wait([
      for (final id in ids)
        _butikk.store(id).then((info) {
          if (info != null && mounted) setState(() => _stores[id] = info);
        }),
    ]);
  }

  Future<void> _loadOrders() async {
    final orders = await _api.orders(limit: 50);
    if (!mounted) return;
    final now = DateTime.now();
    for (final o in orders) {
      final store = o['store'];
      final id = store is Map
          ? int.tryParse('${store['id'] ?? store['store_id'] ?? ''}')
          : int.tryParse('${o['store_id'] ?? ''}');
      final at = DateTime.tryParse('${o['ordered_at'] ?? ''}');
      if (id == null || id == 0 || at == null) continue;
      final days = now.difference(at.toLocal()).inDays;
      final prev = _orderedDaysAgo[id];
      if (prev == null || days < prev) _orderedDaysAgo[id] = days;
    }
    setState(() {});
  }

  Future<void> _loadPromo() async {
    final list = await _api.poser();
    if (!mounted || list.isEmpty) return;
    setState(() => _bags = list);
    final id = (list.first['store_id'] as num?)?.toInt() ?? 0;
    if (id == 0) return;
    final info = await _butikk.store(id);
    if (mounted && info != null) setState(() => _promoStore = info);
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  Future<void> _toggleLike(FeedTabItem item) async {
    final was = _liked[item.id] ?? item.isLiked;
    final count = _likes[item.id] ?? item.likeCount;
    setState(() {
      _liked[item.id] = !was;
      _likes[item.id] = was ? count - 1 : count + 1;
    });
    try {
      final r = was ? await _repo.unlikePost(item.id) : await _repo.likePost(item.id);
      if (!mounted) return;
      setState(() {
        _liked[item.id] = r.isLiked;
        if (r.likeCount != null) _likes[item.id] = r.likeCount!;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _liked[item.id] = was;
        _likes[item.id] = count;
      });
    }
  }

  Future<void> _toggleFollow(FeedTabItem item) async {
    final store = item.store;
    if (store == null) return;
    final id = int.tryParse(store.id) ?? 0;
    final was = _following[id] ?? store.isFollowing;
    setState(() => _following[id] = !was);
    showBergenToast(
      context,
      was ? UtforskCopy.a1_feed_unfollow_toast(store.name) : UtforskCopy.a1_feed_follow_toast(store.name),
    );
    try {
      final r = was ? await _repo.unfollowStore(store.id) : await _repo.followStore(store.id);
      if (!mounted) return;
      setState(() => _following[id] = r.isFollowing);
    } catch (_) {
      if (!mounted) return;
      setState(() => _following[id] = was);
    }
  }

  void _open(FeedTabItem item) {
    setState(() => _playing = null);
    final store = item.store;
    if (store != null) {
      BergenRoutes.push(context, '/bergen/butikk/${store.id}', arguments: {'name': store.name});
      return;
    }
    openScreen(context, PostDetailScreen(postId: item.id));
  }

  void _share(FeedTabItem item) {
    Share.share(UtforskCopy.a1_feed_share_text(item.title, item.publisherName));
  }

  void _cta(FeedTabItem item) {
    final store = item.store;
    final storeId = int.tryParse(store?.id ?? '') ?? 0;
    final open = _stores[storeId]?.open ?? true;
    if (item.hasProduct && open) {
      // The order this basket becomes is counted on the post (Step 9).
      BergenCart.add(context, storeId: storeId, productId: item.storeProductId!).then((ok) {
        if (ok) FeedAttribution.remember(storeId: storeId, postId: item.id);
      });
      return;
    }
    _open(item);
  }

  /// `feedBytt` (L18518): the visible posts fade down and out (170 ms + 30 ms
  /// apart), then the new set glides in (460 ms, 40 + 70 ms apart).
  void _setFilter(String slug) {
    if (slug == _filter) return;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) == true;
    _byttT?.cancel();
    void bytt() {
      if (!mounted) return;
      setState(() {
        _filter = slug;
        _playing = null;
        _leaving = false;
        if (!reduce) {
          _postSeq++;
          _postSince = DateTime.now();
        }
      });
    }

    final visible = _visible.length;
    if (reduce || visible == 0) {
      bytt();
      return;
    }
    setState(() => _leaving = true);
    _byttT = Timer(Duration(milliseconds: 170 + math.min(visible - 1, 3) * 30), bytt);
  }

  // ── Build ───────────────────────────────────────────────────────────────

  List<FeedTabItem> get _visible {
    // The pinned drift post leads I nærheten (backend plan Step 9), but the
    // drift card above already shows it: not twice.
    final pinnedId = _naer ? '${widget.drift?['post_id'] ?? ''}' : '';
    final all = [
      for (final i in _items ?? const <FeedTabItem>[])
        if (pinnedId.isEmpty || i.id != pinnedId) i,
    ];
    if (_filter == 'alle') return all;
    return [
      for (final i in all)
        if (i.category == _filter) i,
    ];
  }

  bool _hasNewIn(String slug) {
    final all = _items ?? const [];
    return all.any((i) => i.category == slug && i.isFromToday);
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final visible = _visible;

    final children = <Widget>[
      _orbRail(context),
      _filterRow(),
      if (_naer && widget.drift != null) FeedDriftNotice(note: widget.drift!),
      if (items == null)
        const Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(child: CircularProgressIndicator(color: Color(0xFF5CE0B8))),
        )
      else if (visible.isEmpty)
        _empty()
      else
        for (var i = 0; i < visible.length; i++) _post(visible[i], i),
      if (_naer && _bags.isNotEmpty) _promoCard(_bags.first),
    ];

    // `utfSeg` (L15225): every child after the segment control slides in
    // from the side the segment came from, 45 ms apart (six at most).
    final wrapped = <Widget>[
      for (var i = 0; i < children.length; i++)
        UtfInn(
          seq: widget.segSeq,
          since: widget.segSince,
          delayMs: math.min(i, 6) * 45.0,
          durMs: 480,
          from: Offset(widget.segDir * 28.0, 10),
          scaleFrom: .97,
          opacityAt: .55,
          curve: const Cubic(.25, 1.15, .4, 1),
          child: i == 0 ? children[i] : Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: children[i]),
        ),
    ];

    if (widget.sliver) return SliverList(delegate: SliverChildListDelegate(wrapped));
    return ListView(
      key: const Key('a1_feed_list'),
      padding: EdgeInsets.only(bottom: widget.bottomReserve + 16),
      children: wrapped,
    );
  }

  Widget _post(FeedTabItem item, int i) {
    final storeId = int.tryParse(item.store?.id ?? '') ?? 0;
    return UtfUt(
      leaving: _leaving,
      index: i,
      child: UtfInn(
        seq: _postSeq,
        since: _postSince,
        delayMs: 40 + math.min(i, 4) * 70.0,
        durMs: 460,
        from: const Offset(0, 22),
        scaleFrom: .97,
        curve: const Cubic(.2, .9, .3, 1),
        child: FeedPostCard(
          key: ValueKey('card-${item.id}'),
          item: item,
          store: _stores[storeId],
          orderedDaysAgo: storeId == 0 ? null : _orderedDaysAgo[storeId],
          liked: _liked[item.id],
          likeCount: _likes[item.id],
          following: storeId == 0 ? null : _following[storeId],
          playing: _playing == item.id,
          onOpen: () => _open(item),
          onLike: () => _toggleLike(item),
          onShare: () => _share(item),
          onFollow: () => _toggleFollow(item),
          onCta: () => _cta(item),
          onPlay: () => setState(() => _playing = item.id),
          onStop: () => setState(() => _playing = null),
        ),
      ),
    );
  }

  // ── Orbs (L5466–5486) ───────────────────────────────────────────────────

  /// `margin: 6px -16px 0; padding: 14px 16px 16px` — the rail runs edge to
  /// edge; every other child sits inside the 16 px gutter.
  Widget _orbRail(BuildContext context) {
    return SizedBox(
      height: 6 + 14 + 52 + 6 + 15 + 16,
      child: ListView(
        key: const Key('a1_utforsk_filters'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6 + 14, 16, 16),
        children: [
          for (final slug in UtforskFeedTab.orbs) ...[
            UtfOrb(
              slug: slug,
              active: _filter == slug,
              hasNew: slug != 'alle' && _hasNewIn(slug),
              onTap: () => _setFilter(_filter == slug ? 'alle' : slug),
            ),
            if (slug != UtforskFeedTab.orbs.last) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }

  /// `filterPa`: the active category as a mint chip, ✕ clears it (L5487–5490).
  Widget _filterRow() {
    if (_filter == 'alle') return const SizedBox(height: 2);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            key: const Key('a1_feed_filter_clear'),
            onTap: () => _setFilter('alle'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: rgba(92, 224, 184, .16),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: rgba(92, 224, 184, .5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(UtforskCopy.a1_feed_orb(_filter), style: inter(11, weight: FontWeight.w800, color: const Color(0xFF5CE0B8))),
                  const SizedBox(width: 5),
                  feedIcon(FeedIcons.close, 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty (L5562–5569) ──────────────────────────────────────────────────

  Widget _empty() {
    final String title, text, cta;
    final VoidCallback onCta;
    if (_error) {
      title = UtforskCopy.a1_feed_error_title;
      text = UtforskCopy.a1_feed_error_text;
      cta = UtforskCopy.a1_feed_retry;
      onCta = _load;
    } else if (widget.fane == 'folger') {
      title = UtforskCopy.a1_feed_folger_tom_title;
      text = UtforskCopy.a1_feed_folger_tom_text;
      cta = UtforskCopy.a1_feed_empty_cta;
      onCta = () => widget.onFane?.call('naer');
    } else if (_filter != 'alle') {
      title = UtforskCopy.a1_feed_empty_cat_title;
      text = UtforskCopy.a1_feed_empty_cat_text;
      cta = UtforskCopy.a1_feed_empty_cat_cta;
      onCta = () => _setFilter('alle');
    } else {
      title = UtforskCopy.a1_feed_empty_title;
      text = UtforskCopy.a1_feed_empty_text;
      cta = UtforskCopy.a1_feed_empty_cta;
      onCta = widget.fane == 'naer' ? _load : () => widget.onFane?.call('naer');
    }

    return Padding(
      key: const Key('a1_feed_empty'),
      padding: const EdgeInsets.only(top: 14),
      child: CssBox(
        radius: BorderRadius.circular(24),
        bg: kFeedGlassBg,
        border: Border.all(color: rgba(255, 255, 255, .2)),
        shadows: [
          CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .28)),
          CssShadow(0, 24, 40, -22, rgba(4, 18, 26, .85)),
        ],
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: ColoredBox(
                color: rgba(255, 255, 255, .12),
                child: Image.asset('assets/images/dashboard/find.png', width: 76, height: 76, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: jakarta(15, height: 1.3)),
            const SizedBox(height: 4),
            Text(text, textAlign: TextAlign.center, style: inter(12.5, weight: FontWeight.w500, color: const Color(0xFFDCE9EC))),
            const SizedBox(height: 12),
            _OrangePill(label: cta, height: 42, padH: 18, onTap: onCta),
          ],
        ),
      ),
    );
  }

  // ── Promo (`visPromo`, L5570–5579) ──────────────────────────────────────

  Widget _promoCard(Map<String, dynamic> bag) {
    final priceKr = ((bag['price_ore'] as num?)?.toInt() ?? 0) ~/ 100;
    final valueKr = ((bag['value_ore'] as num?)?.toInt() ?? 0) ~/ 100;
    final store = '${bag['store_name'] ?? ''}';
    final label = [UtforskCopy.a1_utforsk_tab_pose.toUpperCase(), if (store.isNotEmpty) store.toUpperCase()].join(' · ');
    final hentes = utfPoseHentes(bag, _promoStore);
    final what = '${bag['description'] ?? ''}'.trim();
    final under = [if (what.isNotEmpty) what, if (hentes.isNotEmpty) hentes.toLowerCase()].join(' · ');

    return LfPress(
      key: const Key('a1_feed_promo'),
      onTap: widget.onPose ?? () => BergenRoutes.push(context, '/bergen/automat'),
      scale: .985,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: CssBox(
          radius: BorderRadius.circular(20),
          bg: kFeedGlassBg,
          border: Border.all(color: rgba(255, 255, 255, .2)),
          shadows: [
            CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .28)),
            CssShadow(0, 24, 40, -22, rgba(4, 18, 26, .85)),
          ],
          clip: true,
          child: Stack(
            children: [
              Positioned(
                top: -30,
                left: -20,
                child: IgnorePointer(
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [rgba(92, 224, 184, .35), rgba(92, 224, 184, 0)], stops: const [0, .7]),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // `bob 4.4s ease-in-out infinite`.
                    RepaintBoundary(
                      child: LfLoop(
                        frozenMs: 0,
                        builder: (context, t, child) => Transform.translate(
                          offset: Offset(0, kf((t % 4400) / 4400, const [0, .5, 1], const [0, -5, 0], cssEaseInOut)),
                          child: child,
                        ),
                        child: utfPose3d(70),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(10.5, weight: FontWeight.w800, em: .04, color: const Color(0xFF9FE0C8))),
                          const SizedBox(height: 3),
                          Text(
                            valueKr > 0 ? UtforskCopy.a1_feed_promo_price(priceKr, valueKr) : UtforskCopy.a1_utforsk_pose_price(priceKr),
                            style: jakarta(17, em: -0.015, height: 1.15),
                          ),
                          if (under.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(under, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(12, weight: FontWeight.w600, color: const Color(0xFFDCE9EC))),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _OrangePill(label: UtforskCopy.a1_utforsk_promo_cta, height: 36, padH: 15, onTap: widget.onPose ?? () => BergenRoutes.push(context, '/bergen/automat')),
                              const SizedBox(width: 9),
                              Flexible(
                                child: Text(
                                  UtforskCopy.a1_utforsk_promo_left(_bags.length),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: inter(11.5, weight: FontWeight.w700, color: const Color(0xFF9FD3DE)).copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()]),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «Hentes …» for a bag: the endpoint's pickup window when the store has ops
/// hours, else the store's own hours (`til 22:00` / `Åpner 10:00`).
String utfPoseHentes(Map<String, dynamic> bag, BergenStoreInfo? store) {
  final w = '${bag['pickup_window'] ?? ''}'.trim();
  if (w.isNotEmpty) return UtforskCopy.a1_utforsk_pose_pickup(w);
  if (store == null) return '';
  String hhmm(String t) => t.length >= 5 ? t.substring(0, 5) : t;
  if (store.open && (store.closeTime ?? '').isNotEmpty) return UtforskCopy.a1_pose_hentes_til(hhmm(store.closeTime!));
  if (!store.open && (store.openTime ?? '').isNotEmpty) return UtforskCopy.a1_pose_aapner(hhmm(store.openTime!));
  return store.open ? '' : UtforskCopy.a1_pose_stengt;
}

// ── Drift notice (`visDrift`, L5491–5500) ───────────────────────────────────

/// The pinned «Ærend · Drift» notice: the Æ tile, the title with the gold
/// «Festet til …» pill, the note, and the northern-lights streak blurred
/// across the top-left corner.
class FeedDriftNotice extends StatelessWidget {
  const FeedDriftNotice({super.key, required this.note});

  final Map<String, dynamic> note;

  @override
  Widget build(BuildContext context) {
    final until = '${note['pinned_until'] ?? ''}';
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: CssBox(
        key: const Key('a1_utforsk_drift'),
        radius: BorderRadius.circular(22),
        bg: const [
          CssLinear(160, [Color(0xFF25606F), Color(0xFF1E4F5C), Color(0xFF173E48)], [0, .6, 1]),
        ],
        border: Border.all(color: rgba(255, 255, 255, .18)),
        shadows: [
          CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .26)),
          CssShadow(0, 20, 34, -18, rgba(15, 31, 43, .7)),
        ],
        clip: true,
        child: Stack(
          children: [
            Positioned(
              left: -20,
              top: -20,
              child: IgnorePointer(
                child: Opacity(
                  opacity: .4,
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: const SizedBox(width: 360, height: 70, child: CustomPaint(painter: _StreakPainter())),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  CssBox(
                    width: 40,
                    height: 40,
                    radius: BorderRadius.circular(14),
                    bg: [CssSolid(rgba(255, 255, 255, .14))],
                    border: Border.all(color: rgba(255, 255, 255, .28)),
                    shadows: [CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .3))],
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/svgs/dashboard/ae_mark.svg',
                        width: 24,
                        height: 15,
                        colorFilter: const ColorFilter.mode(Color(0xFFF5F3EF), BlendMode.srcIn),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                UtforskCopy.a1_utforsk_drift_title,
                                overflow: TextOverflow.ellipsis,
                                style: jakarta(14.5, weight: FontWeight.w700, color: const Color(0xFFF5F3EF)),
                              ),
                            ),
                            if (until.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: rgba(242, 193, 78, .22), borderRadius: BorderRadius.circular(999)),
                                child: Text(
                                  UtforskCopy.a1_utforsk_drift_pinned(until),
                                  style: inter(9.5, weight: FontWeight.w800, color: const Color(0xFFF2C14E)),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${note['note']}',
                          style: inter(12.5, weight: FontWeight.w500, height: 1.4, color: const Color(0xFFDCE9EC)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `#nl-grad` (mint → violet) along the design's wavy path, 18 px wide.
class _StreakPainter extends CustomPainter {
  const _StreakPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 56)
      ..cubicTo(70, 22, 140, 48, 210, 18)
      ..cubicTo(260, -2, 310, 12, 360, -6);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..shader = const LinearGradient(colors: [Color(0xFF5CE0B8), Color(0xFF9C7BE8)]).createShader(Offset.zero & size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StreakPainter old) => false;
}

/// The design's orange pill with the 3D edge (`Hent posen`, the empty
/// state's button).
class _OrangePill extends StatelessWidget {
  const _OrangePill({required this.label, required this.height, required this.padH, required this.onTap});

  final String label;
  final double height;
  final double padH;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final big = height > 40;
    return LfPress(
      onTap: onTap,
      dy: 2,
      scale: .98,
      child: CssBox(
        height: height,
        radius: BorderRadius.circular(height / 2),
        padding: EdgeInsets.symmetric(horizontal: padH),
        bg: const [
          CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1]),
        ],
        border: big ? null : Border.all(color: rgba(255, 255, 255, .3)),
        shadows: [
          CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .45)),
          CssShadow(0, 3, 0, 0, rgba(160, 60, 20, .55)),
          big ? CssShadow(0, 12, 22, -10, rgba(242, 109, 61, .8)) : CssShadow(0, 10, 18, -8, rgba(242, 109, 61, .8)),
        ],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(12.5, weight: FontWeight.w800)))],
        ),
      ),
    );
  }
}
