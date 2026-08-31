import 'package:flutter/material.dart';

import '../theme/sc_saas_theme.dart';

/// Ærend segmented control — pill container with white-card active segment.
///
/// Design spec: preview/comp-chips-tabs.html → .seg
/// - Container: white bg, radius 14, card shadow, 4px padding/gap.
/// - Active segment: purple-600 fill, white text, radius 10.
/// - Inactive segment: transparent, gray-500 text.
class AeSegmentedControl extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double height;

  const AeSegmentedControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.height = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14), // --ae-r-md
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final bool active = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? ScSaasThemeTokens.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : ScSaasThemeTokens.gray500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
