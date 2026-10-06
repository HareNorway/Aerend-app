import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/home/bergen/bergen_kit.dart' show BergenWeather, BergenWeatherLook;
import 'aegil_bits.dart';

/// Ægil's pose on Fløyen (`agBFront` / `agBHei` / `agBFunn` / `agBLeter` /
/// `agBLei`).
enum AeKropp { rygg, hei, funn, leter, lei }

/// The head in the header avatar (`agHode_*`).
enum AeHode { front, find, popup, discount, store, sorry, wait }

/// The top of `erAgent` (L4501–4537): the sky gradient, the Fløyen view
/// (the prototype's `data-flgl="agent"` WebGL scene with its blur, light and
/// vignette layers, baked per weather), Ægil on the viewpoint with his
/// shadow, and the listening bars beside him.
class AegilScene extends StatelessWidget {
  const AegilScene({super.key, required this.look, required this.kropp, this.lytter = false});

  final BergenWeatherLook look;
  final AeKropp kropp;
  final bool lytter;

  String get _bilde => 'assets/images/aegil/floyen_${switch (look.kind) {
        BergenWeather.regn => 'regn',
        BergenWeather.sol => 'sol',
        BergenWeather.solnedgang => 'solnedgang',
        BergenWeather.natt => 'natt',
      }}.jpg';

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          top: 0,
          width: 390,
          height: 252,
          child: Image.asset(_bilde, fit: BoxFit.fill, gaplessPlayback: true, filterQuality: FilterQuality.medium),
        ),
        // The shadow under his feet (`left:46px;top:180px;78×13`, blur 3).
        Positioned(
          left: 46,
          top: 180,
          width: 78,
          height: 13,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: cssSigma(3), sigmaY: cssSigma(3)),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.elliptical(39, 6.5)),
                gradient: RadialGradient(colors: [Color.fromRGBO(0, 15, 22, .5), Color.fromRGBO(0, 15, 22, 0)], stops: [0, .72]),
              ),
            ),
          ),
        ),
        Positioned(left: 48, top: 116, width: 74, child: _Kropp(kropp: kropp)),
        if (lytter) const Positioned(left: 120, top: 134, child: _Lytt()),
      ],
    );
  }
}

class _Kropp extends StatelessWidget {
  const _Kropp({required this.kropp});

  final AeKropp kropp;

  @override
  Widget build(BuildContext context) {
    final pose = kropp;
    final (navn, ms, m, glod) = switch (pose) {
      AeKropp.rygg => ('rear', 3800.0, aeStaa, false),
      AeKropp.hei => ('front', 2400.0, aegVink, false),
      AeKropp.funn => ('front', 2400.0, aegHopp, true),
      AeKropp.leter => ('side', 2800.0, aegKikk, false),
      AeKropp.lei => ('front', 3400.0, aeStaa, false),
    };
    final bilde = Image.asset(aePose(navn), width: 74, gaplessPlayback: true);
    // `filter: drop-shadow(0 6px 6px rgba(0,15,22,.5))` on the rear pose
    // (`agGlow`), and the mint glow on `funn`.
    final Widget figur = Stack(
      clipBehavior: Clip.none,
      children: [
        if (pose == AeKropp.rygg)
          Positioned(
            left: 0,
            top: 6,
            width: 74,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: ColorFiltered(colorFilter: const ColorFilter.mode(Color.fromRGBO(0, 15, 22, .5), BlendMode.srcIn), child: bilde),
            ),
          ),
        if (glod)
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: ColorFiltered(colorFilter: const ColorFilter.mode(Color.fromRGBO(92, 224, 184, .95), BlendMode.srcIn), child: bilde),
            ),
          ),
        bilde,
      ],
    );
    return AeLoop(key: ValueKey(pose), m: (t) => m(t, ms), child: figur);
  }
}

