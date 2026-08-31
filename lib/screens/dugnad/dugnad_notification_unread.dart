import 'package:flutter/foundation.dart';

import 'dugnad_repo.dart';

/// Shared unread count for the dugnad bell red-dot across home/profile.
class DugnadNotificationUnread {
  DugnadNotificationUnread._();

  static final ValueNotifier<int> count = ValueNotifier<int>(0);

  static bool get hasUnread => count.value > 0;

  static Future<void> refresh() async {
    try {
      final next = await DugnadRepo().getNotificationUnreadCount();
      count.value = next;
    } catch (_) {
      // Keep last known value.
    }
  }

  static void clearLocal() {
    count.value = 0;
  }
}
