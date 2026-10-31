import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;

import '../../common/auth/launch/lf_css.dart' show kf, rad, cssEaseInOut, cssEaseOut;
import '../../common/auth/launch/lf_motion.dart' show LfLoop, aegStaa;
import '../../common/auth/onboarding_kit.dart' show onbDisplay, OnbTimeline, onbP;
import '../kit/bergen_perf.dart';
import '../kit/svg_sti.dart';
import 'onb_maal.dart';
import 'onb_runde.dart';
import 'onb_steg.dart';

// ── Design constants (prototype L792–885, L11154–11302, rtVals L16851) ──────

const Color _morkt = Color(0xFF04121A);
const Color _mint = Color(0xFF5CE0B8);
const Color _mintLys = Color(0xFF7FF0CB);
const Color _mintTekst = Color(0xFFBFF3E2);
const Color _teal = Color(0xFF1E4F5C);
const Cubic _e = Cubic(.45, 0, .15, 1);
const Cubic _e2 = Cubic(.22, 1, .36, 1);
const Cubic _hopp = Cubic(.3, 1.3, .5, 1);
const double _frame = 390;

/// Ægil-runden's layer over the whole app (prototype `data-rt-lag`, z 86):
/// the dim with the rounded hole, the frame with its corner marks and waves,
/// the tether, the HUD, the card with Ægil, and the drops. It listens to
/// [OnbRunde] and animates between its states; the engine never knows the
/// geometry, the layer never changes the state.
///
/// Sizes are the design's 390-frame values × `s` (width / 390). The height
/// is the real screen height, the top limits move under the status bar.
class OnbLag extends StatefulWidget {
  const OnbLag({super.key});

  @override
  State<OnbLag> createState() => _OnbLagState();
}

class _OnbLagState extends State<OnbLag> {
  final OnbRunde _r = OnbRunde.instance;
  _Geo? _g;
  _Aeg? _a;
  int _gRev = -1, _aRev = -1;

  /// The done card's Ægil, where the kai-hopp starts from.
  final GlobalKey _ferdigAeg = GlobalKey();
  Rect? _kaiFra;

  @override
  void initState() {
    super.initState();
    _r.addListener(_endret);
  }

  @override
  void dispose() {
    _r.removeListener(_endret);
    super.dispose();
  }

