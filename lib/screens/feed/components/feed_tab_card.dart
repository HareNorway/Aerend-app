import 'package:flutter/material.dart';

import '../../../data/feed/feed_tab_item.dart';
import '../../../networking/feed/feed_cloudinary_config.dart';
import '../../../theme/sc_saas_theme.dart';
import '../utils/feed_image.dart';

/// A card in one of the publisher tabs.
///
/// Two things it does that the older post card cannot: it renders a post with
/// no shop behind it (an Ærend post), and it shows the *live* product price
/// rather than whatever was true when the post was written. A card that quotes
/// a stale price is worse than a card with no price — the customer arrives
/// expecting one number and is charged another.
class FeedTabCard extends StatelessWidget {
  const FeedTabCard({
    super.key,
    required this.item,
    this.livePriceOre,
    this.onTap,
    this.onPublisherTap,
  });

  final FeedTabItem item;

  /// The product's price as of now, fetched separately. Null means unknown, and
  /// then no price is shown at all rather than a guess.
  final int? livePriceOre;

  final VoidCallback? onTap;
  final VoidCallback? onPublisherTap;

  static String formatOre(int ore) {
    if (ore % 100 == 0) {
      return (ore ~/ 100).toString();
    }
    final String kr = (ore ~/ 100).toString();
    final String rest = (ore % 100).toString().padLeft(2, '0');
    return '$kr,$rest';
  }

  @override
  Widget build(BuildContext context) {
    final String mediaUrl =
        item.media.cloudinaryUrl(FeedCloudinaryConfig.cloudName);

    return Card(
      key: Key('feed_tab_card_${item.id}'),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 4 / 3,
              child: FeedImage(url: mediaUrl, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  InkWell(
                    key: Key('feed_tab_publisher_${item.id}'),
                    onTap: onPublisherTap,
                    child: Row(
                      children: <Widget>[
                        Text(
                          item.publisherName,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (item.isFromAerend) ...<Widget>[
                          const SizedBox(width: 6),
                          // Labelled on the card as well as by the tab: a card
                          // screenshotted or deep-linked out of its tab must
                          // still say who wrote it.
                          Container(
                            key: Key('feed_tab_aerend_badge_${item.id}'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: ScSaasThemeTokens.primary
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Ærend',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (item.headline != null &&
                      item.caption.trim().isNotEmpty &&
                      item.caption != item.headline) ...<Widget>[
                    const SizedBox(height: 3),
                    Text(item.caption, style: const TextStyle(fontSize: 13)),
                  ],
                  if (livePriceOre != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      '${formatOre(livePriceOre!)} kr',
                      key: Key('feed_tab_price_${item.id}'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  if (item.bydel != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      item.bydel!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ScSaasThemeTokens.muted,
                      ),
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
