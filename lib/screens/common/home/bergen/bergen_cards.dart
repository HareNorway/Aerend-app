import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../auth/onboarding_kit.dart';
import 'bergen_copy.dart';
import 'bergen_kit.dart';

// ── Sheet cards ─────────────────────────────────────────────────────────────
// The Forundringspose row, the Utforsk row, section headers and the
// "Under kaien" zone that hides beneath the sheet.

/// `Butikker på Bryggen` / `Populært i kveld` — title, pill, dots, "Se alle".
class BergenSectionHeader extends StatelessWidget {
  const BergenSectionHeader({
    super.key,
    required this.title,
    required this.pill,
    required this.onSeeAll,
    this.pillDot = BergenColors.gold,
    this.pulse = true,
    this.dots,
    this.topPad = 12,
  });

  final String title;
  final String pill;
  final Color pillDot;
  final bool pulse;
  final VoidCallback onSeeAll;
  final Widget? dots;
  final double topPad;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Padding(
      padding: EdgeInsets.only(top: topPad * s, left: 4 * s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bDisplay(context, 15, letterSpacingEm: -.02),
                      ),
                    ),
                    SizedBox(width: 7 * s),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 9 * s,
                        vertical: 3 * s,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0x2EFFFFFF)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Glow(
                            on: pulse,
                            child: Container(
                              width: (pulse ? 6 : 5) * s,
                              height: (pulse ? 6 : 5) * s,
                              decoration: BoxDecoration(
                                color: pillDot,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          SizedBox(width: 5 * s),
                          Text(
                            pill,
                            style: bText(
                              context,
                              10,
                              weight: pulse ? FontWeight.w700 : FontWeight.w800,
                              color: pulse
                                  ? Colors.white
                                  : const Color(0xD9FFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (dots != null) ...[SizedBox(height: 4 * s), dots!],
              ],
            ),
          ),
          OnbPressable(
            onTap: onSeeAll,
            pressScale: .95,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 14 * s,
                vertical: 7 * s,
              ),
              decoration: BoxDecoration(
                color: const Color(0x1FFFFFFF),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0x38FFFFFF)),
              ),
              child: Text(
                BergenCopy.seeAll,
                style: bText(context, 12, weight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.child, required this.on});
  final Widget child;
  final bool on;
  @override
  Widget build(BuildContext context) {
    if (!on) return child;
    return OnbLoopClock(
      child: child,
      builder: (context, t, child) {
        final p = (onbLoop(t, 0, 3000) ?? 0);
        final g = onbKf(
          p,
          const [0, .5, 1],
          const [8, 15, 8],
          Curves.easeInOut,
        );
        final a = onbKf(
          p,
          const [0, .5, 1],
          const [.9, 1, .9],
          Curves.easeInOut,
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: BergenColors.gold.withValues(alpha: a),
                blurRadius: g,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

/// `Forundringspose` — the glass row with the 3D bag and the orange price.
class BergenSurpriseCard extends StatelessWidget {
  const BergenSurpriseCard({
    super.key,
    required this.onTap,
    this.price = 99,
    this.left = 2,
    this.value = 250,
  });

  final VoidCallback onTap;
  final int price;
  final int left;
  final int value;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return OnbPressable(
      onTap: onTap,
      pressScale: .985,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22 * s),
        child: Container(
          padding: EdgeInsets.fromLTRB(10 * s, 10 * s, 12 * s, 10 * s),
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(22 * s),
            border: Border.all(color: const Color(0x2EFFFFFF)),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(4, 18, 26, .7),
                offset: Offset(0, 20 * s),
                blurRadius: onbBlur(30 * s),
                spreadRadius: -16 * s,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(child: IgnorePointer(child: _sheen())),
              bergenInsetTop(radius: 22 * s, height: 1, alpha: .22),
              Row(
                children: [
                  SizedBox(
                    width: 56 * s,
                    height: 54 * s,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 4 * s,
                          right: 4 * s,
                          bottom: 2 * s,
                          height: 10 * s,
                          child: onbBlurred(
                            4,
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(60, 48, 30, .3),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          width: 56 * s,
                          height: 50 * s,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromRGBO(60, 48, 30, .45),
                                  offset: Offset(0, 4 * s),
                                  blurRadius: 6 * s,
                                ),
                              ],
                              borderRadius: BorderRadius.circular(18 * s),
                            ),
                            child: bergenSvg('bag3d'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 11 * s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 10 * s,
                              color: BergenColors.gold,
                            ),
                            SizedBox(width: 5 * s),
                            Text(
                              BergenCopy.surpriseBag,
                              style: bText(
                                context,
                                9,
                                weight: FontWeight.w800,
                                letterSpacingEm: .06,
                                color: const Color(0x8CFFFFFF),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 1 * s),
                        Text(
                          BergenCopy.surpriseTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bDisplay(context, 14.5, letterSpacingEm: -.02),
                        ),
                        SizedBox(height: 3 * s),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 7 * s,
                                vertical: 2 * s,
                              ),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(242, 136, 78, .22),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                BergenCopy.surpriseLeft(left),
                                style: bText(
                                  context,
                                  9.5,
                                  weight: FontWeight.w800,
                                  color: const Color(0xFFFFC9A8),
                                ),
                              ),
                            ),
                            SizedBox(width: 6 * s),
                            Text(
                              BergenCopy.surpriseValue(value),
                              style: bText(
                                context,
                                9.5,
                                weight: FontWeight.w800,
                                color: BergenColors.mint,
                              ),
                            ),
                            SizedBox(width: 6 * s),
                            Flexible(
                              child: Text(
                                BergenCopy.surpriseUnder,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: bText(
                                  context,
                                  10,
                                  color: const Color(0x99FFFFFF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 11 * s),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 13 * s,
                      vertical: 9 * s,
                    ),
                    decoration: BoxDecoration(
                      gradient: kBergenOrangeGradient,
                      borderRadius: BorderRadius.circular(16 * s),
                      boxShadow: [
                        const BoxShadow(
                          color: Color.fromRGBO(150, 60, 15, .9),
                          offset: Offset(0, 2),
                        ),
                        BoxShadow(
                          color: const Color.fromRGBO(120, 50, 10, .7),
                          offset: Offset(0, 9 * s),
                          blurRadius: onbBlur(16 * s),
                          spreadRadius: -8 * s,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$price kr',
                          style: bDisplay(context, 15, height: 1),
                        ),
                        SizedBox(height: 1 * s),
                        Text(
                          BergenCopy.secureOne,
                          style: bText(
                            context,
                            8.5,
                            weight: FontWeight.w800,
                            color: const Color(0xFFFFE4D2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// `sveipLys 6s 1.4s` — a light sweep across the glass.
  Widget _sheen() => OnbLoopClock(
    builder: (context, t, _) {
      final p = onbLoop(t, 1400, 6000);
      if (p == null) return const SizedBox.shrink();
      final x = p < .45
          ? -1.2 + 2.4 * Curves.easeInOut.transform(p / .45)
          : 1.2;
      return LayoutBuilder(
        builder: (context, box) => Transform.translate(
          offset: Offset(x * box.maxWidth, 0),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1, -.2),
                end: Alignment(1, .2),
                colors: [
                  Color(0x00FFFFFF),
                  Color(0x24FFFFFF),
                  Color(0x00FFFFFF),
                ],
                stops: [.44, .5, .56],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// `Utforsk-kort` (rom) — Ægil waving, "Fjordfiske, poser og nytt", "Åpne".
class BergenExploreCard extends StatelessWidget {
  const BergenExploreCard({super.key, required this.onTap, required this.line});

  final VoidCallback onTap;
  final String line;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return OnbPressable(
      onTap: onTap,
      pressScale: .985,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22 * s),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 9 * s),
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(22 * s),
            border: Border.all(color: const Color(0x2EFFFFFF)),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(4, 18, 26, .7),
                offset: Offset(0, 18 * s),
                blurRadius: onbBlur(30 * s),
                spreadRadius: -14 * s,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: -20 * s,
                top: -22 * s,
                width: 360 * s,
                height: 70 * s,
                child: const IgnorePointer(child: _NorthernLight(opacity: .35)),
              ),
              bergenInsetTop(radius: 22 * s, height: 1, alpha: .22),
              Row(
                children: [
                  SizedBox(
                    width: 40 * s,
                    height: 40 * s,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          bottom: 1 * s,
                          width: 30 * s,
                          height: 6 * s,
                          child: onbBlurred(
                            3,
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(0, 15, 22, .5),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ),
                        OnbLoopClock(
                          child: Image.asset(
                            BergenAssets.aegilExplore,
                            width: 40 * s,
                          ),
                          builder: (context, t, child) {
                            final p = (onbLoop(t, 0, 3600) ?? 0);
                            final r = onbKf(
                              p,
                              const [0, .25, .75, 1],
                              const [0, -6, 6, 0],
                              Curves.easeInOut,
                            );
                            return Transform.rotate(
                              angle: r * math.pi / 180,
                              alignment: Alignment.bottomCenter,
                              child: child,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10 * s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          BergenCopy.exploreTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bDisplay(
                            context,
                            13,
                            letterSpacingEm: -.015,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 1 * s),
                        Text(
                          line,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bText(
                            context,
                            10.5,
                            weight: FontWeight.w600,
                            color: const Color(0x99FFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10 * s),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 11 * s,
                      vertical: 7 * s,
                    ),
                    decoration: BoxDecoration(
                      gradient: kBergenOrangeGradient,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(120, 50, 10, .7),
                          offset: Offset(0, 4 * s),
                          blurRadius: onbBlur(10 * s),
                          spreadRadius: -5 * s,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          BergenCopy.openBtn,
                          style: bText(context, 11.5, weight: FontWeight.w800),
                        ),
                        SizedBox(width: 5 * s),
                        OnbIcons.of(OnbIcons.chevronRight('#FFFFFF'), 11 * s),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The blurred mint→violet arc glowing behind the Utforsk card (`nl-grad`).
class _NorthernLight extends StatelessWidget {
  const _NorthernLight({required this.opacity});
  final double opacity;
  @override
  Widget build(BuildContext context) => OnbLoopClock(
    builder: (context, t, _) {
      final p = (onbLoop(t, 0, 4500) ?? 0);
      final g = onbKf(p, const [0, .5, 1], const [.7, 1, .7], Curves.easeInOut);
      return Opacity(
        opacity: opacity * g,
        child: onbBlurred(9, CustomPaint(painter: _ArcPainter())),
      );
    },
  );
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size size) {
    final sx = size.width / 360;
    final sy = size.height / 70;
    final p = Path()
      ..moveTo(0, 60 * sy)
      ..cubicTo(70 * sx, 24 * sy, 140 * sx, 50 * sy, 210 * sx, 20 * sy)
      ..cubicTo(260 * sx, 2 * sy, 310 * sx, 16 * sy, 360 * sx, 0);
    c.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18 * sy
        ..shader = const LinearGradient(
          colors: [BergenColors.mint, Color(0xFF9C7BE8)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => false;
}

/// `Under kaien` — the underwater zone revealed when the sheet is pushed up:
/// kelp, drifting fish, three glass cards with Ægil's finds.
/// What the first Under kaien card shows when agil-2's suggestions tray has
/// a real find for `context=under_kaien`; null keeps the design's sample.
class BergenUnderQuayOffer {
  const BergenUnderQuayOffer({
    required this.id,
    required this.title,
    required this.price,
    required this.store,
    this.sub = '',
  });

  final String id;
  final String title;
  final String price;
  final String store;
  final String sub;
}

class BergenUnderQuay extends StatelessWidget {
  const BergenUnderQuay({
    super.key,
    required this.revealed,
    required this.onOffer,
    required this.onBag,
    required this.onShipping,
    this.offer,
  });

  /// `kaien` — cards lift and brighten once the sheet reaches the bottom.
  final bool revealed;

  /// A real find from `GET /api/agent/me/suggestions?context=under_kaien`.
  final BergenUnderQuayOffer? offer;
  final VoidCallback onOffer;
  final VoidCallback onBag;
  final VoidCallback onShipping;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return ClipRRect(
      borderRadius: BorderRadius.circular(26 * s),
      child: Container(
        height: 300 * s,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E5064),
              Color(0xFF143B4D),
              Color(0xFF0B2634),
              Color(0xFF05161F),
              Color(0xFF2A2418),
            ],
            stops: [0, .26, .58, .84, 1],
          ),
        ),
        child: OnbLoopClock(
          shared: true,
          builder: (context, t, _) => Stack(
            clipBehavior: Clip.none,
            children: [
              // Light shafts.
              for (final (l, w, h, sk, dur, delay) in [
                (52.0, 78.0, 290.0, 8.0, 9000.0, 0.0),
                (168.0, 54.0, 270.0, -6.0, 11000.0, 1400.0),
                (266.0, 88.0, 300.0, 13.0, 13000.0, 800.0),
              ])
                Positioned(
                  left: l * s,
                  top: 0,
                  width: w * s,
                  height: h * s,
                  child: Builder(
                    builder: (context) {
                      final p = onbLoop(t, delay, dur) ?? 0;
                      final o = onbKf(
                        p,
                        const [0, .5, 1],
                        const [.16, .34, .16],
                        Curves.easeInOut,
                      );
                      final r = onbKf(
                        p,
                        const [0, .5, 1],
                        [sk, sk + 2, sk],
                        Curves.easeInOut,
                      );
                      return Opacity(
                        opacity: o,
                        child: Transform.rotate(
                          angle: r * math.pi / 180,
                          alignment: Alignment.topCenter,
                          child: onbBlurred(
                            9,
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x8CC6EEF8),
                                    Color(0x00C6EEF8),
                                  ],
                                  stops: [0, .8],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              // Seabed and caustics.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 64 * s,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x003C3220),
                        Color(0xFF3A3020),
                        Color(0xFF2A2318),
                      ],
                      stops: [0, .3, 1],
                    ),
                  ),
                ),
              ),
              // Kelp.
              for (final (l, r, w, h, dur, delay, rev, op) in [
                (30.0, null, 60.0, 120.0, 5500.0, 0.0, false, .85),
                (null, 40.0, 50.0, 96.0, 6800.0, 900.0, true, .75),
              ])
                Positioned(
                  left: l == null ? null : l * s,
                  right: r == null ? null : r * s,
                  bottom: 26 * s,
                  width: w * s,
                  height: h * s,
                  child: Builder(
                    builder: (context) {
                      var p = onbLoop(t, delay, dur) ?? 0;
                      if (rev) p = 1 - p;
                      final a = onbKf(
                        p,
                        const [0, .5, 1],
                        const [-4, 5, -4],
                        Curves.easeInOut,
                      );
                      return Opacity(
                        opacity: op,
                        child: Transform.rotate(
                          angle: a * math.pi / 180,
                          alignment: Alignment.bottomCenter,
                          child: CustomPaint(painter: _KelpPainter()),
                        ),
                      );
                    },
                  ),
                ),
              // Fish drifting by.
              Positioned(
                top: 150 * s,
                left: 0,
                child: Builder(
                  builder: (context) {
                    final p = (onbLoop(t, 0, 18000) ?? 0);
                    const st = [0.0, .08, .45, .5, .92, 1.0];
                    final x = onbKf(p, st, const [
                      -60,
                      -12,
                      200,
                      220,
                      20,
                      -60,
                    ], Curves.linear);
                    final y = onbKf(p, st, const [
                      0,
                      0,
                      -8,
                      -6,
                      0,
                      4,
                    ], Curves.linear);
                    final o = onbKf(p, st, const [
                      0,
                      .7,
                      .7,
                      .5,
                      .6,
                      0,
                    ], Curves.linear);
                    final flip = p >= .5;
                    return Opacity(
                      opacity: o.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(x * s, y * s),
                        child: Transform.flip(
                          flipX: flip,
                          child: SizedBox(
                            width: 60 * s,
                            height: 24 * s,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  child: Opacity(
                                    opacity: .55,
                                    child: bergenSvg('orb_fish', width: 22 * s),
                                  ),
                                ),
                                Positioned(
                                  left: 26 * s,
                                  top: 9 * s,
                                  child: Opacity(
                                    opacity: .45,
                                    child: bergenSvg('orb_fish', width: 18 * s),
                                  ),
                                ),
                                Positioned(
                                  left: 14 * s,
                                  top: 16 * s,
                                  child: Opacity(
                                    opacity: .4,
                                    child: bergenSvg('orb_fish', width: 16 * s),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Bubbles.
              for (final (l, tp, sz, dur, delay) in [
                (38.0, 206.0, 5.0, 7000.0, 0.0),
                (124.0, 230.0, 3.5, 9000.0, 1800.0),
                (268.0, 216.0, 4.5, 8000.0, 3200.0),
                (332.0, 238.0, 3.0, 10000.0, 900.0),
              ])
                Positioned(
                  left: l * s,
                  top: tp * s,
                  width: sz * s,
                  height: sz * s,
                  child: Builder(
                    builder: (context) {
                      final p = onbLoop(t, delay, dur);
                      if (p == null) return const SizedBox.shrink();
                      final e = Curves.easeIn.transform(p);
                      final o = onbKf(
                        p,
                        const [0, .25, 1],
                        const [0, .6, 0],
                        Curves.linear,
                      );
                      return Opacity(
                        opacity: o.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, (10 - 94 * e) * s),
                          child: Transform.scale(
                            scale: .7 + .3 * e,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(206, 240, 250, .7),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              Positioned(
                left: 66 * s,
                top: 246 * s,
                child: Opacity(
                  opacity: .9,
                  child: bergenSvg('garnkule', width: 34 * s, height: 37 * s),
                ),
              ),
              // Vignette.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        radius: 1.1,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: .55),
                        ],
                        stops: const [.6, 1],
                      ),
                    ),
                  ),
                ),
              ),
              // Header + cards.
              Positioned(
                left: 16 * s,
                right: 16 * s,
                top: 46 * s,
                child: Row(
                  children: [
                    Container(
                      width: 36 * s,
                      height: 36 * s,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          center: Alignment(0, -.4),
                          colors: [BergenColors.teal1, BergenColors.teal3],
                          stops: [0, .8],
                        ),
                        boxShadow: [
                          const BoxShadow(
                            color: Color(0x80BEE8F4),
                            spreadRadius: 1.5,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .8),
                            offset: Offset(0, 6 * s),
                            blurRadius: onbBlur(12 * s),
                            spreadRadius: -6 * s,
                          ),
                        ],
                      ),
                      child: Align(
                        alignment: const Alignment(0, 1.4),
                        child: Image.asset(
                          BergenAssets.aegilFront,
                          width: 36 * s,
                        ),
                      ),
                    ),
                    SizedBox(width: 10 * s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            BergenCopy.underQuay,
                            style: bText(
                              context,
                              9,
                              weight: FontWeight.w800,
                              letterSpacingEm: .08,
                              color: BergenColors.skyText,
                            ),
                          ),
                          Text(
                            BergenCopy.underQuayLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: bDisplay(
                              context,
                              13,
                              letterSpacingEm: -.015,
                              height: 1.2,
                              color: BergenColors.cream,
                              shadows: const [
                                Shadow(
                                  color: Color(0x80000000),
                                  offset: Offset(0, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 12 * s,
                right: 12 * s,
                top: 94 * s,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 450),
                  opacity: revealed ? 1 : .35,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 550),
                    curve: const Cubic(.2, .9, .3, 1),
                    offset: Offset(0, revealed ? 0 : .1),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _FindCard(
                              tag: BergenCopy.offer,
                              tagColor: const Color(0xFFFFB27A),
                              tagBg: const Color.fromRGBO(242, 109, 61, .28),
                              tagBorder: const Color.fromRGBO(
                                249,
                                162,
                                115,
                                .5,
                              ),
                              badge: '+5',
                              badgeGradient: const [
                                Color(0xFFFFDD86),
                                BergenColors.gold,
                              ],
                              badgeText: const Color(0xFF3A2708),
                              badgeRot: 6,
                              glow: const Color.fromRGBO(152, 216, 234, .25),
                              border: const Color.fromRGBO(190, 232, 244, .35),
                              art: bergenSvg(
                                'float_shrimp',
                                width: 44 * s,
                                height: 34 * s,
                              ),
                              title: offer?.title ?? 'Reker, 1 kg',
                              price: offer?.price ?? '299 kr',
                              priceColor: const Color(0xFFFFB27A),
                              sub: offer == null
                                  ? '· ${BergenCopy.before} 349'
                                  : offer!.sub,
                              link: offer?.store ?? 'Torgboden',
                              delay: 100,
                              bob: 5200,
                              onTap: onOffer,
                            ),
                          ),
                          SizedBox(width: 9 * s),
                          Expanded(
                            child: _FindCard(
                              tag: BergenCopy.bag,
                              tagColor: BergenColors.goldLight,
                              tagBg: const Color.fromRGBO(242, 193, 78, .26),
                              tagBorder: const Color.fromRGBO(
                                255,
                                221,
                                134,
                                .5,
                              ),
                              badge: BergenCopy.left2,
                              badgeGradient: const [
                                BergenColors.mintPale,
                                BergenColors.mintDeep,
                              ],
                              badgeText: const Color(0xFF0F1F2B),
                              badgeRot: -5,
                              glow: const Color.fromRGBO(242, 193, 78, .3),
                              border: const Color.fromRGBO(242, 193, 78, .45),
                              art: bergenSvg(
                                'bag3d',
                                width: 36 * s,
                                height: 36 * s,
                              ),
                              title: 'Forundringspose',
                              price: '99 kr',
                              priceColor: BergenColors.goldLight,
                              sub: '· ${BergenCopy.worth} 250+',
                              link: BergenCopy.openBag,
                              delay: 220,
                              bob: 5800,
                              onTap: onBag,
                            ),
                          ),
                          SizedBox(width: 9 * s),
                          Expanded(
                            child: _FindCard(
                              tag: BergenCopy.shipping,
                              tagColor: BergenColors.mintPale,
                              tagBg: const Color.fromRGBO(92, 224, 184, .22),
                              tagBorder: const Color.fromRGBO(
                                127,
                                240,
                                203,
                                .5,
                              ),
                              badge: BergenCopy.tonight,
                              badgeGradient: const [
                                Color(0xFFF9A273),
                                BergenColors.orange,
                              ],
                              badgeText: Colors.white,
                              badgeRot: 5,
                              glow: const Color.fromRGBO(92, 224, 184, .28),
                              border: const Color.fromRGBO(92, 224, 184, .4),
                              art: bergenSvg(
                                'longship3d',
                                width: 46 * s,
                                height: 30 * s,
                              ),
                              title: BergenCopy.freeDelivery,
                              price: '300 kr',
                              priceColor: BergenColors.mintPale,
                              sub: BergenCopy.overTonight,
                              subFirst: 'Over ',
                              link: 'Casa Maria',
                              delay: 340,
                              bob: 6400,
                              onTap: onShipping,
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
        ),
      ),
    );
  }
}

class _KelpPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size size) {
    final sx = size.width / 60;
    final sy = size.height / 120;
    final stem = Path()
      ..moveTo(30 * sx, 120 * sy)
      ..cubicTo(26 * sx, 100 * sy, 36 * sx, 90 * sy, 30 * sx, 72 * sy)
      ..cubicTo(24 * sx, 54 * sy, 36 * sx, 44 * sy, 30 * sx, 24 * sy)
      ..cubicTo(27 * sx, 14 * sy, 32 * sx, 8 * sy, 30 * sx, 0);
    c.drawPath(
      stem,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7 * sx
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF2F6B4A),
    );
    c.save();
    c.translate(-1.5 * sx, 0);
    c.drawPath(
      stem,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * sx
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF4F9A6A),
    );
    c.restore();
    final leaves = Path()
      ..moveTo(30 * sx, 96 * sy)
      ..cubicTo(40 * sx, 92 * sy, 46 * sx, 84 * sy, 48 * sx, 74 * sy)
      ..moveTo(30 * sx, 60 * sy)
      ..cubicTo(20 * sx, 56 * sy, 14 * sx, 48 * sy, 12 * sx, 38 * sy)
      ..moveTo(30 * sx, 40 * sy)
      ..cubicTo(40 * sx, 36 * sy, 44 * sx, 30 * sy, 45 * sx, 22 * sy);
    c.drawPath(
      leaves,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * sx
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF3F8A5C),
    );
  }

  @override
  bool shouldRepaint(_KelpPainter old) => false;
}

class _FindCard extends StatelessWidget {
  const _FindCard({
    required this.tag,
    required this.tagColor,
    required this.tagBg,
    required this.tagBorder,
    required this.badge,
    required this.badgeGradient,
    required this.badgeText,
    required this.badgeRot,
    required this.glow,
    required this.border,
    required this.art,
    required this.title,
    required this.price,
    required this.priceColor,
    required this.sub,
    this.subFirst,
    required this.link,
    required this.delay,
    required this.bob,
    required this.onTap,
  });

  final String tag;
  final Color tagColor;
  final Color tagBg;
  final Color tagBorder;
  final String badge;
  final List<Color> badgeGradient;
  final Color badgeText;
  final double badgeRot;
  final Color glow;
  final Color border;
  final Widget art;
  final String title;
  final String price;
  final Color priceColor;
  final String sub;
  final String? subFirst;
  final String link;
  final double delay;
  final double bob;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return OnbTimeline(
      durationMs: delay + 500,
      builder: (context, t, child) {
        final p = const Cubic(.2, .9, .3, 1).transform(onbP(t, delay, 500));
        return Opacity(
          opacity: p.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - p) * s),
            child: child,
          ),
        );
      },
      child: OnbLoopClock(
        child: OnbPressable(
          onTap: onTap,
          pressDy: 3,
          child: Container(
            padding: EdgeInsets.all(10 * s),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18 * s),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x29FFFFFF), Color(0x12FFFFFF)],
              ),
              border: Border.all(color: border),
              boxShadow: [
                const BoxShadow(
                  color: Color.fromRGBO(2, 12, 18, .7),
                  offset: Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: .85),
                  offset: Offset(0, 22 * s),
                  blurRadius: onbBlur(30 * s),
                  spreadRadius: -14 * s,
                ),
                BoxShadow(
                  color: glow,
                  blurRadius: onbBlur(24 * s),
                  spreadRadius: -6 * s,
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: -2 * s,
                  right: -2 * s,
                  top: -10 * s,
                  height: 1,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x00FFFFFF),
                          Color(0xCCFFFFFF),
                          Color(0x00FFFFFF),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -16 * s,
                  top: -18 * s,
                  child: Transform.rotate(
                    angle: badgeRot * math.pi / 180,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7 * s,
                        vertical: 3 * s,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: badgeGradient,
                        ),
                        boxShadow: [
                          const BoxShadow(
                            color: Colors.white,
                            spreadRadius: 1.5,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .6),
                            offset: Offset(0, 3 * s),
                            blurRadius: 6 * s,
                            spreadRadius: -2 * s,
                          ),
                        ],
                      ),
                      child: Text(
                        badge,
                        style: bText(
                          context,
                          8.5,
                          weight: FontWeight.w800,
                          color: badgeText,
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 34 * s,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.fromLTRB(
                                5 * s,
                                2.5 * s,
                                7 * s,
                                2.5 * s,
                              ),
                              decoration: BoxDecoration(
                                color: tagBg,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: tagBorder),
                              ),
                              child: Text(
                                tag,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: bText(
                                  context,
                                  8,
                                  weight: FontWeight.w800,
                                  letterSpacingEm: .02,
                                  color: tagColor,
                                ),
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: Offset(2 * s, -2 * s),
                            child: art,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 5 * s),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bDisplay(
                        context,
                        12.5,
                        letterSpacingEm: -.02,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: 5 * s),
                    Text.rich(
                      TextSpan(
                        style: bText(
                          context,
                          10,
                          color: const Color(0x9EFFFFFF),
                          height: 1.2,
                        ),
                        children: [
                          if (subFirst != null) TextSpan(text: subFirst),
                          TextSpan(
                            text: price,
                            style: TextStyle(
                              color: priceColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(text: ' $sub'),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6 * s),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            link,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: bText(
                              context,
                              10,
                              weight: FontWeight.w800,
                              color: BergenColors.skyText,
                            ),
                          ),
                        ),
                        SizedBox(width: 3 * s),
                        OnbIcons.of(OnbIcons.chevronRight('#9FD3DE'), 8 * s),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        builder: (context, t, child) {
          final p = onbLoop(t, delay * 6, bob) ?? 0;
          final dy = onbKf(
            p,
            const [0, .5, 1],
            const [0, -5, 0],
            Curves.easeInOut,
          );
          return Transform.translate(offset: Offset(0, dy * s), child: child);
        },
      ),
    );
  }
}
