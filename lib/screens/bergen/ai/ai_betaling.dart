// ignore_for_file: non_constant_identifier_names
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../networking/ops/cus_api.dart';
import '../../../services/customer/client_flags.dart';
import '../kasse/kasse_stripe.dart';
import '../kit/bergen_kit.dart';
import 'ai_copy.dart';
import 'ai_overlays.dart';
import 'ai_store.dart';
import '../../../services/customer/beacons.dart';

/// Customer plan Step 14 — «Bekreft og betal» (Commerce stage 1, D-K16): the
/// device check (O-4, `cus.ai.device_auth`) or the «Åpner Vipps …» overlay,
/// then the app's own confirmation of the request.
///
/// Customer v2 Step 3 (D2-5): the confirmation starts the payment and no order
/// exists yet. Vipps: the app switches to Vipps and the request waits
/// (`betaler`) until the app is back — the return link or the next resume asks
/// [sjekk]. Card: the Stripe sheet on the request's own intent, then [sjekk]
/// at once. The order is placed by the server when the provider says paid;
/// then «Bestilt via {AI} · {kode}» and Sporing.
abstract final class AiBetaling {
  static CusApi get _api => AiStore.instance.api;

  /// Customer v2 Step 4: Stripe's 3-D Secure step on a saved-card charge (tests swap it).
  @visibleForTesting
  static Future<void> Function(String clientSecret) nextAction = kasseStripeNextAction;

  /// The device check (O-4); tests swap it — the platform channel never answers under flutter_test.
  @visibleForTesting
  static Future<bool> Function() deviceCheck = _enhet;

  /// [feil]: `venter` (Vipps is open; ask [sjekk] on the way back), `payment` (the sheet was closed),
  /// `failed` (the provider said no), or the backend's code on a refusal (`confirmation_required`, `quote_expired` …).
  static Future<({bool ok, String? feil, CusAiOrder? order})> betal(BuildContext context, CusAiRequest r, {String payment = 'vipps', bool harness = false, bool overOk = false}) async {
    final vipps = payment == 'vipps';
    // Customer v2 Step 4 (stage 2): «kort» with a saved card behind `cus.ai.linked_checkout` is the saved card — the
    // server charges it after the confirmation; without one the sheet opens as before.
    CusSavedCard? kort;
    if (!vipps && !harness && ClientFlags.on(ClientFlags.aiLinkedCheckout)) {
      final cards = await _api.savedCards();
      kort = cards?.where((c) => c.isDefault).firstOrNull ?? (cards != null && cards.length == 1 ? cards.first : null);
      if (!context.mounted) return (ok: false, feil: null, order: null);
    }
    final lagret = kort != null;
    final metode = lagret ? 'saved_card' : payment;
    final under = lagret ? AiCopy.cus_ai_betaling_med(kort.navn) : AiCopy.cus_ai_betaling_med(AiCopy.cus_ai_lagret_kort);
    // The device check before the in-app payment step (O-4), behind `cus.ai.device_auth`; a saved card always asks (stage 2).
    if (!vipps && !harness && (lagret || ClientFlags.on(ClientFlags.aiDeviceAuth))) {
      final ok = await AiOverlays.face<bool>(context, vipps: false, sum: r.total.display, under: under, until: deviceCheck());
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
    final res = await AiOverlays.face(context, vipps: vipps, sum: r.total.display, under: vipps ? AiCopy.cus_ai_tilbake_etterpaa : under, until: _api.aiRequestConfirm(r.id, payment: metode, overLimitOk: overOk, paymentMethod: kort?.id));
    if (!context.mounted) return (ok: false, feil: res.feil, order: null);
    final b = res.betaling;
    if (b == null) return (ok: false, feil: res.feil ?? 'failed', order: null);
    unawaited(AiStore.instance.load(force: true));
    if (vipps) {
      try {
        final url = b.redirectUrl;
        if (url != null) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {
        // Vipps could not be opened here; the request waits (`betaler`) and «Sjekk betalingen» stays.
        CusBeacons.melde('payment_failed', code: 'vipps_open', screen: 'ai_kurv');
      }
      return (ok: false, feil: 'venter', order: null);
    }
    if (lagret) {
      // The server confirmed the charge; the bank may still want 3-D Secure — Stripe's step, then the server decides.
      if (b.requiresAction && b.clientSecret != null) {
        try {
          await nextAction(b.clientSecret!);
        } catch (_) {
          CusBeacons.melde('payment_failed', code: 'stripe_3ds', screen: 'ai_kurv');
          if (context.mounted) showBergenToast(context, AiCopy.cus_ai_bet_feilet, icon: Icons.error_outline_rounded);
          return (ok: false, feil: 'payment', order: null);
        }
      }
      if (!context.mounted) return (ok: false, feil: 'venter', order: null);
      return sjekk(context, r, paymentResultRef: b.reference);
    }
    final sheet = b.sheet;
    if (sheet == null) return (ok: false, feil: 'failed', order: null);
    try {
      await kasseStripePay(apiPaymentType: 1, intent: sheet, orderNo: '', total: r.total.ore / 100);
    } catch (_) {
      CusBeacons.melde('payment_failed', code: 'stripe_sheet', screen: 'ai_kurv');
      if (context.mounted) showBergenToast(context, AiCopy.cus_ai_bet_feilet, icon: Icons.error_outline_rounded);
      return (ok: false, feil: 'payment', order: null);
    }
    if (!context.mounted) return (ok: false, feil: 'venter', order: null);
    return sjekk(context, r);
  }

  /// Asks the server whether the payment is in ([forsok] times, a second apart — a card can take a moment):
  /// paid → the order exists, «Bestilt via» and Sporing; `failed` → nothing ordered; otherwise still `venter`.
  static Future<({bool ok, String? feil, CusAiOrder? order})> sjekk(BuildContext context, CusAiRequest r, {int forsok = 3, String? paymentResultRef}) async {
    for (var i = 0; i < forsok; i++) {
      final p = await _api.aiRequestPay(r.id, paymentResultRef: paymentResultRef);
      if (!context.mounted) return (ok: false, feil: 'venter', order: null);
      final order = p.order;
      if (p.resultat == 'confirmed' && order != null) {
        unawaited(AiStore.instance.load(force: true));
        showBergenToast(context, AiCopy.cus_ai_bestilt_via(r.assistant, order.number), icon: Icons.check_rounded);
        BergenRoutes.push<void>(context, '/bergen/sporing/${order.id}');
        return (ok: true, feil: null, order: order);
      }
      if (p.resultat == 'failed') return (ok: false, feil: 'failed', order: null);
      if (i < forsok - 1) await Future<void>.delayed(const Duration(seconds: 1));
    }

    return (ok: false, feil: 'venter', order: null);
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
