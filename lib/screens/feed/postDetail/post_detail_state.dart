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

/// The post is gone — deleted by its store, or removed by Ærend (T8).
///
/// Separate from [PostDetailError] because it is not an error the customer can
/// retry out of. A deep link from a push notification to a post that has since
/// been taken down should say so and offer a way back, not show a retry button
/// that will fail identically every time.
class PostDetailNotFound extends PostDetailState {
  const PostDetailNotFound();
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
