import 'package:flutter/material.dart';
import 'package:aerend_customer/theme/app_ui.dart';
import 'package:aerend_customer/dialogs/reviewDialog/review_dialog_repo.dart';
import 'package:aerend_customer/screens/common/home/home_repo.dart';
import 'package:aerend_customer/theme/sc_saas_theme.dart';

import '../../../utils/utils.dart';

// The post-order feedback dialogs (product rating → courier rating), moved
// out of the old `HomeV1` so the Bergen dashboard can run the same flow when
// it is opened with an `orderId` after a delivery.

/// Runs the two dialogs and posts the ratings, exactly as `HomeV1` did.
void runPostOrderFeedback(BuildContext context, int orderId) {
  if (orderId == 0) return;
  final flow = _PostOrderFeedback(context, orderId);
  flow.openFeedbackModal().then((_) {
    flow.openFeedbackModal2().then((Object? result) {
      if (result is! List || result.length < 2) return;
      final num? stars = result[0] as num?;
      final String driverComment = result[1]?.toString() ?? '';
      if (stars == null) return;
      ReviewDialogRepo().callOrderRatingApi(
        orderId,
        null,
        stars.toDouble(),
        null,
        driverComment.isEmpty ? null : driverComment,
      );
    });
  });
}

class _PostOrderFeedback {
  _PostOrderFeedback(this.context, this.orderId);

  final BuildContext context;
  final int orderId;

