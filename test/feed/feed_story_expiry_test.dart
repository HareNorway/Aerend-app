import 'package:aerend_customer/screens/feed/storyViewer/story_unavailable_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Handover T3: a story whose media has expired mid-view.
///
/// The view is tested directly rather than by driving `StoryViewerScreen` with
/// a broken URL. `CachedNetworkImage`'s cache manager needs `path_provider`,
/// which has no implementation in the widget-test binding, so its future never
/// completes and its error widget is never reached — a viewer-level test would
/// sit on the placeholder forever and pass for the wrong reason. What is worth
/// pinning is what replaces the broken-image icon, and that is this widget.
void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('it names the story as ended, and says whose it was', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        StoryUnavailableView(
          storeName: 'Sky Bangkok',
          message: 'This story is no longer available',
          onExpired: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('story_unavailable')), findsOneWidget);
    expect(find.text('This story is no longer available'), findsOneWidget);
    // Whose story ended, so the viewer is not left guessing which one they lost.
    expect(find.text('Sky Bangkok'), findsOneWidget);

    // And nothing that reads as "the app is broken".
    expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
  });

  testWidgets('it reports the expiry exactly once, not once per repaint', (
    WidgetTester tester,
  ) async {
    int calls = 0;

    await tester.pumpWidget(
      wrap(
        StoryUnavailableView(
          storeName: 'Sky Bangkok',
          message: 'gone',
          onExpired: () => calls++,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 3));

    // Reported from initState, not build: build runs again on every repaint,
    // and each extra report would restart the two-second skip timer and leave
    // the viewer stuck on this screen.
    expect(calls, 1);
  });

  testWidgets('a rebuild with new content does not re-report', (
    WidgetTester tester,
  ) async {
    int calls = 0;

    Widget view(String name) => wrap(
          StoryUnavailableView(
            storeName: name,
            message: 'gone',
            onExpired: () => calls++,
          ),
        );

    await tester.pumpWidget(view('Sky Bangkok'));
    await tester.pump();
    await tester.pumpWidget(view('Torgboden'));
    await tester.pump();

    expect(find.text('Torgboden'), findsOneWidget);
    expect(calls, 1);
  });
}
