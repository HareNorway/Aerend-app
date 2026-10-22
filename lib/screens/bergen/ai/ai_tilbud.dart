// ignore_for_file: non_constant_identifier_names
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../networking/ops/cus_api.dart';
import '../../common/auth/launch/lf_css.dart';
import '../aegil/aegil_bits.dart';
import 'ai_bits.dart';
import 'ai_copy.dart';

/// Customer plan Step 14 — the offer as both «Handlekurv fra assistent» and
/// «Bekreft bestilling» draw it (design `aiTilbudVals`, modes C and D): the
/// assistant's log card («{AI} bygde handlekurven» / «{AI} ber om å
/// bestille» with the ticked steps), the lines with their availability, the
/// sold-out row's «Fjern», «Tilbudet ditt» with the countdown ring, the
/// fees, the window, the address, the total (with the old one when a new
/// quote replaced an expired one), and the gauge against the customer's cap.
class AiTilbud extends StatelessWidget {
  const AiTilbud({super.key, required this.r, required this.venter, this.laster = false, this.banner, this.visFrist = true, this.visGauge = false, this.onFjern, this.sekunder, this.gammelTotal, this.stoppTx});

  final CusAiRequest r;

  /// D («Bekreft innen», the last step waits on the customer) or C («Tilbudet gjelder i»).
  final bool venter;
  final bool laster;
  final Widget? banner;
  final bool visFrist;
  final bool visGauge;
  final void Function(CusAiLinje)? onFjern;
  final int? sekunder;
  final CusMoney? gammelTotal;

  /// The last log step replaced by a stopped line («Forespørselen utløp · ingenting bestilt»).
  final String? stoppTx;

