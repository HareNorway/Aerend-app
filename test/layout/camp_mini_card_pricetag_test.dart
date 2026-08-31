// The home carousel card wears the same animated `.mk-pricetag` as the
// Kampanje tab card. It is the tighter of the two frames -- a square card at
// 72% of the viewport -- so the tag's intrinsic width is what can push the
// goal label off the row. Pinned at the narrow frame and a five-digit price.
import 'package:aerend_customer/screens/dugnad/dugnad_models.dart';
import 'package:aerend_customer/screens/dugnad/widgets/dugnad_campaign_carousel.dart';
import 'package:aerend_customer/screens/dugnad/widgets/mk_price_tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reduced_motion_harness.dart';

Future<void> pumpAt(WidgetTester tester, double width, num price) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: DugnadCampaignCarousel(
        campaigns: [
          ClubCampaignSummary.fromJson({
            'id': 1,
            'name': 'Esports athlete 10',
            'landing_intro_text': 'No woories',
            'min_price': price,
            'goal_percent': 7,
          }),
        ],
        clubLabel: 'Sadelen IL',
        campaignPoints: 50,
      ),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(() => bootstrapGlobals(locale: 'no'));

  testWidgets('mini card renders the price tag with no overflow', (t) async {
    await pumpAt(t, 375, 100);
    expect(find.byType(MkPriceTag), findsWidgets);
    expect(find.textContaining('100 kr'), findsWidgets);
    expect(t.takeException(), isNull);
  });

  testWidgets('narrow frame + long price still fits', (t) async {
    await pumpAt(t, 320, 12500);
    expect(find.byType(MkPriceTag), findsWidgets);
    expect(t.takeException(), isNull);
  });
}
