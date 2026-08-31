import 'package:flutter/material.dart';

import 'responsive_helper.dart';
import 'responsive_tokens.dart';

class ResponsiveGap extends StatelessWidget {
  const ResponsiveGap(
    this.base, {
    super.key,
    this.axis = Axis.vertical,
    this.min = 0,
    this.max = double.infinity,
  });

  final double base;
  final Axis axis;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final value = r.sizeValue(base, min: min, max: max);
    return axis == Axis.vertical
        ? SizedBox(height: value)
        : SizedBox(width: value);
  }
}

class ResponsiveSection extends StatelessWidget {
  const ResponsiveSection({
    super.key,
    required this.child,
    this.horizontal = UiSpacing.lg,
    this.vertical = 0,
    this.maxWidth,
  });

  final Widget child;
  final double horizontal;
  final double vertical;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: r.sizeValue(
          horizontal,
          min: UiSpacing.md,
          max: UiSpacing.xl,
        ),
        vertical: r.sizeValue(vertical),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? r.maxContentWidth(),
          ),
          child: child,
        ),
      ),
    );
  }
}

class ResponsiveCard extends StatelessWidget {
  const ResponsiveCard({
    super.key,
    required this.child,
    this.color,
    this.radius = UiRadius.lg,
    this.minRadius = 8,
    this.maxRadius = 28,
    this.padding,
    this.minPadding = 0,
    this.maxPadding = double.infinity,
    this.border,
    this.boxShadow,
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final Color? color;
  final double radius;
  final double minRadius;
  final double maxRadius;
  final double? padding;
  final double minPadding;
  final double maxPadding;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final cardChild = padding == null
        ? child
        : Padding(
            padding: EdgeInsets.all(
              r.sizeValue(padding!, min: minPadding, max: maxPadding),
            ),
            child: child,
          );

    return Container(
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(
          r.sizeValue(radius, min: minRadius, max: maxRadius),
        ),
        border: border,
        boxShadow: boxShadow,
      ),
      child: cardChild,
    );
  }
}
