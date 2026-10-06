import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/ops/butikk_models.dart';
import '../../../networking/ops/ops_butikk_api.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../utils/utils.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart';
import '../../common/home/bergen/bergen_kit.dart' show BergenWeatherLook;
import '../../common/home/bergen/bergen_nav.dart';
import '../fiske/fiske_scene.dart';
import '../hjem/hjem_harness.dart';
import '../kit/bergen_css.dart' show rgba, cssLinear;
import '../kit/bergen_kit.dart';
import '../utforsk/feed_tab.dart' show utfPoseHentes;
import '../utforsk/utforsk_bits.dart';
import '../utforsk/utforsk_copy.dart';

/// `automat` — Poseautomaten (L5715–5906 in `Ærend Kunde Launch.dc.html`,
/// design px) at `/bergen/automat`.
///
/// A claw machine floating on a raft in Vågen, over tonight's real bags
/// (`GET /api/ops/products?kind=pose`, one slot per shop, four at most): steer
/// the claw with the arrows or tap a bag, pull the lever — the claw drops,
/// grips and lifts the bag (`krok`, `kabelNed`, `kloGrip`, `poseLoft`), the
/// sign flashes (`autoBlits`), and the bag tumbles into the water below
/// (`poseUtFall`, splash rings and drops). «Fisk den inn» sends Ægil rowing
/// out to hook it (`poseFiskStart`, ported frame for frame); when the bag is
/// in his boat it goes into the real basket. «Ingen nedtelling. Ingen niter.»
/// — there is no losing pull.
///
/// Pops with a shell tab index (the nav, «Se posen i kurven») or `'sok'` (the
/// search orb); Utforsk switches tab.
class AutomatScreen extends StatefulWidget {
  const AutomatScreen({super.key, this.api, this.butikkApi});

  final OpsCustomerApi? api;
  final OpsButikkApi? butikkApi;

  /// Pref: the bags taken today (`yyyy-mm-dd|id,id`), one per shop
  /// (`poseHentet`).
  static const String prefHentet = 'a1_automat_hentet';

  @override
  State<AutomatScreen> createState() => _AutomatScreenState();
}

class _AutomatScreenState extends State<AutomatScreen> {
  List<Map<String, dynamic>>? _bags;
  final Map<int, BergenStoreInfo> _stores = {};

  /// `kloValg` — the slot the claw is over.
  int _valg = 0;

  /// `poseHentet` — slots taken today.
  final Set<int> _hentet = {};

  bool _trekker = false;
  bool _pose = false;
  bool _fisk = false;
  bool _fisket = false;
  int _trekkSeq = 0;
  int _poseSeq = 0;

  /// The fishing clock's head start (`poseFiskStart(6200)` for a bag that is
  /// already in the boat).
  double _fiskFra = 0;

  Timer? _tr;
  Timer? _pf;

  OpsCustomerApi get _api => widget.api ?? OpsCustomerApi();
  OpsButikkApi get _butikk => widget.butikkApi ?? OpsButikkApi();

