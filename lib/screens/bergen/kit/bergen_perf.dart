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

/// The app-wide motion tier: chosen at start-up from the device class and
/// the user's own low power mode / battery saver, stepped down by a frame
/// watchdog in profile / release builds (off unless `AE_WATCHDOG`). Konto's
/// «Roligere bevegelse» and the OS reduce motion setting always mean `still`
/// (they arrive as `MediaQuery.disableAnimations`). Heat plan Step 12: the
/// thermal state never changes the tier (plan §0.2); it only reaches the
/// heartbeat (`thermal=`), unless [varmeTrinnGammel] brings back the old
/// step-down for an A/B run.
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
    'ShaderMask', 'ImageFiltered', 'Transform.scale', 'MalerVert',
  };

  /// Perf plan: the top route and the Bergen tab, for the heartbeat.
  static final PerfRuteObserver ruter = PerfRuteObserver();
  static ValueListenable<int>? fane;

  static double _battery = -1, _battTemp = -1, _headroom = -1;

  /// Perf plan: extra fields for the heartbeat (e.g. CssBake's hit counts).
  static final List<String Function()> pulsTillegg = [];

  /// Heat plan Step 4 check (debug/profile): shader renders per host since the
  /// last heartbeat, printed as `render=SpGl:31,Sjo:60` — the render cadence must
  /// be the same with `stegRammer` on and off.
  static final Map<String, int> _renders = {};
  static bool _rendersReg = false;
  static void telRender(String navn) {
    if (kReleaseMode) return;
    _renders[navn] = (_renders[navn] ?? 0) + 1;
    if (_rendersReg) return;
    _rendersReg = true;
    pulsTillegg.add(() {
      final s = _renders.entries.map((e) => '${e.key}:${e.value}').join(',');
      _renders.clear();
      return 'render=${s.isEmpty ? '-' : s}';
    });
  }

  static BergenTier _device = BergenTier.full;
  static String _deviceWhy = 'device';
  static bool _lowPower = false;
  // 0 nominal · 1 fair · 2 serious · 3 critical: for the heartbeat only
  // (and [varmeTrinnGammel]), never the tier (Heat plan Step 12).
  static int _thermal = 0;
  // Heat ladder: the platform's own thermal status (Android PowerManager
  // 0–6, iOS ProcessInfo 0–3; -1 until reported), which tells Android's
  // light from moderate (both are `_thermal` 1).
  static int _status = -1;
  static bool _android = defaultTargetPlatform == TargetPlatform.android;
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
    // back. Off by default since 2026-11-04; the low-power and reduced-motion
    // tiers are untouched (heat: Step 12). `--dart-define=AE_WATCHDOG=true`
    // turns it back on for an experiment.
    if ((kReleaseMode || kProfileMode) && vakthund) {
      SchedulerBinding.instance.addTimingsCallback(_Watchdog.onTimings);
    }
    if (!kReleaseMode) _Puls.start();
    _update();
    // Idle slow-down: the count starts with the app.
    _planleggLedig();
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
    if (args['platform'] is String) _android = args['platform'] == 'android';
    if (args['lowPower'] is bool) _lowPower = args['lowPower'] as bool;
    if (args['thermal'] is num) _thermal = (args['thermal'] as num).toInt();
    if (args['thermalStatus'] is num) _status = (args['thermalStatus'] as num).toInt();
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

  /// Heat plan Step 12 (harness `varmeTrinn: true`, A/B measurement only):
  /// the old thermal step-down — fair → `lite`, serious / critical → `still`.
  /// False (always, outside the harness): heat never changes the motion.
  static bool varmeTrinnGammel = false;

  /// The tier and its reason for these inputs (what [_update] applies).
  @visibleForTesting
  static (BergenTier, String) velg({
    BergenTier device = BergenTier.full,
    String deviceWhy = 'device',
    int watchdogSteps = 0,
    int thermal = 0,
    bool lowPower = false,
    BergenTier? forced,
    bool varmeTrinn = false,
    int varme = 0,
  }) {
    BergenTier t = device;
    var why = deviceWhy;
    BergenTier raise(BergenTier a, BergenTier b) => a.index >= b.index ? a : b;
    if (watchdogSteps > 0) {
      final w = BergenTier.values[math.min(2, watchdogSteps)];
      if (w.index > t.index) why = 'slow frames ×$watchdogSteps';
      t = raise(t, w);
    }
    // Heat ladder (2026-11-10): only at critical does heat stop the motion;
    // hot (level 1) keeps the tier and lowers the decorative cadence instead
    // (PerfTakt). The old step-down only for an A/B run.
    if (!varmeTrinn && varme >= 2) {
      t = BergenTier.still;
      why = 'thermal critical';
    }
    if (varmeTrinn) {
      if (thermal >= 2) {
        t = BergenTier.still;
        why = 'thermal $thermal';
      } else if (thermal == 1 && t == BergenTier.full) {
        t = BergenTier.lite;
        why = 'thermal fair';
      }
    }
    // The user's own Low Power Mode (iOS) / battery saver (Android), plan D1.
    if (lowPower) {
      t = BergenTier.still;
      why = 'low power mode';
    }
    if (forced != null) {
      t = forced;
      why = 'forced';
    }
    return (t, why);
  }

  /// Test only: new thermal / low power readings, as the platform channel
  /// would bring them, applied at once.
  @visibleForTesting
  static void debugTilstand({int? thermal, bool? lowPower}) {
    if (thermal != null) _thermal = thermal;
    if (lowPower != null) _lowPower = lowPower;
    _update();
  }

  /// Heat plan Step 12 (harness `termisk: 0..3`, debug / profile only): a
  /// thermal state injected as if the platform channel had reported it, so a
  /// device check can force fair / serious / critical. The real readings
  /// keep arriving underneath; null goes back to them at once.
  static int? get termisk => _termisk;
  static int? _termisk;

  static void termiskTvang(int? thermal, {int? status}) {
    if (kReleaseMode) return;
    _termisk = thermal?.clamp(0, 3);
    _termiskStatus = status?.clamp(0, 6);
    _update();
  }

  /// Heat ladder (harness `termiskStatus`, debug / profile only): a raw
  /// platform status injected (Android 2 = moderate, which `termisk` cannot
  /// tell from light). Wins over [termisk].
  static int? get termiskStatus => _termiskStatus;
  static int? _termiskStatus;

  /// The thermal state in force: the injected one, else the platform's.
  static int get _thermalNaa => _termisk ?? _thermal;

  // The raw status for a mapped state (0 nominal · 1 fair · 2 serious ·
  // 3 critical): on Android fair stands for light, serious for severe.
  static int _statusFor(int thermal) => _android ? const [0, 1, 3, 4][thermal.clamp(0, 3)] : thermal.clamp(0, 3);

  /// The raw platform status in force: injected, else reported, else (an
  /// older native side) from the mapped state.
  static int get _statusNaa {
    if (_termiskStatus case final s?) return s;
    if (_termisk case final t?) return _statusFor(t);
    return _status >= 0 ? _status : _statusFor(_thermal);
  }

  /// Heat ladder (approved 2026-11-10): the heat level for a raw platform
  /// status. Android `PowerManager` (0 none · 1 light · 2 moderate · 3 severe
  /// · 4 critical · 5 emergency · 6 shutdown): moderate / severe = 1,
  /// critical and above = 2. iOS `ProcessInfo.ThermalState` (0 nominal ·
  /// 1 fair · 2 serious · 3 critical): serious = 1, critical = 2. Android
  /// light and iOS fair stay 0 (the Vivo reports light after minutes on its
  /// charger).
  static int varmeFor(int status, {required bool android}) =>
      android ? (status >= 4 ? 2 : (status >= 2 ? 1 : 0)) : (status >= 3 ? 2 : (status == 2 ? 1 : 0));

  /// The heat level in force: 0 normal, 1 hot (decorative motion at 30 fps,
  /// [PerfTakt]), 2 critical (all motion off). It rises at once; it falls one
  /// level at a time, each only after the cooler reading has held for
  /// [varmeNed] (no flapping at a threshold).
  static final ValueNotifier<int> varme = ValueNotifier<int>(0);

  /// Harness `varmeStige: false` (A/B): heat never changes the motion, as
  /// after Step 12. True (the default): the ladder.
  static bool varmeStigePaa = true;

  /// How long a cooler reading must hold before the level steps down
  /// (harness `varmeNedSek`).
  static Duration varmeNed = const Duration(seconds: 60);
  static Timer? _nedTimer;

  static int get _varmeMaal => varmeStigePaa && !varmeTrinnGammel ? varmeFor(_statusNaa, android: _android) : 0;

  /// Applies a new reading to [varme] (called from [_update]; changes the
  /// level only, the tier follows in [_update]).
  static void _vurderVarme() {
    final maal = _varmeMaal;
    final naa = varme.value;
    // Ladder off: back at once (A/B).
    if (maal >= naa || !varmeStigePaa || varmeTrinnGammel) {
      _nedTimer?.cancel();
      _nedTimer = null;
      if (maal != naa) _settVarme(maal);
      return;
    }
    _nedTimer ??= Timer(varmeNed, () {
      _nedTimer = null;
      if (_varmeMaal < varme.value) _settVarme(varme.value - 1);
      _update();
    });
  }

  static void _settVarme(int n) {
    varme.value = n;
    if (!kReleaseMode) debugPrint('PERF_VARME $n status=$_statusNaa');
  }

  /// Test only: the hysteresis timer is pending.
  @visibleForTesting
  static bool get debugVarmeVenter => _nedTimer != null;

  // ── Idle slow-down (approved 2026-11-10, point 6) ──

  /// After this long without a touch the decorative motion runs at 30 fps
  /// ([PerfTakt]); the next touch brings it back at once. Zero = off
  /// (harness `ledigSek`).
  static Duration ledigEtter = const Duration(seconds: 30);

  /// True while nobody has touched the screen for [ledigEtter].
  static final ValueNotifier<bool> ledig = ValueNotifier<bool>(false);
  static final Stopwatch _sw = Stopwatch()..start();

  /// The clock of the idle count, in µs (a test puts its fake clock here).
  @visibleForTesting
  static int Function() debugTidUs = () => _sw.elapsedMicroseconds;
  static int _beroertUs = 0;
  static Duration get _siden => Duration(microseconds: debugTidUs() - _beroertUs);
  static Timer? _ledigTimer;

  /// A touch, a route change or the app coming back: the idle slow-down
  /// ends at once and the count starts again. Cheap (pointer moves call it).
  static void beroering() {
    _beroertUs = debugTidUs();
    if (ledig.value) {
      ledig.value = false;
      if (!kReleaseMode) debugPrint('PERF_LEDIG off');
      _takt();
    }
    _planleggLedig();
  }

  static void _planleggLedig() {
    if (ledigEtter <= Duration.zero) {
      _ledigTimer?.cancel();
      _ledigTimer = null;
      if (ledig.value) {
        ledig.value = false;
        _takt();
      }
      return;
    }
    if (ledig.value || _ledigTimer != null) return;
    final rest = ledigEtter - _siden;
    _ledigTimer = Timer(rest.isNegative ? Duration.zero : rest, _ledigSjekk);
  }

  static void _ledigSjekk() {
    _ledigTimer = null;
    if (ledigEtter <= Duration.zero || ledig.value) return;
    // Typing (the keyboard is up) or in the background: not idle.
    final tastatur = ui.PlatformDispatcher.instance.views.any((v) => v.viewInsets.bottom > 0);
    if (tastatur || !foreground.value) _beroertUs = debugTidUs();
    if (_siden < ledigEtter) {
      _planleggLedig();
      return;
    }
    ledig.value = true;
    if (!kReleaseMode) debugPrint('PERF_LEDIG on');
    _takt();
  }

  /// Heat ladder (harness `taktViktig`; decision pending, off = the approved
  /// scope): essential loops — the live-order pill, loaders, typing dots, the
  /// tour cue, the Sporing map — follow the 30 fps takt too; only games
  /// ([BergenEssential.spill]) keep every vsync. Off: essential loops keep
  /// every vsync (and with them the whole screen, while one is visible).
  static bool taktViktigPaa = false;

  /// Whether a loop at [context] follows the takt ([essential]: its own flag).
  static bool paaTakt(BuildContext context, {required bool essential}) =>
      taktViktigPaa ? !BergenEssential.spillInni(context) : !essential && !BergenEssential.inside(context);

  /// How long after a touch automatic decoration on animation controllers
  /// ([PerfTaktTikker]) stays at every vsync.
  static const Duration roligEtter = Duration(seconds: 2);

  /// Nobody has touched the screen for [roligEtter].
  static bool get urort => _siden >= roligEtter;

  /// Harness `takt: true` (debug / profile): the 30 fps cadence on without
  /// heat or idle, for measuring it.
  static bool taktTvang = false;

  /// Puts [PerfTakt] on while hot (level 1 and up) or idle; off under the
  /// frozen test clock.
  static void _takt() {
    final grunn = frosset
        ? null
        : taktTvang
            ? 'tvang'
            : varme.value >= 1
                ? 'varme'
                : ledig.value
                    ? 'ledig'
                    : null;
    PerfTakt._sett(grunn);
  }

  /// Harness (debug / profile): the ladder's switches — [stige] the ladder
  /// itself, [nedSek] its hold, [ledigSek] the idle slow-down (0 = off),
  /// [takt] the cadence forced on.
  static void settStige({required bool stige, required int nedSek, required int ledigSek, required bool takt}) {
    if (kReleaseMode) return;
    varmeStigePaa = stige;
    varmeNed = Duration(seconds: math.max(0, nedSek));
    taktTvang = takt;
    final ny = Duration(seconds: math.max(0, ledigSek));
    if (ny != ledigEtter) {
      ledigEtter = ny;
      _ledigTimer?.cancel();
      _ledigTimer = null;
      ledig.value = false;
      _beroertUs = debugTidUs();
      _planleggLedig();
    }
    _update();
  }

  /// Harness `rammeSek: true` (debug / profile): `PERF_RAMMER` every second —
  /// frames drawn that second, takt frames, the takt's reason — so a device
  /// check sees 30 while only decoration moves and 60 under a scroll or tap.
  static void rammeSek(bool paa) {
    if (kReleaseMode) return;
    _rammeSekTimer?.cancel();
    _rammeSekTimer = null;
    if (_rammeSekCb != null) SchedulerBinding.instance.removeTimingsCallback(_rammeSekCb!);
    _rammeSekCb = null;
    if (!paa) return;
    var n = 0, takt0 = PerfTakt.rammer;
    _rammeSekCb = (ts) => n += ts.length;
    SchedulerBinding.instance.addTimingsCallback(_rammeSekCb!);
    // Frames the framework began (n counts what the engine reported).
    if (!_rammeBegynt) {
      _rammeBegynt = true;
      SchedulerBinding.instance.addPersistentFrameCallback((_) => _begynt++);
    }
    var b0 = _begynt;
    _rammeSekTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // (The heartbeat zeroes PerfTakt.rammer every 30 s.)
      final tk = PerfTakt.rammer >= takt0 ? PerfTakt.rammer - takt0 : PerfTakt.rammer;
      takt0 = PerfTakt.rammer;
      final b = _begynt - b0;
      b0 = _begynt;
      debugPrint('PERF_RAMMER n=$n b=$b takt=$tk grunn=${PerfTakt.grunn ?? 'av'} varme=${varme.value} ledig=${ledig.value}');
      n = 0;
    });
  }

  static Timer? _rammeSekTimer;
  static bool _rammeBegynt = false;
  static int _begynt = 0;
  static TimingsCallback? _rammeSekCb;

  /// Test only: back to the start state of the ladder and the idle count.
  @visibleForTesting
  static void debugNullstillStige() {
    _nedTimer?.cancel();
    _nedTimer = null;
    _ledigTimer?.cancel();
    _ledigTimer = null;
    varme.value = 0;
    ledig.value = false;
    varmeStigePaa = true;
    varmeNed = const Duration(seconds: 60);
    ledigEtter = const Duration(seconds: 30);
    taktTvang = false;
    _status = -1;
    _termiskStatus = null;
    _beroertUs = debugTidUs();
    _takt();
  }

  /// Test only: a raw platform status as the channel would bring it.
  @visibleForTesting
  static void debugStatus(int status, {bool? android}) {
    if (android != null) _android = android;
    _status = status;
    _update();
  }

  /// Test only: re-arm the idle count (as [start] does).
  @visibleForTesting
  static void debugStartLedig() {
    _beroertUs = debugTidUs();
    _planleggLedig();
  }

  static void _update() {
    _vurderVarme();
    final (t, why) = velg(
      device: _device,
      deviceWhy: _deviceWhy,
      watchdogSteps: _watchdogSteps,
      thermal: _thermalNaa,
      lowPower: _lowPower,
      forced: _forced,
      varmeTrinn: varmeTrinnGammel,
      varme: varme.value,
    );
    if (t != tier.value || why != reason) {
      reason = why;
      tier.value = t;
      debugPrint('PERF_TIER ${t.name} $why');
    }
    _takt();
  }

  /// Perf plan: off-screen rest on/off (harness `hvile: false` for A/B).
  static bool hvilePaa = true;

  /// Heat plan Step 2 (harness `usynlig: false` for A/B): invisible work
  /// stops — the nav's hidden Ægil loop, resting loops' wake timers while
  /// their ticker is muted, rail turns on a hidden tab, Sporing / Hjem order
  /// polls in the background. False = everything runs as before.
  static bool usynligPaa = true;

  /// Heat plan Step 2: the app can be seen — resumed, or inactive (a system
  /// sheet or the notification shade over it, still on the screen). Hidden,
  /// paused or detached is the background; no state yet counts as visible.
  static bool get appSynlig {
    final s = WidgetsBinding.instance.lifecycleState;
    return s == null || s == AppLifecycleState.resumed || s == AppLifecycleState.inactive;
  }

  /// Heat plan Step 3: a loop whose design keyframes hold still for part of
  /// each cycle ([LfStille]) stops ticking inside that hold and wakes just
  /// before it ends (harness `pauseSov: false` keeps it ticking, A/B).
  static bool pauseSovPaa = true;

  /// Heat plan Step 3: the wake calls of the loops asleep in a hold, so a
  /// change of [frysMs] or [pauseSovPaa] reaches them at once.
  static final Set<VoidCallback> _sovende = {};

  /// Wakes every loop asleep in a hold (after the harness sets `klokke` or
  /// `pauseSov`).
  static void vekkSovende() {
    for (final v in _sovende.toList()) {
      v();
    }
  }

  /// Heat plan Step 4 (harness `stegRammer: false` for A/B): shader scenes
  /// ask for frames only around their own steps (see [PerfStegRammer]).
  static bool stegRammerPaa = true;

  /// Heat plan Step 6 (harness `malerVert: false` for A/B): shader hosts draw
  /// each new frame through a repaint notifier instead of setState +
  /// LayoutBuilder + RawImage, and the scenes with a static part (Ægil·Fløyen,
  /// Søk's Flesland rock) bake it once and read it back (same pixels).
  static bool malerVertPaa = true;

  /// Heat plan Step 7, three switches so each is measured and decided on its
  /// own (A/B on one build; harness `pass2Klipp`, `pass2Css`, `pass2Bakt`).
  ///
  /// `pass2Klipp` (on): the even-odd clips that keep a CSS shadow outside its
  /// translucent box (BergenCssShadow, CssBox) reach only as far as the
  /// shadows do instead of 400–600 px around the box — the same pixels, a
  /// much smaller clip write per box per frame. False = the big clips.
  static bool pass2KlippPaa = true;

  /// `pass2Css` (off until decided): a CssBox that went live after an
  /// animated entrance returns to CssBake's raster once it has been still for
  /// 600 ms. Changes pixels against today's build wherever that box would
  /// have stayed live (the raster is resampled: up to ~68/255 on edges).
  static bool pass2CssPaa = false;

  /// `pass2Bakt` (off until decided): BergenBakt draws its raster on the
  /// device pixel grid exactly where live painting lands, and paints live
  /// where it cannot (rotation, perspective, moving, clipped). Pixel-exact,
  /// but sites under a moving transform lose their caching.
  static bool pass2BaktPaa = false;

  /// Heat plan Step 8 (harness `lagring: true`; off until the device gates):
  /// every Bergen route's screen sits in a [BergenLagring], which draws the
  /// screen's unchanged bottom run of layers from one cached image. False =
  /// no BergenLagring in the tree at all.
  static bool lagringPaa = false;

  /// Heat plan Step 8 (harness `lagringOvre: true`; off until the device
  /// gates; only with [lagringPaa]): BergenLagring also caches the runs above
  /// a live layer — drawn on transparent and blended, so a translucent pixel
  /// may round by ≤ 1/255 (accepted 2026-11-09). Runs holding a backdrop
  /// filter, and runs beneath a `BergenLagringLive` subtree (blends that read
  /// the screen), stay live. False = only the exact bottom run.
  static bool lagringOvrePaa = false;

  /// Heat plan Step 9 (harness `loopGrense: true`; off until the device
  /// gates): every LfLoop / OnbLoopClock (and so BergenLoop, KatLoop) puts
  /// its animated output in its own repaint boundary, so a moving icon does
  /// not repaint the static picture around it. False = no boundary.
  static bool loopGrensePaa = false;

  /// Heat plan Step 5 (harness `bryggenDeling: false` for A/B): the Bryggen
  /// scene bakes its static city once per weather / form / size and draws
  /// only what moves on top (`shaders/hjem_bryggen_liv.frag`, see
  /// `SpGlDeling`); false = the original `hjem_bryggen.frag` every step.
  static bool bryggenDelingPaa = true;

  /// Heat plan Step 11 (harness `klokke1: true`; off until device-verified):
  /// every `LfLoop` / `OnbLoopClock` ticks from one shared frame callback
  /// (`LfKlokke`) instead of a transient callback of its own — the same
  /// frames, the same elapsed time per loop. The harness moves running loops
  /// over at once (`LfKlokke.byttAlle`). `--dart-define=AE_KLOKKE1=true`
  /// sets the default (a whole test run or build on the clock).
  static const bool klokkeStandard = bool.fromEnvironment('AE_KLOKKE1');
  static bool klokkePaa = klokkeStandard;

  /// Heat plan Step 11 (harness `rammeLoop: true`; off until device-verified):
  /// loops marked `ramme` apply their Transform / Opacity chain to the render
  /// objects they have instead of rebuilding their builder every frame
  /// (`LfRammeBygger`). Read on every tick. `--dart-define=AE_RAMMELOOP=true`
  /// sets the default.
  static const bool rammeLoopStandard = bool.fromEnvironment('AE_RAMMELOOP');
  static bool rammeLoopPaa = rammeLoopStandard;

  /// Heat test (harness `shaderFrys`): shader scenes draw their first frames,
  /// then keep showing the last one while their clock runs on — the upper
  /// bound of what pre-rendered video could save. Debug/profile harness only.
  static bool shaderFrys = false;

  /// Heat plan Step 0 (harness `klokke: <ms>`): every continuous animation
  /// clock — the loops, the shader scenes, the hero water and rod — reads this
  /// fixed time instead of its own, and wall-clock timers (rail turns, coupon
  /// rotation, showcase autoplay, random float ripples) hold still, so two
  /// builds can be compared pixel by pixel on an animated screen. Null = off.
  static double? get frysMs => _frysMs;
  static double? _frysMs;
  static set frysMs(double? v) {
    _frysMs = v;
    frysVarsel.value = v;
    // The frozen clock wants every loop on every frame (no takt).
    _takt();
  }

  /// Fires when the frozen test clock is set or cleared, so a loop that has
  /// not ticked yet (muted under a cover, resting) shows the frozen pose too.
  static final ValueNotifier<double?> frysVarsel = ValueNotifier<double?>(null);
  static bool get frosset => frysMs != null;

  /// Heat test: freeze only one kind — 'vann' (SjoWater) or 'spgl' (SpGl scenes).
  static String? shaderFrysKun;

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
  /// only comes from low power mode / battery saver or a slow phone (or the
  /// old heat step under [varmeTrinnGammel]).
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
/// `MediaQuery`, so it can tell a user's calm setting from low power mode.
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
        // `still` from low power mode (or the device class / watchdog) reuses
        // every helper's reduced-motion path.
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
  const BergenEssential({super.key, this.spill = false, required super.child});

  /// A game: its motion answers taps, so it keeps every vsync under the heat
  /// ladder's takt even with `taktViktig` on.
  final bool spill;

  static bool inside(BuildContext context) =>
      context.getInheritedWidgetOfExactType<BergenEssential>() != null;

  /// Inside a game ([spill]).
  static bool spillInni(BuildContext context) =>
      context.getInheritedWidgetOfExactType<BergenEssential>()?.spill == true;

  @override
  bool updateShouldNotify(BergenEssential old) => false;
}

