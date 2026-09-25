import '../../networking/api_base_helper.dart';
import '../../utils/shared_pref_utill.dart';
import '../../utils/utils.dart';
import '../aegil/aegil_app_models.dart';
import 'league_models.dart';
import 'points_models.dart';
import 'points_repo.dart';

/// What the Meg / Points screens read and write (agil-3 Phase 7), behind an
/// interface so every screen renders from a fake in tests. Wraps agil-2's
/// [PointsRepo] and adds the league, the referral, "Ægil velger" and the
/// Fjordfiske earn call.
abstract class PointsAppApi {
  Future<PointsBalance?> balance();
  Future<Premiehylla?> shelf();
  Future<List<PrizeClaim>> claims();
  Future<({PrizeClaim? claim, String? error})> claim(int prizeId, {String? identityName});
  Future<PointGoal?> setGoal({int? prizeId, int? tier});
  Future<Mission?> mission();
  Future<({Mission? replacement, String? error})> declineMission();
  Future<League?> league();
  Future<bool> leagueOptIn(bool optIn);
  Future<Referral?> referral();
  Future<AegilPick?> pick();
  Future<EarnResult?> earn({required int catchNumber, int? suggestionId});
}

class PointsAppRepo implements PointsAppApi {
  PointsAppRepo({PointsRepo? points}) : _points = points ?? PointsRepo();

  final PointsRepo _points;

  ApiBaseHelper get _api => ApiBaseHelper(baseUrl: ApiConst.basePointsUrl);

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
  Future<PointsBalance?> balance() => _points.fetchBalance();

  @override
  Future<Premiehylla?> shelf() => _points.fetchShelf();

  @override
  Future<List<PrizeClaim>> claims() => _points.fetchClaims();

  @override
  Future<({PrizeClaim? claim, String? error})> claim(int prizeId, {String? identityName}) =>
      _points.claimPrize(prizeId, identityName: identityName);

  @override
  Future<PointGoal?> setGoal({int? prizeId, int? tier}) =>
      _points.setGoal(kind: prizeId != null ? 'prize' : 'tier', prizeId: prizeId, tier: tier);

  @override
  Future<Mission?> mission() => _points.fetchMission();

  @override
  Future<({Mission? replacement, String? error})> declineMission() => _points.declineMission();

  @override
  Future<League?> league() async {
    try {
      final json = _ok(await _api.get('league?${_query(_auth())}'));
      return json == null ? null : League.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> leagueOptIn(bool optIn) async {
    try {
      return _ok(await _api.post(optIn ? 'league/opt-in' : 'league/opt-out', body: _auth())) != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Referral?> referral() async {
    try {
      final json = _ok(await _api.get('${ApiConst.endPointPointsReferral}?${_query(_auth())}'));
      final r = json?['referral'];
      return r is Map ? Referral.fromJson(r.cast<String, dynamic>()) : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AegilPick?> pick() async {
    try {
      final json = _ok(await _api.post('prizes/pick', body: _auth()));
      return json == null ? null : AegilPick.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<EarnResult?> earn({required int catchNumber, int? suggestionId}) async {
    try {
      final json = _ok(await _api.post('me/earn?rule=dagens_napp', body: {
        ..._auth(),
        'rule': 'dagens_napp',
        'catch': catchNumber,
        if (suggestionId != null) 'suggestion_id': suggestionId,
      }));
      return json == null ? null : EarnResult.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
