import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:aerend_customer/blocs/bloc.dart';
import 'package:aerend_customer/screens/common/homeMainV1/home_main_v1.dart';
import 'package:aerend_customer/screens/common/orderHistory/order_history_bloc.dart';
import 'package:aerend_customer/screens/common/orderHistory/order_history_dl.dart';
import 'package:aerend_customer/theme/sc_saas_theme.dart';

import '../../../commonView/guest_empty_state.dart';
import '../../../utils/guest_auth_helper.dart';
import '../../../utils/utils.dart';
import '../../dugnad/dugnad_club_theme.dart';
import '../../dugnad/widgets/dugnad_rise_in.dart';
import '../address_order_chrome.dart';
import '../auth/auth_style.dart';
import 'order_detail/order_detail.dart';

/// Ordrehistorikk — prototype `OrderHistoryScreen` in `dugnad/offers.jsx`:
/// `.tk-head` + `.dg-green-banner` + `.dg-label` + `.oh-list`/`.oh-order`
/// cards + `.dg-info`. Bloc wiring and navigation are unchanged.
class OrderHistory extends StatefulWidget {
  const OrderHistory({super.key});

  @override
  State<OrderHistory> createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory> {
  bool isEmpty = true;
  OrderHistoryBloc? bloc;

  @override
  initState() {
    super.initState();
    bloc = OrderHistoryBloc(context, this);
  }

  @override
  void didChangeDependencies() {
    bloc ??= OrderHistoryBloc(context, this);
    super.didChangeDependencies();
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
              AoTkHead(title: languages.orderHistory),
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
            AoTkHead(title: languages.orderHistory),
            Expanded(
              child: StreamBuilder<ApiResponse<OrderHistoryListPojo>>(
                stream: bloc?.subject,
                builder: (context, snapshot) {
                  if (snapshot.hasData &&
                      snapshot.data?.status != Status.loading) {
                    var orderHistoryList =
                        snapshot.data?.data?.orderHistoryList;
                    if (orderHistoryList?.isNotEmpty ?? false) {
                      return _buildOrderList(orderHistoryList!);
                    } else {
                      return _buildEmptyHistory();
                    }
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `.ae-body { padding: 0 18px 120px; gap: 14px }`.
  Widget _buildOrderList(List<OrderHistoryListItem> orders) {
    var step = 0;
    Widget rise(Widget child) {
      final delay = Duration(milliseconds: 120 + 70 * step++);
      return DugnadRiseIn(delay: delay, child: child);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 120),
      children: [
        rise(_buildDonationBanner(orders)),
        const SizedBox(height: 14),
        // .dg-label { margin: 2px 2px 0 }
        rise(const AoSectionLabel(kAoYourOrdersLabel, bottom: 0)),
        const SizedBox(height: 14),
        // .oh-list { gap: 10px }
        ...orders.map(
          (o) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: rise(_buildOrderCard(o)),
          ),
        ),
        // .dg-info { margin-top: 4 } on top of the 14px column gap.
        const SizedBox(height: 8),
        rise(
          const AoInfoBox(
            icon: Icons.receipt_long_outlined,
            text: kAoReceiptsInfoNote,
          ),
        ),
      ],
    );
  }

  /// `.dg-green-banner` — total club share for the year.
  Widget _buildDonationBanner(List<OrderHistoryListItem> orders) {
    final totalDonation = orders.fold<double>(
      0,
      (sum, o) => sum + (o.totalPay * 0.08).roundToDouble(),
    );
    final donationText = totalDonation.toStringAsFixed(0);

    return AoGreenBanner(
      title: 'Du har gitt $donationText kr til klubben i år', // TODO(l10n)
      subtitle: kAoDonationBannerSub,
    );
  }

  /// `.oh-order` — grid 46px / 1fr / auto, radius 16, padding 13×14, white,
  /// `--ae-shadow-card`; crest tile, title, date · order no, club share and a
  /// right-aligned amount + status pill.
  Widget _buildOrderCard(OrderHistoryListItem order) {
    final status = _statusUi(order.orderStatus);
    final hasImage = order.storeImage.isNotEmpty;

    return AoPressable(
      onTap: () =>
          openScreenWithResult(context, OrderDetail(orderDetail: order)),
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: ScSaasThemeTokens.shadowCard,
        ),
        child: Row(
          children: [
            // .oh-order .lg
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ScSaasThemeTokens.primaryTint,
                borderRadius: BorderRadius.circular(13),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? CachedNetworkImage(
                      imageUrl: order.storeImage,
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.storefront_rounded,
                        size: 20,
                        color: ScSaasThemeTokens.primaryHover,
                      ),
                    )
                  : const Icon(
                      Icons.storefront_rounded,
                      size: 20,
                      color: ScSaasThemeTokens.primaryHover,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // .oh-order .nm
                  Text(
                    order.storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: aoText(
                      14,
                      FontWeight.w800,
                      letterSpacingEm: -0.01,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // .oh-order .who
                  Text(
                    '${_formatDate(order.orderDateTime)} · #${order.orderNo}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: aoText(
                      11.5,
                      FontWeight.w700,
                      color: ScSaasThemeTokens.gray500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // .oh-order .share
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        size: 10,
                        color: ScSaasThemeTokens.success,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${(order.totalPay * 0.08).round()} $kAoToTheClub',
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
              ),
            ),
            const SizedBox(width: 8),
            // .oh-order .amt
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${order.totalPay.round()} kr',
                  style: aoText(
                    15,
                    FontWeight.w900,
                    letterSpacingEm: -0.02,
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

  Widget _buildEmptyHistory() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 120),
      children: [
        const LoadImageSimple(
          image: 'assets/images/empty_history.png',
          width: 220,
          imageFit: BoxFit.fitHeight,
        ),
        const SizedBox(height: 20),
        Text(
          kAoEmptyHistoryTitle,
          textAlign: TextAlign.center,
          style: aoText(22, FontWeight.w800, letterSpacingEm: -0.02),
        ),
        const SizedBox(height: 10),
        Text(
          kAoEmptyHistorySub,
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
          label: kAoEmptyHistoryCta,
          onPressed: () => openScreenWithResult(context, const HomeMainV1()),
        ),
      ],
    );
  }

  String _formatDate(String rawDateTime) {
    if (rawDateTime.trim().isEmpty) return '';
    try {
      final parts = rawDateTime.split(',');
      return parts.first.trim();
    } catch (_) {
      return rawDateTime;
    }
  }

  _OrderStatusUi _statusUi(int status) {
    switch (status) {
      case 1:
        return const _OrderStatusUi(
          label: 'Bestilt', // TODO(l10n)
          foreground: ScSaasThemeTokens.warning,
        );
      case 2:
      case 3:
      case 4:
      case 5:
        return const _OrderStatusUi(
          label: 'På vei', // TODO(l10n)
          foreground: ScSaasThemeTokens.warning,
          icon: Icons.local_shipping_outlined,
        );
      case 6:
      case 7:
      case 8:
        return const _OrderStatusUi(
          label: 'Levert', // TODO(l10n)
          foreground: ScSaasThemeTokens.success,
          icon: Icons.check_rounded,
        );
      case 9:
        return const _OrderStatusUi(
          label: 'Fullført', // TODO(l10n)
          foreground: ScSaasThemeTokens.success,
          icon: Icons.check_rounded,
        );
      case 10:
        return const _OrderStatusUi(
          label: 'Kansellert', // TODO(l10n)
          foreground: ScSaasThemeTokens.danger,
          icon: Icons.close_rounded,
        );
      default:
        return const _OrderStatusUi(
          label: 'Bestilt', // TODO(l10n)
          foreground: ScSaasThemeTokens.gray500,
        );
    }
  }
}

/// `.oh-order .amt .st` — levert = success, vei = warning.
class _OrderStatusUi {
  final String label;
  final Color foreground;
  final IconData? icon;

  const _OrderStatusUi({
    required this.label,
    required this.foreground,
    this.icon,
  });
}

// ── Prototype copy with no matching l10n key ─────────────────────────────
const String kAoYourOrdersLabel = 'Dine bestillinger'; // TODO(l10n)
const String kAoDonationBannerSub =
    'gjennom kjøpene dine — takk! 💜'; // TODO(l10n)
const String kAoToTheClub = 'kr til klubben'; // TODO(l10n)
const String kAoReceiptsInfoNote =
    'Kvitteringer og ordrebekreftelser sendes til e-posten din.'; // TODO(l10n)
const String kAoEmptyHistoryTitle =
    'Du har ingen bestillinger ennå.'; // TODO(l10n)
const String kAoEmptyHistorySub =
    'Handle fra en butikk i nærheten — klubben får en andel av alt du kjøper.'; // TODO(l10n)
const String kAoEmptyHistoryCta =
    'Utforsk butikker og restauranter'; // TODO(l10n)
