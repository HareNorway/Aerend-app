import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/widgets.dart';

import '../../screens/bergen/kit/bergen_perf.dart';
import 'bergen_modus.dart';

/// Lys plan Step 2: the switch moment everywhere but Hjem (design `modusSett`):
/// a picture of the old mode is frozen, the new mode is applied under it and
/// uncovered in a circle growing from the tap (760 ms, `cubic-bezier(.55,0,.18,1)`)
/// while the old picture scales 1 → .985 and dims to brightness .9 (to light) /
/// brightens to 1.08 (to dark). No picture within 300 ms → the design's fallback:
/// a colour wash in the new base colour grows from the tap (520 ms), the mode
/// changes under it, and the wash fades (380 ms). `still` (reduced motion, low
/// power) switches at once. A toast names the mode after every switch.
///
/// Mounted once around the app in `MaterialApp.builder`; one tree shape from
/// first to last frame (the 29 Oct remount rule), pointer-transparent.
class ModusAvduk extends StatefulWidget {
  const ModusAvduk({super.key, required this.child});

  final Widget child;

  /// The picture timeout (widget tests never finish `toImage`).
  static Duration bildeFrist = const Duration(milliseconds: 300);

  @override
  State<ModusAvduk> createState() => _ModusAvdukState();
}

const Cubic _avdukKurve = Cubic(.55, 0, .18, 1);
const Cubic _vaskKurve = Cubic(.4, 0, .2, 1);

