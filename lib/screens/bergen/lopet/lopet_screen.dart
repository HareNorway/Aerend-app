import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../game/fjordlopet/sim/engine.dart';
import '../kit/bergen_kit.dart';
import '../../../services/lopet_utboks.dart';
import 'lopet_copy.dart';
import 'lopet_data.dart';
import 'lopet_painter.dart';

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
  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);
  StreamSubscription<LopetSignal>? _sig;
  Timer? _poll;
  Timer? _nedtelling;

  int _orderId = 0;
  LopetState? _s;
  bool _laster = true;
  bool _stengt = false;
  _Fase _fase = _Fase.start;

  FjordSim? _sim;
  String? _token;
  final List<List<int>> _inputs = [];
  final List<int> _venter = [];
  int _tickBase = 0;
  int _startetMs = 0;
  double _dragDx = 0;
  bool _dragBrukt = false;

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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sig?.cancel();
    _poll?.cancel();
    _nedtelling?.cancel();
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  // ── session ──────────────────────────────────────────────────────────────

  Future<void> _hent({bool stille = false}) async {
    final s = _orderId > 0 ? await _api.state(_orderId) : null;
    if (!mounted) return;
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

  void _settSeil() {
    final s = _s;
    if (s == null || s.noNewRun) return;
    final ledige = LopetLager.ledige(s);
    if (ledige.isEmpty) return;
    setState(() {
      _token = ledige.first;
      _sim = FjordSim(s.course, s.perk);
      _inputs.clear();
      _venter.clear();
      _tickBase = 0;
      _startetMs = DateTime.now().millisecondsSinceEpoch;
      _res = null;
      _fase = _Fase.spill;
      _pauseGrunn = null;
    });
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final sim = _sim;
    if (sim == null || _fase != _Fase.spill) return;
    final target = _tickBase + elapsed.inMicroseconds * 60 ~/ 1000000;
    var steps = 0;
    while (sim.tick < target && !sim.done && steps < 12) {
      final dirs = List<int>.of(_venter);
      _venter.clear();
      for (final d in dirs) {
        _inputs.add([sim.tick, d]);
      }
      sim.stepTick(dirs);
      steps++;
    }
    _repaint.value++;
    if (sim.done) _avslutt('kollisjon');
  }

  void _styr(int dir) {
    if (_fase != _Fase.spill) return;
    _venter.add(dir);
  }

  void _pause(String grunn) {
    if (_fase != _Fase.spill) return;
    _ticker.stop();
    _tickBase = _sim?.tick ?? 0;
    _nedtelling?.cancel();
    setState(() {
      _fase = _Fase.pause;
      _pauseGrunn = grunn;
      _teller = null;
    });
  }

  /// 3 · 2 · 1, 800 ms each, then on.
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
        _ticker.start();
      } else {
        setState(() => _teller = (_teller ?? 3) - 1);
      }
    });
  }

  Future<void> _avslutt(String grunn) async {
    final sim = _sim;
    final s = _s;
    final token = _token;
    if (sim == null || s == null || token == null || _fase == _Fase.slutt) return;
    if (_ticker.isActive) _ticker.stop();
    _nedtelling?.cancel();
    final res = sim.result();
    final forBeste = LopetLager.beste(s.week) ?? s.personalBestM;
    final rekord = forBeste != null && res.distanceM > forBeste;
    setState(() {
      _res = res;
      _sluttGrunn = grunn;
      _sluttRekord = rekord;
      _sluttFraRekord = forBeste != null && res.distanceM < forBeste ? forBeste - res.distanceM : null;
      _sluttPoeng = s.pointsFor(res.gates, personalBest: rekord);
      _fase = _Fase.slutt;
      _token = null;
    });
    await LopetLager.lagre(token: token, s: s, inputs: List.of(_inputs), result: res.toJson(), startedMs: _startetMs);
    if (mounted) setState(() {});
    // Points plan Step 8: the run goes to the server now if there is a network, else later from the outbox.
    unawaited(LopetUtboks.send());
    LopetPort.status.value = LopetInngang(orderId: s.orderId, runsLeft: _igjen);
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
    if (state != AppLifecycleState.resumed) _pause('bakgrunn');
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
    return Scaffold(
      backgroundColor: const Color(0xFF0C2A38),
      body: SafeArea(
        child: Column(
          children: [
            _Stripe(s: _s, stengt: _stengt, onTap: _tilSporing, onTilbake: () => Navigator.of(context).maybePop()),
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
        Text('${s.week} · ${s.losgrad}', style: BergenTokens.text(13, weight: FontWeight.w700, color: const Color(0xFF7FF0CB))),
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
                  if (s.perk == 'vest') ...[
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
        Center(
          child: TextButton(
            key: const Key('lopet-vilkaar-knapp'),
            onPressed: _vilkaar,
            child: Text(LopetCopy.vilkaar, style: BergenTokens.text(13, weight: FontWeight.w700, color: const Color(0xFF7FF0CB))),
          ),
        ),
      ],
    );
  }

  Widget _spill() {
    final sim = _sim!;
    final s = _s!;
    final rolig = MediaQuery.of(context).disableAnimations;
    return LayoutBuilder(
      builder: (context, box) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: const Key('lopet-felt'),
              behavior: HitTestBehavior.opaque,
              // Tap the left or right half of the screen (full-height targets), or swipe 22 px.
              onTapUp: (d) => _styr(d.localPosition.dx < box.maxWidth / 2 ? -1 : 1),
              onHorizontalDragStart: (_) {
                _dragDx = 0;
                _dragBrukt = false;
              },
              onHorizontalDragUpdate: (d) {
                if (_dragBrukt) return;
                _dragDx += d.delta.dx;
                if (_dragDx.abs() >= 22) {
                  _dragBrukt = true;
                  _styr(_dragDx < 0 ? -1 : 1);
                }
              },
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: LopetPainter(sim: sim, boat: s.boat, milestones: s.milestones, portNavn: LopetCopy.porter, rolig: rolig, repaint: _repaint),
                ),
              ),
            ),
          ),
          // HUD
          Positioned(
            left: 16,
            top: 12,
            right: 16,
            child: ValueListenableBuilder<int>(
              valueListenable: _repaint,
              builder: (_, __, ___) {
                final m = sim.sailedM + sim.crates * sim.crateM;
                String? neste;
                for (var k = 0; k < s.milestones.length && k < 3; k++) {
                  if (sim.sailedM < s.milestones[k]) {
                    neste = LopetCopy.omMeter(LopetCopy.porter[k], s.milestones[k] - sim.sailedM);
                    break;
                  }
                }
                final vestNa = sim.vestHitTick != null && sim.tick - sim.vestHitTick! < 90;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$m m', key: const Key('lopet-meter'), style: BergenTokens.display(30, weight: FontWeight.w800, color: Colors.white)),
                        if (neste != null) Text(neste, style: BergenTokens.text(12.5, weight: FontWeight.w700, color: const Color(0xFFF7D57E))),
                        if (vestNa) Text(LopetCopy.vestTok, style: BergenTokens.text(12.5, weight: FontWeight.w800, color: const Color(0xFFFF9C7A))),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      key: const Key('lopet-pause-knapp'),
                      onPressed: () => _pause('manuell'),
                      icon: const Icon(Icons.pause_circle_filled_rounded, color: Colors.white, size: 36),
                    ),
                  ],
                );
              },
            ),
          ),
          if (_fase == _Fase.pause) Positioned.fill(child: _pauseLag()),
        ],
      ),
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
            if (r.vestUsed) _Chip(tekst: LopetCopy.vestTok, farge: const Color(0xFFE5532D)),
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
