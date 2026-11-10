import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/kit/br_pal.dart';
import 'package:aerend_customer/screens/bergen/sporing/sporing_gl.dart';
import 'package:aerend_customer/screens/common/home/bergen/bergen_kit.dart' show BergenWeather;

/// Heat plan Step 5: the Bryggen split (`hjem_bryggen_stat.frag` baked through
/// [SpGlBake], then `hjem_bryggen_liv.frag`) draws the same pixels as the
/// original `hjem_bryggen.frag`, for every weather, both forms and several
/// scene times.
///
/// The shaders run on the tester's CPU (Skia SkSL). SkSL has no array
/// initialisers, so the test compiles copies of the three production shaders
/// itself (impellerc, next to flutter_tester), with each `const vecN X[n] =
/// …` turned into a function — the same constants, nothing else changed; no
/// test shader goes into the app's pubspec.
///
/// Default: the four weathers on Hjem at its device pixel grid (780 × 254)
/// and Fjordfiske (643 × 467) in rain, two times each. `BRYGGEN_DELING_FULL=1`
/// runs every weather × form × four times. `BRYGGEN_DELING_PNG=<dir>` writes
/// both frames and a diff mask per case.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('cache keys and invalidation (pure Dart)', () {
    tearDown(SpGlBake.tomCache);

    test('every bake input is in the key', () {
      final base = [390.0, 127, 2, 0, 0, .74, 0, 0, 1, 0, 1, 1, 196, 1100].map((e) => e.toDouble()).toList();
      final k = SpGlBake.nokkelFor('s', 780, 254, base);
      expect(SpGlBake.nokkelFor('s', 780, 254, [...base]), k);
      expect(SpGlBake.nokkelFor('s', 429, 140, base), isNot(k), reason: 'lite tier / other size');
      expect(SpGlBake.nokkelFor('s2', 780, 254, base), isNot(k), reason: 'other bake shader');
      for (var i = 0; i < base.length; i++) {
        final b = [...base]..[i] += 1e-6;
        expect(SpGlBake.nokkelFor('s', 780, 254, b), isNot(k), reason: 'uniform $i');
      }
    });

    test('LRU cache owns clones; holders keep theirs', () {
      ui.Image px() {
        final r = ui.PictureRecorder();
        Canvas(r).drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint());
        return r.endRecording().toImageSync(1, 1);
      }

      SpGlBake fertig(String key) {
        final b = SpGlBake(key, 2, 1, 1);
        b.bilder.addAll([px(), px()]);
        expect(b.ferdig, isTrue);
        return b;
      }

      expect(SpGlBake.hent('a'), isNull);
      final a = fertig('a');
      SpGlBake.legg(a);
      final a2 = SpGlBake.hent('a')!;
      expect(a2.ferdig, isTrue);
      expect(a2.bilder.first.isCloneOf(a.bilder.first), isTrue);
      expect(identical(a2.bilder.first, a.bilder.first), isFalse);
      SpGlBake.legg(fertig('b'));
      SpGlBake.hent('a'); // a most recently used
      SpGlBake.legg(fertig('c')); // evicts b
      expect(SpGlBake.cacheNokler, ['a', 'c']);
      SpGlBake.legg(fertig('d')); // evicts a
      expect(SpGlBake.cacheNokler, ['c', 'd']);
      // The holders' own clones survive the eviction.
      expect(a.bilder.first.debugDisposed, isFalse);
      expect(a2.bilder.first.debugDisposed, isFalse);
      a.dispose();
      a2.dispose();
    });
  });

  group('pixels: split == original', () {
    final imp = File('${File(Platform.resolvedExecutable).parent.path}/impellerc');
    final full = Platform.environment['BRYGGEN_DELING_FULL'] == '1';
    final png = Platform.environment['BRYGGEN_DELING_PNG'];
    late ui.FragmentProgram ref, stat, liv;

    setUpAll(() async {
      if (!imp.existsSync()) return;
      const dir = 'build/unit_test_assets/bryggen_deling_test';
      Directory(dir).createSync(recursive: true);
      Future<ui.FragmentProgram> compile(String name) async {
        final src = _utenArrays(File('shaders/$name.frag').readAsStringSync());
        File('$dir/$name.frag.src').writeAsStringSync(src);
        final out = '$dir/$name.frag';
        final r = await Process.run(imp.path, [
          '--sksl',
          '--runtime-stage-vulkan',
          '--iplr',
          '--sl=$out',
          '--spirv=$out.spirv',
          '--input=$dir/$name.frag.src',
          '--input-type=frag',
          '--include=shaders',
          '--include=${imp.parent.path}/shader_lib',
        ]);
        if (r.exitCode != 0) throw StateError('impellerc $name: ${r.stderr}');
        return ui.FragmentProgram.fromAsset('bryggen_deling_test/$name.frag');
      }

      ref = await compile('hjem_bryggen');
      stat = await compile('hjem_bryggen_stat');
      liv = await compile('hjem_bryggen_liv');
    });

    final saker = <(BergenWeather, bool)>[
      for (final k in BergenWeather.values) (k, true),
      for (final k in BergenWeather.values)
        if (full || k == BergenWeather.regn) (k, false),
    ];
    final tider = full ? [12.0, 47.31, 230.9, 3411.77] : [12.0, 230.9];

    for (final (kind, hjem) in saker) {
      test('${kind.name} ${hjem ? 'hjem' : 'fiske'}', () async {
        if (!imp.existsSync()) {
          markTestSkipped('impellerc not found next to flutter_tester');
          return;
        }
        final p = BrPal.of(kind);
        // HjemBryggen / SpGl exactly: 390 × h, pixel ratio min(2, √(300 000 / px)).
        const w = 390.0;
        final h = hjem ? 127.0 : 283.0;
        final dpr = math.max(.5, math.min(2.0, math.sqrt(300000 / (w * h))));
        final pw = (w * dpr).round(), ph = (h * dpr).round();
        List<double> floats(double t) => [w, h, pw / w, t % 3600, 127 - h, p.night, p.sun, p.sunset, p.rain, p.snow, p.wet, hjem ? p.veil : 0, p.cb, p.vis, ...p.skT, ...p.skM, ...p.skB];
        final samplere = p.sun > 0 ? const [0, 1, 2, 3, 4, 5, 6, 7, 8] : const [0, 1, 2, 3, 4, 1, 2, 3, 4];

        // The bake, through the production code (stripes and all).
        final bake = SpGlBake('test', samplere.reduce(math.max) + 1, pw, ph);
        final st = stat.fragmentShader();
        final bf = floats(0);
        while (!bake.steg(st, bf)) {}
        final info = await _slotInfo(bake, pw, ph);
        // ignore: avoid_print
        print('${kind.name} ${hjem ? 'hjem' : 'fiske'} ${pw}x$ph: $info');
        expect(info.klemt, 0, reason: 'a colour outside the 24-bit range [0, 4)');

        for (final t in tider) {
          final a = await _draw(ref.fragmentShader(), floats(t), const [], pw, ph);
          final ls = liv.fragmentShader();
          final b = await _draw(ls, floats(t), [for (final k in samplere) bake.bilder[k]], pw, ph);
          var n = 0, maks = 0;
          final mask = Uint8List(pw * ph);
          for (var o = 0; o < a.length; o += 4) {
            for (var c = 0; c < 3; c++) {
              final d = (a[o + c] - b[o + c]).abs();
              if (d > 0) {
                n++;
                mask[o >> 2] = 1;
                maks = math.max(maks, d);
              }
            }
          }
          final px = mask.where((x) => x == 1).length;
          // ignore: avoid_print
          print('  t $t: $px px / ${pw * ph} differ ($n channels), max $maks/255');
          if (png != null) await _png(png, '${kind.name}_${hjem ? 'hjem' : 'fiske'}_$t', a, b, mask, pw, ph);
          expect(maks, lessThanOrEqualTo(1), reason: 'never more than 1/255');
          expect(px, lessThanOrEqualTo(pw * ph ~/ 2000), reason: 'rounding-level differences only');
        }
        bake.dispose();
      }, timeout: const Timeout(Duration(minutes: 30)));
    }
  });
}

