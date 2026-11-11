import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../utils/shared_pref_utill.dart' show prefGetBoolOr, prefSetBool;
import 'kglatt.dart';

const MethodChannel _channel = MethodChannel('aerend/haptic');

/// The vibration kinds of the customer app — the Partner app's kinds (Kunde
/// Glatt D3), plus the games' single heavy pulse. The name is what the
/// Android channel plays and the `PERF_HAPTIKK kind=` log prints.
enum AeVib { tikk, fast, suksess, feil, tung }

/// Haptic feedback for the whole customer app (Kunde Glatt Steps 2–4, the
/// Partner app's `PartnerHaptikk` as the template):
///
/// * [tikk] — the lightest tick: a tap was taken (button, tab, chip, toggle,
///   key, a sheet opened by a tap), an orb passing the wheel's front;
/// * [fast] — a firm tap: an action the customer started succeeded (into
///   the basket, favourite saved, address saved, handed to payment);
/// * [suksess] — a double tap: the payment landed, a code was accepted, a
///   Fjordfiske catch;
/// * [feil] — a short buzz: a failure the customer sees;
/// * [tung] — one heavy pulse, only where a game or a sequence already had
///   one (Automat's bag, Bekreftet's landing): today's pattern, unchanged.
///
/// Android drives the motor directly (`aerend/haptic` in `MainActivity.kt`,
/// tagged media, so it plays with the phone's touch-vibration off); iOS uses
/// the system feedback generators, which follow the phone's System Haptics
/// switch. The in-app «Vibrasjon» switch ([vibrasjon], Meg → Konto) silences
/// every kind. D4 throttle: at most one [tikk] per 50 ms, and a [tikk] within
/// 150 ms after a stronger kind is dropped.
///
/// Harness `kglattVib: false` (debug / profile): the app vibrates as before
/// the plan — each routed call plays its old `HapticFeedback` call ([vib]'s
/// `gammel`), the plan's new ones (`ny: true`) stay silent.
abstract final class AeHaptikk {
  static void tikk({VoidCallback? gammel, bool ny = false}) => vib(AeVib.tikk, gammel: gammel, ny: ny);
  static void fast({VoidCallback? gammel, bool ny = false}) => vib(AeVib.fast, gammel: gammel, ny: ny);
  static void suksess({VoidCallback? gammel, bool ny = false}) => vib(AeVib.suksess, gammel: gammel, ny: ny);
  static void feil({VoidCallback? gammel, bool ny = true}) => vib(AeVib.feil, gammel: gammel, ny: ny);
  static void tung({VoidCallback? gammel, bool ny = false}) => vib(AeVib.tung, gammel: gammel, ny: ny);

  /// The SharedPreferences key of the «Vibrasjon» switch (default on).
  static const String prefVibrasjon = 'ae_vibrasjon';

  /// The «Vibrasjon» switch: on unless the customer turned it off.
  static bool get vibrasjon {
    try {
      return prefGetBoolOr(prefVibrasjon, true);
    } catch (_) {
      return true;
    }
  }

  static Future<void> settVibrasjon(bool on) async {
    try {
      await prefSetBool(prefVibrasjon, on);
    } catch (_) {}
  }

  /// D4: at most one [tikk] per this window.
  static const int tikkVinduMs = 50;

  /// D4: a [tikk] this soon after a stronger kind is dropped.
  static const int etterSterkMs = 150;

  /// Milliseconds on a monotonic clock. Tests replace it.
  static int Function() klokke = _naa;

  /// Plays a kind on the device. Tests replace it to record what passed the
  /// switches and the throttle.
  static Future<void> Function(AeVib kind) native = spillPaaEnhet;

  static final Stopwatch _ur = Stopwatch()..start();
  static int _naa() => _ur.elapsedMilliseconds;

  static int? _sisteTikk;
  static int? _sisteSterk;
  static int _stille = 0;

  @visibleForTesting
  static void nullstill() {
    _sisteTikk = null;
    _sisteSterk = null;
    _stille = 0;
    klokke = _naa;
    native = spillPaaEnhet;
  }

