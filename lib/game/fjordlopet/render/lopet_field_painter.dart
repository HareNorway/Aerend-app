import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/rendering.dart';

import '../sim/engine.dart';
import 'lopet_atlas.dart';
import 'lopet_look.dart';
import 'lopet_loop.dart';
import 'lopet_quality.dart';
import 'lopet_water.dart';

/// The flags on the water (spec §4.1 Markers, §5.6): distances in mm, −1 for none. Set at the start of a run.
class LopetFlags {
  double bestMm = -1;
  double weekMm = -1;
  double rivalMm = -1;
}

/// Fjordløpet v1.3 plan Step 9 (spec §12.2 layer 6): particles from one fixed pool (at most 256; the quality level
/// caps how many are live), and the events the screen queues for the painter (a crate, a near miss, a hit). Owned by
/// the screen so it outlives a rebuilt painter.
class LopetFx {
  static const int cap = 256;
  final Float32List x = Float32List(cap), y = Float32List(cap), vx = Float32List(cap), vy = Float32List(cap), life = Float32List(cap);
  final Uint8List kind = Uint8List(cap); // 0 spray, 1 rain
  int live = 0;
  int queued = 0; // FjordSim event bits

  void queue(int ev) => queued |= ev;

  void spawn(double px, double py, double pvx, double pvy, double l, int k, int limit) {
    if (live >= limit || live >= cap) return;
    x[live] = px;
    y[live] = py;
    vx[live] = pvx;
    vy[live] = pvy;
    life[live] = l;
    kind[live] = k;
    live++;
  }

  /// Moves every particle one frame and removes the dead (compacted in place, nothing allocated).
  void step(double dt, double scrollPy) {
    var j = 0;
    for (var i = 0; i < live; i++) {
      final l = life[i] - dt;
      if (l <= 0) continue;
      x[j] = x[i] + vx[i] * dt;
      y[j] = y[i] + vy[i] * dt + (kind[i] == 0 ? scrollPy : 0);
      vx[j] = vx[i];
      vy[j] = vy[i] + (kind[i] == 0 ? 180 * dt : 0);
      life[j] = l;
      kind[j] = kind[i];
      j++;
    }
    live = j;
  }

  void clear() {
    live = 0;
    queued = 0;
  }
}

/// Fjordløpet v1.3 plan Steps 5 and 9 (spec v1.3 §12.2, §12.5, §12.6): the play field.
///
/// One CustomPainter, repainted by the [FjordLoop] (a Listenable, no setState per frame). In drawing order:
/// 1. the water: at High and Medium [LopetWater] (the shader into a smaller offscreen image, the foam map); at Low two
///    textures scrolling at different speeds;
/// 2–4. then, in **one `drawRawAtlas` call**: cloud shadows (High), the banks with quay walls, piers and moored
///    boats, the landmarks; under every object its shadow, its reflection (all at High, the boat only at Medium) and
///    the foam where it meets the water; the lane foam;
/// 5. the gates, flags, obstacles, crates, ghost and boat sorted from the far row to the near, each bobbing in one
///    shared wave field (visual only: no hitbox moves);
/// 6. particles (spray, splashes) and rain from the fixed pool; glow sprites for the lights in Kveld and Regn.
///
/// Positions are interpolated between the last two ticks and never rounded to whole pixels. The transform, rect and
/// colour buffers, the staging arrays and the Paints are made once. No saveLayer, blur or opacity layer (T30). The
/// lanes sit where the prototype has them (centres at 0.24, 0.5 and 0.76 of the width), so the banks have room.
class LopetFieldPainter extends CustomPainter {
  LopetFieldPainter({
    required this.loop,
    required this.atlas,
    required this.boat,
    required this.milestones,
    required this.flags,
    this.rolig = false,
    this.quality,
    this.water,
    this.fx,
    List<Map<String, dynamic>> landmarks = const [],
  })  : _lmD = Float64List(landmarks.length),
        _lmSide = Int8List(landmarks.length),
        _lmSprite = Int16List(landmarks.length),
        super(repaint: loop) {
    var n = 0;
    for (final l in landmarks) {
      final sp = LopetAtlas.landmark('${l['k']}');
      if (sp == null) continue;
      _lmD[n] = (l['d'] as num?)?.toDouble() ?? 0;
      _lmSide[n] = ((l['s'] as num?)?.toInt() ?? -1) < 0 ? -1 : 1;
      _lmSprite[n] = sp.index;
      n++;
    }
    _lmN = n;
  }

