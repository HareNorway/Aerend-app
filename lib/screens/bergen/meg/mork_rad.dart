import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../aegil/aegil_bits.dart';

// ── The dark Ark's rows (new Bergen `radMork`, L19866–19900, L9954) ────────
// One card per row on the teal glass: the 40 px tile (icon or text), the
// name and line, and on the right a chip, a field, a switch, the mint check
// or an arrow. Shared by Innstillinger for Ægil and the Meg sheets that new
// Bergen turned dark (Gullbilletten, Språk, Varsler, Slik får du poeng …).

abstract final class MorkIk {
  static const String lommebok = 'M4 7h14a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H4zM4 7l11-3v3M16 13.5h.01';
  static const String klokke = 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 7v5l3 2';
  static const String ned = 'M12 4v14M6 12l6 6 6-6';
  static const String hist = 'M3 12a9 9 0 1 0 3-6.7M3 4v4h4M12 8v4l3 2';
  static const String butikk = 'M4 10l1.6-5h12.8L20 10M4 10h16M5 10v10h14V10M10 20v-5h4v5';
  static const String hylle = 'M4 6h16M4 12h16M4 18h16M7 6v12M17 6v12';
  // `radMork`'s IK set (L19867).
  static const String pose = 'M6 8h12l-1.2 12H7.2zM9 8V6.5a3 3 0 0 1 6 0V8';
  static const String krok = 'M15 2.5a1.7 1.7 0 1 0 0 3.4 1.7 1.7 0 0 0 0-3.4zM15 5.9v8a5 5 0 0 1-10 0v-1.6l3 2.6';
  static const String stjerne = 'M12 3.5l2.6 5.3 5.8.8-4.2 4.1 1 5.8-5.2-2.7-5.2 2.7 1-5.8-4.2-4.1 5.8-.8z';
  static const String flagg = 'M5 21V4M5 4h11l-2 4 2 4H5';
  static const String person = 'M12 11.5a3.8 3.8 0 1 0 0-7.6 3.8 3.8 0 0 0 0 7.6zM4.5 20c1.3-3.8 4-5.6 7.5-5.6s6.2 1.8 7.5 5.6';
  static const String opp = 'M4 17l6-6 4 4 6-7M14 8h6v6';
  static const String gave = 'M4 10h16v10H4zM3 7h18v3H3zM12 7v13M12 7c-2-3-5-3-5-1s3 1 5 1c2 0 5 1 5-1s-3-2-5 1';
  static const String bjelle = 'M6 16V11a6 6 0 0 1 12 0v5l1.5 2h-15zM10 20a2 2 0 0 0 4 0';
  static const String pokal = 'M8 4h8v5a4 4 0 0 1-8 0zM8 6H5a3 3 0 0 0 3 4M16 6h3a3 3 0 0 1-3 4M12 13v4M8.5 20h7';
  static const String skjold = 'M12 3l7.5 3v5.5c0 4.5-3.2 8.2-7.5 9.5-4.3-1.3-7.5-5-7.5-9.5V6z';
  static const String bok = 'M5 4h10a4 4 0 0 1 4 4v12H9a4 4 0 0 1-4-4zM5 16a4 4 0 0 1 4-4h10';
}

/// A section head: the glowing mint dot, the name in capitals, its line and
/// (for the levels) the «Nivå N» chip.
class MorkSeksjon extends StatelessWidget {
  const MorkSeksjon(this.navn, this.under, {super.key, this.verdi});

  final String navn;
  final String under;
  final String? verdi;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 12, 4, 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF5CE0B8),
                      boxShadow: [BoxShadow(color: Color.fromRGBO(92, 224, 184, .8), blurRadius: 8 / 2 / .57735)],
                    ),
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      navn.toUpperCase(),
                      style: inter(11, weight: FontWeight.w800, em: .1, color: const Color(0xFF7FF0CB)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(under, style: inter(12, height: 1.4, color: const Color.fromRGBO(255, 255, 255, .62))),
            ],
          ),
        ),
        if (verdi != null) ...[const SizedBox(width: 10), MorkVerdi(verdi!)],
      ],
    ),
  );
}

/// The chip's colours (`radMork`'s vBg / vBd / vC): plain, «Må velges» /
/// «Nytt» (orange), «Valgt» (mint), «Kommer snart» (gold), points (gold
/// gradient), «Nådd» (faint mint) and the next level (orange gradient).
enum MorkStil { vanlig, ny, valgt, snart, gull, naadd, nesteNiv }

