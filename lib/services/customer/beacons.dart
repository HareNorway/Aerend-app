import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import '../../networking/api_constant.dart';
import '../../utils/shared_pref_utill.dart';
import 'client_flags.dart';

/// Customer plan Step 16: the client beacons and the per-version flags of the
/// Agents plan's health module (MERGE-CONTRACT §5: `POST /api/agents/client_events`,
/// `GET /api/agents/flags?app=customer&version=`).
///
/// A beacon is a technical event, never personal data: a class, the endpoint
/// *template* and status when there is one, a short machine-readable code and
/// a stack hash. Beacons queue from the first frame, are sent only once the
/// customer is logged in (signed with `user_id` + `access_token`), batched
/// every minute and on pause, rate-limited per class and in total, and
/// dropped (counted) when the queue is full. A 404 from the server switches
/// the module off for this run; the app behaves exactly as without it.
class CusBeacon {
  CusBeacon({required this.cls, required this.at, this.endpoint, this.status, this.code, this.screen, this.data = const <String, Object?>{}});

  /// `uncaught_error` | `api_failed` | `timeout` | `payment_failed` |
  /// `stuck_screen` | `feed_degraded`.
  final String cls;
  final DateTime at;
  final String? endpoint;
  final int? status;
  final String? code;
  final String? screen;
  final Map<String, Object?> data;

  /// The cluster key the server groups by (class + endpoint + code), hashed.
  String get stackHash => hash('$cls|${endpoint ?? ''}|${code ?? ''}');

  Map<String, Object?> toJson() => <String, Object?>{
        'class': cls,
        'at': at.toUtc().toIso8601String(),
        if (endpoint != null) 'endpoint': endpoint,
        if (status != null) 'status': status,
        if (code != null) 'code': code,
        if (screen != null) 'screen': screen,
        'stack_hash': stackHash,
        if (data.isNotEmpty) 'data': data,
      };

