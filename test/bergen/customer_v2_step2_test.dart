import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/networking/ops/cus_api.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_bits.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_copy.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_sheets.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_store.dart';
import 'package:aerend_customer/screens/bergen/hjem/hjem_harness.dart';
import 'package:aerend_customer/screens/bergen/hjem/hjem_kort.dart';
import 'package:aerend_customer/services/customer/client_flags.dart';
import 'package:aerend_customer/utils/utils.dart';

import '../a3/a3_fakes.dart';

/// Customer v2 Step 2 (spec §4.10 A, B, E): text marks instead of logos, the
/// privacy line and «Kopier kobling» / the QR on the entry, the consent text's
/// version, «Del Min bio» since, and the activity from its own route.
class _Cus extends CusApi {
  final List<String> calls = [];
  List<CusAiLink> links = [];

  @override
  Future<List<CusAiLink>?> aiLinks() async => links;
  @override
  Future<List<CusAiClient>> aiClients() async {
    lastConsentVersion = '2026-10-utkast';
    return const [CusAiClient(clientId: 'claude', name: 'Claude', vendor: 'claude'), CusAiClient(clientId: 'chatgpt', name: 'ChatGPT', vendor: 'chatgpt')];
  }

  @override
  Future<CusAiRequest?> aiRequestLatest() async => null;
  @override
  Future<({CusAiLink link, List<CusAiAktivitet> aktivitet})?> aiLink(int id) async {
    calls.add('link:$id');
    return (link: links.firstWhere((l) => l.id == id), aktivitet: const <CusAiAktivitet>[]);
  }

  @override
  Future<List<CusAiAktivitet>?> aiLinkActivity(int id, {int limit = 30}) async {
    calls.add('activity:$id');
    return [CusAiAktivitet(tool: 'search_products', outcome: 'ok', at: DateTime.now())];
  }

  @override
  Future<CusAiKode?> aiLinkCode({String? clientId, CusAiPrefs? prefs}) async {
    calls.add('code:$clientId');
    return const CusAiKode(code: 'ÆR-7K2Q', raw: '7K2Q', status: 'pending', linkUrl: 'https://aerend.no/koble/7k2q');
  }
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
    ClientFlags.flags = {ClientFlags.aiLinking: true};
  });
  late _Cus cus;
  setUp(() {
    cus = _Cus();
    AiStore.instance.reset();
    AiStore.instance.api = cus;
    HjemHarness.aiStart = null;
  });

  testWidgets('Claude and ChatGPT carry their logos, Gemini and Siri their letters (the onboarding design, 2026-11-01)', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Row(children: [const AiMerke('Claude'), const AiMerke('ChatGPT'), const AiMerke('Gemini'), const AiMerke('Siri'), HjemAiMerker(onTap: () {})]))));
    final logos = tester.widgetList<Image>(find.byType(Image)).map((i) => (i.image as AssetImage).assetName).toList()..sort();
    expect(logos, ['assets/images/ai/chatgpt.png', 'assets/images/ai/chatgpt.png', 'assets/images/ai/claude.png', 'assets/images/ai/claude.png']);
    expect(find.text('Cl'), findsNothing);
    expect(find.text('Ge'), findsOneWidget);
    expect(find.text('Si'), findsOneWidget);
  });

  testWidgets('the entry: the privacy line, «Kopier kobling» makes the code once, the QR opens inline', (tester) async {
    _phone(tester);
    await AiStore.instance.load(force: true);
    await tester.pumpWidget(_host((c) => AiArk.flyt(c, 'inngang')));
    await _open(tester);
    expect(find.byKey(const Key('cus-ai-personvern')), findsOneWidget);
    expect(find.text(AiCopy.assistants_privacy_line('Claude')), findsOneWidget);
    expect(find.byKey(const Key('cus-ai-annen-enhet')), findsOneWidget);
    String? kopi;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') kopi = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.ensureVisible(find.byKey(const Key('cus-ai-inngang-kopier')));
    await tester.tap(find.byKey(const Key('cus-ai-inngang-kopier')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(cus.calls, ['code:claude']);
    expect(kopi, 'https://aerend.no/koble/7k2q');

    expect(find.byKey(const Key('cus-ai-inngang-qr-kode')), findsNothing);
    await tester.tap(find.byKey(const Key('cus-ai-inngang-qr-vis')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('cus-ai-inngang-qr-kode')), findsOneWidget);
    expect(cus.calls, ['code:claude'], reason: 'the code is made once per assistant');
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('the consent sheet names the consent text\'s version', (tester) async {
    _phone(tester);
    await AiStore.instance.load(force: true);
    await tester.pumpWidget(_host((c) => AiArk.flyt(c, 'samtykke')));
    await _open(tester);
    expect(find.byKey(const Key('cus-ai-samtykke')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_samtykke_versjon('2026-10-utkast')), findsOneWidget);
  });

  testWidgets('the detail: «Del Min bio» since, the version, and the activity from its own route', (tester) async {
    _phone(tester);
    cus.links = [
      CusAiLink.fromJson({'id': 3, 'client_id': 'claude', 'name': 'Claude', 'vendor': 'claude', 'active': true, 'scopes': ['catalog:read', 'cart:write', 'orders:write'], 'share_bio': true,
        'share_bio_consented_at': '2026-10-03T18:00:00+02:00', 'consent_version': '2026-10-utkast', 'granted_at': '2026-10-01T18:00:00+02:00'}),
    ];
    await AiStore.instance.load(force: true);
    await tester.pumpWidget(_host((c) => AiArk.flyt(c, 'detalj:3')));
    await _open(tester);
    await tester.pump(const Duration(milliseconds: 600));
    expect(cus.calls, containsAll(['link:3', 'activity:3']));
    expect(find.text(AiCopy.cus_ai_bio_delt_siden('3. oktober')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_samtykke_versjon('2026-10-utkast')), findsOneWidget);
    expect(find.text(AiCopy.cus_ai_akt('search_products')), findsOneWidget);
  });
}
