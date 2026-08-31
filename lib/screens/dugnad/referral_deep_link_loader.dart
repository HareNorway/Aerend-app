import 'package:flutter/material.dart';

import '../../ui/kit/ae_loader.dart';
import '../../utils/utils.dart';
import '../common/login/login.dart';
import 'dugnad_referral_state.dart';
import 'dugnad_repo.dart';
import '../../ui/kit/ae_theme.dart';

/// Validates aerend://referral deep links and routes into signup with pending attribution.
class ReferralDeepLinkLoader extends StatefulWidget {
  final String clubSlug;
  final String referralToken;

  const ReferralDeepLinkLoader({
    super.key,
    required this.clubSlug,
    required this.referralToken,
  });

  @override
  State<ReferralDeepLinkLoader> createState() => _ReferralDeepLinkLoaderState();
}

class _ReferralDeepLinkLoaderState extends State<ReferralDeepLinkLoader> {
  @override
  void initState() {
    super.initState();
    _handle();
  }

  Future<void> _handle() async {
    final repo = DugnadRepo();
    final result = await repo.validateReferral(
      clubSlug: widget.clubSlug,
      referralToken: widget.referralToken,
    );

    if (result.valid) {
      await DugnadReferralState.instance.saveFromValidation(
        clubSlug: result.clubSlug ?? widget.clubSlug,
        referralToken: result.referralToken ?? widget.referralToken,
        referralCode: result.referralCode,
        organizationId: result.organizationId,
        referrerDisplayName: result.referrerDisplayName,
        organizationName: result.organizationName,
        organizationLogo: result.organizationLogo,
      );
    } else if (mounted) {
      openSimpleSnackbar(result.message ?? languages.dugnadReferralCodeInvalid);
    }

    if (!mounted) return;
    openScreenWithClearPrevious(context, const Login());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.aeTheme.background,
      body: const AeLoaderScreen(),
    );
  }
}
