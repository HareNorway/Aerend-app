// ignore_for_file: non_constant_identifier_names
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../networking/ops/cus_api.dart';
import '../../../utils/utils.dart' show isLoggedIn;
import '../../common/auth/launch/lf_css.dart';
import '../aegil/aegil_bits.dart';
import '../hjem/hjem_harness.dart';
import '../kasse/kurv_betal.dart';
import '../kit/bergen_kit.dart';
import 'ai_betaling.dart';
import 'ai_bits.dart';
import 'ai_copy.dart';
import 'ai_store.dart';
import 'ai_tilbud.dart';
import '../../../services/customer/beacons.dart';

/// Customer plan Step 14 — «Handlekurv fra assistent» (design 8060–8187,
/// `skjerm: 'aiKurv'`, route `/bergen/ai/foresporsel/{id}`, the hand-off
/// link's target): the header with «Fra {AI}», «Ingenting sendes før du
/// bekrefter her», the store card; the states `laster`, `gjest`, `dekning`
/// (waitlist), `normal` / `utsolgt` / `utlopt` with the offer, «Endre
/// handlekurven» (→ Kurv) and «Avvis», the delivery and payment rows and
/// the drag-to-pay slider; the bottom nav hidden.
class AiKurvScreen extends StatefulWidget {
  const AiKurvScreen({super.key, this.id, this.api, this.tilstand});

  final String? id;
  final CusApi? api;

  /// Debug / tests: `laster` | `gjest` | `dekning` | `normal` | `utsolgt` | `utlopt` | `vente` on the sample request.
  final String? tilstand;

  @override
  State<AiKurvScreen> createState() => _AiKurvScreenState();
}

class _AiKurvScreenState extends State<AiKurvScreen> {
  CusApi get _api => widget.api ?? AiStore.instance.api;
  CusAiRequest? _r;
  bool _laster = true;
  bool _gjest = false;
  bool _vente = false;
  bool _betaler = false;
  String? _tilstand;
  CusMoney? _gammelTotal;
  String _bet = 'vipps';
  Timer? _laserT;

  String get _id => widget.id ?? BergenRoutes.argsOf(context)['id'] ?? '';

  @override
  void initState() {
    super.initState();
    _tilstand = widget.tilstand ?? (kDebugMode ? HjemHarness.ai?.replaceFirst('kurv', '').toLowerCase() : null);
    if (_tilstand != null && _tilstand!.isEmpty) _tilstand = 'normal';
    if (kDebugMode && HjemHarness.ai != null && HjemHarness.ai!.startsWith('kurv')) HjemHarness.ai = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _vakt.start();
  }

  /// Customer Step 16: a loader longer than 20 s is a `stuck_screen` beacon.
  final _vakt = CusStuckWatch('ai_kurv');

