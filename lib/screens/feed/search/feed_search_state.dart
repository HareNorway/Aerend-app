import '../../../data/feed/feed_store.dart';

sealed class FeedSearchState {
  const FeedSearchState();
}

class FeedSearchInitial extends FeedSearchState {
  const FeedSearchInitial();
}

class FeedSearchLoading extends FeedSearchState {
  const FeedSearchLoading();
}

class FeedSearchLoaded extends FeedSearchState {
  final List<FeedStore> results;
  final String query;

  const FeedSearchLoaded({
    required this.results,
    required this.query,
  });
}

class FeedSearchEmpty extends FeedSearchState {
  final String query;
  const FeedSearchEmpty(this.query);
}

class FeedSearchError extends FeedSearchState {
  final String message;
  const FeedSearchError(this.message);
}
