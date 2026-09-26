import 'package:flutter/material.dart';

import '../../../data/feed/feed_tab_item.dart';
import '../../../data/ops/fiske_models.dart';
import '../../../networking/feed/feed_repo.dart';
import '../../../networking/ops/ops_butikk_api.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../utils/utils.dart';
import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../../common/home/bergen/bergen_nav.dart';
import '../../common/home/bergen/bergen_painters.dart';
import '../kit/bergen_kit.dart';
import 'feed_icons.dart';
import 'feed_tab.dart';
import 'utforsk_copy.dart';

/// `utforsk` (≈L4389–4635 in `Ærend Kunde Bergen.dc.html`) — tab 1 of the
/// shell, and `/bergen/utforsk` (`?tab=feed|fiske|pose`).
///
/// Three segments behind one orange thumb: **Feed** ([UtforskFeedTab]: the
/// category orbs, the pinned Drift notice, the post cards and the bag promo),
/// **Fjordfiske** (a landing card — the game itself is agil-3's
/// `/bergen/fjordfiske`) and **Forundringspose** (bags from
/// `GET /api/ops/products?kind=pose`, and the way to Poseautomaten).
class UtforskScreen extends StatefulWidget {
  const UtforskScreen({
    super.key,
    this.initialTab,
    this.api,
    this.feedRepo,
    this.butikkApi,
    this.embedded = true,
  });

  /// Injected in tests: the feed service and the store reads behind the cards.
  final FeedRepo? feedRepo;
  final OpsButikkApi? butikkApi;

  /// `feed` | `fiske` | `pose`; overrides the route's `?tab=`.
  final String? initialTab;

  /// Injected in tests.
  final OpsCustomerApi? api;

  /// Inside the shell (no back button, nav reserve at the bottom).
  final bool embedded;

  static const String tabFeed = 'feed';
  static const String tabFiske = 'fiske';
  static const String tabPose = 'pose';

  /// Pref: when the Feed segment was last opened — the unread badge counts
  /// posts newer than this.
  static const String prefFeedSeenAt = 'a1_utforsk_feed_seen_at';

  /// The category orbs (design `STORIES`), by slug.
  static const List<String> filters = UtforskFeedTab.orbs;

  @override
  State<UtforskScreen> createState() => _UtforskScreenState();
}

class _UtforskScreenState extends State<UtforskScreen> {
  late String _tab;
  int _unread = 0;
  bool _routeRead = false;

  List<Map<String, dynamic>>? _poser;
  Map<String, dynamic>? _drift;

  /// `ops.customer.fiske`: the daily-catch cap the landing card shows as
  /// «N napp igjen i dag» — the same count the earn endpoint caps on. Null
  /// (offline, guest) hides the chip rather than inventing a number.
  FiskeDay? _fiskeDay;

