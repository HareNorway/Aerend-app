import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../dugnad_club_theme.dart';

/// Bottom sheet explaining the transparent two-part donation fee (Spleis model).
class DonationWhyFeeSheet extends StatelessWidget {
  const DonationWhyFeeSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DonationWhyFeeSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(context.dp(24)),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(context.dp(20), context.dp(12), context.dp(20), context.dp(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: context.dp(40),
                  height: context.dp(4),
                  margin: EdgeInsets.only(bottom: context.dp(18)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(context.dp(99)),
                  ),
                ),
              ),
              Text(
                languages.dugnadDonationWhyFeeTitle,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.dugnadTheme.text,
                ),
              ),
              SizedBox(height: context.dp(10)),
              Text(
                languages.dugnadDonationWhyFeeLead,
                style: const TextStyle(
                  // `.dn-why-lead` is a neutral gray-500 paragraph, not a
                  // themed accent.
                  color: ScSaasThemeTokens.gray500,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              SizedBox(height: context.dp(18)),
              _feePart(
                context,
                icon: Icons.credit_card_rounded,
                title: languages.dugnadDonationWhyFeeTransactionTitle,
                body: languages.dugnadDonationWhyFeeTransactionBody,
              ),
              _feePart(
                context,
                icon: Icons.bolt_rounded,
                title: languages.dugnadDonationWhyFeePlatformTitle,
                body: languages.dugnadDonationWhyFeePlatformBody,
              ),
              SizedBox(height: context.dp(16)),
              Container(
                padding: EdgeInsets.all(context.dp(14)),
                decoration: BoxDecoration(
                  color: context.dugnadTheme.primaryTint,
                  borderRadius: BorderRadius.circular(context.dp(14)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      color: context.dugnadTheme.primary,
                      size: context.dp(20),
                    ),
                    SizedBox(width: context.dp(10)),
                    Expanded(
                      child: Text(
                        languages.dugnadDonationWhyFeeHeartNote,
                        style: TextStyle(
                          color: context.dugnadTheme.text,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.dp(18)),
              ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.dugnadTheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: context.dp(14)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.dp(14)),
                  ),
                ),
                child: Text(
                  languages.dugnadDonationWhyFeeUnderstand,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feePart(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
  }) {
    // `.dn-why-part` — a hairline gray-100 top divider with 13px vertical
    // padding separates each fee part; the app had dropped it for plain gaps.
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.dp(13)),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: ScSaasThemeTokens.gray100),
        ),
      ),
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: context.dp(40),
          height: context.dp(40),
          decoration: BoxDecoration(
            color: context.dugnadTheme.primaryTint,
            borderRadius: BorderRadius.circular(context.dp(12)),
          ),
          child: Icon(icon, color: context.dugnadTheme.primary, size: context.dp(20)),
        ),
        SizedBox(width: context.dp(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: context.dp(4)),
              Text(
                body,
                style: const TextStyle(
                  // `.dn-why-part .s` is a neutral gray-500 body, not a themed
                  // accent.
                  color: ScSaasThemeTokens.gray500,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    );
  }
}
