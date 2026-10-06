import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/ops/butikk_models.dart';
import '../../../data/points/points_models.dart';
import '../../../networking/ops/ops_butikk_api.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart';
import '../kit/bergen_css.dart' show rgba;
import '../meg/a3_services.dart';
import 'feed_icons.dart';
import 'feed_tab.dart' show utfPoseHentes;
import 'utforsk_bits.dart';
import 'utforsk_copy.dart';

/// The Forundringspose segment of Utforsk (`utfPose`, L5632–5708 in `Ærend
/// Kunde Launch.dc.html`, design px): «Forundringsposer i nærheten» with the
/// live count, the rail of bags floating on their rafts under the northern
/// lights (each card opens Poseautomaten), the Poseautomaten card with its
/// rocking lever, the Ærend-feed card back to the Feed segment, and the
/// points goal.
///
/// Data: tonight's bags from `GET /api/ops/products?kind=pose` (price, value,
/// shop; the pickup line from the shop's hours), the points balance and goal
/// (`points/me`, the prize shelf), and the newest feed post from the screen.
/// No stock is tracked, so a card shows no «N igjen»; the head chip counts
/// the bags themselves («ekte antall»).
class UtforskPoseSegment extends StatefulWidget {
  const UtforskPoseSegment({
    super.key,
    required this.onAutomat,
    required this.onFeed,
    required this.onMeg,
    required this.onPremier,
    this.newest,
    this.unread = 0,
    this.api,
    this.butikkApi,
    this.segSeq = 0,
    this.segSince,
  });

  final VoidCallback onAutomat;
  final VoidCallback onFeed;
  final VoidCallback onMeg;
  final VoidCallback onPremier;

  /// «{butikk}: {tittel}» of the newest feed post, when the feed has loaded.
  final String? newest;
  final int unread;

  final OpsCustomerApi? api;
  final OpsButikkApi? butikkApi;

  final int segSeq;
  final DateTime? segSince;

  @override
  State<UtforskPoseSegment> createState() => _UtforskPoseSegmentState();
}

class _UtforskPoseSegmentState extends State<UtforskPoseSegment> {
  List<Map<String, dynamic>>? _bags;
  final Map<int, BergenStoreInfo> _stores = {};
  PointsBalance? _balance;
  PointGoal? _goal;

