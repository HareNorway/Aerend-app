import 'feed_store.dart';

class FeedCta {
  final String postId;
  final FeedStore store;
  final String deeplinkPath;
  final String webUrl;

  const FeedCta({
    required this.postId,
    required this.store,
    required this.deeplinkPath,
    required this.webUrl,
  });

  factory FeedCta.fromJson(Map<String, dynamic> json) {
    return FeedCta(
      postId: json['post_id'] as String,
      store: FeedStore.fromJson(json['store'] as Map<String, dynamic>),
      deeplinkPath: json['deeplink_path'] as String,
      webUrl: json['web_url'] as String,
    );
  }
}
