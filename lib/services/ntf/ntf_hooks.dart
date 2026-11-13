import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../networking/ops/cus_api.dart';
import '../../screens/bergen/hjem/hjem_varsler.dart';
import '../../utils/shared_pref_utill.dart' show prefGetString, prefSetString;
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
    unawaited(reportPermission());
  }

  /// Step 13: is the OS notification permission on? null = not asked yet (nothing is reported). Tests swap it.
  @visibleForTesting
  static Future<bool?> Function() permissionEnabled = _osPermission;

  /// This install's own id (kept in prefs; not the push token, which changes). Tests swap it.
  @visibleForTesting
  static Future<String> Function() installId = _installId;

  static Future<bool?> _osPermission() async {
    final s = await FirebaseMessaging.instance.getNotificationSettings();
    return switch (s.authorizationStatus) {
      AuthorizationStatus.authorized || AuthorizationStatus.provisional => true,
      AuthorizationStatus.denied => false,
      _ => null,
    };
  }

  static Future<String> _installId() async {
    var id = prefGetString(_installKey);
    if (id.isEmpty) {
      final r = Random.secure();
      id = List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      await prefSetString(_installKey, id);
    }
    return id;
  }

  static const _installKey = 'ntf_install_id';

  /// Step 13 (spec §11): the permission state to the server, at start (with the token) — the opt-out metric. True when
  /// a report went off.
  static Future<bool> reportPermission() async {
    try {
      final on = await permissionEnabled();
      if (on == null) return false;
      return await api().varselTillatelse(on, await installId(), platform: Platform.isIOS ? 'ios' : 'android');
    } catch (_) {
      return false;
    }
  }

  /// Step 13: «Færre slike» pressed on an INSIGHT push (Android action): the outcome, and a short confirmation.
  static bool reportLess(Map<String, dynamic> d) {
    final id = NtfPayload.notificationId(d);
    if (id == null) return false;
    try {
      unawaited(api().varselUtfall(id, 'less').catchError((_) => false));
    } catch (_) {}
    try {
      final ctx = navigatorKey.currentContext;
      final m = ctx == null ? null : ScaffoldMessenger.maybeOf(ctx);
      m?.showSnackBar(const SnackBar(content: Text(VarslerCopy.faerreSlikeOk), duration: Duration(seconds: 3)));
    } catch (_) {}
    return true;
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
