import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/hjem/hjem_hjul.dart';
import 'package:aerend_customer/screens/bergen/hjem/hjem_kaien.dart';
import 'package:aerend_customer/screens/bergen/hjem/hjem_kort.dart';
import 'package:aerend_customer/screens/bergen/hjem/hjem_snart.dart';
import 'package:aerend_customer/screens/bergen/hjem/hjem_tilbud.dart';
import 'package:aerend_customer/screens/bergen/kit/fane_bytte.dart';
import 'package:aerend_customer/screens/common/auth/launch/lf_css.dart';

import '../layout/reduced_motion_harness.dart';

/// Step 2 (App shell and Hjem): the new Hjem pieces render their states and
/// answer taps, with motion frozen.
void main() {
  setUpAll(() => bootstrapGlobals(locale: 'no'));

  // The test font's glyphs are square (1em each); at .5 they take about
  // the room Jakarta/Inter do, so the design-px rows lay out as on device.
  // Set in MaterialApp.builder so pushed routes (the sheet) get it too.
  Widget host(Widget child, {double h = 844}) => MaterialApp(
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true, size: Size(390, h), textScaler: const TextScaler.linear(.5)),
      child: app!,
    ),
    home: Scaffold(body: child),
  );

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  const kat = [
    HjemHjulKat(navn: 'Restaurant', live: '24 åpne nå', ikon: 0, snart: false),
    HjemHjulKat(navn: 'Mat & fisk', live: 'Kommer snart', ikon: 1, snart: true),
    HjemHjulKat(navn: 'Mote', live: 'Kommer snart', ikon: 2, snart: true, varsles: true),
    HjemHjulKat(navn: 'Interiør', live: 'Kommer snart', ikon: 3, snart: true),
    HjemHjulKat(navn: 'Gaver', live: 'Kommer snart', ikon: 4, snart: true),
  ];

  testWidgets('Kategorirad: live line for restaurants, Varsle-meg chip for coming soon', (tester) async {
    phone(tester);
    var index = 0, snart = -1;
    Widget hjul() => StatefulBuilder(
      builder: (context, set) => lfFlow(
        390,
        HjemKategoriHjul(
          kategorier: kat,
          index: index,
          onIndex: (k) => set(() => index = k),
          onOpen: (_) {},
          onSnart: (k) => snart = k,
        ),
      ),
    );
    await tester.pumpWidget(host(hjul()));
    await tester.pump();
    expect(find.text('Restaurant'), findsOneWidget);
    expect(find.text('24 åpne nå'), findsOneWidget);
    expect(find.text('Kommer snart · Varsle meg'), findsNothing);

    // Next → Mat & fisk: coming soon, so the chip replaces the live line.
    await tester.tap(find.byType(GestureDetector).last);
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('Mat & fisk'), findsOneWidget);
    expect(find.text('Kommer snart · Varsle meg'), findsOneWidget);
    await tester.tap(find.text('Kommer snart · Varsle meg'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(snart, 1);

    // Mote has asked to be told.
    index = 2;
    await tester.pumpWidget(host(hjul()));
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('Du får beskjed'), findsOneWidget);
  });

  testWidgets('Kommer snart sheet: progress, Varsle meg → Du får beskjed → Slå av', (tester) async {
    phone(tester);
    final varsler = <bool>[];
    var restauranter = false;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => visKommerSnart(
                context,
                k: 1,
                info: kHjemSnartPrototype[1]!,
                varsles: false,
                onVarsle: varsler.add,
                onRestauranter: () => restauranter = true,
              ),
              child: const Text('åpne'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('åpne'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Mat & fisk kommer til Ærend'), findsOneWidget);
    expect(find.text('8 av 10'), findsOneWidget);
    expect(find.text('Vi åpner når de siste 2 butikkene er klare.'), findsOneWidget);

    await tester.tap(find.text('Varsle meg når det åpner'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(varsler, [true]);
    expect(find.text('Du får beskjed'), findsOneWidget);
    expect(find.textContaining('Notert!'), findsOneWidget);

    await tester.tap(find.text('Slå av varselet'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(varsler, [true, false]);

    await tester.tap(find.text('Bestill fra restauranter i mellomtiden'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(restauranter, isTrue);
    expect(find.text('Mat & fisk kommer til Ærend'), findsNothing);
  });

  testWidgets('Ærend-tilbud: countdown, coupons and the mystery coupon', (tester) async {
    phone(tester);
    var trykk = 0;
    await tester.pumpWidget(
      host(
        lfFlow(
          358,
          HjemTilbudRad(
            tilbud: [
              HjemTilbud(
                eyebrow: 'Dagens kupp',
                navn: 'Crispy chicken',
                butikk: 'Burger King',
                meta: 'Bergen Storsenter · 25 min',
                ny: '89 kr',
                gml: '129 kr',
                verdi: '−30 %',
                under: 'Spar 40 kr',
                stub: HjemStub.oransje,
                onTap: () => trykk++,
              ),
            ],
            onMysterie: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Ærend-tilbud'), findsOneWidget);
    expect(find.textContaining('Slutter om'), findsOneWidget);
    expect(find.text('Crispy chicken'), findsOneWidget);
    expect(find.text('DAGENS KUPP'), findsOneWidget);
    expect(find.text('Spar 40 kr'), findsOneWidget);
    await tester.tap(find.text('Crispy chicken'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(trykk, 1);
    expect(hjemTilbudTid(DateTime(2026, 10, 5, 22, 24, 40)), '01:35:19');
    // Step 12 (#17): no personal offer, no mystery coupon.
    expect(find.text('Avslør'), findsNothing);
  });

  testWidgets('The mystery coupon is the customer\'s own offer, revealed by the server', (tester) async {
    phone(tester);
    final til = DateTime.now().add(const Duration(hours: 3));
    final mysterie = HjemPersonlig(id: 7, avslort: false, gyldigTil: til);
    var avslor = 0, butikk = 0;
    HjemPersonlig? svar = HjemPersonlig(id: 7, avslort: true, gyldigTil: til, tittel: 'Rabatt hos Torgboden', verdi: '−20 %', butikk: 'Torgboden', butikkId: 9);
    await tester.pumpWidget(
      host(
        lfFlow(
          358,
          HjemTilbudRad(
            tilbud: const [],
            personlig: mysterie,
            onAvslor: (p) async {
              avslor++;
              expect(p.id, 7);
              return svar;
            },
            onMysterie: () => butikk++,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Et tilbud bare for deg'), findsOneWidget);
    expect(find.text('?'), findsOneWidget, reason: 'the value is hidden until revealed');
    expect(find.text('Torgboden'), findsNothing);

    await tester.tap(find.text('Avslør'));
    await tester.pump(const Duration(milliseconds: 900));
    expect(avslor, 1);
    expect(find.text('−20 %'), findsOneWidget);
    expect(find.text('Rabatt hos Torgboden'), findsOneWidget);
    expect(find.text('Torgboden'), findsOneWidget);

    await tester.tap(find.text('Til butikken'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(butikk, 1);

    // A reveal that does not land turns the coupon back.
    svar = null;
    await tester.pumpWidget(host(lfFlow(358, HjemTilbudRad(tilbud: const [], personlig: HjemPersonlig(id: 8, avslort: false, gyldigTil: til), onAvslor: (_) async => svar, onMysterie: () {}))));
    await tester.pump();
    await tester.tap(find.text('Avslør'));
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('Avslør'), findsOneWidget);
    await tester.pump(const Duration(seconds: 12));
  });

  test('A personal offer parses from offers/mine and hides what is not revealed', () {
    final p = HjemPersonlig.fraJson({'id': 3, 'mystery': true, 'valid_until': '2030-01-01T23:59:00+01:00', 'value_label': null});
    expect(p, isNotNull);
    expect(p!.avslort, isFalse);
    expect(p.verdi, isNull);
    expect(HjemPersonlig.fraJson({'id': 3}), isNull, reason: 'no expiry: not a usable offer');
    final r = HjemPersonlig.fraJson({'id': 3, 'mystery': false, 'valid_until': '2030-01-01T23:59:00Z', 'value_label': '50 kr', 'all_stores': true});
    expect(r!.alleButikker, isTrue);
    expect(r.verdi, '50 kr');
  });

  testWidgets('Sheet cards: Hurtigbestilling, section header, Utforsk, Forundringspose', (tester) async {
    phone(tester);
    final trykk = <String>[];
    await tester.pumpWidget(
      host(
        SingleChildScrollView(
          child: lfFlow(
            358,
            Column(
              children: [
                HjemHurtigInngang(linje: 'Fiskesuppe · Torgboden · 347 kr', onTap: () => trykk.add('hurtig')),
                HjemSeksjonHode(tittel: 'Butikker på Bryggen', chip: HjemChip.bergensk, chipTekst: 'Bergensk', prikker: 5, onSeAlle: () => trykk.add('se alle')),
                HjemUtforskKort(linje: '2 nye innlegg fra butikker du følger', onTap: () => trykk.add('utforsk')),
                HjemPoseKort(tittel: 'Det som er igjen i kveld', igjen: '2 igjen i kveld', verdi: 'verdi minst 250 kr', under: 'Sandviken Bakeri', kr: '99', onTap: () => trykk.add('pose')),
              ],
            ),
          ),
        ),
        h: 1400,
      ),
    );
    await tester.pump();
    for (final t in ['Hurtigbestilling', 'Bestill', 'Butikker på Bryggen', 'Se alle', 'Fjordfiske, poser og nytt', 'Åpne', 'FORUNDRINGSPOSE', '99 kr', 'Sikre en']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    await tester.tap(find.text('Bestill'));
    await tester.tap(find.text('Se alle'));
    await tester.tap(find.text('Åpne'));
    await tester.tap(find.text('Sikre en'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(trykk, ['hurtig', 'se alle', 'utforsk', 'pose']);
  });

  testWidgets('Under kaien: three finds', (tester) async {
    phone(tester);
    var reker = false;
    await tester.pumpWidget(
      host(
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 300,
            child: HjemUnderKaien(
              vist: true,
              reker: HjemKaienFunn(tittel: 'Reker, 1 kg', under: 'Torgboden · før 349', pris: '299 kr', onTap: () => reker = true),
              pose: HjemKaienFunn(tittel: 'Forundringspose', under: 'Verdi minst 250 kr', pris: '99 kr', merke: '2 igjen', onTap: () {}),
              frakt: HjemKaienFunn(tittel: 'Gratis levering', under: 'Over 300 kr · Testbutikk', pris: '0 kr', onTap: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('UNDER KAIEN'), findsOneWidget);
    expect(find.text('Reker, 1 kg'), findsOneWidget);
    expect(find.text('Forundringspose'), findsOneWidget);
    expect(find.text('Gratis levering'), findsOneWidget);
    await tester.tap(find.text('Reker, 1 kg'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(reker, isTrue);
  });

  testWidgets('Under kaien shows only real finds, and says so when there are none (backend plan Step 8)', (tester) async {
    phone(tester);
    Widget kaien({HjemKaienFunn? pose}) => host(
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(height: 300, child: HjemUnderKaien(vist: true, pose: pose)),
          ),
        );
    await tester.pumpWidget(kaien());
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Ingen funn i kveld. Jeg ser etter mer.'), findsOneWidget);
    expect(find.text('Gratis levering'), findsNothing);
    expect(find.text('Reker, 1 kg'), findsNothing);

    await tester.pumpWidget(kaien(pose: HjemKaienFunn(tittel: 'Forundringspose', under: 'Pokemon Pizza', pris: '79 kr', merke: '1 igjen', onTap: () {})));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Psst — jeg fant én ting som lå gjemt her.'), findsOneWidget);
    expect(find.text('79 kr'), findsOneWidget);
    expect(find.text('1 igjen'), findsOneWidget);
  });

  testWidgets('faneBytt: only the active tab is built; it switches', (tester) async {
    phone(tester);
    var i = 0;
    late StateSetter set;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, s) {
            set = s;
            return BergenFaneBytte(
              index: i,
              background: const LinearGradient(colors: [Colors.teal, Colors.black]),
              builder: (context, k) => Center(child: Text('fane $k')),
            );
          },
        ),
      ),
    );
    expect(find.text('fane 0'), findsOneWidget);
    expect(find.text('fane 1'), findsNothing);
    set(() => i = 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('fane 1'), findsOneWidget);
    expect(find.text('fane 0'), findsNothing);
  });
}