  int get _n => math.min(4, _bags?.length ?? 0);
  List<int> get _fri => [for (var k = 0; k < 4; k++) if (k < _n && !_hentet.contains(k)) k];
  bool get _laast => _trekker || _pose || _fri.isEmpty;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tr?.cancel();
    _pf?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final bags = await _api.poser();
    if (!mounted) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final raw = prefGetString(AutomatScreen.prefHentet);
    final ids = raw.startsWith('$today|') ? raw.substring(11).split(',').where((e) => e.isNotEmpty).toSet() : <String>{};
    setState(() {
      _bags = bags;
      for (var k = 0; k < math.min(4, bags.length); k++) {
        if (ids.contains('${bags[k]['id']}')) _hentet.add(k);
      }
      // The prototype's claw starts over the third slot.
      _valg = _fri.contains(2) ? 2 : (_fri.isEmpty ? 0 : _fri.first);
    });
    for (final b in bags.take(4)) {
      final id = (b['store_id'] as num?)?.toInt() ?? 0;
      if (id == 0) continue;
      _butikk.store(id).then((info) {
        if (info != null && mounted) setState(() => _stores[id] = info);
      });
    }
    if (kDebugMode) _harness();
  }

  void _harness() {
    if (HjemHarness.autoHentet case final h?) {
      setState(() => _hentet.addAll(h.where((k) => k < _n)));
      if (_hentet.contains(_valg) && _fri.isNotEmpty) _valg = _fri.first;
    }
    if (HjemHarness.autoValg case final v? when v < _n) setState(() => _valg = v);
    switch (HjemHarness.autoAct) {
      case 'trekk':
        _trekk();
      case 'pose':
        setState(() {
          _pose = true;
          _poseSeq++;
        });
      case 'fisk':
        setState(() {
          _pose = _fisk = true;
          _fiskFra = 0;
        });
      case 'fisket':
        setState(() {
          _pose = _fisk = _fisket = true;
          _fiskFra = 6200;
          _hentet.add(_valg);
        });
    }
  }

  void _lagreHentet() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final ids = [for (final k in _hentet) if (k < _n) '${_bags![k]['id']}'];
    prefSetString(AutomatScreen.prefHentet, '$today|${ids.join(',')}');
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  void _steg(int d) {
    if (_laast) return;
    for (var k = _valg + d; k >= 0 && k <= 3; k += d) {
      if (_fri.contains(k)) {
        setState(() => _valg = k);
        HapticFeedback.selectionClick();
        return;
      }
    }
  }

  /// `trekk()` (L16445).
  void _trekk() {
    if (_pose || _trekker) return;
    if (_fri.isEmpty) {
      showBergenToast(context, UtforskCopy.a1_auto_alle_hentet);
      return;
    }
    if (!_fri.contains(_valg)) _valg = _fri.first;
    HapticFeedback.mediumImpact();
    setState(() {
      _trekker = true;
      _trekkSeq++;
    });
    _tr?.cancel();
    _tr = Timer(_ms(1500), () {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _trekker = false;
        _pose = true;
        _poseSeq++;
      });
    });
  }

  Duration _ms(int ms) => MediaQuery.maybeDisableAnimationsOf(context) == true ? const Duration(milliseconds: 1) : Duration(milliseconds: (ms * timeDilation).round());

  /// `poseTilKurv` (L20013): Ægil rows out; at 4.3 s the bag is in the boat
  /// and goes into the real basket.
  void _fiskInn() {
    if (_fisk) return;
    final bag = _bags![_valg];
    setState(() {
      _fisk = true;
      _fiskFra = 0;
    });
    _pf?.cancel();
    _pf = Timer(_ms(4300), () async {
      if (!mounted) return;
      final ok = await BergenCart.add(
        context,
        storeId: (bag['store_id'] as num?)?.toInt() ?? 0,
        productId: int.tryParse('${bag['id']}') ?? 0,
        toast: UtforskCopy.a1_auto_fisket_toast,
      );
      if (!mounted) return;
      if (!ok) {
        // The basket said no (another shop's basket, offline): the bag
        // floats again.
        setState(() => _fisk = false);
        return;
      }
      HapticFeedback.mediumImpact();
      setState(() {
        _fisket = true;
        _hentet.add(_valg);
      });
      _lagreHentet();
    });
  }

  /// `poseNyTrekk` (L20014).
  void _nyTrekk() {
    _pf?.cancel();
    setState(() {
      _pose = _fisk = _fisket = false;
      if (_fri.isNotEmpty) _valg = _fri.first;
    });
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final look = BergenWeatherLook.forHour(DateTime.now().hour);

    return Scaffold(
      backgroundColor: const Color(0xFF173E48),
      body: LfFrame(
        child: Builder(
          builder: (context) {
            final mq = MediaQuery.of(context);
            final top = mq.padding.top;
            final h = mq.size.height;
            return LfOnce(
              ms: 340,
              builder: (context, t, child) {
                // `skjermInn .34s cubic-bezier(.2,.9,.3,1)`.
                final p = (t / 340).clamp(0.0, 1.0);
                final k = const Cubic(.2, .9, .3, 1).transform(p);
                return Opacity(
                  opacity: kf(p, const [0, .55], const [0, 1], const Cubic(.2, .9, .3, 1)),
                  child: Transform.translate(offset: Offset(0, 14 * (1 - k)), child: Transform.scale(scale: .978 + .022 * k, child: child)),
                );
              },
              child: Stack(
                key: const Key('a1_automat_screen'),
                children: [
                  // The sky, Bryggen and the water — the same `fiske` canvases as
                  // Fjordfiske (`data-brgl` / `data-sjogl`).
                  FiskeBakgrunn(look: look),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: top + 170,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [rgba(6, 20, 28, .62), rgba(6, 20, 28, .25), rgba(6, 20, 28, 0)],
                            stops: const [0, .6, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CssBox(
                        bg: [
                          CssRadial([rgba(0, 0, 0, 0), rgba(0, 0, 0, 0), rgba(3, 12, 18, .5)], stops: const [0, .55, 1], rx: .9, ry: .7, cx: .5, cy: .46),
                        ],
                      ),
                    ),
                  ),
                  // The machine and everything under it scroll; the top fades.
                  Positioned(
                    left: 0,
                    right: 0,
                    // The prototype's frame has no status bar: the header's
                    // 14 px top gap and part of the 46 px fade are absorbed so
                    // the pull key stays clear of the nav (8 + 16 px).
                    top: top + 112,
                    bottom: 0,
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (r) {
                        final hh = r.height;
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: const [Color(0x00000000), Color(0x40000000), Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
                          stops: [0, 10 / hh, 30 / hh, (hh - 96) / hh, (hh - 40) / hh],
                        ).createShader(r);
                      },
                      child: SingleChildScrollView(
                        key: const Key('a1_automat_scroll'),
                        padding: EdgeInsets.fromLTRB(0, 30, 0, 120 + mq.padding.bottom * .5),
                        // The frame is 844 px with no status bar; below the real
                        // one the machine is fitted with one uniform scale (as
                        // Fjordfiske's frame is), so the pull key clears the nav.
                        child: Transform.scale(
                          scale: ((h - top) / 844).clamp(.86, 1.0),
                          alignment: Alignment.topCenter,
                          child: Center(
                          child: SizedBox(
                            width: 260,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _maskin(),
                                _posenIVaagen(),
                                _infoKort(),
                                const SizedBox(height: 16),
                                _knapp(),
                                const SizedBox(height: 14),
                                Text(
                                  UtforskCopy.a1_auto_fot,
                                  textAlign: TextAlign.center,
                                  style: inter(10, weight: FontWeight.w600, color: const Color(0xFFBFD6DD)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(left: 0, right: 0, top: top, child: _topp()),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: BergenBottomNav(
                      index: -1,
                      merkMeg: false,
                      onTab: (i) => Navigator.of(context).pop(i),
                      cartCount: ValueNotifier<int>(prefGetInt(prefCartCount)),
                      onSearch: (_) => Navigator.of(context).pop('sok'),
                      onAegil: (_) => BergenRoutes.push(context, '/bergen/aegil'),
                      showHint: false,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Header (L5724–5734) ─────────────────────────────────────────────────

  Widget _topp() {
    final igjen = _bags == null ? null : _fri.length - (_pose && !_fisket ? 1 : 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: UtforskCopy.a1_auto_tilbake,
                child: LfPress(
                  key: const Key('a1_automat_tilbake'),
                  onTap: () => Navigator.of(context).maybePop(),
                  dy: 2,
                  child: CssBox(
                    width: 38,
                    height: 38,
                    radius: BorderRadius.circular(13),
                    bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .22), Color.fromRGBO(255, 255, 255, .08)])],
                    shadows: [
                      CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .38)),
                      CssShadow.inset(0, 0, 0, 1, rgba(255, 255, 255, .14)),
                      CssShadow(0, 3, 0, 0, rgba(6, 22, 30, .55)),
                      CssShadow(0, 10, 16, -8, rgba(0, 0, 0, .6)),
                    ],
                    child: Center(child: SvgPicture.string(_svgTilbake, width: 15, height: 15)),
                  ),
                ),
              ),
              const Spacer(),
              if (igjen != null)
                Flexible(
                  flex: 50,
                  child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: CssBox(
                  key: const Key('a1_automat_igjen'),
                  radius: BorderRadius.circular(999),
                  padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
                  bg: const [CssLinear(180, [Color.fromRGBO(255, 231, 168, .28), Color.fromRGBO(233, 172, 60, .14)])],
                  shadows: [
                    CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .3)),
                    CssShadow(0, 0, 0, 1, rgba(255, 214, 140, .45)),
                    CssShadow(0, 8, 14, -8, rgba(0, 0, 0, .6)),
                  ],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const UtfPulsDot(color: Color(0xFFFFD27A)),
                      const SizedBox(width: 6),
                      Text(
                        UtforskCopy.a1_auto_igjen(igjen),
                        style: inter(11, weight: FontWeight.w800, color: const Color(0xFFFFE7A8)).copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()]),
                      ),
                    ],
                  ),
                ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    UtforskCopy.a1_auto_title,
                    style: jakarta(24, em: -0.03, shadows: [Shadow(color: rgba(3, 14, 20, .6), blurRadius: 12, offset: const Offset(0, 2))]),
                  ),
                  const SizedBox(width: 8),
                  utfMerke(34, 27),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                UtforskCopy.a1_auto_line,
                style: inter(12, weight: FontWeight.w700, color: const Color(0xFFDCE9EC)).copyWith(
                  shadows: [Shadow(color: rgba(3, 14, 20, .7), blurRadius: 8, offset: const Offset(0, 1))],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── The machine (L5736–5816) ────────────────────────────────────────────

  static const List<double> _kloX = [19, 71, 125, 176];

  String _kort(String name) {
    final up = name.toUpperCase().replaceAll(' & ', '&');
    final words = up.split(RegExp(r'\s+'));
    if (up.length <= 11) return up;
    if (words.first.length >= 5) return words.first;
    return words.take(2).join(' ');
  }

  Widget _maskin() {
    final bags = _bags ?? const <Map<String, dynamic>>[];
    final v = _valg;
    final kloX = _kloX[v];
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) == true;
    final kloTrans = _trekker || reduce ? Duration.zero : const Duration(milliseconds: 450);
    const kloCurve = Cubic(.3, 1.15, .4, 1);
    final bag = v < bags.length ? bags[v] : null;
    final priceKr = bag == null ? 99 : ((bag['price_ore'] as num?)?.toInt() ?? 0) ~/ 100;
    final valueKr = bag == null ? 0 : ((bag['value_ore'] as num?)?.toInt() ?? 0) ~/ 100;

    Widget glidX({required double width, double? top, double? bottom, double? height, required Widget child}) => AnimatedPositioned(
      duration: kloTrans,
      curve: kloCurve,
      left: kloX,
      top: top,
      bottom: bottom,
      width: width,
      height: height,
      child: child,
    );

    // `flaateVugg 7s` on the whole raft.
    return RepaintBoundary(
      child: LfLoop(
        builder: (context, t, child) {
          final p = (t % 7000) / 7000;
          final dy = kf(p, const [0, .3, .7, 1], const [0, 1.5, -1, 0], cssEaseInOut);
          final r = kf(p, const [0, .3, .7, 1], const [0, .35, -.3, 0], cssEaseInOut);
          return Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..translateByDouble(0, dy, 0, 1)
              ..rotateZ(r * math.pi / 180),
            child: child,
          );
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // The warm glow under the raft (`lyktGlo 3.6s`).
            Positioned(
              left: -80,
              right: -80,
              bottom: -70,
              height: 120,
              child: IgnorePointer(
                child: _Puls(
                  periodMs: 3600,
                  min: .55,
                  child: CssBox(
                    radius: const BorderRadius.all(Radius.elliptical(210, 60)),
                    bg: [
                      CssRadial([rgba(255, 190, 110, .32), rgba(92, 224, 184, .12), rgba(0, 0, 0, 0)], stops: const [0, .5, .75], cx: .5, cy: .4),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(left: -36, right: -36, bottom: -26, height: 40, child: IgnorePointer(child: _Flaate())),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _KabRist(seq: _trekkSeq, on: _trekker, child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // The cabinet's side, in perspective.
                    Positioned(
                      right: -14,
                      top: 14,
                      bottom: 4,
                      width: 14,
                      child: ClipPath(
                        clipper: _SideClip(),
                        child: const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF163A45), Color(0xFF0B2229)]))),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _skilt(),
                        const SizedBox(height: 3),
                        _glass(bags, kloX, glidX),
                        _messingSkinne(bags),
                        _panel(priceKr, valueKr, bag),
                        Container(
                          height: 12,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0F2A33), Color(0xFF081A20)]),
                            boxShadow: [BoxShadow(color: rgba(0, 0, 0, .7), offset: const Offset(0, 6), blurRadius: 10, spreadRadius: -4)],
                          ),
                          foregroundDecoration: BoxDecoration(
                            border: Border(top: BorderSide(color: rgba(255, 214, 140, .4))),
                          ),
                        ),
                      ],
                    ),
                  ],
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// The lit sign (L5745–5755).
  Widget _skilt() {
    return SizedBox(
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CssBox(
              radius: const BorderRadius.vertical(top: Radius.circular(20), bottom: Radius.circular(4)),
              bg: const [CssLinear(180, [Color(0xFF3E8293), Color(0xFF24596A), Color(0xFF173F4C)], [0, .55, 1])],
              shadows: [
                CssShadow.inset(0, 2, 0, 0, rgba(255, 255, 255, .35)),
                CssShadow.inset(0, -3, 0, 0, rgba(3, 16, 24, .4)),
                const CssShadow(0, 0, 0, 2, Color(0xFFC99A4E)),
                CssShadow(0, 0, 0, 3, rgba(60, 40, 10, .5)),
              ],
            ),
          ),
          // Twelve bulbs chasing (`paere 1.44s`, .12 s apart).
          Positioned.fill(
            child: RepaintBoundary(
              child: LfLoop(
                frozenMs: 720,
                builder: (context, t, _) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 0; i < 12; i++)
                      Positioned(
                        top: -4,
                        left: 10 + 21.8 * i,
                        width: 8,
                        height: 8,
                        child: Builder(builder: (context) {
                          final p = kfLoop(t, i * 120.0, 1440);
                          final o = p == null ? 1.0 : kf(p, const [0, .5, 1], const [.35, 1, .35], cssEaseInOut);
                          final s = p == null ? 1.0 : kf(p, const [0, .5, 1], const [.85, 1.05, .85], cssEaseInOut);
                          return Opacity(opacity: o, child: Transform.scale(scale: s, child: const _Paere()));
                        }),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            top: 12,
            bottom: 9,
            child: CssBox(
              radius: BorderRadius.circular(12),
              bg: const [CssLinear(180, [Color(0xFF0A1E26), Color(0xFF122E38)])],
              shadows: [
                CssShadow.inset(0, 2, 6, 0, rgba(0, 0, 0, .7)),
                CssShadow(0, 1, 0, 0, rgba(255, 255, 255, .18)),
              ],
              clip: true,
              child: Stack(
                children: [
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        utfMerke(22, 18),
                        const SizedBox(width: 7),
                        // `neonFlimmer 6s`.
                        LfLoop(
                          builder: (context, t, child) {
                            final p = (t % 6000) / 6000;
                            final o = kf(p, const [0, .08, .09, .11, .12, .6, 1], const [1, 1, .55, .55, 1, .92, 1], cssEaseInOut);
                            return Opacity(opacity: o, child: child);
                          },
                          child: Text(
                            UtforskCopy.a1_auto_skilt,
                            style: jakarta(13, em: .16, color: const Color(0xFFFFF6DE), shadows: [
                              Shadow(color: rgba(255, 236, 190, .95), blurRadius: 4),
                              Shadow(color: rgba(255, 170, 90, .75), blurRadius: 12),
                              Shadow(color: rgba(242, 109, 61, .5), blurRadius: 22),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Positioned.fill(child: _Sveip(periodMs: 5000, band: [.4, .5, .6], a: .14)),
                ],
              ),
            ),
          ),
          // `autoFlash`: blinking while the claw works, one glow when it wins.
          Positioned(
            left: -2,
            right: -2,
            top: -2,
            bottom: -2,
            child: IgnorePointer(
              child: _Blits(trekker: _trekker, pose: _pose, seq: _trekkSeq, poseSeq: _poseSeq),
            ),
          ),
        ],
      ),
    );
  }

  /// The glass case with the bags, the claw and its light (L5756–5796).
  Widget _glass(List<Map<String, dynamic>> bags, double kloX, Widget Function({required double width, double? top, double? bottom, double? height, required Widget child}) glidX) {
    const posL = [22.0, 74.0, 126.0, 180.0];
    const posB = [26.0, 22.0, 28.0, 22.0];
    const posW = [54.0, 54.0, 58.0, 52.0];
    const posH = [58.0, 58.0, 63.0, 56.0];
    const rot = [-6.0, 4.0, -3.0, 7.0];
    const ringL = [16.0, 68.0, 120.0, 174.0];
    const ringB = [14.0, 10.0, 16.0, 10.0];
    const ringW = [64.0, 64.0, 68.0, 62.0];
    const skL = [24.0, 76.0, 128.0, 182.0];
    const skB = [20.0, 16.0, 22.0, 16.0];
    const skW = [48.0, 48.0, 52.0, 46.0];

    return Container(
      height: 236,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFFC99A4E), width: 7), right: BorderSide(color: Color(0xFFC99A4E), width: 7)),
        boxShadow: [
          BoxShadow(color: Color(0xFFFFE7A8), offset: Offset(-1, 0)),
          BoxShadow(color: Color(0xFF8A6224), offset: Offset(1, 0)),
        ],
      ),
      child: CssBox(
        bg: const [CssLinear(180, [Color(0xFF0B2028), Color(0xFF123441), Color(0xFF173F4C)], [0, .55, 1])],
        shadows: [
          CssShadow.inset(0, 0, 0, 1, rgba(255, 255, 255, .08)),
          CssShadow.inset(0, 14, 18, -10, rgba(0, 0, 0, .7)),
        ],
        clip: true,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Aurora (`onbLysDrift 10s`).
            Positioned(
              left: -.2 * 246,
              top: -30,
              width: 1.4 * 246,
              height: 80,
              child: RepaintBoundary(
                child: LfLoop(
                  builder: (context, t, child) {
                    final k = kf((t % 10000) / 10000, const [0, .5, 1], const [0, 1, 0], cssEaseInOut);
                    return Transform.translate(offset: Offset(14 * k, -10 * k), child: Transform.scale(scale: 1 + .06 * k, child: child));
                  },
                  child: Transform.rotate(
                    angle: -5 * math.pi / 180,
                    child: const CssBox(
                      radius: BorderRadius.all(Radius.elliptical(999, 999)),
                      bg: [
                        CssLinear(100, [
                          Color.fromRGBO(92, 224, 184, 0),
                          Color.fromRGBO(92, 224, 184, .38),
                          Color.fromRGBO(140, 120, 230, .34),
                          Color.fromRGBO(92, 224, 184, 0),
                        ], [.12, .36, .6, .86]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Positioned.fill(child: CustomPaint(painter: _StriperPainter())),
            Positioned(left: 0, top: 0, bottom: 0, width: 20, child: ClipPath(clipper: _VeggClip(venstre: true), child: const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0x80000000), Color(0x00000000)]))))),
            Positioned(right: 0, top: 0, bottom: 0, width: 20, child: ClipPath(clipper: _VeggClip(venstre: false), child: const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0x00000000), Color(0x80000000)]))))),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 60,
              child: ClipPath(
                clipper: _GulvClip(),
                child: CssBox(
                  bg: [
                    CssRadial([rgba(120, 180, 190, .22), rgba(0, 0, 0, 0)], stops: const [0, .7], rx: .6, ry: .8, cx: .5, cy: .3),
                    const CssLinear(180, [Color(0xFF1E4A58), Color(0xFF0E2A34)]),
                  ],
                  shadows: [CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .12))],
                ),
              ),
            ),
            // The claw's light cone and its spot on the floor.
            glidX(
              width: 60,
              top: 8,
              bottom: 14,
              child: ClipPath(
                clipper: _KjegleClip(),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [rgba(255, 240, 200, .3), rgba(255, 240, 200, .04)]),
                  ),
                ),
              ),
            ),
            glidX(
              width: 60,
              bottom: 10,
              height: 16,
              child: CssBox(
                radius: const BorderRadius.all(Radius.elliptical(30, 8)),
                bg: [CssRadial.closestSide([rgba(255, 240, 200, .35), rgba(255, 240, 200, 0)])],
              ),
            ),
            for (var k = 0; k < 4; k++) ..._slot(k, bags, ringL[k], ringB[k], ringW[k], skL[k], skB[k], skW[k], posL[k], posB[k], posW[k], posH[k], rot[k]),
            // The rail.
            Positioned(
              left: 8,
              right: 8,
              top: 5,
              height: 5,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF2F6F8), Color(0xFF9AA7B0), Color(0xFF56626B)], stops: [0, .5, 1]),
                  boxShadow: [BoxShadow(color: rgba(0, 0, 0, .6), offset: const Offset(0, 2), blurRadius: 3)],
                ),
              ),
            ),
            // The carriage.
            glidX(
              width: 60,
              top: 2,
              height: 12,
              child: Center(
                child: Container(
                  width: 22,
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE8EEF1), Color(0xFF8A97A2), Color(0xFF4E5A62)], stops: [0, .6, 1]),
                    boxShadow: [BoxShadow(color: rgba(0, 0, 0, .6), offset: const Offset(0, 3), blurRadius: 4)],
                  ),
                  foregroundDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border(top: BorderSide(color: rgba(255, 255, 255, .8))),
                  ),
                ),
              ),
            ),
            // The cable and the claw (`kabelNed`, `krok`, `klo` / `kloGrip`).
            glidX(
              width: 60,
              top: -6,
              height: 12 + 96 + 6,
              child: _Klo(trekker: _trekker, seq: _trekkSeq),
            ),
            // Reflections on the glass, dust, the slow sheen, the top edge.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: cssLinear(112, [rgba(255, 255, 255, .22), rgba(255, 255, 255, .05), rgba(255, 255, 255, 0), rgba(255, 255, 255, .08), rgba(255, 255, 255, 0)], const [0, .12, .26, .5, .62]),
                  ),
                ),
              ),
            ),
            Positioned(left: 150, top: 30, child: _prikk(9, rgba(255, 200, 130, .32))),
            Positioned(left: 170, top: 44, child: _prikk(6, rgba(255, 200, 130, .24))),
            Positioned(left: 32, top: 60, child: _prikk(7, rgba(160, 240, 215, .2))),
            const Positioned.fill(child: IgnorePointer(child: _Sveip(periodMs: 8000, delayMs: 1000, band: [.46, .5, .54], a: .12, wide: true))),
            Positioned(left: 0, right: 0, top: 0, height: 1, child: ColoredBox(color: rgba(255, 255, 255, .4))),
          ],
        ),
      ),
    );
  }

  static Widget _prikk(double d, Color c) => IgnorePointer(child: Container(width: d, height: d, decoration: BoxDecoration(color: c, shape: BoxShape.circle)));

  List<Widget> _slot(int k, List<Map<String, dynamic>> bags, double rl, double rb, double rw, double sl, double sb, double sw, double pl, double pb, double pw, double ph, double rot) {
    final finnes = k < _n;
    final valgt = k == _valg;
    final tatt = !finnes || _hentet.contains(k);
    final op = tatt || (valgt && _pose) ? 0.0 : 1.0;
    final ring = valgt && !_laast && !tatt ? 1.0 : 0.0;
    final navn = finnes ? '${bags[k]['store_name'] ?? ''}' : '';
    return [
      Positioned(
        left: rl,
        bottom: rb,
        width: rw,
        height: 22,
        child: IgnorePointer(
          child: AnimatedOpacity(
            opacity: ring,
            duration: const Duration(milliseconds: 300),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.elliptical(rw / 2, 11)),
                border: Border.all(color: rgba(92, 224, 184, .9), width: 1.5),
                boxShadow: [BoxShadow(color: rgba(92, 224, 184, .7), blurRadius: 14)],
              ),
            ),
          ),
        ),
      ),
      Positioned(
        left: sl,
        bottom: sb,
        width: sw,
        height: 12,
        child: Opacity(
          opacity: op,
          child: CssBox(
            radius: BorderRadius.all(Radius.elliptical(sw / 2, 6)),
            bg: [CssRadial.closestSide([rgba(2, 10, 14, .7), rgba(2, 10, 14, 0)])],
          ),
        ),
      ),
      Positioned(
        left: pl,
        bottom: pb,
        width: pw,
        height: ph,
        child: Semantics(
          button: finnes && !tatt,
          label: finnes ? UtforskCopy.a1_auto_velg(navn) : null,
          child: GestureDetector(
            key: Key('a1_automat_pose_$k'),
            onTap: () {
              if (!_laast && !tatt) {
                setState(() => _valg = k);
                HapticFeedback.selectionClick();
              }
            },
            child: Opacity(
              opacity: op,
              child: _PoseLoft(on: valgt && _trekker, seq: _trekkSeq, rot: rot, child: utfPoseBag(pw, ph)),
            ),
          ),
        ),
      ),
    ];
  }

  /// The brass rail with the shops' names; the chosen one lit in mint
  /// (L5797).
  Widget _messingSkinne(List<Map<String, dynamic>> bags) {
    const lefts = [28.0, 80.0, 134.0, 185.0];
    return Container(
      height: 18,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE7A8), Color(0xFFE9C072), Color(0xFFB98A3E), Color(0xFF8A6224)],
          stops: [0, .3, .7, 1],
        ),
        boxShadow: [BoxShadow(color: rgba(0, 0, 0, .5), offset: const Offset(0, 2), blurRadius: 3)],
      ),
      foregroundDecoration: BoxDecoration(border: Border(top: BorderSide(color: rgba(255, 255, 255, .7)))),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var k = 0; k < math.min(4, bags.length); k++)
            Positioned(
              left: lefts[k] + 3,
              top: 3,
              width: 50,
              height: 12,
              child: AnimatedOpacity(
                opacity: _hentet.contains(k) ? .4 : 1,
                duration: const Duration(milliseconds: 300),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: AnimatedOpacity(
                        opacity: k == _valg && !_laast && !_hentet.contains(k) ? 1 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8CF0D2), Color(0xFF3CC79F)]),
                            boxShadow: [BoxShadow(color: rgba(92, 224, 184, .8), blurRadius: 8)],
                          ),
                        ),
                      ),
                    ),
                    OverflowBox(
                      maxWidth: 80,
                      child: Text(
                        _kort('${bags[k]['store_name'] ?? ''}'),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        style: inter(6.5, weight: FontWeight.w800, em: .02, color: const Color(0xFF3A2810)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The control panel: display, arrows, coin slot, UTGANG and the lever
  /// (L5798–5815).
  Widget _panel(int priceKr, int valueKr, Map<String, dynamic>? bag) {
    final pil = _laast ? .35 : 1.0;
    final navn = bag == null ? '' : '${bag['store_name'] ?? ''}';
    return SizedBox(
      height: 86,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CssBox(
              radius: const BorderRadius.vertical(bottom: Radius.circular(14)),
              bg: const [CssLinear(180, [Color(0xFF3A7A8A), Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173F4C)], [0, .24, .6, 1])],
              shadows: [
                CssShadow.inset(0, 2, 0, 0, rgba(255, 255, 255, .3)),
                CssShadow.inset(0, -6, 10, 0, rgba(0, 0, 0, .3)),
              ],
            ),
          ),
          Positioned(
            left: 12,
            top: 10,
            width: 132,
            height: 46,
            child: CssBox(
              key: const Key('a1_automat_display'),
              radius: BorderRadius.circular(11),
              bg: const [CssLinear(180, [Color(0xFF06141A), Color(0xFF0E222A)])],
              shadows: [
                CssShadow.inset(0, 3, 8, 0, rgba(0, 0, 0, .85)),
                CssShadow(0, 0, 0, 1.5, rgba(255, 214, 140, .5)),
                CssShadow(0, 1, 0, 2, rgba(255, 255, 255, .12)),
                CssShadow(0, 0, 16, 0, rgba(242, 193, 78, .18)),
              ],
              clip: true,
              child: Stack(
                children: [
                  const Positioned.fill(child: CustomPaint(painter: _PunktPainter())),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              UtforskCopy.a1_utforsk_pose_price(priceKr),
                              style: jakarta(17, height: 1, color: const Color(0xFFFFD27A), shadows: [Shadow(color: rgba(255, 200, 100, .8), blurRadius: 8)]).copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()]),
                            ),
                            if (valueKr > 0) ...[
                              const SizedBox(width: 6),
                              Text(UtforskCopy.a1_auto_verdi(valueKr), style: inter(8, weight: FontWeight.w700, color: const Color(0xFFBFD6DD))),
                            ],
                          ],
                        ),
                        ),
                        const SizedBox(height: 2),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: Text(
                            navn.isEmpty ? '' : '▸ $navn',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: inter(9, weight: FontWeight.w800, em: .02, color: const Color(0xFF9FF0D4)).copyWith(
                              shadows: [Shadow(color: rgba(92, 224, 184, .6), blurRadius: 6)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: 46 * .4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [rgba(255, 255, 255, .1), rgba(255, 255, 255, 0)]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 154,
            top: 18,
            child: Row(
              children: [
                _pilKnapp(venstre: true, op: pil),
                const SizedBox(width: 10),
                _pilKnapp(venstre: false, op: pil),
              ],
            ),
          ),
          // Coin slot with its glowing slit (`lyktGlo 2.4s`).
          Positioned(
            left: 12,
            top: 64,
            width: 30,
            height: 12,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB98A3E), Color(0xFF7A5520)]),
                boxShadow: [BoxShadow(color: rgba(0, 0, 0, .5), offset: const Offset(0, 1), blurRadius: 2)],
              ),
              foregroundDecoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border(top: BorderSide(color: rgba(255, 236, 190, .6)))),
              alignment: Alignment.center,
              child: _Puls(
                periodMs: 2400,
                min: .55,
                child: Container(
                  width: 18,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A0E04),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [BoxShadow(color: rgba(255, 140, 60, .9), blurRadius: 6)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 50,
            top: 65,
            child: Text(UtforskCopy.a1_auto_kr(priceKr), style: inter(7.5, weight: FontWeight.w800, em: .12, color: rgba(220, 233, 236, .75))),
          ),
          Positioned(
            left: 96,
            top: 60,
            width: 72,
            height: 20,
            child: CssBox(
              radius: BorderRadius.circular(5),
              bg: const [CssLinear(180, [Color(0xFF06141A), Color(0xFF10262E)])],
              shadows: [
                CssShadow.inset(0, 2, 4, 0, rgba(0, 0, 0, .8)),
                const CssShadow(0, 0, 0, 1.5, Color(0xFFB98A3E)),
                CssShadow(0, 1, 0, 2, rgba(255, 236, 190, .25)),
              ],
              clip: true,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: AnimatedOpacity(
                      opacity: _pose ? 1 : 0,
                      duration: const Duration(milliseconds: 500),
                      child: CssBox(bg: [CssRadial([rgba(92, 224, 184, .75), rgba(92, 224, 184, 0)], stops: const [0, .8], rx: .6, ry: .9, cx: .5, cy: 1)]),
                    ),
                  ),
                  Text(UtforskCopy.a1_auto_utgang, style: inter(7, weight: FontWeight.w800, em: .16, color: const Color(0xFFDCE9EC))),
                ],
              ),
            ),
          ),
          // The lever (`spak 1.5s` on a pull).
          Positioned(
            right: 14,
            top: -12,
            width: 36,
            height: 90,
            child: Semantics(
              button: true,
              label: UtforskCopy.a1_auto_spak,
              child: GestureDetector(
                key: const Key('a1_automat_spak'),
                behavior: HitTestBehavior.opaque,
                onTap: _trekk,
                child: _Spak(on: _trekker, seq: _trekkSeq),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pilKnapp({required bool venstre, required double op}) => Semantics(
    button: true,
    label: venstre ? UtforskCopy.a1_auto_venstre : UtforskCopy.a1_auto_hoyre,
    child: LfPress(
      key: Key(venstre ? 'a1_automat_venstre' : 'a1_automat_hoyre'),
      onTap: () => _steg(venstre ? -1 : 1),
      dy: 2.5,
      ms: 100,
      child: AnimatedOpacity(
        opacity: op,
        duration: const Duration(milliseconds: 250),
        child: CssBox(
          width: 30,
          height: 30,
          radius: BorderRadius.circular(15),
          bg: const [CssRadial([Color(0xFFB6F6E2), Color(0xFF5CE0B8), Color(0xFF2FA883)], stops: [0, .45, 1], rx: .5, ry: .5, cx: .5, cy: .3, circle: true, farthestCorner: true)],
          shadows: [
            CssShadow.inset(0, 2, 2, 0, rgba(255, 255, 255, .7)),
            CssShadow.inset(0, -3, 4, 0, rgba(10, 60, 44, .35)),
            const CssShadow(0, 0, 0, 2.5, Color(0xFF0F2F38)),
            CssShadow(0, 0, 0, 4, rgba(255, 231, 168, .55)),
            const CssShadow(0, 3.5, 0, 4, Color(0xFF0A2128)),
            CssShadow(0, 8, 12, -2, rgba(0, 0, 0, .6)),
          ],
          child: Center(child: SvgPicture.string(venstre ? _svgPilV : _svgPilH, width: 12, height: 12)),
        ),
      ),
    ),
  );

  // ── Posen i Vågen (L5817–5852) ──────────────────────────────────────────

  Widget _posenIVaagen() {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) == true;
    return AnimatedContainer(
      duration: Duration(milliseconds: reduce ? 0 : 500),
      curve: const Cubic(.3, .9, .3, 1),
      height: _pose ? 112 : 18,
      margin: const EdgeInsets.only(top: 26),
      child: !_pose
          ? const SizedBox.shrink()
          : OverflowBox(
              alignment: Alignment.topLeft,
              maxHeight: 112,
              minHeight: 112,
              child: SizedBox(
                key: const Key('a1_automat_vaagen'),
                width: 260,
                height: 112,
                child: _fisk
                    ? _PoseFisk(key: ValueKey('fisk-$_poseSeq-$_fiskFra'), fra: _fiskFra, fisket: _fisket)
                    : _PoseLander(key: ValueKey('lander-$_poseSeq')),
              ),
            ),
    );
  }

  // ── The card under the water (L5853–5893) ───────────────────────────────

  Widget _infoKort() {
    final bags = _bags ?? const <Map<String, dynamic>>[];
    final bag = _valg < bags.length ? bags[_valg] : null;
    final priceKr = bag == null ? 99 : ((bag['price_ore'] as num?)?.toInt() ?? 0) ~/ 100;
    final hint = _bags != null && _n == 0
        ? UtforskCopy.a1_auto_tom
        : _fri.isEmpty
        ? UtforskCopy.a1_auto_hint_alle
        : _hentet.isNotEmpty
        ? UtforskCopy.a1_auto_hint_en
        : UtforskCopy.a1_auto_hint_start;
    final hentes = bag == null ? '' : utfPoseHentes(bag, _stores[(bag['store_id'] as num?)?.toInt() ?? 0]);
    final linje = _fisket
        ? (hentes.isEmpty ? UtforskCopy.a1_auto_i_kurven : UtforskCopy.a1_auto_linje_kurv(hentes))
        : _fisk
        ? UtforskCopy.a1_auto_linje_ror
        : UtforskCopy.a1_auto_linje_flyter;

    return CssBox(
      key: const Key('a1_automat_kort'),
      radius: BorderRadius.circular(22),
      bg: kUtfGlassBg,
      shadows: kUtfGlassShadow,
      clip: true,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: cssEase,
        child: !_pose
            ? SizedBox(
                height: 64,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CssBox(
                        width: 30,
                        height: 30,
                        radius: BorderRadius.circular(10),
                        bg: const [CssLinear(160, [Color(0xFF3F8798), Color(0xFF1A4654)])],
                        shadows: [
                          CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .3)),
                          CssShadow(0, 6, 10, -6, rgba(3, 16, 24, .8)),
                        ],
                        child: Center(
                          child: LfLoop(
                            builder: (context, t, child) => Transform.translate(
                              offset: Offset(0, kf((t % 3400) / 3400, const [0, .5, 1], const [0, -5, 0], cssEaseInOut)),
                              child: child,
                            ),
                            child: SvgPicture.string(_svgNed, width: 14, height: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(hint, style: inter(11, weight: FontWeight.w700, height: 1.35, color: const Color(0xFFDCE9EC))),
                      ),
                    ],
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (_fisket) ...[
                          _PopInn(
                            ms: 450,
                            child: CssBox(
                              width: 58,
                              height: 56,
                              radius: BorderRadius.circular(17),
                              bg: [
                                CssRadial([rgba(140, 240, 210, .35), rgba(255, 255, 255, 0)], stops: const [0, .7], rx: .8, ry: .6, cx: .5, cy: 0),
                                const CssLinear(180, [Color(0xFF3E7E8E), Color(0xFF173F4C)]),
                              ],
                              shadows: [
                                CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .35)),
                                CssShadow.inset(0, -3, 6, 0, rgba(3, 16, 24, .35)),
                                CssShadow(0, 8, 12, -6, rgba(3, 16, 24, .7)),
                              ],
                              child: Stack(clipBehavior: Clip.none, children: [Positioned(left: 10, top: 6, child: utfPoseBag(38, 42))]),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _merke(),
                              const SizedBox(height: 4),
                              Text(
                                bag == null ? '' : '${bag['store_name'] ?? ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: jakarta(15, em: -0.02),
                              ),
                              const SizedBox(height: 4),
                              Text(linje, style: inter(11, weight: FontWeight.w700, height: 1.35, color: const Color(0xFFBFD6DD))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!_fisk) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 16,
                            child: LfPress(
                              key: const Key('a1_automat_fisk'),
                              onTap: _fiskInn,
                              dy: 2,
                              ms: 120,
                              child: CssBox(
                                height: 46,
                                radius: BorderRadius.circular(14),
                                bg: const [CssLinear(180, [Color(0xFFFF9466), Color(0xFFE95C2C)])],
                                shadows: [
                                  CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .45)),
                                  CssShadow.inset(0, -2, 0, 0, rgba(0, 0, 0, .08)),
                                  const CssShadow(0, 3, 0, 0, Color(0xFFA63A12)),
                                  CssShadow(0, 12, 16, -8, rgba(3, 16, 24, .75)),
                                ],
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.string(_svgKrok, width: 15, height: 15),
                                    const SizedBox(width: 7),
                                    Flexible(
                                      child: Text(UtforskCopy.a1_auto_fisk_inn(priceKr), maxLines: 1, overflow: TextOverflow.ellipsis, style: jakarta(13)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(flex: 10, child: _glassKnapp(UtforskCopy.a1_auto_prov_igjen, 46, _nyTrekk, const Key('a1_automat_prov'))),
                        ],
                      ),
                    ],
                    if (_fisk && !_fisket) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 6,
                        child: CssBox(
                          radius: BorderRadius.circular(3),
                          bg: [CssSolid(rgba(0, 8, 12, .4))],
                          shadows: [CssShadow.inset(0, 1, 2, 0, rgba(0, 0, 0, .5))],
                          clip: true,
                          // `fiskFrem 4.3s linear`.
                          child: LfOnce(
                            key: ValueKey('frem-$_poseSeq'),
                            ms: 4300,
                            builder: (context, t, child) => Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(widthFactor: (t / 4300).clamp(0.0, 1.0), heightFactor: 1, child: child),
                            ),
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(3)),
                                gradient: LinearGradient(colors: [Color(0xFF2E9C78), Color(0xFF5CE0B8)]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (_fisket && _fri.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _glassKnapp(UtforskCopy.a1_auto_en_til, 42, _nyTrekk, const Key('a1_automat_en_til')),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _merke() {
    if (_fisket) {
      return CssBox(
        radius: BorderRadius.circular(6),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        bg: const [CssLinear(180, [Color(0xFF8CF0D2), Color(0xFF3CC79F)])],
        shadows: [CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .5)), const CssShadow(0, 1.5, 0, 0, Color(0xFF1F8A6B))],
        child: Text(UtforskCopy.a1_auto_i_kurven_merke, style: inter(8.5, weight: FontWeight.w800, em: .08, color: const Color(0xFF0F2A30))),
      );
    }
    if (_fisk) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: rgba(255, 255, 255, .12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: rgba(255, 255, 255, .2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const UtfPulsDot(color: Color(0xFFFF9466), size: 5, periodMs: 1000),
            const SizedBox(width: 5),
            Text(UtforskCopy.a1_auto_fisker, style: inter(8.5, weight: FontWeight.w800, em: .08)),
          ],
        ),
      );
    }
    return CssBox(
      radius: BorderRadius.circular(6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      bg: const [CssLinear(180, [Color(0xFFFFE7A8), Color(0xFFE9AC3C)])],
      shadows: [CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .6)), const CssShadow(0, 1.5, 0, 0, Color(0xFFA87418))],
      child: Text(UtforskCopy.a1_auto_din, style: inter(8.5, weight: FontWeight.w800, em: .08, color: const Color(0xFF4A300A))),
    );
  }

  Widget _glassKnapp(String label, double h, VoidCallback onTap, Key key) => LfPress(
    key: key,
    onTap: onTap,
    dy: 2,
    ms: 120,
    child: CssBox(
      height: h,
      radius: BorderRadius.circular(14),
      bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .2), Color.fromRGBO(255, 255, 255, .08)])],
      shadows: [
        CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .32)),
        CssShadow.inset(0, 0, 0, 1, rgba(255, 255, 255, .1)),
        CssShadow(0, 3, 0, 0, rgba(8, 28, 36, .75)),
      ],
      child: Center(child: Text(label, style: inter(12.5, weight: FontWeight.w800))),
    ),
  );

  // ── The big key under the card (L5894–5905) ─────────────────────────────

  Widget _knapp() {
    if (_bags == null) return const SizedBox(height: 52);
    if (_fisket) {
      return LfPress(
        key: const Key('a1_automat_se_kurv'),
        onTap: () => Navigator.of(context).pop(BergenTab.cart.index),
        dy: 2,
        child: CssBox(
          height: 52,
          radius: BorderRadius.circular(26),
          bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .16), Color.fromRGBO(255, 255, 255, .08)])],
          border: Border.all(color: rgba(255, 255, 255, .26)),
          shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .3)), CssShadow(0, 14, 24, -14, rgba(4, 18, 26, .8))],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(UtforskCopy.a1_auto_se_kurven, style: inter(14, weight: FontWeight.w800)),
              const SizedBox(width: 8),
              SvgPicture.string(_svgPilMint, width: 13, height: 13),
            ],
          ),
        ),
      );
    }
    if (_pose) return const SizedBox.shrink();
    if (_fri.isEmpty) {
      return CssBox(
        key: const Key('a1_automat_alle'),
        height: 52,
        radius: BorderRadius.circular(26),
        bg: [CssSolid(rgba(6, 22, 30, .35))],
        shadows: [CssShadow.inset(0, 0, 0, 1, rgba(255, 255, 255, .14)), CssShadow.inset(0, 2, 4, 0, rgba(0, 0, 0, .25))],
        child: Center(child: Text(UtforskCopy.a1_auto_alle_hentet, style: inter(13, weight: FontWeight.w800, color: const Color(0xFFBFD6DD)))),
      );
    }
    final bag = _bags![_valg.clamp(0, _n - 1)];
    final priceKr = ((bag['price_ore'] as num?)?.toInt() ?? 0) ~/ 100;
    // `aeKnSvev 3.4s -.8s` with its shadow (`aeKnSkygge`).
    return RepaintBoundary(
      child: LfLoop(
        builder: (context, t, child) {
          final p = ((t + 800) % 3400) / 3400;
          final k = kf(p, const [0, .5, 1], const [0, 1, 0], cssEaseInOut);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 26,
                right: 26,
                top: 53,
                height: 15,
                child: Opacity(
                  opacity: 1 - .4 * k,
                  child: Transform.translate(
                    offset: Offset(0, 5 * k),
                    child: Transform.scale(
                      scaleX: 1 - .18 * k,
                      child: CssBox(radius: const BorderRadius.all(Radius.elliptical(104, 7.5)), bg: [CssRadial([rgba(8, 26, 32, .5), rgba(0, 0, 0, 0)], stops: const [0, .72], rx: .5, ry: .5)]),
                    ),
                  ),
                ),
              ),
              Transform.translate(offset: Offset(0, -5 * k), child: child),
            ],
          );
        },
        child: LfPress(
          key: const Key('a1_automat_trekk'),
          onTap: _trekk,
          dy: 2,
          child: CssBox(
            height: 52,
            radius: BorderRadius.circular(26),
            bg: const [CssLinear(180, [Color(0xFFF68450), Color(0xFFE65A28)])],
            shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .4)), CssShadow.inset(0, -3, 6, 0, rgba(150, 40, 10, .3))],
            child: Center(child: Text(UtforskCopy.a1_auto_trekk(priceKr), style: inter(14.5, weight: FontWeight.w800))),
          ),
        ),
      ),
    );
  }

  static const String _svgTilbake =
      '<svg viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M15 6l-6 6 6 6"/></svg>';
  static const String _svgPilV =
      '<svg viewBox="0 0 24 24" fill="none" stroke="#0F2A30" stroke-width="3.6" stroke-linecap="round" stroke-linejoin="round"><path d="M15 6l-6 6 6 6"/></svg>';
  static const String _svgPilH =
      '<svg viewBox="0 0 24 24" fill="none" stroke="#0F2A30" stroke-width="3.6" stroke-linecap="round" stroke-linejoin="round"><path d="M9 6l6 6-6 6"/></svg>';
  static const String _svgNed =
      '<svg viewBox="0 0 24 24" fill="none" stroke="#9FF0D4" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M12 4v12M6 11l6 6 6-6M5 20h14"/></svg>';
  static const String _svgKrok =
      '<svg viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M5 3v12a5 5 0 0 0 10 0v-2M15 13l-2 2M15 13l2 2"/></svg>';
  static const String _svgPilMint =
      '<svg viewBox="0 0 24 24" fill="none" stroke="#5CE0B8" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M9 5l7 7-7 7"/></svg>';
}

