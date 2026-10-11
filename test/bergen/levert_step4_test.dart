import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/ops/tracking_models.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/sporing/hjelp_sheet.dart';
import 'package:aerend_customer/screens/bergen/sporing/levert_screen.dart';
import 'package:aerend_customer/screens/bergen/sporing/sporing_copy.dart';

import '../layout/reduced_motion_harness.dart';

/// Backend plan Step 4: Levert's local line and store story come from the
/// tracking payload (`month_local_count`, `store.story`); the courier's
/// «since» drives «sykler siden …».
class _Api extends OpsCustomerApi {
  @override
  Future<Map<String, dynamic>?> pointsMe() async => null;
  @override
  Future<Map<String, dynamic>?> pointsForOrder(int orderId) async => null;
  @override
  Future<Map<String, dynamic>?> referral() async => null;
}

Map<String, dynamic> _levert({int? monthLocal, String? story}) => {
      'order_id': '4471',
      'code': 'Æ-42K',
      'mode': 'delivery',
      'state': 'delivered',
      'stage': 3,
      'stage_label': 'Levert',
      'delivery_actor': 'aerend_courier',
      'delivered_by_label': 'Bud',
      'delivered_at': '2026-09-25T18:20:00+02:00',
      'courier': {'id': 19, 'first_name': 'Jonas', 'since': '2025-03-14T10:00:00+01:00', 'rating': 4.8},
      'store': {'id': 41, 'name': 'Pokemon Pizza', if (story != null) 'story': story},
      if (monthLocal != null) 'month_local_count': monthLocal,
    };

void main() {
  setUpAll(() async {
    await bootstrapGlobals();
    OpsCustomerApi.networkEnabled = false;
  });
  tearDownAll(() => OpsCustomerApi.networkEnabled = true);

  Future<void> pump(WidgetTester tester, Map<String, dynamic> p) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: LevertScreen(orderId: 4471, tracking: OpsTracking.fromJson(p), api: _Api())));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('the local line counts what the server counted, with the store story under it', (tester) async {
    await pump(tester, _levert(monthLocal: 3, story: 'Familiedrevet pizzeria på Bryggen.'));

    expect(find.text(SporingCopy.a1_sporing_lokalt('Pokemon Pizza', 3)), findsOneWidget);
    expect(find.text('Familiedrevet pizzeria på Bryggen.'), findsOneWidget);
  });

  testWidgets('no count from the server: no local line (never a client guess)', (tester) async {
    await pump(tester, _levert());

    expect(find.byKey(const Key('a1_sporing_lokalt')), findsNothing);
    expect(find.byKey(const Key('a1_sporing_historie')), findsNothing);
  });

  test('the courier payload carries since and rating', () {
    final c = OpsCourier.fromJson({'first_name': 'Jonas', 'since': '2025-03-14T10:00:00+01:00', 'rating': 4.8});
    expect(c.since?.year, 2025);
    expect(c.since?.month, 3);
    expect(c.rating, 4.8);
    expect(OpsCourier.fromJson({'first_name': 'Jonas'}).since, isNull);
  });

  testWidgets('the Hjelp card shows the courier rating, and no chip without one', (tester) async {
    Future<void> hjelp(Map<String, dynamic> courier) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final p = {..._levert(), 'state': 'picked_up', 'stage': 2, 'stage_label': 'På vei', 'courier': courier};
      await tester.pumpWidget(MaterialApp(home: HjelpScreen(key: UniqueKey(), orderId: 4471, tracking: OpsTracking.fromJson(p), api: _Api())));
      await tester.pump();
      await tester.pump();
    }

    await hjelp({'id': 19, 'first_name': 'Jonas', 'vehicle': 'sykkel', 'rating': 4.86});
    expect(find.byKey(const Key('a1_sporing_hjelp_rating')), findsOneWidget);
    expect(find.text('4,9'), findsOneWidget);

    await hjelp({'id': 19, 'first_name': 'Jonas', 'vehicle': 'sykkel'});
    expect(find.byKey(const Key('a1_sporing_hjelp_rating')), findsNothing);
  });

  test('«sykler siden …» from the courier\'s start month', () {
    expect(SporingCopy.a1_sporing_sykler_siden(null), 'sykler');
    final iAar = DateTime(DateTime.now().year, 3, 14);
    expect(SporingCopy.a1_sporing_sykler_siden(iAar), 'sykler siden mars');
    expect(SporingCopy.a1_sporing_sykler_siden(DateTime(2023, 11, 2)), 'sykler siden november 2023');
  });
}
