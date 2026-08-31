import 'package:flutter/material.dart';

class CommonCircularProgressIndicator extends StatelessWidget {
  final double strokeWidth, size;
  final Color color;
  final double? value;

  const CommonCircularProgressIndicator({super.key, required this.strokeWidth, required this.size, required this.color, this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: Center(
        child: SizedBox(
          child: CircularProgressIndicator(strokeWidth: strokeWidth, value: value, valueColor: AlwaysStoppedAnimation<Color>(color)),
        ),
      ),
    );
  }
}
