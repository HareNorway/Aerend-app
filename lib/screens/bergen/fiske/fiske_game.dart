import 'dart:ui';

import '../../../data/aegil/suggestion_models.dart';

/// The rules of Fjordfiske that do not touch a widget (design JS
/// `fiskeDekk`, `fiskePremieVelg`, `FKAT`, `FISKE[].tint`), so the tests
/// cover cadence and filtering without pumping frames.

/// The five phases of a cast (`st.fiskeFase`): `klar` → `venter` → `napp` →
/// `fangst` (or `mistet` → `klar`).
enum FiskePhase { klar, venter, napp, fangst, mistet }

/// The bait row (`FKAT`): the key, and how a suggestion's `category` lands
/// in a bucket. `alle` counts everything; a category nobody recognises is
/// only in `alle`.
enum FiskeAgn {
  alle,
  fisk,
  mat,
  mote,
  interior,
  gaver;

  static FiskeAgn? of(Suggestion s) {
    final c = (s.category ?? '').toLowerCase();
    if (c.isEmpty) return null;
    if (c.contains('bak')) return mat;
    if (c.contains('mote') ||
        c.contains('klær') ||
        c.contains('fashion') ||
        c.contains('sko')) {
      return mote;
    }
    if (c.contains('interi') || c.contains('møbel')) return interior;
    if (c.contains('gave') || c.contains('blomst') || c.contains('gift')) {
      return gaver;
    }
    if (c.contains('fisk') ||
        c.contains('mat') ||
        c.contains('restaurant') ||
        c.contains('sjø') ||
        c.contains('daglig') ||
        c.contains('food') ||
        c.contains('grocer') ||
        c.contains('kafe') ||
        c.contains('cafe') ||
        c.contains('burger') ||
        c.contains('pizza')) {
      return fisk;
    }
    return null;
  }
}

/// The catch card's hero art per bucket (design `FISKE[].ik`): which
/// `assets/svgs/dashboard/*.svg`, its box and offset inside the 250×150
/// hero, and the tint behind it.
class FiskeArt {
  const FiskeArt(
    this.asset,
    this.width,
    this.height,
    this.left,
    this.top,
    this.tint,
  );

  final String asset;
  final double width;
  final double height;
  final double left;
  final double top;

  /// `linear-gradient(165deg, a, b)`.
  final List<Color> tint;

  /// Design `FISKE[].ik` → the art. `pose` (Forundringspose) and `burger`
  /// exist in the design deck; suggestions carry a category, so the
  /// bucket decides.
  static FiskeArt of(FiskeAgn? agn) => switch (agn) {
    FiskeAgn.mat => const FiskeArt('ico_mat', 110, 100, 69, 36, [
      Color(0xFFFBE9C4),
      Color(0xFFE9B76A),
    ]),
    FiskeAgn.mote => const FiskeArt('ico_mote', 110, 112, 69, 30, [
      Color(0xFFEEE6F0),
      Color(0xFFB9A2CC),
    ]),
    FiskeAgn.interior => const FiskeArt('ico_interior', 100, 110, 74, 30, [
      Color(0xFFE4EAEC),
      Color(0xFF9DB0B8),
    ]),
    FiskeAgn.gaver => const FiskeArt('ico_gaver', 106, 112, 71, 30, [
      Color(0xFFFBE9C4),
      Color(0xFFD9A254),
    ]),
    _ => const FiskeArt('ico_fisk', 150, 100, 49, 36, [
      Color(0xFFCFE3E8),
      Color(0xFF6FA3B2),
    ]),
  };
}

/// Design `fiskePremieVelg` §1: "eligibility evaluated at cast time. Rules,
/// not chance." Tweaks `fiskePremieHverN` (8), `fiskePremieMaks` (3),
/// `fiskePremieFraKast` (3), `fiskePremieAv`.
class FiskePrizeRules {
  const FiskePrizeRules({
    this.everyN = 8,
    this.max = 3,
    this.fromCast = 3,
    this.off = false,
  });

  final int everyN;
  final int max;
  final int fromCast;
  final bool off;

  FiskePrizeRules copyWith({int? everyN, int? fromCast}) => FiskePrizeRules(
    everyN: everyN ?? this.everyN,
    max: max,
    fromCast: fromCast ?? this.fromCast,
    off: off,
  );

  /// True when cast [kastNr] may be a Premiefangst: from [fromCast] on, at
  /// most [max] a session, and at least [everyN] casts after the last one.
  bool eligible(int kastNr, {required int taken, required int lastAt}) {
    if (off) return false;
    if (kastNr < fromCast || taken >= max) return false;
    if (lastAt > 0 && kastNr - lastAt < everyN) return false;
    return true;
  }
}

/// The deck (`fiskeDekk`): the suggestions from `agent/suggestions?context=fiske`,
/// filtered by the chosen bait, with the counts the bait row shows.
class FiskeDeck {
  const FiskeDeck(this.all, {this.agn = FiskeAgn.alle});

  final List<Suggestion> all;
  final FiskeAgn agn;

  List<Suggestion> get cards => agn == FiskeAgn.alle
      ? all
      : all.where((s) => FiskeAgn.of(s) == agn).toList();

  int count(FiskeAgn a) =>
      a == FiskeAgn.alle ? all.length : all.where((s) => FiskeAgn.of(s) == a).length;

  FiskeDeck withAgn(FiskeAgn a) => FiskeDeck(all, agn: a);
}

/// `String(n).replace(/\B(?=(\d{3})+(?!\d))/g, ' ')` — 1 360 → "1 360".
String fiskeNfp(int n) {
  final s = n.toString();
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final left = s.length - i;
    if (i > 0 && left % 3 == 0) out.write(' ');
    out.write(s[i]);
  }
  return out.toString();
}
