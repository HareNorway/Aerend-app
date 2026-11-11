import 'package:flutter/foundation.dart';

/// Kunde Glatt plan (KundeGlatt/AEREND-KUNDE-HJUL-HAPTIKK-PLAN.md §0.5): the
/// test switches for the plan's behaviour changes, set from the debug /
/// profile harness file (`kunde_state.json` / `hjem_state.json`, see
/// `HjemHarness.load`):
///
/// * `kglatt: false` turns every change below off together;
/// * `kglattHjul: false` — the Hjem wheel turns as before (against the
///   finger) and gives no detent ticks;
/// * `kglattVib: false` — no new vibrations (the plan's added ticks and the
///   routing of the old raw calls through the service); the app vibrates as
///   it did before the plan.
///
/// Release builds always have every change on.
abstract final class KGlatt {
  static bool _hjul = true, _vib = true;

  /// Step 1: the wheel turns with the finger, with detent ticks.
  static bool get hjul => kReleaseMode || _hjul;

  /// Steps 2–4: the vibrations of the plan.
  static bool get vib => kReleaseMode || _vib;

  /// Reads the switches from a harness map (absent keys = on).
  static void sett(Map<String, dynamic> m) {
    final alle = m['kglatt'] != false;
    _hjul = alle && m['kglattHjul'] != false;
    _vib = alle && m['kglattVib'] != false;
  }

  /// No harness file: everything on, as shipped.
  static void nullstill() {
    _hjul = true;
    _vib = true;
  }
}
