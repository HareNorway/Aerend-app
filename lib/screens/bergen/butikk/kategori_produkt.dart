import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/bergen_tokens.dart';
import '../../common/auth/onboarding_kit.dart' show onbBlur;
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_css.dart';
import '../kit/bergen_lagring.dart' show BergenLagringLive;
import '../kit/bergen_motion.dart';
import '../kit/bergen_perf.dart';
import '../sok/sok_oversikt.dart' show SokIkon;
import 'kategori_kort.dart';

/// Kategori › Produkter (Onboarding plan Step 6, §3 #16, prototype
/// `data-screen-label="Produktkort"` L6827–6885): the «plate on the cloth»
/// cards — the hero (first card, full width) and the small ones — with the
/// product photo (Ken Burns, parallax from the tilt) or the 3D icon, the
/// rotated tag, the store mark, the eta chip, and the stepper that grows
/// out of the «+».

const Color _kInk = Color(0xFF23201D);
const Color _kGra = Color(0xFF6E675D);

/// The cloth colours per store (`bord` / `bordDyp`).
const List<Color> kKatBord = [Color(0xFFFFE4D2), Color(0xFFFFDAD6), Color(0xFFFFEBC6), Color(0xFFFFDDE2)];
const List<Color> kKatBordDyp = [Color(0xFFF5BC9A), Color(0xFFF1A9A2), Color(0xFFF2CB85), Color(0xFFEFB0BA)];

/// The tag's colours (`tagBg` / `tagFg`): «Tilbud» orange, «Ny» white on
/// red, else («Mest kjøpt») gold on ink.
({Gradient? gradient, Color? color, Color fg}) katTagFarger(String tag, {required String tilbud, required String ny}) {
  if (tag == tilbud) return (gradient: cssLinear(160, const [Color(0xFFF2884E), Color(0xFFE0662C)]), color: null, fg: Colors.white);
  if (tag == ny) return (gradient: null, color: Colors.white, fg: const Color(0xFFB8380F));
  return (gradient: null, color: const Color(0xFFF2C14E), fg: _kInk);
}

/// The store mark without a logo (`pmLogo`): initials on a colour hashed
/// from the name.
({String mono, Color bg}) katMerke(String navn) {
  var h = 0;
  for (final c in navn.codeUnits) {
    h = (h * 31 + c) % 997;
  }
  final mono = navn.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).map((w) => w[0]).join().toUpperCase();
  return (mono: mono.length > 2 ? mono.substring(0, 2) : mono, bg: const [Color(0xFFB0472C), Color(0xFF2A6272), Color(0xFF8A5A1E), Color(0xFF4A3A6B)][h % 4]);
}

/// The grid: the hero spans both columns, the rest go in pairs.
List<List<int>> katProduktRader(int n) {
  if (n == 0) return const [];
  final r = <List<int>>[
    [0],
  ];
  for (var i = 1; i < n; i += 2) {
    r.add(i + 1 < n ? [i, i + 1] : [i]);
  }
  return r;
}

class KatProduktKortNy extends StatelessWidget {
  const KatProduktKortNy({
    super.key,
    required this.p,
    required this.hero,
    required this.ant,
    required this.onTap,
    required this.onLegg,
    required this.onMinus,
    required this.tilbud,
    required this.ny,
  });

  final KatProduktVis p;
  final bool hero;

  /// Lines of this product in the cart (`ant`): 0 shows the «+», else the stepper.
  final int ant;
  final VoidCallback onTap, onLegg, onMinus;

  /// The tag words (to colour them).
  final String tilbud, ny;

  @override
  Widget build(BuildContext context) {
    final fase = p.nr * 2300.0;
    return _Inn(
      delayMs: p.nr * 60.0,
      child: KatSvevKort(
        key: ValueKey('kat-p-${p.id}'),
        perspektiv: 780,
        svevMs: 9000,
        faseMs: fase,
        tiltK: 9,
        trykk: .975,
        onTap: onTap,
        builder: (context, lys) => hero ? _Hero(p: p, lys: lys, ant: ant, onLegg: onLegg, onMinus: onMinus, tilbud: tilbud, ny: ny) : _Liten(p: p, lys: lys, ant: ant, onLegg: onLegg, onMinus: onMinus, tilbud: tilbud, ny: ny),
      ),
    );
  }
}

