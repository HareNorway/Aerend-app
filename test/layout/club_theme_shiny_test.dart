import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/ui/kit/ae_theme.dart';

/// `--ae-shiny-purple` must darken toward the far stop. The feed-card shade
/// helper floors at 0.48 L, which *lightens* a navy accent and inverts the CTA.
void main() {
  test('Sædalen navy CTA darkens along the 150deg ramp', () {
    final navy = AeThemePalette.resolve(accentColor: '#1E4377');
    final g = navy.shinyGradient;

    expect(g.colors, hasLength(3));
    expect(g.stops, [0.0, 0.55, 1.0]);
    expect(g.colors[1], const Color(0xFF1E4377));

    final light = HSLColor.fromColor(g.colors.first);
    final mid = HSLColor.fromColor(g.colors[1]);
    final dark = HSLColor.fromColor(g.colors.last);
    expect(light.lightness, greaterThan(mid.lightness));
    expect(dark.lightness, lessThan(mid.lightness));
  });

  test('shiny stops match buildClubThemeStyle mix 12 / 22', () {
    final navy = AeThemePalette.resolve(accentColor: '#1E4377');
    // mixHex(#1E4377, #fff, 12) / mixHex(#1E4377, #000, 22)
    expect(navy.shinyGradient.colors.first, const Color(0xFF395A87));
    expect(navy.shinyGradient.colors.last, const Color(0xFF17345D));
  });

  test('Ærend defaults keep the authored purple shiny token', () {
    final g = AeThemePalette.defaults.shinyGradient;
    expect(g.colors, const [
      Color(0xFFA98FE0),
      Color(0xFF7F5FC4),
      Color(0xFF6B4FA8),
    ]);
  });
}
