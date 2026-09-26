import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../common/home/bergen/bergen_kit.dart';

/// The design frame for Fjordfiske: 390 × 844 with no status bar. The
/// screen is one fixed composition (cards at `top:322`, the rail at
/// `top:582`, the controls at `bottom:104`), so it is fitted with **one**
/// scale — the smaller of width/390 and safe-height/844 — instead of the
/// width-only `context.bs` the scrolling Bergen screens use; on a tall phone
/// the frame keeps its proportions, on a short one nothing collides.
/// [FiskeScope] publishes that scale and also narrows `MediaQuery.size` so
/// `context.bs`, `bText` and `bDisplay` inside the screen read the same
/// number.
class FiskeFrame {
  FiskeFrame.of(BuildContext context)
    : this._(context.dependOnInheritedWidgetOfExactType<FiskeScope>(), context);

  FiskeFrame._(FiskeScope? scope, BuildContext context)
    : s = scope?.s ?? context.bs,
      width = scope?.width ?? MediaQuery.sizeOf(context).width,
      height = scope?.height ?? MediaQuery.sizeOf(context).height,
      safeTop = scope?.safeTop ?? MediaQuery.paddingOf(context).top,
      safeBottom = scope?.safeBottom ?? MediaQuery.paddingOf(context).bottom;

  static const double frameWidth = 390;
  static const double frameHeight = 844;

  final double s;
  final double width;
  final double height;
  final double safeTop;
  final double safeBottom;

  /// Design px → device px.
  double x(double designPx) => designPx * s;

  /// Design `top:` → device y (below the status bar).
  double y(double designTop) => safeTop + designTop * s;

  /// Design `bottom:` → device distance from the bottom (above the home bar).
  double b(double designBottom) => safeBottom + designBottom * s;
}

/// Wraps the screen: computes the uniform scale from the real size and
/// narrows `MediaQuery.size.width` to `390·s` for the kit's `context.bs`.
class FiskeScope extends InheritedWidget {
  const FiskeScope({
    super.key,
    required this.s,
    required this.width,
    required this.height,
    required this.safeTop,
    required this.safeBottom,
    required super.child,
  });

  final double s;
  final double width;
  final double height;
  final double safeTop;
  final double safeBottom;

  static Widget fit({required Widget child}) => LayoutBuilder(
    builder: (context, box) {
      final mq = MediaQuery.of(context);
      final width = box.maxWidth.isFinite ? box.maxWidth : mq.size.width;
      final height = box.maxHeight.isFinite ? box.maxHeight : mq.size.height;
      final safeTop = mq.padding.top;
      final safeBottom = mq.padding.bottom;
      final s = math.min(
        width / FiskeFrame.frameWidth,
        (height - safeTop - safeBottom) / FiskeFrame.frameHeight,
      );
      return FiskeScope(
        s: s,
        width: width,
        height: height,
        safeTop: safeTop,
        safeBottom: safeBottom,
        child: MediaQuery(
          data: mq.copyWith(size: Size(FiskeFrame.frameWidth * s, height)),
          child: child,
        ),
      );
    },
  );

  @override
  bool updateShouldNotify(FiskeScope old) =>
      old.s != s ||
      old.width != width ||
      old.height != height ||
      old.safeTop != safeTop ||
      old.safeBottom != safeBottom;
}

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
