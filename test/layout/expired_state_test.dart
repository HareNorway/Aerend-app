import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `.is-expired` is derived from the campaign's own deadline, not a flag.
///
/// `campState(c)` returns `expired` when the deadline has passed, `last` under
/// 24h, `active` otherwise. The app had no expired concept at all — the veil,
/// the dimmed CTA and the hidden countdown were all absent together, which is
/// why it read as a deferred feature rather than a set of missed values.
void main() {
  String src() => File('lib/screens/dugnad/widgets/mk_campaign_card.dart')
      .readAsStringSync();

  test('expiry is derived from salesWindowEnd', () {
    expect(src(), contains('deadline.isBefore(DateTime.now())'));
  });

  test('the countdown chip is replaced by the veil, not joined by it', () {
    final s = src();
    expect(s, contains('if (!expired &&'),
        reason: 'the chip must be hidden when expired');
    expect(s, contains('if (expired) const Positioned.fill'));
  });

  test('the veil actually filters the backdrop', () {
    final s = src();
    // `backdrop-filter: saturate(.6) blur(1px)`. A flat scrim would darken the
    // image but leave it as saturated and as sharp as before — visible only
    // with the two side by side, which is how it stayed missing.
    expect(s, contains('BackdropFilter'));
    expect(s, contains('ImageFilter.blur(sigmaX: 1, sigmaY: 1)'));
    expect(s, contains('ColorFilter.matrix'),
        reason: 'saturate(.6) needs a colour matrix, not an opacity');
  });

  test('.is-expired dims the card and the CTA separately', () {
    final s = src();
    // Two overrides, checked individually: a partially applied one looks
    // intentional.
    expect(s, contains('opacity: expired ? 0.96 : 1'));
    expect(s, contains('ScSaasThemeTokens.gray400'));
  });
}
