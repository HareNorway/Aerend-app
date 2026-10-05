import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'lf_css.dart';
import 'lf_icons.dart';
import 'lf_motion.dart';

// ── Launch onboarding · shared pieces ───────────────────────────────────────
// Prototype L1887–2214 (`data-screen-label="Onboarding"`).

// ── Overflate · onboarding ──────────────────────────────────────────────────

/// The persistent sea surface behind every step (L1888): radial base, two
/// drifting light blobs, four expanding rings, vignette and bottom shade.
/// The blobs' CSS `blur(28/30px)` is baked into softer radial stops (one
/// blur layer per screen — the ladder's frosted glass owns it).
class LfSurface extends StatelessWidget {
  const LfSurface({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        return RepaintBoundary(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              const Positioned.fill(
                child: CssBox(
                  bg: [
                    CssRadial(
                      [Color(0xFF3A7080), Color(0xFF2F6270), Color(0xFF1F4A56)],
                      stops: [0, .45, 1],
                      rx: 1.1,
                      ry: .7,
                      cx: .5,
                      cy: .22,
                    ),
                  ],
                ),
              ),
              _blob(w, h, left: -.2 * w, top: -.1 * h, bw: .8 * w, bh: .5 * h,
                  color: const Color.fromRGBO(255, 255, 255, .14), dur: 17000, delay: 0, reverse: false),
              _blob(w, h, left: w - (-.25 * w) - .75 * w, top: .22 * h, bw: .75 * w, bh: .44 * h,
                  color: const Color.fromRGBO(120, 200, 190, .16), dur: 23000, delay: -9000, reverse: true),
              _ring(cx: .5 * w, cy: .38 * h, rw: 300, rh: 110, bw: 1.5, a: .55, dur: 9000, delay: 0),
              _ring(cx: .5 * w, cy: .38 * h, rw: 300, rh: 110, bw: 1, a: .45, dur: 9000, delay: 1100),
              _ring(cx: .22 * w, cy: .72 * h, rw: 180, rh: 64, bw: 1, a: .4, dur: 12000, delay: 5000),
              _ring(cx: .82 * w, cy: .16 * h, rw: 140, rh: 50, bw: 1, a: .4, dur: 14000, delay: 7500),
              const Positioned.fill(
                child: CssBox(
                  bg: [
                    CssRadial(
                      [Color(0x00000000), Color(0x00000000), Color.fromRGBO(8, 26, 36, .45)],
                      stops: [0, .45, 1],
                      rx: 1.2,
                      ry: .8,
                      cx: .5,
                      cy: .2,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: .42 * h,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromRGBO(15, 31, 43, 0),
                        Color.fromRGBO(15, 31, 43, .62),
                        Color.fromRGBO(15, 31, 43, .86),
                      ],
                      stops: [0, .65, 1],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// `onbLysDrift` — translate3d(14px,-10px) scale(1.06) at 50%.
  static Widget _blob(
    double w,
    double h, {
    required double left,
    required double top,
    required double bw,
    required double bh,
    required Color color,
    required double dur,
    required double delay,
    required bool reverse,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: bw,
      height: bh,
      child: LfLoop(
        builder: (context, t, child) {
          var p = ((t - delay) / dur) % 1.0;
          if (reverse) p = 1 - p;
          final k = kf(p, const [0, .5, 1], const [0, 1, 0], cssEaseInOut);
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.translationValues(14 * k, -10 * k, 0)
              ..scaleByDouble(1 + .06 * k, 1 + .06 * k, 1, 1),
            child: child,
          );
        },
        child: CssBox(
          bg: [
            CssRadial(
              [color, color.withValues(alpha: color.a * .55), color.withValues(alpha: 0)],
              stops: const [0, .45, .92],
            ),
          ],
        ),
      ),
    );
  }

  /// `onbRing` — 0–12% scale .55 opacity 0, 18% .5, 60% .18, 100% scale
  /// 1.9 opacity 0; ease-out.
  static Widget _ring({
    required double cx,
    required double cy,
    required double rw,
    required double rh,
    required double bw,
    required double a,
    required double dur,
    required double delay,
  }) {
    return Positioned(
      left: cx - rw / 2,
      top: cy - rh / 2,
      width: rw,
      height: rh,
      child: LfLoop(
        builder: (context, t, child) {
          final p = kfLoop(t, delay, dur);
          if (p == null) return const SizedBox.shrink();
          final s = kf(p, const [0, .12, 1], const [.55, .55, 1.9], cssEaseOut);
          final o = kf(p, const [0, .12, .18, .6, 1], const [0, 0, .5, .18, 0], cssEaseOut);
          return Opacity(
            opacity: o.clamp(0.0, 1.0),
            child: Transform.scale(scale: s, child: child),
          );
        },
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: OvalBorder(side: BorderSide(color: Color.fromRGBO(255, 255, 255, a), width: bw)),
          ),
        ),
      ),
    );
  }
}

// ── Stige (step ladder) ─────────────────────────────────────────────────────

/// L1900: frosted pill with "STEG n/m", the groove with the mint→orange
/// fill, numbered nodes and the gift ring. [index] is the active step.
class LfLadder extends StatefulWidget {
  const LfLadder({super.key, required this.steps, required this.index});

  final List<String> steps;
  final int index;

  @override
  State<LfLadder> createState() => _LfLadderState();
}

class _LfLadderState extends State<LfLadder> with TickerProviderStateMixin {
  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  double _from = 0, _to = 0;
  final GlobalKey<_GiftState> _gift = GlobalKey();

  static const Cubic _fillCurve = Cubic(.3, 1.1, .5, 1);

  double get _andel => widget.steps.length < 2 ? 0 : widget.index / (widget.steps.length - 1);

  @override
  void initState() {
    super.initState();
    _from = _to = _andel;
    _fill.value = 1;
  }

  @override
  void didUpdateWidget(LfLadder old) {
    super.didUpdateWidget(old);
    final a = _andel;
    if (a != _to) {
      _from = _value;
      _to = a;
      _fill.forward(from: 0);
      if (widget.index > old.index) {
        // `onbRos` 420ms after moving forward.
        final i = widget.index == widget.steps.length - 1 ? 3 : widget.index;
        Future.delayed(const Duration(milliseconds: 420), () {
          if (mounted) _gift.currentState?.celebrate(i);
        });
      }
    }
  }

  double get _value => _from + (_to - _from) * _fillCurve.transform(_fill.value);

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.steps.length;
    final idx = widget.index.clamp(0, n - 1);
    return LfRise(
      dur: 400,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        clipBehavior: Clip.none,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: BackdropFilter(
                  filter: ui.ImageFilter.compose(
                    outer: const ColorFilter.matrix(_saturate13),
                    inner: ui.ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            CssBox(
              radius: BorderRadius.circular(999),
              bg: const [
                CssLinear(165, [
                  Color.fromRGBO(255, 255, 255, .18),
                  Color.fromRGBO(255, 255, 255, .07),
                  Color.fromRGBO(8, 26, 36, .2),
                ], [0, .45, 1]),
              ],
              shadows: const [
                CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .36)),
                CssShadow.inset(0, -1, 0, 0, Color.fromRGBO(255, 255, 255, .06)),
                CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .2)),
                CssShadow(0, 3, 0, 0, Color.fromRGBO(8, 30, 38, .55)),
                CssShadow(0, 18, 28, -16, Color.fromRGBO(2, 12, 18, .95)),
              ],
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              child: Row(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 52),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STEG ${idx + 1}/$n',
                          style: inter(8.5, weight: FontWeight.w800, em: .1, height: 1.1, color: const Color.fromRGBO(255, 255, 255, .55)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.steps[idx],
                          softWrap: false,
                          style: jakarta(12.5, height: 1.1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final tw = box.maxWidth;
                          return Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.centerLeft,
                            children: [
                              Positioned(
                                left: 11,
                                right: 11,
                                top: 13,
                                height: 10,
                                child: CssBox(
                                  radius: BorderRadius.circular(99),
                                  bg: const [
                                    CssLinear(180, [Color.fromRGBO(0, 0, 0, .45), Color.fromRGBO(0, 0, 0, .22)]),
                                  ],
                                  shadows: const [
                                    CssShadow.inset(0, 2, 3, 0, Color.fromRGBO(0, 0, 0, .55)),
                                    CssShadow.inset(0, -1, 0, 0, Color.fromRGBO(255, 255, 255, .14)),
                                    CssShadow(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .08)),
                                  ],
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _fill,
                                builder: (context, _) => Positioned(
                                  left: 13,
                                  top: 15,
                                  height: 6,
                                  width: math.max(0, (tw - 26) * _value),
                                  child: const _LadderFill(),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  for (var i = 0; i < n; i++)
                                    _Node(
                                      key: ValueKey('n$i-${i < idx ? 'f' : i == idx ? 'a' : 'i'}'),
                                      nr: i + 1,
                                      state: i < idx ? 0 : (i == idx ? 1 : 2),
                                    ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedBuilder(
                    animation: _fill,
                    builder: (context, _) => _Gift(key: _gift, andel: _value),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `saturate(1.3)` as a colour matrix.
const List<double> _saturate13 = <double>[
  1.2149, -.2145, -.0004, 0, 0, //
  -.0637, 1.0643, -.0006, 0, 0, //
  -.0637, -.2145, 1.2782, 0, 0, //
  0, 0, 0, 1, 0,
];

class _LadderFill extends StatelessWidget {
  const _LadderFill();

  @override
  Widget build(BuildContext context) {
    return CssBox(
      radius: BorderRadius.circular(99),
      clip: true,
      bg: const [
        CssLinear(90, [Color(0xFF3FD0A4), Color(0xFF9CF5D6), Color(0xFFF9A273)], [0, .6, 1]),
      ],
      shadows: const [
        CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .6)),
        CssShadow(0, 0, 10, 0, Color.fromRGBO(92, 224, 184, .5)),
      ],
      child: LayoutBuilder(
        builder: (context, box) => LfLoop(
          builder: (context, t, child) {
            // tbSheen 3.2s ease-in-out: -120% → 320% by 30%, then holds.
            final p = (t / 3200) % 1.0;
            final x = kf(p, const [0, .3, 1], const [-1.2, 3.2, 3.2], cssEaseInOut);
            return Transform.translate(
              offset: Offset(x * box.maxWidth * .3, 0),
              child: child,
            );
          },
          child: const FractionallySizedBox(
            widthFactor: .3,
            alignment: Alignment.centerLeft,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0x00FFFFFF), Color(0xB3FFFFFF), Color(0x00FFFFFF)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({super.key, required this.nr, required this.state});

  final int nr;

  /// 0 done, 1 active, 2 ahead.
  final int state;

  static const Cubic _pop = Cubic(.34, 1.56, .64, 1);

  @override
  Widget build(BuildContext context) {
    final CssBg bg = switch (state) {
      0 => const CssRadial(
        [Color(0xFFC8FBE9), Color(0xFF5CE0B8), Color(0xFF23A07C)],
        stops: [0, .5, 1],
        cx: .35,
        cy: .28,
        farthestCorner: true,
        circle: true,
      ),
      1 => const CssRadial(
        [Color(0xFFFFC9A2), Color(0xFFF47A45), Color(0xFFC9461A)],
        stops: [0, .5, 1],
        cx: .35,
        cy: .28,
        farthestCorner: true,
        circle: true,
      ),
      _ => const CssLinear(180, [Color(0xFF2A5A68), Color(0xFF1B4250)]),
    };
    final sh = switch (state) {
      1 => const [
        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .6)),
        CssShadow(0, 2, 0, 0, Color(0xFFA8380F)),
        CssShadow(0, 0, 0, 4, Color.fromRGBO(242, 109, 61, .22)),
        CssShadow(0, 6, 12, -4, Color.fromRGBO(242, 109, 61, .8)),
      ],
      0 => const [
        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .7)),
        CssShadow(0, 2, 0, 0, Color(0xFF187A5E)),
        CssShadow(0, 5, 10, -4, Color.fromRGBO(47, 184, 147, .8)),
      ],
      _ => const [
        CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .2)),
        CssShadow.inset(0, -1, 2, 0, Color.fromRGBO(0, 0, 0, .35)),
        CssShadow(0, 2, 0, 0, Color.fromRGBO(0, 0, 0, .35)),
      ],
    };
    Widget node = CssBox(
      width: 22,
      height: 22,
      radius: BorderRadius.circular(11),
      bg: [bg],
      shadows: sh,
      child: Center(
        child: state == 0
            ? LfOnce(
                ms: 380,
                builder: (context, t, child) => _hake(t / 380, child!),
                child: const LfStroke(LfIco.check, size: 11, color: Color(0xFF0F1F2B), width: 4),
              )
            : Text(
                '$nr',
                style: inter(9.5, weight: FontWeight.w800, height: 1,
                    color: state == 1 ? Colors.white : const Color.fromRGBO(255, 255, 255, .55)),
              ),
      ),
    );
    if (state == 1) {
      // onbNode .5s: scale .6 → 1.18 (60%) → 1.
      node = LfOnce(
        ms: 500,
        builder: (context, t, child) => Transform.scale(
          scale: kf(t / 500, const [0, .6, 1], const [.6, 1.18, 1], _pop),
          child: child,
        ),
        child: node,
      );
    }
    return node;
  }

  /// `onbHake` — scale(0) rotate(-30deg) → 1.25/4deg (60%) → 1/0.
  static Widget _hake(double p, Widget child) {
    final s = kf(p, const [0, .6, 1], const [0, 1.25, 1], _pop);
    final r = kf(p, const [0, .6, 1], const [-30, 4, 0], _pop);
    final o = kf(p, const [0, .6, 1], const [0, 1, 1], _pop);
    return Opacity(
      opacity: o.clamp(0.0, 1.0),
      child: Transform.rotate(angle: rad(r), child: Transform.scale(scale: s, child: child)),
    );
  }
}

Widget lfHake(double p, Widget child) => _Node._hake(p, child);

/// The welcome-gift ring (`data-onbgave`) with `onbRos`: wiggle, 12
/// sparks and a gold label under it.
class _Gift extends StatefulWidget {
  const _Gift({super.key, required this.andel});

  final double andel;

  @override
  State<_Gift> createState() => _GiftState();
}

class _GiftState extends State<_Gift> with TickerProviderStateMixin {
  late final AnimationController _wiggle = AnimationController(vsync: this, duration: const Duration(milliseconds: 560));
  late final AnimationController _sparks = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  late final AnimationController _label = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  List<(double, double, double, Color)> _dots = const [];
  String _text = '';

  static const _labels = ['', 'Godt jobbet!', 'Snart i mål!', 'Gaven er din!'];

  void celebrate(int i) {
    if (MediaQuery.disableAnimationsOf(context)) return;
    HapticFeedback.lightImpact();
    final r = math.Random();
    const f = [Color(0xFFF2C14E), Color(0xFF5CE0B8), Color(0xFFFFFFFF), Color(0xFFF9A273)];
    _dots = [
      for (var k = 0; k < 12; k++)
        (k / 12 * math.pi * 2, 22 + r.nextDouble() * 14, 3 + r.nextDouble() * 3, f[k % 4]),
    ];
    _text = (i >= 0 && i < _labels.length && _labels[i].isNotEmpty) ? _labels[i] : 'Bra!';
    _wiggle.forward(from: 0);
    _sparks.forward(from: 0);
    _label.forward(from: 0);
    setState(() {});
  }

  @override
  void dispose() {
    _wiggle.dispose();
    _sparks.dispose();
    _label.dispose();
    super.dispose();
  }

  static const Cubic _wig = Cubic(.3, 1.4, .5, 1);
  static const Cubic _spk = Cubic(.2, .7, .3, 1);
  static const Cubic _lab = Cubic(.2, .9, .3, 1);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _wiggle,
            builder: (context, child) {
              final p = _wiggle.isAnimating ? _wiggle.value : 0.0;
              final s = kf(p, const [0, .4, 1], const [1, 1.22, 1], _wig);
              final r = kf(p, const [0, .4, 1], const [0, -8, 0], _wig);
              return Transform.rotate(angle: rad(r), child: Transform.scale(scale: s, child: child));
            },
            child: CssBox(
              width: 40,
              height: 40,
              radius: BorderRadius.circular(20),
              bg: const [
                CssRadial(
                  [Color.fromRGBO(255, 255, 255, .12), Color.fromRGBO(0, 0, 0, .28)],
                  cx: .5,
                  cy: .35,
                  farthestCorner: true,
                  circle: true,
                ),
              ],
              shadows: const [
                CssShadow.inset(0, 2, 4, 0, Color.fromRGBO(0, 0, 0, .55)),
                CssShadow.inset(0, -1, 0, 0, Color.fromRGBO(255, 255, 255, .14)),
                CssShadow(0, 0, 16, 0, Color.fromRGBO(242, 193, 78, .25)),
              ],
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Positioned.fill(child: CustomPaint(painter: _GiftRing(widget.andel))),
                  const LfSvgAsset('onb_ico_gaver', w: 22, h: 23),
                  AnimatedBuilder(
                    animation: _sparks,
                    builder: (context, _) {
                      if (!_sparks.isAnimating) return const SizedBox.shrink();
                      final p = _spk.transform(_sparks.value);
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (final (a, v, s, c) in _dots)
                            Positioned(
                              left: 20 - s / 2 + math.cos(a) * v * p,
                              top: 20 - s / 2 + math.sin(a) * v * p,
                              child: Opacity(
                                opacity: (1 - p).clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: 1 - .6 * p,
                                  child: Container(
                                    width: s,
                                    height: s,
                                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _label,
            builder: (context, _) {
              if (!_label.isAnimating) return const SizedBox.shrink();
              final o = kf(_label.value, const [0, .18, .8, 1], const [0, 1, 1, 0], _lab);
              final y = kf(_label.value, const [0, .18, .8, 1], const [6, 0, -2, -10], _lab);
              final sc = kf(_label.value, const [0, .18, .8, 1], const [.8, 1, 1, .96], _lab);
              return Positioned(
                top: 40 + 6,
                left: -60,
                right: -60,
                child: IgnorePointer(
                  child: Center(
                    child: Opacity(
                      opacity: o.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, y),
                        child: Transform.scale(
                          scale: sc,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFFFE19A), Color(0xFFF2B63C)],
                              ),
                              boxShadow: const [
                                BoxShadow(color: Color.fromRGBO(0, 0, 0, .5), offset: Offset(0, 8), blurRadius: 16, spreadRadius: -6),
                              ],
                            ),
                            child: Text(_text, softWrap: false, style: jakarta(11.5, color: const Color(0xFF3A2508))),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GiftRing extends CustomPainter {
  const _GiftRing(this.andel);

  final double andel;

  @override
  void paint(Canvas canvas, Size size) {
    const c = Offset(20, 20);
    canvas.drawCircle(
      c,
      16.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..color = const Color.fromRGBO(0, 0, 0, .3),
    );
    if (andel <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: 16.5),
      -math.pi / 2,
      math.pi * 2 * andel.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFF2C14E),
    );
  }

  @override
  bool shouldRepaint(_GiftRing old) => old.andel != andel;
}

// ── Ægil speaks ─────────────────────────────────────────────────────────────

/// The bubble's typing dots (`onbPrikkUt .2s .7s`) and the text arriving
/// (`onbTekst .35s .75s`). The text keeps its space from the start.
class LfTyping extends StatelessWidget {
  const LfTyping({super.key, required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return LfOnce(
      ms: 1100,
      builder: (context, t, _) {
        final tp = kfP(t, 750, 350);
        final dots = 1 - kfP(t, 700, 200);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Opacity(
              opacity: tp,
              child: Transform.translate(
                offset: Offset(0, 3 * (1 - tp)),
                child: LfPretty(text, style: style),
              ),
            ),
            if (dots > 0)
              Positioned(
                left: 0,
                bottom: 1,
                child: Opacity(opacity: dots, child: const LfDots()),
              ),
          ],
        );
      },
    );
  }
}

/// Three mint dots bouncing (`onbPrikk .9s`, .15s apart).
class LfDots extends StatelessWidget {
  const LfDots({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          LfLoop(
            builder: (context, t, child) {
              final p = kfLoop(t, 150.0 * i, 900) ?? 0;
              final y = kf(p, const [0, .5, 1], const [0, -3, 0], cssEaseInOut);
              final o = kf(p, const [0, .5, 1], const [.45, 1, .45], cssEaseInOut);
              return Opacity(opacity: o, child: Transform.translate(offset: Offset(0, y), child: child));
            },
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: Color(0xFF2FB893), shape: BoxShape.circle),
            ),
          ),
        ],
      ],
    );
  }
}

/// Vilkår: Ægil standing (66×72) next to a bubble with the "ÆGIL" label.
class LfAegilStanding extends StatelessWidget {
  const LfAegilStanding({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return LfBubbleIn(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 66,
            height: 72,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned(
                  left: 12,
                  bottom: -2,
                  width: 44,
                  height: 10,
                  child: CssBox(
                    bg: [
                      CssRadial.closestSide([Color.fromRGBO(3, 16, 24, .6), Color.fromRGBO(3, 16, 24, 0)]),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: LfLoop(
                    builder: (context, t, child) => Transform(
                      transform: aegStaa(t, 3400),
                      alignment: Alignment.bottomCenter,
                      child: child,
                    ),
                    child: Image.asset(
                      'assets/images/aegil/aegil_landing.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: CssBox(
                radius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(5),
                ),
                bg: const [CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFEEF3F2)])],
                shadows: const [
                  CssShadow.inset(0, 1, 0, 0, Color(0xFFFFFFFF)),
                  CssShadow(0, 3, 0, 0, Color(0xFF9FB2B6)),
                  CssShadow(0, 14, 22, -12, Color.fromRGBO(3, 16, 24, .85)),
                ],
                padding: const EdgeInsets.fromLTRB(13, 10, 13, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ÆGIL', style: inter(9.5, weight: FontWeight.w800, em: .1, color: const Color(0xFF1F8A66))),
                    const SizedBox(height: 2),
                    LfTyping(
                      text: text,
                      style: inter(12.5, weight: FontWeight.w700, height: 1.42, color: const Color(0xFF173E48)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Konto / Ferdig: a framed Ægil portrait rocking (`onbBaat`) next to a
/// white bubble with a tail.
class LfAegilPortrait extends StatelessWidget {
  const LfAegilPortrait({
    super.key,
    required this.text,
    required this.image,
    this.size = 48,
    this.radius = 16,
    this.delay = 160,
  });

  final String text;
  final String image;
  final double size;
  final double radius;
  final double delay;

  @override
  Widget build(BuildContext context) {
    return LfBubbleIn(
      delay: delay,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          LfLoop(
            builder: (context, t, child) => Transform(
              transform: onbBaat(t),
              alignment: Alignment.center,
              child: child,
            ),
            child: LfPortrait(image: image, size: size, radius: radius),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CssBox(
                  radius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                    bottomLeft: Radius.circular(6),
                  ),
                  bg: const [CssSolid(Colors.white)],
                  shadows: const [
                    CssShadow(0, 2, 0, 0, Color.fromRGBO(180, 171, 160, .8)),
                    CssShadow(0, 14, 24, -14, Color.fromRGBO(3, 16, 24, .9)),
                  ],
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  child: SizedBox(
                    width: double.infinity,
                    child: LfTyping(
                      text: text,
                      style: inter(12, weight: FontWeight.w700, height: 1.4, color: const Color(0xFF23201D)),
                    ),
                  ),
                ),
                Positioned(
                  left: -6,
                  bottom: 8,
                  child: ClipPath(
                    clipper: _TailClip(),
                    child: const SizedBox(width: 12, height: 12, child: ColoredBox(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `clip-path: polygon(100% 0,100% 100%,0 100%)`.
class _TailClip extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..moveTo(s.width, 0)
    ..lineTo(s.width, s.height)
    ..lineTo(0, s.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// A rounded Ægil portrait with the white ring.
class LfPortrait extends StatelessWidget {
  const LfPortrait({super.key, required this.image, required this.size, required this.radius});

  final String image;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: const Color.fromRGBO(255, 255, 255, .14),
        boxShadow: [
          const BoxShadow(color: Color.fromRGBO(255, 255, 255, .85), spreadRadius: 2),
          BoxShadow(
            color: const Color.fromRGBO(3, 16, 24, .9),
            offset: Offset(0, size >= 84 ? 14 : 12),
            blurRadius: (size >= 84 ? 24 : 20) / 2 / .57735,
            spreadRadius: size >= 84 ? -14 : -12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(image, fit: BoxFit.cover, filterQuality: FilterQuality.medium),
      ),
    );
  }
}

// ── CTAs ────────────────────────────────────────────────────────────────────

/// `GT` / `AV` CTA (L2054 …): 54px, radius 18, orange 3D when [ready],
/// frosted otherwise; `tbSheen` sweeps once ready; presses 3px.
class LfCta extends StatefulWidget {
  const LfCta({super.key, required this.label, required this.ready, required this.onTap, this.arrow = true});

  final String label;
  final bool ready;
  final VoidCallback onTap;
  final bool arrow;

  @override
  State<LfCta> createState() => _LfCtaState();
}

class _LfCtaState extends State<LfCta> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.ready;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedSlide(
        offset: Offset(0, _down ? 3 / 54 : 0),
        duration: const Duration(milliseconds: 140),
        curve: cssEase,
        child: SizedBox(
          height: 54,
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: r ? 0 : 1,
                  duration: const Duration(milliseconds: 250),
                  child: const CssBox(
                    radius: BorderRadius.all(Radius.circular(18)),
                    bg: [
                      CssLinear(180, [Color.fromRGBO(255, 255, 255, .16), Color.fromRGBO(255, 255, 255, .08)]),
                    ],
                    shadows: [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .2))],
                  ),
                ),
              ),
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: r ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const CssBox(
                    radius: BorderRadius.all(Radius.circular(18)),
                    bg: [CssLinear(180, [Color(0xFFF68450), Color(0xFFE65A28)])],
                    shadows: [
                      CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
                      CssShadow(0, 2, 0, 0, Color(0xFFC4491A)),
                      CssShadow(0, 18, 28, -14, Color.fromRGBO(200, 70, 25, .95)),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedOpacity(
                    opacity: r ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const LfSheen(widthFactor: .36, durMs: 3800, delayMs: 1000, alpha: .45),
                  ),
                ),
              ),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.label, style: jakarta(15.5)),
                    if (widget.arrow) ...[
                      const SizedBox(width: 8),
                      const LfStroke(LfIco.arrowRight, size: 15, color: Colors.white, width: 2.8),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `tbSheen`: a 100deg white band sweeping across (−120% → 320% in the
/// first 30% of the cycle).
class LfSheen extends StatelessWidget {
  const LfSheen({super.key, required this.widthFactor, required this.durMs, this.delayMs = 0, this.alpha = .45});

  final double widthFactor;
  final double durMs;
  final double delayMs;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final bw = box.maxWidth * widthFactor;
        return LfLoop(
          builder: (context, t, child) {
            final p = kfLoop(t, delayMs, durMs);
            if (p == null) return const SizedBox.shrink();
            final x = kf(p, const [0, .3, 1], const [-1.2, 3.2, 3.2], cssEaseInOut);
            return Transform.translate(offset: Offset(x * bw, 0), child: child);
          },
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: bw,
              height: box.maxHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: const Alignment(-1, -.18),
                    end: const Alignment(1, .18),
                    colors: [
                      const Color(0x00FFFFFF),
                      Color.fromRGBO(255, 255, 255, alpha),
                      const Color(0x00FFFFFF),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The floating pill CTA (`data-kn="o"`): orange, radius 999, `aeKnSvev`
/// float with the `aeKnSkygge` ellipse shadow under it; optional
/// `onbPuls` mint ring.
class LfPillCta extends StatelessWidget {
  const LfPillCta({
    super.key,
    required this.child,
    required this.onTap,
    this.height = 52,
    this.phaseMs = -800,
    this.pulse = false,
  });

  final Widget child;
  final VoidCallback onTap;
  final double height;
  final double phaseMs;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: RepaintBoundary(
        child: LfLoop(
          builder: (context, t, _) {
            final p = ((t - phaseMs) / 3400) % 1.0;
            final y = kf(p, const [0, .5, 1], const [0, -5, 0], cssEaseInOut);
            final shS = kf(p, const [0, .5, 1], const [1, .82, 1], cssEaseInOut);
            final shO = kf(p, const [0, .5, 1], const [1, .6, 1], cssEaseInOut);
            double ring = 0, ringA = 0;
            if (pulse) {
              final q = kfLoop(t, 1200, 2400);
              if (q != null) {
                ring = kf(q, const [0, .7, 1], const [0, 14, 0], cssEaseOut);
                ringA = kf(q, const [0, .7, 1], const [.55, 0, .55], cssEaseOut);
              }
            }
            return SizedBox(
              height: height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: height + 1,
                    height: 15,
                    child: FractionallySizedBox(
                      widthFactor: .8,
                      child: Opacity(
                        opacity: shO,
                        child: Transform(
                          alignment: Alignment.center,
                          // `translate` on the pill and the opposite move on
                          // its ::after cancel out: the shadow only breathes.
                          transform: Matrix4.diagonal3Values(shS, 1, 1),
                          child: const CssBox(
                            bg: [
                              CssRadial.closestSide(
                                [Color.fromRGBO(8, 26, 32, .5), Color.fromRGBO(0, 0, 0, 0)],
                                stops: [0, .72],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: y,
                    height: height,
                    child: CssBox(
                      radius: BorderRadius.circular(999),
                      bg: const [CssLinear(180, [Color(0xFFF68450), Color(0xFFE65A28)])],
                      shadows: [
                        if (ringA > 0) CssShadow(0, 0, 0, ring, Color.fromRGBO(92, 224, 184, ringA)),
                        const CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
                        const CssShadow.inset(0, -3, 6, 0, Color.fromRGBO(150, 40, 10, .3)),
                      ],
                      child: Center(child: child),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Fields ──────────────────────────────────────────────────────────────────

/// White label field (L2096): 58px, radius 17, icon, small caps label,
/// input and the 4px validation bar on the left.
class LfField extends StatelessWidget {
  const LfField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    required this.accent,
    this.icon,
    this.obscure = false,
    this.keyboard,
    this.formatters,
    this.onChanged,
    this.inputStyle,
    this.autofill,
    this.textInputAction,
    this.onSubmitted,
    this.focusNode,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final Color accent;
  final Widget? icon;
  final bool obscure;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? formatters;
  final ValueChanged<String>? onChanged;
  final TextStyle? inputStyle;
  final Iterable<String>? autofill;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final style = inputStyle ?? inter(15, weight: FontWeight.w700, color: const Color(0xFF23201D));
    return CssBox(
      height: 58,
      radius: BorderRadius.circular(17),
      bg: const [CssSolid(Colors.white)],
      shadows: const [
        CssShadow(0, 2, 0, 0, Color.fromRGBO(180, 171, 160, .8)),
        CssShadow(0, 14, 24, -16, Color.fromRGBO(3, 16, 24, .9)),
      ],
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                if (icon != null) ...[icon!, const SizedBox(width: 11)],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: inter(10, weight: FontWeight.w800, em: .07, height: 1.2, color: const Color(0xFF9A9188))),
                      const SizedBox(height: 2),
                      TextField(
                        controller: controller,
                        focusNode: focusNode,
                        obscureText: obscure,
                        keyboardType: keyboard,
                        inputFormatters: formatters,
                        onChanged: onChanged,
                        autofillHints: autofill,
                        textInputAction: textInputAction,
                        onSubmitted: onSubmitted,
                        autocorrect: false,
                        enableSuggestions: !obscure,
                        cursorColor: const Color(0xFFF26D3D),
                        cursorWidth: 1.5,
                        style: style,
                        decoration: InputDecoration(
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                          isDense: true,
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: hint,
                          hintStyle: style.copyWith(color: const Color(0xFF757575)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(17)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Field icon in the prototype's grey (`#9A9188`, 18px, stroke 2).
Widget lfFieldIcon(String extra) =>
    LfStroke('', extra: extra, size: 18, color: const Color(0xFF9A9188), width: 2);

// ── Press feedback ──────────────────────────────────────────────────────────

/// `style-active` press transforms: translateY / scale while pressed.
class LfPress extends StatefulWidget {
  const LfPress({super.key, required this.child, required this.onTap, this.dy = 0, this.scale = 1, this.ms = 120});

  final Widget child;
  final VoidCallback? onTap;
  final double dy;
  final double scale;
  final int ms;

  @override
  State<LfPress> createState() => _LfPressState();
}

class _LfPressState extends State<LfPress> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: _down ? 1 : 0),
        duration: Duration(milliseconds: widget.ms),
        curve: cssEase,
        builder: (context, v, child) => Transform.translate(
          offset: Offset(0, widget.dy * v),
          child: Transform.scale(scale: 1 + (widget.scale - 1) * v, child: child),
        ),
        child: widget.child,
      ),
    );
  }
}

// ── Toast (`kSi`) ───────────────────────────────────────────────────────────

/// The prototype's toast (L9524): Ægil walking in (`aegLop`) beside a white
/// 3D bubble (`bobleInn`), `bottom:152px`, 2.6s. Shown in the root overlay.
abstract final class LfToast {
  static OverlayEntry? _entry;
  static int _gen = 0;

  static void show(BuildContext context, String text, {OverlayState? overlay}) {
    overlay ??= Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _entry?.remove();
    final gen = ++_gen;
    _entry = OverlayEntry(
      builder: (context) => IgnorePointer(
        child: LfFrame(
          child: Builder(
            builder: (context) {
              final b = MediaQuery.paddingOf(context).bottom;
              return Stack(
                children: [
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 152 + b * .5,
                    child: _ToastBody(key: ValueKey(gen), text: text),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    overlay.insert(_entry!);
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (gen != _gen) return;
      _entry?.remove();
      _entry = null;
    });
  }
}

class _ToastBody extends StatelessWidget {
  const _ToastBody({super.key, required this.text});

  final String text;

  static const Cubic _walk = Cubic(.2, .9, .3, 1);
  static const Cubic _pop = Cubic(.25, 1.25, .45, 1);

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          LfOnce(
            ms: 420,
            builder: (context, t, child) {
              final p = kfP(t, 0, 420);
              final x = kf(p, const [0, 1], const [-40, 0], _walk);
              final o = kf(p, const [0, .3, 1], const [0, 1, 1], _walk);
              return Opacity(opacity: o.clamp(0.0, 1.0), child: Transform.translate(offset: Offset(x, 0), child: child));
            },
            child: SizedBox(
              width: 56,
              height: 60,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned(
                    left: 9,
                    bottom: -3,
                    width: 38,
                    height: 9,
                    child: CssBox(
                      bg: [
                        CssRadial([Color.fromRGBO(3, 14, 20, .5), Color.fromRGBO(3, 14, 20, 0)], stops: [0, .72]),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    bottom: 0,
                    width: 58,
                    child: LfLoop(
                      builder: (context, t, child) => Transform(
                        transform: aegStaa(t, 3400),
                        alignment: Alignment.bottomCenter,
                        child: child,
                      ),
                      child: Image.asset('assets/images/aegil/aegil_landing.png', width: 58, fit: BoxFit.fitWidth),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: LfOnce(
              ms: 340,
              builder: (context, t, child) {
                final p = _pop.transform(kfP(t, 0, 340));
                return Opacity(
                  opacity: p.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 8 * (1 - p)),
                    child: Transform.scale(scale: .6 + .4 * p, alignment: Alignment.bottomLeft, child: child),
                  ),
                );
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 250 + 28), // content-box max-width + padding
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CssBox(
                      radius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                        bottomLeft: Radius.circular(6),
                      ),
                      bg: const [CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFF4F1EA)])],
                      shadows: const [
                        CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .95)),
                        CssShadow(0, 2, 0, 0, Color(0xFFE5DDCD)),
                        CssShadow(0, 4, 0, 0, Color(0xFFCFC5B2)),
                        CssShadow(0, 5, 0, 0, Color.fromRGBO(50, 38, 20, .4)),
                        CssShadow(0, 16, 24, -12, Color.fromRGBO(6, 26, 36, .7)),
                      ],
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: LfPretty(text, style: jakarta(12.5, em: -.012, height: 1.34, color: const Color(0xFF12303B))),
                    ),
                    Positioned(
                      left: -5,
                      bottom: 9,
                      child: Transform.rotate(
                        angle: math.pi / 4,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F5EF),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: const [BoxShadow(color: Color.fromRGBO(180, 170, 150, .5), offset: Offset(-1.5, 1.5))],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
