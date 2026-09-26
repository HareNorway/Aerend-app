import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/feed/feed_tab_item.dart';
import '../../../data/ops/butikk_models.dart';
import '../../../networking/feed/feed_repo.dart';
import '../../../networking/ops/ops_butikk_api.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../utils/utils.dart';
import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../../feed/postDetail/post_detail.dart';
import '../kit/bergen_kit.dart';
import 'feed_icons.dart';
import 'feed_post_card.dart';
import 'utforsk_copy.dart';

/// The Feed segment of Utforsk (`utfFeed` ≈L4402–4511 in `Ærend Kunde
/// Bergen.dc.html`): the category orbs, the active-filter chip, the pinned
/// «Ærend · Drift» notice, the post cards, the honest empty state, and the
/// Forundringspose promo at the bottom.
///
/// Data: `GET /v1/feed/tabs?tab=naerheten` through [FeedRepo] for the posts;
/// the shop's open state, delivery minutes and distance through
/// [OpsButikkApi.store]; the «Du bestilte …» hint from the customer's own
/// orders (`ops.customer.orders`); the promo bag from `GET /api/ops/products
/// ?kind=pose`. Every read degrades to "not shown" — a card never waits for
/// the monolith to answer before it renders.
class UtforskFeedTab extends StatefulWidget {
  const UtforskFeedTab({
    super.key,
    required this.bottomReserve,
    this.drift,
    this.onPostsLoaded,
    this.repo,
    this.api,
    this.butikkApi,
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

  /// The orbs (design `STORIES`), in order.
  static const List<String> orbs = [
    'alle',
    'restaurant',
    'fisk',
    'bakeri',
    'gront',
    'mote',
  ];

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
  Map<String, dynamic>? _promo;

  FeedRepo get _repo => widget.repo ?? FeedRepo();
  OpsCustomerApi get _api => widget.api ?? OpsCustomerApi();
  OpsButikkApi get _butikk => widget.butikkApi ?? OpsButikkApi();

  @override
  void initState() {
    super.initState();
    _load();
    _loadPromo();
    _loadOrders();
  }

  Future<void> _load() async {
    setState(() {
      _items = null;
      _error = false;
    });
    try {
      final page = await _repo.fetchFeedTab(tab: 'naerheten', limit: 30);
      if (!mounted) return;
      setState(() => _items = page.items);
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
    setState(() => _promo = list.first);
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
      final r = was
          ? await _repo.unlikePost(item.id)
          : await _repo.likePost(item.id);
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
      was
          ? UtforskCopy.a1_feed_unfollow_toast(store.name)
          : UtforskCopy.a1_feed_follow_toast(store.name),
    );
    try {
      final r = was
          ? await _repo.unfollowStore(store.id)
          : await _repo.followStore(store.id);
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
      BergenRoutes.push(
        context,
        '/bergen/butikk/${store.id}',
        arguments: {'name': store.name},
      );
      return;
    }
    openScreen(context, PostDetailScreen(postId: item.id));
  }

  void _comments(FeedTabItem item) {
    setState(() => _playing = null);
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
      BergenCart.add(
        context,
        storeId: storeId,
        productId: item.storeProductId!,
      );
      return;
    }
    _open(item);
  }

  // ── Build ───────────────────────────────────────────────────────────────

  List<FeedTabItem> get _visible {
    final all = _items ?? const [];
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
    final s = context.bs;
    final items = _items;
    final visible = _visible;

    return ListView(
      key: const Key('a1_feed_list'),
      padding: EdgeInsets.fromLTRB(
        16 * s,
        0,
        16 * s,
        widget.bottomReserve + 16 * s,
      ),
      children: [
        _orbRail(context),
        _filterRow(context),
        if (widget.drift != null) FeedDriftNotice(note: widget.drift!),
        if (items == null)
          Padding(
            padding: EdgeInsets.only(top: 40 * s),
            child: const Center(
              child: CircularProgressIndicator(color: BergenTokens.mint),
            ),
          )
        else if (visible.isEmpty)
          _empty(context)
        else
          for (final item in visible) _card(item),
        if (_promo != null) _promoCard(context, _promo!),
      ],
    );
  }

  Widget _card(FeedTabItem item) {
    final storeId = int.tryParse(item.store?.id ?? '') ?? 0;
    return FeedPostCard(
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
      onComments: () => _comments(item),
      onShare: () => _share(item),
      onFollow: () => _toggleFollow(item),
      onCta: () => _cta(item),
      onPlay: () => setState(() => _playing = item.id),
      onStop: () => setState(() => _playing = null),
    );
  }

  // ── Orbs ────────────────────────────────────────────────────────────────

  Widget _orbRail(BuildContext context) {
    final s = context.bs;
    return SizedBox(
      height: (14 + 52 + 6 + 16 + 16) * s,
      child: ListView(
        key: const Key('a1_utforsk_filters'),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 16 * s),
        children: [
          for (final slug in UtforskFeedTab.orbs) ...[
            _Orb(
              slug: slug,
              active: _filter == slug,
              hasNew: slug != 'alle' && _hasNewIn(slug),
              onTap: () => setState(() {
                _filter = _filter == slug ? 'alle' : slug;
                _playing = null;
              }),
            ),
            SizedBox(width: 12 * s),
          ],
        ],
      ),
    );
  }

