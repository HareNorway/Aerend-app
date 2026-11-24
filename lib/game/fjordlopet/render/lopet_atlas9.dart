import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'lopet_look.dart';

/// Design (9) 1:1 plan D1: the play field's sprites are the design's own atlas.
///
/// `atlasBak` of `designs/21nov-kunde/proto/Fjordlopet.dc.html` was run at R = 3 and exported per sea mode
/// (`assets/game/fjordlopet/atlas9_kveld.png`, `atlas9_dag.png`; Regn uses Kveld, as the design: the same `P.lys`), with
/// its table in `atlas9.json` — per sprite the source rectangle in image pixels and the design's `ew, eh, ax, ay`
/// (size and anchor in design px; one design px = one logical px at M0 = 17). When the session opens, [build] draws that
/// image into one runtime atlas at the device's density and redraws what carries text or data, exactly as the design
/// draws it: the gate labels, the flags («Din beste», the rival, «Ukens beste»), the landmark name tags, «Din beste» over
/// the ghost, the Platina name, Ægil from the app's own asset, and the Gull/Platina hull.
class LopetAtlas9 {
  LopetAtlas9._(this.image, this.density, this.ids, this.src, this.geo);

  final ui.Image image;

  /// Image px per design px.
  final double density;
  final Map<String, int> ids;

  /// Per sprite: x0, y0, x1, y1 in image px.
  final Float32List src;

  /// Per sprite: ew, eh, ax, ay in design px.
  final Float32List geo;

  static const double m0 = 17;
  static const double kant = 30;

  static int live = 0;

  /// Tests set this false: Google Fonts loads asynchronously and reports a missing font after the test body.
  static bool googleFont = true;

  /// The sprite's index, or −1 (the design's `A[name]`; drawing −1 is a no-op).
  int id(String name) => ids[name] ?? -1;

  double ew(int i) => geo[i * 4];
  double eh(int i) => geo[i * 4 + 1];
  double ax(int i) => geo[i * 4 + 2];
  double ay(int i) => geo[i * 4 + 3];

  void dispose() {
    image.dispose();
    live--;
  }

  static Map<String, dynamic>? _meta;

  static Future<Map<String, dynamic>> _loadMeta() async =>
      _meta ??= jsonDecode(await rootBundle.loadString('assets/game/fjordlopet/atlas9.json')) as Map<String, dynamic>;

  static Future<ui.Image> _decode(String asset, {int? width}) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  /// [labels]: the three gate names (Bøye 1, Bøye 2, Bryggen) — drawn in capitals, gold for the last. [flags]: «Din
  /// beste», the rival's name ('' = none), «Ukens beste». [landmarks]: name per landmark id 0–7. [level]: Bronse, Sølv,
  /// Gull or Platina.
  static Future<LopetAtlas9> build({
    double density = 3,
    LopetMode mode = LopetMode.kveld,
    String level = 'Bronse',
    List<String> labels = const ['Bøye 1', 'Bøye 2', 'Bryggen'],
    List<String> flags = const ['Din beste', '', 'Ukens beste'],
    String ghost = 'Din beste',
    String name = '',
    Map<int, String> landmarks = const {},
  }) async {
    final meta = await _loadMeta();
    final r0 = (meta['R'] as num).toDouble();
    final iw = (meta['width'] as num).toDouble(), ih = (meta['height'] as num).toDouble();
    final d = density.clamp(1.0, r0).toDouble();
    final sc = d / r0;
    final base = await _decode(mode == LopetMode.dag ? 'assets/game/fjordlopet/atlas9_dag.png' : 'assets/game/fjordlopet/atlas9_kveld.png');
    final hull = level == 'Gull' || level == 'Platina' ? await _decode('assets/game/fjordlopet/skrog_${level.toLowerCase()}.png') : null;
    ui.Image? aegil;
    try {
      aegil = await _decode('assets/images/aegil/rear.png');
    } catch (_) {}
    if (googleFont) {
      try {
        await GoogleFonts.pendingFonts([GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)]);
      } catch (_) {}
    }

