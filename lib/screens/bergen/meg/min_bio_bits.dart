import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../aegil/aegil_bits.dart' show aePose;
import '../kit/bergen_perf.dart';
import 'min_bio.dart';

// ── Min Bio · shared pieces (design L7458–7478, L9693–9762, L4821–4905) ─────

/// The chip looks (`AV`, `MINT`, `ORA`, `GUL`, `NEI`): a two-stop fill (one
/// colour twice when the design's is flat), the border and the text.
@immutable
class BioStil {
  const BioStil(this.a, this.b, this.bd, this.c);

  final Color a, b, bd, c;

  List<CssBg> get bg => [CssLinear(180, [a, b])];

  static BioStil lerp(BioStil x, BioStil y, double t) => BioStil(
        Color.lerp(x.a, y.a, t)!,
        Color.lerp(x.b, y.b, t)!,
        Color.lerp(x.bd, y.bd, t)!,
        Color.lerp(x.c, y.c, t)!,
      );

  static const av = BioStil(Color.fromRGBO(255, 255, 255, .07), Color.fromRGBO(255, 255, 255, .07), Color.fromRGBO(255, 255, 255, .18), Color.fromRGBO(255, 255, 255, .88));
  static const mint = BioStil(Color.fromRGBO(127, 240, 203, .3), Color.fromRGBO(92, 224, 184, .14), Color.fromRGBO(127, 240, 203, .75), Color(0xFFE9FFF7));
  static const ora = BioStil(Color.fromRGBO(249, 162, 115, .34), Color.fromRGBO(233, 92, 44, .18), Color.fromRGBO(249, 162, 115, .85), Color(0xFFFFE3D5));
  static const gul = BioStil(Color.fromRGBO(242, 193, 78, .16), Color.fromRGBO(242, 193, 78, .16), Color.fromRGBO(246, 210, 122, .7), Color(0xFFFFE7A8));
  static const nei = BioStil(Color.fromRGBO(255, 148, 102, .12), Color.fromRGBO(255, 148, 102, .12), Color.fromRGBO(255, 148, 102, .6), Color(0xFFFFC7AE));
}

/// The icon paths (`IK`), drawn on a 24 × 24 box.
abstract final class BioIk {
  static const hake = 'M4.5 12.5l5 5 10-11';
  static const varsel = 'M12 3l9 16H3z M12 10v4 M12 17v.01';
  static const blad = 'M5 19c0-8 6-14 15-14 0 9-6 15-14 15z M5 19l7-7';
  static const hjerte = 'M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z';
  static const nei = 'M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18z M6 6l12 12';
  static const pluss = 'M12 5v14M5 12h14';
  static const stjerne = 'M12 2l2.2 7.8L22 12l-7.8 2.2L12 22l-2.2-7.8L2 12l7.8-2.2z';
  static const blyant = 'M4 20h4L19 9l-4-4L4 16z M13.5 6.5l4 4';
  static const kryss = 'M6 6l12 12M18 6L6 18';
}

String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// A stroked design icon ([fill] for the star).
class BioIkon extends StatelessWidget {
  const BioIkon(this.d, {super.key, required this.color, this.size = 13, this.width = 2.6, this.fill = false, this.w});

  final String d;
  final Color color;
  final double size;
  final double width;
  final bool fill;

  /// The box width when it differs from [size] (`svg width="{{ c.ikW }}"`).
  final double? w;

  @override
  Widget build(BuildContext context) {
    final bw = w ?? size;
    if (bw <= 0) return const SizedBox.shrink();
    final op = color.a;
    final svg = fill
        ? '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="$d" fill="${_hex(color)}" fill-opacity="$op"/></svg>'
        : '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="$d" fill="none" stroke="${_hex(color)}" stroke-opacity="$op" stroke-width="$width" stroke-linecap="round" stroke-linejoin="round"/></svg>';
    return SizedBox(width: bw, height: size, child: SvgPicture.string(svg, width: bw, height: size));
  }
}

