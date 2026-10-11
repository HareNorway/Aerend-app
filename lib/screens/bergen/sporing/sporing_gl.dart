import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../common/home/bergen/bergen_kit.dart' show BergenWeather, BergenWeatherLook;
import '../hjem/hjem_harness.dart';
import '../hjem/hjem_hero.dart' show HjemVaer;
import '../kit/bergen_perf.dart';

/// The weather the Sporing scenes are drawn in: the harness `vaer` in debug
/// builds (so the scenes can be compared with the prototype's default rain),
/// else Bergen's look for the hour, like Meg and Ægil.
BergenWeather spVaer() {
  if (kDebugMode && HjemHarness.vaer != null) {
    return switch (HjemHarness.vaer!) {
      HjemVaer.regn => BergenWeather.regn,
      HjemVaer.sol => BergenWeather.sol,
      HjemVaer.solnedgang => BergenWeather.solnedgang,
      HjemVaer.natt => BergenWeather.natt,
    };
  }
  return BergenWeatherLook.forHour(DateTime.now().hour).kind;
}

/// `spPal()` in the prototype: night, sunset, rain, wet and the two sky
/// colours for one weather. The prototype's sea mode (`sjoM`) is Dag in sun
/// and Kveld otherwise (its default `sjoModus`), so rain is the evening rain
/// the manager sees.
class SpPal {
  const SpPal._(this.night, this.sunset, this.rain, this.wet, this.skT, this.skH);

  final double night, sunset, rain, wet;
  final List<double> skT, skH;
  double get snow => 0;

  factory SpPal.of(BergenWeather v) {
    var night = v == BergenWeather.sol ? .14 : .74;
    double sunset = 0;
    if (v == BergenWeather.natt) night = 1;
    if (v == BergenWeather.solnedgang) {
      sunset = 1;
      night = math.max(night, .5);
    }
    final double rain = v == BergenWeather.regn ? 1 : 0;
    final wet = rain > 0 ? 1.0 : .55;
    List<double> mx(List<double> a, List<double> b, double t) => [for (var i = 0; i < a.length; i++) a[i] + (b[i] - a[i]) * t];
    var skT = mx(const [.56, .70, .80], const [.09, .17, .23], night);
    var skH = mx(const [.82, .88, .90], const [.33, .43, .48], night);
    if (sunset > 0) skH = mx(skH, const [.95, .66, .48], .55);
    if (rain > 0) {
      skT = mx(skT, [for (final c in const [.5, .55, .6]) c * (1 - night * .65)], .35);
      skH = mx(skH, [for (final c in const [.72, .76, .78]) c * (1 - night * .5)], .3);
    }
    return SpPal._(night, sunset, rain, wet, skT, skH);
  }
}

/// One texture of a scene: an image provider decoded at the size the
/// prototype samples it at (its mip level), or nothing (a store without a
/// logo) — then the slot gets a clear pixel and the scene's «ok» flag is 0.
class SpGlTex {
  const SpGlTex(this.provider);

  /// An asset decoded at exactly [w] × [h] (the prototype stretches its
  /// sprites into a 512² canvas; ours are square too).
  SpGlTex.asset(String path, int w, int h) : provider = ResizeImage(AssetImage(path), width: w, height: h, policy: ResizeImagePolicy.exact);

  /// A network image (the store's logo) decoded at [size]².
  SpGlTex.net(String? url, int size)
    : provider = url == null || url.isEmpty ? null : ResizeImage(NetworkImage(url), width: size, height: size, policy: ResizeImagePolicy.exact);

  final ImageProvider? provider;
}

/// Writes a scene's uniforms after `uRes`, `uDpr` and `uT`: [f] sets the next
/// float, [t] is the scene clock in seconds, [age] the real seconds since the
/// scene appeared (the clock its CSS overlays animate on), [ok] says whether
/// texture i has loaded.
typedef SpGlUniforms = void Function(void Function(double) f, double t, double age, bool Function(int i) ok);

