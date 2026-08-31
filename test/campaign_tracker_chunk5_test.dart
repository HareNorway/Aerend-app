import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aerend_customer/l10n/app_localizations.dart';
import 'package:aerend_customer/main.dart' as app;
import 'package:aerend_customer/utils/shared_pref_utill.dart';
import 'package:aerend_customer/screens/dugnad/dugnad_club_theme.dart';
import 'package:aerend_customer/screens/dugnad/dugnad_celebration_orchestrator.dart';
import 'package:aerend_customer/screens/campaign/campaign_repo.dart';
import 'package:aerend_customer/screens/campaign/campaign_tracker_controller.dart';
import 'package:aerend_customer/screens/campaign/models/campaign_order_pojo.dart';
import 'package:aerend_customer/screens/campaign/widgets/campaign_tracker.dart';
import 'package:aerend_customer/screens/campaign/widgets/campaign_tracker_countdown.dart';

CampaignMyOrder mkOrder({
  required String no,
  required String name,
  required CampaignPurchaseState state,
  required DateTime window,
  String method = 'pickup',
  DateTime? bought,
}) {
  return CampaignMyOrder(
    id: no.hashCode,
    orderNo: no,
    campaignName: name,
    deliveryMethod: method,
    totalPay: 100,
    paymentStatus: 1,
    status: 1,
    state: state,
    windowStart: window,
    createdAt: bought?.toIso8601String(),
  );
}

