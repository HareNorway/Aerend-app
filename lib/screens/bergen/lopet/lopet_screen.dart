import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../game/fjordlopet/input/lopet_input.dart';
import '../../../game/fjordlopet/lopet_lyd.dart';
import '../../../game/fjordlopet/nearest_goal.dart';
import '../../../game/fjordlopet/render/lopet_atlas.dart';
import '../../../game/fjordlopet/render/lopet_field_painter.dart';
import '../../../game/fjordlopet/render/lopet_look.dart';
import '../../../game/fjordlopet/render/lopet_loop.dart';
import '../../../game/fjordlopet/render/lopet_quality.dart';
import '../../../game/fjordlopet/render/lopet_water.dart';
import '../hjem/hjem_hero.dart';
import '../../common/auth/launch/lf_css.dart' show LfFrame;
import '../../../game/fjordlopet/sim/engine.dart';
import '../kit/bergen_kit.dart';
import '../../../services/lopet_utboks.dart';
import 'lopet_copy.dart';
import 'lopet_liste.dart';
import 'lopet_kai.dart';
import '../kit/ae_primitiver.dart' show AeKnappPille;
import 'lopet_data.dart';

enum _Fase { start, spill, pause, slutt }

/// Points plan Step 7 (game spec §4, §5.2, §6.3, §7, §12, §15): Fjordløpet — the start screen at the quay, the run,
/// the pause and the end of the run, with the delivery strip on every screen.
///
/// The delivery always wins: the strip shows the order's stage, window and the courier's minutes, and a tap pauses and
/// opens Sporing; the courier at the door ends a run (its distance counts); a card, a call or message, any CRITICAL
/// notification and the app going to the background pause it, and it resumes with 3 · 2 · 1. No new run once the
/// courier is within two minutes. Runs are recorded tick by tick and kept on the phone for Step 8 to submit.
class LopetScreen extends StatefulWidget {
  const LopetScreen({super.key, this.orderId, this.api, this.pollEvery = const Duration(seconds: 6), this.tilSporingEtter = const Duration(milliseconds: 1500)});

  final int? orderId;
  final LopetApi? api;
  final Duration pollEvery;

  /// After the courier reached the door, how long the end card stays before Sporing (spec T6).
  final Duration tilSporingEtter;

  /// Fjordløpet v1.3 plan Step 9 (spec §12.2): from «Sett seil» the picture moves into play in at most 0.6 s — when
  /// Home's scene is there to move (widget tests start at once unless a test sets [overgangTest]).
  static Duration get overgang => overgangTest ?? (hjemScene ? const Duration(milliseconds: 450) : Duration.zero);
  static Duration? overgangTest;

  /// The start screen sits on Home's Bryggen and Vågen scene (the same widget). Off in widget tests (FLUTTER_TEST):
  /// the scene's shaders and live mirror are not there; a plain backdrop of the same height stands in.
  static bool hjemScene = !Platform.environment.containsKey('FLUTTER_TEST');

  @override
  State<LopetScreen> createState() => _LopetScreenState();
}

