import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../game/fjordlopet/sim/engine.dart';

/// Points plan Step 7 (game spec §4, §12): the play field, drawn from the simulation and never feeding back into it.
/// Portrait, seen from above: three lanes of water, the boat in the lower third, the fjord scrolling towards it. Every
/// element differs by shape, not only by colour. Placeholder art in the fjord palette until Step 15's final art.
class LopetPainter extends CustomPainter {
  LopetPainter({required this.sim, required this.boat, required this.milestones, required this.portNavn, this.rolig = false, required Listenable repaint})
      : super(repaint: repaint);

  final FjordSim sim;

  /// robaat | vimpel | snekke | egen
  final String boat;
  final List<int> milestones;
  final List<String> portNavn;

  /// Reduce motion: no wave scroll.
  final bool rolig;

  static const _mAhead = 46.0; // metres visible ahead of the boat
  static const _mBehind = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final boatY = h * .74;
    final pxPerM = boatY / _mAhead;
    final boatMm = sim.u / 60.0;
    double yOf(int mm) => boatY - (mm - boatMm) / 1000.0 * pxPerM;
    double laneX(double lane) => w * (lane + .5) / 3;

    // Water.
    canvas.drawRect(Offset.zero & size, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0E3446), Color(0xFF155A70)]).createShader(Offset.zero & size));
    if (!rolig) {
      final ripple = Paint()..color = Colors.white.withValues(alpha: .05)..strokeWidth = 1.2;
      final phase = (boatMm / 1000.0 * pxPerM) % 38;
      for (var y = -38.0 + phase; y < h; y += 38) {
        for (var x = 12.0 + (y.round() % 2) * 24; x < w; x += 58) {
          canvas.drawLine(Offset(x, y), Offset(x + 16, y), ripple);
        }
      }
    }
    // Lane lines.
    final dash = Paint()..color = Colors.white.withValues(alpha: .14)..strokeWidth = 1.5;
    for (final lx in [w / 3, 2 * w / 3]) {
      final off = (boatMm / 1000.0 * pxPerM) % 30;
      for (var y = -30.0 + off; y < h; y += 30) {
        canvas.drawLine(Offset(lx, y), Offset(lx, y + 14), dash);
      }
    }

    // Gates across the fjord (Bøye 1, Bøye 2, Bryggen) — the first lap only.
    for (var k = 0; k < milestones.length; k++) {
      final y = yOf(milestones[k] * 1000);
      if (y < -20 || y > h + 20) continue;
      final g = Paint()..color = const Color(0xFFF2C14E)..strokeWidth = 4;
      canvas.drawLine(Offset(0, y), Offset(w, y), g);
      for (final x in [8.0, w - 8.0]) {
        canvas.drawCircle(Offset(x, y), 9, Paint()..color = const Color(0xFFE0A32C));
      }
      _tekst(canvas, k < portNavn.length ? portNavn[k] : '${milestones[k]} m', Offset(w / 2, y - 16), 13, const Color(0xFFF7D57E), bold: true);
    }

    // Rows in view.
    final fromMm = (boatMm - _mBehind * 1000).round();
    final toMm = (boatMm + _mAhead * 1000).round();
    var n = math.max(0, sim.nextRow - 4);
    for (var guard = 0; guard < 80; guard++, n++) {
      final (r, d) = sim.rowAt(n);
      if (d > toMm) break;
      if (d < fromMm) continue;
      final y = yOf(d);
      final p = (r['p'] as Map?) ?? const {};
      final t = '${r['t']}';
      final lanes = [for (final l in ((r['l'] as List?) ?? const [])) (l as num).toInt()];
      switch (t) {
        case 'boye':
          for (final l in lanes) {
            _boye(canvas, Offset(laneX(l.toDouble()), y));
          }
        case 'stokk':
          _stokk(canvas, laneX(lanes.first.toDouble()) - w / 7, laneX(lanes.last.toDouble()) + w / 7, y);
        case 'garn':
          _garn(canvas, laneX(lanes.first.toDouble()) - w / 7, laneX(lanes.last.toDouble()) + w / 7, y, pxPerM);
        case 'beffen':
          final x = FjordEngine.beffenX(r, d, sim.tick, sim.firstAt, sim.u);
          _beffen(canvas, Offset(w * x / 3000, y), w, pxPerM);
        case 'make':
          final lane = (p['lane'] as num?)?.toInt() ?? 1;
          final a = (p['a'] as num?)?.toInt() ?? 0;
          if (sim.u >= (d - a) * 60) {
            final st = sim.firstAt((d - a) * 60);
            final dived = sim.tick >= st + ((p['delay'] as num?)?.toInt() ?? 60);
            _make(canvas, Offset(laneX(lane.toDouble()), y), dived);
          }
        case 'wake':
          _wake(canvas, y, w, ((p['w'] as num?)?.toInt() ?? 1));
        default:
          break;
      }
      final c = ((r['c'] as num?)?.toInt() ?? -1);
      if (c >= 0 && d > boatMm) _kasse(canvas, Offset(laneX(c.toDouble()), y - pxPerM * 1.2));
    }
    // Kajakks on the move.
    for (final k in sim.kajakks) {
      final y = yOf(k.uAt(sim.tick) ~/ 60);
      if (y > -30 && y < h + 30) _kajakk(canvas, Offset(laneX(k.lane.toDouble()), y), pxPerM);
    }
    // Kajakks not yet put out: at their row.
    for (var m = sim.kNext, guard = 0; guard < 40; m++, guard++) {
      final (r, d) = sim.rowAt(m);
      if (d > toMm) break;
      if (r['t'] == 'kajakk') {
        final lane = (((r['p'] as Map)['lane']) as num).toInt();
        _kajakk(canvas, Offset(laneX(lane.toDouble()), yOf(d)), pxPerM);
      }
    }

    // The boat, mid lane change when changing.
    final lc = sim.lc;
    final f = ((sim.tick - sim.chStart) / lc).clamp(0.0, 1.0);
    final lanePos = sim.chFrom + (sim.chTo - sim.chFrom) * f;
    final graceBlink = sim.tick < sim.graceUntil && (sim.tick ~/ 6).isEven;
    _baat(canvas, Offset(laneX(lanePos), boatY), pxPerM, graceBlink ? .45 : 1);
  }

  void _boye(Canvas c, Offset o) {
    c.drawCircle(o, 13, Paint()..color = const Color(0xFFE5532D));
    c.drawRect(Rect.fromCenter(center: o, width: 26, height: 6), Paint()..color = Colors.white);
    c.drawCircle(o, 13, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0xFF7A1F0A));
  }

  void _stokk(Canvas c, double x1, double x2, double y) {
    final r = RRect.fromLTRBR(x1, y - 9, x2, y + 9, const Radius.circular(9));
    c.drawRRect(r, Paint()..color = const Color(0xFF8A5A2B));
    for (var x = x1 + 18; x < x2 - 10; x += 26) {
      c.drawLine(Offset(x, y - 6), Offset(x + 8, y + 6), Paint()..color = const Color(0xFF5E3B18)..strokeWidth = 2);
    }
  }

  void _garn(Canvas c, double x1, double x2, double y, double pxPerM) {
    final net = Paint()..color = Colors.white.withValues(alpha: .55)..strokeWidth = 1.4;
    for (var x = x1; x <= x2; x += 10) {
      c.drawLine(Offset(x, y - 7), Offset(x + 7, y + 7), net);
      c.drawLine(Offset(x + 7, y - 7), Offset(x, y + 7), net);
    }
    // Floats mark it early (two rows ahead).
    for (var x = x1; x <= x2; x += (x2 - x1) / 4) {
      c.drawCircle(Offset(x, y - pxPerM * 6), 5, Paint()..color = const Color(0xFFF2C14E));
      c.drawCircle(Offset(x, y), 5, Paint()..color = const Color(0xFFF2C14E));
    }
  }

  void _beffen(Canvas c, Offset o, double w, double pxPerM) {
    final len = w * 900 / 3000;
    final r = RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: len, height: pxPerM * 5), const Radius.circular(10));
    c.drawRRect(r, Paint()..color = Colors.white);
    c.drawRect(Rect.fromCenter(center: o, width: len * .55, height: pxPerM * 2.4), Paint()..color = const Color(0xFFD94B3A));
    c.drawRRect(r, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0xFF1B2A33));
  }

  void _make(Canvas c, Offset o, bool dived) {
    if (!dived) {
      c.drawOval(Rect.fromCenter(center: o, width: 34, height: 14), Paint()..color = Colors.black.withValues(alpha: .35));
      return;
    }
    final p = Path()
      ..moveTo(o.dx - 18, o.dy - 4)
      ..quadraticBezierTo(o.dx - 8, o.dy - 14, o.dx, o.dy - 2)
      ..quadraticBezierTo(o.dx + 8, o.dy - 14, o.dx + 18, o.dy - 4)
      ..lineTo(o.dx, o.dy + 6)
      ..close();
    c.drawPath(p, Paint()..color = Colors.white);
    c.drawPath(p, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = const Color(0xFF34474F));
  }

  void _wake(Canvas c, double y, double w, int dir) {
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..color = Colors.white.withValues(alpha: .7);
    for (var k = 0; k < 3; k++) {
      final path = Path()..moveTo(0, y + k * 7.0);
      for (var x = 0.0; x <= w; x += w / 12) {
        path.lineTo(x, y + k * 7.0 + math.sin(x / 18) * 3);
      }
      c.drawPath(path, p);
    }
    final ax = dir > 0 ? w * .82 : w * .18;
    final head = Path()
      ..moveTo(ax + dir * 14, y - 12)
      ..lineTo(ax - dir * 4, y - 22)
      ..lineTo(ax - dir * 4, y - 2)
      ..close();
    c.drawPath(head, Paint()..color = Colors.white.withValues(alpha: .8));
  }

  void _kajakk(Canvas c, Offset o, double pxPerM) {
    final r = RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: 14, height: pxPerM * 4.2), const Radius.circular(8));
    c.drawRRect(r, Paint()..color = const Color(0xFFF7C948));
    c.drawLine(Offset(o.dx - 16, o.dy), Offset(o.dx + 16, o.dy), Paint()..color = const Color(0xFF2B2B2B)..strokeWidth = 2.5);
  }

  void _kasse(Canvas c, Offset o) {
    final r = Rect.fromCenter(center: o, width: 20, height: 20);
    c.drawRect(r, Paint()..color = const Color(0xFFB07A3E));
    c.drawRect(r, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0xFF6B4520));
    c.drawLine(r.topLeft, r.bottomRight, Paint()..color = const Color(0xFF6B4520)..strokeWidth = 1.5);
    c.drawLine(r.topRight, r.bottomLeft, Paint()..color = const Color(0xFF6B4520)..strokeWidth = 1.5);
  }

  void _baat(Canvas c, Offset o, double pxPerM, double alpha) {
    final len = pxPerM * (boat == 'snekke' || boat == 'egen' ? 6.0 : 4.6);
    final bw = len * .42;
    final hull = Path()
      ..moveTo(o.dx, o.dy - len / 2)
      ..quadraticBezierTo(o.dx + bw / 2, o.dy - len / 6, o.dx + bw / 2, o.dy + len / 2)
      ..lineTo(o.dx - bw / 2, o.dy + len / 2)
      ..quadraticBezierTo(o.dx - bw / 2, o.dy - len / 6, o.dx, o.dy - len / 2)
      ..close();
    final colour = switch (boat) {
      'snekke' => Colors.white,
      'egen' => const Color(0xFF2F7FB8),
      _ => const Color(0xFF9C6A3A),
    };
    c.drawPath(hull, Paint()..color = colour.withValues(alpha: alpha));
    c.drawPath(hull, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0xFF1B2A33).withValues(alpha: alpha));
    if (boat == 'vimpel' || boat == 'egen') {
      c.drawLine(Offset(o.dx, o.dy), Offset(o.dx, o.dy - len * .55), Paint()..color = Colors.white.withValues(alpha: alpha)..strokeWidth = 2);
      final flag = Path()
        ..moveTo(o.dx, o.dy - len * .55)
        ..lineTo(o.dx + bw * .8, o.dy - len * .47)
        ..lineTo(o.dx, o.dy - len * .39)
        ..close();
      c.drawPath(flag, Paint()..color = const Color(0xFFE5532D).withValues(alpha: alpha));
    }
    // Ægil at the oars: a small figure.
    c.drawCircle(Offset(o.dx, o.dy + len * .12), bw * .22, Paint()..color = const Color(0xFF2B4C59).withValues(alpha: alpha));
  }

  void _tekst(Canvas c, String s, Offset centre, double size, Color colour, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: colour, fontSize: size, fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(LopetPainter old) => true;
}
