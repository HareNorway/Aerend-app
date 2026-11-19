import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/points/points_models.dart';

/// Points plan Step 2: the level as the server sends it — review date, risk, pace, boat and perk; nothing assumed.
void main() {
  test('the tier payload: review date, at risk, threshold, pace, boat and perk', () {
    final b = PointsBalance.fromJson({
      'points': {'available': 10, 'earned_12m': 3400},
      'tier': {
        'index': 2,
        'name': 'Gull',
        'next_name': 'Platina',
        'points_to_next': 2600,
        'threshold': 3000,
        'review_at': '2027-02-16',
        'keep_gap': 0,
        'at_risk': false,
        'boat': 'snekke',
        'perk': 'vest',
        'pace': {'per_month': 300, 'months_to_next': 9},
      },
    });
    expect(b.reviewAt, DateTime(2027, 2, 16));
    expect(b.atRisk, isFalse);
    expect(b.marginOverThreshold, 400, reason: '«400 poeng over grensen for Gull»');
    expect(b.pacePerMonth, 300);
    expect(b.monthsToNext, 9);
    expect(b.boat, 'snekke');
    expect(b.perk, 'vest');
  });

  test('the first level: no review date, no margin, a rowing boat', () {
    final b = PointsBalance.fromJson({
      'points': {'earned_12m': 120},
      'tier': {'index': 0, 'name': 'Bronse', 'threshold': 0, 'review_at': null, 'at_risk': false, 'boat': 'robaat', 'perk': 'none', 'pace': {'per_month': 40, 'months_to_next': 23}},
    });
    expect(b.reviewAt, isNull);
    expect(b.marginOverThreshold, 0);
    expect(b.boat, 'robaat');
  });

  test('an older server without at_risk: a gap means at risk', () {
    expect(PointsBalance.fromJson({'tier': {'index': 1, 'keep_gap': 200}}).atRisk, isTrue);
    expect(PointsBalance.fromJson({'tier': {'index': 1, 'keep_gap': 0}}).atRisk, isFalse);
  });
}
