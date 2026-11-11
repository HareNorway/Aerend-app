import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aerend_customer/screens/bergen/aegil/aegil_bits.dart' show AePress;
import 'package:aerend_customer/screens/common/auth/auth_style.dart' show AuthPressable;
import 'package:aerend_customer/screens/common/auth/launch/lf_widgets.dart' show LfPress;
import 'package:aerend_customer/screens/common/auth/onboarding_kit.dart' show OnbPressable;
import 'package:aerend_customer/ui/kit/ae_haptic.dart';
import 'package:aerend_customer/ui/kit/kglatt.dart';
import 'package:aerend_customer/utils/shared_pref_utill.dart' show initSharedPreferences;

/// Kunde Glatt Step 4 (D6, D7): the shared press widgets give one light tick
/// per taken tap — never two, none while a list scrolls, none when disabled —
/// a firm tap from the tap's own action wins, and a switch turned off is not
/// felt while one turned on is.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> kanal, system;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await initSharedPreferences();
    AeHaptikk.nullstill();
    KGlatt.nullstill();
    kanal = [];
    system = [];
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('aerend/haptic'), (c) async {
      kanal.add('${c.arguments}');
      return true;
    });
    m.setMockMethodCallHandler(SystemChannels.platform, (c) async {
      if (c.method == 'HapticFeedback.vibrate') system.add('${c.arguments}'.replaceFirst('HapticFeedbackType.', ''));
      return null;
    });
  });

  tearDown(() {
    AeHaptikk.nullstill();
    KGlatt.nullstill();
  });

  Future<void> pump(WidgetTester tester, Widget w) async {
    AeHaptikk.klokke = () => tester.binding.clock.now().millisecondsSinceEpoch;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: w))));
  }

  const box = SizedBox(width: 120, height: 60, child: Text('trykk'));

  final presses = <String, Widget Function(VoidCallback? onTap)>{
    'LfPress': (t) => LfPress(onTap: t, child: box),
    'AePress': (t) => AePress(onTap: t, child: box),
    'OnbPressable': (t) => OnbPressable(onTap: t, child: box),
    'AuthPressable': (t) => AuthPressable(onTap: t, builder: (_, __) => box),
  };

  for (final e in presses.entries) {
    testWidgets('${e.key}: one tick per taken tap, the callback\'s own tick muted', (tester) async {
      var n = 0;
      await pump(
        tester,
        e.value(() {
          n++;
          AeHaptikk.tikk(); // the old tick inside many callbacks
        }),
      );
      await tester.tap(find.text('trykk'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(n, 1);
      expect(kanal, ['tikk']);
      await tester.tap(find.text('trykk'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(kanal, ['tikk', 'tikk']);
    });

    testWidgets('${e.key}: disabled — no tick', (tester) async {
      await pump(tester, e.value(null));
      await tester.tap(find.text('trykk'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 200));
      expect(kanal, isEmpty);
    });
  }

  testWidgets('a firm tap from the tap\'s own action wins (no tick on top)', (tester) async {
    await pump(tester, const LfPress(onTap: aeConfirm, child: box));
    await tester.tap(find.text('trykk'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(kanal, ['fast']);
  });

  testWidgets('scrolling a list of press widgets: silent', (tester) async {
    AeHaptikk.klokke = () => tester.binding.clock.now().millisecondsSinceEpoch;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(children: [for (var i = 0; i < 30; i++) LfPress(onTap: () {}, child: SizedBox(height: 60, child: Text('rad $i')))]),
        ),
      ),
    );
    await tester.drag(find.text('rad 3'), const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.fling(find.text('rad 10'), const Offset(0, 300), 1500);
    await tester.pumpAndSettle();
    expect(kanal, isEmpty);
    expect(system, isEmpty);
  });

  testWidgets('a switch: turning «Vibrasjon» off is not felt, turning it on is', (tester) async {
    await pump(tester, LfPress(onTap: () => AeHaptikk.settVibrasjon(!AeHaptikk.vibrasjon), child: box));
    await tester.tap(find.text('trykk'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(AeHaptikk.vibrasjon, isFalse);
    expect(kanal, isEmpty);
    await tester.tap(find.text('trykk'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(AeHaptikk.vibrasjon, isTrue);
    expect(kanal, ['tikk']);
  });

  testWidgets('kglattVib: false — the press adds nothing; the callback\'s old call plays as before', (tester) async {
    KGlatt.sett({'kglattVib': false});
    await pump(tester, LfPress(onTap: () => AeHaptikk.tikk(), child: box));
    await tester.tap(find.text('trykk'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(kanal, isEmpty);
    expect(system, ['selectionClick'], reason: 'the old raw selectionClick, once');
  });
}
