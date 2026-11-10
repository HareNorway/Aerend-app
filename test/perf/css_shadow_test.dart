import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/kit/bergen_css_shadow.dart';
import 'package:aerend_customer/screens/bergen/kit/bergen_perf.dart';
import 'package:aerend_customer/screens/common/auth/launch/lf_css.dart';

/// Heat Step 7 (`pass2Klipp`): BergenCssShadow and CssBox clip their outer
/// shadows to the outside of the box with an outer edge only as far as the
/// shadows reach, instead of 600 / 400 px around it — the same pixels.
void main() {
  tearDown(() {
    BergenPerf.pass2KlippPaa = true;
    CssBake.paa = true;
    CssBake.tom();
  });

  testWidgets('the tight clip draws the same pixels as the 600 px one', (tester) async {
    const dpr = 2.625;
    tester.view.devicePixelRatio = dpr;
    tester.view.physicalSize = const Size(1080, 1080);
    addTearDown(tester.view.reset);
    final rot = GlobalKey();
    Widget skjerm(Offset at, double radius, List<BoxShadow> skygger) => Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: rot,
        child: ColoredBox(
          color: const Color(0xFF2A6272),
          child: Align(
            alignment: Alignment.topLeft,
            child: Transform.translate(
              offset: at,
              child: BergenCssShadow(
                radius: radius,
                shadows: skygger,
                child: const SizedBox(width: 150, height: 56, child: ColoredBox(color: Color(0x33FFFFFF))),
              ),
            ),
          ),
        ),
      ),
    );
    Future<Uint8List> skudd() async {
      final ro = rot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = ro.toImageSync(pixelRatio: dpr);
      final data = await tester.runAsync(() => img.toByteData(format: ui.ImageByteFormat.rawRgba));
      img.dispose();
      return data!.buffer.asUint8List();
    }

    const sett = [
      [BoxShadow(color: Color(0x5904141C), blurRadius: 24, offset: Offset(0, 12))],
      [BoxShadow(color: Color(0x40000000), blurRadius: 40, spreadRadius: 4, offset: Offset(-6, 18)), BoxShadow(color: Color(0x26FFFFFF), blurRadius: 2, offset: Offset(0, -1))],
      [BoxShadow(color: Color(0x80000000), offset: Offset(3, 3))],
    ];
    for (final at in const [Offset(90.3, 120.77), Offset(140, 200.5)]) {
      for (final (i, sk) in sett.indexed) {
        for (final radius in const [16.0, 999.0]) {
          BergenPerf.pass2KlippPaa = false;
          await tester.pumpWidget(skjerm(at, radius, sk));
          final foer = await skudd();
          BergenPerf.pass2KlippPaa = true;
          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(skjerm(at, radius, sk));
          final naa = await skudd();
          var maks = 0;
          for (var k = 0; k < foer.length; k++) {
            final d = (foer[k] - naa[k]).abs();
            if (d > maks) maks = d;
          }
          expect(maks, 0, reason: 'at $at, shadows #$i, radius $radius');
          await tester.pumpWidget(const SizedBox());
        }
      }
    }
  });

  testWidgets('CssBox: the tight clip draws the same pixels as the 400 px one (live and from CssBake)', (tester) async {
    const dpr = 2.625;
    tester.view.devicePixelRatio = dpr;
    tester.view.physicalSize = const Size(1080, 1080);
    addTearDown(tester.view.reset);
    final rot = GlobalKey();
    Widget skjerm(Offset at, BorderRadius radius, List<CssShadow> skygger, Border? kant) => Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: rot,
        child: ColoredBox(
          color: const Color(0xFF2A6272),
          child: Align(
            alignment: Alignment.topLeft,
            child: Transform.translate(
              offset: at,
              // Translucent backgrounds: the outer shadows take the clip path.
              child: CssBox(
                width: 150,
                height: 56,
                radius: radius,
                bg: const [CssLinear(180, [Color(0x40FFFFFF), Color(0x14FFFFFF)])],
                shadows: skygger,
                border: kant,
              ),
            ),
          ),
        ),
      ),
    );
    Future<Uint8List> skudd() async {
      final ro = rot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = ro.toImageSync(pixelRatio: dpr);
      final data = await tester.runAsync(() => img.toByteData(format: ui.ImageByteFormat.rawRgba));
      img.dispose();
      return data!.buffer.asUint8List();
    }

    const sett = <List<CssShadow>>[
      // outer blurred, offset
      [CssShadow(0, 14, 30, 0, Color.fromRGBO(4, 20, 28, .4))],
      // outer with positive and negative spread, sideways offsets
      [CssShadow(-8, 18, 40, 6, Color.fromRGBO(0, 0, 0, .3)), CssShadow(6, 4, 10, -4, Color.fromRGBO(255, 160, 90, .45))],
      // sharp (blur 0) outer + spread ring
      [CssShadow(3, 3, 0, 0, Color.fromRGBO(0, 0, 0, .5)), CssShadow(0, 0, 0, 2, Color.fromRGBO(92, 224, 184, .6))],
      // outer + inset (blurred and sharp), as the glass buttons use
      [
        CssShadow(0, 12, 18, -12, Color.fromRGBO(233, 92, 44, .6)),
        CssShadow.inset(0, 1.5, 0, 0, Color(0x80FFFFFF)),
        CssShadow.inset(0, -3, 8, 0, Color.fromRGBO(0, 0, 0, .25)),
        CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .12)),
      ],
    ];
    final radii = [
      BorderRadius.circular(16),
      BorderRadius.circular(999),
      const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomRight: Radius.circular(20), bottomLeft: Radius.circular(6)),
      BorderRadius.zero,
    ];
    var n = 0;
    for (final cache in [false, true]) {
      CssBake.paa = cache;
      for (final at in const [Offset(120.3, 140.77), Offset(200, 260.5)]) {
        for (final (i, sk) in sett.indexed) {
          for (final (j, radius) in radii.indexed) {
            final kant = j.isEven ? Border.all(color: const Color(0x66FFFFFF)) : null;
            BergenPerf.pass2KlippPaa = false;
            CssBake.tom();
            await tester.pumpWidget(skjerm(at, radius, sk, kant));
            final foer = await skudd();
            BergenPerf.pass2KlippPaa = true;
            CssBake.tom();
            await tester.pumpWidget(const SizedBox());
            await tester.pumpWidget(skjerm(at, radius, sk, kant));
            final naa = await skudd();
            var maks = 0;
            for (var k = 0; k < foer.length; k++) {
              final d = (foer[k] - naa[k]).abs();
              if (d > maks) maks = d;
            }
            expect(maks, 0, reason: 'cache $cache, at $at, shadows #$i, radius #$j');
            await tester.pumpWidget(const SizedBox());
            n++;
          }
        }
      }
    }
    expect(n, 64);
  });
}
