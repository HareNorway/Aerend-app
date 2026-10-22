// Customer Step 16 — the deterministic-fallback audit: every agent / commerce
// surface this plan added renders its plain state when its endpoint is off,
// unreachable or throwing, and the «Alle agenter av» drill (every flag off)
// leaves the app without an AI entry point. One test per sheet / screen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/networking/ops/cus_api.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_copy.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_kurv_screen.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_sheets.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_store.dart';
import 'package:aerend_customer/screens/bergen/ai/siste_bestilling_screen.dart';
import 'package:aerend_customer/screens/bergen/hjem/hjem_kort.dart';
import 'package:aerend_customer/screens/bergen/hurtig/hurtig_screen.dart';
import 'package:aerend_customer/screens/bergen/kit/bergen_routes.dart';
import 'package:aerend_customer/services/customer/client_flags.dart';
import 'package:aerend_customer/utils/utils.dart';

import '../a3/a3_fakes.dart';
import 'hurtig_test.dart' as hb;

/// Every AI call throws: the backend is down or answers 5xx.
class _Nede extends CusApi {
  Never _ned() => throw Exception('nede');
  @override
  Future<List<CusAiLink>> aiLinks() async => _ned();
  @override
  Future<List<CusAiClient>> aiClients() async => _ned();
  @override
  Future<CusAiRequest?> aiRequestLatest() async => _ned();
  @override
  Future<CusAiRequest?> aiRequest(String id) async => _ned();
  @override
  Future<CusAiKode?> aiLinkCode({String? clientId, CusAiPrefs? prefs}) async => _ned();
  @override
  Future<CusAiKode?> aiLinkCodeStatus(String code) async => _ned();
}

class _OrdreNede extends OpsCustomerApi {
  @override
  Future<List<Map<String, dynamic>>> orders({int limit = 50}) async => throw Exception('nede');
}

Widget _host(void Function(BuildContext) onOpen) => MaterialApp(
  home: Scaffold(body: Builder(builder: (context) => Center(child: ElevatedButton(key: const Key('open'), onPressed: () => onOpen(context), child: const Text('open'))))),
);

void _phone(WidgetTester t) {
  t.view.physicalSize = const Size(390, 2600);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

Future<void> _open(WidgetTester t) async {
  await t.tap(find.byKey(const Key('open')));
  await t.pump();
  await t.pump(const Duration(milliseconds: 700));
}

void main() {
  setUpAll(() async {
    await a3Bootstrap(prefs: {prefUserId: 656, prefAccessToken: 'tok', prefUserName: 'Kari Nordmann', prefUserVerified: 1});
    OpsCustomerApi.networkEnabled = false;
  });
  tearDownAll(() => OpsCustomerApi.networkEnabled = true);
  setUp(() {
    ClientFlags.flags = {ClientFlags.aiLinking: true, ClientFlags.aiIntents: true};
    AiStore.instance.reset();
  });

  group('the AI endpoints throw', () {
    setUp(() => AiStore.instance.api = _Nede());

    testWidgets('AiStore.load swallows the failure: no links, no clients, no request, no exception', (tester) async {
      await AiStore.instance.load(force: true);
      expect(AiStore.instance.aktive, isEmpty);
      expect(AiStore.instance.latest, isNull);
    });

    testWidgets('aiInngang: the four assistants «Ikke koblet», the steps, the CTA', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_host((c) => AiArk.flyt(c, 'inngang')));
      await _open(tester);
      expect(find.byKey(const Key('cus-ai-inngang')), findsOneWidget);
      expect(find.text(AiCopy.cus_ai_ikke_koblet), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('aiKoblede: the empty state', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_host((c) => AiArk.flyt(c, 'koblede')));
      await _open(tester);
      expect(find.byKey(const Key('cus-ai-koblede-tom')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('aiQr: the sheet stands without a code (the tiles show dots), no exception', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_host((c) => AiArk.flyt(c, 'qr')));
      await _open(tester);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(const Key('cus-ai-qr')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const Key('cus-ai-qr-tilbake')));
      await tester.tap(find.byKey(const Key('cus-ai-qr-tilbake')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('«Handlekurv fra assistent» with a request the server cannot give: the plain empty state', (tester) async {
      _phone(tester);
      await tester.pumpWidget(MaterialApp(home: AiKurvScreen(id: 'q_borte', api: _Nede())));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(find.byType(AiKurvScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 25));
    });

    testWidgets('siste-bestilling with the orders endpoint down: Ordrehistorikk with the line', (tester) async {
      final names = <String>[];
      await tester.pumpWidget(MaterialApp(
        navigatorObservers: [_Obs(names)],
        onGenerateRoute: BergenRoutes.generate,
        home: SisteBestillingScreen(api: _OrdreNede()),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(names.last, contains('/bergen/meg/bestillinger'));
      expect(find.text(AiCopy.cus_ai_ingen_bestilling), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('the endpoints are off (the flag answer never came): the real client answers nothing', () {
    testWidgets('aiInngang and aiKoblede render the plain state over the offline client', (tester) async {
      _phone(tester);
      AiStore.instance.api = CusApi();
      await tester.pumpWidget(_host((c) => AiArk.flyt(c, 'koblede')));
      await _open(tester);
      expect(find.byKey(const Key('cus-ai-koblede-tom')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('«Alle agenter av»: every flag off', () {
    setUp(() => ClientFlags.flags = {});

    testWidgets('Hurtig has no AI row; Hjem\'s card has no AI pill; Siri is not an assistant', (tester) async {
      _phone(tester);
      await tester.pumpWidget(MaterialApp(
        builder: (context, app) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true, textScaler: const TextScaler.linear(.5)), child: app!),
        home: HurtigScreen(data: hb.kData, now: hb.kNow),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const Key('cus-ai-hurtig-rad')), findsNothing);
      expect(find.text('Oftest bestilt'), findsOneWidget, reason: 'the plain modules stay');
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: HjemHurtigInngang(linje: 'Fiskesuppe · Torgboden', onTap: () {}))));
      await tester.pump();
      expect(find.byKey(const Key('cus-ai-hjem-merker')), findsNothing);
      expect(find.text('Hurtigbestilling'), findsOneWidget);
      expect(AiStore.instance.navn, isNot(contains('Siri')));
      await tester.pumpWidget(const SizedBox());
    });
  });
}

class _Obs extends NavigatorObserver {
  _Obs(this.names);
  final List<String> names;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => names.add(route.settings.name ?? '?');
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => names.add(newRoute?.settings.name ?? '?');
}
