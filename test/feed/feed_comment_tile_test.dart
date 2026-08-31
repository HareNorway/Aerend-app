import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aerend_customer/data/feed/feed_comment.dart';
import 'package:aerend_customer/screens/feed/components/feed_comment_tile.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(child: child),
    ),
  );
}

FeedComment _comment({String? avatarUrl}) {
  return FeedComment(
    id: 'c1',
    postId: 'p1',
    user: FeedCommentUser(
      id: 'u1',
      name: 'Jane Doe',
      avatarUrl: avatarUrl,
    ),
    body: 'Nice post!',
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
  );
}

void main() {
  testWidgets('renders user name + body + relative time', (tester) async {
    await tester.pumpWidget(_wrap(FeedCommentTile(comment: _comment())));
    final bodyRich = find.byWidgetPredicate(
      (w) =>
          w is RichText && w.text.toPlainText().contains('Nice post!'),
    );
    expect(bodyRich, findsOneWidget);
    expect(
      tester.widget<RichText>(bodyRich).text.toPlainText(),
      contains('Jane Doe'),
    );
  });

  testWidgets('renders avatar placeholder when avatarUrl null', (tester) async {
    await tester.pumpWidget(_wrap(FeedCommentTile(comment: _comment())));
    expect(find.text('J'), findsOneWidget);
  });

  testWidgets('long-press triggers onLongPress callback', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      _wrap(
        FeedCommentTile(
          comment: _comment(),
          onLongPress: () => pressed = true,
        ),
      ),
    );
    await tester.longPress(find.byKey(const Key('feed_comment_tile_gesture')));
    expect(pressed, isTrue);
  });
}
