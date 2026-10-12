import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/ops/butikk_models.dart';
import '../../../data/points/points_rules.dart';
import '../../../networking/ops/ops_butikk_api.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../networking/ops/ops_kasse_api.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart';
import '../../common/home/bergen/bergen_rails.dart' show BergenHolo, BergenKenBurns, BergenRail;
import '../hjem/hjem_harness.dart';
import '../kit/bergen_css.dart' show rgba;
import '../kit/bergen_toast.dart';
import 'feed_tab.dart' show utfPoseHentes;
import 'pose_ark.dart';
import 'utforsk_bits.dart';
import 'utforsk_copy.dart';

/// A bag as the Forundringspose segment, its card and its sheet show it
/// (new Bergen `utfPoserVals`, L19899): the store's bag from `GET
/// /api/ops/products?kind=pose`, the store itself (logo, distance, address)
/// and whether it is already in the customer's cart («Sikret»).
class UtfPose {
  const UtfPose({
    required this.id,
    required this.storeId,
    required this.navn,
    required this.priceOre,
    required this.verdiKr,
    this.kat,
    this.igjen,
    this.kap,
    this.hent,
    this.hentLinje,
    this.bildeUrl,
    this.innhold,
    this.utlagt,
    this.avstand,
    this.gate,
    this.logoUrl,
    this.sikret = false,
  });

  /// The bag's product id (the cart line's product).
  final int id;
  final int storeId;

  /// The store's name (`p.navn`).
  final String navn;
  final int priceOre;

  /// The value before the discount, in kr; 0 when the store gave none.
  final int verdiKr;

  /// The card line, «Bakst» (`p.kat`).
  final String? kat;

  /// Bags left / put out today (`igjen` / `kap`); null when stock is not
  /// tracked for this bag (no dots, no «N igjen»).
  final int? igjen;
  final int? kap;

  /// «16–18» from the store's pickup window (`p.hent`).
  final String? hent;

  /// The card's «hentes 16–18», or the store's hours when the bag has no
  /// window («hentes til 18:00»).
  final String? hentLinje;

  /// The bag's photo, or the store's own banner when the bag has none.
  final String? bildeUrl;

  /// What the store writes about the bag (`p.innhold`).
  final String? innhold;

  /// «15:40» when the bag was put out today (`p.utlagt`).
  final String? utlagt;

  /// «1,4 km» from the customer's address, and the store's street.
  final String? avstand;
  final String? gate;
  final String? logoUrl;
  final bool sikret;

  int get prisKr => priceOre ~/ 100;

  /// What is left once the customer's own bag is counted (`igjenN`).
  int? get igjenN => igjen == null ? null : math.max(0, igjen! - (sikret ? 1 : 0));

  /// «−60 %», when the store gave a value.
  int? get rabatt => verdiKr > prisKr && verdiKr > 0 ? ((1 - prisKr / verdiKr) * 100).round() : null;
  int get spar => verdiKr > prisKr ? verdiKr - prisKr : 0;

  UtfPose medSikret(bool v) => UtfPose(
    id: id,
    storeId: storeId,
    navn: navn,
    priceOre: priceOre,
    verdiKr: verdiKr,
    kat: kat,
    igjen: igjen,
    kap: kap,
    hent: hent,
    hentLinje: hentLinje,
    bildeUrl: bildeUrl,
    innhold: innhold,
    utlagt: utlagt,
    avstand: avstand,
    gate: gate,
    logoUrl: logoUrl,
    sikret: v,
  );

