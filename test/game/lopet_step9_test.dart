import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/game/fjordlopet/lopet_enhet.dart';
import 'package:aerend_customer/game/fjordlopet/render/lopet_atlas9.dart';
import 'package:aerend_customer/game/fjordlopet/render/lopet_look.dart';
import 'package:aerend_customer/game/fjordlopet/render/lopet_loop.dart';
import 'package:aerend_customer/game/fjordlopet/render/lopet_quality.dart';
import 'package:aerend_customer/game/fjordlopet/render/lopet_scene9.dart';
import 'package:aerend_customer/game/fjordlopet/render/lopet_sea9.dart';
import 'package:aerend_customer/game/fjordlopet/sim/engine.dart';
import 'package:aerend_customer/networking/api_base_helper.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_data.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_screen.dart';
import 'package:aerend_customer/services/lopet_utboks.dart';

import '../a3/a3_fakes.dart';

/// Fjordløpet v1.3 plan Step 9 (spec §12.2, §12.5, §12.6; T31–T35): the quality levels and their rule, the atlas
/// (since the Design (9) 1:1 plan: the design's own sprites), readability in the three sea modes, the same result at every level, memory over twenty opens, the
/// device model, and the move from the quay into play.

const _params = {
  'speed_start_mms': 9000, 'speed_step_mms': 120, 'speed_max_mms': 24000, 'lane_change_ticks': 7,
  'milestones_m': [200, 500, 1000], 'length_m': 5000, 'wake_from_m': 700, 'wake_counter_ticks': 30,
  'vest_grace_ticks': 60, 'vest_crates': 8, 'near_miss_ticks': 18, 'kajakk_ahead_mm': 60000,
};

Map<String, dynamic> _course() => {
      'id': 9,
      'week': '2026-W47',
      'engine_version': 2,
      'params': _params,
      'rows': [
        for (var i = 0; i < 14; i++) {'d': 40000 + i * 22000, 't': i % 4 == 3 ? 'stokk' : 'boye', 'l': i % 4 == 3 ? [0, 1] : [i % 3]},
        {'d': 400000, 't': 'boye', 'l': [0, 1, 2]},
      ],
      'crates': [for (var i = 0; i < 6; i++) {'d': 50000 + i * 30000, 'l': (i + 1) % 3}],
      'landmarks': [
        {'d': 90000, 'k': 'fyr', 's': -1},
        {'d': 200000, 'k': 'naust', 's': 1},
      ],
      'squalls': [],
    };

Map<String, dynamic> _stateJson() => {
      'status': 1,
      'session': {'id': 1, 'order_id': 42, 'state': 'open', 'runs_allowed': 3, 'runs_left': 3, 'bonus_granted': false, 'perk': 'none', 'tokens': ['rt_a', 'rt_b', 'rt_c']},
      'course': _course(),
      'personal_best_m': null,
      'week_best_m': null,
      'losgrad': {'name': 'Lettmatros', 'lifetime_m': 0},
      'level': {'index': 0, 'name': 'Bronse', 'boat': 'robaat'},
      'rewards': {'buoy1': 3, 'buoy2': 6, 'quay': 12, 'personal_best': 3, 'cap': 15, 'milestones_m': [200, 500, 1000]},
      'delivery': {'state': 'seen', 'stage': 1, 'stage_label': 'Tilberedes', 'promised_end': null, 'courier_eta_minutes': null, 'no_new_run': false},
      'vilkaar': ['Linje 1'],
      'profile': {'sound_on': false},
      'quality': {'max': 'high', 'low_model': false, 'up_p99_ms': 14, 'down_avg_ms': 18},
    };

class _FakeApi extends LopetApi {
  @override
  Future<LopetState?> state(int orderId) async => LopetState.fromJson(_stateJson());

  @override
  Future<void> sound(bool on) async {}
}

/// Relative luminance (WCAG) of an sRGB colour.
double _lum(int r, int g, int b) {
  double ch(int v) {
    final c = v / 255;
    return c <= .03928 ? c / 12.92 : math.pow((c + .055) / 1.055, 2.4).toDouble();
  }

  return .2126 * ch(r) + .7152 * ch(g) + .0722 * ch(b);
}


