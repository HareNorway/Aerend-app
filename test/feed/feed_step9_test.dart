import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aerend_customer/networking/feed/feed_api_helper.dart';
import 'package:aerend_customer/networking/feed/feed_attribution.dart';
import 'package:aerend_customer/networking/feed/feed_repo.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/feed/components/feed_post_kebab_sheet.dart';
import 'package:aerend_customer/utils/shared_pref_utill.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../layout/reduced_motion_harness.dart';

/// Answers every feed call from a table and remembers what was asked.
class _FakeFeed implements HttpClientAdapter {
  _FakeFeed(this.answers);

  final Map<String, Object> answers;
  final List<RequestOptions> asked = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    asked.add(options);
    final key = '${options.method} ${options.path}';
    final body = answers[key] ?? {'error': {'code': 'not_found', 'message': key}};
    return ResponseBody.fromString(
      jsonEncode(body),
      answers.containsKey(key) ? 200 : 404,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

FeedRepo _repo(_FakeFeed fake) {
  final dio = Dio()..httpClientAdapter = fake;
  return FeedRepo(helper: FeedApiHelper.withDio(dio));
}

/// Backend plan Step 9 — the app's half of the feed backend: the server's
/// unread count, the pinned drift notice, reports, «Ærend» follow, and the
/// post an order came from.
void main() {
  setUp(() => bootstrapGlobals(locale: 'no'));

  group('FeedAttribution', () {
    test('remembers the post per store for a day, and forgets it after the order', () {
      final now = DateTime(2026, 10, 8, 12);
      FeedAttribution.remember(storeId: 41, postId: '77', now: now);
      FeedAttribution.remember(storeId: 42, postId: '78', now: now);

      expect(FeedAttribution.forStore(41, now: now.add(const Duration(hours: 3))), '77');
      expect(FeedAttribution.forStore(41, now: now.add(const Duration(hours: 25))), isNull);
      expect(FeedAttribution.forStore(43, now: now), isNull);

      FeedAttribution.remember(storeId: 41, postId: '80', now: now);
      expect(FeedAttribution.forStore(41, now: now), '80', reason: 'the latest post wins');

      FeedAttribution.clear(41);
      expect(FeedAttribution.forStore(41, now: now), isNull);
      expect(FeedAttribution.forStore(42, now: now), '78');
    });

    test('no store or no post is not remembered', () {
      FeedAttribution.remember(storeId: 0, postId: '77');
      FeedAttribution.remember(storeId: 41, postId: '');
      expect(FeedAttribution.forStore(0), isNull);
      expect(FeedAttribution.forStore(41), isNull);
    });
  });

  group('FeedRepo (Step 9 calls)', () {
    test('unread and seen go to the server, with the address when there is one', () async {
      final fake = _FakeFeed({
        'GET feed/unread': {'tab': 'naerheten', 'unread': 99, 'capped': true, 'seen_at': null},
        'POST feed/seen': {'tab': 'naerheten', 'unread': 0},
      });
      final repo = _repo(fake);

      expect(feedAddressLatLng(), isNull, reason: 'no address picked: no filter');
      prefSetString(prefSelectedLatLng, '60.3913,5.3221');
      final at = feedAddressLatLng();

      final r = await repo.fetchUnread(lat: at?.lat, lng: at?.lng);
      await repo.markSeen();

      expect(r.unread, 99);
      expect(r.capped, isTrue);
      expect(fake.asked.first.queryParameters, {'tab': 'naerheten', 'lat': 60.3913, 'lng': 5.3221});
      expect(fake.asked.last.data, {'tab': 'naerheten'});
    });

    test('a report says whether it was the first', () async {
      final fake = _FakeFeed({
        'POST posts/77/report': {'post_id': '77', 'reported': true, 'already_reported': true},
      });

      expect(await _repo(fake).reportPost('77', reason: 'wrong_price', note: '  '), isFalse);
      expect(fake.asked.single.data, {'reason': 'wrong_price'}, reason: 'a blank note is left out');
    });

    test('following «Ærend» is a PUT on and a DELETE off', () async {
      final fake = _FakeFeed({
        'PUT me/aerend-follow': {'following': true},
        'DELETE me/aerend-follow': {'following': false},
        'GET me/aerend-follow': {'following': true},
      });
      final repo = _repo(fake);

      expect(await repo.setAerendFollow(true), isTrue);
      expect(await repo.setAerendFollow(false), isFalse);
      expect(await repo.fetchAerendFollow(), isTrue);
      expect(fake.asked.map((o) => o.method), ['PUT', 'DELETE', 'GET']);
    });

    test('the notice is null when nothing is pinned', () async {
      expect(await _repo(_FakeFeed({'GET feed/notice': {'notice': null}})).fetchNotice(), isNull);
    });
  });

  test('Utforsk drift notice no longer returns null every time (it asks the feed)', () async {
    // Without a store it is the feed's notice; the feed does not answer in a
    // test, so null — but through the feed call, not a hard-coded return.
    expect(await OpsCustomerApi().driftNotice(), isNull);
    final src = await File('lib/networking/ops/ops_customer_api.dart').readAsString();
    expect(src.contains('if (storeId == null) return _feedDriftNotice();'), isTrue);
  });

  testWidgets('«Rapporter» asks why, then reports', (tester) async {
    final fake = _FakeFeed({
      'POST posts/77/report': {'post_id': '77', 'reported': true, 'already_reported': false},
    });
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => reportFeedPost(context, '77', repo: _repo(fake)),
            child: const Text('rapporter'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('rapporter'));
    await tester.pumpAndSettle();
    expect(find.text('Hvorfor rapporterer du innlegget?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('feed-report-misleading')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(fake.asked.single.data, {'reason': 'misleading'});
    expect(find.text('Takk! Vi ser på innlegget.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}
