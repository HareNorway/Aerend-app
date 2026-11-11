import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/hjem/hjem_hjul.dart';
import 'package:aerend_customer/screens/common/auth/launch/lf_css.dart';
import 'package:aerend_customer/screens/common/auth/launch/lf_widgets.dart' show LfPress;
import 'package:aerend_customer/ui/kit/kglatt.dart';

import '../layout/reduced_motion_harness.dart';

/// Kunde Glatt Step 1 (D1, D2): the Hjem wheel turns with the finger, the
/// arrows bring the orb on their side to the front, and an orb passing the
/// front while dragging or gliding gives one detent tick.
void main() {
  setUpAll(() => bootstrapGlobals(locale: 'no'));

  const kat = [
    HjemHjulKat(navn: 'Restaurant', live: '24 åpne nå', ikon: 0, snart: false),
    HjemHjulKat(navn: 'Mat & fisk', live: 'Kommer snart', ikon: 1, snart: true),
    HjemHjulKat(navn: 'Mote', live: 'Kommer snart', ikon: 2, snart: true),
    HjemHjulKat(navn: 'Interiør', live: 'Kommer snart', ikon: 3, snart: true),
    HjemHjulKat(navn: 'Gaver', live: 'Kommer snart', ikon: 4, snart: true),
  ];

  late List<String> kanal, system;

  setUp(() {
    KGlatt.nullstill();
    kanal = [];
    system = [];
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('aerend/haptic'), (c) async {
      kanal.add('${c.arguments}');
      return true;
    });
    m.setMockMethodCallHandler(SystemChannels.platform, (c) async {
      if (c.method == 'HapticFeedback.vibrate') system.add('${c.arguments}');
      return null;
    });
  });

  tearDown(KGlatt.nullstill);

  late int index;

  /// The glide starts on the frame after the index changes; then 800 ms.
  Future<void> ro(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
  }

  Future<void> pump(WidgetTester tester, {bool rolig = false}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    index = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: rolig, size: const Size(390, 844), textScaler: const TextScaler.linear(.5)),
          child: app!,
        ),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, set) => lfFlow(
              390,
              HjemKategoriHjul(kategorier: kat, index: index, onIndex: (k) => set(() => index = k), onOpen: (_) {}, onSnart: (_) {}),
            ),
          ),
        ),
      ),
    );
    await ro(tester);
  }

  double x(WidgetTester tester, int ikon) => tester.getCenter(find.byWidgetPredicate((w) => w is HjemKatIkon && w.ikon == ikon)).dx;

  /// Drags start on the front orb, as a finger does (the wheel takes a drag
  /// that starts on what it draws: an orb or the ring on the floor).
  Offset start(WidgetTester tester) => tester.getCenter(find.byWidgetPredicate((w) => w is HjemKatIkon && w.ikon == index));

  /// A slow horizontal drag of [dx] px in 10 px moves, then held still so the
  /// release velocity is ~0 (the wheel's velocity is measured on a real clock).
  Future<TestGesture> dra(WidgetTester tester, double dx, {bool slipp = true}) async {
    final g = await tester.startGesture(start(tester));
    final n = (dx.abs() / 10).round();
    for (var i = 0; i < n; i++) {
      await g.moveBy(Offset(dx.sign * 10, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    for (var i = 0; i < 20; i++) {
      await g.moveBy(Offset.zero);
    }
    await tester.pump(const Duration(milliseconds: 16));
    if (slipp) {
      await g.up();
      await ro(tester);
    }
    return g;
  }

  testWidgets('drag right: the front orb moves right with the finger, the left orb comes to the front', (tester) async {
    await pump(tester);
    final x0 = x(tester, 0);
    expect(x(tester, 1), lessThan(x0), reason: 'Mat & fisk (index 1) stands on the left of the front');
    final g = await dra(tester, 60, slipp: false);
    expect(x(tester, 0), greaterThan(x0 + 20), reason: 'the front orb follows the finger to the right');
    await g.up();
    await ro(tester);
    expect(index, 1, reason: 'the orb that was on the left is now in front');
    expect((x(tester, 1) - x0).abs(), lessThan(2), reason: 'and it settled at the front');
    // One detent tick (the orb passed the front), no extra tick at release.
    expect(kanal, ['tick']);
    expect(system, isEmpty);
  });

  testWidgets('drag left: the right orb comes to the front', (tester) async {
    await pump(tester);
    final x0 = x(tester, 0);
    final g = await dra(tester, -60, slipp: false);
    expect(x(tester, 0), lessThan(x0 - 20));
    await g.up();
    await ro(tester);
    expect(index, 4);
    expect(kanal, ['tick']);
  });

  testWidgets('a long slow drag across two orbs: two detent ticks, lands two on', (tester) async {
    await pump(tester);
    await dra(tester, 160);
    expect(index, 2);
    expect(kanal, ['tick', 'tick']);
    expect(system, isEmpty);
  });

  testWidgets('a fling goes at most two orbs, one tick per orb passed', (tester) async {
    await pump(tester);
    final g = await tester.startGesture(start(tester));
    for (var i = 0; i < 8; i++) {
      await g.moveBy(const Offset(10, 0));
    }
    await g.up();
    await ro(tester);
    expect(index, 2);
    expect(kanal, ['tick', 'tick']);
  });

  testWidgets('a short drag (> 26 px) still moves one orb in the finger\'s direction', (tester) async {
    await pump(tester);
    await dra(tester, 30);
    expect(index, 1);
    expect(kanal, ['tick'], reason: 'the detent ticks when the glide brings the orb past the front');
  });

  testWidgets('arrows: ‹ brings the left orb, › the right orb; one tick each, no detent on top', (tester) async {
    await pump(tester);
    final pil = find.byType(LfPress);
    await tester.tap(pil.first);
    await ro(tester);
    expect(index, 1, reason: '‹ brings Mat & fisk, which stood on the left');
    expect(system, ['HapticFeedbackType.selectionClick']);
    expect(kanal, isEmpty);
    await tester.tap(pil.last);
    await ro(tester);
    expect(index, 0, reason: '› brings back Restaurant, which stood on the right');
    await tester.tap(pil.last);
    await ro(tester);
    expect(index, 4);
    expect(system.length, 3);
    expect(kanal, isEmpty);
  });

  testWidgets('Reduce Motion: a drag still lands on the left orb and snaps to it', (tester) async {
    await pump(tester, rolig: true);
    final x0 = x(tester, 0);
    await dra(tester, 60);
    expect(index, 1);
    expect((x(tester, 1) - x0).abs(), lessThan(2));
    expect(kanal, ['tick']);
  });

  testWidgets('kglattHjul: false — the old wheel (against the finger, old arrows, tick on release, no detents)', (tester) async {
    KGlatt.sett({'kglattHjul': false});
    await pump(tester);
    final x0 = x(tester, 0);
    final g = await dra(tester, 60, slipp: false);
    expect(x(tester, 0), lessThan(x0 - 20), reason: 'old: the front orb moves against the finger');
    await g.up();
    await ro(tester);
    expect(index, 4);
    expect(kanal, isEmpty);
    expect(system, ['HapticFeedbackType.selectionClick']);
    await tester.tap(find.byType(LfPress).first);
    await ro(tester);
    expect(index, 3, reason: 'old: ‹ = index − 1');
  });
}
