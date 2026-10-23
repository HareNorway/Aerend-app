import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('aerend/haptic');

// Haptics that still play when the phone's touch-vibration setting is off.
// Android drives the vibration motor directly (`MainActivity.haptic`); iOS
// uses Apple's feedback generators, which follow the user's System Haptics
// switch (apps cannot override it).

/// A subtle tick: a card or an option comes to the front.
void aeTick() => _spill('tick', HapticFeedback.selectionClick);

/// A firm tap: something went into the basket, the pay slider reached the end.
void aeConfirm() => _spill('confirm', HapticFeedback.mediumImpact);

/// A double tap: a Fjordfiske catch, a secured surprise bag, the order moved on.
void aeSuccess() => _spill('success', () {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 110), HapticFeedback.mediumImpact);
    });

void _spill(String kind, VoidCallback ios) {
  if (defaultTargetPlatform == TargetPlatform.android) {
    _channel.invokeMethod<void>('play', kind).catchError((Object _) => HapticFeedback.lightImpact());
  } else {
    ios();
  }
}