  @override
  Widget build(BuildContext context) {
    final n = r.assistant;
    final steg = r.log.isEmpty
        ? [(AiCopy.cus_ai_akt('search_products'), ''), (AiCopy.cus_ai_akt('create_cart'), ''), (venter ? AiCopy.cus_ai_akt('start_checkout') : (laster ? AiCopy.cus_ai_henter_tilbud : AiCopy.cus_ai_akt('quote')), '')]
        : [for (final l in r.log) (l.text, aiTid(l.at))];
    final utsolgt = r.harUtsolgt;
    final over = r.overCap;
    final cap = r.capPerOrder;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // The log card.
      AiKort(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          AiMerke(n, size: 36),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(venter ? AiCopy.cus_ai_ber_om(n) : AiCopy.cus_ai_bygde(n), style: inter(14, weight: FontWeight.w800)),
            Text(venter ? AiCopy.cus_ai_foresporsel(r.store) : AiCopy.cus_ai_apnet_fra(n), style: inter(11.5, color: const Color.fromRGBO(255, 255, 255, .65))),
          ])),
        ]),
        const SizedBox(height: 10),
        for (final (i, s) in steg.indexed)
          () {
            final sist = i == steg.length - 1;
            final stopp = sist && stoppTx != null;
            final aktiv = sist && (venter || laster) && !stopp;
            return AeOnce(kind: AeInn.stigOpp, ms: 380, delay: 150.0 + i * 220, child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                SizedBox(width: 20, height: 20, child: stopp
                    ? const AeIkon(AiIk.kryss, size: 12, stroke: 2.6, color: Color.fromRGBO(255, 255, 255, .62))
                    : (aktiv && laster
                        ? const Padding(padding: EdgeInsets.all(3), child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7FF0CB)))
                        : (aktiv ? Center(child: Container(width: 9, height: 9, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFC8A8)))) : Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF5CE0B8)), child: const AeIkon(AiIk.hake, size: 11, stroke: 3, color: Color(0xFF0F2B33)))))),
                const SizedBox(width: 8),
                Expanded(child: Text(stopp ? stoppTx! : s.$1, style: inter(12.5, weight: FontWeight.w700, color: stopp ? const Color.fromRGBO(255, 255, 255, .62) : (aktiv && venter ? const Color(0xFFFFC8A8) : Colors.white)))),
                if (s.$2.isNotEmpty) Text(s.$2, style: aeTab(inter(11, color: const Color.fromRGBO(255, 255, 255, .55)))),
              ]),
            ));
          }(),
      ])),
      const SizedBox(height: 10),
      if (banner != null) banner!,
      // The lines.
      AiKort(padding: const EdgeInsets.fromLTRB(12, 10, 12, 6), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [Text(AiCopy.cus_ai_varer, style: inter(13.5, weight: FontWeight.w800)), const SizedBox(width: 8), Text(AiCopy.cus_ai_antall_varer(r.lines.length), style: inter(11.5, color: const Color.fromRGBO(255, 255, 255, .6))), const Spacer(), Text(r.subtotal.display, style: aeTab(inter(13.5, weight: FontWeight.w800)))]),
        const SizedBox(height: 4),
        for (final (i, l) in r.lines.indexed)
          AeOnce(kind: AeInn.stigOpp, ms: 360, delay: 100.0 + i * 60, child: Container(
            key: Key('cus-ai-linje-${l.productId}'),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(border: i > 0 ? const Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, .1))) : null),
            child: Opacity(opacity: l.available ? 1 : .62, child: Row(children: [
              Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), color: const Color.fromRGBO(255, 255, 255, .1)), child: const AeIkon(AiIk.pose, size: 15, stroke: 2.2)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.name, style: inter(13.5, weight: FontWeight.w800).copyWith(decoration: l.available ? null : TextDecoration.lineThrough)),
                Text('${l.quantity}×${l.options.isNotEmpty ? ' · ${l.options.join(', ')}' : ''}', style: inter(11.5, color: const Color.fromRGBO(255, 255, 255, .62))),
                if (!l.available) Text(AiCopy.cus_ai_utsolgt_naa, style: inter(11, weight: FontWeight.w800, color: const Color(0xFFFFC8A8))),
              ])),
              Text(l.lineTotal.display, style: aeTab(inter(13.5, weight: FontWeight.w800))),
            ])),
          )),
        if (utsolgt && onFjern != null)
          () {
            final s = r.lines.firstWhere((l) => !l.available);
            return Container(
              key: const Key('cus-ai-utsolgt-rad'),
              margin: const EdgeInsets.only(top: 6, bottom: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color.fromRGBO(245, 196, 81, .12), border: Border.all(color: const Color.fromRGBO(245, 196, 81, .4))),
              child: Row(children: [
                const AeIkon(AiIk.advarsel, size: 16, stroke: 2.2, color: Color(0xFFFFE08A)),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AiCopy.cus_ai_fjern_tx(s.name), style: inter(12.5, weight: FontWeight.w800)), Text(AiCopy.cus_ai_fjern_under, style: inter(11, color: const Color.fromRGBO(255, 255, 255, .7)))])),
                AePress(onTap: () => onFjern!(s), dy: 1.5, child: Container(key: const Key('cus-ai-fjern'), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), gradient: const LinearGradient(colors: [Color(0xFFF9A273), Color(0xFFF26D3D)])), child: Text(AiCopy.cus_ai_fjern, style: inter(12, weight: FontWeight.w800)))),
              ]),
            );
          }(),
      ])),
      const SizedBox(height: 10),
      // «Tilbudet ditt».
      AiKort(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF5CE0B8))),
          const SizedBox(width: 7),
          Expanded(child: Text(AiCopy.cus_ai_tilbudet_ditt.toUpperCase(), style: inter(11, weight: FontWeight.w800, em: .1, color: const Color(0xFF7FF0CB)))),
          if (visFrist) AiFrist(sekunder: sekunder ?? r.secondsLeft, label: venter ? AiCopy.cus_ai_bekreft_innen : AiCopy.cus_ai_tilbudet_gjelder),
        ]),
        const SizedBox(height: 10),
        _rad(AiIk.pose, AiCopy.cus_ai_varer, null, r.subtotal.display),
        _rad(AiIk.sykkel, AiCopy.cus_ai_levering, r.deliveryFee.ore == 0 && r.serviceFee.ore == 0 ? null : [if (r.deliveryFee.ore > 0) r.deliveryFee.display, if (r.serviceFee.ore > 0) '+${r.serviceFee.display}'].join(' · '), CusMoney(ore: r.deliveryFee.ore + r.serviceFee.ore, display: AiCopy.kr((r.deliveryFee.ore + r.serviceFee.ore) ~/ 100)).display),
        _rad(AiIk.klokke, AiCopy.cus_ai_leveringsvindu, null, r.windowDisplay),
        _rad(AiIk.pin, AiCopy.cus_ai_leveres_til, null, r.address),
        const Divider(color: Color.fromRGBO(255, 255, 255, .14), height: 18),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(gammelTotal != null ? AiCopy.cus_ai_ny_total : AiCopy.cus_ai_totalt, style: inter(13, weight: FontWeight.w800)),
            if (gammelTotal != null) Text(gammelTotal!.display, style: aeTab(inter(12, color: const Color.fromRGBO(255, 255, 255, .55)).copyWith(decoration: TextDecoration.lineThrough))),
          ])),
          if (gammelTotal != null) Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color(0xFFF2C14E)), child: Text(AiCopy.cus_ai_ny, style: inter(10.5, weight: FontWeight.w800, color: const Color(0xFF3A2708)))),
          Text(r.total.display, key: const Key('cus-ai-total'), style: aeTab(jakarta(22, weight: FontWeight.w800))),
        ]),
        if (visGauge && cap != null) ...[
          const SizedBox(height: 10),
          Row(children: [
            AeIkon(AiIk.skjold, size: 13, stroke: 2.4, color: over ? const Color(0xFFFFE08A) : const Color(0xFF7FF0CB)),
            const SizedBox(width: 6),
            Expanded(child: Text(over ? AiCopy.cus_ai_over(cap.kr) : AiCopy.cus_ai_innenfor(cap.kr), style: inter(11.5, weight: FontWeight.w800, color: over ? const Color(0xFFFFE08A) : const Color(0xFF7FF0CB)))),
            Text(AiCopy.cus_ai_av(r.total.display, cap.display), style: aeTab(inter(11, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .7)))),
          ]),
          const SizedBox(height: 6),
          () {
            final skala = (cap.ore * 1.3 > r.total.ore * 1.08 ? cap.ore * 1.3 : r.total.ore * 1.08).toDouble();
            return Stack(children: [
              ClipRRect(borderRadius: BorderRadius.circular(99), child: SizedBox(height: 6, child: Stack(children: [const Positioned.fill(child: ColoredBox(color: Color.fromRGBO(255, 255, 255, .12))), FractionallySizedBox(widthFactor: (r.total.ore / skala).clamp(0.02, 1.0), heightFactor: 1, alignment: Alignment.centerLeft, child: DecoratedBox(decoration: BoxDecoration(gradient: over ? const LinearGradient(colors: [Color(0xFFF7D27A), Color(0xFFE4B040)]) : const LinearGradient(colors: [Color(0xFF7FF0CB), Color(0xFF5CE0B8)]))))]))),
              const Positioned(left: null, top: -3, child: FractionallySizedBox(child: SizedBox())),
              Align(alignment: Alignment(((cap.ore / skala).clamp(0.0, 1.0) * 2) - 1, 0), child: Container(width: 2, height: 12, color: Colors.white)),
            ]);
          }(),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('0 kr', style: inter(10.5, color: const Color.fromRGBO(255, 255, 255, .5))), Text(AiCopy.cus_ai_grense(cap.kr), style: inter(10.5, color: const Color.fromRGBO(255, 255, 255, .5)))]),
        ],
      ])),
    ]);
  }

  static Widget _rad(String ik, String navn, String? under, String verdi) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      AeIkon(ik, size: 14, stroke: 2.2, color: const Color.fromRGBO(255, 255, 255, .75)),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(navn, style: inter(12.5, weight: FontWeight.w700)), if (under != null) Text(under, style: inter(10.5, color: const Color.fromRGBO(255, 255, 255, .55)))])),
      Flexible(child: Text(verdi, textAlign: TextAlign.end, maxLines: 2, style: aeTab(inter(12.5, weight: FontWeight.w800)))),
    ]),
  );
}

