import 'dart:math' as math;
import 'dart:ui';

/// An SVG path `d` string as a [Path]: M L H V C S Q T A Z, absolute and
/// relative, implicit repeats.
Path svgSti(String d) {
  final p = Path();
  final tok = RegExp(r'[MLHVCSQTAZmlhvcsqtaz]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?').allMatches(d).map((m) => m.group(0)!).toList();
  var i = 0;
  var cmd = 'M';
  double x = 0, y = 0, sx = 0, sy = 0;
  // Last control point, for S/T reflection.
  double? cx2, cy2;
  String prev = '';
  bool isCmd(String t) => RegExp(r'^[A-Za-z]$').hasMatch(t);
  double n() => double.parse(tok[i++]);
  bool flag() {
    // Arc flags may be packed ("011"): take one character at a time.
    final t = tok[i];
    if (t.length > 1 && (t.startsWith('0') || t.startsWith('1')) && !t.contains('.')) {
      tok[i] = t.substring(1);
      return t[0] == '1';
    }
    i++;
    return t == '1';
  }

  while (i < tok.length) {
    if (isCmd(tok[i])) {
      cmd = tok[i++];
      if (cmd == 'Z' || cmd == 'z') {
        p.close();
        x = sx;
        y = sy;
        prev = 'Z';
        continue;
      }
    }
    final rel = cmd == cmd.toLowerCase();
    final c = cmd.toUpperCase();
    final ox = rel ? x : 0.0, oy = rel ? y : 0.0;
    switch (c) {
      case 'M':
        x = ox + n();
        y = oy + n();
        p.moveTo(x, y);
        sx = x;
        sy = y;
        cmd = rel ? 'l' : 'L';
      case 'L':
        x = ox + n();
        y = oy + n();
        p.lineTo(x, y);
      case 'H':
        x = (rel ? x : 0) + n();
        p.lineTo(x, y);
      case 'V':
        y = (rel ? y : 0) + n();
        p.lineTo(x, y);
      case 'C':
        final a = ox + n(), b = oy + n(), c1 = ox + n(), d1 = oy + n();
        x = ox + n();
        y = oy + n();
        p.cubicTo(a, b, c1, d1, x, y);
        cx2 = c1;
        cy2 = d1;
      case 'S':
        final r1x = (prev == 'C' || prev == 'S') && cx2 != null ? 2 * x - cx2 : x;
        final r1y = (prev == 'C' || prev == 'S') && cy2 != null ? 2 * y - cy2 : y;
        final c1 = ox + n(), d1 = oy + n();
        x = ox + n();
        y = oy + n();
        p.cubicTo(r1x, r1y, c1, d1, x, y);
        cx2 = c1;
        cy2 = d1;
      case 'Q':
        final a = ox + n(), b = oy + n();
        x = ox + n();
        y = oy + n();
        p.quadraticBezierTo(a, b, x, y);
        cx2 = a;
        cy2 = b;
      case 'T':
        final a = (prev == 'Q' || prev == 'T') && cx2 != null ? 2 * x - cx2 : x;
        final b = (prev == 'Q' || prev == 'T') && cy2 != null ? 2 * y - cy2 : y;
        x = ox + n();
        y = oy + n();
        p.quadraticBezierTo(a, b, x, y);
        cx2 = a;
        cy2 = b;
      case 'A':
        final rx = n(), ry = n(), rot = n();
        final large = flag(), sweep = flag();
        x = ox + n();
        y = oy + n();
        p.arcToPoint(Offset(x, y), radius: Radius.elliptical(rx, ry), rotation: rot, largeArc: large, clockwise: sweep);
      default:
        i++;
    }
    prev = c;
  }
  return p;
}

/// [path] cut into dashes (`stroke-dasharray`), shifted by [offset].
Path svgStreker(Path path, List<double> dash, double offset) {
  final out = Path();
  final total = dash.fold<double>(0, (a, b) => a + b);
  if (total <= 0) return path;
  for (final m in path.computeMetrics()) {
    // A negative dash offset moves the pattern forward along the path.
    var d = -(offset % total);
    var k = 0;
    while (d < m.length) {
      final len = dash[k % dash.length];
      final on = k.isEven;
      if (on) {
        final a = math.max(0.0, d), b = math.min(m.length, d + len);
        if (b > a) out.addPath(m.extractPath(a, b), Offset.zero);
      }
      d += len;
      k++;
    }
  }
  return out;
}
