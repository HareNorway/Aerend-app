import 'package:flutter/material.dart';

import '../../../theme/bergen_tokens.dart';
import '../../../utils/utils.dart';
import '../../bergen/kasse/kasse_copy.dart';
import '../../bergen/kasse/kjop_sekvens.dart';
import '../../bergen/kit/bergen_toast.dart';
import '../../deliveryService/checkout/checkout_repo.dart';
import '../home/bergen/bergen_kit.dart';
import '../homeMainV1/home_main_v1.dart';
import '../login/login_dl.dart';
import '../login/vipps_login_helper.dart';

/// The Vipps return (`aerendapp://payment/vipps?orderId=N`).
///
/// It only asks the backend to confirm the payment and then hands over to the
/// Bergen screens — no result page of its own (the old lavender «Vipps-retur»
/// showed first and the Bergen screens only after it was closed):
///
/// - paid → [KjopBekreftetScreen] («Betalt»), which opens Sporing;
/// - not paid → back to Kassen with the Bergen toast, as a card payment that
///   fails does.
///
/// When the app was started by the return itself (nothing under this route),
/// Hjem is put underneath first, so «tilbake» from Sporing / Kassen lands there.
class VippsPaymentReturnScreen extends StatefulWidget {
  const VippsPaymentReturnScreen({super.key, required this.orderId, this.confirm});

  final int orderId;

  /// Tests: the backend confirm call (`vipps/confirm`).
  final Future<Map<String, dynamic>> Function(int orderId)? confirm;

  @override
  State<VippsPaymentReturnScreen> createState() => _VippsPaymentReturnScreenState();
}

class _VippsPaymentReturnScreenState extends State<VippsPaymentReturnScreen> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _confirm());
  }

  Future<void> _confirm() async {
    Map<String, dynamic>? response;
    try {
      final call = widget.confirm ?? (int id) async => Map<String, dynamic>.from(await CheckoutRepo().confirmVippsViaBackend(id) as Map);
      response = await call(widget.orderId);
    } catch (_) {
      response = null;
    }
    if (!mounted || _done) return;
    _done = true;

    final paid = response?['status'] == 1;
    if (paid) {
      prefSetInt('vipps_pending_order_id', 0);
      prefSetInt(prefCartCount, 0);
    }
    final nav = Navigator.of(context);
    final alone = !nav.canPop();

    if (paid) {
      final bekreftet = MaterialPageRoute<void>(
        builder: (_) => KjopBekreftetScreen(orderId: widget.orderId, fjernUnder: true),
      );
      if (alone) {
        nav.pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const HomeMainV1(homeIndex: 0)), (_) => false);
        nav.push(bekreftet);
      } else {
        nav.pushReplacement(bekreftet);
      }
      return;
    }

    // Not paid: Kassen again (it reloads the basket on resume), with the reason.
    if (alone) {
      nav.pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const HomeMainV1(homeIndex: 1)), (_) => false);
    } else {
      nav.pop();
    }
    final overlayContext = navigatorKey.currentState?.overlay?.context;
    if (overlayContext != null) {
      showBergenToast(overlayContext, KasseCopy.a1_kasse_betaling_avbrutt);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: kBergenScreenGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            key: const Key('vipps-return-pending'),
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(strokeWidth: 3, color: BergenTokens.mint),
              ),
              const SizedBox(height: 16),
              Text(
                KasseCopy.a1_kasse_vipps_bekrefter,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
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
