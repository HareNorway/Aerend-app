import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/sc_saas_theme.dart';
import '../../../../commonView/surface_decorations.dart';

/// Ærend category wheel — circular arrangement of shiny chips.
///
/// Design spec: Home.jsx — 8-12 chips in a circle, center breathing orb,
/// tap navigates to category. This implementation is tappable and lightly
/// rotatable via drag. Full momentum/friction physics is not included.
class CategoryWheel extends StatefulWidget {
  final List<CategoryChip> categories;
  final ValueChanged<int> onCategoryTap;

  const CategoryWheel({
    super.key,
    required this.categories,
    required this.onCategoryTap,
  });

  @override
  State<CategoryWheel> createState() => _CategoryWheelState();
}

class _CategoryWheelState extends State<CategoryWheel>
    with SingleTickerProviderStateMixin {
  double _rotationAngle = 0;
  late AnimationController _breatheController;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int count = widget.categories.length;
    if (count == 0) return const SizedBox.shrink();

    const double outerRadius = 120; // distance from center to chip center
    const double chipSize = 72;
    const double widgetSize = (outerRadius + chipSize / 2) * 2 + 8;

    return SizedBox(
      width: widgetSize,
      height: widgetSize,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _rotationAngle += details.delta.dx * 0.005;
          });
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center breathing orb
            AnimatedBuilder(
              animation: _breatheController,
              builder: (context, child) {
                final scale = 1.0 + _breatheController.value * 0.08;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: AeSurface.shinyPurple(isCircle: true),
                    child: const Center(
                      child: Icon(Icons.auto_awesome,
                          color: Colors.white, size: 22),
                    ),
                  ),
                );
              },
            ),
            // Category chips arranged in a circle
            ...List.generate(count, (i) {
              final angle =
                  (2 * math.pi * i / count) + _rotationAngle - math.pi / 2;
              final dx = math.cos(angle) * outerRadius;
              final dy = math.sin(angle) * outerRadius;

              return Transform.translate(
                offset: Offset(dx, dy),
                child: _buildChip(widget.categories[i], i),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(CategoryChip cat, int index) {
    const double chipSize = 72;
    return GestureDetector(
      onTap: () => widget.onCategoryTap(index),
      child: SizedBox(
        width: chipSize,
        height: chipSize + 18,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: chipSize,
              height: chipSize,
              decoration: AeSurface.shiny(isCircle: true),
              child: Center(
                child: cat.iconUrl.isNotEmpty
                    ? SvgPicture.network(
                        cat.iconUrl,
                        width: 28,
                        height: 28,
                        colorFilter: const ColorFilter.mode(
                          ScSaasThemeTokens.primaryHover,
                          BlendMode.srcIn,
                        ),
                        placeholderBuilder: (_) => const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Text(
                        cat.label.isNotEmpty ? cat.label[0].toUpperCase() : '?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: ScSaasThemeTokens.primaryHover,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              cat.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ScSaasThemeTokens.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data holder for a category chip in the wheel.
class CategoryChip {
  final int id;
  final String label;
  final String iconUrl;

  const CategoryChip({
    required this.id,
    required this.label,
    this.iconUrl = '',
  });
}
