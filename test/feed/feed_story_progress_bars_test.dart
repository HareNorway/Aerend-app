import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aerend_customer/screens/feed/components/feed_story_progress_bars.dart';

void main() {
  testWidgets('renders one segment per story', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FeedStoryProgressBars(
            storyCount: 3,
            currentIndex: 1,
            currentProgress: 0.5,
          ),
        ),
      ),
    );
    expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
  });

  testWidgets('current segment reflects partial progress', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FeedStoryProgressBars(
            storyCount: 2,
            currentIndex: 0,
            currentProgress: 0.25,
          ),
        ),
      ),
    );
    final bars = tester.widgetList<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bars.first.value, 0.25);
    expect(bars.last.value, 0);
  });
}
