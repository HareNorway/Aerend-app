import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where a mode switch came from: the Hjem moon/sun button plays the Hjem
/// show, everything else the circle reveal (design `modusSett`).
enum ModusKilde { hjem, konto, harness }

/// Plays the switch moment. Registered by the app-wide [ModusAvduk] (circle
/// reveal) and, while Hjem is on screen, by Hjem's show. [spill] must call
/// [bruk] exactly once (the moment the new mode is applied) and may return
/// before the moment has finished.
abstract interface class ModusVert {
  /// Return false when this host can't play now (the next one is asked).
  bool spill({required bool lys, required Offset? fra, required ModusKilde kilde, required VoidCallback bruk});
}

/// Lys plan: the one light/dark switch for the whole customer app (design
/// `modus` = 'mork' | 'lys', `localStorage['aerend.modus.v1']`). Saved on the
/// phone only (L4), default Mørk, read in `main()` before `runApp` so the
/// first frame already has it (L10). Widgets read it through
/// `BergenModusScope` (`context.lys`), never through `Theme.brightness`.
class BergenModus extends ChangeNotifier {
  BergenModus._();

  static final BergenModus i = BergenModus._();

  /// The SharedPreferences key (same name as the design's localStorage key).
  static const String nokkel = 'aerend.modus.v1';

  bool _lys = false;
  bool? _mal;

  /// The applied mode.
  bool get lys => _lys;

  /// The mode being switched to while a moment plays (design `modusMal`),
  /// else [lys]. Konto's Utseende cards show this one, so the tick moves at
  /// the tap.
  bool get modusMal => _mal ?? _lys;

  final List<ModusVert> _verter = [];

  /// Shows «Lys modus · Skydans» / «Mørk modus · Fjord» (set by the app root).
  void Function(bool lys)? visToast;

  /// Hosts are asked last-registered first (Hjem's show over the app-wide reveal).
  void registrer(ModusVert v) => _verter.add(v);
  void avregistrer(ModusVert v) => _verter.remove(v);

  /// Read the saved mode (before `runApp`). Missing or unreadable = Mørk.
  Future<void> last() async {
    try {
      final p = await SharedPreferences.getInstance();
      _lys = p.getString(nokkel) == 'lys';
    } catch (_) {
      _lys = false;
    }
  }

  /// Switch to [lys]. Saves it, then lets the top host play the moment
  /// (which applies the mode at its own time); without a host — or with
  /// [stille] — the mode is applied at once. [ferdig] runs once the mode is
  /// applied (the toast is the host's job).
  void sett(bool lys, {Offset? fra, ModusKilde kilde = ModusKilde.konto, bool stille = false}) {
    if (lys == modusMal) return;
    _mal = lys;
    _lagre(lys);
    var brukt = false;
    void bruk() {
      if (brukt) return;
      brukt = true;
      _mal = null;
      if (_lys != lys) {
        _lys = lys;
      }
      notifyListeners();
    }

    if (!stille) {
      for (final v in _verter.reversed.toList()) {
        if (v.spill(lys: lys, fra: fra, kilde: kilde, bruk: bruk)) {
          // The target shows at once (Utseende's tick) while the old mode is still applied.
          if (!brukt) notifyListeners();
          return;
        }
      }
    }
    bruk();
  }

  /// Flip (the Hjem button).
  void bytt({Offset? fra, ModusKilde kilde = ModusKilde.hjem}) => sett(!modusMal, fra: fra, kilde: kilde);

  Future<void> _lagre(bool lys) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(nokkel, lys ? 'lys' : 'mork');
    } catch (_) {}
  }

  /// Tests: back to the default without touching storage.
  @visibleForTesting
  void tilbakestill({bool lys = false}) {
    _lys = lys;
    _mal = null;
    _verter.clear();
    notifyListeners();
  }
}
