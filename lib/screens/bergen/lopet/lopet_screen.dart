import 'dart:async';
import 'dart:math' as math;
import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../game/fjordlopet/haptics/game_haptics.dart';
import '../../../game/fjordlopet/haptics/haptikk_lab.dart';
import '../../../game/fjordlopet/haptics/haptikk_moenster.dart';
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
import 'lopet_vibrasjon.dart';
import 'lopet_kai.dart';
import '../kit/ae_primitiver.dart' show AeKnappPille, AeKollaps;
import '../kit/ae_mynt.dart' show AeMynt;
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
  const LopetScreen({super.key, this.orderId, this.api, this.haptics, this.pollEvery = const Duration(seconds: 6), this.tilSporingEtter = const Duration(milliseconds: 1500), this.fraSporing});

  final int? orderId;
  final LopetApi? api;

  /// Opened from Sporing (route argument `fra: sporing`): «Til sporing» goes back. From Hjem, Utforsk or Ægil it opens
  /// Sporing in the quay's place (T3 GAM-D05: at the door the app went back to Hjem instead of Sporing).
  final bool? fraSporing;

  /// The game's haptics (tests pass one with a fake channel); the screen makes its own otherwise.
  final GameHaptics? haptics;
  final Duration pollEvery;

  /// After the courier reached the door, how long the end card stays before Sporing (spec T6).
  final Duration tilSporingEtter;

  /// Fjordløpet v1.3 plan Step 9 (spec §12.2): from «Sett seil» the picture moves into play in at most 0.6 s — when
  /// Home's scene is there to move (widget tests start at once unless a test sets [overgangTest]).
  // Design 21 Nov plan Step 9: the design's Bølge — 0.6 s with a wave front sweeping up from the bottom.
  static Duration get overgang => overgangTest ?? (hjemScene ? const Duration(milliseconds: 600) : Duration.zero);
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
  bool _fraSporing = false;
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

  String? _pauseGrunn; // manuell | bakgrunn | trenger (a courier call or message, a CRITICAL push) | kort (a card for the customer)
  String? _trengerSett; // the needs-you card that already paused a run
  Timer? _doraTimer;
  String? _sluttToken; // the token of the run on the end card
  String? _sluttMaalServer; // the server's nearest goal for that run, once it answered
  // The state as the run ended. The end card adds this run to its badge progress; the 6 s poll's newer state already
  // counts the run once the server has it, so that one would count it twice (T3 GAM-E03).
  LopetState? _sluttS;
  int? _teller;

  FjordResult? _res;

  /// Design 21 Nov plan Step 7: how many places win from Premiehylla (the ladder's voucher prizes), for the tile.
  int? _toppVinner;

  /// Design 21 Nov plan Step 8: the end card's «Mer om seilasen» fold.
  bool _merOm = false;
  bool _premieHentet = false;
  String _sluttGrunn = 'kollisjon'; // kollisjon | ved_dora
  int _sluttPoeng = 0;
  int? _sluttFraRekord;
  bool _sluttRekord = false;
  bool _lyd = false;
  final LopetLyd _lyder = LopetLyd();

  // Fjordløpet haptics plan Step 4: every haptic of the game goes through GameHaptics (spec §6), next to the sound.
  late final GameHaptics _hap = widget.haptics ?? GameHaptics.felles;
  bool _rivalForbi = false;
  bool _ukeForbi = false;
  // Step 5: the knock for «Budet er to minutter unna» waits for the run (DH9) and, after a collision, for a touch.
  bool _snartSett = false;
  bool _bankVenter = false;
  bool _bonusVist = false;
  String? _sistLosgrad;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    WidgetsBinding.instance.addObserver(this);
    _sig = LopetSignaler.stream.listen(_onSignal);
    LopetUtboks.onSvar = _svar;
    unawaited(_hap.prepare());
    unawaited(PackageInfo.fromPlatform().then((i) => _appVersion = i.version, onError: (_) => null));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_orderId == 0) {
      _orderId = widget.orderId ?? int.tryParse(BergenRoutes.argsOf(context)['order_id'] ?? '') ?? 0;
      _fraSporing = widget.fraSporing ?? BergenRoutes.argsOf(context)['fra'] == 'sporing';
      _hent();
      unawaited(LopetUtboks.send()); // runs left over from an offline session
      _poll = Timer.periodic(widget.pollEvery, (_) => _hent(stille: true));
    }
    // Fjordløpet v1.3 plan Step 5 (spec §12.2): a covered screen stops the run, as the background does.
    final dekket = !TickerMode.of(context); // same value as valuesOf(context).enabled, which needs Flutter ≥ 3.38
    if (dekket && _fase == _Fase.spill) _pause('dekket');
    // Haptics plan Step 4: covered, nothing plays (also during the freeze after a collision, which is not paused).
    if (dekket) {
      _hap.hold(true);
    } else if (_fase != _Fase.pause) {
      _hap.hold(false);
    }
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
    // The shared instance outlives the screen: stopped, and free to play elsewhere.
    _hap
      ..stop()
      ..hold(false)
      ..newRun();
    _zoom.dispose();
    super.dispose();
  }

  // ── session ──────────────────────────────────────────────────────────────

  Future<void> _hent({bool stille = false}) async {
    final s = _orderId > 0 ? await _api.state(_orderId) : null;
    if (!mounted) return;
    if (s != null) {
      // Haptics plan Step 7 (DH8, TH12): the policies apply at every state read — no release needed.
      _hap.setPolicy(enabled: s.hapticsEnabled, scale: s.hapticsScale);
      _rundtHaptikk(s);
    }
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
        // A card that needs the customer's answer (spec §7), once per card: a delay or problem notice from the store or
        // Ærend, not a courier message, so «Ærendet ditt trenger deg» (T3 GAM-D03).
        _pause('kort');
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
    _rivalForbi = false;
    _ukeForbi = false;
    _flash.value = null;
    loop.onTickEvents = _hap.tickEvents;
    _hap.newRun();
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
    _hap.hold(false);
    _hap.play(HaptikkId.h14); // control starts
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
    _puls(loop);
    if (_perfOverlay && ++_rammer % 30 == 0) {
      // Design 21 Nov plan Step 9 (design `ytelseVis`): fps, average, worst, frames over 20 ms, the level by its name
      // and the water's resolution.
      final lvl = _q?.level;
      _perfTekst.value = '${(1000 / (_perf.recentAvgMs(30).clamp(1, 1000))).round()} fps · snitt ${_perf.avgMs.toStringAsFixed(1)} ms · '
          'verst ${_perf.worstMs.toStringAsFixed(1)} ms · >20 ms ${_perf.over20} · ${LopetCopy.kvalitet(lvl?.key ?? 'low')}'
          '${lvl == null || lvl.waterScale == 0 ? '' : ' · vann ${(lvl.waterScale * 100).round()} %'}';
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
    // Haptics plan Step 4: the haptics are played per tick by GameHaptics (FjordLoop.onTickEvents); this is the sound
    // and the picture.
    if (ev & FjordSim.evHit != 0) {
      _lyder.spill('treff');
    } else if (ev & FjordSim.evVest != 0) {
      _lyder.spill('vest');
      _vestMelding.value = true;
      _vestTimer?.cancel();
      _vestTimer = Timer(const Duration(milliseconds: 1500), () => _vestMelding.value = false);
    } else if (ev & (FjordSim.evNearMiss | FjordSim.evMeterFull) != 0) {
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
      _lyder.kasse(_hap.rad); // the same row as H02 (DH6)
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
      _hap.play(const [HaptikkId.h06, HaptikkId.h07, HaptikkId.h08][_porterVist]);
      _lyder.spill('port');
      _porterVist++;
    }
    final best = _forBesteRun;
    if (!_rekordVist && best != null && best > 0 && m > best) {
      _rekordVist = true;
      _vis(LopetCopy.nyRekordKort);
      _hap.play(HaptikkId.h10);
      _lyder.spill('rekord');
    }
    // Haptics plan Step 4: H11 when the rival ahead is passed, H12 when the week's best is (not H10 then: when the
    // week's best is the customer's own, the record above plays).
    final rival = s.rival;
    if (!_rivalForbi && rival != null && !rival.me && rival.distanceM > 0 && m > rival.distanceM) {
      _rivalForbi = true;
      _hap.play(HaptikkId.h11);
    }
    final uke = s.weekBestM;
    if (!_ukeForbi && uke != null && uke > 0 && m > uke) {
      _ukeForbi = true;
      if (uke != best) _hap.play(HaptikkId.h12);
    }
  }

  Widget _lydVibRad() => Container(
        key: const Key('lopet-lyd-vib'),
        padding: const EdgeInsets.fromLTRB(12, 8, 10, 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white.withValues(alpha: .07), border: Border.all(color: Colors.white.withValues(alpha: .12))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(child: Text(LopetCopy.lydVib, style: BergenTokens.text(13.5, weight: FontWeight.w800, color: Colors.white))),
              Semantics(
                toggled: _lyd,
                label: LopetCopy.lyd,
                child: IconButton(
                  key: const Key('lopet-kai-lyd'),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() => _settLyd(!_lyd));
                    _api.sound(_lyd);
                  },
                  icon: Icon(_lyd ? Icons.volume_up_rounded : Icons.volume_off_rounded, color: Colors.white.withValues(alpha: .85), size: 22),
                ),
              ),
            ]),
            LopetVibrasjon(haptics: _hap, kompakt: true),
          ],
        ),
      );

  /// Haptics plan Step 5: «Sett seil» / «Seil igjen» — U01, or U09 when no run can start.
  void _seil(VoidCallback go) {
    final s = _s;
    if (s == null || s.noNewRun || LopetLager.ledige(s).isEmpty) {
      _hap.play(HaptikkId.u09);
      return;
    }
    _hap.play(HaptikkId.u01);
    go();
  }

  /// Haptics plan Step 7 (spec §11.2): the run's `perf` carries the phone's tier and the level in force.
  Map<String, String> _hapPerf() => {
        'haptics_tier': _hap.tier.name,
        'haptics_level': _hap.virkelig.name,
      };

  /// Plays U04 now, or after the run.
  void _bank() {
    _bankVenter = false;
    _hap.play(HaptikkId.u04);
  }

  /// A state read (Step 5): the first «Budet er to minutter unna» knocks (DH9) — after the run if one is going; a new
  /// losgrad plays the fanfare (U11; DH10: no weekly-prize moment exists in the app yet).
  void _rundtHaptikk(LopetState s) {
    // It knocks when it turns true, not when the game opens with the courier already near.
    if (_sistLosgrad == null) _snartSett = s.noNewRun;
    if (s.noNewRun && !_snartSett) {
      _snartSett = true;
      if (_fase == _Fase.spill || _fase == _Fase.pause || _hap.spiller == HaptikkId.h13) {
        _bankVenter = true;
      } else {
        _bank();
      }
    }
    final g = s.losgrad;
    final sist = _sistLosgrad;
    _sistLosgrad = g;
    if (sist != null && g.isNotEmpty && g != sist && _fase != _Fase.spill) _hap.play(HaptikkId.u11);
  }

  /// Runs [f] once after this frame (a haptic for something the build just showed).
  Widget _naarVist(VoidCallback f) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) f();
    });
    return const SizedBox.shrink();
  }

  /// The pulse before «Din beste» (spec §4.3): from 60 m before the best not yet passed in this run — none in the
  /// week's first run (no best yet).
  void _puls(FjordLoop loop) {
    final best = _forBesteRun;
    if (best == null || best <= 0 || _rekordVist) {
      _hap.pulse(null);
      return;
    }
    _hap.pulse(best - loop.boatMm() / 1000);
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
    _hap.touch();
    _lyder.spill('bytte'); // H01 plays when the change is carried out (evLane, DH1)
  }

  void _pause(String grunn) {
    if (_fase != _Fase.spill || _krasjTimer != null) return;
    _ticker.stop();
    _perf.stop();
    _hap.hold(true); // stop, and nothing new while paused (spec §6)
    // Step 5: U03 when the player pauses, U04 the knock for «Du har en melding fra budet».
    if (grunn == 'manuell') _hap.preview(HaptikkId.u03);
    if (grunn == 'trenger' || grunn == 'kort') _hap.preview(HaptikkId.u04);
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
    _hap.preview(HaptikkId.u02);
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
        _hap.hold(false);
        _hap.play(HaptikkId.h14); // control starts again
      } else {
        setState(() => _teller = (_teller ?? 3) - 1);
        _lyder.spill('blip');
        _hap.preview(HaptikkId.u02);
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
      _sluttS = s;
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
    // Step 5: U07 with the «Nytt merke» card (allowed in the silence after a collision); the knock that waited for
    // the run (DH9) — after a collision it waits for the next touch.
    if (vis && grunn != 'forlatt' && _nyttMerke(s, res) != null) _hap.play(HaptikkId.u07);
    if (_bankVenter && grunn != 'ved_dora' && grunn != 'kollisjon') _bank();
    await LopetLager.lagre(token: token, s: s, inputs: loop.inputsJson(), result: res.toJson(), startedMs: _startetMs,
        perf: {if (_perf.frames > 0) ..._perf.toJson(_q?.level.key ?? 'low'), ..._hapPerf()}, appVersion: _appVersion);
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
    if (state == AppLifecycleState.resumed) {
      if (_fase != _Fase.pause) _hap.hold(false);
      return;
    }
    // Haptics plan Step 4 (TH9): in the background nothing plays — a pattern under way (H13 in the freeze) stops.
    _hap.hold(true);
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
    // Step 5 (TH5): the knock-knock stops whatever is playing — it outranks everything.
    _hap.stop();
    _hap.preview(HaptikkId.u05);
    _bankVenter = false;
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
    if (_fraSporing && nav.canPop()) {
      nav.pop();
      return;
    }
    final sporing = BergenRoutes.generate(RouteSettings(name: '/bergen/sporing', arguments: {'id': '$_orderId'}));
    if (sporing != null) {
      nav.pushReplacement<dynamic, dynamic>(sporing);
    } else if (nav.canPop()) {
      nav.pop();
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
      // The text is edited in the panel (`game.vilkaar`) and grows with the text size: the sheet takes its height from
      // the text and scrolls when that is more than the screen (T3 GAM-B09: it overflowed at 9/16 of the screen).
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
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
      // Haptics plan Step 4: any touch ends the silence after a collision (spec §6).
      child: Listener(
      onPointerDown: (_) {
        _hap.touch();
        if (_bankVenter && _fase != _Fase.spill && _fase != _Fase.pause) _bank();
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
        if (s.bonusGranted && !_bonusVist) _naarVist(() {
          // Step 5: U08 the first time the bonus chip is shown.
          _bonusVist = true;
          _hap.play(HaptikkId.u08);
        }),
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
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _hap.play(HaptikkId.u09),
            child: _Melding(key: const Key('lopet-snart'), tekst: LopetCopy.snartFremme, knapp: LopetCopy.tilSporing, onTap: _tilSporing),
          ),
        ] else if (igjen > 0)
          AeKnappPille(key: const Key('lopet-sett-seil'), label: LopetCopy.settSeil, onPressed: () => _seil(_settSeilMedOvergang))
        else
          _Melding(key: const Key('lopet-neste'), tekst: LopetCopy.nesteSeilas, knapp: LopetCopy.tilSporing, onTap: _tilSporing),
        // Haptics plan Step 6 (DH4): the compact «Lyd · Vibrasjon» row — the sound switch back on the quay, with it.
        const SizedBox(height: 12),
        _lydVibRad(),
        const SizedBox(height: 4),
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
        builder: (_, v, child) => v == 0 ? child! : ClipPath(clipper: _Bolge(v), child: FractionalTranslation(translation: Offset(0, -v * .35), child: child)),
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

  /// Design 21 Nov plan Step 8 (design `Fjordløpet · Pause`): the cause's title and line («Seilasen venter på deg ·
  /// Båten ligger stille til du er klar.», «… · Du var borte et øyeblikk …», «Du har en melding fra budet · Les den i
  /// sporingen, eller seil videre.»), «Fortsett om 3 · 2 · 1», the sound switch (moved here from the quay), «Fortsett».
  Widget _pauseLag() {
    final (tittel, under) = LopetCopy.pauseTekst(_pauseGrunn);
    return Container(
      key: const Key('lopet-pause'),
      color: const Color(0xCC071C25),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF235C6A), Color(0xFF173F4A)]),
          border: Border.all(color: Colors.white.withValues(alpha: .16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_teller != null ? LopetCopy.fortsettOm(_teller!) : tittel, key: const Key('lopet-pause-tekst'), textAlign: TextAlign.center,
                style: BergenTokens.display(22, weight: FontWeight.w800, color: Colors.white)),
            if (_teller == null) ...[
              const SizedBox(height: 6),
              Text(under, key: const Key('lopet-pause-under'), textAlign: TextAlign.center, style: BergenTokens.text(14, weight: FontWeight.w600, color: Colors.white.withValues(alpha: .75))),
              const SizedBox(height: 16),
              Semantics(
                toggled: _lyd,
                label: LopetCopy.lyd,
                child: GestureDetector(
                  key: const Key('lopet-lyd'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() => _settLyd(!_lyd));
                    _api.sound(_lyd);
                  },
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white.withValues(alpha: .07), border: Border.all(color: Colors.white.withValues(alpha: .12))),
                    child: Row(children: [
                      Icon(_lyd ? Icons.volume_up_rounded : Icons.volume_off_rounded, color: Colors.white.withValues(alpha: .85), size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(LopetCopy.lydTekst(_lyd), style: BergenTokens.text(14, weight: FontWeight.w800, color: Colors.white))),
                      Switch.adaptive(value: _lyd, activeTrackColor: const Color(0xFF5CE0B8), onChanged: (v) {
                        setState(() => _settLyd(v));
                        _api.sound(v);
                      }),
                    ]),
                  ),
                ),
              ),
              // Haptics plan Step 6 (DH4): «Vibrasjon» under «Lyd».
              const SizedBox(height: 12),
              LopetVibrasjon(haptics: _hap),
              const SizedBox(height: 14),
              AeKnappPille(key: const Key('lopet-fortsett'), label: LopetCopy.fortsett, onPressed: _fortsett),
              const SizedBox(height: 4),
              TextButton(onPressed: _tilSporing, child: Text(LopetCopy.tilSporing, style: BergenTokens.text(13.5, weight: FontWeight.w800, color: const Color(0xFF7FF0CB)))),
              // Haptics plan Step 8: the lab, from the paused run, in LOPET_PERF builds only.
              if (_perfOverlay)
                TextButton(
                  key: const Key('lopet-haptikk-lab'),
                  onPressed: () => Navigator.of(context).pushNamed(HaptikkLab.rute),
                  child: const Text('Haptikk-lab', style: TextStyle(color: Colors.white70)),
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// The badge this run finished (counted on the phone; the server says the same when the run is verified): the
  /// first one, its name, what it unlocks or its stars.
  (String, String)? _nyttMerke(LopetState s, FjordResult r) {
    int plus(String m) => switch (m) { 'crates' => r.crates, 'near_misses' => r.nearMisses, 'metres' => r.distanceM, _ => 0 };
    final nye = [for (final b in s.badges) if (!b.done && b.progress + plus(b.metric) >= b.target && plus(b.metric) > 0) b];
    if (nye.isEmpty) return null;
    final b = nye.first;
    final eid = s.cosmetics.where((c) => c.item == b.unlocks).firstOrNull;
    final pynt = s.katalog.where((v) => v.item == b.unlocks).firstOrNull?.name ?? eid?.name ?? '';
    return eid == null ? (LopetCopy.nyttMerke(b.name), LopetCopy.laaserOpp(pynt)) : (LopetCopy.nyStjerne(b.name), LopetCopy.stjerner(eid.stars + 1));
  }

  /// Design 21 Nov plan Step 8 (design `Fjordløpet · Slutt på seilas`): the metres counting up, what ended it (or
  /// the record, or «Budet er ved døra · du rakk 316 m»), the nearest goal in its mint pill, the order's points with
  /// the coin, the «Nytt merke» card, «Seil igjen · 2 igjen» with «Til kaien» / «Til sporing», and «Mer om seilasen»:
  /// the numbers (Kasser, Tid, Nære på, Vest), the week's badges as rings, Sjøkortet stopped where the run ended, the
  /// ladder link. Lines 1–5 stay in the spec's order and fit the smallest screen (T24).
  Widget _slutt() {
    final r = _res!;
    final s = _s;
    final igjen = _igjen;
    final vedDora = _sluttGrunn == 'ved_dora' || _stengt;
    final cause = r.endCause;
    final rolig = MediaQuery.disableAnimationsOf(context);
    final kort = MediaQuery.sizeOf(context).height < 720;
    final linje2 = _sluttRekord
        ? LopetCopy.nyRekord
        : vedDora
            ? LopetCopy.doraRakk(r.distanceM)
            : _sluttGrunn == 'kollisjon' && cause != null
                ? LopetCopy.aarsak('${cause['obstacle']}', s?.landmarkName(cause['landmark'] as String?), r.distanceM)
                : (_sluttFraRekord != null ? LopetCopy.fraRekorden(_sluttFraRekord!) : null);
    final linje3 = _sluttMaalServer ?? _maalTekst(_sluttMaal);
    final sb = _sluttS ?? s;
    final merke = sb == null ? null : _nyttMerke(sb, r);
    final plass = s?.ladderTop.where((x) => x.me).firstOrNull?.place ?? (s?.rival == null ? null : s!.rival!.place + 1);
    int plus(String m) => switch (m) { 'crates' => r.crates, 'near_misses' => r.nearMisses, 'metres' => r.distanceM, _ => 0 };
    return ListView(
      key: const Key('lopet-slutt'),
      padding: EdgeInsets.fromLTRB(20, kort ? 8 : 20, 20, 28),
      children: [
        // 1 · the distance, counting up
        TweenAnimationBuilder<double>(
          tween: Tween(begin: rolig ? r.distanceM.toDouble() : 0, end: r.distanceM.toDouble()),
          duration: Duration(milliseconds: rolig ? 0 : 560),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => Text('${v.round()} m', key: const Key('lopet-slutt-meter'), textAlign: TextAlign.center,
              style: BergenTokens.display(kort ? 44 : 64, weight: FontWeight.w800, color: Colors.white, letterSpacingEm: -0.04)),
        ),
        // 2 · what ended it, and where — or the record, or the door
        if (linje2 != null)
          Text(linje2, key: const Key('lopet-slutt-aarsak'), textAlign: TextAlign.center,
              style: BergenTokens.text(15, weight: FontWeight.w800, color: _sluttRekord ? const Color(0xFFF7D57E) : Colors.white)),
        const SizedBox(height: 12),
        // 3 · the nearest goal, one only
        if (linje3 != null)
          Center(
            child: Container(
              key: const Key('lopet-slutt-maal'),
              padding: const EdgeInsets.fromLTRB(16, 10, 18, 10),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: const Color.fromRGBO(127, 240, 203, .1), border: Border.all(color: const Color.fromRGBO(127, 240, 203, .45))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.flag_outlined, size: 18, color: Color(0xFF7FF0CB)),
                const SizedBox(width: 10),
                Flexible(child: Text(linje3, textAlign: TextAlign.center, style: BergenTokens.display(15, weight: FontWeight.w800, color: const Color(0xFFDDFBF0)))),
              ]),
            ),
          ),
        // 4 · the order's points so far, and when they are paid
        if (_sluttPoeng > 0) ...[
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const AeMynt(size: 22, flip: false),
            const SizedBox(width: 8),
            Flexible(child: Text(LopetCopy.poengVedLevering(_sluttPoeng), key: const Key('lopet-slutt-poeng'), textAlign: TextAlign.center,
                style: BergenTokens.text(14.5, weight: FontWeight.w800, color: const Color(0xFFF7D57E)))),
          ]),
        ],
        if (merke != null && !kort) ...[
          const SizedBox(height: 12),
          Container(
            key: const Key('lopet-slutt-merke'),
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: const Color.fromRGBO(242, 193, 78, .1), border: Border.all(color: const Color.fromRGBO(242, 193, 78, .5))),
            child: Row(children: [
              const AeMynt(size: 40, flip: false, mark: false, child: Icon(Icons.military_tech_rounded, size: 20, color: AeMynt.ink)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(merke.$1, style: BergenTokens.display(15, weight: FontWeight.w800, color: const Color(0xFFFFE3A3))),
                  Text(merke.$2, style: BergenTokens.text(12.5, weight: FontWeight.w700, color: Colors.white.withValues(alpha: .82))),
                ]),
              ),
            ]),
          ),
        ],
        SizedBox(height: kort ? 10 : 18),
        // 5 · the button within reach of the thumb
        if (vedDora)
          Column(key: const Key('lopet-slutt-dora'), children: [
            AeKnappPille(label: LopetCopy.tilSporing, onPressed: _tilSporing),
          ])
        else if (s != null && s.noNewRun)
          _Melding(tekst: LopetCopy.snartFremme, knapp: LopetCopy.tilSporing, onTap: _tilSporing)
        else if (igjen > 0)
          AeKnappPille(key: const Key('lopet-seil-igjen'), label: LopetCopy.seilIgjen(igjen), leading: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20), onPressed: () => _seil(_settSeil))
        else
          _Melding(key: const Key('lopet-slutt-neste'), tekst: LopetCopy.nesteSeilas, knapp: LopetCopy.tilSporing, onTap: _tilSporing),
        if (!vedDora)
          Wrap(alignment: WrapAlignment.center, spacing: 24, children: [
            TextButton(key: const Key('lopet-til-kaien'), onPressed: () => setState(() => _fase = _Fase.start), child: Text(LopetCopy.tilKaien, style: BergenTokens.text(14, weight: FontWeight.w800, color: Colors.white))),
            // T3 E01/E04: when the main action is already «Til sporing» (no run left, or none coming), not twice.
            if (igjen > 0 && !(s != null && s.noNewRun))
              TextButton(key: const Key('lopet-slutt-til-sporing'), onPressed: _tilSporing, child: Text(LopetCopy.tilSporing, style: BergenTokens.text(14, weight: FontWeight.w800, color: Colors.white))),
          ]),
        // Below: «Mer om seilasen».
        Center(
          child: TextButton(
            key: const Key('lopet-mer-om'),
            onPressed: () => setState(() => _merOm = !_merOm),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(LopetCopy.merOm, style: BergenTokens.text(13.5, weight: FontWeight.w700, color: Colors.white.withValues(alpha: .75))),
              const SizedBox(width: 6),
              AnimatedRotation(turns: _merOm ? .5 : 0, duration: const Duration(milliseconds: 260), child: Icon(Icons.expand_more_rounded, size: 18, color: Colors.white.withValues(alpha: .75))),
            ]),
          ),
        ),
        AeKollaps(
          aapen: _merOm,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: _Stat(ikon: Icons.grid_view_rounded, tall: '${r.crates}', etikett: LopetCopy.kasser)),
              const SizedBox(width: 10),
              Expanded(child: _Stat(ikon: Icons.timer_outlined, tall: LopetCopy.sek((r.ticks / 60).round()), etikett: LopetCopy.tid)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _Stat(ikon: Icons.bolt_rounded, tall: '${r.nearMisses}', etikett: LopetCopy.naerePaaTall)),
              const SizedBox(width: 10),
              Expanded(child: _Stat(ikon: Icons.support_rounded, tall: '${r.vestUses}', etikett: LopetCopy.vestBruk)),
            ]),
            if (sb != null && sb.badges.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                key: const Key('lopet-merker'),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                decoration: lopetKort(),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Expanded(child: Text(LopetCopy.merkerUke, style: BergenTokens.text(12, weight: FontWeight.w800, color: Colors.white.withValues(alpha: .75)).copyWith(letterSpacing: 1.1))),
                    Text(LopetCopy.listeAv(sb.badges.where((b) => b.done || b.progress + plus(b.metric) >= b.target).length, sb.badges.length), style: BergenTokens.text(12.5, weight: FontWeight.w800, color: const Color(0xFFF7D57E))),
                  ]),
                  const SizedBox(height: 12),
                  LopetMerkeRader(badges: sb.badges, pluss: plus),
                ]),
              ),
            ],
            if (s != null) ...[
              const SizedBox(height: 12),
              LopetKaiSjokort(s: s, besteM: [LopetLager.beste(s.week) ?? 0, s.personalBestM ?? 0, r.distanceM].reduce((a, b) => a > b ? a : b), stoppM: r.distanceM),
              const SizedBox(height: 12),
              GestureDetector(
                key: const Key('lopet-slutt-liste'),
                behavior: HitTestBehavior.opaque,
                onTap: () => LopetListe.vis(context, s: s),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: lopetKort(),
                  child: Row(children: [
                    const Icon(Icons.emoji_events_outlined, color: Color(0xFFF2C14E), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(plass == null ? LopetCopy.ukeliste : LopetCopy.nrPaaListen(plass), style: BergenTokens.display(15, weight: FontWeight.w800, color: Colors.white)),
                        if (s.rival != null)
                          Text(LopetCopy.seilerForan(s.rival!.name, (s.rival!.distanceM - r.distanceM).clamp(1, 1 << 30)), style: BergenTokens.text(12.5, weight: FontWeight.w700, color: Colors.white.withValues(alpha: .8))),
                      ]),
                    ),
                    Text(LopetCopy.seListen, style: BergenTokens.text(13.5, weight: FontWeight.w800, color: const Color(0xFF7FF0CB))),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF7FF0CB)),
                  ]),
                ),
              ),
            ],
          ]),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.ikon, required this.tall, required this.etikett});
  final IconData ikon;
  final String tall;
  final String etikett;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
    decoration: lopetKort(r: 18),
    child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), color: Colors.white.withValues(alpha: .08)), child: Icon(ikon, size: 18, color: const Color(0xFFF7D57E))),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tall, style: BergenTokens.display(18, weight: FontWeight.w800, color: Colors.white)),
          // T3 GAM-E03: «Redningsvest brukt» was cut to «Redningsvest b…» in a half-width tile.
          Text(etikett, maxLines: 2, overflow: TextOverflow.ellipsis, style: BergenTokens.text(12, weight: FontWeight.w700, color: Colors.white.withValues(alpha: .7))),
        ]),
      ),
    ]),
  );
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

/// Design 21 Nov plan Step 9: the Bølge front — the quay is cut along a sine wave that rises from the bottom over
/// the transition, the water (play) showing below it.
class _Bolge extends CustomClipper<Path> {
  _Bolge(this.v);
  final double v;

  @override
  Path getClip(Size size) {
    final y0 = size.height * (1 - v);
    final amp = 14 * (1 - (v - .5).abs() * 2).clamp(0.0, 1.0) + 4;
    final p = Path()..moveTo(0, 0)..lineTo(size.width, 0)..lineTo(size.width, y0);
    const steps = 24;
    for (var i = steps; i >= 0; i--) {
      final x = size.width * i / steps;
      p.lineTo(x, y0 + amp * math.sin(i / steps * 2 * math.pi * 1.5 + v * 6));
    }
    return p..close();
  }

  @override
  bool shouldReclip(_Bolge old) => old.v != v;
}
