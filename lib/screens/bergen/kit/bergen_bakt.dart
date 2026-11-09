import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
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
  const BergenBakt({super.key, this.opacity = 1, this.margin = EdgeInsets.zero, this.skalaToleranse = 0, super.child});

  final double opacity;
  final EdgeInsets margin;

  /// A raster made at a scale within this fraction of the current one is
  /// reused (0 = exact). Only for soft content (radial glows, blurred
  /// shadows) under an animated scale, where resampling cannot be seen.
  final double skalaToleranse;

  /// Off: every BergenBakt paints live (harness `bakt: false`, A/B on one build).
  static bool paa = true;

  /// Heat Step 7 ([BergenPerf.pass2BaktPaa]): the raster is chosen when the
  /// scene is built (see [_BaktLag]), only in a real frame. Tests that read
  /// pixels back with `toImage` outside a frame set this to use it there too.
  @visibleForTesting
  static bool debugRutenettUtenforRamme = false;

  /// Rasters made, live fallbacks — for the perf heartbeat.
  static int laget = 0, levende = 0;
  static bool _registrert = false;

  @override
  RenderObject createRenderObject(BuildContext context) {
    if (!_registrert) {
      _registrert = true;
      BergenPerf.pulsTillegg.add(() => 'bakt=${laget}r/${levende}l');
    }
    return _RenderBakt(opacity, margin, skalaToleranse);
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {
    (renderObject as _RenderBakt)
      ..opacity = opacity
      ..margin = margin
      ..toleranse = skalaToleranse;
  }
}

class _RenderBakt extends RenderProxyBox {
  _RenderBakt(this._opacity, this._margin, this.toleranse);

  double _opacity;
  EdgeInsets _margin;
  double toleranse;

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

  /// Heat Step 7: with [BergenPerf.pass2BaktPaa] on when the layer is made, the
  /// boundary's layer is a [_BaktLag] (it acts as a plain [OffsetLayer]
  /// whenever the old path paints into it).
  @override
  OffsetLayer updateCompositedLayer({required covariant OffsetLayer? oldLayer}) =>
      oldLayer ?? (BergenPerf.pass2BaktPaa ? _BaktLag() : OffsetLayer());

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

