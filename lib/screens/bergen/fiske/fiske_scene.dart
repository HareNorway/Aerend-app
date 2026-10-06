import 'package:flutter/material.dart';

import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/sjo_water.dart';
import 'fiske_frame.dart';

/// The pier Ægil sits on (design: the three `div`s at `right:0;top:296/310/316`,
/// the three posts, the flipped reflection and the blurred shadow under Ægil).
class FiskePier extends StatelessWidget {
  const FiskePier({super.key});

  static const Color _wood1 = Color(0xFF6A5A44);
  static const Color _wood2 = Color(0xFF4A3C2A);
  static const Color _wood3 = Color(0xFF2C2114);

  @override
  Widget build(BuildContext context) {
    final f = FiskeFrame.of(context);
    final s = f.s;

    Widget planks({required LinearGradient base}) => CustomPaint(
      painter: _PlanksPainter(base: base, s: s),
    );

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Posts (z2, behind the deck).
            for (final right in [138.0, 70.0, 14.0])
              Positioned(
                right: f.x(right),
                top: f.y(290),
                width: f.x(5),
                height: f.x(40),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(f.x(2)),
                    ),
                    gradient: cssLinear(90, const [_wood2, _wood3]),
                  ),
                ),
              ),
            // Reflection (z2): `top:318;height:40;opacity:.35;scaleY(-1)`,
            // masked to fade away from the deck.
            Positioned(
              right: 0,
              top: f.y(318),
              width: f.x(150),
              height: f.x(40),
              child: Opacity(
                opacity: .35,
                child: Transform.flip(
                  flipY: true,
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (r) => const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.white, Color(0x00FFFFFF)],
                    ).createShader(r),
                    child: planks(
                      base: cssLinear(180, const [_wood2, _wood3]),
                    ),
                  ),
                ),
              ),
            ),
            // Shadow on the water (z3): `top:316;height:14`.
            Positioned(
              right: 0,
              top: f.y(316),
              width: f.x(150),
              height: f.x(14),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: cssLinear(180, [
                    rgba(8, 24, 32, .5),
                    rgba(8, 24, 32, 0),
                  ]),
                ),
              ),
            ),
            // Under-edge (z3): `top:310;height:6;radius 0 0 0 4`.
            Positioned(
              right: 0,
              top: f.y(310),
              width: f.x(150),
              height: f.x(6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(f.x(4)),
                  ),
                  gradient: cssLinear(180, [
                    const Color(0xFF1C1A17),
                    rgba(28, 26, 23, .6),
                  ]),
                ),
              ),
            ),
            // Deck (z3): `top:296;height:14;radius 7 0 0 3`, plank stripes
            // over the wood gradient, `inset 0 1px 0 rgba(255,255,255,.28)`
            // and `0 6px 10px -6px rgba(8,24,32,.6)`.
            Positioned(
              right: 0,
              top: f.y(296),
              width: f.x(150),
              height: f.x(14),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(f.x(7)),
                    bottomLeft: Radius.circular(f.x(3)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: rgba(8, 24, 32, .6),
                      offset: Offset(0, f.x(6)),
                      blurRadius: onbBlur(f.x(10)),
                      spreadRadius: f.x(-6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(f.x(7)),
                    bottomLeft: Radius.circular(f.x(3)),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      planks(
                        base: cssLinear(180, const [
                          _wood1,
                          _wood2,
                          _wood3,
                        ], const [0, .4, 1]),
                      ),
                      bergenInsetTop(radius: 0, height: 1 * s, alpha: .28),
                    ],
                  ),
                ),
              ),
            ),
            // Ægil's shadow (z3): `right:20;top:288;74×9;rgba(20,40,50,.4);blur(3px)`.
            Positioned(
              right: f.x(20),
              top: f.y(288),
              width: f.x(74),
              height: f.x(9),
              child: onbBlurred(
                3 * s,
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rgba(20, 40, 50, .4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `repeating-linear-gradient(90deg, transparent 0 18px, rgba(0,0,0,.22)
/// 18px 19px)` over a wood gradient.
class _PlanksPainter extends CustomPainter {
  const _PlanksPainter({required this.base, required this.s});

  final LinearGradient base;
  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = base.createShader(rect));
    final gap = Paint()..color = Colors.black.withValues(alpha: .22);
    for (var x = 18.0 * s; x < size.width; x += 19 * s) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1 * s, size.height), gap);
    }
  }

  @override
  bool shouldRepaint(_PlanksPainter old) => old.base != base || old.s != s;
}

