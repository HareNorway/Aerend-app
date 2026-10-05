import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';

import 'package:aerend_customer/screens/bergen/adresse/adr_ark.dart';
import 'package:aerend_customer/screens/common/manageAddress/manage_address_dl.dart';

import '../layout/reduced_motion_harness.dart';

/// Step 3 (Address flow): the two sheets against a fake [AdrKilde], with
/// motion frozen.
class _Kilde implements AdrKilde {
  _Kilde(List<AddressListItem> l, {this.dek}) {
    listeS.add(l);
    valgtS.add(l.last);
  }

  final listeS = BehaviorSubject<List<AddressListItem>?>();
  final valgtS = BehaviorSubject<AddressListItem?>();
  AdrDekning? dek;
  final slettet = <int>[], toasts = <String>[], sagtFra = <int>[];
  final lagt = <({String adresse, String type, String info})>[];

  @override
  Stream<List<AddressListItem>?> get liste => listeS;
  @override
  Stream<AddressListItem?> get valgt => valgtS;
  @override
  void velg(int id) => valgtS.add(listeS.value!.firstWhere((a) => a.addressId == id));
  @override
  Future<void> slett(int id) async => slettet.add(id);
  @override
  Future<AdrDekning?> dekning(AddressListItem a) async => dek;
  @override
  Future<AdrDekning?> dekningForslag(AdrForslag f) async => dek;
  @override
  Future<void> siFra(AddressListItem a) async => sagtFra.add(a.addressId);
  @override
  String dor(AddressListItem a) => adrDor(a);
  @override
  Future<bool> lagreDor(AddressListItem a, String tekst) async => true;
  @override
  Future<List<AdrForslag>> forslag(String q) async => const [AdrForslag(gate: 'Bryggen 11', sted: '5003 Bergen', placeId: 'p1')];
  @override
  Future<int?> leggTil({required String adresse, required String type, required AdrForslag? fra, required String info}) async {
    lagt.add((adresse: adresse, type: type, info: info));
    return 9;
  }

  @override
  void minPosisjon(void Function() ferdig) => ferdig();
  @override
  void toast(String tekst) => toasts.add(tekst);
}

AddressListItem _adr(int id, String type, String address, {String landmark = ''}) =>
    AddressListItem(addressId: id, type: type, address: address, lat: '60.39', long: '5.32', flatNo: 'N/A', landmark: landmark);

