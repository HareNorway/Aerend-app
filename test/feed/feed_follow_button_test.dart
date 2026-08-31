import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aerend_customer/l10n/app_localizations.dart';
import 'package:aerend_customer/screens/feed/components/feed_follow_button.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('shows Follow when isFollowing=false', (tester) async {
    await tester.pumpWidget(
      _wrap(FeedFollowButton(isFollowing: false, onTap: () {})),
    );
    expect(find.text('Follow'), findsOneWidget);
  });

  testWidgets('shows Following when isFollowing=true', (tester) async {
    await tester.pumpWidget(
      _wrap(FeedFollowButton(isFollowing: true, onTap: () {})),
    );
    expect(find.text('Following'), findsOneWidget);
  });

  testWidgets('tap fires onTap callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(FeedFollowButton(isFollowing: false, onTap: () => tapped = true)),
    );
    await tester.tap(find.text('Follow'));
    expect(tapped, isTrue);
  });

  testWidgets('disabled when isInFlight=true', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        FeedFollowButton(
          isFollowing: false,
          isInFlight: true,
          onTap: () => tapped = true,
        ),
      ),
    );
    await tester.tap(find.byType(FilledButton));
    expect(tapped, isFalse);
  });
}
