import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../kit/svg_sti.dart';
import 'sporing_bits.dart';
import 'sporing_copy.dart';
import 'sporing_scene_kai.dart';

/// **Sporing · Levert** (L6896): the house at night (baked from the
/// prototype's WebGL canvas), the street number, Ægil on the step waving and
/// walking back to the bike (`lvGaa`, `lvSteg`), the bike rolling off
/// (`lvHopp`, `lvTramp`, `lvLys`, `lvKjor`) — or Ægil staying and waving for
/// a pickup or a partner delivery — the «God appetitt!» bubble, «Håper det
/// smaker.» and the SPART TID chip. 390 × 480.
class SpSceneHus extends StatelessWidget {
  const SpSceneHus({super.key, required this.info});

  final SpSceneInfo info;

  @override
  Widget build(BuildContext context) {
    final drar = !info.henting && !info.partner;
    final spart = info.spartSek ?? 0;
    return SpSceneInn(
      child: SizedBox(
        width: 390,
        height: 480,
        child: ClipRect(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Image.asset('assets/images/sporing/hus.jpg', fit: BoxFit.fill, filterQuality: FilterQuality.medium),
              ),
              // The street number (left 225, top 246, 12 × 12).
              if (info.husnummer.isNotEmpty)
                Positioned(
                  left: 225,
                  top: 246,
                  child: CssBox(
                    width: 12,
                    height: 12,
                    radius: BorderRadius.circular(2),
                    bg: const [
                      CssLinear(180, [Color(0xFF2D64A8), Color(0xFF1C4682)]),
                    ],
                    shadows: [const CssShadow(0, 0, 0, 1, Color(0xFFDCE4EA)), CssShadow(0, 1, 2, 0, rgba(0, 0, 0, .55))],
                    child: Center(child: Text(info.husnummer, style: jakarta(8.5, height: 1))),
                  ),
                ),
              // The bike (left 60, top 228, 120 × 120) or the van.
              if (drar && info.sykkel) const Positioned(left: 60, top: 228, child: _Sykkel()),
              if (drar && !info.sykkel) const Positioned(left: 26, top: 211, child: _Bil()),
              // Ægil on the step (left 163, top 238, 66 × 66).
              Positioned(left: 163, top: 238, child: drar ? const _AegilDrar() : _AegilBlir()),
              // «God appetitt!» (left 100, top 186), `lvBoble 2.6s 1.4s`.
              Positioned(
                left: 100,
                top: 186,
                child: IgnorePointer(
                  child: LfOnce(
                    ms: 4000,
                    builder: (context, t, child) {
                      final p = cssEaseOut.transform(kfP(t, 1400, 2600));
                      const st = [0.0, .12, .85, 1.0];
                      final o = kf(p, st, const [0, 1, 1, 0]);
                      final y = kf(p, st, const [8, 0, 0, -4]);
                      final k = kf(p, st, const [.9, 1, 1, 1]);
                      return Opacity(
                        opacity: o.clamp(0.0, 1.0),
                        child: Transform(alignment: Alignment.center, transform: Matrix4.translationValues(0, y, 0)..scaleByDouble(k, k, 1, 1), child: child),
                      );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CssBox(
                          radius: BorderRadius.circular(14),
                          padding: const EdgeInsets.fromLTRB(11, 7, 11, 7),
                          bg: [
                            CssLinear(160, [rgba(255, 255, 255, .97), rgba(233, 240, 242, .94)]),
                          ],
                          shadows: [CssShadow(0, 10, 22, -8, rgba(3, 16, 24, .6)), const CssShadow.inset(0, 1, 0, 0, Color(0xFFFFFFFF))],
                          child: Text(SporingCopy.a1_sporing_god_appetitt, style: jakarta(12.5, em: -.01, color: kSpPaperInk)),
                        ),
                        Positioned(
                          right: 14,
                          bottom: -6,
                          child: Transform.rotate(
                            angle: rad(45),
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEEF3F4),
                                borderRadius: BorderRadius.only(bottomRight: Radius.circular(3)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // «Håper det smaker.» (top 20), `spOpp .6s 1.2s`.
              Positioned(
                left: 0,
                right: 0,
                top: 20,
                child: LfRise(
                  delay: 1200,
                  dur: 600,
                  curve: cssOppStor,
                  child: Text(
                    SporingCopy.a1_sporing_haaper_smaker,
                    textAlign: TextAlign.center,
                    style: jakarta(26, em: -.03, height: 1.1, color: const Color(0xFFF5F3EF), shadows: spTekstSkygge()),
                  ),
                ),
              ),
              // SPART TID (top 58), `spChipC .5s 1.6s`.
              if (spart > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 58,
                  child: Center(
                    child: SpChipC(
                      child: CssBox(
                        radius: BorderRadius.circular(999),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        border: Border.all(color: rgba(92, 224, 184, .55)),
                        bg: [
                          CssLinear(180, [rgba(10, 32, 42, .9), rgba(6, 22, 30, .94)]),
                        ],
                        shadows: [CssShadow(0, 0, 0, 1, rgba(92, 224, 184, .2)), CssShadow(0, 0, 22, 0, rgba(92, 224, 184, .35)), CssShadow(0, 14, 24, -12, rgba(3, 16, 24, .9))],
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            spIkon(kSpIkonKlokke, size: 14, color: kSpMintLight, extra: kSpIkonKlokkeExtra),
                            const SizedBox(width: 8),
                            Text(
                              SporingCopy.a1_sporing_spart,
                              style: inter(10, weight: FontWeight.w800, em: .1, color: kSpMintLight),
                            ),
                            const SizedBox(width: 8),
                            Text(spMmSs(spart), style: jakarta(18, em: -.02)),
                            if (info.poeng != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '+${info.poeng}',
                                style: inter(12, weight: FontWeight.w800, color: kSpMintLight),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // Shooting stars and the bottom fade.
              const Positioned(right: 20, top: 30, child: _Stjerneskudd(w: 90, dur: 9000, delay: 2000)),
              const Positioned(right: 120, top: 80, child: _Stjerneskudd(w: 70, dur: 13000, delay: 7000)),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 140,
                child: IgnorePointer(
                  child: CssBox(
                    bg: [
                      CssLinear(180, [rgba(6, 20, 28, 0), rgba(6, 20, 28, .5)]),
                    ],
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

/// `stjerneskudd` — a streak that fires once per cycle (86 %→96 %).
class _Stjerneskudd extends StatelessWidget {
  const _Stjerneskudd({required this.w, required this.dur, required this.delay});

  final double w, dur, delay;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: LfLoop(
      builder: (context, t, child) {
        final e = t - delay;
        final p = e < 0 ? 0.0 : (e / dur) % 1.0;
        final q = cssEaseIn.transform(p);
        const st = [0.0, .86, .88, .96, 1.0];
        final o = kf(q, st, const [0, 0, 1, 0, 0]);
        final x = kf(q, st, const [0, 0, 0, -220, -220]);
        final y = kf(q, st, const [0, 0, 0, 120, 120]);
        return Opacity(
          opacity: o.clamp(0.0, 1.0),
          child: Transform(alignment: Alignment.centerRight, transform: Matrix4.translationValues(x, y, 0)..rotateZ(rad(-28)), child: child),
        );
      },
      child: Container(
        width: w,
        height: 2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: LinearGradient(colors: [rgba(255, 255, 255, 0), Colors.white]),
          boxShadow: [BoxShadow(color: rgba(255, 255, 255, .8), blurRadius: 4)],
        ),
      ),
    ),
  );
}

/// A reflection in the wet street: the child flipped, 20 %, fading up.
class _Speil extends StatelessWidget {
  const _Speil({required this.child, required this.height, this.origin = .955, this.alpha = .2, this.fadeTo = .5});

  final Widget child;
  final double height, origin, alpha, fadeTo;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Opacity(
      opacity: alpha,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (r) => LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: const [Colors.black, Colors.transparent], stops: [0, fadeTo]).createShader(r),
        child: Transform(alignment: Alignment(0, origin * 2 - 1), transform: Matrix4.diagonal3Values(1, -1, 1), child: child),
      ),
    ),
  );
}

/// The bike parked, then Ægil on it rolling away (120 × 120).
class _Sykkel extends StatelessWidget {
  const _Sykkel();

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: 9300,
    builder: (context, t, child) {
      // lvKjor 2.3s 6.9s cubic-bezier(.5,0,.92,.55)
      final k = const Cubic(.5, 0, .92, .55).transform(kfP(t, 6900, 2300));
      return Transform.translate(offset: Offset(-430 * k, 0), child: child);
    },
    child: SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: _Speil(height: 120, child: _SykkelKropp(speil: true))),
          const Positioned.fill(child: _SykkelKropp()),
        ],
      ),
    ),
  );
}

class _SykkelKropp extends StatelessWidget {
  const _SykkelKropp({this.speil = false});

  final bool speil;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: 7500,
    builder: (context, t, _) {
      // lvHopp .5s 6s
      final h = cssEaseOut.transform(kfP(t, 6000, 500));
      const st = [0.0, .3, .6, 1.0];
      final y = kf(h, st, const [0, -6, 1, 0]);
      final sx = kf(h, st, const [1, .98, 1.03, 1]);
      final sy = kf(h, st, const [1, 1.04, .96, 1]);
      final bytt = kfP(t, 6050, 160); // aegUt / aegVis
      return Transform(
        alignment: const Alignment(0, .91),
        transform: Matrix4.translationValues(0, y, 0)..scaleByDouble(sx, sy, 1, 1),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Opacity(
              opacity: 1 - bytt,
              child: const CustomPaint(size: Size(120, 120), painter: _ParkertSykkel()),
            ),
            Opacity(
              opacity: bytt,
              child: LfLoop(
                builder: (context, t, child) {
                  // lvTramp .42s 6.9s
                  final e = t - 6900;
                  final p = e < 0 ? 0.0 : (e / 420) % 1.0;
                  final ty = kf(p, const [0, .5, 1], const [0, -1.2, 0], cssEaseInOut);
                  final r = kf(p, const [0, .5, 1], const [0, -.8, 0], cssEaseInOut);
                  return Transform(alignment: const Alignment(0, .9), transform: Matrix4.translationValues(0, ty, 0)..rotateZ(rad(r)), child: child);
                },
                child: aegil('bike', w: 120, h: 120),
              ),
            ),
            if (!speil) ...[
              Positioned(left: 23, top: 60, child: _Lys(size: 16, farger: const [Color(0xFFFFFCEC), Color(0x99FFEEC4), Color(0x00FFDC96)])),
              Positioned(left: 78, top: 76, child: _Lys(size: 12, farger: const [Color(0xFFFF7864), Color(0x8CFF281E), Color(0x00FF140A)])),
            ],
          ],
        ),
      );
    },
  );
}

/// `lvLys .5s 6.3s` — a lamp flickering on.
class _Lys extends StatelessWidget {
  const _Lys({required this.size, required this.farger});

  final double size;
  final List<Color> farger;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: 6800,
    builder: (context, t, child) {
      final p = cssEaseOut.transform(kfP(t, 6300, 500));
      final o = kf(p, const [0, .2, .35, .55, 1], const [0, 1, .25, 1, 1]);
      return Opacity(opacity: o.clamp(0.0, 1.0), child: child);
    },
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: farger, stops: const [0, .3, .7]),
      ),
    ),
  );
}

