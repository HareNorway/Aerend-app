import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/aegil/aegil_app_models.dart';
import 'package:aerend_customer/data/aegil/aegil_models.dart';
import 'package:aerend_customer/screens/bergen/aegil/aegil_innst.dart';
import 'package:aerend_customer/screens/bergen/meg/a3_services.dart';
import 'package:aerend_customer/screens/bergen/meg/fast_ukeshandel.dart';
import 'package:aerend_customer/screens/bergen/meg/meg_sheets.dart';
import 'package:aerend_customer/services/customer/client_flags.dart';

import '../a3/a3_fakes.dart';

/// Customer v2 Step 6 (spec §4.11) in the app: «Fast ukeshandel» — the opt-in
/// screen with the explicit consent, the Vipps hand-off and «Jeg har
/// bekreftet», the overview with «Endre» on the noticed week, «Pause» /
/// «Fortsett», «Avslutt» with a confirmation, the failed-payment state; the
/// row in Meg's Ukeshandel Ark and the settings' level-4 row behind the flag;
/// the models read the server shape.
const _run = StandingRunView(id: 7, week: '2026-W45', state: 'noticed', total: '268 kr', lineCount: 3);
const _active = StandingView(id: 1, state: 'active', scheduleDow: 4, scheduleDay: 'torsdag', window: '17-20', cap: '1 000 kr', capKr: 1000, paymentMethod: 'vipps_recurring', consentVersion: 'app-2026-11', agreementState: 'active', nextCutoffLine: 'onsdag 20:00', run: _run, line: 'torsdag kl. 17–20 · inntil 1 000 kr');
const _failed = StandingView(id: 1, state: 'paused', pauseReason: 'payment_failed', scheduleDow: 4, scheduleDay: 'torsdag', window: '17-20', cap: '1 000 kr', capKr: 1000, paymentMethod: 'vipps_recurring', consentVersion: 'app-2026-11', agreementState: 'active', nextCutoffLine: 'onsdag 20:00', run: StandingRunView(id: 7, state: 'failed'), line: 'torsdag kl. 17–20 · inntil 1 000 kr');

Widget _app(FakeAegilApi api, {VoidCallback? onKurv, VoidCallback? onEndret}) => MaterialApp(
  home: Scaffold(
    body: Builder(
      builder: (ctx) => TextButton(key: const Key('aapne'), onPressed: () => FastUkeshandel.vis(ctx, api: api, onKurv: onKurv, onEndret: onEndret), child: const Text('åpne')),
    ),
  ),
);

Future<void> _open(WidgetTester t) async {
  await t.tap(find.byKey(const Key('aapne')));
  await t.pumpAndSettle();
}

