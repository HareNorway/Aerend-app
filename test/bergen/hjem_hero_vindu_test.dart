import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/hjem/hjem_hero.dart';
import 'package:aerend_customer/screens/common/auth/launch/lf_css.dart' show LfFrame;

import '../a3/a3_fakes.dart';

/// Design 21 Nov plan Step 10 (found on the emulator): Fjordløpet's quay shows Home's scene as a window (`vindu`)
/// while Hjem's own scene is still mounted under the route. The light-mode show's global anchors may sit in one of
/// them only — the same GlobalKey twice broke the quay's scene with a framework assertion.
void main() {
  setUp(() async => a3Bootstrap());

  Widget hero({bool vindu = false}) => SizedBox(
    width: 390,
    height: 300,
    child: LfFrame(
      child: HjemHero(
        vaer: HjemVaer.sol,
        floats: const [],
        onFloatAdd: (_) {},
        onFloatSink: (_) {},
        onFloatNever: (_) {},
        onPose: () {},
        onFjordfiske: () {},
        nappAvailable: false,
        vindu: vindu,
      ),
    ),
  );

  testWidgets('Hjem\'s scene and the quay\'s window copy can be mounted at the same time', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      builder: (context, app) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: app!),
      home: Scaffold(body: SingleChildScrollView(child: Column(children: [hero(), hero(vindu: true)]))),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(HjemHero), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