/// The parked bike (prototype SVG, viewBox 360 → 120).
class _ParkertSykkel extends CustomPainter {
  const _ParkertSykkel();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 360);
    Paint strek(Color c, double w) => Paint()
      ..color = c
      ..strokeWidth = w
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawCircle(const Offset(92, 292), 48, strek(const Color(0xFF16242A), 11));
    canvas.drawCircle(const Offset(92, 292), 41, strek(const Color(0xFFCFE3EA), 2.5));
    canvas.drawCircle(const Offset(242, 270), 40, strek(const Color(0xFF16242A), 10));
    canvas.drawCircle(const Offset(242, 270), 34, strek(const Color(0xFFCFE3EA), 2.5));
    canvas.drawPath(
      svgSti('M92 292 L74 254 M92 292 L132 302 M92 292 L62 322 M92 292 L104 336 M242 270 L268 242 M242 270 L212 288 M242 270 L262 302 M242 270 L236 232'),
      strek(const Color(0xFF8FA4AA), 1.6),
    );
    final ramme = svgSti('M242 270 L168 282 L186 196 L118 200 Z M168 282 L118 200 M118 200 L92 292');
    canvas.drawPath(ramme, strek(const Color(0xFF1E3A40), 12));
    canvas.drawPath(ramme, strek(const Color(0xFF9FD0DC), 6.5));
    canvas.drawPath(svgSti('M186 196 L182 184'), strek(const Color(0xFF1E3A40), 6));
    canvas.drawPath(svgSti('M172 182 L204 184'), strek(const Color(0xFF16242A), 10));
    canvas.drawPath(svgSti('M118 200 L112 176 L134 170'), strek(const Color(0xFF16242A), 7));
    canvas.drawPath(svgSti('M168 282 L186 338'), strek(const Color(0xFF16242A), 5));
    canvas.drawCircle(const Offset(168, 282), 10, Paint()..color = const Color(0xFF16242A));
    canvas.drawCircle(const Offset(92, 292), 5, Paint()..color = const Color(0xFF16242A));
    canvas.drawCircle(const Offset(242, 270), 5, Paint()..color = const Color(0xFF16242A));
    canvas.drawCircle(const Offset(104, 206), 7, Paint()..color = const Color(0xFFF2EEDC));
    canvas.drawCircle(const Offset(104, 206), 7, strek(const Color(0xFF16242A), 3));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// The van variant (172 × 172): the van, Ægil in it from 6.05 s, rolling off.
