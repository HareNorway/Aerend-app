import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../common/auth/onboarding_kit.dart' show onbBlur, OnbPressable;
import '../../common/home/bergen/bergen_kit.dart';
import '../../../theme/bergen_tokens.dart';
import '../kit/bergen_css.dart';
import '../kit/bergen_motion.dart';
import '../kit/svg_sti.dart';
import 'kasse_copy.dart';
import 'kurv_parts.dart';

/// Kassen › Flere valg (Onboarding plan Step 7, §3 #18–#19, prototype
/// L7087–7128 + L24313–24350): the dark «Beskjed til butikken» card for
/// both modes — chips with a mint check, the 140-char pill field (the
/// «Allergi» placeholder and orange ring), the Hentetid segment with the
/// sliding thumb (pickup) and the mint receipt line — and the tips card's
/// «Eget beløp» row.

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
}

const Color _mint = Color(0xFF5CE0B8);

/// One pickup time of the Hentetid segment.
class KurvHentetid {
  const KurvHentetid(this.id, this.label);
  final String id;
  final String label;
}

class KurvBeskjedKort extends StatelessWidget {
  const KurvBeskjedKort({
    super.key,
    required this.hent,
    required this.butikk,
    required this.chips,
    required this.valgte,
    required this.onChip,
    required this.controller,
    required this.onEndret,
    required this.allergiPaa,
    required this.kvittering,
    this.tider = const [],
    this.tidId,
    this.onTid,
  });

  final bool hent;
  final String butikk;
  final List<String> chips;
  final Set<String> valgte;
  final ValueChanged<String> onChip;
  final TextEditingController controller;
  final VoidCallback onEndret;

  /// «Allergi» is on: the field asks which, with an orange ring.
  final bool allergiPaa;

  /// The mint receipt line, null to hide it.
  final String? kvittering;
  final List<KurvHentetid> tider;
  final String? tidId;
  final ValueChanged<KurvHentetid>? onTid;

