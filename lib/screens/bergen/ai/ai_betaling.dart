// ignore_for_file: non_constant_identifier_names
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../networking/ops/cus_api.dart';
import '../../../networking/ops/ops_kasse_api.dart';
import '../../../services/customer/client_flags.dart';
import '../kasse/kasse_stripe.dart';
import '../kit/bergen_kit.dart';
import 'ai_copy.dart';
import 'ai_overlays.dart';
import 'ai_store.dart';

/// Customer plan Step 14 — «Bekreft og betal» (Commerce stage 1, D-K16): the
/// device check (O-4, `cus.ai.device_auth`) or the «Åpner Vipps …» overlay,
/// the app's own confirmation of the request (`POST customer/ai/requests/{id}/confirm`
/// — the order carries the assistant), then the existing payment: Vipps
/// through the app's redirect (never completed locally; the callback
/// simulates), card through the Stripe sheet on the intent the booking path
/// created. Then «Bestilt via {AI} · {kode}» and Sporing.
abstract final class AiBetaling {
  static CusApi get _api => AiStore.instance.api;

  /// True when the order was created (paid or waiting for Vipps). [feil] is the backend's code on a refusal.
  static Future<({bool ok, String? feil, CusAiOrder? order})> betal(BuildContext context, CusAiRequest r, {String payment = 'vipps', bool harness = false}) async {
    final vipps = payment == 'vipps';
    // The device check before the in-app payment step (O-4), behind `cus.ai.device_auth`; Vipps authenticates itself.
    if (!vipps && !harness && ClientFlags.on(ClientFlags.aiDeviceAuth)) {
      final ok = await AiOverlays.face<bool>(context, vipps: false, sum: r.total.display, under: AiCopy.cus_ai_betaling_med(AiCopy.cus_ai_lagret_kort), until: _enhet());
      if (!context.mounted) return (ok: false, feil: null, order: null);
      if (!ok) {
        showBergenToast(context, AiCopy.cus_ai_enhet_avvist, icon: Icons.error_outline_rounded);
        return (ok: false, feil: 'device', order: null);
      }
    }
    if (harness) {
      await AiOverlays.face<void>(context, vipps: vipps, sum: r.total.display, under: vipps ? AiCopy.cus_ai_tilbake_etterpaa : AiCopy.cus_ai_betaling_med(AiCopy.cus_ai_lagret_kort), until: Future<void>.delayed(const Duration(milliseconds: 1700)));
      return (ok: false, feil: null, order: null);
    }
    final res = await AiOverlays.face(context, vipps: vipps, sum: r.total.display, under: vipps ? AiCopy.cus_ai_tilbake_etterpaa : AiCopy.cus_ai_betaling_med(AiCopy.cus_ai_lagret_kort), until: _api.aiRequestConfirm(r.id, payment: payment));
    if (!context.mounted) return (ok: false, feil: res.feil, order: res.order);
    final order = res.order;
    if (order == null) {
      return (ok: false, feil: res.feil ?? 'failed', order: null);
    }
    unawaited(AiStore.instance.load(force: true));
    if (vipps) {
      try {
        final url = await OpsKasseApi().vippsRedirect(order.id);
        if (!context.mounted) return (ok: true, feil: null, order: order);
        if (url != null) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      } catch (_) {
        // Vipps could not be opened here; the order waits unpaid and Sporing says so.
      }
    } else if (order.paymentIntent != null && order.paymentStatus != 'paid') {
      try {
        await kasseStripePay(apiPaymentType: 2, intent: {'paymentIntent': order.paymentIntent}, orderNo: order.number, total: order.total.ore / 100);
      } catch (_) {
        if (context.mounted) showBergenToast(context, AiCopy.cus_ai_bet_feilet, icon: Icons.error_outline_rounded);
        return (ok: true, feil: 'payment', order: order);
      }
    }
    if (context.mounted) {
      showBergenToast(context, AiCopy.cus_ai_bestilt_via(r.assistant, order.number), icon: Icons.check_rounded);
      BergenRoutes.push<void>(context, '/bergen/sporing/${order.id}');
    }
    return (ok: true, feil: null, order: order);
  }

  static Future<bool> _enhet() async {
    if (kIsWeb) return true;
    try {
      final auth = LocalAuthentication();
      if (!await auth.isDeviceSupported()) return true;
      return await auth.authenticate(localizedReason: 'Bekreft bestillingen fra assistenten din', options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true));
    } catch (_) {
      // No biometrics and no passcode on this device: the payment step itself authenticates (Vipps / 3-D Secure).
      return true;
    }
  }
}
