class FollowToggleResult {
  final String storeId;
  final bool isFollowing;
  final int? followerCount;

  const FollowToggleResult({
    required this.storeId,
    required this.isFollowing,
    this.followerCount,
  });

  factory FollowToggleResult.fromJson(Map<String, dynamic> json) {
    return FollowToggleResult(
      storeId: json['store_id'] as String,
      isFollowing: json['is_following'] as bool,
      followerCount: json['follower_count'] == null
          ? null
          : (json['follower_count'] as num).toInt(),
    );
  }
}

class LikeToggleResult {
  final String postId;
  final bool isLiked;
  final int? likeCount;

  const LikeToggleResult({
    required this.postId,
    required this.isLiked,
    this.likeCount,
  });

  factory LikeToggleResult.fromJson(Map<String, dynamic> json) {
    return LikeToggleResult(
      postId: json['post_id'] as String,
      isLiked: json['is_liked'] as bool,
      likeCount: json['like_count'] == null
          ? null
          : (json['like_count'] as num).toInt(),
    );
  }
}

class CommentDeleteResult {
  final String commentId;
  final bool deleted;
  final int postCommentCount;

  const CommentDeleteResult({
    required this.commentId,
    required this.deleted,
    required this.postCommentCount,
  });

  factory CommentDeleteResult.fromJson(Map<String, dynamic> json) {
    return CommentDeleteResult(
      commentId: json['comment_id'] as String,
      deleted: json['deleted'] as bool,
      postCommentCount: (json['post_comment_count'] as num).toInt(),
    );
  }
}
