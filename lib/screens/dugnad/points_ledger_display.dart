import '../../l10n/app_localizations.dart';
import 'dugnad_models.dart';

class PointsLedgerDisplay {
  final String title;
  final String? subtitle;

  const PointsLedgerDisplay({
    required this.title,
    this.subtitle,
  });
}

PointsLedgerDisplay pointsLedgerDisplay(
  PointsLedgerEntry entry,
  AppLocalizations languages,
) {
  final action = entry.action;
  final meta = entry.meta;

  switch (action) {
    case 'campaign_purchase':
      return PointsLedgerDisplay(title: languages.dugnadPointsActionCampaign);
    case 'subscription_donation':
      return PointsLedgerDisplay(title: languages.dugnadPointsActionDonation);
    case 'referral':
      return PointsLedgerDisplay(
        title: languages.dugnadPointsActionReferral,
        subtitle: meta.referralSequence != null
            ? languages.dugnadPointsReferralConversionDetail(
                meta.referralSequence!,
              )
            : null,
      );
    case 'referred_join':
      return PointsLedgerDisplay(title: languages.dugnadPointsActionReferral);
    case 'referral_milestone':
      return PointsLedgerDisplay(
        title: languages.dugnadPointsActionReferralMilestone,
        subtitle: meta.milestoneCount != null
            ? languages.dugnadPointsReferralMilestoneDetail(meta.milestoneCount!)
            : null,
      );
    case 'campaign_purchase_reversal':
      return PointsLedgerDisplay(
        title: languages.dugnadPointsActionCampaignReversal,
      );
    case 'subscription_donation_reversal':
      return PointsLedgerDisplay(
        title: languages.dugnadPointsActionDonationReversal,
      );
    case 'referral_reversal':
      return PointsLedgerDisplay(
        title: languages.dugnadPointsActionReferralReversal,
        subtitle: meta.referralSequence != null
            ? languages.dugnadPointsReferralConversionDetail(
                meta.referralSequence!,
              )
            : null,
      );
    case 'referral_milestone_reversal':
      return PointsLedgerDisplay(
        title: languages.dugnadPointsActionReferralMilestoneReversal,
        subtitle: meta.milestoneCount != null
            ? languages.dugnadPointsReferralMilestoneDetail(meta.milestoneCount!)
            : null,
      );
    case 'weekly_challenge_bonus':
      return PointsLedgerDisplay(title: 'Ukesoppdrag fullført');
    case 'season_goal_bonus':
      return PointsLedgerDisplay(title: 'Sesongmål fullført');
    case 'streak_bonus':
      return PointsLedgerDisplay(title: 'Streak-bonus');
    case 'badge_unlock':
      return PointsLedgerDisplay(title: 'Merke låst opp');
    case 'season_carryover':
      return PointsLedgerDisplay(title: 'Sesong-carryover');
    default:
      return PointsLedgerDisplay(title: _humanizeAction(action));
  }
}

String _humanizeAction(String action) {
  if (action.isEmpty) return action;
  return action
      .split('_')
      .where((part) => part.isNotEmpty)
      .map(
        (part) => part.length == 1
            ? part.toUpperCase()
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}
