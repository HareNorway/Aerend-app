import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../data/ops/kasse_models.dart';
import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_css.dart';
import '../kit/bergen_kit.dart';
import '../kit/bergen_motion.dart';
import 'kasse_copy.dart';

/// The pieces of the Kurv panel (design L5047–5228), each with the
/// prototype's sizes, colours and shadows. Glass = `linear-gradient(180deg,
/// rgba(255,255,255,.13), rgba(255,255,255,.06))`, `1px rgba(255,255,255,.18)`,
/// `inset 0 1.5px 0 rgba(255,255,255,.28)` and the deep drop shadow, drawn
/// through [BergenCssShadow] so the glass stays clear.

// ── icons ───────────────────────────────────────────────────────────────────

typedef KurvDraw = void Function(Canvas c, Paint p);

class KurvIcon extends StatelessWidget {
  const KurvIcon(this.size, this.draw, {super.key, this.color = Colors.white, this.width = 2, this.fill});

  final double size;
  final KurvDraw draw;
  final Color color;
  final double width;
  final Color? fill;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _IconPainter(draw, color, width, fill),
  );
}

class _IconPainter extends CustomPainter {
  const _IconPainter(this.draw, this.color, this.width, this.fill);

  final KurvDraw draw;
  final Color color;
  final double width;
  final Color? fill;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24);
    if (fill != null) draw(canvas, Paint()..color = fill!);
    draw(
      canvas,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.color != color || old.width != width || old.fill != fill;
}

abstract final class KurvIcons {
  /// `M2.8 6.5h10.4v9.2H2.8z · M13.2 9.8h3.5l2.9 3v2.9h-6.4z · wheels`.
  static void truck(Canvas c, Paint p) {
    c.drawRect(const Rect.fromLTWH(2.8, 6.5, 10.4, 9.2), p);
    c.drawPath(
      Path()
        ..moveTo(13.2, 9.8)
        ..lineTo(16.7, 9.8)
        ..lineTo(19.6, 12.8)
        ..lineTo(19.6, 15.7)
        ..lineTo(13.2, 15.7)
        ..close(),
      p,
    );
    c.drawCircle(const Offset(7, 17.8), 1.9, p);
    c.drawCircle(const Offset(16.4, 17.8), 1.9, p);
  }

  /// `M4 9.5h16v10.5H4z · M4 9.5 6.5 4h11L20 9.5 · M9.5 13.5h5`.
  static void bag(Canvas c, Paint p) {
    c.drawRect(const Rect.fromLTWH(4, 9.5, 16, 10.5), p);
    c.drawPath(
      Path()
        ..moveTo(4, 9.5)
        ..lineTo(6.5, 4)
        ..lineTo(17.5, 4)
        ..lineTo(20, 9.5),
      p,
    );
    c.drawLine(const Offset(9.5, 13.5), const Offset(14.5, 13.5), p);
  }

  static void pin(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(12, 21.5)
        ..cubicTo(12, 21.5, 5.5, 15.5, 5.5, 10.5)
        ..arcToPoint(const Offset(18.5, 10.5), radius: const Radius.circular(6.5), largeArc: true)
        ..cubicTo(18.5, 15.5, 12, 21.5, 12, 21.5)
        ..close(),
      p,
    );
    c.drawCircle(const Offset(12, 10.5), 2.3, p);
  }

  static void clock(Canvas c, Paint p) {
    c.drawCircle(const Offset(12, 12), 8.5, p);
    c.drawPath(
      Path()
        ..moveTo(12, 7.5)
        ..lineTo(12, 12)
        ..lineTo(14.8, 13.8),
      p,
    );
  }

  static void card(Canvas c, Paint p) {
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(3.5, 6, 17, 12.5), const Radius.circular(2.5)), p);
    c.drawLine(const Offset(3.5, 10), const Offset(20.5, 10), p);
  }

  static void door(Canvas c, Paint p) {
    c.drawRect(const Rect.fromLTWH(4, 6, 16, 10), p);
    c.drawLine(const Offset(8, 20), const Offset(16, 20), p);
    c.drawLine(const Offset(12, 16), const Offset(12, 20), p);
  }

  static void map(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(9, 4.5)
        ..lineTo(3.5, 6.6)
        ..lineTo(3.5, 19.6)
        ..lineTo(9, 17.4)
        ..lineTo(15, 19.5)
        ..lineTo(20.5, 17.4)
        ..lineTo(20.5, 4.4)
        ..lineTo(15, 6.6)
        ..close(),
      p,
    );
    c.drawLine(const Offset(9, 4.5), const Offset(9, 17.4), p);
    c.drawLine(const Offset(15, 6.6), const Offset(15, 19.5), p);
  }

  static void chevron(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(9, 5)
        ..lineTo(16, 12)
        ..lineTo(9, 19),
      p,
    );
  }

  static void chevronDown(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(6, 9)
        ..lineTo(12, 15)
        ..lineTo(18, 9),
      p,
    );
  }

  static void plus(Canvas c, Paint p) {
    c.drawLine(const Offset(12, 5), const Offset(12, 19), p);
    c.drawLine(const Offset(5, 12), const Offset(19, 12), p);
  }

  static void minus(Canvas c, Paint p) => c.drawLine(const Offset(6, 12), const Offset(18, 12), p);

  static void cross(Canvas c, Paint p) {
    c.drawLine(const Offset(6, 6), const Offset(18, 18), p);
    c.drawLine(const Offset(18, 6), const Offset(6, 18), p);
  }

  static void check(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(4.5, 12.5)
        ..lineTo(9.5, 17.5)
        ..lineTo(19.5, 6.5),
      p,
    );
  }

  /// `M12 3v18M7 8h7a3 3 0 0 1 0 6H9a3 3 0 0 0 0 6h8` — the kroner sign.
  static void kroner(Canvas c, Paint p) {
    c.drawLine(const Offset(12, 3), const Offset(12, 21), p);
    c.drawPath(
      Path()
        ..moveTo(7, 8)
        ..lineTo(14, 8)
        ..arcToPoint(const Offset(14, 14), radius: const Radius.circular(3))
        ..lineTo(9, 14)
        ..arcToPoint(const Offset(9, 20), radius: const Radius.circular(3), clockwise: false)
        ..lineTo(17, 20),
      p,
    );
  }
}

