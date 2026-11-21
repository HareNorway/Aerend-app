import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/kit/ae_mynt.dart';
import 'package:aerend_customer/screens/bergen/kit/ae_primitiver.dart';
import 'package:aerend_customer/theme/lys/modus_scope.dart';

import '../a3/a3_fakes.dart';

SemanticsData _sem(WidgetTester t, Finder f) => t.getSemantics(f).getSemanticsData();

/// Design 21 Nov plan Step 1: the shared primitives — the coin and the medal, the CTA pill, the radio card, the tab
/// pill, the collapsible panel and the typing guard — in both colour modes.

Widget _app(Widget child, {bool lys = false}) => MaterialApp(
      home: BergenModusScope(lys: lys, child: Scaffold(backgroundColor: const Color(0xFF1E4F5C), body: Center(child: Padding(padding: const EdgeInsets.all(16), child: child)))),
    );

void main() {
  setUp(() async => a3Bootstrap());

  testWidgets('the coin and the medals build at every size, in both modes', (tester) async {
    for (final lys in [false, true]) {
      await tester.pumpWidget(_app(
        const Column(children: [
          AeMynt(size: 128, glow: true),
          AeMynt(size: 16, flip: false, mark: false),
          AeMedalje(name: 'Gull', size: 104, ring: 3),
          AeMedalje(name: 'Sølv', size: 42),
          AeMedalje(name: 'Bronse', size: 12, mark: false),
          AeMedalje(name: 'Platina', size: 24, child: Text('1')),
        ]),
        lys: lys,
      ));
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.byType(AeMynt), findsNWidgets(2));
      expect(find.byType(AeMedalje), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('the CTA pill is 56 px, taps, and sinks while disabled', (tester) async {
    var n = 0;
    await tester.pumpWidget(_app(AeKnappPille(label: 'Gå til kassen · 347 kr', onPressed: () => n++)));
    await tester.tap(find.text('Gå til kassen · 347 kr'));
    await tester.pump();
    expect(n, 1);
    final box = tester.getSize(find.byType(AeKnappPille));
    expect(box.height, closeTo(56 * (tester.view.physicalSize.width / tester.view.devicePixelRatio) / 390, 1));
    await tester.pumpWidget(_app(const AeKnappPille(label: 'Vent', onPressed: null)));
    final d = _sem(tester, find.byType(AeKnappPille));
    expect(d.label, contains('Vent'));
    expect(d.hasFlag(SemanticsFlag.isButton), isTrue);
    expect(d.hasFlag(SemanticsFlag.isEnabled), isFalse);
  });

  testWidgets('radio cards: one selected, each a radio in a group, taps choose', (tester) async {
    var valgt = 1;
    await tester.pumpWidget(_app(StatefulBuilder(
      builder: (context, set) => Column(children: [
        for (var i = 0; i < 3; i++)
          AeRadioKort(valgt: valgt == i, onTap: () => set(() => valgt = i), tittel: 'Valg $i', under: 'Under $i', ikon: const Icon(Icons.schedule)),
      ]),
    )));
    final d1 = _sem(tester, find.text('Valg 1')), d0 = _sem(tester, find.text('Valg 0'));
    expect([d1.hasFlag(SemanticsFlag.isChecked), d1.hasFlag(SemanticsFlag.isInMutuallyExclusiveGroup), d1.hasFlag(SemanticsFlag.isButton), d1.hasAction(SemanticsAction.tap)], [true, true, true, true]);
    expect(d1.label, contains('Valg 1'));
    expect(d0.hasFlag(SemanticsFlag.isChecked), isFalse);
    await tester.tap(find.text('Valg 2'));
    await tester.pumpAndSettle();
    expect(valgt, 2);
    expect(tester.getSize(find.byType(AeRadioKort).first).height, greaterThanOrEqualTo(60));
  });

  testWidgets('the tab pill switches and announces the chosen tab', (tester) async {
    var v = 0;
    await tester.pumpWidget(_app(StatefulBuilder(
      builder: (context, set) => AeFanePille(
        faner: const [AeFane(label: 'Levering', icon: Icons.local_shipping_outlined), AeFane(label: 'Henting', icon: Icons.shopping_bag_outlined)],
        valgt: v,
        onValg: (i) => set(() => v = i),
      ),
    )));
    await tester.tap(find.text('Henting'));
    await tester.pumpAndSettle();
    expect(v, 1);
    final dh = _sem(tester, find.text('Henting')), dl = _sem(tester, find.text('Levering'));
    expect([dh.hasFlag(SemanticsFlag.isSelected), dh.hasFlag(SemanticsFlag.isButton), dh.hasAction(SemanticsAction.tap)], [true, true, true]);
    expect(dh.label, contains('Henting'));
    expect(dl.hasFlag(SemanticsFlag.isSelected), isFalse);
  });

  testWidgets('the collapsible panel takes no height closed and opens in 360 ms', (tester) async {
    var open = false;
    await tester.pumpWidget(_app(StatefulBuilder(
      builder: (context, set) => Column(children: [
        TextButton(onPressed: () => set(() => open = !open), child: const Text('Toggle')),
        AeKollaps(aapen: open, child: const SizedBox(height: 120, child: Text('Panel'))),
      ]),
    )));
    expect(tester.getSize(find.byType(AeKollaps)).height, 0);
    await tester.tap(find.text('Toggle'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    final mid = tester.getSize(find.byType(AeKollaps)).height;
    expect(mid, greaterThan(0));
    expect(mid, lessThan(120));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.getSize(find.byType(AeKollaps)).height, closeTo(120, .5));
  });

  testWidgets('aeSkriver is true only while a text field has focus', (tester) async {
    final node = FocusNode();
    await tester.pumpWidget(_app(TextField(focusNode: node)));
    expect(aeSkriver(), isFalse);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(node.hasFocus, isTrue);
    expect(aeSkriver(), isTrue);
    node.unfocus();
    await tester.pump();
    expect(aeSkriver(), isFalse);
  });
}