  final FjordLoop loop;
  final LopetAtlas atlas;

  /// robaat | vimpel | snekke | egen
  final String boat;
  final List<int> milestones;
  final LopetFlags flags;

  /// Reduce motion: no parallax between the water layers, no bobbing, no shake.
  final bool rolig;

  /// The level to draw at; null = Low.
  final LopetQuality? quality;

  /// The shader water (null when the program did not load: Low).
  final LopetWater? water;
  final LopetFx? fx;

  final Float64List _lmD;
  final Int8List _lmSide;
  final Int16List _lmSprite;
  int _lmN = 0;

  static const int cap = 900;
  static const double mAhead = 46; // metres visible ahead of the boat
  static const double mBehind = 12;
  static const List<double> laneCentres = [.24, .5, .76];
  static const double laneShare = .26;
  static const double bankShare = .085;

  final Float32List _t = Float32List(cap * 4);
  final Float32List _r = Float32List(cap * 4);
  final Int32List _c = Int32List(cap);
  final List<Float32List?> _tv = List<Float32List?>.filled(cap + 1, null);
  final List<Float32List?> _rv = List<Float32List?>.filled(cap + 1, null);
  final List<Int32List?> _cv = List<Int32List?>.filled(cap + 1, null);

  // Staging: sprite, centre x, y, scale, rotation, colour; and the draw order.
  final Int16List _sp = Int16List(cap);
  final Float32List _x = Float32List(cap);
  final Float32List _y = Float32List(cap);
  final Float32List _s = Float32List(cap);
  final Float32List _rot = Float32List(cap);
  final Int32List _col = Int32List(cap);
  final Int16List _order = Int16List(cap);
  int _n = 0;
  int _bgCount = 0;
  int _objEnd = 0;

  final Paint _paint = Paint()..filterQuality = FilterQuality.low;
  final Paint _water = Paint();
  Rect _bgRect = Rect.zero;
  Size _lastSize = Size.zero;
  double _lastT = -1;

  // This frame's geometry (fields, not closures: nothing allocated per frame).
  double _boatY = 0, _boatMm = 0, _pxPerM = 1, _laneW = 1, _w = 1, _tick = 0;
  LopetNivaa _level = LopetNivaa.low;

  double _yOf(double mm) => _boatY - (mm - _boatMm) / 1000 * _pxPerM;
  double _laneX(double lane) => _w * (laneCentres[0] + laneShare * lane);

  static const int _white = 0xFFFFFFFF;
  static const int _ghost = 0x59FFFFFF;
  static const int _blink = 0x73FFFFFF;
  static const int _dim = 0xB3FFFFFF;

  /// The level drawn in the last frame (tests, the developer overlay, the run's perf).
  LopetNivaa get lastLevel => _level;

  void _add(LopetSprite s, double x, double y, double scale, [int colour = _white, double rot = 0]) {
    if (_n >= cap) return;
    _sp[_n] = s.index;
    _x[_n] = x;
    _y[_n] = y;
    _s[_n] = scale;
    _rot[_n] = rot;
    _col[_n] = colour;
    _n++;
  }

  /// The shared wave field: a small lift and tilt for an object at (y, seed). Visual only.
  double _bob(double seed) => rolig ? 0 : math.sin(_tick * .07 + seed) * 1.2;
  double _tilt(double seed) => rolig ? 0 : math.sin(_tick * .05 + seed) * .05;

  /// An object with its height: shadow, reflection and foam under it (background), the figure itself (sorted).
  void _object(LopetSprite s, double x, double y, double scale, double seed, {int colour = _white, bool reflect = false}) {
    final sw = atlas.width(s) * scale, sh = atlas.height(s) * scale;
    // A sprite scales the same both ways, so a wide object (the log, Beffen) gets its shadow and foam as a row of
    // small ones along its length, each about as wide as the object is tall.
    final parts = (sw / (sh * 1.6)).ceil().clamp(1, 6);
    final pw = sw / parts;
    final shadowScale = pw / atlas.width(LopetSprite.shadow);
    for (var k = 0; k < parts; k++) {
      final px = x - sw / 2 + pw * (k + .5);
      _addBg(LopetSprite.shadow, px + sh * .1, y + sh * .16, shadowScale);
      _addBg(LopetSprite.foamRing, px, y + sh * .2, shadowScale * .95);
    }
    if (reflect) {
      final r = LopetAtlas.reflectionOf(s);
      if (r != null) _addBg(r, x, y + sh * .62, scale * atlas.width(s) / atlas.width(r) * .92);
    }
    _add(s, x, y + _bob(seed), scale, colour, _tilt(seed));
  }

