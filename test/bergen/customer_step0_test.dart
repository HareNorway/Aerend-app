import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/aegil/aegil_models.dart';
import 'package:aerend_customer/data/aegil/aegil_repo.dart';
import 'package:aerend_customer/data/aegil/against_interest_models.dart';
import 'package:aerend_customer/data/ops/kasse_models.dart';
import 'package:aerend_customer/data/points/points_rules.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/networking/ops/ops_kasse_api.dart';
import 'package:aerend_customer/screens/bergen/aegil/aegil_guide.dart';
import 'package:aerend_customer/screens/bergen/aegil/aegil_innst.dart';
import 'package:aerend_customer/screens/bergen/aegil/aegil_kontekst.dart';
import 'package:aerend_customer/screens/bergen/aegil/aegil_screen.dart';
import 'package:aerend_customer/screens/bergen/hjem/hjem_kaien.dart';
import 'package:aerend_customer/screens/bergen/hurtig/hurtig_data.dart';
import 'package:aerend_customer/screens/bergen/meg/a3_services.dart';
import 'package:aerend_customer/screens/bergen/meg/meg_paaminnelser.dart';
import 'package:aerend_customer/screens/common/splash/splash.dart';
import 'package:aerend_customer/utils/route_names.dart';
import 'package:aerend_customer/utils/shared_pref_utill.dart';

import '../a3/a3_fakes.dart';

/// Customer plan Step 0: the Ægil fixes (D-K20) — the route's context goes
/// with the chat and nothing stands in for an unasked question; «Ikke nå»
/// comes back after the re-invite days; levels above the rollout cap are not
/// offered; the composer has no mic (D-K2); the reminders sheet; Under
/// kaien's line opens the Brett; route names without Snurre (D-K1).

class _Kasse extends OpsKasseApi {
  @override
  Future<KurvState> cart() async => const KurvState();
}

class _Kunde extends OpsCustomerApi {
  @override
  Future<List<Map<String, dynamic>>> orders({int limit = 50}) async => const [];

  @override
  Future<PointsRules?> rules() async => null;
}

class _Paam extends AegilRepo {
  _Paam(this.items);

  List<AgentReminderItem>? items;
  final List<int> avsluttet = [];

  @override
  Future<List<AgentReminderItem>?> reminders() async => items;

  @override
  Future<bool> cancelReminder(AgentReminderItem r) async {
    avsluttet.add(r.id);
    return true;
  }
}

void _frame(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 700));
}

/// Ægil pushed the way `BergenRoutes` does: the arguments on the route.
Widget _medArgs(Map<String, String> args, {FakeAegilApi? api, FakeAegilRepo? repo}) => MaterialApp(
  onGenerateRoute: (_) => MaterialPageRoute<void>(
    settings: RouteSettings(name: '/', arguments: args),
    builder: (_) => AegilScreen(api: api ?? FakeAegilApi(), repo: repo ?? FakeAegilRepo(), steg: 'start', kasseApi: _Kasse(), customerApi: _Kunde()),
  ),
);

Future<void> _skriv(WidgetTester tester, String t) async {
  await tester.enterText(find.byKey(const Key('a1_aegil_felt')), t);
  await tester.testTextInput.receiveAction(TextInputAction.send);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pump(const Duration(milliseconds: 1500));
}

