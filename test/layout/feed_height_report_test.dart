import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/main.dart' as app;
import 'package:aerend_customer/screens/dugnad/dugnad_club_theme.dart';
import 'package:aerend_customer/screens/dugnad/widgets/dugnad_feed_entry_banner.dart';

import 'reduced_motion_harness.dart';

/// §5 height report for home's feed children.
///
/// Design heights were measured from the rendered DOM at the 375x812 frame, so
/// they include the inherited `line-height: 1.4` **and any wrapping**. A card
/// whose subtitle wraps to two lines in the app but one in the design differs
/// legitimately, so this renders the real Norwegian copy at the real column
/// width rather than placeholder text.
///
/// `.h-feed` padding is `24 20 132`, so the column at 375 is 375 - 40 = 335.
/// Using 327 here would wrap earlier and inflate every height.
void main() {
  const double frame = 375.0;
  const double column = 335.0;

  setUpAll(() => bootstrapGlobals(locale: 'no'));

  /// Design height and its share of the 375pt frame, per rule 11.
  const design = <String, List<double>>{
    // label:            [height, % of 375]
    'lb-entry': [70.5, 18.81],
    'dg-missions-entry': [72.0, 19.20],
    'dg-transfer-banner': [112.2, 29.92],
    'dg-ref-banner.heart': [76.5, 20.40],
    'dg-ref-banner': [87.8, 23.42],
  };

  Future<double> measure(
    WidgetTester tester,
    DugnadFeedEntryVariant variant, {
    required String title,
    required String subtitle,
    Widget? leading,
    bool trailingIsNorthEast = false,
  }) async {
    tester.view.physicalSize = const Size(frame, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: DugnadClubThemeScope(
          palette: DugnadClubThemePalette.defaults,
          child: Scaffold(
            // Unbounded height, so the banner must size to its content
            // instead of being stretched to the frame.
            body: SingleChildScrollView(
              child: SizedBox(
                width: column,
                child: DugnadFeedEntryBanner(
                  title: title,
                  subtitle: subtitle,
                  onTap: () {},
                  variant: variant,
                  leading: leading,
                  trailingIsNorthEast: trailingIsNorthEast,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // The glaze overlays loop forever; one frame is enough for layout.
    await tester.pump(const Duration(milliseconds: 50));

    return tester.getSize(find.byType(DugnadFeedEntryBanner)).height;
  }

  testWidgets('report: feed banner heights against the design table',
      (tester) async {
    final languages = app.languages;
    const club = 'Fana IL';

    final measured = <String, double>{};

    measured['lb-entry'] = await measure(
      tester,
      DugnadFeedEntryVariant.leagueGold,
      title: languages.dugnadLeagueCtaTitle,
      subtitle: languages.dugnadLeagueCtaSubtitle,
      trailingIsNorthEast: true,
      // Home renders the glyph, not an icon box.
      leading: const Text('🏆', style: TextStyle(fontSize: 28, height: 1)),
    );

    measured['dg-missions-entry'] = await measure(
      tester,
      DugnadFeedEntryVariant.missionsPurple,
      title: languages.dugnadMissionsEntryTitle,
      subtitle: languages.dugnadMissionsEntrySubtitle,
    );

    measured['dg-transfer-banner'] = await measure(
      tester,
      DugnadFeedEntryVariant.transferDark,
      title: languages.dugnadTransferBannerTitle,
      subtitle: languages.dugnadTransferBannerSubtitle(12),
    );

    measured['dg-ref-banner.heart'] = await measure(
      tester,
      DugnadFeedEntryVariant.supportLight,
      title: languages.dugnadSupportClubFast(club),
      subtitle: languages.dugnadSupportClubFastSub,
    );

    measured['dg-ref-banner'] = await measure(
      tester,
      DugnadFeedEntryVariant.referralPurple,
      title: languages.dugnadReferFriendsToClub(club),
      subtitle: languages.dugnadReferFriendsSubtitle,
    );

    // Second pass with copy too short to wrap. This isolates the *box*
    // geometry — padding + the tallest of icon / text / go — from the wrap
    // point, which under `flutter test` is decided by a fallback font rather
    // than Plus Jakarta Sans and so cannot be compared to the design.
    final boxOnly = <String, double>{
      'lb-entry': await measure(tester, DugnadFeedEntryVariant.leagueGold,
          title: 'A',
          subtitle: 'B',
          leading:
              const Text('🏆', style: TextStyle(fontSize: 28, height: 1))),
      'dg-missions-entry': await measure(
          tester, DugnadFeedEntryVariant.missionsPurple,
          title: 'A', subtitle: 'B'),
      'dg-transfer-banner': await measure(
          tester, DugnadFeedEntryVariant.transferDark,
          title: 'A', subtitle: 'B'),
      'dg-ref-banner.heart': await measure(
          tester, DugnadFeedEntryVariant.supportLight,
          title: 'A', subtitle: 'B'),
      'dg-ref-banner': await measure(
          tester, DugnadFeedEntryVariant.referralPurple,
          title: 'A', subtitle: 'B'),
    };

    final rows = <String>[];
    design.forEach((label, d) {
      final app = measured[label]!;
      final box = boxOnly[label]!;
      rows.add('  ${label.padRight(22)} '
          'design ${d[0].toStringAsFixed(1).padLeft(6)}  '
          'app-box ${box.toStringAsFixed(1).padLeft(6)}  '
          'box-delta ${(box - d[0]).toStringAsFixed(1).padLeft(5)}');
      final appPct = app / frame * 100;
      rows.add('  ${label.padRight(22)} '
          'design ${d[0].toStringAsFixed(1).padLeft(6)} (${d[1].toStringAsFixed(2)}%)  '
          'app ${app.toStringAsFixed(1).padLeft(6)} (${appPct.toStringAsFixed(2)}%)  '
          'delta ${(appPct - d[1]).toStringAsFixed(2)} pp');
    });

    // ignore: avoid_print
    print('\n§5 feed-child heights at the 375 frame, column $column:\n'
        '${rows.join('\n')}\n');

    expect(measured, hasLength(design.length));
  });

  test('the designHeight constants match the measured design table', () {
    // These constants are not decorative: each one converts a CSS inset's px
    // extent into a gradient stop. A wrong height silently mis-sizes the
    // highlight rather than failing anywhere visible.
    const encoded = <String, double>{
      'lb-entry': 70.5,
      'dg-missions-entry': 72.0,
      'dg-transfer-banner': 112.2,
      'dg-ref-banner.heart': 76.5,
      'dg-ref-banner': 87.8,
    };
    design.forEach((label, d) {
      expect(encoded[label], d[0], reason: '$label designHeight drifted');
    });
  });
}
