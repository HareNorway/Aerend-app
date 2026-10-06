import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_kit.dart';
import 'fiske_copy.dart';
import 'fiske_frame.dart';
import 'fiske_motion.dart';

// ── icons (the design's inline 24-box SVGs) ─────────────────────────────────

typedef _IconDraw = void Function(Canvas c, Paint stroke);

class _Icon extends StatelessWidget {
  const _Icon(this.size, this.strokeWidth, this.draw);

  static const Color color = Colors.white;

  final double size;
  final double strokeWidth;
  final _IconDraw draw;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _IconPainter(strokeWidth, draw, color, null),
  );
}

class _IconPainter extends CustomPainter {
  const _IconPainter(this.strokeWidth, this.draw, this.color, this.fill);

  final double strokeWidth;
  final _IconDraw draw;
  final Color color;
  final Color? fill;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    if (fill != null) {
      final f = Paint()..color = fill!;
      draw(canvas, f);
    }
    draw(canvas, stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.strokeWidth != strokeWidth || old.color != color || old.fill != fill;
}

/// `M15 6l-6 6 6 6` — back.
void _chevron(Canvas c, Paint p) {
  c.drawPath(
    Path()
      ..moveTo(15, 6)
      ..lineTo(9, 12)
      ..lineTo(15, 18),
    p,
  );
}

// ── glass ───────────────────────────────────────────────────────────────────

/// `background:rgba(15,31,43,a);backdrop-filter:blur(b);border:1px
/// rgba(255,255,255,c);box-shadow:inset 0 1px 0 rgba(255,255,255,d), …`.
/// The outer shadow goes through [BergenCssShadow] so the glass stays clear.
class _Glass extends StatelessWidget {
  const _Glass({
    super.key,
    required this.radius,
    required this.child,
    this.shadows = const [],
    this.padding = EdgeInsets.zero,
    this.width,
    this.height,
    this.alignment,
  });

  final double radius;
  final Widget child;
  // `rgba(15,31,43,.45)`, `blur(18px)`, border `.3`, inset `.25`.
  static const double fill = .45, blur = 18, border = .3, inset = .25;
  final List<BoxShadow> shadows;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final r = BorderRadius.circular(radius);
    return BergenCssShadow(
      radius: radius,
      shadows: shadows,
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur * s, sigmaY: blur * s),
          child: Container(
            width: width,
            height: height,
            alignment: alignment,
            padding: padding,
            decoration: BoxDecoration(
              color: rgba(15, 31, 43, fill),
              borderRadius: r,
              border: Border.all(color: rgba(255, 255, 255, border)),
            ),
            child: Stack(
              alignment: alignment ?? Alignment.topLeft,
              children: [
                child,
                bergenInsetTop(radius: radius, height: 1 * s, alpha: inset),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The orange face the three round/pill buttons share:
/// `linear-gradient(180deg,#F9A273,#F26D3D 56%,#DD5A25)`.
const LinearGradient kFiskeOrange = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)],
  stops: [0, .56, 1],
);

// ── header ──────────────────────────────────────────────────────────────────

/// The header row (`padding:12px 16px 0`): the back button (`40×40;
/// radius 14; rgba(15,31,43,.45); blur 18; border rgba(255,255,255,.3);
/// inset 0 1px 0 rgba(255,255,255,.25), 0 8px 16px -8px rgba(15,31,43,.6)`,
/// pressed `scale(.92)`) and the status pill (`padding 7px 12px; 11.5px 800`
/// with the lantern dot `7px #F2C14E; lyktPuls 3s`).
class FiskeHeader extends StatelessWidget {
  const FiskeHeader({
    super.key,
    required this.kast,
    required this.av,
    required this.lagret,
    required this.onBack,
  });

