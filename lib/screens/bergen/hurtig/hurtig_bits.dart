import 'package:flutter/material.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart' show LfPress;
import '../kit/svg_sti.dart';

// ── Hurtigbestilling · small pieces shared by the screen and its cards ─────

const Color kHbInk = Color(0xFF23201D);
const Color kHbInkSoft = Color(0xFF57534B);
const Color kHbInkFaint = Color(0xFF6B655D);
const Color kHbTeal = Color(0xFF2A6272);
const Color kHbTealDeep = Color(0xFF1E4F5C);
const Color kHbMint = Color(0xFF5CE0B8);
const Color kHbMintPale = Color(0xFF9FF0D4);

/// `cubic-bezier(.2,1.2,.3,1)` (`vcMeg`, `vcBoble`).
const Cubic kVcBoble = Cubic(.2, 1.2, .3, 1);

/// `cubic-bezier(.2,1.15,.3,1)` (`vcKort`).
const Cubic kVcKort = Cubic(.2, 1.15, .3, 1);

/// `cubic-bezier(.2,1.3,.3,1)` (`vcKnapp`).
const Cubic kVcKnapp = Cubic(.2, 1.3, .3, 1);

const List<FontFeature> kTabular = [FontFeature.tabularFigures()];

TextStyle hbJ(double size, {double em = 0, double? height, Color color = kHbInk, FontWeight weight = FontWeight.w800, bool tabular = false, List<Shadow>? shadows}) =>
    jakarta(size, em: em, height: height, color: color, weight: weight, shadows: shadows).copyWith(fontFeatures: tabular ? kTabular : null);

TextStyle hbI(double size, {FontWeight weight = FontWeight.w600, double em = 0, double? height, Color color = kHbInk, bool tabular = false}) =>
    inter(size, weight: weight, em: em, height: height, color: color).copyWith(fontFeatures: tabular ? kTabular : null);

// ── icons ───────────────────────────────────────────────────────────────────

/// The prototype's inline 24-box SVG icons.
abstract final class HbIkoner {
  static const String lyn = 'M13 2L4 14h7l-1 8 9-12h-7z';
  static const String tilbake = 'M15 6l-6 6 6 6';
  static const String omstart = 'M3 12a9 9 0 1 0 3-6.7L3 8M3 3v5h5';
  static const String pluss = 'M12 5v14M5 12h14';
  static const String minus = 'M5 12h14';
  static const String hake = 'M5 12l5 5 9-10';
  static const String kryss = 'M6 6l12 12M18 6L6 18';
  static const String videre = 'M9 6l6 6-6 6';
  static const String klokke = 'M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18M12 7v5l3 2';
  static const String pin = 'M12 2a7 7 0 0 0-7 7c0 5.2 7 13 7 13s7-7.8 7-13a7 7 0 0 0-7-7zm0 9.6a2.6 2.6 0 1 1 0-5.2 2.6 2.6 0 0 1 0 5.2z';
  static const String kort = 'M5.5 6h13a2.5 2.5 0 0 1 2.5 2.5v8a2.5 2.5 0 0 1-2.5 2.5h-13a2.5 2.5 0 0 1-2.5-2.5v-8a2.5 2.5 0 0 1 2.5-2.5zM3 10.5h18';
  static const String kurv = 'M3 4h2.5l2.2 11h10.6l2-8H6.6M9.5 18.1a1.4 1.4 0 1 0 0 2.8a1.4 1.4 0 1 0 0-2.8M17 18.1a1.4 1.4 0 1 0 0 2.8a1.4 1.4 0 1 0 0-2.8';
  static const String tidBytt = 'M7 4l-4 4 4 4M3 8h14a4 4 0 0 1 0 8h-3';
  static const String modOftest = 'M3 17l5-5 4 4 8-8M15 8h5v5';
  static const String modForrige = 'M3 12a9 9 0 1 0 3-6.7L3 8M3 3v5h5M12 7.5V12l3 2';
  static const String modPref = 'M4 7h9M17 7h3M4 17h3M11 17h9M15 5v4M9 15v4';
  static const String send = 'M12 19V5M5.5 11.5L12 5l6.5 6.5';
}

/// One SVG icon: stroked (round caps and joins) or filled.
class HbIkon extends StatelessWidget {
  const HbIkon(this.d, {super.key, required this.size, this.stroke, this.width = 2.4, this.fill});

  final String d;
  final double size;
  final Color? stroke;
  final double width;
  final Color? fill;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _IkonPainter(d, stroke, width, fill));
}

