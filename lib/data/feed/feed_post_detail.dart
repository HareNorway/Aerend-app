import 'feed_comment.dart';
import 'feed_page.dart';
import 'feed_post.dart';

class FeedPostDetail extends FeedPost {
  final FeedPage<FeedComment> comments;

  const FeedPostDetail({
    required super.id,
    required super.store,
    required super.caption,
    super.locationName,
    required super.media,
    required super.likeCount,
    required super.commentCount,
    required super.isLiked,
    super.publishedAt,
    required this.comments,
  });

  factory FeedPostDetail.fromJson(Map<String, dynamic> json) {
    final post = FeedPost.fromJson(json);
    return FeedPostDetail(
      id: post.id,
      store: post.store,
      caption: post.caption,
      locationName: post.locationName,
      media: post.media,
      likeCount: post.likeCount,
      commentCount: post.commentCount,
      isLiked: post.isLiked,
      publishedAt: post.publishedAt,
      comments: FeedPage.fromJson(
        json['comments'] as Map<String, dynamic>,
        FeedComment.fromJson,
      ),
    );
  }
}
