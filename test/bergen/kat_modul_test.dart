import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/butikk/kategori_modul.dart';

/// Kategori › Butikker, the store module (Onboarding Step 5): the rail's
/// columns, its physics (stops, rubber band, spring) and the tile icons.
void main() {
  KatModulVare v(int id) => KatModulVare(id: id, storeId: 1, navn: 'Vare $id', prisTx: '$id kr');

  test('the columns alternate one large tile and two small, seven at most', () {
    final k = KatModulKolonne.lag([for (var i = 0; i < 10; i++) v(i)]);
    expect(k.map((c) => c.w).toList(), [206, 132, 206, 132, 206, 132, 206]);
    expect(k.map((c) => c.fliser.length).toList(), [1, 2, 1, 2, 1, 2, 1]);
    expect(k.length, 7);
    // An odd tail: the last small column holds one tile, shown large.
    final o = KatModulKolonne.lag([v(0), v(1)]);
    expect(o.length, 2);
    expect(o.last.w, 132);
    expect(o.last.stor, isTrue);
    expect(KatModulKolonne.lag(const []), isEmpty);
  });

  test('the stops are the column edges less the padding, clamped, plus the end', () {
    final s = BmFysikk.stopp([12, 226, 366, 580], 400);
    expect(s, [0, 214, 354, 400]);
    expect(BmFysikk.naermest(s, 300), 354);
    expect(BmFysikk.naermest(s, 100), 0);
    // A fling projects 220 ms of speed, clamped to the range.
    expect(BmFysikk.maal(s, 400, 0, 1000), 214);
    expect(BmFysikk.maal(s, 400, 0, 9000), 400);
    expect(BmFysikk.maal(s, 400, 400, -9000), 0);
  });

  test('the rubber band shortens the pull past the ends', () {
    expect(BmFysikk.gummi(100, 400), 100);
    expect(BmFysikk.gummi(-100, 400), closeTo(-24.0, .5));
    expect(BmFysikk.gummi(500, 400), closeTo(424.0, .5));
  });

  test('the spring lands without a bounce and the skew follows the speed', () {
    var x = 0.0, v = 0.0, sk = 0.0;
    var over = false;
    for (var i = 0; i < 400 && !BmFysikk.ferdig(x, v, 214, sk); i++) {
      (x, v) = BmFysikk.fjaer(x, v, 214, .016);
      sk += (BmFysikk.skjevMaal(v) - sk) * .18;
      if (x > 214.5) over = true;
    }
    expect(BmFysikk.ferdig(x, v, 214, sk), isTrue);
    expect(over, isFalse, reason: 'ζ .96: no overshoot past the stop');
    expect(BmFysikk.skjevMaal(5000), -2.6);
    expect(BmFysikk.skjevMaal(-500), closeTo(.8, .001));
  });

  test('the tile icon follows the product name, else the category', () {
    expect(katVareIkon('Pizza margherita', 0), 'pi_pizza');
    expect(katVareIkon('Pommes frites', 0), 'ico_frites');
    expect(katVareIkon('Coca-Cola 0,5 l', 0), 'ico_brus');
    expect(katVareIkon('Dobbel cheeseburger', 0), 'ico_burger');
    expect(katVareIkon('Røykelaks', 1), 'ico_fisk');
    expect(katVareIkon('Ukjent ting', 0), 'ico_mat');
    expect(katVareIkon('Ukjent ting', 2), 'ico_mote');
    expect(katVareIkon('Ukjent ting', 4), 'ico_gaver');
    expect(katVareTint('ico_brus', 3).first.toARGB32(), 0xFFF28B7E);
  });
}
