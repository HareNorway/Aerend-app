import 'package:flutter/material.dart';

import '../../common/auth/onboarding_kit.dart' show onbBlur, OnbPressable;
import '../../common/home/bergen/bergen_kit.dart';
import '../../../theme/bergen_tokens.dart';
import '../../../theme/lys/lys_palett.dart';
import '../../../theme/lys/modus_scope.dart';
import '../kit/ae_primitiver.dart' show AeKollaps;
import '../kit/bergen_css.dart';
import '../kit/css_decoration.dart';
import '../kit/svg_sti.dart';
import '../onboarding/onb_maal.dart';
import 'kasse_copy.dart';
import 'kurv_beskjed.dart';
import 'kurv_kvittering.dart' show KvBryter;
import 'kurv_parts.dart';
import '../../../utils/utils.dart' show languages;

/// Design 21 Nov plan Step 2 (A2, design `Kasse · beskjed til budet` / `Kasse · beskjed til butikken`): the two
/// collapsible rows at the foot of the choices card.
///
/// - [KurvDorRad] (delivery only): the orange door tile, «Beskjed til budet», the note or «Porttelefon, etasje eller
///   hvor maten skal stå», and the pill «Legg til» / «Endre» / «Ferdig». Open: the 46 px pill field (placeholder
///   «F.eks. 3. etasje, ring på Hansen», 140 chars, Enter saves) with its clear key and a mint «Lagre», the four
///   chips («Ring på» and «Ikke ring på» push each other out), the switch «Del dørnotatet med budene dine» and
///   «Kode ved levering» with its line.
/// - [KurvButikkRad]: the bag tile, «Beskjed til butikken» (pickup: «Beskjed og hentetid»), the chips + «text»
///   (pickup: + «klar 18:20») or the empty line, and the round chevron key. Open: «{butikk} ser dette …», the chips,
///   the field (Enter saves), Hentetid (pickup) and the mint receipt line; the Bedriftskvittering row rides at the
///   bottom ([bunn]).
///
/// Both panels open like the design's `grid-template-rows: 0fr → 1fr` (.36 s) with the content fading (.26 s)
/// ([AeKollaps]); rows carry the `rgba(255,255,255,.1)` hairline on top.

const Color _mint = Color(0xFF5CE0B8);

class KurvDorRad extends StatelessWidget {
  const KurvDorRad({
    super.key,
    required this.aapen,
    required this.onAapen,
    required this.controller,
    required this.onEndret,
    required this.onLagre,
    required this.delt,
    required this.onDelt,
    required this.kode,
    required this.onKode,
    required this.kodeLinje,
  });

  final bool aapen;
  final ValueChanged<bool> onAapen;
  final TextEditingController controller;
  final VoidCallback onEndret;

