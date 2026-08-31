import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/design_scale.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import 'donation_fee_calculator.dart';
import 'donation_manage_screen.dart';
import 'dugnad_club_branding.dart';
import 'dugnad_club_theme.dart';
import 'dugnad_models.dart';
import 'dugnad_repo.dart';
import 'dugnad_state.dart';
import 'kampanje_screen.dart';
import 'widgets/dugnad_confetti.dart';
import 'widgets/dugnad_points_pop.dart';
import 'widgets/dugnad_rise_in.dart';
import 'widgets/dugnad_support_share.dart';

/// Shown after Vipps agreement sync succeeds.
class DonationConfirmScreen extends StatefulWidget {
  final DonationSubscriptionRecord subscription;
  final bool activated;

  const DonationConfirmScreen({
    super.key,
    required this.subscription,
    this.activated = true,
  });

  @override
  State<DonationConfirmScreen> createState() => _DonationConfirmScreenState();
}

class _DonationConfirmScreenState extends State<DonationConfirmScreen>
    with SingleTickerProviderStateMixin {
  final DugnadRepo _repo = DugnadRepo();
  DonationFeePreview? _feePreview;
  late final AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !MediaQuery.disableAnimationsOf(context)) {
        _confettiController.forward();
      }
      HapticFeedback.mediumImpact();
    });
    _loadFeePreview();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadFeePreview() async {
    final amount = widget.subscription.amountKr.round();
    if (amount <= 0) return;
    final preview = await _repo.donationFeePreview(amount);
    if (mounted) setState(() => _feePreview = preview);
  }

  DonationFeeBreakdown get _feeBreakdown {
    final amount = widget.subscription.amountKr.round();
    final preview = _feePreview;
    if (preview != null && preview.amountKr == amount && amount > 0) {
      final feeKr = preview.totalFeeKr.round();
      final netKr = preview.netToBeneficiaryKr.round();
      final tx = (feeKr / 2).round();
      return DonationFeeBreakdown(
        grossKr: amount,
        feeKr: feeKr,
        netKr: netKr,
        transactionFeeKr: tx,
        platformFeeKr: feeKr - tx,
      );
    }
    return DonationFeeCalculator.forAmountKr(amount);
  }

  int get _points {
    final preview = _feePreview;
    final amount = widget.subscription.amountKr.round();
    if (preview != null &&
        preview.amountKr == amount &&
        preview.estimatedPoints > 0) {
      return preview.estimatedPoints;
    }
    return DonationFeeCalculator.previewPointsForAmountKr(amount);
  }

  String _formatKr(int value) =>
      value.toString().replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]} ',
          );

  String get _teamName => widget.subscription.targetLabel;

  String get _clubName => DugnadClubBranding.fullName();

  String get _clubShort => DugnadClubBranding.compactName();

  String? get _teamLogo {
    final ds = DugnadState.instance;
    if (widget.subscription.teamId != null &&
        ds.hasPointsTeam &&
        ds.pointsTeamId == widget.subscription.teamId &&
        ds.pointsTeamLogo.isNotEmpty) {
      return ds.pointsTeamLogo;
    }
    return ds.clubLogo.isEmpty ? null : ds.clubLogo;
  }

  String get _shareMessage =>
      languages.dugnadSupportShareCardMessage(_teamName);

  void _copyShareLink() => copyDugnadSupportShareLink(context);

  List<InlineSpan> _emphasizedSpans(
    String source,
    List<String> highlights,
    TextStyle emphasize,
  ) {
    if (source.isEmpty || highlights.isEmpty) {
      return [TextSpan(text: source)];
    }
    final pattern = highlights
        .where((h) => h.isNotEmpty)
        .map(RegExp.escape)
        .join('|');
    if (pattern.isEmpty) return [TextSpan(text: source)];
    final re = RegExp(pattern);
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in re.allMatches(source)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: source.substring(cursor, match.start)));
      }
      spans.add(TextSpan(text: match.group(0), style: emphasize));
      cursor = match.end;
    }
    if (cursor < source.length) {
      spans.add(TextSpan(text: source.substring(cursor)));
    }
    return spans.isEmpty ? [TextSpan(text: source)] : spans;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final fee = _feeBreakdown;
    final amountKr = widget.subscription.amountKr.round();
    final amountPerMonth = languages.dugnadDonationManageAmountPerMonth(amountKr);

    return Scaffold(
      backgroundColor: theme.background,
      body: Stack(
        children: [
          DugnadPointsPopTrigger(
            points: _points,
            reason: DugnadPointsPopReasons.monthlySupport(context),
            enabled: widget.activated && _points > 0,
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(context.dp(20), context.dp(16), context.dp(20), context.dp(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        DugnadRiseIn(
                          delay: const Duration(milliseconds: 100),
                          child: Container(
                            width: context.dp(80),
                            height: context.dp(80),
                            decoration: BoxDecoration(
                              color: theme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.primary.withValues(alpha: 0.32),
                                  blurRadius: context.dp(18),
                                  offset: Offset(0, context.dp(8)),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.favorite_rounded,
                              color: Colors.white,
                              size: context.dp(36),
                            ),
                          ),
                        ),
                        SizedBox(height: context.dp(18)),
                        DugnadRiseIn(
                          delay: const Duration(milliseconds: 160),
                          child: Text(
                            widget.activated
                                ? languages.dugnadDonationConfirmThanks
                                : languages.dugnadDonationPendingTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: theme.text,
                              letterSpacing: 28 * -0.02,
                            ),
                          ),
                        ),
                        SizedBox(height: context.dp(8)),
                        DugnadRiseIn(
                          delay: const Duration(milliseconds: 220),
                          child: Text.rich(
                            TextSpan(
                              style: TextStyle(
                                color: ScSaasThemeTokens.gray600,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                height: 1.4,
                              ),
                              children: _emphasizedSpans(
                                languages.dugnadDonationConfirmSupportLine(
                                  _teamName,
                                  amountPerMonth,
                                ),
                                [
                                  _teamName,
                                  amountPerMonth,
                                ],
                                TextStyle(
                                  color: theme.text,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (_points > 0) ...[
                          SizedBox(height: context.dp(22)),
                          DugnadRiseIn(
                            delay: const Duration(milliseconds: 280),
                            child: DugnadSuccessPointsBadge(
                              points: _points,
                              label: languages.dugnadDonationConfirmPointsLabel,
                              animate: widget.activated,
                            ),
                          ),
                        ],
                        SizedBox(height: context.dp(16)),
                        DugnadRiseIn(
                          delay: const Duration(milliseconds: 340),
                          child: DugnadSuccessCardWidth(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _splitCard(fee),
                                SizedBox(height: context.dp(8)),
                                Text.rich(
                                  TextSpan(
                                    style: TextStyle(
                                      color: ScSaasThemeTokens.gray500,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11.5,
                                      height: 1.5,
                                    ),
                                    children: _emphasizedSpans(
                                      languages.dugnadDonationHowPaidBody(
                                        _clubName,
                                        _clubShort,
                                        _teamName,
                                      ),
                                      const ['Reen Dugnad'],
                                      TextStyle(
                                        color: theme.text,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: context.dp(20)),
                        DugnadRiseIn(
                          delay: const Duration(milliseconds: 420),
                          child: Center(
                            child: DugnadSupportShareCard(
                              teamName: _teamName,
                              message: _shareMessage,
                              logoUrl: _teamLogo,
                            ),
                          ),
                        ),
                        SizedBox(height: context.dp(12)),
                        DugnadRiseIn(
                          delay: const Duration(milliseconds: 460),
                          child: DugnadSuccessCardWidth(
                            child: DugnadShareSupportButton(
                              onPressed: _copyShareLink,
                            ),
                          ),
                        ),
                        SizedBox(height: context.dp(12)),
                        DugnadRiseIn(
                          delay: const Duration(milliseconds: 500),
                          child: DugnadSuccessCardWidth(child: _giveMoreCard(theme)),
                        ),
                      ],
                    ),
                  ),
                ),
                DugnadRiseIn(
                  delay: const Duration(milliseconds: 540),
                  child: _confirmFooter(theme),
                ),
              ],
            ),
          ),
          if (widget.activated)
            Positioned.fill(
              child: IgnorePointer(
                child: DugnadConfetti(
                  progress: _confettiController,
                  fadeByHeight: true,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _splitCard(DonationFeeBreakdown fee) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: context.dp(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(16)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0D2D1B5B),
            blurRadius: context.dp(4),
            offset: Offset(0, context.dp(2)),
          ),
        ],
      ),
      child: Column(
        children: [
          _splitRow(
            icon: Icons.shield_outlined,
            label: languages.dugnadDonationConfirmEarmarked(_teamName),
            value: '${_formatKr(fee.netKr)} kr',
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: ScSaasThemeTokens.gray100,
          ),
          _splitRow(
            icon: Icons.credit_card_outlined,
            label: languages.dugnadDonationConfirmOperations,
            value: '${_formatKr(fee.feeKr)} kr',
            subdued: true,
          ),
        ],
      ),
    );
  }

  Widget _splitRow({
    required IconData icon,
    required String label,
    required String value,
    bool subdued = false,
  }) {
    final theme = context.dugnadTheme;
    final labelColor =
        subdued ? ScSaasThemeTokens.gray500 : theme.text;
    final iconColor =
        subdued ? ScSaasThemeTokens.gray400 : theme.primary;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.dp(13)),
      child: Row(
        children: [
          Icon(icon, size: context.dp(16), color: iconColor),
          SizedBox(width: context.dp(8)),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontWeight: subdued ? FontWeight.w700 : FontWeight.w800,
                fontSize: 13.5,
                letterSpacing: 13.5 * -0.01,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: labelColor,
              fontWeight: subdued ? FontWeight.w800 : FontWeight.w900,
              fontSize: 15,
              letterSpacing: 15 * -0.02,
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmFooter(DugnadClubThemePalette theme) {
    final radius = BorderRadius.circular(context.dp(14));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.dp(22)),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x2E2D1B5B),
            blurRadius: context.dp(20),
            offset: Offset(0, context.dp(-6)),
            spreadRadius: context.dp(-10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.dp(18),
          context.dp(14),
          context.dp(18),
          MediaQuery.paddingOf(context).bottom + context.dp(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: context.dp(48),
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    openScreenWithClearPrevious(
                      context,
                      const DonationManageScreen(),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: theme.primary,
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 16 * -0.01,
                    ),
                  ),
                  child: Text(
                    languages.dugnadDonationConfirmManage,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 16 * -0.01,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: context.dp(10)),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.primary,
                  borderRadius: radius,
                  boxShadow: theme.shadowButton,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                    borderRadius: radius,
                    child: SizedBox(
                      height: context.dp(48),
                      child: Center(
                        child: Text(
                          languages.dugnadDonationConfirmReady,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 16 * -0.01,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _giveMoreCard(DugnadClubThemePalette theme) {
    final radius = BorderRadius.circular(context.dp(16));
    final wellColor = Color.alphaBlend(
      theme.primary.withValues(alpha: 0.12),
      Colors.white,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: const Color(0x0D2D1B5B),
            blurRadius: context.dp(4),
            offset: Offset(0, context.dp(2)),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: radius,
        child: InkWell(
          onTap: () => openScreen(context, const KampanjeScreen()),
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.all(context.dp(14)),
            child: Row(
              children: [
                Container(
                  width: context.dp(42),
                  height: context.dp(42),
                  decoration: BoxDecoration(
                    color: wellColor,
                    borderRadius: BorderRadius.circular(context.dp(12)),
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/svgs/menu/box.svg',
                    width: context.dp(18),
                    height: context.dp(18),
                    colorFilter: ColorFilter.mode(
                      theme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                SizedBox(width: context.dp(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languages.dugnadDonationConfirmGiveMoreTitle,
                        style: TextStyle(
                          color: theme.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                      SizedBox(height: context.dp(2)),
                      Text(
                        languages.dugnadDonationConfirmGiveMoreBody,
                        style: TextStyle(
                          color: theme.primaryHover,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: context.dp(34),
                  height: context.dp(34),
                  decoration: BoxDecoration(
                    color: wellColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chevron_right_rounded, color: theme.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
