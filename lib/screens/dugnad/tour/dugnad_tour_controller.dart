import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../main.dart' show navigatorKey;
import '../../../utils/shared_pref_utill.dart';
import '../dugnad_models.dart';
import '../dugnad_repo.dart';
import '../dugnad_state.dart';
import '../gamification_models.dart';
import '../supporter_card_screen.dart';
import '../widgets/dugnad_points_pop.dart';
import 'dugnad_tour_keys.dart';

/// Which screen a step lives on.
enum DugnadTourScreen { clubHome, playerCard }

/// Card placement hint relative to the spotlight (real geometry lands Chunk 2).
enum DugnadTourPlacement { auto, above, center }

/// One tour step. NO user-facing copy in this chunk — id only.
class DugnadTourStep {
  final String id;

  /// Null target ⇒ centered card, no spotlight (welcome / done).
  final DugnadTourTarget? target;
  final DugnadTourScreen screen;
  final DugnadTourPlacement placement;

  const DugnadTourStep({
    required this.id,
    required this.target,
    required this.screen,
    this.placement = DugnadTourPlacement.auto,
  });

  /// Localised title. [again] only affects `done` (its "again" variant); every
  /// other step falls back to its normal copy on a repeat run.
  String title(AppLocalizations l, {bool again = false}) {
    switch (id) {
      case 'welcome':
        return l.dugnadTourWelcomeTitle;
      case 'team':
        return l.dugnadTourTeamTitle;
      case 'connect':
        return l.dugnadTourConnectTitle;
      case 'earn':
        return l.dugnadTourEarnTitle;
      case 'addr':
        return l.dugnadTourAddrTitle;
      case 'camps':
        return l.dugnadTourCampsTitle;
      case 'donate':
        return l.dugnadTourDonateTitle;
      case 'refer':
        return l.dugnadTourReferTitle;
      case 'comp':
        return l.dugnadTourCompTitle;
      case 'sto':
        return l.dugnadTourStoTitle;
      case 'form':
        return l.dugnadTourFormTitle;
      case 'badges':
        return l.dugnadTourBadgesTitle;
      case 'done':
        return again ? l.dugnadTourDoneAgainTitle : l.dugnadTourDoneTitle;
      default:
        return '';
    }
  }

  /// Localised body. See [title] for the [again] rule.
  String body(AppLocalizations l, {bool again = false}) {
    switch (id) {
      case 'welcome':
        return l.dugnadTourWelcomeBody;
      case 'team':
        return l.dugnadTourTeamBody;
      case 'connect':
        return l.dugnadTourConnectBody;
      case 'earn':
        return l.dugnadTourEarnBody;
      case 'addr':
        return l.dugnadTourAddrBody;
      case 'camps':
        return l.dugnadTourCampsBody;
      case 'donate':
        return l.dugnadTourDonateBody;
      case 'refer':
        return l.dugnadTourReferBody;
      case 'comp':
        return l.dugnadTourCompBody;
      case 'sto':
        return l.dugnadTourStoBody;
      case 'form':
        return l.dugnadTourFormBody;
      case 'badges':
        return l.dugnadTourBadgesBody;
      case 'done':
        return again ? l.dugnadTourDoneAgainBody : l.dugnadTourDoneBody;
      default:
        return '';
    }
  }
}

