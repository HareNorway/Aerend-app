import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `dugnad_subpage_shell.dart` supplies four of the seven widgets shared across
/// the gamify cluster — `AeFixedTypography` and `AeRiseIn` in seven of
/// eight screens, `AeHero` and `AeScrollBody` in four each.
///
/// It was ~80% unscaled, so a fixed-px shell wrapped seven screens whose
/// contents scaled around it. One file, one fix, the whole cluster.
///
/// This guard matches the **property**, not the wrapping widget. The
/// banner-scaling guard keys on `SizedBox(`, which is why `Container(width: 44)`
/// walked past it — a guard evadable by moving code is keyed on the wrong thing
/// (rule 23).
void main() {
  const path = 'lib/screens/dugnad/widgets/dugnad_subpage_shell.dart';

  test('no unscaled design dimension survives in the shared shell', () {
    final lines = File(path).readAsStringSync().split('\n');
    final offenders = <String>[];

    // Sizing and spacing properties, wherever they appear.
    final prop = RegExp(
      r'\b(width|height|size|blurRadius|spreadRadius|elevation):\s*(\d+(?:\.\d+)?)',
    );

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('context.dp(')) continue;
      final m = prop.firstMatch(line);
      if (m == null) continue;
      final v = double.parse(m.group(2)!);
      // Zero is position, not dimension; <= 2 is a hairline or a line-height
      // ratio, neither of which scales (rules 19 and 7).
      if (v == 0 || v <= 2) continue;
      offenders.add('  ${i + 1}: ${line.trim()}');
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Unscaled dimensions in a shell rendered by seven screens:\n'
          '${offenders.join('\n')}',
    );
  });

  test('no AeDugnadText call in the gamify cluster is left unscaled', () {
    // A helper carries the em conversion but cannot carry the device scale --
    // the call site must add it. Six sites across four cluster screens were
    // missing it, and three of those screens hand-roll their own hero instead
    // of using AeHero, which is why scaling the shell did not reach them.
    const cluster = [
      'lib/screens/dugnad/points_team_picker_screen.dart',
      'lib/screens/dugnad/widgets/dugnad_player_card.dart',
      'lib/screens/dugnad/team_detail_screen.dart',
      'lib/screens/dugnad/dugnad_formen_screen.dart',
      'lib/screens/dugnad/dugnad_missions_screen.dart',
      'lib/screens/dugnad/season_recap_screen.dart',
      'lib/screens/dugnad/transfer_window_screen.dart',
      'lib/screens/dugnad/career_screen.dart',
    ];
    final offenders = <String>[];
    for (final f in cluster) {
      final src = File(f).readAsStringSync();
      for (final m in RegExp(r'AeDugnadText\.\w+\([^;]*?\),').allMatches(src)) {
        if (!m.group(0)!.contains('.dp(context)')) {
          offenders.add(f);
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'Unscaled typography helper calls in: '
            '${offenders.toSet().join(", ")}');
  });

  test('the hero text styles go through the scale extension', () {
    final src = File(path).readAsStringSync();
    // A helper carries the em conversion but cannot carry the device scale --
    // the call site must add it, which is what AeSectionLabel was missing.
    // Every AeDugnadText call in this file must be followed by .dp(context).
    final calls = 'AeDugnadText.'.allMatches(src).length;
    final scaled = ').dp(context)'.allMatches(src).length;
    expect(scaled, greaterThanOrEqualTo(calls),
        reason: 'AeDugnadText is called $calls times but only $scaled styles '
            'are run through .dp(context) -- an unscaled style is fixed at '
            'every device width');
  });
}
