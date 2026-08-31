class FeedStoreProfile {
  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String? coverUrl;
  final bool isActive;
  final bool isSportsClub;
  final bool isFollowing;
  final int followerCount;
  final int postCount;
  final String? bio;
  final String? description;
  final bool hasActiveStories;
  final String deeplinkPath;

  const FeedStoreProfile({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.coverUrl,
    required this.isActive,
    required this.isSportsClub,
    required this.isFollowing,
    required this.followerCount,
    required this.postCount,
    this.bio,
    this.description,
    required this.hasActiveStories,
    required this.deeplinkPath,
  });

  factory FeedStoreProfile.fromJson(Map<String, dynamic> json) {
    return FeedStoreProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      logoUrl: json['logo_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isSportsClub: json['is_sports_club'] as bool? ?? false,
      isFollowing: json['is_following'] as bool? ?? false,
      followerCount: (json['follower_count'] as num).toInt(),
      postCount: (json['post_count'] as num).toInt(),
      bio: json['bio'] as String?,
      description: json['description'] as String?,
      hasActiveStories: json['has_active_stories'] as bool? ?? false,
      deeplinkPath: json['deeplink_path'] as String,
    );
  }
}
