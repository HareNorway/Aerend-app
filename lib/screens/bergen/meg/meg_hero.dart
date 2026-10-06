import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/home/bergen/bergen_kit.dart' show BergenWeather, BergenWeatherLook;
import '../aegil/aegil_bits.dart';

/// The Meg header (`erMeg` L7341–7355, 390 × 196 design px): Brann stadion
/// under Ulriken — the prototype's `data-ulgl="meg"` WebGL scene running live
/// ([MegStadion]: rain, players, Ulriksbanen, the LED boards, mist, stars),
/// with the still of the weather until its first frame — Ægil on the path (`aegStaa 3.6s`; a tap makes him hop and say
/// the next tip, `megAegTrykk`) and his bubble, and the light fade at the
/// bottom.
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
            // The bubble (`right:16px;bottom:94px;max-width:150px`).
            Positioned(
              right: 16,
              bottom: 94,
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
                    alignment: const Alignment(.7, 1),
                    child: Container(
                      key: const Key('meg-boble'),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14), bottomLeft: Radius.circular(14), bottomRight: Radius.circular(4)),
                        color: const Color.fromRGBO(255, 255, 255, .86),
                        border: Border.all(color: const Color.fromRGBO(255, 255, 255, .95)),
                        boxShadow: const [BoxShadow(color: Color.fromRGBO(15, 31, 43, .4), offset: Offset(0, 10), blurRadius: 9, spreadRadius: -12)],
                      ),
                      child: Text(bubble, style: inter(10.5, weight: FontWeight.w700, height: 1.35, color: const Color(0xFF173E48))),
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

/// One weather of the scene (`brPal()` in the prototype, read from it per
/// weather): the sky's top / middle / bottom, night, sun, sunset, rain, wet.
class _StadionPal {
  const _StadionPal(this.skT, this.skM, this.skB, {required this.night, this.sun = 0, this.sunset = 0, this.rain = 0, required this.wet});
  final List<double> skT, skM, skB;
  final double night, sun, sunset, rain, wet;

  static const Map<BergenWeather, _StadionPal> av = {
    BergenWeather.regn: _StadionPal([.7176, .7765, .8235], [.8275, .8627, .8745], [.7882, .8275, .8353], night: .74, rain: 1, wet: 1),
    BergenWeather.sol: _StadionPal([.36, .57, .78], [.55, .71, .84], [.72, .82, .88], night: .06, sun: 1, wet: .55),
    BergenWeather.solnedgang: _StadionPal([.4941, .4706, .5647], [.7882, .5647, .4314], [.8510, .6314, .4627], night: .55, sunset: 1, wet: .55),
    BergenWeather.natt: _StadionPal([.0627, .1176, .1882], [.0863, .1961, .2902], [.1216, .2667, .3765], night: 1, wet: .55),
  };
}

/// The stadium scene, live: `shaders/meg_stadion.frag` (the prototype's own
/// shader) rendered offscreen at about 20 frames a second into at most
/// 160 000 pixels (`ulGlTegn`), drawn over the still (which also stands in
/// when the shader cannot load). Reduced motion slows the scene to 15 %, as
/// the prototype's `rolig` does.
class MegStadion extends StatefulWidget {
  const MegStadion({super.key, required this.kind});

  final BergenWeather kind;

  @override
  State<MegStadion> createState() => _MegStadionState();
}

class _MegStadionState extends State<MegStadion> with SingleTickerProviderStateMixin {
  static Future<ui.FragmentProgram>? _program;
  static const double _w = 390, _h = 196;

  ui.FragmentShader? _shader;
  ui.Image? _frame;
  late final Ticker _ticker;
  Duration _sist = Duration.zero;
  Duration _prev = Duration.zero;
  double _t = 0;
  double _dpr = 1.5;
  bool _reduce = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _program ??= ui.FragmentProgram.fromAsset('shaders/meg_stadion.frag');
    _program!.then((pr) {
      if (!mounted) return;
      _shader = pr.fragmentShader();
      _render();
      _ticker.start();
    }).catchError((Object _) {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.disableAnimationsOf(context);
    _dpr = math.min(1.5, MediaQuery.devicePixelRatioOf(context));
  }

  @override
  void didUpdateWidget(MegStadion old) {
    super.didUpdateWidget(old);
    if (old.kind != widget.kind) _render();
  }

  void _tick(Duration e) {
    _t += ((e - _prev).inMicroseconds / 1e6).clamp(0.0, .1) * (_reduce ? .15 : 1);
    _prev = e;
    // The scene moves calmly; 20 frames a second is enough (`ulGlTegn`).
    if (e - _sist < const Duration(milliseconds: 50)) return;
    _sist = e;
    _render();
  }

  void _render() {
    final sh = _shader;
    if (sh == null) return;
    final dpr = math.max(.5, math.min(_dpr, math.sqrt(160000 / (_w * _h))));
    final pw = (_w * dpr).round(), ph = (_h * dpr).round();
    final p = _StadionPal.av[widget.kind]!;
    var i = 0;
    void f(double v) => sh.setFloat(i++, v);
    f(_w);
    f(_h);
    f(pw / _w);
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
    final rec = ui.PictureRecorder();
    Canvas(rec).drawRect(Rect.fromLTWH(0, 0, pw.toDouble(), ph.toDouble()), Paint()..shader = sh);
    final img = rec.endRecording().toImageSync(pw, ph);
    final old = _frame;
    setState(() => _frame = img);
    old?.dispose();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame?.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final img = _frame;
    if (img == null) return const SizedBox.expand();
    return RepaintBoundary(
      child: RawImage(key: const Key('meg-stadion-live'), image: img, width: _w, height: _h, fit: BoxFit.fill, filterQuality: FilterQuality.medium),
    );
  }
}
