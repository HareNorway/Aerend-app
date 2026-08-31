import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/design_scale.dart';
import '../../utils/utils.dart';
import 'dugnad_repo.dart';
import '../../ui/kit/ae_theme.dart';
import '../../ui/kit/ae_rise_in.dart';

/// Shown when the user returns from Vipps without an active agreement.
class DonationIncompleteScreen extends StatelessWidget {
  const DonationIncompleteScreen({
    super.key,
    required this.subscriptionId,
    this.confirmationUrl,
  });

  final int subscriptionId;
  final String? confirmationUrl;

  Future<void> _retry(BuildContext context) async {
    final url = confirmationUrl;
    if (url == null || url.isEmpty) {
      openSimpleSnackbar(languages.dugnadDonationVippsLaunchFailed);
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        openSimpleSnackbar(languages.dugnadDonationVippsLaunchFailed);
      }
    }
  }

  Future<void> _discard(BuildContext context) async {
    final ok = await DugnadRepo().abandonDonationSubscription(subscriptionId);
    if (!context.mounted) return;
    if (ok) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      openSimpleSnackbar(languages.dugnadDonationSyncFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.aeTheme.background,
      appBar: AppBar(
        backgroundColor: context.aeTheme.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          languages.dugnadDonationConfirmAppBar,
          style: TextStyle(
            color: context.aeTheme.text,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(context.dp(20), context.dp(8), context.dp(20), context.dp(24)),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AeRiseIn(
                    delay: const Duration(milliseconds: 120),
                    child: Container(
                      width: context.dp(72),
                      height: context.dp(72),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE8E8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFDC4040),
                        size: context.dp(40),
                      ),
                    ),
                  ),
                  SizedBox(height: context.dp(20)),
                  AeRiseIn(
                    delay: const Duration(milliseconds: 190),
                    child: Text(
                      languages.dugnadDonationIncompleteTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  SizedBox(height: context.dp(10)),
                  AeRiseIn(
                    delay: const Duration(milliseconds: 260),
                    child: Text(
                      languages.dugnadDonationIncompleteBody,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.aeTheme.primaryHover,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AeRiseIn(
              delay: const Duration(milliseconds: 440),
              duration: const Duration(milliseconds: 550),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _retry(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.aeTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: context.dp(16)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.dp(14)),
                    ),
                  ),
                  child: Text(languages.dugnadDonationIncompleteRetry),
                ),
              ),
            ),
            SizedBox(height: context.dp(10)),
            AeRiseIn(
              delay: const Duration(milliseconds: 490),
              duration: const Duration(milliseconds: 550),
              child: TextButton(
                onPressed: () => _discard(context),
                child: Text(languages.dugnadDonationIncompleteDiscard),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
