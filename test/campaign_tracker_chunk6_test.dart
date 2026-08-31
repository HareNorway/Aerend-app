import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aerend_customer/l10n/app_localizations.dart';
import 'package:aerend_customer/main.dart' as app;
import 'package:aerend_customer/utils/shared_pref_utill.dart';
import 'package:aerend_customer/screens/campaign/campaign_delivery_utils.dart';
import 'package:aerend_customer/screens/campaign/campaign_purchases_screen.dart';
import 'package:aerend_customer/screens/campaign/models/campaign_order_pojo.dart';
import 'package:aerend_customer/screens/dugnad/dugnad_club_theme.dart';

CampaignMyOrder mkOrder({
  required String no,
  required String name,
  required CampaignPurchaseState state,
  DateTime? window,
  String method = 'pickup',
  int points = 0,
  double total = 749,
  DateTime? lockAt,
}) {
  return CampaignMyOrder(
    id: no.hashCode,
    orderNo: no,
    campaignName: name,
    deliveryMethod: method,
    totalPay: total,
    paymentStatus: 1,
    status: 1,
    state: state,
    windowStart: window,
    earnedPoints: points,
    clubName: 'Sædalen IL',
    teamName: 'Gutter 16',
    productSummary: 'Grillkasse Familie',
    methodChangeLockAt: lockAt,
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('nb');
    await initializeDateFormatting('en');
    SharedPreferences.setMockInitialValues(<String, Object>{
      'UserId': 5,
      'AccessToken': 'tok',
      'userVerified': 1,
      'dugnadModeEnabled': true,
      'selectedClubId': 1,
    });
    await initSharedPreferences();
    app.languages = await AppLocalizations.delegate.load(const Locale('no'));
  });

  group('split + format helpers', () {
    test('campaignActiveOrders / campaignArchivedOrders follow server state', () {
      final awaiting = mkOrder(
        no: '1',
        name: 'A',
        state: CampaignPurchaseState.awaiting,
      );
      final locked = mkOrder(
        no: '2',
        name: 'B',
        state: CampaignPurchaseState.locked,
      );
      final archived = mkOrder(
        no: '3',
        name: 'C',
        state: CampaignPurchaseState.archived,
        points: 40,
      );
      final unknown = mkOrder(
        no: '4',
        name: 'D',
        state: CampaignPurchaseState.unknown,
      );
      final all = [awaiting, locked, archived, unknown];
      expect(campaignActiveOrders(all).map((o) => o.orderNo), ['1', '2']);
      expect(campaignArchivedOrders(all).map((o) => o.orderNo), ['3']);
      expect(campaignArchivePointsSum(campaignArchivedOrders(all)), 40);
    });

    test('campaignKr formats whole and fractional NOK', () {
      expect(campaignKr(749), '749 kr');
      expect(campaignKrNumber(39), '39');
      expect(campaignKr(39.5), '39,50 kr');
    });

    test('day and clock labels use the given locale, single time', () {
      final dt = DateTime(2026, 6, 7, 16, 0);
      expect(campaignDayLabel(dt, locale: 'nb'), '7. juni 2026');
      expect(campaignClockLabel(dt, locale: 'nb'), 'kl. 16:00');
      expect(campaignClockLabel(dt, locale: 'en'), 'kl. 16:00');
    });

    test('lock-at label matches prototype fmtLockAt (day month kl. time)', () {
      final dt = DateTime(2026, 5, 23, 11, 0);
      expect(campaignLockAtLabel(dt, locale: 'nb'), '23. mai kl. 11:00');
    });

    test('otherMethod / otherMethodOffered', () {
      final o = CampaignMyOrder(
        id: 1,
        orderNo: '1',
        deliveryMethod: 'pickup',
        totalPay: 0,
        paymentStatus: 1,
        status: 1,
        state: CampaignPurchaseState.awaiting,
        methodsOffered: const ['pickup'],
      );
      expect(o.isPickup, isTrue);
      expect(o.otherMethod, 'delivery');
      expect(o.otherMethodOffered, isFalse);
      expect(o.isActiveLifecycle, isTrue);
    });
  });

  group('Kampanjekjøp overview', () {
    testWidgets('empty active tab shows empty copy', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('no'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DugnadClubThemeScope(
            palette: DugnadClubThemePalette.defaults,
            child: CampaignPurchasesScreen(debugOrders: const []),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Kampanjekjøp'), findsOneWidget);
      expect(find.text('Ingen aktive kjøp'), findsOneWidget);
    });

    testWidgets('tabs split active vs archive and show receipt title',
        (tester) async {
      final orders = [
        mkOrder(
          no: 'a',
          name: 'Sommerens grillkasse',
          state: CampaignPurchaseState.awaiting,
          window: DateTime(2026, 6, 7, 16),
          points: 75,
        ),
        mkOrder(
          no: 'b',
          name: 'Frukt- & bærkasse',
          state: CampaignPurchaseState.archived,
          window: DateTime(2026, 5, 21, 16),
          points: 40,
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('no'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DugnadClubThemeScope(
            palette: DugnadClubThemePalette.defaults,
            child: CampaignPurchasesScreen(debugOrders: orders),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Sommerens grillkasse'), findsOneWidget);
      expect(find.text('Frukt- & bærkasse'), findsNothing);
      expect(find.text('+75'), findsOneWidget);
      expect(find.text('POENG'), findsOneWidget);

      await tester.tap(find.text('Arkiv'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Frukt- & bærkasse'), findsOneWidget);
      expect(find.text('Sommerens grillkasse'), findsNothing);
    });

    testWidgets('locked receipt uses design lock copy', (tester) async {
      final orders = [
        mkOrder(
          no: 'a',
          name: 'Fersk fiskekasse',
          state: CampaignPurchaseState.locked,
          window: DateTime(2026, 5, 24, 11),
          points: 65,
          lockAt: DateTime(2026, 5, 23, 11, 0),
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('no'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DugnadClubThemeScope(
            palette: DugnadClubThemePalette.defaults,
            child: CampaignPurchasesScreen(debugOrders: orders),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.textContaining('den gikk ut 23. mai kl. 11:00'),
        findsOneWidget,
      );
      expect(find.textContaining('på hentestedet'), findsOneWidget);
      expect(find.text('+65'), findsOneWidget);
    });
  });
}
