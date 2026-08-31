import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'feed_store_avatar_assets.dart';

/// Circular store avatar: network logo, else default store profile icon.
class FeedAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackLetter;
  final double radius;
  final Color? backgroundColor;
  final Color? fallbackTextColor;
  final bool useLetterFallback;

  const FeedAvatar({
    super.key,
    this.imageUrl,
    this.fallbackLetter = '?',
    this.radius = 16,
    this.backgroundColor,
    this.fallbackTextColor,
    this.useLetterFallback = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? scheme.surfaceContainerHighest;
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    if (!hasImage) {
      return _fallbackAvatar(bg);
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!.trim(),
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (_, __) => CircleAvatar(
            radius: radius,
            backgroundColor: bg,
            child: _fallbackContent(bg),
          ),
          errorWidget: (_, __, ___) => _fallbackAvatar(bg),
        ),
      ),
    );
  }

  Widget _fallbackAvatar(Color bg) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: ClipOval(
        child: _fallbackContent(bg),
      ),
    );
  }

  Widget _fallbackContent(Color bg) {
    if (useLetterFallback) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: Text(
          fallbackLetter,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: radius * 0.85,
            color: fallbackTextColor,
          ),
        ),
      );
    }

    return Image.asset(
      FeedStoreAvatarAssets.defaultImage,
      width: radius * 2,
      height: radius * 2,
      fit: BoxFit.cover,
    );
  }
}
