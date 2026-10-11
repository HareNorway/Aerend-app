import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// How much motion the phone can afford (parity plan §3.1).
///
/// `full` is the prototype's look. `lite` keeps the same still image and
/// layout with less motion: only loops inside a [BergenEssential] keep
/// running, shaders run slower at fewer pixels, particles halve and blur is
/// softer. `still` is the reduced-motion app: no loops, no shaders, no blur.
enum BergenTier { full, lite, still }

/// The app-wide motion tier: chosen at start-up from the device class, low
/// power mode and the thermal state, stepped down by a frame watchdog in
/// profile / release builds. Konto's «Roligere bevegelse» and the OS reduce
/// motion setting always mean `still` (they arrive as
/// `MediaQuery.disableAnimations`).
abstract final class BergenPerf {
  static const MethodChannel _channel = MethodChannel('aerend/perf');

  /// The tier before reduced motion is applied (see [of]).
  static final ValueNotifier<BergenTier> tier = ValueNotifier<BergenTier>(BergenTier.full);

  /// False while the app is in the background: videos and other
  /// non-ticker work pause on it (tickers stop by themselves without frames).
  static final ValueNotifier<bool> foreground = ValueNotifier<bool>(true);

  static String reason = 'start';

  static BergenTier _device = BergenTier.full;
  static String _deviceWhy = 'device';
  static bool _lowPower = false;
  static int _thermal = 0; // 0 nominal · 1 fair · 2 serious · 3 critical
  static int _watchdogSteps = 0;
  static BergenTier? _forced;
  static bool _started = false;

  /// Reads the device class and starts listening. Safe to call twice; does
  /// nothing visible when the platform channel is missing (tests, web).
  static Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(_Lifecycle());
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'changed') _readState(call.arguments);
    });
    try {
      final info = await _channel.invokeMapMethod<String, Object?>('info');
      if (info != null) {
        _readDevice(info);
        _readState(info);
      }
    } catch (_) {
      // No channel (tests): stay on the prototype's tier.
    }
    if (kReleaseMode || kProfileMode) {
      SchedulerBinding.instance.addTimingsCallback(_Watchdog.onTimings);
    }
    _update();
  }

  static void _readDevice(Map<String, Object?> m) {
    final ramMb = (m['ramMb'] as num?)?.toDouble() ?? 0;
    final lowRam = m['lowRam'] == true;
    final sdk = (m['sdk'] as num?)?.toInt() ?? 0;
    final android = m['platform'] == 'android';
    if (android && (lowRam || (ramMb > 0 && ramMb < 3800) || (sdk > 0 && sdk < 28))) {
      _device = BergenTier.lite;
      _deviceWhy = 'android ram ${ramMb.round()} MB, sdk $sdk${lowRam ? ', low-ram' : ''}';
    } else if (!android && ramMb > 0 && ramMb < 3584) {
      _device = BergenTier.lite;
      _deviceWhy = 'iphone ram ${ramMb.round()} MB (${m['model']})';
    } else {
      _deviceWhy = '${m['model'] ?? 'device'} ram ${ramMb.round()} MB';
    }
  }

  static void _readState(Object? args) {
    if (args is! Map) return;
    if (args['lowPower'] is bool) _lowPower = args['lowPower'] as bool;
    if (args['thermal'] is num) _thermal = (args['thermal'] as num).toInt();
    if (_started) _update();
  }

  /// Debug harness only (`perf` in `hjem_state.json`): pin a tier, or null
  /// to go back to the automatic one.
  static void force(BergenTier? t) {
    if (!kDebugMode) return;
    _forced = t;
    _update();
  }

  static void _stepDown() {
    if (_watchdogSteps >= 2) return;
    _watchdogSteps++;
    _update();
  }

  static void _update() {
    BergenTier t = _device;
    var why = _deviceWhy;
    BergenTier raise(BergenTier a, BergenTier b) => a.index >= b.index ? a : b;
    if (_watchdogSteps > 0) {
      final w = BergenTier.values[math.min(2, _watchdogSteps)];
      if (w.index > t.index) why = 'slow frames ×$_watchdogSteps';
      t = raise(t, w);
    }
    if (_thermal >= 2) {
      t = BergenTier.still;
      why = 'thermal $_thermal';
    } else if (_thermal == 1 && t == BergenTier.full) {
      t = BergenTier.lite;
      why = 'thermal fair';
    }
    if (_lowPower) {
      t = BergenTier.still;
      why = 'low power mode';
    }
    if (_forced != null) {
      t = _forced!;
      why = 'forced';
    }
    if (t != tier.value || why != reason) {
      reason = why;
      tier.value = t;
      debugPrint('PERF_TIER ${t.name} $why');
    }
  }

  /// The tier for this subtree: `still` under reduced motion, else the app's.
  static BergenTier of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<_PerfScope>();
    if (s != null) return s.tier;
    return MediaQuery.maybeDisableAnimationsOf(context) == true ? BergenTier.still : BergenTier.full;
  }

  /// True when the user (Konto's «Roligere bevegelse» or the OS setting)
  /// asked for less motion — the prototype's `rolig`. False when `still`
  /// only comes from heat, battery or a slow phone.
  static bool calmOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PerfScope>()?.calm ??
      (MediaQuery.maybeDisableAnimationsOf(context) == true);

  /// Whether loops in this subtree may run.
  static bool loopsRun(BuildContext context, {bool essential = false}) {
    final t = of(context);
    if (t == BergenTier.still) return false;
    if (t == BergenTier.lite) return essential || BergenEssential.inside(context);
    return true;
  }

  /// A `BackdropFilter` blur for this tier: softer in `lite`. Pair it with
  /// `enabled: BergenPerf.blurOn(context)` (no blur in `still`).
  static ui.ImageFilter blur(BuildContext context, double sigmaX, [double? sigmaY]) {
    final k = of(context) == BergenTier.lite ? .6 : 1.0;
    return ui.ImageFilter.blur(sigmaX: sigmaX * k, sigmaY: (sigmaY ?? sigmaX) * k);
  }

  static bool blurOn(BuildContext context) => of(context) != BergenTier.still;

  /// A particle count: the prototype's [n] in `full`, half in `lite`, none in
  /// `still`.
  static int count(BuildContext context, int n) => switch (of(context)) {
    BergenTier.full => n,
    BergenTier.lite => (n / 2).ceil(),
    BergenTier.still => 0,
  };

  /// Decode width for network images: never wider than the screen in device
  /// pixels (2× in `lite`). Flutter never upscales with `cacheWidth`, so small
  /// images are untouched and large photos stop costing full-size memory.
  static int get decodeWidth {
    final views = ui.PlatformDispatcher.instance.views;
    if (views.isEmpty) return 1290;
    final v = views.first;
    final dpr = tier.value == BergenTier.full ? v.devicePixelRatio : math.min(2.0, v.devicePixelRatio);
    final w = v.physicalSize.width / v.devicePixelRatio * dpr;
    return w <= 0 ? 1290 : w.round().clamp(320, 1600);
  }

  /// Minimum time between two shader frames for this tier, or null when the
  /// shader should hold still. [fullMs] is the prototype's own pace.
  static Duration? shaderStep(BuildContext context, {required double fullMs, required double liteMs}) =>
      switch (of(context)) {
        BergenTier.full => Duration(microseconds: (fullMs * 1000).round()),
        BergenTier.lite => Duration(microseconds: (liteMs * 1000).round()),
        BergenTier.still => null,
      };

  /// Shader pixel budget: the prototype's in `full`, 55 % in `lite`.
  static double shaderBudget(BuildContext context, double full) =>
      of(context) == BergenTier.lite ? full * .55 : full;
}

