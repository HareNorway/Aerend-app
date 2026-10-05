import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../bergen/kit/sjo_water.dart';
import 'lf_css.dart';
import 'lf_motion.dart';

// ── Velkommen · Bryggen ─────────────────────────────────────────────────────
// `data-screen-label="Velkommen · Bryggen"` (prototype L1957): the rain sky,
// Bryggen seen from Nordnes (`canvas[data-brgl="fiske"]`), Vågen
// (`canvas[data-sjogl="fiske"]`), the raft with Ægil and his speech bubble.
//
// Bryggen is the prototype's own WebGL render (rain palette, 4×) baked into
// `assets/images/onboarding/bryggen_regn.jpg`: a static layer, drawn once
// (performance rule: bake expensive scenes). The water is the prototype's
// fragment shader, ported to `shaders/sjo.frag`, animated, reflecting that
// same image the way `sjoRefBr` does.

const String kBryggenAsset = 'assets/images/onboarding/bryggen_regn.jpg';

/// `VAER.regn.himmel` — `linear-gradient(180deg,#B7C6D2 0%,#C6D2DA 30%,#D3DCDF 58%,#C9D3D5 100%)`.
const CssLinear kRegnHimmel = CssLinear(180, [
  Color(0xFFB7C6D2),
  Color(0xFFC6D2DA),
  Color(0xFFD3DCDF),
  Color(0xFFC9D3D5),
], [0, .3, .58, 1]);