class _Lifecycle with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    BergenPerf.foreground.value = state == AppLifecycleState.resumed;
    // Back in the foreground counts as a touch (idle slow-down).
    if (state == AppLifecycleState.resumed) BergenPerf.beroering();
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

/// Heat plan Step 2: the 120 ms wake timer of a resting (off-screen) loop.
/// It only runs while the loop's ticker could be heard: a muted ticker (a
/// hidden tab) cannot wake anyway, so the timer is cancelled, and it starts
/// again the moment the ticker is unmuted, with one check right after that
/// frame — no later than the old always-on timer would have woken it.
/// TickerMode reaches tickers through [TickerMode.getNotifier] (the ticker
/// mixins listen to it; it does not call didChangeDependencies), so this
/// listens to the same notifier while the loop rests. [BergenPerf.usynligPaa]
/// false keeps the timer running as before.
class PerfVekker {
  PerfVekker(this.sjekk);

  /// The host's on-screen check (it wakes the loop when it is visible).
  final VoidCallback sjekk;

  Timer? _t;
  ValueListenable<bool>? _modus;
  bool _hviler = false;

  /// The loop has just gone to rest (from its ticker, so it is unmuted).
  void start(BuildContext context) {
    _hviler = true;
    _tid();
    folg(context);
  }