/// Puts [BergenPerf.tier] into the tree. Goes inside the reduced-motion
/// `MediaQuery`, so it can tell a user's calm setting from heat.
class BergenPerfScope extends StatelessWidget {
  const BergenPerfScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final calm = MediaQuery.maybeDisableAnimationsOf(context) == true;
    return ValueListenableBuilder<BergenTier>(
      valueListenable: BergenPerf.tier,
      child: child,
      builder: (context, t, child) {
        final eff = calm ? BergenTier.still : t;
        Widget c = child!;
        // `still` from heat reuses every helper's reduced-motion path.
        if (eff == BergenTier.still && !calm) {
          c = MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: c);
        }
        return _PerfScope(tier: eff, calm: calm, child: c);
      },
    );
  }
}

class _PerfScope extends InheritedWidget {
  const _PerfScope({required this.tier, required this.calm, required super.child});

  final BergenTier tier;
  final bool calm;

  @override
  bool updateShouldNotify(_PerfScope old) => old.tier != tier || old.calm != calm;
}

/// Loops inside this subtree carry meaning (the live pill, a game, a typing
/// indicator) and keep running in `lite`.
class BergenEssential extends InheritedWidget {
  const BergenEssential({super.key, required super.child});

  static bool inside(BuildContext context) =>
      context.getInheritedWidgetOfExactType<BergenEssential>() != null;

  @override
  bool updateShouldNotify(BergenEssential old) => false;
}

class _Lifecycle with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    BergenPerf.foreground.value = state == AppLifecycleState.resumed;
  }
}

/// Steps the tier down when the 90th-percentile frame time over 5 s is above
/// 1.5× the frame budget, twice in a row (profile / release only: debug
/// frames are always slow).
abstract final class _Watchdog {
  static final List<int> _us = [];
  static int _windowStart = 0;
  static int _badWindows = 0;

  static void onTimings(List<ui.FrameTiming> timings) {
    if (!BergenPerf.foreground.value) return;
    for (final t in timings) {
      _us.add(t.totalSpan.inMicroseconds);
    }
    final now = DateTime.now().microsecondsSinceEpoch;
    if (_windowStart == 0) _windowStart = now;
    if (now - _windowStart < 5000000 || _us.length < 30) return;
    _us.sort();
    final p90 = _us[(_us.length * .9).floor().clamp(0, _us.length - 1)];
    _us.clear();
    _windowStart = now;
    final views = ui.PlatformDispatcher.instance.views;
    final hz = views.isEmpty ? 60.0 : (views.first.display.refreshRate.clamp(30.0, 120.0));
    final budgetUs = 1e6 / math.min(hz, 60.0);
    if (p90 > 1.5 * budgetUs) {
      if (++_badWindows >= 2) {
        _badWindows = 0;
        BergenPerf._stepDown();
      }
    } else {
      _badWindows = 0;
    }
  }
}
