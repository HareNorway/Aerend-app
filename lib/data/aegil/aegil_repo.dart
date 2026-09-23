import '../../networking/api_base_helper.dart';
import '../../utils/shared_pref_utill.dart';
import '../../utils/utils.dart';
import 'aegil_models.dart';

/// Networking for the customer's own Ægil (`/api/agent/me/*`).
///
/// Like PointsRepo, the helper is built per call from [ApiConst.baseAgentUrl] so the dev-env
/// base-URL override keeps working.
class AegilRepo {
  ApiBaseHelper get _api => ApiBaseHelper(baseUrl: ApiConst.baseAgentUrl);

  Map<String, dynamic> _auth() => {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
      };

  String _query(Map<String, dynamic> params) => Uri(
        queryParameters: params.map((k, v) => MapEntry(k, v?.toString() ?? '')),
      ).query;

  Future<({AegilSettings? settings, List<AegilLevel> levels})> fetchSettings() async {
    final response = await _api.get('me/settings?${_query(_auth())}');
    final json = _ok(response);

    if (json == null) return (settings: null, levels: const <AegilLevel>[]);

    return (
      settings: AegilSettings.fromJson(
          (json['settings'] as Map).cast<String, dynamic>()),
      levels: ((json['levels'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => AegilLevel.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  /// Returns the updated settings, or the backend's error code —
  /// LEVEL_REQUIRES_RECURRING when level 4 is asked for without a Vipps agreement.
  Future<({AegilSettings? settings, String? error})> updateSettings(
    Map<String, dynamic> changes,
  ) async {
    try {
      final response = await _api.post('me/settings', body: {
        ..._auth(),
        ...changes,
        // The route is a PATCH; the rest of this app posts, so the method is overridden
        // rather than introducing a second transport style.
        '_method': 'PATCH',
      });

      final json = _ok(response);
      if (json == null) return (settings: null, error: _message(response));

      return (
        settings: AegilSettings.fromJson(
            (json['settings'] as Map).cast<String, dynamic>()),
        error: null,
      );
    } catch (e) {
      return (settings: null, error: e.toString());
    }
  }

  Future<List<MemoryEntry>> fetchMemory() async {
    final response = await _api.get('me/memory?${_query(_auth())}');
    final json = _ok(response);
    if (json == null) return const [];

    return ((json['memory'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => MemoryEntry.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// Everything Ægil has learned, gone.
  Future<bool> forgetAll() async {
    final response = await _api.post('me/memory', body: {
      ..._auth(),
      '_method': 'DELETE',
    });

    return _ok(response) != null;
  }

  /// The onboarding chip batch. Every chip is an explicit choice, which is the only way an
  /// allergen or diet can be recorded at all.
  Future<({int stored, String? error})> submitChips(List<OnboardingChip> chips) async {
    try {
      final response = await _api.post('me/preferences/batch', body: {
        ..._auth(),
        'chips': chips.map((c) => c.toJson()).toList(),
      });

      final json = _ok(response);
      if (json == null) return (stored: 0, error: _message(response));

      return (stored: (json['stored'] as num?)?.toInt() ?? 0, error: null);
    } catch (e) {
      return (stored: 0, error: e.toString());
    }
  }

  Map<String, dynamic>? _ok(dynamic response) {
    if (response is! Map) return null;
    final json = response.cast<String, dynamic>();

    return json['status'] == 1 ? json : null;
  }

  String? _message(dynamic response) =>
      response is Map ? response['message'] as String? : null;
}