  /// Woken, reduced to still, or disposed: no more checks.
  void stopp() {
    _hviler = false;
    _t?.cancel();
    _t = null;
    _modus?.removeListener(_endret);
    _modus = null;
  }

  /// Follows the TickerMode at [context] (again after a move in the tree:
  /// call it from the host's `activate`).
  void folg(BuildContext context) {
    if (!_hviler) return;
    final n = TickerMode.getNotifier(context);
    if (identical(n, _modus)) return;
    _modus?.removeListener(_endret);
    _modus = n..addListener(_endret);
    _endret();
  }

  void _tid() {
    _t ??= Timer.periodic(const Duration(milliseconds: 120), (_) => sjekk());
  }

  void _endret() {
    final m = _modus;
    if (!_hviler || m == null) return;
    if (m.value) {
      if (_t != null) return;
      _tid();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (_hviler) sjekk();
      });
    } else if (BergenPerf.usynligPaa) {
      _t?.cancel();
      _t = null;
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
  late final PerfVekker _t = PerfVekker(_sjekk);
  ScrollPosition? _rull;

  bool get hviler => _sw != null;

  /// From the ticker callback: true when the host has just gone to rest.
  /// [n] is the number of vsyncs since the last tick (more than one after a
  /// [PerfStegRammer] sleep), so the check still comes every 12 vsyncs.
  bool tikk({int n = 1}) {
    final f = _tikk;
    _tikk += n;
    if (_tikk ~/ 12 == f ~/ 12 || !BergenPerf.utenforSkjerm(context)) return false;
    hvile();
    return true;
  }

  void hvile() {
    if (!ticker.isActive || _sw != null) return;
    ticker.stop();
    _sw = Stopwatch()..start();
    _t.start(context);
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
    _t.stopp();
    _rull?.removeListener(_sjekk);
    _rull = null;
    final sw = _sw;
    _sw = null;
    if (sw == null) return;
    onVaakn(sw.elapsedMicroseconds / 1e6);
    if (start && !ticker.isActive) ticker.start();
  }

  void dispose() {
    _t.stopp();
    _rull?.removeListener(_sjekk);
  }
}

