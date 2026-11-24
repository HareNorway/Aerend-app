import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'lopet_look.dart';

/// Design (9) 1:1 plan D2: the design's water (`shaders/lopet_sjo9.frag`, a port of `FS`) and its foam map.
///
/// The water is drawn into a smaller offscreen image (the quality's share of the field: 0.75 High, 0.5 Middels and
/// Lav) and scaled up, as the design's `vannFbo`. The foam map is the design's `skumkart`: 128 × 512 px over 128 m of
/// water in world coordinates; each frame the old map fades (`max(t − 0.0055·dt, 0) · 0.985^dt`, the design's `pF`) and
/// the frame's stamps are added on top (`stp`: soft dots, rings and streaks from the atlas, red channel only).
class LopetSea9 {
  LopetSea9(ui.FragmentProgram program, this.mode, {ui.FragmentProgram? lav}) : _shader = program.fragmentShader(), _lav = lav?.fragmentShader();

  final LopetMode mode;
  final ui.FragmentShader _shader;

  /// Lav: the design's `LAV_FS` (null when it did not load: then a flat sea).
  final ui.FragmentShader? _lav;
  ui.Image? _lavTex;

  static ui.FragmentProgram? _program, _lavProgram;
  static bool _failed = false, _lavFailed = false;

  /// The Lav program (loaded once; null if it cannot load).
  static Future<ui.FragmentProgram?> loadLav() async {
    if (_lavProgram != null || _lavFailed) return _lavProgram;
    try {
      return _lavProgram = await ui.FragmentProgram.fromAsset('shaders/lopet_lav9.frag');
    } catch (_) {
      _lavFailed = true;
      return null;
    }
  }
  static int liveImages = 0;

  static Future<ui.FragmentProgram?> load() async {
    if (_program != null || _failed) return _program;
    try {
      return _program = await ui.FragmentProgram.fromAsset('shaders/lopet_sjo9.frag');
    } catch (_) {
      _failed = true;
      return null;
    }
  }

  static void resetForTest() {
    _program = null;
    _failed = false;
    _lavProgram = null;
    _lavFailed = false;
  }

