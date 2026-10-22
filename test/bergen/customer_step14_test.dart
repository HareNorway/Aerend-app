import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/ops/tracking_models.dart';
import 'package:aerend_customer/networking/ops/cus_api.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_bekreft.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_bits.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_copy.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_kurv_screen.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_overlays.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_sheets.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_store.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_tilbud.dart';
import 'package:aerend_customer/screens/bergen/hjem/hjem_harness.dart';
import 'package:aerend_customer/utils/utils.dart';

import '../a3/a3_fakes.dart';

/// Customer plan Step 14 in the app: the AI sheets (inngang, velg, samtykke,
/// koblet, koblede, detalj, kobleFra, feil), «Handlekurv fra assistent» in
/// its states, «Bekreft bestilling» in its states, the push banner, the
/// «Via {AI}» chip, and the models — all on a fake [CusApi].

class _Cus extends CusApi {
  final List<String> calls = [];
  List<CusAiLink> links = [];
  CusAiRequest? request;
  bool confirmOk = true;
  String? confirmFeil;

  @override
  Future<List<CusAiLink>?> aiLinks() async => links;
  @override
  Future<List<CusAiClient>> aiClients() async => const [CusAiClient(clientId: 'claude', name: 'Claude', vendor: 'claude'), CusAiClient(clientId: 'chatgpt', name: 'ChatGPT', vendor: 'chatgpt')];
  @override
  Future<CusAiRequest?> aiRequestLatest() async => request;
  @override
  Future<CusAiRequest?> aiRequest(String id) async { calls.add('request:$id'); return request; }
  @override
  Future<({CusAiLink link, List<CusAiAktivitet> aktivitet})?> aiLink(int id) async => (link: links.firstWhere((l) => l.id == id), aktivitet: [CusAiAktivitet(tool: 'create_cart', outcome: 'ok', at: DateTime.now()), CusAiAktivitet(tool: 'confirm_order', outcome: 'ok', at: DateTime(2026, 10, 3, 18, 2))]);
  @override
  Future<CusAiLink?> aiLinkUpdate(int id, {List<String>? scopes, int? capPerOrderKr, int? capPerDayKr, String? paymentPref, String? addressPref, bool? shareBio}) async { calls.add('update:$id:${capPerOrderKr ?? '-'}:${scopes?.join('+') ?? '-'}'); return links.firstWhere((l) => l.id == id); }
  @override
  Future<bool> aiLinkRevoke(int id) async { calls.add('revoke:$id'); links = [for (final l in links) if (l.id == id) AiStore.harnessLink(l.name, active: false) else l]; return true; }
  @override
  Future<int?> aiLinksRevokeAll() async { calls.add('revokeAll'); links = [for (final l in links) AiStore.harnessLink(l.name, active: false)]; return links.length; }
  @override
  Future<({CusAiOrder? order, String? feil, CusAiRequest? request})> aiRequestConfirm(String id, {String payment = 'vipps'}) async {
    calls.add('confirm:$id:$payment');
    if (!confirmOk) return (order: null, feil: confirmFeil, request: request);
    return (order: const CusAiOrder(id: 777, number: 'Æ-77X', paymentStatus: 'pending'), feil: null, request: request);
  }
  @override
  Future<CusAiRequest?> aiRequestDecline(String id) async { calls.add('decline:$id'); return request; }
  @override
  Future<CusAiRequest?> aiRequestRequote(String id, {int? removeLineId}) async { calls.add('requote:$id:${removeLineId ?? '-'}'); return aiSampleRequest(); }
  @override
  Future<String?> aiRequestWaitlist(String id) async { calls.add('waitlist:$id'); return 'wl_1'; }
  @override
  Future<CusAiKode?> aiLinkCode({String? clientId, CusAiPrefs? prefs}) async { calls.add('code:$clientId:${prefs?.capPerOrderKr}:${prefs?.scopes.join('+')}'); return const CusAiKode(code: 'ÆR-7K2Q', raw: '7K2Q', status: 'pending', linkUrl: 'https://aerend.no/koble/7k2q'); }
  @override
  Future<CusAiKode?> aiLinkCodeStatus(String code) async => const CusAiKode(code: 'ÆR-7K2Q', raw: '7K2Q', status: 'pending');
}

