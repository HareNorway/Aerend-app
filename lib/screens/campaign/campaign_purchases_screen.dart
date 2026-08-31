import 'package:flutter/material.dart';

import '../../commonView/guest_empty_state.dart';
import '../../theme/ae_typography.dart';
import '../../theme/design_scale.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/guest_auth_helper.dart';
import '../../utils/utils.dart';
import '../common/address_order_chrome.dart';
import '../dugnad/dugnad_club_theme.dart';
import '../dugnad/widgets/dugnad_rise_in.dart';
import 'campaign_delivery_utils.dart';
import 'campaign_my_orders_screen.dart';
import 'campaign_repo.dart';
import 'campaign_strings.dart';
import 'campaign_tracker_controller.dart';
import 'models/campaign_order_pojo.dart';
import 'widgets/cp_active_card.dart';
import 'widgets/cp_archive_sheet.dart';
import 'widgets/cp_receipt_paper.dart';

/// Kampanjekjøp overview — active receipts + archive (Chunks 6–7).
class CampaignPurchasesScreen extends StatefulWidget {
  const CampaignPurchasesScreen({super.key, this.debugOrders});

  /// Skip the network fetch (widget tests).
  @visibleForTesting
  final List<CampaignMyOrder>? debugOrders;

  @override
  State<CampaignPurchasesScreen> createState() =>
      _CampaignPurchasesScreenState();
}

