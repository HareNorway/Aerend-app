import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../auth/onboarding_kit.dart';
import 'bergen_copy.dart';
import 'bergen_kit.dart';
import 'bergen_painters.dart';

// ── Ægil's floats (`dupper`) and the card that rises from the water ─────────
// Three crates bob on the water in front of the pier, each carrying a product
// Ægil picked. Tapping one reels it to the pier and lifts a card with the
// offer (`Napp-kort`).

enum BergenFloatKind { offer, fresh, rhythm }

enum BergenFloatIcon { shrimp, fish, crate }

class BergenFloatItem {
  const BergenFloatItem({
    required this.id,
    required this.title,
    required this.store,
    required this.priceText,
    required this.reason,
    required this.kind,
    required this.icon,
    this.storeId = 0,
    this.productId = 0,
    this.price = 0,
    this.photoUrl,
    this.photoAsset,
    this.bergensk = false,
    this.glow = false,
    this.ring = false,
    this.tint = const LinearGradient(
      colors: [Color(0xFFDCE9EC), Color(0xFF9FB6C2)],
    ),
  });

  final String id;
  final String title;
  final String store;
  final String priceText;
  final String reason;
  final BergenFloatKind kind;
  final BergenFloatIcon icon;
  final int storeId;
  final int productId;
  final double price;
  final String? photoUrl;
  final String? photoAsset;
  final bool bergensk;

  /// `funn` — a mint glow behind the badge.
  final bool glow;

  /// `ny` — a slow ring pulsing out from the float.
  final bool ring;
  final Gradient tint;

  bool get hasPhoto => photoUrl != null || photoAsset != null;

  Color get color => kind == BergenFloatKind.rhythm
      ? const Color(0xFFE9573A)
      : BergenColors.teal1;

  String get iconAsset => switch (icon) {
    BergenFloatIcon.shrimp => 'float_shrimp',
    BergenFloatIcon.fish => 'float_fish',
    BergenFloatIcon.crate => 'float_crate',
  };

  String get cardIconAsset => switch (icon) {
    BergenFloatIcon.shrimp => 'pi_bowl',
    BergenFloatIcon.fish => 'orb_fish',
    BergenFloatIcon.crate => 'pi_wok',
  };
}

class BergenFloat extends StatelessWidget {
  const BergenFloat({
    super.key,
    required this.item,
    required this.index,
    required this.selected,
    required this.dimmed,
    required this.showCatchBadge,
    required this.onTap,
  });

  final BergenFloatItem item;
  final int index;
  final bool selected;
  final bool dimmed;

  /// `napp` — the "+5" pill on the first float.
  final bool showCatchBadge;
  final VoidCallback onTap;

