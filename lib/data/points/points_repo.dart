import '../../networking/api_base_helper.dart';
import '../../utils/shared_pref_utill.dart';
import '../../utils/utils.dart';
import 'points_models.dart';

/// Networking for Points v2 (AGIL-2).
///
/// The Points endpoints live at `/api/points/*`, not under `/api/customer/`, so this builds
/// its own [ApiBaseHelper] per call from [ApiConst.basePointsUrl]. Constructing it at call
/// time rather than once in a field is deliberate: it keeps the dev-env base-URL override
/// working, which a cached fixed base would not.
class PointsRepo {
  ApiBaseHelper get _api => ApiBaseHelper(baseUrl: ApiConst.basePointsUrl);

  /// The house auth handshake, same as every other customer endpoint.
  Map<String, dynamic> _auth() => {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
      };

  String _query(Map<String, dynamic> params) => Uri(
        queryParameters:
            params.map((k, v) => MapEntry(k, v?.toString() ?? '')),
      ).query;

  /// The "Meg" balance strip and Nivå card.
  Future<PointsBalance?> fetchBalance() async {
    final response = await _api.get(
      '${ApiConst.endPointPointsMe}?${_query(_auth())}',
    );
    final json = _ok(response);

    return json == null ? null : PointsBalance.fromJson(json);
  }

  Future<List<LedgerEntry>> fetchLedger({int page = 1, int perPage = 30}) async {
    final response = await _api.get(
      '${ApiConst.endPointPointsLedger}?${_query({..._auth(), 'page': page, 'per_page': perPage})}',
    );
    final json = _ok(response);
    if (json == null) return const [];

    return ((json['ledger'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => LedgerEntry.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// Premiehylla: claimable prizes, blurred previews and the active goal.
  Future<Premiehylla?> fetchShelf() async {
    final response = await _api.get(
      '${ApiConst.endPointPointsPrizes}?${_query(_auth())}',
    );
    final json = _ok(response);

    return json == null ? null : Premiehylla.fromJson(json);
  }

  /// Returns the new claim, or the backend's error code (e.g. PRIZE_SOLD_OUT).
  Future<({PrizeClaim? claim, String? error})> claimPrize(
    int prizeId, {
    String? identityName,
    String? donationTarget,
  }) async {
    try {
      final response = await _api.post(
        '${ApiConst.endPointPointsPrizes}/$prizeId/claim',
        body: {
          ..._auth(),
          if (identityName != null) 'identity_name': identityName,
          if (donationTarget != null) 'donation_target': donationTarget,
        },
      );
      final json = _ok(response);
      if (json == null) return (claim: null, error: _message(response));

      return (
        claim: PrizeClaim.fromJson(
            (json['claim'] as Map).cast<String, dynamic>()),
        error: null,
      );
    } catch (e) {
      return (claim: null, error: e.toString());
    }
  }

  Future<List<PrizeClaim>> fetchClaims() async {
    final response = await _api.get(
      '${ApiConst.endPointPointsClaims}?${_query(_auth())}',
    );
    final json = _ok(response);
    if (json == null) return const [];

    return ((json['claims'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => PrizeClaim.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<PointGoal?> setGoal({
    required String kind,
    int? prizeId,
    int? tier,
  }) async {
    final response = await _api.post(ApiConst.endPointPointsGoal, body: {
      ..._auth(),
      'kind': kind,
      if (prizeId != null) 'prize_id': prizeId,
      if (tier != null) 'tier': tier,
      // The backend route is a PUT; Dio's post is what the rest of this app uses, so the
      // method is overridden rather than introducing a second transport style here.
      '_method': 'PUT',
    });
    final json = _ok(response);
    if (json == null || json['goal'] == null) return null;

    return PointGoal.fromJson((json['goal'] as Map).cast<String, dynamic>());
  }

  Future<Mission?> fetchMission() async {
    final response = await _api.get(
      '${ApiConst.endPointPointsMission}?${_query(_auth())}',
    );
    final json = _ok(response);
    if (json == null || json['mission'] == null) return null;

    return Mission.fromJson((json['mission'] as Map).cast<String, dynamic>());
  }

  /// Declining rerolls once a week; a second decline comes back as MISSION_DECLINE_LIMIT.
  Future<({Mission? replacement, String? error})> declineMission() async {
    try {
      final response = await _api.post(
        ApiConst.endPointPointsMissionDecline,
        body: _auth(),
      );
      final json = _ok(response);
      if (json == null) return (replacement: null, error: _message(response));

      final replacement = json['replacement'];

      return (
        replacement: replacement == null
            ? null
            : Mission.fromJson((replacement as Map).cast<String, dynamic>()),
        error: null,
      );
    } catch (e) {
      return (replacement: null, error: e.toString());
    }
  }

  /// The house envelope is {status, message, message_code, ...}; status 1 means success.
  Map<String, dynamic>? _ok(dynamic response) {
    if (response is! Map) return null;
    final json = response.cast<String, dynamic>();

    return json['status'] == 1 ? json : null;
  }

  String? _message(dynamic response) =>
      response is Map ? response['message'] as String? : null;
}
