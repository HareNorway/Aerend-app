import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'beacons.dart';

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
  // Customer Step 14: the AI-assistant surfaces.
  static const String aiLinking = 'cus.ai.linking';
  static const String aiDeviceAuth = 'cus.ai.device_auth';
  static const String aiIntents = 'cus.ai.intents';

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
  /// A per-version override from `agents/flags` wins over the surface flag.
  static bool on(String key) => _overrides[key] ?? _flags[key] ?? false;

  // Customer Step 16: the per-version answer (overrides, banner, min_version).
  static Map<String, bool> _overrides = const <String, bool>{};

  /// The last `agents/flags` answer: the shell's banner and the update prompt read it.
  static final ValueNotifier<CusClientFlags?> agents = ValueNotifier<CusClientFlags?>(null);

  static void applyAgents(CusClientFlags f) {
    _overrides = Map.of(f.flags);
    agents.value = f;
  }

  @visibleForTesting
  static void resetAgents() {
    _overrides = const <String, bool>{};
    agents.value = null;
  }

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