class _Bil extends StatelessWidget {
  const _Bil();

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: 9800,
    builder: (context, t, child) {
      final k = const Cubic(.5, 0, .92, .55).transform(kfP(t, 7200, 2500));
      return Transform.translate(offset: Offset(-430 * k, 0), child: child);
    },
    child: SizedBox(
      width: 172,
      height: 172,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: _Speil(height: 172, origin: .765, fadeTo: .62, child: _BilKropp(speil: true))),
          const Positioned.fill(child: _BilKropp()),
        ],
      ),
    ),
  );
}

class _BilKropp extends StatelessWidget {
  const _BilKropp({this.speil = false});

  final bool speil;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: 7500,
    builder: (context, t, _) {
      final h = cssEaseOut.transform(kfP(t, 6000, 500));
      const st = [0.0, .3, .6, 1.0];
      final y = kf(h, st, const [0, -6, 1, 0]);
      final sx = kf(h, st, const [1, .98, 1.03, 1]);
      final sy = kf(h, st, const [1, 1.04, .96, 1]);
      return Transform(
        alignment: const Alignment(0, .53),
        transform: Matrix4.translationValues(0, y, 0)..scaleByDouble(sx, sy, 1, 1),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            LfLoop(
              builder: (context, t, child) {
                final e = t - 6400;
                final p = e < 0 ? 0.0 : (e / 300) % 1.0;
                final ty = kf(p, const [0, .5, 1], const [0, -1.2, 0], cssEaseInOut);
                final r = kf(p, const [0, .5, 1], const [0, -.8, 0], cssEaseInOut);
                return Transform(alignment: const Alignment(0, .52), transform: Matrix4.translationValues(0, ty, 0)..rotateZ(rad(r)), child: child);
              },
              child: aegil('van', w: 172, h: 172),
            ),
            if (!speil) ...[
              Positioned(left: 5, top: 93, child: _Lys(size: 18, farger: const [Color(0xFFFFFCEC), Color(0x99FFEEC4), Color(0x00FFDC96)])),
              Positioned(left: 36, top: 93, child: _Lys(size: 18, farger: const [Color(0xFFFFFCEC), Color(0x99FFEEC4), Color(0x00FFDC96)])),
              Positioned(left: 154, top: 96, child: _Lys(size: 14, farger: const [Color(0xFFFF7864), Color(0x8CFF281E), Color(0x00FF140A)])),
            ],
          ],
        ),
      );
    },
  );
}

