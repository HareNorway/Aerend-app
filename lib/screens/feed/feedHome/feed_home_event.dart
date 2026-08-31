sealed class FeedHomeEvent {
  const FeedHomeEvent();
}

class FeedHomeInitRequested extends FeedHomeEvent {
  const FeedHomeInitRequested();
}

class FeedHomeRefreshRequested extends FeedHomeEvent {
  const FeedHomeRefreshRequested();
}

class FeedHomeLikeToggle extends FeedHomeEvent {
  final String postId;

  const FeedHomeLikeToggle(this.postId);
}

class FeedHomeUnlikeToggle extends FeedHomeEvent {
  final String postId;

  const FeedHomeUnlikeToggle(this.postId);
}
