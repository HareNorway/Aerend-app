import 'package:flutter/material.dart';

import '../../../data/points/points_models.dart';
import '../../../theme/reen_pre_club_theme.dart';

/// Shown once when a promotion has handed the customer a welcome gift.
///
/// The gift is zero-cost ([PrizeClaim.isGift]), so the copy says so plainly rather than
/// leaving the customer wondering whether points were quietly spent.
class WelcomeMoment extends StatelessWidget {
  const WelcomeMoment({
    super.key,
    required this.tierName,
    required this.gift,
    this.onDismiss,
    this.onOpenShelf,
  });

  final String tierName;
  final PrizeClaim gift;
  final VoidCallback? onDismiss;
  final VoidCallback? onOpenShelf;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('welcome-moment'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AerendBergenAuthTokens.screenGradient,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AerendBergenAuthTokens.glassBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Velkommen til $tierName',
            key: const Key('welcome-moment-tier'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AerendBergenAuthTokens.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            gift.isGift
                ? 'Du har fått ${gift.prizeName ?? 'en premie'} — uten å bruke poeng.'
                : 'Du har fått ${gift.prizeName ?? 'en premie'}.',
            key: const Key('welcome-moment-gift'),
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: AerendBergenAuthTokens.textSubtitle,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                key: const Key('welcome-moment-open-shelf'),
                onPressed: onOpenShelf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AerendBergenAuthTokens.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Se premien'),
              ),
              const SizedBox(width: 10),
              TextButton(
                key: const Key('welcome-moment-dismiss'),
                onPressed: onDismiss,
                child: const Text(
                  'Senere',
                  style: TextStyle(color: AerendBergenAuthTokens.textSoft),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
