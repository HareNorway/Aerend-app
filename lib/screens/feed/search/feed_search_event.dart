sealed class FeedSearchEvent {
  const FeedSearchEvent();
}

class FeedSearchQueryChanged extends FeedSearchEvent {
  final String query;
  const FeedSearchQueryChanged(this.query);
}

class FeedSearchSubmitted extends FeedSearchEvent {
  final String query;
  const FeedSearchSubmitted(this.query);
}
