class FeedMedia {
  final String cloudinaryPublicId;
  final String cloudinaryVersion;
  final String format;
  final int width;
  final int height;
  final String resourceType;

  const FeedMedia({
    required this.cloudinaryPublicId,
    required this.cloudinaryVersion,
    required this.format,
    required this.width,
    required this.height,
    required this.resourceType,
  });

  factory FeedMedia.fromJson(Map<String, dynamic> json) {
    return FeedMedia(
      cloudinaryPublicId: json['cloudinary_public_id'] as String,
      cloudinaryVersion: json['cloudinary_version'] as String,
      format: json['format'] as String,
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      resourceType: json['resource_type'] as String,
    );
  }

  String cloudinaryUrl(String cloudName) {
    final type = resourceType == 'video' ? 'video' : 'image';
    return 'https://res.cloudinary.com/$cloudName/$type/upload/f_auto,q_auto/v$cloudinaryVersion/$cloudinaryPublicId.$format';
  }
}
