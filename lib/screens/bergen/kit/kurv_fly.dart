import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;

import '../../common/auth/launch/lf_css.dart' show jakarta, kf;
import 'bergen_perf.dart';

/// TestFlight 6 feedback («the animation that shows live that the product is added to the basket is missing»): the
/// design's `flyTilKurv()` (25 Nov prototype). A copy of the dish lifts off its picture, squashes, arcs up and over
/// into the basket bar's cart while it shrinks and turns (720 ms, `cubic-bezier(.45,.05,.35,1)`); there the cart
/// bounces (480 ms), a mint «+1» rises (820 ms) and six mint / gold sparks burst (560 ms). Nothing under «Roligere
/// bevegelse» / the OS reduced-motion setting (the prototype's `rolig`).
///
/// Wiring: [KurvFlyKort] around the card or sheet that holds the dish, [KurvFlyKilde] around its picture,
/// [KurvFlyMaal] around the cart that receives it; [kurvFly] from the tapped key.
Future<void> kurvFly(BuildContext fra) async {
  if (BergenPerf.calmOf(fra)) return;
  final kort = fra.findAncestorStateOfType<KurvFlyKortState>();
  final kilde = kort?._kilde;
  final kc = kilde?.context;
  final ro = (kc != null && kc.mounted ? kc : fra).findRenderObject();
  if (ro is! RenderBox || !ro.hasSize || !ro.attached) return;
  final r0 = MatrixUtils.transformRect(ro.getTransformTo(null), Offset.zero & ro.size);
  if (r0.width <= 0) return;
  final overlay = Overlay.maybeOf(fra, rootOverlay: true);
  if (overlay == null) return;
  // The prototype's px are the 390 pt frame's; the device draws it scaled to its width.
  final view = View.of(fra);
  final skjerm = view.physicalSize / view.devicePixelRatio;
  final s = skjerm.width / 390;
  _Fly(overlay: overlay, r0: r0, s: s, skjerm: skjerm, url: kilde?.widget.url, radius: (kilde?.widget.radius ?? 20) * s).start();
}

/// The card / sheet a [kurvFly] starts in: it knows its dish picture ([KurvFlyKilde]).
class KurvFlyKort extends StatefulWidget {
  const KurvFlyKort({super.key, required this.child});

  final Widget child;

  @override
  State<KurvFlyKort> createState() => KurvFlyKortState();
}

class KurvFlyKortState extends State<KurvFlyKort> {
  _KurvFlyKildeState? _kilde;

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The dish picture a [kurvFly] copies ([url]: the same image, already cached; null: the warm placeholder).
class KurvFlyKilde extends StatefulWidget {
  const KurvFlyKilde({super.key, required this.url, required this.child, this.radius = 20});

  final String? url;
  final double radius;
  final Widget child;

  @override
  State<KurvFlyKilde> createState() => _KurvFlyKildeState();
}

class _KurvFlyKildeState extends State<KurvFlyKilde> {
  KurvFlyKortState? _kort;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final k = context.findAncestorStateOfType<KurvFlyKortState>();
    if (k != _kort) {
      if (_kort?._kilde == this) _kort!._kilde = null;
      _kort = k?..
          _kilde = this;
    }
  }

  @override
  void dispose() {
    if (_kort?._kilde == this) _kort!._kilde = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The cart a [kurvFly] lands in (the basket bar's cart; the latest one on screen wins). When the dish arrives it
/// bounces: `scale 1 → 1.28 rotate(-6°) → .94 rotate(3°) → 1`, 480 ms, `cubic-bezier(.3,1.3,.5,1)`.
class KurvFlyMaal extends StatefulWidget {
  const KurvFlyMaal({super.key, required this.child});

  final Widget child;

  static final List<_KurvFlyMaalState> _maal = [];

  /// The cart's centre on screen, if one is laid out.
  static (Offset, _KurvFlyMaalState)? get naa {
    for (final m in _maal.reversed) {
      final ro = m.mounted ? m.context.findRenderObject() : null;
      if (ro is RenderBox && ro.hasSize && ro.attached) {
        return (MatrixUtils.transformRect(ro.getTransformTo(null), Offset.zero & ro.size).center, m);
      }
    }
    return null;
  }

  @override
  State<KurvFlyMaal> createState() => _KurvFlyMaalState();
}

class _KurvFlyMaalState extends State<KurvFlyMaal> with SingleTickerProviderStateMixin {
  late final AnimationController _dunk = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));

  @override
  void initState() {
    super.initState();
    KurvFlyMaal._maal.add(this);
  }

  @override
  void dispose() {
    KurvFlyMaal._maal.remove(this);
    _dunk.dispose();
    super.dispose();
  }

  void dunk() => _dunk.forward(from: 0);

  static const _kurve = Cubic(.3, 1.3, .5, 1);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _dunk,
    child: widget.child,
    builder: (context, child) {
      // Always the same Transform (identity at rest), so the cart is never rebuilt (its own `kurvDunk` would replay).
      final p = _dunk.isAnimating ? _kurve.transform(_dunk.value) : 0.0;
      final sk = kf(p, const [0, .35, .65, 1], const [1, 1.28, .94, 1]);
      final rot = kf(p, const [0, .35, .65, 1], const [0, -6, 3, 0]);
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..scaleByDouble(sk, sk, 1, 1)
          ..rotateZ(rot * math.pi / 180),
        child: child,
      );
    },
  );
}