// ── Small animated pieces ───────────────────────────────────────────────────

/// An opacity loop between [min] and 1 (`lyktGlo`).
class _Puls extends StatelessWidget {
  const _Puls({required this.periodMs, required this.min, required this.child});

  final double periodMs;
  final double min;
  final Widget child;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: LfLoop(
      frozenMs: periodMs / 2,
      builder: (context, t, child) => Opacity(
        opacity: kf((t % periodMs) / periodMs, const [0, .5, 1], [min, 1, min], cssEaseInOut),
        child: child,
      ),
      child: child,
    ),
  );
}

/// `poseChipInn`-style pop for the tile that appears with «I kurven».
class _PopInn extends StatelessWidget {
  const _PopInn({required this.ms, required this.child, this.delayMs = 0});

  final double ms;
  final double delayMs;
  final Widget child;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: ms + delayMs,
    child: child,
    builder: (context, t, child) {
      final p = kfP(t, delayMs, ms);
      final k = const Cubic(.3, 1.4, .5, 1).transform(p);
      return Opacity(
        opacity: p.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 8 * (1 - k)), child: Transform.scale(scale: .5 + .5 * k, child: child)),
      );
    },
  );
}

/// One sign bulb.
class _Paere extends StatelessWidget {
  const _Paere();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const RadialGradient(center: Alignment(-.2, -.3), colors: [Colors.white, Color(0xFFFFE2A0), Color(0xFFE9A23C)], stops: [0, .45, 1]),
      boxShadow: [
        BoxShadow(color: rgba(255, 214, 140, .85), blurRadius: 6, spreadRadius: 1),
        BoxShadow(color: rgba(255, 170, 90, .5), blurRadius: 14),
      ],
    ),
  );
}

