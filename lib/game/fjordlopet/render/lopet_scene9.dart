import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../sim/engine.dart';
import 'lopet_atlas9.dart';
import 'lopet_look.dart';
import 'lopet_loop.dart';
import 'lopet_quality.dart';
import 'lopet_sea9.dart';

/// The flags on the water (distances in mm, −1 = none), set when a run starts.
class LopetFlags9 {
  double bestMm = -1;
  double weekMm = -1;
  double rivalMm = -1;
}

/// Design (9) 1:1 plan Steps 2–3: the play field's state that outlives a painter (the screen owns it): particles
/// (the design's fixed pool of 256, kinds 0 drop · 1 spark · 2 confetti · 3 plank), the boat's track for the wake,
/// ripples, the rowing phase, the zoom, flashes, and the events the screen hands over.
class LopetFx9 {
  static const int cap = 256;
  final Float32List x = Float32List(cap), y = Float32List(cap), vx = Float32List(cap), vy = Float32List(cap), g = Float32List(cap);
  final Float32List life = Float32List(cap), maxLife = Float32List(cap), size = Float32List(cap), rot = Float32List(cap), vr = Float32List(cap), sc = Float32List(cap);
  final Uint8List kind = Uint8List(cap), colour = Uint8List(cap);
  int n = 0;
  int maxN = cap;

  /// FjordSim event bits not yet drawn.
  int queued = 0;
  void queue(int ev) => queued |= ev;

  // The boat's track: 8 x positions, one per 2.2 m (the design's `_spor`).
  final Float32List trail = Float32List(8);
  double trailD0 = double.nan;

  // Ripples in world metres: x, z, start (s), strength; 8 at a time (the design's `_ripA`).
  final Float64List rip = Float64List(32);
  int ripI = 0;
  double buoyRipT = 0;

  double zoom = 0;
  double rowPhase = 0;
  double rowT = 0;
  bool oarIn = false;
  double nearMissT = 0;
  double glimtT = 0;
  double vestT = 0; // ms timestamp of the life ring's pop; −1 = already on
  double landTick = -1e9;
  double landSign = 0;
  int lastLaneTo = 1;
  int gatesPassed = 0;
  final List<bool> gateSmelt = [false, false, false];
  bool recordSaid = false;
  double lastTick = -1;
  final Map<int, bool> gullSplashed = {};

  // The life ring that spreads when the vest takes a hit (`_ring`).
  double ringX = 0, ringY = 0, ringR = 0, ringA = 0;

  /// The run ended: 0 → 1 over 0.54 s after the hit (`_dod`).
  double dod = 0;
  double dodStartMs = 0;

  final math.Random _r = math.Random();
  double rnd() => _r.nextDouble();

  void add(int k, double px, double py, double pvx, double pvy, double pg, double l, double m, double s, int c, double r, double pvr, double psc) {
    final i = n;
    if (i >= maxN) return;
    n = i + 1;
    kind[i] = k;
    x[i] = px;
    y[i] = py;
    vx[i] = pvx;
    vy[i] = pvy;
    g[i] = pg;
    life[i] = l;
    maxLife[i] = m;
    size[i] = s;
    colour[i] = c;
    rot[i] = r;
    vr[i] = pvr;
    sc[i] = psc;
  }

  void _move(int a, int b) {
    kind[b] = kind[a];
    x[b] = x[a];
    y[b] = y[a];
    vx[b] = vx[a];
    vy[b] = vy[a];
    g[b] = g[a];
    life[b] = life[a];
    maxLife[b] = maxLife[a];
    size[b] = size[a];
    colour[b] = colour[a];
    rot[b] = rot[a];
    vr[b] = vr[a];
    sc[b] = sc[a];
  }

  /// The design's `fxSteg` (dt in 60 Hz frames, scroll in px per frame).
  void step(double dt, double scroll) {
    final s = scroll * dt;
    if (ringA > 0) {
      ringR += 4.5 * dt;
      ringA -= .03 * dt;
      ringY += s;
    }
    var m = n;
    for (var i = m - 1; i >= 0; i--) {
      life[i] -= dt;
      if (life[i] <= 0) {
        m--;
        if (i != m) _move(m, i);
        continue;
      }
      vy[i] += g[i] * dt;
      x[i] += vx[i] * dt;
      y[i] += vy[i] * dt + s * sc[i];
      rot[i] += vr[i] * dt;
    }
    n = m;
  }

  void sprut(double px, double py, double side, int k) {
    for (var i = 0; i < k; i++) {
      add(0, px + side * 9, py + rnd() * 22 - 6, side * (1 + rnd() * 2.6), -1.2 - rnd() * 1.6, .16, 16 + rnd() * 12, 28, 1.3 + rnd() * 1.8, 0, 0, 0, .6);
    }
  }

  void plask(double px, double py, int k, bool planks) {
    for (var i = 0; i < k; i++) {
      final a = rnd() * 6.283, v = 1.5 + rnd() * 4.5;
      add(0, px, py, math.cos(a) * v, math.sin(a) * v - 1.5, .14, 22 + rnd() * 20, 42, 1.6 + rnd() * 2.6, 0, 0, 0, .4);
    }
    if (planks) {
      for (var i = 0; i < 7; i++) {
        final a = rnd() * 6.283, v = 1 + rnd() * 3;
        add(3, px, py, math.cos(a) * v, math.sin(a) * v - 2, .1, 50 + rnd() * 20, 70, 8, i.isOdd ? 4 : 5, a, (rnd() - .5) * .4, .8);
      }
    }
  }

  void gnist(double px, double py, int k, List<int> cs) {
    for (var i = 0; i < k; i++) {
      final a = rnd() * 6.283, v = 1 + rnd() * 3.4;
      add(1, px, py, math.cos(a) * v, math.sin(a) * v - .6, .03, 20 + rnd() * 16, 36, 2 + rnd() * 2.5, cs[i % cs.length], 0, 0, .3);
    }
  }

  void clear() {
    n = 0;
    queued = 0;
    trailD0 = double.nan;
    rip.fillRange(0, 32, 0);
    zoom = 0;
    gatesPassed = 0;
    gateSmelt.fillRange(0, 3, false);
    recordSaid = false;
    ringA = 0;
    dod = 0;
    vestT = 0;
    gullSplashed.clear();
    lastTick = -1;
  }
}