/// Heat plan Step 3: where a loop's builder output does not change. [fra] –
/// [til] (and each pair in [mer]) are open intervals of the cycle's phase
/// `((t - forsinkelseMs) / periodeMs) % 1.0` — the phase `kfLoop` /
/// `onbLoop` hand the builders — inside which the builder draws one pose.
/// [foer]: the builder also draws one fixed picture before the delay
/// (`t < forsinkelseMs`; not necessarily the hold's).
@immutable
class LfStille {
  const LfStille({
    required this.periodeMs,
    required this.fra,
    required this.til,
    this.forsinkelseMs = 0,
    this.foer = false,
    this.mer = const [],
  });

  final double periodeMs, fra, til, forsinkelseMs;
  final bool foer;

  /// More still intervals, as `[fra, til, fra, til, …]`.
  final List<double> mer;

  /// Ms (on [t]'s clock) left of the still stretch [t] lies in, or null when
  /// [t] is in motion.
  double? igjen(double t) {
    final e = t - forsinkelseMs;
    if (e < 0) return foer ? -e : null;
    final p = (e / periodeMs) % 1.0;
    double? slutt;
    if (p > fra && p < til) slutt = til;
    for (var i = 0; slutt == null && i + 1 < mer.length; i += 2) {
      if (p > mer[i] && p < mer[i + 1]) slutt = mer[i + 1];
    }
    return slutt == null ? null : (slutt - p) * periodeMs;
  }

