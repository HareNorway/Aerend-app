import 'package:flutter/material.dart';

import '../../../theme/bergen_tokens.dart';

/// The four-step progress row (design `.steg`): done steps are mint, the
/// current one orange, the rest paper. Labels sit under the dots.
class BergenStepper extends StatelessWidget {
  const BergenStepper({
    super.key,
    required this.steps,
    required this.current,
    this.onDark = false,
  });

  /// The default Sporing steps.
  static const List<String> sporing = ['Mottatt', 'Klar', 'På vei', 'Levert'];

  final List<String> steps;

  /// Index of the active step; values past the end mark everything done.
  final int current;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final labelColor = onDark ? Colors.white : BergenTokens.inkSecondary;
    final active = current.clamp(0, steps.length - 1);

    return Semantics(
      label: 'Steg ${active + 1} av ${steps.length}: ${steps[active]}',
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 3,
                  color: i <= current
                      ? BergenTokens.mintDeep
                      : (onDark
                            ? BergenTokens.glassBorder
                            : BergenTokens.paperWarm),
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: BergenTokens.motion(
                    context,
                    BergenTokens.motionBase,
                  ),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < current
                        ? BergenTokens.mintDeep
                        : i == current
                        ? BergenTokens.orange
                        : (onDark
                              ? BergenTokens.glassFill
                              : BergenTokens.paperWarm),
                    border: Border.all(
                      color: i == current
                          ? BergenTokens.orangeDeep
                          : Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[i],
                  style: BergenTokens.text(
                    BergenTokens.textMicro,
                    weight: i == current ? FontWeight.w800 : FontWeight.w600,
                    color: labelColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
