import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/aegil/aegil_app_models.dart';
import 'package:aerend_customer/data/aegil/chat_card_models.dart';
import 'package:aerend_customer/screens/bergen/meg/a3_services.dart';
import 'package:aerend_customer/screens/bergen/meg/meg_copy_a4.dart';
import 'package:aerend_customer/screens/bergen/meg/meg_sheets.dart';

import '../a3/a3_fakes.dart';

/// Customer plan Step 8 in the app: Meg's «Ukeshandel» Ark — the list as
/// chips with the planned dinners, then «Ukens kurv» with savings, a
/// substitution to say yes or no to, «Legg i kurven» below level 3 and the
/// level-3 checkout, one Vipps confirmation per store.

const _items = [
  ShoppingListItem(id: 1, text: 'Melk', qty: 1, source: 'user'),
  ShoppingListItem(id: 2, text: 'Kaffe', qty: 1, source: 'pattern', addedByAgent: true),
  ShoppingListItem(id: 3, text: 'Brød', qty: 2, source: 'user'),
];

const _plan = [
  DinnerDay(weekday: 1, name: 'Mandag'),
  DinnerDay(weekday: 2, name: 'Tirsdag', choiceType: 'restaurant', storeProductId: 777, label: 'Pad thai · Fyllingsdalen Wok', price: '189 kr'),
  DinnerDay(weekday: 3, name: 'Onsdag'),
  DinnerDay(weekday: 4, name: 'Torsdag', rhythm: true),
  DinnerDay(weekday: 5, name: 'Fredag'),
  DinnerDay(weekday: 6, name: 'Lørdag'),
  DinnerDay(weekday: 7, name: 'Søndag'),
];

const _candidates = [
  DinnerCandidate(storeProductId: 777, name: 'Pad thai', store: 'Fyllingsdalen Wok', storeId: 9, price: '189 kr'),
  DinnerCandidate(storeProductId: 808, name: 'Fiskesuppe', store: 'Torgboden', storeId: 43, price: '149 kr'),
];

const _lines = [
  WeeklyLine(lineId: 1, name: 'Melk 1 l', store: 'Torgboden', storeId: 43, price: '24 kr'),
  WeeklyLine(lineId: 2, name: 'Friele 500 g', store: 'Rema', storeId: 44, price: '89 kr', saving: '40 kr', substitution: 'Evergood', needsAccept: true),
  WeeklyLine(lineId: 3, name: 'Brød', store: 'Torgboden', storeId: 43, qty: 2, price: '78 kr'),
  WeeklyLine(lineId: 4, name: 'Pad thai', store: 'Fyllingsdalen Wok', storeId: 9, source: 'dinner', price: '189 kr'),
];

const _weekly = WeeklyOrder(id: 50, week: '2026-W43', state: 'ready', total: '380 kr', savings: '40 kr', savingsOre: 4000, lines: _lines, pendingAccept: 1);

WeeklyView _view({WeeklyOrder? weekly}) => WeeklyView(week: '2026-W43', weekly: weekly, items: _items, plan: _plan, candidates: _candidates);

