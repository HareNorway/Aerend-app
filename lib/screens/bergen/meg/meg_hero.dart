import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/home/bergen/bergen_kit.dart' show BergenWeather, BergenWeatherLook;
import '../aegil/aegil_bits.dart';
import '../kit/br_pal.dart';
import '../kit/bergen_perf.dart';
import '../kit/maler_vert.dart';

/// The Meg header (`erMeg` L7341–7355, 390 × 196 design px): Brann stadion
/// under Ulriken — the prototype's `data-ulgl="meg"` WebGL scene running live
/// ([MegStadion]: rain, players, Ulriksbanen, the LED boards, mist, stars),
/// with the still of the weather until its first frame — Ægil on the path (`aegStaa 3.6s`; a tap makes him hop and say
/// the next tip, `megAegTrykk`) and his bubble, and the light fade at the
/// bottom.
/// The stadium's top pixel ratio at full tier (design: 3; heat plan: 1.5).
const double kStadionMaksDpr = 1.5;

class MegHero extends StatelessWidget {
  const MegHero({super.key, required this.look, required this.bubble, required this.n, required this.onAegil});

  final BergenWeatherLook look;
  final String bubble;

  /// Taps on Ægil so far (`megAegN`).
  final int n;
  final VoidCallback onAegil;

  String get _bilde => 'assets/images/meg/stadion_${switch (look.kind) {
        BergenWeather.regn => 'regn',
        BergenWeather.sol => 'sol',
        BergenWeather.solnedgang => 'solnedgang',
        BergenWeather.natt => 'natt',
      }}.jpg';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('meg-hero'),
      width: 390,
      height: 196,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF7E93A3), Color(0xFF9FB2BD), Color(0xFFB6BFB8), Color(0xFFA8B6BA)],
                    stops: [0, .44, .74, 1],
                  ),
                ),
              ),
            ),
            Positioned.fill(child: Image.asset(_bilde, fit: BoxFit.fill, gaplessPlayback: true, filterQuality: FilterQuality.medium)),
            Positioned.fill(child: MegStadion(kind: look.kind)),
            // «BRANN» on the stand (`left:138px;width:112px;top:176px`).
            Positioned(
              left: 138,
              width: 112,
              top: 176,
              height: 8,
              child: IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.only(left: 6 * .34),
                  child: Center(child: Text('BRANN', style: jakarta(6, em: .34, height: 1, color: const Color(0xFFF4ECE6)))),
                ),
              ),
            ),
            // The bubble (new Bergen L7425: `right:12px;bottom:92px;max-width:150px`,
            // white, 14 px round, with a tail toward Ægil).
            Positioned(
              right: 12,
              bottom: 92,
              child: GestureDetector(
                onTap: onAegil,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: AeOnce(
                    key: ValueKey('b$n'),
                    kind: n == 0 || n.isEven ? AeInn.bobleFraAegil : AeInn.vcBoble,
                    ms: n == 0 ? 500 : (n.isOdd ? 420 : 450),
                    delay: n == 0 ? 450 : 120,
                    curve: n.isOdd ? const Cubic(.25, 1.25, .45, 1) : const Cubic(.3, 1.3, .5, 1),
                    // `transform-origin: calc(100% - 42px) 100%`.
                    alignment: const Alignment(.44, 1),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          right: 36,
                          bottom: -5,
                          child: Transform.rotate(
                            angle: math.pi / 4,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(bottomRight: Radius.circular(3))),
                            ),
                          ),
                        ),
                        Container(
                          key: const Key('meg-boble'),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.white,
                            boxShadow: const [BoxShadow(color: Color.fromRGBO(15, 31, 43, .55), offset: Offset(0, 10), blurRadius: 18 / 2 / .57735, spreadRadius: -10)],
                          ),
                          child: Text(bubble, style: inter(10.5, weight: FontWeight.w700, height: 1.35, color: const Color(0xFF173E48))),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // His shadow (`bottom:17px;right:30px;48×10`).
            const Positioned(
              right: 30,
              bottom: 17,
              width: 48,
              height: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.elliptical(24, 5)),
                  gradient: RadialGradient(colors: [Color.fromRGBO(3, 14, 20, .55), Color.fromRGBO(3, 14, 20, 0)], stops: [0, .72]),
                ),
              ),
            ),
            Positioned(
              right: 21,
              bottom: 19,
              width: 66,
              child: GestureDetector(
                key: const Key('meg-aegil'),
                onTap: onAegil,
                child: _Aegil(key: ValueKey('a$n'), hopp: n > 0, child: Image.asset(aePose('front'), width: 66)),
              ),
            ),
            // `linear-gradient(180deg,rgba(245,243,239,0),rgba(245,243,239,.28))`.
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 26,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color.fromRGBO(245, 243, 239, 0), Color.fromRGBO(245, 243, 239, .28)],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `aegHoppA/B .64s cubic-bezier(.3,.7,.4,1)` on a tap, then `aegStaa 3.6s`.
class _Aegil extends StatelessWidget {
  const _Aegil({super.key, required this.hopp, required this.child});

