import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'bergen_css.dart';

/// Where the finger last went down — the drop into a store grows from it
/// (`this._pek`, kept for 1.5s).
abstract final class DrapePek {
  static Offset? _pos;
  static DateTime _t = DateTime(0);
  static bool _lytter = false;

  /// Starts listening (once) to every pointer-down in the app.
  static void lytt() {
    if (_lytter) return;
    _lytter = true;
    GestureBinding.instance.pointerRouter.addGlobalRoute((e) {
      if (e is PointerDownEvent) {
        _pos = e.position;
        _t = DateTime.now();
      }
    });
  }

  static Offset? get siste => _pos != null && DateTime.now().difference(_t).inMilliseconds < 1500 ? _pos : null;
}

/// The "Dråpe" portal (`portalOvergang`, L17572): into a store a teal drop
/// grows out of the tap, wobbling (`borderRadius` R1 → R4) until it fills the
/// screen, splashes seven drops, and the store is underneath when it fades;
/// out of it a drop rises from the middle of the screen (not the back key),
/// covers the page, and the water fades off what was underneath.
class DrapeRoute<T> extends PageRoute<T> {
  DrapeRoute({required this.builder, super.settings}) : _fra = DrapePek.siste, _seed = math.Random().nextInt(1 << 30);

  final WidgetBuilder builder;
  final Offset? _fra;
  final int _seed;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  bool get opaque => true;

  /// In: the drop 420ms, then its fade 180ms.
  @override
  Duration get transitionDuration => const Duration(milliseconds: 600);

  /// Out: the drop 320ms, then its fade 170ms.
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 490);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) =>
      builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return _Drape(animation: animation, fra: _fra, seed: _seed, child: child);
  }
}

/// `border-radius` of a 90px drop as `a b c d / e f g h` percentages.
typedef _Form = List<double>;

const _Form _r1 = [50, 50, 50, 50, 50, 50, 50, 50];
const _Form _r2 = [42, 58, 63, 37, 45, 40, 60, 55];
const _Form _r3 = [60, 40, 38, 62, 55, 62, 38, 45];
const _Form _r4 = [48, 52, 55, 45, 50, 45, 55, 50];
const _Form _r0 = [50, 50, 50, 50, 60, 60, 40, 40];

_Form _lerpForm(_Form a, _Form b, double t) => [for (var i = 0; i < 8; i++) a[i] + (b[i] - a[i]) * t];

BorderRadius _radius(_Form f, double d) => BorderRadius.only(
  topLeft: Radius.elliptical(f[0] / 100 * d, f[4] / 100 * d),
  topRight: Radius.elliptical(f[1] / 100 * d, f[5] / 100 * d),
  bottomRight: Radius.elliptical(f[2] / 100 * d, f[6] / 100 * d),
  bottomLeft: Radius.elliptical(f[3] / 100 * d, f[7] / 100 * d),
);

/// Keyframes: which segment `t` is in and how far along.
(int, double) _seg(List<double> stops, double t) {
  for (var i = 0; i < stops.length - 1; i++) {
    if (t <= stops[i + 1]) return (i, ((t - stops[i]) / (stops[i + 1] - stops[i])).clamp(0.0, 1.0));
  }
  return (stops.length - 2, 1);
}

class _Drape extends StatelessWidget {
  const _Drape({required this.animation, required this.fra, required this.seed, required this.child});

  final Animation<double> animation;
  final Offset? fra;
  final int seed;
  final Widget child;

