import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/kit/bergen_bakt.dart';
import 'package:aerend_customer/screens/bergen/kit/bergen_perf.dart';

/// Perf plan: BergenBakt draws its subtree from a raster with the same
/// pixels as the live Opacity / ShaderMask, reuses it while only the
/// opacity changes, and paints live where a raster would freeze motion.
void main() {
  setUp(() {
    BergenBakt.paa = true;
    BergenBakt.laget = 0;
    BergenBakt.levende = 0;
    BergenPerf.pass2BaktPaa = false;
    BergenBakt.debugRutenettUtenforRamme = false;
  });
  tearDown(() {
    BergenPerf.pass2BaktPaa = false;
    BergenBakt.debugRutenettUtenforRamme = false;
  });

  // Overlapping content: group opacity differs from per-primitive alpha here.
  Widget innhold({Color farge = const Color(0xFFE95C2C)}) => SizedBox(
    width: 140,
    height: 70,
    child: Stack(children: [
      Positioned(left: 0, top: 0, width: 100, height: 60, child: DecoratedBox(decoration: BoxDecoration(color: farge, borderRadius: BorderRadius.circular(14)))),
      const Positioned(left: 40, top: 10, width: 100, height: 60, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF1E8F72), shape: BoxShape.circle))),
      const Positioned(left: 10, top: 20, child: Text('Ærend', textDirection: TextDirection.ltr, style: TextStyle(fontSize: 18, color: Colors.white))),
    ]),
  );

  Widget scene(Widget child, GlobalKey key) => Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: RepaintBoundary(key: key, child: ColoredBox(color: const Color(0xFF123B46), child: Padding(padding: const EdgeInsets.all(24), child: child)))),
  );

  Future<Uint8List> piksler(WidgetTester tester, GlobalKey key) async {
    final ro = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = ro.toImageSync(pixelRatio: 2);
    final data = await tester.runAsync(() => img.toByteData(format: ui.ImageByteFormat.rawRgba));
    img.dispose();
    return data!.buffer.asUint8List();
  }

  double ulike(Uint8List a, Uint8List b) {
    var n = 0;
    for (var i = 0; i < a.length; i++) {
      if ((a[i] - b[i]).abs() > 8) n++;
    }
    return n / a.length;
  }

  testWidgets('same pixels as Opacity (group opacity over overlapping content)', (tester) async {
    final k = GlobalKey();
    await tester.pumpWidget(scene(Opacity(opacity: .55, child: innhold()), k));
    final live = await piksler(tester, k);
    await tester.pumpWidget(scene(BergenBakt(opacity: .55, child: innhold()), k));
    final bakt = await piksler(tester, k);
    expect(BergenBakt.laget, 1);
    expect(bakt.length, live.length);
    expect(ulike(live, bakt), lessThan(.01));
  });

  testWidgets('same pixels as a ShaderMask', (tester) async {
    final k = GlobalKey();
    Widget maske() => ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (r) => const LinearGradient(colors: [Color(0x00000000), Color(0xFF000000)]).createShader(r),
      child: innhold(),
    );
    await tester.pumpWidget(scene(maske(), k));
    final live = await piksler(tester, k);
    await tester.pumpWidget(scene(BergenBakt(child: maske()), k));
    final bakt = await piksler(tester, k);
    expect(ulike(live, bakt), lessThan(.01));
  });

  testWidgets('an opacity change reuses the raster; a change inside makes a new one', (tester) async {
    final k = GlobalKey();
    await tester.pumpWidget(scene(BergenBakt(opacity: .3, child: innhold()), k));
    expect(BergenBakt.laget, 1);
    for (final o in [.4, .5, .6, .7]) {
      await tester.pumpWidget(scene(BergenBakt(opacity: o, child: innhold()), k));
    }
    expect(BergenBakt.laget, 1, reason: 'only the opacity changed');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(scene(BergenBakt(opacity: .7, child: innhold(farge: const Color(0xFF2A6272))), k));
    expect(BergenBakt.laget, 2, reason: 'the content changed');
  });

  testWidgets('a nested repaint boundary is painted live (it could update on its own)', (tester) async {
    final k = GlobalKey();
    await tester.pumpWidget(scene(BergenBakt(opacity: .5, child: RepaintBoundary(child: innhold())), k));
    expect(BergenBakt.laget, 0);
  });

  testWidgets('a subtree that repaints every frame falls back to live painting', (tester) async {
    final k = GlobalKey();
    for (var i = 0; i < 10; i++) {
      await tester.pumpWidget(scene(BergenBakt(opacity: .5, child: innhold(farge: Color.fromARGB(255, 20 * i, 90, 110))), k));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(BergenBakt.levende, greaterThanOrEqualTo(1));
    expect(BergenBakt.laget, lessThanOrEqualTo(4));
    await tester.pump(const Duration(seconds: 1)); // the idle re-try timer
  });

  // ── Heat Step 7 (BergenPerf.pass2BaktPaa): the raster on the device pixel grid ──

  group('pass2Bakt: raster on the device pixel grid', () {
    setUp(() => BergenPerf.pass2BaktPaa = true);
    const dpr = 2.625; // the Vivo V40
    // Overlapping shapes, a blurred shadow and text: a real group-opacity
    // pass. The margin covers the shadow (blur 10 → σ ≈ 6.3, ×4 + offset).
    Widget motiv() => SizedBox(
      width: 140,
      height: 70,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(
          left: 0,
          top: 0,
          width: 100,
          height: 60,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFE95C2C),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: Color(0x8A04141C), blurRadius: 10, offset: Offset(0, 4))],
            ),
          ),
        ),
        const Positioned(left: 40, top: 10, width: 100, height: 60, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF1E8F72), shape: BoxShape.circle))),
        const Positioned(left: 10, top: 20, child: Text('Ærend', textDirection: TextDirection.ltr, style: TextStyle(fontSize: 18, color: Colors.white))),
      ]),
    );
    const margin = EdgeInsets.all(34);

    final rot = GlobalKey();
    // The screen: a root boundary at the origin, so a snapshot at the view's
    // pixel ratio has exactly the screen's device transform.
    Widget skjerm(Offset at, Widget child, {bool roter = false, Rect? klipp}) {
      Widget c = Transform.translate(offset: at, child: child);
      if (roter) c = Transform.rotate(angle: .1, child: c);
      if (klipp != null) {
        c = Padding(padding: EdgeInsets.only(left: klipp.left, top: klipp.top), child: ClipRect(child: SizedBox(width: klipp.width, height: klipp.height, child: OverflowBox(alignment: Alignment.topLeft, maxWidth: 400, maxHeight: 400, child: c))));
      }
      return Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: rot,
          child: ColoredBox(color: const Color(0xFF123B46), child: Align(alignment: Alignment.topLeft, child: c)),
        ),
      );
    }

    Future<Uint8List> skudd(WidgetTester tester) async {
      final ro = rot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = ro.toImageSync(pixelRatio: dpr);
      final data = await tester.runAsync(() => img.toByteData(format: ui.ImageByteFormat.rawRgba));
      img.dispose();
      return data!.buffer.asUint8List();
    }

    int maks(Uint8List a, Uint8List b) {
      expect(a.length, b.length);
      var m = 0;
      for (var i = 0; i < a.length; i++) {
        final d = (a[i] - b[i]).abs();
        if (d > m) m = d;
      }
      return m;
    }

    void skjermStr(WidgetTester tester) {
      tester.view.devicePixelRatio = dpr;
      tester.view.physicalSize = const Size(1080, 1080);
      addTearDown(tester.view.reset);
      BergenBakt.debugRutenettUtenforRamme = true;
    }

    testWidgets('same pixels as Opacity at fractional device offsets (≤ 1/255)', (tester) async {
      skjermStr(tester);
      for (final (at, o) in [(const Offset(47.3, 51.77), .55), (const Offset(80.123, 49.5), .3), (const Offset(52.9, 140.06), .9)]) {
        await tester.pumpWidget(skjerm(at, Opacity(opacity: o, child: motiv())));
        final live = await skudd(tester);
        BergenBakt.laget = 0;
        await tester.pumpWidget(skjerm(at, BergenBakt(opacity: o, margin: margin, child: motiv())));
        expect(BergenBakt.laget, 1, reason: 'the raster is made in the frame');
        final bakt = await skudd(tester);
        expect(maks(live, bakt), lessThanOrEqualTo(1), reason: 'at $at, opacity $o');
        // The same widget, the switch off: today's resampled placement.
        BergenPerf.pass2BaktPaa = false;
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(skjerm(at, BergenBakt(opacity: o, margin: margin, child: motiv())));
        final foer = await skudd(tester);
        BergenPerf.pass2BaktPaa = true;
        await tester.pumpWidget(const SizedBox());
        // ignore: avoid_print
        print('PASS2_BAKT at=$at o=$o max|grid−live|=${maks(live, bakt)} max|old−live|=${maks(live, foer)}');
      }
    });

    testWidgets('a parent moves the boundary without painting it: a new raster at the new offset, same pixels', (tester) async {
      skjermStr(tester);
      await tester.pumpWidget(skjerm(const Offset(60.2, 70.3), BergenBakt(opacity: .6, margin: margin, child: motiv())));
      expect(BergenBakt.laget, 1);
      await tester.pump(const Duration(seconds: 1));
      // Only the translation above changes; the BergenBakt is not repainted.
      await tester.pumpWidget(skjerm(const Offset(60.65, 71.1), BergenBakt(opacity: .6, margin: margin, child: motiv())));
      expect(BergenBakt.laget, 2, reason: 'the layer saw the new device position');
      final bakt = await skudd(tester);
      await tester.pumpWidget(skjerm(const Offset(60.65, 71.1), Opacity(opacity: .6, child: motiv())));
      final live = await skudd(tester);
      expect(maks(live, bakt), lessThanOrEqualTo(1));
    });

    testWidgets('moving on every frame: live, then the raster again once still for 600 ms', (tester) async {
      skjermStr(tester);
      for (var i = 0; i < 8; i++) {
        await tester.pumpWidget(skjerm(Offset(60 + .37 * i, 70), BergenBakt(opacity: .6, margin: margin, child: motiv())));
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(BergenBakt.levende, 1, reason: 'it moved on most frames');
      final laget = BergenBakt.laget;
      expect(laget, lessThanOrEqualTo(4));
      final live = await skudd(tester); // added live while moving
      // Nothing on this test screen asks for frames; on a phone something else
      // animating does. The next frame after 600 ms still rasters it again.
      await tester.pump(const Duration(milliseconds: 300));
      tester.binding.scheduleFrame();
      await tester.pump(const Duration(milliseconds: 16));
      expect(BergenBakt.laget, laget, reason: 'still for less than 600 ms: live');
      await tester.pump(const Duration(milliseconds: 400));
      tester.binding.scheduleFrame();
      await tester.pump(const Duration(milliseconds: 16));
      expect(BergenBakt.laget, laget + 1, reason: 'still for 600 ms: rastered again');
      final bakt = await skudd(tester);
      expect(maks(live, bakt), lessThanOrEqualTo(1));
    });

    testWidgets('under a rotation, or cut by a clip: live (no raster)', (tester) async {
      skjermStr(tester);
      await tester.pumpWidget(skjerm(const Offset(40.4, 40.4), BergenBakt(opacity: .6, margin: margin, child: motiv()), roter: true));
      expect(BergenBakt.laget, 0);
      final bakt = await skudd(tester);
      await tester.pumpWidget(skjerm(const Offset(40.4, 40.4), Opacity(opacity: .6, child: motiv()), roter: true));
      expect(maks(await skudd(tester), bakt), 0);
      await tester.pumpWidget(const SizedBox());
      // The clip cuts through the raster's area (box and shadow margin).
      await tester.pumpWidget(skjerm(const Offset(40.4, 40.4), BergenBakt(opacity: .6, margin: margin, child: motiv()), klipp: const Rect.fromLTWH(10, 10, 120, 300)));
      expect(BergenBakt.laget, 0);
      final klippet = await skudd(tester);
      await tester.pumpWidget(skjerm(const Offset(40.4, 40.4), Opacity(opacity: .6, child: motiv()), klipp: const Rect.fromLTWH(10, 10, 120, 300)));
      expect(maks(await skudd(tester), klippet), 0);
    });

    testWidgets('an opacity change reuses the raster; opacity 1 matches the bare child', (tester) async {
      skjermStr(tester);
      const at = Offset(61.7, 77.31);
      for (final o in [.3, .4, .5, .6, .7, 1.0]) {
        await tester.pumpWidget(skjerm(at, BergenBakt(opacity: o, margin: margin, child: motiv())));
      }
      expect(BergenBakt.laget, 1, reason: 'only the opacity changed');
      final bakt = await skudd(tester);
      await tester.pumpWidget(skjerm(at, motiv()));
      final bar = await skudd(tester);
      // The raster holds the content in 8 bits once before blending; drawn
      // straight onto the screen a translucent pixel is rounded once less.
      final d = maks(bar, bakt);
      // ignore: avoid_print
      print('PASS2_BAKT opacity 1 vs bare child: max $d');
      expect(d, lessThanOrEqualTo(1));
    });

    testWidgets('a change inside while at opacity 0 shows once it fades back in', (tester) async {
      skjermStr(tester);
      Widget m(Color c) => SizedBox(width: 60, height: 40, child: Stack(children: [ColoredBox(color: c, child: const SizedBox.expand()), const Center(child: Text('Æ', textDirection: TextDirection.ltr))]));
      await tester.pumpWidget(skjerm(const Offset(10.5, 10.5), BergenBakt(opacity: .5, child: m(const Color(0xFFE95C2C)))));
      await tester.pumpWidget(skjerm(const Offset(10.5, 10.5), BergenBakt(opacity: 0, child: m(const Color(0xFFE95C2C)))));
      await tester.pumpWidget(skjerm(const Offset(10.5, 10.5), BergenBakt(opacity: 0, child: m(const Color(0xFF1E8F72)))));
      await tester.pumpWidget(skjerm(const Offset(10.5, 10.5), BergenBakt(opacity: .5, child: m(const Color(0xFF1E8F72)))));
      final bakt = await skudd(tester);
      await tester.pumpWidget(skjerm(const Offset(10.5, 10.5), Opacity(opacity: .5, child: m(const Color(0xFF1E8F72)))));
      expect(maks(await skudd(tester), bakt), lessThanOrEqualTo(1));
    });
  });
}
