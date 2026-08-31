import 'package:flutter/material.dart';

/// Reen coral-navy tokens for pre-club surfaces (splash, login, mode select,
/// club onboarding) — mirrors `.reen-pre` in Design/Custom Dugnad.html.
///
/// After a club is selected, [AeThemePalette.resolve] takes over.
abstract final class ReenPreClubTokens {
  // Coral
  static const Color coral = Color(0xFFE86657);
  static const Color coralLight = Color(0xFFF6A796);
  static const Color coralMid = Color(0xFFF08D80);
  static const Color coralSoft = Color(0xFFF5B8AF);
  static const Color coralDeep = Color(0xFFC94F41);
  static const Color coralHover = Color(0xFFF0866F);
  static const Color coralThumbEnd = Color(0xFFD9503F);

  // Navy
  static const Color navy = Color(0xFF16304F);
  static const Color navyTop = Color(0xFF1B3A5C);
  static const Color navyMid = Color(0xFF16304F);
  static const Color navyBottom = Color(0xFF12283F);
  static const Color splashPanelTop = Color(0xFF213D61);
  static const Color splashPanelBottom = Color(0xFF14273F);

  static const Color ink = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xB3FFFFFF); // ~.70
  static const Color textSubtitle = Color(0xB8FFFFFF); // ~.72
  static const Color textSoft = Color(0x9EFFFFFF); // ~.62
  static const Color glassFill = Color(0x14FFFFFF); // ~.075
  static const Color glassBorder = Color(0x29FFFFFF); // ~.16

  static const LinearGradient screenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [navyTop, navyMid, navyBottom],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient splashPanelGradient = LinearGradient(
    begin: Alignment(-0.26, -1),
    end: Alignment(0.26, 1),
    colors: [splashPanelTop, splashPanelBottom],
  );

  static const LinearGradient shinyCoral = LinearGradient(
    begin: Alignment(-0.5, -0.85),
    end: Alignment(0.5, 0.85),
    colors: [coralMid, coral, coralDeep],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient regDemoThumb = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF5907A), coral, coralThumbEnd],
    stops: [0.0, 0.55, 1.0],
  );

  // Assets — same files as Design/Custom Dugnad.html
  // splash: website/assets/reen-logo-white.svg
  // login:  website/assets/reen-mark-coral.svg
  // credit: Design inline Æ mark ≡ assets/Logo/aerend_mark.svg
  static const String logoWhite = 'assets/Logo/reen-logo-white.svg';
  /// Raster fallback — flutter_svg often ignores `style="fill:…"` on SVG paths.
  static const String logoWhitePng = 'assets/Logo/reen-logo-white.png';
  static const String markCoral = 'assets/Logo/reen-mark-coral.svg';
  static const String markCoralPng = 'assets/Logo/reen-mark-coral.png';
  static const String markCoralNavy = 'assets/Logo/reen/mark-coral-navy.svg';
  static const String markCoralNavyPng = 'assets/Logo/reen/mark-coral-navy.png';
  static const String aerendMark = 'assets/Logo/aerend_mark.svg';

  /// Design `Splash.jsx` / `Login.jsx` inline Æ credit mark (gradient + white strokes).
  static const String aerendByMarkSvg = '''
<svg viewBox="0 0 176 176" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="ae-by-sq" x1="30" y1="6" x2="150" y2="176" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#b69ee8"/>
      <stop offset="0.55" stop-color="#7f5fc4"/>
      <stop offset="1" stop-color="#6b4fa8"/>
    </linearGradient>
  </defs>
  <path d="M136.469 0H39.5312C17.6987 0 0 17.6987 0 39.5312V136.469C0 158.301 17.6987 176 39.5312 176H136.469C158.301 176 176 158.301 176 136.469V39.5312C176 17.6987 158.301 0 136.469 0Z" fill="url(#ae-by-sq)"/>
  <path d="M37.6748 130.625L72.8404 45.2375" stroke="#fff" stroke-width="12.5709" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M72.8403 45.2375L108.006 130.625" stroke="#fff" stroke-width="12.5709" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M55.2402 91.7812H138.325" stroke="#fff" stroke-width="12.5709" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M108.006 45.2375H138.325" stroke="#fff" stroke-width="12.5709" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M108.006 130.625H138.325" stroke="#fff" stroke-width="12.5709" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';
}
