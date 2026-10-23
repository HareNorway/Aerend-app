// Customer Step 15 — Siri App Intents and Android shortcuts: every intent only
// opens the app at a Bergen route (Commerce spec §10, D-K19). The app side:
// the deep links resolve, Hurtig takes `mod` / `si` from the route (the
// OrderAgain confirmation step), `/bergen/siste-bestilling` finds the order to
// follow, and Siri's chip needs `cus.ai.intents`. The platform side: the Swift
// intents and `shortcuts.xml` carry the same four links and nothing that orders.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_copy.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_store.dart';
import 'package:aerend_customer/screens/bergen/ai/siste_bestilling_screen.dart';
import 'package:aerend_customer/screens/bergen/hurtig/hurtig_copy.dart';
import 'package:aerend_customer/screens/bergen/hurtig/hurtig_screen.dart';
import 'package:aerend_customer/screens/bergen/kit/bergen_routes.dart';
import 'package:aerend_customer/services/customer/client_flags.dart';
import 'package:aerend_customer/utils/utils.dart';

import '../a3/a3_fakes.dart';
import 'hurtig_test.dart' as hb;

class _Cus extends OpsCustomerApi {
  _Cus(this.rows);
  final List<Map<String, dynamic>> rows;
  @override
  Future<List<Map<String, dynamic>>> orders({int limit = 50}) async => rows;
}

class _Spor extends NavigatorObserver {
  final List<String> names = [];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => names.add(route.settings.name ?? '?');
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => names.add('replace:${newRoute?.settings.name ?? '?'}');
}

void _phone(WidgetTester t) {
  t.view.physicalSize = const Size(390, 2600);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

/// Hurtig on the route with [args]; the half text scale is the Hurtig tests'
/// (the header row overflows at the test font otherwise).
Widget _hurtig(Map<String, String> args) => MaterialApp(
  builder: (context, app) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true, textScaler: const TextScaler.linear(.5)), child: app!),
  onGenerateRoute: (s) => MaterialPageRoute(settings: RouteSettings(name: '/bergen/hurtig', arguments: args), builder: (_) => HurtigScreen(data: hb.kData, now: hb.kNow)),
  initialRoute: '/bergen/hurtig',
);

const _links = ['aerendapp://bergen/hurtig?mod=forrige', 'aerendapp://bergen/siste-bestilling', 'aerendapp://bergen/sok?naer=1', 'aerendapp://bergen/kurv'];

void main() {
  setUpAll(() async {
    await a3Bootstrap(prefs: {prefUserId: 656, prefAccessToken: 'tok', prefUserName: 'Kari Nordmann', prefUserVerified: 1});
    OpsCustomerApi.networkEnabled = false;
  });
  tearDownAll(() => OpsCustomerApi.networkEnabled = true);

  test('the four deep links resolve to Bergen routes and keep their arguments', () {
    for (final l in _links) {
      final u = Uri.parse(l);
      final name = '/bergen${u.path}${u.hasQuery ? '?${u.query}' : ''}';
      expect(BergenRoutes.resolve(name), isNotNull, reason: name);
    }
    expect(BergenRoutes.resolve('/bergen/siste-bestilling'), '/bergen/siste-bestilling');
    expect(BergenRoutes.arguments('/bergen/hurtig?mod=forrige', null)['mod'], 'forrige');
    expect(BergenRoutes.arguments('/bergen/hurtig?si=Bestill%20fiskesuppe', null)['si'], 'Bestill fiskesuppe');
    expect(BergenRoutes.arguments('/bergen/sok?naer=1', null)['naer'], '1');
  });

  testWidgets('Hurtig from the OrderAgain link presses «Bestilt forrige gang» — the draft, never an order', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_hurtig(BergenRoutes.arguments('/bergen/hurtig?mod=forrige', null)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text(HurtigCopy.spForrige), findsOneWidget);
    expect(find.byKey(const Key('a1_hurtig_felt')), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('Hurtig from a favourite link sends «Bestill …» as the line', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_hurtig(const {'si': 'Bestill fiskesuppe'}));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('Bestill fiskesuppe'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('siste-bestilling: the live order, else the newest not cancelled, else Ordrehistorikk with a line', (tester) async {
    final spor = _Spor();
    Widget host(SisteBestillingScreen s) => MaterialApp(navigatorObservers: [spor], onGenerateRoute: BergenRoutes.generate, home: s);
    // The live order wins.
    await tester.pumpWidget(host(SisteBestillingScreen(api: _Cus(const []), liveId: 458)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(spor.names.last, contains('/bergen/sporing/458'));
    await tester.pumpWidget(const SizedBox());
    spor.names.clear();
    // The newest order that was not cancelled.
    await tester.pumpWidget(host(SisteBestillingScreen(api: _Cus(const [
      {'order_id': '460', 'state': 'cancelled'},
      {'order_id': '459', 'state': 'delivered'},
    ]))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(spor.names.last, contains('/bergen/sporing/459'));
    await tester.pumpWidget(const SizedBox());
    spor.names.clear();
    // Nothing to follow.
    await tester.pumpWidget(host(SisteBestillingScreen(api: _Cus(const []))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(spor.names.last, contains('/bergen/meg/bestillinger'));
    expect(find.text(AiCopy.cus_ai_ingen_bestilling), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpWidget(const SizedBox());
  });

  test('Siri shows only with cus.ai.intents (the harness aside)', () {
    ClientFlags.flags = {};
    expect(AiStore.instance.navn, ['Claude', 'ChatGPT', 'Gemini']);
    ClientFlags.flags = {ClientFlags.aiIntents: true};
    expect(AiStore.instance.navn, ['Claude', 'ChatGPT', 'Gemini', 'Siri']);
    ClientFlags.flags = {};
  });

  test('the Swift intents and the Android shortcuts carry the same four links and nothing that orders', () {
    final dir = Directory('ios/Runner/AppIntents');
    final swift = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.swift')).map((f) => f.readAsStringSync()).join('\n');
    for (final name in ['OrderAgainIntent', 'TrackOrderIntent', 'FindStoresNearMeIntent', 'OpenCartIntent', 'AerendShortcuts']) {
      expect(swift, contains('struct $name'), reason: name);
    }
    expect(swift, contains('"aerendapp://bergen"'));
    for (final path in ['/hurtig?mod=forrige', '/siste-bestilling', '/sok?naer=1', '/kurv']) {
      expect(swift, contains('"$path"'), reason: path);
    }
    expect(swift, contains('Bestill det vanlige med \\(.applicationName)'));
    expect(swift, contains('openAppWhenRun: Bool = true'));
    // Only opening the app: no network, no order call.
    expect(swift.contains('URLSession'), isFalse);
    expect(swift.contains('confirm_order'), isFalse);
    expect(swift.contains('http'), isFalse);
    final xml = File('android/app/src/main/res/xml/shortcuts.xml').readAsStringSync();
    for (final l in _links) {
      expect(xml, contains('android:data="$l"'), reason: l);
    }
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:name="android.app.shortcuts" android:resource="@xml/shortcuts"'));
    expect(manifest, contains('android:scheme="aerendapp" android:host="bergen"'));
    final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    for (final f in ['AerendLink.swift', 'OrderAgainIntent.swift', 'TrackOrderIntent.swift', 'FindStoresNearMeIntent.swift', 'OpenCartIntent.swift', 'AerendShortcuts.swift']) {
      expect(pbx, contains('$f in Sources'), reason: f);
    }
  });
}