  OpsCustomerApi get _api => widget.api ?? OpsCustomerApi();
  OpsButikkApi get _butikk => widget.butikkApi ?? OpsButikkApi();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bags = await _api.poser();
    if (!mounted) return;
    setState(() => _bags = bags);
    final ids = {for (final b in bags) (b['store_id'] as num?)?.toInt() ?? 0}..remove(0);
    unawaited(Future.wait([
      for (final id in ids)
        _butikk.store(id).then((info) {
          if (info != null && mounted) setState(() => _stores[id] = info);
        }),
    ]));
    final pts = A3Services.points();
    final r = await Future.wait<Object?>([a3Try(pts.balance), a3Try(pts.shelf)]);
    if (!mounted) return;
    setState(() {
      _balance = r[0] as PointsBalance?;
      _goal = (r[1] as Premiehylla?)?.goal;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bags = _bags ?? const <Map<String, dynamic>>[];
    final children = <Widget>[
      _head(bags.length),
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
        child: Text(
          UtforskCopy.a1_utforsk_pose_line,
          style: inter(11.5, weight: FontWeight.w600, height: 1.45, color: const Color(0xFFBFD6DD)),
        ),
      ),
      _rail(bags),
      _feedKort(),
      _maalKort(),
    ];
    return SliverList(
      delegate: SliverChildListDelegate([
        for (var i = 0; i < children.length; i++)
          UtfInn(
            seq: widget.segSeq,
            since: widget.segSince,
            delayMs: math.min(i, 6) * 45.0,
            durMs: 480,
            from: const Offset(28, 10),
            scaleFrom: .97,
            opacityAt: .55,
            curve: const Cubic(.25, 1.15, .4, 1),
            child: i == 2 ? children[i] : Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: children[i]),
          ),
      ]),
    );
  }

  // ── Head (L5633–5637) ───────────────────────────────────────────────────

  Widget _head(int n) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
    child: Row(
      children: [
        Expanded(
          child: Text(UtforskCopy.a1_utforsk_pose_title, style: jakarta(16, em: -0.02)),
        ),
        const SizedBox(width: 8),
        if (_bags != null)
          CssBox(
            key: const Key('a1_pose_igjen'),
            radius: BorderRadius.circular(999),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            bg: const [
              CssLinear(180, [Color.fromRGBO(255, 148, 102, .3), Color.fromRGBO(233, 92, 44, .16)]),
            ],
            shadows: const [
              CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .25)),
              CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 148, 102, .45)),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const UtfPulsDot(color: Color(0xFFFF9466)),
                const SizedBox(width: 5),
                Text(
                  UtforskCopy.a1_utforsk_pose_left_today(n),
                  style: inter(10, weight: FontWeight.w800, color: const Color(0xFFFFD2BC)).copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()]),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  // ── Rail (L5639–5692) ───────────────────────────────────────────────────

  Widget _rail(List<Map<String, dynamic>> bags) {
    // `display:flex` with the cards stretched to the tallest (the automat card
    // grows to the bag cards' height).
    return SingleChildScrollView(
      key: const Key('a1_pose_rail'),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12 + 4, 16, 10),
      clipBehavior: Clip.none,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_bags == null) ...[
              const SizedBox(width: 204, height: 200, child: Center(child: CircularProgressIndicator(color: Color(0xFF5CE0B8)))),
              const SizedBox(width: 10),
            ]
            else if (bags.isEmpty)
              SizedBox(
                width: 204,
                child: CssBox(
                  key: const Key('a1_utforsk_pose_empty'),
                  radius: BorderRadius.circular(24),
                  padding: const EdgeInsets.all(14),
                  bg: kUtfGlassBg,
                  shadows: kUtfGlassShadow,
                  child: Center(
                    child: Text(
                      UtforskCopy.a1_utforsk_pose_empty,
                      style: inter(11.5, weight: FontWeight.w600, height: 1.4, color: const Color(0xFFDCE9EC)),
                    ),
                  ),
                ),
              ),
            if (_bags != null && bags.isEmpty) const SizedBox(width: 10),
            for (var i = 0; i < bags.length; i++) ...[
              _PoseKort(bag: bags[i], index: i, store: _stores[(bags[i]['store_id'] as num?)?.toInt() ?? 0], onTap: widget.onAutomat),
              const SizedBox(width: 10),
            ],
            _AutomatKort(priceKr: bags.isEmpty ? 99 : ((bags.first['price_ore'] as num?)?.toInt() ?? 9900) ~/ 100, onTap: widget.onAutomat),
          ],
        ),
      ),
    );
  }

  // ── Ærend-feed (L5693–5700) ─────────────────────────────────────────────

  Widget _feedKort() => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: LfPress(
      key: const Key('a1_pose_feed'),
      onTap: widget.onFeed,
      scale: .985,
      ms: 160,
      child: CssBox(
        radius: BorderRadius.circular(24),
        padding: const EdgeInsets.all(12),
        bg: kUtfGlassBg,
        shadows: kUtfGlassShadow,
        child: Row(
          children: [
            CssBox(
              width: 52,
              height: 52,
              radius: BorderRadius.circular(17),
              bg: kUtfTileBg,
              shadows: kUtfTileShadow,
              // `bob 5s .8s ease-in-out infinite`.
              child: Center(
                child: RepaintBoundary(
                  child: LfLoop(
                    builder: (context, t, child) {
                      final p = kfLoop(t, 800, 5000);
                      return Transform.translate(
                        offset: Offset(0, p == null ? 0 : kf(p, const [0, .5, 1], const [0, -5, 0], cssEaseInOut)),
                        child: child,
                      );
                    },
                    child: utfStakk3d(38, 36),
                  ),
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
                      Container(
                        width: 22,
                        height: 22,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          boxShadow: [
                            BoxShadow(color: rgba(255, 255, 255, .18), spreadRadius: 1),
                            BoxShadow(color: rgba(0, 8, 12, .5), offset: const Offset(0, 2), blurRadius: 4),
                          ],
                        ),
                        child: Image.asset('assets/images/dashboard/invitation.png', fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 7),
                      Text(UtforskCopy.a1_pose_feed_title, style: jakarta(15, em: -0.02)),
                      if (widget.unread > 0) ...[
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: rgba(92, 224, 184, .16),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: rgba(92, 224, 184, .38)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const UtfPulsDot(color: Color(0xFF5CE0B8), glow: 8),
                              const SizedBox(width: 5),
                              Text(UtforskCopy.a1_pose_feed_nye(widget.unread), style: inter(10, weight: FontWeight.w800, color: const Color(0xFF9FF0D4))),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.newest ?? UtforskCopy.a1_pose_feed_tom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: inter(11.5, weight: FontWeight.w600, height: 1.35, color: const Color(0xFFBFD6DD)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const UtfPilDisk(size: 32),
          ],
        ),
      ),
    ),
  );

  // ── Mål (L5701–5707) ────────────────────────────────────────────────────

  Widget _maalKort() {
    final g = _goal;
    final b = _balance;
    final linje = g == null
        ? UtforskCopy.a1_maal_ingen
        : g.reached
        ? UtforskCopy.a1_maal_klar(g.label.toLowerCase())
        : UtforskCopy.a1_maal_igjen(g.label.toLowerCase(), g.remaining);
    final pct = g == null ? 0.0 : (g.percent / 100).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: LfPress(
        key: const Key('a1_pose_maal'),
        onTap: widget.onMeg,
        scale: .985,
        ms: 160,
        child: CssBox(
          radius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(12),
          bg: kUtfGlassBg,
          shadows: kUtfGlassShadow,
          child: Row(
            children: [
              CssBox(
                width: 52,
                height: 52,
                radius: BorderRadius.circular(17),
                bg: kUtfTileBg,
                shadows: kUtfTileShadow,
                child: Center(child: SvgPicture.asset('assets/svgs/dashboard/varde3d.svg', width: 30, height: 38)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(linje, style: jakarta(13.5, em: -0.02, height: 1.25)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 8,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: CssBox(
                              radius: BorderRadius.circular(4),
                              bg: [CssSolid(rgba(0, 8, 12, .4))],
                              shadows: [
                                CssShadow.inset(0, 1.5, 2, 0, rgba(0, 0, 0, .5)),
                                CssShadow.inset(0, -1, 0, 0, rgba(255, 255, 255, .1)),
                              ],
                            ),
                          ),
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: pct,
                                  heightFactor: 1,
                                  child: CssBox(
                                    radius: BorderRadius.circular(4),
                                    bg: const [CssLinear(90, [Color(0xFF2E9C78), Color(0xFF5CE0B8)])],
                                    shadows: [
                                      CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .45)),
                                      CssShadow(0, 0, 10, 0, rgba(92, 224, 184, .6)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // The goal's lantern (`lyktPuls 3s`).
                          Positioned(
                            right: 0,
                            top: -2,
                            child: RepaintBoundary(
                              child: LfLoop(
                                frozenMs: 0,
                                builder: (context, t, _) {
                                  final p = (t % 3000) / 3000;
                                  final blur = kf(p, const [0, .5, 1], const [8, 15, 8], cssEase);
                                  final a = kf(p, const [0, .5, 1], const [.9, 1, .9], cssEase);
                                  return Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2C14E),
                                      shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: rgba(242, 193, 78, a), blurRadius: blur)],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            b == null ? '' : UtforskCopy.a1_poeng(b.available),
                            style: inter(11, weight: FontWeight.w700, color: const Color(0xFFBFD6DD)).copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()]),
                          ),
                        ),
                        LfPress(
                          key: const Key('a1_pose_premiehylla'),
                          onTap: widget.onPremier,
                          scale: .96,
                          child: CssBox(
                            radius: BorderRadius.circular(999),
                            padding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
                            bg: const [
                              CssLinear(180, [Color.fromRGBO(130, 242, 210, .3), Color.fromRGBO(92, 224, 184, .1)]),
                            ],
                            shadows: const [
                              CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .32)),
                              CssShadow.inset(0, -2, 4, 0, Color.fromRGBO(4, 30, 26, .32)),
                              CssShadow(0, 0, 0, 1, Color.fromRGBO(92, 224, 184, .38)),
                              CssShadow(0, 6, 10, -6, Color.fromRGBO(3, 16, 24, .85)),
                            ],
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(UtforskCopy.a1_premiehylla, style: inter(10.5, weight: FontWeight.w800)),
                                const SizedBox(width: 4),
                                feedIcon(FeedIcons.arrowRight, 10),
                              ],
                            ),
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
      ),
    );
  }
}

// ── One bag on its raft (L5640–5660) ────────────────────────────────────────

class _PoseKort extends StatelessWidget {
  const _PoseKort({required this.bag, required this.index, required this.store, required this.onTap});

  final Map<String, dynamic> bag;
  final int index;
  final BergenStoreInfo? store;
  final VoidCallback onTap;

  /// The scene's warm or green glow (L5641 / L5660), alternating.
  static const _glow = [Color.fromRGBO(255, 214, 140, .32), Color.fromRGBO(140, 240, 190, .3)];

  @override
  Widget build(BuildContext context) {
    final priceKr = ((bag['price_ore'] as num?)?.toInt() ?? 0) ~/ 100;
    final valueKr = ((bag['value_ore'] as num?)?.toInt() ?? 0) ~/ 100;
    final left = (bag['left'] as num?)?.toInt();
    final what = '${bag['description'] ?? ''}'.trim();
    final under = valueKr > 0
        ? UtforskCopy.a1_pose_kort_under(what.isEmpty ? UtforskCopy.a1_utforsk_tab_pose : what, valueKr)
        : what;
    final hentes = utfPoseHentes(bag, store);
    final pct = valueKr > priceKr && valueKr > 0 ? ((1 - priceKr / valueKr) * 100).round() : 0;
    // Phase per card (`0s` / `1.1s` in the prototype).
    final d = index * 1100.0;

    return LfPress(
      key: Key('a1_pose_kort_${bag['id']}'),
      onTap: onTap,
      scale: .97,
      ms: 160,
      child: SizedBox(
        width: 204,
        child: CssBox(
          radius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(6),
          bg: kUtfGlassBg,
          shadows: kUtfGlassShadow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 112,
                child: PoseVannScene(width: 192, glow: _glow[index % 2], delayMs: d, child: Stack(
                  children: [
                    if (left != null)
                      Positioned(
                        top: 9,
                        left: 9,
                        child: _igjenChip(left),
                      ),
                    if (pct > 0)
                      Positioned(
                        top: 8,
                        right: 9,
                        child: Transform.rotate(
                          angle: -5 * math.pi / 180,
                          child: CssBox(
                            radius: BorderRadius.circular(7),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            bg: const [CssLinear(180, [Color(0xFFFFE7A8), Color(0xFFE9AC3C)])],
                            shadows: [
                              CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .7)),
                              const CssShadow(0, 2, 0, 0, Color(0xFFA87418)),
                              CssShadow(0, 6, 8, -4, rgba(3, 16, 24, .6)),
                            ],
                            child: Text(
                              UtforskCopy.a1_pose_rabatt(pct),
                              style: jakarta(11, color: const Color(0xFF4A300A)).copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()]),
                            ),
                          ),
                        ),
                      ),
                  ],
                )),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${bag['store_name'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: jakarta(13.5, em: -0.01)),
                    const SizedBox(height: 2),
                    Text(under, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(10.5, weight: FontWeight.w600, color: const Color(0xFFBFD6DD))),
                    const SizedBox(height: 2 + 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (hentes.isNotEmpty)
                          Flexible(
                            child: CssBox(
                              radius: BorderRadius.circular(999),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              bg: [CssSolid(rgba(255, 255, 255, .1))],
                              shadows: [CssShadow.inset(0, 0, 0, 1, rgba(255, 255, 255, .14))],
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  feedIcon(FeedIcons.pickupClock, 10),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(hentes, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(9.5, weight: FontWeight.w800, color: const Color(0xFFDCE9EC))),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(width: 6),
                        CssBox(
                          radius: BorderRadius.circular(13),
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                          bg: const [CssLinear(180, [Color(0xFFFF9466), Color(0xFFE95C2C)])],
                          shadows: [
                            CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .45)),
                            CssShadow.inset(0, -2, 0, 0, rgba(0, 0, 0, .08)),
                            const CssShadow(0, 3, 0, 0, Color(0xFFA63A12)),
                            CssShadow(0, 10, 14, -8, rgba(3, 16, 24, .75)),
                          ],
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(UtforskCopy.a1_utforsk_pose_price(priceKr), style: jakarta(14.5, height: 1).copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()])),
                              const SizedBox(height: 1),
                              Text(UtforskCopy.a1_utforsk_pose_secure, style: inter(8.5, weight: FontWeight.w800, color: rgba(255, 255, 255, .92))),
                            ],
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
      ),
    );
  }

  Widget _igjenChip(int left) => Container(
    padding: const EdgeInsets.fromLTRB(7, 3, 8, 3),
    decoration: BoxDecoration(
      color: rgba(6, 22, 30, .5),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: rgba(255, 255, 255, .16)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UtfPulsDot(color: left <= 1 ? const Color(0xFFFF9466) : const Color(0xFF5CE0B8)),
        const SizedBox(width: 5),
        Text(UtforskCopy.a1_utforsk_pose_left(left), style: inter(9.5, weight: FontWeight.w800)),
      ],
    ),
  );
}

