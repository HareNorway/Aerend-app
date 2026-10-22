import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../networking/ops/cus_api.dart';
import '../../../utils/utils.dart';
import '../../common/auth/launch/lf_css.dart';
import '../aegil/aegil_bits.dart';
import '../aegil/aegil_chat.dart' show AeTenker;
import '../kit/bergen_kit.dart';
import '../hjem/hjem_harness.dart';
import '../meg/a3_services.dart';
import '../meg/meg_ark.dart';
import 'package:aerend_customer/utils/route_names.dart';
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
  const NoeGaltRad({super.key, required this.onTap, this.under});

  final VoidCallback onTap;

  /// Customer Step 10: «Ett bilde og én linje · svar innen N min» from the server's SLA.
  final String? under;

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
                  Text(under ?? SupportCopy.noeGaltUnder, style: inter(12, weight: FontWeight.w600, color: const Color.fromRGBO(255, 255, 255, .66))),
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
    routeSettings: const RouteSettings(name: '${appRoutePrefix}noe-galt'),
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

// ── Customer Step 10: «Noe galt med bestillingen?» (C2) ─────────────────────

/// Copy for the C2 sheet and the case row (design `agentfunksjoner C2.1–C2.10`;
/// Customer spec §4.4, support refunds spec §2.4). `cus_sak_*` keys, NO and EN.
abstract final class CusIssueCopy {
  static bool get _en => resolveSelectedLanguage() == 'en';
  static String _t(String no, String en) => _en ? en : no;

  // C2.1 the entry row.
  static String get cus_sak_rad => _t('Noe galt med bestillingen?', 'Something wrong with the order?');
  static String cus_sak_rad_under(int min) => _t('Ett bilde og én linje · svar innen $min min', 'One photo and one line · answer within $min min');

  // C2.2 / C2.3 step 1.
  static String get cus_sak_lytter => _t('Lytter', 'Listening');
  static String get cus_sak_hva_skjedde => _t('Hva skjedde?', 'What happened?');
  static String get cus_sak_linje => _t('Velg hva, og skriv én linje om du vil. Ett bilde er nok.', 'Pick what, write a line if you like. One photo is enough.');
  static String get cus_sak_bilde => _t('Bilde', 'Photo');
  static String get cus_sak_bilde_fjern => _t('Fjern bildet', 'Remove the photo');
  static String get cus_sak_skriv => _t('Rømmen manglet …', 'The cream was missing …');
  static String get cus_sak_send => _t('Send', 'Send');
  static String get cus_sak_legg_til_linje => _t('Det du skriver nå legges til saken.', 'What you write now joins the case.');

  // C2.4 sending.
  static String get cus_sak_tenker => _t('Tenker', 'Thinking');
  static String get cus_sak_ser_paa => _t('Ser på bestillingen …', 'Looking at the order …');
  static String get cus_sak_svar_sekunder => _t('Svar innen sekunder', 'An answer within seconds');

  // C2.5–C2.8 the outcomes (the lines come from the server; these are the eyebrows and keys).
  static String get cus_sak_lost => _t('Løst', 'Resolved');
  static String get cus_sak_ser_paa_det => _t('Ser på det', 'Looking into it');
  static String get cus_sak_beklager => _t('Beklager', 'Sorry');
  static String get cus_sak_avgjort => _t('Avgjort', 'Decided');
  static String cus_sak_aapen_kort(String ref) => _t('Sak $ref er åpen', 'Case $ref is open');
  static String get cus_sak_ordre_naa => _t('Ordre · nå', 'Order · now');
  static String cus_sak_budets_bilde(String tid, String label) => _t('Budets bilde · $tid · ${label.toLowerCase()}', "The courier's photo · $tid · ${label.toLowerCase()}");
  static String cus_sak_budets_bevis(String tid, String label) => _t('$label · $tid', '$label · $tid');
  static String get cus_sak_allerede => _t('Denne saken er allerede åpen.', 'This case is already open.');
  static String cus_sak_allerede_linje(String ref, String? innen) => _t('$ref · ${innen == null ? 'Vi svarer snart' : 'Vi svarer innen $innen'} · det du skriver nå legges til saken', '$ref · ${innen == null ? 'We answer soon' : 'We answer by $innen'} · what you write now joins the case');
  static String get cus_sak_legg_til => _t('Legg til i saken', 'Add to the case');
  static String get cus_sak_se_saken => _t('Se saken', 'See the case');
  static String get cus_sak_lagt_til => _t('Lagt til i saken', 'Added to the case');
  static String get cus_sak_ferdig => _t('Ferdig', 'Done');
  static String get cus_sak_feil => _t('Fikk ikke sendt saken. Prøv igjen, eller snakk med oss under Hjelp.', 'Could not send the case. Try again, or talk to us under Help.');
  static String get cus_sak_frist_ute => _t('Fristen for å melde fra har gått ut. Snakk med oss under Hjelp.', 'The window to report has passed. Talk to us under Help.');

