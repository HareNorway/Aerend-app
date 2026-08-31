import 'package:flutter/material.dart';

import '../../../data/feed/feed_story.dart';
import '../../../l10n/app_localizations.dart';
import 'feed_story_bubble.dart';

class FeedStoriesRow extends StatelessWidget {
  final List<FeedStoreStories> storeStories;
  final void Function(FeedStoreStories store) onStoreStoriesTap;
  final VoidCallback onYourStoryTap;
  final String? yourStoryAvatarUrl;
  final String yourStoryFallbackLetter;

  const FeedStoriesRow({
    super.key,
    required this.storeStories,
    required this.onStoreStoriesTap,
    required this.onYourStoryTap,
    this.yourStoryAvatarUrl,
    this.yourStoryFallbackLetter = '?',
  });

  @override
  Widget build(BuildContext context) {
    if (storeStories.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 108,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: storeStories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FeedStoryBubble(
                label: l10n.feed_story_your_story,
                imageUrl: yourStoryAvatarUrl,
                fallbackLetter: yourStoryFallbackLetter,
                useLetterFallback: true,
                showAddBadge: true,
                onTap: onYourStoryTap,
              ),
            );
          }
          final entry = storeStories[index - 1];
          final letter = entry.store.name.isNotEmpty
              ? entry.store.name[0].toUpperCase()
              : '?';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FeedStoryBubbleImage(
              label: entry.store.name,
              imageUrl: entry.store.logoUrl,
              fallbackLetter: letter,
              onTap: () => onStoreStoriesTap(entry),
            ),
          );
        },
      ),
    );
  }
}
