import 'dart:math';

import 'package:flutter/material.dart';

abstract class Shape {
  Path build({Rect rect, double scale});
}

abstract class BorderShape {
  void drawBorder(Canvas canvas, Rect rect);
}

class ShapeOfViewBorder extends ShapeBorder {
  final Shape? shape;

  const ShapeOfViewBorder({this.shape}) : assert(shape != null);

  @override
  EdgeInsetsGeometry get dimensions {
    return const EdgeInsets.all(0);
  }

  @override
  ShapeBorder scale(double t) => this;

  /*
  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    if (a is CircleBorder)
      return CircleBorder(side: BorderSide.lerp(a.side, side, t));
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    if (b is CircleBorder)
      return CircleBorder(side: BorderSide.lerp(side, b.side, t));
    return super.lerpTo(b, t);
  }
  */

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return shape!.build(rect: rect, scale: 1);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (shape is BorderShape) {
      (shape as BorderShape).drawBorder(canvas, rect);
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (runtimeType != other.runtimeType) return false;
    final ShapeOfViewBorder typedOther = other;
    return shape == typedOther.shape;
  }

  @override
  int get hashCode => shape.hashCode;

  @override
  String toString() {
    return '$runtimeType($shape)';
  }
}

class BubbleShapeView extends StatelessWidget {
  final Widget? child;
  final double? elevation;
  final Clip? clipBehavior;
  final double? height;
  final double? width;

  final BubblePosition? bubblePosition;
  final double? bubbleBorderRadius;
  final double? bubbleArrowHeight;
  final double? bubbleArrowWidth;
  final double? bubbleArrowPositionPercent;

  const BubbleShapeView(
      {super.key,
      this.child,
      this.elevation = 4,
      this.clipBehavior = Clip.antiAlias,
      this.width,
      this.height,
      this.bubblePosition = BubblePosition.bottom,
      this.bubbleBorderRadius = 12,
      this.bubbleArrowHeight = 10,
      this.bubbleArrowWidth = 10,
      this.bubbleArrowPositionPercent = 0.5});

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: ShapeOfViewBorder(
        shape: BubbleShape(
          arrowHeight: bubbleArrowHeight!,
          arrowPositionPercent: bubbleArrowPositionPercent!,
          arrowWidth: bubbleArrowWidth!,
          borderRadius: bubbleBorderRadius!,
          position: bubblePosition!,
        ),
      ),
      clipBehavior: clipBehavior!,
      elevation: elevation!,
      child: SizedBox(
        height: height,
        width: width,
        child: child,
      ),
    );
  }
}

enum BubblePosition { bottom, top, left, right }

class BubbleShape extends Shape {
  final BubblePosition position;

  final double borderRadius;
  final double arrowHeight;
  final double arrowWidth;

  final double arrowPositionPercent;

  BubbleShape({
    this.position = BubblePosition.bottom,
    this.borderRadius = 12,
    this.arrowHeight = 10,
    this.arrowWidth = 10,
    this.arrowPositionPercent = 0.5,
  });

  @override
  Path build({Rect? rect, double? scale}) {
    return generatePath(rect: rect!);
  }

  Path generatePath({Rect? rect}) {
    final Path path = Path();

    double topLeftDiameter = max(borderRadius, 0);
    double topRightDiameter = max(borderRadius, 0);
    double bottomLeftDiameter = max(borderRadius, 0);
    double bottomRightDiameter = max(borderRadius, 0);

    final double spacingLeft = position == BubblePosition.left ? arrowHeight : 0;
    final double spacingTop = position == BubblePosition.top ? arrowHeight : 0;
    final double spacingRight = position == BubblePosition.right ? arrowHeight : 0;
    final double spacingBottom = position == BubblePosition.bottom ? arrowHeight : 0;

    final double left = spacingLeft + rect!.left;
    final double top = spacingTop + rect.top;
    final double right = rect.right - spacingRight;
    final double bottom = rect.bottom - spacingBottom;

    final double centerX = (rect.left + rect.right) * arrowPositionPercent;

    path.moveTo(left + topLeftDiameter / 2.0, top);
    //LEFT, TOP

    if (position == BubblePosition.top) {
      path.lineTo(centerX - arrowWidth, top);
      path.lineTo(centerX, rect.top);
      path.lineTo(centerX + arrowWidth, top);
    }
    path.lineTo(right - topRightDiameter / 2.0, top);

    path.quadraticBezierTo(right, top, right, top + topRightDiameter / 2);
    //RIGHT, TOP

    if (position == BubblePosition.right) {
      path.lineTo(right, bottom - (bottom * (1 - arrowPositionPercent)) - arrowWidth);
      path.lineTo(rect.right, bottom - (bottom * (1 - arrowPositionPercent)));
      path.lineTo(right, bottom - (bottom * (1 - arrowPositionPercent)) + arrowWidth);
    }
    path.lineTo(right, bottom - bottomRightDiameter / 2);

    path.quadraticBezierTo(right, bottom, right - bottomRightDiameter / 2, bottom);
    //RIGHT, BOTTOM

    if (position == BubblePosition.bottom) {
      path.lineTo(centerX + arrowWidth, bottom);
      path.lineTo(centerX, rect.bottom);
      path.lineTo(centerX - arrowWidth, bottom);
    }
    path.lineTo(left + bottomLeftDiameter / 2, bottom);

    path.quadraticBezierTo(left, bottom, left, bottom - bottomLeftDiameter / 2);
    //LEFT, BOTTOM

    if (position == BubblePosition.left) {
      path.lineTo(left, bottom - (bottom * (1 - arrowPositionPercent)) + arrowWidth);
      path.lineTo(rect.left, bottom - (bottom * (1 - arrowPositionPercent)));
      path.lineTo(left, bottom - (bottom * (1 - arrowPositionPercent)) - arrowWidth);
    }
    path.lineTo(left, top + topLeftDiameter / 2);

    path.quadraticBezierTo(left, top, left + topLeftDiameter / 2, top);

    path.close();

    return path;
  }
}
