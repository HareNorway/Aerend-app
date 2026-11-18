import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/ops/butikk_models.dart';
import 'package:aerend_customer/data/points/points_rules.dart';
import 'package:aerend_customer/screens/bergen/sporing/sporing_bits.dart';

/// Points plan Step 1 (nothing hardcoded): the app takes the rate and the store's «+N per kjøp» from the server,
/// which takes them from the panel.
void main() {
  test('the rate is kr_per_point from the panel; points are whole, rounded down', () {
    final r = PointsRules.fromJson({'kjop_per_10kr': 2, 'kr_per_point': 5, 'first_order_bonus': 50})!;
    expect(r.krPerPoint, 5);
    expect(r.pointsForOre(34700), 69, reason: '347 kr at 5 kr per point');
    expect(r.pointsForOre(499), 0);
  });

  test('an older server without kr_per_point: derived from kjop_per_10kr', () {
    expect(PointsRules.fromJson({'kjop_per_10kr': 1})!.krPerPoint, 10);
    expect(PointsRules.fromJson({'kjop_per_10kr': 2})!.krPerPoint, 5);
  });

  test("the store page's «+N per kjøp» is the server's points_per_order, not a basket the app assumes", () {
    final d = BergenProductDetail.fromJson({'id': 1, 'name': 'Fiskesuppe', 'store_id': 7, 'points_per_10kr': 1, 'points_per_order': 42});
    expect(d.pointsPerOrder, 42);
    expect(BergenProductDetail.fromJson({'id': 1, 'name': 'x', 'store_id': 7}).pointsPerOrder, isNull, reason: 'unknown hides the pill');
  });

  test("Levert's «+N poeng for denne ordren» is the snapshot's net points, without the new-store bonus", () {
    expect(spPoengFraSnapshot({'points': {'granted': 84, 'breakdown': {'purchase': 34, 'new_store': 50}}}), 34);
    expect(spPoengFraSnapshot({'points': {'granted': 20, 'breakdown': {'purchase': 20}}}), 20, reason: 'after a partial refund');
    expect(spPoengFraSnapshot({'points': null}), isNull, reason: 'nothing granted yet: fall back to the ledger');
    expect(spPoengFraSnapshot({}), isNull);
  });
}
