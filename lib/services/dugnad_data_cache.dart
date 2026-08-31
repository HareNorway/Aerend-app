import 'dart:async';

import 'package:flutter/foundation.dart';

import '../screens/dugnad/dugnad_models.dart';
import '../screens/dugnad/dugnad_repo.dart';
import '../screens/dugnad/dugnad_state.dart';
import '../screens/dugnad/gamification_models.dart';
import '../screens/dugnad/transfer_window_models.dart';
import '../utils/utils.dart';
import 'dugnad_cache_persistence.dart';

class _CacheEntry {
  _CacheEntry(this.value, this.expiresAt);

  final dynamic value;
  final DateTime expiresAt;

  bool isFresh(DateTime now) => now.isBefore(expiresAt);
}

/// In-memory cache for dugnad API payloads — TTL, in-flight dedupe,
/// stale-while-revalidate, and prefs persistence for cold start.
class DugnadDataCache {
  DugnadDataCache._();

  static final DugnadDataCache instance = DugnadDataCache._();

  final DugnadRepo _repo = DugnadRepo();
  final Map<String, _CacheEntry> _cache = {};
  final Map<String, Future<dynamic>> _inFlight = {};
  final Map<String, DugnadPersistedEntry> _persisted = {};
  Timer? _persistTimer;
  bool _hydrated = false;

  static String leaderboardKey(int clubId) => 'leaderboard:$clubId';
  static String clubDetailKey(int clubId) => 'clubDetail:$clubId';
  static String sponsorStoresKey(int clubId) => 'sponsorStores:$clubId';
  static String gamificationConfigKey(int clubId) =>
      'gamificationConfig:$clubId';
  static String gamificationCareerKey(int clubId, int? teamId) =>
      'gamificationCareer:$clubId:${teamId ?? 0}';
  static String transferWindowKey(int clubId) => 'transferWindow:$clubId';

