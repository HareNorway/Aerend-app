import 'package:flutter/widgets.dart';

/// Widgets the guided tour can spotlight. Order here is not significant — the
/// step order lives in the controller. See Chunk 0B §2 for the mapping to the
/// prototype's `data-tour` selectors.
enum DugnadTourTarget {
  points,
  earn,
  addr,
  camps,
  comp,
  donate,
  refer,
  playerCard,
  formButton,
  badges,
}

/// Registry of [GlobalKey]s attached to the live widgets the tour highlights.
///
/// Keys are created lazily via [register] and reused across rebuilds, so calling
/// `DugnadTourKeys.register(target)` inside a `build()` is safe and idempotent —
/// the same key comes back every frame, never a duplicate-key error.
///
/// SupporterCardScreen (playerCard / formButton / badges) can be pushed more than
/// once per session. Those three keys are torn down in that screen's `dispose`
/// via [unregister] so a second push re-registers fresh keys instead of leaving
/// a stale key pointed at a disposed element.
class DugnadTourKeys {
  DugnadTourKeys._();

  static final Map<DugnadTourTarget, GlobalKey> _keys =
      <DugnadTourTarget, GlobalKey>{};

  /// Returns the key for [target], creating it on first use and reusing it on
  /// every subsequent call (idempotent across rebuilds).
  static GlobalKey register(DugnadTourTarget target) => _keys.putIfAbsent(
        target,
        () => GlobalKey(debugLabel: 'tour_${target.name}'),
      );

  /// Forgets [target]'s key so the next [register] mints a fresh one. Call from
  /// the `dispose` of a screen whose targets can be re-mounted later.
  static void unregister(DugnadTourTarget target) => _keys.remove(target);

  static GlobalKey? keyFor(DugnadTourTarget target) => _keys[target];

  // ── Player-card ownership (double-push guard; Chunk-3 newest-wins) ───
  // SupporterCardScreen can be mounted twice (fast double-tap; openScreen is not
  // debounced). Both instances calling register(playerCard/…) would share one
  // GlobalKey via putIfAbsent → Flutter throws on a duplicate live key. The keys
  // belong to exactly ONE live instance — the NEWEST to claim. Each build gates
  // its own registration on [isPlayerCardOwner], so a non-owner never registers.
  static Object? _playerCardOwner;

  /// The three targets that live on SupporterCardScreen.
  static const List<DugnadTourTarget> playerCardTargets = [
    DugnadTourTarget.playerCard,
    DugnadTourTarget.formButton,
    DugnadTourTarget.badges,
  ];

  /// True while any SupporterCardScreen is live (used to avoid a double-push).
  static bool get hasLivePlayerCard => _playerCardOwner != null;

  static bool isPlayerCardOwner(Object owner) =>
      identical(_playerCardOwner, owner);

  /// Newest live SupporterCardScreen takes ownership. The previous owner's keys
  /// are dropped from the registry so the new owner mints FRESH keys via
  /// register(); the old instance, no longer the owner, stops registering on its
  /// next build (its widgets keep their now-orphan GlobalKeys harmlessly).
  static void claimPlayerCard(Object owner) {
    if (identical(_playerCardOwner, owner)) return;
    _playerCardOwner = owner;
    for (final t in playerCardTargets) {
      unregister(t);
    }
  }

  /// Release + drop the player-card keys, but ONLY if [owner] is the CURRENT
  /// owner. A stale owner (superseded by a newer instance) disposing is a no-op,
  /// so it can never clobber the current owner's registration. Safe across
  /// pop-then-push: the owner's dispose clears ownership; the next push re-claims.
  static void releasePlayerCard(Object owner) {
    if (!identical(_playerCardOwner, owner)) return;
    _playerCardOwner = null;
    for (final t in playerCardTargets) {
      unregister(t);
    }
  }

  /// True only when [target]'s key is attached to a laid-out, non-zero-size
  /// [RenderBox] — i.e. the feature is genuinely on screen right now. Returns
  /// false when the key was never registered, is registered but not mounted, or
  /// resolves to a zero-size box (e.g. a conditional widget that collapsed to
  /// `SizedBox.shrink()`).
  static bool isResolvable(DugnadTourTarget target) {
    final key = _keys[target];
    final ctx = key?.currentContext;
    if (ctx == null) return false;
    final ro = ctx.findRenderObject();
    if (ro is! RenderBox) return false;
    if (!ro.attached || !ro.hasSize) return false;
    return ro.size.width > 0 && ro.size.height > 0;
  }
}
