import 'package:flutter/material.dart';
import '../../../data/feed/feed_post.dart';
import '../../../networking/feed/feed_cloudinary_config.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../utils/feed_image.dart';

class FeedPostThumbnail extends StatelessWidget {
  final FeedPost post;
  final VoidCallback onTap;

  const FeedPostThumbnail({
    super.key,
    required this.post,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final url = post.media.cloudinaryUrl(FeedCloudinaryConfig.cloudName);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FeedImage(url: url, fit: BoxFit.cover),
            if (post.likeCount > 0 || post.commentCount > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (post.likeCount > 0) ...[
                        const Icon(Icons.favorite, color: Colors.white, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          '${post.likeCount}',
                          style: aeCaption(color: Colors.white).copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                      if (post.likeCount > 0 && post.commentCount > 0)
                        const SizedBox(width: 8),
                      if (post.commentCount > 0) ...[
                        const Icon(
                          Icons.chat_bubble,
                          color: Colors.white,
                          size: 11,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${post.commentCount}',
                          style: aeCaption(color: Colors.white).copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FeedPostsGridDivider extends StatelessWidget {
  const FeedPostsGridDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: ScSaasThemeTokens.border),
            bottom: BorderSide(color: ScSaasThemeTokens.border),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Icon(
                Icons.grid_on_rounded,
                size: 22,
                color: ScSaasThemeTokens.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
