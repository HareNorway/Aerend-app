// Fjordløpet v1.3 plan Step 6 (spec v1.3 §12.1 «heard», plan D9): renders the game's sounds to WAV files, once.
//
//   dart run tool/fjordlopet_sounds.dart [out_dir]      (default assets/game/sounds)
//
// The sounds are the ones the design prototype synthesises in `lyd(n)` (designs/25des/Fjordlopet.dc.html): oscillator
// tones with the same frequencies, ramps and envelopes, and band-passed noise from the same LCG, so the app sounds like
// the design without any recorded audio. 22 050 Hz, 16-bit mono. The crate note rises one step of the major scale per
// crate in a row, so it is 15 files (kasse_0 … kasse_14).
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int rate = 22050;

class _Mix {
  _Mix(double seconds) : buf = Float64List((seconds * rate).ceil());

  final Float64List buf;

  /// An oscillator from [f0] to [f1] (exponential) starting at [t0] for [dur] s; gain 0.0001 → [vol] in 12 ms, then
  /// exponentially to 0.0008 at the end (the Web Audio envelope).
  void tone(double f0, double f1, double t0, double dur, String type, double vol) {
    var phase = 0.0;
    final start = (t0 * rate).round(), n = ((dur + .03) * rate).round();
    for (var i = 0; i < n && start + i < buf.length; i++) {
      final t = i / rate;
      final f = f0 == f1 ? f0 : f0 * math.pow(f1 / f0, math.min(1, t / dur));
      phase += f / rate;
      final p = phase - phase.floorToDouble();
      final v = switch (type) {
        'sine' => math.sin(2 * math.pi * p),
        'triangle' => 1 - 4 * (p - .5).abs(),
        'sawtooth' => 2 * p - 1,
        _ => math.sin(2 * math.pi * p),
      };
      buf[start + i] += v * _env(t, dur, vol);
    }
  }

  /// Band-passed noise (Q 1.2) whose centre goes from [f0] to [f1] over [dur] s; gain [vol] → 0.0008.
  void sus(double f0, double f1, double dur, double vol) {
    final noise = Float64List((rate * .4).round());
    var s = 1234567;
    for (var i = 0; i < noise.length; i++) {
      s = (s * 1103515245 + 12345).toSigned(32);
      noise[i] = ((s & 0xFFFFFFFF) >> 8) / 8388608 - 1;
    }
    var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0;
    final n = ((dur + .02) * rate).round();
    for (var i = 0; i < n && i < buf.length; i++) {
      final t = i / rate;
      final f = f0 * math.pow(f1 / f0, math.min(1, t / dur));
      final w0 = 2 * math.pi * f / rate, alpha = math.sin(w0) / (2 * 1.2);
      final b0 = alpha, b2 = -alpha, a0 = 1 + alpha, a1 = -2 * math.cos(w0), a2 = 1 - alpha;
      final x = noise[i % noise.length];
      final y = (b0 * x + b2 * x2 - a1 * y1 - a2 * y2) / a0;
      x2 = x1;
      x1 = x;
      y2 = y1;
      y1 = y;
      final g = vol * math.pow(.0008 / vol, math.min(1, t / dur));
      buf[i] += y * g;
    }
  }

  static double _env(double t, double dur, double vol) {
    if (t < .012) return .0001 + (vol - .0001) * t / .012;
    if (t >= dur) return .0008;
    return vol * math.pow(.0008 / vol, (t - .012) / (dur - .012));
  }

  Uint8List wav() {
    final data = ByteData(44 + buf.length * 2);
    void str(int o, String s) {
      for (var i = 0; i < s.length; i++) {
        data.setUint8(o + i, s.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    data.setUint32(4, 36 + buf.length * 2, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, rate, Endian.little);
    data.setUint32(28, rate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    str(36, 'data');
    data.setUint32(40, buf.length * 2, Endian.little);
    for (var i = 0; i < buf.length; i++) {
      data.setInt16(44 + i * 2, (buf[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }
}

void main(List<String> args) {
  final out = Directory(args.isEmpty ? 'assets/game/sounds' : args.first)..createSync(recursive: true);
  final sounds = <String, _Mix Function()>{
    'bytte': () => _Mix(.2)..sus(700, 2600, .16, .16),
    'naer': () => _Mix(.15)..tone(880, 1320, 0, .1, 'sine', .1),
    'full': () => _Mix(.35)
      ..tone(659.25, 659.25, 0, .1, 'triangle', .14)
      ..tone(987.77, 987.77, .09, .2, 'triangle', .14),
    'vest': () => _Mix(.28)
      ..sus(1800, 300, .22, .22)
      ..tone(330, 110, 0, .22, 'sine', .16),
    'port': () => _Mix(.6)
      ..tone(196, 196, 0, .55, 'sawtooth', .06)
      ..tone(146.83, 146.83, 0, .55, 'sawtooth', .06)
      ..tone(293.66, 293.66, .02, .5, 'triangle', .09),
    'rekord': () {
      final m = _Mix(.8);
      const f = [523.25, 659.25, 783.99, 1046.5];
      for (var i = 0; i < 4; i++) {
        m.tone(f[i], f[i], i * .1, i == 3 ? .42 : .12, 'triangle', .15);
      }
      return m;
    },
    'treff': () => _Mix(.36)
      ..tone(130, 42, 0, .3, 'sine', .3)
      ..sus(400, 90, .2, .2),
    'blip': () => _Mix(.15)..tone(783.99, 783.99, 0, .1, 'triangle', .12),
  };
  const steps = [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23, 24];
  for (var k = 0; k < steps.length; k++) {
    final f = 523.25 * math.pow(2, steps[k] / 12);
    sounds['kasse_$k'] = () => _Mix(.18)..tone(f, f, 0, .13, 'triangle', .16);
  }
  var total = 0;
  for (final e in sounds.entries) {
    final bytes = e.value().wav();
    File('${out.path}/${e.key}.wav').writeAsBytesSync(bytes);
    total += bytes.length;
  }
  stdout.writeln('Wrote ${sounds.length} sounds to ${out.path} (${(total / 1024).round()} kB).');
}
