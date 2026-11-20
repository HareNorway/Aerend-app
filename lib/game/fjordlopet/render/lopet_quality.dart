import '../../../utils/shared_pref_utill.dart';

/// The three quality levels (spec §12.5), lowest first so `index` orders them.
enum LopetNivaa { low, medium, high }

extension LopetNivaaX on LopetNivaa {
  String get key => name;

  /// The water shader's work, as a share of full detail (spec §12.5: «Shader at 0.75 / 0.5 scale»).
  double get waterScale => switch (this) { LopetNivaa.high => .75, LopetNivaa.medium => .5, LopetNivaa.low => 0 };
  bool get shader => this != LopetNivaa.low;
  bool get foamMap => this != LopetNivaa.low;

  /// Reflections: all objects at High, the boat only at Medium, none at Low.
  bool get reflectAll => this == LopetNivaa.high;
  bool get reflectBoat => this != LopetNivaa.low;
  bool get cloudShadows => this == LopetNivaa.high;
  int get particles => switch (this) { LopetNivaa.high => 256, LopetNivaa.medium => 128, LopetNivaa.low => 48 };

  static LopetNivaa parse(Object? v, [LopetNivaa fallback = LopetNivaa.medium]) =>
      LopetNivaa.values.firstWhere((l) => l.name == '$v', orElse: () => fallback);
}

/// Fjordløpet v1.3 plan Step 9 (spec §12.5, T32, T33): which level the game draws at.
///
/// - The level is stored on the device; a new install starts at Medium.
/// - The policy caps it: `game.quality_max` for everyone, and Low for a device model in `game.quality_low_models`
///   (the server answers `quality.low_model` for the model the app sends). A shader that fails to load means Low for
///   the session.
/// - Raised one step after a whole run whose p99 frame time is under `up_p99_ms`.
/// - Lowered one step at once when the average over the last 2 s is above `down_avg_ms`, and then kept for the rest of
///   the session (no step up or down after that).
///
/// The simulation never reads this: speed, hitboxes and results are the same at every level (T31).
class LopetQuality {
  LopetQuality({
    LopetNivaa? stored,
    this.policyMax = LopetNivaa.high,
    this.lowModel = false,
    this.upP99Ms = 14,
    this.downAvgMs = 18,
    this.framesFor2s = 120,
  }) : _stored = stored ?? LopetNivaa.medium;

  /// From `/game/state`'s `quality` {max, low_model, up_p99_ms, down_avg_ms} and the level kept on the phone.
  factory LopetQuality.fromState(Map<String, dynamic> q, {LopetNivaa? stored}) => LopetQuality(
        stored: stored ?? LopetQuality.load(),
        policyMax: LopetNivaaX.parse(q['max'], LopetNivaa.high),
        lowModel: q['low_model'] == true,
        upP99Ms: (q['up_p99_ms'] as num?)?.toDouble() ?? 14,
        downAvgMs: (q['down_avg_ms'] as num?)?.toDouble() ?? 18,
      );

  static const prefKey = 'lopet_quality';

  final LopetNivaa policyMax;
  final bool lowModel;
  final double upP99Ms;
  final double downAvgMs;

  /// How many frames make «2 s» (60 Hz); the drop rule waits for that many frames at the current level.
  final int framesFor2s;

  LopetNivaa _stored;
  bool _shaderFailed = false;
  bool _lockedDown = false;
  int _framesAtLevel = 0;

  /// The cap from the policy and the device.
  LopetNivaa get cap => _shaderFailed || lowModel ? LopetNivaa.low : policyMax;

  /// The level drawn now.
  LopetNivaa get level => _stored.index <= cap.index ? _stored : cap;

  bool get lockedDown => _lockedDown;
  bool get shaderFailed => _shaderFailed;

  /// The water shader did not load: Low for this session, nothing else changes (T32).
  void markShaderFailed() => _shaderFailed = true;

  /// A frame at the current level with the average over the last 2 s; true when the level just dropped (T33).
  bool frame(double recentAvgMs) {
    if (_lockedDown) return false;
    _framesAtLevel++;
    if (_framesAtLevel < framesFor2s || recentAvgMs <= downAvgMs || level == LopetNivaa.low) return false;
    _stored = LopetNivaa.values[level.index - 1];
    _lockedDown = true;
    _framesAtLevel = 0;
    _save();
    return true;
  }

  /// A whole run ended with this p99: one step up when it was under the threshold (and nothing dropped this session).
  bool afterRun(double p99Ms, {required int frames}) {
    _framesAtLevel = 0;
    if (_lockedDown || frames < framesFor2s || p99Ms <= 0 || p99Ms >= upP99Ms) return false;
    if (level.index >= cap.index || _stored.index >= LopetNivaa.high.index) return false;
    _stored = LopetNivaa.values[level.index + 1];
    _save();
    return true;
  }

  /// A new run starts: the drop rule counts its 2 s again.
  void runStarted() => _framesAtLevel = 0;

  static LopetNivaa load() {
    try {
      final v = prefGetString(prefKey);
      return v.isEmpty ? LopetNivaa.medium : LopetNivaaX.parse(v);
    } catch (_) {
      return LopetNivaa.medium;
    }
  }

  void _save() {
    try {
      prefSetString(prefKey, _stored.key);
    } catch (_) {}
  }
}
