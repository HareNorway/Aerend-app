import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_theme.dart';
import '../dugnad_models.dart';
import '../dugnad_sto_utils.dart';
import '../gamification_models.dart';
import '../../../ui/kit/ae_hourglass.dart';

/// Season finale carryover card (prototype: `SeasonCarryoverCard` in gamify-cards.jsx).
class DugnadSeasonFinaleSection extends StatelessWidget {
  const DugnadSeasonFinaleSection({
    super.key,
    required this.summary,
    required this.config,
    required this.seasonEndRaw,
    required this.seasonBadgeCount,
    required this.dismissed,
    required this.onDismiss,
    required this.onShowAgain,
    this.onOpen,
  });

  final PointsSummary summary;
  final GamificationConfig config;
  final String? seasonEndRaw;
  final int seasonBadgeCount;
  final bool dismissed;
  final VoidCallback onDismiss;
  final VoidCallback onShowAgain;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    if (dismissed) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onShowAgain,
          style: TextButton.styleFrom(
            foregroundColor: ScSaasThemeTokens.gray500,
            padding: EdgeInsets.symmetric(horizontal: context.dp(4), vertical: context.dp(6)),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: Icon(Icons.refresh_rounded, size: context.dp(15)),
          label: Text(
            languages.dugnadSeasonFinaleShowAgain,
            style: aeCaption().copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ).dp(context),
          ),
        ),
      );
    }

    return DugnadSeasonFinaleCard(
      summary: summary,
      config: config,
      seasonEndRaw: seasonEndRaw,
      seasonBadgeCount: seasonBadgeCount,
      onDismiss: onDismiss,
      onOpen: onOpen,
    );
  }
}

class DugnadSeasonFinaleCard extends StatelessWidget {
  const DugnadSeasonFinaleCard({
    super.key,
    required this.summary,
    required this.config,
    required this.seasonEndRaw,
    required this.seasonBadgeCount,
    required this.onDismiss,
    this.onOpen,
  });

  final PointsSummary summary;
  final GamificationConfig config;
  final String? seasonEndRaw;
  final int seasonBadgeCount;
  final VoidCallback onDismiss;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    // Fixed per-metal carryover (what the rollover awards), not percent.
    final carryover = dugnadMetalCarryoverPreview(
      stoRating: summary.stoRating,
      config: config,
    );
    final currentLabel = dugnadMetalLabelFromTiers(
          summary.metalTiers,
          carryover.metal ?? '',
        ) ??
        (carryover.metal ?? '');
    final nextLabel = carryover.nextMetal == null
        ? ''
        : (dugnadMetalLabelFromTiers(summary.metalTiers, carryover.nextMetal!) ??
            carryover.nextMetal!);
    final nextRating = carryover.nextMetal == null
        ? 0
        : dugnadTierStoRatingForMetal(
            carryover.nextMetal!, config.stoTierThresholds);
    final seasonEnd = _formatSeasonEnd(context, seasonEndRaw);

