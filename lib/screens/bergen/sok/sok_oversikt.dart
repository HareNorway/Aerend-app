import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/ops/sok_models.dart';
import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_css.dart';
import '../kit/bergen_css_shadow.dart';
import '../kit/bergen_motion.dart';
import '../kit/svg_sti.dart';
import 'sok_copy.dart';

/// One remembered search (`sokNylig`: `{ t, n }`).
class SokNylig {
  const SokNylig(this.t, this.n);

  final String t;

  /// When it was searched, ms since epoch.
  final int n;

  /// `nar(n)` (design `sbVals`): "Akkurat nå", "12 min siden", "2 t siden",
  /// "I går", "4 dager siden".
  String nar([DateTime? now]) {
    final ms = (now ?? DateTime.now()).millisecondsSinceEpoch - n;
    final m = (ms / 60000).round();
    if (m < 2) return SokCopy.a1_sok_nar_naa;
    if (m < 60) return SokCopy.a1_sok_nar_min(m);
    final h = (m / 60).round();
    if (h < 24) return SokCopy.a1_sok_nar_t(h);
    final d = (h / 24).round();
    return d == 1 ? SokCopy.a1_sok_nar_igaar : SokCopy.a1_sok_nar_dager(d);
  }
}

/// `Søk · Oversikt` (L5225): Nylige søk, Spør Ægil, Populært i Bergen nå and
/// Ukens oppdrag, 20px apart under a 16px top gap. Full panel width — the
/// chip rows bleed to the panel's edges (`margin:0 -16px`).
class SokOversikt extends StatelessWidget {
  const SokOversikt({
    super.key,
    required this.nylig,
    required this.onNylig,
    required this.onFjern,
    required this.onTom,
    required this.onAegil,
    required this.onEksempel,
    required this.populaert,
    required this.onPopulaert,
    required this.oppdrag,
    required this.onOppdrag,
  });

  final List<SokNylig> nylig;
  final ValueChanged<String> onNylig;
  final ValueChanged<String> onFjern;
  final VoidCallback onTom;

  /// `tilAgent` — the Spør Ægil row.
  final VoidCallback onAegil;

  /// `sokEks1` / `sokEks3` — the example chips fill the field.
  final ValueChanged<String> onEksempel;

  final List<SokTrend> populaert;
  final ValueChanged<String> onPopulaert;

  /// `points.mission`'s `mission`; null hides the card.
  final Map<String, dynamic>? oppdrag;
  final VoidCallback onOppdrag;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final pad = EdgeInsets.symmetric(horizontal: 16 * s);
    final pop = populaert.take(3).toList();
    return Padding(
      padding: EdgeInsets.only(top: 16 * s),
      child: Column(
        key: const Key('a1_sok_oversikt'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Nylige(nylig: nylig, onNylig: onNylig, onFjern: onFjern, onTom: onTom),
          SizedBox(height: 20 * s),
          Padding(
            padding: pad,
            child: _SporAegil(onStart: onAegil, onEksempel: onEksempel),
          ),
          if (pop.isNotEmpty) ...[
            SizedBox(height: 20 * s),
            Padding(
              padding: pad,
              child: _Populaert(rader: pop, onTap: onPopulaert),
            ),
          ],
          if (oppdrag != null) ...[
            SizedBox(height: 20 * s),
            Padding(
              padding: pad,
              child: _Oppdrag(oppdrag: oppdrag!, onTap: onOppdrag),
            ),
          ],
        ],
      ),
    );
  }
}

// ── shared pieces ───────────────────────────────────────────────────────────

const Color _kMint = Color(0xFF9FF0D4);
const Color _kLys = Color(0xFFBFD6DD);

/// A 24-unit stroked icon from the design's SVG `d` (circles written as two
/// arcs), scaled to [size].
class SokIkon extends StatelessWidget {
  const SokIkon(
    this.d, {
    super.key,
    required this.size,
    required this.color,
    required this.stroke,
    this.fill = false,
    this.blur = 0,
  });