// ── glass ───────────────────────────────────────────────────────────────────

/// A glass card of the panel: `radius`, glass gradient, `.18` border, inset
/// top highlight and the deep shadow (`0 18px 30px -18px` for the tall cards,
/// `0 14px 22px -14px` for the flat ones).
class KurvGlass extends StatelessWidget {
  const KurvGlass({
    super.key,
    required this.radius,
    required this.padding,
    required this.child,
    this.deep = true,
    this.transparent = false,
  });

  final double radius;
  final EdgeInsetsGeometry padding;
  final Widget child;
  final bool deep;

  /// `kurvKortBg: transparent` — the lines card in the empty state.
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return BergenCssShadow(
      radius: radius,
      shadows: transparent
          ? const []
          : [
              BoxShadow(
                color: rgba(4, 18, 26, .9),
                offset: Offset(0, (deep ? 18 : 14) * s),
                blurRadius: onbBlur((deep ? 30 : 22) * s),
                spreadRadius: -(deep ? 18 : 14) * s,
              ),
            ],
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: transparent ? null : cssLinear(180, [rgba(255, 255, 255, .13), rgba(255, 255, 255, .06)]),
          border: Border.all(color: rgba(255, 255, 255, .18)),
        ),
        child: Stack(
          children: [
            child,
            if (!transparent) bergenInsetTop(radius: radius, height: 1.5 * s, alpha: .28),
          ],
        ),
      ),
    );
  }
}

/// The frosted paper card of Flere valg (`rgba(255,255,255,.62)`, blur 26,
/// `1px rgba(255,255,255,.9)`, `stigOpp .3s cubic-bezier(.2,.9,.3,1)`).
class KurvFrost extends StatelessWidget {
  const KurvFrost({super.key, required this.child, this.radius = 22, this.blur = true});

  final Widget child;
  final double radius;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return BergenOnce(
      durationMs: 300,
      child: BergenCssShadow(
        radius: radius * s,
        shadows: [
          BoxShadow(color: rgba(120, 80, 40, .14), offset: Offset(0, 2 * s), blurRadius: onbBlur(3 * s), spreadRadius: -1 * s),
          BoxShadow(color: rgba(90, 60, 30, .5), offset: Offset(0, 18 * s), blurRadius: onbBlur(30 * s), spreadRadius: -18 * s),
        ],
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius * s),
          child: BackdropFilter(
            filter: blur ? ui.ImageFilter.blur(sigmaX: 26 * s, sigmaY: 26 * s) : ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Container(
              padding: EdgeInsets.fromLTRB(14 * s, 12 * s, 14 * s, 12 * s),
              decoration: BoxDecoration(
                color: rgba(255, 255, 255, .62),
                borderRadius: BorderRadius.circular(radius * s),
                border: Border.all(color: rgba(255, 255, 255, .9)),
              ),
              child: Stack(
                children: [child, bergenInsetTop(radius: radius * s, height: 1.5 * s, alpha: .95)],
              ),
            ),
          ),
        ),
      ),
      builder: (context, p, child) {
        final q = const Cubic(.2, .9, .3, 1).transform(p);
        return Opacity(
          opacity: q,
          child: Transform.translate(offset: Offset(0, 26 * (1 - q) * s), child: child),
        );
      },
    );
  }
}

// ── Levering / Henting ──────────────────────────────────────────────────────

/// The thumb toggle (design L5049–5054): `#EEE9DF` track with inset shadows,
/// the teal thumb (`165deg #2A6272→#1E4F5C`, `inset 0 1.5px 0 …, 0 2px 0
/// rgba(11,38,45,.85), 0 7px 11px -5px …`) sliding `.5s cubic-bezier(.3,1.25,.4,1)`;
/// labels 12.5px 800 white / `#55504A` with the truck and bag icons.
class KurvModus extends StatelessWidget {
  const KurvModus({super.key, required this.pickup, required this.onMode});

