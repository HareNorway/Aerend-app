import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../game/fjordlopet/render/lopet_atlas9.dart';
import '../../../game/fjordlopet/sim/engine.dart';
import 'lopet_copy.dart';
import 'lopet_data.dart';

/// Design (9) 1:1 plan Step 4: Sjøkortet as the design draws it (`kartSti`, `tegnKart`, `tegnStorKart`).
///
/// The path is the customer's best run sailed again: the run's own inputs through the engine (the design's
/// `opptak`), sampled every fifth tick and on every lane change. The obstacles are the course's rows and crates up to
/// what was sailed; beyond it lies the fog.
class LopetKartSti {
  LopetKartSti._(this.mm, this.lane);

  /// Distance (m) and lane position (0–2) per point.
  final List<double> mm, lane;

  static final Map<String, LopetKartSti> _cache = {};

  static LopetKartSti of(LopetState s, int bestM) {
    final g = s.ghost;
    final key = '${s.courseId}|$bestM|${g?.inputs.length ?? -1}|${g?.perk}';
    final hit = _cache[key];
    if (hit != null) return hit;
    final mm = <double>[0], lane = <double>[1];
    if (g != null && bestM > 0) {
      try {
        final sim = FjordSim(s.course, g.perk);
        var i = 0;
        for (var n = 0; n < 60000 && !sim.done && sim.u / 60000 < bestM; n++) {
          final dirs = <int>[];
          while (i < g.inputs.length && g.inputs[i].tick == sim.tick) {
            dirs.add(g.inputs[i].dir);
            i++;
          }
          sim.stepTick(dirs);
          final moving = sim.tick < sim.chStart + sim.lc;
          if (n % 5 == 0 || moving) {
            mm.add(sim.u / 60000);
            lane.add(sim.lanePosAt(sim.tick));
          }
        }
      } catch (_) {}
    }
    if (_cache.length > 8) _cache.clear();
    return _cache[key] = LopetKartSti._(mm, lane);
  }

  /// The lane at [m] metres (rounded), the design's `laneVed`.
  int laneAt(int m) {
    var l = 1.0;
    for (var i = 0; i < mm.length; i++) {
      if (mm[i] > m) break;
      l = lane[i];
    }
    return l.round();
  }
}

/// Tests set this false (Google Fonts reports a missing font after the test body).
bool lopetKartGoogleFont = true;

TextStyle _f(double size, FontWeight w, Color c) {
  if (lopetKartGoogleFont) {
    try {
      return GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: w, color: c, height: 1);
    } catch (_) {}
  }
  return TextStyle(fontSize: size, fontWeight: w, color: c, height: 1);
}

TextPainter _tp(String s, double size, FontWeight w, Color c) => TextPainter(text: TextSpan(text: s, style: _f(size, w, c)), textDirection: TextDirection.ltr)..layout();

void _text(Canvas g, String s, double size, FontWeight w, Color c, double x, double y, {String align = 'center'}) {
  final t = _tp(s, size, w, c);
  final x0 = align == 'left' ? x : align == 'right' ? x - t.width : x - t.width / 2;
  t.paint(g, Offset(x0, y - t.height / 2));
}

RRect _rr(double x, double y, double w, double h, double r) => RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

/// The design's `skrog`: the færing's outline, length 2.3·2, beam 1.12·2.
Path _skrog(double k) {
  const l = 2.3, b = 1.12;
  return Path()
    ..moveTo(0, -l * k)
    ..cubicTo(b * .95 * k, -l * .78 * k, b * k, -l * .3 * k, b * k, .1 * k)
    ..cubicTo(b * k, l * .52 * k, b * .66 * k, l * .84 * k, 0, l * .92 * k)
    ..cubicTo(-b * .66 * k, l * .84 * k, -b * k, l * .52 * k, -b * k, .1 * k)
    ..cubicTo(-b * k, -l * .3 * k, -b * .95 * k, -l * .78 * k, 0, -l * k)
    ..close();
}

/// The boat marker on the chart (hull, inner hull, a seat), drawn at (0, 0) pointing up.
void _baat(Canvas g, double scale) {
  g.save();
  g.scale(scale);
  g.save();
  g.translate(.3, .4);
  g.drawPath(_skrog(1), Paint()..color = const Color(0x5904121A));
  g.restore();
  g.drawPath(_skrog(1), Paint()..color = const Color(0xFFB07A45));
  g.drawPath(_skrog(1), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = .3
    ..color = const Color(0xFF3A2412));
  g.drawPath(_skrog(.78), Paint()..color = const Color(0xFF6E4526));
  g.drawCircle(const Offset(0, .15), .62, Paint()..color = const Color(0xFF1E4F5C));
  g.restore();
}

