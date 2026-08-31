import 'package:flutter/material.dart';

import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import 'feed_avatar.dart';

/// Ærend story bubble — purple gradient ring around store avatar.
///
/// Design spec: Stories.jsx — store bubble with gradient ring.
class FeedStoryBubble extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final String fallbackLetter;
  final bool showAddBadge;
  final bool useLetterFallback;
  final VoidCallback onTap;

  const FeedStoryBubble({
    super.key,
    required this.label,
    this.imageUrl,
    required this.fallbackLetter,
    this.showAddBadge = false,
    this.useLetterFallback = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        height: 92,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF7F5FC4), // Purple 600
                        Color(0xFF6CC985), // Acid green
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    child: FeedAvatar(
                      imageUrl: imageUrl,
                      fallbackLetter: fallbackLetter,
                      useLetterFallback: useLetterFallback,
                      radius: 23,
                      backgroundColor: ScSaasThemeTokens.primaryTint,
                      fallbackTextColor: ScSaasThemeTokens.primaryHover,
                    ),
                  ),
                ),
                if (showAddBadge)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: ScSaasThemeTokens.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.add, size: 14, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: aeCaption(color: ScSaasThemeTokens.text).copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar bubble using [FeedImage] for network logos in story rings.
class FeedStoryBubbleImage extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final String fallbackLetter;
  final VoidCallback onTap;

  const FeedStoryBubbleImage({
    super.key,
    required this.label,
    this.imageUrl,
    required this.fallbackLetter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        height: 92,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF7F5FC4),
                    Color(0xFF6CC985),
                  ],
                ),
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white,
                child: FeedAvatar(
                  imageUrl: imageUrl,
                  fallbackLetter: fallbackLetter,
                  radius: 23,
                  backgroundColor: ScSaasThemeTokens.primaryTint,
                  fallbackTextColor: ScSaasThemeTokens.primaryHover,
                  useLetterFallback: true,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: aeCaption(color: ScSaasThemeTokens.text).copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