  /// From the bag row, its store (when loaded) and the cart.
  static UtfPose fra(Map<String, dynamic> bag, BergenStoreInfo? store, {bool sikret = false, DateTime? naa}) {
    int? i(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');
    String? str(Object? v) {
      final t = '${v ?? ''}'.trim();
      return t.isEmpty ? null : t;
    }

    final fra = str(bag['pickup_from']), til = str(bag['pickup_to']);
    final hent = fra != null && til != null ? '${_kl(fra)}–${_kl(til)}' : null;
    final reserve = utfPoseHentes(bag, store);
    final posted = DateTime.tryParse('${bag['posted_at'] ?? ''}')?.toLocal();
    final now = naa ?? DateTime.now();
    final idag = posted != null && posted.year == now.year && posted.month == now.month && posted.day == now.day;
    final km = store?.distanceKm;
    return UtfPose(
      id: i(bag['id']) ?? 0,
      storeId: i(bag['store_id']) ?? 0,
      navn: str(bag['store_name']) ?? store?.name ?? '',
      priceOre: i(bag['price_ore']) ?? 0,
      verdiKr: (i(bag['value_ore']) ?? 0) ~/ 100,
      kat: str(bag['category']) ?? store?.categoryName,
      igjen: i(bag['left']),
      kap: i(bag['capacity']),
      hent: hent,
      hentLinje: hent != null ? UtforskCopy.a1_pose_hentes(hent) : (reserve.isEmpty ? null : reserve.toLowerCase()),
      bildeUrl: str(bag['image_url']) ?? store?.bannerUrl,
      innhold: str(bag['description']),
      utlagt: idag ? '${posted.hour.toString().padLeft(2, '0')}:${posted.minute.toString().padLeft(2, '0')}' : null,
      avstand: km == null ? null : UtforskCopy.a1_pose_avstand(km),
      gate: store?.address == null ? null : store!.address!.split(',').first.trim(),
      logoUrl: store?.logoUrl,
      sikret: sikret,
    );
  }

  /// «16:00» → «16», «16:30» → «16:30».
  static String _kl(String t) {
    final hhmm = t.length >= 5 ? t.substring(0, 5) : t;
    return hhmm.endsWith(':00') ? hhmm.substring(0, 2).replaceFirst(RegExp('^0'), '') : hhmm;
  }
}

/// The Forundringspose segment of Utforsk (new Bergen `utfPose`, L5719–5781,
/// design px): «Forundringsposer i nærheten» with what is left today, the
/// line, the bags in the 3D carousel (as «Populært i kveld»: the front card
/// sharp, the back ones blurred 1.6 px in `full` and at .48) with the dots
/// under it, and the Poseautomaten module. A card opens the bag's sheet; its
/// «+» secures one (a real cart line) without opening it.
///
/// Data: tonight's bags (`GET /api/ops/products?kind=pose`, with the store's
/// stock and pickup window from `ops_pose_stock`), each bag's store (logo,
/// distance, street), the cart (which bags are «Sikret») and the points
/// rules (the sheet's «+N poeng»).
class UtforskPoseSegment extends StatefulWidget {
  const UtforskPoseSegment({
    super.key,
    required this.onAutomat,
    this.api,
    this.butikkApi,
    this.kasseApi,
    this.segSeq = 0,
    this.segSince,
  });

  final VoidCallback onAutomat;

  final OpsCustomerApi? api;
  final OpsButikkApi? butikkApi;
  final OpsKasseApi? kasseApi;

  final int segSeq;
  final DateTime? segSince;

  @override
  State<UtforskPoseSegment> createState() => _UtforskPoseSegmentState();
}

class _UtforskPoseSegmentState extends State<UtforskPoseSegment> {
  List<Map<String, dynamic>>? _bags;
  final Map<int, BergenStoreInfo> _stores = {};
  Set<int> _iKurven = {};
  PointsRules? _rules;

  OpsCustomerApi get _api => widget.api ?? OpsCustomerApi();
  OpsButikkApi get _butikk => widget.butikkApi ?? OpsButikkApi();
  OpsKasseApi get _kasse => widget.kasseApi ?? OpsKasseApi();

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
    unawaited(_lastKurv());
    final rules = await _api.rules();
    if (mounted && rules != null) setState(() => _rules = rules);
    // Debug: `poseArk` opens bag N's sheet once the stores have loaded.
    final i = kDebugMode ? HjemHarness.poseArk : null;
    if (i != null && i < bags.length) {
      HjemHarness.poseArk = null;
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (mounted) unawaited(_apne(_poser[i]));
    }
  }

  /// «Sikret»: the bags already in the cart, read from the cart itself.
  Future<void> _lastKurv() async {
    try {
      final cart = await _kasse.cart();
      if (mounted) setState(() => _iKurven = {for (final l in cart.lines) l.productId});
    } catch (_) {}
  }

