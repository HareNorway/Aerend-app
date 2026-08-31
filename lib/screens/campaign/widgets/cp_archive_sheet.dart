import 'package:flutter/material.dart';

import '../../../theme/ae_typography.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../dugnad/dugnad_club_theme.dart';
import '../../dugnad/dugnad_sheet.dart';
import '../../dugnad/widgets/dugnad_confirm_sheet.dart';
import '../campaign_delivery_utils.dart';
import '../campaign_my_orders_screen.dart';
import '../campaign_strings.dart';
import '../models/campaign_order_pojo.dart';
import 'cp_receipt_paper.dart';

Future<void> showCpArchiveSheet(
  BuildContext context,
  CampaignMyOrder order,
) async {
  final openHistory = await showDugnadSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _CpArchiveSheet(order: order),
  );
  if (openHistory == true && context.mounted) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CampaignMyOrdersScreen()),
    );
  }
}

class _CpArchiveSheet extends StatelessWidget {
  const _CpArchiveSheet({required this.order});

  final CampaignMyOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final pickup = order.isPickup;
    final window = order.windowInstant;
    final day = campaignDayLabel(window);
    final clock = campaignClockLabel(window);
    final placeValue = campaignLocationLine(order, pickup: pickup);
    final doneTitle = pickup
        ? CampaignStrings.archivePickedUp(day)
        : CampaignStrings.archiveDelivered(day);
    final media = MediaQuery.of(context);

    return SingleChildScrollView(
      child: Padding(
      padding: EdgeInsets.fromLTRB(
        context.dp(16),
        context.dp(18),
        context.dp(16),
        media.padding.bottom + context.dp(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DugnadSheetHandle(bottom: 8),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.close, color: theme.ink, size: 18),
            ),
          ),
          CpReceiptPaper(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CpReceiptHeader(order: order),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: context.dp(16)),
                  padding: EdgeInsets.all(context.dp(12)),
                  decoration: BoxDecoration(
                    color: ScSaasThemeTokens.success.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(context.dp(12)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: context.dp(30),
                        height: context.dp(30),
                        decoration: BoxDecoration(
                          color: ScSaasThemeTokens.success.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(context.dp(10)),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: ScSaasThemeTokens.success,
                        ),
                      ),
                      SizedBox(width: context.dp(10)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doneTitle,
                              style: aeTitle(color: ScSaasThemeTokens.success)
                                  .copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                              ),
                            ),
                            SizedBox(height: context.dp(1)),
                            Text(
                              CampaignStrings.archiveCompleteNote,
                              style: aeCaption(
                                color: ScSaasThemeTokens.success
                                    .withValues(alpha: 0.7),
                              ).copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.dp(16),
                    context.dp(12),
                    context.dp(16),
                    context.dp(11),
                  ),
                  child: Column(
                    children: [
                      CpDottedRow(
                        label: CampaignStrings.rowPaid,
                        value: campaignKr(order.totalPay),
                      ),
                      SizedBox(height: context.dp(7)),
                      CpDottedRow(
                        label: CampaignStrings.boughtLabel,
                        value: campaignDayLabel(order.boughtAt),
                      ),
                      SizedBox(height: context.dp(7)),
                      CpDottedRow(
                        label: pickup
                            ? CampaignStrings.pickedUpShort
                            : CampaignStrings.deliveredShort,
                        value: day,
                      ),
                      if (clock.isNotEmpty) ...[
                        SizedBox(height: context.dp(7)),
                        CpDottedRow(
                          label: CampaignStrings.rowTimeSlot,
                          value: clock,
                        ),
                      ],
                      if (placeValue.isNotEmpty) ...[
                        SizedBox(height: context.dp(7)),
                        CpDottedRow(
                          label: pickup
                              ? CampaignStrings.rowPickupPlace
                              : CampaignStrings.rowAddress,
                          value: placeValue,
                        ),
                      ],
                      SizedBox(height: context.dp(7)),
                      CpDottedRow(
                        label: CampaignStrings.rowMethod,
                        value: '',
                        valueWidget: Align(
                          alignment: Alignment.centerRight,
                          child: CpMethodTag(pickup: pickup),
                        ),
                      ),
                      ..._changeLogRows(order),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.dp(16),
                    context.dp(12),
                    context.dp(16),
                    context.dp(13),
                  ),
                  child: Column(
                    children: [
                      CpDashedHairline(
                        color: Color.lerp(Colors.white, theme.primary, 0.26)!,
                      ),
                      SizedBox(height: context.dp(12)),
                      Row(
                        children: [
                          CpPointsStamp(points: order.earnedPoints ?? 0),
                          SizedBox(width: context.dp(10)),
                          Expanded(
                            child: Text(
                              CampaignStrings.pointsAddedToAccount,
                              style: aeCaption().copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          DugnadSheetPrimaryButton(
            label: CampaignStrings.viewFullHistory,
            icon: Icons.receipt_long_outlined,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
      ),
    );
  }

  List<Widget> _changeLogRows(CampaignMyOrder order) {
    if (order.methodChangeLog.isEmpty) return const [];
    return [
      for (final e in order.methodChangeLog) ...[
        SizedBox(height: 7),
        CpDottedRow(
          label: e.feePaid
              ? '${_methodLabel(e.from)} → ${_methodLabel(e.to)}'
              : CampaignStrings.methodChangePending,
          value: campaignKr(e.feeNok),
        ),
      ],
    ];
  }

  String _methodLabel(String method) => method == 'pickup'
      ? CampaignStrings.methodPickup
      : CampaignStrings.methodDelivery;
}
