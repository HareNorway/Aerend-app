import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/meg/a3_services.dart';
import 'package:aerend_customer/screens/bergen/meg/borte_entry.dart';

import '../a3/a3_fakes.dart';

/// AGIL-3-PLAN Phase 7 — Meg: the header, Gullbilletten, the Poeng card, the
/// rows, "Slik får du poeng", Konto's switches, Varsler's filters and swipe.
void main() {
  setUpAll(() => a3Bootstrap());
  tearDown(() {
    A3Services.reset();
    setMensDuVarBorteForTest(const []);
  });

  Future<void> settle(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
  }

  // The old Varsler page went in Gap Step 4; the panel is covered by
  // test/hjem/hjem_varsler_test.dart.

  test('mensDuVarBorteCard is null with nothing to say', () {
    setMensDuVarBorteForTest(const []);
    expect(mensDuVarBorteCard(_FakeContext()), isNull);
  });
}

class _FakeContext extends Fake implements BuildContext {}
