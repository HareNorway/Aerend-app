import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/reen_pre_club_theme.dart';

/// AI disclosure, shown on first use in every surface that can show agent output
/// (AGIL-2-PLAN §1: "AI disclosure on first use in every surface").
///
/// The copy is the "Om Ægil" sheet from `designs/Ærend Kunde Bergen.dc.html`
/// (`type: 'ai'`), which is also what the admin panel shows through
/// `resources/views/components/agent/disclosure.blade.php` in Hare-AdminPanel.
/// Change both together, or the two surfaces will say different things about the
/// same assistant.
///
/// Whether a surface has shown it yet is the caller's business — see
/// [AegilDisclosureTracker] — because "first use" means first use of *that*
/// surface, not of the app.
enum AegilDisclosureVariant {
  /// The full paragraph, for a settings sheet or an onboarding step.
  full,

  /// One line, for the top of a chat turn or a suggestion card.
  short,
}

class AegilDisclosure extends StatelessWidget {
  const AegilDisclosure({
    super.key,
    this.variant = AegilDisclosureVariant.full,
    this.agentName,
    this.onTerms,
    this.onDismiss,
  });

  final AegilDisclosureVariant variant;

  /// Names the agent that produced the output, when a surface shows several.
  final String? agentName;

  final VoidCallback? onTerms;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isShort = variant == AegilDisclosureVariant.short;

    final text = isShort
        ? (l10n?.aegil_disclosure_short ?? _fallbackShort)
        : (l10n?.aegil_disclosure_body ?? _fallbackBody);

    return Semantics(
      container: true,
      label: l10n?.aegil_disclosure_title ?? 'Om Ægil',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AerendBergenAuthTokens.glassFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AerendBergenAuthTokens.glassBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.info_outline,
                size: 15,
                color: AerendBergenAuthTokens.textSoft,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    agentName == null ? text : '$text ($agentName)',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: AerendBergenAuthTokens.textSubtitle,
                    ),
                  ),
                  if (onTerms != null && !isShort) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onTerms,
                      child: Text(
                        l10n?.aegil_disclosure_terms ?? 'Vilkår',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AerendBergenAuthTokens.orange,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onDismiss != null)
              GestureDetector(
                onTap: onDismiss,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8, top: 1),
                  child: Icon(
                    Icons.close,
                    size: 15,
                    color: AerendBergenAuthTokens.textMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Used only if localisations are unavailable (a bare test pump, or a locale
  // that failed to load). Norwegian, because that is the product's language.
  static const String _fallbackBody =
      'Ægil er en assistent laget av Ærend, ikke et menneske. Ægil gjør ingenting '
      'med pengene dine uten et trykk fra deg under nivå 3, og alt Ægil gjør kan '
      'angres i 7 dager. Ærend-innlegg i feeden skrives aldri i Ægils stemme.';

  static const String _fallbackShort =
      'Laget med AI-hjelp. Ægil er en assistent laget av Ærend, ikke et menneske.';
}

/// Remembers which surfaces have already shown the disclosure.
///
/// In-memory and per-session on purpose: showing it again after a restart is
/// harmless, whereas persisting a "seen" flag risks a surface that never
/// discloses at all if the flag is written before the widget renders.
class AegilDisclosureTracker {
  AegilDisclosureTracker._();

  static final Set<String> _shown = <String>{};

  /// True the first time a given surface asks, false afterwards.
  static bool shouldShow(String surface) => _shown.add(surface);

  static bool hasShown(String surface) => _shown.contains(surface);

  @visibleForTesting
  static void reset() => _shown.clear();
}
