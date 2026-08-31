import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../commonView/ae_inset_surface.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/ae_typography.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_theme.dart';
import '../../../ui/kit/ae_sheet.dart';
import '../donation_setup_screen.dart';
import '../kampanje_screen.dart';
import '../leaderboard_screen.dart';
import '../referral_share_screen.dart';

/// Home feed row — opens [showDugnadEarnSheet].
class DugnadEarnPointsEntry extends StatelessWidget {
  const DugnadEarnPointsEntry({
    super.key,
    required this.clubName,
    required this.onTap,
  });

  final String clubName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(context.dp(12)),
        child: Padding(
          // `padding: 4px 4px 0` with `marginTop: 2` on the button itself.
          padding: EdgeInsets.fromLTRB(
            context.dp(4),
            context.dp(4) + context.dp(2),
            context.dp(4),
            context.dp(0),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: context.dp(15),
                          color: theme.primary,
                        ),
                        SizedBox(width: context.dp(7)),
                        Expanded(
                          child: Text(
                            languages.dugnadEarnMostPointsTitle,
                            style: aeBody(color: theme.text).copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: 15 * -0.01,
                            ).dp(context),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.dp(3)),
                    Padding(
                      padding: EdgeInsets.only(left: context.dp(22)),
                      child: Text(
                        languages.dugnadEarnMostPointsSub(clubName),
                        style: aeCaption().copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ).dp(context),
                      ),
                    ),
                  ],
                ),
              ),
              // The button's outer flex has `gap: 10`.
              SizedBox(width: context.dp(10)),
              Container(
                width: context.dp(28),
                height: context.dp(28),
                decoration: BoxDecoration(
                  color: theme.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: context.dp(16),
                  // `--ae-purple-700`, not purple-600 — the chevron is a step
                  // darker than the sparkle above it.
                  color: theme.primaryHover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DugnadEarnSheetPoints {
  const DugnadEarnSheetPoints({
    required this.campaign,
    required this.referral,
    required this.donationPerMonth,
  });

  final int campaign;
  final int referral;
  final int donationPerMonth;
}

Future<void> showDugnadEarnSheet(
  BuildContext context, {
  required String clubName,
  required DugnadEarnSheetPoints points,
}) {
  return showAeSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _DugnadEarnSheetBody(
      clubName: clubName,
      points: points,
    ),
  );
}

class _DugnadEarnSheetBody extends StatelessWidget {
  const _DugnadEarnSheetBody({
    required this.clubName,
    required this.points,
  });

  final String clubName;
  final DugnadEarnSheetPoints points;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(context.dp(0), context.dp(10), context.dp(0), bottomInset + context.dp(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AeSheetHandle(bottom: 12),
          Padding(
            padding: EdgeInsets.fromLTRB(context.dp(18), context.dp(4), context.dp(12), context.dp(0)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languages.dugnadHowYouEarnPoints,
                        style: aeH2(color: theme.text).copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ).dp(context),
                      ),
                      SizedBox(height: context.dp(4)),
                      Text(
                        languages.dugnadEarnSheetSubtitle(clubName),
                        style: aeCaption().copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ).dp(context),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    aeSheetCloseHaptic();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close_rounded),
                  color: ScSaasThemeTokens.gray500,
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(context.dp(16), context.dp(8), context.dp(16), context.dp(0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(context.dp(14), context.dp(13), context.dp(14), context.dp(13)),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.primaryTint.withValues(alpha: 0.45),
                          theme.primaryTint.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(context.dp(15)),
                      border: Border.all(
                        color: theme.primaryTint.withValues(alpha: 0.7),
                      ),
                      // Design intro: 0 1px 2px .06 + 0 8px 18px -12px .3
                      // Flutter paints CSS .3 as mud — use card-token alphas.
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0F2D1B5B),
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                        BoxShadow(
                          color: Color(0x1F2D1B5B),
                          offset: Offset(0, 8),
                          blurRadius: 18,
                          spreadRadius: -12,
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: context.dp(18),
                          color: theme.primary,
                        ),
                        SizedBox(width: context.dp(11)),
                        Expanded(
                          child: Text(
                            languages.dugnadEarnSheetIntro,
                            style: aeCaption(color: ScSaasThemeTokens.gray700)
                                .copyWith(
                              fontSize: 12.5,
                              height: 1.5,
                            ).dp(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.dp(16)),
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: context.dp(14),
                        color: theme.primary,
                      ),
                      SizedBox(width: context.dp(7)),
                      Text(
                        languages.dugnadEarnSheetActivitiesLabel,
                        style: aeOverline(color: theme.primary).copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 12.5 * 0.06,
                        ).dp(context),
                      ),
                    ],
                  ),
                  SizedBox(height: context.dp(10)),
                  _EarnActivityRow(
                    icon: Icons.inventory_2_outlined,
                    gradient: LinearGradient(
                      colors: [theme.primarySoft, theme.primary],
                    ),
                    title: languages.dugnadBuyCampaign,
                    subtitle: languages.dugnadEarnBuyCampaignDesc,
                    pointsLabel: '+${points.campaign}',
                    onTap: () {
                      Navigator.pop(context);
                      openScreen(context, const KampanjeScreen());
                    },
                  ),
                  _EarnActivityRow(
                    icon: Icons.share_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7FD0C4), Color(0xFF2F9C8A)],
                    ),
                    title: languages.dugnadReferFriend,
                    subtitle: languages.dugnadEarnReferDesc(clubName),
                    pointsLabel: '+${points.referral}',
                    onTap: () {
                      Navigator.pop(context);
                      openScreen(context, const ReferralShareScreen());
                    },
                  ),
                  _EarnActivityRow(
                    icon: Icons.favorite_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE89BB8), Color(0xFFB8557E)],
                    ),
                    title: languages.dugnadRegularSupport,
                    subtitle: languages.dugnadEarnDonationDesc,
                    pointsLabel: languages.dugnadEarnDonationPtsPerMonth(
                      points.donationPerMonth,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      openScreen(context, const DonationSetupScreen());
                    },
                  ),
                  _EarnActivityRow(
                    icon: Icons.emoji_events_outlined,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF4D06A), Color(0xFFD8A93A)],
                    ),
                    title: languages.dugnadLeaderboardSectionTitle,
                    subtitle: languages.dugnadEarnLeaderboardDesc,
                    pointsLabel: languages.dugnadEarnTeamPointsLabel,
                    onTap: () {
                      Navigator.pop(context);
                      openScreen(context, const LeaderboardScreen());
                    },
                  ),
                  SizedBox(height: context.dp(16)),
                  Text(
                    languages.dugnadEarnSheetTapHint,
                    textAlign: TextAlign.center,
                    style: aeCaption().copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ).dp(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarnActivityRow extends StatelessWidget {
  const _EarnActivityRow({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.pointsLabel,
    required this.onTap,
  });

  final IconData icon;
  final Gradient gradient;
  final String title;
  final String subtitle;
  final String pointsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: context.dp(10)),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: AeInsetSurface(
          borderRadius: BorderRadius.circular(context.dp(16)),
          color: Colors.white,
          border: Border.all(color: const Color(0x0D2D1B5B)),
          insets: [
            AeSurfaceInset.top(
              Colors.white.withValues(alpha: 0.9),
              extentPx: 1,
            ),
          ],
          // `.dg-earnrow` = same relief as `--ae-shadow-card` (not CSS .38,
          // which Flutter renders as a black smear).
          shadows: ScSaasThemeTokens.shadowCard,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.dp(13),
              context.dp(12),
              context.dp(13),
              context.dp(12),
            ),
            child: Row(
              children: [
                AeInsetSurface(
                  borderRadius: BorderRadius.circular(context.dp(13)),
                  gradient: gradient,
                  insets: [
                    AeSurfaceInset.top(
                      Colors.white.withValues(alpha: 0.30),
                      extentPx: 1,
                    ),
                  ],
                  shadows: const [
                    BoxShadow(
                      color: Color(0x1A2D1B5B),
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                    BoxShadow(
                      color: Color(0x2E2D1B5B),
                      offset: Offset(0, 8),
                      blurRadius: 16,
                      spreadRadius: -8,
                    ),
                  ],
                  child: SizedBox(
                    width: context.dp(46),
                    height: context.dp(46),
                    child: Icon(icon, color: Colors.white, size: context.dp(20)),
                  ),
                ),
                SizedBox(width: context.dp(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: aeBody(color: theme.text).copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ).dp(context),
                      ),
                      SizedBox(height: context.dp(2)),
                      Text(
                        subtitle,
                        style: aeCaption().copyWith(fontSize: 11.5).dp(context),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.dp(9),
                    vertical: context.dp(5),
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryTint,
                    borderRadius: BorderRadius.circular(context.dp(9)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: context.dp(11),
                        color: theme.primaryHover,
                      ),
                      SizedBox(width: context.dp(4)),
                      Text(
                        pointsLabel,
                        style: aeCaption(color: theme.primaryHover).copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ).dp(context),
                      ),
                    ],
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
