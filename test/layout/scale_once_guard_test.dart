import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Source-level guard: **every design value must be scaled exactly once.**
///
/// The `ds²` regression happened because a bulk transform wrapped
/// `fontSize: 24` into `fontSize: context.dp(24)` *and* appended
/// `.dp(context)` to the same `style:` expression. Each value was then
/// multiplied by the scale factor twice — +4.8% at 393pt, +14.7% at 430pt.
///
/// Only text overshot, because geometry went through `dp()` once. That
/// asymmetry is what made it hard to spot by eye, so it is worth pinning in
/// CI rather than trusting review.
void main() {
  /// End index of the Dart expression starting at [start].
  int expressionEnd(String src, int start) {
    var depth = 0;
    for (var i = start; i < src.length; i++) {
      final c = src[i];
      if (c == '(' || c == '[' || c == '{') {
        depth++;
      } else if (c == ')' || c == ']' || c == '}') {
        if (depth == 0) return i;
        depth--;
      } else if (c == ',' && depth == 0) {
        return i;
      }
    }
    return src.length;
  }

  List<File> dartSources() => Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('no style: expression is scaled twice', () {
    final offenders = <String>[];

    for (final file in dartSources()) {
      final src = file.readAsStringSync();
      if (!src.contains('.dp(context)')) continue;

      for (final m in RegExp(r'style:\s*').allMatches(src)) {
        final start = m.end;
        final expr = src.substring(start, expressionEnd(src, start));
        if (!expr.contains('.dp(context)')) continue;

        // Strip the legitimate outer call, then look for an inner one.
        final inner = expr.replaceAll('.dp(context)', '');
        if (inner.contains('context.dp(')) {
          final line = '\n'.allMatches(src.substring(0, start)).length + 1;
          offenders.add('${file.path}:$line');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'These expressions apply the scale factor twice (ds²). Remove '
          'the inner context.dp() and keep the outer .dp(context):\n'
          '${offenders.join('\n')}',
    );
  });

  test('letterSpacing is never a bare decimal in the dugnad tree', () {
    // CSS letter-spacing is em-relative; Flutter's is absolute logical px.
    // `letterSpacing: -0.02` is visually nothing — the design means
    // `fontSize * -0.02`. A bare decimal is therefore always a porting bug.
    final bare = RegExp(r'letterSpacing:\s*-?0?\.\d+\s*[,)]');
    final offenders = <String>[];

    for (final file in dartSources()) {
      if (!file.path.contains('dugnad')) continue;
      final lines = file.readAsStringSync().split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (bare.hasMatch(lines[i])) {
          offenders.add('${file.path}:${i + 1}  ${lines[i].trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'letterSpacing must derive from the font size '
          '(e.g. `context.dp(24) * -0.02`), not be an absolute px value:\n'
          '${offenders.join('\n')}',
    );
  });

  test('letterSpacing is never hand-scaled from a bare em value', () {
    // The blind spot in the test above: it looks for a *bare* decimal, so
    // `letterSpacing: context.dp(0.04)` sails through — it is scaled, and it
    // is still wrong. `.04em` at 10px is 0.4px; that expression yields 0.04px,
    // an order of magnitude short, so the tracking is effectively absent.
    //
    // No real design tracking is below 1 logical px before scaling, so a
    // sub-1 argument to dp() in this position is always the em value that was
    // never multiplied by the font size.
    final handScaled = RegExp(r'letterSpacing:\s*context\.dp\(\s*-?0?\.\d+\s*\)');
    final offenders = <String>[];

    for (final file in dartSources()) {
      final lines = file.readAsStringSync().split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (handScaled.hasMatch(lines[i])) {
          offenders.add('${file.path}:${i + 1}  ${lines[i].trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'These scale the em value instead of the derived px. Multiply by '
          'the font size first (`context.dp(10) * 0.04`):\n'
          '${offenders.join('\n')}',
    );
  });

  test('report: dugnad TextStyles that set fontSize but no letterSpacing', () {
    // The third blind spot — an *absent* property is never flagged, because
    // every guard here matches the shape of values that are present. The rank
    // chip was missing `letterSpacing` entirely and no test could have caught
    // it.
    //
    // This cannot be an assertion: plenty of styles legitimately have no
    // tracking, and the design is the only authority on which. So it reports,
    // the same way the bare-radius sweep does, and the number is the thing to
    // watch.
    var withSize = 0;
    var withoutTracking = 0;

    for (final file in dartSources()) {
      if (!file.path.contains('dugnad')) continue;
      final src = file.readAsStringSync();
      for (final m in RegExp(r'fontSize:\s*').allMatches(src)) {
        withSize++;
        // Look within the enclosing argument list, approximated by the 400
        // characters around the match — enough for a copyWith block.
        final from = (m.start - 200).clamp(0, src.length);
        final to = (m.start + 200).clamp(0, src.length);
        if (!src.substring(from, to).contains('letterSpacing')) {
          withoutTracking++;
        }
      }
    }

    // ignore: avoid_print
    print('dugnad fontSize sites: $withSize, '
        'without a nearby letterSpacing: $withoutTracking');
    expect(withSize, greaterThan(0));
  });
}
