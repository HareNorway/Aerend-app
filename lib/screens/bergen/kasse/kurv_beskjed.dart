import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../common/auth/onboarding_kit.dart' show onbBlur, OnbPressable;
import '../../common/home/bergen/bergen_kit.dart';
import '../../../theme/bergen_tokens.dart';
import '../kit/bergen_css.dart';
import 'kasse_copy.dart';
import 'kurv_parts.dart';
import 'package:aerend_customer/screens/bergen/kit/css_decoration.dart';
import '../../../theme/lys/lys_palett.dart';
import '../../../theme/lys/modus_scope.dart';

/// Kassen's note pieces (Onboarding plan Step 7 #18–#19; Design 21 Nov plan Step 2 moved the cards into the
/// collapsible rows of `kurv_rader.dart`): the pure rules, the dark chips with a mint check, the Hentetid segment
/// with the sliding thumb and the tips card's «Eget beløp» row.

/// The pure rules, so they can be tested.
abstract final class KasseValg {
  /// `tipsEgetEndre`: digits only, no leading zeros, four at most, capped at
  /// 2000 kr. Returns the text to show; '' when nothing is left.
  static String tipsEget(String raw) {
    var v = raw.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');
    if (v.length > 4) v = v.substring(0, 4);
    if (v.isEmpty) return '';
    final n = int.parse(v);
    return '${n > 2000 ? 2000 : n}';
  }

  /// Notes travelling with the order: the chips plus the free text when any.
  static int antall(Iterable<String> valgte, String tekst) => valgte.length + (tekst.trim().isEmpty ? 0 : 1);

  /// The part of the order note the store reads (`chips · tekst`).
  static String notat(Iterable<String> valgte, String tekst) => [...valgte, if (tekst.trim().isNotEmpty) tekst.trim()].join(' · ');

  /// Design 21 Nov (A2): the courier note is its parts joined with « · » — the chips and whatever was typed.
  static List<String> dorDeler(String tekst) => [for (final d in tekst.split(' · ')) if (d.trim().isNotEmpty) d.trim()];

  /// A door chip toggles its part of the note; a chip's opposite ([mot]: «Ring på» ⇄ «Ikke ring på») leaves first.
  static String dorBytt(String tekst, String chip, Map<String, String> mot) {
    final deler = dorDeler(tekst);
    if (deler.contains(chip)) return deler.where((d) => d != chip).join(' · ');
    return [...deler.where((d) => d != mot[chip]), chip].join(' · ');
  }

  /// The first clock time in a text («Innen 18:15 · 25–35 min» → «18:15»), or null.
  static String? klokke(String tekst) => RegExp(r'\d{1,2}[:.]\d{2}').firstMatch(tekst)?.group(0)?.replaceAll('.', ':');

  /// The flat / floor for the address title, or null when the field holds nothing real («N/A», «-», «0»).
  static String? flatNo(String raw) {
    final f = raw.trim();
    if (f.isEmpty || RegExp(r'^(n/?a|none|null|-+|0)$', caseSensitive: false).hasMatch(f)) return null;
    return f;
  }

  /// «412 34 567»: an eight-digit Norwegian number in 3-2-3 (a leading +47 dropped); anything else as typed.
  static String tlf(String raw) {
    var d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length == 10 && d.startsWith('47')) d = d.substring(2);
    if (d.length == 8) return '${d.substring(0, 3)} ${d.substring(3, 5)} ${d.substring(5)}';
    return raw.trim();
  }
}

const Color _mint = Color(0xFF5CE0B8);

/// Lys plan: the design's input placeholder (`input::placeholder`).
const Color _plassLys = Color(0xFF9A9188);

/// Lys plan: `inset 0 0 0 1.5px rgba(11,107,87,.4)` — the filled field ring
/// (`bkFeltSh` / `tipsEgetSh`).
const Color _ringLys = Color.fromRGBO(11, 107, 87, .4);

/// One pickup time of the Hentetid segment.
class KurvHentetid {
  const KurvHentetid(this.id, this.label);
  final String id;
  final String label;
}

/// A chip on the dark card: mint gradient and check when on ([hoyde] 34, the door chips 36).
class KurvMorkChip extends StatelessWidget {
  const KurvMorkChip({super.key, required this.label, required this.paa, required this.onTap, this.hoyde = 34});
  final String label;
  final bool paa;
  final VoidCallback onTap;
  final double hoyde;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    // Lys plan (`cbg` / `cfg` / `csh`, L25788–25790): mint-dis with the
    // `rgba(11,107,87,.25)` ring when on, `--lys-dis` without one when off.
    final lys = context.lys;
    return OnbPressable(
      onTap: onTap,
      pressDy: 1.5,
      child: AnimatedContainer(
        duration: BergenTokens.motion(context, const Duration(milliseconds: 200)),
        constraints: BoxConstraints(minHeight: hoyde * s),
        padding: EdgeInsets.symmetric(horizontal: 12 * s),
        decoration: CssDecoration(
          borderRadius: BorderRadius.circular(999),
          color: lys ? (paa ? LysPalett.mintDis : LysPalett.dis) : paa ? null : rgba(255, 255, 255, .08),
          gradient: paa && !lys ? cssLinear(180, [rgba(130, 242, 210, .3), rgba(92, 224, 184, .1)]) : null,
          border: Border.all(
            color: lys
                ? (paa ? const Color.fromRGBO(11, 107, 87, .25) : const Color(0x00000000))
                : paa
                ? rgba(92, 224, 184, .5)
                : rgba(255, 255, 255, .1),
          ),
          boxShadow: paa && !lys ? [BoxShadow(color: rgba(3, 16, 24, .85), offset: Offset(0, 9 * s), blurRadius: onbBlur(12 * s), spreadRadius: -7 * s)] : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (paa) ...[KurvIcon(11 * s, KurvIcons.check, color: context.aeM(_mint, kurvLysIkon), width: 3.4), SizedBox(width: 5 * s)],
          Text(
            label,
            style: bText(
              context,
              11.5,
              weight: FontWeight.w800,
              letterSpacingEm: -.01,
              color: paa ? context.aeM(_mint, LysPalett.mintTekst) : context.aeM(rgba(255, 255, 255, .86), LysPalett.brod),
            ),
          ),
        ]),
      ),
    );
  }
}