class _ModusAvdukState extends State<ModusAvduk> with TickerProviderStateMixin implements ModusVert {
  final GlobalKey _rb = GlobalKey();
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 760));
  late final AnimationController _ut = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  ui.Image? _bilde;
  Offset _fra = Offset.zero;
  bool _tilLys = false;
  bool _vask = false;
  int _gen = 0;

  /// The pending `bruk` of a moment still playing: applied at once if this host goes away mid-switch.
  VoidCallback? _venter;

  @override
  void initState() {
    super.initState();
    BergenModus.i.registrer(this);
  }

  @override
  void dispose() {
    final v = _venter;
    _venter = null;
    v?.call();
    BergenModus.i.avregistrer(this);
    _a.dispose();
    _ut.dispose();
    _bilde?.dispose();
    super.dispose();
  }

  void _ferdig(bool lys) {
    if (kDebugMode) timeDilation = 1.0;
    if (!mounted) return;
    BergenModus.i.visToast?.call(lys);
  }

  void _rydd() {
    _bilde?.dispose();
    _bilde = null;
    _vask = false;
    _a.duration = const Duration(milliseconds: 760);
    _a.value = 0;
    _ut.value = 0;
  }

  @override
  bool spill({required bool lys, required Offset? fra, required ModusKilde kilde, required VoidCallback bruk}) {
    final gen = ++_gen;
    // A moment still playing ends at once (the design skips the running transition).
    final forrige = _venter;
    _venter = null;
    forrige?.call();
    _a.stop();
    _ut.stop();
    setState(_rydd);
    final size = MediaQuery.sizeOf(context);
    _fra = fra ?? size.center(Offset.zero);
    _tilLys = lys;
    if (BergenPerf.of(context) == BergenTier.still) {
      bruk();
      _ferdig(lys);
      return true;
    }
    var brukt = false;
    void brukEn() {
      if (brukt) return;
      brukt = true;
      if (_venter == brukEn) _venter = null;
      bruk();
    }

    _venter = brukEn;
    _ta(lys, gen, brukEn);
    return true;
  }

  Future<void> _ta(bool lys, int gen, VoidCallback bruk) async {
    ui.Image? bilde;
    try {
      final ro = _rb.currentContext?.findRenderObject();
      // `debugNeedsPaint` exists only with asserts on (debug); release/profile just take the picture.
      if (ro is RenderRepaintBoundary && ro.hasSize && (!kDebugMode || !ro.debugNeedsPaint)) {
        final dpr = math.min(MediaQuery.devicePixelRatioOf(context), 2.0);
        final f = ro.toImage(pixelRatio: dpr);
        bilde = await f.timeout(ModusAvduk.bildeFrist, onTimeout: () {
          // Too slow: the picture that arrives later is thrown away.
          f.then((i) => i.dispose(), onError: (_) {});
          throw TimeoutException('modus');
        });
      }
    } catch (_) {
      bilde = null;
    }
    if (!mounted || gen != _gen) {
      bilde?.dispose();
      return;
    }
    if (bilde == null) {
      _vaskSpill(lys, gen, bruk);
      return;
    }
    setState(() => _bilde = bilde);
    // The new mode goes in under the frozen picture, then the circle opens.
    bruk();
    await _a.animateTo(1, curve: Curves.linear);
    if (!mounted || gen != _gen) return;
    setState(_rydd);
    _ferdig(lys);
  }

  Future<void> _vaskSpill(bool lys, int gen, VoidCallback bruk) async {
    setState(() => _vask = true);
    unawaited(_a.animateTo(1, duration: const Duration(milliseconds: 520)));
    await Future<void>.delayed(const Duration(milliseconds: 530));
    if (!mounted || gen != _gen) return;
    bruk();
    await _ut.animateTo(1);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    if (!mounted || gen != _gen) return;
    setState(_rydd);
    _ferdig(lys);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        RepaintBoundary(key: _rb, child: widget.child),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: Listenable.merge([_a, _ut]),
              builder: (context, _) => CustomPaint(
                painter: _AvdukMaler(
                  bilde: _bilde,
                  vask: _vask,
                  tilLys: _tilLys,
                  fra: _fra,
                  t: _vask ? _vaskKurve.transform(_a.value) : _avdukKurve.transform(_a.value),
                  ut: _ut.value,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvdukMaler extends CustomPainter {
  _AvdukMaler({required this.bilde, required this.vask, required this.tilLys, required this.fra, required this.t, required this.ut});

  final ui.Image? bilde;
  final bool vask;
  final bool tilLys;
  final Offset fra;
  final double t;
  final double ut;

  double _r(Size s) => math.sqrt(math.pow(math.max(fra.dx, s.width - fra.dx), 2) + math.pow(math.max(fra.dy, s.height - fra.dy), 2)) + 12;

  @override
  void paint(Canvas canvas, Size size) {
    final b = bilde;
    if (b != null) {
      final r = _r(size) * t;
      final rect = Offset.zero & size;
      canvas.save();
      canvas.clipPath(Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(rect)
        ..addOval(Rect.fromCircle(center: fra, radius: r)));
      // `::view-transition-old(root)`: scale(1 → .985) around the middle, brightness(1 → .9 | 1.08).
      final sk = 1 - .015 * t;
      final br = 1 + ((tilLys ? .9 : 1.08) - 1) * t;
      canvas.translate(size.width / 2, size.height / 2);
      canvas.scale(sk);
      canvas.translate(-size.width / 2, -size.height / 2);
      final p = Paint()
        ..filterQuality = FilterQuality.medium
        ..colorFilter = ColorFilter.matrix(<double>[br, 0, 0, 0, 0, 0, br, 0, 0, 0, 0, 0, br, 0, 0, 0, 0, 0, 1, 0]);
      canvas.drawImageRect(b, Offset.zero & Size(b.width.toDouble(), b.height.toDouble()), rect, p);
      canvas.restore();
      return;
    }
    if (vask && t > 0) {
      final r = _r(size) * t;
      final rect = Offset.zero & size;
      final o = 1 - ut;
      if (o <= 0) return;
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: fra, radius: r)));
      if (tilLys) {
        // linear-gradient(180deg,#F7FBFD,#E7F5FA)
        canvas.drawRect(
          rect,
          Paint()
            ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
              const Color(0xFFF7FBFD).withValues(alpha: o),
              const Color(0xFFE7F5FA).withValues(alpha: o),
            ]),
        );
      } else {
        // radial-gradient(80% 50% at 14% 0%,rgba(255,255,255,.18),transparent 60%),linear-gradient(180deg,#2A6272,#1E4F5C 50%,#173E48)
        canvas.drawRect(
          rect,
          Paint()
            ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
              const Color(0xFF2A6272).withValues(alpha: o),
              const Color(0xFF1E4F5C).withValues(alpha: o),
              const Color(0xFF173E48).withValues(alpha: o),
            ], const [0, .5, 1]),
        );
        final c = Offset(size.width * .14, 0);
        final rx = size.width * .8;
        final ry = size.height * .5;
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.scale(1, ry / rx);
        canvas.drawCircle(
          Offset.zero,
          rx,
          Paint()
            ..shader = ui.Gradient.radial(Offset.zero, rx, [
              Color.fromRGBO(255, 255, 255, .18 * o),
              const Color.fromRGBO(255, 255, 255, 0),
            ], const [0, .6]),
        );
        canvas.restore();
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_AvdukMaler o) =>
      o.bilde != bilde || o.vask != vask || o.t != t || o.ut != ut || o.fra != fra || o.tilLys != tilLys;
}
