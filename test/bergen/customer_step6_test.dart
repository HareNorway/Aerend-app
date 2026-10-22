import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/aegil/aegil_app_models.dart';
import 'package:aerend_customer/data/aegil/aegil_models.dart';
import 'package:aerend_customer/networking/ops/cus_api.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/aegil/aegil_verktoy.dart';
import 'package:aerend_customer/screens/bergen/hurtig/hurtig_data.dart';
import 'package:aerend_customer/screens/bergen/meg/min_bio.dart';
import 'package:aerend_customer/screens/bergen/meg/min_bio_ark.dart';

import '../a3/a3_fakes.dart';

/// Customer plan Step 6: Min bio on the server — codes in and out, strict
/// diets, the consent gate before anything sensitive is saved, «Slett bioen»
/// with «Er du sikker?», Ægil's «Skjult på grunn av bioen din — vis likevel»
/// and «Allergener ikke oppgitt», and Hurtig's «Unngår skalldyr» from the bio.

/// Records what the sheet sends instead of calling the server.
class _Cus extends CusApi {
  Map<String, dynamic>? lagret;
  bool? samtykke;
  bool slettet = false;

  @override
  Future<({CusBio? bio, String? feil})> bioLagre(Map<String, dynamic> kropp, {bool samtykke = false, String versjon = 'v1'}) async {
    lagret = kropp;
    this.samtykke = samtykke;
    return (bio: CusBio(allergener: List<String>.from(kropp['allergens'] as List), samtykkeGjeldende: true, kjent: true), feil: null);
  }

  @override
  Future<bool> bioSlett() async => slettet = true;

  @override
  Future<({String kilde, List<CusBioForslag> forslag})?> bioTolk(String tekst, {bool samtykke = false}) async => null;
}

const _bio = CusBio(
  allergener: ['nuts'],
  unngaar: ['milk'],
  annet: ['kiwi'],
  kost: ['halal', 'low_carb'],
  annetKost: ['FODMAP'],
  streng: ['halal'],
  liker: [(value: 'thai', label: 'Thai')],
  ikke: [(value: 'koriander', label: 'Liker ikke koriander')],
  tekst: 'Allergisk mot nøtter.',
  kjent: true,
);

void _frame(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 1200));
}

/// A button that opens the sheet with [bio]; [svar] gets what it returned.
Widget _apne(MinBio bio, _Cus api, List<int?> svar) => MaterialApp(
  home: Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        key: const Key('apne'),
        onPressed: () async => svar.add(await visMinBio(context, repo: FakeAegilRepo(), bio: bio, minne: const [], api: api)),
        child: const Text('Min bio'),
      ),
    ),
  ),
);

