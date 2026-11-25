import 'package:flutter/material.dart';

import '../../common/auth/launch/lf_css.dart' show kf;
import 'bergen_perf.dart';

/// TestFlight 6 feedback («the button is missing the animation from Claude design»): the prototype's `knTrykk` — on
/// every press of a pill or round key, the key squashes down and springs back (640 ms) while three rings spread on
/// the ground under it (1.4 s, 0 / 180 / 360 ms apart). The squash adds to whatever the key does already (its float).
/// Like the prototype's layer, the rings are drawn over the screen (the root overlay) — not cut off by the bar the key
/// sits in — with the key's own rounded shape masked out. Nothing under «Roligere bevegelse» / the OS setting.
class KnTrykk extends StatefulWidget {
  const KnTrykk({super.key, required this.child, required this.hoyde, required this.lys, this.s = 1});

  final Widget child;

  /// The key's height (its rings sit on its foot; `d` and `bred` follow from it).
  final double hoyde;

  /// Over a light ground (`knLys ≥ .6`): fjord rings; else white.
  final bool lys;

  /// The frame scale (`context.bs`) for the design px.
  final double s;

  @override
  State<KnTrykk> createState() => _KnTrykkState();
}

class _KnTrykkState extends State<KnTrykk> with TickerProviderStateMixin {
  late final AnimationController _klem = AnimationController(vsync: this, duration: const Duration(milliseconds: 640));
  late final AnimationController _ring = AnimationController(vsync: this, duration: const Duration(milliseconds: 1760));

  static const _klemKurve = Cubic(.3, .7, .4, 1);

  OverlayEntry? _lag;

  @override
  void initState() {
    super.initState();
    _ring.addStatusListener((st) {
      if (st == AnimationStatus.completed) _fjernLag();
    });
  }

  void _fjernLag() {
    _lag?.remove();
    _lag = null;
  }

  @override
  void dispose() {
    _fjernLag();
    _klem.dispose();
    _ring.dispose();
    super.dispose();
  }

  void _trykk(PointerDownEvent _) {
    if (BergenPerf.calmOf(context)) return;
    _klem.forward(from: 0);
    _ringer();
  }

  /// The rings' layer: the key's rect on screen at the press (the prototype's `r`), its scale to design px (`k`).
  void _ringer() {
    final ro = context.findRenderObject();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (ro is! RenderBox || !ro.hasSize || overlay == null) return;
    final m = ro.getTransformTo(null);
    final knapp = MatrixUtils.transformRect(m, Offset.zero & Size(ro.size.width, widget.hoyde));
    final k = knapp.width / ro.size.width;
    final bred = ro.size.width > widget.hoyde * 1.6;
    _fjernLag();
    final lag = OverlayEntry(
      builder: (context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _ring,
          builder: (context, _) => CustomPaint(size: Size.infinite, painter: _Ringer(_ring.value * 1760, knapp, bred, widget.lys, widget.s * k)),
        ),
      ),
    );
    overlay.insert(lag);
    _lag = lag;
    _ring.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return Listener(
      // Its own bounds count: the key under it is often an IgnorePointer (the tap belongs to the pressable outside).
      behavior: HitTestBehavior.translucent,
      onPointerDown: _trykk,
      child: LayoutBuilder(
        builder: (context, box) {
          final h = widget.hoyde;
          final w = box.maxWidth;
          // `bred = w > h·1.6`, `d = h ≥ 46 ? 7 : 5` (design px).
          final hp = h / s, bred = w > h * 1.6;
          final d = (hp >= 46 ? 7 : 5) * s;
          return Stack(
            clipBehavior: Clip.none,
            // The key keeps the size its parent gives it (a loose Stack would let a sizeless key shrink to nothing).
            fit: StackFit.passthrough,
            children: [
              AnimatedBuilder(
                animation: _klem,
                child: widget.child,
                builder: (context, child) {
                  // Always the same Transform (identity at rest): swapping it in and out would rebuild the key and
                  // replay its own entry animations (the price's tick).
                  final p = _klem.isAnimating ? _klemKurve.transform(_klem.value) : 0.0;
                  final y = kf(p, const [0, .2, .6, 1], [0, d, -1.5 * s, 0]);
                  final sx = kf(p, const [0, .2, .6, 1], [1, bred ? .97 : .94, 1.01, 1]);
                  final sy = kf(p, const [0, .2, .6, 1], [1, bred ? .94 : .88, 1.02, 1]);
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..translateByDouble(0, y, 0, 1)
                      ..scaleByDouble(sx, sy, 1, 1),
                    child: child,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The three rings at time [ms] over the screen: centred on the key's foot, `w + 28` wide and 36 tall (wide keys; 24
/// round), `scale(.82,.5) → (1.16,1.75)` (round `.55 → 1.5`), opacity `.8 → 0`, 1400 ms ease-out, 0 / 180 / 360 ms
/// apart, borders 1.5 / 1.5 / 1 px; the key's own rounded shape is masked out.
class _Ringer extends CustomPainter {
  _Ringer(this.ms, this.knapp, this.bred, this.lys, this.s);

  final double ms;
  final Rect knapp;
  final bool bred, lys;

  /// Design px → screen.
  final double s;

  /// CSS / WAAPI `ease-out`.
  static const _easeOut = Cubic(0, 0, .58, 1);

  @override
  void paint(Canvas canvas, Size size) {
    final a = lys ? const [.5, .36, .24] : const [.75, .55, .38];
    final farge = lys ? const Color.fromRGBO(30, 79, 92, 1) : const Color.fromRGBO(255, 255, 255, 1);
    final rr = RRect.fromRectAndRadius(knapp, Radius.circular(knapp.height / 2));
    canvas.save();
    canvas.clipPath(Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), Path()..addRRect(rr)));
    final senter = Offset(knapp.center.dx, knapp.bottom);
    final bw = knapp.width + 28 * s, bh = (bred ? 36 : 24) * s;
    for (var j = 0; j < 3; j++) {
      final t = (ms - j * 180) / 1400;
      if (t <= 0 || t >= 1) continue;
      final p = _easeOut.transform(t);
      final sx = bred ? .82 + (1.16 - .82) * p : .55 + (1.5 - .55) * p;
      final sy = bred ? .5 + (1.75 - .5) * p : sx;
      final op = .8 * (1 - p);
      canvas.drawOval(
        Rect.fromCenter(center: senter, width: bw * sx, height: bh * sy),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (j == 2 ? 1 : 1.5) * s
          ..color = farge.withValues(alpha: a[j] * op),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Ringer old) => old.ms != ms;
}
