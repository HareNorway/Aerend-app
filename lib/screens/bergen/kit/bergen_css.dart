import 'dart:math' as math;

import 'package:flutter/material.dart';

/// CSS `linear-gradient(<deg>, …)` → the two alignments Flutter wants.
LinearGradient cssLinear(
  double deg,
  List<Color> colors, [
  List<double>? stops,
]) {
  final r = deg * math.pi / 180;
  final dx = math.sin(r);
  final dy = -math.cos(r);
  return LinearGradient(
    begin: Alignment(-dx, -dy),
    end: Alignment(dx, dy),
    colors: colors,
    stops: stops,
  );
}

/// CSS `rgba(r,g,b,a)`.
Color rgba(int r, int g, int b, double a) => Color.fromRGBO(r, g, b, a);
