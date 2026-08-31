import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A hand-defined colour constant that duplicates a token's hex is a shadow:
/// it is verified once or not at all, and every site it backs is silently
/// wrong together. `_kPurplePoints` held `#5a3d96` against
/// `--ae-purple-700`'s `#6b4fa8` and tinted both leaderboard families'
/// numerals — consistent with each other, wrong against the source.
void main() {
  test('no _k constant duplicates a ScSaasThemeTokens hex', () {
    final tokenSrc = File('lib/theme/sc_saas_theme.dart').readAsStringSync();
    final tokens = <String, String>{};
    for (final m in RegExp(
      r'static const Color (\w+) = Color\((0x[0-9A-Fa-f]{8})\)',
    ).allMatches(tokenSrc)) {
      tokens[m.group(2)!.toUpperCase()] = m.group(1)!;
    }

    final offenders = <String>[];
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      for (final m in RegExp(
        r'const (_k\w+) = Color\((0x[0-9A-Fa-f]{8})\)',
      ).allMatches(f.readAsStringSync())) {
        final token = tokens[m.group(2)!.toUpperCase()];
        if (token != null) {
          offenders.add('${f.path}: ${m.group(1)} == ScSaasThemeTokens.$token');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'These repeat a token hex instead of aliasing it. Consume the '
          'token so there is one place to verify:\n${offenders.join('\n')}',
    );
  });
}