  /// Heat Step 7: records the child into [_BaktLag.innhold] (only when
  /// something inside repainted) and hands the layer the opacity and bounds;
  /// the layer decides per scene whether its raster lands on exactly the
  /// pixels live painting would cover, and otherwise adds the content live.
  void _malRutenett(PaintingContext context, Offset offset, _BaktLag lag) {
    _slipp();
    final child = this.child;
    lag.rutenett = true;
    if (child == null || _opacity <= 0) {
      // Nothing shows. [_skitten] stays set, so a change made meanwhile is
      // recorded once the box shows again.
      lag.alfa = 0;
      return;
    }
    var inn = lag.innhold;
    if (inn == null || _skitten) {
      inn = lag.nyttInnhold();
      context.pushLayer(inn, super.paint, offset);
    } else {
      context.addLayer(inn);
    }
    _skitten = false;
    lag
      ..alfa = Color.getAlphaFromOpacity(_opacity)
      ..grenser = _grenser.shift(offset)
      ..kan = !(child.isRepaintBoundary || _harGrense(child));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final lag = layer;
    if (lag is _BaktLag) {
      if (BergenPerf.pass2BaktPaa && BergenBakt.paa) {
        _malRutenett(context, offset, lag);
        return;
      }
      lag.rutenett = false;
    }
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
    // Under the frozen test clock (harness `klokke`) always the exact scale,
    // so screenshots don't depend on when the raster was first made.
    final tol = BergenPerf.frosset ? 0.0 : toleranse;
    final skalaUlik = _bildeSkala == null || (tol > 0 ? (r / _bildeSkala! - 1).abs() > tol : _bildeSkala != r);
    if (_bilde == null || _skitten || _bildeStr != size || skalaUlik) {
      final naa = _klokke.elapsedMilliseconds;
      _serie = naa - _sistMs < 300 ? _serie + 1 : 1;
      _sistMs = naa;
      // Under the frozen test clock never fall back to live painting: the
      // screenshot must not depend on start-up repaint timing.
      if (_serie > 3 && !BergenPerf.frosset) {
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
    final rb = _bildeSkala!;
    context.canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromLTWH(offset.dx + b.left, offset.dy + b.top, img.width / rb, img.height / rb),
      Paint()
        ..filterQuality = FilterQuality.low
        ..color = Color.fromRGBO(0, 0, 0, _opacity.clamp(0.0, 1.0)),
    );
  }
}

/// Heat Step 7 ([BergenPerf.pass2BaktPaa]): BergenBakt's layer, which puts the
/// raster on the device pixel grid exactly where live painting lands.
///
/// A raster drawn at a fractional device position (or at a rounded scale) is
/// resampled, and its edges differ from live painting (up to ~40/255
/// measured). Here the choice is made when the scene is built, from the
/// layer's real device transform (every layer above, the view's pixel ratio
/// included), because a parent boundary can move this one (a scroll, a
/// slide) without painting it again:
///
/// * The raster is made at exactly that scale, with the fractional part of
///   the device position baked into its own transform, and drawn 1:1 at an
///   integer device position, texel on pixel, with no filtering. Every
///   command inside lands on the same device coordinates as live: the same
///   coverage, the same glyph positions. Its origin is a multiple of 8 device
///   pixels, so Impeller's 8×8 ordered gradient dither (keyed on the target's
///   pixel coordinates) has the same phase as on the screen.
/// * Only under translate + uniform scale, wholly inside the screen and every
///   clip above (a clipped blur snapshots and downsamples from a different
///   origin), and under no layer that draws into its own offscreen (group
///   opacity, shader mask, colour or image filter, backdrop, a clip with
///   saveLayer: the dither phase there is that offscreen's). Anywhere else,
///   and while the transform or content changes on most frames, the content
///   is added live: what an `Opacity` would draw.
/// * The opacity is the same integer alpha an `OpacityLayer` applies.
///
/// What remains (each ≤ 1/255): the raster stores the content once in 8 bits
/// before it is blended, which a live group opacity does too (its offscreen
/// layer) — but at opacity 1, where live content is drawn straight onto the
/// screen, a translucent pixel is rounded once more; and below 1 a live
/// `Opacity` dithers gradients at its own offscreen's origin (set by the
/// content's bounds), so gradient content can differ in a dither pattern.
class _BaktLag extends OffsetLayer {
  /// The child's painting, kept for live frames and for making the raster.
  final LayerHandle<OffsetLayer> _innHandle = LayerHandle<OffsetLayer>();

  /// Set by the render object on every paint.
  bool rutenett = false;
  int alfa = 255;
  Rect grenser = Rect.zero;
  bool kan = false;

  /// Bumped whenever the content is recorded again.
  int _versjon = 0;

  ui.Image? _bilde;
  ui.Picture? _tegning;
  int _tegningAlfa = -1;
  double _sk = 0, _fx = 0, _fy = 0;
  int _bildeVersjon = -1;
  Rect _bildeGrenser = Rect.zero;
  ui.OpacityEngineLayer? _opLag;

  /// Misses less than 300 ms apart; after more than 3 the content is added
  /// live until its device position, scale and content have held for 600 ms.
  int _serie = 0;
  int _sistBomMs = -100000;
  bool _levende = false;
  int _nokkelSidenMs = 0;
  (double, double, double, int, Rect)? _sistNokkel;

  static const int _maksPiksler = 2400000;

  OffsetLayer? get innhold => _innHandle.layer;

  OffsetLayer nyttInnhold() {
    _versjon++;
    return _innHandle.layer ??= OffsetLayer();
  }

  @override
  bool get alwaysNeedsAddToScene => rutenett;

  @override
  void markNeedsAddToScene() {
    // Added to every scene anyway (see [alwaysNeedsAddToScene]).
    if (rutenett) return;
    super.markNeedsAddToScene();
  }

