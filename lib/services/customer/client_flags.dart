import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../networking/api_base_helper.dart';
import '../../networking/api_constant.dart';
import '../../networking/ops/ops_customer_api.dart';
import '../../utils/shared_pref_utill.dart';

/// Customer plan Step 11: the `cus.*` surface flags the app renders on, from
/// `GET /api/customer/flags` (public). Read once at launch and kept in prefs,
/// so a screen reads a flag without a round-trip and the last answer serves
/// offline. Step 16 adds the per-version flags, banner and `min_version`
/// (`GET /api/agents/flags`) beside it.
abstract final class ClientFlags {
  static const String _pref = 'cus_client_flags';
  static const String feedDisclosure = 'cus.feed.disclosure';

  static Map<String, bool>? _cache;

  /// Tests set the flags directly.
  @visibleForTesting
  static set flags(Map<String, bool> v) => _cache = Map.of(v);

  static Map<String, bool> get _flags {
    final c = _cache;
    if (c != null) return c;
    try {
      final raw = prefGetString(_pref);
      final j = raw.isEmpty ? null : jsonDecode(raw);
      _cache = j is Map ? {for (final e in j.entries) '${e.key}': e.value == true} : <String, bool>{};
    } catch (_) {
      _cache = <String, bool>{};
    }
    return _cache!;
  }

  /// The flag's last known state; false until the server has answered once.
  static bool on(String key) => _flags[key] ?? false;

  /// Reads the flags; silent on any failure (the last answer stays).
  static Future<void> refresh({ApiBaseHelper? helper}) async {
    if (!OpsCustomerApi.networkEnabled) return;
    try {
      final json = await (helper ?? ApiBaseHelper(baseUrl: BaseUrl.domain)).get('api/customer/flags');
      final f = json is Map ? json['flags'] : null;
      if (f is! Map) return;
      final next = {for (final e in f.entries) '${e.key}': e.value == true};
      _cache = next;
      prefSetString(_pref, jsonEncode(next));
    } catch (_) {
      // Offline or the server is older: the last answer stays.
    }
  }
}
