// ignore_for_file: non_constant_identifier_names
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../networking/ops/cus_api.dart';
import '../kit/bergen_kit.dart';
import '../meg/meg_ark.dart';
import 'ai_betaling.dart';
import 'ai_bits.dart';
import 'ai_copy.dart';
import 'ai_store.dart';
import 'ai_tilbud.dart';

/// Customer plan Step 14 — «Bekreft bestilling fra {AI}» (design `aiBekreft`,
/// mode D): the request as a sheet from the push, a Varsler item or the
/// «Denne bestillingen trenger din bekreftelse» error — normal («Bekreft og
/// betal»), over the cap («Bekreft likevel»), payment failed («Prøv igjen» /
/// «Bytt betalingsmåte»), expired and withdrawn («Lukk»). «Avvis» declines.
///
/// Customer v2 Step 3 (live): the states come from the server (`over`, `betaler`, `feilet`, `trukket`); «Bekreft
/// likevel» is the explicit second confirmation over a cap (D2-4); while Vipps runs the sheet hands over to
/// «Handlekurv fra assistent», which asks for the payment's answer on the way back (D2-5).
abstract final class AiBekreft {
  /// [tilstand] forces a state for the harness: `normal` | `over` | `feilet` | `utlopt` | `trukket` | `faceid` | `vipps`.
  static Future<void> vis(BuildContext context, CusAiRequest request, {String? tilstand, bool harness = false}) async {
    var r = request;
    var feilet = tilstand == 'feilet';
    var bet = r.paymentPref == 'card' ? 'card' : 'vipps';
    String ts() => feilet || r.state == 'feilet'
        ? 'feilet'
        : (tilstand == 'trukket' || r.state == 'trukket' || r.state == 'replaced'
            ? 'trukket'
            : (r.state == 'betaler'
                ? 'betaler'
                : (tilstand == 'utlopt' || r.state == 'utlopt' || r.secondsLeft <= 0 ? 'utlopt' : (tilstand == 'over' || r.state == 'over' || r.overCap ? 'over' : 'normal'))));
    Future<void> avvis(BuildContext ctx) async {
      if (!harness) await AiStore.instance.api.aiRequestDecline(r.id);
      if (!ctx.mounted) return;
      Navigator.of(ctx).pop();
      showBergenToast(ctx, AiCopy.cus_ai_avvist);
    }
    Future<void> betal(BuildContext ctx, void Function(void Function()) setState) async {
      final res = await AiBetaling.betal(ctx, r, payment: bet, harness: harness, overOk: ts() == 'over');
      if (!ctx.mounted) return;
      if (res.ok) {
        Navigator.of(ctx).pop();
        return;
      }
      // Vipps is open: the request screen waits for the way back and asks for the answer.
      if (res.feil == 'venter') {
        Navigator.of(ctx).pop();
        BergenRoutes.push<void>(ctx, '/bergen/ai/foresporsel/${r.id}');
        return;
      }
      if (res.feil == 'payment' || res.feil == 'failed') setState(() => feilet = true);
      if (res.feil == 'quote_expired') setState(() => r = CusAiRequest.fromJson({'id': r.id, 'state': 'utlopt', 'assistant': {'name': r.assistant, 'vendor': r.vendor}, 'store': {'name': r.store}}));
    }
    if (tilstand == 'faceid' || tilstand == 'vipps') {
      WidgetsBinding.instance.addPostFrameCallback((_) => AiBetaling.betal(context, r, payment: tilstand == 'vipps' ? 'vipps' : 'card', harness: true));
    }
    await showMegArk<void>(
      context,
      key: const Key('cus-ai-bekreft'),
      mork: true,
      title: AiCopy.cus_ai_bekreft_tittel(r.assistant),
      subtitle: AiCopy.cus_ai_bekreft_linje(r.store, bet == 'vipps' ? AiCopy.cus_ai_med_vipps : AiCopy.cus_ai_med_kort),
      body: (ctx, setState) {
        final t = ts();
        final over = t == 'over';
        final banner = switch (t) {
          'utlopt' => AiBanner(tone: 'graa', tittel: AiCopy.cus_ai_for_utlopt, tekst: AiCopy.cus_ai_for_utlopt_tx(r.assistant), ikon: AiIk.klokke),
          'trukket' => AiBanner(tone: 'graa', tittel: AiCopy.cus_ai_trukket(r.assistant), tekst: AiCopy.cus_ai_trukket_tx, ikon: AiIk.kryss),
          'feilet' => AiBanner(tone: 'rod', tittel: AiCopy.cus_ai_bet_feilet, tekst: AiCopy.cus_ai_bet_feilet_tx, ikon: AiIk.kort),
          'over' => AiBanner(tone: 'gul', tittel: AiCopy.cus_ai_over_banner(r.capPerOrder?.kr ?? 0), tekst: AiCopy.cus_ai_over_banner_tx, ikon: AiIk.skjold),
          'betaler' => AiBanner(tone: 'gul', tittel: AiCopy.cus_ai_venter_betaling, tekst: AiCopy.cus_ai_venter_betaling_tx, ikon: AiIk.kort),
          _ => null,
        };
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AiTilbud(
            key: Key('cus-ai-bekreft-$t'),
            r: r,
            venter: true,
            banner: banner,
            visFrist: t != 'utlopt' && t != 'trukket',
            visGauge: t != 'utlopt' && t != 'trukket' && r.capPerOrder != null,
            stoppTx: t == 'utlopt' ? AiCopy.cus_ai_for_utlopt_steg : (t == 'trukket' ? AiCopy.cus_ai_trukket(r.assistant) : null),
            sekunder: t == 'utlopt' ? 0 : null,
          ),
          if (over) const SizedBox(height: 4),
        ]);
      },
      primaryBuilder: (ctx) {
        final t = ts();
        return switch (t) {
          'utlopt' || 'trukket' => MegArkButton(key: const Key('cus-ai-bekreft-lukk'), label: AiCopy.cus_ai_lukk, onTap: () => Navigator.of(ctx).pop()),
          'feilet' => MegArkButton(key: const Key('cus-ai-bekreft-igjen'), label: AiCopy.cus_ai_prov_igjen, onTap: () {
            feilet = false;
            betal(ctx, (f) { f(); (ctx as Element).markNeedsBuild(); });
          }),
          'betaler' => MegArkButton(key: const Key('cus-ai-bekreft-sjekk'), label: AiCopy.cus_ai_sjekk_betaling, onTap: () async {
            final res = await AiBetaling.sjekk(ctx, r, forsok: 1);
            if (res.ok && ctx.mounted) Navigator.of(ctx).pop();
          }),
          'over' => MegArkButton(key: const Key('cus-ai-bekreft-likevel'), label: AiCopy.cus_ai_bekreft_likevel, onTap: () => betal(ctx, (f) { f(); (ctx as Element).markNeedsBuild(); })),
          _ => MegArkButton(key: const Key('cus-ai-bekreft-cta'), label: AiCopy.cus_ai_bekreft_betal, onTap: () => betal(ctx, (f) { f(); (ctx as Element).markNeedsBuild(); })),
        };
      },
      secondary: MegArkButton(key: const Key('cus-ai-bekreft-avvis'), label: feilet ? AiCopy.cus_ai_bytt_bet : AiCopy.cus_ai_avvis, onTap: () {
        if (feilet) {
          bet = bet == 'vipps' ? 'card' : 'vipps';
          feilet = false;
          showBergenToast(context, AiCopy.cus_ai_betaler_med(bet == 'vipps' ? AiCopy.cus_ai_med_vipps : AiCopy.cus_ai_med_kort));
          return;
        }
        avvis(context);
      }),
    );
  }
}
