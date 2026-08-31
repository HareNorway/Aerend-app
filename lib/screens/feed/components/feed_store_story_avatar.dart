import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../theme/sc_saas_theme.dart';

/// Instagram-style gradient ring when [hasActiveStory] is true.
class FeedStoreStoryAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackLetter;
  final bool hasActiveStory;
  final double size;
  final VoidCallback? onTap;

  const FeedStoreStoryAvatar({
    super.key,
    this.imageUrl,
    required this.fallbackLetter,
    required this.hasActiveStory,
    this.size = 86,
    this.onTap,
  });

  static const List<Color> _storyRingColors = [
    Color(0xFFF58529),
    Color(0xFFDD2A7B),
    Color(0xFF8134AF),
    Color(0xFF515BD4),
  ];

  @override
  Widget build(BuildContext context) {
    final innerSize = size - (hasActiveStory ? 6 : 4);
    final avatarSize = innerSize - (hasActiveStory ? 6 : 4);
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    Widget avatar = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(hasActiveStory ? 3 : 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasActiveStory
            ? const SweepGradient(
                colors: _storyRingColors,
                startAngle: 0,
                endAngle: 6.28,
              )
            : null,
        border: hasActiveStory
            ? null
            : Border.all(color: ScSaasThemeTokens.border, width: 2),
      ),
      child: Container(
        padding: EdgeInsets.all(hasActiveStory ? 2.5 : 0),
        decoration: const BoxDecoration(
          color: ScSaasThemeTokens.card,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: hasImage
              ? CachedNetworkImage(
                  imageUrl: imageUrl!.trim(),
                  width: avatarSize,
                  height: avatarSize,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _defaultAvatar(avatarSize),
                  errorWidget: (_, __, ___) => _defaultAvatar(avatarSize),
                )
              : _defaultAvatar(avatarSize),
        ),
      ),
    );

    if (hasActiveStory && onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  Widget _defaultAvatar(double avatarSize) {
    return Container(
      width: avatarSize,
      height: avatarSize,
      color: ScSaasThemeTokens.primary.withValues(alpha: 0.14),
      alignment: Alignment.center,
      child: Text(
        fallbackLetter,
        style: TextStyle(
          color: ScSaasThemeTokens.primary,
          fontSize: avatarSize * 0.42,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
