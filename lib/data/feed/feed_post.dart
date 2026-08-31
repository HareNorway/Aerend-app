import 'feed_date_time.dart';
import 'feed_media.dart';
import 'feed_store.dart';

class FeedPost {
  final String id;
  final FeedStore store;
  final String caption;
  final String? locationName;
  final FeedMedia media;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final DateTime? publishedAt;

  const FeedPost({
    required this.id,
    required this.store,
    required this.caption,
    this.locationName,
    required this.media,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    this.publishedAt,
  });

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    return FeedPost(
      id: json['id'] as String,
      store: FeedStore.fromJson(json['store'] as Map<String, dynamic>),
      caption: json['caption'] as String? ?? '',
      locationName: json['location_name'] as String?,
      media: FeedMedia.fromJson(json['media'] as Map<String, dynamic>),
      likeCount: (json['like_count'] as num).toInt(),
      commentCount: (json['comment_count'] as num).toInt(),
      isLiked: json['is_liked'] as bool? ?? false,
      publishedAt: parseFeedDateTimeOrNull(json['published_at']),
    );
  }
}
