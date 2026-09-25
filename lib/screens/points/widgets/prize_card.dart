import 'package:flutter/material.dart';

import '../../../data/points/points_models.dart';
import '../../../theme/bergen_tokens.dart';

/// A claimable prize on the shelf.
///
/// The claim button is disabled — not hidden — when the customer cannot claim, and says why.
/// Hiding it would leave them guessing; the design keeps the prize visible and the reason
/// plain.
class PrizeCard extends StatelessWidget {
  const PrizeCard({super.key, required this.prize, this.onClaim});

  final Prize prize;
  final VoidCallback? onClaim;

  /// Only enabled when the backend says the claim would succeed.
  bool get canClaim => prize.claimable && onClaim != null;

  String get _blockedLabel {
    switch (prize.blockedReason) {
      case 'PRIZE_INSUFFICIENT_POINTS':
        return 'Mangler ${prize.pointPrice} poeng';
      case 'PRIZE_SOLD_OUT':
        return 'Utsolgt';
      case 'PRIZE_USER_CAP':
        return 'Allerede hentet';
      case 'PRIZE_TIER_LOCKED':
        return 'Fra ${prize.tierName}';
      default:
        return 'Ikke tilgjengelig';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AerendBergenAuthTokens.glassFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AerendBergenAuthTokens.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            prize.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AerendBergenAuthTokens.ink,
            ),
          ),
          if (prize.line != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                prize.line!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AerendBergenAuthTokens.textSoft,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${prize.pointPrice} poeng',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AerendBergenAuthTokens.textSubtitle,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                key: const Key('prize-claim-button'),
                // null disables the button; the reason is shown beside it.
                onPressed: canClaim ? onClaim : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AerendBergenAuthTokens.orange,
                  disabledBackgroundColor:
                      AerendBergenAuthTokens.glassBorder,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(canClaim ? 'Hent' : _blockedLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
