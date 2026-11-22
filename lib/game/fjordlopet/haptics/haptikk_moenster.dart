/// Fjordløpet haptics plan Step 1 (haptics spec v1.0 §3–§6): every pattern of the game, in one file.
///
/// The values are the spec's starting values (§5). They are tuned by hand on the reference phones in chunk H3 (TH13)
/// and the tuned table replaces them here — tuning is a change in this one file. The table is sent to the native side
/// once, in `prepare()`; nothing is built at play time.
library;

/// The 25 patterns: H01–H14 during a run, U01–U11 around it (spec §4).
enum HaptikkId {
  h01, // lane tick
  h02, // crate pop (step = the crate's place in the row)
  h03, // near miss
  h04, // vest ready
  h05, // vest used
  h06, // Bøye 1
  h07, // Bøye 2
  h08, // Bryggen
  h09, // pulse (step = the 10 m band to «Din beste», 0 = 50–60 m … 5 = 0–10 m)
  h10, // new best
  h11, // rival passed
  h12, // week's best passed
  h13, // collision
  h14, // go
  u01, // set sail
  u02, // countdown
  u03, // pause
  u04, // knock
  u05, // knock-knock
  u06, // points paid
  u07, // badge
  u08, // good news
  u09, // not available
  u10, // selection
  u11, // fanfare
}

/// The strength levels (spec §3.1); the knock stands outside them and ranks as strong.
abstract final class HaptikkNivaa {
  static const int tick = 1, pop = 2, rush = 3, hit = 4, blow = 5, knock = 6;

  static int av(HaptikkId id) => switch (id) {
        HaptikkId.h01 || HaptikkId.u02 || HaptikkId.u10 => tick,
        HaptikkId.h02 || HaptikkId.h09 || HaptikkId.u03 || HaptikkId.u06 => pop,
        HaptikkId.h03 || HaptikkId.h04 || HaptikkId.h11 || HaptikkId.h14 || HaptikkId.u01 || HaptikkId.u08 || HaptikkId.u09 => rush,
        HaptikkId.h05 || HaptikkId.h06 || HaptikkId.h07 || HaptikkId.h08 || HaptikkId.h10 || HaptikkId.h12 || HaptikkId.u07 || HaptikkId.u11 => hit,
        HaptikkId.h13 => blow,
        HaptikkId.u04 || HaptikkId.u05 => knock,
      };
}

/// The order of priority (spec §6), highest first. The run's list is the spec's; the U patterns, which never meet a run
/// pattern (U04 waits for the run to end), sit by their level so the rule stays total.
const List<HaptikkId> kHaptikkPrioritet = [
  HaptikkId.u05,
  HaptikkId.u04,
  HaptikkId.h13,
  HaptikkId.h05,
  HaptikkId.h12,
  HaptikkId.h10,
  HaptikkId.u11,
  HaptikkId.u07,
  HaptikkId.h08,
  HaptikkId.h07,
  HaptikkId.h06,
  HaptikkId.h04,
  HaptikkId.h03,
  HaptikkId.u01,
  HaptikkId.u08,
  HaptikkId.u09,
  HaptikkId.h11,
  HaptikkId.h02,
  HaptikkId.u06,
  HaptikkId.u03,
  HaptikkId.h14,
  HaptikkId.h01,
  HaptikkId.u02,
  HaptikkId.u10,
  HaptikkId.h09,
];

/// Dempet (spec §6): these are off; every other pattern plays at [kDempetStyrke] on Rich.
const Set<HaptikkId> kDempetAv = {HaptikkId.h01, HaptikkId.h02, HaptikkId.h09, HaptikkId.h14, HaptikkId.u02, HaptikkId.u10};
const double kDempetStyrke = 0.7;

/// The crate row: crates less than 1.5 s apart (spec §4.1 H02), counted in ticks at 60 Hz.
const int kKasseRadTikk = 90;

/// No pattern is longer than this (spec §6).
const int kMaksMs = 850;

/// After a pattern of level 3 or more has ended, levels 1–2 are dropped for this long (spec §6).
const int kHvileMs = 80;

/// The pulse (spec §4.3): from 60 m before «Din beste», a beat every 800 ms at 60 m down to 350 ms at 0 m.
const int kPulsFraM = 60;
const int kPulsLangsomMs = 800;
const int kPulsRaskMs = 350;

/// The step of a pattern that has steps: H02 by its place in the row (1–5), H09 by its 10 m band (0–5).
int haptikkSteg(HaptikkId id, {int step = 0, double metresLeft = 0}) => switch (id) {
      HaptikkId.h02 => step.clamp(1, 5),
      HaptikkId.h09 => (5 - (metresLeft.clamp(0, 59.999) ~/ 10)).clamp(0, 5),
      _ => 0,
    };

/// The key a variant is sent and played under: `h02.3`, `h09.5`, or the id alone.
String haptikkNokkel(HaptikkId id, int step) => id == HaptikkId.h02 || id == HaptikkId.h09 ? '${id.name}.$step' : id.name;