  // The case row on the order (C2.1 «Sak», refunds spec §2.4) and C2.9 / C2.10.
  static String get cus_sak_ikke_lost => _t('Ikke løst', 'Not resolved');
  static String get cus_sak_gjenaapnet => _t('Saken er åpnet igjen · et menneske ser på den', 'The case is open again · a person looks at it');
  static String cus_sak_svar_fra(String navn) => _t('$navn, Ærend', '$navn, Ærend');
  static String get cus_sak_naa => _t('Nå', 'Now');
}

/// The six chips of step 1 (C2.2), in the design's order, with the server's
/// labels when it sent them.
const List<(String, String)> kCusIssueTyper = [('missing_item', 'Manglet noe'), ('wrong_item', 'Feil vare'), ('damaged', 'Skadet'), ('cold_late', 'Kaldt eller sent'), ('not_delivered', 'Ikke levert'), ('other', 'Annet')];

/// How «Noe galt» opens on an order: the C2 sheet when `cus.order_issue` is
/// on (the server answers the window and the chips), else the plain
/// three-step sheet that files through `ops.customer.problem` — the design's
/// own «gateway off → plain form». Returns the issue when one was filed or
/// joined.
Future<CusIssue?> noeGaltFlyt(BuildContext context, {required SupportOrdre ordre, required List<NoeGaltLinje> linjer, CusApi? api, CusIssueStatus? status}) async {
  final a = api ?? CusApi();
  final st = status ?? await a.issueStatus(ordre.id);
  if (!context.mounted) return null;
  if (st == null) {
    await visNoeGalt(context, ordre: ordre, linjer: linjer);
    return null;
  }
  if (!st.canReport && st.issue == null) {
    showBergenToast(context, CusIssueCopy.cus_sak_frist_ute);
    return null;
  }
  return visNoeGaltC2(context, ordre: ordre, status: st, api: a);
}

