import '../../../data/feed/feed_post.dart';

sealed class PostDetailState {
  const PostDetailState();
}

class PostDetailInitial extends PostDetailState {
  const PostDetailInitial();
}

class PostDetailLoading extends PostDetailState {
  const PostDetailLoading();
}

class PostDetailError extends PostDetailState {
  final String message;
  const PostDetailError(this.message);
}

class PostDetailLoaded extends PostDetailState {
  final FeedPost post;
  final bool likeInFlight;
  final bool commentSending;
  final DateTime? rateLimitUntil;

  const PostDetailLoaded({
    required this.post,
    this.likeInFlight = false,
    this.commentSending = false,
    this.rateLimitUntil,
  });

  bool get isRateLimited =>
      rateLimitUntil != null && DateTime.now().isBefore(rateLimitUntil!);

  PostDetailLoaded copyWith({
    FeedPost? post,
    bool? likeInFlight,
    bool? commentSending,
    DateTime? rateLimitUntil,
    bool clearRateLimit = false,
  }) {
    return PostDetailLoaded(
      post: post ?? this.post,
      likeInFlight: likeInFlight ?? this.likeInFlight,
      commentSending: commentSending ?? this.commentSending,
      rateLimitUntil:
          clearRateLimit ? null : (rateLimitUntil ?? this.rateLimitUntil),
    );
  }
}
