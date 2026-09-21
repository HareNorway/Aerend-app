import 'package:flutter/material.dart';

/// Ærend Kunde Bergen tokens for pre-auth surfaces (splash, login, OTP,
/// consent, Vipps return, logout curtain) — mirrors the teal-navy / orange
/// identity in `designs/20des/Ærend Kunde Bergen.dc.html`.
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

  // Assets — see `designs/20des/Ærend Kunde Bergen.dc.html` `<symbol id="merke-flat">`.
  static const String mark = 'assets/Logo/aerend_mark_bergen.svg';
}
