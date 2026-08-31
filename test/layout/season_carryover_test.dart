import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/l10n/app_localizations.dart';

/// The season card renders the carryover number as its own highlighted
/// TextSpan, so the surrounding sentence must not repeat it.
///
/// Regression: the Norwegian suffix was " {points} poeng inn i neste sesong.",
/// which produced "…tar du med deg **100** 100 poeng inn i neste sesong."
void main() {
  Future<AppLocalizations> load(Locale locale) =>
      AppLocalizations.delegate.load(locale);

  test('Norwegian carryover suffix carries no number', () async {
    final l = await load(const Locale('no'));
    const points = 250;

    final prefix = l.dugnadSeasonFinaleCarryoverBodyPrefix(84);
    final suffix = l.dugnadSeasonFinaleCarryoverBodySuffix(points);
    // The widget emits: prefix + '$points' + suffix
    final sentence = '$prefix$points$suffix';

    expect('250'.allMatches(sentence).length, 1,
        reason: 'sentence was: $sentence');
    expect(suffix, isNot(contains('250')));
    expect(suffix.startsWith(' '), isTrue,
        reason: 'suffix must keep its leading space: ${suffix.substring(0, 3)}');
  });

  test('English keeps its plural word but not the number', () async {
    final l = await load(const Locale('en'));
    final suffix = l.dugnadSeasonFinaleCarryoverBodySuffix(250);
    expect(suffix, isNot(contains('250')));
    expect(suffix, contains('points'));
  });

  testWidgets('rendered sentence shows the number exactly once',
      (tester) async {
    final l = await load(const Locale('no'));
    const points = 250;
    final text = '${l.dugnadSeasonFinaleCarryoverBodyPrefix(84)}'
        '$points'
        '${l.dugnadSeasonFinaleCarryoverBodySuffix(points)}';

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Text(text))),
    );

    expect(find.textContaining('250 250'), findsNothing);
    expect(find.textContaining('250 poeng'), findsOneWidget);
  });
}