/// Hosts one of the prototype's Sporing WebGL scenes (`data-spgl`), ported as
/// a fragment shader (`shaders/sp_*.frag`) and rendered offscreen as the
/// prototype's canvas is (`spGlTegn`): at most 300 000 pixels and a device
/// pixel ratio of 2 (the prototype's `_sgBud`), every frame up to 60 a second.
///
/// Motion tiers (parity plan §3.1): `full` as the prototype; `lite` 30 fps at
/// 55 % of the pixels; `still` holds one frame — unless the user asked for
/// calm motion, which runs the scene at the prototype's slow `rolig` (15 %).
/// [still] (the baked frame, where there is one) shows until the first frame
/// and stays if the shader can't load.
class SpGl extends StatefulWidget {
  const SpGl({
    super.key,
    required this.asset,
    required this.w,
    required this.h,
    required this.uniforms,
    this.tex = const [],
    this.still,
    this.t0 = 8,
    this.fullMs = 1000 / 60,
    this.liteMs = 1000 / 30,
    this.stillTier = false,
    this.onFrame,
    this.waitTex = false,
  });

  final String asset;
  final double w, h;
  final SpGlUniforms uniforms;
  final List<SpGlTex> tex;
  final Widget? still;

  /// Where the scene clock starts (s); the prototype's clock has run since
  /// the page loaded, so the boats and cars are already under way.
  final double t0;

  /// The frame interval in the `full` / `lite` tiers (ms). The Sporing scenes
  /// draw every frame; Bryggen every 31 ms (`brGlTegn`).
  final double fullMs, liteMs;

  /// In the heat / battery `still` tier, show [still] instead of holding a
  /// rendered frame (parity plan Step 11: the baked still is the `still` tier).
  final bool stillTier;

  /// Each new frame (owned by this widget: clone it to keep it).
  final void Function(ui.Image frame)? onFrame;

  /// Draw nothing until every texture has loaded (a scene that is all
  /// texture would otherwise flash empty over [still]).
  final bool waitTex;

  @override
  State<SpGl> createState() => _SpGlState();
}

class _SpGlState extends State<SpGl> with SingleTickerProviderStateMixin {
  static final Map<String, Future<ui.FragmentProgram>> _programs = {};
  static ui.Image? _clear;

  ui.FragmentShader? _shader;
  ui.Image? _frame;
  late final Ticker _ticker;
  late List<ui.Image?> _img;
  final List<ImageStream> _streams = [];
  final List<ImageStreamListener> _listeners = [];
  // Seconds since the scene appeared, on the ticker's clock (so `timeDilation`
  // slows it with the overlays' LfOnce animations); wall time until the
  // ticker runs.
  final Stopwatch _sw = Stopwatch()..start();
  double? _age;
  Duration _sist = Duration.zero;
  Duration _prev = Duration.zero;
  late double _t = widget.t0;
  double _dpr = 2;
  bool _calm = false;
  Duration? _step = const Duration(microseconds: 16667);
  double _budget = 300000;

