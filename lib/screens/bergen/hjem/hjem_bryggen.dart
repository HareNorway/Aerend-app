import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../common/home/bergen/bergen_kit.dart' show BergenWeather;
import '../kit/br_pal.dart';
import '../sporing/sporing_gl.dart';

/// Bryggen, live: the prototype's own WebGL scene (`data-brgl`, `brGlInit` /
/// `brGlTegn`) as `shaders/hjem_bryggen.frag` — on Hjem (`hjem`, 390 × 127
/// design px, with the veil) and behind Fjordfiske / Poseautomaten (`fiske`,
/// 390 × 223, `uOff` −96, no veil) — drawn every 31 ms into at most 300 000
/// pixels at a device pixel ratio of at most 2 (the prototype's `_sgBud`).
///
/// Motion tiers (parity plan §3.1): `full` as the prototype; `lite` every
/// 62 ms at 55 % of the pixels; `still` shows [still] (the baked frame,
/// which is also there until the first frame and if the shader can't load).
/// «Roligere bevegelse» keeps the slow `rolig` clock.
class HjemBryggen extends StatelessWidget {
  const HjemBryggen({super.key, required this.kind, required this.still, this.onFrame, this.h = 127, this.hjem = true});

  final BergenWeather kind;
  final Widget still;

  /// The canvas height (127 on Hjem, 223 on Fjordfiske); `uOff` is 127 − h.
  final double h;

  /// `art === 'hjem'`: only Hjem's Bryggen gets the veil.
  final bool hjem;

  /// Each new frame (the water's mirror); owned by the scene.
  final void Function(ui.Image frame)? onFrame;

  @override
  Widget build(BuildContext context) {
    final p = BrPal.of(kind);
    return SpGl(
      key: Key(hjem ? 'hjem-bryggen-live' : 'fiske-bryggen-live'),
      asset: 'shaders/hjem_bryggen.frag',
      w: 390,
      h: h,
      t0: 12,
      fullMs: 31,
      liteMs: 62,
      stillTier: true,
      still: still,
      onFrame: onFrame,
      uniforms: (f, t, age, ok) {
        f(127 - h); // uOff
        f(p.night);
        f(p.sun);
        f(p.sunset);
        f(p.rain);
        f(p.snow);
        f(p.wet);
        f(hjem ? p.veil : 0); // uVeil: Hjem only
        f(p.cb);
        f(p.vis);
        for (final c in [p.skT, p.skM, p.skB]) {
          c.forEach(f);
        }
      },
    );
  }
}
