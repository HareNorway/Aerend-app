import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('aerend/haptic');

/// A subtle tick that still plays when the phone's touch-vibration setting
/// is off. Android drives the vibration motor directly (`MainActivity.tick`);
/// iOS uses the selection tick, which follows the user's System Haptics
/// switch (apps cannot override it).
void aeTick() {
  if (defaultTargetPlatform == TargetPlatform.android) {
    _channel.invokeMethod<void>('tick').catchError((Object _) => HapticFeedback.lightImpact());
  } else {
    HapticFeedback.selectionClick();
  }
}