  @override
  void initState() {
    super.initState();
    _img = List<ui.Image?>.filled(widget.tex.length, null);
    _ticker = createTicker(_tick);
    _programs[widget.asset] ??= ui.FragmentProgram.fromAsset(widget.asset);
    _programs[widget.asset]!.then((pr) {
      if (!mounted) return;
      _shader = pr.fragmentShader();
      if (!(widget.stillTier && _step == null)) _render();
      _sync();
    }).catchError((Object _) {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dpr = math.min(2, MediaQuery.devicePixelRatioOf(context));
    _calm = BergenPerf.calmOf(context);
    _step = BergenPerf.shaderStep(context, fullMs: widget.fullMs, liteMs: widget.liteMs) ?? (_calm ? const Duration(microseconds: 33333) : null);
    _budget = BergenPerf.shaderBudget(context, 300000);
    if (_streams.isEmpty) _load();
    _sync();
  }

  @override
  void didUpdateWidget(SpGl old) {
    super.didUpdateWidget(old);
    // The store's logo can arrive after the first build.
    final ny = [for (final x in widget.tex) x.provider];
    final gml = [for (final x in old.tex) x.provider];
    if (!listEquals(ny, gml)) {
      _unload();
      _img = List<ui.Image?>.filled(widget.tex.length, null);
      _load();
    }
    // A held frame follows new data (weather, the store's logo).
    if (!_ticker.isActive && !(widget.stillTier && _step == null)) SchedulerBinding.instance.addPostFrameCallback((_) => _render());
  }

  void _sync() {
    if (_shader == null) return;
    final run = _step != null;
    if (run && !_ticker.isActive) _ticker.start();
    if (!run && _ticker.isActive) _ticker.stop();
    if (!run && widget.stillTier && widget.still != null) {
      final old = _frame;
      if (old != null) setState(() => _frame = null);
      old?.dispose();
      return;
    }
    if (!run) _render();
  }

  void _load() {
    final cfg = createLocalImageConfiguration(context);
    for (var i = 0; i < widget.tex.length; i++) {
      final p = widget.tex[i].provider;
      if (p == null) continue;
      final s = p.resolve(cfg);
      final l = ImageStreamListener((info, _) {
        if (!mounted) return;
        if (i >= _img.length) return;
        _img[i]?.dispose();
        _img[i] = info.image.clone();
        if (!_ticker.isActive) _render();
      }, onError: (Object _, StackTrace? _) {});
      s.addListener(l);
      _streams.add(s);
      _listeners.add(l);
    }
  }

  void _unload() {
    for (var k = 0; k < _streams.length; k++) {
      _streams[k].removeListener(_listeners[k]);
    }
    _streams.clear();
    _listeners.clear();
    for (final im in _img) {
      im?.dispose();
    }
  }

  void _tick(Duration e) {
    final dt = ((e - _prev).inMicroseconds / 1e6).clamp(0.0, .1);
    _age = (_age ?? _sw.elapsedMicroseconds / 1e6) + dt;
    _t += dt * (_calm ? .15 : 1);
    _prev = e;
    final step = _step;
    if (step == null || e - _sist < step) return;
    _sist = e;
    _render();
  }

  static ui.Image _blank() {
    if (_clear != null) return _clear!;
    final rec = ui.PictureRecorder();
    Canvas(rec).drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint()..color = const Color(0x00000000));
    return _clear = rec.endRecording().toImageSync(1, 1);
  }

  void _render() {
    final sh = _shader;
    if (sh == null || !mounted) return;
    if (widget.waitTex && _img.any((x) => x == null)) return;
    final w = widget.w, h = widget.h;
    final dpr = math.max(.5, math.min(_dpr, math.sqrt(_budget / (w * h))));
    final pw = (w * dpr).round(), ph = (h * dpr).round();
    var i = 0;
    void f(double v) => sh.setFloat(i++, v);
    f(w);
    f(h);
    f(pw / w);
    f(_t % 3600);
    widget.uniforms(f, _t, _age ?? _sw.elapsedMicroseconds / 1e6, (k) => k < _img.length && _img[k] != null);
    for (var k = 0; k < _img.length; k++) {
      sh.setImageSampler(k, _img[k] ?? _blank());
    }
    final rec = ui.PictureRecorder();
    Canvas(rec).drawRect(Rect.fromLTWH(0, 0, pw.toDouble(), ph.toDouble()), Paint()..shader = sh);
    final img = rec.endRecording().toImageSync(pw, ph);
    final old = _frame;
    setState(() => _frame = img);
    old?.dispose();
    widget.onFrame?.call(img);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _unload();
    _frame?.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final img = _frame;
    return SizedBox(
      width: widget.w,
      height: widget.h,
      child: img == null
          ? widget.still
          : RepaintBoundary(
              child: RawImage(image: img, width: widget.w, height: widget.h, fit: BoxFit.fill, filterQuality: FilterQuality.medium),
            ),
    );
  }
}