  // Background entries are staged in a second region and copied in front of the objects in [_flush].
  final Int16List _bsp = Int16List(cap);
  final Float32List _bx = Float32List(cap);
  final Float32List _by = Float32List(cap);
  final Float32List _bs = Float32List(cap);
  int _bn = 0;

  void _addBg(LopetSprite s, double x, double y, double scale) {
    if (_bn >= cap) return;
    _bsp[_bn] = s.index;
    _bx[_bn] = x;
    _by[_bn] = y;
    _bs[_bn] = scale;
    _bn++;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = _w = size.width, h = size.height;
    if (size != _lastSize) {
      _lastSize = size;
      _bgRect = Offset.zero & size;
    }
    final look = LopetLook.of(atlas.mode);
    final q = quality;
    final wtr = water;
    _level = q == null ? LopetNivaa.low : q.level;
    if (wtr == null) _level = LopetNivaa.low;

    final sim = loop.sim;
    _tick = sim.tick + loop.alpha;
    final laneW = _laneW = w * laneShare;
    final s1 = laneW / (LopetAtlas.unit * atlas.density); // one lane unit
    final boatY = _boatY = h * .74;
    final pxPerM = _pxPerM = boatY / mAhead;
    final boatMm = _boatMm = loop.boatMm();
    final scroll = boatMm / 1000 * pxPerM;
    final tSec = _tick / 60;
    final dt = _lastT < 0 ? 0.0 : (tSec - _lastT).clamp(0.0, .1).toDouble();
    final speedMms = sim.speedAt(sim.tick);
    final dScroll = dt * speedMms / 1000 * pxPerM;
    _lastT = tSec;
    final bankW = w * bankShare;

    // 1. The water.
    if (_level.shader && wtr != null) {
      wtr.paint(canvas, size, scrollPx: scroll, tSec: tSec, level: _level, laneW: laneW, bankW: bankW);
    } else {
      _water.color = look.deep;
      canvas.drawRect(_bgRect, _water);
    }

    _n = 0;
    _bn = 0;

    // Low: two water textures scrolling at different speeds.
    if (!_level.shader || wtr == null) {
      final rows = (h / laneW).ceil() + 2;
      for (var layer = 0; layer < 2; layer++) {
        final speed = layer == 0 || rolig ? 1.0 : .6;
        final off = (scroll * speed) % laneW;
        final sprite = layer == 0 ? LopetSprite.water0 : LopetSprite.water1;
        for (var row = -1; row < rows; row++) {
          final y = row * laneW + off + laneW / 2;
          for (var col = 0; col < 4; col++) {
            _addBg(sprite, laneW * (col + .1), y, s1);
          }
        }
      }
    }

    // Cloud shadows drift over the water (High).
    if (_level.cloudShadows && !rolig) {
      final cw = atlas.width(LopetSprite.cloud) * s1 * 1.4;
      for (var k = 0; k < 2; k++) {
        final cx = (tSec * 6 + k * w * .7) % (w + cw) - cw / 2;
        final cy = (scroll * .9 + k * h * .55) % (h + cw) - cw / 2;
        _addBg(LopetSprite.cloud, cx, cy, s1 * 1.4);
      }
    }

    // The banks: stone quay on both sides, a pier and a moored boat now and then.
    final tileH = atlas.height(LopetSprite.bankQuay) * s1 * (bankW / (atlas.width(LopetSprite.bankQuay) * s1 * .82));
    final bankScale = bankW / (atlas.width(LopetSprite.bankQuay) * .82);
    final bankOff = scroll % tileH;
    final tiles = (h / tileH).ceil() + 2;
    final firstTile = (scroll / tileH).floor();
    for (var t = -1; t < tiles; t++) {
      final y = t * tileH + bankOff - tileH / 2 + tileH;
      final idx = firstTile - t;
      _addBg(LopetSprite.bankQuay, bankW * .5, y, bankScale);
      _addBgFlipped(LopetSprite.bankQuay, w - bankW * .5, y, bankScale);
      if (idx % 5 == 0) _addBg(LopetSprite.bankPier, bankW * 1.05, y, bankScale * .9);
      if (idx % 7 == 3) {
        final mx = w - bankW * 1.15;
        _addBg(LopetSprite.shadow, mx + 3, y + 6, s1 * .5);
        _addBg(LopetSprite.moored, mx, y, s1 * .9);
      }
    }

    final fromMm = boatMm - mBehind * 1000, toMm = boatMm + mAhead * 1000;

    // Landmarks on their bank (from the course), standing with their footprint at the water's edge.
    final lmLen = atlas.rects.length; // guard for an atlas without the landmark sprites
    for (var i = 0; i < _lmN; i++) {
      final d = _lmD[i];
      if (d < fromMm - 20000 || d > toMm + 20000) continue;
      final sp = LopetSprite.values[_lmSprite[i]];
      if (sp.index * 4 >= lmLen) continue;
      final y = _yOf(d);
      final sc = bankW * 1.2 / atlas.width(sp);
      final x = _lmSide[i] < 0 ? bankW * .62 : w - bankW * .62;
      _addBg(LopetSprite.shadow, x + bankW * .3, y + bankW * .1, sc * atlas.width(sp) / atlas.width(LopetSprite.shadow));
      if (look.lightsOn) _addBg(LopetSprite.streak, x, y + atlas.height(sp) * sc * .5, s1 * 1.2);
      _add(sp, x, y - atlas.height(sp) * sc * .38, sc);
    }

    // The lane foam: faint streaks between the lanes, flowing with the water (speed shows).
    final foamGap = laneW * .55;
    final foamOff = scroll % foamGap;
    final foamRows = (h / foamGap).ceil() + 2;
    for (var row = -1; row < foamRows; row++) {
      final y = row * foamGap + foamOff;
      _addBg(LopetSprite.foam, w * (laneCentres[0] + laneCentres[1]) / 2, y, s1);
      _addBg(LopetSprite.foam, w * (laneCentres[1] + laneCentres[2]) / 2, y, s1);
    }

    final reflectAll = _level.reflectAll;

    // Gates (first lap) with their labels.
    final gateScale = (w - 2 * bankW) / atlas.width(LopetSprite.gate);
    for (var k = 0; k < milestones.length && k < 3; k++) {
      final y = _yOf(milestones[k] * 1000.0);
      if (y < -laneW || y > h + laneW) continue;
      _add(LopetSprite.gate, w / 2, y, gateScale, _white, 0);
      _add(LopetSprite.values[LopetSprite.label0.index + k], w / 2, y - laneW * .36, s1);
    }
    // Flags: your best, the rival, the week's best.
    if (flags.bestMm >= 0) _flag(LopetSprite.flagBest, w - bankW - laneW * .1, _yOf(flags.bestMm), s1, h, laneW);
    if (flags.rivalMm >= 0) _flag(LopetSprite.flagRival, w - bankW - laneW * .32, _yOf(flags.rivalMm), s1, h, laneW);
    if (flags.weekMm >= 0) _flag(LopetSprite.flagWeek, bankW + laneW * .1, _yOf(flags.weekMm), s1, h, laneW);

    // Rows in view.
    final tick = sim.tick;
    var n = sim.nextRow - 4;
    if (n < 0) n = 0;
    for (var guard = 0; guard < 80; guard++, n++) {
      final d = sim.rowDAt(n);
      if (d > toMm) break;
      if (d < fromMm) continue;
      final r = sim.rowMapAt(n);
      final y = _yOf(d.toDouble());
      final t = r['t'];
      final lanes = r['l'] as List;
      if (t == 'boye') {
        for (var i = 0; i < lanes.length; i++) {
          final x = _laneX((lanes[i] as num).toDouble());
          _object(LopetSprite.boye, x, y, s1, n + i * 1.7, reflect: reflectAll);
          if (look.lightsOn) _addTop(LopetSprite.glow, x, y + _bob(n + i * 1.7), s1 * .7);
        }
      } else if (t == 'stokk' || t == 'garn') {
        final a = (lanes[0] as num).toDouble(), b = (lanes[lanes.length - 1] as num).toDouble();
        if (t == 'stokk') {
          _object(LopetSprite.stokk, _laneX((a + b) / 2), y, s1, n.toDouble(), reflect: reflectAll);
        } else {
          _add(LopetSprite.garn, _laneX((a + b) / 2), y, s1);
          final fy = y - pxPerM * 6; // floats mark it early
          _add(LopetSprite.garnFloat, _laneX(a), fy + _bob(n + .3), s1);
          _add(LopetSprite.garnFloat, _laneX(b), fy + _bob(n + .9), s1);
        }
      } else if (t == 'kajakk') {
        if (n >= sim.kNext) _object(LopetSprite.kajakk, _laneX(((r['p'] as Map)['lane'] as num).toDouble()), y, s1, n.toDouble(), reflect: reflectAll);
      } else if (t == 'beffen') {
        final xv = sim.beffenXNow(r, d);
        _object(LopetSprite.beffen, _w * (laneCentres[0] - laneShare / 2) + xv / 1000 * laneW, y, s1, n.toDouble(), reflect: reflectAll);
      } else if (t == 'make') {
        final p = r['p'] as Map;
        final a = (p['a'] as num).toInt();
        final lane = _laneX((p['lane'] as num).toDouble());
        if (sim.u >= (d - a) * 60) {
          final st = sim.firstAt((d - a) * 60);
          final dived = tick >= st + (p['delay'] as num).toInt();
          if (dived) {
            _addBg(LopetSprite.shadow, lane + 3, y + 5, s1 * .8);
            _add(LopetSprite.gull, lane, y, s1);
          } else {
            _add(LopetSprite.gullShadow, lane, y, s1);
          }
        }
      } else if (t == 'wake') {
        _add(LopetSprite.wake, w / 2, y, (w - 2 * bankW) / atlas.width(LopetSprite.wake));
      }
    }
    // Crates in view (a crate picked up is gone), each with its pulsing ring.
    var m = sim.nextCrate - 6;
    if (m < 0) m = 0;
    for (var guard = 0; guard < 60; guard++, m++) {
      final d = sim.crateDAt(m);
      if (d < 0 || d > toMm) break;
      if (d < fromMm || sim.crateTaken(m)) continue;
      final x = _laneX(sim.crateLaneAt(m).toDouble()), y = _yOf(d.toDouble());
      _addBg(LopetSprite.crateRing, x, y, s1 * (.95 + .08 * math.sin(_tick * .12 + m)));
      _object(LopetSprite.crate, x, y, s1, m * 2.1, reflect: reflectAll);
    }
    // Kajakks on the move.
    for (var i = 0; i < sim.kajakks.length; i++) {
      final k = sim.kajakks[i];
      _object(LopetSprite.kajakk, _laneX(k.lane.toDouble()), _yOf(k.uAt(tick) / 60), s1, 40.0 + i, reflect: reflectAll);
    }
    // The ghost (spec §5.5): translucent, cannot be hit, no shadow.
    final gm = loop.ghostMm();
    final boatSprite = switch (boat) {
      'vimpel' => LopetSprite.boatVimpel,
      'snekke' => LopetSprite.boatSnekke,
      'egen' => LopetSprite.boatEgen,
      _ => LopetSprite.boatRobaat,
    };
    if (gm >= 0) _add(boatSprite, _laneX(loop.ghostLanePos()), _yOf(gm), s1, _ghost);

    // Far to near.
    _objEnd = _n;
    _sortObjects();

    // The boat: bow wave, V wake that lengthens with speed, roll in the turn, then the life ring when the meter is full.
    final lp = loop.lanePos();
    final bx = _laneX(lp);
    final roll = rolig ? 0.0 : ((sim.chTo - lp) * .3).clamp(-.26, .26).toDouble();
    final speedShare = ((speedMms - 9000) / 15000).clamp(0.0, 1.0).toDouble();
    final blink = tick < sim.graceUntil && (tick ~/ 6).isEven;
    final boatH = atlas.height(boatSprite) * s1;
    if (_level.reflectBoat) _addBoat(LopetSprite.reflBoat, bx, boatY + boatH * .5, s1 * atlas.width(boatSprite) / atlas.width(LopetSprite.reflBoat) * .9, _dim, 0);
    _addBoat(LopetSprite.shadow, bx + 4, boatY + 8, s1 * atlas.width(boatSprite) / atlas.width(LopetSprite.shadow) * 1.1, _white, 0);
    _addBoat(LopetSprite.bowWave, bx, boatY - boatH * .46, s1 * (.8 + .4 * speedShare), _white, roll * .5);
    final wtr2 = water;
    // The V wake: two arms that open behind the stern, longer at speed, bent by the roll in a lane change. Drawn as
    // sprites at every level (stamped into the scrolling foam map they would smear into straight lines).
    final len = boatH * (1 + 1.8 * speedShare);
    for (var i = 1; i <= 5; i++) {
      final f = i / 5;
      final yy = boatY + boatH * .38 + f * len, bend = roll * laneW * .5 * f;
      final sz = s1 * (1.9 - f * .7);
      _addBoat(LopetSprite.spray, bx - f * laneW * .34 + bend, yy, sz, _dim, 0);
      _addBoat(LopetSprite.spray, bx + f * laneW * .34 + bend, yy, sz, _dim, 0);
    }
    if (wtr2 != null && _level.foamMap) {
      // The foam map takes the track right behind the stern and the bow wave; the water carries them away and they fade.
      wtr2.stamp(bx, boatY + boatH * .42, 3.2, .3);
      wtr2.stamp(bx, boatY - boatH * .48, 4.5, .35);
    }
    _addBoat(boatSprite, bx, boatY + _bob(0) * .5, s1, blink ? _blink : _white, roll);
    if (sim.hasVest) _addBoat(LopetSprite.ring, bx, boatY, s1, _white, 0);
    if (look.lightsOn) _addBoat(LopetSprite.glow, bx, boatY + boatH * .45, s1 * .5, _white, 0);

    // Particles and weather.
    final f = fx;
    if (f != null) {
      final limit = _level.particles;
      if (!rolig && dt > 0) {
        // Spray from the oars and the bow, more at speed.
        final k = (1 + 3 * speedShare).round();
        for (var i = 0; i < k; i++) {
          final side = (i + tick).isEven ? -1.0 : 1.0;
          f.spawn(bx + side * laneW * .2, boatY - boatH * .2, side * (20 + 40 * _hash(tick * 7 + i)), -60 - 60 * _hash(tick * 13 + i), .35, 0, limit);
        }
      }
      final ev = f.queued;
      if (ev != 0) {
        f.queued = 0;
        final ring = ev & (FjordSim.evCrate | FjordSim.evNearMiss) != 0;
        final hit = ev & (FjordSim.evHit | FjordSim.evVest) != 0;
        if (hit) {
          for (var i = 0; i < 24; i++) {
            final a = i / 24 * math.pi * 2;
            f.spawn(bx, boatY - boatH * .4, math.cos(a) * 140, math.sin(a) * 140 - 60, .6, 0, limit);
          }
          wtr2?.stamp(bx, boatY - boatH * .4, 22, .9, ring: true);
        } else if (ring) {
          wtr2?.stamp(bx, boatY - boatH * .2, 16, .8, ring: true);
          for (var i = 0; i < 8; i++) {
            final a = i / 8 * math.pi * 2;
            f.spawn(bx, boatY - boatH * .2, math.cos(a) * 80, math.sin(a) * 80, .4, 0, limit);
          }
        }
      }
      if (look.regn) {
        while (f.live < limit && _rainCount(f) < limit ~/ 4) {
          f.spawn(_hash(tick * 3 + f.live) * w, _hash(tick * 5 + f.live) * h, -60, 900, .5 + _hash(f.live.toDouble()) * .4, 1, limit);
        }
      }
      f.step(dt, dScroll);
      for (var i = 0; i < f.live; i++) {
        _addBoat(f.kind[i] == 0 ? LopetSprite.spray : LopetSprite.rain, f.x[i], f.y[i], s1 * (f.kind[i] == 0 ? .9 : 1.2), f.kind[i] == 0 ? _white : _dim, 0);
      }
    }
    _flush(canvas);
  }