/// A sheen sweeping across (`sveipLys`: −120 % → 120 % in the first 45 %).
class _Sveip extends StatelessWidget {
  const _Sveip({required this.periodMs, required this.band, required this.a, this.delayMs = 0, this.wide = false});

  final double periodMs;
  final double delayMs;
  final List<double> band;
  final double a;

  /// The glass case's sheen box is `inset:-40% -60%`.
  final bool wide;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, c) {
          final w = wide ? c.maxWidth * 2.2 : c.maxWidth;
          return LfLoop(
            builder: (context, t, child) {
              final p = kfLoop(t, delayMs, periodMs);
              final x = p == null ? -1.2 : kf(p, const [0, .45, 1], const [-1.2, 1.2, 1.2], cssEaseInOut);
              return ClipRect(
                child: OverflowBox(
                  maxWidth: w,
                  maxHeight: wide ? c.maxHeight * 1.8 : c.maxHeight,
                  child: Transform.translate(offset: Offset(x * w, 0), child: child),
                ),
              );
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: cssLinear(100, [rgba(255, 255, 255, 0), rgba(255, 255, 255, a), rgba(255, 255, 255, 0)], band),
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// The sign's `autoFlash`: `autoBlits .25s ease-in-out 6 alternate` while
/// the claw works, `autoVinn 1.4s ease-out` when the bag drops.
class _Blits extends StatelessWidget {
  const _Blits({required this.trekker, required this.pose, required this.seq, required this.poseSeq});

  final bool trekker;
  final bool pose;
  final int seq;
  final int poseSeq;

  @override
  Widget build(BuildContext context) {
    final glow = CssBox(
      radius: const BorderRadius.vertical(top: Radius.circular(21), bottom: Radius.circular(5)),
      bg: [CssRadial([rgba(255, 226, 160, .5), rgba(255, 226, 160, 0)], stops: const [0, .7], rx: .7, ry: .9)],
    );
    if (trekker) {
      return LfOnce(
        key: ValueKey('blits-$seq'),
        ms: 1500,
        child: glow,
        builder: (context, t, child) {
          final i = (t / 250).floor().clamp(0, 5);
          final local = ((t - i * 250) / 250).clamp(0.0, 1.0);
          final e = cssEaseInOut.transform(local);
          return Opacity(opacity: i.isEven ? e : 1 - e, child: child);
        },
      );
    }
    if (pose) {
      return LfOnce(
        key: ValueKey('vinn-$poseSeq'),
        ms: 1400,
        child: glow,
        builder: (context, t, child) => Opacity(opacity: 1 - cssEaseOut.transform((t / 1400).clamp(0.0, 1.0)), child: child),
      );
    }
    return const SizedBox.shrink();
  }
}

/// `kabRist .5s .62s` — the cabinet shudders as the claw grips.
class _KabRist extends StatelessWidget {
  const _KabRist({required this.seq, required this.on, required this.child});

  final int seq;
  final bool on;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!on) return child;
    return LfOnce(
      key: ValueKey('rist-$seq'),
      ms: 1120,
      child: child,
      builder: (context, t, child) {
        final p = kfP(t, 620, 500);
        final x = p <= 0 || p >= 1 ? 0.0 : kf(p, const [0, .2, .4, .6, .8, 1], const [0, -1.5, 1.5, -1, 1, 0], cssEaseInOut);
        return Transform.translate(offset: Offset(x, 0), child: child);
      },
    );
  }
}

/// A bag lifted by the claw (`poseLoft 1.5s ease-in-out`), or resting at
/// its own tilt.
class _PoseLoft extends StatelessWidget {
  const _PoseLoft({required this.on, required this.seq, required this.rot, required this.child});

  final bool on;
  final int seq;
  final double rot;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!on) return Transform.rotate(angle: rot * math.pi / 180, child: child);
    return LfOnce(
      key: ValueKey('loft-$seq'),
      ms: 1500,
      child: child,
      builder: (context, t, child) {
        final p = (t / 1500).clamp(0.0, 1.0);
        final y = kf(p, const [0, .58, .99, 1], const [0, 0, -96, -96], cssEaseInOut);
        final r = kf(p, const [0, .58, .99, 1], const [-3, -3, -1, -1], cssEaseInOut);
        return Opacity(
          opacity: p >= 1 ? 0 : 1,
          child: Transform.translate(offset: Offset(0, y), child: Transform.rotate(angle: r * math.pi / 180, child: child)),
        );
      },
    );
  }
}

