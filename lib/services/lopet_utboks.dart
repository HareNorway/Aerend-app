import 'dart:convert';

import '../networking/api_base_helper.dart';
import '../networking/ops/ops_customer_api.dart';
import '../utils/shared_pref_utill.dart';

/// Points plan Step 8 (game spec §10.2, §12, T12): Fjordløpet's outbox. A finished run waits on the phone (LopetLager
/// writes it) until `POST /api/game/runs` answers. A 200 or any 422 (RUN_TOKEN_USED, RUN_REJECTED, SESSION_CLOSED, …)
/// takes it out — the server has decided; a network failure keeps it for the next try (the game screen, Sporing and
/// app start send). Runs are never lost and never sent twice for points: the token is single-use on the server.
abstract final class LopetUtboks {
  static const _nokkel = 'lopet_utboks';

  /// Called with each server answer (tests, the game screen's «+N poeng»).
  static void Function(Map<String, dynamic> run, Map<String, dynamic>? svar)? onSvar;

  static bool _sender = false;
  static bool _igjen = false;

  static List<Map<String, dynamic>> _les() {
    try {
      return [for (final r in (jsonDecode(prefGetString(_nokkel)) as List)) Map<String, dynamic>.from(r as Map)];
    } catch (_) {
      return [];
    }
  }

  /// Send what is waiting. Returns how many left the outbox.
  static Future<int> send({ApiBaseHelper? helper}) async {
    // A send already under way: it goes once more when done, so a run finished meanwhile is not left waiting.
    if (_sender) {
      _igjen = true;
      return 0;
    }
    final auth = OpsCustomerApi.authParams();
    if (auth == null || !OpsCustomerApi.networkEnabled) return 0;
    _sender = true;
    var sendt = 0;
    try {
      final h = helper ?? ApiBaseHelper(baseUrl: BaseUrl.domain);
      for (final run in _les()) {
        ApiClientResult r;
        try {
          r = await h.postAllowClientError('api/game/runs?${Uri(queryParameters: auth).query}', body: {
            'token': run['token'],
            'course_id': run['course_id'],
            'engine_version': run['engine_version'],
            'inputs': run['inputs'],
            'duration_ticks': run['duration_ticks'],
            'distance_m': run['distance_m'],
            'crates': run['crates'],
            // Fjordløpet v1.3 plan Step 3: the engine v2 result is replayed field by field.
            'near_misses': run['near_misses'],
            'vest_uses': run['vest_uses'],
            'started_client_ts': run['started_client_ts'],
            if (run['perf'] != null) 'perf': run['perf'],
            if (run['app_version'] != null) 'app_version': run['app_version'],
            if (run['device_model'] != null) 'device_model': run['device_model'],
          });
        } catch (_) {
          break; // offline: keep the rest for the next try
        }
        if (r.statusCode == 200 || r.statusCode == 422) {
          final ny = _les()..removeWhere((x) => x['token'] == run['token']);
          await prefSetString(_nokkel, jsonEncode(ny));
          sendt++;
          onSvar?.call(run, r.data is Map ? Map<String, dynamic>.from(r.data as Map) : null);
        } else {
          break;
        }
      }
    } finally {
      _sender = false;
    }
    if (_igjen) {
      _igjen = false;
      sendt += await send(helper: helper);
    }
    return sendt;
  }
}
