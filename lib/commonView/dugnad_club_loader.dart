import 'package:flutter/material.dart';

import '../screens/dugnad/dugnad_club_theme.dart';
import '../utils/utils.dart' show languages;

/// Club-themed loader from the design tweaks / loading screenshot:
/// thin orbiting ring + solid center disc + “Laster …” label.
///
/// Color comes from the active club theme ([DugnadClubThemePalette.primary]).
class DugnadClubLoader extends StatelessWidget {
  const DugnadClubLoader({
    super.key,
    this.label,
    this.size = 56,
    this.color,
    this.showLabel = true,
  });

  /// Defaults to localized “Laster…” / “Loading…”.
  final String? label;

  /// Outer ring diameter.
  final double size;

  /// Override; defaults to club [DugnadClubThemePalette.primary].
  final Color? color;

  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final c = color ?? theme.primary;
    final text = label ?? languages.feed_loading;
    final trackW = (size * 0.048).clamp(2.0, 3.0);
    final arcW = (size * 0.056).clamp(2.2, 3.4);
    final disc = size * 0.40;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Soft full track (design: light grey-blue ring).
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: trackW,
                  color: c.withValues(alpha: 0.18),
                ),
              ),
              // Spinning arc in club color.
              SizedBox.expand(
                child: CircularProgressIndicator(
                  strokeWidth: arcW,
                  color: c,
                  strokeCap: StrokeCap.round,
                ),
              ),
              // Faint center disc (same hue, soft fill).
              Container(
                width: disc,
                height: disc,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
        if (showLabel) ...[
          SizedBox(height: size * 0.32),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: 0.01 * 15,
              color: c,
            ),
          ),
        ],
      ],
    );
  }
}

/// Image-slot progress for [CachedNetworkImage] — club orbit, no label.
class DugnadClubImageLoader extends StatelessWidget {
  const DugnadClubImageLoader({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.dugnadTheme.primaryTint,
      child: Center(
        child: DugnadClubLoader(showLabel: false, size: size),
      ),
    );
  }
}

/// Full-screen club loader (`.ae-loader-screen` — club background).
class DugnadClubLoaderScreen extends StatelessWidget {
  const DugnadClubLoaderScreen({
    super.key,
    this.label,
    this.size = 56,
    this.color,
  });

  final String? label;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return ColoredBox(
      color: theme.background,
      child: Center(
        child: DugnadClubLoader(
          label: label,
          size: size,
          color: color ?? theme.primary,
        ),
      ),
    );
  }
}
