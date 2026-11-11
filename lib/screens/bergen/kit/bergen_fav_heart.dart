import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/ops/favourite_stores.dart';
import '../../../networking/ops/ops_customer_api.dart';
import 'bergen_toast.dart';
import '../../../ui/kit/ae_haptic.dart';

/// Copy for the store hearts (design `toggleFavBK` / `si(...)`).
class FavCopy {
  static const String lagtTil = 'Lagt til i favoritter';
  static const String fjernet = 'Fjernet fra favoritter';
  static const String loggInn = 'Logg inn for å lagre favoritter';
  static const String feil = 'Fikk ikke lagret akkurat nå. Prøv igjen.';
  static const String leggTil = 'Legg til i favoritter';
  static const String fjern = 'Fjern fra favoritter';

  /// 29 Oct, the category cards: «{navn} er lagret i favoritter».
  static String lagret(String navn) => '$navn er lagret i favoritter';
}

/// A store heart that works wherever it sits: filled orange when the store is
/// a favourite, the design's `popp` on heart (.42s, scale 1 → 1.16 → .96 → 1,
/// cubic-bezier(.34,1.56,.64,1)), and the design's toast either way.
///
/// [onDark] is the store-page look (dark glass circle, like the back button);
/// otherwise it is Hjem's white card chip.
///
/// With [burst] (the category's store cards, Bergen 29 Oct `favPop`): the
/// heart springs in with an elastic scale, a ring in [burstFarge] spreads
/// out, and ten small hearts and dots shoot out in a wreath; taking it away is
/// a short shrink. Then the toast says «{navn} er lagret i favoritter».
class BergenFavHeart extends StatefulWidget {
  const BergenFavHeart({
    super.key,
    required this.storeId,
    this.size = 30,
    this.iconSize = 15,
    this.onDark = false,
    this.fill,
    this.border,
    this.strokeInk,
    this.burst = false,
    this.burstFarge = const Color(0xFFF26D3D),
    this.navn,
  });

  final int storeId;
  final double size;
  final double iconSize;
  final bool onDark;
  final bool burst;
  final Color burstFarge;
  final String? navn;

  /// Debug: burst the heart of this store id (0: whichever bursting heart
  /// was built first), without touching the favourite.
  static final ValueNotifier<int?> demoBurst = ValueNotifier<int?>(null);
  static int? _forste;

  /// Overrides for a surface that draws its own chip (the Hjem Ark's glass
  /// heart: `rgba(255,255,255,.5)`, `1px rgba(255,255,255,.55)`).
  final Color? fill;
  final Color? border;
  final Color? strokeInk;

  @override
  State<BergenFavHeart> createState() => _BergenFavHeartState();
}

