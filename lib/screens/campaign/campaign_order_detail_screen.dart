import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import '../common/address_order_chrome.dart';
import '../dugnad/dugnad_club_theme.dart';
import '../dugnad/widgets/dugnad_rise_in.dart';
import 'campaign_order_pdf.dart';
import 'models/campaign_order_pojo.dart';

/// Matkasse-ordredetaljer — same `.tk-head` / white shadow-card language as
/// `OrderDetail` (`dugnad/address-order.jsx`), scoped to a single campaign
/// order: head card, order info rows, payment rows and an optional product
/// summary, plus a sticky PDF download for accounting.
class CampaignOrderDetailScreen extends StatefulWidget {
  final CampaignMyOrder order;

  const CampaignOrderDetailScreen({super.key, required this.order});

  @override
  State<CampaignOrderDetailScreen> createState() =>
      _CampaignOrderDetailScreenState();
}

class _CampaignOrderDetailScreenState extends State<CampaignOrderDetailScreen> {
  bool _exporting = false;

  CampaignMyOrder get order => widget.order;

  String _formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      return DateFormat('d. MMM yyyy, HH:mm', 'nb_NO')
          .format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      return DateFormat('d. MMM yyyy', 'nb_NO').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  bool get _isDone => order.status == 9;

  Future<void> _downloadPdf() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      await CampaignOrderPdfExporter.share(
        context,
        order: order,
        statusLabel: (_) => _isDone
            ? languages.campaignOrderDone
            : languages.campaignOrderOngoing,
        deliveryMethodLabel: (o) => o.deliveryMethod == 'pickup'
            ? languages.campaignPickupAtClub
            : languages.campaignHomeDelivery,
        labels: {
          'title': languages.campaignOrderDetailsTitle,
          'matkasseFallback': languages.campaignMatkasseFallback,
          'orderNumber': languages.campaignOrderNumber,
          'placedOn': languages.campaignOrderPlacedOn,
          'deliveryMethod': languages.campaignDeliveryMethod,
          'distributionDate': languages.campaignDistributionDate,
          'pickupLocation': languages.campaignPickupLocation,
          'paymentStatus': languages.campaignPaymentStatusLabel,
          'paymentMethod': languages.campaignPaymentMethod,
          'amount': languages.campaignOrderAmount,
          'products': languages.campaignProductsSection,
          'pdfFooter': languages.campaignOrderPdfFooter,
        },
      );
    } catch (_) {
      if (!mounted) return;
      openSimpleSnackbar(languages.campaignOrderPdfFailed);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var step = 0;
    Widget rise(Widget child) {
      final delay = Duration(milliseconds: 120 + 70 * step++);
      return DugnadRiseIn(delay: delay, child: child);
    }

    final theme = context.dugnadTheme;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AoTkHead(title: languages.campaignOrderDetailsTitle),
            Expanded(
              // .ae-body { padding: 0 18px …; gap: 16px }
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                children: [
                  rise(_buildHeadCard(context)),
                  const SizedBox(height: 16),
                  rise(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AoSectionLabel(
                          languages.campaignOrderNumber,
                          bottom: 8,
                        ),
                        _buildOrderInfo(context),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  rise(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AoSectionLabel(
                          languages.campaignPaymentStatusLabel,
                          bottom: 8,
                        ),
                        _buildPayment(context),
                      ],
                    ),
                  ),
                  if (order.productSummary != null &&
                      order.productSummary!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    rise(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AoSectionLabel(
                            languages.campaignProductsSection,
                            bottom: 8,
                          ),
                          _buildProducts(),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AoStickyFooter(
              child: AoPressable(
                onTap: _exporting ? null : _downloadPdf,
                scale: 0.98,
                builder: (context, pressed) {
                  return Container(
                    width: double.infinity,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: theme.shadowButton,
                    ),
                    child: _exporting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.download_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                languages.campaignDownloadPdf,
                                style: aoText(
                                  15.5,
                                  FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `.dgo-head` — 48px icon tile, campaign name, club name, status pill.
  Widget _buildHeadCard(BuildContext context) {
    final theme = context.dugnadTheme;
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
              color: theme.primaryTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              size: 22,
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
                    16,
                    FontWeight.w800,
                    letterSpacingEm: -0.01,
                    color: theme.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order.clubName ?? '-',
                  maxLines: 1,
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
          _statusPill(context),
        ],
      ),
    );
  }

  Widget _statusPill(BuildContext context) {
    final theme = context.dugnadTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _isDone ? kAoSuccessChipBg : theme.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isDone ? Icons.check_rounded : Icons.hourglass_top_rounded,
            size: 11,
            color: _isDone ? kAoSuccessChipFg : theme.primaryHover,
          ),
          const SizedBox(width: 4),
          Text(
            _isDone
                ? languages.campaignOrderDone
                : languages.campaignOrderOngoing,
            style: aoText(
              11.5,
              FontWeight.w800,
              color: _isDone ? kAoSuccessChipFg : theme.primaryHover,
            ),
          ),
        ],
      ),
    );
  }

  /// `.dgo-sum`-style label/value rows — order number, placed-on date,
  /// delivery method, distribution date/location, amount.
  Widget _buildOrderInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: Column(
        children: [
          _row(context, languages.campaignOrderNumber, '#${order.orderNo}'),
          _row(
            context,
            languages.campaignOrderPlacedOn,
            _formatDateTime(order.createdAt),
          ),
          _row(
            context,
            languages.campaignDeliveryMethod,
            order.deliveryMethod == 'pickup'
                ? languages.campaignPickupAtClub
                : languages.campaignHomeDelivery,
          ),
          _row(
            context,
            languages.campaignDistributionDate,
            _formatDate(order.distributionDate),
          ),
          _row(
            context,
            languages.campaignPickupLocation,
            order.distributionLocation ?? '-',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPayment(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: Column(
        children: [
          _row(
            context,
            languages.campaignPaymentStatusLabel,
            order.paymentStatusLabel,
          ),
          _row(
            context,
            languages.campaignPaymentMethod,
            (order.paymentProvider ?? '-').toUpperCase(),
          ),
          _totalRow(context),
        ],
      ),
    );
  }

  Widget _buildProducts() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: Text(
        order.productSummary!,
        style: aoText(
          13.5,
          FontWeight.w600,
          height: 1.5,
          color: ScSaasThemeTokens.gray500,
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: kAoHairline)),
            ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: aoText(
              13.5,
              FontWeight.w600,
              color: ScSaasThemeTokens.gray500,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: aoText(
                14,
                FontWeight.w700,
                color: context.dugnadTheme.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 13, bottom: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: kAoHairline, width: 1.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            languages.campaignOrderAmount,
            style: aoText(14, FontWeight.w800, color: ScSaasThemeTokens.gray500),
          ),
          Text(
            '${order.totalPay.round()} kr',
            style: aoText(
              17,
              FontWeight.w800,
              color: context.dugnadTheme.text,
            ),
          ),
        ],
      ),
    );
  }
}
