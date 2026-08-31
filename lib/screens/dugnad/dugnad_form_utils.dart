import 'package:flutter/material.dart';

import '../../theme/design_scale.dart';

import 'gamification_models.dart';

/// Form tempo from backend progress — mirrors `dgFormMeta` in gamify-form.jsx.
enum DugnadFormStatus { up, flat, down }

DugnadFormStatus dugnadFormStatusFromProgress(
  GamificationProgress progress, {
  int warningThreshold = 55,
}) {
  if (progress.formWarning || progress.formValue <= warningThreshold) {
    return DugnadFormStatus.down;
  }
  if (progress.formValue >= 68) return DugnadFormStatus.up;
  return DugnadFormStatus.flat;
}

class DugnadFormTone {
  const DugnadFormTone({
    required this.arrowBackground,
    required this.arrowColor,
  });

  final Color arrowBackground;
  final Color arrowColor;
}

DugnadFormTone dugnadFormTone(DugnadFormStatus status) {
  switch (status) {
    case DugnadFormStatus.up:
      return const DugnadFormTone(
        arrowBackground: Color(0x2422A769),
        arrowColor: Color(0xFF22A769),
      );
    case DugnadFormStatus.down:
      return const DugnadFormTone(
        arrowBackground: Color(0x29E0A93A),
        arrowColor: Color(0xFFE0A93A),
      );
    case DugnadFormStatus.flat:
      return const DugnadFormTone(
        arrowBackground: Color(0x298A86A0),
        arrowColor: Color(0xFF8A86A0),
      );
  }
}

/// Discrete form arrow — mirrors `FormArrow` in gamify-form.jsx.
class DugnadFormArrow extends StatelessWidget {
  const DugnadFormArrow({
    super.key,
    required this.status,
    this.size = 22,
    this.chip = false,
    this.showLabel = true,
  });

  final DugnadFormStatus status;
  final double size;

  /// Prototype `chip` — compact pill (`.dg-formchip`) vs square form-entry tile.
  final bool chip;

  /// When [chip] is true, mirrors `label={false}` to hide the status text.
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final tone = dugnadFormTone(status);
    final arrow = CustomPaint(
      size: Size(size, size),
      painter: _DugnadFormArrowPainter(
        status: status,
        color: tone.arrowColor,
      ),
    );

    // `.dg-formchip` — compact pill used in STØ sheet tempo / boost rows.
    if (chip) {
      return Container(
        padding: EdgeInsets.fromLTRB(
          context.dp(6),
          context.dp(3),
          context.dp(showLabel ? 9 : 6),
          context.dp(3),
        ),
        decoration: BoxDecoration(
          color: tone.arrowBackground,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            arrow,
            if (showLabel) ...[
              SizedBox(width: context.dp(5)),
              Text(
                _chipLabel(status),
                style: TextStyle(
                  fontSize: context.dp(11),
                  fontWeight: FontWeight.w900,
                  letterSpacing: context.dp(11) * -0.01,
                  color: tone.arrowColor,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Form-entry tile — `.dg-form-entry .dg-formarrow` 42×42.
    return Container(
      width: context.dp(42),
      height: context.dp(42),
      decoration: BoxDecoration(
        color: tone.arrowBackground,
        borderRadius: BorderRadius.circular(context.dp(12)),
      ),
      alignment: Alignment.center,
      child: arrow,
    );
  }
}

class _DugnadFormArrowPainter extends CustomPainter {
  _DugnadFormArrowPainter({
    required this.status,
    required this.color,
  });

  final DugnadFormStatus status;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    switch (status) {
      case DugnadFormStatus.up:
        path.moveTo(size.width * 0.2, size.height * 0.62);
        path.lineTo(size.width * 0.5, size.height * 0.28);
        path.lineTo(size.width * 0.8, size.height * 0.62);
        break;
      case DugnadFormStatus.down:
        path.moveTo(size.width * 0.2, size.height * 0.38);
        path.lineTo(size.width * 0.5, size.height * 0.72);
        path.lineTo(size.width * 0.8, size.height * 0.38);
        break;
      case DugnadFormStatus.flat:
        path.moveTo(size.width * 0.2, size.height * 0.5);
        path.lineTo(size.width * 0.68, size.height * 0.5);
        canvas.drawPath(path, paint);
        path.reset();
        path.moveTo(size.width * 0.58, size.height * 0.34);
        path.lineTo(size.width * 0.76, size.height * 0.5);
        path.lineTo(size.width * 0.58, size.height * 0.66);
        break;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DugnadFormArrowPainter oldDelegate) {
    return oldDelegate.status != status || oldDelegate.color != color;
  }
}

String _chipLabel(DugnadFormStatus status) {
  switch (status) {
    case DugnadFormStatus.up:
      return 'I form';
    case DugnadFormStatus.flat:
      return 'Stabil';
    case DugnadFormStatus.down:
      return 'Ute av form';
  }
}
