import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

// ── Vågen water (shared) ────────────────────────────────────────────────────
// The prototype's `canvas[data-sjogl]` (sjoGlInit / sjoGlTegn), ported to
// `shaders/sjo.frag`. Rendered offscreen each frame at ≤2× the CSS px (as the
// prototype caps it) and drawn scaled; reflects a baked Bryggen image the
// way `sjoRefBr` does. Used by the onboarding welcome scene, Hjem's hero and
// (later) Fjordfiske.

/// `sjoPal(m)`.
class SjoPalette {
  const SjoPalette({
    required this.deep,
    required this.shal,
    required this.skyHi,
    required this.skyLo,
    required this.fog,
    required this.fogA,
    required this.sun,
    required this.l,
    required this.pow,
    required this.sunA,
    required this.amp,
    required this.refl,
  });

  final Color deep, shal, skyHi, skyLo, fog, sun;
  final double fogA, pow, sunA, amp, refl;
  final List<double> l;

  static const dag = SjoPalette(
    deep: Color(0xFF245866),
    shal: Color(0xFF6FAFBD),
    skyHi: Color(0xFF7FB6CE),
    skyLo: Color(0xFFE6F0F2),
    fog: Color(0xFFD3E3E7),
    fogA: .14,
    sun: Color(0xFFFFF6DC),
    l: [.42, .3, 1],
    pow: 380,
    sunA: 2.2,
    amp: .9,
    refl: 1,
  );

  static const kveld = SjoPalette(
    deep: Color(0xFF19434F),
    shal: Color(0xFF4C8796),
    skyHi: Color(0xFF6A8A96),
    skyLo: Color(0xFFC2D2D6),
    fog: Color(0xFFA9BCC2),
    fogA: .18,
    sun: Color(0xFFFFE2B6),
    l: [-.32, .2, 1],
    pow: 90,
    sunA: .3,
    amp: 1,
    refl: .96,
  );

  static const regn = SjoPalette(
    deep: Color(0xFF192E36),
    shal: Color(0xFF45616B),
    skyHi: Color(0xFF6C7F87),
    skyLo: Color(0xFFAEBABD),
    fog: Color(0xFF98A7AB),
    fogA: .28,
    sun: Color(0xFFE8EEF0),
    l: [0, .5, 1],
    pow: 24,
    sunA: .1,
    amp: .8,
    refl: .88,
  );
}

/// One water ripple (`uRip`): position in the canvas' CSS px, start time
/// (water clock, s) and amplitude.
class SjoRipple {
  SjoRipple(this.x, this.y, this.t0, this.a);
  final double x, y, t0, a;
}

/// Lets the owner drop ripples (`sjoRippelPkt`) and read the water clock.
class SjoRipples extends ChangeNotifier {
  final List<SjoRipple> _list = [];
  double clock = 0;

  /// Up to six live ripples, as the prototype keeps.
  void add(double x, double y, double a) {
    _list.add(SjoRipple(x, y, clock, a));
    if (_list.length > 6) _list.removeAt(0);
  }

  List<SjoRipple> live(double t) {
    _list.removeWhere((r) => t - r.t0 >= 5);
    return _list;
  }
}

class SjoWater extends StatefulWidget {
  const SjoWater({
    super.key,
    required this.palette,
    required this.regn,
    required this.reflection,
    required this.reflectionHeight,
    required this.fogColor,
    this.ripples,
    this.onTick,
    this.maxPixels,
  });

  /// `_sgBud`: the prototype caps the pixels it shades per frame
  /// (`dpr = min(2, √(budget / (w·h)))`, never below .3). Null = ≤2×.
  final double? maxPixels;

  final SjoPalette palette;

  /// `uRegn`: 1 in the rain palette, .5 with rain over another sea, else 0.
  final double regn;

  /// The Bryggen image the water mirrors, and its CSS height (`Hb`).
  final String reflection;
  final double reflectionHeight;

  /// `brPal().skB` — fills the reflection texture behind Bryggen.
  final Color fogColor;

  final SjoRipples? ripples;

  /// Called every frame with the water clock (s) — the owner's ripple timer.
  final void Function(double t)? onTick;

  @override
  State<SjoWater> createState() => _SjoWaterState();
}

class _SjoWaterState extends State<SjoWater> with SingleTickerProviderStateMixin {
  static Future<ui.FragmentProgram>? _program;
  static final Map<String, Future<ui.Image>> _reflections = {};

  ui.FragmentShader? _shader;
  ui.Image? _ref;
  ui.Image? _frame;
  late final Ticker _ticker;
  Duration _prev = Duration.zero;
  double _t = 0;
  bool _reduce = false;
  Size _size = Size.zero;
  double _dpr = 2;

