import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../networking/api_base_helper.dart';
import '../../utils/utils.dart';
import 'dugnad_feature_flags.dart';
import 'celebration_models.dart';
import 'dugnad_models.dart';
import 'dugnad_state.dart';
import 'gamification_models.dart';
import 'shop/club_shop_models.dart';
import 'transfer_window_models.dart';

class _LoggedApiHelper {
  _LoggedApiHelper(this._inner);

  final ApiBaseHelper _inner;

  Future<dynamic> get(String url) => _timed('GET $url', () => _inner.get(url));

  Future<dynamic> post(String url, {dynamic body}) =>
      _timed('POST $url', () => _inner.post(url, body: body));

  Future<dynamic> postFormData(String url, {dynamic body, onProgress}) =>
      _timed(
        'POST(form) $url',
        () => _inner.postFormData(url, body: body, onProgress: onProgress),
      );

  Future<dynamic> put(String url, dynamic body) =>
      _timed('PUT $url', () => _inner.put(url, body));

  Future<dynamic> patch(String url, {dynamic body}) =>
      _timed('PATCH $url', () => _inner.patch(url, body: body));

  Future<dynamic> delete(String url) =>
      _timed('DELETE $url', () => _inner.delete(url));

  Future<T> _timed<T>(String label, Future<T> Function() request) async {
    if (!kDebugMode) return request();
    final stopwatch = Stopwatch()..start();
    try {
      return await request();
    } finally {
      debugPrint('[DugnadRepo] $label ${stopwatch.elapsedMilliseconds}ms');
    }
  }
}

/// API client for dugnad sports-club endpoints (D1).
class DugnadRepo {
  final _LoggedApiHelper _api = _LoggedApiHelper(ApiBaseHelper());

  /// GET /api/customer/sports-club/list
  Future<dynamic> listClubs() async {
    return _api.get(
      '${ApiConst.endPointSportsClubList}'
      '?user_id=${prefGetInt(prefUserId)}'
      '&access_token=${prefGetString(prefAccessToken)}',
    );
  }

  /// GET /api/customer/sports-club/{id}
  Future<dynamic> getClubDetail(int clubId) async {
    return _api.get(
      '${ApiConst.endPointSportsClubDetail}$clubId'
      '?user_id=${prefGetInt(prefUserId)}'
      '&access_token=${prefGetString(prefAccessToken)}',
    );
  }

  /// GET /api/customer/sports-club/{id}/sponsor-stores
  Future<dynamic> getSponsorStores(int clubId) async {
    return _api.get(
      '${ApiConst.endPointSportsClubDetail}$clubId/sponsor-stores'
      '?user_id=${prefGetInt(prefUserId)}'
      '&access_token=${prefGetString(prefAccessToken)}',
    );
  }

