import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'lopet_look.dart';

/// Fjordløpet v1.3 plan Step 9 (spec §12.2, §12.6, plan D10/D11): the sprite atlas — every figure the play field draws,
/// in one image per session, so the painter makes one `drawRawAtlas` call per frame.
///
/// The figures are ports of the prototype's canvas code in `designs/25des/Fjordlopet.dc.html` (`tTing` for the
/// buoy, log, net, kayak, Beffen and crate; `tPort` for the gate bunting; `tFlagg`; `tMaake`; `skrog`/`skrogSprite` for
/// the færing per level), with Ægil from `assets/images/aegil/rear.png`. Plan D11: they are drawn into the atlas when
/// the session opens (before «Sett seil» can be tapped, so nothing decodes during a run) rather than shipped as PNGs —
/// the same pixels at the device's own density (2× or 3×), the gate labels in the customer's language, the sea mode's
/// lights, and no asset weight.
///
/// Sizes are in lane units (one lane = [unit] px at 1×) times the density; 2 px of padding around each figure; at most
/// 2048 × 2048 (a 3× atlas that would not fit is built at 2×). Every obstacle differs by shape, not only by colour, and
/// every object has a dark outline and a light rim, so it reads against deep and shallow water alike (T34).
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
  crateRing,
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
  // Step 9: height, banks, landmarks, light and weather.
  shadow,
  foamRing,
  reflBoat,
  reflBoye,
  reflStokk,
  reflKajakk,
  reflBeffen,
  reflCrate,
  bankQuay,
  bankPier,
  moored,
  lmNaust,
  lmKran,
  lmFyr,
  lmAkvariet,
  lmFestningen,
  lmSeilskute,
  lmVerftet,
  lmSjobad,
  glow,
  streak,
  rain,
  cloud,
  bowWave,
  lantern,
}

class LopetAtlas {
  LopetAtlas._(this.image, this.rects, this.density, this.mode);

  static const double unit = 100;
  static const double pad = 2;
  static const double maxSide = 2048;

  /// Atlases alive now (T35: back to zero once the game has closed).
  static int live = 0;

  final ui.Image image;

  /// Per sprite: left, top, right, bottom in the atlas (px), in [LopetSprite] order.
  final Float32List rects;
  final double density;
  final LopetMode mode;
  bool _disposed = false;

  double width(LopetSprite s) => rects[s.index * 4 + 2] - rects[s.index * 4];
  double height(LopetSprite s) => rects[s.index * 4 + 3] - rects[s.index * 4 + 1];

  /// The landmark sprite for a course key (`game.course.landmark_set`), or null.
  static LopetSprite? landmark(String? k) => switch (k) {
        'naust' => LopetSprite.lmNaust,
        'kran' => LopetSprite.lmKran,
        'fyr' => LopetSprite.lmFyr,
        'akvariet' => LopetSprite.lmAkvariet,
        'festningen' => LopetSprite.lmFestningen,
        'seilskute' => LopetSprite.lmSeilskute,
        'verftet' => LopetSprite.lmVerftet,
        'sjobad' => LopetSprite.lmSjobad,
        _ => null,
      };

  /// The reflection sprite for an object, or null.
  static LopetSprite? reflectionOf(LopetSprite s) => switch (s) {
        LopetSprite.boatRobaat || LopetSprite.boatVimpel || LopetSprite.boatSnekke || LopetSprite.boatEgen => LopetSprite.reflBoat,
        LopetSprite.boye => LopetSprite.reflBoye,
        LopetSprite.stokk => LopetSprite.reflStokk,
        LopetSprite.kajakk => LopetSprite.reflKajakk,
        LopetSprite.beffen => LopetSprite.reflBeffen,
        LopetSprite.crate => LopetSprite.reflCrate,
        _ => null,
      };

  /// Sizes in lane units (width, height).
  static const Map<LopetSprite, (double, double)> sizes = {
    LopetSprite.water0: (1, 1),
    LopetSprite.water1: (1, 1),
    LopetSprite.foam: (.05, .5),
    LopetSprite.boye: (.36, .36),
    LopetSprite.stokk: (1.84, .26),
    LopetSprite.garn: (1.84, .36),
    LopetSprite.garnFloat: (.12, .14),
    LopetSprite.kajakk: (.44, .5),
    LopetSprite.beffen: (.92, .5),
    LopetSprite.gull: (.5, .3),
    LopetSprite.gullShadow: (.4, .2),
    LopetSprite.wake: (1, .3),
    LopetSprite.crate: (.24, .24),
    LopetSprite.crateRing: (.44, .44),
    LopetSprite.boatRobaat: (.4, .74),
    LopetSprite.boatVimpel: (.4, .74),
    LopetSprite.boatSnekke: (.42, .78),
    LopetSprite.boatEgen: (.42, .78),
    LopetSprite.ring: (.6, .6),
    LopetSprite.gate: (3, .3),
    LopetSprite.flagBest: (.26, .34),
    LopetSprite.flagWeek: (.26, .34),
    LopetSprite.flagRival: (.26, .34),
    LopetSprite.spray: (.06, .06),
    LopetSprite.label0: (1.4, .24),
    LopetSprite.label1: (1.4, .24),
    LopetSprite.label2: (1.4, .24),
    LopetSprite.shadow: (.5, .24),
    LopetSprite.foamRing: (.5, .26),
    LopetSprite.reflBoat: (.36, .4),
    LopetSprite.reflBoye: (.32, .26),
    LopetSprite.reflStokk: (1.7, .18),
    LopetSprite.reflKajakk: (.3, .3),
    LopetSprite.reflBeffen: (.8, .3),
    LopetSprite.reflCrate: (.22, .16),
    LopetSprite.bankQuay: (.3, 1),
    LopetSprite.bankPier: (.3, .5),
    LopetSprite.moored: (.2, .42),
    LopetSprite.lmNaust: (.56, .66),
    LopetSprite.lmKran: (.56, .9),
    LopetSprite.lmFyr: (.4, .9),
    LopetSprite.lmAkvariet: (.6, .56),
    LopetSprite.lmFestningen: (.62, .7),
    LopetSprite.lmSeilskute: (.5, .9),
    LopetSprite.lmVerftet: (.62, .66),
    LopetSprite.lmSjobad: (.62, .44),
    LopetSprite.glow: (.3, .3),
    LopetSprite.streak: (.06, .4),
    LopetSprite.rain: (.02, .12),
    LopetSprite.cloud: (1.6, 1),
    LopetSprite.bowWave: (.5, .3),
    LopetSprite.lantern: (.08, .08),
  };

