import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';

class FeedVisitStoreButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;

  const FeedVisitStoreButton({
    super.key,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OutlinedButton(
      onPressed: isLoading ? null : onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: ScSaasThemeTokens.primary,
        side: const BorderSide(color: ScSaasThemeTokens.primary),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: const Size(double.infinity, 44),
      ),
      child: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              l10n.store_profile_visit_store,
              style: aeLabel(color: ScSaasThemeTokens.primary),
            ),
    );
  }
}
