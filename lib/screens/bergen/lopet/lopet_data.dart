import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../../../networking/api_constant.dart';
import '../../../networking/api_base_helper.dart';
import '../../../networking/ops/ops_customer_api.dart';
import '../../../utils/shared_pref_utill.dart';
import '../kit/bergen_routes.dart';

/// Points plan Step 7 (game spec §10.2, §3, §7, §8): what the app knows about Fjordløpet — the session for an order
/// (`GET /game/state`), the runs played on this phone (kept locally until Step 8 submits them), the entry switch
/// (Fjordløpet while a session is open, Fjordfiske otherwise) and the signals that pause a run.

int _i(Object? v, [int d = 0]) => v is int ? v : (v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? d);

/// `GET /game/state?order_id=` — one order's session, this week's course and everything the start screen shows.
class LopetState {
  LopetState({
    required this.sessionId,
    required this.orderId,
    required this.state,
    required this.runsAllowed,
    required this.runsLeft,
    required this.bonusGranted,
    required this.perk,
    required this.tokens,
    this.fullMeterToken,
    required this.course,
    required this.courseId,
    required this.week,
    required this.personalBestM,
    required this.weekBestM,
    required this.losgrad,
    required this.levelName,
    required this.boat,
    this.boatName,
    required this.rewards,
    required this.delivery,
    required this.vilkaar,
    required this.soundOn,
  });

  final int sessionId;
  final int orderId;

  /// open | no_new_run
  final String state;
  final int runsAllowed;
  final int runsLeft;
  final bool bonusGranted;

  /// none | vest
  final String perk;
  final List<String> tokens;

  /// Fjordløpet v1.3 plan Step 3 (D2): the token whose run starts with a full meter (Gull/Platina, the order's first
  /// run), or null.
  final String? fullMeterToken;
  final Map<String, dynamic> course;
  final int courseId;
  final String week;
  final int? personalBestM;
  final int? weekBestM;
  final String losgrad;
  final String levelName;

  /// robaat | vimpel | snekke | egen
  final String boat;

  /// Points plan Step 13: the Platina boat's approved name, or null.
  final String? boatName;
  final Map<String, dynamic> rewards;
  final Map<String, dynamic> delivery;
  final List<String> vilkaar;
  final bool soundOn;

  bool get noNewRun => state == 'no_new_run' || delivery['no_new_run'] == true;
  List<int> get milestones => [for (final m in ((rewards['milestones_m'] as List?) ?? const [])) _i(m)];

  static LopetState? fromJson(Map<String, dynamic> j) {
    final s = j['session'];
    final c = j['course'];
    if (s is! Map || c is! Map) return null;
    final l = (j['losgrad'] as Map?) ?? const {};
    final lv = (j['level'] as Map?) ?? const {};
    return LopetState(
      sessionId: _i(s['id']),
      orderId: _i(s['order_id']),
      state: '${s['state'] ?? 'open'}',
      runsAllowed: _i(s['runs_allowed']),
      runsLeft: _i(s['runs_left']),
      bonusGranted: s['bonus_granted'] == true,
      perk: '${s['perk'] ?? 'none'}',
      tokens: [for (final t in ((s['tokens'] as List?) ?? const [])) '$t'],
      fullMeterToken: s['full_meter_token'] as String?,
      course: Map<String, dynamic>.from(c),
      courseId: _i(c['id']),
      week: '${c['week'] ?? ''}',
      personalBestM: j['personal_best_m'] == null ? null : _i(j['personal_best_m']),
      weekBestM: j['week_best_m'] == null ? null : _i(j['week_best_m']),
      losgrad: '${l['name'] ?? ''}',
      levelName: '${lv['name'] ?? ''}',
      boat: '${lv['boat'] ?? 'robaat'}',
      boatName: lv['boat_name'] as String?,
      rewards: Map<String, dynamic>.from((j['rewards'] as Map?) ?? const {}),
      delivery: Map<String, dynamic>.from((j['delivery'] as Map?) ?? const {}),
      vilkaar: [for (final v in ((j['vilkaar'] as List?) ?? const [])) '$v'],
      soundOn: ((j['profile'] as Map?)?['sound_on']) == true,
    );
  }

