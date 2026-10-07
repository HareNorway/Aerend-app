import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aerend_customer/l10n/app_localizations.dart';
import 'package:aerend_customer/main.dart' as app;
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/hjelp/support.dart';
import 'package:aerend_customer/screens/bergen/sporing/hjelp_sheet.dart';
import 'package:aerend_customer/screens/bergen/sporing/sporing_copy.dart';
import 'package:aerend_customer/utils/shared_pref_utill.dart';

/// Backend plan Step 5 — the support chat on the server: the order the
/// customer came from goes along, the hub reads `support/config`, and a
/// conversation the server closed takes no more input.
class _Api extends OpsCustomerApi {
  final List<Map<String, dynamic>> opened = [];
  String state = 'assistant';

  @override
  Future<List<Map<String, dynamic>>> orders({int limit = 50}) async => const [];

  @override
  Future<List<Map<String, dynamic>>> pointsLedger() async => const [];

  @override
  Future<Map<String, dynamic>> tracking(int orderId) async => throw StateError('offline');

  Map<String, dynamic> _conversation(List<Map<String, dynamic>> messages) => {
    'conversation': {'id': 7, 'topic': 'support', 'state': state, 'order_id': opened.lastOrNull?['order_id'], 'messages': messages},
  };

  @override
  Future<Map<String, dynamic>?> supportOpen({required String topic, int? orderId, String? guestToken}) async {
    opened.add({'topic': topic, 'order_id': orderId});
    return _conversation([
      {'id': 1, 'author': 'assistant', 'body': 'Hei Kari. Hva kan jeg hjelpe med?', 'at': DateTime.now().toIso8601String()},
    ]);
  }

  @override
  Future<Map<String, dynamic>?> supportPoll(int id, int after, {String? guestToken}) async {
    if (state != 'closed') return {'conversation': {'id': id, 'state': state}, 'messages': const []};
    return {
      'conversation': {'id': id, 'state': 'closed'},
      'messages': [
        if (after < 2) {'id': 2, 'author': 'system', 'body': 'Samtalen er avsluttet', 'at': DateTime.now().toIso8601String()},
      ],
    };
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

  test('the hub lines read support/config: hours, answer time, who is on call', () {
    SupportConfig.settFra({'hours': {'opens': 0, 'closes': 24}, 'answer_minutes': 12, 'on_call': <String>[]});
    expect(SporingCopy.a1_sporing_aapent_til, 'Åpent til 24:00 · svarer innen 12 min');
    expect(SporingCopy.a1_sporing_raskest, 'Raskest');
    SupportConfig.settFra({'hours': {'opens': 8, 'closes': 23}, 'answer_minutes': 30, 'on_call': ['Kari', 'Ola', 'Sindre']});
    expect(SporingCopy.a1_sporing_raskest, 'Raskest · Kari, Ola og Sindre er på vakt');
    SupportConfig.settFra({'hours': {'opens': 8, 'closes': 23}, 'answer_minutes': 30, 'on_call': <String>[]});
  });

  testWidgets('chat from Sporing\'s Kundeservice sends that order along; a closed conversation offers a new one', (tester) async {
    phone(tester);
    final api = _Api();
    SupportStore.instance.reset(api: api);
    await tester.pumpWidget(MaterialApp(home: HjelpScreen(api: api, orderId: 65, initial: HjelpState.kundeservice)));
    await settle(tester);

    await tester.tap(find.byKey(const Key('a1_sporing_ks_chat')));
    await settle(tester);
    expect(api.opened.single, {'topic': 'support', 'order_id': 65});
    expect(find.byKey(const Key('a1_hjelp_chat_felt')), findsOneWidget);
    expect(find.text(SupportCopy.aiUnder), findsOneWidget);
    expect(find.textContaining('· AI'), findsNothing);

    // Staff close it in the panel; the next poll brings it.
    api.state = 'closed';
    await tester.pump(const Duration(seconds: 6));
    await settle(tester);
    expect(find.text(SupportCopy.avsluttetUnder), findsWidgets);
    expect(find.byKey(const Key('a1_hjelp_chat_felt')), findsNothing);
    expect(find.byKey(const Key('a1_hjelp_chat_menneske')), findsNothing);
    await tester.tap(find.byKey(const Key('a1_hjelp_chat_ny')));
    await settle(tester);
    expect(find.byKey(const Key('a1_hjelp_chat')), findsNothing);

    SupportStore.instance.stoppPolling();
  });
}
