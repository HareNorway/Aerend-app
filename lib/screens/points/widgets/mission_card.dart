import 'package:flutter/material.dart';

import '../../../data/points/points_models.dart';
import '../../../screens/aegil/widgets/aegil_disclosure.dart';
import '../../../theme/reen_pre_club_theme.dart';

/// Ukens oppdrag — one mission, with a decline that works once a week.
///
/// The decline button disappears after it has been used, rather than showing an error on tap:
/// an unlimited reroll would make this a slot machine, which the shared design rules rule out
/// as gamification.
///
/// When Ægil reworded the mission ([Mission.wordingSource] == 'agent') the card carries the
/// AI disclosure, because that text is model-written.
class MissionCard extends StatelessWidget {
  const MissionCard({
    super.key,
    required this.mission,
    this.canDecline = true,
    this.onDecline,
  });

  final Mission mission;
  final bool canDecline;
  final VoidCallback? onDecline;

  bool get _isAgentWorded => mission.wordingSource == 'agent';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AerendBergenAuthTokens.glassFill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AerendBergenAuthTokens.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'UKENS OPPDRAG',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AerendBergenAuthTokens.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            mission.title,
            key: const Key('mission-title'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AerendBergenAuthTokens.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mission.body,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: AerendBergenAuthTokens.textSoft,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${mission.points} poeng',
                key: const Key('mission-points'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AerendBergenAuthTokens.mint,
                ),
              ),
              if (mission.target > 1) ...[
                const SizedBox(width: 10),
                Text(
                  '${mission.progress}/${mission.target}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AerendBergenAuthTokens.textMuted,
                  ),
                ),
              ],
              const Spacer(),
              // Gone once used, rather than present-but-failing.
              if (canDecline && onDecline != null)
                TextButton(
                  key: const Key('mission-decline'),
                  onPressed: onDecline,
                  child: const Text(
                    'Ikke denne',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AerendBergenAuthTokens.textSubtitle,
                    ),
                  ),
                ),
            ],
          ),
          if (_isAgentWorded) ...[
            const SizedBox(height: 10),
            const AegilDisclosure(variant: AegilDisclosureVariant.short),
          ],
        ],
      ),
    );
  }
}