/// The bag's little evening (L5641–5650): the warm or green glow over deep
/// teal, two aurora bands drifting (`onbLysDrift` 9 s / 12 s reverse), the
/// water with its fine lines, a ring spreading (`duppSkvulp 4.6s`) and the bag
/// on its raft bobbing (`duppDrift 5.6s`, origin 50% 85%). [child] draws on
/// top (the chips).
class PoseVannScene extends StatelessWidget {
  const PoseVannScene({super.key, required this.width, required this.glow, this.delayMs = 0, this.child});

  final double width;
  final Color glow;
  final double delayMs;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return CssBox(
      radius: BorderRadius.circular(18),
      clip: true,
      bg: [
        CssRadial([glow, glow.withValues(alpha: 0)], stops: const [0, .7], rx: .7, ry: .55, cx: .5, cy: 0),
        const CssLinear(180, [Color(0xFF16384A), Color(0xFF1F4C5E), Color(0xFF2A6272), Color(0xFF1A4654)], [0, .55, .76, 1]),
      ],
      shadows: [
        CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .22)),
        CssShadow.inset(0, -6, 12, -6, rgba(3, 14, 20, .5)),
      ],
      child: Stack(
        children: [
          RepaintBoundary(
            child: Builder(
          builder: (context) {
            final w = width;
            return LfLoop(
              frozenMs: 2000,
              builder: (context, t, _) {
                final a1 = _lys(t, delayMs, 9000, false);
                final a2 = _lys(t, delayMs + 2000, 12000, true);
                final sp = kfLoop(t, delayMs, 4600);
                final ringS = sp == null ? .55 : kf(sp, const [0, 1], const [.55, 1.6], cssEaseOut);
                final ringO = sp == null ? 0.0 : kf(sp, const [0, .18, 1], const [0, .5, 0], cssEaseOut);
                final dp = kfLoop(t, delayMs, 5600);
                final ty = dp == null ? 0.0 : kf(dp, const [0, .25, .5, .75, 1], const [0, -2, -3.4, -1, 0], cssEaseInOut);
                final rot = dp == null ? -2.6 : kf(dp, const [0, .25, .5, .75, 1], const [-2.6, 0, 2.6, 0, -2.6], cssEaseInOut);
                final sy = dp == null ? 1.0 : kf(dp, const [0, .25, .5, .75, 1], const [1, .982, 1, 1.016, 1], cssEaseInOut);
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      left: -.3 * w,
                      top: -26,
                      width: 1.6 * w,
                      height: 60,
                      child: Transform.translate(
                        offset: Offset(a1.dx, a1.dy),
                        child: Transform.scale(scale: a1.s, child: Transform.rotate(angle: -6 * math.pi / 180, child: const _Band(a: [
                          Color.fromRGBO(92, 224, 184, 0),
                          Color.fromRGBO(92, 224, 184, .45),
                          Color.fromRGBO(140, 120, 230, .4),
                          Color.fromRGBO(92, 224, 184, 0),
                        ], s: [.1, .32, .58, .86]))),
                      ),
                    ),
                    Positioned(
                      left: -.2 * w,
                      top: -8,
                      width: 1.4 * w,
                      height: 34,
                      child: Transform.translate(
                        offset: Offset(a2.dx, a2.dy),
                        child: Transform.scale(scale: a2.s, child: Transform.rotate(angle: 4 * math.pi / 180, child: const _Band(a: [
                          Color.fromRGBO(140, 120, 230, 0),
                          Color.fromRGBO(160, 240, 215, .28),
                          Color.fromRGBO(140, 120, 230, 0),
                        ], s: [.15, .45, .8]))),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 80,
                      bottom: 0,
                      child: CustomPaint(painter: _VannPainter()),
                    ),
                    Positioned(
                      left: w / 2 - 43,
                      top: 91,
                      width: 86,
                      height: 14,
                      child: Opacity(
                        opacity: ringO,
                        child: Transform.scale(
                          scale: ringS,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(Radius.elliptical(43, 7)),
                              border: Border.all(color: rgba(214, 242, 250, .45), width: 1.2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: w / 2 - 39,
                      top: 19,
                      width: 78,
                      height: 86,
                      child: Transform(
                        alignment: const Alignment(0, .7),
                        transform: Matrix4.identity()
                          ..translateByDouble(0, ty, 0, 1)
                          ..rotateZ(rot * math.pi / 180)
                          ..scaleByDouble(1, sy, 1, 1),
                        child: utfPoseVann(78, 86),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
          ),
          if (child != null) Positioned.fill(child: child!),
        ],
      ),
    );
  }

  /// `onbLysDrift` (0,0,1 → 14,-10,1.06 → back), ease-in-out.
  static ({double dx, double dy, double s}) _lys(double t, double delay, double dur, bool reverse) {
    var p = kfLoop(t, delay, dur);
    if (p == null) return (dx: 0, dy: 0, s: 1);
    if (reverse) p = 1 - p;
    final k = kf(p, const [0, .5, 1], const [0, 1, 0], cssEaseInOut);
    return (dx: 14 * k, dy: -10 * k, s: 1 + .06 * k);
  }
}

/// An aurora band: a 100° gradient in an ellipse.
class _Band extends StatelessWidget {
  const _Band({required this.a, required this.s});

  final List<Color> a;
  final List<double> s;

  @override
  Widget build(BuildContext context) => CssBox(
    radius: const BorderRadius.all(Radius.elliptical(999, 999)),
    bg: [CssLinear(100, a, s)],
  );
}

/// The water under the raft: `repeating-linear-gradient(0deg, rgba(200,240,245,
/// .07) 0 1px, transparent 1px 7px)` over `#2C6A7B → #17404D`, and the
/// 1 px surface line.
class _VannPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(
      r,
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2C6A7B), Color(0xFF17404D)]).createShader(r),
    );
    final line = Paint()..color = const Color.fromRGBO(200, 240, 245, .07);
    for (var y = size.height - 1; y >= 0; y -= 7) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), line);
    }
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 1), Paint()..color = const Color.fromRGBO(214, 242, 250, .35));
  }

  @override
  bool shouldRepaint(_VannPainter old) => false;
}

