import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../dugnad_club_branding.dart';
import '../dugnad_club_theme.dart';
import '../dugnad_models.dart';
import '../dugnad_share.dart';
import '../dugnad_sheet.dart';
import '../dugnad_state.dart';
import 'dugnad_player_card.dart';

/// Supporter card bottom sheet (prototype mock6) — no info icons / badge row.
///
/// Card sizing matches [SupporterCardScreen] (≈72% width, 1.42 aspect). Sheet
/// height is capped at ~90% of the screen so the card isn’t stretched edge-to-edge.
Future<void> showSupporterPreviewSheet({
  required BuildContext context,
  required LeaderboardScorerRow scorer,
  required String teamName,
}) {
  HapticFeedback.lightImpact();
  final crestName = DugnadClubBranding.compactName();
  final crestLogo = DugnadState.instance.clubLogo;
  final tier = MetalTierInfo(
    key: scorer.tierKey,
    metal: scorer.tierMetal,
    minPoints: 0,
    labelNo: scorer.tierLabel,
    titleSuffix: scorer.tierTitle.isNotEmpty
        ? scorer.tierTitle
        : scorer.tierLabel.toLowerCase(),
  );

  final blurb =
      '${scorer.displayName} bidrar med ${scorer.goals} mål og ${scorer.assists} assist for $teamName denne sesongen.'; // TODO(l10n)

  return showDugnadSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final theme = sheetContext.dugnadTheme;
      final media = MediaQuery.of(sheetContext);
      final bottom = media.padding.bottom;
      final screen = media.size;
      // Same portrait card sizing as SupporterCardScreen.
      final cardWidth = DugnadPlayerCard.stoCardWidth(screen.width);
      final cardMinHeight = DugnadPlayerCard.stoCardMinHeight(cardWidth);
      final sheetMaxHeight = screen.height * 0.90;

      return SizedBox(
        height: sheetMaxHeight,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.dp(18),
            context.dp(8),
            context.dp(18),
            context.dp(18) + bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DugnadSheetHandle(bottom: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      languages.dugnadSupporterCardTitle,
                      style: TextStyle(
                        fontSize: context.dp(18),
                        fontWeight: FontWeight.w800,
                        color: theme.text,
                      ),
                    ),
                  ),
                  _sheetCloseButton(sheetContext),
                ],
              ),
              // Tight stack under the header — card → blurb → share.
              // Extra sheet height stays below the button (not above the card).
              SizedBox(height: context.dp(10)),
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      Center(
                        child: DugnadPlayerCard(
                          name: scorer.displayName,
                          tier: tier,
                          points: scorer.seasonPoints,
                          stoRating: scorer.stoRating,
                          isCaptain: false,
                          crestName: crestName,
                          crestLogo: crestLogo.isEmpty ? null : crestLogo,
                          purchases: scorer.goals,
                          referrals: scorer.assists,
                          badges: const [],
                          showRisingChevron: false,
                          animateIn: true,
                          width: cardWidth,
                          minHeight: cardMinHeight,
                        ),
                      ),
                      SizedBox(height: context.dp(14)),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.dp(8),
                        ),
                        child: Text(
                          blurb,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: context.dp(13),
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            color: ScSaasThemeTokens.gray600,
                          ),
                        ),
                      ),
                      SizedBox(height: context.dp(14)),
                      Center(
                        child: SizedBox(
                          width: cardWidth,
                          child: FilledButton(
                            onPressed: () {
                              shareDugnadText(
                                sheetContext,
                                text: blurb,
                                subject:
                                    '${scorer.displayName} · STØ ${scorer.stoRating}',
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: context.dp(15),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(context.dp(15)),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.share_rounded,
                                  size: context.dp(18),
                                ),
                                SizedBox(width: context.dp(8)),
                                Text(
                                  'Del kortet', // TODO(l10n)
                                  style: TextStyle(
                                    fontSize: context.dp(15.5),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _sheetCloseButton(BuildContext context) {
  final theme = context.dugnadTheme;
  return GestureDetector(
    onTap: () => Navigator.maybePop(context),
    child: Container(
      width: context.dp(40),
      height: context.dp(40),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A1C274C),
            blurRadius: context.dp(12),
            offset: Offset(0, context.dp(4)),
            spreadRadius: context.dp(-2),
          ),
        ],
      ),
      child: Icon(
        Icons.close_rounded,
        size: context.dp(22),
        color: theme.primaryHover,
      ),
    ),
  );
}