class LfWelcomeScene extends StatelessWidget {
  const LfWelcomeScene({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 390,
      height: 352,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Mask: #000 74% → transparent 100%.
          Positioned.fill(
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (r) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.black, Colors.transparent],
                stops: [0, .74, 1],
              ).createShader(r),
              child: ClipRect(
                child: Stack(
                  children: [
                    const Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 230,
                      child: CssBox(bg: [kRegnHimmel]),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      width: 390,
                      height: 223,
                      child: Image.asset(
                        kBryggenAsset,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.medium,
                        gaplessPlayback: true,
                      ),
                    ),
                    const Positioned(
                      left: 0,
                      right: 0,
                      top: 223,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF2C6474), Color(0xFF163C48)],
                          ),
                        ),
                        child: RepaintBoundary(
                          child: SjoWater(
                            palette: SjoPalette.kveld,
                            regn: .5,
                            reflection: kBryggenAsset,
                            reflectionHeight: 223,
                            fogColor: Color(0xFFC9D3D5),
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 110,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x80081A22), Color(0x00081A22)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(left: 178, top: 290, width: 112, height: 40, child: _Raft()),
          Positioned(
            left: 178,
            top: 178,
            width: 112,
            height: 126,
            child: RepaintBoundary(
              child: LfLoop(
                builder: (context, t, child) => Transform(
                  transform: _flaateVugg(t),
                  alignment: Alignment.center,
                  child: child,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: -7,
                      top: 0,
                      width: 126,
                      height: 126,
                      child: LfLoop(
                        builder: (context, t, child) => Transform(
                          transform: aegStaa(t, 3600),
                          alignment: Alignment.bottomCenter,
                          child: child,
                        ),
                        child: Image.asset(
                          'assets/images/aegil/aegil_landing.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(left: 22, top: 150, child: _HeiBubble()),
        ],
      ),
    );
  }
}

/// `flaateVugg 6s ease-in-out infinite`.
Matrix4 _flaateVugg(double t) {
  final p = (t / 6000) % 1.0;
  final y = kf(p, const [0, .3, .7, 1], const [0, 1.5, -1, 0], cssEaseInOut);
  final r = kf(p, const [0, .3, .7, 1], const [0, .35, -.3, 0], cssEaseInOut);
  return Matrix4.translationValues(0, y, 0)..rotateZ(rad(r));
}

class _Raft extends StatelessWidget {
  const _Raft();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final (delay, w, a) in const [(0.0, 1.3, .5), (2300.0, 1.0, .35)])
            Positioned(
              left: -26,
              right: -26,
              top: 14,
              height: 26,
              child: LfLoop(
                builder: (context, t, child) {
                  final p = kfLoop(t, delay, 4600);
                  if (p == null) return const SizedBox.shrink();
                  final e = cssEaseOut.transform(p);
                  final s = .55 + (1.6 - .55) * e;
                  final o = p < .18 ? kf(p, const [0, .18], const [0, .5], cssEaseOut) : kf(p, const [.18, 1], const [.5, 0], cssEaseOut);
                  return Opacity(
                    opacity: o.clamp(0.0, 1.0),
                    child: Transform.scale(scale: s, child: child),
                  );
                },
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: OvalBorder(
                      side: BorderSide(color: Color.fromRGBO(214, 242, 250, a), width: w),
                    ),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: LfLoop(
              builder: (context, t, child) => Transform(
                transform: _flaateVugg(t),
                alignment: Alignment.center,
                child: child,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 6,
                    height: 12,
                    child: CustomPaint(painter: _PlankPainter()),
                  ),
                  const Positioned(
                    left: 3,
                    right: 3,
                    top: 16,
                    height: 9,
                    child: CssBox(
                      radius: BorderRadius.vertical(bottom: Radius.circular(6)),
                      bg: [CssLinear(180, [Color(0xFF8A5A2C), Color(0xFF5E3A1A)])],
                    ),
                  ),
                  Positioned(
                    left: -2,
                    right: -2,
                    top: 20,
                    height: 10,
                    child: CustomPaint(painter: _RaftWaterPainter()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The plank top: `border-radius:6px 6px 3px 3px`, wood gradient with 1px
/// grain every 18px and an `inset 0 1.5px 0` highlight.
class _PlankPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final rr = RRect.fromRectAndCorners(
      r,
      topLeft: const Radius.circular(6),
      topRight: const Radius.circular(6),
      bottomLeft: const Radius.circular(3),
      bottomRight: const Radius.circular(3),
    );
    canvas.save();
    canvas.clipRRect(rr);
    canvas.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE3B272), Color(0xFFB47A42)],
        ).createShader(r),
    );
    final grain = Paint()..color = const Color.fromRGBO(60, 32, 12, .5);
    for (double x = 0; x < size.width; x += 18) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), grain);
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 1.5),
      Paint()..color = const Color.fromRGBO(255, 236, 200, .7),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// `border-radius:0 0 50% 50%/0 0 80% 80%` water lip with a 1px light top.
class _RaftWaterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rx = w * .5, ry = h * .8;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h - ry)
      ..arcToPoint(Offset(w - rx, h), radius: Radius.elliptical(rx, ry))
      ..arcToPoint(Offset(0, h - ry), radius: Radius.elliptical(rx, ry))
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.fromRGBO(60, 140, 160, .6), Color.fromRGBO(14, 52, 66, .85)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, 1),
      Paint()..color = const Color.fromRGBO(226, 248, 252, .8),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeiBubble extends StatelessWidget {
  const _HeiBubble();

  static const Cubic _c = Cubic(.3, 1.3, .5, 1);

  @override
  Widget build(BuildContext context) {
    final bubble = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 150 + 26), // content-box max-width + padding
      child: CssBox(
        radius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(6),
          bottomLeft: Radius.circular(18),
        ),
        bg: const [CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFF2EFE8)])],
        shadows: const [
          CssShadow.inset(0, -2, 0, 0, Color.fromRGBO(180, 171, 160, .35)),
          CssShadow(0, 3, 0, 0, Color.fromRGBO(8, 28, 36, .35)),
          CssShadow(0, 16, 24, -12, Color.fromRGBO(3, 14, 20, .75)),
        ],
        padding: const EdgeInsets.fromLTRB(13, 10, 13, 11),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  LfHeiCopy.title,
                  style: jakarta(17, em: -.02, height: 1.1, color: const Color(0xFF1E4F5C)),
                ),
                const SizedBox(height: 3),
                Text(
                  LfHeiCopy.sub,
                  style: inter(11, weight: FontWeight.w700, height: 1.35, color: const Color(0xFF57534B)),
                ),
              ],
            ),
            // Tail: right:-6px; bottom:8px (bubble padding offsets it).
            Positioned(
              right: -6 - 13,
              bottom: 8 - 11,
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2EFE8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    // bobleFraAegil .55s .5s: translateX(-14)→2→0, scale .7→1.03→1;
    // the keyframe starts at transform-origin 0 100% and eases to the
    // element's own 100% 100%.
    return LfOnce(
      ms: 1050,
      child: bubble,
      builder: (context, t, child) {
        final p = kfP(t, 500, 550);
        final x = kf(p, const [0, .6, 1], const [-14, 2, 0], _c);
        final s = kf(p, const [0, .6, 1], const [.7, 1.03, 1], _c);
        final o = kf(p, const [0, .6, 1], const [0, 1, 1], _c);
        final ox = _c.transform(p);
        return Opacity(
          opacity: o.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(x, 0),
            child: Transform.scale(
              scale: s,
              alignment: Alignment(-1 + 2 * ox, 1),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Copy for the welcome scene bubble.
abstract final class LfHeiCopy {
  static String title = 'Hei! Jeg er Ægil.';
  static String sub = 'Butikkene i Bergen, levert av ett bud.';
}