  final bool pickup;
  final ValueChanged<bool> onMode;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      padding: EdgeInsets.all(4 * s),
      decoration: BoxDecoration(
        color: const Color(0xFFEEE9DF),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: rgba(255, 255, 255, .7), offset: Offset(0, 1 * s))],
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = (box.maxWidth - 5 * s) / 2;
          return Stack(
            children: [
              // inset 0 1.5px 3px rgba(35,32,29,.14) — the track's dip.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [rgba(35, 32, 29, .14), rgba(35, 32, 29, 0), rgba(255, 255, 255, 0), rgba(255, 255, 255, .9)],
                      stops: const [0, .18, .9, 1],
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: BergenTokens.motion(context, const Duration(milliseconds: 500)),
                curve: const Cubic(.3, 1.25, .4, 1),
                left: pickup ? w + 5 * s : 0,
                top: 0,
                bottom: 0,
                width: w,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: cssLinear(165, const [Color(0xFF2A6272), Color(0xFF1E4F5C)]),
                    boxShadow: [
                      BoxShadow(color: rgba(11, 38, 45, .85), offset: Offset(0, 2 * s)),
                      BoxShadow(color: rgba(15, 45, 55, .7), offset: Offset(0, 7 * s), blurRadius: onbBlur(11 * s), spreadRadius: -5 * s),
                    ],
                  ),
                  child: Stack(children: [bergenInsetTop(radius: 999, height: 1.5 * s, alpha: .28)]),
                ),
              ),
              Row(
                children: [
                  for (final (m, label, draw) in [
                    (false, KasseCopy.a1_kasse_levering, KurvIcons.truck),
                    (true, KasseCopy.a1_kasse_henting, KurvIcons.bag),
                  ])
                    Expanded(
                      child: OnbPressable(
                        key: Key(m ? 'a1_kasse_henting' : 'a1_kasse_levering'),
                        onTap: () => onMode(m),
                        pressDy: 1.5,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10 * s),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              KurvIcon(15 * s, draw, color: pickup == m ? Colors.white : const Color(0xFF55504A)),
                              SizedBox(width: 7 * s),
                              Text(
                                label,
                                style: bText(context, 12.5, weight: FontWeight.w800, letterSpacingEm: -.01, color: pickup == m ? Colors.white : const Color(0xFF55504A)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── lines ───────────────────────────────────────────────────────────────────

/// One cart line (design L5056–5099): the 48 tile, name 13px 800, «n stk. ·
/// pris kr per stk.» 10.5px 700 white .62, the stepper pill (`rgba(0,0,0,.26)`
/// with inset shadows; 36 white buttons `#FFFFFF→#F3EFE6` on three shadows),
/// and the sum (Plus Jakarta 14px + «kr» 10px white .5).
class KurvLinje extends StatelessWidget {
  const KurvLinje({super.key, required this.line, required this.onMinus, required this.onPlus, this.last = false});

  final KurvLine line;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    Widget button(String label, KurvDraw draw, VoidCallback onTap, Key key) => Semantics(
      button: true,
      label: label,
      child: OnbPressable(
        key: key,
        onTap: onTap,
        pressDy: 1.5,
        child: Container(
          width: 36 * s,
          height: 36 * s,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: cssLinear(180, const [Color(0xFFFFFFFF), Color(0xFFF3EFE6)]),
            boxShadow: [
              BoxShadow(color: const Color(0xFFD9D2C4), offset: Offset(0, 1.5 * s)),
              BoxShadow(color: rgba(90, 74, 48, .3), offset: Offset(0, 2.5 * s)),
              BoxShadow(color: rgba(35, 32, 29, .5), offset: Offset(0, 5 * s), blurRadius: onbBlur(7 * s), spreadRadius: -4 * s),
            ],
          ),
          child: KurvIcon(11 * s, draw, color: const Color(0xFF23201D), width: 3.2),
        ),
      ),
    );
    return Container(
      key: Key('a1_kasse_linje_${line.cartId}'),
      padding: EdgeInsets.symmetric(vertical: 10 * s),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: rgba(255, 255, 255, .12))),
      ),
      child: Row(
        children: [
          Container(
            width: 48 * s,
            height: 48 * s,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16 * s),
              gradient: cssLinear(165, const [Color(0xFFF6D9B4), Color(0xFFD2854A)]),
              boxShadow: [
                BoxShadow(color: rgba(255, 255, 255, .6), spreadRadius: 1 * s),
                BoxShadow(color: rgba(190, 170, 140, .6), offset: Offset(0, 2 * s)),
                BoxShadow(color: rgba(60, 35, 10, .55), offset: Offset(0, 8 * s), blurRadius: onbBlur(13 * s), spreadRadius: -7 * s),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // The design's `#ico-mat` (30×28 @8,9) when there is no photo.
                Positioned(
                  left: 8 * s,
                  top: 9 * s,
                  width: 30 * s,
                  height: 28 * s,
                  child: bergenSvg('ico_mat', fit: BoxFit.contain),
                ),
                if (line.imageUrl != null && line.imageUrl!.isNotEmpty)
                  Image.network(line.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
                // radial shine at (-14%, -30%), 74% × 80%.
                Positioned(
                  left: -.14 * 48 * s,
                  top: -.3 * 48 * s,
                  width: .74 * 48 * s,
                  height: .8 * 48 * s,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [rgba(255, 255, 255, .5), rgba(255, 255, 255, 0)], stops: const [0, .7]),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 15 * s,
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: cssLinear(180, [rgba(60, 35, 10, 0), rgba(60, 35, 10, .2)])),
                  ),
                ),
                bergenInsetTop(radius: 16 * s, height: 2 * s, alpha: .7),
              ],
            ),
          ),
          SizedBox(width: 11 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: bText(context, 13, weight: FontWeight.w800)),
                Text(
                  KasseCopy.a1_kasse_stk_pris(line.quantity, KasseCopy.tall(line.unitPrice)),
                  style: bText(context, 10.5, color: rgba(255, 255, 255, .62)),
                ),
              ],
            ),
          ),
          SizedBox(width: 11 * s),
          Container(
            padding: EdgeInsets.all(3 * s),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: rgba(0, 0, 0, .26),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [rgba(0, 0, 0, .45), rgba(0, 0, 0, .26), rgba(0, 0, 0, .26), rgba(255, 255, 255, .14)],
                stops: const [0, .2, .95, 1],
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                button(KasseCopy.a1_kasse_en_mindre, KurvIcons.minus, onMinus, Key('a1_kasse_minus_${line.cartId}')),
                SizedBox(width: 3 * s),
                ConstrainedBox(
                  constraints: BoxConstraints(minWidth: 18 * s),
                  child: Text('${line.quantity}', textAlign: TextAlign.center, style: bText(context, 12.5, weight: FontWeight.w800)),
                ),
                SizedBox(width: 3 * s),
                button(KasseCopy.a1_kasse_en_mer, KurvIcons.plus, onPlus, Key('a1_kasse_plus_${line.cartId}')),
              ],
            ),
          ),
          SizedBox(width: 11 * s),
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: 52 * s),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(KasseCopy.tall(line.sum), style: bDisplay(context, 14, letterSpacingEm: -.02)),
                SizedBox(width: 2 * s),
                Text('kr', style: bText(context, 10, weight: FontWeight.w800, color: rgba(255, 255, 255, .5))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// «Legg til noe mer · Glemte du drikke?» (design L5150).
class KurvLeggMer extends StatelessWidget {
  const KurvLeggMer({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return GestureDetector(
      key: const Key('a1_kasse_legg_mer'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10 * s),
        child: Row(
          children: [
            KurvIcon(13 * s, KurvIcons.plus, color: const Color(0xFF5CE0B8), width: 2.6),
            SizedBox(width: 8 * s),
            Flexible(
              child: Text(KasseCopy.a1_kasse_legg_mer, maxLines: 1, overflow: TextOverflow.ellipsis, style: bText(context, 12, weight: FontWeight.w800, color: const Color(0xFF5CE0B8))),
            ),
            SizedBox(width: 8 * s),
            const Spacer(),
            Flexible(
              child: Text(KasseCopy.a1_kasse_glemte_drikke, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: bText(context, 10.5, color: rgba(255, 255, 255, .5))),
            ),
          ],
        ),
      ),
    );
  }
}

// ── empty ───────────────────────────────────────────────────────────────────

/// `tomKurv` (design L5101–5120): Ægil pushing the empty cart (`aegSkyv`,
/// `tomVipp`), the glow and the two `damp` dots, the ÆGIL bubble on
/// `bobleInn .38s cubic-bezier(.25,1.25,.45,1)` and the «Bla gjennom Bergen»
/// 3D button.
class KurvTom extends StatelessWidget {
  const KurvTom({super.key, required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Padding(
      key: const Key('a1_kasse_tom'),
      padding: EdgeInsets.fromLTRB(0, 6 * s, 0, 18 * s),
      child: Column(
        children: [
          SizedBox(
            width: 230 * s,
            height: 132 * s,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 115 * s - 90 * s,
                  top: 16 * s,
                  width: 180 * s,
                  height: 96 * s,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [rgba(220, 233, 236, .55), rgba(220, 233, 236, 0)], stops: const [0, .7]),
                    ),
                  ),
                ),
                Positioned(
                  left: 34 * s,
                  bottom: 10 * s,
                  width: 150 * s,
                  height: 14 * s,
                  child: onbBlurred(
                    2 * s,
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [rgba(35, 32, 29, .22), rgba(35, 32, 29, 0)], stops: const [0, .72]),
                      ),
                    ),
                  ),
                ),
                for (final (l, t, d, a, delay) in [(24.0, 18.0, 8.0, .18, 0.0), (186.0, 30.0, 6.0, .14, 1800.0)])
                  Positioned(
                    left: l * s,
                    top: t * s,
                    width: d * s,
                    height: d * s,
                    child: BergenLoop(
                      durationMs: 4600,
                      delayMs: delay,
                      builder: (context, p, _) => Opacity(
                        opacity: p == null ? 0 : kf(Curves.easeOut.transform(p), const [0, .2, 1], const [0, .7, 0]),
                        child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: rgba(30, 79, 92, a))),
                      ),
                    ),
                  ),
                Positioned(
                  left: 28 * s,
                  bottom: 12 * s,
                  width: 62 * s,
                  child: BergenLoop(
                    durationMs: 3400,
                    child: Image.asset('assets/images/dashboard/side.png', width: 62 * s, fit: BoxFit.contain),
                    builder: (context, p, child) {
                      final q = p ?? 0;
                      return Transform(
                        alignment: Alignment.bottomCenter,
                        transform: Matrix4.identity()
                          ..scale(-1.0, 1.0)
                          ..translate(0.0, kf(q, const [0, .5, 1], const [0, -2.5, 0], Curves.easeInOut) * s)
                          ..rotateZ(kf(q, const [0, .5, 1], const [1, -1.5, 1], Curves.easeInOut) * math.pi / 180),
                        child: child,
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 78 * s,
                  bottom: 10 * s,
                  width: 112 * s,
                  height: 86 * s,
                  child: BergenLoop(
                    durationMs: 3400,
                    child: CustomPaint(painter: _CartPainter(s)),
                    builder: (context, p, child) {
                      final q = p ?? 0;
                      return Transform(
                        alignment: const Alignment(.4, 1),
                        transform: Matrix4.identity()
                          ..rotateZ(kf(q, const [0, .5, 1], const [-7, -2, -7], Curves.easeInOut) * math.pi / 180)
                          ..translate(0.0, kf(q, const [0, .5, 1], const [0, -3, 0], Curves.easeInOut) * s),
                        child: child,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2 * s),
          BergenOnce(
            durationMs: 380,
            builder: (context, p, child) {
              final q = const Cubic(.25, 1.25, .45, 1).transform(p);
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
              constraints: BoxConstraints(maxWidth: 270 * s),
              child: BergenCssShadow(
                radius: 18 * s,
                shadows: [BoxShadow(color: rgba(4, 18, 26, .85), offset: Offset(0, 16 * s), blurRadius: onbBlur(24 * s), spreadRadius: -14 * s)],
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 11 * s),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18 * s),
                      topRight: Radius.circular(18 * s),
                      bottomRight: Radius.circular(18 * s),
                      bottomLeft: Radius.circular(6 * s),
                    ),
                    gradient: cssLinear(180, [rgba(255, 255, 255, .16), rgba(255, 255, 255, .08)]),
                    border: Border.all(color: rgba(255, 255, 255, .24)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(KasseCopy.a1_kasse_tom_kicker, style: bText(context, 9, weight: FontWeight.w800, letterSpacingEm: .06, color: const Color(0xFF5CE0B8))),
                      SizedBox(height: 2 * s),
                      Text(KasseCopy.a1_kasse_tom_title, style: bDisplay(context, 13, letterSpacingEm: -.015, height: 1.3)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 14 * s),
          OnbPressable(
            onTap: onBrowse,
            pressDy: 3,
            child: Container(
              key: const Key('a1_kasse_tom_cta'),
              padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 12 * s),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16 * s),
                gradient: cssLinear(160, const [Color(0xFFF2884E), Color(0xFFE0662C)]),
                boxShadow: [
                  BoxShadow(color: rgba(150, 60, 15, .8), offset: Offset(0, 3 * s)),
                  BoxShadow(color: rgba(120, 50, 10, .9), offset: Offset(0, 14 * s), blurRadius: onbBlur(22 * s), spreadRadius: -12 * s),
                ],
              ),
              child: Stack(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(KasseCopy.a1_kasse_tom_cta, style: bDisplay(context, 13.5, letterSpacingEm: 0)),
                      SizedBox(width: 8 * s),
                      KurvIcon(13 * s, KurvIcons.chevron, width: 3.2),
                    ],
                  ),
                  bergenInsetTop(radius: 16 * s, height: 1.5 * s, alpha: .35),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The empty cart (design L5112–5117), 112×86.
class _CartPainter extends CustomPainter {
  const _CartPainter(this.s);

  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(s);
    final grey = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF9FB6C2);
    canvas.drawPath(
      Path()
        ..moveTo(2, 34)
        ..lineTo(15, 34)
        ..lineTo(24, 26),
      grey..strokeWidth = 4.5,
    );
    final basket = Path()
      ..moveTo(23, 25)
      ..lineTo(96, 25)
      ..lineTo(85, 58)
      ..lineTo(34, 58)
      ..close();
    canvas.drawPath(basket, Paint()..color = rgba(220, 233, 236, .5));
    canvas.drawPath(basket, grey..strokeWidth = 4);
    final bars = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4
      ..color = rgba(159, 182, 194, .7);
    canvas.drawLine(const Offset(42, 28), const Offset(47, 55), bars);
    canvas.drawLine(const Offset(58, 28), const Offset(60, 55), bars);
    canvas.drawLine(const Offset(74, 28), const Offset(73, 55), bars);
    canvas.drawLine(const Offset(28, 39), const Offset(92, 39), bars..color = rgba(159, 182, 194, .6));
    for (final cx in [44.0, 78.0]) {
      canvas.drawCircle(Offset(cx, 70), 7.5, Paint()..color = const Color(0xFFEAF1F3));
      canvas.drawCircle(Offset(cx, 70), 7.5, grey..strokeWidth = 3.5);
    }
  }

  @override
  bool shouldRepaint(_CartPainter old) => old.s != s;
}

// ── Endre rows ──────────────────────────────────────────────────────────────

/// The white «Endre ›» pill (design L5158): `min-height 38; 0 12; #FFFFFF→
/// #EFF3F4; #1B4A57 11.5px 800; 0 0 0 1px white .95, 0 1.5px 0 #D2DDE0,
/// 0 3px 0 rgba(60,90,100,.3), 0 7px 10px -6px rgba(15,45,55,.55)`.
class KurvEndrePill extends StatelessWidget {
  const KurvEndrePill({super.key, required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final KurvDraw? icon;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return OnbPressable(
      onTap: onTap,
      pressDy: 2,
      child: Container(
        constraints: BoxConstraints(minHeight: 38 * s),
        padding: EdgeInsets.symmetric(horizontal: (icon == null ? 12 : 13) * s),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: cssLinear(180, const [Color(0xFFFFFFFF), Color(0xFFEFF3F4)]),
          boxShadow: [
            BoxShadow(color: rgba(255, 255, 255, .95), spreadRadius: 1),
            BoxShadow(color: const Color(0xFFD2DDE0), offset: Offset(0, 1.5 * s)),
            BoxShadow(color: rgba(60, 90, 100, .3), offset: Offset(0, 3 * s)),
            BoxShadow(color: rgba(15, 45, 55, .55), offset: Offset(0, 7 * s), blurRadius: onbBlur(10 * s), spreadRadius: -6 * s),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[KurvIcon(13 * s, icon!, color: const Color(0xFF1B4A57)), SizedBox(width: 5 * s)],
            Text(label, style: bText(context, 11.5, weight: FontWeight.w800, letterSpacingEm: -.01, color: const Color(0xFF1B4A57))),
            if (icon == null) ...[SizedBox(width: 4 * s), KurvIcon(11 * s, KurvIcons.chevron, color: const Color(0xFF1B4A57), width: 3.2)],
          ],
        ),
      ),
    );
  }
}

/// A row of the Endre card (design L5155–5185): the 36 icon tile
/// (`rgba(255,255,255,.12)`, `.18` border, mint 17px icon), title 12.5px 700,
/// line 11px white .62, the pill.
class KurvEndreRad extends StatelessWidget {
  const KurvEndreRad({
    super.key,
    required this.keyName,
    required this.icon,
    required this.title,
    required this.line,
    required this.action,
    required this.onTap,
    this.actionIcon,
    this.orange = false,
    this.last = false,
  });

  final String keyName;
  final KurvDraw icon;
  final String title;
  final String line;
  final String action;
  final VoidCallback onTap;
  final KurvDraw? actionIcon;

  /// The «Beskjed til budet» row: 32 tile `rgba(242,109,61,.14)`, `#B9441A`.
  final bool orange;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      key: Key(keyName),
      padding: EdgeInsets.symmetric(vertical: 9 * s),
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: rgba(255, 255, 255, .12)))),
      child: Row(
        children: [
          Container(
            width: (orange ? 32 : 36) * s,
            height: (orange ? 32 : 36) * s,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular((orange ? 11 : 13) * s),
              color: orange ? rgba(242, 109, 61, .14) : rgba(255, 255, 255, .12),
              border: orange ? null : Border.all(color: rgba(255, 255, 255, .18)),
            ),
            child: KurvIcon((orange ? 15 : 17) * s, icon, color: orange ? const Color(0xFFB9441A) : const Color(0xFF5CE0B8), width: orange ? 1.9 : 2),
          ),
          SizedBox(width: 11 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: bText(context, 12.5)),
                if (line.isNotEmpty) Text(line, maxLines: 1, overflow: TextOverflow.ellipsis, style: bText(context, 11, weight: FontWeight.w600, color: rgba(255, 255, 255, .62))),
              ],
            ),
          ),
          SizedBox(width: 8 * s),
          KurvEndrePill(label: action, onTap: onTap, icon: actionIcon),
        ],
      ),
    );
  }
}