  final int kast;
  final int av;
  final int lagret;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Padding(
      padding: EdgeInsets.fromLTRB(16 * s, 12 * s, 16 * s, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Semantics(
            button: true,
            label: FiskeCopy.a1_fiske_tilbake,
            child: OnbPressable(
              onTap: onBack,
              pressScale: .92,
              child: _Glass(
                key: const Key('a1_fiske_tilbake'),
                radius: 14 * s,
                width: 40 * s,
                height: 40 * s,
                alignment: Alignment.center,
                shadows: [
                  BoxShadow(
                    color: rgba(15, 31, 43, .6),
                    offset: Offset(0, 8 * s),
                    blurRadius: onbBlur(16 * s),
                    spreadRadius: -8 * s,
                  ),
                ],
                child: _Icon(16 * s, 2.4, _chevron),
              ),
            ),
          ),
          _Glass(
            radius: 999,
            padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 7 * s),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FiskeLoop(
                  durationMs: 3000,
                  builder: (context, p, _) {
                    final q = kf(p ?? 0, const [0, .5, 1], const [0, 1, 0], Curves.easeInOut);
                    return Container(
                      width: 7 * s,
                      height: 7 * s,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF2C14E),
                        boxShadow: [
                          BoxShadow(
                            color: rgba(242, 193, 78, .9 + .1 * q),
                            blurRadius: onbBlur((8 + 7 * q) * s),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(width: 6 * s),
                Text(
                  FiskeCopy.a1_fiske_status(kast, av, lagret),
                  key: const Key('a1_fiske_status'),
                  style: bText(context, 11.5, weight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `Fjordfiske` (28px Plus Jakarta 800, −.03em, `text-shadow 0 2px 12px
/// rgba(8,24,32,.45)`, `vekt .9s ease-out`: weight 500 → 800 and opacity .6
/// → 1 — the opacity is played; the variable weight is not, see ledger) and
/// the 12px subtitle under it.
class FiskeTitle extends StatelessWidget {
  const FiskeTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20 * s, 10 * s, 20 * s, 0),
          child: FiskeOnce(
            durationMs: 900,
            builder: (context, p, child) => Opacity(
              opacity: .6 + .4 * Curves.easeOut.transform(p),
              child: child,
            ),
            child: Text(
              FiskeCopy.a1_fiske_title,
              key: const Key('a1_fiske_title'),
              style: bDisplay(
                context,
                28,
                letterSpacingEm: -.03,
                shadows: [Shadow(color: rgba(8, 24, 32, .45), offset: Offset(0, 2 * s), blurRadius: 12 * s)],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20 * s, 2 * s, 20 * s, 0),
          child: Text(
            FiskeCopy.a1_fiske_sub,
            style: bText(
              context,
              12,
              color: rgba(255, 255, 255, .85),
              shadows: [Shadow(color: rgba(8, 24, 32, .5), offset: Offset(0, 1 * s), blurRadius: 8 * s)],
            ),
          ),
        ),
      ],
    );
  }
}

/// `Ægil snakker`: `left:16;top:236;max-width:216;radius 18 18 18 6;
/// padding 8px 12px 9px; rgba(15,31,43,.62); blur 16; border
/// rgba(255,255,255,.28); inset 0 1px 0 rgba(255,255,255,.25), 0 12px 22px
/// -12px rgba(4,18,26,.9); bobleInn .4s cubic-bezier(.3,1.3,.5,1)`.
class FiskeBubble extends StatelessWidget {
  const FiskeBubble({super.key, required this.text, required this.seq});

  final String text;

  /// Bumps when the line changes so `bobleInn` replays.
  final int seq;

  @override
  Widget build(BuildContext context) {
    final f = FiskeFrame.of(context);
    final s = f.s;
    return Positioned(
      left: f.x(16),
      top: f.y(236),
      child: FiskeOnce(
        key: ValueKey('a1_fiske_boble_$seq'),
        durationMs: 400,
        builder: (context, p, child) {
          final q = kBobleInn.transform(p);
          return Opacity(
            opacity: q.clamp(0, 1),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..translate(0.0, 8 * (1 - q) * s)
                ..scale(.6 + .4 * q),
              child: child,
            ),
          );
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 216 * s),
          child: BergenCssShadow(
            radius: 18 * s,
            shadows: [
              BoxShadow(
                color: rgba(4, 18, 26, .9),
                offset: Offset(0, 12 * s),
                blurRadius: onbBlur(22 * s),
                spreadRadius: -12 * s,
              ),
            ],
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18 * s),
                topRight: Radius.circular(18 * s),
                bottomRight: Radius.circular(18 * s),
                bottomLeft: Radius.circular(6 * s),
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 16 * s, sigmaY: 16 * s),
                child: Container(
                  padding: EdgeInsets.fromLTRB(12 * s, 8 * s, 12 * s, 9 * s),
                  decoration: BoxDecoration(
                    color: rgba(15, 31, 43, .62),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18 * s),
                      topRight: Radius.circular(18 * s),
                      bottomRight: Radius.circular(18 * s),
                      bottomLeft: Radius.circular(6 * s),
                    ),
                    border: Border.all(color: rgba(255, 255, 255, .28)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6 * s,
                            height: 6 * s,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF7FF0CB),
                              boxShadow: [BoxShadow(color: rgba(127, 240, 203, .9), blurRadius: onbBlur(6 * s))],
                            ),
                          ),
                          SizedBox(width: 5 * s),
                          Text(
                            FiskeCopy.a1_fiske_aegil,
                            style: bText(context, 9.5, weight: FontWeight.w800, letterSpacingEm: .1, color: const Color(0xFF7FF0CB)),
                          ),
                        ],
                      ),
                      SizedBox(height: 3 * s),
                      Text(
                        text,
                        key: const Key('a1_fiske_snakk'),
                        style: bText(context, 12.5, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Fiske-kontroller ────────────────────────────────────────────────────────

/// The hint line (`bottom:80;10.5px 700 rgba(255,255,255,.85); text-shadow
/// 0 1px 6px rgba(8,24,32,.6)`).
class FiskeHint extends StatelessWidget {
  const FiskeHint({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Text(
      text,
      key: const Key('a1_fiske_hint'),
      textAlign: TextAlign.center,
      style: bText(
        context,
        10.5,
        color: rgba(255, 255, 255, .85),
        shadows: [Shadow(color: rgba(8, 24, 32, .6), offset: Offset(0, 1 * s), blurRadius: 6 * s)],
      ),
    );
  }
}

/// Screen entrance (`skjermInn .34s cubic-bezier(.2,.9,.3,1)`: opacity 0 → 1,
/// translateY(10) scale(.985) → rest).
class FiskeSkjermInn extends StatelessWidget {
  const FiskeSkjermInn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => FiskeOnce(
    durationMs: 340,
    child: child,
    builder: (context, p, child) {
      final q = kSkjermInn.transform(p);
      return Opacity(
        opacity: q.clamp(0, 1),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translate(0.0, 10 * (1 - q) * context.bs)
            ..scale(.985 + .015 * q),
          child: child,
        ),
      );
    },
  );
}

/// The perspective-free helper the screen uses to size a keyframe in degrees.
double fiskeDeg(double d) => d * math.pi / 180;