/// `agentfunksjoner C2.2–C2.8` on the dark Ark: one step (the chips, a photo,
/// one line, «Send»), «Tenker · Ser på bestillingen …», then the outcome the
/// policy engine gave — «Løst» with the amount, «Ser på det» with the case,
/// «Beklager» with the courier's proof for «Ikke levert», or «Denne saken er
/// allerede åpen» with «Legg til i saken». Nothing is negotiated here: the
/// amount is the policy's, a decline only ever comes from a person.
Future<CusIssue?> visNoeGaltC2(BuildContext context, {required SupportOrdre ordre, required CusIssueStatus status, CusApi? api, Future<String?> Function()? velgBilde, CusIssue? fake}) async {
  final a = api ?? CusApi();
  final typer = status.types.isEmpty ? kCusIssueTyper : [for (final t in status.types) (t.key, t.label)];
  String? valgt;
  String? bilde;
  var steg = status.issue != null && status.issue!.open ? 'utfall' : 'skriv';
  CusIssue? issue = status.issue != null && status.issue!.open ? CusIssue.fromJson({'already': true}) : null;
  if (issue != null) issue = _medAllerede(status.issue!);
  if (fake != null) {
    issue = fake;
    steg = 'utfall';
  } else if (kDebugMode && HjemHarness.ohSakJson != null) {
    issue = CusIssue.fromJson(HjemHarness.ohSakJson!);
    HjemHarness.ohSakJson = null;
    steg = 'utfall';
  }
  var append = false;
  var sender = false;
  StateSetter? setArk;
  Future<void> Function()? sendFn;
  final tekst = TextEditingController();
  // Debug: `ohSakSteg` opens the sheet at `tenker`.
  if (kDebugMode && HjemHarness.ohSakSteg == 'tenker') {
    steg = 'tenker';
    HjemHarness.ohSakSteg = null;
  }
  final out = await showMegArk<CusIssue?>(
    context,
    mork: true,
    tastatur: true,
    key: const Key('cus-sak-ark'),
    title: CusIssueCopy.cus_sak_lytter,
    titleBuilder: () => switch (steg) {
      'tenker' => CusIssueCopy.cus_sak_tenker,
      'utfall' => _eyebrow(issue),
      _ => CusIssueCopy.cus_sak_lytter,
    },
    subtitleBuilder: () => steg == 'skriv' ? (append ? CusIssueCopy.cus_sak_legg_til_linje : null) : null,
    body: (ctx, setState) {
      setArk = setState;
      Future<void> send() async {
        if (sender) return;
        if (valgt == null && tekst.text.trim().isEmpty && bilde == null) return;
        setState(() {
          sender = true;
          steg = 'tenker';
        });
        final r = append && issue != null
            ? (issue: await a.issueAppend(issue!.id, tekst.text), feil: null)
            : await a.issueOpen(ordre.id, type: valgt, text: tekst.text, photoPath: bilde, append: append);
        if (!ctx.mounted) return;
        setState(() {
          sender = false;
          if (r.issue != null) {
            issue = r.issue;
            steg = 'utfall';
            if (append) showBergenToast(ctx, CusIssueCopy.cus_sak_lagt_til);
            append = false;
          } else {
            steg = 'skriv';
            showBergenToast(ctx, r.feil == 'ISSUE_WINDOW_CLOSED' ? CusIssueCopy.cus_sak_frist_ute : CusIssueCopy.cus_sak_feil);
          }
        });
      }

      sendFn = send;
      Future<void> taBilde() async {
        final f = await (velgBilde ?? A3Services.velgBilde)();
        if (ctx.mounted && f != null) setState(() => bilde = f);
      }

      switch (steg) {
        case 'tenker':
          return _SakTenker(key: const Key('cus-sak-tenker'));
        case 'utfall':
          return _SakUtfall(issue: issue!, ordre: ordre, onSeSaken: () => Navigator.of(ctx).pop(issue));
        default:
          return _SakSkriv(
            typer: typer,
            valgt: valgt,
            bilde: bilde,
            tekst: tekst,
            append: append,
            onVelg: (k) => setState(() => valgt = valgt == k ? null : k),
            onBilde: taBilde,
            onFjernBilde: () => setState(() => bilde = null),
            onSend: send,
          );
      }
    },
    primaryBuilder: (ctx) => switch (steg) {
      'tenker' => MegArkButton(label: CusIssueCopy.cus_sak_svar_sekunder, onTap: () {}, av: true),
      'utfall' when issue!.already => MegArkButton(
          key: const Key('cus-sak-legg-til'),
          label: CusIssueCopy.cus_sak_legg_til,
          // Into the write step with the case kept: the next «Send» joins it (C2.8).
          onTap: () => setArk?.call(() {
            append = true;
            steg = 'skriv';
          }),
        ),
      'utfall' => MegArkButton(key: const Key('cus-sak-ferdig'), label: CusIssueCopy.cus_sak_ferdig, onTap: () => Navigator.of(ctx).pop(issue)),
      _ => MegArkButton(key: const Key('cus-sak-send'), label: CusIssueCopy.cus_sak_send, av: sender || (valgt == null && tekst.text.trim().isEmpty && bilde == null), onTap: () => sendFn?.call()),
    },
  );
  tekst.dispose();
  return out ?? issue;
}

CusIssue _medAllerede(CusIssue i) => CusIssue.fromJson({
  'id': i.id, 'order_id': i.orderId, 'order_code': i.orderCode, 'case_ref': i.caseRef, 'type': i.type, 'type_label': i.typeLabel, 'state': i.state, 'outcome': i.outcome,
  'title': i.title, 'sub': i.sub, 'status_text': i.statusText, 'items': i.items, 'amount': i.amountDisplay == null ? null : {'ore': i.amountOre, 'display': i.amountDisplay},
  'sla_minutes': i.slaMinutes, 'answer_by': i.answerBy, 'conversation_id': i.conversationId, 'can_reopen': i.canReopen, 'reopen_count': i.reopenCount, 'already': true,
});

