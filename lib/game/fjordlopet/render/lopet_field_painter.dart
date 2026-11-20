import 'dart:typed_data';

import 'package:flutter/rendering.dart';

import 'lopet_atlas.dart';
import 'lopet_loop.dart';

/// The flags on the water (spec §4.1 Markers, §5.6): distances in mm, −1 for none. Set at the start of a run.
class LopetFlags {
  double bestMm = -1;
  double weekMm = -1;
  double rivalMm = -1;
}

/// Fjordløpet v1.3 plan Step 5 (spec v1.3 §12.2, §12.5 Low): the play field.
///
/// One CustomPainter, repainted by the [FjordLoop] (a Listenable, no setState per frame). Every figure comes from the
/// [LopetAtlas] and goes out in **one `drawRawAtlas` call**: the water (two textures scrolling at different speeds —
/// quality Low), the lane foam, then the gates, flags, obstacles, crates, ghost and boat sorted from the far row to the
/// near. Positions are interpolated between the last two ticks and never rounded to whole pixels. Nothing is allocated
/// per frame: the transform, rect and colour buffers, the staging arrays and the Paint are made once (the list views
/// for each count are cached the first time that count is drawn). No saveLayer, blur or opacity layer.
class LopetFieldPainter extends CustomPainter {
  LopetFieldPainter({
    required this.loop,
    required this.atlas,
    required this.boat,
    required this.milestones,
    required this.flags,
    this.rolig = false,
  }) : super(repaint: loop);

  final FjordLoop loop;
  final LopetAtlas atlas;

  /// robaat | vimpel | snekke | egen
  final String boat;
  final List<int> milestones;
  final LopetFlags flags;

  /// Reduce motion: no parallax between the water layers.
  final bool rolig;

  static const int cap = 512;
  static const double mAhead = 46; // metres visible ahead of the boat
  static const double mBehind = 12;

  final Float32List _t = Float32List(cap * 4);
  final Float32List _r = Float32List(cap * 4);
  final Int32List _c = Int32List(cap);
  final List<Float32List?> _tv = List<Float32List?>.filled(cap + 1, null);
  final List<Float32List?> _rv = List<Float32List?>.filled(cap + 1, null);
  final List<Int32List?> _cv = List<Int32List?>.filled(cap + 1, null);

  // Staging: sprite, centre x, y, scale, colour; and the draw order.
  final Int16List _sp = Int16List(cap);
  final Float32List _x = Float32List(cap);
  final Float32List _y = Float32List(cap);
  final Float32List _s = Float32List(cap);
  final Int32List _col = Int32List(cap);
  final Int16List _order = Int16List(cap);
  int _n = 0;
  int _bgCount = 0;

  final Paint _paint = Paint()..filterQuality = FilterQuality.low;
  final Paint _water = Paint()..color = const Color(0xFF155A70);
  Rect _bgRect = Rect.zero;
  Size _lastSize = Size.zero;

  // This frame's geometry (fields, not closures: nothing allocated per frame).
  double _boatY = 0, _boatMm = 0, _pxPerM = 1, _laneW = 1;

  double _yOf(double mm) => _boatY - (mm - _boatMm) / 1000 * _pxPerM;
  double _laneX(double lane) => _laneW * (lane + .5);

  static const int _white = 0xFFFFFFFF;
  static const int _ghost = 0x59FFFFFF;
  static const int _blink = 0x73FFFFFF;