// ── Poseautomaten card (L5671–5690) ─────────────────────────────────────────

class _AutomatKort extends StatelessWidget {
  const _AutomatKort({required this.priceKr, required this.onTap});

  final int priceKr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LfPress(
    key: const Key('a1_utforsk_automat'),
    onTap: onTap,
    scale: .97,
    ms: 160,
    child: SizedBox(
      width: 150,
      child: CssBox(
        radius: BorderRadius.circular(24),
        padding: const EdgeInsets.all(6),
        bg: kUtfGlassBg,
        shadows: kUtfGlassShadow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 112,
              child: CssBox(
                radius: BorderRadius.circular(18),
                clip: true,
                bg: const [
                  CssRadial([Color.fromRGBO(140, 120, 230, .38), Color.fromRGBO(140, 120, 230, 0)], stops: [0, .7], rx: .7, ry: .6, cx: .5, cy: 0),
                  CssLinear(180, [Color(0xFF16384A), Color(0xFF1A4654)]),
                ],
                shadows: [
                  CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .22)),
                  CssShadow.inset(0, -6, 12, -6, rgba(3, 14, 20, .5)),
                ],
                child: RepaintBoundary(
                  child: Builder(
                    builder: (context) {
                      const w = 138.0;
                      return LfLoop(
                        frozenMs: 0,
                        builder: (context, t, _) {
                          final a = PoseVannScene._lys(t, 500, 10000, false);
                          final sp = (t % 3200) / 3200;
                          final spak = kf(sp, const [0, .62, .72, .8, .88, 1], const [18, 18, -24, -16, 14, 18], cssEaseInOut);
                          return Stack(
                            children: [
                              Positioned(
                                left: -.3 * w,
                                top: -26,
                                width: 1.6 * w,
                                height: 60,
                                child: Transform.translate(
                                  offset: Offset(a.dx, a.dy),
                                  child: Transform.scale(scale: a.s, child: Transform.rotate(angle: -6 * math.pi / 180, child: const _Band(a: [
                                    Color.fromRGBO(92, 224, 184, 0),
                                    Color.fromRGBO(92, 224, 184, .4),
                                    Color.fromRGBO(140, 120, 230, .4),
                                    Color.fromRGBO(92, 224, 184, 0),
                                  ], s: [.1, .4, .64, .9]))),
                                ),
                              ),
                              const Positioned(
                                left: w / 2 - 42,
                                top: 86,
                                width: 84,
                                height: 14,
                                child: CssBox(
                                  radius: BorderRadius.all(Radius.elliptical(42, 7)),
                                  bg: [CssRadial.closestSide([Color.fromRGBO(3, 14, 20, .6), Color.fromRGBO(3, 14, 20, 0)])],
                                ),
                              ),
                              // The lever (`spakVipp 3.2s`), pivoting at its foot.
                              Positioned(
                                left: w / 2 + 6,
                                top: 30,
                                width: 4,
                                height: 42,
                                child: Transform.rotate(
                                  angle: spak * math.pi / 180,
                                  alignment: Alignment.bottomCenter,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(2),
                                            gradient: const LinearGradient(colors: [Colors.white, Color(0xFF8FA4AB)]),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: -9,
                                        top: -16,
                                        child: CssBox(
                                          width: 22,
                                          height: 22,
                                          radius: BorderRadius.circular(11),
                                          bg: const [
                                            CssRadial([Color(0xFFFFC2A6), Color(0xFFE95C2C), Color(0xFFA63A12)], stops: [0, .55, 1], rx: .8, ry: .8, cx: .34, cy: .28),
                                          ],
                                          shadows: [
                                            CssShadow.inset(0, -3, 5, 0, rgba(80, 20, 4, .35)),
                                            CssShadow(0, 4, 6, -2, rgba(3, 16, 24, .6)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: w / 2 - 33,
                                top: 62,
                                width: 66,
                                height: 32,
                                child: CssBox(
                                  radius: BorderRadius.circular(11),
                                  bg: kUtfTileBg,
                                  shadows: [
                                    CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .32)),
                                    CssShadow.inset(0, -3, 5, 0, rgba(4, 20, 28, .42)),
                                    CssShadow(0, 0, 0, 1, rgba(255, 255, 255, .07)),
                                    CssShadow(0, 9, 12, -6, rgba(3, 16, 24, .8)),
                                  ],
                                  child: Center(
                                    child: CssBox(
                                      width: 28,
                                      height: 6,
                                      radius: BorderRadius.circular(3),
                                      bg: [CssSolid(rgba(3, 16, 24, .6))],
                                      shadows: [
                                        CssShadow.inset(0, 1.5, 2, 0, rgba(0, 0, 0, .6)),
                                        CssShadow(0, 1, 0, 0, rgba(255, 255, 255, .18)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(UtforskCopy.a1_utforsk_automat, style: jakarta(13.5, em: -0.01)),
                    const SizedBox(height: 2),
                    Text(UtforskCopy.a1_utforsk_automat_line(priceKr), style: inter(10.5, weight: FontWeight.w700, color: const Color(0xFF9FF0D4))),
                    const Spacer(),
                    const Align(alignment: Alignment.centerRight, child: UtfPilDisk()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
