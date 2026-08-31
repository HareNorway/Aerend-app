import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../commonView/skeleton_loaders/dugnad_subpage_skeletons.dart';
import '../../theme/design_scale.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import 'dugnad_club_branding.dart';
import 'dugnad_models.dart';
import 'dugnad_repo.dart';
import 'dugnad_share.dart';
import 'dugnad_state.dart';
import 'widgets/ae_sheen.dart';
import 'widgets/dugnad_points_earn.dart';
import 'widgets/dugnad_subpage_shell.dart';
import 'widgets/dugnad_rise_in.dart';
import 'dugnad_club_theme.dart';

/// Club-level referral share screen (prototype: ClubReferral in club-select.jsx).
class ReferralShareScreen extends StatefulWidget {
  const ReferralShareScreen({super.key});

  @override
  State<ReferralShareScreen> createState() => _ReferralShareScreenState();
}

class _ReferralShareScreenState extends State<ReferralShareScreen> {
  final DugnadRepo _repo = DugnadRepo();
  ReferralSummary? _summary;
  bool _loading = true;
  int? _loadedClubId;

  @override
  void initState() {
    super.initState();
    DugnadState.instance.revision.addListener(_onClubChanged);
    _load();
  }

  @override
  void dispose() {
    DugnadState.instance.revision.removeListener(_onClubChanged);
    super.dispose();
  }

  void _onClubChanged() {
    final clubId = DugnadState.instance.clubId;
    if (!mounted || clubId == _loadedClubId) return;
    _load();
  }

