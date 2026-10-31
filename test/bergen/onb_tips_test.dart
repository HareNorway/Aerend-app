import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/onboarding/onb_maal.dart';
import 'package:aerend_customer/screens/bergen/onboarding/onb_runde.dart';
import 'package:aerend_customer/screens/bergen/onboarding/onb_status.dart';
import 'package:aerend_customer/screens/bergen/onboarding/onb_tips.dart';
import 'package:aerend_customer/services/customer/client_flags.dart';
import 'package:aerend_customer/utils/shared_pref_utill.dart';

import '../layout/reduced_motion_harness.dart';

/// Ægil-tips, Onboarding Step 4: the catalogue's precedence, the session and
/// day caps, the flag gate, the «?» dot after an auto-close.
void main() {
  setUpAll(() => bootstrapGlobals(locale: 'no'));

  final t = OnbTips.instance, st = OnbStatus.instance;
  setUp(() {
    t.reset();
    st.reset();
    OnbRunde.instance.reset();
    OnbMaalRegistry.reset();
    prefSetString('aerend.onb.v2', '');
    prefSetInt(prefUserId, 0);
    prefSetString(prefAccessToken, '');
    ClientFlags.flags = {OnbStatus.flagg: true, OnbStatus.flaggTips: true};
    st.hoppet = true; // the tour is out of the way
    t.hentOrdrer = () async => const [];
  });

  test('the catalogue is the design\'s sixteen marks in its order', () {
    expect(OnbTips.katalog.map((c) => c.id).toList(), [
      'peek', 'handoff', 'nytt', 'bio', 'kamera', 'adresse', 'fleks', 'gebyr', 'kode', 'varsler', 'hjelp', 'ai', 'abo', 'gaver', 'feed', 'pose',
    ]);
    expect(OnbTips.finn('fleks')!.flagg, 'pricing.flex_window');
    expect(OnbTips.katalog.where((c) => c.handling).map((c) => c.id), ['nytt', 'bio', 'gebyr', 'varsler', 'ai', 'abo', 'gaver', 'pose']);
    expect(OnbTips.finn('peek')!.autoMs, 3000);
  });

  test('precedence: the peek before «nytt», a mark with a target waits for the target, seen marks are skipped', () {
    // Off the shell nothing is «hjem»: the free marks need their screen.
    t.sett('hjelp', true);
    expect(t.velg(), 'hjelp');
    t.sett('varsler', true);
    expect(t.velg(), 'varsler'); // earlier in the order
    st.cm['varsler'] = 1; // seen before
    expect(t.velg(), 'hjelp');
    st.cm['hjelp'] = 1;
    expect(t.velg(), isNull);
    // A target mark without its anchor never wins.
    t.sett('sporing', 2);
    expect(t.velg(), isNull);
  });

  test('nothing when the tips flag is off, the tour is up, or the tour was never finished or skipped', () {
    t.sett('hjelp', true);
    expect(t.velg(), 'hjelp');
    ClientFlags.flags = {OnbStatus.flagg: true, OnbStatus.flaggTips: false};
    expect(t.kan, isFalse);
    expect(t.velg(), isNull);
    ClientFlags.flags = {OnbStatus.flagg: true, OnbStatus.flaggTips: true};
    st.hoppet = false;
    expect(t.kan, isFalse, reason: 'the tour has not run yet');
    st.ankomst = 'handoff';
    expect(t.kan, isTrue, reason: 'an arrival skipped the tour');
    ClientFlags.flags = {OnbStatus.flagg: false, OnbStatus.flaggTips: true};
    st.ankomst = null;
    expect(t.kan, isTrue, reason: 'the tour flag off: the tips stand alone');
  });

  test('one mark per session by itself, three per day; a forced one counts for neither', () {
    t.sett('hjelp', true);
    expect(t.vis('hjelp'), isTrue);
    expect(t.naa!.tip.id, 'hjelp');
    expect(t.sesjonAntall, 1);
    t.lukk();
    t.sett('varsler', true);
    expect(t.velg(), isNull, reason: 'session cap');
    t.sesjonAntall = 0;
    expect(t.velg(), 'varsler');
    final now = DateTime.now().millisecondsSinceEpoch;
    st.cm = {'a': now, 'b': now, 'c': now};
    expect(t.dagsKvoteBrukt, isTrue);
    expect(t.velg(), isNull, reason: 'day cap');
    expect(t.vis('varsler', tving: true), isTrue);
    expect(t.sesjonAntall, 0);
    expect(t.naa!.tving, isTrue);
  });

  testWidgets('the «?» dot stays on the target after an auto-close, and goes once the mark was acted on', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 200, 0, 0),
            child: OnbMaal(id: 'lev', radius: 22, child: SizedBox(width: 300, height: 60)),
          ),
        ),
      ),
    );
    t.sett('kurvRute', true);
    expect(t.kurv, isTrue);
    expect(t.velg(), 'gebyr', reason: 'fleks needs its flag');
    t.sjekk();
    expect(t.naa?.tip.id, 'gebyr');
    expect(t.naa!.m!.rect, const Rect.fromLTWH(16, 200, 300, 60));
    expect(t.prikk(), isNull, reason: 'no dot while the mark is up');
    await tester.pump(const Duration(seconds: 9)); // `auto_dismiss_seconds` 8
    expect(t.naa, isNull);
    final p = t.prikk()!;
    expect(p.id, 'gebyr');
    expect(p.m.x + p.m.w - 12, 304);
    expect(p.m.y - 5, 195);
    // Reopened from the dot, then its action used: no dot any more.
    expect(t.vis('gebyr', tving: true), isTrue);
    t.lukk(handlet: true);
    expect(st.cmHandlet, contains('gebyr'));
    expect(t.prikk(), isNull);
    // Older than `dot_days`: gone too.
    st.cmHandlet.clear();
    st.cm['gebyr'] = DateTime.now().subtract(const Duration(days: 8)).millisecondsSinceEpoch;
    expect(t.prikk(), isNull);
    // The target's unmount re-plans the tips a frame later: take the tree
    // down first, then cancel the plan / sync timers.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    t.reset();
    st.reset();
    await tester.pump(const Duration(seconds: 1));
  });

  test('the peek waits after a skip and «nytt» after a version bump; both only on Hjem', () {
    t.peekVentes = true;
    expect(t.velg(), isNull, reason: 'not on the shell');
    expect(OnbTips.finn('peek')!.naar(t), isFalse);
    st.ferdig = true;
    st.hoppet = false;
    st.versjon = 1;
    st.serverVersjon = 3;
    expect(st.nyVersjon, isTrue);
    expect(OnbTips.finn('nytt')!.naar(t), isFalse, reason: 'not on Hjem');
  });
}
