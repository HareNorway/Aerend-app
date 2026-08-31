import 'package:flutter/material.dart';

import '../../screens/deliveryService/storeDetail/store_detail_dl.dart';
import '../../theme/sc_saas_theme.dart';

/// One review inside the store-review sheet — `.dgs-list` row styling on a
/// white radius-16 card: name 15/700 midnight, a purple rating chip, comment
/// 12.5/600 gray-500 at lh 1.45.
class ItemStoreReviewDialog extends StatelessWidget {
  final StoreRatingListItem storeRatingListItem;

  const ItemStoreReviewDialog({super.key, required this.storeRatingListItem});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme.bodyMedium;
    final comment = storeRatingListItem.comment?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  storeRatingListItem.firstName,
                  style: theme?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ScSaasThemeTokens.text,
                      ) ??
                      const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ScSaasThemeTokens.text,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 5, horizontal: 9),
                decoration: BoxDecoration(
                  color: ScSaasThemeTokens.primaryTint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: ScSaasThemeTokens.primaryHover,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      storeRatingListItem.rating.toString(),
                      style: theme?.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: ScSaasThemeTokens.primaryHover,
                          ) ??
                          const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: ScSaasThemeTokens.primaryHover,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              comment,
              style: theme?.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                    color: ScSaasThemeTokens.gray500,
                  ) ??
                  const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                    color: ScSaasThemeTokens.gray500,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
