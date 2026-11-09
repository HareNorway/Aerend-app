import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../bergen/kit/bergen_perf.dart';
import 'lf_css.dart';

// ── Launch onboarding · motion ──────────────────────────────────────────────
// Clocks for the prototype's CSS animations. A one-shot clock starts when its
// element mounts (like a CSS animation on a freshly inserted node); a loop
// clock ticks forever. Both freeze under reduced motion and stop with
// TickerMode (covered routes, app in background).

/// Plays once from mount and hands [builder] the elapsed ms.
class LfOnce extends StatefulWidget {
  const LfOnce({
    super.key,
    required this.ms,
    required this.builder,
    this.child,
  });

  final double ms;
  final Widget Function(BuildContext context, double t, Widget? child) builder;
  final Widget? child;

  @override
  State<LfOnce> createState() => _LfOnceState();
}

class _LfOnceState extends State<LfOnce> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.ms.round().clamp(1, 1 << 30)),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (context, child) =>
        widget.builder(context, _c.value * widget.ms, child),
  );
}

/// Ticks forever from mount; [builder] gets the elapsed ms. Frozen at
/// [frozenMs] under reduced motion.
class LfLoop extends StatefulWidget {
  const LfLoop({
    super.key,
    required this.builder,
    this.child,
    this.frozenMs = 0,
    this.essential = false,
  });

  final Widget Function(BuildContext context, double t, Widget? child) builder;
  final Widget? child;
  final double frozenMs;

  /// Keeps running in the `lite` tier (see [BergenEssential]).
  final bool essential;

  @override
  State<LfLoop> createState() => _LfLoopState();
}

class _LfLoopState extends State<LfLoop> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier<double>(0);
  Duration _base = Duration.zero;
  Duration _last = Duration.zero;
  bool _reduce = false;

  // Perf plan: a loop whose box is wholly off the screen (scrolled away,
  // under the fold) stops ticking — no frame, no rebuild — while its clock
  // keeps wall time ([_hvil]), so it comes back at exactly the pose the
  // design's CSS animation would show at that moment. The nearest scroll
  // position and a 120 ms timer wake it as soon as it is on the screen.
  int _tikk = 0;
  Stopwatch? _hvil;
  late final PerfVekker _vekk = PerfVekker(_sjekk);
  ScrollPosition? _rull;

  @override
  void initState() {
    super.initState();
    BergenPerf.lfLoopsMounted++;
    if (kDebugMode) BergenPerf.debugLoops[context] = () => _ticker.isActive && !_ticker.muted;
    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration e) {
    _last = e;
    _t.value = BergenPerf.frysMs ?? (_base + e).inMicroseconds / 1000.0;
    if (BergenPerf.hvilePaa && ++_tikk % 12 == 0 && BergenPerf.utenforSkjerm(context)) _hvile();
  }

  void _hvile() {
    if (!_ticker.isActive) return;
    _base += _last;
    _last = Duration.zero;
    _ticker.stop();
    _hvil = Stopwatch()..start();
    _vekk.start(context);
    _rull = Scrollable.maybeOf(context)?.position;
    _rull?.addListener(_sjekk);
  }

  void _sjekk() {
    if (!mounted || _reduce || _ticker.muted) return;
    if (BergenPerf.utenforSkjerm(context)) return;
    _vaakn();
  }

  void _vaakn() {
    _vekk.stopp();
    _rull?.removeListener(_sjekk);
    _rull = null;
    final h = _hvil;
    _hvil = null;
    if (h != null) _base += h.elapsed;
    if (!_reduce && !_ticker.isActive) _ticker.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion, or a decorative loop in the `lite` tier, rests at
    // [frozenMs] (keyframe 0 unless the caller says otherwise).
    _reduce = MediaQuery.disableAnimationsOf(context) ||
        !BergenPerf.loopsRun(context, essential: widget.essential);
    if (_reduce) {
      if (_ticker.isActive) {
        _base += _last;
        _last = Duration.zero;
        _ticker.stop();
      }
      _vekk.stopp();
      _rull?.removeListener(_sjekk);
      _rull = null;
      _hvil = null;
      _t.value = widget.frozenMs;
    } else if (!_ticker.isActive && _hvil == null) {
      _ticker.start();
    }
  }

  @override
  void activate() {
    super.activate();
    _vekk.folg(context);
  }

  @override
  void dispose() {
    BergenPerf.lfLoopsMounted--;
    if (kDebugMode) BergenPerf.debugLoops.remove(context);
    _vekk.stopp();
    _rull?.removeListener(_sjekk);
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: _t,
    child: widget.child,
    builder: (context, t, child) => widget.builder(context, t, child),
  );
}

