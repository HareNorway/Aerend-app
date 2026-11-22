import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/game/fjordlopet/haptics/game_haptics.dart';
import 'package:aerend_customer/game/fjordlopet/haptics/haptikk_moenster.dart';

/// Fjordløpet haptics plan Steps 2–3 (spec §7.1, §11.3): the `aerend/game_haptics` contract seen from Dart — the tier
/// the native side reports, the table it is sent, and a missing native side.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const ch = MethodChannel('aerend/game_haptics');
  final log = <MethodCall>[];

  void native(Map<String, Object?> caps) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(ch, (c) async {
      log.add(c);
      return c.method == 'capabilities' ? caps : null;
    });
  }

  tearDown(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(ch, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('rich: the table goes over once with the scale; play sends the key only', () async {
    native({'tier': 'rich', 'why': null, 'sdk': 34});
    final h = GameHaptics(ios: false);
    await h.prepare();
    expect(h.tier, HaptikkTier.rich);
    final prep = log.firstWhere((c) => c.method == 'prepare');
    final args = prep.arguments as Map;
    expect(args['scale'], 1.0);
    final table = args['table'] as Map;
    expect((table['android'] as Map).keys, containsAll(['h01', 'h02.1', 'h02.5', 'h09.0', 'h09.5', 'h13', 'u11']));
    expect(table['primitives'], kAndroidPrimitiver);
    expect((table['standardAndroid'] as Map)['h10'], 'DOUBLE_CLICK');
    h.play(HaptikkId.h05);
    await Future<void>.delayed(Duration.zero);
    expect(log.last.method, 'play');
    expect(log.last.arguments, {'key': 'h05'});
    await h.dispose();
    expect(log.last.method, 'release');
  });

  test('standard on Android: the table is sent (the predefined effects are built natively)', () async {
    native({'tier': 'standard'});
    final h = GameHaptics(ios: false);
    await h.prepare();
    expect(h.tier, HaptikkTier.standard);
    expect(log.where((c) => c.method == 'prepare'), hasLength(1));
  });

  test('off with the phone\'s touch feedback off: why system_off, nothing sent (DH3, TH7)', () async {
    native({'tier': 'off', 'why': 'system_off'});
    final h = GameHaptics(ios: false);
    await h.prepare();
    expect(h.tier, HaptikkTier.off);
    expect(h.tierWhy, 'system_off');
    expect(h.virkelig, HaptikkNivaaValg.off);
    h.play(HaptikkId.h13);
    await Future<void>.delayed(Duration.zero);
    expect(log.map((c) => c.method), ['capabilities']);
  });

  test('no native side: Off on Android, Standard on the iPhone (DH7: a failure costs richness, not a crash)', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect((await const MethodHaptikkKanal().capabilities()).tier, HaptikkTier.off);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect((await const MethodHaptikkKanal().capabilities()).tier, HaptikkTier.standard);
  });

  test('a channel error on play is swallowed', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(ch, (c) async {
      if (c.method == 'capabilities') return {'tier': 'rich'};
      throw PlatformException(code: 'x');
    });
    final h = GameHaptics(ios: false);
    await h.prepare();
    h.play(HaptikkId.h13);
    await Future<void>.delayed(Duration.zero);
  });
}
