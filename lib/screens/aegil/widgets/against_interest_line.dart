import 'package:flutter/material.dart';

import '../../../data/aegil/against_interest_models.dart';
import '../../../theme/reen_pre_club_theme.dart';

/// Advice that costs Ærend money, rendered first in the turn (AGIL-2 Phase 8).
///
/// First is not a styling choice. If Ægil is going to tell someone the thing is cheaper
/// elsewhere, burying that under the suggestion would make it technically honest and
/// practically useless. The alternative is always offered alongside, because advice with no
/// action is a scolding.
class AgainstInterestLineCard extends StatelessWidget {
  const AgainstInterestLineCard({
    super.key,
    required this.line,
    this.onTakeAlternative,
    this.onSilence,
  });

  final AgainstInterestLine line;
  final void Function(AgainstInterestLine line)? onTakeAlternative;
  final void Function(AgainstInterestLine line)? onSilence;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('against-interest-${line.check}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AerendBergenAuthTokens.mint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AerendBergenAuthTokens.mint.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.savings_outlined,
                size: 15,
                color: AerendBergenAuthTokens.mintDeep,
              ),
              const SizedBox(width: 6),
              if (line.savingOre > 0)
                Text(
                  'Spar ${line.savingKr} kr',
                  key: Key('against-interest-saving-${line.check}'),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AerendBergenAuthTokens.mintDeep,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            line.line,
            key: Key('against-interest-text-${line.check}'),
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: AerendBergenAuthTokens.ink,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                key: Key('against-interest-alternative-${line.check}'),
                onPressed: onTakeAlternative == null
                    ? null
                    : () => onTakeAlternative!(line),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AerendBergenAuthTokens.mintDeep,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: Text(line.alternativeLabel),
              ),
              const Spacer(),
              if (onSilence != null)
                TextButton(
                  key: Key('against-interest-silence-${line.check}'),
                  onPressed: () => onSilence!(line),
                  child: const Text(
                    'Ikke si fra om dette',
                    style: TextStyle(
                      fontSize: 12,
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

/// A turn in chat or cart: the against-interest lines, then whatever Ægil was going to say.
class AgainstInterestTurn extends StatelessWidget {
  const AgainstInterestTurn({
    super.key,
    required this.lines,
    required this.body,
    this.onTakeAlternative,
    this.onSilence,
  });

  final List<AgainstInterestLine> lines;
  final Widget body;
  final void Function(AgainstInterestLine line)? onTakeAlternative;
  final void Function(AgainstInterestLine line)? onSilence;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('against-interest-turn'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // First, always.
        for (final line in lines) ...[
          AgainstInterestLineCard(
            line: line,
            onTakeAlternative: onTakeAlternative,
            onSilence: onSilence,
          ),
          const SizedBox(height: 10),
        ],
        body,
      ],
    );
  }
}

/// The trust-ledger card in "Meg".
///
/// Counts what Ægil *found*, not what it was allowed to say — so silencing the advice cannot
/// quietly inflate the numbers, and the card stays honest either way.
class TrustLedgerCard extends StatelessWidget {
  const TrustLedgerCard({super.key, required this.ledger, this.onOpen});

  final TrustLedgerMonth ledger;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        key: const Key('trust-ledger-card'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AerendBergenAuthTokens.glassFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AerendBergenAuthTokens.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TILLITSREGNSKAP',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: AerendBergenAuthTokens.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            if (!ledger.hasAnything)
              const Text(
                'Ægil har ikke hatt noe å spare deg for ennå.',
                key: Key('trust-ledger-empty'),
                style: TextStyle(
                  fontSize: 12.5,
                  color: AerendBergenAuthTokens.textSoft,
                ),
              )
            else ...[
              Text(
                'Ægil sparte deg ${ledger.savedKr} kr',
                key: const Key('trust-ledger-saved'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AerendBergenAuthTokens.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${ledger.againstInterestShown} råd mot egen interesse · '
                '${ledger.findsApplied} tatt i bruk',
                key: const Key('trust-ledger-detail'),
                style: const TextStyle(
                  fontSize: 12,
                  color: AerendBergenAuthTokens.textSoft,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