void main() {
  setUpAll(() async {
    await a3Bootstrap(prefs: {'flutter.${AegilScreen.prefTillatelse}': true, AegilScreen.prefTillatelse: true});
    OpsCustomerApi.networkEnabled = false;
  });

  setUp(() {
    A3Services.points = () => FakePointsApi();
    HurtigKilde.memory = () async => const <MemoryEntry>[];
    AegilGuide.reset();
  });

  tearDown(() async {
    A3Services.reset();
    HurtigKilde.reset();
    await prefRemove(AegilScreen.prefAvslaattDato);
    await prefRemove(AegilScreen.prefAvslaatt);
  });

  group('D-K20: the route context', () {
    testWidgets('a store «Spør Ægil» opens with the store chip and asks nothing', (tester) async {
      _frame(tester);
      final api = FakeAegilApi();
      await tester.pumpWidget(_medArgs({'intent': 'store', 'store_id': '43', 'store': 'Torgboden'}, api: api));
      await _settle(tester);

      // The taco bug: no stand-in question is sent.
      expect(api.calls, isEmpty);
      expect(find.text('Om Torgboden'), findsOneWidget);

      await _skriv(tester, 'Har dere reker?');
      expect(api.chats.single, {'text': 'Har dere reker?', 'intent': 'store', 'store_id': 43, 'category': null, 'for': null});

      // The intent goes with the first line only; the store stays.
      await _skriv(tester, 'Og sitron?');
      expect(api.chats.last['intent'], isNull);
      expect(api.chats.last['store_id'], 43);

      // × talks about anything again.
      await tester.ensureVisible(find.byKey(const Key('cus_aegil_ktx_fjern')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('cus_aegil_ktx_fjern')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('cus_aegil_ktx')), findsNothing);
      await _skriv(tester, 'Noe annet');
      expect(api.chats.last['store_id'], isNull);
    });

    testWidgets('a category and a gift are named in the chip and sent', (tester) async {
      _frame(tester);
      final api = FakeAegilApi();
      await tester.pumpWidget(_medArgs({'intent': 'gift', 'store_id': '5', 'store': 'Kollektivet', 'for': 'Mamma'}, api: api));
      await _settle(tester);
      expect(api.calls, isEmpty);
      expect(find.text('Gave til Mamma · Kollektivet'), findsOneWidget);
      await _skriv(tester, 'Noe til 300 kr');
      expect(api.chats.single['intent'], 'gift');
      expect(api.chats.single['for'], 'Mamma');

      expect(AeKontekst.fra(const {'intent': 'category', 'category': 'Bakeri'})!.etikett, 'Om Bakeri');
      expect(AeKontekst.fra(const {'q': 'sushi'}), isNull);
    });

    testWidgets('a question from Søk is sent as asked, without a chip', (tester) async {
      _frame(tester);
      final api = FakeAegilApi();
      await tester.pumpWidget(_medArgs({'q': 'sushi i kveld'}, api: api));
      await _settle(tester);
      await tester.pump(const Duration(milliseconds: 2500));
      expect(api.calls, ['chat:sushi i kveld']);
      expect(find.byKey(const Key('cus_aegil_ktx')), findsNothing);
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('D-K20: «Ikke nå» comes back', () {
    test('the window is the re-invite days', () {
      final naa = DateTime(2026, 10, 21, 12);
      expect(AegilScreen.avslaattGjelder(null, 7, naa), isFalse);
      expect(AegilScreen.avslaattGjelder(naa.subtract(const Duration(days: 2)), 7, naa), isTrue);
      expect(AegilScreen.avslaattGjelder(naa.subtract(const Duration(days: 8)), 7, naa), isFalse);
      expect(AegilScreen.avslaattGjelder(naa.subtract(const Duration(days: 2)), 1, naa), isFalse);
    });

    testWidgets('«Ikke nå» stores today and hides the offer; an old one shows it again', (tester) async {
      _frame(tester);
      final repo = FakeAegilRepo()..memory = const [];
      await tester.pumpWidget(_medArgs(const {}, repo: repo));
      await _settle(tester);
      expect(find.byKey(const Key('a1_aegil_minne_tilbud')), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('a1_aegil_ikke_naa')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('a1_aegil_ikke_naa')));
      await _settle(tester);
      expect(find.byKey(const Key('a1_aegil_minne_tilbud')), findsNothing);
      final lagret = DateTime.parse(prefGetString(AegilScreen.prefAvslaattDato));
      expect(DateTime.now().difference(lagret).inMinutes, lessThan(1));

      await prefSetString(AegilScreen.prefAvslaattDato, DateTime.now().subtract(const Duration(days: 8)).toIso8601String());
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_medArgs(const {}, repo: FakeAegilRepo()..memory = const []));
      await _settle(tester);
      expect(find.byKey(const Key('a1_aegil_minne_tilbud')), findsOneWidget);
    });

    testWidgets('a «for good» from before starts the wait now', (tester) async {
      _frame(tester);
      await prefSetBool(AegilScreen.prefAvslaatt, true);
      await tester.pumpWidget(_medArgs(const {}, repo: FakeAegilRepo()..memory = const []));
      await _settle(tester);
      expect(find.byKey(const Key('a1_aegil_minne_tilbud')), findsNothing);
      expect(prefGetString(AegilScreen.prefAvslaattDato), isNotEmpty);
      expect(prefGetBool(AegilScreen.prefAvslaatt), isFalse);
    });
  });

  group('D-K20: the rollout cap', () {
    test('the settings carry the cap, the acting level and the re-invite days', () {
      final s = AegilSettings.fromJson(const {'level': 3, 'level_cap': 2, 'effective_level': 2, 'reinvite_days': 3});
      expect(s.levelCap, 2);
      expect(s.effectiveLevel, 2);
      expect(s.reinviteDays, 3);
      expect(s.tillatt(2), isTrue);
      expect(s.tillatt(3), isFalse);
      expect(AegilSettings.fromJson(const {'level': 2}).reinviteDays, 7);
      expect(AegilSettings.fromJson(const {'level': 2}).tillatt(4), isTrue);
    });

    testWidgets('a level above the cap is shown as not open, and is not sent', (tester) async {
      _frame(tester);
      final endret = <Map<String, dynamic>>[];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AegilInnstListe(
              settings: const AegilSettings(level: 2, levelCap: 2),
              levels: const [],
              onEndre: (e, {toast}) async => endret.add(e),
              onButikker: () async {},
            ),
          ),
        ),
      ));
      await _settle(tester);
      final rad3 = find.byKey(const Key('ae-innst-nivaa-3'));
      expect(find.descendant(of: rad3, matching: find.text(AeInnstCopy.cus_aegil_nivaa_ikke_enna)), findsOneWidget);
      await tester.tap(rad3);
      await tester.pump(const Duration(milliseconds: 300));
      expect(endret, isEmpty);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('a capped level says what Ægil acts as', (tester) async {
      _frame(tester);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AegilInnstListe(
              settings: const AegilSettings(level: 3, levelCap: 2, effectiveLevel: 2),
              levels: const [],
              onEndre: (e, {toast}) async {},
              onButikker: () async {},
            ),
          ),
        ),
      ));
      await _settle(tester);
      expect(find.text(AeInnstCopy.cus_aegil_nivaa_virker_som(3, 2)), findsOneWidget);
    });
  });

  group('D-K2: no mic', () {
    testWidgets('the empty orange key focuses the field instead of a voice toast', (tester) async {
      _frame(tester);
      await tester.pumpWidget(_medArgs(const {}));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('a1_aegil_send')));
      await tester.pump(const Duration(milliseconds: 300));
      final felt = tester.widget<TextField>(find.byKey(const Key('a1_aegil_felt')));
      expect(felt.focusNode!.hasFocus, isTrue);
      expect(find.textContaining('hold inne'), findsNothing);
    });
  });

  group('Meg: Påminnelser', () {
    Future<void> apne(WidgetTester tester, AegilRepo repo) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (c) => Scaffold(body: TextButton(onPressed: () => visPaaminnelser(c, repo: repo), child: const Text('åpne')))),
      ));
      await tester.tap(find.text('åpne'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }

    testWidgets('lists the price reminders and subscriptions; a tap stops one', (tester) async {
      _frame(tester);
      final repo = _Paam([
        const AgentReminderItem(id: 4, kind: 'wait_for_offer', productName: 'Reker 1 kg', targetPriceOre: 14900),
        AgentReminderItem(id: 9, kind: AegilRepo.kAvailabilityKind, productName: 'Kanelboller', expiresAt: DateTime(2026, 11, 3)),
      ]);
      await apne(tester, repo);
      expect(find.text('Reker 1 kg'), findsOneWidget);
      expect(find.text(CusPaaminnelserCopy.cus_paam_pris_under(149)), findsOneWidget);
      expect(find.text('Kanelboller'), findsOneWidget);
      expect(find.textContaining(CusPaaminnelserCopy.cus_paam_lager), findsOneWidget);

      await tester.tap(find.byKey(const Key('cus-paam-wait_for_offer-4')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(repo.avsluttet, [4]);
      expect(find.text('Reker 1 kg'), findsNothing);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('empty: says so', (tester) async {
      _frame(tester);
      await apne(tester, _Paam(const []));
      expect(find.text(CusPaaminnelserCopy.cus_paam_tom), findsOneWidget);
    });
  });

  testWidgets('Under kaien: the line opens the Brett when there are finds', (tester) async {
    _frame(tester);
    var apnet = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: HjemUnderKaien(vist: true, onLinje: () => apnet++))));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byKey(const Key('cus_kaien_brett')));
    expect(apnet, 1);
    await tester.pumpWidget(const SizedBox());
  });

  test('D-K1: route names carry no Snurre', () {
    expect(routeNameFor(const Splash()), '${appRoutePrefix}splash');
    expect(appRoutePrefix.toLowerCase(), isNot(contains('snurre')));
    expect(isAppRoute(MaterialPageRoute<void>(settings: const RouteSettings(name: '${appRoutePrefix}ark'), builder: (_) => const SizedBox())), isTrue);
    expect(isAppRoute(MaterialPageRoute<void>(builder: (_) => const SizedBox())), isFalse);
  });
}