  /// Enter, «Ferdig» or «Lagre»: trims, closes the row and says it.
  final VoidCallback onLagre;
  final bool delt;
  final VoidCallback onDelt;
  final bool kode;
  final VoidCallback onKode;
  final String kodeLinje;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final tekst = controller.text.trim();
    final har = tekst.isNotEmpty;
    final deler = KasseValg.dorDeler(tekst);
    final chips = KasseCopy.a1_kasse_dor_chips;
    final mot = KasseCopy.a1_kasse_dor_chips_mot;
    final hvit = context.aeM(Colors.white, LysPalett.tittel);
    final dus = context.aeM(rgba(255, 255, 255, .62), LysPalett.sekundar);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: aapen,
          label: KasseCopy.a1_kasse_beskjed_bud,
          child: GestureDetector(
            key: const Key('a1_kasse_rad_beskjed'),
            behavior: HitTestBehavior.opaque,
            onTap: () => aapen ? onLagre() : onAapen(true),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12 * s),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: context.aeM(rgba(255, 255, 255, .1), LysPalett.skille)))),
              child: Row(
                children: [
                  const KurvRadFlis(icon: KurvIcons.door, orange: true),
                  SizedBox(width: 11 * s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(KasseCopy.a1_kasse_beskjed_bud, style: bText(context, 13, weight: FontWeight.w800, letterSpacingEm: -.01, height: 1.3, color: hvit)),
                        Text(
                          har ? tekst : KasseCopy.a1_kasse_dor_under,
                          key: const Key('a1_kasse_dor_under'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bText(context, 11, weight: FontWeight.w600, color: dus),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8 * s),
                  ExcludeSemantics(
                    child: KurvEndrePill(
                      key: const Key('a1_kasse_dor_knapp'),
                      label: aapen ? languages.done : (har ? KasseCopy.a1_kasse_endre : languages.add),
                      ned: true,
                      aapen: aapen,
                      onTap: () => aapen ? onLagre() : onAapen(true),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AeKollaps(
          aapen: aapen,
          child: Padding(
            padding: EdgeInsets.only(bottom: 14 * s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OnbMaal(
                  id: 'dor',
                  radius: 23,
                  child: KurvFeltPille(
                    feltKey: const Key('a1_kasse_dor'),
                    tomKey: const Key('a1_kasse_dor_tom'),
                    controller: controller,
                    hint: KasseCopy.a1_kasse_dor_hint,
                    semantikk: KasseCopy.a1_kasse_dor_felt_label,
                    onEndret: onEndret,
                    onSubmit: onLagre,
                    lagre: onLagre,
                  ),
                ),
                SizedBox(height: 10 * s),
                Wrap(
                  spacing: 6 * s,
                  runSpacing: 6 * s,
                  children: [
                    for (var i = 0; i < chips.length; i++)
                      KurvMorkChip(
                        key: Key('a1_kasse_dor_chip_$i'),
                        label: chips[i],
                        paa: deler.contains(chips[i]),
                        hoyde: 36,
                        onTap: () {
                          controller.text = KasseValg.dorBytt(controller.text, chips[i], mot);
                          onEndret();
                        },
                      ),
                  ],
                ),
                SizedBox(height: 8 * s),
                _BryterRad(
                  nokkel: const Key('a1_kasse_dor_del'),
                  tittel: KasseCopy.a1_kasse_dor_del,
                  paa: delt,
                  onTap: onDelt,
                  hoyde: 48,
                ),
                _BryterRad(
                  nokkel: const Key('a1_kasse_kode_switch'),
                  tittel: KasseCopy.a1_kasse_kode,
                  linje: kodeLinje,
                  paa: kode,
                  onTap: onKode,
                  hoyde: 56,
                  strek: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class KurvButikkRad extends StatelessWidget {
  const KurvButikkRad({
    super.key,
    required this.aapen,
    required this.onAapen,
    required this.hent,
    required this.butikk,
    required this.chips,
    required this.valgte,
    required this.onChip,
    required this.controller,
    required this.onEndret,
    required this.onLagre,
    required this.allergiPaa,
    required this.kvittering,
    required this.tidLabel,
    this.tider = const [],
    this.tidId,
    this.onTid,
    this.bunn,
  });

  final bool aapen;
  final ValueChanged<bool> onAapen;
  final bool hent;
  final String butikk;
  final List<String> chips;
  final Set<String> valgte;
  final ValueChanged<String> onChip;
  final TextEditingController controller;
  final VoidCallback onEndret;
  final VoidCallback onLagre;

  /// «Allergi» is on: the field asks which, with an orange ring.
  final bool allergiPaa;

  /// The mint receipt line, null to hide it.
  final String? kvittering;

  /// The chosen slot's label («18:20») for the pickup sub-line.
  final String tidLabel;
  final List<KurvHentetid> tider;
  final String? tidId;
  final ValueChanged<KurvHentetid>? onTid;

  /// A row at the foot of the panel (the Bedriftskvittering row).
  final Widget? bunn;

  static void _pose(Canvas c, Paint p) {
    c.drawPath(svgSti('M6 8h12l-1 12H7L6 8z'), p);
    c.drawPath(svgSti('M9 8V6.5a3 3 0 0 1 6 0V8'), p);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final lys = context.lys;
    final hvit = context.aeM(Colors.white, LysPalett.tittel);
    final dus = context.aeM(rgba(255, 255, 255, .62), LysPalett.sekundar);
    final tekst = controller.text.trim();
    final valgTekst = [...chips.where(valgte.contains), if (tekst.isNotEmpty) '«$tekst»'];
    final String under;
    if (hent) {
      under = valgTekst.isEmpty ? KasseCopy.a1_kasse_bk_under_tom_hent(tidLabel) : '${valgTekst.join(' · ')} · ${KasseCopy.a1_kasse_bk_klar(tidLabel)}';
    } else {
      under = valgTekst.isEmpty ? KasseCopy.a1_kasse_bk_under_tom_lev : valgTekst.join(' · ');
    }
    final tittel = hent ? KasseCopy.a1_kasse_bk_tittel_hent : KasseCopy.a1_kasse_beskjed_butikk;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnbMaal(
          id: 'flere',
          radius: 22,
          child: Semantics(
            button: true,
            expanded: aapen,
            label: tittel,
            child: GestureDetector(
              key: const Key('a1_kasse_rad_butikk'),
              behavior: HitTestBehavior.opaque,
              onTap: () => aapen ? onLagre() : onAapen(true),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12 * s),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: context.aeM(rgba(255, 255, 255, .1), LysPalett.skille)))),
                child: Row(
                  children: [
                    const KurvRadFlis(icon: _pose),
                    SizedBox(width: 11 * s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tittel, style: bText(context, 13, weight: FontWeight.w800, letterSpacingEm: -.01, height: 1.3, color: hvit)),
                          SizedBox(height: 1 * s),
                          Text(under, key: const Key('a1_kasse_bk_under'), maxLines: 1, overflow: TextOverflow.ellipsis, style: bText(context, 11, weight: FontWeight.w600, color: dus)),
                        ],
                      ),
                    ),
                    SizedBox(width: 8 * s),
                    ExcludeSemantics(child: KurvPilKnapp(aapen: aapen)),
                  ],
                ),
              ),
            ),
          ),
        ),
        AeKollaps(
          aapen: aapen,
          child: Padding(
            padding: EdgeInsets.only(bottom: 14 * s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(hent ? KasseCopy.a1_kasse_bk_under_hent(butikk) : KasseCopy.a1_kasse_bk_under_lev(butikk), style: bText(context, 11, weight: FontWeight.w600, height: 1.4, color: dus)),
                SizedBox(height: 10 * s),
                Wrap(
                  spacing: 6 * s,
                  runSpacing: 6 * s,
                  children: [
                    for (var i = 0; i < chips.length; i++)
                      KurvMorkChip(key: Key('a1_kasse_bk_chip_$i'), label: chips[i], paa: valgte.contains(chips[i]), onTap: () => onChip(chips[i])),
                  ],
                ),
                SizedBox(height: 10 * s),
                KurvFeltPille(
                  feltKey: const Key('a1_kasse_bk_felt'),
                  tomKey: const Key('a1_kasse_bk_tom'),
                  controller: controller,
                  hint: allergiPaa ? KasseCopy.a1_kasse_bk_plass_allergi : KasseCopy.a1_kasse_hent_beskjed_hint(butikk),
                  allergi: allergiPaa,
                  onEndret: onEndret,
                  onSubmit: onLagre,
                ),
                if (hent && tider.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 14 * s),
                    padding: EdgeInsets.only(top: 12 * s),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: context.aeM(rgba(255, 255, 255, .1), LysPalett.skille)))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(KasseCopy.a1_kasse_hentetid, style: bText(context, 12.5, weight: FontWeight.w800, color: hvit)),
                        SizedBox(width: 10 * s),
                        Expanded(child: Text(KasseCopy.a1_kasse_hentetid_line, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: bText(context, 11, weight: FontWeight.w600, color: dus))),
                      ]),
                      SizedBox(height: 10 * s),
                      KurvSegment(
                        valg: [for (final t in tider) t.label],
                        i: tider.indexWhere((t) => t.id == tidId).clamp(0, tider.length - 1),
                        onValg: (i) => onTid?.call(tider[i]),
                        keyPrefix: 'a1_kasse_hentetid_',
                      ),
                    ]),
                  ),
                if (kvittering != null)
                  Container(
                    margin: EdgeInsets.only(top: 12 * s),
                    padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 10 * s),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14 * s), color: context.aeM(rgba(92, 224, 184, .1), LysPalett.mintDis), border: Border.all(color: lys ? const Color(0x00000000) : rgba(92, 224, 184, .22))),
                    child: Row(children: [
                      KurvIcon(14 * s, KurvIcons.check, color: context.aeM(_mint, kurvLysIkon), width: 2.6),
                      SizedBox(width: 8 * s),
                      Expanded(child: Text(kvittering!, key: const Key('a1_kasse_bk_kvitt'), style: bText(context, 11, weight: FontWeight.w700, height: 1.4, color: context.aeM(const Color(0xFFBFF3E2), LysPalett.mintTekst)))),
                    ]),
                  ),
                if (bunn != null) Padding(padding: EdgeInsets.only(top: 4 * s), child: bunn),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The design's pill field (`label` 46 px, padding 4 4 4 16, radius 999): dark `rgba(0,0,0,.22)` with the inset
