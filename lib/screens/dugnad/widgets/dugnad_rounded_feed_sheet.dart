import 'package:flutter/material.dart';

import '../../../theme/design_scale.dart';
import '../../../ui/kit/ae_theme.dart';

/// Shared `.lb-feed` / `.h-feed` sheet — rounded top over the club hero.
///
/// Design (app.css / dugnad.css / Custom Dugnad.html):
/// ```css
/// .h-feed  { background: var(--ae-lavender); border-radius: 24px 24px 0 0; margin-top: -18px; }
/// .lb-feed { background: var(--ae-lavender); border-radius: 22px 22px 0 0; margin-top: -12px; }
/// ```
///
/// Paint like CSS: rounded [BoxDecoration] fill, **no** [ClipRRect]. Soft
/// anti-aliased clipping blends the curve against the hero and leaves a bright
/// cyan/white fringe on the tips (the “coloring off” bug on every lb-feed
/// screen). Corner cut-outs stay transparent so the real hero shows through.
///
/// Call sites must overlap this sheet onto the purple hero **inside the same
/// paint clip**. Translating a feed sliver up over a previous hero sliver is
/// clipped by [CustomScrollView] and removes the visible curve.
class DugnadRoundedFeedSheet extends StatelessWidget {
  const DugnadRoundedFeedSheet({
    super.key,
    required this.child,
    this.radius,
    this.sheetColor,
    this.heroColor,
    this.heroOverlap,
  });

  /// Sub-page default — `.lb-feed` 22px. Pass home’s 24 for `.h-feed`.
  final double? radius;

  final Widget child;
  final Color? sheetColor;

  /// Ignored — tips come from the hero behind this sheet.
  final Color? heroColor;

  /// Ignored — overlap is owned by the page shell.
  final double? heroOverlap;

  /// Design-px radius for dugnad sub-pages (`.lb-feed`).
  static const double subpageRadius = 22;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final r = context.dp(radius ?? subpageRadius);
    final sheet = sheetColor ?? theme.background;
    final topRadius = BorderRadius.only(
      topLeft: Radius.circular(r),
      topRight: Radius.circular(r),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: sheet,
        borderRadius: topRadius,
      ),
      child: child,
    );
  }
}
