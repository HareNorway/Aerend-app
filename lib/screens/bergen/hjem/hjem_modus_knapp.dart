import 'package:flutter/material.dart';

import '../../../theme/lys/bergen_modus.dart';
import '../../../theme/lys/hjem_modus_show.dart';
import '../../../ui/kit/ae_haptic.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_widgets.dart' show LfPress;
import '../aegil/aegil_bits.dart' show AeIkon;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'hjem_harness.dart';

/// Lys plan Step 2: the round 44 px moon/sun button in Hjem's top bar,
/// between the address pill and the bell (design `data-modusbryter="hjem"`):
/// the bell's fjord ball (`linear-gradient(160deg,#2A6272,#1E4F5C 60%,#173E48)`),
/// press scale .93; the moon and the sun swap in .55 s
/// (`cubic-bezier(.34,1.4,.5,1)`, scale .3 + rotate ±90°, opacity .28 s).
/// Hjem is fjord in both modes, so the button reads the switch itself.
class HjemModusKnapp extends StatefulWidget {
  const HjemModusKnapp({super.key});

  static const String maane = 'M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z';
  static const String sol =
      'M16 12a4 4 0 1 1-8 0 4 4 0 0 1 8 0zM12 2.5v2.5M12 19v2.5M2.5 12H5M19 12h2.5M5.3 5.3l1.8 1.8M16.9 16.9l1.8 1.8M5.3 18.7l1.8-1.8M16.9 7.1l1.8-1.8';

  @override
  State<HjemModusKnapp> createState() => _HjemModusKnappState();
}

class _HjemModusKnappState extends State<HjemModusKnapp> with SingleTickerProviderStateMixin {
  // The show's first beat: 1 → .8 (25 %) → 1.16 (60 %) → 1, 600 ms ease-out.
  late final AnimationController _sprett = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

  @override
  void initState() {
    super.initState();
    ModusAnkre.bryterSprett.addListener(_spill);
    // Debug harness (`modusBytt: "hjem"`, `modusTreg`): play the switch 1.5 s after the harness file is read.
    if (kDebugMode) HjemHarness.modusByttPuls.addListener(_harness);
  }

  @override
  void dispose() {
    ModusAnkre.bryterSprett.removeListener(_spill);
    HjemHarness.modusByttPuls.removeListener(_harness);
    _sprett.dispose();
    super.dispose();
  }

  void _spill() => _sprett.forward(from: 0);

  void _harness() {
    if (HjemHarness.modusBytt != 'hjem') return;
    HjemHarness.modusBytt = null;
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      final treg = HjemHarness.modusTreg;
      if (treg != null) timeDilation = treg;
      _trykk();
    });
  }

  void _trykk() {
    final ro = ModusAnkre.bryter.currentContext?.findRenderObject();
    Offset? fra;
    if (ro is RenderBox && ro.hasSize) fra = ro.localToGlobal(ro.size.center(Offset.zero));
    BergenModus.i.bytt(fra: fra, kilde: ModusKilde.hjem);
  }

  double _skala(double t) {
    final e = Curves.easeOut.transform(t);
    if (e < .25) return 1 - .2 * (e / .25);
    if (e < .6) return .8 + .36 * ((e - .25) / .35);
    return 1.16 - .16 * ((e - .6) / .4);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BergenModus.i,
      builder: (context, _) {
        final lys = BergenModus.i.modusMal;
        return Semantics(
          button: true,
          label: lys ? 'Bytt til mørk modus' : 'Bytt til lys modus',
          child: AnimatedBuilder(
            animation: _sprett,
            builder: (context, child) => Transform.scale(scale: _sprett.isAnimating ? _skala(_sprett.value) : 1, child: child),
            child: LfPress(
              scale: .93,
              onTap: aeTrykkTikk(_trykk),
              child: SizedBox(
                key: ModusAnkre.bryter,
                width: 44,
                height: 44,
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: CssBox(
                        radius: BorderRadius.all(Radius.circular(999)),
                        bg: [CssLinear(160, [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)], [0, .6, 1])],
                        shadows: [
                          CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
                          CssShadow(0, 2, 0, 0, Color.fromRGBO(15, 45, 55, .9)),
                          CssShadow(0, 10, 16, -9, Color.fromRGBO(15, 45, 55, .7)),
                        ],
                      ),
                    ),
                    _Ikon(d: HjemModusKnapp.maane, synlig: !lys, vinkel: -90),
                    _Ikon(d: HjemModusKnapp.sol, synlig: lys, vinkel: 90),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Ikon extends StatelessWidget {
  const _Ikon({required this.d, required this.synlig, required this.vinkel});

  final String d;
  final bool synlig;

  /// The hidden icon's turn (moon −90°, sun +90°).
  final double vinkel;

  @override
  Widget build(BuildContext context) {
    final rolig = MediaQuery.maybeDisableAnimationsOf(context) == true;
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: synlig ? 1 : 0),
        duration: rolig ? Duration.zero : const Duration(milliseconds: 550),
        curve: const Cubic(.34, 1.4, .5, 1),
        builder: (context, t, child) => Transform.rotate(
          angle: (1 - t) * vinkel * 3.141592653589793 / 180,
          child: Transform.scale(scale: .3 + .7 * t, child: child),
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: synlig ? 1 : 0),
          duration: rolig ? Duration.zero : const Duration(milliseconds: 280),
          curve: Curves.ease,
          builder: (context, o, child) => Opacity(opacity: o.clamp(0.0, 1.0), child: child),
          child: AeIkon(d, size: 21, stroke: 2, color: Colors.white),
        ),
      ),
    );
  }
}