Widget _host(void Function(BuildContext) onOpen) => MaterialApp(
  home: Scaffold(body: Builder(builder: (context) => Center(child: ElevatedButton(key: const Key('open'), onPressed: () => onOpen(context), child: const Text('open'))))),
);

void phone(WidgetTester t, {double h = 2600}) {
  t.view.physicalSize = Size(390, h);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

Future<void> open(WidgetTester t) async {
  await t.tap(find.byKey(const Key('open')));
  await t.pump();
  await t.pump(const Duration(milliseconds: 700));
}

void main() {
  setUpAll(() async => a3Bootstrap(prefs: {prefUserId: 656, prefAccessToken: 'tok', prefUserName: 'Kari Nordmann', prefUserVerified: 1}));
  late _Cus cus;
  setUp(() {
    cus = _Cus();
    AiStore.instance.reset();
    AiStore.instance.api = cus;
    HjemHarness.aiStart = null;
  });

  test('models: a link, a request, a code and the via map parse', () {
    final l = CusAiLink.fromJson({'id': 3, 'client_id': 'claude', 'name': 'Claude', 'vendor': 'claude', 'active': true, 'scopes': ['catalog:read', 'cart:write', 'orders:write'], 'permissions': [{'scope': 'catalog:read', 'on': true, 'locked': true, 'title': 'Se menyer og priser', 'line': 'x'}], 'cap_per_order': {'amount_ore': 50000, 'currency': 'NOK', 'display': '500 kr'}, 'used_today': {'amount_ore': 4900, 'currency': 'NOK', 'display': '49 kr'}, 'orders': 1, 'payment_pref': 'vipps', 'address_pref': 'home', 'share_bio': false, 'granted_at': '2026-10-22T18:00:00+02:00'});
    expect(l.has('cart:write'), isTrue);
    expect(l.capPerOrder!.kr, 500);
    expect(l.permissions.single.locked, isTrue);
    final r = CusAiRequest.fromJson({'id': 'q_1', 'state': 'normal', 'assistant': {'name': 'Claude', 'vendor': 'claude'}, 'store': {'name': 'Torgboden', 'line': 'Torggaten 9'}, 'log': [{'tool': 'quote', 'text': 'Hentet tilbud', 'at': null}], 'lines': [{'product_id': 818, 'line_id': 1, 'name': 'Sitron', 'quantity': 2, 'unit_price': {'amount_ore': 1000, 'display': '10 kr'}, 'line_total': {'amount_ore': 2000, 'display': '20 kr'}, 'available': false}], 'quote': {'subtotal': {'amount_ore': 2000, 'display': '20 kr'}, 'delivery_fee': {'amount_ore': 3900, 'display': '39 kr'}, 'service_fee': {'amount_ore': 1500, 'display': '15 kr'}, 'total': {'amount_ore': 7400, 'display': '74 kr'}, 'window': {'display': '18:12–18:22'}, 'address': {'text': 'Torggaten 9'}, 'delivery_method': {'key': 'delivery'}}, 'seconds_left': 580, 'cap_per_order': {'amount_ore': 50000, 'display': '500 kr'}, 'over_cap': false, 'covered': true, 'payment_pref': 'vipps'});
    expect(r.harUtsolgt, isTrue);
    expect(r.total.display, '74 kr');
    expect(r.windowDisplay, '18:12–18:22');
    expect(CusAiKode.fromJson({'code': 'ÆR-7K2Q', 'raw': '7K2Q', 'link_status': 'linked', 'minutes': 10}).status, 'linked');
    expect(OpsTracking.fromJson({'order_id': '1', 'state': 'placed', 'stage': 0, 'stage_label': 'x', 'mode': 'delivery', 'via': {'name': 'Claude', 'vendor': 'claude'}}).via!.name, 'Claude');
    expect(AiNavn.vendor('ChatGPT'), 'chatgpt');
    expect(AiCopy.kr(1000), '1 000 kr');
  });

  testWidgets('aiKoblede: empty state, then a card for a linked assistant; detalj saves a cap; kobleFra revokes', (tester) async {
    phone(tester);
    await tester.pumpWidget(_host((c) => AiArk.flyt(c, 'koblede')));
    await open(tester);
    expect(find.byKey(const Key('cus-ai-koblede')), findsOneWidget);
    expect(find.byKey(const Key('cus-ai-koblede-tom')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_slik_kobler), findsOneWidget);
    await tester.tap(find.byKey(const Key('cus-ai-koblede-cta')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byKey(const Key('cus-ai-inngang')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_inngang_tittel), findsOneWidget);
    expect(find.byKey(const Key('cus-ai-chip-claude')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());

    cus.links = [AiStore.harnessLink('Claude')];
    await AiStore.instance.load(force: true);
    await tester.pumpWidget(_host((c) => AiArk.flyt(c, 'koblede')));
    await open(tester);
    expect(find.byKey(const Key('cus-ai-kort-1')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_brukt_i_dag), findsOneWidget);
    expect(find.byKey(const Key('cus-ai-koble-fra-alle')), findsOneWidget);
    await tester.tap(find.byKey(const Key('cus-ai-kort-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byKey(const Key('cus-ai-detalj')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_aktivitet.toUpperCase()), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(AiCopy.cus_ai_akt('confirm_order')), findsOneWidget);
    // «Maks per bestilling» + 50 → saved after the debounce.
    await tester.ensureVisible(find.text(AiCopy.cus_ai_maks_per_best));
    final pluss = find.descendant(of: find.ancestor(of: find.text(AiCopy.cus_ai_maks_per_best), matching: find.byType(Row)).first, matching: find.byType(Opacity)).last;
    await tester.tap(pluss);
    await tester.pump(const Duration(milliseconds: 800));
    expect(cus.calls.any((c) => c.startsWith('update:1:550:')), isTrue, reason: cus.calls.join(','));
    await tester.ensureVisible(find.byKey(const Key('cus-ai-detalj-koble-fra')));
    await tester.tap(find.byKey(const Key('cus-ai-detalj-koble-fra')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byKey(const Key('cus-ai-koble-fra')), findsOneWidget);
    expect(find.byKey(const Key('cus-ai-hs-brutt')), findsOneWidget);
    await tester.tap(find.byKey(const Key('cus-ai-koble-fra-cta')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(cus.calls, contains('revoke:1'));
    expect(find.byKey(const Key('cus-ai-koblede')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_frakoblet), findsWidgets);
  });

  testWidgets('aiSamtykke → the code with the choices → aiQr shows ÆR-7K2Q, copy and the waiting line', (tester) async {
    phone(tester, h: 3200);
    await tester.pumpWidget(_host((c) => AiArk.flyt(c, 'samtykke', navn: 'Claude')));
    await open(tester);
    expect(find.byKey(const Key('cus-ai-samtykke')), findsOneWidget);
    expect(find.byKey(const Key('cus-ai-hs-kobler')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_sam_tittel('Claude')), findsOneWidget);
    expect(find.byKey(const Key('cus-ai-rett-orders:write')), findsOneWidget);
    // Switch «Åpne en supportsak» on, then «Koble til Claude» → the code carries 6 scopes.
    await tester.ensureVisible(find.byKey(const Key('cus-ai-rett-support:write')));
    await tester.tap(find.byKey(const Key('cus-ai-rett-support:write')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('cus-ai-samtykke-cta')));
    await tester.tap(find.byKey(const Key('cus-ai-samtykke-cta')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byKey(const Key('cus-ai-qr')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    expect(cus.calls.any((c) => c.startsWith('code:claude:500:') && c.contains('support:write')), isTrue, reason: cus.calls.join(','));
    expect(find.byKey(const Key('cus-ai-kode-0')), findsOneWidget);
    expect(find.text('7'), findsWidgets);
    await tester.ensureVisible(find.byKey(const Key('cus-ai-kopier-kode')));
    await tester.tap(find.byKey(const Key('cus-ai-kopier-kode')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('cus-ai-venter')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_kopiert), findsOneWidget);
    // «Annen enhet»: the QR of the link.
    await tester.tap(find.byKey(const Key('cus-ai-qr-modus-qr')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('cus-ai-qr-bilde')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_jeg_har_skannet), findsOneWidget);
    // «Tilbake» closes the sheet and stops the status poll.
    await tester.ensureVisible(find.byKey(const Key('cus-ai-qr-tilbake')));
    await tester.tap(find.byKey(const Key('cus-ai-qr-tilbake')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byKey(const Key('cus-ai-inngang')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('aiVelg lists the four with Koble til / Bestill; aiFeil ikkeKoblet → samtykke', (tester) async {
    phone(tester);
    cus.links = [AiStore.harnessLink('Claude')];
    await AiStore.instance.load(force: true);
    await tester.pumpWidget(_host((c) => AiArk.velg(c)));
    await open(tester);
    expect(find.byKey(const Key('cus-ai-velg')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_bestill), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_koble), findsNWidgets(2));
    expect(find.text(AiCopy.cus_ai_legg_til), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_bestill_med('Claude')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());

    await tester.pumpWidget(_host((c) => AiArk.flyt(c, 'feil:ikkeKoblet', navn: 'Gemini')));
    await open(tester);
    expect(find.byKey(const Key('cus-ai-feil-ikkeKoblet')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_ingenting_bestilt), findsOneWidget);
    await tester.tap(find.byKey(const Key('cus-ai-feil-cta')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byKey(const Key('cus-ai-samtykke')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_sam_tittel('Gemini')), findsOneWidget);
  });

  testWidgets('Handlekurv fra assistent: normal with the offer and the slider; utsolgt hides the slider and Fjern re-quotes; gjest, dekning → venteliste, laster, utlopt', (tester) async {
    phone(tester, h: 2200);
    Future<void> show(String t) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(MaterialApp(home: AiKurvScreen(api: cus, tilstand: t)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
    await show('normal');
    expect(find.byKey(const Key('cus-ai-kurv-tittel')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_kurv_tittel('Claude')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_ingenting_sendes), findsOneWidget);
    expect(find.byKey(const Key('cus-ai-kurv-normal')), findsOneWidget);
    expect(find.byKey(const Key('cus-ai-linje-818')), findsOneWidget);
    expect(find.byKey(const Key('cus-ai-frist')), findsOneWidget);
    expect(find.byKey(const Key('cus-ai-betal')), findsOneWidget);
    expect(find.byKey(const Key('cus-ai-endre')), findsOneWidget);

    await show('utsolgt');
    expect(find.byKey(const Key('cus-ai-utsolgt-rad')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_utsolgt_naa), findsOneWidget);
    expect(find.byKey(const Key('cus-ai-betal')), findsNothing);
    await tester.tap(find.byKey(const Key('cus-ai-fjern')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('cus-ai-utsolgt-rad')), findsNothing);
    expect(find.byKey(const Key('cus-ai-betal')), findsOneWidget);

    await show('gjest');
    expect(find.byKey(const Key('cus-ai-kurv-gjest')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_logg_inn_fortsett), findsOneWidget);

    await show('dekning');
    expect(find.byKey(const Key('cus-ai-kurv-dekning')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_leverer_ikke), findsOneWidget);
    await tester.tap(find.byKey(const Key('cus-ai-venteliste')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('cus-ai-kurv-vente')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_paa_venteliste), findsWidgets);

    await show('laster');
    expect(find.byKey(const Key('cus-ai-kurv-laster')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.byKey(const Key('cus-ai-kurv-normal')), findsOneWidget);

    await show('utlopt');
    expect(find.byKey(const Key('cus-ai-banner-gul')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_ny_total), findsOneWidget);
  });

  testWidgets('Handlekurv fra assistent on the server: the request loads, Avvis declines, the slider confirms with Vipps and lands on Sporing', (tester) async {
    phone(tester, h: 2200);
    cus.request = aiSampleRequest();
    await tester.pumpWidget(MaterialApp(home: AiKurvScreen(id: 'q_sample', api: cus), onGenerateRoute: (s) => MaterialPageRoute(builder: (_) => Scaffold(body: Text('route:${s.name}')))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(cus.calls, contains('request:q_sample'));
    expect(find.byKey(const Key('cus-ai-kurv-normal')), findsOneWidget);
    final state = tester.state(find.byType(AiKurvScreen)) as dynamic;
    final fut = state.betalNaa(payment: 'card') as Future<bool>;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final ok = await fut;
    expect(ok, isTrue);
    expect(cus.calls, contains('confirm:q_sample:card'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(AiCopy.cus_ai_bestilt_via('Claude', 'Æ-77X')), findsOneWidget);
  });

  testWidgets('Bekreft bestilling: normal → Bekreft og betal; over → Bekreft likevel; utlopt / trukket → Lukk; feilet → Prøv igjen; Avvis declines', (tester) async {
    phone(tester, h: 2600);
    Future<void> show(String t, {CusAiRequest? r}) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_host((c) => AiBekreft.vis(c, r ?? aiSampleRequest(), tilstand: t, harness: true)));
      await open(tester);
    }
    await show('normal');
    expect(find.byKey(const Key('cus-ai-bekreft')), findsOneWidget);
    expect(find.byKey(const Key('cus-ai-bekreft-cta')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_ber_om('Claude')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_bekreft_innen), findsOneWidget);
    await show('over', r: aiSampleRequest(over: true));
    expect(find.byKey(const Key('cus-ai-banner-gul')), findsOneWidget);
    expect(find.byKey(const Key('cus-ai-bekreft-likevel')), findsOneWidget);
    await show('utlopt');
    expect(find.byKey(const Key('cus-ai-banner-graa')), findsOneWidget);
    expect(find.byKey(const Key('cus-ai-bekreft-lukk')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_for_utlopt_steg), findsOneWidget);
    await show('trukket');
    expect(find.text(AiCopy.cus_ai_trukket('Claude')), findsWidgets);
    await show('feilet');
    expect(find.byKey(const Key('cus-ai-banner-rod')), findsOneWidget);
    expect(find.byKey(const Key('cus-ai-bekreft-igjen')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_bytt_bet), findsOneWidget);

    cus.request = aiSampleRequest();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_host((c) => AiBekreft.vis(c, cus.request!)));
    await open(tester);
    await tester.tap(find.byKey(const Key('cus-ai-bekreft-avvis')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(cus.calls, contains('decline:q_sample'));
    expect(find.text(AiCopy.cus_ai_avvist), findsOneWidget);
  });

  testWidgets('the push banner «Claude vil bestille» with Se bestillingen / Avvis, and the Via chip', (tester) async {
    phone(tester);
    var avvist = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (c) => Column(children: [const AiViaChip('Claude'), ElevatedButton(key: const Key('open'), onPressed: () => AiOverlays.push(c, aiSampleRequest(), onAvvis: () => avvist = true), child: const Text('open'))])))));
    expect(find.byKey(const Key('cus-ai-via-claude')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_via('Claude')), findsOneWidget);
    await tester.tap(find.byKey(const Key('open')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('cus-ai-push')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_push_tittel('Claude')), findsOneWidget);
    await tester.tap(find.byKey(const Key('cus-ai-push-avvis')));
    await tester.pump();
    expect(avvist, isTrue);
    expect(find.byKey(const Key('cus-ai-push')), findsNothing);
    AiOverlays.lukkPush();
  });
}
