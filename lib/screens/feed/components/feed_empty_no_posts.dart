import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';

/// The empty feed for someone who *does* follow shops (handover T4).
///
/// Deliberately without an Explore call to action. The zero-follows empty state
/// has one, and it belongs there — but pushing someone to follow more shops
/// when they already follow five reads as the app not listening. The honest
/// answer here is that there is nothing yet and it is not their fault.
class FeedEmptyNoPosts extends StatelessWidget {
  const FeedEmptyNoPosts({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Center(
      key: const Key('feed_empty_no_posts'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.schedule_outlined,
              size: 56,
              color: ScSaasThemeTokens.muted.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.feed_empty_no_posts,
              textAlign: TextAlign.center,
              style: aeBody(color: ScSaasThemeTokens.text).copyWith(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
