import 'package:flutter/material.dart';

import '../../common/auth/launch/lf_css.dart';
import '../aegil/aegil_bits.dart';
import '../kit/bergen_kit.dart';
import '../meg/meg_ark.dart';
import 'support.dart';

/// «Sak på ordren» (Launch L9237, `sakVals`): the case filed on this order —
/// the dot, «Vi ser på det · svar innen 30 min» and when. A case is shown
/// open; its resolution («Løst · N kr refundert», «Ikke løst») has no
/// customer read in the backend yet.
class SakPaaOrdren extends StatelessWidget {
  const SakPaaOrdren({super.key, required this.sak});

  final SupportSak sak;

  @override
  Widget build(BuildContext context) {
    final naar = DateTime.now().difference(sak.at).inMinutes < 60
        ? SupportCopy.naa
        : '${sak.at.hour.toString().padLeft(2, '0')}:${sak.at.minute.toString().padLeft(2, '0')}';
    return Container(
      key: const Key('oh-sak'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(242, 193, 78, .16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color.fromRGBO(35, 32, 29, .08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE0913A))),
              const SizedBox(width: 8),
              Expanded(child: Text(SupportCopy.ack, style: inter(13.5, weight: FontWeight.w800, color: const Color(0xFF23201D)))),
              Text(naar, style: inter(11, weight: FontWeight.w700, color: const Color(0xFF8C847C))),
            ],
          ),
          if ((sak.customerSees ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                style: inter(12.5, height: 1.45, color: const Color(0xFF57534B)),
                children: [
                  TextSpan(text: 'Ærend: ', style: inter(12.5, weight: FontWeight.w800, height: 1.45, color: const Color(0xFF23201D))),
                  TextSpan(text: sak.customerSees),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// «Noe galt med bestillingen? · Ægil ordner kreditt med én gang» — the
/// white row under the receipt (`kNoeGalt`).
class NoeGaltRad extends StatelessWidget {
  const NoeGaltRad({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AePress(
    key: const Key('oh-noe-galt'),
    onTap: onTap,
    dy: 0,
    scale: .985,
    child: CssBox(
      radius: BorderRadius.circular(22),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      bg: const [
        CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFFAF8F4)]),
      ],
      shadows: const [
        CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .95)),
        CssShadow(0, 0, 0, 1, Color.fromRGBO(35, 32, 29, .04)),
        CssShadow(0, 12, 20, -14, Color.fromRGBO(8, 24, 32, .45)),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 32),
        child: Row(
          children: [
            CssBox(
              width: 40,
              height: 40,
              radius: BorderRadius.circular(13),
              clip: true,
              bg: const [
                CssLinear(160, [Color(0xFF3F8798), Color(0xFF27606F), Color(0xFF1A4654)], [0, .52, 1]),
              ],
              shadows: const [
                CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .32)),
                CssShadow.inset(0, -3, 5, 0, Color.fromRGBO(4, 20, 28, .42)),
                CssShadow(0, 8, 12, -6, Color.fromRGBO(8, 24, 32, .55)),
              ],
              child: Center(child: Image.asset('assets/images/dashboard/invitation.png', width: 36, height: 36, fit: BoxFit.contain)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(SupportCopy.noeGalt, style: inter(13.5, weight: FontWeight.w800, color: const Color(0xFF23201D))),
                  Text(SupportCopy.noeGaltUnder, style: inter(11.5, color: const Color(0xFF6E6862))),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const CssBox(
              width: 30,
              height: 30,
              radius: BorderRadius.all(Radius.circular(999)),
              bg: [
                CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFE9EEED)]),
              ],
              shadows: [CssShadow.inset(0, -2, 4, 0, Color.fromRGBO(30, 79, 92, .14)), CssShadow(0, 4, 8, -4, Color.fromRGBO(8, 24, 32, .4))],
              child: Center(child: AeIkon('M9 6l6 6-6 6', size: 11, stroke: 3, color: Color(0xFF1E4F5C))),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A line of the order for step 2: count, name, price in kr.
typedef NoeGaltLinje = (int n, String navn, int kr);

/// `kArk noeGalt` (L19022): 1) what went wrong, 2) which line, 3) «Vi har
/// mottatt saken.» with the case reference; «Ferdig» files it through
/// `ops.customer.problem` (or, for «Ikke levert», a message on the order).
Future<void> visNoeGalt(BuildContext context, {required SupportOrdre ordre, required List<NoeGaltLinje> linjer}) {
  var steg = 1;
  (String, String, String, String)? valg;
  NoeGaltLinje? linje;
  var sender = false;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color.fromRGBO(15, 25, 30, .5),
    sheetAnimationStyle: AnimationStyle(
      curve: const Cubic(.2, .9, .3, 1),
      duration: BergenTokens.motion(context, const Duration(milliseconds: 300)),
      reverseDuration: BergenTokens.motion(context, BergenTokens.motionBase),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        if (steg == 1) {
          return MegArk(
            key: const Key('oh-noe-galt-1'),
            title: SupportCopy.noeGaltTittel(ordre.kode),
            subtitle: SupportCopy.noeGaltLinje,
            body: Column(
              children: [
                for (final v in SupportCopy.noeGaltValg)
                  MegArkRow(
                    key: Key('noe-galt-${v.$3}'),
                    title: v.$1,
                    sub: v.$2,
                    leading: _IkonFlis(sti: v.$4),
                    onTap: () => setState(() {
                      valg = v;
                      steg = 2;
                    }),
                  ),
              ],
            ),
          );
        }
        if (steg == 2) {
          return MegArk(
            key: const Key('oh-noe-galt-2'),
            title: SupportCopy.steg2Tittel(valg!.$1, ordre.kode),
            subtitle: SupportCopy.steg2Linje,
            body: Column(
              children: [
                for (final (i, l) in linjer.indexed)
                  MegArkRow(
                    key: Key('noe-galt-linje-$i'),
                    title: l.$2,
                    sub: '${l.$3} kr',
                    leading: _TallFlis(n: l.$1),
                    onTap: () => setState(() {
                      linje = l;
                      steg = 3;
                    }),
                  ),
              ],
            ),
            secondary: MegArkButton(key: const Key('noe-galt-tilbake'), label: SupportCopy.tilbake, onTap: () => setState(() => steg = 1)),
          );
        }
        final eksisterende = SupportStore.instance.sakFor(ordre.id);
        if (eksisterende != null) {
          return MegArk(
            key: const Key('oh-noe-galt-har'),
            title: SupportCopy.harAllerede,
            subtitle: SupportCopy.harAlleredeLinje,
            primary: MegArkButton(label: SupportCopy.ferdig, onTap: () => Navigator.of(ctx).pop()),
          );
        }
        final ref = '${valg!.$1}${linje == null ? '' : ' · ${linje!.$2}'} · ${ordre.kode}';
        return MegArk(
          key: const Key('oh-noe-galt-3'),
          title: SupportCopy.mottatt,
          subtitle: SupportCopy.ack,
          body: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: .9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(SupportCopy.saksreferanse, style: inter(10, weight: FontWeight.w800, em: .08, color: MegArkInk.sub)),
                const SizedBox(height: 4),
                Text(ref, key: const Key('noe-galt-ref'), style: inter(13.5, weight: FontWeight.w700, color: MegArkInk.ink)),
              ],
            ),
          ),
          primary: MegArkButton(
            key: const Key('noe-galt-ferdig'),
            label: SupportCopy.ferdig,
            onTap: () async {
              if (sender) return;
              sender = true;
              final sak = await SupportStore.instance.meld(ordre, valg!.$3, varer: [if (linje != null) linje!.$2], ord: valg!.$1);
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              if (context.mounted) showBergenToast(context, sak == null ? BergenRoutes.kommerSnart : SupportCopy.registrert);
            },
          ),
        );
      },
    ),
  );
}

class _IkonFlis extends StatelessWidget {
  const _IkonFlis({required this.sti});
  final String sti;

  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(color: MegArkInk.teal.withValues(alpha: .1), borderRadius: BorderRadius.circular(11)),
    child: Center(child: AeIkon(sti, size: 16, stroke: 2, color: MegArkInk.teal)),
  );
}

class _TallFlis extends StatelessWidget {
  const _TallFlis({required this.n});
  final int n;

  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(color: MegArkInk.teal.withValues(alpha: .1), borderRadius: BorderRadius.circular(11)),
    child: Center(child: Text('$n×', style: inter(12, weight: FontWeight.w800, color: MegArkInk.teal))),
  );
}