/// A segmented pill with the white thumb sliding `.45s cubic(.34,1.56,.64,1)`
/// (the Hentetid times; the tips chips use the same look in `KurvTips`).
class KurvSegment extends StatelessWidget {
  const KurvSegment({super.key, required this.valg, required this.i, required this.onValg, required this.keyPrefix});
  final List<String> valg;
  final int i;
  final ValueChanged<int> onValg;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    // Lys plan (`.mk7g` track, `.mk7h` thumb, `h.fg` as `tf`).
    final lys = context.lys;
    return Container(
      padding: EdgeInsets.all(4 * s),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: context.aeM(rgba(0, 0, 0, .22), LysPalett.dis), border: Border(bottom: BorderSide(color: lys ? const Color(0x00000000) : rgba(255, 255, 255, .1)))),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth / valg.length;
          return SizedBox(
            height: 38 * s,
            child: Stack(children: [
              AnimatedPositioned(
                duration: BergenTokens.motion(context, const Duration(milliseconds: 450)),
                curve: const Cubic(.34, 1.56, .64, 1),
                left: w * i,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: lys ? kurvLysFjordFyll : cssLinear(180, const [Color(0xFFFFFFFF), Color(0xFFE9EEED)]),
                    boxShadow: lys ? kurvLysTommelSkygge(s) : [BoxShadow(color: rgba(0, 10, 14, .7), offset: Offset(0, 6 * s), blurRadius: onbBlur(10 * s), spreadRadius: -6 * s)],
                  ),
                ),
              ),
              Row(children: [
                for (var k = 0; k < valg.length; k++)
                  Expanded(
                    child: GestureDetector(
                      key: Key('$keyPrefix$k'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onValg(k),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: BergenTokens.motion(context, const Duration(milliseconds: 300)),
                          style: bText(
                            context,
                            12.5,
                            weight: FontWeight.w800,
                            color: k == i ? context.aeM(const Color(0xFF1E4F5C), Colors.white) : context.aeM(rgba(255, 255, 255, .8), LysPalett.sekundar),
                          ),
                          child: Text(valg[k]),
                        ),
                      ),
                    ),
                  ),
              ]),
            ]),
          );
        },
      ),
    );
  }
}

/// The tips card's «Eget beløp … kr» row (#19): numeric, four digits, cap 2000.
class KurvTipsEget extends StatelessWidget {
  const KurvTipsEget({super.key, required this.controller, required this.onEndret});
  final TextEditingController controller;
  final ValueChanged<String> onEndret;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final paa = controller.text.isNotEmpty;
    // Lys plan (`tipsEgetBg` / `tipsEgetSh`, `.mk14`, `.mk12`).
    final lys = context.lys;
    return AnimatedContainer(
      duration: BergenTokens.motion(context, const Duration(milliseconds: 250)),
      height: 46 * s,
      margin: EdgeInsets.only(top: 8 * s),
      padding: EdgeInsets.symmetric(horizontal: 16 * s),
      decoration: CssDecoration(
        borderRadius: BorderRadius.circular(999),
        color: paa ? context.aeM(rgba(92, 224, 184, .12), LysPalett.mintDis) : context.aeM(rgba(0, 0, 0, .22), LysPalett.dis),
        border: paa ? Border.all(color: context.aeM(rgba(92, 224, 184, .7), _ringLys), width: 1.5 * s) : null,
        boxShadow: lys
            ? null
            : paa
            ? [BoxShadow(color: rgba(92, 224, 184, .5), offset: Offset(0, 6 * s), blurRadius: onbBlur(14 * s), spreadRadius: -8 * s)]
            : [BoxShadow(color: rgba(0, 0, 0, .35), blurRadius: onbBlur(3 * s), offset: Offset(0, 1 * s), blurStyle: BlurStyle.inner)],
      ),
      child: Row(children: [
        Expanded(child: Text(KasseCopy.a1_kasse_tips_eget, style: bText(context, 12.5, weight: FontWeight.w700, color: context.aeM(rgba(255, 255, 255, .72), LysPalett.sekundar)))),
        SizedBox(width: 10 * s),
        SizedBox(
          width: 70 * s,
          child: Semantics(
            label: KasseCopy.a1_kasse_tips_eget_label,
            child: TextField(
              key: const Key('a1_kasse_tips_eget'),
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
              textAlign: TextAlign.right,
              cursorColor: context.aeM(_mint, LysPalett.mintTekst),
              onChanged: (v) {
                final n = KasseValg.tipsEget(v);
                if (n != v) controller.value = TextEditingValue(text: n, selection: TextSelection.collapsed(offset: n.length));
                onEndret(n);
              },
              style: bText(context, 15, weight: FontWeight.w800, color: context.aeM(Colors.white, LysPalett.tittel)),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: '0',
                hintStyle: bText(context, 15, weight: FontWeight.w800, color: context.aeM(rgba(255, 255, 255, .35), _plassLys)),
              ),
            ),
          ),
        ),
        SizedBox(width: 10 * s),
        Text(KasseCopy.a1_kasse_kr, style: bText(context, 13, weight: FontWeight.w800, color: context.aeM(rgba(255, 255, 255, .72), LysPalett.sekundar))),
      ]),
    );
  }
}
