import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/ops/kart_models.dart';
import 'package:aerend_customer/screens/bergen/kit/ae_kart.dart';

/// 2026-11-14 — the real maps' data (`ops.customer.order_map` / `store_route`): the points, the road, where Ægil is
/// put before the courier's position is known; the map itself is off under `flutter test` (no platform view).
void main() {
  test('reads the order map: store, door, courier, the road and where it starts', () {
    final k = AeKartData.fromJson(<String, dynamic>{
      'actor': 'aerend_courier',
      'store': {'id': 1, 'name': 'Torgboden', 'lat': 60.3964, 'lng': 5.3266},
      'door': {'lat': 60.3913, 'lng': 5.3221, 'label': 'Torggaten 9'},
      'courier': {'lat': 60.395, 'lng': 5.325, 'recorded_at': '2026-11-14T10:00:00Z'},
      'route': {
        'points': [
          [60.395, 5.325],
          [60.393, 5.323],
          [60.3913, 5.3221],
        ],
        'metres': 650,
        'seconds': 240,
        'from': 'courier',
      },
    });
    expect(k.store, (60.3964, 5.3266));
    expect([k.storeName, k.doorLabel], ['Torgboden', 'Torggaten 9']);
    expect(k.door, (60.3913, 5.3221));
    expect(k.courier, (60.395, 5.325));
    expect([k.route.length, k.metres, k.seconds, k.fromCourier, k.partner], [3, 650, 240, true, false]);

    final tom = AeKartData.fromJson(<String, dynamic>{'store': {'lat': 60.0, 'lng': 5.0}, 'route': null});
    expect([tom.route, tom.door, tom.courier], [isEmpty, null, null]);
    expect(tom.along(.5), isNull);
  });

  test('Ægil along the road: the start, the end and in between', () {
    const k = AeKartData(route: [(60.0, 5.0), (60.0, 5.2)]);
    expect(k.along(0), (60.0, 5.0));
    expect(k.along(1), (60.0, 5.2));
    final mid = k.along(.5)!;
    expect(mid.$1, 60.0);
    expect(mid.$2, closeTo(5.1, 1e-9));
    expect(k.along(7), (60.0, 5.2), reason: 'clamped');
  });

  test('the real map is off under flutter test (the drawn maps stay)', () {
    expect(AeKart.aktiv, isFalse);
  });
}
