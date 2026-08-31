import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `dg-offer-shine` is one-shot on **tap**, not a loop and not hover.
///
/// The design added `:active` triggers with an explicit comment — "fires on
/// tap everywhere" — precisely because `:hover` never fires on touch. A port
/// wired to a hover equivalent ships an animation no user will ever see, and
/// it looks correct in review.
///
/// `MkCampaignCard` had this right from the start; `DugnadCampMiniCard`, the
/// other widget rendering the same `.mk-camp2`, had no shine at all.
void main() {
  const cards = {
    'MkCampaignCard': 'lib/screens/dugnad/widgets/mk_campaign_card.dart',
    'DugnadCampMiniCard':
        'lib/screens/dugnad/widgets/dugnad_campaign_carousel.dart',
  };

  cards.forEach((name, path) {
    test('$name fires its shine on tap, gated, at 1000ms', () {
      final src = File(path).readAsStringSync();

      expect(src, contains('onTapDown'),
          reason: '$name must trigger on tap; hover never fires on touch');
      expect(src, contains('forward(from: 0)'),
          reason: 'dg-offer-shine is one-shot, not a repeat()');
      expect(src, contains('disableAnimationsOf'),
          reason: 'it is in the reduced-motion list — treatment A');
      expect(src, contains('milliseconds: 1000'),
          reason: '.mk-camp2 runs dg-offer-shine at its own 1s, not a period '
              'propagated from another element in the family');
    });
  });

  test('the shine keeps lb-sheen geometry with a linear fade', () {
    // Same travel and skew as lb-sheen (-160% -> 240%, skewX(-16deg)) but a
    // linear 1 -> 0 fade rather than lb-sheen's fade-in-at-6% envelope.
    for (final path in cards.values) {
      final src = File(path).readAsStringSync();
      expect(src, contains('-1.6 + t * 4.0'), reason: path);
      expect(src, contains('Matrix4.skewX(-0.2867)'), reason: path);
      expect(src, contains('1 - t'), reason: path);
    }
  });
}
