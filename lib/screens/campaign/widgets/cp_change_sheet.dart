import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/ae_typography.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/stripe_payment_helper.dart';
import '../../../utils/utils.dart';
import '../../dugnad/dugnad_celebration_orchestrator.dart';
import '../../../ui/kit/ae_theme.dart';
import '../../../ui/kit/ae_sheet.dart';
import '../../../ui/kit/ae_address_drawer.dart';
import '../../../ui/kit/ae_checkout_payment_selector.dart';
import '../../../ui/kit/ae_confirm_sheet.dart';
import '../../common/vipps/vipps_return_screens.dart';
import '../../common/manageAddress/manage_address_dl.dart';
import '../campaign_delivery_utils.dart';
import '../campaign_repo.dart';
import '../campaign_strings.dart';
import '../campaign_tracker_controller.dart';
import '../models/campaign_order_pojo.dart';
import 'campaign_swipe_pay_bar.dart';
import 'cp_receipt_paper.dart';

Future<bool?> showCpChangeSheet(
  BuildContext context,
  CampaignMyOrder order,
) {
  return showAeSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => CpChangeSheet(order: order),
  );
}

enum _ChangePhase { form, busy, done }

class CpChangeSheet extends StatefulWidget {
  const CpChangeSheet({super.key, required this.order});

  final CampaignMyOrder order;

  @override
  State<CpChangeSheet> createState() => _CpChangeSheetState();
}

