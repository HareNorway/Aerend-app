import 'package:flutter/material.dart';

import '../../bergen/kasse/kjop_sekvens.dart';

import '../../../theme/bergen_tokens.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_subpage_shell.dart';
import '../account/settings_design_kit.dart';
import '../../deliveryService/checkout/checkout_repo.dart';
import '../login/login_dl.dart';
import '../login/vipps_login_helper.dart';

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
      final response = await CheckoutRepo().confirmVippsViaBackend(
        widget.orderId,
      );
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

  /// Success routing: the Bergen purchase sequence (AGIL-1 v2 Phase 5) —
  /// Bekreftet, then the Sporing route — and clears the stack.
  void _openTracking() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => KjopBekreftetScreen(orderId: widget.orderId),
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
      backgroundColor: AerendBergenAuthTokens.navy,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AerendBergenAuthTokens.screenGradient,
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: AerendBergenAuthTokens.orange,
          ),
        ),
      ),
    );
  }
}