  List<UtfPose> get _poser => [
    for (final b in _bags ?? const <Map<String, dynamic>>[])
      UtfPose.fra(b, _stores[(b['store_id'] as num?)?.toInt() ?? 0], sikret: _iKurven.contains((b['id'] is num ? (b['id'] as num).toInt() : int.tryParse('${b['id']}') ?? 0))),
  ];

  /// `sikreKn` (the card's «+»): a real cart line, the toast, no sheet.
  Future<void> _sikre(UtfPose p) async {
    if (p.sikret) {
      _apne(p);
      return;
    }
    final ok = await sikrePose(context, p, toast: false);
    if (!mounted || !ok) return;
    setState(() => _iKurven = {..._iKurven, p.id});
    showBergenToast(context, UtforskCopy.a1_pose_sikret_toast(p.hent ?? ''));
  }

  Future<void> _apne(UtfPose p) async {
    await visPoseArk(context, p, rules: _rules, onSikret: () {
      if (mounted) setState(() => _iKurven = {..._iKurven, p.id});
    });
    // Back from the sheet (or the cart): the cart decides «Sikret».
    if (mounted) unawaited(_lastKurv());
  }

  @override
  Widget build(BuildContext context) {
    final poser = _poser;
    final children = <Widget>[
      _head(poser),
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
        child: Text(
          UtforskCopy.a1_pose_linje,
          style: inter(11.5, weight: FontWeight.w600, height: 1.45, color: const Color(0xFFBFD6DD)),
        ),
      ),
      _karusell(poser),
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: _AutomatModul(priceKr: poser.isEmpty ? 99 : poser.first.prisKr, onTap: widget.onAutomat),
      ),
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

  // ── Head (L5720–5723) ───────────────────────────────────────────────────

  Widget _head(List<UtfPose> poser) {
    // `utfIgjenTx`: what is left across the bags; a bag whose store tracks
    // no stock counts as the one it is.
    final n = poser.fold<int>(0, (a, p) => a + (p.igjenN ?? 1));
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
      child: Row(
        children: [
          Expanded(child: Text(UtforskCopy.a1_utforsk_pose_title, style: jakarta(16, em: -0.02))),
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
  }

  // ── The carousel (L5725–5774) ───────────────────────────────────────────

  Widget _karusell(List<UtfPose> poser) {
    if (_bags == null) {
      return const SizedBox(height: 240, child: Center(child: CircularProgressIndicator(color: Color(0xFF5CE0B8))));
    }
    if (poser.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: CssBox(
          key: const Key('a1_utforsk_pose_empty'),
          radius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(18),
          bg: kUtfGlassBg,
          shadows: kUtfGlassShadow,
          child: Text(
            UtforskCopy.a1_utforsk_pose_empty,
            textAlign: TextAlign.center,
            style: inter(11.5, weight: FontWeight.w600, height: 1.4, color: const Color(0xFFDCE9EC)),
          ),
        ),
      );
    }
    final vis = poser.take(3).toList();
    return Padding(
      // margin: 12px -16px 0; the dots `margin: 2px 0 4px`.
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: BergenRail(
        key: const Key('a1_pose_rail'),
        height: 228 + 2,
        cardTop: 4,
        count: vis.length,
        intervalMs: 5200,
        onOpen: (i) => _apne(vis[i]),
        builder: (context, i, front) => _PoseKortBody(pose: vis[i], seed: i, onPluss: () => _sikre(vis[i])),
      ),
    );
  }
}

/// One bag in the carousel (L5730–5770): the photo (Ken Burns, the holo
/// shine) with «N igjen», «Sikret» and the price pill, the store, «Bakst ·
/// hentes 16–18», and the round key — orange «+», mint ✓ once secured.
class _PoseKortBody extends StatelessWidget {
  const _PoseKortBody({required this.pose, required this.seed, required this.onPluss});

  final UtfPose pose;
  final int seed;
  final VoidCallback onPluss;

