import 'package:flutter/material.dart';

import '../../../theme/bergen_tokens.dart';
import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart';

// ── The orange segmented toggle (Butikker / Produkter) ─────────────────────
// One thumb slides between the segments like Kurv's Levering / Henting
// (`KurvModus`: `translateX .5s cubic-bezier(.3,1.25,.4,1)`), instead of each
// segment fading its own fill in and out. The thumb is the design's orange
// pill (`180deg #F9A273 → #F26D3D 56% → #DD5A25`, `0 4px 10px -4px` glow,
// `inset 0 1.5px 0 white .4`) on the dark track (`rgba(0,0,0,.28)`, border
// white .12, padding 3).

/// One segment: [bygg] draws its label for the selection progress `t`
/// (0 = off, 1 = on), so colours cross-fade while the thumb travels.
class BergenFane {
  const BergenFane({required this.key, required this.bygg});
  final Key key;
  final Widget Function(BuildContext context, double t) bygg;
}

class BergenFaner extends StatelessWidget {
  const BergenFaner({super.key, required this.faner, required this.valgt, required this.onValg, this.scale = 1});

  final List<BergenFane> faner;
  final int valgt;
  final ValueChanged<int> onValg;

  /// The screen's design scale (`context.bs` where the screen uses it).
  final double scale;

  /// The off → on label colour.
  static Color farge(double t, {double av = .6}) => Color.lerp(Color.fromRGBO(255, 255, 255, av), Colors.white, t)!;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final n = faner.length;
    final gap = 3 * s;
    final glide = BergenTokens.motion(context, const Duration(milliseconds: 500));
    final fade = BergenTokens.motion(context, const Duration(milliseconds: 250));
    return Container(
      padding: EdgeInsets.all(3 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color.fromRGBO(0, 0, 0, .28),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, .12)),
      ),
      foregroundDecoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(999)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.fromRGBO(0, 0, 0, .18), Color.fromRGBO(0, 0, 0, 0)],
          stops: [0, .14],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = (box.maxWidth - gap * (n - 1)) / n;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: glide,
                curve: const Cubic(.3, 1.25, .4, 1),
                left: valgt * (w + gap),
                top: 0,
                bottom: 0,
                width: w,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)],
                      stops: [0, .56, 1],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(242, 109, 61, .9),
                        offset: Offset(0, 4 * s),
                        blurRadius: onbBlur(10 * s),
                        spreadRadius: -4 * s,
                      ),
                    ],
                  ),
                  child: Stack(children: [bergenInsetTop(radius: 999, height: 1.5 * s, alpha: .4)]),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < n; i++) ...[
                    if (i > 0) SizedBox(width: gap),
                    Expanded(
                      child: OnbPressable(
                        key: faner[i].key,
                        onTap: () {
                          if (i != valgt) onValg(i);
                        },
                        pressDy: 0,
                        pressScale: .97,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10 * s),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(end: i == valgt ? 1 : 0),
                            duration: fade,
                            curve: Curves.ease,
                            builder: (context, t, _) => faner[i].bygg(context, t),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
