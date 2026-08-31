import 'package:flutter/material.dart';

import '../../blocs/bloc.dart';
import '../../commonView/guest_empty_state.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/guest_auth_helper.dart';
import '../../utils/utils.dart';
import '../common/homeMainV1/home_main_v1.dart';
import '../dugnad/dugnad_club_theme.dart';
import '../dugnad/widgets/dugnad_rise_in.dart';
import 'bloc/campaign_my_orders_bloc.dart';
import 'campaign_order_detail_screen.dart';
import 'campaign_strings.dart';
import 'models/campaign_order_pojo.dart';
import '../common/address_order_chrome.dart';
import '../common/auth/auth_style.dart';

/// Order history (campaign matkasse purchases) — same `.tk-head` / `.dg-label` / `.oh-list`/`.oh-order`
/// card language as `OrderHistory` (`dugnad/offers.jsx`), scoped to campaign
/// (Dugnad food-box) purchases. Bloc wiring and navigation are unchanged.
class CampaignMyOrdersScreen extends StatefulWidget {
  const CampaignMyOrdersScreen({super.key});

  @override
  State<CampaignMyOrdersScreen> createState() =>
      _CampaignMyOrdersScreenState();
}

class _CampaignMyOrdersScreenState extends State<CampaignMyOrdersScreen> {
  CampaignMyOrdersBloc? _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = CampaignMyOrdersBloc(context, this);
  }

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso);
      const months = [
        'jan',
        'feb',
        'mar',
        'apr',
        'mai',
        'jun',
        'jul',
        'aug',
        'sep',
        'okt',
        'nov',
        'des',
      ];
      return '${d.day}. ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isGuestUser()) {
      return Scaffold(
        backgroundColor: context.dugnadTheme.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AoTkHead(title: CampaignStrings.myMatkasser),
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

    return Scaffold(
      backgroundColor: context.dugnadTheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AoTkHead(title: CampaignStrings.myMatkasser),
            Expanded(
              child: StreamBuilder<ApiResponse<CampaignMyOrdersListPojo>>(
                stream: _bloc?.ordersStream,
                builder: (context, snapshot) {
                  final theme = context.dugnadTheme;
                  final isLoading = !snapshot.hasData ||
                      snapshot.data?.status == Status.loading;
                  if (isLoading) {
                    return Center(
                      child: CircularProgressIndicator(color: theme.primary),
                    );
                  }
                  if (snapshot.hasData && snapshot.data?.status == Status.error) {
                    return _buildError(snapshot.data?.message ?? '');
                  }
                  final orders = snapshot.data?.data?.orders ?? [];
                  if (orders.isEmpty) {
                    return _buildEmpty();
                  }
                    return RefreshIndicator(
                    color: context.dugnadTheme.primary,
                    onRefresh: () => _bloc!.refresh(),
                    child: _buildOrderList(orders),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `.ae-body { padding: 0 18px 120px; gap: 14px }`.
  Widget _buildOrderList(List<CampaignMyOrder> orders) {
    var step = 0;
    Widget rise(Widget child) {
      final delay = Duration(milliseconds: 120 + 70 * step++);
      return DugnadRiseIn(delay: delay, child: child);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 120),
      children: [
        rise(
          AoGreenBanner(
            title: CampaignStrings.ordersBoughtBanner(orders.length),
            subtitle: CampaignStrings.ordersBoughtBannerSub,
          ),
        ),
        const SizedBox(height: 14),
        rise(const AoSectionLabel(kMkYourOrdersLabel, bottom: 0)),
        const SizedBox(height: 14),
        ...orders.map(
          (o) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: rise(_buildOrderCard(o)),
          ),
        ),
        const SizedBox(height: 8),
        rise(
          const AoInfoBox(
            icon: Icons.receipt_long_outlined,
            text: kMkReceiptsInfoNote,
          ),
        ),
      ],
    );
  }

  /// `.oh-mk` — 46px icon tile, campaign name, date · order no, earned
  /// points and a right-aligned amount + payment-status pill.
  Widget _buildOrderCard(CampaignMyOrder order) {
    final status = _statusUi(order.paymentStatus);
    final theme = context.dugnadTheme;
    final points = order.earnedPoints ?? 0;

    return AoPressable(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CampaignOrderDetailScreen(order: order),
        ),
      ),
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: ScSaasThemeTokens.shadowCard,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.primaryTint,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                size: 20,
                color: theme.primaryHover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.campaignName ?? languages.campaignMatkasseFallback,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: aoText(
                      14,
                      FontWeight.w800,
                      letterSpacingEm: -0.01,
                      color: theme.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatDate(order.createdAt)} · #${order.orderNo}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: aoText(
                      11.5,
                      FontWeight.w700,
                      color: ScSaasThemeTokens.gray500,
                    ),
                  ),
                  if (points > 0) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 10,
                          color: ScSaasThemeTokens.success,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            CampaignStrings.pointsChip(points),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: aoText(
                              11,
                              FontWeight.w800,
                              color: ScSaasThemeTokens.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${order.totalPay.round()} kr',
                  style: aoText(
                    15,
                    FontWeight.w900,
                    letterSpacingEm: -0.02,
                    color: theme.text,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status.icon != null) ...[
                      Icon(status.icon, size: 11, color: status.foreground),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      status.label.toUpperCase(),
                      style: aoText(
                        10,
                        FontWeight.w800,
                        letterSpacingEm: 0.03,
                        color: status.foreground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 120),
      children: [
        Icon(
          Icons.inventory_2_outlined,
          size: 64,
          color: ScSaasThemeTokens.gray500.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 20),
        Text(
          kMkEmptyTitle,
          textAlign: TextAlign.center,
          style: aoText(20, FontWeight.w800, letterSpacingEm: -0.02),
        ),
        const SizedBox(height: 10),
        Text(
          kMkEmptySub,
          textAlign: TextAlign.center,
          style: aoText(
            13.5,
            FontWeight.w600,
            height: 1.45,
            color: ScSaasThemeTokens.gray500,
          ),
        ),
        const SizedBox(height: 24),
        AuthPrimaryButton(
          label: kMkEmptyCta,
          onPressed: () => openScreenWithResult(context, const HomeMainV1()),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 120),
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: aoText(14, FontWeight.w600, color: ScSaasThemeTokens.gray500),
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton(
            onPressed: () => _bloc?.refresh(),
            child: Text(
              CampaignStrings.tryAgain,
              style: aoText(
                14,
                FontWeight.w700,
                color: ScSaasThemeTokens.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  _MkStatusUi _statusUi(int paymentStatus) {
    switch (paymentStatus) {
      case 1:
        return _MkStatusUi(
          label: CampaignStrings.paid,
          foreground: ScSaasThemeTokens.success,
          icon: Icons.check_rounded,
        );
      case 2:
        return _MkStatusUi(
          label: CampaignStrings.failed,
          foreground: ScSaasThemeTokens.danger,
          icon: Icons.close_rounded,
        );
      default:
        return _MkStatusUi(
          label: CampaignStrings.pending,
          foreground: ScSaasThemeTokens.warning,
        );
    }
  }
}

class _MkStatusUi {
  final String label;
  final Color foreground;
  final IconData? icon;

  const _MkStatusUi({required this.label, required this.foreground, this.icon});
}

// ── Prototype copy with no matching l10n key ─────────────────────────────
const String kMkYourOrdersLabel = 'Dine matkasser'; // TODO(l10n)
const String kMkReceiptsInfoNote =
    'Kvitteringer og ordrebekreftelser sendes til e-posten din.'; // TODO(l10n)
const String kMkEmptyTitle = 'Du har ingen matkasser ennå.'; // TODO(l10n)
const String kMkEmptySub =
    'Bli med på en kampanje og støtt klubben — kjøp din første matkasse.'; // TODO(l10n)
const String kMkEmptyCta = 'Utforsk kampanjer'; // TODO(l10n)
