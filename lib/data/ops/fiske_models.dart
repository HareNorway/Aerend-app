/// `GET /api/ops/customer/fiske` (`ops.customer.fiske`, AGIL-CONTRACT §3.2):
/// Fjordfiske today — the daily-catch cap from the same ledger count
/// `points/me/earn` caps on, and the prize cadence from the policy table.
class FiskeDay {
  const FiskeDay({
    required this.today,
    required this.max,
    required this.left,
    required this.capped,
    this.perCatch = 5,
    this.prizeEveryN,
    this.prizeFromCast,
  });

  final int today;
  final int max;
  final int left;
  final bool capped;
  final int perCatch;
  final int? prizeEveryN;
  final int? prizeFromCast;

  factory FiskeDay.fromJson(Map<String, dynamic> json) {
    final max = (json['max'] as num?)?.toInt() ?? 5;
    final today = (json['today'] as num?)?.toInt() ?? 0;
    return FiskeDay(
      today: today,
      max: max,
      left: (json['left'] as num?)?.toInt() ?? (max - today).clamp(0, max),
      capped: json['capped'] == true,
      perCatch: (json['per_catch'] as num?)?.toInt() ?? 5,
      prizeEveryN: (json['prize_every_n'] as num?)?.toInt(),
      prizeFromCast: (json['prize_from_cast'] as num?)?.toInt(),
    );
  }
}