  void _slippBilde() {
    _tegning?.dispose();
    _tegning = null;
    _tegningAlfa = -1;
    _bilde?.dispose();
    _bilde = null;
    _bildeVersjon = -1;
  }

  @override
  void dispose() {
    _slippBilde();
    _opLag?.dispose();
    _opLag = null;
    _innHandle.layer = null;
    super.dispose();
  }

  @override
  void addToScene(ui.SceneBuilder builder) {
    if (!rutenett) {
      // The old path painted into this layer: a plain OffsetLayer.
      _slippBilde();
      super.addToScene(builder);
      return;
    }
    engineLayer = builder.pushOffset(offset.dx, offset.dy, oldLayer: engineLayer as ui.OffsetEngineLayer?);
    if (alfa > 0 && innhold != null) {
      final p = _velg();
      if (p != null) {
        builder.addPicture(Offset.zero, p);
      } else if (alfa < 255) {
        _opLag?.dispose();
        _opLag = builder.pushOpacity(alfa);
        addChildrenToScene(builder);
        builder.pop();
      } else {
        addChildrenToScene(builder);
      }
    }
    builder.pop();
  }

  /// The device transform of this layer's content and whether the raster may
  /// stand in for it here (see the class doc); null = add it live.
  Matrix4? _tilSkjerm() {
    final kjede = <ContainerLayer>[];
    ContainerLayer? l = this;
    while (l != null) {
      kjede.add(l);
      l = l.parent;
    }
    final view = ui.PlatformDispatcher.instance.implicitView;
    if (view == null) return null;
    var klipp = Offset.zero & view.physicalSize;
    final m = Matrix4.identity();
    for (var i = kjede.length - 1; i > 0; i--) {
      final c = kjede[i];
      Rect? lokal;
      if (c is ClipRectLayer) {
        if (c.clipBehavior == Clip.antiAliasWithSaveLayer) return null;
        lokal = c.clipRect;
      } else if (c is ClipRRectLayer) {
        if (c.clipBehavior == Clip.antiAliasWithSaveLayer) return null;
        lokal = c.clipRRect?.outerRect;
      } else if (c is ClipRSuperellipseLayer) {
        if (c.clipBehavior == Clip.antiAliasWithSaveLayer) return null;
        lokal = c.clipRSuperellipse?.outerRect;
      } else if (c is ClipPathLayer) {
        if (c.clipBehavior == Clip.antiAliasWithSaveLayer) return null;
        lokal = c.clipPath?.getBounds();
      } else if (c is OpacityLayer) {
        if ((c.alpha ?? 255) < 255) return null;
      } else if (c is ShaderMaskLayer || c is ColorFilterLayer || c is ImageFilterLayer || c is BackdropFilterLayer) {
        return null;
      }
      if (lokal != null) {
        if (!_flat(m)) return null;
        klipp = klipp.intersect(MatrixUtils.transformRect(m, lokal));
      }
      c.applyTransform(kjede[i - 1], m);
    }
    m.translateByDouble(offset.dx, offset.dy, 0, 1);
    if (!_flat(m)) return null;
    _klipp = klipp;
    return m;
  }

  Rect _klipp = Rect.zero;

  /// Translate + uniform positive scale only (no rotation, skew, perspective).
  static bool _flat(Matrix4 m) {
    final s = m.storage;
    if (s[1].abs() > 1e-9 || s[4].abs() > 1e-9 || s[3].abs() > 1e-9 || s[7].abs() > 1e-9 || (s[15] - 1).abs() > 1e-9) return false;
    return s[0] > 0 && (s[5] - s[0]).abs() <= s[0] * 1e-9;
  }

