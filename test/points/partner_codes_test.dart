import 'package:flutter_test/flutter_test.dart';
import 'package:aerend_customer/data/points/points_models.dart';
import 'package:aerend_customer/screens/bergen/kasse/kasse_copy.dart';
import 'package:aerend_customer/screens/bergen/meg/meg_copy_a4.dart';

/// Points plan follow-up (points spec §6.2 kode / send; P-T15, P-T16): the claim's store ids for Kassen and the send
/// flow fields.
void main() {
  test('a kode premie knows its stores; a send premie asks for the address, then shows tracking', () {
    final kode = PrizeClaim.fromJson({'id': 5, 'prize_id': 6, 'state': 'claimed', 'spec_type': 'kode', 'voucher_code': 'SANDV-8QK2', 'store_ids': [875006, 875007]});
    expect(kode.storeIds, [875006, 875007]);
    expect(kode.status, 'klar');
    expect(KasseCopy.a1_kasse_kodepremie('Seks kanelboller'), 'Legg til premien din: Seks kanelboller');

    final send = PrizeClaim.fromJson({'id': 9, 'prize_id': 8, 'state': 'claimed', 'spec_type': 'send', 'needs_address': true});
    expect(send.needsAddress, isTrue);
    final sent = PrizeClaim.fromJson({'id': 9, 'prize_id': 8, 'state': 'shipped', 'status': 'paa_vei', 'spec_type': 'send', 'tracking': 'PB123NO', 'shipped_at': '2026-11-20T10:00:00+01:00'});
    expect([sent.status, sent.tracking], ['paa_vei', 'PB123NO']);
    expect(sent.shippedAt, isNotNull);
    expect(A4MegCopy.a4_hylla_send_sporing('PB123NO'), 'Sporingsnummer PB123NO');
  });
}