String _eyebrow(CusIssue? i) => switch (i?.outcome) {
  'resolved' => CusIssueCopy.cus_sak_lost,
  'not_delivered' => CusIssueCopy.cus_sak_beklager,
  'approved' || 'denied' => CusIssueCopy.cus_sak_avgjort,
  _ => CusIssueCopy.cus_sak_ser_paa_det,
};

/// Step 1: the chips, the photo, one line. «Send» is the Ark's primary.
class _SakSkriv extends StatelessWidget {
  const _SakSkriv({required this.typer, required this.valgt, required this.bilde, required this.tekst, required this.append, required this.onVelg, required this.onBilde, required this.onFjernBilde, required this.onSend});

  final List<(String, String)> typer;
  final String? valgt;
  final String? bilde;
  final TextEditingController tekst;
  final bool append;
  final void Function(String) onVelg;
  final VoidCallback onBilde, onFjernBilde, onSend;

  @override
  Widget build(BuildContext context) => Column(
    key: const Key('cus-sak-skriv'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(CusIssueCopy.cus_sak_hva_skjedde, style: jakarta(24, em: -.03, color: Colors.white)),
      const SizedBox(height: 4),
      Text(CusIssueCopy.cus_sak_linje, style: inter(12.5, weight: FontWeight.w600, height: 1.4, color: const Color.fromRGBO(255, 255, 255, .7))),
      const SizedBox(height: 14),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (i, t) in typer.indexed)
            AePress(
              key: Key('cus-sak-type-${t.$1}'),
              onTap: () => onVelg(t.$1),
              dy: 0,
              scale: .96,
              child: AeOnce(
                kind: AeInn.chip,
                ms: 450,
                delay: 80 + i * 60.0,
                curve: const Cubic(.3, 1.3, .5, 1),
                child: CssBox(
                  radius: BorderRadius.circular(999),
                  bg: valgt == t.$1
                      ? const [CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1])]
                      : const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, .07)])],
                  shadows: valgt == t.$1
                      ? const [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .45)), CssShadow(0, 3, 0, 0, Color.fromRGBO(160, 60, 20, .55)), CssShadow(0, 10, 18, -8, Color.fromRGBO(242, 109, 61, .8))]
                      : const [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)), CssShadow(0, 12, 20, -14, Color.fromRGBO(4, 18, 26, .8))],
                  border: Border.all(color: Color.fromRGBO(255, 255, 255, valgt == t.$1 ? .4 : .24)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text(t.$2, style: inter(12.5, weight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bilde case final b?)
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(File(b), key: const Key('cus-sak-bilde'), width: 58, height: 58, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 58, height: 58, color: const Color.fromRGBO(255, 255, 255, .12))),
                ),
                Positioned(
                  right: -6,
                  top: -6,
                  child: AePress(
                    key: const Key('cus-sak-bilde-fjern'),
                    onTap: onFjernBilde,
                    dy: 0,
                    scale: .9,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF122F3A), border: Border.all(color: const Color.fromRGBO(255, 255, 255, .4))),
                      child: const Center(child: AeIkon('M7 7l10 10M17 7L7 17', size: 10, stroke: 2.6)),
                    ),
                  ),
                ),
              ],
            )
          else
            AePress(
              key: const Key('cus-sak-ta-bilde'),
              onTap: onBilde,
              dy: 0,
              scale: .96,
              child: Container(
                width: 64,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color.fromRGBO(255, 255, 255, .1),
                  border: Border.all(color: const Color.fromRGBO(255, 255, 255, .22)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AeIkon('M4 8h3l2-3h6l2 3h3v11H4z M12 17a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7z', size: 16, stroke: 2.2),
                    const SizedBox(height: 3),
                    Text(CusIssueCopy.cus_sak_bilde, style: inter(11, weight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color.fromRGBO(0, 0, 0, .22),
                border: Border.all(color: const Color.fromRGBO(255, 255, 255, .18)),
              ),
              alignment: Alignment.centerLeft,
              child: TextField(
                key: const Key('cus-sak-tekst'),
                controller: tekst,
                maxLines: 1,
                maxLength: 600,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: inter(13.5, weight: FontWeight.w600, color: Colors.white),
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: CusIssueCopy.cus_sak_skriv,
                  hintStyle: inter(13.5, weight: FontWeight.w600, color: const Color.fromRGBO(255, 255, 255, .45)),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

/// «Tenker · Ser på bestillingen …» — Ægil's thinking state, no spinner (C2.4).
class _SakTenker extends StatelessWidget {
  const _SakTenker({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 6, 0, 18),
    child: Row(
      children: [
        const AeTenker(),
        const SizedBox(width: 12),
        Expanded(child: Text(CusIssueCopy.cus_sak_ser_paa, style: inter(14, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .85)))),
      ],
    ),
  );
}

/// The outcome card (C2.5–C2.8): the policy engine's answer, the case card,
/// the courier's proof, or the open case.
class _SakUtfall extends StatelessWidget {
  const _SakUtfall({required this.issue, required this.ordre, required this.onSeSaken});

  final CusIssue issue;
  final SupportOrdre ordre;
  final VoidCallback onSeSaken;

  @override
  Widget build(BuildContext context) {
    final i = issue;
    final white = Colors.white;
    final dim = const Color.fromRGBO(255, 255, 255, .72);
    if (i.already) {
      return Column(
        key: const Key('cus-sak-allerede'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF2C14E)),
                child: Text('${i.reopenCount + 1}', style: inter(12, weight: FontWeight.w800, color: const Color(0xFF23201D))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(CusIssueCopy.cus_sak_allerede, style: jakarta(20, em: -.02, color: white))),
            ],
          ),
          const SizedBox(height: 8),
          Text(CusIssueCopy.cus_sak_allerede_linje(i.caseRef, i.answerBy), style: inter(12.5, weight: FontWeight.w600, height: 1.45, color: dim)),
          const SizedBox(height: 12),
          AePress(
            key: const Key('cus-sak-se-saken'),
            onTap: onSeSaken,
            dy: 0,
            scale: .97,
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color.fromRGBO(255, 255, 255, .1), border: Border.all(color: const Color.fromRGBO(255, 255, 255, .24))),
              child: Text(CusIssueCopy.cus_sak_se_saken, style: inter(13, weight: FontWeight.w800, color: white)),
            ),
          ),
        ],
      );
    }
    return Column(
      key: Key('cus-sak-utfall-${i.outcome}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(i.title, style: jakarta(22, em: -.02, height: 1.15, color: white)),
        const SizedBox(height: 6),
        Text(i.sub, style: inter(12.5, weight: FontWeight.w600, height: 1.45, color: dim)),
        if (i.outcome == 'resolved' && i.amountDisplay != null) ...[
          const SizedBox(height: 14),
          // The amount as a sticker (design C2.5: `klask` onto the saldo chip).
          Transform.rotate(
            angle: -.06,
            child: Container(
              key: const Key('cus-sak-sticker'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(colors: [Color(0xFF7FF0CB), Color(0xFF5CE0B8)]),
                boxShadow: const [BoxShadow(color: Color.fromRGBO(92, 224, 184, .5), blurRadius: 14, offset: Offset(0, 6))],
              ),
              child: Text('+${i.amountDisplay}', style: jakarta(16, color: const Color(0xFF0F2B33))),
            ),
          ),
        ],
        if (i.outcome == 'reviewing' || i.outcome == 'reopened') ...[
          const SizedBox(height: 14),
          _Kort(
            key: const Key('cus-sak-kort'),
            dot: const Color(0xFFF2C14E),
            tittel: CusIssueCopy.cus_sak_aapen_kort(i.caseRef),
            under: CusIssueCopy.cus_sak_ordre_naa,
          ),
        ],
        if (i.outcome == 'not_delivered') ...[
          const SizedBox(height: 14),
          _Bevis(proof: i.proof),
        ],
      ],
    );
  }
}