  T? peek<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    return entry.value as T?;
  }

  PointsSummary? peekPointsSummary() => peek<PointsSummary>('pointsSummary');

  LeaderboardData? peekLeaderboard(int clubId) =>
      peek<LeaderboardData>(leaderboardKey(clubId));

  ClubDetail? peekClubDetail(int clubId) =>
      peek<ClubDetail>(clubDetailKey(clubId));

  /// Restore last session snapshot from prefs (call once after prefs init).
  Future<void> hydrateFromPrefs() async {
    if (_hydrated) return;
    _hydrated = true;

    final snapshot = await DugnadCachePersistence.load();
    if (snapshot == null) return;
    if (!DugnadCachePersistence.matchesCurrentScope(snapshot)) {
      await DugnadCachePersistence.clear();
      return;
    }

    final now = DateTime.now();
    for (final entry in snapshot.entries.entries) {
      if (entry.value.expiresAt.isBefore(now)) continue;
      final decoded = decodeDugnadCacheValue(entry.value.codec, entry.value.data);
      if (decoded == null) continue;
      _cache[entry.key] = _CacheEntry(decoded, entry.value.expiresAt);
      _persisted[entry.key] = entry.value;
    }

    if (kDebugMode) {
      debugPrint(
        '[DugnadDataCache] hydrated ${_cache.length} entries from prefs',
      );
    }
  }

  /// Fire-and-forget warm-up before dugnad home mounts.
  void prefetchForDugnadEntry() {
    if (!DugnadState.instance.hasClub) return;
    final clubId = DugnadState.instance.clubId;
    if (clubId <= 0) return;

    final teamId = prefGetInt(prefPointsTeamId);
    unawaited(
      loadHomeBundle(
        clubId: clubId,
        loggedIn: isLoggedIn(),
        teamId: teamId > 0 ? teamId : null,
      ),
    );
  }

  void clearAll() {
    _cache.clear();
    _inFlight.clear();
    _persisted.clear();
    _persistTimer?.cancel();
    unawaited(DugnadCachePersistence.clear());
  }

  void invalidate(String key) {
    _cache.remove(key);
    _inFlight.remove(key);
    _persisted.remove(key);
    _schedulePersist();
  }

  /// Drop club-scoped entries when the user switches club or logs out.
  void invalidateClubScoped() {
    _cache.removeWhere(
      (key, _) =>
          key.startsWith('leaderboard:') ||
          key.startsWith('clubDetail:') ||
          key.startsWith('sponsorStores:') ||
          key.startsWith('gamificationConfig:') ||
          key.startsWith('gamificationCareer:') ||
          key.startsWith('referralSummary:') ||
          key.startsWith('transferWindow:'),
    );
    _inFlight.removeWhere(
      (key, _) =>
          key.startsWith('leaderboard:') ||
          key.startsWith('clubDetail:') ||
          key.startsWith('sponsorStores:') ||
          key.startsWith('gamificationConfig:') ||
          key.startsWith('gamificationCareer:') ||
          key.startsWith('referralSummary:') ||
          key.startsWith('transferWindow:'),
    );
    _persisted.removeWhere(
      (key, _) =>
          key.startsWith('leaderboard:') ||
          key.startsWith('clubDetail:') ||
          key.startsWith('sponsorStores:') ||
          key.startsWith('gamificationConfig:') ||
          key.startsWith('gamificationCareer:') ||
          key.startsWith('referralSummary:') ||
          key.startsWith('transferWindow:'),
    );
    _schedulePersist();
  }

  void invalidateHomeBundle(int clubId, {int? teamId}) {
    invalidate('pointsSummary');
    invalidate(leaderboardKey(clubId));
    invalidate(gamificationConfigKey(clubId));
    invalidate(gamificationCareerKey(clubId, teamId));
    invalidate('referralSummary:$clubId');
  }

  void _store(
    String key,
    dynamic value,
    Duration ttl, {
    String? codec,
    Object? persistData,
  }) {
    final expiresAt = DateTime.now().add(ttl);
    _cache[key] = _CacheEntry(value, expiresAt);
    if (codec != null && persistData != null) {
      _persisted[key] = DugnadPersistedEntry(
        codec: codec,
        data: persistData,
        expiresAt: expiresAt,
      );
      _schedulePersist();
    }
  }

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 400), () {
      unawaited(DugnadCachePersistence.save(entries: Map.of(_persisted)));
    });
  }

  Future<T?> _getOrFetch<T>({
    required String key,
    required Duration ttl,
    required Future<T?> Function() fetch,
    bool forceRefresh = false,
    String? persistCodec,
    Future<({T? value, Object? persistData})> Function()? fetchWithPersist,
  }) async {
    final now = DateTime.now();
    final cached = _cache[key];

    if (!forceRefresh && cached != null && cached.isFresh(now)) {
      return cached.value as T?;
    }

    if (!forceRefresh && cached != null) {
      unawaited(_fetchDeduped<T>(
        key,
        ttl,
        fetch,
        persistCodec: persistCodec,
        fetchWithPersist: fetchWithPersist,
      ));
      return cached.value as T?;
    }

    return _fetchDeduped<T>(
      key,
      ttl,
      fetch,
      persistCodec: persistCodec,
      fetchWithPersist: fetchWithPersist,
    );
  }

  Future<T?> _fetchDeduped<T>(
    String key,
    Duration ttl,
    Future<T?> Function() fetch, {
    String? persistCodec,
    Future<({T? value, Object? persistData})> Function()? fetchWithPersist,
  }) async {
    final existing = _inFlight[key];
    if (existing != null) {
      return existing as Future<T?>;
    }

    final future = _fetchAndStore<T>(
      key,
      ttl,
      fetch,
      persistCodec: persistCodec,
      fetchWithPersist: fetchWithPersist,
    );
    _inFlight[key] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(key);
    }
  }

  Future<T?> _fetchAndStore<T>(
    String key,
    Duration ttl,
    Future<T?> Function() fetch, {
    String? persistCodec,
    Future<({T? value, Object? persistData})> Function()? fetchWithPersist,
  }) async {
    try {
      if (fetchWithPersist != null) {
        final result = await fetchWithPersist();
        final value = result.value;
        if (value != null) {
          _store(
            key,
            value,
            ttl,
            codec: persistCodec,
            persistData: result.persistData,
          );
        }
        return value;
      }

      final value = await fetch();
      if (value != null) {
        _store(key, value, ttl);
      }
      return value;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DugnadDataCache] fetch failed for $key: $e');
      }
      return null;
    }
  }

  Future<List<ClubListItem>> getClubList({bool forceRefresh = false}) async {
    const ttl = Duration(minutes: 15);
    final clubs = await _getOrFetch<List<ClubListItem>>(
      key: 'clubList',
      ttl: ttl,
      forceRefresh: forceRefresh,
      persistCodec: 'clubList',
      fetchWithPersist: () async {
        final raw = await _repo.listClubs();
        if (raw is Map && raw['status'] == 1) {
          final list = (raw['clubs'] as List? ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          final parsed =
              list.map((e) => ClubListItem.fromJson(e)).toList(growable: false);
          return (value: parsed, persistData: list);
        }
        return (value: null, persistData: null);
      },
      fetch: () async => null,
    );
    return clubs ?? const [];
  }

  Future<ClubDetail?> getClubDetail(
    int clubId, {
    bool forceRefresh = false,
  }) async {
    const ttl = Duration(minutes: 15);
    return _getOrFetch<ClubDetail?>(
      key: clubDetailKey(clubId),
      ttl: ttl,
      forceRefresh: forceRefresh,
      persistCodec: 'clubDetail',
      fetchWithPersist: () async {
        final response = await _repo.getClubDetail(clubId);
        if (response is Map && response['status'] == 1) {
          final club = response['club'];
          if (club is Map) {
            final map = Map<String, dynamic>.from(club);
            return (
              value: ClubDetail.fromJson(map),
              persistData: map,
            );
          }
        }
        return (value: null, persistData: null);
      },
      fetch: () async => null,
    );
  }

  Future<List<SponsorStore>?> getSponsorStores(
    int clubId, {
    bool forceRefresh = false,
  }) async {
    const ttl = Duration(minutes: 15);
    return _getOrFetch<List<SponsorStore>?>(
      key: sponsorStoresKey(clubId),
      ttl: ttl,
      forceRefresh: forceRefresh,
      persistCodec: 'sponsorStores',
      fetchWithPersist: () async {
        final response = await _repo.getSponsorStores(clubId);
        if (response is Map && response['status'] == 1) {
          final list = (response['stores'] as List? ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          final parsed =
              list.map((e) => SponsorStore.fromJson(e)).toList(growable: false);
          return (value: parsed, persistData: list);
        }
        return (value: null, persistData: null);
      },
      fetch: () async => null,
    );
  }

  Future<PointsSummary?> getPointsSummary({bool forceRefresh = false}) {
    const ttl = Duration(seconds: 60);
    return _getOrFetch<PointsSummary?>(
      key: 'pointsSummary',
      ttl: ttl,
      forceRefresh: forceRefresh,
      persistCodec: 'pointsSummary',
      fetchWithPersist: () async {
        if (!isLoggedIn()) return (value: null, persistData: null);
        try {
          final response = await _repo.getPointsSummaryRaw();
          if (response is Map && response['status'] == 1) {
            final summary = response['summary'];
            final points = response['points'];
            if (summary is Map) {
              final merged = Map<String, dynamic>.from(summary);
              if (points is Map) {
                final cpp = points['campaign_purchase_points'];
                if (cpp != null) merged['campaign_purchase_points'] = cpp;
              }
              return (
                value: PointsSummary.fromJson(merged),
                persistData: merged,
              );
            }
          }
        } catch (_) {}
        return (value: null, persistData: null);
      },
      fetch: () async => null,
    );
  }

  Future<LeaderboardData?> getLeaderboard(
    int clubId, {
    bool forceRefresh = false,
  }) =>
      _getOrFetch<LeaderboardData?>(
        key: leaderboardKey(clubId),
        ttl: const Duration(seconds: 120),
        forceRefresh: forceRefresh,
        persistCodec: 'leaderboard',
        fetchWithPersist: () async {
          final response = await _repo.getLeaderboardRaw(clubId);
          if (response is Map && response['status'] == 1) {
            final board = response['leaderboard'];
            if (board is Map) {
              final map = Map<String, dynamic>.from(board);
              return (
                value: LeaderboardData.fromJson(map),
                persistData: map,
              );
            }
          }
          return (value: null, persistData: null);
        },
        fetch: () async => null,
      );

  Future<GamificationConfig?> getGamificationConfig({
    required int organizationId,
    int? teamId,
    bool forceRefresh = false,
  }) =>
      _getOrFetch<GamificationConfig?>(
        key: gamificationConfigKey(organizationId),
        ttl: const Duration(hours: 1),
        forceRefresh: forceRefresh,
        persistCodec: 'gamificationConfig',
        fetchWithPersist: () async {
          final response = await _repo.getGamificationConfigRaw(
            organizationId: organizationId,
            teamId: teamId,
          );
          if (response is Map && response['status'] == 1) {
            final map = Map<String, dynamic>.from(response);
            return (
              value: GamificationConfig.fromJson(map),
              persistData: map,
            );
          }
          return (value: null, persistData: null);
        },
        fetch: () async => null,
      );

  Future<TransferWindowContext?> getTransferWindow({
    bool forceRefresh = false,
  }) {
    final clubId = DugnadState.instance.clubId;
    return _getOrFetch<TransferWindowContext?>(
      key: transferWindowKey(clubId),
      ttl: const Duration(minutes: 3),
      forceRefresh: forceRefresh,
      fetch: () => _repo.getTransferWindow(),
    );
  }

  Future<GamificationCareer?> getGamificationCareer({
    required int organizationId,
    int? teamId,
    bool forceRefresh = false,
  }) =>
      _getOrFetch<GamificationCareer?>(
        key: gamificationCareerKey(organizationId, teamId),
        ttl: const Duration(seconds: 60),
        forceRefresh: forceRefresh,
        persistCodec: 'gamificationCareer',
        fetchWithPersist: () async {
          if (!isLoggedIn()) return (value: null, persistData: null);
          final response = await _repo.getGamificationCareerRaw(
            organizationId: organizationId,
            teamId: teamId,
          );
          if (response is Map && response['status'] == 1) {
            final career = response['career'];
            if (career is Map) {
              final map = Map<String, dynamic>.from(career);
              return (
                value: GamificationCareer.fromJson(map),
                persistData: map,
              );
            }
          }
          return (value: null, persistData: null);
        },
        fetch: () async => null,
      );

  Future<ReferralSummary?> getReferralSummary({
    required int organizationId,
    bool forceRefresh = false,
  }) =>
      _getOrFetch<ReferralSummary?>(
        key: 'referralSummary:$organizationId',
        ttl: const Duration(seconds: 60),
        forceRefresh: forceRefresh,
        persistCodec: 'referralSummary',
        fetchWithPersist: () async {
          if (!isLoggedIn()) return (value: null, persistData: null);
          final response = await _repo.getReferralSummaryRaw(
            organizationId: organizationId,
          );
          if (response is Map && response['status'] == 1) {
            final summary = response['summary'];
            if (summary is Map) {
              final map = Map<String, dynamic>.from(summary);
              return (
                value: ReferralSummary.fromJson(map),
                persistData: map,
              );
            }
          }
          return (value: null, persistData: null);
        },
        fetch: () async => null,
      );

  /// Warm home tab data; returns the same tuple shape as DGHome._loadData.
  Future<DugnadHomeBundle> loadHomeBundle({
    required int clubId,
    required bool loggedIn,
    int? teamId,
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      invalidateHomeBundle(clubId, teamId: teamId);
    }

    final bundled = await _tryLoadHomeBundleFromApi(
      clubId: clubId,
      loggedIn: loggedIn,
      teamId: teamId,
    );
    if (bundled != null) return bundled;

    final results = await Future.wait<dynamic>([
      getClubList(forceRefresh: forceRefresh),
      getClubDetail(clubId, forceRefresh: forceRefresh),
      getSponsorStores(clubId, forceRefresh: forceRefresh),
      DugnadState.instance.syncPointsTeamFromServer().catchError((_) => null),
      if (loggedIn)
        getPointsSummary(forceRefresh: forceRefresh)
      else
        Future.value(null),
      if (loggedIn)
        getLeaderboard(clubId, forceRefresh: forceRefresh)
      else
        Future.value(null),
      getGamificationConfig(
        organizationId: clubId,
        teamId: teamId,
        forceRefresh: forceRefresh,
      ),
      if (loggedIn)
        getGamificationCareer(
          organizationId: clubId,
          teamId: teamId,
          forceRefresh: forceRefresh,
        )
      else
        Future.value(null),
      if (loggedIn)
        getReferralSummary(
          organizationId: clubId,
          forceRefresh: forceRefresh,
        )
      else
        Future.value(null),
    ]);

    return DugnadHomeBundle(
      clubs: results[0] as List<ClubListItem>? ?? const [],
      clubDetail: results[1] as ClubDetail?,
      sponsors: results[2] as List<SponsorStore>? ?? const [],
      pointsSummary: results[4] as PointsSummary?,
      leaderboard: results[5] as LeaderboardData?,
      gamificationConfig: results[6] as GamificationConfig?,
      gamificationCareer: results[7] as GamificationCareer?,
      referralSummary: results[8] as ReferralSummary?,
    );
  }

  Future<DugnadHomeBundle?> _tryLoadHomeBundleFromApi({
    required int clubId,
    required bool loggedIn,
    int? teamId,
  }) async {
    try {
      final response = await _repo.getHomeBundleRaw(
        clubId: clubId,
        teamId: teamId,
      );
      if (response is! Map || response['status'] != 1) return null;

      final bundle = response['bundle'];
      if (bundle is! Map) return null;

      const clubListTtl = Duration(minutes: 15);
      const clubDetailTtl = Duration(minutes: 15);
      const sponsorTtl = Duration(minutes: 15);
      const pointsTtl = Duration(seconds: 60);
      const leaderboardTtl = Duration(seconds: 120);
      const configTtl = Duration(hours: 1);
      const careerTtl = Duration(seconds: 60);
      const referralTtl = Duration(seconds: 60);

      List<ClubListItem> clubs = const [];
      final clubsRaw = bundle['clubs'];
      if (clubsRaw is List) {
        final list = clubsRaw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        clubs = list.map(ClubListItem.fromJson).toList(growable: false);
        _store('clubList', clubs, clubListTtl, codec: 'clubList', persistData: list);
      }

      ClubDetail? clubDetail;
      final clubRaw = bundle['club'];
      if (clubRaw is Map) {
        final map = Map<String, dynamic>.from(clubRaw);
        clubDetail = ClubDetail.fromJson(map);
        _store(
          clubDetailKey(clubId),
          clubDetail,
          clubDetailTtl,
          codec: 'clubDetail',
          persistData: map,
        );
      }

      List<SponsorStore> sponsors = const [];
      final storesRaw = bundle['sponsor_stores'];
      if (storesRaw is List) {
        final list = storesRaw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        sponsors = list.map(SponsorStore.fromJson).toList(growable: false);
        _store(
          sponsorStoresKey(clubId),
          sponsors,
          sponsorTtl,
          codec: 'sponsorStores',
          persistData: list,
        );
      }

      LeaderboardData? leaderboard;
      final boardRaw = bundle['leaderboard'];
      if (boardRaw is Map) {
        final map = Map<String, dynamic>.from(boardRaw);
        leaderboard = LeaderboardData.fromJson(map);
        _store(
          leaderboardKey(clubId),
          leaderboard,
          leaderboardTtl,
          codec: 'leaderboard',
          persistData: map,
        );
      }

      GamificationConfig? gamificationConfig;
      final configRaw = bundle['gamification_config'];
      if (configRaw is Map) {
        final map = Map<String, dynamic>.from(configRaw);
        gamificationConfig = GamificationConfig.fromJson(map);
        _store(
          gamificationConfigKey(clubId),
          gamificationConfig,
          configTtl,
          codec: 'gamificationConfig',
          persistData: map,
        );
      }

      PointsSummary? pointsSummary;
      GamificationCareer? gamificationCareer;
      ReferralSummary? referralSummary;

      if (loggedIn) {
        final summaryRaw = bundle['points_summary'];
        final pointsRaw = bundle['points'];
        if (summaryRaw is Map) {
          final merged = Map<String, dynamic>.from(summaryRaw);
          if (pointsRaw is Map) {
            final cpp = pointsRaw['campaign_purchase_points'];
            if (cpp != null) merged['campaign_purchase_points'] = cpp;
          }
          pointsSummary = PointsSummary.fromJson(merged);
          _store(
            'pointsSummary',
            pointsSummary,
            pointsTtl,
            codec: 'pointsSummary',
            persistData: merged,
          );
        }

        final careerRaw = bundle['career'];
        if (careerRaw is Map) {
          final map = Map<String, dynamic>.from(careerRaw);
          gamificationCareer = GamificationCareer.fromJson(map);
          _store(
            gamificationCareerKey(clubId, teamId),
            gamificationCareer,
            careerTtl,
            codec: 'gamificationCareer',
            persistData: map,
          );
        }

        final referralRaw = bundle['referral_summary'];
        if (referralRaw is Map) {
          final map = Map<String, dynamic>.from(referralRaw);
          referralSummary = ReferralSummary.fromJson(map);
          _store(
            'referralSummary:$clubId',
            referralSummary,
            referralTtl,
            codec: 'referralSummary',
            persistData: map,
          );
        }
      }

      unawaited(DugnadState.instance.syncPointsTeamFromServer().catchError((_) => null));

      return DugnadHomeBundle(
        clubs: clubs,
        clubDetail: clubDetail,
        sponsors: sponsors,
        pointsSummary: pointsSummary,
        leaderboard: leaderboard,
        gamificationConfig: gamificationConfig,
        gamificationCareer: gamificationCareer,
        referralSummary: referralSummary,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DugnadDataCache] home-bundle failed: $e');
      }
      return null;
    }
  }
}

class DugnadHomeBundle {
  const DugnadHomeBundle({
    this.clubs = const [],
    this.clubDetail,
    this.sponsors = const [],
    this.pointsSummary,
    this.leaderboard,
    this.gamificationConfig,
    this.gamificationCareer,
    this.referralSummary,
  });

  final List<ClubListItem> clubs;
  final ClubDetail? clubDetail;
  final List<SponsorStore> sponsors;
  final PointsSummary? pointsSummary;
  final LeaderboardData? leaderboard;
  final GamificationConfig? gamificationConfig;
  final GamificationCareer? gamificationCareer;
  final ReferralSummary? referralSummary;
}
