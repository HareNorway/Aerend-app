import 'feed_date_time.dart';

class FeedCommentUser {
  final String id;
  final String name;
  final String? avatarUrl;

  const FeedCommentUser({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  factory FeedCommentUser.fromJson(Map<String, dynamic> json) {
    return FeedCommentUser(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class FeedComment {
  final String id;
  final String postId;
  final FeedCommentUser user;
  final String body;
  final DateTime createdAt;

  const FeedComment({
    required this.id,
    required this.postId,
    required this.user,
    required this.body,
    required this.createdAt,
  });

  factory FeedComment.fromJson(Map<String, dynamic> json) {
    return FeedComment(
      id: json['id'] as String,
      postId: json['post_id'] as String? ?? '',
      user: FeedCommentUser.fromJson(json['user'] as Map<String, dynamic>),
      body: json['body'] as String,
      createdAt: parseFeedDateTime(json['created_at']),
    );
  }
}
