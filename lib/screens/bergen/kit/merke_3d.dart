import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../common/splash/splash_sticker_painter.dart';

// ── The 3D Æ block of the loaders (Bergen 29 Oct, `data-lsd-logo` /
// `data-lss-logo`) ──────────────────────────────────────────────────────────
// `merke-kant` layers sit 1px apart behind the face (`merke-flate`), the
// sheen (`#last-sheen`, a skewed band masked by the outline) just in front.
// The whole block turns with `rotateX`/`rotateY` under a CSS perspective and
// may be moved along z (the screen loader flies it in from −700 and out to
// +600).

/// The puck's block: 46×37, four depth layers (`data-lsd-logo`).
const List<Color> kMerkeLagPuck = [Color(0xFF7D949C), Color(0xFF98ADB3), Color(0xFFB7C6CB), Color(0xFFD5DEE1)];

/// The screen loader's block: 132×106, nine depth layers (`data-lss-logo`).
const List<Color> kMerkeLagSkjerm = [
  Color(0xFF6F8790),
  Color(0xFF7D949C),
  Color(0xFF8CA2A9),
  Color(0xFF98ADB3),
  Color(0xFFA9BAC0),
  Color(0xFFB7C6CB),
  Color(0xFFC9D4D8),
  Color(0xFFD5DEE1),
  Color(0xFFE1E7EA),
];

class Merke3D extends StatelessWidget {
  const Merke3D({
    super.key,
    required this.width,
    required this.height,
    required this.lag,
    this.perspektiv = 220,
    this.rx = 0,
    this.ry = 0,
    this.x = 0,
    this.y = 0,
    this.z = 0,
    this.skala = 1,
    this.glansX = 0,
    this.glansZ = .4,
  });

  final double width, height;

  /// Depth colours, deepest first (`translateZ(-n)` … `translateZ(-1)`).
  final List<Color> lag;

  /// CSS `perspective` of the parent (220 on the puck, 760 on the screen).
  final double perspektiv;

  /// `rotateX` / `rotateY` in degrees.
  final double rx, ry;

  /// `translate3d(x, y, z)` in px (z toward the viewer).
  final double x, y, z;
  final double skala;

  /// `translateX` of the sheen band in the mark's SVG space (0 → 230).
  final double glansX;

  /// `translateZ` of the sheen layer (.4 on the puck, .6 on the screen).
  final double glansZ;

  @override
  Widget build(BuildContext context) {
    final n = lag.length;
    Matrix4 m(double dz) => Matrix4.identity()
      ..setEntry(3, 2, -1 / perspektiv)
      ..translateByDouble(x, y, z, 1)
      ..rotateX(rx * math.pi / 180)
      ..rotateY(ry * math.pi / 180)
      ..scaleByDouble(skala, skala, 1, 1)
      ..translateByDouble(0, 0, dz, 1);
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < n; i++)
            Positioned.fill(
              child: Transform(
                alignment: Alignment.center,
                transform: m(-(n - i).toDouble()),
                child: CustomPaint(painter: MerkeKantPainter(lag[i])),
              ),
            ),
          Positioned.fill(
            child: Transform(
              alignment: Alignment.center,
              transform: m(0),
              child: const CustomPaint(painter: MerkeFlatePainter()),
            ),
          ),
          Positioned.fill(
            child: Transform(
              alignment: Alignment.center,
              transform: m(glansZ),
              child: CustomPaint(painter: SplashSheenPainter(translateX: glansX, opacity: 1, bandWidth: 46, bandX: -70)),
            ),
          ),
        ],
      ),
    );
  }
}
