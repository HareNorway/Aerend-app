import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../common/home/bergen/bergen_kit.dart' show BergenWeather;
import '../kit/br_pal.dart';
import '../sporing/sporing_gl.dart';
import 'hjem_hero.dart' show HjemVaer;

/// Bryggen on Hjem, live: the prototype's own WebGL scene (`data-brgl="hjem"`,
/// `brGlInit` / `brGlTegn`) as `shaders/hjem_bryggen.frag`, 390 × 127 design
/// px, drawn every 31 ms into at most 300 000 pixels at a device pixel ratio
/// of at most 2 (the prototype's `_sgBud`).
///
/// Motion tiers (parity plan §3.1): `full` as the prototype; `lite` every
/// 62 ms at 55 % of the pixels; `still` shows [still] (the baked frame,
/// which is also there until the first frame and if the shader can't load).
/// «Roligere bevegelse» keeps the slow `rolig` clock.
class HjemBryggen extends StatelessWidget {
  const HjemBryggen({super.key, required this.vaer, required this.still, this.onFrame});

  final HjemVaer vaer;
  final Widget still;

  /// Each new frame (the water's mirror); owned by the scene.
  final void Function(ui.Image frame)? onFrame;

  @override
  Widget build(BuildContext context) {
    final p = BrPal.of(BergenWeather.values.byName(vaer.name));
    return SpGl(
      key: const Key('hjem-bryggen-live'),
      asset: 'shaders/hjem_bryggen.frag',
      w: 390,
      h: 127,
      t0: 12,
      fullMs: 31,
      liteMs: 62,
      stillTier: true,
      still: still,
      onFrame: onFrame,
      uniforms: (f, t, age, ok) {
        f(0); // uOff: 127 - h
        f(p.night);
        f(p.sun);
        f(p.sunset);
        f(p.rain);
        f(p.snow);
        f(p.wet);
        f(p.veil); // uVeil: Hjem only
        f(p.cb);
        f(p.vis);
        for (final c in [p.skT, p.skM, p.skB]) {
          c.forEach(f);
        }
      },
    );
  }
}