  int _rainCount(LopetFx f) {
    var n = 0;
    for (var i = 0; i < f.live; i++) {
      if (f.kind[i] == 1) n++;
    }
    return n;
  }

  static double _hash(num v) {
    final s = math.sin(v * 12.9898) * 43758.5453;
    return s - s.floorToDouble();
  }

  void _flag(LopetSprite s, double x, double y, double scale, double h, double laneW) {
    if (y < -laneW || y > h + laneW) return;
    _add(s, x, y, scale);
  }

  // The right bank's quay: the same tile turned half a circle (its land side outwards).
  void _addBgFlipped(LopetSprite s, double x, double y, double scale) {
    if (_bn >= cap) return;
    _bsp[_bn] = -1 - s.index; // negative = turned
    _bx[_bn] = x;
    _by[_bn] = y;
    _bs[_bn] = scale;
    _bn++;
  }

  /// A bright sprite laid on top of the object just staged (glow): sorted right after it.
  void _addTop(LopetSprite s, double x, double y, double scale) => _add(s, x, y + .01, scale);

  void _addBoat(LopetSprite s, double x, double y, double scale, int colour, double rot) {
    _add(s, x, y, scale, colour, rot);
    _order[_n - 1] = _n - 1;
  }

  /// Insertion sort of the object entries by y (small arrays; nothing allocated).
  void _sortObjects() {
    for (var i = 0; i < _n; i++) {
      _order[i] = i;
    }
    _bgCount = 0;
    for (var i = 1; i < _objEnd; i++) {
      final v = _order[i];
      final key = _y[v];
      var j = i - 1;
      while (j >= 0 && _y[_order[j]] > key) {
        _order[j + 1] = _order[j];
        j--;
      }
      _order[j + 1] = v;
    }
  }

