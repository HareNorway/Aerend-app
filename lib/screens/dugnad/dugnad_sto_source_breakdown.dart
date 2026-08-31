import 'dart:math';

import 'dugnad_models.dart';

class StoSourcePoints {
  const StoSourcePoints({
    required this.activityPoints,
    required this.campaignPoints,
    required this.badgePoints,
    required this.seasonTotal,
  });

  final int activityPoints;
  final int campaignPoints;
  final int badgePoints;
  final int seasonTotal;
}

StoSourcePoints computeStoSourceBreakdown({
  required List<PointsLedgerEntry> entries,
  required int seasonPoints,
  String? seasonStartsAt,
  String? seasonEndsAt,
}) {
  final seasonStart = _parseSeasonDate(seasonStartsAt);
  final seasonEnd = _parseSeasonDate(seasonEndsAt, endOfDay: true);

  var activity = 0;
  var campaign = 0;
  var badge = 0;

  for (final entry in entries) {
    if (entry.points <= 0 || entry.meta.isReversal) continue;
    if (!_isInSeason(entry.createdAt, seasonStart, seasonEnd)) continue;

    switch (entry.action) {
      case 'campaign_purchase':
        campaign += entry.points;
        break;
      case 'badge_unlock':
        badge += entry.points;
        break;
      default:
        activity += entry.points;
        break;
    }
  }

  final ledgerSum = activity + campaign + badge;
  final total = max(0, seasonPoints);

  if (ledgerSum > 0 && total > 0) {
    if (ledgerSum != total) {
      final scale = total / ledgerSum;
      activity = (activity * scale).round();
      campaign = (campaign * scale).round();
      badge = total - activity - campaign;
    }
  } else if (total > 0) {
    badge = (total * 0.15).round();
    campaign = (total * 0.35).round();
    activity = max(0, total - campaign - badge);
  }

  return StoSourcePoints(
    activityPoints: max(0, activity),
    campaignPoints: max(0, campaign),
    badgePoints: max(0, badge),
    seasonTotal: total,
  );
}

DateTime? _parseSeasonDate(String? raw, {bool endOfDay = false}) {
  if (raw == null || raw.trim().isEmpty) return null;
  final parsed = DateTime.tryParse(raw.trim());
  if (parsed == null) return null;
  if (endOfDay) {
    return DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59);
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

bool _isInSeason(
  String? createdAt,
  DateTime? seasonStart,
  DateTime? seasonEnd,
) {
  if (seasonStart == null && seasonEnd == null) return true;
  if (createdAt == null || createdAt.trim().isEmpty) return true;
  final created = DateTime.tryParse(createdAt.trim());
  if (created == null) return true;
  if (seasonStart != null && created.isBefore(seasonStart)) return false;
  if (seasonEnd != null && created.isAfter(seasonEnd)) return false;
  return true;
}
