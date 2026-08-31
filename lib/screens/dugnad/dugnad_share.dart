import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Share text via the system sheet.
///
/// iOS (especially iPad) requires [ShareParams.sharePositionOrigin] for the
/// popover anchor. Without it, `Share.share` can no-op or throw — which is why
/// dugnad share buttons appeared broken on iPhone/iPad while Android worked.
Future<ShareResult> shareDugnadText(
  BuildContext context, {
  required String text,
  String? subject,
}) {
  return Share.share(
    text,
    subject: subject,
    sharePositionOrigin: _shareOrigin(context),
  );
}

Rect _shareOrigin(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
    return box.localToGlobal(Offset.zero) & box.size;
  }
  // Safe fallback when the widget isn't laid out yet: a tiny rect under the
  // status bar. UIActivityViewController still needs a non-zero origin.
  final size = MediaQuery.sizeOf(context);
  final top = MediaQuery.paddingOf(context).top + 12;
  return Rect.fromLTWH(size.width / 2 - 1, top, 2, 2);
}
