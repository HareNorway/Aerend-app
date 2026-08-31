import 'package:flutter/material.dart';
import '../../../utils/utils.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/sc_saas_theme.dart';

class FeedErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const FeedErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayMessage =
        message.isEmpty ? l10n.feed_error_generic : message;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 56, color: ScSaasThemeTokens.muted),
            const SizedBox(height: 16),
            Text(
              displayMessage,
              textAlign: TextAlign.center,
              style: aeBody(color: ScSaasThemeTokens.text),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: ScSaasThemeTokens.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(
                l10n.feed_retry,
                style: aeLabel(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
