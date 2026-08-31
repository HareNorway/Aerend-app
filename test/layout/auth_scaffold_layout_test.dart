import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/common/auth/auth_style.dart';
import 'package:aerend_customer/theme/design_scale.dart';

/// Geometry regression tests for the auth layer.
///
/// Two properties are asserted, and they pull in opposite directions — which
/// is exactly why both are needed:
///
///  1. **Design-frame exactness.** At 375pt wide (the `.ae-screen` frame),
///     `ds == 1.0` and every value renders at its literal CSS px. A 56px
///     button is 56.0, not 55.2 or 57.1.
///  2. **Proportional match.** On wider devices every dimension grows by
///     `width / 375`, so each element occupies the *same fraction of the
///     screen* as it does in the design. That fraction being constant across
///     sizes is the single assertion that proves the match.
void main() {
  const sizes = <String, Size>{
    'SE 375x667': Size(375, 667),
    'design frame 375x812': Size(375, 812),
    '15 Pro 393x852': Size(393, 852),
    'Pro Max 430x932': Size(430, 932),
  };

  /// Expected `ds` per width, from `width / 375`.
  double expectedDs(double width) => width / 375.0;

  Future<void> pumpAt(WidgetTester tester, Size size, Widget child) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: child));
    // The controls are AnimatedContainers. When a test re-pumps at a second
    // size the element tree is reused, so the height change animates and a
    // single pump() would sample it mid-flight. Settle before measuring.
    await tester.pumpAndSettle();
  }

  group('design scale', () {
    testWidgets('ds is exactly 1.0 on the 375 design frame', (tester) async {
      for (final size in [const Size(375, 667), const Size(375, 812)]) {
        late double ds;
        await pumpAt(
          tester,
          size,
          Builder(
            builder: (context) {
              ds = context.ds;
              return const SizedBox();
            },
          ),
        );
        expect(ds, 1.0, reason: 'the design frame must be pixel-exact');
      }
    });

    testWidgets('ds tracks width / 375 above the frame', (tester) async {
      for (final width in [393.0, 430.0]) {
        late double ds;
        await pumpAt(
          tester,
          Size(width, 900),
          Builder(
            builder: (context) {
              ds = context.ds;
              return const SizedBox();
            },
          ),
        );
        expect(ds, closeTo(expectedDs(width), 0.001));
      }
    });

    testWidgets('ds clamps so tablets do not get a blown-up phone layout',
        (tester) async {
      late double ds;
      await pumpAt(
        tester,
        const Size(1024, 1366),
        Builder(
          builder: (context) {
            ds = context.ds;
            return const SizedBox();
          },
        ),
      );
      expect(ds, kMaxDesignScale);
    });
  });

  group('scaled control sizes', () {
    /// The design px → expected rendered value at each width.
    const socialButtonDesignPx = 56.0;

    for (final entry in sizes.entries) {
      testWidgets('social button height at ${entry.key}', (tester) async {
        await pumpAt(
          tester,
          entry.value,
          AuthScaffold(
            child: AuthSocialButton(
              type: AuthSocialButtonType.google,
              // Short label: the test font is fixed-width, so real copy would
              // measure far wider here than it does on device.
              label: 'x',
              onTap: () {},
            ),
          ),
        );

        final height = tester
            .getRect(find.byType(AuthSocialButton))
            .height;
        final expected =
            socialButtonDesignPx * expectedDs(entry.value.width);
        expect(height, closeTo(expected, 0.5));
      });
    }

    testWidgets('56.0 exactly at 375, 64.2 at 430', (tester) async {
      await pumpAt(
        tester,
        const Size(375, 812),
        AuthScaffold(
          child: AuthSocialButton(
            type: AuthSocialButtonType.google,
            label: 'x',
            onTap: () {},
          ),
        ),
      );
      expect(tester.getRect(find.byType(AuthSocialButton)).height, 56.0);

      await pumpAt(
        tester,
        const Size(430, 932),
        AuthScaffold(
          child: AuthSocialButton(
            type: AuthSocialButtonType.google,
            label: 'x',
            onTap: () {},
          ),
        ),
      );
      expect(
        tester.getRect(find.byType(AuthSocialButton)).height,
        closeTo(64.2, 0.5),
      );
    });

    testWidgets('all three social buttons are the same height — Vipps too',
        (tester) async {
      await pumpAt(
        tester,
        const Size(430, 932),
        AuthScaffold(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AuthSocialButton(
                type: AuthSocialButtonType.vipps,
                label: 'Vipps',
                onTap: () {},
              ),
              AuthSocialButton(
                type: AuthSocialButtonType.google,
                label: 'Google',
                onTap: () {},
              ),
              AuthSocialButton(
                type: AuthSocialButtonType.apple,
                label: 'Apple',
                onTap: () {},
              ),
            ],
          ),
        ),
      );

      final heights = tester
          .widgetList(find.byType(AuthSocialButton))
          .map((w) => tester.getRect(find.byWidget(w)).height)
          .toList();
      expect(heights, hasLength(3));
      // `.ae-btn { height: 56 }` applies to all three; `.ae-btn--vipps`'s
      // min-height: 52 is a floor that never binds.
      for (final h in heights) {
        expect(h, closeTo(heights.first, 0.01));
        expect(h, closeTo(64.2, 0.5));
      }
    });

    testWidgets('button height ÷ screen width is constant at every size',
        (tester) async {
      final ratios = <double>[];
      for (final size in sizes.values) {
        await pumpAt(
          tester,
          size,
          AuthScaffold(
            child: AuthSocialButton(
              type: AuthSocialButtonType.google,
              label: 'x',
              onTap: () {},
            ),
          ),
        );
        ratios.add(
          tester.getRect(find.byType(AuthSocialButton)).height / size.width,
        );
      }

      // This is the assertion that proves the proportional match: the control
      // must occupy the same fraction of the screen on every device.
      for (final r in ratios) {
        expect(r, closeTo(56.0 / 375.0, 0.001));
      }
    });
  });

  group('fill and scroll', () {
    for (final entry in sizes.entries) {
      testWidgets('footer pinned one scaled body-padding above the bottom '
          'at ${entry.key}', (tester) async {
        await pumpAt(
          tester,
          entry.value,
          const AuthScaffold(
            child: SizedBox(height: 120, child: Text('head')),
            footer: SizedBox(height: 56, child: Text('cta')),
          ),
        );

        final ds = expectedDs(entry.value.width);
        // `.auth-body { padding-bottom: 24 }`, scaled.
        expect(
          tester.getRect(find.text('cta')).bottom,
          closeTo(entry.value.height - 24 * ds, 0.5),
        );
        // `.auth-body { padding-top: 8 }`, scaled.
        expect(tester.getRect(find.text('head')).top, closeTo(8 * ds, 0.5));
      });

      testWidgets('overflowing content scrolls at ${entry.key}',
          (tester) async {
        await pumpAt(
          tester,
          entry.value,
          const AuthScaffold(
            child: SizedBox(height: 1400, child: Text('tall')),
            footer: SizedBox(height: 56, child: Text('cta')),
          ),
        );

        expect(tester.takeException(), isNull);
        final position =
            tester.state<ScrollableState>(find.byType(Scrollable)).position;
        expect(position.maxScrollExtent, greaterThan(0));
      });
    }

    testWidgets('no footer: content flows from the top', (tester) async {
      await pumpAt(
        tester,
        const Size(430, 932),
        const AuthScaffold(
          child: SizedBox(height: 120, child: Text('head')),
        ),
      );
      expect(
        tester.getRect(find.text('head')).top,
        closeTo(8 * expectedDs(430), 0.5),
      );
    });
  });
}
