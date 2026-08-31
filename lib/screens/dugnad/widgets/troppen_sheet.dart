import 'package:flutter/material.dart';

import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../ui/kit/ae_club_crest.dart';
import '../dugnad_club_branding.dart';
import '../../../ui/kit/ae_theme.dart';
import '../dugnad_models.dart';
import '../../../ui/kit/ae_sheet.dart';
import '../dugnad_state.dart';
import '../dugnad_sto_utils.dart';

/// Full Troppen list (prototype mock5).
Future<void> showTroppenSheet({
  required BuildContext context,
  required String teamName,
  required int activeFamilies,
  required List<LeaderboardScorerRow> squad,
  required int? captainUserId,
  required int anonymousCount,
  required void Function(LeaderboardScorerRow scorer) onOpenScorer,
}) {
  return showAeSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFF4F2F8),
    builder: (sheetContext) {
      final theme = sheetContext.aeTheme;
      final maxH = MediaQuery.sizeOf(sheetContext).height * 0.86;
      return SizedBox(
        height: maxH,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.dp(18),
                context.dp(8),
                context.dp(14),
                context.dp(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AeSheetHandle(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Troppen', // TODO(l10n)
                          style: TextStyle(
                            fontSize: context.dp(22),
                            fontWeight: FontWeight.w800,
                            letterSpacing: context.dp(22) * -0.02,
                            color: theme.text,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: ScSaasThemeTokens.gray500,
                        ),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: context.dp(12.5),
                        fontWeight: FontWeight.w600,
                        color: ScSaasThemeTokens.gray500,
                      ),
                      children: [
                        TextSpan(
                          text: '$activeFamilies ildsjeler',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: theme.primaryHover,
                          ),
                        ),
                        TextSpan(text: ' støtter $teamName'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  context.dp(16),
                  context.dp(2),
                  context.dp(16),
                  context.dp(22),
                ),
                children: [
                  for (final s in squad)
                    _SquadListRow(
                      scorer: s,
                      isCaptain: captainUserId != null &&
                          s.userId == captainUserId,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        onOpenScorer(s);
                      },
                    ),
                  for (var i = 0; i < anonymousCount; i++)
                    const _AnonListRow(),
                  SizedBox(height: context.dp(14)),
                  const _PrivacyNote(),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _SquadListRow extends StatelessWidget {
  const _SquadListRow({
    required this.scorer,
    required this.isCaptain,
    required this.onTap,
  });

  final LeaderboardScorerRow scorer;
  final bool isCaptain;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final chip = dugnadStoChipColors(scorer.stoRating);
    final metalDot = PointsMetalDot.forMetal(scorer.tierMetal);
    // Opaque white fill — translucent Material lets the previous row's
    // box-shadow bleed through the card edge (same fix as missions cards).
    return Padding(
      padding: EdgeInsets.only(bottom: context.dp(8)),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.dp(12),
            vertical: context.dp(9),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.dp(15)),
            border: Border.all(color: ScSaasThemeTokens.gray100, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0x142D1B5B),
                blurRadius: context.dp(6),
                offset: Offset(0, context.dp(2)),
              ),
            ],
          ),
          child: Row(
            children: [
              const _MiniAva(anon: false),
              SizedBox(width: context.dp(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 7,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          scorer.displayName,
                          style: TextStyle(
                            fontSize: context.dp(14),
                            fontWeight: FontWeight.w800,
                            color: theme.text,
                          ),
                        ),
                        if (isCaptain)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.dp(8),
                              vertical: context.dp(2),
                            ),
                            decoration: BoxDecoration(
                              gradient: theme.shinyGradient,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '🏅 KAPTEIN',
                              style: TextStyle(
                                fontSize: context.dp(9),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        if (scorer.isViewer)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.dp(8),
                              vertical: context.dp(2),
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryTint,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'DEG',
                              style: TextStyle(
                                fontSize: context.dp(9),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                                color: theme.primaryHover,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: context.dp(3)),
                    Row(
                      children: [
                        Container(
                          width: context.dp(6),
                          height: context.dp(6),
                          decoration: BoxDecoration(
                            color: metalDot,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: context.dp(5)),
                        Text(
                          scorer.tierTitle.isNotEmpty
                              ? scorer.tierTitle
                              : scorer.tierLabel,
                          style: TextStyle(
                            fontSize: context.dp(11.5),
                            fontWeight: FontWeight.w700,
                            color: ScSaasThemeTokens.gray500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.dp(9),
                  vertical: context.dp(4),
                ),
                decoration: BoxDecoration(
                  color: chip.bg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded,
                        size: context.dp(11), color: chip.fg),
                    SizedBox(width: context.dp(4)),
                    Text(
                      '${scorer.stoRating}',
                      style: TextStyle(
                        fontSize: context.dp(12),
                        fontWeight: FontWeight.w900,
                        color: chip.fg,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.dp(4)),
              Icon(
                Icons.chevron_right_rounded,
                size: context.dp(16),
                color: ScSaasThemeTokens.gray300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnonListRow extends StatelessWidget {
  const _AnonListRow();

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: context.dp(8)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.dp(12),
          vertical: context.dp(9),
        ),
        decoration: BoxDecoration(
          color: ScSaasThemeTokens.gray50,
          borderRadius: BorderRadius.circular(context.dp(15)),
          border: Border.all(
            color: ScSaasThemeTokens.gray100,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            const _MiniAva(anon: true),
            SizedBox(width: context.dp(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anonym støttespiller', // TODO(l10n)
                    style: TextStyle(
                      fontSize: context.dp(14),
                      fontWeight: FontWeight.w800,
                      color: theme.text,
                    ),
                  ),
                  SizedBox(height: context.dp(3)),
                  Row(
                    children: [
                      Container(
                        width: context.dp(6),
                        height: context.dp(6),
                        decoration: const BoxDecoration(
                          color: ScSaasThemeTokens.gray300,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: context.dp(5)),
                      Text(
                        'Skjult profil', // TODO(l10n)
                        style: TextStyle(
                          fontSize: context.dp(11.5),
                          fontWeight: FontWeight.w700,
                          color: ScSaasThemeTokens.gray500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniAva extends StatelessWidget {
  const _MiniAva({required this.anon});
  final bool anon;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final logo = DugnadState.instance.clubLogo;
    return SizedBox(
      width: context.dp(42),
      height: context.dp(42),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: context.dp(42),
            height: context.dp(42),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: anon ? ScSaasThemeTokens.gray300 : theme.primaryTint,
            ),
            child: Icon(
              Icons.person_rounded,
              size: context.dp(21),
              color: anon ? Colors.white : theme.primaryHover,
            ),
          ),
          if (!anon)
            Positioned(
              right: -2,
              bottom: -2,
              child: AeClubCrest(
                name: DugnadClubBranding.compactName(),
                logoUrl: logo.isEmpty ? null : logo,
                size: context.dp(20),
              ),
            ),
        ],
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    return Container(
      padding: EdgeInsets.all(context.dp(12)),
      decoration: BoxDecoration(
        color: theme.primaryTint.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(context.dp(14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined,
              size: context.dp(15), color: theme.primaryHover),
          SizedBox(width: context.dp(8)),
          Expanded(
            child: Text(
              'Vi viser kun støttespillere som har valgt å være synlige. Mindreårige vises med fornavn og initial.', // TODO(l10n)
              style: TextStyle(
                fontSize: context.dp(12),
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: ScSaasThemeTokens.gray600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tiny helper so troppen sheet can map metal → tier dot colour.
class PointsMetalDot {
  static Color forMetal(String metal) {
    switch (metal) {
      case 'gull':
        return const Color(0xFFD4A017);
      case 'solv':
        return const Color(0xFF9AA3B2);
      case 'platina':
        return const Color(0xFF6B7A9A);
      case 'bronse':
      default:
        return const Color(0xFFB87333);
    }
  }
}