/// `const vecN X[n] = vecN[n](a, …);` → `vecN X_(int i)`, `X[e]` → `X_(e)`.
String _utenArrays(String src) {
  final re = RegExp(r'const (vec\d|float) (\w+)\[(\d+)\] = \1\[\3\]\((.*)\);');
  final names = <String>[];
  src = src.replaceAllMapped(re, (m) {
    final ty = m[1]!, name = m[2]!, n = int.parse(m[3]!);
    final args = <String>[];
    var depth = 0, cur = StringBuffer();
    for (final ch in m[4]!.split('')) {
      if (ch == '(') depth++;
      if (ch == ')') depth--;
      if (ch == ',' && depth == 0) {
        args.add(cur.toString().trim());
        cur = StringBuffer();
      } else {
        cur.write(ch);
      }
    }
    args.add(cur.toString().trim());
    expect(args.length, n);
    names.add(name);
    return [
      '$ty ${name}_(int i){',
      for (var k = 0; k < n - 1; k++) '  if (i == $k) return ${args[k]};',
      '  return ${args.last};',
      '}',
    ].join('\n');
  });
  for (final name in names) {
    src = src.replaceAllMapped(RegExp('\\b$name\\[([^\\]]+)\\]'), (m) => '${name}_(${m[1]})');
  }
  return src;
}