class _BergenFavHeartState extends State<BergenFavHeart>
    with TickerProviderStateMixin {
  static const _orange = Color(0xFFF26D3D);
  static const _ink = Color(0xFF23201D);

  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  // CSS applies animation-timing-function to each keyframe step, so the
  // curve goes on every segment and the controller runs linearly. (On the
  // whole sequence the overshoot would push t past 1.0, which TweenSequence
  // asserts against.)
  static const _popp = Cubic(.34, 1.56, .64, 1);
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.16).chain(CurveTween(curve: _popp)), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 1.16, end: .96).chain(CurveTween(curve: _popp)), weight: 35),
    TweenSequenceItem(tween: Tween(begin: .96, end: 1.0).chain(CurveTween(curve: _popp)), weight: 30),
  ]).animate(_pop);

  bool _busy = false;

  /// `favPop`: the heart's spring (620ms), the chip's bump (480ms), the ring
  /// and the wreath (up to 70 + 760ms).
  late final AnimationController _burst;
  late final AnimationController _krymp;

  @override
  void initState() {
    super.initState();
    _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _krymp = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    FavouriteStores.instance.ensureLoaded();
    if (widget.burst) {
      BergenFavHeart._forste ??= widget.storeId;
      BergenFavHeart.demoBurst.addListener(_onDemo);
    }
  }

  void _onDemo() {
    final id = BergenFavHeart.demoBurst.value;
    if (id == null || !mounted) return;
    if (id == widget.storeId || (id == 0 && BergenFavHeart._forste == widget.storeId)) _burst.forward(from: 0);
  }

  @override
  void dispose() {
    if (widget.burst) BergenFavHeart.demoBurst.removeListener(_onDemo);
    if (BergenFavHeart._forste == widget.storeId) BergenFavHeart._forste = null;
    _pop.dispose();
    _burst.dispose();
    _krymp.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    if (_busy || widget.storeId <= 0) return;
    if (OpsCustomerApi.authParams() == null) {
      showBergenToast(context, FavCopy.loggInn);
      return;
    }
    final favs = FavouriteStores.instance;
    final next = !favs.isFavourite(widget.storeId);
    // Kunde Glatt D6: a tick on the tap (a toggle), the outcome after.
    AeHaptikk.tikk(ny: true);
    final burst = widget.burst && !MediaQuery.disableAnimationsOf(context);
    if (next) {
      if (burst) {
        _burst.forward(from: 0);
      } else {
        _pop.forward(from: 0);
      }
    } else if (burst) {
      _krymp.forward(from: 0);
    }
    _busy = true;
    final ok = await favs.set(widget.storeId, next);
    _busy = false;
    if (!mounted) return;
    if (!ok) {
      AeHaptikk.feil();
    } else if (next) {
      AeHaptikk.fast(ny: true);
    }
    if (widget.burst && ok && !next) return;
    final navn = widget.navn;
    showBergenToast(
      context,
      !ok ? FavCopy.feil : (next ? (widget.burst && navn != null ? FavCopy.lagret(navn) : FavCopy.lagtTil) : FavCopy.fjernet),
      icon: ok && next ? Icons.favorite_rounded : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<int>>(
      valueListenable: FavouriteStores.instance.ids,
      builder: (context, ids, _) {
        final on = ids.contains(widget.storeId);
        final chip = Semantics(
          button: true,
          selected: on,
          label: on ? FavCopy.fjern : FavCopy.leggTil,
          child: GestureDetector(
            key: Key('fav-heart-${widget.storeId}'),
            behavior: HitTestBehavior.opaque,
            onTap: _tap,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.fill ??
                    (widget.onDark
                        ? const Color(0x59000000)
                        : Colors.white.withValues(alpha: .72)),
                border: widget.border != null
                    ? Border.all(color: widget.border!)
                    : widget.onDark
                    ? Border.all(color: const Color(0x40FFFFFF))
                    : null,
              ),
              child: ScaleTransition(
                scale: _scale,
                child: Icon(
                  on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: widget.iconSize,
                  color: on
                      ? _orange
                      : (widget.strokeInk ??
                            (widget.onDark ? Colors.white : _ink)),
                ),
              ),
            ),
          ),
        );
        if (!widget.burst) return chip;
        return AnimatedBuilder(
          animation: Listenable.merge([_burst, _krymp]),
          builder: (context, child) {
            final ms = _burst.value * 900;
            final kr = _krymp.isAnimating ? _krymp.value : 1.0;
            // The chip bumps (`el.animate`, 480ms ease-out) …
            final cp = const Cubic(0, 0, .58, 1).transform((ms / 480).clamp(0.0, 1.0));
            final chipS = _burst.isAnimating ? _kf(cp, const [0, .2, .55, 1], const [1, .9, 1.08, 1]) : 1.0;
            // … the heart springs (620ms ease-out), or shrinks (260ms).
            final hp = const Cubic(0, 0, .58, 1).transform((ms / 620).clamp(0.0, 1.0));
            final heartS = _burst.isAnimating
                ? _kf(hp, const [0, .42, .68, .84, 1], const [.2, 1.45, .88, 1.06, 1])
                : (_krymp.isAnimating ? _kf(const Cubic(0, 0, .58, 1).transform(kr), const [0, .5, 1], const [1, .7, 1]) : 1.0);
            final heartO = _burst.isAnimating ? _kf(hp, const [0, .42, 1], const [.4, 1, 1]) : 1.0;
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (_burst.isAnimating)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: OverflowBox(
                        maxWidth: 160,
                        maxHeight: 160,
                        child: CustomPaint(size: const Size(160, 160), painter: _BurstPainter(ms: ms, farge: widget.burstFarge)),
                      ),
                    ),
                  ),
                Transform.scale(
                  scale: chipS,
                  child: Opacity(
                    opacity: heartO.clamp(0.0, 1.0),
                    child: Transform.scale(scale: heartS, child: child),
                  ),
                ),
              ],
            );
          },
          child: chip,
        );
      },
    );
  }
}

