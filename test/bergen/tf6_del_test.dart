import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/feed/feed_tab_item.dart';
import 'package:aerend_customer/screens/bergen/kit/del_trygt.dart';
import 'package:aerend_customer/screens/bergen/utforsk/feed_post_card.dart';
import 'package:aerend_customer/screens/bergen/utforsk/utforsk_copy.dart';

import '../a3/a3_fakes.dart';

/// TestFlight 6 feedback: «Share button is not working on the posts». iOS 26 shows the share sheet as a popover on the
/// iPhone and share_plus refuses an anchor that is not inside the screen; the feed anchored it on the whole tab.

const _media = {'cloudinary_public_id': 'aerend/feed/demo/x', 'cloudinary_version': '1', 'format': 'jpg', 'width': 1200, 'height': 1500, 'resource_type': 'image'};

FeedTabItem _item() => FeedTabItem.fromJson({
  'id': '77', 'publisher': {'type': 'store', 'name': 'Torgboden', 'logo_url': null}, 'store': null, 'post_type': 'nytt_i_hyllene', 'headline': 'Fiskekaker 4 stk til kvelds',
  'caption': 'Håndformet av hyse og sei.', 'media': _media, 'like_count': 0, 'comment_count': 0, 'is_liked': false, 'published_at': '2026-11-24T18:00:00Z',
});

const _share = MethodChannel('dev.fluttercommunity.plus/share');

void main() {
  setUpAll(() async {
    await a3Bootstrap();
  });

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  test('the share text reads «{title} hos {store}» (gen-l10n orders the parameters store, title)', () {
    expect(UtforskCopy.a1_feed_share_text('Fiskekaker 4 stk til kvelds', 'Torgboden'), 'Fiskekaker 4 stk til kvelds hos Torgboden — på Ærend');
  });

  testWidgets('the feed card\'s share key hands its own context: a 34 pt anchor inside the screen', (tester) async {
    phone(tester);
    BuildContext? anker;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SizedBox(height: 760, child: FeedPostCard(item: _item(), onShare: (a) => anker = a)))));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byKey(const Key('a1_feed_share_77')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(anker, isNotNull);
    final r = delAnker(anker!);
    expect(r.size, const Size(34, 34));
    expect((Offset.zero & const Size(402, 874)).contains(r.center), isTrue, reason: '$r');
  });

  testWidgets('an anchor taller than the screen (the whole feed tab) is kept inside it; an off-screen one falls back', (tester) async {
    phone(tester);
    final hoyK = GlobalKey(), utenforK = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(children: [SizedBox(key: hoyK, height: 3000), SizedBox(key: utenforK, height: 40)]),
        ),
      ),
    ));
    final hoy = hoyK.currentContext!, utenfor = utenforK.currentContext!;
    final skjerm = Offset.zero & const Size(402, 874);
    final r = delAnker(hoy);
    expect(r.top, greaterThanOrEqualTo(0));
    expect(r.bottom, lessThanOrEqualTo(874), reason: 'the whole-tab anchor $r must sit inside the screen');
    final f = delAnker(utenfor);
    expect(skjerm.contains(f.topLeft) && skjerm.contains(f.bottomRight - const Offset(.01, .01)), isTrue, reason: 'fallback $f');
  });

  testWidgets('when the platform still refuses, the text is copied and «Kopiert» shows (never a dead tap)', (tester) async {
    phone(tester);
    String? kopi;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_share, (call) async => throw PlatformException(code: 'error', message: 'sharePositionOrigin'));
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') kopi = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_share, null);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });
    final ankerK = GlobalKey();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: SizedBox(key: ankerK, width: 34, height: 34)))));
    final anker = ankerK.currentContext!;
    late bool ok;
    await tester.runAsync(() async => ok = await delTrygt(anker, 'Fiskekaker hos Torgboden'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(ok, isFalse);
    expect(kopi, 'Fiskekaker hos Torgboden');
    expect(find.text('Kopiert'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });
}