/// One small chip (24 px: the card, the panel, «fanget opp»).
class BioSmaaChip extends StatelessWidget {
  const BioSmaaChip({super.key, required this.tx, required this.stil, this.ik, this.merke, this.merkeBg, this.merkeC, this.panel = false});

  final String tx;
  final BioStil stil;
  final String? ik;
  final String? merke;
  final Color? merkeBg, merkeC;

  /// The panel's chip: no icon, 9 px each side, a 8 px badge.
  final bool panel;

  @override
  Widget build(BuildContext context) => CssBox(
        height: 24,
        radius: BorderRadius.circular(999),
        bg: stil.bg,
        border: Border.all(color: stil.bd),
        padding: panel ? const EdgeInsets.symmetric(horizontal: 9) : const EdgeInsets.fromLTRB(7, 0, 9, 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ik != null) ...[BioIkon(ik!, color: stil.c, size: 11), const SizedBox(width: 4)],
            Flexible(child: Text(tx, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(11, weight: FontWeight.w800, color: stil.c))),
            if (merke != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: merkeBg, borderRadius: BorderRadius.circular(5)),
                child: Text(merke!, style: inter(8, weight: FontWeight.w800, em: .06, color: merkeC ?? Colors.white, height: 1.2)),
              ),
            ],
          ],
        ),
      );
}

/// `bioDot`: the breathing mint dot (opacity .5 ↔ 1, scale .85 ↔ 1.15).
class BioDot extends StatelessWidget {
  const BioDot({super.key, this.ms = 2200, this.delay = 0, this.size = 6, this.glow = 6, this.ring});

  final double ms, delay, size, glow;

  /// The panel row's dot: a 2 px ring in the card colour instead of a glow.
  final Color? ring;

  @override
  Widget build(BuildContext context) => LfLoop(
        // At rest (`lite`, `still`): the dot's own look, no keyframe.
        frozenMs: -1,
        builder: (context, t, child) {
          if (t < 0) return child!;
          final p = kfLoop(t, delay, ms) ?? 0;
          final o = kf(p, const [0, .5, 1], const [.5, 1, .5], cssEaseInOut);
          final s = kf(p, const [0, .5, 1], const [.85, 1.15, .85], cssEaseInOut);
          return Opacity(opacity: o, child: Transform.scale(scale: s, child: child));
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF5CE0B8),
            border: ring == null ? null : Border.all(color: ring!, width: 2, strokeAlign: BorderSide.strokeAlignOutside),
            boxShadow: ring == null && glow > 0 ? [BoxShadow(color: const Color(0xFF5CE0B8), blurRadius: glow / 2)] : null,
          ),
        ),
      );
}

/// «● Ærend Intelligence».
class BioIntelligence extends StatelessWidget {
  const BioIntelligence({super.key});

  @override
  Widget build(BuildContext context) => Container(
        height: 20,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(92, 224, 184, .14),
          border: Border.all(color: const Color.fromRGBO(92, 224, 184, .42)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BioDot(),
            const SizedBox(width: 5),
            Flexible(child: Text(BioCopy.intelligence, maxLines: 1, overflow: TextOverflow.clip, style: inter(10, weight: FontWeight.w800, color: const Color(0xFF7FF0CB)))),
          ],
        ),
      );
}

/// The five score segments (`bioSeg`): mint, gold at 5/5, and a pop on the
/// one that just filled (`bioSegA`, .5 s).
class BioSegmenter extends StatefulWidget {
  const BioSegmenter({super.key, required this.score, this.h = 7});

  final int score;
  final double h;

  @override
  State<BioSegmenter> createState() => _BioSegmenterState();
}

