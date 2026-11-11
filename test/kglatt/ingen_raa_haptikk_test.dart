import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Kunde Glatt Step 3 (D7): every vibration goes through `AeHaptikk`, so
/// Android plays it with the phone's touch-vibration off, the «Vibrasjon»
/// switch and the throttle apply, and the log sees it. No raw
/// `HapticFeedback.x()` call outside `lib/ui/kit/ae_haptic.dart` (a
/// `gammel: HapticFeedback.x` tear-off — the call a site made before the
/// plan, for `kglattVib: false` — is not a call).
void main() {
  test('no raw HapticFeedback call outside the haptics service', () {
    final kall = RegExp(r'HapticFeedback\.[a-zA-Z]+\(');
    final funn = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.endsWith('ui/kit/ae_haptic.dart')) continue;
      final linjer = f.readAsLinesSync();
      for (var i = 0; i < linjer.length; i++) {
        if (kall.hasMatch(linjer[i])) funn.add('${f.path}:${i + 1}: ${linjer[i].trim()}');
      }
    }
    expect(funn, isEmpty, reason: funn.join('\n'));
  });
}