/// Design (9) 1:1 plan Steps 2–3: the play field, a port of the design's `tegnGL` with `tingGL`, `portGL`, `baatGL`,
/// `skyggeGL`, `maakeGL`, `refl`, `lysStr`, `strek` and `fxGL`. The water is [LopetSea9]; everything else is sprites from
/// [LopetAtlas9], batched as the design's vertex buffer (a quad with UVs and a colour per sprite, the colour multiplied
/// in; a negative alpha adds light) and drawn with `drawVertices` in runs of the same blend.
///
/// Units are the design's: x and y in logical px, distances in mm, the zoom m in px per metre (16.5 at the start, 12.5
/// at full speed), sprite scale k = m / 17. The course is the app's (rows, crates, kayaks, landmarks — plan D3).
class LopetScene9 extends CustomPainter {
  LopetScene9({
    required this.loop,
    required this.atlas,
    required this.sea,
    required this.fx,
    required this.flags,
    required this.milestones,
    required this.mode,
    this.level = 'Bronse',
    this.vimpel = '',
    this.figur = '',
    this.kjol = '',
    this.rolig = false,
    this.quality,
    this.ghostLabelTicks = 170,
    List<Map> landmarks = const [],
  }) : super(repaint: loop) {
    for (final l in landmarks) {
      final id = _lmIds[l['k']];
      if (id == null) continue;
      _lm.add((((l['d'] as num?) ?? 0).toDouble(), id, ((l['s'] as num?)?.toInt() ?? -1) < 0 ? 0 : 1));
    }
  }

  final FjordLoop loop;
  final LopetAtlas9 atlas;
  final LopetSea9? sea;
  final LopetFx9 fx;
  final LopetFlags9 flags;
  final List<int> milestones;
  final LopetMode mode;
  final String level, vimpel, figur, kjol;
  final bool rolig;
  final LopetQuality? quality;
  final int ghostLabelTicks;

  static const Map<String, int> _lmIds = {'naust': 0, 'kran': 1, 'fyr': 2, 'akvariet': 3, 'festningen': 4, 'seilskute': 5, 'verftet': 6, 'sjobad': 7};
  final List<(double, int, int)> _lm = [];

  static const double m0 = 17, kant = 30;
  static const List<int> bkLys = [68, 20, 104, 76, 0];
  static const List<double> mint3 = [.361, .878, .722], gull3 = [.949, .757, .306], hvit3 = [1, 1, 1];
  static const List<int> fxc = [0xFFFFFF, 0x7FF0CB, 0xF2C14E, 0x5CE0B8, 0x9A6A3C, 0xC99862, 0xF5F3EF, 0xFFE3A3];
  static const List<int> gnKasse = [1, 2, 0], gnVest = [1, 0], ksGull = [2, 3, 0], ksMint = [3, 2, 0];

  // ── the sprite batch (the design's `spr`/`sprV`) ─────────────────────────

  static const int cap = 2400;
  static final Float32List _pos = Float32List(cap * 12), _uv = Float32List(cap * 12);
  static final Int32List _col = Int32List(cap * 6);
  static final Uint8List _add = Uint8List(cap);
  int _n = 0;
  final Paint _norm = Paint()..filterQuality = FilterQuality.medium;
  final Paint _plus = Paint()
    ..filterQuality = FilterQuality.medium
    ..blendMode = BlendMode.plus;

  late final Map<String, int> _id = atlas.ids;
  int _a(String n) => _id[n] ?? -1;

  void spr(int id, double x, double y, double sx, double sy, double rot, double r, double g, double b, double a) {
    final n = _n;
    if (n >= cap || id < 0) return;
    _n = n + 1;
    final G = atlas.geo, S = atlas.src, o = id * 4;
    final x0 = -G[o + 2] * sx, y0 = -G[o + 3] * sy, x1 = x0 + G[o] * sx, y1 = y0 + G[o + 1] * sy;
    double ax, ay, bx, by, cx, cy, dx, dy;
    if (rot != 0) {
      final c = math.cos(rot), s = math.sin(rot);
      ax = x + x0 * c - y0 * s;
      ay = y + x0 * s + y0 * c;
      bx = x + x1 * c - y0 * s;
      by = y + x1 * s + y0 * c;
      cx = x + x1 * c - y1 * s;
      cy = y + x1 * s + y1 * c;
      dx = x + x0 * c - y1 * s;
      dy = y + x0 * s + y1 * c;
    } else {
      ax = x + x0;
      ay = y + y0;
      bx = x + x1;
      by = y + y0;
      cx = x + x1;
      cy = y + y1;
      dx = x + x0;
      dy = y + y1;
    }
    _quad(n, ax, ay, bx, by, cx, cy, dx, dy, S[o], S[o + 1], S[o + 2], S[o + 3], r, g, b, a);
  }

  void _quad(int n, double ax, double ay, double bx, double by, double cx, double cy, double dx, double dy, double u0, double v0, double u1, double v1, double r, double g, double b, double a) {
    final p = n * 12;
    _pos[p] = ax;
    _pos[p + 1] = ay;
    _pos[p + 2] = bx;
    _pos[p + 3] = by;
    _pos[p + 4] = cx;
    _pos[p + 5] = cy;
    _pos[p + 6] = ax;
    _pos[p + 7] = ay;
    _pos[p + 8] = cx;
    _pos[p + 9] = cy;
    _pos[p + 10] = dx;
    _pos[p + 11] = dy;
    _uv[p] = u0;
    _uv[p + 1] = v0;
    _uv[p + 2] = u1;
    _uv[p + 3] = v0;
    _uv[p + 4] = u1;
    _uv[p + 5] = v1;
    _uv[p + 6] = u0;
    _uv[p + 7] = v0;
    _uv[p + 8] = u1;
    _uv[p + 9] = v1;
    _uv[p + 10] = u0;
    _uv[p + 11] = v1;
    // a < 0: light that adds (the design's premultiplied alpha 0).
    final add = a < 0;
    final m = add ? -a : a;
    final c = ((m.clamp(0.0, 1.0) * 255).round() << 24) | ((r.clamp(0.0, 1.0) * 255).round() << 16) | ((g.clamp(0.0, 1.0) * 255).round() << 8) | (b.clamp(0.0, 1.0) * 255).round();
    final q = n * 6;
    for (var j = 0; j < 6; j++) {
      _col[q + j] = c;
    }
    _add[n] = add ? 1 : 0;
  }

  /// A vertical slice v0–v1 of a sprite (reflections).
  void sprV(int id, double x, double y, double sx, double sy, double v0, double v1, double r, double g, double b, double a) {
    final n = _n;
    if (n >= cap || id < 0) return;
    _n = n + 1;
    final G = atlas.geo, S = atlas.src, o = id * 4, eh = G[o + 1];
    final x0 = x - G[o + 2] * sx, x1 = x0 + G[o] * sx, ya = y + (v0 * eh - G[o + 3]) * sy, yb = y + (v1 * eh - G[o + 3]) * sy;
    final t0 = S[o + 1] + (S[o + 3] - S[o + 1]) * v0, t1 = S[o + 1] + (S[o + 3] - S[o + 1]) * v1;
    _quad(n, x0, ya, x1, ya, x1, yb, x0, yb, S[o], t0, S[o + 2], t1, r, g, b, a);
  }

  void _flush(Canvas canvas) {
    if (_n == 0) return;
    final shader = ImageShader(atlas.image, TileMode.clamp, TileMode.clamp, Matrix4Identity.m, filterQuality: FilterQuality.medium);
    _norm.shader = shader;
    _plus.shader = shader;
    var s = 0;
    while (s < _n) {
      final add = _add[s];
      var e = s + 1;
      while (e < _n && _add[e] == add) {
        e++;
      }
      final v = ui.Vertices.raw(
        ui.VertexMode.triangles,
        Float32List.sublistView(_pos, s * 12, e * 12),
        textureCoordinates: Float32List.sublistView(_uv, s * 12, e * 12),
        colors: Int32List.sublistView(_col, s * 6, e * 6),
      );
      canvas.drawVertices(v, BlendMode.modulate, add == 1 ? _plus : _norm);
      v.dispose();
      s = e;
    }
  }

