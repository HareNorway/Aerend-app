import 'package:flutter_test/flutter_test.dart';
import 'package:aerend_customer/data/points/points_rules.dart';
import 'package:aerend_customer/screens/bergen/aegil/aegil_verktoy.dart';
import 'package:aerend_customer/screens/bergen/meg/meg_copy_a4.dart';

import '../a3/a3_fakes.dart';

/// Points plan Step 14 (plan §4c, points spec §3, §14): the corrected texts and the points chat card's line.
void main() {
  setUp(() async => a3Bootstrap());

  test('Dagens napp carries the month cap from the rules', () {
    final r = PointsRules.fromJson({'kjop_per_10kr': 1, 'fiske': {'points_per_catch': 5, 'monthly_cap': 50}})!;
    expect(r.fiskeMonthlyCap, 50);
    expect(A4MegCopy.a4_meg_rate_napp(r.fiskePerCatch, r.fiskeMonthlyCap), '+5 poeng for dagens første funn, opptil 50 i måneden');
    expect(A4MegCopy.a4_meg_rate_kr_per_point(10), '1 poeng per 10 kr du handler for');
  });

  test('points expire on inactivity, not by age', () {
    expect(A4MegCopy.a4_premie_vilkaar_poeng_sub(12), 'Utløper ikke så lenge du har fått levert en ordre de siste 12 månedene');
  });

  test('the points card line', () {
    expect(AeVerktoyCopy.cus_aegil_poeng(400, 'Bronse', 600, 'Sølv'), '400 poeng · Bronse · 600 til Sølv');
    expect(AeVerktoyCopy.cus_aegil_poeng(7000, 'Platina', null, null), '7000 poeng · Platina');
  });
}
