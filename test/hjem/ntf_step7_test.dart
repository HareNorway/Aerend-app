import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/networking/ops/cus_api.dart';
import 'package:aerend_customer/screens/bergen/hjem/hjem_varsler.dart';
import 'package:aerend_customer/screens/bergen/kit/live_aerend.dart';
import 'package:aerend_customer/screens/bergen/meg/varsler_innst.dart';
import 'package:aerend_customer/services/ntf/ntf_hooks.dart';
import 'package:aerend_customer/services/ntf/ntf_push.dart';

import '../layout/reduced_motion_harness.dart';

/// Notifications plan Step 7 — the customer app: a channel per class (full screen only for CRITICAL), routing by the
/// server's `route` first, the badge / toast / opened hooks, the Varsler card (AI label, «Færre slike», «Slå av
/// denne typen», the button and inline actions report «acted»), the settings screen from the server, and the
/// marketing question once.
class _FakeCus extends CusApi {
  final List<(int, String)> utfall = [];
  final List<String> tokens = [];

  @override
  Future<bool> varselUtfall(int notificationId, String utfall, {String? skjerm}) async {
    this.utfall.add((notificationId, utfall));
    return true;
  }

  @override
  Future<bool> pushToken(String token, {String? platform}) async {
    tokens.add(token);
    return true;
  }
}

