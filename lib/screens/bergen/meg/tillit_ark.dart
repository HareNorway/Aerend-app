// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';

import '../../../data/aegil/aegil_app_models.dart';
import 'meg_ark.dart';
import 'meg_copy_a4.dart';

/// «Tillitsregnskap» (Customer Step 5; design kArk `tillit`, from Meg's
/// «Ægil sparte deg N kr» row): the month's line — advice against Ærend's
/// own interest, wait recommendations, cheaper elsewhere taken, what Ægil
/// saved — and one row per finding (`GET agent/me/trust-ledger` `lines`),
/// then «Lukk».
abstract final class TillitArk {
  static const tittel = 'Tillitsregnskap';
  static const tom = 'Ingenting å regne med ennå denne måneden.';

  /// `tl.mot + ' råd mot egen interesse · ' + tl.vent + ' vent-anbefalinger · ' + tl.billigere + ' billigere andre steder som du tok. Ægil sparte deg ' + S.saldo.sparte + ' kr denne måneden.'`
  static String linje(TrustLedger t) =>
      '${t.againstInterestShown} råd mot egen interesse · ${t.waitRecommended} vent-anbefalinger · ${t.cheaperElsewhereTaken} billigere andre steder som du tok. Ægil sparte deg ${t.savedKr} kr denne måneden.';

  static Future<void> vis(BuildContext context, TrustLedger t) => showMegArk<void>(
    context,
    key: const Key('cus-meg-tillit-ark'),
    title: tittel,
    subtitle: linje(t),
    body: (ctx, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (t.lines.isEmpty) const MegArkRow(title: tom),
        for (final l in t.lines) MegArkRow(title: l.text),
      ],
    ),
    primary: MegArkButton(key: const Key('cus-meg-tillit-lukk'), label: A4MegCopy.a4_meg_lukk, onTap: () => Navigator.of(context).pop()),
  );
}