  static void _pose(Canvas c, Paint p) {
    c.drawPath(svgSti('M6 8h12l-1 12H7L6 8z'), p);
    c.drawPath(svgSti('M9 8V6.5a3 3 0 0 1 6 0V8'), p);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final fylt = controller.text.trim().isNotEmpty;
    final hvit = Colors.white;
    return BergenOnce(
      durationMs: 300,
      builder: (context, p, child) {
        final q = const Cubic(.2, .9, .3, 1).transform(p);
        return Opacity(opacity: q, child: Transform.translate(offset: Offset(0, 26 * (1 - q) * s), child: child));
      },
      child: KurvGlass(
        key: const Key('a1_kasse_beskjed_kort'),
        radius: 22 * s,
        padding: EdgeInsets.all(14 * s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const KurvRadFlis(icon: _pose),
              SizedBox(width: 11 * s),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(KasseCopy.a1_kasse_beskjed_butikk, style: bText(context, 13, weight: FontWeight.w800, letterSpacingEm: -.01)),
                  Text(hent ? KasseCopy.a1_kasse_bk_under_hent(butikk) : KasseCopy.a1_kasse_bk_under_lev(butikk), style: bText(context, 11, weight: FontWeight.w600, color: rgba(255, 255, 255, .62))),
                ]),
              ),
            ]),
            SizedBox(height: 12 * s),
            Wrap(
              spacing: 6 * s,
              runSpacing: 6 * s,
              children: [
                for (var i = 0; i < chips.length; i++)
                  _MorkChip(key: Key('a1_kasse_bk_chip_$i'), label: chips[i], paa: valgte.contains(chips[i]), onTap: () => onChip(chips[i])),
              ],
            ),
            SizedBox(height: 10 * s),
            // The pill field: mint ring when filled, orange when «Allergi» waits.
            AnimatedContainer(
              duration: BergenTokens.motion(context, const Duration(milliseconds: 250)),
              constraints: BoxConstraints(minHeight: 46 * s),
              padding: EdgeInsets.fromLTRB(16 * s, 4 * s, 4 * s, 4 * s),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: fylt ? rgba(92, 224, 184, .1) : rgba(0, 0, 0, .22),
                border: fylt
                    ? Border.all(color: rgba(92, 224, 184, .6), width: 1.5 * s)
                    : allergiPaa
                        ? Border.all(color: rgba(242, 109, 61, .7), width: 1.5 * s)
                        : null,
                boxShadow: fylt || allergiPaa ? null : [BoxShadow(color: rgba(0, 0, 0, .35), blurRadius: onbBlur(3 * s), offset: Offset(0, 1 * s), blurStyle: BlurStyle.inner)],
              ),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    key: const Key('a1_kasse_bk_felt'),
                    controller: controller,
                    onChanged: (_) => onEndret(),
                    maxLength: 140,
                    cursorColor: _mint,
                    style: bDisplay(context, 12.5, weight: FontWeight.w700, letterSpacingEm: 0, color: hvit),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      counterText: '',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 9 * s),
                      hintText: allergiPaa ? KasseCopy.a1_kasse_bk_plass_allergi : KasseCopy.a1_kasse_hent_beskjed_hint(butikk),
                      hintStyle: bDisplay(context, 12.5, weight: FontWeight.w700, letterSpacingEm: 0, color: rgba(255, 255, 255, .45)),
                    ),
                  ),
                ),
                if (controller.text.isNotEmpty)
                  Semantics(
                    button: true,
                    label: KasseCopy.a1_kasse_tom_beskjed,
                    child: OnbPressable(
                      key: const Key('a1_kasse_bk_tom'),
                      onTap: () {
                        controller.clear();
                        onEndret();
                      },
                      pressDy: 1.5,
                      child: Container(
                        width: 36 * s,
                        height: 36 * s,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: rgba(255, 255, 255, .1), border: Border.all(color: rgba(255, 255, 255, .1))),
                        child: KurvIcon(11 * s, KurvIcons.cross, color: rgba(255, 255, 255, .8), width: 3),
                      ),
                    ),
                  ),
              ]),
            ),
            if (hent && tider.isNotEmpty) ...[
              Container(
                margin: EdgeInsets.only(top: 14 * s),
                padding: EdgeInsets.only(top: 12 * s),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: rgba(255, 255, 255, .1)))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(KasseCopy.a1_kasse_hentetid, style: bText(context, 12.5, weight: FontWeight.w800)),
                    SizedBox(width: 10 * s),
                    Expanded(child: Text(KasseCopy.a1_kasse_hentetid_line, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: bText(context, 11, weight: FontWeight.w600, color: rgba(255, 255, 255, .62)))),
                  ]),
                  SizedBox(height: 10 * s),
                  _Segment(
                    valg: [for (final t in tider) t.label],
                    i: tider.indexWhere((t) => t.id == tidId).clamp(0, tider.length - 1),
                    onValg: (i) => onTid?.call(tider[i]),
                    keyPrefix: 'a1_kasse_hentetid_',
                  ),
                ]),
              ),
            ],
            if (kvittering != null)
              Container(
                margin: EdgeInsets.only(top: 12 * s),
                padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 10 * s),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14 * s), color: rgba(92, 224, 184, .1), border: Border.all(color: rgba(92, 224, 184, .22))),
                child: Row(children: [
                  KurvIcon(14 * s, KurvIcons.check, color: _mint, width: 2.6),
                  SizedBox(width: 8 * s),
                  Expanded(child: Text(kvittering!, key: const Key('a1_kasse_bk_kvitt'), style: bText(context, 11, weight: FontWeight.w700, height: 1.4, color: const Color(0xFFBFF3E2)))),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

/// A chip on the dark card: mint gradient and check when on.
class _MorkChip extends StatelessWidget {
  const _MorkChip({super.key, required this.label, required this.paa, required this.onTap});
  final String label;
  final bool paa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return OnbPressable(
      onTap: onTap,
      pressDy: 1.5,
      child: AnimatedContainer(
        duration: BergenTokens.motion(context, const Duration(milliseconds: 200)),
        constraints: BoxConstraints(minHeight: 34 * s),
        padding: EdgeInsets.symmetric(horizontal: 12 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: paa ? null : rgba(255, 255, 255, .08),
          gradient: paa ? cssLinear(180, [rgba(130, 242, 210, .3), rgba(92, 224, 184, .1)]) : null,
          border: Border.all(color: paa ? rgba(92, 224, 184, .5) : rgba(255, 255, 255, .1)),
          boxShadow: paa ? [BoxShadow(color: rgba(3, 16, 24, .85), offset: Offset(0, 9 * s), blurRadius: onbBlur(12 * s), spreadRadius: -7 * s)] : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (paa) ...[KurvIcon(11 * s, KurvIcons.check, color: _mint, width: 3.4), SizedBox(width: 5 * s)],
          Text(label, style: bText(context, 11.5, weight: FontWeight.w800, letterSpacingEm: -.01, color: paa ? _mint : rgba(255, 255, 255, .86))),
        ]),
      ),
    );
  }
}

