import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/aegil/aegil_models.dart';
import 'package:aerend_customer/data/ops/kasse_models.dart';
import 'package:aerend_customer/networking/ops/ops_butikk_api.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/networking/ops/ops_kasse_api.dart';
import 'package:aerend_customer/screens/bergen/hurtig/hurtig_brain.dart';
import 'package:aerend_customer/screens/bergen/hurtig/hurtig_copy.dart';
import 'package:aerend_customer/screens/bergen/hurtig/hurtig_data.dart';
import 'package:aerend_customer/screens/bergen/hurtig/hurtig_bits.dart';
import 'package:aerend_customer/screens/bergen/hurtig/hurtig_kort.dart';
import 'package:aerend_customer/screens/bergen/hurtig/hurtig_screen.dart';
import 'package:aerend_customer/screens/common/manageAddress/manage_address_dl.dart';

import '../layout/reduced_motion_harness.dart';

/// Step 7 (Hurtigbestilling): Ægil's reasoning over a real-shaped history
/// and the screen's states — the welcome, the three module cards, the draft
/// with its steppers, the countdown and Angre, and the basket hand-off.

// A Thursday evening in Bergen.
final DateTime kNow = DateTime(2026, 10, 8, 17, 30);

const _tb = HbButikk(id: 1, navn: 'Torgboden', ini: 'TB', bg: Color(0xFF2A6272), min: 25);
const _fw = HbButikk(id: 2, navn: 'Fyllingsdalen Wok', ini: 'FW', bg: Color(0xFF8A5A1E), min: 35);
const _cm = HbButikk(id: 3, navn: 'Casa Maria', ini: 'CM', bg: Color(0xFFB0472C), min: 30);
const _mp = HbButikk(id: 4, navn: 'Møhlenpris Pizza', ini: 'MP', bg: Color(0xFF7A3B2A), min: 30, aapen: false, aapner: '10:00');

HbVare _v(int id, String navn, HbButikk b, double pris, {bool hoved = false, bool skalldyr = false, List<String>? ord}) =>
    HbVare(id: id, navn: navn, butikkId: b.id, butikk: b.navn, pris: pris, ord: ord ?? [navn.toLowerCase()], hoved: hoved, skalldyr: skalldyr);

final Map<int, HbVare> _meny = {
  101: _v(101, 'Fiskesuppe', _tb, 149, hoved: true, ord: ['fiskesuppe', 'suppe']),
  102: _v(102, 'Hjemmelaget brød', _tb, 49, ord: ['hjemmelaget brød', 'brød']),
  103: _v(103, 'Reker 500 g', _tb, 179, hoved: true, skalldyr: true, ord: ['reker 500 g', 'reker']),
  104: _v(104, 'Sitron', _tb, 9, ord: ['sitron']),
  201: _v(201, 'Pad thai med kylling', _fw, 189, hoved: true, ord: ['pad thai med kylling', 'pad thai', 'thai']),
  202: _v(202, 'Vårruller, 4 stk', _fw, 69, ord: ['vårruller', 'vårrull']),
  301: _v(301, 'Margherita', _cm, 129, hoved: true, ord: ['margherita', 'pizza']),
  302: _v(302, 'Brus', _cm, 54, ord: ['brus']),
  401: _v(401, 'Diavola', _mp, 199, hoved: true, ord: ['diavola']),
};

HbOrdre _o(int id, HbButikk b, DateTime at, List<(int, int)> lines) => HbOrdre(
  id: id,
  kode: 'Æ-$id',
  butikkId: b.id,
  butikk: b.navn,
  naar: at,
  sum: lines.fold(0, (a, l) => a + _meny[l.$1]!.pris * l.$2),
  linjer: [for (final l in lines) HbOrdreLinje(id: l.$1, ant: l.$2, navn: _meny[l.$1]!.navn, pris: _meny[l.$1]!.pris * l.$2)],
);