/// The 13-step definition (Chunk 0B §2), ids in prototype order. Targets per the
/// registry; welcome/done have none; sto/form/badges live on the player card.
const List<DugnadTourStep> kDugnadTourSteps = <DugnadTourStep>[
  DugnadTourStep(
      id: 'welcome',
      target: null,
      screen: DugnadTourScreen.clubHome,
      placement: DugnadTourPlacement.center),
  DugnadTourStep(
      id: 'team', target: DugnadTourTarget.points, screen: DugnadTourScreen.clubHome),
  DugnadTourStep(
      id: 'connect', target: DugnadTourTarget.points, screen: DugnadTourScreen.clubHome),
  DugnadTourStep(
      id: 'earn', target: DugnadTourTarget.earn, screen: DugnadTourScreen.clubHome),
  DugnadTourStep(
      id: 'addr', target: DugnadTourTarget.addr, screen: DugnadTourScreen.clubHome),
  DugnadTourStep(
      id: 'camps', target: DugnadTourTarget.camps, screen: DugnadTourScreen.clubHome),
  DugnadTourStep(
      id: 'donate', target: DugnadTourTarget.donate, screen: DugnadTourScreen.clubHome),
  DugnadTourStep(
      id: 'refer', target: DugnadTourTarget.refer, screen: DugnadTourScreen.clubHome),
  DugnadTourStep(
      id: 'comp', target: DugnadTourTarget.comp, screen: DugnadTourScreen.clubHome),
  DugnadTourStep(
      id: 'sto', target: DugnadTourTarget.playerCard, screen: DugnadTourScreen.playerCard),
  DugnadTourStep(
      id: 'form', target: DugnadTourTarget.formButton, screen: DugnadTourScreen.playerCard),
  DugnadTourStep(
      id: 'badges', target: DugnadTourTarget.badges, screen: DugnadTourScreen.playerCard),
  DugnadTourStep(
      id: 'done',
      target: null,
      screen: DugnadTourScreen.clubHome,
      placement: DugnadTourPlacement.center),
];

/// Drives the guided tour: resolves the live step list, walks it, handles the
/// clubHome ↔ playerCard hop, and measures the current target so the overlay can
/// paint. Extends [ChangeNotifier]; the overlay listens and rebuilds.
class DugnadTourController extends ChangeNotifier with WidgetsBindingObserver {
  DugnadTourController({DugnadTourScreen startScreen = DugnadTourScreen.clubHome})
      : _startScreen = startScreen,
        _visibleScreen = startScreen;

  /// The single active controller, so [SupporterCardScreen] can tell us when its
  /// route is disposed (incl. by the Cupertino back-swipe). See [start]/[_end].
  static DugnadTourController? active;

  /// Fired when [active] is cleared so the celebration queue can resume.
  static void Function()? onBecameInactive;

  /// The tour-completion reward, in points. Single source of truth for the
  /// prompt's reward strip and (Chunk 3+) the award. Client-side only for now.
  static const int rewardPoints = 50;

  /// Data-driven absences for targets whose key can't report at start because
  /// their screen isn't open yet. Currently only `badges` (off-screen; depends
  /// on the user having earned badges). `camps` is intentionally NOT here — it
  /// is on the start screen and drops via live [DugnadTourKeys.isResolvable].
  /// A1: every launcher (incl. Chunk 4's real trigger) calls this instead of
  /// hand-rolling the set, so the badges case can't be forgotten.
  static Set<DugnadTourTarget> computeKnownAbsent({
    GamificationCareer? career,
    bool? hasEarnedBadges,
  }) {
    final has = hasEarnedBadges ??
        ((career?.permanentBadges.isNotEmpty ?? false) ||
            (career?.seasonalBadges.isNotEmpty ?? false));
    return {
      if (!has) DugnadTourTarget.badges,
    };
  }

  final DugnadTourScreen _startScreen;
  DugnadTourScreen _visibleScreen;

  List<DugnadTourStep> _steps = const <DugnadTourStep>[];
  int _index = 0;
  bool _ready = false;
  bool _finished = false;

  /// Captured once at [start]: whether the reward was already paid on a prior
  /// run. Drives the `done` step's "again" copy. Never written here.
  bool _again = false;

  /// Set just before the controller itself pops the player card, so the
  /// resulting dispose is not mistaken for a user back-swipe.
  bool _expectedPop = false;

  /// Direction of travel (+1 next / -1 back), so an unresolvable step is skipped
  /// the way the user was going (A2).
  int _dir = 1;

  /// True only when THIS controller pushed the player card (vs. finding one
  /// already live). Only a tour-pushed card is popped on the way back (5b).
  bool _tourPushedCard = false;

  bool _observing = false;

  /// Live target rect in OVERLAY coordinates. Scroll-following writes here so a
  /// notification repaints only the spotlight painter and repositions the card —
  /// never the whole overlay subtree or the card's contents.
  final ValueNotifier<Rect?> rect = ValueNotifier<Rect?>(null);

  /// Bumped on viewport-metrics changes (keyboard / rotation / split screen) so
  /// the card re-runs its MediaQuery-based placement even when the rect is equal.
  final ValueNotifier<int> metricsTick = ValueNotifier<int>(0);