  // ── frame state (fields: nothing allocated per object) ───────────────────

  LopetNivaa _level = LopetNivaa.high;

  /// The level drawn in the last frame (tests, the developer overlay).
  LopetNivaa get lastLevel => _level;

  /// Sprites in the last frame.
  int lastCount = 0;

  double _w = 390, _h = 844, _t = 0, _m = 16.5, _k = 16.5 / 17, _px = .0165, _by = 650, _lw = 101.4, _tkf = 0;
  bool _lys = false, _run = false;
  int _qR = 2;
  double _rimA = 0, _df = 1;
  final Float64List _lx = Float64List(3);
  final Float32List _ob = Float32List(48);
  int _obN = 0;
  final Float32List _rpU = Float32List(32);
  final Float32List _kj = Float32List(4);

  // the camera for stamps (world → foam map)
  double _camD = 0;

  double _hoyde(double x, double t, double ph) => 2.4 * math.sin(t * 1.05 + x * .017 + ph) + 1.3 * math.sin(t * 1.73 - x * .031 + ph * 1.7) + .6 * math.sin(t * 2.9 + x * .07);
  double _bobF(double x, double ph, double k) => rolig ? 0 : _hoyde(x, _t, ph) * .32 * k;
  double _rulF(double x, double ph) => rolig ? 0 : math.atan2(_hoyde(x + 8, _t, ph) - _hoyde(x - 8, _t, ph), 16) * .7;

  void _obAdd(double x, double y, double a, double b) {
    final n = _obN;
    if (n >= 48) return;
    _ob[n] = x;
    _ob[n + 1] = y;
    _ob[n + 2] = a;
    _ob[n + 3] = b;
    _obN = n + 4;
  }

  /// The design's `refl`: mirrored at the waterline, short, broken in three bands by the waves.
  void _refl(int id, double x, double y, double k, double rot, double a) {
    if (_qR < 2 || id < 0) return;
    final G = atlas.geo, o = id * 4, vT = G[o + 3] / G[o + 1];
    if (vT <= 0) return;
    for (var i = 0; i < 3; i++) {
      final v0 = vT * i / 3, v1 = vT * (i + 1) / 3;
      final dx = rolig ? 0.0 : math.sin(_t * 2.3 + i * 1.9 + x * .05) * .55 * k * (3 - i) + math.sin(rot) * 6 * k * (1 - i / 3);
      sprV(id, x + dx, y, k, -k * .55, v0, v1, .45, .58, .64, a);
    }
  }

  /// The design's `lysStr`: a light that mirrors in the water (added light).
  void _lysStr(double x, double y, double len, double a, [double r = 1, double g = .84, double b = .55]) {
    final wb = rolig ? 0.0 : math.sin(_t * 2.4 + y * .07) * 1.6;
    final id = _a('lysStr');
    spr(id, x + wb, y, 1.2, len / 64, wb * .012, r, g, b, -a);
    spr(id, x - wb * .6, y + len * .35, .7, len * .5 / 64, 0, r, g, b, -a * .7);
  }

  void _strek(double x, double y, double dir, double w, List<double> c) {
    final id = _a('hvitM');
    for (var q = 0.0; q < w * .8; q += 11) {
      spr(id, x + dir * (q + 1.5), y, 3, 1.5, 0, c[0], c[1], c[2], .45);
    }
  }

  /// The design's `stp`: a stamp into the foam map at a field point.
  void _stp(String sprite, double x, double y, double wpx, double hm, double a) {
    final s = sea;
    if (s == null || a <= 0) return;
    final zA = _camD / 1000 + (_by - y) / _px / 1000;
    final v = zA / 128 - (zA / 128).floorToDouble();
    final yt = 512 - v * 512, xt = x * 128 / _w, sx = wpx * 128 / _w / 32, sy = hm * 4 / 32;
    final id = _a(sprite);
    s.stamp(id, xt, yt, sx, sy, a);
    if (yt < 24) {
      s.stamp(id, xt, yt + 512, sx, sy, a);
    } else if (yt > 488) {
      s.stamp(id, xt, yt - 512, sx, sy, a);
    }
  }

  /// The design's `ripNy`: a ring that spreads in the water (world metres).
  void _rip(double x, double y, double a) {
    final i = (fx.ripI = (fx.ripI + 1) % 8) * 4;
    fx.rip[i] = (x - _w / 2) / _px / 1000;
    fx.rip[i + 1] = _camD / 1000 + (_by - y) / _px / 1000;
    fx.rip[i + 2] = _t;
    fx.rip[i + 3] = a;
  }

  // ── paint ────────────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    final w = _w = size.width, h = _h = size.height;
    final sim = loop.sim;
    final nowMs = DateTime.now().microsecondsSinceEpoch / 1000.0;
    final T = _t = (nowMs / 1000) % 3600;
    final q = quality;
    // Without the shader the field is Low whatever the level says (spec §12.5, T32).
    final lvl = _level = sea == null ? LopetNivaa.low : q == null ? LopetNivaa.high : q.level;
    _qR = lvl == LopetNivaa.high ? 2 : lvl == LopetNivaa.medium ? 1 : 0;
    fx.maxN = lvl.particles;
    _lys = mode != LopetMode.dag;
    final regn = mode == LopetMode.regn;
    _rimA = regn ? .6 : 0;
    _n = 0;
    _obN = 0;
    _ob.fillRange(0, 48, 0);

    final tk = sim.tick;
    final tkf = _tkf = tk + loop.alpha;
    final dtf = fx.lastTick < 0 ? 1.0 : ((tkf - fx.lastTick)).clamp(0.0, 3.0).toDouble();
    _df = dtf;
    final vms = sim.speedAt(tk).toDouble();
    final vf = ((vms - sim.start) / math.max(1, sim.max - sim.start)).clamp(0.0, 1.0).toDouble();
    final d = loop.boatMm();
    _camD = d;
    _run = !sim.done;

    // The zoom: closer at the start, wider with speed, a small pulse on a near miss.
    final zm = rolig ? 13.5 : 16.5 - 4 * vf;
    var m = fx.zoom = fx.zoom == 0 ? zm : fx.zoom + (zm - fx.zoom) * .06;
    if (!rolig && fx.nearMissT > 0) {
      final u = (nowMs - fx.nearMissT) / 200;
      if (u < 1) {
        m *= 1 + .03 * math.sin(u * math.pi);
      } else {
        fx.nearMissT = 0;
      }
    }
    _m = m;
    final px = _px = m / 1000;
    final by = _by = (h * .77).roundToDouble();
    final cy0 = by + d * px;
    final lw = _lw = w * .26;
    final k = _k = m / m0;
    _lx[0] = w * .24;
    _lx[1] = w * .5;
    _lx[2] = w * .76;
    final scroll = _run ? vms / 60 * px : 0.0;