class _LopetScreenState extends State<LopetScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final LopetApi _api = widget.api ?? LopetApi();
  late final Ticker _ticker;
  StreamSubscription<LopetSignal>? _sig;
  Timer? _poll;
  Timer? _nedtelling;

  int _orderId = 0;
  LopetState? _s;
  bool _laster = true;
  bool _stengt = false;
  _Fase _fase = _Fase.start;

  // Fjordløpet v1.3 plan Step 5 (spec §12.2–12.4): the fixed-step loop, the atlas, the flags and the frame numbers.
  FjordLoop? _loop;
  LopetAtlas? _atlas;
  bool _atlasLaster = false;
  final LopetFlags _flags = LopetFlags();
  final FramePerf _perf = FramePerf();

  // Fjordløpet v1.3 plan Step 9 (spec §12.2, §12.5, §12.6): the quality level, the shader water, the particle pool,
  // Home's sea mode and Ægil's back for the boat sprite — all made when the session opens.
  LopetQuality? _q;
  LopetWater? _water;
  final LopetFx _fx = LopetFx();
  final LopetMode _mode = LopetLook.now();
  ui.Image? _aegil;
  bool _overgang = false; // the ≤ 0.6 s move from the quay into play
  final ValueNotifier<LopetState?> _sVn = ValueNotifier<LopetState?>(null);
  final ValueNotifier<bool> _vestMelding = ValueNotifier<bool>(false);
  final ValueNotifier<String> _perfTekst = ValueNotifier<String>('');
  Timer? _vestTimer;
  Timer? _krasjTimer;
  String? _appVersion;
  int _rammer = 0;
  String? _token;
  int _startetMs = 0;
  static const bool _perfOverlay = bool.fromEnvironment('LOPET_PERF');

  // Fjordløpet v1.3 plan Step 6 (spec §12.1, §4.6): flashes on the water, the near-miss zoom, the end screen's lines.
  final ValueNotifier<String?> _flash = ValueNotifier<String?>(null);
  final ValueNotifier<double> _zoom = ValueNotifier<double>(1);
  Timer? _flashTimer;
  Timer? _zoomTimer;
  int? _forBesteRun;
  bool _rekordVist = false;
  int _porterVist = 0;
  int _ordrePoeng = 0;
  FjordGoal? _sluttMaal;

  String? _pauseGrunn; // manuell | bakgrunn | trenger
  String? _trengerSett; // the needs-you card that already paused a run
  Timer? _doraTimer;
  String? _sluttToken; // the token of the run on the end card
  String? _sluttMaalServer; // the server's nearest goal for that run, once it answered
  int? _teller;

  FjordResult? _res;

  /// Design 21 Nov plan Step 7: how many places win from Premiehylla (the ladder's voucher prizes), for the tile.
  int? _toppVinner;
  bool _premieHentet = false;
  String _sluttGrunn = 'kollisjon'; // kollisjon | ved_dora
  int _sluttPoeng = 0;
  int? _sluttFraRekord;
  bool _sluttRekord = false;
  bool _lyd = false;
  final LopetLyd _lyder = LopetLyd();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    WidgetsBinding.instance.addObserver(this);
    _sig = LopetSignaler.stream.listen(_onSignal);
    LopetUtboks.onSvar = _svar;
    unawaited(PackageInfo.fromPlatform().then((i) => _appVersion = i.version, onError: (_) => null));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_orderId == 0) {
      _orderId = widget.orderId ?? int.tryParse(BergenRoutes.argsOf(context)['order_id'] ?? '') ?? 0;
      _hent();
      unawaited(LopetUtboks.send()); // runs left over from an offline session
      _poll = Timer.periodic(widget.pollEvery, (_) => _hent(stille: true));
    }
    // Fjordløpet v1.3 plan Step 5 (spec §12.2): a covered screen stops the run, as the background does.
    if (!TickerMode.valuesOf(context).enabled && _fase == _Fase.spill) _pause('dekket');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sig?.cancel();
    if (LopetUtboks.onSvar == _svar) LopetUtboks.onSvar = null;
    _poll?.cancel();
    _nedtelling?.cancel();
    _vestTimer?.cancel();
    _krasjTimer?.cancel();
    _doraTimer?.cancel();
    // Leaving mid-run (the route replaced, the app closing the screen): the run is kept and its token spent.
    if ((_fase == _Fase.spill || _fase == _Fase.pause) && _token != null) unawaited(_avslutt('forlatt', vis: false));
    _ticker.dispose();
    _perf.stop();
    _loop?.dispose();
    _atlas?.dispose();
    _water?.dispose();
    _aegil?.dispose();
    _sVn.dispose();
    _vestMelding.dispose();
    _perfTekst.dispose();
    _flashTimer?.cancel();
    _zoomTimer?.cancel();
    _flash.dispose();
    unawaited(_lyder.dispose());
    _zoom.dispose();
    super.dispose();
  }

  // ── session ──────────────────────────────────────────────────────────────

  Future<void> _hent({bool stille = false}) async {
    final s = _orderId > 0 ? await _api.state(_orderId) : null;
    if (!mounted) return;
    // Fjordløpet v1.3 plan Step 5: offline or a timeout is not the window closing — the run goes on (spec §12).
    if (s == null && _api.lastOffline) {
      if (_laster) setState(() => _laster = false);
      return;
    }
    if (s != null && (_fase == _Fase.spill || _fase == _Fase.pause)) {
      // During a run the tree is not rebuilt: the strip listens on its own.
      _s = s;
      _sVn.value = s;
      _settLyd(s.soundOn);
      final trenger = s.delivery['needs_you'];
      if ((s.delivery['state'] ?? '') == 'arrived_customer') {
        _vedDora();
      } else if (trenger is String && trenger.isNotEmpty && trenger != _trengerSett) {
        _trengerSett = trenger;
        _pause('trenger'); // a card that needs the customer's answer (spec §7), once per card
      }
      return;
    }
    if (s == null) {
      // The window closed: the courier is at the door, or the order was delivered or cancelled.
      if (_fase == _Fase.spill || _fase == _Fase.pause) {
        _vedDora();
      }
      setState(() {
        _laster = false;
        _stengt = true;
      });
      LopetPort.status.value = null;
      return;
    }
    _q ??= LopetQuality.fromState(s.quality);
    setState(() {
      _s = s;
      _laster = false;
      _stengt = false;
      _settLyd(s.soundOn);
    });
    _sVn.value = s;
    _byggAtlas(s);
    LopetPort.status.value = LopetInngang(orderId: s.orderId, runsLeft: _igjen);
    if ((s.delivery['state'] ?? '') == 'arrived_customer' && (_fase == _Fase.spill || _fase == _Fase.pause)) {
      _vedDora();
    }
  }

  /// Runs left on this phone: the session's tokens not yet played here (a run is never played twice on one token).
  int get _igjen {
    final s = _s;
    if (s == null || s.noNewRun) return 0;
    return LopetLager.ledige(s).length;
  }

  // ── the run ──────────────────────────────────────────────────────────────

  /// The atlas is made when the session opens, before «Sett seil» (spec §12.2): nothing decodes during a run.
  Future<void> _byggAtlas(LopetState s) async {
    if (_atlas != null || _atlasLaster) return;
    _atlasLaster = true;
    try {
      final dpr = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
      final labels = [for (var k = 0; k < 3; k++) k < s.milestones.length ? '${LopetCopy.porter[k]} · ${s.milestones[k]} m' : ''];
      _aegil ??= await _lastAegil();
      final program = await LopetWater.load();
      final a = await LopetAtlas.build(density: dpr >= 2.5 ? 3 : 2, labels: labels, mode: _mode, aegil: _aegil);
      if (!mounted) {
        a.dispose();
        return;
      }
      // A shader that does not load means Low for the session (spec §12.5, T32).
      if (program == null) {
        _q?.markShaderFailed();
      } else {
        _water ??= LopetWater(program, LopetLook.of(_mode));
      }
      setState(() => _atlas = a);
    } catch (_) {
      // Without an atlas the field draws only the water (the run itself does not depend on it).
    } finally {
      _atlasLaster = false;
    }
  }

  /// Ægil from behind (`assets/images/aegil/rear.png`), decoded once for the atlas; null if it cannot be read.
  static Future<ui.Image?> _lastAegil() async {
    try {
      final data = await rootBundle.load('assets/images/aegil/rear.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: 180);
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  /// «Sett seil»: the quay moves up and the play view comes in (at most 0.6 s, spec §12.2), then the run starts.
  void _settSeilMedOvergang() {
    final s = _s;
    if (s == null || s.noNewRun || LopetLager.ledige(s).isEmpty || _overgang) return;
    if (MediaQuery.of(context).disableAnimations || LopetScreen.overgang == Duration.zero) {
      _settSeil();
      return;
    }
    setState(() => _overgang = true);
    Future<void>.delayed(LopetScreen.overgang, () {
      if (!mounted) return;
      _overgang = false;
      _settSeil();
    });
  }

  void _settSeil() {
    final s = _s;
    if (s == null || s.noNewRun) return;
    final ledige = LopetLager.ledige(s);
    if (ledige.isEmpty) return;
    _loop?.dispose();
    // From the second run of the week the ghost of the best verified run sails along (spec §5.5).
    final g = s.ghost;
    final loop = g == null
        ? FjordLoop(FjordSim(s.course, _perkFor(s, ledige.first)))
        : FjordLoop(FjordSim(s.course, _perkFor(s, ledige.first)), ghost: FjordSim(s.course, g.perk), ghostTicks: g.ticks, ghostInputs: g.inputs);
    final best = LopetLager.beste(s.week) ?? s.personalBestM;
    _flags
      ..bestMm = best == null ? -1 : best * 1000.0
      ..weekMm = s.weekBestM == null || s.weekBestM == best ? -1 : s.weekBestM! * 1000.0
      ..rivalMm = s.rival == null ? -1 : s.rival!.distanceM * 1000.0;
    _forBesteRun = best;
    _rekordVist = false;
    _porterVist = 0;
    _flash.value = null;
    setState(() {
      _token = ledige.first;
      _loop = loop;
      _startetMs = DateTime.now().millisecondsSinceEpoch;
      _res = null;
      _fase = _Fase.spill;
      _pauseGrunn = null;
    });
    _perf.start();
    _q?.runStarted();
    _fx.clear();
    _rammer = 0;
    loop.resetClock();
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final loop = _loop;
    if (loop == null || _fase != _Fase.spill || _krasjTimer != null) return;
    loop.frame(elapsed);
    final ev = loop.takeEvents();
    if (ev != 0) {
      _feedback(ev);
      _fx.queue(ev);
    }
    // Spec §12.5: one step down at once when the last 2 s average over the limit, then kept for the session.
    _q?.frame(_perf.recentAvgMs(120));
    _milepaeler(loop);
    if (_perfOverlay && ++_rammer % 30 == 0) {
      _perfTekst.value = '${(1000 / (_perf.recentAvgMs(30).clamp(1, 1000))).round()} fps · snitt ${_perf.avgMs.toStringAsFixed(1)} ms · '
          'verst ${_perf.worstMs.toStringAsFixed(1)} ms · >20 ms ${_perf.over20} · ${_q?.level.key ?? 'low'}';
    }
    if (loop.done) {
      // The picture freezes, then the end of the run — within 0.9 s of the collision (spec §4.6, §12.1).
      _ticker.stop();
      _krasjTimer = Timer(const Duration(milliseconds: 740), () {
        _krasjTimer = null;
        _avslutt('kollisjon');
      });
    }
  }

  /// Fjordløpet v1.3 plan Step 5: the felt column of spec §12.1 for the events that exist so far (Step 6 adds the rest).
  void _feedback(int ev) {
    if (ev & FjordSim.evHit != 0) {
      HapticFeedback.heavyImpact();
      _lyder.spill('treff');
    } else if (ev & FjordSim.evVest != 0) {
      HapticFeedback.heavyImpact();
      _lyder.spill('vest');
      _vestMelding.value = true;
      _vestTimer?.cancel();
      _vestTimer = Timer(const Duration(milliseconds: 1500), () => _vestMelding.value = false);
    } else if (ev & (FjordSim.evNearMiss | FjordSim.evMeterFull) != 0) {
      HapticFeedback.mediumImpact();
      _lyder.spill(ev & FjordSim.evMeterFull != 0 ? 'full' : 'naer');
      if (ev & FjordSim.evNearMiss != 0) {
        _vis(LopetCopy.naerePaa);
        // A 3 % zoom for 0.2 s — not with reduce motion.
        if (!MediaQuery.of(context).disableAnimations) {
          _zoom.value = 1.03;
          _zoomTimer?.cancel();
          _zoomTimer = Timer(const Duration(milliseconds: 200), () => _zoom.value = 1);
        }
      }
    } else if (ev & FjordSim.evCrate != 0) {
      HapticFeedback.selectionClick();
      _lyder.kasse();
    }
  }

  /// Gates and «Din beste» passed (spec §12.1): one label each, shown once.
  void _milepaeler(FjordLoop loop) {
    final s = _s;
    if (s == null) return;
    final m = loop.sim.sailedM;
    while (_porterVist < s.milestones.length && _porterVist < 3 && m >= s.milestones[_porterVist]) {
      final p = s.pointsFor(s.milestones.sublist(0, _porterVist + 1));
      _vis(LopetCopy.portPoeng(LopetCopy.porter[_porterVist], p));
      HapticFeedback.heavyImpact();
      _lyder.spill('port');
      _porterVist++;
    }
    final best = _forBesteRun;
    if (!_rekordVist && best != null && best > 0 && m > best) {
      _rekordVist = true;
      _vis(LopetCopy.nyRekordKort);
      HapticFeedback.heavyImpact();
      _lyder.spill('rekord');
    }
  }

  /// Sound is off until the customer turns it on (spec §7); the sounds load the first time it is on.
  void _settLyd(bool on) {
    _lyd = on;
    _lyder.on = on;
    if (on) unawaited(_lyder.last());
  }

  void _vis(String tekst) {
    _flash.value = tekst;
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 1200), () => _flash.value = null);
  }

  void _styr(int dir) {
    if (_fase != _Fase.spill) return;
    _loop?.input(dir);
    HapticFeedback.selectionClick();
    _lyder.spill('bytte');
  }

  void _pause(String grunn) {
    if (_fase != _Fase.spill || _krasjTimer != null) return;
    _ticker.stop();
    _perf.stop();
    _nedtelling?.cancel();
    setState(() {
      _fase = _Fase.pause;
      _pauseGrunn = grunn;
      _teller = null;
    });
  }

  /// 3 · 2 · 1, 800 ms each, then on — only while the app is in the foreground (spec §7).
  void _fortsett() {
    if (_fase != _Fase.pause) return;
    setState(() => _teller = 3);
    _nedtelling?.cancel();
    _nedtelling = Timer.periodic(const Duration(milliseconds: 800), (t) {
      if (!mounted || _fase != _Fase.pause) {
        t.cancel();
        return;
      }
      if ((_teller ?? 1) <= 1) {
        t.cancel();
        setState(() {
          _teller = null;
          _pauseGrunn = null;
          _fase = _Fase.spill;
        });
        _loop?.resetClock();
        _perf.resume();
        _ticker.start();
      } else {
        setState(() => _teller = (_teller ?? 3) - 1);
        _lyder.spill('blip');
      }
    });
  }

  /// Ends the run and keeps it: [grunn] kollisjon | ved_dora | forlatt. [vis] false when the screen is going away.
  Future<void> _avslutt(String grunn, {bool vis = true}) async {
    final loop = _loop;
    final s = _s;
    final token = _token;
    if (loop == null || s == null || token == null || _fase == _Fase.slutt) return;
    if (_ticker.isActive) _ticker.stop();
    _perf.stop();
    _nedtelling?.cancel();
    _krasjTimer?.cancel();
    _krasjTimer = null;
    final res = loop.sim.result();
    final forBeste = LopetLager.beste(s.week) ?? s.personalBestM;
    final rekord = forBeste != null && res.distanceM > forBeste;
    _token = null;
    _sluttToken = token;
    _sluttMaalServer = null;
    final poeng = s.pointsFor(res.gates, personalBest: rekord);
    if (poeng > _ordrePoeng) _ordrePoeng = poeng;
    final maal = _maalFor(s, res, forBeste);
    void sett() {
      _sluttMaal = maal;
      _res = res;
      _sluttGrunn = grunn;
      _sluttRekord = rekord;
      _sluttFraRekord = forBeste != null && res.distanceM < forBeste ? forBeste - res.distanceM : null;
      _sluttPoeng = _ordrePoeng;
      _fase = _Fase.slutt;
    }

    if (vis && mounted) {
      setState(sett);
    } else {
      sett();
    }
    await LopetLager.lagre(token: token, s: s, inputs: loop.inputsJson(), result: res.toJson(), startedMs: _startetMs,
        perf: _perf.frames > 0 ? _perf.toJson(_q?.level.key ?? 'low') : null, appVersion: _appVersion);
    // Spec §12.5: one step up after a whole run with a p99 under the limit.
    if (grunn == 'kollisjon' || grunn == 'ved_dora') _q?.afterRun(_perf.p99Ms, frames: _perf.frames);
    if (mounted) setState(() {});
    // Points plan Step 8: the run goes to the server now if there is a network, else later from the outbox.
    unawaited(LopetUtboks.send());
    LopetPort.status.value = LopetInngang(orderId: s.orderId, runsLeft: _igjen);
  }

  /// The server answered a run from the outbox (spec §12, plan D6): for the run on the end card, its points pending
  /// and nearest goal replace the phone's own; for any run of this order, the order's points.
  void _svar(Map<String, dynamic> run, Map<String, dynamic>? svar) {
    final d = svar?['data'] is Map ? Map<String, dynamic>.from(svar!['data'] as Map) : svar;
    if (!mounted || d == null || d['state'] != 'verified') return;
    final poeng = (d['points_pending'] as num?)?.toInt();
    setState(() {
      if (poeng != null) _ordrePoeng = poeng;
      if (run['token'] == _sluttToken && _fase == _Fase.slutt) {
        if (poeng != null) _sluttPoeng = poeng;
        _sluttMaalServer = LopetCopy.maalFra(d['nearest_goal']) ?? _sluttMaalServer;
      }
    });
  }

  /// The end screen's third line (spec §4.6, plan D6): badges counted with this run.
  FjordGoal? _maalFor(LopetState s, FjordResult res, int? forBeste) {
    int plus(String metric) => switch (metric) {
          'crates' => res.crates,
          'near_misses' => res.nearMisses,
          'metres' => res.distanceM,
          _ => 0,
        };
    return FjordGoal.of(
      distanceM: res.distanceM,
      milestones: s.milestones,
      bestM: forBeste,
      rival: s.rival == null ? null : (s.rival!.place, s.rival!.name, s.rival!.distanceM),
      ladder: [for (final r in s.ladderTop) (r.place, r.name, r.distanceM, r.me)],
      badges: [for (final b in s.badges) (b.name, b.metric, b.target, b.progress + plus(b.metric), b.done)],
    );
  }

  String? _maalTekst(FjordGoal? g) => switch (g?.type) {
        'badge' => LopetCopy.maalMerke(g!.name, g.metric, g.remaining),
        'milestone' => LopetCopy.maalMilepael(LopetCopy.porter[g!.index.clamp(0, 2)], g.gapM),
        'best' => LopetCopy.maalBeste(g!.gapM),
        'rival' || 'top10' => LopetCopy.maalSeiler(g!.name, g.gapM),
        _ => null,
      };

  /// Back during a run pauses it; back again (or the arrow) leaves, and the run is kept (spec §12.3).
  void _tilbake() {
    if (_fase == _Fase.spill) {
      _pause('manuell');
      return;
    }
    if (_fase == _Fase.pause) {
      _avslutt('forlatt', vis: false).whenComplete(_forlat);
      return;
    }
    _forlat();
  }

  /// Leaves the screen. A direct pop: the run is already kept, and asking PopScope again before it has rebuilt would
  /// send the back press round in a loop.
  void _forlat() {
    if (!mounted) return;
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  void _onSignal(LopetSignal sig) {
    if (sig == LopetSignal.varsel) {
      _lyder.stille();
      return;
    }
    if (sig == LopetSignal.vedDora) {
      _vedDora();
      _hent(stille: true);
    } else {
      _pause('trenger');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    if (_fase == _Fase.pause && _nedtelling != null) {
      // The countdown never runs in the background: back to the pause screen.
      _nedtelling?.cancel();
      _nedtelling = null;
      setState(() => _teller = null);
    }
    _pause('bakgrunn');
  }

  /// The courier is at the door (spec §3, §7, T6): a run in progress ends at once and its distance counts. The end
  /// card shows the distance for a moment ([LopetScreen.tilSporingEtter]), then Sporing comes up with the code. The
  /// run is kept before the screen goes.
  void _vedDora() {
    if (_fase != _Fase.spill && _fase != _Fase.pause) return;
    unawaited(_avslutt('ved_dora').whenComplete(() {
      if (!mounted) return;
      _doraTimer?.cancel();
      _doraTimer = Timer(widget.tilSporingEtter, () {
        if (mounted && _fase == _Fase.slutt) _tilSporing();
      });
    }));
  }

  void _tilSporing() {
    if (_fase == _Fase.spill) _pause('manuell');
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      BergenRoutes.push(context, '/bergen/sporing', arguments: {'id': '$_orderId'});
    }
  }

  /// Pynt på båten (spec §5.7, Design 21 Nov plan Step 7): three places × three tiles from the catalogue; a tap on an
  /// unlocked one shows it on the boat at once (the server keeps the choice). Never affects play.
  void _pynt() {
    final s = _s;
    if (s == null) return;
    LopetArk.vis(context, (ctx) => LopetPyntArk(s: s, onVelg: (valgt) => _api.equip(valgt).then((_) => _hent(stille: true))));
  }

  void _vilkaar() {
    final s = _s;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF103847),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          key: const Key('lopet-vilkaar'),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(LopetCopy.vilkaar, style: BergenTokens.display(20, weight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 12),
              for (final l in (s?.vilkaar ?? const <String>[]))
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(padding: EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 6, color: Color(0xFF7FF0CB))),
                      const SizedBox(width: 10),
                      Expanded(child: Text(l, style: BergenTokens.text(13, weight: FontWeight.w600, color: Colors.white.withValues(alpha: .86), height: 1.4))),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final iLop = _fase == _Fase.spill || _fase == _Fase.pause;
    return PopScope(
      canPop: !iLop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _tilbake();
      },
      child: Scaffold(
      backgroundColor: const Color(0xFF0C2A38),
      body: SafeArea(
        child: Column(
          children: [
            ValueListenableBuilder<LopetState?>(
              valueListenable: _sVn,
              builder: (_, sv, __) => _Stripe(s: sv ?? _s, stengt: _stengt, onTap: _tilSporing, onTilbake: _tilbake),
            ),
            Expanded(
              child: _laster
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF7FF0CB)))
                  : switch (_fase) {
                      _Fase.start => _start(),
                      _Fase.spill || _Fase.pause => _spill(),
                      _Fase.slutt => _slutt(),
                    },
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// The ladder once per screen: the prizes say how many places win from Premiehylla (never a number in the app).
  void _hentPremier() {
    if (_premieHentet) return;
    _premieHentet = true;
    LopetListeApi().ladder().then((d) {
      final p = ((d?['prizes'] as List?) ?? const []).whereType<Map>().where((p) => p['kind'] == 'voucher');
      final n = p.isEmpty || d?['prizes_enabled'] == false ? null : p.map((p) => (p['to'] as num?)?.toInt() ?? 0).reduce((a, b) => a > b ? a : b);
      if (mounted && n != null && n > 0) setState(() => _toppVinner = n);
    });
  }

  /// Design 21 Nov plan Step 7 (design `Fjordløpet · Start`): «Ukens led» with the week line and the losgrad pill,
  /// Sjøkortet, the NESTE MÅL and UKELISTEN tiles, the life rings, «Sett seil» and «Vilkår for Fjordløpet»; the
  /// badges live in the Ukeliste sheet and Pynt is the corner button on the scene.
  Widget _start() {
    final s = _s;
    if (s == null || _stengt) {
      return _Melding(key: const Key('lopet-stengt'), tekst: LopetCopy.stengt, knapp: LopetCopy.tilSporing, onTap: _tilSporing);
    }
    _hentPremier();
    final igjen = _igjen;
    final beste = LopetLager.beste(s.week) ?? s.personalBestM;
    final b = beste ?? 0;
    // Short screens (the iPhone SE) keep the quay as a band behind the title, so the start fits as before (T24).
    final kort = MediaQuery.sizeOf(context).height < 720;
    final kaiH = kort ? _kaiHKort : _kaiH;
    final liste = ListView(
      key: const Key('lopet-start'),
      padding: EdgeInsets.fromLTRB(16, kort ? 12 : _kaiTopp, 16, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(LopetCopy.ukensLed, style: BergenTokens.display(28, weight: FontWeight.w800, color: Colors.white, letterSpacingEm: -0.03)),
                  const SizedBox(height: 2),
                  // Points plan Step 13 (game spec §5.3): the Platina boat sails under its own name.
                  Text([LopetCopy.kaiUke(s.week), if (s.weeksSailed > 0) LopetCopy.uker(s.weeksSailed), if ((s.boatName ?? '').isNotEmpty) s.boatName!].join(' · '),
                      style: BergenTokens.text(13, weight: FontWeight.w600, color: Colors.white.withValues(alpha: .76))),
                ],
              ),
            ),
            const SizedBox(width: 10),
            LopetLosgrad(s: s),
          ],
        ),
        if (s.bonusGranted) ...[
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerLeft, child: _Chip(key: const Key('lopet-bonus'), tekst: LopetCopy.forsinket, farge: const Color(0xFFF2C14E))),
        ],
        const SizedBox(height: 14),
        LopetKaiSjokort(s: s, besteM: b),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: LopetMaalFlis(s: s, besteM: b)),
              const SizedBox(width: 10),
              Expanded(child: LopetListeFlis(s: s, besteM: b, toppVinner: _toppVinner, onTap: () => LopetListe.vis(context, s: s))),
            ],
          ),
        ),
        const SizedBox(height: 18),
        LopetBoyer(antall: s.runsAllowed, igjen: igjen, vest: _nesteFullMaaler(s)),
        const SizedBox(height: 14),
        if (s.noNewRun) ...[
          _Melding(key: const Key('lopet-snart'), tekst: LopetCopy.snartFremme, knapp: LopetCopy.tilSporing, onTap: _tilSporing),
        ] else if (igjen > 0)
          AeKnappPille(key: const Key('lopet-sett-seil'), label: LopetCopy.settSeil, onPressed: _settSeilMedOvergang)
        else
          _Melding(key: const Key('lopet-neste'), tekst: LopetCopy.nesteSeilas, knapp: LopetCopy.tilSporing, onTap: _tilSporing),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            key: const Key('lopet-vilkaar-knapp'),
            onPressed: _vilkaar,
            child: Text(LopetCopy.vilkaarLenke, style: BergenTokens.text(14, weight: FontWeight.w800, color: Colors.white.withValues(alpha: .86))),
          ),
        ),
      ],
    );
    // Fjordløpet v1.3 plan Step 9 (spec §12.2): the start screen on Home's Bryggen and Vågen scene, the boat moored in
    // it; from «Sett seil» the picture moves up into play in [LopetScreen.overgang] (≤ 0.6 s). A Transform, not a
    // fade: no Opacity layer anywhere near the scene.
    final look = LopetLook.of(_mode);
    return ClipRect(
      child: TweenAnimationBuilder<double>(
        key: const Key('lopet-kai'),
        tween: Tween<double>(begin: 0, end: _overgang ? 1 : 0),
        duration: LopetScreen.overgang,
        curve: Curves.easeInCubic,
        builder: (_, v, child) => FractionalTranslation(translation: Offset(0, -v), child: child),
        child: Stack(
          children: [
            Positioned(left: 0, right: 0, top: 0, height: kaiH, child: IgnorePointer(child: RepaintBoundary(child: _kaiScene(look, kaiH)))),
            Positioned(
              left: 0,
              right: 0,
              top: kort ? 0 : kaiH - 120,
              height: kort ? kaiH : 120,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [kort ? const Color(0x990C2A38) : const Color(0x000C2A38), const Color(0xFF0C2A38)]),
                  ),
                ),
              ),
            ),
            Positioned.fill(child: liste),
            if (!kort) Positioned(right: 16, top: 14, child: LopetPyntKnapp(onTap: _pynt)),
          ],
        ),
      ),
    );
  }

  static const double _kaiH = 230;
  static const double _kaiHKort = 120;
  static const double _kaiTopp = 96;

  /// Home's scene (the same widget, as a window onto Vågen: no floats, raft or Fjordfiske pill), with the boat moored
  /// at the quay; in widget tests a plain sky-over-water stand-in.
  Widget _kaiScene(LopetLook look, double kaiH) {
    final boat = Positioned(
      left: 0,
      right: 0,
      top: kaiH * .35,
      child: Center(child: Icon(Icons.sailing_rounded, key: const Key('lopet-kai-baat'), size: 34, color: Colors.white.withValues(alpha: .92))),
    );
    if (!LopetScreen.hjemScene) {
      return Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              key: const Key('lopet-kai-scene'),
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [look.skyHi, look.skyLo, look.shal, look.deep], stops: const [0, .45, .55, 1])),
            ),
          ),
          boat,
        ],
      );
    }
    return Stack(
      children: [
        Positioned.fill(
          child: LfFrame(
            child: HjemHero(
              key: const Key('lopet-kai-scene'),
              vaer: _hjemVaer(),
              floats: const [],
              onFloatAdd: (_) {},
              onFloatSink: (_) {},
              onFloatNever: (_) {},
              onPose: () {},
              onFjordfiske: () {},
              nappAvailable: false,
              vindu: true,
            ),
          ),
        ),
        boat,
      ],
    );
  }

  /// Home's weather for the scene: the same choice Home makes (the harness, else the hour).
  HjemVaer _hjemVaer() => switch (_mode) {
        LopetMode.dag => HjemVaer.sol,
        LopetMode.regn => HjemVaer.regn,
        LopetMode.kveld => (DateTime.now().hour >= 23 || DateTime.now().hour < 5) ? HjemVaer.natt : HjemVaer.solnedgang,
      };

  /// Points plan Step 12 (game spec §5.3, G-T15): one redningsvest per order — once a run of this order used it, the
  /// rest sail without it (kept on the phone per order; the server's state says the same once the run is verified).
  // Fjordløpet v1.3 plan Step 3 (D2): Gull/Platina start the order's first run — its first token — with a full meter;
  // the server replays each token with the same perk.
  String _perkFor(LopetState s, String token) => token == s.fullMeterToken ? 'full_meter' : 'none';

  bool _nesteFullMaaler(LopetState s) {
    final ledige = LopetLager.ledige(s);
    return ledige.isNotEmpty && ledige.first == s.fullMeterToken;
  }

  Widget _spill() {
    final loop = _loop!;
    final s = _s!;
    final rolig = MediaQuery.of(context).disableAnimations;
    final atlas = _atlas;
    return Stack(
      key: const Key('lopet-spill'),
      children: [
        // The scene and the HUD are separate repaint boundaries (spec §12.2); the field reads raw pointers (§12.3).
        Positioned.fill(
          child: LopetInput(
            key: const Key('lopet-felt'),
            onDir: _styr,
            child: RepaintBoundary(
              child: ValueListenableBuilder<double>(
                valueListenable: _zoom,
                builder: (_, z, child) => Transform.scale(scale: z, child: child),
                child: atlas == null
                    ? const ColoredBox(color: Color(0xFF155A70))
                    : CustomPaint(
                        painter: LopetFieldPainter(
                          loop: loop,
                          atlas: atlas,
                          boat: s.boat,
                          milestones: s.milestones,
                          flags: _flags,
                          rolig: rolig,
                          quality: _q,
                          water: _water,
                          fx: _fx,
                          landmarks: [for (final l in (s.course['landmarks'] as List? ?? const [])) if (l is Map) Map<String, dynamic>.from(l)],
                        ),
                      ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          top: 12,
          right: 16,
          child: RepaintBoundary(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: loop.metres,
                  builder: (_, m, __) {
                    String? neste;
                    for (var k = 0; k < s.milestones.length && k < 3; k++) {
                      if (m < s.milestones[k]) {
                        neste = LopetCopy.omMeter(LopetCopy.porter[k], s.milestones[k] - m);
                        break;
                      }
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$m m', key: const Key('lopet-meter'), style: BergenTokens.display(30, weight: FontWeight.w800, color: Colors.white)),
                        if (neste != null) Text(neste, style: BergenTokens.text(12.5, weight: FontWeight.w700, color: const Color(0xFFF7D57E))),
                        const SizedBox(height: 6),
                        _Maaler(loop: loop),
                        ValueListenableBuilder<bool>(
                          valueListenable: _vestMelding,
                          builder: (_, on, __) => on
                              ? Text(LopetCopy.vestTok, style: BergenTokens.text(12.5, weight: FontWeight.w800, color: const Color(0xFFFF9C7A)))
                              : const SizedBox.shrink(),
                        ),
                      ],
                    );
                  },
                ),
                const Spacer(),
                IconButton(
                  key: const Key('lopet-pause-knapp'),
                  onPressed: () => _pause('manuell'),
                  icon: const Icon(Icons.pause_circle_filled_rounded, color: Colors.white, size: 36),
                ),
              ],
            ),
          ),
        ),
        // One label at a time on the water: «Nære på», a gate with its points, «Ny rekord».
        Positioned(
          left: 0,
          right: 0,
          top: 120,
          child: IgnorePointer(
            child: ValueListenableBuilder<String?>(
              valueListenable: _flash,
              builder: (_, t, __) => t == null
                  ? const SizedBox.shrink()
                  : Center(child: Text(t, key: const Key('lopet-flash'), style: BergenTokens.display(22, weight: FontWeight.w800, color: const Color(0xFFF7D57E)))),
            ),
          ),
        ),
        if (_perfOverlay)
          Positioned(
            left: 8,
            bottom: 8,
            child: ValueListenableBuilder<String>(
              valueListenable: _perfTekst,
              builder: (_, t, __) => Text(t, key: const Key('lopet-perf'), style: const TextStyle(color: Colors.white, fontSize: 11, backgroundColor: Color(0xAA000000))),
            ),
          ),
        if (_fase == _Fase.pause) Positioned.fill(child: _pauseLag()),
      ],
    );
  }

  Widget _pauseLag() {
    final tekst = switch (_pauseGrunn) {
      'trenger' => LopetCopy.trengerDeg,
      _ => LopetCopy.pause,
    };
    return Container(
      key: const Key('lopet-pause'),
      color: const Color(0xCC071C25),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_teller != null ? LopetCopy.fortsettOm(_teller!) : tekst, key: const Key('lopet-pause-tekst'),
              style: BergenTokens.display(24, weight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 18),
          if (_teller == null) ...[
            _Knapp(key: const Key('lopet-fortsett'), tekst: LopetCopy.fortsett, onTap: _fortsett),
            const SizedBox(height: 10),
            TextButton(onPressed: _tilSporing, child: Text(LopetCopy.tilSporing, style: BergenTokens.text(13, weight: FontWeight.w700, color: const Color(0xFF7FF0CB)))),
          ],
        ],
      ),
    );
  }

  Widget _slutt() {
    final r = _res!;
    final s = _s;
    final igjen = _igjen;
    final vedDora = _sluttGrunn == 'ved_dora' || _stengt;
    final cause = r.endCause;
    final linje2 = _sluttRekord
        ? LopetCopy.nyRekord
        : _sluttGrunn == 'kollisjon' && cause != null
            ? LopetCopy.aarsak('${cause['obstacle']}', s?.landmarkName(cause['landmark'] as String?), r.distanceM)
            : vedDora
                ? null // said once, in the button area
                : (_sluttFraRekord != null ? LopetCopy.fraRekorden(_sluttFraRekord!) : null);
    final linje3 = _sluttMaalServer ?? _maalTekst(_sluttMaal);
    return ListView(
      key: const Key('lopet-slutt'),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      children: [
        // 1 · the distance
        Text('${r.distanceM} m', key: const Key('lopet-slutt-meter'), textAlign: TextAlign.center, style: BergenTokens.display(48, weight: FontWeight.w800, color: Colors.white)),
        // 2 · what ended it, and where — or the record
        if (linje2 != null)
          Text(linje2, key: const Key('lopet-slutt-aarsak'), textAlign: TextAlign.center,
              style: BergenTokens.text(14.5, weight: FontWeight.w800, color: _sluttRekord ? const Color(0xFFF7D57E) : Colors.white70)),
        const SizedBox(height: 10),
        // 3 · the nearest goal, one only
        if (linje3 != null)
          Text(linje3, key: const Key('lopet-slutt-maal'), textAlign: TextAlign.center, style: BergenTokens.text(15, weight: FontWeight.w800, color: const Color(0xFF7FF0CB))),
        // 4 · the order's points so far, and when they are paid
        if (_sluttPoeng > 0) ...[
          const SizedBox(height: 8),
          Text(LopetCopy.poengVedLevering(_sluttPoeng), key: const Key('lopet-slutt-poeng'), textAlign: TextAlign.center,
              style: BergenTokens.text(15, weight: FontWeight.w800, color: const Color(0xFFF7D57E))),
        ],
        const SizedBox(height: 18),
        // 5 · the button within reach of the thumb
        if (vedDora)
          _Melding(key: const Key('lopet-slutt-dora'), tekst: LopetCopy.vedDora, knapp: LopetCopy.tilSporing, onTap: _tilSporing)
        else if (s != null && s.noNewRun)
          _Melding(tekst: LopetCopy.snartFremme, knapp: LopetCopy.tilSporing, onTap: _tilSporing)
        else if (igjen > 0)
          _Knapp(key: const Key('lopet-seil-igjen'), tekst: LopetCopy.seilIgjen(igjen), onTap: _settSeil)
        else
          _Melding(key: const Key('lopet-slutt-neste'), tekst: LopetCopy.nesteSeilas, knapp: LopetCopy.tilSporing, onTap: _tilSporing),
        // Below, on scrolling: statistics, gates, badges, the chart where the run ended, the ladder.
        const SizedBox(height: 28),
        Wrap(
          alignment: WrapAlignment.spaceEvenly,
          spacing: 18,
          runSpacing: 10,
          children: [
            _Tall(etikett: LopetCopy.kasser, verdi: '${r.crates}'),
            _Tall(etikett: LopetCopy.naerePaaTall, verdi: '${r.nearMisses}'),
            _Tall(etikett: LopetCopy.vestBruk, verdi: '${r.vestUses}'),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var k = 0; k < (s?.milestones.length ?? 0) && k < 3; k++)
              _Chip(tekst: LopetCopy.porter[k], farge: r.gates.contains(s!.milestones[k]) ? const Color(0xFFF2C14E) : Colors.white24),
          ],
        ),
        if (s != null && s.badges.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Merker(badges: s.badges, plus: (m) => switch (m) { 'crates' => r.crates, 'near_misses' => r.nearMisses, 'metres' => r.distanceM, _ => 0 }),
        ],
        if (s != null) ...[
          const SizedBox(height: 16),
          Center(child: _Sjokort(s: s, besteM: [LopetLager.beste(s.week) ?? 0, s.personalBestM ?? 0, r.distanceM].reduce((a, b) => a > b ? a : b), merkeM: r.distanceM)),
        ],
        TextButton(
          onPressed: () => LopetListe.vis(context),
          child: Text(LopetCopy.ukeliste, style: BergenTokens.text(13, weight: FontWeight.w700, color: const Color(0xFFF7D57E))),
        ),
      ],
    );
  }
}

