import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class FeedPostSkeleton extends StatelessWidget {
  const FeedPostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Shimmer.fromColors(
        baseColor: base.withValues(alpha: 0.5),
        highlightColor: Theme.of(context).colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 120,
                  height: 14,
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1,
              child: Container(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Container(width: 160, height: 12, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
