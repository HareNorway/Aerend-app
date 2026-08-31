import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/design_scale.dart';
import '../../../utils/utils.dart';
import '../celebration_copy.dart';
import '../celebration_models.dart';
import '../dugnad_badges.dart';
import '../dugnad_club_branding.dart';
import '../dugnad_club_theme.dart';
import '../dugnad_state.dart';
import '../leaderboard_screen.dart';
import 'dugnad_bead_badge.dart';
import 'dugnad_club_contract_card.dart';
import 'dugnad_ceremonial_screen.dart';
import 'dugnad_shiny_press.dart';
import 'dugnad_team_sign_card.dart';
import 'dugnad_throne_player_hero.dart';
import 'lucide_trophy_icon.dart';
import '../season_recap_screen.dart';

/// Builds full-screen ceremonial presenters per celebration type.
class CelebrationCeremonialPresenter {
  const CelebrationCeremonialPresenter._();

  /// Same shiny primary CTA as T3 celebration modals / club shop unlock.
  static Widget _seasonPrimaryCta({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
  }) {
    final theme = context.dugnadTheme;
    return DugnadShinyPress(
      borderRadius: context.dp(14),
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: context.dp(50),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: theme.shinyGradient,
          borderRadius: BorderRadius.circular(context.dp(14)),
          boxShadow: theme.shadowButton,
        ),
        child: Text(
          label,
          style: aeLabel(color: Colors.white).copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  static Future<void> show(
    BuildContext context, {
    required PendingCelebration item,
    required VoidCallback onDismiss,
    VoidCallback? onCta,
  }) {
    switch (item.type) {
      case CelebrationType.t14:
        return _showClubWelcome(context, item: item, onDismiss: onDismiss);
      case CelebrationType.t13:
        return _showTeamSign(context, item: item, onDismiss: onDismiss);
      case CelebrationType.t9:
        return _showSeasonTeamWin(
          context,
          item: item,
          onDismiss: onDismiss,
          onCta: onCta,
        );
      case CelebrationType.t15:
        return _showSeasonPlace(
          context,
          item: item,
          onDismiss: onDismiss,
          onCta: onCta,
        );
      case CelebrationType.t10:
      case CelebrationType.t11:
      case CelebrationType.t12:
        return _showPersonalTitle(
          context,
          item: item,
          onDismiss: onDismiss,
          onCta: onCta,
        );
      default:
        return DugnadCeremonialScreen.show(
          context,
          onDismiss: onDismiss,
          kicker: item.type.apiKey,
          title: item.type.apiKey,
          subtitle: 'Ceremonial UI pending',
        );
    }
  }

  static Future<void> _showClubWelcome(
    BuildContext context, {
    required PendingCelebration item,
    required VoidCallback onDismiss,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final clubName = item.stringPayload('club_name')?.trim().isNotEmpty == true
        ? item.stringPayload('club_name')!
        : DugnadClubBranding.fullName();
    final logo = item.stringPayload('club_logo_url') ??
        (DugnadState.instance.clubLogo.isNotEmpty
            ? DugnadState.instance.clubLogo
            : null);
    final playerName = item.stringPayload('user_name')?.trim().isNotEmpty == true
        ? item.stringPayload('user_name')!
        : prefGetString(prefUserName);
    final seasonStamp = dugnadFormatSeasonTag(
      item.stringPayload('season_label'),
    );
    final season = seasonStamp.isNotEmpty ? seasonStamp : '25/26';

    return DugnadCeremonialScreen.show(
      context,
      onDismiss: onDismiss,
      showCloseButton: true,
      autoDismissAfter: DugnadCeremonialScreen.kTapDismissMax,
      hero: Padding(
        padding: EdgeInsets.only(bottom: context.dp(24)),
        child: DugnadClubContractCard(
          clubName: clubName,
          playerName: playerName,
          roleLabel: l10n.dugnadSupporter,
          clubLogoUrl: logo,
          seasonStamp: season,
        ),
      ),
      kicker: l10n.celebrationTitleT14,
      title: clubName,
      subtitle: l10n.celebrationBodyT14,
    );
  }

  static Future<void> _showTeamSign(
    BuildContext context, {
    required PendingCelebration item,
    required VoidCallback onDismiss,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final teamName = item.stringPayload('team_name')?.trim().isNotEmpty == true
        ? item.stringPayload('team_name')!
        : (DugnadState.instance.pointsTeamName.isNotEmpty
            ? DugnadState.instance.pointsTeamName
            : 'Laget ditt');
    final teamLogo = item.stringPayload('team_logo_url') ??
        (DugnadState.instance.pointsTeamLogo.isNotEmpty
            ? DugnadState.instance.pointsTeamLogo
            : null);
    final seasonStamp = dugnadFormatSeasonTag(
      item.stringPayload('season_label'),
    );
    final season = seasonStamp.isNotEmpty ? seasonStamp : '25/26';

    return DugnadCeremonialScreen.show(
      context,
      onDismiss: onDismiss,
      showCloseButton: true,
      autoDismissAfter: DugnadCeremonialScreen.kTapDismissMax,
      // Quiet team-sign moment. Auto-dismiss + close so stacked modals cannot trap.
      confettiPieces: 0,
      hero: Padding(
        padding: EdgeInsets.only(bottom: context.dp(22)),
        child: DugnadTeamSignCard(
          teamName: teamName,
          teamLogoUrl: teamLogo,
        ),
      ),
      kicker: l10n.celebrationTitleT13,
      title: teamName,
      subtitle: l10n.celebrationBodyT13,
      footer: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.dp(12),
          vertical: context.dp(6),
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_rounded,
              size: context.dp(12),
              color: Colors.white.withValues(alpha: 0.85),
            ),
            SizedBox(width: context.dp(6)),
            Text(
              l10n.celebrationTeamContractConfirmed(season),
              style: aeLabel(color: Colors.white.withValues(alpha: 0.72)).copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _showSeasonTeamWin(
    BuildContext context, {
    required PendingCelebration item,
    required VoidCallback onDismiss,
    VoidCallback? onCta,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final copy = CelebrationCopy(l10n);
    final seasonStamp = dugnadFormatSeasonTag(
      item.stringPayload('season_label'),
    );
    final season = seasonStamp.isNotEmpty ? seasonStamp : '25/26';
    final reduce = MediaQuery.disableAnimationsOf(context);

    void finishAnd(VoidCallback? next) {
      Navigator.of(context).maybePop();
      if (next != null) {
        next();
      } else {
        onDismiss();
      }
    }

    return DugnadCeremonialScreen.show(
      context,
      onDismiss: onDismiss,
      showCloseButton: true,
      showSpotlight: true,
      tapToDismiss: false,
      confettiPieces: 90,
      hero: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Design `.dgseq-cup` — gold disc + 14 laurel nubs + Lucide trophy.
          DugnadBeadBadge(
            size: context.dp(168),
            beadCount: 14,
            reduceMotion: reduce,
            // Design/Figma: black outline trophy, gold disc shows through.
            child: LucideTrophyIcon(
              key: const ValueKey('t9-trophy-outline'),
              size: context.dp(48),
              color: LucideTrophyIcon.kOutline,
              strokeWidth: 2.0,
            ),
          ),
          SizedBox(height: context.dp(20)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.dp(13),
              vertical: context.dp(6),
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF6DB), Color(0xFFF8E2AD)],
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0xFFD8A028).withValues(alpha: 0.46),
              ),
            ),
            child: Text(
              l10n.celebrationSeasonPillFinal(season).toUpperCase(),
              style: aeLabel(color: const Color(0xFF7A5410)).copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 10.5,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ],
      ),
      title: copy.title(item),
      subtitle: copy.body(item),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seasonPrimaryCta(
            context: context,
            label: l10n.celebrationCtaSeason,
            onPressed: () => finishAnd(onCta),
          ),
          SizedBox(height: context.dp(10)),
          TextButton(
            onPressed: () {
              Navigator.of(context).maybePop();
              onDismiss();
              final nav = navigatorKey.currentState;
              if (nav != null) {
                nav.push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LeaderboardScreen(),
                  ),
                );
              }
            },
            child: Text(
              l10n.celebrationCtaTable,
              style: aeLabel(
                color: Colors.white.withValues(alpha: 0.72),
              ).copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Season 2nd/3rd place finale (`.dgseq-cup.p2` / `.p3`) — same stage as T9.
  /// Place and copy come from backend `final_position` (2 = silver, 3 = bronze).
  static Future<void> _showSeasonPlace(
    BuildContext context, {
    required PendingCelebration item,
    required VoidCallback onDismiss,
    VoidCallback? onCta,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final copy = CelebrationCopy(l10n);
    final seasonStamp = dugnadFormatSeasonTag(
      item.stringPayload('season_label'),
    );
    final season = seasonStamp.isNotEmpty ? seasonStamp : '25/26';
    final place = item.intPayload('final_position') ?? 3;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final isSilver = place == 2;

    final discColors = isSilver
        ? DugnadBeadBadge.kDiscSilver
        : DugnadBeadBadge.kDiscBronze;
    final beadColor = isSilver
        ? DugnadBeadBadge.kLaurelSilver
        : DugnadBeadBadge.kLaurelBronze;
    final medal = isSilver ? '🥈' : '🥉';
    final stampFg =
        isSilver ? const Color(0xFF46525F) : const Color(0xFF6B431C);
    final stampBorder = isSilver
        ? const Color(0xFF7A8694).withValues(alpha: 0.44)
        : const Color(0xFF9D5F30).withValues(alpha: 0.42);
    final stampGradient = isSilver
        ? const [Color(0xFFFBFCFF), Color(0xFFE6EBF1)]
        : const [Color(0xFFFDF1E4), Color(0xFFF2D9BD)];

    void finishAnd(VoidCallback? next) {
      Navigator.of(context).maybePop();
      if (next != null) {
        next();
      } else {
        onDismiss();
      }
    }

    return DugnadCeremonialScreen.show(
      context,
      onDismiss: onDismiss,
      showCloseButton: true,
      showSpotlight: true,
      tapToDismiss: false,
      confettiPieces: 75,
      hero: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DugnadBeadBadge(
            size: context.dp(168),
            beadCount: 14,
            reduceMotion: reduce,
            discColors: discColors,
            beadColor: beadColor,
            glowColor: discColors.last,
            // Design: medal emoji in the disc (not trophy / club crest).
            child: Text(
              medal,
              style: TextStyle(
                fontSize: context.dp(58),
                height: 1,
                shadows: const [
                  Shadow(
                    color: Color(0x4D140C28),
                    blurRadius: 4,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: context.dp(20)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.dp(13),
              vertical: context.dp(6),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: stampGradient,
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: stampBorder),
            ),
            child: Text(
              l10n.celebrationSeasonPillFinal(season).toUpperCase(),
              style: aeLabel(color: stampFg).copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 10.5,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ],
      ),
      title: copy.title(item),
      subtitle: copy.body(item),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seasonPrimaryCta(
            context: context,
            label: l10n.celebrationCtaSeason,
            onPressed: () => finishAnd(onCta),
          ),
          SizedBox(height: context.dp(10)),
          TextButton(
            onPressed: () {
              Navigator.of(context).maybePop();
              onDismiss();
              final nav = navigatorKey.currentState;
              if (nav != null) {
                nav.push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LeaderboardScreen(),
                  ),
                );
              }
            },
            child: Text(
              l10n.celebrationCtaTable,
              style: aeLabel(
                color: Colors.white.withValues(alpha: 0.72),
              ).copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _personalBadgeEmoji(CelebrationType type) {
    switch (type) {
      case CelebrationType.t10:
        return '⚽';
      case CelebrationType.t11:
        return '🅰️';
      case CelebrationType.t12:
        return '👑';
      default:
        return '🏆';
    }
  }

  static String _personalSecondaryCta(
    AppLocalizations l10n,
    CelebrationType type,
  ) {
    switch (type) {
      case CelebrationType.t10:
        return l10n.celebrationCtaScorers;
      case CelebrationType.t11:
        return l10n.celebrationCtaAssists;
      case CelebrationType.t12:
        return l10n.celebrationCtaSto;
      default:
        return l10n.celebrationCtaSeason;
    }
  }

  static Widget _personalSecondaryPage(CelebrationType type) {
    switch (type) {
      case CelebrationType.t10:
        return const LeaderboardScreen(openTopScorerTab: true);
      case CelebrationType.t11:
        return const LeaderboardScreen(openAssistTab: true);
      case CelebrationType.t12:
        return const LeaderboardScreen(openStoTab: true);
      default:
        return const SeasonRecapScreen();
    }
  }

  static Future<void> _showPersonalTitle(
    BuildContext context, {
    required PendingCelebration item,
    required VoidCallback onDismiss,
    VoidCallback? onCta,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final copy = CelebrationCopy(l10n);
    final seasonStamp = dugnadFormatSeasonTag(
      item.stringPayload('season_label'),
    );
    final season = seasonStamp.isNotEmpty ? seasonStamp : '25/26';
    final emoji = _personalBadgeEmoji(item.type);
    final name = item.stringPayload('display_name') ??
        item.stringPayload('user_name');

    void finishAnd(VoidCallback? next) {
      Navigator.of(context).maybePop();
      if (next != null) {
        next();
      } else {
        onDismiss();
      }
    }

    return DugnadCeremonialScreen.show(
      context,
      onDismiss: onDismiss,
      showCloseButton: true,
      showSpotlight: true,
      tapToDismiss: false,
      confettiPieces: 70,
      hero: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DugnadThronePlayerHero(
            badgeEmoji: emoji,
            displayName: name,
          ),
          SizedBox(height: context.dp(18)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.dp(12),
              vertical: context.dp(6),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE8D4A8),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              l10n.celebrationSeasonPillFinal(season).toUpperCase(),
              style: aeLabel(color: const Color(0xFF6B5420)).copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
      title: copy.title(item),
      subtitle: copy.body(item),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seasonPrimaryCta(
            context: context,
            label: l10n.celebrationCtaSeason,
            onPressed: () => finishAnd(onCta),
          ),
          SizedBox(height: context.dp(12)),
          TextButton(
            onPressed: () {
              Navigator.of(context).maybePop();
              onDismiss();
              final nav = navigatorKey.currentState;
              if (nav != null) {
                nav.push(
                  MaterialPageRoute<void>(
                    builder: (_) => _personalSecondaryPage(item.type),
                  ),
                );
              }
            },
            child: Text(
              _personalSecondaryCta(l10n, item.type),
              style: aeLabel(color: Colors.white).copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