class _BioSegmenterState extends State<BioSegmenter> with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  int _i = -1;

  @override
  void didUpdateWidget(BioSegmenter old) {
    super.didUpdateWidget(old);
    if (widget.score > old.score) {
      _i = widget.score - 1;
      _pop.duration = BergenPerf.oneShot(context, 500);
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gull = widget.score == 5;
    return Row(
      children: [
        for (var i = 0; i < 5; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: AnimatedBuilder(
              animation: _pop,
              builder: (context, child) {
                final sy = i == _i && _pop.isAnimating ? kf(_pop.value, const [0, .4, 1], const [1, 1.9, 1], const Cubic(.3, 1.5, .5, 1)) : 1.0;
                return Transform(alignment: Alignment.center, transform: Matrix4.diagonal3Values(1, sy, 1), child: child);
              },
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: i < widget.score ? 1 : 0),
                duration: BergenPerf.oneShot(context, 400),
                curve: cssEase,
                builder: (context, on, _) {
                  final a = gull ? const Color(0xFFFFE7A8) : const Color(0xFF5CE0B8);
                  final b = gull ? const Color(0xFFE9AC3C) : const Color(0xFF9FF0D4);
                  const tom = Color.fromRGBO(255, 255, 255, .14);
                  final glow = gull ? const Color.fromRGBO(242, 193, 78, .6) : const Color.fromRGBO(92, 224, 184, .5);
                  return CssBox(
                    height: widget.h,
                    radius: BorderRadius.circular(999),
                    bg: [CssLinear(90, [Color.lerp(tom, a, on)!, Color.lerp(tom, b, on)!])],
                    shadows: on > 0 ? [CssShadow(0, 0, 8, 0, glow.withValues(alpha: glow.a * on))] : const [],
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// `bioSkannRing`: the mint arc turning around Ægil's portrait (3.6 s).
class BioRingPortrett extends StatelessWidget {
  const BioRingPortrett({super.key, this.size = 52, this.inset = 2.5, this.aegW = 46, this.aegBunn = -8, this.merke = 19, this.merkeIk = 11, this.merkeR = -3, this.merkeB = -2});

  final double size, inset, aegW, aegBunn, merke, merkeIk, merkeR, merkeB;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: LfLoop(
                builder: (context, t, _) => CustomPaint(painter: _Ring(((t / 3600) % 1) * 2 * math.pi)),
              ),
            ),
            Positioned.fill(
              left: inset,
              top: inset,
              right: inset,
              bottom: inset,
              child: ClipOval(
                child: CssBox(
                  bg: const [CssLinear(165, [Color(0xFF2F6E80), Color(0xFF173E48)])],
                  shadows: const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .25))],
                  radius: BorderRadius.circular(999),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: (size - 2 * inset - aegW) / 2,
                        width: aegW,
                        bottom: aegBunn,
                        child: LfLoop(
                          builder: (context, t, child) => Transform(alignment: Alignment.bottomCenter, transform: aegStaa(t, 3400), child: child),
                          child: Image.asset(aePose('front'), width: aegW, fit: BoxFit.fitWidth),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: merkeR,
              bottom: merkeB,
              width: merke,
              height: merke,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFE7A8), Color(0xFFE9AC3C)]),
                  boxShadow: [
                    BoxShadow(color: Color(0xFF23596A), spreadRadius: 2),
                    BoxShadow(color: Color.fromRGBO(242, 193, 78, .6), blurRadius: 5),
                  ],
                ),
                alignment: Alignment.center,
                child: BioIkon(BioIk.stjerne, color: const Color(0xFF4A300A), size: merkeIk, fill: true),
              ),
            ),
          ],
        ),
      );
}

class _Ring extends CustomPainter {
  const _Ring(this.a);

  final double a;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    // conic-gradient(from 0deg, transparent 0, mint .95 80deg, transparent 150deg …)
    canvas.drawOval(
      r,
      Paint()
        ..shader = SweepGradient(
          colors: const [Color.fromRGBO(127, 240, 203, 0), Color.fromRGBO(127, 240, 203, .95), Color.fromRGBO(127, 240, 203, 0), Color.fromRGBO(127, 240, 203, 0)],
          stops: const [0, 80 / 360, 150 / 360, 1],
          transform: GradientRotation(a - math.pi / 2),
        ).createShader(r),
    );
  }

  @override
  bool shouldRepaint(covariant _Ring old) => old.a != a;
}

