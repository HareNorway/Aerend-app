import 'package:flutter_stripe/flutter_stripe.dart';

/// The Stripe publishable key that belongs to a PaymentIntent (deployment plan A7).
///
/// The backend returns `publishableKey` with every PaymentIntent (`paymentIntent`,
/// `ephemeralKey`, `customerId`, `publishableKey`). A live intent needs the live key and a test
/// intent the test key, so the app takes the server's key instead of trusting the one it was
/// built with (`stripePublishableKey`, kept as the start-up fallback in main.dart).
Future<void> useServerStripeKey(dynamic intent) async {
  final key = intent is Map ? '${intent['publishableKey'] ?? ''}'.trim() : '';
  if (key.isEmpty || Stripe.publishableKey == key) return;
  Stripe.publishableKey = key;
  await Stripe.instance.applySettings();
}

/// Google Pay's test environment only with a Stripe test key, so a live build never pays in
/// test mode and a test build never charges a real card.
bool get stripeTestMode => Stripe.publishableKey.startsWith('pk_test_');
