import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../snurre/snurre_launcher_policy.dart';
import '../../home/bergen/bergen_nav.dart';

// ── onbWow / hjemInn / myntRegn ─────────────────────────────────────────────
// Prototype L17389–17450: the onboarding opens like a ring in the water from
// the tapped button (1050ms, easeInOutCubic) with a mint ring and a white
// echo; Hjem is underneath. 900ms later 14 gold coins burst from the middle
// and fly to the Meg tab, which bumps.

/// `p < .5 ? 4p³ : 1 − (−2p + 2)³ / 2`.
double _ease(double p) => p < .5 ? 4 * p * p * p : 1 - math.pow(-2 * p + 2, 3) / 2;

/// The reveal route: [screen] shows inside a growing circle centred on
/// [center] (global logical px); the previous route stays visible outside it.
PageRoute<T> lfWowRoute<T extends Object?>(Widget screen, Offset center, {bool coins = true}) {
  return PageRouteBuilder<T>(
    settings: RouteSettings(name: snurreLauncherRouteNameFor(screen)),
    opaque: false,
    transitionDuration: const Duration(milliseconds: 1050),
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (context, a, b) => coins ? _CoinHost(child: screen) : screen,
    transitionsBuilder: (context, animation, _, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      return AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) {
          final p = animation.value;
          if (p >= 1) return child!;
          final size = MediaQuery.sizeOf(context);
          final maxR = math.sqrt(
                math.pow(math.max(center.dx, size.width - center.dx), 2) +
                    math.pow(math.max(center.dy, size.height - center.dy), 2),
              ) +
              60;
          final r = _ease(p) * maxR;
          final r2 = math.max(0.0, _ease(math.max(0, p - .12) / .88) * maxR * .92);
          return Stack(
            children: [
              ClipPath(clipper: _Circle(center, r), child: child),
              IgnorePointer(
                child: CustomPaint(
                  size: size,
                  painter: _Rings(center, r, r2, p),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

class _Circle extends CustomClipper<Path> {
  const _Circle(this.c, this.r);

  final Offset c;
  final double r;

  @override
  Path getClip(Size size) => Path()..addOval(Rect.fromCircle(center: c, radius: math.max(r, .01)));

  @override
  bool shouldReclip(_Circle old) => old.r != r || old.c != c;
}

class _Rings extends CustomPainter {
  const _Rings(this.c, this.r, this.r2, this.p);

  final Offset c;
  final double r, r2, p;

  @override
  void paint(Canvas canvas, Size size) {
    final o1 = (1 - math.pow(p, 3)).clamp(0.0, 1.0).toDouble();
    if (r > 0 && o1 > 0) {
      // 0 0 34px 10px rgba(92,224,184,.55): soft outer glow.
      canvas.drawCircle(
        c,
        r + 10,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20
          ..color = Color.fromRGBO(92, 224, 184, .55 * o1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 17),
      );
      // inset 0 0 40px rgba(255,255,255,.35)
      canvas.drawCircle(
        c,
        math.max(0, r - 10),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20
          ..color = Color.fromRGBO(255, 255, 255, .35 * o1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
      // 0 0 0 3px rgba(156,245,214,.95)
      canvas.drawCircle(
        c,
        r + 1.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Color.fromRGBO(156, 245, 214, .95 * o1),
      );
    }
    final o2 = (.8 * (1 - p)).clamp(0.0, 1.0);
    if (r2 > 0 && o2 > 0) {
      canvas.drawCircle(
        c,
        r2 + 1,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Color.fromRGBO(255, 255, 255, .55 * o2),
      );
    }
  }

  @override
  bool shouldRepaint(_Rings old) => old.r != r || old.r2 != r2 || old.p != p;
}

/// Runs `myntRegn` over the new screen 900ms after it arrives.
class _CoinHost extends StatefulWidget {
  const _CoinHost({required this.child});

  final Widget child;

  @override
  State<_CoinHost> createState() => _CoinHostState();
}

class _CoinHostState extends State<_CoinHost> with TickerProviderStateMixin {
  AnimationController? _c;
  final List<(double, double, double)> _coins = [];
  Offset _target = Offset.zero;
  Offset _start = Offset.zero;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), _rain);
  }

  void _rain() {
    if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final size = box.size;
    _start = Offset(size.width / 2, size.height * .42);
    final meg = BergenBottomNav.megTabKey.currentContext?.findRenderObject() as RenderBox?;
    if (meg != null && meg.hasSize && meg.attached) {
      _target = box.globalToLocal(meg.localToGlobal(meg.size.center(Offset.zero)));
    } else {
      _target = Offset(size.width * .75, size.height - 60);
    }
    final r = math.Random();
    _coins
      ..clear()
      ..addAll([
        for (var i = 0; i < 14; i++) (r.nextDouble() * math.pi * 2, 50 + r.nextDouble() * 70, 16 + r.nextDouble() * 6),
      ]);
    // Longest coin: 1000 + 13·45 ms plus a 13·35 ms stagger.
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000 + 13 * 45 + 13 * 35))
      ..addListener(() => setState(() {}))
      ..forward().whenComplete(() {
        if (mounted) setState(() => _coins.clear());
      });
    Future.delayed(const Duration(milliseconds: 1500 - 900), () {
      if (!mounted) return;
      HapticFeedback.selectionClick();
      BergenBottomNav.megBump.value++;
    });
    setState(() {});
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  static const Cubic _curve = Cubic(.45, 0, .2, 1);

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final elapsed = c == null ? 0.0 : c.value * c.duration!.inMilliseconds;
    return Stack(
      children: [
        widget.child,
        if (c != null && _coins.isNotEmpty)
          IgnorePointer(
            child: Stack(
              children: [
                for (var i = 0; i < _coins.length; i++) _coin(i, elapsed),
              ],
            ),
          ),
      ],
    );
  }

  Widget _coin(int i, double elapsed) {
    final (a, v, s) = _coins[i];
    final dur = 1000 + i * 45.0, delay = i * 35.0;
    final raw = ((elapsed - delay) / dur);
    if (raw <= 0 || raw >= 1) return const SizedBox.shrink();
    final p = _curve.transform(raw);
    final mx = math.cos(a) * v, my = math.sin(a) * v - 40;
    final end = _target - _start;
    double x, y, sc, rot, o;
    if (p < .35) {
      final k = p / .35;
      x = mx * k;
      y = my * k;
      sc = .3 + (1.1 - .3) * k;
      rot = 180 * k;
      o = k;
    } else {
      final k = (p - .35) / .65;
      x = mx + (end.dx - mx) * k;
      y = my + (end.dy - my) * k;
      sc = 1.1 + (.45 - 1.1) * k;
      rot = 180 + 360 * k;
      o = 1 - .1 * k;
    }
    final flip = math.cos(rot * math.pi / 180).abs();
    return Positioned(
      left: _start.dx + x - s / 2,
      top: _start.dy + y - s / 2,
      width: s,
      height: s,
      child: Opacity(
        opacity: o.clamp(0.0, 1.0),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(sc * math.max(flip, .08), sc, 1),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment(-.32, -.44),
                radius: .9,
                colors: [Color(0xFFFFF2C8), Color(0xFFF2C14E), Color(0xFFB77F1C)],
                stops: [0, .55, 1],
              ),
              boxShadow: [BoxShadow(color: Color.fromRGBO(242, 193, 78, .7), blurRadius: 8)],
            ),
          ),
        ),
      ),
    );
  }
}