final List<HbOrdre> _hist = [
  _o(41, _fw, DateTime(2026, 10, 6, 17, 40), [(201, 1)]), // Tuesday
  _o(40, _tb, DateTime(2026, 10, 1, 17, 35), [(101, 2), (103, 1), (104, 1)]), // last Thursday
  _o(39, _cm, DateTime(2026, 9, 25, 18, 10), [(301, 2), (302, 1)]),
  _o(38, _mp, DateTime(2026, 9, 10, 18, 0), [(401, 1)]),
  _o(37, _fw, DateTime(2026, 8, 19, 17, 30), [(201, 1)]),
  _o(36, _tb, DateTime(2026, 8, 14, 17, 30), [(101, 2), (102, 1)]),
];

final HurtigData kData = HurtigData(
  hist: _hist,
  meny: _meny,
  butikker: {for (final b in [_tb, _fw, _cm, _mp]) b.id: b},
  minne: const HbMinne(liker: ['Fisk', 'Thai', 'Pizza'], butikker: ['Torgboden', 'Fyllingsdalen Wok'], husstand: 2, unngaaSkalldyr: true, middag: ['tirsdag', 'torsdag'], middagKl: '17'),
  adresse: 'Nygårdsgaten 5',
  adresseId: 7,
  navn: 'Didrik',
);

class _FakeKasse extends OpsKasseApi {
  KurvState state = const KurvState();
  final List<int> removed = [];
  @override
  Future<KurvState> cart() async => state;
  @override
  Future<bool> remove(int cartId) async {
    removed.add(cartId);
    return true;
  }

  @override
  Future<List<AddressListItem>> addresses() async => const [];
}

class _FakeCustomer extends OpsCustomerApi {
  @override
  Future<List<Map<String, dynamic>>> orders({int limit = 50}) async => const [];
}