/// «Flere valg» (design L5187–5192): 12.5px 800 + line 10.5px 700 white .55,
/// the mint chevron turning 180° in `.28s cubic-bezier(.3,1.2,.5,1)`.
class KurvFlere extends StatelessWidget {
  const KurvFlere({super.key, required this.open, required this.line, required this.onTap});

  final bool open;
  final String line;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return OnbPressable(
      key: const Key('a1_kasse_flere'),
      onTap: onTap,
      pressDy: 2,
      child: KurvGlass(
        radius: 18 * s,
        deep: false,
        padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 12 * s),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(KasseCopy.a1_kasse_flere_valg, style: bText(context, 12.5, weight: FontWeight.w800)),
                  SizedBox(height: 1 * s),
                  Text(line, style: bText(context, 10.5, color: rgba(255, 255, 255, .55))),
                ],
              ),
            ),
            AnimatedRotation(
              turns: open ? .5 : 0,
              duration: BergenTokens.motion(context, const Duration(milliseconds: 280)),
              curve: const Cubic(.3, 1.2, .5, 1),
              child: KurvIcon(14 * s, KurvIcons.chevronDown, color: const Color(0xFF5CE0B8), width: 3),
            ),
          ],
        ),
      ),
    );
  }
}

/// A paper chip of the pickup card (`pv/pf/ps`): teal when on, white when off.
class KurvChip extends StatelessWidget {
  const KurvChip({super.key, required this.label, required this.on, required this.onTap, this.padding = 12});

