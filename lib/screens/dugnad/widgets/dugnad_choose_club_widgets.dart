import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/ae_typography.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../dugnad_club_theme.dart';
import '../dugnad_models.dart';
import '../dugnad_state.dart';

/// White REEN wordmark for navy heroes (browse-without-club).
class DugnadReenLogo extends StatelessWidget {
  const DugnadReenLogo({super.key, this.height = 28});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/Logo/reen-logo-white.svg',
      height: context.dp(height),
      fit: BoxFit.contain,
    );
  }
}

/// Home-feed card — mock `.dg-choose-club` (white card + gradient CTA).
class DugnadChooseClubHomeCard extends StatelessWidget {
  const DugnadChooseClubHomeCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    const cardTitle = Color(0xFF16304F);
    const cardBody = Color(0xFF6D7684);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.dp(18)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(20)),
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.dp(44),
            height: context.dp(44),
            decoration: BoxDecoration(
              gradient: theme.shinyGradient,
              borderRadius: BorderRadius.circular(context.dp(13)),
              boxShadow: [
                BoxShadow(
                  color: theme.primary.withValues(alpha: 0.26),
                  blurRadius: context.dp(18),
                  offset: Offset(0, context.dp(8)),
                  spreadRadius: context.dp(-5),
                ),
              ],
            ),
            child: Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: context.dp(22),
            ),
          ),
          SizedBox(height: context.dp(14)),
          Text(
            languages.dugnadChooseClubHomeCardTitle,
            style: aeH3(color: cardTitle)
                .copyWith(fontWeight: FontWeight.w800, fontSize: 18)
                .dp(context),
          ),
          SizedBox(height: context.dp(8)),
          Text(
            languages.dugnadChooseClubHomeCardBody,
            style: aeBody(color: cardBody)
                .copyWith(fontSize: 13.5, height: 1.5, fontWeight: FontWeight.w500)
                .dp(context),
          ),
          SizedBox(height: context.dp(16)),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: context.dp(14)),
              decoration: BoxDecoration(
                gradient: theme.shinyGradient,
                borderRadius: BorderRadius.circular(context.dp(14)),
                boxShadow: theme.shadowButton,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    languages.dugnadChooseClubHomeCardCta,
                    style: aeLabel(color: Colors.white)
                        .copyWith(fontWeight: FontWeight.w800, fontSize: 15)
                        .dp(context),
                  ),
                  SizedBox(width: context.dp(4)),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.white, size: context.dp(20)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder campaigns shown under blur when browsing without a club.
List<ClubCampaignSummary> dugnadDummyCampaigns() {
  return const [
    ClubCampaignSummary(
      id: -1,
      name: 'Matkasse',
      slug: 'demo-matkasse-1',
      teamName: 'Gutter 16–17',
      productCount: 12,
      minPrice: 299,
      totalOrdersCount: 48,
      totalRevenueNok: 14200,
    ),
    ClubCampaignSummary(
      id: -2,
      name: 'Matkasse',
      slug: 'demo-matkasse-2',
      teamName: 'Jenter 16–17',
      productCount: 10,
      minPrice: 279,
      totalOrdersCount: 36,
      totalRevenueNok: 9800,
    ),
    ClubCampaignSummary(
      id: -3,
      name: 'Matkasse',
      slug: 'demo-matkasse-3',
      teamName: 'Gutter 14–15',
      productCount: 11,
      minPrice: 289,
      totalOrdersCount: 22,
      totalRevenueNok: 6400,
    ),
  ];
}

/// Whether a feed section should show the guest/club browse lock overlay.
bool dugnadBrowseSectionLocked() {
  return !DugnadState.instance.hasClub || !isLoggedIn();
}

/// Lock pill label — choose-club copy when no club, guest copy otherwise.
String dugnadBrowseLockLabel({
  required String guestLabel,
  required String clubLabel,
}) {
  if (!DugnadState.instance.hasClub) return clubLabel;
  if (!isLoggedIn()) return guestLabel;
  return guestLabel;
}
