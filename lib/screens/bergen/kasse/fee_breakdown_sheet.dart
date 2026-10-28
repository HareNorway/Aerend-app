import 'package:flutter/material.dart';

import '../../../data/ops/fee_quote.dart';
import '../../../main.dart' show languages;
import '../../../utils/utils.dart';
import '../kit/bergen_ark.dart';
import 'kasse_copy.dart';

/// «Levering {fee} ›» (Customer v2 Step 1, D2-2; pricing spec §2.4): the engine's lines in the spec's
/// words, one tap from Kassen, the agentic basket and the tracking details — the same sheet in all
/// three, so the customer reads one fee everywhere. Nothing is computed here: the lines and the total
/// come from the quote. NEW UI (no design for the sheet itself; the generic Ark).
Future<void> visLeveringsprisArk(BuildContext context, FeeQuoteView quote, {String? selfDeliveryStore, DateTime? now}) {
  final held = quote.expiresAt;
  final heldText = held == null || held.isBefore(now ?? DateTime.now()) ? null : languages.fee_breakdown_held_until(_hhmm(held.toLocal()));
  return showBergenArk<void>(
    context,
    title: languages.fee_breakdown_title(KasseCopy.kr(quote.totalKr)),
    subtitle: languages.fee_breakdown_subtitle,
    rows: [
      for (final l in quote.lines) BergenArkRow(label: l.label, value: l.detail.isEmpty ? null : l.detail, trailing: feeAmount(l.amountOre)),
      BergenArkRow(label: languages.fee_breakdown_total, trailing: KasseCopy.kr(quote.totalKr)),
    ],
    body: Column(
      key: const Key('fee_breakdown_sheet'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selfDeliveryStore != null && selfDeliveryStore.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(languages.fee_breakdown_self_delivery(selfDeliveryStore), style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        Text(languages.fee_breakdown_no_hidden),
        if (heldText != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(heldText)),
      ],
    ),
  );
}

/// «+6 kr», «−10 kr», «35 kr» for a line (the base has no sign).
String feeAmount(int ore) {
  final kr = KasseCopy.kr(ore.abs() / 100);
  return ore < 0 ? '−$kr' : kr;
}

String _hhmm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
