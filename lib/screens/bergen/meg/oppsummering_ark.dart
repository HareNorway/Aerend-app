// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';

import '../../../data/aegil/aegil_app_models.dart';
import '../../../data/points/league_models.dart';
import '../../../data/points/points_models.dart';
import 'meg_ark.dart';
import 'meg_copy_a4.dart';
import 'mork_rad.dart';

/// The month's summary (Customer Step 12; Points spec §8 «monthly summary
/// (1st): Meg card, Varsler — points earned, tier and distance to the next,
/// rank, best mission, the savings line»). The dark Ark from Meg's «Oktober i
/// poeng» row: `GET agent/me/monthly-summary` plus what Meg already holds
/// (the balance, the league, the mission). Rows without data stay out.
abstract final class OppsummeringArk {
  static String tittel(MonthlySummary s) => A4MegCopy.cus_meg_oppsummering_rad(A4MegCopy.cus_meg_maaned(s.month));

  static Future<void> vis(BuildContext context, {required MonthlySummary s, PointsBalance? balance, League? league, Mission? mission}) {
    final b = balance;
    final nivaa = b == null
        ? null
        : (b.nextTierName == null || b.pointsToNextTier == null ? '${b.tierName} · ${A4MegCopy.a4_meg_hoyeste}' : '${b.tierName} · ${A4MegCopy.a4_meg_avstand(b.pointsToNextTier!, b.nextTierName!)}');
    final liga = league == null
        ? null
        : (league.optedIn && league.own != null ? A4MegCopy.a4_meg_plass(league.own!.rank) : A4MegCopy.cus_meg_opps_liga_ute);
    final oppdrag = mission != null && mission.state == 'completed' ? '${mission.title} · ${A4MegCopy.a4_meg_pluss(mission.points)}' : null;
    var i = 0;
    MorkRad rad(Key key, String ikon, String navn, String under) => MorkRad(key: key, delayMs: 40.0 * i++, ikon: ikon, navn: navn, under: under, onTap: () {});
    return showMegArk<void>(
      context,
      key: const Key('cus-meg-oppsummering-ark'),
      mork: true,
      title: tittel(s),
      subtitle: A4MegCopy.cus_meg_oppsummering_linje,
      body: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          rad(const Key('cus-opps-opptjent'), MorkIk.opp, A4MegCopy.cus_meg_opps_opptjent, A4MegCopy.cus_meg_opps_poeng(s.earned)),
          const SizedBox(height: 8),
          rad(const Key('cus-opps-brukt'), MorkIk.hylle, A4MegCopy.cus_meg_opps_brukt, A4MegCopy.cus_meg_opps_poeng(s.spent)),
          if (s.expired > 0) ...[const SizedBox(height: 8), rad(const Key('cus-opps-utlopt'), MorkIk.klokke, A4MegCopy.cus_meg_opps_utlopt, A4MegCopy.cus_meg_opps_poeng(s.expired))],
          if (nivaa != null) ...[const SizedBox(height: 8), rad(const Key('cus-opps-nivaa'), MorkIk.stjerne, A4MegCopy.cus_meg_opps_nivaa, nivaa)],
          if (liga != null) ...[const SizedBox(height: 8), rad(const Key('cus-opps-liga'), MorkIk.pokal, A4MegCopy.cus_meg_opps_liga, liga)],
          if (oppdrag != null) ...[const SizedBox(height: 8), rad(const Key('cus-opps-oppdrag'), MorkIk.flagg, A4MegCopy.cus_meg_opps_oppdrag, oppdrag)],
          const SizedBox(height: 8),
          rad(const Key('cus-opps-sparte'), MorkIk.skjold, A4MegCopy.cus_meg_opps_sparte, '${A4MegCopy.cus_meg_opps_kr(s.savedKr)} · ${A4MegCopy.cus_meg_opps_handlinger(s.actions)}'),
        ],
      ),
      primary: MegArkButton(key: const Key('cus-meg-oppsummering-lukk'), label: A4MegCopy.a4_meg_lukk, onTap: () => Navigator.of(context).pop()),
    );
  }
}