/// The countdown ring and m:ss (design `aiTid`): mint, amber under a minute.
class AiFrist extends StatefulWidget {
  const AiFrist({super.key, required this.sekunder, required this.label, this.total = 600, this.onUtlopt});

  final int sekunder;
  final String label;
  final int total;
  final VoidCallback? onUtlopt;

  @override
  State<AiFrist> createState() => _AiFristState();
}

class _AiFristState extends State<AiFrist> {
  late int _s = widget.sekunder;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_s <= 0) {
        _t?.cancel();
        return;
      }
      setState(() => _s--);
      if (_s == 0) widget.onUtlopt?.call();
    });
  }

  @override
  void didUpdateWidget(covariant AiFrist old) {
    super.didUpdateWidget(old);
    if (old.sekunder != widget.sekunder) _s = widget.sekunder;
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _s < 60 ? const Color(0xFFF2C14E) : const Color(0xFF5CE0B8);
    final tx = '${_s ~/ 60}:${(_s % 60).toString().padLeft(2, '0')}';
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(widget.label, style: inter(10, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .6))), Text(tx, key: const Key('cus-ai-frist'), style: aeTab(inter(14, weight: FontWeight.w800, color: c)))]),
      const SizedBox(width: 8),
      SizedBox(width: 30, height: 30, child: CircularProgressIndicator(value: (_s / widget.total).clamp(0.0, 1.0), strokeWidth: 3, color: c, backgroundColor: const Color.fromRGBO(255, 255, 255, .14))),
    ]);
  }
}