/// One flight, in the root overlay: the copy, then the «+1» and the sparks at the cart.
class _Fly {
  _Fly({required this.overlay, required this.r0, required this.s, required this.skjerm, required this.url, required this.radius});

  final OverlayState overlay;
  final Rect r0;
  final double s;
  final Size skjerm;
  final String? url;
  final double radius;

  static const _flyKurve = Cubic(.45, .05, .35, 1);
  static const _utKurve = Cubic(.2, .7, .3, 1);

  void start() {
    // `w = min(120, width)`, the picture's proportions; centred on the picture.
    final w = math.min(120 * s, r0.width);
    final h = w * (r0.height / r0.width);
    final start = r0.center;
    late final OverlayEntry flyEntry;
    var landet = false;
    flyEntry = OverlayEntry(
      builder: (context) => _Tikker(
        ms: 720,
        onFerdig: () {
          if (landet) return;
          landet = true;
          flyEntry.remove();
          _land();
        },
        builder: (t) {
          // The cart is looked up on every frame: on the first dish the bar only appears once the server answers.
          final mal = KurvFlyMaal.naa?.$1 ?? Offset(skjerm.width / 2, skjerm.height - 60 * s);
          final dx = mal.dx - start.dx, dy = mal.dy - start.dy, topp = math.min(0.0, dy) - 90 * s;
          final dir = dx > 0 ? 1.0 : -1.0;
          // WAAPI: the timing function eases the whole flight, the keyframes interpolate linearly.
          final p = _flyKurve.transform(t);
          final x = kf(p, const [0, .08, .5, 1], [0, 0, dx * .42, dx]);
          final y = kf(p, const [0, .08, .5, 1], [0, 6 * s, topp, dy]);
          final sx = kf(p, const [0, .08, .5, 1], const [1, 1.08, .82, .16]);
          final sy = kf(p, const [0, .08, .5, 1], const [1, .9, .82, .16]);
          final rot = kf(p, const [0, .08, .5, 1], [0, 0, 14 * dir, 28 * dir]);
          final op = 1 - .1 * p;
          return Positioned(
            left: start.dx - w / 2,
            top: start.dy - h / 2,
            width: w,
            height: h,
            child: IgnorePointer(
              child: Opacity(
                opacity: op,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translateByDouble(x, y, 0, 1)
                    ..scaleByDouble(sx, sy, 1, 1)
                    ..rotateZ(rot * math.pi / 180),
                  // `filter: drop-shadow(0 10px 10px rgba(0,0,0,.45))`.
                  child: DecoratedBox(
                    key: const Key('kurv-fly-kopi'),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius * w / r0.width),
                      boxShadow: [BoxShadow(color: const Color.fromRGBO(0, 0, 0, .45), offset: Offset(0, 10 * s), blurRadius: 10 * s)],
                    ),
                    child: ClipRRect(borderRadius: BorderRadius.circular(radius * w / r0.width), child: _bilde()),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    overlay.insert(flyEntry);
  }

  Widget _bilde() {
    final u = url;
    const varm = DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(center: Alignment(-.4, -.8), radius: 1.2, colors: [Color(0xFFFDF0D8), Color(0xFFF6D9A6), Color(0xFFE7B66C)], stops: [0, .52, 1]),
      ),
    );
    if (u == null || u.isEmpty) return varm;
    return Image.network(u, cacheWidth: BergenPerf.decodeWidth, fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: (_, _, _) => varm);
  }

  void _land() {
    final naa = KurvFlyMaal.naa;
    if (naa == null) return;
    final (mal, cart) = naa;
    cart.dunk();
    final rnd = math.Random();
    final gnister = [
      for (var j = 0; j < 6; j++) (-math.pi / 2 + (j - 2.5) * .45, (20 + rnd.nextDouble() * 12) * s, j.isOdd ? const Color(0xFFFFDD86) : const Color(0xFF7FF0CB)),
    ];
    late final OverlayEntry e;
    var borte = false;
    e = OverlayEntry(
      builder: (context) => _Tikker(
        ms: 820,
        onFerdig: () {
          if (borte) return;
          borte = true;
          e.remove();
        },
        builder: (t) {
          final ms = t * 820;
          // «+1»: `translateY(6px) scale(.5)` → `-4px 1.1` (30 %) → `-22px 1`, opacity 0 → 1 → 0; 820 ms.
          final pb = _utKurve.transform(t);
          final by = kf(pb, const [0, .3, 1], const [6, -4, -22]) * s;
          final bs = kf(pb, const [0, .3, 1], const [.5, 1.1, 1]);
          final bo = kf(pb, const [0, .3, 1], const [0, 1, 0]);
          // Sparks: 560 ms of the 820.
          final tg = (ms / 560).clamp(0.0, 1.0);
          final pg = _utKurve.transform(tg);
          return Stack(
            children: [
              if (tg < 1)
                for (final (a, d, farge) in gnister)
                  Positioned(
                    left: mal.dx - 3 * s,
                    top: mal.dy - 3 * s,
                    width: 6 * s,
                    height: 6 * s,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: kf(pg, const [0, .5, 1], const [1, 1, 0]),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..translateByDouble(
                              kf(pg, const [0, .5, 1], [0, math.cos(a) * d, math.cos(a) * d * 1.3]),
                              kf(pg, const [0, .5, 1], [0, math.sin(a) * d, math.sin(a) * d + 14 * s]),
                              0,
                              1,
                            )
                            ..scaleByDouble(kf(pg, const [0, .5, 1], const [.4, 1, .2]), kf(pg, const [0, .5, 1], const [.4, 1, .2]), 1, 1),
                          child: DecoratedBox(
                            decoration: BoxDecoration(shape: BoxShape.circle, color: farge, boxShadow: [BoxShadow(color: farge, blurRadius: 6 * s)]),
                          ),
                        ),
                      ),
                    ),
                  ),
              Positioned(
                left: mal.dx + 6 * s,
                top: mal.dy - 22 * s,
                child: IgnorePointer(
                  key: const Key('kurv-fly-pluss1'),
                  child: Opacity(
                    opacity: bo.clamp(0.0, 1.0),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..translateByDouble(0, by, 0, 1)
                        ..scaleByDouble(bs, bs, 1, 1),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 7 * s, vertical: 2 * s),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7FF0CB), Color(0xFF2FB893)]),
                          boxShadow: [BoxShadow(color: const Color.fromRGBO(47, 184, 147, .8), offset: Offset(0, 6 * s), blurRadius: 12 * s, spreadRadius: -4 * s)],
                        ),
                        child: Text(
                          '+1',
                          style: jakarta(11 * s, height: 1.25, color: const Color(0xFF0F2A33)).copyWith(decoration: TextDecoration.none),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    overlay.insert(e);
  }
}

/// Rebuilds every frame for [ms] on the frame clock (the ticker's elapsed time), then calls [onFerdig] once.
class _Tikker extends StatefulWidget {
  const _Tikker({required this.ms, required this.builder, required this.onFerdig});

  final int ms;
  final Widget Function(double t) builder;
  final VoidCallback onFerdig;

  @override
  State<_Tikker> createState() => _TikkerState();
}

class _TikkerState extends State<_Tikker> with SingleTickerProviderStateMixin {
  double _t = 0;
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    // Not a lazy `late final … ..start()`: that would only be built (and started) the first time dispose() read it.
    _ticker = createTicker((elapsed) {
      final t = (elapsed.inMicroseconds / 1000 / widget.ms).clamp(0.0, 1.0);
      setState(() => _t = t);
      if (t >= 1) {
        _ticker.stop();
        WidgetsBinding.instance.addPostFrameCallback((_) => widget.onFerdig());
      }
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.builder(_t);
    return c is Positioned ? Stack(children: [c]) : c;
  }
}
