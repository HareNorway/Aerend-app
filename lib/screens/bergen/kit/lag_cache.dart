import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// Heat-test prototype (harness `lagCache: true`): a raster cache for
/// Impeller, written in Dart.
///
/// Impeller has no raster cache: every frame re-runs every recorded drawing
/// command of the whole screen, even the parts that did not change. Flutter
/// already keeps an unchanged part of the screen as the *same* `PictureLayer`
/// (with the same `ui.Picture`) from frame to frame. After every frame this
/// walks the layer tree; a `PictureLayer` that has stayed the same for
/// [_stabil] frames is rasterised once, at its exact device transform, and its
/// picture is swapped for one that only draws that image. Animated parts sit
/// in their own repaint boundaries (their own picture layers), keep painting
/// live and keep their place in the paint order.
///
/// Prototype limits: only scale + translate transforms; the raster covers the
/// layer's canvas bounds plus [_kant] and is clipped to the screen; a total
/// pixel budget over the attached cached layers. Off unless switched on.
class LagCache {
  static bool _paa = false;
  static bool _registrert = false;
  static final Expando<int> _sett = Expando<int>('lagCacheSett');
  static final Expando<bool> _cachet = Expando<bool>('lagCacheCachet');
  static int _rammer = 0;
  static int laget = 0, piksler = 0;
  static final List<(WeakReference<PictureLayer>, int)> _liste = [];

  static const int _stabil = 3;
  static const double _kant = 24; // logical px around the canvas bounds
  static const int _budsjett = 9000000; // device px held in cached images
  static const int _minPiksler = 96 * 96;

  static void start() {
    _paa = true;
    if (_registrert) return;
    _registrert = true;
    SchedulerBinding.instance.addPersistentFrameCallback((_) {
      if (!_paa) return;
      try {
        _gaa();
      } catch (e) {
        debugPrint('PERF_LAGCACHE error $e');
      }
    });
  }

  static void stopp() => _paa = false;

  static void _gaa() {
    _rammer++;
    if (_rammer % 60 == 0) {
      _liste.removeWhere((e) => e.$1.target?.attached != true);
      piksler = _liste.fold(0, (a, e) => a + e.$2);
    }
    for (final v in RendererBinding.instance.renderViews) {
      // ignore: invalid_use_of_protected_member
      final rot = v.layer;
      if (rot == null) continue;
      final skjerm = Offset.zero & v.size * v.flutterView.devicePixelRatio;
      _besok(rot, skjerm);
    }
    if (_rammer % 300 == 0) {
      final typer = <String, int>{};
      var bilder = 0, cachet = 0;
      void tell(Layer l) {
        final n = l.runtimeType.toString();
        typer[n] = (typer[n] ?? 0) + 1;
        if (l is PictureLayer) {
          bilder++;
          if (_cachet[l] == true) cachet++;
        }
        if (l is ContainerLayer) {
          var c = l.firstChild;
          while (c != null) {
            tell(c);
            c = c.nextSibling;
          }
        }
      }
      for (final v in RendererBinding.instance.renderViews) {
        // ignore: invalid_use_of_protected_member
        final r = v.layer;
        if (r != null) tell(r);
      }
      debugPrint('PERF_LAGCACHE laget=$laget piksler=$piksler bilder=$bilder cachet=$cachet typer=$typer');
    }
  }

  static void _besok(Layer l, Rect skjerm) {
    if (l is PictureLayer) {
      _bilde(l, skjerm);
      return;
    }
    if (l is ContainerLayer) {
      // Backdrop filters, shader masks and platform views are left whole.
      var c = l.firstChild;
      while (c != null) {
        _besok(c, skjerm);
        c = c.nextSibling;
      }
    }
  }

  static Matrix4? _tilSkjerm(Layer l) {
    final m = Matrix4.identity();
    Layer node = l;
    while (node.parent != null) {
      final p = node.parent!;
      p.applyTransform(node, m);
      node = p;
    }
    return m;
  }

  static void _bilde(PictureLayer l, Rect skjerm) {
    if (_cachet[l] == true) return;
    final pic = l.picture;
    if (pic == null) return;
    final n = (_sett[l] ?? 0) + 1;
    _sett[l] = n;
    if (n < _stabil) return;
    if (piksler >= _budsjett) return;
    final m = _tilSkjerm(l);
    if (m == null) return;
    final s = m.storage;
    // Scale + translate only.
    if (s[1].abs() > 1e-6 || s[4].abs() > 1e-6 || s[3].abs() > 1e-6 || s[7].abs() > 1e-6 || (s[15] - 1).abs() > 1e-6) {
      _cachet[l] = true; // never try again
      return;
    }
    final sx = s[0], sy = s[5];
    if (sx <= 0 || sy <= 0) return;
    final lokal = l.canvasBounds.inflate(_kant);
    final dev = MatrixUtils.transformRect(m, lokal).intersect(skjerm);
    if (dev.isEmpty) return;
    final r = Rect.fromLTRB(dev.left.floorToDouble(), dev.top.floorToDouble(), dev.right.ceilToDouble(), dev.bottom.ceilToDouble());
    final w = r.width.toInt(), h = r.height.toInt();
    if (w * h < _minPiksler) {
      _cachet[l] = true;
      return;
    }
    // Raster at the exact device transform.
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.translate(-r.left, -r.top);
    c.transform(m.storage);
    c.drawPicture(pic);
    final img = rec.endRecording().toImageSync(w, h);
    // The replacement draws the image back through the inverse transform, so
    // while the transform is unchanged it lands on exactly the same pixels.
    final inv = Matrix4.tryInvert(m);
    if (inv == null) {
      img.dispose();
      return;
    }
    final rec2 = ui.PictureRecorder();
    final c2 = Canvas(rec2);
    c2.transform(inv.storage);
    c2.drawImage(img, r.topLeft, Paint()..filterQuality = FilterQuality.none);
    final ny = rec2.endRecording();
    img.dispose(); // the picture keeps its own reference
    _cachet[l] = true;
    l.picture = ny; // disposes the original picture
    laget++;
    piksler += w * h;
    _liste.add((WeakReference(l), w * h));
  }
}
