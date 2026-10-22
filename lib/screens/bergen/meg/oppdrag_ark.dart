// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';

import '../../../data/points/points_models.dart';
import 'meg_ark.dart';
import 'meg_copy_a4.dart';
import 'mork_rad.dart';

/// «Ukens oppdrag» (Customer Step 12; Points spec §6, design Meg vals
/// `oppdragNy` / `oppdragTatt` / `oppdragGodta` / `oppdragNei`): the dark
/// Ark from Meg's mission row — the mission's title and wording, how it
/// counts (`+N poeng når ordren er levert`), its status, and for a new
/// mission «Godta» / «Ikke dette» (one decline a week, `MISSION_DECLINE_LIMIT`
/// otherwise). Accepting and declining happen on Meg after the sheet closes.
abstract final class OppdragArk {
  static String status(Mission m) => switch (m.state) {
    'completed' => '${A4MegCopy.cus_meg_oppdrag_ferdig} · ${A4MegCopy.a4_meg_pluss(m.points)}',
    _ when m.accepted => '${A4MegCopy.cus_meg_oppdrag_tatt} · ${A4MegCopy.a4_meg_oppdrag_status(m.progress, m.target)}',
    _ => A4MegCopy.cus_meg_oppdrag_nytt,
  };

  static bool ny(Mission m) => m.state == 'active' && !m.accepted;

  /// Resolves to `godta`, `nei` or null (closed).
  static Future<String?> vis(BuildContext context, Mission m) => showMegArk<String>(
    context,
    key: const Key('cus-meg-oppdrag-ark'),
    mork: true,
    title: m.title,
    subtitle: m.body.isEmpty ? A4MegCopy.cus_meg_oppdrag_ark_linje : m.body,
    body: (ctx, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MorkRad(delayMs: 0, ikon: MorkIk.flagg, navn: A4MegCopy.cus_meg_oppdrag_slik, under: A4MegCopy.cus_meg_oppdrag_poeng(m.points), onTap: () {}),
        const SizedBox(height: 8),
        MorkRad(key: const Key('cus-meg-oppdrag-status'), delayMs: 40, ikon: MorkIk.stjerne, navn: A4MegCopy.cus_meg_oppdrag_status, under: status(m), onTap: () {}),
        if (m.body.isNotEmpty) ...[
          const SizedBox(height: 8),
          MorkRad(delayMs: 80, ikon: MorkIk.bok, navn: A4MegCopy.a4_meg_oppdrag, under: A4MegCopy.cus_meg_oppdrag_ark_linje, onTap: () {}),
        ],
      ],
    ),
    primary: ny(m)
        ? MegArkButton(key: const Key('cus-meg-oppdrag-godta'), label: A4MegCopy.a4_meg_godta, onTap: () => Navigator.of(context).pop('godta'))
        : MegArkButton(key: const Key('cus-meg-oppdrag-lukk'), label: A4MegCopy.a4_meg_lukk, onTap: () => Navigator.of(context).pop()),
    secondary: ny(m) ? MegArkButton(key: const Key('cus-meg-oppdrag-nei'), label: A4MegCopy.a4_meg_ikke_dette, onTap: () => Navigator.of(context).pop('nei')) : null,
  );
}
