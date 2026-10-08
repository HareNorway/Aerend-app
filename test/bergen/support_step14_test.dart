import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aerend_customer/l10n/app_localizations.dart';
import 'package:aerend_customer/main.dart' as app;
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/hjelp/support.dart';
import 'package:aerend_customer/screens/bergen/sporing/hjelp_sheet.dart';
import 'package:aerend_customer/utils/shared_pref_utill.dart';

/// Backend plan Step 14 — the 1-tap support rating (CSAT): `can_rate` and
/// `csat_score` on every conversation payload, «Hvordan var hjelpen?» under a
/// closed thread, one tap sends, then «Takk for vurderingen!».
class _Api extends OpsCustomerApi {
  String state = 'assistant';
  bool canRate = false;

  /// What `rating` answers: null = 200, else the 422 code, or 'OFFLINE'.
  String? ratingError;
  final List<(int, int)> rated = [];

  @override
  Future<List<Map<String, dynamic>>> orders({int limit = 50}) async => const [];

  @override
  Future<List<Map<String, dynamic>>> pointsLedger() async => const [];

  @override
  Future<Map<String, dynamic>> tracking(int orderId) async => throw StateError('offline');

  Map<String, dynamic> _c({int? score, List<Map<String, dynamic>> messages = const []}) => {
    'id': 7,
    'topic': 'support',
    'state': state,
    'can_rate': canRate,
    'csat_score': score,
    'messages': messages,
  };

  @override
  Future<Map<String, dynamic>?> supportOpen({required String topic, int? orderId, String? guestToken}) async => {
    'conversation': _c(messages: [
      {'id': 1, 'author': 'assistant', 'body': 'Hei Kari. Hva kan jeg hjelpe med?', 'at': DateTime.now().toIso8601String()},
    ]),
  };

  @override
  Future<Map<String, dynamic>?> supportPoll(int id, int after, {String? guestToken}) async => {'conversation': _c()};