/// The courier's proof card (C2.7): the photo as a thumbnail with the time,
/// «Levert ved døren», «Budets bilde · 18:19 · ved døren».
class _Bevis extends StatelessWidget {
  const _Bevis({required this.proof});

  final CusProof? proof;

  @override
  Widget build(BuildContext context) {
    final p = proof;
    final tid = p?.time ?? '';
    final label = (p?.label ?? '').isEmpty ? 'Levert' : p!.label;
    final url = p?.photoUrl;
    return Container(
      key: const Key('cus-sak-bevis'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, .05)]),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, .16)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: url != null && url.isNotEmpty
                      ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color.fromRGBO(255, 255, 255, .08)))
                      : Container(color: const Color.fromRGBO(255, 255, 255, .08), child: const Center(child: AeIkon('M4 8h3l2-3h6l2 3h3v11H4z M12 17a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7z', size: 18, stroke: 2))),
                ),
                if (tid.isNotEmpty)
                  Positioned(
                    left: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: const Color.fromRGBO(6, 22, 30, .7), borderRadius: BorderRadius.circular(999)),
                      child: Text(tid, style: inter(9.5, weight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: inter(13.5, weight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 2),
                Text(
                  url != null && url.isNotEmpty ? CusIssueCopy.cus_sak_budets_bilde(tid, label) : CusIssueCopy.cus_sak_budets_bevis(tid, label),
                  style: inter(11.5, weight: FontWeight.w600, height: 1.35, color: const Color.fromRGBO(255, 255, 255, .62)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A small case card inside the Ark («Sak Æ-42K-1 er åpen · Ordre · nå»).
class _Kort extends StatelessWidget {
  const _Kort({super.key, required this.dot, required this.tittel, required this.under});

  final Color dot;
  final String tittel, under;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, .05)]),
      border: Border.all(color: const Color.fromRGBO(255, 255, 255, .16)),
    ),
    child: Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: dot, boxShadow: [BoxShadow(color: dot, blurRadius: 8 / 2 / .57735)])),
        const SizedBox(width: 8),
        Expanded(child: Text(tittel, style: inter(13, weight: FontWeight.w800, color: Colors.white))),
        Text(under, style: inter(11, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .62))),
      ],
    ),
  );
}