  @override
  bool operator ==(Object other) =>
      other is LfStille && other.periodeMs == periodeMs && other.fra == fra && other.til == til && other.forsinkelseMs == forsinkelseMs && other.foer == foer && listEquals(other.mer, mer);

  @override
  int get hashCode => Object.hash(periodeMs, fra, til, forsinkelseMs, foer, Object.hashAll(mer));
}

/// Heat plan Step 3: puts a loop's ticker to sleep while its [LfStille] says
/// the picture holds still. The tick that lands inside a hold is drawn (the
/// host has set its value), then the ticker stops and a one-shot timer wakes
/// the host [vekkFoerMs] before the hold ends, so the first moving frame is
/// on time; the host carries its clock on in wall time. Holds shorter than
/// [minMs] are not slept through (and so the ticks after a wake do not sleep
/// again). Off with [BergenPerf.pauseSovPaa] false or under the frozen clock.
class PerfSov {
  PerfSov(this.ticker, {required this.onVaakn});

  final Ticker ticker;

  /// Restarts the host's ticker (unless reduced motion / resting says no).
  final VoidCallback onVaakn;

  static const double vekkFoerMs = 50, minMs = 100;

  Timer? _timer;

  bool get sover => _timer != null;

  /// From the tick, after the frame's value is set: true when the ticker has
  /// just been stopped for a hold. [tidsfaktor] turns [t]'s ms into wall ms
  /// (`timeDilation` for ticker time).
  bool tikk(LfStille? s, double t, {double tidsfaktor = 1}) {
    if (s == null || !BergenPerf.pauseSovPaa || BergenPerf.frosset || !ticker.isActive || _timer != null) return false;
    final ms = s.igjen(t);
    if (ms == null || ms < minMs) return false;
    ticker.stop();
    _timer = Timer(Duration(microseconds: ((ms - vekkFoerMs) * tidsfaktor * 1000).round()), vaakn);
    BergenPerf._sovende.add(vaakn);
    return true;
  }