  final String d;
  final double size;
  final Color color;
  final double stroke;
  final bool fill;

  /// Blur sigma in screen px, for a `filter: drop-shadow(…)` copy.
  final double blur;

  /// SVG `<circle cx cy r>` as a path.
  static String sirkel(double cx, double cy, double r) =>
      'M${cx - r} ${cy}a$r $r 0 1 0 ${2 * r} 0a$r $r 0 1 0 ${-2 * r} 0';

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _IkonPainter(d, color, stroke, fill, blur),
  );
}

class _IkonPainter extends CustomPainter {
  _IkonPainter(this.d, this.color, this.stroke, this.fill, this.blur);

  final String d;
  final Color color;
  final double stroke;
  final bool fill;
  final double blur;

  static final Map<String, Path> _cache = {};

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final path = _cache.putIfAbsent(d, () => svgSti(d));
    canvas.save();
    canvas.scale(k);
    canvas.drawPath(
      path,
      Paint()
        ..isAntiAlias = true
        ..color = color
        ..style = fill ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = blur > 0 ? MaskFilter.blur(BlurStyle.normal, blur / k) : null,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IkonPainter old) =>
      old.d != d || old.color != color || old.stroke != stroke;
}

/// `#gevir` — Ægil's antlers, in [color].
Widget sokGevir(double w, double h, Color color) => Image.asset(
  'assets/images/dashboard/sok_gevir.png',
  width: w,
  height: h,
  fit: BoxFit.contain,
  color: color,
  colorBlendMode: BlendMode.srcIn,
);

/// The panel's glass: `linear-gradient(180deg,rgba(255,255,255,.15),
/// rgba(255,255,255,.06))`, `inset 0 1.5px 0 rgba(255,255,255,.3)`,
/// `inset 0 0 0 1px rgba(255,255,255,.12)`, `0 3px 0 rgba(8,28,36,.45)`,
/// `0 18px 26px -18px rgba(3,14,20,.85)`.
class SokGlass extends StatelessWidget {
  const SokGlass({
    super.key,
    required this.radius,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.ring = const Color.fromRGBO(255, 255, 255, .12),
    this.inset = .3,
    this.under,
  });

  final double radius;
  final EdgeInsets padding;
  final Widget child;
  final Color ring;
  final double inset;

  /// An extra background layer over the glass gradient (the Spør Ægil
  /// card's mint corner glow).
  final Gradient? under;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final r = BorderRadius.circular(radius);
    return BergenCssShadow(
      radius: radius,
      shadows: [
        BoxShadow(color: rgba(8, 28, 36, .45), offset: Offset(0, 3 * s)),
        BoxShadow(
          color: rgba(3, 14, 20, .85),
          offset: Offset(0, 18 * s),
          blurRadius: onbBlur(26 * s),
          spreadRadius: -18 * s,
        ),
      ],
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: r,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [rgba(255, 255, 255, .15), rgba(255, 255, 255, .06)],
          ),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: r,
          border: Border.all(color: ring),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -padding.left,
              right: -padding.right,
              top: -padding.top,
              bottom: -padding.bottom,
              child: Stack(
                children: [
                  if (under != null)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: r,
                          gradient: under,
                        ),
                      ),
                    ),
                  bergenInsetTop(radius: radius, height: 1.5 * s, alpha: inset),
                ],
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// The teal icon tile (`linear-gradient(160deg,#3F8798 0%,#27606F 52%,
/// #1A4654 100%)`, `inset 0 1.5px 0 rgba(255,255,255,.32)`, `inset 0 -3px
/// 5px rgba(4,20,28,.42)`, `0 0 0 1px rgba(255,255,255,.07)`, `0 8px 10px
/// -6px rgba(3,16,24,.8)`).
class SokFlis extends StatelessWidget {
  const SokFlis({
    super.key,
    required this.size,
    required this.radius,
    required this.child,
  });

