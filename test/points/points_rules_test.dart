import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/points/points_rules.dart';

/// Backend plan Step 3: `GET /api/points/rules` parsing and the Sporing
/// stage split.
void main() {
  const json = {
    'status': 1,
    'config_version': '2026-09-22-v1',
    'kjop_per_10kr': 1,
    'earn_percent': 10,
    'first_order_bonus': 50,
    'referral': {'referrer': 200, 'referee': 200, 'min_order_ore': 20000},
    'signup_bonus': {'enabled': false, 'amount': 0},
    'fiske': {'daily_cap': 5, 'points_per_catch': 5},
  };

  test('parses the rules the server sends', () {
    final r = PointsRules.fromJson(Map<String, dynamic>.from(json))!;
    expect(r.kjopPer10kr, 1);
    expect(r.firstOrderBonus, 50);
    expect(r.referrer, 200);
    expect(r.referee, 200);
    expect(r.signupBonus, 0);
    expect(r.signupEnabled, isFalse);
    expect(r.fiskePerCatch, 5);
    expect(r.configVersion, '2026-09-22-v1');
  });

  test('no rules, no model (the screen hides its numbers)', () {
    expect(PointsRules.fromJson(null), isNull);
    expect(PointsRules.fromJson(const {'status': 0}), isNull);
  });

  test('product coins count whole 10 kr like KjopRule', () {
    final r = PointsRules.fromJson(Map<String, dynamic>.from(json))!;
    expect(r.pointsForOre(14900), 14);
    expect(r.pointsForOre(999), 0);
    expect(r.pointsForOre(0), 0);
  });

  test('the stage split adds up to the real total by the prototype weights', () {
    expect(splitPointsByStage(58), [8, 8, 8, 34]);
    expect(splitPointsByStage(64).fold<int>(0, (a, b) => a + b), 64);
    expect(splitPointsByStage(64), [8, 8, 8, 40]);
    expect(splitPointsByStage(3), [0, 0, 0, 3]);
    expect(splitPointsByStage(0), [0, 0, 0, 0]);
  });

  test('Ægil answer points: off hides the number, on pays per answer under the cap (backend plan Step 7)', () {
    final off = PointsRules.fromJson({'kjop_per_10kr': 1})!;
    expect(off.aegilAnswerEnabled, isFalse);
    expect(off.aegilPointsFor(4), 0);

    final on = PointsRules.fromJson({
      'kjop_per_10kr': 1,
      'aegil_answer': {'enabled': true, 'per_answer': 5, 'cap': 50},
    })!;
    expect(on.aegilPointsFor(3), 15);
    expect(on.aegilPointsFor(20), 50);
    expect(on.aegilPointsFor(0), 0);
  });
}