Future<void> pumpTracker(
  WidgetTester tester,
  CampaignTrackerController controller, {
  bool reduced = false,
  VoidCallback? onOpen,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: MaterialApp(
        locale: const Locale('no'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DugnadClubThemeScope(
          palette: DugnadClubThemePalette.reenPreClub,
          child: Scaffold(
            body: Center(
              child: CampaignTracker(
                controller: controller,
                onOpenOverview: onOpen ?? () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(); // post-frame ensureLoaded + first tween frame
  await tester.pump(const Duration(milliseconds: 350)); // settle appear tween
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
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

  final now = DateTime.now();

  testWidgets('A. one awaiting order → name + countdown + method icon, no +N',
      (tester) async {
    final c = CampaignTrackerController.test()
      ..debugSetActive([
        mkOrder(
            no: 'A1',
            name: 'Grillkasse',
            state: CampaignPurchaseState.awaiting,
            window: now.add(const Duration(days: 5)),
            method: 'pickup'),
      ]);
    await pumpTracker(tester, c);

    expect(find.text('Grillkasse'), findsOneWidget);
    expect(find.byKey(const ValueKey('cp-tracker-pickup')), findsOneWidget);
    expect(find.byKey(const ValueKey('cp-tracker-rail-truck')), findsOneWidget);
    expect(find.byType(TrackerCountdown), findsOneWidget);
    expect(find.textContaining('til'), findsNothing); // no "+N mer"
  });

  testWidgets('B. three active → soonest window + "+2 til"', (tester) async {
    final c = CampaignTrackerController.test()
      ..debugSetActive([
        mkOrder(
            no: 'B2',
            name: 'Senere',
            state: CampaignPurchaseState.awaiting,
            window: now.add(const Duration(days: 9))),
        mkOrder(
            no: 'B1',
            name: 'Soonest',
            state: CampaignPurchaseState.awaiting,
            window: now.add(const Duration(days: 2))),
        mkOrder(
            no: 'B3',
            name: 'Sist',
            state: CampaignPurchaseState.locked,
            window: now.add(const Duration(days: 20))),
      ]);
    await pumpTracker(tester, c);

    expect(find.text('Soonest'), findsOneWidget);
    expect(find.text('Senere'), findsNothing);
    expect(find.text('+2 til'), findsOneWidget);
  });

  testWidgets('C. no active orders → renders nothing', (tester) async {
    final c = CampaignTrackerController.test()..debugSetActive([]);
    await pumpTracker(tester, c);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(find.byType(TrackerCountdown), findsNothing);
  });

  testWidgets(
      'I. home-shell Positioned (left/right/bottom) does not explode height',
      (tester) async {
    final c = CampaignTrackerController.test()
      ..debugSetActive([
        mkOrder(
            no: 'I1',
            name: 'Grillkasse',
            state: CampaignPurchaseState.awaiting,
            window: now.add(const Duration(days: 5))),
      ]);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: MaterialApp(
          locale: const Locale('no'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DugnadClubThemeScope(
            palette: DugnadClubThemePalette.reenPreClub,
            child: Scaffold(
              body: Stack(
                children: [
                  const SizedBox.expand(),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 92,
                    child: CampaignTracker(
                      controller: c,
                      onOpenOverview: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    expect(find.text('Grillkasse'), findsOneWidget);
    final box = tester.getRect(find.byType(ClipRRect));
    expect(box.height, lessThan(120),
        reason: 'pill must hug content; stretch+unbounded height fills the screen');
  });

  testWidgets('D. locked order → lock badge shown, still visible',
      (tester) async {
    final c = CampaignTrackerController.test()
      ..debugSetActive([
        mkOrder(
            no: 'D1',
            name: 'Låst kasse',
            state: CampaignPurchaseState.locked,
            window: now.add(const Duration(hours: 5)),
            method: 'delivery'),
      ]);
    await pumpTracker(tester, c);

    expect(find.text('Låst kasse'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsOneWidget);
    expect(find.byKey(const ValueKey('cp-tracker-delivery')), findsOneWidget);
    expect(find.byKey(const ValueKey('cp-tracker-rail-truck')), findsOneWidget);
  });

  testWidgets('E. reads shared suppression signal (hide/show)', (tester) async {
    final orch = DugnadCelebrationOrchestrator.instance;
    final c = CampaignTrackerController.test()
      ..debugSetActive([
        mkOrder(
            no: 'E1',
            name: 'Kasse',
            state: CampaignPurchaseState.awaiting,
            window: now.add(const Duration(days: 3))),
      ]);
    await pumpTracker(tester, c);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    orch.holdCriticalFlow(); // celebrations' own suppression signal
    await tester.pump();
    expect(find.byIcon(Icons.chevron_right), findsNothing,
        reason: 'tracker must hide under the shared blocked signal');

    orch.releaseCriticalFlow();
    await tester.pump();
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('F. dismiss (X) is in-memory only; next takes its place',
      (tester) async {
    final a = mkOrder(
        no: 'F1',
        name: 'Foerste',
        state: CampaignPurchaseState.awaiting,
        window: now.add(const Duration(days: 2)));
    final b = mkOrder(
        no: 'F2',
        name: 'Andre',
        state: CampaignPurchaseState.awaiting,
        window: now.add(const Duration(days: 6)));

    final c = CampaignTrackerController.test()..debugSetActive([a, b]);
    await pumpTracker(tester, c);
    expect(find.text('Foerste'), findsOneWidget);
    expect(find.text('Andre'), findsNothing);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450)); // cp-tracker-out 420ms
    expect(find.text('Foerste'), findsNothing);
    expect(find.text('Andre'), findsOneWidget); // next-soonest surfaces

    // Fresh controller = simulated reload → dismissal gone (no persistence).
    final c2 = CampaignTrackerController.test()..debugSetActive([a, b]);
    await pumpTracker(tester, c2);
    expect(find.text('Foerste'), findsOneWidget);
  });

  test('G. soon (<26h) branch + remaining clamps at zero', () {
    expect(trackerIsSoon(const Duration(hours: 10)), isTrue);
    expect(trackerIsSoon(const Duration(hours: 30)), isFalse);
    expect(trackerIsSoon(Duration.zero), isFalse); // expired, not "soon"
    final past = DateTime.now().subtract(const Duration(hours: 1));
    expect(trackerRemaining(past), Duration.zero); // never negative
  });

  test('H. progress straddling now is in (0,1); fallback when no boughtAt', () {
    final n = DateTime(2026, 5, 23, 12);
    final p = trackerProgress(
      DateTime(2026, 5, 13),
      DateTime(2026, 6, 2),
      now: n,
    );
    expect(p, greaterThan(0.0));
    expect(p, lessThan(1.0));

    // No boughtAt → 30-day fallback span, still within (0,1) near the window.
    final pf = trackerProgress(null, n.add(const Duration(days: 5)), now: n);
    expect(pf, greaterThan(0.0));
    expect(pf, lessThan(1.0));
  });

  testWidgets('H. dial is reduced-motion-safe (no animation, static)',
      (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          locale: const Locale('no'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DugnadClubThemeScope(
            palette: DugnadClubThemePalette.reenPreClub,
            child: Scaffold(
              body: Center(
                child: TrackerDial(
                  // soon window would trigger the pulse path — must stay gated.
                  windowStart: DateTime.now().add(const Duration(hours: 5)),
                  boughtAt: DateTime.now().subtract(const Duration(days: 5)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.binding.transientCallbackCount, 0,
        reason: 'reduced motion → no animation controller running');
    expect(find.byType(TrackerDial), findsOneWidget); // static value rendered
  });

  test('controller.refresh excludes archived (server-state filter)', () async {
    final c = CampaignTrackerController.test()..repo = _FakeRepo();
    await c.refresh();
    final states = c.visibleActive.map((o) => o.state).toSet();
    expect(c.visibleActive.length, 2); // awaiting + locked only
    expect(states.contains(CampaignPurchaseState.archived), isFalse);
    expect(states, containsAll(<CampaignPurchaseState>{
      CampaignPurchaseState.awaiting,
      CampaignPurchaseState.locked,
    }));
  });
}

class _FakeRepo extends CampaignRepo {
  @override
  Future<dynamic> getMyOrders() async {
    return {
      'status': 1,
      'orders': [
        {
          'id': 1, 'order_no': 'r1', 'delivery_method': 'pickup',
          'total_pay': 100, 'payment_status': 1, 'status': 1,
          'state': 'awaiting', 'window_start': '2026-06-07T15:00:00+00:00',
        },
        {
          'id': 2, 'order_no': 'r2', 'delivery_method': 'pickup',
          'total_pay': 100, 'payment_status': 1, 'status': 1,
          'state': 'locked', 'window_start': '2026-05-24T10:00:00+00:00',
        },
        {
          'id': 3, 'order_no': 'r3', 'delivery_method': 'pickup',
          'total_pay': 100, 'payment_status': 1, 'status': 1,
          'state': 'archived', 'window_start': '2026-05-16T15:00:00+00:00',
        },
      ],
    };
  }
}
