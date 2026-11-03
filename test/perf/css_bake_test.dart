import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/common/auth/launch/lf_css.dart';

/// Perf plan: CssBake (the CssBox raster cache) must draw the same pixels as
/// the live painter, reuse its raster across frames and boxes, and fall back
/// to live painting for a box whose look changes every frame.
void main() {
  setUp(() {
    CssBake.paa = true;
    CssBake.tom();
    CssBake.treff = 0;
    CssBake.bom = 0;
  });
  tearDown(() {
    CssBake.paa = true;
    CssBake.tom();
  });

  const shadows = [
    CssShadow(0, 6, 14, 0, Color.fromRGBO(4, 20, 28, .35)),
    CssShadow.inset(0, 2, 6, 0, Color.fromRGBO(255, 255, 255, .5)),
    CssShadow.inset(0, -3, 8, 0, Color.fromRGBO(0, 0, 0, .25)),
  ];
  const bg = [
    CssLinear(180, [Color(0xFFFF9466), Color(0xFFE95C2C)]),
  ];

  Widget boks({Color? farge, double w = 120}) => CssBox(
    width: w,
    height: 48,
    radius: BorderRadius.circular(16),
    bg: farge == null ? bg : [CssSolid(farge)],
    shadows: shadows,
    border: Border.all(color: const Color(0x66FFFFFF)),
  );

  Widget scene(Widget child, {GlobalKey? key}) => Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: RepaintBoundary(
        key: key,
        child: Padding(padding: const EdgeInsets.all(30), child: child),
      ),
    ),
  );

  Future<Uint8List> piksler(WidgetTester tester, GlobalKey key) async {
    final ro = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = ro.toImageSync(pixelRatio: 2);
    final data = await tester.runAsync(() => img.toByteData(format: ui.ImageByteFormat.rawRgba));
    img.dispose();
    return data!.buffer.asUint8List();
  }

  testWidgets('a box with blurred shadows is rastered once and reused', (tester) async {
    // A parent that repaints every frame (as under a running animation)
    // repaints the box too: each repaint must hit the raster.
    Widget ramme(int i) => scene(ColoredBox(color: Color.fromARGB(255, i, 0, 0), child: boks()));
    await tester.pumpWidget(ramme(0));
    expect(CssBake.bom, 1);
    for (var i = 1; i <= 5; i++) {
      await tester.pumpWidget(ramme(i));
    }
    expect(CssBake.bom, 1, reason: 'repaints with the same look reuse the raster');
    expect(CssBake.treff, 5);
  });

  testWidgets('identical boxes share one raster', (tester) async {
    await tester.pumpWidget(scene(Column(mainAxisSize: MainAxisSize.min, children: [boks(), boks(), boks()])));
    expect(CssBake.bom, 1);
    expect(CssBake.treff, 2);
  });

  testWidgets('a box whose look changes every frame falls back to live painting', (tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pumpWidget(scene(boks(farge: Color.fromARGB(255, 10 * i, 80, 120))));
    }
    expect(CssBake.bom, lessThanOrEqualTo(4), reason: 'after a few misses the box paints live');
  });

  testWidgets('a box without blur or translucent shadow is not rastered', (tester) async {
    await tester.pumpWidget(scene(const CssBox(width: 60, height: 20, bg: [CssSolid(Color(0xFF123456))])));
    expect(CssBake.bom, 0);
  });

  testWidgets('the raster draws the same pixels as the live painter', (tester) async {
    final key = GlobalKey();
    CssBake.paa = false;
    await tester.pumpWidget(scene(boks(), key: key));
    final live = await piksler(tester, key);
    CssBake.paa = true;
    CssBake.tom();
    await tester.pumpWidget(scene(boks(w: 120.0001), key: key));
    await tester.pumpWidget(scene(boks(), key: key));
    expect(CssBake.bom, greaterThanOrEqualTo(1));
    final bakt = await piksler(tester, key);
    expect(bakt.length, live.length);
    var maks = 0, ulike = 0;
    for (var i = 0; i < live.length; i++) {
      final d = (live[i] - bakt[i]).abs();
      if (d > maks) maks = d;
      if (d > 8) ulike++;
    }
    // Same paint commands; only resampling of the raster may differ, by a
    // few levels on anti-aliased edges.
    expect(ulike / live.length, lessThan(.01), reason: 'max channel difference $maks');
  });
}