  String get _refKey => '${widget.reflection}|${widget.reflectionHeight}|${widget.fogColor.toARGB32()}';

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _program ??= ui.FragmentProgram.fromAsset('shaders/sjo.frag');
    _load();
  }

  void _load() {
    final key = _refKey;
    final ref = _reflections[key] ??= _bake(widget.reflection, widget.reflectionHeight, widget.fogColor);
    Future.wait([_program!, ref]).then((v) {
      if (!mounted || key != _refKey) return;
      _shader ??= (v[0] as ui.FragmentProgram).fragmentShader();
      _ref = v[1] as ui.Image;
      _render();
      if (!_reduce && !_ticker.isActive) _ticker.start();
    }).catchError((_) {});
  }

  @override
  void didUpdateWidget(SjoWater old) {
    super.didUpdateWidget(old);
    if (old.reflection != widget.reflection ||
        old.reflectionHeight != widget.reflectionHeight ||
        old.fogColor != widget.fogColor) {
      _load();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.disableAnimationsOf(context);
    _dpr = math.min(2.0, MediaQuery.devicePixelRatioOf(context));
    if (_reduce && _ticker.isActive) _ticker.stop();
    if (!_reduce && !_ticker.isActive && _shader != null) _ticker.start();
  }

  void _tick(Duration e) {
    final dt = ((e - _prev).inMicroseconds / 1e6).clamp(0.0, .05);
    _prev = e;
    _t += dt;
    widget.ripples?.clock = _t;
    widget.onTick?.call(_t);
    _render();
  }

  /// `sjoRefBr`: Bryggen flipped from its waterline up into 512×256, on the
  /// fog colour.
  static Future<ui.Image> _bake(String asset, double hb, Color fog) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final br = (await codec.getNextFrame()).image;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.drawRect(const Rect.fromLTWH(0, 0, 512, 256), Paint()..color = fog);
    final m = Matrix4.identity()
      ..setEntry(0, 0, 512 / 390)
      ..setEntry(1, 1, -1.28)
      ..setEntry(1, 3, 1.28 * hb);
    c.transform(Float64List.fromList(m.storage));
    c.drawImageRect(
      br,
      Rect.fromLTWH(0, 0, br.width.toDouble(), br.height.toDouble()),
      Rect.fromLTWH(0, 0, 390, hb),
      Paint()..filterQuality = FilterQuality.medium,
    );
    final img = rec.endRecording().toImageSync(512, 256);
    br.dispose();
    return img;
  }

  void _render() {
    final sh = _shader, ref = _ref;
    if (sh == null || ref == null || _size.isEmpty) return;
    final w = _size.width, h = _size.height;
    var dpr = _dpr;
    final bud = widget.maxPixels;
    if (bud != null && w * h > 0) dpr = math.max(.3, math.min(dpr, math.sqrt(bud / (w * h))));
    final pw = (w * dpr).round(), ph = (h * dpr).round();
    if (pw <= 0 || ph <= 0) return;
    final p = widget.palette;
    var i = 0;
    void f(double v) => sh.setFloat(i++, v);
    void c(Color col) {
      f(col.r);
      f(col.g);
      f(col.b);
    }

    f(w);
    f(h);
    f(pw / w);
    f(_t % 3600);
    f(40); // uHz
    f(400); // uF
    f(120); // uZ0
    f(p.amp);
    f(p.pow);
    f(p.sunA);
    f(p.fogA);
    f(widget.regn);
    f(p.refl);
    c(p.deep);
    c(p.shal);
    c(p.skyHi);
    c(p.skyLo);
    c(p.fog);
    c(p.sun);
    final ll = math.sqrt(p.l[0] * p.l[0] + p.l[1] * p.l[1] + p.l[2] * p.l[2]);
    f(p.l[0] / ll);
    f(p.l[1] / ll);
    f(p.l[2] / ll);
    final rips = widget.ripples?.live(_t) ?? const <SjoRipple>[];
    for (var k = 0; k < 6; k++) {
      if (k < rips.length) {
        final r = rips[k];
        f(r.x);
        f(r.y);
        f(_t - r.t0);
        f(r.a);
      } else {
        f(0);
        f(0);
        f(0);
        f(0);
      }
    }
    f(-9999); // uDons.x — no boat wake yet
    f(0);
    sh.setImageSampler(0, ref);
    final rec = ui.PictureRecorder();
    Canvas(rec).drawRect(Rect.fromLTWH(0, 0, pw.toDouble(), ph.toDouble()), Paint()..shader = sh);
    final img = rec.endRecording().toImageSync(pw, ph);
    final old = _frame;
    setState(() => _frame = img);
    old?.dispose();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame?.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final s = box.biggest;
        if (s != _size) {
          _size = s;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _frame == null) _render();
          });
        }
        final img = _frame;
        if (img == null) return const SizedBox.expand();
        return RawImage(
          image: img,
          width: s.width,
          height: s.height,
          fit: BoxFit.fill,
          filterQuality: FilterQuality.medium,
        );
      },
    );
  }
}
