// ignore_for_file: non_constant_identifier_names
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../networking/ops/cus_api.dart';
import '../../../utils/utils.dart' show isLoggedIn;
import '../../common/auth/launch/lf_css.dart';
import '../aegil/aegil_bits.dart';
import '../hjem/hjem_harness.dart';
import '../kit/bergen_kit.dart';
import '../meg/meg_ark.dart';
import '../meg/mork_rad.dart';
import 'ai_bekreft.dart';
import 'ai_bits.dart';
import 'ai_copy.dart';
import 'ai_overlays.dart';
import 'ai_store.dart';
import 'ai_tilbud.dart';

/// Customer plan Step 14 — the AI sheets of design 10140–10325 / 21549–21672
/// on the dark Ark: `aiInngang`, `aiVelg`, `aiQr`, `aiSamtykke`, `aiKoblet`,
/// `aiKoblede`, `aiDetalj`, `aiKobleFra`, `aiFeil`. Every sheet answers with
/// the next step (a string), and [flyt] walks the chain: Meg → inngang →
/// samtykke (the choices ride on the code, D-K15) → qr (the assistant uses
/// the code; the app polls the link) → koblet → koblede ↔ detalj → kobleFra.
abstract final class AiArk {
  static AiStore get _store => AiStore.instance;
  static CusApi get _api => _store.api;

  /// Walk the sheets from [start] until one closes without a next step.
  static Future<void> flyt(BuildContext context, String start, {String navn = 'Claude', CusAiPrefs? prefs, bool fraHurtig = false}) async {
    var neste = start;
    var n = navn;
    var p = prefs ?? const CusAiPrefs();
    while (neste.isNotEmpty && context.mounted) {
      final deler = neste.split(':');
      final type = deler.first;
      final arg = deler.length > 1 ? deler.sublist(1).join(':') : '';
      if (arg.isNotEmpty && AiNavn.alle.contains(arg)) n = arg;
      String? svar;
      switch (type) {
        case 'inngang':
          svar = await inngang(context, navn: n);
        case 'velg':
          svar = await velg(context);
        case 'samtykke':
          final r = await samtykke(context, n, prefs: p, gjest: !isLoggedIn());
          if (r is CusAiPrefs) {
            p = r;
            svar = 'qr:$n';
          } else {
            svar = r as String?;
          }
        case 'qr':
        case 'qrAnnen':
          svar = await qr(context, n, prefs: p, modus: type == 'qrAnnen' ? 'qr' : 'mobil');
        case 'koblet':
          svar = await koblet(context, _store.linkFor(n) ?? AiStore.harnessLink(n), fraHurtig: fraHurtig);
        case 'koblede':
          svar = await koblede(context);
        case 'detalj':
          final l = int.tryParse(arg) != null ? _store.alle.where((x) => x.id == int.parse(arg)).firstOrNull : _store.linkFor(n);
          svar = await detalj(context, l, navn: l?.name ?? n);
        case 'kobleFra':
          final l = int.tryParse(arg) != null ? _store.alle.where((x) => x.id == int.parse(arg)).firstOrNull : _store.linkFor(n);
          svar = await kobleFra(context, link: l, navn: l?.name ?? n);
        case 'kobleFraAlle':
          svar = await kobleFra(context, alle: true);
        case 'feil':
          svar = await feil(context, arg.isEmpty ? 'generisk' : arg, n);
        case 'bestill':
          await AiOverlays.bytt(context, n, kurv: true);
          svar = null;
        case 'logg':
          svar = null;
        default:
          svar = null;
      }
      neste = svar ?? '';
    }
  }

  /// Debug: open the harness state (`ai`) from Meg (`HjemHarness.ai`).
  static Future<void> harness(BuildContext context) async {
    final s = HjemHarness.ai;
    if (s == null) return;
    HjemHarness.ai = null;
    final n = HjemHarness.aiNavn ?? 'Claude';
    await _store.load();
    if (!context.mounted) return;
    switch (s) {
      case 'inngang': return flyt(context, 'inngang', navn: n);
      case 'velg': return flyt(context, 'velg', navn: n);
      case 'qr': return flyt(context, 'qr', navn: n);
      case 'qrAnnen': return flyt(context, 'qrAnnen', navn: n);
      case 'qrKopiert': return flyt(context, 'qr', navn: n);
      case 'samtykke': return flyt(context, 'samtykke', navn: n);
      case 'samtykkeGjest': await samtykke(context, n, gjest: true); return;
      case 'koblet': return flyt(context, 'koblet', navn: n);
      case 'koblede': return flyt(context, 'koblede', navn: n);
      case 'detalj': return flyt(context, 'detalj', navn: n);
      case 'kobleFra': return flyt(context, 'kobleFra', navn: n);
      case 'kobleFraAlle': return flyt(context, 'kobleFraAlle', navn: n);
      case 'feilIkkeKoblet': return flyt(context, 'feil:ikkeKoblet', navn: n);
      case 'feilBekreft': return flyt(context, 'feil:bekreft', navn: n);
      case 'feilGenerisk': return flyt(context, 'feil:generisk', navn: n);
      case 'bytt': return AiOverlays.bytt(context, n, apne: false, ut: const Duration(seconds: 3), inn: const Duration(seconds: 3));
      case 'byttKurv': return AiOverlays.bytt(context, n, kurv: true, apne: false, ut: const Duration(seconds: 3), inn: const Duration(seconds: 3));
      case 'push': AiOverlays.push(context, aiSampleRequest(navn: n), hide: const Duration(seconds: 20)); return;
      case 'bekreft': return AiBekreft.vis(context, aiSampleRequest(navn: n), harness: true);
      case 'bekreftOver': return AiBekreft.vis(context, aiSampleRequest(navn: n, over: true), tilstand: 'over', harness: true);
      case 'bekreftFeilet': return AiBekreft.vis(context, aiSampleRequest(navn: n), tilstand: 'feilet', harness: true);
      case 'bekreftUtlopt': return AiBekreft.vis(context, aiSampleRequest(navn: n, state: 'utlopt'), tilstand: 'utlopt', harness: true);
      case 'bekreftTrukket': return AiBekreft.vis(context, aiSampleRequest(navn: n), tilstand: 'trukket', harness: true);
      case 'faceid': return AiBekreft.vis(context, aiSampleRequest(navn: n), tilstand: 'faceid', harness: true);
      case 'vipps': return AiBekreft.vis(context, aiSampleRequest(navn: n), tilstand: 'vipps', harness: true);
    }
  }

  // ── aiInngang ────────────────────────────────────────────────────────────