void main() {
  setUpAll(() => bootstrapGlobals(locale: 'no'));

  final naa = DateTime(2026, 11, 12, 12, 0);

  Widget host(Widget child) => MaterialApp(
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true, size: const Size(390, 844), textScaler: const TextScaler.linear(.5)),
      child: app!,
    ),
    home: Scaffold(body: child),
  );

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  group('channels and routing', () {
    test('a channel per class; only CRITICAL may take the screen', () {
      expect(NtfChannels.forClass('critical').id, 'ntf_critical');
      expect(NtfChannels.forClass('operational').id, 'ntf_operational');
      expect(NtfChannels.forClass('insight').id, 'ntf_insight');
      expect(NtfChannels.forClass(null).id, 'ntf_operational', reason: 'an old push without a class: the manifest default');
      expect([NtfChannels.fullScreen('critical'), NtfChannels.fullScreen('operational'), NtfChannels.fullScreen('insight')], [true, false, false]);
      expect(NtfChannels.insight.playSound, isFalse, reason: 'INSIGHT comes silently');
      expect(NtfChannels.priority('insight'), Priority.low);
      expect(NtfChannels.importance('critical'), Importance.max);
    });

    test('the server\'s route first, then the type, else the old fallbacks', () {
      expect(NtfRouting.route({'route': '/bergen/sporing/12', 'type': 'customer.order.ready', 'order_id': '9'}), '/bergen/sporing/12');
      expect(NtfRouting.route({'type': 'customer.order.ready', 'order_id': '9'}), '/bergen/sporing/9');
      expect(NtfRouting.route({'type': 'customer.courier_message', 'order_id': '4'}), '/bergen/sporing/4');
      expect(NtfRouting.route({'type': 'customer.campaign', 'deep_link': 'aerend://store/12'}), isNull, reason: 'PushDeepLink takes it');
      expect(NtfRouting.route({'route': 'https://evil.example', 'notification_type': '1'}), isNull);
    });

    test('the payload kinds', () {
      expect(NtfPayload.isBadge({'kind': 'ntf.badge', 'unread': '3'}), isTrue);
      expect(NtfPayload.unread({'kind': 'ntf.badge', 'unread': '3'}), 3);
      expect(NtfPayload.isToast({'toast': '1'}), isTrue);
      expect(NtfPayload.notificationId({'notification_id': '55'}), 55);
      expect(NtfPayload.cls({'class': ''}), isNull);
    });
  });

  group('hooks', () {
    late _FakeCus api;
    setUp(() {
      api = _FakeCus();
      NtfHooks.api = () => api;
      NtfHooks.toasts.clear();
    });
    tearDown(HjemVarsler.reset);

    test('a badge push refreshes the bell and shows nothing', () async {
      HjemVarsler.kilde = HjemVarslerKilde(
        pushes: () async => const [],
        aegil: () async => const [],
        unseen: () async => (antall: 0, sett: null),
        markerSett: () async {},
        ordre: (_) async => null,
        antall: () async => 4,
      );
      expect(await NtfHooks.handleData({'kind': 'ntf.badge', 'unread': '4'}), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(HjemVarsler.uleste.value, 4);
      expect(await NtfHooks.handleData({'kind': 'order', 'title': 'x'}), isFalse, reason: 'an ordinary push is shown as before');
    });

    test('a toast push is recorded; a tap reports «opened»; the token is reported', () async {
      NtfHooks.toast({'title': 'Svar fra Torgboden', 'message': 'Den er klar'});
      expect(NtfHooks.toasts, ['Svar fra Torgboden · Den er klar']);
      expect(NtfHooks.reportOpened({'notification_id': '91'}), isTrue);
      expect(NtfHooks.reportOpened({'title': 'no id'}), isFalse);
      NtfHooks.reportToken('fcm-token-abcdefghijklmnopqrstuvwxyz');
      await Future<void>.delayed(Duration.zero);
      expect(api.utfall, [(91, 'opened')]);
      expect(api.tokens, ['fcm-token-abcdefghijklmnopqrstuvwxyz']);
    });
  });

  group('Varsler', () {
    final utfall = <(int, String)>[];
    final typerAv = <String>[];

    CusVarsel v(String key, String type, String title, {bool ai = false, bool less = false, String? ntfType, String? action, List<CusVarselHandling> actions = const []}) => CusVarsel(
      key: key,
      type: type,
      muteKey: type,
      kind: '',
      sender: 'Ægil',
      title: title,
      body: '',
      at: naa.subtract(const Duration(minutes: 5)),
      read: true,
      aiLabel: ai,
      lessOk: less,
      ntfType: ntfType,
      action: action,
      actions: actions,
    );

    setUp(() {
      utfall.clear();
      typerAv.clear();
      hjemLiveOrdre.value = null;
      HjemVarsler.kilde = HjemVarslerKilde(
        pushes: () async => const [],
        aegil: () async => const [],
        unseen: () async => (antall: 0, sett: null),
        markerSett: () async {},
        ordre: (_) async => null,
        inbox: () async => CusInbox(items: [
          v('n:31', 'tilbud', 'Skrei hos Torgboden', ai: true, less: true, ntfType: 'customer.aegil.suggestion'),
          v('n:32', 'aerend', 'Driftsmelding', action: 'Les'),
          v('n:33', 'valg', 'Torgboden svarer ikke', actions: const [CusVarselHandling(label: 'Vent', route: '/bergen/sporing/5')]),
        ], unread: 0, mutes: const []),
        utfall: (id, u) async {
          utfall.add((id, u));
          return true;
        },
        typeAv: (t) async {
          typerAv.add(t);
          return true;
        },
      );
    });
    tearDown(HjemVarsler.reset);

    testWidgets('the AI label; «Færre slike» and «Slå av denne typen» on INSIGHT; the button reports «acted»', (tester) async {
      phone(tester);
      await tester.pumpWidget(host(VarslerPanel(naa: naa)));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('varsel-ai')), findsOneWidget, reason: 'only the agent-written card');
      await tester.longPress(find.text('Skrei hos Torgboden'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('varsel-faerre')));
      await tester.pumpAndSettle();
      expect(utfall, [(31, 'less')]);

      await tester.longPress(find.text('Skrei hos Torgboden'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('varsel-type-av')));
      await tester.pumpAndSettle();
      expect(typerAv, ['customer.aegil.suggestion']);

      await tester.longPress(find.text('Driftsmelding'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('varsel-faerre')), findsNothing, reason: 'not offered on a type one cannot turn down');

      await tester.tap(find.byKey(const Key('varsel-inline-Vent')));
      await tester.pump();
      expect(utfall.last, (33, 'acted'));
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('settings and consent', () {
    CusVarselPrefs fixture({bool? marketing}) => CusVarselPrefs(types: const [
      CusVarselType(type: 'customer.order.at_door', cls: 'critical', label: 'Budet er fremme', alwaysOn: true, push: true, inApp: true, sound: true),
      CusVarselType(type: 'customer.order.ready', cls: 'operational', label: 'Klar', alwaysOn: true, push: true, inApp: true, sound: true),
      CusVarselType(type: 'customer.aegil.suggestion', cls: 'insight', label: 'Forslag fra Ægil', alwaysOn: false, push: true, inApp: true, sound: true),
    ], marketing: marketing);

    testWidgets('the screen renders from the server; CRITICAL is «Alltid på» with a sound switch; push off calls the server', (tester) async {
      phone(tester);
      final lagret = <(String, bool?, bool?)>[];
      VarslerInnstScreen.kilde = VarslerInnstKilde(
        hent: () async => fixture(),
        lagre: (t, {push, lyd}) async {
          lagret.add((t, push, lyd));
          return fixture();
        },
        samtykke: (_) async => true,
      );
      await tester.pumpWidget(host(const VarslerInnstScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('alltid-customer.order.at_door')), findsOneWidget);
      expect(find.byKey(const Key('lyd-customer.order.at_door')), findsOneWidget);
      expect(find.byKey(const Key('push-customer.order.at_door')), findsNothing, reason: 'CRITICAL cannot be turned off');
      await tester.tap(find.byKey(const Key('push-customer.aegil.suggestion')));
      await tester.pumpAndSettle();
      expect(lagret, [('customer.aegil.suggestion', false, null)]);
      await tester.tap(find.byKey(const Key('lyd-customer.order.at_door')));
      await tester.pumpAndSettle();
      expect(lagret.last, ('customer.order.at_door', null, false));
      VarslerInnstScreen.kilde = VarslerInnstKilde.standard();
    });

    testWidgets('the marketing question is asked once, only when never answered', (tester) async {
      phone(tester);
      var spurt = false;
      final svar = <bool>[];
      NtfSamtykke.spurt = () => spurt;
      NtfSamtykke.markerSpurt = () => spurt = true;
      NtfSamtykke.kilde = () => VarslerInnstKilde(hent: () async => fixture(), lagre: (t, {push, lyd}) async => null, samtykke: (ja) async {
        svar.add(ja);
        return true;
      });
      late BuildContext ctx;
      await tester.pumpWidget(host(Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));
      final vist = NtfSamtykke.kanskje(ctx);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ntf-samtykke')), findsOneWidget);
      await tester.tap(find.byKey(const Key('ntf-samtykke-ja')));
      await tester.pumpAndSettle();
      expect(await vist, isTrue);
      expect(svar, [true]);
      expect(await NtfSamtykke.kanskje(ctx), isFalse, reason: 'once');

      spurt = false;
      NtfSamtykke.kilde = () => VarslerInnstKilde(hent: () async => fixture(marketing: false), lagre: (t, {push, lyd}) async => null, samtykke: (_) async => true);
      expect(await NtfSamtykke.kanskje(ctx), isFalse, reason: 'already answered on the server');
    });
  });
}