// ── Shared keyframes ────────────────────────────────────────────────────────

/// `spOpp` — opacity 0→1, translateY(12px)→0. Default `ease-out`.
class LfRise extends StatelessWidget {
  const LfRise({
    super.key,
    required this.child,
    this.delay = 0,
    this.dur = 450,
    this.curve = cssEaseOut,
    this.dy = 12,
  });

  final Widget child;
  final double delay;
  final double dur;
  final Curve curve;
  final double dy;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: delay + dur,
    child: child,
    builder: (context, t, child) {
      final p = curve.transform(kfP(t, delay, dur));
      return Opacity(
        opacity: p.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, dy * (1 - p)), child: child),
      );
    },
  );
}

/// `onbInn` — a step's content slides in 26px from the right.
class LfStepIn extends StatelessWidget {
  const LfStepIn({super.key, required this.child, this.dur = 320, this.curve = const Cubic(.2, .9, .3, 1), this.paa = true});

  final Widget child;
  final double dur;
  final Curve curve;

  /// Off when the Menisk carries the step in instead (Bergen 29 Oct).
  final bool paa;

  @override
  Widget build(BuildContext context) => !paa ? child : LfOnce(
    ms: dur,
    child: child,
    builder: (context, t, child) {
      final p = curve.transform(kfP(t, 0, dur));
      return Opacity(
        opacity: p.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(26 * (1 - p), 0), child: child),
      );
    },
  );
}

/// `onbBoble` — opacity, translateY(8px) scale(.92) → none.
class LfBubbleIn extends StatelessWidget {
  const LfBubbleIn({
    super.key,
    required this.child,
    this.delay = 160,
    this.dur = 500,
  });

  final Widget child;
  final double delay;
  final double dur;

  static const Cubic _c = Cubic(.2, 1.1, .4, 1);

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: delay + dur,
    child: child,
    builder: (context, t, child) {
      final p = _c.transform(kfP(t, delay, dur));
      return Opacity(
        opacity: p.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - p)),
          child: Transform.scale(scale: .92 + .08 * p, child: child),
        ),
      );
    },
  );
}

/// `aegStaa` — Ægil breathing from the feet (origin 50% 100%).
Matrix4 aegStaa(double t, double durMs) {
  final p = ((t / durMs) % 1.0);
  final sx = kf(p, const [0, .3, .62, 1], const [1, .99, 1.006, 1], cssEaseInOut);
  final sy = kf(p, const [0, .3, .62, 1], const [1, 1.02, .994, 1], cssEaseInOut);
  final r = kf(p, const [0, .3, .62, 1], const [0, -.7, .6, 0], cssEaseInOut);
  return Matrix4.identity()
    ..rotateZ(rad(r))
    ..scaleByDouble(sx, sy, 1, 1);
}

/// `onbBaat` — the framed Ægil portraits rocking: translateY(0→-3px),
/// rotate(-2deg→2deg), 3.4s ease-in-out.
Matrix4 onbBaat(double t) {
  final p = (t / 3400) % 1.0;
  final y = kf(p, const [0, .5, 1], const [0, -3, 0], cssEaseInOut);
  final r = kf(p, const [0, .5, 1], const [-2, 2, -2], cssEaseInOut);
  return Matrix4.translationValues(0, y, 0)..rotateZ(rad(r));
}

/// Shakes horizontally once when [trigger] changes (`onbRist .45s`).
class LfShake extends StatefulWidget {
  const LfShake({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<LfShake> createState() => _LfShakeState();
}

class _LfShakeState extends State<LfShake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void didUpdateWidget(LfShake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && widget.trigger > 0) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (context, child) {
      final x = kf(_c.value, const [0, .2, .4, .6, .8, 1], const [0, -7, 6, -4, 3, 0], cssEaseInOut);
      return Transform.translate(offset: Offset(x, 0), child: child);
    },
  );
}
