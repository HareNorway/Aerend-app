import 'package:flutter/material.dart';
import 'package:aerend_customer/l10n/app_localizations.dart';
import 'package:aerend_customer/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aerend_customer/data/aegil/aegil_app_models.dart';
import 'package:aerend_customer/data/aegil/aegil_app_repo.dart';
import 'package:aerend_customer/data/aegil/aegil_models.dart';
import 'package:aerend_customer/data/aegil/aegil_repo.dart';
import 'package:aerend_customer/data/aegil/suggestion_models.dart';
import 'package:aerend_customer/data/points/league_models.dart';
import 'package:aerend_customer/data/points/points_app_repo.dart';
import 'package:aerend_customer/data/points/points_models.dart';
import 'package:aerend_customer/screens/bergen/meg/a3_services.dart';
import 'package:aerend_customer/screens/bergen/bergen_routes_agil3.dart';
import 'package:aerend_customer/utils/shared_pref_utill.dart';

/// Shared fakes for the agil-3 Phase 7 widget tests: every screen renders from
/// these, nothing touches the network.
Future<void> a3Bootstrap({Map<String, Object> prefs = const {}}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{
    'userName': 'Kari Nordmann',
    'referralCode': 'KARI200',
    ...prefs,
  });
  await initSharedPreferences();
  // AGIL-1 v2 Phase 8: the copy classes read the ARB through `languages`.
  app.languages = await AppLocalizations.delegate.load(const Locale('no'));
  A3Services.reset();
}

Widget a3App(Widget home) =>
    MaterialApp(home: home, routes: bergenRoutesAgil3());

const kPrize = Prize(
  id: 7,
  name: 'Kaffe hos Kaffemisjonen',
  pointPrice: 300,
  tierBand: 1,
  tierName: 'Fløyen',
  line: 'To kopper, én regning',
  partnerName: 'Kaffemisjonen',
  affordable: true,
  claimable: true,
);
const kPrizeFar = Prize(
  id: 8,
  name: 'Fløibanen tur-retur',
  pointPrice: 900,
  tierBand: 1,
  tierName: 'Fløyen',
  partnerName: 'Fløibanen',
  affordable: false,
  claimable: false,
);
const kPrizeSoldOut = Prize(
  id: 9,
  name: 'Skillingsboller',
  pointPrice: 120,
  tierBand: 1,
  tierName: 'Fløyen',
  inStock: false,
);

class FakePointsApi implements PointsAppApi {
  FakePointsApi({
    this.shelfValue,
    this.balanceValue,
    this.leagueValue,
    this.missionValue,
    this.pickValue,
    this.earnValues = const [],
  });

  Premiehylla? shelfValue;
  PointsBalance? balanceValue;
  League? leagueValue;
  Mission? missionValue;
  AegilPick? pickValue;
  List<EarnResult> earnValues;
  final List<String> calls = [];

  @override
  Future<PointsBalance?> balance() async =>
      balanceValue ??
      const PointsBalance(
        available: 420,
        pending: 30,
        earned12m: 1200,
        tier: 1,
        tierName: 'Fløyen',
        nextTierName: 'Ulriken',
        pointsToNextTier: 800,
      );

  @override
  Future<Premiehylla?> shelf() async =>
      shelfValue ??
      const Premiehylla(
        prizes: [kPrize, kPrizeFar, kPrizeSoldOut],
        previews: [
          PrizePreview(
            id: 20,
            name: 'Middag på Bryggen',
            pointPrice: 1500,
            tierName: 'Ulriken',
            pointsToUnlock: 800,
            teaser: 'Fra Ulriken',
          ),
        ],
        goal: PointGoal(
          kind: 'prize',
          label: 'Fløibanen tur-retur',
          current: 420,
          target: 900,
          remaining: 480,
          percent: 46,
          prizeId: 8,
        ),
      );

  @override
  Future<List<PrizeClaim>> claims() async => const [
    PrizeClaim(
      id: 1,
      prizeId: 3,
      prizeName: 'Gratis levering',
      state: 'claimed',
      pointsSpent: 0,
    ),
  ];

  @override
  Future<({PrizeClaim? claim, String? error})> claim(
    int prizeId, {
    String? identityName,
  }) async {
    calls.add('claim:$prizeId');
    return (
      claim: PrizeClaim(
        id: 2,
        prizeId: prizeId,
        prizeName: 'Premie',
        state: 'claimed',
        pointsSpent: 300,
        voucherCode: 'KAFFE-1',
      ),
      error: null,
    );
  }

  @override
  Future<PointGoal?> setGoal({int? prizeId, int? tier}) async {
    calls.add('goal:${prizeId ?? tier}');
    return PointGoal(
      kind: 'prize',
      label: 'Mål',
      current: 0,
      target: 1,
      remaining: 1,
      percent: 0,
      prizeId: prizeId,
    );
  }

  @override
  Future<Mission?> mission() async =>
      missionValue ??
      const Mission(
        id: 1,
        title: 'Handle hos to bergenske butikker',
        body: 'Denne uka',
        points: 50,
      );

  @override
  Future<({Mission? replacement, String? error})> declineMission() async {
    calls.add('decline');
    return (replacement: null, error: null);
  }

  @override
  Future<League?> league() async =>
      leagueValue ??
      const League(
        month: '2026-09',
        optedIn: true,
        participants: 120,
        top: [
          LeagueStanding(
            rank: 1,
            userId: 100,
            points: 1000,
            bydel: 'Bergenhus',
          ),
          LeagueStanding(rank: 2, userId: 101, points: 900, bydel: 'Årstad'),
        ],
        own: LeagueStanding(
          rank: 14,
          userId: 999,
          points: 320,
          bydel: 'Årstad',
        ),
        bydel: 'Årstad',
        bydelStandings: [
          LeagueStanding(rank: 14, userId: 999, points: 320, bydel: 'Årstad'),
        ],
      );