  Widget _filterRow(BuildContext context) {
    final s = context.bs;
    if (_filter == 'alle') return SizedBox(height: 2 * s);
    return Padding(
      padding: EdgeInsets.fromLTRB(6 * s, 2 * s, 6 * s, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OnbPressable(
            key: const Key('a1_feed_filter_clear'),
            onTap: () => setState(() => _filter = 'alle'),
            pressDy: 0,
            pressScale: .96,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10 * s,
                vertical: 4 * s,
              ),
              decoration: BoxDecoration(
                color: const Color(0x295CE0B8),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0x805CE0B8)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    UtforskCopy.a1_feed_orb(_filter),
                    style: bText(
                      context,
                      11,
                      weight: FontWeight.w800,
                      color: BergenTokens.mint,
                    ),
                  ),
                  SizedBox(width: 5 * s),
                  feedIcon(FeedIcons.close, 10 * s),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty ───────────────────────────────────────────────────────────────

  Widget _empty(BuildContext context) {
    final s = context.bs;
    final String title, text, cta;
    final VoidCallback onCta;
    if (_error) {
      title = UtforskCopy.a1_feed_error_title;
      text = UtforskCopy.a1_feed_error_text;
      cta = UtforskCopy.a1_feed_retry;
      onCta = _load;
    } else if (_filter != 'alle') {
      title = UtforskCopy.a1_feed_empty_cat_title;
      text = UtforskCopy.a1_feed_empty_cat_text;
      cta = UtforskCopy.a1_feed_empty_cat_cta;
      onCta = () => setState(() => _filter = 'alle');
    } else {
      title = UtforskCopy.a1_feed_empty_title;
      text = UtforskCopy.a1_feed_empty_text;
      cta = UtforskCopy.a1_feed_empty_cta;
      onCta = _load;
    }

    return Container(
      key: const Key('a1_feed_empty'),
      margin: EdgeInsets.only(top: 14 * s),
      padding: EdgeInsets.fromLTRB(18 * s, 22 * s, 18 * s, 22 * s),
      decoration: _glass(24 * s),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22 * s),
            child: Image.asset(
              'assets/images/dashboard/find.png',
              width: 76 * s,
              height: 76 * s,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 10 * s),
          Text(
            title,
            textAlign: TextAlign.center,
            style: bDisplay(context, 15, weight: FontWeight.w800, height: 1.3),
          ),
          SizedBox(height: 4 * s),
          Text(
            text,
            textAlign: TextAlign.center,
            style: bText(
              context,
              12.5,
              weight: FontWeight.w500,
              color: const Color(0xFFDCE9EC),
            ),
          ),
          SizedBox(height: 12 * s),
          _OrangePill(label: cta, height: 42, onTap: onCta),
        ],
      ),
    );
  }

  // ── Promo (design `visPromo`) ───────────────────────────────────────────

  Widget _promoCard(BuildContext context, Map<String, dynamic> bag) {
    final s = context.bs;
    final priceKr = ((bag['price_ore'] as num?)?.toInt() ?? 0) ~/ 100;
    final valueKr = ((bag['value_ore'] as num?)?.toInt() ?? 0) ~/ 100;
    final left = (bag['left'] as num?)?.toInt();
    final window = bag['pickup_window']?.toString() ?? '';
    final label = [
      UtforskCopy.a1_utforsk_tab_pose.toUpperCase(),
      '${bag['store_name'] ?? bag['name'] ?? ''}'.toUpperCase(),
    ].where((e) => e.isNotEmpty).join(' · ');

    return OnbPressable(
      key: const Key('a1_feed_promo'),
      onTap: () => BergenRoutes.push(context, '/bergen/automat'),
      pressDy: 0,
      pressScale: .985,
      child: Container(
        margin: EdgeInsets.only(top: 12 * s),
        clipBehavior: Clip.antiAlias,
        decoration: _glass(20 * s),
        child: Stack(
          children: [
            Positioned(
              top: -30 * s,
              left: -20 * s,
              child: IgnorePointer(
                child: Container(
                  width: 160 * s,
                  height: 160 * s,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x595CE0B8), Color(0x005CE0B8)],
                      stops: [0, .7],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(14 * s),
              child: Row(
                children: [
                  _Bob(
                    child: bergenSvg('bag3d', width: 70 * s, height: 70 * s),
                  ),
                  SizedBox(width: 14 * s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bText(
                            context,
                            10.5,
                            weight: FontWeight.w800,
                            letterSpacingEm: .04,
                            color: const Color(0xFF9FE0C8),
                          ),
                        ),
                        SizedBox(height: 3 * s),
                        Text(
                          valueKr > 0
                              ? UtforskCopy.a1_feed_promo_price(
                                  priceKr,
                                  valueKr,
                                )
                              : UtforskCopy.a1_utforsk_pose_price(priceKr),
                          style: bDisplay(
                            context,
                            17,
                            weight: FontWeight.w800,
                            letterSpacingEm: -0.015,
                            height: 1.15,
                          ),
                        ),
                        if (window.isNotEmpty) ...[
                          SizedBox(height: 4 * s),
                          Text(
                            UtforskCopy.a1_utforsk_pose_pickup(window),
                            style: bText(
                              context,
                              12,
                              weight: FontWeight.w600,
                              color: const Color(0xFFDCE9EC),
                            ),
                          ),
                        ],
                        SizedBox(height: 10 * s),
                        Row(
                          children: [
                            _OrangePill(
                              label: UtforskCopy.a1_utforsk_promo_cta,
                              height: 36,
                              onTap: () =>
                                  BergenRoutes.push(context, '/bergen/automat'),
                            ),
                            if (left != null) ...[
                              SizedBox(width: 9 * s),
                              Flexible(
                                child: Text(
                                  UtforskCopy.a1_utforsk_promo_left(left),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: bText(
                                    context,
                                    11.5,
                                    weight: FontWeight.w700,
                                    color: const Color(0xFF9FD3DE),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bergenInsetTop(radius: 20 * s, alpha: .28),
          ],
        ),
      ),
    );
  }

  static BoxDecoration _glass(double radius) => BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x24FFFFFF), Color(0x0FFFFFFF)],
    ),
    border: Border.all(color: const Color(0x33FFFFFF)),
    boxShadow: const [
      BoxShadow(
        color: Color(0xD904121A),
        offset: Offset(0, 24),
        blurRadius: 40,
        spreadRadius: -22,
        blurStyle: BlurStyle.outer,
      ),
    ],
  );
}

// ── Orb ─────────────────────────────────────────────────────────────────────

/// One category orb (design `stories`): a 52px sphere on a teal gradient that
/// turns orange, lifts and grows when it is the filter, with the «nytt» dot
/// when a post in that category is from today.
class _Orb extends StatelessWidget {
  const _Orb({
    required this.slug,
    required this.active,
    required this.hasNew,
    required this.onTap,
  });

  final String slug;
  final bool active;
  final bool hasNew;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final duration = BergenTokens.motion(
      context,
      const Duration(milliseconds: 280),
    );
    const curve = Cubic(.3, 1.3, .5, 1);
    final label = UtforskCopy.a1_feed_orb(slug);

    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          key: Key('a1_feed_orb_$slug'),
          width: 66 * s,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSlide(
                offset: Offset(0, active ? -3 / 52 : 0),
                duration: duration,
                curve: curve,
                child: AnimatedScale(
                  scale: active ? 1.08 : 1,
                  duration: duration,
                  curve: curve,
                  child: AnimatedContainer(
                    duration: duration,
                    // The decoration lerps shadows; an overshooting curve
                    // would take a blur radius below zero mid-flight.
                    curve: Curves.easeOutCubic,
                    width: 52 * s,
                    height: 52 * s,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: active
                          ? const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFF9A273),
                                Color(0xFFF26D3D),
                                Color(0xFFDD5A25),
                              ],
                              stops: [0, .56, 1],
                            )
                          : const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF2A6272), Color(0xFF1E4F5C)],
                            ),
                      boxShadow: active
                          ? const [
                              BoxShadow(
                                color: Color(0xFF12333D),
                                spreadRadius: 3,
                              ),
                              BoxShadow(
                                color: Color(0x59000000),
                                spreadRadius: 4,
                              ),
                              BoxShadow(
                                color: Color(0xFFC4491A),
                                offset: Offset(0, 3),
                                spreadRadius: 3,
                              ),
                              BoxShadow(
                                color: Color(0xD9C8461A),
                                offset: Offset(0, 12),
                                blurRadius: 18,
                                spreadRadius: -6,
                                blurStyle: BlurStyle.outer,
                              ),
                            ]
                          : const [
                              BoxShadow(
                                color: Color(0xD90B262D),
                                offset: Offset(0, 2),
                                blurRadius: 1,
                                blurStyle: BlurStyle.outer,
                              ),
                              BoxShadow(
                                color: Color(0xBF0F2D37),
                                offset: Offset(0, 7),
                                blurRadius: 11,
                                spreadRadius: -5,
                                blurStyle: BlurStyle.outer,
                              ),
                            ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Center(child: feedIcon(FeedIcons.orb(slug), 26 * s)),
                        bergenInsetTop(radius: 999, alpha: active ? .45 : .28),
                        if (hasNew)
                          Positioned(
                            top: -2 * s,
                            right: -2 * s,
                            child: Container(
                              key: Key('a1_feed_orb_new_$slug'),
                              width: 14 * s,
                              height: 14 * s,
                              decoration: BoxDecoration(
                                color: BergenTokens.orange,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF12333D),
                                  width: 2.5,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xCCE95C2C),
                                    offset: Offset(0, 3),
                                    blurRadius: 6,
                                    spreadRadius: -2,
                                    blurStyle: BlurStyle.outer,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 6 * s),
              AnimatedDefaultTextStyle(
                duration: BergenTokens.motion(
                  context,
                  const Duration(milliseconds: 250),
                ),
                style: bText(
                  context,
                  11,
                  weight: FontWeight.w800,
                  color: active
                      ? const Color(0xFF7FF0CB)
                      : const Color(0x99FFFFFF),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Drift notice ────────────────────────────────────────────────────────────

/// The pinned «Ærend · Drift» notice (`visDrift`): the Æ tile, the title with
/// the gold «Festet til …» pill, the note, and the northern-lights streak the
/// design blurs across the top-left corner.
class FeedDriftNotice extends StatelessWidget {
  const FeedDriftNotice({super.key, required this.note});

  final Map<String, dynamic> note;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final until = '${note['pinned_until'] ?? ''}';
    return Container(
      key: const Key('a1_utforsk_drift'),
      margin: EdgeInsets.only(top: 12 * s),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF25606F), Color(0xFF1E4F5C), Color(0xFF173E48)],
          stops: [0, .6, 1],
        ),
        borderRadius: BorderRadius.circular(22 * s),
        border: Border.all(color: const Color(0x2EFFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0xB30F1F2B),
            offset: Offset(0, 20),
            blurRadius: 34,
            spreadRadius: -18,
            blurStyle: BlurStyle.outer,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -20 * s,
            top: -20 * s,
            child: IgnorePointer(
              child: Opacity(
                opacity: .4,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: SizedBox(
                    width: 360 * s,
                    height: 70 * s,
                    child: CustomPaint(painter: _StreakPainter()),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 12 * s),
            child: Row(
              children: [
                Container(
                  width: 40 * s,
                  height: 40 * s,
                  decoration: BoxDecoration(
                    color: const Color(0x24FFFFFF),
                    borderRadius: BorderRadius.circular(14 * s),
                    border: Border.all(color: const Color(0x47FFFFFF)),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      AerendBergenAuthTokens.mark,
                      width: 24 * s,
                      height: 15 * s,
                    ),
                  ),
                ),
                SizedBox(width: 12 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              UtforskCopy.a1_utforsk_drift_title,
                              style: bDisplay(
                                context,
                                14.5,
                                weight: FontWeight.w700,
                                color: BergenTokens.paper,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (until.isNotEmpty) ...[
                            SizedBox(width: 6 * s),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8 * s,
                                vertical: 2 * s,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x38F2C14E),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                UtforskCopy.a1_utforsk_drift_pinned(until),
                                style: bText(
                                  context,
                                  9.5,
                                  weight: FontWeight.w800,
                                  color: BergenTokens.lantern,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 2 * s),
                      Text(
                        '${note['note']}',
                        style: bText(
                          context,
                          12.5,
                          weight: FontWeight.w500,
                          color: const Color(0xFFDCE9EC),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bergenInsetTop(radius: 22 * s, alpha: .26),
        ],
      ),
    );
  }
}

/// `#nl-grad` (mint → violet) along the design's wavy path, 18px wide.
class _StreakPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 360, sy = size.height / 70;
    final path = Path()
      ..moveTo(0, 56 * sy)
      ..cubicTo(70 * sx, 22 * sy, 140 * sx, 48 * sy, 210 * sx, 18 * sy)
      ..cubicTo(260 * sx, -2 * sy, 310 * sx, 12 * sy, 360 * sx, -6 * sy);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18 * sy
      ..shader = const LinearGradient(
        colors: [Color(0xFF5CE0B8), Color(0xFF9C7BE8)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StreakPainter old) => false;
}

// ── Small pieces ────────────────────────────────────────────────────────────

/// The design's orange pill CTA with the 3D edge (`Hent posen`, the empty
/// state's button).
class _OrangePill extends StatelessWidget {
  const _OrangePill({
    required this.label,
    required this.height,
    required this.onTap,
  });

  final String label;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return OnbPressable(
      onTap: onTap,
      pressDy: 2,
      pressScale: .98,
      child: Container(
        height: height * s,
        padding: EdgeInsets.symmetric(horizontal: (height > 40 ? 18 : 15) * s),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)],
            stops: [0, .56, 1],
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x4DFFFFFF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x8CA03C14),
              offset: Offset(0, 3),
              blurRadius: 1,
              blurStyle: BlurStyle.outer,
            ),
            BoxShadow(
              color: Color(0xCCF26D3D),
              offset: Offset(0, 12),
              blurRadius: 22,
              spreadRadius: -10,
              blurStyle: BlurStyle.outer,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: bText(context, 12.5, weight: FontWeight.w800),
        ),
      ),
    );
  }
}

/// The design's `bob` keyframes (translateY 0 ↔ −5px over 4.4 s).
class _Bob extends StatefulWidget {
  const _Bob({required this.child});

  final Widget child;

  @override
  State<_Bob> createState() => _BobState();
}

class _BobState extends State<_Bob> with SingleTickerProviderStateMixin {
  AnimationController? _c;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) == true) {
      _c?.dispose();
      _c = null;
      return;
    }
    _c ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null) return widget.child;
    return AnimatedBuilder(
      animation: c,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -5 * Curves.easeInOut.transform(c.value)),
        child: child,
      ),
      child: widget.child,
    );
  }
}
