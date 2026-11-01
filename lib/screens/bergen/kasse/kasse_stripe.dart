import 'dart:io' show Platform;

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../constant/constant.dart' show appUrlScheme;
import 'kasse_sheets.dart';
import '../../../utils/stripe_server_key.dart';

/// The API's `payment_type` for a method picked in Betaling: 1 card (the
/// Stripe payment sheet), 2 Google / Apple Pay (Stripe platform pay), 3 Vipps.
/// The sheet's own ids (kBet*) are display ids, not API values.
int kasseApiPaymentType(int method) => switch (method) {
  kBetVipps => 3,
  kBetApple || kBetGoogle => 2,
  _ => 1,
};

/// Pays an order's Stripe payment intent — the legacy checkout's
/// `_stripePaymentProcess`, without its bloc. Throws a [StripeException]
/// when the customer closes the sheet; the order then stays unpaid.
Future<void> kasseStripePay({
  required int apiPaymentType,
  required Map<String, dynamic> intent,
  required String orderNo,
  required double total,
}) async {
  final secret = '${intent['paymentIntent'] ?? ''}';
  if (secret.isEmpty) throw StateError('Missing payment intent');
  await useServerStripeKey(intent);

  if (apiPaymentType == 2) {
    if (Platform.isIOS) {
      await Stripe.instance.confirmPlatformPayPaymentIntent(
        clientSecret: secret,
        confirmParams: PlatformPayConfirmParams.applePay(
          applePay: ApplePayParams(
            merchantCountryCode: 'no',
            currencyCode: 'nok',
            cartItems: [
              ApplePayCartSummaryItem.immediate(label: 'Ærend $orderNo', amount: total.toStringAsFixed(2)),
            ],
          ),
        ),
      );
    } else {
      await Stripe.instance.confirmPlatformPayPaymentIntent(
        clientSecret: secret,
        confirmParams: PlatformPayConfirmParams.googlePay(
          googlePay: GooglePayParams(
            merchantName: 'Ærend',
            allowCreditCards: true,
            isEmailRequired: false,
            testEnv: stripeTestMode,
            currencyCode: 'nok',
            merchantCountryCode: 'no',
          ),
        ),
      );
    }
    return;
  }

  await Stripe.instance.initPaymentSheet(
    paymentSheetParameters: SetupPaymentSheetParameters(
      customFlow: false,
      allowsDelayedPaymentMethods: true,
      returnURL: '$appUrlScheme://stripe-redirect',
      merchantDisplayName: 'Ærend',
      paymentIntentClientSecret: secret,
      customerEphemeralKeySecret: intent['ephemeralKey']?.toString(),
      customerId: intent['customerId']?.toString(),
      style: ThemeMode.light,
    ),
  );
  await Stripe.instance.presentPaymentSheet();
}

/// Customer v2 Step 4: Stripe's sheet in setup mode — adds a card to the customer (Meg → Betaling); the number never
/// touches our server. Throws a [StripeException] when the customer closes the sheet.
Future<void> kasseStripeSetupCard(Map<String, dynamic> setup) async {
  final secret = '${setup['setup_intent'] ?? ''}';
  if (secret.isEmpty) throw StateError('Missing setup intent');
  await useServerStripeKey({'publishableKey': setup['publishable_key']});
  await Stripe.instance.initPaymentSheet(
    paymentSheetParameters: SetupPaymentSheetParameters(
      customFlow: false,
      returnURL: '$appUrlScheme://stripe-redirect',
      merchantDisplayName: 'Ærend',
      setupIntentClientSecret: secret,
      customerEphemeralKeySecret: setup['ephemeral_key']?.toString(),
      customerId: setup['customer_id']?.toString(),
      style: ThemeMode.light,
    ),
  );
  await Stripe.instance.presentPaymentSheet();
}

/// Customer v2 Step 4: the bank wants 3-D Secure on a saved-card charge the server confirmed — Stripe's own step, then
/// the server is asked (`pay`). Throws when the customer abandons it.
Future<void> kasseStripeNextAction(String clientSecret) async {
  await Stripe.instance.handleNextAction(clientSecret);
}
