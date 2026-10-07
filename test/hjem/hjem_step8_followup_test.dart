import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/common/home/bergen/bergen_rails.dart';
import 'package:aerend_customer/screens/common/home/home_dl.dart';

import '../layout/reduced_motion_harness.dart';

/// Backend plan Step 8 follow-up — Hjem never shows the design's sample
/// cards (a tap on one could only say «Kommer snart»), and the live-ærend
/// pill does not outlive its user or its order.
void main() {
  setUpAll(() => bootstrapGlobals(locale: 'no'));

  Widget host(Widget child) => MaterialApp(
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true, size: const Size(390, 844), textScaler: const TextScaler.linear(.5)),
      child: app!,
    ),
    home: Scaffold(body: child),
  );

  testWidgets('no stores: «Butikker på …» says so instead of sample shops', (tester) async {
    await tester.pumpWidget(host(BergenStoreRail(stores: const [], onOpen: (_) {})));
    await tester.pump();

    expect(find.text('Ingen butikker her ennå'), findsOneWidget);
    expect(find.text('Torgboden'), findsNothing);
    expect(find.text('Casa Maria'), findsNothing);
  });

  testWidgets('no products: «Populært i kveld» says so instead of sample cards', (tester) async {
    await tester.pumpWidget(host(BergenProductRail(products: const [], onOpen: (_) {}, onAdd: (_) {})));
    await tester.pump();

    expect(find.text('Ingen varer her ennå'), findsOneWidget);
    expect(find.text('Pad thai med kylling'), findsNothing);
  });

  test('Hjem has no sample store or product cards left', () {
    final src = File('lib/screens/common/home/bergen/bergen_home.dart').readAsStringSync();

    expect(src.contains('_placeholderStores'), isFalse);
    // (The hero's floats keep their own samples until Ægil's
    // recommendations; those are not rail cards.)
    for (final sample in ['Whopper meny', 'Reker 1 kg', 'Fersk fisk fra Fisketorget', 'Steinovn på Bryggen']) {
      expect(src.contains(sample), isFalse, reason: sample);
    }
    // Without the swipe feed the rail asks for the category's popular list.
    expect(src.contains('_ensurePopulaert(cat)'), isTrue);
  });

  test('«no order under way» (code 59) parses as order 0, which hides the pill', () {
    final r = HomeTrackOrderPojo.fromJson({'status': 0, 'message': 'Ingen ordre', 'message_code': 59});

    expect(r.status, 0);
    expect(r.messageCode, 59);
    expect(r.orderId, 0);
    final bloc = File('lib/screens/common/home/home_bloc.dart').readAsStringSync();
    expect(bloc.contains('response.messageCode == 59'), isTrue, reason: 'the bloc passes code 59 on as an answer');
  });

  test('logout drops the live-ærend pill', () {
    final src = File('lib/utils/utils.dart').readAsStringSync();
    final logout = src.substring(src.indexOf('logout(BuildContext context) async'));

    expect(logout.substring(0, logout.indexOf('getApiMsg')).contains('hjemLiveOrdre.value = null'), isTrue);
  });
}