/// The lever (`spak 1.5s`: 14° → −30° at 45–60 % → 14°).
class _Spak extends StatelessWidget {
  const _Spak({required this.on, required this.seq});

  final bool on;
  final int seq;

  @override
  Widget build(BuildContext context) {
    Widget stang(double deg) => Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 4,
          bottom: 14,
          width: 28,
          height: 14,
          child: CssBox(
            radius: const BorderRadius.all(Radius.elliptical(14, 7)),
            bg: const [CssRadial([Color(0xFF2E3A40), Color(0xFF0A1418)], rx: .5, ry: .5, cx: .5, cy: .3)],
            shadows: [
              CssShadow.inset(0, 2, 3, 0, rgba(0, 0, 0, .8)),
              const CssShadow(0, 0, 0, 2, Color(0xFFB98A3E)),
              CssShadow(0, 1, 0, 3, rgba(255, 236, 190, .25)),
            ],
          ),
        ),
        Positioned(
          left: 15,
          bottom: 20,
          width: 6,
          height: 46,
          child: Transform.rotate(
            angle: deg * math.pi / 180,
            alignment: Alignment.bottomCenter,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: const LinearGradient(colors: [Color(0xFF6E7B85), Color(0xFFF2F6F8), Color(0xFF8A97A2)], stops: [0, .45, 1]),
                    ),
                  ),
                ),
                Positioned(
                  left: -12,
                  top: -24,
                  width: 30,
                  height: 30,
                  child: CssBox(
                    radius: BorderRadius.circular(15),
                    bg: const [CssRadial([Color(0xFFFFC2A6), Color(0xFFF26D3D), Color(0xFFA63A12)], stops: [0, .5, 1], rx: .8, ry: .8, cx: .34, cy: .28)],
                    shadows: [CssShadow.inset(0, -4, 6, 0, rgba(80, 20, 4, .35)), CssShadow(0, 8, 12, -4, rgba(0, 0, 0, .7))],
                    child: Stack(
                      children: [
                        Positioned(
                          left: 6,
                          top: 5,
                          width: 10,
                          height: 7,
                          child: Transform.rotate(
                            angle: -25 * math.pi / 180,
                            child: CssBox(radius: const BorderRadius.all(Radius.elliptical(5, 3.5)), bg: [CssRadial.closestSide([rgba(255, 255, 255, .9), rgba(255, 255, 255, 0)])]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    if (!on) return stang(0);
    return LfOnce(
      key: ValueKey('spak-$seq'),
      ms: 1500,
      builder: (context, t, _) => stang(kf((t / 1500).clamp(0.0, 1.0), const [0, .45, .6, 1], const [14, -30, -30, 14], cssEaseInOut)),
    );
  }
}

/// The cable and the claw: idle the claw sways (`klo 3s`); on a pull the
/// cable unrolls (`kabelNed`), the hook drops 96 px and back (`krok`) and the
/// fingers open then close (`kloGrip`).
class _Klo extends StatelessWidget {
  const _Klo({required this.trekker, required this.seq});

  final bool trekker;
  final int seq;

  @override
  Widget build(BuildContext context) {
    Widget tegn(double krok, double kabel, double grip, double rot) => Stack(
      clipBehavior: Clip.none,
      children: [
        // The cable from under the carriage (top 12 + 6 for the svg's −6).
        Positioned(
          left: 29,
          top: 18,
          width: 2,
          height: 96,
          child: Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.diagonal3Values(1, kabel, 1),
            child: const DecoratedBox(
              decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF9AA7B0), Color(0xFFF2F6F8), Color(0xFF6E7B85)])),
            ),
          ),
        ),
        Positioned(
          left: 6,
          top: krok,
          width: 48,
          height: 80,
          child: CustomPaint(painter: _KloPainter(grip: grip, rot: rot)),
        ),
      ],
    );
    if (trekker) {
      return LfOnce(
        key: ValueKey('klo-$seq'),
        ms: 1500,
        builder: (context, t, _) {
          final p = (t / 1500).clamp(0.0, 1.0);
          final krok = kf(p, const [0, .14, .44, .58, 1], const [0, 0, 96, 96, 0], cssEaseInOut);
          final kabel = kf(p, const [0, .14, .44, .58, 1], const [0, 0, 1, 1, 0], cssEaseInOut);
          final grip = kf(p, const [0, .4, .5, 1], const [1.15, 1.15, .72, .72], cssEaseInOut);
          return tegn(krok, kabel, grip, 0);
        },
      );
    }
    return RepaintBoundary(
      child: LfLoop(
        builder: (context, t, _) => tegn(0, 0, 1, kf((t % 3000) / 3000, const [0, .5, 1], const [-4, 4, -4], cssEaseInOut)),
      ),
    );
  }
}

