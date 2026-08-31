import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

/// Extracted from checkout_bloc.dart _stripePaymentProcess.
/// Reusable for both store-checkout and campaign-checkout Stripe flows.
class StripePaymentHelper {
  /// Initialise and present the Stripe PaymentSheet.
  ///
  /// [clientSecret] — PaymentIntent client_secret from the backend.
  /// [orderNo] — order reference shown on Apple/Google Pay sheet.
  /// [totalPay] — total amount (for Apple/Google Pay display).
  /// [ephemeralKey] / [customerId] — optional, omit for guest checkouts.
  ///
  /// Throws on user cancellation or payment failure.
  static Future<void> presentPaymentSheet({
    required String clientSecret,
    required String orderNo,
    required double totalPay,
    String? ephemeralKey,
    String? customerId,
    VoidCallback? onReadyToPresent,
    bool allowsDelayedPaymentMethods = true,
  }) async {
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        customFlow: false,
        allowsDelayedPaymentMethods: allowsDelayedPaymentMethods,
        returnURL: 'aerend://stripe-redirect',
        merchantDisplayName: 'Ærend',
        paymentIntentClientSecret: clientSecret,
        customerEphemeralKeySecret: ephemeralKey,
        customerId: customerId,
        applePay: PaymentSheetApplePay(
          merchantCountryCode: 'NO',
          cartItems: [
            ApplePayCartSummaryItem.immediate(
              label: orderNo,
              amount: '$totalPay',
              isPending: false,
            ),
          ],
        ),
        googlePay: const PaymentSheetGooglePay(
          merchantCountryCode: 'NO',
          testEnv: false,
        ),
        style: ThemeMode.light,
      ),
    );

    onReadyToPresent?.call();
    await Stripe.instance.presentPaymentSheet();
  }

  /// Confirm PaymentIntent directly with platform wallet.
  /// Uses Google Pay on Android and Apple Pay on iOS.
  static Future<void> confirmPlatformPay({
    required String clientSecret,
    required String orderNo,
    required double totalPay,
    required TargetPlatform platform,
  }) async {
    if (platform == TargetPlatform.android) {
      await Stripe.instance.confirmPlatformPayPaymentIntent(
        clientSecret: clientSecret,
        confirmParams: const PlatformPayConfirmParams.googlePay(
          googlePay: GooglePayParams(
            merchantName: 'Ærend',
            allowCreditCards: true,
            isEmailRequired: false,
            testEnv: false,
            currencyCode: 'nok',
            merchantCountryCode: 'no',
          ),
        ),
      );
      return;
    }

    if (platform == TargetPlatform.iOS) {
      await Stripe.instance.confirmPlatformPayPaymentIntent(
        clientSecret: clientSecret,
        confirmParams: PlatformPayConfirmParams.applePay(
          applePay: ApplePayParams(
            merchantCountryCode: 'no',
            currencyCode: 'nok',
            cartItems: [
              ApplePayCartSummaryItem.immediate(
                label: orderNo,
                amount: '$totalPay',
                isPending: true,
              ),
            ],
          ),
        ),
      );
      return;
    }

    throw UnsupportedError('Platform wallet is not supported on this platform');
  }
}
