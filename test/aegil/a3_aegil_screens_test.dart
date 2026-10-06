import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/meg/a3_services.dart';
import 'package:aerend_customer/screens/bergen/aegil/aegil_entry.dart';
import 'package:aerend_customer/screens/bergen/aegil/brett_entry.dart';

import '../a3/a3_fakes.dart';

/// AGIL-3-PLAN Phase 7 — the Brett and the Hjem greeting. The Ægil screen
/// itself (Launch UI Step 11) is covered in `test/bergen/aegil_step11_test.dart`.
void main() {
  setUpAll(() => a3Bootstrap());
  tearDown(() => A3Services.reset());

  testWidgets('Brett: opens with the finds, Legg til adds', (tester) async {
    final api = FakeAegilApi();
    late BuildContext ctx;
    await tester.pumpWidget(a3App(Builder(builder: (c) {
      ctx = c;
      return const Scaffold(body: SizedBox());
    })));
    showAegilBrett(ctx, api: api);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const Key('aegil-brett')), findsOneWidget);
    expect(find.text('Reker fra Torgboden'), findsOneWidget);
    expect(aegilFindCount(), 2);
  });

  testWidgets('aegilGreeting greets by first name and refreshAegilFindCount counts', (tester) async {
    await tester.pumpWidget(a3App(Scaffold(body: Builder(builder: aegilGreeting))));
    expect(find.textContaining('Hei, Kari!'), findsOneWidget);
    final n = await refreshAegilFindCount(api: FakeAegilApi());
    expect(n, 2);
    expect(aegilFindCount(), 2);
  });
}