class _CampaignPurchasesScreenState extends State<CampaignPurchasesScreen> {
  final CampaignRepo _repo = CampaignRepo();
  List<CampaignMyOrder> _orders = const [];
  bool _loading = true;
  String? _error;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    if (widget.debugOrders != null) {
      _orders = widget.debugOrders!;
      _loading = false;
    } else if (!isGuestUser()) {
      _load();
    } else {
      _loading = false;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _repo.getMyOrders();
      if (!mounted) return;
      final pojo = CampaignMyOrdersListPojo.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
      setState(() {
        _orders = pojo.orders;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _onChanged() async {
    await _load();
    await CampaignTrackerController.instance.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    if (isGuestUser() && widget.debugOrders == null) {
      return Scaffold(
        backgroundColor: theme.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AoTkHead(title: CampaignStrings.purchasesTitle),
              Expanded(
                child: GuestEmptyState(
                  title: languages.signInToViewOrders,
                  message: languages.guestAccountPromptMessage,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final active = campaignActiveOrders(_orders);
    final archived = campaignArchivedOrders(_orders);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AoTkHead(title: CampaignStrings.purchasesTitle),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: theme.primary),
                    )
                  : _error != null
                      ? _errorView()
                      : RefreshIndicator(
                          color: theme.primary,
                          onRefresh: _load,
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                              context.dp(18),
                              context.dp(10),
                              context.dp(18),
                              context.dp(32),
                            ),
                            children: [
                              _CpSeg(
                                index: _tab,
                                activeCount: active.length,
                                onChanged: (i) => setState(() => _tab = i),
                              ),
                              SizedBox(height: context.dp(14)),
                              if (_tab == 0)
                                ..._activePane(active)
                              else
                                ..._archivePane(archived),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _activePane(List<CampaignMyOrder> active) {
    if (active.isEmpty) {
      return [
        _CpEmpty(
          icon: Icons.inventory_2_outlined,
          title: CampaignStrings.activeEmptyTitle,
          body: CampaignStrings.activeEmptyBody,
        ),
      ];
    }
    return [
      for (var i = 0; i < active.length; i++) ...[
        DugnadRiseIn(
          delay: Duration(milliseconds: 80 * i),
          child: CpActiveCard(order: active[i], onChanged: (_) => _onChanged()),
        ),
        if (i != active.length - 1) SizedBox(height: context.dp(14)),
      ],
    ];
  }

  List<Widget> _archivePane(List<CampaignMyOrder> archived) {
    if (archived.isEmpty) {
      return [
        _CpEmpty(
          icon: Icons.receipt_long_outlined,
          title: CampaignStrings.archiveEmptyTitle,
          body: CampaignStrings.archiveEmptyBody,
        ),
      ];
    }
    final points = campaignArchivePointsSum(archived);
    return [
      _ArchiveSummary(points: points, count: archived.length),
      SizedBox(height: context.dp(14)),
      for (var i = 0; i < archived.length; i++) ...[
        _ArchiveRow(
          order: archived[i],
          onTap: () => showCpArchiveSheet(context, archived[i]),
        ),
        if (i != archived.length - 1) SizedBox(height: context.dp(10)),
      ],
      SizedBox(height: context.dp(16)),
      TextButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CampaignMyOrdersScreen(),
            ),
          );
        },
        child: Text(
          CampaignStrings.viewFullHistory,
          style: aeLabel(color: context.dugnadTheme.primary),
        ),
      ),
    ];
  }

  Widget _errorView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 120),
      children: [
        Text(
          _error ?? CampaignStrings.somethingWentWrong,
          textAlign: TextAlign.center,
          style: aeCaption(),
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton(
            onPressed: _load,
            child: Text(
              CampaignStrings.tryAgain,
              style: aeLabel(color: context.dugnadTheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _CpSeg extends StatelessWidget {
  const _CpSeg({
    required this.index,
    required this.activeCount,
    required this.onChanged,
  });

  final int index;
  final int activeCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pillW = (constraints.maxWidth - 0) / 2;
          return SizedBox(
            height: context.dp(38),
            child: Stack(
              children: [
                AnimatedAlign(
                  duration: reduce
                      ? Duration.zero
                      : const Duration(milliseconds: 360),
                  curve: Curves.easeInOut,
                  alignment:
                      index == 0 ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    width: pillW,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: ScSaasThemeTokens.text.withValues(alpha: 0.14),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    _segBtn(
                      context,
                      selected: index == 0,
                      label: CampaignStrings.tabActive(activeCount),
                      onTap: () => onChanged(0),
                    ),
                    _segBtn(
                      context,
                      selected: index == 1,
                      label: CampaignStrings.tabArchive,
                      onTap: () => onChanged(1),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _segBtn(
    BuildContext context, {
    required bool selected,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: aeCaption(
              color: selected
                  ? context.dugnadTheme.ink
                  : ScSaasThemeTokens.gray500,
            ).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class _CpEmpty extends StatelessWidget {
  const _CpEmpty({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.dp(36)),
      child: Column(
        children: [
          Container(
            width: context.dp(56),
            height: context.dp(56),
            decoration: BoxDecoration(
              color: theme.primaryTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: theme.primary),
          ),
          SizedBox(height: context.dp(14)),
          Text(
            title,
            style: aeTitle(color: theme.ink).copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: context.dp(6)),
          Text(
            body,
            textAlign: TextAlign.center,
            style: aeCaption(),
          ),
        ],
      ),
    );
  }
}

class _ArchiveSummary extends StatelessWidget {
  const _ArchiveSummary({required this.points, required this.count});

  final int points;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return Container(
      padding: EdgeInsets.all(context.dp(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(18)),
        boxShadow: [
          BoxShadow(
            color: ScSaasThemeTokens.text.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: context.dp(42),
            decoration: BoxDecoration(
              color: ScSaasThemeTokens.success,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          SizedBox(width: context.dp(12)),
          Container(
            width: context.dp(42),
            height: context.dp(42),
            decoration: BoxDecoration(
              color: ScSaasThemeTokens.success.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(context.dp(14)),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: ScSaasThemeTokens.success,
              size: 17,
            ),
          ),
          SizedBox(width: context.dp(13)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CampaignStrings.archivePointsEarnedLabel.toUpperCase(),
                  style: aeOverline().copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: context.dp(3)),
                Text(
                  CampaignStrings.archivePointsTotal(points),
                  style: aeH3(color: theme.ink).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CampaignStrings.archiveCount(count),
            style: aeCaption().copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ArchiveRow extends StatelessWidget {
  const _ArchiveRow({required this.order, required this.onTap});

  final CampaignMyOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final pickup = order.isPickup;
    final day = campaignDayLabel(order.windowInstant);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(context.dp(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.dp(16)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.dp(12),
            context.dp(12),
            context.dp(10),
            context.dp(12),
          ),
          child: Row(
            children: [
              CpCrest(
                name: order.clubName ?? order.campaignName ?? '',
                logoUrl: campaignClubCrestUrl(order),
              ),
              SizedBox(width: context.dp(11)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.campaignName ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: aeTitle(color: theme.ink).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    SizedBox(height: context.dp(5)),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            day,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: aeCaption().copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                        SizedBox(width: context.dp(7)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.dp(7),
                            vertical: context.dp(3),
                          ),
                          decoration: BoxDecoration(
                            color: theme.primaryTint,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                pickup
                                    ? Icons.storefront_outlined
                                    : Icons.local_shipping_outlined,
                                size: 10,
                                color: theme.primary,
                              ),
                              SizedBox(width: context.dp(4)),
                              Text(
                                pickup
                                    ? CampaignStrings.pickedUpShort
                                    : CampaignStrings.deliveredShort,
                                style: aeCaption(color: theme.primary).copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.dp(8)),
              Text(
                '+${order.earnedPoints ?? 0}',
                style: aeCaption(color: theme.ink).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: ScSaasThemeTokens.gray500,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
