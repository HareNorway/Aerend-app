import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../networking/ops/cus_api.dart';

/// Notifications plan Step 10 (spec §4 «Live cards instead of pushes», §9) — the customer's order as one ongoing
/// Android notification while it is on its way: the stage, the ETA, the courier's first name (or the store), the
/// next step and «Åpne for koden» when a code is needed (the code itself is never on the card). It starts when the
/// customer follows the order (Sporing reads the card, which also tells the server the card is up), changes on the
/// server's silent `ntf.live_card` pushes instead of new alerts, and goes away when the order is delivered or
/// cancelled. Behind `ntf.live_card` (the card read says `enabled`). The iOS Live Activity is a separate Mac step.
abstract final class NtfLiveCard {
  static const channel = AndroidNotificationChannel('ntf_live', 'Bestillingen din nå',
      description: 'Bestillingen som er på vei, oppdatert uten nye varsler.', importance: Importance.low, playSound: false, showBadge: false);

  static const String aapneForKoden = 'Åpne for koden';

  /// Show / cancel the ongoing notification; the plugin in the app, a recorder in tests.
  static Future<void> Function(int id, String title, String body)? show;
  static Future<void> Function(int id)? cancel;

  @visibleForTesting
  static CusApi Function() api = CusApi.new;

  static final Set<int> _shown = <int>{};

  @visibleForTesting
  static void reset() {
    _shown.clear();
    show = null;
    cancel = null;
    api = CusApi.new;
  }

  static int idFor(int orderId) => 70000 + orderId % 10000;

  /// The card's two lines.
  static (String, String) text(Map<String, dynamic> card) {
    String s(String k) => '${card[k] ?? ''}'.trim();
    final eta = DateTime.tryParse(s('eta'))?.toLocal();
    final hm = eta == null ? '' : '${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}';
    final title = [s('stage_label'), if (hm.isNotEmpty) 'ca. $hm'].where((x) => x.isNotEmpty).join(' · ');
    final kode = card['open_for_code'] == true || s('open_for_code') == '1';
    final body = [s('who'), s('next_action'), if (kode) aapneForKoden].where((x) => x.isNotEmpty).join(' · ');
    return (title.isEmpty ? 'Bestillingen din' : title, body);
  }

  static bool _live(Map<String, dynamic> card) => card['live'] == true || '${card['live'] ?? ''}' == '1';

  /// Sporing follows [orderId]: read the card (which tells the server it is up) and show it while live.
  static Future<bool> start(int orderId) async {
    // Only where the app can show the card (Android): reading it tells the server the card is up and turns the
    // stage pushes into silent updates — on iOS (no Live Activity yet) the customer keeps the pushes.
    if (show == null) return false;
    final r = await api().liveCard(orderId).catchError((_) => null);
    if (r == null || !r.enabled) return false;
    return apply(orderId, r.card);
  }

  /// A card state (from the read or a silent push): shown while live, gone when not.
  static Future<bool> apply(int orderId, Map<String, dynamic> card) async {
    final id = idFor(orderId);
    if (!_live(card)) {
      if (_shown.remove(orderId)) await cancel?.call(id);
      return false;
    }
    final (t, b) = text(card);
    await show?.call(id, t, b);
    _shown.add(orderId);
    return true;
  }

  /// A silent `ntf.live_card` push (`object: order:<id>`).
  static Future<void> fromPush(Map<String, dynamic> d) async {
    final o = '${d['object'] ?? ''}';
    final orderId = o.startsWith('order:') ? int.tryParse(o.substring(6)) : null;
    if (orderId != null) await apply(orderId, d);
  }

  /// The order is delivered or cancelled.
  static Future<void> end(int orderId) async {
    if (_shown.remove(orderId)) await cancel?.call(idFor(orderId));
  }

  @visibleForTesting
  static bool isShown(int orderId) => _shown.contains(orderId);
}
