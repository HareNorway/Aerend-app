import 'package:flutter/material.dart';

import '../commonView/dugnad_club_loader.dart';
import '../main.dart';

OverlayEntry? _entry;
int _depth = 0;
String? _message;

bool get isGlobalLoadingOverlayVisible => _entry != null;

/// Full-screen club-themed loading overlay via the root navigator.
void showGlobalLoadingOverlay({String? message}) {
  _depth++;
  _message = message ?? _message;

  if (_entry != null) {
    _entry!.markNeedsBuild();
    return;
  }

  final overlay = navigatorKey.currentState?.overlay;
  if (overlay == null) return;

  _entry = OverlayEntry(
    builder: (context) => Material(
      type: MaterialType.transparency,
      child: DugnadClubLoaderScreen(
        label: (_message != null && _message!.isNotEmpty) ? _message : null,
      ),
    ),
  );
  overlay.insert(_entry!);
}

void hideGlobalLoadingOverlay() {
  if (_depth <= 0) return;
  _depth--;
  if (_depth > 0) return;
  _entry?.remove();
  _entry = null;
  _message = null;
}

/// Force the overlay down and zero the depth counter, whatever the balance of
/// show/hide calls was. Overlay entries are not routes, so a logout's
/// `pushAndRemoveUntil` leaves a leaked loader in the root Overlay — above
/// every route of the NEXT session, swallowing its input.
void resetGlobalLoadingOverlay() {
  _depth = 0;
  _message = null;
  final entry = _entry;
  _entry = null;
  if (entry == null) return;
  try {
    entry.remove();
  } catch (_) {}
}

Future<T> withGlobalLoadingOverlay<T>(
  Future<T> Function() action, {
  String? message,
}) async {
  showGlobalLoadingOverlay(message: message);
  try {
    return await action();
  } finally {
    hideGlobalLoadingOverlay();
  }
}
