import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/sc_saas_theme.dart';

/// "Vågen" — the daily catch (feed update spec §3.4).
///
/// One pull a day, and that limit is the design rather than a restriction. A
/// reel you can do twenty times is a slot machine; a reel you can do once is a
/// reason to open the app tomorrow.
///
/// Once pulled, the card stays visible and says so instead of disappearing. A
/// card that vanishes leaves the customer wondering whether they imagined it,
/// or whether it worked.
class VaagenCard extends StatelessWidget {
  const VaagenCard({
    super.key,
    required this.available,
    this.onReel,
    this.pending = false,
  });

  /// False once today's pull is spent.
  final bool available;

  /// Called when the customer pulls. The caller emits `suggestion.reeled`.
  final VoidCallback? onReel;

  /// A pull is in flight — the button is disabled so a double-tap cannot
  /// become two requests the server then has to refuse.
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Card(
      key: const Key('vaagen_card'),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Icon(
              available ? Icons.waves_rounded : Icons.check_circle_rounded,
              size: 36,
              color: available
                  ? ScSaasThemeTokens.primary
                  : const Color(0xFF2E7E4F),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.feed_vaagen_title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    available ? l10n.feed_vaagen_pull : l10n.feed_vaagen_done,
                    key: const Key('vaagen_state_line'),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            if (available)
              FilledButton(
                key: const Key('vaagen_reel'),
                onPressed: pending ? null : onReel,
                child: Text(l10n.feed_vaagen_pull),
              ),
          ],
        ),
      ),
    );
  }
}