  static const _xs = [106.0, 195.0, 284.0];

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final x = selected ? 306.0 : _xs[math.min(index, 2)];
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 600),
      curve: const Cubic(.3, .8, .3, 1),
      left: (x - 22) * s,
      top: 130 * s,
      width: 44 * s,
      height: 44 * s,
      child: OnbTimeline(
        durationMs: 1200,
        builder: (context, t, child) {
          // duppInn .7s .5s — slides in from the right.
          final p = const Cubic(.2, .9, .3, 1).transform(onbP(t, 500, 700));
          return Opacity(
            opacity: (p * (dimmed ? .55 : 1)).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(120 * (1 - p) * s, 0),
              child: child,
            ),
          );
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: OnbLoopClock(builder: (context, t, _) => _body(context, t)),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, double t) {
    final s = context.bs;
    final c = item.color;
    // duppDrift (5+n)s (n*.7)s — bobbing and rolling.
    final pd = (onbLoop(t, index * 700.0, (5 + index) * 1000.0) ?? 0);
    const ds = [0.0, .25, .5, .75, 1.0];
    final dy = onbKf(pd, ds, const [0, -2, -3.4, -1, 0], Curves.easeInOut);
    final rot = onbKf(pd, ds, const [-2.6, 0, 2.6, 0, -2.6], Curves.easeInOut);
    final sy = onbKf(pd, ds, const [1, .982, 1, 1.016, 1], Curves.easeInOut);
    final breathe = onbKf(
      (onbLoop(t, 0, 4200) ?? 0),
      const [0, .5, 1],
      const [.55, 1, .55],
      Curves.easeInOut,
    );
    final glans = onbKf(
      (onbLoop(t, 0, 3800) ?? 0),
      const [0, .5, 1],
      const [.5, .85, .5],
      Curves.easeInOut,
    );

    Widget ring(
      double left,
      double top,
      double w,
      double h,
      double delayMs,
      double dur,
      double alpha,
    ) {
      final p = onbLoop(t, delayMs, dur);
      final sc = p == null ? .55 : .55 + 1.05 * Curves.easeOut.transform(p);
      final o = p == null
          ? 0.0
          : (p < .18 ? p / .18 * .5 : .5 * (1 - (p - .18) / .82));
      return Positioned(
        left: left * s,
        top: top * s,
        width: w * s,
        height: h * s,
        child: Opacity(
          opacity: o.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: sc,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: const Color(0xFFD6F2FA).withValues(alpha: alpha),
                  width: 1.1 * s,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Shadows, glow and water rings under the float.
        Positioned(
          left: -4 * s,
          top: 26 * s,
          width: 56 * s,
          height: 18 * s,
          child: onbBlurred(
            3,
            bergenRadial(
              colors: const [
                Color.fromRGBO(6, 26, 36, .5),
                Color.fromRGBO(6, 26, 36, 0),
              ],
              stops: const [0, .72],
            ),
          ),
        ),
        Positioned(
          left: 8 * s,
          top: 40 * s,
          width: 28 * s,
          height: 14 * s,
          child: Opacity(
            opacity: .32 * breathe,
            child: Transform.scale(
              scaleY: .7,
              child: onbBlurred(
                2.5,
                bergenRadial(
                  center: const Offset(.5, .3),
                  colors: [c, c.withValues(alpha: 0)],
                  stops: const [0, .7],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: -6 * s,
          top: 28 * s,
          width: 60 * s,
          height: 16 * s,
          child: onbBlurred(
            2.5,
            bergenRadial(
              colors: const [
                Color.fromRGBO(196, 236, 248, .3),
                Color.fromRGBO(196, 236, 248, 0),
              ],
              stops: const [0, .7],
            ),
          ),
        ),
        Positioned(
          left: 6 * s,
          top: 32 * s,
          width: 32 * s,
          height: 9 * s,
          child: onbBlurred(
            2,
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(8, 24, 32, .42),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
        Positioned(
          left: 8 * s,
          top: 29 * s,
          width: 28 * s,
          height: 8 * s,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: const Color(0xB3D6F2FA),
                width: 1.2 * s,
              ),
            ),
          ),
        ),
        ring(4, 27, 36, 11, 0, 5000, .5),
        ring(0, 26, 44, 13, 1900, 5000, .32),
        if (item.ring)
          Positioned(
            left: 1 * s,
            top: 20 * s,
            width: 42 * s,
            height: 16 * s,
            child: Builder(
              builder: (context) {
                final p = onbLoop(t, 1200, 4000);
                if (p == null) return const SizedBox.shrink();
                final e = Curves.easeOut.transform(p);
                return Opacity(
                  opacity: .8 * (1 - e),
                  child: Transform.scale(
                    scale: .4 + 1.4 * e,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: const Color(0xD9FFFFFF),
                          width: 1.5 * s,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        // The crate on the water.
        Positioned(
          left: 2 * s,
          top: 2 * s,
          width: 40 * s,
          height: 40 * s,
          child: Transform.translate(
            offset: Offset(0, dy * s),
            child: Transform(
              alignment: const Alignment(0, .84),
              transform: Matrix4.identity()
                ..rotateZ(rot * math.pi / 180)
                ..scaleByDouble(1, sy, 1, 1),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -10 * s,
                    top: -6 * s,
                    width: 60 * s,
                    height: 50 * s,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 6 * s,
                          right: 6 * s,
                          top: 30 * s,
                          height: 22 * s,
                          child: onbBlurred(
                            7,
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: c.withValues(alpha: .28),
                                borderRadius: BorderRadius.circular(16 * s),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromRGBO(3, 16, 24, .35),
                                  offset: Offset(0, 6 * s),
                                  blurRadius: 6 * s,
                                ),
                              ],
                              borderRadius: BorderRadius.circular(20 * s),
                            ),
                            child: bergenSvg(
                              item.iconAsset,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        if (item.hasPhoto)
                          Positioned(
                            left: 13 * s,
                            top: -4 * s,
                            width: 36 * s,
                            height: 30 * s,
                            child: Transform.rotate(
                              angle: -4 * math.pi / 180,
                              child: _photo(item, BoxFit.contain),
                            ),
                          ),
                        // Water surface across the crate.
                        Positioned(
                          left: 8 * s,
                          right: 8 * s,
                          top: 36 * s,
                          height: 14 * s,
                          child: ClipPath(
                            clipper: _TrapezoidClipper(),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: const Color(0xCCD6F2FA),
                                    width: 1.2 * s,
                                  ),
                                ),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color.fromRGBO(40, 120, 150, .18),
                                    Color.fromRGBO(8, 44, 62, .7),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 35 * s,
                          height: 2 * s,
                          child: Opacity(
                            opacity: glans,
                            child: onbBlurred(
                              .6,
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0x00FFFFFF),
                                      Color(0xBFFFFFFF),
                                      Color(0xBFFFFFFF),
                                      Color(0x00FFFFFF),
                                    ],
                                    stops: [0, .3, .7, 1],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16 * s,
                          top: 44 * s,
                          width: 20 * s,
                          height: 3 * s,
                          child: onbBlurred(
                            1,
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(198, 238, 248, .5),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // The coloured badge with its icon.
                  Positioned(
                    left: -14 * s,
                    top: -8 * s,
                    width: 19 * s,
                    height: 19 * s,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (item.glow)
                          Positioned(
                            left: -6 * s,
                            top: -6 * s,
                            width: 52 * s,
                            height: 52 * s,
                            child: Opacity(
                              opacity: .7 + .3 * breathe,
                              child: onbBlurred(
                                2,
                                bergenRadial(
                                  colors: const [
                                    Color.fromRGBO(92, 224, 184, .45),
                                    Color.fromRGBO(127, 180, 196, .2),
                                    Color.fromRGBO(92, 224, 184, 0),
                                  ],
                                  stops: const [0, .55, .72],
                                ),
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              boxShadow: [
                                const BoxShadow(
                                  color: Colors.white,
                                  spreadRadius: 2.2,
                                ),
                                BoxShadow(
                                  color: const Color.fromRGBO(6, 26, 36, .65),
                                  offset: Offset(0, 5 * s),
                                  blurRadius: 7 * s,
                                  spreadRadius: -2 * s,
                                ),
                              ],
                            ),
                            child: _badgeIcon(context),
                          ),
                        ),
                        Positioned(
                          left: 3 * s,
                          top: 2 * s,
                          width: 8 * s,
                          height: 4.5 * s,
                          child: onbBlurred(
                            1.2,
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .6),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Price pill.
                  Positioned(
                    left: -20 * s,
                    right: -20 * s,
                    top: 44 * s,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.fromLTRB(
                          9 * s,
                          3 * s,
                          9 * s,
                          3.5 * s,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white, Color(0xFFF4EFE4)],
                          ),
                          boxShadow: [
                            const BoxShadow(
                              color: Color(0xF2FFFFFF),
                              spreadRadius: 1,
                            ),
                            const BoxShadow(
                              color: Color(0xFFE2DACA),
                              offset: Offset(0, 2),
                            ),
                            const BoxShadow(
                              color: Color.fromRGBO(6, 26, 36, .35),
                              offset: Offset(0, 3),
                            ),
                            BoxShadow(
                              color: const Color.fromRGBO(6, 26, 36, .7),
                              offset: Offset(0, 10 * s),
                              blurRadius: onbBlur(12 * s),
                              spreadRadius: -6 * s,
                            ),
                          ],
                        ),
                        child: Text(
                          item.priceText,
                          style: bDisplay(
                            context,
                            9.5,
                            color: BergenColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showCatchBadge)
          Positioned(
            left: 7 * s,
            top: -16 * s,
            child: OnbTimeline(
              durationMs: 900,
              builder: (context, t, child) {
                final p = onbP(t, 400, 500);
                final sc = onbKf(
                  p,
                  const [0, .35, .7, 1],
                  const [.6, 1.16, .96, 1],
                  const Cubic(.34, 1.56, .64, 1),
                );
                return Opacity(
                  opacity: p.clamp(0.0, 1.0),
                  child: Transform.scale(scale: sc, child: child),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * s,
                  vertical: 2 * s,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [BergenColors.mint, BergenColors.mintDeep],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: BergenColors.mintDeep.withValues(alpha: .9),
                      offset: Offset(0, 4 * s),
                      blurRadius: onbBlur(10 * s),
                      spreadRadius: -4 * s,
                    ),
                  ],
                ),
                child: Text(
                  '+5',
                  style: bText(
                    context,
                    10,
                    weight: FontWeight.w800,
                    color: const Color(0xFF0F1F2B),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _badgeIcon(BuildContext context) {
    final s = context.bs;
    switch (item.kind) {
      case BergenFloatKind.offer:
        return SizedBox(
          width: 10 * s,
          height: 10 * s,
          child: CustomPaint(painter: _DiamondPainter()),
        );
      case BergenFloatKind.fresh:
        return Text(
          'NY',
          style: bText(
            context,
            7.5,
            weight: FontWeight.w800,
            letterSpacingEm: .01,
          ),
        );
      case BergenFloatKind.rhythm:
        return SizedBox(
          width: 10 * s,
          height: 10 * s,
          child: CustomPaint(painter: _ClockPainter()),
        );
    }
  }
}

Widget _photo(BergenFloatItem item, BoxFit fit) {
  if (item.photoAsset != null) return Image.asset(item.photoAsset!, fit: fit);
  return CachedNetworkImage(
    imageUrl: item.photoUrl!,
    fit: fit,
    errorWidget: (_, __, ___) => const SizedBox.shrink(),
  );
}

class _TrapezoidClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width * .95, size.height)
    ..lineTo(size.width * .05, size.height)
    ..close();
  @override
  bool shouldReclip(_TrapezoidClipper old) => false;
}

class _DiamondPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size size) {
    final k = size.width / 24;
    final p = Path()
      ..moveTo(4 * k, 4 * k)
      ..lineTo(12 * k, 4 * k)
      ..lineTo(20 * k, 12 * k)
      ..lineTo(12 * k, 20 * k)
      ..lineTo(4 * k, 12 * k)
      ..close();
    c.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2 * k
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_DiamondPainter old) => false;
}

class _ClockPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size size) {
    final k = size.width / 24;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * k
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    c.drawCircle(Offset(12 * k, 12 * k), 8.5 * k, p);
    c.drawPath(
      Path()
        ..moveTo(12 * k, 7.5 * k)
        ..lineTo(12 * k, 12 * k)
        ..lineTo(15 * k, 14 * k),
      p,
    );
  }

  @override
  bool shouldRepaint(_ClockPainter old) => false;
}

/// `Napp-kort` — the offer card rising out of the water.
class BergenNappCard extends StatelessWidget {
  const BergenNappCard({
    super.key,
    required this.item,
    required this.onClose,
    required this.onAdd,
    required this.onNotNow,
    required this.onNever,
  });

  final BergenFloatItem item;
  final VoidCallback onClose;
  final VoidCallback onAdd;
  final VoidCallback onNotNow;
  final VoidCallback onNever;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onClose,
          child: const ColoredBox(color: Color.fromRGBO(8, 24, 32, .1)),
        ),
        Positioned(
          left: 24 * s,
          right: 24 * s,
          bottom: 14 * s,
          child: OnbTimeline(
            durationMs: 450,
            builder: (context, t, child) {
              final p = const Cubic(.2, .9, .3, 1).transform(onbP(t, 0, 450));
              return Opacity(
                opacity: p.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 60 * (1 - p) * s),
                  child: child,
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22 * s),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  padding: EdgeInsets.all(12 * s),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .94),
                    borderRadius: BorderRadius.circular(22 * s),
                    border: Border.all(color: const Color(0xF2FFFFFF)),
                    boxShadow: [
                      const BoxShadow(
                        color: Color.fromRGBO(8, 24, 32, .15),
                        offset: Offset(0, 2),
                        blurRadius: 3,
                        spreadRadius: -1,
                      ),
                      BoxShadow(
                        color: const Color.fromRGBO(8, 24, 32, .6),
                        offset: Offset(0, 24 * s),
                        blurRadius: onbBlur(44 * s),
                        spreadRadius: -20 * s,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 64 * s,
                            height: 64 * s,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16 * s),
                              gradient: item.hasPhoto ? null : item.tint,
                              color: item.hasPhoto ? BergenColors.plate : null,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromRGBO(8, 24, 32, .5),
                                  offset: Offset(0, 6 * s),
                                  blurRadius: onbBlur(12 * s),
                                  spreadRadius: -8 * s,
                                ),
                              ],
                            ),
                            child: item.hasPhoto
                                ? _photo(item, BoxFit.cover)
                                : Center(
                                    child: bergenSvg(
                                      item.cardIconAsset,
                                      width: 44 * s,
                                      height: 40 * s,
                                    ),
                                  ),
                          ),
                          SizedBox(width: 12 * s),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: bDisplay(
                                    context,
                                    15,
                                    letterSpacingEm: -.02,
                                    height: 1.2,
                                    color: BergenColors.ink,
                                  ),
                                ),
                                SizedBox(height: 3 * s),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        item.store,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: bText(
                                          context,
                                          11,
                                          color: BergenColors.inkSoft,
                                        ),
                                      ),
                                    ),
                                    if (item.bergensk) ...[
                                      SizedBox(width: 6 * s),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6 * s,
                                          vertical: 1 * s,
                                        ),
                                        decoration: BoxDecoration(
                                          color: BergenColors.orange.withValues(
                                            alpha: .14,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          BergenCopy.bergensk,
                                          style: bText(
                                            context,
                                            9,
                                            weight: FontWeight.w800,
                                            color: const Color(0xFFB9441A),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                SizedBox(height: 3 * s),
                                Text(
                                  item.priceText,
                                  style: bText(
                                    context,
                                    12.5,
                                    weight: FontWeight.w800,
                                    color: BergenColors.ink,
                                  ),
                                ),
                                SizedBox(height: 2 * s),
                                Text(
                                  item.reason,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: bText(
                                    context,
                                    11,
                                    weight: FontWeight.w600,
                                    color: const Color(0xFF6E6862),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10 * s),
                      Row(
                        children: [
                          Expanded(
                            flex: 14,
                            child: _btn(
                              context,
                              BergenCopy.addToCart,
                              onAdd,
                              gradient: kBergenOrangeGradient,
                              color: Colors.white,
                              fontSize: 13,
                              shadow: [
                                const BoxShadow(
                                  color: Color(0xB3FFFFFF),
                                  spreadRadius: 1,
                                ),
                                BoxShadow(
                                  color: const Color.fromRGBO(233, 92, 44, .7),
                                  offset: Offset(0, 10 * s),
                                  blurRadius: onbBlur(18 * s),
                                  spreadRadius: -8 * s,
                                ),
                                BoxShadow(
                                  color: const Color.fromRGBO(
                                    242,
                                    193,
                                    78,
                                    .35,
                                  ),
                                  blurRadius: onbBlur(18 * s),
                                  spreadRadius: 2 * s,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 6 * s),
                          Expanded(
                            flex: 10,
                            child: _btn(
                              context,
                              BergenCopy.notNow,
                              onNotNow,
                              color: BergenColors.ink,
                            ),
                          ),
                          SizedBox(width: 6 * s),
                          Expanded(
                            flex: 10,
                            child: _btn(
                              context,
                              BergenCopy.neverThis,
                              onNever,
                              color: const Color(0xFF6E6862),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _btn(
    BuildContext context,
    String label,
    VoidCallback onTap, {
    Gradient? gradient,
    required Color color,
    double fontSize = 12.5,
    List<BoxShadow>? shadow,
  }) {
    final s = context.bs;
    return OnbPressable(
      onTap: onTap,
      pressScale: .96,
      child: Container(
        height: 44 * s,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? Colors.white : null,
          borderRadius: BorderRadius.circular(999),
          border: gradient == null
              ? Border.all(color: const Color(0x1F23201D))
              : null,
          boxShadow: shadow,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: bText(
            context,
            fontSize,
            weight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }
}
