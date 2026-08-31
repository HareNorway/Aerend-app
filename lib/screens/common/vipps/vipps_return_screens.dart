import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../main.dart';
import '../../../theme/reen_pre_club_theme.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/global_loading_overlay.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_subpage_shell.dart';
import '../account/settings_design_kit.dart';
import '../../campaign/campaign_order_success_screen.dart';
import '../../campaign/campaign_repo.dart';
import '../../campaign/campaign_strings.dart';
import '../../campaign/campaign_tracker_controller.dart';
import '../../dugnad/referral_capture_helper.dart';
import '../../dugnad/dugnad_state.dart';
import '../../deliveryService/checkout/checkout_repo.dart';
import '../../deliveryService/trackOrder/track_order.dart';
import '../login/login_dl.dart';
import '../login/vipps_login_helper.dart';

const String prefVippsPendingCampaignOrderNo = 'vipps_pending_campaign_order_no';
const String prefVippsPendingCampaignMeta = 'vipps_pending_campaign_meta';
const String prefVippsPendingMethodChangeOrderNo =
    'vipps_pending_method_change_order_no';

bool _campaignVippsConfirmInFlight = false;

void savePendingCampaignVippsCheckout({
  required String orderNo,
  String? distributionDate,
  int? clubShareAmount,
  String? clubName,
  String? clubLogo,
  String? teamName,
  String? teamLogo,
  String? email,
  double? totalPayNok,
  int? boxCount,
  List<CampaignOrderSuccessLineItem> lineItems = const [],
}) {
  prefSetString(prefVippsPendingCampaignOrderNo, orderNo);
  prefSetString(
    prefVippsPendingCampaignMeta,
    jsonEncode({
      'started_at': DateTime.now().millisecondsSinceEpoch,
      'distribution_date': distributionDate,
      'club_share_amount': clubShareAmount,
      'club_name': clubName,
      'club_logo': clubLogo,
      'team_name': teamName,
      'team_logo': teamLogo,
      'email': email,
      'total_pay_nok': totalPayNok,
      'box_count': boxCount,
      'line_items': lineItems.map((e) => e.toJson()).toList(),
    }),
  );
}

void clearPendingCampaignVippsCheckout() {
  prefSetString(prefVippsPendingCampaignOrderNo, '');
  prefSetString(prefVippsPendingCampaignMeta, '');
}

void savePendingCampaignMethodChangeVipps(String orderNo) {
  prefSetString(prefVippsPendingMethodChangeOrderNo, orderNo.trim());
}

void clearPendingCampaignMethodChangeVipps() {
  prefSetString(prefVippsPendingMethodChangeOrderNo, '');
}

bool hasPendingCampaignMethodChangeVipps() {
  return prefGetString(prefVippsPendingMethodChangeOrderNo).trim().isNotEmpty;
}

Map<String, dynamic> readPendingCampaignVippsMeta() {
  try {
    final raw = prefGetString(prefVippsPendingCampaignMeta).trim();
    if (raw.isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
  } catch (_) {}
  return {};
}

bool isCampaignPaymentConfirmed(dynamic response) {
  if (response is! Map) return false;
  final status = response['status'];
  if (status != 1 && status != '1') return false;
  final paid = response['paid'];
  if (paid == true || paid == 1 || paid == '1') return true;
  final paymentStatus = response['payment_status'];
  return paymentStatus == 1 || paymentStatus == '1';
}

Future<bool> completeCampaignVippsPayment(
  String orderNo, {
  int retries = 2,
}) async {
  final trimmed = orderNo.trim();
  if (trimmed.isEmpty || !isLoggedIn()) return false;

  return withGlobalLoadingOverlay(() async {
    final meta = readPendingCampaignVippsMeta();

    for (var attempt = 0; attempt <= retries; attempt++) {
      if (attempt > 0) {
        await Future.delayed(const Duration(seconds: 2));
      }
      final body = Map<String, dynamic>.from(
        await CampaignRepo().confirmPayment(trimmed),
      );
      if (isCampaignPaymentConfirmed(body)) {
        clearPendingCampaignVippsCheckout();
        await capturePendingDugnadReferralIfNeeded();
        await DugnadState.instance.syncPointsTeamFromServer();

        final nav = navigatorKey.currentState;
        if (nav == null) return true;

        nav.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => CampaignOrderSuccessScreen(
              orderNo: trimmed,
              distributionDate: meta['distribution_date'] as String?,
              clubShareAmount: (meta['club_share_amount'] as num?)?.toInt(),
              clubName: meta['club_name'] as String?,
              clubLogo: meta['club_logo'] as String?,
              teamName: meta['team_name'] as String?,
              teamLogo: meta['team_logo'] as String?,
              pointsEarned: (body['points_earned'] as num?)?.toInt(),
              pointsTeamName: body['points_team_name'] as String?,
              email: meta['email'] as String?,
              totalPayNok: (meta['total_pay_nok'] as num?)?.toDouble(),
              boxCount: (meta['box_count'] as num?)?.toInt(),
              lineItems: campaignOrderLineItemsFromMeta(meta),
            ),
          ),
          (route) => route.isFirst,
        );
        return true;
      }
    }

    return false;
  }, message: CampaignStrings.processing);
}

