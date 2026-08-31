import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/commonView/ae_inset_surface.dart';

/// The `--ae-shiny-*` families are **inset-led**: their top highlight and
/// bottom lift carry the surface, and the outer drop alone reads flat.
/// `AeSurface.shiny` shipped the drop by itself for exactly the reason its own
/// docstring gave — "Flutter cannot do inset box-shadow" — which is rule 5's
/// failure mode written down and then committed.
void main() {
  Future<void> pump(WidgetTester tester, Widget surface) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          // Unbounded height so the surface sizes to content; a stretched box
          // drives every 1/H stop into the clamp floor (rule 22).
          body: SingleChildScrollView(
            child: SizedBox(width: 335, child: surface),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }

  LinearGradient? insetAt(WidgetTester tester, Key key) {
    final f = find.byKey(key);
    if (f.evaluate().isEmpty) return null;
    return (tester.widget<DecoratedBox>(f).decoration as BoxDecoration).gradient
        as LinearGradient?;
  }

  testWidgets('shiny carries both insets and the deep drop', (tester) async {
    await pump(
      tester,
      AeInsetSurface.shiny(
        borderRadius: BorderRadius.circular(16),
        child: const SizedBox(height: 60, width: double.infinity),
      ),
    );

    final top = insetAt(tester, kAeInsetTopKey);
    expect(top, isNotNull, reason: 'top highlight dropped');
    expect(top!.colors.first.a, closeTo(0.9, 0.005));
    expect(top.begin, Alignment.topCenter);

    final bottom = insetAt(tester, kAeInsetBottomKey);
    expect(bottom, isNotNull, reason: 'bottom lift dropped');
    expect(bottom!.colors.first.a, closeTo(0.14, 0.005));
    // The -3px offset anchors this to the bottom. Painting it from the top
    // would put the purple lift across the wrong edge.
    expect(bottom.begin, Alignment.bottomCenter);
    expect(bottom.end, Alignment.topCenter);

    // 2px and 8px of the laid-out height, not of a constant.
    final h = tester.getSize(find.byKey(kAeInsetTopKey)).height;
    expect(top.stops!.last, closeTo(2 / h, 0.001));
    expect(bottom.stops!.last, closeTo(8 / h, 0.001));
  });

  testWidgets('shinyPurple has ONE inset, not three layers', (tester) async {
    await pump(
      tester,
      AeInsetSurface.shinyPurple(
        isCircle: true,
        child: const SizedBox(height: 44, width: 44),
      ),
    );

    expect(insetAt(tester, kAeInsetTopKey), isNotNull);
    expect(
      find.byKey(kAeInsetBottomKey),
      findsNothing,
      reason: 'the purple family is deliberately lighter than the neutral one '
          '(rule 18) — do not normalise it up to three layers',
    );
    expect(insetAt(tester, kAeInsetTopKey)!.colors.first.a, closeTo(0.45, 0.005));
  });

  testWidgets('shinySm is not a scaled copy of shiny', (tester) async {
    await pump(
      tester,
      AeInsetSurface.shinySm(
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox(height: 40, width: double.infinity),
      ),
    );
    // The alphas move between the two sizes (.14 -> .12, .42 -> .34), so no
    // single multiplier expresses the relationship.
    expect(insetAt(tester, kAeInsetBottomKey)!.colors.first.a,
        closeTo(0.12, 0.005));
  });

  testWidgets('the three families are mutually distinct', (tester) async {
    final seen = <String>{};
    for (final build in [
      () => AeInsetSurface.shiny(
          borderRadius: BorderRadius.circular(16),
          child: const SizedBox(height: 60, width: double.infinity)),
      () => AeInsetSurface.shinySm(
          borderRadius: BorderRadius.circular(16),
          child: const SizedBox(height: 60, width: double.infinity)),
      () => AeInsetSurface.shinyPurple(
          borderRadius: BorderRadius.circular(16),
          child: const SizedBox(height: 60, width: double.infinity)),
    ]) {
      await pump(tester, build());
      final drop = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.boxShadow?.isNotEmpty ?? false)
          .boxShadow!
          .first;
      final n = find.byKey(kAeInsetTopKey).evaluate().length +
          find.byKey(kAeInsetBottomKey).evaluate().length;
      final key = '${drop.color.toARGB32()}|${drop.offset.dy}|'
          '${drop.blurRadius}|${drop.spreadRadius}|$n';
      expect(seen.add(key), isTrue, reason: 'a house default has returned');
    }
    expect(seen, hasLength(3));
  });
}
