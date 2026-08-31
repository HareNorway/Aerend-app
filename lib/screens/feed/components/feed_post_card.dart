import 'package:flutter/material.dart';

import '../../../commonView/surface_decorations.dart';
import '../../../data/feed/feed_post.dart';
import '../../../l10n/app_localizations.dart';
import '../../../networking/feed/feed_cloudinary_config.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import 'feed_avatar.dart';
import '../utils/feed_image.dart';
import '../utils/feed_time_ago.dart';

class FeedPostCard extends StatelessWidget {
  final FeedPost post;
  final VoidCallback onLikeTap;
  final VoidCallback onStoreTap;
  final VoidCallback onCommentsTap;
  final VoidCallback onVisitStoreTap;
  final VoidCallback onKebabTap;
  final bool isLikeInFlight;

  const FeedPostCard({
    super.key,
    required this.post,
    required this.onLikeTap,
    required this.onStoreTap,
    required this.onCommentsTap,
    required this.onVisitStoreTap,
    required this.onKebabTap,
    this.isLikeInFlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final storeLetter = post.store.name.isNotEmpty
        ? post.store.name[0].toUpperCase()
        : '?';
    final imageUrl =
        post.media.cloudinaryUrl(FeedCloudinaryConfig.cloudName);
    final timeLabel = feedTimeAgo(post.publishedAt, context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: AeSurface.card(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Store header row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onStoreTap,
                    child: FeedAvatar(
                      imageUrl: post.store.logoUrl,
                      fallbackLetter: storeLetter,
                      radius: 18,
                      backgroundColor: ScSaasThemeTokens.primaryTint,
                      fallbackTextColor: ScSaasThemeTokens.primaryHover,
                      useLetterFallback: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: onStoreTap,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.store.name, style: aeTitle()),
                          if (timeLabel.isNotEmpty)
                            Text(timeLabel, style: aeCaption()),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz_rounded),
                    onPressed: onKebabTap,
                    color: ScSaasThemeTokens.gray500,
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            // Post image
            ClipRRect(
              child: FeedImage(url: imageUrl, aspectRatio: 1),
            ),
            // Actions row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Row(
                children: [
                  // Like
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
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: post.isLiked
                                ? ScSaasThemeTokens.danger
                                : ScSaasThemeTokens.gray500,
                            size: 24,
                          ),
                          const SizedBox(width: 4),
                          Text('${post.likeCount}', style: aeLabel()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Comments
                  InkWell(
                    onTap: onCommentsTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              color: ScSaasThemeTokens.gray500, size: 22),
                          const SizedBox(width: 4),
                          Text('${post.commentCount}', style: aeLabel()),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Bookmark hidden — no save endpoint.
                ],
              ),
            ),
            // Caption
            if (post.caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                child: Text(post.caption, maxLines: 3,
                    overflow: TextOverflow.ellipsis, style: aeBody()),
              ),
            // View comments
            if (post.commentCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                child: GestureDetector(
                  onTap: onCommentsTap,
                  child: Text(
                    l10n.feed_view_comments(post.commentCount),
                    style: aeCaption(color: ScSaasThemeTokens.primaryHover),
                  ),
                ),
              ),
            // Visit store CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: GestureDetector(
                onTap: onVisitStoreTap,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: ScSaasThemeTokens.primaryTint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    l10n.store_profile_visit_store,
                    style: aeLabel(color: ScSaasThemeTokens.primaryHover),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
