import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

// ── faneBytt: the tab change ("Umulig trapp", prototype L17934) ────────────
// The old screen breaks into five bands that step down and away (tipping
// back, 300ms, 30ms apart); the new one comes down from above in five bands
// and lands (320ms from 60ms). Both screens are snapshotted once and the
// bands are drawn from the snapshots, so neither screen renders five times.
//
// A tab is built the first time it is opened and then kept (offstage, its
// tickers paused) while another tab is up, so coming back shows it as it was
// instead of loading it from nothing. The screens refresh themselves when they
// become active again ([BergenFaneBytte.aktiv]).

class BergenFaneBytte extends StatefulWidget {
  const BergenFaneBytte({super.key, required this.index, required this.builder, required this.background});

  final int index;
  final Widget Function(BuildContext context, int index) builder;

  /// What shows between the bands (the screen behind the tabs).
  final Gradient background;

  /// The tab that is up (for kept tabs that refresh when shown again).
  static final ValueNotifier<int> aktiv = ValueNotifier<int>(0);

  @override
  State<BergenFaneBytte> createState() => _BergenFaneBytteState();
}

class _BergenFaneBytteState extends State<BergenFaneBytte> with TickerProviderStateMixin {
  /// One snapshot boundary per kept tab.
  final Map<int, GlobalKey> _flater = {};
  GlobalKey _flate(int i) => _flater.putIfAbsent(i, GlobalKey.new);

  /// The tabs built so far (kept while another one is up).
  final Set<int> _bygd = {};
  late int _aktiv = widget.index;
  late final AnimationController _c;
  ui.Image? _gml, _ny;
  bool _dekk = false;
  int _dir = 1;

  int _seq = 0;

