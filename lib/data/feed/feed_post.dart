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

  /// `publisher.type`: `store`, or `aerend` for Ærend's own posts (Step 13).
  final String publisherType;

  /// Ærend posts carry a headline above the caption; null for most.
  final String? headline;

  /// A store profile's post (Bergen UI Step 4, `GET /v1/stores/:id/posts`):
  /// its type (`tilbud`, `ny_i_hyllene` …), price and the product it sells.
  final String? postType;
  final int? priceOre;
  final String? storeProductId;

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
    this.publisherType = 'store',
    this.headline,
    this.postType,
    this.priceOre,
    this.storeProductId,
  });

  /// The post has a picture or video (a text-only post has none).
  bool get hasMedia => media.cloudinaryPublicId.isNotEmpty;

  /// Ærend's post with no shop behind it: no store profile, no follow.
  bool get hasStore => store.hasStore;

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    final storeJson = json['store'];
    final publisher = json['publisher'];
    return FeedPost(
      id: '${json['id']}',
      store: storeJson is Map<String, dynamic>
          ? FeedStore.fromJson(storeJson)
          : const FeedStore(id: '', name: 'Ærend', slug: '', isFollowing: false),
      caption: json['caption'] as String? ?? '',
      locationName: json['location_name'] as String?,
      media: FeedMedia.fromJson(json['media'] as Map<String, dynamic>),
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      publishedAt: parseFeedDateTimeOrNull(json['published_at']),
      publisherType: json['publisher_type'] is String
          ? json['publisher_type'] as String
          : publisher is Map
          ? '${publisher['type'] ?? 'store'}'
          : (storeJson is Map<String, dynamic> && '${storeJson['id'] ?? ''}'.isNotEmpty ? 'store' : 'aerend'),
      headline: json['headline'] as String?,
      postType: json['post_type'] as String?,
      priceOre: (json['price_ore'] as num?)?.toInt(),
      storeProductId: json['store_product_id'] == null ? null : '${json['store_product_id']}',
    );
  }
}
