import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Fjordløpet v1.3 plan Step 5 (spec v1.3 §12.2, plan D10): the sprite atlas — every figure the play field draws, in one
/// image per session, so the painter makes one `drawRawAtlas` call per frame.
///
/// Step 5 draws placeholder figures in vector code at session open (before «Sett seil» can be tapped, so nothing
/// decodes during a run); Step 9 replaces them with the atlas built from the prototype's figures. Sizes are in lane
/// units (one lane = [unit] px at 1×), multiplied by the density (2× or 3×); 2 px of padding around each figure; at most
/// 2048 px wide. Every obstacle differs by shape, not only by colour (spec §12 accessibility).
enum LopetSprite {
  water0,
  water1,
  foam,
  boye,
  stokk,
  garn,
  garnFloat,
  kajakk,
  beffen,
  gull,
  gullShadow,
  wake,
  crate,
  boatRobaat,
  boatVimpel,
  boatSnekke,
  boatEgen,
  ring,
  gate,
  flagBest,
  flagWeek,
  flagRival,
  spray,
  label0,
  label1,
  label2,
}

class LopetAtlas {
  LopetAtlas._(this.image, this.rects, this.density);

  static const double unit = 100;
  static const double pad = 2;
  static const double maxWidth = 2048;

  final ui.Image image;

  /// Per sprite: left, top, right, bottom in the atlas (px), in [LopetSprite] order.
  final Float32List rects;
  final double density;

  double width(LopetSprite s) => rects[s.index * 4 + 2] - rects[s.index * 4];
  double height(LopetSprite s) => rects[s.index * 4 + 3] - rects[s.index * 4 + 1];

  /// Sizes in lane units.
  static const Map<LopetSprite, (double, double)> sizes = {
    LopetSprite.water0: (1, 1),
    LopetSprite.water1: (1, 1),
    LopetSprite.foam: (.06, 1),
    LopetSprite.boye: (.32, .32),
    LopetSprite.stokk: (1.9, .22),
    LopetSprite.garn: (1.9, .2),
    LopetSprite.garnFloat: (.12, .12),
    LopetSprite.kajakk: (.18, .5),
    LopetSprite.beffen: (.9, .42),
    LopetSprite.gull: (.4, .2),
    LopetSprite.gullShadow: (.4, .16),
    LopetSprite.wake: (1, .3),
    LopetSprite.crate: (.24, .24),
    LopetSprite.boatRobaat: (.42, .7),
    LopetSprite.boatVimpel: (.42, .7),
    LopetSprite.boatSnekke: (.46, .86),
    LopetSprite.boatEgen: (.46, .86),
    LopetSprite.ring: (.66, .66),
    LopetSprite.gate: (3, .12),
    LopetSprite.flagBest: (.22, .32),
    LopetSprite.flagWeek: (.22, .32),
    LopetSprite.flagRival: (.22, .32),
    LopetSprite.spray: (.08, .08),
    LopetSprite.label0: (1.4, .24),
    LopetSprite.label1: (1.4, .24),
    LopetSprite.label2: (1.4, .24),
  };

  /// Builds the atlas at [density] (2 or 3) with the gate labels given.
  static Future<LopetAtlas> build({double density = 2, List<String> labels = const ['', '', '']}) async {
    final k = density;
    final rects = Float32List(LopetSprite.values.length * 4);
    // Shelf packing.
    var x = 0.0, y = 0.0, shelf = 0.0, widest = 0.0;
    final limit = math.min(maxWidth, 6 * unit * k + 16 * pad);
    for (final s in LopetSprite.values) {
      final (wu, hu) = sizes[s]!;
      final w = wu * unit * k, h = hu * unit * k;
      if (x + w + 2 * pad > limit) {
        x = 0;
        y += shelf;
        shelf = 0;
      }
      rects[s.index * 4] = x + pad;
      rects[s.index * 4 + 1] = y + pad;
      rects[s.index * 4 + 2] = x + pad + w;
      rects[s.index * 4 + 3] = y + pad + h;
      x += w + 2 * pad;
      shelf = math.max(shelf, h + 2 * pad);
      widest = math.max(widest, x);
    }
    final total = y + shelf;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    for (final s in LopetSprite.values) {
      final r = Rect.fromLTRB(rects[s.index * 4], rects[s.index * 4 + 1], rects[s.index * 4 + 2], rects[s.index * 4 + 3]);
      c.save();
      c.clipRect(r);
      c.translate(r.left, r.top);
      _draw(c, s, r.width, r.height, labels);
      c.restore();
    }
    final img = await rec.endRecording().toImage(widest.ceil(), total.ceil());
    return LopetAtlas._(img, rects, k);
  }

  void dispose() => image.dispose();

