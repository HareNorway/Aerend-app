import 'package:flutter/material.dart';

import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../dugnad_club_theme.dart';
import '../dugnad_sheet.dart';

/// Choice sheet: Fast støtte vs Kjøp kampanje (prototype mock4 / `.dn-entry`).
Future<void> showTeamSupportSheet({
  required BuildContext context,
  required String teamName,
  required String campaignSubtitle,
  required VoidCallback onFastStotte,
  required VoidCallback onBuyCampaign,
}) {
  final theme = context.dugnadTheme;
  return showDugnadSheet(
    context: context,
    isScrollControlled: true,
    // Mock4 uses a light sheet surface, not the club page wash.
    backgroundColor: const Color(0xFFF4F2F8),
    builder: (sheetContext) {
      final bottom = MediaQuery.paddingOf(sheetContext).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(
          context.dp(18),
          context.dp(4),
          context.dp(18),
          context.dp(18) + bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DugnadSheetHandle(bottom: 10),
            Text(
              'Støtt $teamName', // TODO(l10n)
              style: TextStyle(
                fontSize: context.dp(20),
                fontWeight: FontWeight.w800,
                letterSpacing: context.dp(20) * -0.02,
                color: theme.text,
              ),
            ),
            SizedBox(height: context.dp(5)),
            Text(
              'Velg hvordan du vil bidra til laget.', // TODO(l10n)
              style: TextStyle(
                fontSize: context.dp(13),
                fontWeight: FontWeight.w600,
                color: ScSaasThemeTokens.gray500,
              ),
            ),
            SizedBox(height: context.dp(14)),
            _DnEntry(
              primary: true,
              icon: Icons.favorite_rounded,
              title: 'Fast støtte', // TODO(l10n)
              subtitle: 'Fast månedlig beløp til laget', // TODO(l10n)
              onTap: () {
                Navigator.pop(sheetContext);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onFastStotte();
                });
              },
            ),
            SizedBox(height: context.dp(10)),
            _DnEntry(
              primary: false,
              icon: Icons.inventory_2_outlined,
              title: 'Kjøp kampanje', // TODO(l10n)
              subtitle: campaignSubtitle,
              onTap: () {
                Navigator.pop(sheetContext);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onBuyCampaign();
                });
              },
            ),
          ],
        ),
      );
    },
  );
}

/// `.dn-entry` — primary shiny / secondary tinted choice rows.
class _DnEntry extends StatelessWidget {
  const _DnEntry({
    required this.primary,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool primary;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    // `.dn-entry` uses 16px. Keep the shadow on this outer decoration —
    // putting it on [Ink] clips the glow to a rectangle (sharp corners),
    // which is especially visible on the light secondary row.
    final radius = BorderRadius.circular(context.dp(16));

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: primary ? theme.shinyGradient : null,
        color: primary ? null : theme.primaryTint,
        borderRadius: radius,
        boxShadow: [
          if (primary)
            BoxShadow(
              color: theme.primary.withValues(alpha: 0.55),
              blurRadius: context.dp(28),
              offset: Offset(0, context.dp(14)),
              spreadRadius: context.dp(-16),
            )
          else
            BoxShadow(
              color: const Color(0x142D1B5B),
              blurRadius: context.dp(10),
              offset: Offset(0, context.dp(3)),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radius),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(borderRadius: radius),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.dp(16),
              vertical: context.dp(14),
            ),
            child: Row(
              children: [
                Container(
                  width: context.dp(42),
                  height: context.dp(42),
                  decoration: BoxDecoration(
                    color: primary
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(context.dp(12)),
                    border: primary
                        ? Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          )
                        : null,
                  ),
                  child: Icon(
                    icon,
                    size: context.dp(19),
                    color: primary ? Colors.white : theme.primaryHover,
                  ),
                ),
                SizedBox(width: context.dp(13)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: context.dp(15),
                          fontWeight: FontWeight.w800,
                          letterSpacing: context.dp(15) * -0.01,
                          color: primary ? Colors.white : theme.text,
                        ),
                      ),
                      SizedBox(height: context.dp(2)),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: context.dp(11.5),
                          fontWeight: FontWeight.w600,
                          color: primary
                              ? Colors.white.withValues(alpha: 0.92)
                              : ScSaasThemeTokens.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: context.dp(32),
                  height: context.dp(32),
                  decoration: BoxDecoration(
                    color: primary
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: context.dp(18),
                    color: primary ? Colors.white : theme.primaryHover,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
