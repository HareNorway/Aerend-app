import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/points/points_models.dart';
import 'package:aerend_customer/screens/bergen/kit/ae_mynt.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_copy.dart';
import 'package:aerend_customer/screens/bergen/meg/a3_services.dart';
import 'package:aerend_customer/screens/bergen/poeng/poeng_kreditert.dart';
import 'package:aerend_customer/utils/utils.dart' show prefGetBool;

import '../a3/a3_fakes.dart';

/// Design 21 Nov plan Step 6: «Poeng kreditert» — the rows from the snapshot, the timeline's end state, skip,
/// reduced motion, the balance from `points/me`, and once per order.

const _stige = [TierStep(index: 0, name: 'Bronse', threshold: 0), TierStep(index: 1, name: 'Sølv', threshold: 1000), TierStep(index: 2, name: 'Gull', threshold: 3000), TierStep(index: 3, name: 'Platina', threshold: 6000)];

PointsBalance _b({int available = 1249, int earned = 3609}) => PointsBalance(available: available, earned12m: earned, tier: 2, tierName: 'Gull', nextTierName: 'Platina', pointsToNextTier: 6000 - earned, tiers: _stige);

Map<String, dynamic> _game(List<Map<String, dynamic>> rows, {int best = 540}) => {'best_m': best, 'gate': 1, 'points': rows.fold<int>(0, (a, r) => a + (r['points'] as int)), 'rows': rows, 'credited_at': '2026-11-22T18:11:00+01:00'};