    // The boat across the lanes, and its heel in a lane change (fast out, soft landing, a small overshoot).
    final lp = loop.lanePos();
    final bx = w * (.24 + .26 * lp);
    var tilt = 0.0;
    final pr = ((tkf - sim.chStart) / sim.lc).clamp(0.0, 1.0).toDouble();
    final sg = (sim.chTo - sim.chFrom).sign.toDouble();
    if (pr < 1 && sg != 0) {
      tilt = math.sin(pr * math.pi) * .26 * sg;
    } else {
      final u = (tkf - (sim.chStart + sim.lc)) / 26;
      if (u >= 0 && u < 1.6) tilt = -.075 * sg * math.sin(u * math.pi * 1.6) * math.exp(-u * 2.2);
    }
    final byy = by - .8 * m;

    // The track for the wake: one point per 2.2 m.
    if (fx.trailD0.isNaN) {
      fx.trailD0 = d;
      fx.trail.fillRange(0, 8, bx);
    }
    fx.trail[0] = bx;
    var guard = 0;
    while (d - fx.trailD0 >= 2200 && guard++ < 8) {
      for (var i = 7; i > 1; i--) {
        fx.trail[i] = fx.trail[i - 1];
      }
      fx.trail[1] = bx;
      fx.trailD0 += 2200;
    }
    if (d - fx.trailD0 >= 2200) fx.trailD0 = d;
    final fr = (d - fx.trailD0) / 2200;

    // Rowing: the oars' phase runs with the run.
    final dR = fx.rowT == 0 ? 0.0 : ((nowMs - fx.rowT) / 1000).clamp(0.0, .1).toDouble();
    fx.rowT = nowMs;
    if (_run) fx.rowPhase += dR * (5.5 + 4 * vf);

    _events(sim, bx, byy, nowMs);

    // ── the banks: five tile types in Bryggen style, fixed per stretch, the right side mirrored ──
    {
      final ls = 128 / m0;
      final z0 = (d - (h - by) / px) / 1000, z1 = (d + by / px) / 1000;
      for (var j = math.max(-3, (z0 / ls).floor() - 1); j <= (z1 / ls).ceil(); j++) {
        final yb = cy0 - j * ls * 1000 * px;
        final t0 = _bankTyp(j, 0), t1 = _bankTyp(j, 1);
        spr(_a('bk$t0'), 0, yb, k, k, 0, 1, 1, 1, 1);
        spr(_a('bk$t1'), w, yb, -k, k, 0, 1, 1, 1, 1);
        if (_lys) {
          final l0 = bkLys[t0], l1 = bkLys[t1];
          if (l0 > 0) _lysStr((kant + 5) * k, yb - (128 - l0) * k, 40 * k, .28);
          if (l1 > 0) _lysStr(w - (kant + 5) * k, yb - (128 - l1) * k, 40 * k, .28);
        }
      }
    }

    // ── landmarks on a platform with their name tag (drawn at their own size, as the design) ──
    for (final (lmD, id, side) in _lm) {
      final y = cy0 - lmD * px;
      if (y < -40 || y > h + 110) continue;
      spr(_a('plattform'), side == 1 ? w : 0, y + 2, side == 1 ? -1 : 1, 1, 0, 1, 1, 1, 1);
      spr(_a('lm$id'), side == 1 ? w : 0, y, side == 1 ? -1 : 1, 1, 0, 1, 1, 1, 1);
      final tid = _a('lmTx$id');
      if (tid >= 0) {
        final ew = atlas.ew(tid);
        final cx = (side == 1 ? w - 25 : 25.0).clamp(ew / 2 + 2, w - ew / 2 - 2).toDouble();
        spr(tid, cx, y + 10, 1, 1, 0, 1, 1, 1, 1);
      }
      if (_lys) _lysStr(side == 1 ? w - (kant + 9) * k : (kant + 9) * k, y - 4, 52 * k, .3);
    }

    // ── rows in view (the app's course), drawn as the design's things in the water ──
    final toMm = d + by / px + 3000, fromMm = d - (h - by) / px - 3000;
    var n = sim.nextRow - 6;
    if (n < 0) n = 0;
    for (var gi = 0; gi < 90; gi++, n++) {
      final rd = sim.rowDAt(n);
      if (rd > toMm) break;
      if (rd < fromMm) continue;
      final r = sim.rowMapAt(n);
      final y = cy0 - rd * px;
      final t = r['t'];
      final lanes = r['l'] as List;
      if (t == 'boye') {
        for (var i = 0; i < lanes.length; i++) {
          _boye((lanes[i] as num).toInt(), y, n * 3 + i);
        }
      } else if (t == 'stokk' || t == 'garn') {
        var a = 2, b = 0;
        for (final l in lanes) {
          final v = (l as num).toInt();
          a = math.min(a, v);
          b = math.max(b, v);
        }
        if (t == 'stokk') {
          _stokk(a, b, y, n);
        } else {
          _garn(a, b, y, n);
        }
      } else if (t == 'beffen') {
        final xv = sim.beffenXNow(r, rd);
        final vx = ((r['p'] as Map)['vx'] as num?)?.toDouble() ?? 1;
        _beffen(w * (.24 - .13) + xv / 1000 * lw, y, vx >= 0 ? 1 : -1, n);
      } else if (t == 'make') {
        final p = r['p'] as Map;
        final a = (p['a'] as num).toInt();
        if (sim.u >= (rd - a) * 60) {
          final st = sim.firstAt((rd - a) * 60);
          final delay = math.max(1, (p['delay'] as num?)?.toInt() ?? 60);
          _maake((p['lane'] as num).toInt(), y, (tkf - st) * 60 / delay, n);
        }
      } else if (t == 'wake') {
        if (_run) {
          for (var i = 0; i < 3; i++) {
            _stp('strek', _lx[i], y, lw * 1.1, .9, .05 * _df);
          }
        }
      }
    }
    // crates (a crate taken is gone)
    var c = sim.nextCrate - 6;
    if (c < 0) c = 0;
    for (var gi = 0; gi < 60; gi++, c++) {
      final cd = sim.crateDAt(c);
      if (cd < 0 || cd > toMm) break;
      if (cd < fromMm || sim.crateTaken(c)) continue;
      _kasse(sim.crateLaneAt(c), cy0 - cd * px, c);
    }
    // kayaks on the move
    for (var i = 0; i < sim.kajakks.length; i++) {
      final kj = sim.kajakks[i];
      _kajakk(kj.lane, cy0 - kj.uAt(tk) / 60 * px, i + 40);
    }

    // ── the gates: two buoys, a sagging rope with bunting, and the label ──
    for (var i = 0; i < milestones.length && i < 3; i++) {
      final y = cy0 - milestones[i] * 1000 * px;
      if (y > -70 && y < h + 70) _port(i, w, y, fx.gateSmelt[i]);
    }