  void _endret() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_r.aktiv) return const SizedBox.shrink();
    final mq = MediaQuery.of(context);
    final W = mq.size.width, H = mq.size.height, s = W / _frame, top = mq.padding.top;
    final still = BergenPerf.of(context) == BergenTier.still;
    final rolig = _r.rolig || still;
    final stor = mq.textScaler.scale(10) >= 11.5;
    _r.bandLo = () => top + 90 * s;
    _r.bandHi = () => H - 204 * s;

    final steg = _r.naa!;
    final fase = _r.fase;
    final her = fase == OnbFase.her, jubel = fase == OnbFase.jubel, ferdig = fase == OnbFase.ferdig;
    final stempel = fase == OnbFase.stempel, kai = fase == OnbFase.kai, ut = fase == OnbFase.ut || kai;
    final intro = steg.intro;
    final m = (ferdig || stempel || ut || intro) ? null : _r.m;
    final hull = onbHull(m, W, H, s);
    // The geometry and Ægil's pose stay put while the step changes, so
    // nothing jumps before the next target is found (`_rtG`, `_rtA`).
    if (her || jubel || _g == null || _gRev != _r.rev && (her || jubel)) {
      if (her || jubel || _g == null) {
        _g = _beregn(hull, m != null, steg, W, H, s, top, stor);
        _gRev = _r.rev;
      }
    }
    final g = _g!;
    if (her || jubel || stempel || _a == null) {
      final titt = her && intro;
      _Anim anim;
      if (jubel || stempel) {
        anim = _Anim.jubel;
      } else if (titt) {
        anim = _Anim.titt;
      } else if (her) {
        anim = _Anim.hopp;
      } else {
        anim = _Anim.idle;
      }
      final pose = (jubel || stempel) ? OnbPose.voucher : steg.pose;
      if (_a == null || _a!.anim != anim || _a!.pose != pose || _aRev != _r.n) {
        _a = _Aeg(anim, pose, _r.n);
        _aRev = _r.n;
      }
    }
    final a = _a!;
    final kVis = !(ferdig || ut);
    if (ferdig || ut) _g ??= _beregn(hull, false, steg, W, H, s, top, stor);
    final ab = _r.n.isOdd;
    final markOp = (her || jubel) && m != null;
    final hudSkjul = g.hudSkjul;
    final hudVis = !ferdig && !ut && (stempel || !hudSkjul);
    final tx = steg.malAlt != null && _r.malNaa == steg.malAlt ? steg.txAlt! : steg.tx;
    final oppdrag = steg.malAlt != null && _r.malNaa == steg.malAlt ? steg.oppdragAlt : steg.oppdrag;
    final harOppdrag = oppdrag != null;
    final qOk = jubel && harOppdrag;
    final sekNavn = intro ? OnbCopy.velkommen : kOnbSeksjoner.firstWhere((x) => x.id == steg.sek).navn;
    final dim = ferdig ? .66 : (jubel ? .42 : .56);
    Duration d(int ms) => Duration(milliseconds: rolig ? 1 : ms);

    final aegX = !g.harM ? (g.bw - g.aW) / 2 : (g.aegLeft ? 10 * s : g.bw - g.aW - 10 * s);
    final flip = !g.harM ? 1.0 : (g.aegLeft ? 1.0 : -1.0);

    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
        IgnorePointer(
        ignoring: ut,
        child: AnimatedOpacity(
          key: const Key('onb-lag'),
          opacity: ut ? 0 : 1,
          duration: d(420),
          child: DefaultTextStyle(
            style: onbDisplay(14 * s),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // The dim and the hole, one painter; the hole glides with the target.
                Positioned.fill(
                  child: IgnorePointer(
                    child: _Innfade(
                      ms: rolig ? 1 : 500,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: dim),
                        duration: d(600),
                        builder: (context, op, _) => TweenAnimationBuilder<OnbHullRekt>(
                          tween: _OnbHullTween(end: hull),
                          duration: d(760),
                          curve: _e,
                          builder: (context, h, _) => CustomPaint(
                            painter: _DimMaler(h, op),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                if (markOp || jubel)
                                  Positioned(
                                    left: h.x,
                                    top: h.y,
                                    width: h.w,
                                    height: h.h,
                                    child: _Ramme(
                                      key: ValueKey('ramme-${_r.n}'),
                                      h: h,
                                      s: s,
                                      vis: markOp,
                                      ab: ab,
                                      jubel: jubel,
                                      hand: her && harOppdrag && m != null,
                                      rolig: rolig,
                                      W: W,
                                      H: H,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Taps: around the hole they advance a free step; inside it
                // they advance too, unless it is a mission (the control takes them).
                ..._treff(hull, W, H, her, harOppdrag, m != null),
                // The tether from the card to the target.
                if (g.tet != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: her ? 1 : 0,
                        duration: her ? d(400) : d(140),
                        curve: her ? const Interval(.63, 1) : Curves.linear,
                        child: LfLoop(
                          builder: (context, t, _) => CustomPaint(painter: _TetMaler(g.tet!, s, t)),
                        ),
                      ),
                    ),
                  ),
                // The HUD.
                Positioned(
                  left: 48 * s,
                  top: top + 12 * s,
                  width: 294 * s,
                  height: 44 * s,
                  child: IgnorePointer(
                    ignoring: !hudVis,
                    child: AnimatedSlide(
                      offset: Offset(0, hudVis ? 0 : -64 / 44),
                      duration: d(620),
                      curve: _e,
                      child: AnimatedOpacity(
                        opacity: hudVis ? 1 : 0,
                        duration: d(420),
                        child: _Hud(
                          s: s,
                          steg: steg,
                          alleSteg: _r.steg,
                          i: _r.i,
                          ferdige: _r.ferdigeSek,
                          nySek: _r.nySek,
                          intro: intro,
                          ferdig: ferdig,
                          rolig: rolig,
                          onLukk: _r.avslutt,
                        ),
                      ),
                    ),
                  ),
                ),
                // The card with Ægil, placed by the geometry; slides with it.
                TweenAnimationBuilder<Offset>(
                  tween: Tween(end: Offset(g.bx, g.by)),
                  duration: d(800),
                  curve: _e,
                  builder: (context, p, child) => Positioned(left: p.dx, top: p.dy, width: g.bw, child: child!),
                  child: AnimatedOpacity(
                    opacity: kVis ? 1 : 0,
                    duration: d(400),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Ægil, on the card's top edge, left or right of it.
                        Positioned(
                          left: 0,
                          top: 0,
                          child: IgnorePointer(
                            child: TweenAnimationBuilder<Offset>(
                              tween: Tween(end: Offset(aegX, -g.up)),
                              duration: d(740),
                              curve: _e,
                              builder: (context, p, child) => Transform.translate(offset: p, child: child),
                              child: AnimatedOpacity(
                                opacity: kVis ? 1 : 0,
                                duration: d(340),
                                child: Transform.scale(
                                  scale: g.aW / (128 * s),
                                  alignment: Alignment.topLeft,
                                  child: SizedBox(
                                    width: 128 * s,
                                    height: 128 * s,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Positioned.fill(
                                          child: TweenAnimationBuilder<double>(
                                            tween: Tween(end: flip),
                                            duration: d(360),
                                            curve: _e,
                                            builder: (context, f, child) => Transform(
                                              alignment: Alignment.center,
                                              transform: Matrix4.diagonal3Values(f, 1, 1),
                                              child: child,
                                            ),
                                            child: _AegilFigur(key: ValueKey('aeg-${a.n}-${a.anim.name}-${a.pose.name}'), a: a, s: s, rolig: rolig),
                                          ),
                                        ),
                                        // Six drops when he lands beside the target.
                                        if (her && !intro && !rolig)
                                          Positioned(
                                            left: 64 * s,
                                            top: 0,
                                            child: _Draper(key: ValueKey('dr-${_r.n}'), s: s, titt: false, ab: ab, skala: 128 * s / g.aW),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // The card itself, under or over the target.
                        FractionalTranslation(
                          translation: Offset(0, g.under ? 0 : -1),
                          child: IgnorePointer(
                            ignoring: !(her || jubel),
                            child: AnimatedScale(
                              scale: kVis ? 1 : .94,
                              duration: d(550),
                              curve: const Cubic(.3, 1.25, .5, 1),
                              alignment: g.under ? Alignment.topCenter : Alignment.bottomCenter,
                              child: _KortInn(
                                intro: intro && her,
                                rolig: rolig,
                                under: g.under,
                                child: _Kort(
                                  key: ValueKey('kort-${steg.id}-${_r.malNaa}'),
                                  s: s,
                                  stor: stor,
                                  rolig: rolig,
                                  sekNavn: sekNavn,
                                  teller: intro ? OnbCopy.ettMinutt : OnbCopy.stegAv(_r.i, _r.antall - 1),
                                  tx: tx,
                                  typStart: intro ? 760 : (_r.etterSt ? 420 : 280),
                                  her: her,
                                  jubel: jubel,
                                  n: _r.n,
                                  oppdrag: oppdrag,
                                  qOk: qOk,
                                  visHopp: !intro,
                                  visTilbake: !intro && _r.i > 1 && !jubel,
                                  visSenere: intro,
                                  visNeste: !harOppdrag,
                                  nesteTx: intro ? OnbCopy.bliMed : (_r.i == _r.antall - 1 ? OnbCopy.fullfor : OnbCopy.neste),
                                  handling: steg.handling,
                                  visVisMeg: harOppdrag && !jubel,
                                  onNeste: _r.neste,
                                  onTilbake: _r.tilbake,
                                  onHopp: _r.avslutt,
                                  onVisMeg: _r.visMeg,
                                  onHandling: () => _r.handling(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // The section stamp: slams in, flies to its HUD station.
                if (stempel && _r.stempel != null)
                  _Stempel(
                    key: ValueKey('st-${_r.stempel}'),
                    s: s,
                    W: W,
                    H: H,
                    top: top,
                    sek: kOnbSeksjoner.firstWhere((x) => x.id == _r.stempel),
                    k: kOnbSeksjoner.indexWhere((x) => x.id == _r.stempel),
                    fly: _r.stFly,
                    rolig: rolig,
                  ),
                // The done card.
                if (ferdig)
                  _FerdigKort(
                    s: s,
                    W: W,
                    H: H,
                    rolig: rolig,
                    aegKey: _ferdigAeg,
                    onStart: () {
                      final rb = _ferdigAeg.currentContext?.findRenderObject();
                      _kaiFra = rb is RenderBox && rb.attached && rb.hasSize ? (rb.localToGlobal(Offset.zero) & rb.size) : null;
                      _r.kaiHoppKan = _kaiFra != null;
                      _r.slutt();
                    },
                  ),
              ],
            ),
          ),
        ),
        ),
            // «Start å handle»: Ægil jumps out of the card onto the quay.
            if (kai && _kaiFra != null) _KaiHopp(key: const ValueKey('kai'), fra: _kaiFra!, s: s, W: W, H: H, r: _r),
          ],
        ),
      ),
    );
  }

  /// The four tap areas around the hole, and the hole itself on a free step.
  List<Widget> _treff(OnbHullRekt h, double W, double H, bool her, bool oppdrag, bool harM) {
    final r = _r;
    Widget flate(double l, double t, double w, double hh, VoidCallback fn) => Positioned(
      left: l,
      top: t,
      width: math.max(0, w),
      height: math.max(0, hh),
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: fn),
    );
    return [
      flate(0, 0, W, h.y, r.bak),
      flate(0, h.y + h.h, W, H - (h.y + h.h), r.bak),
      flate(0, h.y, h.x, h.h, r.bak),
      flate(h.x + h.w, h.y, W - (h.x + h.w), h.h, r.bak),
      if (her && harM && !oppdrag) flate(h.x, h.y, h.w, h.h, r.neste),
    ];
  }
}

// ── Geometry (rtVals) ───────────────────────────────────────────────────────

class OnbHullRekt {
  const OnbHullRekt(this.x, this.y, this.w, this.h, this.r, {this.hjorne = const {}});
  final double x, y, w, h, r;

  /// Which screen corners the hole touches (concentric marks there).
  final Set<String> hjorne;

  bool get iHjorne => hjorne.isNotEmpty;
  Rect get rect => Rect.fromLTWH(x, y, w, h);

  static OnbHullRekt lerp(OnbHullRekt a, OnbHullRekt b, double t) => OnbHullRekt(
    ui.lerpDouble(a.x, b.x, t)!,
    ui.lerpDouble(a.y, b.y, t)!,
    ui.lerpDouble(a.w, b.w, t)!,
    ui.lerpDouble(a.h, b.h, t)!,
    ui.lerpDouble(a.r, b.r, t)!,
    hjorne: t < .5 ? a.hjorne : b.hjorne,
  );
}

class _OnbHullTween extends Tween<OnbHullRekt> {
  _OnbHullTween({super.begin, super.end});

  @override
  OnbHullRekt lerp(double t) => OnbHullRekt.lerp(begin!, end!, t);
}

/// The hole (`rtVals`, public for the tests): 12 px inside the screen, tight air (2) for small targets, 7
/// otherwise; in a screen corner it becomes concentric with the phone's
/// corner (36 px) so frame and marks are never clipped.
OnbHullRekt onbHull(dynamic m, double W, double H, double s) {
  if (m == null) return OnbHullRekt(W / 2, 400 * s, 0, 0, 0);
  final M = 12 * s;
  final pd = (m.w < 110 * s && m.h < 80 * s) ? 2 * s : 7 * s;
  final x = math.max(M, m.x - pd), y = math.max(M, m.y - pd);
  final x2 = math.min(W - M, m.x + m.w + pd), y2 = math.min(H - M, m.y + m.h + pd);
  final w = math.max(10 * s, x2 - x), h = math.max(10 * s, y2 - y);
  final kant = m.x - pd < M || m.x + m.w + pd > W - M;
  var r = math.max(0.0, <double>[m.radius * s + (kant ? 0 : pd), 30 * s, w / 2, h / 2].reduce(math.min));
  final oo = y <= M + .5, uu = y2 >= H - M - .5, vv = x <= M + .5, hh = x2 >= W - M - .5;
  final hj = <String>{if (oo && vv) 'TL', if (oo && hh) 'TR', if (uu && vv) 'BL', if (uu && hh) 'BR'};
  if (hj.isNotEmpty) r = math.max(r, <double>[36 * s - M, w / 2, h / 2].reduce(math.min));
  return OnbHullRekt(x, y, w, h, r, hjorne: hj);
}

class _Tet {
  const _Tet(this.x0, this.y0, this.x1, this.y1);
  final double x0, y0, x1, y1;
}

class _Geo {
  const _Geo({
    required this.bx,
    required this.by,
    required this.bw,
    required this.under,
    required this.aegLeft,
    required this.tet,
    required this.hudSkjul,
    required this.aW,
    required this.up,
    required this.harM,
  });
  final double bx, by, bw, aW, up;
  final bool under, aegLeft, hudSkjul, harM;
  final _Tet? tet;
}

/// Where the card and Ægil go (`beregn()`): under the target when there is
/// room, else over it; Ægil on the side nearer the target; the tether when
/// the gap is at least 18 px.
_Geo _beregn(OnbHullRekt hull, bool harM, OnbSteg s0, double W, double H, double s, double top, bool stor) {
  final intro = s0.intro;
  final bw = 326 * s;
  final aW = (intro ? (stor ? 112 : 128) : (stor ? 74 : 84)) * s;
  final up = aW - (aW * .34).roundToDouble();
  final tx = s0.tx;
  final linjer = (tx.length / (stor ? 28 : 35)).ceil();
  final est = (46 + linjer * (stor ? 24 : 20.5) + (s0.harOppdrag ? 68 : 0) + 56) * s;
  var bx = (W - bw) / 2, by = (intro ? 396 : 430) * H / 844;
  var under = true, aegLeft = true;
  _Tet? tet;
  final hudSkjul = harM && hull.y < top + 66 * s;
  if (harM) {
    final cx = hull.x + hull.w / 2, cy = hull.y + hull.h / 2;
    final gU = up + 12 * s, gO = 34 * s, topMin = (hudSkjul ? top + 12 * s : top + 66 * s) + up;
    final bunn = H - 8 * s;
    final kanU = hull.y + hull.h + gU + est <= bunn, kanO = hull.y - gO - est >= topMin;
    under = cy < H / 2 ? (kanU || !kanO) : (!kanO && kanU);
    if (!kanU && !kanO) under = (bunn - (hull.y + hull.h)) >= (hull.y - topMin);
    by = under ? math.min(hull.y + hull.h + gU, bunn - est) : math.max(hull.y - gO, est + topMin);
    bx = (cx - bw / 2).clamp(10 * s, W - 10 * s - bw);
    aegLeft = cx >= W / 2;
    final lo = aegLeft ? bx + aW + 18 * s : bx + 28 * s, hi = aegLeft ? bx + bw - 28 * s : bx + bw - aW - 18 * s;
    final ax = cx.clamp(math.min(lo, hi), math.max(lo, hi)).toDouble();
    final x1 = ax.clamp(hull.x + 12 * s, math.max(hull.x + 12 * s, hull.x + hull.w - 12 * s)).toDouble();
    final y1 = under ? hull.y + hull.h : hull.y;
    final gap = under ? by - y1 : y1 - by;
    if (gap >= 18 * s) tet = _Tet(ax, by, x1, y1);
  }
  return _Geo(bx: bx, by: by, bw: bw, under: under, aegLeft: aegLeft, tet: tet, hudSkjul: hudSkjul, aW: aW, up: up, harM: harM);
}

// ── Painters ────────────────────────────────────────────────────────────────

class _DimMaler extends CustomPainter {
  _DimMaler(this.h, this.op);
  final OnbHullRekt h;
  final double op;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    if (h.w > 0 && h.h > 0) p.addRRect(RRect.fromRectAndRadius(h.rect, Radius.circular(h.r)));
    canvas.drawPath(p, Paint()..color = _morkt.withValues(alpha: op));
  }

  @override
  bool shouldRepaint(_DimMaler o) => o.h != h || o.op != op;
}

/// The tether: a dotted curve (`0.1 7` dashes, marching), a dot at the card
/// end and a pulsing dot at the target.
class _TetMaler extends CustomPainter {
  _TetMaler(this.t, this.s, this.ms);
  final _Tet t;
  final double s, ms;

  @override
  void paint(Canvas canvas, Size size) {
    final my = (t.y0 + t.y1) / 2;
    final path = Path()
      ..moveTo(t.x0, t.y0)
      ..cubicTo(t.x0, my, t.x1, my, t.x1, t.y1);
    final off = -7.1 * s * ((ms / 700) % 1.0);
    final dashed = svgStreker(path, [.1 * s, 7 * s], off);
    canvas.drawPath(
      dashed,
      Paint()
        ..color = _mint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6 * s
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(t.x1, t.y1), 4.5 * s, Paint()..color = _mint);
    final p = (ms / 1600) % 1.0;
    final k = kf(p, const [0, 1], const [1, 3.2], cssEaseOut), a = kf(p, const [0, 1], const [.9, 0], cssEaseOut);
    canvas.drawCircle(
      Offset(t.x1, t.y1),
      4.5 * s * k,
      Paint()
        ..color = _mint.withValues(alpha: a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * s,
    );
    canvas.drawCircle(Offset(t.x0, t.y0), 3 * s, Paint()..color = _mint);
  }

  @override
  bool shouldRepaint(_TetMaler o) => o.ms != ms || o.t != t;
}

/// One SVG icon path (24-unit box) as a stroke.
class _Ikon extends StatelessWidget {
  const _Ikon(this.d, {required this.size, required this.color, this.strokeWidth = 2, this.fill = false});
  final String d;
  final double size, strokeWidth;
  final Color color;
  final bool fill;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _IkonMaler(d, color, strokeWidth, fill));
}

class _IkonMaler extends CustomPainter {
  _IkonMaler(this.d, this.color, this.sw, this.fill);
  final String d;
  final Color color;
  final double sw;
  final bool fill;
  static final Map<String, Path> _cache = {};

  @override
  void paint(Canvas canvas, Size size) {
    final p = _cache.putIfAbsent(d, () => svgSti(d));
    final k = size.width / 24;
    canvas.save();
    canvas.scale(k);
    canvas.drawPath(
      p,
      Paint()
        ..color = color
        ..style = fill ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IkonMaler o) => o.d != d || o.color != color || o.sw != sw;
}

const String _ikPil = 'M5 12h13M13 6l6 6-6 6';
const String _ikHand = 'M9 11V5.5a1.5 1.5 0 0 1 3 0V11m0-1.5a1.5 1.5 0 0 1 3 0V11m0-.5a1.5 1.5 0 0 1 3 0V15a5 5 0 0 1-5 5h-1.5a5 5 0 0 1-4.2-2.3L5 14.5a1.5 1.5 0 0 1 2.5-1.6L9 15';
const String _ikHopp = 'M6 6l6 6-6 6M13 6l6 6-6 6';
const String _ikTilbake = 'M15 6l-6 6 6 6';
const String _ikHak = 'M4.5 12.5l5 5 10-11';
const String _ikKryss = 'M6 6l12 12M18 6L6 18';

/// A layer-wide fade on mount (`vkFade .5s`).
class _Innfade extends StatelessWidget {
  const _Innfade({required this.ms, required this.child});
  final double ms;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: ms.round()),
    builder: (context, v, child) => Opacity(opacity: v, child: child),
    child: child,
  );
}

// ── The frame around the hole ───────────────────────────────────────────────

class _Ramme extends StatelessWidget {
  const _Ramme({
    super.key,
    required this.h,
    required this.s,
    required this.vis,
    required this.ab,
    required this.jubel,
    required this.hand,
    required this.rolig,
    required this.W,
    required this.H,
  });
  final OnbHullRekt h;
  final double s, W, H;
  final bool vis, ab, jubel, hand, rolig;

  @override
  Widget build(BuildContext context) {
    final r4 = h.r + 4 * s;
    final hj = h.iHjorne;
    final mR = hj ? h.r + 9 * s : 12 * s, mS = hj ? mR + 6 * s : 18 * s;
    // The hand button sits on the lower right corner, kept inside the screen
    // and clear of the phone's rounded corners (26 px pulse + 36 px radius).
    final hp = _haand(h, s, W, H);
    return AnimatedOpacity(
      opacity: vis ? 1 : 0,
      duration: Duration(milliseconds: vis ? 0 : (rolig ? 1 : 160)),
      child: OnbTimeline(
        durationMs: rolig ? 1 : 4000,
        builder: (context, t, _) {
          // rtRamInn .5s .52s: the frame scales in from 1.08.
          final inn = onbP(t, rolig ? 0 : 520, rolig ? 1 : 500);
          final innC = _e2.transform(inn);
          final tegn = onbP(t, rolig ? 0 : 560, rolig ? 1 : 800);
          final tegnC = const Cubic(.65, 0, .35, 1).transform(tegn);
          final blink = jubel ? onbP(t, 0, 700) : 0.0;
          return Opacity(
            opacity: innC,
            child: Transform.scale(
              scale: 1.08 - .08 * innC,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Mint blink on success.
                  if (jubel)
                    Positioned.fill(
                      child: Opacity(
                        opacity: kf(blink, const [0, .22, 1], const [0, 1, 0]),
                        child: DecoratedBox(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(h.r), color: _mint.withValues(alpha: .3)),
                        ),
                      ),
                    ),
                  // Glow ring (box-shadow 0 0 0 1.5px .5 + 0 0 24px 4px .42), breathing.
                  Positioned.fill(
                    child: LfLoop(
                      builder: (context, ms, _) {
                        final p = (ms / 2400) % 1.0;
                        final a = kf(p, const [0, .5, 1], const [.35, 1, .35], cssEaseInOut);
                        return CustomPaint(painter: _GlodMaler(h, r4, s, a));
                      },
                    ),
                  ),
                  // The dashed rect, drawn on.
                  Positioned.fill(child: CustomPaint(painter: _TegnMaler(h, r4, s, tegnC))),
                  // The four corner marks.
                  for (final k in const ['TL', 'TR', 'BL', 'BR'])
                    Positioned.fill(
                      child: LfLoop(
                        builder: (context, ms, _) {
                          final p = (ms / 2400) % 1.0;
                          final v = hj ? 0.0 : kf(p, const [0, .5, 1], const [0, 3, 0], cssEaseInOut) * s;
                          final dx = k.endsWith('L') ? -v : v, dy = k.startsWith('T') ? -v : v;
                          return Transform.translate(offset: Offset(dx, dy), child: CustomPaint(painter: _HjorneMaler(k, h, s, mR, mS)));
                        },
                      ),
                    ),
                  // Two waves when the target is found.
                  if (!rolig) ...[
                    _Bolge(h: h, s: s, r4: r4, k: 1, t: t),
                    _Bolge(h: h, s: s, r4: r4, k: 2, t: t),
                  ],
                  // The hand on a mission.
                  if (hand) ...[
                    Positioned.fill(
                      child: LfLoop(
                        builder: (context, ms, _) {
                          final p = (ms / 1400) % 1.0;
                          return Opacity(
                            opacity: kf(p, const [0, .5, 1], const [.35, 1, .35], cssEaseInOut),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(r4),
                                border: Border.all(color: Colors.white.withValues(alpha: .85), width: 2 * s),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      left: hp.dx,
                      top: hp.dy,
                      width: 30 * s,
                      height: 30 * s,
                      child: LfLoop(
                        builder: (context, ms, _) {
                          final p = (ms / 1400) % 1.0;
                          final sk = kf(p, const [0, .4, 1], const [1, 1.05, 1], cssEaseInOut);
                          final rp = ((ms - 200) / 1400) % 1.0;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned.fill(
                                child: Transform.scale(
                                  scale: kf(rp, const [0, 1], const [1, 1.7], cssEaseOut),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withValues(alpha: .85 * kf(rp, const [0, 1], const [.9, 0], cssEaseOut)), width: 2 * s),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Transform.scale(
                                  scale: sk,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], stops: [0, .56, 1]),
                                      border: Border.all(color: Colors.white, width: 2 * s),
                                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .6), blurRadius: 12 * s, offset: Offset(0, 6 * s), spreadRadius: -4 * s)],
                                    ),
                                    child: Center(child: _Ikon(_ikHand, size: 16 * s, color: Colors.white, strokeWidth: 2.2)),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                  // Sparks on success.
                  if (jubel && !rolig)
                    for (var j = 0; j < 10; j++)
                      Positioned(
                        left: h.w / 2,
                        top: h.h / 2,
                        child: Transform.rotate(
                          angle: rad(j * 36.0),
                          child: Builder(
                            builder: (context) {
                              final p = onbP(t, (j % 3) * 30, 700);
                              final c = const Cubic(.2, .8, .3, 1).transform(p);
                              return Transform.translate(
                                offset: Offset(-4 * s, -4 * s + kf(c, const [0, 1], const [-18, -100]) * s),
                                child: Opacity(
                                  opacity: kf(p, const [0, .25, 1], const [0, 1, 0]),
                                  child: Transform.scale(
                                    scale: kf(c, const [0, 1], const [.4, 1]),
                                    child: Container(
                                      width: 8 * s,
                                      height: 8 * s,
                                      decoration: BoxDecoration(shape: BoxShape.circle, color: const [_mint, Color(0xFFF26D3D), Color(0xFFF2C14E)][j % 3]),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Offset _haand(OnbHullRekt h, double s, double W, double H) {
    final s0 = 30 * s, half = s0 / 2, ring = 26 * s, kant = ring + 2 * s, R = 36 * s;
    var cx = h.x + h.w - half - 4 * s, cy = h.y + h.h - half - 4 * s;
    cx = cx.clamp(kant, W - kant);
    cy = cy.clamp(kant, H - kant);
    for (final k in [Offset(R, R), Offset(W - R, R), Offset(R, H - R), Offset(W - R, H - R)]) {
      final iH = k.dx < W / 2 ? cx < k.dx : cx > k.dx, iV = k.dy < H / 2 ? cy < k.dy : cy > k.dy;
      if (!iH || !iV) continue;
      final dx = cx - k.dx, dy = cy - k.dy, d = math.sqrt(dx * dx + dy * dy), maks = R - ring;
      if (d <= maks) continue;
      final f = maks / (d == 0 ? 1 : d);
      cx = k.dx + dx * f;
      cy = k.dy + dy * f;
    }
    return Offset(cx - half - h.x, cy - half - h.y);
  }
}

class _GlodMaler extends CustomPainter {
  _GlodMaler(this.h, this.r4, this.s, this.a);
  final OnbHullRekt h;
  final double r4, s, a;

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(Rect.fromLTWH(-4 * s, -4 * s, size.width + 8 * s, size.height + 8 * s), Radius.circular(r4));
    canvas.drawRRect(
      rr.inflate(2 * s),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * s
        ..color = _mint.withValues(alpha: .42 * a)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * s),
    );
    canvas.drawRRect(
      rr.inflate(.75 * s),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * s
        ..color = _mint.withValues(alpha: .5 * a),
    );
  }

  @override
  bool shouldRepaint(_GlodMaler o) => o.a != a || o.h != h;
}

/// The dashed 2 px rect, drawn from 0 to [p] around the hole (`rtTegn`).
class _TegnMaler extends CustomPainter {
  _TegnMaler(this.h, this.r4, this.s, this.p);
  final OnbHullRekt h;
  final double r4, s, p;

  @override
  void paint(Canvas canvas, Size size) {
    if (p <= 0) return;
    final rr = RRect.fromRectAndRadius(Rect.fromLTWH(-4 * s, -4 * s, size.width + 8 * s, size.height + 8 * s), Radius.circular(r4));
    final path = Path()..addRRect(rr);
    final out = Path();
    for (final m in path.computeMetrics()) {
      out.addPath(m.extractPath(0, m.length * p), Offset.zero);
    }
    canvas.drawPath(
      out,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * s
        ..strokeCap = StrokeCap.round
        ..color = _mint,
    );
  }

  @override
  bool shouldRepaint(_TegnMaler o) => o.p != p || o.h != h;
}

/// One corner mark: an L of 3 px `#7FF0CB` with a rounded outer corner,
/// 18×18 at inset −9 (or concentric in a screen corner).
class _HjorneMaler extends CustomPainter {
  _HjorneMaler(this.k, this.h, this.s, this.r, this.size);
  final String k;
  final OnbHullRekt h;
  final double s, r, size;

  @override
  void paint(Canvas canvas, Size sz) {
    final inset = -9 * s;
    final left = k.endsWith('L');
    final top = k.startsWith('T');
    final x = left ? inset : sz.width - inset - size;
    final y = top ? inset : sz.height - inset - size;
    final rect = Rect.fromLTWH(x, y, size, size);
    final rr = RRect.fromRectAndCorners(
      rect,
      topLeft: k == 'TL' ? Radius.circular(r) : Radius.zero,
      topRight: k == 'TR' ? Radius.circular(r) : Radius.zero,
      bottomLeft: k == 'BL' ? Radius.circular(r) : Radius.zero,
      bottomRight: k == 'BR' ? Radius.circular(r) : Radius.zero,
    );
    // Clip to the two sides that carry a border.
    canvas.save();
    final clip = Path()..addRect(Rect.fromLTWH(left ? x - 2 : x + size / 2, top ? y - 2 : y + size / 2, size / 2 + 2, size / 2 + 2));
    canvas.clipPath(clip);
    canvas.drawRRect(
      rr.deflate(1.5 * s),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * s
        ..color = _mintLys,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HjorneMaler o) => o.k != k || o.size != size || o.r != r;
}

/// A wave: the border at inset −2 scaling out by 64 px, fading (WAAPI in the prototype).
class _Bolge extends StatelessWidget {
  const _Bolge({required this.h, required this.s, required this.r4, required this.k, required this.t});
  final OnbHullRekt h;
  final double s, r4, t;
  final int k;

  @override
  Widget build(BuildContext context) {
    final dur = 1050.0 + k * 120, delay = 520.0 + (k - 1) * 240 + 30;
    final p = _e2.transform(onbP(t, delay, dur));
    if (p <= 0 || p >= 1) return const SizedBox.shrink();
    final w = h.w + 18 * s, hh = h.h + 18 * s;
    final sx = 1 + p * 64 * s / w, sy = 1 + p * 64 * s / hh;
    return Positioned.fill(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(sx, sy, 1),
        child: Opacity(
          opacity: (k == 1 ? .9 : .6) * (1 - p),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(r4),
              border: Border.all(color: k == 1 ? _mint.withValues(alpha: .8) : Colors.white.withValues(alpha: .6), width: (k == 1 ? 2 : 1.5) * s),
            ),
          ),
        ),
      ),
    );
  }
}

// ── The HUD ─────────────────────────────────────────────────────────────────

class _Hud extends StatelessWidget {
  const _Hud({
    required this.s,
    required this.steg,
    required this.alleSteg,
    required this.i,
    required this.ferdige,
    required this.nySek,
    required this.intro,
    required this.ferdig,
    required this.rolig,
    required this.onLukk,
  });
  final double s;
  final OnbSteg steg;
  final List<OnbSteg> alleSteg;
  final int i;
  final List<String> ferdige;
  final String? nySek;
  final bool intro, ferdig, rolig;
  final VoidCallback onLukk;

  @override
  Widget build(BuildContext context) {
    final curK = kOnbSeksjoner.indexWhere((x) => x.id == steg.sek);
    final iSek = alleSteg.where((x) => x.sek == steg.sek && !x.intro).toList();
    final pos = math.max(0, iSek.indexOf(steg));
    final frac = intro ? 0.0 : (pos + 1) / math.max(1, iSek.length);
    final blur = BergenPerf.blurOn(context);
    return _HudInn(
      rolig: rolig,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          enabled: blur,
          filter: BergenPerf.blur(context, 18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(40, 94, 108, .94), Color.fromRGBO(20, 56, 68, .96)]),
              border: Border.all(color: Colors.white.withValues(alpha: .14)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .8), blurRadius: 28 * s, spreadRadius: -14 * s, offset: Offset(0, 16 * s))],
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: .22), width: 1.5 * s)),
            ),
            padding: EdgeInsets.only(left: 10 * s, right: 6 * s),
            child: Row(
              children: [
                for (var k = 0; k < kOnbSeksjoner.length; k++) ...[
                  if (k > 0)
                    Container(
                      width: 18 * s,
                      height: 3 * s,
                      margin: EdgeInsets.symmetric(horizontal: 3 * s),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(2 * s), color: Colors.white.withValues(alpha: .14)),
                      clipBehavior: Clip.antiAlias,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedFractionallySizedBox(
                          duration: Duration(milliseconds: rolig ? 1 : 850),
                          curve: _e,
                          widthFactor: !ferdige.contains(kOnbSeksjoner[k - 1].id) ? (k - 1 == curK && !intro ? frac : 0) : 1,
                          child: const DecoratedBox(decoration: BoxDecoration(color: _mint)),
                        ),
                      ),
                    ),
                  _Stasjon(
                    s: s,
                    sek: kOnbSeksjoner[k],
                    ok: ferdige.contains(kOnbSeksjoner[k].id),
                    naa: !intro && !ferdig && k == curK && !ferdige.contains(kOnbSeksjoner[k].id),
                    pop: nySek == kOnbSeksjoner[k].id,
                    rolig: rolig,
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  key: const Key('onb-hud-lukk'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onLukk,
                  child: Container(
                    width: 32 * s,
                    height: 32 * s,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: .08),
                      border: Border.all(color: Colors.white.withValues(alpha: .12)),
                    ),
                    child: Center(child: _Ikon(_ikKryss, size: 10 * s, color: Colors.white.withValues(alpha: .78), strokeWidth: 3)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `rtHudInn .7s .15s`: the HUD drops in from −14 px, scale .94.
class _HudInn extends StatelessWidget {
  const _HudInn({required this.rolig, required this.child});
  final bool rolig;
  final Widget child;

  @override
  Widget build(BuildContext context) => OnbTimeline(
    durationMs: rolig ? 1 : 850,
    child: child,
    builder: (context, t, child) {
      final p = _e2.transform(onbP(t, rolig ? 0 : 150, rolig ? 1 : 700));
      return Opacity(
        opacity: p,
        child: Transform.translate(
          offset: Offset(0, -14 * (1 - p)),
          child: Transform.scale(scale: .94 + .06 * p, child: child),
        ),
      );
    },
  );
}

class _Stasjon extends StatelessWidget {
  const _Stasjon({required this.s, required this.sek, required this.ok, required this.naa, required this.pop, required this.rolig});
  final double s;
  final OnbSek sek;
  final bool ok, naa, pop, rolig;

  @override
  Widget build(BuildContext context) {
    final fg = ok ? const Color(0xFF0F3A44) : (naa ? Colors.white : Colors.white.withValues(alpha: .42));
    Widget st = SizedBox(
      width: 28 * s,
      height: 28 * s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .07), border: Border.all(color: Colors.white.withValues(alpha: .1))),
            ),
          ),
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: naa ? 1 : 0,
              duration: Duration(milliseconds: rolig ? 1 : 500),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3F8798), _teal]),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .6), blurRadius: 8 * s, spreadRadius: -3 * s, offset: Offset(0, 4 * s))],
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border(top: BorderSide(color: Colors.white.withValues(alpha: .3), width: 1.5 * s))),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: ok ? 1 : 0,
              duration: Duration(milliseconds: rolig ? 1 : 400),
              child: AnimatedScale(
                scale: ok ? 1 : .5,
                duration: Duration(milliseconds: rolig ? 1 : 600),
                curve: const Cubic(.3, 1.45, .5, 1),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8CF5D5), Color(0xFF3CC79F)]),
                    boxShadow: [BoxShadow(color: _mint.withValues(alpha: .55), blurRadius: 12 * s)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(left: 7 * s, top: 7 * s, child: _Ikon(sek.ikon, size: 14 * s, color: fg, strokeWidth: 2.2)),
          // Orange pulse on the current station.
          if (naa)
            Positioned.fill(
              child: LfLoop(
                builder: (context, ms, _) {
                  final p = (ms / 1600) % 1.0;
                  final sk = kf(p, const [0, .5, 1], const [1, 1.28, 1], cssEaseInOut), a = kf(p, const [0, .5, 1], const [1, .15, 1], cssEaseInOut);
                  return Transform.scale(
                    scale: sk * (36 / 28),
                    child: Opacity(
                      opacity: a,
                      child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFF26D3D), width: 2 * s))),
                    ),
                  );
                },
              ),
            ),
          // The check badge on a done station.
          Positioned(
            right: -3 * s,
            bottom: -3 * s,
            child: AnimatedOpacity(
              opacity: ok ? 1 : 0,
              duration: Duration(milliseconds: rolig ? 1 : 350),
              child: AnimatedScale(
                scale: ok ? 1 : .5,
                duration: Duration(milliseconds: rolig ? 1 : 550),
                curve: const Cubic(.3, 1.6, .5, 1),
                child: Container(
                  width: 13 * s,
                  height: 13 * s,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: _teal, width: 2 * s)),
                  child: Center(child: _Ikon(_ikHak, size: 8 * s, color: const Color(0xFF1E8F72), strokeWidth: 4)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (pop && !rolig) {
      st = OnbTimeline(
        durationMs: 600,
        child: st,
        builder: (context, t, child) {
          final p = const Cubic(.2, 1.5, .4, 1).transform(onbP(t, 0, 600));
          return Transform.scale(scale: kf(p, const [0, .55, 1], const [.4, 1.38, 1]), child: child);
        },
      );
    }
    return st;
  }
}

// ── The card ────────────────────────────────────────────────────────────────

/// `rtKortStorA .85s .3s`: the intro card rises and settles.
class _KortInn extends StatelessWidget {
  const _KortInn({required this.intro, required this.rolig, required this.under, required this.child});
  final bool intro, rolig, under;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!intro || rolig) return child;
    return OnbTimeline(
      durationMs: 1150,
      child: child,
      builder: (context, t, child) {
        final p = _e2.transform(onbP(t, 300, 850));
        final op = kf(p, const [0, .55, 1], const [0, 1, 1]);
        final ty = kf(p, const [0, .55, .78, 1], const [46, -6, 0, 0]);
        final sk = kf(p, const [0, .55, .78, 1], const [.72, 1.04, .99, 1]);
        final rot = kf(p, const [0, .55, .78, 1], const [-3, .6, 0, 0]);
        return Opacity(
          opacity: op,
          child: Transform.translate(
            offset: Offset(0, ty),
            child: Transform.rotate(angle: rad(rot), child: Transform.scale(scale: sk, child: child)),
          ),
        );
      },
    );
  }
}

class _Kort extends StatelessWidget {
  const _Kort({
    super.key,
    required this.s,
    required this.stor,
    required this.rolig,
    required this.sekNavn,
    required this.teller,
    required this.tx,
    required this.typStart,
    required this.her,
    required this.jubel,
    required this.n,
    required this.oppdrag,
    required this.qOk,
    required this.visHopp,
    required this.visTilbake,
    required this.visSenere,
    required this.visNeste,
    required this.nesteTx,
    required this.handling,
    required this.visVisMeg,
    required this.onNeste,
    required this.onTilbake,
    required this.onHopp,
    required this.onVisMeg,
    required this.onHandling,
  });
  final double s;
  final bool stor, rolig, her, jubel, qOk, visHopp, visTilbake, visSenere, visNeste, visVisMeg;
  final String sekNavn, teller, tx, nesteTx;
  final String? oppdrag, handling;
  final int typStart, n;
  final VoidCallback onNeste, onTilbake, onHopp, onVisMeg, onHandling;

  @override
  Widget build(BuildContext context) {
    final blur = BergenPerf.blurOn(context, secondary: true);
    final innhold = her || jubel;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24 * s),
      child: BackdropFilter(
        enabled: blur,
        filter: BergenPerf.blur(context, 24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24 * s),
            gradient: const LinearGradient(
              begin: Alignment(-.6, -1),
              end: Alignment(.6, 1),
              colors: [Color.fromRGBO(48, 108, 124, .97), Color.fromRGBO(30, 79, 92, .98), Color.fromRGBO(21, 60, 72, .99)],
              stops: [0, .46, 1],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: .16)),
            boxShadow: [
              BoxShadow(color: const Color.fromRGBO(6, 26, 34, .6), offset: Offset(0, 2 * s)),
              BoxShadow(color: Colors.black.withValues(alpha: .85), blurRadius: 46 * s, spreadRadius: -18 * s, offset: Offset(0, 30 * s)),
            ],
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24 * s),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: .28), width: 1.5 * s)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Soft light top-left and the glans sweep.
              Positioned(
                left: -40 * s,
                top: -70 * s,
                width: 230 * s,
                height: 170 * s,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [Colors.white.withValues(alpha: .13), Colors.white.withValues(alpha: 0)]),
                    ),
                  ),
                ),
              ),
              if (her && !rolig) Positioned.fill(child: IgnorePointer(child: _Glans(key: ValueKey('glans-$n'), s: s))),
              // The content fades out before a step change and in with the text.
              AnimatedSize(
                duration: Duration(milliseconds: rolig ? 1 : 580),
                curve: _e,
                alignment: Alignment.topCenter,
                child: AnimatedSlide(
                  offset: Offset(0, innhold ? 0 : -5 / 120),
                  duration: Duration(milliseconds: rolig ? 1 : (innhold ? 400 : 170)),
                  curve: innhold ? _e2 : const Cubic(.4, 0, 1, 1),
                  child: AnimatedOpacity(
                    opacity: innhold ? 1 : 0,
                    duration: Duration(milliseconds: rolig ? 1 : (innhold ? 400 : 170)),
                    curve: innhold ? _e2 : const Cubic(.4, 0, 1, 1),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(14 * s, 14 * s, 14 * s, 12 * s),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 7 * s,
                                height: 7 * s,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _mint,
                                  boxShadow: [BoxShadow(color: _mint.withValues(alpha: .2), spreadRadius: 3 * s), BoxShadow(color: _mint.withValues(alpha: .8), blurRadius: 10 * s)],
                                ),
                              ),
                              SizedBox(width: 7 * s),
                              // Flexible: the test font is wide, and 120 % text must not overflow the row.
                              Flexible(child: Text('ÆGIL · ${sekNavn.toUpperCase()}', style: onbDisplay(9.5 * s, letterSpacingEm: .1, color: _mintLys), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              const Spacer(),
                              Flexible(child: Text(teller, style: onbDisplay(10.5 * s, weight: FontWeight.w700, color: Colors.white.withValues(alpha: .56)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              if (visHopp)
                                Padding(
                                  padding: EdgeInsets.only(left: 4 * s),
                                  child: _Pille(
                                    key: const Key('onb-hopp'),
                                    s: s,
                                    h: 26,
                                    padL: 10,
                                    padR: 10,
                                    onTap: onHopp,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(OnbCopy.hoppOver, style: onbDisplay(11 * s)),
                                        SizedBox(width: 4 * s),
                                        _Ikon(_ikHopp, size: 10 * s, color: Colors.white, strokeWidth: 3),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 7 * s),
                          _Ord(key: ValueKey('ord-$n-$tx'), tx: tx, s: s, stor: stor, start: typStart, rolig: rolig),
                          if (oppdrag != null) ...[
                            SizedBox(height: 11 * s),
                            _Oppdrag(s: s, tx: oppdrag!, ok: qOk, rolig: rolig),
                          ],
                          SizedBox(height: 12 * s),
                          ConstrainedBox(
                            constraints: BoxConstraints(minHeight: 42 * s),
                            child: Row(
                              children: [
                                if (visTilbake)
                                  _Trykk(
                                    key: const Key('onb-tilbake'),
                                    onTap: onTilbake,
                                    child: SizedBox(
                                      height: 40 * s,
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 2 * s, right: 8 * s),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _Ikon(_ikTilbake, size: 14 * s, color: Colors.white.withValues(alpha: .7), strokeWidth: 2.6),
                                            SizedBox(width: 3 * s),
                                            Text(OnbCopy.tilbake, style: onbDisplay(12.5 * s, color: Colors.white.withValues(alpha: .7))),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                if (visSenere)
                                  _Trykk(
                                    key: const Key('onb-senere'),
                                    onTap: onHopp,
                                    child: SizedBox(
                                      height: 40 * s,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8 * s),
                                        child: Center(child: Text(OnbCopy.senere, style: onbDisplay(12.5 * s, color: Colors.white.withValues(alpha: .7)))),
                                      ),
                                    ),
                                  ),
                                if (handling != null)
                                  _Pille(
                                    key: const Key('onb-handling'),
                                    s: s,
                                    h: 36,
                                    padL: 12,
                                    padR: 12,
                                    onTap: onHandling,
                                    child: Text(handling!, style: onbDisplay(12 * s), maxLines: 1),
                                  ),
                                const Spacer(),
                                if (visVisMeg)
                                  _Pille(
                                    key: const Key('onb-vismeg'),
                                    s: s,
                                    h: 40,
                                    padL: 12,
                                    padR: 15,
                                    lys: true,
                                    onTap: onVisMeg,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _Ikon(_ikHand, size: 16 * s, color: _mint, strokeWidth: 2),
                                        SizedBox(width: 7 * s),
                                        Text(OnbCopy.visMeg, style: onbDisplay(13 * s)),
                                      ],
                                    ),
                                  ),
                                if (visNeste) ...[
                                  SizedBox(width: 6 * s),
                                  _Oransje(key: const Key('onb-neste'), s: s, tx: nesteTx, onTap: onNeste),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The white band sweeping across the card once per step (`rtGlans 1.2s .8s`).
class _Glans extends StatelessWidget {
  const _Glans({super.key, required this.s});
  final double s;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24 * s),
    child: OnbTimeline(
      durationMs: 2000,
      builder: (context, t, _) {
        final p = cssEaseInOut.transform(onbP(t, 800, 1200));
        return LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth * .46;
            final x = kf(p, const [0, 1], const [-1.3, 3.3]) * w;
            return Transform.translate(
              offset: Offset(x, 0),
              child: Transform(
                transform: Matrix4.skewX(rad(-14)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: w,
                    height: box.maxHeight + 40 * s,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: .13), Colors.white.withValues(alpha: 0)]),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

/// The text, word by word (`rtOrd .52s`, 34 ms apart, after [start] ms).
class _Ord extends StatelessWidget {
  const _Ord({super.key, required this.tx, required this.s, required this.stor, required this.start, required this.rolig});
  final String tx;
  final double s;
  final bool stor, rolig;
  final int start;

  @override
  Widget build(BuildContext context) {
    final style = onbDisplay((stor ? 17 : 14.5) * s, letterSpacingEm: -.014, height: 1.38);
    final ord = tx.split(' ');
    if (rolig) return Text(tx, style: style);
    return OnbTimeline(
      durationMs: start + 60 + ord.length * 34 + 520.0,
      builder: (context, t, _) => Text.rich(
        TextSpan(
          children: [
            for (var k = 0; k < ord.length; k++) ...[
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: Builder(
                  builder: (context) {
                    final p = _e2.transform(onbP(t, start + 60 + k * 34, 520));
                    return Opacity(
                      opacity: p,
                      child: Transform.translate(offset: Offset(0, 7 * s * (1 - p)), child: Text(ord[k], style: style)),
                    );
                  },
                ),
              ),
              if (k < ord.length - 1) TextSpan(text: ' ', style: style),
            ],
          ],
        ),
      ),
    );
  }
}

/// The mission box: «OPPDRAG · GJØR DET SELV» → «Oppdrag fullført».
class _Oppdrag extends StatelessWidget {
  const _Oppdrag({required this.s, required this.tx, required this.ok, required this.rolig});
  final double s;
  final String tx;
  final bool ok, rolig;

  @override
  Widget build(BuildContext context) {
    Widget boks = AnimatedContainer(
      duration: Duration(milliseconds: rolig ? 1 : 350),
      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 10 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16 * s),
        color: _mint.withValues(alpha: ok ? .24 : .1),
        border: Border.all(color: _mint.withValues(alpha: .42), width: 1.5 * s),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The breathing inner glow while the mission waits.
          Positioned.fill(
            left: -12 * s,
            right: -12 * s,
            top: -10 * s,
            bottom: -10 * s,
            child: IgnorePointer(
              child: ok
                  ? const SizedBox.shrink()
                  : LfLoop(
                      builder: (context, ms, _) {
                        final p = (ms / 1900) % 1.0;
                        return Opacity(
                          opacity: kf(p, const [0, .5, 1], const [.35, 1, .35], cssEaseInOut),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16 * s),
                              border: Border.all(color: _mintLys.withValues(alpha: .95), width: 1.5 * s),
                              boxShadow: [BoxShadow(color: _mint.withValues(alpha: .3), blurRadius: 18 * s)],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          Row(
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: rolig ? 1 : 300),
                width: 32 * s,
                height: 32 * s,
                decoration: BoxDecoration(shape: BoxShape.circle, color: ok ? _mint : _mint.withValues(alpha: .16)),
                child: Center(
                  child: ok
                      ? OnbTimeline(
                          durationMs: rolig ? 1 : 500,
                          builder: (context, t, _) => CustomPaint(
                            size: Size.square(16 * s),
                            painter: _SjekkMaler(onbP(t, rolig ? 0 : 100, rolig ? 1 : 400)),
                          ),
                        )
                      : CustomPaint(size: Size.square(17 * s), painter: _MaalIkonMaler(s)),
                ),
              ),
              SizedBox(width: 10 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text((ok ? OnbCopy.oppdragFerdig : OnbCopy.oppdragSelv).toUpperCase(), style: onbDisplay(9.5 * s, letterSpacingEm: .1, color: _mintLys)),
                    SizedBox(height: 1 * s),
                    Text(tx, style: onbDisplay(13.5 * s, letterSpacingEm: -.01, height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (ok && !rolig) {
      boks = OnbTimeline(
        durationMs: 500,
        child: boks,
        builder: (context, t, child) {
          final p = const Cubic(.2, 1.4, .4, 1).transform(onbP(t, 0, 500));
          return Transform.scale(scale: kf(p, const [0, .4, 1], const [1, 1.05, 1]), child: child);
        },
      );
    }
    return boks;
  }
}

class _MaalIkonMaler extends CustomPainter {
  _MaalIkonMaler(this.s);
  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero), k = size.width / 24;
    final p = Paint()
      ..color = _mint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * k;
    canvas.drawCircle(c, 8 * k, p);
    canvas.drawCircle(c, 4 * k, p);
    canvas.drawCircle(c, .9 * k, Paint()..color = _mint);
  }

  @override
  bool shouldRepaint(_MaalIkonMaler o) => false;
}

class _SjekkMaler extends CustomPainter {
  _SjekkMaler(this.p);
  final double p;

  @override
  void paint(Canvas canvas, Size size) {
    if (p <= 0) return;
    final k = size.width / 24;
    final path = svgSti(_ikHak);
    final out = Path();
    for (final m in path.computeMetrics()) {
      out.addPath(m.extractPath(0, m.length * cssEaseOut.transform(p)), Offset.zero);
    }
    canvas.save();
    canvas.scale(k);
    canvas.drawPath(
      out,
      Paint()
        ..color = const Color(0xFF0F3A44)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SjekkMaler o) => o.p != p;
}

/// A press that only sinks 1–2 px (the design's `style-active`).
class _Trykk extends StatefulWidget {
  const _Trykk({super.key, required this.onTap, required this.child, this.dy = 1, this.scale = 1});
  final VoidCallback onTap;
  final Widget child;
  final double dy, scale;

  @override
  State<_Trykk> createState() => _TrykkState();
}

class _TrykkState extends State<_Trykk> {
  bool _ned = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => setState(() => _ned = true),
    onTapCancel: () => setState(() => _ned = false),
    onTapUp: (_) => setState(() => _ned = false),
    onTap: widget.onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      transform: Matrix4.translationValues(0, _ned ? widget.dy : 0, 0)..scaleByDouble(_ned ? widget.scale : 1, _ned ? widget.scale : 1, 1, 1),
      transformAlignment: Alignment.center,
      child: widget.child,
    ),
  );
}

/// A glass pill button (white .1, ring .16).
class _Pille extends StatelessWidget {
  const _Pille({super.key, required this.s, required this.h, required this.padL, required this.padR, required this.onTap, required this.child, this.lys = false});
  final double s, h, padL, padR;
  final VoidCallback onTap;
  final Widget child;

  /// «Vis meg»: an inset highlight on top as well.
  final bool lys;

  @override
  Widget build(BuildContext context) => _Trykk(
    onTap: onTap,
    dy: lys ? 2 : 1,
    scale: h <= 26 ? .94 : 1,
    child: Container(
      height: h * s,
      padding: EdgeInsets.only(left: padL * s, right: padR * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: .1),
        border: Border.all(color: Colors.white.withValues(alpha: lys ? .14 : .16)),
      ),
      foregroundDecoration: lys
          ? BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border(top: BorderSide(color: Colors.white.withValues(alpha: .18))))
          : null,
      alignment: Alignment.center,
      child: child,
    ),
  );
}

/// The orange 3D «Neste» / «Bli med» / «Fullfør».
class _Oransje extends StatelessWidget {
  const _Oransje({super.key, required this.s, required this.tx, required this.onTap});
  final double s;
  final String tx;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _Trykk(
    onTap: onTap,
    dy: 2,
    child: Container(
      height: 42 * s,
      padding: EdgeInsets.only(left: 19 * s, right: 16 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], stops: [0, .56, 1]),
        boxShadow: [
          BoxShadow(color: const Color(0xFFB9441A), offset: Offset(0, 3 * s)),
          BoxShadow(color: const Color.fromRGBO(185, 68, 26, .85), blurRadius: 14 * s, spreadRadius: -6 * s, offset: Offset(0, 9 * s)),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: .4), width: 1.5 * s)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tx, style: onbDisplay(13.5 * s)),
          SizedBox(width: 7 * s),
          _Ikon(_ikPil, size: 14 * s, color: Colors.white, strokeWidth: 2.8),
        ],
      ),
    ),
  );
}

// ── Ægil ────────────────────────────────────────────────────────────────────

enum _Anim { idle, titt, hopp, jubel }

class _Aeg {
  const _Aeg(this.anim, this.pose, this.n);
  final _Anim anim;
  final OnbPose pose;
  final int n;
}

/// Ægil's picture with the step's animation: peek up and wave on the intro,
/// hop in and talk on a step, two hops on success, then breathing
/// (`rtTittOpp`, `vkVink`, `rtHoppA/B`, `rtSnakk`, `vkHopp`, `aegStaa`).
class _AegilFigur extends StatelessWidget {
  const _AegilFigur({super.key, required this.a, required this.s, required this.rolig});
  final _Aeg a;
  final double s;
  final bool rolig;

  @override
  Widget build(BuildContext context) {
    final img = Image.asset('assets/images/aegil/${a.pose.name}.png', fit: BoxFit.contain, gaplessPlayback: true);
    if (rolig) return img;
    final ab = a.n.isOdd ? 1.0 : -1.0;
    return LfLoop(
      child: img,
      builder: (context, ms, child) {
        var m = Matrix4.identity();
        var ty = 0.0, sx = 1.0, sy = 1.0, rot = 0.0;
        double idleFra;
        switch (a.anim) {
          case _Anim.titt:
            // rtTittOpp .95s .35s, vkVink .9s ×2 at 1.35s, aegStaa from 3.2s.
            final p = _e2.transform(onbP(ms, 350, 950));
            ty = kf(p, const [0, .62, 1], const [.9, -.05, 0]) * 128 * s;
            sx = kf(p, const [0, .62, 1], const [.94, 1.02, 1]);
            sy = kf(p, const [0, .62, 1], const [1.03, .98, 1]);
            if (ms >= 1350 && ms < 3150) {
              final q = ((ms - 1350) / 900) % 1.0;
              rot = kf(q, const [0, .2, .45, .7, 1], const [0, -7, 6, -4, 0], cssEaseInOut);
            }
            idleFra = 3200;
          case _Anim.hopp:
            // rtHopp .82s, rtSnakk .36s ×3 at .88s, aegStaa from 2s.
            final p = cssEaseInOut.transform(onbP(ms, 0, 820));
            ty = kf(p, const [0, .14, .46, .76, 1], const [0, 3, -28, 1, 0]) * s;
            sx = kf(p, const [0, .14, .46, .76, 1], const [1, 1.05, .98, 1.03, 1]);
            sy = kf(p, const [0, .14, .46, .76, 1], const [1, .94, 1.03, .97, 1]);
            rot = kf(p, const [0, .46, 1], [0, -3 * ab, 0]);
            if (ms >= 880 && ms < 1960) {
              final q = ((ms - 880) / 360) % 1.0;
              rot += kf(q, const [0, .5, 1], const [0, -2.5, 0], cssEaseInOut);
              ty += kf(q, const [0, .5, 1], const [0, -1.5, 0], cssEaseInOut) * s;
            }
            idleFra = 2000;
          case _Anim.jubel:
            // vkHopp .62s ×2, aegStaa from 1.3s.
            if (ms < 1240) {
              final q = _hopp.transform((ms / 620) % 1.0);
              sx = kf(q, const [0, .2, .5, .8, 1], const [1, 1.08, .95, 1.04, 1]);
              sy = kf(q, const [0, .2, .5, .8, 1], const [1, .9, 1.06, .96, 1]);
              ty = kf(q, const [0, .2, .5, .8, 1], const [0, 0, -22, 0, 0]) * s;
            }
            idleFra = 1300;
          case _Anim.idle:
            idleFra = 0;
        }
        m = Matrix4.identity()
          ..translateByDouble(0, ty, 0, 1)
          ..rotateZ(rad(rot))
          ..scaleByDouble(sx, sy, 1, 1);
        if (ms >= idleFra) m = m.multiplied(aegStaa(ms - idleFra, 3600));
        return Transform(alignment: Alignment.bottomCenter, transform: m, child: child);
      },
    );
  }
}

/// Six drops flying up from Ægil's feet when he lands (`rtDrA/B .62s`).
class _Draper extends StatelessWidget {
  const _Draper({super.key, required this.s, required this.titt, required this.ab, required this.skala});
  final double s, skala;
  final bool titt, ab;

  @override
  Widget build(BuildContext context) => OnbTimeline(
    durationMs: 1800,
    builder: (context, t, _) => Stack(
      clipBehavior: Clip.none,
      children: [
        for (var k = 0; k < 6; k++)
          Builder(
            builder: (context) {
              const rots = [-68, -40, -14, 14, 40, 68];
              final delay = ((titt ? .95 : .66) + (k % 2) * .04) * 1000;
              final p = onbP(t, delay, 620);
              if (p <= 0 || p >= 1) return const SizedBox.shrink();
              final c = const Cubic(.2, .8, .3, 1).transform(p);
              final sz = (k % 2 == 1 ? 5 : 7) * s * skala;
              return Transform.rotate(
                angle: rad(rots[k].toDouble()),
                child: Transform.translate(
                  offset: Offset(-3 * s, -3 * s + kf(c, const [0, 1], const [0, -34]) * s * skala),
                  child: Opacity(
                    opacity: kf(p, const [0, .18, 1], const [0, 1, 0]),
                    child: Transform.scale(
                      scale: kf(c, const [0, 1], const [.4, 1]),
                      child: Container(width: sz, height: sz, decoration: BoxDecoration(shape: BoxShape.circle, color: k % 3 == 1 ? Colors.white : _mint)),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    ),
  );
}


// ── The section stamp ───────────────────────────────────────────────────────

/// Slams in at the centre (`rtSlam .72s`, two ink rings, 12 sparks), then
/// flies into its HUD station at scale .18 (`rtStTr`, .56 s) while the
/// station pops (`rtStPop`, in the HUD).
class _Stempel extends StatelessWidget {
  const _Stempel({super.key, required this.s, required this.W, required this.H, required this.top, required this.sek, required this.k, required this.fly, required this.rolig});
  final double s, W, H, top;
  final OnbSek sek;
  final int k;
  final bool fly, rolig;

  @override
  Widget build(BuildContext context) {
    final size = 156 * s;
    final cx = W / 2, cy = 400 * H / 844;
    // The station's centre: HUD left 48 + pad 10 + k·52 + 14, top + 12 + 22.
    final sx = (72 + 52 * k) * s, sy = top + 34 * s;
    return Positioned(
      left: cx - size / 2,
      top: cy - size / 2,
      width: size,
      height: size,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: fly ? 0 : 1,
          duration: Duration(milliseconds: rolig ? 1 : 180),
          curve: const Interval(.78, 1),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: fly ? 1 : 0),
            duration: Duration(milliseconds: rolig ? 1 : 560),
            curve: const Cubic(.55, -0.3, .7, 1),
            builder: (context, f, child) => Transform.translate(
              offset: Offset((sx - cx) * f, (sy - cy) * f),
              child: Transform.scale(scale: 1 - .82 * f, child: child),
            ),
            child: OnbTimeline(
              durationMs: rolig ? 1 : 1400,
              builder: (context, t, _) {
                final p = const Cubic(.2, 1.1, .4, 1).transform(onbP(t, 0, rolig ? 1 : 720));
                final op = kf(p, const [0, .4, 1], const [0, 1, 1]);
                final sk = kf(p, const [0, .4, .56, .72, 1], const [2.4, .92, 1.05, 1, 1]);
                final rot = kf(p, const [0, .4, .56, .72, 1], const [-28, 5, -2, 0, 0]);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final (d, dur, c, w) in [(260.0, 800.0, _mint.withValues(alpha: .75), 3.0), (400.0, 900.0, Colors.white.withValues(alpha: .6), 2.0)])
                      Builder(
                        builder: (context) {
                          final q = cssEaseOut.transform(onbP(t, rolig ? 0 : d, rolig ? 1 : dur));
                          if (q <= 0 || q >= 1) return const SizedBox.shrink();
                          return Positioned.fill(
                            child: Transform.scale(
                              scale: kf(q, const [0, 1], const [.7, 1.7]),
                              child: Opacity(opacity: .8 * (1 - q), child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c, width: w * s)))),
                            ),
                          );
                        },
                      ),
                    if (!rolig)
                      for (var j = 0; j < 12; j++)
                        Positioned(
                          left: size / 2,
                          top: size / 2,
                          child: Transform.rotate(
                            angle: rad(j * 30.0),
                            child: Builder(
                              builder: (context) {
                                final q = onbP(t, (j % 3) * 40, 800);
                                final c = const Cubic(.2, .8, .3, 1).transform(q);
                                return Transform.translate(
                                  offset: Offset(-5 * s, -5 * s + kf(c, const [0, 1], const [-18, -100]) * s),
                                  child: Opacity(
                                    opacity: kf(q, const [0, .25, 1], const [0, 1, 0]),
                                    child: Transform.scale(
                                      scale: kf(c, const [0, 1], const [.4, 1]),
                                      child: Container(width: 10 * s, height: 10 * s, decoration: BoxDecoration(shape: BoxShape.circle, color: const [_mint, Color(0xFFF26D3D), Color(0xFFF2C14E)][j % 3])),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    Positioned.fill(
                      child: Opacity(
                        opacity: op,
                        child: Transform.rotate(
                          angle: rad(rot),
                          child: Transform.scale(
                            scale: sk,
                            child: Transform.rotate(
                              angle: rad(-8),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const RadialGradient(center: Alignment(-.3, -.44), colors: [Color(0xFF3F8798), _teal, Color(0xFF143A45)], stops: [0, .58, 1]),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: .7), blurRadius: 36 * s, spreadRadius: -14 * s, offset: Offset(0, 22 * s)),
                                    BoxShadow(color: _mint.withValues(alpha: .35), blurRadius: 40 * s),
                                  ],
                                ),
                                foregroundDecoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _mint, width: 4 * s),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(4 * s),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _teal, width: 5 * s)),
                                    child: Padding(
                                      padding: EdgeInsets.all(5 * s),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _mint.withValues(alpha: .55), width: 1.5 * s)),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            _Ikon(sek.ikon, size: 38 * s, color: _mint, strokeWidth: 1.9),
                                            SizedBox(height: 5 * s),
                                            Text(sek.navn, style: onbDisplay(17 * s, letterSpacingEm: -.02)),
                                            SizedBox(height: 5 * s),
                                            Text(OnbCopy.stempelTatt.toUpperCase(), style: onbDisplay(9.5 * s, letterSpacingEm: .14, color: _mint)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── The done card ───────────────────────────────────────────────────────────

class _FerdigKort extends StatefulWidget {
  const _FerdigKort({required this.s, required this.W, required this.H, required this.rolig, required this.aegKey, required this.onStart});
  final double s, W, H;
  final bool rolig;
  final GlobalKey aegKey;
  final VoidCallback onStart;

  @override
  State<_FerdigKort> createState() => _FerdigKortState();
}

class _FerdigKortState extends State<_FerdigKort> {
  Timer? _auto;

  @override
  void initState() {
    super.initState();
    // Debug harness `onbAuto: start`: «Start å handle» pressed by itself.
    if (OnbRunde.instance.auto == 'start') _auto = Timer(const Duration(milliseconds: 2600), () => mounted ? widget.onStart() : null);
  }

  @override
  void dispose() {
    _auto?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s, W = widget.W, H = widget.H, rolig = widget.rolig, aegKey = widget.aegKey, onStart = widget.onStart;
    final konf = List.generate(26, (k) => (x: (k * 37 + 5) % 100 / 100, rot: ((k * 53) % 40) - 20.0, d: ((k * 7) % 10) / 12, dur: 2.2 + ((k * 13) % 10) / 8, c: const [Color(0xFFF26D3D), _mint, Color(0xFFF2C14E), Colors.white, Color(0xFF3F8798)][k % 5], w: 6.0 + (k % 3) * 2, h: 10.0 + (k % 4) * 2));
    const rots = <double>[-8, 5, -4, 7, -6];
    return Positioned.fill(
      child: Stack(
        children: [
          // Confetti falling through the whole screen.
          if (!rolig)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRect(
                  child: OnbTimeline(
                    durationMs: 5000,
                    builder: (context, t, _) => Stack(
                      children: [
                        for (final k in konf)
                          Builder(
                            builder: (context) {
                              final p = const Cubic(.3, .6, .5, 1).transform(onbP(t, k.d * 1000, k.dur * 1000));
                              if (p <= 0) return const SizedBox.shrink();
                              return Positioned(
                                left: k.x * W,
                                top: kf(p, const [0, 1], const [-60, 930]) * s,
                                child: Transform.rotate(
                                  angle: rad(k.rot + 720 * p),
                                  child: Opacity(
                                    opacity: 1 - .1 * p,
                                    child: Container(width: k.w * s, height: k.h * s, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2 * s), color: k.c)),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 22 * s),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 346 * s),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Rays behind the card.
                    Positioned(
                      left: 0,
                      right: 0,
                      top: -176 * s,
                      child: IgnorePointer(
                        child: Center(
                          child: SizedBox(
                            width: 380 * s,
                            height: 380 * s,
                            child: LfLoop(
                              builder: (context, ms, _) => Opacity(
                                opacity: rolig ? 1 : onbP(ms, 200, 600),
                                child: Transform.rotate(
                                  angle: rolig ? 0 : rad(360 * ((ms / 16000) % 1.0)),
                                  child: CustomPaint(painter: _StraaleMaler()),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _KortInn(
                      intro: !rolig,
                      rolig: rolig,
                      under: true,
                      child: Container(
                        key: const Key('onb-ferdig'),
                        padding: EdgeInsets.fromLTRB(20 * s, 84 * s, 20 * s, 20 * s),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28 * s),
                          gradient: const LinearGradient(
                            begin: Alignment(-.6, -1),
                            end: Alignment(.6, 1),
                            colors: [Color.fromRGBO(48, 108, 124, .97), Color.fromRGBO(30, 79, 92, .98), Color.fromRGBO(21, 60, 72, .99)],
                            stops: [0, .46, 1],
                          ),
                          border: Border.all(color: Colors.white.withValues(alpha: .16)),
                          boxShadow: [
                            BoxShadow(color: const Color.fromRGBO(6, 26, 34, .6), offset: Offset(0, 2 * s)),
                            BoxShadow(color: Colors.black.withValues(alpha: .85), blurRadius: 46 * s, spreadRadius: -18 * s, offset: Offset(0, 30 * s)),
                          ],
                        ),
                        foregroundDecoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28 * s),
                          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: .28), width: 1.5 * s)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(OnbCopy.ferdigTittel, textAlign: TextAlign.center, style: onbDisplay(25 * s, letterSpacingEm: -.025, height: 1.15)),
                            SizedBox(height: 8 * s),
                            Text(OnbCopy.ferdigTekst, textAlign: TextAlign.center, style: onbDisplay(14 * s, weight: FontWeight.w600, height: 1.45, color: Colors.white.withValues(alpha: .74))),
                            SizedBox(height: 18 * s),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var k = 0; k < kOnbSeksjoner.length; k++)
                                  Flexible(
                                    child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4 * s),
                                    child: OnbTimeline(
                                      durationMs: rolig ? 1 : 1500,
                                      builder: (context, t, child) {
                                        final p = const Cubic(.2, 1.2, .4, 1).transform(onbP(t, rolig ? 0 : 550 + k * 120, rolig ? 1 : 450));
                                        return Opacity(
                                          opacity: kf(p, const [0, .7, 1], const [0, 1, 1]),
                                          child: Transform.rotate(
                                            angle: rad(kf(p, const [0, .7, 1], const [-20, 3, 0])),
                                            child: Transform.scale(scale: kf(p, const [0, .7, 1], const [1.9, .94, 1]), child: child),
                                          ),
                                        );
                                      },
                                      child: Column(
                                        children: [
                                          Transform.rotate(
                                            angle: rad(rots[k]),
                                            child: Container(
                                              width: 46 * s,
                                              height: 46 * s,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: const RadialGradient(center: Alignment(-.3, -.44), colors: [Color(0xFF3F8798), _teal], stops: [0, .6]),
                                                border: Border.all(color: _mint, width: 2 * s),
                                                boxShadow: [BoxShadow(color: _mint.withValues(alpha: .35), blurRadius: 14 * s), BoxShadow(color: Colors.black.withValues(alpha: .6), blurRadius: 14 * s, spreadRadius: -8 * s, offset: Offset(0, 8 * s))],
                                              ),
                                              child: Center(child: _Ikon(kOnbSeksjoner[k].ikon, size: 20 * s, color: _mint, strokeWidth: 2)),
                                            ),
                                          ),
                                          SizedBox(height: 5 * s),
                                          Text(kOnbSeksjoner[k].navn, style: onbDisplay(10 * s, color: _mintTekst), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 20 * s),
                            _Trykk(
                              key: const Key('onb-start'),
                              onTap: onStart,
                              dy: 2,
                              child: Container(
                                height: 52 * s,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], stops: [0, .56, 1]),
                                  boxShadow: [
                                    BoxShadow(color: const Color(0xFFB9441A), offset: Offset(0, 3 * s)),
                                    BoxShadow(color: const Color.fromRGBO(185, 68, 26, .85), blurRadius: 14 * s, spreadRadius: -6 * s, offset: Offset(0, 9 * s)),
                                  ],
                                ),
                                foregroundDecoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border(top: BorderSide(color: Colors.white.withValues(alpha: .4), width: 1.5 * s))),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(OnbCopy.startHandle, style: onbDisplay(15 * s)),
                                    SizedBox(width: 8 * s),
                                    _Ikon(_ikPil, size: 15 * s, color: Colors.white, strokeWidth: 2.8),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Ægil cheering over the card.
                    Positioned(
                      left: 0,
                      right: 0,
                      top: -82 * s,
                      child: IgnorePointer(
                        child: Center(
                          child: SizedBox(
                            width: 146 * s,
                            height: 146 * s,
                            child: OnbTimeline(
                              durationMs: rolig ? 1 : 3000,
                              child: Image.asset('assets/images/aegil/voucher.png', key: aegKey, fit: BoxFit.contain),
                              builder: (context, t, child) {
                                if (rolig) return child!;
                                final p = _e2.transform(onbP(t, 250, 850));
                                var ty = kf(p, const [0, .62, 1], const [.9, -.05, 0]) * 146 * s;
                                var sx = kf(p, const [0, .62, 1], const [.94, 1.02, 1]), sy = kf(p, const [0, .62, 1], const [1.03, .98, 1]);
                                if (t >= 1150 && t < 2550) {
                                  final q = _hopp.transform(((t - 1150) / 700) % 1.0);
                                  sx *= kf(q, const [0, .2, .5, .8, 1], const [1, 1.08, .95, 1.04, 1]);
                                  sy *= kf(q, const [0, .2, .5, .8, 1], const [1, .9, 1.06, .96, 1]);
                                  ty += kf(q, const [0, .2, .5, .8, 1], const [0, 0, -22, 0, 0]) * s;
                                }
                                return Transform(
                                  alignment: Alignment.bottomCenter,
                                  transform: Matrix4.identity()..translateByDouble(0, ty, 0, 1)..scaleByDouble(sx, sy, 1, 1),
                                  child: child,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `repeating-conic-gradient` of mint rays, masked to a soft disc.
class _StraaleMaler extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero), r = size.width / 2;
    final sh = ui.Gradient.radial(c, r, [_mintLys.withValues(alpha: .3), _mintLys.withValues(alpha: .3), _mintLys.withValues(alpha: 0)], [0, .18, 1]);
    final p = Paint()..shader = sh;
    for (var a = 0.0; a < 360; a += 20) {
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..arcTo(Rect.fromCircle(center: c, radius: r), rad(a - 90), rad(7), false)
        ..close();
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_StraaleMaler o) => false;
}

// ── The kai-hopp ────────────────────────────────────────────────────────────

/// `rtKaiHopp`: Ægil crouches, jumps out of the done card with a pirouette
/// (A, 580 ms), hovers while Hjem comes back under him (`vent`), double-jumps
/// over the city to the quay Ægil's spot (B, 780 ms, turning to the water:
/// the back face shows), lands with dust, a shock ring and sparks (L, 340 ms)
/// and a pill «Klar til å handle!» — then he *is* the quay Ægil.
class _KaiHopp extends StatefulWidget {
  const _KaiHopp({super.key, required this.fra, required this.s, required this.W, required this.H, required this.r});
  final Rect fra;
  final double s, W, H;
  final OnbRunde r;

  @override
  State<_KaiHopp> createState() => _KaiHoppState();
}

class _Gnist {
  _Gnist(this.x, this.y, this.t0, this.c, this.z, this.jx, this.jy);
  final double x, y, t0, z, jx, jy;
  final Color c;
}

class _Sprut {
  _Sprut(this.x, this.y, this.ex, this.ey, this.t0, this.c, this.z, this.rund);
  final double x, y, ex, ey, t0, z;
  final Color c;
  final bool rund;
}

class _Ring {
  _Ring(this.x, this.y, this.w, this.h, this.k0, this.c, this.dur, this.bw, this.t0);
  final double x, y, w, h, k0, dur, bw, t0;
  final Color c;
}

class _KaiHoppState extends State<_KaiHopp> with SingleTickerProviderStateMixin {
  late final Ticker _tk;
  double _t = 0;
  String _fase = 'A';
  double _tB = 0, _tL = 0, _e = .55, _mh = 0, _sistG = -1;
  Offset? _M, _C;
  OnbMaalRekt? _forr;
  int _stabil = 0;
  bool _slutt = false, _pill = false, _stov = false;
  double _pillT = 0;
  final List<_Gnist> _gn = [];
  final List<_Sprut> _sp = [];
  final List<_Ring> _ri = [];
  final List<_Ring> _dust = [];
  late final Offset _A, _K;
  late final double _S;
  static const _F = [Color(0xFF7FF0CB), Color(0xFFF2C14E), Color(0xFFF26D3D), Colors.white, _mint];
  int _gi = 0;

  @override
  void initState() {
    super.initState();
    final s = widget.s;
    _S = widget.fra.width;
    _A = Offset(widget.fra.center.dx, widget.fra.bottom);
    _K = Offset((_A.dx + 34 * s).clamp(120 * s, 270 * s).toDouble(), (_A.dy - 150 * s).clamp(160 * s, 236 * s).toDouble());
    widget.r.kaiSkjult.value = true;
    _tk = createTicker((d) {
      _t = d.inMilliseconds.toDouble();
      _tikk();
      if (mounted) setState(() {});
    })..start();
  }

  @override
  void dispose() {
    _tk.dispose();
    super.dispose();
  }

  double _lerp(double a, double b, double f) => a + (b - a) * f;
  double _cl(double v) => v.clamp(0.0, 1.0);
  double _ut(double p) => 1 - math.pow(1 - p, 3).toDouble();
  double _io(double p) => p * p * (3 - 2 * p);

  void _gnist(double x, double y) {
    final i = _gi++;
    _gn.add(_Gnist(x, y, _t, _F[i % 5], (4 + (i % 3) * 1.7) * widget.s, ((i * 37) % 13) - 6.0, ((i * 53) % 11) - 5.0));
  }

  void _sprut(double x, double y, int n, double d0, double d1, double fra, double til) {
    for (var j = 0; j < n; j++) {
      final v = (fra + (til - fra) * (j + .5) / n) * math.pi / 180, d = d0 + ((j * 29) % 7) / 6 * (d1 - d0);
      _sp.add(_Sprut(x, y, x + math.cos(v) * d, y + math.sin(v) * d, _t, _F[j % 5], (4 + (j % 3) * 1.6) * widget.s, j.isOdd));
    }
  }

  void _ring(double x, double y, double w, double h, double k0, Color c, double dur, double bw) => _ri.add(_Ring(x, y, w, h, k0, c, dur, bw, _t));

  // Where Ægil is drawn this frame.
  double _x = 0, _y = 0, _sc = 1, _sx = 1, _sy = 1, _rz = 0, _ry = 0, _go = 0;
  bool _spor = false;

  void _tikk() {
    if (_slutt) return;
    final s = widget.s, t = _t;
    const DA = 580.0, DB = 780.0, DL = 340.0;
    var x = _A.dx, y = _A.dy, sc = 1.0, sx = 1.0, sy = 1.0, rz = 0.0, ry = 0.0, go = 0.0, spor = false;
    if (_fase == 'A' && t >= DA) _fase = 'vent';
    if (_fase == 'A') {
      if (t < 150) {
        final q = _ut(t / 150);
        sx = 1 + .14 * q;
        sy = 1 - .2 * q;
      } else {
        final q = _cl((t - 150) / (DA - 150)), u = _ut(q);
        x = _lerp(_A.dx, _K.dx, _io(q));
        y = _lerp(_A.dy, _K.dy, u);
        sc = 1 - .18 * u;
        if (q < .25) {
          final f = _io(q / .25);
          sx = _lerp(1.14, .9, f);
          sy = _lerp(.8, 1.14, f);
        } else {
          final f = _io(_cl((q - .25) / .45));
          sx = _lerp(.9, 1, f);
          sy = _lerp(1.14, 1, f);
        }
        rz = 7 * math.sin(math.pi * q);
        ry = 360 * _ut(q);
        go = .6 * _cl(q * 2.2);
        spor = q < .9;
        if (q < .06 && !_stov) {
          _stov = true;
          _ring(_A.dx, _A.dy - 3 * s, 90 * s, 22 * s, .2, Colors.white.withValues(alpha: .7), 460, 1.5);
        }
      }
    }
    if (_fase == 'vent') {
      x = _K.dx;
      y = _K.dy + math.sin((t - DA) / 240) * 3.2 * s;
      sc = .82;
      ry = 360;
      go = .6;
      final r = widget.r.skjermNaa() == 'hjem' ? OnbMaalRegistry.maal('kaiaeg') : null;
      if (r != null && r.w > 4) {
        _stabil = _forr != null && (_forr!.x - r.x).abs() + (_forr!.y - r.y).abs() + (_forr!.w - r.w).abs() < .6 ? _stabil + 1 : 0;
        _forr = r;
      }
      if (r != null && r.w > 4 && _stabil >= 3) {
        if (r.y + r.h < 40 * s || r.y > widget.H - 24 * s) return _bort();
        _M = Offset(r.x + r.w / 2, r.y + r.h);
        _mh = r.h;
        _e = r.w / _S;
        _C = Offset((_K.dx + _M!.dx) / 2, math.max(70 * s, math.min(_K.dy, _M!.dy) - 120 * s));
        _fase = 'B';
        _tB = t;
        _ring(_K.dx, _K.dy - 2 * s, 86 * s, 24 * s, .15, _mintLys.withValues(alpha: .9), 460, 2);
        _sprut(_K.dx, _K.dy - 4 * s, 6, 14 * s, 26 * s, 40, 140);
      } else if (t > DA + 1700) {
        return _bort();
      }
    }
    if (_fase == 'B') {
      final p = _cl((t - _tB) / DB), f = p * p * (2.2 - 1.2 * p), a1 = 1 - f;
      final M = _M!, C = _C!;
      x = a1 * a1 * _K.dx + 2 * a1 * f * C.dx + f * f * M.dx;
      y = a1 * a1 * _K.dy + 2 * a1 * f * C.dy + f * f * M.dy;
      sc = _lerp(.82, _e, _io(p));
      ry = 360 + 180 * _io(_cl((p - .08) / .64));
      rz = 12 * math.sin(math.pi * p) * (M.dx >= _K.dx ? 1 : -1);
      go = _lerp(.6, .18, p);
      spor = p < .94;
      if (p < .2) {
        final k = math.sin(math.pi * p / .2);
        sy = 1 + .12 * k;
        sx = 1 - .07 * k;
      } else if (p > .78) {
        final k = (p - .78) / .22;
        sy = 1 + .1 * k;
        sx = 1 - .06 * k;
      }
      if (p >= 1) {
        _fase = 'L';
        _tL = t;
        _lande();
      }
    }
    if (_fase == 'L') {
      final q = _cl((t - _tL) / DL);
      x = _M!.dx;
      y = _M!.dy;
      sc = _e;
      ry = 540;
      go = .18 * (1 - q);
      if (q < .28) {
        final f = _ut(q / .28);
        sx = _lerp(.94, 1.22, f);
        sy = _lerp(1.1, .76, f);
      } else if (q < .64) {
        final f = _io((q - .28) / .36);
        sx = _lerp(1.22, .96, f);
        sy = _lerp(.76, 1.05, f);
      } else {
        final f = _io((q - .64) / .36);
        sx = _lerp(.96, 1, f);
        sy = _lerp(1.05, 1, f);
      }
      if (q >= 1) {
        _x = x;
        _y = y;
        _sc = sc;
        _sx = _sy = 1;
        _rz = 0;
        _ry = 540;
        _go = 0;
        return _avslutt();
      }
    }
    _x = x;
    _y = y;
    _sc = sc;
    _sx = sx;
    _sy = sy;
    _rz = rz;
    _ry = ry;
    _go = go;
    _spor = spor;
    if (spor && t - _sistG > 34) {
      _sistG = t;
      _gnist(x, y - _S * sc * .42);
    }
  }

  void _lande() {
    final s = widget.s, M = _M!, fy = M.dy - 3 * s;
    _ring(M.dx, fy, 120 * s, 28 * s, .15, _mintLys.withValues(alpha: .95), 620, 2.5);
    _ring(M.dx, fy, 76 * s, 18 * s, .2, Colors.white.withValues(alpha: .75), 480, 1.5);
    _sprut(M.dx, fy - 8 * s, 12, 26 * s, 50 * s, -172, -8);
    for (var j = 0; j < 6; j++) {
      final sgn = j.isOdd ? 1 : -1, dx = sgn * (10 + j * 4.5) * s, z = (10 + (j % 3) * 3) * s;
      _dust.add(_Ring(M.dx, fy, z, z, .3, const Color.fromRGBO(240, 230, 212, .9), 560, dx, _t - ((j % 3) * 3) * s));
    }
    _pill = true;
    _pillT = _t;
  }

  void _avslutt() {
    _slutt = true;
    // The pill lingers (460 + 1500 + 380 ms) after the landing; the layer is
    // already gone for the user, so hand over at once.
    Future<void>.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) widget.r.kaiFerdig();
    });
    widget.r.kaiSkjult.value = false;
  }

  void _bort() {
    _slutt = true;
    _sprut(_x, _y - _S * .4, 10, 18 * widget.s, 40 * widget.s, 0, 360);
    _fase = 'bort';
    _tL = _t;
    Future<void>.delayed(const Duration(milliseconds: 760), () {
      if (mounted) widget.r.kaiFerdig();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s, S = _S;
    final foran = math.cos(_ry * math.pi / 180) >= 0;
    final bortOp = _fase == 'bort' ? (1 - _cl((_t - _tL) / 320)) : 1.0;
    final goOp = _go.clamp(0.0, 1.0);
    final visAeg = !(_slutt && _fase != 'bort');
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: CustomPaint(painter: _KaiFxMaler(_gn, _sp, _ri, _dust, _t, s))),
            if (visAeg)
              // A box 2S × 1.3S with Ægil's feet at its bottom centre: the
              // transforms pivot there, the glow sits behind his body.
              Positioned(
                left: _x - S,
                top: _y - S * 1.3,
                width: 2 * S,
                height: S * 1.3,
                child: Opacity(
                  opacity: bortOp,
                  child: Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.identity()
                      ..rotateZ(rad(_rz))
                      ..scaleByDouble(_sc * _sx * (_fase == 'bort' ? 1 - .6 * (1 - bortOp) : 1), _sc * _sy * (_fase == 'bort' ? 1 - .6 * (1 - bortOp) : 1), 1, 1),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: S * .38,
                          top: S * .22,
                          width: S * 1.24,
                          height: S * 1.24,
                          child: Opacity(
                            opacity: goOp,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color.fromRGBO(127, 240, 203, .6), Color.fromRGBO(92, 224, 184, .2), Color.fromRGBO(92, 224, 184, 0)], stops: [0, .55, 1])),
                            ),
                          ),
                        ),
                        Positioned(
                          left: S * .5,
                          top: S * .3,
                          width: S,
                          height: S,
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..setEntry(3, 2, 1 / (720 * s))..rotateY(rad(_ry)),
                            child: foran
                                ? Image.asset('assets/images/aegil/voucher.png', fit: BoxFit.contain)
                                : Transform(alignment: Alignment.center, transform: Matrix4.diagonal3Values(-1, 1, 1), child: Image.asset('assets/images/dashboard/rear.png', fit: BoxFit.contain)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_pill && _M != null)
              Builder(
                builder: (context) {
                  final q = _t - _pillT;
                  final inn = const Cubic(.3, 1.2, .5, 1).transform(_cl((q - 140) / 460));
                  final utP = const Cubic(.42, 0, 1, 1).transform(_cl((q - 140 - 460 - 1500) / 380));
                  if (q < 140 || utP >= 1) return const SizedBox.shrink();
                  // The spring curve overshoots 1: the opacity is clamped, the scale keeps the bounce.
                  final op = (inn * (1 - utP)).clamp(0.0, 1.0), sk = kf(inn, const [0, .6, 1], const [.55, 1.07, 1]), dy = kf(inn, const [0, .6, 1], const [10, -2, 0]) - 12 * utP;
                  return Positioned(
                    left: 12 * s,
                    right: 12 * s,
                    top: math.max(52 * s, _M!.dy - _mh - 32 * s - 12 * s) + dy * s,
                    child: Align(
                      alignment: Alignment((_M!.dx / widget.W) * 2 - 1, 0),
                      child: Opacity(
                        opacity: op,
                        child: Transform.scale(
                          scale: sk,
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            padding: EdgeInsets.fromLTRB(6 * s, 6 * s, 13 * s, 6 * s),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(40, 94, 108, .97), Color.fromRGBO(20, 56, 68, .98)]),
                              border: Border.all(color: Colors.white.withValues(alpha: .18)),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .75), blurRadius: 20 * s, spreadRadius: -10 * s, offset: Offset(0, 12 * s))],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 20 * s,
                                  height: 20 * s,
                                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8CF5D5), Color(0xFF3CC79F)]), boxShadow: [BoxShadow(color: _mint.withValues(alpha: .6), blurRadius: 10 * s)]),
                                  child: Center(child: _Ikon(_ikHak, size: 11 * s, color: const Color(0xFF0F3B33), strokeWidth: 3.4)),
                                ),
                                SizedBox(width: 7 * s),
                                Text(OnbCopy.klarTilAaHandle, style: onbDisplay(12.5 * s, letterSpacingEm: -.01)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _KaiFxMaler extends CustomPainter {
  _KaiFxMaler(this.gn, this.sp, this.ri, this.dust, this.t, this.s);
  final List<_Gnist> gn;
  final List<_Sprut> sp;
  final List<_Ring> ri, dust;
  final double t, s;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (final g in gn) {
      final q = ((t - g.t0) / 660).clamp(0.0, 1.0);
      if (q >= 1) continue;
      final c = const Cubic(.2, .7, .4, 1).transform(q);
      final x = g.x + g.jx * s * (1 + .8 * c), y = g.y + g.jy * s + 18 * s * c;
      final z = g.z * (1 - .85 * c);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rad(45 + 115 * c));
      p
        ..color = g.c.withValues(alpha: 1 - q)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * s);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: z, height: z), Radius.circular(1.5 * s)), p);
      canvas.restore();
    }
    for (final k in sp) {
      final q = ((t - k.t0) / 760).clamp(0.0, 1.0);
      if (q >= 1) continue;
      final c = const Cubic(.15, .8, .35, 1).transform(q);
      final f = c < .55 ? c / .55 : 1.0;
      final x = k.x + (k.ex - k.x) * f, y = k.y + (k.ey - k.y) * f + (c > .55 ? 14 * s * (c - .55) / .45 : 0);
      final sk = c < .55 ? .4 + .6 * f : 1 - .7 * (c - .55) / .45, op = c < .55 ? 1.0 : 1 - (c - .55) / .45;
      p
        ..color = k.c.withValues(alpha: op.clamp(0, 1))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5 * s);
      final z = k.z * sk;
      if (k.rund) {
        canvas.drawCircle(Offset(x, y), z / 2, p);
      } else {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: z, height: z), Radius.circular(1.5 * s)), p);
      }
    }
    for (final r in ri) {
      final q = ((t - r.t0) / r.dur).clamp(0.0, 1.0);
      if (q >= 1) continue;
      final c = const Cubic(.2, .8, .3, 1).transform(q);
      final k = r.k0 + (1 - r.k0) * c;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(r.x, r.y), width: r.w * k, height: r.h * k),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r.bw * s
          ..color = r.c.withValues(alpha: r.c.a * (.95 - .95 * c)),
      );
    }
    for (final d in dust) {
      final q = ((t - d.t0) / d.dur).clamp(0.0, 1.0);
      if (q >= 1) continue;
      final c = const Cubic(.2, .8, .3, 1).transform(q);
      final x = d.x + d.bw * c, y = d.y - 7 * s * c, z = d.w * (.3 + 1.2 * c);
      canvas.drawCircle(Offset(x, y), z / 2, Paint()..shader = ui.Gradient.radial(Offset(x, y), z / 2, [d.c.withValues(alpha: .95 * (1 - c)), d.c.withValues(alpha: 0)]));
    }
  }

  @override
  bool shouldRepaint(_KaiFxMaler o) => true;
}