  Future<void> _load() async {
    if (!DugnadState.instance.hasClub) {
      _loadedClubId = null;
      if (mounted) {
        setState(() {
          _summary = null;
          _loading = false;
        });
      }
      return;
    }

    final clubId = DugnadState.instance.clubId;
    setState(() => _loading = true);
    final summary = await _repo.getReferralSummary(organizationId: clubId);
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _loading = false;
      _loadedClubId = clubId;
    });
  }

  Future<void> _copy(String value) async {
    HapticFeedback.lightImpact();
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    openSimpleSnackbar(languages.referralCopied);
  }

  Future<void> _share(BuildContext shareContext, String link, String code) async {
    HapticFeedback.lightImpact();
    final club = _referralClubLabel(compact: true);
    await shareDugnadText(
      shareContext,
      text: languages.dugnadReferralShareMessage(club, link, code),
      subject: languages.dugnadReferralShareSubject(club),
    );
  }

  String _referralClubLabel({required bool compact}) {
    final fromSummary = compact
        ? _summary?.organizationShortName
        : _summary?.organizationName;
    if (fromSummary != null && fromSummary.trim().isNotEmpty) {
      return fromSummary.trim();
    }
    return compact
        ? DugnadClubBranding.compactName()
        : DugnadClubBranding.fullName();
  }

  @override
  Widget build(BuildContext context) {
    final clubName = DugnadClubBranding.fullName();
    final clubLogo = DugnadState.instance.clubLogo;

    return DugnadFixedTypography(
      child: Scaffold(
        // Club primary under the hero/feed shell so pull-down never flashes
        // lavender through the overlap seam.
        backgroundColor: context.dugnadTheme.primary,
        body: DugnadLbScrollBody(
          hero: DugnadLbHero(
            clubName: clubName,
            clubLogo: clubLogo,
            title: languages.dugnadReferralTitle,
            subtitle: languages.dugnadReferFriendsSubtitle,
            subtitleWithHeart: true,
            onBack: () => Navigator.pop(context),
          ),
          // `.dn-feed` — 18px gap, 22px top radius, room for floating nav.
          itemGap: 18,
          topPadding: 18,
          feedRadius: 22,
          overlap: 12,
          bottomPadding: 120,
          children: _loading
              ? const [DugnadReferralFeedSkeleton()]
              : [
                  _riseIn(0, _buildShareCard()),
                  _riseIn(1, _buildPointsCard()),
                  _riseIn(2, _buildStatsRow()),
                  _riseIn(3, _buildAmbassadorCard()),
                  _riseIn(4, _buildSteps()),
                  if (_summary?.recentReferrals.isNotEmpty ?? false)
                    _riseIn(5, _buildRecruits()),
                ],
        ),
      ),
    );
  }

  Widget _buildShareCard() {
    final theme = context.dugnadTheme;
    final code = _summary?.referralCode ?? '—';
    final link = _summary?.referralLink ?? '';
    // Club primary → subtle magenta (mock: red/navy cards bleed into magenta).
    const magenta = Color(0xFFC43B9A);
    final gradientEnd =
        Color.lerp(theme.primary, magenta, 0.78) ?? magenta;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.dp(20)),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [theme.primary, gradientEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.55),
            blurRadius: context.dp(28),
            offset: const Offset(0, 14),
            spreadRadius: -14,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(context.dp(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.share_rounded,
                  size: context.dp(13),
                  color: Colors.white.withValues(alpha: 0.92),
                ),
                SizedBox(width: context.dp(6)),
                Text(
                  languages.dugnadReferralYourLink.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 11 * 0.04,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.dp(9)),
            Text(
              code,
              style: AeDugnadText.referralCode(color: Colors.white),
            ),
            if (link.isNotEmpty) ...[
              SizedBox(height: context.dp(5)),
              Row(
                children: [
                  Icon(
                    Icons.link_rounded,
                    size: context.dp(13),
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  SizedBox(width: context.dp(6)),
                  Expanded(
                    child: Text(
                      link,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: context.dp(16)),
            Row(
              children: [
                Expanded(
                  child: _refActionButton(
                    label: languages.dugnadReferralCopyLink,
                    icon: Icons.content_copy_rounded,
                    filled: true,
                    onTap: link.isEmpty ? null : () => _copy(link),
                  ),
                ),
                SizedBox(width: context.dp(9)),
                _refActionButton(
                  label: languages.post_detail_share_action,
                  icon: Icons.share_rounded,
                  filled: false,
                  onTap: link.isEmpty ? null : () => _share(context, link, code),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _refActionButton({
    required String label,
    required IconData icon,
    required bool filled,
    VoidCallback? onTap,
  }) {
    final accent = context.dugnadTheme.primary;
    final radius = BorderRadius.circular(context.dp(12));

    return Material(
      color: filled ? Colors.white : Colors.white.withValues(alpha: 0.2),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.dp(16),
            vertical: context.dp(12),
          ),
          decoration: filled
              ? null
              : BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: filled ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: context.dp(16),
                color: filled ? accent : Colors.white,
              ),
              SizedBox(width: context.dp(7)),
              Text(
                label,
                style: TextStyle(
                  color: filled ? accent : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  letterSpacing: -0.01 * 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsCard() {
    final points = _summary?.referralPoints ?? 100;
    return DugnadPointsEarn(
      points: points,
      title: languages.dugnadReferralPointsTitle,
      subtitle: languages.dugnadReferralPointsSubtitle(points),
    );
  }

  Widget _buildStatsRow() {
    final count = _summary?.convertedCount ?? 0;
    return Row(
      children: [
        Expanded(
          child: _statTile('$count', languages.dugnadReferralConvertedCount),
        ),
        SizedBox(width: context.dp(11)),
        Expanded(
          child: _statTile(
            '${_summary?.referralPoints ?? 100}',
            languages.dugnadReferralPointsPerConversion,
          ),
        ),
      ],
    );
  }

  Widget _statTile(String value, String label) {
    return Container(
      padding: EdgeInsets.all(context.dp(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(16)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D2D1B5B),
            blurRadius: context.dp(4),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AeDugnadText.statTileValue(),
          ),
          SizedBox(height: context.dp(3)),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AeDugnadText.statTileLabel(),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbassadorCard() {
    final count = _summary?.convertedCount ?? 0;
    final goal = _summary?.ambassadorGoal ?? 5;
    final left = (goal - count).clamp(0, goal);
    final pct = goal > 0 ? (count / goal).clamp(0.0, 1.0) : 0.0;
    final iconRadius = context.dp(11);

    return Container(
      padding: EdgeInsets.all(context.dp(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(16)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D2D1B5B),
            blurRadius: context.dp(4),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // `.dg-ref-prog .ic` — 38×38 rounded square (not oval sheen).
              Container(
                width: context.dp(38),
                height: context.dp(38),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFE9A8),
                      Color(0xFFF6CF6B),
                      Color(0xFFE7B542),
                    ],
                    stops: [0, 0.48, 1],
                  ),
                  borderRadius: BorderRadius.circular(iconRadius),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD8A028).withValues(alpha: 0.7),
                      blurRadius: context.dp(14),
                      offset: Offset(0, context.dp(6)),
                      spreadRadius: context.dp(-8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: const Color(0xFF5B4410),
                      size: context.dp(16),
                    ),
                    const Positioned.fill(
                      child: AeSheen(
                        curve: AeSheenCurve.lbSheen,
                        period: Duration(milliseconds: 6500),
                        bandWidthFactor: 0.55,
                        highlight: Color(0x66FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.dp(11)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languages.dugnadReferralAmbassadorTitle,
                      style: aeTitle().copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: context.dp(2)),
                    Text(
                      left > 0
                          ? languages.dugnadReferralAmbassadorProgress(left)
                          : languages.dugnadReferralAmbassadorDone,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: ScSaasThemeTokens.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$count/$goal',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: context.dugnadTheme.text,
                ),
              ),
            ],
          ),
          SizedBox(height: context.dp(12)),
          ClipRRect(
            borderRadius: BorderRadius.circular(context.dp(99)),
            child: SizedBox(
              height: context.dp(8),
              child: Stack(
                children: [
                  Container(color: const Color(0xFFF0EEF5)),
                  FractionallySizedBox(
                    widthFactor: pct,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF7D979), Color(0xFFE0A93A)],
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
    );
  }

  Widget _buildSteps() {
    final theme = context.dugnadTheme;
    final club = _referralClubLabel(compact: true);
    final steps = [
      (
        languages.dugnadReferralStep1Title,
        languages.dugnadReferralStep1Subtitle,
      ),
      (
        languages.dugnadReferralStep2Title,
        languages.dugnadReferralStep2Subtitle(club),
      ),
      (
        languages.dugnadReferralStep3Title,
        languages.dugnadReferralStep3Subtitle(club),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DugnadSectionLabel(languages.dugnadReferralHowItWorks),
        ...steps.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final step = entry.value;
          return Padding(
            padding: EdgeInsets.only(top: entry.key > 0 ? context.dp(8) : 0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.dp(14), vertical: context.dp(12)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(context.dp(14)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A2D1B5B),
                    blurRadius: context.dp(2),
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: context.dp(28),
                    height: context.dp(28),
                    decoration: BoxDecoration(
                      color: theme.primaryTint,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$index',
                      style: TextStyle(
                        color: theme.primaryHover,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  SizedBox(width: context.dp(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.$1,
                          style: aeTitle().copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                        SizedBox(height: context.dp(2)),
                        Text(
                          step.$2,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: ScSaasThemeTokens.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRecruits() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DugnadSectionLabel(languages.dugnadReferralYourRecruits),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.dp(16)),
            boxShadow: [
              BoxShadow(
                color: Color(0x0D2D1B5B),
                blurRadius: context.dp(4),
                offset: Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: _summary!.recentReferrals.asMap().entries.map((entry) {
              final index = entry.key;
              final record = entry.value;
              return Column(
                children: [
                  if (index > 0)
                    Divider(height: context.dp(1), color: Color(0xFFF0EEF5)),
                  _recruitRow(record),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _recruitRow(ReferralRecord record) {
    final theme = context.dugnadTheme;
    final isConverted = record.status == 'converted';
    final isPending = !record.referredIsVerified;
    final name =
        record.referredDisplayName ?? languages.dugnadReferralPendingInvite;
    final subtitle = isConverted
        ? languages.dugnadReferralActive
        : (record.referredIsVerified
            ? languages.dugnadReferralWaitingFirstPurchase
            : languages.dugnadReferralPending);

    return Padding(
      key: ValueKey('referral-${record.id}-${record.referredUserId ?? 0}'),
      padding: EdgeInsets.symmetric(horizontal: context.dp(14), vertical: context.dp(12)),
      child: Row(
        children: [
          Container(
            width: context.dp(36),
            height: context.dp(36),
            decoration: BoxDecoration(
              color: isPending
                  ? const Color(0xFFF0EEF5)
                  : theme.primaryTint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_rounded,
              color: isPending
                  ? ScSaasThemeTokens.gray500
                  : theme.primaryHover,
              size: context.dp(16),
            ),
          ),
          SizedBox(width: context.dp(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: aeTitle().copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: AeFontSize.titleMd,
                  ),
                ),
                Text(
                  subtitle,
                  style: AeDugnadText.bannerSubtitle(),
                ),
              ],
            ),
          ),
          Container(
            width: context.dp(26),
            height: context.dp(26),
            decoration: BoxDecoration(
              color: isConverted
                  ? const Color(0x2922A769)
                  : const Color(0xFFF0EEF5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isConverted ? Icons.check_rounded : Icons.schedule_rounded,
              color: isConverted
                  ? const Color(0xFF22A769)
                  : ScSaasThemeTokens.gray500,
              size: context.dp(14),
            ),
          ),
        ],
      ),
    );
  }
}

/// Canonical `au-rise` entrance cadence (dugnad.css / splash.css): the first
/// block rises at 120ms, then roughly 70ms apart; trailing blocks use the
/// 550ms duration and ~50ms spacing of the `.auth-bottom` group. Blocks past
/// the first screenful render immediately rather than animating out of view.
Widget _riseIn(int index, Widget child) {
  if (index > 6) return child;
  return DugnadRiseIn(
    delay: Duration(
      milliseconds: index < 4 ? 120 + index * 70 : 400 + (index - 4) * 50,
    ),
    duration: Duration(milliseconds: index < 4 ? 600 : 550),
    child: child,
  );
}