/// The claw (L5784–5795, viewBox 0 0 48 80): stem, head with its highlight
/// and orange ball, and the three fingers turning (`klo`) or gripping
/// (`kloGrip`) about (24, 36).
class _KloPainter extends CustomPainter {
  const _KloPainter({required this.grip, required this.rot});

  final double grip;
  final double rot;

  static const _staal = LinearGradient(colors: [Color(0xFF56626B), Color(0xFFF2F6F8), Color(0xFF9AA7B0), Color(0xFF4E5A62)], stops: [0, .42, .7, 1]);

  @override
  void paint(Canvas canvas, Size size) {
    Paint staal(Rect r) => Paint()..shader = _staal.createShader(r);
    canvas.drawRect(const Rect.fromLTWH(23, 16, 2, 12), staal(const Rect.fromLTWH(23, 16, 2, 12)));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(15, 26, 18, 11), const Radius.circular(3.5)), staal(const Rect.fromLTWH(15, 26, 18, 11)));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(15, 26, 18, 2), const Radius.circular(1)), Paint()..color = rgba(255, 255, 255, .7));
    canvas.drawCircle(
      const Offset(24, 31.5),
      2.6,
      Paint()
        ..shader = const RadialGradient(center: Alignment(-.3, -.4), radius: .8, colors: [Color(0xFFFFC2A6), Color(0xFFE95C2C), Color(0xFF8F3414)], stops: [0, .55, 1])
            .createShader(Rect.fromCircle(center: const Offset(24, 31.5), radius: 2.6)),
    );
    canvas.save();
    canvas.translate(24, 36);
    canvas.rotate(rot * math.pi / 180);
    canvas.scale(grip, 1);
    canvas.translate(-24, -36);
    const r = Rect.fromLTWH(7, 36, 34, 27);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..shader = _staal.createShader(r);
    canvas.drawPath(
      Path()
        ..moveTo(19, 36)
        ..cubicTo(11, 40, 7, 48, 9.5, 57)
        ..cubicTo(10.5, 61, 13.5, 62.5, 16.5, 60.5),
      p..strokeWidth = 3.4,
    );
    canvas.drawPath(
      Path()
        ..moveTo(29, 36)
        ..cubicTo(37, 40, 41, 48, 38.5, 57)
        ..cubicTo(37.5, 61, 34.5, 62.5, 31.5, 60.5),
      p..strokeWidth = 3.4,
    );
    canvas.drawPath(
      Path()
        ..moveTo(24, 37)
        ..lineTo(24, 56)
        ..cubicTo(24, 59, 22, 60.5, 20.5, 59.5),
      p..strokeWidth = 3,
    );
    final o = Paint()..color = const Color(0xFFE95C2C);
    canvas.drawCircle(const Offset(16.5, 60.5), 2, o);
    canvas.drawCircle(const Offset(31.5, 60.5), 2, o);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_KloPainter old) => old.grip != grip || old.rot != rot;
}

/// `repeating-linear-gradient(90deg, rgba(255,255,255,.025) 0 1px, transparent 1px 12px)`.
class _StriperPainter extends CustomPainter {
  const _StriperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color.fromRGBO(255, 255, 255, .025);
    for (var x = 0.0; x < size.width; x += 12) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), p);
    }
  }

  @override
  bool shouldRepaint(_StriperPainter old) => false;
}

/// `radial-gradient(rgba(255,255,255,.06) .7px, transparent 1px)` 3 px dots.
class _PunktPainter extends CustomPainter {
  const _PunktPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color.fromRGBO(255, 255, 255, .06);
    for (var y = 1.5; y < size.height; y += 3) {
      for (var x = 1.5; x < size.width; x += 3) {
        canvas.drawCircle(Offset(x, y), .7, p);
      }
    }
  }

  @override
  bool shouldRepaint(_PunktPainter old) => false;
}

class _SideClip extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..moveTo(0, 0)
    ..lineTo(s.width, 10)
    ..lineTo(s.width, s.height - 8)
    ..lineTo(0, s.height)
    ..close();

  @override
  bool shouldReclip(_SideClip old) => false;
}

class _VeggClip extends CustomClipper<Path> {
  _VeggClip({required this.venstre});

  final bool venstre;

  @override
  Path getClip(Size s) => venstre
      ? (Path()
          ..moveTo(0, 0)
          ..lineTo(s.width, 16)
          ..lineTo(s.width, s.height - 52)
          ..lineTo(0, s.height)
          ..close())
      : (Path()
          ..moveTo(0, 16)
          ..lineTo(s.width, 0)
          ..lineTo(s.width, s.height)
          ..lineTo(0, s.height - 52)
          ..close());

  @override
  bool shouldReclip(_VeggClip old) => old.venstre != venstre;
}

class _GulvClip extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..moveTo(20, 0)
    ..lineTo(s.width - 20, 0)
    ..lineTo(s.width, s.height)
    ..lineTo(0, s.height)
    ..close();

  @override
  bool shouldReclip(_GulvClip old) => false;
}

class _KjegleClip extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..moveTo(s.width * .42, 0)
    ..lineTo(s.width * .58, 0)
    ..lineTo(s.width, s.height)
    ..lineTo(0, s.height)
    ..close();

  @override
  bool shouldReclip(_KjegleClip old) => false;
}

// ── The raft (L5739–5744) ───────────────────────────────────────────────────

class _Flaate extends StatelessWidget {
  const _Flaate();

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: LfLoop(
      frozenMs: 1500,
      builder: (context, t, _) {
        double ring(double delay) {
          final p = kfLoop(t, delay, 5000);
          return p ?? -1;
        }

        Widget skvulp(double p, double bw, double a) {
          if (p < 0) return const SizedBox.shrink();
          final s = kf(p, const [0, 1], const [.55, 1.6], cssEaseOut);
          final o = kf(p, const [0, .18, 1], const [0, .5, 0], cssEaseOut);
          return Opacity(
            opacity: o,
            child: Transform.scale(
              scale: s,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.elliptical(180, 13)),
                  border: Border.all(color: rgba(214, 242, 250, a), width: bw),
                ),
              ),
            ),
          );
        }

        final gp = (t % 3800) / 3800;
        final go = kf(gp, const [0, .5, 1], const [.5, .85, .5], cssEaseInOut);
        final gx = kf(gp, const [0, .5, 1], const [0, 1.5, 0], cssEaseInOut);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(left: -14, right: -14, top: 22, height: 26, child: skvulp(ring(0), 1.3, .45)),
            Positioned(left: -14, right: -14, top: 22, height: 26, child: skvulp(ring(2500), 1, .35)),
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 20,
              child: CustomPaint(painter: _PlankePainter(top: true)),
            ),
            const Positioned(
              left: 3,
              right: 3,
              top: 18,
              height: 14,
              child: CustomPaint(painter: _PlankePainter(top: false)),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 25,
              height: 16,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.elliptical(166, 12.8)),
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [rgba(60, 140, 160, .6), rgba(14, 52, 66, .85)]),
                  border: Border(top: BorderSide(color: rgba(226, 248, 252, .8))),
                ),
              ),
            ),
            Positioned(
              left: 33.2,
              right: 33.2,
              top: 25,
              height: 1.5,
              child: Opacity(
                opacity: go,
                child: Transform.translate(
                  offset: Offset(gx, 0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [rgba(255, 255, 255, 0), rgba(255, 255, 255, .8), rgba(255, 255, 255, .8), rgba(255, 255, 255, 0)], stops: const [0, .3, .7, 1]),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

/// The raft's planks: the deck (`#E3B272 → #B47A42`, lines every 22 px) and
/// its front edge (`#8A5A2C → #5E3A1A`).
class _PlankePainter extends CustomPainter {
  const _PlankePainter({required this.top});

  final bool top;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final rr = top
        ? RRect.fromRectAndCorners(r, topLeft: const Radius.circular(10), topRight: const Radius.circular(10), bottomLeft: const Radius.circular(4), bottomRight: const Radius.circular(4))
        : RRect.fromRectAndCorners(r, bottomLeft: const Radius.circular(8), bottomRight: const Radius.circular(8));
    canvas.save();
    canvas.clipRRect(rr);
    canvas.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: top ? const [Color(0xFFE3B272), Color(0xFFB47A42)] : const [Color(0xFF8A5A2C), Color(0xFF5E3A1A)],
        ).createShader(r),
    );
    final line = Paint()..color = top ? rgba(60, 32, 12, .55) : rgba(40, 20, 6, .5);
    for (var x = 0.0; x < size.width; x += 22) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), line);
    }
    if (top) canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 1.5), Paint()..color = rgba(255, 236, 200, .7));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PlankePainter old) => false;
}

