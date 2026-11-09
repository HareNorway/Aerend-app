import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'bergen_perf.dart';

/// Heat plan Step 8 ([BergenPerf.lagringPaa], harness `lagring`): our own
/// raster cache for Impeller, at a screen's root.
///
/// Impeller has no raster cache: whenever anything moves it re-runs every
/// drawing command of the whole screen. Flutter already keeps an unchanged
/// part of the screen as the same layers (the same `ui.Picture`s) from frame
/// to frame. [BergenLagring] reads its subtree's layer tree when the scene is
/// built, in paint order, and draws the leading run of layers that have not
/// changed for a few frames — everything from the bottom of the screen up to
/// the first layer that moves — from ONE image; the rest is added to the scene
/// live, as before, in the same order. See [_LagringLag] for why the pixels
/// are the same and what stays live.
///
/// The framework's layers are never detached or changed: the layer only
/// decides what it hands the scene builder. Off: a plain repaint boundary.
class BergenLagring extends SingleChildRenderObjectWidget {
  const BergenLagring({super.key, super.child});

  /// Tests that read pixels back with `toImage` outside a frame set this so
  /// the cached image is used there too (the scene under a root boundary at
  /// the origin, at the view's pixel ratio, has the screen's transform).
  @visibleForTesting
  static bool debugUtenforRamme = false;

  /// Frames a run must hold unchanged before it is rastered.
  static int stabileRammer = 3;

  /// Images made, frames drawn from an image, frames added live.
  static int laget = 0, treff = 0, levende = 0;

  /// Bytes held in cached images (all screens).
  static int get bytes => _Register.bytes;

  /// Cached images held (all screens).
  static int get bilder => _Register.alle.length;

  /// Drops every cached image (memory pressure, tests).
  static void tom() => _Register.tom();

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderLagring();
}

class _RenderLagring extends RenderProxyBox {
  @override
  bool get isRepaintBoundary => true;

  @override
  OffsetLayer updateCompositedLayer({required covariant OffsetLayer? oldLayer}) => oldLayer ?? _LagringLag();
}

/// The images held, the memory budget (≈ 2 screens), eviction when a screen
/// is no longer composited (covered by another route) or memory runs low.
abstract final class _Register {
  static final Set<_LagringLag> alle = {};
  static int bytes = 0;

  /// Bumped after every frame (a persistent frame callback, after the
  /// scene has been composited).
  static int ramme = 0;
  static bool _klar = false;

  static void sikre() {
    if (_klar) return;
    _klar = true;
    SchedulerBinding.instance.addPersistentFrameCallback(_etterRamme);
    WidgetsBinding.instance.addObserver(_Minne());
    BergenPerf.pulsTillegg.add(
      () => 'lagring=${alle.length}i/${(bytes / (1 << 20)).toStringAsFixed(1)}MB r=${BergenLagring.laget} h=${BergenLagring.treff} l=${BergenLagring.levende}',
    );
  }

  static void _etterRamme(Duration _) {
    for (final l in alle.toList()) {
      if (l._sistKomponert < ramme) {
        // Not in this frame's scene: its route is covered or gone.
        if (++l._uteRammer >= 2) l._slipp();
      } else {
        l._uteRammer = 0;
      }
    }
    ramme++;
  }

  static int get maksBytes {
    final v = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (v == null) return 40 << 20;
    return (v.physicalSize.width * v.physicalSize.height * 4 * 2).round();
  }

  /// Room for [b] more bytes for [ny], evicting the images composited
  /// longest ago first.
  static bool plass(_LagringLag ny, int b) {
    final andre = alle.where((l) => !identical(l, ny)).toList()..sort((a, c) => a._sistKomponert.compareTo(c._sistKomponert));
    var i = 0;
    while (bytes + b > maksBytes && i < andre.length) {
      andre[i++]._slipp();
    }
    return bytes + b <= maksBytes;
  }