  /// The single active scroll-follow subscription for the current step. Never
  /// outlives its step (detached in [_goToIndex] and [_end]).
  ScrollPosition? _followedPosition;
  VoidCallback? _followListener;

  List<DugnadTourStep> get steps => _steps;
  int get index => _index;
  int get totalSteps => _steps.length;
  bool get ready => _ready;
  bool get isFinished => _finished;
  bool get isAgain => _again;
  DugnadTourStep? get current =>
      (_index >= 0 && _index < _steps.length) ? _steps[_index] : null;

  /// Filters the 13 steps to those actually present.
  ///
  /// Rules:
  ///  - null-target steps (welcome / done) are always kept.
  ///  - a targeted step is dropped if its target is in [knownAbsent].
  ///  - otherwise it is kept when its key [DugnadTourKeys.isResolvable] now, OR
  ///    when it lives on a screen we have not opened yet (off-screen targets
  ///    cannot be measured at start — they resolve on navigation).
  ///  - an on-screen target that is not resolvable is dropped.
  ///
  /// This drops on-screen conditional absences (camps → collapsed carousel) via
  /// live [isResolvable], and off-screen conditional absences (badges → user has
  /// no earned badges) via [knownAbsent], while keeping unconditional off-screen
  /// steps (sto / form). See the chunk cross-check.
  void resolveSteps({Set<DugnadTourTarget> knownAbsent = const {}}) {
    _steps = kDugnadTourSteps.where((s) {
      final t = s.target;
      if (t == null) return true;
      if (knownAbsent.contains(t)) return false;
      if (DugnadTourKeys.isResolvable(t)) return true;
      return s.screen != _startScreen;
    }).toList();
    _index = 0;
    _ready = false;
    rect.value = null;
  }

  /// Waits until club-home tour anchors are laid out (or [timeout] elapses).
  ///
  /// Needed when relaunching from profile: PageView has disposed DGHome, so
  /// [resolveSteps] would otherwise drop every club-home spotlight and leave
  /// only welcome + player-card + done (the "1 / 4" bug). Polls the points
  /// card — same readiness gate the first-run prompt uses via summary load.
  static Future<bool> waitUntilClubHomeReady({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    const frame = Duration(milliseconds: 16);
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (DugnadTourKeys.isResolvable(DugnadTourTarget.points)) return true;
      await Future<void>.delayed(frame);
    }
    return DugnadTourKeys.isResolvable(DugnadTourTarget.points);
  }

  /// Resolve + show the first step. [knownAbsent] carries data-driven absences
  /// the launcher knows but the off-screen keys cannot report yet (e.g. badges).
  Future<void> start({Set<DugnadTourTarget> knownAbsent = const {}}) async {
    active = this;
    _again = prefGetBool(prefDugnadTourRewardPaid);
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    resolveSteps(knownAbsent: knownAbsent);
    notifyListeners();
    await _goToIndex(0);
  }

  Future<void> next() async {
    if (_index >= _steps.length - 1) {
      await finish();
      return;
    }
    await _goToIndex(_index + 1, dir: 1);
  }

  Future<void> back() async {
    if (_index <= 0) return;
    await _goToIndex(_index - 1, dir: -1);
  }

  /// Completes the tour: marks it seen, credits the tour reward, then closes.
  /// The popup fires after the overlay is gone so it is not covered.
  Future<void> finish() async {
    if (_finished) return;
    _finished = true;
    await prefSetBool(prefDugnadTourCompleted, true);
    await prefSetBool(prefDugnadTourFinished, true);
    final popPoints = await awardTourCompletion();
    _end();
    if (popPoints <= 0) return;
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final overlay = navigatorKey.currentState?.overlay;
    final ctx = overlay?.context ?? navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    DugnadPointsPop.award(
      popPoints,
      context: ctx,
      reason: DugnadPointsPopReasons.tour(ctx),
    );
    await prefSetBool(prefDugnadTourPopShown, true);
  }

  /// Aborts the tour. Marks it seen. Awards nothing (dismiss ≠ finish).
  Future<void> dismiss() async {
    await prefSetBool(prefDugnadTourCompleted, true);
    _end();
  }