/// Ægil waving on the step, then walking to the vehicle and fading
/// (`lvGaa 2.1s 3.9s linear`, `aegUt .2s 5.95s`), with his reflection.
class _AegilDrar extends StatelessWidget {
  const _AegilDrar();

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: 6200,
    builder: (context, t, child) {
      final g = kfP(t, 3900, 2100);
      const st = [0.0, .12, .24, .55, .7, .8, 1.0];
      final x = kf(g, st, const [0, -5, -10, -26, -33, -37, -46]);
      final y = kf(g, st, const [0, 7, 14, 24, 29, 35, 42]);
      final k = kf(g, st, const [1, 1.01, 1.03, 1.12, 1.17, 1.21, 1.3]);
      final ut = cssEaseOut.transform(kfP(t, 5950, 200));
      return Opacity(
        opacity: 1 - ut,
        child: Transform(alignment: const Alignment(0, .9), transform: Matrix4.translationValues(x, y, 0)..scaleByDouble(k, k, 1, 1), child: child),
      );
    },
    child: SizedBox(
      width: 66,
      height: 66,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: _Speil(height: 66, origin: .95, alpha: .18, fadeTo: .55, child: const _AegilSteg())),
          const Positioned.fill(child: _AegilSteg()),
        ],
      ),
    ),
  );
}

/// front.png waving until 3.9 s, then side.png stepping (`lvSteg .35s ×6`).
class _AegilSteg extends StatelessWidget {
  const _AegilSteg();

  @override
  Widget build(BuildContext context) => LfLoop(
    builder: (context, t, _) {
      final bytt = cssEaseOut.transform(kfP(t, 3900, 180));
      final e = t - 3900;
      final p = e < 0 || e >= 350 * 6 ? 0.0 : (e / 350) % 1.0;
      final sy = kf(p, const [0, .5, 1], const [0, -2.5, 0], cssEaseInOut);
      final sr = kf(p, const [0, .5, 1], const [0, -2, 0], cssEaseInOut);
      return Stack(
        children: [
          Opacity(opacity: 1 - bytt, child: spVink(aegil('front', w: 66, h: 66), dur: 2400)),
          Opacity(
            opacity: bytt,
            child: Transform(alignment: const Alignment(0, .9), transform: Matrix4.translationValues(0, sy, 0)..rotateZ(rad(sr)), child: aegil('side', w: 66, h: 66)),
          ),
        ],
      );
    },
  );
}

/// Ægil staying on the step and waving (pickup, partner).
class _AegilBlir extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(width: 66, height: 66, child: spVink(aegil('front', w: 66, h: 66), dur: 2400));
}

/// Kept for parity with the kitchen's blurred glows.
Widget spBlur(Widget child, double sigma) => ImageFiltered(
  imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
  child: child,
);