Future<bool> completeCampaignMethodChangePayment(
  String orderNo, {
  String targetMethod = '',
  int retries = 4,
}) async {
  final trimmed = orderNo.trim();
  if (trimmed.isEmpty || !isLoggedIn()) return false;

  for (var attempt = 0; attempt <= retries; attempt++) {
    if (attempt > 0) {
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    try {
      final response = await CampaignRepo().confirmPayment(trimmed);
      if (isMethodChangeFeeSettled(response, targetMethod: targetMethod)) {
        clearPendingCampaignMethodChangeVipps();
        await CampaignTrackerController.instance.refresh();
        return true;
      }
    } catch (_) {}
  }
  return false;
}

/// Called when the app returns from Vipps without a deep-link route (common on Android).
Future<void> resumePendingCampaignVippsPaymentIfNeeded() async {
  if (_campaignVippsConfirmInFlight) return;

  if (hasPendingCampaignMethodChangeVipps()) {
    // The change sheet owns this confirm. Do not treat it as a new campaign order.
    return;
  }

  final orderNo = prefGetString(prefVippsPendingCampaignOrderNo).trim();
  if (orderNo.isEmpty || !isLoggedIn()) return;

  final meta = readPendingCampaignVippsMeta();
  final startedAt = meta['started_at'] as num?;
  if (startedAt != null) {
    final ageMs = DateTime.now().millisecondsSinceEpoch - startedAt.toInt();
    if (ageMs > const Duration(minutes: 45).inMilliseconds) {
      clearPendingCampaignVippsCheckout();
      return;
    }
  }

  _campaignVippsConfirmInFlight = true;
  try {
    await completeCampaignVippsPayment(orderNo);
  } finally {
    _campaignVippsConfirmInFlight = false;
  }
}

class VippsPaymentReturnScreen extends StatefulWidget {
  const VippsPaymentReturnScreen({super.key, required this.orderId});

  final int orderId;

  @override
  State<VippsPaymentReturnScreen> createState() =>
      _VippsPaymentReturnScreenState();
}

enum _VippsReturnState { pending, ok, bad }

/// «Vipps-retur» — mirrors design `settings-screens.jsx` `VippsReturnScreen`
/// (`.dgv-burst` + 25/800 h1 + 15px gray body + primary CTA + `.dga-cancel`).
class _VippsPaymentReturnScreenState extends State<VippsPaymentReturnScreen> {
  _VippsReturnState _state = _VippsReturnState.pending;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _confirm());
  }

  Future<void> _confirm() async {
    if (mounted) setState(() => _state = _VippsReturnState.pending);
    try {
      final response =
          await CheckoutRepo().confirmVippsViaBackend(widget.orderId);
      if (!mounted) return;

      if (response['status'] == 1) {
        prefSetInt('vipps_pending_order_id', 0);
        prefSetInt(prefCartCount, 0);
        setState(() => _state = _VippsReturnState.ok);
        return;
      }

      openSimpleSnackbar(
        response['message']?.toString() ?? 'Payment not completed',
      );
      setState(() => _state = _VippsReturnState.bad);
    } catch (e) {
      if (!mounted) return;
      openSimpleSnackbar(e.toString());
      setState(() => _state = _VippsReturnState.bad);
    }
  }

  /// Unchanged success routing — pushes TrackOrder and clears the stack.
  void _openTracking() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => TrackOrder(orderId: widget.orderId),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_state == _VippsReturnState.pending) {
      return const Scaffold(
        backgroundColor: kDgPageBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final ok = _state == _VippsReturnState.ok;

    return Scaffold(
      backgroundColor: kDgPageBackground,
      body: AeFixedTypography(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              // .ae-body { padding: 0 26px 30px; gap: 14 }
              padding: const EdgeInsets.fromLTRB(26, 0, 26, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: DgvBurst(ok: ok)),
                  const SizedBox(height: 14),
                  Text(
                    ok
                        ? 'Betalingen er godkjent' // TODO(l10n)
                        : 'Betalingen ble avbrutt', // TODO(l10n)
                    textAlign: TextAlign.center,
                    style: dgText(25, FontWeight.w800, letterSpacingEm: -0.02),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: Text(
                        ok
                            // TODO(l10n)
                            ? 'Vipps bekreftet betalingen. Butikken har fått '
                                'bestillingen din. 💜'
                            // TODO(l10n)
                            : 'Ingen penger er trukket. Du kan prøve igjen, '
                                'eller velge en annen betalingsmåte.',
                        textAlign: TextAlign.center,
                        style: dgText(
                          15,
                          FontWeight.w500,
                          height: 1.5,
                          color: ScSaasThemeTokens.gray500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26), // 14 gap + marginTop 12
                  DgPrimaryButton(
                    label: ok
                        ? 'Følg bestillingen' // TODO(l10n)
                        : languages.tryAgain,
                    onPressed: ok ? _openTracking : _confirm,
                  ),
                  if (!ok)
                    DgCancelButton(
                      label: 'Tilbake til kassen', // TODO(l10n)
                      onTap: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CampaignVippsReturnScreen extends StatefulWidget {
  const CampaignVippsReturnScreen({
    super.key,
    required this.orderNo,
    this.purpose,
  });

  final String orderNo;
  final String? purpose;

  @override
  State<CampaignVippsReturnScreen> createState() =>
      _CampaignVippsReturnScreenState();
}

class _CampaignVippsReturnScreenState extends State<CampaignVippsReturnScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _confirm());
  }

  bool get _isMethodChange =>
      widget.purpose == 'method_change' || hasPendingCampaignMethodChangeVipps();

  Future<void> _confirm() async {
    final orderNo = widget.orderNo.trim().isNotEmpty
        ? widget.orderNo.trim()
        : (hasPendingCampaignMethodChangeVipps()
            ? prefGetString(prefVippsPendingMethodChangeOrderNo)
            : prefGetString(prefVippsPendingCampaignOrderNo));

    try {
      if (_isMethodChange) {
        final ok = await completeCampaignMethodChangePayment(orderNo);
        if (!mounted) return;
        if (!ok) openSimpleSnackbar(CampaignStrings.paymentFailed);
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        return;
      }

      final ok = await completeCampaignVippsPayment(orderNo);
      if (!mounted) return;
      if (ok) return;

      openSimpleSnackbar(CampaignStrings.paymentFailed);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      openSimpleSnackbar(e.toString());
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.shrink(),
    );
  }
}

class VippsLoginReturnScreen extends StatefulWidget {
  const VippsLoginReturnScreen({
    super.key,
    required this.code,
    required this.state,
  });

  final String code;
  final String state;

  @override
  State<VippsLoginReturnScreen> createState() => _VippsLoginReturnScreenState();
}

class _VippsLoginReturnScreenState extends State<VippsLoginReturnScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _complete());
  }

  Future<void> _complete() async {
    if (_started) return;
    _started = true;
    await VippsLoginHelper.completeFromCallback(
      context,
      code: widget.code,
      state: widget.state,
      onSuccess: (LoginPojo response) async {
        if (!mounted) return;
        await manageLoginResponse(context, response);
      },
      onError: (message) {
        if (!mounted) return;
        // Duplicate Vipps callbacks must not pop a successful OTP/home stack.
        openSimpleSnackbar(message);
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Handoff beat between Vipps and the next screen — still an auth surface,
    // so it wears Reen navy + coral, not the app theme's purple spinner.
    return const Scaffold(
      backgroundColor: ReenPreClubTokens.navy,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: ReenPreClubTokens.screenGradient),
        child: Center(
          child: CircularProgressIndicator(color: ReenPreClubTokens.coral),
        ),
      ),
    );
  }
}
