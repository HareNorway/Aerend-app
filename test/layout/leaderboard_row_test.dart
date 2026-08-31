import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `.lb-trow` source guards.
///
/// The row's border is **load-bearing**: the design declares
/// `1.5px solid transparent` on the base rule and `.mine` only *recolours* it.
/// A port that adds the border on selection instead of recolouring it reflows
/// every row by 1px the moment it becomes yours — a defect that is invisible
/// in a static screenshot and only shows when the user's own team loads.
void main() {
  String src() =>
      File('lib/screens/dugnad/leaderboard_screen.dart').readAsStringSync();

  test('the row border width never depends on selection', () {
    final s = src();
    expect(
      RegExp(r'width:\s*team\.isUserTeam\s*\?').hasMatch(s),
      isFalse,
      reason: '.lb-trow is 1.5px in every state; .mine recolours the border '
          'rather than adding one. A conditional width reflows the row.',
    );
  });

  test('.mine carries its own drop, not the base shadow recoloured', () {
    final s = src();
    // 0 12px 26px -16px rgba(127,95,196,.5)
    expect(s, contains('alpha: 0.5'));
    expect(s, contains('context.dp(26)'));
    expect(s, contains('context.dp(-16)'));
  });

  test('the base and inzone shadows are 3px blur, not 8', () {
    final s = src();
    // Both states are `0 1px 3px`; only the tint differs.
    expect(s, contains('blurRadius: context.dp(3)'));
    expect(
      RegExp(r'blurRadius:\s*8\b').hasMatch(s),
      isFalse,
      reason: 'the row shadow is 0 1px 3px in both states',
    );
  });

  test('the prize zone uses its own 155deg axis', () {
    final s = src();
    // 155deg is steeper than .inzone's 135 and the shiny token's 150 — three
    // distinct axes on one screen.
    expect(s, contains('Alignment(-0.45, -0.9)'));
  });

  test('.scl-tier stays two stops -- it is NOT Family A', () {
    final s = src();
    // Family A's gull ramp is #ffe9a8 / #f6cf6b / #e7b542. The tier badge is
    // #f7d979 -> #e7b542: same tone name, same 135deg, only the end stop
    // shared. A three-stop metal ramp is not legible at 8.5px, so this is
    // deliberate -- the inverse of the #f7cf6b/#f6cf6b trap.
    expect(s, contains('Color(0xFFF7D979)'));
    expect(
      s.contains('Color(0xFFF7D979), const Color(0xFFF6CF6B)'),
      isFalse,
      reason: 'a Family A midpoint has been spliced into the tier badge',
    );
    for (final pair in [
      ['0xFFEDEBF2', '0xFFDCD8E6'],
      ['0xFFF4D9BF', '0xFFE3B48B'],
      ['0xFFE7EDF6', '0xFFC6D3E8'],
    ]) {
      expect(s, contains(pair[0]));
      expect(s, contains(pair[1]));
    }
  });

  test('.scl-row.me lifts from 10px, the base row from 1px', () {
    final s = src();
    expect(s, contains('scorer.isViewer ? 10 : 1'),
        reason: '.me is 0 10px 24px -16px; reusing the base 1px offset makes '
            'the selected row sit flat under a 24px blur');
  });

  test('.scl-hero keeps its inset and its own two stops', () {
    final s = src();
    expect(s, contains('Color(0xFFFFE9A8)'));
    expect(s, contains('Color(0xFFF3C95F)'));
    expect(s, contains('alpha: 0.6'),
        reason: '0 1px 1px rgba(255,255,255,.6) inset must survive');
  });

  test('both marked numerals carry tabular figures', () {
    final s = src();
    // `.lb-trow .pts b` and `.scl-stat b` are both changing numerals in a
    // ranked list -- the jitter case. The app applies tabularFigures in 16
    // places across dugnad/ and has missed a marked one before.
    expect(
      RegExp(r'FontFeature\.tabularFigures\(\)').allMatches(s).length,
      greaterThanOrEqualTo(2),
      reason: 'both .pts b and .scl-stat b are marked tabular-nums',
    );
  });

  test('.scl-stat b is 17px with -0.02em, not the 15px default', () {
    final s = src();
    expect(s, contains('context.dp(17) * -0.02'));
  });

  test('every letterSpacing on this screen is em-derived', () {
    // Rule 3: a bare decimal is 10x under. All of these are hand-rolled
    // TextStyles, which is the only place the bug has ever appeared.
    final bare = RegExp(r'letterSpacing:\s*-?0?\.\d+\s*[,)]');
    expect(bare.hasMatch(src()), isFalse);
  });

  test('.scl-hero overrides both badge sizes, not just the tier', () {
    final s = src();
    // `.scl-hero .scl-tier` is 9px and `.scl-hero .scl-sto` is 10.5px. The
    // tier badge carried its flag from the start; the sto badge did not, so
    // the hero silently rendered the row's 9.5px beside a correctly enlarged
    // tier -- two sibling badges disagreeing with each other.
    expect(s, contains('large ? 9 : 8.5'));
    expect(s, contains('large ? 10.5 : 9.5'));
    expect(s, contains('large: true'));
  });

  test('.scl-sto is 800 with a 900 rating, not 900 throughout', () {
    final s = src();
    expect(s, contains("const TextSpan(text: 'STØ ')"),
        reason: 'the label and the numeral carry different weights');
  });

  test('zone and row geometry are scaled', () {
    final s = src();
    for (final v in ['context.dp(16)', 'context.dp(13)', 'context.dp(7)']) {
      expect(s, contains(v), reason: '$v should go through dp()');
    }
  });
}
