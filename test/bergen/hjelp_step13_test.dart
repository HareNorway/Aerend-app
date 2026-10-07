import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aerend_customer/l10n/app_localizations.dart';
import 'package:aerend_customer/main.dart' as app;
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/hjelp/noe_galt_sheet.dart';
import 'package:aerend_customer/screens/bergen/hjelp/support.dart';
import 'package:aerend_customer/screens/bergen/meg/bestillinger_screen.dart';
import 'package:aerend_customer/screens/bergen/sporing/hjelp_sheet.dart';
import 'package:aerend_customer/utils/shared_pref_utill.dart';

/// Launch UI Step 13 — help and support: «Hjelp og kontakt», the support
/// chat (assistant → a person), the guest step, «Sak på ordren» and «Noe
/// galt med bestillingen?». Cases go through `ops.customer.problem`.
class _Api extends OpsCustomerApi {
  _Api({this.rows = const []});

  final List<Map<String, dynamic>> rows;
  final List<Map<String, dynamic>> problems = [];
  final List<Map<String, dynamic>> contacts = [];

  @override
  Future<List<Map<String, dynamic>>> orders({int limit = 50}) async => rows;

  @override
  Future<List<Map<String, dynamic>>> pointsLedger() async => const [];

  @override
  Future<Map<String, dynamic>> tracking(int orderId) async => throw StateError('offline');

  @override
  Future<Map<String, dynamic>?> problem(int orderId, {required String kind, String? words, List<String>? items}) async {
    problems.add({'order': orderId, 'kind': kind, 'words': words, 'items': items});
    return {'kind': kind, 'problem_id': 40 + problems.length, 'customer_sees': 'Vi sjekker bestillingen din med butikken.'};
  }

  @override
  Future<Map<String, dynamic>?> contact(int orderId, {required String kind, String? message}) async {
    contacts.add({'order': orderId, 'kind': kind, 'message': message});
    return {'kind': kind};
  }

  /// `support/guest/lookup` / `verify` as the server answers them (Step 5).
  final List<(String, Map<String, dynamic>)> guest = [];

  @override
  Future<(int, Map<String, dynamic>)?> supportGuest(String step, Map<String, dynamic> body) async {
    guest.add((step, body));
    final ordre = '${body['order_no']}';
    if (ordre != 'Æ-42K') return (422, <String, dynamic>{'error': 'ORDER_NOT_FOUND'});
    if (step == 'lookup') return (200, <String, dynamic>{'status': 1, 'sent_to': '•••• ••34'});
    if (body['code'] != '4831') return (422, <String, dynamic>{'error': 'INVALID_CODE'});
    return (200, <String, dynamic>{'status': 1, 'guest_token': 'gjest-token', 'order_id': 42});
  }
}

Map<String, dynamic> _ordre(int id, String state, {bool paid = true}) => {
  'order_id': id,
  'code': 'Æ-$id',
  'store': {'id': 6, 'name': 'Holy Cow'},
  'ordered_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
  'total_pay': 248,
  'delivery_cost': 39,
  'state': state,
  'stage_label': state == 'delivered' ? 'Levert' : 'På vei',
  'paid': paid,
  'items': [
    {'product_id': 1, 'name': 'Classic', 'quantity': 1, 'unit_price': 149},
    {'product_id': 2, 'name': 'Classic Fries', 'quantity': 1, 'unit_price': 60},
  ],
};

