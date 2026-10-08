/// The admin panel's feed switches («Funksjoner», backend plan Step 13) as
/// `GET /v1/feed/config` answers them. Every switch defaults to on: a feed
/// that cannot read its config looks the way it always has.
class FeedConfig {
  final bool stories;
  final bool comments;
  final bool explore;
  final bool likeCounts;
  final bool sharing;

  const FeedConfig({
    this.stories = true,
    this.comments = true,
    this.explore = true,
    this.likeCounts = true,
    this.sharing = true,
  });

  static const FeedConfig defaults = FeedConfig();

  /// A missing or non-bool field stays on.
  factory FeedConfig.fromJson(Map<String, dynamic> json) {
    bool on(String key) {
      final v = json[key];
      return v is bool ? v : true;
    }

    return FeedConfig(
      stories: on('stories'),
      comments: on('comments'),
      explore: on('explore'),
      likeCounts: on('like_counts'),
      sharing: on('sharing'),
    );
  }

  FeedConfig copyWith({bool? comments}) => FeedConfig(
    stories: stories,
    comments: comments ?? this.comments,
    explore: explore,
    likeCounts: likeCounts,
    sharing: sharing,
  );
}
