import 'package:flutter/material.dart';

import '../../common/home/bergen/bergen_kit.dart' show BergenWeather;
import '../sporing/sporing_gl.dart';

/// The scenes the prototype runs through its scene post pass
/// (`canvas[data-scgl]`): the Torg header (Favoritter, Konto), Flesland's
/// rock and the «BERGEN?» sign (Søk).
enum SceneKind { torg, berg, skilt }

/// `scProfil()`: how much sky, fog bands, planks, stone, water glints and
/// sheen a scene gets.
class _Prof {
  const _Prof({this.sky = 0, this.hz = -1, this.take = const [0, 0, 0], this.plank = 0, this.rock = 0, this.vann = 0, this.sheen = 0});
  final double sky, hz, plank, rock, vann, sheen;
  final List<double> take;
}

/// `scPal(sjoM())`: the light for Dag (sun) or Kveld (the other looks).
class _Pal {
  const _Pal(this.lit, this.shade, this.fog, {required this.glow, required this.sol, required this.sky});
  final List<double> lit, shade, fog;
  final double glow, sol, sky;
}

/// One scene through the prototype's own post pass (`scGlInit` /
/// `scGlTegn`, `shaders/scene_gl.frag`): grain, planks, stone relief and
/// drips, forest, clouds and fog bands, water glints, the flickering window
/// glow, the sign's sheen and the rain, over the scene the prototype bakes
/// from its SVG (`assets/images/scgl/<kind>.png`, with the mip levels its
/// biased reads use). Drawn every 30 ms within 300 000 px at a pixel ratio of
/// at most 2, as `scGlTegn` does; the alpha is kept, so the screen's own
/// backdrop shows where the SVG has none.
///
/// Motion tiers (parity plan §3.1): `full` as the prototype; `lite` every
/// 60 ms at 55 % of the pixels; `still` shows [still] (the baked frame, also
/// there until the textures and the shader are ready). «Roligere bevegelse»
/// keeps the slow `rolig` clock.
class SceneGl extends StatelessWidget {
  const SceneGl({super.key, required this.kind, required this.weather, required this.still});

  final SceneKind kind;
  final BergenWeather weather;
  final Widget still;

  /// The SVG's size (design px) and scBake's texture: pot(w·2.2) × pot(h·2.2).
  static const Map<SceneKind, (double, double, int, int)> _size = {
    SceneKind.torg: (390, 104, 1024, 256),
    SceneKind.berg: (410, 300, 1024, 1024),
    SceneKind.skilt: (308, 83, 1024, 256),
  };

  static const Map<SceneKind, _Prof> _prof = {
    SceneKind.torg: _Prof(sky: .85, hz: .3, take: [.08, .32, .4], plank: .4, vann: .3),
    SceneKind.berg: _Prof(rock: 1),
    SceneKind.skilt: _Prof(sheen: 1),
  };

  static const _Pal _dag = _Pal([1, 1, 1], [.64, .71, .75], [.88, .92, .93], glow: .3, sol: .16, sky: 1);
  static const _Pal _kveld = _Pal([.91, .86, .82], [.44, .52, .57], [.74, .79, .81], glow: 1, sol: .06, sky: .9);

  @override
  Widget build(BuildContext context) {
    final (w, h, tw, th) = _size[kind]!;
    final f0 = _prof[kind]!;
    // sjoM(): sol → Dag; natt / solnedgang / regn → the default sjoModus Kveld.
    final p = weather == BergenWeather.sol ? _dag : _kveld;
    final himmel = f0.sky > 0;
    final base = 'assets/images/scgl/${kind.name}';
    return SpGl(
      key: Key('scene-gl-${kind.name}'),
      asset: 'shaders/scene_gl.frag',
      w: w,
      h: h,
      t0: 12,
      fullMs: 30,
      liteMs: 60,
      stillTier: true,
      waitTex: true,
      still: still,
      tex: [
        SpGlTex.asset('$base.png', tw, th),
        SpGlTex.asset('${base}_1.png', tw ~/ 2, th ~/ 2),
        SpGlTex.asset('${base}_2.png', tw ~/ 4, th ~/ 4),
        SpGlTex.asset('${base}_3.png', tw ~/ 8, th ~/ 8),
      ],
      uniforms: (f, t, age, ok) {
        f(f0.sky * p.sky);
        f(f0.hz > 0 ? f0.hz * h : -1);
        f(f0.plank);
        f(f0.rock);
        f(p.glow);
        f(himmel ? (weather == BergenWeather.regn ? .45 : 0) : 0); // uRegn (sjoM is never Regn here)
        f(p.sol * (himmel ? 1 : 0));
        f(f0.vann > 0 ? f0.vann * h : -1);
        f(f0.sheen);
        f(f0.take[0] * h);
        f(f0.take[1] * h);
        f(f0.take[2]);
        for (final c in [p.lit, p.shade, p.fog]) {
          c.forEach(f);
        }
        f(tw.toDouble());
        f(th.toDouble());
      },
    );
  }
}