  /// Calls the idempotent tour-completion endpoint. Credits points immediately
  /// (club is enough; team is not required). Returns points to pop on first
  /// award, otherwise 0. Never surfaces errors.
  static Future<int> awardTourCompletion() async {
    try {
      final clubId = DugnadState.instance.clubId;
      if (clubId <= 0) return 0;
      final alreadyPaid = prefGetBool(prefDugnadTourRewardPaid);
      final res = await DugnadRepo().completeTour(clubId: clubId);
      if (res == null) return 0;

      final awarded = _jsonTruthy(res['awarded']);
      final firstAward = _jsonTruthy(res['first_award']);
      final awardedPts = (res['tour_points_awarded'] as num?)?.toInt() ??
          (res['tour_points'] as num?)?.toInt() ??
          0;

      if (awarded) {
        await prefSetBool(prefDugnadTourRewardPaid, true);
      }

      final points = res['points'];
      if (points is Map) {
        await DugnadState.instance.applyPointsTeamProfile(
          PointsTeamProfile.fromJson(Map<String, dynamic>.from(points)),
        );
      }

      if (awardedPts > 0 &&
          (firstAward ||
              !alreadyPaid ||
              !prefGetBool(prefDugnadTourPopShown))) {
        return awardedPts;
      }
    } catch (_) {
      // Swallow — completion already recorded; the award retries on next check.
    }
    return 0;
  }

  static bool _jsonTruthy(Object? value) =>
      value == true || value == 1 || value == '1' || value == 'true';

  /// Retry hook: if the tour was FINISHED but the reward was never paid,
  /// fire the award once. Gated on `finished` — NOT merely `completed` — so a
  /// dismiss never awards. Server idempotency makes repeated calls safe.
  static Future<void> retryAwardIfNeeded() async {
    if (active != null) return;
    if (!prefGetBool(prefDugnadTourFinished)) return;
    if (prefGetBool(prefDugnadTourRewardPaid) &&
        prefGetBool(prefDugnadTourPopShown)) {
      return;
    }
    final popPoints = await awardTourCompletion();
    if (popPoints <= 0) return;
    final overlay = navigatorKey.currentState?.overlay;
    final ctx = overlay?.context ?? navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    DugnadPointsPop.award(
      popPoints,
      context: ctx,
      reason: DugnadPointsPopReasons.tour(ctx),
    );
    await prefSetBool(prefDugnadTourPopShown, true);
  }

  void _end() {
    _detachFollow();
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
    _finished = true;
    if (identical(active, this)) {
      active = null;
      onBecameInactive?.call();
    }
    notifyListeners();
  }

  /// Full teardown. Called from the overlay host after the entry is removed, so
  /// nothing reads the notifiers afterwards. Detaches the scroll follow, removes
  /// the metrics observer, and disposes the ValueNotifiers.
  @override
  void dispose() {
    _detachFollow();
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
    if (identical(active, this)) {
      active = null;
      onBecameInactive?.call();
    }
    rect.dispose();
    metricsTick.dispose();
    super.dispose();
  }

  /// Viewport changed — the card's placement reads MediaQuery height, so both the
  /// rect and the placement must update. Re-measure in place (ready unchanged) and
  /// tick [metricsTick] so the card re-runs placement even if the rect is equal.
  @override
  void didChangeMetrics() {
    metricsTick.value++;
    if (!_ready) return;
    final step = current;
    final target = step?.target;
    if (target == null) return;
    final r = _measureRectFor(DugnadTourKeys.keyFor(target)?.currentContext);
    if (r != null) rect.value = r;
  }

  /// Android / predictive back while the tour overlay is up.
  ///
  /// Used instead of [BackButtonListener] (which needs a [Router] the root
  /// Overlay does not have under classic [MaterialApp]). When the navigator
  /// cannot pop (club-home root), WidgetsApp's maybePop returns false and this
  /// runs. When a player-card route is on top, the navigator pops it first and
  /// [notifyPlayerCardScreenDisposed] cleans up.
  @override
  Future<bool> didPopRoute() async {
    if (_finished) return false;
    // Absorb back while the first step is still mounting/measuring so a
    // spurious pop during launch cannot tear the overlay down before the card
    // appears.
    if (!_ready) return true;
    return handleAndroidBack();
  }

