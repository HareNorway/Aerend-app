import 'package:flutter/material.dart';

import '../../theme/design_scale.dart';

import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import '../campaign/campaign_supplier_content.dart';
import '../../ui/kit/ae_theme.dart';
import '../../ui/kit/ae_sheet.dart';

const Color _kSuccessGreen = Color(0xFF22A769);

/// Supplier detail bottom sheet — prototype `SupplierSheet` (matkasse.jsx).
///
/// Content is the real seeded supplier record (Jens Eide) from
/// [CampaignSupplierContent], not an invented field. Opened by tapping the
/// supplier banner on the product screen.
Future<void> showDugnadSupplierSheet(
  BuildContext context, {
  required String heading,
}) {
  return showAeSheet<void>(
    context: context,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.85,
    ),
    builder: (_) => _SupplierSheetBody(heading: heading),
  );
}

class _SupplierSheetBody extends StatelessWidget {
  const _SupplierSheetBody({required this.heading});

  final String heading;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final lang = Localizations.localeOf(context).languageCode;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(context.dp(18), context.dp(12), context.dp(18), bottomInset + context.dp(22)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AeSheetHandle(),
          // Header — green shield emblem + "Leverandør" eyebrow + supplier name.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: context.dp(44),
                height: context.dp(44),
                decoration: BoxDecoration(
                  color: _kSuccessGreen.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(context.dp(13)),
                ),
                child: Icon(Icons.shield_outlined,
                    color: _kSuccessGreen, size: context.dp(20)),
              ),
              SizedBox(width: context.dp(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languages.dugnadSupplierEyebrow.toUpperCase(),
                      style: aeCaption(color: _kSuccessGreen).copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.04 * 11,
                      ),
                    ),
                    SizedBox(height: context.dp(2)),
                    Text(
                      heading,
                      style: aeH2().copyWith(
                        fontSize: 19,
                        letterSpacing: -0.01 * 19,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.dp(16)),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section(
                    CampaignSupplierContent.historyTitle(lang),
                    CampaignSupplierContent.historyBody(lang),
                  ),
                  SizedBox(height: context.dp(16)),
                  _section(
                    CampaignSupplierContent.spekematTitle(lang),
                    CampaignSupplierContent.spekematBody(lang),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: context.dp(18)),
          // "Skjønner" — reuses the existing why-fee sheet button copy.
          GestureDetector(
            onTap: () {
              aeSheetCloseHaptic();
              Navigator.pop(context);
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: context.dp(15)),
              decoration: BoxDecoration(
                color: theme.primary,
                borderRadius: BorderRadius.circular(context.dp(14)),
                boxShadow: theme.shadowButton,
              ),
              child: Center(
                child: Text(
                  languages.dugnadDonationWhyFeeUnderstand,
                  style: aeLabel(color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: aeTitle().copyWith(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 6),
        Text(
          body,
          style: aeBody(color: ScSaasThemeTokens.gray600).copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}
