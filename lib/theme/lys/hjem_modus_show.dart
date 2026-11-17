import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../screens/bergen/kit/bergen_perf.dart';
import 'bergen_modus.dart';

/// Where the Hjem show aims: the moon/sun button, the Bryggen picture, the
/// sea, and the three tabs that really change. Widgets register their keys;
/// the sea registers its point-ripple (design `sjoRippelPkt`).
abstract final class ModusAnkre {
  static final GlobalKey bryter = GlobalKey(debugLabel: 'modusBryter');
  static final GlobalKey byen = GlobalKey(debugLabel: 'modusByen');
  static final GlobalKey vann = GlobalKey(debugLabel: 'modusVann');

  /// Utforsk, Kurv, Meg (the nav tabs).
  static final List<GlobalKey> faner = List.generate(3, (i) => GlobalKey(debugLabel: 'modusFane$i'));

  /// Drops a ripple at (x, y) in the sea canvas' own px, strength a.
  static void Function(double x, double y, double a)? rippel;

  /// The tab icons bounce (540 ms) when their light orb lands: tab index → start.
  static final ValueNotifier<Map<int, Duration>> faneSprett = ValueNotifier(const {});

  /// The button's bounce (the show's first beat).
  static final ValueNotifier<int> bryterSprett = ValueNotifier(0);
}

/// A nav tab icon that bounces when the show's light orb lands on it
/// (`translateY(-5px) scale(1.22)` at 35 %, 540 ms, `cubic-bezier(.3,1.5,.5,1)`).
class ModusFaneSprett extends StatefulWidget {
  const ModusFaneSprett({super.key, required this.fane, required this.child});

  /// 0 = Utforsk, 1 = Kurv, 2 = Meg.
  final int fane;
  final Widget child;

  @override
  State<ModusFaneSprett> createState() => _ModusFaneSprettState();
}