class MorkVerdi extends StatelessWidget {
  const MorkVerdi(this.t, {super.key, this.snart = false, this.stil = MorkStil.vanlig});

  final String t;
  final bool snart;
  final MorkStil stil;

  @override
  Widget build(BuildContext context) {
    final st = snart ? MorkStil.snart : stil;
    final (List<CssBg> bg, Color bd, Color c) = switch (st) {
      MorkStil.ny => (const [CssSolid(Color.fromRGBO(242, 109, 61, .22))], const Color.fromRGBO(249, 162, 115, .5), const Color(0xFFFFC8A8)),
      MorkStil.valgt => (const [CssSolid(Color.fromRGBO(92, 224, 184, .2))], const Color.fromRGBO(127, 240, 203, .5), const Color(0xFF7FF0CB)),
      MorkStil.snart => (const [CssSolid(Color.fromRGBO(245, 196, 81, .16))], const Color.fromRGBO(245, 196, 81, .55), const Color(0xFFFFE08A)),
      MorkStil.gull => (
        const [
          CssLinear(180, [Color.fromRGBO(245, 196, 81, .3), Color.fromRGBO(245, 196, 81, .1)]),
        ],
        const Color.fromRGBO(245, 196, 81, .6),
        const Color(0xFFFFE08A),
      ),
      MorkStil.naadd => (const [CssSolid(Color.fromRGBO(92, 224, 184, .12))], const Color.fromRGBO(127, 240, 203, .35), const Color(0xFF9FF3D6)),
      MorkStil.nesteNiv => (
        const [
          CssLinear(180, [Color.fromRGBO(249, 162, 115, .32), Color.fromRGBO(242, 109, 61, .14)]),
        ],
        const Color.fromRGBO(249, 162, 115, .6),
        const Color(0xFFFFC8A8),
      ),
      MorkStil.vanlig => (const [CssSolid(Color.fromRGBO(255, 255, 255, .12))], const Color.fromRGBO(255, 255, 255, .2), Colors.white),
    };
    return CssBox(
      radius: BorderRadius.circular(999),
      bg: bg,
      shadows: [CssShadow.inset(0, 0, 0, 1, bd)],
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      child: Text(
        t,
        maxLines: 1,
        softWrap: false,
        style: aeTab(inter(11, weight: FontWeight.w800, color: c)),
      ),
    );
  }
}

/// A metal tile (`r.metall`: the tier's coin colours and ink).
class MorkMetall {
  const MorkMetall({required this.farger, required this.stopp, required this.ink});
  final List<Color> farger;
  final List<double> stopp;
  final Color ink;
}

/// One card row (`radMork`): the tile (icon or number), the name and line,
/// and on the right a chip, a field, a switch, the mint check or an arrow.
class MorkRad extends StatelessWidget {
  const MorkRad({
    super.key,
    required this.delayMs,
    required this.navn,
    required this.onTap,
    this.ikon,
    this.tileTx,
    this.under,
    this.verdi,
    this.felt,
    this.bryter,
    this.valgt = false,
    this.pil = false,
    this.snart = false,
    this.stil = MorkStil.vanlig,
    this.ny = false,
    this.metall,
    this.laast = false,
    this.tileBarn,
  });

  final double delayMs;
  final String navn;
  final VoidCallback onTap;
  final String? ikon;
  final String? tileTx;
  final String? under;
  final String? verdi;
  final Widget? felt;
  final bool? bryter;
  final bool valgt;
  final bool pil;
  final bool snart;

  /// The chip's colours.
  final MorkStil stil;

  /// «Må velges» / «Nytt»: the tile turns orange too.
  final bool ny;

  /// A tier's metal on the tile instead of glass.
  final MorkMetall? metall;

  /// A level not reached yet: the card dims.
  final bool laast;

  /// Something else in the tile (a medal, a ticket).
  final Widget? tileBarn;