  /// Reduced motion (the user's calm setting, or `still` from heat or power
  /// saving): no bands, a short cross-fade instead of a hard cut, which reads
  /// as a blink. [_forrige] is the tab fading out underneath.
  late final AnimationController _f = AnimationController(vsync: this, duration: const Duration(milliseconds: 180), value: 1);
  int? _forrige;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _bygd.add(_aktiv);
    BergenFaneBytte.aktiv.value = _aktiv;
  }

  void _vis(int til) {
    _aktiv = til;
    _bygd.add(til);
    BergenFaneBytte.aktiv.value = til;
  }

  @override
  void didUpdateWidget(BergenFaneBytte old) {
    super.didUpdateWidget(old);
    if (widget.index == _aktiv || widget.index == _mot) return;
    final til = widget.index;
    if (MediaQuery.disableAnimationsOf(context)) {
      _tone(til);
      return;
    }
    _bytt(til);
  }

  void _tone(int til) {
    ++_seq;
    _mot = null;
    _c.stop();
    _rydd();
    setState(() {
      _dekk = false;
      _forrige = _aktiv;
      _vis(til);
    });
    _f.forward(from: 0).whenCompleteOrCancel(() {
      if (mounted && _f.isCompleted) setState(() => _forrige = null);
    });
  }

  /// The tab we're switching to while the old one is being snapshotted.
  int? _mot;

  Future<void> _bytt(int til) async {
    final seq = ++_seq;
    _mot = til;
    _c.stop();
    _f.value = 1;
    _forrige = null;
    _rydd();
    // The old screen stays up until its picture is ready (one frame).
    final gml = await _bilde();
    if (!mounted || seq != _seq) {
      gml?.dispose();
      return;
    }
    _dir = til > _aktiv ? 1 : -1;
    // Back to the start before the cover shows: left at the end of the last
    // switch, the cover's first frames drew the old bands already fallen
    // away and the new ones not yet there — the bare background, a blink.
    _c.value = 0;
    setState(() {
      _gml = gml;
      _vis(til);
      _mot = null;
      _dekk = gml != null;
    });
    if (gml == null) return;
    // The new screen paints under the cover; picture it once it has.
    await SchedulerBinding.instance.endOfFrame;
    final ny = await _bilde();
    if (!mounted || seq != _seq) {
      ny?.dispose();
      return;
    }
    setState(() => _ny = ny);
    await _c.forward(from: 0).orCancel.catchError((_) {});
    if (!mounted || seq != _seq) return;
    setState(() => _dekk = false);
    _rydd();
  }

  Future<ui.Image?> _bilde() async {
    final ro = _flate(_aktiv).currentContext?.findRenderObject();
    if (ro is! RenderRepaintBoundary || !ro.hasSize) return null;
    try {
      // At the screen's own density: a lower one is softer than the live
      // screen, which then visibly sharpens when the bands hand back.
      final gpu = await ro.toImage(pixelRatio: MediaQuery.devicePixelRatioOf(context));
      // Re-upload as a plain RGBA image: the layer snapshot's own texture
      // drops out when it is clipped or faded.
      final data = await gpu.toByteData(format: ui.ImageByteFormat.rawRgba);
      final w = gpu.width, h = gpu.height;
      gpu.dispose();
      if (data == null) return null;
      final done = Completer<ui.Image>();
      ui.decodeImageFromPixels(data.buffer.asUint8List(), w, h, ui.PixelFormat.rgba8888, done.complete);
      return await done.future;
    } catch (_) {
      return null;
    }
  }

  void _rydd() {
    _gml?.dispose();
    _ny?.dispose();
    _gml = _ny = null;
  }

  @override
  void dispose() {
    _c.dispose();
    _f.dispose();
    _rydd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // The active tab last (on top of the one fading out); keyed, so the
        // reorder keeps every tab's state.
        for (final i in (_bygd.toList()..sort((a, b) => a == _aktiv ? 1 : (b == _aktiv ? -1 : a.compareTo(b)))))
          Offstage(
            key: ValueKey('fane-$i'),
            offstage: i != _aktiv && i != _forrige,
            child: TickerMode(
              enabled: i == _aktiv,
              child: FadeTransition(
                opacity: i == _aktiv && _forrige != null ? _f : kAlwaysCompleteAnimation,
                child: RepaintBoundary(
                  key: _flate(i),
                  child: KeyedSubtree(key: ValueKey(i), child: widget.builder(context, i)),
                ),
              ),
            ),
          ),
        if (_dekk)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => _trapp(context, _c.value * 500),
              ),
            ),
          ),
      ],
    );
  }

  static const int _n = 5;
  static const Cubic _eo = Cubic(.6, 0, .3, 1), _ei = Cubic(.2, .8, .1, 1);

  /// Both screens in five bands each, the new ones over the old.
  Widget _trapp(BuildContext context, double ms) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        final bh = size.height / _n;
        final c = size.center(Offset.zero);
        Widget band(ui.Image img, int i, double tx, double ty, double tz, double rx, double a) {
          if (a <= 0) return const SizedBox.shrink();
          final m = Matrix4.identity()
            ..translateByDouble(c.dx, c.dy, 0, 1)
            ..multiply(Matrix4.identity()..setEntry(3, 2, -1 / 1100))
            ..translateByDouble(tx, ty, tz, 1)
            ..rotateX(rx * math.pi / 180)
            ..translateByDouble(-c.dx, -c.dy, 0, 1);
          return Positioned.fill(
            child: Transform(
              transform: m,
              child: ClipRect(
                clipper: _Band(i * bh, bh + .5),
                child: RawImage(
                  image: img,
                  width: size.width,
                  height: size.height,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.low,
                  opacity: AlwaysStoppedAnimation(a.clamp(0.0, 1.0)),
                ),
              ),
            ),
          );
        }

        final g = _gml, n = _ny;
        return Stack(
          children: [
            Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: widget.background))),
            if (g != null)
              for (var i = 0; i < _n; i++)
                () {
                  final e = _eo.transform(((ms - i * 30) / 300).clamp(0.0, 1.0));
                  return band(g, i, 20 * _dir * e, bh * .9 * e, -60 * e, -40 * e, 1 - e);
                }(),
            if (n != null)
              for (var i = 0; i < _n; i++)
                () {
                  final e = _ei.transform(((ms - 60 - i * 30) / 320).clamp(0.0, 1.0));
                  final k = 1 - e;
                  return band(n, i, -20 * _dir * k, -bh * .9 * k, 60 * k, 40 * k, e);
                }(),
          ],
        );
      },
    );
  }
}

class _Band extends CustomClipper<Rect> {
  const _Band(this.top, this.h);
  final double top, h;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, top, size.width, h);

  @override
  bool shouldReclip(covariant _Band old) => old.top != top || old.h != h;
}
