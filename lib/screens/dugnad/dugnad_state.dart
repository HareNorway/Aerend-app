import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../services/dugnad_data_cache.dart';
import '../../utils/utils.dart';
import 'dugnad_celebration_orchestrator.dart';
import 'dugnad_club_theme.dart';
import 'dugnad_models.dart';
import 'dugnad_repo.dart';

/// Singleton helper for reading/writing dugnad mode state via SharedPreferences.
///
/// Separate from the server-schedule-driven prefReenSportsMode / prefActiveSportsClubId
/// which are set by HomeBloc from the home API. This state is user-driven (chosen
/// via onboarding / club switcher).
///
/// Exposes [revision] — a [ValueListenable<int>] that increments on every
/// mode/club/membership change so listeners (e.g. HomeMainV1State) can rebuild.
class DugnadState {
  DugnadState._();
  static final DugnadState instance = DugnadState._();

  /// Bumped on every state mutation; listen to rebuild UI.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);
  void _notify() => revision.value++;

  /// Wired from [MyApp] so referrer points pops can use the root overlay
  /// without a circular import through `dugnad_points_pop.dart`.
  void Function(int points)? onReferrerPointsAwarded;
  void Function(int points, String action)? onMissionPointsAwarded;

  Future<void>? _referrerPopInFlight;
  int _pendingReferrerPopPoints = 0;
  final Set<int> _presentedReferralLedgerIds = <int>{};
  final List<_PendingMissionPop> _pendingMissionPops = [];
  final Set<int> _presentedMissionLedgerIds = <int>{};
  bool _homeShellReady = false;

  bool get isHomeShellReady => _homeShellReady;

  // ── Mode ─────────────────────────────────────────────────────────

  bool get isDugnadMode => prefGetBool(prefDugnadModeEnabled);

  Future<void> setDugnadMode(bool enabled) async {
    await prefSetBool(prefDugnadModeEnabled, enabled);
    _notify();
  }

  // ── Selected club ────────────────────────────────────────────────

  bool get hasClub => prefGetInt(prefSelectedClubId) > 0;

  int get clubId => prefGetInt(prefSelectedClubId);
  String get clubName => prefGetString(prefSelectedClubName);
  String get clubShortName => prefGetString(prefSelectedClubShortName);
  String get clubLogo => prefGetString(prefSelectedClubLogo);
  String get clubArea => prefGetString(prefSelectedClubArea);
  String get clubPortalThemeColor =>
      prefGetString(prefSelectedClubPortalThemeColor);
  String get clubPortalBackgroundColor =>
      prefGetString(prefSelectedClubPortalBackgroundColor);

  DugnadClubThemePalette get themePalette => DugnadClubThemePalette.resolve(
        accentColor: clubPortalThemeColor.isEmpty ? null : clubPortalThemeColor,
        backgroundColor:
            clubPortalBackgroundColor.isEmpty ? null : clubPortalBackgroundColor,
      );

  Future<void> selectClub(ClubListItem club) async {
    final previousClubId = clubId;
    final clubChanged = previousClubId != club.id;

    await prefSetInt(prefSelectedClubId, club.id);
    await prefSetString(prefSelectedClubName, club.name);
    await prefSetString(prefSelectedClubShortName, club.shortName ?? '');
    await prefSetString(prefSelectedClubLogo, club.logo ?? '');
    await prefSetString(prefSelectedClubArea, club.area ?? '');
    await prefSetString(
      prefSelectedClubPortalThemeColor,
      club.portalThemeColor ?? '',
    );
    await prefSetString(
      prefSelectedClubPortalBackgroundColor,
      club.portalBackgroundColor ?? '',
    );

    if (clubChanged && previousClubId > 0) {
      await clearPointsTeam(persistOnly: true);
    }

    DugnadDataCache.instance.invalidateClubScoped();

    if (clubChanged && isLoggedIn()) {
      try {
        final profile = await DugnadRepo().setClub(clubId: club.id);
        if (profile != null) {
          await applyPointsTeamProfile(profile);
        }
      } catch (_) {}
    }

    _notify();
    if (clubChanged && isLoggedIn()) {
      unawaited(DugnadCelebrationOrchestrator.instance.sync(clubId: club.id));
    }
  }

