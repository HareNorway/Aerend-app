import 'package:flutter/material.dart';

import '../../../data/points/points_models.dart';
import '../../../theme/bergen_tokens.dart';
import 'prize_card.dart';
import 'prize_preview_card.dart';

/// Premiehylla: the claimable shelf, then the blurred previews from the band above.
///
/// Bands are cumulative, so reaching a new level adds to the shelf rather than replacing it.
/// The previews come last and are capped at three by the backend — the design is deliberate
/// that a customer sees a little of what is next, not a catalogue of what they lack.
class PremiehyllaShelf extends StatelessWidget {
  const PremiehyllaShelf({
    super.key,
    required this.shelf,
    this.onClaim,
    this.maxPreviews = 3,
  });

  final Premiehylla shelf;
  final void Function(Prize prize)? onClaim;
  final int maxPreviews;

  List<PrizePreview> get _previews =>
      shelf.previews.take(maxPreviews).toList(growable: false);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (shelf.prizes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Hylla fylles opp etter hvert som du samler poeng.',
              key: Key('premiehylla-empty'),
              style: TextStyle(
                fontSize: 13,
                color: AerendBergenAuthTokens.textSoft,
              ),
            ),
          ),

        for (final prize in shelf.prizes) ...[
          PrizeCard(
            prize: prize,
            onClaim: onClaim == null ? null : () => onClaim!(prize),
          ),
          const SizedBox(height: 10),
        ],

        if (_previews.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text(
            'SNART PÅ HYLLA',
            key: Key('premiehylla-previews-heading'),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AerendBergenAuthTokens.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          for (final preview in _previews) ...[
            PrizePreviewCard(preview: preview),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}