/// `pmInn .7s <delay> cubic-bezier(.2,.9,.25,1)`: from 46 px below, tipped
/// back 24° in perspective.
class _Inn extends StatelessWidget {
  const _Inn({required this.delayMs, required this.child});
  final double delayMs;
  final Widget child;
  static const Curve _c = Cubic(.2, .9, .25, 1);

  @override
  Widget build(BuildContext context) {
    if (BergenPerf.of(context) == BergenTier.still || MediaQuery.disableAnimationsOf(context)) return child;
    final s = context.bs;
    return BergenOnce(
      durationMs: 700,
      delayMs: delayMs,
      child: child,
      builder: (context, p, child) {
        final e = _c.transform(p);
        final m = Matrix4.identity()
          ..setEntry(3, 2, -1 / (900 * s))
          ..translateByDouble(0, 46 * s * (1 - e), -80 * s * (1 - e), 1)
          ..rotateX(24 * math.pi / 180 * (1 - e));
        return Opacity(opacity: e.clamp(0.0, 1.0), child: Transform(alignment: Alignment.center, transform: m, child: child));
      },
    );
  }
}

BoxDecoration _kortDeko(double s, double r) => BoxDecoration(
  borderRadius: BorderRadius.circular(r * s),
  gradient: cssLinear(180, const [Color(0xFFFFFDF9), Color(0xFFFAF3EA), Color(0xFFF4EADD)], const [0, .55, 1]),
  boxShadow: [
    BoxShadow(color: rgba(255, 255, 255, .6), spreadRadius: 1),
    BoxShadow(color: rgba(205, 188, 160, .9), offset: Offset(0, 2 * s)),
    BoxShadow(color: rgba(4, 18, 26, .4), offset: Offset(0, 6 * s), blurRadius: onbBlur(12 * s), spreadRadius: -8 * s),
    BoxShadow(color: rgba(4, 18, 26, .85), offset: Offset(0, 26 * s), blurRadius: onbBlur(36 * s), spreadRadius: -20 * s),
  ],
);

