import 'package:flutter/material.dart';

import '../../../data/feed/feed_story.dart';
import '../../../networking/feed/feed_cloudinary_config.dart';
import 'feed_story_bubble.dart';

class FeedStoreStoriesRow extends StatelessWidget {
  final List<FeedStory> stories;
  final String storeName;
  final String? logoUrl;
  final void Function(int storyIndex) onStoryTap;

  const FeedStoreStoriesRow({
    super.key,
    required this.stories,
    required this.storeName,
    this.logoUrl,
    required this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) {
      return const SizedBox.shrink();
    }

    final letter =
        storeName.isNotEmpty ? storeName[0].toUpperCase() : '?';

    return SizedBox(
      height: 108,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          final thumbUrl =
              story.media.cloudinaryUrl(FeedCloudinaryConfig.cloudName);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FeedStoryBubbleImage(
              label: storeName,
              imageUrl: thumbUrl,
              fallbackLetter: letter,
              onTap: () => onStoryTap(index),
            ),
          );
        },
      ),
    );
  }
}
