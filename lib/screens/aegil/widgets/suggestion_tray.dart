import 'package:flutter/material.dart';

import '../../../data/aegil/suggestion_models.dart';
import '../../../theme/reen_pre_club_theme.dart';
import 'aegil_disclosure.dart';

/// The suggestion tray (AGIL-2 Phase 7).
///
/// Every card leads with *why* it is there, not what it is selling. That is the whole
/// difference between a suggestion and an advert, and it is enforced upstream too — the
/// engine will not produce a suggestion it cannot name a reason for.
///
/// "Legg til" does not put anything in the cart below level 3. The backend returns the item
/// and `cart_written: false`; the customer's own tap is what adds it.
class SuggestionTray extends StatelessWidget {
  const SuggestionTray({
    super.key,
    required this.suggestions,
    this.onAdd,
    this.onDismiss,
    this.onNotForMe,
    this.emptyMessage = 'Ingenting å foreslå akkurat nå.',
  });

  final List<Suggestion> suggestions;
  final void Function(Suggestion suggestion)? onAdd;
  final void Function(Suggestion suggestion)? onDismiss;
  final void Function(Suggestion suggestion)? onNotForMe;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          emptyMessage,
          key: const Key('suggestion-tray-empty'),
          style: const TextStyle(
            fontSize: 13,
            color: AerendBergenAuthTokens.textSoft,
          ),
        ),
      );
    }

    return Column(
      key: const Key('suggestion-tray'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            'ÆGIL FORESLÅR',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AerendBergenAuthTokens.textMuted,
            ),
          ),
        ),
        for (final suggestion in suggestions)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _card(suggestion),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: AegilDisclosure(variant: AegilDisclosureVariant.short),
        ),
      ],
    );
  }

  Widget _card(Suggestion suggestion) {
    return Container(
      key: Key('suggestion-card-${suggestion.id}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AerendBergenAuthTokens.glassFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AerendBergenAuthTokens.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The reason comes first. A suggestion that cannot explain itself is an advert.
          Text(
            suggestion.reason,
            key: Key('suggestion-reason-${suggestion.id}'),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AerendBergenAuthTokens.mint,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            suggestion.headline ?? 'Forslag',
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AerendBergenAuthTokens.ink,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                key: Key('suggestion-add-${suggestion.id}'),
                onPressed: onAdd == null ? null : () => onAdd!(suggestion),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AerendBergenAuthTokens.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Legg til'),
              ),
              const SizedBox(width: 8),
              TextButton(
                key: Key('suggestion-dismiss-${suggestion.id}'),
                onPressed: onDismiss == null ? null : () => onDismiss!(suggestion),
                child: const Text(
                  'Ikke nå',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AerendBergenAuthTokens.textSoft,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                key: Key('suggestion-never-${suggestion.id}'),
                onPressed: onNotForMe == null ? null : () => onNotForMe!(suggestion),
                child: const Text(
                  'Ikke for meg',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AerendBergenAuthTokens.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The "Ikke for meg" sheet.
///
/// Asking *why* is what makes the answer useful: "already have" is not a dislike, and
/// "wrong store" says nothing about the product. Without the reason, every no would have to
/// be treated as the harshest one.
class NotForMeSheet extends StatelessWidget {
  const NotForMeSheet({super.key, required this.suggestion, this.onChosen});

  final Suggestion suggestion;
  final void Function(NotForMeReason reason)? onChosen;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('not-for-me-sheet'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      decoration: const BoxDecoration(
        color: AerendBergenAuthTokens.navyMid,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hvorfor ikke?',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AerendBergenAuthTokens.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Svaret hjelper Ægil å forstå forskjellen på «ikke denne» og «ikke sånt».',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: AerendBergenAuthTokens.textSoft,
            ),
          ),
          const SizedBox(height: 16),
          for (final reason in NotForMeReason.values)
            ListTile(
              key: Key('not-for-me-${reason.code}'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                reason.label,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AerendBergenAuthTokens.ink,
                ),
              ),
              onTap: onChosen == null ? null : () => onChosen!(reason),
            ),
        ],
      ),
    );
  }
}