Future<Uint8List> _draw(ui.FragmentShader sh, List<double> floats, List<ui.Image> samplers, int pw, int ph) async {
  for (var i = 0; i < floats.length; i++) {
    sh.setFloat(i, floats[i]);
  }
  for (var k = 0; k < samplers.length; k++) {
    sh.setImageSampler(k, samplers[k]);
  }
  final rec = ui.PictureRecorder();
  Canvas(rec).drawRect(Rect.fromLTWH(0, 0, pw.toDouble(), ph.toDouble()), Paint()..shader = sh);
  final img = rec.endRecording().toImageSync(pw, ph);
  final bd = await img.toByteData();
  img.dispose();
  sh.dispose();
  return bd!.buffer.asUint8List();
}

/// What the bake holds: how many pixels show the deep part (G), draw the
/// front live (E), are sky; the largest colour; any clamped channel.
Future<({int g, int e, int himmel, double maks, int klemt})> _slotInfo(SpGlBake b, int pw, int ph) async {
  final s = [for (final im in b.bilder) (await im.toByteData())!.buffer.asUint8List()];
  int v(Uint8List d, int o) => d[o] << 16 | d[o + 1] << 8 | d[o + 2];
  var g = 0, e = 0, himmel = 0, klemt = 0;
  var maks = 0.0;
  for (var o = 0; o < pw * ph * 4; o += 4) {
    final t0 = v(s[0], o);
    if (t0 & 1 == 1) e++;
    final gg = t0 >> 1 & 1 == 1;
    if (gg) g++;
    if (v(s[1], o) == 0xFFFFFF) {
      if (gg) himmel++;
      continue;
    }
    for (var k = 1; k < s.length; k++) {
      if (k % 4 == 0) continue; // the low bytes
      final c = v(s[k], o);
      if (c == 0xFFFFFE) klemt++;
      maks = math.max(maks, c / 4194304);
    }
  }
  return (g: g, e: e, himmel: himmel, maks: maks, klemt: klemt);
}

Future<void> _png(String dir, String name, Uint8List a, Uint8List b, Uint8List mask, int pw, int ph) async {
  Directory(dir).createSync(recursive: true);
  Future<void> save(String n, Uint8List px) async {
    final buf = await ui.ImmutableBuffer.fromUint8List(px);
    final desc = ui.ImageDescriptor.raw(buf, width: pw, height: ph, pixelFormat: ui.PixelFormat.rgba8888);
    final codec = await desc.instantiateCodec();
    final img = (await codec.getNextFrame()).image;
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$n.png').writeAsBytesSync(bd!.buffer.asUint8List());
  }

  await save('${name}_orig', a);
  await save('${name}_delt', b);
  final m = Uint8List(pw * ph * 4);
  for (var i = 0; i < pw * ph; i++) {
    final x = mask[i] == 1 ? 255 : 0;
    m[i * 4] = x;
    m[i * 4 + 1] = x ~/ 4;
    m[i * 4 + 2] = 0;
    m[i * 4 + 3] = 255;
  }
  await save('${name}_diff', m);
}
