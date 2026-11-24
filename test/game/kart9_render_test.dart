import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:aerend_customer/game/fjordlopet/render/lopet_atlas9.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_data.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_kart9.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../a3/a3_fakes.dart';

/// Design (9) 1:1 plan Step 4: Sjøkortet draws the best run's path (its inputs through the engine), the course's
/// obstacles up to it, the gates, the flags and the fog. `--dart-define=OUT=<dir>` writes both charts as PNG.
void main() {
  setUp(() async => a3Bootstrap());
  LopetAtlas9.googleFont = false;
  lopetKartGoogleFont = false;

  test('the path follows the best run and the charts paint', () async {
    final g = (jsonDecode(File('test/game/fixtures/golden_runs.json').readAsStringSync()) as Map).cast<String, dynamic>();
    final course = ((g['courses'] as Map)['c1'] as Map).cast<String, dynamic>();
    final run = (g['runs'] as List).cast<Map>().firstWhere((r) => r['id'] == 121);
    final s = LopetState.fromJson({
      'status': 1,
      'session': {'id': 1, 'order_id': 42, 'state': 'open', 'runs_allowed': 3, 'runs_left': 2, 'bonus_granted': false, 'perk': 'none', 'tokens': ['rt_a', 'rt_b']},
      'course': {...course, 'id': 1, 'week': '2026-W47'},
      'personal_best_m': 516,
      'week_best_m': 1318,
      'rival': {'place': 30, 'name': 'Seiler 30', 'distance_m': 528},
      'ghost': {'inputs': run['inputs'], 'distance_m': 516, 'ticks': 3000, 'perk': run['perk']},
      'my_runs': [{'distance_m': 188, 'end_cause': {'obstacle': 'boye'}}, {'distance_m': 341, 'end_cause': {'obstacle': 'stokk'}}, {'distance_m': 516, 'end_cause': {'obstacle': 'boye'}}],
      'losgrad': {'name': 'Matros', 'lifetime_m': 6240},
      'level': {'index': 0, 'name': 'Bronse', 'boat': 'robaat'},
      'rewards': {'buoy1': 3, 'buoy2': 6, 'quay': 12, 'personal_best': 3, 'cap': 15, 'milestones_m': [200, 500, 1000]},
      'delivery': {'state': 'seen', 'stage': 1, 'stage_label': 'Tilberedes', 'promised_end': null, 'courier_eta_minutes': null, 'no_new_run': false},
      'vilkaar': ['Linje 1'],
      'profile': {'sound_on': false},
      'quality': {'max': 'high', 'low_model': false, 'up_p99_ms': 14, 'down_avg_ms': 18},
    })!;
    final sti = LopetKartSti.of(s, 516);
    expect(sti.mm.last, greaterThan(500), reason: 'the path reaches the best distance');
    expect(sti.lane.toSet().length, greaterThan(2), reason: 'it changes lanes');
    const out = String.fromEnvironment('OUT');
    for (final (name, size, painter) in [
      ('kart-mini', const Size(342, 98), LopetKart9Maler(s: s, bestM: 516) as CustomPainter),
      ('kart-stor', const Size(390, 2200), LopetStorKart9Maler(s: s, bestM: 516)),
    ]) {
      final rec = ui.PictureRecorder();
      final c = Canvas(rec)..scale(2);
      painter.paint(c, size);
      final img = await rec.endRecording().toImage((size.width * 2).round(), (size.height * 2).round());
      if (out.isNotEmpty) {
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$out/app-$name.png').writeAsBytesSync(png!.buffer.asUint8List());
      }
      img.dispose();
    }
  });
}