  /// What a run that reached [gates] is worth when the order is delivered (game spec §6.1): the highest threshold,
  /// not the sum; +personal best once; capped.
  int pointsFor(List<int> gates, {bool personalBest = false}) {
    final ms = milestones;
    final keys = ['buoy1', 'buoy2', 'quay'];
    var p = 0;
    for (var k = 0; k < ms.length && k < keys.length; k++) {
      if (gates.contains(ms[k])) p = _i(rewards[keys[k]]);
    }
    if (personalBest) p += _i(rewards['personal_best']);
    final cap = _i(rewards['cap'], 1 << 30);
    return p > cap ? cap : p;
  }
}

/// `api/game/*` with the customer auth of `/points/*`.
class LopetApi {
  LopetApi({ApiBaseHelper? helper}) : _helper = helper ?? ApiBaseHelper(baseUrl: BaseUrl.domain);

  final ApiBaseHelper _helper;

  /// Null when the window is not open (404 GAME_CLOSED), the game is off for this customer, or offline.
  Future<LopetState?> state(int orderId) async {
    final auth = OpsCustomerApi.authParams();
    if (auth == null || !OpsCustomerApi.networkEnabled) return null;
    try {
      final q = Uri(queryParameters: {...auth, 'order_id': '$orderId'}).query;
      final json = await _helper.get('api/game/state?$q');
      if (json is! Map<String, dynamic> || json['status'] != 1) return null;
      return LopetState.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> sound(bool on) async {
    final auth = OpsCustomerApi.authParams();
    if (auth == null) return;
    try {
      await _helper.post('api/game/profile?${Uri(queryParameters: auth).query}', body: {'sound_on': on ? 1 : 0});
    } catch (_) {}
  }
}

/// The runs played on this phone: the used tokens (a run is never played twice on one token, also after a restart)
/// and the outbox Step 8 submits; and the best distance per week, for «Din beste denne uken» and the chart.
class LopetLager {
  static const _brukt = 'lopet_brukte_tokens';
  static const _utboks = 'lopet_utboks';
  static const _beste = 'lopet_beste';

  static Set<String> brukte() {
    try {
      return {for (final t in (jsonDecode(prefGetString(_brukt)) as List)) '$t'};
    } catch (_) {
      return {};
    }
  }

  static List<Map<String, dynamic>> utboks() {
    try {
      return [for (final r in (jsonDecode(prefGetString(_utboks)) as List)) Map<String, dynamic>.from(r as Map)];
    } catch (_) {
      return [];
    }
  }

  static int? beste(String week) {
    try {
      final m = jsonDecode(prefGetString(_beste)) as Map;
      return m[week] == null ? null : _i(m[week]);
    } catch (_) {
      return null;
    }
  }

  /// The tokens of [s] not yet played here.
  static List<String> ledige(LopetState s) {
    final b = brukte();
    return [for (final t in s.tokens) if (!b.contains(t)) t];
  }

  /// Keep a finished run: its token is spent, it waits in the outbox, and the week's best moves.
  static Future<void> lagre({required String token, required LopetState s, required List<List<int>> inputs, required Map<String, dynamic> result, required int startedMs}) async {
    final b = brukte()..add(token);
    await prefSetString(_brukt, jsonEncode(b.toList()));
    final u = utboks()
      ..add({
        'token': token,
        'order_id': s.orderId,
        'course_id': s.courseId,
        'week': s.week,
        'engine_version': s.course['engine_version'],
        'inputs': inputs,
        'duration_ticks': result['ticks'],
        'distance_m': result['distance_m'],
        'crates': result['crates'],
        'near_misses': result['near_misses'],
        'vest_uses': result['vest_uses'],
        'started_client_ts': startedMs,
        'result': result,
      });
    await prefSetString(_utboks, jsonEncode(u));
    Map m;
    try {
      m = jsonDecode(prefGetString(_beste)) as Map;
    } catch (_) {
      m = {};
    }
    final d = _i(result['distance_m']);
    if (_i(m[s.week]) < d) m[s.week] = d;
    await prefSetString(_beste, jsonEncode(m));
  }
}

/// Why a run pauses by itself (game spec §7).
enum LopetSignal {
  /// arrived_customer / the courier at the door: the run ends and counts.
  vedDora,

  /// A card that needs an answer, a courier call or message, any CRITICAL notification.
  trengerDeg,
}

/// The pause signals from outside the game: the foreground push handler feeds them (`PushNotificationService`).
abstract final class LopetSignaler {
  static final StreamController<LopetSignal> _c = StreamController<LopetSignal>.broadcast();

  static Stream<LopetSignal> get stream => _c.stream;

  static void send(LopetSignal s) => _c.add(s);

  /// A foreground push: the courier at the door ends a run; a courier message or call, the code card, a choice or
  /// any CRITICAL notification pauses it.
  static void fraPush(Map<String, dynamic> data) {
    final type = '${data['type'] ?? data['ntf_type'] ?? data['kind'] ?? ''}';
    final cls = '${data['class'] ?? data['ntf_class'] ?? ''}'.toUpperCase();
    if (type == 'customer.order.at_door' || type.endsWith('arrived_customer')) {
      send(LopetSignal.vedDora);
    } else if (cls == 'CRITICAL' || type.contains('courier_message') || type.contains('code.required') || type.contains('delay_with_options') ||
        type.contains('issue_notice') || type.contains('call')) {
      send(LopetSignal.trengerDeg);
    }
  }
}

/// An order with an open Fjordløpet session.
class LopetInngang {
  const LopetInngang({required this.orderId, required this.runsLeft});

  final int orderId;
  final int runsLeft;
}

/// The entry switch (game spec §8, G7): while one of the customer's orders has an open session, every Fjordfiske
/// entry opens Fjordløpet; otherwise Fjordfiske, as today. Fjordløpet has no entry outside the window.
abstract final class LopetPort {
  /// The open session, if any (Hjem's and Utforsk's labels listen).
  static final ValueNotifier<LopetInngang?> status = ValueNotifier<LopetInngang?>(null);
  static DateTime? _sjekket;

  static const _aktive = {'seen', 'ready', 'picked_up'};

  /// From a tracking payload (Sporing): the order snapshot's `game { open, runs_left }`.
  static void fraSporing(int orderId, Object? game) {
    if (game is Map && game['open'] == true) {
      status.value = LopetInngang(orderId: orderId, runsLeft: _i(game['runs_left']));
    } else if (status.value?.orderId == orderId) {
      status.value = null;
    }
  }

  /// Look for an open session among the active orders (cached for 30 s).
  static Future<LopetInngang?> sjekk({OpsCustomerApi? api, bool tving = false}) async {
    final now = DateTime.now();
    if (!tving && _sjekket != null && now.difference(_sjekket!) < const Duration(seconds: 30)) return status.value;
    // Not signed in yet (a cold start): ask again next time rather than remembering «nothing».
    if (api == null && OpsCustomerApi.authParams() == null) return status.value;
    final a = api ?? OpsCustomerApi();
    try {
      final orders = await a.orders(limit: 8);
      for (final o in orders) {
        if (!_aktive.contains('${o['state'] ?? ''}')) continue;
        final id = _i(o['order_id'] ?? o['id']);
        if (id <= 0) continue;
        final t = await a.tracking(id);
        final g = t['game'];
        if (g is Map && g['open'] == true) {
          status.value = LopetInngang(orderId: id, runsLeft: _i(g['runs_left']));
          _sjekket = now;
          return status.value;
        }
      }
      _sjekket = now;
    } catch (_) {
      return status.value; // offline: keep what we knew, ask again next time
    }
    status.value = null;
    return null;
  }

  /// Open the game for [orderId] (Sporing knows it), or for the open session found, or Fjordfiske.
  static Future<void> apne(BuildContext context, {int? orderId, bool gameOpen = false}) async {
    var id = gameOpen ? orderId : null;
    id ??= (await sjekk())?.orderId;
    if (!context.mounted) return;
    if (id != null) {
      await BergenRoutes.push(context, '/bergen/lopet', arguments: {'order_id': '$id'});
    } else {
      await BergenRoutes.push(context, '/bergen/fjordfiske');
    }
  }
}