  /// Ends the sleep now and lets the host restart.
  void vaakn() {
    if (_timer == null) return;
    avbryt();
    onVaakn();
  }

  /// Ends the sleep without waking the host (reduced motion, dispose).
  void avbryt() {
    _timer?.cancel();
    _timer = null;
    BergenPerf._sovende.remove(vaakn);
  }
}

/// Heat plan Step 4: frames only when a shader host really has a new
/// picture (harness `stegRammer: false` turns it off for A/B).
///
/// A host renders every `step` (31–50 ms) but its ticker asked for a frame
/// on every vsync, so a screen where the scene was the only thing moving drew
/// identical copies in between. After each tick the host calls [etter] with
/// its last render and its step. When the earliest moment its own check
/// (`e - sist < step`) can pass is more than a vsync away, the ticker is
/// muted — its elapsed time runs on, exactly as under `TickerMode` — and a
/// timer unmutes it [margin] before that moment. From then on it
/// ticks every vsync again, so the host decides on the very same vsync, with
/// the very same timestamp, as it did with a ticker that never slept.
///
/// [dt] gives the host the scene time across a sleep as the per-vsync sum it
/// added before: the whole gap (the clamps only ever cut a real stall, a
/// hidden route or the background, and those cuts are kept). [n] is the
/// number of vsyncs the last tick stands for (for [PerfHvile.tikk]).
///
/// No sleep under `timeDilation` (the timer runs on wall time), outside the
/// resumed lifecycle, or in the first 8 ticks after a (re)start, which give
/// the vsync period and the lag between a vsync and its tick (the timer is
/// set from the vsync, not from the moment the tick ran).
class PerfStegRammer with WidgetsBindingObserver {
  PerfStegRammer(this.ticker, {this.tickerModus, int Function()? naaUs, Timer Function(Duration, void Function())? timer, Duration? Function()? rammeTid})
      : _naaUs = naaUs ?? _klokke(),
        _timer = timer ?? Timer.new,
        _rammeTid = rammeTid ?? _iRamme {
    WidgetsBinding.instance.addObserver(this);
  }

  final Ticker ticker;

  /// The host's `TickerMode` (`() => TickerMode.getNotifier(context)`): a
  /// muted host stays muted when its timer fires, and a scene hidden while it
  /// sleeps keeps the moment it would have stopped ticking.
  final ValueListenable<bool> Function()? tickerModus;

  final int Function() _naaUs;
  final Timer Function(Duration, void Function()) _timer;
  final Duration? Function() _rammeTid;

  static int Function() _klokke() {
    final sw = Stopwatch()..start();
    return () => sw.elapsedMicroseconds;
  }

  static Duration? _iRamme() {
    final b = SchedulerBinding.instance;
    return b.schedulerPhase == SchedulerPhase.idle ? null : b.currentFrameTimeStamp;
  }

  /// How long before the earliest possible render the ticker is awake
  /// again: covers a late timer (whole-ms rounding, a busy isolate) and the
  /// trip from `scheduleFrame` to the vsync source.
  static const Duration margin = Duration(milliseconds: 10);

  /// Vsyncs since the last tick (1 unless it followed a sleep).
  int n = 1;

  Timer? _vekker;
  bool _fraSovn = false;
  Duration _vakt = Duration.zero;
  Duration? _kutt;
  Duration? _start;
  Duration? _sistE;
  int? _off;
  int _proever = 0;
  final List<int> _gap = [];
  int _gi = 0;
  ValueListenable<bool>? _modus;

  /// True while the ticker is muted by a sleep.
  bool get sover => _vekker != null;

  int get _p {
    if (_gap.isEmpty) return 16667;
    var p = _gap[0];
    for (final g in _gap) {
      if (g < p) p = g;
    }
    return p;
  }

