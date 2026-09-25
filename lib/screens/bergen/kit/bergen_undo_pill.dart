import 'package:flutter/material.dart';

import '../../../theme/bergen_tokens.dart';

/// The "Angre" pill (design `.angre`): a message with an undo action that
/// stays for [BergenTokens.motionUndo]. Built on [ScaffoldMessenger] so it
/// behaves like every other snackbar (one at a time, swipe to dismiss).
class BergenUndoPill extends StatelessWidget {
  const BergenUndoPill({
    super.key,
    required this.message,
    required this.onUndo,
    this.undoLabel = label,
  });

  static const String label = 'Angre';

  final String message;
  final VoidCallback onUndo;
  final String undoLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        decoration: BoxDecoration(
          color: BergenTokens.tealNight.withValues(alpha: .96),
          borderRadius: BorderRadius.circular(BergenTokens.radiusChip),
          border: Border.all(color: BergenTokens.glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: BergenTokens.text(
                  BergenTokens.textSmall,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: onUndo,
              style: TextButton.styleFrom(
                foregroundColor: BergenTokens.orangeLight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                shape: const StadiumBorder(),
                textStyle: BergenTokens.display(
                  BergenTokens.textSmall,
                  weight: FontWeight.w800,
                ),
              ),
              child: Text(undoLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Show the undo pill. [onUndo] runs at most once and closes the pill.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showBergenUndo(
  BuildContext context, {
  required String message,
  required VoidCallback onUndo,
  Duration? duration,
}) {
  final messenger = ScaffoldMessenger.of(context);
  var undone = false;

  return messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      duration: duration ?? BergenTokens.motionUndo,
      content: Center(
        child: BergenUndoPill(
          message: message,
          onUndo: () {
            if (undone) return;
            undone = true;
            messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.action);
            onUndo();
          },
        ),
      ),
    ),
  );
}