/// The redningsvest meter (spec §4.4): one field per crate or near miss, a life ring when full.
class _Maaler extends StatelessWidget {
  const _Maaler({required this.loop});

  final FjordLoop loop;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: loop.meter,
        builder: (_, m, __) {
          final full = loop.sim.full;
          return Row(
            key: const Key('lopet-maaler'),
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < full; i++)
                Container(
                  width: 10,
                  height: 8,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(color: i < m ? const Color(0xFFE5532D) : Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              if (m >= full) const Icon(Icons.radio_button_checked_rounded, key: Key('lopet-livboye'), size: 16, color: Color(0xFFE5532D)),
            ],
          );
        },
      );
}

/// The week's three badges with progress (spec §5.7); [plus] adds what the last run brought.
class _Merker extends StatelessWidget {
  const _Merker({required this.badges, this.plus});

  final List<LopetBadge> badges;
  final int Function(String metric)? plus;

  @override
  Widget build(BuildContext context) => Column(
        key: const Key('lopet-merker'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(LopetCopy.merker, style: BergenTokens.text(12, weight: FontWeight.w800, color: Colors.white60)),
          const SizedBox(height: 6),
          for (final b in badges)
            Builder(builder: (_) {
              final p = (b.progress + (plus?.call(b.metric) ?? 0)).clamp(0, b.target);
              final done = b.done || p >= b.target;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(done ? Icons.military_tech_rounded : Icons.radio_button_unchecked_rounded, size: 18, color: done ? const Color(0xFFF2C14E) : Colors.white38),
                    const SizedBox(width: 8),
                    Expanded(child: Text(b.name, style: BergenTokens.text(13, weight: FontWeight.w700, color: Colors.white))),
                    Text('$p / ${b.target}', style: BergenTokens.text(12.5, weight: FontWeight.w700, color: Colors.white70)),
                  ],
                ),
              );
            }),
        ],
      );
}