void main() {
  setUpAll(() => bootstrapGlobals(locale: 'no'));

  Widget host(Widget child) => MaterialApp(
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true, size: const Size(390, 1500), textScaler: const TextScaler.linear(.5)),
      child: app!,
    ),
    home: Scaffold(body: child),
  );

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 4500);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> open(WidgetTester tester, _Kilde k, {bool ny = false}) async {
    await tester.pumpWidget(
      host(Builder(builder: (context) => Center(child: ElevatedButton(onPressed: () => visAdresseArk(context, k, ny: ny), child: const Text('åpne'))))),
    );
    await tester.tap(find.text('åpne'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    // Coverage arrives after that frame.
    await tester.pump();
  }

  test('Helpers: merke, gate/nr, door-note chips, coverage JSON', () {
    expect(adrMerke('Hjemme'), 'Hjem');
    expect(adrMerke('home'), 'Hjem');
    expect(adrMerke('Jobb'), 'Jobb');
    expect(adrMerke('Hytte'), 'Hytte');
    expect(adrMerke('Annet'), 'Annet');
    expect(adrType('Hjem'), 'Hjemme');
    expect(adrGateNr('Nygårdsgaten 5, 5015 Bergen'), ('Nygårdsgaten', '5'));
    expect(adrGateNr('Bryggen 11B'), ('Bryggen', '11B'));
    expect(adrGateNr('Torget'), ('Torget', null));

    final c = dorTolk('Tredje etasje, ring på Hansen, bakgården, kode 1234');
    expect(c.map((e) => '${e.$1}=${e.$2}'), ['Etasje=3', 'Ring på=Hansen', 'Inngang=bakgården', 'Kode=1234']);
    expect(adrUnder(_adr(1, 'Hjemme', 'Nygårdsgaten 5, 5015 Møhlenpris', landmark: '3. etasje')), 'Møhlenpris · 3. etasje');
    expect(adrDor(_adr(1, 'home', 'Torggaten 9, Bergen', landmark: 'Torggaten 9, Bergen')), '');

    final d = AdrDekning.fraJson({
      'covered': true,
      'zone': {'status': 'active'},
      'stores': [
        {'eta_minutes': 35},
        {'eta_minutes': 25},
      ],
      'fee_ore': 3900,
    });
    expect(d.linje, '2 butikker leverer hit · 39 kr · 25–35 min');
    expect(d.hodeEta, '25–35 min');
    final p = AdrDekning.fraJson({'covered': true, 'zone': {'status': 'paused'}, 'stores': const []});
    expect(p.pauset, isTrue);
    expect(p.hodeEta, isNull);
    expect(AdrDekning.fraJson({'covered': false, 'stores': const []}).dekket, isFalse);
  });

  testWidgets('Adresse: places, coverage, delete with Angre, delete goes through', (tester) async {
    phone(tester);
    final k = _Kilde(
      [_adr(1, 'Jobb', 'Solheimsgaten 7, Danmarksplass'), _adr(2, 'Hjemme', 'Nygårdsgaten 5, 5015 Møhlenpris')],
      dek: const AdrDekning(dekket: true, butikker: 6, gebyrKr: 29, eta: '25–35 min'),
    );
    await open(tester, k);
    expect(find.text('Hvor skal ærendet?'), findsOneWidget);
    expect(find.text('HER BOR DU'), findsOneWidget);
    expect(find.text('LEVERES HIT'), findsOneWidget);
    expect(find.text('6 butikker leverer hit · 29 kr · 25–35 min'), findsOneWidget);
    expect(find.text('2 av 4 steder'), findsOneWidget);
    expect(find.text('Legg til et nytt sted'), findsOneWidget);

    // Delete Jobb, then undo it.
    final trash = find.descendant(of: find.byKey(const ValueKey('rad-1')), matching: find.byWidgetPredicate((w) => w.runtimeType.toString() == 'LfPress'));
    await tester.tap(trash.last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Jobb er slettet'), findsOneWidget);
    expect(find.text('1 av 4 steder'), findsOneWidget);
    await tester.tap(find.text('Angre'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Jobb er slettet'), findsNothing);
    expect(find.text('Solheimsgaten 7'), findsOneWidget);
    expect(k.slettet, isEmpty);

    // Delete again and let the 5s pass: the delete goes to the API.
    await tester.tap(find.descendant(of: find.byKey(const ValueKey('rad-1')), matching: find.byWidgetPredicate((w) => w.runtimeType.toString() == 'LfPress')).last);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 5));
    expect(k.slettet, [1]);
    expect(find.text('Jobb er slettet'), findsNothing);

    // The last place can't go.
    await tester.tap(find.descendant(of: find.byKey(const ValueKey('rad-2')), matching: find.byWidgetPredicate((w) => w.runtimeType.toString() == 'LfPress')).last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(k.toasts, contains('Du må ha minst ett sted å levere til'));
  });

  testWidgets('Adresse: Ikke dekket → Si fra → Vi sier fra; Pauset', (tester) async {
    phone(tester);
    final k = _Kilde([_adr(3, 'Hytte', 'Ulsetveien 3, Åsane')], dek: const AdrDekning(dekket: false));
    await open(tester, k);
    expect(find.text('HYTTA DI'), findsOneWidget);
    expect(find.text('Vi leverer ikke hit ennå.'), findsOneWidget);
    await tester.tap(find.text('Si fra når dere gjør det'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(k.sagtFra, [3]);
    expect(find.text('Vi sier fra.'), findsOneWidget);

    final p = _Kilde([_adr(4, 'Hjemme', 'Torggaten 9, Bergen')], dek: const AdrDekning(dekket: true, pauset: true, pausetTil: '17:00'));
    await tester.pumpWidget(const SizedBox());
    await open(tester, p);
    expect(find.text('Midlertidig pauset · til 17:00'), findsOneWidget);
    expect(find.text('Du kan se butikkene, og vi åpner for bestilling igjen da.'), findsOneWidget);
  });

  testWidgets('Adresse: picking another place selects it and closes after 2s', (tester) async {
    phone(tester);
    final k = _Kilde([_adr(1, 'Jobb', 'Solheimsgaten 7, Danmarksplass'), _adr(2, 'Hjemme', 'Nygårdsgaten 5, Møhlenpris')]);
    await open(tester, k);
    await tester.tap(find.text('Solheimsgaten 7'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(k.valgtS.value!.addressId, 1);
    expect(find.text('HER JOBBER DU'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Hvor skal ærendet?'), findsNothing);
  });

  testWidgets('Ny adresse: steps, search, valgt card, Lagre og lever hit', (tester) async {
    phone(tester);
    final k = _Kilde([_adr(2, 'Hjemme', 'Nygårdsgaten 5, Møhlenpris')], dek: const AdrDekning(dekket: true, butikker: 6, eta: '25–35 min'));
    await open(tester, k);
    await tester.tap(find.text('Legg til et nytt sted'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Nytt sted på kartet'), findsOneWidget);
    expect(find.text('LEDIG TOMT'), findsOneWidget);
    expect(find.text('Skriv adressen først'), findsOneWidget);

    await tester.tap(find.text('Hytte'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.enterText(find.byType(TextField).first, 'Bryg');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('5003 Bergen'), findsOneWidget);
    expect(find.text('Lagre og lever hit'), findsOneWidget);

    await tester.tap(find.text('5003 Bergen'));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('HYTTA DI'), findsOneWidget);
    expect(find.text('Endre'), findsOneWidget);
    expect(find.text('Ægil leverer hit · 25–35 min'), findsOneWidget);
    expect(find.text('Tenner lyset'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '3. etasje');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Lyset er på'), findsOneWidget);

    await tester.tap(find.text('Lagre og lever hit'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(k.lagt.single, (adresse: 'Bryggen 11, 5003 Bergen', type: 'Hytte', info: '3. etasje'));
    expect(k.toasts, contains('Lagret · leverer til Bryggen 11'));
    expect(find.text('Hvor skal ærendet?'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}
