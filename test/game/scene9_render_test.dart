import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:aerend_customer/game/fjordlopet/render/lopet_atlas9.dart';
import 'package:aerend_customer/game/fjordlopet/render/lopet_look.dart';
import 'package:aerend_customer/game/fjordlopet/render/lopet_loop.dart';
import 'package:aerend_customer/game/fjordlopet/render/lopet_scene9.dart';
import 'package:aerend_customer/game/fjordlopet/render/lopet_sea9.dart';
import 'package:aerend_customer/game/fjordlopet/sim/engine.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// Design (9) 1:1 plan Steps 2–3: the field paints a real run (golden run 121 on course c1) without errors, with the
/// water shader and the design's atlas. `--dart-define=OUT=<dir>` writes frames as PNG (390 × 844 at 2×) for the
/// side-by-side check with the design's mid-run frames.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  LopetAtlas9.googleFont = false;

  test('the field paints a run frame by frame', timeout: const Timeout(Duration(minutes: 10)), () async {
    final g = (jsonDecode(File('test/game/fixtures/golden_runs.json').readAsStringSync()) as Map).cast<String, dynamic>();
    final course = ((g['courses'] as Map)['c1'] as Map).cast<String, dynamic>();
    final run = (g['runs'] as List).cast<Map>().firstWhere((r) => r['id'] == 121);
    final inputs = [for (final i in (run['inputs'] as List)) (i as List).cast<int>()];
    final atlas = await LopetAtlas9.build(density: 2, mode: LopetMode.kveld, flags: const ['Din beste', 'Seiler 30', 'Ukens beste'], landmarks: const {0: 'Naustet', 1: 'Kranen', 2: 'Fyret', 3: 'Akvariet', 4: 'Festningen', 5: 'Seilskipet', 6: 'Verftet', 7: 'Sjøbadet'});
    final program = await LopetSea9.load();
    expect(program, isNotNull, reason: 'the water shader loads');
    final sea = LopetSea9(program!, LopetMode.kveld);
    final sim = FjordSim(course, run['perk'] as String);
    final loop = FjordLoop(sim);
    final fx = LopetFx9();
    final flags = LopetFlags9()
      ..bestMm = 120000
      ..weekMm = 1318000
      ..rivalMm = 300000;
    final painter = LopetScene9(
      loop: loop,
      atlas: atlas,
      sea: sea,
      fx: fx,
      flags: flags,
      milestones: const [200, 500, 1000],
      mode: LopetMode.kveld,
      landmarks: ((course['landmarks'] as List?) ?? const []).cast<Map>(),
    );
    const out = String.fromEnvironment('OUT');
    var ii = 0;
    for (final shot in const [200, 450, 1300, 2600]) {
      while (sim.tick < shot && !sim.done) {
        while (ii < inputs.length && inputs[ii][0] == sim.tick) {
          loop.input(inputs[ii][1]);
          ii++;
        }
        loop.step();
        fx.queue(loop.takeEvents());
        // a frame every other tick, as at 30 Hz: the foam map and the particles run
        if (sim.tick % 6 == 0) {
          final rec = ui.PictureRecorder();
          painter.paint(Canvas(rec), const Size(390, 844));
          rec.endRecording().dispose();
        }
      }
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      c.scale(2);
      painter.paint(c, const Size(390, 844));
      final img = await rec.endRecording().toImage(780, 1688);
      if (out.isNotEmpty) {
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$out/app-run-$shot.png').writeAsBytesSync(png!.buffer.asUint8List());
      }
      img.dispose();
    }
    expect(sim.tick, greaterThanOrEqualTo(2600));
    sea.dispose();
    atlas.dispose();
  });
}
