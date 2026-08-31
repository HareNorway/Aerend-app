import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aerend_customer/l10n/app_localizations.dart';
import 'package:aerend_customer/screens/feed/components/feed_comment_input_panel.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(bottomNavigationBar: child),
  );
}

void main() {
  testWidgets('initial state: send disabled, no counter', (tester) async {
    await tester.pumpWidget(
      _wrap(FeedCommentInputPanel(onSubmit: (_) {})),
    );
    final send = tester.widget<IconButton>(
      find.byKey(const Key('feed_comment_send_btn')),
    );
    expect(send.onPressed, isNull);
    expect(find.textContaining('/ 2000'), findsNothing);
  });

  testWidgets('type text: send enables, counter hidden', (tester) async {
    await tester.pumpWidget(
      _wrap(FeedCommentInputPanel(onSubmit: (_) {})),
    );
    await tester.enterText(find.byKey(const Key('feed_comment_input')), 'Hi');
    await tester.pump();
    final send = tester.widget<IconButton>(
      find.byKey(const Key('feed_comment_send_btn')),
    );
    expect(send.onPressed, isNotNull);
    expect(find.textContaining('/ 2000'), findsNothing);
  });

  testWidgets('type >1500 chars: counter visible', (tester) async {
    await tester.pumpWidget(
      _wrap(FeedCommentInputPanel(onSubmit: (_) {})),
    );
    await tester.enterText(
      find.byKey(const Key('feed_comment_input')),
      'x' * 1501,
    );
    await tester.pump();
    expect(find.textContaining('/ 2000'), findsOneWidget);
  });

  testWidgets('send tapped: onSubmit fires with trimmed text', (tester) async {
    String? submitted;
    await tester.pumpWidget(
      _wrap(FeedCommentInputPanel(onSubmit: (t) => submitted = t)),
    );
    await tester.enterText(find.byKey(const Key('feed_comment_input')), '  hello  ');
    await tester.pump();
    await tester.tap(find.byKey(const Key('feed_comment_send_btn')));
    expect(submitted, 'hello');
  });

  testWidgets('sending=true: field disabled, spinner on send', (tester) async {
    await tester.pumpWidget(
      _wrap(
        FeedCommentInputPanel(
          sending: true,
          onSubmit: (_) {},
        ),
      ),
    );
    final field = tester.widget<TextField>(find.byKey(const Key('feed_comment_input')));
    expect(field.enabled, isFalse);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
