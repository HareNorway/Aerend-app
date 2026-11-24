import 'dart:ui' as ui;

import 'package:aerend_customer/game/fjordlopet/render/lopet_atlas9.dart';
import 'package:aerend_customer/game/fjordlopet/render/lopet_look.dart';
import 'package:aerend_customer/game/fjordlopet/render/lopet_sea9.dart';
import 'package:flutter_test/flutter_test.dart';

/// Design (9) 1:1 (2026-11-24, emulator): a ring or streak stamped into the foam map fades away within seconds, as the
/// design's (`max(t − 0.0055·dt, 0) · 0.985^dt`); under Impeller the colour-matrix fade did nothing and every stamp stayed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  LopetAtlas9.googleFont = false;

  test('a stamp fades out of the foam map', () async {
    final a = await LopetAtlas9.build(density: 2);
    final s = LopetSea9((await LopetSea9.load())!, LopetMode.kveld);
    Future<int> maxRed() async {
      final d = (await s.foamImage!.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      var mx = 0;
      for (var k = 0; k < d.lengthInBytes; k += 4) {
        if (d.getUint8(k) > mx) mx = d.getUint8(k);
      }
      return mx;
    }

    s.stamp(a.id('ringS'), 64, 256, 1, 1, 1);
    s.updateFoam(1, atlas: a.image, src: a.src, geo: a.geo, density: a.density, on: true);
    expect(await maxRed(), greaterThan(150));
    for (var i = 0; i < 240; i++) {
      s.updateFoam(1, atlas: a.image, src: a.src, geo: a.geo, density: a.density, on: true);
    }
    expect(await maxRed(), lessThanOrEqualTo(3), reason: 'gone after 4 s at 60 Hz');
    // A new run starts on clean water.
    s.stamp(a.id('ringS'), 64, 256, 1, 1, 1);
    s.updateFoam(1, atlas: a.image, src: a.src, geo: a.geo, density: a.density, on: true);
    s.clearFoam();
    expect(s.foamImage, isNull);
    s.dispose();
    a.dispose();
  });
}
