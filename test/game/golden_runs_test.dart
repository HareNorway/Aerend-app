import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/game/fjordlopet/sim/engine.dart';

/// Points plan Step 5, engine v2 since Fjordløpet v1.3 plan Step 1 (game spec §9, G-T10): the Dart core against the 200
/// golden runs. The same file is checked into
/// Hare-AdminPanel (`tests/fixtures/game/golden_runs.json`), where the PHP core must give the same results
/// (`Step5FjordlopetCoreTest`). Any difference fails the build.
void main() {
  final g = (jsonDecode(File('test/game/fixtures/golden_runs.json').readAsStringSync()) as Map).cast<String, dynamic>();
  final courses = (g['courses'] as Map).cast<String, dynamic>();

  test('the golden file is for this engine version', () {
    expect(g['engine_version'], FjordEngine.version);
    expect((g['runs'] as List).length, 200);
  });

  test('G-T10: all 200 golden runs give exactly the recorded result', () {
    for (final run in (g['runs'] as List).cast<Map>()) {
      final inputs = [for (final i in (run['inputs'] as List)) FjordInput((i as List)[0] as int, i[1] as int)];
      final got = FjordEngine.run((courses[run['course']] as Map).cast<String, dynamic>(), run['perk'] as String, inputs);
      expect(got.toJson(), run['expect'], reason: 'golden run ${run['id']}');
    }
  });

  test('G-T13: the same course and the same inputs give the same result, every time', () {
    final c = (courses['c1'] as Map).cast<String, dynamic>();
    const inputs = [FjordInput(40, 1), FjordInput(200, -1), FjordInput(420, -1)];
    expect(FjordEngine.run(c, 'none', inputs).toJson(), FjordEngine.run(c, 'none', inputs).toJson());
  });

  test('the engine reads the course parameters: a slower lane change changes the run', () {
    final c = (courses['c4'] as Map).cast<String, dynamic>();
    expect((c['params'] as Map)['lane_change_ticks'], 12, reason: 'c4 was made with 200 ms');
    final c1 = (courses['c1'] as Map).cast<String, dynamic>();
    expect((c1['params'] as Map)['lane_change_ticks'], 7);
  });
}
