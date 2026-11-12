import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../networking/ops/cus_api.dart';
import '../../screens/bergen/hjem/hjem_varsler.dart';
import '../../utils/utils.dart' show navigatorKey;
import 'ntf_push.dart';

/// Notifications plan Step 7: what the customer app does with the Varselsentral's pushes beyond showing them —
/// report the token and the outcome, refresh the bell on a badge push, show a toast instead of an alert, and update a
/// live card. Static and fire-and-forget (never awaited by the caller, never throws); tests swap [api].
abstract final class NtfHooks {
  @visibleForTesting
  static CusApi Function() api = CusApi.new;

  /// A live-card update (Step 10); null until the live card is wired.
  static Future<void> Function(Map<String, dynamic> data)? onLiveCard;

  /// The toasts shown (tests read it).
  @visibleForTesting
  static final List<String> toasts = [];

  /// A data push that shows nothing on its own: true when handled.
  static Future<bool> handleData(Map<String, dynamic> d) async {
    if (NtfPayload.isBadge(d)) {
      unawaited(HjemVarsler.oppdater());
      return true;
    }
    if (NtfPayload.isLiveCard(d)) {
      if (onLiveCard case final f?) await f(d);
      return true;
    }
    if (NtfPayload.isToast(d)) return toast(d);
    return false;
  }

  /// The person is on the screen this is about: a SnackBar instead of a system notification.
  static bool toast(Map<String, dynamic> d) {
    final title = '${d['title'] ?? ''}'.trim();
    final body = '${d['message'] ?? d['body'] ?? ''}'.trim();
    final text = [title, body].where((s) => s.isNotEmpty).join(' · ');
    if (text.isEmpty) return true;
    toasts.add(text);
    final ctx = navigatorKey.currentContext;
    final m = ctx == null ? null : ScaffoldMessenger.maybeOf(ctx);
    if (m == null) return false;
    m.showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 4)));
    return true;
  }

  static void reportToken(String token) {
    try {
      unawaited(api().pushToken(token, platform: Platform.isIOS ? 'ios' : 'android').catchError((_) => false));
    } catch (_) {}
  }

  /// «opened» for a tapped push that carries its notification id.
  static bool reportOpened(Map<String, dynamic> d) {
    final id = NtfPayload.notificationId(d);
    if (id == null) return false;
    try {
      unawaited(api().varselUtfall(id, 'opened').catchError((_) => false));
    } catch (_) {}
    return true;
  }
}
