import 'dugnad_models.dart';

class TransferWindowContext {
  final bool enabled;
  final bool windowOpen;
  final int? daysRemaining;
  final bool autoPromoteEnabled;
  final TransferClubInfo? club;
  final ClubTeamItem? currentTeam;
  final TransferPromotion promotion;
  final List<ClubTeamItem> clubTeams;
  final TransferOptions options;

  const TransferWindowContext({
    this.enabled = false,
    this.windowOpen = false,
    this.daysRemaining,
    this.autoPromoteEnabled = false,
    this.club,
    this.currentTeam,
    this.promotion = const TransferPromotion(),
    this.clubTeams = const [],
    this.options = const TransferOptions(),
  });

  factory TransferWindowContext.fromJson(Map<String, dynamic> json) {
    final currentRaw = json['current_team'];
    final clubRaw = json['club'];
    final promoRaw = json['promotion'];
    final windowRaw = json['transfer_window'];
    final window = windowRaw is Map
        ? Map<String, dynamic>.from(windowRaw)
        : const <String, dynamic>{};

    return TransferWindowContext(
      enabled: json['enabled'] == true,
      windowOpen: json['window_open'] == true,
      daysRemaining: (json['days_remaining'] as num?)?.toInt(),
      autoPromoteEnabled: window['auto_promote_enabled'] == true,
      club: clubRaw is Map
          ? TransferClubInfo.fromJson(Map<String, dynamic>.from(clubRaw))
          : null,
      currentTeam: currentRaw is Map
          ? ClubTeamItem.fromJson(Map<String, dynamic>.from(currentRaw))
          : null,
      promotion: promoRaw is Map
          ? TransferPromotion.fromJson(Map<String, dynamic>.from(promoRaw))
          : const TransferPromotion(),
      clubTeams: (json['club_teams'] as List? ?? [])
          .whereType<Map>()
          .map((e) => ClubTeamItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      options: json['options'] is Map
          ? TransferOptions.fromJson(
              Map<String, dynamic>.from(json['options'] as Map),
            )
          : const TransferOptions(),
    );
  }

  String get currentTeamName => currentTeam?.name ?? '';
  String get nextTeamName => promotion.nextTeam?.name ?? '';
  String get clubShortName => club?.shortName?.isNotEmpty == true
      ? club!.shortName!
      : (club?.name ?? '');
}

class TransferClubInfo {
  final int id;
  final String name;
  final String? shortName;

  const TransferClubInfo({
    required this.id,
    required this.name,
    this.shortName,
  });

  factory TransferClubInfo.fromJson(Map<String, dynamic> json) {
    return TransferClubInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      shortName: json['short_name']?.toString(),
    );
  }
}

class TransferPromotion {
  final bool available;
  final String? fromLabel;
  final String? toLabel;
  final ClubTeamItem? nextTeam;

  const TransferPromotion({
    this.available = false,
    this.fromLabel,
    this.toLabel,
    this.nextTeam,
  });

  factory TransferPromotion.fromJson(Map<String, dynamic> json) {
    final nextRaw = json['next_team'];
    return TransferPromotion(
      available: json['available'] == true,
      fromLabel: json['from_label']?.toString(),
      toLabel: json['to_label']?.toString(),
      nextTeam: nextRaw is Map
          ? ClubTeamItem.fromJson(Map<String, dynamic>.from(nextRaw))
          : null,
    );
  }
}

class TransferOptions {
  final bool moveUp;
  final bool stay;
  final bool teamSwitch;
  final bool clubChange;

  const TransferOptions({
    this.moveUp = false,
    this.stay = false,
    this.teamSwitch = false,
    this.clubChange = false,
  });

  factory TransferOptions.fromJson(Map<String, dynamic> json) {
    bool flag(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';
    return TransferOptions(
      moveUp: flag(json['move_up']),
      stay: flag(json['stay']),
      teamSwitch: flag(json['team_switch']),
      clubChange: flag(json['club_change']),
    );
  }
}

class TransferCommitResult {
  final String? action;
  final int? teamId;
  final String? teamName;
  final PointsTeamProfile? points;

  const TransferCommitResult({
    this.action,
    this.teamId,
    this.teamName,
    this.points,
  });

  factory TransferCommitResult.fromJson(
    Map<String, dynamic> json, {
    PointsTeamProfile? points,
  }) {
    final result = json['result'];
    if (result is! Map) {
      return TransferCommitResult(points: points);
    }
    final map = Map<String, dynamic>.from(result);
    return TransferCommitResult(
      action: map['action']?.toString(),
      teamId: (map['team_id'] as num?)?.toInt(),
      teamName: map['team_name']?.toString(),
      points: points,
    );
  }
}
