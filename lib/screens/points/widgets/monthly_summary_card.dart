import 'package:flutter/material.dart';

import '../../../theme/reen_pre_club_theme.dart';

/// The monthly points summary.
///
/// Carries the savings line that used to live on a standalone trust-ledger card: the plan
/// folds that card into this summary rather than keeping a separate surface for it. For
/// customers whose kroner balance was converted, [migratedSavingsKr] is what they had saved
/// before the migration — shown so the conversion is visible rather than silent.
class MonthlySummaryCard extends StatelessWidget {
  const MonthlySummaryCard({
    super.key,
    required this.month,
    this.earned = 0,
    this.spent = 0,
    this.expiring = 0,
    this.savedKr = 0,
    this.migratedSavingsKr,
  });

  final String month;
  final int earned;
  final int spent;
  final int expiring;

  /// What Ægil's advice saved this month, in kroner.
  final int savedKr;

  /// Kroner converted to points in the migration, if this customer had a balance.
  final double? migratedSavingsKr;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('monthly-summary-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AerendBergenAuthTokens.glassFill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AerendBergenAuthTokens.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            month.toUpperCase(),
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AerendBergenAuthTokens.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          _row('Tjent', '+$earned poeng', AerendBergenAuthTokens.mint),
          _row('Brukt', '−$spent poeng', AerendBergenAuthTokens.textSubtitle),
          if (expiring > 0)
            _row('Utløper snart', '$expiring poeng',
                AerendBergenAuthTokens.orangeLight),
          if (savedKr > 0)
            _row('Ægil sparte deg', '$savedKr kr',
                AerendBergenAuthTokens.textSubtitle),
          if (migratedSavingsKr != null && migratedSavingsKr! > 0)
            _row(
              'Overført fra kroner',
              '${migratedSavingsKr!.toStringAsFixed(0)} kr',
              AerendBergenAuthTokens.textSoft,
              key: const Key('monthly-summary-migrated-line'),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color valueColor, {Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AerendBergenAuthTokens.textSoft,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
