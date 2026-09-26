import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../theme/bergen_tokens.dart';
import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_painters.dart';
import 'fiske_frame.dart';

/// `Sjø · fiske` (design ≈L6491–6508): the water from `top:223px` to the
/// bottom.
///
/// The prototype bakes its ripple textures once (`sjoBake()`: SVG patterns
/// pushed through `feTurbulence` + `feDisplacementMap`, rasterised to a
/// canvas) and then only *moves* them: four tiled layers and a glint inside a
/// `perspective(560px) rotateX(-24deg)` box, each drifting on `sjoX` /
/// `sjoY` (±18 px / ±8 px, `ease-in-out infinite alternate`, 9–23 s). This
/// widget does the same: [FiskeSjoBake] draws the two tiles to a `ui.Image`
/// once per sea mode, and [_SjoLayersPainter] only translates them — no
/// filter on an animated layer (the prototype's own note: drop-shadow on an
/// animated layer stutters).
class FiskeSjo extends StatefulWidget {
  const FiskeSjo({super.key, required this.mode});

  final BergenSea mode;

  @override
  State<FiskeSjo> createState() => _FiskeSjoState();
}

class _FiskeSjoState extends State<FiskeSjo> {
  ui.Image? _hero;
  ui.Image? _ka;
  bool _asked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_asked) return;
    _asked = true;
    final dpr = math.min(2.0, MediaQuery.devicePixelRatioOf(context));
    FiskeSjoBake.hero(widget.mode, dpr).then((img) {
      if (mounted) setState(() => _hero = img);
    });
    FiskeSjoBake.ka(dpr).then((img) {
      if (mounted) setState(() => _ka = img);
    });
  }

  @override
  Widget build(BuildContext context) {
    final f = FiskeFrame.of(context);
    final s = f.s;
    final mode = widget.mode;
    final base = BergenTokens.seaFor(mode);
    final depth = switch (mode) {
      BergenSea.day => (
        const [Color(0xFF9FC3CC), Color(0xFF7FAAB6), Color(0xFF5A8C9A)],
        const [0.0, .4, 1.0],
        .4,
      ),
      BergenSea.rain => (
        const [Color(0xFF6F8790), Color(0xFF4E6871), Color(0xFF2E444C)],
        const [0.0, .4, 1.0],
        .45,
      ),
      BergenSea.evening => (
        const [Color(0xFF3D6B7A), Color(0xFF2C5563), Color(0xFF16303A)],
        const [0.0, .35, 1.0],
        .45,
      ),
    };
    final kaOp = switch (mode) {
      BergenSea.day => .2,
      BergenSea.rain => .12,
      BergenSea.evening => .18,
    };
    final ready = _hero != null && _ka != null;

    return Positioned(
      left: 0,
      right: 0,
      top: f.y(223),
      bottom: 0,
      child: IgnorePointer(
        child: ClipRect(
          child: LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth;
              final h = box.maxHeight;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // `<rect fill=base>` + `hav-dybde` flipped (`scale(1 -1)`),
                  // so the deep colour sits at the horizon.
                  Positioned.fill(child: ColoredBox(color: base)),
                  Positioned.fill(
                    child: Opacity(
                      opacity: depth.$3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: depth.$1,
                            stops: depth.$2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // The perspective box: `left:-40%;right:-40%;top:0;
                  // height:150%;transform-origin:50% 0;
                  // transform:perspective(560px) rotateX(-24deg)`.
                  if (ready)
                    Positioned(
                      left: -.4 * w,
                      top: 0,
                      width: 1.8 * w,
                      height: 1.5 * h,
                      child: Transform(
                        alignment: Alignment.topCenter,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, -1 / (560 * s))
                          ..rotateX(-24 * math.pi / 180),
                        child: OnbLoopClock(
                          builder: (context, t, _) => CustomPaint(
                            painter: _SjoLayersPainter(
                              t: t,
                              hero: _hero!,
                              ka: _ka!,
                              kaOp: kaOp,
                              s: s,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Surface haze: `height:110px; rgba(190,214,222,.32) →
                  // .12 at 45% → 0`.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: 110 * s,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: cssLinear(
                          180,
                          [
                            rgba(190, 214, 222, .32),
                            rgba(190, 214, 222, .12),
                            rgba(190, 214, 222, 0),
                          ],
                          const [0, .45, 1],
                        ),
                      ),
                    ),
                  ),
                  // Bottom vignette: `left:-20%;right:-20%;bottom:-10%;
                  // height:55%; radial 60% 70% at 50% 100%`.
                  Positioned(
                    left: -.2 * w,
                    right: -.2 * w,
                    bottom: -.1 * h,
                    height: .55 * h,
                    child: CustomPaint(
                      painter: _RadialPainter(
                        center: const Offset(.5, 1),
                        radii: const Offset(.6, .7),
                        colors: [rgba(3, 14, 20, .42), rgba(3, 14, 20, 0)],
                        stops: const [0, .75],
                      ),
                    ),
                  ),
                  // The houses' reflection: `height:60px;opacity:.28;
                  // scaleY(-1);filter:url(#hav-speil)` (displacement + blur
                  // 1.4 — the displacement is approximated by the blur).
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: 60 * s,
                    child: onbBlurred(
                      1.4 * s,
                      const CustomPaint(painter: BergenHouseReflectionPainter()),
                    ),
                  ),
                  // Top shade: `height:28px; rgba(8,24,32,.3) → 0`.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: 28 * s,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: cssLinear(180, [
                          rgba(8, 24, 32, .3),
                          rgba(8, 24, 32, 0),
                        ]),
                      ),
                    ),
                  ),
                  // Vignette: `radial 110% 90% at 50% 30%, transparent 50%
                  // → rgba(3,14,20,.5)`.
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RadialPainter(
                        center: const Offset(.5, .3),
                        radii: const Offset(1.1, .9),
                        colors: [rgba(3, 14, 20, 0), rgba(3, 14, 20, .5)],
                        stops: const [.5, 1],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// CSS `alternate` progress with `ease-in-out` per cycle; [delayMs] may be
/// negative (`animation-delay: -8s` starts eight seconds in).
double _alt(double t, double durMs, double delayMs, {bool reverse = false}) {
  final elapsed = t - delayMs;
  final cycle = (elapsed / durMs).floor();
  final p = (elapsed / durMs) - cycle;
  final forward = (cycle.isEven) != reverse;
  return Curves.easeInOut.transform(forward ? p : 1 - p);
}

/// The four tiled texture layers and the glint inside the perspective box.
class _SjoLayersPainter extends CustomPainter {
  const _SjoLayersPainter({
    required this.t,
    required this.hero,
    required this.ka,
    required this.kaOp,
    required this.s,
  });

  final double t;
  final ui.Image hero;
  final ui.Image ka;
  final double kaOp;
  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    // Every layer: `left:-30px;top:-14px;width:calc(100% + 60px);
    // height:calc(100% + 28px)`.
    final layer = Rect.fromLTWH(
      -30 * s,
      -14 * s,
      size.width + 60 * s,
      size.height + 28 * s,
    );
    double x(double dur, double delay, {bool reverse = false}) =>
        (-18 + 36 * _alt(t, dur, delay, reverse: reverse)) * s;
    double y(double dur, double delay, {bool reverse = false}) =>
        (-8 + 16 * _alt(t, dur, delay, reverse: reverse)) * s;

    // 1. caustics: sjoX 19s -8s · sjoY 13s -3s · opacity kaOp.
    _tile(
      canvas,
      layer,
      ka,
      dx: x(19000, -8000),
      dy: y(13000, -3000),
      tileH: 240 * s,
      opacity: kaOp,
    );
    // 2. hero: sjoX 15s · sjoY 9s -6s.
    _tile(
      canvas,
      layer,
      hero,
      dx: x(15000, 0),
      dy: y(9000, -6000),
      tileH: 240 * s,
      opacity: 1,
    );
    // 3. hero mirrored: sjoX 23s -17s alternate-reverse · sjoY 16s -11s
    //    alternate-reverse · opacity .42 · scaleX(-1).
    _tile(
      canvas,
      layer,
      hero,
      dx: x(23000, -17000, reverse: true),
      dy: y(16000, -11000, reverse: true),
      tileH: 240 * s,
      opacity: .42,
      flip: true,
    );
    // 4. hero, lower half only: sjoX 17s -5s · sjoY 11s -2s · opacity .55 ·
    //    mask transparent 35% → opaque 75% · tile 380px at `0 60%`.
    canvas.saveLayer(layer, Paint());
    _tile(
      canvas,
      layer,
      hero,
      dx: x(17000, -5000),
      dy: y(11000, -2000),
      tileH: 380 * s,
      originY: .6 * (layer.height - 380 * s),
      opacity: .55,
    );
    canvas.drawRect(
      layer,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.linear(
          layer.topLeft,
          layer.bottomLeft,
          const [Color(0x00000000), Color(0xFF000000)],
          const [.35, .75],
        ),
    );
    canvas.restore();
    // 5. glint: `left:-10%;right:-10%;top:-30%;bottom:-30%`, radial 42% 38%
    //    white .2 → 0 at 72%, sjoGlint 33s -12s alternate.
    final g = Rect.fromLTWH(
      -.1 * size.width,
      -.3 * size.height,
      1.2 * size.width,
      1.6 * size.height,
    );
    final p = _alt(t, 33000, -12000);
    final tx = onbKf(p, const [0, .5, 1], const [-.12, .06, .14], Curves.linear);
    final ty = onbKf(p, const [0, .5, 1], const [-.06, .04, -.02], Curves.linear);
    final sc = onbKf(p, const [0, .5, 1], const [1, 1.15, 1.05], Curves.linear);
    final op = onbKf(p, const [0, .5, 1], const [.55, 1, .6], Curves.linear);
    canvas.save();
    canvas.translate(g.center.dx + tx * g.width, g.center.dy + ty * g.height);
    canvas.scale(sc);
    canvas.translate(-g.center.dx, -g.center.dy);
    canvas.drawRect(
      g,
      Paint()
        ..shader = ui.Gradient.radial(
          g.center,
          g.width * .42,
          [
            Colors.white.withValues(alpha: .2 * op),
            Colors.white.withValues(alpha: 0),
          ],
          const [0, .72],
          TileMode.clamp,
          Matrix4.diagonal3Values(1, .38 * g.height / (.42 * g.width), 1)
              .storage,
          g.center,
        ),
    );
    canvas.restore();
  }

  void _tile(
    Canvas canvas,
    Rect layer,
    ui.Image img, {
    required double dx,
    required double dy,
    required double tileH,
    required double opacity,
    double originY = 0,
    bool flip = false,
  }) {
    final sx = layer.width / img.width;
    final sy = tileH / img.height;
    final m = Matrix4.identity()
      ..translate(
        flip ? layer.right + dx : layer.left + dx,
        layer.top + originY + dy,
      )
      ..scale(flip ? -sx : sx, sy);
    canvas.drawRect(
      layer,
      Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..shader = ImageShader(
          img,
          TileMode.repeated,
          TileMode.repeated,
          m.storage,
          filterQuality: FilterQuality.low,
        ),
    );
  }

  @override
  bool shouldRepaint(_SjoLayersPainter old) =>
      old.t != t || old.hero != hero || old.ka != ka || old.kaOp != kaOp;
}

/// CSS `radial-gradient(<rx>% <ry>% at <cx>% <cy>%, …)` in a box.
class _RadialPainter extends CustomPainter {
  const _RadialPainter({
    required this.center,
    required this.radii,
    required this.colors,
    required this.stops,
  });

  final Offset center;
  final Offset radii;
  final List<Color> colors;
  final List<double> stops;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(center.dx * size.width, center.dy * size.height);
    final rx = radii.dx * size.width;
    final ry = radii.dy * size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          rx,
          colors,
          stops,
          TileMode.clamp,
          Matrix4.diagonal3Values(1, ry / rx, 1).storage,
          c,
        ),
    );
  }

  @override
  bool shouldRepaint(_RadialPainter old) =>
      old.center != center || old.radii != radii || old.colors != colors;
}