Future<void> _login({bool inn = true}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    if (inn) prefUserId: 656,
    if (inn) prefAccessToken: 'tok',
    prefUserName: 'Kari Nordmann',
  });
  await initSharedPreferences();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    app.languages = await AppLocalizations.delegate.load(const Locale('no'));
    OpsCustomerApi.networkEnabled = false;
  });

  void phone(WidgetTester t) {
    t.view.physicalSize = const Size(390, 1600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  // Ægil "thinks" for 1.3 s before each answer.
  Future<void> svar(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 1400));
    await t.pump(const Duration(milliseconds: 400));
  }

  testWidgets('Hjelp og kontakt: the hub with no order on its way — chat, FAQ, e-mail', (tester) async {
    phone(tester);
    await _login();
    final api = _Api(rows: [_ordre(275, 'delivered')]);
    SupportStore.instance.reset(api: api);
    await tester.pumpWidget(MaterialApp(home: HjelpScreen(api: api, initial: HjelpState.hub)));
    await settle(tester);

    expect(find.byKey(const Key('a1_hjelp_hub')), findsOneWidget);
    expect(find.text(SupportCopy.hjelpOgKontakt), findsOneWidget);
    expect(find.byKey(const Key('a1_hjelp_hub_aapen')), findsOneWidget);
    expect(find.text(SupportCopy.chatMedOss), findsOneWidget);
    for (final f in SupportCopy.faq) {
      expect(find.text(f.$1), findsOneWidget, reason: f.$1);
    }
    expect(find.byKey(const Key('a1_hjelp_epost')), findsOneWidget);
    expect(find.byKey(const Key('a1_hjelp_hub_fortsett')), findsNothing);

    // A FAQ question opens the chat with it and Ægil's answer.
    await tester.tap(find.byKey(const Key('a1_hjelp_faq_0')));
    await svar(tester);
    expect(find.byKey(const Key('a1_hjelp_chat')), findsOneWidget);
    expect(find.text(SupportCopy.faq[0].$1), findsOneWidget);
    expect(find.text(SupportCopy.refusjon), findsOneWidget);

    // Back: the hub offers to continue the conversation.
    await tester.tap(find.byKey(const Key('a1_sporing_hjelp_tilbake')));
    await settle(tester);
    expect(find.byKey(const Key('a1_hjelp_hub_fortsett')), findsOneWidget);
  });

  testWidgets('Hjelp og kontakt with an order on its way opens that order\'s main state', (tester) async {
    phone(tester);
    await _login();
    final api = _Api(rows: [_ordre(280, 'picked_up'), _ordre(275, 'delivered')]);
    SupportStore.instance.reset(api: api);
    await tester.pumpWidget(MaterialApp(home: HjelpScreen(api: api, initial: HjelpState.hub)));
    await settle(tester);
    expect(find.byKey(const Key('a1_sporing_hjelp_main')), findsOneWidget);
    expect(find.byKey(const Key('a1_hjelp_hub')), findsNothing);
  });

  testWidgets('Support chat: «Hvor er bestillingen?» answers with the order card; «Noe mangler» asks, a line files the case', (tester) async {
    phone(tester);
    await _login();
    final api = _Api(rows: [_ordre(280, 'picked_up')]);
    SupportStore.instance.reset(api: api);
    await tester.pumpWidget(MaterialApp(home: HjelpScreen(api: api, initial: HjelpState.chat)));
    await settle(tester);

    expect(find.byKey(const Key('a1_hjelp_chat')), findsOneWidget);
    expect(find.text(SupportCopy.emneSupport), findsOneWidget);
    expect(find.textContaining('Hei Kari. Jeg er Ærend-assistenten.'), findsOneWidget);

    await tester.tap(find.text(SupportCopy.hvorEr));
    await svar(tester);
    expect(find.byKey(const Key('a1_hjelp_kort_ordre')), findsOneWidget);
    expect(find.text('Holy Cow · 248 kr'), findsOneWidget);
    expect(find.text('Bestillingen er på vei.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('a1_hjelp_chat_felt')), SupportCopy.noeMangler);
    await tester.tap(find.byKey(const Key('a1_hjelp_chat_send')));
    await svar(tester);
    expect(find.text(SupportCopy.hvaMangler(SupportOrdre.fraRad(_ordre(280, 'picked_up')))), findsOneWidget);

    await tester.tap(find.text('Classic Fries'));
    await svar(tester);
    // Backend plan Step 5: the case kind itself, not the old «missing».
    expect(api.problems.single['kind'], 'missing_item');
    expect(api.problems.single['items'], ['Classic Fries']);
    expect(find.byKey(const Key('a1_hjelp_kort_sak')), findsOneWidget);
    expect(find.textContaining('SAK-41'), findsOneWidget);
    expect(SupportStore.instance.sakFor(280)?.problemId, 41);
  });

  testWidgets('«Snakk med et menneske» queues once; a person who takes over is named', (tester) async {
    phone(tester);
    await _login();
    final api = _Api(rows: [_ordre(275, 'delivered')]);
    SupportStore.instance.reset(api: api);
    await tester.pumpWidget(MaterialApp(home: HjelpScreen(api: api, initial: HjelpState.chat)));
    await settle(tester);

    await tester.tap(find.byKey(const Key('a1_hjelp_chat_menneske')));
    await svar(tester);
    expect(find.text(SupportCopy.eskalert), findsOneWidget);
    expect(find.textContaining('Du står i kø for et menneske'), findsOneWidget);

    await tester.tap(find.byKey(const Key('a1_hjelp_chat_menneske')));
    await tester.pump();
    expect(find.text(SupportCopy.allerede), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));

    final s = SupportStore.instance.aapen!;
    SupportAssistent.taOver(s, 'Kari N.', 'Kari');
    await settle(tester);
    expect(find.text(SupportCopy.tokOver('Kari')), findsOneWidget);
    expect(find.text(SupportCopy.iSamtalen('Kari')), findsOneWidget);
    expect(find.text(SupportCopy.menneskeUnder('Kari')), findsOneWidget);
  });

  testWidgets('Guest: order number, then the code; wrong ones show the 422 line', (tester) async {
    phone(tester);
    await _login(inn: false);
    final api = _Api();
    SupportStore.instance.reset(api: api);
    await tester.pumpWidget(MaterialApp(home: HjelpScreen(api: api, initial: HjelpState.chat)));
    await settle(tester);

    expect(find.byKey(const Key('a1_hjelp_gjest')), findsOneWidget);
    expect(find.text(SupportCopy.gjestTittel), findsOneWidget);

    await tester.enterText(find.byKey(const Key('a1_hjelp_gjest_ordre')), 'hei');
    await tester.tap(find.byKey(const Key('a1_hjelp_gjest_neste')));
    await tester.pump();
    expect(find.text('422 · ORDER_NOT_FOUND'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('a1_hjelp_gjest_ordre')), 'Æ-42K');
    await tester.pump();
    await tester.tap(find.byKey(const Key('a1_hjelp_gjest_neste')));
    await tester.pump();
    expect(find.byKey(const Key('a1_hjelp_gjest_kode')), findsOneWidget);
    expect(find.text(SupportCopy.bekreftKode), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));

    await tester.enterText(find.byKey(const Key('a1_hjelp_gjest_kode')), '12');
    await tester.tap(find.byKey(const Key('a1_hjelp_gjest_neste')));
    await tester.pump();
    expect(find.text('422 · INVALID_CODE'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('a1_hjelp_gjest_kode')), '4831');
    await tester.pump();
    await tester.tap(find.byKey(const Key('a1_hjelp_gjest_neste')));
    await settle(tester);
    expect(find.byKey(const Key('a1_hjelp_gjest')), findsNothing);
    expect(find.byKey(const Key('a1_hjelp_chat_traad')), findsOneWidget);
    // The server's lookup / verify, and the guest token kept for the chat.
    expect([for (final g in api.guest) g.$1], ['lookup', 'lookup', 'verify', 'verify']);
    expect(SupportStore.instance.gjestToken, 'gjest-token');
    expect(SupportStore.instance.gjestOrdreId, 42);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Ordrehistorikk: «Noe galt» in three steps files the case; «Sak på ordren» then shows', (tester) async {
    phone(tester);
    await _login();
    final api = _Api(rows: [_ordre(275, 'delivered')]);
    SupportStore.instance.reset(api: api);
    await tester.pumpWidget(MaterialApp(home: BestillingerScreen(api: api)));
    await settle(tester);

    await tester.tap(find.byKey(const Key('oh-ordre-275')));
    await settle(tester);
    expect(find.byKey(const Key('oh-ordre-sheet')), findsOneWidget);
    expect(find.byKey(const Key('oh-sak')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('oh-noe-galt')));
    await tester.tap(find.byKey(const Key('oh-noe-galt')));
    await settle(tester);

    expect(find.byKey(const Key('oh-noe-galt-1')), findsOneWidget);
    expect(find.text(SupportCopy.noeGaltTittel('Æ-275')), findsOneWidget);
    await tester.tap(find.byKey(const Key('noe-galt-missing_item')));
    await settle(tester);
    expect(find.byKey(const Key('oh-noe-galt-2')), findsOneWidget);
    expect(find.text('Classic Fries'), findsOneWidget);
    expect(find.text('60 kr'), findsOneWidget);
    await tester.tap(find.byKey(const Key('noe-galt-linje-1')));
    await settle(tester);
    expect(find.byKey(const Key('oh-noe-galt-3')), findsOneWidget);
    expect(find.text('Mangler noe · Classic Fries · Æ-275'), findsOneWidget);
    await tester.tap(find.byKey(const Key('noe-galt-ferdig')));
    await settle(tester);
    expect(api.problems.single['items'], ['Classic Fries']);
    expect(find.text(SupportCopy.registrert), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));

    await tester.tap(find.byKey(const Key('oh-ordre-275')));
    await settle(tester);
    expect(find.byType(SakPaaOrdren), findsOneWidget);
    expect(find.text(SupportCopy.ack), findsOneWidget);
  });

  testWidgets('Kom aldri files a not_delivered case on the order', (tester) async {
    phone(tester);
    await _login();
    final api = _Api(rows: [_ordre(278, 'delivered')]);
    SupportStore.instance.reset(api: api);
    await tester.pumpWidget(MaterialApp(home: HjelpScreen(orderId: 278, api: api, initial: HjelpState.komAldri)));
    await settle(tester);
    expect(find.text(SupportCopy.emneKomAldri), findsOneWidget);
    // Backend plan Step 5: a real case (kind not_delivered), not a message.
    expect(api.problems.single['kind'], 'not_delivered');
    expect(api.contacts, isEmpty);
    expect(find.byKey(const Key('a1_hjelp_kort_sak')), findsOneWidget);
  });
}
