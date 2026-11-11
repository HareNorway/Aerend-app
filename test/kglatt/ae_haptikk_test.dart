import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aerend_customer/ui/kit/ae_haptic.dart';
import 'package:aerend_customer/ui/kit/kglatt.dart';
import 'package:aerend_customer/utils/shared_pref_utill.dart' show initSharedPreferences;

/// Kunde Glatt Step 2 (D3, D4, D5): one haptics service — the kinds on the
/// Android channel and as iOS HapticFeedback, the throttle, the «Vibrasjon»
/// switch, the harness switch and the log line.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> kanal, system, logg;
  late int t;
  bool kanalSvar = true;
  final orig = debugPrint;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await initSharedPreferences();
    AeHaptikk.nullstill();
    KGlatt.nullstill();
    kanal = [];
    system = [];
    logg = [];
    t = 1000;
    kanalSvar = true;
    AeHaptikk.klokke = () => t;
    debugPrint = (String? m, {int? wrapWidth}) {
      if (m != null && m.startsWith('PERF_HAPTIKK')) logg.add(m);
    };
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('aerend/haptic'), (c) async {
      kanal.add('${c.arguments}');
      return kanalSvar;
    });
    m.setMockMethodCallHandler(SystemChannels.platform, (c) async {
      if (c.method == 'HapticFeedback.vibrate') system.add('${c.arguments}'.replaceFirst('HapticFeedbackType.', ''));
      return null;
    });
  });

  tearDown(() {
    debugPrint = orig;
    debugDefaultTargetPlatformOverride = null;
    AeHaptikk.nullstill();
    KGlatt.nullstill();
  });

  Future<void> vent() => Future<void>.delayed(const Duration(milliseconds: 150));

  test('Android: each kind goes to the channel by its name', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AeHaptikk.tikk();
    t += 400;
    AeHaptikk.fast();
    t += 400;
    AeHaptikk.suksess();
    t += 400;
    AeHaptikk.feil();
    t += 400;
    AeHaptikk.tung();
    await vent();
    expect(kanal, ['tikk', 'fast', 'suksess', 'feil', 'tung']);
    expect(system, isEmpty);
    expect(logg, ['PERF_HAPTIKK kind=tikk', 'PERF_HAPTIKK kind=fast', 'PERF_HAPTIKK kind=suksess', 'PERF_HAPTIKK kind=feil', 'PERF_HAPTIKK kind=tung']);
  });

  test('Android without a vibrator (channel says false): one plain HapticFeedback call', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    kanalSvar = false;
    AeHaptikk.tikk();
    t += 400;
    AeHaptikk.feil();
    await vent();
    expect(kanal, ['tikk', 'feil']);
    expect(system, ['selectionClick', 'heavyImpact']);
  });

  test('iOS: the feedback generators (suksess = heavy + medium, feil = heavy + heavy)', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    AeHaptikk.tikk();
    t += 400;
    AeHaptikk.fast();
    t += 400;
    AeHaptikk.suksess();
    await vent();
    t += 400;
    AeHaptikk.feil();
    await vent();
    t += 400;
    AeHaptikk.tung();
    await vent();
    expect(kanal, isEmpty);
    expect(system, ['selectionClick', 'mediumImpact', 'heavyImpact', 'mediumImpact', 'heavyImpact', 'heavyImpact', 'heavyImpact']);
  });

  test('throttle: one tikk per 50 ms; a tikk within 150 ms after a stronger kind is dropped', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AeHaptikk.tikk();
    t += 20;
    AeHaptikk.tikk(); // dropped
    t += 40;
    AeHaptikk.tikk(); // 60 ms after the first: plays
    t += 10;
    AeHaptikk.fast();
    t += 100;
    AeHaptikk.tikk(); // 100 ms after fast: dropped
    t += 60;
    AeHaptikk.tikk(); // 160 ms after fast: plays
    t += 10;
    AeHaptikk.fast(); // strong kinds are never throttled
    await vent();
    expect(kanal, ['tikk', 'tikk', 'fast', 'tikk', 'fast']);
  });

  test('«Vibrasjon» off: silent, every kind (games too); default on', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(AeHaptikk.vibrasjon, isTrue);
    await AeHaptikk.settVibrasjon(false);
    expect(AeHaptikk.vibrasjon, isFalse);
    AeHaptikk.tikk();
    AeHaptikk.fast();
    AeHaptikk.suksess();
    AeHaptikk.feil();
    AeHaptikk.tung();
    aeTick();
    aeConfirm();
    aeSuccess();
    KGlatt.sett({'kglattVib': false});
    AeHaptikk.tikk();
    await vent();
    expect(kanal, isEmpty);
    expect(system, isEmpty);
    expect(logg, isEmpty);
    await AeHaptikk.settVibrasjon(true);
    KGlatt.nullstill();
    AeHaptikk.tikk();
    await vent();
    expect(kanal, ['tikk']);
  });

  test('utenTikk: the tap\'s own tick already played — inner ticks are dropped, stronger kinds play', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AeHaptikk.utenTikk(() {
      AeHaptikk.tikk();
      AeHaptikk.fast();
    });
    await vent();
    expect(kanal, ['fast']);
  });

  test('the old helpers keep their meaning: aeTick → tikk, aeConfirm → fast, aeSuccess → suksess', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    aeTick();
    t += 400;
    aeConfirm();
    t += 400;
    aeSuccess();
    await vent();
    expect(kanal, ['tikk', 'fast', 'suksess']);
  });

  test('kglattVib: false — each call plays what it played before the plan; new ones stay silent', () async {
    KGlatt.sett({'kglattVib': false});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    aeTick();
    aeConfirm();
    aeSuccess();
    AeHaptikk.tikk(); // was selectionClick
    AeHaptikk.tikk(gammel: HapticFeedback.lightImpact);
    AeHaptikk.fast(); // was mediumImpact
    AeHaptikk.suksess(); // was heavyImpact
    AeHaptikk.tikk(ny: true); // new: silent
    AeHaptikk.feil(); // new by default: silent
    await vent();
    expect(kanal, ['tick', 'confirm', 'success'], reason: 'the channel\'s old kinds, unthrottled');
    expect(system, ['selectionClick', 'lightImpact', 'mediumImpact', 'heavyImpact']);
    expect(logg.every((l) => l == 'PERF_HAPTIKK kind=gammel'), isTrue);
    expect(logg.length, 7);
  });
}