  static void tom() {
    for (final l in alle.toList()) {
      l._slipp();
    }
  }
}

class _Minne with WidgetsBindingObserver {
  @override
  void didHaveMemoryPressure() => _Register.tom();
}

/// One drawable in paint order: a picture, or an effect layer (opacity,
/// shader mask, colour / image / backdrop filter) taken whole, or a layer
/// that must stay live.
class _Post {
  _Post(this.lag, this.sig, {required this.levende, this.bakteppe = false, this.lesBunn = false, this.bilder = 0});
  final Layer lag;

  /// Everything that decides its pixels: the containers above it (offsets,
  /// transforms, clips), its own properties, its picture(s).
  final List<Object?> sig;
  final bool levende;

  /// Holds a backdrop filter (it reads what is beneath it).
  final bool bakteppe;

  /// A [BergenLagringLive] subtree: draws with a blend mode that reads what
  /// is beneath it, so nothing beneath it may come from an upper-run image.
  final bool lesBunn;

  /// Pictures in it (how much drawing a run of it saves).
  final int bilder;
}

/// One cached run: its drawables, the chain it was made under, the image.
class _Bilde {
  _Bilde(this.poster, this.kjede, this.bilde, this.tegning, this.bytes, this.laget);
  final List<_Post> poster;
  final List<Object?> kjede;
  final ui.Image bilde;
  final ui.Picture tegning;
  final int bytes;
  final int laget;

  void dispose() {
    tegning.dispose();
    bilde.dispose();
  }
}

/// When a layer's signature last changed (frame number).
class _Spor {
  _Spor(this.sig, this.siden);
  List<Object?> sig;
  int siden;
}