int _imul(int a, int b) => ((a.toUnsigned(32) * b) & 0xFFFFFFFF);

/// One obstacle row of the course for the charts: type, lanes a–b, distance (m).
class _Ting {
  const _Ting(this.t, this.a, this.b, this.m);
  final String t;
  final int a, b;
  final double m;
}

List<_Ting> _ting(LopetState s, double toM) {
  final out = <_Ting>[];
  for (final r in (s.course['rows'] as List? ?? const [])) {
    if (r is! Map) continue;
    final m = ((r['d'] as num?) ?? 0) / 1000;
    if (m > toM) break;
    final t = '${r['t']}';
    final lanes = [for (final l in ((r['l'] as List?) ?? const [])) (l as num).toInt()];
    final pl = ((r['p'] as Map?)?['lane'] as num?)?.toInt();
    if (t == 'boye') {
      for (final l in lanes) {
        out.add(_Ting(t, l, l, m));
      }
    } else if (t == 'stokk' || t == 'garn') {
      if (lanes.isEmpty) continue;
      out.add(_Ting(t, lanes.reduce(math.min), lanes.reduce(math.max), m));
    } else if (t == 'kajakk' || t == 'make') {
      out.add(_Ting(t, pl ?? 1, pl ?? 1, m));
    } else if (t == 'beffen') {
      out.add(_Ting(t, 0, 2, m));
    }
  }
  for (final c in (s.course['crates'] as List? ?? const [])) {
    if (c is! Map) continue;
    final m = ((c['d'] as num?) ?? 0) / 1000;
    if (m > toM) break;
    final l = (c['l'] as num?)?.toInt() ?? 1;
    out.add(_Ting('kasse', l, l, m));
  }
  return out;
}

/// The quay's chart card (horizontal, 98 px high): the design's `tegnKart`. [stoppM]: the end card's cross.
class LopetKart9Maler extends CustomPainter {
  LopetKart9Maler({required this.s, required this.bestM, this.stoppM, this.stoppLane});

  final LopetState s;
  final int bestM;
  final int? stoppM;
  final int? stoppLane;

