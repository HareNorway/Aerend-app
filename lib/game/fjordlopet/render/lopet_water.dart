import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'lopet_look.dart';
import 'lopet_quality.dart';

/// Fjordløpet v1.3 plan Step 9 (spec §12.2 layers 1–2, §12.5): the water at High and Medium.
///
/// - **Water:** `shaders/lopet_sjo.frag` over the field, drawn into a smaller offscreen image (0.75 of the field at
///   High, 0.5 at Medium) and scaled up.
/// - **Foam map:** an offscreen image the same size that scrolls with the water and fades a little each frame. The
///   painter stamps wakes, bow waves, rings and splashes into it ([stamp]), and the shader samples it.
///
/// The program is loaded once ([load]) when the session opens, before «Sett seil»; a program that fails to load
/// returns null and the game draws at Low (T32). The shader, the Paints and the stamp pool are made once. The two
/// offscreen images are the only things made per frame (they are what §12.2 asks for), and each frame's images are
/// disposed as soon as the next frame has replaced them (T35: [liveImages] is back to zero after [dispose]).
class LopetWater {
  LopetWater(ui.FragmentProgram program, this.look) : _shader = program.fragmentShader();

  final LopetLook look;
  final ui.FragmentShader _shader;

  static ui.FragmentProgram? _program;
  static bool _failed = false;

  /// Offscreen images alive now, across all instances.
  static int liveImages = 0;

  /// Loads the program once; null when it cannot be loaded on this device (the game then runs at Low).
  static Future<ui.FragmentProgram?> load() async {
    if (_program != null || _failed) return _program;
    try {
      return _program = await ui.FragmentProgram.fromAsset('shaders/lopet_sjo.frag');
    } catch (_) {
      _failed = true;
      return null;
    }
  }

  /// Tests: forget a cached program or failure.
  static void resetForTest() {
    _program = null;
    _failed = false;
  }

  final Paint _waterPaint = Paint();
  final Paint _blit = Paint()..filterQuality = FilterQuality.low;
  final Paint _fade = Paint()..color = const Color(0xF0FFFFFF);
  final Paint _foamInk = Paint()..color = const Color(0xFFFFFFFF);
  final Paint _foamRing = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xFFFFFFFF);

  /// White at 0/16 … 16/16 alpha, made once (no Color per stamp).
  static final List<Color> _alpha = List<Color>.generate(17, (i) => Color.fromRGBO(255, 255, 255, i / 16));

  ui.Image? _foam;
  ui.Image? _blank;
  double _foamScroll = 0;
  int _w = 0, _h = 0;
  bool _disposed = false;

  // The stamp pool: x, y, radius (field px), strength; kind 0 = dot, 1 = ring.
  static const int stampCap = 64;
  final Float32List _stamps = Float32List(stampCap * 4);
  final Uint8List _kind = Uint8List(stampCap);
  int _nStamps = 0;

  /// Stamps foam into the map at (x, y) in field px, for this frame.
  void stamp(double x, double y, double r, double strength, {bool ring = false}) {
    if (_nStamps >= stampCap) return;
    final i = _nStamps * 4;
    _stamps[i] = x;
    _stamps[i + 1] = y;
    _stamps[i + 2] = r;
    _stamps[i + 3] = strength;
    _kind[_nStamps] = ring ? 1 : 0;
    _nStamps++;
  }

  /// Draws the water over [size] at [level]. [scrollPx] is the distance flowed past in field px; [tSec] the water clock.
  void paint(Canvas canvas, Size size, {required double scrollPx, required double tSec, required LopetNivaa level, required double laneW, required double bankW}) {
    if (_disposed) return;
    final s = level.waterScale;
    final w = (size.width * s).ceil(), h = (size.height * s).ceil();
    if (w <= 0 || h <= 0) return;
    if (w != _w || h != _h) {
      _w = w;
      _h = h;
      _swapFoam(null);
      _foamScroll = scrollPx;
    }

    // The foam map: last frame's moved down by the distance flowed, faded, with this frame's stamps.
    if (level.foamMap) {
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      final prev = _foam;
      if (prev != null) c.drawImage(prev, Offset(0, (scrollPx - _foamScroll) * s), _fade);
      for (var k = 0; k < _nStamps; k++) {
        final i = k * 4;
        final x = _stamps[i] * s, y = _stamps[i + 1] * s, r = _stamps[i + 2] * s, a = _stamps[i + 3];
        if (_kind[k] == 1) {
          _foamRing
            ..strokeWidth = r * .25
            ..color = _alpha[(a.clamp(0, 1) * 16).round()];
          c.drawCircle(Offset(x, y), r, _foamRing);
        } else {
          _foamInk.color = _alpha[(a.clamp(0, 1) * 16).round()];
          c.drawCircle(Offset(x, y), r, _foamInk);
        }
      }
      final pic = rec.endRecording();
      _swapFoam(pic.toImageSync(w, h));
      pic.dispose();
    }
    _foamScroll = scrollPx;
    _nStamps = 0;

    // The water, small, then scaled up.
    final period = 512.0 * s;
    final sh = _shader
      ..setFloat(0, w.toDouble())
      ..setFloat(1, h.toDouble())
      ..setFloat(2, (scrollPx * s) % period)
      ..setFloat(3, tSec % 600)
      ..setFloat(4, period)
      ..setFloat(5, bankW * s)
      ..setFloat(6, laneW * s)
      ..setFloat(7, level == LopetNivaa.high ? 1 : .67)
      ..setFloat(8, look.glitter)
      ..setFloat(9, look.regn ? 1 : 0)
      ..setFloat(10, level.foamMap && _foam != null ? 1 : 0);
    _colour(sh, 11, look.deep);
    _colour(sh, 14, look.shal);
    _colour(sh, 17, look.skyHi);
    _colour(sh, 20, look.sun);
    _colour(sh, 23, look.mist);
    sh.setFloat(26, look.mistA);
    sh.setImageSampler(0, _foam ?? (_blank ??= _makeBlank()));
    _waterPaint.shader = sh;
    final rec = ui.PictureRecorder();
    Canvas(rec).drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), _waterPaint);
    final pic = rec.endRecording();
    final img = pic.toImageSync(w, h);
    pic.dispose();
    liveImages++;
    canvas.drawImageRect(img, Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), Offset.zero & size, _blit);
    img.dispose(); // the canvas keeps what it drew
    liveImages--;
  }

  static void _colour(ui.FragmentShader sh, int at, Color c) {
    sh
      ..setFloat(at, c.r)
      ..setFloat(at + 1, c.g)
      ..setFloat(at + 2, c.b);
  }

  void _swapFoam(ui.Image? next) {
    final prev = _foam;
    if (prev != null) {
      prev.dispose();
      liveImages--;
    }
    _foam = next;
    if (next != null) liveImages++;
  }

  ui.Image _makeBlank() {
    final rec = ui.PictureRecorder();
    Canvas(rec);
    final pic = rec.endRecording();
    final img = pic.toImageSync(1, 1);
    pic.dispose();
    liveImages++;
    return img;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _swapFoam(null);
    final b = _blank;
    if (b != null) {
      b.dispose();
      liveImages--;
      _blank = null;
    }
    _shader.dispose();
  }
}