/// shadow while empty, mint `.1` with a 1.5 px mint ring once filled (orange while «Allergi» waits); the 34 px clear
/// key and, with [lagre], the mint «Lagre» key.
class KurvFeltPille extends StatelessWidget {
  const KurvFeltPille({
    super.key,
    required this.feltKey,
    required this.tomKey,
    required this.controller,
    required this.hint,
    required this.onEndret,
    required this.onSubmit,
    this.semantikk,
    this.allergi = false,
    this.lagre,
  });

  final Key feltKey;
  final Key tomKey;
  final TextEditingController controller;
  final String hint;
  final String? semantikk;
  final VoidCallback onEndret;
  final VoidCallback onSubmit;
  final bool allergi;
  final VoidCallback? lagre;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final lys = context.lys;
    final fylt = controller.text.trim().isNotEmpty;
    final hvit = context.aeM(Colors.white, LysPalett.tittel);
    return AnimatedContainer(
      duration: BergenTokens.motion(context, const Duration(milliseconds: 250)),
      constraints: BoxConstraints(minHeight: 46 * s),
      padding: EdgeInsets.fromLTRB(16 * s, 4 * s, 4 * s, 4 * s),
      decoration: CssDecoration(
        borderRadius: BorderRadius.circular(999),
        color: fylt ? context.aeM(rgba(92, 224, 184, .1), LysPalett.mintDis) : context.aeM(rgba(0, 0, 0, .22), LysPalett.dis),
        border: fylt
            ? Border.all(color: context.aeM(rgba(92, 224, 184, .6), const Color.fromRGBO(11, 107, 87, .4)), width: 1.5 * s)
            : allergi
                ? Border.all(color: rgba(242, 109, 61, .7), width: 1.5 * s)
                : null,
        boxShadow: fylt || allergi || lys ? null : [BoxShadow(color: rgba(0, 0, 0, .35), blurRadius: onbBlur(3 * s), offset: Offset(0, 1 * s), blurStyle: BlurStyle.inner)],
      ),
      child: Row(children: [
        Expanded(
          child: Semantics(
            label: semantikk,
            child: TextField(
              key: feltKey,
              controller: controller,
              onChanged: (_) => onEndret(),
              onSubmitted: (_) => onSubmit(),
              textInputAction: TextInputAction.done,
              maxLength: 140,
              cursorColor: context.aeM(_mint, LysPalett.mintTekst),
              style: bDisplay(context, 12.5, weight: FontWeight.w700, letterSpacingEm: 0, color: hvit),
              decoration: InputDecoration(
                isCollapsed: true,
                counterText: '',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 9 * s),
                hintText: hint,
                hintStyle: bDisplay(context, 12.5, weight: FontWeight.w700, letterSpacingEm: 0, color: context.aeM(rgba(255, 255, 255, .45), const Color(0xFF9A9188))),
              ),
            ),
          ),
        ),
        if (controller.text.isNotEmpty) ...[
          Semantics(
            button: true,
            label: KasseCopy.a1_kasse_tom_beskjed,
            child: OnbPressable(
              key: tomKey,
              onTap: () {
                controller.clear();
                onEndret();
              },
              pressDy: 1.5,
              child: Container(
                width: 34 * s,
                height: 34 * s,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: context.aeM(rgba(255, 255, 255, .1), LysPalett.dis), border: Border.all(color: lys ? const Color(0x00000000) : rgba(255, 255, 255, .1))),
                child: KurvIcon(11 * s, KurvIcons.cross, color: context.aeM(rgba(255, 255, 255, .8), const Color.fromRGBO(30, 79, 92, .8)), width: 3),
              ),
            ),
          ),
          if (lagre != null) ...[
            SizedBox(width: 6 * s),
            Semantics(
              button: true,
              label: languages.save,
              child: OnbPressable(
                key: const Key('a1_kasse_dor_lagre'),
                onTap: lagre!,
                pressDy: 1.5,
                child: Container(
                  height: 38 * s,
                  padding: EdgeInsets.symmetric(horizontal: 14 * s),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: lys ? kurvLysFjordFyll : cssLinear(180, const [Color(0xFF8AF2D4), Color(0xFF3FCFA6)]),
                    boxShadow: [BoxShadow(color: rgba(3, 16, 24, lys ? .25 : .6), offset: Offset(0, 6 * s), blurRadius: onbBlur(10 * s), spreadRadius: -5 * s)],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    KurvIcon(11 * s, KurvIcons.check, color: lys ? Colors.white : const Color(0xFF0E3B3A), width: 3.4),
                    SizedBox(width: 6 * s),
                    Text(languages.save, style: bText(context, 12.5, weight: FontWeight.w800, letterSpacingEm: -.01, color: lys ? Colors.white : const Color(0xFF0E3B3A))),
                  ]),
                ),
              ),
            ),
          ],
        ],
      ]),
    );
  }
}

