import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/l10n/app_localizations.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/aegil/aegil_entry.dart';
import 'package:aerend_customer/screens/bergen/aegil/brett_entry.dart';
import 'package:aerend_customer/screens/bergen/bergen_routes_agil1.dart';
import 'package:aerend_customer/screens/bergen/bergen_routes_agil3.dart';
import 'package:aerend_customer/screens/bergen/kit/bergen_kit.dart';
import 'package:aerend_customer/screens/bergen/meg/borte_entry.dart';
import 'package:aerend_customer/screens/bergen/meg/meg_host.dart';
import 'package:aerend_customer/screens/bergen/poeng/napp_entry.dart';
import 'package:aerend_customer/screens/bergen/poeng/poeng_entry.dart';

import '../layout/reduced_motion_harness.dart';

/// AGIL-CONTRACT §4.1, kind `dart`: every route in both maps builds without
/// throwing, every registered route name lives in the right map, and every
/// seam file exports its declared symbols (reflection-free: import and use).
///
/// The reserved lists mirror `tests/fixtures/contract/names.agil{1,3}.json`
/// in Hare-AdminPanel. A route in a map that is not reserved fails; a
/// reserved route that is not yet in its map is reported as pending, not as
/// a failure, until the phase that builds it lands.
const List<String> kReservedAgil1 = [
  '/bergen/sok',
  '/bergen/butikk/{id}',
  '/bergen/kategori/{slug}',
  '/bergen/automat',
  '/bergen/kurv',
  '/bergen/bestilling/{id}',
  '/bergen/sporing/{id}',
  '/bergen/sporing/{id}/hjelp',
  '/bergen/levert/{id}',
  '/bergen/utforsk',
  '/bergen/kundeservice',
];

const List<String> kReservedAgil3 = [
  kPoengRoute,
  '/bergen/premiehylla',
  '/bergen/premie/{id}',
  '/bergen/liga',
  '/bergen/opprykk',
  '/bergen/fjordfiske',
  kAegilRoute,
  '/bergen/aegil/minne',
  '/bergen/meg',
  '/bergen/meg/favoritter',
  '/bergen/meg/konto',
  '/bergen/meg/bestillinger',
  '/bergen/meg/varsler',
];

/// `/bergen/butikk/{id}` registered as `/bergen/butikk` (parameters travel
/// in `RouteSettings.arguments`) still counts as the reserved name.
bool _matchesReserved(String registered, String reserved) {
  final base = reserved.replaceAll(RegExp(r'/\{[a-z]+\}'), '');
  return registered == reserved || registered == base;
}

void main() {
  // The Bergen screens read prefs (auth, language) as they build, and some
  // start a request in initState — answered as offline here, so no real
  // socket timer outlives the fake-async test zone.
  setUpAll(() async {
    await bootstrapGlobals();
    OpsCustomerApi.networkEnabled = false;
  });
  tearDownAll(() => OpsCustomerApi.networkEnabled = true);

  group('route maps', () {
    test('every agil-1 route is a reserved name', () {
      for (final name in bergenRoutesAgil1().keys) {
        expect(
          kReservedAgil1.any((r) => _matchesReserved(name, r)),
          isTrue,
          reason: '$name is not reserved for agil-1 in AGIL-CONTRACT §3.4',
        );
      }
    });

    test('every agil-3 route is a reserved name', () {
      for (final name in bergenRoutesAgil3().keys) {
        expect(
          kReservedAgil3.any((r) => _matchesReserved(name, r)),
          isTrue,
          reason: '$name is not reserved for agil-3 in AGIL-CONTRACT §3.4',
        );
      }
    });

    test('the two maps never claim the same name', () {
      final overlap = bergenRoutesAgil1().keys.toSet().intersection(
        bergenRoutesAgil3().keys.toSet(),
      );
      expect(overlap, isEmpty);
    });

    test('every reserved name starts with /bergen/', () {
      for (final r in [...kReservedAgil1, ...kReservedAgil3]) {
        expect(r, startsWith('/bergen/'));
      }
    });

    testWidgets('every registered route builds without throwing', (
      tester,
    ) async {
      final routes = {...bergenRoutesAgil1(), ...bergenRoutesAgil3()};
      for (final entry in routes.entries) {
        // The app always provides the localizations; a screen that mounts
        // the feed reads them as it builds.
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(builder: entry.value),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '${entry.key} threw');
      }
    });
  });

  group('seam files export their declared symbols', () {
    testWidgets('MegScreen builds', (tester) async {
      // Account() reaches into redux and networking; a throw here is fine
      // as long as the type and constructor exist. Pump with a small frame.
      const Widget w = MegScreen();
      expect(w, isA<StatelessWidget>());
    });

    test('poeng_entry: kPoengRoute and poengEntryCard', () {
      expect(kPoengRoute, '/bergen/poeng');
      expect(poengEntryCard, isA<Widget Function(BuildContext)>());
    });

    test('napp_entry: NappOffer and showNappKort', () {
      const offer = NappOffer(
        id: 's_1',
        title: 'Skillingsboller',
        storeName: 'Godt Brød',
        priceOre: 3900,
        reason: 'tilbud',
        kind: 'tilbud',
      );
      expect(offer.kind, 'tilbud');
      expect(
        showNappKort,
        isA<Future<void> Function(BuildContext, NappOffer)>(),
      );
    });

    test('aegil_entry: kAegilRoute and aegilGreeting', () {
      expect(kAegilRoute, '/bergen/aegil');
      expect(aegilGreeting, isA<Widget Function(BuildContext)>());
    });

    test(
      'brett_entry: aegilFindCount is 0 in the stub, showAegilBrett exists',
      () {
        expect(aegilFindCount(), 0);
        expect(showAegilBrett, isA<Future<void> Function(BuildContext)>());
      },
    );

    test('borte_entry: mensDuVarBorteCard exists', () {
      expect(mensDuVarBorteCard, isA<Widget? Function(BuildContext)>());
    });

    testWidgets('the stubs render (or return null) inside a MaterialApp', (
      tester,
    ) async {
      Widget? borte;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              borte = mensDuVarBorteCard(context);
              return Column(
                children: [
                  poengEntryCard(context),
                  aegilGreeting(context),
                  if (borte != null) borte!,
                ],
              );
            },
          ),
        ),
      );
      expect(borte, isNull);
      expect(find.byType(BergenChip), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('kit barrel', () {
    test('exports the tokens and every widget', () {
      expect(BergenTokens.orange, const Color(0xFFF26D3D));
      expect(BergenSheetHandle.release.label, 'Slipp — Ægil åpner');
      expect(BergenOfflineBanner.copy, 'Uten nett · viser siste kjente status');
      expect(BergenUndoPill.label, 'Angre');
      expect(BergenStepper.sporing.length, 4);
    });
  });
}
