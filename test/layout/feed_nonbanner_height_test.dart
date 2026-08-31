import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/ui/kit/ae_theme.dart';
import 'package:aerend_customer/screens/dugnad/dugnad_models.dart';
import 'package:aerend_customer/screens/dugnad/gamification_models.dart';
import 'package:aerend_customer/screens/dugnad/widgets/dugnad_campaign_carousel.dart';
import 'package:aerend_customer/screens/dugnad/widgets/dugnad_earn_sheet.dart';
import 'package:aerend_customer/screens/dugnad/widgets/dugnad_home_anchor_card.dart';
import 'package:aerend_customer/screens/dugnad/widgets/dugnad_season_finale_card.dart';

import 'reduced_motion_harness.dart';

/// §5, the four non-banner feed children.
///
/// Rule 22: a rendered height is box + wrapped copy, and `flutter test` cannot
/// load Plus Jakarta Sans, so wrap points never match the design. Each row is
/// therefore measured twice — once with the copy it really carries, once with
/// copy too short to wrap — and only the second number is comparable to a
/// design height that is itself single-line.
void main() {
  const double frame = 375.0;
  const double column = 335.0;

  setUpAll(() => bootstrapGlobals(locale: 'no'));

  /// [height, % of 375]
  const design = <String, List<double>>{
    'points card': [224.6, 59.89],
    'season finale': [256.6, 68.42],
    'earn row': [42.0, 11.19],
    'dg-pcar carousel': [311.1, 82.96],
  };

  /// Widening past every wrap point is the box-vs-copy split for widgets whose
  /// copy comes from l10n and cannot be shortened in place.
  ///
  /// The **viewport** has to widen, not just the box: a `SizedBox(width: 900)`
  /// inside a 375 viewport is clamped straight back to 375 by
  /// `constraints.enforce()`, so widening the SizedBox alone measures the same
  /// width twice and reports every row as having no copy term.
  Future<double> measure(WidgetTester tester, Widget child,
      {double width = column, double viewport = frame}) async {
    tester.view.physicalSize = Size(viewport, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: AeThemeScope(
          palette: AeThemePalette.defaults,
          child: Scaffold(
            // Unbounded height so nothing stretches to the frame (rule 22).
            body: SingleChildScrollView(
              child: SizedBox(width: width, child: child),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    return tester.getSize(find.byWidget(child)).height;
  }

  /// The design's 224.6 / 256.6 are the fully-populated cards: button,
  /// divider, progress row, team row, and the season card's closing medal
  /// line. A summary thin enough to strip those renders a different card, not
  /// a shorter one.
  PointsSummary summary() => PointsSummary.fromJson(const {
        // The design mounts SeasonCarryoverCard with rating 84 / seasonPts
        // 320 and derives seasonBadges to 3; 256.6 was measured with exactly
        // those, so the fixture has to use them too.
        'lifetime_points': 12480,
        'season_points': 320,
        'sto_rating': 84,
        'progression_percent': 62,
        'points_to_next_tier': 760,
        'campaign_purchase_points': 50,
        'current_tier': {
          'key': 'sølv',
          'metal': 'solv',
          'min_points': 10000,
          'label_no': 'Sølv',
          'title_suffix': 'supporter',
          'color_hex': '#B8C2CC',
          'achieved': true,
        },
        'next_tier': {
          'key': 'gull',
          'metal': 'gull',
          'min_points': 13240,
          'label_no': 'Gull',
          'title_suffix': 'supporter',
          'color_hex': '#E7B542',
        },
        'metal_tiers': [
          {'key': 'bronse', 'metal': 'bronse', 'min_points': 0,
           'label_no': 'Bronse', 'achieved': true},
          {'key': 'solv', 'metal': 'solv', 'min_points': 10000,
           'label_no': 'Sølv', 'achieved': true},
          {'key': 'gull', 'metal': 'gull', 'min_points': 13240,
           'label_no': 'Gull'},
          {'key': 'platina', 'metal': 'platina', 'min_points': 25000,
           'label_no': 'Platina'},
        ],
        'season': {'starts_at': '2025-08-01', 'ends_at': '2026-06-30'},
      });

  /// The populated state is gated on **config**, not the summary: without
  /// `metal_carryover`, dugnadMetalCarryoverPreview returns an empty preview
  /// and the carryover line, the "Nå {nextTier}" row and its bar all vanish.
  /// Changing the summary alone leaves the height untouched.
  GamificationConfig config() => GamificationConfig.fromJson(const {
        'sto_tier_thresholds': [
          {'tier_key': 'bronse', 'rating_min': 0, 'rating_max': 69,
           'label': 'Bronse', 'color_hex': '#A46321'},
          {'tier_key': 'solv', 'rating_min': 70, 'rating_max': 84,
           'label': 'Sølv', 'color_hex': '#B8C2CC'},
          {'tier_key': 'gull', 'rating_min': 85, 'rating_max': 94,
           'label': 'Gull', 'color_hex': '#E7B542'},
          {'tier_key': 'platina', 'rating_min': 95, 'rating_max': 100,
           'label': 'Platina', 'color_hex': '#BCCAE2'},
        ],
        'metal_carryover': [
          {'tier_key': 'bronse', 'carryover_points': 0},
          {'tier_key': 'solv', 'carryover_points': 250},
          {'tier_key': 'gull', 'carryover_points': 500},
          {'tier_key': 'platina', 'carryover_points': 1000},
        ],
      });

  testWidgets('report: non-banner feed children', (tester) async {
    final measured = <String, double>{};

    measured['points card'] = await measure(
      tester,
      DugnadHomeAnchorCard(
        summary: summary(),
        config: config(),
        teamRank: 7,
        teamTotal: 24,
        isGuest: false,
        onOpenPoints: () {},
        onOpenStoCard: () {},
        onConnectTeam: () {},
      ),
    );

    measured['season finale'] = await measure(
      tester,
      DugnadSeasonFinaleSection(
        summary: summary(),
        config: config(),
        seasonEndRaw: '2026-06-30',
        seasonBadgeCount: 3,
        dismissed: false,
        onDismiss: () {},
        onShowAgain: () {},
      ),
    );

    measured['earn row'] = await measure(
      tester,
      DugnadEarnPointsEntry(clubName: 'Fana IL', onTap: () {}),
    );

    measured['dg-pcar carousel'] = await measure(
      tester,
      DugnadCampaignCarousel(
        campaigns: [
          ClubCampaignSummary.fromJson(const {
            'id': 1,
            'title': 'Vintersalg hos Intersport',
            'partner_name': 'Intersport',
          }),
        ],
        clubLabel: 'Fana IL',
        campaignPoints: 50,
      ),
    );

    // Second pass at a width nothing can wrap at.
    final box = <String, double>{
      'points card': await measure(
        tester,
        DugnadHomeAnchorCard(
          summary: summary(), config: config(), teamRank: 7, teamTotal: 24,
          isGuest: false, onOpenPoints: () {}, onOpenStoCard: () {},
          onConnectTeam: () {},
        ),
        width: 860, viewport: 900),
      'season finale': await measure(
        tester,
        DugnadSeasonFinaleSection(
          summary: summary(), config: config(), seasonEndRaw: '2026-06-30',
          seasonBadgeCount: 3, dismissed: false, onDismiss: () {},
          onShowAgain: () {},
        ),
        width: 860, viewport: 900),
      'earn row': await measure(
        tester, DugnadEarnPointsEntry(clubName: 'Fana IL', onTap: () {}),
        width: 860, viewport: 900),
      'dg-pcar carousel': await measure(
        tester,
        DugnadCampaignCarousel(
          campaigns: [
            ClubCampaignSummary.fromJson(const {
              'id': 1,
              'title': 'Vintersalg hos Intersport',
              'partner_name': 'Intersport',
            }),
          ],
          clubLabel: 'Fana IL',
          campaignPoints: 50,
        ),
        width: 860, viewport: 900),
    };

    final rows = <String>[];
    design.forEach((label, d) {
      final app = measured[label]!;
      final pct = app / frame * 100;
      rows.add('  ${label.padRight(20)} '
          'design ${d[0].toStringAsFixed(1).padLeft(6)}  '
          'app ${app.toStringAsFixed(1).padLeft(6)} (${pct.toStringAsFixed(2)}%, '
          'delta ${(pct - d[1]).toStringAsFixed(2)} pp)  '
          'box ${box[label]!.toStringAsFixed(1).padLeft(6)}  '
          'box-delta ${(box[label]! - d[0]).toStringAsFixed(1).padLeft(6)}');
    });

    // ignore: avoid_print
    print('\n§5 non-banner feed children at the 375 frame, column $column:\n'
        '${rows.join('\n')}\n');

    expect(measured, hasLength(4));

    // A degenerate fixture does not fail — it renders a *different*, shorter
    // card and reports a confident delta. Both of these collapsed to exactly
    // 124.0 with an empty config, which is what gave the first pass its
    // -100pp and -132pp phantom findings.
    expect(measured['points card']!, greaterThan(220),
        reason: 'the points card has collapsed to its unpopulated state — '
            'check config.metalCarryover, not the summary');
    expect(measured['season finale']!, greaterThan(220),
        reason: 'the season card has collapsed to its unpopulated state — '
            'the carryover rows are gated on config, not on rating or '
            'seasonPoints');
  });

  testWidgets('earn row is the clean single-line comparison', (tester) async {
    // 42.0 in the design with no wrapping anywhere, so this row alone can be
    // compared directly without the box-vs-copy split.
    final h = await measure(
      tester,
      DugnadEarnPointsEntry(clubName: 'Fana IL', onTap: () {}),
    );
    // ignore: avoid_print
    print('earn row: design 42.0, app ${h.toStringAsFixed(1)}');
    expect(h, greaterThan(0));
  });
}