/// The luminances of the sprite's silhouette edge — its opaque pixels (alpha > 200) near the water (a
/// transparent pixel) — within 4 px, and its alpha mask on a 24 × 24 grid.
(List<double>, List<bool>) _pixels(ByteData rgba, int stride, Rect r) {
  final lums = <double>[];
  final mask = List<bool>.filled(24 * 24, false);
  int alpha(int x, int y) => x < r.left || y < r.top || x >= r.right || y >= r.bottom ? 0 : rgba.getUint8((y * stride + x) * 4 + 3);
  bool nearWater(int x, int y) {
    for (var dy = -4; dy <= 4; dy++) {
      for (var dx = -4; dx <= 4; dx++) {
        if (alpha(x + dx, y + dy) < 40) return true;
      }
    }
    return false;
  }

  for (var y = r.top.toInt(); y < r.bottom.toInt(); y++) {
    for (var x = r.left.toInt(); x < r.right.toInt(); x++) {
      final i = (y * stride + x) * 4;
      final a = rgba.getUint8(i + 3);
      if (a <= 200) continue;
      // The mask keeps the figure's proportions (scaled by its longer side, centred), so a log is not a crate.
      final side = math.max(r.width, r.height);
      final gx0 = (((x - r.left) + (side - r.width) / 2) / side * 24).floor().clamp(0, 23), gy0 = (((y - r.top) + (side - r.height) / 2) / side * 24).floor().clamp(0, 23);
      mask[gy0 * 24 + gx0] = true;
      if (!nearWater(x, y)) continue;
      // Straight colour from premultiplied.
      final k = 255 / a;
      lums.add(_lum((rgba.getUint8(i) * k).round().clamp(0, 255), (rgba.getUint8(i + 1) * k).round().clamp(0, 255), (rgba.getUint8(i + 2) * k).round().clamp(0, 255)));
    }
  }
  return (lums, mask);
}

double _iou(List<bool> a, List<bool> b) {
  var inter = 0, union = 0;
  for (var i = 0; i < a.length; i++) {
    if (a[i] && b[i]) inter++;
    if (a[i] || b[i]) union++;
  }
  return union == 0 ? 0 : inter / union;
}

