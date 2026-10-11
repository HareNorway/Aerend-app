import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/home/bergen/bergen_kit.dart' show BergenWeather;
import '../kit/br_pal.dart';
import '../kit/bergen_perf.dart';

/// Fløyen behind Ægil, live: the prototype's own WebGL scene
/// (`data-flgl="agent"`, `flGlInit` / `flGlTegn`), 390 × 252 design px.
///
/// As in the prototype, the heavy city (`shaders/aegil_floyen.frag`: the
/// ray-traced blocks, shadows, mountains) is drawn once per weather, at
/// twice the size, in 20 stripes (one per frame), into an image; each frame
/// (every 33 ms, at a device pixel ratio of at most 1.6) then reads it and
/// adds what moves (`shaders/aegil_floyen_liv.frag`: the water, the boats,
/// the fountain, the Fløibanen car, the rain). The page's layers over the
/// canvas — its `saturate(.92) contrast(.97) brightness(1.02)`, the two soft
/// blurs at the top, the haze, the warm light (soft-light), the shade
/// (multiply) and the vignette — are drawn into the same frame offscreen,
/// so the screen gets no extra blur layer.
///
/// Motion tiers (parity plan §3.1): `full` as the prototype; `lite` every
/// 66 ms at 55 % of the pixels; `still` shows [still] (the baked frame,
/// which is also there until the city is drawn and if a shader can't load).
/// «Roligere bevegelse» keeps the slow `rolig` clock.
class AegilFloyen extends StatefulWidget {
  const AegilFloyen({super.key, required this.kind, required this.still});

  final BergenWeather kind;
  final Widget still;

  @override
  State<AegilFloyen> createState() => _AegilFloyenState();
}

class _AegilFloyenState extends State<AegilFloyen> with SingleTickerProviderStateMixin {
  static const double _w = 390, _h = 252;
  static const int _stripes = 20;
  static Future<List<ui.FragmentProgram>>? _programs;

  /// The last finished city (one weather, one size), kept across visits.
  static String? _cacheSig;
  static ui.Image? _cache;

  ui.FragmentShader? _by, _liv;
  late final Ticker _ticker;
  Duration _sist = Duration.zero;
  Duration _prev = Duration.zero;
  double _t = 12;
  double _dpr = 1.6;
  bool _calm = false;
  Duration? _step = const Duration(milliseconds: 33);
  double _budgetK = 1;

