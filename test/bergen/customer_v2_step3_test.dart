import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/networking/ops/cus_api.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_copy.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_kurv_screen.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_store.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_tilbud.dart';
import 'package:aerend_customer/screens/bergen/hjem/hjem_harness.dart';
import 'package:aerend_customer/services/customer/client_flags.dart';
import 'package:aerend_customer/utils/utils.dart';

import '../a3/a3_fakes.dart';

/// Customer v2 Step 3 (spec §4.10 C, D, H; D2-4, D2-5, D2-7) in the app: over
/// the cap the slider opens the explicit confirmation; confirming starts the
/// payment and the order comes from `pay`; waiting, failed and withdrawn
/// requests; the method switch; «Bytt»; «Endre handlekurven» re-quotes; the
/// live refusals open their sheets.
class _Cus extends CusApi {
  final List<String> calls = [];
  CusAiRequest? request;
  String payResultat = 'confirmed';
  String? confirmFeil;
  List<CusAiAlternativ> alternativer = const [];

  @override
  Future<List<CusAiLink>?> aiLinks() async => const [];
  @override
  Future<List<CusAiClient>> aiClients() async => const [];
  @override
  Future<CusAiRequest?> aiRequestLatest() async => request;
  @override
  Future<CusAiRequest?> aiRequest(String id) async {
    calls.add('request:$id');
    return request;
  }

  @override
  Future<({CusAiBetaling? betaling, String? feil, CusAiRequest? request})> aiRequestConfirm(String id, {String payment = 'vipps', bool overLimitOk = false}) async {
    calls.add('confirm:$id:$payment${overLimitOk ? ':over' : ''}');
    if (confirmFeil != null) return (betaling: null, feil: confirmFeil, request: request);
    return (betaling: CusAiBetaling(method: payment), feil: null, request: request);
  }

  @override
  Future<({String resultat, CusAiOrder? order, CusAiRequest? request})> aiRequestPay(String id) async {
    calls.add('pay:$id');
    return (resultat: payResultat, order: payResultat == 'confirmed' ? const CusAiOrder(id: 777, number: 'Æ-77X', paymentStatus: 'paid') : null, request: request);
  }

  @override
  Future<List<CusAiAlternativ>> aiRequestAlternatives(String id, int lineId) async {
    calls.add('alternatives:$id:$lineId');
    return alternativer;
  }

  @override
  Future<CusAiRequest?> aiRequestRequote(String id, {int? removeLineId, int? addProductId}) async {
    calls.add('requote:$id:${removeLineId ?? '-'}:${addProductId ?? '-'}');
    return aiSampleRequest();
  }

  @override
  Future<CusAiRequest?> aiRequestDecline(String id) async => request;
}