/// The prototype's `sjoBake()` in Dart: the tiles drawn once to an image.
///
/// * `hero<Mode>`: a 390×240 tile of the `lf` (evening/rain) or `yf` (day)
///   line pattern — 7 px period, a light line (.9 px) over a dark one (1 px)
///   — pushed through the `k` filter (`feTurbulence` fractalNoise
///   `0.016 0.08`, two octaves, `feDisplacementMap scale=22`) or `kf` for
///   rain (`0.04 0.16`, scale 10), at .85 / .8 / .7, masked (`mu`) to fade
///   over the bottom 30 %.
/// * `kaHero`: the caustics — `feTurbulence` turbulence `0.018 0.03`, one
///   octave, kept where the noise passes `2.4·a − 1.05`, blurred 1.4, tinted
///   `(1, 1, .92)`, same mask.
///
/// The noise is value noise with the same frequencies and octaves; the
/// `seed`s differ from SVG's, so the wobble has the same character, not the
/// same pixels.
abstract final class FiskeSjoBake {
  static const double tileW = 390;
  static const double tileH = 240;

  static final Map<String, Future<ui.Image>> _cache = {};

  static Future<ui.Image> hero(BergenSea mode, double dpr) =>
      _cache.putIfAbsent('hero-$mode-$dpr', () => _bakeHero(mode, dpr));