  // The city being drawn (stripe by stripe) and the one in use.
  String? _sig;
  ui.Image? _acc;
  int _stripe = 0;
  String? _statSig;
  ui.Image? _stat;
  ui.Image? _frame;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _programs ??= Future.wait([ui.FragmentProgram.fromAsset('shaders/aegil_floyen.frag'), ui.FragmentProgram.fromAsset('shaders/aegil_floyen_liv.frag')]);
    _programs!
        .then((p) {
          if (!mounted) return;
          _by = p[0].fragmentShader();
          _liv = p[1].fragmentShader();
          _sync();
        })
        .catchError((Object _) {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dpr = math.max(1, math.min(1.6, MediaQuery.devicePixelRatioOf(context)));
    _calm = BergenPerf.calmOf(context);
    _step = BergenPerf.shaderStep(context, fullMs: 33, liteMs: 66) ?? (_calm ? const Duration(milliseconds: 33) : null);
    _budgetK = BergenPerf.shaderBudget(context, 1);
    _sync();
  }

  @override
  void didUpdateWidget(AegilFloyen old) {
    super.didUpdateWidget(old);
    if (old.kind != widget.kind) _sync();
  }

  void _sync() {
    if (_by == null) return;
    final run = _step != null;
    if (run && !_ticker.isActive) _ticker.start();
    if (!run && _ticker.isActive) _ticker.stop();
    if (!run) {
      // The heat / battery `still` tier: the baked frame.
      final old = _frame;
      if (old != null) setState(() => _frame = null);
      old?.dispose();
    }
  }

  double get _d => _dpr * math.sqrt(_budgetK);

  void _tick(Duration e) {
    final dt = ((e - _prev).inMicroseconds / 1e6).clamp(0.0, .1);
    _prev = e;
    _t += dt * (_calm ? .15 : 1);
    final step = _step;
    if (step == null || e - _sist < step) return;
    _sist = e;
    _city();
    if (_stat != null) _render();
  }

  /// `flGlTegn`'s first pass: one stripe of the city per frame.
  void _city() {
    final sh = _by!;
    final d = _d, pw = (_w * d).round(), ph = (_h * d).round(), w2 = pw * 2, h2 = ph * 2;
    final p = BrPal.of(widget.kind);
    final sig = '${widget.kind.name}|${w2}x$h2';
    if (_statSig == sig) return;
    if (_cacheSig == sig && _cache != null) {
      _useStat(sig, _cache!.clone());
      return;
    }
    if (_sig != sig) {
      _sig = sig;
      _stripe = 0;
      _acc?.dispose();
      _acc = null;
    }
    var i = 0;
    void f(double v) => sh.setFloat(i++, v);
    f(_w);
    f(_h);
    f(w2 / _w);
    f(0); // uT
    f(p.night);
    f(p.sun);
    f(p.sunset);
    f(p.rain);
    f(p.snow);
    f(p.wet);
    f(p.rain > 0 ? 34 : (p.snow > 0 ? 30 : -20)); // uCY
    f(_vis(p));
    for (final c in [p.skT, p.skM, p.skB]) {
      c.forEach(f);
    }
    final y0 = (h2 * _stripe / _stripes).floorToDouble(), y1 = (h2 * (_stripe + 1) / _stripes).floorToDouble();
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final all = Rect.fromLTWH(0, 0, w2.toDouble(), h2.toDouble());
    if (_acc != null) c.drawImage(_acc!, Offset.zero, Paint()..blendMode = BlendMode.src);
    // `src`: the alpha is the material mask the second pass reads, kept as written.
    c.drawRect(
      Rect.fromLTRB(0, y0, all.right, y1),
      Paint()
        ..shader = sh
        ..blendMode = BlendMode.src,
    );
    final img = rec.endRecording().toImageSync(w2, h2);
    _acc?.dispose();
    _acc = img;
    if (++_stripe == _stripes) {
      _cache?.dispose();
      _cacheSig = sig;
      _cache = img.clone();
      _useStat(sig, img);
      _acc = null;
      _sig = null;
    }
  }

  void _useStat(String sig, ui.Image img) {
    _stat?.dispose();
    _stat = img;
    _statSig = sig;
  }

  static double _vis(BrPal p) => p.rain > 0 ? 4800 : (p.snow > 0 ? 4200 : (p.sunset > 0 ? 9000 : (p.sun > .9 ? 16000 : (p.night > .7 ? 6000 : 7000))));

  /// `flGlTegn`'s second pass, then the page's layers over the canvas.
  void _render() {
    final sh = _liv!, stat = _stat!;
    final d = _d, pw = (_w * d).round(), ph = (_h * d).round();
    final p = BrPal.of(widget.kind);
    final ln = p.night > .7 ? .24 : (p.rain > 0 ? .7 : (p.snow > 0 ? .8 : .95)), lys = .2 + .8 * p.night;
    final ss = p.sunset > 0;
    var i = 0;
    void f(double v) => sh.setFloat(i++, v);
    f(_w);
    f(_h);
    f(pw / _w);
    f(_t % 3600);
    f(p.night);
    f(p.rain);
    f(p.snow);
    f(_vis(p));
    f(ln * (ss ? 1 : .97));
    f(ln * (ss ? .84 : .98));
    f(ln * (ss ? .72 : 1));
    f(lys);
    f(.74 * lys);
    f(.42 * lys);
    sh.setImageSampler(0, stat);
    final full = Rect.fromLTWH(0, 0, pw.toDouble(), ph.toDouble());
    // The canvas, with its CSS filter.
    var rec = ui.PictureRecorder();
    Canvas(rec).drawRect(
      full,
      Paint()
        ..shader = sh
        ..colorFilter = _canvasFilter,
    );
    final canvas = rec.endRecording().toImageSync(pw, ph);
    // The layers over it, in design px.
    rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.drawImage(canvas, Offset.zero, Paint());
    c.scale(d);
    const all = Rect.fromLTWH(0, 0, _w, _h);
    void blur(double h, double sigma, double from, ColorFilter? cf) {
      final r = Rect.fromLTWH(0, 0, _w, h);
      c.saveLayer(r, Paint());
      c.save();
      c.scale(1 / d);
      c.drawImage(
        canvas,
        Offset.zero,
        Paint()
          ..imageFilter = ui.ImageFilter.blur(sigmaX: sigma * d, sigmaY: sigma * d, tileMode: TileMode.clamp)
          ..colorFilter = cf,
      );
      c.restore();
      c.drawRect(
        r,
        Paint()
          ..shader = ui.Gradient.linear(Offset(0, from), Offset(0, h), const [Color(0xFF000000), Color(0x00000000)])
          ..blendMode = BlendMode.dstIn,
      );
      c.restore();
    }

    // `backdrop-filter: blur(.9px)`, masked 40 → 150 px; then `blur(1.8px)
    // saturate(.8)`, masked 30 → 96 px, over the first (≈ one blur of 2 px).
    blur(150, .9, 40, null);
    blur(96, 2.0, 30, ColorFilter.matrix(_saturate80));
    for (final (bg, mode) in _lag) {
      c.drawRect(
        all,
        Paint()
          ..shader = bg.shader(all)
          ..blendMode = mode,
      );
    }
    final img = rec.endRecording().toImageSync(pw, ph);
    canvas.dispose();
    final old = _frame;
    setState(() => _frame = img);
    old?.dispose();
  }

  static final List<(CssBg, BlendMode)> _lag = [
    (
      const CssLinear(180, [Color.fromRGBO(208, 222, 230, .3), Color.fromRGBO(204, 218, 226, .18), Color.fromRGBO(198, 212, 220, .08), Color.fromRGBO(198, 212, 220, 0)], [0, .22, .42, .62]),
      BlendMode.srcOver,
    ),
    (const CssRadial([Color.fromRGBO(255, 236, 206, .34), Color.fromRGBO(255, 236, 206, 0)], stops: [0, .6], rx: .9, ry: .7, cx: .18, cy: .08), BlendMode.softLight),
    (const CssLinear(180, [Color.fromRGBO(0, 0, 0, 0), Color.fromRGBO(16, 34, 40, .22)], [.55, 1]), BlendMode.multiply),
    (const CssRadial([Color.fromRGBO(0, 0, 0, 0), Color.fromRGBO(8, 20, 26, .32)], stops: [.62, 1], rx: 1.25, ry: .95, cx: .5, cy: .38), BlendMode.srcOver),
  ];

  /// CSS `saturate(.92) contrast(.97) brightness(1.02)` (applied in that order).
  static final ColorFilter _canvasFilter = ColorFilter.matrix(_cssFilter(.92, .97, 1.02));
  static final List<double> _saturate80 = _cssFilter(.8, 1, 1);

  static List<double> _cssFilter(double s, double c, double b) {
    final m = [.213 + .787 * s, .715 - .715 * s, .072 - .072 * s, .213 - .213 * s, .715 + .285 * s, .072 - .072 * s, .213 - .213 * s, .715 - .715 * s, .072 + .928 * s];
    final k = b * (.5 - .5 * c) * 255;
    return [
      for (var r = 0; r < 3; r++) ...[b * c * m[r * 3], b * c * m[r * 3 + 1], b * c * m[r * 3 + 2], 0, k],
      0,
      0,
      0,
      1,
      0,
    ];
  }

  @override
  void dispose() {
    _ticker.dispose();
    _acc?.dispose();
    _stat?.dispose();
    _frame?.dispose();
    _by?.dispose();
    _liv?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final img = _frame;
    return SizedBox(
      width: _w,
      height: _h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.still,
          if (img != null)
            RepaintBoundary(
              child: RawImage(key: const Key('aegil-floyen-live'), image: img, width: _w, height: _h, fit: BoxFit.fill, filterQuality: FilterQuality.medium),
            ),
        ],
      ),
    );
  }
}
