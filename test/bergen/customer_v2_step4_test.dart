import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/networking/ops/cus_api.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_betaling.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_kurv_screen.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_store.dart';
import 'package:aerend_customer/screens/bergen/ai/ai_tilbud.dart';
import 'package:aerend_customer/screens/bergen/hjem/hjem_harness.dart';
import 'package:aerend_customer/screens/bergen/meg/betaling_screen.dart';
import 'package:aerend_customer/services/customer/client_flags.dart';
import 'package:aerend_customer/utils/utils.dart';

import '../a3/a3_fakes.dart';

/// Customer v2 Step 4 (Commerce spec §6 stage 2) in the app: Meg → Betaling
/// lists, defaults, removes and adds saved cards (Stripe's sheet in setup
/// mode); «Lagret kort» with a default card confirms as `saved_card` with the
/// card, handles 3-D Secure, then asks `pay` with the intent id; without a
/// saved card the Stripe sheet path stays; with the flag off nothing changes.
class _Cus extends CusApi {
  final List<String> calls = [];
  CusAiRequest? request;
  List<CusSavedCard> cards = const [];
  bool requiresAction = false;
  Map<String, dynamic>? setup = const {'setup_intent': 'seti_1_secret_x', 'ephemeral_key': 'ek_x', 'customer_id': 'cus_x', 'publishable_key': 'pk_test_x'};

  @override
  Future<List<CusAiLink>?> aiLinks() async => const [];
  @override
  Future<List<CusAiClient>> aiClients() async => const [];
  @override
  Future<CusAiRequest?> aiRequestLatest() async => request;
  @override
  Future<CusAiRequest?> aiRequest(String id) async {
    calls.add('request:$id');
    return request;
  }

  @override
  Future<List<CusSavedCard>?> savedCards() async {
    calls.add('cards');
    return cards;
  }

  @override
  Future<Map<String, dynamic>?> savedCardSetup() async {
    calls.add('setup');
    return setup;
  }

  @override
  Future<List<CusSavedCard>?> savedCardDefault(String pm) async {
    calls.add('default:$pm');
    cards = [for (final c in cards) CusSavedCard(id: c.id, brand: c.brand, last4: c.last4, expMonth: c.expMonth, expYear: c.expYear, isDefault: c.id == pm)];
    return cards;
  }

  @override
  Future<List<CusSavedCard>?> savedCardDelete(String pm) async {
    calls.add('delete:$pm');
    cards = [for (final c in cards) if (c.id != pm) c];
    return cards;
  }

  @override
  Future<({CusAiBetaling? betaling, String? feil, CusAiRequest? request})> aiRequestConfirm(String id, {String payment = 'vipps', bool overLimitOk = false, String? paymentMethod}) async {
    calls.add('confirm:$id:$payment${paymentMethod == null ? '' : ':$paymentMethod'}');
    if (payment == 'saved_card') {
      return (betaling: CusAiBetaling(method: 'saved_card', status: requiresAction ? 'requires_action' : 'succeeded', clientSecret: 'pi_77_secret_abc', requiresAction: requiresAction, paymentMethod: paymentMethod), feil: null, request: request);
    }
    return (betaling: CusAiBetaling(method: payment), feil: null, request: request);
  }

  @override
  Future<({String resultat, CusAiOrder? order, CusAiRequest? request})> aiRequestPay(String id, {String? paymentResultRef}) async {
    calls.add('pay:$id${paymentResultRef == null ? '' : ':$paymentResultRef'}');
    return (resultat: 'confirmed', order: const CusAiOrder(id: 777, number: 'Æ-77X', paymentStatus: 'paid'), request: request);
  }

  @override
  Future<CusAiRequest?> aiRequestDecline(String id) async => request;
}

const _visa = CusSavedCard(id: 'pm_visa', brand: 'visa', last4: '4242', expMonth: 4, expYear: 2029, isDefault: true);
const _mc = CusSavedCard(id: 'pm_mc', brand: 'mastercard', last4: '4444', expMonth: 12, expYear: 2028);