void main() {
  setUpAll(() => bootstrapGlobals(locale: 'no'));
  setUp(() {
    HurtigKilde.reset();
    HurtigKilde.kasse = () => _FakeKasse();
    HurtigKilde.customer = () => _FakeCustomer();
    HurtigKilde.butikk = () => OpsButikkApi();
    HurtigKilde.memory = () async => const <MemoryEntry>[];
  });

  group('HurtigHjerne', () {
    final h = HurtigHjerne(kData, now: kNow);
    const st = HbTilstand();

    test('oftest ranks by orders, then units, ties in history order', () {
      final o = h.oftest();
      expect(o.map((x) => x.id).toList(), [101, 201, 301, 103]);
      expect(o.first.ganger, 2);
      expect(o.first.ant, 4);
    });

    test('the habit of the day is the latest order on this weekday', () {
      final v = h.vane(st)!;
      expect(v.dag, 'torsdag');
      expect(v.butikk, 'Torgboden');
      expect(v.linjer.map((l) => l.id), [101, 103, 104]);
      expect(h.velkomst(st).tekst, startsWith('Torsdag igjen, Didrik! Du pleier å ta 2× fiskesuppe og reker 500 g og sitron fra Torgboden'));
    });

    test('vanligAnt is the mean quantity, at least one', () {
      expect(h.vanligAnt(101), 2);
      expect(h.vanligAnt(301), 2);
      expect(h.vanligAnt(999), 1);
    });

    test('sum: delivery is 39 under the threshold and free from 300', () {
      final s = h.sum(const HbUtkast(butikkId: 1, butikk: 'Torgboden', linjer: [HbLinje(101, 1)]));
      expect(s.varer, 149);
      expect(s.lev, 39);
      final s2 = h.sum(const HbUtkast(butikkId: 1, butikk: 'Torgboden', linjer: [HbLinje(101, 2), HbLinje(104, 1)]));
      expect(s2.lev, 0);
      expect(s2.total, 307);
    });

    test('klar: now plus the shop\'s minutes', () {
      expect(h.klar(const HbUtkast(butikkId: 1, butikk: 'Torgboden', linjer: [])), 'Hos deg ca. 17:55');
      expect(h.klar(const HbUtkast(butikkId: 2, butikk: 'FW', linjer: [], tid: 'Kl. 19:00')), 'Levering kl. 19:00');
    });

    test('dato labels: weekday, forrige weekday, then the date', () {
      expect(h.dato(DateTime(2026, 10, 6)), 'tirsdag');
      expect(h.dato(DateTime(2026, 10, 1)), 'forrige torsdag');
      expect(h.dato(DateTime(2026, 8, 14)), '14. august');
      expect(h.dato(DateTime(2026, 10, 8)), 'i dag');
    });

    test('tolk: a dish «for to» becomes a draft with the main doubled', () {
      final s = h.tolk('pad thai for to', st);
      expect(s.utkast!.butikk, 'Fyllingsdalen Wok');
      expect(s.utkast!.linjer.single.id, 201);
      expect(s.utkast!.linjer.single.ant, 2);
      expect(s.tekst, 'Satt opp: 2× pad thai med kylling fra Fyllingsdalen Wok.');
    });

    test('tolk: «det vanlige» and «samme som sist»', () {
      final v = h.tolk('Det vanlige', st);
      expect(v.modul, 'oftest');
      expect(v.utkast!.butikk, 'Torgboden');
      final s = h.tolk('samme som sist', st);
      expect(s.modul, 'forrige');
      expect(s.utkast!.butikk, 'Fyllingsdalen Wok');
      expect(s.tekst, 'Samme som tirsdag, altså pad thai med kylling fra Fyllingsdalen Wok.');
    });

    test('tolk: «bestill» appends the five-second warning and orders', () {
      final s = h.tolk('bestill det vanlige', st);
      expect(s.bestill, isTrue);
      expect(s.tekst, endsWith('Jeg bestiller om fem sekunder, trykk Angre hvis du ombestemmer deg.'));
    });

    test('tolk: shellfish is questioned while the customer avoids it', () {
      final s = h.tolk('reker', st);
      expect(s.utkast, isNull);
      expect(s.tekst, 'Du har bedt meg unngå skalldyr. Skal jeg legge til reker 500 g likevel?');
      expect(s.knapper.first.h, 'leggtil:103');
      final ok = h.tolk('reker likevel', const HbTilstand(skalldyr: false));
      expect(ok.utkast!.linjer.single.id, 103);
    });

    test('tolk: a closed shop offers the favourite from an open one', () {
      final s = h.tolk('diavola', st);
      expect(s.humor, 'lei');
      expect(s.tekst, startsWith('Møhlenpris Pizza er stengt nå og åpner kl. 10:00. Torgboden er åpen. Vil du ha fiskesuppe derfra?'));
      expect(s.knapper.first.h, 'leggtil:101');
    });

    test('tolk: «uten …» removes a line, the last one empties the draft', () {
      const U = HbUtkast(butikkId: 1, butikk: 'Torgboden', linjer: [HbLinje(101, 2), HbLinje(102, 1)]);
      final s = h.tolk('uten brød', const HbTilstand(utkast: U));
      expect(s.utkast!.linjer.map((l) => l.id), [101]);
      expect(s.tekst, 'Fjernet hjemmelaget brød.');
      final t = h.tolk('dropp fiskesuppe', HbTilstand(utkast: s.utkast));
      expect(t.tomUtkast, isTrue);
    });

    test('tolk: «billigere» trims sides, then quantities', () {
      const U = HbUtkast(butikkId: 1, butikk: 'Torgboden', linjer: [HbLinje(101, 2), HbLinje(102, 1)]);
      final s = h.tolk('kan det bli billigere', const HbTilstand(utkast: U));
      expect(s.utkast!.linjer.single.ant, 1);
      expect(s.tekst, startsWith('Nå er det 149 kr i stedet for 347 kr.'));
    });

    test('tolk: a time sets the slot; «ja» with a draft orders; unknown asks the assistant', () {
      const U = HbUtkast(butikkId: 1, butikk: 'Torgboden', linjer: [HbLinje(101, 2)]);
      final t = h.tolk('kl 19 passer', const HbTilstand(utkast: U));
      expect(t.tid, 'Kl. 19:00');
      expect(h.tolk('ja', const HbTilstand(utkast: U)).bestill, isTrue);
      expect(h.tolk('hva er meningen med livet', st).ai, isTrue);
    });

    test('forslagFor: co-ordered items first, then the cheapest side', () {
      const U = HbUtkast(butikkId: 1, butikk: 'Torgboden', linjer: [HbLinje(101, 2)]);
      final f = h.forslagFor(U, st);
      // Reker are skipped (shellfish); sitron and brød were ordered with the soup.
      expect(f.map((v) => v.id).toSet(), {102, 104});
    });

    test('prefForslag: the favourite main for the household plus a side', () {
      final p = h.prefForslag(st)!;
      expect(p.butikk, 'Torgboden');
      expect(p.linjer.first.id, 101);
      expect(p.linjer.first.ant, 2);
      expect(p.grunner, contains('Torsdag er middagsdag'));
      expect(p.grunner, contains('Uten skalldyr'));
    });

    test('the Hjem line names the habit of the day', () {
      expect(hurtigHjemLinje(kData, now: kNow), 'Fiskesuppe · Torgboden · 486 kr');
      expect(hurtigHjemLinje(null), HurtigCopy.sjekkerVanene);
    });
  });

  group('HurtigScreen', () {
    Widget host({Widget? home}) => MaterialApp(
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true, textScaler: const TextScaler.linear(.5)),
        child: app!,
      ),
      home: home ?? HurtigScreen(data: kData, now: kNow),
    );

    Future<void> svar(WidgetTester tester) async {
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
    }

    Future<void> trykk(WidgetTester tester, Finder f) async {
      await tester.ensureVisible(f);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(f, warnIfMissed: false);
      await tester.pump();
    }

    void phone(WidgetTester tester) {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }

    testWidgets('welcome with the habit of the day and its two keys', (tester) async {
      phone(tester);
      await tester.pumpWidget(host());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Torsdag igjen, Didrik!'), findsOneWidget);
      expect(find.text('Ja, det vanlige · 486 kr'), findsOneWidget);
      expect(find.text('Noe annet'), findsOneWidget);
      expect(find.text('Kjenner 6 bestillinger'), findsOneWidget);
      expect(find.text('Torsdag 17:30'), findsOneWidget);
    });

    testWidgets('«Ja, det vanlige» → the draft card with lines, sums and the order key', (tester) async {
      phone(tester);
      await tester.pumpWidget(host());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Ja, det vanlige · 486 kr'));
      await svar(tester);
      expect(find.byType(HbUtkastKort), findsOneWidget);
      expect(find.text('ÆGILS UTKAST'), findsOneWidget);
      expect(find.text('Bestill nå · 486 kr'), findsOneWidget);
      expect(find.text('Gratis låst opp'), findsOneWidget);
      expect(find.text('Legg i kurven i stedet'), findsOneWidget);
      // The stepper: minus on the soup → 1× → 149 + 179 + 9 = 337 kr, still free.
      await trykk(tester, find.descendant(of: find.byType(HbUtkastKort), matching: find.byWidgetPredicate((w) => w is HbIkon && w.d == HbIkoner.minus)).first);
      expect(find.text('Bestill nå · 337 kr'), findsOneWidget);
      // The time tile cycles Snarest → the next half hour.
      await trykk(tester, find.text('Snarest'));
      expect(find.text('Kl. 18:30'), findsOneWidget);
    });

    testWidgets('module key → the «oftest» card, + adds to the draft', (tester) async {
      phone(tester);
      await tester.pumpWidget(host());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Oftest bestilt'));
      await svar(tester);
      expect(find.byType(HbOftestKort), findsOneWidget);
      expect(find.text('OFTEST BESTILT'), findsOneWidget);
      expect(find.text('6 bestillinger siden august'), findsOneWidget);
      expect(find.text('TORSDAGSFAVORITTEN'), findsOneWidget);
      expect(find.text('Fiskesuppe'), findsWidgets);
      // The first row's +: the soup at its usual quantity (2) → a Torgboden draft, 298 + 39 kr.
      await trykk(tester, find.descendant(of: find.byType(HbOftestKort), matching: find.byWidgetPredicate((w) => w is HbIkon && w.d == HbIkoner.pluss)).first);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(HbUtkastKort), findsOneWidget);
      expect(find.text('Bestill nå · 337 kr'), findsOneWidget);
      expect(find.descendant(of: find.byType(HbOftestKort), matching: find.byWidgetPredicate((w) => w is HbIkon && w.d == HbIkoner.hake)), findsOneWidget);
    });

    testWidgets('«Bestilt forrige gang» and «Dine preferanser» cards render', (tester) async {
      phone(tester);
      await tester.pumpWidget(host());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Bestilt forrige gang'));
      await svar(tester);
      expect(find.byType(HbForrigeKort), findsOneWidget);
      expect(find.text('LEVERT'), findsOneWidget);
      expect(find.text('Bestill det samme igjen'), findsOneWidget);
      expect(find.text('TIDLIGERE'), findsOneWidget);
      await tester.tap(find.text('Dine preferanser'));
      await svar(tester);
      expect(find.byType(HbPrefKort), findsOneWidget);
      expect(find.text('Unngår skalldyr'), findsOneWidget);
      expect(find.text('Tirsdag og torsdag · rundt 17'), findsOneWidget);
      expect(find.text('ÆGIL FORESLÅR I KVELD'), findsOneWidget);
      // The shellfish toggle flips in place.
      await trykk(tester, find.text('Unngår skalldyr'));
      expect(find.text('Skalldyr er ok'), findsOneWidget);
    });

    testWidgets('typing a dish sets up a draft; the countdown shows Angre and stops', (tester) async {
      phone(tester);
      await tester.pumpWidget(host());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byKey(const Key('a1_hurtig_felt')), 'pad thai for to');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await svar(tester);
      expect(find.text('Satt opp: 2× pad thai med kylling fra Fyllingsdalen Wok.'), findsOneWidget);
      expect(find.text('Bestill nå · 378 kr'), findsOneWidget);
      await trykk(tester, find.text('Bestill nå · 378 kr'));
      expect(find.text('Angre · bestiller om 5 s'), findsOneWidget);
      expect(find.text('Betales med Vipps når tiden er ute'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Angre · bestiller om 4 s'), findsOneWidget);
      await trykk(tester, find.text('Angre · bestiller om 4 s'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Bestill nå · 378 kr'), findsOneWidget);
      expect(find.text('Stoppet. Utkastet ligger her til du er klar.'), findsOneWidget);
    });

    testWidgets('Start på nytt clears the conversation and the draft', (tester) async {
      phone(tester);
      await tester.pumpWidget(host());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Ja, det vanlige · 486 kr'));
      await svar(tester);
      expect(find.byType(HbUtkastKort), findsOneWidget);
      await trykk(tester, find.text('Start på nytt'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(HbUtkastKort), findsNothing);
      expect(find.textContaining('Torsdag igjen, Didrik!'), findsOneWidget);
    });

    testWidgets('reduced motion: the screen builds and settles with no ticking frames', (tester) async {
      // The test font's square glyphs need the .5 scale the other Bergen tests use.
      await expectRespectsReducedMotion(
        tester,
        () => Builder(
          builder: (c) => MediaQuery(
            data: MediaQuery.of(c).copyWith(textScaler: const TextScaler.linear(.5)),
            child: SizedBox(width: 390, height: 844, child: HurtigScreen(data: kData, now: kNow)),
          ),
        ),
      );
    });
  });
}
