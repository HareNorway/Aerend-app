import 'dart:math' as math;
import 'dart:ui' as ui;

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
    // `filter: drop-shadow(0 8px 10px rgba(8,24,32,.45))`: a blurred copy,
    // drawn once in its own layer and moved with him.
    final img = RepaintBoundary(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: Offset(0, 8 * s),
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 5 * s, sigmaY: 5 * s),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(Color.fromRGBO(8, 24, 32, .45), BlendMode.srcIn),
                child: Image.asset(asset, width: 80 * s, height: 80 * s, fit: BoxFit.contain),
              ),
            ),
          ),
          Image.asset(asset, width: 80 * s, height: 80 * s, fit: BoxFit.contain),
        ],
      ),
    );
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