  @override
  Widget build(BuildContext context) {
    final v = valgt;
    final met = metall;
    final tBd = met != null
        ? (v ? const Color.fromRGBO(127, 240, 203, .9) : const Color.fromRGBO(255, 255, 255, .45))
        : snart
        ? const Color.fromRGBO(245, 196, 81, .4)
        : (v ? const Color.fromRGBO(127, 240, 203, .55) : (ny ? const Color.fromRGBO(249, 162, 115, .5) : const Color.fromRGBO(255, 255, 255, .2)));
    final tC = met != null ? met.ink : (snart ? const Color(0xFFFFE08A) : (v ? const Color(0xFF7FF0CB) : (ny ? const Color(0xFFFFC8A8) : Colors.white)));
    final tile = CssBox(
      width: 40,
      height: 40,
      radius: BorderRadius.circular(13),
      bg: [
        if (met != null)
          CssRadial(met.farger, stops: met.stopp, rx: .9, ry: .9, cx: .34, cy: .26)
        else
          CssLinear(
            160,
            snart
                ? const [Color.fromRGBO(245, 196, 81, .22), Color.fromRGBO(245, 196, 81, .05)]
                : v
                ? const [Color.fromRGBO(127, 240, 203, .4), Color.fromRGBO(92, 224, 184, .14)]
                : ny
                ? const [Color.fromRGBO(249, 162, 115, .36), Color.fromRGBO(242, 109, 61, .12)]
                : const [Color.fromRGBO(255, 255, 255, .2), Color.fromRGBO(255, 255, 255, .06)],
          ),
      ],
      shadows: [const CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .28)), CssShadow.inset(0, 0, 0, 1, tBd), const CssShadow(0, 8, 12, -6, Color.fromRGBO(0, 0, 0, .5))],
      child: Center(
        child: tileBarn ?? (tileTx != null ? Text(tileTx!, style: jakarta(13, color: tC)) : AeIkon(ikon ?? MorkIk.hist, size: 18, stroke: 2.1, color: tC)),
      ),
    );
    final Widget? hoyre =
        felt ??
        (bryter != null
            ? MorkBryter(paa: bryter!)
            : verdi != null
            ? (v
                  ? Row(mainAxisSize: MainAxisSize.min, children: [MorkVerdi(verdi!, snart: snart, stil: stil), const SizedBox(width: 12), const MorkHake()])
                  : MorkVerdi(verdi!, snart: snart, stil: stil))
            : v
            ? const MorkHake()
            : pil
            ? const MorkPil()
            : null);
    final innhold = Row(
      children: [
        tile,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(navn, style: inter(14, weight: FontWeight.w800, em: -.01, height: 1.3)),
              if (under != null && under!.isNotEmpty) ...[const SizedBox(height: 2), Text(under!, style: inter(12, height: 1.4, color: const Color.fromRGBO(255, 255, 255, .62)))],
            ],
          ),
        ),
        if (hoyre != null) ...[const SizedBox(width: 12), hoyre],
      ],
    );
    // `transition: box-shadow .25s ease, background .25s ease` between the
    // plain and the chosen look; «Kommer snart» has its own stripes.
    final kort = snart
        ? CustomPaint(
            painter: const MorkStriper(),
            child: CssBox(
              radius: BorderRadius.circular(20),
              shadows: const [CssShadow(0, 0, 0, 1.5, Color.fromRGBO(245, 196, 81, .32)), CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .18))],
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60),
                child: Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 12), child: innhold),
              ),
            ),
          )
        : TweenAnimationBuilder<double>(
            tween: Tween(end: v ? 1 : 0),
            duration: const Duration(milliseconds: 250),
            curve: cssEase,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 12), child: innhold),
            ),
            builder: (context, a, child) {
              Color l(Color x, Color y) => Color.lerp(x, y, a)!;
              return CssBox(
                radius: BorderRadius.circular(20),
                bg: [
                  CssLinear(180, [
                    l(laast ? const Color.fromRGBO(255, 255, 255, .08) : const Color.fromRGBO(255, 255, 255, .14), const Color.fromRGBO(92, 224, 184, .24)),
                    l(laast ? const Color.fromRGBO(255, 255, 255, .03) : const Color.fromRGBO(255, 255, 255, .05), const Color.fromRGBO(92, 224, 184, .08)),
                  ]),
                ],
                shadows: [
                  CssShadow(0, 0, 0, 1.5, l(laast ? const Color.fromRGBO(255, 255, 255, .1) : const Color.fromRGBO(255, 255, 255, .16), const Color.fromRGBO(127, 240, 203, .75))),
                  const CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .18)),
                  // `0 12px 20px -14px rgba(4,18,26,.8)` ↔ `0 0 22px -6px rgba(92,224,184,.7)`.
                  CssShadow(0, 12 * (1 - a), 20 + 2 * a, -14 + 8 * a, l(const Color.fromRGBO(4, 18, 26, .8), const Color.fromRGBO(92, 224, 184, .7))),
                ],
                child: child,
              );
            },
          );
    return MorkStag(
      delayMs: delayMs,
      child: AePress(onTap: onTap, dy: 0, scale: .985, child: kort),
    );
  }
}

