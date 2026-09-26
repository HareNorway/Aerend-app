import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_kit.dart';
import 'fiske_copy.dart';
import 'fiske_frame.dart';
import 'fiske_game.dart';
import 'fiske_motion.dart';

// ── icons (the design's inline 24-box SVGs) ─────────────────────────────────

typedef _IconDraw = void Function(Canvas c, Paint stroke);

class _Icon extends StatelessWidget {
  const _Icon(this.size, this.strokeWidth, this.draw, {this.fill});

  static const Color color = Colors.white;

  final double size;
  final double strokeWidth;
  final _IconDraw draw;
  final Color? fill;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _IconPainter(strokeWidth, draw, color, fill),
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

/// `M4 20L16 4 · M16 4c2 3 1 7-2 9 · circle 13 15 r2.2` — the rod.
void _rod(Canvas c, Paint p) {
  c.drawLine(const Offset(4, 20), const Offset(16, 4), p);
  c.drawPath(
    Path()
      ..moveTo(16, 4)
      ..relativeCubicTo(2, 3, 1, 7, -2, 9),
    p,
  );
  c.drawCircle(const Offset(13, 15), 2.2, p);
}

/// `M12 19V5 · M5.5 11.5L12 5l6.5 6.5` — the up arrow.
void _up(Canvas c, Paint p) {
  c.drawLine(const Offset(12, 19), const Offset(12, 5), p);
  c.drawPath(
    Path()
      ..moveTo(5.5, 11.5)
      ..lineTo(12, 5)
      ..lineTo(18.5, 11.5),
    p,
  );
}

/// `M6 6l12 12 · M18 6L6 18`.
void _cross(Canvas c, Paint p) {
  c.drawLine(const Offset(6, 6), const Offset(18, 18), p);
  c.drawLine(const Offset(18, 6), const Offset(6, 18), p);
}

/// `M20 7L9 18l-5-5`.
void _check(Canvas c, Paint p) {
  c.drawPath(
    Path()
      ..moveTo(20, 7)
      ..lineTo(9, 18)
      ..lineTo(4, 13),
    p,
  );
}

/// `circle r9 · r4.5 · r1 (fill)`.
void _target(Canvas c, Paint p) {
  c.drawCircle(const Offset(12, 12), 9, p);
  c.drawCircle(const Offset(12, 12), 4.5, p);
  c.drawCircle(const Offset(12, 12), 1, Paint()..color = p.color);
}

/// `M12 20.4l-7.2-7.2a4.9 4.9 0 1 1 7-7l.2.3.2-.3a4.9 4.9 0 1 1 7 7z`.
void _heart(Canvas c, Paint p) {
  c.drawPath(
    Path()
      ..moveTo(12, 20.4)
      ..relativeLineTo(-7.2, -7.2)
      ..relativeArcToPoint(const Offset(7, -7), radius: const Radius.circular(4.9), largeArc: true)
      ..relativeLineTo(.2, .3)
      ..relativeLineTo(.2, -.3)
      ..relativeArcToPoint(const Offset(7, 7), radius: const Radius.circular(4.9), largeArc: true)
      ..close(),
    p,
  );
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
    this.fill = .45,
    this.blur = 18,
    this.border = .3,
    this.inset = .25,
    this.shadows = const [],
    this.padding = EdgeInsets.zero,
    this.width,
    this.height,
    this.alignment,
  });

  final double radius;
  final Widget child;
  final double fill;
  final double blur;
  final double border;
  final double inset;
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