  /// The objects that stand out of the water (they get a shadow, foam and bobbing; T34 checks their contrast).
  static const List<LopetSprite> objects = [
    LopetSprite.boye,
    LopetSprite.stokk,
    LopetSprite.garn,
    LopetSprite.kajakk,
    LopetSprite.beffen,
    LopetSprite.gull,
    LopetSprite.crate,
    LopetSprite.boatRobaat,
  ];

  /// Lays out the sprites for [density] (shelf packing). Returns the rects, width and height.
  static (Float32List, double, double) layout(double density) {
    final k = density;
    final rects = Float32List(LopetSprite.values.length * 4);
    var x = 0.0, y = 0.0, shelf = 0.0, widest = 0.0;
    final limit = math.min(maxSide, 6 * unit * k + 16 * pad);
    for (final s in LopetSprite.values) {
      final (wu, hu) = sizes[s]!;
      final w = (wu * unit * k).ceilToDouble(), h = (hu * unit * k).ceilToDouble();
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
    return (rects, widest, y + shelf);
  }

  /// Builds the atlas at [density] (2 or 3; a 3× layout over 2048 px falls back to 2×), in sea [mode], with the gate
  /// labels given and Ægil's back for the boat.
  static Future<LopetAtlas> build({double density = 2, List<String> labels = const ['', '', ''], LopetMode mode = LopetMode.kveld, ui.Image? aegil}) async {
    var (rects, w, h) = layout(density);
    if (w > maxSide || h > maxSide) {
      density = 2;
      (rects, w, h) = layout(density);
    }
    final look = LopetLook.of(mode);
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    for (final s in LopetSprite.values) {
      final r = Rect.fromLTRB(rects[s.index * 4], rects[s.index * 4 + 1], rects[s.index * 4 + 2], rects[s.index * 4 + 3]);
      c.save();
      c.clipRect(r);
      c.translate(r.left, r.top);
      _Figur(c, r.width, r.height, look, labels, aegil).draw(s);
      c.restore();
    }
    final picture = rec.endRecording();
    final img = await picture.toImage(w.ceil(), h.ceil());
    picture.dispose();
    live++;
    return LopetAtlas._(img, rects, density, mode);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    live--;
    image.dispose();
  }
}

/// One figure, drawn into its cell (w × h px). Ported from the prototype; `m` is the prototype's metre scale for the
/// figure (its sizes are written in `m`).
class _Figur {
  _Figur(this.c, this.w, this.h, this.look, this.labels, this.aegil);

  final Canvas c;
  final double w, h;
  final LopetLook look;
  final List<String> labels;
  final ui.Image? aegil;

  static const _ink = Color(0xFF23201D);
  static const _outline = Color(0xFF14232A);
  static const _cream = Color(0xFFF5F3EF);

  Paint get _p => Paint()..isAntiAlias = true;
  Paint _stroke(Color colour, double width) => Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = colour;

  /// The readability rim (spec §12.6): a dark outline and a light edge, on every object.
  void _rim(Path p, double width) {
    // At least 5.6 px of outline with 2 px of light edge on it (at 2×): the dark band outside the light one reads on
    // light water, the light one on dark water, also on a small figure (the crate).
    c.drawPath(p, _stroke(_outline, math.max(width * 2, 5.6)));
    c.drawPath(p, _stroke(look.rim, math.max(width * .8, 2.0)));
  }