/// A segmented pill with the white thumb sliding `.45s cubic(.34,1.56,.64,1)`
/// (the Hentetid times; the tips chips use the same look in `KurvTips`).
class _Segment extends StatelessWidget {
  const _Segment({required this.valg, required this.i, required this.onValg, required this.keyPrefix});
  final List<String> valg;
  final int i;
  final ValueChanged<int> onValg;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      padding: EdgeInsets.all(4 * s),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: rgba(0, 0, 0, .22), border: Border(bottom: BorderSide(color: rgba(255, 255, 255, .1)))),
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
                    gradient: cssLinear(180, const [Color(0xFFFFFFFF), Color(0xFFE9EEED)]),
                    boxShadow: [BoxShadow(color: rgba(0, 10, 14, .7), offset: Offset(0, 6 * s), blurRadius: onbBlur(10 * s), spreadRadius: -6 * s)],
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
                          style: bText(context, 12.5, weight: FontWeight.w800, color: k == i ? const Color(0xFF1E4F5C) : rgba(255, 255, 255, .8)),
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
    return AnimatedContainer(
      duration: BergenTokens.motion(context, const Duration(milliseconds: 250)),
      height: 46 * s,
      margin: EdgeInsets.only(top: 8 * s),
      padding: EdgeInsets.symmetric(horizontal: 16 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: paa ? rgba(92, 224, 184, .12) : rgba(0, 0, 0, .22),
        border: paa ? Border.all(color: rgba(92, 224, 184, .7), width: 1.5 * s) : null,
        boxShadow: paa
            ? [BoxShadow(color: rgba(92, 224, 184, .5), offset: Offset(0, 6 * s), blurRadius: onbBlur(14 * s), spreadRadius: -8 * s)]
            : [BoxShadow(color: rgba(0, 0, 0, .35), blurRadius: onbBlur(3 * s), offset: Offset(0, 1 * s), blurStyle: BlurStyle.inner)],
      ),
      child: Row(children: [
        Expanded(child: Text(KasseCopy.a1_kasse_tips_eget, style: bText(context, 12.5, weight: FontWeight.w700, color: rgba(255, 255, 255, .72)))),
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
              cursorColor: _mint,
              onChanged: (v) {
                final n = KasseValg.tipsEget(v);
                if (n != v) controller.value = TextEditingValue(text: n, selection: TextSelection.collapsed(offset: n.length));
                onEndret(n);
              },
              style: bText(context, 15, weight: FontWeight.w800),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: '0',
                hintStyle: bText(context, 15, weight: FontWeight.w800, color: rgba(255, 255, 255, .35)),
              ),
            ),
          ),
        ),
        SizedBox(width: 10 * s),
        Text(KasseCopy.a1_kasse_kr, style: bText(context, 13, weight: FontWeight.w800, color: rgba(255, 255, 255, .72))),
      ]),
    );
  }
}