/// The design's sample request for the harness, on local data (Torgboden) —
/// never the seeded Sandviken Bakeri figures.
CusAiRequest aiSampleRequest({String navn = 'Claude', String state = 'normal', bool over = false}) {
  final lines = [
    const CusAiLinje(productId: 818, lineId: 1, name: 'Sitron', quantity: 2, unitPrice: CusMoney(ore: 1000, display: '10 kr'), lineTotal: CusMoney(ore: 2000, display: '20 kr')),
    CusAiLinje(productId: 819, lineId: 2, name: 'Remulade', quantity: 1, unitPrice: const CusMoney(ore: 2900, display: '29 kr'), lineTotal: const CusMoney(ore: 2900, display: '29 kr'), available: state != 'utsolgt'),
    if (over) const CusAiLinje(productId: 820, lineId: 3, name: 'Fiskesuppe for fire', quantity: 1, unitPrice: CusMoney(ore: 52000, display: '520 kr'), lineTotal: CusMoney(ore: 52000, display: '520 kr')),
  ];
  final sub = lines.fold<int>(0, (s, l) => s + l.lineTotal.ore);
  final tot = sub + 3900 + 1500;
  final naa = DateTime.now();
  return CusAiRequest(
    id: 'q_sample', state: state, assistant: navn, vendor: AiNavn.vendor(navn), store: 'Torgboden', storeLine: 'Torggaten 9, Bergen',
    log: [CusAiLogg(tool: 'search_products', text: 'Søkte i menyer', at: naa.subtract(const Duration(minutes: 3))), CusAiLogg(tool: 'create_cart', text: 'Bygde handlekurv', at: naa.subtract(const Duration(minutes: 2))), CusAiLogg(tool: 'quote', text: 'Hentet tilbud fra Ærend', at: naa.subtract(const Duration(minutes: 1))), CusAiLogg(tool: 'start_checkout', text: 'Ber om å bestille · venter på deg', at: naa)],
    lines: lines, subtotal: CusMoney(ore: sub, display: AiCopy.kr(sub ~/ 100)), deliveryFee: const CusMoney(ore: 3900, display: '39 kr'), serviceFee: const CusMoney(ore: 1500, display: '15 kr'), total: CusMoney(ore: tot, display: AiCopy.kr(tot ~/ 100)),
    windowDisplay: '18:12–18:22', address: 'Torggaten 9', expiresAt: naa.add(const Duration(seconds: 580)), secondsLeft: state == 'utlopt' ? 0 : 580,
    capPerOrder: const CusMoney(ore: 50000, display: '500 kr'), overCap: over || tot > 50000, covered: state != 'dekning', waitlistId: state == 'dekning' ? 'wl_sample' : null, paymentPref: 'vipps', linkId: 1,
  );
}
