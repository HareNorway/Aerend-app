import 'package:flutter/material.dart';
import 'package:aerend_customer/blocs/bloc.dart';
import 'package:aerend_customer/screens/common/homeMainV1/home_main_v1.dart';

import 'deliveries_order_detail_dl.dart';
import 'deliveries_order_detail_bloc.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';

class DeliveriesOrderDetail extends StatefulWidget {
  final bool isFromTrackOrderActivity;
  final int orderId;

  const DeliveriesOrderDetail(
      {super.key,
      required this.isFromTrackOrderActivity,
      required this.orderId});

  @override
  State<DeliveriesOrderDetail> createState() => _DeliveriesOrderDetailState();
}

class _DeliveriesOrderDetailState extends State<DeliveriesOrderDetail> {
  DeliveriesOrderDetailBloc? _bloc;

  @override
  void didChangeDependencies() {
    _bloc = DeliveriesOrderDetailBloc(context, widget.orderId, this);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = Theme.of(context).scaffoldBackgroundColor;
    final Color cardBg = isDark ? const Color(0xFF252530) : ScSaasThemeTokens.card;
    final Color textPrimary =
        isDark ? Colors.white : ScSaasThemeTokens.text;
    final Color textSecondary =
        isDark ? Colors.white70 : ScSaasThemeTokens.muted;
    final Color tintBg =
        isDark ? Colors.white.withOpacity(0.06) : ScSaasThemeTokens.primary.withOpacity(0.08);
    final Color breakdownBg =
        isDark ? Colors.white.withOpacity(0.04) : ScSaasThemeTokens.border.withOpacity(0.55);
    final List<BoxShadow> cardShadow = isDark
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ]
        : [
            BoxShadow(
              color: ScSaasThemeTokens.primary.withOpacity(0.07),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ];

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: pageBg,
        toolbarHeight: 64,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Expanded(
              child: Text(
                languages.receipt,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Material(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : ScSaasThemeTokens.card,
              shape: const CircleBorder(),
              elevation: isDark ? 0 : 1,
              shadowColor: Colors.black26,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => openScreenWithResult(
                  context,
                  HomeMainV1(orderId: widget.orderId),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(Icons.close_rounded, color: textPrimary, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: StreamBuilder<ApiResponse<DeliveriesOrderDetailPojo>>(
          stream: _bloc!.subject,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  color: ScSaasThemeTokens.primary,
                  strokeWidth: 2.5,
                ),
              );
            }
            final DeliveriesOrderDetailPojo? detail = snapshot.data?.data;
            if (detail == null) {
              return Center(
                child: Text(
                  languages.apiErrorUnexpectedErrorMsg,
                  style: TextStyle(color: textPrimary),
                ),
              );
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            tintBg,
                            tintBg.withOpacity(0),
                          ],
                          radius: 1.15,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: LoadImageSimple(
                        image: 'assets/images/delivered.png',
                        width: deviceWidth * 0.42,
                        height: deviceWidth * 0.34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E7A4A).withOpacity(0.35)
                            : ScSaasThemeTokens.accentSoft,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF34C759).withOpacity(0.5)
                              : ScSaasThemeTokens.accent.withOpacity(0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: isDark
                                ? const Color(0xFF34C759)
                                : const Color(0xFF2A9D6E),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            languages.delivered,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      detail.storeName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : ScSaasThemeTokens.border.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${detail.orderNo}',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : ScSaasThemeTokens.border,
                      ),
                      boxShadow: cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _rowItem(
                          'Order number',
                          '#${detail.orderNo}',
                          textPrimary,
                          textSecondary,
                        ),
                        _rowItem(
                          'Order from',
                          detail.storeName,
                          textPrimary,
                          textSecondary,
                        ),
                        _addressBlock(
                          'Delivery address',
                          _safeAddress(detail.deliveryAddress),
                          textPrimary,
                          textSecondary,
                          isDark,
                        ),
                        _rowItem(
                          'Payment type',
                          getPaymentType(context, detail.paymentType),
                          textPrimary,
                          textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: isDark
                              ? Colors.white12
                              : ScSaasThemeTokens.border,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: breakdownBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              _rowItem(
                                languages.itemTotal,
                                _amount(_effectiveItemTotal(detail)),
                                textPrimary,
                                textSecondary,
                              ),
                              _rowItem(
                                languages.deliveryCharges,
                                _amount(detail.deliveryCost),
                                textPrimary,
                                textSecondary,
                              ),
                              _rowItem(
                                languages.packagingCharge,
                                _amount(detail.packagingCost),
                                textPrimary,
                                textSecondary,
                              ),
                              _rowItem(
                                languages.tax,
                                _amount(detail.taxCost),
                                textPrimary,
                                textSecondary,
                              ),
                              _rowItem(
                                languages.discount,
                                _amount(_effectiveDiscountTotal(detail)),
                                textPrimary,
                                textSecondary,
                                valueColor: isDark
                                    ? const Color(0xFFFF8A8A)
                                    : ScSaasThemeTokens.danger,
                              ),
                              if (getDoubleFromDynamic(detail.tip) > 0)
                                _rowItem(
                                  languages.tip,
                                  _amount(detail.tip),
                                  textPrimary,
                                  textSecondary,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      ScSaasThemeTokens.primary.withOpacity(0.22),
                                      ScSaasThemeTokens.primary.withOpacity(0.12),
                                    ]
                                  : [
                                      ScSaasThemeTokens.primary.withOpacity(0.12),
                                      ScSaasThemeTokens.primary.withOpacity(0.05),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: ScSaasThemeTokens.primary.withOpacity(0.22),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  languages.total,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                _amount(detail.totalPay),
                                style: TextStyle(
                                  color: ScSaasThemeTokens.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (detail.productList.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ScSaasThemeTokens.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.receipt_long_rounded,
                            size: 22,
                            color: ScSaasThemeTokens.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          languages.orderDetails,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...detail.productList.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : ScSaasThemeTokens.border,
                            ),
                            boxShadow: isDark
                                ? null
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(top: 7, right: 12),
                                decoration: BoxDecoration(
                                  color: ScSaasThemeTokens.primary
                                      .withOpacity(0.65),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  item.productName,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _amount(item.productPrice ??
                                        item.productPriceForOne),
                                    style: TextStyle(
                                      color: ScSaasThemeTokens.primary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    '× ${item.productQuantity}',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: MediaQuery.paddingOf(context).bottom + 28),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _safeAddress(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return '---';
    return trimmed;
  }

  /// Order detail API sometimes omits `total_item_cost`; sum line items instead.
  double _effectiveItemTotal(DeliveriesOrderDetailPojo detail) {
    final double fromApi = getDoubleFromDynamic(detail.totalItemCost);
    if (fromApi > 0) return fromApi;
    double sum = 0;
    for (final item in detail.productList) {
      final double unit = getDoubleFromDynamic(
        item.productPrice ?? item.productPriceForOne,
      );
      sum += unit * item.productQuantity;
    }
    return sum;
  }

  /// Promo / refer amounts are often outside [discount_cost] alone.
  double _effectiveDiscountTotal(DeliveriesOrderDetailPojo detail) {
    return getDoubleFromDynamic(detail.discountCost) +
        getDoubleFromDynamic(detail.promoCodeDiscount) +
        getDoubleFromDynamic(detail.referDiscount);
  }

  String _amount(dynamic value) {
    return getAmountWithCurrency(getDoubleFromDynamic(value));
  }

  Widget _addressBlock(
    String label,
    String value,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : ScSaasThemeTokens.backgroundLavender.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : ScSaasThemeTokens.border,
              ),
            ),
            child: Text(
              value,
              textAlign: TextAlign.start,
              style: TextStyle(
                color: textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowItem(
    String label,
    String value,
    Color textPrimary,
    Color textSecondary, {
    bool isBold = false,
    int valueMaxLines = 1,
    Color? valueColor,
  }) {
    final TextStyle keyStyle = TextStyle(
      color: textSecondary,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
    );
    final TextStyle valueStyle = TextStyle(
      color: valueColor ?? textPrimary,
      fontSize: 14,
      fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
      letterSpacing: -0.1,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 5,
            child: Text(label, style: keyStyle),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              maxLines: valueMaxLines,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}