double _kf(double p, List<double> stops, List<double> values) {
  if (p <= stops.first) return values.first;
  for (var i = 0; i < stops.length - 1; i++) {
    if (p <= stops[i + 1]) {
      final u = (p - stops[i]) / (stops[i + 1] - stops[i]);
      return values[i] + (values[i + 1] - values[i]) * u;
    }
  }
  return values.last;
}

/// The ring (3px → 6px → 1px, scale .4 → 1.7, 520ms) and the wreath of ten
/// hearts and dots (640–760ms from 70ms, `cubic-bezier(.2,.9,.3,1)`).
class _BurstPainter extends CustomPainter {
  const _BurstPainter({required this.ms, required this.farge});

  final double ms;
  final Color farge;

  static const Cubic _e = Cubic(.2, .9, .3, 1);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final rp = _e.transform((ms / 520).clamp(0.0, 1.0));
    if (rp < 1) {
      final sc = .4 + 1.3 * rp, op = .9 * (1 - rp), bw = 6 + (1 - 6) * rp;
      canvas.drawCircle(
        c,
        20 * sc - bw / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = bw * sc
          ..color = farge.withValues(alpha: op.clamp(0, 1)),
      );
    }
    final pal = [farge, const Color(0xFFF2C14E), const Color(0xFF5CE0B8), farge, Colors.white];
    for (var i = 0; i < 10; i++) {
      final a = (i / 10) * math.pi * 2 - math.pi / 2 + (i.isOdd ? .18 : 0), d = i.isOdd ? 30.0 : 38.0, hj = i % 3 == 0, s = hj ? 9.0 : (i.isOdd ? 5.0 : 6.0);
      final dur = 640 + (i % 3) * 60;
      final q = _e.transform(((ms - 70) / dur).clamp(0.0, 1.0));
      if (ms < 70 || q >= 1) continue;
      final x = math.cos(a) * d, y = math.sin(a) * d, rot = (i.isOdd ? -1 : 1) * (14 + i * 3.0);
      final tx = _kf(q, const [0, .35, 1], [0, x * .55, x]), ty = _kf(q, const [0, .35, 1], [0, y * .55, y + 4]);
      final sc = _kf(q, const [0, .35, 1], const [.3, 1.1, .4]), op = _kf(q, const [0, .35, 1], const [0, 1, 0]), r = _kf(q, const [0, .35, 1], [0, rot / 2, rot]);
      canvas.save();
      canvas.translate(c.dx + tx, c.dy + ty);
      canvas.rotate(r * math.pi / 180);
      canvas.scale(sc);
      if (hj) {
        final p = Path()
          ..moveTo(0, s / 2 * .7)
          ..cubicTo(-s * .55, -s * .1, -s * .25, -s * .6, 0, -s * .25)
          ..cubicTo(s * .25, -s * .6, s * .55, -s * .1, 0, s / 2 * .7)
          ..close();
        canvas.drawPath(p, Paint()..color = farge.withValues(alpha: op.clamp(0, 1)));
      } else {
        canvas.drawCircle(Offset.zero, s / 2, Paint()..color = pal[i % pal.length].withValues(alpha: op.clamp(0, 1)));
        canvas.drawCircle(
          Offset.zero,
          s / 2,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = Colors.white.withValues(alpha: .6 * op.clamp(0, 1)),
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.ms != ms || old.farge != farge;
}
