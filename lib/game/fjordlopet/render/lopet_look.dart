import 'dart:ui';

import 'package:flutter/foundation.dart' show kReleaseMode;

import '../../../screens/bergen/hjem/hjem_harness.dart';
import '../../../screens/common/home/bergen/bergen_kit.dart' show BergenWeatherLook;
import '../../../screens/bergen/hjem/hjem_hero.dart' show HjemVaer;

/// The three sea modes (spec §12.6), the same as Home's water at that moment.
enum LopetMode { dag, kveld, regn }

/// Fjordløpet v1.3 plan Step 9 (spec §12.6): the colours of one sea mode, for the water shader, the Low water and the
/// atlas (lights on, the rim, the quay stone). Object colours do not change with the mode (readability first).
class LopetLook {
  const LopetLook._({
    required this.mode,
    required this.deep,
    required this.shal,
    required this.skyHi,
    required this.skyLo,
    required this.mist,
    required this.mistA,
    required this.sun,
    required this.glitter,
    required this.lightsOn,
    required this.lights,
    required this.rim,
    required this.stone,
    required this.stoneDark,
  });

  final LopetMode mode;
  final Color deep, shal, skyHi, skyLo, mist, sun, lights, rim, stone, stoneDark;
  final double mistA;

  /// Sun glitter: strong in Dag, soft in Kveld, none in Regn.
  final double glitter;
  final bool lightsOn;

  bool get regn => mode == LopetMode.regn;

  static const dag = LopetLook._(
    mode: LopetMode.dag,
    deep: Color(0xFF245866),
    shal: Color(0xFF6FAFBD),
    skyHi: Color(0xFF7FB6CE),
    skyLo: Color(0xFFE6F0F2),
    mist: Color(0xFFD3E3E7),
    mistA: .14,
    sun: Color(0xFFFFF6DC),
    glitter: 1,
    lightsOn: false,
    lights: Color(0xFFFFF6DC),
    rim: Color(0xE6F5F3EF),
    stone: Color(0xFF8E9590),
    stoneDark: Color(0xFF5C6460),
  );

  static const kveld = LopetLook._(
    mode: LopetMode.kveld,
    deep: Color(0xFF19434F),
    shal: Color(0xFF4C8796),
    skyHi: Color(0xFF6A8A96),
    skyLo: Color(0xFFC2D2D6),
    mist: Color(0xFFA9BCC2),
    mistA: .18,
    sun: Color(0xFFFFE2B6),
    glitter: .35,
    lightsOn: true,
    lights: Color(0xFFFFD488),
    rim: Color(0xE6F5F3EF),
    stone: Color(0xFF6B6F68),
    stoneDark: Color(0xFF3E423D),
  );

  static const regnLook = LopetLook._(
    mode: LopetMode.regn,
    deep: Color(0xFF192E36),
    shal: Color(0xFF45616B),
    skyHi: Color(0xFF6C7F87),
    skyLo: Color(0xFFAEBABD),
    mist: Color(0xFF98A7AB),
    mistA: .28,
    sun: Color(0xFFE8EEF0),
    glitter: 0,
    lightsOn: true,
    lights: Color(0xFFF2C878),
    // Regn: «a light rim on every obstacle».
    rim: Color(0xFFFFFFFF),
    stone: Color(0xFF5E6666),
    stoneDark: Color(0xFF363D3E),
  );

  static LopetLook of(LopetMode m) => switch (m) {
        LopetMode.dag => dag,
        LopetMode.kveld => kveld,
        LopetMode.regn => regnLook,
      };

  /// Home's sea mode now: the harness override in debug builds, else the time of day (rain is Home's `regn` look).
  static LopetMode now({DateTime? at}) {
    final forced = kReleaseMode ? null : HjemHarness.vaer;
    if (forced != null) return fromHjem(forced);
    return fromHour((at ?? DateTime.now()).hour);
  }

  static LopetMode fromHjem(HjemVaer v) => switch (v) {
        HjemVaer.sol => LopetMode.dag,
        HjemVaer.regn => LopetMode.regn,
        HjemVaer.solnedgang || HjemVaer.natt => LopetMode.kveld,
      };

  /// Home's own choice for the hour (`BergenWeatherLook.forHour`): sun → Dag, sunset and night → Kveld, Bergen's rainy
  /// default → Regn.
  static LopetMode fromHour(int hour) {
    final look = BergenWeatherLook.forHour(hour);
    if (identical(look, BergenWeatherLook.sol)) return LopetMode.dag;
    if (identical(look, BergenWeatherLook.solnedgang) || identical(look, BergenWeatherLook.natt)) return LopetMode.kveld;
    return LopetMode.regn;
  }
}