bool _likSig(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Heat plan Step 8 ([BergenPerf.lagringOvrePaa]): keeps [child]'s layers
/// live inside a [BergenLagring], and caches no upper run beneath it.
///
/// For painting that blends with what is already on the screen (colour
/// dodge, overlay, soft light, multiply … drawn straight onto the canvas,
/// not inside a save layer of its own): an upper run's image is drawn on
/// transparent, so such a blend inside it would mix with nothing, and one
/// over it would amplify that image's rounding. Off (or with `lagringOvre`
/// off): just [child].
class BergenLagringLive extends StatelessWidget {
  const BergenLagringLive({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => BergenPerf.lagringPaa && BergenPerf.lagringOvrePaa ? _LiveGrense(child: child) : child;
}

class _LiveGrense extends SingleChildRenderObjectWidget {
  const _LiveGrense({super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderLiveGrense();
}

class _RenderLiveGrense extends RenderProxyBox {
  @override
  bool get isRepaintBoundary => true;

  @override
  OffsetLayer updateCompositedLayer({required covariant OffsetLayer? oldLayer}) => oldLayer ?? _LiveLag();
}

/// The layer of a [BergenLagringLive]: a plain offset layer the cache
/// recognises (always live, reads beneath).
class _LiveLag extends OffsetLayer {}

/// The layer at the root of a [BergenLagring].
///
/// **The runs.** In paint order, every maximal run of drawables unchanged for
/// [BergenLagring.stabileRammer] frames, between drawables that change (or
/// must stay live), is a candidate for one image: the bottom run always; the
/// runs above a live layer with [BergenPerf.lagringOvrePaa]. At most two
/// images per screen (the bottom run and the upper run with the most
/// pictures), within a budget of two screens for the whole app.
///
/// **The image.** A run is drawn into an image the size of the visible region
/// with exactly the scene-builder operations the screen uses for it: the same
/// ancestor transforms and clips (the view's pixel ratio included) and the
/// same containers above each of its drawables, the same pictures, the same
/// effect layers. Its origin is a multiple of 8 device pixels (Impeller's 8×8
/// gradient dither is keyed on the target's pixel coordinates). It is drawn
/// back 1:1 in device space, texel on pixel, no filtering, srcOver, at the
/// run's place in paint order; everything else is added live, in order.
///
/// **Pixels.** The bottom run is the bottom of the screen: nothing is painted
/// beneath this layer (checked: no earlier sibling of it or of any ancestor
/// holds a picture), so on the screen its commands run on an empty target,
/// exactly as in the image — same commands, device coordinates, clip
/// coverage (the image covers the whole visible region), dither phase, blur
/// snapshots and backdrops — and srcOver onto the empty screen copies it
/// unchanged: identical, except where a later translucent draw covers one of
/// its anti-aliased edges (≤ 1/255). An upper run is the same commands on a
/// transparent target, then blended: an opaque pixel of the run is identical;
/// a translucent one is rounded to 8 bits once more before the blend
/// (≤ 1/255). Accepted 2026-11-09 for upper runs, on two conditions kept
/// here: a backdrop filter in an upper run stays live (its backdrop is not in
/// the image), and no upper run is cached beneath a [BergenLagringLive]
/// subtree (blends that read the screen). Blend modes inside a save layer of
/// a picture, a shader mask or a colour filter read only their own content,
/// which is always in the same drawable, so the same run: those are fine.
///
/// **What stays live.** Every drawable that changed in the last frames (an
/// animation, a scroll, a new picture) and, always: platform views,
/// textures, leader/follower layers, layers rebuilt every frame
/// (`alwaysNeedsAddToScene`: BergenBakt, a nested BergenLagring), unknown
/// layer types, [BergenLagringLive] subtrees; a backdrop filter outside a
/// bottom run that covers the whole screen. The whole screen stays live
/// under a transform that is not 2D-affine, under a group opacity, shader
/// mask or filter above the root, under a rounded / path clip or a clip not
/// on whole device pixels above the root (the images are drawn inside those
/// clips again), outside the screen's own scene (`toImage`, SnapshotWidget),
/// and when something is painted beneath the root (with `lagringOvre`, the
/// bottom run is then treated as an upper run).
class _LagringLag extends OffsetLayer {
  /// The images, in paint order.
  List<_Bilde> _bilder = [];
  int _bytes = 0;

  int _sistKomponert = -1, _uteRammer = 0;

  /// The runs of the last frame (by their first drawable) and for how many
  /// frames each held unchanged.
  Map<Layer, (List<_Post>, int)> _kandidater = {};

  /// Frames a run must hold; doubled (to 60) when an image is thrown away
  /// within 30 frames of being made.
  int _kreves = BergenLagring.stabileRammer;

  final Expando<_Spor> _spor = Expando<_Spor>('lagringSpor');
  final Expando<int> _antall = Expando<int>('lagringAntall');

  /// Engine layers this layer pushed itself in the last scene (disposed when
  /// the next one is built, as the framework does with its own).
  final List<ui.EngineLayer> _motorlag = [];

  int _i = 0;

  /// The view root's engine layer at the last scene this layer was added to.
  ui.EngineLayer? _sistRotMotor;

  static const int _maksBilder = 2;

  @override
  bool get alwaysNeedsAddToScene => BergenPerf.lagringPaa;

  @override
  void markNeedsAddToScene() {
    // Added to every scene anyway (see [alwaysNeedsAddToScene]).
    if (alwaysNeedsAddToScene) return;
    super.markNeedsAddToScene();
  }

  void _slipp() {
    for (final b in _bilder) {
      b.dispose();
    }
    _bilder = [];
    if (_Register.alle.remove(this)) _Register.bytes -= _bytes;
    _bytes = 0;
  }

  void _slippEn(_Bilde b) {
    b.dispose();
    _bilder.remove(b);
    _bytes -= b.bytes;
    _Register.bytes -= b.bytes;
    if (_bilder.isEmpty) _Register.alle.remove(this);
  }

  @override
  void dispose() {
    _slipp();
    for (final e in _motorlag) {
      e.dispose();
    }
    _motorlag.clear();
    super.dispose();
  }

  @override
  void addToScene(ui.SceneBuilder builder) {
    if (!BergenPerf.lagringPaa) {
      _slipp();
      super.addToScene(builder);
      return;
    }
    _Register.sikre();
    _sistKomponert = _Register.ramme;
    for (final e in _motorlag) {
      e.dispose();
    }
    _motorlag.clear();
    engineLayer = builder.pushOffset(offset.dx, offset.dy, oldLayer: engineLayer as ui.OffsetEngineLayer?);
    final plan = _velg();
    if (plan == null) {
      BergenLagring.levende++;
      addChildrenToScene(builder);
    } else {
      BergenLagring.treff++;
      var fra = 0;
      for (final (start, b) in plan.$2) {
        if (start > fra) {
          _i = 0;
          _omraade(this, builder, fra, start, _motorlag, raster: false);
        }
        builder.addPicture(Offset.zero, b.tegning);
        fra = start + b.poster.length;
      }
      if (fra < plan.$1) {
        _i = 0;
        _omraade(this, builder, fra, plan.$1, _motorlag, raster: false);
      }
    }
    builder.pop();
  }

  // ── the layer types ──────────────────────────────────────────────────────

  /// A container whose own operation is a plain offset, transform or clip
  /// (no offscreen pass): its children are drawables of their own.
  static bool _gruppe(Layer l) {
    if (l.alwaysNeedsAddToScene) return false;
    final t = l.runtimeType;
    if (t == ContainerLayer || t == OffsetLayer || t == TransformLayer || t == ClipRectLayer || t == ClipRRectLayer || t == ClipRSuperellipseLayer || t == ClipPathLayer) {
      return true;
    }
    if (t == OpacityLayer) return (l as OpacityLayer).alpha == 255;
    return l is AnnotatedRegionLayer;
  }

  static List<Object?> _egenSig(ContainerLayer l) => switch (l) {
    TransformLayer t => ['T', t.offset, Matrix4.copy(t.transform!)],
    OpacityLayer o => ['A', o.alpha, o.offset, o.firstChild == null],
    ClipRectLayer c => ['R', c.clipRect, c.clipBehavior],
    ClipRRectLayer c => ['RR', c.clipRRect, c.clipBehavior],
    ClipRSuperellipseLayer c => ['RS', c.clipRSuperellipse, c.clipBehavior],
    ClipPathLayer c => ['P', c.clipPath, c.clipBehavior],
    OffsetLayer o => ['O', o.offset],
    _ => const ['C'],
  };

  /// Pushes [l]'s own operation exactly as its `addToScene` does; false when
  /// it pushes nothing (no pop).
  bool _pushEgen(ContainerLayer l, ui.SceneBuilder b, List<ui.EngineLayer> motor) {
    final ui.EngineLayer e;
    switch (l) {
      case TransformLayer t:
        var m = t.transform!;
        if (t.offset != Offset.zero) m = Matrix4.translationValues(t.offset.dx, t.offset.dy, 0)..multiply(m);
        e = b.pushTransform(m.storage);
      case OpacityLayer o:
        // At 255 an OpacityLayer pushes an offset (none without a child).
        if (o.firstChild == null) return false;
        e = b.pushOffset(o.offset.dx, o.offset.dy);
      case ClipRectLayer c:
        e = b.pushClipRect(c.clipRect!, clipBehavior: c.clipBehavior);
      case ClipRRectLayer c:
        e = b.pushClipRRect(c.clipRRect!, clipBehavior: c.clipBehavior);
      case ClipRSuperellipseLayer c:
        e = b.pushClipRSuperellipse(c.clipRSuperellipse!, clipBehavior: c.clipBehavior);
      case ClipPathLayer c:
        e = b.pushClipPath(c.clipPath!, clipBehavior: c.clipBehavior);
      case OffsetLayer o:
        e = b.pushOffset(o.offset.dx, o.offset.dy);
      default:
        return false;
    }
    motor.add(e);
    return true;
  }

  /// The signature of an effect layer taken whole (its properties and every
  /// drawable inside), or null when something inside must stay live.
  /// [f]: [0] holds a backdrop filter, [1] holds a [BergenLagringLive],
  /// [2] counts pictures.
  static List<Object?>? _helSig(Layer l, List<int> f) {
    if (l is PictureLayer) {
      f[2]++;
      return ['p', l.picture, l.isComplexHint, l.willChangeHint];
    }
    if (l is _LiveLag) {
      f[1] = 1;
      return null;
    }
    if (l.alwaysNeedsAddToScene) return null;
    final List<Object?> s;
    if (_gruppe(l)) {
      s = _egenSig(l as ContainerLayer);
    } else if (l.runtimeType == OpacityLayer) {
      final o = l as OpacityLayer;
      s = ['a', o.alpha, o.offset];
    } else if (l.runtimeType == ShaderMaskLayer) {
      final m = l as ShaderMaskLayer;
      s = ['m', m.shader, m.maskRect, m.blendMode];
    } else if (l.runtimeType == ColorFilterLayer) {
      s = ['c', (l as ColorFilterLayer).colorFilter];
    } else if (l.runtimeType == ImageFilterLayer) {
      final i = l as ImageFilterLayer;
      s = ['f', i.imageFilter, i.offset];
    } else if (l.runtimeType == BackdropFilterLayer) {
      final b = l as BackdropFilterLayer;
      f[0] = 1;
      // A backdrop key (BackdropGroup) shares one backdrop across layers.
      s = ['b', b.filter, b.blendMode, b];
    } else {
      return null;
    }
    s.add('(');
    for (Layer? c = (l as ContainerLayer).firstChild; c != null; c = c.nextSibling) {
      final cs = _helSig(c, f);
      if (cs == null) return null;
      s.addAll(cs);
    }
    s.add(')');
    return s;
  }

  /// Flattens [c]'s subtree into drawables in paint order; returns how many.
  int _flat(ContainerLayer c, List<Object?> sti, List<_Post> ut) {
    var n = 0;
    for (Layer? l = c.firstChild; l != null; l = l.nextSibling) {
      int m;
      if (l is PictureLayer) {
        if (l.picture == null) {
          m = 0;
        } else {
          ut.add(_Post(l, [...sti, 'p', l.picture, l.isComplexHint, l.willChangeHint], levende: false, bilder: 1));
          m = 1;
        }
      } else if (_gruppe(l)) {
        m = _flat(l as ContainerLayer, [...sti, ..._egenSig(l)], ut);
      } else {
        final f = [0, 0, 0];
        final s = _helSig(l, f);
        ut.add(_Post(
          l,
          s == null ? [...sti, 'live', l] : [...sti, ...s],
          levende: s == null,
          bakteppe: f[0] == 1,
          lesBunn: f[1] == 1,
          bilder: f[2],
        ));
        m = 1;
      }
      _antall[l] = m;
      n += m;
    }
    return n;
  }

  /// Something already drawn in [l]'s subtree (a picture or a live leaf).
  static bool _harInnhold(Layer l) {
    if (l is ContainerLayer) {
      for (Layer? c = l.firstChild; c != null; c = c.nextSibling) {
        if (_harInnhold(c)) return true;
      }
      return false;
    }
    return true;
  }

  static bool _helPiksel(double v) => (v - v.roundToDouble()).abs() < 1e-3;

  // ── choosing ─────────────────────────────────────────────────────────────

  /// This scene's plan — the number of drawables and the images to draw at
  /// their start index — or null: all live.
  (int, List<(int, _Bilde)>)? _velg() {
    if (debugDisableClipLayers || debugDisableOpacityLayers || debugDisablePhysicalShapeLayers) return null;
    final iRamme = SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks;
    if (!iRamme && !BergenLagring.debugUtenforRamme) return null;
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view == null) return null;
    final ovre = BergenPerf.lagringOvrePaa;

    // The ancestors: supported operations only; is anything painted beneath?
    final kjede = <ContainerLayer>[];
    var under = false;
    Layer barn = this;
    for (ContainerLayer? p = parent; p != null; p = p.parent) {
      for (Layer? s = barn.previousSibling; !under && s != null; s = s.previousSibling) {
        if (_harInnhold(s)) under = true;
      }
      if (!_gruppe(p)) return null;
      kjede.add(p);
      barn = p;
    }
    // Beneath the root: only upper-run images (on transparent, blended).
    if (under && !ovre) return null;
    // The chain must end at a view's root layer: a layer painted into a
    // snapshot (SnapshotWidget under a zoom transition, `toImage` of a
    // boundary) hangs under a detached layer whose scene has its own scale.
    final rotLag = kjede.isEmpty ? this : kjede.last;
    // ignore: invalid_use_of_protected_member
    if (!RendererBinding.instance.renderViews.any((v) => identical(v.layer, rotLag))) return null;
    // The view's own scene: its root pushes a new engine layer before its
    // children are added. A `toImage` of an attached boundary during a frame
    // leaves the root's engine layer as it was — not the screen's scene.
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    final rotMotor = rotLag.engineLayer;
    if (!BergenLagring.debugUtenforRamme && (rotMotor == null || identical(rotMotor, _sistRotMotor))) return null;
    _sistRotMotor = rotMotor;
    final skjerm = Offset.zero & view.physicalSize;
    var synlig = skjerm;
    final m = Matrix4.identity();
    final kjedeSig = <Object?>[skjerm];
    for (var i = kjede.length - 1; i >= 0; i--) {
      final p = kjede[i];
      kjedeSig.addAll(_egenSig(p));
      if (p is ClipRRectLayer || p is ClipRSuperellipseLayer || p is ClipPathLayer) return null;
      if (p is ClipRectLayer) {
        // Drawn inside this clip again: it must cut on whole device pixels.
        final s = m.storage;
        if (s[1].abs() > 1e-9 || s[4].abs() > 1e-9 || s[3].abs() > 1e-9 || s[7].abs() > 1e-9) return null;
        final r = MatrixUtils.transformRect(m, p.clipRect!);
        if (!_helPiksel(r.left) || !_helPiksel(r.top) || !_helPiksel(r.right) || !_helPiksel(r.bottom)) return null;
        synlig = synlig.intersect(r);
      }
      p.applyTransform(i == 0 ? this : kjede[i - 1], m);
    }
    m.translateByDouble(offset.dx, offset.dy, 0, 1);
    kjedeSig.add(offset);
    final s = m.storage;
    // 2D affine only.
    if (s[3].abs() > 1e-9 || s[7].abs() > 1e-9 || (s[15] - 1).abs() > 1e-9 || s[2].abs() > 1e-9 || s[6].abs() > 1e-9) return null;
    final inv = Matrix4.tryInvert(m);
    if (inv == null || synlig.isEmpty) return null;
    // The image: the visible region, origin on a multiple of 8.
    final r = Rect.fromLTRB(
      (synlig.left.roundToDouble() / 8).floorToDouble() * 8,
      (synlig.top.roundToDouble() / 8).floorToDouble() * 8,
      synlig.right.roundToDouble(),
      synlig.bottom.roundToDouble(),
    );
    final helSkjerm = r == skjerm;
    kjedeSig.add(r);

    // The drawables and how long each has held.
    final poster = <_Post>[];
    _flat(this, const [], poster);
    final n = poster.length;
    final ramme = _Register.ramme;
    for (final p in poster) {
      final sp = _spor[p.lag];
      if (sp == null) {
        _spor[p.lag] = _Spor(p.sig, ramme);
      } else if (!_likSig(sp.sig, p.sig)) {
        sp
          ..sig = p.sig
          ..siden = ramme;
      }
    }
    // Upper runs only above the last drawable that blends with the screen.
    var sistLeser = -1;
    for (var i = 0; i < n; i++) {
      if (poster[i].lesBunn) sistLeser = i;
    }
    // May drawable i sit in an image starting at [start]?
    bool kan(int i, int start) {
      final p = poster[i];
      if (p.levende) return false;
      final bunn = start == 0 && !under;
      if (p.bakteppe && !(bunn && helSkjerm)) return false;
      return bunn || (ovre && start > sistLeser);
    }

    // Which images are still exact for this scene?
    final gyldige = <(int, _Bilde)>[];
    for (final b in _bilder.toList()) {
      var j = -1;
      for (var i = 0; i < n; i++) {
        if (identical(poster[i].lag, b.poster.first.lag)) {
          j = i;
          break;
        }
      }
      var ok = j >= 0 && _likSig(b.kjede, kjedeSig) && j + b.poster.length <= n;
      for (var i = 0; ok && i < b.poster.length; i++) {
        ok = identical(b.poster[i].lag, poster[j + i].lag) && _likSig(b.poster[i].sig, poster[j + i].sig) && kan(j + i, j);
      }
      if (ok && gyldige.isNotEmpty && gyldige.last.$1 + gyldige.last.$2.poster.length > j) ok = false;
      if (ok) {
        gyldige.add((j, b));
      } else {
        // Thrown away soon after it was made: ask for a longer hold next time.
        _kreves = ramme - b.laget < 30 ? (_kreves * 2).clamp(BergenLagring.stabileRammer, 60) : BergenLagring.stabileRammer;
        _slippEn(b);
      }
    }
    gyldige.sort((a, c) => a.$1.compareTo(c.$1));

    // The runs: drawables that may be cached and have held [_kreves] frames.
    final runs = <(int, int)>[];
    var i = 0;
    while (i < n) {
      final start = i;
      while (i < n && kan(i, start) && ramme - _spor[poster[i].lag]!.siden >= _kreves) {
        i++;
      }
      if (i > start) {
        runs.add((start, i));
      } else {
        i++;
      }
    }
    // Each run's stability as a whole.
    final nye = <Layer, (List<_Post>, int)>{};
    for (final (a, e) in runs) {
      final del = poster.sublist(a, e);
      final f = _kandidater[poster[a].lag];
      var lik = f != null && f.$1.length == del.length;
      for (var k = 0; lik && k < del.length; k++) {
        lik = identical(f!.$1[k].lag, del[k].lag) && _likSig(f.$1[k].sig, del[k].sig);
      }
      nye[poster[a].lag] = (del, lik ? f!.$2 + 1 : 0);
    }
    _kandidater = nye;

    // The runs worth an image: the bottom one, then by pictures.
    int verdi((int, int) run) {
      var v = 0;
      for (var k = run.$1; k < run.$2; k++) {
        v += poster[k].bilder;
      }
      return v;
    }

    final valgt = runs.where((run) => verdi(run) > 0).toList()
      ..sort((x, y) {
        if (x.$1 == 0 && !under) return -1;
        if (y.$1 == 0 && !under) return 1;
        return verdi(y).compareTo(verdi(x));
      });
    if (valgt.length > _maksBilder) valgt.removeRange(_maksBilder, valgt.length);
    // Images outside the chosen runs go (memory, fill).
    for (final g in gyldige.toList()) {
      final inne = valgt.any((run) => g.$1 >= run.$1 && g.$1 + g.$2.poster.length <= run.$2);
      if (!inne) {
        gyldige.remove(g);
        _slippEn(g.$2);
      }
    }
    // A chosen run that held long enough and has no image covering it all.
    if (iRamme) {
      for (final run in valgt) {
        final hel = gyldige.any((g) => g.$1 == run.$1 && g.$2.poster.length == run.$2 - run.$1);
        if (hel) continue;
        if ((_kandidater[poster[run.$1].lag]?.$2 ?? 0) < _kreves) continue;
        // Its partial images give way to the new one.
        for (final g in gyldige.where((g) => g.$1 >= run.$1 && g.$1 < run.$2).toList()) {
          gyldige.remove(g);
          _slippEn(g.$2);
        }
        if (_bilder.length >= _maksBilder) continue;
        final b = _lagBilde(kjede, poster, run.$1, run.$2, r, inv, kjedeSig, ramme);
        if (b != null) gyldige.add((run.$1, b));
      }
      gyldige.sort((a, c) => a.$1.compareTo(c.$1));
    }
    if (gyldige.isEmpty) return null;
    return (n, gyldige);
  }

  _Bilde? _lagBilde(List<ContainerLayer> kjede, List<_Post> poster, int fra, int til, Rect r, Matrix4 inv, List<Object?> kjedeSig, int ramme) {
    final w = r.width.toInt(), h = r.height.toInt();
    final bytes = w * h * 4;
    if (w <= 0 || h <= 0) return null;
    if (!_Register.plass(this, bytes)) return null;
    final motor = <ui.EngineLayer>[];
    final sb = ui.SceneBuilder();
    motor.add(sb.pushTransform(Matrix4.translationValues(-r.left, -r.top, 0).storage));
    for (var i = kjede.length - 1; i >= 0; i--) {
      _pushEgen(kjede[i], sb, motor);
    }
    motor.add(sb.pushOffset(offset.dx, offset.dy));
    _i = 0;
    _omraade(this, sb, fra, til, motor, raster: true);
    final scene = sb.build();
    final img = scene.toImageSync(w, h);
    scene.dispose();
    for (final e in motor) {
      e.dispose();
    }
    // Drawn back in device space: the inverse of this layer's transform,
    // then the image at its device origin, texel on pixel.
    final rec = ui.PictureRecorder();
    Canvas(rec)
      ..transform(inv.storage)
      ..drawImage(img, r.topLeft, Paint()..filterQuality = FilterQuality.none);
    final b = _Bilde(poster.sublist(fra, til), kjedeSig, img, rec.endRecording(), bytes, ramme);
    _bilder.add(b);
    _bytes += bytes;
    _Register.alle.add(this);
    _Register.bytes += bytes;
    BergenLagring.laget++;
    return b;
  }

  /// Drawables [fra] ≤ index < [til], with their containers' operations:
  /// into an image ([raster]: pictures and effect layers only, containers
  /// pushed again) or live (a container wholly inside is added as itself, so
  /// the framework's retained engine layers below it are reused).
  void _omraade(ContainerLayer c, ui.SceneBuilder b, int fra, int til, List<ui.EngineLayer> motor, {required bool raster}) {
    for (Layer? l = c.firstChild; l != null; l = l.nextSibling) {
      final n = _antall[l] ?? 0;
      final s = _i, e = _i + n;
      _i = e;
      if (n == 0 || e <= fra || s >= til) continue;
      if (l is PictureLayer) {
        b.addPicture(Offset.zero, l.picture!, isComplexHint: l.isComplexHint, willChangeHint: l.willChangeHint);
        continue;
      }
      if (!_gruppe(l) || (!raster && s >= fra && e <= til)) {
        // An effect layer taken whole, a live leaf, or a whole live
        // container: its own addToScene. (Into an image, an effect layer's
        // engine layer then belongs to the image's scene; the framework
        // re-adds or retains it as it would after a `toImage`.)
        l.addToScene(b);
        continue;
      }
      _i = s;
      final pushet = _pushEgen(l as ContainerLayer, b, motor);
      _omraade(l, b, fra, til, motor, raster: raster);
      if (pushet) b.pop();
      _i = e;
    }
  }
}
