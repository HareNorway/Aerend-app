import 'package:flutter/material.dart';
import 'package:aerend_customer/blocs/bloc.dart';
import 'package:aerend_customer/theme/sc_saas_theme.dart';
import 'package:aerend_customer/screens/common/orderHistory/order_history_dl.dart';
import 'package:aerend_customer/commonView/no_record_found.dart';

import '../../../../utils/utils.dart';
import '../../../../ui/kit/ae_theme.dart';
import '../../../../ui/kit/ae_rise_in.dart';
import '../../address_order_chrome.dart';
// Imported through the same `package:` URI the bloc uses — mixing a relative
// and a package URI for this library made the analyzer treat
// `ApiResponse<OrderDetailPojo>` as two distinct types (pre-existing error).
import 'package:aerend_customer/screens/common/orderHistory/order_detail/order_detail_dl.dart';

import 'order_detail_bloc.dart';

/// Ordredetaljer — prototype `OrderDetailScreen` in `dugnad/address-order.jsx`:
/// `.tk-head` + `.dgo-head` header card + `.dgo-route` from/to block +
/// `.dg-label`/`.dgo-sum` item lines & totals + `.dg-label`/`.dgo-ship`
/// delivery block. Bloc wiring and the API fallbacks are unchanged.
class OrderDetail extends StatefulWidget {
  final OrderHistoryListItem orderDetail;

  const OrderDetail({super.key, required this.orderDetail});

  @override
  State<OrderDetail> createState() => _OrderDetailState();
}

class _OrderDetailState extends State<OrderDetail> {
  bool isEmpty = true;
  OrderDetailBloc? bloc;

  @override
  initState() {
    super.initState();
    bloc = OrderDetailBloc(context, widget.orderDetail.orderId, this);
  }

  @override
  void didChangeDependencies() {
    bloc ??= OrderDetailBloc(context, widget.orderDetail.orderId, this);
    super.didChangeDependencies();
  }

  bool get _isDelivered {
    final s = widget.orderDetail.orderStatus;
    return s >= 6 && s <= 9;
  }