  /// POST /api/customer/sports-club/financial-summary (existing endpoint)
  /// Returns YTD club_share for a single club when called with year boundaries.
  Future<double> getFundraisingYtd(int clubId) async {
    final now = DateTime.now();
    final response = await _api.post(
      ApiConst.endPointSportsClubFinancialSummary,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        'start_date': '${now.year}-01-01',
        'end_date': '${now.year}-12-31',
        'sports_club_store_id': clubId,
      },
    );
    if (response is Map && response['status'] == 1) {
      final List summary = response['summary'] ?? [];
      for (final row in summary) {
        if (row is! Map) continue;
        final rowClubId = (row['sports_club_store_id'] as num?)?.toInt();
        if (rowClubId == clubId) {
          return (row['club_share'] as num?)?.toDouble() ?? 0;
        }
      }
      if (summary.isNotEmpty && summary.first is Map) {
        final first = summary.first as Map;
        return (first['club_share'] as num?)?.toDouble() ?? 0;
      }
    }
    return 0;
  }

  /// GET /api/customer/sports-club/{clubId}/teams
  Future<List<ClubTeamItem>> listTeams(int clubId) async {
    try {
      final response = await _api.get(
        '${ApiConst.endPointSportsClubDetail}$clubId/teams'
        '?user_id=${prefGetInt(prefUserId)}'
        '&access_token=${prefGetString(prefAccessToken)}',
      );
      if (response is Map && response['status'] == 1) {
        final List raw = response['teams'] ?? [];
        return raw.map((e) => ClubTeamItem.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// POST /api/customer/sports-club/points-team
  Future<PointsTeamProfile?> getPointsTeam({
    int? lastSeenReferralLedgerId,
    int? lastSeenMissionLedgerId,
  }) async {
    if (!isLoggedIn()) return null;
    final body = <String, dynamic>{
      ApiParam.paramUserId: prefGetInt(prefUserId),
      ApiParam.paramAccessToken: prefGetString(prefAccessToken),
    };
    if (lastSeenReferralLedgerId != null) {
      body['last_seen_referral_ledger_id'] = lastSeenReferralLedgerId;
    }
    if (lastSeenMissionLedgerId != null) {
      body['last_seen_mission_ledger_id'] = lastSeenMissionLedgerId;
    }
    final response = await _api.post(
      ApiConst.endPointSportsClubPointsTeam,
      body: body,
    );
    if (response is Map && response['status'] == 1) {
      final points = response['points'];
      if (points is Map) {
        return PointsTeamProfile.fromJson(Map<String, dynamic>.from(points));
      }
    }
    return null;
  }

  /// POST /api/customer/sports-club/club/set
  /// Sets the active club. Clears the points team when it belongs to another club.
  Future<PointsTeamProfile?> setClub({required int clubId}) async {
    if (!isLoggedIn() || clubId <= 0) return null;
    final response = await _api.post(
      ApiConst.endPointSportsClubClubSet,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        'club_id': clubId,
      },
    );
    if (response is Map && response['status'] == 1) {
      final points = response['points'];
      if (points is Map) {
        return PointsTeamProfile.fromJson(Map<String, dynamic>.from(points));
      }
    }
    return null;
  }

  /// POST /api/customer/sports-club/points-team/set
  Future<PointsTeamProfile?> setPointsTeam({
    required int teamId,
    int? clubId,
  }) async {
    if (!isLoggedIn()) return null;
    final body = <String, dynamic>{
      ApiParam.paramUserId: prefGetInt(prefUserId),
      ApiParam.paramAccessToken: prefGetString(prefAccessToken),
      'team_id': teamId,
    };
    if (clubId != null && clubId > 0) {
      body['club_id'] = clubId;
    }
    final response = await _api.post(
      ApiConst.endPointSportsClubPointsTeamSet,
      body: body,
    );
    if (response is Map && response['status'] == 1) {
      final points = response['points'];
      if (points is Map) {
        final json = Map<String, dynamic>.from(points);
        json['welcome_bonus_points_awarded'] =
            (response['welcome_bonus_points_awarded'] as num?)?.toInt() ?? 0;
        json['referral_join_points_awarded'] =
            (response['referred_join_points_awarded'] as num?)?.toInt() ?? 0;
        var profile = PointsTeamProfile.fromJson(json);
        final resolvedClubId = clubId ?? profile.organizationId;
        // Team save already succeeded — never fail the whole call if bonus claim fails.
        if (profile.welcomeBonusPointsAwarded <= 0 &&
            resolvedClubId != null &&
            resolvedClubId > 0) {
          try {
            final claimed = await claimWelcomeBonus(clubId: resolvedClubId);
            if (claimed != null &&
                claimed.welcomeBonusPointsAwarded >
                    profile.welcomeBonusPointsAwarded) {
              profile = claimed;
            }
          } catch (_) {}
        }
        return profile;
      }
    }
    return null;
  }

  /// POST /api/customer/sports-club/welcome-bonus/claim
  Future<PointsTeamProfile?> claimWelcomeBonus({
    required int clubId,
  }) async {
    if (!isLoggedIn()) return null;
    final body = <String, dynamic>{
      ApiParam.paramUserId: prefGetInt(prefUserId),
      ApiParam.paramAccessToken: prefGetString(prefAccessToken),
      'club_id': clubId,
    };
    final response = await _api.post(
      ApiConst.endPointSportsClubWelcomeBonusClaim,
      body: body,
    );
    if (response is Map && response['status'] == 1) {
      final points = response['points'];
      if (points is Map) {
        final json = Map<String, dynamic>.from(points);
        json['welcome_bonus_points_awarded'] =
            (response['welcome_bonus_points_awarded'] as num?)?.toInt() ?? 0;
        json['referral_join_points_awarded'] =
            (response['referred_join_points_awarded'] as num?)?.toInt() ?? 0;
        return PointsTeamProfile.fromJson(json);
      }
    }
    return null;
  }

  /// POST /api/customer/sports-club/tour/complete — idempotent tour reward.
  /// Returns the raw response map on success (carries `awarded` / `tour_points`),
  /// or null on failure. Safe to call repeatedly (server-side idempotent).
  Future<Map<String, dynamic>?> completeTour({required int clubId}) async {
    if (!isLoggedIn()) return null;
    final body = <String, dynamic>{
      ApiParam.paramUserId: prefGetInt(prefUserId),
      ApiParam.paramAccessToken: prefGetString(prefAccessToken),
      'club_id': clubId,
    };
    final response = await _api.post(
      ApiConst.endPointSportsClubTourComplete,
      body: body,
    );
    if (response is Map && response['status'] == 1) {
      return Map<String, dynamic>.from(response);
    }
    return null;
  }

  Future<ReferralValidationResult> validateReferral({
    required String clubSlug,
    String? referralToken,
    String? referralCode,
  }) async {
    final params = <String, String>{
      'club': clubSlug,
      if (referralToken != null && referralToken.isNotEmpty) 'v': referralToken,
      if (referralCode != null && referralCode.isNotEmpty) 'code': referralCode,
      if (isLoggedIn()) 'user_id': '${prefGetInt(prefUserId)}',
    };
    final query = params.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    final response = await _api.get('${ApiConst.endPointReferralValidate}?$query');
    if (response is Map && response['status'] == 1) {
      final referral = response['referral'];
      if (referral is Map) {
        return ReferralValidationResult.fromJson({
          'valid': true,
          ...Map<String, dynamic>.from(referral),
        });
      }
    }
    return ReferralValidationResult(
      valid: false,
      message: response is Map ? response['message']?.toString() : null,
      code: response is Map ? response['code']?.toString() : null,
    );
  }

  Future<ReferralRecord?> captureReferral({
    String? clubSlug,
    String? referralToken,
    String? referralCode,
    String captureSource = 'manual',
  }) async {
    if (!isLoggedIn()) return null;
    final response = await _api.post(
      ApiConst.endPointReferralCapture,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        if (clubSlug != null && clubSlug.isNotEmpty) 'club_slug': clubSlug,
        if (referralToken != null && referralToken.isNotEmpty) 'referral_token': referralToken,
        if (referralCode != null && referralCode.isNotEmpty) 'referral_code': referralCode,
        'capture_source': captureSource,
      },
    );
    if (response is Map && response['status'] == 1) {
      final joinPoints =
          (response['referred_join_points_awarded'] as num?)?.toInt() ?? 0;
      if (joinPoints > 0) {
        await prefSetInt(prefDugnadReferralJoinPoints, joinPoints);
      }
      final referral = response['referral'];
      if (referral is Map) {
        return ReferralRecord.fromJson(Map<String, dynamic>.from(referral));
      }
    }
    return null;
  }

  Future<ReferralSummary?> getReferralSummary({int? organizationId}) async {
    if (!isLoggedIn()) return null;
    final body = <String, dynamic>{
      ApiParam.paramUserId: prefGetInt(prefUserId),
      ApiParam.paramAccessToken: prefGetString(prefAccessToken),
    };
    if (organizationId != null && organizationId > 0) {
      body['organization_id'] = organizationId;
    }
    try {
      final response = await _api.post(
        ApiConst.endPointReferralSummary,
        body: body,
      );
      if (response is Map && response['status'] == 1) {
        final summary = response['summary'];
        if (summary is Map) {
          return ReferralSummary.fromJson(Map<String, dynamic>.from(summary));
        }
      }
    } catch (_) {}
    return null;
  }

  Future<ShareSummary?> getShareSummary({int? organizationId}) async {
    if (!isLoggedIn()) return null;
    final body = <String, dynamic>{
      ApiParam.paramUserId: prefGetInt(prefUserId),
      ApiParam.paramAccessToken: prefGetString(prefAccessToken),
    };
    if (organizationId != null && organizationId > 0) {
      body['organization_id'] = organizationId;
    }
    final response = await _api.post(
      ApiConst.endPointShareSummary,
      body: body,
    );
    if (response is Map && response['status'] == 1) {
      final share = response['share'];
      if (share is Map) {
        return ShareSummary.fromJson(Map<String, dynamic>.from(share));
      }
    }
    return null;
  }

  Future<bool> donationsEnabled() async {
    try {
      final response = await _api.get(ApiConst.endPointDonationEnabled);
      if (response is Map) {
        final status = response['status'];
        if (status == 1 || status == '1') {
          final enabled = response['enabled'];
          return enabled == true ||
              enabled == 1 ||
              enabled == '1' ||
              enabled == 'true';
        }
      }
    } catch (_) {}
    // Fall back to compile-time flag when the endpoint is unavailable.
    return DugnadFeatureFlags.donationsEnabled;
  }

  Future<DonationFeePreview?> donationFeePreview(int amountKr) async {
    final response = await _api.get(
      '${ApiConst.endPointDonationFeePreview}?amount_kr=$amountKr',
    );
    if (response is Map && response['status'] == 1) {
      final preview = response['preview'];
      if (preview is Map) {
        return DonationFeePreview.fromJson(Map<String, dynamic>.from(preview));
      }
    }
    return null;
  }

  Future<List<DonationSubscriptionRecord>> listDonationSubscriptions() async {
    if (!isLoggedIn()) return [];
    final response = await _api.get(
      '${ApiConst.endPointDonationSubscriptions}'
      '?user_id=${prefGetInt(prefUserId)}'
      '&access_token=${prefGetString(prefAccessToken)}',
    );
    if (response is Map && response['status'] == 1) {
      final list = response['subscriptions'];
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => DonationSubscriptionRecord.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList();
      }
    }
    return [];
  }

  Future<Map<String, dynamic>?> createDonationSubscription({
    required String beneficiaryType,
    required int organizationId,
    int? teamId,
    required int amountKr,
  }) async {
    if (!isLoggedIn()) return null;
    try {
      final response = await _api.post(
        ApiConst.endPointDonationSubscriptions,
        body: {
          ApiParam.paramUserId: prefGetInt(prefUserId),
          ApiParam.paramAccessToken: prefGetString(prefAccessToken),
          'beneficiary_type': beneficiaryType,
          'organization_id': organizationId,
          if (teamId != null) 'team_id': teamId,
          'amount_kr': amountKr,
        },
      );
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
    } on BadRequestException catch (e) {
      return _parseApiErrorBody(e.toString());
    } catch (_) {}
    return null;
  }

  Map<String, dynamic>? _parseApiErrorBody(String raw) {
    final body = raw.replaceFirst('Invalid Request: ', '').trim();
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return {'status': 0, 'message': body};
  }

  Future<Map<String, dynamic>?> syncDonationSubscription(int id) async {
    if (!isLoggedIn()) return null;
    final response = await _api.post(
      '${ApiConst.endPointDonationSubscriptions}/$id/sync',
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
      },
    );
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return null;
  }

  Future<Map<String, dynamic>?> updateDonationSubscription({
    required int id,
    int? amountKr,
    String? beneficiaryType,
    int? organizationId,
    int? teamId,
  }) async {
    if (!isLoggedIn()) return null;
    try {
      final body = <String, dynamic>{
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
      };
      if (amountKr != null) body['amount_kr'] = amountKr;
      if (beneficiaryType != null) body['beneficiary_type'] = beneficiaryType;
      if (organizationId != null) body['organization_id'] = organizationId;
      if (teamId != null) body['team_id'] = teamId;

      final response = await _api.patch(
        '${ApiConst.endPointDonationSubscriptions}/$id',
        body: body,
      );
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
    } on BadRequestException catch (e) {
      return _parseApiErrorBody(e.toString());
    } catch (_) {}
    return null;
  }

  Future<bool> pauseDonationSubscription(int id) async {
    if (!isLoggedIn()) return false;
    final response = await _api.post(
      '${ApiConst.endPointDonationSubscriptions}/$id/pause',
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
      },
    );
    return response is Map && response['status'] == 1;
  }

  Future<bool> resumeDonationSubscription(int id) async {
    if (!isLoggedIn()) return false;
    final response = await _api.post(
      '${ApiConst.endPointDonationSubscriptions}/$id/resume',
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
      },
    );
    return response is Map && response['status'] == 1;
  }

  Future<bool> abandonDonationSubscription(int id) async {
    if (!isLoggedIn()) return false;
    final response = await _api.post(
      '${ApiConst.endPointDonationSubscriptions}/$id/abandon',
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
      },
    );
    return response is Map && response['status'] == 1;
  }

  Future<bool> cancelDonationSubscription(int id) async {
    if (!isLoggedIn()) return false;
    final response = await _api.delete(
      '${ApiConst.endPointDonationSubscriptions}/$id'
      '?user_id=${prefGetInt(prefUserId)}'
      '&access_token=${prefGetString(prefAccessToken)}',
    );
    return response is Map && response['status'] == 1;
  }

  /// POST /api/customer/points/summary
  Future<PointsSummary?> getPointsSummary() async {
    if (!isLoggedIn()) return null;
    try {
      final response = await _api.post(
        ApiConst.endPointPointsSummary,
        body: {
          ApiParam.paramUserId: prefGetInt(prefUserId),
          ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        },
      );
      if (response is Map && response['status'] == 1) {
        final summary = response['summary'];
        final points = response['points'];
        if (summary is Map) {
          final merged = Map<String, dynamic>.from(summary);
          if (points is Map) {
            final cpp = points['campaign_purchase_points'];
            if (cpp != null) merged['campaign_purchase_points'] = cpp;
          }
          return PointsSummary.fromJson(merged);
        }
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/customer/points/ledger
  Future<PointsLedgerPage?> getPointsLedger({
    int page = 1,
    int perPage = 20,
  }) async {
    if (!isLoggedIn()) return null;
    try {
      final response = await _api.post(
        ApiConst.endPointPointsLedger,
        body: {
          ApiParam.paramUserId: prefGetInt(prefUserId),
          ApiParam.paramAccessToken: prefGetString(prefAccessToken),
          'page': page,
          'per_page': perPage,
        },
      );
      if (response is Map && response['status'] == 1) {
        final ledger = response['ledger'];
        if (ledger is Map) {
          return PointsLedgerPage.fromJson(Map<String, dynamic>.from(ledger));
        }
      }
    } catch (_) {}
    return null;
  }

  Future<List<PointsLedgerEntry>> getAllPointsLedgerEntries({
    int perPage = 50,
  }) async {
    final all = <PointsLedgerEntry>[];
    var page = 1;
    while (true) {
      final result = await getPointsLedger(page: page, perPage: perPage);
      if (result == null) break;
      all.addAll(result.entries);
      if (result.entries.isEmpty || all.length >= result.total) break;
      page++;
    }
    return all;
  }

  /// GET /api/customer/sports-club/{clubId}/leaderboard
  Future<LeaderboardData?> getLeaderboard(int clubId) async {
    try {
      final response = await _api.get(
        '${ApiConst.endPointSportsClubDetail}$clubId/leaderboard'
        '?user_id=${prefGetInt(prefUserId)}'
        '&access_token=${prefGetString(prefAccessToken)}',
      );
      if (response is Map && response['status'] == 1) {
        final board = response['leaderboard'];
        if (board is Map) {
          return LeaderboardData.fromJson(Map<String, dynamic>.from(board));
        }
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/customer/sports-club/{clubId}/leaderboard/scorers?tab=
  Future<LeaderboardScorersData?> getLeaderboardScorers(
    int clubId, {
    required String tab,
    int? teamId,
  }) async {
    var url =
        '${ApiConst.endPointSportsClubDetail}$clubId/leaderboard/scorers'
        '?tab=$tab'
        '&user_id=${prefGetInt(prefUserId)}'
        '&access_token=${prefGetString(prefAccessToken)}';
    if (teamId != null) {
      url += '&team_id=$teamId';
    }
    try {
      final response = await _api.get(url);
      if (response is Map && response['status'] == 1) {
        final payload = response['scorers'];
        if (payload is Map) {
          return LeaderboardScorersData.fromJson(
            Map<String, dynamic>.from(payload),
          );
        }
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/customer/sports-club/{clubId}/teams/{teamId}/detail
  Future<TeamDetailData?> getTeamDetail(int clubId, int teamId) async {
    try {
      final response = await _api.get(
        '${ApiConst.endPointSportsClubDetail}$clubId/teams/$teamId/detail'
        '?user_id=${prefGetInt(prefUserId)}'
        '&access_token=${prefGetString(prefAccessToken)}',
      );
      if (response is Map && response['status'] == 1) {
        final detail = response['team_detail'];
        if (detail is Map) {
          return TeamDetailData.fromJson(Map<String, dynamic>.from(detail));
        }
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/customer/dugnad/config
  Future<GamificationConfig?> getGamificationConfig({
    int? organizationId,
    int? teamId,
  }) async {
    var url = ApiConst.endPointDugnadConfig;
    final params = <String>[];
    if (organizationId != null && organizationId > 0) {
      params.add('organization_id=$organizationId');
    }
    if (teamId != null && teamId > 0) {
      params.add('team_id=$teamId');
    }
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    try {
      final response = await _api.get(url);
      if (response is Map && response['status'] == 1) {
        return GamificationConfig.fromJson(Map<String, dynamic>.from(response));
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/customer/dugnad/celebrations/pending
  Future<PendingCelebrationsResponse?> fetchPendingCelebrations({
    int? clubId,
  }) async {
    if (!isLoggedIn()) return null;
    final body = <String, dynamic>{
      ApiParam.paramUserId: prefGetInt(prefUserId),
      ApiParam.paramAccessToken: prefGetString(prefAccessToken),
    };
    if (clubId != null && clubId > 0) {
      body['club_id'] = clubId;
    }
    try {
      final response = await _api.post(
        ApiConst.endPointDugnadCelebrationsPending,
        body: body,
      );
      if (response is Map && response['status'] == 1) {
        return PendingCelebrationsResponse.fromJson(
          Map<String, dynamic>.from(response),
        );
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/customer/dugnad/celebrations/dev/trigger (debug only)
  Future<bool> triggerDevCelebration({
    required String typeKey,
    int? clubId,
  }) async {
    if (!isLoggedIn() || !kDebugMode) return false;
    final body = <String, dynamic>{
      ApiParam.paramUserId: prefGetInt(prefUserId),
      ApiParam.paramAccessToken: prefGetString(prefAccessToken),
      'type_key': typeKey,
    };
    if (clubId != null && clubId > 0) {
      body['club_id'] = clubId;
    }
    try {
      final response = await _api.post(
        ApiConst.endPointDugnadCelebrationsDevTrigger,
        body: body,
      );
      return response is Map && response['status'] == 1;
    } catch (_) {
      return false;
    }
  }

  /// POST /api/customer/dugnad/celebrations/dev/clear (debug only)
  Future<bool> clearDevCelebrations({int? clubId}) async {
    if (!isLoggedIn() || !kDebugMode) return false;
    final body = <String, dynamic>{
      ApiParam.paramUserId: prefGetInt(prefUserId),
      ApiParam.paramAccessToken: prefGetString(prefAccessToken),
    };
    if (clubId != null && clubId > 0) {
      body['club_id'] = clubId;
    }
    try {
      final response = await _api.post(
        ApiConst.endPointDugnadCelebrationsDevClear,
        body: body,
      );
      return response is Map && response['status'] == 1;
    } catch (_) {
      return false;
    }
  }

  /// POST /api/customer/dugnad/celebrations/{id}/consume
  Future<bool> consumeCelebration(int id) async {
    if (!isLoggedIn() || id <= 0) return false;
    try {
      final response = await _api.post(
        '${ApiConst.endPointDugnadCelebrationsConsume}/$id/consume',
        body: {
          ApiParam.paramUserId: prefGetInt(prefUserId),
          ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        },
      );
      return response is Map && response['status'] == 1;
    } catch (_) {
      return false;
    }
  }

  /// POST /api/customer/dugnad/gamification/progress
  Future<GamificationProgress?> getGamificationProgress({
    int? organizationId,
    int? teamId,
  }) async {
    if (!isLoggedIn()) return null;
    final body = <String, dynamic>{
      ApiParam.paramUserId: prefGetInt(prefUserId),
      ApiParam.paramAccessToken: prefGetString(prefAccessToken),
    };
    if (organizationId != null && organizationId > 0) {
      body['organization_id'] = organizationId;
    }
    if (teamId != null && teamId > 0) {
      body['team_id'] = teamId;
    }

    try {
      final response = await _api.post(
        ApiConst.endPointDugnadGamificationProgress,
        body: body,
      );
      if (response is Map && response['status'] == 1) {
        final progress = response['progress'];
        if (progress is Map) {
          return GamificationProgress.fromJson(
            Map<String, dynamic>.from(progress),
          );
        }
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/customer/dugnad/gamification/career
  Future<GamificationCareer?> getGamificationCareer({
    int? organizationId,
    int? teamId,
  }) async {
    if (!isLoggedIn()) return null;
    final body = <String, dynamic>{
      ApiParam.paramUserId: prefGetInt(prefUserId),
      ApiParam.paramAccessToken: prefGetString(prefAccessToken),
    };
    if (organizationId != null && organizationId > 0) {
      body['organization_id'] = organizationId;
    }
    if (teamId != null && teamId > 0) {
      body['team_id'] = teamId;
    }

    try {
      final response = await _api.post(
        ApiConst.endPointDugnadGamificationCareer,
        body: body,
      );
      if (response is Map && response['status'] == 1) {
        final career = response['career'];
        if (career is Map) {
          return GamificationCareer.fromJson(
            Map<String, dynamic>.from(career),
          );
        }
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/customer/dugnad/gamification/activity
  Future<bool> recordGamificationActivity(String activityKey) async {
    if (!isLoggedIn()) return false;
    try {
      final response = await _api.post(
        ApiConst.endPointDugnadGamificationActivity,
        body: {
          ApiParam.paramUserId: prefGetInt(prefUserId),
          ApiParam.paramAccessToken: prefGetString(prefAccessToken),
          'activity_key': activityKey,
          if (DugnadState.instance.clubId > 0)
            'organization_id': DugnadState.instance.clubId,
        },
      );
      return response is Map && response['status'] == 1;
    } catch (_) {
      return false;
    }
  }

  /// POST /api/customer/dugnad/transfer/window
  Future<TransferWindowContext?> getTransferWindow() async {
    if (!isLoggedIn()) return null;
    final response = await _api.post(
      ApiConst.endPointDugnadTransferWindow,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
      },
    );
    if (response is Map && response['status'] == 1) {
      final transfer = response['transfer'];
      if (transfer is Map) {
        return TransferWindowContext.fromJson(
          Map<String, dynamic>.from(transfer),
        );
      }
    }
    return null;
  }

  /// POST /api/customer/dugnad/transfer/commit
  Future<TransferCommitResult?> commitTransfer({
    required String action,
    int? teamId,
  }) async {
    if (!isLoggedIn()) return null;
    final body = <String, dynamic>{
      ApiParam.paramUserId: prefGetInt(prefUserId),
      ApiParam.paramAccessToken: prefGetString(prefAccessToken),
      'action': action,
    };
    if (teamId != null && teamId > 0) {
      body['team_id'] = teamId;
    }
    final response = await _api.post(
      ApiConst.endPointDugnadTransferCommit,
      body: body,
    );
    if (response is Map && response['status'] == 1) {
      PointsTeamProfile? points;
      final pointsRaw = response['points'];
      if (pointsRaw is Map) {
        points = PointsTeamProfile.fromJson(
          Map<String, dynamic>.from(pointsRaw),
        );
      }
      return TransferCommitResult.fromJson(
        Map<String, dynamic>.from(response),
        points: points,
      );
    }
    return null;
  }

  /// POST /api/customer/dugnad/privacy
  Future<DugnadPrivacySettings?> getPrivacySettings() async {
    if (!isLoggedIn()) return null;
    final response = await _api.post(
      ApiConst.endPointDugnadPrivacy,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
      },
    );
    if (response is Map && response['status'] == 1) {
      final privacy = response['privacy'];
      if (privacy is Map) {
        return DugnadPrivacySettings.fromJson(
          Map<String, dynamic>.from(privacy),
        );
      }
    }
    return null;
  }

  /// POST /api/customer/dugnad/privacy/update
  Future<DugnadPrivacySettings?> updatePrivacySettings({
    required String displayNamePref,
    required String nickname,
    required bool isVisible,
  }) async {
    if (!isLoggedIn()) return null;
    final response = await _api.post(
      ApiConst.endPointDugnadPrivacyUpdate,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        'display_name_pref': displayNamePref,
        'nickname': nickname,
        'is_visible': isVisible,
      },
    );
    if (response is Map && response['status'] == 1) {
      final privacy = response['privacy'];
      if (privacy is Map) {
        return DugnadPrivacySettings.fromJson(
          Map<String, dynamic>.from(privacy),
        );
      }
    }
    return null;
  }

  /// Raw API response for cache persistence.
  Future<dynamic> getPointsSummaryRaw() async {
    if (!isLoggedIn()) return null;
    return _api.post(
      ApiConst.endPointPointsSummary,
      body: {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
      },
    );
  }

  Future<dynamic> getLeaderboardRaw(int clubId) async {
    return _api.get(
      '${ApiConst.endPointSportsClubDetail}$clubId/leaderboard'
      '?user_id=${prefGetInt(prefUserId)}'
      '&access_token=${prefGetString(prefAccessToken)}',
    );
  }

  Future<dynamic> getGamificationConfigRaw({
    int? organizationId,
    int? teamId,
  }) async {
    var url = ApiConst.endPointDugnadConfig;
    final params = <String>[];
    if (organizationId != null && organizationId > 0) {
      params.add('organization_id=$organizationId');
    }
    if (teamId != null && teamId > 0) {
      params.add('team_id=$teamId');
    }
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }
    return _api.get(url);
  }

  Future<dynamic> getGamificationCareerRaw({
    int? organizationId,
    int? teamId,
  }) async {
    if (!isLoggedIn()) return null;
    final body = <String, dynamic>{
      ApiParam.paramUserId: prefGetInt(prefUserId),
      ApiParam.paramAccessToken: prefGetString(prefAccessToken),
    };
    if (organizationId != null && organizationId > 0) {
      body['organization_id'] = organizationId;
    }
    if (teamId != null && teamId > 0) {
      body['team_id'] = teamId;
    }
    return _api.post(ApiConst.endPointDugnadGamificationCareer, body: body);
  }

  Future<dynamic> getReferralSummaryRaw({int? organizationId}) async {
    if (!isLoggedIn()) return null;
    final body = <String, dynamic>{
      ApiParam.paramUserId: prefGetInt(prefUserId),
      ApiParam.paramAccessToken: prefGetString(prefAccessToken),
    };
    if (organizationId != null && organizationId > 0) {
      body['organization_id'] = organizationId;
    }
    return _api.post(ApiConst.endPointReferralSummary, body: body);
  }

  /// GET /api/customer/sports-club/{id}/home-bundle
  Future<dynamic> getHomeBundleRaw({
    required int clubId,
    int? teamId,
  }) async {
    var url =
        '${ApiConst.endPointSportsClubDetail}$clubId/home-bundle'
        '?user_id=${prefGetInt(prefUserId)}'
        '&access_token=${prefGetString(prefAccessToken)}';
    if (teamId != null && teamId > 0) {
      url += '&team_id=$teamId';
    }
    return _api.get(url);
  }

  Map<String, dynamic> _authBody() => {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
      };

  /// POST /api/customer/dugnad/notifications
  Future<DugnadNotificationsPage?> getNotifications({
    int page = 1,
    int perPage = 30,
  }) async {
    if (!isLoggedIn()) return null;
    final response = await _api.post(
      ApiConst.endPointDugnadNotifications,
      body: {
        ..._authBody(),
        ApiParam.paramPage: page,
        ApiParam.paramPerPage: perPage,
      },
    );
    if (response is Map && response['status'] == 1) {
      return DugnadNotificationsPage.fromJson(
        Map<String, dynamic>.from(response),
      );
    }
    return null;
  }

  /// POST /api/customer/dugnad/notifications/unread-count
  Future<int> getNotificationUnreadCount() async {
    if (!isLoggedIn()) return 0;
    final response = await _api.post(
      ApiConst.endPointDugnadNotificationsUnreadCount,
      body: _authBody(),
    );
    if (response is Map && response['status'] == 1) {
      return (response['unread_count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  /// POST /api/customer/dugnad/notifications/mark-read
  Future<bool> markNotificationsRead({int? id, List<int>? ids}) async {
    if (!isLoggedIn()) return false;
    final body = <String, dynamic>{..._authBody()};
    if (ids != null && ids.isNotEmpty) {
      body['ids'] = ids;
    } else if (id != null) {
      body['id'] = id;
    } else {
      return false;
    }
    final response = await _api.post(
      ApiConst.endPointDugnadNotificationsMarkRead,
      body: body,
    );
    return response is Map && response['status'] == 1;
  }

  /// POST /api/customer/dugnad/notifications/mark-feed-seen
  Future<bool> markNotificationFeedSeen() async {
    if (!isLoggedIn()) return false;
    final response = await _api.post(
      ApiConst.endPointDugnadNotificationsMarkFeedSeen,
      body: _authBody(),
    );
    return response is Map && response['status'] == 1;
  }

  /// POST /api/customer/dugnad/notifications/prefs
  Future<DugnadNotificationPrefs?> getNotificationPrefs() async {
    if (!isLoggedIn()) return null;
    final response = await _api.post(
      ApiConst.endPointDugnadNotificationsPrefs,
      body: _authBody(),
    );
    if (response is Map && response['status'] == 1) {
      final prefs = response['prefs'];
      if (prefs is Map) {
        return DugnadNotificationPrefs.fromJson(
          Map<String, dynamic>.from(prefs),
        );
      }
    }
    return null;
  }

  /// POST /api/customer/dugnad/notifications/prefs/update
  Future<DugnadNotificationPrefs?> updateNotificationPrefs(
    DugnadNotificationPrefs prefs,
  ) async {
    if (!isLoggedIn()) return null;
    final response = await _api.post(
      ApiConst.endPointDugnadNotificationsPrefsUpdate,
      body: {
        ..._authBody(),
        ...prefs.toUpdatePayload(),
      },
    );
    if (response is Map && response['status'] == 1) {
      final raw = response['prefs'];
      if (raw is Map) {
        return DugnadNotificationPrefs.fromJson(
          Map<String, dynamic>.from(raw),
        );
      }
      return prefs;
    }
    return null;
  }

  Map<String, dynamic> _clubShopAuth(int clubId) => {
        ApiParam.paramUserId: prefGetInt(prefUserId),
        ApiParam.paramAccessToken: prefGetString(prefAccessToken),
        'club_id': clubId,
      };

  /// GET|POST /api/customer/dugnad/club-shop/access
  Future<ClubShopAccess?> clubShopAccess({required int clubId}) async {
    if (!isLoggedIn()) return null;
    try {
      final response = await _api.post(
        ApiConst.endPointClubShopAccess,
        body: _clubShopAuth(clubId),
      );
      if (response is Map && response['status'] == 1) {
        return ClubShopAccess.fromJson(Map<String, dynamic>.from(response));
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/customer/dugnad/club-shop/unlock
  Future<ClubShopUnlockResult> clubShopUnlock({
    required int clubId,
    required String membershipNumber,
  }) async {
    if (!isLoggedIn()) {
      return const ClubShopUnlockResult(
        ok: false,
        message: '',
        reason: 'unknown',
      );
    }
    try {
      final response = await _api.post(
        ApiConst.endPointClubShopUnlock,
        body: {
          ..._clubShopAuth(clubId),
          'membership_number': membershipNumber,
        },
      );
      if (response is Map) {
        return ClubShopUnlockResult.fromJson(Map<String, dynamic>.from(response));
      }
    } catch (_) {}
    return const ClubShopUnlockResult(
      ok: false,
      reason: 'unknown',
      message: '',
    );
  }

  /// GET|POST /api/customer/dugnad/club-shop/catalog
  Future<ClubShopCatalog?> clubShopCatalog({required int clubId}) async {
    if (!isLoggedIn()) return null;
    try {
      final response = await _api.post(
        ApiConst.endPointClubShopCatalog,
        body: _clubShopAuth(clubId),
      );
      if (response is Map && response['status'] == 1) {
        return ClubShopCatalog.fromJson(Map<String, dynamic>.from(response));
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> clubShopPay({
    required int clubId,
    required List<Map<String, dynamic>> lines,
    required String paymentMethod,
    String? phone,
  }) async {
    if (!isLoggedIn()) return null;
    try {
      final response = await _api.post(
        ApiConst.endPointClubShopPay,
        body: {
          ..._clubShopAuth(clubId),
          'lines': lines,
          'payment_method': paymentMethod,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> clubShopConfirm({
    required int clubId,
    required String paymentRef,
  }) async {
    if (!isLoggedIn()) return null;
    try {
      final response = await _api.post(
        ApiConst.endPointClubShopConfirm,
        body: {
          ..._clubShopAuth(clubId),
          'payment_ref': paymentRef,
        },
      );
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
    } catch (_) {}
    return null;
  }

  Future<List<ClubShopPaidOrder>> clubShopOrders({required int clubId}) async {
    if (!isLoggedIn()) return const [];
    try {
      final response = await _api.post(
        ApiConst.endPointClubShopOrders,
        body: _clubShopAuth(clubId),
      );
      if (response is Map && response['status'] == 1) {
        final raw = response['orders'] as List? ?? [];
        return raw
            .whereType<Map>()
            .map(
              (e) => ClubShopPaidOrder.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      }
    } catch (_) {}
    return const [];
  }
}
