import 'package:flutter/services.dart';

/// The order's live card on the Android lock screen (`LiveCardPlugin`). A plugin so it is there in every engine —
/// also the one Firebase starts for a push while the app is closed, so the card keeps up on a locked phone.
///
/// [show] takes the view the app built (`NtfLiveCard.view`): every word is decided in Dart; Android only draws it.
abstract final class AerendLiveCard {
  static const MethodChannel _c = MethodChannel('aerend/live_card');

  static Future<bool> show(int id, Map<String, Object?> view) async {
    try {
      return await _c.invokeMethod<bool>('show', {'id': id, 'view': view}) ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> cancel(int id) async {
    try {
      await _c.invokeMethod<void>('cancel', {'id': id});
    } on MissingPluginException {
      // Not on this platform.
    } on PlatformException {
      // Nothing to cancel.
    }
  }
}