// ── Hero ────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({required this.p, required this.lys, required this.ant, required this.onLegg, required this.onMinus, required this.tilbud, required this.ny});
  final KatProduktVis p;
  final Offset lys;
  final int ant;
  final VoidCallback onLegg, onMinus;
  final String tilbud, ny;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final butikkEta = p.eta != null ? '${p.butikk} · ${p.eta}' : p.butikk;
    return Container(
      decoration: _kortDeko(s, 28),
      padding: EdgeInsets.all(7 * s),
      child: LayoutBuilder(
        builder: (context, c) => ConstrainedBox(
          constraints: BoxConstraints(minHeight: (210 - 14) * s),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(9 * s, 9 * s, 12 * s, 7 * s),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (p.tag != null) Align(alignment: Alignment.centerLeft, child: Transform.rotate(angle: -4 * math.pi / 180, child: _Tag(tag: p.tag!, tilbud: tilbud, ny: ny))),
                        SizedBox(height: 10 * s),
                        Text(p.navn, style: bDisplay(context, 20, letterSpacingEm: -.03, height: 1.12, color: _kInk)),
                        SizedBox(height: 8 * s),
                        Row(children: [
                          _Merke(navn: p.butikk, logoUrl: p.logoUrl, size: 26),
                          SizedBox(width: 7 * s),
                          Expanded(child: Text(butikkEta, maxLines: 1, overflow: TextOverflow.ellipsis, style: bText(context, 12, weight: FontWeight.w700, color: const Color(0xFF5E574D)))),
                        ]),
                        if ((p.besk ?? '').isNotEmpty) ...[
                          SizedBox(height: 6 * s),
                          Text(p.besk!, maxLines: 3, overflow: TextOverflow.ellipsis, style: bText(context, 12, weight: FontWeight.w500, height: 1.35, color: const Color(0xFF5E574D))),
                        ],
                        SizedBox(height: 10 * s),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(p.pris, maxLines: 1, style: bDisplay(context, 21, letterSpacingEm: -.02, color: _kInk).copyWith(fontFeatures: const [FontFeature.tabularFigures()])))),
                            SizedBox(width: 8 * s),
                            _Stepper(ant: ant, stor: true, onLegg: onLegg, onMinus: onMinus, navn: p.navn),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // The plate: the right 46 % of the card, lifted 34 px in Z (`pmLoft`).
                SizedBox(
                  width: (c.maxWidth) * .46,
                  child: katZ(34 * s, _Tallerken(p: p, lys: lys, ikS: 150, delayMs: (p.nr * .06 + .12) * 1000)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Small ───────────────────────────────────────────────────────────────────

class _Liten extends StatelessWidget {
  const _Liten({required this.p, required this.lys, required this.ant, required this.onLegg, required this.onMinus, required this.tilbud, required this.ny});
  final KatProduktVis p;
  final Offset lys;
  final int ant;
  final VoidCallback onLegg, onMinus;
  final String tilbud, ny;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      decoration: _kortDeko(s, 26),
      padding: EdgeInsets.fromLTRB(7 * s, 7 * s, 7 * s, 13 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 168 * s,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: katZ(34 * s, _Tallerken(p: p, lys: lys, ikS: 120, delayMs: (p.nr * .06 + .12) * 1000))),
                if (p.tag != null)
                  Positioned(left: 10 * s, top: 10 * s, child: katZ(64 * s, Transform.rotate(angle: -7 * math.pi / 180, child: _Tag(tag: p.tag!, tilbud: tilbud, ny: ny)))),
                Positioned(left: 9 * s, bottom: 9 * s, child: katZ(60 * s, _Merke(navn: p.butikk, logoUrl: p.logoUrl, size: 34, ring: true))),
                Positioned(right: 8 * s, bottom: 8 * s, child: katZ(68 * s, _Stepper(ant: ant, stor: false, onLegg: onLegg, onMinus: onMinus, navn: p.navn))),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(6 * s, 12 * s, 6 * s, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.navn, maxLines: 2, overflow: TextOverflow.ellipsis, style: bDisplay(context, 14.5, letterSpacingEm: -.02, height: 1.2, color: _kInk)),
                SizedBox(height: 3 * s),
                Text(p.butikk, maxLines: 1, overflow: TextOverflow.ellipsis, style: bText(context, 11.5, weight: FontWeight.w700, color: const Color(0xFF7A7266))),
                SizedBox(height: 9 * s),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(p.pris, style: bDisplay(context, 16.5, letterSpacingEm: -.02, color: _kInk).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                    if (p.eta != null) ...[
                      SizedBox(width: 6 * s),
                      Flexible(
                        child: Container(
                          height: 22 * s,
                          padding: EdgeInsets.fromLTRB(6 * s, 0, 8 * s, 0),
                          decoration: BoxDecoration(color: rgba(35, 32, 29, .055), borderRadius: BorderRadius.circular(999), border: Border.all(color: rgba(35, 32, 29, .05))),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            SokIkon('${SokIkon.sirkel(12, 12, 8.5)}M12 7.5V12l3 2', size: 11 * s, color: const Color(0xFF8A8174), stroke: 2.6),
                            SizedBox(width: 4 * s),
                            Flexible(child: Text(p.eta!, maxLines: 1, overflow: TextOverflow.ellipsis, style: bText(context, 10.5, weight: FontWeight.w700, color: _kGra))),
                          ]),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Parts ───────────────────────────────────────────────────────────────────

/// The plate (`translateZ(34px)`, `pmLoft .9s`): the dotted cloth with the
/// store's tint, the photo with `pmKB 16s` and the tilt parallax, the soft
/// light and `pmGlans 7.5s`; without a photo the 3D icon floats (`bmFlyt`).
class _Tallerken extends StatelessWidget {
  const _Tallerken({required this.p, required this.lys, required this.ikS, required this.delayMs});
  final KatProduktVis p;
  final Offset lys;
  final double ikS;
  final double delayMs;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final r = BorderRadius.circular(22 * s);
    final bord = kKatBord[p.fargeNr % 4], dyp = kKatBordDyp[p.fargeNr % 4];
    final rolig = BergenPerf.of(context) == BergenTier.still || MediaQuery.disableAnimationsOf(context);
    final foto = (p.bildeUrl ?? '').isNotEmpty;
    final fase = p.nr * 2300.0;
    // `--px/--py` from the tilt: the light offset is the pointer in [0,1].
    final px = (lys.dx - .5).clamp(-.5, .5), py = (lys.dy - .5).clamp(-.5, .5);
    Widget plate = Container(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [
          BoxShadow(color: rgba(255, 255, 255, .4), spreadRadius: 1),
          BoxShadow(color: rgba(60, 24, 8, .62), offset: Offset(0, 20 * s), blurRadius: onbBlur(26 * s), spreadRadius: -16 * s),
          BoxShadow(color: rgba(60, 24, 8, .32), offset: Offset(0, 5 * s), blurRadius: onbBlur(10 * s), spreadRadius: -6 * s),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(center: Alignment.topCenter, radius: 1.15, colors: [bord, dyp]))),
            const DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(center: Alignment(0, -.48), radius: .95, colors: [Color(0x99FFFFFF), Color(0x00FFFFFF)], stops: [0, .62]))),
            CustomPaint(painter: _PrikkMaler(9 * s, .9 * s)),
            if (foto)
              Positioned(
                left: -14 * s - px * 18 * s,
                right: -14 * s + px * 18 * s,
                top: -14 * s - py * 18 * s,
                bottom: -14 * s + py * 18 * s,
                child: _KenBurns(rolig: rolig, delayMs: fase, durMs: 16000, child: _foto(p.bildeUrl!)),
              ),
            // Heat plan Step 8: `soft-light` blends with the screen beneath.
            IgnorePointer(
              child: BergenLagringLive(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(center: Alignment(lys.dx * 2 - 1, lys.dy * 2 - 1), radius: .7, colors: [rgba(255, 255, 255, .4), rgba(255, 255, 255, 0)], stops: const [0, .7]),
                    backgroundBlendMode: BlendMode.softLight,
                  ),
                ),
              ),
            ),
            if (!rolig) IgnorePointer(child: _Glans(delayMs: fase)),
            IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(borderRadius: r, border: Border.all(color: rgba(255, 255, 255, .22))))),
            bergenInsetTop(radius: 22 * s, height: 1.5 * s, alpha: .45),
          ],
        ),
      ),
    );
    plate = _Loft(delayMs: delayMs, rolig: rolig, child: plate);
    if (foto) return plate;
    final ikon = katIkonFor(p);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: plate),
        Center(
          child: katZ(
            44 * s,
            SizedBox(
              width: ikS * s,
              height: ikS * s,
              child: Stack(children: [
                Positioned(
                  left: ikS * s * .16,
                  right: ikS * s * .16,
                  bottom: -ikS * s * .02,
                  height: ikS * s * .12,
                  child: const DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0x733C1404), Color(0x003C1404)]))),
                ),
                Positioned.fill(
                  child: rolig
                      ? SvgPicture.asset('assets/images/kategori/$ikon.svg', fit: BoxFit.contain)
                      : BergenLoop(
                          durationMs: 4600,
                          delayMs: -fase % 4600,
                          child: SvgPicture.asset('assets/images/kategori/$ikon.svg', fit: BoxFit.contain),
                          builder: (context, q, child) {
                            final e = .5 - .5 * math.cos((q ?? 0) * 2 * math.pi);
                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..translateByDouble(0, -4 * s * e, 0, 1)
                                ..rotateZ((-1.5 + 3 * e) * math.pi / 180),
                              child: child,
                            );
                          },
                        ),
                ),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

