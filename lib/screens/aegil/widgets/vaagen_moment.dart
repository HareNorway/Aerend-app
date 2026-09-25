import 'package:flutter/material.dart';

import '../../../data/aegil/suggestion_models.dart';
import '../../../theme/bergen_tokens.dart';

/// "Vågen" — the daily catch (AGIL-2 Phase 7).
///
/// Reeling it in fires `suggestion.reeled`, which the Points side turns into Dagens napp.
/// The contract allows one per customer per calendar day and enforces it server-side, so this
/// widget's job is to make that limit feel like a rhythm rather than a refusal: once today's
/// catch is in, it says so warmly instead of greying out a button.
class VaagenMoment extends StatelessWidget {
  const VaagenMoment({
    super.key,
    required this.catchOfTheDay,
    this.onReel,
    this.reeling = false,
  });

  final DailyCatch catchOfTheDay;
  final VoidCallback? onReel;
  final bool reeling;

  bool get _done => catchOfTheDay.alreadyReeled;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('vaagen-moment'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AerendBergenAuthTokens.screenGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AerendBergenAuthTokens.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VÅGEN',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AerendBergenAuthTokens.textMuted,
            ),
          ),
          const SizedBox(height: 6),

          if (_done) ...[
            Text(
              catchOfTheDay.points > 0
                  ? 'Dagens napp er i boks — ${catchOfTheDay.points} poeng.'
                  : 'Dagens napp er i boks.',
              key: const Key('vaagen-done'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AerendBergenAuthTokens.ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Kom tilbake i morgen.',
              style: TextStyle(
                fontSize: 12.5,
                color: AerendBergenAuthTokens.textSoft,
              ),
            ),
          ] else ...[
            const Text(
              'Det napper',
              key: Key('vaagen-ready'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AerendBergenAuthTokens.ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Dra det inn og se hva Ægil fant til deg i dag.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AerendBergenAuthTokens.textSoft,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              key: const Key('vaagen-reel'),
              onPressed: reeling || onReel == null ? null : onReel,
              style: ElevatedButton.styleFrom(
                backgroundColor: AerendBergenAuthTokens.orange,
                foregroundColor: Colors.white,
              ),
              child: Text(reeling ? 'Drar inn…' : 'Dra inn'),
            ),
          ],

          if (catchOfTheDay.suggestion != null) ...[
            const SizedBox(height: 14),
            Container(
              key: const Key('vaagen-catch'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AerendBergenAuthTokens.glassFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AerendBergenAuthTokens.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    catchOfTheDay.suggestion!.reason,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AerendBergenAuthTokens.mint,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    catchOfTheDay.suggestion!.headline ?? 'Dagens funn',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AerendBergenAuthTokens.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