  static Future<String?> inngang(BuildContext context, {String navn = 'Claude'}) async {
    var valgt = navn;
    var stegN = 0;
    final snarveier = <String>{};
    return showMegArk<String>(
      context,
      key: const Key('cus-ai-inngang'),
      mork: true,
      title: AiCopy.cus_ai_inngang_tittel,
      subtitle: AiCopy.cus_ai_inngang_linje,
      body: (ctx, setState) {
        final siri = valgt == 'Siri';
        final link = _store.aktivFor(valgt);
        final steg = siri ? AiCopy.cus_ai_steg_siri : AiCopy.cus_ai_steg(valgt);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AiKort(child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.asset('assets/images/dashboard/front.png', width: 46, height: 46, fit: BoxFit.cover)),
            const SizedBox(width: 10),
            Expanded(child: Text(AiCopy.cus_ai_inngang_aegil, style: inter(12.5, height: 1.4, color: const Color.fromRGBO(255, 255, 255, .85)))),
          ])),
          AiSeksjon(AiCopy.cus_ai_stottede),
          Row(children: [
            for (final n in AiNavn.alle) ...[
              Expanded(child: AePress(
                onTap: () => setState(() { valgt = n; stegN = 0; }),
                dy: 1.5,
                child: AnimatedContainer(
                  key: Key('cus-ai-chip-${AiNavn.vendor(n)}'),
                  duration: const Duration(milliseconds: 220),
                  transform: Matrix4.translationValues(0, valgt == n ? -4 : 0, 0),
                  padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: valgt == n ? const [Color.fromRGBO(92, 224, 184, .28), Color.fromRGBO(92, 224, 184, .08)] : const [Color.fromRGBO(255, 255, 255, .12), Color.fromRGBO(255, 255, 255, .04)]),
                    border: Border.all(color: valgt == n ? const Color.fromRGBO(127, 240, 203, .85) : const Color.fromRGBO(255, 255, 255, .14)),
                    boxShadow: valgt == n ? const [BoxShadow(color: Color.fromRGBO(92, 224, 184, .75), blurRadius: 24 / 2 / .57735, spreadRadius: -6)] : null,
                  ),
                  child: Column(children: [
                    AiMerke(n, size: 34),
                    const SizedBox(height: 6),
                    Text(n, style: inter(11.5, weight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      if (_store.aktivFor(n) != null) Container(width: 5, height: 5, margin: const EdgeInsets.only(right: 4), decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF7FF0CB))),
                      Flexible(child: Text(_store.aktivFor(n) != null ? AiCopy.cus_ai_koblet : (n == 'Siri' ? AiCopy.cus_ai_snarveier : AiCopy.cus_ai_ikke_koblet), maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(9.5, weight: FontWeight.w700, color: _store.aktivFor(n) != null ? const Color(0xFF7FF0CB) : const Color.fromRGBO(255, 255, 255, .55)))),
                    ]),
                  ]),
                ),
              )),
              if (n != AiNavn.alle.last) const SizedBox(width: 6),
            ],
          ]),
          if (link != null) ...[
            const SizedBox(height: 10),
            AePress(onTap: () => Navigator.of(ctx).pop('detalj:${link.id}'), dy: 1.5, child: AiKort(mint: true, padding: const EdgeInsets.fromLTRB(12, 10, 12, 10), child: Row(children: [
              const AeIkon(AiIk.kobling, size: 16, stroke: 2.3, color: Color(0xFF7FF0CB)),
              const SizedBox(width: 8),
              Expanded(child: Text(AiCopy.cus_ai_allerede_koblet(valgt), style: inter(13, weight: FontWeight.w800))),
              Text(AiCopy.cus_ai_se_rettigheter, style: inter(12, weight: FontWeight.w800, color: const Color(0xFF7FF0CB))),
              const SizedBox(width: 4),
              const AeIkon(AiIk.pil, size: 12, stroke: 2.4, color: Color(0xFF7FF0CB)),
            ]))),
          ],
          AiSeksjon(AiCopy.cus_ai_slik_fungerer),
          AiKort(child: Row(children: [
            for (final (i, t) in [AiCopy.cus_ai_fl1(valgt), AiCopy.cus_ai_fl2, AiCopy.cus_ai_fl3].indexed) ...[
              Expanded(child: Column(children: [
                Container(width: 30, height: 30, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: i == 2 ? const Color(0xFF5CE0B8) : const Color.fromRGBO(255, 255, 255, .12)), child: AeIkon([AiIk.person, AiIk.pose, AiIk.skjold][i], size: 14, stroke: 2.3, color: i == 2 ? const Color(0xFF0F2B33) : Colors.white)),
                const SizedBox(height: 6),
                Text(t, textAlign: TextAlign.center, style: inter(11, weight: FontWeight.w700, height: 1.3)),
              ])),
              if (i < 2) const SizedBox(width: 18, child: Divider(color: Color.fromRGBO(255, 255, 255, .25), thickness: 1.5)),
            ],
          ])),
          AiSeksjon(AiCopy.cus_ai_steg_tittel(valgt)),
          for (final (i, s) in steg.indexed)
            AePress(
              onTap: () => setState(() {
                stegN = i + 1 > stegN ? i + 1 : i;
                if (stegN == steg.length) showBergenToast(ctx, AiCopy.cus_ai_klart);
              }),
              dy: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 28, height: 28, alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: i < stegN ? const LinearGradient(colors: [Color(0xFFB4F9E2), Color(0xFF5CE0B8)]) : (i == stegN ? const LinearGradient(colors: [Color(0xFFF9A273), Color(0xFFF26D3D)]) : null), color: i > stegN ? const Color.fromRGBO(255, 255, 255, .1) : null),
                    child: i < stegN ? const AeIkon(AiIk.hake, size: 13, stroke: 3, color: Color(0xFF0F2B33)) : Text('${i + 1}', style: inter(12, weight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s, style: inter(13, weight: i <= stegN ? FontWeight.w800 : FontWeight.w600, height: 1.35, color: i <= stegN ? Colors.white : const Color.fromRGBO(255, 255, 255, .6))),
                    if (i == stegN) Text(i == steg.length - 1 ? AiCopy.cus_ai_steg_hint_sist : AiCopy.cus_ai_steg_hint, style: inter(11, color: const Color(0xFFFFC8A8))),
                  ])),
                ]),
              ),
            ),
          AiSeksjon(AiCopy.cus_ai_hva_ser(valgt)),
          AiKort(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AiCopy.cus_ai_kan_se, style: inter(11, weight: FontWeight.w800, em: .08, color: const Color(0xFF7FF0CB))),
              for (final t in AiCopy.cus_ai_kan_se_liste) Padding(padding: const EdgeInsets.only(top: 6), child: Row(children: [const AeIkon(AiIk.hake, size: 12, stroke: 2.6, color: Color(0xFF7FF0CB)), const SizedBox(width: 6), Expanded(child: Text(t, style: inter(12.5, weight: FontWeight.w700)))])),
            ])),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AiCopy.cus_ai_ser_aldri, style: inter(11, weight: FontWeight.w800, em: .08, color: const Color(0xFFFFC8A8))),
              for (final t in AiCopy.cus_ai_ser_aldri_liste) Padding(padding: const EdgeInsets.only(top: 6), child: Row(children: [const AeIkon(AiIk.kryss, size: 12, stroke: 2.6, color: Color(0xFFFFC8A8)), const SizedBox(width: 6), Expanded(child: Text(t, style: inter(12.5, weight: FontWeight.w700)))])),
            ])),
          ])),
          Padding(padding: const EdgeInsets.fromLTRB(4, 8, 4, 0), child: AePress(onTap: () => launchUrl(Uri.parse('https://aerend.no/terms-and-conditions'), mode: LaunchMode.externalApplication), dy: 1, child: Row(children: [Text(AiCopy.cus_ai_les_mer, style: inter(12.5, weight: FontWeight.w800, color: const Color(0xFF7FF0CB))), const SizedBox(width: 4), const AeIkon(AiIk.pil, size: 11, stroke: 2.4, color: Color(0xFF7FF0CB))]))),
          const SizedBox(height: 12),
          AiKort(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const AiMerke('Siri', size: 36),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AiCopy.cus_ai_bruk_siri, style: inter(13.5, weight: FontWeight.w800)), Text(AiCopy.cus_ai_siri_linje, style: inter(11.5, height: 1.35, color: const Color.fromRGBO(255, 255, 255, .75)))])),
            ]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Flexible(child: Text(AiCopy.cus_ai_snarveier, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(11, weight: FontWeight.w800, em: .08, color: const Color.fromRGBO(255, 255, 255, .6)))), const SizedBox(width: 8), Flexible(child: Text(AiCopy.cus_ai_siri_antall(snarveier.length), maxLines: 1, textAlign: TextAlign.right, style: inter(11, weight: FontWeight.w700, color: const Color(0xFF7FF0CB))))]),
            for (final s in AiCopy.cus_ai_siri_snarveier)
              AePress(
                onTap: () => setState(() { snarveier.contains(s) ? snarveier.remove(s) : snarveier.add(s); showBergenToast(ctx, snarveier.contains(s) ? AiCopy.cus_ai_snarvei_lagt(s) : AiCopy.cus_ai_snarvei_fjernet); }),
                dy: 1,
                child: Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: snarveier.contains(s) ? const Color.fromRGBO(92, 224, 184, .18) : const Color.fromRGBO(255, 255, 255, .07), border: Border.all(color: snarveier.contains(s) ? const Color.fromRGBO(127, 240, 203, .6) : const Color.fromRGBO(255, 255, 255, .16))),
                  child: Row(children: [const AeIkon(AiIk.lyn, size: 13, stroke: 2.4, color: Color(0xFFF2C14E)), const SizedBox(width: 8), Expanded(child: Text('«$s»', style: inter(12.5, weight: FontWeight.w700))), AeIkon(snarveier.contains(s) ? AiIk.hake : AiIk.pluss, size: 13, stroke: 2.6, color: snarveier.contains(s) ? const Color(0xFF7FF0CB) : Colors.white)]),
                ),
              ),
          ])),
        ]);
      },
      primaryBuilder: (ctx) => MegArkButton(
        key: const Key('cus-ai-inngang-cta'),
        label: valgt == 'Siri' ? AiCopy.cus_ai_siri_alle : AiCopy.cus_ai_koble_til(valgt),
        onTap: () {
          if (valgt == 'Siri') {
            showBergenToast(ctx, AiCopy.cus_ai_siri_lagt);
            launchUrl(Uri.parse('shortcuts://'), mode: LaunchMode.externalApplication).catchError((_) => false);
            return;
          }
          Navigator.of(ctx).pop('samtykke:$valgt');
        },
      ),
      secondary: MegArkButton(key: const Key('cus-ai-inngang-qr'), label: AiCopy.cus_ai_vis_qr, onTap: () => Navigator.of(context).pop('qrAnnen:$valgt')),
    );
  }

  // ── aiVelg ───────────────────────────────────────────────────────────────

  static Future<String?> velg(BuildContext context) async {
    final forste = _store.aktive.where((l) => l.vendor != 'siri').firstOrNull;
    return showMegArk<String>(
      context,
      key: const Key('cus-ai-velg'),
      mork: true,
      title: AiCopy.cus_ai_velg_tittel,
      subtitle: AiCopy.cus_ai_velg_linje,
      body: (ctx, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final (i, n) in AiNavn.alle.indexed) ...[
          () {
            final l = _store.aktivFor(n);
            final ak = l != null;
            final siri = n == 'Siri';
            return AeOnce(kind: AeInn.stigOpp, ms: 420, delay: 60.0 + i * 60, child: AePress(
              onTap: () => Navigator.of(ctx).pop(ak ? 'bestill:$n' : (siri ? 'inngang:Siri' : 'samtykke:$n')),
              dy: 1.5,
              child: Container(
                key: Key('cus-ai-velg-${AiNavn.vendor(n)}'),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: ak ? const [Color.fromRGBO(92, 224, 184, .16), Color.fromRGBO(255, 255, 255, .05)] : const [Color.fromRGBO(255, 255, 255, .12), Color.fromRGBO(255, 255, 255, .04)]), border: Border.all(color: ak ? const Color.fromRGBO(127, 240, 203, .45) : const Color.fromRGBO(255, 255, 255, .14))),
                child: Row(children: [
                  AiMerke(n, size: 40),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Flexible(child: Text(n, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(14, weight: FontWeight.w800))), const SizedBox(width: 8), Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: _status(ak ? AiCopy.cus_ai_koblet : (siri ? AiCopy.cus_ai_snarvei : AiCopy.cus_ai_ikke_koblet), ak)))]),
                    const SizedBox(height: 2),
                    Text(ak ? AiCopy.cus_ai_velg_koblet_under(l.capPerOrder?.kr ?? 0, _betNavn(l.paymentPref)) : (siri ? AiCopy.cus_ai_velg_siri_under : AiCopy.cus_ai_velg_ukoblet_under), style: inter(11.5, color: const Color.fromRGBO(255, 255, 255, .7))),
                  ])),
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), gradient: ak ? const LinearGradient(colors: [Color(0xFFF9A273), Color(0xFFF26D3D)]) : null, color: ak ? null : const Color.fromRGBO(255, 255, 255, .1), border: ak ? null : Border.all(color: const Color.fromRGBO(255, 255, 255, .2))), child: Text(ak ? AiCopy.cus_ai_bestill : (siri ? AiCopy.cus_ai_legg_til : AiCopy.cus_ai_koble), style: inter(12, weight: FontWeight.w800))),
                ]),
              ),
            ));
          }(),
        ],
        const SizedBox(height: 6),
        Row(children: [
          for (final (i, t) in AiCopy.cus_ai_velg_steg.indexed) ...[
            Expanded(child: Column(children: [AeIkon([AiIk.person, AiIk.pose, AiIk.skjold][i], size: 16, stroke: 2.2, color: const Color(0xFF7FF0CB)), const SizedBox(height: 4), Text(t, textAlign: TextAlign.center, style: inter(11, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .75)))])),
          ],
        ]),
      ]),
      primary: forste == null ? null : MegArkButton(key: const Key('cus-ai-velg-cta'), label: AiCopy.cus_ai_bestill_med(forste.name), onTap: () => Navigator.of(context).pop('bestill:${forste.name}')),
      secondary: MegArkButton(label: AiCopy.cus_ai_lukk, onTap: () => Navigator.of(context).pop()),
    );
  }

  static Widget _status(String tx, bool ak) => Container(padding: const EdgeInsets.fromLTRB(7, 2, 8, 2), decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: ak ? const Color.fromRGBO(92, 224, 184, .16) : const Color.fromRGBO(255, 255, 255, .08), border: Border.all(color: ak ? const Color.fromRGBO(127, 240, 203, .5) : const Color.fromRGBO(255, 255, 255, .18))), child: Row(mainAxisSize: MainAxisSize.min, children: [if (ak) Container(width: 5, height: 5, margin: const EdgeInsets.only(right: 4), decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF7FF0CB))), Text(tx, style: inter(10.5, weight: FontWeight.w800, color: ak ? const Color(0xFF7FF0CB) : const Color.fromRGBO(255, 255, 255, .6)))]));

  static String _betNavn(String pref) => switch (pref) { 'card' => AiCopy.cus_ai_lagret_kort, 'ask' => AiCopy.cus_ai_spor_hver_gang, _ => AiCopy.cus_ai_vipps };

  // ── aiQr ─────────────────────────────────────────────────────────────────

  static Future<String?> qr(BuildContext context, String navn, {CusAiPrefs? prefs, String modus = 'mobil'}) async {
    var m = modus;
    CusAiKode? kode;
    var kopiert = HjemHarness.ai == null && kDebugModeHarness('qrKopiert');
    var venter = kopiert;
    Timer? poll;
    var lukket = false;
    Future<void> hent(void Function(void Function()) setState) async {
      if (_store.harness) {
        kode = CusAiKode(code: 'ÆR-7K2Q', raw: '7K2Q', status: 'pending', expiresAt: DateTime.now().add(const Duration(minutes: 10)), linkUrl: 'https://aerend.no/koble/7k2q');
      } else {
        kode = await _api.aiLinkCode(clientId: AiNavn.clientId(navn), prefs: prefs);
      }
      if (!lukket) setState(() {});
    }
    return showMegArk<String>(
      context,
      key: const Key('cus-ai-qr'),
      mork: true,
      title: AiCopy.cus_ai_qr_tittel(navn),
      titleBuilder: () => AiCopy.cus_ai_qr_tittel(navn),
      subtitleBuilder: () => m == 'mobil' ? AiCopy.cus_ai_qr_linje_mobil(navn) : AiCopy.cus_ai_qr_linje_qr(navn),
      body: (ctx, setState) {
        if (kode == null && !lukket) {
          kode = const CusAiKode(code: '', raw: '', status: 'pending');
          unawaited(hent(setState));
          poll ??= Timer.periodic(const Duration(seconds: 3), (_) async {
            final k = kode;
            if (lukket || k == null || k.raw.isEmpty || _store.harness) return;
            final st = await _api.aiLinkCodeStatus(k.raw);
            if (lukket || st == null) return;
            if (st.status == 'linked') {
              lukket = true;
              poll?.cancel();
              await _store.load(force: true);
              if (ctx.mounted) {
                showBergenToast(ctx, AiCopy.cus_ai_brukte_koden(navn));
                Navigator.of(ctx).pop('koblet:$navn');
              }
            } else if (st.status == 'expired') {
              setState(() { kode = null; venter = false; kopiert = false; });
              showBergenToast(ctx, AiCopy.cus_ai_kode_utlopt);
            }
          });
        }
        final k = kode ?? const CusAiKode(code: '', raw: '', status: 'pending');
        final tegn = k.raw.isEmpty ? ['·', '·', '·', '·'] : k.raw.split('');
        final steg = m == 'mobil' ? AiCopy.cus_ai_qr_steg_mobil(navn) : AiCopy.cus_ai_qr_steg_qr(navn);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color.fromRGBO(255, 255, 255, .08), border: Border.all(color: const Color.fromRGBO(255, 255, 255, .14))),
            child: Row(children: [
              for (final (v, t, ik) in [('mobil', AiCopy.cus_ai_paa_mobilen, AiIk.mobil), ('qr', AiCopy.cus_ai_annen_enhet, AiIk.qr)])
                Expanded(child: AePress(onTap: () => setState(() => m = v), dy: 1, child: Container(key: Key('cus-ai-qr-modus-$v'), height: 36, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), gradient: m == v ? const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFE6F2EF)]) : null), child: FittedBox(fit: BoxFit.scaleDown, child: Row(mainAxisSize: MainAxisSize.min, children: [AeIkon(ik, size: 13, stroke: 2.3, color: m == v ? const Color(0xFF1E4F5C) : const Color.fromRGBO(255, 255, 255, .78)), const SizedBox(width: 6), Text(t, style: inter(12.5, weight: FontWeight.w800, color: m == v ? const Color(0xFF1E4F5C) : const Color.fromRGBO(255, 255, 255, .78)))]))))),
            ]),
          ),
          const SizedBox(height: 12),
          if (m == 'mobil') ...[
            AiKort(mint: true, child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Column(children: [Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), gradient: const LinearGradient(colors: [Color(0xFFF58A55), Color(0xFFE95C2C)])), child: Text('Æ', style: jakarta(20, weight: FontWeight.w800, color: const Color(0xFF23201D)))), const SizedBox(height: 4), Text('Ærend', style: inter(11, weight: FontWeight.w800))]),
                const SizedBox(width: 14), const AeIkon('M5 12h14M13 6l6 6-6 6', size: 18, stroke: 2.4, color: Color(0xFF7FF0CB)), const SizedBox(width: 14),
                Column(children: [AiMerke(navn, size: 44), const SizedBox(height: 4), Text(navn, style: inter(11, weight: FontWeight.w800))]),
              ]),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [const AeIkon(AiIk.mobil, size: 12, stroke: 2.3, color: Color(0xFF7FF0CB)), const SizedBox(width: 6), Flexible(child: Text(AiCopy.cus_ai_begge_appene, maxLines: 2, textAlign: TextAlign.center, style: inter(11.5, weight: FontWeight.w700, color: const Color(0xFF7FF0CB))))]),
            ])),
            const SizedBox(height: 10),
            AiKort(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF5CE0B8))), const SizedBox(width: 7), Expanded(child: Text(AiCopy.cus_ai_eller_kode.toUpperCase(), style: inter(11, weight: FontWeight.w800, em: .1, color: const Color(0xFF7FF0CB)))), const AeIkon(AiIk.klokke, size: 11, stroke: 2.4, color: Color.fromRGBO(255, 255, 255, .6)), const SizedBox(width: 4), Text(AiCopy.cus_ai_gyldig_min(k.minutes), style: inter(11, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .6)))]),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('ÆR', style: jakarta(26, weight: FontWeight.w800, em: .06)), Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text('–', style: jakarta(26, weight: FontWeight.w800, color: const Color.fromRGBO(255, 255, 255, .5)))),
                for (final (i, c) in tegn.indexed) AeOnce(kind: AeInn.stigOpp, ms: 400, delay: 180.0 + i * 70, child: Container(key: Key('cus-ai-kode-$i'), width: 40, height: 48, margin: const EdgeInsets.symmetric(horizontal: 3), alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color.fromRGBO(0, 0, 0, .25), border: Border.all(color: const Color.fromRGBO(255, 255, 255, .22))), child: Text(c, style: jakarta(24, weight: FontWeight.w800)))),
              ]),
              const SizedBox(height: 10),
              Text(AiCopy.cus_ai_lim_inn(navn), textAlign: TextAlign.center, style: inter(12, height: 1.4, color: const Color.fromRGBO(255, 255, 255, .75))),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(flex: 3, child: AePress(
                  onTap: () async {
                    if (k.code.isEmpty) return;
                    setState(() { kopiert = true; venter = true; });
                    try {
                      await Clipboard.setData(ClipboardData(text: k.code));
                    } catch (_) {}
                    if (ctx.mounted) showBergenToast(ctx, AiCopy.cus_ai_kode_kopiert(k.code, navn));
                  },
                  dy: 1.5,
                  child: Container(key: const Key('cus-ai-kopier-kode'), height: 40, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), gradient: kopiert ? const LinearGradient(colors: [Color(0xFFB4F9E2), Color(0xFF5CE0B8)]) : const LinearGradient(colors: [Color(0xFFF9A273), Color(0xFFF26D3D)])), child: Row(mainAxisSize: MainAxisSize.min, children: [AeIkon(kopiert ? AiIk.hake : AiIk.kopier, size: 13, stroke: 2.6, color: kopiert ? const Color(0xFF0F2B33) : Colors.white), const SizedBox(width: 6), Text(kopiert ? AiCopy.cus_ai_kopiert : AiCopy.cus_ai_kopier_kode, style: inter(13, weight: FontWeight.w800, color: kopiert ? const Color(0xFF0F2B33) : Colors.white))])),
                )),
                const SizedBox(width: 8),
                Flexible(flex: 2, child: AePress(
                  onTap: () async {
                    if (k.linkUrl == null) return;
                    try {
                      await Clipboard.setData(ClipboardData(text: k.linkUrl!));
                    } catch (_) {}
                    if (ctx.mounted) showBergenToast(ctx, AiCopy.cus_ai_lenke_kopiert(navn));
                  },
                  dy: 1.5,
                  child: Container(key: const Key('cus-ai-kopier-lenke'), height: 40, padding: const EdgeInsets.symmetric(horizontal: 12), alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color.fromRGBO(255, 255, 255, .1), border: Border.all(color: const Color.fromRGBO(255, 255, 255, .2))), child: Row(mainAxisSize: MainAxisSize.min, children: [const AeIkon(AiIk.kobling, size: 13, stroke: 2.4), const SizedBox(width: 6), Flexible(child: Text((k.linkUrl ?? '').replaceFirst(RegExp(r'^https?://'), ''), maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(12, weight: FontWeight.w700)))])),
                )),
              ]),
              if (venter) ...[
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7FF0CB))), const SizedBox(width: 8), Flexible(child: Text(AiCopy.cus_ai_venter(navn), key: const Key('cus-ai-venter'), maxLines: 2, style: inter(12, weight: FontWeight.w700, color: const Color(0xFF7FF0CB))))]),
              ],
            ])),
          ] else ...[
            Center(child: Container(
              key: const Key('cus-ai-qr-bilde'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: Colors.white, boxShadow: const [BoxShadow(color: Color.fromRGBO(4, 18, 26, .6), offset: Offset(0, 14), blurRadius: 28 / 2 / .57735, spreadRadius: -10)]),
              child: k.linkUrl == null ? const SizedBox(width: 196, height: 196, child: Center(child: CircularProgressIndicator(color: Color(0xFF1E4F5C)))) : QrImageView(data: k.linkUrl!, size: 196, backgroundColor: Colors.white, eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0B1014)), dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF0B1014))),
            )),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [const AeIkon(AiIk.klokke, size: 12, stroke: 2.3, color: Color.fromRGBO(255, 255, 255, .7)), const SizedBox(width: 6), Flexible(child: Text(AiCopy.cus_ai_kode_for(navn, k.minutes), maxLines: 2, textAlign: TextAlign.center, style: inter(12, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .7))))]),
            if (k.code.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(k.code, textAlign: TextAlign.center, style: jakarta(18, weight: FontWeight.w800, em: .08))),
          ],
          const SizedBox(height: 12),
          for (final (i, s) in steg.indexed)
            AeOnce(kind: AeInn.stigOpp, ms: 400, delay: 250.0 + i * 80, child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Container(width: 22, height: 22, alignment: Alignment.center, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(255, 255, 255, .12)), child: Text('${i + 1}', style: inter(11, weight: FontWeight.w800))), const SizedBox(width: 10), Expanded(child: Text(s, style: inter(13, weight: FontWeight.w700)))]))),
        ]);
      },
      primaryBuilder: (ctx) => MegArkButton(
        key: const Key('cus-ai-qr-cta'),
        label: m == 'mobil' ? AiCopy.cus_ai_apne(navn) : AiCopy.cus_ai_jeg_har_skannet,
        onTap: () async {
          if (m == 'mobil') {
            await AiOverlays.bytt(ctx, navn, apne: !_store.harness);
            return;
          }
          final k = kode;
          if (k == null || k.raw.isEmpty || _store.harness) return;
          final st = await _api.aiLinkCodeStatus(k.raw);
          if (!ctx.mounted) return;
          if (st?.status == 'linked') {
            lukket = true;
            poll?.cancel();
            await _store.load(force: true);
            if (ctx.mounted) Navigator.of(ctx).pop('koblet:$navn');
          } else {
            showBergenToast(ctx, AiCopy.cus_ai_venter(navn));
          }
        },
      ),
      secondary: MegArkButton(key: const Key('cus-ai-qr-tilbake'), label: AiCopy.cus_ai_tilbake, onTap: () => Navigator.of(context).pop('inngang:$navn')),
    ).whenComplete(() {
      lukket = true;
      poll?.cancel();
    });
  }

  static bool kDebugModeHarness(String state) => HjemHarness.aiStart != null && _harnessState == state;
  static String? _harnessState;

  /// The harness state the next sheet should open in (set by [harness] before the flow).
  static set harnessState(String? s) => _harnessState = s;

  // ── aiSamtykke (and «Logg inn først») ────────────────────────────────────

  /// Returns the chosen [CusAiPrefs] on «Koble til», `'logg'` on «Logg inn», null on «Avbryt».
  static Future<Object?> samtykke(BuildContext context, String navn, {CusAiPrefs? prefs, bool gjest = false, String? adresse}) async {
    if (gjest) {
      return showMegArk<String>(
        context,
        key: const Key('cus-ai-logg'),
        mork: true,
        title: AiCopy.cus_ai_logg_tittel,
        subtitle: AiCopy.cus_ai_logg_linje,
        body: (ctx, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AiHandshake(modus: 'ukoblet', navn: navn, linje: AiCopy.cus_ai_logg_inn_forst),
          AiKort(child: Column(children: [
            Container(width: 44, height: 44, alignment: Alignment.center, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(255, 255, 255, .1)), child: const AeIkon(AiIk.laas, size: 20, stroke: 2.2)),
            const SizedBox(height: 8),
            Text(AiCopy.cus_ai_logg_tx(navn), textAlign: TextAlign.center, style: inter(14, weight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(AiCopy.cus_ai_logg_under, textAlign: TextAlign.center, style: inter(12.5, height: 1.4, color: const Color.fromRGBO(255, 255, 255, .75))),
          ])),
        ]),
        primary: MegArkButton(key: const Key('cus-ai-logg-cta'), label: AppFeatureFlagsVipps.on ? AiCopy.cus_ai_logg_vipps : AiCopy.cus_ai_logg_inn, onTap: () => Navigator.of(context).pop('logg')),
        secondary: MegArkButton(label: AiCopy.cus_ai_avbryt, onTap: () => Navigator.of(context).pop()),
      );
    }
    var p = prefs ?? const CusAiPrefs();
    return showMegArk<Object>(
      context,
      key: const Key('cus-ai-samtykke'),
      mork: true,
      title: AiCopy.cus_ai_sam_tittel(navn),
      subtitle: AiCopy.cus_ai_sam_linje(navn),
      body: (ctx, setState) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AiHandshake(modus: 'kobler', navn: navn, linje: AiCopy.cus_ai_venter_svar),
        Row(children: [
          _pill(AiIk.skjold, AiCopy.cus_ai_rett_antall(2 + p.scopes.where((s) => s != 'catalog:read' && s != 'orders:write').length)),
          const SizedBox(width: 8),
          Flexible(child: _pill(AiIk.lommebok, AiCopy.cus_ai_grense_sum(p.capPerOrderKr, p.capPerDayKr))),
        ]),
        rettigheter(ctx, navn, p, (ny) => setState(() => p = ny), adresse: adresse),
        const SizedBox(height: 10),
        Row(children: [const AeIkon(AiIk.skjold, size: 14, stroke: 2.2, color: Color(0xFF7FF0CB)), const SizedBox(width: 8), Expanded(child: Text(AiCopy.cus_ai_sam_samtykke(navn), style: inter(12, height: 1.4, color: const Color.fromRGBO(255, 255, 255, .72))))]),
      ]),
      primary: MegArkButton(key: const Key('cus-ai-samtykke-cta'), label: AiCopy.cus_ai_koble_til(navn), onTap: () => Navigator.of(context).pop(p)),
      secondary: MegArkButton(key: const Key('cus-ai-samtykke-avbryt'), label: AiCopy.cus_ai_avbryt, onTap: () => Navigator.of(context).pop()),
    );
  }

  static Widget _pill(String ik, String tx) => Container(padding: const EdgeInsets.fromLTRB(9, 5, 10, 5), decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color.fromRGBO(92, 224, 184, .14), border: Border.all(color: const Color.fromRGBO(92, 224, 184, .35))), child: Row(mainAxisSize: MainAxisSize.min, children: [AeIkon(ik, size: 12, stroke: 2.4, color: const Color(0xFF7FF0CB)), const SizedBox(width: 5), Flexible(child: Text(tx, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(11, weight: FontWeight.w800, color: const Color(0xFF7FF0CB))))]));

  /// The rights, the limits, payment, address and Min bio (design `rettVals`) — shared by aiSamtykke and aiDetalj.
  static Widget rettigheter(BuildContext ctx, String navn, CusAiPrefs p, void Function(CusAiPrefs) sett, {String? adresse}) {
    const scopes = ['catalog:read', 'cart:write', 'orders:read', 'orders:write', 'profile:read', 'support:write'];
    const locked = ['catalog:read', 'orders:write'];
    const ik = [AiIk.bok, AiIk.pose, AiIk.hist, AiIk.skjold, AiIk.pin, AiIk.person];
    final paaN = 2 + p.scopes.where((s) => !locked.contains(s)).length;
    Widget stepper(String navnTx, String under, String ik, int verdi, int steg, int min, int max, void Function(int) on) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: [
        Row(children: [
          Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), color: const Color.fromRGBO(255, 255, 255, .1)), child: AeIkon(ik, size: 16, stroke: 2.2)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(navnTx, style: inter(13.5, weight: FontWeight.w800)), Text(under, style: inter(11.5, color: const Color.fromRGBO(255, 255, 255, .65)))])),
          AePress(onTap: () => on((verdi - steg).clamp(min, max)), dy: 1, child: Opacity(opacity: verdi <= min ? .4 : 1, child: Container(width: 30, height: 30, alignment: Alignment.center, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(255, 255, 255, .12)), child: const AeIkon('M5 12h14', size: 12, stroke: 2.6)))),
          SizedBox(width: 72, child: Text(AiCopy.kr(verdi), textAlign: TextAlign.center, style: aeTab(inter(14, weight: FontWeight.w800)))),
          AePress(onTap: () => on((verdi + steg).clamp(min, max)), dy: 1, child: Opacity(opacity: verdi >= max ? .4 : 1, child: Container(width: 30, height: 30, alignment: Alignment.center, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(255, 255, 255, .12)), child: const AeIkon('M12 5v14M5 12h14', size: 12, stroke: 2.6)))),
        ]),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(99), child: SizedBox(height: 5, child: Stack(children: [const Positioned.fill(child: ColoredBox(color: Color.fromRGBO(255, 255, 255, .12))), FractionallySizedBox(widthFactor: ((verdi - min) / (max - min)).clamp(0.02, 1.0), heightFactor: 1, alignment: Alignment.centerLeft, child: const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF7FF0CB), Color(0xFF5CE0B8)]))))]))),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(AiCopy.kr(min), style: inter(10.5, color: const Color.fromRGBO(255, 255, 255, .5))), Text(AiCopy.kr(max), style: inter(10.5, color: const Color.fromRGBO(255, 255, 255, .5)))]),
      ]),
    );
    Widget seg(List<(String, String)> alt, String verdi, void Function(String) on) => Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color.fromRGBO(0, 0, 0, .22), border: Border.all(color: const Color.fromRGBO(255, 255, 255, .14))),
      child: Row(children: [for (final (v, t) in alt) Expanded(child: AePress(onTap: () => on(v), dy: 1, child: Container(key: Key('cus-ai-seg-$v'), height: 30, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), gradient: verdi == v ? const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFE6F2EF)]) : null), child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(11.5, weight: FontWeight.w800, color: verdi == v ? const Color(0xFF1E4F5C) : const Color.fromRGBO(255, 255, 255, .75))))))]),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AiSeksjon(AiCopy.cus_ai_rett_tittel(navn), hoyre: AiCopy.cus_ai_rett_antall(paaN)),
      for (final (i, s) in scopes.indexed)
        MorkRad(
          key: Key('cus-ai-rett-$s'),
          delayMs: 50.0 + i * 40,
          ikon: ik[i],
          navn: AiCopy.cus_ai_rett[i][0],
          under: AiCopy.cus_ai_rett[i][1],
          bryter: locked.contains(s) ? null : p.scopes.contains(s),
          verdi: locked.contains(s) ? (s == 'catalog:read' ? AiCopy.cus_ai_alltid_paa : AiCopy.cus_ai_paakrevd) : null,
          onTap: () {
            if (locked.contains(s)) {
              showBergenToast(ctx, s == 'orders:write' ? AiCopy.cus_ai_bekrefter_alltid : AiCopy.cus_ai_menyer_synlige);
              return;
            }
            final ny = List<String>.from(p.scopes);
            ny.contains(s) ? ny.remove(s) : ny.add(s);
            sett(p.copyWith(scopes: ny));
          },
        ),
      AiSeksjon(AiCopy.cus_ai_dine_grenser),
      Padding(padding: const EdgeInsets.fromLTRB(4, 0, 4, 4), child: Text(AiCopy.cus_ai_grense_tittel(navn), style: inter(13.5, weight: FontWeight.w800))),
      stepper(AiCopy.cus_ai_maks_per_best, AiCopy.cus_ai_forslag(500), AiIk.lommebok, p.capPerOrderKr, 50, 100, 2000, (v) => sett(p.copyWith(capPerOrderKr: v))),
      stepper(AiCopy.cus_ai_maks_per_dag, AiCopy.cus_ai_forslag(1000), AiIk.kal, p.capPerDayKr, 100, 200, 5000, (v) => sett(p.copyWith(capPerDayKr: v))),
      const SizedBox(height: 6),
      Row(children: [Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), color: const Color.fromRGBO(255, 255, 255, .1)), child: const AeIkon(AiIk.kort, size: 16, stroke: 2.2)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AiCopy.cus_ai_betaling, style: inter(13.5, weight: FontWeight.w800)), Text(AiCopy.cus_ai_betaling_under, style: inter(11.5, color: const Color.fromRGBO(255, 255, 255, .65)))]))]),
      const SizedBox(height: 8),
      seg([('vipps', AiCopy.cus_ai_vipps), ('card', AiCopy.cus_ai_lagret_kort), ('ask', AiCopy.cus_ai_spor_hver_gang)], p.paymentPref, (v) => sett(p.copyWith(paymentPref: v))),
      const SizedBox(height: 12),
      Row(children: [Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), color: const Color.fromRGBO(255, 255, 255, .1)), child: const AeIkon(AiIk.hus, size: 16, stroke: 2.2)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AiCopy.cus_ai_leveringsadresse, style: inter(13.5, weight: FontWeight.w800)), Text(AiCopy.cus_ai_hjemme_er(adresse ?? AiCopy.cus_ai_hjemme), maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(11.5, color: const Color.fromRGBO(255, 255, 255, .65)))]))]),
      const SizedBox(height: 8),
      seg([('home', AiCopy.cus_ai_hjemme), ('ask', AiCopy.cus_ai_spor_hver_gang)], p.addressPref, (v) => sett(p.copyWith(addressPref: v))),
      const SizedBox(height: 12),
      MorkRad(key: const Key('cus-ai-bio'), delayMs: 0, ikon: AiIk.hjerte, navn: AiCopy.cus_ai_del_bio, bryter: p.shareBio, onTap: () => sett(p.copyWith(shareBio: !p.shareBio))),
      Padding(padding: const EdgeInsets.fromLTRB(4, 6, 4, 0), child: Text(AiCopy.cus_ai_bio_tx(navn), style: inter(11.5, height: 1.4, color: const Color.fromRGBO(255, 255, 255, .65)))),
    ]);
  }

  // ── aiKoblet ─────────────────────────────────────────────────────────────

  static Future<String?> koblet(BuildContext context, CusAiLink link, {bool fraHurtig = false}) async {
    final n = link.name;
    return showMegArk<String>(
      context,
      key: const Key('cus-ai-koblet'),
      mork: true,
      title: AiCopy.cus_ai_koblet_tittel(n),
      subtitle: AiCopy.cus_ai_koblet_linje(n),
      body: (ctx, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AiHandshake(modus: 'koblet', navn: n, linje: AiCopy.cus_ai_koblet_naa),
        Row(children: [
          for (final (i, x) in [(AiCopy.cus_ai_per_best, link.capPerOrder?.display ?? '—', AiIk.lommebok), (AiCopy.cus_ai_betaling, _betNavn(link.paymentPref), AiIk.kort), (AiCopy.cus_ai_levering, link.addressPref == 'ask' ? AiCopy.cus_ai_spor_hver_gang : AiCopy.cus_ai_hjemme, AiIk.hus)].indexed) ...[
            Expanded(child: AeOnce(kind: AeInn.stigOpp, ms: 420, delay: 950.0 + i * 80, child: AiKort(padding: const EdgeInsets.all(10), child: Column(children: [AeIkon(x.$3, size: 16, stroke: 2.2, color: const Color(0xFF7FF0CB)), const SizedBox(height: 6), Text(x.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(13, weight: FontWeight.w800)), Text(x.$1, style: inter(10.5, color: const Color.fromRGBO(255, 255, 255, .6)))])))),
            if (i < 2) const SizedBox(width: 8),
          ],
        ]),
        AiSeksjon(AiCopy.cus_ai_prov_naa),
        AiKort(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [AiMerke(n, size: 30), const SizedBox(width: 10), Expanded(child: Text('«${AiCopy.cus_ai_prompt}»', style: inter(13.5, weight: FontWeight.w700, height: 1.4)))]),
          const SizedBox(height: 10),
          AePress(onTap: () async { try { await Clipboard.setData(ClipboardData(text: AiCopy.cus_ai_prompt)); } catch (_) {} if (ctx.mounted) showBergenToast(ctx, AiCopy.cus_ai_kopiert_lim(n)); }, dy: 1.5, child: Container(key: const Key('cus-ai-kopier-forslag'), height: 38, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color.fromRGBO(255, 255, 255, .1), border: Border.all(color: const Color.fromRGBO(255, 255, 255, .2))), child: Row(mainAxisSize: MainAxisSize.min, children: [const AeIkon(AiIk.kopier, size: 13, stroke: 2.4), const SizedBox(width: 6), Text(AiCopy.cus_ai_kopier_forslag, style: inter(12.5, weight: FontWeight.w800))]))),
        ])),
      ]),
      primary: MegArkButton(key: const Key('cus-ai-koblet-cta'), label: fraHurtig ? AiCopy.cus_ai_bestill_naa(n) : AiCopy.cus_ai_ferdig, onTap: () => Navigator.of(context).pop(fraHurtig ? 'bestill:$n' : 'koblede')),
      secondary: MegArkButton(key: const Key('cus-ai-koblet-grenser'), label: AiCopy.cus_ai_endre_grenser, onTap: () => Navigator.of(context).pop('detalj:${link.id}')),
    );
  }

  // ── aiKoblede ────────────────────────────────────────────────────────────

  static Future<String?> koblede(BuildContext context) async {
    final L = _store.alle;
    final aktive = _store.aktive;
    final tom = L.isEmpty;
    return showMegArk<String>(
      context,
      key: const Key('cus-ai-koblede'),
      mork: true,
      title: AiCopy.cus_ai_koblede_tittel,
      subtitle: tom ? AiCopy.cus_ai_koblede_tom : (aktive.isEmpty ? AiCopy.cus_ai_ingen_aktive : AiCopy.cus_ai_koblede_linje(aktive.length)),
      body: (ctx, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (tom) ...[
          AiKort(padding: const EdgeInsets.all(16), child: Column(children: [
            Image.asset('assets/images/dashboard/find.png', height: 90),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (final (i, n) in const ['Claude', 'ChatGPT', 'Gemini'].indexed) AeOnce(kind: AeInn.stigOpp, ms: 420, delay: 300.0 + i * 120, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: AiMerke(n, size: 30)))]),
            const SizedBox(height: 10),
            Text(AiCopy.cus_ai_koblede_tom, key: const Key('cus-ai-koblede-tom'), style: inter(15, weight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(AiCopy.cus_ai_tom_tekst, textAlign: TextAlign.center, style: inter(12.5, height: 1.4, color: const Color.fromRGBO(255, 255, 255, .72))),
          ])),
        ],
        for (final (i, l) in L.indexed)
          AeOnce(kind: AeInn.stigOpp, ms: 420, delay: 50.0 + i * 70, child: AePress(
            onTap: () => Navigator.of(ctx).pop('detalj:${l.id}'),
            dy: 1.5,
            child: Opacity(opacity: l.active ? 1 : .75, child: Container(
              key: Key('cus-ai-kort-${l.id}'),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: l.active ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(255, 255, 255, .15), Color.fromRGBO(255, 255, 255, .05)]) : null, color: l.active ? null : const Color.fromRGBO(255, 255, 255, .04), border: Border.all(color: l.active ? const Color.fromRGBO(255, 255, 255, .18) : const Color.fromRGBO(255, 255, 255, .1))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  AiMerke(l.name, size: 40),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Flexible(child: Text(l.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(14, weight: FontWeight.w800))), const SizedBox(width: 8), Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: _status(l.active ? AiCopy.cus_ai_aktiv : AiCopy.cus_ai_frakoblet, l.active)))]),
                    const SizedBox(height: 2),
                    Text(l.active ? AiCopy.cus_ai_sist_brukt(aiTid(l.lastUsedAt), l.capPerOrder?.kr ?? 0) : AiCopy.cus_ai_frakoblet_dato(aiTid(l.revokedAt)), style: inter(11.5, color: const Color.fromRGBO(255, 255, 255, .7))),
                  ])),
                  const AeIkon(AiIk.pil, size: 13, stroke: 2.3, color: Color.fromRGBO(255, 255, 255, .7)),
                ]),
                if (l.active) ...[
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(AiCopy.cus_ai_brukt_i_dag, style: inter(11, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .65))), Text(AiCopy.cus_ai_av(l.usedToday.display, l.capPerDay?.display ?? '—'), style: aeTab(inter(11, weight: FontWeight.w800)))]),
                  const SizedBox(height: 5),
                  ClipRRect(borderRadius: BorderRadius.circular(99), child: SizedBox(height: 5, child: Stack(children: [const Positioned.fill(child: ColoredBox(color: Color.fromRGBO(255, 255, 255, .12))), FractionallySizedBox(widthFactor: ((l.capPerDay?.ore ?? 0) > 0 ? (l.usedToday.ore / l.capPerDay!.ore) : 0.0).toDouble().clamp(0.03, 1.0), heightFactor: 1, alignment: Alignment.centerLeft, child: const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF7FF0CB), Color(0xFF5CE0B8)]))))]))),
                  const SizedBox(height: 8),
                  Row(children: [const AeIkon(AiIk.skjold, size: 12, stroke: 2.4, color: Color(0xFF7FF0CB)), const SizedBox(width: 6), Expanded(child: Text(AiCopy.cus_ai_rett_kort.where((r) => l.has(r[0])).map((r) => r[1]).join(' · '), style: inter(11.5, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .75))))]),
                ],
              ]),
            )),
          )),
        if (aktive.isNotEmpty)
          Center(child: AePress(onTap: () => Navigator.of(ctx).pop('kobleFraAlle'), dy: 1, child: Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.fromLTRB(16, 9, 18, 9), decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color.fromRGBO(242, 109, 61, .12), border: Border.all(color: const Color.fromRGBO(255, 200, 168, .35))), child: Row(mainAxisSize: MainAxisSize.min, children: [const AeIkon(AiIk.ut, size: 13, stroke: 2.4, color: Color(0xFFFFC8A8)), const SizedBox(width: 6), Text(AiCopy.cus_ai_koble_fra_alle, key: const Key('cus-ai-koble-fra-alle'), style: inter(12.5, weight: FontWeight.w800, color: const Color(0xFFFFC8A8)))])))),
      ]),
      primary: tom ? MegArkButton(key: const Key('cus-ai-koblede-cta'), label: AiCopy.cus_ai_slik_kobler, onTap: () => Navigator.of(context).pop('inngang')) : null,
      secondary: tom ? null : MegArkButton(key: const Key('cus-ai-koblede-ny'), label: AiCopy.cus_ai_koble_ny, onTap: () => Navigator.of(context).pop('inngang')),
    );
  }

  // ── aiDetalj ─────────────────────────────────────────────────────────────

  static Future<String?> detalj(BuildContext context, CusAiLink? link, {required String navn}) async {
    if (link == null) {
      return showMegArk<String>(
        context,
        key: const Key('cus-ai-detalj-ukoblet'),
        mork: true,
        title: navn,
        subtitle: AiCopy.cus_ai_ikke_koblet_linje(navn),
        body: (ctx, _) => AiHandshake(modus: 'ukoblet', navn: navn, linje: AiCopy.cus_ai_ikke_koblet_hs),
        primary: MegArkButton(label: AiCopy.cus_ai_koble_til(navn), onTap: () => Navigator.of(context).pop('samtykke:$navn')),
        secondary: MegArkButton(label: AiCopy.cus_ai_tilbake, onTap: () => Navigator.of(context).pop('koblede')),
      );
    }
    var l = link;
    List<CusAiAktivitet>? akt;
    var p = CusAiPrefs(scopes: l.scopes, capPerOrderKr: l.capPerOrder?.kr ?? 500, capPerDayKr: l.capPerDay?.kr ?? 1000, paymentPref: l.paymentPref, addressPref: l.addressPref, shareBio: l.shareBio);
    Timer? lagre;
    final n = l.name;
    return showMegArk<String>(
      context,
      key: const Key('cus-ai-detalj'),
      mork: true,
      title: n,
      subtitle: l.active ? AiCopy.cus_ai_detalj_linje(n) : AiCopy.cus_ai_detalj_ikke(n),
      body: (ctx, setState) {
        if (akt == null) {
          akt = const [];
          if (_store.harness) {
            akt = [CusAiAktivitet(tool: 'search_products', outcome: 'ok', at: DateTime.now().subtract(const Duration(minutes: 22))), CusAiAktivitet(tool: 'create_cart', outcome: 'ok', at: DateTime.now().subtract(const Duration(minutes: 20))), CusAiAktivitet(tool: 'confirm_order', outcome: 'ok', at: DateTime(2026, 10, 3, 18, 2))];
          } else {
            _api.aiLink(l.id).then((r) {
              if (r != null && ctx.mounted) setState(() { l = r.link; akt = r.aktivitet; });
            });
          }
        }
        void oppdater(CusAiPrefs ny) {
          setState(() => p = ny);
          lagre?.cancel();
          lagre = Timer(const Duration(milliseconds: 600), () async {
            if (_store.harness) return;
            final r = await _api.aiLinkUpdate(l.id, scopes: p.scopes, capPerOrderKr: p.capPerOrderKr, capPerDayKr: p.capPerDayKr, paymentPref: p.paymentPref, addressPref: p.addressPref, shareBio: p.shareBio);
            if (!ctx.mounted) return;
            if (r == null) {
              showBergenToast(ctx, AiCopy.cus_ai_lagret_feil, icon: Icons.error_outline_rounded);
            } else {
              setState(() => l = r);
              unawaited(_store.load(force: true));
            }
          });
        }
        final A = akt ?? const <CusAiAktivitet>[];
        final best = A.where((a) => a.tool == 'confirm_order').length + (A.isEmpty ? l.orders : 0);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AiKort(child: Row(children: [
            AiMerke(n, size: 46),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Flexible(child: Text(n, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(16, weight: FontWeight.w800))), const SizedBox(width: 8), Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: _status(l.active ? AiCopy.cus_ai_aktiv : AiCopy.cus_ai_frakoblet, l.active)))]),
              const SizedBox(height: 2),
              Text(l.active ? AiCopy.cus_ai_koblet_til(aiDato(l.grantedAt), aiTid(l.lastUsedAt)) : AiCopy.cus_ai_frakoblet_dato(aiTid(l.revokedAt)), style: inter(11.5, color: const Color.fromRGBO(255, 255, 255, .7))),
            ])),
          ])),
          const SizedBox(height: 8),
          Row(children: [
            for (final (i, x) in [('$best', best == 1 ? AiCopy.cus_ai_bestilling : AiCopy.cus_ai_bestillinger), (l.usedToday.display, AiCopy.cus_ai_brukt_i_dag), (aiTid(l.lastUsedAt), AiCopy.cus_ai_sist_brukt_lbl)].indexed) ...[
              Expanded(child: AeOnce(kind: AeInn.stigOpp, ms: 400, delay: 120.0 + i * 60, child: AiKort(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6), child: Column(children: [Text(x.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: aeTab(inter(15, weight: FontWeight.w800))), Text(x.$2, style: inter(10.5, color: const Color.fromRGBO(255, 255, 255, .6)))])))),
              if (i < 2) const SizedBox(width: 8),
            ],
          ]),
          if (l.active) rettigheter(ctx, n, p, oppdater),
          AiSeksjon(AiCopy.cus_ai_aktivitet),
          if (A.isEmpty) Padding(padding: const EdgeInsets.fromLTRB(4, 0, 4, 8), child: Text(AiCopy.cus_ai_ingen_aktivitet, style: inter(12.5, color: const Color.fromRGBO(255, 255, 255, .6)))),
          for (final (i, a) in A.indexed)
            AeOnce(kind: AeInn.stigOpp, ms: 380, delay: 100.0 + i * 60, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(children: [
                Container(width: 28, height: 28, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, gradient: a.tool == 'confirm_order' ? const LinearGradient(colors: [Color(0xFFB4F9E2), Color(0xFF5CE0B8)]) : null, color: a.tool == 'start_checkout' ? const Color.fromRGBO(245, 196, 81, .24) : (a.tool == 'confirm_order' ? null : const Color.fromRGBO(255, 255, 255, .14))), child: AeIkon(switch (a.tool) { 'confirm_order' || 'create_cart' || 'update_cart' || 'reorder' => AiIk.pose, 'start_checkout' => AiIk.skjold, 'search_products' || 'search_stores' => AiIk.sok, 'open_support' => AiIk.person, _ => AiIk.kobling }, size: 13, stroke: 2.4, color: a.tool == 'confirm_order' ? const Color(0xFF0F2B33) : (a.tool == 'start_checkout' ? const Color(0xFFFFE08A) : Colors.white))),
                if (i < A.length - 1) Container(width: 2, height: 18, color: const Color.fromRGBO(255, 255, 255, .14)),
              ]),
              const SizedBox(width: 10),
              Expanded(child: Padding(padding: const EdgeInsets.only(top: 4, bottom: 6), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AiCopy.cus_ai_akt(a.tool), style: inter(13, weight: FontWeight.w800)), Text(aiTid(a.at), style: inter(11, color: const Color.fromRGBO(255, 255, 255, .6)))]))),
            ])),
          const SizedBox(height: 6),
          if (l.active)
            AePress(onTap: () => Navigator.of(ctx).pop('kobleFra:${l.id}'), dy: 1, child: Container(key: const Key('cus-ai-detalj-koble-fra'), height: 44, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color.fromRGBO(242, 109, 61, .14), border: Border.all(color: const Color.fromRGBO(249, 162, 115, .45))), child: Row(mainAxisSize: MainAxisSize.min, children: [const AeIkon(AiIk.ut, size: 14, stroke: 2.4, color: Color(0xFFFFC8A8)), const SizedBox(width: 6), Text(AiCopy.cus_ai_koble_fra(n), style: inter(13, weight: FontWeight.w800, color: const Color(0xFFFFC8A8)))])))
          else
            AePress(onTap: () => Navigator.of(ctx).pop('samtykke:$n'), dy: 1, child: Container(key: const Key('cus-ai-detalj-koble-igjen'), height: 44, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color.fromRGBO(92, 224, 184, .14), border: Border.all(color: const Color.fromRGBO(127, 240, 203, .45))), child: Row(mainAxisSize: MainAxisSize.min, children: [const AeIkon(AiIk.oppdater, size: 14, stroke: 2.4, color: Color(0xFF7FF0CB)), const SizedBox(width: 6), Text(AiCopy.cus_ai_koble_igjen(n), style: inter(13, weight: FontWeight.w800, color: const Color(0xFF7FF0CB)))]))),
        ]);
      },
      secondary: MegArkButton(key: const Key('cus-ai-detalj-tilbake'), label: AiCopy.cus_ai_tilbake, onTap: () => Navigator.of(context).pop('koblede')),
    ).whenComplete(() {
      if (lagre?.isActive == true) {
        lagre!.cancel();
        if (!_store.harness) unawaited(_api.aiLinkUpdate(l.id, scopes: p.scopes, capPerOrderKr: p.capPerOrderKr, capPerDayKr: p.capPerDayKr, paymentPref: p.paymentPref, addressPref: p.addressPref, shareBio: p.shareBio).then((_) => _store.load(force: true)));
      }
    });
  }

  // ── aiKobleFra ───────────────────────────────────────────────────────────

  static Future<String?> kobleFra(BuildContext context, {CusAiLink? link, String navn = '', bool alle = false}) async {
    final n = link?.name ?? navn;
    final antall = _store.aktive.length;
    return showMegArk<String>(
      context,
      key: const Key('cus-ai-koble-fra'),
      mork: true,
      title: alle ? AiCopy.cus_ai_fra_alle_tittel : AiCopy.cus_ai_fra_tittel(n),
      subtitle: alle ? AiCopy.cus_ai_fra_alle_linje : AiCopy.cus_ai_fra_linje(n),
      body: (ctx, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AiHandshake(modus: 'brutt', navn: alle ? AiCopy.cus_ai_assistenter(antall) : n, linje: alle ? AiCopy.cus_ai_alle_mister : AiCopy.cus_ai_mister, merkeTx: alle ? '$antall' : null),
        for (final (i, t) in AiCopy.cus_ai_fra_info.indexed) AiLinjeRad(ikon: [AiIk.kobling, AiIk.pose, AiIk.oppdater][i], tekst: t, delayMs: 550.0 + i * 70),
      ]),
      primary: MegArkButton(
        key: const Key('cus-ai-koble-fra-cta'),
        label: AiCopy.cus_ai_koble_fra_cta,
        rod: true,
        onTap: () async {
          if (_store.harness) {
            _store.settLokalt([for (final l in _store.alle) if (alle || l.id == link?.id) AiStore.harnessLink(l.name, active: false) else l]);
          } else if (alle) {
            await _api.aiLinksRevokeAll();
          } else if (link != null) {
            await _api.aiLinkRevoke(link.id);
          }
          await _store.load(force: true);
          if (!context.mounted) return;
          showBergenToast(context, alle ? AiCopy.cus_ai_alle_koblet_fra : AiCopy.cus_ai_er_koblet_fra(n));
          Navigator.of(context).pop('koblede');
        },
      ),
      secondary: MegArkButton(label: AiCopy.cus_ai_avbryt, onTap: () => Navigator.of(context).pop(alle || link == null ? 'koblede' : 'detalj:${link.id}')),
    );
  }

  // ── aiFeil ───────────────────────────────────────────────────────────────

  /// [kind]: `ikkeKoblet` | `bekreft` | `generisk`.
  static Future<String?> feil(BuildContext context, String kind, String navn, {int belopKr = 612, int grenseKr = 500, String? requestId}) async {
    final (tittel, linje, cta, neste) = switch (kind) {
      'ikkeKoblet' => (AiCopy.cus_ai_feil_ikke_koblet(navn), AiCopy.cus_ai_feil_ikke_koblet_linje(navn), AiCopy.cus_ai_koble, 'samtykke:$navn'),
      'bekreft' => (AiCopy.cus_ai_feil_bekreft, AiCopy.cus_ai_feil_bekreft_linje(grenseKr), AiCopy.cus_ai_se_bestillingen, 'bekreft:${requestId ?? ''}'),
      _ => (AiCopy.cus_ai_feil_generisk, AiCopy.cus_ai_feil_generisk_linje, AiCopy.cus_ai_prov_igjen, 'kurvLaster'),
    };
    return showMegArk<String>(
      context,
      key: Key('cus-ai-feil-$kind'),
      mork: true,
      title: tittel,
      subtitle: linje,
      body: (ctx, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (kind == 'ikkeKoblet') AiHandshake(modus: 'ukoblet', navn: navn, linje: AiCopy.cus_ai_ikke_koblet_enna),
        if (kind == 'bekreft')
          AiKort(child: Row(children: [
            Container(width: 52, height: 52, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color.fromRGBO(245, 196, 81, .18), border: Border.all(color: const Color.fromRGBO(245, 196, 81, .5))), child: const AeIkon(AiIk.skjold, size: 24, stroke: 2.2, color: Color(0xFFFFE08A))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AiCopy.kr(belopKr), style: aeTab(jakarta(24, weight: FontWeight.w800))), Text(AiCopy.cus_ai_grensen_din(grenseKr), style: inter(12, color: const Color.fromRGBO(255, 255, 255, .7)))])),
          ])),
        if (kind != 'ikkeKoblet' && kind != 'bekreft') Center(child: Image.asset('assets/images/dashboard/sorry.png', height: 120)),
        const SizedBox(height: 10),
        Center(child: _pill(AiIk.skjold, AiCopy.cus_ai_ingenting_bestilt)),
      ]),
      primary: MegArkButton(key: const Key('cus-ai-feil-cta'), label: cta, onTap: () => Navigator.of(context).pop(neste)),
      secondary: MegArkButton(label: AiCopy.cus_ai_lukk, onTap: () => Navigator.of(context).pop()),
    );
  }
}

/// Whether the Vipps login is enabled in this build (the design's «Logg inn med Vipps» only then; D-K16).
abstract final class AppFeatureFlagsVipps {
  static bool get on => const bool.fromEnvironment('SHOW_VIPPS_LOGIN', defaultValue: false);
}