  void _flush(Canvas canvas) {
    final rects = atlas.rects;
    var o = 0;
    // Background first, in the order staged.
    for (var i = 0; i < _bn && o < cap; i++, o++) {
      final raw = _bsp[i];
      final turned = raw < 0;
      final sp = turned ? -1 - raw : raw;
      final l = rects[sp * 4], t = rects[sp * 4 + 1], r = rects[sp * 4 + 2], b = rects[sp * 4 + 3];
      final sc = _bs[i];
      final hw = sc * (r - l) / 2, hh = sc * (b - t) / 2;
      final scos = turned ? -sc : sc;
      _t[o * 4] = scos;
      _t[o * 4 + 1] = 0;
      _t[o * 4 + 2] = turned ? _bx[i] + hw : _bx[i] - hw;
      _t[o * 4 + 3] = turned ? _by[i] + hh : _by[i] - hh;
      _r[o * 4] = l;
      _r[o * 4 + 1] = t;
      _r[o * 4 + 2] = r;
      _r[o * 4 + 3] = b;
      _c[o] = _white;
    }
    for (var i = 0; i < _n && o < cap; i++, o++) {
      final e = _order[i];
      final sp = _sp[e];
      final l = rects[sp * 4], t = rects[sp * 4 + 1], r = rects[sp * 4 + 2], b = rects[sp * 4 + 3];
      final sc = _s[e];
      final rot = _rot[e];
      final y = _y[e];
      final scos = rot == 0 ? sc : sc * math.cos(rot), ssin = rot == 0 ? 0.0 : sc * math.sin(rot);
      final ax = (r - l) / 2, ay = (b - t) / 2;
      _t[o * 4] = scos;
      _t[o * 4 + 1] = ssin;
      _t[o * 4 + 2] = _x[e] - scos * ax + ssin * ay;
      _t[o * 4 + 3] = y - ssin * ax - scos * ay;
      _r[o * 4] = l;
      _r[o * 4 + 1] = t;
      _r[o * 4 + 2] = r;
      _r[o * 4 + 3] = b;
      _c[o] = _col[e];
    }
    final n = o;
    _drawn = n;
    final tv = _tv[n] ??= Float32List.sublistView(_t, 0, n * 4);
    final rv = _rv[n] ??= Float32List.sublistView(_r, 0, n * 4);
    final cv = _cv[n] ??= Int32List.sublistView(_c, 0, n);
    canvas.drawRawAtlas(atlas.image, tv, rv, cv, BlendMode.modulate, null, _paint);
  }

  int _drawn = 0;

  /// Entries drawn in the last frame (tests and the developer overlay).
  int get lastCount => _drawn;

  @override
  bool shouldRepaint(LopetFieldPainter old) =>
      old.atlas != atlas || old.loop != loop || old.boat != boat || old.rolig != rolig || old.water != water || old.quality != quality;
}
