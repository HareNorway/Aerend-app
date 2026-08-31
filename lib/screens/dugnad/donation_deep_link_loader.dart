import 'package:flutter/material.dart';

import '../../utils/utils.dart';
import '../common/vipps/donation_vipps_return.dart';
import 'dugnad_club_theme.dart';

/// Syncs Vipps recurring agreement after aerend://donation/vipps return.
/// Loading is shown via the global processing overlay (same as campaign payments).
class DonationDeepLinkLoader extends StatefulWidget {
  final int subscriptionId;

  const DonationDeepLinkLoader({
    super.key,
    required this.subscriptionId,
  });

  @override
  State<DonationDeepLinkLoader> createState() => _DonationDeepLinkLoaderState();
}

class _DonationDeepLinkLoaderState extends State<DonationDeepLinkLoader> {
  @override
  void initState() {
    super.initState();
    _handle();
  }

  Future<void> _handle() async {
    final ok = await completeDonationVippsSync(widget.subscriptionId);

    if (!mounted) return;

    if (!ok) {
      openSimpleSnackbar(languages.dugnadDonationSyncFailed);
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.dugnadTheme.background,
    );
  }
}
