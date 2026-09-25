import '../../networking/api_base_helper.dart';
import '../../utils/shared_pref_utill.dart';
import '../../utils/utils.dart';
import 'aegil_app_models.dart';
import 'suggestion_models.dart';

/// The Ægil screen's calls (agil-3 Phase 7): chat turns, the suggestion
/// tray by context, feedback on a suggestion, "Mens du var borte", the trust
/// ledger, C3 photo and C4 door. Same auth shape as [AegilRepo].
///
/// Screens take an [AegilAppApi] so tests can inject a fake; this class is
/// the network implementation.
abstract class AegilAppApi {
  Future<AegilTurn?> chat({String? text, String? intent, int? storeId});
  Future<List<Suggestion>> suggestions({String? context});
  Future<bool> add(int suggestionId);
  Future<bool> dismiss(int suggestionId);
  Future<bool> never(int suggestionId, String reasonCode);
  Future<List<AwayItem>> away();
  Future<TrustLedger?> trustLedger();
  Future<AegilTurn?> photoOrder(List<String> items);
  Future<String?> doorNote(String note);
}

class AegilAppRepo implements AegilAppApi {
  ApiBaseHelper get _api => ApiBaseHelper(baseUrl: ApiConst.baseAgentUrl);

  Map<String, dynamic> _auth() => {
    ApiParam.paramUserId: prefGetInt(prefUserId),
    ApiParam.paramAccessToken: prefGetString(prefAccessToken),
  };

  String _query(Map<String, dynamic> params) => Uri(
    queryParameters: params.map((k, v) => MapEntry(k, v?.toString() ?? '')),
  ).query;

  Map<String, dynamic>? _ok(dynamic response) {
    if (response is! Map) return null;
    final json = response.cast<String, dynamic>();
    return json['status'] == 1 ? json : null;
  }

  @override
  Future<AegilTurn?> chat({String? text, String? intent, int? storeId}) async {
    try {
      final json = _ok(await _api.post('chat', body: {
        ..._auth(),
        if (text != null) 'text': text,
        if (intent != null) 'intent': intent,
        if (storeId != null) 'store_id': storeId,
      }));
      return json == null ? null : AegilTurn.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Suggestion>> suggestions({String? context}) async {
    try {
      final json = _ok(await _api.get('me/suggestions?${_query({..._auth(), if (context != null) 'context': context})}'));
      if (json == null) return const [];
      return ((json['suggestions'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Suggestion.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<bool> add(int suggestionId) => _feedback('me/suggestions/$suggestionId/add');

  @override
  Future<bool> dismiss(int suggestionId) => _feedback('me/suggestions/$suggestionId/dismiss');

  @override
  Future<bool> never(int suggestionId, String reasonCode) => _feedback('me/suggestions/$suggestionId/never', {'reason_code': reasonCode});

  Future<bool> _feedback(String path, [Map<String, dynamic> extra = const {}]) async {
    try {
      return _ok(await _api.post(path, body: {..._auth(), ...extra})) != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<AwayItem>> away() async {
    try {
      final json = _ok(await _api.get('me/away?${_query(_auth())}'));
      if (json == null) return const [];
      return ((json['items'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => AwayItem.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<TrustLedger?> trustLedger() async {
    try {
      final json = _ok(await _api.get('me/trust-ledger?${_query(_auth())}'));
      final ledger = json?['ledger'];
      return ledger is Map ? TrustLedger.fromJson(ledger.cast<String, dynamic>()) : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AegilTurn?> photoOrder(List<String> items) async {
    try {
      final json = _ok(await _api.post('photo-order', body: {..._auth(), 'items': items}));
      return json == null ? null : AegilTurn.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> doorNote(String note) async {
    try {
      final json = _ok(await _api.post('door-note', body: {..._auth(), 'note': note}));
      return json?['courier_line'] as String?;
    } catch (_) {
      return null;
    }
  }
}
