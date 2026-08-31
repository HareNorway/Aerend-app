import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aerend_customer/l10n/app_localizations.dart';
import 'package:aerend_customer/main.dart' as app;
import 'package:aerend_customer/utils/shared_pref_utill.dart';

/// Initialise the two globals that widgets reach for directly — `languages`
/// and the SharedPreferences instance behind `prefGet*`.
///
/// Without this, harness coverage is decided by which widgets happen to touch
/// a global rather than by which widgets animate, which is the wrong axis.
/// Call from `setUpAll`.
Future<void> bootstrapGlobals({String locale = 'no'}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await initSharedPreferences();
  app.languages = await AppLocalizations.delegate.load(Locale(locale));
}

/// Shared reduced-motion contract for animated widgets.
///
/// Three bugs recur in this codebase and none is visible unless you actually
/// exercise the reduced-motion path, which nobody does by hand:
///
/// 1. The controller is started in `initState` unconditionally and `build`
///    merely declines to show the result — so it runs, burns battery and keeps
///    a frame permanently scheduled.
/// 2. `animation-delay` is a fire-and-forget `Future.delayed`. `mounted` stays
///    true through deactivation, so a late callback re-registers the
///    controller and blows up the `TickerMode` lookup.
/// 3. Controllers are `late final`, so under reduced motion the field is never
///    read and `TickerProviderStateMixin` is left with an unstable ticker set.
///
/// [expectRespectsReducedMotion] asserts all three at once. Point new animated
/// widgets at it and they inherit the coverage.
Future<void> expectRespectsReducedMotion(
  WidgetTester tester,
  Widget Function() build, {
  /// Longest `animation-delay` in the widget; the harness advances past it to
  /// catch a timer that outlived disposal.
  Duration longestDelay = const Duration(seconds: 2),
  String? reason,
}) async {
  Widget host({required bool reduced}) => MaterialApp(
        home: Builder(
          // MediaQuery must sit INSIDE MaterialApp — it inserts its own from
          // the window and would override an outer one.
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: Scaffold(body: Center(child: build())),
          ),
        ),
      );

  // ---- 1. nothing animates under reduced motion -------------------------
  await tester.pumpWidget(host(reduced: true));
  await tester.pump(const Duration(milliseconds: 16));

  expect(
    _animatingCount(tester),
    0,
    reason: reason ??
        'controllers still animating under reduced motion — the gate must '
            'prevent them starting, not just hide their output',
  );

  // A still-running controller keeps requesting frames.
  await tester.pump(longestDelay);
  expect(
    _animatingCount(tester),
    0,
    reason: 'a delayed start fired despite reduced motion',
  );

  // ---- 3. it built at all (an unstable ticker set throws here) -----------
  expect(tester.takeException(), isNull,
      reason: 'widget failed to build under reduced motion');

  // ---- 2. no timer survives disposal ------------------------------------
  await tester.pumpWidget(host(reduced: false));
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pumpWidget(const SizedBox()); // dispose it
  // Advancing past the longest delay would fire an uncancelled timer; the
  // binding then fails the test with "A Timer is still pending".
  await tester.pump(longestDelay + const Duration(milliseconds: 100));
  expect(tester.takeException(), isNull,
      reason: 'a timer outlived disposal — cancel it in dispose()');
}

/// An animating `AnimationController` registers a persistent frame callback,
/// so a non-zero transient-callback count is the reliable "something is still
/// animating" signal — more robust than inspecting private ticker state.
int _animatingCount(WidgetTester tester) =>
    tester.binding.transientCallbackCount;
