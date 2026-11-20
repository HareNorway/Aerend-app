import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';

/// Fjordløpet v1.3 plan Step 9 (spec §12.4, §12.5): the device model, as the panel groups frame times by it and
/// `game.quality_low_models` pins a model to Low. Android sends `Build.MODEL` (e.g. «SM-A155F»), iOS the machine id
/// (e.g. «iPhone14,5»). Read once and kept; empty when the platform does not say (tests, desktop).
abstract final class LopetEnhet {
  static String? _model;
  static Future<String>? _henter;

  /// The model read so far ('' until [hent] has answered).
  static String get model => _model ?? '';

  /// Tests set the model directly.
  static set model(String v) => _model = v;

  static Future<String> hent() {
    if (_model != null) return Future.value(_model);
    return _henter ??= _les().then((m) => _model = m.length > 64 ? m.substring(0, 64) : m);
  }

  static Future<String> _les() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) return (await info.androidInfo).model;
      if (Platform.isIOS) return (await info.iosInfo).utsname.machine;
    } catch (_) {}
    return '';
  }
}