  /// Runs [f] with [tikk] muted: the tap's own tick already played (D7: one
  /// tick per taken tap, e.g. `LfPress`'s and its callback's own). Stronger
  /// kinds inside [f] still play.
  static void utenTikk(VoidCallback f) {
    _stille++;
    try {
      f();
    } finally {
      _stille--;
    }
  }

  /// Plays [kind] unless a switch or the throttle says no. [gammel] is the
  /// call this site made before the plan (default: selectionClick for a
  /// tick, mediumImpact for a firm tap, heavyImpact for the rest); [ny] marks
  /// a vibration the plan added.
  static void vib(AeVib kind, {VoidCallback? gammel, bool ny = false}) {
    if (!vibrasjon) return;
    if (!KGlatt.vib) {
      if (ny) return;
      if (!kReleaseMode) debugPrint('PERF_HAPTIKK kind=gammel');
      (gammel ?? _gammel(kind))();
      return;
    }
    final t = klokke();
    if (kind == AeVib.tikk) {
      if (_stille > 0) return;
      if (_sisteTikk != null && t - _sisteTikk! < tikkVinduMs) return;
      if (_sisteSterk != null && t - _sisteSterk! < etterSterkMs) return;
      _sisteTikk = t;
    } else {
      _sisteSterk = t;
    }
    if (!kReleaseMode) debugPrint('PERF_HAPTIKK kind=${kind.name}');
    native(kind).catchError((Object _) {});
  }

  static VoidCallback _gammel(AeVib kind) => switch (kind) {
        AeVib.tikk => HapticFeedback.selectionClick,
        AeVib.fast => HapticFeedback.mediumImpact,
        AeVib.suksess || AeVib.feil || AeVib.tung => HapticFeedback.heavyImpact,
      };

  /// The device layer. Android: the channel (answers true when the motor
  /// played); no vibrator, an old app build or an error → one plain
  /// [HapticFeedback] call. iOS: the selection / impact generators.
  static Future<void> spillPaaEnhet(AeVib kind) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      var spilt = false;
      try {
        spilt = await _channel.invokeMethod<bool>('play', kind.name) ?? false;
      } catch (_) {
        spilt = false;
      }
      if (!spilt) {
        await switch (kind) {
          AeVib.tikk => HapticFeedback.selectionClick(),
          AeVib.fast => HapticFeedback.mediumImpact(),
          AeVib.suksess || AeVib.feil || AeVib.tung => HapticFeedback.heavyImpact(),
        };
      }
      return;
    }
    switch (kind) {
      case AeVib.tikk:
        await HapticFeedback.selectionClick();
      case AeVib.fast:
        await HapticFeedback.mediumImpact();
      case AeVib.suksess:
        await HapticFeedback.heavyImpact();
        Timer(const Duration(milliseconds: 110), HapticFeedback.mediumImpact);
      case AeVib.feil:
        await HapticFeedback.heavyImpact();
        Timer(const Duration(milliseconds: 90), HapticFeedback.heavyImpact);
      case AeVib.tung:
        await HapticFeedback.heavyImpact();
    }
  }
}

// The three helpers from before the plan, kept so their 22 call sites keep
// their meaning: tick → [AeHaptikk.tikk], confirm → [AeHaptikk.fast],
// success → [AeHaptikk.suksess]. With `kglattVib: false` they play exactly
// what they played before (the channel's old kinds).

/// A subtle tick: a card or an option comes to the front.
void aeTick() => AeHaptikk.tikk(gammel: () => _gammelKanal('tick', HapticFeedback.selectionClick));

/// A firm tap: something went into the basket, the pay slider reached the end.
void aeConfirm() => AeHaptikk.fast(gammel: () => _gammelKanal('confirm', HapticFeedback.mediumImpact));

/// A double tap: a Fjordfiske catch, a secured surprise bag, the order moved on.
void aeSuccess() => AeHaptikk.suksess(
      gammel: () => _gammelKanal('success', () {
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 110), HapticFeedback.mediumImpact);
      }),
    );

void _gammelKanal(String kind, VoidCallback ios) {
  if (defaultTargetPlatform == TargetPlatform.android) {
    _channel.invokeMethod<void>('play', kind).catchError((Object _) => HapticFeedback.lightImpact());
  } else {
    ios();
  }
}