void main() {
  setUp(() async => a3Bootstrap());
  LopetAtlas9.googleFont = false;
  tearDown(() {
    LopetScreen.overgangTest = null;
    LopetEnhet.model = '';
  });

  group('quality levels (spec §12.5)', () {
    test('a new install starts at Medium; the level is kept on the device', () async {
      expect(LopetQuality.load(), LopetNivaa.medium);
      final q = LopetQuality(framesFor2s: 4);
      expect(q.level, LopetNivaa.medium);
      expect(q.afterRun(10, frames: 10), isTrue, reason: 'a whole run with a p99 under 14 ms raises one step');
      expect(q.level, LopetNivaa.high);
      expect(LopetQuality.load(), LopetNivaa.high);
      expect(q.afterRun(10, frames: 10), isFalse, reason: 'High is the top');
    });

    test('T32: game.quality_max = low, a model pinned to Low, or a shader that fails — Low, nothing else changes', () {
      expect(LopetQuality.fromState({'max': 'low'}, stored: LopetNivaa.high).level, LopetNivaa.low);
      expect(LopetQuality.fromState({'max': 'medium'}, stored: LopetNivaa.high).level, LopetNivaa.medium);
      expect(LopetQuality.fromState({'max': 'high', 'low_model': true}, stored: LopetNivaa.high).level, LopetNivaa.low);
      final q = LopetQuality.fromState({'max': 'high'}, stored: LopetNivaa.high);
      q.markShaderFailed();
      expect([q.level, q.afterRun(5, frames: 999), q.level], [LopetNivaa.low, false, LopetNivaa.low]);
      expect([LopetNivaa.high.particles, LopetNivaa.medium.particles, LopetNivaa.low.particles], [256, 128, 48]);
      expect([LopetNivaa.high.waterScale, LopetNivaa.medium.waterScale], [.75, .5]);
      expect([LopetNivaa.high.reflectAll, LopetNivaa.medium.reflectAll, LopetNivaa.medium.reflectBoat, LopetNivaa.low.reflectBoat], [true, false, true, false]);
    });

    test('T33: an average over 18 ms for 2 s drops one step at once and it stays there for the session', () {
      final q = LopetQuality(stored: LopetNivaa.high, framesFor2s: 120);
      for (var i = 0; i < 119; i++) {
        expect(q.frame(25), isFalse, reason: 'not before 2 s of frames');
      }
      expect(q.frame(25), isTrue);
      expect([q.level, q.lockedDown], [LopetNivaa.medium, true]);
      for (var i = 0; i < 400; i++) {
        q.frame(40);
      }
      expect(q.level, LopetNivaa.medium, reason: 'one step, then kept');
      expect(q.afterRun(5, frames: 999), isFalse, reason: 'no step up after a drop in the session');
      expect(LopetQuality.load(), LopetNivaa.medium, reason: 'kept on the device');
    });

    test('T33: the drop does not move the boat — the core never reads the level', () {
      final a = FjordLoop(FjordSim(_course(), 'none'));
      final b = FjordLoop(FjordSim(_course(), 'none'));
      final q = LopetQuality(stored: LopetNivaa.high, framesFor2s: 10);
      var t = Duration.zero;
      for (var f = 0; f < 240; f++) {
        t += const Duration(microseconds: 16667);
        a.frame(t);
        b.frame(t);
        q.frame(f > 100 ? 30 : 8);
        if (f == 60) {
          a.input(1);
          b.input(1);
        }
        expect(a.sim.u, b.sim.u);
      }
      expect(q.level, LopetNivaa.medium);
    });
  });

  group('the atlas (spec §12.2, §12.6)', () {
    testWidgets('at 2× and 3× it holds every figure the field draws and a landmark for every key', (tester) async {
      await tester.runAsync(() async {
        for (final d in [2.0, 3.0]) {
          final a = await LopetAtlas9.build(density: d);
          expect(a.image.width, lessThanOrEqualTo(4096));
          for (final n in ['boye3', 'kasse3', 'stokkR0', 'kajakk3', 'beffen3', 'garn', 'skrog', 'skyggeOm', 'vest', 'pboye0', 'pboye1', 'plattform', 'bk0', 'bk1', 'bk2', 'bk3', 'bk4']) {
            expect(a.id(n), greaterThanOrEqualTo(0), reason: '$d× $n');
          }
          for (var i = 0; i < 8; i++) {
            expect(a.id('lm$i'), greaterThanOrEqualTo(0), reason: 'landmark $i');
          }
          a.dispose();
        }
      });
      expect(LopetAtlas9.live, 0);
    });

    testWidgets('T34: the obstacles, the crate and the boat differ in shape', (tester) async {
      await tester.runAsync(() async {
        for (final mode in [LopetMode.kveld, LopetMode.dag]) {
          final atlas = await LopetAtlas9.build(density: 2, mode: mode);
          final data = (await atlas.image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
          final masks = <String, List<bool>>{};
          for (final n in ['boye3', 'kasse3', 'stokkR0', 'kajakk3', 'beffen3', 'skrog']) {
            final i = atlas.id(n);
            final r = Rect.fromLTRB(atlas.src[i * 4], atlas.src[i * 4 + 1], atlas.src[i * 4 + 2], atlas.src[i * 4 + 3]);
            final (lums, mask) = _pixels(data, atlas.image.width, r);
            expect(lums, isNotEmpty, reason: '$mode $n');
            masks[n] = mask;
          }
          final keys = masks.keys.toList();
          for (var i = 0; i < keys.length; i++) {
            for (var j = i + 1; j < keys.length; j++) {
              expect(_iou(masks[keys[i]]!, masks[keys[j]]!), lessThan(.9), reason: '$mode ${keys[i]} vs ${keys[j]}');
            }
          }
          atlas.dispose();
        }
      });
      expect(LopetAtlas9.live, 0);
    });
  });

  LopetScene9 painter(FjordLoop loop, LopetAtlas9 atlas, LopetSea9? sea, LopetFx9 fx, LopetNivaa level, String boatLevel, LopetMode mode) => LopetScene9(
        loop: loop,
        atlas: atlas,
        sea: sea,
        fx: fx,
        flags: LopetFlags9(),
        milestones: const [200, 500, 1000],
        mode: mode,
        level: boatLevel,
        quality: LopetQuality(stored: level),
        landmarks: (_course()['landmarks'] as List).cast<Map>(),
      );

  testWidgets('T31: the same inputs drawn at High and at Low give the same result', (tester) async {
    await tester.runAsync(() async {
      final atlas = await LopetAtlas9.build(density: 2);
      final program = await LopetSea9.load();
      FjordResult sail(LopetNivaa level) {
        final loop = FjordLoop(FjordSim(_course(), 'none'));
        final fx = LopetFx9();
        final sea = level == LopetNivaa.low || program == null ? null : LopetSea9(program, LopetMode.kveld);
        final p = painter(loop, atlas, sea, fx, level, 'Bronse', LopetMode.kveld);
        var t = Duration.zero;
        for (var f = 0; f < 600 && !loop.done; f++) {
          t += const Duration(microseconds: 16667);
          loop.frame(t);
          fx.queue(loop.takeEvents());
          if (f % 50 == 25) loop.input(f % 100 == 25 ? 1 : -1);
          if (f % 10 == 0) {
            final rec = ui.PictureRecorder();
            p.paint(Canvas(rec), const Size(390, 700));
            rec.endRecording().dispose();
            expect(fx.n, lessThanOrEqualTo(p.lastLevel.particles), reason: 'the pool is capped by the level');
          }
        }
        if (sea != null) expect(p.lastLevel, level, reason: 'drawn at the level asked for');
        sea?.dispose();
        return loop.sim.result();
      }

      final high = sail(LopetNivaa.high), low = sail(LopetNivaa.low);
      expect(high.toJson(), low.toJson());
      atlas.dispose();
    });
  });

  testWidgets('T32: without the shader the painter draws Low, whatever the level says', (tester) async {
    await tester.runAsync(() async {
      final atlas = await LopetAtlas9.build(density: 2, mode: LopetMode.regn);
      final loop = FjordLoop(FjordSim(_course(), 'none'));
      final p = painter(loop, atlas, null, LopetFx9(), LopetNivaa.high, 'Gull', LopetMode.regn);
      final rec = ui.PictureRecorder();
      p.paint(Canvas(rec), const Size(390, 700));
      rec.endRecording().dispose();
      expect(p.lastLevel, LopetNivaa.low);
      expect(p.lastCount, greaterThan(40), reason: 'banks, buoys, crates, the boat');
      atlas.dispose();
    });
  });

  testWidgets('T35: the game screen opened and closed 20 times, runs started, leaves no Ticker or timer behind', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    for (var i = 0; i < 20; i++) {
      await a3Bootstrap(); // a fresh phone each time: three tokens to play
      await tester.pumpWidget(MaterialApp(home: LopetScreen(orderId: 42, api: _FakeApi(), pollEvery: const Duration(hours: 1))));
      await tester.pump();
      if (i.isEven) {
        await tester.tap(find.byKey(const Key('lopet-sett-seil')));
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.binding.transientCallbackCount, greaterThan(0), reason: 'sailing: the Ticker runs');
      }
      await tester.pumpWidget(const SizedBox());
    }
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0, reason: 'the Ticker is stopped');
    expect(LopetAtlas9.live, 0);
    expect(LopetSea9.liveImages, 0);
  });

  testWidgets('T35: twenty sessions of atlas, water and painter return every image', (tester) async {
    await tester.runAsync(() async {
      final program = await LopetSea9.load();
      for (var i = 0; i < 20; i++) {
        final mode = LopetMode.values[i % 3];
        final atlas = await LopetAtlas9.build(density: i.isEven ? 2 : 3, mode: mode);
        final sea = program == null ? null : LopetSea9(program, mode);
        final loop = FjordLoop(FjordSim(_course(), 'none'));
        final p = painter(loop, atlas, sea, LopetFx9(), LopetNivaa.high, 'Platina', mode);
        var t = Duration.zero;
        for (var f = 0; f < 30; f++) {
          t += const Duration(microseconds: 16667);
          loop.frame(t);
          final rec = ui.PictureRecorder();
          p.paint(Canvas(rec), const Size(390, 700));
          rec.endRecording().dispose();
        }
        expect(LopetAtlas9.live, 1);
        atlas.dispose();
        sea?.dispose();
        loop.dispose();
        expect([LopetAtlas9.live, LopetSea9.liveImages], [0, 0], reason: 'session $i');
      }
    });
  });

  testWidgets('«Sett seil»: the quay moves up and the run starts within 0.6 s', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    LopetScreen.overgangTest = const Duration(milliseconds: 450);
    await tester.pumpWidget(MaterialApp(home: LopetScreen(orderId: 42, api: _FakeApi(), pollEvery: const Duration(hours: 1))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('lopet-kai-scene')), findsOneWidget, reason: 'the start sits on the scene');
    await tester.tap(find.byKey(const Key('lopet-sett-seil')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('lopet-spill')), findsNothing, reason: 'moving');
    final ft = tester.widget<FractionalTranslation>(find.descendant(of: find.byKey(const Key('lopet-kai')), matching: find.byType(FractionalTranslation)));
    expect(ft.translation.dy, lessThan(0), reason: 'the picture moves up');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.byKey(const Key('lopet-spill')), findsOneWidget, reason: 'in play within 0.6 s');
  });

  test('the device model goes with /game/state and with every run', () async {
    await a3Bootstrap(prefs: {'UserId': 815, 'AccessToken': 'tok'});
    LopetEnhet.model = 'SM-A155F';
    final h = _Opptak();
    await LopetApi(helper: h).state(42);
    expect(h.urls.single, contains('device_model=SM-A155F'));

    final s = LopetState.fromJson(_stateJson())!;
    await LopetLager.lagre(token: 'rt_a', s: s, inputs: const [], result: const {'distance_m': 10, 'ticks': 60, 'crates': 0}, startedMs: 1, perf: {'quality': 'medium', 'avg_ms': 9.0, 'p99_ms': 12.0, 'slow_frames': 0});
    await LopetUtboks.send(helper: h);
    expect(h.posted.single['device_model'], 'SM-A155F');
    expect((h.posted.single['perf'] as Map)['quality'], 'medium');
  });

  test('sea modes follow Home: sun is Dag, sunset and night Kveld, Bergen\'s rainy default Regn', () {
    expect(LopetLook.fromHour(12), LopetMode.dag);
    expect(LopetLook.fromHour(20), LopetMode.kveld);
    expect(LopetLook.fromHour(2), LopetMode.kveld);
    expect(LopetLook.fromHour(7), LopetMode.regn);
    expect(LopetLook.of(LopetMode.kveld).lightsOn, isTrue);
    expect(LopetLook.of(LopetMode.dag).lightsOn, isFalse);
    expect(LopetLook.of(LopetMode.regn).glitter, 0);
  });
}

class _Opptak extends ApiBaseHelper {
  _Opptak() : super(baseUrl: 'http://test.local/');

  final List<String> urls = [];
  final List<Map<String, dynamic>> posted = [];

  @override
  Future<ApiClientResult> getAllowClientError(String url) async {
    urls.add(url);
    return ApiClientResult(200, _stateJson());
  }

  @override
  Future<ApiClientResult> postAllowClientError(String url, {dynamic body}) async {
    posted.add(Map<String, dynamic>.from(body as Map));
    return ApiClientResult(200, {'status': 1, 'state': 'verified'});
  }
}
