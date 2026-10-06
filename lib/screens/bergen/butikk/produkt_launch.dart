import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/ops/butikk_models.dart';
import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_css.dart';
import '../kit/bergen_motion.dart';
import '../sok/sok_oversikt.dart' show SokIkon;
import 'butikk_copy.dart';

// ── The product sheet's Launch pieces (`visProdukt`, L8901–8990) ────────────

/// The hero (`data-prodhero`): teal with a soft top light, the warm glow
/// breathing behind the dish (`prodGlod 6s`), a mint corner, two rings
/// spreading on the water (`prodRing 4.2s`), the shadow (`prodSkygge`),
/// steam (`prodDamp`), and the dish lifting in (`heroLoft`) and breathing
/// (`prodPust`) with a glint (`prodGlint`).
///
/// [fold] (0–1, already eased) is `pRull`: the hero shrinks from 276 to
/// 90px, the dish slides to the left corner at a third of its size, the
/// effects fade and the small title comes in.
class ProduktHero extends StatelessWidget {
  const ProduktHero({
    super.key,
    required this.fold,
    required this.imageUrl,
    required this.name,
    required this.sum,
    required this.onClose,
  });

  final ValueListenable<double> fold;
  final String? imageUrl;
  final String name;
  final String sum;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return ValueListenableBuilder<double>(
      valueListenable: fold,
      builder: (context, e, _) {
        final fx = (1 - e * 1.4).clamp(0.0, 1.0);
        final mini = math.max(0.0, (e - .55) / .45);
        return SizedBox(
          height: (276 - 186 * e) * s,
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30 * s)),
                      child: _Bakgrunn(fx: fx),
                    ),
                  ),
                  // Steam over the dish (`data-prodfx`).
                  if (fx > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Opacity(opacity: fx, child: const RepaintBoundary(child: _Damp())),
                      ),
                    ),
                  if (mini > 0)
                    Positioned(
                      left: 112 * s,
                      right: 64 * s,
                      top: 26 * s,
                      child: Opacity(
                        opacity: mini,
                        child: Transform.translate(
                          offset: Offset(0, 8 * s * (1 - mini)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: bDisplay(context, 16, letterSpacingEm: -.02),
                              ),
                              SizedBox(height: 2 * s),
                              Text(
                                sum,
                                style: bText(
                                  context,
                                  12,
                                  weight: FontWeight.w800,
                                  color: const Color(0xFFFFB27A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // The dish: 240×252 at top −38, centred; folding, it moves
                  // to (58 − W/2, −38) and shrinks to a third.
                  Positioned(
                    left: w / 2 - 120 * s,
                    top: -38 * s,
                    width: 240 * s,
                    height: 252 * s,
                    child: IgnorePointer(
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.translationValues((58 * s - w / 2) * e, -38 * s * e, 0)
                          ..scaleByDouble(1 - .66 * e, 1 - .66 * e, 1, 1),
                        child: _Rett(url: imageUrl, aktiv: e < .01),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10 * s,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: onClose,
                        child: Container(
                          width: 44 * s,
                          height: 5 * s,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3 * s),
                            color: rgba(255, 255, 255, .55),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14 * s,
                    right: 14 * s,
                    child: OnbPressable(
                      key: const Key('a1_butikk_produkt_lukk'),
                      onTap: onClose,
                      pressDy: 0,
                      pressScale: .92,
                      child: Container(
                        width: 38 * s,
                        height: 38 * s,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: rgba(15, 31, 43, .5),
                          border: Border.all(color: rgba(255, 255, 255, .3)),
                          boxShadow: [
                            BoxShadow(
                              color: rgba(0, 0, 0, .6),
                              offset: Offset(0, 10 * s),
                              blurRadius: onbBlur(14 * s),
                              spreadRadius: -7 * s,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            bergenInsetTop(radius: 999, height: 1 * s, alpha: .25),
                            SokIkon('M6 6l12 12M18 6L6 18', size: 13 * s, color: Colors.white, stroke: 2.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // `linear-gradient(180deg, rgba(30,79,92,0), #1E4F5C)` into
                  // the body.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -1,
                    height: 36 * s,
                    child: const IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x001E4F5C), Color(0xFF1E4F5C)],
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
      },
    );
  }
}

class _Bakgrunn extends StatelessWidget {
  const _Bakgrunn({required this.fx});

  final double fx;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: cssLinear(
              180,
              const [Color(0xFF2F6C7E), Color(0xFF225868), Color(0xFF1B4A57)],
              const [0, .45, 1],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: .9,
              colors: [Color.fromRGBO(255, 255, 255, .18), Color.fromRGBO(255, 255, 255, 0)],
              stops: [0, .6],
            ),
          ),
        ),
        // The warm glow, breathing (`prodGlod 6s`).
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 276 * s,
          child: Align(
            alignment: const Alignment(0, -.12),
            child: RepaintBoundary(
              child: BergenLoop(
                durationMs: 6000,
                child: Container(
                  width: 330 * s,
                  height: 260 * s,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.elliptical(165 * s, 130 * s)),
                    gradient: const RadialGradient(
                      colors: [
                        Color.fromRGBO(255, 190, 120, .38),
                        Color.fromRGBO(255, 160, 90, .14),
                        Color.fromRGBO(255, 160, 90, 0),
                      ],
                      stops: [0, .45, .72],
                    ),
                  ),
                ),
                builder: (context, p, child) {
                  final k = p == null ? 0.0 : kf(p, const [0, .5, 1], const [0, 1, 0], Curves.easeInOut);
                  return Opacity(
                    opacity: .85 + .15 * k,
                    child: Transform.scale(scale: 1 + .06 * k, child: child),
                  );
                },
              ),
            ),
          ),
        ),
        Positioned(
          right: -60 * s,
          top: -40 * s,
          width: 220 * s,
          height: 220 * s,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color.fromRGBO(127, 240, 203, .2), Color.fromRGBO(127, 240, 203, 0)],
                stops: [0, .7],
              ),
            ),
          ),
        ),
        if (fx > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 36 * s,
            height: 46 * s,
            child: Opacity(
              opacity: fx,
              child: const RepaintBoundary(
                child: Stack(
                  alignment: Alignment.center,
                  children: [_Ring(forsinkelse: 0), _Ring(forsinkelse: 2100)],
                ),
              ),
            ),
          ),
        if (fx > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 44 * s,
            height: 24 * s,
            child: Opacity(
              opacity: fx,
              child: Center(
                child: BergenLoop(
                  durationMs: 5500,
                  delayMs: 1000,
                  child: Container(
                    width: 200 * s,
                    height: 24 * s,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.elliptical(100 * s, 12 * s)),
                      gradient: const RadialGradient(
                        colors: [Color.fromRGBO(4, 18, 26, .6), Color.fromRGBO(4, 18, 26, 0)],
                        stops: [0, .72],
                      ),
                    ),
                  ),
                  builder: (context, p, child) {
                    final k = p == null ? 0.0 : kf(p, const [0, .5, 1], const [0, 1, 0], Curves.easeInOut);
                    return Opacity(
                      opacity: 1 - .2 * k,
                      child: Transform.scale(scale: 1 - .07 * k, child: child),
                    );
                  },
                ),
              ),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 60 * s,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x001B4A57), Color(0xFF1E4F5C)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// `prodRing 4.2s ease-out`: an ellipse (250×46) grows from .62 to 1.25.