void _phone(WidgetTester t) {
  t.view.physicalSize = const Size(1170, 2532);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

void main() {
  setUpAll(() async {
    await a3Bootstrap();
  });
  late FakeAegilApi api;
  late List<Uri> opened;
  setUp(() {
    api = FakeAegilApi();
    opened = [];
    FastUkeshandel.launcher = (u) async => opened.add(u);
    ClientFlags.flags = {ClientFlags.aegilLevel4: true};
  });
  tearDown(A3Services.reset);

  testWidgets('the opt-in: consent first, then the standing order with Vipps — the agreement opens, «Jeg har bekreftet» syncs to active', (t) async {
    _phone(t);
    api.standingUrl = 'https://vipps.test/agreement/agr_1';
    var endret = 0;
    await t.pumpWidget(_app(api, onEndret: () => endret++));
    await _open(t);
    expect(find.byKey(const Key('meg-fast-oppsett')), findsOneWidget);
    expect(find.text(FastCopy.standing_order_notice), findsOneWidget);
    await t.tap(find.byKey(const Key('fast-start')));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text(FastCopy.cus_fast_samtykke_kreves), findsOneWidget, reason: 'nothing without the explicit consent');
    expect(api.calls.where((c) => c.startsWith('standing-create')), isEmpty);
    await t.pump(const Duration(seconds: 3));

    // The cap from its picker, then the consent, then start.
    await t.tap(find.byKey(const Key('fast-tak')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('fast-velg-1500')));
    await t.pumpAndSettle();
    expect(find.text('1500 kr'), findsOneWidget);
    await t.tap(find.byKey(const Key('fast-samtykke')));
    await t.pump();
    await t.tap(find.byKey(const Key('fast-start')));
    await t.pumpAndSettle();
    expect(api.calls, contains('standing-create:4:17-20:1500:vipps_recurring:${FastUkeshandel.consentVersion}'));
    expect(opened.map((u) => u.toString()), ['https://vipps.test/agreement/agr_1'], reason: 'the Vipps hand-off');
    expect(find.byKey(const Key('meg-fast-venter')), findsOneWidget);

    // Not confirmed yet → told; confirmed → active and the overview.
    await t.tap(find.byKey(const Key('fast-sjekk')));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text(FastCopy.cus_fast_ikke_aktiv_enna), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
    api.syncedValue = _active;
    await t.tap(find.byKey(const Key('fast-sjekk')));
    await t.pumpAndSettle();
    expect(api.calls.where((c) => c == 'standing-sync').length, 2);
    expect(find.byKey(const Key('meg-fast-oversikt')), findsOneWidget);
    expect(find.text('torsdag kl. 17–20 · inntil 1 000 kr'), findsOneWidget);
    expect(endret, greaterThanOrEqualTo(2));
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('the overview: «Endre» on the noticed week opens the basket; «Pause» then «Fortsett»; «Avslutt» asks first', (t) async {
    _phone(t);
    api.standingValue = _active;
    var kurv = 0;
    await t.pumpWidget(_app(api, onKurv: () => kurv++));
    await _open(t);
    expect(find.byKey(const Key('meg-fast-oversikt')), findsOneWidget);
    expect(find.text(FastCopy.cus_fast_run_noticed('268 kr', 'onsdag 20:00')), findsOneWidget);
    expect(find.text(FastCopy.cus_fast_endre), findsOneWidget);
    await t.tap(find.byKey(const Key('fast-neste')));
    await t.pumpAndSettle();
    expect(kurv, 1);

    await _open(t);
    await t.tap(find.byKey(const Key('fast-pause')));
    await t.pumpAndSettle();
    expect(api.calls, contains('standing-pause'));
    expect(find.text(FastCopy.cus_fast_pauset), findsOneWidget);
    expect(find.byKey(const Key('fast-fortsett')), findsOneWidget);
    expect(find.text(FastCopy.cus_fast_endre), findsNothing, reason: 'paused: nothing to edit');
    await t.tap(find.byKey(const Key('fast-fortsett')));
    await t.pumpAndSettle();
    expect(api.calls, contains('standing-resume'));
    expect(find.byKey(const Key('fast-pause')), findsOneWidget);

    await t.tap(find.byKey(const Key('fast-avslutt')));
    await t.pumpAndSettle();
    expect(find.text(FastCopy.cus_fast_avslutt_sporsmal), findsOneWidget);
    await t.tap(find.text(FastCopy.cus_fast_avbryt));
    await t.pumpAndSettle();
    expect(api.calls, isNot(contains('standing-end')));
    await t.tap(find.byKey(const Key('fast-avslutt')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('fast-avslutt-ja')));
    await t.pumpAndSettle();
    expect(api.calls, contains('standing-end'));
    expect(find.byKey(const Key('meg-fast-oversikt')), findsNothing);
    expect(find.text(FastCopy.cus_fast_avsluttet), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('a failed payment: the state is said, and «Fortsett» is the way on', (t) async {
    _phone(t);
    api.standingValue = _failed;
    await t.pumpWidget(_app(api));
    await _open(t);
    expect(find.byKey(const Key('fast-betaling-feilet')), findsOneWidget);
    expect(find.text(FastCopy.cus_fast_run_failed), findsOneWidget);
    expect(find.byKey(const Key('fast-fortsett')), findsOneWidget);
  });

  testWidgets('Meg\'s Ukeshandel Ark carries the «Fast ukeshandel» row, and the settings\' level-4 row opens it instead of «Kommer snart»', (t) async {
    _phone(t);
    var fast = 0;
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => Column(children: [
            TextButton(key: const Key('aapne-uke'), onPressed: () => MegSheets.ukeshandel(ctx, api: api, view: const WeeklyView(), level: 3, onFast: () => fast++), child: const Text('uke')),
            Expanded(
              child: SingleChildScrollView(
                child: AegilInnstListe(settings: const AegilSettings(level: 3), levels: const [], onEndre: (e, {toast}) async {}, onButikker: () async {}, onFast: () => fast++),
              ),
            ),
          ]),
        ),
      ),
    ));
    await t.pump(const Duration(milliseconds: 600));
    final rad4 = find.byKey(const Key('ae-innst-nivaa-4'));
    expect(find.descendant(of: rad4, matching: find.text(AeInnstCopy.settOpp)), findsOneWidget);
    expect(find.descendant(of: rad4, matching: find.text(AeInnstCopy.kommerSnart)), findsNothing);
    await t.tap(rad4);
    await t.pump();
    expect(fast, 1);

    await t.tap(find.byKey(const Key('aapne-uke')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('uke-fast')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('uke-fast')), matching: find.text(FastCopy.cus_fast_sett_opp)), findsOneWidget);
    await t.tap(find.byKey(const Key('uke-fast')));
    await t.pumpAndSettle();
    expect(fast, 2);
  });

  test('the standing models read the server shape', () {
    final s = StandingView.fromJson(const {
      'id': 3, 'state': 'paused', 'schedule_dow': 2, 'schedule_day': 'tirsdag', 'window': '18-21', 'cap': {'amount_ore': 75000, 'display': '750 kr'},
      'payment_method': 'card', 'pause_reason': 'payment_failed', 'consent_version': 'app-2026-11',
      'agreement': {'state': 'pending', 'confirmation_url': 'https://vipps.test/a'},
      'next': {'week': '2026-W45', 'cutoff_line': 'onsdag 20:00', 'delivery_at': '2026-11-05T17:00:00+01:00', 'notice_at': '2026-11-03T20:00:00+01:00'},
      'run': {'id': 9, 'week': '2026-W45', 'state': 'placed', 'total': {'amount_ore': 26800, 'display': '268 kr'}, 'line_count': 3, 'order_ids': [1, 2]},
      'line': 'tirsdag kl. 18–21 · inntil 750 kr',
    });
    expect([s.id, s.state, s.scheduleDow, s.window, s.cap, s.capKr, s.paymentMethod, s.paymentFailed, s.agreementState, s.confirmationUrl, s.nextCutoffLine], [3, 'paused', 2, '18-21', '750 kr', 750, 'card', true, 'pending', 'https://vipps.test/a', 'onsdag 20:00']);
    expect([s.run!.state, s.run!.total, s.run!.lineCount, s.run!.orderIds], ['placed', '268 kr', 3, [1, 2]]);
    expect(FastUkeshandel.runLine(s), FastCopy.cus_fast_run_placed);
  });
}
