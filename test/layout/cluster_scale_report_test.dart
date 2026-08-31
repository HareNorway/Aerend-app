import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Scale and tracking census for the gamify cluster.
///
/// This **reports**; it does not assert. The standing order for unscaled
/// geometry is "verify values against the design per screen, then scale —
/// never scale first", because scaling an unverified screen only makes it
/// consistently wrong at a new size. Seven of these eight screens have not
/// been verified yet, so the numbers below are a work queue, not a defect
/// count.
///
/// The one assertion here is behavioural and cheap: no file may repeat an
/// animation without mentioning reduced motion. That is keyed on the property
/// rather than a code shape, which is what let it catch the lazy getter that
/// two initState-based checks missed.
void main() {
  const cluster = <String, String>{
    'teampicker': 'lib/screens/dugnad/points_team_picker_screen.dart',
    'playercard': 'lib/screens/dugnad/widgets/dugnad_player_card.dart',
    'teamdetail': 'lib/screens/dugnad/team_detail_screen.dart',
    'form': 'lib/screens/dugnad/dugnad_formen_screen.dart',
    'missions': 'lib/screens/dugnad/dugnad_missions_screen.dart',
    'recap': 'lib/screens/dugnad/season_recap_screen.dart',
    'transfer': 'lib/screens/dugnad/transfer_window_screen.dart',
    'career': 'lib/screens/dugnad/career_screen.dart',
  };

  test('every cluster screen gates its repeating animations', () {
    final offenders = <String>[];
    cluster.forEach((name, path) {
      final src = File(path).readAsStringSync();
      if (RegExp(r'\.repeat\(').hasMatch(src) &&
          !src.contains('disableAnimationsOf')) {
        offenders.add(name);
      }
    });
    expect(offenders, isEmpty,
        reason: 'repeat an animation with no reduced-motion gate, wherever '
            'the start lives: ${offenders.join(", ")}');
  });

  test('report: unscaled geometry and absent tracking per screen', () {
    final dim = RegExp(r'\b(width|height|size|blurRadius|spreadRadius):\s*'
        r'(\d+(?:\.\d+)?)');
    final circ = RegExp(r'circular\(\s*(\d+(?:\.\d+)?)');

    final rows = <String>[];
    cluster.forEach((name, path) {
      final src = File(path).readAsStringSync();
      var dims = 0, radii = 0;
      for (final line in src.split('\n')) {
        if (line.contains('context.dp(')) continue;
        final m = dim.firstMatch(line);
        // <= 2 is a hairline or a line-height ratio; neither scales.
        if (m != null && double.parse(m.group(2)!) > 2) dims++;
        final c = circ.firstMatch(line);
        if (c != null && double.parse(c.group(1)!) != 999) radii++;
      }
      var sizes = 0, untracked = 0;
      for (final m in RegExp('fontSize:').allMatches(src)) {
        sizes++;
        final lo = (m.start - 260).clamp(0, src.length);
        final hi = (m.start + 260).clamp(0, src.length);
        if (!src.substring(lo, hi).contains('letterSpacing')) untracked++;
      }
      rows.add('  ${name.padRight(12)} unscaled ${dims.toString().padLeft(3)} '
          'dims / ${radii.toString().padLeft(2)} radii    '
          'fontSize $sizes, ${untracked} without tracking');
    });

    // ignore: avoid_print
    print('\ngamify cluster census:\n${rows.join('\n')}\n');
    expect(rows, hasLength(cluster.length));
  });
}
