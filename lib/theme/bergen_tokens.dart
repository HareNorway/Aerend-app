import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ærend Kunde Bergen tokens for pre-auth surfaces (splash, login, OTP,
/// consent, Vipps return, logout curtain) — mirrors the teal-navy / orange
/// identity in `designs/21des/Ærend Kunde Bergen.dc.html`.
///
/// After login, the app's own theme (`ScSaasThemeTokens` / `AeThemePalette`)
/// takes over.
abstract final class AerendBergenAuthTokens {
  // Teal-navy background ramp — the shared gradient for every pre-auth screen.
  static const Color navyTop = Color(0xFF245A69);
  static const Color navyMid = Color(0xFF173E48);
  static const Color navyBottom = Color(0xFF0F1F2B);
  /// Flat fallback for spots that want a single solid color, not a gradient.
  static const Color navy = navyMid;

  // Orange — primary CTA / link / accent color (Design `#F26D3D` ramp).
  static const Color orange = Color(0xFFF26D3D);
  static const Color orangeLight = Color(0xFFF9A273);
  static const Color orangeMid = Color(0xFFF58A55);
  static const Color orangeSoft = Color(0xFFF5B79B);
  static const Color orangeHover = Color(0xFFDD5A25);
  static const Color orangeDeep = Color(0xFFC4491A);

  // Mint — secondary accent (success ticks / referral checkmarks).
  static const Color mint = Color(0xFF5CE0B8);
  static const Color mintDeep = Color(0xFF2FB893);

  // Mark colors — the sticker's teal strokes + orange accent bar.
  static const Color markTeal = Color(0xFF3A7D8C);
  static const Color markOrange = orange;

  // Cream text on dark.
  static const Color ink = Color(0xFFF5F3EF);
  static const Color textSubtitle = Color(0xFFDCE9EC);
  static const Color textSoft = Color(0xFFBFD6DD);
  static const Color textMuted = Color(0xFF9FB6C2);
  static const Color glassFill = Color(0x14FFFFFF); // ~.075
  static const Color glassBorder = Color(0x29FFFFFF); // ~.16

  static const LinearGradient screenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [navyTop, navyMid, navyBottom],
    stops: [0.0, 0.45, 1.0],
  );

  /// Same gradient, used by `logout_curtain.dart` as a full-bleed panel.
  static const LinearGradient splashPanelGradient = LinearGradient(
    begin: Alignment(-0.26, -1),
    end: Alignment(0.26, 1),
    colors: [navyTop, navyBottom],
  );

  static const LinearGradient shinyOrange = LinearGradient(
    begin: Alignment(-0.5, -0.85),
    end: Alignment(0.5, 0.85),
    colors: [orangeLight, orange, orangeDeep],
    stops: [0.0, 0.55, 1.0],
  );

  // Assets — see `designs/21des/Ærend Kunde Bergen.dc.html` `<symbol id="merke-flat">`.
  static const String mark = 'assets/Logo/aerend_mark_bergen.svg';
}

/// Ærend Kunde Bergen — the whole-app design tokens (AGIL-CONTRACT §2.2,
/// Sync C). Values are the inline hex of `designs/21des/Ærend Kunde
/// Bergen.dc.html`; the design declares no CSS variables, so this file is the
/// single place the palette, sea modes, type scale, radii and motion live.
///
/// [AerendBergenAuthTokens] above keeps the pre-auth surfaces working
/// unchanged; new screens (`lib/screens/bergen/**`) read [BergenTokens].
abstract final class BergenTokens {
  // ── Ink and text on paper ──────────────────────────────────────────────
  static const Color ink = Color(0xFF23201D);
  static const Color inkSecondary = Color(0xFF57534B);
  static const Color inkMuted = Color(0xFF6E6862);
  static const Color inkFaint = Color(0xFF8C847C);

  // ── Paper ──────────────────────────────────────────────────────────────
  static const Color paper = Color(0xFFF5F3EF);
  static const Color paperWarm = Color(0xFFE9E2D2);
  static const Color paperBright = Color(0xFFFBFAF6);
  static const Color body = Color(0xFFE2DFD8);