  /// Refresh cached branding from a fresher API payload (e.g. after DGHome load).
  Future<void> syncClubBranding({
    String? logo,
    String? area,
    String? name,
    String? shortName,
    String? portalThemeColor,
    String? portalBackgroundColor,
  }) async {
    var changed = false;
    if (name != null && name.isNotEmpty && name != clubName) {
      await prefSetString(prefSelectedClubName, name);
      changed = true;
    }
    if (shortName != null && shortName.isNotEmpty && shortName != clubShortName) {
      await prefSetString(prefSelectedClubShortName, shortName);
      changed = true;
    }
    if (logo != null && logo.isNotEmpty && logo != clubLogo) {
      await prefSetString(prefSelectedClubLogo, logo);
      changed = true;
    }
    if (area != null && area.isNotEmpty && area != clubArea) {
      await prefSetString(prefSelectedClubArea, area);
      changed = true;
    }
    if (portalThemeColor != null && portalThemeColor != clubPortalThemeColor) {
      await prefSetString(prefSelectedClubPortalThemeColor, portalThemeColor);
      changed = true;
    }
    if (portalBackgroundColor != null &&
        portalBackgroundColor != clubPortalBackgroundColor) {
      await prefSetString(
        prefSelectedClubPortalBackgroundColor,
        portalBackgroundColor,
      );
      changed = true;
    }
    if (changed) _notify();
  }

  Future<void>? _syncClubThemeFuture;

  /// Pull portal theme colors from API when prefs are empty or stale.
  /// Concurrent callers share one in-flight request (Account + profile).
  Future<void> syncClubThemeFromApi() {
    if (!isDugnadMode || !hasClub) return Future.value();
    _syncClubThemeFuture ??= _syncClubThemeFromApiImpl().whenComplete(() {
      _syncClubThemeFuture = null;
    });
    return _syncClubThemeFuture!;
  }

  Future<void> _syncClubThemeFromApiImpl() async {
    try {
      final response = await DugnadRepo().getClubDetail(clubId);
      if (response == null || response['status'] != 1) return;
      final club = ClubDetail.fromJson(response['club'] ?? response);
      await syncClubBranding(
        portalThemeColor: club.portalThemeColor ?? '',
        portalBackgroundColor: club.portalBackgroundColor ?? '',
      );
    } catch (_) {}
  }

  Future<void> clearClub() async {
    await prefSetInt(prefSelectedClubId, 0);
    await prefSetString(prefSelectedClubName, '');
    await prefSetString(prefSelectedClubShortName, '');
    await prefSetString(prefSelectedClubLogo, '');
    await prefSetString(prefSelectedClubArea, '');
    await prefSetString(prefSelectedClubPortalThemeColor, '');
    await prefSetString(prefSelectedClubPortalBackgroundColor, '');
    _notify();
  }

  // ── Membership ───────────────────────────────────────────────────

  String get membershipNumber => prefGetString(prefMembershipNumber);
  bool get hasMembership => membershipNumber.trim().isNotEmpty;

  Future<void> setMembershipNumber(String number) async {
    await prefSetString(prefMembershipNumber, number.trim());
    _notify();
  }

  Future<void> clearMembership() async {
    await prefSetString(prefMembershipNumber, '');
    _notify();
  }

  /// When set, Kampanje tab applies this team-name chip filter on next open.
  String? pendingKampanjeTeamFilter;

  void setPendingKampanjeTeamFilter(String? teamName) {
    pendingKampanjeTeamFilter = teamName;
    _notify();
  }

  String? takePendingKampanjeTeamFilter() {
    final value = pendingKampanjeTeamFilter;
    pendingKampanjeTeamFilter = null;
    return value;
  }