/// `repeating-linear-gradient(135deg, white .05 0 8px, white .02 8px 16px)`
/// behind «Kommer snart».
class MorkStriper extends CustomPainter {
  const MorkStriper();

  @override
  void paint(Canvas canvas, Size size) {
    const k = 16 / math.sqrt2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(k, k),
          const [Color.fromRGBO(255, 255, 255, .05), Color.fromRGBO(255, 255, 255, .05), Color.fromRGBO(255, 255, 255, .02), Color.fromRGBO(255, 255, 255, .02)],
          const [0, .5, .5, 1],
          TileMode.repeated,
        ),
    );
  }

  @override
  bool shouldRepaint(MorkStriper o) => false;
}

/// `kortStag .45s <delay> cubic-bezier(.2,.9,.3,1) both`.
class MorkStag extends StatelessWidget {
  const MorkStag({required this.delayMs, required this.child});

  final double delayMs;
  final Widget child;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: 450 + delayMs,
    child: child,
    builder: (context, t, child) {
      final e = const Cubic(.2, .9, .3, 1).transform(kfP(t, delayMs, 450));
      return Opacity(
        opacity: e.clamp(0.0, 1.0),
        child: Transform(alignment: Alignment.center, transform: Matrix4.translationValues(0, 18 * (1 - e), 0)..scaleByDouble(.97 + .03 * e, .97 + .03 * e, 1, 1), child: child),
      );
    },
  );
}

/// The switch: 46 × 28, mint when on, the knob springing 18 px
/// (`cubic-bezier(.34,1.56,.64,1)` .3 s).
class MorkBryter extends StatelessWidget {
  const MorkBryter({required this.paa});
  final bool paa;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: paa,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 46,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: paa ? null : const Color.fromRGBO(255, 255, 255, .14),
        gradient: paa ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7FF0CB), Color(0xFF3FCB9E)]) : null,
        border: Border.all(color: paa ? const Color.fromRGBO(255, 255, 255, .4) : const Color.fromRGBO(255, 255, 255, .2)),
      ),
      child: Stack(
        children: [
          // `inset 0 2px 4px rgba(0,0,0,.3)`.
          Positioned.fill(
            child: CssBox(radius: BorderRadius.circular(999), clip: true, shadows: const [CssShadow.inset(0, 2, 4, 0, Color.fromRGBO(0, 0, 0, .3))]),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: const Cubic(.34, 1.56, .64, 1),
            left: paa ? 20 : 2,
            top: 2,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFE4ECEE)]),
                boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, .35), offset: Offset(0, 2), blurRadius: 5 / 2 / .57735)],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// The mint check of the chosen level (`klask .4s`).
class MorkHake extends StatelessWidget {
  const MorkHake();

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: 400,
    builder: (context, t, child) {
      final p = kfP(t, 0, 400);
      const c = Cubic(.3, 1.4, .5, 1);
      final s = kf(p, const [0, .6, 1], const [1.15, .98, 1], c);
      final o = kf(p, const [0, .6, 1], const [0, 1, 1], c);
      return Opacity(
        opacity: o.clamp(0.0, 1.0),
        child: Transform.scale(scale: s, child: child),
      );
    },
    child: Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB4F9E2), Color(0xFF5CE0B8)]),
        boxShadow: [BoxShadow(color: Color.fromRGBO(92, 224, 184, .6), blurRadius: 14 / 2 / .57735)],
      ),
      child: const AeIkon('M5 12.5l4.5 4.5L19 7.5', size: 13, stroke: 3.6, color: Color(0xFF0F2B33)),
    ),
  );
}

class MorkPil extends StatelessWidget {
  const MorkPil();

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color.fromRGBO(255, 255, 255, .12),
      border: Border.all(color: const Color.fromRGBO(255, 255, 255, .22)),
    ),
    child: const AeIkon('M9 6l6 6-6 6', size: 11, stroke: 3),
  );
}
