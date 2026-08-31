import '../../../data/feed/feed_store_profile.dart';
import '../../../data/feed/feed_story.dart';

sealed class StoreProfileState {
  const StoreProfileState();
}

class StoreProfileInitial extends StoreProfileState {
  const StoreProfileInitial();
}

class StoreProfileLoading extends StoreProfileState {
  const StoreProfileLoading();
}

class StoreProfileError extends StoreProfileState {
  final String message;
  const StoreProfileError(this.message);
}

class StoreProfileLoaded extends StoreProfileState {
  final FeedStoreProfile profile;
  final List<FeedStory> stories;
  final bool storiesLoading;
  final bool followInFlight;
  final bool visitInFlight;

  const StoreProfileLoaded({
    required this.profile,
    this.stories = const [],
    this.storiesLoading = false,
    this.followInFlight = false,
    this.visitInFlight = false,
  });

  StoreProfileLoaded copyWith({
    FeedStoreProfile? profile,
    List<FeedStory>? stories,
    bool? storiesLoading,
    bool? followInFlight,
    bool? visitInFlight,
  }) {
    return StoreProfileLoaded(
      profile: profile ?? this.profile,
      stories: stories ?? this.stories,
      storiesLoading: storiesLoading ?? this.storiesLoading,
      followInFlight: followInFlight ?? this.followInFlight,
      visitInFlight: visitInFlight ?? this.visitInFlight,
    );
  }
}
