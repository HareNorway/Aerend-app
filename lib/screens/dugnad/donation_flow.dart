import 'package:flutter/material.dart';

import '../../utils/utils.dart';
import 'donation_manage_screen.dart';
import 'donation_setup_screen.dart';
import 'dugnad_repo.dart';

/// Opens fixed-support setup, or the manage screen when the user already has
/// an active (or paused) subscription.
Future<void> openDonationFlow(BuildContext context) async {
  try {
    final subs = await DugnadRepo().listDonationSubscriptions();
    final hasMembership = subs.any((s) => s.isManageable);
    if (!context.mounted) return;
    openScreen(
      context,
      hasMembership ? const DonationManageScreen() : const DonationSetupScreen(),
    );
  } catch (_) {
    if (!context.mounted) return;
    openScreen(context, const DonationSetupScreen());
  }
}