  ui.Picture? _velg() {
    if (!kan || !BergenPerf.pass2BaktPaa) return null;
    final fase = SchedulerBinding.instance.schedulerPhase;
    // A `toImage` of a boundary above builds its scene under its own
    // transform, which the layers here do not show: there, live.
    if (fase != SchedulerPhase.persistentCallbacks && !BergenBakt.debugRutenettUtenforRamme) return null;
    final m = _tilSkjerm();
    if (m == null) return null;
    final s = m.storage;
    final sk = s[0];
    final g = grenser;
    if (g.isEmpty || !sk.isFinite || sk > 8) return null;
    final dx = s[12] + sk * g.left, dy = s[13] + sk * g.top;
    if (!dx.isFinite || !dy.isFinite) return null;
    // Origin on a multiple of 8 device pixels (the gradient dither's phase).
    final ix = (dx / 8).floorToDouble() * 8, iy = (dy / 8).floorToDouble() * 8;
    final fx = dx - ix, fy = dy - iy;
    final w = (sk * g.width + fx - 1e-6).ceil(), h = (sk * g.height + fy - 1e-6).ceil();
    if (w <= 0 || h <= 0 || w * h > _maksPiksler) return null;
    final dev = Rect.fromLTWH(ix, iy, w.toDouble(), h.toDouble());
    if (!_inni(_klipp, dev)) return null;
    // The frame's vsync time: monotonic, and the test clock in tests.
    final naa = SchedulerBinding.instance.currentSystemFrameTimeStamp.inMilliseconds;
    final nokkel = (sk, fx, fy, _versjon, g);
    final like = _sistNokkel != null && _likNokkel(_sistNokkel!, nokkel);
    if (!like) {
      _sistNokkel = nokkel;
      _nokkelSidenMs = naa;
    }
    final treff = _bilde != null && _bildeVersjon == _versjon && _bildeGrenser == g && _likTall(_sk, sk) && _likTall(_fx, fx) && _likTall(_fy, fy);
    if (!treff) {
      if (!BergenPerf.frosset) {
        if (_levende) {
          // Live until it has held still for 600 ms.
          if (naa - _nokkelSidenMs < 600) return null;
          _levende = false;
          _serie = 0;
        }
        _serie = naa - _sistBomMs < 300 ? _serie + 1 : 1;
        _sistBomMs = naa;
        if (_serie > 3) {
          // It moves or changes on most frames: live for a while.
          _serie = 0;
          _levende = true;
          _nokkelSidenMs = naa;
          BergenBakt.levende++;
          _slippBilde();
          return null;
        }
      }
      _slippBilde();
      final inn = innhold!;
      final b = ui.SceneBuilder();
      // Content → raster: the device transform less the integer origin.
      b.pushTransform(Float64List.fromList([sk, 0, 0, 0, 0, sk, 0, 0, 0, 0, 1, 0, s[12] - ix, s[13] - iy, 0, 1]));
      final scene = inn.buildScene(b);
      _bilde = scene.toImageSync(w, h);
      scene.dispose();
      _sk = sk;
      _fx = fx;
      _fy = fy;
      _bildeVersjon = _versjon;
      _bildeGrenser = g;
      BergenBakt.laget++;
    }
    if (_tegning == null || _tegningAlfa != alfa) {
      _tegning?.dispose();
      final img = _bilde!;
      final rec = ui.PictureRecorder();
      // In content coordinates: (g.left - fx / sk) lands on device x = ix.
      Canvas(rec).drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromLTWH(g.left - fx / sk, g.top - fy / sk, img.width / sk, img.height / sk),
        Paint()
          ..filterQuality = FilterQuality.none
          ..color = Color.fromARGB(alfa, 0, 0, 0),
      );
      _tegning = rec.endRecording();
      _tegningAlfa = alfa;
    }
    return _tegning;
  }

  static bool _likTall(double a, double b) => (a - b).abs() <= 1e-6;

  static bool _likNokkel((double, double, double, int, Rect) a, (double, double, double, int, Rect) b) =>
      _likTall(a.$1, b.$1) && _likTall(a.$2, b.$2) && _likTall(a.$3, b.$3) && a.$4 == b.$4 && a.$5 == b.$5;

  static bool _inni(Rect ytre, Rect indre) =>
      indre.left >= ytre.left - 1e-6 && indre.top >= ytre.top - 1e-6 && indre.right <= ytre.right + 1e-6 && indre.bottom <= ytre.bottom + 1e-6;
}