    final card = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        // 150deg, not 135 — the same axis the shinyGradient token uses.
        //
        // These two stops are raw hex in a declaration whose border is
        // `var(--ae-purple-100, #e7defb)`. The author tokenised what they
        // wanted themed and wrote literals for what they did not, so a club
        // override moves the border and leaves the gradient alone. Deriving
        // these from primaryTint/primarySoft would diverge on every
        // non-default club.
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -0.85),
          end: Alignment(0.5, 0.85),
          colors: [Color(0xFFFBF9FF), Color(0xFFF3EEFE)],
        ),
        borderRadius: BorderRadius.circular(context.dp(18)),
        // 1px `--ae-purple-100` at full strength. The authored width is 1px;
        // a computed read reports it snapped (rule 19).
        border: Border.all(color: theme.primaryTint),
        boxShadow: [
          BoxShadow(
            // rgba(45,27,91,.05) is `--ae-midnight`, not the brand purple.
            color: theme.text.withValues(alpha: 0.05),
            blurRadius: context.dp(6),
            offset: Offset(context.dp(0), context.dp(2)),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(context.dp(16), context.dp(15), context.dp(16), context.dp(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _SeasonFinaleHourglass(color: theme.primary, tint: theme.primaryTint),
              SizedBox(width: context.dp(8)),
              Expanded(
                child: Text(
                  languages.dugnadSeasonFinaleTitle.toUpperCase(),
                  style: aeCaption(color: theme.primary).copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                    letterSpacing: 11.5 * 0.05,
                  ).dp(context),
                ),
              ),
              if (seasonEnd.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.dp(9), vertical: context.dp(3)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primary.withValues(alpha: 0.06),
                        blurRadius: context.dp(2),
                        offset: Offset(context.dp(0), context.dp(1)),
                      ),
                    ],
                  ),
                  child: Text(
                    seasonEnd,
                    style: aeCaption(color: ScSaasThemeTokens.gray500).copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ).dp(context),
                  ),
                ),
                SizedBox(width: context.dp(6)),
              ],
              Semantics(
                button: true,
                label: languages.dugnadSeasonFinaleDismiss,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 0,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onDismiss();
                    },
                    child: SizedBox(
                      width: context.dp(24),
                      height: context.dp(24),
                      child: Icon(
                        Icons.close_rounded,
                        size: context.dp(15),
                        color: ScSaasThemeTokens.gray500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Carryover content hidden entirely if metal_carryover is unavailable
          // (no wrong/percent/zero number shown).
          if (carryover.hasValue) ...[
          SizedBox(height: context.dp(12)),
          RichText(
            text: TextSpan(
              style: aeBody(color: ScSaasThemeTokens.ink).copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                height: 1.42,
                letterSpacing: 15 * -0.01,
              ).dp(context),
              children: [
                TextSpan(
                  text: languages.dugnadSeasonFinaleCarryoverBodyPrefix(
                    summary.stoRating,
                  ),
                ),
                TextSpan(
                  text: '${carryover.appliedPoints!}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: context.dp(19),
                    letterSpacing: context.dp(19) * -0.02,
                    color: theme.primary,
                  ),
                ),
                TextSpan(
                  text: languages.dugnadSeasonFinaleCarryoverBodySuffix(
                    carryover.appliedPoints!,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.dp(6)),
          Row(
            children: [
              Icon(
                Icons.star_rounded,
                size: context.dp(12),
                color: const Color(0xFFD9A441),
              ),
              SizedBox(width: context.dp(5)),
              Expanded(
                child: Text(
                  languages.dugnadSeasonFinaleHigherMetalHint,
                  style: aeCaption(color: ScSaasThemeTokens.gray500).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ).dp(context),
                ),
              ),
            ],
          ),
          SizedBox(height: context.dp(12)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.dp(11), vertical: context.dp(9)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.dp(12)),
              boxShadow: [
                BoxShadow(
                  color: theme.primary.withValues(alpha: 0.05),
                  blurRadius: context.dp(2),
                  offset: Offset(context.dp(0), context.dp(1)),
                ),
              ],
            ),
            child: carryover.atMax
                ? Row(
                    children: [
                      Text(
                        currentLabel,
                        style: aeCaption(color: theme.primary).copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ).dp(context),
                      ),
                      SizedBox(width: context.dp(8)),
                      Expanded(
                        child: Text(
                          languages.dugnadSeasonFinaleMaxCarryover,
                          style: aeCaption(color: ScSaasThemeTokens.gray700)
                              .copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ).dp(context),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Text(
                        languages.dugnadNowTier(currentLabel),
                        style: aeCaption(color: theme.primary).copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ).dp(context),
                      ),
                      SizedBox(width: context.dp(8)),
                      Expanded(
                        child: Text(
                          languages.dugnadSeasonFinaleNextCarryover(
                            nextLabel,
                            nextRating,
                            carryover.nextMetalPoints ?? 0,
                          ),
                          style: aeCaption(color: ScSaasThemeTokens.gray700)
                              .copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ).dp(context),
                        ),
                      ),
                    ],
                  ),
          ),
          ],
          if (seasonBadgeCount > 0) ...[
            SizedBox(height: context.dp(9)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🏅', style: TextStyle(fontSize: context.dp(14))),
                SizedBox(width: context.dp(8)),
                Expanded(
                  child: Text(
                    languages.dugnadSeasonFinaleBadgesLocked(seasonBadgeCount),
                    style: aeCaption(color: theme.primary).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ).dp(context),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (onOpen == null) return card;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onOpen!();
      },
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }

  String _formatSeasonEnd(BuildContext context, String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return '';
    final isNo = Localizations.localeOf(context).languageCode == 'no';
    return DateFormat(
      isNo ? 'd. MMMM' : 'MMMM d',
      isNo ? 'nb_NO' : 'en_US',
    ).format(parsed.toLocal());
  }
}

class _SeasonFinaleHourglass extends StatelessWidget {
  const _SeasonFinaleHourglass({
    required this.color,
    required this.tint,
  });

  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.dp(30),
      height: context.dp(30),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(context.dp(9)),
      ),
      alignment: Alignment.center,
      child: AeHourglass(
        size: context.dp(17),
        color: color,
        spin: true,
      ),
    );
  }
}