  static void _draw(Canvas c, LopetSprite s, double w, double h, List<String> labels) {
    final p = Paint()..isAntiAlias = true;
    switch (s) {
      case LopetSprite.water0:
      case LopetSprite.water1:
        // Faint ripples: short light strokes, two patterns so the layers do not line up.
        p
          ..color = const Color(0x14FFFFFF)
          ..strokeWidth = w * .012
          ..strokeCap = StrokeCap.round;
        final seed = s == LopetSprite.water0 ? 3 : 7;
        for (var i = 0; i < 9; i++) {
          final fx = ((i * 37 + seed * 11) % 100) / 100, fy = ((i * 53 + seed * 29) % 100) / 100;
          c.drawLine(Offset(fx * w, fy * h), Offset((fx + .14) * w, fy * h), p);
        }
      case LopetSprite.foam:
        p.shader = ui.Gradient.linear(Offset.zero, Offset(w, 0), [const Color(0x00FFFFFF), const Color(0x33FFFFFF), const Color(0x00FFFFFF)], [0, .5, 1]);
        for (var i = 0; i < 4; i++) {
          c.drawRect(Rect.fromLTWH(0, h * (i / 4), w, h * .16), p);
        }
      case LopetSprite.boye:
        c.drawCircle(Offset(w / 2, h / 2), w * .44, p..color = const Color(0xFFE5532D));
        c.drawRect(Rect.fromCenter(center: Offset(w / 2, h / 2), width: w * .88, height: h * .2), Paint()..color = const Color(0xFFFFFFFF));
        c.drawCircle(Offset(w / 2, h / 2), w * .44, Paint()..style = PaintingStyle.stroke..strokeWidth = w * .07..color = const Color(0xFF7A1F0A));
      case LopetSprite.stokk:
        c.drawRRect(RRect.fromLTRBR(0, h * .1, w, h * .9, Radius.circular(h * .4)), p..color = const Color(0xFF8A5A2B));
        final grain = Paint()..color = const Color(0xFF5E3B18)..strokeWidth = h * .08;
        for (var gx = h; gx < w - h; gx += h * 1.3) {
          c.drawLine(Offset(gx, h * .3), Offset(gx + h * .4, h * .7), grain);
        }
      case LopetSprite.garn:
        final net = Paint()..color = const Color(0x8CFFFFFF)..strokeWidth = h * .07;
        for (var gx = 0.0; gx <= w; gx += h * .5) {
          c.drawLine(Offset(gx, 0), Offset(gx + h * .35, h), net);
          c.drawLine(Offset(gx + h * .35, 0), Offset(gx, h), net);
        }
        for (var i = 0; i <= 4; i++) {
          c.drawCircle(Offset(w * i / 4, h / 2), h * .22, Paint()..color = const Color(0xFFF2C14E));
        }
      case LopetSprite.garnFloat:
        c.drawCircle(Offset(w / 2, h / 2), w * .42, p..color = const Color(0xFFF2C14E));
      case LopetSprite.kajakk:
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .2, 0, w * .6, h), Radius.circular(w * .3)), p..color = const Color(0xFFF7C948));
        c.drawLine(Offset(0, h / 2), Offset(w, h / 2), Paint()..color = const Color(0xFF2B2B2B)..strokeWidth = w * .1);
      case LopetSprite.beffen:
        final hull = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), Radius.circular(h * .25));
        c.drawRRect(hull, p..color = const Color(0xFFFFFFFF));
        c.drawRect(Rect.fromCenter(center: Offset(w / 2, h / 2), width: w * .55, height: h * .5), Paint()..color = const Color(0xFFD94B3A));
        c.drawRRect(hull, Paint()..style = PaintingStyle.stroke..strokeWidth = h * .05..color = const Color(0xFF1B2A33));
      case LopetSprite.gull:
        final path = Path()
          ..moveTo(0, h * .4)
          ..quadraticBezierTo(w * .25, -h * .1, w * .5, h * .55)
          ..quadraticBezierTo(w * .75, -h * .1, w, h * .4)
          ..lineTo(w * .5, h)
          ..close();
        c.drawPath(path, p..color = const Color(0xFFFFFFFF));
        c.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = h * .06..color = const Color(0xFF34474F));
      case LopetSprite.gullShadow:
        c.drawOval(Rect.fromLTWH(0, 0, w, h), p..color = const Color(0x59000000));
      case LopetSprite.wake:
        final wp = Paint()..style = PaintingStyle.stroke..strokeWidth = h * .08..color = const Color(0xB3FFFFFF);
        for (var k = 0; k < 3; k++) {
          final path = Path()..moveTo(0, h * (.25 + k * .22));
          for (var gx = 0.0; gx <= w; gx += w / 12) {
            path.lineTo(gx, h * (.25 + k * .22) + math.sin(gx / w * 12) * h * .06);
          }
          c.drawPath(path, wp);
        }
      case LopetSprite.crate:
        final r = Rect.fromLTWH(w * .06, h * .06, w * .88, h * .88);
        c.drawRect(r, p..color = const Color(0xFFB07A3E));
        final edge = Paint()..style = PaintingStyle.stroke..strokeWidth = w * .08..color = const Color(0xFF6B4520);
        c.drawRect(r, edge);
        c.drawLine(r.topLeft, r.bottomRight, edge..strokeWidth = w * .06);
        c.drawLine(r.topRight, r.bottomLeft, edge);
      case LopetSprite.boatRobaat:
      case LopetSprite.boatVimpel:
      case LopetSprite.boatSnekke:
      case LopetSprite.boatEgen:
        final colour = switch (s) {
          LopetSprite.boatSnekke => const Color(0xFFFFFFFF),
          LopetSprite.boatEgen => const Color(0xFF2F7FB8),
          _ => const Color(0xFF9C6A3A),
        };
        final hull = Path()
          ..moveTo(w / 2, 0)
          ..quadraticBezierTo(w, h * .33, w * .92, h)
          ..lineTo(w * .08, h)
          ..quadraticBezierTo(0, h * .33, w / 2, 0)
          ..close();
        c.drawPath(hull, p..color = colour);
        c.drawPath(hull, Paint()..style = PaintingStyle.stroke..strokeWidth = w * .05..color = const Color(0xFF1B2A33));
        c.drawCircle(Offset(w / 2, h * .62), w * .14, Paint()..color = const Color(0xFF2B4C59)); // Ægil at the oars
        if (s == LopetSprite.boatVimpel || s == LopetSprite.boatEgen) {
          c.drawLine(Offset(w / 2, h * .5), Offset(w / 2, h * .06), Paint()..color = const Color(0xFFFFFFFF)..strokeWidth = w * .04);
          c.drawPath(Path()..moveTo(w / 2, h * .06)..lineTo(w * .86, h * .12)..lineTo(w / 2, h * .18)..close(), Paint()..color = const Color(0xFFE5532D));
        }
      case LopetSprite.ring:
        c.drawCircle(Offset(w / 2, h / 2), w * .44, Paint()..style = PaintingStyle.stroke..strokeWidth = w * .07..color = const Color(0xFFE5532D));
        final white = Paint()..style = PaintingStyle.stroke..strokeWidth = w * .075..color = const Color(0xFFFFFFFF);
        for (var i = 0; i < 4; i++) {
          c.drawArc(Rect.fromCircle(center: Offset(w / 2, h / 2), radius: w * .44), i * math.pi / 2 + .3, .5, false, white);
        }
      case LopetSprite.gate:
        c.drawRect(Rect.fromLTWH(0, h * .3, w, h * .4), p..color = const Color(0xFFF2C14E));
        for (var i = 0; i < 24; i++) {
          final bx = w * (i + .5) / 24;
          c.drawPath(Path()..moveTo(bx - h * .3, h * .3)..lineTo(bx + h * .3, h * .3)..lineTo(bx, h), Paint()..color = i.isEven ? const Color(0xFFE5532D) : const Color(0xFF7FF0CB));
        }
      case LopetSprite.flagBest:
      case LopetSprite.flagWeek:
      case LopetSprite.flagRival:
        final colour = switch (s) {
          LopetSprite.flagBest => const Color(0xFFF7D57E),
          LopetSprite.flagWeek => const Color(0xFF7FF0CB),
          _ => const Color(0xFFFF9C7A),
        };
        c.drawLine(Offset(w * .2, h), Offset(w * .2, 0), Paint()..color = const Color(0xFFFFFFFF)..strokeWidth = w * .1);
        c.drawPath(Path()..moveTo(w * .2, 0)..lineTo(w, h * .2)..lineTo(w * .2, h * .42)..close(), Paint()..color = colour);
      case LopetSprite.spray:
        c.drawCircle(Offset(w / 2, h / 2), w * .45, p..color = const Color(0xCCFFFFFF));
      case LopetSprite.label0:
      case LopetSprite.label1:
      case LopetSprite.label2:
        final i = s.index - LopetSprite.label0.index;
        final text = i < labels.length ? labels[i] : '';
        final tp = TextPainter(
          text: TextSpan(text: text, style: TextStyle(color: const Color(0xFFF7D57E), fontSize: h * .62, fontWeight: FontWeight.w800)),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: w);
        tp.paint(c, Offset((w - tp.width) / 2, (h - tp.height) / 2));
        tp.dispose();
    }
  }
}
