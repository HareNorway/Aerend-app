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
