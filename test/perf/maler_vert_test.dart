import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/aegil/aegil_floyen.dart';
import 'package:aerend_customer/screens/bergen/kit/bergen_perf.dart';
import 'package:aerend_customer/screens/bergen/kit/maler_vert.dart';
import 'package:aerend_customer/screens/bergen/kit/scene_gl.dart';
import 'package:aerend_customer/screens/bergen/kit/sjo_water.dart';
import 'package:aerend_customer/screens/bergen/meg/meg_hero.dart';
import 'package:aerend_customer/screens/bergen/sporing/sporing_gl.dart';
import 'package:aerend_customer/screens/common/home/bergen/bergen_kit.dart' show BergenWeather;

/// Heat plan Step 6 (`BergenPerf.malerVertPaa`): the shader hosts draw their
/// frames through MalerVert instead of RawImage, and two scenes read a baked
/// static part back instead of computing it. Both must give the pixels of
/// the old path.
///
/// Shaders run here on Skia's CPU raster (SkSL), not on Impeller: the tests
/// prove the math of the splits and the painter; the device diff (Step 6
/// checks) proves the GPU.
void main() {
  tearDown(() {
    BergenPerf.malerVertPaa = true;
    BergenPerf.frysMs = null;
    BergenPerf.stegRammerPaa = true;
  });

  Future<Uint8List> rgba(WidgetTester tester, ui.Image img) async {
    final bd = await tester.runAsync(() => img.toByteData(format: ui.ImageByteFormat.rawRgba));
    return bd!.buffer.asUint8List();
  }

  /// (pixels that differ, largest channel difference).
  (int, int) diff(Uint8List a, Uint8List b) {
    expect(a.length, b.length);
    var n = 0, maks = 0;
    for (var i = 0; i < a.length; i += 4) {
      var d = 0;
      for (var c = 0; c < 4; c++) {
        d = math.max(d, (a[i + c] - b[i + c]).abs());
      }
      if (d > 0) n++;
      maks = math.max(maks, d);
    }
    return (n, maks);
  }

  ui.Image run(ui.FragmentShader sh, int pw, int ph) {
    final rec = ui.PictureRecorder();
    Canvas(rec).drawRect(Rect.fromLTWH(0, 0, pw.toDouble(), ph.toDouble()), Paint()..shader = sh);
    return rec.endRecording().toImageSync(pw, ph);
  }

  Future<ui.Image> asset(WidgetTester tester, String path, [int? w, int? h]) async {
    final img = await tester.runAsync(() async {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: w, targetHeight: h);
      return (await codec.getNextFrame()).image;
    });
    return img!;
  }

  Future<ui.FragmentProgram> program(WidgetTester tester, String a) async => (await tester.runAsync(() => ui.FragmentProgram.fromAsset(a)))!;

  group('MalerVert draws as RawImage', () {
    // A test frame with hard edges and a smooth ramp, so any change in
    // filtering, scaling or placement shows.
    ui.Image testbilde(int w, int h, int sd) {
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      final r = math.Random(sd);
      c.drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(w.toDouble(), h.toDouble()), const [Color(0xFF103040), Color(0xFFE0B070)]));
      for (var k = 0; k < 40; k++) {
        c.drawRect(Rect.fromLTWH(r.nextDouble() * w, r.nextDouble() * h, 1 + r.nextDouble() * 9, 1 + r.nextDouble() * 9), Paint()..color = Color(0xFF000000 | r.nextInt(0xFFFFFF)));
      }
      return rec.endRecording().toImageSync(w, h);
    }

    Widget scene(GlobalKey key, Widget child, {required double l, required double t, required double w, required double h}) => Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: key,
          child: SizedBox(
            width: 400,
            height: 300,
            child: Stack(children: [Positioned(left: l, top: t, width: w, height: h, child: child)]),
          ),
        ),
      ),
    );

    Future<Uint8List> piksler(WidgetTester tester, GlobalKey key, double pr) async {
      final ro = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = ro.toImageSync(pixelRatio: pr);
      final b = await rgba(tester, img);
      img.dispose();
      return b;
    }

    for (final (l, t, w, h, iw, ih, pr, fq) in const [
      (0.0, 0.0, 390.0, 196.0, 585, 294, 3.0, FilterQuality.medium), // Meg: 1.5× frame on a 3× screen
      (13.37, 41.5, 300.0, 200.0, 640, 427, 2.0, FilterQuality.medium), // fractional offset, downscaled
      (5.25, 7.75, 233.3, 101.1, 97, 61, 2.75, FilterQuality.medium), // upscaled, odd sizes
      (1.0, 2.0, 160.0, 90.0, 333, 177, 3.0, FilterQuality.low),
    ]) {
      testWidgets('frame ${iw}x$ih in ${w}x$h at ($l, $t), ${pr}x, $fq', (tester) async {
        final ka = GlobalKey(), kb = GlobalKey();
        final img = testbilde(iw, ih, iw);
        await tester.pumpWidget(scene(ka, RawImage(image: img, width: w, height: h, fit: BoxFit.fill, filterQuality: fq), l: l, t: t, w: w, h: h));
        final a = await piksler(tester, ka, pr);
        final ramme = MalerRamme()..sett(img.clone());
        await tester.pumpWidget(scene(kb, MalerVert(ramme: ramme, width: w, height: h, filterQuality: fq), l: l, t: t, w: w, h: h));
        final b = await piksler(tester, kb, pr);
        expect(diff(a, b), (0, 0));
        await tester.pumpWidget(const SizedBox());
        ramme.dispose();
        img.dispose();
      });
    }

    testWidgets('a new frame repaints without a rebuild; the old frame is disposed', (tester) async {
      final key = GlobalKey();
      final ramme = MalerRamme();
      var bygg = 0;
      final a = testbilde(120, 80, 1), b = testbilde(120, 80, 2);
      final aKopi = a.clone(), bKopi = b.clone();
      await tester.pumpWidget(scene(key, Builder(builder: (_) {
        bygg++;
        return MalerVert(ramme: ramme, width: 200, height: 100);
      }), l: 3, t: 4, w: 200, h: 100));
      ramme.sett(a);
      await tester.pump();
      final pa = await piksler(tester, key, 2);
      ramme.sett(b);
      expect(a.debugDisposed, isTrue);
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pump();
      final pb = await piksler(tester, key, 2);
      expect(bygg, 1);
      // Each paint is the frame it had: compare with RawImage.
      final k2 = GlobalKey();
      await tester.pumpWidget(scene(k2, RawImage(image: aKopi, width: 200, height: 100, fit: BoxFit.fill, filterQuality: FilterQuality.medium), l: 3, t: 4, w: 200, h: 100));
      expect(diff(pa, await piksler(tester, k2, 2)), (0, 0));
      await tester.pumpWidget(scene(k2, RawImage(image: bKopi, width: 200, height: 100, fit: BoxFit.fill, filterQuality: FilterQuality.medium), l: 3, t: 4, w: 200, h: 100));
      expect(diff(pb, await piksler(tester, k2, 2)), (0, 0));
      await tester.pumpWidget(const SizedBox());
      ramme.dispose();
      expect(b.debugDisposed, isTrue);
      // After dispose a late frame is dropped, not leaked.
      final c = testbilde(4, 4, 3);
      ramme.sett(c);
      expect(c.debugDisposed, isTrue);
      aKopi.dispose();
      bKopi.dispose();
    });
  });

  group('SceneGl berg split', () {
    // SpGl's render size for Flesland's rock: 410 × 300 within 300 000 px at
    // ≤ 2× (`full`), and the `lite` budget (55 %).
    for (final (vaer, budget, tider) in const [
      (BergenWeather.sol, 300000.0, [12.0, 47.3, 391.9]),
      (BergenWeather.regn, 300000.0, [12.0, 1203.25]),
      (BergenWeather.natt, 165000.0, [88.8]),
    ]) {
      testWidgets('$vaer, $budget px: split == scene_gl.frag', (tester) async {
        late SpGl gl;
        await tester.pumpWidget(Builder(builder: (context) {
          gl = SceneGl(kind: SceneKind.berg, weather: vaer, still: const SizedBox()).build(context) as SpGl;
          return const SizedBox();
        }));
        final del = gl.del!;
        const w = 410.0, h = 300.0;
        final dpr = math.max(.5, math.min(2.0, math.sqrt(budget / (w * h))));
        final pw = (w * dpr).round(), ph = (h * dpr).round();
        final tex = <ui.Image>[
          await asset(tester, 'assets/images/scgl/berg.png', 1024, 1024),
          await asset(tester, 'assets/images/scgl/berg_1.png', 512, 512),
          await asset(tester, 'assets/images/scgl/berg_2.png', 256, 256),
          await asset(tester, 'assets/images/scgl/berg_3.png', 128, 128),
        ];
        final orig = (await program(tester, gl.asset)).fragmentShader();
        final liv = (await program(tester, del.liv)).fragmentShader();
        final bake = (await program(tester, del.bake)).fragmentShader();

        final u0 = <double>[];
        gl.uniforms(u0.add, 0, 0, (_) => true);
        final bu = <double>[];
        del.bakeU(u0, bu.add);
        final lag = <ui.Image>[];
        for (var n = 0; n < malerNivaaer; n++) {
          var i = 0;
          void f(double v) => bake.setFloat(i++, v);
          f(w);
          f(h);
          f(pw / w);
          bu.forEach(f);
          f(n.toDouble());
          for (var k = 0; k < 4; k++) {
            bake.setImageSampler(k, tex[k]);
          }
          lag.add(run(bake, pw, ph));
        }
        for (final t in tider) {
          final u = <double>[];
          gl.uniforms(u.add, t, t, (_) => true);
          var i = 0;
          void f(double v) => orig.setFloat(i++, v);
          f(w);
          f(h);
          f(pw / w);
          f(t % 3600);
          u.forEach(f);
          for (var k = 0; k < 4; k++) {
            orig.setImageSampler(k, tex[k]);
          }
          final a = run(orig, pw, ph);
          i = 0;
          void g(double v) => liv.setFloat(i++, v);
          g(w);
          g(h);
          g(pw / w);
          g(t % 3600);
          del.livU(u, g);
          g(pw.toDouble());
          g(ph.toDouble());
          for (var k = 0; k < 4; k++) {
            liv.setImageSampler(k, tex[k]);
          }
          for (var k = 0; k < lag.length; k++) {
            liv.setImageSampler(4 + k, lag[k]);
          }
          final b = run(liv, pw, ph);
          final d = diff(await rgba(tester, a), await rgba(tester, b));
          // ignore: avoid_print
          print('scene_gl berg $vaer ${pw}x$ph t=$t: ${d.$1} px differ, max ${d.$2}/255');
          expect(d, (0, 0));
          a.dispose();
          b.dispose();
        }
        for (final x in [...tex, ...lag]) {
          x.dispose();
        }
      });
    }
  });

  group('hosts: switch off vs on, frozen clock', () {
    // Each host runs with `malerVert: false` (setState + RawImage, unsplit
    // shaders), then the switch goes on in the same instance (MalerVert, and
    // for Ægil·Fløyen and Flesland the bake, then the split). The screen's
    // pixels at the same scene time must be the same, and with the switch on
    // a new frame must not rebuild the host.
    Future<Uint8List> skjerm(WidgetTester tester, GlobalKey key) async {
      final ro = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = ro.toImageSync(pixelRatio: tester.view.devicePixelRatio);
      final b = await rgba(tester, img);
      img.dispose();
      return b;
    }

    Future<void> steg(WidgetTester tester, int n, int ms) async {
      for (var k = 0; k < n; k++) {
        // Real time for image decodes and shader loads, then one frame.
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
        await tester.pump(Duration(milliseconds: ms));
      }
    }

    Future<void> sjekk(WidgetTester tester, Widget host, {required int ms, required int for0, int etter = 8, bool delt = false}) async {
      BergenPerf.frysMs = 5432.1;
      BergenPerf.stegRammerPaa = false;
      BergenPerf.malerVertPaa = false;
      final key = GlobalKey();
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Align(alignment: Alignment.topLeft, child: RepaintBoundary(key: key, child: host)),
      ));
      await steg(tester, for0, ms);
      expect(find.byType(RawImage), findsOneWidget, reason: 'the host drew a frame the old way');
      final av = await skjerm(tester, key);
      BergenPerf.malerVertPaa = true;
      final r0 = malerDeltRammer;
      await steg(tester, etter, ms);
      expect(find.byType(RawImage), findsNothing);
      final vert = tester.widget<MalerVert>(find.byType(MalerVert));
      final bilde = vert.ramme.bilde;
      await steg(tester, 3, ms);
      expect(identical(tester.widget<MalerVert>(find.byType(MalerVert)), vert), isTrue, reason: 'no rebuild per frame');
      expect(identical(vert.ramme.bilde, bilde), isFalse, reason: 'new frames still arrive');
      if (delt) expect(malerDeltRammer, greaterThan(r0), reason: 'the split ran');
      final paa = await skjerm(tester, key);
      expect(diff(av, paa), (0, 0));
      await tester.pumpWidget(const SizedBox());
    }

    testWidgets('MegStadion', (tester) async {
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await sjekk(tester, const SizedBox(width: 390, height: 196, child: MegStadion(kind: BergenWeather.regn)), ms: 51, for0: 4);
    });

    testWidgets('SjoWater (Hjem hero water)', (tester) async {
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await sjekk(
        tester,
        const SizedBox(
          width: 390,
          height: 150,
          child: SjoWater(palette: SjoPalette.kveld, regn: .5, reflection: 'assets/images/bryggen/hjem_regn.jpg', reflectionHeight: 127, fogColor: Color(0xFF98A7AB)),
        ),
        ms: 17,
        for0: 6,
      );
    });

    // One test for all weathers: the host keeps its shader programs in
    // statics, and a test's futures die with its fake-async zone.
    testWidgets('AegilFloyen, every weather (bake + split)', (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final vaer in BergenWeather.values) {
        await sjekk(tester, AegilFloyen(key: ValueKey(vaer), kind: vaer, still: const SizedBox()), ms: 34, for0: 24, delt: true);
      }
    });

    testWidgets('SceneGl berg through SpGl (bake + split)', (tester) async {
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await sjekk(tester, const SceneGl(kind: SceneKind.berg, weather: BergenWeather.solnedgang, still: SizedBox()), ms: 31, for0: 6, delt: true);
    });
  });
}
