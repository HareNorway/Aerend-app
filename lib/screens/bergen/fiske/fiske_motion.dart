import 'package:flutter/material.dart';

import '../../common/auth/onboarding_kit.dart';

/// Small CSS-keyframe helpers shared by the Fjordfiske layers. Both honour
/// reduced motion through the onboarding kit's clocks: [OnbLoopClock] stops
/// its ticker, [OnbTimeline] jumps to the end state.

/// `animation: <name> <dur> <delay> <timing> infinite` — [builder] gets the
/// cycle progress, or null before the delay (CSS shows the static style).
class FiskeLoop extends StatelessWidget {
  const FiskeLoop({
    super.key,
    required this.durationMs,
    required this.builder,
    this.delayMs = 0,
    this.child,
  });

  final double durationMs;
  final double delayMs;
  final Widget Function(BuildContext context, double? p, Widget? child) builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) => OnbLoopClock(
    child: child,
    builder: (context, t, child) =>
        builder(context, onbLoop(t, delayMs, durationMs), child),
  );
}

/// `animation: <name> <dur> <delay> <timing> both` — plays once; [builder]
/// gets the eased-by-caller progress in [0, 1]. Re-key it to replay.
class FiskeOnce extends StatelessWidget {
  const FiskeOnce({
    super.key,
    required this.durationMs,
    required this.builder,
    this.delayMs = 0,
    this.child,
  });

  final double durationMs;
  final double delayMs;
  final Widget Function(BuildContext context, double p, Widget? child) builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) => OnbTimeline(
    durationMs: durationMs + delayMs,
    child: child,
    builder: (context, t, child) =>
        builder(context, onbP(t, delayMs, durationMs), child),
  );
}

/// A keyframe track: `onbKf` with the design's stops.
double kf(double p, List<double> stops, List<double> values, [Curve curve = Curves.linear]) =>
    onbKf(p, stops, values, curve);

/// CSS `cubic-bezier(.34,1.56,.64,1)` (`popp`, the Ægil pose pop).
const Curve kPopp = Cubic(.34, 1.56, .64, 1);

/// CSS `cubic-bezier(.2,1.1,.4,1)` (`fangstOpp`).
const Curve kFangstOpp = Cubic(.2, 1.1, .4, 1);

/// CSS `cubic-bezier(.3,1.2,.5,1)` (`kortInn`).
const Curve kKortInn = Cubic(.3, 1.2, .5, 1);

/// CSS `cubic-bezier(.3,1.3,.5,1)` (`bobleInn` on the bubble and Kast ut).
const Curve kBobleInn = Cubic(.3, 1.3, .5, 1);

/// CSS `cubic-bezier(.2,.9,.3,1)` (`skjermInn`).
const Curve kSkjermInn = Cubic(.2, .9, .3, 1);
