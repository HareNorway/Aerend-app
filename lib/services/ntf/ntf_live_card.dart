import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:aerend_live_card/aerend_live_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../constant/constant.dart' show appUrlScheme;
import '../../networking/ops/cus_api.dart';
import '../../utils/shared_pref_utill.dart';

/// Notifications plan Step 10 (spec §4 «Live cards instead of pushes», §9) — the customer's order as one live card
/// on Android while it is on its way. It changes on the server's silent `ntf.live_card` pushes instead of new alerts
/// and goes away when the order is cancelled. Behind `ntf.live_card` (the card read says `enabled`). The iOS Live
/// Activity is a separate Mac step.
///
/// 2026-11-14 (manager): the card is the «Ærend Kunde Bergen» lock-screen design (Låseskjerm · leveringsstatus,
/// 23des) — drawn natively by `aerend_live_card`: Æ · ÆREND · the order's code · LIVE, the stage and its line, a
/// countdown to the time with «ankommer 14:55», the mint track with the four steps and the stage's Ægil, and
/// «Burger King → Nygårdsgaten 5 · Åpne». It is up from the moment the order is placed (Kjøp), keeps up from pushes
/// while the app is closed (the background handler), and ends on «Levert på døra» for a while. The delivery code is
/// never on it.
abstract final class NtfLiveCard {
  /// Default importance, silent: Android hides low («silent») notifications on the lock screen by default.
  static const channel = AndroidNotificationChannel('ntf_live_v2', 'Bestillingen din nå',
      description: 'Bestillingen som er på vei, på låseskjermen og oppdatert uten nye varsler.',
      importance: Importance.defaultImportance, playSound: false, enableVibration: false, showBadge: false);

  /// The first card's channel (low importance: hidden on the lock screen); removed at start.
  static const String oldChannelId = 'ntf_live';

  static const String aapneForKoden = 'Åpne for koden';

  /// How long «Levert på døra» stays before Android removes it.
  static const Duration ferdigVises = Duration(minutes: 20);

  /// Show / cancel the card; the plugin on Android (see [installAndroid]), a recorder in tests.
  static Future<void> Function(int id, Map<String, Object?> view)? show;
  static Future<void> Function(int id)? cancel;

  @visibleForTesting
  static CusApi Function() api = CusApi.new;

  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  static final Set<int> _shown = <int>{};

  @visibleForTesting
  static void reset() {
    _shown.clear();
    show = null;
    cancel = null;
    api = CusApi.new;
    now = DateTime.now;
  }

  /// The native card (any engine — also the one a push wakes while the app is closed).
  static void installAndroid() {
    if (kIsWeb || !Platform.isAndroid) return;
    show = (id, view) => AerendLiveCard.show(id, view);
    cancel = AerendLiveCard.cancel;
  }

  static int idFor(int orderId) => 70000 + orderId % 10000;

  /// The card's two plain lines (the notification's text for screen readers and old shades).
  static (String, String) text(Map<String, dynamic> card) {
    String s(String k) => '${card[k] ?? ''}'.trim();
    final eta = DateTime.tryParse(s('eta'))?.toLocal();
    final hm = eta == null ? '' : _hm(eta);
    final title = [s('stage_label'), if (hm.isNotEmpty) 'ca. $hm'].where((x) => x.isNotEmpty).join(' · ');
    final kode = card['open_for_code'] == true || s('open_for_code') == '1';
    final body = [s('who'), s('next_action'), if (kode) aapneForKoden].where((x) => x.isNotEmpty).join(' · ');
    return (title.isEmpty ? 'Bestillingen din' : title, body);
  }

