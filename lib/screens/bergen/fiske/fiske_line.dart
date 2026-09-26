import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'fiske_frame.dart';
import 'fiske_game.dart';
import 'fiske_motion.dart';

/// Ægil, the line, the float and the water effects (design ≈L6515–6531).
/// Everything is positioned in the 390-frame; every keyframe below is the
/// prototype's, with its duration, delay and easing.

/// `assets/images/dashboard/*.png` — the prototype's `assets/aegil-s/*`.
abstract final class FiskeAegilPose {
  static const String rear = 'assets/images/dashboard/rear.png';
  static const String shock = 'assets/images/dashboard/shock.png';
  static const String find = 'assets/images/dashboard/find.png';
  static const String sorry = 'assets/images/dashboard/sorry.png';
  static const String noresto = 'assets/images/dashboard/noresto.png';
}

/// Ægil on the pier: `right:22px;top:222px;80×80;transform-origin:50% 100%`.
/// `rear` bobs (`aegBob 3.6s ease-in-out infinite`), `shock` shakes
/// (`rist .5s ease-in-out infinite`), `find` pops in
/// (`popp .6s cubic-bezier(.34,1.56,.64,1) both`), `sorry` bobs.
/// The design's `drop-shadow(0 8px 10px rgba(8,24,32,.45))` is left off
/// the animated image (the prototype's note: it stutters); the blurred
/// shadow ellipse on the pier stands in.
class FiskeAegil extends StatelessWidget {
  const FiskeAegil({super.key, required this.phase});

  final FiskePhase phase;

  @override
  Widget build(BuildContext context) {
    final f = FiskeFrame.of(context);
    final s = f.s;
    final (asset, key) = switch (phase) {
      FiskePhase.klar || FiskePhase.venter => (FiskeAegilPose.rear, 'rear'),
      FiskePhase.napp => (FiskeAegilPose.shock, 'shock'),
      FiskePhase.fangst => (FiskeAegilPose.find, 'find'),
      FiskePhase.mistet => (FiskeAegilPose.sorry, 'sorry'),
    };
    final img = Image.asset(asset, width: 80 * s, height: 80 * s, fit: BoxFit.contain);
    Widget body;
    switch (phase) {
      case FiskePhase.napp:
        body = FiskeLoop(
          key: Key('a1_fiske_aegil_$key'),
          durationMs: 500,
          child: img,
          builder: (context, p, child) {
            final q = p ?? 0;
            const st = [0.0, .2, .4, .6, .8, 1.0];
            final tx = kf(q, st, const [0, -5, 5, -3, 3, 0], Curves.easeInOut);
            final rot = kf(q, st, const [0, -2, 2, 0, 0, 0], Curves.easeInOut);
            return Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..translate(tx * s)
                ..rotateZ(rot * math.pi / 180),
              child: child,
            );
          },
        );
      case FiskePhase.fangst:
        body = FiskeOnce(
          key: Key('a1_fiske_aegil_$key'),
          durationMs: 600,
          child: img,
          builder: (context, p, child) => Transform.scale(
            alignment: Alignment.bottomCenter,
            scale: kf(p, const [0, .35, .7, 1], const [1, 1.16, .96, 1], kPopp),
            child: child,
          ),
        );
      default:
        body = FiskeLoop(
          key: Key('a1_fiske_aegil_$key'),
          durationMs: 3600,
          child: img,
          builder: (context, p, child) => Transform.translate(
            offset: Offset(
              0,
              kf(p ?? 0, const [0, .5, 1], const [0, -2.5, 0], Curves.easeInOut) * s,
            ),
            child: child,
          ),
        );
    }
    return Positioned(
      right: f.x(22),
      top: f.y(222),
      width: 80 * s,
      height: 80 * s,
      child: IgnorePointer(child: body),
    );
  }
}

/// The line (`<svg 390×844 z5>`): out — `M296 250 Q250 290 152 420`, white
/// .8, 1.3 px, drawn on by `snoreKast .7s ease-out` (dasharray 400, offset
/// 400 → 0); in — `M296 250 Q300 268 298 286` with the hook at (298, 289),
/// r 3, `#F26D3D` with a 1 px white stroke.
class FiskeLine extends StatelessWidget {
  const FiskeLine({super.key, required this.out, required this.castSeq});

  final bool out;

  /// Bumps on every cast so the draw-on replays.
  final int castSeq;