  void draw(LopetSprite s) {
    switch (s) {
      case LopetSprite.water0 || LopetSprite.water1:
        _water(s == LopetSprite.water0 ? 3 : 7);
      case LopetSprite.foam:
        final p = _stroke(const Color(0x26FFFFFF), w * .5);
        c.drawLine(Offset(w / 2, h * .15), Offset(w / 2, h * .55), p);
      case LopetSprite.boye:
        _boye(1);
      case LopetSprite.reflBoye:
        _reflection(() => _boye(.9));
      case LopetSprite.stokk:
        _stokk(1);
      case LopetSprite.reflStokk:
        _reflection(() => _stokk(.9));
      case LopetSprite.garn:
        _garn();
      case LopetSprite.garnFloat:
        final path = Path()
          ..moveTo(w / 2, h * .05)
          ..lineTo(w * .95, h / 2)
          ..lineTo(w / 2, h * .95)
          ..lineTo(w * .05, h / 2)
          ..close();
        c.drawPath(path, _p..color = const Color(0xFFF2C14E));
        c.drawPath(path, _stroke(const Color(0xD95A3E08), w * .1));
      case LopetSprite.kajakk:
        _kajakk(1);
      case LopetSprite.reflKajakk:
        _reflection(() => _kajakk(.9));
      case LopetSprite.beffen:
        _beffen(1);
      case LopetSprite.reflBeffen:
        _reflection(() => _beffen(.9));
      case LopetSprite.gull:
        _gull();
      case LopetSprite.gullShadow:
        c.drawOval(Rect.fromLTWH(0, 0, w, h), _p..color = const Color(0x660A1A20));
      case LopetSprite.wake:
        for (var k = 0; k < 3; k++) {
          final path = Path()..moveTo(0, h * (.25 + k * .22));
          for (var gx = 0.0; gx <= w; gx += w / 16) {
            path.lineTo(gx, h * (.25 + k * .22) + math.sin(gx / w * 14) * h * .07);
          }
          c.drawPath(path, _stroke(const Color(0xB3FFFFFF), h * .08));
        }
      case LopetSprite.crate:
        _crate(1);
      case LopetSprite.reflCrate:
        _reflection(() => _crate(.9));
      case LopetSprite.crateRing:
        c.drawCircle(Offset(w / 2, h / 2), w * .44, _stroke(const Color(0xB37FF0CB), w * .05));
      case LopetSprite.boatRobaat || LopetSprite.boatVimpel || LopetSprite.boatSnekke || LopetSprite.boatEgen:
        _boat(s);
      case LopetSprite.reflBoat:
        _reflection(() => _hull(_HullColours.ro, .9, w * .5, h * .62, h / 5.4));
      case LopetSprite.ring:
        c.drawCircle(Offset(w / 2, h / 2), w * .42, _stroke(const Color(0xFFE5532D), w * .09));
        final white = _stroke(const Color(0xFFFFFFFF), w * .095)..strokeCap = StrokeCap.butt;
        for (var i = 0; i < 4; i++) {
          c.drawArc(Rect.fromCircle(center: Offset(w / 2, h / 2), radius: w * .42), i * math.pi / 2 + .3, .5, false, white);
        }
      case LopetSprite.gate:
        _gate();
      case LopetSprite.flagBest || LopetSprite.flagWeek || LopetSprite.flagRival:
        final colour = switch (s) {
          LopetSprite.flagBest => const Color(0xFF5CE0B8),
          LopetSprite.flagWeek => const Color(0xFFF2C14E),
          _ => const Color(0xFFFF9C7A),
        };
        // `tFlagg`: a white pole on a float, a pennant.
        c.drawCircle(Offset(w * .2, h * .86), w * .12, _p..color = _cream);
        c.drawLine(Offset(w * .2, h * .86), Offset(w * .2, h * .04), _stroke(_cream, w * .07));
        c.drawPath(Path()..moveTo(w * .2, h * .04)..lineTo(w * .98, h * .22)..lineTo(w * .2, h * .4)..close(), _p..color = colour);
      case LopetSprite.spray:
        c.drawCircle(Offset(w / 2, h / 2), w * .45, _p..color = const Color(0xE6FFFFFF));
      case LopetSprite.label0 || LopetSprite.label1 || LopetSprite.label2:
        _label(s.index - LopetSprite.label0.index);
      case LopetSprite.shadow:
        c.drawOval(Rect.fromLTWH(w * .04, h * .1, w * .92, h * .8), _p..color = const Color(0x4D04121A));
        c.drawOval(Rect.fromLTWH(w * .16, h * .24, w * .68, h * .52), _p..color = const Color(0x3304121A));
      case LopetSprite.foamRing:
        c.drawOval(Rect.fromLTWH(w * .05, h * .1, w * .9, h * .8), _stroke(const Color(0x8CFFFFFF), h * .1));
        c.drawOval(Rect.fromLTWH(w * .14, h * .26, w * .72, h * .48), _stroke(const Color(0x40FFFFFF), h * .06));
      case LopetSprite.bankQuay:
        _quay();
      case LopetSprite.bankPier:
        _pier();
      case LopetSprite.moored:
        _hull(_HullColours.snekke, 1, w / 2, h / 2, h / 5.2);
      case LopetSprite.lmNaust:
        _naust();
      case LopetSprite.lmKran:
        _kran();
      case LopetSprite.lmFyr:
        _fyr();
      case LopetSprite.lmAkvariet:
        _akvariet();
      case LopetSprite.lmFestningen:
        _festningen();
      case LopetSprite.lmSeilskute:
        _seilskute();
      case LopetSprite.lmVerftet:
        _verftet();
      case LopetSprite.lmSjobad:
        _sjobad();
      case LopetSprite.glow:
        c.drawCircle(Offset(w / 2, h / 2), w / 2,
            _p..shader = ui.Gradient.radial(Offset(w / 2, h / 2), w / 2, [look.lights.withValues(alpha: .7), look.lights.withValues(alpha: 0)]));
      case LopetSprite.streak:
        c.drawRect(Rect.fromLTWH(0, 0, w, h),
            _p..shader = ui.Gradient.linear(Offset.zero, Offset(0, h), [look.lights.withValues(alpha: .55), look.lights.withValues(alpha: 0)]));
      case LopetSprite.rain:
        c.drawLine(Offset(w, 0), Offset(0, h), _stroke(const Color(0x59FFFFFF), w * .6));
      case LopetSprite.cloud:
        // One soft shadow with no edges (three wide overlapping falloffs, faint), so no blob reads on its own.
        for (var i = 0; i < 3; i++) {
          final cx = w * (.3 + i * .2), cy = h * (.5 + (i == 1 ? -.06 : .05));
          c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: w * .8, height: h * .95),
              _p..shader = ui.Gradient.radial(Offset(cx, cy), w * .4, [const Color(0x1404121A), const Color(0x0004121A)]));
        }
      case LopetSprite.bowWave:
        final p = _stroke(const Color(0xCCFFFFFF), h * .1);
        c.drawPath(Path()..moveTo(w * .05, h * .95)..quadraticBezierTo(w * .3, h * .3, w * .5, h * .05), p);
        c.drawPath(Path()..moveTo(w * .95, h * .95)..quadraticBezierTo(w * .7, h * .3, w * .5, h * .05), p);
      case LopetSprite.lantern:
        c.drawCircle(Offset(w / 2, h / 2), w * .45, _p..color = look.lights);
    }
  }

  // ── water (quality Low) ──

  void _water(int seed) {
    // `vann2d`: short light curves on the water, two patterns so the layers do not line up.
    final p = _stroke(const Color(0x1AFFFFFF), w * .012);
    for (var i = 0; i < 9; i++) {
      final fx = ((i * 37 + seed * 11) % 100) / 100, fy = ((i * 53 + seed * 29) % 100) / 100, len = .1 + ((i * 7 + seed) % 10) / 60;
      c.drawPath(Path()..moveTo(fx * w, fy * h)..quadraticBezierTo((fx + len / 2) * w, fy * h - w * .02, (fx + len) * w, fy * h), p);
    }
  }

  /// A reflection: the figure flipped, short and broken by the waves (two bands), dim.
  void _reflection(void Function() figure) {
    c.save();
    c.clipRect(Rect.fromLTWH(0, 0, w, h * .4));
    c.clipRect(Rect.fromLTWH(0, h * .5, w, h * .5), clipOp: ui.ClipOp.difference);
    _flipDim(figure);
    c.restore();
    c.save();
    c.clipRect(Rect.fromLTWH(0, h * .5, w, h * .3));
    c.translate(w * .03, 0);
    _flipDim(figure);
    c.restore();
  }

  void _flipDim(void Function() figure) {
    c.saveLayer(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0x47FFFFFF));
    c.translate(0, h * .9);
    c.scale(1, -.9);
    figure();
    c.restore();
  }

  // ── tTing ──

  void _boye(double k) {
    final r = w * .4 * k, o = Offset(w / 2, h / 2);
    c.drawCircle(o, r, _p..shader = ui.Gradient.radial(o - Offset(r * .35, r * .4), r, const [Color(0xFFFF8D6E), Color(0xFFDF4428), Color(0xFF8A2212)], [0, .55, 1]));
    c.drawCircle(o, r * .62, _stroke(const Color(0xF0FFFFFF), r * .3));
    c.drawCircle(o, r * .27, _p..color = _ink);
    if (look.lightsOn) {
      c.drawCircle(o, r * 1.2, _p..shader = ui.Gradient.radial(o, r * 1.2, [look.lights.withValues(alpha: .36), look.lights.withValues(alpha: 0)]));
    }
    c.drawCircle(o, r * .13, _p..color = look.lightsOn ? look.lights : _cream);
    c.drawOval(Rect.fromCenter(center: o - Offset(r * .42, r * .46), width: r * .4, height: r * .22), _p..color = const Color(0x8CFFFFFF));
    _rim(Path()..addOval(Rect.fromCircle(center: o, radius: r)), r * .1);
  }

  void _stokk(double k) {
    final th = h * .78 * k, y0 = (h - th) / 2;
    final body = RRect.fromLTRBR(w * .01, y0, w * .99, y0 + th, Radius.circular(th / 2));
    c.drawRRect(body, _p..shader = ui.Gradient.linear(Offset(0, y0), Offset(0, y0 + th), const [Color(0xFFC89058), Color(0xFF9A6638), Color(0xFF553217)], [0, .35, 1]));
    final grain = _stroke(const Color(0x8C3C220E), th * .05);
    for (var i = 0; i < 8; i++) {
      final xx = w * (.06 + .82 * ((i * 37 + 13) % 100) / 100), len = w * (.04 + (i * 7 % 14) / 300), ly = y0 + th * (.3 + (i % 3) * .2);
      c.drawLine(Offset(xx, ly), Offset(xx + len, ly), grain);
    }
    c.drawLine(Offset(w * .05, y0 + th * .2), Offset(w * .95, y0 + th * .2), _stroke(const Color(0x80FFE8C4), th * .07));
    for (final xx in [w * .01 + th * .3, w * .99 - th * .3]) {
      c.drawOval(Rect.fromCenter(center: Offset(xx, h / 2), width: th * .4, height: th * .8), _p..color = const Color(0xFFDDB27C));
      c.drawOval(Rect.fromCenter(center: Offset(xx, h / 2), width: th * .2, height: th * .44), _stroke(const Color(0xFF8A5A33), th * .05));
    }
    _rim(Path()..addRRect(body), th * .05);
  }

  void _garn() {
    final y = h * .3;
    final net = RRect.fromLTRBR(w * .01, y - h * .02, w * .99, h * .92, Radius.circular(h * .1));
    c.drawRRect(net, _p..color = const Color(0x3D061A21));
    final mesh = _stroke(const Color(0x52061A21), h * .025);
    for (var xx = w * .02; xx < w; xx += h * .25) {
      c.drawLine(Offset(xx, y), Offset(xx - h * .14, h * .9), mesh);
      c.drawLine(Offset(xx, y), Offset(xx + h * .14, h * .9), mesh);
    }
    c.drawLine(Offset(w * .01, y), Offset(w * .99, y), _stroke(const Color(0xFFEFE6D2), h * .05));
    for (var i = 0; i <= 9; i++) {
      final xx = w * (.02 + .96 * i / 9), r = h * (i.isOdd ? .1 : .13), o = Offset(xx, y);
      c.drawCircle(o, r, _p..shader = ui.Gradient.radial(o - Offset(r * .3, r * .3), r, i.isOdd ? const [Color(0xFFFFFFFF), Color(0xFFBFCDD2)] : const [Color(0xFFFFE9A8), Color(0xFFD4941A)]));
      c.drawCircle(o, r, _stroke(_outline, r * .3));
    }
    c.drawLine(Offset(w * .01, y), Offset(w * .99, y), _stroke(_outline, h * .02));
  }

  void _kajakk(double k) {
    c.save();
    c.translate(w / 2, h / 2);
    final lk = h * .48 * k, wk = w * .14 * k;
    final hull = Path()
      ..moveTo(0, -lk)
      ..quadraticBezierTo(wk * 1.6, 0, 0, lk)
      ..quadraticBezierTo(-wk * 1.6, 0, 0, -lk)
      ..close();
    c.drawPath(hull, _p..shader = ui.Gradient.linear(Offset(-wk, 0), Offset(wk, 0), const [Color(0xFFFFE38F), Color(0xFFF2B93B), Color(0xFFB27A18)], [0, .5, 1]));
    final line = _stroke(const Color(0x997A560F), wk * .08);
    c.drawLine(Offset(0, -lk * .82), Offset(0, -lk * .28), line);
    c.drawLine(Offset(0, lk * .36), Offset(0, lk * .82), line);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: wk * 1.24, height: lk * .44), _p..color = _ink);
    c.drawOval(Rect.fromCenter(center: Offset(0, lk * .04), width: wk * 1.12, height: lk * .26), _p..color = const Color(0xFF2A6272));
    c.drawCircle(Offset(0, -lk * .04), wk * .36, _p..color = const Color(0xFFE8C79A));
    // The paddle across: the kayak's shape differs from every other obstacle.
    c.drawLine(Offset(-w * .46, 0), Offset(w * .46, 0), _stroke(_cream, wk * .22));
    for (final sx in [-1.0, 1.0]) {
      c.drawOval(Rect.fromCenter(center: Offset(sx * w * .43, 0), width: wk, height: wk * .48), _p..color = _cream);
    }
    _rim(hull, wk * .1);
    c.restore();
  }

  void _beffen(double k) {
    c.save();
    c.translate(w / 2, h / 2);
    final hw = w * .48 * k, hh = h * .46 * k;
    Path hull(double s) => Path()
      ..moveTo(-hw * s, -hh * .78 * s)
      ..lineTo(hw * .5 * s, -hh * s)
      ..quadraticBezierTo(hw * 1.12 * s, 0, hw * .5 * s, hh * s)
      ..lineTo(-hw * s, hh * .78 * s)
      ..quadraticBezierTo(-hw * 1.07 * s, 0, -hw * s, -hh * .78 * s)
      ..close();
    c.drawPath(hull(1), _p..shader = ui.Gradient.linear(Offset(0, -hh), Offset(0, hh), const [Color(0xFFFFFFFF), Color(0xFFC0CED3)]));
    c.drawPath(hull(.86), _p..color = const Color(0xFFC99862));
    final plank = _stroke(const Color(0x735E3A1E), hh * .03);
    for (var i = -3; i <= 3; i++) {
      c.drawLine(Offset(-hw * .8, i * hh * .2), Offset(hw * .62, i * hh * .2), plank);
    }
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-hw * .6, -hh * .55, hw * .95, hh * 1.1), Radius.circular(hh * .15)),
        _p..shader = ui.Gradient.linear(Offset(0, -hh * .55), Offset(0, hh * .55), const [Color(0xFF3F8A9E), Color(0xFF1E4F5C)]));
    final win = _p..color = look.lightsOn ? const Color(0xFFFFD98A) : const Color(0xFFBFE3EC);
    for (var i = 0; i < 5; i++) {
      c.drawRect(Rect.fromLTWH(-hw * .54 + i * hw * .18, -hh * .47, hw * .12, hh * .18), win);
      c.drawRect(Rect.fromLTWH(-hw * .54 + i * hw * .18, hh * .29, hw * .12, hh * .18), win);
    }
    c.drawCircle(Offset(-hw * .43, 0), hh * .17, _p..color = _ink);
    final tp = TextPainter(
      text: TextSpan(text: 'BEFFEN', style: TextStyle(color: const Color(0xFFFFFFFF), fontSize: hh * .32, fontWeight: FontWeight.w800, letterSpacing: hh * .02)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(-tp.width / 2 + hw * .1, -tp.height / 2));
    tp.dispose();
    _rim(hull(1), hh * .05);
    c.restore();
  }

  void _gull() {
    // `tMaake` fugl: white wings with dark tips and a yellow beak.
    final s = w / 3.2, cx = w / 2, cy = h * .45, wy = s * .2;
    final body = Path()
      ..moveTo(cx - s * 1.5, cy - wy)
      ..quadraticBezierTo(cx - s * .6, cy - s * .55 - wy, cx, cy - s * .1)
      ..quadraticBezierTo(cx + s * .6, cy - s * .55 - wy, cx + s * 1.5, cy - wy)
      ..quadraticBezierTo(cx + s * .6, cy + s * .1, cx, cy + s * .45)
      ..quadraticBezierTo(cx - s * .6, cy + s * .1, cx - s * 1.5, cy - wy)
      ..close();
    c.drawPath(body, _p..color = const Color(0xFFFFFFFF));
    for (final q in [-1.0, 1.0]) {
      c.drawPath(Path()..moveTo(cx + q * s * 1.5, cy - wy)..lineTo(cx + q * s * 1.12, cy - wy - s * .12)..lineTo(cx + q * s * 1.18, cy - wy + s * .12)..close(), _p..color = _ink);
    }
    c.drawPath(Path()..moveTo(cx - s * .14, cy - s * .15)..lineTo(cx + s * .14, cy - s * .15)..lineTo(cx, cy - s * .55)..close(), _p..color = const Color(0xFFF2C14E));
    c.drawPath(body, _stroke(const Color(0xFF3A4A50), s * .06));
  }

  void _crate(double k) {
    final s = w * .4 * k, o = Offset(w / 2, h / 2);
    final box = RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: s * 2, height: s * 2), Radius.circular(s * .15));
    c.drawRRect(box, _p..shader = ui.Gradient.linear(o - Offset(s, s), o + Offset(s, s), const [Color(0xFFEDC78C), Color(0xFFA16E38)]));
    final edge = _stroke(const Color(0xFF6B4420), s * .1);
    c.drawRRect(box, edge);
    c.drawLine(o + Offset(-s, -s * .36), o + Offset(s, -s * .36), edge);
    c.drawLine(o + Offset(-s, s * .36), o + Offset(s, s * .36), edge);
    c.drawCircle(o, s * .46, _p..color = const Color(0xFF5CE0B8));
    final cross = _stroke(const Color(0xFF0F3540), s * .12);
    c.drawLine(o + Offset(-s * .24, 0), o + Offset(s * .24, 0), cross);
    c.drawLine(o + Offset(0, -s * .24), o + Offset(0, s * .24), cross);
    _rim(Path()..addRRect(box), s * .06);
  }

  // ── the færing (`skrog`, `skrogSprite`) ──

  void _boat(LopetSprite s) {
    final colours = switch (s) {
      LopetSprite.boatSnekke => _HullColours.snekke,
      LopetSprite.boatEgen => _HullColours.egen,
      _ => _HullColours.ro,
    };
    final u = h / 5.4; // the prototype's hull is 2 × 2.3 units long
    final cx = w / 2, cy = h * .56;
    _hull(colours, 1, cx, cy, u);
    // Ægil from behind, at the oars.
    final a = aegil;
    final fig = Rect.fromCenter(center: Offset(cx, cy - u * .1), width: u * 1.9, height: u * 1.9);
    if (a != null) {
      c.drawImageRect(a, Rect.fromLTWH(0, 0, a.width.toDouble(), a.height.toDouble()), fig, Paint()..filterQuality = FilterQuality.medium);
    } else {
      c.drawCircle(fig.center, u * .55, _p..color = const Color(0xFF2B4C59));
    }
    // Oars.
    final oar = _stroke(const Color(0xFFDDB27C), u * .12);
    c.drawLine(Offset(cx - u * .7, cy - u * .1), Offset(cx - w * .48, cy + u * .3), oar);
    c.drawLine(Offset(cx + u * .7, cy - u * .1), Offset(cx + w * .48, cy + u * .3), oar);
    if (s == LopetSprite.boatVimpel || s == LopetSprite.boatEgen) {
      c.drawLine(Offset(cx, cy - u * 1.6), Offset(cx, cy - u * 2.9), _stroke(_cream, u * .1));
      c.drawPath(Path()..moveTo(cx, cy - u * 2.9)..lineTo(cx + u * 1.1, cy - u * 2.7)..lineTo(cx, cy - u * 2.5)..close(), _p..color = const Color(0xFFE5532D));
    }
    if (look.lightsOn) c.drawCircle(Offset(cx, cy + u * 2), u * .22, _p..color = look.lights); // the lantern astern
  }

  Path _hullPath(double k, double cx, double cy, double u) {
    const l = 2.3, b = 1.12;
    return Path()
      ..moveTo(cx, cy - l * k * u)
      ..cubicTo(cx + b * .95 * k * u, cy - l * .78 * k * u, cx + b * k * u, cy - l * .3 * k * u, cx + b * k * u, cy + .1 * k * u)
      ..cubicTo(cx + b * k * u, cy + l * .52 * k * u, cx + b * .66 * k * u, cy + l * .84 * k * u, cx, cy + l * .92 * k * u)
      ..cubicTo(cx - b * .66 * k * u, cy + l * .84 * k * u, cx - b * k * u, cy + l * .52 * k * u, cx - b * k * u, cy + .1 * k * u)
      ..cubicTo(cx - b * k * u, cy - l * .3 * k * u, cx - b * .95 * k * u, cy - l * .78 * k * u, cx, cy - l * k * u)
      ..close();
  }

  void _hull(_HullColours f, double k, double cx, double cy, double u) {
    final hull = _hullPath(k, cx, cy, u);
    c.drawPath(hull, _p..shader = ui.Gradient.linear(Offset(cx - 1.12 * u, 0), Offset(cx + 1.12 * u, 0), [f.u1, f.u0, f.u1], [0, .5, 1]));
    c.drawPath(_hullPath(k * .937, cx, cy, u), _stroke(f.str, u * .045));
    c.drawPath(_hullPath(k * .9, cx, cy, u), _stroke(f.ripe, u * .12));
    c.drawPath(_hullPath(k * .82, cx, cy, u), _p..shader = ui.Gradient.linear(Offset(cx, cy - 2 * u), Offset(cx, cy + 2 * u), [f.i0, f.i1]));
    final plank = _stroke(f.sp, u * .03);
    for (var i = -3; i <= 3; i++) {
      c.drawLine(Offset(cx - u * .8, cy + i * u * .5), Offset(cx + u * .8, cy + i * u * .5), plank);
    }
    _rim(hull, u * .05);
  }

  // ── tPort, labels ──

  void _gate() {
    // The bunting across the fjord between two white buoys.
    final y = h * .25, sag = h * .2;
    final line = Path()..moveTo(w * .02, y)..quadraticBezierTo(w / 2, y + sag * 2, w * .98, y);
    c.drawPath(line, _stroke(const Color(0xE6F5F3EF), h * .05));
    for (var i = 1; i < 24; i++) {
      final f = i / 24, x = w * (.02 + .96 * f), yy = y + 4 * sag * f * (1 - f);
      final colour = i % 3 == 0 ? const Color(0xFFFFFFFF) : i % 3 == 1 ? const Color(0xFF5CE0B8) : const Color(0xFFF2C14E);
      c.drawPath(Path()..moveTo(x - h * .17, yy)..lineTo(x + h * .17, yy)..lineTo(x, yy + h * .42)..close(), _p..color = colour);
    }
    for (final x in [w * .02 + h * .2, w * .98 - h * .2]) {
      final o = Offset(x, y);
      c.drawCircle(o, h * .2, _p..shader = ui.Gradient.radial(o - Offset(h * .06, h * .06), h * .2, const [Color(0xFFFFFFFF), Color(0xFFB4C3C8)]));
      c.drawCircle(o, h * .12, _stroke(const Color(0xFF5CE0B8), h * .07));
      c.drawCircle(o, h * .045, _p..color = _ink);
    }
  }

  void _label(int i) {
    final text = (i < labels.length ? labels[i] : '').toUpperCase();
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: const Color(0xFF5CE0B8), fontSize: h * .5, fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: w * .92);
    final pill = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w / 2, h / 2), width: math.min(w - 2, tp.width + h * .9), height: h * .92), Radius.circular(h * .46));
    c.drawRRect(pill, _p..color = const Color(0xE60A2128));
    c.drawRRect(pill, _stroke(const Color(0xFF5CE0B8), h * .06));
    tp.paint(c, Offset((w - tp.width) / 2, (h - tp.height) / 2));
    tp.dispose();
  }

  // ── banks (spec §12.6: stone quay walls, piers on piles, fenders, moored boats and naust) ──

  void _quay() {
    // A vertical strip of stone wall with its top edge towards the land side (left of the cell is land).
    c.drawRect(Rect.fromLTWH(0, 0, w * .78, h), _p..color = look.stone);
    final joint = _stroke(look.stoneDark, w * .02);
    for (var row = 0; row < 8; row++) {
      final y = h * row / 8;
      c.drawLine(Offset(0, y), Offset(w * .78, y), joint);
      for (var col = 0; col < 3; col++) {
        final x = w * (.13 + .26 * col + (row.isOdd ? .13 : 0));
        if (x < w * .78) c.drawLine(Offset(x, y), Offset(x, y + h / 8), joint);
      }
    }
    // The wall's face and its shadow on the water.
    c.drawRect(Rect.fromLTWH(w * .72, 0, w * .1, h), _p..color = look.stoneDark);
    c.drawRect(Rect.fromLTWH(w * .82, 0, w * .18, h),
        _p..shader = ui.Gradient.linear(Offset(w * .82, 0), Offset(w, 0), const [Color(0x6604121A), Color(0x0004121A)]));
    // The foam line along the quay.
    c.drawLine(Offset(w * .84, 0), Offset(w * .84, h), _stroke(const Color(0x8CFFFFFF), w * .035));
    for (var i = 0; i < 3; i++) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .74, h * (.14 + i * .32), w * .1, h * .1), Radius.circular(w * .04)), _p..color = _ink); // fenders
    }
  }

  void _pier() {
    final deck = _p..color = const Color(0xFF8E6A46);
    c.drawRect(Rect.fromLTWH(0, h * .3, w * .9, h * .4), deck);
    final board = _stroke(const Color(0xFF5E4430), w * .02);
    for (var i = 1; i < 8; i++) {
      c.drawLine(Offset(w * .9 * i / 8, h * .3), Offset(w * .9 * i / 8, h * .7), board);
    }
    for (var i = 0; i < 3; i++) {
      final x = w * (.15 + i * .35);
      c.drawCircle(Offset(x, h * .76), w * .05, _p..color = const Color(0xFF4A3524)); // piles
      c.drawCircle(Offset(x, h * .76), w * .08, _stroke(const Color(0x66FFFFFF), w * .02));
    }
    c.drawRect(Rect.fromLTWH(0, h * .7, w * .9, h * .14),
        _p..shader = ui.Gradient.linear(Offset(0, h * .7), Offset(0, h * .84), const [Color(0x5904121A), Color(0x0004121A)]));
  }

  // ── landmarks, seen slightly from the front: a footprint on the water, the body above it ──

  void _footprint(double fx, double fw) {
    c.drawOval(Rect.fromLTWH(w * fx, h * .86, w * fw, h * .12), _p..color = const Color(0x5904121A));
    c.drawOval(Rect.fromLTWH(w * fx, h * .86, w * fw, h * .12), _stroke(const Color(0x73FFFFFF), h * .015));
  }

  void _windows(Rect r, int cols, int rows) {
    final lit = _p..color = look.lightsOn ? look.lights : const Color(0xFF2C3E45);
    for (var j = 0; j < rows; j++) {
      for (var i = 0; i < cols; i++) {
        final x = r.left + r.width * (i + .3) / cols, y = r.top + r.height * (j + .3) / rows;
        if (look.lightsOn && (i + j * 2) % 3 == 0) continue;
        c.drawRect(Rect.fromLTWH(x, y, r.width * .4 / cols, r.height * .4 / rows), lit);
      }
    }
  }

  void _naust() {
    _footprint(.08, .84);
    final wall = Rect.fromLTWH(w * .12, h * .44, w * .76, h * .44);
    c.drawRect(wall, _p..color = const Color(0xFFB7412A));
    final plank = _stroke(const Color(0x40000000), w * .012);
    for (var x = wall.left + w * .05; x < wall.right; x += w * .06) {
      c.drawLine(Offset(x, wall.top), Offset(x, wall.bottom), plank);
    }
    c.drawPath(Path()..moveTo(w * .06, h * .46)..lineTo(w / 2, h * .1)..lineTo(w * .94, h * .46)..close(), _p..color = const Color(0xFF3A2E26));
    c.drawRect(Rect.fromLTWH(w * .36, h * .6, w * .28, h * .28), _p..color = _ink); // the boat door
    _windows(Rect.fromLTWH(w * .42, h * .3, w * .16, h * .1), 1, 1);
  }

  void _kran() {
    _footprint(.2, .5);
    final steel = _stroke(const Color(0xFFE5A23A), w * .05);
    c.drawLine(Offset(w * .45, h * .9), Offset(w * .45, h * .2), steel);
    c.drawLine(Offset(w * .45, h * .2), Offset(w * .95, h * .3), steel);
    c.drawLine(Offset(w * .45, h * .2), Offset(w * .15, h * .26), steel);
    for (var i = 0; i < 6; i++) {
      c.drawLine(Offset(w * .41, h * (.85 - i * .11)), Offset(w * .49, h * (.8 - i * .11)), _stroke(const Color(0xFFB57A20), w * .02));
    }
    c.drawLine(Offset(w * .9, h * .3), Offset(w * .9, h * .6), _stroke(const Color(0xFF2B2B2B), w * .015));
    c.drawRect(Rect.fromLTWH(w * .82, h * .6, w * .16, h * .06), _p..color = const Color(0xFF2B2B2B));
    c.drawRect(Rect.fromLTWH(w * .32, h * .22, w * .22, h * .1), _p..color = const Color(0xFF34474F)); // the cab
  }

  void _fyr() {
    _footprint(.15, .7);
    final tower = Path()..moveTo(w * .32, h * .88)..lineTo(w * .4, h * .24)..lineTo(w * .6, h * .24)..lineTo(w * .68, h * .88)..close();
    c.drawPath(tower, _p..color = const Color(0xFFF5F3EF));
    c.save();
    c.clipPath(tower);
    for (var i = 0; i < 3; i++) {
      c.drawRect(Rect.fromLTWH(0, h * (.36 + i * .2), w, h * .08), _p..color = const Color(0xFFC0392B));
    }
    c.restore();
    c.drawRect(Rect.fromLTWH(w * .38, h * .14, w * .24, h * .1), _p..color = look.lightsOn ? look.lights : const Color(0xFFBFE3EC));
    c.drawPath(Path()..moveTo(w * .34, h * .14)..lineTo(w / 2, h * .04)..lineTo(w * .66, h * .14)..close(), _p..color = _ink);
    c.drawPath(tower, _stroke(_outline, w * .02));
  }

  void _akvariet() {
    _footprint(.05, .9);
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(w * .08, h * .36, w * .84, h * .52), Radius.circular(w * .04));
    c.drawRRect(body, _p..color = const Color(0xFFD9D4C8));
    c.drawRect(Rect.fromLTWH(w * .12, h * .46, w * .76, h * .22), _p..color = look.lightsOn ? const Color(0xFF7FCFE0) : const Color(0xFF4C8796)); // the glass
    c.drawArc(Rect.fromLTWH(w * .3, h * .14, w * .4, h * .44), math.pi, math.pi, false, _stroke(const Color(0xFF9FB4B8), w * .04));
    c.drawPath(Path()..moveTo(w * .44, h * .57)..quadraticBezierTo(w * .5, h * .5, w * .58, h * .57)..lineTo(w * .62, h * .53)..lineTo(w * .62, h * .61)..close(),
        _p..color = const Color(0xFFF2B93B)); // a fish in the window
  }

  void _festningen() {
    _footprint(.04, .92);
    final stone = _p..color = const Color(0xFF8D8A80);
    c.drawRect(Rect.fromLTWH(w * .06, h * .5, w * .88, h * .38), stone);
    for (var i = 0; i < 6; i++) {
      c.drawRect(Rect.fromLTWH(w * (.06 + i * .16), h * .44, w * .09, h * .08), stone); // battlements
    }
    c.drawRect(Rect.fromLTWH(w * .32, h * .2, w * .36, h * .32), _p..color = const Color(0xFF9E9A8E));
    c.drawPath(Path()..moveTo(w * .28, h * .22)..lineTo(w / 2, h * .06)..lineTo(w * .72, h * .22)..close(), _p..color = const Color(0xFF3F5A4A));
    c.drawRect(Rect.fromLTWH(w * .44, h * .66, w * .12, h * .22), _p..color = _ink);
    _windows(Rect.fromLTWH(w * .34, h * .26, w * .32, h * .18), 3, 1);
  }

  void _seilskute() {
    _hull(_HullColours.egen, 1, w / 2, h * .74, h / 14);
    c.drawLine(Offset(w / 2, h * .7), Offset(w / 2, h * .04), _stroke(const Color(0xFF5E3A1C), w * .03));
    for (var i = 0; i < 3; i++) {
      final y = h * (.1 + i * .17), sw = w * (.34 - i * .04);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w / 2 - sw, y, sw * 2, h * .14), Radius.circular(w * .04)), _p..color = const Color(0xFFF2EBDD));
      c.drawLine(Offset(w / 2 - sw, y), Offset(w / 2 + sw, y), _stroke(const Color(0xFF5E3A1C), w * .015));
    }
    c.drawPath(Path()..moveTo(w / 2, h * .04)..lineTo(w * .66, h * .07)..lineTo(w / 2, h * .1)..close(), _p..color = const Color(0xFFC0392B));
  }

  void _verftet() {
    _footprint(.05, .9);
    c.drawRect(Rect.fromLTWH(w * .08, h * .4, w * .84, h * .48), _p..color = const Color(0xFFEFE4CC));
    c.drawPath(Path()..moveTo(w * .05, h * .42)..lineTo(w * .3, h * .2)..lineTo(w * .3, h * .42)..lineTo(w * .55, h * .2)..lineTo(w * .55, h * .42)..lineTo(w * .8, h * .2)..lineTo(w * .95, h * .42)..close(),
        _p..color = const Color(0xFF5A4A3E)); // the shed roofs
    c.drawRect(Rect.fromLTWH(w * .4, h * .6, w * .2, h * .28), _p..color = const Color(0xFF34474F)); // the slipway door
    _windows(Rect.fromLTWH(w * .12, h * .48, w * .76, h * .1), 5, 1);
    c.drawLine(Offset(w * .82, h * .4), Offset(w * .82, h * .06), _stroke(const Color(0xFF8D3B2A), w * .05)); // the chimney
  }

  void _sjobad() {
    _footprint(.04, .92);
    final deck = _p..color = const Color(0xFFC9A57A);
    c.drawRect(Rect.fromLTWH(w * .06, h * .5, w * .88, h * .14), deck);
    c.drawRect(Rect.fromLTWH(w * .06, h * .5, w * .1, h * .38), deck);
    c.drawRect(Rect.fromLTWH(w * .84, h * .5, w * .1, h * .38), deck);
    c.drawRect(Rect.fromLTWH(w * .2, h * .22, w * .2, h * .28), _p..color = const Color(0xFFEFE4CC)); // the bath house
    c.drawPath(Path()..moveTo(w * .17, h * .24)..lineTo(w * .3, h * .1)..lineTo(w * .43, h * .24)..close(), _p..color = const Color(0xFF2A6272));
    c.drawLine(Offset(w * .7, h * .5), Offset(w * .7, h * .16), _stroke(const Color(0xFFF5F3EF), w * .025)); // the diving tower
    c.drawLine(Offset(w * .7, h * .18), Offset(w * .84, h * .18), _stroke(const Color(0xFFF5F3EF), w * .025));
    c.drawLine(Offset(w * .66, h * .36), Offset(w * .78, h * .36), _stroke(const Color(0xFFF5F3EF), w * .025));
  }
}

class _HullColours {
  const _HullColours(this.u0, this.u1, this.ripe, this.i0, this.i1, this.sp, this.str);

  final Color u0, u1, ripe, i0, i1, sp, str;

  /// `skrogSprite` F, per level: the rowing boat (Bronse, Sølv), the snekke (Gull), the own boat (Platina).
  static const ro = _HullColours(Color(0xFFB07A45), Color(0xFF4A2A12), Color(0xFFDDA66A), Color(0xFF93602F), Color(0xFF5E3A1C), Color(0x80281406), Color(0xFF2A6272));
  static const snekke = _HullColours(Color(0xFFFFFFFF), Color(0xFFB9C7CC), Color(0xFF2A6272), Color(0xFFC99862), Color(0xFF9A6A3C), Color(0x5246280E), Color(0xFF2A6272));
  static const egen = _HullColours(Color(0xFF3F8A9E), Color(0xFF0F2E37), Color(0xFFF2C14E), Color(0xFFB58450), Color(0xFF7A4E26), Color(0x66321C0A), Color(0xFFF2C14E));
}
