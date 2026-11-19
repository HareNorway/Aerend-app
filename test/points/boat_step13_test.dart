import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aerend_customer/data/points/velger_api.dart';
import 'package:aerend_customer/screens/bergen/hjem/hjem_baat.dart';
import 'package:aerend_customer/screens/bergen/meg/meg_copy_a4.dart';

class _FakeBoat extends VelgerApi {
  _FakeBoat(this.shown);
  final bool shown;

  @override
  Future<({String? name, String? state, bool shown})?> boat() async => (name: 'Fjordulv', state: 'approved', shown: shown);
}

/// Points plan Step 13 (points spec §6.2 baat): the boat on Hjem only when approved and Platina; Meg's row texts.
void main() {
  testWidgets('the boat shows its name when the server says shown', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: HjemBaat(api: _FakeBoat(true)))));
    await tester.pumpAndSettle();
    expect(find.text('Fjordulv'), findsOneWidget);
  });

  test('Meg row texts follow the review state', () {
    expect(A4MegCopy.a4_meg_baat_rad(null), 'Båten din i Vågen');
    expect(A4MegCopy.a4_meg_baat_under('pending', false), 'Navnet venter på godkjenning');
    expect(A4MegCopy.a4_meg_baat_under('approved', true), 'Ligger i Vågen på Hjem');
    expect(A4MegCopy.a4_meg_baat_under('approved', false), 'Vises på Hjem når du er Platina');
  });
}