  /// First thing in the host's tick.
  void tikk(Duration e) {
    n = 1;
    _vekker?.cancel();
    _vekker = null;
    _slipp();
    final rt = _rammeTid();
    final st = rt == null ? null : rt - e, gml = _start;
    if (st != null) _start = st;
    final sist = _sistE;
    _sistE = e;
    if (sist == null || e <= sist || (st != null && gml != null && st != gml) || timeDilation != 1.0) {
      // A (re)started ticker: its elapsed time begins again.
      _off = null;
      _proever = 0;
      _gap.clear();
      _gi = 0;
      _fraSovn = false;
      _kutt = null;
    } else {
      final g = (e - sist).inMicroseconds;
      if (_fraSovn) {
        n = math.max(1, (g / _p).round());
      } else if (g >= 3000 && g <= 50000) {
        if (_gap.length < 16) {
          _gap.add(g);
        } else {
          _gap[_gi] = g;
          _gi = (_gi + 1) % 16;
        }
      }
    }
    final o = _naaUs() - e.inMicroseconds;
    if (_off == null || o < _off!) _off = o;
    _proever++;
  }

  /// The host's `((e - prev).inMicroseconds / 1e6).clamp(0.0, maks)`.
  double dt(Duration e, Duration prev, double maks) {
    final g = (e - prev).inMicroseconds;
    if (!_fraSovn) return (g / 1e6).clamp(0.0, maks);
    _fraSovn = false;
    final kutt = _kutt;
    _kutt = null;
    // Until [_vakt] (or the hiding frame) the old ticker ticked every vsync,
    // each gap far below the clamp; only the rest can be one long gap.
    final q = math.max(0, ((kutt ?? _vakt) - prev).inMicroseconds);
    if (g - q <= maks * 1e6) return g < 0 ? 0.0 : g / 1e6;
    return q / 1e6 + maks;
  }

  /// Last thing in the host's tick: [sist] its last render, [step] its step,
  /// [slakk] the slack its check allows (`e - sist < step - slakk`).
  void etter(Duration e, Duration sist, Duration? step, {Duration slakk = Duration.zero}) {
    // Heat ladder / idle: the takt decides the next frame instead.
    if (PerfTakt.paa) {
      PerfTakt.etter(ticker, tickerModus?.call());
      return;
    }
    if (!BergenPerf.stegRammerPaa || step == null || !ticker.isActive || ticker.muted) return;
    final off = _off;
    if (off == null || _proever < 8 || timeDilation != 1.0) return;
    final ls = SchedulerBinding.instance.lifecycleState;
    if (ls != null && ls != AppLifecycleState.resumed) return;
    final vakt = sist + step - slakk - margin;
    final til = (vakt - e).inMicroseconds;
    // The next vsync may be the one: stay awake (the ticker as it was).
    if (til < _p) return;
    // From the vsync, not from now: less the lag of this tick behind it.
    final d = til - math.max<int>(0, _naaUs() - e.inMicroseconds - off);
    if (d <= 0) return;
    ticker.muted = true;
    _fraSovn = true;
    _vakt = vakt;
    _kutt = null;
    _modus = tickerModus?.call()?..addListener(_modusEndret);
    _vekker = _timer(Duration(microseconds: d), _vaakn);
  }

  void _vaakn() {
    _vekker = null;
    if (ticker.isActive) ticker.muted = !(_modus?.value ?? true);
  }

  void _modusEndret() {
    // Hidden while asleep: the old ticker's last tick was this frame.
    if (_modus?.value != false || !_fraSovn || _kutt != null) return;
    final rt = _rammeTid(), st = _start, s = _sistE, off = _off;
    if (rt != null && st != null) {
      _kutt = rt - st;
    } else if (s != null && off != null) {
      // Outside a frame (rare): the last vsync before now.
      final k = math.max(0, ((_naaUs() - off - s.inMicroseconds) / _p).floor());
      _kutt = s + Duration(microseconds: k * _p);
    }
  }

  void _slipp() {
    _modus?.removeListener(_modusEndret);
    _modus = null;
  }

  /// Before the host stops or holds its ticker: no sleep, no timer.
  void vekk() {
    if (_vekker == null) return;
    _vekker!.cancel();
    _vaakn();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Leaving the foreground: tick every vsync again, so the last tick
    // before frames stop is the one the old ticker had.
    if (state != AppLifecycleState.resumed) vekk();
  }

  void dispose() {
    _vekker?.cancel();
    _vekker = null;
    _slipp();
    WidgetsBinding.instance.removeObserver(this);
  }
}

/// Heat ladder + idle slow-down (approved 2026-11-10): the decorative
/// cadence. While the phone is hot ([BergenPerf.varme] 1) or nobody has
/// touched it for [BergenPerf.ledigEtter], the decorative tickers — loops
/// that are not essential, the shader scenes, Hjem's water surface and rod —
/// tick together at 30 fps: after its tick each one is muted (its elapsed
/// time runs on, exactly as under `TickerMode`) and one shared timer unmutes
/// all of them for the same vsync, [periode] after the frame they last
/// ticked in. A screen where only decorative things move then draws 30
/// frames a second instead of 60 (120 on ProMotion). Scrolling, taps, route
/// transitions, entrances, loaders and essential loops run on their own
/// tickers and keep every vsync; the motion keeps its speed on the wall
/// clock and its resolution, it is only sampled less often.
///
/// Off (the default unless hot or idle): every host takes its old code path.
abstract final class PerfTakt {
  /// 30 fps.
  static const Duration periode = Duration(microseconds: 33333);

  /// How much earlier than its own step a scene may render on a takt frame
  /// (half a 60 Hz vsync: vsync times jitter around 33.3 ms).
  static const Duration toleranse = Duration(milliseconds: 8);

  static String? _grunn;

  /// Why the takt is on (`varme`, `ledig`, `tvang`), or null when off.
  static String? get grunn => _grunn;
  static bool get paa => _grunn != null;