  @override
  Widget build(BuildContext context) {
    final p = pose;
    final igjen = p.igjenN;
    final lav = igjen != null && igjen <= 1;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The card's holo band (bottom 46 %, `bm3Holo 5s`).
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 96,
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
              child: BergenHolo(
                colors: [
                  Color.fromRGBO(255, 255, 255, 0),
                  Color.fromRGBO(255, 190, 160, .34),
                  Color.fromRGBO(255, 228, 150, .34),
                  Color.fromRGBO(245, 185, 225, .3),
                  Color.fromRGBO(255, 255, 255, 0),
                ],
                stops: [.28, .40, .48, .56, .68],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(7, 7, 7, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 126,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(begin: Alignment(-.26, -.97), end: Alignment(.26, .97), colors: [Color(0xFFF6F0E6), Color(0xFFDCCDB4)]),
                        ),
                      ),
                      if (p.bildeUrl != null)
                        // kenBurnsProd (8 + 2i) s alternate: one way per period.
                        BergenKenBurns(
                          seconds: (8 + seed * 2) * 2,
                          reverse: false,
                          product: true,
                          child: Image.network(p.bildeUrl!, fit: BoxFit.cover, cacheWidth: 720, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                        ),
                      const IgnorePointer(
                        child: BergenHolo(
                          dodge: true,
                          colors: [
                            Color.fromRGBO(255, 255, 255, 0),
                            Color.fromRGBO(255, 120, 80, .6),
                            Color.fromRGBO(255, 214, 120, .6),
                            Color.fromRGBO(255, 150, 190, .55),
                            Color.fromRGBO(210, 150, 255, .45),
                            Color.fromRGBO(255, 255, 255, 0),
                          ],
                          stops: [.22, .36, .45, .54, .63, .76],
                        ),
                      ),
                      // inset 0 0 0 1px .08 + inset 0 2px 6px .18, and the light from above.
                      const IgnorePointer(
                        child: CssBox(
                          radius: BorderRadius.all(Radius.circular(20)),
                          bg: [
                            CssRadial([Color.fromRGBO(255, 255, 255, .32), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .6], rx: 1.2, ry: .9, cx: .3, cy: .1),
                            CssLinear(180, [Color.fromRGBO(60, 35, 10, 0), Color.fromRGBO(60, 35, 10, 0), Color.fromRGBO(60, 35, 10, .2)], [0, .56, 1]),
                          ],
                          shadows: [
                            CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(0, 0, 0, .08)),
                            CssShadow.inset(0, 2, 6, 0, Color.fromRGBO(0, 0, 0, .18)),
                          ],
                        ),
                      ),
                      if (igjen != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: _MorkChip(
                            key: const Key('a1_pose_kort_igjen'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                UtfPulsDot(color: lav ? const Color(0xFFFF9466) : const Color(0xFF5CE0B8)),
                                const SizedBox(width: 5),
                                Text(UtforskCopy.a1_utforsk_pose_left(igjen), style: inter(10, weight: FontWeight.w800).copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()])),
                              ],
                            ),
                          ),
                        ),
                      if (p.sikret) const Positioned(top: 8, right: 8, child: PoseSikretChip(small: true)),
                      Positioned(left: 8, bottom: 8, child: PosePrisPille(pose: p)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 9, 4, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.navn, maxLines: 1, overflow: TextOverflow.ellipsis, style: jakarta(13.5, em: -.01, color: const Color(0xFF23201D))),
                          Text(
                            [if (p.kat != null) p.kat!, if (p.hentLinje != null) p.hentLinje!].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: inter(11, weight: FontWeight.w600, color: const Color(0xFF8C847C)).copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      button: true,
                      label: UtforskCopy.a1_pose_sikre_label,
                      child: LfPress(key: ValueKey('a1_pose_pluss_${p.id}'), dy: 3, ms: 120, onTap: onPluss, child: _RundKnapp(sikret: p.sikret)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The card's 40 px round key (`knBg` / `knSh`): orange «+», or mint ✓.
class _RundKnapp extends StatelessWidget {
  const _RundKnapp({required this.sikret});

  final bool sikret;

  @override
  Widget build(BuildContext context) => CssBox(
    width: 40,
    height: 40,
    radius: BorderRadius.circular(20),
    bg: [
      sikret
          ? const CssLinear(180, [Color(0xFF9FF0D4), Color(0xFF5CE0B8)])
          : const CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1]),
    ],
    shadows: sikret
        ? const [
            CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .45)),
            CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .5)),
            CssShadow(0, 3, 0, 0, Color(0xFF2E9C78)),
            CssShadow(0, 12, 16, -9, Color.fromRGBO(46, 156, 120, .7)),
          ]
        : const [
            CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .45)),
            CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
            CssShadow(0, 3, 0, 0, Color(0xFFC4491A)),
            CssShadow(0, 5, 0, 0, Color.fromRGBO(120, 45, 15, .22)),
            CssShadow(0, 12, 16, -9, Color.fromRGBO(200, 70, 25, .8)),
          ],
    child: Center(
      child: sikret
          ? const PoseInn(child: _Hake(size: 17, color: Color(0xFF0E4A3A), stroke: 3.2))
          : SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg>',
              width: 16,
              height: 16,
            ),
    ),
  );
}