  @override
  Widget build(BuildContext context) {
    var step = 0;
    Widget rise(Widget child) {
      final delay = Duration(milliseconds: 120 + 70 * step++);
      return AeRiseIn(delay: delay, child: child);
    }

    return Scaffold(
      backgroundColor: context.aeTheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AoTkHead(title: kAoOrderDetailTitle),
            Expanded(
              // .ae-body { padding: 0 18px 120px; gap: 16px }
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                children: [
                  rise(_buildHeadCard()),
                  const SizedBox(height: 16),
                  rise(_buildRoute()),
                  const SizedBox(height: 16),
                  rise(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AoSectionLabel(languages.orderSummary, bottom: 8),
                        _buildSummary(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  rise(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AoSectionLabel(languages.delivery, bottom: 8),
                        _buildShipping(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `.dgo-head` — 48px crest tile, store name, "#order · date", status pill.
  Widget _buildHeadCard() {
    final order = widget.orderDetail;
    final theme = context.aeTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.background,
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: order.storeImage.isNotEmpty
                ? LoadImageWithPlaceHolder(
                    width: 48,
                    height: 48,
                    image: order.storeImage,
                    borderRadius: BorderRadius.circular(14),
                  )
                : Icon(
                    Icons.storefront_rounded,
                    size: 22,
                    color: theme.primaryHover,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // .dgo-head .nm
                Text(
                  order.storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: aoText(
                    16,
                    FontWeight.w800,
                    letterSpacingEm: -0.01,
                    color: theme.text,
                  ),
                ),
                const SizedBox(height: 2),
                // .dgo-head .no
                Text(
                  '#${order.orderNo} · ${order.orderDateTime}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: aoText(
                    12.5,
                    FontWeight.w600,
                    color: ScSaasThemeTokens.gray500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _statusPill(),
        ],
      ),
    );
  }

  /// `.dgo-head .st` — levert (#EAFAF0/#1F8A5B) vs vei (club tint / primaryHover).
  Widget _statusPill() {
    final delivered = _isDelivered;
    final theme = context.aeTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: delivered ? kAoSuccessChipBg : theme.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            delivered ? Icons.check_rounded : Icons.local_shipping_outlined,
            size: 11,
            color: delivered ? kAoSuccessChipFg : theme.primaryHover,
          ),
          const SizedBox(width: 4),
          Text(
            delivered ? kAoStatusDelivered : kAoStatusOnTheWay,
            style: aoText(
              11.5,
              FontWeight.w800,
              color: delivered ? kAoSuccessChipFg : theme.primaryHover,
            ),
          ),
        ],
      ),
    );
  }

  /// `.dgo-route` — club-tint Fra → Til block.
  Widget _buildRoute() {
    final theme = context.aeTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.primaryTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _routeLeg(kAoRouteFrom, widget.orderDetail.storeName)),
          const SizedBox(width: 10),
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: theme.primarySoft,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _routeLeg(
              kAoRouteTo,
              _firstAddressLine(widget.orderDetail.deliveryAddress),
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeLeg(String key, String value) {
    final theme = context.aeTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          key.toUpperCase(),
          style: aoText(
            11,
            FontWeight.w800,
            letterSpacingEm: 0.06,
            color: ScSaasThemeTokens.gray500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: aoText(14.5, FontWeight.w800, color: theme.text),
        ),
      ],
    );
  }

  /// `.dgo-sum` — item lines, fee rows and the `.tot` grand total.
  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: StreamBuilder<ApiResponse<OrderDetailPojo>>(
        stream: bloc?.subject.stream,
        builder: (context, snapshot) {
          final api = snapshot.data;

          if (api == null || api.status == Status.loading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          // If the API failed (for example, pickup-at-store orders with an
          // outdated delivery range), fall back to a basic summary built from
          // the already-known history data so the screen is never empty.
          if (api.status == Status.error) {
            return _fallbackOrderSummary(
              errorMessage: api.message,
              totalFromHistory: widget.orderDetail.totalPay,
            );
          }

          final OrderDetailPojo? detail = api.data;
          if (detail == null) {
            return _fallbackOrderSummary(
              totalFromHistory: widget.orderDetail.totalPay,
            );
          }

          final double subtotal = detail.subTotal;
          final double deliveryFee = detail.deliveryFee;
          final double orderCost = detail.orderFee;
          final List<OrderSummaryItem> orderList = detail.orderSummaryList;

          if (orderList.isEmpty &&
              subtotal == 0 &&
              deliveryFee == 0 &&
              orderCost == 0 &&
              detail.tip == 0 &&
              widget.orderDetail.totalPay > 0) {
            // Another safety net: if the backend returns no monetary info,
            // still show the total from history.
            return _fallbackOrderSummary(
              totalFromHistory: widget.orderDetail.totalPay,
            );
          }

          final total = subtotal + deliveryFee + orderCost + detail.tip;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final item in orderList) _summaryItem(item),
              // .dgo-sum .rows { padding: 12px 0 2px; gap: 9px }
              const SizedBox(height: 12),
              _feeRow(languages.subTotal, subtotal),
              const SizedBox(height: 9),
              _feeRow(languages.delivery, deliveryFee),
              const SizedBox(height: 9),
              _feeRow(kAoServiceFee, orderCost),
              const SizedBox(height: 9),
              _feeRow(kAoCourierTip, detail.tip),
              const SizedBox(height: 2),
              _totalRow(total),
            ],
          );
        },
      ),
    );
  }

  /// `.dgo-sum .it` — 44px thumb, name, line price, `.qt` quantity chip.
  Widget _summaryItem(OrderSummaryItem item) {
    final theme = context.aeTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kAoHairline)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              color: theme.background,
              child: LoadImageSimple(
                image: item.productImage,
                width: 44,
                height: 44,
                imageFit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: aoText(14.5, FontWeight.w800, color: theme.text),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_money(item.productAmount - item.discountAmount)} NOK',
                  style: aoText(
                    13,
                    FontWeight.w700,
                    color: ScSaasThemeTokens.gray500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // .dgo-sum .it .qt
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: Color.alphaBlend(
                  theme.primary.withValues(alpha: 0.28),
                  Colors.white,
                ),
                width: 1.5,
              ),
            ),
            child: Text(
              '${item.productQuantity}×',
              style: aoText(
                12.5,
                FontWeight.w800,
                color: theme.primaryHover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// `.dgo-sum .rows .r` — 13.5/600 gray-500 label, 700 club text value.
  Widget _feeRow(String label, double value) {
    final theme = context.aeTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: aoText(
              13.5,
              FontWeight.w600,
              color: ScSaasThemeTokens.gray500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${_money(value)} NOK',
          style: aoText(13.5, FontWeight.w700, color: theme.text),
        ),
      ],
    );
  }

  /// `.dgo-sum .tot` — 12px top margin, 13px top padding, 1.5px hairline.
  Widget _totalRow(double total) {
    final theme = context.aeTheme;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.only(top: 13),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: kAoHairline, width: 1.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            languages.total,
            style: aoText(
              14,
              FontWeight.w800,
              color: ScSaasThemeTokens.gray500,
            ),
          ),
          Text(
            '${_money(total)} NOK',
            style: aoText(17, FontWeight.w800, color: theme.text),
          ),
        ],
      ),
    );
  }

  /// `.dgo-ship` — delivery address row (+ error/fallback safe).
  Widget _buildShipping() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _shipRow(
            Icons.place_outlined,
            languages.deliveryAddress,
            widget.orderDetail.deliveryAddress.trim().isEmpty
                ? '—'
                : widget.orderDetail.deliveryAddress,
          ),
        ],
      ),
    );
  }

  Widget _shipRow(IconData icon, String key, String value) {
    final theme = context.aeTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.primaryTint,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 17, color: theme.primaryHover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  key.toUpperCase(),
                  style: aoText(
                    11.5,
                    FontWeight.w800,
                    letterSpacingEm: 0.05,
                    color: ScSaasThemeTokens.gray500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: aoText(
                    14.5,
                    FontWeight.w700,
                    height: 1.35,
                    color: theme.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackOrderSummary({
    String? errorMessage,
    double? totalFromHistory,
  }) {
    final hasTotal = (totalFromHistory ?? 0) > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        if (errorMessage != null && errorMessage.trim().isNotEmpty) ...[
          AoInfoBox(
            icon: Icons.info_outline_rounded,
            text: errorMessage,
          ),
          const SizedBox(height: 14),
        ],
        if (hasTotal)
          _totalRow(totalFromHistory!)
        else
          const NoRecordFound(message: 'No order summary available.'),
      ],
    );
  }
}

String _money(double value) => value.toStringAsFixed(2);

String _firstAddressLine(String address) {
  final trimmed = address.trim();
  if (trimmed.isEmpty) return '—';
  final parts = trimmed.split(',');
  return parts.first.trim().isEmpty ? trimmed : parts.first.trim();
}

// ── Prototype copy with no matching l10n key ─────────────────────────────
const String kAoOrderDetailTitle = 'Ordredetaljer'; // TODO(l10n)
const String kAoRouteFrom = 'Fra'; // TODO(l10n)
const String kAoRouteTo = 'Til'; // TODO(l10n)
const String kAoStatusDelivered = 'Levert'; // TODO(l10n)
const String kAoStatusOnTheWay = 'På vei'; // TODO(l10n)
const String kAoServiceFee = 'Servicegebyr'; // TODO(l10n)
const String kAoCourierTip = 'Tips til budet'; // TODO(l10n)
