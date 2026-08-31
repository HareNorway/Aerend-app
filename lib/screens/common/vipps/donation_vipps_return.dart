import 'package:flutter/material.dart';

import '../../../utils/global_loading_overlay.dart';
import '../../../utils/utils.dart';
import '../../dugnad/donation_confirm_screen.dart';
import '../../dugnad/donation_incomplete_screen.dart';
import '../../dugnad/donation_setup_failed_screen.dart';
import '../../dugnad/dugnad_models.dart';
import '../../dugnad/dugnad_repo.dart';

const String prefDonationPendingSubscriptionId =
    'donation_pending_subscription_id';

bool _donationVippsSyncInFlight = false;

void clearPendingDonationVipps() {
  prefSetInt(prefDonationPendingSubscriptionId, 0);
}

bool isDonationSubscriptionActivated(Map<String, dynamic> response) {
  final status = response['status'];
  if (status != 1 && status != '1') return false;
  if (response['activated'] == true) return true;
  final sub = response['subscription'];
  if (sub is Map) {
    final agreementStatus = sub['status']?.toString().toLowerCase();
    return agreementStatus == 'active';
  }
  return false;
}

Future<Map<String, dynamic>?> syncDonationSubscriptionWithRetry(
  int subscriptionId, {
  int retries = 4,
}) async {
  final repo = DugnadRepo();
  Map<String, dynamic>? lastResponse;

  for (var attempt = 0; attempt <= retries; attempt++) {
    if (attempt > 0) {
      await Future.delayed(const Duration(seconds: 2));
    }

    final response = await repo.syncDonationSubscription(subscriptionId);
    if (response == null) continue;

    final status = response['status'];
    if (status != 1 && status != '1') continue;

    lastResponse = response;

    if (isDonationSubscriptionActivated(response)) {
      return response;
    }

    final sub = response['subscription'];
    if (sub is Map) {
      final record = DonationSubscriptionRecord.fromJson(
        Map<String, dynamic>.from(sub),
      );
      if (record.status == 'cancelled' || record.status == 'failed') {
        return response;
      }
    }
  }

  return lastResponse;
}

void _pushDonationOutcome({
  required int subscriptionId,
  required Map<String, dynamic> response,
}) {
  final nav = navigatorKey.currentState;
  if (nav == null) return;

  final sub = response['subscription'];
  if (sub is! Map) return;

  final record = DonationSubscriptionRecord.fromJson(
    Map<String, dynamic>.from(sub),
  );
  final activated = isDonationSubscriptionActivated(response);
  final incomplete = response['incomplete'] == true;
  final confirmationUrl = response['confirmation_url']?.toString();

  if (activated) {
    clearPendingDonationVipps();
    nav.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => DonationConfirmScreen(
          subscription: record,
          activated: true,
        ),
      ),
      (route) => route.isFirst,
    );
    return;
  }

  if (record.status == 'cancelled' || record.status == 'failed') {
    clearPendingDonationVipps();
    nav.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => DonationSetupFailedScreen(
          subscriptionId: subscriptionId,
        ),
      ),
      (route) => route.isFirst,
    );
    return;
  }

  if (incomplete || record.isPending) {
    nav.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => DonationIncompleteScreen(
          subscriptionId: subscriptionId,
          confirmationUrl: confirmationUrl,
        ),
      ),
      (route) => route.isFirst,
    );
  }
}

/// Syncs donation after Vipps return and navigates to the right screen.
/// Returns true when navigation was handled (success, incomplete, or failed).
Future<bool> completeDonationVippsSync(
  int subscriptionId, {
  int retries = 4,
}) async {
  if (subscriptionId <= 0 || !isLoggedIn()) return false;

  return withGlobalLoadingOverlay(() async {
    final response = await syncDonationSubscriptionWithRetry(
      subscriptionId,
      retries: retries,
    );
    if (response == null) return false;

    final sub = response['subscription'];
    if (sub is! Map) return false;

    _pushDonationOutcome(
      subscriptionId: subscriptionId,
      response: response,
    );
    return true;
  }, message: languages.dugnadDonationSyncing);
}

/// Called when the app returns from Vipps without a deep-link route.
Future<void> resumePendingDonationVippsIfNeeded() async {
  if (_donationVippsSyncInFlight) return;

  final subscriptionId = prefGetInt(prefDonationPendingSubscriptionId);
  if (subscriptionId <= 0 || !isLoggedIn()) return;

  _donationVippsSyncInFlight = true;
  try {
    await completeDonationVippsSync(subscriptionId);
  } finally {
    _donationVippsSyncInFlight = false;
  }
}
