import 'package:flutter/material.dart';

import '../dugnad_club_branding.dart';
import '../dugnad_state.dart';
import '../dugnad_referral_state.dart';
import 'referral_invite_card.dart';

/// `.reg-invite` — shown under the "Via vervelenke" tab of `.reg-demo` when a
/// referral link is actually pending. Renders nothing otherwise.
class ReferralCaptureBanner extends StatelessWidget {
  const ReferralCaptureBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final pending = DugnadReferralState.instance.pending;
    if (pending == null || pending.referrerDisplayName == null) {
      return const SizedBox.shrink();
    }

    final clubName = pending.organizationName?.trim().isNotEmpty == true
        ? pending.organizationName!.trim()
        : DugnadClubBranding.compactName();

    return ReferralInviteCard(
      clubName: clubName,
      clubLogoUrl: pending.organizationLogo ?? DugnadState.instance.clubLogo,
      recruitedBy: pending.referrerDisplayName!,
    );
  }
}
