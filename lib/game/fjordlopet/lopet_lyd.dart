import 'package:audioplayers/audioplayers.dart';

/// Fjordløpet v1.3 plan Step 6 (spec v1.3 §7 Sound, §12.1 «heard», plan D9): the game's sounds.
///
/// The nine sounds of the design prototype, rendered once to `assets/game/sounds/` by `tool/fjordlopet_sounds.dart`.
/// Off until the customer turns it on; it follows the phone's silent switch and ducks under nothing — a notification
/// sound always wins (the game never asks for audio focus). Loaded when the session opens, so nothing decodes during a
/// run. Every call is safe without a player (tests, platforms without one): a sound that fails is simply not heard,
/// and every sound has a visual twin.
class LopetLyd {
  LopetLyd({this.on = false});

  bool on;
  final Map<String, AudioPool> _pools = {};
  bool _lastet = false;
  int _kasseN = 0;
  DateTime _kasseT = DateTime.fromMillisecondsSinceEpoch(0);

  static const List<String> navn = ['bytte', 'naer', 'full', 'vest', 'port', 'rekord', 'treff', 'blip'];

  /// Loads every sound (call when the session opens).
  Future<void> last() async {
    if (_lastet) return;
    _lastet = true;
    try {
      await AudioPlayer.global.setAudioContext(AudioContextConfig(respectSilence: true, stayAwake: false, focus: AudioContextConfigFocus.mixWithOthers).build());
      for (final n in [...navn, for (var k = 0; k < 15; k++) 'kasse_$k']) {
        _pools[n] = await AudioPool.createFromAsset(path: 'game/sounds/$n.wav', maxPlayers: n.startsWith('kasse') ? 2 : 3);
      }
    } catch (_) {
      _pools.clear(); // no player here: the game stays silent
    }
  }

  DateTime _stilleTil = DateTime.fromMillisecondsSinceEpoch(0);

  /// A notification sound always wins: the game keeps quiet for [d].
  void stille([Duration d = const Duration(seconds: 2)]) => _stilleTil = DateTime.now().add(d);

  void spill(String n) {
    if (!on || DateTime.now().isBefore(_stilleTil)) return;
    try {
      _pools[n]?.start(volume: .9);
    } catch (_) {}
  }

  /// The crate note rises one step for each crate in a row; resets after 1.5 s (spec §12.1).
  /// [rad]: the crate's place in the row from GameHaptics (1, 2 …, counted in ticks — haptics plan DH6); without it
  /// the row is counted here by the clock, as before.
  void kasse([int? rad]) {
    final now = DateTime.now();
    _kasseN = rad != null
        ? (rad - 1).clamp(0, 14)
        : now.difference(_kasseT) > const Duration(milliseconds: 1500)
            ? 0
            : (_kasseN + 1).clamp(0, 14);
    _kasseT = now;
    spill('kasse_$_kasseN');
  }

  Future<void> dispose() async {
    for (final p in _pools.values) {
      try {
        await p.dispose();
      } catch (_) {}
    }
    _pools.clear();
  }
}
