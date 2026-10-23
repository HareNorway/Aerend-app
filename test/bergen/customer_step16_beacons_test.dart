// Customer Step 16 — the client beacons and the per-version flags: events
// are technical (template + status, hashes), rate-limited, batched and sent
// signed only after login; 404 switches the module off; `agents/flags`
// overrides a surface flag, carries the banner and `min_version`; the shell
// banner renders per level and closes; the update prompt shows once.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/kit/server_banner.dart';
import 'package:aerend_customer/services/customer/beacons.dart';
import 'package:aerend_customer/services/customer/client_flags.dart';

import '../a3/a3_fakes.dart';

class _Transport implements CusBeaconTransport {
  final List<Map<String, Object?>> sent = [];
  final List<String> versions = [];
  int status = 202;
  CusClientFlags? answer;
  @override
  Future<int> send(Map<String, Object?> batch, {required String version}) async {
    sent.add(batch);
    versions.add(version);
    return status;
  }

  @override
  Future<CusClientFlags?> flags({required String version}) async => answer;
}

DioException _dio(String url, {int? status, DioExceptionType type = DioExceptionType.badResponse}) {
  final o = RequestOptions(path: url);
  return DioException(requestOptions: o, type: type, response: status == null ? null : Response(requestOptions: o, statusCode: status));
}