/// The product's 3D icon by its name, else its category's (`ik`).
String katIkonFor(KatProduktVis p) => p.ikon ?? 'ico_mat';

/// `pmLoft .9s <delay> cubic-bezier(.2,1,.3,1)`: tipped −38° and small, up past
/// 44 px, settles at 34 px.
class _Loft extends StatelessWidget {
  const _Loft({required this.delayMs, required this.rolig, required this.child});
  final double delayMs;
  final bool rolig;
  final Widget child;
  static const Curve _c = Cubic(.2, 1, .3, 1);

  @override
  Widget build(BuildContext context) {
    if (rolig) return child;
    final s = context.bs;
    return BergenOnce(
      durationMs: 900,
      delayMs: delayMs,
      child: child,
      builder: (context, p, child) {
        final e = _c.transform(p);
        final rx = kf(e, const [0, .6, 1], const [-38, 4, 0]) * math.pi / 180;
        final sc = kf(e, const [0, .6, 1], const [.86, 1.02, 1]);
        final o = kf(e, const [0, .6, 1], const [0, 1, 1]);
        final m = Matrix4.identity()
          ..setEntry(3, 2, -1 / (780 * s))
          ..rotateX(rx)
          ..scaleByDouble(sc, sc, 1, 1);
        return Opacity(opacity: o.clamp(0.0, 1.0), child: Transform(alignment: Alignment.center, transform: m, child: child));
      },
    );
  }
}

