import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/kit/bergen_perf.dart';
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
    BergenPerf.pass2CssPaa = false;
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

  test('an equal (but new) look does not repaint; a different one does', () {
    CssBoxPainter p(Color c) => CssBoxPainter(
      radius: BorderRadius.circular(12),
      bg: [CssLinear(165, [c, const Color(0xFF2A1208)])],
      shadows: [CssShadow(0, 12, 18, -12, c.withValues(alpha: .6)), const CssShadow.inset(0, 1.5, 0, 0, Color(0x80FFFFFF))],
    );
    expect(p(const Color(0xFF123456)).shouldRepaint(p(const Color(0xFF123456))), isFalse);
    expect(p(const Color(0xFF123456)).shouldRepaint(p(const Color(0xFF654321))), isTrue);
  });

  // ── Heat Step 7 (BergenPerf.pass2CssPaa) ──

  for (final pass2 in [true, false]) {
    testWidgets('pass2 ${pass2 ? 'on' : 'off'}: after an animated entrance the box ${pass2 ? 'returns to' : 'stays off'} the raster once still', (tester) async {
      BergenPerf.pass2CssPaa = pass2;
      // The entrance: the look changes on every frame, so the box goes live.
      for (var i = 0; i < 12; i++) {
        await tester.pumpWidget(scene(boks(farge: Color.fromARGB(255, 10 * i, 80, 120))));
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(CssBake.bom, lessThanOrEqualTo(4), reason: 'live after a few misses');
      // It stops changing: nothing repaints it any more.
      final bom = CssBake.bom, treff = CssBake.treff;
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(CssBake.bom + CssBake.treff, bom + treff, reason: 'still for less than 600 ms: no repaint');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      if (pass2) {
        expect(CssBake.bom, bom + 1, reason: 'one repaint, which rasters the final look');
        // From now on a repaint draws the raster.
        Widget ramme(int i) => scene(ColoredBox(color: Color.fromARGB(255, i, 0, 0), child: boks(farge: const Color.fromARGB(255, 110, 80, 120))));
        await tester.pumpWidget(ramme(1));
        await tester.pumpWidget(ramme(2));
        expect(CssBake.treff, greaterThan(treff), reason: 'drawn from the raster');
      } else {
        expect(CssBake.bom + CssBake.treff, bom + treff, reason: 'switch off: stays live as before');
      }
    });
  }

  testWidgets('measured: the raster vs the live painter at a fractional device offset', (tester) async {
    // What a box shows once it is back on the raster (CssBake draws its
    // image at the 1/16-rounded scale, resampled at the box's position).
    const dpr = 2.625;
    tester.view.devicePixelRatio = dpr;
    tester.view.physicalSize = const Size(1080, 1080);
    addTearDown(tester.view.reset);
    final rot = GlobalKey();
    Widget skjerm(Offset at) => Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: rot,
        child: ColoredBox(color: const Color(0xFF123B46), child: Align(alignment: Alignment.topLeft, child: Transform.translate(offset: at, child: boks()))),
      ),
    );
    Future<Uint8List> skudd() async {
      final ro = rot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = ro.toImageSync(pixelRatio: dpr);
      final data = await tester.runAsync(() => img.toByteData(format: ui.ImageByteFormat.rawRgba));
      img.dispose();
      return data!.buffer.asUint8List();
    }

    for (final at in const [Offset(40, 40), Offset(47.3, 51.77), Offset(80.123, 49.5)]) {
      CssBake.paa = false;
      await tester.pumpWidget(skjerm(at));
      final live = await skudd();
      CssBake.paa = true;
      CssBake.tom();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(skjerm(at));
      expect(CssBake.bom, greaterThanOrEqualTo(1));
      final bakt = await skudd();
      var maks = 0, over1 = 0;
      for (var i = 0; i < live.length; i++) {
        final d = (live[i] - bakt[i]).abs();
        if (d > maks) maks = d;
        if (d > 1) over1++;
      }
      // ignore: avoid_print
      print('CSSBAKE_VS_LIVE at=$at max=$maks channels>1: $over1 of ${live.length}');
      await tester.pumpWidget(const SizedBox());
    }
  });
}
