import 'package:flutter/widgets.dart';

/// Width of the design's own frame — `.ae-screen { width: 375px }` in
/// `ui_kits/kit-shared.css`. Every value in the prototype CSS (`height: 56`,
/// `font-size: 26px`, `padding: 8px 24px 24px`) is authored against it.
const double kDesignWidth = 375.0;

/// Lower/upper bounds on [DesignScale.ds]. Above `kDesignWidth * kMaxDesignScale`
/// (450pt) we stop scaling and centre a fixed-width column instead, so a tablet
/// never renders a 2.7×-blown-up phone layout.
const double kMinDesignScale = 0.85;
const double kMaxDesignScale = 1.20;

/// Width-anchored scale between the design frame and the real device.
///
/// This is deliberately **not** the old `dimensions.dart` approach. That used
/// arbitrary fractions of `deviceAverageSize` (a mean of width and height), so
/// it was wrong at every size — including the design's own. This is anchored to
/// the design's real frame width: it is exactly `1.0` at 375pt, making the
/// reference frame pixel-exact, and proportional everywhere else.
///
/// Width-only is correct because the frame's aspect (375×812 → 2.165) matches a
/// modern iPhone's (430×932 → 2.167) almost exactly, so scaling by width scales
/// the vertical rhythm too. The exception is the iPhone SE (375×667): there
/// `ds == 1.0`, the content is design-exact, and it simply scrolls — which is
/// what the prototype does when you shorten its frame.
extension DesignScale on BuildContext {
  /// 1.0 on a 375pt-wide device, 1.048 at 393, 1.147 at 430.
  double get ds => (MediaQuery.sizeOf(this).width / kDesignWidth)
      .clamp(kMinDesignScale, kMaxDesignScale);

  /// Scale a design-px value to this device.
  double dp(double designPx) => designPx * ds;

  /// Width of the centred content column: the full device width up to 450pt,
  /// then pinned so tablets get a phone-width column rather than giant text.
  double get designColumnWidth => dp(kDesignWidth);
}

/// Scale a design-authored [TextStyle] to this device.
///
/// `fontSize` and `letterSpacing` both scale — the CSS letter-spacing values
/// are em-relative (`-0.02em`), so they must track the scaled size. `height`
/// is a ratio and is deliberately left alone.
extension DesignScaleTextStyle on TextStyle {
  TextStyle dp(BuildContext context) {
    final s = context.ds;
    if (s == 1.0) return this;
    return copyWith(
      fontSize: fontSize == null ? null : fontSize! * s,
      letterSpacing: letterSpacing == null ? null : letterSpacing! * s,
    );
  }
}
