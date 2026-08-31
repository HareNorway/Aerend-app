import 'package:flutter/material.dart';

import '../../../theme/ae_typography.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../ui/kit/ae_theme.dart';
import '../campaign_delivery_utils.dart';
import '../campaign_strings.dart';
import '../models/campaign_order_pojo.dart';
import 'campaign_tracker_countdown.dart';
import 'cp_change_sheet.dart';
import 'cp_receipt_paper.dart';

class CpActiveCard extends StatelessWidget {
  const CpActiveCard({
    super.key,
    required this.order,
    this.onChanged,
  });

  final CampaignMyOrder order;
  final ValueChanged<CampaignMyOrder>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final locked = order.state == CampaignPurchaseState.locked;
    final pickup = order.isPickup;
    final window = order.windowInstant;
    final day = campaignDayLabel(window);
    final clock = campaignClockLabel(window);
    final placeValue = campaignLocationLine(order, pickup: pickup);
    final canChange = order.canChangeMethod && order.otherMethodOffered;
    final dash = Color.lerp(Colors.white, theme.primary, 0.26)!;

    return CpReceiptPaper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CpReceiptHeader(order: order),
          if (window != null) _CountWrap(order: order, pickup: pickup),
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
                  label: pickup
                      ? CampaignStrings.rowPickupDay
                      : CampaignStrings.rowDeliveryDay,
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
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.dp(16),
              0,
              context.dp(16),
              context.dp(13),
            ),
            child: Column(
              children: [
                CpDashedHairline(color: dash),
                SizedBox(height: context.dp(12)),
                Row(
                  children: [
                    CpPointsStamp(points: order.earnedPoints ?? 0),
                    const Spacer(),
                    _ChangeButton(
                      locked: locked,
                      enabled: canChange,
                      onTap: canChange
                          ? () async {
                              final ok = await showCpChangeSheet(
                                context,
                                order,
                              );
                              if (ok == true) onChanged?.call(order);
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (locked)
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.dp(16),
                0,
                context.dp(16),
                context.dp(13),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: ScSaasThemeTokens.gray50,
                  borderRadius: BorderRadius.circular(context.dp(12)),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.dp(12),
                    context.dp(10),
                    context.dp(12),
                    context.dp(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.info_outline,
                          size: 13,
                          color: ScSaasThemeTokens.gray500,
                        ),
                      ),
                      SizedBox(width: context.dp(8)),
                      Expanded(
                        child: Text(
                          CampaignStrings.lockMessage(
                            campaignLockAtLabel(order.methodChangeLockAt),
                            delivery: !pickup,
                          ),
                          style: aeCaption(color: ScSaasThemeTokens.gray600)
                              .copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.dp(16),
                0,
                context.dp(16),
                context.dp(12),
              ),
              child: Text(
                order.methodChangeFeeNok > 0
                    ? CampaignStrings.changeFee(
                        campaignKrNumber(order.methodChangeFeeNok),
                      )
                    : CampaignStrings.freeChangeUntil(
                        campaignLockAtLabel(order.methodChangeLockAt),
                      ),
                style: aeCaption(
                  color: order.methodChangeFeeNok > 0
                      ? ScSaasThemeTokens.gray500
                      : ScSaasThemeTokens.success,
                ).copyWith(fontWeight: FontWeight.w700, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

/// `.count-wrap` — dashed rules, club-tint wash, `cp-shine` sweep.
class _CountWrap extends StatelessWidget {
  const _CountWrap({required this.order, required this.pickup});

  final CampaignMyOrder order;
  final bool pickup;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final window = order.windowInstant!;
    final dash = Color.lerp(Colors.white, theme.primary, 0.26)!;
    final washTop = Color.lerp(Colors.white, theme.primary, 0.13)!;
    final washBot = Color.lerp(Colors.white, theme.primary, 0.07)!;
    return Column(
      children: [
        CpDashedHairline(color: dash),
        ClipRect(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(-0.7, -1),
                end: const Alignment(0.8, 1),
                colors: [washTop, washBot],
              ),
            ),
            child: Stack(
              children: [
                const Positioned.fill(child: _CpCountShine()),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.dp(16),
                    vertical: context.dp(14),
                  ),
                  child: Row(
                    children: [
                      TrackerDial(
                        windowStart: window,
                        boughtAt: order.boughtAt,
                      ),
                      SizedBox(width: context.dp(14)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trackerCountdownLabel(!pickup).toUpperCase(),
                              style: aeOverline(color: theme.primaryHover)
                                  .copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 0.9,
                              ),
                            ),
                            SizedBox(height: context.dp(7)),
                            TrackerCountdown(
                              windowStart: window,
                              size: TrackerCountdownSize.row,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        CpDashedHairline(color: dash),
      ],
    );
  }
}

/// `cp-shine` 4.4s — overlay slides −130% → 130% after a 62% dwell.
class _CpCountShine extends StatefulWidget {
  const _CpCountShine();

  @override
  State<_CpCountShine> createState() => _CpCountShineState();
}

class _CpCountShineState extends State<_CpCountShine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _started = false;
      if (_ctrl.isAnimating) _ctrl.stop();
      _ctrl.value = 0;
      return;
    }
    if (_started) return;
    _started = true;
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _tx(double t) {
    if (t <= 0.62) return -1.3;
    if (t >= 0.88) return 1.3;
    final p = Curves.easeInOut.transform((t - 0.62) / 0.26);
    return -1.3 + p * 2.6;
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth.isFinite ? c.maxWidth : 0.0;
              return Transform.translate(
                offset: Offset(_tx(_ctrl.value) * w, 0),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-0.35, -1),
                      end: Alignment(0.7, 1),
                      colors: [
                        Color(0x00FFFFFF),
                        Color(0x8CFFFFFF),
                        Color(0x00FFFFFF),
                      ],
                      stops: [0.42, 0.50, 0.58],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ChangeButton extends StatelessWidget {
  const _ChangeButton({
    required this.locked,
    required this.enabled,
    this.onTap,
  });

  final bool locked;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final off = !enabled;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: StadiumBorder(
            side: BorderSide(
              color: off
                  ? Colors.transparent
                  : theme.primary.withValues(alpha: 0.22),
            ),
          ),
          color: off ? ScSaasThemeTokens.gray50 : null,
          gradient: off
              ? null
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Color.lerp(Colors.white, theme.primary, 0.07)!,
                  ],
                ),
          shadows: off
              ? [
                  BoxShadow(
                    color: ScSaasThemeTokens.text.withValues(alpha: 0.08),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0x1F140C28),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                  BoxShadow(
                    color: const Color(0x57140C28),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                    spreadRadius: -6,
                  ),
                ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.dp(6),
            context.dp(6),
            context.dp(12),
            context.dp(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: context.dp(24),
                height: context.dp(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: off ? null : theme.shinyGradient,
                  color: off ? Colors.white : null,
                  border: off
                      ? Border.all(
                          color:
                              ScSaasThemeTokens.text.withValues(alpha: 0.08),
                        )
                      : null,
                ),
                child: Icon(
                  locked ? Icons.lock_outline : Icons.sync_rounded,
                  size: 13,
                  color: off ? ScSaasThemeTokens.gray500 : Colors.white,
                ),
              ),
              SizedBox(width: context.dp(7)),
              Text(
                locked
                    ? CampaignStrings.lockedButton
                    : CampaignStrings.changeButton,
                style: aeCaption(
                  color: off ? ScSaasThemeTokens.gray500 : theme.primaryHover,
                ).copyWith(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
