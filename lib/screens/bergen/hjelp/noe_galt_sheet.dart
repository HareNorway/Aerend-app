import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../common/auth/launch/lf_css.dart';
import '../aegil/aegil_bits.dart';
import '../kit/bergen_kit.dart';
import '../hjem/hjem_harness.dart';
import '../meg/meg_ark.dart';
import '../../snurre/snurre_launcher_policy.dart';
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
    final naar = DateTime.now().difference(sak.at).inMinutes < 60 ? SupportCopy.naa : '${sak.at.hour.toString().padLeft(2, '0')}:${sak.at.minute.toString().padLeft(2, '0')}';
    return Container(
      key: const Key('oh-sak'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      // The dark Ark's glass (new Bergen L9883).
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, .05)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, .16)),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 10, 16, .85), offset: Offset(0, 12), blurRadius: 20 / 2 / .57735, spreadRadius: -14)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sak.loest ? const Color(0xFF5CE0B8) : const Color(0xFFF2C14E),
                  boxShadow: [BoxShadow(color: sak.loest ? const Color(0xFF5CE0B8) : const Color(0xFFF2C14E), blurRadius: 8 / 2 / .57735)],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  SupportCopy.ack,
                  style: inter(13.5, weight: FontWeight.w800, color: Colors.white),
                ),
              ),
              Text(
                naar,
                style: inter(11.5, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .62)),
              ),
            ],
          ),
          if ((sak.customerSees ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                style: inter(12.5, weight: FontWeight.w600, height: 1.45, color: const Color.fromRGBO(255, 255, 255, .8)),
                children: [
                  TextSpan(
                    text: 'Ærend: ',
                    style: inter(12.5, weight: FontWeight.w800, height: 1.45, color: Colors.white),
                  ),
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

/// «Noe galt med bestillingen? · Vi ser på det og svarer innen … min» — the
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
      radius: BorderRadius.circular(20),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      // The dark Ark's glass (new Bergen L9890).
      bg: const [
        CssLinear(180, [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, .05)]),
      ],
      shadows: const [
        CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .22)),
        CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .16)),
        CssShadow(0, 12, 20, -14, Color.fromRGBO(0, 10, 16, .85)),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 36),
        child: Row(
          children: [
            CssBox(
              width: 42,
              height: 42,
              radius: BorderRadius.circular(14),
              clip: true,
              bg: const [
                CssLinear(160, [Color(0xFF3F8798), Color(0xFF27606F), Color(0xFF1A4654)], [0, .52, 1]),
              ],
              shadows: const [
                CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .32)),
                CssShadow(0, 6, 10, -6, Color.fromRGBO(0, 10, 16, .7)),
              ],
              child: Center(child: Image.asset('assets/images/dashboard/invitation.png', width: 38, height: 38, fit: BoxFit.contain)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    SupportCopy.noeGalt,
                    style: inter(14, weight: FontWeight.w800, color: Colors.white),
                  ),
                  Text(SupportCopy.noeGaltUnder, style: inter(12, weight: FontWeight.w600, color: const Color.fromRGBO(255, 255, 255, .66))),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: const Color.fromRGBO(255, 255, 255, .12),
                border: Border.all(color: const Color.fromRGBO(255, 255, 255, .2)),
              ),
              child: const Center(child: AeIkon('M9 6l6 6-6 6', size: 12, stroke: 3)),
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
  // Debug: `ohNoeGaltSteg` opens on step 2 or 3 (first reason, first line).
  if (kDebugMode && HjemHarness.ohNoeGaltSteg > 1) {
    steg = HjemHarness.ohNoeGaltSteg;
    valg = SupportCopy.noeGaltValg.first;
    if (steg == 3 && linjer.isNotEmpty) linje = linjer.first;
    HjemHarness.ohNoeGaltSteg = 1;
  }
  return showModalBottomSheet<void>(
    context: context,
    routeSettings: const RouteSettings(name: '${snurreLauncherHiddenRoutePrefix}noe-galt'),
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color.fromRGBO(15, 25, 30, .5),
    sheetAnimationStyle: AnimationStyle(
      curve: const Cubic(.2, .9, .3, 1),
      duration: BergenTokens.motion(context, const Duration(milliseconds: 300)),
      reverseDuration: BergenTokens.motion(context, BergenTokens.motionBase),
    ),
    builder: (ctx) => MegArkSkala(
      child: StatefulBuilder(
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
                      leading: MegArkIkon(v.$4),
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
            body: MegArkCodeCard(
              tapKey: const Key('noe-galt-kopier'),
              codeKey: const Key('noe-galt-ref'),
              label: SupportCopy.saksreferanse,
              code: ref,
              onCopy: () {
                Clipboard.setData(ClipboardData(text: ref));
                showBergenToast(ctx, SupportCopy.kopiert);
              },
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
                if (context.mounted) showBergenToast(context, sak == null ? SupportCopy.ikkeSendt : SupportCopy.registrert);
              },
            ),
          );
        },
      ),
    ),
  );
}

/// `harTileTx`: the teal tile of [MegArkIkon] with the line's count.
class _TallFlis extends StatelessWidget {
  const _TallFlis({required this.n});
  final int n;

  @override
  Widget build(BuildContext context) => CssBox(
    width: 40,
    height: 40,
    radius: BorderRadius.circular(13),
    bg: const [
      CssLinear(160, [Color(0xFF3F8798), Color(0xFF27606F), Color(0xFF1A4654)], [0, .52, 1]),
    ],
    shadows: const [
      CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .32)),
      CssShadow.inset(0, -3, 5, 0, Color.fromRGBO(4, 20, 28, .42)),
      CssShadow(0, 8, 12, -6, Color.fromRGBO(8, 24, 32, .55)),
    ],
    child: Center(
      child: Text('$n×', style: jakarta(13, color: Colors.white)),
    ),
  );
}