  final String label;
  final bool on;
  final VoidCallback onTap;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return OnbPressable(
      onTap: onTap,
      pressDy: 1.5,
      child: AnimatedContainer(
        duration: BergenTokens.motion(context, const Duration(milliseconds: 200)),
        padding: EdgeInsets.symmetric(horizontal: padding * s, vertical: 8 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: on ? cssLinear(165, const [Color(0xFF2A6272), Color(0xFF1E4F5C)]) : cssLinear(180, const [Color(0xFFFFFFFF), Color(0xFFF1ECE1)]),
          boxShadow: on
              ? [
                  BoxShadow(color: rgba(11, 38, 45, .9), offset: Offset(0, 2 * s)),
                  BoxShadow(color: rgba(15, 45, 55, .8), offset: Offset(0, 7 * s), blurRadius: onbBlur(11 * s), spreadRadius: -6 * s),
                ]
              : [
                  BoxShadow(color: rgba(255, 255, 255, .95), spreadRadius: 1),
                  BoxShadow(color: const Color(0xFFD9D2C4), offset: Offset(0, 1.5 * s)),
                  BoxShadow(color: rgba(90, 74, 48, .26), offset: Offset(0, 3 * s)),
                  BoxShadow(color: rgba(35, 32, 29, .45), offset: Offset(0, 7 * s), blurRadius: onbBlur(11 * s), spreadRadius: -7 * s),
                ],
        ),
        child: Text(label, style: bText(context, 11.5, weight: FontWeight.w800, color: on ? Colors.white : const Color(0xFF1B4A57))),
      ),
    );
  }
}

