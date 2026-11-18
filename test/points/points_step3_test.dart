import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/points/points_models.dart';
import 'package:aerend_customer/screens/bergen/poeng/poeng_feil.dart';

/// Points plan Step 3 (points spec §6): the premie and claim as the server sends them, and the spec's error codes.
void main() {
  test('a premie: spec type, sold out this month, stock left, validity', () {
    final p = Prize.fromJson({'id': 3, 'name': 'Seks kanelboller', 'type': 'partner', 'spec_type': 'kode', 'point_price': 500, 'in_stock': false, 'sold_out': true, 'stock_left': 0, 'valid_days': 60});
    expect(p.specType, 'kode');
    expect(p.soldOut, isTrue);
    expect(p.stockLeft, 0);
    expect(p.validDays, 60);
    // An older server: the type maps.
    expect(Prize.fromJson({'id': 1, 'name': 'Gratis levering', 'type': 'voucher'}).specType, 'auto');
  });

  test("a claim: Mine premier's status, returnable, and an older server's state", () {
    final c = PrizeClaim.fromJson({'id': 9, 'prize_id': 3, 'state': 'cancelled', 'status': 'angret', 'returnable': false, 'spec_type': 'kode'});
    expect(c.status, 'angret');
    expect(c.cancellable, isFalse);
    expect(PrizeClaim.fromJson({'id': 9, 'prize_id': 3, 'state': 'shipped'}).status, 'paa_vei');
    expect(PrizeClaim.fromJson({'id': 9, 'prize_id': 3, 'state': 'failed'}).status, 'feilet');
  });

  test("the spec's error codes are known (their words are in poeng_feil.dart)", () {
    for (final code in ['POINTS_INSUFFICIENT', 'SHELF_LOCKED', 'PREMIE_SOLD_OUT', 'PREMIE_LIMIT', 'CLAIM_NOT_RETURNABLE']) {
      expect(CusPoengFeil.kjent(code), isTrue, reason: code);
    }
  });
}