  @override
  Future<bool> leagueOptIn(bool optIn) async {
    calls.add('optin:$optIn');
    return true;
  }

  @override
  Future<Referral?> referral() async =>
      const Referral(code: 'KARI200', link: 'https://aerend.no/r/KARI200');

  @override
  Future<AegilPick?> pick() async {
    calls.add('pick');
    return pickValue ??
        const AegilPick(
          prize: {
            'id': 7,
            'name': 'Kaffe hos Kaffemisjonen',
            'point_price': 300,
            'partner_name': 'Kaffemisjonen',
          },
          reason: 'Du har vært der tre torsdager på rad.',
          valueHint: 'Verdi minst 300 kr',
          affordable: true,
        );
  }

  @override
  Future<EarnResult?> earn({
    required int catchNumber,
    int? suggestionId,
  }) async {
    calls.add('earn:$catchNumber');
    if (earnValues.isNotEmpty)
      return earnValues[(catchNumber - 1) % earnValues.length];
    return EarnResult(
      earned: 5,
      today: 5 * catchNumber,
      max: 5,
      capped: catchNumber >= 5,
    );
  }
}

const kSuggestion = Suggestion(
  id: 11,
  reasonCode: 'offer',
  reason: 'Tilbud hos Torgboden',
  headline: 'Reker fra Torgboden',
  storeId: 3,
);
const kSuggestion2 = Suggestion(
  id: 12,
  reasonCode: 'rhythm',
  reason: 'Torsdag er tacodag',
  headline: 'Tacokveld for fire',
  storeId: 4,
);

class FakeAegilApi implements AegilAppApi {
  FakeAegilApi({
    this.turn,
    this.awayValue = const [],
    this.suggestionValue = const [kSuggestion, kSuggestion2],
  });

  AegilTurn? turn;
  List<AwayItem> awayValue;
  List<Suggestion> suggestionValue;
  final List<String> calls = [];

  @override
  Future<AegilTurn?> chat({String? text, String? intent, int? storeId}) async {
    calls.add('chat:${text ?? intent}');
    return turn ??
        const AegilTurn(
          state: 'agForslag',
          reply: 'Tacokveld for fire — under 500 kr hos Torgboden.',
          basket: AegilBasket(
            lines: [
              AegilBasketLine(name: 'Tortilla', qty: 2, priceOre: 2990),
              AegilBasketLine(name: 'Kjøttdeig', qty: 1, priceOre: 7990),
            ],
            storeName: 'Torgboden',
            subtotalOre: 13970,
            derfor: 'billigst av tre',
          ),
          cards: [kSuggestion],
        );
  }

  @override
  Future<List<Suggestion>> suggestions({String? context}) async {
    calls.add('suggestions:$context');
    return suggestionValue;
  }

  @override
  Future<bool> add(int suggestionId) async {
    calls.add('add:$suggestionId');
    return true;
  }

  @override
  Future<bool> dismiss(int suggestionId) async {
    calls.add('dismiss:$suggestionId');
    return true;
  }

  @override
  Future<bool> never(int suggestionId, String reasonCode) async {
    calls.add('never:$suggestionId:$reasonCode');
    return true;
  }

  @override
  Future<List<AwayItem>> away() async => awayValue;

  @override
  Future<TrustLedger?> trustLedger() async => const TrustLedger(
    month: '2026-09',
    savedKr: 312,
    findsApplied: 4,
    againstInterestShown: 2,
    waitRecommended: 1,
  );

  @override
  Future<AegilTurn?> photoOrder(List<String> items) async =>
      const AegilTurn(state: 'agFunn', reply: 'Fant alt.');

  @override
  Future<String?> doorNote(String note) async {
    calls.add('door:$note');
    return note;
  }
}

class FakeAegilRepo extends AegilRepo {
  final List<String> calls = [];
  List<MemoryEntry> memory = const [
    MemoryEntry(
      id: 1,
      kind: 'like',
      value: 'reker',
      label: 'Reker',
      source: 'chips',
    ),
    MemoryEntry(
      id: 2,
      kind: 'store',
      value: 'torgboden',
      label: 'Torgboden',
      source: 'orders',
    ),
    MemoryEntry(
      id: 3,
      kind: 'allergen',
      value: 'nøtter',
      label: 'Ingen nøtter',
      source: 'chips',
      hardConstraint: true,
    ),
  ];

  @override
  Future<({AegilSettings? settings, List<AegilLevel> levels})>
  fetchSettings() async => (
    settings: const AegilSettings(level: 2, levelName: 'Varsle og foreslå'),
    levels: const [
      AegilLevel(level: 1, name: 'Bare svar', body: 'Svarer når du spør'),
      AegilLevel(
        level: 2,
        name: 'Varsle og foreslå',
        body: 'Sier fra om tilbud',
      ),
    ],
  );

  @override
  Future<({AegilSettings? settings, String? error})> updateSettings(
    Map<String, dynamic> changes,
  ) async {
    calls.add('settings:$changes');
    return (
      settings: const AegilSettings(level: 2, levelName: 'Varsle og foreslå'),
      error: null,
    );
  }

  @override
  Future<List<MemoryEntry>> fetchMemory() async => memory;

  @override
  Future<bool> forgetAll() async {
    calls.add('forget');
    memory = const [];
    return true;
  }

  @override
  Future<({int stored, String? error})> submitChips(
    List<OnboardingChip> chips,
  ) async {
    calls.add('chips:${chips.map((c) => c.value).join(',')}');
    return (stored: chips.length, error: null);
  }
}