/// `pmKB <dur> ease-in-out infinite alternate`: scale 1 → 1.07, drift −1.5 % / −1 %.
class _KenBurns extends StatelessWidget {
  const _KenBurns({required this.rolig, required this.delayMs, required this.durMs, required this.child});
  final bool rolig;
  final double delayMs, durMs;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (rolig) return child;
    return BergenLoop(
      durationMs: durMs * 2,
      delayMs: -delayMs % (durMs * 2),
      child: child,
      builder: (context, q, child) {
        final t = q ?? 0;
        final e = Curves.easeInOut.transform(t < .5 ? t * 2 : 2 - t * 2);
        return FractionalTranslation(
          translation: Offset(-.015 * e, -.01 * e),
          child: Transform.scale(scale: 1 + .07 * e, child: child),
        );
      },
    );
  }
}

/// `pmGlans 7.5s`: a skewed light band crosses from −140 % to 340 % after 62 %.
class _Glans extends StatelessWidget {
  const _Glans({required this.delayMs});
  final double delayMs;

  @override
  Widget build(BuildContext context) => BergenLoop(
    durationMs: 7500,
    delayMs: -delayMs % 7500,
    // Heat Step 3: nothing drawn before the delay and below 62 %.
    stille: LfStille(periodeMs: 7500, forsinkelseMs: -delayMs % 7500, fra: 0, til: .62, foer: true),
    builder: (context, q, _) {
      final t = q ?? 0;
      if (t < .62) return const SizedBox.shrink();
      final e = Curves.easeInOut.transform((t - .62) / .38);
      // The band is 40 % wide and travels −140 % → 340 % of its own width.
      return Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: .4,
          heightFactor: 1.4,
          child: FractionalTranslation(
            translation: Offset(-1.4 + 4.8 * e, 0),
            child: Transform(
              transform: Matrix4.identity()..setEntry(0, 1, math.tan(-14 * math.pi / 180)),
              child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [rgba(255, 255, 255, 0), rgba(255, 255, 255, .22), rgba(255, 255, 255, 0)]))),
            ),
          ),
        ),
      );
    },
  );
}

/// The cloth's dots: `radial-gradient(rgba(255,255,255,.36) .9px, transparent 1.5px) 0 0/9px 9px`.
class _PrikkMaler extends CustomPainter {
  const _PrikkMaler(this.steg, this.r);
  final double steg, r;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0x5CFFFFFF);
    for (var y = 0.0; y < size.height; y += steg) {
      for (var x = 0.0; x < size.width; x += steg) {
        canvas.drawCircle(Offset(x, y), r, p);
      }
    }
  }

  @override
  bool shouldRepaint(_PrikkMaler old) => old.steg != steg || old.r != r;
}