  final bool hopp;
  final Widget child;

  static const Cubic _c = Cubic(.3, .7, .4, 1);

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: LfLoop(
      child: child,
      builder: (context, t, child) {
        var m = Matrix4.identity();
        if (hopp && t < 640) {
          final p = t / 640;
          const st = <double>[0, .14, .38, .6, .76, .9, 1];
          final dy = kf(p, st, const [0, 0, -30, -10, 0, 0, 0], _c);
          final sx = kf(p, st, const [1, 1.1, .93, 1, 1.08, .98, 1], _c);
          final sy = kf(p, st, const [1, .86, 1.09, 1, .9, 1.02, 1], _c);
          m = Matrix4.translationValues(0, dy, 0)..scaleByDouble(sx, sy, 1, 1);
        } else {
          m = aegStaa(t - (hopp ? 640 : 0), 3600);
        }
        return Transform(alignment: Alignment.bottomCenter, transform: m, child: child);
      },
    ),
  );
}

/// The stadium scene, live: `shaders/meg_stadion.frag` (the prototype's own
/// shader) in `ulGlTegn`'s two passes — the scene (uPass 0) into a
/// supersampled image (`ss`: twice the screen's pixel ratio, at most 4× the
/// design px, 2× in `lite`), whole the first time (and on a new weather or
/// size), then one stripe of [_stripes] a frame; the screen pass (uPass 1,
/// at a pixel ratio of at most 3, 1.5 in `lite` — the prototype's `svak`)
/// reads it and adds what moves. Rendered offscreen at about 33 frames a
/// second and drawn over the still (which also stands in when the shader
/// cannot load). Reduced motion slows the scene to 15 %, as the prototype's
/// `rolig` does.
class MegStadion extends StatefulWidget {
  const MegStadion({super.key, required this.kind});

  final BergenWeather kind;

  @override
  State<MegStadion> createState() => _MegStadionState();
}

class _MegStadionState extends State<MegStadion> with SingleTickerProviderStateMixin {
  static Future<ui.FragmentProgram>? _program;
  static const double _w = 390, _h = 196;

  // The scene pass and the screen pass (one program, two sets of uniforms).
  ui.FragmentShader? _shader, _skjerm;
  // The scene image, its weather and size, and the next stripe (rows from
  // the bottom, as GL's scissor counts them).
  ui.Image? _scene;
  String? _sceneSig;
  int _rad = 0;
  bool _aBusy = false;
  bool _aVenter = false;
  bool _ventSkjerm = false;
  // uScene for the scene pass, which doesn't read it (the prototype's `tom`).
  ui.Image? _tom;
  // Heat plan Step 6: the newest frame; with [BergenPerf.malerVertPaa] a new
  // one only repaints [MalerVert] (no setState per step).
  final MalerRamme _ramme = MalerRamme();
  bool _vert = false;
  late final Ticker _ticker;
  Duration _sist = Duration.zero;
  Duration _prev = Duration.zero;
  double _t = 0;
  double _dpr = 3;
  bool _reduce = false;

  // Motion tier (parity plan §3.1): every 30 ms in `full` (`ulGlTegn`'s step
  // when its two passes take over 9 ms; 14 ms when they're quicker), 60 ms
  // with the `svak` sizes in `lite`, one frame in `still` unless the user
  // asked for calm (then the prototype's slow `rolig`).
  // Lys plan Step 15 (heat): the design adapts 14–30 ms; the app keeps its heat-tuned 20 fps (12 in lite).
  static const double _fullMs = 50, _liteMs = 1000 / 12;
  Duration _step = const Duration(milliseconds: 30);
  bool _svak = false;

