import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notifications plan Step 7: what a push from the Varselsentral carries and where it goes.
///
/// The server sends every push with its class (`data.class`: critical | operational | insight) and, with
/// `ntf.payload_v2`, the matching Android channel. The app creates the same three channels so a push lands on the
/// right one even when it is shown locally (foreground), and only a CRITICAL push may take the screen.
abstract final class NtfChannels {
  static const critical = AndroidNotificationChannel(
    'ntf_critical',
    'Viktige varsler',
    description: 'Ordren din er fremme, avbestillinger og annet du må vite med en gang.',
    importance: Importance.max,
    playSound: true,
  );

  static const operational = AndroidNotificationChannel(
    'ntf_operational',
    'Bestillinger',
    description: 'Oppdateringer om bestillingene dine og svar fra butikken og budet.',
    importance: Importance.high,
    playSound: true,
  );

  static const insight = AndroidNotificationChannel(
    'ntf_insight',
    'Forslag og nyheter',
    description: 'Forslag fra Ægil, tilbud og nytt i byen. Kommer stille.',
    importance: Importance.low,
    playSound: false,
  );

  static const all = [critical, operational, insight];

  /// The channel for a push's class; an old push without a class goes to «Bestillinger» (the manifest default).
  static AndroidNotificationChannel forClass(String? cls) => switch (cls) {
    'critical' => critical,
    'insight' => insight,
    _ => operational,
  };

  /// Only a CRITICAL push may use a full-screen intent (plan §2, D-6).
  static bool fullScreen(String? cls) => cls == 'critical';

  static Importance importance(String? cls) => forClass(cls).importance;

  static Priority priority(String? cls) => switch (cls) {
    'critical' => Priority.max,
    'insight' => Priority.low,
    _ => Priority.high,
  };
}

/// The kinds of Varselsentral data pushes the app handles without showing anything.
abstract final class NtfPayload {
  /// Step 5: «refresh the bell» — data only, the unread count in `unread`.
  static bool isBadge(Map<String, dynamic> d) => '${d['kind'] ?? ''}' == 'ntf.badge';

  /// Step 4 (context): the person is on the screen the notification is about — an in-app toast, not an alert.
  static bool isToast(Map<String, dynamic> d) => '${d['toast'] ?? ''}' == '1';

  /// A live-card update (Step 10): the ongoing notification changes, nothing new is shown.
  static bool isLiveCard(Map<String, dynamic> d) => '${d['kind'] ?? ''}' == 'ntf.live_card';

  static int? unread(Map<String, dynamic> d) => int.tryParse('${d['unread'] ?? ''}');

  /// The `ops_notifications` id the outcome route takes.
  static int? notificationId(Map<String, dynamic> d) => int.tryParse('${d['notification_id'] ?? ''}');

  static String? cls(Map<String, dynamic> d) {
    final c = '${d['class'] ?? ''}';
    return c.isEmpty ? null : c;
  }
}

/// Routing by the server's `route` and `type` first (plan Step 7); null leaves it to today's fallbacks
/// (`PushDeepLink`, `notification_type`, the chat).
abstract final class NtfRouting {
  static String? route(Map<String, dynamic> d) {
    final r = '${d['route'] ?? ''}'.trim();
    if (r.startsWith('/bergen/')) return r;
    final type = '${d['type'] ?? ''}';
    final orderId = int.tryParse('${d['order_id'] ?? ''}');
    if (type.startsWith('customer.order.') && orderId != null && orderId > 0) return '/bergen/sporing/$orderId';
    if ((type == 'customer.courier_message' || type == 'customer.store_answer') && orderId != null && orderId > 0) return '/bergen/sporing/$orderId';
    // Ægil, campaigns and broadcasts carry their own `aerend://` link: PushDeepLink routes them.
    return null;
  }
}