    final sprites = (meta['sprites'] as Map).cast<String, dynamic>();
    final ids = <String, int>{};
    final srcL = <double>[], geoL = <double>[];
    void put(String n, double x0, double y0, double x1, double y1, double ew, double eh, double ax, double ay) {
      final i = ids[n] ?? ids.length;
      ids[n] = i;
      if (i * 4 >= srcL.length) {
        srcL.addAll([0, 0, 0, 0]);
        geoL.addAll([0, 0, 0, 0]);
      }
      srcL.setAll(i * 4, [x0, y0, x1, y1]);
      geoL.setAll(i * 4, [ew, eh, ax, ay]);
    }

    sprites.forEach((n, v) {
      final l = (v as List).map((e) => (e as num).toDouble()).toList();
      put(n, l[0] * sc, l[1] * sc, l[2] * sc, l[3] * sc, l[4], l[5], l[6], l[7]);
    });

    // The runtime sprites go on shelves under the exported image (design px × d), 2 px apart as the design's.
    final shelfY0 = ih * sc + 4;
    var px = 0.0, py = shelfY0, rh = 0.0;
    final maxW = iw * sc;
    final jobs = <(double, double, double, double, double, double, void Function(Canvas))>[];
    void e(String n, double ew, double eh, double ax, double ay, void Function(Canvas) f) {
      final pw = (ew * d).ceilToDouble() + 4, ph = (eh * d).ceilToDouble() + 4;
      if (px + pw > maxW) {
        px = 0;
        py += rh;
        rh = 0;
      }
      put(n, px + 2, py + 2, px + 2 + ew * d, py + 2 + eh * d, ew, eh, ax, ay);
      jobs.add((px + 2, py + 2, ew * d, eh * d, ax, ay, f));
      px += pw;
      rh = math.max(rh, ph);
    }

