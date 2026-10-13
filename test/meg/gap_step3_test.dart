import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/aegil/aegil_app_models.dart';
import 'package:aerend_customer/data/points/points_models.dart';
import 'package:aerend_customer/data/points/points_rules.dart';
import 'package:aerend_customer/screens/bergen/meg/aegil_logg.dart';
import 'package:aerend_customer/screens/bergen/poeng/premie_ark.dart';

import '../a3/a3_fakes.dart';
import '../layout/reduced_motion_harness.dart';

/// Gap Step 3: «Ægil de siste 30 dagene» (logg), the shared claim sheet
/// (krev) and «Vilkår for premier».
void main() {
  setUpAll(() => bootstrapGlobals(locale: 'no'));

  final naa = DateTime(2026, 10, 13, 18);

  Widget host(Object? Function(BuildContext) knapp) => MaterialApp(
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true, size: const Size(390, 844), textScaler: const TextScaler.linear(.5)),
      child: app!,
    ),
    home: Scaffold(
      body: Builder(
        builder: (c) => Center(
          child: TextButton(onPressed: () => knapp(c), child: const Text('åpne')),
        ),
      ),
    ),
  );

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> apne(WidgetTester tester) async {
    await tester.tap(find.text('åpne'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  test('logg times: today, yesterday, this week, last week, older', () {
    expect(AegilLogg.naar(DateTime(2026, 10, 13, 10), naa), 'i dag 10:00');
    expect(AegilLogg.naar(DateTime(2026, 10, 12, 21, 4), naa), 'i går 21:04');
    expect(AegilLogg.naar(DateTime(2026, 10, 10, 10), naa), 'lørdag 10:00');
    expect(AegilLogg.naar(DateTime(2026, 10, 1, 10), naa), 'forrige torsdag');
    expect(AegilLogg.naar(DateTime(2026, 8, 28, 10), naa), '28. august');
  });

  testWidgets('logg: one row per action, no «angres i 7 dager» claim; empty line without actions', (tester) async {
    phone(tester);
    final api = FakeAegilApi()..actionsValue = [AwayItem(id: 1, text: 'La 4 ting i kurven', action: 'cart.add', at: DateTime(2026, 10, 13, 10))];
    await tester.pumpWidget(host((c) => AegilLogg.vis(c, api: api, naa: naa)));
    await apne(tester);
    expect(find.text('Ægil de siste 30 dagene'), findsOneWidget);
    expect(find.text('Alt Ægil har gjort mens du var borte.'), findsOneWidget);
    expect(find.textContaining('angres'), findsNothing);
    expect(find.text('La 4 ting i kurven'), findsOneWidget);
    expect(find.text('i dag 10:00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('aegil-logg-lukk')));
    await tester.pump(const Duration(milliseconds: 600));
    api.actionsValue = const [];
    await apne(tester);
    expect(find.text(AegilLogg.tom), findsOneWidget);
  });

  testWidgets('krev: the claim sheet with the real validity and the points after', (tester) async {
    phone(tester);
    const p = Prize(id: 1, name: 'Gratis levering', pointPrice: 400, tierBand: 1, tierName: 'Bronse', affordable: true, claimable: true);
    await tester.pumpWidget(host((c) => PremieArk.krev(c, p: p, poeng: 1240, api: FakePointsApi(), gyldigDager: 45)));
    await apne(tester);
    expect(find.byKey(const Key('hylla-krev-sheet')), findsOneWidget);
    expect(find.text('Gjelder i 45 dager'), findsOneWidget);
    expect(find.text('840 poeng'), findsOneWidget);
    expect(find.text('Brukes automatisk på neste levering'), findsOneWidget);
  });

  testWidgets('Vilkår for premier: real rules only, no «Utsolgt … neste måned»', (tester) async {
    phone(tester);
    final regler = PointsRules.fromJson({'kjop_per_10kr': 1, 'claim_expiry_days': 60, 'points_expiry_months': 12});
    expect(regler?.claimExpiryDays, 60);
    expect(regler?.pointsExpiryMonths, 12);
    await tester.pumpWidget(host((c) => PremieArk.vilkaar(c, regler: regler)));
    await apne(tester);
    expect(find.text('Vilkår for premier'), findsOneWidget);
    expect(find.text('En hentet premie gjelder i 60 dager'), findsOneWidget);
    expect(find.text('Utløper 12 måneder etter at de er tjent'), findsOneWidget);
    expect(find.text('Partnerpremier'), findsOneWidget);
    expect(find.text('Utsolgt'), findsNothing);
  });

  testWidgets('Vilkår for premier on an older server: the rule rows hide', (tester) async {
    phone(tester);
    final gammel = PointsRules.fromJson({'kjop_per_10kr': 1});
    expect(gammel?.claimExpiryDays, isNull);
    await tester.pumpWidget(host((c) => PremieArk.vilkaar(c, regler: gammel)));
    await apne(tester);
    expect(find.text('Gyldighet'), findsNothing);
    expect(find.text('Poeng'), findsNothing);
    expect(find.text('Partnerpremier'), findsOneWidget);
  });
}
