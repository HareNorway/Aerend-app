import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../sim/engine.dart';
import 'haptikk_moenster.dart';

/// The device's haptics tier (spec §7.1), asked once when the game opens.
enum HaptikkTier { rich, standard, off }

/// The player's setting «Vibrasjon» (spec §8): Full · Dempet · Av.
enum HaptikkNivaaValg { full, soft, off }

/// The native side of `aerend/game_haptics` (spec §11.3). Tests pass a fake.
abstract class HaptikkKanal {
  /// The tier, and when it is off why (`system_off` when the phone's touch feedback is off).
  Future<({HaptikkTier tier, String? why})> capabilities();

  /// Builds every pattern once (Rich and Standard); [scale] is multiplied into every Rich strength.
  Future<void> prepare(Map<String, Object> table, double scale);

  /// Plays one prepared pattern by its key (`h05`, `h02.3`). Never awaited; nothing is built at play time.
  void play(String key);

  void stop();

  Future<void> release();
}

/// The method channel. A missing native side (a test, an old build) is a tier, never a crash.
class MethodHaptikkKanal implements HaptikkKanal {
  const MethodHaptikkKanal();

  static const MethodChannel _ch = MethodChannel('aerend/game_haptics');

  @override
  Future<({HaptikkTier tier, String? why})> capabilities() async {
    try {
      final r = await _ch.invokeMapMethod<String, Object?>('capabilities');
      final t = r?['tier'];
      final tier = t == 'rich'
          ? HaptikkTier.rich
          : t == 'standard'
              ? HaptikkTier.standard
              : HaptikkTier.off;
      return (tier: tier, why: r?['why'] as String?);
    } on MissingPluginException {
      // No native side: the iPhone still has Flutter's HapticFeedback (Standard); anything else is quiet.
      return (tier: defaultTargetPlatform == TargetPlatform.iOS ? HaptikkTier.standard : HaptikkTier.off, why: null);
    } catch (_) {
      return (tier: defaultTargetPlatform == TargetPlatform.iOS ? HaptikkTier.standard : HaptikkTier.off, why: null);
    }
  }

  @override
  Future<void> prepare(Map<String, Object> table, double scale) async {
    try {
      await _ch.invokeMethod<void>('prepare', {'table': table, 'scale': scale});
    } catch (_) {}
  }

  @override
  void play(String key) {
    _ch.invokeMethod<void>('play', {'key': key}).catchError((Object _) {});
  }

  @override
  void stop() {
    _ch.invokeMethod<void>('stop').catchError((Object _) {});
  }

  @override
  Future<void> release() async {
    try {
      await _ch.invokeMethod<void>('release');
    } catch (_) {}
  }
}

/// What happened to a [GameHaptics.play] call — for the tests and the lab.
enum HaptikkUtfall { played, dropped, silent }

/// Fjordløpet haptics plan Step 1 (spec §6, §7, §11): every haptic in and around the game goes through here, and every
/// rule of §6 is kept in this one place.
///
/// - One pattern at a time. A higher event stops a lower pattern; a lower one is dropped, never queued.
/// - On one tick only the highest plays ([playTick]; a crate that fills the meter gives H04).
/// - For 80 ms after a pattern of level 3 or more, levels 1–2 are dropped.
/// - After H13 nothing plays until a touch ([touch]) — except U07.
/// - Paused, in the background or covered ([hold]): stopped, and nothing new plays.
/// - Dempet: H01, H02, H09, H14, U02, U10 are off; the rest at 0.7 on Rich (only the off-list on Standard).
/// - `game.haptics_scale` on every Rich strength; `game.haptics_enabled` off silences everything.
class GameHaptics {
  GameHaptics({
    HaptikkKanal? kanal,
    int Function()? klokke,
    bool? ios,
    void Function(String kind)? standardIos,
  })  : _kanal = kanal ?? const MethodHaptikkKanal(),
        _klokke = klokke ?? _naa,
        _ios = ios ?? defaultTargetPlatform == TargetPlatform.iOS,
        _standardIos = standardIos ?? _flutterStandard;

