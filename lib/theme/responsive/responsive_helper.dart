import 'package:flutter/material.dart';

import 'responsive_tokens.dart';

class ResponsiveHelper {
  ResponsiveHelper(this.context);

  final BuildContext context;

  MediaQueryData get _mq => MediaQuery.of(context);

  Size get size => _mq.size;
  double get width => size.width;
  double get height => size.height;
  double get shortestSide => size.shortestSide;
  double get textScaleFactor => _mq.textScaleFactor;

  bool get isSmallPhone => width < ResponsiveBreakpoints.smallPhone;
  bool get isPhone => width < ResponsiveBreakpoints.phone;
  bool get isTablet =>
      width >= ResponsiveBreakpoints.phone &&
      width < ResponsiveBreakpoints.tablet;
  bool get isDesktop => width >= ResponsiveBreakpoints.tablet;

  double get _layoutScale {
    final double widthScale = width / 390;
    return _clamp(widthScale, 0.88, 1.24);
  }

  double get _fontScale {
    final double scale = _layoutScale * _clamp(textScaleFactor, 1.0, 1.2);
    return _clamp(scale, 0.92, 1.3);
  }

  double w(double factor, {double min = 0, double max = double.infinity}) {
    return _clamp(width * factor, min, max);
  }

  double h(double factor, {double min = 0, double max = double.infinity}) {
    return _clamp(height * factor, min, max);
  }

  double sizeValue(
    double base, {
    double min = 0,
    double max = double.infinity,
  }) {
    return _clamp(base * _layoutScale, min, max);
  }

  double text(double base, {double min = 0, double max = double.infinity}) {
    return _clamp(base * _fontScale, min, max);
  }

  EdgeInsets pagePadding({
    double horizontal = UiSpacing.lg,
    double vertical = 0,
  }) {
    return EdgeInsets.symmetric(
      horizontal: sizeValue(horizontal, min: UiSpacing.md, max: UiSpacing.xl),
      vertical: sizeValue(vertical),
    );
  }

  double maxContentWidth({
    double phone = 560,
    double tablet = 760,
    double desktop = 980,
  }) {
    if (isDesktop) return desktop;
    if (isTablet) return tablet;
    return phone;
  }

  int adaptiveColumns({int phone = 2, int tablet = 3, int desktop = 4}) {
    if (isDesktop) return desktop;
    if (isTablet) return tablet;
    return phone;
  }

  double _clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}

extension ResponsiveBuildContext on BuildContext {
  ResponsiveHelper get responsive => ResponsiveHelper(this);
}