/// A `40×24` toggle (`#2E7E4F` on / `rgba(35,32,29,.22)` off, 18 thumb at
/// left 3 / 21, `.2s`).
class KurvToggle extends StatelessWidget {
  const KurvToggle({super.key, required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: BergenTokens.motion(context, const Duration(milliseconds: 200)),
        width: 40 * s,
        height: 24 * s,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: on ? const Color(0xFF2E7E4F) : rgba(35, 32, 29, .22)),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: BergenTokens.motion(context, const Duration(milliseconds: 200)),
              left: (on ? 21 : 3) * s,
              top: 3 * s,
              child: Container(
                width: 18 * s,
                height: 18 * s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: rgba(35, 32, 29, .35), offset: Offset(0, 1 * s), blurRadius: onbBlur(3 * s))],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── the receipt ─────────────────────────────────────────────────────────────

/// One dotted row of SAMMENDRAG: label 12.5px 600 `#57534B`, the dotted
/// leader, value 13px 800 `#23201D` (or a custom trailing widget).
class KurvRad extends StatelessWidget {
  const KurvRad({super.key, required this.label, this.value, this.trailing});

  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5 * s),
      child: LayoutBuilder(
        builder: (context, box) => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Label and value never take more than their share, so the dotted
            // leader keeps at least a few dots and nothing overflows.
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: box.maxWidth * .5),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: bText(context, 12.5, weight: FontWeight.w600, height: 1.2, color: const Color(0xFF57534B))),
            ),
            SizedBox(width: 6 * s),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: 4 * s),
                child: CustomPaint(size: Size(double.infinity, 1.5 * s), painter: _DotsPainter(s)),
              ),
            ),
            SizedBox(width: 6 * s),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: box.maxWidth * .45),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: trailing ?? Text(value ?? '', style: bText(context, 13, weight: FontWeight.w800, height: 1.2, color: const Color(0xFF23201D))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter(this.s);

  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = rgba(35, 32, 29, .2);
    for (var x = 0.0; x < size.width; x += 3 * s) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1.5 * s, 1.5 * s), p);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.s != s;
}