void main() {
  setUpAll(() async {
    await a3Bootstrap();
    OpsCustomerApi.networkEnabled = false;
  });

  test('the server bio maps codes to chips and back', () {
    final b = minBioFraCus(_bio);
    expect(b.all, {'Nøtter': BioAll.allergi, 'Melk': BioAll.unnga, 'Kiwi': BioAll.allergi});
    expect(b.kost, ['Halal', 'Lavkarbo', 'FODMAP']);
    expect(b.streng, {'Halal'});
    expect(b.ikke, ['Koriander'], reason: 'a stored value finds the chip («koriander» → «Koriander»)');
    expect(b.server, isTrue);

    final k = minBioKropp(b);
    expect(k['allergens'], ['nuts']);
    expect(k['avoids'], ['milk']);
    expect(k['other'], ['Kiwi']);
    expect(k['preferences'], ['halal', 'low_carb']);
    expect(k['other_preferences'], ['FODMAP']);
    expect(k['strict'], ['halal'], reason: 'only a diet that can be strict');
    expect(k['likes'], ['Thai']);
    expect(minBioSensitiv(b), isTrue);
    expect(minBioSensitiv(const MinBio(liker: ['Thai'])), isFalse, reason: 'likes alone need no consent');
  });

  test('a diet that can be strict starts strict; the switch and the chip change it', () {
    final k = MinBioKontroll(const MinBio());
    k.kost('Vegetar');
    expect(k.bio.streng, {'Vegetar'});
    k.strengTrykk('Vegetar');
    expect(k.bio.streng, isEmpty);
    expect(k.aeg, contains('viser deg resten'));
    k.kost('Lavkarbo');
    expect(k.bio.streng, isEmpty, reason: 'low carb only ranks');
    k.strengTrykk('Vegetar');
    k.kost('Vegetar');
    expect(k.bio.streng, isEmpty, reason: 'taken off with its chip');
    k.dispose();
  });

  test('onboarding picks wait in Min bio as suggestions', () {
    final E = bioEff(minBioFraCus(const CusBio(), ventende: ['all:Nøtter', 'kost:Halal']));
    expect(E.forslag, containsAll(['all:Nøtter', 'kost:Halal']));
    expect(E.all, isEmpty);
    expect(E.kost, isEmpty);
  });

  testWidgets('nothing sensitive is saved before the consent tick; with it the codes go', (tester) async {
    _frame(tester);
    final api = _Cus();
    final svar = <int?>[];
    final bio = minBioFraCus(const CusBio(allergener: ['nuts']));
    await tester.pumpWidget(_apne(bio, api, svar));
    await tester.tap(find.byKey(const Key('apne')));
    await _settle(tester);

    expect(find.byKey(const Key('min-bio-samtykke')), findsOneWidget);
    expect(find.byKey(const Key('min-bio-ansvar')), findsOneWidget);
    expect(find.textContaining('sjekk med butikken'), findsOneWidget);
    await tester.tap(find.byKey(const Key('min-bio-lagre')));
    await _settle(tester);
    expect(api.lagret, isNull, reason: 'refused in the app before any call');
    expect(find.textContaining('Kryss av for samtykket'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('min-bio-samtykke')));
    await tester.tap(find.byKey(const Key('min-bio-samtykke')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('min-bio-lagre')));
    await _settle(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(api.samtykke, isTrue);
    expect(api.lagret?['allergens'], ['nuts']);
    expect(svar, [1]);
  });

  testWidgets('a strict switch for each diet that can be strict', (tester) async {
    _frame(tester);
    await tester.pumpWidget(_apne(minBioFraCus(const CusBio(kost: ['halal', 'low_carb'], streng: ['halal'], samtykkeGjeldende: true)), _Cus(), []));
    await tester.tap(find.byKey(const Key('apne')));
    await _settle(tester);
    expect(find.byKey(const ValueKey('min-bio-streng-Halal')), findsOneWidget);
    expect(find.byKey(const ValueKey('min-bio-streng-Lavkarbo')), findsNothing);
    expect(find.text('Ægil viser bare det butikken har merket'), findsOneWidget);
  });

  testWidgets('«Slett bioen» asks «Er du sikker?», then deletes and says so', (tester) async {
    _frame(tester);
    final api = _Cus();
    final svar = <int?>[];
    await tester.pumpWidget(_apne(minBioFraCus(CusBio(allergener: const ['nuts'], kjent: true, samtykkeGjeldende: true, samtykket: DateTime(2026, 10, 22), oppdatert: DateTime(2026, 10, 22))), api, svar));
    await tester.tap(find.byKey(const Key('apne')));
    await _settle(tester);
    expect(find.textContaining('Du samtykket 22. okt. 2026'), findsOneWidget);
    expect(find.text('Ægil kjenner bioen din · sist oppdatert 22. okt. 2026'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('min-bio-slett')));
    await tester.tap(find.byKey(const Key('min-bio-slett')));
    await _settle(tester);
    expect(find.text('Er du sikker?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('min-bio-slett-ja')));
    await _settle(tester);
    expect(api.slettet, isTrue);
    expect(svar, [0]);
    expect(find.text('Bioen er slettet. Ægil har glemt den.'), findsOneWidget);
  });

  testWidgets('Ægil\'s products: «N skjult på grunn av bioen din · Vis likevel», «Allergener ikke oppgitt»', (tester) async {
    const v = AeVerktoy('products', {
      'type': 'products',
      'items': [
        {'id': 1, 'name': 'Laksefilet', 'store_id': 43, 'store_name': 'Torgboden'},
        {'id': 2, 'name': 'Laksesuppe', 'store_id': 43, 'store_name': 'Torgboden', 'bio': {'allergens_unknown': true}},
      ],
      'hidden': [
        {'id': 3, 'name': 'Laks med nøttepesto', 'store_id': 43, 'store_name': 'Torgboden', 'bio': {'hidden': true, 'reason': 'Inneholder nøtter', 'code': 'nuts'}},
      ],
      'bio': {'applied': true, 'for_someone_else': false, 'hidden_count': 1},
    });
    String sub(Map<String, dynamic> p) {
      final b = p['bio'] is Map ? p['bio'] as Map : const {};
      return [p['name'], b['hidden'] == true ? b['reason'] : (b['allergens_unknown'] == true ? 'Allergener ikke oppgitt' : null)].whereType<String>().join(' · ');
    }

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: AeVarerKort(v: v, vare: (p) => Text(sub(p)), notis: Text.new))));
    expect(find.text('Laksefilet'), findsOneWidget);
    expect(find.text('Laksesuppe · Allergener ikke oppgitt'), findsOneWidget);
    expect(find.text('Skjult av bioen din'), findsOneWidget);
    expect(find.textContaining('nøttepesto'), findsNothing);

    await tester.tap(find.text('Vis likevel'));
    await tester.pump();
    expect(find.text('Laks med nøttepesto · Inneholder nøtter'), findsOneWidget);
    expect(find.text('Skjult av bioen din'), findsNothing);
  });

  test('Hurtig reads «Unngår skalldyr» from the bio', () async {
    HurtigKilde.reset();
    HurtigKilde.memory = () async => const <MemoryEntry>[];
    HurtigKilde.bio = () async => const CusBio(allergener: ['crustaceans']);
    final d = await HurtigKilde.load(refresh: true);
    expect(d.minne.unngaaSkalldyr, isTrue);
    HurtigKilde.reset();
  });
}