  final double size;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final r = BorderRadius.circular(radius);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: cssLinear(
          160,
          const [Color(0xFF3F8798), Color(0xFF27606F), Color(0xFF1A4654)],
          const [0, .52, 1],
        ),
        boxShadow: [
          BoxShadow(color: rgba(255, 255, 255, .07), spreadRadius: 1),
          BoxShadow(
            color: rgba(3, 16, 24, .8),
            offset: Offset(0, 8 * s),
            blurRadius: onbBlur(10 * s),
            spreadRadius: -6 * s,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          sokInsetBunn(radius: radius, extent: 7 * s, alpha: .42, rgb: const [4, 20, 28]),
          bergenInsetTop(radius: radius, height: 1.5 * s, alpha: .32),
          child,
        ],
      ),
    );
  }
}

/// CSS `inset 0 -3px 5px rgba(…)`: the shade rising from the bottom edge,
/// as a short gradient inside the box's clip.
Widget sokInsetBunn({
  required double radius,
  required double extent,
  required double alpha,
  required List<int> rgb,
}) => Positioned.fill(
  child: IgnorePointer(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: extent,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  rgba(rgb[0], rgb[1], rgb[2], alpha * .88),
                  rgba(rgb[0], rgb[1], rgb[2], alpha * .5),
                  rgba(rgb[0], rgb[1], rgb[2], 0),
                ],
                stops: const [0, .43, 1],
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

/// `vcKort .42s <i·.05>s cubic-bezier(.2,1.15,.3,1) both`.
class _VcKort extends StatelessWidget {
  const _VcKort({super.key, required this.i, required this.child});

  final int i;
  final Widget child;

  static const Curve _c = Cubic(.2, 1.15, .3, 1);

  @override
  Widget build(BuildContext context) => BergenOnce(
    durationMs: 420,
    delayMs: i * 50.0,
    child: child,
    builder: (context, p, child) {
      final e = _c.transform(p.clamp(0.0, 1.0));
      return Opacity(
        opacity: e.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 14 * context.bs * (1 - e)),
          child: Transform.scale(scale: .96 + .04 * e, child: child),
        ),
      );
    },
  );
}

// ── Søk · Nylige søk (L5226) ────────────────────────────────────────────────

class _Nylige extends StatelessWidget {
  const _Nylige({
    required this.nylig,
    required this.onNylig,
    required this.onFjern,
    required this.onTom,
  });

