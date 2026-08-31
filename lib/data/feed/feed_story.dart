import 'feed_date_time.dart';
import 'feed_media.dart';
import 'feed_store.dart';

class FeedStory {
  final String id;
  final FeedMedia media;
  final String? caption;
  final DateTime expiresAt;
  final DateTime createdAt;

  const FeedStory({
    required this.id,
    required this.media,
    this.caption,
    required this.expiresAt,
    required this.createdAt,
  });

  factory FeedStory.fromJson(Map<String, dynamic> json) {
    return FeedStory(
      id: json['id'] as String,
      media: FeedMedia.fromJson(json['media'] as Map<String, dynamic>),
      caption: json['caption'] as String?,
      expiresAt: parseFeedDateTime(json['expires_at']),
      createdAt: parseFeedDateTime(json['created_at']),
    );
  }
}

class FeedStoreStories {
  final FeedStore store;
  final List<FeedStory> stories;

  const FeedStoreStories({
    required this.store,
    required this.stories,
  });

  factory FeedStoreStories.fromJson(Map<String, dynamic> json) {
    final rawStories = json['stories'] as List<dynamic>? ?? const [];
    return FeedStoreStories(
      store: FeedStore.fromJson(json['store'] as Map<String, dynamic>),
      stories: rawStories
          .map((e) => FeedStory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FeedStoryFeed {
  final List<FeedStoreStories> items;

  const FeedStoryFeed({required this.items});

  factory FeedStoryFeed.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return FeedStoryFeed(
      items: rawItems
          .map((e) => FeedStoreStories.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
