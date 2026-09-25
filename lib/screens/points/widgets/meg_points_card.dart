import 'package:flutter/material.dart';

import '../../../data/points/points_models.dart';
import '../../../theme/bergen_tokens.dart';

/// The Poeng card on "Meg": balance, Nivå with progress, and the expiry notice.
///
/// The Nivå line carries the promise the design makes in words and the engine keeps in code:
/// spending points never lowers a level, because a level follows what you earned, not what
/// you have left.
class MegPointsCard extends StatelessWidget {
  const MegPointsCard({
    super.key,
    required this.balance,
    this.goal,
    this.onOpenPremiehylla,
    this.onOpenNiva,
  });

  final PointsBalance balance;
  final PointGoal? goal;
  final VoidCallback? onOpenPremiehylla;
  final VoidCallback? onOpenNiva;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x24FFFFFF), Color(0x0FFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AerendBergenAuthTokens.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Nivå -------------------------------------------------------
          GestureDetector(
            onTap: onOpenNiva,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DITT NIVÅ',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AerendBergenAuthTokens.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  balance.tierName,
                  key: const Key('meg-tier-name'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AerendBergenAuthTokens.ink,
                  ),
                ),
                if (balance.nextTierName != null &&
                    balance.pointsToNextTier != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${balance.pointsToNextTier} poeng til ${balance.nextTierName}',
                    key: const Key('meg-tier-progress-line'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AerendBergenAuthTokens.textSoft,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: balance.progressToNextTier(),
                      minHeight: 6,
                      backgroundColor: AerendBergenAuthTokens.glassBorder,
                      valueColor: const AlwaysStoppedAnimation(
                        AerendBergenAuthTokens.mint,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                const Text(
                  'Nivået påvirkes aldri av at du bruker poeng',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AerendBergenAuthTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 26, color: AerendBergenAuthTokens.glassBorder),

          // --- Balance ----------------------------------------------------
          const Text(
            'POENG Å BRUKE',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AerendBergenAuthTokens.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${balance.available}',
                key: const Key('meg-available-points'),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AerendBergenAuthTokens.ink,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'poeng',
                style: TextStyle(
                  fontSize: 13,
                  color: AerendBergenAuthTokens.textSoft,
                ),
              ),
            ],
          ),

          if (balance.pending > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                // Kjøp points wait for the return window to close; saying so up front
                // avoids the "where are my points?" support ticket.
                '${balance.pending} poeng er på vei — de blir klare når returfristen er ute',
                key: const Key('meg-pending-line'),
                style: const TextStyle(
                  fontSize: 12,
                  color: AerendBergenAuthTokens.textSoft,
                ),
              ),
            ),

          if (balance.hasExpiryNotice)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AerendBergenAuthTokens.orange.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${balance.expiringAmount} poeng utløper snart',
                  key: const Key('meg-expiry-notice'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AerendBergenAuthTokens.orangeLight,
                  ),
                ),
              ),
            ),

          // --- Goal -------------------------------------------------------
          if (goal != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sparer til ${goal!.label}',
                    key: const Key('meg-goal-label'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AerendBergenAuthTokens.textSubtitle,
                    ),
                  ),
                ),
                Text(
                  '${goal!.percent} %',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AerendBergenAuthTokens.mint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (goal!.percent / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AerendBergenAuthTokens.glassBorder,
                valueColor: const AlwaysStoppedAnimation(
                  AerendBergenAuthTokens.orange,
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),
          Row(
            children: [
              ElevatedButton(
                key: const Key('meg-open-premiehylla'),
                onPressed: onOpenPremiehylla,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AerendBergenAuthTokens.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Premiehylla'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