  @override
  void paint(Canvas g, Size size) {
    final w = size.width, h = size.height, best = bestM.toDouble();
    final u = (s.weekBestM ?? 0).toDouble();
    const vis = 900.0;
    final a0 = best + 260 > 1150 ? math.max(0.0, ((best + 260 - vis) / 50).ceil() * 50.0) : 0.0;
    final span = a0 > 0 ? a0 + vis : 1150.0;
    double x(double mm) => 10 + (mm - a0) / (span - a0) * (w - 20);
    bool inn(double mm) => mm >= a0 - 5 && mm <= span;
    const top = 20.0;
    final bot = h - 15;
    double ly(num l) => top + 10 + (bot - top - 20) * l / 2;

    g.drawRect(Offset.zero & size, Paint()
      ..shader = ui.Gradient.linear(const Offset(0, top), Offset(0, bot), const [Color(0xFF134551), Color(0xFF1B5D6B), Color(0xFF134551)], const [0, .5, 1]));
    for (final side in [0, 1]) {
      final y0 = side == 1 ? bot : 0.0, hh = side == 1 ? h - bot : top;
      g.drawRect(Rect.fromLTWH(0, y0, w, hh), Paint()
        ..shader = ui.Gradient.linear(Offset(0, y0), Offset(0, y0 + hh), side == 1 ? const [Color(0xFF3D5C49), Color(0xFF22382D)] : const [Color(0xFF22382D), Color(0xFF3D5C49)]));
      g.drawRect(Rect.fromLTWH(0, side == 1 ? bot : top - 2, w, 2), Paint()..color = const Color(0xBFECDCB2));
    }
    final faint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x0DFFFFFF);
    for (var k = 0; k < 4; k++) {
      final p = Path();
      for (var xx = 0.0; xx <= w; xx += 6) {
        final yy = top + 5 + k * (bot - top - 10) / 3 + math.sin(xx * .035 + k * 1.9) * 2.5;
        xx == 0 ? p.moveTo(xx, yy) : p.lineTo(xx, yy);
      }
      g.drawPath(p, faint);
    }
    final dash = Paint()
      ..strokeWidth = 1
      ..color = const Color(0x24FFFFFF);
    for (final yy in [(ly(0) + ly(1)) / 2, (ly(1) + ly(2)) / 2]) {
      for (var xx = 0.0; xx < w; xx += 8) {
        g.drawLine(Offset(xx, yy), Offset(xx + 3, yy), dash);
      }
    }
    for (final q in _ting(s, best + 12)) {
      if (q.m < a0 - 8) continue;
      final xx = x(q.m), yy = ly(q.a);
      switch (q.t) {
        case 'boye':
          g.drawCircle(Offset(xx, yy), 3.1, Paint()..color = const Color(0xFFF5F3EF));
          g.drawArc(Rect.fromCircle(center: Offset(xx, yy), radius: 3.1), math.pi * .75, math.pi, true, Paint()..color = const Color(0xFFDF4428));
          g.drawCircle(Offset(xx, yy), .9, Paint()..color = const Color(0xFF23201D));
        case 'stokk':
          final y0 = ly(q.a) - 4, y1 = ly(q.b) + 4;
          g.drawRRect(_rr(xx - 2, y0, 4, y1 - y0, 2), Paint()..color = const Color(0xFFA9743F));
          g.drawRRect(_rr(xx - 2, y0, 4, y1 - y0, 2), Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = .8
            ..color = const Color(0xFF3A2412));
        case 'garn':
          final y0 = ly(q.a) - 4, y1 = ly(q.b) + 4;
          g.drawLine(Offset(xx, y0), Offset(xx, y1), Paint()
            ..strokeWidth = 1
            ..color = const Color(0xA6EFE6D2));
          for (var yy2 = y0; yy2 <= y1 + .1; yy2 += 4.6) {
            g.drawCircle(Offset(xx, yy2), 1.4, Paint()..color = const Color(0xFFF2C14E));
          }
        case 'kajakk':
          g.drawOval(Rect.fromCenter(center: Offset(xx + 3, yy), width: 10, height: 3.6), Paint()..color = const Color(0xFFF2B93B));
          g.drawCircle(Offset(xx + 3, yy), .9, Paint()..color = const Color(0xFF23201D));
        case 'beffen':
          g.drawRRect(_rr(xx - 3.2, ly(0) - 6, 6.4, ly(2) - ly(0) + 12, 3), Paint()..color = const Color(0xFFF5F3EF));
          g.drawRRect(_rr(xx - 1.6, ly(0) - 2, 3.2, ly(2) - ly(0) + 4, 1.5), Paint()..color = const Color(0xFF2A6272));
        case 'make':
          g.drawPath(Path()
            ..moveTo(xx - 3.5, yy - 2)
            ..quadraticBezierTo(xx - 1.5, yy - 3.6, xx, yy)
            ..quadraticBezierTo(xx + 1.5, yy - 3.6, xx + 3.5, yy - 2), Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.3
            ..strokeCap = StrokeCap.round
            ..color = Colors.white);
        case 'kasse':
          g.drawRect(Rect.fromLTWH(xx - 2, yy - 2, 4, 4), Paint()..color = const Color(0xFF5CE0B8));
          g.drawRect(Rect.fromLTWH(xx - 2, yy - 2, 4, 4), Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = .8
            ..color = const Color(0xFF0F3540));
      }
    }
    // the best run's path (a glow, then the line), lane changes as soft steps
    final sti = LopetKartSti.of(s, bestM);
    var l0 = 1;
    for (var i = 0; i < sti.mm.length && sti.mm[i] <= a0; i++) {
      l0 = sti.lane[i].round();
    }
    final seg = <(double, int)>[(a0, l0)];
    for (var i = 0; i < sti.mm.length; i++) {
      if (sti.mm[i] <= a0) continue;
      final ln = sti.lane[i].round();
      if (ln != seg.last.$2) seg.add((sti.mm[i], ln));
    }
    if (best > 0) {
      for (final (lw, c) in [(7.0, const Color(0x335CE0B8)), (2.2, const Color(0xFF5CE0B8))]) {
        final p = Path()..moveTo(x(a0), ly(l0));
        for (var i = 1; i < seg.length; i++) {
          final xx = x(seg[i].$1);
          final r = math.max(.5, math.min(4.5, math.min((xx - x(seg[i - 1].$1)) / 2, i + 1 < seg.length ? (x(seg[i + 1].$1) - xx) / 2 : 4.5)));
          final y0 = ly(seg[i - 1].$2), y1 = ly(seg[i].$2);
          p.lineTo(xx - r, y0);
          p.cubicTo(xx, y0, xx, y1, xx + r, y1);
        }
        p.lineTo(x(best), ly(seg.last.$2));
        g.drawPath(p, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = lw
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = c);
      }
    }
    if (a0 == 0) {
      g.drawCircle(Offset(x(0), ly(1)), 3.4, Paint()..color = const Color(0xFFF5F3EF));
      g.drawCircle(Offset(x(0), ly(1)), 3.4, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFF5CE0B8));
    } else {
      g.drawRect(Rect.fromLTRB(0, top, 34, bot), Paint()..shader = ui.Gradient.linear(Offset.zero, const Offset(34, 0), const [Color(0xF2134551), Color(0x00134551)]));
    }
    // the fog over what is not sailed
    final xb = x(best), fy0 = top - 2, fy1 = bot + 2;
    const fc = Color(0xF2ACC5CD);
    g.drawRect(Rect.fromLTRB(xb, fy0, xb + 44, fy1), Paint()..shader = ui.Gradient.linear(Offset(xb, 0), Offset(xb + 44, 0), const [Color(0x00ACC5CD), fc]));
    g.drawRect(Rect.fromLTRB(xb + 44, fy0, w, fy1), Paint()..color = fc);
    for (var i = 0; i < 18; i++) {
      final hs = _imul(i + 13, 0x9E3779B1);
      final cx = xb + 16 + (hs % 1000) / 1000 * math.max(10, w - xb), cy = fy0 + ((hs >> 10) % 1000) / 1000 * (fy1 - fy0), r = 12.0 + (hs >> 20) % 16;
      g.drawRect(Rect.fromLTWH(cx - r, cy - r, r * 2, r * 2), Paint()..shader = ui.Gradient.radial(Offset(cx, cy), r, const [Color(0x99EEF6F8), Color(0x00EEF6F8)]));
    }
    if (w - xb > 170) _text(g, LopetCopy.take, 10, FontWeight.w700, const Color(0xFF3B5D66), (xb + 44 + w) / 2, ly(1) + 14);
    // the gates: dashed line and a chip with name and points, ticked when taken
    final pts = [s.rewards['buoy1'], s.rewards['buoy2'], s.rewards['quay']].map((v) => (v as num?)?.toInt() ?? 0).toList();
    var hoyre = -1e9;
    final ms = s.milestones;
    for (var k = 0; k < ms.length && k < 3; k++) {
      final m = ms[k].toDouble();
      if (!inn(m)) continue;
      final xx = x(m), ok = best >= m, c = k == 2 ? const Color(0xFFF2C14E) : const Color(0xFF7FF0CB);
      final dp = Paint()
        ..strokeWidth = 1.3
        ..color = ok ? c : const Color(0xB31E4F5C);
      for (var yy = top; yy < bot; yy += 6) {
        g.drawLine(Offset(xx, yy), Offset(xx, math.min(bot, yy + 3)), dp);
      }
      final tx = '${LopetCopy.porter[k]} +${pts[k]}';
      final tw = _tp(tx, 9, FontWeight.w800, c).width + (ok ? 22 : 12);
      final px = math.min(w - tw / 2 - 2, math.max(tw / 2 + 2, xx));
      if (px - tw / 2 < hoyre + 4) continue;
      hoyre = px + tw / 2;
      g.drawRRect(_rr(px - tw / 2, 3, tw, 14, 7), Paint()..color = ok ? c : const Color(0xF00A2128));
      if (!ok) {
        g.drawRRect(_rr(px - tw / 2, 3, tw, 14, 7), Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = c);
      }
      _text(g, tx, 9, FontWeight.w800, ok ? const Color(0xFF0F3540) : c, px + (ok ? 5 : 0), 10.5);
      if (ok) {
        g.drawPath(Path()
          ..moveTo(px - tw / 2 + 6, 10.5)
          ..lineTo(px - tw / 2 + 8.5, 13)
          ..lineTo(px - tw / 2 + 12.5, 8), Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF0F3540));
      }
    }
    // the week's best: a gold flag, or an arrow at the right edge when it lies beyond the chart
    if (u >= a0 && u > 0) {
      if (u <= span) {
        final xu = x(u);
        g.drawLine(Offset(xu, top + 2), Offset(xu, bot), Paint()
          ..strokeWidth = 2
          ..color = const Color(0xFFF2C14E));
        g.drawPath(Path()
          ..moveTo(xu, top + 2)
          ..lineTo(xu - 9, top + 6)
          ..lineTo(xu, top + 10)
          ..close(), Paint()..color = const Color(0xFFF2C14E));
      } else {
        final yy = ly(1);
        g.drawPath(Path()
          ..moveTo(w - 3, yy)
          ..lineTo(w - 11, yy - 6)
          ..lineTo(w - 11, yy + 6)
          ..close(), Paint()..color = const Color(0xFFC9971F));
      }
    }
    final rv = s.rival;
    if (rv != null && !rv.me && inn(rv.distanceM.toDouble())) {
      final xr = x(rv.distanceM.toDouble());
      g.drawLine(Offset(xr, top + 2), Offset(xr, bot), Paint()
        ..strokeWidth = 1.6
        ..color = const Color(0xFFF5F3EF));
      g.drawPath(Path()
        ..moveTo(xr, top + 2)
        ..lineTo(xr + 8, top + 5.5)
        ..lineTo(xr, top + 9)
        ..close(), Paint()..color = const Color(0xFFF5F3EF));
    }
    // the boat at the best distance, lying on its side
    if (best > 0) {
      g.save();
      g.translate(xb, ly(seg.last.$2));
      g.rotate(math.pi / 2);
      _baat(g, 3.6);
      g.restore();
    }
    // the metre scale under the chart
    final stl = a0 > 0 ? 200 : 500;
    for (var mm = ((a0 + 1) / 100).ceil() * 100; mm < span; mm += 100) {
      final xx = x(mm.toDouble());
      if (xx < 8) continue;
      g.drawRect(Rect.fromLTWH(xx - .5, bot + 2, 1, mm % stl != 0 ? 2.5 : 4), Paint()..color = const Color(0xB3ECF4F6));
      if (mm % stl == 0 && (xx - xb).abs() > 26 && xx > 22) _text(g, '${LopetCopy.tallTekst(mm)} m', 8, FontWeight.w700, const Color(0xB3ECF4F6), xx, bot + 10);
    }
    final st = stoppM;
    if (st != null && st < best - 3 && inn(st.toDouble())) {
      final xx = x(st.toDouble()), yy = ly(stoppLane ?? sti.laneAt(st));
      g.drawCircle(Offset(xx, yy), 7.5, Paint()..color = const Color(0xFF23201D));
      final wp = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFF5F3EF);
      g.drawCircle(Offset(xx, yy), 7.5, wp);
      g.drawLine(Offset(xx - 3, yy - 3), Offset(xx + 3, yy + 3), wp);
      g.drawLine(Offset(xx + 3, yy - 3), Offset(xx - 3, yy + 3), wp);
    }
  }

  @override
  bool shouldRepaint(LopetKart9Maler old) => old.bestM != bestM || old.stoppM != stoppM || old.s != s;
}