// ── iPhone, Rich (Core Haptics, spec §5.2) ──────────────────────────────────────────────────────────────────────────
// A transient: ['T', time ms, intensity, sharpness]. A continuous event with an intensity curve:
// ['C', start ms, end ms, intensity from, intensity to, sharpness].

List<Object> _t(int ms, double i, double s) => ['T', ms, i, s];
List<Object> _c(int from, int to, double i0, double i1, double s) => ['C', from, to, i0, i1, s];

final List<List<Object>> _h10Ios = [_t(0, .80, .60), _t(80, .90, .80), _t(160, 1.0, 1.0), _t(270, .40, 1.0), _t(330, .32, 1.0), _t(390, .25, 1.0)];
final List<List<Object>> _h08Ios = [_t(0, .60, .50), _t(90, .70, .60), _t(180, .80, .70), _t(300, 1.0, .90), _c(300, 520, .60, 0, .30)];

final Map<String, List<List<Object>>> kHaptikkIos = {
  'h01': [_t(0, .40, .80)],
  'h02.1': [_t(0, .30, .40)],
  'h02.2': [_t(0, .36, .52)],
  'h02.3': [_t(0, .43, .64)],
  'h02.4': [_t(0, .52, .76)],
  'h02.5': [_t(0, .62, .90)],
  'h03': [_c(0, 90, .25, .70, .30), _t(90, .75, .90)],
  'h04': [_c(0, 120, .30, .60, .20), _t(140, .85, .50)],
  'h05': [_t(0, 1.0, .60), _t(60, .60, .90), _t(120, .40, .90), _t(180, .25, .90)],
  'h06': [_t(0, .60, .50), _t(110, .85, .70)],
  'h07': [_t(0, .55, .50), _t(100, .70, .65), _t(200, .90, .80)],
  'h08': _h08Ios,
  // One beat; intensity on the line from 0.30 at 60 m to 0.55 at 0 m, at the middle of each 10 m band.
  for (var b = 0; b <= 5; b++) 'h09.$b': [_t(0, double.parse((.30 + .25 * ((b * 10 + 5) / 60)).toStringAsFixed(3)), .20)],
  'h10': _h10Ios,
  'h11': [_t(0, .50, .90), _t(70, .70, .90)],
  'h12': [..._h10Ios, _c(440, 840, .70, 0, .40)],
  'h13': [_t(0, 1.0, 1.0), _c(150, 530, .80, 0, .10)],
  'h14': [_t(0, .45, .80)],
  'u01': [_t(0, .70, .40)],
  'u02': [_t(0, .40, .50)],
  'u03': [_t(0, .30, .30)],
  'u04': [_t(0, .80, .15)],
  'u05': [_t(0, .90, .15), _t(180, .90, .15)],
  'u06': [_t(0, .35, .70)],
  'u07': [_t(0, .90, .30), _t(60, .30, .90)],
  'u08': [_t(0, .45, .60), _t(100, .65, .80)],
  'u09': [_t(0, .50, .25), _t(90, .50, .25)],
  'u10': [_t(0, .30, .80)],
  'u11': _h08Ios,
};

// ── Android, Rich (composition primitives, spec §5.3) ───────────────────────────────────────────────────────────────
// [primitive, scale, delay ms after the primitive before it]. Steps of 1.4 (0.35, 0.5, 0.7, 1.0).

List<Object> _p(String prim, double scale, [int delay = 0]) => [prim, scale, delay];

/// The seven primitives a phone must support for Rich (spec §7.1).
const List<String> kAndroidPrimitiver = ['CLICK', 'TICK', 'LOW_TICK', 'THUD', 'QUICK_RISE', 'QUICK_FALL', 'SPIN'];

final List<List<Object>> _h10And = [_p('QUICK_RISE', .7), _p('CLICK', 1.0), _p('SPIN', .5, 60), _p('SPIN', .35, 20)];
final List<List<Object>> _h08And = [_p('CLICK', .5), _p('CLICK', .7, 70), _p('CLICK', .7, 70), _p('CLICK', 1.0, 100), _p('QUICK_FALL', .7)];