Widget _host(Widget child, {bool rolig = false}) => MaterialApp(
  builder: (context, app) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: rolig, textScaler: const TextScaler.linear(.5)), child: app!),
  home: child,
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() async => a3Bootstrap());

  test('the rows: Bøye 1 alone, Bøye 2 + record, Bryggen + record — from the snapshot, named from the course', () {
    final p = LopetCopy.porter;
    final b1 = KrData.raderFra(_game([{'reason': 'milestone', 'gate': 0, 'points': 3}], best: 236));
    expect(b1.map((r) => (r.tittel, r.under, r.poeng, r.rekord)), [(KrCopy.nadd(p[0]), KrCopy.besteSeilas(236), 3, false)]);
    final b2 = KrData.raderFra(_game([{'reason': 'milestone', 'gate': 1, 'points': 6}, {'reason': 'personal_best', 'gate': null, 'points': 3}]));
    expect(b2.map((r) => (r.tittel, r.poeng, r.rekord)), [(KrCopy.nadd(p[1]), 6, false), (KrCopy.nyRekord, 3, true)]);
    final br = KrData.raderFra(_game([{'reason': 'milestone', 'gate': 2, 'points': 12}, {'reason': 'personal_best', 'gate': null, 'points': 3}], best: 1046));
    expect(br.fold<int>(0, (a, r) => a + r.poeng), 15);
    expect(br.first.under, KrCopy.besteSeilas(1046));
    // An older server: one row from the gate and the total; nothing without points.
    expect(KrData.raderFra({'best_m': 540, 'gate': 1, 'points': 6}).single.poeng, 6);
    expect(KrData.raderFra({'best_m': 120, 'gate': null, 'points': 0}), isEmpty);
    expect(KrData.raderFra(null), isEmpty);
  });

  test('the level: same level counts down to the next, a crossing says «Nytt nivå»', () {
    final rader = [const KrRad(tittel: 'Bøye 2 nådd', under: '', poeng: 9)];
    final d = KrData.fra(rader, _b());
    expect([d.fra, d.til, d.oppFra, d.oppTil], [1240, 1249, 3600, 3609]);
    expect(d.nyttNivaa, isFalse);
    expect(d.nivTilTx(3609), KrCopy.poengTil('2 391', 'Platina'));
    final opp = KrData.fra(rader, _b(earned: 3004));
    expect(opp.nyttNivaa, isTrue);
    expect(opp.navn, 'Gull');
    expect(KrData.fra(rader, null).til, isNull, reason: 'no balance without points/me — never computed');
  });

  testWidgets('the timeline ends with «+9», the balance from points/me, the level line and the keys; a tap skips', (tester) async {
    _phone(tester);
    final d = KrData.fra(KrData.raderFra(_game([{'reason': 'milestone', 'gate': 1, 'points': 6}, {'reason': 'personal_best', 'gate': null, 'points': 3}])), _b());
    await tester.pumpWidget(_host(PoengKreditert(data: d)));
    await tester.pump();
    // Early: the total starts at +0 and the balance at the old number.
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('+0'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1400));
    expect(find.text('1 240'), findsOneWidget, reason: 'the card is up, no coin has landed yet');
    // A tap skips to the end.
    await tester.tap(find.byKey(const Key('poeng_kreditert')));
    await tester.pump();
    expect(find.text('+9'), findsWidgets);
    expect(find.text('1 249'), findsOneWidget);
    expect(find.text(KrCopy.poengTil('2 391', 'Platina')), findsOneWidget);
    expect(find.byKey(const Key('kr_rad_0')), findsOneWidget);
    expect(find.byKey(const Key('kr_rad_1')), findsOneWidget);
    expect(find.text(KrCopy.fortsett), findsOneWidget);
    expect(find.text(KrCopy.sePoengene), findsOneWidget);
    // No flying coins are left at the end (the pool painter is gone).
    expect(find.byType(AeMynt), findsNWidgets(2), reason: 'the big coin and the card coin only');
  });

  testWidgets('it runs through on its own: the coins land and the balance counts up', (tester) async {
    _phone(tester);
    final d = KrData.fra(KrData.raderFra(_game([{'reason': 'milestone', 'gate': 1, 'points': 6}, {'reason': 'personal_best', 'gate': null, 'points': 3}])), _b());
    await tester.pumpWidget(_host(PoengKreditert(data: d)));
    await tester.pump();
    // Rows at 1 000 / 1 440 ms, the flight from 2 120 ms, 18 coins × 52 ms + 820 ms → the end at ≈ 3 854 ms.
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('+9'), findsWidgets);
    expect(find.text('1 249'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion opens at the end state', (tester) async {
    _phone(tester);
    final d = KrData.fra([const KrRad(tittel: 'Bøye 1 nådd', under: 'Beste seilas · 236 m', poeng: 3)], _b(available: 1243, earned: 3603));
    await tester.pumpWidget(_host(PoengKreditert(data: d), rolig: true));
    await tester.pump();
    await tester.pump();
    expect(find.text('+3'), findsWidgets);
    expect(find.text('1 243'), findsOneWidget);
  });

  testWidgets('without points/me the card is left out; the rows and the keys stay', (tester) async {
    _phone(tester);
    final d = KrData.fra([const KrRad(tittel: 'Bøye 1 nådd', under: '', poeng: 3)], null);
    await tester.pumpWidget(_host(PoengKreditert(data: d), rolig: true));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('kr_saldo_kort')), findsNothing);
    expect(find.text(KrCopy.fortsett), findsOneWidget);
  });

  testWidgets('once per order: the second visit shows nothing; no points or not yet credited shows nothing', (tester) async {
    _phone(tester);
    final api = FakePointsApi(balanceValue: _b());
    A3Services.points = () => api;
    var visninger = 0;
    late BuildContext ctx;
    await tester.pumpWidget(_host(Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    }), rolig: true));
    final g = _game([{'reason': 'milestone', 'gate': 1, 'points': 6}]);
    final f1 = PoengKreditert.kanskje(ctx, 732, g).then((v) => visninger += v ? 1 : 0);
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('poeng_kreditert')), findsOneWidget);
    expect(prefGetBool(PoengKreditert.prefNokkel(732)), isTrue);
    await tester.tap(find.byKey(const Key('kr_fortsett')));
    await tester.pump();
    await tester.pump();
    await f1;
    expect(find.byKey(const Key('poeng_kreditert')), findsNothing);
    expect(await PoengKreditert.kanskje(ctx, 732, g), isFalse, reason: 'already shown for this order');
    expect(await PoengKreditert.kanskje(ctx, 733, {'best_m': 100, 'gate': null, 'points': 0, 'rows': const []}), isFalse);
    expect(await PoengKreditert.kanskje(ctx, 734, {..._game([{'reason': 'milestone', 'gate': 0, 'points': 3}]), 'credited_at': null}), isFalse, reason: 'not credited yet');
    expect(visninger, 1);
  });
}
