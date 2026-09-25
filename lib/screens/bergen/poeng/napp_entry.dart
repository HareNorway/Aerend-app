import 'package:flutter/material.dart';

import '../../../data/aegil/aegil_app_repo.dart';
import '../meg/a3_scaffold.dart';
import '../meg/a3_services.dart';
import '../kit/bergen_kit.dart';
import 'poeng_copy.dart';

/// What the Hjem bobber knows about a catch (AGIL-CONTRACT §5.4). agil-1
/// constructs it; agil-3 owns this file and the card that rises from the
/// water. The card fetches the rest by [id] from `GET /api/agent/suggestions/{id}`.
class NappOffer {
  const NappOffer({
    required this.id,
    required this.title,
    required this.storeName,
    required this.priceOre,
    required this.reason,
    required this.kind,
  });

  final String id;
  final String title;
  final String storeName;
  final int priceOre;
  final String reason;

  /// `tilbud` | `ny` | `rytme`.
  final String kind;
}

/// Bobber tap → the Napp card (design `nappKort` ≈L2115): the kind chip
/// (Bergensk / Dagens napp: +5), the title, the store and price, Ægil's
/// reason, and Legg til / Ikke nå / Aldri dette. Legg til and Aldri dette
/// go through `agent/me/suggestions/{id}/add|never`; the daily catch earns
/// through `points/me/earn?rule=dagens_napp` (capped per day).
Future<void> showNappKort(BuildContext context, NappOffer offer, {AegilAppApi? aegil, PointsAppApiEarn? earn}) async {
  final api = aegil ?? A3Services.aegil();
  final id = int.tryParse(offer.id);

  await showBergenSheet<void>(
    context,
    onDark: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        key: const Key('napp-kort'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BergenChip(label: offer.kind == 'rytme' ? A3PoengCopy.a3_poeng_napp_dagens : A3PoengCopy.a3_poeng_napp_bergensk, selected: true, icon: offer.kind == 'tilbud' ? Icons.local_offer_rounded : Icons.phishing_rounded),
              const Spacer(),
              Text(a3Kr(offer.priceOre), style: BergenTokens.display(BergenTokens.textBody, color: BergenTokens.lantern)),
            ],
          ),
          const SizedBox(height: 10),
          Text(offer.title, style: BergenTokens.display(BergenTokens.textTitle, color: Colors.white)),
          Text(offer.storeName, style: BergenTokens.text(BergenTokens.textSmall, weight: FontWeight.w600, color: A3Ink.sub)),
          const SizedBox(height: 8),
          Text(offer.reason, style: BergenTokens.text(BergenTokens.textBody, color: A3Ink.sub)),
          const SizedBox(height: 16),
          BergenCta3d(
            key: const Key('napp-legg'),
            label: A3PoengCopy.a3_poeng_napp_legg,
            icon: Icons.add_shopping_cart_rounded,
            onPressed: () async {
              if (id != null) await api.add(id);
              final r = earn == null ? null : await earn(id);
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              showBergenToast(context, r != null && r > 0 ? '${offer.title} lagt til · +$r poeng' : '${offer.title} lagt til', icon: Icons.check_rounded);
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  key: const Key('napp-ikke-naa'),
                  onPressed: () async {
                    if (id != null) await api.dismiss(id);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: Text(A3PoengCopy.a3_poeng_napp_ikke_naa, style: BergenTokens.text(BergenTokens.textBody, weight: FontWeight.w700, color: A3Ink.sub)),
                ),
              ),
              Expanded(
                child: TextButton(
                  key: const Key('napp-aldri'),
                  onPressed: () async {
                    if (id != null) await api.never(id, 'not_interested');
                    if (!ctx.mounted) return;
                    Navigator.of(ctx).pop();
                    showBergenToast(context, 'Ægil foreslår ikke dette igjen');
                  },
                  child: Text(A3PoengCopy.a3_poeng_napp_aldri, style: BergenTokens.text(BergenTokens.textBody, weight: FontWeight.w700, color: BergenTokens.orangeLight)),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Optional earn hook the Hjem may pass (returns points earned, or null).
typedef PointsAppApiEarn = Future<int?> Function(int? suggestionId);