  // ── Points team (single team all earned points count toward) ─────

  bool get hasPointsTeam => prefGetInt(prefPointsTeamId) > 0;

  int get pointsTeamId => prefGetInt(prefPointsTeamId);
  String get pointsTeamName => prefGetString(prefPointsTeamName);
  String get pointsTeamLogo => prefGetString(prefPointsTeamLogo);
  String get pointsTeamAgeGroup => prefGetString(prefPointsTeamAgeGroup);
  int get pointsTotal => prefGetInt(prefPointsTotal);

  Future<void> applyPointsTeamProfile(PointsTeamProfile profile) async {
    if (profile.hasPointsTeam &&
        profile.pointsTeamId != null &&
        !_teamBelongsToSelectedClub(profile)) {
      // Server still has a team from another club — do not restore it.
      final nextTotal = profile.lifetimePoints;
      final changed = hasPointsTeam ||
          pointsTeamName.isNotEmpty ||
          pointsTeamLogo.isNotEmpty ||
          pointsTeamAgeGroup.isNotEmpty ||
          pointsTotal != nextTotal;
      if (!changed) return;
      await clearPointsTeam(persistOnly: true);
      await prefSetInt(prefPointsTotal, nextTotal);
      _notify();
      return;
    }

    if (profile.hasPointsTeam && profile.pointsTeamId != null) {
      final previousTeamId = pointsTeamId;
      final nextTeamId = profile.pointsTeamId!;
      final nextName = profile.pointsTeamName ?? '';
      final nextLogo = profile.pointsTeamLogoUrl ?? '';
      final nextAgeGroup = profile.pointsTeamAgeGroup ?? '';
      final nextTotal = profile.totalPoints;
      final changed = previousTeamId != nextTeamId ||
          pointsTeamName != nextName ||
          pointsTeamLogo != nextLogo ||
          pointsTeamAgeGroup != nextAgeGroup ||
          pointsTotal != nextTotal;

      if (!changed) return;

      await prefSetInt(prefPointsTeamId, nextTeamId);
      await prefSetString(prefPointsTeamName, nextName);
      await prefSetString(prefPointsTeamLogo, nextLogo);
      await prefSetString(prefPointsTeamAgeGroup, nextAgeGroup);
      await prefSetInt(prefPointsTotal, nextTotal);
      _notify();
      if (nextTeamId != previousTeamId && nextTeamId > 0 && isLoggedIn()) {
        unawaited(DugnadCelebrationOrchestrator.instance.sync());
      }
      return;
    }

    // Only clear local selection when server explicitly reports none.
    if (!profile.hasPointsTeam) {
      final nextTotal = profile.totalPoints;
      final changed = hasPointsTeam ||
          pointsTeamName.isNotEmpty ||
          pointsTeamLogo.isNotEmpty ||
          pointsTeamAgeGroup.isNotEmpty ||
          pointsTotal != nextTotal;

      if (!changed) return;

      await clearPointsTeam(persistOnly: true);
      await prefSetInt(prefPointsTotal, nextTotal);
      _notify();
    }
  }

  /// Pull points-team selection from backend (logged-in users).
  Future<void> syncPointsTeamFromServer() async {
    if (!isLoggedIn()) return;
    try {
      final repo = DugnadRepo();
      final cursor = _referralPopCursor();
      var profile = await repo.getPointsTeam(
        lastSeenReferralLedgerId: cursor,
        lastSeenMissionLedgerId: _missionPopCursor(),
      );
      if (profile == null) return;
      final referralPopProfile = profile;

      if (profile.hasPointsTeam &&
          hasClub &&
          !_teamBelongsToSelectedClub(profile)) {
        final repaired = await repo.setClub(clubId: clubId);
        if (repaired != null) profile = repaired;
      }

      final clubIdForBonus = profile.organizationId ?? (hasClub ? clubId : null);
      if (profile.lifetimePoints <= 0 &&
          clubIdForBonus != null &&
          clubIdForBonus > 0) {
        final claimed = await repo.claimWelcomeBonus(clubId: clubIdForBonus);
        if (claimed != null && claimed.lifetimePoints > profile.lifetimePoints) {
          profile = claimed;
        }
      }

      await applyPointsTeamProfile(profile);
      await _presentUnseenReferrerPoints(referralPopProfile);
      await _presentUnseenMissionPoints(referralPopProfile);
      unawaited(DugnadCelebrationOrchestrator.instance.sync());
    } catch (_) {}
  }