class _Tag extends StatelessWidget {
  const _Tag({required this.tag, required this.tilbud, required this.ny});
  final String tag, tilbud, ny;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final f = katTagFarger(tag, tilbud: tilbud, ny: ny);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 5 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: f.color,
        gradient: f.gradient,
        boxShadow: [
          BoxShadow(color: Colors.white, spreadRadius: 2 * s),
          BoxShadow(color: rgba(60, 20, 6, .45), offset: Offset(0, 8 * s), blurRadius: onbBlur(12 * s), spreadRadius: -5 * s),
        ],
      ),
      child: Text(tag.toUpperCase(), style: bText(context, 10, weight: FontWeight.w800, letterSpacingEm: .04, color: f.fg)),
    );
  }
}

/// The store mark: the logo in a white disc, else initials on the hashed colour.
class _Merke extends StatelessWidget {
  const _Merke({required this.navn, required this.logoUrl, required this.size, this.ring = false});
  final String navn;
  final String? logoUrl;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final m = katMerke(navn);
    final har = (logoUrl ?? '').isNotEmpty;
    return Container(
      width: size * s,
      height: size * s,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: har ? Colors.white : m.bg,
        boxShadow: [
          if (ring) BoxShadow(color: rgba(255, 255, 255, .92), spreadRadius: 2.5 * s) else BoxShadow(color: rgba(35, 32, 29, .08), spreadRadius: 1),
          BoxShadow(color: rgba(40, 16, 6, ring ? .6 : .5), offset: Offset(0, (ring ? 8 : 4) * s), blurRadius: onbBlur((ring ? 14 : 8) * s), spreadRadius: -(ring ? 6 : 4) * s),
        ],
      ),
      child: har
          ? ClipOval(child: Padding(padding: EdgeInsets.all(size * s * .08), child: _foto(logoUrl!, fit: BoxFit.contain)))
          : Text(m.mono, style: bDisplay(context, size * .37, letterSpacingEm: -.01, color: Colors.white)),
    );
  }
}

