import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/aegil/aegil_app_models.dart';
import 'package:aerend_customer/data/aegil/aegil_models.dart';
import 'package:aerend_customer/data/aegil/suggestion_models.dart';
import 'package:aerend_customer/data/ops/kasse_models.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/networking/ops/ops_kasse_api.dart';
import 'package:aerend_customer/screens/bergen/aegil/aegil_guide.dart';
import 'package:aerend_customer/screens/bergen/aegil/aegil_launch_copy.dart';
import 'package:aerend_customer/screens/bergen/aegil/aegil_screen.dart';
import 'package:aerend_customer/screens/bergen/hurtig/hurtig_data.dart';
import 'package:aerend_customer/screens/bergen/meg/a3_services.dart';

import '../a3/a3_fakes.dart';

/// Launch UI Step 11: Ægil (`erAgent` L4500–5120) against the Launch
/// prototype — the start view from real data, the chat on `agent/chat` with
/// each reply state's card, the composer morph, the basket strip, Det Ægil
/// vet om deg, Så mye kan Ægil gjøre, the onboarding, and the Ægil-guide.

class _Kasse extends OpsKasseApi {
  _Kasse([this.kurv = const KurvState()]);
  final KurvState kurv;

  @override
  Future<KurvState> cart() async => kurv;
}

class _Kunde extends OpsCustomerApi {
  @override
  Future<List<Map<String, dynamic>>> orders({int limit = 50}) async => const [];
}

class _FeilApi extends FakeAegilApi {
  @override
  Future<AegilTurn?> chat({String? text, String? intent, int? storeId}) async => throw Exception('offline');
}

const _kurvTurn = AegilTurn(
  state: 'agForslag',
  reply: 'Jeg fant det i Vågen og la det klart. Du betaler alltid selv.',
  basket: AegilBasket(
    lines: [
      AegilBasketLine(name: 'Tortilla', qty: 2, priceOre: 2990, storeProductId: 501, storeId: 3, storeName: 'Torgboden', suggestionId: 11),
      AegilBasketLine(name: 'Kjøttdeig', qty: 1, priceOre: 7990, storeProductId: 502, storeId: 3, storeName: 'Torgboden'),
    ],
    storeName: 'Torgboden',
    storeId: 3,
    subtotalOre: 13970,
    derfor: 'Billigst av tre',
  ),
  cards: [Suggestion(id: 11, reasonCode: 'offer', reason: 'Tilbud', headline: 'Tortilla', storeId: 3, storeProductId: 501), kSuggestion2],
);

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

Widget _app(Widget w) => MaterialApp(home: w);

Future<void> _tapV(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
}