  // ── Fjord teal ─────────────────────────────────────────────────────────
  static const Color teal = Color(0xFF1E4F5C);
  static const Color tealLight = Color(0xFF2A6272);
  static const Color tealDeep = Color(0xFF173E48);
  static const Color tealNight = Color(0xFF0F1F2B);

  // ── Accents ────────────────────────────────────────────────────────────
  static const Color mint = Color(0xFF5CE0B8);
  static const Color mintDeep = Color(0xFF2FB893);
  static const Color orange = Color(0xFFF26D3D);
  static const Color orangeLight = Color(0xFFF9A273);
  static const Color orangeMid = Color(0xFFF58A55);
  static const Color orangeHot = Color(0xFFE95C2C);
  static const Color orangeHover = Color(0xFFDD5A25);
  static const Color orangeDeep = Color(0xFFC4491A);
  static const Color lantern = Color(0xFFF2C14E);

  // ── Status ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7E4F);
  static const Color danger = Color(0xFFB8432B);
  static const Color glassFill = Color(0x14FFFFFF);
  static const Color glassBorder = Color(0x2EFFFFFF);

  // ── Sea modes (the hero water; `st.vaer` in the design) ────────────────
  static const Color seaDay = Color(0xFF9FC3CC);
  static const Color seaEvening = Color(0xFF3D6B7A);
  static const Color seaRain = Color(0xFF6F8790);

  static Color seaFor(BergenSea mode) => switch (mode) {
    BergenSea.day => seaDay,
    BergenSea.evening => seaEvening,
    BergenSea.rain => seaRain,
  };

  // ── Gradients ──────────────────────────────────────────────────────────
  /// `linear-gradient(180deg,#2A6272 0%,#1E4F5C 42%,#173E48 100%)`.
  static const LinearGradient screen = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [tealLight, teal, tealDeep],
    stops: [0, .42, 1],
  );

  /// `linear-gradient(180deg,#F58A55,#E95C2C)` — the 3D CTA face.
  static const LinearGradient cta = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [orangeMid, orangeHot],
  );

  /// `linear-gradient(180deg,#FDFBF6 0%,#F6F1E7 100%)` — cards on paper.
  static const LinearGradient card = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFDFBF6), Color(0xFFF6F1E7)],
  );

  // ── Type scale (design px on the 390 frame) ────────────────────────────
  // Plus Jakarta Sans (display) / Inter (body), the same GoogleFonts pair
  // `onboarding_kit.dart` uses, so pre-auth and Bergen screens match.

  static const double textHero = 28;
  static const double textTitle = 22;
  static const double textSection = 17;
  static const double textBody = 15;
  static const double textSmall = 13;
  static const double textMicro = 11;

  static TextStyle display(
    double px, {
    FontWeight weight = FontWeight.w800,
    Color color = ink,
    double letterSpacingEm = -0.02,
    double? height,
  }) => GoogleFonts.plusJakartaSans(
    fontSize: px,
    fontWeight: weight,
    color: color,
    letterSpacing: px * letterSpacingEm,
    height: height,
  );

  static TextStyle text(
    double px, {
    FontWeight weight = FontWeight.w600,
    Color color = ink,
    double? height,
  }) => GoogleFonts.inter(
    fontSize: px,
    fontWeight: weight,
    color: color,
    height: height,
  );

  // ── Radii ──────────────────────────────────────────────────────────────
  static const double radiusChip = 999;
  static const double radiusButton = 16;
  static const double radiusCard = 20;
  static const double radiusSheet = 28;

  // ── Motion ─────────────────────────────────────────────────────────────
  static const Duration motionFast = Duration(milliseconds: 160);
  static const Duration motionBase = Duration(milliseconds: 260);
  static const Duration motionSheet = Duration(milliseconds: 420);
  static const Duration motionToast = Duration(seconds: 3);
  static const Duration motionUndo = Duration(seconds: 5);
  static const Curve motionCurve = Curves.easeOutCubic;

  /// Honour the design reduced-motion kill switch.
  static Duration motion(BuildContext context, Duration d) =>
      MediaQuery.maybeDisableAnimationsOf(context) == true ? Duration.zero : d;
}

/// The three looks of the harbour water in the Hjem hero.
enum BergenSea { day, evening, rain }
