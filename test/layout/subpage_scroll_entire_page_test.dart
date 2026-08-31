// Every dugnad subpage scrolls its hero away, because every design screen
// nests `.lb-hero` inside the scrolling `.ae-body` and never makes it sticky.
// That is now the shell default, so a regression would be silent across ~17
// screens at once. Three halves pinned here: the hero leaves, the status strip
// stays, and the opt-out still pins.
import 'package:aerend_customer/ui/kit/ae_subpage_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reduced_motion_harness.dart';

const double _statusBar = 47;
const Color _heroBg = Color(0xFF123456);
final Key _heroKey = UniqueKey();

Future<void> pumpShell(WidgetTester tester, {required bool entirePage}) async {
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(padding: const EdgeInsets.only(top: _statusBar)),
        child: Scaffold(
          body: AeScrollBody(
            scrollEntirePage: entirePage,
            heroColor: _heroBg,
            hero: Container(key: _heroKey, height: 200, color: _heroBg),
            children: List.generate(
              20,
              (i) => SizedBox(height: 80, child: Text('row $i')),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  setUpAll(() => bootstrapGlobals(locale: 'no'));

  testWidgets('the shell default is scroll-the-hero, not pin-the-hero',
      (tester) async {
    // Omits the flag entirely -- this is the assertion that the ~17 subpages
    // which never mention `scrollEntirePage` get the design behaviour.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AeScrollBody(
          hero: Container(key: _heroKey, height: 200, color: _heroBg),
          children: List.generate(
            20,
            (i) => SizedBox(height: 80, child: Text('row $i')),
          ),
        ),
      ),
    ));
    await tester.pump();
    final before = tester.getTopLeft(find.byKey(_heroKey)).dy;

    await tester.drag(find.text('row 2'), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.byKey(_heroKey)).dy, lessThan(before - 250));
  });

  testWidgets('by default the hero scrolls away with the feed',
      (tester) async {
    await pumpShell(tester, entirePage: true);
    final before = tester.getTopLeft(find.byKey(_heroKey)).dy;

    await tester.drag(find.text('row 2'), const Offset(0, -300));
    await tester.pumpAndSettle();

    final after = tester.getTopLeft(find.byKey(_heroKey)).dy;
    expect(after, lessThan(before - 250),
        reason: 'hero should travel with the scroll, not stay pinned');
  });

  testWidgets('scrollEntirePage keeps a status strip the feed passes under',
      (tester) async {
    await pumpShell(tester, entirePage: true);
    await tester.drag(find.text('row 2'), const Offset(0, -300));
    await tester.pumpAndSettle();

    final strip = find.byWidgetPredicate((w) =>
        w is ColoredBox && w.color == _heroBg);
    expect(
      tester.widgetList<ColoredBox>(strip).length,
      greaterThanOrEqualTo(1),
      reason: 'the hero-colored band must survive the hero leaving',
    );
    final sizes = tester
        .renderObjectList<RenderBox>(strip)
        .map((b) => b.size.height)
        .toList();
    expect(sizes, contains(_statusBar));
  });

  testWidgets('opting out (scrollEntirePage: false) still pins the hero',
      (tester) async {
    await pumpShell(tester, entirePage: false);
    final before = tester.getTopLeft(find.byKey(_heroKey)).dy;

    await tester.drag(find.text('row 2'), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.byKey(_heroKey)).dy, before);
  });
}
