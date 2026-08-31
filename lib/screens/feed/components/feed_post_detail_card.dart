import 'package:flutter/material.dart';
import '../../../data/feed/feed_post.dart';
import '../../../networking/feed/feed_cloudinary_config.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import 'feed_avatar.dart';
import '../utils/feed_image.dart';
import '../utils/feed_time_ago.dart';

class FeedPostDetailCard extends StatelessWidget {
  final FeedPost post;
  final VoidCallback onLikeTap;
  final VoidCallback onStoreTap;
  final bool isLikeInFlight;

  const FeedPostDetailCard({
    super.key,
    required this.post,
    required this.onLikeTap,
    required this.onStoreTap,
    this.isLikeInFlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final storeLetter = post.store.name.isNotEmpty
        ? post.store.name[0].toUpperCase()
        : '?';
    final imageUrl =
        post.media.cloudinaryUrl(FeedCloudinaryConfig.cloudName);
    final timeLabel = feedTimeAgo(post.publishedAt, context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                GestureDetector(
                  onTap: onStoreTap,
                  child: FeedAvatar(
                    imageUrl: post.store.logoUrl,
                    fallbackLetter: storeLetter,
                    radius: 16,
                    backgroundColor: scheme.surfaceContainerHighest,
                    fallbackTextColor: ScSaasThemeTokens.muted,
                    useLetterFallback: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onStoreTap,
                    child: Text(
                      post.store.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: aeLabel(color: ScSaasThemeTokens.text).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        FeedImage(url: imageUrl, aspectRatio: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: isLikeInFlight ? null : onLikeTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        post.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: post.isLiked
                            ? ScSaasThemeTokens.danger
                            : scheme.outline,
                        size: 26,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.likeCount}',
                        style: aeLabel(color: ScSaasThemeTokens.text).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              if (post.caption.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  post.caption,
                  style: aeLabel(color: ScSaasThemeTokens.text).copyWith(height: 1.35),
                ),
              ],
              if (timeLabel.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  timeLabel,
                  style: aeCaption(color: ScSaasThemeTokens.muted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
