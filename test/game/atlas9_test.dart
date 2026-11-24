import 'dart:io';
import 'dart:ui' as ui;

import 'package:aerend_customer/game/fjordlopet/render/lopet_atlas9.dart';
import 'package:aerend_customer/game/fjordlopet/render/lopet_look.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design (9) 1:1 plan Step 1: the design's atlas is loaded with every sprite the field draws, the text sprites are
/// made at runtime, and the density follows the device. `--dart-define=OUT=<dir>` writes the atlas as PNG for the
/// side-by-side check with the design's export.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  LopetAtlas9.googleFont = false;

  test('the atlas has the design sprites and the runtime text sprites', () async {
    for (final (mode, density) in [(LopetMode.kveld, 3.0), (LopetMode.dag, 2.0)]) {
      final a = await LopetAtlas9.build(
        density: density,
        mode: mode,
        level: density == 3 ? 'Gull' : 'Bronse',
        flags: const ['Din beste', 'Seiler 30', 'Ukens beste'],
        landmarks: const {0: 'Naustet', 2: 'Fyret'},
        name: 'Didrik',
      );
      for (final n in ['boye3', 'kasse3', 'stokkR0', 'stokkR3', 'kajakk3', 'beffen3', 'bk0', 'bk4', 'plattform', 'pboye0', 'pboye1', 'lm2', 'skrog', 'skyggeOm', 'vest', 'aegil', 'ring', 'glod', 'lysStr', 'maake7', 'portTx0', 'portTx2', 'flagg0', 'flagg1', 'flagg2', 'skyggeTx', 'lmTx2', 'boye3R', 'kasse3R']) {
        expect(a.id(n), greaterThanOrEqualTo(0), reason: n);
      }
      expect(a.density, density);
      expect(a.ew(a.id('boye3')), closeTo(2 * 17 * 1.05 + 8, .01), reason: 'design px, as the design table');
      const out = String.fromEnvironment('OUT');
      if (out.isNotEmpty) {
        final png = await a.image.toByteData(format: ui.ImageByteFormat.png);
        File('$out/app-atlas9-${mode.name}-${density.toInt()}x.png').writeAsBytesSync(png!.buffer.asUint8List());
      }
      a.dispose();
    }
  });
}