class _IkonPainter extends CustomPainter {
  const _IkonPainter(this.d, this.stroke, this.width, this.fill);
  final String d;
  final Color? stroke;
  final double width;
  final Color? fill;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    canvas.scale(k, k);
    final path = svgSti(d);
    if (fill != null) canvas.drawPath(path, Paint()..color = fill!);
    if (stroke != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = stroke!
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_IkonPainter o) => o.d != d || o.stroke != stroke || o.width != width || o.fill != fill;
}

// ── the store tile ──────────────────────────────────────────────────────────

/// The initials tile (`r.ini` on `r.bg`): inset top light, dark bottom
/// edge, the gloss and the lettering with its 1px shadow.
class HbFlis extends StatelessWidget {
  const HbFlis({super.key, required this.ini, required this.bg, this.fg = Colors.white, required this.size, required this.radius, required this.fontSize});

  final String ini;
  final Color bg;
  final Color fg;
  final double size;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final gr = radius - 3;
    return CssBox(
      width: size,
      height: size,
      radius: BorderRadius.circular(radius),
      clip: true,
      bg: [CssSolid(bg)],
      shadows: const [
        CssShadow.inset(0, 2, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
        CssShadow.inset(0, -3, 0, 0, Color.fromRGBO(0, 0, 0, .18)),
        CssShadow(0, 3, 0, 0, Color.fromRGBO(12, 24, 28, .3)),
        CssShadow(0, 10, 14, -8, Color.fromRGBO(3, 16, 24, .7)),
      ],
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 4,
            right: 4,
            top: 3,
            height: size * .44,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.elliptical(gr, gr),
                  topRight: Radius.elliptical(gr, gr),
                  bottomLeft: Radius.elliptical(size / 2, 8),
                  bottomRight: Radius.elliptical(size / 2, 8),
                ),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.fromRGBO(255, 255, 255, .34), Color.fromRGBO(255, 255, 255, 0)],
                ),
              ),
            ),
          ),
          Text(ini, style: hbJ(fontSize, em: -.01, color: fg, shadows: const [Shadow(color: Color.fromRGBO(0, 0, 0, .28), offset: Offset(0, 1))])),
        ],
      ),
    );
  }
}

// ── the orange key's gloss ──────────────────────────────────────────────────

/// An orange key face with its gloss: [height] tall, [radius] round.
class HbOransje extends StatelessWidget {
  const HbOransje({
    super.key,
    required this.height,
    required this.radius,
    required this.child,
    this.width,
    this.edge = 3,
    this.glossInset = 8,
    this.glossTop = 11,
    this.glossBottom = 20,
    this.padding,
    this.deep = const CssShadow(0, 10, 14, -8, Color.fromRGBO(120, 40, 10, .6)),
    this.extra = const [],
  });

  final double height;
  final double? width;
  final double radius;
  final double edge;
  final double glossInset;
  final double glossTop;
  final double glossBottom;
  final EdgeInsets? padding;
  final CssShadow deep;
  final List<CssShadow> extra;
  final Widget child;

  @override
  Widget build(BuildContext context) => CssBox(
    height: height,
    width: width,
    radius: BorderRadius.circular(radius),
    clip: true,
    bg: const [CssLinear(180, [Color(0xFFFFA77C), Color(0xFFF26D3D), Color(0xFFE95C2C)], [0, .55, 1])],
    shadows: [
      const CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .5)),
      const CssShadow.inset(0, -2, 0, 0, Color.fromRGBO(0, 0, 0, .08)),
      CssShadow(0, edge, 0, 0, const Color(0xFFA63A12)),
      deep,
      ...extra,
    ],
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: glossInset,
          right: glossInset,
          top: 2,
          height: height * .46,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.elliptical(glossTop, glossTop),
                  topRight: Radius.elliptical(glossTop, glossTop),
                  bottomLeft: Radius.elliptical(glossBottom, glossBottom * .4),
                  bottomRight: Radius.elliptical(glossBottom, glossBottom * .4),
                ),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.fromRGBO(255, 255, 255, .32), Color.fromRGBO(255, 255, 255, 0)],
                ),
              ),
            ),
          ),
        ),
        Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ],
    ),
  );
}

// ── entrance animations ─────────────────────────────────────────────────────