  /// SupporterCardScreen is being disposed. If the tour did not initiate the pop
  /// (Cupertino back-swipe / hardware back while a player-card step is showing),
  /// abandon the tour rather than leave the overlay spotlighting a dead element.
  void notifyPlayerCardScreenDisposed() {
    _visibleScreen = DugnadTourScreen.clubHome;
    if (_expectedPop) {
      _expectedPop = false;
      return;
    }
    if (_finished) return;
    final step = current;
    if (step != null && step.screen == DugnadTourScreen.playerCard) {
      // Chosen behaviour: dismiss. The step's screen is gone and cannot be
      // re-measured without re-pushing behind the user's back.
      dismiss();
    }
  }

  Future<void> _goToIndex(int i, {int dir = 1}) async {
    _detachFollow(); // a listener must never outlive its step
    _dir = dir == 0 ? 1 : dir;
    _index = i.clamp(0, _steps.length - 1);
    _ready = false;
    rect.value = null;
    notifyListeners();

    final step = current;
    if (step == null) return;

    await _ensureScreen(step.screen);
    if (_finished) return;
    await _measureCurrent();
  }

  /// Hop between clubHome and the player card on the ROOT navigator so the
  /// root-Overlay tour is unaffected. Push going to playerCard; pop coming back.
  Future<void> _ensureScreen(DugnadTourScreen target) async {
    if (_visibleScreen == target) return;
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    if (target == DugnadTourScreen.playerCard) {
      // 5b: if a SupporterCardScreen is already live, don't push a second — the
      // tour measures the live instance (newest owner). Else push our own.
      if (DugnadTourKeys.hasLivePlayerCard) {
        _tourPushedCard = false;
      } else {
        // Push directly (not via openScreen) so we can await the Cupertino
        // slide-in. Measuring mid-transition places the hole off the right
        // edge — crest clipped, looks like a second card bleeding out.
        final route = CupertinoPageRoute<void>(
          builder: (_) => const SupporterCardScreen(),
        );
        nav.push(route);
        _tourPushedCard = true;
        final anim = route.animation;
        if (anim != null && !anim.isCompleted) {
          final done = Completer<void>();
          void listener(AnimationStatus status) {
            if (status == AnimationStatus.completed ||
                status == AnimationStatus.dismissed) {
              anim.removeStatusListener(listener);
              if (!done.isCompleted) done.complete();
            }
          }
          anim.addStatusListener(listener);
          // In case it completed between the check and the listener attach.
          if (anim.isCompleted && !done.isCompleted) done.complete();
          await done.future;
        }
      }
    } else {
      // Only pop back to clubHome if WE pushed the card; a user-opened card is
      // left to the user.
      if (_tourPushedCard) {
        _expectedPop = true; // our own pop — don't treat the dispose as a swipe
        nav.pop();
        // Wait for the pop animation too so the next clubHome measure is stable.
        await WidgetsBinding.instance.endOfFrame;
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      _tourPushedCard = false;
    }
    _visibleScreen = target;
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _measureCurrent() async {
    final myIndex = _index;
    final step = current;
    if (step == null) return;

    final target = step.target;
    if (target == null) {
      // Centered card, no spotlight — always ready.
      rect.value = null;
      _ready = true;
      notifyListeners();
      return;
    }

    // A3: the target's screen may still be loading (SupporterCardScreen._load).
    // Poll ~every frame until the key is resolvable. Player-card steps get a
    // longer cap — the first open still waits on network even with cache seed;
    // the old 2.5s window short-circuited sto/form → done (the "9/12 → 12/12" bug).
    const frame = Duration(milliseconds: 16);
    final maxTries = step.screen == DugnadTourScreen.playerCard ? 500 : 156; // ~8s / ~2.5s
    var tries = 0;
    while (!DugnadTourKeys.isResolvable(target)) {
      if (_finished || _index != myIndex) return; // superseded by a newer step
      if (tries++ >= maxTries) {
        _handleTimeout(step);
        return;
      }
      await Future<void>.delayed(frame);
    }
    if (_finished || _index != myIndex) return;

    final ctx = DugnadTourKeys.keyFor(target)?.currentContext;
    if (ctx == null || !ctx.mounted) {
      _autoAdvanceUnresolvable();
      return;
    }

    // Scroll-following: attach BEFORE the programmatic scroll so the rect is
    // recomputed throughout ensureVisible (not just at its end), then again after
    // the scroll future settles, then live for the rest of the step.
    _attachFollow(ctx);

    final reduce = _reduceMotion();
    await Scrollable.ensureVisible(
      ctx,
      alignment: 0.4,
      duration: reduce ? Duration.zero : const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
    if (_finished || _index != myIndex) {
      _detachFollow();
      return;
    }

    // Prototype settle (tour.jsx): wait until the target rect is stable across
    // frames before marking ready — covers route slide, ensureVisible, and
    // late layout. Without this the hole freezes mid-slide off the right edge.
    final r = await _settleRect(target, myIndex, reduce: reduce);
    if (_finished || _index != myIndex) {
      _detachFollow();
      return;
    }
    if (r != null) {
      rect.value = r;
      _ready = true;
      notifyListeners();
    } else {
      // A2: measurement failed even though isResolvable passed — skip, don't paint.
      _detachFollow();
      _autoAdvanceUnresolvable();
    }
  }

  /// Wait until [target]'s overlay rect stops moving (design: frames>24 &&
  /// stable≥4, or ~110 frame cap). Mirrors `settle` in dugnad/tour.jsx.
  Future<Rect?> _settleRect(
    DugnadTourTarget target,
    int myIndex, {
    required bool reduce,
  }) async {
    if (reduce) {
      await WidgetsBinding.instance.endOfFrame;
      return _measureRectFor(DugnadTourKeys.keyFor(target)?.currentContext);
    }
    Rect? last;
    var stable = 0;
    var frames = 0;
    const maxFrames = 110;
    while (frames < maxFrames) {
      if (_finished || _index != myIndex) return null;
      await Future<void>.delayed(const Duration(milliseconds: 16));
      frames++;
      final r = _measureRectFor(DugnadTourKeys.keyFor(target)?.currentContext);
      if (r == null) {
        stable = 0;
        last = null;
        continue;
      }
      // Track live while settling so the hole follows the last stretch of motion.
      rect.value = r;
      final same = last != null &&
          (r.left - last.left).abs() < 0.5 &&
          (r.top - last.top).abs() < 0.5 &&
          (r.width - last.width).abs() < 0.5 &&
          (r.height - last.height).abs() < 0.5;
      stable = same ? stable + 1 : 0;
      last = r;
      if (frames > 24 && stable >= 4) return r;
    }
    return last;
  }

  /// A2/A4: a step's target never became resolvable within the polling cap.
  void _handleTimeout(DugnadTourStep step) {
    if (kDebugMode) {
      debugPrint('[dugnad-tour] step "${step.id}" (${step.target}) unresolvable '
          'after poll timeout');
    }
    final prevI = _index - _dir;
    final firstOnScreen = prevI < 0 ||
        prevI >= _steps.length ||
        _steps[prevI].screen != step.screen;
    if (step.screen == DugnadTourScreen.playerCard && firstOnScreen) {
      // A4: the whole player-card screen is unreachable — drop every step on it
      // at once instead of polling 2.5 s per step.
      _shortCircuitPlayerCard();
    } else {
      _autoAdvanceUnresolvable();
    }
  }

  /// A4: drop the contiguous run of playerCard steps in the travel direction and
  /// continue from the next step off that screen (in practice `done`). Pops back
  /// to clubHome via [_goToIndex] → [_ensureScreen]. [totalSteps] unchanged.
  void _shortCircuitPlayerCard() {
    if (_finished) return;
    final dropped = <String>[];
    var i = _index;
    while (i >= 0 &&
        i < _steps.length &&
        _steps[i].screen == DugnadTourScreen.playerCard) {
      dropped.add(_steps[i].id);
      i += _dir;
    }
    if (kDebugMode) {
      debugPrint('[dugnad-tour] player-card screen timed out — dropping '
          '${dropped.join(", ")} (counter unchanged)');
    }
    if (i < 0 || i >= _steps.length) {
      finish();
      return;
    }
    _goToIndex(i, dir: _dir);
  }

  /// A2: advance past a step we couldn't measure, in the current direction,
  /// without ever setting `ready` for it (so the painter never sees a null rect).
  /// [totalSteps] is unchanged — the dead step is skipped, not removed, so the
  /// counter never renumbers.
  void _autoAdvanceUnresolvable() {
    if (_finished) return;
    final nextI = _index + _dir;
    if (nextI >= _steps.length) {
      finish();
      return;
    }
    if (nextI < 0) {
      // Going back off the front — the first step (welcome) has a null target
      // and is always renderable, so this is unreachable in practice.
      return;
    }
    _goToIndex(nextI, dir: _dir);
  }

  // ── Scroll-following ─────────────────────────────────────────────────

  /// Subscribes to the [ScrollPosition] driving the target's scrollable — the
  /// same position the exposed tourScrollController / shell controller owns — so
  /// every scroll pixel recomputes the rect. Detaches any prior subscription so
  /// two steps never both listen.
  void _attachFollow(BuildContext ctx) {
    _detachFollow();
    final pos = Scrollable.maybeOf(ctx)?.position;
    if (pos == null) return;
    _followedPosition = pos;
    _followListener = _onFollowScroll;
    pos.addListener(_followListener!);
  }

  void _detachFollow() {
    final p = _followedPosition;
    final l = _followListener;
    if (p != null && l != null) p.removeListener(l);
    _followedPosition = null;
    _followListener = null;
  }

  void _onFollowScroll() {
    if (_finished) return;
    final target = current?.target;
    if (target == null) return;
    final r = _measureRectFor(DugnadTourKeys.keyFor(target)?.currentContext);
    if (r != null) rect.value = r; // only a valid, non-zero rect is published
  }

  /// Measures [ctx]'s render box relative to the ROOT navigator's Overlay, not
  /// raw screen space — so the ring is correct even if the navigator is inset
  /// (split screen, or a future banner above it). Returns null on a detached /
  /// zero-size / offscreen box (guard so the painter never gets a bad rect).
  ///
  /// Uses the axis-aligned bounding box of all four corners under the paint
  /// transform. `localToGlobal(Offset.zero) & size` is WRONG under rotateY
  /// (player-card entrance flip): the origin slides to the right while width
  /// stays full, so the hole spills off-screen — the clipped white ring bug.
  Rect? _measureRectFor(BuildContext? ctx) {
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    if (box.size.width <= 0 || box.size.height <= 0) return null;
    final overlay =
        navigatorKey.currentState?.overlay?.context.findRenderObject();
    final RenderBox? ancestor =
        (overlay is RenderBox && overlay.attached) ? overlay : null;
    Offset map(Offset o) => ancestor != null
        ? box.localToGlobal(o, ancestor: ancestor)
        : box.localToGlobal(o);
    final w = box.size.width;
    final h = box.size.height;
    final c0 = map(Offset.zero);
    final c1 = map(Offset(w, 0));
    final c2 = map(Offset(0, h));
    final c3 = map(Offset(w, h));
    final r = Rect.fromLTRB(
      math.min(c0.dx, math.min(c1.dx, math.min(c2.dx, c3.dx))),
      math.min(c0.dy, math.min(c1.dy, math.min(c2.dy, c3.dy))),
      math.max(c0.dx, math.max(c1.dx, math.max(c2.dx, c3.dx))),
      math.max(c0.dy, math.max(c1.dy, math.max(c2.dy, c3.dy))),
    );
    if (r.width <= 0 || r.height <= 0) return null;
    return r;
  }

  /// Android hardware/gesture back while the tour runs. clubHome step → dismiss
  /// (never pop the underlying route). playerCard step → tour "back" (returns to
  /// the previous step, popping to clubHome if it lives there). Returns true so
  /// the framework does not also pop the route.
  Future<bool> handleAndroidBack() async {
    if (_finished) return false;
    final step = current;
    if (step == null) return false;
    if (step.screen == DugnadTourScreen.clubHome) {
      await dismiss();
    } else {
      await back();
    }
    return true;
  }

  bool _reduceMotion([BuildContext? ctx]) {
    final c = ctx ?? navigatorKey.currentContext;
    if (c == null) return false;
    return MediaQuery.maybeOf(c)?.disableAnimations ?? false;
  }
}