/// The «+» (44 / 40) or the stepper that grows out of it (`pmStegInn .42s`),
/// the count hopping (`pmHoppA/B`) on every change.
class _Stepper extends StatelessWidget {
  const _Stepper({required this.ant, required this.stor, required this.onLegg, required this.onMinus, required this.navn});
  final int ant;
  final bool stor;
  final VoidCallback onLegg, onMinus;
  final String navn;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final h = (stor ? 44 : 40) * s;
    if (ant <= 0) {
      return Semantics(
        button: true,
        label: 'Legg $navn i kurven',
        child: _Knapp(
          onTap: onLegg,
          child: Container(
            key: const Key('kat-prod-pluss'),
            width: h,
            height: h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: cssLinear(180, const [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], const [0, .56, 1]),
              boxShadow: [
                if (!stor) BoxShadow(color: rgba(255, 255, 255, .92), spreadRadius: 2.5 * s),
                BoxShadow(color: const Color(0xFFC4491A), offset: Offset(0, 3 * s)),
                if (!stor) BoxShadow(color: rgba(150, 52, 16, .32), offset: Offset(0, 4.5 * s), spreadRadius: 2.5 * s),
                BoxShadow(color: rgba(120, 40, 10, .6), offset: Offset(0, (stor ? 10 : 12) * s), blurRadius: onbBlur((stor ? 14 : 16) * s), spreadRadius: -6 * s),
              ],
            ),
            child: SokIkon('M12 5v14M5 12h14', size: 17 * s, color: Colors.white, stroke: 3.2),
          ),
        ),
      );
    }
    final k = (stor ? 34 : 30) * s;
    return _StegInn(
      key: const Key('kat-prod-stepper'),
      child: Container(
        height: h,
        padding: EdgeInsets.symmetric(horizontal: 4 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: cssLinear(180, const [Color(0xFF2A6272), Color(0xFF1E4F5C)]),
          boxShadow: [
            if (!stor) BoxShadow(color: rgba(255, 255, 255, .92), spreadRadius: 2.5 * s),
            BoxShadow(color: const Color(0xFF123540), offset: Offset(0, 3 * s)),
            if (!stor) BoxShadow(color: rgba(4, 18, 26, .28), offset: Offset(0, 4.5 * s), spreadRadius: 2.5 * s),
            BoxShadow(color: rgba(4, 18, 26, .6), offset: Offset(0, (stor ? 10 : 12) * s), blurRadius: onbBlur((stor ? 14 : 16) * s), spreadRadius: -6 * s),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Knapp(
              onTap: onMinus,
              scale: .88,
              child: Container(
                key: const Key('kat-prod-minus'),
                width: k,
                height: k,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: rgba(255, 255, 255, .14)),
                child: SokIkon('M5 12h14', size: 14 * s, color: Colors.white, stroke: 3.2),
              ),
            ),
            SizedBox(width: 2 * s),
            _Hopp(
              key: ValueKey('ant-$ant'),
              a: ant.isOdd,
              child: SizedBox(
                width: 20 * s,
                child: Text('$ant', textAlign: TextAlign.center, style: bText(context, 15, weight: FontWeight.w800, color: Colors.white).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
              ),
            ),
            SizedBox(width: 2 * s),
            _Knapp(
              onTap: onLegg,
              scale: .88,
              child: Container(
                key: const Key('kat-prod-pluss'),
                width: k,
                height: k,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: cssLinear(180, const [Color(0xFFF9A273), Color(0xFFF26D3D)]), boxShadow: [BoxShadow(color: rgba(255, 255, 255, .4), offset: Offset(0, 1 * s), blurRadius: 0, spreadRadius: 0)]),
                child: SokIkon('M12 5v14M5 12h14', size: 14 * s, color: Colors.white, stroke: 3.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `pmStegInn .42s cubic-bezier(.3,1.5,.5,1)` from the right end (scale .5 × .8).
class _StegInn extends StatelessWidget {
  const _StegInn({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: BergenTokens.motion(context, const Duration(milliseconds: 420)),
    curve: const Cubic(.3, 1.5, .5, 1),
    child: child,
    builder: (context, p, child) => Opacity(
      opacity: p.clamp(0.0, 1.0),
      child: Transform(
        alignment: Alignment.centerRight,
        transform: Matrix4.identity()..scaleByDouble(.5 + .5 * p, .8 + .2 * p, 1, 1),
        child: child,
      ),
    ),
  );
}

/// `pmHoppA/B .42s`: up 7 px, ×1.08, ∓4° at 35 %.
class _Hopp extends StatelessWidget {
  const _Hopp({super.key, required this.a, required this.child});
  final bool a;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: BergenTokens.motion(context, const Duration(milliseconds: 420)),
      curve: const Cubic(.3, 1.4, .5, 1),
      child: child,
      builder: (context, p, child) {
        final k = kf(p.clamp(0.0, 1.0), const [0, .35, 1], const [0, 1, 0]);
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translateByDouble(0, -7 * s * k, 0, 1)
            ..scaleByDouble(1 + .08 * k, 1 + .08 * k, 1, 1)
            ..rotateZ((a ? -4 : 4) * math.pi / 180 * k),
          child: child,
        );
      },
    );
  }
}

/// Press: down 3 px and ×.94 (the «+»), or ×.88 (the stepper's ends).
class _Knapp extends StatefulWidget {
  const _Knapp({required this.onTap, required this.child, this.scale = .94});
  final VoidCallback onTap;
  final Widget child;
  final double scale;

  @override
  State<_Knapp> createState() => _KnappState();
}

class _KnappState extends State<_Knapp> {
  bool _ned = false;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _ned = true),
      onTapCancel: () => setState(() => _ned = false),
      onTapUp: (_) => setState(() => _ned = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()
          ..translateByDouble(0, _ned && widget.scale > .9 ? 3 * s : 0, 0, 1)
          ..scaleByDouble(_ned ? widget.scale : 1, _ned ? widget.scale : 1, 1, 1),
        transformAlignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}

Widget _foto(String url, {BoxFit fit = BoxFit.cover}) => CachedNetworkImage(
  memCacheWidth: BergenPerf.decodeWidth,
  imageUrl: url,
  fit: fit,
  fadeInDuration: const Duration(milliseconds: 200),
  errorWidget: (_, _, _) => const SizedBox.shrink(),
);