class _Hake extends StatelessWidget {
  const _Hake({required this.size, required this.color, required this.stroke});

  final double size;
  final Color color;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final hex = color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2);
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#$hex" stroke-width="$stroke" stroke-linecap="round" stroke-linejoin="round"><path d="M4.5 12.5l5 5 10-11"/></svg>',
      width: size,
      height: size,
    );
  }
}

/// `gbPopp .45s cubic-bezier(.3,1.4,.5,1)`: scale .4 → 1.1 (65 %) → 1, fading in.
class PoseInn extends StatelessWidget {
  const PoseInn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: 450,
    child: child,
    builder: (context, t, child) {
      final p = (t / 450).clamp(0.0, 1.0);
      const c = Cubic(.3, 1.4, .5, 1);
      final s = kf(p, const [0, .65, 1], const [.4, 1.1, 1], c);
      final o = kf(p, const [0, .65, 1], const [0, 1, 1], c).clamp(0.0, 1.0);
      return Opacity(opacity: o, child: Transform.scale(scale: s, child: child));
    },
  );
}

/// The «Sikret» chip (mint, ✓), on the card (10 px) and the sheet (11 px).
class PoseSikretChip extends StatelessWidget {
  const PoseSikretChip({super.key, this.small = false});

  final bool small;

  @override
  Widget build(BuildContext context) => PoseInn(
    child: CssBox(
      radius: BorderRadius.circular(999),
      padding: small ? const EdgeInsets.fromLTRB(7, 4, 9, 4) : const EdgeInsets.fromLTRB(8, 5, 10, 5),
      bg: const [CssLinear(180, [Color(0xFF9FF0D4), Color(0xFF5CE0B8)])],
      shadows: const [
        CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .6)),
        CssShadow(0, 4, 10, -4, Color.fromRGBO(3, 16, 24, .6)),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Hake(size: 11, color: Color(0xFF0E4A3A), stroke: 3.4),
          const SizedBox(width: 5),
          Text(UtforskCopy.a1_pose_sikret, style: inter(small ? 10 : 11, weight: FontWeight.w800, color: const Color(0xFF0E4A3A))),
        ],
      ),
    ),
  );
}

/// The dark glass chip on a photo (`rgba(6,22,30,.58)`, a .18 ring). The
/// design blurs behind it (10 px); on a 3D-turned card the tint is drawn
/// flat, as the blur layer would cost a save-layer per card.
class _MorkChip extends StatelessWidget {
  const _MorkChip({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => CssBox(
    radius: BorderRadius.circular(999),
    padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
    bg: const [CssSolid(Color.fromRGBO(6, 22, 30, .58))],
    shadows: const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .18))],
    child: child,
  );
}

/// The cream price pill on the card's photo: «99 kr», ~~250 kr~~, «−60 %».
class PosePrisPille extends StatelessWidget {
  const PosePrisPille({super.key, required this.pose});

  final UtfPose pose;

