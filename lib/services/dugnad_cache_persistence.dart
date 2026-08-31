import 'dart:convert';

import '../screens/dugnad/dugnad_state.dart';
import '../screens/dugnad/gamification_models.dart';
import '../screens/dugnad/dugnad_models.dart';
import '../utils/utils.dart';

/// Disk snapshot for [DugnadDataCache] — cold-start stale-while-revalidate.
class DugnadCachePersistence {
  DugnadCachePersistence._();

  static const int _version = 1;

  static Future<void> save({
    required Map<String, DugnadPersistedEntry> entries,
  }) async {
    final clubId = DugnadState.instance.clubId;
    if (clubId <= 0 || entries.isEmpty) return;

    final payload = <String, dynamic>{
      'v': _version,
      'userId': isLoggedIn() ? prefGetInt(prefUserId) : 0,
      'clubId': clubId,
      'teamId': prefGetInt(prefPointsTeamId),
      'savedAt': DateTime.now().toIso8601String(),
      'entries': entries.map(
        (key, entry) => MapEntry(key, entry.toJson()),
      ),
    };

    await prefSetString(prefDugnadDataCacheSnapshot, jsonEncode(payload));
  }

  static Future<DugnadCacheSnapshot?> load() async {
    final raw = prefGetString(prefDugnadDataCacheSnapshot);
    if (raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      if ((decoded['v'] as num?)?.toInt() != _version) return null;

      final entriesRaw = decoded['entries'];
      if (entriesRaw is! Map) return null;

      final entries = <String, DugnadPersistedEntry>{};
      for (final entry in entriesRaw.entries) {
        if (entry.value is! Map) continue;
        final parsed = DugnadPersistedEntry.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
        if (parsed != null) entries[entry.key] = parsed;
      }
      if (entries.isEmpty) return null;

      return DugnadCacheSnapshot(
        userId: (decoded['userId'] as num?)?.toInt() ?? 0,
        clubId: (decoded['clubId'] as num?)?.toInt() ?? 0,
        teamId: (decoded['teamId'] as num?)?.toInt() ?? 0,
        entries: entries,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    await prefRemove(prefDugnadDataCacheSnapshot);
  }

  static bool matchesCurrentScope(DugnadCacheSnapshot snapshot) {
    final clubId = DugnadState.instance.clubId;
    if (clubId <= 0 || snapshot.clubId != clubId) return false;

    final userId = isLoggedIn() ? prefGetInt(prefUserId) : 0;
    if (snapshot.userId != userId) return false;

    return snapshot.teamId == prefGetInt(prefPointsTeamId);
  }
}

class DugnadCacheSnapshot {
  const DugnadCacheSnapshot({
    required this.userId,
    required this.clubId,
    required this.teamId,
    required this.entries,
  });

  final int userId;
  final int clubId;
  final int teamId;
  final Map<String, DugnadPersistedEntry> entries;
}

class DugnadPersistedEntry {
  const DugnadPersistedEntry({
    required this.codec,
    required this.data,
    required this.expiresAt,
  });

  final String codec;
  final Object data;
  final DateTime expiresAt;

  bool get isFresh => DateTime.now().isBefore(expiresAt);

  Map<String, dynamic> toJson() => {
        'codec': codec,
        'data': data,
        'expiresAt': expiresAt.toIso8601String(),
      };

  static DugnadPersistedEntry? fromJson(Map<String, dynamic> json) {
    final codec = json['codec'] as String?;
    final data = json['data'];
    final expiresRaw = json['expiresAt'] as String?;
    if (codec == null || codec.isEmpty || data == null || expiresRaw == null) {
      return null;
    }
    final expiresAt = DateTime.tryParse(expiresRaw);
    if (expiresAt == null) return null;
    return DugnadPersistedEntry(codec: codec, data: data, expiresAt: expiresAt);
  }
}

/// Decode persisted JSON payloads back into cache value types.
dynamic decodeDugnadCacheValue(String codec, Object data) {
  try {
    switch (codec) {
      case 'clubList':
        if (data is! List) return null;
        return data
            .whereType<Map>()
            .map((e) => ClubListItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      case 'clubDetail':
        if (data is! Map) return null;
        return ClubDetail.fromJson(Map<String, dynamic>.from(data));
      case 'sponsorStores':
        if (data is! List) return null;
        return data
            .whereType<Map>()
            .map((e) => SponsorStore.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      case 'pointsSummary':
        if (data is! Map) return null;
        return PointsSummary.fromJson(Map<String, dynamic>.from(data));
      case 'leaderboard':
        if (data is! Map) return null;
        return LeaderboardData.fromJson(Map<String, dynamic>.from(data));
      case 'gamificationConfig':
        if (data is! Map) return null;
        return GamificationConfig.fromJson(Map<String, dynamic>.from(data));
      case 'gamificationCareer':
        if (data is! Map) return null;
        return GamificationCareer.fromJson(Map<String, dynamic>.from(data));
      case 'referralSummary':
        if (data is! Map) return null;
        return ReferralSummary.fromJson(Map<String, dynamic>.from(data));
      default:
        return null;
    }
  } catch (_) {
    return null;
  }
}
