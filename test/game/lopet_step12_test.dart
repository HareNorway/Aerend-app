import 'package:flutter_test/flutter_test.dart';
import 'package:aerend_customer/data/points/points_rules.dart';
import 'package:aerend_customer/data/points/voucher_api.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_copy.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_liste.dart';
import 'package:aerend_customer/screens/bergen/meg/meg_copy_a4.dart';

import '../a3/a3_fakes.dart';

/// Points plan Step 12 (game spec §5.4, §6.2, §8; points spec §11.2): the ladder's prize lines, the locked Meg row,
/// the rules' Fjordløpet block, a premiekupong.
void main() {
  setUp(() async => a3Bootstrap());

  test('prize lines: vouchers by shelf, points for 4–10', () {
    expect(LopetListe.premie({'from': 1, 'to': 1, 'kind': 'voucher', 'shelf': 'Gull'}), '1. Én premie fra Gull-hylla');
    expect(LopetListe.premie({'from': 2, 'to': 3, 'kind': 'voucher', 'shelf': 'Sølv'}), '2.–3. Én premie fra Sølv-hylla');
    expect(LopetListe.premie({'from': 4, 'to': 10, 'kind': 'points', 'points': 50}), '4.–10. 50 poeng');
  });

  test('the locked Meg row and Levert line', () {
    expect(LopetCopy.megRad(412, 8, 'Matros'), 'Fjordløpet · beste 412 m · 8. plass · Matros');
    expect(LopetCopy.megRad(null, null, 'Lettmatros'), 'Fjordløpet');
    expect(LopetCopy.plassLosgrad(8, 'Matros'), '8. plass · Matros');
    expect(LopetCopy.plassLosgrad(null, ''), '');
  });

  test('the rules carry Fjordløpet for «Slik får du poeng»', () {
    final r = PointsRules.fromJson({
      'kjop_per_10kr': 1, 'first_order_bonus': 50, 'referral': {'referrer': 200, 'referee': 200}, 'signup_bonus': {'enabled': false, 'amount': 0},
      'fiske': {'daily_cap': 1, 'points_per_catch': 5}, 'config_version': '1',
      'fjordlopet': {'milestones_m': [200, 500, 1000], 'points': [3, 6, 12], 'personal_best': 3, 'cap_per_order': 15},
    })!;
    expect(r.fjordlopetPoints, [3, 6, 12]);
    expect(A4MegCopy.a4_meg_rate_fjordlopet(r.fjordlopetPoints, r.fjordlopetPb, r.fjordlopetCap), startsWith('Mens du venter: 3 / 6 / 12 poeng'));
  });

  test('a premiekupong parses', () {
    final v = PremieVoucher.fromJson({'id': 4, 'max_shelf': 1, 'shelf': 'Sølv', 'valid_until': '2027-01-18T00:00:00+01:00'});
    expect([v.id, v.maxShelf, v.shelf], [4, 1, 'Sølv']);
    expect(v.validUntil, isNotNull);
  });
}
