import 'package:flutter/material.dart';

import '../celebration_models.dart';
import 'celebration_ceremonial_presenter.dart';
import 'dugnad_celebration_overlay.dart';

/// Full-screen route for ceremonial celebrations (T14 club welcome, T9–T15 season-end).
class DugnadCelebrationRoute extends StatelessWidget {
  const DugnadCelebrationRoute({
    super.key,
    required this.item,
    required this.onDismiss,
    this.onCta,
  });

  final PendingCelebration item;
  final VoidCallback onDismiss;
  final VoidCallback? onCta;

  static Future<void> show(
    BuildContext context, {
    required PendingCelebration item,
    required VoidCallback onDismiss,
    VoidCallback? onCta,
  }) {
    if (item.type == CelebrationType.t13 ||
        item.type == CelebrationType.t14 ||
        item.type == CelebrationType.t9 ||
        item.type == CelebrationType.t10 ||
        item.type == CelebrationType.t11 ||
        item.type == CelebrationType.t12 ||
        item.type == CelebrationType.t15) {
      return CelebrationCeremonialPresenter.show(
        context,
        item: item,
        onDismiss: onDismiss,
        onCta: onCta,
      );
    }

    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        pageBuilder: (context, animation, secondary) {
          return DugnadCelebrationRoute(
            item: item,
            onDismiss: () {
              Navigator.of(context).maybePop();
              onDismiss();
            },
            onCta: () {
              Navigator.of(context).maybePop();
              (onCta ?? onDismiss)();
            },
          );
        },
        transitionsBuilder: (context, animation, secondary, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DugnadCelebrationOverlay(
      item: item,
      fullscreen: true,
      onDismiss: onDismiss,
      onCta: onCta,
    );
  }
}
