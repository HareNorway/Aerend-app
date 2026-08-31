import 'package:flutter/material.dart';
import '../../../utils/utils.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../common/login/login.dart';

class FeedLoginGate extends StatelessWidget {
  const FeedLoginGate({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dynamic_feed_outlined,
                size: 56, color: scheme.primary.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(
              l10n.feed_error_login_required,
              textAlign: TextAlign.center,
              style: aeBody(color: ScSaasThemeTokens.text).copyWith(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => openScreen(context, const Login()),
              style: FilledButton.styleFrom(
                backgroundColor: ScSaasThemeTokens.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: Text(
                l10n.login,
                style: aeLabel(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