  @override
  Widget build(BuildContext context) {
    final f = FiskeFrame.of(context);
    if (!out) {
      return Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(painter: _LinePainter(f: f, visible: null)),
        ),
      );
    }
    return Positioned.fill(
      child: IgnorePointer(
        child: FiskeOnce(
          key: ValueKey('a1_fiske_snore_$castSeq'),
          durationMs: 700,
          builder: (context, p, _) => CustomPaint(
            painter: _LinePainter(
              f: f,
              visible: 400 * Curves.easeOut.transform(p),
            ),
          ),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({required this.f, required this.visible});

  final FiskeFrame f;

  /// Design px of the out-line to show; null draws the in-line + hook.
  final double? visible;

  @override
  void paint(Canvas canvas, Size size) {
    final s = f.s;
    canvas.save();
    canvas.translate(0, f.safeTop);
    canvas.scale(s);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = Colors.white.withValues(alpha: .8);
    if (visible == null) {
      canvas.drawPath(
        Path()
          ..moveTo(296, 250)
          ..quadraticBezierTo(300, 268, 298, 286),
        stroke,
      );
      canvas.drawCircle(const Offset(298, 289), 3, Paint()..color = const Color(0xFFF26D3D));
      canvas.drawCircle(
        const Offset(298, 289),
        3,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white,
      );
    } else {
      final path = Path()
        ..moveTo(296, 250)
        ..quadraticBezierTo(250, 290, 152, 420);
      for (final m in path.computeMetrics()) {
        canvas.drawPath(m.extractPath(0, math.min(m.length, visible!)), stroke);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.visible != visible || old.f.s != f.s;
}

/// The two ripples under the float: `left:112;top:424;80×26; border 1.5px
/// rgba(255,255,255,.55); rippel 2.6s ease-out infinite` (scale .4 → 1.6,
/// opacity .8 → 0), the second delayed 1.3 s.
class FiskeRipples extends StatelessWidget {
  const FiskeRipples({super.key});

  @override
  Widget build(BuildContext context) {
    final f = FiskeFrame.of(context);
    Widget ring(double delay) => Positioned(
      left: f.x(112),
      top: f.y(424),
      width: f.x(80),
      height: f.x(26),
      child: FiskeLoop(
        durationMs: 2600,
        delayMs: delay,
        builder: (context, p, _) {
          final q = p == null ? null : Curves.easeOut.transform(p);
          return Opacity(
            opacity: q == null ? 1 : .8 * (1 - q),
            child: Transform.scale(
              scale: q == null ? 1 : .4 + 1.2 * q,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: rgba(255, 255, 255, .55),
                    width: 1.5 * f.s,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    return Stack(children: [ring(0), ring(1300)]);
  }
}

/// The float (`dupp`): `left:143;top:412;18×26`, a 2×10 white stick at
/// (8, −8) and the body — `border-radius:50%/40% 40% 60% 60%`,
/// `linear-gradient(180deg,#F9A273 0%,#F26D3D 48%,#FFFFFF 50%,#EAF2F4 100%)`,
/// `inset 0 1px 0 rgba(255,255,255,.7), 0 4px 6px -3px rgba(8,24,32,.6)`.
/// Idle: `duppFlyt 2.8s ease-in-out infinite`; bite: `duppNapp .45s`.
class FiskeDupp extends StatelessWidget {
  const FiskeDupp({super.key, required this.bite});

  final bool bite;

  @override
  Widget build(BuildContext context) {
    final f = FiskeFrame.of(context);
    final s = f.s;
    final body = SizedBox(
      width: 18 * s,
      height: 26 * s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 8 * s,
            top: -8 * s,
            width: 2 * s,
            height: 10 * s,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(1 * s),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.elliptical(9 * s, 10.4 * s),
                  topRight: Radius.elliptical(9 * s, 10.4 * s),
                  bottomLeft: Radius.elliptical(9 * s, 15.6 * s),
                  bottomRight: Radius.elliptical(9 * s, 15.6 * s),
                ),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF9A273),
                    Color(0xFFF26D3D),
                    Color(0xFFFFFFFF),
                    Color(0xFFEAF2F4),
                  ],
                  stops: [0, .48, .5, 1],
                ),
                boxShadow: [
                  BoxShadow(
                    color: rgba(8, 24, 32, .6),
                    offset: Offset(0, 4 * s),
                    blurRadius: 6 * s,
                    spreadRadius: -3 * s,
                  ),
                ],
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 1 * s,
                  margin: EdgeInsets.symmetric(horizontal: 4 * s),
                  color: rgba(255, 255, 255, .7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return Positioned(
      left: f.x(143),
      top: f.y(412),
      width: 18 * s,
      height: 26 * s,
      child: bite
          ? FiskeLoop(
              key: const Key('a1_fiske_dupp_napp'),
              durationMs: 450,
              child: body,
              builder: (context, p, child) {
                final q = p ?? 0;
                const st = [0.0, .3, .6, 1.0];
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translate(0.0, kf(q, st, const [0, 9, 3, 0], Curves.easeInOut) * s)
                    ..rotateZ(kf(q, st, const [0, -8, 6, 0], Curves.easeInOut) * math.pi / 180),
                  child: child,
                );
              },
            )
          : FiskeLoop(
              key: const Key('a1_fiske_dupp_flyt'),
              durationMs: 2800,
              child: body,
              builder: (context, p, child) {
                final q = p ?? 0;
                const st = [0.0, .5, 1.0];
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translate(0.0, kf(q, st, const [0, -3, 0], Curves.easeInOut) * s)
                    ..rotateZ(kf(q, st, const [-3, 3, -3], Curves.easeInOut) * math.pi / 180),
                  child: child,
                );
              },
            ),
    );
  }
}

/// The bite rings: `left:96;top:420;112×34`, `2.5px #F26D3D` and, .45 s
/// behind, `2.5px #FFFFFF`; `nappRing .9s ease-out infinite` (scale .8 →
/// 2.2, opacity .9 → 0).
class FiskeNappRings extends StatelessWidget {
  const FiskeNappRings({super.key});

  @override
  Widget build(BuildContext context) {
    final f = FiskeFrame.of(context);
    Widget ring(Color color, double delay) => Positioned(
      left: f.x(96),
      top: f.y(420),
      width: f.x(112),
      height: f.x(34),
      child: FiskeLoop(
        durationMs: 900,
        delayMs: delay,
        builder: (context, p, _) {
          final q = p == null ? null : Curves.easeOut.transform(p);
          return Opacity(
            opacity: q == null ? 1 : .9 * (1 - q),
            child: Transform.scale(
              scale: q == null ? 1 : .8 + 1.4 * q,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2.5 * f.s),
                ),
              ),
            ),
          );
        },
      ),
    );
    return Stack(
      key: const Key('a1_fiske_napp_ringer'),
      children: [ring(const Color(0xFFF26D3D), 0), ring(Colors.white, 450)],
    );
  }
}

/// The catch splash: `sprut .8s ease-out both` (a 120 px radial white .85 →
/// 0 at 70 %, at `left:50%;top:560`, rising 70 px while scaling .4 → 1.5)
/// and three `#EAF7FA` drops falling 90 px (`dropp`, ease-in: .9s +.1s at
/// (120, 540) 8 px; .8s +.2s at (250, 530) 6 px; 1s at (190, 520) 7 px).
class FiskeSprut extends StatelessWidget {
  const FiskeSprut({super.key});

  @override
  Widget build(BuildContext context) {
    final f = FiskeFrame.of(context);
    final s = f.s;
    Widget drop(double left, double top, double size, double dur, double delay) =>
        Positioned(
          left: f.x(left),
          top: f.y(top),
          width: size * s,
          height: size * s,
          child: FiskeOnce(
            durationMs: dur,
            delayMs: delay,
            builder: (context, p, _) {
              final q = Curves.easeIn.transform(p);
              return Opacity(
                opacity: .95 * (1 - q),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translate(0.0, 90 * q * s)
                    ..scale(1 - .5 * q),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFEAF7FA),
                    ),
                  ),
                ),
              );
            },
          ),
        );
    return Stack(
      key: const Key('a1_fiske_sprut'),
      children: [
        Positioned(
          left: f.width / 2 - 60 * s,
          top: f.y(560),
          width: 120 * s,
          height: 120 * s,
          child: FiskeOnce(
            durationMs: 800,
            builder: (context, p, _) {
              final q = Curves.easeOut.transform(p);
              return Opacity(
                opacity: .95 * (1 - q),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translate(0.0, -70 * q * s)
                    ..scale(.4 + 1.1 * q),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [rgba(255, 255, 255, .85), rgba(255, 255, 255, 0)],
                        stops: const [0, .7],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        drop(120, 540, 8, 900, 100),
        drop(250, 530, 6, 800, 200),
        drop(190, 520, 7, 1000, 0),
      ],
    );
  }
}