class _Ring extends StatelessWidget {
  const _Ring({required this.forsinkelse});

  final double forsinkelse;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return BergenLoop(
      durationMs: 4200,
      delayMs: forsinkelse,
      child: Container(
        width: 250 * s,
        height: 46 * s,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.elliptical(125 * s, 23 * s)),
          border: Border.all(color: rgba(214, 242, 250, .35), width: 1.5 * s),
        ),
      ),
      builder: (context, p, child) {
        if (p == null) return const SizedBox.shrink();
        final e = Curves.easeOut.transform(p);
        final o = kf(e, const [0, .2, 1], const [0, .8, 0], Curves.linear);
        return Opacity(
          opacity: o,
          child: Transform.scale(scale: .62 + .63 * e, child: child),
        );
      },
    );
  }
}

/// `prodDamp`: three wisps rising off the dish.
class _Damp extends StatelessWidget {
  const _Damp();

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    Widget wisp(double left, double top, double w, double h, double a, double ms, double delay) =>
        Positioned(
          left: 0,
          right: 0,
          top: top * s,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child: Align(
              alignment: Alignment(left * 2 - 1, -1),
              child: BergenLoop(
                durationMs: ms,
                delayMs: delay,
                child: Container(
                  width: w * s,
                  height: h * s,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.elliptical(w * s / 2, h * s / 2)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        rgba(255, 255, 255, 0),
                        rgba(255, 255, 255, a * .7),
                        rgba(255, 255, 255, 0),
                      ],
                    ),
                  ),
                ),
                builder: (context, p, child) {
                  if (p == null) return const SizedBox.shrink();
                  final e = Curves.easeInOut.transform(p);
                  final o = kf(p, const [0, .35, 1], const [0, .9, 0], Curves.easeInOut);
                  return Opacity(
                    opacity: o,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.translationValues(6 * s * e, (26 - 60 * e) * s, 0)
                        ..scaleByDouble(.7 + .6 * e, 1, 1, 1),
                      child: child,
                    ),
                  );
                },
              ),
            ),
          ),
        );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        wisp(.43, 24, 16, 64, .28, 4800, 0),
        wisp(.53, 18, 12, 56, .22, 5600, 1600),
        wisp(.61, 30, 10, 48, .18, 6200, 3000),
      ],
    );
  }
}