  static final Stopwatch _sw = Stopwatch()..start();
  static int _naa() => _sw.elapsedMilliseconds;

  final HaptikkKanal _kanal;
  final int Function() _klokke;
  final bool _ios;
  final void Function(String kind) _standardIos;

  HaptikkTier _tier = HaptikkTier.off;
  String? _tierWhy;
  bool _klar = false;

  HaptikkNivaaValg _nivaa = HaptikkNivaaValg.full;
  bool _appAv = false; // the app-wide «Vibrasjon» under Konto is off (DH2)
  bool _policyOn = true;
  double _policyScale = 1.0;
  double? _preparedScale;

  bool _holdt = false; // paused / background / covered
  bool _stille = false; // after H13 until a touch

  HaptikkId? _spiller;
  int _spillerTil = -1;
  int _hvileTil = -1;

  /// The lab's switch: every pattern plays on its own, no rule in the way (single-pattern tuning, Step 8).
  bool utenRegler = false;

  Timer? _dobbel;

  /// The tier the device reported (Off until [prepare] has run).
  HaptikkTier get tier => _tier;

  /// Why the tier is Off (`system_off`: the phone's touch feedback is off — the setting shows its line).
  String? get tierWhy => _tierWhy;

  HaptikkNivaaValg get nivaa => _nivaa;

  /// The level that is in force: Av when the app-wide switch, the policy or the device says so.
  HaptikkNivaaValg get virkelig => !_policyOn || _appAv || _tier == HaptikkTier.off ? HaptikkNivaaValg.off : _nivaa;

  /// The id now playing (tests, the lab).
  HaptikkId? get spiller => _klokke() < _spillerTil ? _spiller : null;

  /// Asks the tier and sends the table once. Safe to call again (a policy or level change re-sends the scale).
  Future<void> prepare() async {
    if (!_klar) {
      final c = await _kanal.capabilities();
      _tier = c.tier;
      _tierWhy = c.why;
      _klar = true;
    }
    await _sendScale();
  }

  double get _scale => (_nivaa == HaptikkNivaaValg.soft ? kDempetStyrke : 1.0) * _policyScale;

  Future<void> _sendScale() async {
    if (_tier == HaptikkTier.off) return;
    if (_ios && _tier == HaptikkTier.standard) return; // the iPhone's Standard is Flutter's HapticFeedback
    final s = double.parse(_scale.toStringAsFixed(3));
    if (_preparedScale == s) return;
    _preparedScale = s;
    await _kanal.prepare(haptikkTabell(), s);
  }

  /// The player's setting.
  void setLevel(HaptikkNivaaValg v) {
    if (_nivaa == v) return;
    _nivaa = v;
    if (v == HaptikkNivaaValg.off) stop();
    unawaited(_sendScale());
  }

  /// The app-wide switch (Meg → Konto «Vibrasjon»); off wins over the game's own setting (DH2).
  void setAppSwitch(bool on) {
    _appAv = !on;
    if (_appAv) stop();
  }

  /// The two policies from `/game/state` (DH8).
  void setPolicy({required bool enabled, required double scale}) {
    _policyOn = enabled;
    _policyScale = scale.clamp(0.5, 1.0).toDouble();
    if (!enabled) stop();
    unawaited(_sendScale());
  }

  /// A new run: the crate row, the pulse and the silence after a collision start over.
  void newRun() {
    _rad = 0;
    _sisteKasse = null;
    _pulsSlutt = false;
    _nesteSlag = null;
    _stille = false;
  }

  /// A touch on the screen ends the silence after H13.
  void touch() => _stille = false;

  /// Paused, in the background or covered: stop now and play nothing new; [on] false lets it play again. The pulse
  /// does not come back in the same approach (spec §4.3).
  void hold(bool on) {
    if (on) {
      _holdt = true;
      _pulsAvbryt();
      stop();
    } else {
      _holdt = false;
    }
  }