/// Sjøkortet in full screen, vertical (the design's `tegnStorKart`): the quay at the bottom, the landmarks by name,
/// the gates, a cross where each of this week's runs stopped, the flags, and fog over what is not sailed. Its height
/// follows the distances ([heightFor]); the screen scrolls it so the best distance sits at 58 %.
class LopetStorKart9Maler extends CustomPainter {
  LopetStorKart9Maler({required this.s, required this.bestM, this.atlas});

  final LopetState s;
  final int bestM;
  final LopetAtlas9? atlas;

  static double spanOf(LopetState s, int bestM) => math.max(math.max((s.weekBestM ?? 0).toDouble(), bestM.toDouble()), (s.rival?.distanceM ?? 0).toDouble()) + 150;

  /// The canvas height for a width: 1 px per … as the design (`(H − 130) / span` px per m, at least the screen).
  static double heightFor(LopetState s, int bestM, double screenH) => math.max(screenH, spanOf(s, bestM) * 1.6 + 130);

  /// Where the best distance sits on the canvas (the screen scrolls to it).
  static double bestY(LopetState s, int bestM, double h) => h - 76 - bestM * (h - 130) / spanOf(s, bestM);

  @override
  void paint(Canvas g, Size size) {
    final w = size.width, hgt = size.height, best = bestM.toDouble();
    final u = (s.weekBestM ?? 0).toDouble();
    final rv = s.rival != null && !s.rival!.me ? s.rival : null;
    final span = spanOf(s, bestM), pxm = (hgt - 130) / span;
    double y(double mm) => hgt - 76 - mm * pxm;
    final bw = (w * .18).roundToDouble();
    final lx = [w * .33, w * .5, w * .67];
    double lane(double l) => lx[0] + (lx[1] - lx[0]) * l;
    double kant(int side, double yy) => bw + math.sin(yy * .021 + side * 2) * 5 + math.sin(yy * .057 + side) * 3;

    g.drawRect(Offset.zero & size, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(w, 0), const [Color(0xFF134551), Color(0xFF1C6070), Color(0xFF134551)], const [0, .5, 1]));
    final faint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x0DFFFFFF);
    for (var yy = 30.0; yy < hgt; yy += 46) {
      final p = Path();
      for (var xx = bw; xx <= w - bw; xx += 8) {
        final y2 = yy + math.sin(xx * .05 + yy) * 2.5;
        xx == bw ? p.moveTo(xx, y2) : p.lineTo(xx, y2);
      }
      g.drawPath(p, faint);
    }
    for (final side in [0, 1]) {
      final p = Path()..moveTo(side == 1 ? w : 0, -10);
      final edge = Path();
      for (var yy = -10.0; yy <= hgt + 10; yy += 10) {
        final e = kant(side, yy), xx = side == 1 ? w - e : e;
        p.lineTo(xx, yy);
        yy == -10 ? edge.moveTo(xx, yy) : edge.lineTo(xx, yy);
      }
      p
        ..lineTo(side == 1 ? w : 0, hgt + 10)
        ..close();
      g.drawPath(p, Paint()..shader = ui.Gradient.linear(Offset(side == 1 ? w : 0, 0), Offset(side == 1 ? w - bw : bw, 0), const [Color(0xFF22382D), Color(0xFF3D5C49)]));
      g.drawPath(edge, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xCCECDCB2));
    }
    final y0 = y(0);
    g.drawRect(Rect.fromLTWH(0, y0 + 18, w, hgt), Paint()..color = const Color(0xFF4A3B2E));
    g.drawRect(Rect.fromLTWH(0, y0 + 18, w, 2.5), Paint()..color = const Color(0xFF6B5644));
    for (var xx = 12.0; xx < w; xx += 38) {
      g.drawRect(Rect.fromLTWH(xx, y0 + 20.5, 5, 10), Paint()..color = const Color(0xFF2E241B));
    }
    _text(g, LopetCopy.kartStart, 11, FontWeight.w800, const Color(0xFFE7D9BF), w / 2, y0 + 44);
    final dash = Paint()
      ..strokeWidth = 1
      ..color = const Color(0x1FFFFFFF);
    for (final xx in [(lx[0] + lx[1]) / 2, (lx[1] + lx[2]) / 2]) {
      for (var yy = y0 + 16; yy > 0; yy -= 11) {
        g.drawLine(Offset(xx, yy), Offset(xx, yy - 4), dash);
      }
    }
    for (var mm = 100; mm < span; mm += 100) {
      final yy = y(mm.toDouble());
      g.drawRect(Rect.fromLTWH(0, yy - .5, mm % 500 != 0 ? 5 : 9, 1), Paint()..color = const Color(0x9EECF4F6));
      _text(g, '${LopetCopy.tallTekst(mm)} m', 9, FontWeight.w700, const Color(0x9EECF4F6), 3, yy - 7, align: 'left');
    }
    for (final q in _ting(s, best + 15)) {
      final yy = y(q.m), xx = lx[math.min(2, q.a)];
      switch (q.t) {
        case 'boye':
          g.drawCircle(Offset(xx, yy), 4.6, Paint()..color = const Color(0xFFF5F3EF));
          g.drawArc(Rect.fromCircle(center: Offset(xx, yy), radius: 4.6), math.pi * .75, math.pi, true, Paint()..color = const Color(0xFFDF4428));
          g.drawCircle(Offset(xx, yy), 1.3, Paint()..color = const Color(0xFF23201D));
        case 'stokk':
          final a = lx[q.a] - 9, b = lx[q.b] + 9;
          g.drawRRect(_rr(a, yy - 3, b - a, 6, 3), Paint()..color = const Color(0xFFA9743F));
          g.drawRRect(_rr(a, yy - 3, b - a, 6, 3), Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = const Color(0xFF3A2412));
        case 'garn':
          final a = lx[q.a] - 9, b = lx[q.b] + 9;
          g.drawLine(Offset(a, yy), Offset(b, yy), Paint()
            ..strokeWidth = 1.2
            ..color = const Color(0xB3EFE6D2));
          for (var k = 0; k <= 7; k++) {
            g.drawCircle(Offset(a + (b - a) * k / 7, yy), 2, Paint()..color = const Color(0xFFF2C14E));
          }
        case 'kajakk':
          g.drawOval(Rect.fromCenter(center: Offset(xx, yy - 4), width: 5.2, height: 15), Paint()..color = const Color(0xFFF2B93B));
          g.drawCircle(Offset(xx, yy - 4), 1.2, Paint()..color = const Color(0xFF23201D));
        case 'beffen':
          g.drawRRect(_rr(lx[0] - 11, yy - 5, lx[2] - lx[0] + 22, 10, 5), Paint()..color = const Color(0xE6F5F3EF));
          g.drawRRect(_rr(lx[0] - 6, yy - 2, lx[2] - lx[0] + 12, 4, 2), Paint()..color = const Color(0xFF2A6272));
        case 'make':
          g.drawPath(Path()
            ..moveTo(xx - 5, yy - 1)
            ..quadraticBezierTo(xx - 2, yy - 4.5, xx, yy + 1)
            ..quadraticBezierTo(xx + 2, yy - 4.5, xx + 5, yy - 1), Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round
            ..color = Colors.white);
        case 'kasse':
          g.drawRect(Rect.fromLTWH(xx - 2.6, yy - 2.6, 5.2, 5.2), Paint()..color = const Color(0xFF5CE0B8));
          g.drawRect(Rect.fromLTWH(xx - 2.6, yy - 2.6, 5.2, 5.2), Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = .9
            ..color = const Color(0xFF0F3540));
      }
    }
    final sti = LopetKartSti.of(s, bestM);
    if (best > 0) {
      for (final (lw, c) in [(8.0, const Color(0x335CE0B8)), (2.6, const Color(0xFF5CE0B8))]) {
        final p = Path()..moveTo(lane(1), y0);
        for (var i = 0; i < sti.mm.length; i++) {
          p.lineTo(lane(sti.lane[i]), y(sti.mm[i]));
        }
        g.drawPath(p, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = lw
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = c);
      }
    }
    // landmarks: the design's sprite and the name tag
    final at = atlas;
    for (final lm in s.landmarks) {
      final m = (((lm['d'] as num?) ?? 0) / 1000).toDouble();
      if (m > best + 25) continue;
      final id = const {'naust': 0, 'kran': 1, 'fyr': 2, 'akvariet': 3, 'festningen': 4, 'seilskute': 5, 'verftet': 6, 'sjobad': 7}['${lm['k']}'];
      if (id == null) continue;
      final side = ((lm['s'] as num?)?.toInt() ?? -1) < 0 ? 0 : 1;
      final yy = y(m);
      const sw = 41.0, sh = 69.0;
      if (at != null) {
        final i = at.id('lm$id');
        if (i >= 0) {
          g.save();
          if (side == 1) {
            g.translate(w, 0);
            g.scale(-1, 1);
          }
          g.drawImageRect(at.image, Rect.fromLTRB(at.src[i * 4], at.src[i * 4 + 1], at.src[i * 4 + 2], at.src[i * 4 + 3]), Rect.fromLTWH(3, yy - 63, sw, sh), Paint()..filterQuality = FilterQuality.medium);
          g.restore();
        }
      }
      var navn = s.landmarkName('${lm['k']}') ?? '';
      if (navn.isNotEmpty) navn = navn[0].toUpperCase() + navn.substring(1);
      final tw = _tp(navn, 11, FontWeight.w800, Colors.white).width + 14;
      final cx = side == 1 ? w - 3 - sw / 2 : 3 + sw / 2, px = math.max(tw / 2 + 2, math.min(w - tw / 2 - 2, cx));
      g.drawRRect(_rr(px - tw / 2, yy + 9, tw, 18, 9), Paint()..color = const Color(0xE60A2128));
      g.drawRRect(_rr(px - tw / 2, yy + 9, tw, 18, 9), Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x59F5F3EF));
      _text(g, navn, 11, FontWeight.w800, const Color(0xFFF5F3EF), px, yy + 18.5);
    }
    // a cross where each of this week's runs stopped, «Her gikk det galt» where there is room
    // Only runs a hit ended (end_cause is set for a collision; the door or the app ending a run leaves it empty).
    final stopp = [for (final r in s.myRuns) if (r.distanceM <= best + 1 && r.endCause != null) r.distanceM]..sort();
    var sist = -1e9;
    for (final m in stopp) {
      final l = sti.laneAt(m), xx = lane(l.toDouble()), yy = y(m.toDouble());
      g.drawCircle(Offset(xx, yy), 8, Paint()..color = const Color(0xFF23201D));
      final wp = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFF5F3EF);
      g.drawCircle(Offset(xx, yy), 8, wp);
      g.drawLine(Offset(xx - 3.2, yy - 3.2), Offset(xx + 3.2, yy + 3.2), wp);
      g.drawLine(Offset(xx + 3.2, yy - 3.2), Offset(xx - 3.2, yy + 3.2), wp);
      if ((m - best).abs() > 4 && (yy - sist).abs() > 26) {
        sist = yy;
        final tx = LopetCopy.herGikkDetGalt, tw = _tp(tx, 10.5, FontWeight.w800, Colors.white).width + 14, px = l <= 1 ? xx + 12 : xx - 12 - tw;
        g.drawRRect(_rr(px, yy - 9, tw, 18, 9), Paint()..color = const Color(0xEB23201D));
        _text(g, tx, 10.5, FontWeight.w800, const Color(0xFFF5F3EF), px + 7, yy + .5, align: 'left');
      }
    }
    // the fog
    final yb = y(best);
    const fc = Color(0xF7ACC5CD);
    g.drawRect(Rect.fromLTWH(0, yb - 64, w, 60), Paint()..shader = ui.Gradient.linear(Offset(0, yb - 4), Offset(0, yb - 64), const [Color(0x00ACC5CD), fc]));
    g.drawRect(Rect.fromLTWH(0, 0, w, math.max(0, yb - 63)), Paint()..color = fc);
    for (var i = 0; i < 46; i++) {
      final hs = _imul(i + 13, 0x9E3779B1);
      final cx = (hs % 1000) / 1000 * w, cy = ((hs >> 10) % 1000) / 1000 * math.max(0, yb - 50), r = 24.0 + (hs >> 20) % 30;
      g.drawRect(Rect.fromLTWH(cx - r, cy - r, r * 2, r * 2), Paint()..shader = ui.Gradient.radial(Offset(cx, cy), r, const [Color(0x99EEF6F8), Color(0x00EEF6F8)]));
    }
    _text(g, LopetCopy.take, 12, FontWeight.w700, const Color(0xFF3B5D66), w / 2, yb - 128);
    // the gates
    final pts = [s.rewards['buoy1'], s.rewards['buoy2'], s.rewards['quay']].map((v) => (v as num?)?.toInt() ?? 0).toList();
    final ms = s.milestones;
    for (var k = 0; k < ms.length && k < 3; k++) {
      final yy = y(ms[k].toDouble()), ok = best >= ms[k], cc = k == 2 ? const Color(0xFFF2C14E) : const Color(0xFF7FF0CB);
      final dp = Paint()
        ..strokeWidth = 1.5
        ..color = ok ? cc : const Color(0xBF1E4F5C);
      for (var xx = bw - 4; xx < w - bw + 4; xx += 8) {
        g.drawLine(Offset(xx, yy), Offset(math.min(w - bw + 4, xx + 4), yy), dp);
      }
      final tx = LopetCopy.portPoeng(LopetCopy.porter[k], pts[k]);
      final tw = _tp(tx, 11, FontWeight.w800, cc).width + (ok ? 30 : 18);
      g.drawRRect(_rr(w / 2 - tw / 2, yy - 10, tw, 20, 10), Paint()..color = ok ? cc : const Color(0xF00A2128));
      if (!ok) {
        g.drawRRect(_rr(w / 2 - tw / 2, yy - 10, tw, 20, 10), Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = cc);
      }
      _text(g, tx, 11, FontWeight.w800, ok ? const Color(0xFF0F3540) : cc, w / 2 + (ok ? 6 : 0), yy + .5);
      if (ok) {
        final a = w / 2 - tw / 2 + 9;
        g.drawPath(Path()
          ..moveTo(a, yy)
          ..lineTo(a + 3, yy + 3)
          ..lineTo(a + 8, yy - 3), Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF0F3540));
      }
    }
    void flagg(double mm, String tx, Color cc, bool hoyre) {
      final yy = y(mm), xx = hoyre ? w - kant(1, yy) + 2 : kant(0, yy) - 2;
      final dp = Paint()
        ..strokeWidth = 1.5
        ..color = cc.withValues(alpha: .55);
      for (var x2 = bw; x2 < w - bw; x2 += 9) {
        g.drawLine(Offset(x2, yy), Offset(math.min(w - bw, x2 + 3), yy), dp);
      }
      g.drawLine(Offset(xx, yy), Offset(xx, yy - 30), Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFF5F3EF));
      g.drawPath(Path()
        ..moveTo(xx, yy - 30)
        ..lineTo(xx + (hoyre ? -20 : 20), yy - 24.5)
        ..lineTo(xx, yy - 19)
        ..close(), Paint()..color = cc);
      final tw = _tp(tx, 11, FontWeight.w800, cc).width + 14, px = hoyre ? xx - 24 - tw : xx + 24;
      g.drawRRect(_rr(px, yy - 34, tw, 19, 9.5), Paint()..color = const Color(0xEB0A2128));
      g.drawRRect(_rr(px, yy - 34, tw, 19, 9.5), Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = cc);
      _text(g, tx, 11, FontWeight.w800, cc, px + 7, yy - 24, align: 'left');
    }

    if (u > 0) flagg(u, '${LopetCopy.ukensBeste} · ${LopetCopy.tallTekst(u.round())} m', const Color(0xFFF2C14E), true);
    if (rv != null) flagg(rv.distanceM.toDouble(), '${rv.name} · ${LopetCopy.tallTekst(rv.distanceM)} m', const Color(0xFFF5F3EF), true);
    if (best > 0) {
      flagg(best, '${LopetCopy.dinBeste} · ${LopetCopy.tallTekst(bestM)} m', const Color(0xFF5CE0B8), false);
      g.save();
      g.translate(lane(sti.lane.isEmpty ? 1 : sti.lane.last), yb);
      _baat(g, 4.4);
      g.restore();
    }
  }

  @override
  bool shouldRepaint(LopetStorKart9Maler old) => old.bestM != bestM || old.s != s || old.atlas != atlas;
}
