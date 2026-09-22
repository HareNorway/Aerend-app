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

  /// Does this customer follow any shops at all?
  ///
  /// An empty feed means two different things, and they need different answers:
  /// "you follow nobody" wants an Explore call to action, while "the shops you
  /// follow have not posted" must not have one. Without this flag both look
  /// identical from inside the paging controller.
  ///
  /// Null means not yet known — the follow count is fetched alongside the first
  /// page, and until it arrives the safer copy is the one with the CTA.
  final bool? hasFollows;

  const FeedHomeLoaded({
    required this.stories,
    this.storiesLoading = false,
    this.likeInFlight = const {},
    this.hasFollows,
  });

  FeedHomeLoaded copyWith({
    List<FeedStoreStories>? stories,
    bool? storiesLoading,
    Set<String>? likeInFlight,
    bool? hasFollows,
  }) {
    return FeedHomeLoaded(
      stories: stories ?? this.stories,
      storiesLoading: storiesLoading ?? this.storiesLoading,
      likeInFlight: likeInFlight ?? this.likeInFlight,
      hasFollows: hasFollows ?? this.hasFollows,
    );
  }
}