class _CpChangeSheetState extends State<CpChangeSheet>
    with WidgetsBindingObserver {
  late AeCheckoutPayMethod _pay = aeCheckoutDefaultPayMethod();
  _ChangePhase _phase = _ChangePhase.form;
  bool _held = false;
  String? _payLabel;
  String _addressRaw = '';
  int? _addressId;
  Completer<bool>? _vippsWait;

  CampaignMyOrder get order => widget.order;
  bool get _toPickup => !order.isPickup;
  bool get _toDelivery => !_toPickup;
  String get _targetMethod => order.otherMethod;
  String get _targetLabel => _toPickup
      ? CampaignStrings.methodPickup
      : CampaignStrings.methodDelivery;
  double get _fee => order.methodChangeFeeNok;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_toDelivery) _hydrateAddress();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final wait = _vippsWait;
    if (wait != null && !wait.isCompleted) wait.complete(false);
    _vippsWait = null;
    clearPendingCampaignMethodChangeVipps();
    _release();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_onResumedFromVipps());
    }
  }

  Future<void> _onResumedFromVipps() async {
    final wait = _vippsWait;
    if (wait == null || wait.isCompleted) return;
    final settled = await _confirmFeePayment();
    if (!wait.isCompleted) wait.complete(settled);
  }

  void _hold() {
    if (_held) return;
    _held = true;
    DugnadCelebrationOrchestrator.instance.holdCriticalFlow();
  }

  void _release() {
    if (!_held) return;
    _held = false;
    DugnadCelebrationOrchestrator.instance.releaseCriticalFlow();
  }

  String _prefAddressText() {
    try {
      final raw = prefGetString(prefNewDeliveryAddress).trim();
      if (raw.isEmpty) return '';
      if (raw.startsWith('{')) {
        return AddressListItem.fromJson(jsonDecode(raw)).address.trim();
      }
      return raw;
    } catch (_) {
      return '';
    }
  }

  void _hydrateAddress() {
    final fromOrder = (order.deliveryAddress ?? '').trim();
    final fromPrefs = _prefAddressText();
    final id = prefGetInt(prefNewDeliveryAddressId);
    _addressRaw = fromOrder.isNotEmpty ? fromOrder : fromPrefs;
    _addressId = id > 0 ? id : null;
  }

  void _loadAddressFromPrefs() {
    final text = _prefAddressText();
    final id = prefGetInt(prefNewDeliveryAddressId);
    if (!mounted) return;
    setState(() {
      if (text.isNotEmpty) _addressRaw = text;
      if (id > 0) _addressId = id;
    });
  }

  Future<void> _pickAddress() async {
    HapticFeedback.lightImpact();
    await showAeAddressDrawer(
      context,
      parentContext: context,
      onAddressChanged: _loadAddressFromPrefs,
    );
    _loadAddressFromPrefs();
  }

  bool get _hasDeliveryAddress => _addressRaw.trim().isNotEmpty;

  String get _apiPayMethod =>
      _pay == AeCheckoutPayMethod.vipps ? 'vipps' : 'stripe';

  String _selectedPayLabel() {
    switch (_pay) {
      case AeCheckoutPayMethod.vipps:
        return CampaignStrings.payWithVippsSemanticsLabel;
      case AeCheckoutPayMethod.platformWallet:
        return aePlatformPayLabel;
      case AeCheckoutPayMethod.cardKlarna:
        return CampaignStrings.payCard;
    }
  }

  bool _isPayCancel(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('cancel');
  }

  Future<bool> _confirmFeePayment() async {
    for (var attempt = 0; attempt < 5; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      try {
        final response = await CampaignRepo().confirmPayment(order.orderNo);
        if (isMethodChangeFeeSettled(response, targetMethod: _targetMethod)) {
          clearPendingCampaignMethodChangeVipps();
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  Future<void> _commit() async {
    if (_phase != _ChangePhase.form) return;
    if (_toDelivery && !_hasDeliveryAddress) {
      openSimpleSnackbar(CampaignStrings.addressRequired);
      await _pickAddress();
      return;
    }
    setState(() {
      _phase = _ChangePhase.busy;
      _payLabel = _selectedPayLabel();
    });
    _hold();
    try {
      final result = await CampaignRepo().changeMethod(
        orderNo: order.orderNo,
        targetMethod: _targetMethod,
        paymentMethod: _apiPayMethod,
        deliveryAddress: _toDelivery ? _addressRaw.trim() : null,
        addressId: _toDelivery ? _addressId : null,
      );

      if (!mounted) return;

      switch (result.kind) {
        case ChangeMethodResultKind.changed:
          setState(() => _phase = _ChangePhase.done);
          return;
        case ChangeMethodResultKind.paymentRequired:
          final paid = await _collectFee(result);
          if (!mounted) return;
          if (!paid) {
            setState(() => _phase = _ChangePhase.form);
            return;
          }
          final settled = await _confirmFeePayment();
          if (!mounted) return;
          if (!settled) {
            setState(() => _phase = _ChangePhase.form);
            openSimpleSnackbar(CampaignStrings.errorGeneric);
            return;
          }
          setState(() => _phase = _ChangePhase.done);
          return;
        case ChangeMethodResultKind.locked:
          setState(() => _phase = _ChangePhase.form);
          openSimpleSnackbar(
            CampaignStrings.lockMessage(
              campaignLockAtLabel(result.lockAt ?? order.methodChangeLockAt),
              delivery: !order.isPickup,
            ),
          );
          return;
        case ChangeMethodResultKind.noChange:
          setState(() => _phase = _ChangePhase.form);
          openSimpleSnackbar(CampaignStrings.errorNoChange);
          return;
        case ChangeMethodResultKind.notOffered:
          setState(() => _phase = _ChangePhase.form);
          openSimpleSnackbar(
            CampaignStrings.errorMethodNotOffered(
              (result.offeredMethods ?? order.methodsOffered)
                  .map((m) => m == 'pickup'
                      ? CampaignStrings.methodPickup
                      : CampaignStrings.methodDelivery)
                  .join(', '),
            ),
          );
          return;
        case ChangeMethodResultKind.error:
          setState(() => _phase = _ChangePhase.form);
          openSimpleSnackbar(result.message ?? CampaignStrings.errorGeneric);
          return;
      }
    } finally {
      _release();
    }
  }

  Future<bool> _collectFee(ChangeMethodResult result) async {
    final payment = result.payment;
    if (payment == null) return false;

    if (payment.isVipps || result.provider == 'vipps') {
      return _collectVippsFee(payment.redirectUrl);
    }

    if (!payment.isStripe || payment.clientSecret == null) {
      if (mounted) openSimpleSnackbar(CampaignStrings.paymentInitFailed);
      return false;
    }

    try {
      if (_pay == AeCheckoutPayMethod.platformWallet) {
        await StripePaymentHelper.confirmPlatformPay(
          clientSecret: payment.clientSecret!,
          orderNo: order.orderNo,
          totalPay: _fee,
          platform: Theme.of(context).platform,
        );
      } else {
        await StripePaymentHelper.presentPaymentSheet(
          clientSecret: payment.clientSecret!,
          orderNo: order.orderNo,
          totalPay: _fee,
          allowsDelayedPaymentMethods: false,
        );
      }
      return true;
    } catch (e) {
      if (mounted && !_isPayCancel(e)) {
        openSimpleSnackbar(CampaignStrings.paymentFailed);
      }
      return false;
    }
  }

  Future<bool> _collectVippsFee(String? url) async {
    if (url == null || url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    savePendingCampaignMethodChangeVipps(order.orderNo);
    final previous = _vippsWait;
    if (previous != null && !previous.isCompleted) previous.complete(false);
    final wait = Completer<bool>();
    _vippsWait = wait;
    try {
      if (!await canLaunchUrl(uri)) return false;
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return wait.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => false,
      );
    } catch (e) {
      if (mounted) openSimpleSnackbar(CampaignStrings.paymentFailed);
      if (!wait.isCompleted) wait.complete(false);
      return false;
    }
  }

  void _finish() {
    CampaignTrackerController.instance.refresh();
    openSimpleSnackbar(CampaignStrings.changeSuccessToast(_targetLabel));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final media = MediaQuery.of(context);
    final window = order.windowInstant;
    final day = campaignDayLabel(window);
    final clock = campaignClockLabel(window);
    final loc = campaignLocationParts(order, pickup: _toPickup);
    final addr = splitSavedAddress(_addressRaw);
    final headline = _toPickup
        ? CampaignStrings.pickupAtName(
            loc.title.isEmpty ? (order.clubName ?? '') : loc.title,
          )
        : (addr.title.isNotEmpty
            ? addr.title
            : CampaignStrings.deliverTo(CampaignStrings.yourAddress));
    final whereSub = _toPickup
        ? loc.subtitle
        : (_hasDeliveryAddress
            ? [
                if (addr.subtitle.isNotEmpty) addr.subtitle,
                if (clock.isNotEmpty) CampaignStrings.withinWindow(clock),
              ].join('\n')
            : languages.dugnadSelectAddress);
    final doneLocation = _toPickup
        ? (loc.title.isEmpty ? (order.clubName ?? '') : loc.title)
        : (_hasDeliveryAddress ? _addressRaw.trim() : loc.title);

    return PopScope(
      canPop: _phase != _ChangePhase.busy,
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                context.dp(18),
                context.dp(12),
                context.dp(18),
                media.padding.bottom + context.dp(22),
              ),
              child: _phase == _ChangePhase.done
                  ? _done(context, theme, doneLocation, clock, day)
                  : _form(
                      context,
                      theme,
                      headline,
                      whereSub,
                      clock,
                      day,
                    ),
            ),
          ),
          if (_phase == _ChangePhase.busy) _busyOverlay(theme),
        ],
      ),
    );
  }

  Widget _form(
    BuildContext context,
    AeThemePalette theme,
    String headline,
    String whereSub,
    String clock,
    String day,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AeSheetHandle(),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: () => Navigator.pop(context, false),
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close, color: theme.ink, size: 18),
          ),
        ),
        Text(
          CampaignStrings.changeSheetTitle(_targetLabel),
          style: aeH3(color: theme.ink).copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: context.dp(6)),
        Text(
          [
            order.campaignName ?? '',
            if (day.isNotEmpty) day,
            if (clock.isNotEmpty) clock,
          ].where((s) => s.isNotEmpty).join(' · '),
          style: aeCaption(),
        ),
        SizedBox(height: context.dp(16)),
        Material(
          color: theme.primaryTint,
          borderRadius: BorderRadius.circular(context.dp(16)),
          child: InkWell(
            onTap: _toDelivery ? _pickAddress : null,
            borderRadius: BorderRadius.circular(context.dp(16)),
            child: Padding(
              padding: EdgeInsets.all(context.dp(14)),
              child: Row(
                children: [
                  Icon(
                    _toPickup
                        ? Icons.storefront_outlined
                        : Icons.local_shipping_outlined,
                    color: theme.primary,
                    size: 17,
                  ),
                  SizedBox(width: context.dp(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headline,
                          style: aeTitle(color: theme.ink).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (whereSub.isNotEmpty) ...[
                          SizedBox(height: context.dp(2)),
                          Text(whereSub, style: aeCaption()),
                        ],
                      ],
                    ),
                  ),
                  if (_toDelivery) ...[
                    SizedBox(width: context.dp(8)),
                    Text(
                      CampaignStrings.change,
                      style: aeLabel(color: theme.primary),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: context.dp(10)),
        Container(
          padding: EdgeInsets.all(context.dp(14)),
          decoration: BoxDecoration(
            color: _fee > 0
                ? ScSaasThemeTokens.warning.withValues(alpha: 0.12)
                : ScSaasThemeTokens.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(context.dp(16)),
          ),
          child: Row(
            children: [
              Icon(
                _fee > 0 ? Icons.account_balance_wallet_outlined : Icons.check_rounded,
                color: _fee > 0
                    ? ScSaasThemeTokens.warning
                    : ScSaasThemeTokens.success,
                size: 15,
              ),
              SizedBox(width: context.dp(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fee > 0
                          ? CampaignStrings.changeFeeLabel
                          : CampaignStrings.changeFreeLabel,
                      style: aeTitle(color: theme.ink).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _fee > 0
                          ? CampaignStrings.changeFeeHint
                          : CampaignStrings.changeFreeHint,
                      style: aeCaption(),
                    ),
                  ],
                ),
              ),
              if (_fee > 0)
                Text(
                  campaignKr(_fee),
                  style: aeTitle(color: theme.ink).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        if (_fee > 0) ...[
          SizedBox(height: context.dp(14)),
          AeCheckoutPaymentSelector(
            value: _pay,
            accent: theme.primary,
            onChanged: (method) => setState(() => _pay = method),
          ),
          SizedBox(height: context.dp(14)),
          CampaignSwipePayBar(
            label: CampaignStrings.swipeToPay,
            amountText: campaignKr(_fee),
            onConfirmed: _commit,
            accent: theme.primary,
            accentHover: theme.primaryHover,
            accentDisabled: theme.primaryDisabled,
            buttonShadow: theme.shadowButton,
          ),
        ] else
          AeSheetPrimaryButton(
            label: CampaignStrings.confirmChange,
            onPressed: _commit,
          ),
        AeSheetCancelButton(
          label: languages.cancel,
          onPressed: () => Navigator.pop(context, false),
        ),
      ],
    );
  }

  Widget _done(
    BuildContext context,
    AeThemePalette theme,
    String location,
    String clock,
    String day,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AeSheetHandle(),
        SizedBox(height: context.dp(12)),
        Center(
          child: Container(
            width: context.dp(56),
            height: context.dp(56),
            decoration: BoxDecoration(
              color: ScSaasThemeTokens.success.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 28,
              color: ScSaasThemeTokens.success,
            ),
          ),
        ),
        SizedBox(height: context.dp(14)),
        Text(
          CampaignStrings.changeDoneTitle(_targetLabel),
          textAlign: TextAlign.center,
          style: aeH3(color: theme.ink).copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: context.dp(6)),
        Text(
          [
            order.campaignName ?? '',
            if (day.isNotEmpty) day,
          ].where((s) => s.isNotEmpty).join(' · '),
          textAlign: TextAlign.center,
          style: aeCaption(),
        ),
        SizedBox(height: context.dp(16)),
        Container(
          padding: EdgeInsets.all(context.dp(14)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.dp(16)),
          ),
          child: Column(
            children: [
              _doneRow(
                _toPickup
                    ? CampaignStrings.rowPickupPlace
                    : CampaignStrings.rowAddress,
                location.isEmpty ? (order.clubName ?? '') : location,
              ),
              if (clock.isNotEmpty) ...[
                SizedBox(height: context.dp(10)),
                _doneRow(CampaignStrings.rowTimeSlot, clock),
              ],
              if (_fee > 0) ...[
                SizedBox(height: context.dp(10)),
                _doneRow(CampaignStrings.paidWith, _payLabel ?? _selectedPayLabel()),
                SizedBox(height: context.dp(10)),
                _doneRow(CampaignStrings.changeFeeLabel, campaignKr(_fee)),
              ] else ...[
                SizedBox(height: context.dp(10)),
                _doneRow(
                  CampaignStrings.changeFeeLabel,
                  CampaignStrings.changeFreeLabel,
                  valueColor: ScSaasThemeTokens.success,
                ),
              ],
            ],
          ),
        ),
        AeSheetPrimaryButton(
          label: languages.done,
          onPressed: _finish,
        ),
      ],
    );
  }

  Widget _doneRow(String label, String value, {Color? valueColor}) {
    final theme = context.aeTheme;
    return Row(
      children: [
        Text(label, style: aeCaption()),
        SizedBox(width: context.dp(12)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: aeTitle(color: valueColor ?? theme.ink).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _busyOverlay(AeThemePalette theme) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.white.withValues(alpha: 0.86),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.primary,
                ),
              ),
              SizedBox(height: context.dp(14)),
              Text(
                _fee > 0
                    ? CampaignStrings.payingOverlay
                    : CampaignStrings.changingOverlay,
                style: aeTitle(color: theme.ink).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: context.dp(4)),
              Text(CampaignStrings.keepAppOpen, style: aeCaption()),
            ],
          ),
        ),
      ),
    );
  }
}
