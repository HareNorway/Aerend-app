import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/sporing/sporing_copy.dart';
import 'package:aerend_customer/services/customer/beacons.dart';

import '../a3/a3_fakes.dart';

/// The 03 customer-app test pass fixes (2026-11-03) that are plain functions: the error beacon's first app frame
/// (CUS-B15), the cancelled order's line (CUS-A24) and the «Klar» line of a delivery order (C1).
void main() {
  setUpAll(() => a3Bootstrap());

  test('the first frame inside the app is a file and a line, nothing else', () {
    final lines = [
      '#0      _AssertionError._doThrowNew (dart:core-patch/errors_patch.dart:67:4)',
      '#1      StatefulElement.unmount (package:flutter/src/widgets/framework.dart:6268:12)',
      '#2      visTakkArk (package:aerend_customer/screens/bergen/sporing/takk_ark.dart:79:5)',
    ];
    expect(CusBeacons.forsteAppRamme(lines), 'screens/bergen/sporing/takk_ark.dart:79');
    expect(CusBeacons.forsteAppRamme(const ['#0 main (package:other/x.dart:1:1)']), isNull);
  });

  test('a cancelled order says why and that the refund has started', () {
    expect(SporingCopy.avbestiltLinje('Butikken var stengt.', 'Refusjon er startet.'), 'Butikken var stengt. Refusjon er startet.');
    expect(SporingCopy.avbestiltLinje('Butikken er tom for skrei', 'Refusjon er startet.'), 'Butikken er tom for skrei. Refusjon er startet.');
    expect(SporingCopy.avbestiltLinje(null, null), SporingCopy.a1_sporing_avbestilt);
    expect(SporingCopy.avbestiltLinje('  ', 'Refusjon er startet.'), '${SporingCopy.a1_sporing_avbestilt} Refusjon er startet.');
  });

  test('a delivery order the store made ready no longer reads as cooking', () {
    expect(SporingCopy.klarLinje(false, 'Torgboden'), contains('budet henter'));
    expect(SporingCopy.klarLinje(true, 'Torgboden'), contains('Torgboden kjører den ut'));
  });
}