  bool _teamBelongsToSelectedClub(PointsTeamProfile profile) {
    if (!hasClub) return true;
    final orgId = profile.organizationId;
    if (orgId == null || orgId <= 0) return true;
    return orgId == clubId;
  }

  String _referralPopCursorPref() =>
      '${prefDugnadReferralPopCursor}_${prefGetInt(prefUserId)}';

  String _referralPopReadyPref() =>
      '${prefDugnadReferralPopCursorReady}_${prefGetInt(prefUserId)}';

  String _missionPopCursorPref() =>
      '${prefDugnadMissionPopCursor}_${prefGetInt(prefUserId)}';

  int _referralPopCursor() => prefGetInt(_referralPopCursorPref());

  int _missionPopCursor() => prefGetInt(_missionPopCursorPref());

  Future<void> _presentUnseenReferrerPoints(PointsTeamProfile profile) async {
    _referrerPopInFlight ??= _presentUnseenReferrerPointsImpl(profile);
    try {
      await _referrerPopInFlight;
    } finally {
      _referrerPopInFlight = null;
    }
  }

  Future<void> _presentUnseenReferrerPointsImpl(
    PointsTeamProfile profile,
  ) async {
    final readyKey = _referralPopReadyPref();
    final cursorKey = _referralPopCursorPref();

    final cursor = prefGetInt(cursorKey);
    final unseen = profile.unseenReferralAwards
        .where((e) =>
            e.id > cursor &&
            e.points > 0 &&
            !_presentedReferralLedgerIds.contains(e.id))
        .toList();
    var nextCursor = cursor;
    if (profile.referralPopCursor > nextCursor) {
      nextCursor = profile.referralPopCursor;
    }
    for (final award in unseen) {
      if (award.id > nextCursor) nextCursor = award.id;
    }
    await prefSetInt(cursorKey, nextCursor);
    await prefSetBool(readyKey, true);

    if (unseen.isEmpty) return;

    _presentedReferralLedgerIds.addAll(unseen.map((e) => e.id));

    final total = unseen.fold<int>(0, (sum, e) => sum + e.points);
    if (total <= 0) return;
    _pendingReferrerPopPoints += total;
    _flushPendingReferrerPop();
  }

  Future<void> _presentUnseenMissionPoints(PointsTeamProfile profile) async {
    final cursorKey = _missionPopCursorPref();
    final cursor = prefGetInt(cursorKey);
    final unseen = profile.unseenMissionAwards
        .where((e) =>
            e.id > cursor &&
            e.points > 0 &&
            !_presentedMissionLedgerIds.contains(e.id))
        .toList();
    var nextCursor = cursor;
    if (profile.missionPopCursor > nextCursor) {
      nextCursor = profile.missionPopCursor;
    }
    for (final award in unseen) {
      if (award.id > nextCursor) nextCursor = award.id;
    }
    await prefSetInt(cursorKey, nextCursor);

    if (unseen.isEmpty) return;

    _presentedMissionLedgerIds.addAll(unseen.map((e) => e.id));

    final grouped = <String, int>{};
    for (final award in unseen) {
      grouped[award.action] = (grouped[award.action] ?? 0) + award.points;
    }
    for (final entry in grouped.entries) {
      if (entry.value <= 0) continue;
      _pendingMissionPops.add(
        _PendingMissionPop(points: entry.value, action: entry.key),
      );
    }
    _flushPendingReferrerPop();
  }

