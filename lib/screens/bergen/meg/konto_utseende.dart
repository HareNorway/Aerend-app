import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;

import '../../../theme/lys/bergen_modus.dart';
import '../../../theme/lys/lys_palett.dart';
import '../../../theme/lys/modus_scope.dart';
import '../../../ui/kit/ae_haptic.dart';
import '../../common/auth/launch/lf_css.dart';
import '../aegil/aegil_bits.dart' show AeIkon;
import '../hjem/hjem_harness.dart';
import 'meg_torg.dart';

/// Lys plan Step 2: Konto › «Utseende» (design region `Utseende`,
/// `data-modusbryter="konto"`): two cards «Mørk · Fjord» / «Lys · Skydans»,
/// each with a mini preview; the chosen one gets `inset 0 0 0 2px #1E4F5C`, a
/// mint dot and the tick fading in; the footnote under them. A tap switches
/// the mode with the circle reveal from the tap.
class KontoUtseende extends StatelessWidget {
  const KontoUtseende({super.key});

  static const String fotnote = 'Hjem, sporing og Fjordfiske er fjordfarget i begge.';

  @override
  Widget build(BuildContext context) {
    // `modusMal`: the tick moves at the tap, before the reveal has finished.
    final lys = BergenModusScope.malOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _Valg(lys: false, valgt: !lys)),
              const SizedBox(width: 10),
              Expanded(child: _Valg(lys: true, valgt: lys)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(3, 0, 3, 10),
          child: Text(fotnote, style: inter(10.5, weight: FontWeight.w400, height: 1.4, color: const Color(0xFF6E6862))),
        ),
      ],
    );
  }
}

class _Valg extends StatefulWidget {
  const _Valg({required this.lys, required this.valgt});

  final bool lys;
  final bool valgt;

  @override
  State<_Valg> createState() => _ValgState();
}

class _ValgState extends State<_Valg> {
  bool _nede = false;

  /// The cards on screen now (the page can be built twice while it slides in).
  static final Map<bool, _ValgState> _paaSkjerm = {};

  @override
  void initState() {
    super.initState();
    _paaSkjerm[widget.lys] = this;
    // Debug harness (`modusBytt: "konto"`, `modusTreg`): 1.5 s after Konto opens, tap the card that isn't chosen.
    if (kDebugMode && HjemHarness.modusBytt == 'konto' && !widget.valgt) {
      HjemHarness.modusBytt = null;
      final maal = widget.lys;
      Future<void>.delayed(const Duration(milliseconds: 1500), () {
        final st = _paaSkjerm[maal];
        if (st == null || !st.mounted) return;
        final treg = HjemHarness.modusTreg;
        if (treg != null) timeDilation = treg;
        final ro = st.context.findRenderObject();
        final fra = ro is RenderBox && ro.hasSize ? ro.localToGlobal(ro.size.center(Offset.zero)) : null;
        BergenModus.i.sett(maal, fra: fra, kilde: ModusKilde.konto);
      });
    }
  }

  @override
  void dispose() {
    if (_paaSkjerm[widget.lys] == this) _paaSkjerm.remove(widget.lys);
    super.dispose();
  }