  OpsCustomerApi get _api => widget.api ?? OpsCustomerApi();

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab ?? UtforskScreen.tabFeed;
    _loadDrift();
    _loadFiskeDay();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeRead) return;
    _routeRead = true;
    if (widget.initialTab == null) {
      final fromRoute = BergenRoutes.argsOf(context)['tab'];
      if (fromRoute != null && fromRoute.isNotEmpty) _tab = fromRoute;
    }
    if (_tab == UtforskScreen.tabPose) _loadPoser();
    if (_tab == UtforskScreen.tabFeed) _markFeedSeen();
  }

  Future<void> _loadDrift() async {
    final note = await _api.driftNotice();
    if (!mounted || note == null) return;
    setState(() => _drift = note);
  }

  Future<void> _loadFiskeDay() async {
    final day = await _api.fiske();
    if (!mounted || day == null) return;
    setState(() => _fiskeDay = day);
  }

  Future<void> _loadPoser() async {
    final list = await _api.poser();
    if (!mounted) return;
    setState(() => _poser = list);
  }

  void _select(String tab) {
    if (tab == _tab) return;
    setState(() => _tab = tab);
    if (tab == UtforskScreen.tabPose && _poser == null) _loadPoser();
    if (tab == UtforskScreen.tabFeed) _markFeedSeen();
  }

  void _markFeedSeen() {
    prefSetString(
      UtforskScreen.prefFeedSeenAt,
      DateTime.now().toIso8601String(),
    );
    if (_unread != 0) setState(() => _unread = 0);
  }

  /// `feedUlest`: posts published since the Feed segment was last open.
  void _onPostsLoaded(List<FeedTabItem> posts) {
    final raw = prefGetString(UtforskScreen.prefFeedSeenAt);
    final seenAt = raw.isEmpty ? null : DateTime.tryParse(raw);
    var unread = 0;
    for (final p in posts) {
      if (seenAt == null || (p.publishedAt?.isAfter(seenAt) ?? true)) unread++;
    }
    if (_tab == UtforskScreen.tabFeed) {
      _markFeedSeen();
      return;
    }
    if (unread != _unread && mounted) setState(() => _unread = unread);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final safeTop = MediaQuery.paddingOf(context).top;
    final bottomReserve = widget.embedded
        ? bergenNavReserve(context)
        : MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: BergenTokens.teal,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: kBergenScreenGradient),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: bergenRadial(
                  center: const Offset(.14, 0),
                  radii: const Offset(.8, .5),
                  colors: const [Color(0x38FFFFFF), Color(0x00FFFFFF)],
                  stops: const [0, .6],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: safeTop,
              height: 52 * s,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20 * s, 14 * s, 20 * s, 0),
                child: Row(
                  children: [
                    if (!widget.embedded && Navigator.of(context).canPop())
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(context).pop(),
                        child: Padding(
                          padding: EdgeInsets.only(right: 10 * s),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 22 * s,
                          ),
                        ),
                      ),
                    Text(
                      UtforskCopy.a1_utforsk_title,
                      key: const Key('a1_utforsk_title'),
                      style: bDisplay(
                        context,
                        20,
                        weight: FontWeight.w800,
                        color: Colors.white,
                      ).copyWith(letterSpacing: -0.5),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: safeTop + 56 * s,
              bottom: 0,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16 * s),
                    child: _Segments(
                      active: _tab,
                      unread: _unread,
                      onSelect: _select,
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: BergenTokens.motion(
                        context,
                        BergenTokens.motionBase,
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(_tab),
                        child: switch (_tab) {
                          UtforskScreen.tabFiske => _FiskeTab(
                            bottomReserve: bottomReserve,
                            nappLeft: _fiskeDay?.left,
                          ),
                          UtforskScreen.tabPose => _PoseTab(
                            poser: _poser,
                            bottomReserve: bottomReserve,
                          ),
                          _ => UtforskFeedTab(
                            drift: _drift,
                            onPostsLoaded: _onPostsLoaded,
                            bottomReserve: bottomReserve,
                            repo: widget.feedRepo,
                            api: widget.api,
                            butikkApi: widget.butikkApi,
                          ),
                        },
                      ),
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

// ── Segmented control ─────────────────────────────────────────────────────

class _Segments extends StatelessWidget {
  const _Segments({
    required this.active,
    required this.unread,
    required this.onSelect,
  });

  final String active;
  final int unread;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final items = <(String, String, String, double)>[
      (UtforskScreen.tabFeed, UtforskCopy.a1_utforsk_tab_feed, FeedIcons.segFeed, 1),
      (
        UtforskScreen.tabFiske,
        UtforskCopy.a1_utforsk_tab_fiske,
        FeedIcons.segFiske,
        1,
      ),
      (
        UtforskScreen.tabPose,
        UtforskCopy.a1_utforsk_tab_pose,
        FeedIcons.segPose,
        1.25,
      ),
    ];
    final index = items.indexWhere((e) => e.$1 == active);
    final total = items.fold<double>(0, (a, e) => a + e.$4);

    return Container(
      padding: EdgeInsets.all(3 * s),
      decoration: BoxDecoration(
        color: const Color(0x47000000),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            offset: Offset(0, 2),
            blurRadius: 4,
            blurStyle: BlurStyle.inner,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth - 3 * s * 2;
          double left = 0;
          for (var i = 0; i < index; i++) {
            left += w * items[i].$4 / total + 3 * s;
          }
          final thumbW = w * items[index < 0 ? 0 : index].$4 / total;
          return SizedBox(
            height: 38 * s,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: BergenTokens.motion(
                    context,
                    const Duration(milliseconds: 500),
                  ),
                  curve: const Cubic(.3, 1.2, .4, 1),
                  left: left,
                  top: 0,
                  bottom: 0,
                  width: thumbW,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFF9A273),
                                Color(0xFFF26D3D),
                                Color(0xFFDD5A25),
                              ],
                              stops: [0, .56, 1],
                            ),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xE6F26D3D),
                                offset: Offset(0, 4),
                                blurRadius: 10,
                                spreadRadius: -4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      bergenInsetTop(radius: 999, alpha: .4),
                    ],
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) SizedBox(width: 3 * s),
                      Expanded(
                        flex: (items[i].$4 * 100).round(),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onSelect(items[i].$1),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  feedIcon(
                                    items[i].$3,
                                    13 * s,
                                    color: active == items[i].$1
                                        ? Colors.white
                                        : const Color(0x99FFFFFF),
                                  ),
                                  SizedBox(width: 5 * s),
                                  Text(
                                    items[i].$2,
                                    key: Key('a1_utforsk_tab_${items[i].$1}'),
                                    style: bText(
                                      context,
                                      12,
                                      weight: FontWeight.w800,
                                      color: active == items[i].$1
                                          ? Colors.white
                                          : const Color(0x99FFFFFF),
                                    ),
                                  ),
                                  if (items[i].$1 == UtforskScreen.tabFeed &&
                                      unread > 0) ...[
                                    SizedBox(width: 5 * s),
                                    Container(
                                      key: const Key('a1_utforsk_feed_unread'),
                                      constraints: BoxConstraints(
                                        minWidth: 17 * s,
                                      ),
                                      height: 17 * s,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 5 * s,
                                      ),
                                      decoration: BoxDecoration(
                                        color: BergenTokens.orange,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '$unread',
                                        style: bText(
                                          context,
                                          9.5,
                                          weight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Fjordfiske tab ────────────────────────────────────────────────────────

class _FiskeTab extends StatelessWidget {
  const _FiskeTab({required this.bottomReserve, this.nappLeft});

  final double bottomReserve;

  /// Daily catches left (`ops.customer.fiske`); null hides the chip.
  final int? nappLeft;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16 * s,
        12 * s,
        16 * s,
        bottomReserve + 16 * s,
      ),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6 * s),
          child: Text(
            UtforskCopy.a1_utforsk_fiske_intro,
            style: bText(
              context,
              12,
              weight: FontWeight.w600,
              color: const Color(0xFFDCE9EC),
            ),
          ),
        ),
        SizedBox(height: 10 * s),
        OnbPressable(
          onTap: () => BergenRoutes.push(context, '/bergen/fjordfiske'),
          pressScale: .985,
          child: Container(
            key: const Key('a1_utforsk_fiske_landing'),
            constraints: BoxConstraints(minHeight: 168 * s),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26 * s),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF7F3EA),
                  Color(0xFFDCE9EC),
                ],
                stops: [0, .52, 1],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x73231D1D),
                  offset: Offset(0, 18),
                  blurRadius: 26,
                  spreadRadius: -14,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 58 * s,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(26 * s),
                      ),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x003A7D8C), Color(0x8C2E6978)],
                      ),
                    ),
                  ),
                ),
                for (final (right, bottom, asset) in [
                  (104.0, 34.0, 'ico_fisk'),
                  (70.0, 40.0, 'ico_gaver'),
                  (36.0, 34.0, 'ico_mat'),
                ])
                  Positioned(
                    right: right * s,
                    bottom: bottom * s,
                    child: Container(
                      width: 46 * s,
                      height: 62 * s,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10 * s),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFFE9E2D2)],
                        ),
                        border: Border.all(color: const Color(0xF2FFFFFF)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x991E4F5C),
                            offset: Offset(0, 10),
                            blurRadius: 18,
                            spreadRadius: -8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: bergenSvg(asset, width: 28 * s, height: 26 * s),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 16 * s),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Text(
                              'Fjordfiske',
                              style: bDisplay(
                                context,
                                18,
                                weight: FontWeight.w800,
                                color: BergenTokens.ink,
                              ),
                            ),
                            if (nappLeft != null) ...[
                              SizedBox(width: 7 * s),
                              Container(
                                key: const Key('a1_utforsk_fiske_napp'),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8 * s,
                                  vertical: 3 * s,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0x241E4F5C),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  UtforskCopy.a1_utforsk_fiske_napp(nappLeft!),
                                  style: bText(
                                    context,
                                    9.5,
                                    weight: FontWeight.w800,
                                    color: BergenTokens.teal,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 3 * s),
                      SizedBox(
                        width: 180 * s,
                        child: Text(
                          UtforskCopy.a1_utforsk_fiske_line,
                          style: bText(
                            context,
                            11.5,
                            weight: FontWeight.w600,
                            color: const Color(0xFF4E5A5E),
                          ),
                        ),
                      ),
                      SizedBox(height: 12 * s),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: BergenCta3d(
                          label: UtforskCopy.a1_utforsk_fiske_cta,
                          expand: false,
                          onPressed: () =>
                              BergenRoutes.push(context, '/bergen/fjordfiske'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Forundringspose tab ───────────────────────────────────────────────────

class _PoseTab extends StatelessWidget {
  const _PoseTab({required this.poser, required this.bottomReserve});

  final List<Map<String, dynamic>>? poser;
  final double bottomReserve;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final list = poser;
    final left =
        list?.fold<int>(0, (a, p) => a + ((p['left'] as num?)?.toInt() ?? 0)) ??
        0;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16 * s,
        14 * s,
        16 * s,
        bottomReserve + 16 * s,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                UtforskCopy.a1_utforsk_pose_title,
                style: bDisplay(
                  context,
                  15.5,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            if (left > 0)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 9 * s,
                  vertical: 3 * s,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x2E5CE0B8),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x805CE0B8)),
                ),
                child: Text(
                  UtforskCopy.a1_utforsk_pose_left_today(left),
                  style: bText(
                    context,
                    10,
                    weight: FontWeight.w800,
                    color: BergenTokens.mint,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 4 * s),
        Text(
          UtforskCopy.a1_utforsk_pose_line,
          style: bText(
            context,
            12,
            weight: FontWeight.w500,
            color: const Color(0xFFDCE9EC),
          ),
        ),
        SizedBox(height: 12 * s),
        if (list == null)
          Padding(
            padding: EdgeInsets.all(24 * s),
            child: const Center(
              child: CircularProgressIndicator(color: BergenTokens.mint),
            ),
          )
        else if (list.isEmpty)
          BergenCard(
            key: const Key('a1_utforsk_pose_empty'),
            onDark: true,
            child: Text(
              UtforskCopy.a1_utforsk_pose_empty,
              style: bText(
                context,
                12.5,
                weight: FontWeight.w600,
                color: const Color(0xFFDCE9EC),
              ),
            ),
          )
        else
          for (final p in list) ...[
            _PoseCard(pose: p),
            SizedBox(height: 10 * s),
          ],
        SizedBox(height: 4 * s),
        OnbPressable(
          onTap: () => BergenRoutes.push(context, '/bergen/automat'),
          pressScale: .985,
          child: Container(
            key: const Key('a1_utforsk_automat'),
            padding: EdgeInsets.all(14 * s),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x29FFFFFF), Color(0x12FFFFFF)],
              ),
              borderRadius: BorderRadius.circular(18 * s),
              border: Border.all(color: const Color(0x73F2C14E)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.casino_rounded,
                  color: BergenTokens.lantern,
                  size: 28 * s,
                ),
                SizedBox(width: 12 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        UtforskCopy.a1_utforsk_automat,
                        style: bText(
                          context,
                          12.5,
                          weight: FontWeight.w800,
                          color: BergenTokens.paper,
                        ),
                      ),
                      Text(
                        UtforskCopy.a1_utforsk_automat_line(99),
                        style: bText(
                          context,
                          11,
                          weight: FontWeight.w600,
                          color: const Color(0xFF9FD3DE),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: const Color(0x8CFFFFFF),
                  size: 20 * s,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PoseCard extends StatelessWidget {
  const _PoseCard({required this.pose});

  final Map<String, dynamic> pose;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final left = (pose['left'] as num?)?.toInt();
    final valueKr = (pose['value_ore'] as num?)?.toInt();
    final priceKr = ((pose['price_ore'] as num?)?.toInt() ?? 0) ~/ 100;
    final window = pose['pickup_window']?.toString();
    final storeId = (pose['store_id'] as num?)?.toInt() ?? 0;
    final productId = int.tryParse('${pose['id']}') ?? 0;

    return BergenCard(
      onDark: true,
      padding: EdgeInsets.all(14 * s),
      child: Row(
        children: [
          Container(
            width: 56 * s,
            height: 56 * s,
            decoration: BoxDecoration(
              color: const Color(0x2E5CE0B8),
              borderRadius: BorderRadius.circular(16 * s),
            ),
            child: Icon(
              Icons.shopping_bag_rounded,
              color: BergenTokens.mint,
              size: 28 * s,
            ),
          ),
          SizedBox(width: 12 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (left != null)
                  Text(
                    UtforskCopy.a1_utforsk_pose_left(left),
                    style: bText(
                      context,
                      10,
                      weight: FontWeight.w800,
                      color: BergenTokens.mint,
                    ),
                  ),
                Text(
                  '${pose['store_name'] ?? pose['name'] ?? ''}',
                  style: bDisplay(
                    context,
                    15,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  [
                    '${pose['name'] ?? ''}',
                    if (valueKr != null)
                      UtforskCopy.a1_utforsk_pose_value(valueKr ~/ 100),
                  ].join(' · '),
                  style: bText(
                    context,
                    11.5,
                    weight: FontWeight.w600,
                    color: const Color(0xFFDCE9EC),
                  ),
                ),
                if (window != null && window.isNotEmpty)
                  Text(
                    UtforskCopy.a1_utforsk_pose_pickup(window),
                    style: bText(
                      context,
                      11,
                      weight: FontWeight.w600,
                      color: const Color(0xFF9FD3DE),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 10 * s),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                UtforskCopy.a1_utforsk_pose_price(priceKr),
                style: bDisplay(
                  context,
                  16,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 6 * s),
              BergenCta3d(
                label: UtforskCopy.a1_utforsk_pose_secure,
                expand: false,
                onPressed: () => BergenCart.add(
                  context,
                  storeId: storeId,
                  productId: productId,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
