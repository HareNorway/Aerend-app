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
import '../kit/maler_vert.dart';

/// The weather the Sporing scenes are drawn in: the harness `vaer` in debug
/// builds (so the scenes can be compared with the prototype's default rain),
/// else Bergen's look for the hour, like Meg and Ægil.
BergenWeather spVaer() {
  if (!kReleaseMode && HjemHarness.vaer != null) {
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

/// Heat plan Step 6 (with [BergenPerf.malerVertPaa]): a scene split into its
/// static part, baked once per key into [malerNivaaer] textures (8-bit
/// digits of the same floats, one bake pass per step), and a live pass
/// ([liv]) that reads them back and adds what moves with the same math.
/// Until the bake is done, and with the switch off, the frame comes from
/// [SpGl.asset] as before.
class SpGlDel {
  const SpGlDel({required this.liv, required this.bake, required this.noekkel, required this.livU, required this.bakeU});

  /// The live and the bake shader.
  final String liv, bake;

  /// What the bake depends on besides its size, its floats and the textures.
  final String noekkel;

  /// The live shader's floats after `uRes`, `uDpr`, `uT`, picked from [u]
  /// (the scene's own floats, as [SpGl.uniforms] wrote them); the host adds
  /// the bake textures' size (`uBSz`) after them.
  final void Function(List<double> u, void Function(double) f) livU;

  /// The bake shader's floats after `uRes`, `uDpr`; the host adds the digit.
  final void Function(List<double> u, void Function(double) f) bakeU;
}

/// Heat plan Step 5: a scene split into a static half ([stat]), baked once
/// per set of uniforms and size into textures on the live frame's own pixel
/// grid ([SpGlBake]), and a live half ([liv]) that reads them and computes
/// only what moves. Until the bake is done, and while [paa] says no, the
/// scene's own shader draws every step exactly as without a split.
class SpGlDeling {
  const SpGlDeling({required this.liv, required this.stat, required this.samplere, required this.paa});

  /// The live shader: the scene shader's float uniforms in the same order,
  /// then one sampler per entry of [samplere].
  final String liv;

  /// The bake shader: the scene shader's float uniforms (with `uT` 0), then
  /// the slot to write.
  final String stat;

  /// The baked slot each sampler of [liv] reads (slots 0 … max).
  final List<int> samplere;

  /// The runtime switch (read on every step).
  final bool Function() paa;

  /// How many slots are baked.
  int get lag => samplere.reduce(math.max) + 1;
}

/// The baked slots of one [SpGlDeling] for one set of bake uniforms and one
/// size ([nokkel]), drawn [striper] stripes per step (so the bake never costs
/// a whole frame at once) into images of exactly the live frame's size.
/// Finished bakes are kept in a small cache across scenes; every holder owns
/// its own clones, so evicting or disposing one never pulls an image from
/// under a shader that still reads it.
class SpGlBake {
  SpGlBake(this.nokkel, this.lag, this.pw, this.ph);

  final String nokkel;
  final int lag, pw, ph;

  /// Stripes per slot (one per step).
  static int striper = 4;

  /// Finished bakes kept (Hjem and Fjordfiske / Automat).
  static int cacheMaks = 2;
  static final Map<String, SpGlBake> _cache = {};

  /// Bakes finished so far (tests, harness logs).
  static int bakt = 0;

  final List<ui.Image> _ferdige = [];
  ui.Image? _acc;
  int _stripe = 0;
  final Stopwatch _sw = Stopwatch();

  bool get ferdig => _ferdige.length == lag;

  /// The finished slots, in slot order.
  List<ui.Image> get bilder => _ferdige;

  /// The bake's identity: the bake shader, the image size and every bake
  /// uniform (size, pixel ratio, palette, form) — any change bakes anew.
  static String nokkelFor(String stat, int pw, int ph, List<double> floats) => '$stat|${pw}x$ph|${floats.join(',')}';

  /// A finished bake for [nokkel] from the cache (own clones), or null.
  static SpGlBake? hent(String nokkel) {
    final c = _cache.remove(nokkel);
    if (c == null) return null;
    _cache[nokkel] = c; // most recently used last
    return SpGlBake(c.nokkel, c.lag, c.pw, c.ph).._ferdige.addAll([for (final im in c._ferdige) im.clone()]);
  }

  /// Keeps a clone of finished [b]; the least recently used beyond
  /// [cacheMaks] is disposed.
  static void legg(SpGlBake b) {
    assert(b.ferdig);
    _cache.remove(b.nokkel)?.dispose();
    _cache[b.nokkel] = SpGlBake(b.nokkel, b.lag, b.pw, b.ph).._ferdige.addAll([for (final im in b._ferdige) im.clone()]);
    while (_cache.length > cacheMaks) {
      final eldst = _cache.keys.first;
      _cache.remove(eldst)!.dispose();
    }
  }

  /// The keys in the cache, least recently used first (tests).
  @visibleForTesting
  static List<String> get cacheNokler => _cache.keys.toList();

  /// Empties the cache (tests).
  @visibleForTesting
  static void tomCache() {
    for (final b in _cache.values) {
      b.dispose();
    }
    _cache.clear();
  }

  /// Draws the next stripe of the next slot with [stat]: [floats] are its
  /// float uniforms before the slot. Returns true when the last slot is done.
  bool steg(ui.FragmentShader stat, List<double> floats) {
    if (ferdig) return true;
    _sw.start();
    final slot = _ferdige.length;
    for (var k = 0; k < floats.length; k++) {
      stat.setFloat(k, floats[k]);
    }
    stat.setFloat(floats.length, slot.toDouble());
    final y0 = (ph * _stripe / striper).floorToDouble(), y1 = (ph * (_stripe + 1) / striper).floorToDouble();
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    // `src`, alpha 1: the bytes land exactly as the shader wrote them.
    if (_acc != null) c.drawImage(_acc!, Offset.zero, Paint()..blendMode = BlendMode.src);
    c.drawRect(
      Rect.fromLTRB(0, y0, pw.toDouble(), y1),
      Paint()
        ..shader = stat
        ..blendMode = BlendMode.src,
    );
    final img = rec.endRecording().toImageSync(pw, ph);
    _acc?.dispose();
    _acc = img;
    if (++_stripe >= striper) {
      _ferdige.add(img);
      _acc = null;
      _stripe = 0;
    }
    _sw.stop();
    if (ferdig) {
      bakt++;
      if (!kReleaseMode) debugPrint('PERF_DELING bakt $lag lag ${pw}x$ph (${_sw.elapsedMilliseconds} ms CPU) ${nokkel.split('|').first}');
    }
    return ferdig;
  }

  void dispose() {
    for (final im in _ferdige) {
      im.dispose();
    }
    _ferdige.clear();
    _acc?.dispose();
    _acc = null;
  }
}

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
    this.del,
    this.deling,
    this.egenRamme = false,
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

  /// Heat plan Step 6: the scene's static/live split, if it has one.
  final SpGlDel? del;

  /// Heat plan Step 5: the scene's static / dynamic split (no textures of
  /// its own then); null = [asset] every step.
  final SpGlDeling? deling;

  /// Android only: never renders in the same frame as another [egenRamme]
  /// scene. On Impeller/Vulkan two such scenes rendered in one frame corrupt
  /// one of the two pictures (Søk: the sign went blank or the stone wall black,
  /// alternating — the «BERGEN?» flicker). The later one renders on the next
  /// vsync with the same scene time, so the same picture, one frame later; its
  /// cadence (30 ms steps) is unchanged. iOS draws as before.
  final bool egenRamme;

  @override
  State<SpGl> createState() => _SpGlState();
}

class _SpGlState extends State<SpGl> with SingleTickerProviderStateMixin {
  static final Map<String, Future<ui.FragmentProgram>> _programs = {};
  static ui.Image? _clear;

  ui.FragmentShader? _shader;
  // Heat plan Step 6: the newest frame; with [BergenPerf.malerVertPaa] a new
  // one only repaints [MalerVert] (no setState per step).
  final MalerRamme _ramme = MalerRamme();
  bool _vert = false;
  // The split ([SpGl.del]): its shaders, the key of the bake and its digits.
  ui.FragmentShader? _liv, _bake;
  String? _delNoekkel;
  final List<ui.Image> _delBilder = [];
  // Bumped whenever a texture changes (part of the bake key).
  int _texGen = 0;
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

  // Perf plan: no frames while the scene is off the screen; its clock
  // carries on (see PerfHvile).
  late final PerfHvile _hvile = PerfHvile(context, _ticker, onVaakn: (s) {
    _t += s * (_calm ? .15 : 1);
    _prev = Duration.zero;
    _sist = Duration.zero;
  });

  // Heat plan Step 4: no frames between the scene's own steps.
  late final PerfStegRammer _rammer;

  // Heat plan Step 5: the split's two shaders (loaded the first time the
  // switch is on) and this scene's bake (in progress, or finished: own clones).
  // (Named apart from Step 6's [SpGl.del] fields above: the two splits
  // coexist, Bryggen on this one, SceneGl berg on that one.)
  ui.FragmentShader? _dlLiv, _dlStat;
  bool _dlLastes = false;
  SpGlBake? _dlBake;
  List<double>? _dlFloats;

  @override
  void initState() {
    super.initState();
    assert(widget.deling == null || widget.tex.isEmpty, 'a split scene has no textures of its own');
    assert(widget.deling == null || widget.del == null, 'one split per scene');
    _img = List<ui.Image?>.filled(widget.tex.length, null);
    _ticker = createTicker(_tick);
    _rammer = PerfStegRammer(_ticker, tickerModus: () => TickerMode.getNotifier(context));
    _programs[widget.asset] ??= ui.FragmentProgram.fromAsset(widget.asset);
    _programs[widget.asset]!.then((pr) {
      if (!mounted) return;
      _shader = pr.fragmentShader();
      if (!(widget.stillTier && _step == null)) _render();
      _sync();
    }).catchError((Object _) {});
    final del = widget.del;
    if (del != null) {
      _programs[del.liv] ??= ui.FragmentProgram.fromAsset(del.liv);
      _programs[del.bake] ??= ui.FragmentProgram.fromAsset(del.bake);
      Future.wait([_programs[del.liv]!, _programs[del.bake]!]).then((p) {
        if (!mounted) return;
        _liv = p[0].fragmentShader();
        _bake = p[1].fragmentShader();
      }).catchError((Object _) {});
    }
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
    if (!_ticker.isActive && !_hvile.hviler && !(widget.stillTier && _step == null)) SchedulerBinding.instance.addPostFrameCallback((_) => _render());
  }

  void _sync() {
    if (_shader == null) return;
    final run = _step != null;
    if (!run) _hvile.vaakn(start: false);
    if (run && !_ticker.isActive && !_hvile.hviler) _ticker.start();
    if (!run && _ticker.isActive) {
      _rammer.vekk();
      _ticker.stop();
    }
    if (!run && widget.stillTier && widget.still != null) {
      if (_ramme.bilde != null) setState(() => _ramme.sett(null));
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
        _texGen++;
        if (!_ticker.isActive && !_hvile.hviler) _render();
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
    _texGen++;
  }

  void _tick(Duration e) {
    _rammer.tikk(e);
    if (_hvile.tikk(n: _rammer.n)) return;
    final dt = _rammer.dt(e, _prev, .1);
    _age = (_age ?? _sw.elapsedMicroseconds / 1e6) + dt;
    _t += dt * (_calm ? .15 : 1);
    if (BergenPerf.frysMs != null) {
      _t = _age = BergenPerf.frysMs! / 1000;
    }
    _prev = e;
    final step = _step;
    // Heat ladder / idle: on the takt's frames ([PerfTakt.steg]); else as
    // before, a render once [step] has passed.
    final sist = step == null ? null : (PerfTakt.paa ? PerfTakt.steg(e, _sist, step) : (e - _sist < step ? null : e));
    if (sist == null) {
      _rammer.etter(e, _sist, step);
      return;
    }
    _sist = sist;
    _rammer.etter(e, _sist, step);
    if ((BergenPerf.shaderFrys || BergenPerf.shaderFrysKun == 'spgl') && _frys++ > 8) return;
    if (widget.egenRamme && defaultTargetPlatform == TargetPlatform.android) {
      _egenRender();
      return;
    }
    _render();
  }

  // [SpGl.egenRamme]: render now unless another such scene already rendered
  // in this frame; then try again on the next vsync.
  void _egenRender() {
    if (!mounted) return;
    final ramme = SchedulerBinding.instance.currentFrameTimeStamp;
    if (_egenRamme == ramme) {
      SchedulerBinding.instance.scheduleFrameCallback((_) => _egenRender());
      SchedulerBinding.instance.scheduleFrame();
      return;
    }
    _egenRamme = ramme;
    _render();
  }

  // [SpGl.egenRamme]: the frame in which such a scene last rendered.
  static Duration? _egenRamme;

  int _frys = 0;

  static ui.Image _blank() {
    if (_clear != null) return _clear!;
    final rec = ui.PictureRecorder();
    Canvas(rec).drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint()..color = const Color(0x00000000));
    return _clear = rec.endRecording().toImageSync(1, 1);
  }

  /// Heat plan Step 5: the live half when the split is on and its bake for
  /// this exact size and these uniforms is done; else null (the scene's own
  /// shader draws, as without a split) after one more bake stripe.
  ui.FragmentShader? _deling(int pw, int ph) {
    final d = widget.deling;
    if (d == null || !d.paa()) return null;
    if (_dlLiv == null || _dlStat == null) {
      if (!_dlLastes) {
        _dlLastes = true;
        final pl = _programs[d.liv] ??= ui.FragmentProgram.fromAsset(d.liv);
        final ps = _programs[d.stat] ??= ui.FragmentProgram.fromAsset(d.stat);
        Future.wait([pl, ps]).then((p) {
          if (!mounted) return;
          _dlLiv = p[0].fragmentShader();
          _dlStat = p[1].fragmentShader();
        }).catchError((Object _) {});
      }
      return null;
    }
    // The bake's uniforms: the scene's own, at uT 0 (the slot follows).
    final floats = <double>[widget.w, widget.h, pw / widget.w, 0];
    widget.uniforms(floats.add, 0, 0, (_) => false);
    var b = _dlBake;
    if (b == null || b.pw != pw || b.ph != ph || !listEquals(floats, _dlFloats)) {
      final key = SpGlBake.nokkelFor(d.stat, pw, ph, floats);
      _dlFloats = floats;
      if (b?.nokkel != key) {
        b?.dispose();
        b = _dlBake = SpGlBake.hent(key) ?? SpGlBake(key, d.lag, pw, ph);
      }
    }
    final bk = b!;
    if (!bk.ferdig && bk.steg(_dlStat!, floats)) SpGlBake.legg(bk);
    return bk.ferdig ? _dlLiv : null;
  }

  void _render() {
    final sh = _shader;
    if (sh == null || !mounted) return;
    if (widget.waitTex && _img.any((x) => x == null)) return;
    final w = widget.w, h = widget.h;
    final dpr = math.max(.5, math.min(_dpr, math.sqrt(_budget / (w * h))));
    final pw = (w * dpr).round(), ph = (h * dpr).round();
    final del = widget.del, liv = _liv, bake = _bake;
    final ui.Image img;
    var vei = 'SpGl';
    if (BergenPerf.malerVertPaa && del != null && liv != null && bake != null) {
      vei = 'SpGl-berg';
      img = _delt(del, liv, bake, sh, w, h, pw, ph);
    } else {
      // Heat plan Step 5 ([SpGl.deling], Bryggen): the same float uniforms go
      // to the live half once its bake is done; until then (and with the
      // switch off) the scene's own shader, as before.
      final dl = _deling(pw, ph);
      if (dl != null) vei = 'SpGl-bdel';
      final s = dl ?? sh;
      var i = 0;
      void f(double v) => s.setFloat(i++, v);
      f(w);
      f(h);
      f(pw / w);
      f(_t % 3600);
      widget.uniforms(f, _t, _age ?? _sw.elapsedMicroseconds / 1e6, (k) => k < _img.length && _img[k] != null);
      if (dl == null) {
        for (var k = 0; k < _img.length; k++) {
          sh.setImageSampler(k, _img[k] ?? _blank());
        }
      } else {
        final b = _dlBake!.bilder, sm = widget.deling!.samplere;
        for (var k = 0; k < sm.length; k++) {
          dl.setImageSampler(k, b[sm[k]]);
        }
      }
      final rec = ui.PictureRecorder();
      Canvas(rec).drawRect(Rect.fromLTWH(0, 0, pw.toDouble(), ph.toDouble()), Paint()..shader = s);
      img = rec.endRecording().toImageSync(pw, ph);
    }
    // One count per frame produced — the unsplit shader, Bryggen's split or
    // the berg split, during a bake or after.
    BergenPerf.telRender(vei);
    if (BergenPerf.malerVertPaa && _vert) {
      _ramme.sett(img);
    } else {
      setState(() => _ramme.sett(img));
    }
    widget.onFrame?.call(img);
  }

  /// Heat plan Step 6: the frame through the split. The scene's floats are
  /// written once into a list and handed to each pass in its own order; the
  /// bake runs one digit per step (the frame then still comes from the
  /// unsplit shader) whenever its key changes — never per frame.
  ui.Image _delt(SpGlDel del, ui.FragmentShader liv, ui.FragmentShader bake, ui.FragmentShader sh, double w, double h, int pw, int ph) {
    final u = <double>[];
    widget.uniforms(u.add, _t, _age ?? _sw.elapsedMicroseconds / 1e6, (k) => k < _img.length && _img[k] != null);
    final bu = <double>[];
    del.bakeU(u, bu.add);
    final noekkel = '${del.noekkel}|${pw}x$ph|$_texGen|${bu.join(',')}';
    if (noekkel != _delNoekkel) {
      _delNoekkel = noekkel;
      for (final b in _delBilder) {
        b.dispose();
      }
      _delBilder.clear();
    }
    final full = Rect.fromLTWH(0, 0, pw.toDouble(), ph.toDouble());
    void tex(ui.FragmentShader s) {
      for (var k = 0; k < _img.length; k++) {
        s.setImageSampler(k, _img[k] ?? _blank());
      }
    }

    if (_delBilder.length < malerNivaaer) {
      var i = 0;
      void f(double v) => bake.setFloat(i++, v);
      f(w);
      f(h);
      f(pw / w);
      bu.forEach(f);
      f(_delBilder.length.toDouble());
      tex(bake);
      final rec = ui.PictureRecorder();
      Canvas(rec).drawRect(full, Paint()..shader = bake);
      _delBilder.add(rec.endRecording().toImageSync(pw, ph));
      // This step's frame: the unsplit shader, as with the switch off.
      var j = 0;
      void g(double v) => sh.setFloat(j++, v);
      g(w);
      g(h);
      g(pw / w);
      g(_t % 3600);
      u.forEach(g);
      tex(sh);
      final rec2 = ui.PictureRecorder();
      Canvas(rec2).drawRect(full, Paint()..shader = sh);
      return rec2.endRecording().toImageSync(pw, ph);
    }
    var i = 0;
    void f(double v) => liv.setFloat(i++, v);
    f(w);
    f(h);
    f(pw / w);
    f(_t % 3600);
    del.livU(u, f);
    f(pw.toDouble());
    f(ph.toDouble());
    tex(liv);
    for (var k = 0; k < _delBilder.length; k++) {
      liv.setImageSampler(_img.length + k, _delBilder[k]);
    }
    final rec = ui.PictureRecorder();
    Canvas(rec).drawRect(full, Paint()..shader = liv);
    malerDeltRammer++;
    return rec.endRecording().toImageSync(pw, ph);
  }

  @override
  void dispose() {
    _hvile.dispose();
    _rammer.dispose();
    PerfTakt.slipp(_ticker);
    _ticker.dispose();
    _unload();
    _ramme.dispose();
    _shader?.dispose();
    _liv?.dispose();
    _bake?.dispose();
    for (final b in _delBilder) {
      b.dispose();
    }
    _dlBake?.dispose();
    _dlLiv?.dispose();
    _dlStat?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final img = _ramme.bilde;
    _vert = img != null && BergenPerf.malerVertPaa;
    return SizedBox(
      width: widget.w,
      height: widget.h,
      child: img == null
          ? widget.still
          : RepaintBoundary(
              child: _vert
                  ? MalerVert(ramme: _ramme, width: widget.w, height: widget.h)
                  : RawImage(image: img, width: widget.w, height: widget.h, fit: BoxFit.fill, filterQuality: FilterQuality.medium),
            ),
    );
  }
}