  void _trykk(TapUpDetails d) {
    setState(() => _nede = false);
    aeTrykkTikk(() => BergenModus.i.sett(widget.lys, fra: d.globalPosition, kilde: ModusKilde.konto))!();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.valgt;
    final blekk = context.aeM(MegTorgSkjerm.blekk, LysPalett.brod);
    return Semantics(
      button: true,
      selected: v,
      label: widget.lys ? 'Lys modus' : 'Mørk modus',
      child: GestureDetector(
        key: Key(widget.lys ? 'konto-modus-lys' : 'konto-modus-mork'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _nede = true),
        onTapCancel: () => setState(() => _nede = false),
        onTapUp: _trykk,
        child: AnimatedScale(
          // `style-active="transform:scale(.97)"`, `.18s cubic-bezier(.3,1.4,.5,1)`.
          scale: _nede ? .97 : 1,
          duration: const Duration(milliseconds: 180),
          curve: const Cubic(.3, 1.4, .5, 1),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: v ? 1 : 0),
            duration: const Duration(milliseconds: 250),
            curve: Curves.ease,
            builder: (context, a, child) => CssBox(
              radius: BorderRadius.circular(16),
              bg: const [CssSolid(Color.fromRGBO(30, 79, 92, .05))],
              // `inset 0 0 0 1px rgba(30,79,92,.14)` ↔ `inset 0 0 0 2px #1E4F5C`.
              shadows: [CssShadow.inset(0, 0, 0, 1 + a, Color.lerp(const Color.fromRGBO(30, 79, 92, .14), const Color(0xFF1E4F5C), a)!)],
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: child,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 66, child: widget.lys ? const _ForhandLys() : const _ForhandMork()),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 30),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(3, 9, 3, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.lys ? 'Lys' : 'Mørk', style: inter(12.5, weight: FontWeight.w800, color: blekk)),
                              Text(widget.lys ? 'Skydans' : 'Fjord', style: inter(10.5, weight: FontWeight.w400, color: const Color(0xFF6E6862))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        _Prikk(valgt: v),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The 22 px dot: mint with the tick when chosen, a 2 px ring when not
/// (`transition: background .25s, box-shadow .25s`; the tick `opacity .2s`).
class _Prikk extends StatelessWidget {
  const _Prikk({required this.valgt});
  final bool valgt;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(end: valgt ? 1 : 0),
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
        builder: (context, a, _) => CssBox(
          width: 22,
          height: 22,
          radius: BorderRadius.circular(11),
          bg: [CssSolid(Color.lerp(const Color(0x005CE0B8), const Color(0xFF5CE0B8), a)!)],
          shadows: [CssShadow.inset(0, 0, 0, 2, Color.fromRGBO(30, 79, 92, .3 * (1 - a)))],
          child: Center(
            child: Opacity(
              opacity: (a * 1.25).clamp(0.0, 1.0),
              child: const AeIkon('M5 12.5l4.5 4.5L19 7.5', size: 12, stroke: 3.4, color: Color(0xFF0F3A47)),
            ),
          ),
        ),
      );
}

/// «Mørk · Fjord»: the fjord gradient with a white title bar, a glass field
/// with the mint dot, and the orange key.
class _ForhandMork extends StatelessWidget {
  const _ForhandMork();

  @override
  Widget build(BuildContext context) => const CssBox(
        radius: BorderRadius.all(Radius.circular(11)),
        clip: true,
        bg: [
          CssRadial([Color.fromRGBO(255, 255, 255, .22), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .6], rx: .8, ry: .6, cx: .14, cy: 0),
          CssLinear(180, [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)], [0, .55, 1]),
        ],
        child: _Mini(
          tittel: Color(0xFFFFFFFF),
          felt: [CssSolid(Color.fromRGBO(255, 255, 255, .14))],
          feltSkygge: [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .22))],
          prikk: Color(0xFF5CE0B8),
        ),
      );
}

/// «Lys · Skydans»: the light gradient with the dark title, a white field
/// with the fjord dot, and the orange key.
class _ForhandLys extends StatelessWidget {
  const _ForhandLys();

  @override
  Widget build(BuildContext context) => const CssBox(
        radius: BorderRadius.all(Radius.circular(11)),
        clip: true,
        bg: [CssLinear(180, [Color(0xFFF7FBFD), Color(0xFFE7F5FA)])],
        shadows: [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(31, 82, 95, .14))],
        child: _Mini(
          tittel: Color(0xFF03313C),
          felt: [CssSolid(Color(0xFFFFFFFF))],
          feltSkygge: [CssShadow(0, 0, 0, 1, Color.fromRGBO(31, 82, 95, .1)), CssShadow(0, 4, 8, -5, Color.fromRGBO(6, 52, 62, .35))],
          prikk: Color(0xFF1E4F5C),
        ),
      );
}

class _Mini extends StatelessWidget {
  const _Mini({required this.tittel, required this.felt, required this.feltSkygge, required this.prikk});

  final Color tittel;
  final List<CssBg> felt;
  final List<CssShadow> feltSkygge;
  final Color prikk;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          return Stack(
            children: [
              Positioned(left: 9, top: 9, width: w * .38, height: 6, child: DecoratedBox(decoration: BoxDecoration(color: tittel, borderRadius: BorderRadius.circular(3)))),
              Positioned(left: 9, right: 9, top: 23, height: 20, child: CssBox(radius: const BorderRadius.all(Radius.circular(7)), bg: felt, shadows: feltSkygge)),
              Positioned(left: 15, top: 30, width: 6, height: 6, child: DecoratedBox(decoration: BoxDecoration(color: prikk, shape: BoxShape.circle))),
              Positioned(
                right: 9,
                bottom: 7,
                width: w * .34,
                height: 9,
                child: const CssBox(radius: BorderRadius.all(Radius.circular(5)), bg: [CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D)])]),
              ),
            ],
          );
        },
      );
}
