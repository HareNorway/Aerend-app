import 'package:flutter/material.dart';

import '../../../utils/utils.dart';

/// Ærend feed header — purple gradient with Æ logo, location, action buttons.
///
/// Design spec: Feed.jsx hero — purple gradient header with brand mark.
class FeedBrandedHeader extends StatelessWidget {
  const FeedBrandedHeader({
    super.key,
    this.onBackTap,
    this.onHeartTap,
    this.onMessageTap,
  });

  final VoidCallback? onBackTap;
  final VoidCallback? onHeartTap;
  final VoidCallback? onMessageTap;

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.canPop(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF6B4FA8), // Purple 700
            Color(0xFF7F5FC4), // Purple 600
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Row(
        children: [
          // Back button (only when pushed, not when embedded as tab)
          if (canPop)
            GestureDetector(
              onTap: onBackTap ?? () => Navigator.of(context).maybePop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          if (canPop) const SizedBox(width: 8),
          // Æ monogram
          SizedBox(
            width: 28,
            height: 28,
            child: FittedBox(
              fit: BoxFit.contain,
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                    Colors.white, BlendMode.srcIn),
                child: Image.asset(
                  'assets/Logo/aerend_mark_coral.png',
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Feed', style: aeH2(color: Colors.white)),
          ),
          // Heart button
          _headerCircleButton(
            icon: Icons.favorite_border_rounded,
            onTap: onHeartTap,
          ),
          const SizedBox(width: 8),
          // Message button
          _headerCircleButton(
            icon: Icons.send_outlined,
            onTap: onMessageTap,
          ),
        ],
      ),
    );
  }

  Widget _headerCircleButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }
}
