import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/feed/feed_post.dart';
import 'package:aerend_customer/data/feed/feed_tab_item.dart';
import 'package:aerend_customer/data/ops/tracking_models.dart';
import 'package:aerend_customer/screens/bergen/kasse/kasse_copy.dart';
import 'package:aerend_customer/screens/bergen/sporing/leveringskode_card.dart';
import 'package:aerend_customer/screens/bergen/sporing/sporing_copy.dart';
import 'package:aerend_customer/screens/bergen/utforsk/feed_post_card.dart';
import 'package:aerend_customer/services/customer/client_flags.dart';

import '../a3/a3_fakes.dart';

/// Customer plan Step 11 in the app: the feed's disclosure line on an
/// agent-written post (only with `cus.feed.disclosure` on), the partner
/// pill «Leveres av {butikk}», the partner guide lines, the checkout's
/// return-to-store line, and the flags the app renders on.

const _media = {'cloudinary_public_id': 'aerend/feed/demo/x', 'cloudinary_version': '1', 'format': 'jpg', 'width': 1200, 'height': 1500, 'resource_type': 'image'};

FeedTabItem _item({bool agent = true}) => FeedTabItem.fromJson({
  'id': '65', 'publisher': {'type': 'aerend', 'name': 'Ærend', 'logo_url': null}, 'store': null, 'post_type': 'nytt_i_hyllene', 'headline': 'Nytt i hyllene på Nordnes',
  'caption': 'Tre butikker på Nordnes har fått nye varer.', 'media': _media, 'like_count': 0, 'comment_count': 0, 'is_liked': false, 'published_at': '2026-10-22T18:00:00Z',
  'origin': agent ? 'agent' : 'person', 'disclosure': agent,
});

void main() {
  setUpAll(() async {
    await a3Bootstrap();
  });

  test('models: disclosure from `disclosure` or `origin = agent`; the flags', () {
    expect(_item().disclosure, isTrue);
    expect(_item(agent: false).disclosure, isFalse);
    expect(FeedTabItem.fromJson({'id': '1', 'publisher': {'type': 'aerend', 'name': 'Ærend'}, 'post_type': 'drift', 'caption': 'x', 'media': _media, 'origin': 'agent'}).disclosure, isTrue);
    final p = FeedPost.fromJson({'id': '65', 'caption': 'x', 'media': _media, 'disclosure': true});
    expect(p.disclosure, isTrue);
    ClientFlags.flags = {ClientFlags.feedDisclosure: true};
    expect(ClientFlags.on(ClientFlags.feedDisclosure), isTrue);
    expect(ClientFlags.on('cus.unknown'), isFalse);
    ClientFlags.flags = {};
    expect(ClientFlags.on(ClientFlags.feedDisclosure), isFalse);
  });

  testWidgets('the feed card says «Skrevet automatisk av Ærend» on an agent-written post, only with the flag on', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    Widget host(FeedTabItem item) => MaterialApp(home: Scaffold(body: SizedBox(height: 700, child: FeedPostCard(item: item))));
    ClientFlags.flags = {ClientFlags.feedDisclosure: true};
    await tester.pumpWidget(host(_item()));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('cus-feed-disclosure')), findsOneWidget);
    expect(find.text('Skrevet automatisk av Ærend'), findsOneWidget);
    await tester.pumpWidget(host(_item(agent: false)));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('cus-feed-disclosure')), findsNothing);
    ClientFlags.flags = {};
    await tester.pumpWidget(host(_item()));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('cus-feed-disclosure')), findsNothing);
  });

  testWidgets('a partner-delivered order: «Leveres av Torgboden», no courier identity, the store\'s copy', (tester) async {
    final t = OpsTracking.fromJson(const {
      'order_id': '401', 'code': 'Æ-2BC', 'state': 'picked_up', 'stage': 2, 'stage_label': 'På vei', 'delivery_actor': 'partner', 'delivered_by_label': 'Torgboden',
      'store': {'id': 43, 'name': 'Torgboden'}, 'courier': null, 'live_position': null, 'promised_start': '2026-10-22T20:23:00Z', 'promised_end': '2026-10-22T20:28:00Z',
    });
    expect(t.isPartner, isTrue);
    expect(t.courier, isNull);
    expect(t.livePosition, isNull);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: BudIdentitetPill(tracking: t)))));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(SporingCopy.a1_sporing_leveres_av('Torgboden')), findsOneWidget);
    expect(find.textContaining('leverer selv'), findsNothing);
    final lines = SporingCopy.lines(false, partner: true, store: 'Torgboden', vindu: '22:23–22:28');
    expect(lines[2], contains('Torgboden er på vei'));
    expect(lines[2], contains('22:23–22:28'));
    expect(lines[3], contains('Levert av Torgboden'));
    expect(lines.join(' '), isNot(contains('sykler')));
  });

  test('the checkout states the return-to-store consequence with the code on', () {
    expect(KasseCopy.cus_kasse_kode_retur, contains('tilbake til butikken'));
    expect(KasseCopy.cus_kasse_kode_retur, contains('aldri ved døren'));
    expect(SporingCopy.cus_sporing_butikken_regner, 'Butikkens tid');
  });
}
