// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

import '../../../data/aegil/aegil_repo.dart';
import '../../../data/aegil/against_interest_models.dart';
import '../../../utils/utils.dart';
import '../kit/bergen_kit.dart';
import 'a3_services.dart' show a3Try;
import 'meg_ark.dart';
import 'mork_rad.dart';

/// Copy for «Påminnelser» (Customer Step 0, D-K20; not in the design — the
/// dark Ark and its rows are the design's components).
abstract final class CusPaaminnelserCopy {
  static bool get _en => resolveSelectedLanguage() == 'en';
  static String _t(String no, String en) => _en ? en : no;

  static String get cus_meg_paaminnelser => _t('Påminnelser', 'Reminders');
  static String get cus_meg_paaminnelser_sub => _t('Priser og varer Ægil sier fra om', 'Prices and items Ægil tells you about');
  static String get cus_paam_linje => _t('Trykk på en for å avslutte den.', 'Tap one to stop it.');
  static String get cus_paam_tom => _t('Ingen påminnelser', 'No reminders');
  static String get cus_paam_tom_under => _t('Ber du Ægil si fra om en pris eller en vare, ligger det her.', 'When you ask Ægil to tell you about a price or an item, it shows here.');
  static String get cus_paam_feil => _t('Fikk ikke hentet påminnelsene. Prøv igjen.', 'Could not load the reminders. Try again.');
  static String get cus_paam_vare => _t('En vare', 'An item');
  static String cus_paam_pris_under(int kr) => _t('Når prisen er under $kr kr', 'When the price is under $kr kr');
  static String get cus_paam_pris => _t('Når prisen går ned', 'When the price drops');
  static String get cus_paam_lager => _t('Når den er tilbake', 'When it is back');
  static String cus_paam_til(DateTime d) => _t('til ${d.day}.${d.month}.', 'until ${d.day}/${d.month}');
  static String get cus_paam_avslutt => _t('Avslutt', 'Stop');
  static String cus_paam_avsluttet(String navn) => _t('Avsluttet · $navn', 'Stopped · $navn');
  static String get cus_paam_ferdig => _t('Ferdig', 'Done');
}

/// «Påminnelser» (Meg): what Ægil is waiting to tell the customer —
/// `agent/me/reminders`, one tap stops one (`DELETE`).
Future<void> visPaaminnelser(BuildContext context, {required AegilRepo repo}) async {
  final liste = await a3Try(repo.reminders);
  if (!context.mounted) return;
  var rader = [...?liste];
  final avsluttet = <int>{};
  return showMegArk<void>(
    context,
    key: const Key('cus-meg-paaminnelser'),
    mork: true,
    title: CusPaaminnelserCopy.cus_meg_paaminnelser,
    subtitle: liste == null ? CusPaaminnelserCopy.cus_paam_feil : (liste.isEmpty ? null : CusPaaminnelserCopy.cus_paam_linje),
    body: (ctx, setArk) {
      if (rader.isEmpty) {
        return MorkRad(
          key: const Key('cus-paam-tom'),
          delayMs: 0,
          ikon: MorkIk.bjelle,
          navn: CusPaaminnelserCopy.cus_paam_tom,
          under: CusPaaminnelserCopy.cus_paam_tom_under,
          onTap: () {},
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, r) in rader.indexed) ...[
            if (i > 0) const SizedBox(height: 8),
            MorkRad(
              key: Key('cus-paam-${r.kind}-${r.id}'),
              delayMs: i * 40.0,
              ikon: r.kind == AegilRepo.kAvailabilityKind ? MorkIk.pose : MorkIk.ned,
              navn: (r.productName ?? '').trim().isEmpty ? CusPaaminnelserCopy.cus_paam_vare : r.productName!.trim(),
              under: _under(r),
              verdi: CusPaaminnelserCopy.cus_paam_avslutt,
              onTap: () async {
                if (!avsluttet.add(r.id)) return;
                final ok = await repo.cancelReminder(r);
                if (!ctx.mounted) return;
                if (!ok) {
                  avsluttet.remove(r.id);
                  showBergenToast(ctx, BergenRoutes.ikkeLagret, icon: Icons.error_outline_rounded);
                  return;
                }
                setArk(() => rader = rader.where((x) => x != r).toList());
                showBergenToast(ctx, CusPaaminnelserCopy.cus_paam_avsluttet(r.productName ?? CusPaaminnelserCopy.cus_paam_vare));
              },
            ),
          ],
        ],
      );
    },
    primary: MegArkButton(
      key: const Key('cus-paam-ferdig'),
      label: CusPaaminnelserCopy.cus_paam_ferdig,
      onTap: () => Navigator.of(context).pop(),
    ),
  );
}

String _under(AgentReminderItem r) {
  final hva = r.kind == AegilRepo.kAvailabilityKind
      ? CusPaaminnelserCopy.cus_paam_lager
      : r.targetPriceOre != null
          ? CusPaaminnelserCopy.cus_paam_pris_under((r.targetPriceOre! / 100).round())
          : CusPaaminnelserCopy.cus_paam_pris;
  final til = r.expiresAt?.toLocal();
  return til == null ? hva : '$hva · ${CusPaaminnelserCopy.cus_paam_til(til)}';
}