    // Plus Jakarta Sans 800 as the design's `F(size)`; the platform font if Google Fonts cannot give it (tests, offline).
    TextStyle font(double size, {Color? color, Paint? foreground}) {
      if (googleFont) {
        try {
          return GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: FontWeight.w800, color: color, foreground: foreground, height: 1);
        } catch (_) {}
      }
      return TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color, foreground: foreground, height: 1);
    }

    TextPainter tp(String s, double size, Color c, {Paint? stroke}) {
      final style = stroke == null ? font(size, color: c) : font(size, foreground: stroke);
      return TextPainter(text: TextSpan(text: s, style: style), textDirection: TextDirection.ltr)..layout();
    }

    // Text drawn on its middle line, as canvas `textBaseline = 'middle'`.
    void text(Canvas g, String s, double size, Color c, double x, double y, {String align = 'center', double strokeW = 0, Color? strokeC}) {
      if (s.isEmpty) return;
      final fill = tp(s, size, c);
      final w = fill.width;
      final x0 = align == 'left' ? x : align == 'right' ? x - w : x - w / 2;
      final y0 = y - fill.height / 2;
      if (strokeW > 0) {
        final st = tp(s, size, c, stroke: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeJoin = StrokeJoin.round
          ..color = strokeC ?? c);
        st.paint(g, Offset(x0, y0));
      }
      fill.paint(g, Offset(x0, y0));
    }

    double measure(String s, double size) => s.isEmpty ? 0 : tp(s, size, const Color(0xFFFFFFFF)).width;
    RRect rr(double x, double y, double w, double h, double r) => RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

    const mint = Color(0xFF5CE0B8), gold = Color(0xFFF2C14E), cream = Color(0xFFF5F3EF);
    // portTx: the gate labels (the design's PORTER names in capitals; the last gate is gold).
    for (var i = 0; i < 3; i++) {
      final c = i == 2 ? gold : mint, tx = (i < labels.length ? labels[i] : '').toUpperCase();
      final tw = measure(tx, 11.5) + 24;
      e('portTx$i', tw + 3, 26, tw / 2 + 1.5, 13, (g) {
        g.drawRRect(rr(-tw / 2, -11.5, tw, 23, 11.5), Paint()..color = const Color(0xE60A2128));
        g.drawRRect(rr(-tw / 2, -11.5, tw, 23, 11.5), Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = c);
        text(g, tx, 11.5, c, 0, .5);
      });
    }
    // flagg0–2: tFlagg with no line (the dashed line is drawn per frame by `strek`).
    const flagW = 150.0;
    for (final (n, tx, c, dir) in [('flagg0', flags[0], mint, 1.0), ('flagg1', flags[1], cream, -1.0), ('flagg2', flags[2], gold, -1.0)]) {
      if (tx.isEmpty) continue;
      e(n, flagW, 42, dir > 0 ? 8 : flagW - 8, 34, (g) {
        g.drawCircle(Offset.zero, 5, Paint()..color = cream);
        g.drawLine(Offset.zero, const Offset(0, -30), Paint()
          ..color = cream
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round);
        g.drawPath(Path()
          ..moveTo(0, -30)
          ..lineTo(dir * 22, -24)
          ..lineTo(0, -18)
          ..close(), Paint()..color = c);
        text(g, tx, 10.5, c, dir * 7, -8, align: dir > 0 ? 'left' : 'right', strokeW: 3, strokeC: const Color(0xD90A2128));
      });
    }
    e('skyggeTx', 74, 17, 37, 8.5, (g) => text(g, ghost, 10.5, const Color(0xFFD4FBEB), 0, 0, strokeW: 3, strokeC: const Color(0xD90A2128)));
    final nm = name.toUpperCase();
    e('platina', 50, 10, 25, 5, (g) => text(g, nm.length > 6 ? nm.substring(0, 6) : nm, 6, gold, 0, 0));
    for (var i = 0; i < 8; i++) {
      final nv = landmarks[i] ?? '';
      final tw = measure(nv, 9.5) + 12;
      e('lmTx$i', tw + 2, 16, tw / 2 + 1, 0, (g) {
        if (nv.isEmpty) return;
        g.drawRRect(rr(-tw / 2, .5, tw, 15, 7.5), Paint()..color = const Color(0xDB0A2128));
        text(g, nv, 9.5, cream, 0, 8.3);
      });
    }

    final outH = (py + rh + 4).ceil();
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final hq = Paint()..filterQuality = FilterQuality.high;
    c.drawImageRect(base, Rect.fromLTWH(0, 0, iw, ih), Rect.fromLTWH(0, 0, iw * sc, ih * sc), hq);
    // The hull for Gull and Platina (Bronse and Sølv share the exported one).
    if (hull != null) {
      final i = ids['skrog']!;
      final r = Rect.fromLTRB(srcL[i * 4], srcL[i * 4 + 1], srcL[i * 4 + 2], srcL[i * 4 + 3]).inflate(2 * sc);
      c.drawRect(r, Paint()..blendMode = BlendMode.clear);
      c.drawImageRect(hull, Rect.fromLTWH(0, 0, hull.width.toDouble(), hull.height.toDouble()), Rect.fromLTRB(srcL[i * 4], srcL[i * 4 + 1], srcL[i * 4 + 2], srcL[i * 4 + 3]), hq);
    }
    // Ægil from behind, the design's crop of rear.png (55, 8, 250 × 224 of 360 × 360).
    if (aegil != null) {
      final i = ids['aegil']!;
      final k = aegil.width / 360;
      c.drawImageRect(aegil, Rect.fromLTWH(55 * k, 8 * k, 250 * k, 224 * k), Rect.fromLTRB(srcL[i * 4], srcL[i * 4 + 1], srcL[i * 4 + 2], srcL[i * 4 + 3]), hq);
    }
    for (final (x, y, pw, ph, ax, ay, f) in jobs) {
      c.save();
      c.clipRect(Rect.fromLTWH(x - 2, y - 2, pw + 4, ph + 4));
      c.translate(x, y);
      c.scale(d);
      c.translate(ax, ay);
      f(c);
      c.restore();
    }
    final img = await rec.endRecording().toImage(maxW.ceil(), outH);
    base.dispose();
    hull?.dispose();
    aegil?.dispose();
    live++;
    return LopetAtlas9._(img, d, ids, Float32List.fromList(srcL), Float32List.fromList(geoL));
  }
}