  static String _hm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// The lock-screen card's view (design `lsVals` / `liveData`): every word decided here, Android only draws it.
  static Map<String, Object?> view(int orderId, Map<String, dynamic> card) {
    String s(String k) => '${card[k] ?? ''}'.trim();
    final naa = now();
    final state = s('state');
    final ferdig = state == 'delivered';
    final hent = s('mode') == 'pickup';
    final partner = s('actor') == 'partner';
    final stage = ferdig ? 3 : (int.tryParse(s('stage')) ?? 0).clamp(0, 3);
    final klar = hent && stage == 2;
    final store = s('store').isNotEmpty ? s('store') : (partner ? s('who') : '');
    final butikk = store.isEmpty ? 'Butikken' : store;
    final area = s('store_area');
    final adr = s('address');
    final first = s('first_name');
    final eta = DateTime.tryParse(s('eta'))?.toLocal();
    final levert = DateTime.tryParse(s('delivered_at'))?.toLocal() ?? naa;
    final igjen = eta?.difference(naa);

    final til = adr.isEmpty ? 'deg' : adr;
    final fram = partner ? '$butikk kjører til $til' : 'Ægil sykler til $til';
    final appetitt = first.isEmpty ? 'God appetitt!' : 'God appetitt, $first!';
    final tittel = (hent
        ? const ['Bestilling bekreftet', 'Maten lages', 'Klar for henting', 'Hentet']
        : ['Bestilling bekreftet', 'Maten lages', partner ? 'Maten er på vei' : 'Ægil er på vei', 'Levert på døra'])[stage];
    final hos = area.isEmpty ? butikk : '$butikk · $area';
    final kode = s('order_code');
    final sub = (hent
        ? ['$butikk har fått bestillingen', hos, kode.isEmpty ? 'Vis koden i disken' : 'Vis koden $kode i disken', appetitt]
        : ['$butikk har fått bestillingen', hos, fram, appetitt])[stage];

    // The track: each step's share of the bar, and how far into the step we are (design `lsP`).
    double inn;
    if (stage >= 3) {
      inn = 0;
    } else if (stage == 2 && igjen != null) {
      inn = (1 - igjen.inMinutes / 15).clamp(.1, .95);
    } else {
      inn = stage == 0 ? .35 : .5;
    }
    final progress = stage >= 3 ? 1.0 : ((stage + inn * .84) / 3).clamp(0.0, 1.0);

    final String timeText;
    final String timeSub;
    if (ferdig) {
      timeText = hent ? 'Hentet!' : 'Levert!';
      timeSub = '${hent ? 'hentet' : 'levert'} ${_hm(levert)}';
    } else if (klar) {
      timeText = 'Klar nå!';
      timeSub = 'i disken nå';
    } else {
      timeText = 'Snart!';
      timeSub = eta == null ? (hent ? 'klar snart' : 'ankommer snart') : '${hent ? 'klar' : 'ankommer'} ${_hm(eta)}';
    }
    final (plainTitle, plainBody) = (tittel, sub);

    return {
      'title': plainTitle,
      'sub': plainBody,
      'code': kode,
      'live': ferdig ? 'FERDIG' : 'LIVE',
      'eta_ms': (ferdig || klar || eta == null) ? null : eta.millisecondsSinceEpoch,
      'time_text': timeText,
      'time_sub': timeSub,
      'stage': stage,
      'progress': progress,
      'pickup': hent,
      'rider': partner ? 'van' : 'bike',
      'labels': hent ? const ['Bekreftet', 'Tilberedes', 'Klar', 'Hentet'] : const ['Bekreftet', 'Tilberedes', 'På vei', 'Levert'],
      'route': hent ? 'Henting · ${area.isEmpty ? butikk : '$butikk, $area'}' : '$butikk → $til',
      'open': 'Åpne',
      'link': '$appUrlScheme://bergen/sporing/$orderId',
      'ongoing': !ferdig,
      'timeout_ms': ferdig ? ferdigVises.inMilliseconds : null,
    };
  }

  static bool _live(Map<String, dynamic> card) => card['live'] == true || '${card['live'] ?? ''}' == '1';

  /// Kjøp (the order is placed) and Sporing (the customer follows it): read the card (which tells the server it is
  /// up) and show it while live.
  static Future<bool> start(int orderId) async {
    // Only where the app can show the card (Android): reading it tells the server the card is up and turns the
    // stage pushes into silent updates — on iOS (no Live Activity yet) the customer keeps the pushes.
    if (show == null) return false;
    final r = await api().liveCard(orderId).catchError((_) => null);
    if (r == null || !r.enabled) return false;
    return apply(orderId, r.card);
  }

