import 'dart:async';
import 'dart:io' show File, FileMode, IOSink, ProcessInfo;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

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

  /// True while a screen's main sheet is scrolling (Hjem sets it from its
  /// scroll notifications): per-frame extras that cost a Gaussian pass (the
  /// rails' back-card blur) pause until it stops.
  static final ValueNotifier<bool> ruller = ValueNotifier<bool>(false);

  static String reason = 'start';

  /// The frame watchdog (see [start]); off unless built with `AE_WATCHDOG=true`.
  static const bool vakthund = bool.fromEnvironment('AE_WATCHDOG');

  /// Perf plan: mounted loop widgets (`LfLoop`, `OnbLoopClock`), for the
  /// heartbeat. The *active* ticker count is the scheduler's transient
  /// callback count, which needs no registry.
  static int lfLoopsMounted = 0, onbLoopsMounted = 0;

  /// Perf plan (debug only): mounted clock loops and whether each is
  /// ticking, for [tickerCensus].
  static final Map<BuildContext, bool Function()> debugLoops = {};

  /// Perf plan (debug only): logs `PERF_CENSUS` lines — who owns each active
  /// ticker. Loop widgets (`LfLoop`, `OnbLoopClock`) by their creator chain,
  /// every other ticker by the first app frame of the stack that started it
  /// (Flutter keeps that stack in debug builds).
  static void tickerCensus(String tag) {
    if (!kDebugMode) return;
    final loops = <String, int>{};
    for (final e in debugLoops.entries) {
      if (!e.value()) continue;
      final ctx = e.key;
      if (!ctx.mounted) continue;
      final chain = (ctx as Element).debugGetCreatorChain(18).split(' ← ').where((w) => !_rammeverk.contains(w.replaceAll(RegExp(r'[-<].*'), ''))).take(4).join(' ← ');
      loops[chain] = (loops[chain] ?? 0) + 1;
    }
    final andre = <String, int>{};
    final old = FlutterError.onError;
    FlutterError.onError = (d) {
      for (final n in d.informationCollector?.call() ?? const <DiagnosticsNode>[]) {
        if (n is! DiagnosticsStackTrace) continue;
        final lines = n.toStringDeep().split('\n').where((l) => l.contains('package:aerend_customer/')).toList();
        if (lines.isEmpty) {
          andre['(framework only)'] = (andre['(framework only)'] ?? 0) + 1;
          continue;
        }
        final eier = lines.firstWhere((l) => !l.contains('lf_motion.dart') && !l.contains('onboarding_kit.dart') && !l.contains('bergen_motion.dart'), orElse: () => 'loop-widget');
        if (eier == 'loop-widget') continue; // counted by creator chain above
        final k = eier.replaceAll(RegExp(r'^.*?#\d+\s+'), '').replaceAll('package:aerend_customer/', '').trim();
        andre[k] = (andre[k] ?? 0) + 1;
      }
    };
    try {
      SchedulerBinding.instance.debugAssertNoTransientCallbacks('perf census');
    } finally {
      FlutterError.onError = old;
    }
    final n = loops.values.fold<int>(0, (a, b) => a + b) + andre.values.fold<int>(0, (a, b) => a + b);
    debugPrint('PERF_CENSUS $tag active=${SchedulerBinding.instance.transientCallbackCount} counted=$n');
    for (final e in (loops.entries.toList()..sort((a, b) => b.value - a.value))) {
      debugPrint('PERF_CENSUS   loop ×${e.value}  ${e.key}');
    }
    for (final e in (andre.entries.toList()..sort((a, b) => b.value - a.value))) {
      debugPrint('PERF_CENSUS   tick ×${e.value}  ${e.key}');
    }
    lagTelling(tag);
  }

  /// Perf plan (debug/profile): `PERF_LAG` — the composited layers of the
  /// last frame. Each Opacity (unless the engine folds it), ShaderMask,
  /// BackdropFilter, ImageFilter and ColorFilter layer is an offscreen pass
  /// on Impeller, every frame.
  static void lagTelling(String tag) {
    if (kReleaseMode) return;
    final lag = <String, int>{};
    // Debug: who created each offscreen-pass layer (creator chain of the
    // render object that pushed it), to find the widgets behind the passes.
    final eiere = <String, int>{};
    void tell(Layer? l) {
      if (l == null) return;
      final k = l.runtimeType.toString();
      lag[k] = (lag[k] ?? 0) + 1;

      if (l is ContainerLayer) {
        for (Layer? c = l.firstChild; c != null; c = c.nextSibling) {
          tell(c);
        }
      }
    }
    for (final v in RendererBinding.instance.renderViews) {
      // ignore: invalid_use_of_protected_member
      tell(v.layer);
    }
    debugPrint('PERF_LAG $tag ${(lag.entries.toList()..sort((a, b) => b.value - a.value)).map((e) => '${e.key}=${e.value}').join(' ')}');
    // Debug: the render objects that push an offscreen pass this frame
    // (partial opacity, fades, shader masks, backdrop / image / colour
    // filters), named by the widgets that created them.
    if (kDebugMode) {
      void besok(RenderObject ro) {
        if (ro is RenderOffstage && ro.offstage) return;
        String? art;
        if (ro is RenderOpacity) {
          if (ro.opacity <= 0) return;
          if (ro.opacity < 1 && ro.child != null) art = 'Opacity';
        } else if (ro is RenderAnimatedOpacity) {
          final o = ro.opacity.value;
          if (o <= 0) return;
          if (o < 1 && ro.child != null) art = 'Fade';
        } else if (ro is RenderShaderMask) {
          art = 'ShaderMask';
        } else if (ro is RenderBackdropFilter) {
          if (ro.enabled) art = 'BackdropFilter';
        } else {
          final t = ro.runtimeType.toString();
          if (t.contains('ImageFilter')) art = 'ImageFiltered';
          if (t.contains('ColorFilter')) art = 'ColorFiltered';
        }
        if (art != null) {
          String hvem = '?';
          final c = ro.debugCreator;
          if (c is DebugCreator) {
            hvem = c.element.debugGetCreatorChain(24).split(' ← ').where((w) => !_rammeverk.contains(w.replaceAll(RegExp(r'[-<(].*'), ''))).take(6).join(' ← ');
          }
          final n = '$art: $hvem';
          eiere[n] = (eiere[n] ?? 0) + 1;
        }
        // Only what paints: offstage overlay entries (covered routes) and
        // hidden IndexedStack children are skipped like the semantics walk
        // skips them; Offstage subtrees above.
        final t = ro.runtimeType.toString();
        if (t == '_RenderTheater' || ro is RenderIndexedStack) {
          ro.visitChildrenForSemantics(besok);
        } else {
          ro.visitChildren(besok);
        }
      }
      for (final v in RendererBinding.instance.renderViews) {
        besok(v);
      }
    }
    final alle = eiere.values.fold<int>(0, (a, b) => a + b);
    if (kDebugMode) debugPrint('PERF_LAG   offscreen-pass render objects: $alle');
    for (final e in (eiere.entries.toList()..sort((a, b) => b.value - a.value)).take(40)) {
      debugPrint('PERF_LAG   ×${e.value}  ${e.key}');
    }
  }

  static const Set<String> _rammeverk = {
    'LfLoop', 'OnbLoopClock', 'BergenLoop', 'Positioned', 'IgnorePointer', 'Transform', 'Opacity', 'Stack', 'SizedBox', 'Padding', 'Align',
    'Center', 'RepaintBoundary', 'ValueListenableBuilder', 'Builder', 'LayoutBuilder', 'KeyedSubtree', 'Semantics', 'GestureDetector',
    'DecoratedBox', 'Container', 'ClipRRect', 'ClipPath', 'ClipRect', 'FittedBox', 'OverflowBox', 'Expanded', 'Flexible', 'Row', 'Column',
    'AnimatedBuilder', 'ListenableBuilder', 'CustomPaint', 'Positioned.fill', 'MouseRegion', 'Listener', 'Material', 'InkWell',
    'Visibility', 'AnimatedOpacity', 'AnimatedPositioned', 'FadeTransition', 'SlideTransition', 'ScaleTransition', 'DefaultTextStyle',
    'MediaQuery', 'Directionality', 'TickerMode', 'Offstage', 'ConstrainedBox', 'LimitedBox', 'AspectRatio', 'Wrap', 'Flex',
    'SingleChildScrollView', 'ListView', 'Scrollable', 'NotificationListener', 'PageView', 'CssBox', 'LfFrame', 'OnbMaal',
    'BergenEssential', 'Text', 'RichText', '_GestureSemantics', 'RawGestureDetector', '_CssPaint', '_EffectiveTickerMode', 'AnimatedScale',
    'AnimatedRotation', 'RotationTransition', 'TweenAnimationBuilder', 'IndexedStack', 'Image', 'RawImage', 'SvgPicture', 'Icon',
    'ShaderMask', 'ImageFiltered', 'Transform.scale',
  };

  /// Perf plan: the top route and the Bergen tab, for the heartbeat.
  static final PerfRuteObserver ruter = PerfRuteObserver();
  static ValueListenable<int>? fane;

  static double _battery = -1, _battTemp = -1, _headroom = -1;

  /// Perf plan: extra fields for the heartbeat (e.g. CssBake's hit counts).
  static final List<String Function()> pulsTillegg = [];

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
    if (!kReleaseMode) _PerfFil.start();
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
    // The frame watchdog (parity plan §3) stepped the tier down on slow
    // frames — in practice it judged every phone whose GPU cannot hold
    // Hjem at 60 fps as "slow" within 20 s of launch and switched all
    // animation off (`still`) for the rest of the session, with no way
    // back. Off by default since 2026-11-04; the thermal, low-power and
    // reduced-motion tiers are untouched. `--dart-define=AE_WATCHDOG=true`
    // turns it back on for an experiment.
    if ((kReleaseMode || kProfileMode) && vakthund) {
      SchedulerBinding.instance.addTimingsCallback(_Watchdog.onTimings);
    }
    if (!kReleaseMode) _Puls.start();
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
    if (args['battery'] is num) _battery = (args['battery'] as num).toDouble();
    if (args['batteryTemp'] is num) _battTemp = (args['batteryTemp'] as num).toDouble();
    if (args['thermalHeadroom'] is num) _headroom = (args['thermalHeadroom'] as num).toDouble();
    if (_started) _update();
  }

  /// Debug harness only (`perf` in `hjem_state.json`): pin a tier, or null
  /// to go back to the automatic one.
  static void force(BergenTier? t) {
    if (kReleaseMode) return;
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

  /// Perf plan: off-screen rest on/off (harness `hvile: false` for A/B).
  static bool hvilePaa = true;

  /// Perf plan: scenes fully covered by an opaque sheet are not painted
  /// (Offstage) — harness `dekket: false` paints them as before (A/B).
  static bool dekketPaa = true;

  /// Perf plan: true when [context]'s render box lies wholly outside the
  /// screen (plus [margin] logical px on every side), false when it is not
  /// laid out yet. A loop or a live scene that is off the screen stops
  /// producing frames; its clock keeps wall time, so it comes back at the
  /// pose the design would show. Cheap enough for a check every few frames.
  static bool utenforSkjerm(BuildContext context, {double margin = 200}) {
    if (!hvilePaa) return false;
    final ro = context.findRenderObject();
    if (ro is! RenderBox || !ro.attached || !ro.hasSize) return false;
    final view = View.maybeOf(context) ?? ui.PlatformDispatcher.instance.implicitView;
    if (view == null) return false;
    final screen = view.physicalSize / view.devicePixelRatio;
    final Rect r;
    try {
      r = MatrixUtils.transformRect(ro.getTransformTo(null), Offset.zero & ro.size);
    } catch (_) {
      return false;
    }
    return !r.overlaps((Offset.zero & screen).inflate(margin));
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

  /// Whether a backdrop blur runs: off in `still`. A [secondary] blur (glass
  /// on a chip, card, bubble or bar, on top of the screen's own sheet or
  /// panel) runs only in `full`, so `lite` keeps at most one per screen
  /// (parity plan §3.1).
  static bool blurOn(BuildContext context, {bool secondary = false}) =>
      secondary ? of(context) == BergenTier.full : of(context) != BergenTier.still;

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

  /// A one-shot state transition (a focus ring, a press): the prototype's
  /// time in `full` and `lite`, none in `still` (it jumps to the end state).
  static Duration oneShot(BuildContext context, int ms) =>
      of(context) == BergenTier.still ? Duration.zero : Duration(milliseconds: ms);
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

  /// `--dart-define=AE_FRAME_LOG=true`: every 5 s window's frame times to the
  /// log (`PERF_FRAMES`), for measuring scroll smoothness on a phone.
  static const bool _log = bool.fromEnvironment('AE_FRAME_LOG');
  static final List<int> _buildUs = [], _rasterUs = [];

  static void onTimings(List<ui.FrameTiming> timings) {
    if (!BergenPerf.foreground.value) return;
    for (final t in timings) {
      _us.add(t.totalSpan.inMicroseconds);
      if (_log) {
        _buildUs.add(t.buildDuration.inMicroseconds);
        _rasterUs.add(t.rasterDuration.inMicroseconds);
      }
    }
    final now = DateTime.now().microsecondsSinceEpoch;
    if (_windowStart == 0) _windowStart = now;
    if (now - _windowStart < 5000000 || _us.length < 30) return;
    _us.sort();
    final p90 = _us[(_us.length * .9).floor().clamp(0, _us.length - 1)];
    if (_log) {
      int pct(List<int> l, double p) => (l..sort())[(l.length * p).floor().clamp(0, l.length - 1)];
      final over = _us.where((u) => u > 16700).length;
      debugPrint('PERF_FRAMES n=${_us.length} over16ms=$over p50=${pct(_us, .5) ~/ 1000}ms p90=${p90 ~/ 1000}ms '
          'p99=${pct(_us, .99) ~/ 1000}ms build_p90=${pct(_buildUs, .9) ~/ 1000}ms raster_p90=${pct(_rasterUs, .9) ~/ 1000}ms tier=${BergenPerf.tier.value.name}');
      _buildUs.clear();
      _rasterUs.clear();
    }
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

/// Perf plan: rests a live scene's ticker while the scene's box is off the
/// screen and wakes it the moment it is back (the nearest scroll position
/// and a 120 ms timer). [onVaakn] gets the rest in seconds, so the host's
/// clock carries on as if it had never stopped — the same pose the design
/// would show, no frames rendered meanwhile.
class PerfHvile {
  PerfHvile(this.context, this.ticker, {required this.onVaakn});

  final BuildContext context;
  final Ticker ticker;
  final void Function(double sekunder) onVaakn;

  int _tikk = 0;
  Stopwatch? _sw;
  Timer? _t;
  ScrollPosition? _rull;

  bool get hviler => _sw != null;

  /// From the ticker callback: true when the host has just gone to rest.
  bool tikk() {
    if (++_tikk % 12 != 0 || !BergenPerf.utenforSkjerm(context)) return false;
    hvile();
    return true;
  }

  void hvile() {
    if (!ticker.isActive || _sw != null) return;
    ticker.stop();
    _sw = Stopwatch()..start();
    _t = Timer.periodic(const Duration(milliseconds: 120), (_) => _sjekk());
    _rull = Scrollable.maybeOf(context)?.position;
    _rull?.addListener(_sjekk);
  }

  void _sjekk() {
    if (!context.mounted || ticker.muted) return;
    if (BergenPerf.utenforSkjerm(context)) return;
    vaakn();
  }

  /// Back from the rest; [start] false leaves the ticker stopped (reduced
  /// motion, a tier without this scene).
  void vaakn({bool start = true}) {
    _t?.cancel();
    _t = null;
    _rull?.removeListener(_sjekk);
    _rull = null;
    final sw = _sw;
    _sw = null;
    if (sw == null) return;
    onVaakn(sw.elapsedMicroseconds / 1e6);
    if (start && !ticker.isActive) ticker.start();
  }

  void dispose() {
    _t?.cancel();
    _rull?.removeListener(_sjekk);
  }
}

/// Perf plan: the top route's name, for the heartbeat (`navigatorObservers`).
class PerfRuteObserver extends NavigatorObserver {
  String rute = '-';

  void _sett(Route<dynamic>? r) {
    rute = r?.settings.name ?? r?.runtimeType.toString() ?? '-';
    if (!kReleaseMode) debugPrint('PERF_RUTE $rute tickers=${SchedulerBinding.instance.transientCallbackCount}');
    if (kDebugMode) {
      final navn = rute;
      Future<void>.delayed(const Duration(seconds: 4), () => BergenPerf.tickerCensus('rute=$navn'));
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _sett(route);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _sett(previousRoute);
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _sett(previousRoute);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _sett(newRoute);
}

/// Perf plan (debug / profile only): mirrors the perf and harness lines
/// (`PERF_*`, `HJEM_*`, `ONB_*`) into `<app documents>/perf_log.txt`, each
/// with its wall-clock ms, so they can be read with `run-as` on phones whose
/// vendor build drops app logs from logcat (Vivo: `persist.sys.log.ctrl=no`).
/// Compiles out of release builds.
abstract final class _PerfFil {
  static IOSink? _ut;
  static final List<String> _venter = [];

  static void start() {
    final orig = debugPrint;
    debugPrint = (String? m, {int? wrapWidth}) {
      orig(m, wrapWidth: wrapWidth);
      if (m == null) return;
      if (!(m.startsWith('PERF_') || m.startsWith('HJEM_') || m.startsWith('ONB_'))) return;
      final l = '${DateTime.now().millisecondsSinceEpoch} $m';
      final ut = _ut;
      if (ut == null) {
        _venter.add(l);
      } else {
        ut.writeln(l);
      }
    };
    getApplicationDocumentsDirectory().then((dir) {
      final ut = File('${dir.path}/perf_log.txt').openWrite(mode: FileMode.append);
      ut.writeln('${DateTime.now().millisecondsSinceEpoch} PERF_START');
      _venter.forEach(ut.writeln);
      _venter.clear();
      _ut = ut;
    }).catchError((Object _) {});
  }
}

/// Perf plan (debug / profile only): one `PERF_HEARTBEAT` line every 30 s with
/// the thermal state, battery, tier, achieved refresh rate, frames drawn,
/// frame-time percentiles, RSS, active tickers and mounted loops — the
/// software baseline of the heat plan. Compiles out of release builds.
abstract final class _Puls {
  static const Duration every = Duration(seconds: 30);
  static final Stopwatch _klokke = Stopwatch();
  static final List<int> _total = [], _build = [], _raster = [], _vsync = [];
  static int _sistVsync = 0;
  static Timer? _timer;

  static void start() {
    if (_timer != null) return;
    _klokke.start();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    _timer = Timer.periodic(every, (_) => _slaa());
  }

  static void _onTimings(List<ui.FrameTiming> timings) {
    for (final t in timings) {
      _total.add(t.totalSpan.inMicroseconds);
      _build.add(t.buildDuration.inMicroseconds);
      _raster.add(t.rasterDuration.inMicroseconds);
      final v = t.timestampInMicroseconds(ui.FramePhase.vsyncStart);
      if (_sistVsync > 0 && v > _sistVsync) _vsync.add(v - _sistVsync);
      _sistVsync = v;
    }
  }

  static int _pct(List<int> l, double p) {
    if (l.isEmpty) return 0;
    final s = List<int>.of(l)..sort();
    return s[(s.length * p).floor().clamp(0, s.length - 1)];
  }

  static Future<void> _slaa() async {
    if (!BergenPerf.foreground.value) return;
    try {
      final info = await BergenPerf._channel.invokeMapMethod<String, Object?>('info');
      if (info != null) BergenPerf._readState(info);
    } catch (_) {}
    final n = _total.length;
    final over = _total.where((u) => u > 16700).length;
    // The vsync cadence the frames actually came at (the panel's rate while
    // anything moved), from the median vsync-to-vsync gap.
    final gap = _pct(_vsync, .5);
    final hz = gap > 0 ? (1e6 / gap).round() : 0;
    final fps = (n / every.inSeconds).toStringAsFixed(1);
    final rss = ProcessInfo.currentRss ~/ (1024 * 1024);
    String na(double v, [int d = 0]) => v < 0 ? 'n/a' : v.toStringAsFixed(d);
    debugPrint('PERF_HEARTBEAT t=${_klokke.elapsed.inSeconds} rute=${BergenPerf.ruter.rute} fane=${BergenPerf.fane?.value ?? '-'} '
        'thermal=${BergenPerf._thermal} lowPower=${BergenPerf._lowPower} battery=${na(BergenPerf._battery)} battTemp=${na(BergenPerf._battTemp, 1)} '
        'headroom=${na(BergenPerf._headroom, 2)} tier=${BergenPerf.tier.value.name} renderer=${ui.ImageFilter.isShaderFilterSupported ? 'impeller' : 'skia'} hz=$hz fps=$fps frames=$n over16=$over '
        'build_p50=${_pct(_build, .5) ~/ 1000} build_p90=${_pct(_build, .9) ~/ 1000} raster_p50=${_pct(_raster, .5) ~/ 1000} raster_p90=${_pct(_raster, .9) ~/ 1000} '
        'rss=$rss tickers=${SchedulerBinding.instance.transientCallbackCount} loops=${BergenPerf.lfLoopsMounted + BergenPerf.onbLoopsMounted}'
        '${BergenPerf.pulsTillegg.map((f) => ' ${f()}').join()}');
    _total.clear();
    _build.clear();
    _raster.clear();
    _vsync.clear();
    final hvor = 'puls rute=${BergenPerf.ruter.rute} fane=${BergenPerf.fane?.value ?? '-'}';
    if (kDebugMode) {
      BergenPerf.tickerCensus(hvor);
    } else {
      BergenPerf.lagTelling(hvor);
    }
  }
}