  bool get holdt => _holdt;

  /// Stops the pattern that is playing.
  void stop() {
    _dobbel?.cancel();
    _dobbel = null;
    if (_spiller != null && _klokke() < _spillerTil) _kanal.stop();
    _spiller = null;
    _spillerTil = -1;
  }

  Future<void> dispose() async {
    stop();
    _dobbel?.cancel();
    if (_tier != HaptikkTier.off) await _kanal.release();
  }

  static int rang(HaptikkId id) => kHaptikkPrioritet.length - kHaptikkPrioritet.indexOf(id);

  /// The highest of the events of one tick, or null.
  static HaptikkId? hoyest(Iterable<HaptikkId> ids) {
    HaptikkId? best;
    for (final id in ids) {
      if (best == null || rang(id) > rang(best)) best = id;
    }
    return best;
  }

  /// One tick's events: only the highest plays (spec §6).
  HaptikkUtfall playTick(Iterable<HaptikkId> ids, {int step = 0}) {
    final id = hoyest(ids);
    if (id == null) return HaptikkUtfall.dropped;
    return play(id, step: step);
  }

  /// Plays [id] under the rules. [step]: H02's place in the row; [metresLeft]: H09's distance to «Din beste».
  HaptikkUtfall play(HaptikkId id, {int step = 0, double metresLeft = 0}) {
    final now = _klokke();
    if (virkelig == HaptikkNivaaValg.off) return HaptikkUtfall.silent;
    if (!utenRegler) {
      if (_holdt) return HaptikkUtfall.silent;
      if (_stille && id != HaptikkId.u07) return HaptikkUtfall.silent;
      if (_nivaa == HaptikkNivaaValg.soft && kDempetAv.contains(id)) return HaptikkUtfall.silent;
    }
    final steg = haptikkSteg(id, step: step, metresLeft: metresLeft);
    if (_tier == HaptikkTier.standard && !_harStandard(id)) {
      // Nothing on Standard for this one; it neither plays nor blocks anything.
      return HaptikkUtfall.silent;
    }
    final niv = HaptikkNivaa.av(id);
    if (!utenRegler) {
      final pagar = _spiller != null && now < _spillerTil;
      if (pagar) {
        if (rang(id) <= rang(_spiller!)) return HaptikkUtfall.dropped;
        stop();
      } else if (niv <= HaptikkNivaa.pop && now < _hvileTil) {
        return HaptikkUtfall.dropped;
      }
    } else {
      stop();
    }
    _send(id, steg);
    final dur = haptikkVarighet(id, steg);
    _spiller = id;
    _spillerTil = now + dur;
    _hvileTil = niv >= HaptikkNivaa.rush ? _spillerTil + kHvileMs : -1;
    if (id == HaptikkId.h13) {
      _stille = true;
      _pulsStopp();
    } else if (id == HaptikkId.h10) {
      _pulsStopp();
    } else if (id == HaptikkId.h12) {
      _pulsAvbryt();
    }
    return HaptikkUtfall.played;
  }

  /// Plays [id] at the chosen level while the game is paused (the setting's own check, spec §8): past the hold, but
  /// under every other rule.
  void preview(HaptikkId id) {
    final h = _holdt;
    _holdt = false;
    play(id);
    _holdt = h;
  }

  bool _harStandard(HaptikkId id) => _ios ? kStandardIos.containsKey(id) : kStandardAndroid.containsKey(id);

  void _send(HaptikkId id, int steg) {
    if (_tier == HaptikkTier.standard && _ios) {
      final kind = kStandardIos[id]!;
      if (kind == 'heavy2') {
        _standardIos('heavy');
        _dobbel?.cancel();
        _dobbel = Timer(const Duration(milliseconds: 120), () {
          _dobbel = null;
          _standardIos('heavy');
        });
      } else {
        _standardIos(kind);
      }
      return;
    }
    _kanal.play(haptikkNokkel(id, steg));
  }