/// The delivery strip (game spec §7): stage, window, the courier's minutes; a tap pauses and opens Sporing.
class _Stripe extends StatelessWidget {
  const _Stripe({required this.s, required this.stengt, required this.onTap, required this.onTilbake});

  final LopetState? s;
  final bool stengt;
  final VoidCallback onTap;
  final VoidCallback onTilbake;

  static String _kl(Object? iso) {
    final d = DateTime.tryParse('${iso ?? ''}')?.toLocal();
    return d == null ? '' : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final d = s?.delivery ?? const {};
    final vindu = [_kl(d['promised_start']), _kl(d['promised_end'])].where((x) => x.isNotEmpty).join('–');
    final eta = d['courier_eta_minutes'];
    final linje = [
      if ('${d['stage_label'] ?? ''}'.isNotEmpty) '${d['stage_label']}',
      if (vindu.isNotEmpty) vindu,
      // Only a plausible ETA (a stale or far-off courier position says nothing useful).
      if (eta is num && eta <= 120) LopetCopy.minUnna(eta.toInt()),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
      child: Row(
        children: [
          IconButton(key: const Key('lopet-tilbake'), onPressed: onTilbake, icon: const Icon(Icons.arrow_back_rounded, color: Colors.white)),
          Expanded(
            child: GestureDetector(
              key: const Key('lopet-stripe'),
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white24)),
                child: Row(
                  children: [
                    const Icon(Icons.delivery_dining_rounded, color: Color(0xFF7FF0CB), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(linje.isEmpty ? LopetCopy.navn : linje, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: BergenTokens.text(13, weight: FontWeight.w700, color: Colors.white)),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sjøkortet (game spec §5.2): this week's course drawn up to the customer's best distance; the rest is fog.
class _Sjokort extends StatelessWidget {
  const _Sjokort({required this.s, required this.besteM, this.merkeM});

  final LopetState s;
  final int besteM;

  /// Where the last run ended (the end screen), or null.
  final int? merkeM;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => LopetSjokortStor.vis(context, s, besteM),
      child: Container(
        key: const Key('lopet-sjokort'),
        width: 96,
        height: 230,
        decoration: BoxDecoration(color: const Color(0xFF123F50), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white24)),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(painter: LopetSjokortMaler(s: s, besteM: besteM, merker: [if (merkeM != null) merkeM!])),
      ),
    );
  }
}

/// Sjøkortet in full screen (spec §5.2): the landmarks by name, the gates, and where each of this week's runs ended.
class LopetSjokortStor {
  static void vis(BuildContext context, LopetState s, int besteM) {
    showDialog<void>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: const Color(0xFF0C2A38),
        child: Column(
          key: const Key('lopet-sjokort-stor'),
          children: [
            Row(
              children: [
                const SizedBox(width: 16),
                Expanded(child: Text(LopetCopy.sjokort, style: BergenTokens.display(20, weight: FontWeight.w800, color: Colors.white))),
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(LopetCopy.kartLukk, style: BergenTokens.text(13, weight: FontWeight.w700, color: const Color(0xFF7FF0CB)))),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: LopetSjokortMaler(s: s, besteM: besteM, merker: [for (final r in s.myRuns) r.distanceM], navn: true),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.close_rounded, size: 14, color: Color(0xFFFF6B5A)),
                  const SizedBox(width: 6),
                  Text(LopetCopy.herGikkDetGalt, style: BergenTokens.text(12, weight: FontWeight.w700, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LopetSjokortMaler extends CustomPainter {
  LopetSjokortMaler({required this.s, required this.besteM, this.merker = const [], this.navn = false, this.visM});

  final LopetState s;
  final int besteM;

  /// Distances where runs ended («Her gikk det galt»).
  final List<int> merker;

  /// Full screen: the landmarks by name.
  final bool navn;

  /// The metres shown (Design 21 Nov: the quay's card shows 1 200 m, turned on its side).
  final int? visM;

  @override
  void paint(Canvas canvas, Size size) {
    final visM = this.visM?.toDouble() ?? (navn ? (besteM + 200).clamp(400, 5000).toDouble() : 1200.0);
    double y(num m) => size.height - 10 - (m / visM) * (size.height - 20);
    final seen = besteM.clamp(0, visM.toInt());
    final rows = (s.course['rows'] as List?) ?? const [];
    for (final r in rows) {
      final m = ((r as Map)['d'] as num) / 1000;
      if (m > visM) break;
      if (m > seen) continue;
      final lanes = [for (final l in ((r['l'] as List?) ?? const [])) (l as num).toInt()];
      final lane = lanes.isNotEmpty ? lanes.first : ((((r['p'] as Map?)?['lane']) as num?)?.toInt() ?? 1);
      final x = size.width * (lane + .5) / 3;
      canvas.drawCircle(Offset(x, y(m)), navn ? 3.4 : 2.6, Paint()..color = r['t'] == 'boye' ? const Color(0xFFE5532D) : Colors.white70);
    }
    for (final g in s.milestones) {
      if (g > visM) continue;
      canvas.drawLine(Offset(6, y(g)), Offset(size.width - 6, y(g)), Paint()..color = const Color(0xFFF2C14E)..strokeWidth = 2);
    }
    if (navn) {
      for (final lm in s.landmarks) {
        final m = ((lm['d'] as num) / 1000);
        if (m > seen || m > visM) continue;
        final tp = TextPainter(
          text: TextSpan(text: s.landmarkName('${lm['k']}'), style: const TextStyle(color: Color(0xFFB8E6F0), fontSize: 11, fontWeight: FontWeight.w700)),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: size.width / 3);
        final right = (lm['s'] as num? ?? 1) > 0;
        tp.paint(canvas, Offset(right ? size.width - tp.width - 2 : 2, y(m) - tp.height / 2));
      }
    }
    final x = Paint()..color = const Color(0xFFFF6B5A)..strokeWidth = 2.2;
    for (final m in merker) {
      if (m > visM) continue;
      final c = Offset(size.width / 2, y(m));
      canvas.drawLine(c + const Offset(-5, -5), c + const Offset(5, 5), x);
      canvas.drawLine(c + const Offset(-5, 5), c + const Offset(5, -5), x);
    }
    // Fog above the best distance.
    final fog = Rect.fromLTRB(0, 0, size.width, y(seen));
    canvas.drawRect(fog, Paint()..shader = LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.white.withValues(alpha: .08), Colors.white.withValues(alpha: .45)]).createShader(fog));
  }

  @override
  bool shouldRepaint(LopetSjokortMaler old) => old.besteM != besteM || old.merker.length != merker.length;
}

class _Tall extends StatelessWidget {
  const _Tall({required this.etikett, required this.verdi});

  final String etikett;
  final String verdi;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etikett, style: BergenTokens.text(11.5, weight: FontWeight.w700, color: Colors.white60)),
          Text(verdi, style: BergenTokens.display(22, weight: FontWeight.w800, color: Colors.white)),
        ],
      );
}

class _Chip extends StatelessWidget {
  const _Chip({super.key, required this.tekst, required this.farge});

  final String tekst;
  final Color farge;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: farge.withValues(alpha: .18), borderRadius: BorderRadius.circular(99), border: Border.all(color: farge.withValues(alpha: .7))),
        child: Text(tekst, style: BergenTokens.text(12, weight: FontWeight.w800, color: Colors.white)),
      );
}

class _Knapp extends StatelessWidget {
  const _Knapp({super.key, required this.tekst, required this.onTap});

  final String tekst;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 56,
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE8682F), shape: const StadiumBorder()),
          child: Text(tekst, style: BergenTokens.text(16, weight: FontWeight.w800, color: Colors.white)),
        ),
      );
}

class _Melding extends StatelessWidget {
  const _Melding({super.key, required this.tekst, required this.knapp, required this.onTap});

  final String tekst;
  final String knapp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(tekst, textAlign: TextAlign.center, style: BergenTokens.text(15, weight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white38), shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12)),
            child: Text(knapp, style: BergenTokens.text(14, weight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      );
}
