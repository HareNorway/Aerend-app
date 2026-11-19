import 'package:flutter_test/flutter_test.dart';
import 'package:aerend_customer/data/aegil/aegil_app_models.dart';
import 'package:aerend_customer/screens/bergen/meg/meg_copy_a4.dart';

/// Points plan Step 10 (points spec §9): the friends' states and the Vilkår rows from the server's numbers.
void main() {
  test('a friend reads the server state; older payloads still read status', () {
    final r = Referral.fromJson(<String, dynamic>{
      'code': 'ABC',
      'monthly_cap': 4,
      'yearly_cap': 20,
      'min_order_ore': 18000,
      'points_for_me': 150,
      'friends': [
        {'name': 'Kari', 'state': 'rewarded', 'status': 'delivered'},
        {'name': 'Ola', 'state': 'over_limit', 'status': 'downloaded'},
        {'name': 'Per', 'state': 'rejected', 'status': 'downloaded'},
        {'name': 'Liv', 'status': 'delivered'},
      ],
    });
    expect(r.friends.map((f) => f.delivered).toList(), [true, false, false, true]);
    expect(r.friends[1].overLimit, isTrue);
    expect(r.friends[2].rejected, isTrue);
    expect(r.yearlyCap, 20);

    final rader = A4MegCopy.a4_meg_vilkaar_rader(r);
    expect(rader.first[1], '150 poeng til hver når vennens første ordre med minst 180 kr i varer er levert');
    expect(rader[1][1], startsWith('4 venner med poeng i måneden og 20 i året.'));
    expect(rader.any((x) => x[0] == 'Billettstigen'), isFalse, reason: 'the ladder is retired');
  });
}
