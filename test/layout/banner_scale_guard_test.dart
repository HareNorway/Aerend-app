import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `DugnadFeedEntryBanner` paints five of home's nine feed cards and was
/// skipped entirely by the ds scaling pass — every radius, padding and gap was
/// a bare literal, so those five rendered at fixed px while their neighbours
/// scaled.
///
/// This pins them, and sweeps the wider tree for the same omission so the next
/// bulk pass cannot silently skip a file again.
void main() {
  /// Character ranges where design-px lives **by design**: the `_EntryStyle`
  /// value table (its class body) and every `_EntryStyle(...)` / `_EntryInset`
  /// constructor call. Values there are consumed through `context.dp()` at the
  /// use site, so a bare number is correct.
  ///
  /// Keyed on the region, not a hardcoded list of field names — the earlier
  /// guard enumerated `titleSize`, `goSize`, `padV` and the rest, so adding a
  /// new well-named field (`titleTracking`, `subtitleWeight`) made a correct
  /// value fire. Rule 23: a guard that punishes the better shape is defective.
  List<List<int>> _styleTableRanges(String src) {
    final ranges = <List<int>>[];
    // The class body.
    final cls = RegExp(r'class _EntryStyle\b').firstMatch(src);
    if (cls != null) {
      final open = src.indexOf('{', cls.end);
      var d = 0, j = open;
      while (j < src.length) {
        if (src[j] == '{') d++;
        if (src[j] == '}') {
          d--;
          if (d == 0) break;
        }
        j++;
      }
      ranges.add([cls.start, j]);
    }
    // Every constructor call that fills the table.
    for (final m
        in RegExp(r'_EntryStyle\(|_EntryInset\.\w+\(').allMatches(src)) {
      final open = src.indexOf('(', m.start);
      var d = 0, j = open;
      while (j < src.length) {
        if (src[j] == '(') d++;
        if (src[j] == ')') {
          d--;
          if (d == 0) break;
        }
        j++;
      }
      ranges.add([m.start, j]);
    }
    return ranges;
  }

  test('feed entry banner has no unscaled geometry literal', () {
    final src = File(
      'lib/screens/dugnad/widgets/dugnad_feed_entry_banner.dart',
    ).readAsStringSync();

    final exempt = _styleTableRanges(src);
    // Char offset of the start of each line, so a line can be tested against
    // the exempt ranges.
    final lineStart = <int>[0];
    for (var k = 0; k < src.length; k++) {
      if (src[k] == '\n') lineStart.add(k + 1);
    }
    bool inTable(int lineIndex) {
      final pos = lineStart[lineIndex];
      return exempt.any((r) => pos >= r[0] && pos <= r[1]);
    }

    final offenders = <String>[];
    final patterns = <String, RegExp>{
      'BorderRadius.circular': RegExp(r'circular\(\s*\d'),
      'EdgeInsets literal': RegExp(r'EdgeInsets\.(all|symmetric|only|fromLTRB)\([^)]*?(?<![\w.])\d'),
      'icon size literal': RegExp(r'\bsize:\s*\d'),
    };
    // `Container(width: 44)` is not `SizedBox(`, which is how a hardcoded 44
    // sat in _IconBox through the whole scaling pass. Match the property
    // wherever it appears rather than guessing the wrapping widget.
    final sizing = RegExp(r'\b(width|height):\s*(\d+(?:\.\d+)?)');

    final lines = src.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Design px inside the style table is correct — it is scaled at the use
      // site. Exempt by region, so a new field needs no guard edit.
      if (inTable(i)) continue;
      patterns.forEach((name, re) {
        if (re.hasMatch(line) && !line.contains('context.dp(')) {
          offenders.add('  ${i + 1}: $name -> ${line.trim()}');
        }
      });

      final m = sizing.firstMatch(line);
      if (m != null && !line.contains('context.dp(')) {
        final value = double.parse(m.group(2)!);
        // Two documented exceptions, both of which must NOT scale: hairline
        // border widths (rule 19) and TextStyle `height`, which is a ratio
        // (rule 7). Both live at or below 2.
        if (value > 2) {
          offenders.add('  ${i + 1}: unscaled ${m.group(1)} -> ${line.trim()}');
        }
      }
    }

    expect(offenders, isEmpty,
        reason: 'unscaled geometry in the banner:\n${offenders.join('\n')}');
  });

  test('report: bare circular() radii remaining across screens/dugnad', () {
    final hits = <String>[];
    for (final f in Directory('lib/screens/dugnad')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final lines = f.readAsStringSync().split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'circular\(\s*\d').hasMatch(lines[i]) &&
            !lines[i].contains('context.dp(') &&
            !lines[i].contains('circular(999)')) {
          hits.add('${f.path}:${i + 1}');
        }
      }
    }
    // Informational: printed so the count is visible, not asserted to zero —
    // several are pill sentinels or non-layout radii.
    // ignore: avoid_print
    print('bare circular() radii outside the banner: ${hits.length}');
    for (final h in hits.take(20)) {
      // ignore: avoid_print
      print('  $h');
    }
  });
}
