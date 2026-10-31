import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The targets («mål») the Ægil-runden tour and the Ægil-tips coach marks
/// point at (Onboarding plan §3 #14). A real control wraps itself in
/// [OnbMaal] with the design's anchor id; the overlay measures it through
/// [OnbMaalRegistry] (the prototype's `cmFinn` / `cmMaal` / `rtRull`).
///
/// Ids are the prototype's: `adresse`, `fjordfiske`, `kategorirad`, `hurtig`,
/// `nav-hjem`, `nav-utforsk`, `nav-kurv`, `nav-meg`, `orb`, `fpost`,
/// `karusell-u`, `seilas`, `legg`, `legg-ark`, `butikk-kurv`, `levhent`,
/// `flere`, `betspor`, `poeng`, `bio`, `ai`, `lev`, `dor`, `leveringskode`.
class OnbMaal extends StatefulWidget {
  const OnbMaal({super.key, required this.id, required this.child, this.radius = 14});

  final String id;
  final Widget child;

  /// The control's corner radius (the prototype reads `border-radius`).
  final double radius;

  @override
  State<OnbMaal> createState() => _OnbMaalState();
}

class _OnbMaalState extends State<OnbMaal> {
  @override
  void initState() {
    super.initState();
    OnbMaalRegistry._add(widget.id, this);
  }

  @override
  void didUpdateWidget(OnbMaal old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      OnbMaalRegistry._remove(old.id, this);
      OnbMaalRegistry._add(widget.id, this);
    }
  }

  @override
  void dispose() {
    OnbMaalRegistry._remove(widget.id, this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A measured target: global rect (logical px) and corner radius.
class OnbMaalRekt {
  const OnbMaalRekt(this.rect, this.radius);
  final Rect rect;
  final double radius;

  double get x => rect.left;
  double get y => rect.top;
  double get w => rect.width;
  double get h => rect.height;
}

abstract final class OnbMaalRegistry {
  static final Map<String, List<_OnbMaalState>> _alle = {};

  /// Bumps once per frame when a target mounts or goes (Step 4: the coach
  /// marks plan a check on it). Never during a build.
  static final ValueNotifier<int> endring = ValueNotifier<int>(0);
  static bool _bump = false;

  static void _varsle() {
    if (_bump) return;
    _bump = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bump = false;
      endring.value++;
    });
  }

  static void _add(String id, _OnbMaalState s) {
    (_alle[id] ??= []).add(s);
    _varsle();
  }

  static void _remove(String id, _OnbMaalState s) {
    final l = _alle[id];
    if (l == null) return;
    l.remove(s);
    if (l.isEmpty) _alle.remove(id);
    _varsle();
  }

  /// The newest mounted target with this id (`cmFinn`), or null.
  static BuildContext? finn(String id) {
    final l = _alle[id];
    if (l == null) return null;
    for (var k = l.length - 1; k >= 0; k--) {
      final s = l[k];
      if (s.mounted) return s.context;
    }
    return null;
  }

  static bool har(String id) => finn(id) != null;

  /// The target's rect on screen, clipped by the scrollables it sits in, so
  /// the marking covers only what is visible (`cmMaal`). Null when it is not
  /// mounted, has no size, or is clipped to under 4 px.
  static OnbMaalRekt? maal(String id) {
    final ctx = finn(id);
    if (ctx == null) return null;
    final rb = ctx.findRenderObject();
    if (rb is! RenderBox || !rb.attached || !rb.hasSize) return null;
    var r = globalRect(rb);
    // Clip against every scroll viewport above the target.
    var c = ctx;
    while (true) {
      final sc = Scrollable.maybeOf(c);
      if (sc == null) break;
      final vb = sc.context.findRenderObject();
      if (vb is RenderBox && vb.attached && vb.hasSize) {
        r = r.intersect(globalRect(vb));
      }
      c = sc.context;
      final parent = c.findAncestorStateOfType<ScrollableState>();
      if (parent == null) break;
      c = parent.context;
      // `Scrollable.maybeOf(c)` on the scrollable's own context returns it
      // again, so step to the ancestor's context explicitly.
    }
    if (r.width < 4 || r.height < 4) {
      assert(() {
        debugPrint('ONB_MAAL $id clipped away: box ${rb.localToGlobal(Offset.zero) & rb.size} → $r');
        return true;
      }());
      return null;
    }
    final w = ctx.widget;
    return OnbMaalRekt(r, w is OnbMaal ? w.radius : 14);
  }

  /// The box's rect on screen with every ancestor transform applied. Hjem's
  /// rows sit in scaled frames (`lfFlow` = a FittedBox), so the origin alone
  /// plus the unscaled size came out too narrow on wide phones.
  static Rect globalRect(RenderBox rb) => MatrixUtils.transformRect(rb.getTransformTo(null), Offset.zero & rb.size);

  /// Scrolls the target so it sits inside the band [lo, hi] (global y) of
  /// its nearest scrollable, the prototype's `rtRull`: a tall target goes to
  /// the top of the band, a short one at most 40 px under it. Returns how far
  /// the content moved (positive = the target moved up), 0 when nothing had
  /// to move or there is no scrollable.
  static double rull(String id, {required double lo, required double hi, required bool rolig, double fortrinn = 40}) {
    final ctx = finn(id);
    if (ctx == null) return 0;
    final rb = ctx.findRenderObject();
    if (rb is! RenderBox || !rb.attached || !rb.hasSize) return 0;
    final sc = Scrollable.maybeOf(ctx);
    if (sc == null || !sc.position.hasPixels) return 0;
    final pos = sc.position;
    if (pos.axis != Axis.vertical) return 0;
    final gr = globalRect(rb);
    final ty = gr.top, th = gr.height;
    if (ty >= lo && ty + th <= hi) return 0;
    final maal = th > hi - lo ? lo : math.max(lo, math.min(hi - th, lo + fortrinn));
    final d = ty - maal;
    final til = (pos.pixels + d).clamp(pos.minScrollExtent, pos.maxScrollExtent);
    final flytt = til - pos.pixels;
    if (flytt.abs() < 4) return 0;
    if (rolig) {
      pos.jumpTo(til);
    } else {
      pos.animateTo(til, duration: const Duration(milliseconds: 420), curve: const Cubic(.2, .9, .3, 1));
    }
    return flytt;
  }

  @visibleForTesting
  static void reset() => _alle.clear();
}