/// The dish: `heroLoft .6s .05s` in, then `prodPust 5.5s 1s` and the glint
/// (`prodGlint 6.5s 1.4s`). A shop photo is shown as a rounded print (the
/// design's dishes are cut-outs).
class _Rett extends StatelessWidget {
  const _Rett({required this.url, required this.aktiv});

  final String? url;

  /// The breathing stops while the hero folds (`animation: none`).
  final bool aktiv;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final bilde = Center(
      child: Container(
        width: 232 * s,
        height: 176 * s,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26 * s),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: rgba(20, 8, 2, .55),
              offset: Offset(0, 18 * s),
              blurRadius: onbBlur(16 * s) + 6 * s,
              spreadRadius: -6 * s,
            ),
          ],
        ),
        padding: EdgeInsets.all(3 * s),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23 * s),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFFFBF7EE)),
              if ((url ?? '').isNotEmpty)
                Image.network(
                  url!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              const RepaintBoundary(child: _Glint()),
            ],
          ),
        ),
      ),
    );
    return BergenOnce(
      durationMs: 600,
      delayMs: 50,
      builder: (context, p, child) {
        const c = Cubic(.3, 1.2, .5, 1);
        final y = kf(p, const [0, .6, 1], const [40, -6, 0], c);
        final sc = kf(p, const [0, .6, 1], const [.9, 1.04, 1], c);
        final o = kf(p, const [0, .6, 1], const [0, 1, 1], c);
        return Opacity(
          opacity: o.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, y * s),
            child: Transform.scale(scale: sc, child: child),
          ),
        );
      },
      child: aktiv
          ? BergenLoop(
              durationMs: 5500,
              delayMs: 1000,
              child: bilde,
              builder: (context, p, child) {
                final k = p == null ? 0.0 : kf(p, const [0, .5, 1], const [0, 1, 0], Curves.easeInOut);
                return Transform.translate(
                  offset: Offset(0, -5 * s * k),
                  child: Transform.scale(scale: 1 + .018 * k, child: child),
                );
              },
            )
          : bilde,
    );
  }
}

/// `prodGlint 6.5s 1.4s cubic-bezier(.5,0,.3,1)`: a warm band crosses the
/// dish in the last 38% of each cycle (`screen`).
class _Glint extends StatelessWidget {
  const _Glint();