class _ModusFaneSprettState extends State<ModusFaneSprett> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 540));
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    ModusAnkre.faneSprett.addListener(_planlegg);
  }

  @override
  void dispose() {
    ModusAnkre.faneSprett.removeListener(_planlegg);
    _a.dispose();
    super.dispose();
  }

  void _planlegg() {
    final d = ModusAnkre.faneSprett.value[widget.fane];
    final gen = ++_gen;
    if (d == null) return;
    Future<void>.delayed(d * timeDilation, () {
      if (mounted && gen == _gen) _a.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _a,
        child: widget.child,
        builder: (context, child) {
          // One tree shape: identity transforms when idle.
          final t = _a.isAnimating ? const Cubic(.3, 1.5, .5, 1).transform(_a.value) : 0.0;
          // keyframes none → (35 %) translateY(-5px) scale(1.22) → none, eased as one animation
          final k = t < .35 ? t / .35 : 1 - (t - .35) / .65;
          return Transform.translate(offset: Offset(0, -5 * k), child: Transform.scale(scale: 1 + .22 * k, child: child));
        },
      );
}

/// Lys plan Step 2: the switch moment on Hjem (design `modusShow`, ~4.6 s).
/// Hjem stays fjord, so the change is shown in the scene: the button bounces
/// with two shock rings and ten sparks, the sun (or moon) flies in an arc to
/// over Bryggen with a five-ghost tail and stays, an impact wave rolls out,
/// the scene over Vågen glows (light: sun rays, a glint over the water,
/// 12 sparkles; dark: dusk, 18 stars, 32 windows, a shooting star), a light
/// column stands on the water with three sea ripples, light orbs fly down to
/// Utforsk, Kurv and Meg (ring burst, a mini sun/moon badge, the icon bounces)
/// and a pill explains why Hjem looks the same. Full tier only (L9); `lite`
/// and `still` fall through to the circle reveal / instant switch.
class HjemModusShow extends StatefulWidget {
  const HjemModusShow({super.key, required this.aktiv});

  /// Only while Hjem is the visible tab.
  final bool aktiv;

  @override
  State<HjemModusShow> createState() => _HjemModusShowState();
}

class _HjemModusShowState extends State<HjemModusShow> with SingleTickerProviderStateMixin implements ModusVert {
  late final Ticker _ticker = createTicker(_tick);
  Duration _t = Duration.zero;
  _Plan? _plan;
  final List<int> _rippler = [];

  @override
  void initState() {
    super.initState();
    BergenModus.i.registrer(this);
  }

  @override
  void didUpdateWidget(HjemModusShow old) {
    super.didUpdateWidget(old);
    // Left Hjem mid-show: stop drawing over the other tab, toast at once.
    if (old.aktiv && !widget.aktiv && _plan != null) _slutt();
  }

  @override
  void dispose() {
    BergenModus.i.avregistrer(this);
    _ticker.dispose();
    super.dispose();
  }

  void _slutt() {
    final p = _plan;
    _ticker.stop();
    _plan = null;
    _rippler.clear();
    ModusAnkre.faneSprett.value = const {};
    // The debug harness slowed time for shots; back to normal once the moment ends.
    if (kDebugMode) timeDilation = 1.0;
    if (mounted) setState(() {});
    if (p != null) BergenModus.i.visToast?.call(p.lys);
  }

  Rect? _rect(GlobalKey k) {
    final ro = k.currentContext?.findRenderObject();
    final me = context.findRenderObject();
    if (ro is! RenderBox || me is! RenderBox || !ro.attached || !ro.hasSize) return null;
    final o = ro.localToGlobal(Offset.zero, ancestor: me);
    return o & ro.size;
  }

  @override
  bool spill({required bool lys, required Offset? fra, required ModusKilde kilde, required VoidCallback bruk}) {
    if (!mounted || !widget.aktiv || kilde != ModusKilde.hjem) return false;
    if (BergenPerf.of(context) != BergenTier.full) return false;
    final me = context.findRenderObject();
    if (me is! RenderBox || !me.hasSize) return false;
    final size = me.size;
    final b = _rect(ModusAnkre.bryter);
    final bc = b?.center ?? (fra != null ? me.globalToLocal(fra) : size.center(Offset.zero));
    final byen = _rect(ModusAnkre.byen) ?? Rect.fromLTWH(0, bc.dy + 36, size.width, 127);
    final vann = _rect(ModusAnkre.vann) ?? Rect.fromLTWH(0, byen.bottom, size.width, 110);
    final faner = [for (final k in ModusAnkre.faner) _rect(k)].whereType<Rect>().toList();
    _plan = _Plan(lys: lys, size: size, bx: bc.dx, by: bc.dy, byen: byen, vann: vann, faner: faner);
    _rippler
      ..clear()
      ..addAll(const [880, 1250, 1700]);
    _t = Duration.zero;
    _ticker
      ..stop()
      ..start();
    ModusAnkre.bryterSprett.value++;
    // Design: `bruk()` at the start — the tabs underneath are already the new mode.
    bruk();
    final starts = <int, Duration>{};
    for (var i = 0; i < faner.length; i++) {
      starts[i] = Duration(milliseconds: 1450 + i * 120 + 700);
    }
    ModusAnkre.faneSprett.value = starts;
    return true;
  }

  void _tick(Duration t) {
    final p = _plan;
    if (p == null) return;
    _t = t;
    final ms = t.inMicroseconds / 1000;
    while (_rippler.isNotEmpty && ms >= _rippler.first) {
      final i = 3 - _rippler.length;
      _rippler.removeAt(0);
      final r = ModusAnkre.rippel;
      if (r != null) {
        r(p.tx - p.vann.left + (i - 1) * 18, p.havY - p.vann.top + 10 + i * 12, .8);
      }
    }
    if (ms >= 4600) {
      _slutt();
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = _plan;
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: p == null ? null : _ShowMaler(p, _t.inMicroseconds / 1000),
        child: p == null
            ? const SizedBox.expand()
            : _Pille(lys: p.lys, ms: _t.inMicroseconds / 1000, bunn: p.size.height - p.navTop + 14),
      ),
    );
  }
}

/// The geometry of one show (design coordinates of the phone frame).
class _Plan {
  _Plan({required this.lys, required this.size, required this.bx, required this.by, required this.byen, required this.vann, required this.faner}) {
    final w = size.width, hh = size.height;
    tx = w * .3;
    ty = math.max(64, math.min(hh * .4, byen.top + 30));
    rEnd = lys ? 220 : -40;
    havY = math.max(vann.top, byen.bottom);
    havB = math.max(havY + 40, vann.bottom);
    fl = _bane(Offset(bx, by), Offset((bx + tx) / 2, math.min(by, ty) - 64), Offset(tx, ty), 16, .45, 1.5, rEnd);
    navTop = faner.isEmpty ? hh - 90 : faner.map((r) => r.top).reduce(math.min);
    // Seeded the design's way (`rnd`, Park–Miller 16807) so stars and sparks sit where they sit there.
    var s = lys ? 4711 : 1337;
    double rnd() {
      s = (s * 16807) % 2147483647;
      return s / 2147483647;
    }

    for (var i = 0; i < 10; i++) {
      gnist.add([i * 36 + rnd() * 12, 40 + rnd() * 16]);
    }
    final W = w, wy = havY - byen.top, wh = havB - havY;
    if (lys) {
      for (var i = 0; i < 12; i++) {
        final px = rnd() * W, py = wy + 6 + rnd() * math.max(4, wh - 12), z = 8 + rnd() * 8;
        glitter.add([px, py, z, 1000 + rnd() * 1100]);
      }
    } else {
      for (var i = 0; i < 18; i++) {
        final px = rnd() * W, py = 4 + rnd() * byen.height * .42, z = 1.5 + rnd() * 1.8;
        stjerner.add([px, py, z, 760 + rnd() * 600]);
      }
      for (var i = 0; i < 32; i++) {
        final px = 6 + rnd() * (W - 12), py = byen.height * (.38 + rnd() * .55), ww = 2.4 + rnd() * 1.6, d0 = 900 + i * 28 + rnd() * 300;
        vinduer.add([px, py, ww, d0]);
      }
    }
    for (var i = 0; i < faner.length; i++) {
      final t = faner[i];
      final ex = t.left + t.width / 2, ey = t.top + t.height * .38;
      faneBaner.add(_bane(Offset(tx, ty), Offset((tx + ex) / 2 + (i - 1) * 60 - 40, ty + (ey - ty) * .35), Offset(ex, ey), 12, 1.4, .8, 0));
    }
  }

