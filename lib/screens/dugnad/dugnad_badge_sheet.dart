import 'package:flutter/material.dart';

import '../../theme/design_scale.dart';

import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import 'dugnad_badge_emblem.dart';
import 'dugnad_badges.dart';
import 'dugnad_club_theme.dart';

Future<void> showDugnadBadgeSheet(
  BuildContext context, {
  required DugnadBadgeItem badge,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _DugnadBadgeSheet(badge: badge),
  );
}

class _DugnadBadgeSheet extends StatelessWidget {
  const _DugnadBadgeSheet({required this.badge});

  final DugnadBadgeItem badge;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final earned = badge.earned;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: EdgeInsets.only(top: context.dp(48)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.dp(AeDugnadSpace.sheetTopRadius)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: context.dp(10)),
          Container(
            width: context.dp(38),
            height: context.dp(4),
            decoration: BoxDecoration(
              color: ScSaasThemeTokens.gray100,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(context.dp(18), context.dp(12), context.dp(12), context.dp(0)),
            child: Row(
              children: [
                Text(
                  languages.dugnadBadgeSheetTitle,
                  style: aeTitle().copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, size: context.dp(20)),
                  style: IconButton.styleFrom(
                    backgroundColor: ScSaasThemeTokens.gray100,
                    foregroundColor: ScSaasThemeTokens.gray500,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(context.dp(18), context.dp(8), context.dp(18), context.dp(24) + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BadgeSheetHero(badge: badge),
                  if (!earned && badge.progressLabel != null) ...[
                    SizedBox(height: context.dp(14)),
                    _BadgeSheetProgress(label: badge.progressLabel!),
                  ],
                  SizedBox(height: context.dp(18)),
                  Text(
                    languages.dugnadBadgeHowToSection,
                    style: aeLabel(color: ScSaasThemeTokens.gray500).copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 11 * 0.06,
                    ),
                  ),
                  SizedBox(height: context.dp(8)),
                  Text(
                    badge.howTo.isNotEmpty
                        ? badge.howTo
                        : languages.dugnadBadgeHowActivityGeneric,
                    style: aeBody().copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: context.dp(1.55),
                      color: const Color(0xFF55506A),
                    ),
                  ),
                  if (badge.howToSteps.isNotEmpty) ...[
                    SizedBox(height: context.dp(12)),
                    for (var i = 0; i < badge.howToSteps.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: i < badge.howToSteps.length - 1 ? 8 : 0,
                        ),
                        child: _BadgeSheetStep(
                          number: i + 1,
                          text: badge.howToSteps[i],
                          theme: theme,
                        ),
                      ),
                  ],
                  SizedBox(height: context.dp(18)),
                  _BadgeSheetReward(badge: badge),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeSheetHero extends StatelessWidget {
  const _BadgeSheetHero({required this.badge});

  final DugnadBadgeItem badge;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final earned = badge.earned;

    return Container(
      padding: EdgeInsets.fromLTRB(context.dp(18), context.dp(22), context.dp(18), context.dp(20)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: earned
              ? [
                  theme.primaryTint.withValues(alpha: 0.35),
                  theme.primaryTint.withValues(alpha: 0.15),
                ]
              : const [Color(0xFFFAFAFB), Color(0xFFF3F2F6)],
        ),
        borderRadius: BorderRadius.circular(context.dp(18)),
        border: Border.all(
          color: earned
              ? theme.primaryTint
              : ScSaasThemeTokens.gray100,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          DugnadBadgeEmblem(
            iconName: badge.icon,
            tone: badge.tone,
            locked: !earned,
            size: context.dp(78),
          ),
          SizedBox(height: context.dp(9)),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            style: aeTitle().copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 20 * -0.02,
              color: earned
                  ? context.dugnadTheme.text
                  : ScSaasThemeTokens.gray500,
            ),
          ),
          SizedBox(height: context.dp(4)),
          Text(
            badge.isSeasonal
                ? languages.dugnadBadgeTypeSeasonal
                : languages.dugnadBadgeTypePermanent,
            style: aeCaption().copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
          SizedBox(height: context.dp(8)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.dp(12), vertical: context.dp(5)),
            decoration: BoxDecoration(
              color: earned ? theme.primaryTint : ScSaasThemeTokens.gray100,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  earned ? Icons.check_rounded : Icons.shield_outlined,
                  size: context.dp(12),
                  color: earned ? theme.primaryHover : ScSaasThemeTokens.gray500,
                ),
                SizedBox(width: context.dp(5)),
                Text(
                  earned
                      ? (badge.isSeasonal
                          ? languages.dugnadBadgeStatusActiveNow
                          : (dugnadFormatBadgeEarnedDate(badge.earnedAt) !=
                                  null
                              ? languages.dugnadBadgeEarnedAt(
                                  dugnadFormatBadgeEarnedDate(
                                    badge.earnedAt,
                                  )!,
                                )
                              : languages.dugnadBadgeUnlocked))
                      : languages.dugnadBadgeStatusLocked,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: earned
                        ? theme.primaryHover
                        : ScSaasThemeTokens.gray500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeSheetProgress extends StatelessWidget {
  const _BadgeSheetProgress({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.dp(14), vertical: context.dp(12)),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6FA),
        borderRadius: BorderRadius.circular(context.dp(14)),
      ),
      child: Row(
        children: [
          Text(
            languages.dugnadBadgeProgressLabel,
            style: aeCaption().copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
          const Spacer(),
          Text(
            label,
            style: aeBody().copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeSheetStep extends StatelessWidget {
  const _BadgeSheetStep({
    required this.number,
    required this.text,
    required this.theme,
  });

  final int number;
  final String text;
  final DugnadClubThemePalette theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.dp(13), vertical: context.dp(11)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(13)),
        boxShadow: [
          BoxShadow(
            color: theme.text.withValues(alpha: 0.05),
            blurRadius: context.dp(2),
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: context.dp(24),
            height: context.dp(24),
            decoration: BoxDecoration(
              gradient: theme.shinyGradient,
              shape: BoxShape.circle,
              boxShadow: theme.shadowButton,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: context.dp(11)),
          Expanded(
            child: Text(
              text,
              style: aeBody().copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeSheetReward extends StatelessWidget {
  const _BadgeSheetReward({required this.badge});

  final DugnadBadgeItem badge;

  @override
  Widget build(BuildContext context) {
    final earned = badge.earned;
    final bonus = badge.stoBonus;

    return Container(
      padding: EdgeInsets.fromLTRB(context.dp(14), context.dp(13), context.dp(14), context.dp(13)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF7E6), Color(0xFFFFEEC2)],
        ),
        borderRadius: BorderRadius.circular(context.dp(15)),
        border: Border.all(
          color: const Color(0x4DD8A028),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: context.dp(36),
            height: context.dp(36),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF7D979), Color(0xFFE0A93A)],
              ),
              borderRadius: BorderRadius.circular(context.dp(11)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD8A028).withValues(alpha: 0.6),
                  blurRadius: context.dp(10),
                  offset: const Offset(0, 4),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Icon(
              Icons.star_rounded,
              size: context.dp(16),
              color: Color(0xFF7A5410),
            ),
          ),
          SizedBox(width: context.dp(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  earned
                      ? languages.dugnadBadgeRewardEarnedTitle(bonus)
                      : languages.dugnadBadgeRewardLockedTitle(bonus),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF6B4A12),
                    letterSpacing: 13.5 * -0.01,
                  ),
                ),
                SizedBox(height: context.dp(1)),
                Text(
                  earned
                      ? languages.dugnadBadgeRewardEarnedSub
                      : languages.dugnadBadgeRewardLockedSub,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9A7526),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
