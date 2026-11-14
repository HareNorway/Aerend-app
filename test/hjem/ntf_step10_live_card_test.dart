import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/networking/ops/cus_api.dart';
import 'package:aerend_customer/services/ntf/ntf_hooks.dart';
import 'package:aerend_customer/services/ntf/ntf_live_card.dart';

import '../layout/reduced_motion_harness.dart';

/// Notifications plan Step 10 — the customer's live card: the card's two lines (stage · ETA; who · next step ·
/// «Åpne for koden», never the code); it starts only when the server has it on and the order is live; a silent
/// `ntf.live_card` push updates it (no new alert); delivered ends it.
class _Cus extends CusApi {
  _Cus(this.svar);

  final ({bool enabled, Map<String, dynamic> card})? svar;
  int lest = 0;

  @override
  Future<({bool enabled, Map<String, dynamic> card})?> liveCard(int orderId) async {
    lest++;
    return svar;
  }
}

void main() {
  setUpAll(() => bootstrapGlobals(locale: 'no'));

  final vist = <(int, String, String)>[];
  final visninger = <Map<String, Object?>>[];
  final borte = <int>[];

  setUp(() {
    vist.clear();
    visninger.clear();
    borte.clear();
    NtfLiveCard.reset();
    NtfLiveCard.show = (id, v) async {
      vist.add((id, '${v['title']}', '${v['sub']}'));
      visninger.add(v);
    };
    NtfLiveCard.cancel = (id) async => borte.add(id);
  });
  tearDown(NtfLiveCard.reset);

  const kort = <String, dynamic>{
    'object': 'order:412',
    'live': true,
    'stage_label': 'På vei',
    'eta': '2026-11-12T17:40:00Z',
    'who': 'Mari',
    'next_action': 'Følg budet',
    'open_for_code': true,
    'code': '4821',
    'state': 'picked_up',
    'stage': 2,
    'store': 'Burger King',
    'order_code': 'Æ-42K',
    'mode': 'delivery',
    'actor': 'courier',
    'store_area': 'Bryggen',
    'address': 'Nygårdsgaten 5',
    'first_name': 'Didrik',
  };

  test('the two lines: stage and ETA; who, next step and «Åpne for koden» — never the code', () {
    final (t, b) = NtfLiveCard.text(kort);
    expect(t, startsWith('På vei · ca. '));
    expect(b, 'Mari · Følg budet · Åpne for koden');
    expect('$t $b', isNot(contains('4821')));
    expect(NtfLiveCard.text(const <String, dynamic>{'live': '1'}).$1, 'Bestillingen din');
  });

  test('it starts only when the server has it on and the order is live', () async {
    NtfLiveCard.api = () => _Cus((enabled: false, card: kort));
    expect(await NtfLiveCard.start(412), isFalse);
    expect(vist, isEmpty, reason: '`ntf.live_card` off: no card');

    NtfLiveCard.api = () => _Cus((enabled: true, card: <String, dynamic>{...kort, 'live': false}));
    expect(await NtfLiveCard.start(412), isFalse, reason: 'not on its way');

    NtfLiveCard.api = () => _Cus((enabled: true, card: kort));
    expect(await NtfLiveCard.start(412), isTrue);
    expect(vist.single.$1, NtfLiveCard.idFor(412));

    // Where the app cannot show a card (iOS until the Live Activity), the card is not read — so the server never
    // marks it up and the customer keeps the stage pushes.
    final ios = _Cus((enabled: true, card: kort));
    NtfLiveCard.reset();
    NtfLiveCard.api = () => ios;
    expect(await NtfLiveCard.start(412), isFalse);
    expect(ios.lest, 0);
  });

  test('a silent push updates the card; delivered ends it', () async {
    NtfLiveCard.api = () => _Cus((enabled: true, card: kort));
    await NtfLiveCard.start(412);
    NtfHooks.onLiveCard = NtfLiveCard.fromPush;

    expect(await NtfHooks.handleData(<String, dynamic>{'kind': 'ntf.live_card', 'object': 'order:412', 'live': '1', 'stage_label': 'Fremme', 'who': 'Mari', 'next_action': 'Møt budet'}), isTrue,
        reason: 'a card update shows no alert');
    expect(visninger.last['stage'], 2);
    expect(vist.last.$1, vist.first.$1, reason: 'the same notification, changed');

    await NtfHooks.handleData(<String, dynamic>{'kind': 'ntf.live_card', 'object': 'order:412', 'live': '0'});
    expect(borte, <int>[NtfLiveCard.idFor(412)]);
    expect(NtfLiveCard.isShown(412), isFalse);
    await NtfLiveCard.end(412);
    expect(borte, hasLength(1), reason: 'ended once');
    NtfHooks.onLiveCard = null;
  });

  group('the «Ærend Kunde Bergen» lock-screen card (2026-11-14)', () {
    final naa = DateTime(2026, 11, 14, 14, 42);
    setUp(() => NtfLiveCard.now = () => naa);
    Map<String, dynamic> k(Map<String, dynamic> m) => <String, dynamic>{...kort, ...m};
    final eta = DateTime(2026, 11, 14, 14, 55).toUtc().toIso8601String();

    test('the stages say what the design says', () {
      final lages = NtfLiveCard.view(412, k({'state': 'accepted', 'stage': 1, 'eta': eta}));
      expect([lages['title'], lages['sub'], lages['code'], lages['live']], ['Maten lages', 'Burger King · Bryggen', 'Æ-42K', 'LIVE']);
      expect([lages['time_sub'], lages['route'], lages['link']], ['ankommer 14:55', 'Burger King → Nygårdsgaten 5', 'aerendapp://bergen/sporing/412']);
      expect(lages['eta_ms'], DateTime.parse(eta).millisecondsSinceEpoch, reason: 'the countdown runs to the time');
      expect(lages['labels'], ['Bekreftet', 'Tilberedes', 'På vei', 'Levert']);
      expect(lages['ongoing'], isTrue);

      expect(NtfLiveCard.view(412, k({'state': 'placed', 'stage': 0}))['title'], 'Bestilling bekreftet');
      expect(NtfLiveCard.view(412, k({'state': 'placed', 'stage': 0}))['sub'], 'Burger King har fått bestillingen');
      final vei = NtfLiveCard.view(412, k({'state': 'picked_up', 'stage': 2}));
      expect([vei['title'], vei['sub'], vei['rider']], ['Ægil er på vei', 'Ægil sykler til Nygårdsgaten 5', 'bike']);
      final butikkKjorer = NtfLiveCard.view(412, k({'state': 'picked_up', 'stage': 2, 'actor': 'partner'}));
      expect([butikkKjorer['title'], butikkKjorer['sub'], butikkKjorer['rider']], ['Maten er på vei', 'Burger King kjører til Nygårdsgaten 5', 'van']);
    });

    test('a pickup: «Klar for henting», the code to show at the counter, «Klar nå!»', () {
      final v = NtfLiveCard.view(412, k({'state': 'ready', 'stage': 2, 'mode': 'pickup', 'eta': eta}));
      expect([v['title'], v['sub'], v['time_text'], v['time_sub'], v['eta_ms']], ['Klar for henting', 'Vis koden Æ-42K i disken', 'Klar nå!', 'i disken nå', null]);
      expect([v['route'], v['labels']], ['Henting · Burger King, Bryggen', ['Bekreftet', 'Tilberedes', 'Klar', 'Hentet']]);
    });

    test('delivered: «Levert på døra», FERDIG, not ongoing, gone after a while — and never the delivery code', () {
      final v = NtfLiveCard.view(412, k({'state': 'delivered', 'stage': 3, 'live': false, 'delivered_at': DateTime(2026, 11, 14, 14, 58).toUtc().toIso8601String()}));
      expect([v['title'], v['sub'], v['live'], v['time_text'], v['time_sub']], ['Levert på døra', 'God appetitt, Didrik!', 'FERDIG', 'Levert!', 'levert 14:58']);
      expect([v['ongoing'], v['timeout_ms'], v['progress']], [false, NtfLiveCard.ferdigVises.inMilliseconds, 1.0]);
      for (final s in [v, NtfLiveCard.view(412, kort)]) {
        expect(s.values.join(' '), isNot(contains('4821')));
      }
    });

    test('an order push while the app was closed: delivered ends on «Levert», cancelled takes it away', () async {
      NtfLiveCard.api = () => _Cus((enabled: true, card: k({'state': 'accepted', 'stage': 1})));
      await NtfLiveCard.start(412);
      expect(visninger.last['title'], 'Maten lages');

      await NtfLiveCard.onPush(<String, dynamic>{'type': 'customer.order.delivered', 'order_id': '412'});
      expect(visninger.last['title'], 'Levert på døra');
      expect(visninger.last['sub'], 'God appetitt, Didrik!', reason: 'drawn from the card it remembered');
      expect(NtfLiveCard.isShown(412), isFalse);

      // A delivered push for an order with no card shows nothing.
      final n = visninger.length;
      await NtfLiveCard.onPush(<String, dynamic>{'type': 'customer.order.delivered', 'order_id': '999'});
      expect(visninger, hasLength(n));

      await NtfLiveCard.start(412);
      await NtfLiveCard.onPush(<String, dynamic>{'type': 'customer.order.cancelled', 'order_id': '412'});
      expect(borte.last, NtfLiveCard.idFor(412));
    });
  });
}