  void _add(LopetSprite s, double x, double y, double scale, [int colour = _white]) {
    if (_n >= cap) return;
    _sp[_n] = s.index;
    _x[_n] = x;
    _y[_n] = y;
    _s[_n] = scale;
    _col[_n] = colour;
    _n++;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (size != _lastSize) {
      _lastSize = size;
      _bgRect = Offset.zero & size;
    }
    canvas.drawRect(_bgRect, _water);

    final sim = loop.sim;
    final laneW = _laneW = w / 3;
    final s1 = laneW / (LopetAtlas.unit * atlas.density); // one lane unit
    final boatY = _boatY = h * .74;
    final pxPerM = _pxPerM = boatY / mAhead;
    final boatMm = _boatMm = loop.boatMm();
    final scroll = boatMm / 1000 * pxPerM;
    _n = 0;

    // Background (not sorted): water layers and lane foam.
    final rows = (h / laneW).ceil() + 2;
    for (var layer = 0; layer < 2; layer++) {
      final speed = layer == 0 || rolig ? 1.0 : .6;
      final off = (scroll * speed) % laneW;
      final sprite = layer == 0 ? LopetSprite.water0 : LopetSprite.water1;
      for (var row = -1; row < rows; row++) {
        final y = row * laneW + off + laneW / 2;
        for (var col = 0; col < 3; col++) {
          _add(sprite, laneW * (col + .5), y, s1);
        }
      }
    }
    final foamOff = scroll % laneW;
    for (var row = -1; row < rows; row++) {
      final y = row * laneW + foamOff + laneW / 2;
      _add(LopetSprite.foam, laneW, y, s1);
      _add(LopetSprite.foam, 2 * laneW, y, s1);
    }
    _bgCount = _n;

    final fromMm = boatMm - mBehind * 1000, toMm = boatMm + mAhead * 1000;

    // Gates (first lap) with their labels.
    final gateScale = w / atlas.width(LopetSprite.gate);
    for (var k = 0; k < milestones.length && k < 3; k++) {
      final y = _yOf(milestones[k] * 1000.0);
      if (y < -laneW || y > h + laneW) continue;
      _add(LopetSprite.gate, w / 2, y, gateScale);
      _add(LopetSprite.values[LopetSprite.label0.index + k], w / 2, y - laneW * .22, s1);
    }
    // Flags: your best, the rival, the week's best.
    if (flags.bestMm >= 0) _flag(LopetSprite.flagBest, w - laneW * .12, _yOf(flags.bestMm), s1, h, laneW);
    if (flags.rivalMm >= 0) _flag(LopetSprite.flagRival, w - laneW * .32, _yOf(flags.rivalMm), s1, h, laneW);
    if (flags.weekMm >= 0) _flag(LopetSprite.flagWeek, laneW * .12, _yOf(flags.weekMm), s1, h, laneW);

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
          _add(LopetSprite.boye, _laneX((lanes[i] as num).toDouble()), y, s1);
        }
      } else if (t == 'stokk' || t == 'garn') {
        final a = (lanes[0] as num).toDouble(), b = (lanes[lanes.length - 1] as num).toDouble();
        _add(t == 'stokk' ? LopetSprite.stokk : LopetSprite.garn, _laneX((a + b) / 2), y, s1);
        if (t == 'garn') {
          final fy = y - pxPerM * 6; // floats mark it early
          _add(LopetSprite.garnFloat, _laneX(a) - laneW * .3, fy, s1);
          _add(LopetSprite.garnFloat, _laneX((a + b) / 2), fy, s1);
          _add(LopetSprite.garnFloat, _laneX(b) + laneW * .3, fy, s1);
        }
      } else if (t == 'kajakk') {
        if (n >= sim.kNext) _add(LopetSprite.kajakk, _laneX(((r['p'] as Map)['lane'] as num).toDouble()), y, s1);
      } else if (t == 'beffen') {
        final x = sim.beffenXNow(r, d);
        _add(LopetSprite.beffen, x / 3000 * w, y, s1);
      } else if (t == 'make') {
        final p = r['p'] as Map;
        final a = (p['a'] as num).toInt();
        final lane = _laneX((p['lane'] as num).toDouble());
        if (sim.u >= (d - a) * 60) {
          final st = sim.firstAt((d - a) * 60);
          final dived = tick >= st + (p['delay'] as num).toInt();
          _add(dived ? LopetSprite.gull : LopetSprite.gullShadow, lane, y, s1);
        }
      } else if (t == 'wake') {
        _add(LopetSprite.wake, w / 2, y, s1 * 3);
      }
    }
    // Crates in view (a crate picked up is gone).
    var m = sim.nextCrate - 6;
    if (m < 0) m = 0;
    for (var guard = 0; guard < 60; guard++, m++) {
      final d = sim.crateDAt(m);
      if (d < 0 || d > toMm) break;
      if (d < fromMm || sim.crateTaken(m)) continue;
      _add(LopetSprite.crate, _laneX(sim.crateLaneAt(m).toDouble()), _yOf(d.toDouble()), s1);
    }
    // Kajakks on the move.
    for (var i = 0; i < sim.kajakks.length; i++) {
      final k = sim.kajakks[i];
      _add(LopetSprite.kajakk, _laneX(k.lane.toDouble()), _yOf(k.uAt(tick) / 60), s1);
    }
    // The ghost (spec §5.5): translucent, cannot be hit.
    final gm = loop.ghostMm();
    final boatSprite = switch (boat) {
      'vimpel' => LopetSprite.boatVimpel,
      'snekke' => LopetSprite.boatSnekke,
      'egen' => LopetSprite.boatEgen,
      _ => LopetSprite.boatRobaat,
    };
    if (gm >= 0) _add(boatSprite, _laneX(loop.ghostLanePos()), _yOf(gm), s1, _ghost);

    // Far to near.
    _sortObjects();
    // The boat last, with the life ring when the meter is full; blinking in the grace after a hit.
    final bx = _laneX(loop.lanePos());
    final blink = tick < sim.graceUntil && (tick ~/ 6).isEven;
    _addBoat(boatSprite, bx, boatY, s1, blink ? _blink : _white);
    if (sim.hasVest) _addBoat(LopetSprite.ring, bx, boatY, s1, _white);

    _flush(canvas);
  }

  void _flag(LopetSprite s, double x, double y, double scale, double h, double laneW) {
    if (y < -laneW || y > h + laneW) return;
    _add(s, x, y, scale);
  }

  void _addBoat(LopetSprite s, double x, double y, double scale, int colour) {
    _add(s, x, y, scale, colour);
    _order[_n - 1] = _n - 1;
  }

  /// Insertion sort of the object entries by y (small arrays; nothing allocated).
  void _sortObjects() {
    for (var i = 0; i < _n; i++) {
      _order[i] = i;
    }
    for (var i = _bgCount + 1; i < _n; i++) {
      final v = _order[i];
      final key = _y[v];
      var j = i - 1;
      while (j >= _bgCount && _y[_order[j]] > key) {
        _order[j + 1] = _order[j];
        j--;
      }
      _order[j + 1] = v;
    }
  }

  void _flush(Canvas canvas) {
    final rects = atlas.rects;
    for (var i = 0; i < _n; i++) {
      final e = _order[i];
      final sp = _sp[e];
      final l = rects[sp * 4], t = rects[sp * 4 + 1], r = rects[sp * 4 + 2], b = rects[sp * 4 + 3];
      final sc = _s[e];
      _t[i * 4] = sc;
      _t[i * 4 + 1] = 0;
      _t[i * 4 + 2] = _x[e] - sc * (r - l) / 2;
      _t[i * 4 + 3] = _y[e] - sc * (b - t) / 2;
      _r[i * 4] = l;
      _r[i * 4 + 1] = t;
      _r[i * 4 + 2] = r;
      _r[i * 4 + 3] = b;
      _c[i] = _col[e];
    }
    final n = _n;
    final tv = _tv[n] ??= Float32List.sublistView(_t, 0, n * 4);
    final rv = _rv[n] ??= Float32List.sublistView(_r, 0, n * 4);
    final cv = _cv[n] ??= Int32List.sublistView(_c, 0, n);
    canvas.drawRawAtlas(atlas.image, tv, rv, cv, BlendMode.modulate, null, _paint);
  }

  /// Entries drawn in the last frame (tests and the developer overlay).
  int get lastCount => _n;

  @override
  bool shouldRepaint(LopetFieldPainter old) => old.atlas != atlas || old.loop != loop || old.boat != boat || old.rolig != rolig;
}
