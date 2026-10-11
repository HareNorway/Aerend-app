class FeedStore {
  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final bool isFollowing;

  const FeedStore({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    required this.isFollowing,
  });

  /// An Ærend post without a shop (backend plan Step 13): the service sends
  /// `store.id` empty and «Ærend» as the name. There is no profile to open
  /// and nothing to follow.
  bool get hasStore => id.isNotEmpty;

  factory FeedStore.fromJson(Map<String, dynamic> json) {
    return FeedStore(
      id: '${json['id'] ?? ''}',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
      isFollowing: json['is_following'] as bool? ?? false,
    );
  }
}