  static const _d = 90.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final size = MediaQuery.sizeOf(context);
        final ut = animation.status == AnimationStatus.reverse || animation.status == AnimationStatus.dismissed;
        return ut ? _ut(size, child!) : _inn(size, child!);
      },
    );
  }

  Widget _inn(Size size, Widget child) {
    final ms = animation.value * 600;
    if (ms >= 600) return child;
    final w = size.width, h = size.height;
    final p = fra ?? Offset(w / 2, h / 2);
    final x = p.dx.clamp(0.0, w), y = p.dy.clamp(0.0, h);
    final r = math.sqrt(math.pow(math.max(x, w - x), 2) + math.pow(math.max(y, h - y), 2));
    final storst = 2 * r / _d * 1.2;
    double skala, dy = 0, op = 1;
    _Form form;
    if (ms <= 420) {
      final t = const Cubic(.4, 0, .2, 1).transform(ms / 420);
      final (i, f) = _seg(const [0, .22, .5, 1], t);
      final sk = [.05, .85, storst * .28, storst];
      final fo = [_r1, _r2, _r3, _r4];
      final dys = [0.0, -6.0, 0.0, 0.0];
      skala = sk[i] + (sk[i + 1] - sk[i]) * f;
      form = _lerpForm(fo[i], fo[i + 1], f);
      dy = dys[i] + (dys[i + 1] - dys[i]) * f;
    } else {
      final t = const Cubic(.2, 0, 0, 1).transform((ms - 420) / 180);
      skala = storst * (1 + .04 * t);
      op = 1 - t;
      form = _r4;
    }
    final rnd = math.Random(seed);
    return Stack(
      fit: StackFit.expand,
      children: [
        // The store is under the water from 330ms on.
        Opacity(opacity: ms >= 330 ? 1 : 0, child: child),
        IgnorePointer(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              _drope(x, y, skala, skala, dy, op, form, inn: true),
              // Seven drops thrown out (`420ms`, 60ms late).
              for (var i = 0; i < 7; i++) _sprut(i, rnd, x, y, ms),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sprut(int i, math.Random rnd, double x, double y, double ms) {
    final ang = (i / 7) * math.pi * 2 + rnd.nextDouble() * .6;
    final dist = 60 + rnd.nextDouble() * 70;
    final sz = 8 + rnd.nextDouble() * 10;
    final t = ((ms - 60) / 420).clamp(0.0, 1.0);
    if (t <= 0 || t >= 1) return const SizedBox.shrink();
    final e = const Cubic(.2, .7, .3, 1).transform(t);
    double dx, dyy, sc, op;
    if (e <= .35) {
      final f = e / .35;
      dx = math.cos(ang) * dist * .5 * f;
      dyy = math.sin(ang) * dist * .5 * f;
      sc = .2 + .8 * f;
      op = f;
    } else {
      final f = (e - .35) / .65;
      dx = math.cos(ang) * dist * (.5 + .5 * f);
      dyy = math.sin(ang) * dist * (.5 + .5 * f) + 20 * f;
      sc = 1 - f;
      op = 1 - f;
    }
    return Positioned(
      left: x - sz / 2,
      top: y - sz / 2,
      width: sz,
      height: sz,
      child: Opacity(
        opacity: op.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(dx, dyy),
          child: Transform.scale(
            scale: sc,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i.isOdd ? const Color(0xFF5CE0B8) : const Color(0xFF2A6272),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ut(Size size, Widget child) {
    final ms = (1 - animation.value) * 490;
    final w = size.width, h = size.height;
    final cx = w / 2, cy = h * .44;
    final r0 = math.sqrt(cx * cx + math.pow(math.max(cy, h - cy), 2));
    final storst = 2 * r0 / _d * 1.15;
    double sx, sy, dy = 0, op;
    _Form form;
    if (ms <= 320) {
      final t = const Cubic(.33, 0, .2, 1).transform(ms / 320);
      final (i, f) = _seg(const [0, .22, .55, 1], t);
      final sxs = [.08, .7, storst * .35, storst];
      final sys = [.1, .66, storst * .35, storst];
      final ops = [0.0, 1.0, 1.0, 1.0];
      final dys = [-22.0, 0.0, 0.0, 0.0];
      final fo = [_r0, _r2, _r3, _r4];
      sx = sxs[i] + (sxs[i + 1] - sxs[i]) * f;
      sy = sys[i] + (sys[i + 1] - sys[i]) * f;
      op = ops[i] + (ops[i + 1] - ops[i]) * f;
      dy = dys[i] + (dys[i + 1] - dys[i]) * f;
      form = _lerpForm(fo[i], fo[i + 1], f);
    } else {
      final t = const Cubic(.2, 0, 0, 1).transform(((ms - 320) / 170).clamp(0.0, 1.0));
      sx = sy = storst * (1 + .04 * t);
      op = 1 - t;
      form = _r4;
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        // The store goes at 250ms; what was under it is there when the
        // water clears.
        Opacity(opacity: ms < 250 ? 1 : 0, child: child),
        IgnorePointer(
          child: Stack(clipBehavior: Clip.hardEdge, children: [_drope(cx, cy, sx, sy, dy, op, form, inn: false)]),
        ),
      ],
    );
  }

  Widget _drope(double x, double y, double sx, double sy, double dy, double op, _Form form, {required bool inn}) {
    return Positioned(
      left: x - _d / 2,
      top: y - _d / 2,
      width: _d,
      height: _d,
      child: Opacity(
        opacity: op.clamp(0.0, 1.0),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.translationValues(0, dy, 0)..scaleByDouble(sx, sy, 1, 1),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: _radius(form, _d),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: inn
                    ? const [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)]
                    : const [Color(0xFF27596A), Color(0xFF1E4F5C), Color(0xFF173E48)],
                stops: const [0, .55, 1],
              ),
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: _radius(form, _d),
              gradient: RadialGradient(
                center: const Alignment(-.3, -.4),
                radius: .4,
                colors: [rgba(255, 255, 255, inn ? .35 : .32), rgba(255, 255, 255, 0)],
                stops: const [0, .6],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
