/// Client-side fee preview for Fast støtte (Spleis-style ~6% split).
class DonationFeeBreakdown {
  final int grossKr;
  final int feeKr;
  final int netKr;
  final int transactionFeeKr;
  final int platformFeeKr;

  const DonationFeeBreakdown({
    required this.grossKr,
    required this.feeKr,
    required this.netKr,
    required this.transactionFeeKr,
    required this.platformFeeKr,
  });
}

class DonationFeeCalculator {
  static const double totalFeeRate = 0.06;
  static const int minFeeKr = 2;

  static DonationFeeBreakdown forAmountKr(int amountKr) {
    final gross = amountKr.clamp(0, 999999);
    if (gross <= 0) {
      return const DonationFeeBreakdown(
        grossKr: 0,
        feeKr: 0,
        netKr: 0,
        transactionFeeKr: 0,
        platformFeeKr: 0,
      );
    }

    var fee = (gross * totalFeeRate).round();
    if (gross >= minFeeKr && fee < minFeeKr) {
      fee = minFeeKr;
    }
    if (fee >= gross) {
      fee = gross > 1 ? gross - 1 : 0;
    }

    final tx = (fee / 2).round();
    final drift = fee - tx;
    final net = gross - fee;

    return DonationFeeBreakdown(
      grossKr: gross,
      feeKr: fee,
      netKr: net,
      transactionFeeKr: tx,
      platformFeeKr: drift,
    );
  }

  /// Monthly donation base points by amount band (§3.2).
  static int monthlyPointsBase(int amountKr) {
    if (amountKr >= 200) return 35;
    if (amountKr >= 100) return 20;
    return 10;
  }

  /// Continuity multiplier from unbroken months (§6).
  static double continuityMultiplier(int streakMonths) {
    if (streakMonths >= 12) return 2.0;
    if (streakMonths >= 6) return 1.5;
    if (streakMonths >= 3) return 1.25;
    return 1.0;
  }

  /// Points preview for setup screen (month 1, no continuity boost yet).
  static int previewPointsForAmountKr(int amountKr) {
    if (amountKr < 10) return 0;
    final base = monthlyPointsBase(amountKr);
    return (base * continuityMultiplier(1)).round();
  }
}

/// Donation amount bands shown in the design prototype (not lifetime metal tiers).
class DonationAmountTier {
  final String id;
  final int minKr;

  const DonationAmountTier({required this.id, required this.minKr});

  static const List<DonationAmountTier> tiers = [
    DonationAmountTier(id: 'bronse', minKr: 50),
    DonationAmountTier(id: 'solv', minKr: 100),
    DonationAmountTier(id: 'gull', minKr: 200),
    DonationAmountTier(id: 'platina', minKr: 500),
  ];

  static DonationAmountTier? forAmount(int amountKr) {
    DonationAmountTier? current;
    for (final tier in tiers) {
      if (amountKr >= tier.minKr) current = tier;
    }
    return current;
  }

  static DonationAmountTier? nextAfter(int amountKr) {
    for (final tier in tiers) {
      if (amountKr < tier.minKr) return tier;
    }
    return null;
  }
}
