import 'package:aerend_customer/screens/bergen/sporing/sporing_bits.dart';
import 'package:aerend_customer/screens/bergen/sporing/sporing_gl.dart';
import 'package:aerend_customer/screens/common/home/bergen/bergen_kit.dart' show BergenWeather;
import 'package:flutter_test/flutter_test.dart';

/// Parity Step 7: the live Sporing scenes' palette and Levert's points split.
void main() {
  group('SpPal (the prototype\'s spPal)', () {
    test('rain is the evening rain the manager sees', () {
      final p = SpPal.of(BergenWeather.regn);
      expect(p.night, .74);
      expect(p.rain, 1);
      expect(p.wet, 1);
      expect(p.sunset, 0);
      // mx([.56,.70,.80], [.09,.17,.23], .74), then the rain mix (.35).
      expect(p.skT[0], closeTo(.2122 + (.5 * (1 - .74 * .65) - .2122) * .35, 1e-6));
    });

    test('sun is day, night is full night, sunset keeps night at .74', () {
      expect(SpPal.of(BergenWeather.sol).night, .14);
      expect(SpPal.of(BergenWeather.sol).rain, 0);
      expect(SpPal.of(BergenWeather.natt).night, 1);
      final sn = SpPal.of(BergenWeather.solnedgang);
      expect(sn.sunset, 1);
      expect(sn.night, .74);
    });
  });

  group('order points on Sporing / Levert', () {
    final ledger = {
      'ledger': [
        {'kind': 'earn', 'rule_key': 'kjop', 'amount': 26, 'ref_type': 'order', 'ref_id': '278'},
        {'kind': 'earn', 'rule_key': 'forste_gang', 'amount': 50, 'ref_type': 'order', 'ref_id': '278'},
        {'kind': 'earn', 'rule_key': 'kjop', 'amount': 9, 'ref_type': 'order', 'ref_id': '277'},
      ],
    };

    test('the order\'s points leave out the first-time bonus', () {
      expect(spPoengForOrdre(ledger, 278), 26);
      expect(spForsteGang(ledger, 278), 50);
    });

    test('no first-time row without one', () {
      expect(spForsteGang(ledger, 277), isNull);
      expect(spPoengForOrdre(ledger, 277), 9);
    });

    test('direct fields still win', () {
      expect(spPoengForOrdre({'points': 34, 'first_time_bonus': 50}, 1), 34);
      expect(spForsteGang({'points': 34, 'first_time_bonus': 50}, 1), 50);
    });
  });
}
