import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import '../../../commonView/surface_decorations.dart';
import '../../../networking/api_constant.dart';
import '../../../theme/ae_typography.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../campaign/campaign_strings.dart';

enum DugnadCheckoutPayMethod { vipps, cardKlarna, platformWallet }

const String kDugnadApplePayLogo = 'assets/images/applepay.png';
const String kDugnadGooglePayLogo = 'assets/images/gpay.png';
const String kDugnadVippsLogo = 'assets/images/Vipps_Logo_orange.png';

bool get dugnadSupportsPlatformPay => Platform.isIOS || Platform.isAndroid;

String get dugnadPlatformPayLabel => Platform.isIOS ? 'Apple Pay' : 'Google Pay';

String get dugnadPlatformPayLogo =>
    Platform.isIOS ? kDugnadApplePayLogo : kDugnadGooglePayLogo;

DugnadCheckoutPayMethod dugnadCheckoutDefaultPayMethod() {
  if (AppFeatureFlags.showVippsPay) return DugnadCheckoutPayMethod.vipps;
  if (dugnadSupportsPlatformPay) return DugnadCheckoutPayMethod.platformWallet;
  return DugnadCheckoutPayMethod.cardKlarna;
}

/// Compact payment row + change sheet used on dugnad campaign checkout.
class DugnadCheckoutPaymentSelector extends StatelessWidget {
  const DugnadCheckoutPaymentSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.accent,
  });

  final DugnadCheckoutPayMethod value;
  final ValueChanged<DugnadCheckoutPayMethod> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isPlatform = value == DugnadCheckoutPayMethod.platformWallet;
    final isVipps = value == DugnadCheckoutPayMethod.vipps;
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
                        kDugnadVippsLogo,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      )
                    : isPlatform
                        ? Padding(
                            padding: const EdgeInsets.all(6),
                            child: Image.asset(
                              dugnadPlatformPayLogo,
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
                              ? dugnadPlatformPayLabel
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
              if (dugnadSupportsPlatformPay) ...[
                _optionTile(
                  title: dugnadPlatformPayLabel,
                  leading: _logoMark(
                    asset: dugnadPlatformPayLogo,
                    darkTile: Platform.isAndroid,
                  ),
                  selected: value == DugnadCheckoutPayMethod.platformWallet,
                  onTap: () {
                    onChanged(DugnadCheckoutPayMethod.platformWallet);
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 8),
              ],
              _optionTile(
                title: 'Card / Klarna',
                icon: Icons.credit_card_outlined,
                selected: value == DugnadCheckoutPayMethod.cardKlarna,
                onTap: () {
                  onChanged(DugnadCheckoutPayMethod.cardKlarna);
                  Navigator.pop(ctx);
                },
              ),
              if (AppFeatureFlags.showVippsPay) ...[
                const SizedBox(height: 8),
                _optionTile(
                  title: CampaignStrings.payWithVippsSemanticsLabel,
                  leading: _logoMark(asset: kDugnadVippsLogo),
                  selected: value == DugnadCheckoutPayMethod.vipps,
                  onTap: () {
                    onChanged(DugnadCheckoutPayMethod.vipps);
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