/// The round 34 px mint key whose chevron turns 180° (`.28s cubic-bezier(.3,1.2,.5,1)`).
class KurvPilKnapp extends StatelessWidget {
  const KurvPilKnapp({super.key, required this.aapen});

  final bool aapen;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      width: 34 * s,
      height: 34 * s,
      alignment: Alignment.center,
      decoration: kurvMintGlass(s, shape: BoxShape.circle, lys: context.lys),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const SizedBox.expand(),
          bergenInsetTop(radius: 17 * s, height: 1.5 * s, alpha: context.aeM(.32, 0)),
          AnimatedRotation(
            turns: aapen ? .5 : 0,
            duration: BergenTokens.motion(context, const Duration(milliseconds: 280)),
            curve: const Cubic(.3, 1.2, .5, 1),
            child: KurvIcon(14 * s, KurvIcons.chevronDown, color: context.aeM(_mint, kurvLysIkon), width: 3),
          ),
        ],
      ),
    );
  }
}

/// A switch row of the door panel: title 12.5/800 (+ line 11/600 1.35), the 48×28 switch; [strek] draws the
/// hairline on top (the «Kode ved levering» row).
class _BryterRad extends StatelessWidget {
  const _BryterRad({required this.nokkel, required this.tittel, this.linje, required this.paa, required this.onTap, required this.hoyde, this.strek = false});

  final Key nokkel;
  final String tittel;
  final String? linje;
  final bool paa;
  final VoidCallback onTap;
  final double hoyde;
  final bool strek;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Semantics(
      toggled: paa,
      label: tittel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: hoyde * s),
          decoration: BoxDecoration(border: strek ? Border(top: BorderSide(color: context.aeM(rgba(255, 255, 255, .1), LysPalett.skille))) : null),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tittel, style: bText(context, 12.5, weight: FontWeight.w800, color: context.aeM(Colors.white, LysPalett.tittel))),
                    if (linje != null)
                      Padding(
                        padding: EdgeInsets.only(top: 1 * s),
                        child: Text(linje!, style: bText(context, 11, weight: FontWeight.w600, height: 1.35, color: context.aeM(rgba(255, 255, 255, .62), LysPalett.sekundar))),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 12 * s),
              ExcludeSemantics(child: KvBryter(key: nokkel, on: paa, onTap: onTap, avFarge: context.aeM(rgba(255, 255, 255, .16), const Color.fromRGBO(30, 79, 92, .16)))),
            ],
          ),
        ),
      ),
    );
  }
}
