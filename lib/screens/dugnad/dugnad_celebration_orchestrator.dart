import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../utils/global_loading_overlay.dart';
import '../../utils/utils.dart';
import 'celebration_debug_flags.dart';
import 'celebration_models.dart';
import 'dugnad_formen_screen.dart';
import 'dugnad_missions_screen.dart';
import 'dugnad_points_screen.dart';
import 'dugnad_repo.dart';
import 'dugnad_state.dart';
import 'leaderboard_screen.dart';
import 'season_recap_screen.dart';
import 'supporter_card_screen.dart';
import 'tour/dugnad_tour_controller.dart';
import 'tour/dugnad_tour_overlay.dart';
import 'tour/dugnad_tour_prompt.dart';
import 'widgets/dugnad_celebration_overlay.dart';
import 'widgets/dugnad_celebration_route.dart';
import 'widgets/dugnad_points_pop.dart';

/// Global celebration queue — fetches pending server rows and shows one at a time.
class DugnadCelebrationOrchestrator {
  DugnadCelebrationOrchestrator._();

  static final DugnadCelebrationOrchestrator instance =
      DugnadCelebrationOrchestrator._();

  final DugnadRepo _repo = DugnadRepo();

  List<PendingCelebration> _pending = [];
  CelebrationConfig _config = const CelebrationConfig();
  int _shownThisSession = 0;
  int _criticalHold = 0;
  bool _busy = false;
  bool _fetching = false;
  bool _debugBypassCap = false;
  int _debugIdSeq = 0;
  OverlayEntry? _entry;
  final Set<int> _inFlightIds = {};

  CelebrationConfig get config => _config;
  int get shownThisSession => _shownThisSession;
  bool get isBusy => _busy;

  @visibleForTesting
  List<PendingCelebration> get debugPending => List.unmodifiable(_pending);

  /// True while a celebration is on screen, still queued, or still being
  /// fetched. The home-entry prompts wait this out: the tour invite is a root
  /// Overlay entry and the referral nudge a modal sheet, so both paint AND
  /// hit-test above every route — over a ceremonial (T13/T14) they hide the
  /// ceremony and swallow its close button.
  bool get hasQueuedOrActive => _busy || _fetching || _pending.isNotEmpty;