final Map<String, List<List<Object>>> kHaptikkAndroid = {
  'h01': [_p('TICK', .5)],
  'h02.1': [_p('CLICK', .35)],
  'h02.2': [_p('CLICK', .35)],
  'h02.3': [_p('CLICK', .5)],
  'h02.4': [_p('CLICK', .5)],
  'h02.5': [_p('CLICK', .7)],
  'h03': [_p('QUICK_RISE', .7), _p('TICK', 1.0)],
  'h04': [_p('QUICK_RISE', .5), _p('CLICK', 1.0, 20)],
  'h05': [_p('THUD', 1.0), _p('TICK', 1.0, 50), _p('TICK', .7, 50), _p('TICK', .5, 50)],
  'h06': [_p('CLICK', .7), _p('CLICK', 1.0, 90)],
  'h07': [_p('CLICK', .5), _p('CLICK', .7, 80), _p('CLICK', 1.0, 80)],
  'h08': _h08And,
  // One LOW_TICK per beat: 0.5 above 40 m (bands 0–1), 0.7 from 40 to 20 m (2–3), 1.0 under 20 m (4–5).
  'h09.0': [_p('LOW_TICK', .5)],
  'h09.1': [_p('LOW_TICK', .5)],
  'h09.2': [_p('LOW_TICK', .7)],
  'h09.3': [_p('LOW_TICK', .7)],
  'h09.4': [_p('LOW_TICK', 1.0)],
  'h09.5': [_p('LOW_TICK', 1.0)],
  'h10': _h10And,
  'h11': [_p('TICK', .7), _p('CLICK', .7, 50)],
  'h12': [..._h10And, _p('QUICK_FALL', 1.0, 50)],
  'h13': [_p('THUD', 1.0), _p('QUICK_FALL', .7, 100)],
  'h14': [_p('TICK', .7)],
  'u01': [_p('CLICK', .7)],
  'u02': [_p('TICK', .5)],
  'u03': [_p('LOW_TICK', .5)],
  'u04': [_p('THUD', .7)],
  'u05': [_p('THUD', 1.0), _p('THUD', 1.0, 150)],
  'u06': [_p('TICK', .7)],
  'u07': [_p('THUD', .7), _p('TICK', .7, 50)],
  'u08': [_p('TICK', .7), _p('CLICK', .7, 80)],
  'u09': [_p('LOW_TICK', .7), _p('LOW_TICK', .7, 80)],
  'u10': [_p('TICK', .5)],
  'u11': _h08And,
};

// ── Standard (system effects, spec §5.4) ────────────────────────────────────────────────────────────────────────────

/// The iPhone's Standard call on Flutter's `HapticFeedback`: selection | light | medium | heavy | heavy2 (heavyImpact
/// twice, 120 ms apart). Missing = no haptic on Standard.
const Map<HaptikkId, String> kStandardIos = {
  HaptikkId.h01: 'selection',
  HaptikkId.h03: 'light',
  HaptikkId.h11: 'light',
  HaptikkId.h14: 'light',
  HaptikkId.u06: 'light',
  HaptikkId.u08: 'light',
  HaptikkId.h04: 'medium',
  HaptikkId.u01: 'medium',
  HaptikkId.u04: 'medium',
  HaptikkId.u07: 'medium',
  HaptikkId.h05: 'heavy',
  HaptikkId.h13: 'heavy',
  HaptikkId.h06: 'medium',
  HaptikkId.h07: 'heavy',
  HaptikkId.h08: 'heavy',
  HaptikkId.u11: 'heavy',
  HaptikkId.h10: 'heavy2',
  HaptikkId.h12: 'heavy2',
  HaptikkId.u05: 'heavy2',
  HaptikkId.u02: 'selection',
  HaptikkId.u10: 'selection',
};

/// Android's Standard predefined effect: TICK | CLICK | HEAVY_CLICK | DOUBLE_CLICK. Missing = no haptic on Standard
/// (Android's guidance: between a buzzy haptic and none, none is better — the frequent ones are left out).
const Map<HaptikkId, String> kStandardAndroid = {
  HaptikkId.h03: 'TICK',
  HaptikkId.h11: 'TICK',
  HaptikkId.h14: 'TICK',
  HaptikkId.u06: 'TICK',
  HaptikkId.u08: 'TICK',
  HaptikkId.h04: 'CLICK',
  HaptikkId.u01: 'CLICK',
  HaptikkId.u04: 'CLICK',
  HaptikkId.u07: 'CLICK',
  HaptikkId.h05: 'HEAVY_CLICK',
  HaptikkId.h13: 'HEAVY_CLICK',
  HaptikkId.h06: 'DOUBLE_CLICK',
  HaptikkId.h07: 'DOUBLE_CLICK',
  HaptikkId.h08: 'DOUBLE_CLICK',
  HaptikkId.u11: 'DOUBLE_CLICK',
  HaptikkId.h10: 'DOUBLE_CLICK',
  HaptikkId.h12: 'DOUBLE_CLICK',
  HaptikkId.u05: 'DOUBLE_CLICK',
};

/// How long a pattern plays (ms), for «one at a time» and the 80 ms rest: the iPhone Rich table's last event, the same
/// on every tier (Standard's own effects are shorter; the rules stay the same on both platforms, spec §7.2).
int haptikkVarighet(HaptikkId id, [int step = 0]) {
  final ev = kHaptikkIos[haptikkNokkel(id, id == HaptikkId.h02 ? step.clamp(1, 5) : step.clamp(0, 5))] ?? const [];
  var end = 0;
  for (final e in ev) {
    final t = e[0] == 'T' ? (e[1] as int) + 10 : e[2] as int; // a transient is felt for about 10 ms
    if (t > end) end = t;
  }
  return end.clamp(10, kMaksMs);
}

/// The table as the native side takes it in `prepare()`.
Map<String, Object> haptikkTabell() => {
      'ios': kHaptikkIos,
      'android': kHaptikkAndroid,
      'standardAndroid': {for (final e in kStandardAndroid.entries) e.key.name: e.value},
      'primitives': kAndroidPrimitiver,
    };
