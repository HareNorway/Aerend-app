import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/kit/bergen_bakt.dart';

/// Perf plan: BergenBakt draws its subtree from a raster with the same
/// pixels as the live Opacity / ShaderMask, reuses it while only the
/// opacity changes, and paints live where a raster would freeze motion.
void main() {
  setUp(() {
    BergenBakt.paa = true;
    BergenBakt.laget = 0;
    BergenBakt.levende = 0;
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
}
