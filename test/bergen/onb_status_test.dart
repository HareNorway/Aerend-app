import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/onboarding/onb_runde.dart';
import 'package:aerend_customer/screens/bergen/onboarding/onb_status.dart';
import 'package:aerend_customer/services/customer/client_flags.dart';
import 'package:aerend_customer/utils/shared_pref_utill.dart';

import '../layout/reduced_motion_harness.dart';

/// Onboarding Step 3: the state (cache + server merge), the trigger's gates,
/// the Hjem card and the Meg row's «Nytt».
class _FakeApi extends OpsCustomerApi {
  _FakeApi(this.svar);
  final Map<String, dynamic>? svar;
  final List<Map<String, Object?>> skrevet = [];

  @override
  Future<Map<String, dynamic>?> onboarding() async => svar;

  @override
  Future<Map<String, dynamic>?> setOnboarding(Map<String, Object?> body) async {
    skrevet.add(body);
    return {'status': 1};
  }
}

void main() {
  setUpAll(() => bootstrapGlobals(locale: 'no'));

  final st = OnbStatus.instance;
  setUp(() {
    st.reset();
    prefSetString('aerend.onb.v2', '');
    prefSetInt(prefUserId, 0);
    prefSetString(prefAccessToken, '');
    ClientFlags.flags = {OnbStatus.flagg: true};
  });

  test('the trigger stays away when the flag is off, after a finish or a skip, and on a hand-off arrival', () {
    expect(OnbRunde.hindring(st), isNull);
    ClientFlags.flags = {OnbStatus.flagg: false};
    expect(OnbRunde.hindring(st), 'flagget er av');
    ClientFlags.flags = {};
    expect(OnbRunde.hindring(st), 'flagget er av'); // unknown = off
    ClientFlags.flags = {OnbStatus.flagg: true};
    st.ferdig = true;
    expect(OnbRunde.hindring(st), 'fullført før');
    st.ferdig = false;
    st.hoppet = true;
    expect(OnbRunde.hindring(st), 'hoppet over før');
    st.hoppet = false;
    st.ankomst = 'handoff';
    expect(OnbRunde.hindring(st), 'ankomst handoff');
  });

  test('the cache survives a restart (a reinstall keeps nothing; the server fills it in)', () async {
    st.merkSett('intro');
    st.merkSett('adresse');
    st.merkPos('tillatt');
    st.merkFerdig(msTotal: 61000);
    st.reset();
    expect(st.ferdig, isFalse);
    await st.last();
    expect(st.ferdig, isTrue);
    expect(st.sett, {'intro', 'adresse'});
    expect(st.pos, 'tillatt');
    expect(st.versjon, OnbStatus.kVersjon);
  });

  test('the server wins for completed_at and adds its seen steps, marks and the newer version', () async {
    prefSetInt(prefUserId, 656);
    prefSetString(prefAccessToken, 'tok');
    st.merkSett('intro');
    final api = _FakeApi({
      'status': 1,
      'config': {'version': 4, 'coach_marks': {'session_cap': 1, 'daily_cap': 2, 'auto_dismiss_seconds': 6, 'dot_days': 7}},
      'state': {
        'completed_at': '2026-10-30T10:00:00+00:00',
        'skipped_at': null,
        'steps_seen': ['intro', 'fiske'],
        'coach_marks_seen': {'gebyr': {'seen_at': '2026-10-30T10:01:00+00:00', 'acted': true}},
        'position': 'avslatt',
        'home_card_dismissed': true,
        'onboarding_version': 3,
      },
    });
    st.reset();
    st.api = () => api;
    await st.last();
    expect(st.ferdig, isTrue); // a reinstall or a second device does not replay the tour
    expect(OnbRunde.hindring(st), 'fullført før');
    expect(st.sett, containsAll(['intro', 'fiske']));
    expect(st.cm.keys, contains('gebyr'));
    expect(st.cmHandlet, contains('gebyr'));
    expect(st.pos, 'avslatt');
    expect(st.hjemKort, isTrue);
    expect(st.serverVersjon, 4);
    expect(st.cmDag, 2);
    // Done at version 3, the server has 4: «Nytt» on the Meg row.
    expect(st.nyVersjon, isTrue);
    // And the merged state goes back up.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    expect(api.skrevet, isNotEmpty);
    expect(api.skrevet.last['completed'], isTrue);
  });

  test('a skip is sent with its step; guests stay local', () async {
    st.merkHoppet(3, 'kategori');
    expect(st.hoppet, isTrue);
    expect(st.versjon, OnbStatus.kVersjon);
    // No user: nothing is sent (the fake would record it).
    final api = _FakeApi(null);
    st.api = () => api;
    st.merkSett('x');
    await Future<void>.delayed(const Duration(milliseconds: 700));
    expect(api.skrevet, isEmpty);
  });

  test('the Hjem card shows after a delivery for a finished tour, until it is closed; never with the flag off', () {
    expect(st.visHjemKort, isFalse);
    st.merkFerdig(msTotal: 1);
    expect(st.visHjemKort, isFalse); // no delivery seen yet
    st.merkLevert();
    expect(st.visHjemKort, isTrue);
    ClientFlags.flags = {OnbStatus.flagg: false};
    expect(st.visHjemKort, isFalse);
    ClientFlags.flags = {OnbStatus.flagg: true};
    st.merkHjemKort();
    expect(st.visHjemKort, isFalse);
  });
}
