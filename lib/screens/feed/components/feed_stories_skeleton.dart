import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class FeedStoriesSkeleton extends StatelessWidget {
  const FeedStoriesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return SizedBox(
      height: 100,
      child: Shimmer.fromColors(
        baseColor: base.withValues(alpha: 0.5),
        highlightColor: Theme.of(context).colorScheme.surface,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 6),
              Container(width: 56, height: 10, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
