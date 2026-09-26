class FeedMedia {
  final String cloudinaryPublicId;
  final String cloudinaryVersion;
  final String format;
  final int width;
  final int height;
  final String resourceType;

  /// Video length; null for an image.
  final int? durationMs;

  /// A publisher-supplied poster frame for a video, else null and the poster
  /// is Cloudinary's first frame (see [posterUrl]).
  final String? thumbnailPublicId;

  const FeedMedia({
    required this.cloudinaryPublicId,
    required this.cloudinaryVersion,
    required this.format,
    required this.width,
    required this.height,
    required this.resourceType,
    this.durationMs,
    this.thumbnailPublicId,
  });

  bool get isVideo => resourceType == 'video';

  /// `0:24` — the design's `varighet` pill on a video card.
  String get durationLabel {
    final ms = durationMs ?? 0;
    final total = (ms / 1000).round();
    final m = total ~/ 60;
    final s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  factory FeedMedia.fromJson(Map<String, dynamic> json) {
    return FeedMedia(
      cloudinaryPublicId: json['cloudinary_public_id'] as String,
      cloudinaryVersion: json['cloudinary_version'] as String,
      format: json['format'] as String,
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      resourceType: json['resource_type'] as String,
      durationMs: (json['duration_ms'] as num?)?.toInt(),
      thumbnailPublicId: json['thumbnail_public_id'] as String?,
    );
  }

  String cloudinaryUrl(String cloudName) {
    final type = resourceType == 'video' ? 'video' : 'image';
    return 'https://res.cloudinary.com/$cloudName/$type/upload/f_auto,q_auto/v$cloudinaryVersion/$cloudinaryPublicId.$format';
  }

  /// The still shown before a video plays: the uploaded thumbnail, else the
  /// first frame Cloudinary derives from the video itself.
  String posterUrl(String cloudName) {
    final thumb = thumbnailPublicId;
    if (thumb != null && thumb.isNotEmpty) {
      return 'https://res.cloudinary.com/$cloudName/image/upload/f_auto,q_auto/$thumb.jpg';
    }
    if (!isVideo) return cloudinaryUrl(cloudName);
    return 'https://res.cloudinary.com/$cloudName/video/upload/so_0,f_auto,q_auto/v$cloudinaryVersion/$cloudinaryPublicId.jpg';
  }
}
