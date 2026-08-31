import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../commonView/surface_decorations.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import '../common/homeMainV1/home_main_v1.dart';
import '../dugnad/club_crest.dart';
import '../dugnad/dugnad_club_branding.dart';
import '../dugnad/dugnad_club_theme.dart';
import '../dugnad/dugnad_state.dart';
import '../dugnad/widgets/dugnad_confetti.dart';
import '../dugnad/widgets/dugnad_points_pop.dart';
import '../dugnad/widgets/dugnad_rise_in.dart';
import '../dugnad/widgets/dugnad_support_share.dart';
import 'campaign_my_orders_screen.dart';
import 'campaign_strings.dart';

class CampaignOrderSuccessLineItem {
  final String name;
  final int quantity;
  final double lineTotalNok;

  const CampaignOrderSuccessLineItem({
    required this.name,
    required this.quantity,
    required this.lineTotalNok,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'line_total_nok': lineTotalNok,
      };

  factory CampaignOrderSuccessLineItem.fromJson(Map<String, dynamic> json) {
    return CampaignOrderSuccessLineItem(
      name: json['name']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      lineTotalNok: (json['line_total_nok'] as num?)?.toDouble() ?? 0,
    );
  }
}

List<CampaignOrderSuccessLineItem> campaignOrderLineItemsFromMeta(
  Map<String, dynamic> meta,
) {
  final raw = meta['line_items'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map(
        (e) => CampaignOrderSuccessLineItem.fromJson(
          Map<String, dynamic>.from(e),
        ),
      )
      .toList();
}

class CampaignOrderSuccessScreen extends StatefulWidget {
  final String orderNo;
  final String? distributionDate;
  final int? clubShareAmount;
  final String? clubName;
  final String? clubLogo;
  final String? teamName;
  final String? teamLogo;
  final int? pointsEarned;
  final String? pointsTeamName;
  final String? email;
  final double? totalPayNok;
  final List<CampaignOrderSuccessLineItem> lineItems;
  final int? boxCount;

  const CampaignOrderSuccessScreen({
    super.key,
    required this.orderNo,
    this.distributionDate,
    this.clubShareAmount,
    this.clubName,
    this.clubLogo,
    this.teamName,
    this.teamLogo,
    this.pointsEarned,
    this.pointsTeamName,
    this.email,
    this.totalPayNok,
    this.lineItems = const [],
    this.boxCount,
  });

  @override
  State<CampaignOrderSuccessScreen> createState() =>
      _CampaignOrderSuccessScreenState();
}

class _CampaignOrderSuccessScreenState extends State<CampaignOrderSuccessScreen>
    with SingleTickerProviderStateMixin {
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
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      return DateFormat('d. MMMM yyyy', languages.localeName)
          .format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  String get _supportName {
    final team = widget.teamName?.trim() ?? '';
    if (team.isNotEmpty) return team;
    return widget.clubName?.trim() ?? DugnadClubBranding.fullName();
  }

  String get _clubDisplayName {
    final club = widget.clubName?.trim() ?? '';
    final team = widget.teamName?.trim() ?? '';
    if (club.isNotEmpty && team.isNotEmpty) return '$club · $team';
    return team.isNotEmpty ? team : club;
  }

  String? get _supportLogo {
    if ((widget.teamLogo ?? '').trim().isNotEmpty) return widget.teamLogo;
    if ((widget.clubLogo ?? '').trim().isNotEmpty) return widget.clubLogo;
    final ds = DugnadState.instance;
    if (ds.pointsTeamLogo.isNotEmpty) return ds.pointsTeamLogo;
    return ds.clubLogo.isEmpty ? null : ds.clubLogo;
  }

  int get _boxCount {
    if (widget.boxCount != null && widget.boxCount! > 0) return widget.boxCount!;
    return widget.lineItems.fold(0, (sum, item) => sum + item.quantity);
  }

  double get _totalNok {
    if (widget.totalPayNok != null && widget.totalPayNok! > 0) {
      return widget.totalPayNok!;
    }
    return widget.lineItems.fold(0.0, (sum, item) => sum + item.lineTotalNok);
  }

  String get _email {
    final passed = widget.email?.trim() ?? '';
    if (passed.isNotEmpty) return passed;
    return prefGetString(prefEmail).trim();
  }

  String get _shareMessage => languages.dugnadSupportShareMessage(_supportName);

  void _copyShareLink() => copyDugnadSupportShareLink(context);

  void _goHome() {
    if (!mounted) return;
    _confettiController.stop();
    DugnadPointsPop.dismissNow();
    final nav = Navigator.of(context);
    // Pop back to the existing home shell. Replacing the whole stack with a
    // new [HomeMainV1] rebuilds the semantics tree mid-frame and can freeze
    // on `!semantics.parentDataDirty` (white screen).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (nav.canPop()) {
        nav.popUntil((route) => route.isFirst);
        return;
      }
      openScreenWithClearPrevious(context, const HomeMainV1());
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDugnad = DugnadState.instance.isDugnadMode;
    final theme = isDugnad ? context.dugnadTheme : null;
    final accent = isDugnad ? theme!.primary : ScSaasThemeTokens.primary;
    final pageBg =
        isDugnad ? theme!.background : ScSaasThemeTokens.background;
    final textColor = isDugnad ? theme!.text : ScSaasThemeTokens.text;

    return Scaffold(
      backgroundColor: pageBg,
      body: Stack(
        children: [
          if (isDugnad)
            DugnadPointsPopTrigger(
              points: widget.pointsEarned ?? 0,
              reason: DugnadPointsPopReasons.campaign(context),
              enabled: (widget.pointsEarned ?? 0) > 0,
            ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        DugnadRiseIn(
                          delay: const Duration(milliseconds: 100),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.4, end: 1),
                            duration: const Duration(milliseconds: 420),
                            curve: Curves.easeOutBack,
                            builder: (_, scale, child) => Transform.scale(
                              scale: scale,
                              child: Opacity(
                                opacity: ((scale - 0.4) / 0.6).clamp(0.0, 1.0),
                                child: child,
                              ),
                            ),
                            child: isDugnad
                                ? const DugnadSuccessBurstCheck()
                                : Container(
                                    width: 80,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: ScSaasThemeTokens.border,
                                      ),
                                      boxShadow: ScSaasThemeTokens.shadowCard,
                                    ),
                                    child: Icon(
                                      Icons.check_rounded,
                                      color: accent,
                                      size: 34,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        DugnadRiseIn(
                          delay: const Duration(milliseconds: 160),
                          child: Text(
                            isDugnad
                                ? languages.campaignSupportThankYou
                                : CampaignStrings.thankYou,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        if (isDugnad && _boxCount > 0) ...[
                          const SizedBox(height: 8),
                          DugnadRiseIn(
                            delay: const Duration(milliseconds: 220),
                            child: Text(
                              languages.campaignBoxesOrdered(_boxCount),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDugnad
                                    ? theme!.primaryHover
                                    : ScSaasThemeTokens.gray500,
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                        ] else if (!isDugnad) ...[
                          const SizedBox(height: 8),
                          Text(
                            CampaignStrings.confirmationSent,
                            textAlign: TextAlign.center,
                            style: aeBody(color: ScSaasThemeTokens.gray500),
                          ),
                        ],
                        if (isDugnad &&
                            widget.pointsEarned != null &&
                            widget.pointsEarned! > 0) ...[
                          const SizedBox(height: 22),
                          DugnadRiseIn(
                            delay: const Duration(milliseconds: 280),
                            child: DugnadSuccessPointsBadge(
                              points: widget.pointsEarned!,
                              label: languages.campaignPointsAddedLabel,
                            ),
                          ),
                        ],
                        if (isDugnad) ...[
                          const SizedBox(height: 18),
                          DugnadRiseIn(
                            delay: const Duration(milliseconds: 330),
                            child: DugnadSuccessCardWidth(
                              child: _clubCard(accent, textColor),
                            ),
                          ),
                          if (widget.distributionDate != null) ...[
                            const SizedBox(height: 12),
                            DugnadRiseIn(
                              delay: const Duration(milliseconds: 370),
                              child: _deliveryPill(accent, theme!),
                            ),
                          ],
                        ],
                        if (widget.lineItems.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          DugnadRiseIn(
                            delay: const Duration(milliseconds: 410),
                            child: DugnadSuccessCardWidth(
                              child: _orderSummaryCard(textColor),
                            ),
                          ),
                        ] else if (!isDugnad) ...[
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: AeSurface.card(),
                            child: Column(
                              children: [
                                _infoRow(
                                  CampaignStrings.orderNumber,
                                  widget.orderNo,
                                ),
                                if (widget.distributionDate != null) ...[
                                  const SizedBox(height: 10),
                                  _infoRow(
                                    CampaignStrings.distributionDate,
                                    _formatDate(widget.distributionDate),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        if (isDugnad && _email.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          DugnadRiseIn(
                            delay: const Duration(milliseconds: 450),
                            child: Text(
                              languages.campaignConfirmationEmailSent(_email),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme!.primaryHover,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                        if (isDugnad) ...[
                          const SizedBox(height: 20),
                          DugnadRiseIn(
                            delay: const Duration(milliseconds: 490),
                            child: Center(
                              child: DugnadSupportShareCard(
                                teamName: _supportName,
                                message: _shareMessage,
                                logoUrl: _supportLogo,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DugnadRiseIn(
                            delay: const Duration(milliseconds: 530),
                            child: DugnadSuccessCardWidth(
                              child: DugnadShareSupportButton(
                                onPressed: _copyShareLink,
                                compact: true,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    children: [
                      if (isDugnad) ...[
                        DugnadSuccessCardWidth(
                          child: DugnadSuccessPrimaryButton(
                            label: CampaignStrings.backToHome,
                            onPressed: _goHome,
                          ),
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const CampaignMyOrdersScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(CampaignStrings.viewMyOrders),
                          ),
                        ),
                        TextButton(
                          onPressed: _goHome,
                          child: Text(
                            CampaignStrings.backToHome,
                            style: aeLabel(color: accent),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isDugnad)
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

  Widget _clubCard(Color accent, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: Row(
        children: [
          ClubCrest(
            name: _clubDisplayName,
            logoUrl: _supportLogo,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _clubDisplayName,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  languages.campaignPurchaseClubShare,
                  style: const TextStyle(
                    color: ScSaasThemeTokens.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deliveryPill(Color accent, DugnadClubThemePalette theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: theme.primaryTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_shipping_outlined, size: 13, color: theme.primaryHover),
          const SizedBox(width: 6),
          Text(
            '${CampaignStrings.deliveryDay} ${_formatDate(widget.distributionDate)}',
            style: TextStyle(
              color: theme.primaryHover,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderSummaryCard(Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 14, color: ScSaasThemeTokens.gray500),
              const SizedBox(width: 6),
              Text(
                languages.campaignOrderSummaryTitle,
                style: TextStyle(
                  color: ScSaasThemeTokens.gray500,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.lineItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    '${item.quantity}× ',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    formatNok(item.lineTotalNok),
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(color: ScSaasThemeTokens.border),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                CampaignStrings.total,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                formatNok(_totalNok),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: aeCaption(color: ScSaasThemeTokens.gray500)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: aeTitle(),
          ),
        ),
      ],
    );
  }
}
