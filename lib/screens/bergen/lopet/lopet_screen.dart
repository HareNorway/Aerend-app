import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../game/fjordlopet/input/lopet_input.dart';
import '../../../game/fjordlopet/render/lopet_atlas.dart';
import '../../../game/fjordlopet/render/lopet_field_painter.dart';
import '../../../game/fjordlopet/render/lopet_loop.dart';
import '../../../game/fjordlopet/sim/engine.dart';
import '../kit/bergen_kit.dart';
import '../../../services/lopet_utboks.dart';
import 'lopet_copy.dart';
import 'lopet_liste.dart';
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
  const LopetScreen({super.key, this.orderId, this.api, this.pollEvery = const Duration(seconds: 6)});

  final int? orderId;
  final LopetApi? api;
  final Duration pollEvery;

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

  String? _pauseGrunn; // manuell | bakgrunn | trenger
  int? _teller;

  FjordResult? _res;
  String _sluttGrunn = 'kollisjon'; // kollisjon | ved_dora
  int _sluttPoeng = 0;
  int? _sluttFraRekord;
  bool _sluttRekord = false;
  bool _lyd = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    WidgetsBinding.instance.addObserver(this);
    _sig = LopetSignaler.stream.listen(_onSignal);
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
    _poll?.cancel();
    _nedtelling?.cancel();
    _vestTimer?.cancel();
    _krasjTimer?.cancel();
    // Leaving mid-run (the route replaced, the app closing the screen): the run is kept and its token spent.
    if ((_fase == _Fase.spill || _fase == _Fase.pause) && _token != null) unawaited(_avslutt('forlatt', vis: false));
    _ticker.dispose();
    _perf.stop();
    _loop?.dispose();
    _atlas?.dispose();
    _sVn.dispose();
    _vestMelding.dispose();
    _perfTekst.dispose();
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
      _lyd = s.soundOn;
      if ((s.delivery['state'] ?? '') == 'arrived_customer') _avslutt('ved_dora');
      return;
    }
    if (s == null) {
      // The window closed: the courier is at the door, or the order was delivered or cancelled.
      if (_fase == _Fase.spill || _fase == _Fase.pause) {
        _avslutt('ved_dora');
      }
      setState(() {
        _laster = false;
        _stengt = true;
      });
      LopetPort.status.value = null;
      return;
    }
    setState(() {
      _s = s;
      _laster = false;
      _stengt = false;
      _lyd = s.soundOn;
    });
    _sVn.value = s;
    _byggAtlas(s);
    LopetPort.status.value = LopetInngang(orderId: s.orderId, runsLeft: _igjen);
    if ((s.delivery['state'] ?? '') == 'arrived_customer' && (_fase == _Fase.spill || _fase == _Fase.pause)) {
      _avslutt('ved_dora');
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
      final a = await LopetAtlas.build(density: dpr >= 2.5 ? 3 : 2, labels: labels);
      if (!mounted) {
        a.dispose();
        return;
      }
      setState(() => _atlas = a);
    } catch (_) {
      // Without an atlas the field draws only the water (the run itself does not depend on it).
    } finally {
      _atlasLaster = false;
    }
  }

  void _settSeil() {
    final s = _s;
    if (s == null || s.noNewRun) return;
    final ledige = LopetLager.ledige(s);
    if (ledige.isEmpty) return;
    _loop?.dispose();
    final loop = FjordLoop(FjordSim(s.course, _perkFor(s, ledige.first)));
    final best = LopetLager.beste(s.week) ?? s.personalBestM;
    _flags
      ..bestMm = best == null ? -1 : best * 1000.0
      ..weekMm = s.weekBestM == null || s.weekBestM == best ? -1 : s.weekBestM! * 1000.0
      ..rivalMm = -1;
    setState(() {
      _token = ledige.first;
      _loop = loop;
      _startetMs = DateTime.now().millisecondsSinceEpoch;
      _res = null;
      _fase = _Fase.spill;
      _pauseGrunn = null;
    });
    _perf.start();
    _rammer = 0;
    loop.resetClock();
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final loop = _loop;
    if (loop == null || _fase != _Fase.spill || _krasjTimer != null) return;
    loop.frame(elapsed);
    final ev = loop.takeEvents();
    if (ev != 0) _feedback(ev);
    if (_perfOverlay && ++_rammer % 30 == 0) {
      _perfTekst.value = '${(1000 / (_perf.recentAvgMs(30).clamp(1, 1000))).round()} fps · snitt ${_perf.avgMs.toStringAsFixed(1)} ms · '
          'verst ${_perf.worstMs.toStringAsFixed(1)} ms · >20 ms ${_perf.over20} · Lav';
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
    } else if (ev & FjordSim.evVest != 0) {
      HapticFeedback.heavyImpact();
      _vestMelding.value = true;
      _vestTimer?.cancel();
      _vestTimer = Timer(const Duration(milliseconds: 1500), () => _vestMelding.value = false);
    } else if (ev & (FjordSim.evNearMiss | FjordSim.evMeterFull) != 0) {
      HapticFeedback.mediumImpact();
    } else if (ev & FjordSim.evCrate != 0) {
      HapticFeedback.selectionClick();
    }
  }

  void _styr(int dir) {
    if (_fase != _Fase.spill) return;
    _loop?.input(dir);
    HapticFeedback.selectionClick();
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
    void sett() {
      _res = res;
      _sluttGrunn = grunn;
      _sluttRekord = rekord;
      _sluttFraRekord = forBeste != null && res.distanceM < forBeste ? forBeste - res.distanceM : null;
      _sluttPoeng = s.pointsFor(res.gates, personalBest: rekord);
      _fase = _Fase.slutt;
    }

    if (vis && mounted) {
      setState(sett);
    } else {
      sett();
    }
    await LopetLager.lagre(token: token, s: s, inputs: loop.inputsJson(), result: res.toJson(), startedMs: _startetMs,
        perf: _perf.frames > 0 ? _perf.toJson('low') : null, appVersion: _appVersion);
    if (mounted) setState(() {});
    // Points plan Step 8: the run goes to the server now if there is a network, else later from the outbox.
    unawaited(LopetUtboks.send());
    LopetPort.status.value = LopetInngang(orderId: s.orderId, runsLeft: _igjen);
  }

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
    if (sig == LopetSignal.vedDora) {
      if (_fase == _Fase.spill || _fase == _Fase.pause) _avslutt('ved_dora');
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

  void _tilSporing() {
    if (_fase == _Fase.spill) _pause('manuell');
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      BergenRoutes.push(context, '/bergen/sporing', arguments: {'id': '$_orderId'});
    }
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

  Widget _start() {
    final s = _s;
    if (s == null || _stengt) {
      return _Melding(key: const Key('lopet-stengt'), tekst: LopetCopy.stengt, knapp: LopetCopy.tilSporing, onTap: _tilSporing);
    }
    final igjen = _igjen;
    final beste = LopetLager.beste(s.week) ?? s.personalBestM;
    return ListView(
      key: const Key('lopet-start'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Row(
          children: [
            Expanded(child: Text(LopetCopy.ukensLed, style: BergenTokens.display(28, weight: FontWeight.w800, color: Colors.white, letterSpacingEm: -0.03))),
            IconButton(
              key: const Key('lopet-lyd'),
              tooltip: LopetCopy.lyd,
              onPressed: () {
                setState(() => _lyd = !_lyd);
                _api.sound(_lyd);
              },
              icon: Icon(_lyd ? Icons.volume_up_rounded : Icons.volume_off_rounded, color: Colors.white70),
            ),
          ],
        ),
        // Points plan Step 13 (game spec §5.3): the Platina boat sails under its own name.
        Text([s.week, s.losgrad, if ((s.boatName ?? '').isNotEmpty) s.boatName!].join(' · '), style: BergenTokens.text(13, weight: FontWeight.w700, color: const Color(0xFF7FF0CB))),
        if (s.bonusGranted) ...[
          const SizedBox(height: 10),
          _Chip(key: const Key('lopet-bonus'), tekst: LopetCopy.forsinket, farge: const Color(0xFFF2C14E)),
        ],
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Sjokort(s: s, besteM: beste ?? 0),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Tall(etikett: LopetCopy.dinBeste, verdi: beste == null ? '—' : '$beste m'),
                  const SizedBox(height: 12),
                  _Tall(etikett: LopetCopy.ukensBeste, verdi: s.weekBestM == null ? '—' : '${s.weekBestM} m'),
                  const SizedBox(height: 12),
                  for (var k = 0; k < s.milestones.length && k < 3; k++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 10, color: (beste ?? 0) >= s.milestones[k] ? const Color(0xFFF2C14E) : Colors.white24),
                          const SizedBox(width: 8),
                          Text('${LopetCopy.porter[k]} · ${s.milestones[k]} m', style: BergenTokens.text(12.5, weight: FontWeight.w700, color: Colors.white70)),
                        ],
                      ),
                    ),
                  if (_nesteFullMaaler(s)) ...[
                    const SizedBox(height: 6),
                    _Chip(key: const Key('lopet-vest'), tekst: LopetCopy.vest, farge: const Color(0xFFE5532D)),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var k = 0; k < s.runsAllowed; k++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.sailing_rounded, size: 22, color: k < igjen ? Colors.white : Colors.white24),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Center(child: Text(LopetCopy.seilaserIgjen(igjen), key: const Key('lopet-igjen'), style: BergenTokens.text(13, weight: FontWeight.w700, color: Colors.white70))),
        const SizedBox(height: 14),
        if (s.noNewRun) ...[
          _Melding(key: const Key('lopet-snart'), tekst: LopetCopy.snartFremme, knapp: LopetCopy.tilSporing, onTap: _tilSporing),
        ] else if (igjen > 0)
          _Knapp(key: const Key('lopet-sett-seil'), tekst: LopetCopy.settSeil, onTap: _settSeil)
        else
          _Melding(key: const Key('lopet-neste'), tekst: LopetCopy.nesteSeilas, knapp: LopetCopy.tilSporing, onTap: _tilSporing),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextButton(
              key: const Key('lopet-ukeliste-knapp'),
              onPressed: () => LopetListe.vis(context),
              child: Text(LopetCopy.ukeliste, style: BergenTokens.text(13, weight: FontWeight.w700, color: const Color(0xFFF7D57E))),
            ),
            TextButton(
              key: const Key('lopet-vilkaar-knapp'),
              onPressed: _vilkaar,
              child: Text(LopetCopy.vilkaar, style: BergenTokens.text(13, weight: FontWeight.w700, color: const Color(0xFF7FF0CB))),
            ),
          ],
        ),
      ],
    );
  }

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
              child: atlas == null
                  ? const ColoredBox(color: Color(0xFF155A70))
                  : CustomPaint(
                      painter: LopetFieldPainter(loop: loop, atlas: atlas, boat: s.boat, milestones: s.milestones, flags: _flags, rolig: rolig),
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
    return ListView(
      key: const Key('lopet-slutt'),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      children: [
        Text(LopetCopy.over, textAlign: TextAlign.center, style: BergenTokens.text(12, weight: FontWeight.w800, color: const Color(0xFF7FF0CB)).copyWith(letterSpacing: 2)),
        const SizedBox(height: 8),
        Text('${r.distanceM} m', key: const Key('lopet-slutt-meter'), textAlign: TextAlign.center, style: BergenTokens.display(48, weight: FontWeight.w800, color: Colors.white)),
        if (_sluttRekord)
          Text(LopetCopy.nyRekord, textAlign: TextAlign.center, style: BergenTokens.text(14, weight: FontWeight.w800, color: const Color(0xFFF7D57E)))
        else if (_sluttFraRekord != null)
          Text(LopetCopy.fraRekorden(_sluttFraRekord!), textAlign: TextAlign.center, style: BergenTokens.text(14, weight: FontWeight.w700, color: Colors.white70)),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var k = 0; k < (s?.milestones.length ?? 0) && k < 3; k++)
              _Chip(tekst: LopetCopy.porter[k], farge: r.gates.contains(s!.milestones[k]) ? const Color(0xFFF2C14E) : Colors.white24),
            if (r.vestUses > 0) _Chip(tekst: LopetCopy.vestTok, farge: const Color(0xFFE5532D)),
          ],
        ),
        if (_sluttPoeng > 0) ...[
          const SizedBox(height: 14),
          Text(LopetCopy.poengVedLevering(_sluttPoeng), key: const Key('lopet-slutt-poeng'), textAlign: TextAlign.center,
              style: BergenTokens.text(15, weight: FontWeight.w800, color: const Color(0xFFF7D57E))),
        ],
        const SizedBox(height: 26),
        if (vedDora)
          _Melding(key: const Key('lopet-slutt-dora'), tekst: LopetCopy.vedDora, knapp: LopetCopy.tilSporing, onTap: _tilSporing)
        else if (s != null && s.noNewRun)
          _Melding(tekst: LopetCopy.snartFremme, knapp: LopetCopy.tilSporing, onTap: _tilSporing)
        else if (igjen > 0)
          _Knapp(key: const Key('lopet-seil-igjen'), tekst: LopetCopy.seilIgjen(igjen), onTap: _settSeil)
        else
          _Melding(key: const Key('lopet-slutt-neste'), tekst: LopetCopy.nesteSeilas, knapp: LopetCopy.tilSporing, onTap: _tilSporing),
      ],
    );
  }
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
  const _Sjokort({required this.s, required this.besteM});

  final LopetState s;
  final int besteM;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('lopet-sjokort'),
      width: 96,
      height: 230,
      decoration: BoxDecoration(color: const Color(0xFF123F50), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white24)),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(painter: _SjokortMaler(s: s, besteM: besteM)),
    );
  }
}

class _SjokortMaler extends CustomPainter {
  _SjokortMaler({required this.s, required this.besteM});

  final LopetState s;
  final int besteM;

  @override
  void paint(Canvas canvas, Size size) {
    const visM = 1200.0; // the chart shows the first 1 200 m
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
      canvas.drawCircle(Offset(x, y(m)), 2.6, Paint()..color = r['t'] == 'boye' ? const Color(0xFFE5532D) : Colors.white70);
    }
    for (final g in s.milestones) {
      if (g > visM) continue;
      canvas.drawLine(Offset(6, y(g)), Offset(size.width - 6, y(g)), Paint()..color = const Color(0xFFF2C14E)..strokeWidth = 2);
    }
    // Fog above the best distance.
    final fog = Rect.fromLTRB(0, 0, size.width, y(seen));
    canvas.drawRect(fog, Paint()..shader = LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.white.withValues(alpha: .08), Colors.white.withValues(alpha: .45)]).createShader(fog));
  }

  @override
  bool shouldRepaint(_SjokortMaler old) => old.besteM != besteM;
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