  static final Map<Ticker, ValueListenable<bool>?> _holdt = {};
  static Timer? _timer;
  static final Stopwatch _sw = Stopwatch()..start();
  static int? _off;

  /// Takt frames since the last heartbeat.
  static int rammer = 0;

  static void _sett(String? grunn) {
    if (grunn == _grunn) return;
    // A fresh lag estimate for each spell (see [etter]).
    if (_grunn == null) _off = null;
    _grunn = grunn;
    if (!kReleaseMode) debugPrint('PERF_TAKT ${grunn ?? 'av'}');
    // Off: everything waiting ticks on the next vsync again.
    if (grunn == null) _slipp();
  }

  /// Last thing in a decorative host's tick (after it used the frame): the
  /// ticker waits, muted, for the next takt frame. [modus] is the host's
  /// `TickerMode` notifier, so a host hidden meanwhile stays muted.
  static void etter(Ticker t, ValueListenable<bool>? modus) {
    if (!paa || !t.isActive || t.muted) return;
    t.muted = true;
    _holdt[t] = modus;
    if (_timer != null) return;
    // The first decorative tick of a takt frame: the next one is [periode]
    // after this frame's vsync. The timer aims at the middle of the vsync
    // gap before that one (the engine draws on the first vsync after the
    // request), less how late this tick runs behind its vsync.
    rammer++;
    final views = ui.PlatformDispatcher.instance.views;
    final hz = views.isEmpty ? 60.0 : views.first.display.refreshRate.clamp(30.0, 120.0);
    final vsyncUs = 1e6 / hz;
    final b = SchedulerBinding.instance;
    var sen = 0;
    if (b.schedulerPhase != SchedulerPhase.idle) {
      final o = _sw.elapsedMicroseconds - b.currentSystemFrameTimeStamp.inMicroseconds;
      final off = _off = _off == null ? o : math.min(_off!, o);
      // At most 40 % of a vsync: a long lag is a busy frame, not a reason
      // to ask for the next takt frame early.
      sen = math.min(o - off, (vsyncUs * .4).round());
    }
    final vent = periode.inMicroseconds - (vsyncUs / 2).round() - 1000 - sen;
    _timer = Timer(Duration(microseconds: math.max(0, vent)), _slipp);
  }

  /// Starts a decorative ticker that rested (a keyframe hold, off the
  /// screen): while a takt frame is pending it waits for it, so it does not
  /// add a frame of its own.
  static void start(Ticker t, ValueListenable<bool>? modus) {
    if (paa && _timer != null && !t.muted) {
      t.muted = true;
      _holdt[t] = modus;
    }
    t.start();
  }

  /// A host going away: forget its ticker.
  static void slipp(Ticker t) => _holdt.remove(t);

  /// Under the takt: whether a scene that renders every [step] renders on
  /// this frame — its new `sist`, or null for not yet. At most once per takt
  /// frame (30 fps); a slower scene keeps its own pace on average (its renders
  /// land on the takt frames nearest its own times, `sist` steps by [step]).
  static Duration? steg(Duration e, Duration sist, Duration step) {
    final s = step < periode ? periode : step;
    if (e - sist < s - toleranse) return null;
    final neste = sist + s;
    return e - neste > s ? e : neste;
  }

  /// Test only: tickers waiting for the next takt frame.
  @visibleForTesting
  static int get debugVenter => _holdt.length;

  static void _slipp() {
    _timer?.cancel();
    _timer = null;
    if (_holdt.isEmpty) return;
    final h = Map.of(_holdt);
    _holdt.clear();
    for (final e in h.entries) {
      e.key.muted = !(e.value?.value ?? true);
    }
  }
}

/// Heat ladder: a State whose own AnimationControllers run automatic
/// decoration (a rail's timed turn, an offer row's timed glide) puts their
/// tickers on [PerfTakt] while it is on — but only when nobody has touched
/// the screen for [BergenPerf.roligEtter], so a turn a finger started keeps
/// every vsync. Mix in after the ticker provider mixin.
mixin PerfTaktTikker<T extends StatefulWidget> on State<T>, TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) {
    late final Ticker t;
    t = super.createTicker((e) {
      onTick(e);
      if (PerfTakt.paa && mounted && BergenPerf.urort) PerfTakt.etter(t, TickerMode.getNotifier(context));
    });
    return t;
  }
}

/// Perf plan: the top route's name, for the heartbeat (`navigatorObservers`).
class PerfRuteObserver extends NavigatorObserver {
  String rute = '-';

  void _sett(Route<dynamic>? r) {
    rute = r?.settings.name ?? r?.runtimeType.toString() ?? '-';
    // A new screen counts as a touch (idle slow-down).
    BergenPerf.beroering();
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
        'thermal=${BergenPerf._thermalNaa}${BergenPerf._termisk == null ? '' : ' thermalEkte=${BergenPerf._thermal}'} lowPower=${BergenPerf._lowPower} battery=${na(BergenPerf._battery)} battTemp=${na(BergenPerf._battTemp, 1)} '
        'headroom=${na(BergenPerf._headroom, 2)} tier=${BergenPerf.tier.value.name} varme=${BergenPerf.varme.value} status=${BergenPerf._statusNaa} '
        'takt=${PerfTakt.grunn ?? 'av'} taktRammer=${PerfTakt.rammer} renderer=${ui.ImageFilter.isShaderFilterSupported ? 'impeller' : 'skia'} hz=$hz fps=$fps frames=$n over16=$over '
        'build_p50=${_pct(_build, .5) ~/ 1000} build_p90=${_pct(_build, .9) ~/ 1000} raster_p50=${_pct(_raster, .5) ~/ 1000} raster_p90=${_pct(_raster, .9) ~/ 1000} '
        'rss=$rss tickers=${SchedulerBinding.instance.transientCallbackCount} loops=${BergenPerf.lfLoopsMounted + BergenPerf.onbLoopsMounted}'
        '${BergenPerf.pulsTillegg.map((f) => ' ${f()}').join()}');
    PerfTakt.rammer = 0;
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
