import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/ops/tracking_models.dart';
import 'package:aerend_customer/screens/bergen/sporing/sporing_scene_kai.dart';
import 'package:aerend_customer/screens/bergen/sporing/sporing_scene_kart.dart';
import 'package:aerend_customer/screens/bergen/sporing/sporing_sist_oppdatert.dart';
import 'package:aerend_customer/services/customer/client_flags.dart';

import '../layout/reduced_motion_harness.dart';

/// Battery plan Step 7 (courier battery spec §4.3): «Sist oppdatert for N s
/// siden» on Sporing once `live_position.recorded_at` is older than 30 s —
/// minutes from 60 s, nothing while fresh, nothing with the flag off.
void main() {
  setUpAll(() async {
    await bootstrapGlobals();
  });

  setUp(() => ClientFlags.flags = {ClientFlags.trackingLastUpdated: true});
  tearDown(() => ClientFlags.flags = {});

  final now = DateTime(2026, 11, 12, 18, 0, 0);
  const style = TextStyle(fontSize: 8.5);
  final linje = find.byKey(const Key('a1_sporing_sist_oppdatert'));

  Future<void> pump(WidgetTester tester, Duration alder) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SpSistOppdatert(at: now.subtract(alder), style: style, now: now)),
    ),
  );

  testWidgets('shown at 31 s', (tester) async {
    await pump(tester, const Duration(seconds: 31));
    expect(linje, findsOneWidget);
    expect(find.text('Sist oppdatert for 31 s siden'), findsOneWidget);
  });

  testWidgets('hidden at 29 s and at exactly 30 s', (tester) async {
    await pump(tester, const Duration(seconds: 29));
    expect(linje, findsNothing);
    await pump(tester, const Duration(seconds: 30));
    expect(linje, findsNothing);
  });

  testWidgets('seconds up to 59, minutes from 60 s', (tester) async {
    await pump(tester, const Duration(seconds: 59));
    expect(find.text('Sist oppdatert for 59 s siden'), findsOneWidget);
    await pump(tester, const Duration(seconds: 60));
    expect(find.text('Sist oppdatert for 1 min siden'), findsOneWidget);
    await pump(tester, const Duration(seconds: 125));
    expect(find.text('Sist oppdatert for 2 min siden'), findsOneWidget);
  });

  testWidgets('nothing with the flag off, without a position, or from the future', (tester) async {
    ClientFlags.flags = {};
    await pump(tester, const Duration(minutes: 5));
    expect(linje, findsNothing);
    ClientFlags.flags = {ClientFlags.trackingLastUpdated: true};
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SpSistOppdatert(at: null, style: style))));
    expect(linje, findsNothing);
    await pump(tester, const Duration(seconds: -90));
    expect(linje, findsNothing);
  });

  test('the text helper and the payload field it reads', () {
    expect(SpSistOppdatert.tekst(now.subtract(const Duration(seconds: 40)), now), 'Sist oppdatert for 40 s siden');
    expect(SpSistOppdatert.tekst(now.subtract(const Duration(seconds: 29)), now), isNull);
    final t = OpsTracking.fromJson({
      'order_id': '4471',
      'state': 'picked_up',
      'stage': 2,
      'live_position': {'lat': 60.39, 'lng': 5.32, 'recorded_at': '2026-11-12T17:59:20+01:00'},
    });
    expect(t.livePosition?.recordedAt, DateTime.parse('2026-11-12T16:59:20Z').toLocal());
  });

  testWidgets('the map card says it under the distance', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // The test font (Ahem) is wider than the card's «ANKOMMER OM» row; that row is not this step's.
    final onError = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.toString().contains('overflowed')) onError?.call(d);
    };
    SpSceneInfo info(int alder) => SpSceneInfo(
      butikk: 'Sandviken Bakeri',
      slutt: DateTime.now().add(const Duration(minutes: 8)),
      totalSek: 600,
      meterIgjen: 1200,
      posAt: DateTime.now().subtract(Duration(seconds: alder)),
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SpSceneKart(info: info(45), linje: ''))));
    await tester.pump(const Duration(seconds: 1));
    // The wall clock moves on while the test runs (the shader loads): 45 s and more. Fresh positions: the tests above.
    expect(find.textContaining(RegExp(r'^Sist oppdatert for \d+ (s|min) siden$')), findsOneWidget);
    expect(tester.getTopLeft(linje).dy, greaterThan(tester.getTopLeft(find.byKey(const Key('a1_sporing_km_igjen'))).dy));
    await tester.pumpWidget(const SizedBox());
    FlutterError.onError = onError;
  });
}
