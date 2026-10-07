/// `GET /api/points/rules` (backend plan Step 3): the rates the app shows.
///
/// Public and the same for everyone. Every number on onboarding, the Sporing
/// chip and the Ærend-kroner lines comes from here, never from a literal. A
/// screen that has no rules (offline, old server) hides the number instead of
/// guessing one.
class PointsRules {
  const PointsRules({
    required this.kjopPer10kr,
    required this.firstOrderBonus,
    required this.referrer,
    required this.referee,
    required this.signupBonus,
    required this.signupEnabled,
    required this.fiskePerCatch,
    required this.configVersion,
  });

  /// Points per whole 10 kr paid (`points.kjop_per_10kr`).
  final int kjopPer10kr;

  /// Første gang (`points.forste_gang`).
  final int firstOrderBonus;

  /// Verving: what the referrer and the new customer each get on the new
  /// customer's first qualifying order.
  final int referrer;
  final int referee;

  /// Start points on verification: 0 while `points.signup_bonus.enabled` is off.
  final int signupBonus;
  final bool signupEnabled;

  /// Points per Fjordfiske catch (`points.dagens_napp`).
  final int fiskePerCatch;

  final String configVersion;

  static int _int(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;

  static PointsRules? fromJson(Map<String, dynamic>? json) {
    if (json == null || json['kjop_per_10kr'] == null) return null;
    final referral = json['referral'] is Map ? Map<String, dynamic>.from(json['referral'] as Map) : const <String, dynamic>{};
    final signup = json['signup_bonus'] is Map ? Map<String, dynamic>.from(json['signup_bonus'] as Map) : const <String, dynamic>{};
    final fiske = json['fiske'] is Map ? Map<String, dynamic>.from(json['fiske'] as Map) : const <String, dynamic>{};
    return PointsRules(
      kjopPer10kr: _int(json['kjop_per_10kr']),
      firstOrderBonus: _int(json['first_order_bonus']),
      referrer: _int(referral['referrer']),
      referee: _int(referral['referee']),
      signupBonus: _int(signup['amount']),
      signupEnabled: signup['enabled'] == true,
      fiskePerCatch: _int(fiske['points_per_catch']),
      configVersion: '${json['config_version'] ?? ''}',
    );
  }

  /// Kjøp points for an amount in øre, the way KjopRule counts them: whole
  /// 10 kr only.
  int pointsForOre(int ore) => ore <= 0 ? 0 : (ore ~/ 1000) * kjopPer10kr;
}

/// Splits an order's real points total over the Sporing stages by the
/// prototype's weights (`[8, 8, 8, 34]`), so the chip's «+N poeng» per stage
/// adds up to exactly what the order earns. Points per stage are not a backend
/// concept (backend plan Step 3); the last stage takes the rounding.
List<int> splitPointsByStage(int total, {List<int> weights = const [8, 8, 8, 34]}) {
  if (total <= 0) return List<int>.filled(weights.length, 0);
  final sum = weights.fold<int>(0, (a, b) => a + b);
  final out = <int>[];
  var given = 0;
  for (var i = 0; i < weights.length; i++) {
    final n = i == weights.length - 1 ? total - given : (total * weights[i] / sum).floor();
    out.add(n);
    given += n;
  }
  return out;
}