/// `Kast ut` (`fiskeKlar`): `height:56;padding:0 26px 0 20px;gap:9;
/// radius 999; gradient; box-shadow 0 0 0 1px rgba(255,255,255,.5),
/// 0 1.5px 0 #C4491A, 0 4px 0 rgba(120,45,15,.42), 0 16px 24px -10px
/// rgba(200,70,25,.9); 16px Plus Jakarta 800 −.01em`; pressed
/// `translateY(3px)` with the edge flattened; enters with `bobleInn .4s`.
class FiskeKastUt extends StatefulWidget {
  const FiskeKastUt({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  State<FiskeKastUt> createState() => _FiskeKastUtState();
}

class _FiskeKastUtState extends State<FiskeKastUt> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final down = _down;
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        key: const Key('a1_fiske_kast'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: FiskeOnce(
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
          child: AnimatedContainer(
            duration: BergenTokens.motion(context, const Duration(milliseconds: 140)),
            curve: Curves.ease,
            transform: Matrix4.translationValues(0, down ? 3 * s : 0, 0),
            height: 56 * s,
            padding: EdgeInsets.only(left: 20 * s, right: 26 * s),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: kFiskeOrange,
              boxShadow: down
                  ? [
                      BoxShadow(color: rgba(255, 255, 255, .5), spreadRadius: 1),
                      BoxShadow(
                        color: rgba(200, 70, 25, .75),
                        offset: Offset(0, 4 * s),
                        blurRadius: onbBlur(8 * s),
                        spreadRadius: -6 * s,
                      ),
                    ]
                  : [
                      BoxShadow(color: rgba(255, 255, 255, .5), spreadRadius: 1),
                      BoxShadow(color: const Color(0xFFC4491A), offset: Offset(0, 1.5 * s)),
                      BoxShadow(color: rgba(120, 45, 15, .42), offset: Offset(0, 4 * s)),
                      BoxShadow(
                        color: rgba(200, 70, 25, .9),
                        offset: Offset(0, 16 * s),
                        blurRadius: onbBlur(24 * s),
                        spreadRadius: -10 * s,
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Icon(22 * s, 2.3, _rod),
                SizedBox(width: 9 * s),
                Text(
                  widget.label,
                  style: bDisplay(context, 16, letterSpacingEm: -.01),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `Snøret er ute … vent på napp` (`fiskeVenter`): a glass pill (`height 52;
/// padding 0 20; rgba(15,31,43,.55); blur 16; border rgba(255,255,255,.3);
/// 13.5px 800`) with three lantern dots on `glod 1.2s` (.7 ↔ 1) at 0 / .3 /
/// .6 s; enters with `bobleInn .3s ease-out`.
class FiskeVenterPill extends StatelessWidget {
  const FiskeVenterPill({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return FiskeOnce(
      key: const Key('a1_fiske_ute'),
      durationMs: 300,
      builder: (context, p, child) {
        final q = Curves.easeOut.transform(p);
        return Opacity(
          opacity: q,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translate(0.0, 8 * (1 - q) * s)
              ..scale(.6 + .4 * q),
            child: child,
          ),
        );
      },
      child: _Glass(
        radius: 999,
        fill: .55,
        blur: 16,
        height: 52 * s,
        width: null,
        padding: EdgeInsets.symmetric(horizontal: 20 * s),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final d in [0.0, 300.0, 600.0]) ...[
              FiskeLoop(
                durationMs: 1200,
                delayMs: d,
                builder: (context, p, _) => Opacity(
                  opacity: p == null ? 1 : kf(p, const [0, .5, 1], const [.7, 1, .7], Curves.easeInOut),
                  child: Container(
                    width: 6 * s,
                    height: 6 * s,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF2C14E)),
                  ),
                ),
              ),
              SizedBox(width: d == 600 ? 9 * s : 4 * s),
            ],
            Flexible(
              child: Text(
                FiskeCopy.a1_fiske_venter,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: bText(context, 13.5, weight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `DRA INN!` (`fiskeNapp`): `84×84` orange circle, `2px #FFFFFF` border,
/// `nappPuls .55s ease-in-out infinite` (scale 1 → 1.06, the ring `0 0 0 0
/// rgba(242,109,61,.7)` → `0 0 0 18px …0`, the drop `0 18px 30px -12px
/// rgba(233,92,44,.9)` → `0 22px 34px -12px …1`), pressed `scale(.92)`; the
/// `tidStrek 1.7s linear` bar under it runs the bite window down.
class FiskeDraInn extends StatelessWidget {
  const FiskeDraInn({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Semantics(
      button: true,
      label: FiskeCopy.a1_fiske_dra,
      child: OnbPressable(
        onTap: onTap,
        pressScale: .92,
        child: SizedBox(
          key: const Key('a1_fiske_dra'),
          width: 84 * s,
          height: 84 * s,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: FiskeLoop(
                  durationMs: 550,
                  builder: (context, p, child) {
                    final q = kf(p ?? 0, const [0, .5, 1], const [0, 1, 0], Curves.easeInOut);
                    return Transform.scale(
                      scale: 1 + .06 * q,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: kFiskeOrange,
                          border: Border.all(color: Colors.white, width: 2 * s),
                          boxShadow: [
                            BoxShadow(
                              color: rgba(242, 109, 61, .7 * (1 - q)),
                              spreadRadius: 18 * q * s,
                            ),
                            BoxShadow(
                              color: rgba(233, 92, 44, .9 + .1 * q),
                              offset: Offset(0, (18 + 4 * q) * s),
                              blurRadius: onbBlur((30 + 4 * q) * s),
                              spreadRadius: -12 * s,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Icon(22 * s, 3, _up),
                      SizedBox(height: 1 * s),
                      Text(
                        FiskeCopy.a1_fiske_dra,
                        style: bDisplay(context, 13, letterSpacingEm: -.01, height: 1),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 8 * s,
                right: 8 * s,
                bottom: -14 * s,
                height: 4 * s,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2 * s),
                  child: ColoredBox(
                    color: rgba(255, 255, 255, .3),
                    child: FiskeOnce(
                      durationMs: 1700,
                      builder: (context, p, _) => Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: 1 - p,
                          child: const ColoredBox(color: Colors.white, child: SizedBox.expand()),
                        ),
                      ),
                    ),
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

/// A glass action (`54×54; rgba(15,31,43,.55); blur 20; border
/// rgba(255,255,255,.35); inset 0 1px 0 rgba(255,255,255,.3), 0 14px 22px
/// -10px rgba(4,18,26,.7)`) with its 10px label; pressed `scale(.9)`.
class FiskeGlassAction extends StatelessWidget {
  const FiskeGlassAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.opacity = 1,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onTap;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Semantics(
      button: true,
      label: label,
      child: OnbPressable(
        onTap: onTap,
        pressScale: .9,
        child: Opacity(
          opacity: opacity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Glass(
                radius: 999,
                fill: .55,
                blur: 20,
                border: .35,
                inset: .3,
                width: 54 * s,
                height: 54 * s,
                alignment: Alignment.center,
                shadows: [
                  BoxShadow(
                    color: rgba(4, 18, 26, .7),
                    offset: Offset(0, 14 * s),
                    blurRadius: onbBlur(22 * s),
                    spreadRadius: -10 * s,
                  ),
                ],
                child: icon,
              ),
              SizedBox(height: 5 * s),
              Text(
                label,
                style: bText(
                  context,
                  10,
                  weight: FontWeight.w800,
                  color: rgba(255, 255, 255, .85),
                  shadows: [Shadow(color: rgba(8, 24, 32, .6), offset: Offset(0, 1 * s), blurRadius: 6 * s)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The orange primary action (`68×68; gradient; 2px rgba(255,255,255,.7);
/// inset 0 2px 0 rgba(255,255,255,.4), 0 1.5px 0 #C4491A, 0 18px 28px -10px
/// rgba(233,92,44,.9)`) with its white label; pressed `scale(.92)`.
class FiskeOrangeAction extends StatelessWidget {
  const FiskeOrangeAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Semantics(
      button: true,
      label: label,
      child: OnbPressable(
        onTap: onTap,
        pressScale: .92,
        child: Opacity(
          opacity: onTap == null ? .55 : 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68 * s,
                height: 68 * s,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: kFiskeOrange,
                  border: Border.all(color: rgba(255, 255, 255, .7), width: 2 * s),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFC4491A), offset: Offset(0, 1.5 * s)),
                    BoxShadow(
                      color: rgba(233, 92, 44, .9),
                      offset: Offset(0, 18 * s),
                      blurRadius: onbBlur(28 * s),
                      spreadRadius: -10 * s,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    icon,
                    bergenInsetTop(radius: 999, height: 2 * s, alpha: .4),
                  ],
                ),
              ),
              SizedBox(height: 5 * s),
              Text(
                label,
                style: bText(
                  context,
                  10,
                  weight: FontWeight.w800,
                  shadows: [Shadow(color: rgba(8, 24, 32, .6), offset: Offset(0, 1 * s), blurRadius: 6 * s)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The ready-made icons for the actions.
abstract final class FiskeIcons {
  static Widget cross(BuildContext c) => _Icon(20 * c.bs, 2.6, _cross);
  static Widget up(BuildContext c) => _Icon(26 * c.bs, 2.8, _up);
  static Widget heart(BuildContext c) =>
      _Icon(20 * c.bs, 1.6, _heart, fill: const Color(0xFFF26D3D));
  static Widget check(BuildContext c) => _Icon(26 * c.bs, 2.8, _check);
  static Widget target(BuildContext c) => _Icon(20 * c.bs, 2.4, _target);
}

// ── Agn ─────────────────────────────────────────────────────────────────────

/// The bait rail (`top:582;padding:0 12;gap:6;overflow-x:auto`): six
/// 58-wide items — a 42 px ring (`padding 2.5; on:
/// linear-gradient(150deg,#F26D3D,#F2C14E 45%,#1E4F5C); off:
/// rgba(255,255,255,.35)`), the tinted disc inside (`2px rgba(255,255,255,.9)
/// border; inset 0 1.5px 0 rgba(255,255,255,.6), inset 0 -7px 12px
/// rgba(10,30,40,.2)`, a `radial-gradient(120% 90% at 30% 12%, …)` sheen and
/// the category art), the count badge (`19px; #FBFAF6; 2px border`) and the
/// 9.5px label.
class FiskeAgnRail extends StatelessWidget {
  const FiskeAgnRail({
    super.key,
    required this.selected,
    required this.count,
    required this.onSelect,
  });

  final FiskeAgn selected;
  final int Function(FiskeAgn) count;
  final ValueChanged<FiskeAgn> onSelect;

  static List<Color> tint(FiskeAgn a) => switch (a) {
    FiskeAgn.alle => const [Color(0xFFDCE9EC), Color(0xFF9FB6C2)],
    FiskeAgn.fisk => const [Color(0xFFCFE3E8), Color(0xFF6FA3B2)],
    FiskeAgn.mat => const [Color(0xFFFBEFDA), Color(0xFFDFBE7E)],
    FiskeAgn.mote => const [Color(0xFFEFE6F2), Color(0xFFB79BC4)],
    FiskeAgn.interior => const [Color(0xFFEAF3E6), Color(0xFF9FC7A6)],
    FiskeAgn.gaver => const [Color(0xFFFBEFD6), Color(0xFFDDB05A)],
  };

  static String label(FiskeAgn a) => switch (a) {
    FiskeAgn.alle => FiskeCopy.a1_fiske_agn_alle,
    FiskeAgn.fisk => FiskeCopy.a1_fiske_agn_fisk,
    FiskeAgn.mat => FiskeCopy.a1_fiske_agn_mat,
    FiskeAgn.mote => FiskeCopy.a1_fiske_agn_mote,
    FiskeAgn.interior => FiskeCopy.a1_fiske_agn_interior,
    FiskeAgn.gaver => FiskeCopy.a1_fiske_agn_gaver,
  };

  /// The art inside the disc (asset, width, height) per bait.
  static (String, double, double) art(FiskeAgn a) => switch (a) {
    FiskeAgn.alle => ('ae_mark', 26, 17),
    FiskeAgn.fisk => ('ico_fisk', 34, 26),
    FiskeAgn.mat => ('pi_bowl', 30, 28),
    FiskeAgn.mote => ('ico_mote', 26, 28),
    FiskeAgn.interior => ('ico_interior', 26, 28),
    FiskeAgn.gaver => ('ico_gaver', 26, 28),
  };

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return SingleChildScrollView(
      key: const Key('a1_fiske_agn'),
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 12 * s),
      child: Row(
        children: [
          for (final a in FiskeAgn.values) ...[
            _AgnItem(
              agn: a,
              on: a == selected,
              count: count(a),
              onTap: () => onSelect(a == selected ? FiskeAgn.alle : a),
            ),
            if (a != FiskeAgn.values.last) SizedBox(width: 6 * s),
          ],
        ],
      ),
    );
  }
}

class _AgnItem extends StatelessWidget {
  const _AgnItem({
    required this.agn,
    required this.on,
    required this.count,
    required this.onTap,
  });

  final FiskeAgn agn;
  final bool on;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final (asset, aw, ah) = FiskeAgnRail.art(agn);
    return GestureDetector(
      key: Key('a1_fiske_agn_${agn.name}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 58 * s,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: BergenTokens.motion(context, const Duration(milliseconds: 250)),
              curve: Curves.ease,
              width: 42 * s,
              height: 42 * s,
              padding: EdgeInsets.all(2.5 * s),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: on
                    ? cssLinear(150, const [Color(0xFFF26D3D), Color(0xFFF2C14E), Color(0xFF1E4F5C)], const [0, .45, 1])
                    : null,
                color: on ? null : rgba(255, 255, 255, .35),
                boxShadow: [
                  on
                      ? BoxShadow(
                          color: rgba(242, 109, 61, .75),
                          offset: Offset(0, 10 * s),
                          blurRadius: onbBlur(18 * s),
                          spreadRadius: -8 * s,
                        )
                      : BoxShadow(
                          color: rgba(10, 30, 40, .5),
                          offset: Offset(0, 6 * s),
                          blurRadius: onbBlur(12 * s),
                          spreadRadius: -8 * s,
                        ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: cssLinear(160, FiskeAgnRail.tint(agn)),
                        border: Border.all(color: rgba(255, 255, 255, .9), width: 2 * s),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: const Alignment(-.4, -.76),
                                  radius: 1.2,
                                  colors: [rgba(255, 255, 255, .5), rgba(255, 255, 255, 0)],
                                  stops: const [0, .62],
                                ),
                              ),
                            ),
                          ),
                          // `inset 0 -7px 12px rgba(10,30,40,.2)`.
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [rgba(10, 30, 40, 0), rgba(10, 30, 40, .2)],
                                  stops: const [.55, 1],
                                ),
                              ),
                            ),
                          ),
                          bergenSvg(asset, width: aw * s, height: ah * s),
                          bergenInsetTop(radius: 999, height: 1.5 * s, alpha: .6),
                        ],
                      ),
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      right: -2 * s,
                      bottom: -2 * s,
                      child: Container(
                        constraints: BoxConstraints(minWidth: 19 * s),
                        height: 19 * s,
                        padding: EdgeInsets.symmetric(horizontal: 5 * s),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: const Color(0xFFFBFAF6),
                          border: Border.all(
                            color: on ? const Color(0xFFF26D3D) : rgba(255, 255, 255, .9),
                            width: 2 * s,
                          ),
                        ),
                        child: Text(
                          '$count',
                          style: bText(context, 9.5, weight: FontWeight.w800, color: const Color(0xFF23201D)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 3 * s),
            SizedBox(
              width: 60 * s,
              child: Text(
                FiskeAgnRail.label(agn),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: bText(
                  context,
                  9.5,
                  weight: FontWeight.w800,
                  color: on ? Colors.white : rgba(255, 255, 255, .72),
                  shadows: [Shadow(color: rgba(10, 30, 40, .5), offset: Offset(0, 1 * s), blurRadius: 4 * s)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