  @override
  Future<({Map<String, dynamic>? conversation, String? error})> rateConversation(int id, int score, {String? guestToken}) async {
    rated.add((id, score));
    final e = ratingError;
    if (e == 'OFFLINE') return (conversation: null, error: null);
    if (e != null) return (conversation: null, error: e);
    canRate = false;
    return (conversation: _c(score: score), error: null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    app.languages = await AppLocalizations.delegate.load(const Locale('no'));
    OpsCustomerApi.networkEnabled = false;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{prefUserId: 656, prefAccessToken: 'tok', prefUserName: 'Kari Nordmann'});
    await initSharedPreferences();
  });

  void phone(WidgetTester t) {
    t.view.physicalSize = const Size(390, 1600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
  }

  group('the payload', () {
    test('can_rate and csat_score are read off the conversation', () {
      final store = SupportStore.instance..reset(api: _Api());
      final s = store.ny(SupportTema.support, 'Support', serverId: 7);
      store.flett(s, {'id': 7, 'state': 'closed', 'can_rate': true, 'csat_score': null, 'messages': const []});
      expect(s.lukket, isTrue);
      expect(s.kanVurdere, isTrue);
      expect(s.vurdering, isNull);
      expect(s.visVurdering, isTrue);

      store.flett(s, {'id': 7, 'state': 'closed', 'can_rate': false, 'csat_score': 4});
      expect(s.kanVurdere, isFalse);
      expect(s.vurdering, 4);
      expect(s.visVurdering, isFalse);
    });

    test('an older server without the fields: false / null, no rating row', () {
      final store = SupportStore.instance..reset(api: _Api());
      final s = store.ny(SupportTema.support, 'Support', serverId: 7);
      store.flett(s, {'id': 7, 'state': 'closed', 'messages': const []});
      expect(s.lukket, isTrue);
      expect(s.kanVurdere, isFalse);
      expect(s.vurdering, isNull);
      expect(s.visVurdering, isFalse);
    });

    test('an open conversation never shows the row, even with can_rate', () {
      final store = SupportStore.instance..reset(api: _Api());
      final s = store.ny(SupportTema.support, 'Support', serverId: 7);
      store.flett(s, {'id': 7, 'state': 'human', 'can_rate': true});
      expect(s.visVurdering, isFalse);
    });

    test('ALREADY_RATED counts as thanks; any other failure does not', () async {
      final api = _Api()..ratingError = 'ALREADY_RATED';
      final store = SupportStore.instance..reset(api: api);
      final s = store.ny(SupportTema.support, 'Support', serverId: 7);
      store.flett(s, {'id': 7, 'state': 'closed', 'can_rate': true});
      expect(await store.vurder(s, 3), isTrue);
      expect(s.takket, isTrue);
      expect(s.visVurdering, isTrue);

      api.ratingError = 'CONVERSATION_OPEN';
      final t = store.ny(SupportTema.support, 'Support', serverId: 8);
      store.flett(t, {'id': 8, 'state': 'closed', 'can_rate': true});
      expect(await store.vurder(t, 3), isFalse);
      expect(t.takket, isFalse);
      expect(t.kanVurdere, isTrue);
    });
  });

  test('rateConversation never throws: offline or a score outside 1–5 is a plain miss', () async {
    final api = OpsCustomerApi();
    for (final score in [0, 3, 6]) {
      final r = await api.rateConversation(7, score);
      expect(r.conversation, isNull);
      expect(r.error, isNull);
    }
  });

  Future<_Api> openChat(WidgetTester tester) async {
    final api = _Api();
    SupportStore.instance.reset(api: api);
    await tester.pumpWidget(MaterialApp(home: HjelpScreen(api: api, orderId: 65, initial: HjelpState.kundeservice)));
    await settle(tester);
    await tester.tap(find.byKey(const Key('a1_sporing_ks_chat')));
    await settle(tester);
    expect(find.byKey(const Key('a1_hjelp_chat_felt')), findsOneWidget);
    return api;
  }

  testWidgets('no row while open, nor when closed without can_rate', (tester) async {
    phone(tester);
    final api = await openChat(tester);
    expect(find.byKey(const Key('a1_hjelp_vurdering')), findsNothing);

    api.state = 'closed';
    await tester.pump(const Duration(seconds: 6));
    await settle(tester);
    expect(find.byKey(const Key('a1_hjelp_chat_ny')), findsOneWidget);
    expect(find.byKey(const Key('a1_hjelp_vurdering')), findsNothing);

    SupportStore.instance.stoppPolling();
  });

  testWidgets('a poll that closes it shows the row; one tap sends that score and thanks', (tester) async {
    phone(tester);
    final api = await openChat(tester);

    api
      ..state = 'closed'
      ..canRate = true;
    await tester.pump(const Duration(seconds: 6));
    await settle(tester);
    expect(find.byKey(const Key('a1_hjelp_vurdering')), findsOneWidget);
    expect(find.text(SupportCopy.vurderSpor), findsOneWidget);
    for (var n = 1; n <= 5; n++) {
      expect(find.byKey(Key('a1_hjelp_vurdering_$n')), findsOneWidget);
    }
    // Still the way back to a new conversation.
    expect(find.byKey(const Key('a1_hjelp_chat_ny')), findsOneWidget);

    await tester.tap(find.byKey(const Key('a1_hjelp_vurdering_4')));
    await settle(tester);
    expect(api.rated, [(7, 4)]);
    expect(find.text(SupportCopy.vurderTakk), findsOneWidget);
    expect(find.text(SupportCopy.vurderSpor), findsNothing);
    // Read-only: the chosen stars, no buttons.
    expect(find.byKey(const Key('a1_hjelp_vurdering_1')), findsNothing);
    for (var n = 1; n <= 5; n++) {
      final icon = tester.widget<Icon>(find.descendant(of: find.byKey(Key('a1_hjelp_vurdering_vist_$n')), matching: find.byType(Icon)));
      expect(icon.color, n <= 4 ? const Color(0xFFF2C14E) : isNot(const Color(0xFFF2C14E)));
    }
    expect(SupportStore.instance.samtaler.single.vurdering, 4);

    SupportStore.instance.stoppPolling();
  });

  testWidgets('ALREADY_RATED shows the thanks', (tester) async {
    phone(tester);
    final api = await openChat(tester);
    api
      ..state = 'closed'
      ..canRate = true
      ..ratingError = 'ALREADY_RATED';
    await tester.pump(const Duration(seconds: 6));
    await settle(tester);

    await tester.tap(find.byKey(const Key('a1_hjelp_vurdering_2')));
    await settle(tester);
    expect(api.rated, [(7, 2)]);
    expect(find.text(SupportCopy.vurderTakk), findsOneWidget);

    SupportStore.instance.stoppPolling();
  });

  testWidgets('a failed send keeps the stars with a retry hint; a retry lands', (tester) async {
    phone(tester);
    final api = await openChat(tester);
    api
      ..state = 'closed'
      ..canRate = true
      ..ratingError = 'OFFLINE';
    await tester.pump(const Duration(seconds: 6));
    await settle(tester);

    await tester.tap(find.byKey(const Key('a1_hjelp_vurdering_5')));
    await settle(tester);
    expect(find.byKey(const Key('a1_hjelp_vurdering_feil')), findsOneWidget);
    expect(find.text(SupportCopy.vurderFeil), findsOneWidget);
    expect(find.text(SupportCopy.vurderTakk), findsNothing);

    api.ratingError = null;
    await tester.tap(find.byKey(const Key('a1_hjelp_vurdering_5')));
    await settle(tester);
    expect(api.rated, [(7, 5), (7, 5)]);
    expect(find.byKey(const Key('a1_hjelp_vurdering_feil')), findsNothing);
    expect(find.text(SupportCopy.vurderTakk), findsOneWidget);

    SupportStore.instance.stoppPolling();
  });
}
