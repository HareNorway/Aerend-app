import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../splash/splash_sticker_painter.dart';
import 'lf_css.dart';
import 'lf_motion.dart';

// ── Laster ──────────────────────────────────────────────────────────────────
// `data-screen-label="Laster"` (prototype L1819), tone "Mørk glass": the Æ
// sticker flipping in 3D with speed streaks, a mint glow, a squashing
// shadow and three bouncing dots under "Henter ærendet". Used while an auth
// call is in flight.

class LfLaster extends StatelessWidget {
  const LfLaster({super.key, this.text = 'Henter ærendet'});

  final String text;

  static const Cubic _io = Cubic(.65, 0, .35, 1);
  static const Cubic _inn = Cubic(.2, 1.25, .4, 1);

  @override
  Widget build(BuildContext context) {
    return LfOnce(
      ms: 360,
      builder: (context, t, child) => Opacity(
        // karmInn .16s ease-out
        opacity: cssEaseOut.transform(kfP(t, 0, 160)),
        child: child,
      ),
      child: ColoredBox(
        color: const Color.fromRGBO(15, 31, 43, .9),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LfOnce(
                ms: 360,
                builder: (context, t, child) {
                  final p = _inn.transform(kfP(t, 0, 360));
                  final m = Matrix4.identity()
                    ..setEntry(3, 2, -1 / 560)
                    ..translateByDouble(0, 30 * (1 - p), 0, 1)
                    ..scaleByDouble(.5 + .5 * p, .5 + .5 * p, 1, 1)
                    ..rotateX(rad(48 * (1 - p)));
                  return Opacity(
                    opacity: p.clamp(0.0, 1.0),
                    child: Transform(transform: m, alignment: Alignment.center, child: child),
                  );
                },
                child: const RepaintBoundary(child: _Card()),
              ),
              const SizedBox(height: 26),
              Text(text, style: jakarta(14, em: -.01)),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    LfLoop(
                      builder: (context, t, child) {
                        final p = kfLoop(t, 130.0 * i, 800) ?? 0;
                        final y = kf(p, const [0, .5, 1], const [0, -4, 0], cssEaseInOut);
                        final o = kf(p, const [0, .5, 1], const [.4, 1, .4], cssEaseInOut);
                        return Opacity(
                          opacity: o,
                          child: Transform.translate(offset: Offset(0, y), child: child),
                        );
                      },
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF5CE0B8),
                          boxShadow: [
                            BoxShadow(color: Color.fromRGBO(92, 224, 184, .8), blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 160,
      child: LfLoop(
        builder: (context, t, _) {
          final p = (t / 1600) % 1.0;
          const io = LfLaster._io;
          // lastGlod
          final gO = kf(p, const [0, .56, 1], const [.35, .75, .35], io);
          final gS = kf(p, const [0, .56, 1], const [1, 1.25, 1], io);
          // lastSkygge
          final sx = kf(p, const [0, .16, .56, .84, 1], const [1, .92, .5, .96, 1], io);
          final sy = kf(p, const [0, .16, .56, .84, 1], const [1, .9, .62, .96, 1], io);
          final sO = kf(p, const [0, .16, .56, .84, 1], const [.6, .5, .22, .55, .6], io);
          // lastFlip
          const st = <double>[0, .16, .56, .84, 1];
          final fy = kf(p, st, const [0, -5, -16, -3, 0], io);
          final ry = kf(p, st, const [0, -14, 180, 360, 360], io);
          final rx = kf(p, st, const [0, -10, 6, -3, 0], io);
          final rz = kf(p, st, const [0, 2, -2, 0, 0], io);
          final flip = Matrix4.identity()
            ..setEntry(3, 2, -1 / 560)
            ..translateByDouble(0, fy, 0, 1)
            ..rotateY(rad(ry))
            ..rotateX(rad(rx))
            ..rotateZ(rad(rz));
          final yy = ry % 360;
          final showBack = yy > 90 && yy < 270;
          // lastGlansSvg
          final gx = kf(p, const [0, .6, .92, 1], const [0, 0, 230, 230], io);
          final go = kf(p, const [0, .6, .68, .92, 1], const [0, 0, 1, 0, 0], io);

          Widget streak(double left, double top, double w, double h, Color c, double delay) {
            final q = ((t - delay) / 1600) % 1.0;
            final sxx = kf(q, const [0, .14, .34, .62, 1], const [0, 0, 1, .15, 0], io);
            final tx = kf(q, const [0, .14, .34, .62, 1], const [0, 0, 0, -40, 0], io);
            final o = kf(q, const [0, .14, .34, .62, 1], const [0, 0, 1, 0, 0], io);
            return Positioned(
              left: left,
              top: top,
              width: w,
              height: h,
              child: Opacity(
                opacity: o.clamp(0.0, 1.0),
                child: Transform(
                  alignment: Alignment.centerRight,
                  transform: Matrix4.diagonal3Values(math.max(sxx, 0.0001), 1, 1)
                    ..translateByDouble(tx, 0, 0, 1),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: LinearGradient(colors: [c.withValues(alpha: 0), c]),
                    ),
                  ),
                ),
              ),
            );
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Glow (blur 16 baked into a wider radial).
              Positioned(
                left: 40 - 16,
                top: 34 - 16,
                width: 110 + 32,
                height: 80 + 32,
                child: Opacity(
                  opacity: gO,
                  child: Transform.scale(
                    scale: gS,
                    child: const CssBox(
                      bg: [
                        CssRadial.closestSide(
                          [Color.fromRGBO(92, 224, 184, .42), Color.fromRGBO(92, 224, 184, .16), Color.fromRGBO(92, 224, 184, 0)],
                          stops: [0, .45, .85],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 40,
                top: 126,
                width: 110,
                height: 20,
                child: Opacity(
                  opacity: sO,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(sx, sy, 1),
                    child: const CssBox(
                      bg: [
                        CssRadial(
                          [Color.fromRGBO(3, 16, 24, .7), Color.fromRGBO(3, 16, 24, 0)],
                          stops: [0, .8],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              streak(-6, 62, 56, 6, const Color(0xFFF26D3D), 0),
              streak(2, 78, 40, 6, const Color(0xFFF26D3D), 60),
              streak(-14, 94, 64, 5, const Color.fromRGBO(255, 255, 255, .7), 120),
              Positioned(
                left: 20,
                top: 14,
                width: 150,
                height: 120,
                child: Transform(
                  alignment: Alignment.center,
                  transform: flip,
                  child: showBack
                      ? Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(math.pi),
                          child: const CustomPaint(painter: LasterBackPainter()),
                        )
                      : Stack(
                          children: [
                            const Positioned.fill(child: CustomPaint(painter: SplashStickerPainter())),
                            Positioned.fill(
                              child: CustomPaint(
                                painter: SplashSheenPainter(
                                  translateX: gx,
                                  opacity: go,
                                  bandWidth: 46,
                                  bandX: -70,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
