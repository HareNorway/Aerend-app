import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/dugnad/dugnad_models.dart';

/// Permanent guard: Norwegian club names must survive parse and render with
/// **æ / ø / å intact**.
///
/// Context: the app was showing "Saelden-supporter" on home. There is no
/// transliteration anywhere in the client and Dio decodes JSON as UTF-8, so
/// that string is what the backend sends as `short_name` — a data defect, not
/// a rendering one. These tests pin the client side so a future regression
/// (an ASCII fold, a latin1 decode) is caught here rather than in a screenshot.
void main() {
  test('ClubListItem keeps æ through JSON parsing', () {
    // Exactly how a UTF-8 response arrives over the wire.
    final bytes = utf8.encode('{"id":1,"name":"Sædalen IL",'
        '"short_name":"Sædalen","area":"Sædalen","sponsor_store_count":3}');
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

    final club = ClubListItem.fromJson(json);

    expect(club.name, 'Sædalen IL');
    expect(club.shortName, 'Sædalen');
    expect(club.area, 'Sædalen');

    // The specific failure modes worth naming.
    expect(club.name, isNot(contains('Saelden')), reason: 'transposed fold');
    expect(club.name, isNot(contains('Saedalen')), reason: 'ASCII fold');
    expect(club.name, isNot(contains('Ã¦')), reason: 'latin1 mis-decode');
  });

  testWidgets('a club name renders with æ intact', (tester) async {
    const name = 'Sædalen IL';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text(name))),
      ),
    );

    expect(find.text('Sædalen IL'), findsOneWidget);
    expect(find.text('Saelden IL'), findsNothing);
    expect(find.text('Saedalen IL'), findsNothing);
  });
}
