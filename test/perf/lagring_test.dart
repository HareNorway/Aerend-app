import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/kit/bergen_lagring.dart';
import 'package:aerend_customer/screens/bergen/kit/bergen_motion.dart';
import 'package:aerend_customer/screens/bergen/kit/bergen_perf.dart';
import 'package:aerend_customer/screens/common/auth/launch/lf_motion.dart';

/// Heat plan Steps 8–9: BergenLagring draws the screen's unchanged bottom run
/// from one image with the same pixels as live painting, keeps what moves
/// live and in order, never shows stale content, evicts covered screens;
/// loop repaint boundaries change no pixel.
void main() {
  const dpr = 2.625; // the Vivo V40
  const fys = Size(840, 1050); // 320 × 400 logical

  setUp(() {
    BergenPerf.lagringPaa = true;
    BergenPerf.loopGrensePaa = false;
    BergenLagring.debugUtenforRamme = true;
    BergenLagring.laget = 0;
    BergenLagring.treff = 0;
    BergenLagring.levende = 0;
    BergenLagring.tom();
  });
  tearDown(() {
    BergenPerf.lagringPaa = false;
    BergenPerf.lagringOvrePaa = false;
    BergenPerf.loopGrensePaa = false;
    BergenPerf.frysMs = null;
    BergenLagring.debugUtenforRamme = false;
    BergenLagring.tom();
  });

  final rot = GlobalKey();

  void skjerm(WidgetTester tester) {
    tester.view.devicePixelRatio = dpr;
    tester.view.physicalSize = fys;
    addTearDown(tester.view.reset);
  }

  /// The screen: a root boundary at the origin (a snapshot at the view's
  /// pixel ratio has the screen's device transform).
  Widget app(Widget innhold, {bool lagring = true}) => Directionality(
    textDirection: TextDirection.ltr,
    child: RepaintBoundary(key: rot, child: lagring ? BergenLagring(child: innhold) : innhold),
  );

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

  /// Frames, as a phone draws them while something else animates.
  Future<void> rammer(WidgetTester tester, int n) async {
    for (var i = 0; i < n; i++) {
      tester.binding.scheduleFrame();
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  // Gradients, text, blurred shadows, a group opacity over overlapping
  // content, a nested boundary, clips, a shader mask, an image filter and a
  // backdrop blur, at fractional positions.
  Widget statisk({Color kort = const Color(0xFFE95C2C), Widget? midt, Widget? over}) => Stack(
    children: [
      const Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2A6272), Color(0xFF173E48)])),
        ),
      ),
      Positioned(
        left: 13.3,
        top: 20.7,
        width: 180,
        height: 70,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: kort,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x8A04141C), blurRadius: 18, offset: Offset(0, 8))],
          ),
          child: const Center(child: Text('Ærend · Bergen', style: TextStyle(fontSize: 17, color: Colors.white, shadows: [Shadow(color: Color(0xCC000000), blurRadius: 6)]))),
        ),
      ),
      Positioned(
        left: 30.5,
        top: 110.2,
        child: Opacity(
          opacity: .55,
          child: SizedBox(
            width: 120,
            height: 60,
            child: Stack(children: [
              Container(width: 90, height: 50, decoration: BoxDecoration(color: const Color(0xFFF2C14E), borderRadius: BorderRadius.circular(12))),
              const Positioned(left: 40, top: 10, child: SizedBox(width: 70, height: 50, child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0xFF5CE0B8), Color(0x005CE0B8)]))))),
            ]),
          ),
        ),
      ),
      Positioned(
        left: 170.25,
        top: 104.6,
        child: RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (r) => const LinearGradient(colors: [Color(0x00000000), Color(0xFF000000)]).createShader(r),
              child: Container(width: 120, height: 64, color: const Color(0xFF9C7BE8), child: const Center(child: Text('Søk', style: TextStyle(fontSize: 20)))),
            ),
          ),
        ),
      ),
      Positioned(
        left: 20.1,
        top: 190.3,
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(width: 80, height: 40, color: const Color(0xFFFF9466)),
        ),
      ),
      ?midt,
      Positioned(
        left: 120.4,
        top: 180.9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(width: 150, height: 70, color: const Color(0x33FFFFFF), child: const Center(child: Text('glass', style: TextStyle(fontSize: 15)))),
          ),
        ),
      ),
      ?over,
    ],
  );

  testWidgets('static screen: one image, same pixels as live (max 0)', (tester) async {
    skjerm(tester);
    await tester.pumpWidget(app(statisk(), lagring: false));
    final live = await skudd(tester);
    await tester.pumpWidget(app(statisk()));
    await rammer(tester, 10);
    expect(BergenLagring.laget, 1, reason: 'the whole screen is one run');
    expect(BergenLagring.bilder, 1);
    expect(BergenLagring.bytes, 840 * 1050 * 4, reason: 'one screen-sized image');
    final treff = BergenLagring.treff;
    final bakt = await skudd(tester);
    expect(BergenLagring.treff, treff + 1, reason: 'the snapshot drew the image');
    expect(maks(live, bakt), 0);
  });

  testWidgets('a content change inside the cached run shows in that very frame', (tester) async {
    skjerm(tester);
    await tester.pumpWidget(app(statisk(kort: const Color(0xFF1E8F72)), lagring: false));
    final ny = await skudd(tester);
    await tester.pumpWidget(app(statisk()));
    await rammer(tester, 10);
    expect(BergenLagring.laget, 1);
    final levende = BergenLagring.levende;
    // One frame: the card repaints; the image is stale and must not be used.
    await tester.pumpWidget(app(statisk(kort: const Color(0xFF1E8F72))));
    expect(BergenLagring.levende, levende + 1, reason: 'that frame was drawn live');
    expect(maks(ny, await skudd(tester)), 0);
    // Thrown away soon after it was made: it waits for a longer hold.
    await rammer(tester, 20);
    expect(BergenLagring.laget, 2, reason: 'rastered again once it held');
    expect(maks(ny, await skudd(tester)), 0);
  });

  testWidgets('a live animated layer between static runs: bottom run cached, the rest live and in order', (tester) async {
    skjerm(tester);
    final tikk = ValueNotifier<int>(0);
    addTearDown(tikk.dispose);
    // A layer that repaints every frame, painted between the static layers,
    // overlapped by the glass card above it.
    Widget levende() => Positioned(
      left: 140.6,
      top: 150.3,
      child: RepaintBoundary(
        child: CustomPaint(size: const Size(90, 60), painter: _Tikk(tikk)),
      ),
    );
    tikk.value = 7;
    await tester.pumpWidget(app(statisk(midt: levende()), lagring: false));
    final live = await skudd(tester);
    await tester.pumpWidget(app(statisk(midt: levende())));
    for (var i = 0; i < 12; i++) {
      tikk.value = i;
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(BergenLagring.laget, 1, reason: 'the run below the live layer');
    tikk.value = 7;
    await tester.pump(const Duration(milliseconds: 16));
    final treff = BergenLagring.treff;
    final bakt = await skudd(tester);
    expect(BergenLagring.treff, treff + 1);
    expect(maks(live, bakt), 0);
  });

  testWidgets('moved by a parent without a repaint (scroll): live while moving, rastered again when settled', (tester) async {
    skjerm(tester);
    Widget flytt(double dy) => Stack(children: [
      const Positioned.fill(child: ColoredBox(color: Color(0xFF173E48))),
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        height: 300,
        child: Transform.translate(
          offset: Offset(0, dy),
          child: RepaintBoundary(child: statisk()),
        ),
      ),
    ]);
    await tester.pumpWidget(app(flytt(0)));
    await rammer(tester, 10);
    expect(BergenLagring.laget, 1);
    for (var i = 1; i <= 6; i++) {
      await tester.pumpWidget(app(flytt(-3.37 * i)));
    }
    expect(BergenLagring.laget, 1, reason: 'no image while it moves');
    final bevegd = await skudd(tester);
    await rammer(tester, 20);
    expect(BergenLagring.laget, 2, reason: 'settled: rastered at the new offset');
    final bakt = await skudd(tester);
    await tester.pumpWidget(app(flytt(-3.37 * 6), lagring: false));
    final live = await skudd(tester);
    expect(maks(live, bevegd), 0);
    expect(maks(live, bakt), 0);
  });

  testWidgets('a covered route drops its image; memory stays within ~2 screens', (tester) async {
    skjerm(tester);
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(320, 400), devicePixelRatio: dpr),
        child: Navigator(
          key: nav,
          onGenerateRoute: (s) => PageRouteBuilder<void>(pageBuilder: (c, a, b) => BergenLagring(child: statisk())),
        ),
      ),
    ));
    await rammer(tester, 10);
    expect(BergenLagring.bilder, 1);
    nav.currentState!.push(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (c, a, b) => BergenLagring(child: statisk(kort: const Color(0xFF1E8F72))),
    ));
    await rammer(tester, 20);
    expect(BergenLagring.bilder, 1, reason: 'the covered screen is evicted, the new one cached');
    expect(BergenLagring.bytes, lessThanOrEqualTo(2 * 840 * 1050 * 4));
    nav.currentState!.pop();
    await rammer(tester, 20);
    expect(BergenLagring.bilder, 1);
    await tester.pumpWidget(const SizedBox());
    await rammer(tester, 3);
    expect(BergenLagring.bilder, 0);
    expect(BergenLagring.bytes, 0);
  });

  testWidgets('without the test hook: rastered in real frames; a toImage outside the screen scene stays live', (tester) async {
    skjerm(tester);
    BergenLagring.debugUtenforRamme = false;
    await tester.pumpWidget(app(statisk(), lagring: false));
    final live = await skudd(tester);
    await tester.pumpWidget(app(statisk()));
    await rammer(tester, 10);
    expect(BergenLagring.laget, 1, reason: 'the screen scene is recognised');
    final treff = BergenLagring.treff;
    final skutt = await skudd(tester);
    expect(BergenLagring.treff, treff, reason: 'a snapshot scene is drawn live');
    expect(maks(live, skutt), 0);
    await rammer(tester, 2);
    expect(BergenLagring.treff, greaterThan(treff), reason: 'the screen keeps the image');
  });

  testWidgets('something painted beneath the root, or the switch off: no image', (tester) async {
    skjerm(tester);
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(children: [
        const Positioned.fill(child: ColoredBox(color: Color(0xFF000000))),
        Positioned.fill(child: BergenLagring(child: statisk())),
      ]),
    ));
    await rammer(tester, 10);
    expect(BergenLagring.laget, 0);
    BergenPerf.lagringPaa = false;
    await tester.pumpWidget(app(statisk()));
    await rammer(tester, 10);
    expect(BergenLagring.laget, 0);
    expect(BergenLagring.bilder, 0);
  });

  // ── Step 8, `lagringOvre`: the runs above a live layer ──

  group('lagringOvre (upper runs: opaque pixels identical, translucent ≤ 2/255)', () {
    late ValueNotifier<int> tikk;
    setUp(() {
      BergenPerf.lagringOvrePaa = true;
      tikk = ValueNotifier<int>(0);
    });
    tearDown(() => tikk.dispose());

    // What is painted above the live layer: a translucent glass card with a
    // blurred shadow over it, text with a shadow, a gradient pill, an opaque
    // card; [dodge]: a colour-dodge sheen drawn straight onto the canvas.
    List<Widget> ovre({Color kort = const Color(0xFF1E8F72), bool dodge = false, bool merk = false}) => [
      Positioned(
        left: 120.3,
        top: 140.6,
        width: 150,
        height: 80,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0x52FFFFFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x66FFFFFF)),
            boxShadow: const [BoxShadow(color: Color(0x6604141C), blurRadius: 20, offset: Offset(0, 10))],
          ),
          child: const Center(child: Text('Hurtig', style: TextStyle(fontSize: 18, color: Colors.white, shadows: [Shadow(color: Color(0x99000000), blurRadius: 4)]))),
        ),
      ),
      Positioned(
        left: 40.7,
        top: 250.2,
        width: 200,
        height: 36,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xCCF2C14E), Color(0x33E95C2C)]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Center(child: Text('Bestill igjen', style: TextStyle(fontSize: 14, color: Color(0xFF173E48)))),
        ),
      ),
      Positioned(left: 200.5, top: 300.5, width: 90, height: 60, child: DecoratedBox(decoration: BoxDecoration(color: kort, borderRadius: BorderRadius.circular(12)))),
      if (dodge)
        Positioned(
          left: 100.2,
          top: 120.4,
          width: 180,
          height: 140,
          child: merk ? BergenLagringLive(child: CustomPaint(painter: _Dodge())) : CustomPaint(painter: _Dodge()),
        ),
    ];

    Widget levende() => Positioned(
      left: 110.6,
      top: 150.3,
      child: RepaintBoundary(child: CustomPaint(size: const Size(120, 70), painter: _Tikk(tikk))),
    );

    Widget skjermen({Color kort = const Color(0xFF1E8F72), bool dodge = false, bool merk = false}) => Stack(children: [
      const Positioned.fill(
        child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2A6272), Color(0xFF173E48)]))),
      ),
      Positioned(left: 13.3, top: 20.7, width: 180, height: 70, child: DecoratedBox(decoration: BoxDecoration(color: const Color(0xFFE95C2C), borderRadius: BorderRadius.circular(16)))),
      levende(),
      ...ovre(kort: kort, dodge: dodge, merk: merk),
    ]);

    Future<void> kjor(WidgetTester tester, int n) async {
      for (var i = 0; i < n; i++) {
        tikk.value = i % 9;
        await tester.pump(const Duration(milliseconds: 16));
      }
      tikk.value = 7;
      await tester.pump(const Duration(milliseconds: 16));
    }

    /// Max difference, and max over the pixels the upper run covers opaquely.
    Future<(int, int, int)> sammenlign(WidgetTester tester, Uint8List a, Uint8List b, {Color kort = const Color(0xFF1E8F72)}) async {
      await tester.pumpWidget(app(Stack(children: ovre(kort: kort)), lagring: false));
      final maske = await skudd(tester);
      var alle = 0, tette = 0, ulike = 0;
      final hist = List<int>.filled(256, 0);
      final lagHist = <int, int>{};
      for (var px = 0; px < a.length; px += 4) {
        var dp = 0;
        for (var c = 0; c < 4; c++) {
          final d = (a[px + c] - b[px + c]).abs();
          if (d > alle) alle = d;
          if (maske[px + 3] == 255 && d > tette) tette = d;
          if (d > 0) ulike++;
          if (d > dp) dp = d;
        }
        hist[dp]++;
        if (dp >= 2) lagHist[maske[px + 3]] = (lagHist[maske[px + 3]] ?? 0) + 1;
      }
      // ignore: avoid_print
      print('LAGRING_OVRE pixels by max channel diff: 0=${hist[0]} 1=${hist[1]} 2=${hist[2]} 3+=${hist.skip(3).fold<int>(0, (x, y) => x + y)}; diff-2 pixels by the run\'s own alpha: $lagHist');
      return (alle, tette, ulike);
    }

    testWidgets('bottom run + the run above the live layer: two images, opaque pixels identical, translucent ≤ 2/255', (tester) async {
      skjerm(tester);
      tikk.value = 7;
      await tester.pumpWidget(app(skjermen(), lagring: false));
      final live = await skudd(tester);
      await tester.pumpWidget(app(skjermen()));
      await kjor(tester, 14);
      expect(BergenLagring.laget, 2, reason: 'the bottom run and the upper run');
      expect(BergenLagring.bilder, 1, reason: 'one screen holds them');
      expect(BergenLagring.bytes, 2 * 840 * 1050 * 4, reason: 'two screen-sized images, the budget');
      final treff = BergenLagring.treff;
      final bakt = await skudd(tester);
      expect(BergenLagring.treff, treff + 1);
      final (alle, tette, ulike) = await sammenlign(tester, live, bakt);
      // ignore: avoid_print
      print('LAGRING_OVRE max=$alle opaque-max=$tette channels≠: $ulike');
      // Each translucent draw of the run is rounded onto its own 8-bit
      // image, then the image once more onto the screen: 1/255 for one
      // translucent layer, 2/255 where several stack (glass + border + shadow
      // + text: 171 of 882 000 pixels here; 39 569 at 1/255).
      expect(alle, lessThanOrEqualTo(2));
      expect(tette, 0);
    });

    testWidgets('a content change in the upper run shows in that very frame', (tester) async {
      skjerm(tester);
      tikk.value = 7;
      await tester.pumpWidget(app(skjermen(kort: const Color(0xFF9C7BE8)), lagring: false));
      final ny = await skudd(tester);
      await tester.pumpWidget(app(skjermen()));
      await kjor(tester, 14);
      expect(BergenLagring.laget, 2);
      // One frame: the opaque card in the upper run repaints.
      await tester.pumpWidget(app(skjermen(kort: const Color(0xFF9C7BE8))));
      final bakt = await skudd(tester);
      final (alle, tette, _) = await sammenlign(tester, ny, bakt, kort: const Color(0xFF9C7BE8));
      expect(alle, lessThanOrEqualTo(2));
      expect(tette, 0, reason: 'the new colour, not the stale image');
    });

    testWidgets('a colour dodge marked BergenLagringLive: nothing beneath it from an upper image (max 0)', (tester) async {
      skjerm(tester);
      tikk.value = 7;
      await tester.pumpWidget(app(skjermen(dodge: true, merk: true), lagring: false));
      final live = await skudd(tester);
      await tester.pumpWidget(app(skjermen(dodge: true, merk: true)));
      await kjor(tester, 14);
      expect(BergenLagring.laget, 1, reason: 'only the exact bottom run');
      final bakt = await skudd(tester);
      expect(maks(live, bakt), 0);
      // Unmarked, the dodge would sit in an upper image drawn on transparent.
      await tester.pumpWidget(const SizedBox());
      BergenLagring.laget = 0;
      await tester.pumpWidget(app(skjermen(dodge: true), lagring: false));
      final live2 = await skudd(tester);
      await tester.pumpWidget(app(skjermen(dodge: true)));
      await kjor(tester, 14);
      final feil = maks(live2, await skudd(tester));
      // ignore: avoid_print
      print('LAGRING_OVRE unmarked colour dodge in an upper image: max $feil (why it is marked)');
      expect(BergenLagring.laget, 2);
      expect(feil, greaterThan(1));
    });

    testWidgets('lagringOvre off: only the bottom run, as before', (tester) async {
      skjerm(tester);
      BergenPerf.lagringOvrePaa = false;
      tikk.value = 7;
      await tester.pumpWidget(app(skjermen(), lagring: false));
      final live = await skudd(tester);
      await tester.pumpWidget(app(skjermen()));
      await kjor(tester, 14);
      expect(BergenLagring.laget, 1);
      expect(maks(live, await skudd(tester)), 0);
    });
  });

  // ── Step 9: loop repaint boundaries ──

  testWidgets('loopGrense: the same pixels with and without the loop boundaries', (tester) async {
    skjerm(tester);
    BergenPerf.lagringPaa = false;
    BergenPerf.frysMs = 1234;
    Widget prikk() => Container(
      width: 14,
      height: 14,
      decoration: const BoxDecoration(color: Color(0xFF5CE0B8), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0xFF5CE0B8), blurRadius: 8)]),
    );
    Widget lf() => LfLoop(
      builder: (context, t, child) => Opacity(opacity: .4 + .5 * ((t % 1800) / 1800), child: Transform.scale(scale: 1 + .3 * ((t % 900) / 900), child: child)),
      child: prikk(),
    );
    Widget bl() => BergenLoop(
      durationMs: 2400,
      builder: (context, p, child) => Transform.translate(offset: Offset(0, -3.3 * (p ?? 0)), child: child),
      child: prikk(),
    );
    Widget innhold() => Stack(children: [
      const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF2A6272), Color(0xFF173E48)])))),
      Positioned(left: 20.3, top: 30.6, child: Row(children: [const Text('Ærend', style: TextStyle(fontSize: 16)), lf(), bl()])),
      // Under a group opacity: side by side (the engine may fold the
      // opacity into each draw) and overlapping (an offscreen layer).
      Positioned(left: 20.3, top: 90.6, child: Opacity(opacity: .5, child: Row(children: [const Text('side', style: TextStyle(fontSize: 16)), const SizedBox(width: 8), bl()]))),
      Positioned(
        left: 20.3,
        top: 150.6,
        child: Opacity(
          opacity: .5,
          child: Stack(clipBehavior: Clip.none, children: [Container(width: 60, height: 30, color: const Color(0xFFF2C14E)), Positioned(left: 40, top: 6, child: lf())]),
        ),
      ),
      Positioned(left: 120.7, top: 200.2, child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Container(width: 80, height: 50, color: const Color(0xFF1E4F5C), child: Center(child: bl())))),
    ]);
    await tester.pumpWidget(app(innhold(), lagring: false));
    await tester.pump(const Duration(milliseconds: 16));
    final av = await skudd(tester);
    BergenPerf.loopGrensePaa = true;
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(innhold(), lagring: false));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byType(RepaintBoundary), findsAtLeastNWidgets(6), reason: 'the loops have their boundaries');
    final paa = await skudd(tester);
    final d = maks(av, paa);
    // ignore: avoid_print
    print('LOOPGRENSE max |on − off| = $d');
    expect(d, 0);
    await tester.pumpWidget(const SizedBox());
  });
}

class _Tikk extends CustomPainter {
  _Tikk(this.n) : super(repaint: n);
  final ValueNotifier<int> n;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      Paint()..color = Color.fromARGB(255, 40 + 15 * n.value, 120, 200),
    );
    canvas.drawCircle(Offset(10 + 5.5 * n.value, size.height / 2), 8, Paint()..color = const Color(0xCCFFFFFF));
  }

  @override
  bool shouldRepaint(_Tikk old) => true;
}

/// A colour-dodge sheen straight onto the canvas (as BergenHolo draws it).
class _Dodge extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..blendMode = BlendMode.colorDodge
        ..shader = const LinearGradient(colors: [Color(0x00FFFFFF), Color(0x99FFE0A0), Color(0x00FFFFFF)]).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_Dodge old) => false;
}