  @override
  void dispose() {
    _vakt.stop();
    _laserT?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final t = _tilstand;
    if (t != null && (widget.id == null || widget.id == 'demo') && (kDebugMode || widget.api == null)) {
      // The harness: the design's states on the sample request.
      _gjest = t == 'gjest';
      _vente = t == 'vente';
      final r = aiSampleRequest(navn: HjemHarness.aiNavn ?? 'Claude', state: t == 'gjest' || t == 'laster' || t == 'vente' ? (t == 'vente' ? 'dekning' : 'normal') : t);
      if (t == 'laster') {
        setState(() { _r = r; _laster = true; });
        _laserT = Timer(const Duration(milliseconds: 1500), () { if (mounted) setState(() => _laster = false); });
        return;
      }
      if (t == 'utlopt') _gammelTotal = CusMoney(ore: r.total.ore - 2000, display: AiCopy.kr((r.total.ore - 2000) ~/ 100));
      setState(() { _r = r; _laster = false; _bet = r.paymentPref == 'card' ? 'card' : 'vipps'; });
      return;
    }
    if (!isLoggedIn()) {
      setState(() { _gjest = true; _laster = false; });
      return;
    }
    CusAiRequest? r;
    try {
      r = await _api.aiRequest(_id);
    } catch (_) {
      r = null; // the plain empty state (fallback audit)
    }
    if (!mounted) return;
    final gammel = r;
    if (gammel != null && gammel.state == 'utlopt' && gammel.orderId == null) {
      // «Tilbudet har utløpt · vi har hentet et nytt tilbud» — re-quote at once, the old total shown struck through.
      final ny = await _api.aiRequestRequote(gammel.id);
      if (!mounted) return;
      if (ny != null) {
        setState(() { _r = ny; _gammelTotal = gammel.total; _laster = false; _bet = ny.paymentPref == 'card' ? 'card' : 'vipps'; });
        return;
      }
    }
    setState(() { _r = r; _laster = false; _bet = (r?.paymentPref ?? 'vipps') == 'card' ? 'card' : 'vipps'; });
    _vakt.stop();
    // Harness: `aiBetal` releases the slider on the real request (acceptance runs; never the sample).
    if (kDebugMode && HjemHarness.aiBetal && r != null && r.state == 'normal' && _id.isNotEmpty && _id != 'demo') {
      HjemHarness.aiBetal = false;
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) betalNaa(payment: 'vipps'); });
    }
  }

  String get _state {
    final r = _r;
    if (_gjest) return 'gjest';
    if (_laster) return 'laster';
    if (r == null) return 'tom';
    if (_vente) return 'vente';
    if (r.state == 'dekning' || !r.covered) return 'dekning';
    return r.state;
  }

  Future<void> _fjern(CusAiLinje l) async {
    final r = _r;
    if (r == null) return;
    if (_tilstand != null && (widget.id == null || widget.id == 'demo')) {
      setState(() => _r = aiSampleRequest(navn: r.assistant));
      showBergenToast(context, AiCopy.cus_ai_endre_under);
      return;
    }
    final ny = await _api.aiRequestRequote(r.id, removeLineId: l.lineId);
    if (!mounted) return;
    if (ny == null) {
      showBergenToast(context, AiCopy.cus_ai_feil_generisk, icon: Icons.error_outline_rounded);
      return;
    }
    setState(() { _r = ny; _gammelTotal = r.total; });
    showBergenToast(context, AiCopy.cus_ai_endre_under);
  }

  Future<void> _avvis() async {
    final r = _r;
    if (r != null && !(_tilstand != null && (widget.id == null || widget.id == 'demo'))) await _api.aiRequestDecline(r.id);
    if (!mounted) return;
    showBergenToast(context, AiCopy.cus_ai_avvist);
    _tilHjem();
  }

  void _tilHjem() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushNamedAndRemoveUntil('/bergen/hjem', (route) => false);
    }
  }

  void _endre() {
    showBergenToast(context, AiCopy.cus_ai_endre_under);
    BergenRoutes.push<void>(context, '/bergen/kurv');
  }

  Future<void> _venteliste() async {
    final r = _r;
    if (r == null) return;
    if (!(_tilstand != null && (widget.id == null || widget.id == 'demo'))) await _api.aiRequestWaitlist(r.id);
    if (!mounted) return;
    setState(() => _vente = true);
    showBergenToast(context, AiCopy.cus_ai_paa_venteliste);
  }

  Future<bool> _betal() async {
    final r = _r;
    if (r == null || _betaler) return false;
    setState(() => _betaler = true);
    final res = await AiBetaling.betal(context, r, payment: _bet, harness: _tilstand != null && (widget.id == null || widget.id == 'demo'));
    if (!mounted) return false;
    setState(() => _betaler = false);
    if (!res.ok && res.feil == 'quote_expired') {
      await _load();
      return false;
    }
    if (!res.ok && res.feil == 'over_limit') {
      showBergenToast(context, AiCopy.cus_ai_over(r.capPerOrder?.kr ?? 0), icon: Icons.error_outline_rounded);
      return false;
    }
    if (!res.ok && res.feil != null && res.feil != 'device') {
      showBergenToast(context, AiCopy.cus_ai_bestilling_feilet, icon: Icons.error_outline_rounded);
      return false;
    }
    return res.ok;
  }

  /// Tests: the slider's release.
  @visibleForTesting
  Future<bool> betalNaa({String? payment}) {
    if (payment != null) _bet = payment;
    return _betal();
  }

  @override
  Widget build(BuildContext context) {
    final r = _r;
    final s = _state;
    final navn = r?.assistant ?? (HjemHarness.aiNavn ?? 'Claude');
    final ok = s == 'normal' || s == 'utsolgt' || s == 'utlopt';
    final visKnapper = ok && r != null && !r.harUtsolgt;
    final top = MediaQuery.paddingOf(context).top;
    final bunn = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: const Color(0xFF0F2B33),
      body: LfFrame(
        child: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1E4F5C), Color(0xFF0F2B33), Color(0xFF081F28)], stops: [0, .55, 1])),
          child: Column(children: [
            // Header.
            Padding(
              padding: EdgeInsets.fromLTRB(16, top + 10, 16, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  AePress(onTap: _tilHjem, dy: 1.5, child: Container(key: const Key('cus-ai-kurv-tilbake'), width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color.fromRGBO(255, 255, 255, .1), border: Border.all(color: const Color.fromRGBO(255, 255, 255, .18))), child: const AeIkon('M15 6l-6 6 6 6', size: 16, stroke: 2.4))),
                  const Spacer(),
                  Container(padding: const EdgeInsets.fromLTRB(5, 4, 11, 4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color.fromRGBO(255, 255, 255, .1), border: Border.all(color: const Color.fromRGBO(255, 255, 255, .2))), child: Row(mainAxisSize: MainAxisSize.min, children: [AiMerke(navn, size: 22, radius: 7), const SizedBox(width: 7), Text(AiCopy.cus_ai_fra(navn), style: inter(12, weight: FontWeight.w800))])),
                ]),
                const SizedBox(height: 14),
                Text(AiCopy.cus_ai_kurv_tittel(navn), key: const Key('cus-ai-kurv-tittel'), style: jakarta(24, em: -.03, height: 1.05)),
                const SizedBox(height: 4),
                Row(children: [const AeIkon(AiIk.skjold, size: 12, stroke: 2.4, color: Color(0xFF7FF0CB)), const SizedBox(width: 6), Expanded(child: Text(AiCopy.cus_ai_ingenting_sendes, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(12, weight: FontWeight.w700, color: const Color(0xFF7FF0CB))))]),
              ]),
            ),
            Expanded(
              child: ListView(
                key: const Key('cus-ai-kurv-liste'),
                padding: EdgeInsets.fromLTRB(16, 14, 16, 24 + bunn),
                children: [
                  if (r != null)
                    AiKort(child: Row(children: [
                      Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), gradient: const LinearGradient(colors: [Color(0xFFF58A55), Color(0xFFE95C2C)])), child: const AeIkon('M4 10l1.6-5h12.8L20 10M4 10h16M5 10v10h14V10M10 20v-5h4v5', size: 18, stroke: 2.2)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.store, style: inter(14, weight: FontWeight.w800)), Text(r.storeLine.isEmpty ? r.address : r.storeLine, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(11.5, color: const Color.fromRGBO(255, 255, 255, .65)))])),
                    ])),
                  const SizedBox(height: 10),
                  if (s == 'laster' && r != null) ...[
                    AiTilbud(key: const Key('cus-ai-kurv-laster'), r: r, venter: false, laster: true, visFrist: false),
                    const SizedBox(height: 10),
                    for (var i = 0; i < 3; i++) Container(height: 54, margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color.fromRGBO(255, 255, 255, .06))),
                  ] else if (s == 'gjest') ...[
                    AiKort(key: const Key('cus-ai-kurv-gjest'), padding: const EdgeInsets.all(18), child: Column(children: [
                      Container(width: 48, height: 48, alignment: Alignment.center, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(255, 255, 255, .1)), child: const AeIkon(AiIk.laas, size: 22, stroke: 2.2)),
                      const SizedBox(height: 10),
                      Text(AiCopy.cus_ai_logg_inn_fortsett, style: inter(16, weight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(AiCopy.cus_ai_kurv_venter(navn), textAlign: TextAlign.center, style: inter(12.5, height: 1.4, color: const Color.fromRGBO(255, 255, 255, .72))),
                      const SizedBox(height: 12),
                      AePress(onTap: () => Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false), dy: 2, child: Container(key: const Key('cus-ai-kurv-logg-inn'), height: 46, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), gradient: const LinearGradient(colors: [Color(0xFFF9A273), Color(0xFFF26D3D)])), child: Text(const bool.fromEnvironment('SHOW_VIPPS_LOGIN', defaultValue: false) ? AiCopy.cus_ai_logg_vipps : AiCopy.cus_ai_logg_inn, style: inter(14, weight: FontWeight.w800)))),
                    ])),
                  ] else if (s == 'dekning' || s == 'vente') ...[
                    AiKort(key: Key('cus-ai-kurv-$s'), padding: const EdgeInsets.all(18), child: Column(children: [
                      if (s == 'dekning') ...[
                        Image.asset('assets/images/dashboard/find.png', height: 110),
                        const SizedBox(height: 8),
                        Text(AiCopy.cus_ai_leverer_ikke, style: inter(16, weight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [const AeIkon(AiIk.pin, size: 12, stroke: 2.4, color: Color(0xFF7FF0CB)), const SizedBox(width: 5), Flexible(child: Text(r?.address ?? '', style: inter(12, weight: FontWeight.w700, color: const Color(0xFF7FF0CB))))]),
                        const SizedBox(height: 6),
                        Text(AiCopy.cus_ai_si_fra, textAlign: TextAlign.center, style: inter(12.5, height: 1.4, color: const Color.fromRGBO(255, 255, 255, .72))),
                        const SizedBox(height: 12),
                        AePress(onTap: _venteliste, dy: 2, child: Container(key: const Key('cus-ai-venteliste'), height: 46, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), gradient: const LinearGradient(colors: [Color(0xFFF9A273), Color(0xFFF26D3D)])), child: Text(AiCopy.cus_ai_venteliste, style: inter(14, weight: FontWeight.w800)))),
                        const SizedBox(height: 8),
                        AePress(onTap: _avvis, dy: 1, child: Container(key: const Key('cus-ai-kurv-avvis'), height: 42, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color.fromRGBO(255, 255, 255, .08), border: Border.all(color: const Color.fromRGBO(255, 255, 255, .2))), child: Text(AiCopy.cus_ai_avvis, style: inter(13.5, weight: FontWeight.w800)))),
                      ] else ...[
                        Container(width: 54, height: 54, alignment: Alignment.center, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF5CE0B8)), child: const AeIkon(AiIk.hake, size: 24, stroke: 3, color: Color(0xFF0F2B33))),
                        const SizedBox(height: 10),
                        Text(AiCopy.cus_ai_paa_venteliste, style: inter(16, weight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(AiCopy.cus_ai_paa_venteliste_tx(r?.address ?? ''), textAlign: TextAlign.center, style: inter(12.5, height: 1.4, color: const Color.fromRGBO(255, 255, 255, .72))),
                        const SizedBox(height: 12),
                        AePress(onTap: _tilHjem, dy: 2, child: Container(key: const Key('cus-ai-til-hjem'), height: 46, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), gradient: const LinearGradient(colors: [Color(0xFFF9A273), Color(0xFFF26D3D)])), child: Text(AiCopy.cus_ai_til_hjem, style: inter(14, weight: FontWeight.w800)))),
                      ],
                    ])),
                  ] else if (r == null) ...[
                    AiKort(key: const Key('cus-ai-kurv-tom'), padding: const EdgeInsets.all(18), child: Column(children: [Image.asset('assets/images/dashboard/sorry.png', height: 100), const SizedBox(height: 8), Text(AiCopy.cus_ai_feil_generisk, style: inter(15, weight: FontWeight.w800)), Text(AiCopy.cus_ai_ingenting_bestilt, style: inter(12.5, color: const Color.fromRGBO(255, 255, 255, .7)))])),
                  ] else ...[
                    AiTilbud(
                      key: Key('cus-ai-kurv-$s'),
                      r: r,
                      venter: false,
                      banner: s == 'utlopt' || _gammelTotal != null ? AiBanner(tone: 'gul', tittel: AiCopy.cus_ai_tilbud_utlopt, tekst: AiCopy.cus_ai_tilbud_utlopt_tx, ikon: AiIk.oppdater) : null,
                      visFrist: true,
                      visGauge: false,
                      onFjern: _fjern,
                      gammelTotal: _gammelTotal,
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: AePress(onTap: _endre, dy: 1.5, child: AiKort(key: const Key('cus-ai-endre'), padding: const EdgeInsets.all(12), child: Row(children: [const AeIkon(AiIk.oppdater, size: 16, stroke: 2.3, color: Color(0xFF7FF0CB)), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AiCopy.cus_ai_endre_kurv, style: inter(13, weight: FontWeight.w800)), Text(AiCopy.cus_ai_endre_under, style: inter(11, color: const Color.fromRGBO(255, 255, 255, .65)))]))])))),
                      const SizedBox(width: 8),
                      AePress(onTap: _avvis, dy: 1.5, child: Container(key: const Key('cus-ai-kurv-avvis'), height: 56, padding: const EdgeInsets.symmetric(horizontal: 16), alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: const Color.fromRGBO(255, 255, 255, .08), border: Border.all(color: const Color.fromRGBO(255, 255, 255, .2))), child: Text(AiCopy.cus_ai_avvis, style: inter(13.5, weight: FontWeight.w800)))),
                    ]),
                  ],
                ],
              ),
            ),
            if (visKnapper)
              Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bunn),
                decoration: const BoxDecoration(color: Color(0xFF0B2229), border: Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, .12)))),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _linjeRad(AiIk.sykkel, r.windowDisplay, r.address, onEndre: null),
                  const SizedBox(height: 8),
                  _linjeRad(AiIk.kort, _bet == 'vipps' ? AiCopy.cus_ai_vipps : AiCopy.cus_ai_kort_ved_bet, _bet == 'vipps' ? AiCopy.cus_ai_godkjenner_vipps : AiCopy.cus_ai_bekreftes_faceid, onEndre: () => setState(() => _bet = _bet == 'vipps' ? 'card' : 'vipps')),
                  const SizedBox(height: 12),
                  KurvBetal(key: const Key('cus-ai-betal'), total: r.total.ore / 100, onPay: _betal, busy: _betaler),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [const AeIkon(AiIk.laas, size: 11, stroke: 2.4, color: Color.fromRGBO(255, 255, 255, .6)), const SizedBox(width: 5), Flexible(child: Text(AiCopy.cus_ai_ingen_betdata(navn), maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(11, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .6))))]),
                ]),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _linjeRad(String ik, String navn, String under, {VoidCallback? onEndre}) => Row(children: [
    Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), color: const Color.fromRGBO(255, 255, 255, .1)), child: AeIkon(ik, size: 16, stroke: 2.2)),
    const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(navn, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(13.5, weight: FontWeight.w800)), Text(under, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(11.5, color: const Color.fromRGBO(255, 255, 255, .65)))])),
    if (onEndre != null) AePress(onTap: onEndre, dy: 1, child: Row(children: [Text(AiCopy.cus_ai_endre, style: inter(12.5, weight: FontWeight.w800, color: const Color(0xFF7FF0CB))), const SizedBox(width: 3), const AeIkon(AiIk.pil, size: 11, stroke: 2.4, color: Color(0xFF7FF0CB))])),
  ]);
}