    // ── the flags: your best (left), the rival and the week's best (right) ──
    if (flags.bestMm > 0) {
      final y = cy0 - flags.bestMm * px;
      if (y > -20 && y < h + 50) {
        _strek(w * .1, y, 1, w, mint3);
        spr(_a('flagg0'), w * .1, y, 1, 1, 0, 1, 1, 1, 1);
      }
    }
    if (flags.rivalMm > 0) {
      final y = cy0 - flags.rivalMm * px;
      if (y > -20 && y < h + 50) {
        _strek(w * .9, y, -1, w, hvit3);
        spr(_a('flagg1'), w * .9, y, 1, 1, 0, 1, 1, 1, 1);
      }
    }
    if (flags.weekMm > 0) {
      final y = cy0 - flags.weekMm * px;
      if (y > -20 && y < h + 50) {
        _strek(w * .9, y, -1, w, gull3);
        spr(_a('flagg2'), w * .9, y, 1, 1, 0, 1, 1, 1, 1);
      }
    }
    if (regn) spr(_a('gradV'), -20, -20, (w + 40) / 4, 300 / 64, 0, .596, .655, .671, .55);

    // ── the ghost: the customer's best run, lane for lane; it stops at its flag ──
    final gm = loop.ghostMm();
    if (gm >= 0) {
      final gx = w * (.24 + .26 * loop.ghostLanePos());
      final g = loop.ghost;
      if (g != null && !g.done && gm >= d - 1) {
        _skygge(gx, byy, k, 1, tk < ghostLabelTicks);
      } else {
        final y = cy0 - gm * px - .8 * m;
        if (y < h + 80) _skygge(gx, y, k, math.max(.35, 1 - (d - gm) / 60000), false);
      }
    }

    // spray from the bow while running
    if (!rolig && _run && fx.rnd() < .3 + vf * .5) {
      final s = fx.rnd() < .5 ? -1.0 : 1.0;
      fx.add(0, bx + s * m * .5, byy - m * 2.2, s * (.5 + fx.rnd() * 1.3), -.3 - fx.rnd(), .09, 12 + fx.rnd() * 10, 22, 1 + fx.rnd() * 1.4, 0, 0, 0, .8);
    }
    final dod = fx.dod;
    if (_qR >= 1) sprV(_a('skrog'), bx, byy + 2.55 * m, k, -k * .4, 0, .5, .45, .58, .64, .2 * (1 - dod));
    _baat(bx, byy, tilt, tkf, sim, m, dod, nowMs);
    if (!sim.done) _aarSprut(bx, byy, m);
    if (_run) {
      _stp('prikk', bx, byy + 2.1 * m, 20 * k, 1.5, .1 * (.6 + vf) * _df);
      _stp('prikk', bx - .9 * m, byy - 2.2 * m, 9 * k, .7, .06 * _df);
      _stp('prikk', bx + .9 * m, byy - 2.2 * m, 9 * k, .7, .06 * _df);
    }
    if (regn) {
      final ty = T * 900;
      for (var i = 0; i < 46; i++) {
        final hs = _imul(i + 7, 0x9E3779B1);
        final x = hs % (w + 40).toInt() - 20.0, y = ((hs >> 12) % h.toInt() + ty) % h;
        spr(_a('hvitM'), x - 2, y + 7.5, 15.5, 1.2, 1.8314, 1, 1, 1, .22);
      }
    }
    if (fx.glimtT > 0) {
      final u = (nowMs - fx.glimtT) / 420;
      if (u < 1) {
        spr(_a('hvit'), -20, -20, w + 40, h + 40, 0, .949, .757, .306, .4 * (1 - u));
      } else {
        fx.glimtT = 0;
      }
    }
    if (fx.ringA > 0) {
      final rs = fx.ringR / 30;
      spr(_a('ring'), fx.ringX, fx.ringY, rs, rs, 0, .498, .941, .796, fx.ringA);
    }
    if (!rolig) fx.step(dtf, scroll);
    _fxGL();
    fx.lastTick = tkf;

