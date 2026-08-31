import 'package:flutter/material.dart';

import '../../screens/deliveryService/storeDetail/store_detail_dl.dart';
import '../../screens/dugnad/widgets/dugnad_confirm_sheet.dart';
import '../../utils/utils.dart';
import 'item_store_review_dialog.dart';

/// The store's existing reviews. The design has no dedicated screen for this
/// list, so it reuses the shared review-sheet chrome: `.dg-msheet` ›
/// `.dg-msheet-grab` › `.dg-mem-head` (purple tone, star glyph) › the review
/// rows › `.dga-cancel` to close. Present it with `showDugnadSheet`.
class StoreReviewDialog extends StatelessWidget {
  final List<StoreRatingListItem> storeRatingList;

  const StoreReviewDialog({super.key, required this.storeRatingList});

  @override
  Widget build(BuildContext context) {
    return DugnadSheetBody(
      children: [
        DugnadSheetHead(
          icon: Icons.star_rounded,
          title: languages.review,
          message: storeRatingList.isEmpty ? languages.noReviewMsg : null,
        ),
        if (storeRatingList.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 12),
            itemCount: storeRatingList.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (BuildContext context, int position) {
              return ItemStoreReviewDialog(
                storeRatingListItem: storeRatingList[position],
              );
            },
          ),
        DugnadSheetCancelButton(label: languages.close),
      ],
    );
  }
}