  static Future<ui.Image> ka(double dpr) =>
      _cache.putIfAbsent('ka-$dpr', () => _bakeKa(dpr));

  static Future<ui.Image> _bakeHero(BergenSea mode, double dpr) {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.scale(dpr);
    final rain = mode == BergenSea.rain;
    final day = mode == BergenSea.day;
    final light = day
        ? Colors.white.withValues(alpha: .6)
        : Colors.white.withValues(alpha: .26);
    final dark = day
        ? const Color.fromRGBO(30, 79, 92, .12)
        : const Color.fromRGBO(8, 24, 32, .14);
    final opacity = day ? .8 : (rain ? .7 : .85);
    final fx = rain ? .04 : .016;
    final fy = rain ? .16 : .08;
    // `feDisplacementMap scale` is the full range; fractal noise sits near
    // its middle, so the typical shift is a third of it.
    final amp = (rain ? 10 : 22) / 2 * .35;

    c.saveLayer(
      const Rect.fromLTWH(0, 0, tileW, tileH),
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    final lp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .9
      ..color = light;
    final dp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = dark;
    for (var y = 0.0; y < tileH + 7; y += 7) {
      _line(c, y, fx, fy, amp, lp, 7);
      _line(c, y + .9, fx, fy, amp, dp, 19);
    }
    _mask(c);
    c.restore();
    return rec.endRecording().toImage((tileW * dpr).round(), (tileH * dpr).round());
  }

  static void _line(
    Canvas c,
    double y,
    double fx,
    double fy,
    double amp,
    Paint paint,
    int seed,
  ) {
    final path = Path();
    var first = true;
    for (var x = -40.0; x <= tileW + 40; x += 3) {
      final n = _fbm(x * fx, y * fy, seed, 2);
      final n2 = _fbm(x * fx, y * fy, seed + 101, 2);
      final px = x + amp * n2;
      final py = y + amp * n;
      if (first) {
        path.moveTo(px, py);
        first = false;
      } else {
        path.lineTo(px, py);
      }
    }
    c.drawPath(path, paint);
  }

  static Future<ui.Image> _bakeKa(double dpr) {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.scale(dpr);
    const rect = Rect.fromLTWH(0, 0, tileW, tileH);
    c.saveLayer(rect, Paint());
    c.saveLayer(rect, Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 1.4, sigmaY: 1.4));
    const step = 3.0;
    for (var y = 0.0; y < tileH; y += step) {
      for (var x = 0.0; x < tileW; x += step) {
        final a = (_fbm(x * .018, y * .03, 4, 1)).abs();
        final alpha = (2.4 * a - 1.05).clamp(0.0, 1.0);
        if (alpha <= 0) continue;
        c.drawRect(
          Rect.fromLTWH(x, y, step, step),
          Paint()..color = Color.fromRGBO(255, 255, 235, alpha),
        );
      }
    }
    c.restore();
    _mask(c);
    c.restore();
    return rec.endRecording().toImage((tileW * dpr).round(), (tileH * dpr).round());
  }

