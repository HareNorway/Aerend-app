import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A property-keyed guard for the letter-spacing tracking-error class.
///
/// The codebase writes tracking as `fontSize * em` (or `em * fontSize`) — the
/// smaller operand is the design's em value. A cluster of bugs was found where
/// that em factor had its decimal shifted a place: `0.8` for `0.08em`, `-0.3`
/// for `-0.02em`, `-0.5` for `-0.02em`. Each renders 10–20x too wide.
///
/// The tracking *manifest* pins a list of classes; it never caught these
/// because the offending classes were not on the list. That is the failure
/// mode of an enumeration guard (rule 23): it protects only what it names, yet
/// its existence implies coverage it does not have.
///
/// This guard keys on the **property** instead of the enumeration: the design's
/// largest authored tracking is `0.09em` (`.lb-prize .eyebrow`), so any em
/// factor whose magnitude exceeds `0.1` is a decimal shift — a defect —
/// regardless of which class it lives on, pinned or not. That single rule would
/// have caught all four of the original cluster's bugs, and it surfaced nine
/// more across four other files.
void main() {
  // The largest tracking any Ærend design element authors is 0.09em. A factor
  // above 0.1 is therefore not a design choice — it is a shifted decimal.
  const maxAuthoredEm = 0.1;

  // `letterSpacing: A * B`, either operand order. The em factor is min(|A|,|B|);
  // the font size is the larger operand.
  final multForm = RegExp(
    r'letterSpacing:\s*(-?\d+(?:\.\d+)?)\s*\*\s*(-?\d+(?:\.\d+)?)',
  );

  test('no letterSpacing em factor exceeds 0.1 (decimal-shift guard)', () {
    final offenders = <String>[];
    for (final f in Directory('lib/screens/dugnad')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final lines = f.readAsStringSync().split('\n');
      for (var i = 0; i < lines.length; i++) {
        final m = multForm.firstMatch(lines[i]);
        if (m == null) continue;
        final a = double.parse(m.group(1)!).abs();
        final b = double.parse(m.group(2)!).abs();
        final em = a < b ? a : b;
        if (em > maxAuthoredEm) {
          offenders.add('  ${f.path}:${i + 1}: em=$em -> ${lines[i].trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'letterSpacing em factor > $maxAuthoredEm is a shifted decimal '
          '(design max is 0.09em):\n${offenders.join('\n')}',
    );
  });
}