void _phone(WidgetTester t) {
  t.view.physicalSize = const Size(390, 2400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

Future<void> _settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
  await t.pump(const Duration(milliseconds: 400));
}

Widget _kurv(_Cus cus) => MaterialApp(
  home: AiKurvScreen(id: 'q_sample', api: cus),
  onGenerateRoute: (s) => MaterialPageRoute(builder: (_) => Scaffold(body: Text('route:${s.name}'))),
);

Future<Future<bool>> _betalKort(WidgetTester tester) async {
  final state = tester.state(find.byType(AiKurvScreen)) as dynamic;
  final fut = state.betalNaa(payment: 'card') as Future<bool>;
  await _settle(tester);
  await tester.pump(const Duration(seconds: 2));
  await _settle(tester);
  return fut;
}

void main() {
  setUpAll(() async {
    await a3Bootstrap(prefs: {prefUserId: 656, prefAccessToken: 'tok', prefUserName: 'Kari Nordmann', prefUserVerified: 1});
  });
  late _Cus cus;
  setUp(() {
    cus = _Cus();
    AiStore.instance.reset();
    AiStore.instance.api = cus;
    HjemHarness.aiStart = null;
    ClientFlags.flags = {ClientFlags.aiLinking: true, ClientFlags.aiLinkedCheckout: true};
    AiBetaling.nextAction = (_) async {};
    AiBetaling.deviceCheck = () async => true;
  });

  group('Meg → Betaling', () {
    testWidgets('lists the saved cards with the default marked; «Bruk som standard» and «Fjern» go to the server', (tester) async {
      _phone(tester);
      cus.cards = const [_visa, _mc];
      await tester.pumpWidget(MaterialApp(home: BetalingScreen(api: cus)));
      await _settle(tester);
      expect(find.byKey(const Key('cus-bet-kort-pm_visa')), findsOneWidget);
      expect(find.byKey(const Key('cus-bet-kort-pm_mc')), findsOneWidget);
      expect(find.text('Visa •••• 4242'), findsOneWidget);
      expect(find.byKey(const Key('cus-bet-standard-pm_visa')), findsNothing, reason: 'the default has no «Bruk som standard»');
      expect(find.byKey(const Key('cus-bet-standard-pm_mc')), findsOneWidget);

      await tester.tap(find.byKey(const Key('cus-bet-standard-pm_mc')));
      await _settle(tester);
      expect(cus.calls, contains('default:pm_mc'));
      expect(find.byKey(const Key('cus-bet-standard-pm_visa')), findsOneWidget, reason: 'Visa is no longer the default');
      expect(find.byKey(const Key('cus-bet-standard-pm_mc')), findsNothing);

      await tester.tap(find.byKey(const Key('cus-bet-slett-pm_visa')));
      await _settle(tester);
      expect(find.text(BetalingCopy.cus_bet_slett_sporsmal('Visa •••• 4242')), findsOneWidget);
      await tester.tap(find.byKey(const Key('cus-bet-slett-ja')));
      await _settle(tester);
      expect(cus.calls, contains('delete:pm_visa'));
      expect(find.byKey(const Key('cus-bet-kort-pm_visa')), findsNothing);
      expect(find.byKey(const Key('cus-bet-kort-pm_mc')), findsOneWidget);
    });

    testWidgets('«Legg til kort»: the SetupIntent, Stripe sheet, then the list again and «Kortet er lagt til»', (tester) async {
      _phone(tester);
      final shown = <Map<String, dynamic>>[];
      await tester.pumpWidget(MaterialApp(home: BetalingScreen(api: cus, presentSetup: (s) async {
        shown.add(s);
        cus.cards = const [_visa];
      })));
      await _settle(tester);
      expect(find.byKey(const Key('cus-bet-ingen')), findsOneWidget);
      await tester.tap(find.byKey(const Key('cus-bet-legg-til')));
      await _settle(tester);
      expect(cus.calls, containsAllInOrder(['cards', 'setup', 'cards']));
      expect(shown.single['setup_intent'], 'seti_1_secret_x');
      expect(find.byKey(const Key('cus-bet-kort-pm_visa')), findsOneWidget);
      expect(find.text(BetalingCopy.cus_bet_lagt_til), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('a closed Stripe sheet adds nothing', (tester) async {
      _phone(tester);
      await tester.pumpWidget(MaterialApp(home: BetalingScreen(api: cus, presentSetup: (_) async => throw StateError('closed'))));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('cus-bet-legg-til')));
      await _settle(tester);
      expect(find.text(BetalingCopy.cus_bet_avbrutt), findsOneWidget);
      expect(find.byKey(const Key('cus-bet-ingen')), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('«Lagret kort» in the request', () {
    testWidgets('with a default saved card: confirm as saved_card with the card, then pay with the intent id', (tester) async {
      _phone(tester);
      cus.cards = const [_mc, _visa];
      cus.request = aiSampleRequest();
      await tester.pumpWidget(_kurv(cus));
      await _settle(tester);
      final fut = await _betalKort(tester);
      expect(cus.calls, contains('confirm:q_sample:saved_card:pm_visa'));
      expect(cus.calls, contains('pay:q_sample:pi_77'));
      expect(await fut, isTrue);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('3-D Secure: the bank step runs on the client secret before pay', (tester) async {
      _phone(tester);
      final secrets = <String>[];
      AiBetaling.nextAction = (s) async => secrets.add(s);
      cus.requiresAction = true;
      cus.cards = const [_visa];
      cus.request = aiSampleRequest();
      await tester.pumpWidget(_kurv(cus));
      await _settle(tester);
      final fut = await _betalKort(tester);
      expect(secrets, ['pi_77_secret_abc']);
      expect(cus.calls, contains('pay:q_sample:pi_77'));
      expect(await fut, isTrue);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('an abandoned 3-D Secure step: no pay, the request shows the failure', (tester) async {
      _phone(tester);
      AiBetaling.nextAction = (_) async => throw StateError('abandoned');
      cus.requiresAction = true;
      cus.cards = const [_visa];
      cus.request = aiSampleRequest();
      await tester.pumpWidget(_kurv(cus));
      await _settle(tester);
      final fut = await _betalKort(tester);
      expect(cus.calls.where((c) => c.startsWith('pay:')), isEmpty);
      expect(await fut, isFalse);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('no saved card: the ordinary card confirmation (the sheet path) as before', (tester) async {
      _phone(tester);
      cus.request = aiSampleRequest();
      await tester.pumpWidget(_kurv(cus));
      await _settle(tester);
      final fut = await _betalKort(tester);
      expect(cus.calls, contains('cards'));
      expect(cus.calls, contains('confirm:q_sample:card'));
      expect(await fut, isFalse);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('flag off: the saved cards are never asked for', (tester) async {
      _phone(tester);
      ClientFlags.flags = {ClientFlags.aiLinking: true};
      cus.cards = const [_visa];
      cus.request = aiSampleRequest();
      await tester.pumpWidget(_kurv(cus));
      await _settle(tester);
      final fut = await _betalKort(tester);
      expect(cus.calls, isNot(contains('cards')));
      expect(cus.calls, contains('confirm:q_sample:card'));
      expect(await fut, isFalse);
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