  @override
  Widget build(BuildContext context) {
    final r = pose.rabatt;
    const tab = [ui.FontFeature.tabularFigures()];
    return CssBox(
      height: 30,
      radius: BorderRadius.circular(999),
      padding: EdgeInsets.fromLTRB(11, 0, r != null ? 4 : 11, 0),
      bg: const [CssSolid(Color(0xFFFFFBF5))],
      shadows: const [
        CssShadow.inset(0, 1, 0, 0, Color(0xFFFFFFFF)),
        CssShadow(0, 3, 0, 0, Color.fromRGBO(120, 60, 20, .28)),
        CssShadow(0, 10, 16, -8, Color.fromRGBO(30, 8, 0, .6)),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(UtforskCopy.a1_utforsk_pose_price(pose.prisKr), style: jakarta(14, em: -.02, color: const Color(0xFF23201D)).copyWith(fontFeatures: tab)),
          if (pose.verdiKr > pose.prisKr) ...[
            const SizedBox(width: 7),
            Text(
              UtforskCopy.a1_utforsk_pose_price(pose.verdiKr),
              style: inter(11, weight: FontWeight.w700, color: const Color(0xFF9A9188)).copyWith(decoration: TextDecoration.lineThrough, fontFeatures: tab),
            ),
          ],
          if (r != null) ...[
            const SizedBox(width: 7),
            CssBox(
              height: 22,
              radius: BorderRadius.circular(999),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              bg: const [CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1])],
              shadows: const [
                CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
                CssShadow(0, 2, 0, 0, Color(0xFFC4491A)),
              ],
              child: Center(child: Text(UtforskCopy.a1_pose_rabatt(r), style: inter(10.5, weight: FontWeight.w800).copyWith(fontFeatures: tab))),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Poseautomaten module (L5778–5810) ───────────────────────────────────────

/// «Tilfeldig pose · Poseautomaten»: the machine under the northern lights —
/// two aurora bands drifting (`onbLysDrift` 9 s / 12 s reverse), the water
/// with its lines and two rings spreading (`duppSkvulp 4.6s`), a bag bobbing
/// on each side (`duppDrift 5.6s`), the lever rocking (`spakVipp 3.2s`) and
/// the three lamps (`paere 1.6s`) — then the name, the line and «99 kr ·
/// Trekk i spaken». Opens the Poseautomaten screen.
class _AutomatModul extends StatelessWidget {
  const _AutomatModul({required this.priceKr, required this.onTap});

  final int priceKr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: UtforskCopy.a1_pose_automat_label,
    child: LfPress(
      key: const Key('a1_utforsk_automat'),
      onTap: onTap,
      scale: .985,
      ms: 160,
      child: CssBox(
        radius: BorderRadius.circular(26),
        padding: const EdgeInsets.all(6),
        bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .15), Color.fromRGBO(255, 255, 255, .06)])],
        shadows: const [
          CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .32)),
          CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .12)),
          CssShadow(0, 3, 0, 0, Color.fromRGBO(10, 34, 42, .55)),
          CssShadow(0, 22, 30, -18, Color.fromRGBO(3, 14, 20, .85)),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 138,
              child: CssBox(
                radius: BorderRadius.circular(20),
                clip: true,
                bg: const [
                  CssRadial([Color.fromRGBO(140, 120, 230, .38), Color.fromRGBO(140, 120, 230, 0)], stops: [0, .7], rx: .7, ry: .7, cx: .5, cy: 0),
                  CssLinear(180, [Color(0xFF16384A), Color(0xFF1F4C5E), Color(0xFF1A4654)], [0, .6, 1]),
                ],
                shadows: [
                  CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .22)),
                  CssShadow.inset(0, -6, 12, -6, rgba(3, 14, 20, .5)),
                ],
                child: const RepaintBoundary(child: _AutomatScene()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 6, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(UtforskCopy.a1_utforsk_automat, style: jakarta(16, em: -0.02)),
                        const SizedBox(height: 3),
                        Text(UtforskCopy.a1_pose_automat_linje, style: inter(11.5, weight: FontWeight.w600, height: 1.4, color: const Color(0xFFBFD6DD))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  CssBox(
                    radius: BorderRadius.circular(15),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    bg: const [CssLinear(180, [Color(0xFFFF9466), Color(0xFFE95C2C)])],
                    shadows: const [
                      CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .45)),
                      CssShadow.inset(0, -2, 0, 0, Color.fromRGBO(0, 0, 0, .08)),
                      CssShadow(0, 3, 0, 0, Color(0xFFA63A12)),
                      CssShadow(0, 10, 14, -8, Color.fromRGBO(3, 16, 24, .75)),
                    ],
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(UtforskCopy.a1_utforsk_pose_price(priceKr), style: jakarta(15, height: 1).copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()])),
                        const SizedBox(height: 1),
                        Text(UtforskCopy.a1_pose_trekk, style: inter(9, weight: FontWeight.w800, color: const Color.fromRGBO(255, 255, 255, .92))),
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

