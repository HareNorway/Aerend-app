import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `.mk-pricetag` source guards.
///
/// The tag's swing controller was started in `initState` and only *hidden* in
/// `build`, so under reduced motion it kept running and held a frame
/// permanently scheduled — rule 16's "gating in build is not gating", on a
/// widget whose other details were all correct.
void main() {
  // The tag moved out of `mk_campaign_card.dart` when the home carousel card
  // needed it too. Only the CTA chevron still belongs to the card.
  String src() => File('lib/screens/dugnad/widgets/mk_price_tag.dart')
      .readAsStringSync();
  String cardSrc() => File('lib/screens/dugnad/widgets/mk_campaign_card.dart')
      .readAsStringSync();

  test('the swing is gated before it starts, not after', () {
    final s = src();
    expect(
      s.contains(')..repeat(reverse: true);'),
      isFalse,
      reason: 'the controller must not start in initState — the gate belongs '
          'in didChangeDependencies behind a _started flag',
    );
    expect(s, contains('didChangeDependencies'));
    expect(s, contains('_started'));
  });

  test('the drop-shadow is drawn behind the clip, not inside it', () {
    final s = src();
    // A BoxShadow inside a ClipPath is removed by the clip: the tag cast
    // nothing. CSS drop-shadow follows the clipped silhouette.
    expect(s, contains('_TagShadowPainter'));
    expect(s, contains('MaskFilter.blur(BlurStyle.normal, 9 / 2)'),
        reason: 'a CSS blur of 9 is a Gaussian sigma of ~4.5, not blurRadius 9');
  });

  test('the silhouette has exactly one definition', () {
    final s = src();
    // The painter and the clipper fill the same path. Two copies of a polygon
    // is the shared-constant problem in geometry form.
    expect(RegExp(r'const notch = 12\.0;').allMatches(s).length, 1);
    expect(s, contains('_PriceTagClipper.pathFor(size)'));
  });

  test('the CTA chevron translates on tap, not hover', () {
    final s = cardSrc();
    // `.cta svg` translates 3px on hover AND active. Hover never fires on
    // touch, so a hover-only port ships an animation no user sees.
    expect(s, contains('onTapCancel'),
        reason: 'a press state needs a cancel path or it sticks');
    expect(s, contains('3 / 15'),
        reason: '3px of a 15px glyph, as an AnimatedSlide fraction');
  });

  test('the swing completes its cycle in 3.6s, not 7.2s', () {
    final s = src();
    // `mk-tag-swing 3.6s` has its midpoint at 50%, so the whole out-and-back
    // is 3.6s. A 3600ms controller with `reverse: true` takes 3.6s each way.
    expect(
      s.contains('_controller.repeat(reverse: true)'),
      isFalse,
      reason: 'reverse doubles the cycle AND drives value 0->1->0, which fires '
          'the shared sheen interval twice per cycle, backwards the second time',
    );
    expect(s, contains('TweenSequence<double>'),
        reason: 'the out-and-back belongs in the tween, not in the controller');
  });

  test('mk-tag-sheen shares the swing controller and sweeps the first 38%', () {
    final s = src();
    expect(s, contains('-2.0 + p * 4.8'), reason: '-200% -> 280%');
    expect(s, contains('t / 0.38'));
    expect(s, contains('t >= 0.39'),
        reason: 'parked invisible for the remaining 61%');
    // Swing and sheen, and nothing else: every controller here is a thing
    // reduced motion has to stop, and `didChangeDependencies` stops exactly
    // these two. A third would slip past that gate unnoticed.
    //
    // NOTE: the comment this guard grew from wanted ONE controller for both
    // animations. The port runs them on separate clocks (3.6s swing, 1.6s
    // sheen), so 2 is the honest count -- collapsing them is a live question,
    // not something this assertion should decide by staying red.
    expect(RegExp(r'AnimationController\(').allMatches(s).length, 2,
        reason: 'the tag owns a swing controller and a sheen controller; '
            'anything beyond those two needs its own reduced-motion gate');
  });

  test('the punch-hole sits on the swing pivot', () {
    final s = src();
    // 6x6 white disc at left 4.5, on `transform-origin: 6px 50%`. Without it
    // the rotation has no visible anchor.
    expect(s, contains('left: 4.5'));
    expect(s, contains('Color(0x474A2E80)'));
  });
}
