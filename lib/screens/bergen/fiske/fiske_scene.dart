import 'package:flutter/material.dart';

import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../../common/home/bergen/bergen_painters.dart';
import 'fiske_frame.dart';

/// The still parts of the harbour behind the game (design `Fjordfiske` root,
/// `Bryggen · fiske`, and the pier on the right), all positioned in the
/// design's 390-frame through [FiskeFrame].
///
/// Everything here is static; nothing needs a ticker, so reduced motion has
/// nothing to gate.
class FiskeSky extends StatelessWidget {
  const FiskeSky({super.key, required this.look});

  final BergenWeatherLook look;

  @override
  Widget build(BuildContext context) {
    final f = FiskeFrame.of(context);
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      // `height:230px` from the design's y=0; the sky continues up under the
      // status bar.
      height: f.y(230),
      child: DecoratedBox(decoration: BoxDecoration(gradient: look.sky)),
    );
  }
}

/// `<svg width=390 height=140 … top:90px>` holding `k-scene2` squashed to
/// 390×190 (`translate(0 4) scale(1 .6333)`) and clipped at 140, plus the lit
/// windows (`k-scene2-lys`: a blurred copy at .55 under a sharp one, at the
/// weather's `visGlod`).
class FiskeMountains extends StatelessWidget {
  const FiskeMountains({super.key, required this.look});

  final BergenWeatherLook look;

  @override
  Widget build(BuildContext context) {
    final f = FiskeFrame.of(context);
    return Positioned(
      left: 0,
      top: f.y(90),
      width: f.width,
      height: f.x(140),
      child: IgnorePointer(
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minHeight: 0,
            maxHeight: double.infinity,
            child: Padding(
              padding: EdgeInsets.only(top: f.x(4)),
              child: SizedBox(
                width: f.width,
                height: f.x(190),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    bergenSvg('scene_mountains', fit: BoxFit.fill),
                    if (look.houseDim > .2)
                      ColoredBox(
                        color: Colors.black.withValues(
                          alpha: look.houseDim * .8,
                        ),
                      ),
                    if (look.glow > 0)
                      Opacity(
                        opacity: look.glow,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Opacity(
                              opacity: .55,
                              child: onbBlurred(
                                4,
                                bergenSvg('scene_lights', fit: BoxFit.fill),
                              ),
                            ),
                            bergenSvg('scene_lights', fit: BoxFit.fill),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `top:90px;height:150px;background:{{ vaerDis }}`.
class FiskeMist extends StatelessWidget {
  const FiskeMist({super.key, required this.look});

  final BergenWeatherLook look;

  @override
  Widget build(BuildContext context) {
    final f = FiskeFrame.of(context);
    return Positioned(
      left: 0,
      right: 0,
      top: f.y(90),
      height: f.x(150),
      child: IgnorePointer(
        child: DecoratedBox(decoration: BoxDecoration(gradient: look.mist)),
      ),
    );
  }
}

/// `Bryggen · fiske`: the eleven houses and the quay, the design's `bryggen`
/// template in a 390×76 box at `top:156px` — the same rows the Hjem hero
/// paints, so [BergenHousesPainter] is reused unchanged (no weather filter on
/// this block in the design, hence `dim: 0`).
class FiskeBryggen extends StatelessWidget {
  const FiskeBryggen({super.key});

  @override
  Widget build(BuildContext context) {
    final f = FiskeFrame.of(context);
    return Positioned(
      left: 0,
      top: f.y(156),
      width: f.width,
      height: f.x(76),
      child: const IgnorePointer(
        child: CustomPaint(painter: BergenHousesPainter(dim: 0)),
      ),
    );
  }
}

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
