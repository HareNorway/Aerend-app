import 'package:flutter/material.dart';

import '../theme/sc_saas_theme.dart';

/// Ærend shared BoxDecoration helpers.
///
/// Uses Chunk 1 shadow constants from [ScSaasThemeTokens].
/// The "shiny surface" is an approximation — Flutter lacks CSS inset shadows,
/// so we simulate with a layered gradient (white→lavender→light-purple) plus
/// a brand-tinted outer drop shadow. The visual effect is close but not
/// pixel-identical to the CSS version.
class AeSurface {
  AeSurface._();

  /// Soft card elevation — brand-tinted, not black.
  static BoxDecoration card({
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: borderRadius ?? BorderRadius.circular(18), // --ae-r-lg
      boxShadow: ScSaasThemeTokens.shadowCard,
    );
  }

  /// Primary-button purple glow.
  static BoxDecoration buttonGlow({
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      borderRadius: borderRadius ?? BorderRadius.circular(14), // --ae-r-md
      boxShadow: ScSaasThemeTokens.shadowButton,
    );
  }

  /// Deep elevation for modals / floating sheets.
  static BoxDecoration deep({
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: borderRadius ?? BorderRadius.circular(24), // --ae-r-xl
      boxShadow: ScSaasThemeTokens.shadowDeep,
    );
  }

  /// Shiny neutral surface — category wheel chips, icon circles.
  ///
  /// Approximates the CSS: background linear-gradient(155deg, #fff 0%,
  /// #f1ebfb 60%, #e7ddf7 100%) + inset highlight + brand drop shadow.
  /// Flutter cannot do inset box-shadow, so we layer:
  ///   1. A gradient from white → lavender → light purple.
  ///   2. A strong brand-tinted outer drop shadow for lift.
  /// The top-highlight illusion comes from the gradient being lightest at
  /// the top-left — close, not identical.
  static BoxDecoration shiny({
    BorderRadius? borderRadius,
    bool isCircle = false,
  }) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment(-0.6, -0.8), // ≈ 155deg origin
        end: Alignment(0.6, 0.8),
        colors: [
          Color(0xFFFFFFFF), // white
          Color(0xFFF1EBFB), // lavender mid
          Color(0xFFE7DDF7), // light purple
        ],
        stops: [0.0, 0.6, 1.0],
      ),
      shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: isCircle ? null : (borderRadius ?? BorderRadius.circular(999)),
      boxShadow: const [
        // Outer brand-tinted drop shadow (simulates --ae-shiny-shadow outer)
        BoxShadow(
          color: Color(0x6B2D1B5B), // rgba(45,27,91,0.42)
          blurRadius: 20,
          offset: Offset(0, 10),
          spreadRadius: -6,
        ),
      ],
    );
  }

  /// Shiny purple surface — primary action circles, AI icon, sponsor banners.
  ///
  /// Approximates --ae-shiny-purple: linear-gradient(150deg, #a98fe0 0%,
  /// #7f5fc4 55%, #6b4fa8 100%) + inset highlight + drop shadow.
  static BoxDecoration shinyPurple({
    BorderRadius? borderRadius,
    bool isCircle = false,
  }) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment(-0.5, -0.85), // ≈ 150deg origin
        end: Alignment(0.5, 0.85),
        colors: [
          Color(0xFFA98FE0), // lighter purple
          Color(0xFF7F5FC4), // primary
          Color(0xFF6B4FA8), // deeper purple
        ],
        stops: [0.0, 0.55, 1.0],
      ),
      shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: isCircle ? null : (borderRadius ?? BorderRadius.circular(999)),
      boxShadow: const [
        // Outer glow (simulates --ae-shiny-shadow-purple outer)
        BoxShadow(
          color: Color(0x662D1B5B), // rgba(45,27,91,0.4)
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    );
  }
}