  openFeedbackModal() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        int amount = 3;
        bool submitting = false;
        final ThemeData theme = Theme.of(dialogContext);
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor:
                  theme.dialogTheme.backgroundColor ??
                  theme.colorScheme.surfaceContainerHigh,
              surfaceTintColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      languages.homeFeedbackTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    onPressed: submitting
                        ? null
                        : () => Navigator.pop(dialogContext),
                    icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
              content: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AbsorbPointer(
                    absorbing: submitting,
                    child: Opacity(
                      opacity: submitting ? 0.45 : 1,
                      child: Builder(
                        builder: (context) {
                          final double panelW =
                              (MediaQuery.sizeOf(context).width - 40).clamp(
                                260.0,
                                520.0,
                              );
                          final double starSize = ((panelW - 32) / 5).clamp(
                            24.0,
                            40.0,
                          );
                          return SingleChildScrollView(
                            child: SizedBox(
                              width: panelW,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    languages.homeFeedbackBody,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.75),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: List.generate(
                                      5,
                                      (index) => Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () async {
                                            setState(() {
                                              amount = index + 1;
                                              submitting = true;
                                            });
                                            try {
                                              await ReviewDialogRepo()
                                                  .callOrderRatingApi(
                                                    orderId,
                                                    amount.toDouble(),
                                                    null,
                                                    null,
                                                    null,
                                                  );
                                              final response = await HomeRepo()
                                                  .addProductRateApi(
                                                    orderId,
                                                    index + 1,
                                                  );
                                              if (response['status'] == 1 &&
                                                  dialogContext.mounted) {
                                                Navigator.pop(dialogContext);
                                              }
                                            } catch (e) {
                                              debugPrint(
                                                "openFeedbackModal: $e",
                                              );
                                            } finally {
                                              if (dialogContext.mounted) {
                                                setState(
                                                  () => submitting = false,
                                                );
                                              }
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: LoadImageSimple(
                                              image: index < amount
                                                  ? 'assets/images/active_star.png'
                                                  : 'assets/images/inactive_star.png',
                                              width: starSize,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (submitting)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ColoredBox(
                          color: theme.colorScheme.surface.withOpacity(0.88),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: ScSaasThemeTokens.primary,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    languages.processing,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  openFeedbackModal1() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        List<String> stateList = ['none', 'none'];
        return AlertDialog(
          content: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: deviceWidth * 0.4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "We need your opinion!",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const Text(
                      "Help others decide what the best to order in the restaurant",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorMainGray, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    StatefulBuilder(
                      builder: (context, setVote) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const LoadImageSimple(
                              image: 'assets/images/products/cruch.png',
                              width: 32,
                              height: 32,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Cruch Rush Pizza',
                              style: TextStyle(fontSize: 16),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => setVote(() => stateList[0] = 'down'),
                              child: LoadImageSimple(
                                image: stateList[0] == 'down'
                                    ? 'assets/images/icons/downvote_red.png'
                                    : 'assets/images/icons/downvote_gray.png',
                                width: 32,
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => setVote(() => stateList[0] = 'up'),
                              child: LoadImageSimple(
                                image: stateList[0] == 'up'
                                    ? 'assets/images/icons/upvote_red.png'
                                    : 'assets/images/icons/upvote_gray.png',
                                width: 32,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    StatefulBuilder(
                      builder: (context, setVote) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const LoadImageSimple(
                              image: 'assets/images/products/cruch.png',
                              width: 32,
                              height: 32,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Cruch Rush Pizza',
                              style: TextStyle(fontSize: 16),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => setVote(() => stateList[1] = 'down'),
                              child: LoadImageSimple(
                                image: stateList[1] == 'down'
                                    ? 'assets/images/icons/downvote_red.png'
                                    : 'assets/images/icons/downvote_gray.png',
                                width: 32,
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => setVote(() => stateList[1] = 'up'),
                              child: LoadImageSimple(
                                image: stateList[1] == 'up'
                                    ? 'assets/images/icons/upvote_red.png'
                                    : 'assets/images/icons/upvote_gray.png',
                                width: 32,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  openFeedbackModal2() {
    const List<String> feedbackOptions = <String>[
      'Very Professional',
      'Arrive on Time',
      'Safety and Hygiene',
      'Handed Gently',
    ];

    return showDialog<List<dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        int amount = 3;
        String comment = "";
        final ThemeData theme = Theme.of(dialogContext);

        Widget starRow(StateSetter setState, double maxWidth) {
          final double safeW = maxWidth.isFinite && maxWidth > 0
              ? maxWidth
              : 280.0;
          final double starSize = ((safeW - 32) / 5).clamp(22.0, 40.0);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              5,
              (index) => Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => amount = index + 1),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: LoadImageSimple(
                      image: index < amount
                          ? 'assets/images/active_star.png'
                          : 'assets/images/inactive_star.png',
                      width: starSize,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        Widget optionChip(
          String label,
          double chipWidth,
          StateSetter setState,
        ) {
          final bool selected = comment == label;
          return SizedBox(
            width: chipWidth,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => comment = label),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? colorPrimary.withOpacity(0.12)
                        : colorMainBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? colorPrimary : Colors.transparent,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? colorPrimary : colorMainGray,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return AlertDialog(
          backgroundColor:
              theme.dialogTheme.backgroundColor ??
              theme.colorScheme.surfaceContainerHigh,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  "Rate a courrier",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: () =>
                    Navigator.pop(dialogContext, <dynamic>[amount, comment]),
                icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
              ),
            ],
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              final double panelW = (MediaQuery.sizeOf(context).width - 40)
                  .clamp(260.0, 520.0);
              const double gap = 8;
              final double chipW = panelW > 280 ? (panelW - gap) / 2 : panelW;
              return SingleChildScrollView(
                child: SizedBox(
                  width: panelW,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Our courier will appreciate your ratings!",
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.75),
                        ),
                      ),
                      const SizedBox(height: 12),
                      starRow(setState, panelW),
                      const SizedBox(height: 16),
                      Text(
                        "Leave a feedback",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        alignment: WrapAlignment.center,
                        children: feedbackOptions
                            .map((label) => optionChip(label, chipW, setState))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, <dynamic>[amount, comment]),
              child: Text(languages.skip),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, <dynamic>[amount, comment]),
              child: Text(languages.submit),
            ),
          ],
        );
      },
    );
  }
}