  /// FNV-1a, 32 bit: short, stable, not reversible to a readable value.
  static String hash(String s) {
    var h = 0x811c9dc5;
    for (final c in utf8.encode(s)) {
      h = ((h ^ c) * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  /// The endpoint as a template: no host, no query, every number an `{id}`,
  /// public ids (`q_…`, `cart_…`, `ÆR-…`) a `{key}`.
  static String template(String url) {
    var p = url;
    final i = p.indexOf('://');
    if (i >= 0) {
      final rest = p.substring(i + 3);
      final slash = rest.indexOf('/');
      p = slash >= 0 ? rest.substring(slash) : '/';
    }
    p = p.split('?').first;
    p = p.replaceAll(RegExp(r'/\d+(?=/|$)'), '/{id}');
    p = p.replaceAll(RegExp(r'/(q|cart|as|cat|crt|ÆR)[_-][A-Za-z0-9]+(?=/|$)'), '/{key}');
    return p.length > 120 ? p.substring(0, 120) : p;
  }

  /// True for the agent and commerce endpoints (their timeouts are a class of their own).
  static bool agentOrCommerce(String template) =>
      template.startsWith('/api/agent/') || template.startsWith('/api/customer/') || template.startsWith('/api/ops/customer/') || template.startsWith('/api/points/');
}

/// What `agents/flags` answers for this app version: flag overrides, the
/// server banner and `min_version`.
class CusClientFlags {
  const CusClientFlags({this.flags = const <String, bool>{}, this.bannerNo, this.bannerEn, this.bannerLevel = 'info', this.minVersion, this.updateRequired = false});

  factory CusClientFlags.fromJson(Map<String, dynamic> j) {
    final f = j['flags'] is Map ? Map<String, dynamic>.from(j['flags'] as Map) : <String, dynamic>{};
    final b = j['banner'] is Map ? Map<String, dynamic>.from(j['banner'] as Map) : <String, dynamic>{};
    String? s(dynamic v) => v == null || '$v'.trim().isEmpty ? null : '$v';
    return CusClientFlags(
      flags: f.map((k, v) => MapEntry<String, bool>(k, v == true)),
      bannerNo: s(b['no']),
      bannerEn: s(b['en']),
      bannerLevel: s(b['level']) ?? 'info',
      minVersion: s(j['min_version']),
      updateRequired: j['update_required'] == true,
    );
  }

  final Map<String, bool> flags;
  final String? bannerNo;
  final String? bannerEn;

  /// `info` | `warning` | `critical`.
  final String bannerLevel;
  final String? minVersion;
  final bool updateRequired;

  String? banner(String lang) => lang == 'en' ? (bannerEn ?? bannerNo) : (bannerNo ?? bannerEn);

  /// True when [version] is older than `min_version` (dotted numbers; build suffixes ignored).
  bool needsUpdate(String version) => updateRequired || (minVersion != null && compareVersions(version, minVersion!) < 0);

  static int compareVersions(String a, String b) {
    List<int> p(String v) => v.split('+').first.split('.').map((x) => int.tryParse(x.replaceAll(RegExp(r'\D'), '')) ?? 0).toList();
    final x = p(a), y = p(b);
    for (var i = 0; i < 3; i++) {
      final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
      if (d != 0) return d.sign;
    }
    return 0;
  }
}

/// The two calls, injected so tests need no server.
abstract class CusBeaconTransport {
  /// The HTTP status of the batch post (404 = endpoint not there).
  Future<int> send(Map<String, Object?> batch, {required String version});

  /// The flags for this version, or null when unreachable.
  Future<CusClientFlags?> flags({required String version});
}

class DioCusBeaconTransport implements CusBeaconTransport {
  DioCusBeaconTransport({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 5), receiveTimeout: const Duration(seconds: 8)));

  final Dio _dio;

  Options _opts(String version) => Options(
        headers: <String, dynamic>{'Accept': 'application/json', 'X-App': 'customer', 'X-App-Version': version},
        validateStatus: (s) => s != null,
      );

  @override
  Future<int> send(Map<String, Object?> batch, {required String version}) async {
    final r = await _dio.post<dynamic>('${BaseUrl.domain}api/agents/client_events', data: batch, options: _opts(version));
    return r.statusCode ?? 0;
  }

  @override
  Future<CusClientFlags?> flags({required String version}) async {
    final r = await _dio.get<dynamic>('${BaseUrl.domain}api/agents/flags', queryParameters: <String, dynamic>{'app': 'customer', 'version': version}, options: _opts(version));
    if (r.statusCode != 200 || r.data is! Map) return null;
    return CusClientFlags.fromJson(Map<String, dynamic>.from(r.data as Map));
  }
}

class CusBeacons {
  CusBeacons({
    required this.transport,
    required this.version,
    this.platform = 'ios',
    this.locale = 'no',
    this.device = '',
    DateTime Function()? clock,
    this.maxQueue = 200,
    this.perClassPerMinute = 10,
    this.perMinute = 60,
    ({int userId, String token})? Function()? signer,
  })  : _clock = clock ?? DateTime.now,
        _signer = signer ?? _prefsSigner;

  /// The one instance the app's hooks report to (null in tests that do not set one).
  static CusBeacons? current;

  /// Report from anywhere (a no-op without an instance).
  static void melde(String cls, {String? endpoint, int? status, String? code, String? screen, Map<String, Object?> data = const <String, Object?>{}}) =>
      current?.report(cls, endpoint: endpoint, status: status, code: code, screen: screen, data: data);

  /// A failed Dio call from the API helpers: `timeout` on the agent and
  /// commerce endpoints, else `api_failed` with the endpoint template and
  /// status. Cancelled requests are not failures.
  static void onDio(DioException e) {
    final t = CusBeacon.template(e.requestOptions.uri.toString());
    final feed = e.requestOptions.uri.port == 3300 || e.requestOptions.uri.path.startsWith('/feed/');
    if (e.type == DioExceptionType.cancel) return;
    final timeout = e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.sendTimeout;
    if (feed) {
      melde('feed_degraded', endpoint: t, status: e.response?.statusCode, code: timeout ? 'timeout' : e.type.name);
      return;
    }
    if (timeout && CusBeacon.agentOrCommerce(t)) {
      melde('timeout', endpoint: t, code: e.type.name);
      return;
    }
    final s = e.response?.statusCode;
    // 4xx answers with a body are the API talking (a refusal), not a failure.
    if (s != null && s >= 400 && s < 500 && s != 408 && s != 429) return;
    melde('api_failed', endpoint: t, status: s, code: s == null ? e.type.name : null);
  }

  /// An uncaught error: the error's type and a hash of the first stack
  /// frames — never the message (it could carry a name or an address).
  static void uncaught(Object error, StackTrace? stack) {
    final frames = (stack?.toString() ?? '').split('\n').take(6).join('\n');
    melde('uncaught_error', code: error.runtimeType.toString().replaceAll(RegExp(r'[^A-Za-z0-9_.:-]'), ''), data: {'stack': CusBeacon.hash(frames)});
  }

  final CusBeaconTransport transport;
  final String version;
  final String platform;
  final String locale;

  /// A hash of the device uid (never the uid itself).
  final String device;
  final DateTime Function() _clock;
  final ({int userId, String token})? Function() _signer;
  final int maxQueue;
  final int perClassPerMinute;
  final int perMinute;

  final List<CusBeacon> _queue = <CusBeacon>[];
  final Map<String, List<DateTime>> _recent = <String, List<DateTime>>{};
  int dropped = 0;

  /// True once the server said 404: nothing more is sent this run.
  bool disabled = false;
  Timer? _timer;

  List<CusBeacon> get queued => List<CusBeacon>.unmodifiable(_queue);

  static ({int userId, String token})? _prefsSigner() {
    final id = prefGetInt(prefUserId);
    final token = prefGetString(prefAccessToken);
    if (id <= 0 || token.isEmpty || prefGetInt(prefUserVerified) != 1) return null;
    return (userId: id, token: token);
  }

  void start({Duration every = const Duration(seconds: 60)}) {
    _timer?.cancel();
    _timer = Timer.periodic(every, (_) => flush());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Queue one beacon unless the class or the total is over its rate.
  void report(String cls, {String? endpoint, int? status, String? code, String? screen, Map<String, Object?> data = const <String, Object?>{}}) {
    if (disabled) return;
    final now = _clock();
    final cut = now.subtract(const Duration(minutes: 1));
    final klasse = (_recent[cls] ??= <DateTime>[])..removeWhere((t) => t.isBefore(cut));
    final total = _recent.values.fold<int>(0, (s, l) => s + l.where((t) => !t.isBefore(cut)).length);
    if (klasse.length >= perClassPerMinute || total >= perMinute) {
      dropped++;
      return;
    }
    klasse.add(now);
    if (_queue.length >= maxQueue) {
      _queue.removeAt(0);
      dropped++;
    }
    _queue.add(CusBeacon(cls: cls, at: now, endpoint: endpoint, status: status, code: code, screen: screen, data: data));
  }

  /// Send the batch, signed — only once the customer is logged in. 404 → off
  /// for this run; any other failure keeps the queue.
  Future<void> flush() async {
    if (disabled || (_queue.isEmpty && dropped == 0)) return;
    final sign = _signer();
    if (sign == null) return;
    final batch = List<CusBeacon>.of(_queue);
    try {
      final s = await transport.send(<String, Object?>{
        'app': 'customer',
        'version': version,
        'platform': platform,
        'locale': locale,
        'device': device,
        'dropped': dropped,
        'user_id': sign.userId,
        'access_token': sign.token,
        'events': <Map<String, Object?>>[for (final b in batch) b.toJson()],
      }, version: version);
      if (s == 404) {
        disabled = true;
        _queue.clear();
        return;
      }
      if (s >= 200 && s < 300) {
        _queue.removeRange(0, batch.length.clamp(0, _queue.length));
        dropped = 0;
      }
    } catch (_) {
      // Offline: the batch waits for the next flush.
    }
  }

  /// At launch and on resume: the flags, banner and min_version for this
  /// version, into [ClientFlags.agents] (and the overrides into the flags).
  Future<void> loadFlags() async {
    try {
      final f = await transport.flags(version: version);
      if (f != null) ClientFlags.applyAgents(f);
    } catch (_) {
      // Unreachable: keep what we had.
    }
  }

  void dispose() => stop();
}

/// A screen that shows a loader longer than 20 s is «stuck»: one beacon with
/// the screen's name. [stop] in the screen's dispose and when the loader
/// goes away.
class CusStuckWatch {
  CusStuckWatch(this.screen, {this.after = const Duration(seconds: 20)});

  final String screen;
  final Duration after;
  Timer? _t;

  void start() {
    _t?.cancel();
    _t = Timer(after, () => CusBeacons.melde('stuck_screen', screen: screen));
  }

  void stop() {
    _t?.cancel();
    _t = null;
  }
}
