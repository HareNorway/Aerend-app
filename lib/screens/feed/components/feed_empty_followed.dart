import 'package:flutter/material.dart';
import '../../../utils/utils.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/sc_saas_theme.dart';

class FeedEmptyFollowed extends StatelessWidget {
  final VoidCallback onExploreTap;

  const FeedEmptyFollowed({super.key, required this.onExploreTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 56,
                color: ScSaasThemeTokens.muted.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              l10n.feed_empty_followed,
              textAlign: TextAlign.center,
              style: aeBody(color: ScSaasThemeTokens.text).copyWith(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onExploreTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: ScSaasThemeTokens.primary,
                side: const BorderSide(color: ScSaasThemeTokens.primary),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              child: Text(
                l10n.feed_empty_explore_button,
                style: aeLabel(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
