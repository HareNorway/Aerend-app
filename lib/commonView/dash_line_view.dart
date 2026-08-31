import 'package:flutter/material.dart';

class DashLineView extends StatelessWidget {
  final double totalHeight, dashWidth, emptyHeight, dashHeight;

  final Color dashColor;

  const DashLineView({
    this.totalHeight = 50,
    this.dashWidth = 2,
    this.emptyHeight = 5,
    this.dashHeight = 2,
    this.dashColor = Colors.grey,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        totalHeight ~/ (dashWidth + emptyHeight),
        (_) => Flexible(
          child: Container(
            width: dashWidth,
            height: dashHeight,
            color: dashColor,
            margin: EdgeInsets.only(top: emptyHeight / 2, bottom: emptyHeight / 2),
          ),
        ),
      ),
    );
  }
}

class HorizontalDashLineView extends StatelessWidget {
  final double height, dashedWidth;
  final Color color;

  const HorizontalDashLineView({super.key, this.height = 1, this.dashedWidth = 5.0, this.color = Colors.black});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        final dashWidth = dashedWidth;
        final dashHeight = height;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}
