import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/aegil/aegil_app_models.dart';
import 'package:aerend_customer/screens/bergen/meg/a3_services.dart';
import 'package:aerend_customer/screens/bergen/poeng/napp_entry.dart';
import 'package:aerend_customer/screens/bergen/poeng/poeng_entry.dart';
import 'package:aerend_customer/screens/bergen/poeng/premie_ark.dart';

import '../a3/a3_fakes.dart';

/// AGIL-3-PLAN Phase 7 — the Points screens render (Premiehylla, Ægil velger,
/// Liga and Opprykk are covered by test/bergen/meg_step12_test.dart) from the API models alone
/// (points, never kroner), and every action reaches the API.
void main() {
  setUpAll(() => a3Bootstrap());
  tearDown(() => A3Services.reset());

  Future<void> settle(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
  }

  testWidgets('Premie: the claim sheet claims through the API (Gap Step 4: the old page is gone)', (tester) async {
    final api = FakePointsApi();
    late BuildContext ctx;
    await tester.pumpWidget(a3App(Builder(builder: (c) {
      ctx = c;
      return const Scaffold(body: SizedBox());
    })));
    PremieArk.krev(ctx, p: kPrize, poeng: 420, api: api);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Kaffe hos Kaffemisjonen'), findsOneWidget);
    await tester.tap(find.byKey(const Key('hylla-krev-cta')));
    await settle(tester);
    expect(api.calls, contains('claim:7'));
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Napp-kort: Legg til adds through the API, Aldri dette marks never', (tester) async {
    final aegil = FakeAegilApi();
    late BuildContext ctx;
    await tester.pumpWidget(a3App(Builder(builder: (c) {
      ctx = c;
      return const Scaffold(body: SizedBox());
    })));
    const offer = NappOffer(id: '11', title: 'Reker fra Torgboden', storeName: 'Torgboden', priceOre: 14900, reason: 'Dagens napp', kind: 'tilbud');
    showNappKort(ctx, offer, aegil: aegil);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const Key('napp-kort')), findsOneWidget);
    expect(find.text('149 kr'), findsOneWidget);
    await tester.tap(find.byKey(const Key('napp-legg')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(aegil.calls, contains('add:11'));
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Poeng entry card renders the balance (the old hub page went in Gap Step 4)', (tester) async {
    final api = FakePointsApi();
    A3Services.points = () => api;
    await tester.pumpWidget(a3App(Scaffold(body: Column(children: [Builder(builder: poengEntryCard)]))));
    await settle(tester);

    expect(find.byKey(const Key('poeng-entry')), findsOneWidget);
    expect(find.textContaining('420 poeng'), findsWidgets);
  });

  test('AegilPick exposes the prize fields', () {
    const p = AegilPick(prize: {'id': 1, 'name': 'X', 'point_price': 10}, reason: 'r');
    expect(p.prizeId, 1);
    expect(p.pointPrice, 10);
  });
}