  final bool lys;
  final Size size;
  final double bx, by;
  final Rect byen, vann;
  final List<Rect> faner;
  late final double tx, ty, rEnd, havY, havB, navTop;
  late final List<_P> fl;
  final List<List<double>> gnist = [], glitter = [], stjerner = [], vinduer = [];
  final List<List<_P>> faneBaner = [];
}

class _P {
  const _P(this.x, this.y, this.s, this.r, this.k);
  final double x, y, s, r, k;
}

double _ez(double u) => u < .5 ? 2 * u * u : 1 - math.pow(-2 * u + 2, 2) / 2;

List<_P> _bane(Offset p0, Offset p1, Offset p2, int n, double s0, double s1, double r1) {
  return [
    for (var i = 0; i <= n; i++)
      () {
        final u = _ez(i / n), v = 1 - u;
        return _P(v * v * p0.dx + 2 * v * u * p1.dx + u * u * p2.dx, v * v * p0.dy + 2 * v * u * p1.dy + u * u * p2.dy, s0 + (s1 - s0) * u, r1 * u, i / n);
      }(),
  ];
}

/// One WAAPI keyframe track: offsets 0…1 with values, linear between (the
/// whole animation's easing applied to the global progress, as WAAPI does).
class _Kf {
  const _Kf(this.o, this.v);
  final double o;
  final List<double> v;
}

List<double> _spor(List<_Kf> kf, double u) {
  if (u <= kf.first.o) return kf.first.v;
  for (var i = 1; i < kf.length; i++) {
    if (u <= kf[i].o) {
      final a = kf[i - 1], b = kf[i];
      final f = b.o == a.o ? 1.0 : (u - a.o) / (b.o - a.o);
      return [for (var j = 0; j < a.v.length; j++) a.v[j] + (b.v[j] - a.v[j]) * f];
    }
  }
  return kf.last.v;
}

const Cubic _std = Cubic(.3, .7, .2, 1);
const Cubic _ring = Cubic(.2, .7, .3, 1);
const Cubic _bolge = Cubic(.2, .6, .3, 1);
const Cubic _glint = Cubic(.5, 0, .3, 1);
const Cubic _sky = Cubic(.3, 0, .7, 1);

/// Progress of an animation (delay, duration) at ms, eased; null before its start
/// (fill: both keeps the first frame before the start, so callers treat null as u = 0
/// where the first keyframe is visible, else skip).
double? _u(double ms, double delay, double dur, [Curve c = _std]) {
  if (ms < delay) return null;
  final x = ((ms - delay) / dur).clamp(0.0, 1.0);
  return c.transform(x);
}

class _ShowMaler extends CustomPainter {
  _ShowMaler(this.p, this.ms);

  final _Plan p;
  final double ms;

  static const _solKjerne = [Color(0xFFFFFFFF), Color(0xFFFFF3C4), Color(0xFFFFD36B), Color(0xFFFFA94D)];

  Color _g(double a) => p.lys ? Color.fromRGBO(255, 200, 100, a) : Color.fromRGBO(170, 210, 255, a);
  Color get _r => p.lys ? const Color(0xFFFFD98A) : const Color(0xFFCBE6FF);

  void _sol(Canvas c, Offset o, double d, double op) {
    final r = d / 2;
    final rect = Rect.fromCircle(center: o, radius: r);
    c.drawCircle(
      o,
      r,
      Paint()
        ..shader = ui.Gradient.radial(Offset(o.dx - r + d * .38, o.dy - r + d * .36), r * 1.6, [for (final k in _solKjerne) k.withValues(alpha: op)], const [0, .28, .58, 1]),
    );
    rect.hashCode;
  }