/// The module's scene, in its 138 px box (width from the layout).
class _AutomatScene extends StatelessWidget {
  const _AutomatScene();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = box.maxWidth;
      return LfLoop(
        frozenMs: 0,
        builder: (context, t, _) {
          final a1 = _lys(t, 0, 9000, false);
          final a2 = _lys(t, 2000, 12000, true);
          ({double s, double o}) ring(double delay) {
            final p = kfLoop(t, delay, 4600);
            if (p == null) return (s: .55, o: 0);
            return (s: kf(p, const [0, 1], const [.55, 1.6], cssEaseOut), o: kf(p, const [0, .18, 1], const [0, .5, 0], cssEaseOut));
          }

          Matrix4 drift(double delay) {
            final p = kfLoop(t, delay, 5600);
            final ty = p == null ? 0.0 : kf(p, const [0, .25, .5, .75, 1], const [0, -2, -3.4, -1, 0], cssEaseInOut);
            final rot = p == null ? -2.6 : kf(p, const [0, .25, .5, .75, 1], const [-2.6, 0, 2.6, 0, -2.6], cssEaseInOut);
            final sy = p == null ? 1.0 : kf(p, const [0, .25, .5, .75, 1], const [1, .982, 1, 1.016, 1], cssEaseInOut);
            return Matrix4.identity()
              ..translateByDouble(0, ty, 0, 1)
              ..rotateZ(rot * math.pi / 180)
              ..scaleByDouble(1, sy, 1, 1);
          }

          final sp = (t % 3200) / 3200;
          final spak = kf(sp, const [0, .62, .72, .8, .88, 1], const [18, 18, -24, -16, 14, 18], cssEaseInOut);
          double paere(double delay) {
            final p = ((t - delay) % 1600) / 1600;
            return kf(p < 0 ? p + 1 : p, const [0, .5, 1], const [0, 1, 0], cssEaseInOut);
          }

          final r1 = ring(0), r2 = ring(1600);
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: -.3 * w,
                top: -28,
                width: 1.6 * w,
                height: 66,
                child: Transform.translate(
                  offset: Offset(a1.dx, a1.dy),
                  child: Transform.scale(
                    scale: a1.s,
                    child: Transform.rotate(
                      angle: -5 * math.pi / 180,
                      child: const _Band(a: [
                        Color.fromRGBO(92, 224, 184, 0),
                        Color.fromRGBO(92, 224, 184, .45),
                        Color.fromRGBO(140, 120, 230, .42),
                        Color.fromRGBO(92, 224, 184, 0),
                      ], s: [.1, .34, .6, .88]),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -.2 * w,
                top: -6,
                width: 1.4 * w,
                height: 36,
                child: Transform.translate(
                  offset: Offset(a2.dx, a2.dy),
                  child: Transform.scale(
                    scale: a2.s,
                    child: Transform.rotate(
                      angle: 4 * math.pi / 180,
                      child: const _Band(a: [
                        Color.fromRGBO(140, 120, 230, 0),
                        Color.fromRGBO(160, 240, 215, .28),
                        Color.fromRGBO(140, 120, 230, 0),
                      ], s: [.15, .45, .8]),
                    ),
                  ),
                ),
              ),
              Positioned(left: 0, right: 0, top: 104, bottom: 0, child: CustomPaint(painter: _VannPainter())),
              for (final (x, top, bw, bh, r) in [(.15 * w, 113.0, 70.0, 12.0, r1), (.85 * w, 115.0, 62.0, 11.0, r2)])
                Positioned(
                  left: x - bw / 2,
                  top: top,
                  width: bw,
                  height: bh,
                  child: Opacity(
                    opacity: r.o.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: r.s,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.elliptical(bw / 2, bh / 2)),
                          border: Border.all(color: rgba(214, 242, 250, .45), width: 1.2),
                        ),
                      ),
                    ),
                  ),
                ),
              for (final (x, top, bw, bh, d) in [(.15 * w, 56.0, 54.0, 60.0, 0.0), (.85 * w, 62.0, 46.0, 51.0, 1600.0)])
                Positioned(
                  left: x - bw / 2,
                  top: top,
                  width: bw,
                  height: bh,
                  child: Transform(alignment: const Alignment(0, .7), transform: drift(d), child: utfPoseVann(bw, bh)),
                ),
              Positioned(
                left: w / 2 - 62,
                top: 106,
                width: 124,
                height: 16,
                child: const CssBox(
                  radius: BorderRadius.all(Radius.elliptical(62, 8)),
                  bg: [CssRadial.closestSide([Color.fromRGBO(3, 14, 20, .6), Color.fromRGBO(3, 14, 20, 0)])],
                ),
              ),
              // The lever (`spakVipp 3.2s`), pivoting at its foot.
              Positioned(
                left: w / 2 + 30,
                top: 20,
                width: 5,
                height: 46,
                child: Transform.rotate(
                  angle: spak * math.pi / 180,
                  alignment: Alignment.bottomCenter,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: const LinearGradient(colors: [Colors.white, Color(0xFF8FA4AB)]),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -11,
                        top: -20,
                        child: CssBox(
                          width: 27,
                          height: 27,
                          radius: BorderRadius.circular(13.5),
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
              // The machine: three lamps and the slot.
              Positioned(
                left: w / 2 - 54,
                top: 58,
                width: 108,
                height: 54,
                child: CssBox(
                  radius: BorderRadius.circular(15),
                  bg: kUtfTileBg,
                  shadows: [
                    CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .32)),
                    CssShadow.inset(0, -3, 5, 0, rgba(4, 20, 28, .42)),
                    CssShadow(0, 0, 0, 1, rgba(255, 255, 255, .07)),
                    CssShadow(0, 10, 14, -6, rgba(3, 16, 24, .8)),
                  ],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final (i, c) in const [Color(0xFFFFD27A), Color(0xFF5CE0B8), Color(0xFFFF9466)].indexed) ...[
                            if (i > 0) const SizedBox(width: 6),
                            Opacity(
                              opacity: .35 + .65 * paere(i * 400.0),
                              child: Transform.scale(
                                scale: .85 + .2 * paere(i * 400.0),
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: c, boxShadow: [BoxShadow(color: c, blurRadius: 3)]),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      CssBox(
                        width: 44,
                        height: 8,
                        radius: BorderRadius.circular(4),
                        bg: [CssSolid(rgba(3, 16, 24, .6))],
                        shadows: [
                          CssShadow.inset(0, 1.5, 2, 0, rgba(0, 0, 0, .6)),
                          CssShadow(0, 1, 0, 0, rgba(255, 255, 255, .18)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // «Tilfeldig pose» (blur 10 drawn flat over the scene).
              Positioned(
                top: 10,
                left: 10,
                child: CssBox(
                  radius: BorderRadius.circular(999),
                  padding: const EdgeInsets.fromLTRB(7, 3, 8, 3),
                  bg: const [CssSolid(Color.fromRGBO(6, 22, 30, .55))],
                  shadows: const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .18))],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.string(
                        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12 0c.8 6.4 4.8 10.6 12 12-7.2 1.4-11.2 5.6-12 12-.8-6.4-4.8-10.6-12-12 7.2-1.4 11.2-5.6 12-12z" fill="#FFD27A"/></svg>',
                        width: 10,
                        height: 10,
                      ),
                      const SizedBox(width: 5),
                      Text(UtforskCopy.a1_pose_tilfeldig, style: inter(9.5, weight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

/// `onbLysDrift` (0,0,1 → 14,-10,1.06 → back), ease-in-out.
({double dx, double dy, double s}) _lys(double t, double delay, double dur, bool reverse) {
  var p = kfLoop(t, delay, dur);
  if (p == null) return (dx: 0, dy: 0, s: 1);
  if (reverse) p = 1 - p;
  final k = kf(p, const [0, .5, 1], const [0, 1, 0], cssEaseInOut);
  return (dx: 14 * k, dy: -10 * k, s: 1 + .06 * k);
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

/// The water under the machine: `repeating-linear-gradient(0deg,
/// rgba(200,240,245,.07) 0 1px, transparent 1px 7px)` over `#2C6A7B →
/// #17404D`, and the 1 px surface line.
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
