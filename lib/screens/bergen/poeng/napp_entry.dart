import 'package:flutter/material.dart';

import '../kit/bergen_toast.dart';

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

/// Bobber tap → the Napp card (seam). Sync C stub shows a toast so the Hjem
/// bobbers are tappable before agil-3 lands the card.
Future<void> showNappKort(BuildContext context, NappOffer offer) async {
  showBergenToast(context, '${offer.title} · ${offer.storeName}');
}
