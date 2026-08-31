import 'package:flutter/material.dart';

import '../../theme/design_scale.dart';
import '../../utils/utils.dart';
import 'dugnad_repo.dart';
import 'dugnad_club_theme.dart';
import 'widgets/dugnad_rise_in.dart';

/// Shown when Vipps rejected or stopped the agreement during sync.
class DonationSetupFailedScreen extends StatelessWidget {
  const DonationSetupFailedScreen({super.key, required this.subscriptionId});

  final int subscriptionId;

  Future<void> _dismiss(BuildContext context) async {
    await DugnadRepo().abandonDonationSubscription(subscriptionId);
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.dugnadTheme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(context.dp(20), context.dp(24), context.dp(20), context.dp(24)),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DugnadRiseIn(
                      delay: Duration(milliseconds: 120),
                      child: Icon(
                        Icons.cancel_outlined,
                        size: context.dp(56),
                        color: Color(0xFFDC4040),
                      ),
                    ),
                    SizedBox(height: context.dp(20)),
                    DugnadRiseIn(
                      delay: const Duration(milliseconds: 190),
                      child: Text(
                        languages.dugnadDonationSetupFailedTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(height: context.dp(10)),
                    DugnadRiseIn(
                      delay: const Duration(milliseconds: 260),
                      child: Text(
                        languages.dugnadDonationSetupFailedBody,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.dugnadTheme.primaryHover,
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              DugnadRiseIn(
                delay: const Duration(milliseconds: 440),
                duration: const Duration(milliseconds: 550),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _dismiss(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.dugnadTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: context.dp(16)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.dp(14)),
                      ),
                    ),
                    child: Text(languages.dugnadDonationConfirmHome),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