  /// The design's `lavTex`: a seamless 256 × 256 water texture for the mode (three octaves of periodic value noise,
  /// the deep–shallow mix and a faint ridge of sky). Made once per session, before «Sett seil».
  Future<void> makeLavTex() async {
    if (_lavTex != null || _lav == null) return;
    const n = 256;
    int h(int x, int y, int sd) {
      var v = ((x * 374761393 + y * 668265263 + sd * 2654435761) & 0xFFFFFFFF).toSigned(32);
      v = ((v * 1274126177) & 0xFFFFFFFF).toSigned(32);
      v = (((v ^ (v.toUnsigned(32) >> 13)) * 1103515245) & 0xFFFFFFFF).toSigned(32);
      return (v ^ (v.toUnsigned(32) >> 16)).toUnsigned(32);
    }

    double hf(int x, int y, int sd) => h(x, y, sd) / 4294967296;
    double vn(double x, double y, int p, int sd) {
      final xi = x.floor(), yi = y.floor(), fx = x - xi, fy = y - yi, u = fx * fx * (3 - 2 * fx), v = fy * fy * (3 - 2 * fy);
      final x0 = ((xi % p) + p) % p, y0 = ((yi % p) + p) % p, x1 = (x0 + 1) % p, y1 = (y0 + 1) % p;
      final a = hf(x0, y0, sd), b = hf(x1, y0, sd), c = hf(x0, y1, sd), d = hf(x1, y1, sd);
      return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v;
    }

    final px = Uint8List(n * n * 4);
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        final xx = x / n, yy = y / n;
        final nz = .5 * vn(xx * 6, yy * 6, 6, 1) + .3 * vn(xx * 12, yy * 12, 12, 2) + .2 * vn(xx * 24, yy * 24, 24, 3);
        final rg = math.pow(1 - (2 * ((nz * 3.2) % 1) - 1).abs(), 6).toDouble(), t = .3 + .45 * nz, o = (y * n + x) * 4;
        for (var c = 0; c < 3; c++) {
          px[o + c] = ((shal[c] + (deep[c] - shal[c]) * t + skyLo[c] * .2 * rg) * 255).clamp(0, 255).round();
        }
        px[o + 3] = 255;
      }
    }
    final buf = await ui.ImmutableBuffer.fromUint8List(px);
    final desc = ui.ImageDescriptor.raw(buf, width: n, height: n, pixelFormat: ui.PixelFormat.rgba8888);
    final codec = await desc.instantiateCodec();
    _lavTex = (await codec.getNextFrame()).image;
    codec.dispose();
    desc.dispose();
    buf.dispose();
  }

  /// Draws Lav water over [size] (the design's `lavVann`), at half resolution. False when Lav cannot draw.
  bool paintLav(Canvas canvas, Size size, {required double t, required double m, required double by, required double vf, required double zF, required double fr, required double baat, required double dod, required double edge, required Float32List trail, required Float32List obs}) {
    final s = _lav, tex = _lavTex;
    if (s == null || tex == null) return false;
    final w = size.width, hh = size.height;
    final iw = math.max(1, (w * .5).round()), ih = math.max(1, (hh * .5).round());
    var i = 0;
    void f(double v) => s.setFloat(i++, v);
    void v3(List<double> v) {
      f(v[0]);
      f(v[1]);
      f(v[2]);
    }

    f(iw.toDouble());
    f(ih.toDouble());
    f(0);
    f(0);
    f(iw / w);
    f(t);
    f(m);
    f(by);
    f(vf);
    f(w);
    f(hh);
    f(edge);
    f(fr);
    f(baat);
    f(dod);
    f(zF % 128);
    v3(grunn);
    v3(mur);
    v3(skum);
    f(w * .24);
    f(w * .5);
    f(w * .76);
    for (var k = 0; k < 8; k++) {
      f(trail[k]);
    }
    for (var k = 0; k < 48; k++) {
      f(obs[k]);
    }
    s.setImageSampler(0, tex);
    _waterPaint.shader = s;
    final rec = ui.PictureRecorder();
    Canvas(rec).drawRect(Rect.fromLTWH(0, 0, iw.toDouble(), ih.toDouble()), _waterPaint);
    final img = rec.endRecording().toImageSync(iw, ih);
    canvas.drawImageRect(img, Rect.fromLTWH(0, 0, iw.toDouble(), ih.toDouble()), Offset.zero & size, _blit);
    img.dispose();
    return true;
  }

  // ── the design's palette (sjoPalL, sjCol) ─────────────────────────────────

  static const Map<LopetMode, Map<String, Object>> _pal = {
    LopetMode.dag: {'deep': 0xFF245866, 'shal': 0xFF6FAFBD, 'skyHi': 0xFF7FB6CE, 'skyLo': 0xFFE6F0F2, 'sun': 0xFFFFF6DC, 'L': [.42, .3, 1.0], 'pow': 380.0, 'sunA': 2.2, 'amp': .9, 'refl': 1.0, 'kau': .5},
    LopetMode.kveld: {'deep': 0xFF19434F, 'shal': 0xFF4C8796, 'skyHi': 0xFF6A8A96, 'skyLo': 0xFFC2D2D6, 'sun': 0xFFFFE2B6, 'L': [-.32, .2, 1.0], 'pow': 90.0, 'sunA': .3, 'amp': 1.0, 'refl': .96, 'kau': .34},
    LopetMode.regn: {'deep': 0xFF192E36, 'shal': 0xFF45616B, 'skyHi': 0xFF6C7F87, 'skyLo': 0xFFAEBABD, 'sun': 0xFFE8EEF0, 'L': [0.0, .5, 1.0], 'pow': 24.0, 'sunA': .1, 'amp': .8, 'refl': .88, 'kau': .22},
  };

  static List<double> _rgb(int c) => [((c >> 16) & 255) / 255, ((c >> 8) & 255) / 255, (c & 255) / 255];
  static List<double> _mix(List<double> a, List<double> b, double t) => [for (var i = 0; i < 3; i++) a[i] + (b[i] - a[i]) * t];

  late final Map<String, Object> _p = _pal[mode]!;
  late final List<double> deep = _rgb(_p['deep'] as int), shal = _rgb(_p['shal'] as int), skyHi = _rgb(_p['skyHi'] as int), skyLo = _rgb(_p['skyLo'] as int), sun = _rgb(_p['sun'] as int);
  late final List<double> grunn = _mix(shal, const [.46, .74, .64], mode == LopetMode.dag ? .42 : .3);
  late final List<double> mur = mode == LopetMode.dag ? const [.25, .27, .26] : const [.12, .14, .15];
  late final List<double> skum = _mix(skyLo, const [1, 1, 1], .62);
  late final List<double> lDir = () {
    final l = _p['L'] as List<double>;
    final n = math.sqrt(l[0] * l[0] + l[1] * l[1] + l[2] * l[2]);
    return [l[0] / n, l[1] / n, l[2] / n];
  }();

  /// The design's `_wv`: per wave its direction's y and its frequency, so the scroll phase (`dy · fr · z`) is computed
  /// in double precision here and the shader never sees a large z.
  static final Float64List _wv = () {
    final l = Float64List(36);
    var dx = .6442, dy = .7648, fr = .34;
    for (var i = 0; i < 18; i++) {
      l[i * 2] = dy;
      l[i * 2 + 1] = fr;
      fr *= 1.2;
      final nx = dx * -.7374 - dy * .6755;
      dy = dx * .6755 + dy * -.7374;
      dx = nx;
    }
    return l;
  }();

  // ── the foam map ──────────────────────────────────────────────────────────

  static const int fw = 128, fh = 512;
  ui.Image? _foam;
  final Paint _fadePaint = Paint();
  final Paint _stampPaint = Paint()..blendMode = BlendMode.plus;
  final Paint _blit = Paint()..filterQuality = FilterQuality.low;

  // The frame's stamps: x, y (map px), sx, sy, alpha, sprite (atlas index); drawn with the atlas.
  static const int stampCap = 320;
  final Float32List _st = Float32List(stampCap * 6);
  int _nSt = 0;

  /// A stamp in map px (the painter converts world → map as the design's `stp`).
  void stamp(int sprite, double x, double y, double sx, double sy, double a) {
    if (_nSt >= stampCap || sprite < 0 || a <= 0) return;
    final o = _nSt * 6;
    _st[o] = x;
    _st[o + 1] = y;
    _st[o + 2] = sx;
    _st[o + 3] = sy;
    _st[o + 4] = a;
    _st[o + 5] = sprite.toDouble();
    _nSt++;
  }

  /// Fades the map and adds this frame's stamps. [atlas] is the sprite image, [src]/[geo] its tables, [density] its
  /// px per design px.
  void updateFoam(double dtf, {required ui.Image atlas, required Float32List src, required Float32List geo, required double density, required bool on}) {
    if (!on) {
      _nSt = 0;
      return;
    }
    final rec = ui.PictureRecorder();
    final c = Canvas(rec, Rect.fromLTWH(0, 0, fw.toDouble(), fh.toDouble()));
    final old = _foam;
    if (old != null) {
      final k = .0055 * dtf, f = math.pow(.985, dtf).toDouble();
      _fadePaint.colorFilter = ColorFilter.matrix(<double>[f, 0, 0, 0, -k * f * 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255]);
      c.drawImage(old, Offset.zero, _fadePaint);
    } else {
      c.drawColor(const Color(0xFF000000), BlendMode.src);
    }
    if (_nSt > 0) {
      final pos = Float32List(_nSt * 12), uv = Float32List(_nSt * 12);
      final col = Int32List(_nSt * 6);
      for (var i = 0; i < _nSt; i++) {
        final o = i * 6, id = _st[o + 5].toInt(), g = id * 4;
        final sx = _st[o + 2], sy = _st[o + 3];
        final x0 = _st[o] - geo[g + 2] * sx, y0 = _st[o + 1] - geo[g + 3] * sy, x1 = x0 + geo[g] * sx, y1 = y0 + geo[g + 1] * sy;
        final p = i * 12;
        pos.setAll(p, [x0, y0, x1, y0, x1, y1, x0, y0, x1, y1, x0, y1]);
        final u0 = src[g], v0 = src[g + 1], u1 = src[g + 2], v1 = src[g + 3];
        uv.setAll(p, [u0, v0, u1, v0, u1, v1, u0, v0, u1, v1, u0, v1]);
        final a = (_st[o + 4].clamp(0.0, 1.0) * 255).round();
        final cc = (a << 24) | 0x00FF0000;
        for (var j = 0; j < 6; j++) {
          col[i * 6 + j] = cc;
        }
      }
      _stampPaint.shader = ImageShader(atlas, TileMode.clamp, TileMode.clamp, Matrix4Identity.m, filterQuality: FilterQuality.medium);
      c.drawVertices(ui.Vertices.raw(ui.VertexMode.triangles, pos, textureCoordinates: uv, colors: col), BlendMode.modulate, _stampPaint);
    }
    _nSt = 0;
    final img = rec.endRecording().toImageSync(fw, fh);
    if (old != null) {
      old.dispose();
      liveImages--;
    }
    _foam = img;
    liveImages++;
  }

  // ── the water ─────────────────────────────────────────────────────────────

  final Paint _waterPaint = Paint();
  ui.Image? _blank;

  /// Draws the water over [size]. [vs] is the quality's share (0.75 / 0.5). The arrays are the design's uniforms.
  void paint(
    Canvas canvas,
    Size size, {
    required double vs,
    required double t,
    required double m,
    required double by,
    required double vf,
    required double zF,
    required double fr,
    required double baat,
    required double dod,
    required bool rolig,
    required bool clouds,
    required double regn,
    required double edge,
    required List<double> kjol, // r, g, b, on
    required Float32List trail, // 8
    required Float32List obs, // 48
    required Float32List rip, // 32
    double sx = 0,
    double sy = 0,
  }) {
    final w = size.width, h = size.height;
    final iw = math.max(1, (w * vs).round()), ih = math.max(1, (h * vs).round());
    final s = _shader;
    var i = 0;
    void f(double v) => s.setFloat(i++, v);
    void v3(List<double> v) {
      f(v[0]);
      f(v[1]);
      f(v[2]);
    }

    f(iw.toDouble());
    f(ih.toDouble());
    f(sx);
    f(sy);
    f(iw / w);
    f(t);
    f(m);
    f(by);
    f(vf);
    f(w);
    f(h);
    f(edge);
    f(regn);
    f(fr);
    f(baat);
    f(dod);
    f(kjol[3]);
    f(_p['kau'] as double);
    f(rolig ? (_p['amp'] as double) * .5 : _p['amp'] as double);
    f(_p['refl'] as double);
    f(_p['pow'] as double);
    f(_p['sunA'] as double);
    f(w * .26);
    f(clouds && mode == LopetMode.dag ? 1 : 0);
    v3(kjol);
    v3(deep);
    v3(shal);
    v3(skyHi);
    v3(skyLo);
    v3(sun);
    v3(lDir);
    v3(grunn);
    v3(mur);
    v3(skum);
    f(w * .24);
    f(w * .5);
    f(w * .76);
    f(zF % 76.8);
    f(zF % 112);
    f(zF % 128);
    f(zF % 1000);
    f(zF % 12);
    f(0);
    for (var k = 0; k < 8; k++) {
      f(trail[k]);
    }
    for (var k = 0; k < 18; k++) {
      f((_wv[k * 2] * _wv[k * 2 + 1] * zF) % (2 * math.pi));
    }
    f(0);
    f(0);
    for (var k = 0; k < 48; k++) {
      f(obs[k]);
    }
    for (var k = 0; k < 32; k++) {
      f(rip[k]);
    }
    final foam = _foam ?? (_blank ??= _blankImage());
    s.setImageSampler(0, foam);
    _waterPaint.shader = s;
    final rec = ui.PictureRecorder();
    Canvas(rec).drawRect(Rect.fromLTWH(0, 0, iw.toDouble(), ih.toDouble()), _waterPaint);
    final img = rec.endRecording().toImageSync(iw, ih);
    canvas.drawImageRect(img, Rect.fromLTWH(0, 0, iw.toDouble(), ih.toDouble()), Offset.zero & size, _blit);
    img.dispose();
  }

  static ui.Image _blankImage() {
    final rec = ui.PictureRecorder();
    Canvas(rec).drawColor(const Color(0xFF000000), BlendMode.src);
    return rec.endRecording().toImageSync(4, 4);
  }

  void dispose() {
    final f = _foam;
    if (f != null) {
      f.dispose();
      liveImages--;
      _foam = null;
    }
    _blank?.dispose();
    _blank = null;
    _lavTex?.dispose();
    _lavTex = null;
  }
}

/// The identity matrix for an ImageShader (no allocation per frame).
class Matrix4Identity {
  static final Float64List m = Float64List.fromList([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
}