    // ── the water, then everything else in one batch ──
    final s = sea;
    if (s != null && lvl != LopetNivaa.low) {
      s.updateFoam(dtf, atlas: atlas.image, src: atlas.src, geo: atlas.geo, density: atlas.density, on: true);
      final kc = kjol;
      _kj[0] = kc == 'gull' ? 1 : .5;
      _kj[1] = kc == 'gull' ? .83 : .94;
      _kj[2] = kc == 'gull' ? .43 : .8;
      _kj[3] = kc.isEmpty ? 0 : 1;
      _rpU.fillRange(0, 32, 0);
      for (var i = 0; i < 8; i++) {
        final o = i * 4, age = T - fx.rip[o + 2];
        if (fx.rip[o + 3] > 0 && age >= 0 && age <= 4) {
          _rpU[o] = fx.rip[o];
          _rpU[o + 1] = fx.rip[o + 1] - d / 1000;
          _rpU[o + 2] = age;
          _rpU[o + 3] = fx.rip[o + 3];
        }
      }
      s.paint(canvas, size,
          vs: lvl == LopetNivaa.high ? .75 : .5,
          t: T,
          m: m,
          by: by,
          vf: vf,
          zF: d / 1000,
          fr: fr,
          baat: 1 - dod,
          dod: dod,
          rolig: rolig,
          clouds: lvl == LopetNivaa.high,
          regn: regn ? 1 : 0,
          edge: kant * k,
          kjol: _kj,
          trail: fx.trail,
          obs: _ob,
          rip: _rpU);
    } else {
      canvas.drawRect(Offset.zero & size, Paint()..color = Color(_lowDeep[mode] ?? 0xFF19434F));
    }
    lastCount = _n;
    _flush(canvas);
  }

  static const Map<LopetMode, int> _lowDeep = {LopetMode.dag: 0xFF2F7384, LopetMode.kveld: 0xFF1E4F5C, LopetMode.regn: 0xFF2B5661};

  static int _imul(int a, int b) => ((a.toUnsigned(32) * b) & 0xFFFFFFFF);

  /// The design's `bankTyp`: steinkai 34 %, trebrygge 20 %, naust 16 %, fortøyd småbåt 16 %, svaberg 14 %.
  static int _bankTyp(int j, int side) {
    final x = ((_imul(j * 2 + side + 0x51ED, 0x9E3779B1) >> 8) % 100 + 100) % 100;
    return x < 34 ? 0 : x < 54 ? 1 : x < 70 ? 2 : x < 86 ? 3 : 4;
  }

  // ── events: the design's `hendelse`, `byttet`, `portFeiring`, record and the hit ──
  void _events(FjordSim sim, double bx, double byy, double nowMs) {
    final ev = fx.queued;
    fx.queued = 0;
    if (ev & FjordSim.evLane != 0 && sim.chTo != fx.lastLaneTo) {
      final sd = sim.chTo > fx.lastLaneTo ? -1.0 : 1.0;
      _stp('prikk', bx + sd * 1.3 * _m, byy, 18, 2, .45);
      _rip(bx + sd * _m, byy, .35);
      fx.sprut(bx, byy, sim.chTo > fx.lastLaneTo ? -1 : 1, 12);
    }
    fx.lastLaneTo = sim.chTo;
    if (ev & FjordSim.evCrate != 0) {
      _stp('ringS', bx, byy - 20, 34, 2.2, .55);
      fx.plask(bx, byy - 20, 7, false);
      _rip(bx, byy - 20, .5);
      fx.gnist(bx, byy - 22, 8, gnKasse);
    }
    if (ev & FjordSim.evNearMiss != 0) fx.nearMissT = nowMs;
    if (ev & FjordSim.evMeterFull != 0) fx.vestT = nowMs;
    if (ev & FjordSim.evVest != 0) {
      _stp('ringS', bx, byy, 60, 4, .8);
      _rip(bx, byy, .9);
      fx.vestT = 0;
      for (var i = 0; i < 16; i++) {
        final a = i / 16 * 6.283, v = 3 + fx.rnd() * 2;
        fx.add(1, bx + math.cos(a) * 3.1 * _m, byy + math.sin(a) * 3.1 * _m, math.cos(a) * v, math.sin(a) * v, .05, 26 + fx.rnd() * 10, 36, 2.5 + fx.rnd() * 2, gnVest[i % 2], 0, 0, .3);
      }
      fx.ringX = bx;
      fx.ringY = byy;
      fx.ringR = 10;
      fx.ringA = 1;
    }
    if (ev & FjordSim.evHit != 0) {
      fx.dodStartMs = nowMs + 150;
      fx.ringX = bx;
      fx.ringY = byy;
      fx.ringR = 8;
      fx.ringA = 1;
      fx.plask(bx, byy, 36, true);
      _stp('ringS', bx, byy, 80, 5, .9);
      _stp('prikk', bx, byy, 46, 3, 1);
      _rip(bx, byy, 1.2);
    }
    if (fx.dodStartMs > 0) fx.dod = ((nowMs - fx.dodStartMs) / 540).clamp(0.0, 1.0).toDouble();
    // gates: the bunting bursts into confetti
    final d = loop.boatMm();
    while (fx.gatesPassed < milestones.length && fx.gatesPassed < 3 && d >= milestones[fx.gatesPassed] * 1000) {
      final i = fx.gatesPassed++;
      fx.gateSmelt[i] = true;
      final y = _by - (milestones[i] * 1000 - d) * _px, gull = i == 2, cs = gull ? ksGull : ksMint;
      for (var q = 1; q < 16; q++) {
        final f = q / 16, x = _w * .1 + _w * .8 * f, yy = y + 48 * f * (1 - f);
        for (var j = 0; j < 3; j++) {
          final a = -math.pi / 2 + (fx.rnd() - .5) * 2.8, v = 2 + fx.rnd() * 4.5;
          fx.add(2, x, yy, math.cos(a) * v, math.sin(a) * v, .13, 38 + fx.rnd() * 30, 68, 6 + fx.rnd() * 4, cs[(q + j) % 3], fx.rnd() * 6.283, (fx.rnd() - .5) * .6, .5);
        }
      }
    }
    if (!fx.recordSaid && flags.bestMm > 0 && d > flags.bestMm) {
      fx.recordSaid = true;
      fx.glimtT = nowMs;
    }
  }

  // ── things in the water (the design's `tingGL`) ──────────────────────────

  void _boye(int lane, double y, int id) {
    if (y < -90 || y > _h + 90) return;
    final x = _lx[lane], k = _k, r = _m * 1.05, ph = id * 1.7, yy = y + _bobF(x, ph, k), rr = _rulF(x, ph);
    _obAdd(x, yy, r + 1, r * .76 + 1);
    spr(_a('prikk'), x + 9 * k, yy + 6 * k, 1.5 * k, .8 * k, 0, .02, .07, .1, .3);
    _refl(_a('boye3'), x, yy, k, rr, .3);
    if (_rimA > 0) spr(_a('boye3R'), x, yy, k, k, rr, 1, 1, 1, _rimA);
    spr(_a('boye3'), x, yy, k, k, rr, 1, 1, 1, 1);
    if (_lys) {
      spr(_a('glod'), x + math.sin(rr) * r * 2.1, yy - math.cos(rr) * r * 2.1, k, k, 0, 1, .84, .55, -.75);
      _lysStr(x, yy + 3 * k, 36 * k, .3);
    }
    if (_run && (_t - fx.buoyRipT > 1.4 || fx.buoyRipT > _t)) {
      fx.buoyRipT = _t;
      _rip(x, yy, .26);
    }
  }

  void _stokk(int a, int b, double y, int id) {
    if (y < -90 || y > _h + 90) return;
    final x0 = _lx[a] - _lw * .44, x1 = _lx[b] + _lw * .44, th = _m * 1.25, cx = (x0 + x1) / 2, yy = y + _bobF(cx, id.toDouble(), _k) * .6;
    _obAdd(cx, yy, (x1 - x0) / 2 + 1, th / 2 + 1);
    final sid = _a('stokkR${(((_tkf / 14).floor() + id) % 4 + 4) % 4}');
    final sx = (x1 - x0) / math.max(1, atlas.ew(sid) - 6);
    if (_rimA > 0) spr(_a('stokkR'), cx, yy, sx, _k, 0, 1, 1, 1, _rimA);
    spr(sid, cx, yy, sx, _k, 0, 1, 1, 1, 1);
    if (_run) _stp('strek', cx, yy - th * .6, x1 - x0, .7, .035 * _df);
  }

  void _garn(int a, int b, double y, int id) {
    if (y < -90 || y > _h + 90 + 18 * _m) return;
    final x0 = _lx[a] - _lw * .44, x1 = _lx[b] + _lw * .44;
    _obAdd((x0 + x1) / 2, y, (x1 - x0) / 2, 4);
    final gid = _a('garn');
    spr(gid, (x0 + x1) / 2, y, (x1 - x0) / math.max(1, atlas.ew(gid) - 2), _k, 0, .62, .8, .86, .72);
    for (var q = 0; q <= 9; q++) {
      final fx0 = x0 + (x1 - x0) * q / 9;
      spr(_a(q.isOdd ? 'flott1' : 'flott0'), fx0, y + (rolig ? 0 : math.sin(_t * 2.2 + q * 1.3 + id) * 1.2 + _hoyde(fx0, _t, q.toDouble()) * .12), 1, 1, 0, 1, 1, 1, 1);
    }
    for (var q = 0; q < 4; q++) {
      spr(_a('garnMerke'), _lx[q.isOdd ? b : a], y + (q < 2 ? 9 : 18) * _m, 1, 1, 0, 1, 1, 1, 1);
    }
  }

  void _kajakk(int lane, double y, int id) {
    if (y < -90 || y > _h + 90) return;
    final x = _lx[lane], k = _k, r1 = math.sin(_tkf * .05 + id) * .05, pa = math.sin(_tkf * .16) * .6;
    _obAdd(x, y, _m * .56 + 2, _m * 2.1);
    if (_rimA > 0) spr(_a('kajakk3R'), x, y, k, k, r1, 1, 1, 1, _rimA);
    spr(_a('kajakk3'), x, y, k, k, r1, 1, 1, 1, 1);
    spr(_a('padle'), x, y - 6 * k, k, k, r1 + pa, 1, 1, 1, 1);
    if (_run) {
      _stp('prikk', x, y + _m * 2.2, 9 * k, 1.4, .07 * _df);
      final n0 = ((_tkf - _df) * .16 / math.pi).floor(), n1 = (_tkf * .16 / math.pi).floor();
      if (n1 != n0) {
        final sd = n1.isOdd ? 1.0 : -1.0, an = r1 + pa, wk = _m * .56 * 2.7, ppx = x + math.cos(an) * wk * sd, ppy = y - 6 * k + math.sin(an) * wk * sd;
        _stp('prikk', ppx, ppy, 10 * k, .9, .3);
        for (var q = 0; q < 3; q++) {
          fx.add(0, ppx, ppy, sd * (.4 + fx.rnd()), -.6 - fx.rnd(), .12, 10 + fx.rnd() * 8, 18, 1 + fx.rnd(), 0, 0, 0, .8);
        }
      }
    }
  }

  void _beffen(double x, double y, double dir, int id) {
    if (y < -90 || y > _h + 90) return;
    final sp = _lx[1] - _lx[0], hw = sp * .82, hh = _m * 2.05, k = _k;
    _obAdd(x, y, hw, hh);
    if (_rimA > 0) spr(_a('beffen3R'), x, y, dir, k, 0, 1, 1, 1, _rimA);
    spr(_a('beffen3'), x, y, dir * sp / (atlas.ew(_a('beffen3')) / 2.4 / .82), k, 0, 1, 1, 1, 1);
    spr(_a('beffenTx'), x - dir * hw * .02, y - 6 * k + .5, 1, 1, 0, 1, 1, 1, 1);
    if (_run) {
      _stp('prikk', x - dir * hw * .95, y, 18 * k, 3.6, .11 * _df);
      _stp('prikk', x, y - hh * .9, hw * 1.5, .8, .04 * _df);
      _stp('prikk', x, y + hh * .9, hw * 1.5, .8, .04 * _df);
    }
  }

  void _kasse(int lane, double y, int id) {
    if (y < -90 || y > _h + 90) return;
    final x = _lx[lane], k = _k, s = _m * .85, ph = id * 2.3, yy = y + _bobF(x, ph, k), rr = _rulF(x, ph) * .8;
    final pu = .5 + .5 * math.sin(_tkf * .12 + id), rg = (s * 1.75 + pu * 3) / 30;
    _obAdd(x, yy, s, s * .76);
    spr(_a('ring'), x, yy, rg, rg * .76, 0, .498, .941, .796, .4 + .5 * pu);
    if (_rimA > 0) spr(_a('kasse3R'), x, yy, k, k, rr, 1, 1, 1, _rimA);
    spr(_a('kasse3'), x, yy, k, k, rr, 1, 1, 1, 1);
    final gp = (_t * .4 + id * .37) % 1;
    if (gp < .18) {
      final u = gp / .18;
      spr(_a('glint'), x + (u * 2 - 1) * s, yy - s * .55, k, k, rr, 1, 1, 1, -(1 - (u * 2 - 1).abs()) * .9);
    }
  }

  /// A diving gull (the design's `maakeGL`), [dt] in the design's ticks: 60 to dive, then the splash.
  void _maake(int lane, double yT0, double dt, int id) {
    if (dt < 0 || dt > 92) return;
    final x = _lx[lane], yT = yT0 - _m * .4;
    if (dt < 60) {
      final f = dt / 60, nA = (40 * (1 - f)).ceil();
      spr(_a('hvit'), x - _lw / 2 + 6, yT0 - _m * 26, _lw - 12, _m * 32, 0, 1, 1, 1, .05 + .06 * math.sin(dt * .26).abs());
      spr(_a('sirkel'), x, yT, (10 + f * 16) / 16, (6 + f * 8) / 16, 0, .016, .071, .102, .2 + .3 * f);
      for (var q = 0; q < nA; q++) {
        final a = -1.5708 + (q + .5) * .15708;
        spr(_a('hvitM'), x + 32 * math.cos(a), yT + 32 * math.sin(a), 5.4, 3, a + 1.5708, 1, 1, 1, 1);
      }
      final s = (20 - f * 9) / 20, fl = dt * .5;
      spr(_a('maake${(((fl / 6.2832 * 8).floor() % 8) + 8) % 8}'), x, yT - (1 - f) * 110, s, s, 0, 1, 1, 1, 1);
    } else {
      if (fx.gullSplashed[id] != true) {
        fx.gullSplashed[id] = true;
        fx.plask(x, yT, 14, false);
        _stp('ringS', x, yT, 44, 2.6, .7);
        _stp('prikk', x, yT, 22, 1.4, .6);
        _rip(x, yT, .9);
      }
      if (dt - 60 < 16) spr(_a('maake2'), x, yT, .55, .55, 0, 1, 1, 1, 1);
    }
  }

  /// A gate (the design's `portGL`): rope with a shadow, two buoys with their light, bunting until it bursts, the label.
  void _port(int i, double w, double y, bool smelt) {
    final gull = i == 2, id = _a(gull ? 'pboye1' : 'pboye0'), hv = _a('hvitM');
    for (var q = 0; q < 16; q++) {
      final f0 = q / 16, f1 = (q + 1) / 16, xa = w * .1 + w * .8 * f0, xb = w * .1 + w * .8 * f1, ya = y + 48 * f0 * (1 - f0), yb = y + 48 * f1 * (1 - f1);
      final ln = math.sqrt((xb - xa) * (xb - xa) + (yb - ya) * (yb - ya)) + .5, an = math.atan2(yb - ya, xb - xa);
      spr(hv, (xa + xb) / 2 + 1.5, (ya + yb) / 2 + 2.5, ln, 2, an, .016, .071, .102, .35);
      spr(hv, (xa + xb) / 2, (ya + yb) / 2, ln, 1.6, an, .96, .953, .937, .92);
    }
    final lr = gull ? 1.0 : .55, lg = gull ? .82 : 1.0, lb = gull ? .45 : .85;
    for (var q = 0; q < 2; q++) {
      final x = q == 1 ? w * .9 : w * .1, ph = i * 3.0 + q, bb = _bobF(x, ph, 1) * .9, rr = _rulF(x, ph) * .8;
      spr(_a('prikk'), x + 7, y + bb + 5, 1, .55, 0, .02, .07, .1, .3);
      _refl(id, x, y + bb, 1, rr, .28);
      spr(id, x, y + bb, 1, 1, rr, 1, 1, 1, 1);
      spr(_a('glod'), x + math.sin(rr) * 26, y + bb - math.cos(rr) * 26, .8, .8, 0, lr, lg, lb, _lys ? -.85 : -.4);
      if (_lys) _lysStr(x, y + bb + 3, 32, .28, lr, lg, lb);
    }
    if (smelt) return;
    final c = gull ? gull3 : mint3, c2 = gull ? mint3 : gull3, tri = _a('tri');
    for (var q = 1; q < 16; q++) {
      final f = q / 16, x = w * .1 + w * .8 * f, yy = y + 48 * f * (1 - f), sw = math.sin(_t * 5 + q * .9) * 2.5, r = q % 3, cc = r == 0 ? hvit3 : r == 1 ? c : c2;
      spr(tri, x, yy, 1, 1, -sw / 13, cc[0], cc[1], cc[2], 1);
    }
    spr(_a('portTx$i'), w / 2, y - 19.5, 1, 1, 0, 1, 1, 1, 1);
  }

  /// The ghost (the design's `skyggeGL`): the hull at 32 %, a dashed outline, «Din beste» over it at the start.
  void _skygge(double x, double y, double k, double a, bool label) {
    spr(_a('skrog'), x, y, k, k, 0, 1, 1, 1, .32 * a);
    spr(_a('skyggeOm'), x, y, k, k, 0, 1, 1, 1, .85 * a);
    if (label) spr(_a('skyggeTx'), x, y - k * m0 * 3.2, 1, 1, 0, 1, 1, 1, a);
  }

  /// The boat (the design's `baatGL`).
  void _baat(double x, double y, double tilt, double tk, FjordSim sim, double m, double dod, double nowMs) {
    final ro = level != 'Gull' && level != 'Platina', ph = fx.rowPhase;
    var rot = tilt + math.sin(tk * .05) * .02, sc = m / m0, a = 1.0;
    if (dod > 0) {
      rot += dod * 1.2;
      sc *= 1 - dod * .3;
      a = 1 - dod * .8;
    }
    final c = math.cos(rot), s = math.sin(rot), u = m0 * sc;
    if (sim.hasVest && dod == 0) {
      final vT = fx.vestT;
      final q = vT <= 0 ? 1.0 : ((nowMs - vT) / 380).clamp(0.0, 1.0).toDouble();
      final e = 1 - math.pow(1 - q, 3).toDouble(), z = sc * (1.3 - .3 * e);
      spr(_a('vest'), x, y, z, z, rot, 1, 1, 1, a * (.4 + .6 * e));
      if (q < 1) spr(_a('vest'), x, y, z, z, rot, 1, 1, 1, -(1 - q) * .9);
    }
    if (sim.tick < sim.graceUntil && ((tk.floor() >> 2) % 2) == 1) a *= .45;
    spr(_a('skrog'), x, y, sc, sc, rot, 1, 1, 1, a);
    if (_lys && dod == 0) {
      final lx = x - 2.0 * s * u, ly = y + 2.0 * c * u;
      spr(_a('glod'), lx, ly, .9 * sc, .9 * sc, 0, 1, .84, .55, -.8 * a);
      spr(_a('prikk'), lx, ly, .14 * sc, .14 * sc, 0, 1, .96, .82, a);
      _lysStr(lx, ly + 3, 46 * sc, .26 * a);
    }
    if (ro) {
      final a0 = math.sin(ph) * .5, inn = math.cos(ph) > 0;
      for (var side = -1; side <= 1; side += 2) {
        final lx = side.toDouble(), ly = .05, ppx = x + (lx * c - ly * s) * u, ppy = y + (lx * s + ly * c) * u, an = rot + (side > 0 ? a0 : math.pi - a0);
        if (!inn) spr(_a('aareSk'), ppx + (.1 * c - .25 * s) * u, ppy + (.1 * s + .25 * c) * u, sc, sc, an, 1, 1, 1, a);
        spr(_a(inn ? 'aareInn' : 'aareUt'), ppx, ppy, sc, sc, an, 1, 1, 1, a);
      }
    }
    final vp = vimpel.isNotEmpty ? vimpel : (level == 'Sølv' ? 'mint' : '');
    if (vp.isNotEmpty) spr(_a('vimpel_$vp'), x - 1.85 * s * u, y + 1.85 * c * u, sc, sc, rot + math.sin(tk * .3) * .04, 1, 1, 1, a);
    {
      final bob = ro ? -math.sin(ph) * .07 : math.sin(tk * .08) * .025, sq = ro ? 1 - .025 * math.cos(ph) : 1.0, ly = .34 + bob;
      spr(_a('aegil'), x - ly * s * u, y + ly * c * u, sc, sc * sq, rot, 1, 1, 1, a);
      spr(_a('toft'), x - .33 * s * u, y + .33 * c * u, sc, sc, rot, 1, 1, 1, a);
    }
    if (figur == 'brygga') {
      spr(_a('fig_brygga'), x + 2.28 * s * u, y - 2.28 * c * u, sc, sc, rot, 1, 1, 1, a);
    } else if (figur == 'stjerne') {
      spr(_a('fig_stjerne'), x + 2.62 * s * u, y - 2.62 * c * u, sc, sc, rot, 1, 1, 1, a);
    }
    if (level == 'Platina' && dod == 0) {
      final ct = math.cos(tilt), st = math.sin(tilt);
      spr(_a('platina'), x - st * m * 1.78, y + ct * m * 1.78, 1, 1, tilt, 1, 1, 1, 1);
    }
  }

  void _aarSprut(double bx, double by, double m) {
    if (level == 'Gull' || level == 'Platina' || rolig) return;
    final ph = fx.rowPhase, inn = math.cos(ph) > 0;
    if (inn && !fx.oarIn) {
      final a = math.sin(ph) * .5;
      for (var s = -1; s <= 1; s += 2) {
        final ex = bx + s * (1 + math.cos(a) * 1.65) * m, ey = by + (.05 + math.sin(a) * 1.65) * m;
        for (var i = 0; i < 5; i++) {
          fx.add(0, ex, ey, s * fx.rnd() * 1.4, -.6 - fx.rnd() * 1.4, .12, 12 + fx.rnd() * 10, 22, 1 + fx.rnd() * 1.3, 0, 0, 0, .8);
        }
      }
    }
    fx.oarIn = inn;
  }

  void _fxGL() {
    final ci = _a('sirkel'), st = _a('stjerne'), hv = _a('hvitM');
    for (var i = 0; i < fx.n; i++) {
      final kk = fx.kind[i], a = (fx.life[i] / (fx.maxLife[i] * .4)).clamp(0.0, 1.0).toDouble(), s = fx.size[i];
      final c = fxc[fx.colour[i]], r = ((c >> 16) & 255) / 255, g = ((c >> 8) & 255) / 255, b = (c & 255) / 255;
      if (kk == 0) {
        spr(ci, fx.x[i], fx.y[i], s / 16, s / 16, 0, r, g, b, a);
      } else if (kk == 1) {
        spr(st, fx.x[i], fx.y[i], s / 8, s / 8, 0, r, g, b, a);
      } else {
        spr(hv, fx.x[i], fx.y[i], s, s * .6, fx.rot[i], r, g, b, a);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LopetScene9 old) => old.atlas != atlas || old.sea != sea || old.mode != mode || old.level != level;
}