/// The perforation between the receipt and Å BETALE NÅ (design L5205–5209).
class KurvPerforering extends StatelessWidget {
  const KurvPerforering({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return SizedBox(height: 13 * s, child: CustomPaint(painter: _PerfPainter(s)));
  }
}

class _PerfPainter extends CustomPainter {
  const _PerfPainter(this.s);

  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..color = rgba(35, 32, 29, .16);
    for (var x = 14.0 * s; x < size.width - 14 * s; x += 8 * s) {
      canvas.drawLine(Offset(x, 6 * s), Offset(math.min(x + 4 * s, size.width - 14 * s), 6 * s), dash);
    }
    final hole = Paint()..color = const Color(0xFFEFE8DB);
    canvas.drawCircle(Offset(-8 * s + 8 * s, 7 * s), 8 * s, hole);
    canvas.drawCircle(Offset(size.width, 7 * s), 8 * s, hole);
  }

  @override
  bool shouldRepaint(_PerfPainter old) => old.s != s;
}

/// The teal «Å BETALE NÅ» box (design L5210–5225).
class KurvAaBetale extends StatelessWidget {
  const KurvAaBetale({super.key, required this.total, required this.points});

  final double total;
  final int points;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      padding: EdgeInsets.fromLTRB(14 * s, 13 * s, 14 * s, 13 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18 * s),
        gradient: cssLinear(165, const [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)], const [0, .58, 1]),
        boxShadow: [BoxShadow(color: rgba(15, 45, 55, .75), offset: Offset(0, 12 * s), blurRadius: onbBlur(20 * s), spreadRadius: -12 * s)],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(KasseCopy.a1_kasse_a_betale, style: bText(context, 9.5, weight: FontWeight.w800, letterSpacingEm: .14, color: const Color(0xFF8FB4C0))),
                        SizedBox(height: 2 * s),
                        Text(KasseCopy.a1_kasse_totalt, style: bDisplay(context, 15, letterSpacingEm: -.02, color: const Color(0xFFF5F3EF))),
                      ],
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        KasseCopy.tall(total),
                        key: const Key('a1_kasse_total'),
                        style: bDisplay(context, 32, letterSpacingEm: -.04, height: .9, shadows: [Shadow(color: rgba(4, 20, 28, .45), offset: Offset(0, 2 * s), blurRadius: 6 * s)]),
                      ),
                      SizedBox(width: 3 * s),
                      Text('kr', style: bText(context, 13, weight: FontWeight.w800, letterSpacingEm: -.01, color: const Color(0xFF9FC2CC))),
                    ],
                  ),
                ],
              ),
              Container(
                margin: EdgeInsets.only(top: 11 * s),
                padding: EdgeInsets.only(top: 10 * s),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: rgba(255, 255, 255, .14)))),
                child: Row(
                  children: [
                    KurvIcon(13 * s, KurvIcons.check, color: const Color(0xFF6FE0AE), width: 2.8),
                    SizedBox(width: 7 * s),
                    Expanded(child: Text(KasseCopy.a1_kasse_inkl, style: bText(context, 11, color: const Color(0xFFCFE3E9)))),
                  ],
                ),
              ),
              SizedBox(height: 7 * s),
              Row(
                children: [
                  KurvIcon(13 * s, KurvIcons.kroner, color: const Color(0xFFF2C14E), width: 2.4),
                  SizedBox(width: 7 * s),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: bText(context, 11, color: const Color(0xFFCFE3E9)),
                        children: _bold(KasseCopy.a1_kasse_poeng_linje(points), '$points', bText(context, 11, weight: FontWeight.w800, color: const Color(0xFFF2C14E))),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          bergenInsetTop(radius: 18 * s, height: 1.5 * s, alpha: .22),
        ],
      ),
    );
  }

  static List<InlineSpan> _bold(String text, String needle, TextStyle style) {
    final i = text.indexOf(needle);
    if (i < 0) return [TextSpan(text: text)];
    return [
      TextSpan(text: text.substring(0, i)),
      TextSpan(text: needle, style: style),
      TextSpan(text: text.substring(i + needle.length)),
    ];
  }
}

