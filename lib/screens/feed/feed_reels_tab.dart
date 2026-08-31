// Unwired pending real Reels implementation. Restore in FeedShellScreen when ready.
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';

class FeedReelsTab extends StatelessWidget {
  const FeedReelsTab({super.key});

  /// Design spec: Reels.jsx — dark background #0D0B16.
  static const Color _reelsBg = Color(0xFF0D0B16);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: _reelsBg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.smart_display_outlined,
                size: 56,
                color: ScSaasThemeTokens.primarySoft.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.feed_nav_reels,
                style: aeH2(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.feed_coming_soon,
                textAlign: TextAlign.center,
                style: aeBody(color: ScSaasThemeTokens.gray500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
