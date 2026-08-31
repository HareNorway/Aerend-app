import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import '../../commonView/surface_decorations.dart';
import '../../networking/api_constant.dart';
import '../../theme/ae_typography.dart';
import '../../theme/sc_saas_theme.dart';
import '../../screens/campaign/campaign_strings.dart';

enum AeCheckoutPayMethod { vipps, cardKlarna, platformWallet }

const String kAeApplePayLogo = 'assets/images/applepay.png';
const String kAeGooglePayLogo = 'assets/images/gpay.png';
const String kAeVippsLogo = 'assets/images/Vipps_Logo_orange.png';

bool get aeSupportsPlatformPay => Platform.isIOS || Platform.isAndroid;

String get aePlatformPayLabel => Platform.isIOS ? 'Apple Pay' : 'Google Pay';

String get aePlatformPayLogo =>
    Platform.isIOS ? kAeApplePayLogo : kAeGooglePayLogo;

AeCheckoutPayMethod aeCheckoutDefaultPayMethod() {
  if (AppFeatureFlags.showVippsPay) return AeCheckoutPayMethod.vipps;
  if (aeSupportsPlatformPay) return AeCheckoutPayMethod.platformWallet;
  return AeCheckoutPayMethod.cardKlarna;
}

/// Compact payment row + change sheet used on dugnad campaign checkout.
class AeCheckoutPaymentSelector extends StatelessWidget {
  const AeCheckoutPaymentSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.accent,
  });

  final AeCheckoutPayMethod value;
  final ValueChanged<AeCheckoutPayMethod> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isPlatform = value == AeCheckoutPayMethod.platformWallet;
    final isVipps = value == AeCheckoutPayMethod.vipps;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AeSurface.card(borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            CampaignStrings.paymentHeading.toUpperCase(),
            style: aeOverline(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isVipps
                      ? Colors.transparent
                      : isPlatform
                          ? (Platform.isIOS ? Colors.white : Colors.black)
                          : accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: isPlatform && Platform.isIOS
                      ? Border.all(color: ScSaasThemeTokens.border)
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: isVipps
                    ? Image.asset(
                        kAeVippsLogo,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      )
                    : isPlatform
                        ? Padding(
                            padding: const EdgeInsets.all(6),
                            child: Image.asset(
                              aePlatformPayLogo,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          )
                        : Icon(
                            Icons.credit_card,
                            color: accent,
                            size: 20,
                          ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isVipps
                          ? CampaignStrings.payWithVippsSemanticsLabel
                          : isPlatform
                              ? aePlatformPayLabel
                              : 'Card / Klarna',
                      style: aeTitle(),
                    ),
                    Text(
                      CampaignStrings.payNow,
                      style: aeCaption(),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showPicker(context),
                child: Text(
                  CampaignStrings.change,
                  style: aeLabel(color: accent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(CampaignStrings.paymentMethod, style: aeH3()),
              const SizedBox(height: 14),
              if (aeSupportsPlatformPay) ...[
                _optionTile(
                  title: aePlatformPayLabel,
                  leading: _logoMark(
                    asset: aePlatformPayLogo,
                    darkTile: Platform.isAndroid,
                  ),
                  selected: value == AeCheckoutPayMethod.platformWallet,
                  onTap: () {
                    onChanged(AeCheckoutPayMethod.platformWallet);
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 8),
              ],
              _optionTile(
                title: 'Card / Klarna',
                icon: Icons.credit_card_outlined,
                selected: value == AeCheckoutPayMethod.cardKlarna,
                onTap: () {
                  onChanged(AeCheckoutPayMethod.cardKlarna);
                  Navigator.pop(ctx);
                },
              ),
              if (AppFeatureFlags.showVippsPay) ...[
                const SizedBox(height: 8),
                _optionTile(
                  title: CampaignStrings.payWithVippsSemanticsLabel,
                  leading: _logoMark(asset: kAeVippsLogo),
                  selected: value == AeCheckoutPayMethod.vipps,
                  onTap: () {
                    onChanged(AeCheckoutPayMethod.vipps);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoMark({required String asset, bool darkTile = false}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: darkTile ? Colors.black : Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Image.asset(
            asset,
            height: 22,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }

  Widget _optionTile({
    required String title,
    IconData? icon,
    Widget? leading,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.08)
              : ScSaasThemeTokens.gray50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accent : ScSaasThemeTokens.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (leading != null)
              SizedBox(width: 36, height: 28, child: Center(child: leading))
            else
              Icon(icon, color: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: aeTitle()),
                  Text(CampaignStrings.payNow, style: aeCaption()),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: accent),
          ],
        ),
      ),
    );
  }
}
