import 'package:flutter/material.dart';

import '../../theme/reen_pre_club_theme.dart';
import '../../theme/sc_saas_theme.dart';

/// Normalize admin/API hex input to `#RRGGBB` or null when invalid/empty.
String? normalizeThemeColor(String? input) {
  if (input == null || input.trim().isEmpty) return null;
  final trimmed = input.trim();
  final match = RegExp(r'^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$').firstMatch(trimmed);
  if (match == null) return null;
  var hex = match.group(1)!;
  if (hex.length == 3) {
    hex = hex.split('').map((c) => c + c).join();
  }
  return '#${hex.toUpperCase()}';
}

Color _hexToColor(String hex) {
  final n = hex.replaceFirst('#', '');
  return Color(int.parse('FF$n', radix: 16));
}

int _channel(Color c, int index) {
  switch (index) {
    case 0:
      return (c.r * 255.0).round();
    case 1:
      return (c.g * 255.0).round();
    default:
      return (c.b * 255.0).round();
  }
}

Color _mixHex(Color a, Color b, double weight) {
  final w = weight / 100;
  return Color.fromARGB(
    255,
    (_channel(a, 0) + (_channel(b, 0) - _channel(a, 0)) * w).round().clamp(0, 255),
    (_channel(a, 1) + (_channel(b, 1) - _channel(a, 1)) * w).round().clamp(0, 255),
    (_channel(a, 2) + (_channel(b, 2) - _channel(a, 2)) * w).round().clamp(0, 255),
  );
}

/// Lighten [c] in HSL. Keeps the admin hue; RGB-mix with white also
/// desaturates and is what made club ramps look chalky.
Color _hslTint(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness((hsl.lightness + amount).clamp(0.16, 0.92))
      .toColor();
}

/// Darken [c] in HSL. Floor is high on purpose: Design `.me-bg` is a *shallow*
/// 600→500 ramp, not a fade to burgundy. Mixing toward black (or shading past
/// ~0.48 L) is what made the feed cards look crushed in the corner.
Color _hslShade(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness((hsl.lightness - amount).clamp(0.48, 0.86))
      .toColor();
}

Color _deriveLavenderFromAccent(Color accent) =>
    _mixHex(accent, Colors.white, 93);

/// Full derived palette for Dugnad mode — mirrors Reen-web-portal `buildClubThemeStyle`.
class AeThemePalette {
  final Color primary;
  final Color primaryHover;
  final Color primarySoft;
  final Color primaryDisabled;
  final Color primaryTint;
  final Color background;
  final Color text;
  final Color ink;
  final LinearGradient heroGradient;
  final LinearGradient shinyGradient;
  final LinearGradient bannerGradient;
  final List<BoxShadow> shadowButton;

  const AeThemePalette({
    required this.primary,
    required this.primaryHover,
    required this.primarySoft,
    required this.primaryDisabled,
    required this.primaryTint,
    required this.background,
    required this.text,
    required this.ink,
    required this.heroGradient,
    required this.shinyGradient,
    required this.bannerGradient,
    required this.shadowButton,
  });

  /// Pre-club Reen coral-navy (Design `.reen-pre`).
  ///
  /// Only for splash / login / mode select / club onboarding — never as the
  /// fallback after a club is selected. Post-club UI uses [resolve] → [defaults].
  static final AeThemePalette reenPreClub =
      AeThemePalette._fromTokens(
    primary: ReenPreClubTokens.coral,
    primaryHover: const Color(0xFFC94F41),
    primarySoft: ReenPreClubTokens.coralMid,
    primaryDisabled: ReenPreClubTokens.coralSoft,
    primaryTint: const Color(0x14FFFFFF),
    background: ReenPreClubTokens.navy,
    text: ReenPreClubTokens.ink,
    ink: ReenPreClubTokens.ink,
    shinyLight: ReenPreClubTokens.coralMid,
    shinyDark: ReenPreClubTokens.coralDeep,
  );

  /// Browse-without-club palette: light feed canvas + coral actions + navy hero.
  static final AeThemePalette reenBrowse =
      AeThemePalette._fromTokens(
    primary: ReenPreClubTokens.coral,
    primaryHover: ReenPreClubTokens.coralDeep,
    primarySoft: ReenPreClubTokens.coralMid,
    primaryDisabled: ReenPreClubTokens.coralSoft,
    primaryTint: const Color(0x1FE86657),
    background: ScSaasThemeTokens.background,
    text: ScSaasThemeTokens.text,
    ink: ScSaasThemeTokens.ink,
    shinyLight: ReenPreClubTokens.coralMid,
    shinyDark: ReenPreClubTokens.coralDeep,
  );

  /// Fallback when a selected club has no admin theme colors — Ærend lavender.
  static final AeThemePalette defaults =
      AeThemePalette._fromTokens(
    primary: ScSaasThemeTokens.primary,
    primaryHover: ScSaasThemeTokens.primaryHover,
    primarySoft: ScSaasThemeTokens.primarySoft,
    primaryDisabled: ScSaasThemeTokens.primaryDisabled,
    primaryTint: ScSaasThemeTokens.primaryTint,
    background: ScSaasThemeTokens.background,
    text: ScSaasThemeTokens.text,
    ink: ScSaasThemeTokens.ink,
    // Authored `--ae-shiny-purple` (not the 12/22 mix used for club accents).
    shinyLight: const Color(0xFFA98FE0),
    shinyDark: ScSaasThemeTokens.primaryHover,
  );

