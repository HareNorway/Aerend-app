import 'package:flutter/material.dart';
import '../../../data/feed/feed_comment.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../utils/feed_time_ago.dart';

class FeedCommentTile extends StatelessWidget {
  final FeedComment comment;
  final VoidCallback? onLongPress;

  const FeedCommentTile({
    super.key,
    required this.comment,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final letter = comment.user.name.isNotEmpty
        ? comment.user.name[0].toUpperCase()
        : '?';
    final timeLabel = feedTimeAgo(comment.createdAt, context);

    return GestureDetector(
      key: const Key('feed_comment_tile_gesture'),
      behavior: HitTestBehavior.opaque,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: scheme.surfaceContainerHighest,
              backgroundImage: comment.user.avatarUrl != null &&
                      comment.user.avatarUrl!.isNotEmpty
                  ? NetworkImage(comment.user.avatarUrl!)
                  : null,
              child: comment.user.avatarUrl == null ||
                      comment.user.avatarUrl!.isEmpty
                  ? Text(
                      letter,
                      style: aeCaption(color: ScSaasThemeTokens.muted).copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: aeLabel(color: ScSaasThemeTokens.text).copyWith(height: 1.35),
                      children: [
                        TextSpan(
                          text: '${comment.user.name} ',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(text: comment.body),
                      ],
                    ),
                  ),
                  if (timeLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      timeLabel,
                      style: aeCaption(color: ScSaasThemeTokens.muted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