/// The orange pencil key (34 px on the card, 38 on the panel).
class BioBlyant extends StatelessWidget {
  const BioBlyant({super.key, this.size = 34, this.ik = 14});

  final double size, ik;

  @override
  Widget build(BuildContext context) => CssBox(
        width: size,
        height: size,
        radius: BorderRadius.circular(999),
        bg: const [CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1])],
        shadows: const [
          CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .4)),
          CssShadow(0, 1.5, 0, 0, Color(0xFFC4491A)),
          CssShadow(0, 6, 10, -6, Color.fromRGBO(200, 70, 25, .8)),
        ],
        child: Center(child: BioIkon(BioIk.blyant, color: Colors.white, size: ik)),
      );
}

/// `skinnSveip3`: a soft white band across the card every [ms] (a third of it
/// moving, the rest resting), after [delay].
class BioSveip extends StatelessWidget {
  const BioSveip({super.key, this.ms = 11000, this.delay = 1500, this.alpha = .1});

  final double ms, delay, alpha;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: LayoutBuilder(
          builder: (context, box) => LfLoop(
            frozenMs: -1,
            builder: (context, t, _) {
              final p = t < 0 ? null : kfLoop(t, delay, ms);
              if (p == null || p > 1 / 3) return const SizedBox.shrink();
              final band = box.maxWidth * .3;
              final x = kf(p, const [0, 1 / 3], const [-1.4, 2.4], const Cubic(.4, 0, .2, 1)) * band;
              final o = kf(p, const [0, .0667, 1 / 3], const [0, .7, 0]);
              return Stack(
                children: [
                  Positioned(
                    left: x,
                    top: -box.maxHeight * .4,
                    bottom: -box.maxHeight * .4,
                    width: band,
                    child: Opacity(
                      opacity: o,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.skewX(-18 * math.pi / 180),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: alpha), Colors.white.withValues(alpha: 0)]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
}

/// A one-shot clock that restarts whenever [trigger] changes (a CSS animation
/// whose name flips A/B). Plays in `full` and `lite`; `still` sits at the end.
class BioOmstart extends StatefulWidget {
  const BioOmstart({super.key, required this.trigger, required this.ms, required this.builder, this.child, this.vedStart = true});

  final Object? trigger;
  final double ms;
  final Widget Function(BuildContext context, double t, Widget? child) builder;
  final Widget? child;

  /// Also plays when first shown.
  final bool vedStart;

  @override
  State<BioOmstart> createState() => _BioOmstartState();
}

class _BioOmstartState extends State<BioOmstart> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: widget.ms.round()));
  bool _startet = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startet) return;
    _startet = true;
    if (!widget.vedStart || BergenPerf.of(context) == BergenTier.still) {
      _c.value = 1;
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _c.forward(from: 0);
      });
    }
  }

  @override
  void didUpdateWidget(BioOmstart old) {
    super.didUpdateWidget(old);
    // A trigger that goes back to null (another chip took over) does not replay.
    if (old.trigger != widget.trigger && widget.trigger != null) {
      if (BergenPerf.of(context) == BergenTier.still) {
        _c.value = 1;
      } else {
        _c.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (context, child) => widget.builder(context, _c.value * widget.ms, child),
      );
}

/// `bioPopA/B`: a chip that was just set pops (.42 s).
Widget bioPop(double t, Widget child, {double ms = 420}) {
  final p = kfP(t, 0, ms);
  const c = Cubic(.3, 1.5, .5, 1);
  final s = kf(p, const [0, .6, 1], const [.6, 1.08, 1], c);
  final o = kf(p, const [0, .6, 1], const [0, 1, 1], c);
  return Opacity(opacity: o.clamp(0.0, 1.0), child: Transform.scale(scale: s, child: child));
}