  factory AeThemePalette.resolve({
    String? accentColor,
    String? backgroundColor,
  }) {
    final accent = normalizeThemeColor(accentColor);
    final background = normalizeThemeColor(backgroundColor);

    // No admin colors → Ærend defaults (never Reen pre-club).
    if (accent == null && background == null) return defaults;

    final primaryHex = accent ?? background!;
    final lavenderHex = background ?? _colorToHex(_deriveLavenderFromAccent(_hexToColor(primaryHex)));

    final primary = _hexToColor(primaryHex);
    final lavender = _hexToColor(lavenderHex);
    final purple700 = _mixHex(primary, Colors.black, 18);
    final purple500 = _mixHex(primary, Colors.white, 28);
    final purple400 = _mixHex(primary, Colors.white, 52);
    final purple100 = _mixHex(primary, Colors.white, 88);
    final midnight = _mixHex(primary, Colors.black, 55);
    final ink = _mixHex(midnight, const Color(0xFF0F1620), 35);
    // Shiny CTA stops match Reen-web-portal `buildClubThemeStyle`:
    // `mixHex(primary, #fff, 12)` / `mixHex(primary, #000, 22)`.
    // Do **not** reuse [_hslShade] here — that helper floors at 0.48 L so
    // feed cards stay a shallow wash. On a navy club accent (Sædalen
    // `#1E4377`, L≈0.29) the floor *lightens* the far stop and the primary
    // button reads inverted vs Design `--ae-shiny-purple`
    // (`#3D6196 → #1E4377 → #143053`).
    final shinyLight = _mixHex(primary, Colors.white, 12);
    final shinyDark = _mixHex(primary, Colors.black, 22);

    return AeThemePalette._fromTokens(
      primary: primary,
      primaryHover: purple700,
      primarySoft: purple500,
      primaryDisabled: purple400,
      primaryTint: purple100,
      background: lavender,
      text: midnight,
      ink: ink,
      shinyLight: shinyLight,
      shinyDark: shinyDark,
    );
  }

  static AeThemePalette _fromTokens({
    required Color primary,
    required Color primaryHover,
    required Color primarySoft,
    required Color primaryDisabled,
    required Color primaryTint,
    required Color background,
    required Color text,
    required Color ink,
    Color? shinyLight,
    Color? shinyDark,
  }) {
    final light = shinyLight ?? _mixHex(primary, Colors.white, 12);
    final dark = shinyDark ?? _mixHex(primary, Colors.black, 22);

    return AeThemePalette(
      primary: primary,
      primaryHover: primaryHover,
      primarySoft: primarySoft,
      primaryDisabled: primaryDisabled,
      primaryTint: primaryTint,
      background: background,
      text: text,
      ink: ink,
      heroGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, primaryHover],
      ),
      shinyGradient: LinearGradient(
        begin: const Alignment(-0.5, -0.85),
        end: const Alignment(0.5, 0.85),
        colors: [light, primary, dark],
        stops: const [0.0, 0.55, 1.0],
      ),
      bannerGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, primaryHover],
      ),
      shadowButton: [
        BoxShadow(
          color: text.withValues(alpha: 0.1),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: primary.withValues(alpha: 0.5),
          blurRadius: 18,
          offset: const Offset(0, 6),
          spreadRadius: -8,
        ),
      ],
    );
  }

  /// `.dg-missions-entry .me-bg`: `135deg, --ae-purple-600, --ae-purple-500`.
  /// 500 is a *lighter* tint of 600 — a shallow even wash, not a dark corner.
  LinearGradient get feedMissionsGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, _hslTint(primary, 0.08)],
      );

  /// `.dg-transfer-banner .tb-bg` is a darker cousin of the missions wash.
  /// Same hue, ~6% less lightness — enough to separate the cards, not enough
  /// to read as maroon. Already-dark admin colours tint the far stop instead.
  LinearGradient get feedTransferGradient {
    final hsl = HSLColor.fromColor(primary);
    if (hsl.lightness <= 0.50) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, _hslTint(primary, 0.08)],
      );
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_hslShade(primary, 0.06), primary],
    );
  }

  static String _colorToHex(Color c) {
    final r = (c.r * 255.0).round() & 0xff;
    final g = (c.g * 255.0).round() & 0xff;
    final b = (c.b * 255.0).round() & 0xff;
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }
}

/// Provides club theme palette to the Dugnad tab shell and its descendants.
class AeThemeScope extends InheritedWidget {
  final AeThemePalette palette;

  const AeThemeScope({
    super.key,
    required this.palette,
    required super.child,
  });

  static AeThemePalette of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AeThemeScope>();
    return scope?.palette ?? AeThemePalette.defaults;
  }

  @override
  bool updateShouldNotify(AeThemeScope oldWidget) =>
      oldWidget.palette != palette;
}

extension AeThemeContext on BuildContext {
  AeThemePalette get aeTheme {
    final scope = dependOnInheritedWidgetOfExactType<AeThemeScope>();
    if (scope != null) return scope.palette;
    return AeThemePalette.defaults;
  }
}
