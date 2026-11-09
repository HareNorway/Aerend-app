import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

// ── Heat plan Step 6: shader hosts without per-frame rebuilds ──────────────
// A shader host (SjoWater, SpGl, MegStadion, AegilFloyen) renders each step
// offscreen into an image, as before. With [BergenPerf.malerVertPaa] the image
// goes into a [MalerRamme] and a [MalerVert] draws it: a new frame only marks
// that one render object for paint — no setState, no build, no LayoutBuilder
// rebuild per step. Off, the host keeps its setState + RawImage path.

/// The newest frame of a shader host. Owns its image: [sett] disposes the
/// frame it replaces (after the swap, so a paint never sees a disposed one;
/// a picture already recorded keeps its own reference, as with RawImage).
class MalerRamme extends ChangeNotifier {
  ui.Image? _bilde;
  bool _borte = false;

  ui.Image? get bilde => _bilde;

  /// Shows [bilde] (owned from now on) and disposes the frame before it.
  void sett(ui.Image? bilde) {
    if (_borte) {
      bilde?.dispose();
      return;
    }
    final old = _bilde;
    if (identical(old, bilde)) return;
    _bilde = bilde;
    notifyListeners();
    old?.dispose();
  }

  @override
  void dispose() {
    _borte = true;
    final b = _bilde;
    _bilde = null;
    b?.dispose();
    super.dispose();
  }
}

/// Draws a [MalerRamme] exactly as `RawImage(image:, width:, height:,
/// fit: BoxFit.fill, filterQuality:)` draws its image: the same size rule
/// (tight [width] × [height] within the constraints) and the same
/// `paintImage` call at `offset & size` (scale 1, opacity 1, no colour
/// filter, centre alignment, no repeat, no flip, invertColors false,
/// isAntiAlias false, srcOver). A RenderBox rather than a CustomPaint:
/// RenderCustomPaint translates the canvas by the offset before painting,
/// RenderImage passes the offset in the rect — kept as RenderImage does it.
class MalerVert extends LeafRenderObjectWidget {
  const MalerVert({super.key, required this.ramme, required this.width, required this.height, this.filterQuality = FilterQuality.medium});

  final MalerRamme ramme;
  final double width, height;
  final FilterQuality filterQuality;

  @override
  RenderMalerVert createRenderObject(BuildContext context) => RenderMalerVert(ramme: ramme, width: width, height: height, filterQuality: filterQuality);

  @override
  void updateRenderObject(BuildContext context, RenderMalerVert renderObject) {
    renderObject
      ..ramme = ramme
      ..width = width
      ..height = height
      ..filterQuality = filterQuality;
  }
}

class RenderMalerVert extends RenderBox {
  RenderMalerVert({required MalerRamme ramme, required double width, required double height, required FilterQuality filterQuality})
    : _ramme = ramme,
      _width = width,
      _height = height,
      _filterQuality = filterQuality;

  MalerRamme _ramme;
  MalerRamme get ramme => _ramme;
  set ramme(MalerRamme v) {
    if (identical(v, _ramme)) return;
    if (attached) {
      _ramme.removeListener(markNeedsPaint);
      v.addListener(markNeedsPaint);
    }
    _ramme = v;
    markNeedsPaint();
  }

  double _width, _height;
  set width(double v) {
    if (v == _width) return;
    _width = v;
    markNeedsLayout();
  }

  set height(double v) {
    if (v == _height) return;
    _height = v;
    markNeedsLayout();
  }

  FilterQuality _filterQuality;
  set filterQuality(FilterQuality v) {
    if (v == _filterQuality) return;
    _filterQuality = v;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _ramme.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _ramme.removeListener(markNeedsPaint);
    super.detach();
  }

  // RenderImage._sizeForConstraints with both width and height given: the
  // image's own size never matters (so a new frame needs no layout).
  Size _sizeFor(BoxConstraints c) => BoxConstraints.tightFor(width: _width, height: _height).enforce(c).smallest;

  @override
  double computeMinIntrinsicWidth(double height) => _sizeFor(BoxConstraints.tightForFinite(height: height)).width;

  @override
  double computeMaxIntrinsicWidth(double height) => _sizeFor(BoxConstraints.tightForFinite(height: height)).width;

  @override
  double computeMinIntrinsicHeight(double width) => _sizeFor(BoxConstraints.tightForFinite(width: width)).height;

  @override
  double computeMaxIntrinsicHeight(double width) => _sizeFor(BoxConstraints.tightForFinite(width: width)).height;

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  @protected
  Size computeDryLayout(covariant BoxConstraints constraints) => _sizeFor(constraints);

  @override
  void performLayout() {
    size = _sizeFor(constraints);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final img = _ramme.bilde;
    if (img == null) return;
    paintImage(
      canvas: context.canvas,
      rect: offset & size,
      image: img,
      scale: 1.0,
      opacity: 1.0,
      fit: BoxFit.fill,
      alignment: Alignment.center,
      repeat: ImageRepeat.noRepeat,
      flipHorizontally: false,
      invertColors: false,
      filterQuality: _filterQuality,
      isAntiAlias: false,
    );
  }
}

/// The exact splits of Step 6: a static value (positive, below 2) baked once
/// per key is kept bit for bit as four base-256 digits of its half, one
/// 8-bit texture per digit, written by the bake shaders' `lv()` and read back
/// by the live shaders' `dk()` (`shaders/*_bake.frag`, `*_delt.frag`). Four
/// bake passes, one per digit.
const int malerNivaaer = 4;

/// Frames drawn through a split's live shader so far (a counter for the
/// tests and the harness; nothing reads it in the app).
int malerDeltRammer = 0;