/// The prototype's default Fjordfiske scene (`sjoGlPaa`, L7892–7926): the
/// sky (`vaerHimmel`, 230 px), Bryggen from the WebGL canvas
/// `data-brgl="fiske"` (390 × 223, baked per weather from the prototype —
/// `assets/images/utforsk/brygge_fiske_*.jpg`, its top extended 60 px for
/// the status bar), and «Sjø · fiske» from `top:223` down: the real water
/// shader (`canvas[data-sjogl="fiske"]` → [SjoWater], shading at most the
/// prototype's ~300 000 px a frame, `_sgBud`) mirroring that Bryggen, the
/// bottom dark, the top shade and the vignette.
class FiskeBakgrunn extends StatelessWidget {
  const FiskeBakgrunn({super.key, required this.look, this.ripples});

  final BergenWeatherLook look;
  final SjoRipples? ripples;

  /// `sjoM()`: sol → Dag, natt / solnedgang → Kveld, regn → the default
  /// `sjoModus` (Kveld).
  SjoPalette get _sea => look.isSun ? SjoPalette.dag : SjoPalette.kveld;

  /// `uRegn`: .5 for rain over a non-rain sea.
  double get _regn => look.isRain ? .5 : 0;

  String get _vaer => switch (look.kind) {
    BergenWeather.sol => 'sol',
    BergenWeather.solnedgang => 'solnedgang',
    BergenWeather.natt => 'natt',
    BergenWeather.regn => 'regn',
  };

  /// `brPal().skB` — the reflection's fog fill (as Hjem).
  Color get _fog => switch (look.kind) {
    BergenWeather.regn => const Color(0xFFC9D3D5),
    BergenWeather.sol => const Color(0xFFB8D1E0),
    BergenWeather.solnedgang => const Color(0xFFD9A176),
    BergenWeather.natt => const Color(0xFF1F4460),
  };

  @override
  Widget build(BuildContext context) {
    final f = FiskeFrame.of(context);
    final s = f.s;
    final vann = f.y(223);
    final brH = 283 * f.width / 390;
    final asset = 'assets/images/utforsk/brygge_fiske_$_vaer.jpg';
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(left: 0, right: 0, top: 0, height: f.y(230), child: DecoratedBox(decoration: BoxDecoration(gradient: look.sky))),
            Positioned(
              left: 0,
              width: f.width,
              top: vann - brH,
              height: brH,
              child: Image.asset(asset, fit: BoxFit.fill, gaplessPlayback: true),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: vann,
              bottom: 0,
              child: ClipRect(
                child: Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: look.isSun ? const Color(0xFF9FC3CC) : const Color(0xFF3D6B7A))),
                    Positioned.fill(
                      child: SjoWater(
                        palette: _sea,
                        regn: _regn,
                        reflection: asset,
                        reflectionHeight: 283,
                        fogColor: _fog,
                        ripples: ripples,
                        maxPixels: 300000 * s * s,
                      ),
                    ),
                    // `radial-gradient(60% 70% at 50% 100%, rgba(3,14,20,.42) → 0 75%)`
                    // on a box −20 % / −20 % / −10 %, 55 % high.
                    Positioned(
                      left: -.2 * f.width,
                      right: -.2 * f.width,
                      bottom: -.1 * (f.height - vann),
                      height: .55 * (f.height - vann),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(0, 1),
                            radius: .7,
                            colors: [Color.fromRGBO(3, 14, 20, .42), Color.fromRGBO(3, 14, 20, 0)],
                            stops: [0, .75],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 28 * s,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color.fromRGBO(8, 24, 32, .3), Color.fromRGBO(8, 24, 32, 0)],
                          ),
                        ),
                      ),
                    ),
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(0, -.4),
                            radius: 1.1,
                            colors: [Color.fromRGBO(0, 0, 0, 0), Color.fromRGBO(0, 0, 0, 0), Color.fromRGBO(3, 14, 20, .5)],
                            stops: [0, .5, 1],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