/// `vcKort .5s [delay] cubic-bezier(.2,1.15,.3,1) both`: up 14px, scale .96.
class VcKort extends StatelessWidget {
  const VcKort({super.key, required this.child, this.delayMs = 0});
  final Widget child;
  final double delayMs;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: 500 + delayMs,
    child: child,
    builder: (context, t, child) {
      final p = kVcKort.transform(kfP(t, delayMs, 500));
      return Opacity(
        opacity: p.clamp(0.0, 1.0),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.translationValues(0, 14 * (1 - p), 0)..scaleByDouble(.96 + .04 * p, .96 + .04 * p, 1, 1),
          child: child,
        ),
      );
    },
  );
}

/// `vcBoble .4s cubic-bezier(.2,1.2,.3,1)` from the bottom-left corner.
class VcBoble extends StatelessWidget {
  const VcBoble({super.key, required this.child, this.ms = 400});
  final Widget child;
  final double ms;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: ms,
    child: child,
    builder: (context, t, child) {
      final p = kVcBoble.transform(kfP(t, 0, ms));
      return Opacity(
        opacity: p.clamp(0.0, 1.0),
        child: Transform(
          alignment: Alignment.bottomLeft,
          transform: Matrix4.translationValues(-6 * (1 - p), 10 * (1 - p), 0)..scaleByDouble(.9 + .1 * p, .9 + .1 * p, 1, 1),
          child: child,
        ),
      );
    },
  );
}

/// `vcMeg .38s cubic-bezier(.2,1.2,.3,1)` from the bottom-right corner.
class VcMeg extends StatelessWidget {
  const VcMeg({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: 380,
    child: child,
    builder: (context, t, child) {
      final p = kVcBoble.transform(kfP(t, 0, 380));
      return Opacity(
        opacity: p.clamp(0.0, 1.0),
        child: Transform(
          alignment: Alignment.bottomRight,
          transform: Matrix4.translationValues(10 * (1 - p), 12 * (1 - p), 0)..scaleByDouble(.88 + .12 * p, .88 + .12 * p, 1, 1),
          child: child,
        ),
      );
    },
  );
}

/// `vcKnapp .4s <delay> cubic-bezier(.2,1.3,.3,1)`: up 8px, scale .85.
class VcKnapp extends StatelessWidget {
  const VcKnapp({super.key, required this.child, this.delayMs = 0, this.ms = 400});
  final Widget child;
  final double delayMs;
  final double ms;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: ms + delayMs,
    child: child,
    builder: (context, t, child) {
      final p = kVcKnapp.transform(kfP(t, delayMs, ms));
      return Opacity(
        opacity: p.clamp(0.0, 1.0),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.translationValues(0, 8 * (1 - p), 0)..scaleByDouble(.85 + .15 * p, .85 + .15 * p, 1, 1),
          child: child,
        ),
      );
    },
  );
}

/// `style-active` press: translateY / scale with the CSS transition.
class HbPress extends StatelessWidget {
  const HbPress({super.key, required this.child, required this.onTap, this.dy = 0, this.scale = 1, this.ms = 120});
  final Widget child;
  final VoidCallback? onTap;
  final double dy;
  final double scale;
  final int ms;

  @override
  Widget build(BuildContext context) => LfPress(dy: dy, scale: scale, ms: ms, onTap: onTap, child: child);
}

/// `repeating-linear-gradient(90deg, ink .22 0 4px, transparent 4px 8px)`.
class HbStiplet extends StatelessWidget {
  const HbStiplet({super.key, this.color = const Color.fromRGBO(35, 32, 29, .22), this.dash = 4, this.gap = 4});
  final Color color;
  final double dash;
  final double gap;

  @override
  Widget build(BuildContext context) => SizedBox(height: 1, width: double.infinity, child: CustomPaint(painter: _StipletPainter(color, dash, gap)));
}

class _StipletPainter extends CustomPainter {
  const _StipletPainter(this.color, this.dash, this.gap);
  final Color color;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawRect(Rect.fromLTWH(x, 0, dash, size.height), p);
    }
  }

  @override
  bool shouldRepaint(_StipletPainter o) => o.color != color || o.dash != dash || o.gap != gap;
}

/// The perforation under the receipt: white half-discs every 10px.
class HbPerforering extends StatelessWidget {
  const HbPerforering({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(height: 6, width: double.infinity, child: CustomPaint(painter: _PerfPainter()));
}

class _PerfPainter extends CustomPainter {
  const _PerfPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white;
    for (var x = 5.0; x < size.width + 5; x += 10) {
      canvas.drawCircle(Offset(x, 0), 5, p);
    }
  }

  @override
  bool shouldRepaint(_PerfPainter o) => false;
}