/// A button that opens the Ark, as Meg's row does.
Widget _app(FakeAegilApi api, {required int level, String steg = 'liste', WeeklyView? view, VoidCallback? onKurv}) => MaterialApp(
  home: Scaffold(
    body: Builder(
      builder: (ctx) => TextButton(
        key: const Key('aapne'),
        onPressed: () => MegSheets.ukeshandel(ctx, api: api, view: view ?? api.weeklyValue ?? const WeeklyView(), level: level, steg: steg, onKurv: onKurv),
        child: const Text('åpne'),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('aapne')));
  await tester.pumpAndSettle();
}

/// A phone-tall surface so the Ark's rows and keys are on screen.
void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUpAll(() async {
    await a3Bootstrap();
  });

  tearDown(A3Services.reset);

  test('the weekly models read the server shape', () {
    final v = WeeklyView.fromJson(const {
      'week': '2026-W43',
      'weekly': {
        'id': 5, 'week': '2026-W43', 'state': 'ready', 'total': {'amount_ore': 38000, 'display': '380 kr'}, 'savings': {'amount_ore': 4000, 'display': '40 kr'},
        'lines': [
          {'line_id': 1, 'name': 'Melk', 'store': 'Torgboden', 'store_id': 43, 'qty': 1, 'source': 'list', 'price': {'display': '24 kr'}, 'saving': null, 'substitution': null, 'needs_accept': false, 'accepted': null},
          {'line_id': 2, 'name': 'Friele', 'store': 'Rema', 'store_id': 44, 'qty': 1, 'source': 'list', 'price': {'display': '89 kr'}, 'saving': {'display': '40 kr'}, 'substitution': {'reason': 'sold_out', 'original': 'Evergood'}, 'needs_accept': true, 'accepted': null},
        ],
        'dropped': [{'name': 'Laks', 'reason': 'cap_per_week', 'text': 'Over ukens tak (900 kr)'}],
        'over_cap': true, 'pending_accept': 1, 'order_ids': [], 'placed_at': null,
      },
      'items': [{'id': 1, 'text': 'Melk', 'qty': 1, 'done': false, 'source': 'user', 'added_by_agent': false}],
      'plan': [{'weekday': 2, 'name': 'Tirsdag', 'rhythm': false, 'choice_type': 'restaurant', 'store_product_id': 777, 'label': 'Pad thai · Wok', 'price': {'display': '189 kr'}}],
      'candidates': [{'store_product_id': 777, 'name': 'Pad thai', 'store': 'Wok', 'store_id': 9, 'price': {'display': '189 kr'}}],
    });
    expect(v.weekly!.total, '380 kr');
    expect(v.weekly!.savingsOre, 4000);
    expect(v.weekly!.lines[1].substitution, 'Evergood');
    expect(v.weekly!.lines[1].pendingAccept, isTrue);
    expect(v.weekly!.dropped.single.reason, 'cap_per_week');
    expect(v.weekly!.overCap, isTrue);
    expect(v.weekly!.open, isTrue);
    expect(v.plan.single.planned, isTrue);
    expect(v.candidates.single.price, '189 kr');
    expect(v.items.single.text, 'Melk');

    final c = WeeklyConfirmation.fromJson(const {
      'confirmation': {'status': 'confirmation_required', 'confirm_token': 'tok', 'store_id': 43, 'store': 'Torgboden', 'summary': {'total': {'display': '102 kr'}}},
      'stores_total': 2, 'stores_done': 0,
    });
    expect([c.confirmToken, c.storeId, c.store, c.total, c.storesTotal, c.storesDone], ['tok', 43, 'Torgboden', '102 kr', 2, 0]);
    final r = WeeklyConfirmResult.fromJson(const {'done': false, 'placed': {'order': {'id': 91}}, 'confirmation': {'confirm_token': 'tok2', 'store_id': 44, 'store': 'Rema'}, 'stores_total': 2, 'stores_done': 1});
    expect([r.done, r.orderId, r.next!.confirmToken, r.next!.storesDone], [false, 91, 'tok2', 1]);
    expect(WeeklyConfirmResult.fromJson(const {'done': true, 'placed': {'order': {'id': 92}}, 'orders': [91, 92]}).orders, [91, 92]);
  });

  testWidgets('Handleliste: chips tick off, a dinner row changes its dish, «Se ukens kurv» opens the basket', (tester) async {
    _phone(tester);
    final api = FakeAegilApi()
      ..listItems = _items
      ..weeklyValue = _view(weekly: _weekly);
    await tester.pumpWidget(_app(api, level: 2));
    await _open(tester);

    expect(find.text(A4MegCopy.a4_meg_handleliste), findsOneWidget);
    expect(find.text(A4MegCopy.a4_meg_liste_linje(3)), findsOneWidget);
    expect(find.text('Melk'), findsOneWidget);
    expect(find.text('2 × Brød'), findsOneWidget);
    expect(find.text('Middag tirsdag'), findsOneWidget);
    expect(find.text('Pad thai · Fyllingsdalen Wok'), findsOneWidget);
    expect(find.text('189 kr'), findsOneWidget);

    await tester.tap(find.byKey(const Key('uke-chip-1')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('list-toggle:1'));
    expect(api.listItems.first.done, isTrue);

    // The dinner row: pick the other dish for Tuesday.
    await tester.tap(find.byKey(const Key('uke-middag-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('meg-middag-rett-sheet')), findsOneWidget);
    expect(find.text('Fiskesuppe'), findsOneWidget);
    await tester.tap(find.byKey(const Key('middag-rett-808')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('dinner:2026-W43:2:restaurant:808'));
    expect(find.text('Fiskesuppe · Torgboden'), findsOneWidget);

    // «Middag · Velg» → the days → Thursday's dish.
    await tester.tap(find.byKey(const Key('uke-middag-velg')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('meg-middag-dag-sheet')), findsOneWidget);
    await tester.tap(find.byKey(const Key('middag-dag-4')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('middag-rett-777')));
    await tester.pumpAndSettle();
    expect(api.calls.last, 'dinner:2026-W43:4:restaurant:777');
    expect(find.text('Middag torsdag'), findsOneWidget);

    await tester.tap(find.byKey(const Key('uke-se-kurv')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('meg-ukeskurv-sheet')), findsOneWidget);
    expect(find.text(A4MegCopy.a4_meg_ukens_kurv('380 kr')), findsOneWidget);
  });

  testWidgets('Ukens kurv below level 3: lines, saving, «Bytte» with Ja/Nei, then «Legg i kurven»; «Ikke denne uken» skips', (tester) async {
    _phone(tester);
    final api = FakeAegilApi()..weeklyValue = _view(weekly: _weekly);
    var kurv = 0;
    await tester.pumpWidget(_app(api, level: 2, steg: 'kurv', onKurv: () => kurv++));
    await _open(tester);

    expect(find.text(A4MegCopy.a4_meg_ukens_kurv('380 kr')), findsOneWidget);
    expect(find.text(A4MegCopy.a4_meg_uke_linje2), findsOneWidget);
    expect(find.text('Melk 1 l'), findsOneWidget);
    expect(find.text('2 × Brød'), findsOneWidget);
    expect(find.text('−40'), findsOneWidget);
    expect(find.text(A4MegCopy.a4_meg_bytte('Friele 500 g', 'Evergood')), findsOneWidget);
    expect(find.byKey(const Key('uke-sparing')), findsOneWidget);
    expect(find.text(A4MegCopy.a4_meg_sparing('40 kr')), findsOneWidget);
    expect(find.text(A4MegCopy.a4_meg_legg_i_kurven), findsOneWidget);
    expect(find.text(A4MegCopy.a4_meg_ikke_denne_uken), findsOneWidget);

    // The CTA waits for the substitution's answer.
    await tester.tap(find.byKey(const Key('uke-cta')));
    await tester.pumpAndSettle();
    expect(api.calls.where((c) => c.startsWith('weekly-basket')), isEmpty);
    expect(find.text(A4MegCopy.a4_meg_bytte_svar), findsOneWidget);

    await tester.tap(find.byKey(const Key('uke-bytte-ja-2')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('weekly-line:2:accept'));
    expect(find.byKey(const Key('uke-bytte-ja-2')), findsNothing, reason: 'answered');
    expect(find.text(A4MegCopy.a4_meg_bytte('Friele 500 g', 'Evergood')), findsOneWidget, reason: 'the swap stays named');

    // Take out the bread: the title follows the total.
    await tester.tap(find.byKey(const Key('uke-fjern-3')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('weekly-line:3:remove'));
    expect(find.text(A4MegCopy.a4_meg_ukens_kurv('302 kr')), findsOneWidget);
    expect(find.text('2 × Brød'), findsNothing);

    await tester.tap(find.byKey(const Key('uke-cta')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('weekly-basket:50'));
    expect(kurv, 1);
    expect(find.byKey(const Key('meg-ukeskurv-sheet')), findsNothing);
    expect(find.text(A4MegCopy.a4_meg_uke_i_kurven), findsOneWidget);

    // Reopen: «Ikke denne uken».
    await _open(tester);
    await tester.tap(find.byKey(const Key('uke-ikke-denne-uken')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('weekly-skip:50'));
    expect(find.text(A4MegCopy.a4_meg_uke_hoppet), findsOneWidget);
  });

  testWidgets('Ukens kurv at level 3: «Til kassen» confirms one store at a time with Vipps, then «bestilt»', (tester) async {
    _phone(tester);
    final vipps = <int>[];
    A3Services.vippsUrl = (id) async {
      vipps.add(id);
      return null;
    };
    final api = FakeAegilApi()
      ..weeklyValue = _view(weekly: _weekly)
      ..confirmations = const [
        WeeklyConfirmation(confirmToken: 't1', storeId: 43, store: 'Torgboden', total: '102 kr', storesTotal: 2, storesDone: 0),
        WeeklyConfirmation(confirmToken: 't2', storeId: 44, store: 'Rema', total: '89 kr', storesTotal: 2, storesDone: 1),
      ];
    await tester.pumpWidget(_app(api, level: 3, steg: 'kurv'));
    await _open(tester);

    expect(find.text(A4MegCopy.a4_meg_uke_linje3), findsOneWidget);
    expect(find.text(A4MegCopy.a4_meg_til_kassen), findsOneWidget);
    await tester.tap(find.byKey(const Key('uke-bytte-nei-2')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('weekly-line:2:reject'));
    expect(find.text('Friele 500 g'), findsNothing);
    expect(find.byKey(const Key('uke-sparing')), findsNothing, reason: 'the saving went with the swap');

    await tester.tap(find.byKey(const Key('uke-cta')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('weekly-checkout:50'));
    expect(find.byKey(const Key('meg-ukeskasse-sheet')), findsOneWidget);
    expect(find.text(A4MegCopy.a4_meg_uke_butikk(1, 2, 'Torgboden')), findsOneWidget);
    expect(find.text('102 kr'), findsOneWidget);

    await tester.tap(find.byKey(const Key('uke-betal')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('weekly-confirm:50:t1:vipps'));
    expect(vipps, [9001]);
    expect(find.text(A4MegCopy.a4_meg_uke_butikk(2, 2, 'Rema')), findsOneWidget);

    await tester.tap(find.byKey(const Key('uke-betal')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('weekly-confirm:50:t2:vipps'));
    expect(vipps, [9001, 9002]);
    expect(find.byKey(const Key('meg-ukeskasse-sheet')), findsNothing);
    expect(find.text(A4MegCopy.a4_meg_uke_bestilt), findsOneWidget);
    expect(api.weeklyValue!.weekly!.state, 'placed');
  });

  testWidgets('no basket yet: «Bygg den nå» builds it and shows the lines; a refusal is told', (tester) async {
    _phone(tester);
    final api = FakeAegilApi()
      ..weeklyValue = _view()
      ..weeklyFeil = 'Ingenting å bygge fra: legg noe i handlelisten eller planlegg en middag.';
    await tester.pumpWidget(_app(api, level: 2, steg: 'kurv'));
    await _open(tester);
    expect(find.text(A4MegCopy.a4_meg_ukeshandel), findsOneWidget);
    expect(find.text(A4MegCopy.a4_meg_uke_tom), findsOneWidget);
    expect(find.byKey(const Key('uke-ikke-denne-uken')), findsNothing);

    await tester.tap(find.byKey(const Key('uke-bygg')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('weekly-build'));
    expect(find.text(api.weeklyFeil!), findsOneWidget);

    api
      ..weeklyFeil = null
      ..builtValue = _weekly;
    await tester.tap(find.byKey(const Key('uke-bygg')));
    await tester.pumpAndSettle();
    expect(find.text(A4MegCopy.a4_meg_ukens_kurv('380 kr')), findsOneWidget);
    expect(find.text('Melk 1 l'), findsOneWidget);
  });
}
