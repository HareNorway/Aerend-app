import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart';
import '../theme/bergen_tokens.dart';

/// Opaque navy curtain held over a logout teardown.
///
/// Logout clears the club *before* it navigates, so every club-themed surface
/// repaints with the Ærend purple defaults (`AeThemePalette.defaults`,
/// primary `#7F5FC4`) while the old route is still on screen — a purple flash
/// under the incoming splash. The curtain paints the splash's own gradient over
/// the teardown, so the swap reads as one continuous navy surface.
///
/// Fail-safe by construction: a watchdog drops the curtain even if the teardown
/// throws or never navigates, so a failed logout can't strand the app behind an
/// unremovable cover.
OverlayEntry? _entry;
Timer? _watchdog;

/// Ceiling on how long the curtain may stay up before it drops itself.
const Duration _kWatchdog = Duration(seconds: 3);

bool get isLogoutCurtainVisible => _entry != null;

/// Raise the curtain. No-op if one is already up, or if there is no overlay yet
/// (nothing on screen to cover).
void showLogoutCurtain() {
  if (_entry != null) return;
  final overlay = navigatorKey.currentState?.overlay;
  if (overlay == null) return;

  _entry = OverlayEntry(
    // Absorbing: a second tap on "log ut" during the teardown must not re-enter.
    builder: (_) => const AbsorbPointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AerendBergenAuthTokens.splashPanelGradient,
        ),
        child: SizedBox.expand(),
      ),
    ),
  );
  overlay.insert(_entry!);

  _watchdog?.cancel();
  _watchdog = Timer(_kWatchdog, hideLogoutCurtain);
}

/// Drop the curtain now.
void hideLogoutCurtain() {
  _watchdog?.cancel();
  _watchdog = null;
  final entry = _entry;
  _entry = null;
  if (entry == null) return;
  try {
    entry.remove();
  } catch (_) {
    // Overlay already gone (hot restart / disposed navigator) — nothing to do.
  }
}

/// Drop the curtain once the route pushed underneath it has actually painted.
///
/// The push lands in the current frame but the new route only builds and paints
/// in the next one, so removing after a single frame would uncover the old
/// screen for one frame — exactly the flash this exists to hide.
void hideLogoutCurtainAfterSwap() {
  if (_entry == null) return;
  final binding = WidgetsBinding.instance;
  binding.addPostFrameCallback((_) {
    binding.addPostFrameCallback((_) => hideLogoutCurtain());
    binding.scheduleFrame();
  });
  binding.scheduleFrame();
}
