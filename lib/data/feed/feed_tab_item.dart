import 'feed_date_time.dart';
import 'feed_media.dart';
import 'feed_store.dart';

/// One item from `GET /v1/feed/tabs` (feed update spec §3.1).
///
/// Distinct from [FeedPost] because `store` is nullable here: an Ærend-published
/// post has no shop behind it. Keeping them apart means the older post card,
/// which assumes a store, cannot be handed one of these by accident.
class FeedTabItem {
  const FeedTabItem({
    required this.id,
    required this.publisherType,
    required this.publisherName,
    required this.postType,
    required this.caption,
    required this.media,
    this.store,
    this.publisherLogoUrl,
    this.category,
    this.headline,
    this.bydel,
    this.locationName,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.publishedAt,
    this.expiresAt,
    this.storeProductId,
    this.priceOre,
    this.attributedOrderCount = 0,
  });

  static const String publisherStore = 'store';
  static const String publisherAerend = 'aerend';

  final String id;

  /// `store` or `aerend`.
  final String publisherType;

  /// The shop's name, or "Ærend".
  final String publisherName;
  final String? publisherLogoUrl;

  /// Null for an Ærend post.
  final FeedStore? store;

  final String postType;
  final String? category;
  final String? headline;
  final String? bydel;

  final String caption;
  final String? locationName;
  final FeedMedia media;

  final int likeCount;
  final int commentCount;
  final bool isLiked;

  final DateTime? publishedAt;
  final DateTime? expiresAt;

  /// The one store product this post is about, and its cached price in øre.
  /// Null when the post is not about a product — the card then leads to the
  /// store rather than straight into the cart.
  final int? storeProductId;
  final int? priceOre;
  final int attributedOrderCount;

  bool get isFromAerend => publisherType == publisherAerend;

  /// A product the customer can add straight from the card.
  bool get hasProduct =>
      storeProductId != null && storeProductId! > 0 && store != null;

  /// Published today, in the device's local day.
  bool get isFromToday {
    final at = publishedAt?.toLocal();
    if (at == null) return false;
    final now = DateTime.now();
    return at.year == now.year && at.month == now.month && at.day == now.day;
  }

  /// What to show as the card's title: the headline if there is one, else the
  /// caption. A card with neither is not worth rendering, and the server does
  /// not produce one.
  String get title =>
      (headline != null && headline!.trim().isNotEmpty) ? headline! : caption;

  factory FeedTabItem.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? storeJson =
        json['store'] as Map<String, dynamic>?;
    final Map<String, dynamic> publisher =
        (json['publisher'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    return FeedTabItem(
      id: json['id'].toString(),
      publisherType: (publisher['type'] ?? publisherStore).toString(),
      publisherName: (publisher['name'] ?? '').toString(),
      publisherLogoUrl: publisher['logo_url'] as String?,
      store: storeJson == null ? null : FeedStore.fromJson(storeJson),
      postType: (json['post_type'] ?? 'generic').toString(),
      category: json['category'] as String?,
      headline: json['headline'] as String?,
      bydel: json['bydel'] as String?,
      caption: (json['caption'] ?? '').toString(),
      locationName: json['location_name'] as String?,
      media: FeedMedia.fromJson(json['media'] as Map<String, dynamic>),
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      publishedAt: parseFeedDateTimeOrNull(json['published_at']),
      expiresAt: parseFeedDateTimeOrNull(json['expires_at']),
      storeProductId: int.tryParse('${json['store_product_id'] ?? ''}'),
      priceOre: (json['price_ore'] as num?)?.toInt(),
      attributedOrderCount:
          (json['attributed_order_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A page of one tab.
class FeedTabPage {
  const FeedTabPage({
    required this.tab,
    required this.label,
    required this.items,
    this.nextCursor,
  });

  final String tab;

  /// The tab's display name as the server gave it — «I nærheten», «Følger»,
  /// «Fra Ærend». Taken from the server so the two never disagree.
  final String label;

  final List<FeedTabItem> items;
  final String? nextCursor;

  factory FeedTabPage.fromJson(Map<String, dynamic> json) {
    return FeedTabPage(
      tab: (json['tab'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      items: ((json['items'] as List<dynamic>?) ?? const <dynamic>[])
          .map((dynamic e) => FeedTabItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['next_cursor'] as String?,
    );
  }
}
