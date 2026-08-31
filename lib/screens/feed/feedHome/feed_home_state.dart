import '../../../data/feed/feed_story.dart';

sealed class FeedHomeState {
  const FeedHomeState();
}

class FeedHomeInitial extends FeedHomeState {
  const FeedHomeInitial();
}

class FeedHomeLoading extends FeedHomeState {
  const FeedHomeLoading();
}

class FeedHomeLoginRequired extends FeedHomeState {
  const FeedHomeLoginRequired();
}

class FeedHomeError extends FeedHomeState {
  final String message;

  const FeedHomeError(this.message);
}

class FeedHomeLoaded extends FeedHomeState {
  final List<FeedStoreStories> stories;
  final bool storiesLoading;
  final Set<String> likeInFlight;

  const FeedHomeLoaded({
    required this.stories,
    this.storiesLoading = false,
    this.likeInFlight = const {},
  });

  FeedHomeLoaded copyWith({
    List<FeedStoreStories>? stories,
    bool? storiesLoading,
    Set<String>? likeInFlight,
  }) {
    return FeedHomeLoaded(
      stories: stories ?? this.stories,
      storiesLoading: storiesLoading ?? this.storiesLoading,
      likeInFlight: likeInFlight ?? this.likeInFlight,
    );
  }
}