/// The footer note (design L5226–5228): `rgba(220,233,236,.5)` blur 20,
/// the lantern dot on `lyktPuls 3s`, 11.5px 600 `#173E48`.
class KurvFot extends StatelessWidget {
  const KurvFot({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return BergenCssShadow(
      radius: 20 * s,
      shadows: [BoxShadow(color: rgba(30, 79, 92, .4), offset: Offset(0, 14 * s), blurRadius: onbBlur(26 * s), spreadRadius: -16 * s)],
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20 * s),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20 * s, sigmaY: 20 * s),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 13 * s, vertical: 11 * s),
            decoration: BoxDecoration(
              color: rgba(220, 233, 236, .5),
              borderRadius: BorderRadius.circular(20 * s),
              border: Border.all(color: rgba(255, 255, 255, .85)),
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    BergenLoop(
                      durationMs: 3000,
                      builder: (context, p, _) {
                        final q = kf(p ?? 0, const [0, .5, 1], const [0, 1, 0], Curves.easeInOut);
                        return Container(
                          width: 9 * s,
                          height: 9 * s,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF2C14E),
                            boxShadow: [BoxShadow(color: rgba(242, 193, 78, .9 + .1 * q), blurRadius: onbBlur((8 + 7 * q) * s))],
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 10 * s),
                    Expanded(child: Text(text, style: bText(context, 11.5, weight: FontWeight.w600, height: 1.45, color: const Color(0xFF173E48)))),
                  ],
                ),
                bergenInsetTop(radius: 20 * s, height: 1.5 * s, alpha: .9),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