  // `ulGlTegn`'s stripe count (`g.N`, 12 to start; the prototype tunes it
  // between 8 and 48 by the frame's GPU time).
  static const int _stripes = 12;

  // Perf plan: no frames while the stadium is off the screen (Meg scrolled
  // down); its clock carries on (see PerfHvile).
  late final PerfHvile _hvile = PerfHvile(context, _ticker, onVaakn: (s) {
    _t += s * (_reduce ? .15 : 1);
    _prev = Duration.zero;
    _sist = Duration.zero;
  });

  // Heat plan Step 4: no frames between the stadium's own steps.
  late final PerfStegRammer _rammer;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _rammer = PerfStegRammer(_ticker, tickerModus: () => TickerMode.getNotifier(context));
    _program ??= ui.FragmentProgram.fromAsset('shaders/meg_stadion.frag');
    _program!.then((pr) {
      if (!mounted) return;
      _shader = pr.fragmentShader();
      _skjerm = pr.fragmentShader();
      _render();
      if (BergenPerf.shaderStep(context, fullMs: _fullMs, liteMs: _liteMs) != null || BergenPerf.calmOf(context)) {
        _ticker.start();
      }
    }).catchError((Object _) {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.disableAnimationsOf(context);
    _dpr = MediaQuery.devicePixelRatioOf(context);
    final calm = BergenPerf.calmOf(context);
    final step = BergenPerf.shaderStep(context, fullMs: _fullMs, liteMs: _liteMs);
    _step = step ?? (calm ? Duration(milliseconds: _liteMs.round()) : _step);
    // `svak` (the prototype's pixel budget under 110 000): the `lite` tier.
    _svak = BergenPerf.shaderBudget(context, 1) < 1;
    // Heat / battery `still`: hold the frame; the user's calm keeps `rolig`.
    final hold = step == null && !calm;
    if (hold) _hvile.vaakn(start: false);
    if (hold && _ticker.isActive) {
      _rammer.vekk();
      _ticker.stop();
    }
    if (!hold && !_ticker.isActive && _shader != null && !_hvile.hviler) _ticker.start();
  }

  @override
  void didUpdateWidget(MegStadion old) {
    super.didUpdateWidget(old);
    if (old.kind != widget.kind) _render();
  }

  void _tick(Duration e) {
    _rammer.tikk(e);
    if (_hvile.tikk(n: _rammer.n)) return;
    _t += _rammer.dt(e, _prev, .1) * (_reduce ? .15 : 1);
    if (BergenPerf.frysMs != null) _t = BergenPerf.frysMs! / 1000;
    _prev = e;
    // Heat ladder / idle: on the takt's frames, at its own pace on average.
    final sist = PerfTakt.paa ? PerfTakt.steg(e, _sist, _step) : (e - _sist < _step ? null : e);
    if (sist == null) {
      _rammer.etter(e, _sist, _step);
      return;
    }
    _sist = sist;
    _rammer.etter(e, _sist, _step);
    _render();
  }

  /// `ulGlTegn`: pass A (the scene into its image, whole or one stripe),
  /// then pass B (the screen).
  void _render() {
    final sh = _shader, sk = _skjerm;
    if (sh == null || sk == null) return;
    // Lys plan Step 15 (heat): the design caps the ratio at 3 (1.5 when weak); the app keeps its own 1.5 cap
    // from the heat work — the same picture at a lower resolution. One number to raise after a device check.
    final d = math.max(1.0, math.min(_svak ? 1.5 : kStadionMaksDpr, _dpr)), ss = math.min(_svak ? 2.0 : 4.0, d * 2);
    final pw = (_w * d).round(), ph = (_h * d).round(), sw = (_w * ss).round(), sh2 = (_h * ss).round();
    final p = BrPal.of(widget.kind);
    void set(ui.FragmentShader s, double dpr, double pass) {
      var i = 0;
      void f(double v) => s.setFloat(i++, v);
      f(_w);
      f(_h);
      f(dpr);
      f(12 + _t % 3600);
      f(p.night);
      f(p.sun);
      f(p.sunset);
      f(p.rain);
      f(0); // uSnow — Bergen's four looks have no snow
      f(p.wet);
      f(p.rain > 0 ? .5 : (p.sun > .9 ? .18 : .3)); // uHz
      f(p.rain > 0 ? 30 : -20); // uCY
      for (final c in [p.skT, p.skM, p.skB]) {
        c.forEach(f);
      }
      f(pass); // uPass
    }

    // Pass A: the scene into its image.
    set(sh, sw / _w, 0);
    sh.setImageSampler(0, _tom ??= _blank());
    final sig = '${widget.kind.name}|${sw}x$sh2';
    final full = Rect.fromLTWH(0, 0, sw.toDouble(), sh2.toDouble());
    final pa = Paint()
      ..shader = sh
      ..blendMode = BlendMode.src;
    // The scene image is made with the async `toImage` (a plain texture). A `toImageSync` image keeps its
    // display list, which drew the previous scene — every stripe step would keep the whole chain of older
    // scenes alive (an unbounded GPU leak). One step in flight; the screen pass uses the newest finished one.
    if (!_aBusy) {
      final ny = _scene == null || _sceneSig != sig;
      if (!ny || !_aVenter) {
        final rec0 = ui.PictureRecorder();
        final c0 = Canvas(rec0);
        if (ny) {
          c0.drawRect(full, pa);
          _rad = 0;
          _aVenter = true;
        } else {
          final n = (sh2 / _stripes).ceil(), y0 = _rad;
          c0.drawImage(_scene!, Offset.zero, Paint()..blendMode = BlendMode.src);
          c0.drawRect(Rect.fromLTRB(0, math.max(0, sh2 - y0 - n).toDouble(), full.right, (sh2 - y0).toDouble()), pa);
          _rad = y0 + n >= sh2 ? 0 : y0 + n;
        }
        final pic = rec0.endRecording();
        _aBusy = true;
        pic.toImage(sw, sh2).then((img) {
          pic.dispose();
          _aBusy = false;
          if (!mounted) {
            img.dispose();
            return;
          }
          _scene?.dispose();
          _scene = img;
          _sceneSig = sig;
          _aVenter = false;
          // A screen frame was skipped waiting for this scene (first frame, `still`): draw it now, once.
          if (_ventSkjerm) {
            _ventSkjerm = false;
            _render();
          }
        }, onError: (Object _) {
          pic.dispose();
          _aBusy = false;
          _aVenter = false;
        });
      }
    }
    final scene = _scene;
    // Nothing finished yet (first frame, new weather/size): the still stays up a frame longer.
    if (scene == null || _sceneSig != sig) {
      _ventSkjerm = true;
      return;
    }
    var rec = ui.PictureRecorder();
    var c = Canvas(rec);
    // Pass B: the screen.
    set(sk, pw / _w, 1);
    sk.setImageSampler(0, scene);
    rec = ui.PictureRecorder();
    c = Canvas(rec);
    c.drawRect(Rect.fromLTWH(0, 0, pw.toDouble(), ph.toDouble()), Paint()..shader = sk);
    final img = rec.endRecording().toImageSync(pw, ph);
    BergenPerf.telRender('Meg');
    if (BergenPerf.malerVertPaa && _vert) {
      _ramme.sett(img);
    } else {
      setState(() => _ramme.sett(img));
    }
  }

  static ui.Image _blank() {
    final rec = ui.PictureRecorder();
    Canvas(rec).drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint()..color = const Color(0x00000000));
    return rec.endRecording().toImageSync(1, 1);
  }

  @override
  void dispose() {
    _hvile.dispose();
    _rammer.dispose();
    PerfTakt.slipp(_ticker);
    _ticker.dispose();
    _ramme.dispose();
    _shader?.dispose();
    _skjerm?.dispose();
    _scene?.dispose();
    _tom?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final img = _ramme.bilde;
    _vert = img != null && BergenPerf.malerVertPaa;
    if (img == null) return const SizedBox.expand();
    return RepaintBoundary(
      child: _vert
          ? MalerVert(key: const Key('meg-stadion-live'), ramme: _ramme, width: _w, height: _h)
          : RawImage(key: const Key('meg-stadion-live'), image: img, width: _w, height: _h, fit: BoxFit.fill, filterQuality: FilterQuality.medium),
    );
  }
}