void main() {
  setUpAll(() async => a3Bootstrap());
  tearDown(() {
    CusBeacons.current = null;
    ClientFlags.resetAgents();
    ClientFlags.flags = {};
    CusOppdaterArk.reset();
    CusServerBanner.lukket = null;
  });

  test('the endpoint template drops host, query, ids and public keys', () {
    expect(CusBeacon.template('http://192.168.29.94:8000/api/ops/customer/orders/458/tracking?user_id=656&access_token=abc'), '/api/ops/customer/orders/{id}/tracking');
    expect(CusBeacon.template('http://x/api/customer/ai/requests/q_hq3e34tt6zw226mv4gprzyun/confirm'), '/api/customer/ai/requests/{key}/confirm');
    expect(CusBeacon.template('http://x/api/agent/chat'), '/api/agent/chat');
    expect(CusBeacon.agentOrCommerce('/api/agent/chat'), isTrue);
    expect(CusBeacon.agentOrCommerce('/api/catalog/home'), isFalse);
    expect(CusBeacon.hash('a'), CusBeacon.hash('a'));
    expect(CusBeacon.hash('a'), isNot(CusBeacon.hash('b')));
  });

  test('onDio: timeouts on agent / commerce endpoints, failures with status, the feed, never a 4xx answer', () {
    final t = _Transport();
    final b = CusBeacons(transport: t, version: '1.2.3+4', signer: () => (userId: 656, token: 'tok'));
    CusBeacons.current = b;
    CusBeacons.onDio(_dio('http://x:8000/api/agent/chat', type: DioExceptionType.receiveTimeout));
    CusBeacons.onDio(_dio('http://x:8000/api/catalog/home', status: 500));
    CusBeacons.onDio(_dio('http://x:8000/api/customer/ai/requests/q_abc', status: 422));
    CusBeacons.onDio(_dio('http://x:3300/feed/home', status: 503));
    CusBeacons.onDio(_dio('http://x:8000/api/catalog/home', type: DioExceptionType.cancel));
    expect(b.queued.map((e) => e.cls).toList(), ['timeout', 'api_failed', 'feed_degraded']);
    expect(b.queued[0].endpoint, '/api/agent/chat');
    expect(b.queued[1].status, 500);
    expect(b.queued[2].status, 503);
    final j = b.queued[1].toJson();
    expect(j['class'], 'api_failed');
    expect(j['stack_hash'], isNotEmpty);
    expect(j.containsKey('message'), isFalse);
  });

  test('uncaught errors carry the type and a stack hash, never the message', () {
    final t = _Transport();
    CusBeacons.current = CusBeacons(transport: t, version: '1.0.0');
    CusBeacons.uncaught(StateError('Kari Nordmann, Torggaten 9'), StackTrace.current);
    final e = CusBeacons.current!.queued.single;
    expect(e.cls, 'uncaught_error');
    expect(e.code, 'StateError');
    expect(e.toJson().toString().contains('Kari'), isFalse);
    expect((e.data['stack'] as String).length, 8);
  });

  test('rate limits per class and in total; the queue caps and counts drops', () {
    var now = DateTime(2026, 10, 23, 12);
    final b = CusBeacons(transport: _Transport(), version: '1.0.0', clock: () => now, perClassPerMinute: 3, perMinute: 5, maxQueue: 4);
    for (var i = 0; i < 5; i++) {
      b.report('api_failed', endpoint: '/a');
    }
    expect(b.queued.length, 3);
    expect(b.dropped, 2);
    b.report('timeout');
    b.report('timeout');
    b.report('timeout');
    expect(b.queued.length, 4, reason: 'total 5 a minute, queue capped at 4');
    expect(b.dropped, 4);
    now = now.add(const Duration(minutes: 2));
    b.report('api_failed', endpoint: '/b');
    expect(b.queued.last.endpoint, '/b');
  });

  test('flush sends a signed batch only after login, with app, version and the events; 404 switches off', () async {
    final t = _Transport();
    ({int userId, String token})? who;
    final b = CusBeacons(transport: t, version: '1.2.3+4', platform: 'ios', locale: 'no', signer: () => who);
    b.report('api_failed', endpoint: '/api/x', status: 500);
    await b.flush();
    expect(t.sent, isEmpty, reason: 'not logged in: nothing leaves the device');
    who = (userId: 656, token: 'tok');
    await b.flush();
    expect(t.sent.length, 1);
    final batch = t.sent.single;
    expect(batch['app'], 'customer');
    expect(batch['version'], '1.2.3+4');
    expect(batch['user_id'], 656);
    expect(batch['access_token'], 'tok');
    expect((batch['events'] as List).length, 1);
    expect(t.versions.single, '1.2.3+4');
    expect(b.queued, isEmpty);
    t.status = 404;
    b.report('timeout');
    await b.flush();
    expect(b.disabled, isTrue);
    b.report('timeout');
    expect(b.queued, isEmpty);
  });

  test('agents/flags: overrides win over the surface flags; banner and min_version parse; update when older', () async {
    ClientFlags.flags = {ClientFlags.aiLinking: true};
    final t = _Transport()
      ..answer = CusClientFlags.fromJson({
        'flags': {'cus.ai.linking': false, 'cus.ai.intents': true},
        'banner': {'no': 'Vi oppgraderer i natt.', 'en': 'We upgrade tonight.', 'level': 'warning'},
        'min_version': '1.4.0',
        'update_required': false,
      });
    final b = CusBeacons(transport: t, version: '1.3.9+12');
    await b.loadFlags();
    expect(ClientFlags.on(ClientFlags.aiLinking), isFalse);
    expect(ClientFlags.on(ClientFlags.aiIntents), isTrue);
    final f = ClientFlags.agents.value!;
    expect(f.banner('no'), 'Vi oppgraderer i natt.');
    expect(f.banner('en'), 'We upgrade tonight.');
    expect(f.bannerLevel, 'warning');
    expect(f.needsUpdate('1.3.9+12'), isTrue);
    expect(f.needsUpdate('1.4.0+1'), isFalse);
    expect(CusClientFlags.compareVersions('1.10.0', '1.9.9'), 1);
    ClientFlags.resetAgents();
    expect(ClientFlags.on(ClientFlags.aiLinking), isTrue);
  });

  testWidgets('the shell banner renders the server line per level and closes for this run', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CusServerBanner())));
    expect(find.byKey(const Key('cus-server-banner')), findsNothing);
    ClientFlags.applyAgents(const CusClientFlags(bannerNo: 'Lang kø hos budene i kveld.', bannerLevel: 'critical'));
    await tester.pump();
    expect(find.byKey(const Key('cus-server-banner')), findsOneWidget);
    expect(find.text('Lang kø hos budene i kveld.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cus-server-banner-lukk')));
    await tester.pump();
    expect(find.byKey(const Key('cus-server-banner')), findsNothing);
    ClientFlags.applyAgents(const CusClientFlags(bannerNo: 'Ny melding.', bannerLevel: 'info'));
    await tester.pump();
    expect(find.text('Ny melding.'), findsOneWidget, reason: 'a new text shows again');
  });

  testWidgets('the min_version prompt shows once, with «Åpne App Store»', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (c) { ctx = c; return const SizedBox(); }))));
    const f = CusClientFlags(minVersion: '2.0.0', updateRequired: true);
    CusOppdaterArk.visHvis(ctx, f, '1.0.0+1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const Key('cus-oppdater')), findsOneWidget);
    expect(find.byKey(const Key('cus-oppdater-cta')), findsOneWidget);
    expect(find.textContaining('2.0.0'), findsOneWidget);
    // A second call does nothing (once per run).
    CusOppdaterArk.visHvis(ctx, f, '1.0.0+1');
    await tester.pump();
    expect(find.byKey(const Key('cus-oppdater')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