  /// A card state (from the read or a silent push): shown while live, «Levert» when delivered, gone otherwise.
  static Future<bool> apply(int orderId, Map<String, dynamic> card) async {
    final id = idFor(orderId);
    final merged = <String, dynamic>{..._husket(orderId), ...card};
    if ('${merged['state'] ?? ''}' == 'delivered') {
      await show?.call(id, view(orderId, merged));
      _shown.remove(orderId);
      _glem(orderId);
      return false;
    }
    if (!_live(merged)) {
      // Cancelled or gone: always cancel (the engine a push woke does not know what was shown).
      await cancel?.call(id);
      _shown.remove(orderId);
      _glem(orderId);
      return false;
    }
    _husk(orderId, merged);
    await show?.call(id, view(orderId, merged));
    _shown.add(orderId);
    return true;
  }

  /// A silent `ntf.live_card` push (`object: order:<id>`).
  static Future<void> fromPush(Map<String, dynamic> d) async {
    final orderId = _ordre(d);
    if (orderId != null) await apply(orderId, d);
  }

  /// An ordinary order push (an alert, not a card update): delivered and cancelled end the card even when the app
  /// was closed; another stage push for a card that is up reads the card again.
  static Future<void> fromOrderPush(Map<String, dynamic> d) async {
    final type = '${d['type'] ?? ''}';
    if (!type.startsWith('customer.order.')) return;
    final orderId = _ordre(d);
    if (orderId == null || show == null) return;
    final husket = _husket(orderId);
    if (type == 'customer.order.cancelled') {
      await apply(orderId, const {'live': false, 'state': 'cancelled'});
    } else if (type == 'customer.order.delivered') {
      if (husket.isEmpty && !_shown.contains(orderId)) return;
      await apply(orderId, {'state': 'delivered', 'live': false, 'stage': 3, 'delivered_at': now().toUtc().toIso8601String()});
    } else if (husket.isNotEmpty) {
      await start(orderId);
    }
  }

  /// Any push (the background handler): a card update or an order push.
  static Future<void> onPush(Map<String, dynamic> d) =>
      '${d['kind'] ?? ''}' == 'ntf.live_card' ? fromPush(d) : fromOrderPush(d);

  /// The order is delivered (Sporing shows it): «Levert på døra» for a while; cancelled: gone.
  static Future<void> end(int orderId, {bool delivered = false}) async {
    if (delivered && (_shown.contains(orderId) || _husket(orderId).isNotEmpty)) {
      await apply(orderId, {'state': 'delivered', 'live': false, 'stage': 3});
      return;
    }
    if (_shown.remove(orderId)) await cancel?.call(idFor(orderId));
    _glem(orderId);
  }

  @visibleForTesting
  static bool isShown(int orderId) => _shown.contains(orderId);

  static int? _ordre(Map<String, dynamic> d) {
    final o = '${d['object'] ?? ''}';
    if (o.startsWith('order:')) return int.tryParse(o.substring(6));
    return int.tryParse('${d['order_id'] ?? ''}');
  }

  // The last card per order, so a push that carries no card (delivered) — or an engine that never saw the card —
  // can still draw it.
  static const String _prefKey = 'ntf_live_card_v1';

  static Map<String, dynamic> _alle() {
    try {
      final raw = prefGetString(_prefKey);
      return raw.isEmpty ? <String, dynamic>{} : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static Map<String, dynamic> _husket(int orderId) {
    final v = _alle()['$orderId'];
    return v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
  }

  static void _husk(int orderId, Map<String, dynamic> card) {
    try {
      final alle = _alle()..['$orderId'] = {for (final e in card.entries) if (e.value == null || e.value is String || e.value is num || e.value is bool) e.key: e.value};
      unawaited(prefSetString(_prefKey, jsonEncode(alle)));
    } catch (_) {}
  }

  static void _glem(int orderId) {
    try {
      final alle = _alle();
      if (alle.remove('$orderId') != null) unawaited(prefSetString(_prefKey, jsonEncode(alle)));
    } catch (_) {}
  }
}