/// `agLytter` — three 3×13 bars, `lyttBar 1s` (scaleY .5 → 1), .2 s apart.
class _Lytt extends StatelessWidget {
  const _Lytt();

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: LfLoop(
      frozenMs: 500,
      builder: (context, t, _) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Transform.scale(
              scaleY: kf(((t - i * 200) / 1000) % 1.0, const [0, .5, 1], const [.5, 1, .5], cssEaseInOut),
              child: Container(
                width: 3,
                height: 13,
                decoration: BoxDecoration(color: const Color(0xFFF5F3EF), borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// The header avatar (L4537–4552): the 54 px sky tile with the ground strip,
/// Ægil's head in the pose of the moment (nodding in on every change,
/// `nikkA/B .9s`, then breathing, `aegPust 4.2s`), and the three speech
/// lines that flick out beside it (`bolge 1.5s`).
class AegilHode extends StatelessWidget {
  const AegilHode({super.key, required this.hode, required this.tikk});

  final AeHode hode;

  /// Bumped on every state change so the nod and the lines replay.
  final int tikk;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CssBox(
              radius: BorderRadius.circular(20),
              clip: true,
              bg: const [
                CssLinear(180, [Color(0xFFA9C5D9), Color(0xFF7E93A3), Color(0xFF456E7C)], [0, .46, 1]),
              ],
              shadows: const [
                CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .6)),
                CssShadow(0, 0, 0, 2.5, Colors.white),
                CssShadow(0, 12, 20, -10, Color.fromRGBO(15, 31, 43, .65)),
              ],
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // `left:-14%;top:-24%;70%×80%` white glow.
                  const Positioned(
                    left: -54 * .14,
                    top: -54 * .24,
                    width: 54 * .7,
                    height: 54 * .8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [Color.fromRGBO(255, 255, 255, .55), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .7]),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 13,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6E5137), Color(0xFF4A3524)]),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 27 - 37,
                    width: 74,
                    bottom: -9,
                    child: _Nikk(key: ValueKey('h$tikk'), child: Image.asset(aePose(hode.name), width: 74, gaplessPlayback: true)),
                  ),
                ],
              ),
            ),
          ),
          Positioned(right: -5, top: -3, child: _Bolger(key: ValueKey('b$tikk'))),
        ],
      ),
    );
  }
}

/// `nikkA/B .9s cubic-bezier(.3,1.2,.5,1) both, aegPust 4.2s 1s infinite`.
class _Nikk extends StatelessWidget {
  const _Nikk({super.key, required this.child});

  final Widget child;

  static const Cubic _c = Cubic(.3, 1.2, .5, 1);

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: LfLoop(
      child: child,
      builder: (context, t, child) {
        Matrix4 m;
        if (t < 1000) {
          final p = (t / 900).clamp(0.0, 1.0);
          final r = kf(p, const [0, .25, .55, 1], const [0, -7, 5, 0], _c);
          final y = kf(p, const [0, .25, .55, 1], const [0, -3, 1, 0], _c);
          m = Matrix4.translationValues(0, y, 0)..rotateZ(rad(r));
        } else {
          final p = ((t - 1000) / 4200) % 1.0;
          final s = kf(p, const [0, .5, 1], const [1, 1.03, 1], cssEaseInOut);
          m = Matrix4.diagonal3Values(s, s, 1);
        }
        return Transform(alignment: Alignment.bottomCenter, transform: m, child: child);
      },
    ),
  );
}

/// The three speech lines (`bolge 1.5s ease-out both`, .05 / .22 / .39 s).
class _Bolger extends StatelessWidget {
  const _Bolger({super.key});

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: 1900,
    builder: (context, t, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final (i, w) in const [(0, 9.0), (1, 13.0), (2, 7.0)]) ...[
          if (i > 0) const SizedBox(height: 2),
          _linje(kfP(t, 50 + i * 170.0, 1500), w),
        ],
      ],
    ),
  );

  Widget _linje(double p, double w) {
    final o = kf(p, const [0, .35, 1], const [0, .85, 0], cssEaseOut);
    final x = kf(p, const [0, .35, 1], const [-3, 0, 4], cssEaseOut);
    final sx = kf(p, const [0, .35, 1], const [.5, 1, .7], cssEaseOut);
    return Opacity(
      opacity: o.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(x, 0),
        child: Transform.scale(
          scaleX: sx,
          child: Container(width: w, height: 2.5, decoration: BoxDecoration(color: kAeTeal, borderRadius: BorderRadius.circular(2))),
        ),
      ),
    );
  }
}
