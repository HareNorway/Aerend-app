import 'package:flutter/material.dart';

/// Instagram-style segmented progress indicators for story playback.
class FeedStoryProgressBars extends StatelessWidget {
  final int storyCount;
  final int currentIndex;
  final double currentProgress;

  const FeedStoryProgressBars({
    super.key,
    required this.storyCount,
    required this.currentIndex,
    required this.currentProgress,
  });

  @override
  Widget build(BuildContext context) {
    if (storyCount <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: List.generate(storyCount, (index) {
          final fill = index < currentIndex
              ? 1.0
              : index == currentIndex
                  ? currentProgress.clamp(0.0, 1.0)
                  : 0.0;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: index == 0 ? 0 : 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: fill,
                  minHeight: 2.5,
                  backgroundColor: Colors.white.withValues(alpha: 0.35),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
