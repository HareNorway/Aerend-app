import 'package:flutter/material.dart';

import '../../common/auth/onboarding_kit.dart' show onbDisplay, OnbTimeline, onbP;

/// «Vil du se hva mer Ærend kan?» on Hjem (design L3509–3516, `vkHjemKort`):
/// after the first delivery, for a customer who finished the tour; «Spill av»
/// replays it, × hides the card for good. Design px (inside `lfFlow(358)`).
class OnbHjemKort extends StatelessWidget {
  const OnbHjemKort({super.key, required this.onSpill, required this.onLukk});

  final VoidCallback onSpill, onLukk;

  static const String tittel = 'Vil du se hva mer Ærend kan?';
  static const String under = 'Ta Ægil-runden på nytt · ett minutt';
  static const String spill = 'Spill av';

  @override
  Widget build(BuildContext context) {
    final rolig = MediaQuery.maybeDisableAnimationsOf(context) == true;
    // `stigOpp .35s ease both`: 26 px up and in.
    return OnbTimeline(
      durationMs: rolig ? 1 : 350,
      builder: (context, t, child) {
        final p = Curves.ease.transform(onbP(t, 0, rolig ? 1 : 350));
        return Opacity(opacity: p, child: Transform.translate(offset: Offset(0, 26 * (1 - p)), child: child));
      },
      child: Container(
        key: const Key('onb-hjemkort'),
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withValues(alpha: .13), Colors.white.withValues(alpha: .06)]),
          border: Border.all(color: Colors.white.withValues(alpha: .18)),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: .28), width: 1.5)),
        ),
        child: Row(
          children: [
            Image.asset('assets/images/aegil/front.png', width: 40, height: 40, fit: BoxFit.contain),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The design lets both lines wrap (no nowrap).
                  Text(tittel, style: onbDisplay(12.5)),
                  Text(under, style: onbDisplay(11, weight: FontWeight.w600, color: Colors.white.withValues(alpha: .62))),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              key: const Key('onb-hjemkort-spill'),
              behavior: HitTestBehavior.opaque,
              onTap: onSpill,
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xFF5CE0B8).withValues(alpha: .16),
                  border: Border.all(color: const Color(0xFF5CE0B8).withValues(alpha: .5)),
                ),
                child: Text(spill, style: onbDisplay(11.5, color: const Color(0xFF5CE0B8))),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              key: const Key('onb-hjemkort-lukk'),
              behavior: HitTestBehavior.opaque,
              onTap: onLukk,
              child: SizedBox(
                width: 28,
                height: 28,
                child: Center(child: CustomPaint(size: const Size.square(10), painter: _Kryss())),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Kryss extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final p = Paint()
      ..color = Colors.white.withValues(alpha: .7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.scale(k);
    canvas.drawLine(const Offset(6, 6), const Offset(18, 18), p);
    canvas.drawLine(const Offset(18, 6), const Offset(6, 18), p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Kryss o) => false;
}
