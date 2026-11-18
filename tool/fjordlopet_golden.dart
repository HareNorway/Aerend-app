// Points plan Step 5 (game spec §9, G-T10): computes the golden runs' results with the Dart core, once.
//
//   dart run tool/fjordlopet_golden.dart <inputs.json from `php artisan game:golden --make`> <golden_runs.json>
//
// The output is checked into both repos: aerend-app `test/game/fixtures/golden_runs.json` (golden_runs_test.dart) and
// Hare-AdminPanel `tests/fixtures/game/golden_runs.json` (GoldenRunsTest). Any difference between the cores fails CI.
import 'dart:convert';
import 'dart:io';

import 'package:aerend_customer/game/fjordlopet/sim/engine.dart';

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('usage: dart run tool/fjordlopet_golden.dart <inputs.json> <golden_runs.json>');
    exit(64);
  }
  final g = (jsonDecode(File(args[0]).readAsStringSync()) as Map).cast<String, dynamic>();
  final courses = (g['courses'] as Map).cast<String, dynamic>();
  for (final run in (g['runs'] as List).cast<Map>()) {
    final inputs = [for (final i in (run['inputs'] as List)) FjordInput((i as List)[0] as int, i[1] as int)];
    run['expect'] = FjordEngine.run((courses[run['course']] as Map).cast<String, dynamic>(), run['perk'] as String, inputs).toJson();
  }
  g['engine_version'] = FjordEngine.version;
  g['made_by'] = 'dart core (tool/fjordlopet_golden.dart)';
  File(args[1]).writeAsStringSync(jsonEncode(g));
  stdout.writeln('Wrote ${args[1]}: ${(g['runs'] as List).length} runs.');
}