/// The case row on a delivered order (C2.1 «Sak», refunds spec §2.4): the
/// dot, the status line, when; the person's answer; «Ikke løst» while it can
/// be reopened. Replaces [SakPaaOrdren] once an issue exists on the order.
class IssueSakRad extends StatelessWidget {
  const IssueSakRad({super.key, required this.issue, this.onIkkeLost});

  final CusIssue issue;
  final VoidCallback? onIkkeLost;

  @override
  Widget build(BuildContext context) {
    final i = issue;
    final at = i.resolvedAt ?? i.createdAt;
    final naar = at == null || DateTime.now().difference(at).inMinutes < 60 ? CusIssueCopy.cus_sak_naa : '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
    final dot = switch (i.outcome) {
      'resolved' || 'approved' => const Color(0xFF5CE0B8),
      'denied' => const Color(0xFFF26D3D),
      _ => const Color(0xFFF2C14E),
    };
    return Container(
      key: const Key('oh-sak'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: dot, boxShadow: [BoxShadow(color: dot, blurRadius: 8 / 2 / .57735)])),
              const SizedBox(width: 8),
              Expanded(child: Text(i.statusText, key: const Key('oh-sak-status'), style: inter(13.5, weight: FontWeight.w800, color: Colors.white))),
              Text(naar, style: inter(11.5, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .62))),
            ],
          ),
          const SizedBox(height: 4),
          Text('${CusIssueCopy.cus_sak_rad.replaceAll('?', '')} · ${i.caseRef}', style: inter(11.5, weight: FontWeight.w600, color: const Color.fromRGBO(255, 255, 255, .55))),
          if (i.reply case final r?) ...[
            const SizedBox(height: 8),
            Text.rich(
              key: const Key('oh-sak-svar'),
              TextSpan(
                style: inter(12.5, weight: FontWeight.w600, height: 1.45, color: const Color.fromRGBO(255, 255, 255, .8)),
                children: [
                  TextSpan(text: '${CusIssueCopy.cus_sak_svar_fra(r.by)}: ', style: inter(12.5, weight: FontWeight.w800, height: 1.45, color: Colors.white)),
                  TextSpan(text: r.text),
                ],
              ),
            ),
          ],
          if (i.canReopen && onIkkeLost != null) ...[
            const SizedBox(height: 10),
            AePress(
              key: const Key('oh-sak-ikke-lost'),
              onTap: onIkkeLost,
              dy: 0,
              scale: .97,
              child: Container(
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color.fromRGBO(255, 255, 255, .1),
                  border: Border.all(color: const Color.fromRGBO(255, 255, 255, .24)),
                ),
                child: Text(CusIssueCopy.cus_sak_ikke_lost, style: inter(12.5, weight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
