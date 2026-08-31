import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// No `AnimationController` may be started inside `initState`.
///
/// `.repeat()` or `.forward()` there runs regardless of the reduced-motion
/// setting, and hiding the result in `build` does not stop it — the controller
/// keeps a frame permanently scheduled. That is rule 16's "gating in build is
/// not gating", and it is invisible to every visual comparison.
///
/// A sweep found **16** of these across `lib/` and 9 in `dugnad/` alone,
/// several sessions after a reduced-motion audit that covered 16 files by
/// pattern. They accumulate because nobody goes looking for them: each one is
/// found incidentally while reading a widget for some other reason.
///
/// The gate belongs in `didChangeDependencies` behind a `_started` flag, where
/// inherited lookups are legal and a runtime toggle re-fires it.
void main() {
  /// The initState check below could not see this one: a lazy getter
  /// (`_ctrl ??= AnimationController(...)..repeat()`) starts the animation on
  /// first access from `build`, so the start never appears in initState at
  /// all. Rule 23 — a guard encodes an assumption about how the code is
  /// written, and this file was written differently.
  test('no file starts a repeating controller without a gate', () {
    final offenders = <String>[];

    for (final file in Directory('lib/screens/dugnad')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final src = file.readAsStringSync();
      if (!src.contains('AnimationController')) continue;
      if (!RegExp(r'\.\.repeat\(|\.repeat\(').hasMatch(src)) continue;
      if (src.contains('disableAnimationsOf')) continue;
      offenders.add(file.path);
    }

    expect(
      offenders,
      isEmpty,
      reason: 'These repeat an animation and never mention reduced motion, so '
          'it runs regardless of the setting — wherever the start lives:\n'
          '${offenders.join('\n')}',
    );
  });

  test('no infinite repeat() is started in initState under dugnad/', () {
    final offenders = <String>[];

    for (final file in Directory('lib/screens/dugnad')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final src = file.readAsStringSync();
      if (!src.contains('AnimationController')) continue;

      for (final m in RegExp(r'void initState\(\)\s*\{').allMatches(src)) {
        var depth = 1;
        var j = m.end;
        while (j < src.length && depth > 0) {
          if (src[j] == '{') depth++;
          if (src[j] == '}') depth--;
          j++;
        }
        final body = src.substring(m.end, j);
        // `.forward()` one-shots are milder — they play once when they should
        // not, rather than holding a frame forever. `repeat()` is the drain.
        if (RegExp(r'\.repeat\(').hasMatch(body) &&
            !body.contains('disableAnimationsOf')) {
          final line = '\n'.allMatches(src.substring(0, m.start)).length + 1;
          offenders.add('${file.path}:$line');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'These start a repeating animation in initState, so it runs '
          'under reduced motion. Move the start into didChangeDependencies '
          'behind a _started flag:\n${offenders.join('\n')}',
    );
  });
}
