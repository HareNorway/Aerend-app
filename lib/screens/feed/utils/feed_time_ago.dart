import 'package:flutter/widgets.dart';

/// Short relative time labels for feed posts (no new ARB keys in 7b).
String feedTimeAgo(DateTime? dt, BuildContext context) {
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.isNegative || diff.inSeconds < 60) {
    return 'just now';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}h';
  }
  if (diff.inDays < 30) {
    return '${diff.inDays}d';
  }
  final months = (diff.inDays / 30).floor();
  return months <= 1 ? '1mo' : '${months}mo';
}