  @override
  Widget build(BuildContext context) => BergenLoop(
    durationMs: 6500,
    delayMs: 1400,
    builder: (context, p, _) {
      if (p == null || p < .62) return const SizedBox.shrink();
      final e = const Cubic(.5, 0, .3, 1).transform((p - .62) / .38);
      return LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth * .34;
          final x = -1.4 * w + (5 * w) * e;
          return Transform(
            transform: Matrix4.translationValues(x, 0, 0)
              ..multiply(Matrix4.skewX(-18 * math.pi / 180)),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: w,
                height: c.maxHeight * 1.4,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-.9, -.2),
                      end: Alignment(.9, .2),
                      colors: [
                        Color.fromRGBO(255, 255, 255, 0),
                        Color.fromRGBO(255, 248, 230, .45),
                        Color.fromRGBO(255, 255, 255, 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// ── Tilvalg · {gruppe} ──────────────────────────────────────────────────────

/// One option group (`pGrupper`): title, the rule ("Velg én" / "Valgfritt")
/// and the status badge ("✓ Valgt", "Påkrevd", "2 valgt", "Valgfritt");
/// below, the glass list of rows with a round (one) or square (several)
/// check that fills mint when chosen.
class ProduktTilvalg extends StatelessWidget {
  const ProduktTilvalg({
    super.key,
    required this.tittel,
    required this.en,
    required this.options,
    required this.picked,
    required this.keyPrefix,
    required this.onTap,
    this.paakrevd = false,
  });

  final String tittel;

  /// One choice (`type: 'en'`) — or several (`'ja'`).
  final bool en;
  final bool paakrevd;
  final List<BergenVariant> options;
  final Set<int> picked;
  final String keyPrefix;
  final ValueChanged<BergenVariant> onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final n = options.where((v) => picked.contains(v.id)).length;
    final ok = !en || n > 0;
    final (String merke, Color bg, Color kant, Color fg) = en
        ? (ok
              ? (ButikkCopy.a1_butikk_prod_valgt_en, rgba(127, 240, 203, .14), rgba(127, 240, 203, .45), const Color(0xFF7FF0CB))
              : (ButikkCopy.a1_butikk_prod_paakrevd, rgba(242, 109, 61, .18), rgba(249, 162, 115, .6), const Color(0xFFFFB27A)))
        : (n > 0
              ? (ButikkCopy.a1_butikk_prod_valgt(n), rgba(127, 240, 203, .14), rgba(127, 240, 203, .45), const Color(0xFF7FF0CB))
              : (ButikkCopy.a1_butikk_prod_valgfritt, rgba(255, 255, 255, .08), rgba(255, 255, 255, .16), rgba(255, 255, 255, .62)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2 * s),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tittel, style: bDisplay(context, 15, letterSpacingEm: -.015)),
                    SizedBox(height: 2 * s),
                    Text(
                      en ? ButikkCopy.a1_butikk_prod_velg_en : ButikkCopy.a1_butikk_prod_valgfritt,
                      style: bText(context, 11.5, weight: FontWeight.w600, color: rgba(255, 255, 255, .58)),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10 * s),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.ease,
                padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 4 * s),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: bg,
                  border: Border.all(color: kant),
                ),
                child: Text(merke, style: bText(context, 10.5, weight: FontWeight.w800, color: fg)),
              ),
            ],
          ),
        ),
        SizedBox(height: 9 * s),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18 * s),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [rgba(255, 255, 255, .12), rgba(255, 255, 255, .05)],
            ),
            border: Border.all(color: rgba(255, 255, 255, .14)),
          ),
          child: Stack(
            children: [
              bergenInsetTop(radius: 18 * s, height: 1.5 * s, alpha: .18),
              Column(
                children: [
                  for (var i = 0; i < options.length; i++)
                    _Rad(
                      key: Key('$keyPrefix${options[i].id}'),
                      v: options[i],
                      on: picked.contains(options[i].id),
                      rund: en,
                      skille: i > 0,
                      onTap: () => onTap(options[i]),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Rad extends StatelessWidget {
  const _Rad({
    super.key,
    required this.v,
    required this.on,
    required this.rund,
    required this.skille,
    required this.onTap,
  });

  final BergenVariant v;
  final bool on;
  final bool rund;
  final bool skille;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    const sprett = Cubic(.3, 1.4, .5, 1);
    final pris = v.priceDelta == 0
        ? (rund ? ButikkCopy.a1_butikk_prod_inkludert : '')
        : '${v.priceDelta > 0 ? '+ ' : '− '}${ButikkCopy.kr(v.priceDelta.abs())}';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: v.inStock
          ? () {
              HapticFeedback.selectionClick();
              onTap();
            }
          : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: v.inStock ? 1 : .42,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.ease,
          constraints: BoxConstraints(minHeight: 50 * s),
          padding: EdgeInsets.symmetric(horizontal: 14 * s),
          decoration: BoxDecoration(
            border: skille ? Border(top: BorderSide(color: rgba(255, 255, 255, .08))) : null,
            gradient: LinearGradient(
              colors: on
                  ? [rgba(127, 240, 203, .14), rgba(127, 240, 203, .04)]
                  : [rgba(127, 240, 203, 0), rgba(127, 240, 203, 0)],
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: sprett,
                width: 22 * s,
                height: 22 * s,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: rund ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: rund ? null : BorderRadius.circular(7 * s),
                  border: Border.all(
                    color: on ? const Color(0xFF7FF0CB) : rgba(255, 255, 255, .42),
                    width: 2 * s,
                  ),
                  gradient: on ? cssLinear(160, const [Color(0xFF9CF5D6), Color(0xFF3FD0A4)]) : null,
                  color: on ? null : rgba(255, 255, 255, .04),
                  boxShadow: on
                      ? [
                          BoxShadow(
                            color: rgba(47, 184, 147, .8),
                            offset: Offset(0, 6 * s),
                            blurRadius: onbBlur(12 * s),
                            spreadRadius: -5 * s,
                          ),
                          BoxShadow(color: rgba(127, 240, 203, .16), spreadRadius: 4 * s),
                        ]
                      : null,
                ),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 220),
                  curve: const Cubic(.3, 1.6, .5, 1),
                  scale: on ? 1 : .3,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: on ? 1 : 0,
                    child: SokIkon('M5 12.5l4.2 4.2L19 7', size: 12 * s, color: const Color(0xFF0F2A33), stroke: 3.4),
                  ),
                ),
              ),
              SizedBox(width: 12 * s),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12 * s),
                  child: Text(
                    v.name,
                    style: bText(
                      context,
                      14,
                      weight: on ? FontWeight.w800 : FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
              if (pris.isNotEmpty) ...[
                SizedBox(width: 12 * s),
                Text(
                  pris,
                  style: bText(
                    context,
                    12.5,
                    weight: FontWeight.w700,
                    color: on ? const Color(0xFF7FF0CB) : rgba(255, 255, 255, .6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Ofte kjøpt med (L8956) ──────────────────────────────────────────────────

/// Two-up glass cards with the dish floating over each, its name and price,
/// and the orange + that turns into a mint ✓ once it is in the basket.
class ProduktOfteMed extends StatelessWidget {
  const ProduktOfteMed({
    super.key,
    required this.items,
    required this.lagt,
    required this.onAdd,
  });

  final List<BergenMenuItem> items;
  final Set<int> lagt;
  final ValueChanged<BergenMenuItem> onAdd;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Column(
      key: const Key('a1_butikk_prod_med'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2 * s),
          child: Text(ButikkCopy.a1_butikk_prod_ofte_med, style: bDisplay(context, 15, letterSpacingEm: -.015)),
        ),
        SizedBox(height: 32 * s),
        for (var i = 0; i < items.length; i += 2) ...[
          if (i > 0) SizedBox(height: 30 * s),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _MedKort(m: items[i], on: lagt.contains(items[i].id), onAdd: () => onAdd(items[i]))),
              SizedBox(width: 10 * s),
              Expanded(
                child: i + 1 < items.length
                    ? _MedKort(m: items[i + 1], on: lagt.contains(items[i + 1].id), onAdd: () => onAdd(items[i + 1]))
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MedKort extends StatelessWidget {
  const _MedKort({required this.m, required this.on, required this.onAdd});

  final BergenMenuItem m;
  final bool on;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final url = m.imageUrl;
    return OnbPressable(
      key: Key('a1_butikk_prod_med_${m.id}'),
      onTap: on ? null : onAdd,
      pressDy: 2 * s,
      child: Container(
        padding: EdgeInsets.fromLTRB(10 * s, 0, 10 * s, 10 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20 * s),
          gradient: cssLinear(165, [
            rgba(255, 255, 255, .18),
            rgba(255, 255, 255, .07),
            rgba(255, 255, 255, .04),
          ], const [0, .4, 1]),
          border: Border.all(color: rgba(255, 255, 255, .22)),
          boxShadow: [
            BoxShadow(
              color: rgba(2, 12, 18, .95),
              offset: Offset(0, 18 * s),
              blurRadius: onbBlur(28 * s),
              spreadRadius: -16 * s,
            ),
            BoxShadow(color: rgba(8, 30, 38, .5), offset: Offset(0, 2 * s)),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            bergenInsetTop(
              radius: 20 * s,
              height: 1.5 * s,
              alpha: .36,
              pad: EdgeInsets.fromLTRB(10 * s, 0, 10 * s, 10 * s),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // `height:74px; margin-top:-26px`.
                SizedBox(
                  height: 48 * s,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: -26 * s,
                        height: 74 * s,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topCenter,
                          children: [
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 2 * s,
                              height: 9 * s,
                              child: FractionallySizedBox(
                                widthFactor: .44,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.all(Radius.elliptical(30 * s, 4.5 * s)),
                                    gradient: RadialGradient(
                                      colors: [rgba(0, 8, 12, .55), rgba(0, 8, 12, 0)],
                                      stops: const [0, .72],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 82 * s,
                              height: 64 * s,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16 * s),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: rgba(0, 8, 12, .45),
                                    offset: Offset(0, 10 * s),
                                    blurRadius: onbBlur(8 * s) + 4 * s,
                                    spreadRadius: -4 * s,
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(2.5 * s),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(13.5 * s),
                                child: (url ?? '').isEmpty
                                    ? const DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: RadialGradient(
                                            colors: [Color(0xFFFDF0D8), Color(0xFFE7B66C)],
                                          ),
                                        ),
                                      )
                                    : Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6 * s),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: bText(context, 12.5, weight: FontWeight.w700, height: 1.2),
                          ),
                          SizedBox(height: 2 * s),
                          Text(ButikkCopy.kr(m.price), style: bDisplay(context, 14)),
                        ],
                      ),
                    ),
                    SizedBox(width: 8 * s),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 32 * s,
                      height: 32 * s,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: on
                            ? cssLinear(160, const [Color(0xFF9CF5D6), Color(0xFF3FD0A4)])
                            : const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)],
                                stops: [0, .56, 1],
                              ),
                        boxShadow: [
                          BoxShadow(
                            color: rgba(0, 0, 0, .6),
                            offset: Offset(0, 8 * s),
                            blurRadius: onbBlur(12 * s),
                            spreadRadius: -6 * s,
                          ),
                          BoxShadow(color: rgba(150, 60, 15, .7), offset: Offset(0, 2 * s)),
                          BoxShadow(color: rgba(255, 255, 255, .35), spreadRadius: 1),
                        ],
                      ),
                      child: SokIkon(
                        on ? 'M5 12.5l4.2 4.2L19 7' : 'M12 5v14M5 12h14',
                        size: 14 * s,
                        color: on ? const Color(0xFF0F2A33) : Colors.white,
                        stroke: 3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Up to four other dishes to suggest beside [item]: drinks and sides first
/// (what people add to a meal), then the rest of the menu.
List<BergenMenuItem> produktOfteMed(BergenMenuItem item, List<BergenMenuItem> meny) {
  final andre = [for (final m in meny) if (m.id != item.id && m.price > 0) m];
  bool tilbeh(BergenMenuItem m) => RegExp(
    r'drikk|brus|soda|cola|fanta|sprite|vann|juice|tilbeh|fries|frites|pommes|side|dip|saus|dessert|is\b',
    caseSensitive: false,
  ).hasMatch('${m.name} ${m.categoryName ?? ''}');
  return [...andre.where(tilbeh), ...andre.where((m) => !tilbeh(m))].take(4).toList();
}

/// `pRull`'s fold for a scroll offset: smoothstep over the first 190 px.
double produktRullE(double scroll, double s) {
  final y = (scroll / s / 190).clamp(0.0, 1.0);
  return y * y * (3 - 2 * y);
}
