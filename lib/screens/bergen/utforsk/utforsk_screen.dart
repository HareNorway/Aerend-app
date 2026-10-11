import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../data/feed/feed_tab_item.dart';
import '../../../networking/feed/feed_repo.dart';
import '../../../networking/ops/ops_butikk_api.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../utils/utils.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/homeMainV1/home_main_v1.dart';
import '../../common/home/bergen/bergen_nav.dart';
import '../aegil/aegil_guide.dart';
import '../hjem/hjem_harness.dart';
import '../kit/bergen_css.dart' show rgba;
import '../kit/bergen_kit.dart';
import 'feed_icons.dart';
import 'feed_tab.dart';
import 'pose_segment.dart';
import 'utforsk_copy.dart';

/// `utforsk` (L5456–5713 in `Ærend Kunde Launch.dc.html`, design px) — tab 1
/// of the shell, and `/bergen/utforsk` (`?tab=fiske|pose`, `&fane=folger`).
///
/// The title stays put; under it one scroll (`data-utfscroll`) carries the
/// segment control and the segment's content. Three segments behind one
/// orange thumb: **Feed** ([UtforskFeedTab]), **Fjordfiske** (a door — the
/// prototype's `segFiske` opens the game at once, and the lit segment stays
/// over the Feed content, `utfFeed: seg !== 'pose'`) and **Forundringspose**
/// ([UtforskPoseSegment], the way to Poseautomaten). Changing segment slides
/// the content in from the side the new segment is on (L15225).
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

  /// Inside the shell (no back button, the shell's nav below).
  final bool embedded;

  static const String tabFeed = 'feed';
  static const String tabFiske = 'fiske';
  static const String tabPose = 'pose';


  /// One-shot: the segment the next Utforsk opens on (Hjem's raft and
  /// Forundringspose card — `scenePose` / `poseFn`).
  static String? apneSegment;

  /// The category orbs (design `STORIES`), by slug.
  static const List<String> filters = UtforskFeedTab.orbs;

  @override
  State<UtforskScreen> createState() => _UtforskScreenState();
}

class _UtforskScreenState extends State<UtforskScreen> {
  late String _tab;
  String _fane = 'naer';
  int _unread = 0;
  bool _routeRead = false;
  List<FeedTabItem> _posts = const [];

  Map<String, dynamic>? _drift;

  int _segSeq = 0;
  DateTime? _segSince;
  int _segDir = -1;

  final ScrollController _scroll = ScrollController();