// ── The bag landing in Vågen (L5819–5826, L5845–5851) ──────────────────────

class _PoseLander extends StatelessWidget {
  const _PoseLander({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LfLoop(
        frozenMs: 2000,
        builder: (context, t, _) {
          Widget plask(double l, double tp, double w, double h, double bw, double a, double dur, double delay) {
            final p = kfP(t, delay, dur);
            if (p <= 0 || p >= 1) return const SizedBox.shrink();
            final e = cssEaseOut.transform(p);
            final s = .2 + 1.4 * e;
            final o = kf(p, const [0, .15, 1], const [0, .9, 0], cssEaseOut);
            return Positioned(
              left: l,
              top: tp,
              width: w,
              height: h,
              child: Opacity(
                opacity: o,
                child: Transform.scale(
                  scale: s,
                  child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.elliptical(w / 2, h / 2)), border: Border.all(color: rgba(255, 255, 255, a), width: bw))),
                ),
              ),
            );
          }

          final sk = kfLoop(t, 1200, 4400);
          const dx = [-26.0, -12.0, 4.0, 18.0, 30.0];
          const dy = [-30.0, -40.0, -44.0, -36.0, -24.0];
          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (sk != null)
                Positioned(
                  left: 86,
                  top: 70,
                  width: 68,
                  height: 16,
                  child: Opacity(
                    opacity: kf(sk, const [0, .18, 1], const [0, .5, 0], cssEaseOut),
                    child: Transform.scale(
                      scale: kf(sk, const [0, 1], const [.55, 1.6], cssEaseOut),
                      child: Container(decoration: BoxDecoration(borderRadius: const BorderRadius.all(Radius.elliptical(34, 8)), border: Border.all(color: rgba(214, 242, 250, .55), width: 1.3))),
                    ),
                  ),
                ),
              plask(80, 66, 80, 22, 2, .85, 900, 600),
              plask(66, 62, 108, 28, 1.4, .6, 1200, 700),
              for (var i = 0; i < 5; i++)
                Builder(builder: (context) {
                  final p = kfP(t, 600 + i * 20.0, 750);
                  if (p <= 0 || p >= 1) return const SizedBox.shrink();
                  const c = Cubic(.2, .7, .4, 1);
                  final x = p < .5 ? dx[i] * .6 * c.transform(p / .5) : dx[i] * .6 + (dx[i] - dx[i] * .6) * c.transform((p - .5) / .5);
                  final y = p < .5 ? dy[i] * c.transform(p / .5) : dy[i] + (6 - dy[i]) * c.transform((p - .5) / .5);
                  final s = p < .5 ? 1.0 : 1 - .5 * c.transform((p - .5) / .5);
                  final o = p < .1 ? p / .1 : (p < .5 ? 1.0 : 1 - c.transform((p - .5) / .5));
                  return Positioned(
                    left: 118 + x,
                    top: 70 + y,
                    width: 4,
                    height: 4,
                    child: Opacity(opacity: o.clamp(0.0, 1.0), child: Transform.scale(scale: s, child: const DecoratedBox(decoration: BoxDecoration(color: Color(0xFFE2F6FA), shape: BoxShape.circle)))),
                  );
                }),
              // The bag tumbling in (`poseUtFall .95s`), then bobbing (`duppDrift 5s .95s`).
              Positioned(
                left: 100,
                top: 40,
                width: 40,
                height: 44,
                child: Builder(builder: (context) {
                  final p = kfP(t, 0, 950);
                  const c = Cubic(.3, .7, .4, 1);
                  final x = kf(p, const [0, .66, .82, 1], const [14, 0, 0, 0], c);
                  final y = kf(p, const [0, .66, .82, 1], const [-120, 9, -3, 0], c);
                  final r = kf(p, const [0, .66, .82, 1], const [-24, 10, -4, 0], c);
                  final s = kf(p, const [0, .66, 1], const [.6, 1, 1], c);
                  final o = kf(p, const [0, .18, 1], const [0, 1, 1], c);
                  final dp = kfLoop(t, 950, 5000);
                  final fy = dp == null ? 0.0 : kf(dp, const [0, .25, .5, .75, 1], const [0, -2, -3.4, -1, 0], cssEaseInOut);
                  final fr = dp == null ? 0.0 : kf(dp, const [0, .25, .5, .75, 1], const [-2.6, 0, 2.6, 0, -2.6], cssEaseInOut);
                  final fs = dp == null ? 1.0 : kf(dp, const [0, .25, .5, .75, 1], const [1, .982, 1, 1.016, 1], cssEaseInOut);
                  return Opacity(
                    opacity: o,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..translateByDouble(x, y, 0, 1)
                        ..rotateZ(r * math.pi / 180)
                        ..scaleByDouble(s, s, 1, 1),
                      child: Transform(
                        alignment: const Alignment(0, .8),
                        transform: Matrix4.identity()
                          ..translateByDouble(0, fy, 0, 1)
                          ..rotateZ(fr * math.pi / 180)
                          ..scaleByDouble(1, fs, 1, 1),
                        child: const _PoseIVann(vann: 1),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The bag with the water lapping at its foot (`posevann`).
class _PoseIVann extends StatelessWidget {
  const _PoseIVann({required this.vann});

  final double vann;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned(left: 0, top: 0, child: utfPoseBag(40, 44)),
      if (vann > 0)
        Positioned(
          left: -5,
          right: -5,
          top: 31,
          height: 15,
          child: Opacity(
            opacity: vann,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(bottom: Radius.elliptical(25, 10.5)),
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [rgba(60, 140, 160, .7), rgba(14, 52, 66, .92)]),
                border: Border(top: BorderSide(color: rgba(226, 248, 252, .85))),
              ),
            ),
          ),
        ),
    ],
  );
}

// ── Ægil fishing the bag in (`poseFiskStart`, L16371–16443) ─────────────────

/// The prototype's requestAnimationFrame loop, frame for frame: the boat
/// glides in (1.3 s), Ægil leans back and casts (1.3–1.85 s), the float
/// lands and twitches twice, the bite (2.92 s) and the drag towards the boat,
/// the bag swung aboard (3.88–4.3 s) shedding drops and the water, then Ægil
/// hops for joy until 6.15 s; ripples follow the bow, the keel and every
/// drop. Rings and drops are a function of the clock (the prototype spawns
/// them; here their times are fixed), so a frame never depends on the last.
class _PoseFisk extends StatelessWidget {
  const _PoseFisk({super.key, required this.fra, required this.fisket});

  /// Head start in ms (`forskyv`).
  final double fra;
  final bool fisket;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LfLoop(
        frozenMs: 6200,
        builder: (context, tMs, _) {
          final f = PoseFiskFrame.at((tMs + fra) / 1000);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Boat shadow, Ægil, the boat.
              Positioned(
                left: 172 + f.bx,
                top: 66,
                width: 130,
                height: 18,
                child: CssBox(radius: const BorderRadius.all(Radius.elliptical(65, 9)), bg: [CssRadial.closestSide([rgba(3, 14, 20, .55), rgba(3, 14, 20, 0)])]),
              ),
              Positioned(
                left: 204,
                top: 10,
                width: 48,
                height: 56,
                child: Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.identity()
                    ..translateByDouble(f.bx, f.by + f.ay, 0, 1)
                    ..rotateZ((f.arot + f.brot * .6) * math.pi / 180),
                  child: Image.asset('assets/images/dashboard/side.png', fit: BoxFit.contain),
                ),
              ),
              // The bag (under the boat's gunwale once aboard).
              Positioned(
                left: 100,
                top: 40,
                width: 40,
                height: 44,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translateByDouble(f.pX - PoseFiskFrame.p0x, f.pY - PoseFiskFrame.p0y, 0, 1)
                    ..rotateZ(f.prot * math.pi / 180),
                  child: _PoseIVann(vann: f.iv),
                ),
              ),
              Positioned(
                left: 176,
                top: 30,
                width: 122,
                height: 46,
                child: Transform(
                  alignment: const Alignment(0, .4),
                  transform: Matrix4.identity()
                    ..translateByDouble(f.bx, f.by, 0, 1)
                    ..rotateZ(f.brot * math.pi / 180),
                  child: SvgPicture.string(_robaat, width: 122, height: 46),
                ),
              ),
              Positioned(left: 0, top: 0, width: 300, height: 112, child: CustomPaint(painter: _FiskPainter(f))),
              if (fisket)
                Positioned(
                  left: 168,
                  top: -8,
                  child: _PopInn(
                    ms: 500,
                    delayMs: 200,
                    child: CssBox(
                      radius: BorderRadius.circular(999),
                      padding: const EdgeInsets.fromLTRB(6, 3, 9, 3),
                      bg: const [CssLinear(180, [Color(0xFF8CF0D2), Color(0xFF3CC79F)])],
                      shadows: [
                        CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .55)),
                        const CssShadow(0, 2, 0, 0, Color(0xFF1F8A6B)),
                        CssShadow(0, 8, 12, -6, rgba(3, 16, 24, .7)),
                      ],
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.string(
                            '<svg viewBox="0 0 24 24" fill="none" stroke="#0F2A30" stroke-width="3.6" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l5 5 9-10"/></svg>',
                            width: 10,
                            height: 10,
                          ),
                          const SizedBox(width: 4),
                          Text(UtforskCopy.a1_auto_i_kurven, style: inter(10, weight: FontWeight.w800, color: const Color(0xFF0F2A30))),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static const String _robaat =
      '<svg viewBox="0 0 160 60"><path d="M6 30 C20 48 140 48 154 30 L146 44 C120 54 40 54 14 44 Z" fill="#54341E"/><path d="M6 30 C20 38 140 38 154 30" stroke="#B98A5C" stroke-width="2.5" fill="none"/><path d="M6 30 C2 24 2 18 8 14 M154 30 C158 24 158 18 152 14" stroke="#54341E" stroke-width="4" stroke-linecap="round" fill="none"/><path d="M40 34 L14 8 M120 34 L146 8" stroke="#8A6A42" stroke-width="3" stroke-linecap="round"/><path d="M10 6 L18 10 M150 6 L142 10" stroke="#B98A5C" stroke-width="3" stroke-linecap="round"/></svg>';
}

/// One frame of `poseFiskStart`'s tick, at `t` seconds.
class PoseFiskFrame {
  PoseFiskFrame._();

  static const double p0x = 120, p0y = 62, w = 71;

  late double t, bx, by, brot, ay, arot, pX, pY, prot, iv;
  late double tX, tY, cX, cY, bX, bY;
  late double dX, dY, eX, eY, slack, vis, dVis, kjolOp;
  final List<({double x, double y, double s, double age})> rings = <({double x, double y, double s, double age})>[];
  final List<Offset> drops = [];

  static double _cl(double x) => x.clamp(0.0, 1.0);
  static double _seg(double x, double a, double b) => _cl((x - a) / (b - a));
  static double _lerp(double a, double b, double k) => a + (b - a) * k;
  static double _oc(double x) => 1 - math.pow(1 - x, 3).toDouble();
  static double _io(double x) => x < .5 ? 4 * x * x * x : 1 - math.pow(-2 * x + 2, 3).toDouble() / 2;

  /// The seven drops' launch (fixed instead of `Math.random()`).
  static final List<({double x0, double vx, double vy, double r})> _drops = () {
    final rnd = math.Random(7);
    return [
      for (var n = 0; n < 7; n++)
        (x0: -8 + rnd.nextDouble() * 16, vx: -14 + rnd.nextDouble() * 40, vy: -30 - rnd.nextDouble() * 30, r: 1 + rnd.nextDouble() * .8),
    ];
  }();

  static ({double bx, double by, double brot}) _baat(double t) {
    final bIn = _oc(_seg(t, 0, 1.3));
    return (bx: (1 - bIn) * 240, by: math.sin(t * 1.7) * 1.1, brot: math.sin(t * 1.7 + .6) * 1.1 - (1 - bIn) * 2.5);
  }

  static ({double x, double y}) _pose(double t) {
    var pX = p0x, pY = p0y + math.sin(t * 2.2) * 1.2;
    if (t >= 2.64 && t < 2.92) pY += math.sin(_seg(t, 2.64, 2.92) * math.pi) * 2.5;
    if (t >= 2.92 && t < 3.88) {
      final k = _io(_seg(t, 2.92, 3.88));
      pX = _lerp(p0x, 166, k);
      pY = p0y + math.sin(t * 16) * .9;
    } else if (t >= 3.88) {
      final b = _baat(t);
      final k = _io(_seg(t, 3.88, 4.3)), ex = 196 + b.bx, ey = 48 + b.by;
      pX = _lerp(166, ex, k);
      pY = _lerp(p0y, ey, k) - math.sin(k * math.pi) * 42;
    }
    return (x: pX, y: pY);
  }

  static PoseFiskFrame at(double t) {
    final f = PoseFiskFrame._()..t = t;
    final b = _baat(t);
    f.bx = b.bx;
    f.by = b.by;
    f.brot = b.brot;
    double ay = 0, arot = 0;
    if (t > 1.3 && t < 1.55) {
      arot = 4 * _seg(t, 1.3, 1.55);
    } else if (t >= 1.55 && t < 1.85) {
      arot = _lerp(4, -6, _oc(_seg(t, 1.55, 1.85)));
    } else if (t >= 1.85 && t < 2.92) {
      arot = -3;
    } else if (t >= 2.92 && t < 3.88) {
      arot = 7 + math.sin(t * 16) * 1.4;
    } else if (t >= 3.88 && t < 4.3) {
      arot = _lerp(7, 0, _seg(t, 3.88, 4.3));
    }
    if (t > 4.35 && t < 6.15) {
      final h = ((t - 4.35) % .9) / .9;
      ay = -math.sin(math.min(1, h / .55) * math.pi) * 8;
    }
    f.ay = ay;
    f.arot = arot;
    double al;
    if (t < 1.3) {
      al = 10;
    } else if (t < 1.55) {
      al = _lerp(10, -30, _io(_seg(t, 1.3, 1.55)));
    } else if (t < 1.85) {
      al = _lerp(-30, 66, _oc(_seg(t, 1.55, 1.85)));
    } else if (t < 2.92) {
      al = 60 + math.sin(t * 3) * 1.6 + (t > 2.34 && t < 2.42 ? 4 : 0) + (t > 2.64 && t < 2.78 ? 7 : 0);
    } else if (t < 3.06) {
      al = _lerp(60, 22, _oc(_seg(t, 2.92, 3.06)));
    } else if (t < 3.88) {
      al = 28 + math.sin(t * 14) * 3.5;
    } else if (t < 4.3) {
      al = _lerp(28, 4, _io(_seg(t, 3.88, 4.3)));
    } else {
      al = 4 + math.sin(t * 1.7) * 1;
    }
    double bend = 0;
    if (t >= 1.55 && t < 1.85) {
      bend = -7 * math.sin(_seg(t, 1.55, 1.85) * math.pi);
    } else if (t >= 2.64 && t < 2.92) {
      bend = 4 * math.sin(_seg(t, 2.64, 2.92) * math.pi);
    } else if (t >= 2.92 && t < 3.88) {
      bend = 11 + math.sin(t * 14) * 2.4;
    } else if (t >= 3.88 && t < 4.3) {
      bend = 11 * (1 - _io(_seg(t, 3.88, 4.3)));
    }
    final ar = al * math.pi / 180;
    const len = 64.0;
    f.bX = 204 + b.bx + 13;
    f.bY = 10 + b.by + ay + 30;
    final px = -math.cos(ar), py = math.sin(ar);
    f.tX = f.bX - math.sin(ar) * len + px * bend * .9;
    f.tY = f.bY - math.cos(ar) * len + py * bend * .9;
    f.cX = (f.bX + f.tX) / 2 + px * bend * .55;
    f.cY = (f.bY + f.tY) / 2 + py * bend * .55;

    final pp = _pose(t);
    f.pX = pp.x;
    f.pY = pp.y;
    f.prot = math.sin(t * 1.6) * 3;
    f.iv = 1;
    if (t >= 2.92 && t < 3.88) {
      final k = _io(_seg(t, 2.92, 3.88));
      f.prot = -12 * math.sin(k * math.pi) + math.sin(t * 16) * 2.2;
    } else if (t >= 3.88) {
      final k = _io(_seg(t, 3.88, 4.3));
      f.prot = math.sin(k * math.pi) * 28 + (k >= 1 ? b.brot : 0);
      f.iv = 1 - _cl(k * 5);
    }

    f.eX = 0;
    f.eY = 0;
    f.slack = 0;
    f.vis = 0;
    f.dVis = 0;
    f.dX = 132;
    f.dY = w;
    if (t >= 1.55 && t < 1.86) {
      final k = _oc(_seg(t, 1.55, 1.86));
      f.dX = _lerp(f.tX, 132, k);
      f.dY = _lerp(f.tY, w, k) - math.sin(k * math.pi) * 20;
      f.eX = f.dX;
      f.eY = f.dY;
      f.slack = .15;
      f.vis = 1;
      f.dVis = 1;
    } else if (t >= 1.86 && t < 2.92) {
      final napp = (t > 2.34 && t < 2.44 ? 2.4 : 0) + (t > 2.64 && t < 2.86 ? 4.5 : 0);
      f.dY = w - 1 + math.sin(t * 5) * .6 + napp;
      f.eX = f.dX;
      f.eY = f.dY;
      f.slack = t < 2.64 ? .55 : .2;
      f.vis = 1;
      f.dVis = napp > 4 ? .3 : 1;
    } else if (t >= 2.92 && t < 4.3) {
      f.eX = f.pX + 5;
      f.eY = f.pY - 16;
      f.slack = .03;
      f.vis = t < 4.25 ? 1 : 0;
      f.dVis = 0;
    }
    f.kjolOp = t >= 2.95 && t < 3.88 ? math.sin(_seg(t, 2.95, 3.88) * math.pi) * .85 : 0;

    // Rings: the fixed ones, the bow wave, the keel and the drops' splashes.
    void ring(double at, double x, double y, double s) {
      final age = (t - at) / (1.1 * s);
      if (age >= 0 && age < 1) f.rings.add((x: x, y: y, s: s, age: age));
    }

    for (final r in const [(1.86, 132.0, w, 1.0), (2.34, 132.0, w, .7), (2.64, 132.0, w, 1.0), (2.92, 120.0, w, 1.3), (3.88, 166.0, w, 1.2)]) {
      ring(r.$1, r.$2, r.$3, r.$4);
    }
    for (var at = 0.0; at < 1.2; at += .16) {
      ring(at, 182 + _baat(at).bx, w + 3, .6);
    }
    for (var at = 2.95; at < 3.85; at += .2) {
      ring(at, _pose(at).x + 14, w, .45);
    }
    // Drops leave the bag at 3.9 s.
    const d0 = 3.9;
    final launch = _pose(d0);
    for (final d in _drops) {
      final a = t - d0;
      final y0 = launch.y + 14;
      // Lands when y0 + vy·a + 160·a² = w + 2 (a > .1).
      final disc = d.vy * d.vy - 4 * 160 * (y0 - w - 2);
      final land = disc < 0 ? 1.0 : (-d.vy + math.sqrt(disc)) / 320;
      final x0 = launch.x + d.x0;
      if (a >= 0 && a < land) {
        f.drops.add(Offset(x0 + d.vx * a, y0 + d.vy * a + 160 * a * a));
      } else if (a >= land) {
        ring(d0 + land, x0 + d.vx * land, w, .3);
      }
    }
    return f;
  }
}

class _FiskPainter extends CustomPainter {
  const _FiskPainter(this.f);

  final PoseFiskFrame f;

  @override
  void paint(Canvas canvas, Size size) {
    const w = PoseFiskFrame.w;
    for (final r in f.rings) {
      final rx = (4 + r.age * 30) * r.s;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(r.x, r.y), width: rx * 2, height: rx * .52),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = rgba(230, 248, 252, .9 * (1 - r.age) * .85),
      );
    }
    if (f.kjolOp > 0) {
      final pX = f.pX;
      canvas.drawPath(
        Path()
          ..moveTo(pX - 34, w - 4)
          ..lineTo(pX - 14, w + 1)
          ..lineTo(pX - 34, w + 7)
          ..moveTo(pX - 50, w - 6)
          ..lineTo(pX - 38, w - 3)
          ..moveTo(pX - 50, w + 9)
          ..lineTo(pX - 38, w + 6),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = rgba(226, 248, 252, .75 * f.kjolOp),
      );
    }
    if (f.vis > 0) {
      final dx = f.eX - f.tX, dy = f.eY - f.tY;
      final sag = f.slack * math.sqrt(dx * dx + dy * dy) * .4;
      canvas.drawPath(
        Path()
          ..moveTo(f.tX, f.tY)
          ..quadraticBezierTo((f.tX + f.eX) / 2, (f.tY + f.eY) / 2 + sag, f.eX, f.eY),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .9
          ..strokeCap = StrokeCap.round
          ..color = rgba(255, 255, 255, .92),
      );
    }
    final rod = Path()
      ..moveTo(f.bX, f.bY)
      ..quadraticBezierTo(f.cX, f.cY, f.tX, f.tY);
    canvas.drawPath(
      rod,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8A5A2C), Color(0xFFF2D7A0)])
            .createShader(Rect.fromPoints(Offset(f.bX, f.bY), Offset(f.tX, f.tY))),
    );
    canvas.drawCircle(Offset(f.tX, f.tY), 1.6, Paint()..color = const Color(0xFFFF9466));
    if (f.dVis > 0) {
      canvas.save();
      canvas.translate(f.dX, f.dY);
      final o = f.dVis;
      canvas.drawCircle(
        Offset.zero,
        3.2,
        Paint()
          ..shader = RadialGradient(center: const Alignment(-.3, -.4), radius: .8, colors: [
            Colors.white.withValues(alpha: o),
            const Color(0xFFFF9466).withValues(alpha: o),
            const Color(0xFFC9461C).withValues(alpha: o),
          ], stops: const [0, .5, 1]).createShader(Rect.fromCircle(center: Offset.zero, radius: 3.2)),
      );
      canvas.drawLine(const Offset(0, -3), const Offset(0, -7), Paint()
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: o));
      canvas.restore();
    }
    final dp = Paint()..color = const Color(0xFFE2F6FA);
    for (var i = 0; i < f.drops.length; i++) {
      canvas.drawCircle(f.drops[i], PoseFiskFrame._drops[i].r, dp);
    }
  }

  @override
  bool shouldRepaint(_FiskPainter old) => true;
}