  /// `mask#mu`: opaque to 70 %, transparent at 100 %.
  static void _mask(Canvas c) {
    c.drawRect(
      const Rect.fromLTWH(-40, 0, tileW + 80, tileH),
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(0, tileH),
          const [Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
          const [0, .7, 1],
        ),
    );
  }

  // ── value noise ────────────────────────────────────────────────────────

  static double _hash(int x, int y, int seed) {
    var h = x * 374761393 + y * 668265263 + seed * 1274126177;
    h = (h ^ (h >> 13)) * 1274126177;
    h ^= h >> 16;
    return (h & 0xFFFF) / 65535.0;
  }

  static double _smooth(double t) => t * t * (3 - 2 * t);

  /// Value noise in [-1, 1] at lattice spacing 1.
  static double _noise(double x, double y, int seed) {
    final xi = x.floor();
    final yi = y.floor();
    final fx = _smooth(x - xi);
    final fy = _smooth(y - yi);
    final a = _hash(xi, yi, seed);
    final b = _hash(xi + 1, yi, seed);
    final c = _hash(xi, yi + 1, seed);
    final d = _hash(xi + 1, yi + 1, seed);
    final top = a + (b - a) * fx;
    final bottom = c + (d - c) * fx;
    return (top + (bottom - top) * fy) * 2 - 1;
  }

  /// `numOctaves` octaves at doubling frequency and halving weight.
  static double _fbm(double x, double y, int seed, int octaves) {
    var sum = 0.0;
    var norm = 0.0;
    var w = 1.0;
    var f = 1.0;
    for (var i = 0; i < octaves; i++) {
      sum += w * _noise(x * f, y * f, seed + i * 7);
      norm += w;
      w *= .5;
      f *= 2;
    }
    return sum / norm;
  }
}