  OpsCustomerApi get _api => widget.api ?? OpsCustomerApi();

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab ?? UtforskScreen.apneSegment ?? UtforskScreen.tabFeed;
    UtforskScreen.apneSegment = null;
    _loadDrift();
    _loadUnread();
    if (kDebugMode) _harness();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeRead) return;
    _routeRead = true;
    final args = BergenRoutes.argsOf(context);
    if (widget.initialTab == null) {
      final fromRoute = args['tab'];
      if (fromRoute != null && fromRoute.isNotEmpty) _tab = fromRoute;
    }
    final fane = args['fane'];
    if (fane != null && fane.isNotEmpty) _fane = fane;
    // `?tab=fiske` (the Hjem card, Meg's rows): the game opens over Utforsk,
    // as the design's `tilFjordfiske` does.
    if (_tab == UtforskScreen.tabFiske) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) BergenRoutes.push(context, '/bergen/fjordfiske');
      });
    }
  }

  @override
  void dispose() {
    // Leaving Utforsk counts as having seen the feed.
    if (_posts.isNotEmpty) _feed.markSeen().catchError((_) {});
    _scroll.dispose();
    super.dispose();
  }

  /// Debug builds: `hjem_state.json` keys (see [HjemHarness]).
  void _harness() {
    if (HjemHarness.utfSeg case final seg?) _tab = seg;
    if (HjemHarness.feedFane case final f?) _fane = f;
    if (HjemHarness.feedDrift) {
      // The prototype's own note, for comparing the card; no API carries one.
      _drift = const {'note': 'Mye regn i kveld — vi legger 5 min på alle tider.', 'pinned_until': '20:00'};
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (HjemHarness.automat) {
        _tilAutomat();
        return;
      }
      if (HjemHarness.utfScroll case final y?) {
        await Future<void>.delayed(const Duration(milliseconds: 1600));
        if (mounted && _scroll.hasClients) _scroll.jumpTo(y.clamp(0, _scroll.position.maxScrollExtent));
      }
    });
  }

  Future<void> _loadDrift() async {
    final note = await _api.driftNotice();
    if (!mounted || note == null) return;
    setState(() => _drift = note);
  }

  void _select(String tab) {
    if (tab == UtforskScreen.tabFiske) {
      // Design `segFiske`: the segment lights up and the game opens — every
      // tap, also when it is already the lit segment.
      if (_tab != tab) setState(() => _tab = tab);
      BergenRoutes.push(context, '/bergen/fjordfiske');
      return;
    }
    if (tab == UtforskScreen.tabFeed) _markFeedSeen();
    if (tab == _tab) return;
    final fromPose = _tab == UtforskScreen.tabPose;
    final toPose = tab == UtforskScreen.tabPose;
    setState(() {
      _tab = tab;
      if (fromPose != toPose) {
        _segSeq++;
        _segSince = DateTime.now();
        _segDir = toPose ? 1 : -1;
      }
    });
  }

  FeedRepo get _feed => widget.feedRepo ?? FeedRepo();

  /// `feedUlest`: posts published since the feed was last read, counted by
  /// the feed service (backend plan Step 9) so every device agrees. No
  /// answer, no badge.
  Future<void> _loadUnread() async {
    try {
      final at = feedAddressLatLng();
      final r = await _feed.fetchUnread(lat: at?.lat, lng: at?.lng);
      if (mounted) setState(() => _unread = r.unread);
    } catch (_) {}
  }

  /// `segFeed` / `tilFeed` set `feedLest`: the badge goes.
  void _markFeedSeen() {
    _feed.markSeen().catchError((_) {});
    if (_unread != 0) setState(() => _unread = 0);
  }

  void _onPostsLoaded(List<FeedTabItem> posts) {
    if (mounted) setState(() => _posts = posts);
  }

  Future<void> _tilAutomat() async {
    final r = await BergenRoutes.push<dynamic>(context, '/bergen/automat');
    if (!mounted) return;
    final shell = _shell;
    // A bag may have gone into the basket while the machine was up.
    shell?.badgeCountNotifier.value = prefGetInt(prefCartCount);
    if (r is int && r >= 0) shell?.switchToTab(r);
    if (r == 'sok') shell?.openSearchTab();
  }

  HomeMainV1State? get _shell => context.findAncestorStateOfType<HomeMainV1State>();

  @override
  Widget build(BuildContext context) {
    final isPose = _tab == UtforskScreen.tabPose;
    final newest = _posts.isEmpty ? null : _posts.first;

    return Scaffold(
      backgroundColor: const Color(0xFF173E48),
      body: LfFrame(
        child: Builder(
          builder: (context) {
            final mq = MediaQuery.of(context);
            final top = mq.padding.top;
            final bottom = widget.embedded ? 130.0 + mq.padding.bottom * .5 : 40 + mq.padding.bottom;
            final body = CssBox(
              bg: const [
                CssRadial([Color.fromRGBO(255, 255, 255, .22), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .6], rx: .8, ry: .5, cx: .14, cy: 0),
                CssLinear(180, [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)], [0, .42, 1]),
              ],
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: top,
                    height: 52,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: Row(
                        children: [
                          if (!widget.embedded && Navigator.of(context).canPop())
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => Navigator.of(context).pop(),
                              child: const Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                              ),
                            ),
                          Text(
                            UtforskCopy.a1_utforsk_title,
                            key: const Key('a1_utforsk_title'),
                            style: jakarta(20, em: -0.025),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: top + 56,
                    bottom: 0,
                    child: CustomScrollView(
                      key: const Key('a1_utforsk_scroll'),
                      controller: _scroll,
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverToBoxAdapter(
                            child: _Segments(active: _tab, unread: _unread, onSelect: _select),
                          ),
                        ),
                        // The feed keeps its state while the bag segment is up.
                        SliverVisibility(
                          visible: !isPose,
                          maintainState: true,
                          sliver: UtforskFeedTab(
                            sliver: true,
                            bottomReserve: 0,
                            drift: _drift,
                            fane: _fane,
                            onFane: (f) => setState(() => _fane = f),
                            onPostsLoaded: _onPostsLoaded,
                            repo: widget.feedRepo,
                            api: widget.api,
                            butikkApi: widget.butikkApi,
                            segSeq: _segSeq,
                            segSince: _segSince,
                            segDir: _segDir,
                            onPose: _tilAutomat,
                          ),
                        ),
                        if (isPose)
                          UtforskPoseSegment(
                            api: widget.api,
                            butikkApi: widget.butikkApi,
                            newest: newest == null ? null : UtforskCopy.a1_pose_feed_linje(newest.publisherName, newest.title),
                            unread: _unread,
                            segSeq: _segSeq,
                            segSince: _segSince,
                            onAutomat: _tilAutomat,
                            onFeed: () {
                              _markFeedSeen();
                              setState(() {
                                _tab = UtforskScreen.tabFeed;
                                _fane = 'naer';
                                _segSeq++;
                                _segSince = DateTime.now();
                                _segDir = -1;
                              });
                            },
                            onMeg: () => _shell?.switchToTab(BergenTab.me.index),
                            onPremier: () => BergenRoutes.push(context, '/bergen/premiehylla'),
                          ),
                        SliverToBoxAdapter(child: SizedBox(height: bottom)),
                      ],
                    ),
                  ),
                  // The Ægil-guide (L9495) — Utforsk's three tips.
                  Positioned.fill(child: AegilGuide(skjerm: 'utforsk', tips: aegilGuideTips('utforsk'), nav: widget.embedded)),
                ],
              ),
            );
            if (widget.embedded) return body;
            // `skjermInn .34s cubic-bezier(.2,.9,.3,1)` when pushed.
            return LfOnce(
              ms: 340,
              child: body,
              builder: (context, t, child) {
                final p = (t / 340).clamp(0.0, 1.0);
                final k = const Cubic(.2, .9, .3, 1).transform(p);
                return Opacity(
                  opacity: kf(p, const [0, .55], const [0, 1], const Cubic(.2, .9, .3, 1)),
                  child: Transform.translate(
                    offset: Offset(0, 14 * (1 - k)),
                    child: Transform.scale(scale: .978 + .022 * k, child: child),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ── Segmented control (L5462–5466) ──────────────────────────────────────────

/// Three segments (flex 1 / 1 / 1.25, 3 px apart) in a sunken pill, one
/// orange thumb gliding under them (`left`/`width .5s cubic-bezier(.3,1.2,
/// .4,1)`); the lit label white, the others `rgba(255,255,255,.6)` (`.35s`);
/// the Feed segment carries the unread count.
class _Segments extends StatelessWidget {
  const _Segments({required this.active, required this.unread, required this.onSelect});

  final String active;
  final int unread;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, String, double)>[
      (UtforskScreen.tabFeed, UtforskCopy.a1_utforsk_tab_feed, FeedIcons.segFeed, 1),
      (UtforskScreen.tabFiske, UtforskCopy.a1_utforsk_tab_fiske, FeedIcons.segFiske, 1),
      (UtforskScreen.tabPose, UtforskCopy.a1_utforsk_tab_pose, FeedIcons.segPose, 1.25),
    ];
    final index = items.indexWhere((e) => e.$1 == active).clamp(0, 2);
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) == true;

    return CssBox(
      radius: BorderRadius.circular(999),
      padding: const EdgeInsets.all(3),
      bg: [CssSolid(rgba(0, 0, 0, .28))],
      border: Border.all(color: rgba(255, 255, 255, .12)),
      shadows: [CssShadow.inset(0, 2, 4, 0, rgba(0, 0, 0, .35))],
      child: LayoutBuilder(
        builder: (context, c) {
          // `W = calc(100% - 12px)` of the 1px-bordered box; one flex unit W/3.25.
          final unit = (c.maxWidth - 6) / 3.25;
          final left = [0.0, unit + 3, unit * 2 + 6][index];
          final width = index == 2 ? unit * 1.25 : unit;
          return SizedBox(
            height: 38,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: Duration(milliseconds: reduce ? 0 : 500),
                  curve: const Cubic(.3, 1.2, .4, 1),
                  left: left,
                  top: 0,
                  bottom: 0,
                  width: width,
                  child: CssBox(
                    radius: BorderRadius.circular(999),
                    bg: const [
                      CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1]),
                    ],
                    shadows: [
                      CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .4)),
                      CssShadow(0, 4, 10, -4, rgba(242, 109, 61, .9)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(width: 3),
                      Expanded(
                        flex: (items[i].$4 * 100).round(),
                        child: _Segment(
                          id: items[i].$1,
                          label: items[i].$2,
                          icon: items[i].$3,
                          on: active == items[i].$1,
                          badge: items[i].$1 == UtforskScreen.tabFeed ? unread : 0,
                          onTap: () => onSelect(items[i].$1),
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

class _Segment extends StatefulWidget {
  const _Segment({required this.id, required this.label, required this.icon, required this.on, required this.badge, required this.onTap});

  final String id;
  final String label;
  final String icon;
  final bool on;
  final int badge;
  final VoidCallback onTap;

  @override
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) == true;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        // `style-active="transform:scale(.96)"`, `.45s cubic-bezier(.3,1.4,.5,1)`.
        scale: _down ? .96 : 1,
        duration: Duration(milliseconds: reduce ? 0 : (_down ? 120 : 450)),
        curve: _down ? cssEase : const Cubic(.3, 1.4, .5, 1),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: widget.on ? 1 : 0),
          duration: Duration(milliseconds: reduce ? 0 : 350),
          curve: cssEase,
          builder: (context, k, _) {
            final c = Color.lerp(rgba(255, 255, 255, .6), Colors.white, k)!;
            return Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    feedIcon(widget.icon, 13, color: c),
                    const SizedBox(width: 5),
                    Text(widget.label, key: Key('a1_utforsk_tab_${widget.id}'), style: inter(12, weight: FontWeight.w800, color: c)),
                    if (widget.badge > 0) ...[
                      const SizedBox(width: 5),
                      Container(
                        key: const Key('a1_utforsk_feed_unread'),
                        constraints: const BoxConstraints(minWidth: 17),
                        height: 17,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF26D3D),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [BoxShadow(color: Colors.white, spreadRadius: 1.5)],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${widget.badge}',
                          style: inter(9.5, weight: FontWeight.w800).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
