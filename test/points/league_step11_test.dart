import 'package:flutter_test/flutter_test.dart';
import 'package:aerend_customer/data/points/league_models.dart';
import 'package:aerend_customer/screens/bergen/poeng/poeng_copy.dart';

/// Points plan Step 11 (points spec §10, §10.1): the league payload's new fields and the prize copy from the server.
void main() {
  final l = League.fromJson(<String, dynamic>{
    'opted_in': true,
    'cap_per_order': 100,
    'league': {
      'month': '2026-11',
      'min_orders': 3,
      'own': {'rank': null, 'user_id': 7, 'points': 120, 'orders': 2, 'name': 'Kari'},
      'prizes': [
        {'from': 1, 'to': 1, 'kind': 'premie', 'premie': 'Kveld på Fløyen', 'uses': 1},
        {'from': 2, 'to': 2, 'kind': 'premie', 'premie': 'Gratis levering', 'uses': 30},
        {'from': 3, 'to': 3, 'kind': 'points', 'points': 500},
        {'from': 4, 'to': 10, 'kind': 'points', 'points': 100},
      ],
      'feed': [
        {'text': 'Kari klatret 2 plasser'},
        {'text': 'Ingrid fikk 40 poeng'},
      ],
      'last_month': {
        'month': '2026-10',
        'top': [
          {'rank': 1, 'name': 'Sjøsprøyt', 'points': 900},
        ],
        'own_rank': 5,
      },
      'boat': 'Sjøsprøyt',
    },
  });

  test('the payload reads min orders, an unranked own row, the feed, last month and the boat', () {
    expect(l.minOrders, 3);
    expect(l.own!.rank, 0);
    expect(l.own!.orders, 2);
    expect(l.feed, ['Kari klatret 2 plasser', 'Ingrid fikk 40 poeng']);
    expect(l.lastMonth!.top.single.label, 'Sjøsprøyt');
    expect(l.lastMonth!.ownRank, 5);
    expect(l.boat, 'Sjøsprøyt');
  });

  test('the prizes come from the server, with the winner\'s mission and boat', () {
    final rader = A3PoengCopy.a3_poeng_liga_premie_liste(l);
    expect(rader[0], '1. Kveld på Fløyen · du velger neste måneds første oppdrag · navnet ditt på Ægils båt');
    expect(rader[1], '2. Gratis levering · opptil 30 leveringer');
    expect(rader[2], '3. 500 poeng');
    expect(rader[3], '4.–10. 100 poeng');
    expect(A3PoengCopy.a3_poeng_liga_ikke_rangert(2, 3), 'Ikke rangert ennå · 2 av 3 ordrer');
    expect(A3PoengCopy.a3_poeng_liga_vilkaar_rader(l).first[1], contains('høyst 100 kjøpspoeng per ordre'));
  });

  test('without the payload the spec table is shown', () {
    expect(A3PoengCopy.a3_poeng_liga_premie_liste().last, '4.–10. 100 poeng');
  });
}