  /// Resolves once [hasQueuedOrActive] clears. Gives up after [timeout] so a
  /// stuck celebration can never suppress the prompts for the whole session.
  Future<void> waitUntilIdle({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (hasQueuedOrActive && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 32));
    }
  }

  /// Public, read-only view of [_blocked] so other passive UI (the campaign
  /// tracker pill) can hide under the SAME suppression rule celebrations use,
  /// without duplicating the three-way check.
  bool get isBlocked => _blocked;

  /// Live signal for the same state. Updated whenever the critical-flow count
  /// changes (checkout / onboarding); [refreshBlockedState] also lets a listener
  /// re-sync for tour/loading transitions it can't observe directly.
  final ValueNotifier<bool> _blockedNotifier = ValueNotifier<bool>(false);
  ValueListenable<bool> get blockedListenable => _blockedNotifier;

  /// Recompute [_blocked] into [blockedListenable]. Cheap; call when a
  /// suppression input may have changed.
  void refreshBlockedState() {
    final v = _blocked;
    if (_blockedNotifier.value != v) _blockedNotifier.value = v;
  }

  void holdCriticalFlow() {
    _criticalHold++;
    refreshBlockedState();
  }

  void releaseCriticalFlow() {
    if (_criticalHold > 0) _criticalHold--;
    refreshBlockedState();
    unawaited(pump());
  }

  bool get _blocked {
    // T1 is inline on the home card. Every queued popup (T2–T16) can surface
    // on any screen — only hold during checkout / onboarding / tour / loading.
    if (_criticalHold > 0) return true;
    if (DugnadTourController.active != null) return true;
    if (isGlobalLoadingOverlayVisible) return true;
    return false;
  }

  /// Drop every trace of the previous account's queue. The orchestrator is a
  /// process-wide singleton, so without this the next login inherits a stuck
  /// [_busy], a leaked [_criticalHold], a spent session cap, and — worst — an
  /// [_entry] still sitting in the root Overlay above every new route.
  void resetForLogout() {
    _removeOverlay();
    _pending.clear();
    _inFlightIds.clear();
    _busy = false;
    _fetching = false;
    _shownThisSession = 0;
    _criticalHold = 0;
    _debugBypassCap = false;
    refreshBlockedState();
  }

  /// Dev / local preview — negative ids skip server consume.
  void debugEnqueue(PendingCelebration item) {
    if (!item.type.isQueuedModal) return;
    _debugBypassCap = CelebrationDebugFlags.bypassSessionCap;
    final id = item.id < 0 ? item.id : _nextDebugId();
    _pending.insert(
      0,
      PendingCelebration(
        id: id,
        type: item.type,
        clubId: item.clubId,
        payload: item.payload,
        priority: item.priority != 0 ? item.priority : item.type.priority,
        createdAt: item.createdAt,
        consumedAt: item.consumedAt,
      ),
    );
    unawaited(pump());
  }

  int _nextDebugId() {
    _debugIdSeq -= 1;
    return _debugIdSeq;
  }

  /// Drop local queue state and dismiss any visible overlay.
  void debugClearLocalQueue() {
    _removeOverlay();
    _pending.clear();
    _inFlightIds.clear();
    _busy = false;
    _shownThisSession = 0;
    _debugBypassCap = false;
  }

  /// Clear local queue and consume all server-side pending rows for [clubId].
  Future<void> debugClearAll({int? clubId}) async {
    debugClearLocalQueue();
    final id = clubId ?? DugnadState.instance.clubId;
    if (id > 0 && isLoggedIn()) {
      await _repo.clearDevCelebrations(clubId: id);
    }
  }

  Future<void> sync({int? clubId}) async {
    if (!isLoggedIn()) return;
    final id = clubId ?? DugnadState.instance.clubId;
    if (id <= 0) return;
    if (_fetching) return;
    _fetching = true;
    try {
      final response = await _repo.fetchPendingCelebrations(clubId: id);
      if (response == null) return;
      _config = response.config;
      final sorted = collapseTransitionDuplicates(
        sortCelebrationsByPriority(response.celebrations),
      );
      _consumeCollapsedDuplicates(response.celebrations, sorted);
      final serverPending = sorted
          .where((e) => e.id > 0 && !_inFlightIds.contains(e.id))
          .toList();
      // Keep local debug previews (negative ids) — sync must not wipe them.
      final localDebug =
          _pending.where((e) => e.id < 0).toList(growable: false);
      _pending = [...localDebug, ...serverPending];
    } finally {
      _fetching = false;
    }
    await pump();
  }

  void _consumeCollapsedDuplicates(
    List<PendingCelebration> original,
    List<PendingCelebration> kept,
  ) {
    final keptIds = kept.map((e) => e.id).toSet();
    for (final item in original) {
      if (item.id <= 0) continue;
      if (item.type != CelebrationType.t13 &&
          item.type != CelebrationType.t14 &&
          item.type != CelebrationType.t16) {
        continue;
      }
      if (keptIds.contains(item.id)) continue;
      unawaited(_repo.consumeCelebration(item.id));
    }
  }

  /// Welcome screen is the T14 presenter — consume without a second overlay.
  Future<void> consumeTypeIfPending(CelebrationType type) async {
    final match = _pending.where((e) => e.type == type).toList();
    for (final item in match) {
      _pending.removeWhere((e) => e.id == item.id);
      unawaited(_repo.consumeCelebration(item.id));
    }
  }

  Future<void> pump() async {
    if (_busy || _pending.isEmpty || _blocked) return;
    final cap = _config.sessionCap;
    if (!_debugBypassCap && _shownThisSession >= cap) return;

    final next = _pending.removeAt(0);
    if (!next.type.isQueuedModal) {
      unawaited(pump());
      return;
    }

    _busy = true;
    _inFlightIds.add(next.id);

    for (var i = 0; i < 180; i++) {
      if (!isGlobalLoadingOverlayVisible && !_blocked) break;
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    if (_blocked) {
      _pending.insert(0, next);
      _inFlightIds.remove(next.id);
      _busy = false;
      return;
    }

    OverlayState? overlay;
    for (var i = 0; i < 30; i++) {
      overlay = navigatorKey.currentState?.overlay;
      if (overlay != null) break;
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    if (overlay == null || !overlay.mounted) {
      _pending.insert(0, next);
      _inFlightIds.remove(next.id);
      _busy = false;
      return;
    }

    // Land the push on a fresh event-loop task. `pump()` is reached from route
    // completers and post-frame callbacks, so pushing straight from here can
    // run inside another Navigator operation — `_pushEntry` then throws
    // `!_debugLocked` and leaves the navigator locked for the rest of the
    // session, which is what stopped the ceremonials from closing.
    await Future<void>.delayed(Duration.zero);
    if (_blocked) {
      _pending.insert(0, next);
      _inFlightIds.remove(next.id);
      _busy = false;
      return;
    }

    _shownThisSession++;
    var settled = false;

    void finish({required bool navigate}) {
      if (settled) return;
      settled = true;
      _removeOverlay();
      _busy = false;
      _inFlightIds.remove(next.id);
      if (next.id > 0) {
        unawaited(_repo.consumeCelebration(next.id));
      }
      if (navigate) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openCta(next);
        });
      }
      // Wait a frame so a pop + next push cannot hit Navigator !_debugLocked.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(pump());
      });
    }

    switch (next.type.presentation) {
      case CelebrationPresentation.fullscreenCeremonial:
        final navContext = navigatorKey.currentContext;
        if (navContext != null && navContext.mounted) {
          await DugnadCelebrationRoute.show(
            navContext,
            item: next,
            onDismiss: () => finish(navigate: false),
            onCta: () => finish(navigate: true),
          );
          if (!settled) finish(navigate: false);
          return;
        }
        break;
      case CelebrationPresentation.modal:
        break;
    }

    final entry = OverlayEntry(
      builder: (context) => DugnadCelebrationOverlay(
        item: next,
        onDismiss: () => finish(navigate: false),
        onCta: () => finish(navigate: true),
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  void _removeOverlay() {
    final entry = _entry;
    _entry = null;
    if (entry == null) return;
    try {
      entry.remove();
    } catch (_) {}
  }

  void _openCta(PendingCelebration item) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    Widget? page;
    switch (item.type) {
      case CelebrationType.t2:
        page = const DugnadPointsScreen();
        break;
      case CelebrationType.t3:
      case CelebrationType.t4:
        page = item.type == CelebrationType.t4
            ? const DugnadFormenScreen()
            : const DugnadMissionsScreen();
        break;
      case CelebrationType.t5a:
      case CelebrationType.t5b:
        page = const LeaderboardScreen();
        break;
      case CelebrationType.t6:
        page = const LeaderboardScreen(openStoTab: true);
        break;
      case CelebrationType.t16:
        page = const SupporterCardScreen();
        break;
      case CelebrationType.t7:
        page = const LeaderboardScreen(openTopScorerTab: true);
        break;
      case CelebrationType.t8:
        page = const LeaderboardScreen(openAssistTab: true);
        break;
      case CelebrationType.t9:
      case CelebrationType.t10:
      case CelebrationType.t11:
      case CelebrationType.t12:
      case CelebrationType.t15:
        page = const SeasonRecapScreen();
        break;
      default:
        return;
    }
    nav.push(MaterialPageRoute<void>(builder: (_) => page!));
  }
}

/// Tear down every dugnad surface that lives in the ROOT Overlay rather than in
/// a route: the celebration queue's own entry, the tour host, the tour invite,
/// the points pop, and the global loader.
///
/// Logout uses `pushAndRemoveUntil`, which clears routes only. An Overlay entry
/// is not a route, so anything still showing at logout survives into the next
/// session — floating above every new route, painting over it and (for the
/// full-screen scrims) swallowing its taps. That is what left the T13/T14
/// ceremonials visible but impossible to close after a log out / log in.
void dugnadResetTransientUi() {
  DugnadTourOverlay.hide();
  DugnadTourPrompt.hide();
  DugnadPointsPop.dismissNow();
  DugnadCelebrationOrchestrator.instance.resetForLogout();
  resetGlobalLoadingOverlay();
}
