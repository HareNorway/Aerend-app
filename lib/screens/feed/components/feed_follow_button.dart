import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';

class FeedFollowButton extends StatelessWidget {
  final bool isFollowing;
  final bool isInFlight;
  final VoidCallback onTap;

  const FeedFollowButton({
    super.key,
    required this.isFollowing,
    required this.onTap,
    this.isInFlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FilledButton(
      onPressed: isInFlight ? null : onTap,
      style: FilledButton.styleFrom(
        backgroundColor:
            isFollowing ? ScSaasThemeTokens.card : ScSaasThemeTokens.primary,
        foregroundColor:
            isFollowing ? ScSaasThemeTokens.text : Colors.white,
        side: isFollowing
            ? const BorderSide(color: ScSaasThemeTokens.border)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        minimumSize: const Size(double.infinity, 44),
      ),
      child: isInFlight
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              isFollowing ? l10n.store_profile_following : l10n.store_profile_follow,
              style: aeLabel(color: isFollowing ? ScSaasThemeTokens.text : Colors.white),
            ),
    );
  }
}