  void _maane(Canvas c, Offset o, double d, double op) {
    final r = d / 2;
    final tl = Offset(o.dx - r, o.dy - r);
    c.drawCircle(
      o,
      r,
      Paint()
        ..shader = ui.Gradient.radial(tl + Offset(d * .36, d * .34), r * 1.5, [
          const Color(0xFFFFFFFF).withValues(alpha: op),
          const Color(0xFFE9F2FC).withValues(alpha: op),
          const Color(0xFFC4D6EA).withValues(alpha: op),
        ], const [0, .55, 1]),
    );
    void krater(double cx, double cy, double rr, double a) {
      c.drawCircle(tl + Offset(d * cx, d * cy), d * rr, Paint()..color = Color.fromRGBO(150, 178, 208, a * op));
    }

    krater(.64, .58, .155, .6);
    krater(.34, .66, .105, .5);
    krater(.48, .28, .085, .45);
  }

  void _glod(Canvas c, Offset o, double r, Color col) {
    if (r <= 0 || col.a <= 0) return;
    c.drawCircle(o, r, Paint()..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .5)..color = col);
  }

  @override
  void paint(Canvas c, Size size) {
    final L = p.lys;
    // 1 · button rings + sparks
    for (var i = 0; i < 2; i++) {
      final u = _u(ms, i * 120.0, 680, _ring);
      if (u == null || u >= 1) continue;
      final s = .5 + (2.9 - .5) * u, op = .95 * (1 - u);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * s
        ..color = _r.withValues(alpha: op);
      _glod(c, Offset(p.bx, p.by), 20 * s + 7, _g(.55 * op * .5));
      c.drawCircle(Offset(p.bx, p.by), 19 * s, paint);
    }
    final ug = _u(ms, 30, 600);
    if (ug != null && ug < 1) {
      for (final g in p.gnist) {
        final a = g[0] * math.pi / 180, d = 16 + (g[1] - 16) * ug, s = 1 - .7 * ug, op = 1 - ug;
        c.save();
        c.translate(p.bx, p.by);
        c.rotate(a);
        c.translate(0, -d);
        c.scale(s);
        if (L) {
          c.drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTWH(-1.5, -5.5, 3, 11), const Radius.circular(3)),
            Paint()..shader = ui.Gradient.linear(const Offset(0, -5.5), const Offset(0, 5.5), [const Color(0xFFFFF6D6).withValues(alpha: op), const Color(0xFFFFC25C).withValues(alpha: op)]),
          );
        } else {
          _glod(c, Offset.zero, 6, Color.fromRGBO(170, 210, 255, .7 * op));
          c.drawCircle(Offset.zero, 2.5, Paint()..color = const Color(0xFFEAF5FF).withValues(alpha: op));
        }
        c.restore();
      }
    }
    // 3 · impact wave (screen / multiply)
    final ub = _u(ms, 780, 1150, _bolge);
    if (ub != null && ub < 1) {
      final S = math.max(size.width, size.height) * 1.7;
      final r = S / 2 * (.05 + .95 * ub), op = 1 - ub;
      c.drawCircle(
        Offset(p.tx, p.ty),
        r,
        Paint()
          ..blendMode = L ? BlendMode.screen : BlendMode.multiply
          ..shader = ui.Gradient.radial(Offset(p.tx, p.ty), r, L
              ? [Color.fromRGBO(255, 232, 176, .6 * op), Color.fromRGBO(255, 232, 176, .32 * op), const Color.fromRGBO(255, 232, 176, 0)]
              : [Color.fromRGBO(8, 24, 52, .55 * op), Color.fromRGBO(8, 24, 52, .3 * op), const Color.fromRGBO(8, 24, 52, 0)], const [0, .3, .6]),
      );
    }
    // 4 · the scene over Vågen (clipped to Bryggen + the sea)
    final hz = Rect.fromLTWH(0, p.byen.top, size.width, p.havB - p.byen.top);
    c.save();
    c.clipRect(hz);
    c.translate(0, p.byen.top);
    final sx = p.tx, sy = p.ty - p.byen.top, wy = p.havY - p.byen.top, wh = p.havB - p.havY, W = size.width;
    final uh = _u(ms, 700, 2300, Curves.easeInOut);
    if (uh != null) {
      final op = _spor(const [_Kf(0, [0]), _Kf(.22, [1]), _Kf(.7, [1]), _Kf(1, [0])], uh)[0];
      if (op > 0) {
        final rx = W * .7, ry = hz.height * .9;
        c.save();
        c.translate(sx, sy);
        c.scale(1, ry / rx);
        c.drawCircle(
          Offset.zero,
          rx,
          Paint()
            ..blendMode = BlendMode.screen
            ..shader = ui.Gradient.radial(Offset.zero, rx, L
                ? [Color.fromRGBO(255, 220, 150, .62 * op), Color.fromRGBO(255, 186, 120, .2 * op), const Color.fromRGBO(255, 186, 120, 0)]
                : [Color.fromRGBO(180, 215, 255, .34 * op), Color.fromRGBO(140, 190, 240, .1 * op), const Color.fromRGBO(140, 190, 240, 0)], L ? const [0, .45, .72] : const [0, .4, .65]),
        );
        c.restore();
      }
    }
    if (L) {
      // rotating conic rays
      final ur = _u(ms, 720, 2300, Curves.linear);
      if (ur != null && ur < 1) {
        final v = _spor(const [_Kf(0, [.6, -10, 0]), _Kf(.3, [1, 4, 1]), _Kf(.7, [1.05, 16, .8]), _Kf(1, [1.1, 24, 0])], ur);
        if (v[2] > 0) {
          c.save();
          c.translate(sx, sy);
          c.rotate(v[1] * math.pi / 180);
          c.scale(v[0]);
          final colors = <Color>[], stops = <double>[];
          for (var k = 0; k < 24; k++) {
            final a0 = k * 15 / 360, a1 = (k * 15 + 5) / 360, a2 = (k * 15 + 15) / 360;
            colors.addAll([Color.fromRGBO(255, 236, 186, .34 * v[2]), Color.fromRGBO(255, 236, 186, .34 * v[2]), const Color.fromRGBO(255, 236, 186, 0), const Color.fromRGBO(255, 236, 186, 0)]);
            stops.addAll([a0, a1, a1, a2]);
          }
          final ray = Paint()
            ..blendMode = BlendMode.screen
            ..shader = ui.Gradient.sweep(Offset.zero, colors, stops, TileMode.clamp, -math.pi / 2, 3 * math.pi / 2);
          c.saveLayer(const Rect.fromLTWH(-300, -300, 600, 600), Paint()..blendMode = BlendMode.screen);
          c.drawCircle(Offset.zero, 300, ray..blendMode = BlendMode.srcOver);
          // mask: radial #000 6%, .5 30%, transparent 62%
          c.drawCircle(
            Offset.zero,
            300,
            Paint()
              ..blendMode = BlendMode.dstIn
              ..shader = ui.Gradient.radial(Offset.zero, 300, const [Color(0xFF000000), Color(0x80000000), Color(0x00000000)], const [.06, .3, .62]),
          );
          c.restore();
          c.restore();
        }
      }
      // glint over the water
      final ul = _u(ms, 980, 1100, _glint);
      if (ul != null && ul < 1) {
        final op = _spor(const [_Kf(0, [0]), _Kf(.15, [1]), _Kf(.8, [1]), _Kf(1, [0])], ul)[0];
        final x = -W * .5 + (W * 1.1 + W * .5) * ul;
        c.save();
        c.translate(x, wy);
        c.transform(Float64List.fromList([1, 0, 0, 0, math.tan(-24 * math.pi / 180), 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]));
        final gw = W * .45;
        c.drawRect(
          Rect.fromLTWH(0, 0, gw, wh),
          Paint()
            ..blendMode = BlendMode.screen
            ..shader = ui.Gradient.linear(Offset.zero, Offset(gw, 0), [const Color.fromRGBO(255, 244, 210, 0), Color.fromRGBO(255, 244, 210, .62 * op), const Color.fromRGBO(255, 244, 210, 0)], const [0, .5, 1]),
        );
        c.restore();
      }
      // 12 sparkle stars
      for (final g in p.glitter) {
        final u = _u(ms, g[3], 700, Curves.easeOut);
        if (u == null || u >= 1) continue;
        final v = _spor(const [_Kf(0, [0, 0, 0]), _Kf(.4, [1, 45, 1]), _Kf(1, [0, 90, 0])], u);
        if (v[2] <= 0) continue;
        c.save();
        c.translate(g[0], g[1]);
        c.rotate(v[1] * math.pi / 180);
        c.scale(v[0]);
        final z = g[2];
        Offset q(double fx, double fy) => Offset((fx - .5) * z, (fy - .5) * z);
        c.drawPath(
          Path()
            ..moveTo(q(.5, 0).dx, q(.5, 0).dy)
            ..lineTo(q(.58, .42).dx, q(.58, .42).dy)
            ..lineTo(q(1, .5).dx, q(1, .5).dy)
            ..lineTo(q(.58, .58).dx, q(.58, .58).dy)
            ..lineTo(q(.5, 1).dx, q(.5, 1).dy)
            ..lineTo(q(.42, .58).dx, q(.42, .58).dy)
            ..lineTo(q(0, .5).dx, q(0, .5).dy)
            ..lineTo(q(.42, .42).dx, q(.42, .42).dy)
            ..close(),
          Paint()..color = Color.fromRGBO(255, 255, 255, v[2]),
        );
        c.restore();
      }
    } else {
      // dusk tint
      final ud = _u(ms, 640, 2400, Curves.easeInOut);
      if (ud != null) {
        final op = _spor(const [_Kf(0, [0]), _Kf(.22, [1]), _Kf(.72, [1]), _Kf(1, [0])], ud)[0];
        if (op > 0) {
          final r = Rect.fromLTWH(0, 0, W, hz.height);
          c.drawRect(
            r,
            Paint()
              ..blendMode = BlendMode.multiply
              ..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, [Color.fromRGBO(8, 20, 54, .62 * op), Color.fromRGBO(14, 34, 66, .42 * op), Color.fromRGBO(6, 18, 36, .5 * op)], const [0, .55, 1]),
          );
        }
      }
      for (final s in p.stjerner) {
        final u = _u(ms, s[3], 2100, Curves.easeInOut);
        if (u == null || u >= 1) continue;
        final op = _spor(const [_Kf(0, [0]), _Kf(.15, [1]), _Kf(.3, [.35]), _Kf(.45, [1]), _Kf(.65, [.5]), _Kf(.78, [1]), _Kf(1, [0])], u)[0];
        _glod(c, Offset(s[0], s[1]), s[2] / 2 + 3, Color.fromRGBO(200, 225, 255, .8 * op * .6));
        c.drawCircle(Offset(s[0], s[1]), s[2] / 2, Paint()..color = Color.fromRGBO(255, 255, 255, op));
      }
      for (final v in p.vinduer) {
        final dur = 3100 - v[3];
        final u = _u(ms, v[3], dur, Curves.linear);
        if (u == null || u >= 1) continue;
        final op = _spor(const [_Kf(0, [0]), _Kf(.06, [1]), _Kf(.09, [.3]), _Kf(.14, [1]), _Kf(.8, [1]), _Kf(1, [0])], u)[0];
        final r = Rect.fromLTWH(v[0], v[1], v[2], v[2] * 1.35);
        _glod(c, r.center, v[2] + 2, Color.fromRGBO(255, 190, 90, .65 * op * .6));
        c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(.6)), Paint()..color = const Color(0xFFFFD27A).withValues(alpha: op));
      }
      final us = _u(ms, 1500, 700, _sky);
      if (us != null && us < 1) {
        final p0 = Offset(W * .88, 6), p1 = Offset(W * .46, p.byen.height * .46);
        final ang = math.atan2(p1.dy - p0.dy, p1.dx - p0.dx);
        final v = _spor(const [_Kf(0, [0, .2, 0]), _Kf(.2, [.2, .44, 1]), _Kf(.75, [.75, .86, 1]), _Kf(1, [1, 1, 0])], us);
        final o = Offset.lerp(p0, p1, v[0])!;
        c.save();
        c.translate(o.dx, o.dy);
        c.rotate(ang);
        c.scale(v[1]);
        c.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(-70, -1, 70, 2), const Radius.circular(2)),
          Paint()..shader = ui.Gradient.linear(const Offset(-70, 0), Offset.zero, [const Color(0x00FFFFFF), Color.fromRGBO(255, 255, 255, v[2])]),
        );
        c.restore();
      }
    }
    // reflection column on the water (both)
    final uc = _u(ms, 820, 2100, Curves.easeInOut);
    if (uc != null && uc < 1) {
      final v = _spor(const [_Kf(0, [.2, 0, 0]), _Kf(.25, [1, 1, 1]), _Kf(.4, [.7, 1, 1]), _Kf(.55, [1.15, 1, 1]), _Kf(.7, [.85, 1, 1]), _Kf(.8, [1, 1, 1]), _Kf(1, [1.2, 1, 0])], uc);
      if (v[2] > 0 && v[1] > 0) {
        c.save();
        c.translate(sx, wy);
        c.scale(v[0], v[1]);
        final r = Rect.fromLTWH(-30, 0, 60, wh);
        c.saveLayer(r, Paint()..blendMode = BlendMode.screen);
        final stripe = L ? Color.fromRGBO(255, 226, 160, .8 * v[2]) : Color.fromRGBO(214, 234, 255, .75 * v[2]);
        for (double y = 0; y < wh; y += 6) {
          c.drawRect(Rect.fromLTWH(-30, y, 60, 2.5), Paint()..color = stripe);
        }
        c.save();
        c.translate(0, 0);
        c.scale(1, wh / 30);
        c.drawCircle(
          Offset.zero,
          30,
          Paint()
            ..blendMode = BlendMode.dstIn
            ..shader = ui.Gradient.radial(Offset.zero, 30, const [Color(0xFF000000), Color(0xFF000000), Color(0x00000000)], const [0, .2, 1]),
        );
        c.drawRect(const Rect.fromLTWH(-30, 30, 60, 1e5), Paint()..blendMode = BlendMode.clear);
        c.restore();
        c.restore();
        c.restore();
      }
    }
    c.restore();
    // 2 · the ghosts and the orb
    for (var g = 4; g >= 0; g--) {
      final u = _u(ms, 60.0 + (g + 1) * 34, 950, Curves.linear);
      if (u == null || u >= 1) continue;
      final kf = <_Kf>[for (var i = 0; i < p.fl.length; i++) _Kf(p.fl[i].k * .8, [p.fl[i].x, p.fl[i].y, p.fl[i].s * .9, i == 0 ? 0 : .55 - g * .09]), _Kf(1, [p.tx, p.ty, 1.2, 0])];
      final v = _spor(kf, u);
      if (v[3] <= 0) continue;
      final sz = 30.0 - g * 3, r = sz / 2 * v[2];
      c.drawCircle(Offset(v[0], v[1]), r, Paint()..shader = ui.Gradient.radial(Offset(v[0], v[1]), r, [_g(.95 * v[3]), _g(0)], const [0, .7]));
    }
    final uo = _u(ms, 60, 3000, Curves.linear);
    if (uo != null && uo < 1) {
      final kf = <_Kf>[
        for (var i = 0; i < p.fl.length; i++) _Kf(p.fl[i].k * .253, [p.fl[i].x, p.fl[i].y, p.fl[i].s, p.fl[i].r, math.min(1, i / 2)]),
        _Kf(.29, [p.tx, p.ty, 1.3, p.rEnd, 1]),
        _Kf(.34, [p.tx, p.ty, 1.46, p.rEnd, 1]),
        _Kf(.8, [p.tx, p.ty, 1.46, p.rEnd + (L ? 30 : 0), 1]),
        _Kf(1, [p.tx, p.ty - (L ? 6 : 10), L ? 2.3 : 1.2, p.rEnd + (L ? 40 : 0), 0]),
      ];
      final v = _spor(kf, uo);
      if (v[4] > 0) {
        final o = Offset(v[0], v[1]), s = v[2], op = v[4];
        c.save();
        c.translate(o.dx, o.dy);
        c.rotate(v[3] * math.pi / 180);
        c.scale(s);
        // box-shadow halo: 0 0 0 6px, 0 0 26px 10px, 0 0 80px 30px
        if (L) {
          _glod(c, Offset.zero, 22 + 30 + 40, Color.fromRGBO(255, 170, 70, .32 * op * .5));
          _glod(c, Offset.zero, 22 + 10 + 13, Color.fromRGBO(255, 196, 92, .6 * op * .6));
          c.drawCircle(Offset.zero, 28, Paint()..color = Color.fromRGBO(255, 214, 120, .22 * op));
          _sol(c, Offset.zero, 44, op);
        } else {
          _glod(c, Offset.zero, 22 + 26 + 35, Color.fromRGBO(120, 170, 230, .28 * op * .5));
          _glod(c, Offset.zero, 22 + 8 + 12, Color.fromRGBO(170, 210, 255, .5 * op * .6));
          c.drawCircle(Offset.zero, 28, Paint()..color = Color.fromRGBO(200, 225, 255, .16 * op));
          _maane(c, Offset.zero, 44, op);
        }
        c.restore();
      }
    }
    // 5 · light orbs down to the tabs
    for (var i = 0; i < p.faner.length; i++) {
      final t = p.faner[i];
      final ex = t.left + t.width / 2, ey = t.top + t.height * .38, d0 = 1450.0 + i * 120;
      final mb = p.faneBaner[i];
      for (var g = 2; g >= 0; g--) {
        final u = _u(ms, d0 + g * 40, 780, Curves.linear);
        if (u == null || u >= 1) continue;
        final kf = <_Kf>[for (var j = 0; j < mb.length; j++) _Kf(mb[j].k * .92, [mb[j].x, mb[j].y, mb[j].s, j == 0 ? 0 : (g > 0 ? .5 - g * .15 : 1)]), _Kf(1, [ex, ey, .4, 0])];
        final v = _spor(kf, u);
        if (v[3] <= 0) continue;
        final z = g > 0 ? 8.0 : 12.0, r = z / 2 * v[2];
        final o = Offset(v[0], v[1]);
        if (g == 0) _glod(c, o, r + 6, _g(.55 * v[3] * .6));
        c.drawCircle(o, r, Paint()..shader = ui.Gradient.radial(o, r, [Color.fromRGBO(255, 255, 255, v[3]), (L ? const Color(0xFFFFF6D6) : const Color(0xFFEAF4FF)).withValues(alpha: v[3]), _g(0)], const [0, .4, .72]));
      }
      final ur = _u(ms, d0 + 720, 620, _ring);
      if (ur != null && ur < 1) {
        final s = .4 + 1.5 * ur, op = 1 - ur;
        _glod(c, Offset(ex, ey), 17 * s + 6, _g(.6 * op * .4));
        c.drawCircle(Offset(ex, ey), 16 * s, Paint()..style = PaintingStyle.stroke..strokeWidth = 2 * s..color = _r.withValues(alpha: op));
      }
      final um = _u(ms, d0 + 700, 2200);
      if (um != null && um < 1) {
        final v = _spor(const [_Kf(0, [0, 0]), _Kf(.12, [1.25, 1]), _Kf(.2, [1, 1]), _Kf(.85, [1, 1]), _Kf(1, [.6, 0])], um);
        if (v[1] > 0) {
          final o = Offset(ex + 11, ey - 9);
          c.save();
          c.translate(o.dx, o.dy);
          c.scale(v[0]);
          _glod(c, Offset.zero, 8 + 4, _g(.6 * v[1] * .6));
          c.drawCircle(Offset.zero, 10, Paint()..color = Color.fromRGBO(20, 60, 70, .9 * v[1]));
          if (L) {
            _sol(c, Offset.zero, 16, v[1]);
          } else {
            c.drawCircle(Offset.zero, 8, Paint()..color = const Color(0xFFEAF4FF).withValues(alpha: v[1]));
            c.drawCircle(const Offset(5, -2), 8, Paint()..color = const Color(0xFF1A4452).withValues(alpha: v[1]));
          }
          c.restore();
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ShowMaler o) => o.ms != ms || o.p != p;
}

/// 6 · «Lys modus er på · Utforsk, Kurv og Meg er nå lyse. Hjem beholder fjorden.»
class _Pille extends StatelessWidget {
  const _Pille({required this.lys, required this.ms, required this.bunn});

  final bool lys;
  final double ms;
  final double bunn;

  @override
  Widget build(BuildContext context) {
    final u = _u(ms, 2050, 2400, const Cubic(.3, .8, .3, 1));
    if (u == null || u >= 1) return const SizedBox.expand();
    final v = _spor(const [_Kf(0, [16, .92, 0]), _Kf(.14, [0, 1, 1]), _Kf(.86, [0, 1, 1]), _Kf(1, [8, .96, 0])], u);
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: bunn,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Opacity(
                opacity: v[2].clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, v[0]),
                  child: Transform.scale(
                    scale: v[1],
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(9, 9, 14, 9),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: const Color.fromRGBO(14, 42, 52, .88),
                        border: Border.all(color: const Color.fromRGBO(255, 255, 255, .14)),
                        boxShadow: const [BoxShadow(offset: Offset(0, 12), blurRadius: 30, spreadRadius: -12, color: Color.fromRGBO(0, 0, 0, .6))],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 30, height: 30, child: CustomPaint(painter: _PilleOrb(lys))),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(lys ? 'Lys modus er på' : 'Mørk modus er på',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, letterSpacing: -.135, color: const Color(0xFFFFFFFF))),
                                const SizedBox(height: 1),
                                Text(lys ? 'Utforsk, Kurv og Meg er nå lyse. Hjem beholder fjorden.' : 'Utforsk, Kurv og Meg er tilbake i fjord.',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.3, color: const Color.fromRGBO(255, 255, 255, .86))),
                              ],
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
        ),
      ],
    );
  }
}

class _PilleOrb extends CustomPainter {
  _PilleOrb(this.lys);
  final bool lys;

  @override
  void paint(Canvas c, Size size) {
    final m = _ShowMaler(_dummy, 0);
    final o = size.center(Offset.zero);
    c.drawCircle(o, 15 + 6, Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)..color = lys ? const Color.fromRGBO(255, 200, 100, .4) : const Color.fromRGBO(170, 210, 255, .35));
    if (lys) {
      m._sol(c, o, 30, 1);
    } else {
      m._maane(c, o, 30, 1);
    }
  }

  static final _Plan _dummy = _Plan(lys: true, size: const Size(390, 844), bx: 0, by: 0, byen: Rect.zero, vann: Rect.zero, faner: const []);

  @override
  bool shouldRepaint(_PilleOrb o) => o.lys != lys;
}