AegilScreen _skjerm({FakeAegilApi? api, FakeAegilRepo? repo, String? steg, KurvState kurv = const KurvState()}) =>
    AegilScreen(api: api ?? FakeAegilApi(turn: _kurvTurn), repo: repo ?? FakeAegilRepo(), steg: steg, kasseApi: _Kasse(kurv), customerApi: _Kunde());

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

  tearDown(() {
    A3Services.reset();
    HurtigKilde.reset();
  });

  group('Start', () {
    testWidgets('the greeting by name, what Ægil remembers, the three asks', (tester) async {
      _frame(tester);
      await tester.pumpWidget(_app(_skjerm(steg: 'start')));
      await _settle(tester);

      expect(find.text(AeCopy.lytter), findsOneWidget);
      expect(find.textContaining('Kari'), findsWidgets);
      expect(find.byKey(const Key('a1_aegil_husker')), findsOneWidget);
      expect(find.textContaining('Reker', findRichText: true), findsOneWidget);
      expect(find.text(AeCopy.taco), findsOneWidget);
      expect(find.text(AeCopy.gave), findsOneWidget);
      expect(find.text(AeCopy.foreslaa), findsOneWidget);
      // No delivered order: no «Ægil tipper».
      expect(find.byKey(const Key('a1_aegil_tipper')), findsNothing);
    });

    testWidgets('an empty memory offers to start one; «Ægil tipper» is the last order', (tester) async {
      _frame(tester);
      HurtigKilde.cache.value = HurtigData(
        hist: [
          HbOrdre(
            id: 9,
            kode: 'Æ-9',
            butikkId: 3,
            butikk: 'Torgboden',
            naar: DateTime.now().subtract(const Duration(days: 7)),
            sum: 402,
            linjer: const [HbOrdreLinje(id: 501, ant: 2, navn: 'Tortilla', pris: 59.8)],
          ),
        ],
        meny: const {},
        butikker: const {},
        minne: const HbMinne(),
        adresse: 'Nygårdsgaten 5',
        adresseId: 1,
        navn: 'Kari',
      );
      final repo = FakeAegilRepo()..memory = const [];
      await tester.pumpWidget(_app(_skjerm(repo: repo, steg: 'start')));
      await _settle(tester);

      expect(find.byKey(const Key('a1_aegil_minne_tilbud')), findsOneWidget);
      expect(find.byKey(const Key('a1_aegil_tipper')), findsOneWidget);
      expect(find.text('402 kr'), findsOneWidget);
      expect(find.text('Nygårdsgaten 5'), findsOneWidget);
      expect(find.text(AeCopy.pleier), findsOneWidget);
    });

    testWidgets('the first visit shows who Ægil is', (tester) async {
      _frame(tester);
      await tester.pumpWidget(_app(_skjerm(steg: 'tillatelse')));
      await _settle(tester);
      expect(find.text(AeCopy.tlTittel), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('a1_aegil_kom_i_gang')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('a1_aegil_kom_i_gang')));
      await _settle(tester);
      expect(find.text(AeCopy.beOm), findsOneWidget);
    });
  });

  group('Chat', () {
    testWidgets('an ask → Ægil thinks → the basket card; nothing is added until a tap', (tester) async {
      _frame(tester);
      final api = FakeAegilApi(turn: _kurvTurn);
      await tester.pumpWidget(_app(_skjerm(api: api, steg: 'start')));
      await _settle(tester);

      await tester.tap(find.byKey(const Key('a1_aegil_be_0')));
      await tester.pump();
      expect(api.calls, contains('chat:${AeCopy.tacoSi}'));
      expect(find.text(AeCopy.skriver), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.text(AeCopy.fantNoe), findsOneWidget);
      expect(find.byKey(const Key('a1_aegil_legg_alt')), findsOneWidget);
      expect(find.text('Torgboden'), findsWidgets);
      expect(find.text(AeCopy.varer(3)), findsOneWidget);
      expect(find.text('140 kr'), findsOneWidget);
      expect(find.textContaining('billigst av tre'), findsOneWidget);
      // The tray's other card, not repeated in the basket card.
      expect(find.text('Tacokveld for fire'), findsOneWidget);
      expect(find.text(AeCopy.allergen), findsOneWidget);
      expect(api.calls.where((c) => c.startsWith('add:')), isEmpty);
      expect(find.byKey(const Key('a1_aegil_forslag_0')), findsOneWidget);
    });

    testWidgets('18+ is said plainly, with BankID', (tester) async {
      _frame(tester);
      final api = FakeAegilApi(turn: const AegilTurn(state: 'agAldersblokk', reply: '18+ · ikke verifisert.', ageGate: true));
      await tester.pumpWidget(_app(_skjerm(api: api, steg: 'start')));
      await _settle(tester);
      await tester.enterText(find.byKey(const Key('a1_aegil_felt')), 'seks øl');
      await tester.pump();
      await tester.tap(find.byKey(const Key('a1_aegil_send')));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.text(AeCopy.beklager), findsOneWidget);
      expect(find.text(AeCopy.alderTittel), findsOneWidget);
      expect(find.text(AeCopy.bankId), findsOneWidget);
    });

    testWidgets('a greeting is answered by Ægil, not as «not found»', (tester) async {
      _frame(tester);
      final api = FakeAegilApi(turn: const AegilTurn(state: 'agIkkeFunnet', reply: 'Fant ikke noe i Vågen for det.'));
      await tester.pumpWidget(_app(_skjerm(api: api, steg: 'start')));
      await _settle(tester);
      await tester.enterText(find.byKey(const Key('a1_aegil_felt')), 'hei');
      await tester.pump();
      await tester.tap(find.byKey(const Key('a1_aegil_send')));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.text(AeCopy.ikkeFunnet), findsNothing);
      expect(find.textContaining('Heisann,'), findsWidgets);

      await tester.enterText(find.byKey(const Key('a1_aegil_felt')), 'xyz');
      await tester.pump();
      await tester.tap(find.byKey(const Key('a1_aegil_send')));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.text(AeCopy.ikkeFunnet), findsOneWidget);
    });

    testWidgets('offline, Ægil says so; «Ny prat» starts over', (tester) async {
      _frame(tester);
      await tester.pumpWidget(_app(_skjerm(api: _FeilApi(), steg: 'start')));
      await _settle(tester);
      await tester.enterText(find.byKey(const Key('a1_aegil_felt')), 'taco');
      await tester.pump();
      await tester.tap(find.byKey(const Key('a1_aegil_send')));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.textContaining('kontakt'), findsWidgets);
      await tester.ensureVisible(find.byKey(const Key('a1_aegil_ny_prat')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('a1_aegil_ny_prat')));
      await _settle(tester);
      expect(find.text(AeCopy.beOm), findsOneWidget);
    });

    testWidgets('the composer morphs on focus; the basket strip shows the real basket', (tester) async {
      _frame(tester);
      const kurv = KurvState(
        storeId: 3,
        lines: [KurvLine(cartId: 1, productId: 501, name: 'Tortilla', quantity: 2, unitPrice: 29.9, storeId: 3)],
      );
      await tester.pumpWidget(_app(_skjerm(steg: 'start', kurv: kurv)));
      await _settle(tester);
      expect(find.byKey(const Key('a1_aegil_lukk')), findsOneWidget);
      final w0 = tester.getSize(find.byKey(const Key('a1_aegil_send'))).width;
      await tester.showKeyboard(find.byKey(const Key('a1_aegil_felt')));
      await tester.pump(const Duration(milliseconds: 700));
      final w1 = tester.getSize(find.byKey(const Key('a1_aegil_send'))).width;
      expect(w0, closeTo(92, 1));
      expect(w1, closeTo(46, 1));

      // The strip only with the chat up.
      expect(find.byKey(const Key('a1_aegil_kurv')), findsNothing);
      await tester.enterText(find.byKey(const Key('a1_aegil_felt')), 'taco');
      await tester.pump();
      await tester.tap(find.byKey(const Key('a1_aegil_send')));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byKey(const Key('a1_aegil_kurv')), findsOneWidget);
      expect(find.text(AeCopy.kurvAnt(2)), findsOneWidget);
      expect(find.text(AeCopy.betalVipps), findsOneWidget);
    });
  });

  group('Minne, nivå, onboarding', () {
    testWidgets('Det Ægil vet om deg: groups, Fjern, Glem alt', (tester) async {
      _frame(tester);
      final repo = FakeAegilRepo();
      await tester.pumpWidget(_app(_skjerm(repo: repo, steg: 'minne')));
      await _settle(tester);
      expect(find.text(AeCopy.minneTittel), findsOneWidget);
      expect(find.text(AeCopy.duLiker), findsOneWidget);
      expect(find.text('Ingen nøtter'), findsOneWidget);
      expect(find.text(AeCopy.brukesAlltid), findsOneWidget);

      await tester.tap(find.text(AeCopy.fjern).first);
      await tester.pump();
      expect(find.text('Reker'), findsNothing);

      await tester.ensureVisible(find.byKey(const Key('a1_aegil_glem')));
      await tester.tap(find.byKey(const Key('a1_aegil_glem')));
      await _settle(tester);
      expect(repo.calls, contains('forget'));
      expect(find.text(AeCopy.minneTom), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('Så mye kan Ægil gjøre: levels and limits go to the settings', (tester) async {
      _frame(tester);
      final repo = FakeAegilRepo();
      await tester.pumpWidget(_app(_skjerm(repo: repo, steg: 'nivaa')));
      await _settle(tester);
      expect(find.text(AeCopy.nivaaTittel), findsOneWidget);
      expect(find.text('2 · Varsle og foreslå'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('a1_aegil_ramme_4')));
      await tester.tap(find.byKey(const Key('a1_aegil_ramme_4')));
      await _settle(tester);
      expect(repo.calls.any((c) => c.contains('learning_enabled')), isTrue);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('the five questions are stored as explicit choices', (tester) async {
      _frame(tester);
      final repo = FakeAegilRepo();
      await tester.pumpWidget(_app(_skjerm(repo: repo, steg: 'ob1')));
      await _settle(tester);
      expect(find.text(AeCopy.ob1), findsOneWidget);
      await _tapV(tester, find.text(AeCopy.kat[1]));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(AeCopy.poeng(5)), findsOneWidget);
      await _tapV(tester, find.byKey(const Key('a1_aegil_ob_neste')));
      await _settle(tester);
      expect(find.text(AeCopy.ob2), findsOneWidget);
      await _tapV(tester, find.byKey(const Key('a1_aegil_ob_hopp')));
      await _settle(tester);
      await _tapV(tester, find.byKey(const Key('a1_aegil_ob_hopp')));
      await _settle(tester);
      expect(find.text(AeCopy.ob4), findsOneWidget);
      await _tapV(tester, find.text('2'));
      await _tapV(tester, find.text(AeCopy.kost[3]));
      await tester.pump(const Duration(milliseconds: 500));
      await _tapV(tester, find.byKey(const Key('a1_aegil_ob_neste')));
      await _settle(tester);
      await _tapV(tester, find.text(AeCopy.dager[3]));
      await tester.pump(const Duration(milliseconds: 500));
      await _tapV(tester, find.byKey(const Key('a1_aegil_ob_neste')));
      await _settle(tester);
      expect(find.text(AeCopy.sumTittel), findsOneWidget);
      await _tapV(tester, find.byKey(const Key('a1_aegil_ob_stemmer')));
      await _settle(tester);
      final chips = repo.calls.firstWhere((c) => c.startsWith('chips:'));
      expect(chips, contains('kategori:mat og fisk'));
      expect(chips, contains('skalldyr'));
      expect(chips, contains('torsdag'));
      expect(find.text(AeCopy.nivaaTittel), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('Ægil-guide', () {
    testWidgets('walks in after 1.5 s, steps through the tips, and leaves', (tester) async {
      _frame(tester);
      await tester.pumpWidget(
        _app(Scaffold(body: Stack(children: [Positioned.fill(child: AegilGuide(skjerm: 'kategori', tips: aegilGuideTips('kategori'), nav: false))]))),
      );
      await tester.pump(const Duration(milliseconds: 1400));
      expect(find.byKey(const Key('a1_guide_aegil')), findsNothing);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(AeCopy.gKategori1), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      await tester.tap(find.byKey(const Key('a1_guide_neste')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(AeCopy.gKategori2), findsOneWidget);
      expect(find.text(AeCopy.gSkjonner), findsOneWidget);
      await tester.tap(find.byKey(const Key('a1_guide_lukk')));
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('a1_guide_aegil')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    test('the basket tips use the store\'s own threshold', () {
      final t = aegilGuideTips('kurv', sum: 240, gratisOver: 300);
      expect(t.first.tx, AeCopy.gKurvIgjen(60));
      expect(aegilGuideTips('kurv').first.tx, AeCopy.gKurvTom);
      // No threshold known: no free-delivery tip.
      expect(aegilGuideTips('butikk').length, 1);
    });
  });
}