void _phone(WidgetTester t) {
  t.view.physicalSize = const Size(390, 2400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

class _Ruter extends NavigatorObserver {
  final List<String> navn = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => navn.add(route.settings.name ?? '');
}

Widget _app(_Cus cus, [_Ruter? ruter]) => MaterialApp(
  home: AiKurvScreen(id: 'q_sample', api: cus),
  navigatorObservers: [if (ruter != null) ruter],
  onGenerateRoute: (s) => MaterialPageRoute(builder: (_) => Scaffold(body: Text('route:${s.name}'))),
);

Future<void> _settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
  await t.pump(const Duration(milliseconds: 400));
}

void main() {
  setUpAll(() async {
    await a3Bootstrap(prefs: {prefUserId: 656, prefAccessToken: 'tok', prefUserName: 'Kari Nordmann', prefUserVerified: 1});
    ClientFlags.flags = {ClientFlags.aiLinking: true};
  });
  late _Cus cus;
  setUp(() {
    cus = _Cus();
    AiStore.instance.reset();
    AiStore.instance.api = cus;
    HjemHarness.aiStart = null;
  });

  testWidgets('over the cap: the banner, and the slider opens «Bekreft likevel», which confirms explicitly', (tester) async {
    _phone(tester);
    cus.request = aiSampleRequest(state: 'over', over: true);
    await tester.pumpWidget(_app(cus));
    await _settle(tester);
    expect(find.byKey(const Key('cus-ai-kurv-over')), findsOneWidget);
    expect(find.byKey(const Key('cus-ai-betal')), findsOneWidget);
    final state = tester.state(find.byType(AiKurvScreen)) as dynamic;
    final fut = state.betalNaa(payment: 'vipps') as Future<bool>;
    await _settle(tester);
    expect(find.byKey(const Key('cus-ai-bekreft-likevel')), findsOneWidget);
    expect(cus.calls.where((c) => c.startsWith('confirm')), isEmpty, reason: 'nothing starts before the explicit confirmation');
    await tester.tap(find.byKey(const Key('cus-ai-bekreft-likevel')));
    await _settle(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(cus.calls, contains('confirm:q_sample:vipps:over'));
    expect(await fut, isFalse);
  });

  testWidgets('waiting for the payment: the banner and «Sjekk betalingen»; paid → Sporing', (tester) async {
    _phone(tester);
    cus.request = aiSampleRequest(state: 'betaler');
    cus.payResultat = 'paying';
    await tester.pumpWidget(_app(cus));
    await _settle(tester);
    expect(cus.calls, contains('pay:q_sample'), reason: 'asked once on arrival (the Vipps return link)');
    expect(find.byKey(const Key('cus-ai-kurv-venter-betaling')), findsOneWidget);
    expect(find.byKey(const Key('cus-ai-betal')), findsNothing);
    expect(find.byKey(const Key('cus-ai-endre')), findsNothing);
    cus.payResultat = 'confirmed';
    await tester.tap(find.byKey(const Key('cus-ai-sjekk')));
    await _settle(tester);
    expect(find.text(AiCopy.cus_ai_bestilt_via('Claude', 'Æ-77X')), findsOneWidget);
  });

  testWidgets('a failed payment can be tried again; a withdrawn request has no slider', (tester) async {
    _phone(tester);
    cus.request = aiSampleRequest(state: 'feilet');
    await tester.pumpWidget(_app(cus));
    await _settle(tester);
    expect(find.text(AiCopy.cus_ai_bet_feilet), findsOneWidget);
    expect(find.byKey(const Key('cus-ai-betal')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    cus.request = aiSampleRequest(state: 'trukket');
    await tester.pumpWidget(_app(cus));
    await _settle(tester);
    expect(find.text(AiCopy.cus_ai_trukket('Claude')), findsWidgets);
    expect(find.byKey(const Key('cus-ai-betal')), findsNothing);
    expect(find.byKey(const Key('cus-ai-endre')), findsNothing);
  });

  testWidgets('the method switch: «Betal med Vipps» / «Betal med kort» above the slider (D2-7)', (tester) async {
    _phone(tester);
    cus.request = aiSampleRequest();
    await tester.pumpWidget(_app(cus));
    await _settle(tester);
    expect(find.byKey(const Key('cus-ai-bet-vipps')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_betal_med_kort(cus.request!.total.ore ~/ 100)), findsOneWidget);
    await tester.tap(find.byKey(const Key('cus-ai-bet-card')));
    await tester.pump();
    final state = tester.state(find.byType(AiKurvScreen)) as dynamic;
    final fut = state.betalNaa() as Future<bool>;
    await _settle(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(cus.calls, contains('confirm:q_sample:card'));
    expect(await fut, isFalse);
  });

  testWidgets('«Bytt» lists the same store\'s products and swaps the sold-out line', (tester) async {
    _phone(tester);
    cus.request = aiSampleRequest(state: 'utsolgt');
    cus.alternativer = const [CusAiAlternativ(productId: 901, name: 'Remulade glutenfri', price: CusMoney(ore: 3400, display: '34 kr'))];
    await tester.pumpWidget(_app(cus));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('cus-ai-bytt')));
    await _settle(tester);
    expect(cus.calls, contains('alternatives:q_sample:2'));
    expect(find.text(AiCopy.cus_ai_bytt_tittel('Remulade')), findsOneWidget);
    await tester.tap(find.byKey(const Key('cus-ai-bytt-901')));
    await _settle(tester);
    expect(cus.calls, contains('requote:q_sample:2:901'));
  });

  testWidgets('«Endre handlekurven» opens Kurv and re-quotes on the way back', (tester) async {
    _phone(tester);
    cus.request = aiSampleRequest();
    final ruter = _Ruter();
    await tester.pumpWidget(_app(cus, ruter));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('cus-ai-endre')));
    await tester.pump();
    expect(ruter.navn.last, contains('/bergen/kurv'));
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await _settle(tester);
    expect(cus.calls, contains('requote:q_sample:-:-'));
  });

  testWidgets('a live refusal opens its sheet, not a toast (spec §4.10 H)', (tester) async {
    _phone(tester);
    cus.request = aiSampleRequest();
    cus.confirmFeil = 'scope_missing';
    await tester.pumpWidget(_app(cus));
    await _settle(tester);
    final state = tester.state(find.byType(AiKurvScreen)) as dynamic;
    state.betalNaa(payment: 'vipps');
    await _settle(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const Key('cus-ai-feil-ikkeKoblet')), findsOneWidget);
  });
}