  /// Call once the main home shell is on screen (not splash).
  void markHomeShellReady() {
    _homeShellReady = true;
    _flushPendingReferrerPop();
    unawaited(DugnadCelebrationOrchestrator.instance.sync());
  }

  void markHomeShellNotReady() {
    _homeShellReady = false;
  }

  void _flushPendingReferrerPop() {
    if (!_homeShellReady) return;
    final total = _pendingReferrerPopPoints;
    if (total > 0) {
      _pendingReferrerPopPoints = 0;
      onReferrerPointsAwarded?.call(total);
    }
    if (_pendingMissionPops.isEmpty) return;
    final pending = List<_PendingMissionPop>.from(_pendingMissionPops);
    _pendingMissionPops.clear();
    for (final pop in pending) {
      onMissionPointsAwarded?.call(pop.points, pop.action);
    }
  }

  /// Credits the onboarding welcome bonus for [clubId]. Team is not required.
  /// Returns points awarded (0 if skipped / already pending / failed).
  Future<int> claimOnboardingWelcomeBonus({int? clubId}) async {
    if (!isLoggedIn()) return 0;
    final id = clubId ?? (hasClub ? this.clubId : 0);
    if (id <= 0) return 0;
    try {
      final profile = await DugnadRepo().claimWelcomeBonus(clubId: id);
      if (profile == null) return 0;
      await applyPointsTeamProfile(profile);
      final joinPoints = profile.referralJoinPointsAwarded;
      if (joinPoints > 0) {
        await prefSetInt(prefDugnadReferralJoinPoints, joinPoints);
      }
      return profile.welcomeBonusPointsAwarded;
    } catch (_) {
      return 0;
    }
  }

  Future<void> clearPointsTeam({bool persistOnly = false}) async {
    await prefSetInt(prefPointsTeamId, 0);
    await prefSetString(prefPointsTeamName, '');
    await prefSetString(prefPointsTeamLogo, '');
    await prefSetString(prefPointsTeamAgeGroup, '');
    if (!persistOnly) {
      await prefSetInt(prefPointsTotal, 0);
      _notify();
    }
  }

  // ── Convenience ──────────────────────────────────────────────────

  /// Whether the user has completed onboarding (mode chosen + club selected).
  bool get onboardingComplete => isDugnadMode && hasClub;

  /// Whether the guided-tour prompt has already been handled this session. Held
  /// here (not as a screen static) so [reset] clears it on logout/account switch,
  /// otherwise a second account on the same process would never see the prompt.
  bool tourPromptHandledThisSession = false;

  /// Reset all dugnad state (e.g. on logout).
  Future<void> reset() async {
    tourPromptHandledThisSession = false;
    _homeShellReady = false;
    _pendingReferrerPopPoints = 0;
    _pendingMissionPops.clear();
    _presentedMissionLedgerIds.clear();
    // Individual setters already call _notify(); avoid triple-fire by calling
    // prefs directly and notifying once at the end.
    await prefSetBool(prefDugnadModeEnabled, false);
    await prefSetInt(prefSelectedClubId, 0);
    await prefSetString(prefSelectedClubName, '');
    await prefSetString(prefSelectedClubShortName, '');
    await prefSetString(prefSelectedClubLogo, '');
    await prefSetString(prefSelectedClubArea, '');
    await prefSetString(prefSelectedClubPortalThemeColor, '');
    await prefSetString(prefSelectedClubPortalBackgroundColor, '');
    await prefSetString(prefMembershipNumber, '');
    await prefSetInt(prefPointsTeamId, 0);
    await prefSetString(prefPointsTeamName, '');
    await prefSetString(prefPointsTeamLogo, '');
    await prefSetString(prefPointsTeamAgeGroup, '');
    await prefSetInt(prefPointsTotal, 0);
    DugnadDataCache.instance.clearAll();
    _notify();
  }
}

class _PendingMissionPop {
  const _PendingMissionPop({required this.points, required this.action});

  final int points;
  final String action;
}
