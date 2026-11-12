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
  final borte = <int>[];

  setUp(() {
    vist.clear();
    borte.clear();
    NtfLiveCard.reset();
    NtfLiveCard.show = (id, t, b) async => vist.add((id, t, b));
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
    expect(vist.last.$2, 'Fremme');
    expect(vist.last.$1, vist.first.$1, reason: 'the same notification, changed');

    await NtfHooks.handleData(<String, dynamic>{'kind': 'ntf.live_card', 'object': 'order:412', 'live': '0'});
    expect(borte, <int>[NtfLiveCard.idFor(412)]);
    expect(NtfLiveCard.isShown(412), isFalse);
    await NtfLiveCard.end(412);
    expect(borte, hasLength(1), reason: 'ended once');
    NtfHooks.onLiveCard = null;
  });
}
