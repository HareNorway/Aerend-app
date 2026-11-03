import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'bergen_perf.dart';

/// Perf plan: draws [child] — including any opacity, shader mask, image
/// filter or backdrop blur inside it — from a raster made once, instead of
/// re-rendering those offscreen passes on every frame.
///
/// Impeller has no raster cache: an `Opacity`, `ShaderMask`, `ImageFiltered`
/// or `BackdropFilter` costs its own render pass (target, flush, resolve) on
/// every frame anything on the screen moves, even when its content never
/// changes. Measured on the Vivo V40: 73 such passes per frame on Hjem, 34 on
/// Kategori.
///
/// [BergenBakt] is a repaint boundary that paints its subtree once, at the
/// subtree's on-screen device scale, into an image, and draws that image
/// (with [opacity] applied to it, the same group opacity an `Opacity` gives).
/// It paints again only when something inside it repaints or its size or
/// scale changes. It falls back to painting live when the subtree contains
/// its own repaint boundary (that layer could update on its own and would
/// be frozen in the raster), when it repaints on most frames (an animation
/// inside), or when it is too big.
///
/// [margin] widens the raster beyond the child's box for what the child
/// paints outside it (shadows, glows, a blur's spread); too small a margin
/// would clip it, so callers set it from their own shadow and blur sizes.
///
/// A backdrop blur inside the subtree blurs what the subtree itself painted
/// beneath it; use it only where that is all the blur sees on screen.
class BergenBakt extends SingleChildRenderObjectWidget {
  const BergenBakt({super.key, this.opacity = 1, this.margin = EdgeInsets.zero, super.child});

  final double opacity;
  final EdgeInsets margin;

  /// Off: every BergenBakt paints live (harness `bakt: false`, A/B on one build).
  static bool paa = true;

  /// Rasters made, live fallbacks — for the perf heartbeat.
  static int laget = 0, levende = 0;
  static bool _registrert = false;

  @override
  RenderObject createRenderObject(BuildContext context) {
    if (!_registrert) {
      _registrert = true;
      BergenPerf.pulsTillegg.add(() => 'bakt=${laget}r/${levende}l');
    }
    return _RenderBakt(opacity, margin);
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {
    (renderObject as _RenderBakt)
      ..opacity = opacity
      ..margin = margin;
  }
}

class _RenderBakt extends RenderProxyBox {
  _RenderBakt(this._opacity, this._margin);

  double _opacity;
  EdgeInsets _margin;

  ui.Image? _bilde;
  Size? _bildeStr;
  double? _bildeSkala;

  /// Something inside repainted (not only the opacity changed).
  bool _skitten = true;
  bool _iAlfa = false;

  /// Rasters made in quick succession (< 300 ms apart), and paints left to
  /// draw live after too many; [_vekk] tries the raster again once the
  /// subtree has been still for 600 ms.
  int _serie = 0, _pause = 0;
  final Stopwatch _klokke = Stopwatch()..start();
  int _sistMs = -100000;
  Timer? _vekk;

  static const int _maksPiksler = 2400000;

  set opacity(double v) {
    if (v == _opacity) return;
    _opacity = v;
    _iAlfa = true;
    markNeedsPaint();
    _iAlfa = false;
  }

  set margin(EdgeInsets v) {
    if (v == _margin) return;
    _margin = v;
    markNeedsPaint();
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  bool get alwaysNeedsCompositing => false;

  @override
  void markNeedsPaint() {
    if (!_iAlfa) _skitten = true;
    super.markNeedsPaint();
  }

  @override
  void detach() {
    _vekk?.cancel();
    _slipp();
    super.detach();
  }

  @override
  void dispose() {
    _vekk?.cancel();
    _slipp();
    super.dispose();
  }

  void _vekkSenere() {
    _vekk?.cancel();
    _vekk = Timer(const Duration(milliseconds: 600), () {
      if (!attached) return;
      _pause = 0;
      _serie = 0;
      markNeedsPaint();
    });
  }

  void _slipp() {
    _bilde?.dispose();
    _bilde = null;
    _bildeStr = null;
    _bildeSkala = null;
  }

  double? _skala() {
    final Matrix4 m;
    try {
      m = getTransformTo(null);
    } catch (_) {
      return null;
    }
    final s = m.storage;
    final dpr = ui.PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 2;
    double r;
    if (s[3].abs() > 1e-6 || s[7].abs() > 1e-6 || (s[15] - 1).abs() > 1e-6) {
      // Under a perspective (a card tilted in 3D): the largest on-screen
      // scale over the box, from its projected corners (+10 % headroom so
      // the near edge is never upsampled).
      final box = Offset.zero & size;
      if (box.isEmpty) return null;
      final Rect p;
      try {
        p = MatrixUtils.transformRect(m, box);
      } catch (_) {
        return null;
      }
      if (!p.isFinite) return null;
      r = math.max(p.width / box.width, p.height / box.height) * 1.1 * dpr;
    } else {
      final sx = math.sqrt(s[0] * s[0] + s[1] * s[1]), sy = math.sqrt(s[4] * s[4] + s[5] * s[5]);
      r = math.max(sx, sy) * dpr;
    }
    if (!r.isFinite || r <= 0 || r > 8) return null;
    return (r * 16).round() / 16;
  }

  static bool _harGrense(RenderObject r) {
    var funnet = false;
    r.visitChildren((c) {
      if (funnet) return;
      if (c.isRepaintBoundary || _harGrense(c)) funnet = true;
    });
    return funnet;
  }

  Rect get _grenser => _margin.inflateRect(Offset.zero & size);

  void _live(PaintingContext context, Offset offset) {
    if (_opacity >= 1) {
      super.paint(context, offset);
    } else {
      context.pushOpacity(offset, (_opacity * 255).round(), super.paint);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null || _opacity <= 0) {
      _skitten = false;
      return;
    }
    if (!BergenBakt.paa || _pause > 0) {
      if (_pause > 0) {
        _pause--;
        _vekkSenere();
      }
      _slipp();
      _skitten = false;
      _live(context, offset);
      return;
    }
    final r = _skala();
    final b = _grenser;
    if (r == null || b.width * b.height * r * r > _maksPiksler || child.isRepaintBoundary || _harGrense(child)) {
      _slipp();
      _skitten = false;
      _live(context, offset);
      return;
    }
    if (_bilde == null || _skitten || _bildeStr != size || _bildeSkala != r) {
      final naa = _klokke.elapsedMilliseconds;
      _serie = naa - _sistMs < 300 ? _serie + 1 : 1;
      _sistMs = naa;
      if (_serie > 3) {
        // It repaints on most frames: an animation inside. Live for a while.
        _serie = 0;
        _pause = 90;
        BergenBakt.levende++;
        _vekkSenere();
        _slipp();
        _skitten = false;
        _live(context, offset);
        return;
      }
      _slipp();
      final lag = OffsetLayer();
      // ignore: invalid_use_of_protected_member
      final c = PaintingContext(lag, b);
      super.paint(c, Offset.zero);
      // ignore: invalid_use_of_protected_member
      c.stopRecordingIfNeeded();
      _bilde = lag.toImageSync(b, pixelRatio: r);
      lag.dispose();
      _bildeStr = size;
      _bildeSkala = r;
      BergenBakt.laget++;
    }
    _skitten = false;
    final img = _bilde!;
    context.canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromLTWH(offset.dx + b.left, offset.dy + b.top, img.width / r, img.height / r),
      Paint()
        ..filterQuality = FilterQuality.low
        ..color = Color.fromRGBO(0, 0, 0, _opacity.clamp(0.0, 1.0)),
    );
  }
}
