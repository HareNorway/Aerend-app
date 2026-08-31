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

  factory FeedStore.fromJson(Map<String, dynamic> json) {
    return FeedStore(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      logoUrl: json['logo_url'] as String?,
      isFollowing: json['is_following'] as bool? ?? false,
    );
  }
}
