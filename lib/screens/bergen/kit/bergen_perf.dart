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
  }) {
    BergenTier t = device;
    var why = deviceWhy;
    BergenTier raise(BergenTier a, BergenTier b) => a.index >= b.index ? a : b;
    if (watchdogSteps > 0) {
      final w = BergenTier.values[math.min(2, watchdogSteps)];
      if (w.index > t.index) why = 'slow frames ×$watchdogSteps';
      t = raise(t, w);
    }
    // Heat plan Step 12: heat alone never stops, slows or reduces the
    // motion (plan §0.2) — the old step-down only for an A/B run.
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

  static void termiskTvang(int? thermal) {
    if (kReleaseMode) return;
    _termisk = thermal?.clamp(0, 3);
    _update();
  }

  /// The thermal state in force: the injected one, else the platform's.
  static int get _thermalNaa => _termisk ?? _thermal;

  static void _update() {
    final (t, why) = velg(
      device: _device,
      deviceWhy: _deviceWhy,
      watchdogSteps: _watchdogSteps,
      thermal: _thermalNaa,
      lowPower: _lowPower,
      forced: _forced,
      varmeTrinn: varmeTrinnGammel,
    );
    if (t != tier.value || why != reason) {
      reason = why;
      tier.value = t;
      debugPrint('PERF_TIER ${t.name} $why');
    }
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
        'thermal=${BergenPerf._thermalNaa}${BergenPerf._termisk == null ? '' : ' thermalEkte=${BergenPerf._thermal}'} lowPower=${BergenPerf._lowPower} battery=${na(BergenPerf._battery)} battTemp=${na(BergenPerf._battTemp, 1)} '
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
