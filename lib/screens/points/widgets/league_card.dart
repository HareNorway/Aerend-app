import 'package:flutter/material.dart';

import '../../../data/points/league_models.dart';
import '../../../theme/bergen_tokens.dart';

/// Fløyen-ligaen.
///
/// Three things this widget is careful about, all from the shared design rules:
///
///   It is opt-in, and says so before you are in it. Nobody is ranked without choosing to be.
///   It states that it is tier-blind, so it cannot be read as a second status ladder on Nivå.
///   It shows your own rank wherever it falls, not only the top ten — a board that only shows
///   the leaders is a board most people are invisible on.
class LeagueCard extends StatelessWidget {
  const LeagueCard({
    super.key,
    required this.league,
    this.onOptIn,
    this.onOptOut,
    this.showBydel = true,
  });

  final League league;
  final VoidCallback? onOptIn;
  final VoidCallback? onOptOut;
  final bool showBydel;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('league-card'),
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
            'FLØYEN-LIGAEN',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AerendBergenAuthTokens.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            league.month,
            style: const TextStyle(
              fontSize: 13,
              color: AerendBergenAuthTokens.textSoft,
            ),
          ),

          if (!league.optedIn) ...[
            const SizedBox(height: 12),
            const Text(
              'Ligaen er frivillig, og varer én måned om gangen. Nivået ditt teller ikke '
              'med — alle samler på samme måte.',
              key: Key('league-opt-in-explainer'),
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AerendBergenAuthTokens.textSoft,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              key: const Key('league-opt-in'),
              onPressed: onOptIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AerendBergenAuthTokens.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Bli med denne måneden'),
            ),
          ] else ...[
            const SizedBox(height: 12),
            if (league.own != null)
              Container(
                key: const Key('league-own-rank'),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AerendBergenAuthTokens.mint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Du er nr. ${league.own!.rank} av ${league.participants} '
                  'med ${league.own!.points} poeng',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AerendBergenAuthTokens.ink,
                  ),
                ),
              ),

            const SizedBox(height: 14),
            _table('TOPP 10', league.top, const Key('league-top')),

            if (showBydel && league.bydel != null && league.bydelStandings.isNotEmpty) ...[
              const SizedBox(height: 14),
              _table(
                'DIN BYDEL · ${league.bydel!.toUpperCase()}',
                league.bydelStandings,
                const Key('league-bydel'),
              ),
            ],

            const SizedBox(height: 12),
            Text(
              'Nivået ditt teller ikke med. Én bestilling gir maks ${league.capPerOrder} ligapoeng.',
              key: const Key('league-fairness-note'),
              style: const TextStyle(
                fontSize: 11.5,
                color: AerendBergenAuthTokens.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('league-opt-out'),
              onPressed: onOptOut,
              child: const Text(
                'Meld meg av',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AerendBergenAuthTokens.textSoft,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _table(String heading, List<LeagueStanding> rows, Key key) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: AerendBergenAuthTokens.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${row.rank}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AerendBergenAuthTokens.textSubtitle,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    row.bydel ?? '—',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AerendBergenAuthTokens.textSoft,
                    ),
                  ),
                ),
                Text(
                  '${row.points}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AerendBergenAuthTokens.ink,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