  static void _flutterStandard(String kind) {
    switch (kind) {
      case 'selection':
        HapticFeedback.selectionClick();
      case 'light':
        HapticFeedback.lightImpact();
      case 'medium':
        HapticFeedback.mediumImpact();
      case 'heavy':
        HapticFeedback.heavyImpact();
    }
  }

  /// Haptics plan Step 4: one tick's engine events (FjordLoop.onTickEvents) — H13 a collision, H05 the vest used, H04
  /// the meter full, H03 a near miss, H02 a crate (its place in the row), H01 a lane change carried out; only the
  /// highest of them plays. The crate row advances even when the pop itself does not play.
  HaptikkUtfall tickEvents(int tick, int ev) {
    var n = 0;
    if (ev & FjordSim.evCrate != 0) n = crate(tick);
    if (ev & FjordSim.evHit != 0) collision();
    final id = ev & FjordSim.evHit != 0
        ? HaptikkId.h13
        : ev & FjordSim.evVest != 0
            ? HaptikkId.h05
            : ev & FjordSim.evMeterFull != 0
                ? HaptikkId.h04
                : ev & FjordSim.evNearMiss != 0
                    ? HaptikkId.h03
                    : ev & FjordSim.evCrate != 0
                        ? HaptikkId.h02
                        : ev & FjordSim.evLane != 0
                            ? HaptikkId.h01
                            : null;
    if (id == null) return HaptikkUtfall.dropped;
    return play(id, step: n);
  }

  // ── The crate row (DH6): crates less than 90 ticks apart; a near miss neither advances nor breaks it ─────────────

  int _rad = 0;
  int? _sisteKasse;

  /// A crate taken at [tick]: its place in the row (1, 2, 3 …). The sound and H02 both read it.
  int crate(int tick) {
    final s = _sisteKasse;
    _rad = s != null && tick - s < kKasseRadTikk ? _rad + 1 : 1;
    _sisteKasse = tick;
    return _rad;
  }

  int get rad => _rad;

  // ── The pulse before «Din beste» (spec §4.3) ───────────────────────────────────────────────────────────────────

  bool _pulsSlutt = false;
  int? _nesteSlag;

  bool get pulsStoppet => _pulsSlutt;

  void _pulsStopp() {
    _pulsSlutt = true;
    _nesteSlag = null;
  }

  /// Stops a pulse that is beating; before the approach it changes nothing.
  void _pulsAvbryt() {
    if (_nesteSlag != null) _pulsStopp();
  }

  /// The pulse is beating (inside the last 60 m).
  bool get pulsAktiv => _nesteSlag != null;

  /// The beat interval at [metresLeft]: 800 ms at 60 m down to 350 ms at 0 m, on a line.
  static int slagMs(double metresLeft) =>
      (kPulsRaskMs + (kPulsLangsomMs - kPulsRaskMs) * (metresLeft.clamp(0, kPulsFraM) / kPulsFraM)).round();

  /// Called every frame of a run with the metres to «Din beste», or null when there is no best to chase (none yet,
  /// already passed in this run). Plays a beat when one is due. Returns true when a beat was sent.
  bool pulse(double? metresLeft) {
    if (_pulsSlutt) return false;
    if (metresLeft == null || metresLeft > kPulsFraM) {
      _nesteSlag = null;
      return false;
    }
    if (metresLeft <= 0) {
      _pulsStopp(); // passed: the approach is over
      return false;
    }
    final now = _klokke();
    final neste = _nesteSlag;
    if (neste != null && now < neste) return false;
    _nesteSlag = now + slagMs(metresLeft);
    return play(HaptikkId.h09, metresLeft: metresLeft) == HaptikkUtfall.played;
  }

  /// A collision ends the pulse too (with H13).
  void collision() => _pulsStopp();
}