  final List<SokNylig> nylig;
  final ValueChanged<String> onNylig;
  final ValueChanged<String> onFjern;
  final VoidCallback onTom;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final har = nylig.isNotEmpty;
    return Column(
      key: const Key('a1_sok_nylig'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20 * s),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  SokCopy.a1_sok_nylig,
                  style: bDisplay(context, 15, color: Colors.white),
                ),
              ),
              if (har)
                GestureDetector(
                  key: const Key('a1_sok_tom_nylig'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onTom,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 4 * s,
                      horizontal: 2 * s,
                    ),
                    child: Text(
                      SokCopy.a1_sok_clear_recent,
                      style: bText(
                        context,
                        11.5,
                        weight: FontWeight.w800,
                        color: const Color(0xFF9FE0C8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 10 * s),
        if (har)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.fromLTRB(16 * s, 2 * s, 16 * s, 8 * s),
            child: Row(
              children: [
                for (var i = 0; i < nylig.length; i++) ...[
                  if (i > 0) SizedBox(width: 8 * s),
                  _VcKort(
                    key: ValueKey('nylig-${nylig[i].t}'),
                    i: i,
                    child: _NyligChip(
                      n: nylig[i],
                      onTap: () => onNylig(nylig[i].t),
                      onFjern: () => onFjern(nylig[i].t),
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20 * s),
            child: Text(
              SokCopy.a1_sok_ingen_nylig,
              style: bText(context, 12, weight: FontWeight.w600, color: _kLys),
            ),
          ),
      ],
    );
  }
}

class _NyligChip extends StatelessWidget {
  const _NyligChip({
    required this.n,
    required this.onTap,
    required this.onFjern,
  });

  final SokNylig n;
  final VoidCallback onTap;
  final VoidCallback onFjern;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return SizedBox(
      height: 40 * s,
      child: SokGlass(
        radius: 14 * s,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OnbPressable(
              onTap: onTap,
              pressDy: 0,
              pressScale: .96,
              child: Padding(
                padding: EdgeInsets.only(left: 12 * s, right: 4 * s),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SokIkon(
                      '${SokIkon.sirkel(12, 12, 9)}M12 7v5l3 2',
                      size: 13 * s,
                      color: _kMint,
                      stroke: 2.6,
                    ),
                    SizedBox(width: 7 * s),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.t,
                          maxLines: 1,
                          style: bText(
                            context,
                            13,
                            weight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          n.nar(),
                          maxLines: 1,
                          style: bText(
                            context,
                            9.5,
                            weight: FontWeight.w700,
                            height: 1.1,
                            color: _kLys,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onFjern,
              child: SizedBox(
                width: 30 * s,
                height: 40 * s,
                child: Center(
                  child: SokIkon(
                    'M6 6l12 12M18 6L6 18',
                    size: 9 * s,
                    color: rgba(255, 255, 255, .55),
                    stroke: 3.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Søk · Spør Ægil (L5242) ─────────────────────────────────────────────────

class _SporAegil extends StatelessWidget {
  const _SporAegil({required this.onStart, required this.onEksempel});

  final VoidCallback onStart;
  final ValueChanged<String> onEksempel;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return SokGlass(
      key: const Key('a1_sok_aegil_card'),
      radius: 24 * s,
      inset: .32,
      ring: rgba(92, 224, 184, .32),
      // `radial-gradient(90% 80% at 0% 0%, rgba(92,224,184,.22),
      // rgba(92,224,184,0) 60%)`.
      under: RadialGradient(
        center: Alignment.topLeft,
        radius: 1,
        colors: [rgba(92, 224, 184, .22), rgba(92, 224, 184, 0)],
        stops: const [0, .6],
        transform: const _CssEllipse(.9, .8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24 * s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(14 * s, 14 * s, 14 * s, 0),
              child: OnbPressable(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onStart();
                },
                pressDy: 0,
                pressScale: .985,
                child: Row(
                  children: [
                    const _AegilAvatar(),
                    SizedBox(width: 12 * s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              sokGevir(15 * s, 9 * s, _kMint),
                              SizedBox(width: 6 * s),
                              Text(
                                SokCopy.a1_sok_aegil_kicker,
                                style: bText(
                                  context,
                                  10,
                                  weight: FontWeight.w800,
                                  letterSpacingEm: .08,
                                  color: _kMint,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2 * s),
                          Text(
                            SokCopy.a1_sok_aegil_line,
                            style: bDisplay(
                              context,
                              15,
                              letterSpacingEm: -.02,
                              height: 1.25,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12 * s),
                    const _ChatKey(),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12 * s),
            // `margin:12px -14px 0; padding:0 14px 2px` — the row scrolls
            // to the card's edges.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.fromLTRB(14 * s, 0, 14 * s, 2 * s),
              child: Row(
                children: [
                  _Eksempel(
                    tekst: SokCopy.a1_sok_aegil_eks1,
                    onTap: () => onEksempel(SokCopy.a1_sok_aegil_eks1),
                  ),
                  SizedBox(width: 7 * s),
                  _Eksempel(
                    tekst: SokCopy.a1_sok_aegil_eks2,
                    onTap: () => onEksempel(SokCopy.a1_sok_aegil_eks2),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14 * s),
          ],
        ),
      ),
    );
  }
}

class _Eksempel extends StatelessWidget {
  const _Eksempel({required this.tekst, required this.onTap});

  final String tekst;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return OnbPressable(
      onTap: onTap,
      pressDy: 2 * s,
      child: Container(
        padding: EdgeInsets.fromLTRB(10 * s, 8 * s, 12 * s, 8 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: rgba(6, 22, 30, .32),
          border: Border.all(color: rgba(159, 240, 212, .36)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SokIkon(
              'M4 5v6a4 4 0 0 0 4 4h12M15 10l5 5-5 5',
              size: 10 * s,
              color: _kMint,
              stroke: 3,
            ),
            SizedBox(width: 6 * s),
            Text(
              tekst,
              maxLines: 1,
              style: bText(
                context,
                12,
                weight: FontWeight.w800,
                color: const Color(0xFFDFF8EE),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ægil in his 52px window: `vcPuls 2.2s` ring, `aegVink 2.6s` wave.
class _AegilAvatar extends StatelessWidget {
  const _AegilAvatar();

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return SizedBox(
      width: 52 * s,
      height: 52 * s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // `inset:-4px; border:1.5px solid rgba(92,224,184,.6)`,
          // `vcPuls 2.2s ease-out infinite` (scale .9 → 1.35, .9 → 0).
          Positioned(
            left: -4 * s,
            top: -4 * s,
            right: -4 * s,
            bottom: -4 * s,
            child: RepaintBoundary(
              child: BergenLoop(
                durationMs: 2200,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: rgba(92, 224, 184, .6),
                      width: 1.5 * s,
                    ),
                  ),
                ),
                builder: (context, p, child) {
                  final e = Curves.easeOut.transform(p ?? 0);
                  return Opacity(
                    opacity: (.9 * (1 - e)).clamp(0.0, 1.0),
                    child: Transform.scale(scale: .9 + .45 * e, child: child),
                  );
                },
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: rgba(255, 255, 255, .85),
                    spreadRadius: 2 * s,
                  ),
                  BoxShadow(
                    color: rgba(3, 16, 24, .8),
                    offset: Offset(0, 8 * s),
                    blurRadius: onbBlur(12 * s),
                    spreadRadius: -6 * s,
                  ),
                ],
              ),
              child: ClipOval(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: cssLinear(160, const [
                      Color(0xFFDCE9EC),
                      Color(0xFF9FB6C2),
                    ]),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: -10 * s,
                        top: 3 * s,
                        width: 74 * s,
                        child: RepaintBoundary(
                          child: sokVink(
                            Image.asset(BergenAssets.aegilPopup, width: 74 * s),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `aegVink 2.6s ease-in-out infinite` (rotate 0 → -6° → 6° → 0, from the
/// bottom centre).
Widget sokVink(Widget child) => BergenLoop(
  durationMs: 2600,
  child: child,
  builder: (context, p, child) {
    final r = p == null
        ? 0.0
        : kf(p, const [0, .25, .75, 1], const [0, -6, 6, 0], Curves.easeInOut);
    return Transform.rotate(
      angle: r * math.pi / 180,
      alignment: Alignment.bottomCenter,
      child: child,
    );
  },
);

/// The orange chat key (44px, radius 15).
class _ChatKey extends StatelessWidget {
  const _ChatKey();

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      width: 44 * s,
      height: 44 * s,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15 * s),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF9466), Color(0xFFE95C2C)],
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFFA63A12), offset: Offset(0, 3 * s)),
          BoxShadow(
            color: rgba(3, 16, 24, .75),
            offset: Offset(0, 10 * s),
            blurRadius: onbBlur(14 * s),
            spreadRadius: -8 * s,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          sokInsetBunn(radius: 15 * s, extent: 2 * s, alpha: .08, rgb: const [0, 0, 0]),
          bergenInsetTop(radius: 15 * s, height: 1 * s, alpha: .45),
          SokIkon(
            'M4 5h16v11H9l-5 4z',
            size: 18 * s,
            color: Colors.white,
            stroke: 2.4,
          ),
        ],
      ),
    );
  }
}

/// CSS `radial-gradient(<rx>% <ry>% at 0% 0%, …)`: Flutter's radial is a
/// circle on the box's shortest side; this stretches it to the ellipse.
class _CssEllipse extends GradientTransform {
  const _CssEllipse(this.rx, this.ry);

  final double rx;
  final double ry;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final short = math.min(bounds.width, bounds.height) / 2;
    final sx = rx * bounds.width / short;
    final sy = ry * bounds.height / short;
    return Matrix4.identity()
      ..translateByDouble(bounds.left, bounds.top, 0, 1)
      ..scaleByDouble(sx, sy, 1, 1)
      ..translateByDouble(-bounds.left, -bounds.top, 0, 1);
  }
}

// ── Søk · Populært nå (L5259) ───────────────────────────────────────────────

class _Populaert extends StatelessWidget {
  const _Populaert({required this.rader, required this.onTap});

  final List<SokTrend> rader;
  final ValueChanged<String> onTap;

  /// The rank figures: gold, silver, bronze.
  static const List<Color> _rang = [
    Color(0xFFFFD27A),
    Color(0xFFDCE9EC),
    Color(0xFFE9B27A),
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Column(
      key: const Key('a1_sok_populaert'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4 * s),
          child: Row(
            children: [
              const _PulsDot(),
              SizedBox(width: 8 * s),
              Text(
                SokCopy.a1_sok_populaert,
                style: bDisplay(context, 15, color: Colors.white),
              ),
            ],
          ),
        ),
        SizedBox(height: 10 * s),
        SokGlass(
          radius: 22 * s,
          padding: EdgeInsets.symmetric(vertical: 2 * s),
          child: Column(
            children: [
              for (var i = 0; i < rader.length; i++)
                OnbPressable(
                  onTap: () => onTap(rader[i].term),
                  pressDy: 0,
                  pressScale: .985,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(12 * s, 10 * s, 10 * s, 10 * s),
                    decoration: BoxDecoration(
                      border: i == 0
                          ? null
                          : Border(
                              top: BorderSide(color: rgba(255, 255, 255, .08)),
                            ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18 * s,
                          child: Text(
                            '${i + 1}',
                            textAlign: TextAlign.center,
                            style: bDisplay(
                              context,
                              20,
                              letterSpacingEm: -.04,
                              height: 1,
                              color: _rang[i % 3],
                            ).copyWith(
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        SizedBox(width: 12 * s),
                        SokFlis(
                          size: 36 * s,
                          radius: 12 * s,
                          child: SokIkon(
                            sokTrendIkon(rader[i].term),
                            size: 18 * s,
                            color: Colors.white,
                            stroke: 2.2,
                          ),
                        ),
                        SizedBox(width: 12 * s),
                        Expanded(
                          child: Text(
                            rader[i].term,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: bText(context, 14, weight: FontWeight.w800),
                          ),
                        ),
                        if (rader[i].count != null) ...[
                          SizedBox(width: 12 * s),
                          _SokTall(n: rader[i].count!),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The design's three term icons (soup, cinnamon swirl, pizza slice), picked
/// by what the term is; anything else gets the plain search glass.
String sokTrendIkon(String term) {
  final t = term.toLowerCase();
  if (RegExp('suppe|gryte|ramen|pho|nudel').hasMatch(t)) {
    return 'M3 11h18a9 9 0 0 1-18 0zM8 7c0-1.5 1-2 1-3M12 7c0-1.5 1-2 1-3M16 7c0-1.5 1-2 1-3';
  }
  if (RegExp('bolle|kanel|bakst|bakeri|kake|croissant|skolebrød').hasMatch(t)) {
    return 'M12 4a8 8 0 1 0 0 16a8 8 0 1 0 0-16M12 12c0-1.6 2.6-1.6 2.6 0s-1.8 3.4-4.4 2.6-2.6-5.2 1-6 6 1.8 5.2 5.2';
  }
  if (RegExp('pizza|calzone').hasMatch(t)) {
    return 'M12 3L3 20c6 2 12 2 18 0zM9.5 14h.01M14 16h.01M12 10h.01';
  }
  return '${SokIkon.sirkel(11, 11, 7)}M20.5 20.5l-4.3-4.3';
}

/// "38 søk" with the trend arrow.
class _SokTall extends StatelessWidget {
  const _SokTall({required this.n});

  final int n;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      padding: EdgeInsets.fromLTRB(7 * s, 4 * s, 9 * s, 4 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: rgba(92, 224, 184, .14),
        border: Border.all(color: rgba(92, 224, 184, .3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SokIkon(
            'M4 16l6-6 4 4 6-7M14 7h6v6',
            size: 9 * s,
            color: _kMint,
            stroke: 3.2,
          ),
          SizedBox(width: 4 * s),
          Text(
            SokCopy.a1_sok_antall(n),
            style: bText(
              context,
              10.5,
              weight: FontWeight.w800,
              color: _kMint,
            ),
          ),
        ],
      ),
    );
  }
}

/// `pulsDot 1.8s ease-in-out infinite` — the orange live dot.
class _PulsDot extends StatelessWidget {
  const _PulsDot();

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return RepaintBoundary(
      child: BergenLoop(
        durationMs: 1800,
        child: Container(
          width: 7 * s,
          height: 7 * s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFF9466),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9466),
                blurRadius: onbBlur(8 * s),
              ),
            ],
          ),
        ),
        builder: (context, p, child) {
          if (p == null) return child!;
          final sc = kf(p, const [0, .5, 1], const [1, 1.35, 1], Curves.easeInOut);
          final o = kf(p, const [0, .5, 1], const [1, .7, 1], Curves.easeInOut);
          return Opacity(
            opacity: o,
            child: Transform.scale(scale: sc, child: child),
          );
        },
      ),
    );
  }
}

// ── Søk · Ukens oppdrag (L5282) ─────────────────────────────────────────────

class _Oppdrag extends StatelessWidget {
  const _Oppdrag({required this.oppdrag, required this.onTap});

  final Map<String, dynamic> oppdrag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final poeng = (oppdrag['points'] as num?)?.toInt() ?? 0;
    final maal = (oppdrag['target'] as num?)?.toInt() ?? 1;
    final gjort = (oppdrag['progress'] as num?)?.toInt() ?? 0;
    return OnbPressable(
      onTap: onTap,
      pressDy: 0,
      pressScale: .985,
      child: SokGlass(
        key: const Key('a1_sok_oppdrag'),
        radius: 22 * s,
        padding: EdgeInsets.all(12 * s),
        child: Row(
          children: [
            SokFlis(
              size: 46 * s,
              radius: 15 * s,
              child: Image.asset(
                'assets/images/dashboard/sok_v_varde.png',
                width: 22 * s,
                height: 28 * s,
              ),
            ),
            SizedBox(width: 12 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    SokCopy.a1_sok_oppdrag_tittel,
                    style: bText(
                      context,
                      10,
                      weight: FontWeight.w800,
                      letterSpacingEm: .08,
                      color: _kMint,
                    ),
                  ),
                  SizedBox(height: 2 * s),
                  Text(
                    '${oppdrag['title'] ?? ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: bDisplay(
                      context,
                      14,
                      letterSpacingEm: -.015,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2 * s),
                  Text(
                    SokCopy.a1_sok_oppdrag_teller(gjort, maal),
                    style: bText(
                      context,
                      11,
                      weight: FontWeight.w600,
                      color: _kLys,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12 * s),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 4 * s),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9 * s),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFE7A8), Color(0xFFE9AC3C)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFA87418),
                    offset: Offset(0, 2 * s),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -9 * s,
                    right: -9 * s,
                    top: -4 * s,
                    bottom: -4 * s,
                    child: Stack(
                      children: [
                        bergenInsetTop(radius: 9 * s, height: 1 * s, alpha: .6),
                      ],
                    ),
                  ),
                  Text(
                    SokCopy.a1_sok_oppdrag_poeng(poeng),
                    style: bDisplay(
                      context,
                      12,
                      color: const Color(0xFF4A300A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
